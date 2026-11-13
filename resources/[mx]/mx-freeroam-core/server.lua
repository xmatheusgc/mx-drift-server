local profiles, rates, locks, pending, activeIdentifiers = {},{},{},{},{}
local ready=false
assert(GetConvar('mx_migrations','check')=='check','MX: migrations só são aplicadas offline pelo script migrate')
local boot=('%x-%x'):format(os.time(),math.random(1,0x7fffffff))
local sequence=0
local function token() sequence=sequence+1 return boot..'-'..sequence end
local function query(sql,args)
    MX.require(ready,'DATABASE','Banco/migrations indisponíveis')
    local ok,result=pcall(MySQL.query.await,sql,args or {})
    MX.require(ok,'DATABASE','Banco indisponível; operação não confirmada') return result
end
exports('Query',query)
exports('IsReady',function() return ready end)
exports('BootId',function() return boot end)
exports('Transaction',function(queries)
    MX.require(ready,'DATABASE')
    local ok,result=pcall(MySQL.transaction.await,queries)
    MX.require(ok and result,'DATABASE','Transação não confirmada') return true
end)
exports('Profile',function(src) return profiles[tonumber(src)] and MX.copy(profiles[tonumber(src)]) end)
exports('Profiles',function() return MX.copy(profiles) end)
exports('Guard',function(src,action)
    local now=GetGameTimer()
    rates[src]=rates[src] or {at=now,n=0,actions={}}
    local r=rates[src]
    if now-r.at>CoreConfig.requestWindow then r.at=now r.n=0 end
    r.n=r.n+1
    if r.n>CoreConfig.requestLimit or now-(r.actions[action] or -10000)<150 then return false end
    r.actions[action]=now return true
end)
exports('Run',function(src,epoch,fn)
    return MX.capture(function()
        MX.require(profiles[src] and profiles[src].epoch==epoch,'SESSION')
        MX.require(not locks[src],'BUSY','Outra operação está em andamento')
        locks[src]=epoch
        local ok,result=pcall(fn)
        if locks[src]==epoch then locks[src]=nil end
        if not ok then error(result,0) end return result
    end)
end)
exports('ClientCall',function(src,domain,action,data)
    return MX.capture(function()
        local profile=profiles[src]
        MX.require(profile,'SESSION')
        local id=token() local p=promise.new()
        pending[id]={src=src,epoch=profile.epoch,p=p}
        TriggerClientEvent('mx:'..domain..':client',src,id,action,data)
        local timeout=CoreConfig.clientTimeouts[domain..':'..action] or CoreConfig.clientTimeout
        SetTimeout(timeout,function() if pending[id] then pending[id]=nil p:resolve({ok=false}) end end)
        local result=Citizen.Await(p)
        MX.require(profiles[src] and profiles[src].epoch==profile.epoch,'SESSION')
        -- A failure payload only rejects this player's operation; it never
        -- grants authority or confirms a mutation. Keep raw stack traces local.
        local failure=not result.ok and result.received and result.data and result.data.failure
        if type(failure)=='table' and MX.text(failure.code,1,48) and failure.code:match('^[A-Z][A-Z0-9_]*$') and MX.text(failure.message,1,512) then
            MX.fail(failure.code,failure.message)
        end
        MX.require(result.ok,result.received and 'CLIENT_ERROR' or 'CLIENT_TIMEOUT',result.received and ('O cliente falhou em '..domain..'/'..action..'. Consulte o erro no console F8.') or ('Sem resposta do cliente em '..domain..'/'..action)) return result.data
    end)
end)
RegisterNetEvent('mx:core:ack',function(id,ok,data)
    if type(id)~='string' then return end
    local item=pending[id]
    if item and item.src==source and profiles[source] and profiles[source].epoch==item.epoch and type(data)=='table' and #json.encode(data)<16384 then
        pending[id]=nil item.p:resolve({ok=ok==true,received=true,data=data})
    end
end)
local defaults={transmission='automatic',hud=true,minimap=true,units='kmh',scale=1,volume=0.3,blips='all',uniform=false,share=true,invites='all',appearance='driver',outfit=0,photo=false,muted={}}
local function validatePrefs(p)
    MX.require(MX.keys(p,{transmission=true,hud=true,minimap=true,units=true,scale=true,volume=true,blips=true,uniform=true,share=true,invites=true,appearance=true,outfit=true,photo=true,muted=true}),'PREFERENCES')
    if p.transmission==nil then p.transmission='automatic' end
    MX.require(p.transmission=='automatic' or p.transmission=='manual','PREFERENCES')
    if p.minimap==nil then p.minimap=true end -- Existing saved profiles/clients.
    MX.require(type(p.minimap)=='boolean','PREFERENCES')
    MX.require(type(p.hud)=='boolean' and type(p.share)=='boolean' and type(p.uniform)=='boolean' and type(p.photo)=='boolean','PREFERENCES')
    MX.require(p.units=='kmh' or p.units=='mph','PREFERENCES')
    MX.require(p.blips=='all' or p.blips=='group' or p.blips=='none','PREFERENCES')
    MX.require(p.invites=='all' or p.invites=='none','PREFERENCES')
    MX.require(MX.number(p.scale,0.75,1.5) and MX.number(p.volume,0,1),'PREFERENCES')
    MX.require(p.appearance=='driver' or p.appearance=='driver_f','PREFERENCES')
    MX.require(MX.number(p.outfit,0,2,true),'PREFERENCES')
    MX.require(type(p.muted)=='table' and #p.muted<=20,'PREFERENCES')
    for _,v in ipairs(p.muted) do MX.require(MX.number(v,1,65535,true),'PREFERENCES') end
    return p
end
MX.routes('core',{
    profile=function(_,_,actor) return actor end,
    disconnect=function(src) DropPlayer(src,'Você saiu do servidor.') return {} end,
    preferences=function(src,d,actor)
        MX.require(d.revision==actor.revision,'CONFLICT','Preferências foram alteradas; recarregue')
        local prefs=validatePrefs(d.preferences)
        local result=query('UPDATE player_preferences SET document=?,revision=revision+1 WHERE player_id=? AND revision=?',{json.encode(prefs),actor.id,d.revision})
        MX.require(result.affectedRows==1,'CONFLICT')
        profiles[src].preferences=prefs profiles[src].revision=actor.revision+1
        TriggerEvent('mx:profile:changed',src)
        TriggerClientEvent('mx:profile',src,profiles[src]) return profiles[src]
    end
})
AddEventHandler('playerConnecting',function(_,_,deferrals)
    local src=source deferrals.defer() Wait(0)
    if not ready then deferrals.done('MX: banco/migrations indisponíveis. Tente novamente após diagnóstico.') return end
    local identifier=GetPlayerIdentifierByType(src,'license')
    if not identifier then deferrals.done('MX: licença da plataforma não disponível.') return end
    local checked,denial=pcall(function()
        MX.require(MX.online('mx-freeroam-admin'),'UNAVAILABLE','Moderação indisponível')
        return exports['mx-freeroam-admin']:CheckConnection(identifier)
    end)
    if not checked or denial then deferrals.done(checked and denial or 'MX: verificação de acesso indisponível; tente novamente.') return end
    if activeIdentifiers[identifier] then deferrals.done('MX: já existe uma sessão para esta identidade.') return end
    activeIdentifiers[identifier]=src
    local ok,result=pcall(function()
        local name=MX.name(GetPlayerName(src)) if name=='' then name='Piloto' end
        local inserted=query('INSERT INTO players(identifier,name) VALUES (?,?) ON DUPLICATE KEY UPDATE last_seen=CURRENT_TIMESTAMP(3)',{identifier,name})
        local player=query('SELECT id,name,created_at FROM players WHERE identifier=?',{identifier})[1]
        query('INSERT IGNORE INTO player_preferences(player_id,document) VALUES (?,?)',{player.id,json.encode(defaults)})
        local pref=query('SELECT document,revision FROM player_preferences WHERE player_id=?',{player.id})[1]
        profiles[src]={id=player.id,name=player.name,created=player.created_at,firstJoin=inserted.affectedRows==1,preferences=json.decode(pref.document),revision=pref.revision,epoch=token()}
        if profiles[src].preferences.transmission==nil then profiles[src].preferences.transmission='automatic' end
        if profiles[src].preferences.minimap==nil then profiles[src].preferences.minimap=true end
    end)
    if not ok then activeIdentifiers[identifier]=nil profiles[src]=nil deferrals.done('MX: falha ao carregar perfil; dados existentes preservados.') else deferrals.done() end
end)
-- Source muda entre connecting e joining: transferir pela identidade única.
AddEventHandler('playerJoining',function(oldId)
    local src=source local old=tonumber(oldId)
    if old and old~=src and profiles[old] then profiles[src]=profiles[old] profiles[old]=nil end
    local identifier=GetPlayerIdentifierByType(src,'license') if identifier then activeIdentifiers[identifier]=src end
end)
RegisterNetEvent('mx:core:ready',function()
    local src=source
    if profiles[src] and exports['mx-freeroam-core']:Guard(src,'ready') then TriggerClientEvent('mx:profile',src,profiles[src]) end
end)
AddEventHandler('playerDropped',function()
    local src=source
    TriggerEvent('mx:profile:dropped',src,profiles[src] and profiles[src].id)
    for id,s in pairs(activeIdentifiers) do if s==src then activeIdentifiers[id]=nil end end
    for id,item in pairs(pending) do if item.src==src then pending[id]=nil item.p:resolve({ok=false}) end end
    profiles[src]=nil rates[src]=nil locks[src]=nil
end)
MySQL.ready(function()
    local ok,result=pcall(MySQL.query.await,'SELECT version FROM schema_migrations WHERE version=?',{CoreConfig.schema})
    ready=ok and result and #result==1
    print(json.encode({domain='core',ready=ready,schema=CoreConfig.schema,message=ready and 'Banco pronto' or 'Execute npm run migrate; acesso fechado'}))
end)
AddEventHandler('onResourceStop',function(name)
    if name==GetCurrentResourceName() then for src in pairs(profiles) do DropPlayer(src,'MX core reiniciado; reconecte para carregar a sessão segura.') end end
end)
