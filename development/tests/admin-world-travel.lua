local T=TrainerTest
function IsPlayerAceAllowed(_,ace)return not T.adminDenied and (ace=='mx.admin' or ace=='mx.teleport')end
function GetInvokingResource()return 'mx-freeroam-admin'end
local function teleport(point)return MX.unwrap(T.AdminTravel(1,{mode='coordinates',point=point}))end
T.vehicle=10 T.driver=true T.passengers=false T.cars[10].x=500 T.cars[10].y=500
local r=teleport({x=300,y=400,z=20,h=120})
assert(r.point.h==120 and T.cars[10].x==300 and T.cars[10].y==400 and T.cars[10].h==120,'admin export runs actual shared travel and server position confirmation')
T.teleportFailure=true
assert(not pcall(teleport,{x=700,y=800,z=20,h=30}) and T.cars[10].x==300,'failed admin travel rolls back instead of publishing success')
T.teleportFailure=false teleport({x=700,y=800,z=20,h=30})
assert(T.cars[10].x==700,'failed admin reservation is released for retry')
T.blocked=true
assert(not pcall(teleport,{x=12,y=24,z=6,h=0}) and T.cars[10].x==700,'occupied destination stays protected for admin travel')T.blocked=false
T.passengers=true assert(not pcall(teleport,{x=300,y=400,z=20}),'admin cannot move other passengers')T.passengers=false
T.vehicle=0 local carX=T.cars[10].x
teleport({x=900,y=1000,z=40,h=60})
assert(T.cars[1].x==900 and T.cars[10].x==carX,'admin foot travel does not move or summon the saved car')
print('Admin integration with actual world travel: car/foot, heading, occupied destination, passenger guards, ACK rollback and retry passed (native/network adapters).')
