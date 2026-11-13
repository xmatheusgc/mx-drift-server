VehicleInput={}
function VehicleInput.block()
    if GetVehiclePedIsIn(PlayerPedId(),false)==0 then return end
    -- Radio and vehicle weapon selection; leave driving/camera controls intact.
    for _,control in ipairs({81,82,83,84,85,332,333,37,12,13,14,15,16,17,99,100}) do
        DisableControlAction(0,control,true)
    end
    if MenuBindings and MenuBindings.keyInput('engine',true) then DisableControlAction(0,58,true) end
end
