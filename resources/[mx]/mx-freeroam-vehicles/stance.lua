-- Native visual geometry inspired by VStancer. No handling or menu dependency.
VehicleStance={}
local S=VehicleStance local bases,active,pending={},{},{}
local limits={}
local function positive(n) return type(n)=='number' and n>0 and n<math.huge end
local function valid(v,b) return DoesEntityExist(v) and Entity(v).state.mxVehicle==b.id and GetEntityModel(v)==b.model end
local function key(v) return GetVehicleWheelType(v)..':'..GetVehicleMod(v,23)..':'..GetVehicleMod(v,24) end
function S.supported(v) return IsThisModelACar(GetEntityModel(v)) and GetVehicleNumberOfWheels(v)==4 end
function S.awaitReady(v,id,value,timeout)
 value=VehicleStanceRules.validate(value)
 if not value or not IsThisModelACar(GetEntityModel(v)) then return true end
 local model=GetEntityModel(v) local deadline=GetGameTimer()+(timeout or 750)
 while true do
  MX.require(DoesEntityExist(v) and Entity(v).state.mxVehicle==id and GetEntityModel(v)==model,'OBSOLETE','Veículo substituído durante a preparação das rodas')
  local wheels=GetVehicleNumberOfWheels(v)
  local tuning=GetVehicleMod(v,23)>=0
  local ready=wheels>0 and (not tuning or ((value.wheelSize==1 or positive(GetVehicleWheelSize(v))) and (value.wheelWidth==1 or positive(GetVehicleWheelWidth(v)))))
  if ready then return true end
  if GetGameTimer()>=deadline then return false end
  Wait(0)
 end
end
local function capture(v,id)
 local b={id=id,model=GetEntityModel(v),key=key(v),size=GetVehicleWheelSize(v),width=GetVehicleWheelWidth(v),height=GetVehicleSuspensionHeight(v),offset={},rotation={}}
 for i=0,3 do b.offset[i]=GetVehicleWheelXOffset(v,i) b.rotation[i]=GetVehicleWheelYRotation(v,i) end
 bases[v]=b return b
end
function S.restore(v)
 local b=bases[v] if not b or not valid(v,b) then return end
 SetVehicleSuspensionHeight(v,b.height)
 if GetVehicleMod(v,23)>=0 then
  if b.sizeApplied and positive(b.size) then SetVehicleWheelSize(v,b.size) end
  if b.widthApplied and positive(b.width) then SetVehicleWheelWidth(v,b.width) end
 end
 for i=0,3 do SetVehicleWheelXOffset(v,i,b.offset[i]) SetVehicleWheelYRotation(v,i,b.rotation[i]) end
end
function S.check(v,value)
 value=VehicleStanceRules.validate(value) if not value then return end
 MX.require(S.supported(v),'STANCE','Suspensão visual disponível em carros com quatro rodas')
 MX.require((value.wheelSize==1 and value.wheelWidth==1) or GetVehicleMod(v,23)>=0,'STANCE','Instale rodas de personalização antes de alterar tamanho/largura')
end
local function draw(v,s)
 if not valid(v,s.base) then return false end
 local b,p=s.base,s.value
 local l=limits[v] local blocked=l and l.id==b.id and l.key==key(v) and l.fields or {}
 -- Tuning/repair natives may reset size/width. Restore the intended visual
 -- values without capturing already modified geometry as a new default.
 -- A rebuilt wheel mesh can lose its scale while the getter still returns
 -- the requested value. Reassert confirmed custom dimensions, not readback
 -- differences; neutral/unsupported wheels retain their existing guards.
 if GetVehicleMod(v,23)>=0 then
  local initialized=false
  -- Mod indices can arrive before render dimensions on cold spawn/stream-in.
  -- Initialize missing baselines on a later frame without opening an editor.
  if not positive(b.size) then
   local size=GetVehicleWheelSize(v) if positive(size) then b.size=size initialized=true end
  end
  if not positive(b.width) then
   local width=GetVehicleWheelWidth(v) if positive(width) then b.width=width initialized=true end
  end
  if initialized then
   -- Confirm newly available dimensions through the normal guarded path,
   -- including native refusal handling, before continuous visual reassertion.
   local ok=pcall(S.ensure,v,b.id,p,false)
   return ok
  end
  if not blocked.wheelSize and p.wheelSize~=1 and positive(b.size) then SetVehicleWheelSize(v,b.size*p.wheelSize) end
  if not blocked.wheelWidth and p.wheelWidth~=1 and positive(b.width) then SetVehicleWheelWidth(v,b.width*p.wheelWidth) end
 end
 SetVehicleSuspensionHeight(v,b.height-p.height)
 for i=0,3 do
  local front=i<2 local side=i%2==0 and -1 or 1
  SetVehicleWheelXOffset(v,i,b.offset[i]+side*(front and p.frontOffset or p.rearOffset))
  SetVehicleWheelYRotation(v,i,b.rotation[i]+side*math.rad(front and p.frontCamber or p.rearCamber))
 end
 return true
