local T=TrainerMenuTest
local poll=T.threads[2]
local pad=false
MenuBindings={list=function()return {{id='menu',pad='VIEW'}}end,input=function()return pad end,padInput=function()return pad end}
IsInputDisabled=function()return false end
T.nui('close')
pad=true T.tick(poll)
assert(T.focused and T.cursor==false,'controller opens trainer without cursor')
assert(T.disabled[0] and T.disabled[244],'controller opening consumes native camera and interaction actions')
local count=#T.messages T.tick(poll)T.tick(poll)
assert(T.focused and #T.messages==count,'holding pad does not retrigger')
pad=false T.tick(poll)pad=true T.tick(poll)
assert(T.focused,'server open-menu binding cannot override native navigation while focused')
local cancel=false
IsDisabledControlPressed=function(_,control)return cancel and control==202 end
T.tick(T.threads[3])cancel=true T.tick(T.threads[3])cancel=false
assert(T.messages[#T.messages].type=='nav' and T.messages[#T.messages].key=='back','native cancel is the navigation exit')
T.nui('close')
pad=false T.tick(poll)
T.workshop=true pad=true T.tick(poll)assert(not T.focused,'workshop prevents trainer opening')
T.workshop=false pad=false T.tick(poll)
IsPauseMenuActive=function()return true end
pad=true T.tick(poll)assert(not T.focused,'pause prevents trainer opening')
IsPauseMenuActive=function()return false end
pad=false T.tick(poll)
pad=true T.tick(poll)assert(T.focused,'controller works again after leaving pause')
T.nui('navigationContext',{modal=true})
pad=false T.tick(poll)pad=true T.tick(poll)
assert(T.focused,'text modal cannot be closed by menu pad')
T.nui('navigationContext',{modal=false})T.nui('close')
print('Controller menu: opening/closing, held-button edge, native camera suppression, workshop/pause and modal guards passed with input doubles.')
