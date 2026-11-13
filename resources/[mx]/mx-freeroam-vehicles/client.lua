local snapshot,editingNet,editDeadline=nil,nil,0
exports('SetPreviewIntent',VehicleAssets.setIntent)
exports('IsDriftHandlingApplied',function(v) return VehicleDrift.isApplied(v) end)
local baseline={}
local capabilities=VehicleCustomization.inspect
exports('PreviewStance',function(v,id,value)
    MX.require(GetInvokingResource()=='mx-freeroam-experience','FORBIDDEN')
    MX.require(DoesEntityExist(v) and Entity(v).state.mxVehicle==id and NetworkHasControlOfEntity(v),'OBSOLETE')
    VehicleStance.ensure(v,id,value,true)
    return VehicleStance.options(v)
end)
-- RGB xenon is local-only in CFX. The server publishes validated presentation /
-- gameplay state; reapply on streaming and resource restart, including observers.
local xenonPending={}
local function syncXenon(v,data)
    if not data or type(data)~='table' or Entity(v).state.mxVehicle~=data.id then return end
    if type(data.enabled)~='boolean' or not MX.number(data.index,-1,255,true) then return end
    ToggleVehicleMod(v,22,data.enabled)
    if type(data.rgb)=='table' and #data.rgb==3 then
        for _,n in ipairs(data.rgb) do if not MX.number(n,0,255,true) then return end end
        SetVehicleXenonLightsCustomColor(v,table.unpack(data.rgb))
    elseif data.rgb==false then ClearVehicleXenonLightsCustomColor(v) SetVehicleXenonLightsColor(v,data.index or 255) end
end
AddStateBagChangeHandler('mxXenon',nil,function(bag,_,data) if type(data)=='table' then xenonPending[bag]={data=data,expires=GetGameTimer()+10000} else xenonPending[bag]=nil end end)
CreateThread(function()
    for _,v in ipairs(GetGamePool('CVehicle')) do syncXenon(v,Entity(v).state.mxXenon) end
    while true do
        Wait(100)
        for bag,p in pairs(xenonPending) do
            local v=GetEntityFromStateBagName(bag)
            if v~=0 and DoesEntityExist(v) and Entity(v).state.mxVehicle==p.data.id then syncXenon(v,p.data) xenonPending[bag]=nil
            elseif GetGameTimer()>p.expires then xenonPending[bag]=nil end
        end
    end
end)
local function vehicle(d)
    local deadline=GetGameTimer()+8000 local v=VehicleNetwork.resolve(d.net,d.id)
    while (v==0 or not DoesEntityExist(v) or Entity(v).state.mxVehicle~=d.id) and GetGameTimer()<deadline do Wait(50) v=VehicleNetwork.resolve(d.net,d.id) end
    MX.require(v~=0 and DoesEntityExist(v) and Entity(v).state.mxVehicle==d.id,'VEHICLE_SYNC','O veículo de rede não chegou ao cliente (net '..tostring(d.net)..')')
    NetworkRequestControlOfEntity(v)
    while not NetworkHasControlOfEntity(v) and GetGameTimer()<deadline do NetworkRequestControlOfEntity(v) Wait(50) end
    MX.require(NetworkHasControlOfEntity(v),'OWNER','Sem controle de rede; tente novamente')
    MX.require(DoesEntityExist(v) and VehicleNetwork.resolve(d.net,d.id)==v and Entity(v).state.mxVehicle==d.id,'OBSOLETE','Veículo substituído durante a aquisição de controle')
    if not baseline[v] or baseline[v].id~=d.id then baseline[v]={id=d.id} end
    return v
