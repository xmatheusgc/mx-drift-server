-- Only a server-created workshop departure can start this protection.
VehicleDepartureGhost={}
local G=VehicleDepartureGhost
local pending={}
local function owns(s)
    return DoesEntityExist(s.entity) and Entity(s.entity).state.mxVehicle==s.id
end
local function clear(key,s)
    if owns(s) then Entity(s.entity).state:set('mxDepartureGhost',nil,true) end
    pending[key]=nil
end
function G.start(v)
    pending[v.id]={id=v.id,entity=v.entity}
    Entity(v.entity).state:set('mxDepartureGhost',{id=v.id},true)
end
function G.arm(v)
    local s=pending[v.id]
    if s and owns(s) then s.started=GetGameTimer() s.clearAt=nil end
end
function G.tick()
    if not next(pending) then return end
    local now=GetGameTimer() local cfg=VehicleConfig.departureGhost
    local vehicles,players=GetAllVehicles(),GetPlayers()
    for key,s in pairs(pending) do
        if not owns(s) then pending[key]=nil
        else
            local point=GetEntityCoords(s.entity) local bucket=GetEntityRoutingBucket(s.entity)
            local occupied=false
            for _,v in ipairs(vehicles) do
                if v~=s.entity and DoesEntityExist(v) and GetEntityRoutingBucket(v)==bucket and MX.distance(GetEntityCoords(v),point)<cfg.radius then occupied=true break end
            end
            if not occupied then for _,src in ipairs(players) do
                local ped=GetPlayerPed(src)
                if ped~=0 and DoesEntityExist(ped) and GetPlayerRoutingBucket(src)==bucket and GetVehiclePedIsIn(ped,false)~=s.entity and MX.distance(GetEntityCoords(ped),point)<cfg.radius then occupied=true break end
            end end
            if occupied then s.clearAt=nil else s.clearAt=s.clearAt or now end
            -- Never switch collision back on while another player is still inside.
            if s.started and now-s.started>=cfg.minimumMs and s.clearAt and now-s.clearAt>=cfg.clearMs then clear(key,s) end
        end
    end
end
CreateThread(function() while true do Wait(250) G.tick() end end)
AddEventHandler('onResourceStop',function(resource)
    if resource==GetCurrentResourceName() then for key,s in pairs(pending) do clear(key,s) end end
end)
