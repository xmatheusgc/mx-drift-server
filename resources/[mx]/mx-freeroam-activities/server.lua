local sessions,duels,spool={}, {}, {}
local ready=false
local resource=GetCurrentResourceName()
local stored=LoadResourceFile(resource,'pending-results.local.json')
if stored then local ok,data=pcall(json.decode,stored) if ok and type(data)=='table' then spool=data else print('[MX activities] Spool corrompido; intervenção necessária') end end
local function saveSpool() MX.require(SaveResourceFile(resource,'pending-results.local.json',json.encode(spool),-1),'DISK','Falha no diário local; resultado não confirmado') end
local function persist(row)
    MX.tx({{query=[[INSERT IGNORE INTO activity_results(id,player_id,track_id,track_revision,direction,mode,rules,model,signature,conditions,duration_ms,distance_m,eligible,reason,evidence,created_at) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,UTC_TIMESTAMP(3))]],
        values={row.id,row.player_id,row.track_id,row.track_revision,row.direction,row.mode,row.rules,row.model,row.signature,row.conditions,row.duration_ms,row.distance_m,row.eligible,row.reason,json.encode(row.evidence)}},
        {query='INSERT IGNORE INTO activity_delivery(result_id) VALUES (?)',values={row.id}}})
    TriggerEvent('mx:activities:result',row.id)
