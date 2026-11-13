AdminToolTest={time=0,events={},callbacks={},exports={},threads={},ace={},epoch=1,bucket=0,vehicle=0,ped=1,groundAt=300,sceneAt=500,waypoint=true,notices={},tripCount=0}
local T=AdminToolTest
MX.copy=function(v)if type(v)~='table'then return v end local r={}for k,x in pairs(v)do r[k]=MX.copy(x)end return r end
MX.actor=function()return {epoch=T.epoch,id=1}end
MX.online=function()return true end
MX.clients=function(domain,handlers)T.callbacks[domain]=handlers end
MX.routes=function(domain,handlers)T.routes=handlers end
MX.db=function()if T.onAudit then T.onAudit()end return {}end
json.encode=function()return '{}'end
function GetGameTimer()return T.time end
function Wait(ms)T.time=T.time+ms if T.onWait then T.onWait()end end
function CreateThread(fn)T.threads[#T.threads+1]=fn end
function AddEventHandler(name,fn)local previous=T.events[name] if previous then T.events[name]=function(...)previous(...)fn(...)end else T.events[name]=fn end end
function RegisterNetEvent(name,fn)T.events[name]=fn end
function RegisterCommand()end
function GetCurrentResourceName()return 'mx-freeroam-admin'end
function GetInvokingResource()return T.invoker or 'mx-freeroam-admin'end
function IsPlayerAceAllowed(_,ace)return T.ace[ace]==true end
function GetPlayerRoutingBucket()return T.bucket end
function GetResourceState()return 'started'end
function GetPlayerPed()return T.ped end
function PlayerPedId()return T.ped end
function GetVehiclePedIsIn()return T.vehicle end
function DoesEntityExist()return true end
function GetEntityHealth()return 200 end
function GetEntityCoords(entity)return {x=entity*10,y=-20,z=6}end
function GetEntityHeading()return 270 end
function GetEntityModel(entity)return entity*100 end
function GetInteriorFromEntity()return 42 end
function NetworkGetEntityIsNetworked()return true end
function NetworkGetNetworkIdFromEntity(entity)return entity+500 end
function GetDisplayNameFromVehicleModel()return 'FUTO'end
function GetFinalRenderedCamCoord()return {x=50,y=60,z=70}end
function GetFinalRenderedCamRot()return {z=-90}end
function GetFirstBlipInfoId()return 8 end
function DoesBlipExist()return T.waypoint end
function GetBlipCoords()return {x=1000,y=2000,z=0}end
function SetFocusPosAndVel()T.focus=true end
function ClearFocus()T.focus=false end
function NewLoadSceneStartSphere()T.loading=true return true end
function NewLoadSceneStop()T.loading=false end
function IsNewLoadSceneLoaded()return T.time>=T.sceneAt end
function RequestCollisionAtCoord()end
function GetGroundZFor_3dCoord()return T.time>=T.groundAt,40 end
function TriggerEvent(name,data)T.notices[name]=data end
function TriggerClientEvent(name,_,data)local old=source source=65535 if T.events[name]then T.events[name](data)end source=old end
MX.callClient=function(_,domain,action,data)
 if T.onCall then T.onCall()end
 return T.callbacks[domain][action](data)
end
AdminModeration={}
function AdminModeration.allowed(_,action)return T.ace['mx.admin'] and T.ace['mx.'..action] or false end
function AdminModeration.authorize(src,action)MX.require(AdminModeration.allowed(src,action),'FORBIDDEN')end
exports=setmetatable({
 ['mx-freeroam-experience']={IsPrivate=function()return T.private end},
 ['mx-freeroam-vehicles']={OwnedDriver=function()MX.require(not T.passenger and not T.otherOwner and not T.occupied,'PASSENGER')return {entity=T.vehicle}end,Inspect=function()return {}end,PreviewInspect=function()return {}end},
 ['mx-freeroam-activities']={Inspect=function()return {}end}
},{__call=function(_,name,fn)T.exports[name]=fn end})
WorldTrainer={travel=function(src,id,car,point,checkpoint)T.tripCount=T.tripCount+1 T.trip={src=src,id=id,car=car,point=point,checkpoint=checkpoint}return {destination=id}end}
