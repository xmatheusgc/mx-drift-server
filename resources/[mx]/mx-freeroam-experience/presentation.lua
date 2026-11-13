-- Local, disposable visual stand-in. Only the owned workshop preview is used.
WorkshopPresentation={session=nil}
local P=WorkshopPresentation
local function owns(s) return s and DoesEntityExist(s.vehicle) and Entity(s.vehicle).state.mxVehicle==s.vehicleId end
local function actorOwned(s) return s.clone and DoesEntityExist(s.clone) and Entity(s.clone).state.mxWorkshopActor==s.id end
local function validDoor(vehicle,door) local value=GetIsDoorValid(vehicle,door) return value==true or value==1 end
function P.refreshDoors(force)
    local s=P.session if not owns(s) then return end
    local automatic=({engine=4,hood=4,trunk=5,interior=1,leftDoor=0,rightDoor=1})[s.doorRegion]
    s.doorTargets=s.doorTargets or {}
    for door=0,5 do if validDoor(s.vehicle,door) then
        local open=s.allDoors==true or (s.allDoors==nil and automatic==door)
        -- Issue native commands only on intent changes or after parts are applied.
        -- Never chase measured angles: physics/model limits need not reach 1.0.
        if force or s.doorTargets[door]~=open then
            s.doorTargets[door]=open
            if open then SetVehicleDoorOpen(s.vehicle,door,false,false)
            else SetVehicleDoorShut(s.vehicle,door,false) end
        end
    end end
end
function P.doorContext(region)
    local s=P.session if not s then return end
    s.doorRegion=region -- Manual all-open/all-closed choice lasts for this editor session.
    P.refreshDoors(false)
end
function P.toggleDoors(id)
    local s=P.session MX.require(s and s.id==id and owns(s),'SESSION')
    s.allDoors=s.allDoors~=true P.refreshDoors(false) return {open=s.allDoors}
end
local function restoreNeon(s)
    if not owns(s) or not s.neon then return end
    for i=0,3 do SetVehicleNeonLightEnabled(s.vehicle,i,s.neon.restore[i+1]) end
    SetVehicleNeonLightsColour(s.vehicle,table.unpack(s.neon.restoreColor))
    SetVehicleLights(s.vehicle,0) s.neon=nil
end
function P.ground(ped,point,ground)
    WorkshopIdle.stop(ped)
    ClearPedTasksImmediately(ped)
    SetEntityCoordsNoOffset(ped,point.x,point.y,point.z,false,false,false)
    local z=point.z
    if not point.fixed then
        local left=GetPedBoneCoords(ped,0x3779,0.0,0.0,0.0) local right=GetPedBoneCoords(ped,0xCC4D,0.0,0.0,0.0)
        z=point.z+ground+ExperienceConfig.actor.footClearance-math.min(left.z,right.z)
    end
    SetEntityCoordsNoOffset(ped,point.x,point.y,z,false,false,false) SetEntityHeading(ped,point.h)
    SetPedCanRagdoll(ped,false) TaskStandStill(ped,-1) FreezeEntityPosition(ped,true)
    return {x=point.x,y=point.y,z=z,h=point.h,groundZ=ground,fixed=point.fixed}
