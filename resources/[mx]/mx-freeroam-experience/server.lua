local sessions={}
local sessionCars={}
exports('PresentationSettings',function() return MX.copy({presentation=ExperienceConfig.presentation,exit=ExperienceConfig.exit}) end)
local function completed(value) return value==true or value==1 end
local function vehicles() return exports['mx-freeroam-vehicles'] end
local function preview(...) return MX.unwrap(vehicles():Preview(...)) end
local function applyPreview(...) return MX.unwrap(vehicles():ApplyPreview(...)) end
local function record(actor)
    MX.db('INSERT IGNORE INTO player_experience(player_id) VALUES (?)',{actor.id})
    return MX.db('SELECT * FROM player_experience WHERE player_id=?',{actor.id})[1]
end
local function appearance(actor)
    local row=MX.db('SELECT document,revision FROM player_appearance WHERE player_id=?',{actor.id})[1]
    if row then
        local ok,value=pcall(function() return ExperienceRules.appearance(json.decode(row.document)) end)
        if not ok then return ExperienceRules.preset(),row.revision,true end
        return value,row.revision
    end
    return ExperienceRules.preset(actor.preferences.appearance=='driver_f' and 'mp_f_freemode_01' or 'mp_m_freemode_01',actor.preferences.outfit),0
end
local function private(src,d)
    local s=sessions[src]
    MX.require(s and s.epoch==MX.actor(src).epoch and d.token==s.token and not s.leaving,'SESSION','Reabra a oficina') return s
end
exports('IsPrivate',function(src) return sessions[src]~=nil end)
local function displayVehicle(s,row)
    s.displayVehicle=row and row.id and s.preview and row.model==s.preview.model and {id=row.id,model=row.model,revision=row.revision,properties=MX.copy(s.preview.properties)} or nil
