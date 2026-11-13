local profile,spawning,initial=nil,false,false
local lobbyClock=nil
-- World remains the single clock writer; presentation never races its loop.
exports('SetLobbyTime',function(hour,minute,weather)
    MX.require(GetInvokingResource()=='mx-freeroam-experience','RESOURCE')
    if hour==nil then lobbyClock=nil return end
    MX.require(MX.number(hour,0,23,true) and MX.number(minute,0,59,true),'TIME')
    MX.require(weather==nil or weather=='FOGGY','WEATHER')
    lobbyClock={hour=hour,minute=minute,weather=weather}
end)
local outfits={
    driver={{[3]=0,[4]=10,[6]=10,[8]=15,[11]=5},{[3]=0,[4]=1,[6]=1,[8]=15,[11]=0},{[3]=1,[4]=4,[6]=4,[8]=15,[11]=1}},
    driver_f={{[3]=0,[4]=0,[6]=1,[8]=14,[11]=0},{[3]=0,[4]=1,[6]=1,[8]=14,[11]=0},{[3]=1,[4]=4,[6]=4,[8]=14,[11]=1}}
}
local function appearance(p)
    local model=joaat(WorldConfig.appearances[p.appearance] or WorldConfig.appearances.driver)
    RequestModel(model) local deadline=GetGameTimer()+8000
    while not HasModelLoaded(model) and GetGameTimer()<deadline do Wait(50) end
    MX.require(HasModelLoaded(model),'MODEL','Modelo de personagem indisponível')
    SetPlayerModel(PlayerId(),model) SetPedDefaultComponentVariation(PlayerPedId())
    for component,drawable in pairs(outfits[p.appearance][(p.outfit or 0)+1]) do
        if GetNumberOfPedDrawableVariations(PlayerPedId(),component)>drawable then SetPedComponentVariation(PlayerPedId(),component,drawable,0,0) end
    end
    SetModelAsNoLongerNeeded(model)
end
local function loadCollision(entity,p)
    FreezeEntityPosition(entity,true) RequestCollisionAtCoord(p.x,p.y,p.z)
    SetEntityCoordsNoOffset(entity,p.x,p.y,p.z,false,false,false) SetEntityHeading(entity,p.h or 0)
    local deadline=GetGameTimer()+8000
    while not HasCollisionLoadedAroundEntity(entity) and GetGameTimer()<deadline do RequestCollisionAtCoord(p.x,p.y,p.z) Wait(50) end
    return HasCollisionLoadedAroundEntity(entity)
end
local function spawn()
    if spawning or not profile then return end spawning=true
    local ped=PlayerPedId()
    local ok,err=pcall(function()
        DoScreenFadeOut(200) Wait(250)
        local response=MX.request('world','entry',{}) MX.require(response.ok,response.code,response.message)
        if not MX.online('mx-freeroam-experience') or not exports['mx-freeroam-experience']:ApplyConfirmed() then appearance(profile.preferences) end ped=PlayerPedId()
        local p=response.data.point
        NetworkResurrectLocalPlayer(p.x,p.y,p.z,p.h,true,false)
        MX.require(loadCollision(ped,p),'COLLISION')
        SetEntityHealth(ped,200) ClearPedTasksImmediately(ped)
        SetEntityVisible(ped,true,false) SetEntityCollision(ped,true,true)
        Wait(500) local confirmed=MX.request('world','entryDone',{key=response.data.key}) MX.require(confirmed.ok,confirmed.code,confirmed.message)
    end)
    ShutdownLoadingScreen() ShutdownLoadingScreenNui()
    FreezeEntityPosition(ped,false) SetEntityInvincible(ped,false) SetPlayerControl(PlayerId(),true,0) DoScreenFadeIn(250) spawning=false
    if not ok then TriggerEvent('mx:notice',type(err)=='table' and err.message or 'Falha no spawn seguro; use M > Destinos') end