end
local function apply(v,p)
    p=VehicleProperties.validate(MX.copy(p))
    local requestedWheels={p.wheelType,p.mods['23'] or p.mods[23] or -1,p.mods['24'] or p.mods[24] or -1}
    local modsRecovered=VehicleCustomization.preflight(v,p)
    local recovered=requestedWheels[1]~=p.wheelType or requestedWheels[2]~=(p.mods['23'] or p.mods[23] or -1) or requestedWheels[3]~=(p.mods['24'] or p.mods[24] or -1)
    baseline[v]=baseline[v] or {}
    if baseline[v].interiorColor==nil then baseline[v].interiorColor=GetVehicleInteriorColor(v) baseline[v].dashboardColor=GetVehicleDashboardColor(v) baseline[v].roofLivery=GetVehicleRoofLivery(v) baseline[v].livery=GetVehicleLivery(v) baseline[v].modLivery=GetVehicleMod(v,48) end
    for id=0,20 do if DoesExtraExist(v,id) and baseline[v][id]==nil then baseline[v][id]=VehicleCustomization.extraEnabled(v,id) end end
    VehicleStance.restore(v)
    SetVehicleModKit(v,0)
    if GetVehicleWheelType(v)~=p.wheelType then SetVehicleWheelType(v,p.wheelType) end
    ToggleVehicleMod(v,22,p.xenon)
    if GetVehicleWheelType(v)~=p.wheelType then SetVehicleWheelType(v,p.wheelType) end
    recovered=VehicleCustomization.installWheels(v,p) or recovered
    for slot=0,49 do
        if VehicleProperties.allowedSlot(slot) and slot~=23 and slot~=24 then
            local explicit=p.mods[tostring(slot)] or p.mods[slot]
            local value=explicit or (slot==48 and baseline[v].modLivery) or -1
            local legacyLivery=slot==48 and p.livery>=0 and (explicit==nil or explicit<0)
            local variation=slot==23 and p.customTyres or slot==24 and p.customRearTyres or false
            if not legacyLivery and (GetVehicleMod(v,slot)~=value or ((slot==23 or slot==24) and GetVehicleModVariation(v,slot)~=variation)) then SetVehicleMod(v,slot,value,variation) end
        end
    end
    VehicleCustomization.extras(v,p,baseline[v])
    VehicleCustomization.liveries(v,p,baseline[v])
    VehicleCustomization.paint(v,p,baseline[v])
    SetVehicleNumberPlateText(v,p.plate) SetVehicleNumberPlateTextIndex(v,p.plateStyle) SetVehicleWindowTint(v,p.tint)
    ToggleVehicleMod(v,18,p.turbo) ToggleVehicleMod(v,20,p.smoke)
    for i=0,3 do SetVehicleNeonLightEnabled(v,i,p.neon[i+1]) end
    SetVehicleNeonLightsColour(v,p.neonColor[1],p.neonColor[2],p.neonColor[3]) SetVehicleTyreSmokeColor(v,p.smokeColor[1],p.smokeColor[2],p.smokeColor[3])
    local stanceId=Entity(v).state.mxVehicle
    if VehicleStance.awaitReady then VehicleStance.awaitReady(v,stanceId,p.stance,750) end
    local stance=VehicleStance.ensure(v,stanceId,p.stance,true)
    VehicleCustomization.confirmPaint(v,p)
    for key,value in pairs(p.mods) do
        local slot=tonumber(key)
        if VehicleProperties.allowedSlot(slot) and not (slot==48 and p.livery>=0 and value<0) then
            local observed=GetVehicleMod(v,slot)
            MX.require(observed==value,'APPLY',('Peça não confirmada (slot %s, esperado %s, recebido %s).'):format(slot,value,observed))
        end
    end
    local wheels=recovered and {wheelType=p.wheelType,front=-1,rear=-1,customTyres=false,customRearTyres=false} or nil
    return stance,wheels,modsRecovered
