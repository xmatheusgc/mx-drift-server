local navigationGate={}
local navigationText,navigationTabs=false,false
local navigationSettings=false
local navigationCharacter=false
local opened,editing=false,false
local pauseOpen,nativePause=false,false
local nativePauseStarted=0
local preferences={hud=true,minimap=true,units='kmh',scale=1,volume=0.3,photo=false}
local presence,muted={},{}
local keyboardOpen=false
local freeCamera=false
local vehicleEditor=false
local lobbyOpen=false
local workshopOpen=false
local menuModal=false
local cameraDeveloper=false
local domains={core=true,vehicles=true,world=true,social=true,activities=true,progression=true,admin=true,experience=true}
local function workshop() return MX.online('mx-freeroam-experience') and exports['mx-freeroam-experience']:InWorkshop() end
local function focus(value)
    editing=value==true and opened
    SetNuiFocus(editing,editing and (lobbyOpen or workshopOpen or pauseOpen))
    SetNuiFocusKeepInput(editing)
    SendNUIMessage({type='nativeNavigation',enabled=editing and not cameraDeveloper})
end
AddEventHandler('mx:experience:vehicleEditor',function(value) vehicleEditor=value==true focus(true) end)
AddEventHandler('mx:experience:freeCamera',function(value) freeCamera=value==true focus(true) SendNUIMessage({type='workshopCamera',free=freeCamera}) end)
AddEventHandler('mx:experience:cameraDeveloper',function(message)
    cameraDeveloper=message.open==true
    SendNUIMessage({type='nativeNavigation',enabled=editing and not cameraDeveloper})
    if cameraDeveloper then SetNuiFocus(true,true)SetNuiFocusKeepInput(false)else focus(opened)end
    SendNUIMessage({type='cameraDeveloper',open=cameraDeveloper,data=message.data})
end)
AddEventHandler('mx:experience:input',function(message) if opened then SendNUIMessage(message) end end)
AddEventHandler('mx:experience:entryPrompt',function(data)
    SendNUIMessage({type='workshopEntry',visible=data.visible==true})
    if data.visible then SendNUIMessage({type='workshopInputDevice',device=data.device,style=data.style}) end
end)
CreateThread(function()
    local previous=nil
    while true do
        Wait(200)
        if opened then
            local keyboard=IsInputDisabled(0)
            if keyboard~=previous then
                previous=keyboard
                local style=MX.online('mx-freeroam-experience') and exports['mx-freeroam-experience']:ControllerIcons() or 'auto'
                SendNUIMessage({type='workshopInputDevice',device=keyboard and 'keyboard' or 'gamepad',style=style})
            end
        else previous=nil end
    end
end)
local function closePause()
    pauseOpen=false opened=false menuModal=false focus(false)
    SendNUIMessage({type='pauseMenu',open=false})
end
local function close()
    if pauseOpen then closePause() return end
    if lobbyOpen then SendNUIMessage({type='lobbyBack'}) return end
    if freeCamera then exports['mx-freeroam-experience']:LocalAction('freeCamera',{}) return end
    if workshop() then SendNUIMessage({type='workshopBack'}) return end
    opened=false menuModal=false focus(false) SendNUIMessage({type='menu',open=false}) SendNUIMessage({type='workshop',state=false}) TriggerEvent('mx:menu:close')
end
AddEventHandler('mx:menu:close',function() if pauseOpen then closePause() return end menuModal=false if opened then opened=false focus(false) SendNUIMessage({type='menu',open=false}) end end)
local function toggle()
    if pauseOpen or nativePause then return end
    if lobbyOpen then SendNUIMessage({type='lobbyBack'}) return end
    if freeCamera then exports['mx-freeroam-experience']:LocalAction('freeCamera',{}) return end
    if workshop() then SendNUIMessage({type='workshopBack'}) return end
    if opened then close() else opened=true focus(true) SendNUIMessage({type='menu',open=true}) end
