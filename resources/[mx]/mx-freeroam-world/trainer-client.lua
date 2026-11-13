local function binding(action,held,control)
    if GetResourceState('mx-freeroam-menu')=='started' then
        return exports['mx-freeroam-menu']:BindingInput(action,held)
    end
    return held and IsDisabledControlPressed(0,control) or not held and IsDisabledControlJustPressed(0,control)
end
local current=nil
local retired={}
local function state(s)
    return {noclip=true,speed=s.speed,followCamera=s.followCamera,speedLabel=TrainerConfig.speeds[s.speed].label}
end
local function publish(s,sync)
    TriggerEvent('mx:trainer:state',state(s))
    if sync then TriggerServerEvent('mx:trainer:settings',s.token,s.speed,s.followCamera) end
end
local function capture(entity)
    return {entity=entity,alpha=GetEntityAlpha(entity),visible=IsEntityVisible(entity),frozen=IsEntityPositionFrozen(entity),collisionDisabled=GetEntityCollisionDisabled(entity)}
end
local function restore(saved)
    FreezeEntityPosition(saved.entity,saved.frozen) SetEntityCollision(saved.entity,not saved.collisionDisabled,true)
    -- Reset the rendering override, rather than assigning alpha=255 over it.
    -- Preserve deliberate opacity from another flow captured before noclip.
    ResetEntityAlpha(saved.entity)
    if saved.alpha<255 then SetEntityAlpha(saved.entity,saved.alpha,false) end
    SetEntityVisible(saved.entity,saved.visible,false)
end
local function ghost(entity)
    -- Local visibility is frame scoped; stop explicitly resets this alpha override.
    SetEntityVisible(entity,false,false) SetEntityLocallyVisible(entity) SetEntityAlpha(entity,TrainerConfig.ghostAlpha,false)
end
local function suspendDrivecam(value)
    if MX.online('mx-freeroam-experience') then pcall(function() exports['mx-freeroam-experience']:SuspendDrivecam('trainer',value) end) end
end
local function same(s)
    return s~=nil and DoesEntityExist(s.entity) and (s.net and NetworkGetNetworkIdFromEntity(s.entity)==s.net and Entity(s.entity).state.mxVehicle==s.id or not s.net and PlayerPedId()==s.entity)
end
local function stop(notify)
    local s=current current=nil
    if s then retired[s.token]=GetGameTimer()+60000 end
    if s and same(s) then
        restore(s.saved)
        SetEntityVelocity(s.entity,0.0,0.0,0.0)
    end
    if s and s.ped and s.ped.entity==PlayerPedId() and DoesEntityExist(s.ped.entity) then restore(s.ped) end
    if s and notify then TriggerServerEvent('mx:trainer:stopped',s.token) end
    suspendDrivecam(false)
    TriggerEvent('mx:trainer:state',{noclip=false})
    return {stopped=true}
end
local function valid(s)
    local ped=PlayerPedId()
    if not same(s) or IsEntityDead(ped) then return false end
    if s.net then
        if GetVehiclePedIsIn(ped,false)~=s.entity or GetPedInVehicleSeat(s.entity,-1)~=ped or not NetworkHasControlOfEntity(s.entity) then return false end
        for seat=0,GetVehicleMaxNumberOfPassengers(s.entity)-1 do if GetPedInVehicleSeat(s.entity,seat)~=0 then return false end end
    elseif GetVehiclePedIsIn(ped,false)~=0 then return false end
    return not (MX.online('mx-freeroam-experience') and exports['mx-freeroam-experience']:InWorkshop())
