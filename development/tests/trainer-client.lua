function GetResourceState() return 'missing' end
local T=TrainerTest local handlers=T.handlers.trainer
local movement=T.threads[#T.threads]
local function tick() T.time=T.time+16 local ok,err=coroutine.resume(movement) assert(ok,err) end
T.vehicle=10 T.cars[10].id='owned-car'
local args={token='client-grant',net=110,id='owned-car',speed=2}
assert(handlers.start(args).active and T.cars[10].collision and T.cars[10].frozen)
assert(T.suspended,'noclip suspends optional drivecam without changing its preference')
T.forward=-1 local y=T.cars[10].y tick() tick()
assert(T.cars[10].y>y,'noclip movement is rendered every frame')
assert(GetEntityAlpha(10)==80 and T.cars[10].alphaOverride and T.cars[10].visible==false and T.cars[10].localVisible,'noclip keeps a translucent local ghost while active')
local initialZ=T.cars[10].z T.camPitch=80 tick() assert(T.cars[10].z==initialZ,'looking upwards does not accidentally change flight height')
T.held={[44]=true} tick() assert(T.cars[10].z>initialZ,'Q/native cover ascends') T.held={}
T.pressed={[21]=true} tick() local speed=T.notices['mx:trainer:state'].speed
assert(speed==3,'Shift advances the speed level once') tick() assert(T.notices['mx:trainer:state'].speed==3,'held key does not repeatedly cycle speed')
T.pressed={[74]=true} tick() assert(T.notices['mx:trainer:state'].followCamera==false,'H toggles fixed orientation')
T.turn=1 local heading=T.cars[10].h tick() assert(T.cars[10].h~=heading,'A/D or horizontal analog turns in fixed mode') T.turn=0
T.focused=true T.pressed={[21]=true} tick() assert(T.notices['mx:trainer:state'].speed==speed,'speed shortcut is ignored in NUI') T.pressed={} T.focused=false
T.focused=true y=T.cars[10].y tick() assert(T.cars[10].y==y,'menu focus cannot move the noclip entity') T.focused=false
assert(not handlers.stop({token='old'}).stopped and T.cars[10].frozen,'old grant cannot stop the current session')
assert(handlers.stop(args).stopped and not T.cars[10].collision and not T.cars[10].frozen,'stop restores collision and releases the entity')
assert(not T.suspended,'stop releases drivecam suspension')
assert(T.cars[10].alpha==255 and T.cars[10].visible and T.cars[1].visible,'stop restores both vehicle and seated ped visibility')
assert(T.cars[10].alphaResets and not T.cars[10].alphaOverride and not T.cars[1].alphaOverride,'stop resets rendering overrides on both vehicle and driver')
assert(not pcall(handlers.start,args),'delayed activation cannot revive an already stopped grant')
-- Stop during the frame yield, then resume and activate again.
tick()
for n=1,4 do
 args.token='reactivation-'..n handlers.start(args) tick() tick()
 local before=T.cars[10].y
 handlers.stop(args) tick()
 assert(coroutine.status(movement)=='suspended' and T.cars[10].visible and T.cars[10].alpha==255,'stop between frames cannot kill movement')
 args.token='moving-again-'..n handlers.start(args) tick() tick()
 assert(T.cars[10].y>before,'re-enabled car moves after stopped frame')
 handlers.stop(args) tick()
end
args.token='next-grant'
T.passengers=true assert(not pcall(handlers.start,args),'client also rejects passengers') T.passengers=false
handlers.start(args) T.control=false tick() tick()
assert(not T.cars[10].frozen and not T.cars[10].collision,'network control loss stops movement and restores local state') T.control=true
args.token='private-grant' handlers.start(args) T.private=true tick() tick() assert(not T.cars[10].frozen,'private-scene transition releases noclip') T.private=false
args.token='fps-grant' args.followCamera=true handlers.start(args) tick() tick()
local function second(fps)
 T.dt=1/fps T.cars[10].x=0 T.cars[10].y=0 T.cars[10].z=6 T.camYaw=0
 for _=1,fps do tick() end return T.cars[10].y
end
assert(math.abs(second(30)-second(120))<.0001,'travel distance is stable at 30 and 120 FPS') T.dt=nil
handlers.stop(args)
T.vehicle=0 handlers.start({token='ped-grant',speed=1})
T.events.onClientResourceStop('mx-freeroam-menu') assert(not T.cars[1].frozen and not T.cars[1].collision,'menu restart restores the ped')
T.vehicle=10 T.cars[10].alpha=153 T.cars[10].alphaOverride=true
handlers.start({token='prior-opacity',net=110,id='owned-car',speed=1}) tick() tick()
assert(T.cars[10].alpha==80,'active noclip uses configured ghost opacity')
handlers.stop({token='prior-opacity'})
assert(T.cars[10].alpha==153 and T.cars[10].alphaOverride,'cleanup preserves opacity owned by another flow')
T.cars[10].alpha=255 T.cars[10].alphaOverride=false
print('Trainer client: real controller activation, movement, focus pause, stale token, passengers, network loss, private scene and resource cleanup passed with native adapters; no game.')