end
function P.stop(id)
    local s=P.session if not s or (id and id~=s.id) then return end
    P.session=nil
    local ped=PlayerPedId()
    WorkshopIdle.stop(s.clone)
    -- Hide before detach; show only after the real ped is back outside.
    SetEntityVisible(ped,false,false) SetEntityAlpha(ped,0,false)
    restoreNeon(s)
    if owns(s) then SetVehicleEngineOn(s.vehicle,false,true,true) SetVehicleHandbrake(s.vehicle,false) SetVehicleSteeringAngle(s.vehicle,0.0) for door=0,5 do if validDoor(s.vehicle,door) then SetVehicleDoorShut(s.vehicle,door,false) end end FreezeEntityPosition(s.vehicle,true) end
    if GetVehiclePedIsIn(ped,false)==s.vehicle then TaskLeaveVehicle(ped,s.vehicle,16) end
    ClearPedTasksImmediately(ped)
    FreezeEntityPosition(ped,false)
    SetEntityCoordsNoOffset(ped,s.point.x,s.point.y,s.point.z,false,false,true) SetEntityHeading(ped,s.point.h)
    if actorOwned(s) or (s.actorInitializing and s.clone and DoesEntityExist(s.clone)) then DeleteEntity(s.clone) end
    FreezeEntityPosition(ped,true) SetEntityCollision(ped,s.collision,true)
    SetEntityAlpha(ped,s.alpha,false) SetEntityVisible(ped,s.visible,false)
    SetPlayerControl(PlayerId(),s.playerControl,0)
    TriggerEvent('mx:experience:vehicleEditor',false)
end
function P.start(id,vehicle,vehicleId,point)
    if P.session and P.session.id==id and owns(P.session) then return end
    P.stop()
    WorkshopIdle.stop()
    MX.require(DoesEntityExist(vehicle) and Entity(vehicle).state.mxVehicle==vehicleId,'VEHICLE')
    local ped=PlayerPedId()
    local control=IsPlayerControlOn(PlayerId())
    local s={id=id,vehicle=vehicle,vehicleId=vehicleId,point=point,alpha=GetEntityAlpha(ped),visible=IsEntityVisible(ped),collision=not GetEntityCollisionDisabled(ped),playerControl=control==true or control==1,revUntil=0}
    P.session=s -- register before any cleanup-sensitive action
    local ok,err=pcall(function()
        s.actorInitializing=true
        s.clone=ClonePed(ped,false,false,false)
        MX.require(s.clone~=0 and DoesEntityExist(s.clone),'CHARACTER','Não foi possível preparar a apresentação externa')
        SetEntityVisible(s.clone,false,false)
        Entity(s.clone).state:set('mxWorkshopActor',id,false) s.actorInitializing=false
        SetEntityAsMissionEntity(s.clone,true,true) SetEntityInvincible(s.clone,true) SetEntityCollision(s.clone,false,false)
        SetBlockingOfNonTemporaryEvents(s.clone,true) FreezeEntityPosition(s.clone,true)
        MX.require(MX.number(point.groundZ,-1000,5000),'GROUND')
        s.point=P.ground(s.clone,point,point.groundZ)
        ClearPedTasksImmediately(ped) SetEntityVisible(ped,false,false) SetEntityAlpha(ped,0,false)
        FreezeEntityPosition(ped,false) SetEntityCollision(ped,false,false)
        SetPedIntoVehicle(ped,vehicle,-1)
        MX.require(GetPedInVehicleSeat(vehicle,-1)==ped,'DRIVER')
        -- The scene disables the player globally. Native vehicle input/audio
        -- needs an enabled driver; the render loop still blocks all other input.
        SetPlayerControl(PlayerId(),true,0)
        SetEntityVisible(s.clone,true,false)
        FreezeEntityPosition(vehicle,true) SetVehicleHandbrake(vehicle,true) SetVehicleSteeringAngle(vehicle,0.0)
        SetVehicleEngineOn(vehicle,false,true,true)
        TriggerEvent('mx:experience:vehicleEditor',true)
    end)
    if not ok then P.stop(id) error(err,0) end
end
function P.rev(id,pressed)
    local s=P.session if not s or s.id~=id then return end
    local amount=type(pressed)=='number' and math.max(0,math.min(1,pressed)) or (pressed==true and 1 or 0)
    if amount<=.05 then amount=0 end
    s.throttle=amount s.revUntil=amount>0 and GetGameTimer()+500 or 0
