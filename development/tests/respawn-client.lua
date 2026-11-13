local T,R=RespawnTest,VehicleRespawn
local function data(token)return {net=90,id='owned-old',transfer=token}end
T.blockLeave=true
local failure=R.begin(data('one'),90)
assert(not failure.ready and failure.reason=='EXIT_TIMEOUT' and failure.recovered,'detach timeout reports reason and restores locally')
assert(not T.frozen and T.locked==2 and T.inside==90,'failed exit restores original lock and car movement')
T.blockLeave=false
assert(R.begin(data('two'),90).ready and T.inside==0 and T.frozen,'retry after local failure works')
assert(not R.resume(data('one')).resumed and T.frozen,'late rollback cannot cancel newer transfer')
assert(R.resume(data('two')).resumed and not T.frozen and T.inside==90,'server abort reseats original driver and releases car')
T.throwLeave=true
assert(not pcall(R.begin,data('throw'),90) and not T.frozen and T.locked==2,'native exception also restores before propagating')
T.throwLeave=false
assert(R.begin(data('watch'),90).ready)
T.time=T.time+10001 T.inThread=true
assert(coroutine.resume(T.threads[1])) assert(coroutine.resume(T.threads[1])) T.inThread=false
assert(not T.frozen and T.inside==90,'watchdog recovers if server rollback is lost')
assert(R.begin(data('stop'),90).ready)
T.events.onClientResourceStop('mx-freeroam-vehicles')
assert(not T.frozen and T.inside==90 and T.locked==2,'resource stop releases its pending transfer')
assert(R.begin(data('reused'),90).ready)
T.id='other-identity' T.frozen=false T.locked=4 T.inside=0
R.resume(data('reused'))
assert(T.locked==4 and T.inside==0,'identity reuse never touches another vehicle')
T.id='owned-old' T.driver=1 T.inside=90 T.locked=1
assert(R.begin(data('passenger'),90).ready)
T.driver=2 R.resume(data('passenger'))
assert(T.inside==0 and not T.frozen,'rollback never steals an occupied driver seat')
T.driver=1 T.inside=90 T.passenger=true
assert(not pcall(R.begin,data('occupied'),90) and not T.frozen,'passenger rejected before mutations')
T.passenger=false
assert(R.begin(data('deleted'),90).ready)
T.deleted=true T.inThread=true assert(coroutine.resume(T.threads[1])) T.inThread=false
assert(R.resume(data('deleted')).resumed,'deleted old vehicle clears transaction safely')
print('Actual respawn client: unlock before leave, local timeout/exception rollback, retry, stale transfer, lost ACK watchdog, resource stop, reused identity and occupied seat passed with native adapters.')
