-- A nearby vanilla floor is not proof that the custom workshop has streamed.
WorkshopStreaming={session=nil}
local S=WorkshopStreaming
local function finish(s,unpin)
    if S.session~=s then return end
    if s.loading then NewLoadSceneStop() s.loading=false end
    if s.focus then ClearFocus() s.focus=false end
    for _,hash in ipairs(s.models) do SetModelAsNoLongerNeeded(hash) end
    s.models={}
    if unpin then
        if s.interior then UnpinInterior(s.interior) end
        S.session=nil
    end
end
function S.stop() if S.session then finish(S.session,true) end end
function S.prepare(point,context,valid)
    S.stop()
    local cfg=ExperienceConfig.streaming
    local map=context=='garage' and cfg.workshop or nil
    if map then MX.require(GetResourceState(map.resource)=='started','SCENE_ASSET','O mapa da oficina está indisponível') end
    local s={models={}} S.session=s
    local ok,err=pcall(function()
        local ped=PlayerPedId()
        FreezeEntityPosition(ped,true)
        SetEntityCoordsNoOffset(ped,point.x,point.y,point.z,false,false,false)
        SetEntityHeading(ped,point.h or 0)
        SetFocusPosAndVel(point.x,point.y,point.z,0.0,0.0,0.0) s.focus=true
        s.loading=NewLoadSceneStartSphere(point.x,point.y,point.z,cfg.radius,0)
        if not s.loading and context=='lobby' then return false end
        MX.require(s.loading,'SCENE_STREAM','Não foi possível iniciar o carregamento da cena; tente novamente')
        local requested={}
        local started=GetGameTimer()
        local deadline=started+(context=='lobby' and cfg.lobbyTimeout or cfg.timeout) local stableAt local nextReport=0
        repeat
            MX.require(S.session==s and valid(),'OBSOLETE','A cena foi substituída')
            RequestCollisionAtCoord(point.x,point.y,point.z)
            local modelsReady=true local missingModel
            -- A started map resource may not have registered its archetypes on
            -- this client yet. Registration shares the scene deadline; never
            -- RequestModel an unknown hash or ACK an incomplete workshop.
            if map then
                MX.require(GetResourceState(map.resource)=='started','SCENE_ASSET','O mapa da oficina está indisponível')
                for _,model in ipairs(map.models) do
                    local hash=joaat(model)
                    if not requested[hash] then
                        if IsModelInCdimage(hash) then
                            requested[hash]=true s.models[#s.models+1]=hash RequestModel(hash)
                        else modelsReady=false missingModel=missingModel or model end
                    end
                end
            end
            for _,hash in ipairs(s.models) do if not HasModelLoaded(hash) then modelsReady=false end end
            if map and not s.interior then
                local interior=GetInteriorAtCoords(point.x,point.y,point.z)
                if interior~=0 then s.interior=interior PinInteriorInMemory(interior) end
            end
            local interiorReady=not map or (s.interior and IsInteriorReady(s.interior))
            local sceneReady=IsNewLoadSceneLoaded()
            local collisionReady=HasCollisionLoadedAroundEntity(ped)
            local ready=sceneReady and collisionReady and modelsReady and interiorReady
            local pending={}
            if not modelsReady then pending[#pending+1]=missingModel and 'registro dos arquivos do mapa' or 'modelos do mapa' end
            if not interiorReady then pending[#pending+1]='interior da oficina' end
            if not sceneReady then pending[#pending+1]='cenário ao redor' end
            if not collisionReady then pending[#pending+1]='colisão do piso' end
            if GetGameTimer()>=nextReport then
                nextReport=GetGameTimer()+1000
                TriggerEvent('mx:loadingProgress',{message=#pending>0 and 'Carregando '..table.concat(pending,', ') or 'Conferindo o cenário',elapsed=GetGameTimer()-started})
            end
            if ready then stableAt=stableAt or GetGameTimer() else stableAt=nil end
            if stableAt and GetGameTimer()-stableAt>=cfg.stableMs then return true end
            if GetGameTimer()>=deadline then
                print(json.encode({level='warn',domain='experience',action='streaming',context=context,elapsed=GetGameTimer()-started,scene=sceneReady,collision=collisionReady,models=modelsReady,interior=interiorReady==true,missingModel=missingModel}))
                -- Optional lobby scenery must never gate access to the garage.
                if context=='lobby' then return false end
                MX.require(not missingModel,'SCENE_ASSET','Os arquivos do mapa da oficina ainda não ficaram disponíveis. A sessão será recuperada para tentar novamente')
                MX.fail('SCENE_STREAM','O tempo de preparação terminou. Ainda aguardando: '..table.concat(pending,', ')..'. A sessão será recuperada para tentar novamente')
            end
            Wait(50)
        until false
    end)
    finish(s,not ok or err==false)
    if not ok then error(err,0) end
    return err
end
AddEventHandler('onClientResourceStop',function(resource) if resource==GetCurrentResourceName() then S.stop() end end)
