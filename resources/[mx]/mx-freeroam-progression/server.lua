local processing=false
local cache={}
local function summary(player)
    local row=MX.db('SELECT COALESCE(SUM(delta),0) AS xp FROM xp_ledger WHERE player_id=?',{player})[1]
    local xp=tonumber(row.xp) or 0
    local selected=MX.db('SELECT selected_icon,selected_title FROM player_progression WHERE player_id=?',{player})[1]
    return {xp=xp,level=ProgressionRules.level(math.max(0,xp)),icon=selected and selected.selected_icon or 'auto',title=selected and selected.selected_title or 'novato'}
end
local function reconcileQueries(player)
    return {
        {query='INSERT INTO player_progression(player_id,xp) SELECT ?,COALESCE(SUM(delta),0) FROM xp_ledger WHERE player_id=? ON DUPLICATE KEY UPDATE xp=VALUES(xp),revision=revision+1',values={player,player}},
        {query=[[INSERT INTO achievement_progress(player_id,achievement_id,version,progress,granted) SELECT ?,?,?,COUNT(*),IF(COUNT(*)>0,1,0) FROM xp_ledger g WHERE g.player_id=? AND g.delta>0 AND g.origin LIKE 'route:%' AND NOT EXISTS(SELECT 1 FROM xp_ledger c WHERE c.player_id=g.player_id AND c.origin=CONCAT('revoke:',g.id)) ON DUPLICATE KEY UPDATE progress=VALUES(progress),granted=VALUES(granted)]],values={player,ProgressionConfig.achievement.id,ProgressionConfig.achievement.version,player}}
    }
