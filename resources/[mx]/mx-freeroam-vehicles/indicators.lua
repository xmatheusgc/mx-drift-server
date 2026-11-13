-- Indicators are visual state shared with observers, including late streaming.
VehicleIndicators={}
function VehicleIndicators.apply(vehicle,state)
    if not DoesEntityExist(vehicle) or type(state)~='table' or Entity(vehicle).state.mxVehicle~=state.id or
        not MX.number(state.mode,0,3,true) then return false end
    SetVehicleIndicatorLights(vehicle,1,state.mode==1 or state.mode==3)
    SetVehicleIndicatorLights(vehicle,0,state.mode==2 or state.mode==3)
    return true
end
AddStateBagChangeHandler('mxIndicators',nil,function(bag,_,state)
    if type(state)~='table' then return end
    CreateThread(function()
        local deadline=GetGameTimer()+3000
        repeat
            local vehicle=GetEntityFromStateBagName(bag)
            if vehicle~=0 and DoesEntityExist(vehicle) then
                local current=Entity(vehicle).state.mxIndicators
                if type(current)=='table' and (current.id~=state.id or current.mode~=state.mode) then return end
            end
            if vehicle~=0 and VehicleIndicators.apply(vehicle,state) then return end
            Wait(100)
        until GetGameTimer()>=deadline
    end)
end)
AddEventHandler('onClientResourceStart',function(name)
    if name~=GetCurrentResourceName() then return end
    for _,vehicle in ipairs(GetGamePool('CVehicle')) do VehicleIndicators.apply(vehicle,Entity(vehicle).state.mxIndicators) end
end)
