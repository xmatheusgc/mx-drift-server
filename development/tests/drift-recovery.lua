local T=DriftTest local one=T.cars[1].fields
local key='fBackEndPopUpBuildingImpulseMult'
one[key]=0 T.reject=key
local result=VehicleDrift.ensure(1,'one',true,false)
assert(not result.enabled and result.fallback and result.recovered and result.attempts==2,'unsupported subtype writes fall back after one bounded retry')
assert(one.fMass==2 and one.fSteeringLock==2 and one[key]==0 and T.cars[1].highGear==6,'fallback restores baseline physics and transmission instead of leaving a partial preset')
local audit=VehicleDrift.audit(1,'one',false)
assert(audit.mismatches==0 and audit.recovery.detail:find(key,1,true),'fallback remains auditable with exact failed field')
T.reject=nil T.rejectOnce='fMass'
result=VehicleDrift.ensure(1,'one',true,false)
assert(result.enabled and result.recovered and result.attempts==2 and one.fMass==1280,'transient setter failure is reset and retried successfully')
VehicleDrift.ensure(1,'one',false,false)
assert(one.fMass==2 and one[key]==0,'retry never captures a partially applied preset as the original')
T.failRefresh=true
result=VehicleDrift.ensure(1,'one',true,false)
assert(not result.enabled and result.uncertain and not result.recovered,'unconfirmed restoration is surfaced instead of claiming normal physics')
assert(coroutine.resume(T.threads[1]))
local afterFailure=T.writes
assert(coroutine.resume(T.threads[1]) and T.writes==afterFailure,'persistent restore failure is not retried or logged every polling tick')
T.failRefresh=false
assert(VehicleDrift.ensure(1,'one',false,false).recovered and one.fMass==2,'explicit retry can recover a previously unconfirmed original')
VehicleDrift.ensure(1,'one',true,false) T.failRefreshOnce=true
result=VehicleDrift.ensure(1,'one',false,false)
assert(not result.enabled and result.recovered and not result.fallback and one.fMass==2,'a second successful reset confirms disable rather than returning a false failure')
T.missing=key local writes=T.writes
result=VehicleDrift.ensure(2,'two',true,false)
assert(result.recovered and result.code=='HANDLING_UNSUPPORTED' and T.writes==writes,'unsupported preflight leaves the original car untouched')
T.missing=nil
T.cars[1].id='replacement' writes=T.writes
assert(not pcall(VehicleDrift.ensure,1,'one',true,false) and T.writes==writes,'optional fallback cannot bypass entity identity guards')
T.cars[1].id='one'
print('Drift recovery: subtype mismatch, original rollback, bounded retry, transient success, uncertain restore, diagnostic and entity identity passed (native adapters).')