end
RegisterCommand('mxrespawn',function() CreateThread(spawn) end,false)
AddEventHandler('mx:profile:local',function(p)
    local changed=profile and (profile.preferences.appearance~=p.preferences.appearance or profile.preferences.outfit~=p.preferences.outfit)
    profile=p
    if not initial then initial=true if not MX.online('mx-freeroam-experience') then CreateThread(spawn) end elseif changed and not MX.online('mx-freeroam-experience') then CreateThread(function() pcall(appearance,p.preferences) end) end
end)
MX.clients('world',{
    travel=function(d)
        if d.net then MX.require(NetworkDoesEntityExistWithNetworkId(d.net),'ENTITY','O veículo não está no escopo de rede') end
        local entity=d.net and NetToVeh(d.net) or PlayerPedId()
        MX.require(entity~=0 and DoesEntityExist(entity),'ENTITY')
        MX.require(not d.net or (GetPedInVehicleSeat(entity,-1)==PlayerPedId() and NetworkHasControlOfEntity(entity)),'DRIVER','O controle do veículo mudou; tente novamente')
        do
            MX.require(not d.net or Entity(entity).state.mxVehicle==d.id,'ENTITY','O veículo do teleporte foi substituído')
            local frozen=IsEntityPositionFrozen(entity)
            local old=GetEntityCoords(entity) local rotation=GetEntityRotation(entity,2)
            local ok,err=pcall(function()
                FreezeEntityPosition(entity,true) SetEntityVelocity(entity,0.0,0.0,0.0)
                RequestCollisionAtCoord(d.point.x,d.point.y,d.point.z) -- Streaming hint, never a teleport acceptance gate.
                SetEntityCoordsNoOffset(entity,d.point.x,d.point.y,d.point.z,false,false,false)
                SetEntityRotation(entity,d.point.pitch or 0,d.point.roll or 0,d.point.h or 0,2,true)
            end)
            if not ok then
                pcall(SetEntityCoordsNoOffset,entity,old.x,old.y,old.z,false,false,false)
                pcall(SetEntityRotation,entity,rotation.x,rotation.y,rotation.z,2,true)
            end
            FreezeEntityPosition(entity,frozen)
            if not ok then error(err,0) end
            return {arrived=true}
        end
    end
})
CreateThread(function()
    for _,name in ipairs(WorldConfig.blockedWeapons) do local pickup=GetPickupHashFromWeapon(joaat('WEAPON_'..name)) if pickup~=0 then ToggleUsePickupsForPlayer(PlayerId(),pickup,false) end end
    for _,name in ipairs({'PICKUP_ARMOUR_STANDARD','PICKUP_MONEY_VARIABLE','PICKUP_MONEY_WALLET','PICKUP_AMMO_PISTOL','PICKUP_AMMO_RIFLE','PICKUP_AMMO_SHOTGUN','PICKUP_AMMO_SMG','PICKUP_AMMO_SNIPER','PICKUP_AMMO_MG','PICKUP_AMMO_RPG'}) do ToggleUsePickupsForPlayer(PlayerId(),joaat(name),false) end
    while true do
        local ped=PlayerPedId() SetMaxWantedLevel(0) ClearPlayerWantedLevel(PlayerId())
        for i=1,15 do EnableDispatchService(i,false) end
        RemoveAllPedWeapons(ped,true) SetCanAttackFriendly(ped,false,false) NetworkSetFriendlyFireOption(false)
        SetEntityProofs(ped,true,true,true,true,true,true,true,false)
        DisablePlayerVehicleRewards(PlayerId()) SetPlayerHealthRechargeMultiplier(PlayerId(),0.0)
        if profile and IsEntityDead(ped) then Wait(WorldConfig.respawnMs) TriggerEvent('mx:menu:close') spawn() end
        Wait(500)
    end
end)
CreateThread(function()
    -- Full native population/model budgets; density is maintained below each frame.
    SetVehiclePopulationBudget(3) SetPedPopulationBudget(3)
    SetReduceVehicleModelBudget(false) SetReducePedModelBudget(false)
    while true do
        Wait(0)
        SetCinematicButtonActive(false)
        DisableControlAction(0,80,true) -- INPUT_VEH_CIN_CAM: R / controller B.
        if IsCinematicCamRendering() then SetCinematicModeActive(false) end
        SetVehicleDensityMultiplierThisFrame(WorldConfig.traffic) SetRandomVehicleDensityMultiplierThisFrame(WorldConfig.traffic)
        SetParkedVehicleDensityMultiplierThisFrame(WorldConfig.traffic) SetPedDensityMultiplierThisFrame(WorldConfig.pedestrians)
        SetScenarioPedDensityMultiplierThisFrame(WorldConfig.pedestrians,WorldConfig.pedestrians)
        DisableControlAction(0,37,true) DisablePlayerFiring(PlayerId(),true)
        local environment=WorldEnvironment.effective(lobbyClock)
        if environment.weatherFrom and environment.weatherFrom~=environment.weather and environment.weatherBlend<1 then
            SetWeatherTypeTransition(joaat(environment.weatherFrom),joaat(environment.weather),environment.weatherBlend)
        else SetWeatherTypeNowPersist(environment.weather) end
        NetworkOverrideClockTime(environment.hour,environment.minute,environment.second)
    end
end)
AddEventHandler('onClientResourceStop',function(r) if r==GetCurrentResourceName() then FreezeEntityPosition(PlayerPedId(),false) SetEntityProofs(PlayerPedId(),false,false,false,false,false,false,false,false) local v=GetVehiclePedIsIn(PlayerPedId(),false) if v~=0 then FreezeEntityPosition(v,false) end end end)
AddEventHandler('onClientResourceStop',function(r)
    if r=='mx-freeroam-experience' then lobbyClock=nil end
    if r==GetCurrentResourceName() then SetCinematicButtonActive(true) end
end)
CreateThread(function() Wait(1000) TriggerServerEvent('mx:core:ready') end)
