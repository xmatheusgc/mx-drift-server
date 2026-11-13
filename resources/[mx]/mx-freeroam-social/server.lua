local groups,membership,invites,lastInvite,positions,announcements={},{},{},{},{},{}
local serial=0 local function id() serial=serial+1 return tostring(os.time())..'-'..serial end
local function groupOf(src) return membership[src] and groups[membership[src]] end
local function leave(src)
    local group=groupOf(src) membership[src]=nil
    if not group then return end
    for i,s in ipairs(group.members) do if s==src then table.remove(group.members,i) break end end
    if #group.members==0 then groups[group.id]=nil elseif group.leader==src then group.leader=group.members[1] end
end
local function contact(src)
    local p=MX.actor(src) if not p then return end
    return {source=src,bucket=GetPlayerRoutingBucket(src),invites=p.preferences.invites,group=membership[src],blips=p.preferences.blips,share=p.preferences.share}
end
local function progression(actor)
    if MX.online('mx-freeroam-progression') then local ok,p=pcall(function() return exports['mx-freeroam-progression']:Public(actor.id) end) if ok then return p end end
    return {level=1,sprite=1,color=0}
end
local function subject(src,p)
    local ped=GetPlayerPed(src) if ped==0 or not DoesEntityExist(ped) then return end
    local point=GetEntityCoords(ped) local sample=positions[src]
    if not sample or MX.distance(sample.position,point)>1 then positions[src]={position={x=point.x,y=point.y,z=point.z},moved=GetGameTimer()} sample=positions[src] end
    local activity=MX.online('mx-freeroam-activities') and exports['mx-freeroam-activities']:State(src) or nil
    local public=progression(p)
    local region='Mundo' for _,d in pairs(exports['mx-freeroam-world']:Destinations()) do if MX.distance(point,d.slots[1])<d.radius then region=d.name break end end
    return {source=src,session=p.epoch,name=p.name,level=public.level,sprite=public.sprite,color=public.color,position={x=point.x,y=point.y,z=point.z},state=GetGameTimer()-sample.moved>SocialConfig.afkAfter and 'AFK' or (activity and 'Em atividade' or 'Livre'),region=region,bucket=GetPlayerRoutingBucket(src),share=p.preferences.share,group=membership[src]}
