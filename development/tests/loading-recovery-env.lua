LoadingRecoveryTest={exports={},handlers={},frozen=false,control=true}
local T=LoadingRecoveryTest
json={encode=function(v)return v end,decode=function(v)return v end}
MX.clients=function(_,handlers)T.handlers=handlers end
MX.request=function()return {ok=true,data={sceneReady=true}}end
exports=setmetatable({['mx-freeroam-experience']={SuspendDrivecam=function()end},['mx-freeroam-world']={SetLobbyTime=function()end}}, {__call=function(_,name,fn)T.exports[name]=fn end})
WorkshopCameraDev={stop=function()end}
WorkshopDisplay={stop=function()end}
WorkshopIdle={stop=function()end}
WorkshopPresentation={stop=function()end}
WorkshopStreaming={stop=function()T.stopped=true end}
WorkshopTransfer={pending=function()return false end,finish=function()end,restore=function()if T.restore then T.restore()end return {recovered=true}end}
function TriggerEvent(name,data)
 if name=='mx:loading' then T.loading=data.active end
 if name=='mx:experience:lobby' then T.lobby=data end
end
function GetResourceKvpInt()return 0 end
function AddEventHandler()end
function RegisterCommand()end
function RegisterKeyMapping()end
function CreateThread()end
function Wait()end
function PlayerPedId()return 1 end
function PlayerId()return 0 end
function GetVehiclePedIsIn()return 0 end
function IsPedInAnyVehicle()return false end
function IsEntityPositionFrozen()return T.frozen end
function FreezeEntityPosition(_,value)T.frozen=value end
function SetPlayerControl(_,value)T.control=value end
function DoesEntityExist()return true end
function SetNuiFocus()end
function ClearPedTasksImmediately()end
function SetEntityCollision()end
function SetPedCanRagdoll()end
function SetEntityAlpha()end
function SetEntityInvincible()end
function SetEntityVisible()end
function SendLoadingScreenMessage()end
function DoScreenFadeIn()T.fade=true end
