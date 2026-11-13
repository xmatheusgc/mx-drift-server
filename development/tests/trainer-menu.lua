local T=TrainerMenuTest
local nativeFade=T.threads[#T.threads-1] -- The pause-menu input loop follows the fade loop.
assert(not T.bindings.mxtrainer,'legacy native mappings replaced by per-profile registry')
T.commands.mxtrainer() assert(T.focused and T.keepInput,'opening trainer keeps gameplay input available')
assert(T.cursor==false,'trainer never captures the mouse cursor')
local count=#T.messages T.commands.mxtrainer() assert(#T.messages==count,'NUI handles M while focused; native mapping must not toggle twice')
local controls=T.threads[3] T.tick(controls) T.tick(controls)
assert(not T.allControls and not T.disabled[71] and not T.disabled[59] and T.disabled[176],'normal menu consumes frontend input, not throttle/steering')
assert(not T.disabled[1] and not T.disabled[2],'camera look remains available with keyboard-only trainer')
assert(T.nui('openWorkshop').ok and T.garageCalls==1,'return button calls OpenGarage directly, not lobby event')
T.garageFail=true assert(not T.nui('openWorkshop').ok,'garage failure cannot be reported as success') T.garageFail=false
assert(T.recoveries==1 and T.focused and not T.cursor and T.messages[#T.messages].type=='menuError','failed entry restores keyboard-only menu and publishes its error')
T.workshop=true T.events['mx:experience:freeCamera'](false)
assert(not T.cursor,'pending scene cannot capture mouse while trainer is still the visible UI')
T.events['mx:experience:state']({}) assert(T.cursor,'garage UI keeps mouse interaction')
T.workshop=false T.events['mx:experience:closed']() T.commands.mxtrainer()
T.nui('navigationContext',{modal=true}) T.tick(controls) assert(T.allControls,'text modal alone locks gameplay')
T.commands.mxnoclip() assert(#T.requests==0,'native shortcut is ignored while NUI owns the same shortcut')
T.nui('close') T.commands.mxnoclip() T.tick(T.threads[#T.threads])
assert(#T.requests==1 and T.requests[1].action=='toggleNoclip','F2 requests a server grant in one RPC without a preceding state query')
local n=#T.requests T.localActive=true T.commands.mxnoclip()
assert(T.localStops>=2,'F2 disables the local flight immediately, without a 200 ms throttle')
T.tick(T.threads[#T.threads])
assert(T.requests[#T.requests].action=='noclip' and T.requests[#T.requests].data.enabled==false,'immediate local stop reconciles an explicit off state with the server') T.localActive=false
local request=MX.request local prior=#T.requests
MX.request=function(...)coroutine.yield();return request(...)end
T.commands.mxnoclip() local pending=T.threads[#T.threads] T.tick(pending)
T.commands.mxnoclip() -- A second physical press during the pending grant.
MX.request=request T.tick(pending)
local queued=T.threads[#T.threads] T.tick(queued) T.tick(queued) T.tick(T.threads[#T.threads])
assert(#T.requests==prior+2,'a rapid second press is queued rather than lost while authorization is pending')
print('Actual menu bridge: M/F2/F3/F4 bindings, no double-dispatch, driving inputs retained, text-modal isolation, direct garage and failure propagation passed with runtime adapters.')

MenuBindings={list=function()return {{id='repair'}}end,input=function()return T.heldRepair end}
T.time=T.time+500 T.heldRepair=true local poll=T.threads[2] local before=#T.requests
T.tick(poll) -- Start coroutine at the first frame wait.
T.tick(poll) T.tick(T.threads[#T.threads])
assert(T.requests[#T.requests].domain=='vehicles' and T.requests[#T.requests].data.kind=='repair','repair shortcut uses server-owned vehicle service')
T.time=T.time+500 T.tick(poll) assert(#T.requests==before+1,'holding shortcut never repeats its action')
T.heldRepair=false T.tick(poll) T.heldRepair=true T.time=T.time+500 T.tick(poll) T.tick(T.threads[#T.threads])
assert(#T.requests==before+2,'release and press dispatches again')
print('Actual shortcut poll: repair server dispatch, held-key suppression and release/repress passed with input adapters.')
T.commands.mxmenu() T.localActive=true
assert(T.nui('noclipToggle').ok and T.requests[#T.requests].action=='noclip' and T.requests[#T.requests].data.enabled==false,'focused menu uses immediate local stop and explicit off reconciliation')
T.localActive=false T.nui('close')
assert(not T.nui('noclipToggle').ok,'focused toggle endpoint rejects calls outside the trainer menu')
function IsScreenFadingOut()return T.fadeOut or 0 end
function IsScreenFadedOut()return T.faded or false end
function IsScreenFadingIn()return T.fadeIn or false end
T.tick(nativeFade)assert(T.messages[#T.messages].type=='screenFade' and not T.messages[#T.messages].active,'integer native zero keeps interface visible')
T.fadeOut=1 T.tick(nativeFade)assert(T.messages[#T.messages].active,'native fade-out hides NUI')
local messages=#T.messages T.fadeOut=0 T.faded=true T.tick(nativeFade)
assert(#T.messages==messages,'solid black keeps NUI hidden without repeated messages')
T.faded=false T.fadeIn=true T.tick(nativeFade)assert(#T.messages==messages,'native fade-in remains covered until complete')
T.fadeIn=false T.tick(nativeFade)assert(not T.messages[#T.messages].active,'NUI restores after the native image finishes returning')