end
local function players(src,locationsOnly)
    local observer=contact(src) if not observer then return {} end
    local rows={}
    for _,s in ipairs(GetPlayers()) do
        local other=tonumber(s) local p=MX.actor(other)
        if p and other~=src then
            local row=subject(other,p)
            if row and row.bucket==observer.bucket then
                local visible=SocialRules.visible(observer,row)
                if not locationsOnly or visible then
                    row.position=visible and row.position or nil
                    row.region=visible and row.region or nil
                    row.color=membership[src] and membership[src]==row.group and 2 or (row.state=='Em atividade' and 5 or row.color)
                    row.group=membership[src]~=nil and membership[src]==row.group
                    row.bucket=nil row.share=nil
                    rows[#rows+1]=row
                end
            end
        end
    end return rows
end
local function announce(src,destination)
    local d=exports['mx-freeroam-world']:Destinations()[destination]
    MX.require(d,'DESTINATION')
    local actor=MX.actor(src) announcements[#announcements+1]={id=id(),name=actor and actor.name or 'Administração',destination=destination,expires=GetGameTimer()+SocialConfig.announceLifetime}
    TriggerClientEvent('mx:notify',-1,'Encontro anunciado em '..d.name) return {}
end
exports('Announce',announce)
exports('Group',function(src) return membership[src] end)
MX.routes('social',{
    friends=FriendRoutes.state,friendSend=FriendRoutes.send,friendRespond=FriendRoutes.respond,
    players=function(src) return players(src,false) end,
    state=function(src)
        local received={}
        for _,v in pairs(invites) do if v.target==src and v.expires>GetGameTimer() then local copy=MX.copy(v) copy.remaining=math.ceil((v.expires-GetGameTimer())/1000) copy.expires=nil received[#received+1]=copy end end
        local meets={} local all=exports['mx-freeroam-world']:Destinations()
        for _,d in pairs(all) do local n=0 for _,s in ipairs(GetPlayers()) do local actor=MX.actor(tonumber(s)) if actor and (actor.preferences.share or tonumber(s)==src) and GetPlayerRoutingBucket(s)==GetPlayerRoutingBucket(src) and MX.distance(GetEntityCoords(GetPlayerPed(s)),d.slots[1])<d.radius then n=n+1 end end meets[#meets+1]={id=d.id,name=d.name,count=n} end
        return {group=groupOf(src),invites=received,meets=meets,announcements=announcements,voice=MX.online('pma-voice')}
    end,
    invite=function(src,d,actor)
        MX.require(MX.number(d.target,1,65535,true) and (d.kind=='group' or d.kind=='duel'),'INVITE')
        local sender,target=contact(src),contact(d.target)
        MX.require(target and SocialRules.canInvite(sender,target,d.kind),'CONTACT','Jogador não aceita convites neste mundo')
        MX.require(GetGameTimer()-(lastInvite[src] or -10000)>SocialConfig.inviteCooldown,'COOLDOWN')
        local group=groupOf(src) if d.kind=='group' then MX.require(not group or (group.leader==src and #group.members<SocialConfig.groupLimit),'GROUP') MX.require(not membership[d.target],'GROUP','Jogador já está em grupo') end
        local rules
        if d.kind=='duel' then MX.require(MX.online('mx-freeroam-activities'),'UNAVAILABLE') rules=exports['mx-freeroam-activities']:DescribeDuel(src,d.target,d.track) end
        local key=id() invites[key]={id=key,from=src,fromEpoch=actor.epoch,fromName=actor.name,target=d.target,targetEpoch=MX.actor(d.target).epoch,kind=d.kind,track=d.track,rules=rules,expires=GetGameTimer()+SocialConfig.inviteLifetime}
        lastInvite[src]=GetGameTimer() TriggerClientEvent('mx:notify',d.target,actor.name..' enviou convite de '..d.kind..'. F1 > Social para responder.') return {id=key}
    end,
    respond=function(src,d,actor)
        MX.require(type(d.id)=='string' and type(d.accept)=='boolean','INVITE')
        local v=invites[d.id] MX.require(SocialRules.inviteValid(v,src,GetGameTimer()) and v.targetEpoch==actor.epoch,'INVITE','Convite expirado')
        invites[d.id]=nil
        if not d.accept then return {} end
        local from=MX.actor(v.from)
        MX.require(from and from.epoch==v.fromEpoch and SocialRules.canInvite(contact(v.from),contact(src),v.kind),'INVITE')
        if v.kind=='duel' then MX.require(MX.online('mx-freeroam-activities'),'UNAVAILABLE') return exports['mx-freeroam-activities']:StartDuel(v.from,src,v.track,v.rules) end
        MX.require(not membership[src],'GROUP') local group=groupOf(v.from)
        MX.require(not group or (group.leader==v.from and #group.members<SocialConfig.groupLimit),'GROUP')
        if not group then local key=id() group={id=key,leader=v.from,members={v.from}} groups[key]=group membership[v.from]=key end
        group.members[#group.members+1]=src membership[src]=group.id return group
    end,
    leave=function(src) leave(src) return {} end,
    chat=function(src,d,actor)
        MX.require(MX.text(d.message,1,250),'CHAT','Mensagem inválida (até 250 caracteres)')
        MX.require(exports['mx-freeroam-core']:Guard(src,'chat-send'),'RATE')
        for _,s in ipairs(GetPlayers()) do if GetPlayerRoutingBucket(s)==GetPlayerRoutingBucket(src) then TriggerClientEvent('mx:social:chat',tonumber(s),{source=src,name=actor.name,message=d.message}) end end return {}
    end
})
CreateThread(function()
    while true do
        Wait(SocialConfig.interval)
        for _,s in ipairs(GetPlayers()) do TriggerClientEvent('mx:social:presence',tonumber(s),players(tonumber(s),true)) end
        for key,v in pairs(invites) do if v.expires<GetGameTimer() then invites[key]=nil end end
        for i=#announcements,1,-1 do if announcements[i].expires<GetGameTimer() then table.remove(announcements,i) end end
    end
end)
AddEventHandler('mx:profile:changed',function() for _,s in ipairs(GetPlayers()) do TriggerClientEvent('mx:social:presence',tonumber(s),players(tonumber(s),true)) end end)
AddEventHandler('mx:profile:dropped',function(src)
    leave(src) positions[src]=nil lastInvite[src]=nil
    for key,v in pairs(invites) do if v.from==src or v.target==src then invites[key]=nil end end
    TriggerClientEvent('mx:social:remove',-1,src)
end)
AddEventHandler('onResourceStop',function(name) if name==GetCurrentResourceName() then TriggerClientEvent('mx:social:reset',-1) end end)
