-- Read-only local telemetry; administrative movement belongs to world.
AdminTools={watchers={}}
local T=AdminTools
T.editors={}
RegisterNetEvent('mx:admin:cameraEditorClosed',function()T.editors[source]=nil end)
function T.editor(src,d)
    MX.require(type(d.enabled)=='boolean','PAYLOAD')
    if not d.enabled then T.editors[src]=nil MX.callClient(src,'experience','developerCamera',{enabled=false})return {enabled=false}end
    AdminModeration.authorize(src,'inspect') local actor=MX.actor(src) MX.require(actor,'SESSION')
    local result=MX.callClient(src,'experience','developerCamera',{enabled=true})
    AdminModeration.authorize(src,'inspect') MX.require(MX.actor(src)and MX.actor(src).epoch==actor.epoch,'SESSION')
    MX.require(result.enabled==true,'CAMERA','Editor não confirmado') T.editors[src]={epoch=actor.epoch}return result
end
local targets={ped=true,vehicle=true,camera=true}
function T.check(src,permission)
    AdminModeration.authorize(src,permission)
    local actor=MX.actor(src)
    MX.require(actor and GetPlayerRoutingBucket(src)==0,'SESSION','Ferramenta disponível no modo livre')
    MX.require(not MX.online('mx-freeroam-experience') or not exports['mx-freeroam-experience']:IsPrivate(src),'SESSION','Saia da oficina antes de usar esta ferramenta')
    return actor
end
function T.target(value) MX.require(targets[value],'PAYLOAD','Escolha personagem, veículo ou câmera') return value end
function T.snapshot(src,d)
    local actor=T.check(src,'inspect') local target=T.target(d.target)
    local result=MX.callClient(src,'admin','snapshot',{target=target})
    local current=T.check(src,'inspect') MX.require(current.epoch==actor.epoch,'SESSION')
    return result
end
function T.overlay(src,d)
    MX.require(type(d.enabled)=='boolean','PAYLOAD')
    if not d.enabled then
        T.watchers[src]=nil
        MX.callClient(src,'admin','tools',{enabled=false}) return {enabled=false,target=d.target or 'ped'}
    end
    local actor=T.check(src,'inspect') local target=T.target(d.target)
    local result=MX.callClient(src,'admin','tools',{enabled=true,target=target})
    local current=T.check(src,'inspect') MX.require(current.epoch==actor.epoch,'SESSION')
    MX.require(result.enabled==true,'ACK','Painel não confirmado')
    T.watchers[src]={epoch=actor.epoch,target=target}
    return {enabled=true,target=target}
end
function T.refresh()
    for src,s in pairs(T.editors)do
        local actor=MX.actor(src)
        if actor and actor.epoch==s.epoch and AdminModeration.allowed(src,'inspect')then TriggerClientEvent('mx:experience:cameraDeveloperGrant',src,true)
        else T.editors[src]=nil TriggerClientEvent('mx:experience:cameraDeveloperGrant',src,false)end
    end
    for src,s in pairs(T.watchers) do
        local ok,actor=pcall(T.check,src,'inspect')
        if ok and actor.epoch==s.epoch then TriggerClientEvent('mx:admin:toolsGrant',src,true)
        else T.watchers[src]=nil TriggerClientEvent('mx:admin:toolsGrant',src,false) end
    end
end
AddEventHandler('mx:profile:dropped',function(src) T.watchers[src]=nil T.editors[src]=nil end)
CreateThread(function() while true do Wait(2000) T.refresh() end end)