end
RegisterCommand('mxmenu',toggle,false)
RegisterCommand('mxtrainer',function() if not MenuBindings and not IsNuiFocused() then toggle() end end,false)
-- Legacy mapped commands remain inert when the per-player binding registry is loaded.
AddEventHandler('mx:trainer:state',function(data) SendNUIMessage({type='trainer',data=data}) end)
AddEventHandler('mx:admin:telemetry',function(data) SendNUIMessage({type='adminCoordinates',data=data}) end)
local shortcutBusy,lastShortcut=false,-1000
local noclipBusy,noclipQueued=false,false
local function shortcut(action)
    if IsNuiFocused() or IsPauseMenuActive() or workshop() or lobbyOpen or IsEntityDead(PlayerPedId()) then return end
    local stoppedLocally=false
    if action=='noclip' and MX.online('mx-freeroam-world') then stoppedLocally=exports['mx-freeroam-world']:StopLocalTrainer() end
    if action=='noclip' then
        if noclipBusy then
            if not stoppedLocally then noclipQueued=not noclipQueued end
            return
        end
        noclipBusy=true
    else
        if shortcutBusy or GetGameTimer()-lastShortcut<200 then return end
        shortcutBusy=true lastShortcut=GetGameTimer()
    end
    CreateThread(function()
        local ok,result=pcall(function()
            local result
            if action=='noclip' then
                result=MX.request('world',stoppedLocally and 'noclip' or 'toggleNoclip',stoppedLocally and {enabled=false} or {})
            elseif action=='repair' or action=='clean' or action=='flip' or action=='engine' or action=='doors' or action=='stop' or action=='lock' or action=='eject' or action=='respawn' or action=='indicatorLeft' or action=='indicatorRight' or action=='hazards' then result=MX.request('vehicles','service',{kind=action})
            elseif action=='drift' then
                result=MX.request('vehicles','options',{})
                if result.ok then result=MX.request('vehicles','service',{kind='drift',vehicleId=result.data.id,enabled=not result.data.drift}) end
            elseif action=='drivecam' then local current=exports['mx-freeroam-drivecam']:Preference() result={ok=true,data=exports['mx-freeroam-drivecam']:Preference(not current.enabled)}
            elseif action=='recover' then result=MX.request('world','recover',{withCar=false})
            elseif action=='garage' then result=exports['mx-freeroam-experience']:OpenGarage()
            else result=MX.request('world',action,{}) end
            return result
        end)
        if action=='noclip' then noclipBusy=false else shortcutBusy=false end
        if action=='noclip' and noclipQueued then
            noclipQueued=false
            CreateThread(function() Wait(0) shortcut('noclip') end)
        end
        if not ok then TriggerEvent('mx:notice',type(result)=='table' and result.message or 'Trainer indisponível; tente novamente') return end
        if result.ok then
            if action=='noclip' or action:find('Checkpoint') then SendNUIMessage({type='trainer',data=result.data}) end
            TriggerEvent('mx:notice',action=='saveCheckpoint' and 'Checkpoint criado' or action=='returnCheckpoint' and 'Retorno ao checkpoint confirmado' or action=='noclip' and (result.data.noclip and 'Noclip ativado' or 'Noclip desativado') or 'Ação confirmada')
        else TriggerEvent('mx:notice',(result.code or 'ERRO')..': '..(result.message or 'Ação não confirmada')) end
    end)
end
for _,item in ipairs({{'mxnoclip','F2','noclip','MX: alternar noclip'},{'mxcheckpoint','F3','saveCheckpoint','MX: criar checkpoint pessoal'},{'mxcheckpointreturn','F4','returnCheckpoint','MX: voltar ao checkpoint'}}) do
    local action=item[3]
    RegisterCommand(item[1],function() if not MenuBindings then shortcut(action) end end,false)

