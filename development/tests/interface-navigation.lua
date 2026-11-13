local now,keyboard=0,true local held={}local consumed={}
function GetGameTimer()return now end
function IsInputDisabled()return keyboard end
function IsDisabledControlPressed(_,control)return held[control]==true end
function GetDisabledControlNormal()return 0 end
function DisableControlAction(_,control)consumed[control]=true end
local gate={}
local function sample(input,options)held=input or {}now=now+20 return InterfaceNavigation.read(gate,options)end
sample()
assert(sample({[201]=true})=='enter','keyboard frontend accept is handled by native action')
assert(not sample({[201]=true}),'held accept never repeats')sample()
keyboard=false assert(sample({[201]=true})=='enter','controller uses the same native action')sample()
keyboard=true assert(sample({[200]=true})=='back','ESC native pause alternate backs out')sample()
assert(sample({[202]=true})=='back','native cancel backs out')sample()
assert(sample({[205]=true},{tabs=true})=='tabPrev','native LB/Q moves previous tab')sample()
assert(sample({[206]=true},{tabs=true})=='tabNext','native RB/E moves next tab')sample()
assert(sample({[203]=true},{settings=true})=='applySettings','native X/Space applies settings only in its context')sample()
assert(not sample({[203]=true}),'apply shortcut is inactive outside settings')sample()
assert(sample({[203]=true},{character=true})=='saveCharacter','native X/Space saves the character in its own context')sample()
assert(not sample({[205]=true},{tabs=false}),'no tab command without tabs')sample()
assert(not sample({[201]=true,[190]=true},{text=true}),'text editing cannot also navigate/submit natively')sample()
assert(sample({[190]=true})=='right','right arrow uses frontend control')
assert(consumed[201] and consumed[202] and consumed[205] and consumed[206],'native UI controls are consumed')
gate={}assert(not sample({[201]=true}),'held confirmation cannot enter a new context')sample()
assert(sample({[201]=true})=='enter','release arms the new context')
print('Shared native interface navigation passed: both devices, frontend action IDs, text isolation, tab context, repeat and cross-screen hold guards.')
