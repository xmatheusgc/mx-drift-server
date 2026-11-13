local reservations,entries,entered={},{},{}
local function available(d) return d and (d.validated or WorldConfig.allowDrafts) and (not d.asset or MX.online(d.asset)) end
local function reserve(src,id,override,presentationExit,ignoreEntity)
    local d=presentationExit and {id=id,validated=true,slots={override}} or WorldConfig.destinations[id]
    MX.require(available(d),'DESTINATION','Destino não validado ou mapa indisponível')
    local now=GetGameTimer()
    local bucket=GetPlayerRoutingBucket(src)
    for i,slot in ipairs(override and {override} or d.slots) do
        local key=bucket..':'..id..':'..(override and ('recovery:'..slot.x..':'..slot.y) or i) local r=reservations[key]
        local free=not r or r.expires<now
        if free then for _,other in pairs(reservations) do if other.bucket==bucket and other.expires>=now and MX.distance(other.point,slot)<6 then free=false break end end end
        if free then
            for _,v in ipairs(GetAllVehicles()) do if v~=ignoreEntity and GetEntityRoutingBucket(v)==bucket and MX.distance(GetEntityCoords(v),slot)<5 then free=false break end end
            if free then for _,p in ipairs(GetPlayers()) do if tonumber(p)~=src and GetPlayerRoutingBucket(p)==bucket and MX.distance(GetEntityCoords(GetPlayerPed(p)),slot)<3 then free=false break end end end
        end
        if free then reservations[key]={src=src,bucket=bucket,point=slot,expires=now+30000} return {key=key,point=slot} end
    end
    MX.fail('SLOTS','Todos os pontos estão ocupados; tente novamente')
