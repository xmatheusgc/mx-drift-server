-- Public car -> private presentation, with an identity-scoped rollback snapshot.
WorkshopTransfer={}
local T=WorkshopTransfer
local snapshot=nil
local function same(s)
    return s.car and DoesEntityExist(s.car) and NetworkGetNetworkIdFromEntity(s.car)==s.net and Entity(s.car).state.mxVehicle==s.id
end
function T.pending() return snapshot~=nil end
function T.finish()
    local s=snapshot snapshot=nil
    if s and same(s) then FreezeEntityPosition(s.car,s.frozen) end
end
function T.begin(d)
    MX.require(not snapshot,'BUSY','Aguarde a entrada anterior terminar')
    local ped=PlayerPedId() local car=GetVehiclePedIsIn(ped,false)
    local p=GetEntityCoords(ped)
    local s={point={x=p.x,y=p.y,z=p.z,h=GetEntityHeading(ped)}}
    if car~=0 then
        MX.require(d.net and NetworkGetNetworkIdFromEntity(car)==d.net and Entity(car).state.mxVehicle==d.id and NetworkHasControlOfEntity(car) and GetPedInVehicleSeat(car,-1)==ped,'DRIVER','O veículo ou motorista mudou; entrada cancelada')
        s.car=car s.net=d.net s.id=d.id s.frozen=IsEntityPositionFrozen(car)
        local safe=GetOffsetFromEntityInWorldCoords(car,3.0,0.0,0.0)
        s.point={x=safe.x,y=safe.y,z=safe.z,h=GetEntityHeading(car)}
    end
    snapshot=s -- Register before the first mutation, so every failure can roll back.
    SetPlayerControl(PlayerId(),false,0)
    if car~=0 then
        FreezeEntityPosition(car,true) SetEntityVelocity(car,0.0,0.0,0.0)
        TaskLeaveVehicle(ped,car,16)
        local deadline=GetGameTimer()+3000
        while IsPedInAnyVehicle(ped,false) and GetGameTimer()<deadline do Wait(0) end
        MX.require(not IsPedInAnyVehicle(ped,false),'DRIVER','Não foi possível desembarcar para entrar na garagem')
    end
    ClearPedTasksImmediately(ped) FreezeEntityPosition(ped,true) SetEntityCollision(ped,true,true)
    return {ready=true}
end
function T.restore(fallback)
    local s=snapshot local ped=PlayerPedId() local seated=false
    local ok=pcall(function()
        ClearPedTasksImmediately(ped)
        if s and s.net then
            local deadline=GetGameTimer()+1500
            repeat
                if NetworkDoesEntityExistWithNetworkId(s.net) then
                    local car=NetToVeh(s.net)
                    if DoesEntityExist(car) and Entity(car).state.mxVehicle==s.id then s.car=car break end
                end
                Wait(0)
            until GetGameTimer()>=deadline
            if same(s) then
                local controlDeadline=GetGameTimer()+1000
                while not NetworkHasControlOfEntity(s.car) and GetGameTimer()<controlDeadline do NetworkRequestControlOfEntity(s.car) Wait(0) end
            end
        end
        if s and same(s) and NetworkHasControlOfEntity(s.car) and (GetPedInVehicleSeat(s.car,-1)==0 or GetPedInVehicleSeat(s.car,-1)==ped) then
            SetPedIntoVehicle(ped,s.car,-1)
            seated=GetVehiclePedIsIn(ped,false)==s.car
        end
        if not seated then
            local point=s and s.point or fallback
            if s and same(s) then
                -- Never place a pedestrian at the occupied car's centre.
                local p=GetOffsetFromEntityInWorldCoords(s.car,3.0,0.0,0.0)
                point={x=p.x,y=p.y,z=p.z,h=GetEntityHeading(s.car)}
            end
            if point then
                FreezeEntityPosition(ped,true)
                SetEntityCoordsNoOffset(ped,point.x,point.y,point.z,false,false,false) SetEntityHeading(ped,point.h or 0)
                local deadline=GetGameTimer()+3000
                repeat RequestCollisionAtCoord(point.x,point.y,point.z) if HasCollisionLoadedAroundEntity(ped) then break end Wait(0) until GetGameTimer()>=deadline
                MX.require(HasCollisionLoadedAroundEntity(ped),'COLLISION','O cenário de retorno ainda não carregou')
            end
        end
    end)
    -- Cleanup does not depend on the teleport/collision/seat operation succeeding.
    if not seated then ClearPedTasksImmediately(ped) end
    SetEntityCollision(ped,true,true) FreezeEntityPosition(ped,false) SetPlayerControl(PlayerId(),true,0)
    T.finish()
    return {recovered=ok,seated=seated}
end
AddEventHandler('onClientResourceStop',function(name)
    if name==GetCurrentResourceName() and snapshot then T.restore() end
end)
