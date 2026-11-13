-- Vehicle instrumentation only, adapted from the owner's mx-hud.
MenuVehicleHud={}
local trips={}
local function on(value)return value==true or value==1 end
function MenuVehicleHud.sample(v,prefs)
    local state=Entity(v).state
    local key=state.mxVehicle or v
    local now=GetGameTimer() local pos=GetEntityCoords(v)
    local trip=trips[key] or {km=0}
    if trip.position and now-trip.at<1000 then
        local a=trip.position local dx,dy,dz=pos.x-a.x,pos.y-a.y,pos.z-a.z
        local distance=math.sqrt(dx*dx+dy*dy+dz*dz)
        if distance<100 then trip.km=trip.km+distance/1000 end
    end
    trip.position={x=pos.x,y=pos.y,z=pos.z} trip.at=now trips[key]=trip
    local gear=GetVehicleCurrentGear(v)
    local rpm=GetVehicleCurrentRpm(v)
    if GetResourceState('mx-gearbox')=='started' then
        local ok,data=pcall(function()return exports['mx-gearbox']:GetTransmissionData(v)end)
        if ok and type(data)=='table' then gear=data.gear rpm=data.normalizedRpm or rpm end
    end
    if gear==0 and GetEntitySpeedVector(v,true).y<-.1 then gear=-1 end
    local _,low,high=GetVehicleLightsState(v)
    return {enabled=true,speed=GetEntitySpeed(v)*(prefs.units=='mph' and 2.236936 or 3.6),units=prefs.units=='mph' and 'mph' or 'km/h',
        rpm=rpm,gear=gear,scale=prefs.scale,fuel=GetVehicleFuelLevel(v),odometer=trip.km,
        lowBeam=on(low),highBeam=on(high),handbrake=on(GetVehicleHandbrake(v)),engineHealth=GetVehicleEngineHealth(v),
        abs=state.absActive==true,tc=state.tractionControlActive==true}
end