end
exports('Reserve',reserve)
exports('ReservePresentationExit',function(src,point)
    MX.require(MX.number(point.x,-20000,20000) and MX.number(point.y,-20000,20000) and MX.number(point.z,-100,3000) and MX.number(point.h,0,360),'DESTINATION')
    -- This server-authored exit uses entity ghosting, so traffic and concurrent
    -- departures must not reserve/block it. Other travel reservations stay strict.
    return {point=MX.copy(point),ghost=true}
end)
exports('ReserveNearest',function(src)
    local origin=GetEntityCoords(GetPlayerPed(src)) local choices={}
    for id,d in pairs(WorldConfig.destinations) do if available(d) then choices[#choices+1]={id=id,distance=MX.distance(origin,d.slots[1])} end end
    table.sort(choices,function(a,b) return a.distance<b.distance end)
    for _,choice in ipairs(choices) do if choice.distance<150 then local ok,slot=pcall(reserve,src,choice.id) if ok then return slot end end end
    MX.fail('SLOTS','Aproxime-se de um destino aprovado com vaga para criar o carro')
end)
exports('Release',function(key,src) if reservations[key] and reservations[key].src==src then reservations[key]=nil end end)
exports('Destinations',function() return MX.copy(WorldConfig.destinations) end)
exports('Conditions',function() return WorldConfig.revision end)
local function invalidate(src,reason) if MX.online('mx-freeroam-activities') then exports['mx-freeroam-activities']:Invalidate(src,reason) end end
local function travel(src,id,withCar,pointOverride,checkpoint)
    WorldTrainer.stop(src)
    MX.require(not MX.online('mx-freeroam-experience') or not exports['mx-freeroam-experience']:IsPrivate(src),'SESSION','Saia pela oficina')
    local actor=MX.actor(src) MX.require(actor,'SESSION')
    local vehicle,vehicleId=0,nil
    if withCar then
        MX.require(MX.online('mx-freeroam-vehicles'),'UNAVAILABLE')
        local active=exports['mx-freeroam-vehicles']:OwnedDriver(src,true)
        vehicle=active.entity vehicleId=active.id
    else MX.require(GetVehiclePedIsIn(GetPlayerPed(src),false)==0,'PASSENGER','Desembarque antes de viajar a pé') end
    invalidate(src,'travel')
    local slot=reserve(src,checkpoint and 'checkpoint' or id,pointOverride,checkpoint==true,vehicle~=0 and vehicle or nil)
    local entity=vehicle~=0 and vehicle or GetPlayerPed(src)
    local old=GetEntityCoords(entity) local heading=GetEntityHeading(entity)
    local ok,err=pcall(function()
        local response=MX.callClient(src,'world','travel',{point=slot.point,net=vehicle~=0 and NetworkGetNetworkIdFromEntity(vehicle) or nil,id=vehicleId,checkpoint=checkpoint==true})
        MX.require(response.arrived==true,'TELEPORT','O teleporte não foi concluído; tente novamente')
        local deadline=GetGameTimer()+2000
        while DoesEntityExist(entity) and MX.distance(GetEntityCoords(entity),slot.point)>=12 and GetGameTimer()<deadline do Wait(0) end
        MX.require(MX.actor(src) and MX.actor(src).epoch==actor.epoch,'SESSION','A sessão mudou durante o teleporte')
        MX.require(DoesEntityExist(entity) and (vehicle==0 and GetPlayerPed(src)==entity or vehicle~=0 and Entity(entity).state.mxVehicle==vehicleId),'ENTITY','A entidade do teleporte foi substituída')
        MX.require(MX.distance(GetEntityCoords(entity),slot.point)<12,'POSITION','Destino não confirmado pelo servidor')
    end)
    reservations[slot.key]=nil
    if not ok then
        if MX.actor(src) and MX.actor(src).epoch==actor.epoch and DoesEntityExist(entity) and (vehicle==0 and GetPlayerPed(src)==entity or vehicle~=0 and Entity(entity).state.mxVehicle==vehicleId) then SetEntityCoords(entity,old.x,old.y,old.z,false,false,false,false) SetEntityHeading(entity,heading) end
        error(err,0)
    end
    return {destination=id}
end
exports('Travel',travel)
WorldTrainer.travel=travel
MX.routes('world',{
    trainerState=WorldTrainer.status,
    noclip=WorldTrainer.noclip,
    toggleNoclip=WorldTrainer.toggle,
    saveCheckpoint=WorldTrainer.save,
    returnCheckpoint=WorldTrainer.returnTo,
    clearCheckpoint=WorldTrainer.clear,
    entry=function(src)
        MX.require(not MX.online('mx-freeroam-experience') or not exports['mx-freeroam-experience']:IsPrivate(src),'SESSION')
        MX.require(not entered[src] or GetEntityHealth(GetPlayerPed(src))<=0,'RESPAWN','Use destinos para viajar')
        MX.require(not entries[src],'BUSY')
        local slot=reserve(src,WorldConfig.home) entries[src]=slot
        return {point=slot.point,key=slot.key}
    end,
    entryDone=function(src,d)
        local slot=entries[src] MX.require(slot and slot.key==d.key,'RESPAWN')
        MX.require(MX.distance(GetEntityCoords(GetPlayerPed(src)),slot.point)<15,'POSITION')
        reservations[slot.key]=nil entries[src]=nil entered[src]=true return {}
    end,
    destinations=function() local list={} for _,d in pairs(WorldConfig.destinations) do local copy=MX.copy(d) copy.available=available(d) list[#list+1]=copy end return list end,
    travel=function(src,d)
        MX.require(type(d.destination)=='string','PAYLOAD')
        -- The server chooses the travel mode from the actual ped state.
        return travel(src,d.destination,GetVehiclePedIsIn(GetPlayerPed(src),false)~=0)
    end,
    recover=function(src,d) local destination=WorldConfig.home local point
        if MX.online('mx-freeroam-activities') then local recovery=exports['mx-freeroam-activities']:Recovery(src) if recovery then destination=recovery.destination point=recovery.point end end
        return travel(src,destination,d.withCar==true,point)
    end
})
CreateThread(function()
    -- Allow native ambient population; client script-owned entities remain blocked.
    SetRoutingBucketEntityLockdownMode(0,'relaxed') SetRoutingBucketPopulationEnabled(0,true)
    for id,d in pairs(WorldConfig.destinations) do
        assert(id==d.id and #d.slots>0,'Destino inválido')
        for _,p in ipairs(d.slots) do assert(MX.number(p.x,-20000,20000) and MX.number(p.y,-20000,20000) and MX.number(p.z,-100,3000),'Coordenada inválida') end
    end
end)
AddEventHandler('weaponDamageEvent',function() CancelEvent() end)
AddEventHandler('explosionEvent',function() CancelEvent() end)
AddEventHandler('giveWeaponEvent',function() CancelEvent() end)
AddEventHandler('removeWeaponEvent',function() CancelEvent() end)
AddEventHandler('playerDropped',function() entries[source]=nil entered[source]=nil for key,r in pairs(reservations) do if r.src==source then reservations[key]=nil end end end)
CreateThread(function() while true do Wait(1000) for src,slot in pairs(entries) do if not reservations[slot.key] or reservations[slot.key].expires<GetGameTimer() then reservations[slot.key]=nil entries[src]=nil end end end end)
