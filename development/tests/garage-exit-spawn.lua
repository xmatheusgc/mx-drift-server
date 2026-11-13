local T=VehicleOptionsTest local actual=MX.callClient local applied=false
MX.callClient=function(src,domain,action,data)
 if action=='apply' then
    local ghost=T.cars[data.net].state.mxDepartureGhost
    assert(ghost and ghost.id==data.id and data.departure,'real spawn enables ghost before seating/application')
    applied=true
    data=MX.copy(data) data.departure=false -- Reuse the existing trainer-native adapter.
 end
 return actual(src,domain,action,data)
end
local spawned=T.exports.SpawnSavedAt(1,{model='futo',properties=VehicleProperties.defaults()},{point={x=10,y=20,z=6,h=90},ghost=true})
assert(applied and T.cars[spawned.net].state.mxDepartureGhost and T.peds[1].car==spawned.net,'real spawn preserves ghost through public driver seating')
print('Departure spawn integration: real server spawn starts ghost before apply/seating and carries protection into gameplay (adapters).')
