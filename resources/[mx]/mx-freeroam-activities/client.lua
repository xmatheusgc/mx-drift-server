local frozen,session,ghosts=nil,nil,{}
local function release()
    if frozen and DoesEntityExist(frozen) then FreezeEntityPosition(frozen,false) end frozen=nil
end
MX.clients('activities',{
    prepare=function(d)
        local v=NetToVeh(d.net)
        MX.require(v~=0 and v==GetVehiclePedIsIn(PlayerPedId(),false) and GetPedInVehicleSeat(v,-1)==PlayerPedId(),'VEHICLE')
        frozen=v FreezeEntityPosition(v,true)
        SetTimeout(12000,function() if frozen==v then release() end end)
        return {prepared=true}
    end
})
RegisterNetEvent('mx:activities:go',function() if source==65535 then release() end end)
RegisterNetEvent('mx:activities:release',function() if source==65535 then release() session=nil end end)
RegisterNetEvent('mx:activities:state',function(s) if source==65535 then session=s end end)
RegisterNetEvent('mx:activities:ghost',function(players) if source==65535 then ghosts=players end end)
CreateThread(function()
    while true do
        if session or #ghosts>0 then
            Wait(0)
            if session and session.nextPoint then local p=session.nextPoint DrawMarker(1,p.x,p.y,p.z-1,0.0,0.0,0.0,0.0,0.0,0.0,session.radius*2,session.radius*2,2.0,242,181,92,100,false,false,2,false,nil,nil,false) end
            local own=GetVehiclePedIsIn(PlayerPedId(),false)
            for _,id in ipairs(ghosts) do local player=GetPlayerFromServerId(id) if player~=-1 and player~=PlayerId() then local ped=GetPlayerPed(player) local v=GetVehiclePedIsIn(ped,false) if own~=0 and v~=0 then SetEntityNoCollisionEntity(own,v,true) SetEntityNoCollisionEntity(v,own,true) end end end
        else Wait(250) end
    end
end)
CreateThread(function()
    while true do
        Wait(1000)
        if session and session.state=='active' then
            local signature=exports['mx-freeroam-vehicles']:ObservedSignature(session.net)
            if signature then MX.request('activities','configuration',{id=session.id,signature=signature}) end
        end
    end
end)
CreateThread(function()
    while true do
        Wait(500)
        if ActivityConfig.driftTelemetry and session and session.state=='active' and session.mode=='drift' then
            local v=GetVehiclePedIsIn(PlayerPedId(),false)
            if v~=0 then
                local velocity=GetEntitySpeedVector(v,true)
                local angle=math.deg(math.atan(velocity.x,math.abs(velocity.y)+0.001))
                MX.request('activities','telemetry',{id=session.id,speed=GetEntitySpeed(v),angle=angle,rpm=GetVehicleCurrentRpm(v)})
            end
        end
    end
end)
AddEventHandler('onClientResourceStop',function(name) if name==GetCurrentResourceName() then release() ghosts={} session=nil end end)
