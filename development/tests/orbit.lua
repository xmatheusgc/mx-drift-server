-- Actual orbit controller; only shape-test/time natives are replaced.
local oldTime,oldStart,oldResult=GetGameTimer,StartShapeTestCapsule,GetShapeTestResult
local O,F=WorkshopOrbit,WorkshopFraming
local now,delay,hit,nextHandle,queries=0,16,0,0,{}
function GetGameTimer()return now end
function StartShapeTestCapsule()
    nextHandle=nextHandle+1 queries[nextHandle]={ready=now+delay,hit=hit} return nextHandle
end
function GetShapeTestResult(handle)
    local q=queries[handle] assert(not q.consumed,'completed shape handle must not be polled again')
    if now<q.ready then return 1,0 end q.consumed=true return 2,q.hit
end
local car={x=0,y=0,z=0,h=0}
local input={yaw=0,elevation=.22,distance=6}
local position,target=F.orbit(car,2,4.7,1.5,input.yaw,input.elevation,input.distance)
local state=O.new(position,target,input)
O.step(state,car,2,4.7,1.5,input,10,1/60)
assert(nextHandle==0,'idle orbit does not continuously allocate shape tests')
input.yaw=.1
O.step(state,car,2,4.7,1.5,input,10,1/60)
assert(state.query and MX.distance(state.position,position)<.00001,'pending pose is not published')
now=16 O.step(state,car,2,4.7,1.5,input,10,1/60)
assert(MX.distance(state.position,position)>0 and MX.distance(state.position,state.safe)>0,'approved destination is approached instead of snapped')
delay=200 input.yaw=.2
for _=1,5 do
    local before=state.position now=now+16
    O.step(state,car,2,4.7,1.5,input,10,1/60)
    assert(MX.distance(before,state.position)>0,'camera keeps rendering movement while next collision query is pending')
end
assert(state.query and math.abs(state.yaw-.1)<.00001,'delayed result does not prematurely approve the next orbit')
-- One handle can finish before the other; it must not be re-read.
queries[state.query.sight].ready=now queries[state.query.travel].ready=now+16
O.step(state,car,2,4.7,1.5,input,10,1/60)
now=now+16 O.step(state,car,2,4.7,1.5,input,10,1/60)
assert(math.abs(state.yaw-.2)<.00001,'asymmetric shape-test completion is cached')
local approved=state.safe
-- A release cancels both the native-query backlog and the smoothed tail.
local stopped=state.position
O.stop(state,input)
assert(not state.query and state.safe==stopped,'release discards pending query and target')
for _=1,5 do now=now+16 O.step(state,car,2,4.7,1.5,input,10,1/60) end
assert(MX.distance(state.position,stopped)<.000001,'camera stays still after release instead of replaying old movement')
approved=state.safe
hit=1 delay=16 input.yaw=.3
O.step(state,car,2,4.7,1.5,input,10,1/60)
now=now+16 O.step(state,car,2,4.7,1.5,input,10,1/60)
assert(state.safe==approved,'blocked destination is not published')
delay=1000 now=now+16 O.step(state,car,2,4.7,1.5,input,10,1/60)
now=now+ExperienceConfig.orbit.queryTimeout+1 O.step(state,car,2,4.7,1.5,input,10,1/60)
assert(state.safe==approved,'timeout never ends in an unchecked final jump')
for _,fps in ipairs({30,60,144}) do
    local p={x=0,y=0,z=0} local aim={x=10,y=20,z=30}
    for _=1,fps do p=F.dampPoint(p,aim,1/fps,14) end
    assert(math.abs(p.x-10*(1-math.exp(-14)))<.000001,'one-second response is frame-rate independent')
end
local responsive=F.dampPoint({x=0,y=0,z=0},{x=10,y=0,z=0},.05,ExperienceConfig.orbit.response)
assert(responsive.x>8.5,'current response covers at least 85 percent of an approved step within 50ms of simulated render time')
GetGameTimer,StartShapeTestCapsule,GetShapeTestResult=oldTime,oldStart,oldResult
print('Orbit regressions passed: continuous render, pending/blocked/expired queries, cached completions and frame-rate-independent damping; native adapters only.')