end
local function state(src,actor)
    local r=record(actor) local rows=vehicles():SavedList(actor.id) local selected
    for _,row in ipairs(rows) do if row.id==r.selected_id and row.available then selected=row end end
    if not selected then
        for _,row in ipairs(rows) do if row.available then selected=row break end end
        if selected then MX.db('UPDATE player_experience SET selected_id=?,revision=revision+1 WHERE player_id=?',{selected.id,actor.id}) r=record(actor)
        elseif r.selected_id then MX.db('UPDATE player_experience SET selected_id=NULL,revision=revision+1 WHERE player_id=?',{actor.id}) r=record(actor) end
    end
    local a,rev,corrupt=appearance(actor)
    local phase=ExperienceRules.phase(r,selected~=nil,#rows>0)
    -- A completed flag without appearance is corruption, not a fresh account.
    if corrupt or (completed(r.character_completed) and rev==0) then phase='characterRecovery' end
    local s=sessions[src]
    if s and s.context=='garage' and ExperienceConfig.display.enabled then
        local parts={}
        for _,row in ipairs(rows)do parts[#parts+1]=tostring(row.id)..':'..tostring(row.revision)..':'..tostring(row.available)end
        table.sort(parts) -- Usage/selection order must not invalidate scenery.
        local stamp=table.concat(parts,'|')
        if stamp~=s.displayStamp then s.displayStamp=stamp TriggerClientEvent('mx:experience:displayChanged',src,s.token)end
    end
    return {phase=phase,revision=r.revision,appearance=a,appearanceRevision=rev,selected=selected,current=s and s.current,currentDirty=s and s.currentDirty or false,garage=rows,token=s and s.token,preview=s and s.preview,characterCompleted=completed(r.character_completed) and phase~='characterRecovery',vehicleCompleted=completed(r.vehicle_completed)}
end
local function journal(actor,d,kind,fn)
    MX.require(ExperienceRules.uuid(d.operation),'OPERATION')
    local request=MX.copy(d) request.token=nil
    local fingerprint=MX.canonical(request)
    local old=MX.db('SELECT kind,result FROM experience_operations WHERE player_id=? AND operation_id=?',{actor.id,d.operation})[1]
    if old then local result=json.decode(old.result) MX.require(old.kind==kind and result.request==fingerprint,'CONFLICT','Identificador reutilizado para outra alteração') return result.data end
    local queries,result=fn()
    queries[#queries+1]={query='INSERT INTO experience_operations(player_id,operation_id,kind,result) VALUES (?,?,?,?)',values={actor.id,d.operation,kind,json.encode({request=fingerprint,data=result})}}
    MX.tx(queries) return result
end
-- Internal only: durable domain operations, also exercised against isolated SQL by verification.
exports('CommitOperation',journal)
local function previewSelected(src,actor)
    local s=sessions[src] local current=state(src,actor)
    vehicles():RegisterPreviewContext(src,s.token,s.epoch,s.bucket)
    local row=s.current or (current.selected and vehicles():Saved(actor.id,current.selected.id))
    if row then s.current=s.current or MX.copy(row) s.preview=preview(src,row.model,row.properties,(s.context=='lobby' and ExperienceConfig.lobbyScene or ExperienceConfig.scene).car)
    else vehicles():RemovePreview(src,true) s.preview=nil vehicles():RegisterPreviewContext(src,s.token,s.epoch,s.bucket) end
    displayVehicle(s,row)
    MX.callClient(src,'experience','previewChanged',{preview=s.preview,displayVehicle=s.displayVehicle,displayCurrent=s.current})
    return state(src,actor)
end
local function clean(src,returnBucket)
    local s=sessions[src] if not s then return end
    vehicles():RemovePreview(src)
    if returnBucket and GetPlayerPed(src)~=0 then SetPlayerRoutingBucket(src,s.publicBucket) end
    sessions[src]=nil
end
local function detachPresentation(src)
    local detached=MX.callClient(src,'experience','fade',{})
    MX.require(detached.ready,'DRIVER','Não foi possível sair do veículo de apresentação')
    local deadline=GetGameTimer()+1500
    while GetVehiclePedIsIn(GetPlayerPed(src),false)~=0 and GetGameTimer()<deadline do Wait(0) end
    MX.require(GetVehiclePedIsIn(GetPlayerPed(src),false)==0,'DRIVER','Aguarde a confirmação de saída do veículo de apresentação')
end
local function waitEntry(src,s,point,detached)
    local deadline=GetGameTimer()+ExperienceConfig.entrySyncTimeout
    repeat
        local actor=MX.actor(src) local ped=GetPlayerPed(src)
        MX.require(actor and actor.epoch==s.epoch,'SESSION','A sessão mudou durante a entrada na garagem')
        -- First join/model replacement can temporarily have no replicated ped.
        -- This is readiness, not a new player session; never query entity 0.
        if ped~=0 and DoesEntityExist(ped) then
            if detached then
                if GetVehiclePedIsIn(ped,false)==0 then return true end
            elseif GetPlayerRoutingBucket(src)==s.bucket and MX.distance(GetEntityCoords(ped),point)<8 then return true end
        end
        Wait(0)
    until GetGameTimer()>=deadline
    return false
end
local function awaitPed(src,epoch)
    local deadline=GetGameTimer()+ExperienceConfig.entrySyncTimeout
    repeat
        local actor=MX.actor(src)
        MX.require(actor and actor.epoch==epoch,'SESSION','A sessão mudou durante a entrada na garagem')
        local ped=GetPlayerPed(src)
        if ped~=0 and DoesEntityExist(ped) then return ped end
        Wait(0)
    until GetGameTimer()>=deadline
    MX.fail('PLAYER_NOT_READY','O personagem ainda não foi sincronizado pelo servidor; tente novamente')
end
local function failedEntry(src,s,err)
    -- Also used by lobby <-> workshop transitions: they already own a private
    -- session, but must release it and restore the UI on every failed stage.
    local actor=MX.actor(src)
    MX.require(actor and actor.epoch==s.epoch,'SESSION','A sessão mudou durante a recuperação')
    local cleaned=pcall(clean,src,true)
    if not cleaned then SetPlayerRoutingBucket(src,s.publicBucket) sessions[src]=nil end
    local restored,response=pcall(MX.callClient,src,'experience','abort',{point=s.returnPoint})
    local failure=MX.error(err)
    local recovery=restored and response and response.recovered~=false
    local held=restored and response and response.held==true
    MX.fail(failure.code,failure.message..(held and '. A entrada inicial permanece protegida; tente novamente no lobby.' or recovery and '. Modo livre restaurado; tente novamente.' or '. A recuperação não foi confirmada. Feche o menu e tente novamente.'))
end
local function enter(src,actor,context)
    context=context or 'garage'
    local preset=context=='lobby' and ExperienceConfig.lobbyScene or ExperienceConfig.scene
    if sessions[src] and sessions[src].context~=context then
        local s=sessions[src]
        local ok,result=pcall(function()
            detachPresentation(src)
            vehicles():RemovePreview(src,true) s.preview=nil s.context=context
            local response=MX.callClient(src,'experience','scene',{token=s.token,appearance=state(src,actor).appearance,point=preset.ped,context=context})
            MX.require(response.ready,'SCENE_STREAM','O cenário não confirmou o carregamento')
            MX.require(waitEntry(src,s,preset.ped,false),'POSITION','A posição da garagem não foi confirmada a tempo')
            return previewSelected(src,actor)
        end)
        if not ok then failedEntry(src,s,result) end
        return result
    end
    if sessions[src] then
        local s=sessions[src]
        local ok,result=pcall(function()
            local preview=exports['mx-freeroam-vehicles']:CurrentPreview(src)
            if preview then s.preview=preview return state(src,actor) end
            return previewSelected(src,actor)
        end)
        if not ok then failedEntry(src,s,result) end
        return result
    end
    local ped=awaitPed(src,actor.epoch)
    exports['mx-freeroam-world']:StopTrainer(src)
    vehicles():CanEnterWorkshop(src)
    local bucket=GetPlayerRoutingBucket(src) local point=GetEntityCoords(ped)
    local s={context=context,token=MX.uuid(),epoch=actor.epoch,publicBucket=bucket,returnPoint={x=point.x,y=point.y,z=point.z,h=GetEntityHeading(GetPlayerPed(src))},bucket=ExperienceConfig.bucketStart+src}
    local current=state(src,actor)
    local running=vehicles():Active(src)
    if running then
        local old=sessionCars[src]
        s.current=running.presetId and vehicles():Saved(actor.id,running.presetId) or old and old.model==running.model and MX.copy(old) or {model=running.model,name=running.model,available=true}
        s.current.properties=MX.copy(running.properties)
        if s.current.id then local saved=vehicles():Saved(actor.id,s.current.id) s.currentDirty=MX.canonical(saved.properties)~=MX.canonical(s.current.properties) end
    end
    -- Load and validate before touching public context.
    if MX.online('mx-freeroam-activities') then exports['mx-freeroam-activities']:Invalidate(src,'workshop') end
    local ok,err=pcall(function()
        local detached=MX.callClient(src,'experience','prepareEntry',{net=running and running.net,id=running and running.id})
        MX.require(detached.ready and waitEntry(src,s,nil,true),'DRIVER','O desembarque não foi confirmado pelo servidor; entrada cancelada')
        SetRoutingBucketEntityLockdownMode(s.bucket,'strict') SetRoutingBucketPopulationEnabled(s.bucket,false)
        sessions[src]=s SetPlayerRoutingBucket(src,s.bucket)
        vehicles():RegisterPreviewContext(src,s.token,s.epoch,s.bucket)
        local response=MX.callClient(src,'experience','scene',{token=s.token,appearance=current.appearance,point=preset.ped,context=context})
        MX.require(response.ready,'COLLISION','Não foi possível preparar a oficina')
        MX.require(waitEntry(src,s,preset.ped,false),'POSITION','A posição da garagem não foi confirmada a tempo')
        local updated=previewSelected(src,actor)
        vehicles():RemoveManaged(src)
        return updated
    end)
    if not ok then
        failedEntry(src,s,err)
    end
    return state(src,actor)
end
MX.routes('experience',{
    lobby=function(src,_,actor)
        local url=GetConvar('mx_discordInvite','')
        if not (url:match('^https://discord%.gg/[%w%-_]+$') or url:match('^https://discord%.com/invite/[%w%-_]+$')) then url=nil end
        enter(src,actor,'lobby') return {discord=url,sceneReady=true}
    end,
    enter=function(src,_,actor) return enter(src,actor) end,
    enterFromArea=function(src,_,actor)
        MX.require(not sessions[src] and GetPlayerRoutingBucket(src)==0 and ExperienceRules.inEntry(GetEntityCoords(GetPlayerPed(src))),'POSITION','Aproxime-se da entrada da oficina no mundo livre')
        return enter(src,actor)
    end,
    state=function(src,_,actor) return state(src,actor) end,
    displayVehicles=function(src,d,actor)
        local s=private(src,d) local cfg=ExperienceConfig.display
        MX.require(s.context=='garage','SESSION')
        if not cfg.enabled then return {vehicles={}}end
        local count=math.min(7,cfg.maxVehicles,#cfg.points)
        if count<1 then return {vehicles={}}end
        return {vehicles=vehicles():SavedDisplayList(actor.id,count,cfg.excludeCurrent and s.displayVehicle and s.displayVehicle.id or nil),current=s.displayVehicle,selected=s.current}
    end,
    character=function(src,d,actor)
        private(src,d) local a=ExperienceRules.appearance(d.appearance)
        local current=state(src,actor)
        MX.callClient(src,'experience','appearance',{appearance=a}) -- native capabilities validation before persistence
        local result=journal(actor,d,'character',function()
            MX.require(d.revision==current.appearanceRevision,'CONFLICT','Aparência mudou; recarregue')
            local queries={
                {query='INSERT INTO player_appearance(player_id,document,revision) VALUES (?,?,1) ON DUPLICATE KEY UPDATE document=VALUES(document),revision=revision+1',values={actor.id,json.encode(a)}},
                {query='UPDATE player_experience SET character_completed=1,revision=revision+1 WHERE player_id=?',values={actor.id}}
            }
            return queries,{revision=current.appearanceRevision+1}
        end)
        MX.callClient(src,'experience','confirmAppearance',{appearance=a})
        return {saved=result,state=state(src,actor)}
    end,
    preview=function(src,d,actor)
        local s=private(src,d) local current=state(src,actor)
        MX.require(current.characterCompleted,'ONBOARDING','Confirme o personagem primeiro')
        MX.require(ExperienceRules.uuid(d.intent),'PREVIEW_INTENT')
        local row
        local ok,result=pcall(function()
            if d.id then row=vehicles():Saved(actor.id,d.id) return preview(src,row.model,row.properties,ExperienceConfig.scene.car,d.intent)
            else return preview(src,d.model,nil,ExperienceConfig.scene.car,d.intent) end
        end)
        if not ok then s.preview=vehicles():CurrentPreview(src) error(result,0) end
        MX.require(sessions[src]==s and not s.leaving,'SESSION') s.preview=result
        displayVehicle(s,row)
        MX.callClient(src,'experience','previewChanged',{preview=s.preview,displayVehicle=s.displayVehicle,displayCurrent=s.current})
        return s.preview
    end,
    select=function(src,d,actor)
        private(src,d) local row=vehicles():Saved(actor.id,d.id) MX.require(row.available,'MODEL')
        local result=journal(actor,d,'select',function()
            local r=record(actor) MX.require(r.revision==d.revision,'CONFLICT')
            return {
                {query='UPDATE player_experience SET selected_id=?,revision=revision+1 WHERE player_id=? AND revision=?',values={d.id,actor.id,d.revision}},
                {query='INSERT INTO garage_usage(preset_id) VALUES (?) ON DUPLICATE KEY UPDATE used_at=CURRENT_TIMESTAMP(3)',values={d.id}}
            },{id=d.id}
        end)
        local s=sessions[src] s.current=MX.copy(row) s.currentDirty=false
        return {saved=result,state=previewSelected(src,actor)}
    end,
    garage=function(src,d,actor)
        local s=private(src,d) local action=d.action
        local accepted
        MX.require(action=='add' or action=='duplicate' or action=='delete' or action=='rename' or action=='save','ACTION')
        MX.require(ExperienceRules.uuid(d.id),'PRESET')
        if action=='save' then
            local row=vehicles():Saved(actor.id,d.id) MX.require(s.preview and s.preview.model==row.model,'VEHICLE')
            applyPreview(src,d.properties)
            accepted=MX.copy(d) accepted.properties=vehicles():CurrentPreview(src).properties
        end
        local result=journal(actor,d,action,function()
            local r=record(actor) MX.require(r.revision==d.stateRevision,'CONFLICT','Garagem mudou; recarregue')
            MX.require(completed(r.character_completed),'ONBOARDING')
            local prepared=vehicles():PrepareSaved(actor.id,action,accepted or d)
            local selected=r.selected_id
            if action=='add' then selected=d.id
            elseif action=='delete' and selected==d.id then selected=nil for _,row in ipairs(vehicles():SavedList(actor.id)) do if row.id~=d.id and row.available then selected=row.id break end end end
            -- COALESCE avoids passing a Lua nil inside a positional SQL argument array.
            prepared.queries[#prepared.queries+1]={query='UPDATE player_experience SET selected_id=NULLIF(?,\'\'),vehicle_completed=IF(?=\'add\',1,vehicle_completed),revision=revision+1 WHERE player_id=? AND revision=?',values={selected or '',action,actor.id,d.stateRevision}}
            if action=='add' then prepared.queries[#prepared.queries+1]={query='INSERT INTO garage_usage(preset_id) VALUES (?)',values={d.id}} end
            return prepared.queries,prepared.result
        end)
        if action=='add' or (action=='save' and s.current and s.current.id==d.id) then s.current=vehicles():Saved(actor.id,d.id) s.currentDirty=false end
        if action=='rename' and s.current and s.current.id==d.id then s.current.revision=result.revision s.current.name=d.name end
        if action=='delete' and s.current and s.current.id==d.id then s.current.id=nil s.current.revision=nil s.currentDirty=false end
        if action=='rename' or action=='duplicate' or action=='save' then
            s.preview=vehicles():CurrentPreview(src)
            if s.displayVehicle and s.displayVehicle.id==d.id then s.displayVehicle.revision=result.revision s.displayVehicle.properties=MX.copy(s.preview.properties)end
            return {saved=result,state=state(src,actor)}
        end
        return {saved=result,state=previewSelected(src,actor)}
    end,
    useCurrent=function(src,d,actor)
        local s=private(src,d) local r=record(actor)
        MX.require(completed(r.character_completed) and completed(r.vehicle_completed),'ONBOARDING')
        MX.require(vehicles():ShowroomModel(d.model),'MODEL','Modelo fora do Showroom ou indisponível')
        local preview=vehicles():CurrentPreview(src)
        MX.require(preview and preview.model==d.model,'VEHICLE')
        local result=journal(actor,d,'useCurrent',function()
            MX.require(ExperienceRules.uuid(d.id),'PRESET')
            local prepared=vehicles():PrepareSaved(actor.id,'add',{id=d.id,model=preview.model,name=d.name or preview.model,properties=preview.properties})
            prepared.queries[#prepared.queries+1]={query='UPDATE player_experience SET selected_id=?,revision=revision+1 WHERE player_id=?',values={d.id,actor.id}}
            return prepared.queries,prepared.result
        end)
        s.current=vehicles():Saved(actor.id,result.id) s.currentDirty=false
        displayVehicle(s,s.current)
        return {saved=result,state=state(src,actor)}
    end,
    confirmCurrent=function(src,d,actor)
        local s=private(src,d) MX.require(s.current,'VEHICLE')
        local preview=vehicles():CurrentPreview(src) MX.require(preview and preview.model==s.current.model,'VEHICLE')
        local current=MX.copy(s.current)
        local result=journal(actor,d,'confirmCurrent',function()
            MX.require(ExperienceRules.uuid(d.id),'PRESET')
            applyPreview(src,d.properties) s.preview=vehicles():CurrentPreview(src)
            local prepared=vehicles():PrepareSaved(actor.id,current.id and 'save' or 'add',{id=current.id or d.id,model=current.model,name=current.name,revision=current.revision,properties=s.preview.properties})
            prepared.queries[#prepared.queries+1]={query='UPDATE player_experience SET selected_id=?,revision=revision+1 WHERE player_id=?',values={current.id or d.id,actor.id}}
            return prepared.queries,prepared.result
        end)
        s.current=vehicles():Saved(actor.id,result.id) s.currentDirty=false
        displayVehicle(s,s.current)
        return {saved=result,state=state(src,actor)}
    end,
    saveCurrent=function(src,d,actor)
        local s=private(src,d) MX.require(s.current,'VEHICLE')
        local row=MX.copy(s.current) local action=row.id and 'save' or 'add'
        -- Stable ID and journal fingerprint make retries safe even after the association changes.
        local result=journal(actor,d,'saveCurrent',function()
            MX.require(ExperienceRules.uuid(d.id),'PRESET')
            if row.id and not s.currentDirty then return {},{id=row.id,revision=row.revision,unchanged=true} end
            local prepared=vehicles():PrepareSaved(actor.id,action,{id=row.id or d.id,model=row.model,name=d.name or row.name,properties=row.properties,revision=row.revision})
            prepared.queries[#prepared.queries+1]={query='UPDATE player_experience SET selected_id=?,revision=revision+1 WHERE player_id=?',values={row.id or d.id,actor.id}}
            return prepared.queries,prepared.result
        end)
        s.current=vehicles():Saved(actor.id,result.id) s.currentDirty=false
        if not row.id or (s.displayVehicle and s.displayVehicle.id==row.id)then displayVehicle(s,s.current)end
        return {saved=result,state=state(src,actor)}
    end,
    discardCurrent=function(src,d,actor)
        local s=private(src,d) MX.require(s.current and s.current.id,'PRESET')
        s.current=vehicles():Saved(actor.id,s.current.id) s.currentDirty=false
        return {state=previewSelected(src,actor)}
    end,
    cosmetic=function(src,d)
        local s=private(src,d) local result=applyPreview(src,d.properties) s.preview=vehicles():CurrentPreview(src) return result
    end,
    resetPreview=function(src,d,actor) private(src,d) return {state=previewSelected(src,actor)} end,
    play=function(src,d,actor)
        local s=private(src,d) local current=state(src,actor)
        MX.require(current.characterCompleted and current.vehicleCompleted and (s.current or current.selected),'ONBOARDING','Escolha e salve um carro')
        local row=s.current or vehicles():Saved(actor.id,current.selected.id) s.leaving=true
        local slot local spawned
        local ok,err=pcall(function()
            detachPresentation(src)
            s.preview=nil vehicles():RemovePreview(src,true)
            SetPlayerRoutingBucket(src,s.publicBucket)
            slot=exports['mx-freeroam-world']:ReservePresentationExit(src,ExperienceConfig.exit)
            local prepared=MX.callClient(src,'experience','prepareExit',{point=slot.point,appearance=current.appearance}) MX.require(prepared.ready,'COLLISION')
            spawned=vehicles():SpawnSavedAt(src,row,slot)
            local active=vehicles():Active(src)
            MX.require(active and active.net==spawned.net and GetPedInVehicleSeat(active.entity,-1)==GetPlayerPed(src),'DRIVER')
            MX.callClient(src,'experience','departureView',{})
            MX.callClient(src,'vehicles','depart',{id=active.id,net=active.net,minimumMs=ExperienceConfig.departureDelay})
            local ready=vehicles():Active(src)
            MX.require(ready and ready.id==active.id and DoesEntityExist(active.entity) and GetPedInVehicleSeat(active.entity,-1)==GetPlayerPed(src),'DRIVER','O veículo de saída foi substituído durante a partida')
            MX.require(GetPlayerRoutingBucket(src)==s.publicBucket and MX.distance(GetEntityCoords(active.entity),slot.point)<12,'POSITION')
            MX.callClient(src,'experience','finish',{})
        end)
        if slot and slot.key then exports['mx-freeroam-world']:Release(slot.key,src) end
        if not ok then
            s.leaving=false pcall(function() vehicles():RemoveManaged(src) end)
            SetPlayerRoutingBucket(src,s.bucket)
            pcall(MX.callClient,src,'experience','scene',{token=s.token,appearance=current.appearance,point=ExperienceConfig.scene.ped})
            pcall(previewSelected,src,actor)
            pcall(MX.callClient,src,'experience','recoverUI',{state=state(src,actor)})
            error(err,0)
        end
        sessionCars[src]=MX.copy(row) clean(src,false) return {playing=true}
    end
})
AddEventHandler('playerDropped',function() clean(source,false) sessionCars[source]=nil end)
-- Cancellation is deliberately outside the mutation lock: it only invalidates
-- an in-flight visual operation and never spawns, saves or authorizes a vehicle.
RegisterNetEvent('mx:experience:previewIntent',function(token,intent)
    local src=source local s=sessions[src] local actor=MX.actor(src)
    if s and actor and s.epoch==actor.epoch and s.token==token and not s.leaving and ExperienceRules.uuid(intent) then vehicles():PreviewIntent(src,token,intent) end
end)
RegisterNetEvent('mx:experience:uiStopped',function() local src=source if not MX.actor(src) then return end if sessions[src] then clean(src,true) end DropPlayer(src,'Interface reiniciada; reconecte para recuperar o lobby e a garagem.') end)
AddEventHandler('onResourceStop',function(r)
    if r==GetCurrentResourceName() then
        for src in pairs(sessions) do clean(src,true) DropPlayer(src,'Oficina reiniciada. Reconecte para recuperar seus dados salvos.') end
    end
end)
