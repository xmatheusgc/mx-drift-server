DisplayTest={time=0,tasks={},entities={},calls={},events={},commands={},hooks={},nextId=0,loaded=true,caller='mx-freeroam-experience'}
local T=DisplayTest
function IsDuplicityVersion()return false end
function RegisterNetEvent(name,fn)T.events[name]=fn end
function AddEventHandler(name,fn)T.hooks[#T.hooks+1]={name=name,fn=fn}end
function RegisterCommand(name,fn)T.commands[name]=fn end
function GetCurrentResourceName()return 'mx-freeroam-vehicles'end
function GetInvokingResource()return T.caller end
function GetResourceState()return 'started'end
function GetGameTimer()return T.time end
function Wait(ms)return coroutine.yield(math.max(ms,1))end
function CreateThread(fn)T.tasks[#T.tasks+1]={co=coroutine.create(fn),at=T.time}end
function T.step(ms)
 local deadline=T.time+ms
 while true do
  local task for _,v in ipairs(T.tasks)do if coroutine.status(v.co)~='dead' and v.at<=deadline and (not task or v.at<task.at)then task=v end end
  if not task then break end
  T.time=task.at local ok,delay=coroutine.resume(task.co)assert(ok,delay)task.at=T.time+(delay or 1)
 end T.time=deadline
end
function T.live()local n=0 for _,v in pairs(T.entities)do if v.exists then n=n+1 end end return n end
function DoesEntityExist(v)return T.entities[v] and T.entities[v].exists or false end
function GetEntityModel(v)return T.entities[v].model end
function Entity(v)return {state=T.entities[v].state}end
function joaat(model)return model end
function IsModelInCdimage(model)return model~='invalid'end
function IsModelAVehicle()return true end
function RequestModel(hash)T.requested=hash T.modelRequests=(T.modelRequests or 0)+1 end
function HasModelLoaded()return T.loaded end
function SetModelAsNoLongerNeeded(hash)T.released=hash end
function NetworkGetEntityIsNetworked()return T.networked or 0 end
function CreateVehicle(model,x,y,z,h,network,script)
 assert(network==false and script==false,'display must be local')
 T.nextId=T.nextId+1 local id=T.nextId
 local state={}function state:set(k,v,replicated)assert(replicated==false)self[k]=v end
 T.entities[id]={exists=true,model=model,state=state,point={x,y,z,h}}
 return id
end
function DeleteEntity(v)if not T.failDelete then T.entities[v].exists=false end end
for _,name in ipairs({'SetEntityAsMissionEntity','SetEntityInvincible','SetVehicleDoorsLocked','SetVehicleUndriveable','SetVehicleEngineOn','SetVehicleHandbrake','SetVehicleLights','SetVehicleNeonLightEnabled','SetVehicleDirtLevel','SetEntityCollision','FreezeEntityPosition','SetEntityDynamic','SetEntityLodDist','SetVehicleOnGroundProperly'})do
 _G[name]=function(v,...)T.entities[v][name]={...}end
end
function SetEntityVisible(v,visible)if visible then assert(T.entities[v].properties,'appearance before visibility')end T.entities[v].visible=visible end
VehicleProperties={validate=function(p)assert(type(p)=='table' and not p.invalid,'bad properties')return p end}
VehicleDisplay={apply=function(v,p)if T.failApply then error('cosmetic failure')end T.entities[v].properties=p end}
VehicleStance={refresh=function(v)T.entities[v].stance=true end}
json={encode=function()return '{}'end}
exports=setmetatable({}, {__call=function(self,name,fn)self[name]=fn end})
function TriggerEvent()end
function OverrideLodscaleThisFrame(scale)T.lod=scale T.lodCalls=(T.lodCalls or 0)+1 end
