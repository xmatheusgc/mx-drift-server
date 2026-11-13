-- Replayed on every observer; pair-only, frame-only suppression keeps map/floor
-- collision intact and restores automatically on removal, stop or identity change.
VehicleDepartureGhost={}
local G=VehicleDepartureGhost
local tracked={} local pool={} local nextScan=0
local function valid(v,id)
    if not DoesEntityExist(v) then return false end
    local state=Entity(v).state local ghost=state.mxDepartureGhost
    return state.mxVehicle==id and type(ghost)=='table' and ghost.id==id
end
function G.track(v)
    if not DoesEntityExist(v) then return end
    local id=Entity(v).state.mxVehicle
    if valid(v,id) then
        if not tracked[v] then nextScan=0 end
        tracked[v]=id
    end
end
function G.frame()
    local now=GetGameTimer()
    if now>=nextScan then
        pool={}
        for _,v in ipairs(GetGamePool('CVehicle')) do pool[#pool+1]=v G.track(v) end
        if next(tracked) then for _,p in ipairs(GetGamePool('CPed')) do pool[#pool+1]=p end end
        nextScan=now+(next(tracked) and 100 or 500)
    end
    for v,id in pairs(tracked) do
        if not valid(v,id) then tracked[v]=nil
        else
            local point=GetEntityCoords(v)
            for _,other in ipairs(pool) do
                if other~=v and DoesEntityExist(other) and MX.distance(point,GetEntityCoords(other))<30 then
                    SetEntityNoCollisionEntity(v,other,true)
                    SetEntityNoCollisionEntity(other,v,true)
                end
            end
        end
    end
end
AddStateBagChangeHandler('mxDepartureGhost',nil,function(bag)
    local entity=GetEntityFromStateBagName(bag)
    if entity~=0 then G.track(entity) end
    nextScan=0
end)
CreateThread(function() while true do G.frame() Wait(0) end end)
