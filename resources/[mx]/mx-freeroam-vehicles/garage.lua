-- Saved creations and preview entities belong to vehicles, not profile/UI.
local previews={}
local tracked={}
local metrics={created=0,removed=0,reused=0,unchanged=0,loaded=0}
local function equal(a,b)
 if type(a)~=type(b) then return false end
 if type(a)~='table' then return a==b end
 for k,v in pairs(a) do if not equal(v,b[k]) then return false end end
 for k in pairs(b) do if a[k]==nil then return false end end
 return true
end
local resource=GetCurrentResourceName()
local journalFile='preview-journal.local.json'
local function owns(p) return DoesEntityExist(p.entity) and NetworkGetNetworkIdFromEntity(p.entity)==p.net and Entity(p.entity).state.mxVehicle==p.id end
local function allowed(model) local item=VehicleConfig.catalog[model] return item and not item.conflict and (not item.asset or MX.online(item.asset)) end
local function label(row)
    local item=VehicleConfig.catalog[row.model]
    row.modelLabel=item and item.name or row.model
    return row
end
local function saved(player,id)
    MX.require(type(id)=='string' and #id==36,'PRESET')
    local row=MX.db('SELECT * FROM garage_presets WHERE player_id=? AND id=?',{player,id})[1]
    MX.require(row,'NOT_FOUND','Configuração não encontrada')
    row.properties=VehicleProperties.validate(json.decode(row.properties)) row.available=allowed(row.model) and row.schema_version==VehicleConfig.schema or false
    return label(row)
end
exports('Saved',saved)
exports('SavedDisplayList',function(player,limit,excluded)
    MX.require(MX.number(limit,1,7,true),'LIMIT')
    -- One bounded, owner-scoped read. Never fetch the whole garage's documents.
    local rows=MX.db('SELECT id,model,revision,properties,schema_version FROM garage_presets WHERE player_id=? AND id<>? AND schema_version=? ORDER BY created_at DESC,id LIMIT ?', {player,excluded or '',VehicleConfig.schema,limit*3})
    local result={}
    for _,row in ipairs(rows)do
        if allowed(row.model)then
            local ok,properties=pcall(function()return VehicleProperties.validate(json.decode(row.properties))end)
            if ok then result[#result+1]={id=row.id,model=row.model,revision=row.revision,properties=properties}end
        end
        if #result>=limit then break end
    end
    return result
end)
exports('SavedList',function(player)
    local rows=MX.db('SELECT p.id,p.name,p.model,p.revision,p.schema_version,p.drift_enabled,u.used_at FROM garage_presets p LEFT JOIN garage_usage u ON u.preset_id=p.id WHERE p.player_id=? ORDER BY u.used_at DESC,p.created_at DESC,p.id',{player})
    for _,row in ipairs(rows) do row.available=allowed(row.model) and row.schema_version==VehicleConfig.schema or false label(row) end return rows
end)
local function persistPreviews()
    local entries={}
    for _,p in pairs(tracked) do entries[#entries+1]={id=p.id,net=p.net,bucket=p.slot.bucket} end
    SaveResourceFile(resource,journalFile,json.encode({boot=exports['mx-freeroam-core']:BootId(),entries=entries}),-1)
end
local function destroy(s,p,src,ack)
    if not p then return end
    p.cancelled=true
    p.needsAck=ack==true
    if s.current==p then s.current=nil end
    if owns(p) then metrics.removed=metrics.removed+1 DeleteEntity(p.entity) end
    if ack then
        local deadline=GetGameTimer()+1500
        while owns(p) and GetGameTimer()<deadline do Wait(0) end
        MX.require(not owns(p),'PREVIEW_DELETE','A prévia anterior ainda está sendo removida')
        local cleared=MX.callClient(src,'vehicles','previewCleared',{id=p.id,net=p.net})
        MX.require(cleared.cleared,'PREVIEW_DELETE','O cliente ainda não confirmou a remoção')
        p.needsAck=false
    end
    if not owns(p) then s.entities[p.id]=nil tracked[p.id]=nil end
    if s.current==p then s.current=nil end
    persistPreviews()
end
local function remove(src,ack)
    local s=previews[src] if not s then return end
    PreviewState.cancel(s)
    -- Keep every tracked candidate until its deletion is confirmed server-side.
    local entities={} for _,p in pairs(s.entities) do entities[#entities+1]=p end
    for _,p in ipairs(entities) do destroy(s,p,src,ack==true) end
    if previews[src]==s then previews[src]=nil end persistPreviews()
end
exports('RemovePreview',remove)
exports('RegisterPreviewContext',function(src,token,epoch,bucket)
    local old=previews[src]
    if old and old.alive and old.token==token and old.epoch==epoch and old.bucket==bucket then return end
    remove(src,false) previews[src]=PreviewState.new(token,epoch,bucket)
end)
exports('PreviewIntent',function(src,token,id)
    local s=previews[src] local actor=MX.actor(src)
    if not s or not s.alive or not actor or actor.epoch~=s.epoch or token~=s.token then return false end
    PreviewState.intent(s,id) return true
end)
exports('Preview',function(src,model,properties,point,intent)
    return MX.capture(function()
    local loadIntent=intent -- automatic lobby/garage previews have no UI intent
    local s=previews[src] MX.require(s and s.alive,'SESSION')
    MX.require(not s.busy,'BUSY','A prévia anterior ainda está sendo encerrada')
    if intent then MX.require(s.intent==intent,'OBSOLETE','Seleção substituída') else intent=MX.uuid() PreviewState.intent(s,intent) end
    local generation=s.generation
    local function current()
        local actor=MX.actor(src)
        return previews[src]==s and actor and PreviewState.valid(s,generation,s.token,actor.epoch,GetPlayerRoutingBucket(src))
    end
    MX.require(allowed(model),'MODEL','Modelo indisponível')
    local properties=VehicleProperties.validate(properties or VehicleProperties.defaults())
    local previous=s.current local candidate
    s.busy=true
    local ok,result=pcall(function()
        if previous and owns(previous) and previous.model==model and equal(previous.point,point) then
            MX.require(current(),'OBSOLETE')
            if equal(previous.properties,properties) and not previous.uncertain then metrics.unchanged=metrics.unchanged+1
            else
                previous.uncertain=true
                local applied=MX.callClient(src,'vehicles','apply',{id=previous.id,net=previous.net,properties=properties,presentation=true})
                MX.require(current() and s.current==previous and owns(previous),'OBSOLETE') MX.require(applied.applied,'APPLY')
                properties=VehicleProperties.acceptStance(properties,applied)
                previous.properties=MX.copy(properties) previous.capabilities=applied.capabilities previous.uncertain=false
                VehicleProperties.publish(previous.entity,previous.id,properties)
                metrics.reused=metrics.reused+1
            end
            return {id=previous.id,net=previous.net,model=model,properties=MX.copy(previous.properties),capabilities=previous.capabilities,intent=intent}
        end
        metrics.loaded=metrics.loaded+1
        local loaded=MX.callClient(src,'vehicles','load',{model=model,intent=loadIntent})
        MX.require(current() and not loaded.cancelled,'OBSOLETE','Seleção substituída') MX.require(loaded.loaded,'ASSET','O veículo ainda não terminou de carregar. Tente selecioná-lo novamente.')
        -- The previous car survives failed loading. Once loading succeeds, remove it
        -- and observe deletion on both peers before publishing another presentation.
        destroy(s,previous,src,true)
        MX.require(current(),'OBSOLETE')
        local debris={} for _,p in pairs(tracked) do if p.cancelled and p.slot.bucket==s.bucket then debris[#debris+1]=p end end
        for _,p in ipairs(debris) do destroy(p.slot,p,src,true) MX.require(current(),'OBSOLETE') end
        local id=MX.uuid() MX.require(current(),'OBSOLETE')
        local entity=CreateVehicleServerSetter(joaat(model),'automobile',point.x,point.y,point.z,point.h)
        MX.require(entity~=0,'SPAWN') metrics.created=metrics.created+1
        candidate={entity=entity,id=id,net=NetworkGetNetworkIdFromEntity(entity),model=model,properties=MX.copy(properties),point=point,slot=s,source=src}
        s.entities[candidate.id]=candidate -- Register BEFORE the next yielding operation.
        tracked[candidate.id]=candidate
        SetEntityRoutingBucket(entity,s.bucket) SetEntityOrphanMode(entity,2) Entity(entity).state:set('mxVehicle',candidate.id,true)
        persistPreviews()
        local applied=MX.callClient(src,'vehicles','apply',{id=candidate.id,net=candidate.net,properties=properties,presentation=true})
        MX.require(current(),'OBSOLETE') MX.require(applied.applied,'APPLY')
        candidate.capabilities=applied.capabilities
        properties=VehicleProperties.acceptStance(properties,applied) candidate.properties=MX.copy(properties)
        VehicleProperties.publish(candidate.entity,candidate.id,properties)
        s.current=candidate
        return {id=candidate.id,net=candidate.net,model=model,capabilities=applied.capabilities,properties=properties,intent=intent}
    end)
    if not ok and candidate then pcall(destroy,s,candidate,src,true) end
    s.busy=false
    -- Never resurrect the previous choice after cancellation. An ordinary apply
    -- failure can be recovered explicitly using the still-persisted selected ID.
    if not ok then error(result,0) end return result
    end)
end)
exports('ApplyPreview',function(src,properties)
    return MX.capture(function()
    local s=previews[src] local p=s and s.current
    MX.require(s and s.alive and not s.busy and p and owns(p),'VEHICLE','Reabra a criação confirmada')
    local generation=s.generation local values=VehicleProperties.validate(properties)
    p.uncertain=true
    local result=MX.callClient(src,'vehicles','apply',{id=p.id,net=p.net,properties=values,presentation=true})
    local actor=MX.actor(src)
    MX.require(actor and previews[src]==s and PreviewState.valid(s,generation,s.token,actor.epoch,GetPlayerRoutingBucket(src)) and s.current==p and owns(p),'OBSOLETE')
    MX.require(result.applied==true,'APPLY','Personalização não confirmada')
    values=VehicleProperties.acceptStance(values,result)
    p.properties=MX.copy(values) p.capabilities=result.capabilities p.uncertain=false VehicleProperties.publish(p.entity,p.id,values) return result
    end)
end)
exports('PreviewMetrics',function() return MX.copy(metrics) end)
exports('PreviewInspect',function()
    local result={} for src,s in pairs(previews) do local n=0 for _ in pairs(s.entities) do n=n+1 end result[#result+1]={source=src,count=n,busy=s.busy==true,generation=s.generation} end return result
end)
exports('CurrentPreview',function(src)
    local s=previews[src] local p=s and s.current
    if p and owns(p) then return {id=p.id,net=p.net,model=p.model,properties=p.properties,capabilities=p.capabilities} end
end)
AddEventHandler('playerDropped',function() remove(source,false) end)
AddEventHandler('onResourceStop',function(r) if r==resource then local sources={} for src in pairs(previews) do sources[#sources+1]=src end for _,src in ipairs(sources) do remove(src,false) end for _,p in pairs(tracked) do p.cancelled=true if owns(p) then DeleteEntity(p.entity) end end persistPreviews() end end)
CreateThread(function()
    local text=LoadResourceFile(resource,journalFile)
    if text then
        local ok,data=pcall(json.decode,text)
        if ok and data.boot==exports['mx-freeroam-core']:BootId() then
            for _,p in ipairs(data.entries or {}) do
                local entity=NetworkGetEntityFromNetworkId(p.net)
                if entity~=0 and DoesEntityExist(entity) and Entity(entity).state.mxVehicle==p.id and GetEntityRoutingBucket(entity)==p.bucket then
                    local s=PreviewState.new('recovery','',p.bucket) s.alive=false
                    tracked[p.id]={id=p.id,net=p.net,entity=entity,slot=s,cancelled=true} DeleteEntity(entity)
                end
            end
        end
    end
    persistPreviews()
end)
-- Deletion can be asynchronous. Retain tracked references and retry only these
-- owned IDs, never enumerate or delete vehicles by proximity.
CreateThread(function()
    while true do Wait(1000) for src,s in pairs(previews) do
        if not s.alive then for _,p in pairs(s.entities) do if owns(p) then DeleteEntity(p.entity) else s.entities[p.id]=nil end end if not next(s.entities) and not s.busy then previews[src]=nil persistPreviews() end end
    end
    for id,p in pairs(tracked) do if p.cancelled or not p.slot.alive then if owns(p) then DeleteEntity(p.entity) elseif not p.needsAck or not p.source or not MX.actor(p.source) then tracked[id]=nil p.slot.entities[id]=nil persistPreviews() end end end
    end
end)
exports('PrepareSaved',function(player,action,d)
    MX.require(MX.text(d.id,36,36),'PRESET')
    local queries={} local result={id=d.id}
    local function q(sql,args) queries[#queries+1]={query=sql,values=args} end
    if action=='add' or action=='duplicate' then
        MX.require(MX.db('SELECT COUNT(*) n FROM garage_presets WHERE player_id=?',{player})[1].n<VehicleConfig.presetLimit,'LIMIT','Limite de criações atingido')
        local model,p,name,drift=d.model,VehicleProperties.validate(d.properties or VehicleProperties.defaults()),d.name,0
        if action=='duplicate' then local original=saved(player,d.sourceId) model=original.model p=original.properties name=(original.name..' cópia'):sub(1,48) drift=(original.drift_enabled==true or original.drift_enabled==1) and 1 or 0 end
        MX.require(allowed(model),'MODEL','Modelo indisponível') MX.require(MX.text(name,1,48),'NAME')
        MX.require(not MX.db('SELECT id FROM garage_presets WHERE id=?',{d.id})[1],'CONFLICT')
        q('INSERT INTO garage_presets(id,player_id,name,model,properties,schema_version,drift_enabled) VALUES (?,?,?,?,?,?,?)',{d.id,player,name,model,json.encode(p),VehicleConfig.schema,drift}) result.revision=1
    else
        local old=saved(player,d.id) MX.require(old.revision==d.revision,'CONFLICT','Configuração mudou; recarregue')
        if action=='delete' then q('DELETE FROM garage_presets WHERE id=? AND player_id=? AND revision=?',{d.id,player,d.revision})
        elseif action=='rename' then MX.require(MX.text(d.name,1,48),'NAME') q('UPDATE garage_presets SET name=?,revision=revision+1 WHERE id=? AND player_id=? AND revision=?',{d.name,d.id,player,d.revision})
        elseif action=='save' then
            MX.require(allowed(old.model),'MODEL') local p=VehicleProperties.validate(d.properties)
            q('UPDATE garage_presets SET properties=?,revision=revision+1 WHERE id=? AND player_id=? AND revision=?',{json.encode(p),d.id,player,d.revision})
        else MX.fail('ACTION') end
        result.revision=d.revision+1
    end
    return {queries=queries,result=result}
end)
