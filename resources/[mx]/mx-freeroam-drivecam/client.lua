local M,C=DrivecamMath,DrivecamConfig
local enabled=false
local stored=GetResourceKvpString('mx:drivecam:v1')
if stored then local ok,p=pcall(json.decode,stored) if ok and type(p)=='table' and p.version==1 and type(p.enabled)=='boolean' then enabled=p.enabled end end
local cam,view,vehicle,query=nil,nil,nil,nil
local generation=0 local dims={} local lookYaw,pitch,manualAt,lastPoint,lastAt=0,0,0,nil,nil
local permitted=C.distance local lastSafeAt=0 local fallbackUntil=0 local debug=C.debug
local backAngle=0
local rig,geometry=nil,nil
local rearPivotEnabled=true -- session-only comparison; does not change the saved F7 preference
local function coordinator() return exports['mx-freeroam-experience'] end
local function release()
    if cam then
        if view and MX.online('mx-freeroam-experience') and coordinator():OwnsView(view) then RenderScriptCams(false,false,0,true,false) coordinator():ReleaseView(view) end
        DestroyCam(cam,false)
    end
    cam=nil view=nil query=nil vehicle=nil lastAt=nil lastPoint=nil rig=nil geometry=nil backAngle=0 lookYaw=0 pitch=0 manualAt=0 fallbackUntil=0 generation=generation+1
end
local function preference(value)
    enabled=value==true SetResourceKvp('mx:drivecam:v1',json.encode({version=1,enabled=enabled}))
    if not enabled then release() end
    TriggerEvent('mx:drivecam:preference',enabled) return {enabled=enabled}
end
exports('Preference',function(value) if value~=nil then return preference(value) end return {enabled=enabled} end)
RegisterCommand('drivecam',function() if GetResourceState('mx-freeroam-menu')=='started' then return end preference(not enabled) TriggerEvent('mx:notice',enabled and 'Câmera personalizada ligada' or 'Câmera original') end,false)
RegisterKeyMapping('drivecam','MX: alternar câmera de condução','keyboard','F7')
RegisterCommand('drivecamdebug',function() if GetConvarInt('mx_allowDrafts',0)==1 then debug=not debug end end,false)
RegisterCommand('drivecampivot',function()
    rearPivotEnabled=not rearPivotEnabled
    TriggerEvent('mx:notice',rearPivotEnabled and 'Enquadramento traseiro: ligado (teste)' or 'Enquadramento traseiro: desligado')
end,false)
local function eligible()
    if not enabled or not MX.online('mx-freeroam-experience') or coordinator():DrivecamSuspended() or IsPauseMenuActive() or IsNuiFocused() or NetworkIsInSpectatorMode() or IsEntityDead(PlayerPedId()) then return nil end
    local v=GetVehiclePedIsIn(PlayerPedId(),false)
    if v==0 or GetPedInVehicleSeat(v,-1)~=PlayerPedId() or not IsThisModelACar(GetEntityModel(v)) then return nil end return v
