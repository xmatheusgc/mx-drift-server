DriftTest={cars={[1]={id='one'},[2]={id='two'}},writes=0,events={},threads={},wanted={},control=true}
local T=DriftTest
for _,car in pairs(T.cars) do
 car.highGear=6 car.powered={true,true,false,false} car.derivedForce=2 car.derivedVelocity=2 car.refreshes=0
 car.fields={}
 for key in pairs(VehicleDriftPreset.floats)do car.fields[key]=2.0 end
 for key in pairs(VehicleDriftPreset.ints)do car.fields[key]=6 end
 for key in pairs(VehicleDriftPreset.vectors)do car.fields[key]={x=1,y=2,z=3}end
 for key in pairs(VehicleDriftPreset.car)do car.fields[key]=.5 end
end
function CreateThread(fn)T.threads[#T.threads+1]=coroutine.create(fn)end
function Wait()coroutine.yield()end
function GetGamePool()return {1,2}end
function AddEventHandler(name,fn)T.events[name]=fn end
function TriggerEvent(name,...)
 if T.events[name] then T.events[name](...) end
end
function DoesEntityExist(v)return T.cars[v]~=nil end
function Entity(v)return {state={mxVehicle=T.cars[v].id,mxDrift=T.wanted[v]}}end
function vector3(x,y,z)return {x=x,y=y,z=z}end
local function get(v,class,key) if T.missing==key then return false end return T.cars[v].fields[key] end
local function set(v,class,key,value)T.writes=T.writes+1 if T.rejectOnce==key then T.rejectOnce=nil return end if T.reject~=key then T.cars[v].fields[key]=value end end
GetVehicleHandlingFloat=get GetVehicleHandlingInt=get GetVehicleHandlingVector=get
SetVehicleHandlingFloat=set SetVehicleHandlingInt=set SetVehicleHandlingVector=set
function GetCurrentResourceName()return 'mx-freeroam-vehicles' end

function GetVehicleNumberOfWheels()return 4 end
function GetVehicleHighGear(v)return T.cars[v].highGear end
function SetVehicleHighGear(v,value)T.cars[v].highGear=value end
function GetVehicleWheelIsPowered(v,wheel)return T.cars[v].powered[wheel+1]end
function SetVehicleWheelIsPowered(v,wheel,value)if not T.rejectWheel then T.cars[v].powered[wheel+1]=value end end
function NetworkHasControlOfEntity()return T.control end
function ModifyVehicleTopSpeed(v,percent)
 assert(percent==0.0,'handling refresh must not add any power/speed percentage')
 local car=T.cars[v] car.refreshes=car.refreshes+1
 if T.failRefreshOnce then T.failRefreshOnce=false error('one-shot refresh failure')end
 if T.failRefresh then error('transmission refresh failed')end
 car.derivedForce=car.fields.fInitialDriveForce car.derivedVelocity=car.fields.fInitialDriveMaxFlatVel
end