end
local function state(src,s)
    if not s then TriggerClientEvent('mx:activities:state',src,nil) return end
    TriggerClientEvent('mx:activities:state',src,{id=s.id,net=NetworkGetNetworkIdFromEntity(s.entity),state=s.state,mode=s.mode,checkpoint=s.next-1,total=#s.track.checkpoints,elapsed=s.start and math.max(0,GetGameTimer()-s.start) or 0,reason=s.reason,bestMs=s.bestMs,deltaMs=s.deltaMs,nextPoint=s.track.checkpoints[s.next],radius=s.track.checkpointRadius,duel=s.duel})
end
local finish
local function clear(src,s)
    if sessions[src]==s then sessions[src]=nil end
    TriggerClientEvent('mx:activities:release',src)
    state(src,nil)
end
local function duelSummary(key)
    local duel=duels[key] if not duel or not duel.results[duel.players[1]] or not duel.results[duel.players[2]] then return end
    local a,b=duel.results[duel.players[1]],duel.results[duel.players[2]]
    local text
    if not a.eligible or not b.eligible then text='Duelo encerrado: tentativa inválida/desistência; sem vencedor por tempo'
    elseif math.abs(a.duration_ms-b.duration_ms)<=ActivityConfig.tieMs then text='Duelo concluído: empate técnico'
    else text='Duelo concluído: melhor tempo de #'..(a.duration_ms<b.duration_ms and duel.players[1] or duel.players[2]) end
    local function time(row) return row.eligible and ('%.3f s'):format(row.duration_ms/1000) or ('inválido: '..(row.reason or 'sem tempo elegível')) end
    text=text..' | #'..duel.players[1]..': '..time(a)..' | #'..duel.players[2]..': '..time(b)
    for _,src in ipairs(duel.players) do TriggerClientEvent('mx:notify',src,text) TriggerClientEvent('mx:activities:ghost',src,{}) end
    duels[key]=nil
end
finish=function(src,s,nextState,reason)
    if not s or s.terminal then return end s.terminal=true
    ActivityRules.transition(s,nextState) s.reason=reason
    local now=GetGameTimer()
    local row={id=s.id,player_id=s.player,track_id=s.track.id,track_revision=s.track.revision,direction=s.track.direction,mode=s.mode,rules=s.rules,model=s.model,signature=s.signature,conditions=s.conditions,
        duration_ms=s.start and math.max(0,now-s.start) or 0,distance_m=s.distance,eligible=nextState=='completed' and s.track.validated and s.track.activated and (s.mode=='timeattack' or s.mode=='duel'),reason=reason or (s.mode=='practice' and 'practice' or s.mode=='drift' and 'drift_training' or ''),
        evidence={state=nextState,checkpoints=s.evidence,telemetry=s.telemetry,telemetryVersion=ActivityConfig.driftTelemetryVersion,validCompletion=nextState=='completed',sampleMs=ActivityConfig.sampleMs,ruleRevision=s.rules,duel=s.duel}}
    spool[row.id]=row
    local diskOk=pcall(saveSpool)
    local ok=pcall(persist,row)
    if ok then spool[row.id]=nil pcall(saveSpool) end
    clear(src,s)
    TriggerClientEvent('mx:notify',src,ok and (nextState=='completed' and 'Resultado persistido' or 'Tentativa encerrada: '..(reason or nextState)) or (diskOk and 'Banco indisponível: resultado pendente no diário local, sem confirmação de prêmio' or 'Falha de banco e diário; resultado não confirmado. Contate a administração.'))
    if s.duel and duels[s.duel] then
        local duel=duels[s.duel] duel.results[src]=row
        if nextState~='completed' then for _,other in ipairs(duel.players) do if other~=src and sessions[other] then finish(other,sessions[other],'invalid','duel_peer_'..(reason or 'invalid')) end end end
        duelSummary(s.duel)
    end
end
local function invalidate(src,reason)
    local s=sessions[src] if s then finish(src,s,'invalid',reason or 'invalidated') end
end
exports('Invalidate',invalidate)
exports('State',function(src) local s=sessions[src] return s and {id=s.id,state=s.state,mode=s.mode} end)
exports('Recovery',function(src) local s=sessions[src] if s then return {destination=s.track.destination,point=s.track.recoveries[math.max(1,s.next-1)]} end end)
exports('Inspect',function() local rows={} for src,s in pairs(sessions) do rows[#rows+1]={source=src,id=s.id,state=s.state,mode=s.mode,track=s.track.id} end return rows end)
local function track(id,mode)
    MX.require(type(id)=='string','TRACK') local t=ActivityConfig.tracks[id]
    MX.require(ready and t and (not t.asset or MX.online(t.asset)),'TRACK','Pista indisponível')
    MX.require((t.activated and t.validated) or (ActivityConfig.allowDraftPractice and (mode=='practice' or mode=='drift')),'DRAFT','Pista em rascunho; exige validação humana antes de competição') return MX.copy(t)
end
exports('Publish',function(t)
    ActivityRules.track(t) MX.require(t.validated and t.activated,'DRAFT')
    local old=MX.db('SELECT definition FROM track_versions WHERE track_id=? AND revision=?',{t.id,t.revision})[1]
    MX.require(not old or MX.canonical(json.decode(old.definition))==MX.canonical(t),'TRACK_REVISION','Revisão já existe com outra definição; use nova revisão')
    MX.tx({{query='UPDATE track_versions SET active=0 WHERE track_id=?',values={t.id}}, {query='INSERT INTO track_versions(track_id,revision,definition,active) VALUES (?,?,?,1) ON DUPLICATE KEY UPDATE active=1',values={t.id,t.revision,json.encode(t)}}})
    ActivityConfig.tracks[t.id]=MX.copy(t) return true
end)
local function candidate(src,t,mode)
    MX.require(not exports['mx-freeroam-world']:TrainerActive(src),'NOCLIP','Desative o noclip antes de iniciar uma atividade')
    local actor=MX.actor(src) MX.require(actor and not sessions[src],'SESSION','Já existe sessão ativa')
    local v=exports['mx-freeroam-vehicles']:OwnedDriver(src,true)
    MX.require((not v.drift and not v.handlingUncertain) or mode=='practice' or mode=='drift','HANDLING','Desative o drift e confirme o handling original antes de iniciar uma atividade competitiva')
    local car=exports['mx-freeroam-vehicles']:Active(src)
    MX.require(not exports['mx-freeroam-vehicles']:IsEditing(src),'EDIT')
    MX.require(MX.distance(GetEntityCoords(v.entity),t.checkpoints[1])<t.startRadius and GetEntitySpeed(v.entity)<2,'START','Pare com seu carro junto ao início da pista')
    return actor,car
end
local function newSession(src,t,mode,duel)
    local actor,v=candidate(src,t,mode)
    local s={id=MX.uuid(),player=actor.id,epoch=actor.epoch,source=src,state='created',mode=mode,track=t,rules=ActivityConfig.rules,conditions=exports['mx-freeroam-world']:Conditions(),model=v.model,signature=v.signature,vehicle=v.id,entity=v.entity,bucket=GetPlayerRoutingBucket(src),next=2,distance=0,evidence={},telemetry={},duel=duel}
    ActivityRules.transition(s,'preparing') sessions[src]=s
    return s
end
local function prepare(list)
    local ok,err=pcall(function()
        for _,s in ipairs(list) do
            local response=MX.callClient(s.source,'activities','prepare',{id=s.id,net=NetworkGetNetworkIdFromEntity(s.entity)})
            MX.require(response.prepared==true and sessions[s.source]==s,'PREPARE')
            ActivityRules.transition(s,'countdown') state(s.source,s)
        end
    end)
    if not ok then for _,s in ipairs(list) do if sessions[s.source]==s then finish(s.source,s,'invalid','preparation_failed') end end error(err,0) end
    CreateThread(function()
        Wait(ActivityConfig.countdown)
        local valid=true
        for _,s in ipairs(list) do if sessions[s.source]~=s or not MX.actor(s.source) or MX.actor(s.source).epoch~=s.epoch or not DoesEntityExist(s.entity) or MX.distance(GetEntityCoords(s.entity),s.track.checkpoints[1])>s.track.startRadius then valid=false end end
        if not valid then for _,s in ipairs(list) do if sessions[s.source]==s then finish(s.source,s,'invalid','early_start_or_departure') end end return end
        local start=GetGameTimer()
        for _,s in ipairs(list) do
            s.start=start s.lastAt=start local p=GetEntityCoords(s.entity) s.previous={x=p.x,y=p.y,z=p.z}
            ActivityRules.transition(s,'active') state(s.source,s) TriggerClientEvent('mx:activities:go',s.source)
        end
    end)
end
local function describe(src,target,trackId)
    local t=track(trackId,'duel') local _,a=candidate(src,t) local _,b=candidate(target,t)
    MX.require(GetPlayerRoutingBucket(src)==GetPlayerRoutingBucket(target) and ActivityRules.comparable(a,b),'CATEGORY','Duelo exige mesmo modelo e preparação no mesmo mundo')
    return ActivityConfig.rules..' / '..t.id..' v'..t.revision..' / '..t.direction..' / '..exports['mx-freeroam-world']:Conditions()..' / localização compartilhada conforme preferências'
end
exports('DescribeDuel',describe)
exports('StartDuel',function(a,b,trackId,acceptedRules)
    MX.require(describe(a,b,trackId)==acceptedRules,'RULES','Regras mudaram; envie novo convite')
    local t=track(trackId,'duel') local key=MX.uuid()
    local first=newSession(a,t,'duel',key) local second
    local ok,result=pcall(function() second=newSession(b,t,'duel',key) duels[key]={players={a,b},results={}} TriggerClientEvent('mx:activities:ghost',a,{a,b}) TriggerClientEvent('mx:activities:ghost',b,{a,b}) prepare({first,second}) return {id=key} end)
    if not ok then if sessions[a]==first then finish(a,first,'invalid','duel_setup_failed') end if second and sessions[b]==second then finish(b,second,'invalid','duel_setup_failed') end error(result,0) end return result
end)
MX.routes('activities',{
    tracks=function()
        local list={} for _,t in pairs(ActivityConfig.tracks) do list[#list+1]={id=t.id,name=t.name,destination=t.destination,revision=t.revision,direction=t.direction,validated=t.validated and t.activated,rules=ActivityConfig.rules,available=ready and (t.validated and t.activated or ActivityConfig.allowDraftPractice) and (not t.asset or MX.online(t.asset)),drift=t.drift} end return list
    end,
    start=function(src,d)
        MX.require(d.mode=='practice' or d.mode=='timeattack' or d.mode=='drift','MODE')
        local t=track(d.track,d.mode) MX.require(d.mode~='drift' or t.drift,'MODE')
        local s=newSession(src,t,d.mode)
        if d.mode=='timeattack' then
            local rows=MX.db('SELECT duration_ms AS best,evidence FROM activity_results WHERE player_id=? AND track_id=? AND track_revision=? AND direction=? AND mode=? AND rules=? AND model=? AND signature=? AND conditions=? AND eligible=1 AND revoked=0 ORDER BY duration_ms,id LIMIT 1',{s.player,t.id,t.revision,t.direction,s.mode,s.rules,s.model,s.signature,s.conditions})
            if rows[1] then s.bestMs=rows[1].best s.bestSplits=json.decode(rows[1].evidence).checkpoints end
        end
        prepare({s}) return {id=s.id,state=s.state}
    end,
    stop=function(src)
        local s=sessions[src] MX.require(s,'SESSION','Sem sessão ativa')
        finish(src,s,s.mode=='drift' and s.state=='active' and 'completed' or 'cancelled',s.mode=='drift' and 'drift_training' or 'withdrawal') return {}
    end,
    state=function(src) local s=sessions[src] return s and {id=s.id,mode=s.mode,state=s.state} or {} end,
    telemetry=function(src,d)
        local s=sessions[src] MX.require(s and s.id==d.id and s.mode=='drift' and s.state=='active' and ActivityConfig.driftTelemetry,'SESSION')
        MX.require(GetGameTimer()-(s.telemetryAt or -10000)>=450,'RATE')
        MX.require(MX.number(d.speed,0,150) and MX.number(d.angle,-180,180) and MX.number(d.rpm,0,1),'TELEMETRY')
        s.telemetryAt=GetGameTimer()
        if #s.telemetry<ActivityConfig.telemetryLimit then s.telemetry[#s.telemetry+1]={ms=GetGameTimer()-s.start,speed=d.speed,angle=d.angle,rpm=d.rpm,provisional=true} end return {}
    end,
    configuration=function(src,d)
        local s=sessions[src] MX.require(s and s.id==d.id and MX.text(d.signature,1,255),'SESSION')
        s.observationAt=GetGameTimer()
        if d.signature~=s.signature then invalidate(src,'observed_configuration_changed') end return {}
    end,
    ranking=function(src,d)
        local mode=d.mode or 'timeattack' MX.require(mode=='timeattack' or mode=='practice' or mode=='duel','MODE')
        local t=track(d.track,mode) local car=exports['mx-freeroam-vehicles']:Active(src) MX.require(car,'VEHICLE')
        local page=d.page or 0 MX.require(MX.number(page,0,100,true),'PAGE')
        return MX.db([[SELECT r.id,p.name,r.duration_ms,r.model,r.mode FROM activity_results r JOIN players p ON p.id=r.player_id WHERE r.track_id=? AND r.track_revision=? AND r.direction=? AND r.mode=? AND r.rules=? AND r.model=? AND r.signature=? AND r.conditions=? AND r.eligible=? AND r.revoked=0 AND JSON_UNQUOTE(JSON_EXTRACT(r.evidence,'$.state'))='completed' ORDER BY r.duration_ms,r.id LIMIT 20 OFFSET ?]],{t.id,t.revision,t.direction,mode,ActivityConfig.rules,car.model,car.signature,exports['mx-freeroam-world']:Conditions(),mode=='practice' and 0 or 1,page*20})
    end
})
exports('Pending',function(limit)
    return MX.db("SELECT r.*,DATE_FORMAT(r.created_at,'%Y-%m-%d %H:%i:%s') AS created_utc FROM activity_results r JOIN activity_delivery d ON d.result_id=r.id WHERE d.processed=0 ORDER BY r.created_at,r.id LIMIT ?",{limit or 50})
end)
exports('Acknowledge',function(id,revoked) MX.db('UPDATE activity_delivery d JOIN activity_results r ON r.id=d.result_id SET d.processed=1 WHERE r.id=? AND r.revoked=?',{id,revoked}) end)
exports('Result',function(id) return MX.db('SELECT * FROM activity_results WHERE id=?',{id})[1] end)
exports('History',function(player) return MX.db('SELECT id,mode,duration_ms,eligible,revoked,reason,track_id FROM activity_results WHERE player_id=? ORDER BY created_at DESC LIMIT 20',{player}) end)
exports('Stats',function(player) return MX.db("SELECT mode,COUNT(*) AS completed,COALESCE(SUM(distance_m),0) AS distance FROM activity_results WHERE player_id=? AND revoked=0 AND JSON_UNQUOTE(JSON_EXTRACT(evidence,'$.state'))='completed' GROUP BY mode",{player}) end)
exports('Revoke',function(id,reason)
    MX.require(MX.text(id,36,36) and MX.text(reason,1,120),'RESULT')
    local row=MX.db('SELECT * FROM activity_results WHERE id=?',{id})[1] MX.require(row,'NOT_FOUND')
    MX.tx({{query='UPDATE activity_results SET revoked=1,reason=? WHERE id=? AND revoked=0',values={reason,id}}, {query='UPDATE activity_delivery SET processed=0 WHERE result_id=?',values={id}}})
    TriggerEvent('mx:activities:revoked',id) return row
end)
CreateThread(function()
    while not exports['mx-freeroam-core']:IsReady() do Wait(500) end
    local ok,err=pcall(function()
        for id,t in pairs(ActivityConfig.tracks) do
            ActivityRules.track(t) MX.require(t.id==id,'TRACK')
            local rows=MX.db('SELECT definition FROM track_versions WHERE track_id=? AND revision=?',{id,t.revision})
            local definition=MX.canonical(t)
            if #rows>0 then MX.require(MX.canonical(json.decode(rows[1].definition))==definition,'TRACK_REVISION','Definição mudou sem nova revisão')
            else MX.db('INSERT INTO track_versions(track_id,revision,definition,active) VALUES (?,?,?,?)',{id,t.revision,json.encode(t),t.activated and t.validated}) end
        end
        for _,row in ipairs(MX.db('SELECT definition FROM track_versions WHERE active=1')) do
            local definition=ActivityRules.track(json.decode(row.definition))
            MX.require(definition.validated and definition.activated,'TRACK')
            ActivityConfig.tracks[definition.id]=definition
        end
        ready=true
    end)
    print(json.encode({domain='activities',ready=ready,code=not ok and (type(err)=='table' and err.code or 'DATABASE') or 'OK'}))
    if not ok then return end
    while true do
        Wait(ActivityConfig.sampleMs) local now=GetGameTimer()
        for src,s in pairs(sessions) do
            if s.state=='active' then
                local car=exports['mx-freeroam-vehicles']:Active(src)
                local reason
                if not MX.actor(src) or MX.actor(src).epoch~=s.epoch then reason='identity_changed'
                elseif not car or car.id~=s.vehicle or not DoesEntityExist(s.entity) then reason='vehicle_changed'
                elseif GetEntityHealth(GetPlayerPed(src))<=0 then reason='death'
                elseif car.model~=s.model or car.signature~=s.signature then reason='configuration_changed'
                elseif GetPedInVehicleSeat(s.entity,-1)~=GetPlayerPed(src) then reason='driver_changed'
                elseif GetPlayerRoutingBucket(src)~=s.bucket then reason='bucket_changed'
                elseif exports['mx-freeroam-world']:Conditions()~=s.conditions then reason='conditions_changed'
                elseif now-s.lastAt>ActivityConfig.maxGap or GetPlayerPing(src)>500 or (now-s.start>4000 and (not s.observationAt or now-s.observationAt>4000)) then reason='insufficient_sync'
                elseif now-s.start>ActivityConfig.maxDuration then reason='timeout' end
                if reason then finish(src,s,'invalid',reason)
                else
                    local p=GetEntityCoords(s.entity) local current={x=p.x,y=p.y,z=p.z} local distance=MX.distance(s.previous,current)
                    if distance/((now-s.lastAt)/1000)>ActivityConfig.maxSpeed then finish(src,s,'invalid','position_jump')
                    else
                        s.distance=s.distance+distance
                        local checkpoint=s.track.checkpoints[s.next]
                        local crossed=checkpoint and ActivityRules.crossed(s.previous,current,checkpoint,s.track.checkpoints[s.next-1],s.track.checkpointRadius)
                        if not crossed then
                            for future=s.next+1,#s.track.checkpoints do
                                if ActivityRules.crossed(s.previous,current,s.track.checkpoints[future],s.track.checkpoints[future-1],s.track.checkpointRadius) then finish(src,s,'invalid','checkpoint_out_of_order') break end
                            end
                        end
                        if sessions[src]==s and crossed then
                            s.evidence[#s.evidence+1]={checkpoint=s.next,ms=now-s.start} s.next=s.next+1
                            for _,split in ipairs(s.bestSplits or {}) do if split.checkpoint==s.next-1 then s.deltaMs=now-s.start-split.ms break end end
                            if s.next>#s.track.checkpoints then finish(src,s,'completed') end
                        end
                        s.previous=current s.lastAt=now if sessions[src]==s then state(src,s) end
                    end
                end
            end
        end
    end
end)
CreateThread(function()
    while true do Wait(5000) for id,row in pairs(spool) do local ok=pcall(persist,row) if ok then spool[id]=nil pcall(saveSpool) end end end
end)
CreateThread(function()
    while true do
        Wait(3600000)
        pcall(function()
            -- Preserva referências/ledger e razões. Limpa somente a telemetria e evidências extensas após retenção.
            MX.db("UPDATE activity_results SET evidence=JSON_REMOVE(evidence,'$.telemetry') WHERE created_at < UTC_TIMESTAMP() - INTERVAL ? DAY",{ActivityConfig.telemetryRetentionDays})
            MX.db("UPDATE activity_results SET evidence=JSON_REMOVE(evidence,'$.checkpoints') WHERE eligible=0 AND created_at < UTC_TIMESTAMP() - INTERVAL ? DAY",{ActivityConfig.invalidRetentionDays})
        end)
    end
end)
AddEventHandler('mx:profile:dropped',function(src) invalidate(src,'disconnect') end)
AddEventHandler('onResourceStop',function(name)
    if name==resource then for src,s in pairs(sessions) do finish(src,s,'invalid','resource_restart') end pcall(saveSpool) end
    if name=='mx-freeroam-vehicles' or name=='mx-freeroam-world' then for src in pairs(sessions) do invalidate(src,'dependency_restart') end end
end)
