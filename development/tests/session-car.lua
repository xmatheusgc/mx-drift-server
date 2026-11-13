local T=SessionTest local R=T.routes local actor=T.actor
local s=R.enter(1,{},actor) local token=s.token
local function request(d)d=d or {} d.token=token return d end
local function state()return R.state(1,{},actor)end
assert(state().current.id==T.original,'saved identity restored on entry')
R.preview(1,request({intent=MX.uuid(),model='180sx'}),actor)
assert(state().current.id==T.original and T.writes==0,'browsing showroom cannot replace current or write SQL')
local choose=request({id=MX.uuid(),operation=MX.uuid(),model='180sx',name='Custom'})
R.useCurrent(1,choose,actor)
assert(state().current.id==choose.id and T.rows[choose.id].model=='180sx','explicit use persists selected creation')
local writes=T.writes R.useCurrent(1,choose,actor)
assert(T.writes==writes,'replaying selection cannot duplicate saved creation')
local confirm=request({id=MX.uuid(),operation=MX.uuid(),properties={primary=42}})
T.failSave=true assert(not pcall(R.confirmCurrent,1,confirm,actor),'SQL failure propagates')
assert(state().current.properties.primary==0 and T.rows[choose.id].properties.primary==0,'failed confirmation preserves durable baseline')
T.failSave=false local result=R.confirmCurrent(1,confirm,actor)
assert(result.state.current.id==choose.id and T.rows[choose.id].properties.primary==42,'confirm applies and persists existing identity')
writes=T.writes R.confirmCurrent(1,confirm,actor)
assert(T.writes==writes and T.rows[choose.id].revision==2,'lost response retry cannot repeat update')
local count=0 for _ in pairs(T.rows)do count=count+1 end assert(count==2,'exactly one new saved creation')
R.cosmetic(1,request({properties={primary=70}}),actor)
assert(T.rows[choose.id].properties.primary==42,'cosmetic preview never saves')
R.confirmCurrent(1,request({id=MX.uuid(),operation=MX.uuid(),properties={primary=77}}),actor)
assert(T.rows[choose.id].properties.primary==77 and T.rows[choose.id].revision==3,'next confirmation updates same row')
assert(T.rows[T.original].properties.primary==0,'another creation remains untouched')
local writesBeforePreview,notices=T.writes,#T.notifications
R.preview(1,request({intent=MX.uuid(),id=T.original}),actor)
local scenery=R.displayVehicles(1,request(),actor)
assert(scenery.current.id==T.original and T.displayRequest.excluded==T.original,'saved preview exclusion follows visible creation before confirmation')
assert(state().current.id==choose.id and T.writes==writesBeforePreview,'visual exchange cannot select or save a creation')
R.resetPreview(1,request(),actor)
assert(R.displayVehicles(1,request(),actor).current.id==choose.id,'cancel restores confirmed exclusion')
assert(#T.notifications==notices,'preview/reset do not invalidate the saved collection')
R.select(1,request({id=T.original,revision=state().revision,operation=MX.uuid()}),actor)
R.select(1,request({id=choose.id,revision=state().revision,operation=MX.uuid()}),actor)
assert(#T.notifications==notices,'confirmed selection alone never reloads scenery')
R.lobby(1,{},actor)
assert(T.point.x==-949.431 and T.point.y==-3533.159 and T.point.h==280.67,'independent lobby position')
R.enter(1,{},actor)
assert(T.point.x==135.962 and T.point.y==-3030.353 and T.point.z==6.396 and T.point.h==0.11,'garage presentation position')
assert(state().current.id==choose.id and state().current.properties.primary==77,'scene changes recover confirmed configuration')
local display=R.displayVehicles(1,{token=state().token,id='untrusted-owner'},actor)
assert(T.displayRequest.owner==actor.id and T.displayRequest.count==7 and T.displayRequest.excluded==choose.id,'display uses authenticated owner, bounded count and current exclusion')
for _,row in ipairs(display.vehicles)do assert(row.id~=choose.id)end
assert(not pcall(R.displayVehicles,1,{token='stale'},actor),'display rejects stale session')
local epoch=actor.epoch actor.epoch='reused'
assert(not pcall(R.displayVehicles,1,{token=state().token},actor),'display rejects reused source epoch')actor.epoch=epoch
local noticeCount=#T.notifications state()state()assert(#T.notifications==noticeCount,'no redundant display notifications')
T.rows[T.original].revision=T.rows[T.original].revision+1 state()
assert(#T.notifications==noticeCount+1,'saved revision invalidates display')
ExperienceConfig.display.enabled=false T.displayRequest=nil
assert(#R.displayVehicles(1,{token=state().token},actor).vehicles==0 and T.displayRequest==nil,'disabled display does not query documents')
ExperienceConfig.display.enabled=true
R.lobby(1,{},actor)
assert(not pcall(R.displayVehicles,1,{token=state().token},actor),'display unavailable in lobby')
R.enter(1,{},actor)
print('Workshop display routes: owner/session/epoch/context, exclusion, cap, invalidation and disabled read guard passed; adapters only.')
print('15 integration assertions for immediate persistence, preview isolation, SQL failure/retry and independent scenes; adapters simulated.')
local coords,bucket=GetEntityCoords,GetPlayerRoutingBucket
function GetPlayerRoutingBucket()return 1 end
function GetEntityCoords()return {x=140,y=-3020,z=7}end
assert(not pcall(R.enterFromArea,2,{},actor),'area entry rejects a non-public bucket')
function GetPlayerRoutingBucket(src)return T.buckets[src] or 0 end
function GetEntityCoords()return {x=163.2,y=-3024.11,z=6.05}end
assert(not pcall(R.enterFromArea,2,{},actor),'exit point outside area cannot authorize garage entry')
function GetEntityCoords()return {x=140,y=-3020,z=7}end
assert(R.enterFromArea(2,{},actor).token,'server authorizes actual position inside entry area')
assert(not pcall(R.enterFromArea,2,{},actor),'repeated area entry cannot open another private session')
GetEntityCoords,GetPlayerRoutingBucket=coords,bucket
print('4 server-side area entry assertions passed against real route with position/bucket adapters.')
