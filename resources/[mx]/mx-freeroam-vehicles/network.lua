-- A valid network ID may not be streamed on this client, or may have been reused.
VehicleNetwork={}
function VehicleNetwork.resolve(net,id)
    if not MX.number(net,1,65535,true) or not NetworkDoesEntityExistWithNetworkId(net) then return 0 end
    local entity=NetToVeh(net)
    if entity==0 or not DoesEntityExist(entity) or not IsEntityAVehicle(entity) then return 0 end
    if id and Entity(entity).state.mxVehicle~=id then return 0 end
    return entity
end