end
function S.apply(v,id,value,authoritative)
 value=VehicleStanceRules.validate(value)
 MX.require(DoesEntityExist(v) and MX.text(id,1,64) and Entity(v).state.mxVehicle==id,'OBSOLETE')
 if not value and not bases[v] then return end
 if value then S.check(v,value) end
 local b=bases[v]
 -- Immutable baseline per entity identity/model; repeated changes and remote
 -- wheel-family updates must never compound the previous stance.
 if not b or not valid(v,b) then b=capture(v,id) end
 if not value then if authoritative then pending[v]=VehicleStanceRules.signature(value) end S.restore(v) active[v]=nil return end
 if GetVehicleMod(v,23)>=0 then
  local size,width=GetVehicleWheelSize(v),GetVehicleWheelWidth(v)
  -- Stock wheels (or render data not ready yet) can report zero. That is not
  -- a usable scale baseline: initialize each dimension on its first valid
  -- tuning-wheel reading, preserving any baseline already used successfully.
  if not positive(b.size) and positive(size) then b.size=size end
  if not positive(b.width) and positive(width) then b.width=width end
  -- A factor of 1 requests native dimensions, not support for resizing them.
  -- Only restore a dimension here if this controller previously changed it.
  local sizeNeeded=value.wheelSize~=1 or b.sizeApplied
  local widthNeeded=value.wheelWidth~=1 or b.widthApplied
  local wantedSize,wantedWidth=b.size*value.wheelSize,b.width*value.wheelWidth
  local sizeChanged=sizeNeeded and math.abs(size-wantedSize)>.0001
  local widthChanged=widthNeeded and math.abs(width-wantedWidth)>.0001
  local sizeResult=true local widthResult=true
  if sizeChanged then sizeResult=SetVehicleWheelSize(v,wantedSize) end
  if widthChanged then widthResult=SetVehicleWheelWidth(v,wantedWidth) end
  local sizeRead,widthRead=GetVehicleWheelSize(v),GetVehicleWheelWidth(v)
  -- CFX Lua may expose a native BOOL as integer 1. Readback remains mandatory.
  local sizeOk=not sizeChanged or ((sizeResult==true or sizeResult==1) and math.abs(sizeRead-wantedSize)<.001)
  local widthOk=not widthChanged or ((widthResult==true or widthResult==1) and math.abs(widthRead-wantedWidth)<.001)
  if not sizeOk or not widthOk then
   if sizeChanged then SetVehicleWheelSize(v,size) end
   if widthChanged then SetVehicleWheelWidth(v,width) end
   local failedResult=sizeResult if sizeOk then failedResult=widthResult end
   local detail=(' (baseline=%s, solicitado=%s, lido=%s, retorno=%s)'):format(tostring(not sizeOk and b.size or b.width),tostring(not sizeOk and wantedSize or wantedWidth),tostring(not sizeOk and sizeRead or widthRead),tostring(failedResult))
   MX.fail(not sizeOk and 'STANCE_SIZE' or 'STANCE_WIDTH','Não foi possível confirmar '..(not sizeOk and 'tamanho' or 'largura')..' personalizado das rodas'..detail)
  end
  b.sizeApplied=b.sizeApplied or value.wheelSize~=1
  b.widthApplied=b.widthApplied or value.wheelWidth~=1
 end
 if authoritative then pending[v]=VehicleStanceRules.signature(value) end
 active[v]={base=b,value=MX.copy(value)} draw(v,active[v])
end
function S.current(v) return active[v] and valid(v,active[v].base) and MX.copy(active[v].value) or false end
local function limitation(v,id)
 local l=limits[v]
 if not l or l.id~=id or l.model~=GetEntityModel(v) or l.key~=key(v) then
  l={id=id,model=GetEntityModel(v),key=key(v),fields={}} limits[v]=l
 end
 return l