end
MX.clients('trainer',{
    start=function(d)
        MX.require(MX.text(d.token,1,64) and MX.number(d.speed,1,#TrainerConfig.speeds,true) and (d.followCamera==nil or type(d.followCamera)=='boolean'),'PAYLOAD')
        for token,expires in pairs(retired) do if expires<GetGameTimer() then retired[token]=nil end end
        MX.require(not retired[d.token],'OBSOLETE','Esta autorização de noclip já foi encerrada')
        if current and current.token==d.token then
            MX.require(valid(current),'ENTITY','Noclip perdeu o controle da entidade')
            current.speed=d.speed
            if d.followCamera~=nil then current.followCamera=d.followCamera end
            publish(current,false) return {active=true}
        end
        stop(true)
        local entity=PlayerPedId()
        if d.net then
            MX.require(NetworkDoesEntityExistWithNetworkId(d.net),'ENTITY','Veículo fora do escopo de rede')
            entity=NetToVeh(d.net)
        end
        local s={entity=entity,net=d.net,id=d.id,token=d.token,speed=d.speed,followCamera=d.followCamera~=false,heading=GetEntityHeading(entity)}
        MX.require(valid(s),'DRIVER','Noclip exige seu veículo, sem passageiros e com controle de rede')
        s.saved=capture(entity)
        if d.net then s.ped=capture(PlayerPedId()) end
        current=s FreezeEntityPosition(entity,true) SetEntityCollision(entity,false,false) SetEntityVelocity(entity,0.0,0.0,0.0)
        ghost(entity) if s.ped then ghost(s.ped.entity) end
        suspendDrivecam(true)
        publish(s,false)
        return {active=true}
    end,
    stop=function(d)
        MX.require(MX.text(d.token,1,64),'PAYLOAD')
        retired[d.token]=GetGameTimer()+60000
        if current and current.token~=d.token then return {stopped=false} end
        return stop(false)
    end
})
exports('StopLocalTrainer',function()
    if not current then return false end
    stop(true) return true
end)
CreateThread(function()
    while true do
        if not current then Wait(0) else
            Wait(0) local s=current
            -- stop/start RPCs can run during Wait(0). An empty session must not
            -- kill this coroutine and strand the next activation invisible.
            if s and not valid(s) then stop(true) elseif s then
                for _,c in ipairs({20,21,22,23,24,25,30,31,32,33,34,35,36,44,48,59,60,63,64,68,69,70,71,72,74,75,76,85,86,101}) do DisableControlAction(0,c,true) end
                -- Reassert local ghost visibility every frame; do not toggle collision on/off between ticks.
                FreezeEntityPosition(s.entity,true) SetEntityCollision(s.entity,false,false) ghost(s.entity)
                if s.ped then ghost(s.ped.entity) end
                if not IsNuiFocused() and not IsPauseMenuActive() then
                    local controls=TrainerConfig.controls
                    if binding('cycleSpeed',false,controls.cycleSpeed) then s.speed=s.speed%#TrainerConfig.speeds+1 publish(s,true) end
                    if binding('cameraMode',false,controls.cameraMode) then s.followCamera=not s.followCamera publish(s,true) end
                    local f=-GetDisabledControlNormal(0,31) local r=GetDisabledControlNormal(0,30)
                    local up=(binding('up',true,controls.up) and 1 or 0)-(binding('down',true,controls.down) and 1 or 0)
                    local dt=math.min(GetFrameTime(),.05)
                    if s.followCamera then s.heading=GetGameplayCamRot(2).z
                    else s.heading=(s.heading-r*TrainerConfig.turnDegreesPerSecond*dt)%360 end
                    -- Forward movement is horizontal, so looking up does not alter height.
                    local yaw=math.rad(s.heading)
                    local dx,dy,dz=-math.sin(yaw)*f,math.cos(yaw)*f,up
                    local norm=math.max(1,math.sqrt(dx*dx+dy*dy+dz*dz))
                    local delta=dt*TrainerConfig.speeds[s.speed].mps/norm
                    local p=GetEntityCoords(s.entity)
                    SetEntityCoordsNoOffset(s.entity,math.max(-20000,math.min(20000,p.x+dx*delta)),math.max(-20000,math.min(20000,p.y+dy*delta)),math.max(-100,math.min(3000,p.z+dz*delta)),false,false,false)
                    SetEntityRotation(s.entity,0.0,0.0,s.heading,2,true) SetEntityVelocity(s.entity,0.0,0.0,0.0)
                    RequestCollisionAtCoord(p.x,p.y,p.z)
                end
            end
        end
    end
end)
AddEventHandler('onClientResourceStop',function(name)
    if name==GetCurrentResourceName() or name=='mx-freeroam-menu' or name=='mx-freeroam-experience' then stop(true) end
end)
