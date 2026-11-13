GhostTest={time=0,pairs={},events={},entities={
 [1]={x=0,y=0,z=0,bucket=0,vehicle=10,state={}},
 [2]={x=0,y=0,z=0,bucket=0,vehicle=0,state={}},
 [10]={x=0,y=0,z=0,bucket=0,state={mxVehicle='departure'}},
 [20]={x=0,y=0,z=0,bucket=0,state={mxVehicle='traffic'}},
 [30]={x=100,y=0,z=0,bucket=0,state={mxVehicle='far'}}}}
local T=GhostTest
function CreateThread()end
function AddEventHandler(name,fn)T.events[name]=fn end
function AddStateBagChangeHandler(_,_,fn)T.bag=fn end
function GetCurrentResourceName()return 'test-vehicles' end
function GetGameTimer()return T.time end
function DoesEntityExist(e)return T.entities[e]~=nil end
function Entity(e)
 local state=T.entities[e].state
 state.set=function(self,key,value)self[key]=value end
 return {state=state}
end
function GetAllVehicles()return {10,20,30}end
function GetPlayers()return {'1','2'}end
function GetPlayerPed(src)return tonumber(src)end
function GetVehiclePedIsIn(ped)return T.entities[ped].vehicle end
function GetEntityCoords(e)return T.entities[e]end
function GetEntityRoutingBucket(e)return T.entities[e].bucket end
function GetPlayerRoutingBucket(src)return T.entities[tonumber(src)].bucket end
function GetGamePool(kind)if kind=='CVehicle' then return GetAllVehicles()end return {1,2}end
function GetEntityFromStateBagName()return 10 end
function SetEntityNoCollisionEntity(a,b,frame)
 assert(frame==true,'suppression must expire each frame without permanent cleanup')
 T.pairs[a..':'..b]=true
end