end
function S.options(v)
 local l=limitation(v,Entity(v).state.mxVehicle)
 return {available=S.supported(v),tuningWheels=GetVehicleMod(v,23)>=0,ranges=VehicleStanceRules.ranges,unavailable=MX.copy(l.fields),value=S.current(v),warning=next(l.fields) and 'Alguns ajustes de roda não estão disponíveis com estas rodas. Os demais ajustes continuam disponíveis.' or nil}
end
-- Optional native wheel resizing must not reject the entire vehicle. Echo only
-- geometry actually accepted, so the server never persists a rejected factor.
function S.ensure(v,id,value,authoritative)
 value=VehicleStanceRules.validate(value)
 MX.require(DoesEntityExist(v) and Entity(v).state.mxVehicle==id,'OBSOLETE')
 local l=limitation(v,id)
 local effective=value and MX.copy(value) or false
 if effective and not S.supported(v) then effective=false end
 local function observed(field)
  local b=bases[v] local base=b and (field=='wheelSize' and b.size or b.width)
  local actual=field=='wheelSize' and GetVehicleWheelSize(v) or GetVehicleWheelWidth(v)
  local factor=base and base>0 and actual/base or 1
  local range=VehicleStanceRules.ranges[field]
  MX.require(MX.number(factor,range[1],range[2]),'STANCE_RESTORE','A dimensão da roda não pôde ser confirmada')
  return factor
 end
 if effective then
  for _,field in ipairs({'wheelSize','wheelWidth'}) do
   if GetVehicleMod(v,23)<0 then effective[field]=1
   elseif l.fields[field] then effective[field]=observed(field) end
  end
 end
 for _=1,3 do
  local ok,err=pcall(S.apply,v,id,effective,authoritative)
  if ok then return {value=S.current(v),warning=S.options(v).warning} end
  local failure=MX.error(err)
  local field=({STANCE_SIZE='wheelSize',STANCE_WIDTH='wheelWidth'})[failure.code]
  if not field or not effective then error(err,0) end
  if not l.fields[field] then
   l.fields[field]=field=='wheelSize' and 'Este conjunto de rodas não permite alterar o diâmetro.' or 'Este conjunto de rodas não permite alterar a largura.'
   print('[MX:STANCE] '..json.encode({level='warn',id=id,model=l.model,wheels=l.key,field=field,requested=effective[field],detail=failure.message}))
  end
  effective[field]=observed(field)
 end
 MX.fail('STANCE_RESTORE','Não foi possível confirmar a geometria anterior das rodas')
end
function S.refresh(v) return active[v] and draw(v,active[v]) or false end
local function receive(v,data)
 if type(data)~='table' or not MX.text(data.id,1,64) or Entity(v).state.mxVehicle~=data.id then return end
 local ok,value=pcall(VehicleStanceRules.validate,data.value) if not ok then return end
 local signature=VehicleStanceRules.signature(value)
 if pending[v] and pending[v]~=signature then return end
 pending[v]=nil
 local existing=active[v]
 if existing and existing.base.id==data.id and VehicleStanceRules.signature(existing.value)==signature then S.refresh(v) return end
 pcall(S.ensure,v,data.id,value,false)
end
AddStateBagChangeHandler('mxStance',nil,function(bag,_,data)
 local v=GetEntityFromStateBagName(bag) if v~=0 and DoesEntityExist(v) then receive(v,data) end
end)
CreateThread(function()
 while true do
  for _,v in ipairs(GetGamePool('CVehicle')) do receive(v,Entity(v).state.mxStance) end
  for v,b in pairs(bases) do if not valid(v,b) then bases[v]=nil active[v]=nil pending[v]=nil end end
  for v,l in pairs(limits) do if not valid(v,l) then limits[v]=nil end end
  Wait(1000)
 end
end)
CreateThread(function()
 while true do
  if next(active) then
   local player=GetEntityCoords(PlayerPedId())
   for v,s in pairs(active) do if not valid(v,s.base) then active[v]=nil elseif MX.distance(player,GetEntityCoords(v))<200 then S.refresh(v) end end
   Wait(0)
  else Wait(200) end
 end
end)
AddEventHandler('onClientResourceStop',function(r) if r==GetCurrentResourceName() then for v in pairs(bases) do S.restore(v) end end end)
