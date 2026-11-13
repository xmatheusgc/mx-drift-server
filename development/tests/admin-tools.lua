local T,C,S=AdminToolTest,AdminLocalTools,AdminTools local n=0
local function check(ok,message)assert(ok,message)n=n+1 end
local function rejects(fn,code)local ok,err=pcall(fn)check(not ok and MX.error(err).code==code,'expected '..code)end
T.ace['mx.admin']=true T.ace['mx.inspect']=true T.ace['mx.teleport']=true
local p=S.snapshot(1,{target='ped'})check(p.x==10 and p.h==270 and p.interior==42 and p.networkId==501,'ped snapshot contains local pose and inspection fields')
T.vehicle=10 p=S.snapshot(1,{target='vehicle'})check(p.x==100 and p.name=='FUTO','vehicle reference reads actual occupied entity')
p=S.snapshot(1,{target='camera'})check(p.x==50 and p.h==270 and not p.model,'camera yaw normalized without inventing entity data')
T.vehicle=0 rejects(function()S.snapshot(1,{target='vehicle'})end,'VEHICLE')
rejects(function()S.snapshot(1,{target='other'})end,'PAYLOAD')
T.ace['mx.inspect']=false rejects(function()S.snapshot(1,{target='ped'})end,'FORBIDDEN')T.ace['mx.inspect']=true
T.bucket=10000 rejects(function()S.overlay(1,{enabled=true,target='ped'})end,'SESSION')T.bucket=0
T.private=true rejects(function()S.snapshot(1,{target='ped'})end,'SESSION')T.private=false
S.overlay(1,{enabled=true,target='ped'})check(C.enabled and S.watchers[1] and T.notices['mx:admin:telemetry'].x==10,'overlay starts through authorized ACK')
T.time=2000 S.refresh()check(C.expires==8000,'valid admin receives bounded renewal')
source=1 T.events['mx:admin:toolsGrant'](false)check(C.enabled,'client-originated grant event ignored')
T.ace['mx.inspect']=false S.refresh()check(not C.enabled and not S.watchers[1] and T.notices['mx:admin:telemetry']==false,'ACE revocation clears local and server overlay state')T.ace['mx.inspect']=true
S.overlay(1,{enabled=true,target='ped'})T.time=T.time+6000 C.tick()check(not C.enabled,'overlay expires if server renewals disappear')
T.time=0 T.waypoint=false rejects(C.waypoint,'WAYPOINT')check(not T.focus and not T.loading,'missing marker does not acquire focus')
T.waypoint=true p=C.waypoint()check(T.time==500 and p.z==41 and not T.focus and not T.loading,'waypoint waits for streamed ground and releases all hints')
T.time=0 T.groundAt=100000 rejects(C.waypoint,'GROUND')check(T.time==8000 and not T.focus and not T.loading,'unknown ground has bounded failure and cleanup without moving player')
T.groundAt=300 T.time=0
local travel=T.exports.AdminTravel
local function trip(data)return MX.unwrap(travel(1,data))end
T.invoker='other-resource' rejects(function()trip({mode='coordinates',point={x=1,y=2,z=3}})end,'FORBIDDEN')T.invoker=nil
T.ace['mx.teleport']=false rejects(function()trip({mode='coordinates',point={x=1,y=2,z=3}})end,'FORBIDDEN')T.ace['mx.teleport']=true
rejects(function()trip({mode='coordinates',point={x=0/0,y=2,z=3}})end,'COORDS')
rejects(function()trip({mode='coordinates',point={x=1,y=2,z=3001}})end,'COORDS')
rejects(function()trip({mode='coordinates',point={x=1,y=2,z=3,h=361}})end,'COORDS')
rejects(function()trip({mode='coordinates',point={x=1,y=2,z=3,entity=99}})end,'COORDS')
local result=trip({mode='coordinates',point={x=100,y=200,z=30,h=45}})
check(result.point.h==45 and T.trip.checkpoint and not T.trip.car,'explicit coordinates use shared travel with requested heading')
trip({mode='coordinates',point={x=100,y=200,z=30}})check(T.trip.point.h==270,'omitted heading preserves actual direction')
T.vehicle=10 trip({mode='coordinates',point={x=100,y=200,z=30}})check(T.trip.car,'owned driven vehicle is selected on server')
T.occupied=true rejects(function()trip({mode='waypoint'})end,'PASSENGER')T.occupied=false T.vehicle=0
T.onCall=function()T.epoch=T.epoch+1 end rejects(function()trip({mode='waypoint'})end,'OBSOLETE')T.onCall=nil
T.onCall=function()T.ace['mx.teleport']=false end rejects(function()trip({mode='waypoint'})end,'FORBIDDEN')T.onCall=nil T.ace['mx.teleport']=true
T.onCall=function()T.vehicle=10 end rejects(function()trip({mode='waypoint'})end,'OBSOLETE')T.onCall=nil T.vehicle=0
local before=T.tripCount T.waypoint=false rejects(function()trip({mode='waypoint'})end,'WAYPOINT')check(T.tripCount==before,'missing marker never invokes travel')T.waypoint=true
exports['mx-freeroam-world']={AdminTravel=travel}
T.onAudit=function()T.epoch=T.epoch+1 end rejects(function()T.routes.teleport(1,{mode='coordinates',point={x=1,y=2,z=3}},nil,'req')end,'SESSION')T.onAudit=nil
check(T.tripCount==before,'epoch change during audit cannot teleport a replacement profile')
S.overlay(1,{enabled=true,target='ped'})T.events['mx:profile:dropped'](1)check(not S.watchers[1],'profile drop releases subscription')
print(n..' admin tools checks passed: pose references, ACE/epoch, overlay lease/revocation, marker ground/cleanup and guarded travel (native adapters; no FiveM).')
