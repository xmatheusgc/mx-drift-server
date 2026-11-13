local T=NetworkScopeTest
assert(VehicleNetwork.resolve(65534,'owned')==0 and T.conversions==0,'unstreamed network ID is never converted')
T.visible=true
assert(VehicleNetwork.resolve(65534,'owned')==10,'65534 is not blacklisted when scoped and owned')
T.id='reused'
assert(VehicleNetwork.resolve(65534,'owned')==0,'reused network ID cannot target another entity')
T.id='owned' T.exists=false
assert(VehicleNetwork.resolve(65534,'owned')==0,'removed entity cannot be used')
T.exists=true T.vehicle=false
assert(VehicleNetwork.resolve(65534,'owned')==0,'non-vehicle rejected')
local before=T.conversions
assert(VehicleNetwork.resolve(nil,'owned')==0 and VehicleNetwork.resolve(0,'owned')==0 and T.conversions==before,'invalid IDs cannot reach conversion native')
print('6 verificações de escopo/identidade de network ID aprovadas; natives simuladas')
