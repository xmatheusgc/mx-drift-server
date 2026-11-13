EntryTransferTest={time=0,vehicle=10,control=true,collision=true,entities={
 [1]={x=50,y=60,z=6,h=90,collision=true},[10]={x=50,y=60,z=6,h=90,id='original-car',net=110,driver=1,frozen=false}}}
local T=EntryTransferTest
function PlayerPedId()return 1 end
function PlayerId()return 1 end
function GetCurrentResourceName()return 'mx-freeroam-experience' end
function AddEventHandler()end
function GetGameTimer()return T.time end
function Wait(ms)T.time=T.time+math.max(ms or 0,1)end
function GetEntityCoords(e)return T.entities[e] end
function GetEntityHeading(e)return T.entities[e].h end
function GetVehiclePedIsIn()return T.vehicle end
function IsPedInAnyVehicle()return T.vehicle~=0 end
function DoesEntityExist(e)return T.entities[e]~=nil end
function Entity(e)return {state={mxVehicle=T.entities[e].id}}end
function NetworkGetNetworkIdFromEntity(e)return T.entities[e].net end
function NetworkDoesEntityExistWithNetworkId()return T.entities[10]~=nil end
function NetToVeh()return 10 end
function NetworkHasControlOfEntity()return true end
function NetworkRequestControlOfEntity()end
function GetPedInVehicleSeat(e)return T.entities[e].driver or 0 end
function GetOffsetFromEntityInWorldCoords(e,x,y,z)local p=T.entities[e]return {x=p.x+x,y=p.y+y,z=p.z+z}end
function IsEntityPositionFrozen(e)return T.entities[e].frozen==true end
function FreezeEntityPosition(e,value)T.entities[e].frozen=value end
function SetEntityVelocity()end
function SetEntityCollision(e,value)T.entities[e].collision=value end
function ClearPedTasksImmediately()T.cleared=true end
function TaskLeaveVehicle(_,car)if not T.leaveFailure then T.vehicle=0 T.entities[car].driver=0 end end
function SetPedIntoVehicle(_,car)T.vehicle=car T.entities[car].driver=1 end
function SetPlayerControl(_,value)T.control=value end
function SetEntityCoordsNoOffset(e,x,y,z)local p=T.entities[e]p.x=x p.y=y p.z=z end
function SetEntityHeading(e,h)T.entities[e].h=h end
function RequestCollisionAtCoord()end
function HasCollisionLoadedAroundEntity()return T.collision end
