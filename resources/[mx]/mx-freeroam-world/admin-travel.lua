local function check(src)
    MX.require(IsPlayerAceAllowed(src,'mx.admin') and IsPlayerAceAllowed(src,'mx.teleport'),'FORBIDDEN','Permissão ACE necessária: mx.teleport')
    local actor=MX.actor(src)
    MX.require(actor and GetPlayerRoutingBucket(src)==0 and GetEntityHealth(GetPlayerPed(src))>0,'SESSION','Teleporte administrativo disponível no modo livre')
    MX.require(not MX.online('mx-freeroam-experience') or not exports['mx-freeroam-experience']:IsPrivate(src),'SESSION','Saia da oficina antes de teleportar')
    return actor
end
local function point(value)
    MX.require(MX.keys(value,{x=true,y=true,z=true,h=true}) and MX.number(value.x,-20000,20000) and MX.number(value.y,-20000,20000) and MX.number(value.z,-100,3000) and (value.h==nil or MX.number(value.h,0,360)),'COORDS','Informe X/Y entre -20000 e 20000, Z entre -100 e 3000 e heading entre 0 e 360')
    return {x=value.x,y=value.y,z=value.z,h=value.h}
end
exports('AdminTravel',function(src,d)
    local invoker=GetInvokingResource()
    return MX.capture(function()
        MX.require(invoker=='mx-freeroam-admin','FORBIDDEN')
        local actor=check(src) local ped=GetPlayerPed(src) local vehicle=GetVehiclePedIsIn(ped,false)
        if vehicle~=0 then exports['mx-freeroam-vehicles']:OwnedDriver(src,true) end
        MX.require(d.mode=='coordinates' or d.mode=='waypoint','PAYLOAD')
        local destination
        if d.mode=='coordinates' then destination=point(d.point)
        else destination=point(MX.callClient(src,'admin','waypoint',{})) end
        local current=check(src)
        MX.require(current.epoch==actor.epoch and GetPlayerPed(src)==ped and GetVehiclePedIsIn(ped,false)==vehicle,'OBSOLETE','O personagem ou veículo mudou durante a preparação')
        destination.h=destination.h or GetEntityHeading(vehicle~=0 and vehicle or ped)
        local result=WorldTrainer.travel(src,'admin',vehicle~=0,destination,true)
        result.point=destination return result
    end)
end)
