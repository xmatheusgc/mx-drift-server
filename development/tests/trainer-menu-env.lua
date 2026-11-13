TrainerMenuTest={threads={},events={},commands={},bindings={},callbacks={},messages={},focused=false,workshop=false,garageCalls=0,disabled={},allControls=false,requests={},time=1000}
local T=TrainerMenuTest
function CreateThread(fn) T.threads[#T.threads+1]=coroutine.create(fn) end
function Wait() coroutine.yield() end
function AddEventHandler(name,fn) T.events[name]=fn end
function RegisterNetEvent(name,fn) T.events[name]=fn end
function RegisterCommand(name,fn) T.commands[name]=fn end
function RegisterKeyMapping(name,_,_,key) T.bindings[name]=key end
function RegisterNUICallback(name,fn) T.callbacks[name]=fn end
function IsNuiFocused() return T.focused end
function SetNuiFocus(value,cursor) T.focused=value T.cursor=cursor end
function SetNuiFocusKeepInput(value) T.keepInput=value end
function SendNUIMessage(data) T.messages[#T.messages+1]=data end
function IsPauseMenuActive() return false end
function IsEntityDead() return false end
function GetGameTimer() return T.time end
function TriggerEvent(name,data) if T.events[name] then T.events[name](data) end end
function IsInputDisabled() return true end
function DisableControlAction(_,control) T.disabled[control]=true end
function DisableAllControlActions() T.allControls=true end
function IsDisabledControlJustPressed() return false end
function IsDisabledControlPressed() return false end
function GetDisabledControlNormal() return 0 end
MX.online=function() return true end
MX.request=function(domain,action,data)
 T.requests[#T.requests+1]={domain=domain,action=action,data=data}
 return {ok=true,data={noclip=action=='toggleNoclip' or action=='noclip' and data.enabled==true,speed=2}}
end
exports={['mx-freeroam-world']={StopLocalTrainer=function()T.localStops=(T.localStops or 0)+1 return T.localActive==true end},['mx-freeroam-experience']={
 InWorkshop=function()return T.workshop end,
 OpenGarage=function() T.garageCalls=T.garageCalls+1 return {ok=not T.garageFail,code=T.garageFail and 'TEST_FAILURE' or nil,message=T.garageFail and 'Entry failed'} end,
 RecoverEntry=function() T.recoveries=(T.recoveries or 0)+1 end
}}
function T.tick(thread) local ok,err=coroutine.resume(thread) assert(ok,err) end
function T.nui(name,data)
 local result T.callbacks[name](data or {},function(r)result=r end) T.tick(T.threads[#T.threads]) return result
end
