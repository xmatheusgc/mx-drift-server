local blips,muted={},{}
local uniform=false
local function remove(src) if blips[src] then RemoveBlip(blips[src].handle) blips[src]=nil end end
local function reset() for src in pairs(blips) do remove(src) end end
AddEventHandler('mx:profile:local',function(p) uniform=p.preferences.uniform end)
RegisterNetEvent('mx:social:presence',function(rows)
    if source~=65535 then return end local seen={}
    for _,p in ipairs(rows) do
        if p.source~=GetPlayerServerId(PlayerId()) and p.position then
            local current=blips[p.source]
            if current and current.session~=p.session then remove(p.source) current=nil end
            if not current then current={handle=AddBlipForCoord(p.position.x,p.position.y,p.position.z),session=p.session} blips[p.source]=current end
            seen[p.source]=true current.at=GetGameTimer()
            SetBlipCoords(current.handle,p.position.x,p.position.y,p.position.z) SetBlipSprite(current.handle,uniform and 1 or p.sprite) SetBlipColour(current.handle,p.color)
            SetBlipScale(current.handle,0.75) SetBlipAsShortRange(current.handle,false)
            BeginTextCommandSetBlipName('STRING') AddTextComponentSubstringPlayerName(p.name..' · Nv '..p.level..' · '..p.state) EndTextCommandSetBlipName(current.handle)
        end
    end
    for src in pairs(blips) do if not seen[src] then remove(src) end end
end)
RegisterNetEvent('mx:social:remove',function(src) if source==65535 then remove(src) end end)
RegisterNetEvent('mx:social:reset',function() if source==65535 then reset() end end)
AddEventHandler('mx:chat:mute',function(src,value) muted[src]=value end)
RegisterNetEvent('mx:social:chat',function(d) if source==65535 and not muted[d.source] then TriggerEvent('mx:notice',d.name..': '..d.message) end end)
RegisterCommand('mxchat',function(_,args) CreateThread(function() local result=MX.request('social','chat',{message=table.concat(args,' ')}) if not result.ok then TriggerEvent('mx:notice',result.message) end end) end,false)
CreateThread(function() while true do Wait(1000) for src,b in pairs(blips) do if GetGameTimer()-b.at>SocialConfig.expiry then remove(src) end end end end)
AddEventHandler('onClientResourceStop',function(name) if name==GetCurrentResourceName() then reset() end end)
