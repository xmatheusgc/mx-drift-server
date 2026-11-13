local T=WorldPreviewTest local set=T.exports.SetLobbyTime
local function tick()local ok,e=coroutine.resume(T.threads[2])assert(ok,e)end
tick() tick()
assert(T.vehicleBudget==3 and T.pedBudget==3 and T.reduceVehicles==false and T.reducePeds==false,'full native population budgets without model reductions')
assert(T.weather=='EXTRASUNNY' and T.clock.h==14,'normal world defaults')
assert(T.cinematicBlocked and T.cinematicButton==false,'R/controller cinematic action is blocked without changing script cameras')
assert(not T.cinematicActive,'an already running native cinematic camera is released')
set(23,0,'FOGGY') tick()
assert(T.weather=='FOGGY' and T.clock.h==23,'lobby night and fog through single world writer')
set(23,0) tick()
assert(T.weather=='EXTRASUNNY' and T.clock.h==23,'garage night preview does not inherit lobby fog')
set() tick()
assert(T.clock.h==14 and T.weather=='EXTRASUNNY','leaving preview restores world defaults')
T.invoker='other' assert(not pcall(set,23,0,'FOGGY'),'untrusted resource rejected')
T.invoker='mx-freeroam-experience' assert(not pcall(set,23,0,'invalid'),'invalid weather rejected')
set(23,0,'FOGGY') T.handlers.onClientResourceStop('mx-freeroam-experience') tick()
assert(T.clock.h==14 and T.weather=='EXTRASUNNY','experience stop restores world environment')
T.handlers.onClientResourceStop('mx-freeroam-world') assert(T.cinematicButton==true,'resource stop releases the cinematic button policy')
print('7 world preview checks: fog, night, restore, resource stop and authority; natives simulated.')
GlobalState={mxEnvironment={weather='RAIN',weatherFrom='OVERCAST',weatherBlend=.5,hour=21,minute=30,second=15}}
tick() assert(T.blend and T.blend.f==.5 and T.clock.s==15,'actual world loop renders server weather blend and seconds')
set(23,0,'FOGGY') tick() assert(T.weather=='FOGGY' and T.clock.s==0,'presentation overrides dynamic world')
set() tick() assert(T.clock.h==21 and T.blend.f==.5,'leaving presentation restores the latest dynamic state')
GlobalState=nil
