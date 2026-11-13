local T,F=TrainerTest,WorldTrainer
T.vehicle=10 T.driver=true T.control=true T.bucket=0 T.private=false
T.cars[10].x=12 T.cars[10].y=24
F.save(1)
WorldConfig.destinations.home.validated=false WorldConfig.allowDrafts=false
local firstOk,firstResult=pcall(F.returnTo,1) assert(firstOk,'initial checkpoint: '..tostring(firstResult))
assert(firstResult.checkpoint,'return can reuse its own occupied position without duplicating a car')
assert(not pcall(T.routes.travel,1,{destination='home',withCar=true}),'checkpoint is independent of draft destinations; normal destination rules remain')
T.cars[10].x=500 T.blocked=true
assert(not pcall(F.returnTo,1) and T.cars[10].x==500,'other vehicles still block the checkpoint destination')
T.blocked=false T.collisionFailure=true
assert(F.returnTo(1).checkpoint and T.cars[10].x==12 and T.lastTravel.checkpoint,'collision streaming cannot reject a checkpoint return')
T.cars[10].x=500 T.teleportFailure=true
assert(not pcall(F.returnTo,1) and T.cars[10].x==500,'an actual teleport failure still releases reservation and rolls back') T.teleportFailure=false
T.collisionFailure=false F.returnTo(1)
assert(T.cars[10].x==12,'retry succeeds after collision failure')
WorldConfig.destinations.home.validated=true
T.collisionFailure=true T.cars[10].x=500
local carOk,carResult=pcall(T.routes.travel,1,{destination='home',withCar=false}) assert(carOk,'automatic car: '..tostring(carResult))
assert(T.cars[10].x==12 and T.lastTravel.net==110,'track confirmation automatically takes the driven car, ignoring an obsolete client foot selector')
T.vehicle=0 T.cars[10].x=500 T.cars[10].y=500 T.cars[1].x=800
local footOk,footResult=pcall(T.routes.travel,1,{destination='home',withCar=true}) assert(footOk,'automatic foot: '..tostring(footResult))
assert(T.cars[1].x==12 and T.lastTravel.net==nil and T.cars[10].x==500,'server automatically chooses foot travel and leaves the car behind')
T.vehicle=10 T.driver=false
assert(not pcall(T.routes.travel,1,{destination='home'}),'a passenger cannot teleport a vehicle controlled by another driver')
T.driver=true T.passengers=true
assert(not pcall(T.routes.travel,1,{destination='home'}),'other occupants remain protected by the existing passenger policy')
T.passengers=false
print('Trainer actual world travel: own-car slot reuse, occupancy, checkpoint collision bypass, actual teleport rollback and retry passed with native/network adapters.')
