RespawnTest={time=0,car=90,id='owned-old',ped=1,inside=90,driver=1,frozen=false,locked=2,events={},threads={},control=true}
local T=RespawnTest
function GetGameTimer()return T.time end
function Wait()T.time=T.time+100 if T.inThread then coroutine.yield()end if T.onWait then T.onWait()end end
function CreateThread(fn)T.threads[#T.threads+1]=coroutine.create(fn)end
function AddEventHandler(name,fn)T.events[name]=fn end
function GetCurrentResourceName()return 'mx-freeroam-vehicles'end
function PlayerPedId()return T.ped end
function DoesEntityExist(v)return v==T.car and not T.deleted end
VehicleNetwork={resolve=function(net,id)return net==T.car and id==T.id and not T.deleted and T.car or 0 end}
function Entity()return {state={mxVehicle=T.id}}end
function GetVehicleMaxNumberOfPassengers()return 3 end
function GetPedInVehicleSeat(_,seat)return seat==-1 and T.driver or T.passenger and seat==0 and 2 or 0 end
function GetVehiclePedIsIn()return T.inside end
function IsEntityPositionFrozen()return T.frozen end
function GetVehicleDoorLockStatus()return T.locked end
function SetVehicleDoorsLocked(v,value)assert(v==T.car)T.locked=value end
function SetEntityVelocity()end
function FreezeEntityPosition(v,value)assert(v==T.car,'transfer must not freeze the ped')T.frozen=value end
function TaskLeaveVehicle()
 assert(T.locked==1,'unlock before requesting exit')
 if T.throwLeave then error('native leave failure')end
 if not T.blockLeave then T.inside=0 T.driver=0 end
end
function ClearPedTasksImmediately()T.cleared=true end
function SetPedIntoVehicle(ped,v)assert(ped==T.ped and v==T.car)T.inside=v T.driver=ped end
function NetworkRequestControlOfEntity()end
function SetPlayerControl()error('transfer must not acquire or overwrite player controls')end
