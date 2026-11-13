local T,F=EntryTransferTest,WorkshopTransfer
local d={net=110,id='original-car'}
assert(F.begin(d).ready and T.vehicle==0 and T.entities[10].frozen and not T.control,'detach freezes only original car before bucket transfer')
T.entities[1].x=135 T.entities[1].collision=false
assert(F.restore().seated and T.vehicle==10 and T.control and T.entities[1].collision and not T.entities[1].frozen and not T.entities[10].frozen,'rollback restores driver, collision, controls and original freeze state')
assert(not F.pending())
F.begin(d) T.entities[10].driver=2
assert(not F.restore().seated and T.entities[1].x==53 and T.control,'occupied driver seat returns beside car, never inside its centre')
T.entities[10].driver=1 T.vehicle=10
F.begin(d) T.entities[10].id='reused-entity'
F.restore() assert(T.entities[10].frozen and T.control,'rollback never mutates a reused unrelated entity')
T.entities[10].id='original-car' T.entities[10].frozen=false T.entities[10].driver=1 T.vehicle=10
T.leaveFailure=true assert(not pcall(F.begin,d) and F.pending(),'failed leave still has a rollback snapshot')
F.restore() assert(T.control and not T.entities[10].frozen,'failed leave can restore original driver') T.leaveFailure=false
F.begin(d) T.entities[10].driver=2 T.collision=false
assert(not F.restore().recovered and T.control and T.entities[1].collision and not T.entities[1].frozen,'collision failure cannot skip final control cleanup') T.collision=true
T.entities[10].driver=1 T.vehicle=10 F.begin(d) F.finish()
assert(not F.pending() and not T.entities[10].frozen,'successful entry releases the temporary public-car snapshot')
print('Entry-transfer regressions: coordinated detach, original-car rollback, occupied seat, reused identity, failed leave/collision and commit cleanup passed with native adapters.')
