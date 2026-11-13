local T=VehicleOptionsTest local savedId='00000000-0000-4000-8000-000000000001'
T.peds[1].x=10 T.peds[1].y=20 T.peds[1].z=6 T.moveDuringLoad=false
T.time=T.time+6000 T.exports.RemoveManaged(1) T.peds[1].car=0
T.saved[savedId].drift_enabled=1 T.failDriftApply=true
local row=T.exports.Saved(11,savedId)
local result=T.exports.SpawnSavedAt(1,row,{point={x=10,y=20,z=6,h=90},departure=false})
local active=T.exports.Active(1)
assert(T.cars[result.net] and T.peds[1].car==result.net and result.warning,'saved car remains available and seated after a drift fallback')
assert(not active.drift and active.driftRequested and not active.handlingUncertain,'effective normal handling is separate from the saved request')
assert(T.saved[savedId].drift_enabled==1 and not T.cars[result.net].state.mxDrift.enabled,'temporary recovery cannot erase saved preference or publish fake drift success')
T.time=T.time+6000
local recreated=T.routes.service(1,{kind='respawn',vehicleId=active.id})
assert(T.cars[recreated.net] and #T.exports.Inspect()==1 and T.exports.Active(1).driftRequested,'recreation survives repeat drift failure without duplicates or lost requested mode')
assert(T.saved[savedId].drift_enabled==1,'recreation preserves saved progress')
T.softDrift=true
local toggle=T.routes.service(1,{kind='drift',enabled=true})
assert(toggle.persisted==false and not toggle.enabled and toggle.warning and T.saved[savedId].drift_enabled==1,'failed manual toggle returns a warning without a false durable confirmation')
T.softDrift=false T.failDriftRestore=true T.time=T.time+6000
local switched=T.routes.switch(1,{presetId=savedId},T.actors[1])
assert(T.cars[switched.net] and T.exports.Active(1).handlingUncertain,'unconfirmed optional restore still does not abort saved-car switch')
T.failDriftApply=false T.failDriftRestore=false
local retry=T.routes.service(1,{kind='drift',enabled=true})
assert(retry.enabled and retry.persisted and not T.exports.Active(1).handlingUncertain,'successful explicit retry clears uncertainty and persists confirmed drift')
T.softRepair=true
local repaired=T.routes.service(1,{kind='repair'})
assert(repaired.warning and not T.exports.Active(1).drift and T.saved[savedId].drift_enabled==1,'optional reapply failure cannot abort repair or erase saved preference')
T.softRepair=false
T.time=T.time+6000 T.failApply=true
local previous=T.exports.Active(1)
assert(not pcall(T.exports.SpawnSavedAt,1,row,{point={x=10,y=20,z=6,h=90},departure=false}) and T.cars[previous.entity],'mandatory cosmetic ACK failure is still rejected and preserves the previous car')
T.failApply=false
print('Drift/server recovery: saved spawn, respawn, switch, effective state, preserved saved preference, uncertain restore, confirmed retry and mandatory ACK guard passed (adapters).')
