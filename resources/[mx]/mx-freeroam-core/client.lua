local pending,seq={},0
local boot=tostring(GetGameTimer())..'-'..math.random(10000,99999)
exports('Request',function(domain,action,data)
    if GetResourceState('mx-freeroam-'..domain)~='started' then return {ok=false,code='UNAVAILABLE',message='Módulo indisponível: '..domain} end
    seq=seq+1 local id=boot..'-'..seq local p=promise.new()
    pending[id]=p TriggerServerEvent('mx:'..domain..':request',id,action,data)
    SetTimeout(CoreConfig.requestTimeout,function() if pending[id] then pending[id]=nil p:resolve({ok=false,code='TIMEOUT',message='Sem confirmação; recarregue antes de repetir uma gravação'}) end end)
    return Citizen.Await(p)
end)
RegisterNetEvent('mx:response',function(id,result)
    if source==65535 and pending[id] then local p=pending[id] pending[id]=nil p:resolve(result) end
end)
RegisterNetEvent('mx:profile',function(profile)
    if source~=65535 then return end
    LocalPlayer.state:set('mxReady',true,false)
    TriggerEvent('mx:profile:local',profile)
end)
CreateThread(function() while not NetworkIsSessionStarted() do Wait(200) end TriggerServerEvent('mx:core:ready') end)
AddEventHandler('onClientResourceStart',function(name) if name==GetCurrentResourceName() then SetNuiFocus(false,false) end end)
