-- Deterministic unit scheduler ONLY. These natives are test doubles, not a
-- substitute for FiveM/multiplayer entity validation or production code.
PreviewTest={exports={},events={},entities={},actors={[7]={epoch='epoch'}},nextEntity=100,time=0}
local T=PreviewTest
exports=setmetatable({['mx-freeroam-core']={BootId=function() return 'unit-boot' end}}, {__call=function(_,name,fn) T.exports[name]=fn end})
function GetCurrentResourceName() return 'unit-preview' end
function SaveResourceFile() end
function LoadResourceFile() return nil end
function AddEventHandler(name,fn) T.events[name]=fn end
function CreateThread() end
function GetPlayerRoutingBucket() return 10007 end
function GetEntityRoutingBucket() return 10007 end
function SetEntityRoutingBucket() end
function SetEntityOrphanMode() end
function GetGameTimer() return T.time end
function Wait() T.time=T.time+1 end
function joaat(model) return model end
function CreateVehicleServerSetter(model) T.nextEntity=T.nextEntity+1 T.entities[T.nextEntity]={model=model,state={}} return T.nextEntity end
function DoesEntityExist(id) return T.entities[id]~=nil end
function DeleteEntity(id) T.entities[id]=nil end
function NetworkGetNetworkIdFromEntity(id) return id end
function NetworkGetEntityFromNetworkId(id) return id end
function Entity(id) local state=T.entities[id].state state.set=function(_,key,value) state[key]=value end return {state=state} end
json.encode=function() return '{}' end
MX.actor=function(src) return T.actors[src] end
MX.copy=function(value) local t={} for k,v in pairs(value) do t[k]=type(v)=='table' and MX.copy(v) or v end return t end
local sequence=0
MX.uuid=function() sequence=sequence+1 return 'unit-'..sequence end
MX.callClient=function(_,_,action,data) return coroutine.yield(action,data) end
