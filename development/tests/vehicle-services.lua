local T=VehicleApplyTest local car=T.cars[71] local driver=true local speed=35
function PlayerPedId() return 1 end
function GetPedInVehicleSeat(_,seat) return seat==-1 and driver and 1 or 0 end
function GetVehicleMaxNumberOfPassengers()return 3 end
function GetEntityCoords()return {x=0,y=0,z=0}end
function GetEntitySpeed() return speed end
function SetVehicleFixed() car.repaired=true end
function SetVehicleDeformationFixed() end
function SetVehicleEngineHealth(_,value) car.health=value end
function SetVehicleDirtLevel(_,value) car.dirt=value end
function WashDecalsFromVehicle() end
function SetEntityVelocity(_,x,y,z) car.velocity={x,y,z} end
function SetVehicleForwardSpeed(_,value) car.speed=value end
function GetEntityRotation() return {x=90,y=15,z=120} end
function SetEntityRotation(_,x,y,z) car.rotation={x,y,z} end
function SetVehicleOnGroundProperly() car.grounded=true end
function GetIsVehicleEngineRunning() return car.running==true end
function SetVehicleEngineOn(_,value) car.running=value end
car.doors={}
function GetIsDoorValid(_,door) return door<4 end
function GetVehicleDoorAngleRatio(_,door) return car.doors[door] or 0 end
function SetVehicleDoorOpen(_,door) car.doors[door]=1 end
function SetVehicleDoorShut(_,door) car.doors[door]=0 end
local function service(kind) return T.handlers.service({net=71,id=car.id,kind=kind}) end
car.velocity={0,35,0} service('repair') service('clean')
assert(car.repaired and car.health==1000 and car.dirt==0 and car.velocity[2]==35,'repair/clean work without stopping a moving car')
service('engine') assert(car.running) service('engine') assert(not car.running)
function GetVehicleIndicatorLights()return car.indicators or 0 end
function SetVehicleIndicatorLights(_,side,on)
 local bit=side==1 and 1 or 2 local state=car.indicators or 0
 if on and state & bit==0 then state=state+bit elseif not on and state & bit~=0 then state=state-bit end
 car.indicators=state
end
service('indicatorLeft')assert(car.indicators==1,'left indicator')
service('indicatorLeft')assert(car.indicators==0,'same indicator toggles off')
service('indicatorRight')assert(car.indicators==2,'right indicator')
service('hazards')assert(car.indicators==3,'hazards enable both sides')
service('indicatorLeft')assert(car.indicators==1,'left replaces hazards')
service('hazards')service('hazards')assert(car.indicators==0,'hazards toggle off')
driver=false assert(not pcall(service,'hazards'),'passenger cannot operate indicators')driver=true
service('doors') assert(car.doors[0]==1 and car.doors[3]==1 and not car.doors[4]) service('doors') assert(car.doors[0]==0)
assert(not pcall(service,'flip'),'moving flip is rejected') speed=0
service('flip') assert(car.grounded and car.rotation[1]==0 and car.rotation[3]==120 and car.velocity[2]==0)
service('stop') assert(car.speed==0)
driver=false assert(pcall(service,'clean') and pcall(service,'engine'),'nearby owner can clean and use engine on foot')
assert(not pcall(service,'stop'),'driver-only stop remains protected on foot')
T.handlers.service({net=71,id=car.id,kind='doors',door=0}) assert(car.doors[0]==1 and car.doors[1]==0,'single-door action leaves other doors unchanged')
assert(not pcall(T.handlers.service,{net=71,id=car.id,kind='doors',door=5}),'missing model door is rejected')
function GetVehicleDoorLockStatus()return car.locked and 2 or 1 end
function SetVehicleDoorsLocked(_,value)car.locked=value==2 end
service('lock') assert(car.locked) service('lock') assert(not car.locked,'lock toggles both ways')
local seated=71
function GetVehiclePedIsIn()return seated end
function TaskLeaveVehicle(_,v,flags)assert(v==71 and flags==16)seated=0 driver=false end
function FreezeEntityPosition(_,value)car.frozen=value end
assert(T.handlers.eject({net=71,id=car.id}).left and seated==0,'target client leaves only the addressed vehicle')
driver=true seated=71
function IsEntityPositionFrozen()return car.frozen==true end
function SetPedIntoVehicle()seated=71 driver=true end
assert(T.handlers.prepareRespawn({net=71,id=car.id,transfer='service-test'}).ready and seated==0 and car.frozen and not car.locked,'respawn preparation freezes old car but unlocks before detaching its owner')
assert(T.handlers.resumeRespawn({net=71,id=car.id,transfer='service-test'}).resumed and not car.frozen and not car.locked and seated==71,'failed respawn releases old-car state and restores driver')
local oldEntity,oldDrift=Entity,VehicleDrift
local forcedRepair=false
Entity=function(v)local e=oldEntity(v)e.state.mxDrift={id=car.id,enabled=true}return e end
VehicleDrift={ensure=function(v,id,enabled,notify)forcedRepair=v==71 and id==car.id and enabled and notify return {enabled=true}end}
service('repair')assert(forcedRepair,'actual repair handler rebuilds enabled drift after repair natives')
driver=true speed=35 forcedRepair=false
local encode=json.encode json.encode=function()return '{}'end
T.handlers.service({net=71,id=car.id,kind='drift',enabled=true})
json.encode=encode
assert(forcedRepair,'client permits drift activation while driving in motion')
Entity,VehicleDrift=oldEntity,oldDrift
print('Vehicle services: repair/clean preserve moving velocity; engine/doors toggle, flip/stop reset velocity and stale driver is rejected (native adapters).')
