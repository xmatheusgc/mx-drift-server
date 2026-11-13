EntryClientFailureTest={exports={},control=true,frozen=false}
local T=EntryClientFailureTest
function GetResourceKvpInt()return 0 end
function RegisterCommand()end
function RegisterKeyMapping()end
function CreateThread()end
function AddEventHandler()end
function TriggerEvent()end
function SetPlayerControl(_,enabled)T.control=enabled end
function FreezeEntityPosition(_,frozen)T.frozen=frozen end
function GetVehiclePedIsIn()return 10 end
function GetEntitySpeed()return 0 end
function IsEntityPositionFrozen()return false end
MX.clients=function(_,handlers)T.handlers=handlers end
MX.request=function()return {ok=false,code='POSITION',message='A posição não foi confirmada'}end
exports=setmetatable({['mx-freeroam-experience']={SuspendDrivecam=function()end}}, {__call=function(_,name,fn)T.exports[name]=fn end})