end
RegisterCommand('mxedit',function() if workshop() then focus(not editing) end end,false)
local function callback(name,fn)
    RegisterNUICallback(name,function(data,cb)
        CreateThread(function()
            local ok,result=pcall(fn,data)
            if ok then cb(result or {ok=true}) else local failure=MX.error(result) cb({ok=false,code=failure.code,message=failure.message}) end
        end)
    end)
end
-- Use client exports: soundcore retains authoritative permission checks on its server.
callback('vehicleSound',function(d)
    MX.require(opened and not pauseOpen and not workshop() and not lobbyOpen,'SESSION','Disponível no menu do modo livre')
    MX.require(GetResourceState('mx-soundcore')=='started','UNAVAILABLE','O som do veículo não está iniciado no servidor')
    local vehicle=GetVehiclePedIsIn(PlayerPedId(),false)
    MX.require(vehicle~=0 and DoesEntityExist(vehicle) and NetworkGetEntityIsNetworked(vehicle),'VEHICLE','Entre em um veículo para usar o som')
    local netId=NetworkGetNetworkIdFromEntity(vehicle)
    local state=Entity(vehicle).state
    if d.action and d.action~='state' then
        MX.require(type(d.vehicleId)=='number' and d.vehicleId==netId,'VEHICLE','O veículo mudou. Aguarde o menu atualizar e tente novamente')
        local sound=exports['mx-soundcore']
        local accepted=false
        if d.action=='play' or d.action=='queue' then
            MX.require(type(d.input)=='string' and #d.input<=2048 and d.input:find('%S'),'INPUT','Informe o nome da música ou um link (até 2048 caracteres)')
            if d.action=='play' then accepted=sound:PlaySound(vehicle,d.input)
            else accepted=sound:AddToQueue(vehicle,d.input) end
        elseif d.action=='volume' then
            MX.require(type(d.volume)=='number' and d.volume==d.volume and d.volume>=0 and d.volume<=30 and d.volume%1==0,'INPUT','Volume deve ser um número inteiro de 0 a 30')
            accepted=sound:SetVolume(vehicle,d.volume)
        elseif d.action=='pause' then accepted=sound:PauseSound(vehicle)
        elseif d.action=='resume' then accepted=sound:ResumeSound(vehicle)
        elseif d.action=='skip' then accepted=sound:SkipTrack(vehicle)
        elseif d.action=='stop' then accepted=sound:StopSound(vehicle)
        else MX.require(false,'INPUT','Ação de som desconhecida') end
        MX.require(accepted==true,'UNAVAILABLE','Não foi possível enviar o pedido ao sistema de som')
    end
    -- Legacy IsPaused/GetPlaybackStatus reference a missing helper; read replicated state.
    return {ok=true,data={vehicleId=netId,status=state['mxsound:status'] or 'idle',
        paused=state['mxsound:paused']==true,active=state['mxsound:url']~=nil,
        volume=math.floor((state['mxsound:volume'] or 0.5)*30+0.5),
        meta=state['mxsound:meta'],queue=state['mxsound:queue'] or {},error=state['mxsound:error']}}
end)
RegisterNetEvent('chat:addMessage',function(message)
    if type(message)=='table' and type(message.args)=='table' and message.args[1]=='[mx-soundcore]' then
        TriggerEvent('mx:notice',tostring(message.args[2] or ''))
        if opened then SendNUIMessage({type='soundFeedback',message=tostring(message.args[2] or '')}) end
    end
end)
callback('trainerOptions',function() return {ok=true,data={testPlayer=GetConvarInt('mx_menuTestPlayer',0)==1}} end)
callback('personalEnvironment',function(d)
    MX.require(opened and not workshop() and not lobbyOpen,'SESSION','Disponível no menu do modo livre')
    if d.patch~=nil then return {ok=true,data=exports['mx-freeroam-world']:SetPersonalEnvironment(d.patch)} end
    return {ok=true,data=exports['mx-freeroam-world']:PersonalEnvironment()}
end)
callback('noclipToggle',function()
    MX.require(opened and not workshop() and not lobbyOpen,'SESSION','Disponível no menu do modo livre')
    local stopped=exports['mx-freeroam-world']:StopLocalTrainer()
    return MX.request('world',stopped and 'noclip' or 'toggleNoclip',stopped and {enabled=false} or {})
end)
callback('bindings',function() return {ok=true,data=MenuBindings.list()} end)
callback('setBinding',function(d) return {ok=true,data=MenuBindings.update(d.action,d.kind,d.value)} end)
local captureActive,captureCancelled=false,false
callback('cancelBindingCapture',function() captureCancelled=true return {ok=true} end)
callback('captureBinding',function(d)
    MX.require(opened and not keyboardOpen and (d.kind=='key' or d.kind=='pad'),'BIND','Captura indisponível')
    captureActive=true captureCancelled=false keyboardOpen=true
    TriggerEvent('mx:experience:keyboard',true)
    local result
    local ok,failure=pcall(function()
        local state=BindingCapture.new(d.kind,GetGameTimer())
        while opened and not captureCancelled do
            DisableAllControlActions(0) DisableAllControlActions(2)
            local keys,pads=BindingCapture.sample()
            result=BindingCapture.read(state,GetGameTimer(),keys,pads)
            if result then break end
            Wait(0)
        end
        -- Consume the captured button's release so it cannot select/back/apply.
        local deadline=GetGameTimer()+1500
        repeat
            DisableAllControlActions(0) DisableAllControlActions(2)
            local keys,pads=BindingCapture.sample()
            if not next(keys) and not next(pads) then break end
            Wait(0)
        until GetGameTimer()>=deadline
    end)
    captureActive=false keyboardOpen=false navigationGate={}
    TriggerEvent('mx:experience:keyboard',false) focus(opened)
    if not ok then error(failure,0) end
    return {ok=true,data=result or {cancelled=true}}
end)
CreateThread(function()
    local held,started,fired={},{},{}
    while true do
        Wait(0)
        if VehicleInput then VehicleInput.block() end
        if MenuBindings and not IsNuiFocused() and not pauseOpen and not nativePause and not IsPauseMenuActive() and not keyboardOpen and not cameraDeveloper and not workshop() and not lobbyOpen then
            for _,binding in ipairs(MenuBindings.list()) do
                if binding.id~='cycleSpeed' and binding.id~='up' and binding.id~='down' and binding.id~='cameraMode' then
                    local down=MenuBindings.input(binding.id,true)
                    if binding.id=='menu' and binding.pad=='VIEW' and down and not IsInputDisabled(0) then
                        DisableControlAction(0,0,true) -- View/touchpad also changes the native camera.
                        DisableControlAction(0,244,true)
                    end
                    local edge=down and not held[binding.id] held[binding.id]=down
                    if binding.id=='engine' and MenuBindings.keyInput then
                        local key=MenuBindings.keyInput('engine',true)
                        local pad=MenuBindings.padInput('engine',true)
                        if pad then
                            started.engine=started.engine or GetGameTimer()
                            if not fired.engine and GetGameTimer()-started.engine>=700 then fired.engine=true shortcut('engine') end
                        else started.engine=nil fired.engine=nil end
                        if key and not held.engineKey then shortcut('engine') end
                        held.engineKey=key
                    elseif edge then if binding.id=='menu' then toggle() else shortcut(binding.id) end end
                end
            end
        else
            -- A held button used to navigate/close a menu cannot fire in gameplay.
            if MenuBindings then for _,binding in ipairs(MenuBindings.list()) do held[binding.id]=MenuBindings.input(binding.id,true) end end
            held.engineKey=MenuBindings and MenuBindings.keyInput and MenuBindings.keyInput('engine',true) or false
            started={} fired={engine=true}
        end
    end
end)
callback('request',function(d)
    MX.require(opened and type(d)=='table' and domains[d.domain] and MX.text(d.action,1,48) and type(d.data)=='table','ACTION')
    return MX.request(d.domain,d.action,d.data)
end)
callback('experienceLocal',function(d)
    MX.require(type(d)=='table' and type(d.action)=='string','PAYLOAD')
    if d.action=='drivecam' then return {ok=true,data=exports['mx-freeroam-drivecam']:Preference(d.value)} end
    return {ok=true,data=exports['mx-freeroam-experience']:LocalAction(d.action,d)}
end)
callback('cameraDeveloper',function(d)
    MX.require(cameraDeveloper and opened and (lobbyOpen or workshop()),'SESSION','Editor disponível no lobby ou garagem')
    return {ok=true,data=exports['mx-freeroam-experience']:DeveloperCamera(d)}
end)
callback('previewIntent',function(d)
    MX.require(workshop() and type(d.token)=='string' and MX.text(d.intent,36,36),'SESSION')
    exports['mx-freeroam-vehicles']:SetPreviewIntent(d.intent)
    TriggerServerEvent('mx:experience:previewIntent',d.token,d.intent) return {ok=true}
end)
callback('keyboard',function(d)
    MX.require(opened and MX.text(d.initial or '',0,250) and MX.number(d.maxLength or 48,1,250,true),'PAYLOAD')
    keyboardOpen=true SetNuiFocus(false,false)
    TriggerEvent('mx:experience:keyboard',true)
    if MX.online('mx-freeroam-experience') then exports['mx-freeroam-experience']:SuspendDrivecam('keyboard',true) end
    DisplayOnscreenKeyboard(1,'FMMC_KEY_TIP8','',d.initial or '','','','',d.maxLength or 48)
    while UpdateOnscreenKeyboard()==0 do Wait(0) end
    local result=GetOnscreenKeyboardResult()
    keyboardOpen=false
    TriggerEvent('mx:experience:keyboard',false)
    if MX.online('mx-freeroam-experience') then exports['mx-freeroam-experience']:SuspendDrivecam('keyboard',false) end
    if opened then focus(true) end
    return {ok=true,data={value=result,cancelled=result==nil}}
end)
callback('toggleDrivecam',function()
    local current=exports['mx-freeroam-drivecam']:Preference()
    return {ok=true,data=exports['mx-freeroam-drivecam']:Preference(not current.enabled)}
end)
local loadingActive=false
AddEventHandler('mx:loading',function(data)
    loadingActive=data.active==true
    if loadingActive and pauseOpen then closePause() end
    SendNUIMessage({type='loadingStatus',active=loadingActive,message=data.message})
end)
AddEventHandler('mx:loadingProgress',function(data)
    if loadingActive then SendNUIMessage({type='loadingStatus',active=true,message=data.message}) end
end)
AddEventHandler('mx:experience:state',function(state)
    pauseOpen=false nativePause=false SendNUIMessage({type='pauseMenu',open=false})
    lobbyOpen=false workshopOpen=true
    opened=true focus(true) SendNUIMessage({type='menu',open=false}) SendNUIMessage({type='session',data=nil}) SendNUIMessage({type='workshop',state=state})
end)
AddEventHandler('mx:experience:lobby',function(data)
    if type(data)~='table' or not exports['mx-freeroam-experience']:IsLobbyGeneration(data.generation) then return end
    pauseOpen=false nativePause=false SendNUIMessage({type='pauseMenu',open=false})
    lobbyOpen=true workshopOpen=false opened=true focus(true) SendNUIMessage({type='menu',open=false}) SendNUIMessage({type='lobby',data=data})
end)
callback('navigationContext',function(d)
    navigationGate={} menuModal=d.modal==true navigationText=d.text==true navigationTabs=d.tabs==true
    navigationSettings=d.settings==true navigationCharacter=d.character==true
    SendNUIMessage({type='nativeNavigation',enabled=editing and not cameraDeveloper})
    TriggerEvent('mx:experience:modal',menuModal) return {}
end)
callback('lobbyReady',function(d)
    if not lobbyOpen or type(d)~='table' then return {ok=true,data={accepted=false}} end
    local data=exports['mx-freeroam-experience']:LobbyReady(d.generation)
    -- SendNUIMessage targets this resource only: the menu owns the UI veil.
    if data.accepted and lobbyOpen then
        if data.loadingClosed then SendNUIMessage({type='loadingClosed'}) end
        focus(true)
    end
    return {ok=true,data=data}
end)
callback('openGarage',function() MX.require(lobbyOpen,'LOBBY') return exports['mx-freeroam-experience']:OpenGarage() end)
AddEventHandler('mx:experience:error',function(message)
    pauseOpen=false nativePause=false SendNUIMessage({type='pauseMenu',open=false})
    workshopOpen=true opened=true focus(true) SendNUIMessage({type='menu',open=false}) SendNUIMessage({type='workshopError',message=message})
end)
AddEventHandler('mx:experience:closed',function()
    pauseOpen=false nativePause=false SendNUIMessage({type='pauseMenu',open=false})
    lobbyOpen=false workshopOpen=false opened=false focus(false) SendNUIMessage({type='workshop',state=false}) SendNUIMessage({type='lobby',data=false})
end)
callback('close',function() close() return {ok=true} end)
callback('openWorkshop',function()
    MX.require(opened and not lobbyOpen and not workshop(),'SESSION','Use a navegação da garagem neste contexto')
    local ok,result=pcall(function() return exports['mx-freeroam-experience']:OpenGarage() end)
    if not ok then local failure=MX.error(result) result={ok=false,code=failure.code,message=failure.message} end
    if type(result)~='table' or type(result.ok)~='boolean' then result={ok=false,code='UNAVAILABLE',message='A garagem não retornou uma confirmação válida'} end
    if not result.ok then
        pcall(function() exports['mx-freeroam-experience']:RecoverEntry() end)
        lobbyOpen=false workshopOpen=false vehicleEditor=false freeCamera=false opened=true focus(true)
        SendNUIMessage({type='menu',open=true})
        SendNUIMessage({type='menuError',code=result.code,message=result.message})
    end
    return result
end)
callback('focus',function(d) focus(d.editing) return {ok=true} end)
callback('route',function(d)
    local p=presence[d.source] MX.require(p and p.position,'POSITION','Localização não compartilhada ou expirada')
    SetNewWaypoint(p.position.x,p.position.y) return {ok=true}
end)
callback('mute',function(d)
    MX.require(MX.number(d.source,1,65535,true),'PLAYER') muted[d.source]=not muted[d.source]
    MumbleSetVolumeOverrideByServerId(d.source,muted[d.source] and 0.0 or -1.0) TriggerEvent('mx:chat:mute',d.source,muted[d.source]) return {ok=true}
end)
RegisterNUICallback('escape',function(_,cb) close() cb({ok=true}) end)
AddEventHandler('mx:profile:local',function(p)
    preferences=p.preferences
    SendNUIMessage({type='uiPreferences',data=p.preferences})
end)
RegisterNetEvent('mx:social:presence',function(rows)
    if source~=65535 then return end presence={} for _,p in ipairs(rows) do presence[p.source]=p end
end)
RegisterNetEvent('mx:activities:state',function(data) if source==65535 then SendNUIMessage({type='session',data=data}) end end)
AddEventHandler('mx:notice',function(message) SendNUIMessage({type='notice',message=message}) end)
RegisterNetEvent('mx:notify',function(message) if source==65535 then TriggerEvent('mx:notice',message) end end)
CreateThread(function()
    local lastInputKeyboard=nil
    while true do
        if pauseOpen then Wait(0) -- The pause loop owns navigation and gameplay input.
        elseif keyboardOpen then Wait(50)
        elseif opened and cameraDeveloper then Wait(50)
        elseif opened and (lobbyOpen or workshop()) then
            Wait(0)
            -- Experience disables gameplay every frame; read disabled controls only.
            do
                local keyboard=IsInputDisabled(0)
                local key=InterfaceNavigation.read(navigationGate,{text=navigationText,tabs=navigationTabs,settings=navigationSettings,character=navigationCharacter,editor=vehicleEditor,freeCamera=freeCamera})
                if lastInputKeyboard~=keyboard then lastInputKeyboard=keyboard SendNUIMessage({type='workshopInputDevice',device=keyboard and 'keyboard' or 'gamepad',style=exports['mx-freeroam-experience']:ControllerIcons()}) end
                if key then
                    SendNUIMessage({type='workshopInputDevice',device=keyboard and 'keyboard' or 'gamepad',style=exports['mx-freeroam-experience']:ControllerIcons()})
                    if key=='tabPrev' or key=='tabNext' then SendNUIMessage({type='tabNav',direction=key=='tabNext' and 1 or -1})
                    else SendNUIMessage({type='nav',key=key}) end
                end
            end
        elseif opened and not lobbyOpen and not keyboardOpen and not freeCamera and not vehicleEditor then
            Wait(0)
            if menuModal then DisableAllControlActions(0) end -- Text entry only; not the normal trainer menu.
            -- Keep steering, throttle and brake available. Only menu/cursor conflicts are consumed.
            for _,control in ipairs({22,23,24,25,75}) do DisableControlAction(0,control,true) end
            for _,control in ipairs({172,173,174,175,176,177,188,187,200,201,202,27}) do DisableControlAction(0,control,true) end
            local key=InterfaceNavigation.read(navigationGate,{text=navigationText,tabs=navigationTabs})
            if key then SendNUIMessage({type='nav',key=key})end
            if IsEntityDead(PlayerPedId()) and not workshop() then close() end
        else Wait(opened and 50 or 150) end
    end
end)
CreateThread(function()
    while true do
        local v=GetVehiclePedIsIn(PlayerPedId(),false)
        if v~=0 and preferences.hud and not preferences.photo and not workshop() and not lobbyOpen and not pauseOpen and not nativePause and not IsPauseMenuActive() then
            SendNUIMessage({type='hud',data=MenuVehicleHud.sample(v,preferences)})
        else SendNUIMessage({type='hud',data={enabled=false}}) end
        DisplayRadar(preferences.minimap~=false and not workshop() and not lobbyOpen and not preferences.photo and not pauseOpen)
        Wait(100)
    end
end)
AddEventHandler('onClientResourceStop',function(name)
    if name==GetCurrentResourceName() then
        opened=false editing=false SetNuiFocus(false,false) SetNuiFocusKeepInput(false)
        -- PC native FORCE_CLOSE_TEXT_INPUT_BOX; CancelOnscreenKeyboard leaves
        -- UpdateOnscreenKeyboard pending on FiveM/PC (CitizenFX native notes).
        if keyboardOpen and not captureActive then Citizen.InvokeNative(0x8817605C2BA76200) keyboardOpen=false end
        if MX.online('mx-freeroam-experience') then exports['mx-freeroam-experience']:SuspendDrivecam('keyboard',false) end
        SendNUIMessage({type='menu',open=false}) DisplayRadar(true)
        SendNUIMessage({type='pauseMenu',open=false})
        for src in pairs(muted) do MumbleSetVolumeOverrideByServerId(src,-1.0) end
    end
end)
CreateThread(function() Wait(1000) TriggerServerEvent('mx:core:ready') end)
-- Native fades cover GTA, not NUI. Mirror their whole lifecycle without
-- replacing screens or unmounting editors while a scene is being prepared.
CreateThread(function()
    local previous
    local function yes(value)return value==true or value==1 end
    while true do
        local hidden=yes(IsScreenFadingOut()) or yes(IsScreenFadedOut()) or yes(IsScreenFadingIn())
        if hidden~=previous then previous=hidden SendNUIMessage({type='screenFade',active=hidden})end
        Wait((opened or hidden) and 0 or 100)
    end
end)

-- ESC / native pause action: a separate, mouse-enabled session menu.
local pauseCooldown=0
local function openPause()
    if nativePause or IsPauseMenuActive() or (IsNuiFocused() and not opened) or loadingActive or lobbyOpen or workshop() or keyboardOpen or cameraDeveloper or IsEntityDead(PlayerPedId()) then return false end
    pauseOpen=true opened=true menuModal=false navigationGate={}
    DisableAllControlActions(0)
    SendNUIMessage({type='menu',open=false})
    SendNUIMessage({type='pauseMenu',open=true})
    focus(true)
    return true
end
callback('pauseAction',function(d)
    MX.require(pauseOpen and not lobbyOpen and not workshop(),'SESSION','Menu de pausa indisponível')
    if d.kind=='close' then closePause() pauseCooldown=GetGameTimer()+250 return {ok=true} end
    if d.kind=='native' then
        closePause() nativePause=true nativePauseStarted=GetGameTimer()
        ActivateFrontendMenu(joaat('FE_MENU_VERSION_MP_PAUSE'),false,-1)
        return {ok=true}
    end
    MX.require((d.kind=='garage' or d.kind=='disconnect') and d.confirmed==true,'CONFIRM','Confirme a ação antes de continuar')
    if d.kind=='disconnect' then return MX.request('core','disconnect',{}) end
    closePause()
    local ok,result=pcall(function()return exports['mx-freeroam-experience']:OpenGarage()end)
    if not ok then local e=MX.error(result) result={ok=false,code=e.code,message=e.message} end
    if type(result)~='table' or type(result.ok)~='boolean' then result={ok=false,code='UNAVAILABLE',message='A garagem não confirmou a entrada'} end
    if not result.ok then
        pcall(function()exports['mx-freeroam-experience']:RecoverEntry()end)
        openPause()
        SendNUIMessage({type='pauseError',message=result.message or 'Não foi possível abrir a garagem.'})
    end
    return result
end)
CreateThread(function()
    while true do
        Wait(0)
        if nativePause then
            if not IsPauseMenuActive() and GetGameTimer()-nativePauseStarted>=500 then nativePause=false pauseCooldown=GetGameTimer()+300 end
        elseif pauseOpen and not keyboardOpen then
            DisableAllControlActions(0)
            do
                local key=InterfaceNavigation.read(navigationGate,{text=navigationText,tabs=navigationTabs,settings=navigationSettings,character=navigationCharacter,pauseBack=true})
                if key then
                    SendNUIMessage({type='workshopInputDevice',device=IsInputDisabled(0) and 'keyboard' or 'gamepad',style=exports['mx-freeroam-experience']:ControllerIcons()})
                    if key=='tabPrev' or key=='tabNext' then SendNUIMessage({type='tabNav',direction=key=='tabNext' and 1 or -1})else SendNUIMessage({type='nav',key=key})end
                end
            end
        elseif not loadingActive and not lobbyOpen and not workshop() and not IsNuiFocused() and not keyboardOpen and not cameraDeveloper and not IsPauseMenuActive() then
            -- Native pause actions respect the game's device mapping.
            DisableControlAction(0,199,true) -- INPUT_FRONTEND_PAUSE: P / Start.
            DisableControlAction(0,200,true) -- INPUT_FRONTEND_PAUSE_ALTERNATE: ESC.
            if GetGameTimer()>=pauseCooldown and (IsDisabledControlJustPressed(0,199) or IsDisabledControlJustPressed(0,200)) then
                navigationGate={} openPause()
            end
        end
    end
end)
