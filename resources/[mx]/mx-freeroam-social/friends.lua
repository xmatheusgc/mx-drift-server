-- Friend identity is a persistent player ID, never a reusable connection source.
local function pair(player,target)
    MX.require(MX.number(target,1,9007199254740991,true) and target~=player,'FRIEND','Jogador inválido')
    return math.min(player,target),math.max(player,target)
end
local function row(player,target)
    local low,high=pair(player,target)
    return MX.db('SELECT * FROM player_friendships WHERE low_player_id=? AND high_player_id=?',{low,high})[1],low,high
end
local function online()
    local rows={}
    for _,source in ipairs(GetPlayers()) do local p=MX.actor(tonumber(source)) if p then rows[p.id]={id=p.id,name=p.name,source=tonumber(source)} end end
    return rows
end
local function list(player)
    local connected=online() local friends,incoming,outgoing,players={},{},{},{} local relations={}
    local rows=MX.db('SELECT f.*,a.name low_name,b.name high_name FROM player_friendships f JOIN players a ON a.id=f.low_player_id JOIN players b ON b.id=f.high_player_id WHERE f.low_player_id=? OR f.high_player_id=? ORDER BY f.created_at DESC LIMIT 200',{player,player})
    for _,r in ipairs(rows) do
        local id=r.low_player_id==player and r.high_player_id or r.low_player_id
        local item={id=id,name=r.low_player_id==player and r.high_name or r.low_name,online=connected[id]~=nil}
        relations[id]=r.status=='accepted' and 'friend' or r.requested_by==player and 'outgoing' or 'incoming'
        local target=r.status=='accepted' and friends or r.requested_by==player and outgoing or incoming target[#target+1]=item
    end
    for id,p in pairs(connected) do if id~=player then players[#players+1]={id=id,name=p.name,relation=relations[id]} end end
    table.sort(players,function(a,b) return a.name:lower()<b.name:lower() end)
    return {online=players,friends=friends,incoming=incoming,outgoing=outgoing}
end
local function send(src,d,actor)
    local existing,low,high=row(actor.id,d.target)
    if existing then MX.require(existing.status=='pending' and existing.requested_by==actor.id,'FRIEND','Amizade ou solicitação já existente') return {status='pending'} end
    local target
    for _,source in ipairs(GetPlayers()) do local p=MX.actor(tonumber(source)) if p and p.id==d.target then target=p break end end
    MX.require(target and target.preferences.invites~='none','FRIEND','Jogador offline ou não aceita solicitações')
    MX.require(MX.db('SELECT COUNT(*) n FROM player_friendships WHERE low_player_id=? OR high_player_id=?',{actor.id,actor.id})[1].n<100,'LIMIT','Limite de amizades/solicitações atingido')
    MX.require(MX.db('SELECT COUNT(*) n FROM player_friendships WHERE low_player_id=? OR high_player_id=?',{d.target,d.target})[1].n<100,'LIMIT')
    MX.db('INSERT IGNORE INTO player_friendships(low_player_id,high_player_id,requested_by) VALUES (?,?,?)',{low,high,actor.id})
    local saved=row(actor.id,d.target) MX.require(saved and saved.requested_by==actor.id,'FRIEND','Já existe uma solicitação recebida; abra Solicitações')
    return {status=saved.status}
end
local function respond(_,d,actor)
    MX.require(type(d.accept)=='boolean','FRIEND')
    local existing,low,high=row(actor.id,d.target)
    MX.require(existing and existing.requested_by~=actor.id,'FRIEND','Solicitação recebida não encontrada')
    if existing.status=='accepted' then MX.require(d.accept,'FRIEND') return {status='accepted'} end
    if d.accept then MX.db("UPDATE player_friendships SET status='accepted',accepted_at=CURRENT_TIMESTAMP(3) WHERE low_player_id=? AND high_player_id=? AND status='pending' AND requested_by=?",{low,high,d.target})
    else MX.db("DELETE FROM player_friendships WHERE low_player_id=? AND high_player_id=? AND status='pending' AND requested_by=?",{low,high,d.target}) end
    local saved=row(actor.id,d.target)
    MX.require(d.accept and saved and saved.status=='accepted' or not d.accept and not saved,'CONFLICT','Solicitação mudou; atualize a lista')
    return {status=d.accept and 'accepted' or 'declined'}
end
FriendRoutes={state=function(_,_,actor) return list(actor.id) end,send=send,respond=respond}
-- Internal exports used by isolated SQL verification, not network events.
exports('FriendState',list) exports('FriendSend',send) exports('FriendRespond',respond)
