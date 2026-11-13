-- Only this transfer's car may be restored. No UI focus or player freeze is
-- acquired here; a failed detach must never leave the player immobilized.
VehicleRespawn={}
local R=VehicleRespawn
local pending
local function same(s)
    return DoesEntityExist(s.car) and VehicleNetwork.resolve(s.net,s.id)==s.car and Entity(s.car).state.mxVehicle==s.id
end
local function restore(s)
    if not s or pending~=s then return {resumed=true} end
    pending=nil -- Cleanup is idempotent, including a late server rollback.
    if not same(s) then return {resumed=true} end
    NetworkRequestControlOfEntity(s.car)
    FreezeEntityPosition(s.car,s.frozen)
    if PlayerPedId()==s.ped then
        local current=GetVehiclePedIsIn(s.ped,false)
        if current==s.car or current==0 then
            ClearPedTasksImmediately(s.ped)
            local driver=GetPedInVehicleSeat(s.car,-1)
            if s.driver and (driver==0 or driver==s.ped) then SetPedIntoVehicle(s.ped,s.car,-1) end
        end
    end
    SetVehicleDoorsLocked(s.car,s.locked)
    return {resumed=true}
end
function R.resume(d)
    local s=pending
    if not s then return {resumed=true} end
    if d.transfer~=s.transfer or d.id~=s.id or d.net~=s.net then return {resumed=false,obsolete=true} end
    return restore(s)
end
function R.begin(d,v)
    MX.require(not pending,'BUSY','Uma troca de veículo ainda está sendo concluída')
    MX.require(type(d.transfer)=='string','PAYLOAD','Troca sem identificador')
    local ped=PlayerPedId()
    for seat=-1,GetVehicleMaxNumberOfPassengers(v)-1 do
        local occupant=GetPedInVehicleSeat(v,seat)
        MX.require(occupant==0 or occupant==ped,'PASSENGER','O veículo ainda está ocupado')
    end
    local s={car=v,net=d.net,id=d.id,transfer=d.transfer,ped=ped,driver=GetPedInVehicleSeat(v,-1)==ped,
        frozen=IsEntityPositionFrozen(v),locked=GetVehicleDoorLockStatus(v),expires=GetGameTimer()+10000}
    pending=s -- Before the first mutation: errors and timeouts can both restore.
    local ok,result=pcall(function()
        SetVehicleDoorsLocked(v,1)
        SetEntityVelocity(v,0.0,0.0,0.0) FreezeEntityPosition(v,true)
        if GetVehiclePedIsIn(ped,false)==v then TaskLeaveVehicle(ped,v,16) end
        local deadline=GetGameTimer()+2500
        while same(s) and PlayerPedId()==ped and GetVehiclePedIsIn(ped,false)==v and GetGameTimer()<deadline do Wait(0) end
        MX.require(pending==s and same(s) and PlayerPedId()==ped,'OBSOLETE','O veículo ou personagem mudou durante a troca')
        if GetVehiclePedIsIn(ped,false)~=0 then return {ready=false,reason='EXIT_TIMEOUT'} end
        for seat=-1,GetVehicleMaxNumberOfPassengers(v)-1 do MX.require(GetPedInVehicleSeat(v,seat)==0,'PASSENGER','Um ocupante entrou durante a troca') end
        return {ready=true}
    end)
    if not ok or not result.ready then
        restore(s)
        if not ok then error(result,0) end
        result.recovered=true
    end
    return result
end
CreateThread(function()
    while true do
        Wait(250)
        local s=pending
        if s then
            if not same(s) then pending=nil
            elseif GetGameTimer()>=s.expires then restore(s) end
        end
    end
end)
AddEventHandler('onClientResourceStop',function(name)
    if name==GetCurrentResourceName() then restore(pending) end
end)
