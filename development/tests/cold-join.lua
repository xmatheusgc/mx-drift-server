local T=ColdJoinTest
local point={x=135.9,y=-3030.47,z=6.4,h=359.72}
T.sceneAt=500 T.interiorAt=1500 T.modelAt=1000
assert(WorkshopStreaming.prepare(point,'garage',function()return true end))
assert(T.time>=1750,'vanilla collision alone cannot expose the custom workshop')
assert(T.frozen and not T.focus and T.pinned==42,'prepared scene is frozen; focus is released, interior retained')
WorkshopStreaming.stop() assert(not T.pinned and T.unpins==1,'leaving unpins only the acquired interior')
T.time=0 T.sceneAt=0 T.interiorAt=1200 T.modelAt=1100 T.registrationAt=900
local requests=T.requests
assert(WorkshopStreaming.prepare(point,'garage',function()return true end),'first entry waits for late workshop archetype registration')
assert(T.requestedAt==900 and T.requests==requests+1,'model is requested exactly once after registration, never before')
assert(T.time>=1450 and not T.focus and T.pinned==42,'registration is only one prerequisite; interior/model/stability remain required')
WorkshopStreaming.stop()
T.time=0 T.sceneAt=45000 T.modelAt=40000 T.interiorAt=42000 T.registrationAt=35000
local before=#T.progress
assert(WorkshopStreaming.prepare(point,'garage',function()return true end),'cold workshop may need more than the former thirty seconds')
assert(T.time>=45250 and #T.progress-before>=45,'long load emits ongoing, bounded-frequency stage feedback')
assert(T.progress[before+1].message:find('registro dos arquivos',1,true),'feedback identifies pending map registration')
WorkshopStreaming.stop()
T.time=0 T.registrationAt=100000 T.onWait=function()WorkshopStreaming.stop()end requests=T.requests
local ok,err=pcall(WorkshopStreaming.prepare,point,'garage',function()return true end)
assert(not ok and err.code=='OBSOLETE' and T.requests==requests and not WorkshopStreaming.session and not T.focus,'cancellation while waiting for registration makes no request and releases scene')
T.onWait=nil T.time=0 T.registered=false
ok,err=pcall(WorkshopStreaming.prepare,point,'garage',function()return true end)
assert(not ok and err.code=='SCENE_ASSET' and T.time==ExperienceConfig.streaming.timeout,'permanently missing workshop archetype fails at the shared deadline')
assert(T.requests==requests and not WorkshopStreaming.session and not T.focus and not T.pinned,'missing archetype cannot ACK readiness or leak focus/interior')
T.registered=true T.registrationAt=0
T.time=0 T.sceneAt=100000 T.modelAt=0 T.interiorAt=0
ok,err=pcall(WorkshopStreaming.prepare,point,'garage',function()return true end)
assert(not ok and err.code=='SCENE_STREAM' and T.time>=ExperienceConfig.streaming.timeout,'scene timeout is bounded and never ACKs readiness')
assert(not WorkshopStreaming.session and not T.focus and not T.pinned,'timeout cleans scene, focus, models and interior')
T.time=0 T.onWait=function()WorkshopStreaming.stop()end
ok,err=pcall(WorkshopStreaming.prepare,point,'garage',function()return true end)
assert(not ok and err.code=='OBSOLETE' and not T.focus,'scene cancellation cannot confirm an old entry')
T.onWait=nil T.mapStarted=false
ok,err=pcall(WorkshopStreaming.prepare,point,'garage',function()return true end)
assert(not ok and err.code=='SCENE_ASSET','missing workshop resource fails before moving the player')
T.mapStarted=true T.time=0 T.sceneAt=0 T.interiorAt=100000
assert(WorkshopStreaming.prepare(point,'lobby',function()return true end),'outdoor lobby does not require workshop interior')
WorkshopStreaming.stop()
T.time=0 T.sceneAt=100000 T.collisionAt=100000
assert(WorkshopStreaming.prepare(point,'lobby',function()return true end)==false,'unloaded lobby continues with optional scenery unavailable')
assert(T.time==ExperienceConfig.streaming.lobbyTimeout and T.frozen and not T.focus and not WorkshopStreaming.session,'unloaded lobby has short bounded wait, frozen player and no leaked scene')
T.time=0
local startScene=NewLoadSceneStartSphere
NewLoadSceneStartSphere=function()return false end
assert(WorkshopStreaming.prepare(point,'lobby',function()return true end)==false and T.time==0,'lobby loader start failure cannot block garage access')
NewLoadSceneStartSphere=startScene T.sceneAt=0 T.collisionAt=0
T.time=0 T.modelAt=15000 VehicleAssets.setIntent('a')
assert(VehicleAssets.load('futo','a').loaded and T.time==15000,'cold model can finish after the old eight-second cutoff')
T.time=0 T.modelAt=100000 T.released=false T.onWait=function()VehicleAssets.setIntent('b')end
local cancelled=VehicleAssets.load('futo','a')
assert(not cancelled.loaded and cancelled.cancelled and T.time==50 and T.released,'new choice cancels an old pending model immediately')
T.onWait=nil T.time=0
local timeout=VehicleAssets.load('futo','b')
assert(not timeout.loaded and not timeout.cancelled and T.time==VehicleConfig.modelLoadTimeout,'model failure has a bounded wait')
T.registered=false T.time=0
assert(not VehicleAssets.load('missing').loaded and T.time==0,'unregistered models are not requested')
print('Cold join: delayed scene/interior/model, cancellation, bounded failures and cleanup passed with native adapters; no FiveM client.')
