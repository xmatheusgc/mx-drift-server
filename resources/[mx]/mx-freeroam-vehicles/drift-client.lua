VehicleDrift={}
local D=VehicleDrift
local snapshots,restored={},{ }
local support,failed={},{}
local diagnostics={}
local fields={}
for _,group in ipairs({{'floats','Float','CHandlingData'},{'ints','Int','CHandlingData'},{'vectors','Vector','CHandlingData'},{'car','Float','CCarHandlingData'}}) do
 for name,value in pairs(VehicleDriftPreset[group[1]]) do fields[#fields+1]={name=name,value=value,kind=group[2],class=group[3]} end
end
table.sort(fields,function(a,b)return a.class..a.name<b.class..b.name end)
local function read(v,f) return _G['GetVehicleHandling'..f.kind](v,f.class,f.name) end
local function finite(n)return MX.number(n,-1e12,1e12) end
local function valid(f,value)
 if f.kind=='Vector' then return (type(value)=='table' or type(value)=='vector3' or type(value)=='userdata') and finite(value.x) and finite(value.y) and finite(value.z) end
 -- Cfx's handling setter currently clamps nInitialDriveGears to 7. Do not
 -- accept a baseline that this same setter could not restore faithfully.
 if f.name=='nInitialDriveGears' then return MX.number(value,1,7,true) end
 return finite(value)
end
local function equal(f,a,b)
 if not valid(f,a) then return false end
 if f.kind=='Vector' then return math.abs(a.x-b.x)<.001 and math.abs(a.y-b.y)<.001 and math.abs(a.z-b.z)<.001 end
 return math.abs(a-b)<=math.max(.001,math.abs(b)*.00001)
end
local function write(v,f,value)
 if f.kind=='Vector' then SetVehicleHandlingVector(v,f.class,f.name,vector3(value.x,value.y,value.z))
 elseif f.kind=='Int' then SetVehicleHandlingInt(v,f.class,f.name,value)
 else SetVehicleHandlingFloat(v,f.class,f.name,value+0.0) end
end
local function identity(v,id)return DoesEntityExist(v) and Entity(v).state.mxVehicle==id end
local function powered(v,wheel)
 local value=GetVehicleWheelIsPowered(v,wheel) return value==true or value==1
end
local function captureDrive(v)
 MX.require(GetVehicleNumberOfWheels(v)==4,'HANDLING_UNSUPPORTED','O preset de drift exige um carro de quatro rodas')
 local wheels={} for wheel=0,3 do wheels[wheel+1]=powered(v,wheel) end
 local gear=GetVehicleHighGear(v)
 MX.require(MX.number(gear,1,255,true),'HANDLING_UNSUPPORTED','A transmissão original ainda não foi inicializada; tente novamente')
 return {gear=gear,wheels=wheels}
end
local function refreshDrive(v,drive)
 -- Documented native: rebuild transmission after drive-force/max-flat-velocity edits.
 -- Zero is a percentage change of zero, not an extra engine-power multiplier.
 ModifyVehicleTopSpeed(v,0.0)
 SetVehicleHighGear(v,drive.gear)
 for wheel=0,3 do SetVehicleWheelIsPowered(v,wheel,drive.wheels[wheel+1]) end
 MX.require(GetVehicleHighGear(v)==drive.gear,'HANDLING','A transmissão não confirmou o número de marchas')
 for wheel=0,3 do MX.require(powered(v,wheel)==drive.wheels[wheel+1],'HANDLING','A roda '..wheel..' não confirmou a tração') end
end
local function presetDrive()
 local bias=VehicleDriftPreset.floats.fDriveBiasFront
 return {gear=VehicleDriftPreset.ints.nInitialDriveGears,wheels={bias>0,bias>0,bias<1,bias<1}}
end
local function clean(value)
 if type(value)=='vector3' or type(value)=='userdata' then return {x=value.x,y=value.y,z=value.z} end return value
end
function D.audit(v,id,enabled)
 MX.require(identity(v,id),'OBSOLETE','O veículo foi substituído; atualize o diagnóstico')
 local saved=snapshots[v] or restored[v]
 if saved and saved.id~=id then saved=nil end
 local report={id=id,preset=VehicleDriftPreset.id,enabled=enabled,fields={},mismatches=0,checked=0,metadata=VehicleDriftPreset.metadata,metadataNotOverridden={'handlingName','AIHandling','NULL subtype declarations'}}
 report.recovery=diagnostics[v] and diagnostics[v].id==id and MX.copy(diagnostics[v]) or nil
 for i,f in ipairs(fields) do
  local expected=enabled and f.value or (saved and saved.id==id and saved.values[i])
  local actual=read(v,f) local matches
  if expected~=nil then matches=equal(f,actual,expected) end
  if expected~=nil then report.checked=report.checked+1 if not matches then report.mismatches=report.mismatches+1 end end
  report.fields[#report.fields+1]={class=f.class,field=f.name,expected=clean(expected),actual=clean(actual),matches=matches}
 end
 local drive=enabled and presetDrive() or (saved and saved.drive)
 report.drive={gear=GetVehicleHighGear(v),poweredWheels={}}
 for wheel=0,3 do report.drive.poweredWheels[wheel+1]=powered(v,wheel) end
 if drive then
  report.drive.expected=drive
  if report.drive.gear~=drive.gear then report.mismatches=report.mismatches+1 end
  for wheel=1,4 do if report.drive.poweredWheels[wheel]~=drive.wheels[wheel] then report.mismatches=report.mismatches+1 end end
 end
 return report
end
function D.supported(v,id)
 if support[v] and support[v].id==id then return support[v].ok,support[v].reason end
 if GetVehicleNumberOfWheels(v)~=4 then return false,'O preset exige quatro rodas' end
 for _,f in ipairs(fields) do
  local ok,value=pcall(read,v,f)
  if not ok or not valid(f,value) then
   local reason='Modelo/build sem suporte a '..f.class..'.'..f.name
   support[v]={id=id,ok=false,reason=reason} return false,reason
  end
 end
 support[v]={id=id,ok=true} return true
end
function D.isApplied(v)
 local saved=snapshots[v]
 -- A retained snapshot also covers an unconfirmed rollback: keep manual off.
 return saved~=nil and identity(v,saved.id)
end
function D.set(v,id,enabled,forceRefresh)
 MX.require(identity(v,id),'OBSOLETE','O veículo foi substituído; atualize o menu')
 -- Synchronous: manual must restore its ratios/flags BEFORE baseline capture
 -- or any drift writes. A later per-frame shutdown could overwrite the preset.
 if enabled then TriggerEvent('mx:vehicles:beforeDriftHandling',v,id) end
 local saved=snapshots[v]
 if saved and saved.id~=id then snapshots[v]=nil saved=nil end
 if not enabled then
  if saved then
   for i,f in ipairs(fields) do write(v,f,saved.values[i]) end
   refreshDrive(v,saved.drive)
   for i,f in ipairs(fields) do MX.require(equal(f,read(v,f),saved.values[i]),'HANDLING','Não foi possível restaurar '..f.name) end
   local report=D.audit(v,id,false)
   MX.require(report.mismatches==0,'HANDLING','A restauração não passou no diagnóstico')
   restored[v]=saved snapshots[v]=nil
   return {enabled=false,checked=report.checked,mismatches=0,transmissionRefreshed=true}
  end
  return {enabled=false}
 end
 if saved and not forceRefresh then
  local report=D.audit(v,id,true)
  if report.mismatches==0 then return {enabled=true,checked=report.checked,mismatches=0,transmissionRefreshed=true} end
 end
 local values={}
 -- Preflight every field before the first mutation; missing car sub-handling is not silently skipped.
 for i,f in ipairs(fields) do
  local value=read(v,f)
  MX.require(valid(f,value),'HANDLING_UNSUPPORTED','Este modelo/build não expôs '..f.class..'.'..f.name)
  values[i]=f.kind=='Vector' and {x=value.x,y=value.y,z=value.z} or value
 end
 -- Reapplication/ownership changes must never replace the original baseline.
 saved=saved or {id=id,values=values,drive=captureDrive(v)} snapshots[v]=saved
 restored[v]=nil
 local report
 local ok,err=pcall(function()
  for _,f in ipairs(fields) do write(v,f,f.value) end
  refreshDrive(v,presetDrive())
  for _,f in ipairs(fields) do
   local actual=read(v,f)
   MX.require(equal(f,actual,f.value),'HANDLING','Não foi possível confirmar '..f.class..'.'..f.name..' (esperado '..tostring(f.value)..', lido '..tostring(actual)..'). Verifique a definição de handling do modelo e recrie o carro após corrigir o resource.')
  end
  report=D.audit(v,id,true)
  MX.require(report.mismatches==0,'HANDLING','O diagnóstico detectou divergências após recalcular a transmissão')
 end)
 if not ok then
  local restored,restoreError=pcall(D.set,v,id,false)
  if not restored then MX.fail('HANDLING_RESTORE','Falha de aplicação: '..MX.diagnostic(err)..'. Restauração sem confirmação: '..MX.diagnostic(restoreError)) end
  error(err,0)
 end
 saved.control=NetworkHasControlOfEntity(v)
 return {enabled=true,checked=report.checked,mismatches=report.mismatches,transmissionRefreshed=true}
end
-- Drift is optional presentation/gameplay state. Keep strict set()/audit(), but
-- recover its failure without failing the vehicle's spawn/cosmetic ACK.
function D.ensure(v,id,enabled,notify)
 MX.require(identity(v,id),'OBSOLETE','O veículo foi substituído; atualize o menu')
 local failure,recovered,attempts
 for attempt=1,(enabled and 2 or 1) do
  attempts=attempt
  local ok,result=pcall(D.set,v,id,enabled,true)
  MX.require(identity(v,id),'OBSOLETE','O veículo foi substituído durante a recuperação')
  if ok then
   failed[v]=nil diagnostics[v]=nil
   result.requested=enabled result.recovered=true result.attempts=attempt
   if attempt>1 then print('[MX:DRIFT] '..json.encode({level='warn',code='HANDLING_RETRIED',id=id,attempts=attempt,detail=failure.message})) end
   return result
  end
  failure=MX.error(result)
  if failure.code=='OBSOLETE' then error(result,0) end
  if failure.code=='UNAVAILABLE' then failure={code='HANDLING_INTERNAL',message=MX.diagnostic(result)} end
  -- set() already attempts rollback after mutation. Verify/reset again before
  -- retrying, and never capture a partial preset as a new original baseline.
  local reset
  recovered,reset=pcall(D.set,v,id,false)
  MX.require(identity(v,id),'OBSOLETE','O veículo foi substituído durante a restauração')
  if not enabled and recovered then
   diagnostics[v]=nil failed[v]=nil
   reset.requested=false reset.recovered=true reset.attempts=2
   print('[MX:DRIFT] '..json.encode({level='warn',code='HANDLING_RESTORED',id=id,detail=failure.message}))
   return reset
  end
  if not recovered or not enabled or failure.code=='HANDLING_UNSUPPORTED' then break end
 end
 local warning=recovered and 'Não foi possível aplicar o drift. O carro está disponível com o handling original. Diagnóstico no F8.' or 'O handling não foi confirmado. O carro está disponível; recrie-o para recuperar a configuração original. Diagnóstico no F8.'
 local result={id=id,enabled=false,requested=enabled,fallback=true,recovered=recovered,uncertain=not recovered,code=failure.code,warning=warning,attempts=attempts,detail=failure.message}
 diagnostics[v]=result failed[v]=id
 print('[MX:DRIFT] '..json.encode({level='warn',preset=VehicleDriftPreset.id,recovery=result}))
 if notify then TriggerEvent('mx:notice',warning) end
 return result
end
-- Handling overrides are local. Every streaming client applies the server-published identity/state.
CreateThread(function()
 while true do
  Wait(500)
  for _,v in ipairs(GetGamePool('CVehicle')) do
   local state=Entity(v).state local wanted=state.mxDrift
   if type(wanted)=='table' and wanted.id==state.mxVehicle and wanted.preset==VehicleDriftPreset.id then
    local saved=snapshots[v]
    if wanted.enabled==true and not saved and failed[v]~=wanted.id then
     local ok,err=pcall(D.ensure,v,wanted.id,true,false)
     if not ok then failed[v]=wanted.id print('[MX:DRIFT] '..MX.error(err).message) end
    elseif wanted.enabled==true and saved then
     local control=NetworkHasControlOfEntity(v)
     if control and not saved.control then
      local ok,err=pcall(D.ensure,v,wanted.id,true,false)
      if not ok then failed[v]=wanted.id print('[MX:DRIFT] '..MX.error(err).message) end
     end
     saved.control=control
    elseif wanted.enabled==false then
     if saved and (failed[v]~=wanted.id or (diagnostics[v] and diagnostics[v].requested~=false)) then pcall(D.ensure,v,wanted.id,false,false)
     elseif not saved then failed[v]=nil end
    end
   end
  end
  for v,saved in pairs(snapshots) do if not identity(v,saved.id) then snapshots[v]=nil end end
  for v,saved in pairs(support) do if not identity(v,saved.id) then support[v]=nil failed[v]=nil end end
  for v,id in pairs(failed) do if not identity(v,id) then failed[v]=nil end end
  for v,saved in pairs(restored) do if not identity(v,saved.id) then restored[v]=nil end end
  for v,saved in pairs(diagnostics) do if not identity(v,saved.id) then diagnostics[v]=nil end end
 end
end)
RegisterCommand('mxhandling',function()
 CreateThread(function()
  local ok,result=pcall(MX.request,'vehicles','handlingAudit',{})
  if not ok then print('[MX:HANDLING] '..MX.error(result).message)
  elseif not result.ok then print('[MX:HANDLING] '..tostring(result.message))
  else print('[MX:HANDLING] '..json.encode(result.data)) end
 end)
end,false)
AddEventHandler('onClientResourceStop',function(name)
 if name==GetCurrentResourceName() then for v,saved in pairs(snapshots) do if identity(v,saved.id) then pcall(D.set,v,saved.id,false) end end end
end)
