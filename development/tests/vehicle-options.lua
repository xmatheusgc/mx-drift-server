local T=VehicleOptionsTest local routes=T.routes
local empty=routes.options(1) assert(not empty.exists and not empty.available.engine,'empty fleet disables all actions')
local properties={primary=12,mods={['23']=17},extras={['1']=true},livery=2}
function GetCurrentResourceName()return 'mx-freeroam-vehicles'end
local savedId='00000000-0000-4000-8000-000000000001'
T.saved[savedId]={id=savedId,player_id=11,name='Futo',model='futo',properties=json.encode(properties),schema_version=1,revision=1,drift_enabled=0}
local result=T.exports.SpawnSavedAt(1,{id=savedId,model='futo',properties=properties},{point={x=10,y=20,z=6,h=90},departure=false})
local entity=result.net local originalId=result.id
T.time=T.time+6000
local status=routes.options(1) assert(status.driver and status.available.drift and #status.doors==4,'driver options and model doors')
assert(routes.handlingAudit(1).checked==51 and not pcall(routes.handlingAudit,2),'diagnostic is scoped to the requesting owner fleet')
T.peds[1].car=0 T.cars[entity].driver=0
status=routes.options(1) assert(status.available.engine and status.available.doors and status.available.lock and not status.available.stop and not status.available.drift,'on-foot context permits remote controls, not driver actions')
routes.service(1,{kind='engine',vehicleId=originalId}) assert(T.calls[#T.calls].data.driver==false,'server authorizes remote engine without fake driver requirement')
assert(not pcall(routes.service,2,{kind='engine',vehicleId=originalId}),'other player cannot choose or control owner car')
assert(not pcall(routes.service,1,{kind='doors',vehicleId='forged'}),'stale/forged target rejected')
assert(not pcall(routes.service,1,{kind='doors',door=99}),'arbitrary door IDs rejected')
T.peds[1].x=1000 assert(not routes.options(1).available.engine and not pcall(routes.service,1,{kind='engine'}),'distance checked server-side') T.peds[1].x=10
T.bucket=2 assert(not pcall(routes.service,1,{kind='engine'}),'private bucket blocked') T.bucket=0
T.flying=true assert(not pcall(routes.service,1,{kind='repair'}),'noclip context blocked') T.flying=false
T.peds[1].car=entity T.cars[entity].driver=1 T.cars[entity].speed=20
assert(routes.options(1).available.drift and pcall(routes.service,1,{kind='drift',enabled=true}),'moving drift change is allowed')
routes.service(1,{kind='drift',enabled=false}) T.cars[entity].speed=0
T.legacyDrift=true assert(not pcall(routes.service,1,{kind='drift',enabled=true}) and not T.exports.Active(1).drift,'legacy ACK without transmission refresh is not accepted') T.legacyDrift=false
local appliedDrift=routes.service(1,{kind='drift',enabled=true}) assert(T.exports.Active(1).drift and T.cars[entity].state.mxDrift.enabled,'authorized handling published by server')
assert(appliedDrift.persisted and T.saved[savedId].drift_enabled==1,'drift ACK requires durable storage on the owned saved ID')
T.failDatabase=true
assert(not pcall(routes.service,1,{kind='drift',enabled=false}) and T.exports.Active(1).drift and T.cars[entity].state.mxDrift.enabled,'SQL failure restores desired and client handling')
T.failDatabase=false
T.failDrift=true assert(not pcall(routes.service,1,{kind='drift',enabled=false}) and T.exports.Active(1).drift,'failed ACK rolls desired state back') T.failDrift=false
routes.service(1,{kind='drift',enabled=false}) assert(not T.exports.Active(1).drift)
assert(T.saved[savedId].drift_enabled==0,'turning drift off is also durable')
routes.service(1,{kind='drift',enabled=true})
T.peds[2].car=entity assert(not routes.options(1).available.respawn and not pcall(routes.service,1,{kind='respawn'}),'passengers protect replacement')
local ejected=routes.service(1,{kind='eject'}) assert(ejected.count==1 and T.peds[1].car==entity and T.peds[2].car==0,'ejection only targets other occupants of this car')
T.failLoad=true assert(not pcall(routes.service,1,{kind='respawn'}) and T.cars[entity],'model-load failure preserves original entity') T.failLoad=false
T.failPrepare=true assert(not pcall(routes.service,1,{kind='respawn'}) and T.cars[entity] and T.resumed,'failed preparation releases original vehicle') T.failPrepare=false
T.failDelete=true assert(not pcall(routes.service,1,{kind='respawn'}) and T.cars[entity] and T.created==1,'unconfirmed deletion cannot spawn a duplicate') T.failDelete=false
T.respawning=true local respawn=routes.service(1,{kind='respawn'})
assert(respawn.id~=originalId and not T.cars[entity] and #T.exports.Inspect()==1,'replacement creates exactly one managed entity')
assert(T.peds[1].car==respawn.net and T.cars[respawn.net].properties.mods['23']==17 and T.cars[respawn.net].properties.primary==12,'replacement seats owner and preserves customized properties')
assert(T.exports.Active(1).drift and T.cars[respawn.net].state.mxDrift.enabled,'respawn preserves enabled drift state')
assert(T.exports.Active(1).presetId==savedId,'respawn preserves saved creation identity')
assert(not pcall(routes.service,1,{kind='respawn'}),'replacement cooldown checked')
T.swapOnCall=true assert(not pcall(routes.service,1,{kind='engine'}),'reused network identity rejected after ACK')
T.time=T.time+6000 T.exports.RemoveManaged(1) T.peds[1].car=0
T.respawning=false
local recovered=T.exports.SpawnSavedAt(1,{id=savedId,model='futo',properties=properties,drift_enabled=0},{point={x=10,y=20,z=6,h=90},departure=false})
assert(T.exports.Active(1).drift and T.cars[recovered.net].state.mxDrift.enabled,'fresh saved flag overrides stale session row after despawn')
local duplicated=T.exports.PrepareSaved(11,'duplicate',{id='00000000-0000-4000-8000-000000000002',sourceId=savedId})
MX.tx(duplicated.queries) assert(T.exports.Saved(11,'00000000-0000-4000-8000-000000000002').drift_enabled==1,'duplicate inherits durable mode')
assert(not pcall(T.exports.Saved,22,savedId),'saved state remains owner scoped')
T.time=T.time+6000 T.exports.RemoveManaged(1) T.peds[1].car=0
local fresh=T.exports.SpawnSavedAt(1,{model='futo',properties=properties},{point={x=10,y=20,z=6,h=90},departure=false})
local ids=0 for _ in pairs(T.saved)do ids=ids+1 end
MX.uuid=function()return '00000000-0000-4000-8000-000000000003'end
routes.service(1,{kind='drift',enabled=true})
routes.service(1,{kind='drift',enabled=false})
local count=0 for _ in pairs(T.saved)do count=count+1 end
assert(count==ids+1 and T.exports.Active(1).presetId=='00000000-0000-4000-8000-000000000003','unsaved car gets exactly one durable creation across repeated toggles')
assert(T.exports.Saved(11,T.exports.Active(1).presetId).drift_enabled==0,'unsaved creation stores subsequent off toggle')
print('Actual vehicle server: ownership, remote actions, distance/bucket/noclip, stale targets, handling ACK rollback, scoped ejection, respawn preflight/deletion failure, no duplicate entities, preserved properties and owner seating passed (adapters).')
