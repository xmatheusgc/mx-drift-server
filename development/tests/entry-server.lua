local T,R=SessionTest,SessionTest.routes
local oldCall,oldCoords,oldDistance=MX.callClient,GetEntityCoords,MX.distance
local scene=false local polls=0 local blocked=false local aborted=false
MX.distance=function(a,b)return math.sqrt((a.x-b.x)^2+(a.y-b.y)^2+(a.z-b.z)^2)end
function GetEntityCoords()
 if not scene then return {x=500,y=500,z=6} end
 polls=polls+1
 if not blocked and polls>5 then return ExperienceConfig.scene.ped end
 return {x=500,y=500,z=6}
end
MX.callClient=function(src,domain,action,data)
 if action=='scene' then scene=true polls=0 end
 if action=='abort' then aborted=true return {recovered=true} end
 return {ready=true}
end
assert(R.enter(3,{},T.actor).token and polls>5,'entry waits for replicated position after scene ACK instead of rejecting its first sample')
scene=false blocked=true
local ok,err=pcall(R.enter,4,{},T.actor)
assert(not ok and type(err)=='table' and err.code=='POSITION' and err.message:find('Modo livre restaurado',1,true),'timeout has a useful explanation and confirmed recovery')
assert(aborted and T.buckets[4]==0,'failed entry returns public bucket and invokes rollback')
scene=false blocked=false
assert(R.enter(4,{},T.actor).token,'retry after failed entry creates a fresh valid session')
local oldPed=GetPlayerPed local oldWait=Wait
local missing=8 local initialPolls=0
GetPlayerPed=function()initialPolls=initialPolls+1 if initialPolls<=missing then return 0 end return 1 end
GetEntityCoords=function(ped)assert(ped~=0,'never capture return coordinates from entity zero') if scene then return ExperienceConfig.scene.ped end return {x=500,y=500,z=6}end
scene=false
assert(R.enter(5,{},T.actor).token and initialPolls>missing,'initial ped replication is awaited before capturing public return position')
initialPolls=0 missing=0 scene=false
MX.callClient=function(src,domain,action,data)
 if action=='scene' then scene=true missing=initialPolls+8 end
 if action=='abort' then return {recovered=true} end
 return {ready=true}
end
assert(R.enter(6,{},T.actor).token and initialPolls>missing,'temporary missing ped during model replacement does not invalidate epoch')
scene=false GetPlayerPed=function()return 0 end
local started=T.time
local ready,notReady=pcall(R.enter,7,{},T.actor)
assert(not ready and notReady.code=='PLAYER_NOT_READY' and T.time-started>=ExperienceConfig.entrySyncTimeout,'missing ped has a bounded useful readiness error')
GetPlayerPed=function()return 1 end
local actor=T.actor
T.actor={id=actor.id,epoch='changed'}
local same,changed=pcall(R.enter,8,{},actor)
assert(not same and changed.code=='SESSION','real session replacement is still rejected')
T.actor=actor GetPlayerPed=oldPed Wait=oldWait
MX.callClient,GetEntityCoords,MX.distance=oldCall,oldCoords,oldDistance
print('Actual entry-server regressions: delayed position replication, bounded timeout, public bucket rollback and successful retry passed with network/native adapters.')