end
function P.previewNeon(d)
    local s=P.session
    if not s or d.id~=s.id then return {ignored=true} end
    MX.require(owns(s),'SESSION','Reabra a personalização para visualizar o neon')
    local function array(value,boolean)
        MX.require(type(value)=='table' and #value==(boolean and 4 or 3),'NEON','Prévia de neon inválida')
        for _,v in ipairs(value) do MX.require(boolean and type(v)=='boolean' or not boolean and MX.number(v,0,255,true),'NEON','Prévia de neon inválida') end
    end
    if not d.enabled then restoreNeon(s) return {enabled=false} end
    array(d.layout,true) array(d.color,false) array(d.restore,true) array(d.restoreColor,false)
    for i,bone in ipairs({'neon_l','neon_r','neon_f','neon_b'}) do MX.require(not d.layout[i] or GetEntityBoneIndexByName(s.vehicle,bone)~=-1,'NEON','Neon não suportado neste lado do veículo') end
    s.neon={layout=d.layout,color=d.color,restore=d.restore,restoreColor=d.restoreColor}
    return {enabled=true,engine=ExperienceConfig.neonPreview.engine}
end
function P.tick(dt)
    local s=P.session if not s then return end
    if not owns(s) or not actorOwned(s) or GetPedInVehicleSeat(s.vehicle,-1)~=PlayerPedId() then P.stop() return end
    P.refreshDoors(false)
    SetEntityVisible(PlayerPedId(),false,false) SetEntityAlpha(PlayerPedId(),0,false)
    local held=not s.suspended and s.revUntil>GetGameTimer()
    local now=GetGameTimer() local config=ExperienceConfig.engineTest
    local neonPower=s.neon and ExperienceConfig.neonPreview.engine and (s.neon.layout[1] or s.neon.layout[2] or s.neon.layout[3] or s.neon.layout[4])
    if held then
        s.lastThrottle=now
    end
    if (held or neonPower) and not s.running then
        s.running=true SetVehicleEngineOn(s.vehicle,true,false,true)
    elseif not held and not neonPower and s.running and (not s.lastThrottle or now-s.lastThrottle>=config.idleTimeout) then
        s.running=false SetVehicleEngineOn(s.vehicle,false,true,true)
    end
    local engineRunning=GetIsVehicleEngineRunning(s.vehicle)
    local accelerating=held and s.running and (engineRunning==true or engineRunning==1)
    local amount=accelerating and (s.throttle or 0) or 0
    -- Stationary engine/audio presentation only; no handling or drivetrain edits.
    FreezeEntityPosition(s.vehicle,true) SetVehicleHandbrake(s.vehicle,true) SetVehicleSteeringAngle(s.vehicle,0.0)
    -- Feed the native driver/audio path only after startup, with handbrake held.
    EnableControlAction(0,71,true) EnableControlAction(0,76,true) DisableControlAction(0,72,true)
    SetControlNormal(0,76,1.0) SetControlNormal(0,71,amount) SetControlNormal(0,72,0.0)
    if not s.running then SetVehicleEngineOn(s.vehicle,false,true,true) end
    -- RPM, limiter, engine braking and sound are exclusively simulated by GTA.
    if s.neon then
        SetVehicleLights(s.vehicle,2)
        for i=0,3 do SetVehicleNeonLightEnabled(s.vehicle,i,s.neon.layout[i+1]) end
        SetVehicleNeonLightsColour(s.vehicle,table.unpack(s.neon.color))
    end
end
AddEventHandler('mx:experience:keyboard',function(value) if P.session then P.session.suspended=value P.session.revUntil=0 end end)
AddEventHandler('mx:vehicles:presentationApplied',function(id) if P.session and P.session.vehicleId==id then P.refreshDoors(true) end end)
AddEventHandler('mx:experience:previewRemoved',function(id) if P.session and P.session.vehicleId==id then P.stop() end end)
AddEventHandler('onClientResourceStop',function(r) if r==GetCurrentResourceName() or r=='mx-freeroam-menu' or r=='mx-freeroam-vehicles' then P.stop() end end)