end
VehicleDisplay={apply=function(v,properties)
    local id=Entity(v).state.mxVehicle
    if not baseline[v] or baseline[v].id~=id then baseline[v]={id=id}end
    return apply(v,properties)
end} -- Private cosmetic adapter for disposable local scenery.
exports('PresentationOptions',function(d) return VehicleCustomization.options(vehicle(d),d.slot,d.id) end)
exports('ObservedSignature',function(net)
    local v=NetToVeh(net) if v==0 then return nil end
    local p=VehicleProperties.defaults() p.stance=VehicleStance.current(v) p.wheelType=GetVehicleWheelType(v) p.turbo=IsToggleModOn(v,18) p.customTyres=GetVehicleModVariation(v,23) p.customRearTyres=GetVehicleModVariation(v,24)
    for _,slot in ipairs({11,12,13,15,16,23,24}) do p.mods[tostring(slot)]=GetVehicleMod(v,slot) end
    return VehicleProperties.signature(p)
end)
MX.clients('vehicles',{
    previewCleared=function(d)
        local deadline=GetGameTimer()+3000 local v=VehicleNetwork.resolve(d.net,d.id)
        while v~=0 and DoesEntityExist(v) and Entity(v).state.mxVehicle==d.id and GetGameTimer()<deadline do Wait(0) v=VehicleNetwork.resolve(d.net,d.id) end
        for handle,value in pairs(baseline) do if value.id==d.id then baseline[handle]=nil end end
        TriggerEvent('mx:experience:previewRemoved',d.id)
        return {cleared=v==0 or not DoesEntityExist(v) or Entity(v).state.mxVehicle~=d.id}
    end,
    load=function(d)
        return VehicleAssets.load(d.model,d.intent)
    end,
    apply=function(d)
        local v=vehicle(d)
        if VehicleDepartureGhost then VehicleDepartureGhost.track(v) end
        local stance,wheels,modsRecovered=apply(v,d.properties)
        if d.presentation then if not baseline[v].presented then SetVehicleOnGroundProperly(v) SetVehicleEngineOn(v,false,true,true) baseline[v].presented=true end FreezeEntityPosition(v,true) SetEntityInvincible(v,true) SetVehicleDoorsLocked(v,2) SetVehicleDirtLevel(v,0.0) end
        if d.departure then FreezeEntityPosition(v,true) SetVehicleHandbrake(v,true) SetVehicleEngineOn(v,false,true,true) end
        if d.seat then SetPedIntoVehicle(PlayerPedId(),v,-1) SetVehicleOnGroundProperly(v) SetModelAsNoLongerNeeded(GetEntityModel(v)) end
        if d.departure then SetVehicleEngineOn(v,false,true,true) end
        if d.editing==false then snapshot=nil editingNet=nil end
        if d.editing==true then editDeadline=GetGameTimer()+VehicleConfig.editTimeout end
        local extras={} for id=0,20 do if DoesExtraExist(v,id) then extras[tostring(id)]=VehicleCustomization.extraEnabled(v,id) end end
        local inspected=capabilities(v)
        local drift=d.drift and VehicleDrift.ensure(v,d.id,true,true) or nil
        local wheelWarning=wheels and 'A roda salva não está mais disponível ou não foi confirmada. Rodas originais restauradas; escolha outra roda na personalização.' or nil
        if wheelWarning and not baseline[v].wheelWarning then baseline[v].wheelWarning=true TriggerEvent('mx:notice',wheelWarning) end
        local modsWarning=modsRecovered and 'Peças salvas indisponíveis neste modelo foram restauradas para as originais. As demais modificações foram mantidas.' or nil
        if modsWarning and not baseline[v].modsWarning then baseline[v].modsWarning=true TriggerEvent('mx:notice',modsWarning) end
        -- Ground placement, family discovery and optional handling refresh can
        -- rebuild wheel meshes after the first application. Reassert last.
        VehicleStance.refresh(v)
        if d.presentation then TriggerEvent('mx:vehicles:presentationApplied',d.id) end
        return {applied=true,extras=extras,capabilities=inspected,drift=drift,stance=stance,wheels=wheels,modsRecovered=modsRecovered,warning=wheelWarning or modsWarning or stance.warning or (drift and drift.warning)}
    end,
    depart=function(d)
        MX.require(MX.number(d.minimumMs,0,1500,true),'PAYLOAD')
        local v=vehicle(d)
        local function owned() return DoesEntityExist(v) and VehicleNetwork.resolve(d.net,d.id)==v and Entity(v).state.mxVehicle==d.id and NetworkHasControlOfEntity(v) end
        local function valid() MX.require(owned() and GetPedInVehicleSeat(v,-1)==PlayerPedId(),'DRIVER','A partida perdeu o veículo ou motorista; reabra a garagem') end
        valid() FreezeEntityPosition(v,true) SetVehicleHandbrake(v,true)
        local started=GetGameTimer() local running=false
        local ok,err=pcall(function()
            SetVehicleEngineOn(v,true,false,true)
            repeat
                valid()
                DisableControlAction(0,71,true) DisableControlAction(0,72,true)
                SetControlNormal(0,71,0.0) SetControlNormal(0,72,0.0)
                local state=GetIsVehicleEngineRunning(v) running=state==true or state==1
                -- Starter animation is optional feedback, never a gameplay gate.
                if GetGameTimer()-started>=d.minimumMs then break end
                Wait(0)
            until false
        end)
        if owned() then FreezeEntityPosition(v,false) SetVehicleHandbrake(v,false) if not ok then SetVehicleEngineOn(v,false,true,true) end end
        if not ok then error(err,0) end
        return {running=running}
    end,
    inspect=function(d)
        local v=vehicle(d) SetVehicleModKit(v,0) snapshot=MX.copy(d.properties) editingNet=d
        editDeadline=GetGameTimer()+VehicleConfig.editTimeout
        return capabilities(v)
    end,
    handlingAudit=function(d)
        local v=VehicleNetwork.resolve(d.net,d.id)
        MX.require(v~=0,'VEHICLE_SYNC','Aproxime-se do seu carro para ler o diagnóstico')
        local report=VehicleDrift.audit(v,d.id,d.enabled)
        report.networkControl=NetworkHasControlOfEntity(v)
        return report
    end,
    serviceInfo=function(d)
        local v=VehicleNetwork.resolve(d.net,d.id)
        if v==0 then return {streamed=false,doors={}} end
        local doors={} for door=0,5 do if GetIsDoorValid(v,door) then doors[#doors+1]=door end end
        local supported=VehicleDrift.supported(v,d.id)
        return {streamed=true,doors=doors,driftSupported=supported}
    end,
    eject=function(d)
        local v=VehicleNetwork.resolve(d.net,d.id) local ped=PlayerPedId()
        if v==0 or GetVehiclePedIsIn(ped,false)~=v then return {left=true} end
        TaskLeaveVehicle(ped,v,16)
        local deadline=GetGameTimer()+2500
        while GetVehiclePedIsIn(ped,false)==v and GetGameTimer()<deadline do Wait(0) end
        return {left=GetVehiclePedIsIn(ped,false)~=v}
    end,
    prepareRespawn=function(d)
        return VehicleRespawn.begin(d,vehicle(d))
    end,
    resumeRespawn=function(d)
        return VehicleRespawn.resume(d)
    end,
    service=function(d)
        local v=vehicle(d)
        local ped=PlayerPedId()
        MX.require(MX.distance(GetEntityCoords(ped),GetEntityCoords(v))<=60,'DISTANCE','Aproxime-se do seu veículo')
        if d.driver or d.kind=='stop' or d.kind=='drift' then MX.require(GetPedInVehicleSeat(v,-1)==ped,'DRIVER','Entre no banco do motorista do seu carro') end
        if d.kind=='flip' or d.kind=='stop' then for seat=-1,GetVehicleMaxNumberOfPassengers(v)-1 do local p=GetPedInVehicleSeat(v,seat) MX.require(p==0 or p==ped,'PASSENGER','Desembarque os outros ocupantes') end end
        if d.kind=='flip' then MX.require(GetEntitySpeed(v)<=.5,'MOVING','Pare o veículo antes de desvirar') end
        if d.kind=='repair' then SetVehicleFixed(v) SetVehicleDeformationFixed(v) SetVehicleEngineHealth(v,1000.0)
        elseif d.kind=='clean' then SetVehicleDirtLevel(v,0.0) WashDecalsFromVehicle(v,1.0)
        elseif d.kind=='flip' then SetEntityVelocity(v,0.0,0.0,0.0) local r=GetEntityRotation(v,2) SetEntityRotation(v,0,0,r.z,2,true) SetVehicleOnGroundProperly(v)
        elseif d.kind=='stop' then SetEntityVelocity(v,0.0,0.0,0.0) SetVehicleForwardSpeed(v,0.0)
        elseif d.kind=='engine' then SetVehicleEngineOn(v,not GetIsVehicleEngineRunning(v),false,true)
        elseif d.kind=='indicatorLeft' or d.kind=='indicatorRight' or d.kind=='hazards' then
            MX.require(GetPedInVehicleSeat(v,-1)==ped,'DRIVER','Entre no banco do motorista do seu carro')
            local current=GetVehicleIndicatorLights(v)
            local target=d.kind=='indicatorLeft' and 1 or d.kind=='indicatorRight' and 2 or 3
            if current==target then target=0 end
            SetVehicleIndicatorLights(v,1,target==1 or target==3)
            SetVehicleIndicatorLights(v,0,target==2 or target==3)
            return {indicators=target}
        elseif d.kind=='lock' then local locked=GetVehicleDoorLockStatus(v)>=2 SetVehicleDoorsLocked(v,locked and 1 or 2) return {locked=not locked}
        elseif d.kind=='drift' then
            local result=VehicleDrift.ensure(v,d.id,d.enabled,true)
            print('[MX:HANDLING] '..json.encode(result))
            return result
        elseif d.kind=='doors' then
            local door=d.door or -1 MX.require(MX.number(door,-1,5,true),'DOOR','Porta inválida')
            if door~=-1 then MX.require(GetIsDoorValid(v,door),'DOOR','Esta porta não existe neste modelo') end
            local open=false for index=0,5 do if (door==-1 or index==door) and GetIsDoorValid(v,index) and GetVehicleDoorAngleRatio(v,index)<.1 then open=true break end end
            for index=0,5 do if (door==-1 or index==door) and GetIsDoorValid(v,index) then if open then SetVehicleDoorOpen(v,index,false,false) else SetVehicleDoorShut(v,index,false) end end end
        end
        local drift
        if d.kind=='repair' then
            local state=Entity(v).state.mxDrift
            if type(state)=='table' and state.id==d.id and state.enabled==true then drift=VehicleDrift.ensure(v,d.id,true,true) end
        end
        return {drift=drift,warning=drift and drift.warning}
    end
})
CreateThread(function()
    while true do
        Wait(500)
        if snapshot and editingNet and GetGameTimer()>editDeadline then local v=VehicleNetwork.resolve(editingNet.net,editingNet.id) if DoesEntityExist(v) and Entity(v).state.mxVehicle==editingNet.id then pcall(apply,v,snapshot) end snapshot=nil editingNet=nil end
        for v in pairs(baseline) do if not DoesEntityExist(v) then baseline[v]=nil end end
    end
end)
AddEventHandler('mx:menu:close',function()
    if snapshot then
        if editingNet then local v=VehicleNetwork.resolve(editingNet.net,editingNet.id) if DoesEntityExist(v) and Entity(v).state.mxVehicle==editingNet.id then pcall(apply,v,snapshot) end end
        CreateThread(function() for _=1,4 do local r=MX.request('vehicles','cancel',{}) if r.ok or r.code~='BUSY' then break end Wait(500) end end)
    end
end)
AddEventHandler('onClientResourceStop',function(name)
    if name==GetCurrentResourceName() and snapshot and editingNet then local v=VehicleNetwork.resolve(editingNet.net,editingNet.id) if DoesEntityExist(v) and Entity(v).state.mxVehicle==editingNet.id then pcall(apply,v,snapshot) end end
end)
