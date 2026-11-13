local T=ManagementTest
local kvp={}
function SetResourceKvp(k,v)kvp[k]=v end
function GetResourceKvpString(k)return kvp[k] end
local keyboard=true
function IsInputDisabled()return keyboard end
function IsRawKeyDown(key)return key==84 end
function IsRawKeyPressed(key)return key==84 end
function IsControlJustPressed()return false end
function IsControlPressed()return false end
function IsDisabledControlJustPressed(_,control)return not keyboard and control==205 end
function IsDisabledControlPressed(_,control)return control==205 end
function SendNUIMessage()end
assert(not pcall(MenuBindings.update,'repair','key','T'),'requires known player identity')
T.events['mx:profile:local']({id=10})
assert(not pcall(MenuBindings.update,'confirm','key','T') and not pcall(MenuBindings.update,'tabNext','pad','A'),'basic UI navigation is not an editable server binding')
assert(MenuBindings.list()[1].pad=='VIEW','new profiles default to View/touchpad')
assert(MenuBindings.list()[2].key=='R','repair defaults to R')
local byId={}for _,b in ipairs(MenuBindings.list())do byId[b.id]=b end
assert(byId.engine.key=='G' and byId.engine.pad=='LEFT','engine defaults')
assert(byId.indicatorLeft.key=='LEFT' and byId.indicatorRight.key=='RIGHT' and byId.hazards.key=='DOWN','indicator keys')
assert(byId.indicatorLeft.pad=='' and byId.indicatorRight.pad=='' and byId.hazards.pad=='','indicators have no pad defaults')
assert(not pcall(MenuBindings.update,'repair','key','F2'),'duplicate key rejected')
assert(not pcall(MenuBindings.update,'repair','key','F8'),'console key reserved')
assert(not pcall(MenuBindings.update,'repair','key','T;quit'),'no command injection or arbitrary key strings')
MenuBindings.update('repair','key','T') assert(MenuBindings.input('repair',false),'new key dispatches correct action')
MenuBindings.update('repair','pad','LB') keyboard=false assert(MenuBindings.input('repair',false),'optional controller binding dispatches correct action') keyboard=true
T.events['mx:profile:local']({id=11}) assert(MenuBindings.list()[2].key=='R','profiles cannot inherit another profile bindings')
T.events['mx:profile:local']({id=10}) assert(MenuBindings.list()[2].key=='T','bindings restored from per-profile persistent storage')
MenuBindings.update('repair','key','') assert(not MenuBindings.input('repair',false),'removed binding no longer dispatches')
MenuBindings.update('clean','key','T') assert(MenuBindings.input('clean',true),'unbound action can receive a shortcut')
for _,shift in ipairs({16,160,161}) do
 IsRawKeyDown=function(key)return key==shift end
 IsRawKeyPressed=function(key)return key==shift end
 assert(MenuBindings.input('cycleSpeed',false) and MenuBindings.input('cycleSpeed',true),'generic and physical Shift keys dispatch speed binding')
end
MenuBindings.update('cycleSpeed','key','')
assert(not MenuBindings.input('cycleSpeed',false),'removing Shift disables the shortcut')
keyboard=false
IsControlPressed=function(_,control)return control==244 end
IsDisabledControlPressed=function()return false end
assert(MenuBindings.padInput('menu',true),'enabled View/touchpad is read')
IsControlPressed=function()return false end
IsDisabledControlPressed=function(_,control)return control==244 end
assert(MenuBindings.padInput('menu',true),'consumed View/touchpad is still read')
keyboard=true assert(not MenuBindings.padInput('menu',true),'native keyboard M cannot bypass configured raw key')
keyboard=false
kvp['bindings:12']=json.encode({menu={key='P',pad=''},repair={key='T',pad='LB'}})
T.events['mx:profile:local']({id=12})
assert(MenuBindings.list()[1].pad=='VIEW' and MenuBindings.list()[1].key=='P' and MenuBindings.list()[2].pad=='LB','legacy empty pad migrates without resetting remaps')
assert(json.decode(kvp['bindings:12'])._version==3,'migration is persisted')
MenuBindings.update('menu','pad','') T.events['mx:profile:local']({id=12})
assert(MenuBindings.list()[1].pad=='' and not MenuBindings.padInput('menu',true),'explicit removal survives reconnect after migration')
MenuBindings.update('menu','pad','VIEW')
assert(not pcall(MenuBindings.update,'repair','pad','VIEW'),'View collision is rejected')
MenuBindings.update('menu','pad','Y') T.events['mx:profile:local']({id=12})
assert(MenuBindings.list()[1].pad=='Y','custom menu pad survives reconnect')
MenuBindings.update('engine','key','')MenuBindings.update('engine','pad','')
T.events['mx:profile:local']({id=12})
byId={}for _,b in ipairs(MenuBindings.list())do byId[b.id]=b end
assert(byId.engine.key=='' and byId.engine.pad=='','explicit engine removals survive versioned save')
MenuBindings.update('menu','pad','VIEW')
IsDisabledControlPressed=function(_,c)return c==244 or c==189 end
assert(not MenuBindings.padInput('menu',true),'D-pad left cannot masquerade as interaction View')
print('Bindings: default repair, identity scope, persistence, remap, removal, optional controller, collisions, reserved keys and injection rejection passed (KVP/input adapters).')
