AdminLocalTools={enabled=false,target='ped',expires=0}
local T=AdminLocalTools
local function emit(data) TriggerEvent('mx:admin:telemetry',data) end
function T.stop() T.enabled=false T.expires=0 emit(false) end
function T.snapshot(target)
    MX.require(target=='ped' or target=='vehicle' or target=='camera','PAYLOAD')
    local entity=PlayerPedId() local p,h
    if target=='camera' then p=GetFinalRenderedCamCoord() h=GetFinalRenderedCamRot(2).z
    else
        if target=='vehicle' then entity=GetVehiclePedIsIn(entity,false) MX.require(entity~=0,'VEHICLE','Entre em um veículo para capturar suas coordenadas') end
        MX.require(DoesEntityExist(entity),'ENTITY') p=GetEntityCoords(entity) h=GetEntityHeading(entity)
    end
    local result={target=target,x=p.x,y=p.y,z=p.z,h=h%360}
    if target~='camera' then
        result.model=GetEntityModel(entity) result.entity=entity result.interior=GetInteriorFromEntity(entity)
        result.networkId=NetworkGetEntityIsNetworked(entity) and NetworkGetNetworkIdFromEntity(entity) or 0
        if target=='vehicle' then result.name=GetDisplayNameFromVehicleModel(result.model) end
    end
    return result
end
function T.tick()
    if not T.enabled then return end
    if GetGameTimer()>=T.expires then T.stop() return end
    local ok,result=pcall(T.snapshot,T.target)
    emit(ok and result or {target=T.target,error=MX.error(result).message})
end
function T.configure(d)
    if not d.enabled then T.stop() return {enabled=false} end
    T.snapshot(d.target) -- Do not enable a vehicle panel while on foot.
    T.target=d.target T.enabled=true T.expires=GetGameTimer()+6000 T.tick()
    return {enabled=true,target=T.target}
end
function T.waypoint()
    local blip=GetFirstBlipInfoId(8)
    MX.require(DoesBlipExist(blip),'WAYPOINT','Marque um destino no mapa antes de teleportar')
    local p=GetBlipCoords(blip) local loading=false local focused=false
    local ok,result=pcall(function()
        SetFocusPosAndVel(p.x,p.y,0.0,0.0,0.0,0.0) focused=true
        loading=NewLoadSceneStartSphere(p.x,p.y,0.0,100.0,0)
        MX.require(loading,'STREAM','Não foi possível preparar o marcador')
        local deadline=GetGameTimer()+8000
        repeat
            RequestCollisionAtCoord(p.x,p.y,1000.0)
            local found,z=GetGroundZFor_3dCoord(p.x,p.y,1000.0,false)
            if IsNewLoadSceneLoaded() and found then return {x=p.x,y=p.y,z=z+1.0} end
            MX.require(GetGameTimer()<deadline,'GROUND','Não foi possível localizar solo no marcador. Use coordenadas com Z explícito para interiores ou locais sem solo.')
            Wait(50)
        until false
    end)
    if loading then NewLoadSceneStop() end
    if focused then ClearFocus() end
    if not ok then error(result,0) end
    return result
end
MX.clients('admin',{snapshot=function(d)return T.snapshot(d.target)end,tools=T.configure,waypoint=T.waypoint})
RegisterNetEvent('mx:admin:toolsGrant',function(enabled)
    if source~=65535 then return end
    if not enabled then T.stop() elseif T.enabled then T.expires=GetGameTimer()+6000 end
end)
AddEventHandler('mx:experience:state',T.stop)
AddEventHandler('mx:experience:lobby',T.stop)
AddEventHandler('mx:profile:local',T.stop)
AddEventHandler('onClientResourceStop',function(name) if name==GetCurrentResourceName() then T.stop() end end)
CreateThread(function() while true do Wait(T.enabled and 100 or 500) T.tick() end end)
