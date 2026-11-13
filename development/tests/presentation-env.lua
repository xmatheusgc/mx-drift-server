-- Explicit unit doubles. No audio, streaming, collision or FiveM physics runs here.
PresentationTest={time=0,entities={[1]={visible=true,alpha=255,collision=true},[10]={vehicle=true,id='preview',x=1,y=2,z=3}},events={},nextPed=100}
local T=PresentationTest
function PlayerPedId() return 1 end
function PlayerId()return 0 end
function IsPlayerControlOn()return T.playerControl==true end
function SetPlayerControl(_,value)T.playerControl=value end
function EnableControlAction(_,control)T.enabled=T.enabled or {} T.enabled[control]=true end
function GetGameTimer() return T.time end
function GetCurrentResourceName() return 'mx-freeroam-experience' end
function AddEventHandler(k,fn) T.events[k]=fn end
function TriggerEvent(k,v) T.lastEvent={k,v} end
function DoesEntityExist(v) return T.entities[v]~=nil end
function Entity(v) local e=T.entities[v] e.state=e.state or {} e.state.mxVehicle=e.id e.state.set=function(_,k,value) e.state[k]=value end return {state=e.state} end
function ClonePed(_,network,host,blend) T.cloneFlags={network,host,blend} T.nextPed=T.nextPed+1 T.entities[T.nextPed]={visible=true,alpha=255,collision=true} return T.nextPed end
function GetEntityAlpha(v) return T.entities[v].alpha end
function IsEntityVisible(v) return T.entities[v].visible end
function GetEntityCollisionDisabled(v) return not T.entities[v].collision end
function SetEntityVisible(v,value) T.entities[v].visible=value end
function SetEntityAlpha(v,value) T.entities[v].alpha=value end
function SetEntityCollision(v,value) T.entities[v].collision=value end
function FreezeEntityPosition(v,value) T.entities[v].frozen=value end
function SetEntityCoordsNoOffset(v,x,y,z) local e=T.entities[v] e.x=x e.y=y e.z=z end
function SetEntityHeading(v,h) T.entities[v].h=h end
function SetEntityAsMissionEntity() end
function SetEntityInvincible() end
function SetBlockingOfNonTemporaryEvents() end
function TaskStartScenarioInPlace() end
function ClearPedTasksImmediately() end
function SetPedIntoVehicle(ped,vehicle) T.entities[vehicle].driver=ped T.vehicle=vehicle end
function GetPedInVehicleSeat(v) return T.entities[v] and T.entities[v].driver or 0 end
function GetVehiclePedIsIn() return T.vehicle or 0 end
function TaskLeaveVehicle(_,v) T.vehicle=nil if T.entities[v] then T.entities[v].driver=0 end end
function SetVehicleEngineOn(v,value) T.entities[v].engine=value end
function SetVehicleHandbrake(v,value) T.entities[v].handbrake=value end
function SetVehicleSteeringAngle(v,value) T.entities[v].steering=value end
function GetIsDoorValid(_,door)if T.missingDoors and T.missingDoors[door] then return false end return door>=0 and door<=5 end
function GetVehicleDoorAngleRatio(v,door)return (T.entities[v].doors or {})[door] or 0 end
function SetVehicleDoorOpen(v,door,loose,instant)
 assert(not loose and not instant,'native opening keeps hinge and animation')
 T.doorCalls=(T.doorCalls or 0)+1
 T.entities[v].doors=T.entities[v].doors or {} T.entities[v].doors[door]=1
end
function SetVehicleDoorShut(v,door,instant)
 assert(not instant,'native closing keeps animation')
 T.doorCalls=(T.doorCalls or 0)+1
 T.entities[v].doors=T.entities[v].doors or {} T.entities[v].doors[door]=0
end
function SetVehicleDoorControl()error('presentation must not force door angles')end
function SetVehicleCurrentRpm(v,value) T.rpmWrites=(T.rpmWrites or 0)+1 T.entities[v].rpm=value end
function GetIsVehicleEngineRunning(v)if T.cranking then return false end return T.entities[v].engine==true end
function DisableControlAction()end
function SetVehicleNeonLightEnabled(v,i,value)T.entities[v].neon=T.entities[v].neon or {} T.entities[v].neon[i+1]=value end
function SetVehicleNeonLightsColour(v,r,g,b)T.entities[v].neonColor={r,g,b}end
function SetVehicleLights(v,value)T.entities[v].lights=value end
function SetControlNormal(_,control,value) T.controls=T.controls or {} T.controls[control]=value end
function DeleteEntity(v) T.entities[v]=nil end

function GetPedBoneCoords(v) local e=T.entities[v] return {x=e.x or 0,y=e.y or 0,z=(e.z or 1)+(e.footOffset or -1)} end
function SetPedCanRagdoll() end
function TaskStandStill() end
