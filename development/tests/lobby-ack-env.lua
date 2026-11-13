-- Real client exports with only runtime/transport adapters replaced.
LobbyAckTest={exports={},handlers={},threads={},events={},messages={},time=0,shutdown=0,fades=0}
local T=LobbyAckTest
exports=setmetatable({['mx-freeroam-experience']={SuspendDrivecam=function()end},['mx-freeroam-world']={SetLobbyTime=function()end}}, {__call=function(_,name,fn) T.exports[name]=fn end})
MX.clients=function(_,handlers) T.handlers=handlers end
MX.request=function()return {ok=true,data={}}end
json.encode=function(v)return v end
function CreateThread(fn)T.threads[#T.threads+1]=fn end
function GetGameTimer()return T.time end
function Wait(ms)T.time=T.time+(ms or 0) local hook=T.onWait T.onWait=nil if hook then hook()end end
function IsEntityPositionFrozen()return false end
function SetPlayerControl()end
function PlayerId()return 1 end
function SetNuiFocus()end
function SendLoadingScreenMessage(m)T.messages[#T.messages+1]=m end
function ShutdownLoadingScreen()T.shutdown=T.shutdown+1 end
function ShutdownLoadingScreenNui()T.shutdown=T.shutdown+1 end
function DoScreenFadeIn()T.fades=T.fades+1 end
function TriggerEvent(name,data)T.events[#T.events+1]={name=name,data=data} end
function AddEventHandler()end
WorkshopIdle={stop=function()end,update=function()end} -- Animation controller has its own native-adapter suite.
