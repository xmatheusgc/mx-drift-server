VehicleOptionsTest={cars={},peds={[1]={x=10,y=20,z=6,car=0},[2]={x=10,y=20,z=6,car=0}},actors={[1]={id=11,epoch='one'},[2]={id=22,epoch='two'}},exports={},time=10000,seq=10,calls={},created=0,deleted=0}
local T=VehicleOptionsTest
local function clone(v)if type(v)~='table' then return v end local r={} for k,x in pairs(v)do r[k]=clone(x)end return r end
MX.distance=function(a,b)return math.sqrt((a.x-b.x)^2+(a.y-b.y)^2+(a.z-b.z)^2)end
MX.copy=clone MX.actor=function(src)return T.actors[src]end MX.online=function()return true end
MX.uuid=function()T.uuid=(T.uuid or 0)+1 return 'managed-'..T.uuid end
T.saved={}
MX.db=function(sql,args)
 if T.failDatabase then error('database unavailable') end
 if sql:find('SELECT p.id,p.name,p.model',1,true) then local rows={} for _,row in pairs(T.saved)do if row.player_id==args[1]then rows[#rows+1]=clone(row)end end return rows end
 if sql=='SELECT * FROM garage_presets WHERE player_id=? AND id=?' then
  local row=T.saved[args[2]] return row and row.player_id==args[1] and {clone(row)} or {}
 elseif sql=='SELECT COUNT(*) n FROM garage_presets WHERE player_id=?' then local n=0 for _,row in pairs(T.saved)do if row.player_id==args[1] then n=n+1 end end return {{n=n}}
 elseif sql=='SELECT id FROM garage_presets WHERE id=?' then return T.saved[args[1]] and {{id=args[1]}} or {} end
 assert(sql=='UPDATE garage_presets SET drift_enabled=? WHERE id=? AND player_id=?','unexpected vehicle SQL: '..sql)
 local row=T.saved[args[2]]
 if row and row.player_id==args[3] then row.drift_enabled=args[1] return {affectedRows=1} end
 return {affectedRows=0}
end
MX.tx=function(queries)
 if T.failDatabase then error('database unavailable') end
 for _,q in ipairs(queries)do
  if q.query:find('INSERT INTO garage_presets',1,true) then
   local a=q.values assert(not T.saved[a[1]]) T.saved[a[1]]={id=a[1],player_id=a[2],name=a[3],model=a[4],properties=a[5],schema_version=a[6],drift_enabled=a[7],revision=1}
  else MX.db(q.query,q.values) end
 end
end
MX.routes=function(_,routes)T.routes=routes end
MX.callClient=function(src,domain,action,d)
 T.calls[#T.calls+1]={src=src,action=action,data=d}
 if T.swapOnCall then T.cars[d.net].state.mxVehicle='reused' T.swapOnCall=false end
 if action=='load' then
  if T.moveDuringLoad and T.cars[T.peds[src].car] then T.cars[T.peds[src].car].x=T.cars[T.peds[src].car].x+100 T.peds[src].x=T.cars[T.peds[src].car].x end
  return {loaded=not T.failLoad}
 end
 if action=='apply' then
  if T.failApply then return {applied=false} end
  T.peds[src].car=d.net T.cars[d.net].driver=src T.cars[d.net].properties=clone(d.properties)
  assert(d.departure==false,'trainer respawn must not inherit the showroom freeze/handbrake departure')
  local drift=d.drift and (T.failDriftApply and {enabled=false,fallback=true,recovered=not T.failDriftRestore,warning='Drift indisponível; carro preservado'} or {enabled=true,recovered=true,transmissionRefreshed=true}) or nil
  return {applied=true,extras={},drift=drift}
 elseif action=='serviceInfo' then return {streamed=true,doors={0,1,4,5},driftSupported=not T.unsupported} end
 if action=='handlingAudit' then return {checked=51,mismatches=0,enabled=d.enabled} end
 if action=='eject' then T.peds[src].car=0 return {left=true} end
 if action=='prepareRespawn' then
  T.cars[d.net].frozen=true
  if T.failPrepare then return {ready=false,reason='EXIT_TIMEOUT'} end
  T.peds[src].car=0 T.cars[d.net].driver=0 return {ready=true}
 end
 if action=='resumeRespawn' then
  if T.failResume then error('rollback ACK unavailable') end
  T.resumed=true if T.cars[d.net]then T.cars[d.net].frozen=false end return {resumed=true}
 end
 if action=='service' then
  if d.kind=='repair' and T.softRepair then return {drift={enabled=false,fallback=true,recovered=true,warning='Drift indisponível após reparo'},warning='Drift indisponível após reparo'} end
  if d.kind=='drift' then if T.failDrift then error('client drift failed')end if T.softDrift then return {enabled=false,fallback=true,recovered=true,warning='Drift indisponível; carro preservado'} end return {enabled=d.enabled,transmissionRefreshed=not T.legacyDrift,checked=51,mismatches=0} end
  return {locked=true}
 end
 return {}
end
function GetPlayerPed(src)return tonumber(src) end
function GetPlayers()return {'1','2'}end
function GetPlayerRoutingBucket()return T.bucket or 0 end
function GetEntityRoutingBucket(v)return T.cars[v].bucket end
function SetEntityRoutingBucket(v,bucket)T.cars[v].bucket=bucket end
function GetEntityCoords(e)local p=T.cars[e] or T.peds[e] return {x=p.x,y=p.y,z=p.z}end
function GetEntityHeading(v)local entity=T.cars[v] or T.peds[v] return entity.h or 0 end
function GetEntityHealth()return T.dead and 0 or 200 end
function GetEntitySpeed(v)return T.cars[v].speed or 0 end
function GetVehiclePedIsIn(p)return T.peds[p].car end
function GetPedInVehicleSeat(v,seat)return seat==-1 and T.cars[v].driver or 0 end
function DoesEntityExist(e)return T.cars[e]~=nil or T.peds[e]~=nil end
function GetGameTimer()return T.time end
function Wait(ms)T.time=T.time+math.max(ms or 0,1)end
function CreateVehicleServerSetter(_,_,x,y,z,h)
 for _,car in pairs(T.cars)do assert(not T.respawning or car.x~=x or car.y~=y,'old car must be removed before replacement')end
 T.seq=T.seq+1 T.cars[T.seq]={x=x,y=y,z=z,h=h,driver=0,bucket=0,state={}}
 T.created=T.created+1 return T.seq
end
function DeleteEntity(e)if not T.failDelete then T.cars[e]=nil T.deleted=T.deleted+1 end end
function NetworkGetNetworkIdFromEntity(e)return e end
function SetEntityOrphanMode()end
function Entity(e)local state=T.cars[e].state state.set=function(self,key,value)self[key]=value end return {state=state}end
function joaat(v)return v end
function CreateThread()end
function GetCurrentResourceName()return 'mx-freeroam-vehicles'end
function AddEventHandler()end
exports=setmetatable({
 ['mx-freeroam-vehicles']={SavedList=function(_,...)return T.exports.SavedList(...)end,Saved=function(_,...)return T.exports.Saved(...)end,PrepareSaved=function(_,...)return T.exports.PrepareSaved(...)end},
 ['mx-freeroam-experience']={IsPrivate=function()return T.private end},
 ['mx-freeroam-world']={TrainerActive=function()return T.flying end,Release=function()end,StopTrainer=function()T.flying=false end,Reserve=function(_,_,_,point)return {point=point,key='trainer-slot'}end},
 ['mx-freeroam-activities']={Invalidate=function()T.invalidations=(T.invalidations or 0)+1 end}
},{__call=function(_,name,fn)T.exports[name]=fn end})
VehicleConfig={schema=1,presetLimit=20,cooldown=5000,maxActivePerPlayer=1,catalog={futo={id='futo',model='futo',source='vehicles',brand='KARIN'},elegy={id='elegy',model='elegy',source='vehicles',brand='ANNIS'}}}
VehicleProperties={defaults=function()return {}end,validate=clone,publish=function()end,signature=function()return 'properties-signature'end}
VehicleProperties.acceptStance=function(p,result)local accepted=clone(p)if result.stance then accepted.stance=clone(result.stance.value)end return accepted end
