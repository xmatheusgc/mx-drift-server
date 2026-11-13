local T=GhostTest local G=VehicleDepartureGhost
T.entities[10].state.mxDepartureGhost={id='departure'}
G.frame()
assert(T.pairs['10:20'] and T.pairs['20:10'] and T.pairs['10:2'] and T.pairs['2:10'],'observer protects both directions against vehicles and pedestrians')
assert(not T.pairs['10:30'],'distant entities are excluded')
T.pairs={} T.time=16 G.frame() assert(T.pairs['10:20'],'every frame renews collision suppression')
T.entities[10].state.mxDepartureGhost=nil T.pairs={} T.time=32 G.frame()
assert(next(T.pairs)==nil,'server clear restores collision next frame')
T.entities[10].state.mxDepartureGhost={id='departure'} T.entities[10].state.mxVehicle='reused'
T.time=200 G.frame() assert(next(T.pairs)==nil,'reused handles cannot inherit ghost')
T.entities[10].state.mxVehicle='departure' T.time=800 G.frame()
assert(T.pairs['10:20'],'streaming/restart discovers active protection from authoritative entity state')
-- No SetEntityCollision native is supplied: disabling map/floor collision would fail.
print('Departure ghost client: observer symmetry, per-frame renewal, immediate clear, identity reuse and streamed state replay passed; floor collision untouched (adapters).')
