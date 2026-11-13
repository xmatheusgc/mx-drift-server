local active,edits,cooldown,retired,fleet={}, {}, {}, {}, {}
local function selected(src)
    local cars=fleet[src] or {}
    local driven=GetVehiclePedIsIn(GetPlayerPed(src),false)
    for i=#cars,1,-1 do
        local car=cars[i]
        if not DoesEntityExist(car.entity) then table.remove(cars,i)
        elseif driven==car.entity and GetPedInVehicleSeat(car.entity,-1)==GetPlayerPed(src) then active[src]=car end
    end
    if not active[src] or not DoesEntityExist(active[src].entity) then active[src]=cars[#cars] end
    return active[src]
end
local function invalidate(src,why) if MX.online('mx-freeroam-activities') then exports['mx-freeroam-activities']:Invalidate(src,why) end end
local function passengers(entity,src)
    for _,s in ipairs(GetPlayers()) do if tonumber(s)~=src and GetVehiclePedIsIn(GetPlayerPed(s),false)==entity then return true end end return false
end
local function owned(src,empty)
    local v=selected(src)
    MX.require(v and DoesEntityExist(v.entity),'VEHICLE','Sem carro ativo')
    MX.require(GetPedInVehicleSeat(v.entity,-1)==GetPlayerPed(src),'DRIVER','Você precisa dirigir seu carro ativo')
    if empty then MX.require(not passengers(v.entity,src),'PASSENGER','Peça aos passageiros para desembarcarem') end
    return v
end
exports('OwnedDriver',owned)
exports('IsEditing',function(src) return edits[src]~=nil end)
exports('Active',function(src) local v=selected(src) return v and {id=v.id,presetId=v.presetId,entity=v.entity,net=v.net,model=v.model,signature=VehicleProperties.signature(v.properties),properties=MX.copy(v.properties),drift=v.drift==true,driftRequested=v.driftRequested==true,handlingUncertain=v.handlingUncertain==true,handlingWarning=v.handlingWarning} end)
local function retire(v,src)
    if not v or not DoesEntityExist(v.entity) then return end
    if passengers(v.entity,src) then
        retired[v.id]=v
    else DeleteEntity(v.entity) end
end
local function available(item) return item and not item.conflict and (not item.asset or MX.online(item.asset)) end
local function spawn(src,item,properties,actor,preparedSlot,saved)
    MX.require(preparedSlot or not MX.online('mx-freeroam-experience') or not exports['mx-freeroam-experience']:IsPrivate(src),'SESSION','Use Jogar na oficina')
    MX.require(available(item),'MODEL','Modelo/asset indisponível')
    MX.require(GetGameTimer()-(cooldown[src] or -10000)>VehicleConfig.cooldown,'COOLDOWN','Aguarde para trocar de carro')
    MX.require(not edits[src],'EDIT','Finalize ou cancele a personalização')
    local current=selected(src) local cars=fleet[src] or {}
    local old=#cars>=VehicleConfig.maxActivePerPlayer and cars[1] or nil
    MX.require(not old or not passengers(old.entity,src),'PASSENGER','Há passageiros no carro anterior')
    MX.require(GetVehiclePedIsIn(GetPlayerPed(src),false)==0 or (current and GetVehiclePedIsIn(GetPlayerPed(src),false)==current.entity and GetPedInVehicleSeat(current.entity,-1)==GetPlayerPed(src)),'DRIVER','Desembarque do carro alheio')
    invalidate(src,'vehicle_changed')
    local slot=preparedSlot or exports['mx-freeroam-world']:ReserveNearest(src)
    local v
    local ok,result=pcall(function()
        local loaded=MX.callClient(src,'vehicles','load',{model=item.model}) MX.require(loaded.loaded,'ASSET','Modelo indisponível no cliente')
        local p=slot.point
        local entity=CreateVehicleServerSetter(joaat(item.model),'automobile',p.x,p.y,p.z,p.h)
        MX.require(entity~=0,'SPAWN','Falha ao criar carro')
        v={id=MX.uuid(),entity=entity,model=item.model,properties=properties,net=NetworkGetNetworkIdFromEntity(entity)}
        v.presetId=saved and saved.id
        if saved then v.drift=saved.drift_enabled==true or saved.drift_enabled==1
        else v.drift=preparedSlot and preparedSlot.drift==true or false end
        SetEntityRoutingBucket(entity,GetPlayerRoutingBucket(src)) SetEntityOrphanMode(entity,2)
        Entity(entity).state:set('mxVehicle',v.id,true)
        if slot.ghost then VehicleDepartureGhost.start(v) end
        -- The owner verifies application before observers receive an enabled preset.
        Entity(entity).state:set('mxDrift',{id=v.id,preset=VehicleDriftPreset.id,enabled=false,pending=true},true)
        local applied=MX.callClient(src,'vehicles','apply',{net=v.net,id=v.id,properties=properties,seat=true,departure=preparedSlot~=nil and preparedSlot.departure~=false,drift=v.drift})
        MX.require(applied.applied==true,'APPLY','Personalização não confirmada')
        VehicleServices.driftState(v,v.drift,applied.drift or (not v.drift and {enabled=false,recovered=true} or nil))
        v.properties=VehicleProperties.acceptStance(properties,applied) v.properties.extras=applied.extras or v.properties.extras VehicleProperties.validate(v.properties)
        VehicleProperties.publish(v.entity,v.id,v.properties)
        Wait(300)
        MX.require(MX.actor(src) and MX.actor(src).epoch==actor.epoch and DoesEntityExist(entity),'SESSION')
        MX.require(not old or not passengers(old.entity,src),'PASSENGER')
        if old then table.remove(cars,1) end
        cars[#cars+1]=v fleet[src]=cars active[src]=v cooldown[src]=GetGameTimer() retire(old,src)
        if slot.ghost then VehicleDepartureGhost.arm(v) end
        return {id=v.id,model=v.model,net=v.net,warning=v.handlingWarning or applied.warning}
    end)
    if slot.key then exports['mx-freeroam-world']:Release(slot.key,src) end
    if not ok then if v then retire(v,src) end error(result,0) end return result
end
exports('SpawnSavedAt',function(src,row,slot)
    local actor=MX.actor(src)
    -- Fetch the independent handling flag freshly: a workshop session may hold
    -- older cosmetic data, but must not overwrite a durable trainer toggle.
    local saved=row.id and exports[GetCurrentResourceName()]:Saved(actor.id,row.id) or nil
    MX.require(not saved or saved.model==row.model,'PRESET','A criação salva pertence a outro modelo')
    return spawn(src,VehicleConfig.catalog[row.model],VehicleProperties.validate(row.properties),actor,slot,saved)
end)
exports('CanEnterWorkshop',function(src)
    local driven=GetVehiclePedIsIn(GetPlayerPed(src),false)
    if driven~=0 then local v=owned(src,true) MX.require(v.entity==driven,'DRIVER','Dirija seu carro e desembarque os passageiros') end
    MX.require(not edits[src],'DRAFT','Finalize a edição atual') return true
end)
exports('RemoveManaged',function(src)
    for _,v in ipairs(fleet[src] or {}) do MX.require(not passengers(v.entity,src),'PASSENGER') end
    for _,v in ipairs(fleet[src] or {}) do retire(v,src) end fleet[src]={} active[src]=nil
end)
local function preset(actor,id)
    MX.require(MX.text(id,36,36),'PRESET')
    local row=MX.db('SELECT * FROM garage_presets WHERE id=? AND player_id=?',{id,actor.id})[1]
    MX.require(row,'NOT_FOUND','Configuração não encontrada') return row
end
local function cancel(src)
    local edit=edits[src] if not edit then return {} end
    edits[src]=nil
    for _,v in ipairs(fleet[src] or {}) do if v.id==edit.vehicle then pcall(MX.callClient,src,'vehicles','apply',{net=v.net,id=v.id,properties=edit.snapshot,editing=false}) break end end
    return {}
end
local function legacyEditor() MX.require(not MX.online('mx-freeroam-experience'),'WORKSHOP','Use a oficina para catálogo, garagem e personalização') end
local function respawn(src,v,actor,replacement)
    MX.require(GetGameTimer()-(cooldown[src] or -10000)>VehicleConfig.cooldown,'COOLDOWN','Aguarde alguns segundos antes de recriar o carro')
    local target=replacement or {model=v.model,properties=MX.copy(v.properties),id=v.presetId,drift_enabled=v.driftRequested==true or v.drift==true}
    MX.require(available(VehicleConfig.catalog[target.model]),'MODEL','O asset deste carro está indisponível; o veículo atual foi mantido')
    local point,heading
    local properties=MX.copy(target.properties) local drift=target.drift_enabled==true or target.drift_enabled==1
    local transfer=MX.uuid()
    local loaded=MX.callClient(src,'vehicles','load',{model=target.model}) MX.require(loaded.loaded,'ASSET','O modelo não carregou; seu carro foi mantido')
    MX.require(selected(src)==v and DoesEntityExist(v.entity) and MX.actor(src) and MX.actor(src).epoch==actor.epoch,'OBSOLETE')
    MX.require(available(VehicleConfig.catalog[target.model]),'MODEL','O asset foi interrompido; recriação cancelada')
    MX.require(GetPlayerRoutingBucket(src)==0 and GetEntityRoutingBucket(v.entity)==0 and MX.distance(GetEntityCoords(GetPlayerPed(src)),GetEntityCoords(v.entity))<=60,'VEHICLE_CONTEXT','O carro precisa continuar próximo no modo livre')
    MX.require(GetEntitySpeed(v.entity)<=.5 or GetPedInVehicleSeat(v.entity,-1)==GetPlayerPed(src),'DRIVER','Entre no banco do motorista para substituir um carro em movimento')
    MX.require(not passengers(v.entity,src),'PASSENGER','Desembarque os passageiros antes de recriar o carro')
    local ok,err=pcall(function()
        local prepared=MX.callClient(src,'vehicles','prepareRespawn',{net=v.net,id=v.id,transfer=transfer})
        local reason=type(prepared)=='table' and prepared.reason
        MX.require(type(prepared)=='table' and prepared.ready==true,'RESPAWN',reason=='EXIT_TIMEOUT' and 'O desembarque do carro atual não foi concluído' or 'O cliente não confirmou a preparação do carro')
        local deadline=GetGameTimer()+2000
        while GetVehiclePedIsIn(GetPlayerPed(src),false)==v.entity and GetGameTimer()<deadline do Wait(50) end
        MX.require(MX.actor(src) and MX.actor(src).epoch==actor.epoch and selected(src)==v and DoesEntityExist(v.entity) and Entity(v.entity).state.mxVehicle==v.id,'OBSOLETE')
        MX.require(GetPlayerRoutingBucket(src)==0 and GetEntityRoutingBucket(v.entity)==0,'SESSION','A dimensão mudou; recriação cancelada')
        MX.require(GetVehiclePedIsIn(GetPlayerPed(src),false)==0 and not passengers(v.entity,src),'PASSENGER','A saída dos ocupantes não foi confirmada')
        -- Capture the final stopped position, not the point before model loading.
        point=GetEntityCoords(v.entity) heading=GetEntityHeading(v.entity)
        DeleteEntity(v.entity)
        deadline=GetGameTimer()+2000 while DoesEntityExist(v.entity) and GetGameTimer()<deadline do Wait(50) end
        MX.require(not DoesEntityExist(v.entity),'RESPAWN','A remoção do carro anterior não foi confirmada')
    end)
    if not ok then
        local resumed,response=pcall(MX.callClient,src,'vehicles','resumeRespawn',{net=v.net,id=v.id,transfer=transfer})
        local failure=MX.error(err)
        local recovered=resumed and response and response.resumed==true
        if not recovered then print(json.encode({domain='vehicles',action='resumeRespawn',code='RECOVERY_UNCONFIRMED',vehicle=v.id,transfer=transfer})) end
        MX.fail(failure.code,failure.message..(recovered and '. O carro anterior foi liberado; você pode tentar novamente.' or '. A recuperação não foi confirmada; a proteção local libera o carro automaticamente em até 10 segundos.'))
    end
    for i,car in ipairs(fleet[src] or {}) do if car==v then table.remove(fleet[src],i) break end end active[src]=nil
    local created,result=pcall(spawn,src,VehicleConfig.catalog[target.model],properties,actor,{point={x=point.x,y=point.y,z=point.z,h=heading},departure=false,drift=drift},{id=target.id,drift_enabled=drift})
    if not created then MX.fail('RESPAWN','O carro anterior foi removido, mas a recriação falhou. Suas configurações salvas foram preservadas; entre na garagem para recuperá-lo. '..MX.error(result).message) end
    return result
end
local function persistDrift(src,v,enabled,actor)
    local id=v.presetId
    if not id then
        -- Session cars become a single saved creation the first time handling
        -- is persisted. Subsequent toggles reuse its ID, never its model name.
        id=MX.uuid()
        local prepared=exports[GetCurrentResourceName()]:PrepareSaved(actor.id,'add',{id=id,model=v.model,name=v.model,properties=v.properties})
        prepared.queries[#prepared.queries+1]={query='UPDATE garage_presets SET drift_enabled=? WHERE id=? AND player_id=?',values={enabled and 1 or 0,id,actor.id}}
        MX.tx(prepared.queries)
    else
        MX.db('UPDATE garage_presets SET drift_enabled=? WHERE id=? AND player_id=?',{enabled and 1 or 0,id,actor.id})
    end
    v.presetId=id -- Retain identity even if verification times out after commit.
    local row=exports[GetCurrentResourceName()]:Saved(actor.id,id)
    MX.require((row.drift_enabled==true or row.drift_enabled==1)==enabled,'PERSISTENCE','O modo drift não foi confirmado no banco; tente novamente')
end
VehicleServices.configure({selected=selected,editing=function(src)return edits[src]~=nil end,passengers=passengers,invalidate=invalidate,respawn=respawn,persistDrift=persistDrift})
MX.routes('vehicles',{
    trainerGarage=function(src,_,actor)
        MX.require(GetPlayerRoutingBucket(src)==0 and not (MX.online('mx-freeroam-experience') and exports['mx-freeroam-experience']:IsPrivate(src)),'SESSION','Disponível no modo livre')
        return exports[GetCurrentResourceName()]:SavedList(actor.id)
    end,
    switch=function(src,d,actor)
        MX.require(GetPlayerRoutingBucket(src)==0 and GetEntityHealth(GetPlayerPed(src))>0 and not (MX.online('mx-freeroam-experience') and exports['mx-freeroam-experience']:IsPrivate(src)),'SESSION','Disponível no modo livre, com o personagem vivo')
        MX.require(not edits[src],'EDIT','Finalize a personalização')
        MX.require((type(d.presetId)=='string')~=(type(d.model)=='string'),'PAYLOAD','Escolha uma criação salva ou um modelo')
        exports['mx-freeroam-world']:StopTrainer(src)
        local target
        if d.presetId then
            target=exports[GetCurrentResourceName()]:Saved(actor.id,d.presetId)
            MX.require(target.available,'MODEL','A criação salva está indisponível')
        else
            local item=VehicleConfig.catalog[d.model]
            MX.require(item and item.source=='vehicles' and available(item),'MODEL','Modelo indisponível no catálogo')
            target={model=item.model,properties=VehicleProperties.defaults(),drift_enabled=false}
        end
        local v=selected(src) local ped=GetPlayerPed(src)
        if GetVehiclePedIsIn(ped,false)~=0 then v=owned(src,true) end
        invalidate(src,'vehicle_changed')
        if v then return respawn(src,v,actor,target) end
        local p=GetEntityCoords(ped) local point={x=p.x,y=p.y,z=p.z,h=GetEntityHeading(ped)}
        local slot=exports['mx-freeroam-world']:Reserve(src,'trainerSpawn',point,true)
        slot.departure=false
        return spawn(src,VehicleConfig.catalog[target.model],VehicleProperties.validate(target.properties),actor,slot,target)
    end,
    catalogBrands=function()
        local seen,result={},{}
        for _,row in pairs(VehicleConfig.catalog) do if row.source=='vehicles' and not seen[row.brand] then seen[row.brand]=true result[#result+1]=row.brand end end
        table.sort(result) return result
    end,
    catalog=function(_,d,actor)
        local page=d.page or 0 local search=d.search or '' local category=d.category or 'Todas'
        MX.require(MX.number(page,0,100,true) and type(search)=='string' and #search<=64 and MX.text(category,1,32) and (d.favorites==nil or type(d.favorites)=='boolean'),'FILTER')
        local favorites=MX.db('SELECT catalog_id FROM player_favorites WHERE player_id=?',{actor.id}) local fav={} for _,r in ipairs(favorites) do fav[r.catalog_id]=true end
        local list={} for _,v in pairs(VehicleConfig.catalog) do
            if v.source=='vehicles' and (category=='Todas' or v.category==category) and (not d.brand or d.brand==v.brand) and (not d.favorites or fav[v.id]) and (search=='' or (v.name..' '..v.model..' '..table.concat(v.tags,' ')):lower():find(search:lower(),1,true)) then
                local copy=MX.copy(v) copy.available=available(v) copy.favorite=fav[v.id]==true list[#list+1]=copy
            end
        end
        table.sort(list,function(a,b) return a.id<b.id end)
        local result={} for i=page*20+1,math.min(#list,page*20+20) do result[#result+1]=list[i] end return result
    end,
    favorite=function(_,d,actor)
        MX.require(VehicleConfig.catalog[d.id] and type(d.value)=='boolean','MODEL')
        MX.db(d.value and 'INSERT IGNORE INTO player_favorites(player_id,catalog_id) VALUES (?,?)' or 'DELETE FROM player_favorites WHERE player_id=? AND catalog_id=?',{actor.id,d.id}) return {}
    end,
    spawn=function(src,d,actor) legacyEditor() MX.require(type(d.model)=='string','MODEL') return spawn(src,VehicleConfig.catalog[d.model],VehicleProperties.defaults(),actor) end,
    garage=function(_,d,actor)
        local page=d.page or 0 MX.require(MX.number(page,0,100,true),'PAGE')
        local rows=MX.db('SELECT id,name,model,schema_version,revision,properties FROM garage_presets WHERE player_id=? ORDER BY created_at,id LIMIT 20 OFFSET ?',{actor.id,page*20})
        for _,row in ipairs(rows) do row.properties=json.decode(row.properties) end return rows
    end,
    restore=function(src,d,actor) legacyEditor()
        local row=preset(actor,d.id) MX.require(row.schema_version==VehicleConfig.schema,'SCHEMA','Preset de outra versão')
        return spawn(src,VehicleConfig.catalog[row.model],VehicleProperties.validate(json.decode(row.properties)),actor,nil,row)
    end,
    save=function(src,d,actor) legacyEditor()
        local v=owned(src,false) MX.require(not edits[src],'EDIT','Aplique a personalização antes de salvar')
        MX.require(MX.text(d.name,1,48) and MX.text(d.id,36,36),'PRESET')
        local old=MX.db('SELECT id,revision FROM garage_presets WHERE id=? AND player_id=?',{d.id,actor.id})[1]
        if old then
            MX.require(d.revision==old.revision,'CONFLICT','Preset mudou; recarregue')
            local result=MX.db('UPDATE garage_presets SET name=?,properties=?,schema_version=?,revision=revision+1 WHERE id=? AND player_id=? AND revision=?',{d.name,json.encode(v.properties),VehicleConfig.schema,d.id,actor.id,d.revision})
            MX.require(result.affectedRows==1,'CONFLICT') v.presetId=d.id return {id=d.id,revision=d.revision+1}
        end
        MX.require(d.revision==0,'CONFLICT')
        MX.require(MX.db('SELECT COUNT(*) AS n FROM garage_presets WHERE player_id=?',{actor.id})[1].n<VehicleConfig.presetLimit,'LIMIT','Limite da garagem atingido')
        MX.db('INSERT INTO garage_presets(id,player_id,name,model,properties,schema_version,drift_enabled) VALUES (?,?,?,?,?,?,?)',{d.id,actor.id,d.name,v.model,json.encode(v.properties),VehicleConfig.schema,v.drift and 1 or 0}) v.presetId=d.id return {id=d.id,revision=1}
    end,
    rename=function(_,d,actor) legacyEditor()
        preset(actor,d.id) MX.require(MX.text(d.name,1,48) and MX.number(d.revision,1,2147483647,true),'PRESET')
        local r=MX.db('UPDATE garage_presets SET name=?,revision=revision+1 WHERE id=? AND player_id=? AND revision=?',{d.name,d.id,actor.id,d.revision}) MX.require(r.affectedRows==1,'CONFLICT') return {}
    end,
    duplicate=function(_,d,actor) legacyEditor()
        local row=preset(actor,d.id) MX.require(MX.text(d.newId,36,36),'PRESET')
        MX.require(MX.db('SELECT COUNT(*) AS n FROM garage_presets WHERE player_id=?',{actor.id})[1].n<VehicleConfig.presetLimit,'LIMIT')
        MX.db('INSERT IGNORE INTO garage_presets(id,player_id,name,model,properties,schema_version,drift_enabled) VALUES (?,?,?,?,?,?,?)',{d.newId,actor.id,(row.name..' cópia'):sub(1,48),row.model,row.properties,row.schema_version,row.drift_enabled or 0}) return {}
    end,
    delete=function(_,d,actor) legacyEditor()
        preset(actor,d.id) MX.require(MX.number(d.revision,1,2147483647,true),'PRESET')
        local r=MX.db('DELETE FROM garage_presets WHERE id=? AND player_id=? AND revision=?',{d.id,actor.id,d.revision}) MX.require(r.affectedRows==1,'CONFLICT') return {}
    end,
    edit=function(src) legacyEditor()
        local v=owned(src,true) MX.require(not edits[src],'EDIT') invalidate(src,'customization')
        local caps=MX.callClient(src,'vehicles','inspect',{net=v.net,id=v.id,properties=v.properties})
        edits[src]={vehicle=v.id,snapshot=MX.copy(v.properties),preview=MX.copy(v.properties),expires=GetGameTimer()+VehicleConfig.editTimeout}
        return {properties=v.properties,capabilities=caps}
    end,
    preview=function(src,d) legacyEditor()
        local v=owned(src,true) local edit=edits[src] MX.require(edit and edit.vehicle==v.id,'EDIT','Abra a personalização novamente')
        local p=VehicleProperties.validate(d.properties)
        local ok,result=pcall(MX.callClient,src,'vehicles','apply',{net=v.net,id=v.id,properties=p,editing=true})
        if not ok then pcall(MX.callClient,src,'vehicles','apply',{net=v.net,id=v.id,properties=edit.preview,editing=true}) error(result,0) end
        MX.require(result.applied==true,'APPLY')
        edit.preview=VehicleProperties.acceptStance(p,result) edit.expires=GetGameTimer()+VehicleConfig.editTimeout return {capabilities=result.capabilities,warning=result.warning}
    end,
    commit=function(src) legacyEditor()
        local v=owned(src,true) local edit=edits[src] MX.require(edit and edit.vehicle==v.id,'EDIT')
        local result=MX.callClient(src,'vehicles','apply',{net=v.net,id=v.id,properties=edit.preview,editing=false})
        MX.require(result.applied==true,'APPLY')
        v.properties=VehicleProperties.acceptStance(edit.preview,result) edits[src]=nil return {warning=result.warning}
    end,
    cancel=function(src) return cancel(src) end,
    options=VehicleServices.status,
    handlingAudit=VehicleServices.audit,
    service=VehicleServices.run
})
exports('Inspect',function() local list={} for src,cars in pairs(fleet) do for _,v in ipairs(cars) do list[#list+1]={source=src,id=v.id,net=v.net,model=v.model} end end return list end)
exports('Cleanup',function() for src,cars in pairs(fleet) do for i=#cars,1,-1 do local v=cars[i] if not passengers(v.entity,src) then DeleteEntity(v.entity) table.remove(cars,i) if active[src]==v then active[src]=nil edits[src]=nil end end end end end)
AddEventHandler('mx:profile:dropped',function(src) for _,v in ipairs(fleet[src] or {}) do retire(v,-1) end fleet[src]=nil active[src]=nil edits[src]=nil cooldown[src]=nil end)
CreateThread(function() while true do Wait(1000) for src,e in pairs(edits) do if e.expires<GetGameTimer() then cancel(src) end end end end)
AddEventHandler('onResourceStop',function(name)
    if name==GetCurrentResourceName() then
        local journal={boot=exports['mx-freeroam-core']:BootId(),entities={}}
        for _,cars in pairs(fleet) do for _,v in ipairs(cars) do
            if DoesEntityExist(v.entity) then
                if not passengers(v.entity,-1) then DeleteEntity(v.entity) else retired[v.id]=v end
            end
        end end
        for _,v in pairs(retired) do if DoesEntityExist(v.entity) then journal.entities[#journal.entities+1]={id=v.id,entity=v.entity,net=v.net,model=v.model} end end
        SaveResourceFile(GetCurrentResourceName(),'retired.local.json',json.encode(journal),-1)
    end
end)
CreateThread(function()
    Wait(1500)
    assert(MX.number(VehicleConfig.maxActivePerPlayer,1,3,true),'Limite de carros deve ser 1..3')
    local count=0 for id,item in pairs(VehicleConfig.catalog) do
        count=count+1
        assert(id==item.id and MX.text(item.model,1,48) and item.model:match('^[a-z0-9_]+$') and MX.text(item.name,1,64) and MX.text(item.category,1,32),'Catálogo inválido')
        assert(MX.number(item.revision,1,10000,true) and type(item.tags)=='table' and #item.tags<=10,'Catálogo inválido')
        for _,tag in ipairs(item.tags) do assert(MX.text(tag,1,24),('Tag inválida no modelo %s: %q (máximo 24 bytes)'):format(id,tostring(tag))) end
    end
    assert(count>0 and count<=200,'Limite de catálogo inválido')
    local raw=LoadResourceFile(GetCurrentResourceName(),'retired.local.json')
    if raw then
        local ok,journal=pcall(json.decode,raw)
        if ok and journal.boot==exports['mx-freeroam-core']:BootId() then
            for _,v in ipairs(journal.entities) do
                if DoesEntityExist(v.entity) and NetworkGetNetworkIdFromEntity(v.entity)==v.net and GetEntityModel(v.entity)==joaat(v.model) and Entity(v.entity).state.mxVehicle==v.id then retired[v.id]=v end
            end
        end
    end
    -- Registro transitório do servidor confirma responsabilidade; state bag isolada nunca autoriza limpeza.
    while true do Wait(1000) for id,v in pairs(retired) do if not DoesEntityExist(v.entity) then retired[id]=nil elseif not passengers(v.entity,-1) then DeleteEntity(v.entity) retired[id]=nil end end end
end)