end
local function process(row)
    local queries={}
    if row.revoked==1 or row.revoked==true then
        queries[#queries+1]={query=[[INSERT IGNORE INTO xp_ledger(player_id,origin,result_id,delta,policy) SELECT player_id,CONCAT('revoke:',id),result_id,-delta,? FROM xp_ledger WHERE result_id=? AND delta>0]],values={ProgressionConfig.version,row.id}}
    elseif ProgressionRules.rewardable(row) then
        queries[#queries+1]={query='INSERT IGNORE INTO xp_ledger(player_id,origin,result_id,delta,policy) VALUES (?,?,?,?,?)',values={row.player_id,ProgressionRules.origin(row),row.id,ProgressionConfig.firstRouteXp,ProgressionConfig.version}}
        -- Período conferido no banco em UTC: nem o relógio do client nem timestamp tardio do worker autoriza prêmio vencido.
        local challenges=MX.db([[SELECT id,definition FROM weekly_challenges WHERE starts_at<=UTC_TIMESTAMP() AND ends_at>UTC_TIMESTAMP() AND starts_at<=? AND ends_at>?]],{row.created_utc,row.created_utc})
        for _,c in ipairs(challenges) do
            local definition=json.decode(c.definition)
            if definition.enabled and definition.track==row.track_id and definition.revision==row.track_revision and definition.condition=='complete' then
                queries[#queries+1]={query='INSERT IGNORE INTO challenge_claims(player_id,challenge_id,result_id) VALUES (?,?,?)',values={row.player_id,c.id,row.id}}
                queries[#queries+1]={query=[[INSERT IGNORE INTO xp_ledger(player_id,origin,result_id,delta,policy) SELECT player_id,CONCAT('weekly:',challenge_id),result_id,?,? FROM challenge_claims WHERE player_id=? AND challenge_id=? AND result_id=?]],values={definition.xp,ProgressionConfig.version,row.player_id,c.id,row.id}}
            end
        end
    end
    queries[#queries+1]={query='INSERT IGNORE INTO progression_receipts(result_id) VALUES (?)',values={row.id}}
    for _,q in ipairs(reconcileQueries(row.player_id)) do queries[#queries+1]=q end
    MX.tx(queries)
    cache[row.player_id]=nil
    exports['mx-freeroam-activities']:Acknowledge(row.id,row.revoked)
    TriggerEvent('mx:progression:changed',row.player_id)
end
local function drain()
    if processing or not MX.online('mx-freeroam-activities') then return end processing=true
    local ok=pcall(function() for _,row in ipairs(exports['mx-freeroam-activities']:Pending(50)) do process(row) end end)
    processing=false
    if not ok then print(json.encode({domain='progression',code='PENDING_RETRY',message='Entrega durável será reprocessada'})) end
end
exports('ValidateCosmetics',function(p)
    MX.require(p.icon=='auto' or ProgressionConfig.icons[p.icon],'ICON','Ícone fora do catálogo')
    MX.require(ProgressionConfig.titles[p.title],'TITLE')
end)
exports('AuthorizeCosmetics',function(player,p)
    MX.require((p.icon=='auto' or ProgressionConfig.icons[p.icon]) and ProgressionConfig.titles[p.title],'COSMETIC')
    local s=summary(player)
    MX.require(ProgressionRules.icon(p.icon,s.level),'LOCKED','Ícone não desbloqueado')
    local title=ProgressionConfig.titles[p.title]
    if title.achievement then local rows=MX.db('SELECT granted FROM achievement_progress WHERE player_id=? AND achievement_id=? AND version=?',{player,title.achievement,1}) MX.require(rows[1] and (rows[1].granted==1 or rows[1].granted==true),'LOCKED','Título não desbloqueado') end
end)
exports('Public',function(player)
    local s=cache[player]
    if not s or GetGameTimer()-s.at>10000 then s=summary(player) s.at=GetGameTimer() cache[player]=s end
    local icon=ProgressionRules.icon(s.icon,s.level) or ProgressionConfig.icons.driver
    return {level=s.level,sprite=icon.sprite,color=icon.color}
end)
exports('Reprocess',drain)
exports('Reconcile',function(player) MX.tx(reconcileQueries(player)) cache[player]=nil return summary(player) end)
MX.routes('progression',{
    cosmetics=function(_,d,actor)
        MX.require(MX.keys(d,{icon=true,title=true}) and MX.text(d.icon,1,32) and MX.text(d.title,1,32),'COSMETIC')
        exports['mx-freeroam-progression']:AuthorizeCosmetics(actor.id,d)
        MX.db('INSERT INTO player_progression(player_id,selected_icon,selected_title) VALUES (?,?,?) ON DUPLICATE KEY UPDATE selected_icon=VALUES(selected_icon),selected_title=VALUES(selected_title),revision=revision+1',{actor.id,d.icon,d.title})
        cache[actor.id]=nil TriggerEvent('mx:progression:changed',actor.id) return {icon=d.icon,title=d.title}
    end,
    profile=function(_,_,actor)
        local s=summary(actor.id)
        s.achievements=MX.db('SELECT achievement_id,version,progress,granted FROM achievement_progress WHERE player_id=?',{actor.id})
        s.weekly=MX.db("SELECT id,DATE_FORMAT(starts_at,'%Y-%m-%dT%H:%i:%s') AS starts_at,DATE_FORMAT(ends_at,'%Y-%m-%dT%H:%i:%s') AS ends_at FROM weekly_challenges WHERE starts_at<=UTC_TIMESTAMP() AND ends_at>UTC_TIMESTAMP() AND JSON_EXTRACT(definition,'$.enabled')=true")
        s.icons={} for id in pairs(ProgressionConfig.icons) do if ProgressionRules.icon(id,s.level) then s.icons[#s.icons+1]=id end end
        s.titles={}
        for id,title in pairs(ProgressionConfig.titles) do
            local unlocked=not title.achievement
            if title.achievement then for _,a in ipairs(s.achievements) do if a.achievement_id==title.achievement and a.version==1 and (a.granted==true or a.granted==1) then unlocked=true break end end end
            if unlocked then s.titles[#s.titles+1]=id end
        end table.sort(s.titles)
        s.stats={} s.history={}
        if MX.online('mx-freeroam-activities') then s.stats=exports['mx-freeroam-activities']:Stats(actor.id) s.history=exports['mx-freeroam-activities']:History(actor.id) end return s
    end
})
CreateThread(function()
    while not exports['mx-freeroam-core']:IsReady() do Wait(500) end
    local ok=pcall(function()
        local previous=-1 for _,xp in ipairs(ProgressionConfig.levels) do MX.require(MX.number(xp,0,10000000,true) and xp>previous,'LEVELS') previous=xp end
        for _,icon in pairs(ProgressionConfig.icons) do MX.require(MX.number(icon.sprite,1,800,true) and MX.number(icon.minLevel,1,#ProgressionConfig.levels,true),'ICON') end
        for _,w in ipairs(ProgressionConfig.weekly) do
            MX.require(w.starts<w.ends and MX.number(w.xp,0,1000,true) and w.condition=='complete','CHALLENGE')
            local existing=MX.db('SELECT definition FROM weekly_challenges WHERE id=?',{w.id})[1]
            if existing then MX.require(MX.canonical(json.decode(existing.definition))==MX.canonical(w),'CHALLENGE_REVISION')
            else MX.db('INSERT INTO weekly_challenges(id,starts_at,ends_at,definition) VALUES (?,?,?,?)',{w.id,w.starts,w.ends,json.encode(w)}) end
        end
    end)
    if not ok then print('[MX progression] Configuração/banco indisponível; processamento fechado') return end
    while true do drain() Wait(5000) end
end)
AddEventHandler('mx:activities:result',function() CreateThread(drain) end)
AddEventHandler('mx:activities:revoked',function() CreateThread(drain) end)