end
-- Wheel bones are sampled once per vehicle. Missing/malformed mod bones fall
-- back to bounds, rather than querying entity -1 or carrying the previous car.
local function measure(v,low,high)
    local sum=vector3(0,0,0) local points={}
    for _,name in ipairs({'wheel_lf','wheel_rf','wheel_lr','wheel_rr'})do
        local index=GetEntityBoneIndexByName(v,name)
        if index~=-1 then
            local world=GetWorldPositionOfEntityBone(v,index)
            local point=GetOffsetFromEntityGivenWorldCoords(v,world.x,world.y,world.z)
            if math.abs(point.x)<high.x-low.x+1 and math.abs(point.y)<high.y-low.y+1 and math.abs(point.z)<high.z-low.z+1 then
                points[#points+1]=point sum=sum+point
            end
        end
    end
    local length=high.y-low.y
    local center=vector3((low.x+high.x)/2,(low.y+high.y)/2,(low.z+high.z)/2+.1)
    local wheelbase=length*.6
    if #points==4 then
        local front=(points[1]+points[2])/2 local rear=(points[3]+points[4])/2
        local measured=#(front-rear)
        if measured>.5 and measured<length*1.2 then
            wheelbase=measured local wheels=sum/4
            center=vector3(wheels.x,wheels.y,center.z)
        end
    end
    return {center=center,wheelbase=M.clamp(wheelbase,1,8)}
end
CreateThread(function()
    while true do
        Wait(0)
        local v=eligible()
        if not v then release() Wait(enabled and 100 or 500)
        else
            local now=GetGameTimer() local position=GetEntityCoords(v)
            local dt=lastAt and (now-lastAt)/1000 or 1/60
            if v~=vehicle or dt>0.25 or (lastPoint and #(position-lastPoint)>C.teleportDistance) or (cam and not coordinator():OwnsView(view)) then
                release() vehicle=v permitted=C.distance lastSafeAt=0
            end
            dt=M.clamp(dt,0.0001,0.1) lastAt=now lastPoint=position
            local model=GetEntityModel(v)
            if not dims[model] then local low,high=GetModelDimensions(model) dims[model]={low=low,high=high} end
            if not geometry then geometry=measure(v,dims[model].low,dims[model].high)end
            local forward,right,up=GetEntityMatrix(v)
            local velocity=GetEntityVelocity(v)
            local center=geometry.center
            local physical=GetOffsetFromEntityInWorldCoords(v,center.x,center.y,center.z)
            local sample={forward=forward,right=right,up=up,velocity=velocity,anchor=physical,wheelbase=geometry.wheelbase,pivotBack=rearPivotEnabled and C.rearPivotBack or 0}
            rig=rig or DrivecamChase.new(sample)
            local mouse=IsInputDisabled(0)
            DisableControlAction(0,1,true) DisableControlAction(0,2,true)
            local x,y=GetDisabledControlNormal(0,1),GetDisabledControlNormal(0,2)
            if math.abs(x)> (mouse and 0.0001 or C.deadzone) or math.abs(y)>(mouse and 0.0001 or C.deadzone) then
                local scale=mouse and C.mouseSensitivity or C.stickRate*dt
                lookYaw=M.angle(lookYaw-x*scale) pitch=M.clamp(pitch+y*scale,C.pitchMin,C.pitchMax) manualAt=now
            elseif now-manualAt>C.recenterDelay*1000 then lookYaw=M.angleDecay(lookYaw,0,0.2,dt) pitch=M.decay(pitch,0,0.2,dt) end
            backAngle=M.angleDecay(backAngle,IsControlPressed(0,26) and math.pi or 0,0.10,dt)
            local back=backAngle
            local pose=DrivecamChase.step(rig,sample,dt,lookYaw+back,-pitch)
            local desiredPosition=vector3(pose.position.x,pose.position.y,pose.position.z)
            local delta=desiredPosition-physical local requested=#delta
            -- Complete at most one asynchronous capsule. Never interpret pending as clear.
            if query then
                local status,hit,hitPoint=GetShapeTestResult(query.handle)
                if status~=1 then
                    local travel=#(query.origin-physical)
                    if status==2 and M.queryFresh(query,generation,v,now,travel,#(query.target-desiredPosition),math.min(8,pose.speed*.05)) then
                        local blocked=hit==true or hit==1
                        local safe=blocked and math.max(0,#(hitPoint-query.origin)-C.margin-travel) or math.max(0,query.length-travel)
                        permitted=safe<permitted and safe or M.decay(permitted,safe,C.collisionReturn,dt)
                        lastSafeAt=now
                    end query=nil
                elseif now-query.at>150 then query=nil permitted=math.min(permitted,C.minDistance) end
            end
            if not query then query={handle=StartShapeTestCapsule(physical.x,physical.y,physical.z,desiredPosition.x,desiredPosition.y,desiredPosition.z,C.radius,19,v,7),origin=physical,target=desiredPosition,length=requested,vehicle=v,generation=generation,at=now} end
            -- No valid fresh result means remain conservative, including on activation.
            local safeDistance=(now-lastSafeAt<=150) and math.min(requested,permitted) or math.min(C.minDistance-0.1,permitted)
            if safeDistance<C.minDistance then
                if cam then if coordinator():OwnsView(view) then RenderScriptCams(false,false,0,true,false) coordinator():ReleaseView(view) end DestroyCam(cam,false) cam=nil view=nil end
                fallbackUntil=now+350
            elseif now>=fallbackUntil then
                if not cam then view=coordinator():AcquireView('drivecam') if view then cam=CreateCam('DEFAULT_SCRIPTED_CAMERA',true) RenderScriptCams(true,false,0,true,false) end end
                if cam and coordinator():OwnsView(view) then
                    local final=physical+delta*(safeDistance/requested)
                    local aim=vector3(pose.aim.x,pose.aim.y,pose.aim.z)
                    -- Collision retracts the arm, not the view direction. Aiming
                    -- at the full-length target from the compressed position
                    -- introduced a pitch kick on crests, dips and ramp edges.
                    local direction=aim-desiredPosition
                    local horizontal=math.sqrt(direction.x^2+direction.y^2)
                    SetCamCoord(cam,final.x,final.y,final.z)
                    SetCamRot(cam,math.deg(math.atan(direction.z,horizontal)),pose.roll,math.deg(math.atan(-direction.x,direction.y)),2)
                    SetCamFov(cam,pose.fov)
                end
            end
            if debug then
                SetTextFont(0) SetTextScale(0.3,0.3) SetTextColour(255,255,255,255) BeginTextCommandDisplayText('STRING') AddTextComponentSubstringPlayerName(('Kirby chase %s | speed %.1f | G %.2f/%.2f/%.2f | collision %.2f/%.2f'):format(cam and 'active' or 'fallback',pose.speed*3.6,pose.g.x,pose.g.y,pose.g.z,safeDistance,requested)) EndTextCommandDisplayText(0.02,0.75)
            end
        end
    end
end)
AddEventHandler('onClientResourceStop',function(r) if r==GetCurrentResourceName() or r=='mx-freeroam-experience' then release() end end)
