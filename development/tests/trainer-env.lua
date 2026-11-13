TrainerTest={threads={},events={},handlers={},cars={
 [1]={x=10,y=20,z=6,h=90,collision=false},[10]={x=12,y=24,z=6,h=135,collision=false,id='owned-car'}},
 vehicle=0,bucket=0,health=200,passengers=false,control=true,time=0,epoch=1,invalidations=0,notices={}}
local T=TrainerTest
function CreateThread(fn) T.threads[#T.threads+1]=coroutine.create(fn) end
function Wait(ms) local _,main=coroutine.running() if not main then coroutine.yield() else T.time=T.time+(ms or 0) end end
function GetGameTimer() return T.time end
function GetCurrentResourceName() return 'mx-freeroam-world' end
function AddEventHandler(name,fn) T.events[name]=fn end
function RegisterNetEvent(name,fn) T.events[name]=fn end
function TriggerServerEvent(name,...) local old=source source=1 T.events[name](...) source=old end
function TriggerEvent(name,data) T.notices[name]=data end
MX.actor=function(src) return src==1 and {epoch=T.epoch,id='player'} or nil end
MX.online=function(name) return name=='mx-freeroam-experience' or name=='mx-freeroam-activities' or name=='mx-freeroam-vehicles' end
MX.clients=function(domain,handlers) T.handlers[domain]=handlers end
MX.uuid=function() T.time=T.time+1 return 'grant-'..T.time end
MX.callClient=function(_,domain,action,data)
 if T.failAck then error('ACK lost') end
 if T.handlers[domain] then return T.handlers[domain][action](data) end
 return {active=true,stopped=true}
end
function GetPlayerPed() return 1 end
function PlayerPedId() return 1 end
function GetPlayerRoutingBucket() return T.bucket end
function GetEntityHealth() return T.health end
function IsEntityDead() return T.health<=0 end
function DoesEntityExist(e) return T.cars[e]~=nil end
function GetEntityCoords(e) local p=T.cars[e] return {x=p.x,y=p.y,z=p.z} end
function GetEntityHeading(e) return T.cars[e].h end
function GetEntityRotation(e) local p=T.cars[e] return {x=p.pitch or 0,y=p.roll or 0,z=p.h} end
function SetEntityRotation(e,x,y,z) local p=T.cars[e] p.pitch=x p.roll=y p.h=z end
function GetEntityAlpha(e) return T.cars[e].alpha or 255 end
function SetEntityAlpha(e,v) T.cars[e].alpha=v T.cars[e].alphaOverride=true end
function ResetEntityAlpha(e) T.cars[e].alpha=255 T.cars[e].alphaOverride=false T.cars[e].alphaResets=(T.cars[e].alphaResets or 0)+1 end
function IsEntityVisible(e) return T.cars[e].visible~=false end
function SetEntityVisible(e,v) T.cars[e].visible=v end
function SetEntityLocallyVisible(e) T.cars[e].localVisible=true end
function IsEntityPositionFrozen(e) return T.cars[e].frozen==true end
function GetVehiclePedIsIn() return T.vehicle end
function GetPedInVehicleSeat(_,seat) return seat==-1 and (T.driver==false and 2 or 1) or (T.passengers and seat==0 and 2 or 0) end
function GetVehicleMaxNumberOfPassengers() return 3 end
function NetworkGetNetworkIdFromEntity(e) return e+100 end
function NetworkDoesEntityExistWithNetworkId(net) return T.cars[net-100]~=nil end
function NetToVeh(net) return net-100 end
function NetworkHasControlOfEntity() return T.control end
function Entity(e) return {state={mxVehicle=T.cars[e].id}} end
function GetEntityCollisionDisabled(e) return T.cars[e].collision end
function FreezeEntityPosition(e,value) T.cars[e].frozen=value end
function SetEntityCollision(e,value) T.cars[e].collision=not value end
function SetEntityVelocity(e,x,y,z) T.cars[e].velocity={x,y,z} end
function SetEntityCoordsNoOffset(e,x,y,z) local p=T.cars[e] p.x=x p.y=y p.z=z end
function SetEntityHeading(e,h) T.cars[e].h=h end
function RequestCollisionAtCoord() end
function IsNuiFocused() return T.focused==true end
function IsPauseMenuActive() return false end
function DisableControlAction() end
function GetDisabledControlNormal(_,control) return control==31 and (T.forward or 0) or control==30 and (T.turn or 0) or 0 end
function IsDisabledControlPressed(_,c) return T.held and T.held[c]==true end
function IsDisabledControlJustPressed(_,c) if T.pressed and T.pressed[c] then T.pressed[c]=nil return true end return false end
function GetGameplayCamRot() return {x=T.camPitch or 0,z=T.camYaw or 0} end
function GetFrameTime() return T.dt or 1/60 end
exports=setmetatable({
 ['mx-freeroam-experience']={IsPrivate=function()return T.private==true end,InWorkshop=function()return T.private==true end,SuspendDrivecam=function(_,reason,value) assert(reason=='trainer') T.suspended=value end},
 ['mx-freeroam-activities']={Invalidate=function() T.invalidations=T.invalidations+1 end},
 ['mx-freeroam-vehicles']={OwnedDriver=function()
  MX.require(T.vehicle==10 and T.driver~=false,'DRIVER','Dirija seu carro')
  MX.require(not T.passengers,'PASSENGER','Desembarque os passageiros') return {entity=10,id='owned-car'}
 end}
},{__call=function(_,name,fn) T[name]=fn end})
WorldConfig={home='home'}
