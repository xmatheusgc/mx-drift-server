local navigationModal=false
AddEventHandler('mx:experience:modal',function(value) navigationModal=value==true end)
local active,token,cam,view=false,nil,nil,nil
local confirmed,sceneGeneration=nil,0
local reduce=GetResourceKvpInt('mx:reduceMotion')==1
local original=nil
local carDimensions=nil
local previewEntity=0
local previewId=nil
local nightPreview=false
local lightPreview=false
local lobby,lobbyGeneration,lobbyAcknowledged=false,0,false
local lastLobbyData=nil
local initialLoading=true
local function loading(message)
    TriggerEvent('mx:loading', {active=message~=nil,message=message})
    if initialLoading and message then SendLoadingScreenMessage(json.encode({eventName='mxStage',message=message})) end
end
AddEventHandler('mx:loadingProgress',function(data)
    if initialLoading then SendLoadingScreenMessage(json.encode({eventName='mxStage',message=data.message})) end
end)
local played=false
local paused=nil
local function unpause()
    if paused then
        for _,e in ipairs(paused) do if DoesEntityExist(e.entity) and (not e.net or NetworkGetNetworkIdFromEntity(e.entity)==e.net) then FreezeEntityPosition(e.entity,e.frozen) end end
        paused=nil
    end
    if not active then SetPlayerControl(PlayerId(),true,0) end
end
local function pause()
    if active or paused then return end
    local ped=PlayerPedId() local car=GetVehiclePedIsIn(ped,false)
    MX.require(car==0 or GetEntitySpeed(car)<0.5,'LOBBY','Pare o veículo antes de abrir o lobby')
    paused={{entity=ped,frozen=IsEntityPositionFrozen(ped)}}
    if car~=0 and GetPedInVehicleSeat(car,-1)==ped and NetworkHasControlOfEntity(car) then paused[#paused+1]={entity=car,net=NetworkGetNetworkIdFromEntity(car),frozen=IsEntityPositionFrozen(car)} end
    for _,e in ipairs(paused) do FreezeEntityPosition(e.entity,true) end
    SetPlayerControl(PlayerId(),false,0)
end
AddEventHandler('mx:experience:previewRemoved',function(id) if previewId==id then previewEntity=0 previewId=nil end end)
local orbit=0
local cameraBase=nil
local cameraContext='main'
local cameraSequence=0
local cameraVehicle,cameraGeneration=nil,nil
local transitioning={}
local freeCamera=false
local freeReturn='main'
local cameraData,freeReturnData=nil,nil
local orbitState=nil
local orbitMotion=nil
local freeChanging=false
local function freeFocus(value)
    freeCamera=value
    if not value then orbitState=nil orbitMotion=nil end
    TriggerEvent('mx:experience:freeCamera',value)
end
exports('FreeCameraActive',function() return freeCamera end)
exports('ControllerIcons',function() return ExperienceConfig.controllerIcons end)
exports('InWorkshop',function() return active end)
exports('InLobby',function() return lobby end)
exports('IsLobbyGeneration',function(generation) return lobby and generation==lobbyGeneration end)
local function send(state) TriggerEvent('mx:experience:state',state) end
exports('ApplyConfirmed',function() if confirmed then Character.apply(confirmed,true) return true end return false end)
local function collision(point)
    local ped=PlayerPedId() FreezeEntityPosition(ped,true)
    RequestCollisionAtCoord(point.x,point.y,point.z) SetEntityCoordsNoOffset(ped,point.x,point.y,point.z,false,false,false) SetEntityHeading(ped,point.h or 0.0)
    local deadline=GetGameTimer()+ExperienceConfig.timeout
    while not HasCollisionLoadedAroundEntity(ped) and GetGameTimer()<deadline do RequestCollisionAtCoord(point.x,point.y,point.z) Wait(30) end
    return HasCollisionLoadedAroundEntity(ped)
end
local sceneContext='garage'
local personPoint=ExperienceConfig.scene.ped
local function geometry()
 local car=(sceneContext=='lobby' and ExperienceConfig.lobbyScene or ExperienceConfig.scene).car local width,length=1.9,4.5
 if previewEntity~=0 and DoesEntityExist(previewEntity) and Entity(previewEntity).state.mxVehicle==previewId then
  local pos=GetEntityCoords(previewEntity)
  car={x=pos.x,y=pos.y,z=pos.z,h=GetEntityHeading(previewEntity)}
  local low,high=GetModelDimensions(GetEntityModel(previewEntity))
  width=high.x-low.x length=high.y-low.y
 end
 return car,width,length,carDimensions and carDimensions.height or 1.4
end
local function placeCharacter()
 local generation=sceneGeneration local entity=previewEntity
 local point=MX.copy((sceneContext=='lobby' and ExperienceConfig.lobbyScene or ExperienceConfig.scene).ped)
 RequestCollisionAtCoord(point.x,point.y,point.z)
 local found,z=GetGroundZFor_3dCoord(point.x,point.y,point.z+3.0,false)
 local groundDeadline=GetGameTimer()+2000
 while not found and active and generation==sceneGeneration and entity==previewEntity and GetGameTimer()<groundDeadline do
  RequestCollisionAtCoord(point.x,point.y,point.z) Wait(30)
  found,z=GetGroundZFor_3dCoord(point.x,point.y,point.z+3.0,false)
 end
 if not active or generation~=sceneGeneration or entity~=previewEntity then return end
 -- Presentation stays frozen even without a floor; it cannot block garage entry.
 local ped=PlayerPedId()
 FreezeEntityPosition(ped,true)
 SetEntityCoordsNoOffset(ped,point.x,point.y,point.z,false,false,false)
 SetEntityHeading(ped,point.h or 0.0)
 if not found then point.fixed=true z=point.z end
 personPoint=point
 if active and generation==sceneGeneration and entity==previewEntity then personPoint=WorkshopPresentation.ground(PlayerPedId(),point,z) end
end
local function removeCamera()
    WorkshopCameraDev.stop(false)
    freeFocus(false)
    cameraSequence=cameraSequence+1
    for old in pairs(transitioning) do if DoesCamExist(old) then DestroyCam(old,false) end transitioning[old]=nil end
    if cam then
        if view and exports['mx-freeroam-experience']:OwnsView(view) then RenderScriptCams(false,false,0,true,false) exports['mx-freeroam-experience']:ReleaseView(view) end
        DestroyCam(cam,false) cam=nil view=nil
    end
end
local function camera(context,data)
    WorkshopCameraDev.stop(true)
    local selectedRegion=data and data.slot and WorkshopFraming.slots[data.slot] or context
    WorkshopPresentation.doorContext(selectedRegion)
    if freeCamera then freeReturn=context freeReturnData=data return end
    if cam and DoesCamExist(cam) and cameraContext==context and (cameraData and cameraData.slot)==(data and data.slot) and cameraVehicle==previewId and cameraGeneration==sceneGeneration and not (data and data.force) then return end
    -- A piece selection cannot steal manual camera control.
    if not cam or not view or not exports['mx-freeroam-experience']:OwnsView(view) then removeCamera() view=exports['mx-freeroam-experience']:AcquireView('workshop') end
    MX.require(view,'CAMERA','Outra câmera está em uso')
    cameraSequence=cameraSequence+1 local requestSequence=cameraSequence
    local oldCam=cam local oldPosition=cam and GetCamCoord(cam) or nil
    local requestView=view local requestGeneration=sceneGeneration
    local cfg=sceneContext=='lobby' and ExperienceConfig.lobbyCamera or ExperienceConfig.camera local target=cfg.look local position={x=cfg.x,y=cfg.y,z=cfg.z}
    local requiredDistance=0 local detailView=false
    local ped=personPoint local car,width,length,height=geometry()
    local mainPreset=context=='main' and ExperienceConfig.mainCameras[sceneContext]
    if context=='main' then
        if mainPreset then
            position,target=MX.copy(mainPreset.position),MX.copy(mainPreset.look)
            cfg={fov=mainPreset.fov,rotation=mainPreset.rotation}
        else position,target=WorkshopFraming.scene(car,ped,width,length,GetAspectRatio(false),sceneContext,height)end
    end
    if context=='face' or context=='character' then
        local head=GetPedBoneCoords(PlayerPedId(),0x796E,0.0,0.0,0.0)
        local foot=GetPedBoneCoords(PlayerPedId(),0xCC4D,0.0,0.0,0.0)
        local close=context=='face'
        local anchor={x=ped.x,y=ped.y,z=close and head.z-.03 or (head.z+foot.z)/2+.12,h=ped.h}
        target=ExperienceConfig.offset(anchor,0,0,0)
        position=ExperienceConfig.offset(anchor,close and 1.05 or 3.1,0,close and .03 or .05)
        cfg={fov=close and 35.0 or 44.0}
    else
        local region=data and data.slot and WorkshopFraming.slots[data.slot] or ({wheels='frontWheel',low='skirt'})[context] or context
        local spec=WorkshopFraming.regions[region]
        if spec then
            detailView=true
            local bone
            if spec.bone and previewEntity~=0 and DoesEntityExist(previewEntity) and Entity(previewEntity).state.mxVehicle==previewId then
                for _,name in ipairs(spec.bones or {spec.bone})do
                    local index=GetEntityBoneIndexByName(previewEntity,name)
                    if index~=-1 then
                        local p=GetWorldPositionOfEntityBone(previewEntity,index)
                        if MX.distance(p,car)<=math.sqrt(length*length+width*width+height*height)/2+.25 then bone=p break end
                    end
                end
            end
            local framedFov
            position,target,framedFov,requiredDistance=WorkshopFraming.frame(car,width,length,height,region,bone,GetAspectRatio(false))
            cfg={fov=framedFov}
        end
    end
    -- Character editors retain a small composition offset; vehicle views
    -- use the whole scene above the bottom strip.
    local shift=context=='face' and 0.15 or context=='character' and 0.25 or 0
    local dx,dy=target.x-position.x,target.y-position.y local sightLength=math.sqrt(dx*dx+dy*dy)
    if sightLength>0.1 then target={x=target.x-dy/sightLength*shift,y=target.y+dx/sightLength*shift,z=target.z} end
    -- Validate the static sightline with a volume. Native presentation still needs in-game QA.
    local test=StartShapeTestCapsule(target.x,target.y,target.z,position.x,position.y,position.z,0.2,19,previewEntity,7)
    local deadline=GetGameTimer()+250 local status,hit,point
    repeat status,hit,point=GetShapeTestResult(test) if status==1 then Wait(0) end until status~=1 or GetGameTimer()>deadline
    if not active or requestSequence~=cameraSequence or requestGeneration~=sceneGeneration or not exports['mx-freeroam-experience']:OwnsView(requestView) then return end
    if status==2 and hit==1 and not mainPreset then
        local ray=vector3(position.x-target.x,position.y-target.y,position.z-target.z) local distance=#ray
        local free=math.max(0.8,#(point-vector3(target.x,target.y,target.z))-0.15)
        if distance>0 then
            local safe=vector3(target.x,target.y,target.z)+ray*(math.min(distance,free)/distance)
            if WorkshopFraming.outside(car,width,length,height,safe) and MX.distance(safe,target)>=requiredDistance then position={x=safe.x,y=safe.y,z=safe.z}
            elseif oldPosition and WorkshopFraming.outside(car,width,length,height,oldPosition) and MX.distance(oldPosition,target)>=requiredDistance then position={x=oldPosition.x,y=oldPosition.y,z=oldPosition.z}
            else MX.fail('CAMERA','Sem espaço para observar esta peça fora da carroceria') end
        end
    end
    local clearPath=false
    if oldPosition and not reduce then
        local pathTest=StartShapeTestCapsule(oldPosition.x,oldPosition.y,oldPosition.z,position.x,position.y,position.z,0.2,19,0,7)
        deadline=GetGameTimer()+250
        repeat status,hit=GetShapeTestResult(pathTest) if status==1 then Wait(0) end until status~=1 or GetGameTimer()>deadline
        clearPath=status==2 and hit==0
    end
    if requestSequence~=cameraSequence or requestGeneration~=sceneGeneration then return end
    if detailView then target=WorkshopFraming.compose(position,target,cfg.fov)end
    cameraContext=context cameraData=data and {slot=data.slot} cameraVehicle=previewId cameraGeneration=sceneGeneration orbit=0 cameraBase={position=position,target=target}
    local nextCam=CreateCam('DEFAULT_SCRIPTED_CAMERA',true) SetCamCoord(nextCam,position.x+0.0,position.y+0.0,position.z+0.0)
    if cfg.rotation then SetCamRot(nextCam,cfg.rotation.x+0.0,cfg.rotation.y+0.0,cfg.rotation.z+0.0,2)
    else PointCamAtCoord(nextCam,target.x,target.y,target.z)end
    SetCamFov(nextCam,cfg.fov+0.0)
    cam=nextCam
    if oldCam and oldPosition and data and data.orbitReturn and not reduce then
        if DoesCamExist(oldCam) then DestroyCam(oldCam,false) end
        SetCamCoord(nextCam,oldPosition.x,oldPosition.y,oldPosition.z)
        CreateThread(function()
            local started=GetGameTimer() local last=oldPosition local pending
            while GetGameTimer()-started<400 and cam==nextCam and requestSequence==cameraSequence and requestGeneration==sceneGeneration do
                local t=math.min(1,(GetGameTimer()-started)/400) t=t*t*(3-2*t)
                local p=WorkshopFraming.arc(car,width,length,oldPosition,position,t)
                if pending then
                    local state,blocked=GetShapeTestResult(pending.handle)
                    if state~=1 then if state==2 and blocked==0 then last=pending.point SetCamCoord(nextCam,last.x,last.y,last.z) end pending=nil end
                else pending={handle=StartShapeTestCapsule(last.x,last.y,last.z,p.x,p.y,p.z,0.15,19,0,7),point=p} end
                PointCamAtCoord(nextCam,target.x,target.y,target.z) Wait(0)
            end
            if cam==nextCam and requestSequence==cameraSequence and requestGeneration==sceneGeneration then
                SetCamCoord(nextCam,position.x,position.y,position.z)
                if cfg.rotation then StopCamPointing(nextCam) SetCamRot(nextCam,cfg.rotation.x+0.0,cfg.rotation.y+0.0,cfg.rotation.z+0.0,2)end
            end
        end)
    elseif oldCam and clearPath then
        transitioning[oldCam]=true SetCamActiveWithInterp(nextCam,oldCam,250,1,1)
        SetTimeout(300,function() if transitioning[oldCam] then if DoesCamExist(oldCam) then DestroyCam(oldCam,false) end transitioning[oldCam]=nil end end)
    else if oldCam and DoesCamExist(oldCam) then DestroyCam(oldCam,false) end end
    RenderScriptCams(true,false,0,true,false)
end
local function toggleFree()
    if freeChanging then return {free=freeCamera} end
    freeChanging=true
    local ok,result=pcall(function()
    local generation=sceneGeneration
    if not active or not WorkshopPresentation.session or not cam or not view or not exports['mx-freeroam-experience']:OwnsView(view) then return {free=false} end
    if freeCamera then freeFocus(false) camera(freeReturn,{slot=freeReturnData and freeReturnData.slot,orbitReturn=true,force=true}) return {free=false} end
    freeReturn=cameraContext freeReturnData=cameraData
    local startingCam,startingSequence,startingView=cam,cameraSequence,view
    local startingEditor=WorkshopPresentation.session
    local function current()
        return active and generation==sceneGeneration and cam==startingCam and cameraSequence==startingSequence and view==startingView and WorkshopPresentation.session==startingEditor and exports['mx-freeroam-experience']:OwnsView(view)
    end
    local car,width,length,height=geometry() local at=GetCamCoord(cam)
    local aim=ExperienceConfig.offset(car,0,0,height*ExperienceConfig.orbit.aimHeight)
    local horizontal=math.sqrt((at.x-aim.x)^2+(at.y-aim.y)^2)
    orbitState={yaw=math.atan(at.y-aim.y,at.x-aim.x),elevation=math.atan(at.z-aim.z,horizontal),distance=math.sqrt(horizontal^2+(at.z-aim.z)^2)}
    local position,target,distance,elevation=WorkshopFraming.orbit(car,width,length,height,orbitState.yaw,orbitState.elevation,orbitState.distance,GetAspectRatio(false))
    local test=StartShapeTestCapsule(target.x,target.y,target.z,position.x,position.y,position.z,.2,19,previewEntity,7)
    local deadline=GetGameTimer()+250 local status,hit
    repeat status,hit=GetShapeTestResult(test) if status==1 then Wait(0) end until status~=1 or GetGameTimer()>deadline
    if not current() then return {free=false} end
    MX.require(status==2 and hit==0,'CAMERA','Sem espaço para a câmera livre nesta direção')
    local travel=StartShapeTestCapsule(at.x,at.y,at.z,position.x,position.y,position.z,.15,19,previewEntity,7)
    deadline=GetGameTimer()+ExperienceConfig.orbit.queryTimeout
    repeat status,hit=GetShapeTestResult(travel) if status==1 then Wait(0) end until status~=1 or GetGameTimer()>deadline
    if not current() then return {free=false} end
    MX.require(status==2 and hit==0,'CAMERA','Sem espaço para mover a câmera livre nesta direção')
    orbitState.distance=distance orbitState.elevation=elevation
    -- Start outside the body when leaving the interior view, so collision does
    -- not trap the manual camera inside the cabin. Return still restores the part.

    if not current() then return {free=false} end
    cameraSequence=cameraSequence+1
    for old in pairs(transitioning) do if DoesCamExist(old) then DestroyCam(old,false) end transitioning[old]=nil end
    local oldCam=cam
    local nextCam=CreateCam('DEFAULT_SCRIPTED_CAMERA',true)
    SetCamFov(nextCam,ExperienceConfig.orbit.fov) SetCamCoord(nextCam,position.x,position.y,position.z) PointCamAtCoord(nextCam,target.x,target.y,target.z)
    cam=nextCam orbitMotion=WorkshopOrbit.new(position,target,orbitState)
    local duration=reduce and 0 or ExperienceConfig.orbit.transitionMs
    -- Interpolate the full pose/FOV instead of teleporting the existing camera.
    if duration>0 then
        transitioning[oldCam]=true SetCamActiveWithInterp(nextCam,oldCam,duration,1,1)
        SetTimeout(duration+50,function() if transitioning[oldCam] then if DoesCamExist(oldCam) then DestroyCam(oldCam,false) end transitioning[oldCam]=nil end end)
    elseif DoesCamExist(oldCam) then DestroyCam(oldCam,false) end
    freeFocus(true)
    return {free=true}
    end)
    freeChanging=false
    if not ok then error(result,0) end
    return result
end
RegisterCommand('mxworkshopcamera',function() if not IsNuiFocused() then toggleFree() end end,false)
local function scene(d)
    loading(d.context=='lobby' and 'Preparando o personagem e o lobby' or 'Preparando sua entrada na oficina')
    WorkshopDisplay.stop()
    unpause()
    WorkshopPresentation.stop()
    sceneGeneration=sceneGeneration+1
    local generation=sceneGeneration
    exports['mx-freeroam-experience']:SuspendDrivecam('workshop',true)
    -- Give the driver camera one frame to yield before acquiring presentation.
    Wait(0)
    DoScreenFadeOut(reduce and 0 or 150) Wait(reduce and 0 or 180)
    -- A blocked sightline in the new scene cannot fall back to the old location.
    removeCamera()
    local time=d.context=='lobby' and ExperienceConfig.lobbyTime or nil
    nightPreview=false lightPreview=false
    exports['mx-freeroam-world']:SetLobbyTime(time and time.hour,time and time.minute,time and ExperienceConfig.lobbyWeather)
    if not active then original={visible=IsEntityVisible(PlayerPedId()),alpha=GetEntityAlpha(PlayerPedId()),invincible=GetPlayerInvincible(PlayerId()),canRagdoll=CanPedRagdoll(PlayerPedId())} end
    WorkshopIdle.stop()
    active=true sceneContext=d.context or 'garage' previewEntity=0 previewId=nil token=d.token confirmed=d.appearance
    personPoint=MX.copy(d.point)
    local driven=GetVehiclePedIsIn(PlayerPedId(),false)
    if driven~=0 then
        TaskLeaveVehicle(PlayerPedId(),driven,16) local deadline=GetGameTimer()+3000
        while IsPedInAnyVehicle(PlayerPedId(),false) and GetGameTimer()<deadline do Wait(30) end
        MX.require(not IsPedInAnyVehicle(PlayerPedId(),false),'DRIVER','Não foi possível desembarcar')
    end
    Character.apply(d.appearance,true)
    MX.require(generation==sceneGeneration,'SESSION')
    if IsEntityDead(PlayerPedId()) then NetworkResurrectLocalPlayer(d.point.x,d.point.y,d.point.z,d.point.h,true,false) end
    local ready=WorkshopStreaming.prepare(d.point,sceneContext,function() return generation==sceneGeneration end)
    MX.require(generation==sceneGeneration,'SESSION')
    local ped=PlayerPedId() SetEntityVisible(ped,true,false) SetEntityInvincible(ped,true) SetEntityCollision(ped,true,true) SetPlayerControl(PlayerId(),false,0)
    TaskStandStill(ped,-1)
    camera('main')
    loading('Cenário pronto. Preparando o veículo e sincronizando sua sessão')
    -- Scene stays covered until its preview and character have been prepared.
    return {ready=true}
end
local function release(holdLobby)
    loading(nil)
    WorkshopDisplay.stop()
    WorkshopIdle.stop()
    WorkshopStreaming.stop()
    local time=holdLobby and ExperienceConfig.lobbyTime or nil
    nightPreview=false lightPreview=false
    exports['mx-freeroam-world']:SetLobbyTime(time and time.hour,time and time.minute,time and ExperienceConfig.lobbyWeather)
    lobby=holdLobby==true unpause()
    WorkshopPresentation.stop()
    freeFocus(false)
    if previewEntity~=0 and DoesEntityExist(previewEntity) and Entity(previewEntity).state.mxVehicle==previewId then SetVehicleDoorShut(previewEntity,4,false) end
    sceneGeneration=sceneGeneration+1 removeCamera()
    local ped=PlayerPedId() FreezeEntityPosition(ped,false) SetPlayerControl(PlayerId(),true,0)
    if not IsPedInAnyVehicle(ped,false) then ClearPedTasksImmediately(ped) end
    SetEntityCollision(ped,true,true)
    SetPedCanRagdoll(ped,original==nil or original.canRagdoll==true) SetEntityAlpha(ped,original and original.alpha or 255,false) SetEntityInvincible(ped,original and original.invincible or false) SetEntityVisible(ped,original==nil or original.visible,false)
    active=false token=nil SetNuiFocus(false,false)
    exports['mx-freeroam-experience']:SuspendDrivecam('workshop',false)
    exports['mx-freeroam-experience']:SuspendDrivecam('lobby',holdLobby==true)
    if holdLobby and lastLobbyData then TriggerEvent('mx:experience:lobby',lastLobbyData) else TriggerEvent('mx:experience:closed') end
    DoScreenFadeIn(200)
end
local function abortEntry(d)
    local hold=lobby and not played
    -- Invalidate a timed-out scene BEFORE rollback yields; a late loader must
    -- never reposition the player or acknowledge a scene after recovery.
    sceneGeneration=sceneGeneration+1
    WorkshopStreaming.stop()
    loading('Recuperando sua sessão')
    if hold and lastLobbyData then
        lastLobbyData.sceneReady=false
        lastLobbyData.error='A preparação do cenário não foi concluída. Tente novamente; os arquivos já carregados poderão ser reutilizados.'
    end
    if not active and not WorkshopTransfer.pending() then
        if hold then pause() else unpause() end
        loading(nil) DoScreenFadeIn(200)
        if hold and lastLobbyData then TriggerEvent('mx:experience:lobby',lastLobbyData) end
        return {recovered=not hold,held=hold}
    end
    WorkshopPresentation.stop()
    local result=WorkshopTransfer.restore(d and d.point)
    release(lobby)
    -- No public spawn has been completed on first join. Releasing the rollback
    -- snapshot into gameplay here can leave a new ped falling below the map.
    if hold then pause() result.recovered=false result.held=true end
    return result
end
MX.clients('experience',{
    developerCamera=WorkshopCameraDev.start,
    prepareEntry=WorkshopTransfer.begin,
    scene=scene,
    appearance=function(d) WorkshopPresentation.stop() local caps,changed=Character.apply(d.appearance) if active then if changed then placeCharacter() end SetEntityInvincible(PlayerPedId(),true) end return {capabilities=caps} end,
    confirmAppearance=function(d) confirmed=d.appearance return {} end,
    recoverUI=function(d) send(d.state) return {} end,
    previewChanged=function(d)
        WorkshopPresentation.stop() freeFocus(false)
        carDimensions=d.preview and d.preview.capabilities.dimensions
        previewEntity=d.preview and NetworkDoesEntityExistWithNetworkId(d.preview.net) and NetToVeh(d.preview.net) or 0
        previewId=d.preview and d.preview.id
        MX.require(not d.preview or (previewEntity~=0 and DoesEntityExist(previewEntity) and Entity(previewEntity).state.mxVehicle==previewId),'VEHICLE_SYNC','A prévia ainda não está sincronizada; reabra a garagem')
        placeCharacter() camera('main')
        if active and sceneContext=='garage'then WorkshopDisplay.start(token) WorkshopDisplay.preview(d.displayVehicle,d.displayCurrent)end
        loading(nil) DoScreenFadeIn(200) return {}
    end,
    fade=function()
        WorkshopDisplay.stop()
        DoScreenFadeOut(150) Wait(180)
        -- Detach the hidden presentation driver while its vehicle still exists.
        WorkshopPresentation.stop()
        return {ready=not IsPedInAnyVehicle(PlayerPedId(),false)}
    end,
    prepareExit=function(d) WorkshopIdle.stop() WorkshopPresentation.stop() local generation=sceneGeneration ClearPedTasksImmediately(PlayerPedId()) Character.apply(d.appearance) MX.require(generation==sceneGeneration,'SESSION') local ready=collision(d.point) MX.require(generation==sceneGeneration,'SESSION') return {ready=ready} end,
    -- Move the audio listener to the seated gameplay driver under the fade;
    -- controls remain blocked until the engine start acknowledgment.
    departureView=function() removeCamera() return {ready=true} end,
    finish=function() played=true release() return {} end,
    abort=abortEntry
})
local function showLobby()
    pause()
    exports['mx-freeroam-experience']:SuspendDrivecam('lobby',true)
    WorkshopPresentation.stop() freeFocus(false)
    lobby=true lobbyGeneration=lobbyGeneration+1 lobbyAcknowledged=false
    local generation=lobbyGeneration
    SendLoadingScreenMessage(json.encode({eventName='mxStage',message='Carregando configurações do lobby'}))
    local r=MX.request('experience','lobby',{})
    if r.ok then WorkshopTransfer.finish() end
    if generation~=lobbyGeneration or not lobby then return end
    local data=r.ok and r.data or {sceneReady=false,error=r.message or 'Não foi possível carregar o lobby. Tente novamente.'}
    data.generation=generation data.resume=played and not active data.initialLoading=initialLoading
    lastLobbyData=data
    TriggerEvent('mx:experience:lobby',data)
    -- NUI can still be mounting when the profile arrives. Retry delivery until
    -- the opaque lobby acknowledges two painted frames; never reveal the world.
    CreateThread(function()
        local deadline=GetGameTimer()+12000
        while lobby and generation==lobbyGeneration and not lobbyAcknowledged and GetGameTimer()<deadline do
            Wait(500)
            if lobby and generation==lobbyGeneration and not lobbyAcknowledged then TriggerEvent('mx:experience:lobby',data) end
        end
        if lobby and generation==lobbyGeneration and initialLoading and not lobbyAcknowledged then SendLoadingScreenMessage(json.encode({eventName='mxStage',error=true,message='A interface do lobby não respondeu'})) end
    end)
end
exports('ShowLobby',showLobby)
exports('LobbyReady',function(generation)
    -- ACKs are asynchronous UI receipts, not mutations: late/repeated ones are normal.
    if not lobby or generation~=lobbyGeneration then return {accepted=false,loadingClosed=false} end
    if lobbyAcknowledged then return {accepted=true,loadingClosed=not initialLoading} end
    lobbyAcknowledged=true
    if initialLoading then
        SendLoadingScreenMessage(json.encode({eventName='mxFadeOut',duration=reduce and 0 or 180}))
        Wait(reduce and 0 or 200)
        ShutdownLoadingScreen() ShutdownLoadingScreenNui()
        initialLoading=false
        if lastLobbyData then lastLobbyData.initialLoading=false end
    end
    local current=lobby and generation==lobbyGeneration
    if current then DoScreenFadeIn(0) end
    return {accepted=current,loadingClosed=not initialLoading}
end)
local function openGarage(action)
    local r=MX.request('experience',action,{})
    if r.ok then
        WorkshopTransfer.finish()
        camera((r.data.phase=='character' or r.data.phase=='characterRecovery') and 'character' or 'main')
        lobby=false lobbyGeneration=lobbyGeneration+1 exports['mx-freeroam-experience']:SuspendDrivecam('lobby',false) confirmed=r.data.appearance send(r.data)
    elseif WorkshopTransfer.pending() or active then abortEntry({})
    elseif not active and not lobby then unpause() end
    return r
end
exports('OpenGarage',function() return openGarage('enter') end)
exports('RecoverEntry',function() return abortEntry({}) end)
exports('EnterNearbyWorkshop',function() return openGarage('enterFromArea') end)
local function openLobby() if active and not lobby then SendNUIMessage({type='workshopLobby'}) return end if lobby then return end CreateThread(function() local ok,err=pcall(showLobby) if not ok then TriggerEvent('mx:notice',type(err)=='table' and err.message or 'Não foi possível abrir o lobby') end end) end
RegisterCommand('mxworkshop',openLobby,false)
RegisterKeyMapping('mxworkshop','MX: abrir lobby / garagem (parado)','keyboard','F6')
local started=false
AddEventHandler('mx:profile:local',function() if not started then started=true openLobby() end end)
AddEventHandler('mx:experience:open',openLobby)
CreateThread(function() Wait(25000) if not started then SendLoadingScreenMessage(json.encode({eventName='mxStage',message='Aguardando a sincronização do seu perfil. Na primeira entrada isso pode levar mais tempo.'})) end end)
exports('LocalAction',function(action,d)
    if action=='lobby' then showLobby() return {} end
    if action=='resume' then MX.require(lobby and played and not active,'LOBBY') lobby=false lobbyGeneration=lobbyGeneration+1 unpause() exports['mx-freeroam-experience']:SuspendDrivecam('lobby',false) TriggerEvent('mx:experience:closed') return {} end
    if action=='preferences' then return {reduceMotion=reduce} end
    if action=='reduceMotion' then reduce=d.value==true SetResourceKvpInt('mx:reduceMotion',reduce and 1 or 0) return {} end
    MX.require(active,'SESSION')
    -- A late editor cleanup must never reset the environment of the new lobby.
    if (action=='previewNight' or action=='previewLights' or action=='previewNeon') and sceneContext~='garage' then return {ignored=true} end
    if action=='previewNight' then
        nightPreview=d.enabled==true
        local time=nightPreview and ExperienceConfig.lobbyTime or nil
        exports['mx-freeroam-world']:SetLobbyTime(time and time.hour,time and time.minute)
        return {night=nightPreview}
    elseif action=='previewNeon' then return WorkshopPresentation.previewNeon(d)
    elseif action=='previewLights' then
        lightPreview=d.enabled==true
        if previewEntity~=0 and DoesEntityExist(previewEntity) then SetVehicleLights(previewEntity,lightPreview and 2 or 0) end
        return {enabled=lightPreview}
    end
    if action=='characterPreview' then local c,changed=Character.apply(d.appearance) if changed then placeCharacter() end SetEntityInvincible(PlayerPedId(),true) return {capabilities=c}
    elseif action=='characterCancel' then local _,changed=Character.apply(confirmed) if changed then placeCharacter() end return {capabilities=Character.capabilities()}
    elseif action=='characterPreset' then local a=ExperienceRules.preset(d.model,d.outfit) local c,changed=Character.apply(a) if changed then placeCharacter() end return {appearance=a,capabilities=c}
    elseif action=='capabilities' then return {capabilities=Character.capabilities()}
    elseif action=='characterAnchors' then
        if sceneContext~='garage' or WorkshopPresentation.session then return {anchors={}} end
        local generation=sceneGeneration local cameraVersion=cameraSequence Wait(300)
        if not active or generation~=sceneGeneration or cameraVersion~=cameraSequence then return {anchors={}} end
        return {anchors=Character.anchors()}
    elseif action=='vehicleOptions' then
        MX.require(previewEntity~=0 and DoesEntityExist(previewEntity) and Entity(previewEntity).state.mxVehicle==previewId,'VEHICLE')
        return exports['mx-freeroam-vehicles']:PresentationOptions({net=VehToNet(previewEntity),id=previewId,slot=d.slot})
    elseif action=='vehicleEditor' then
        if d.enabled then MX.require(MX.text(d.id,1,64) and previewEntity~=0,'SESSION') WorkshopPresentation.start(d.id,previewEntity,previewId,personPoint)
        elseif not WorkshopPresentation.session or WorkshopPresentation.session.id==d.id then
            local restore=freeCamera
            WorkshopPresentation.stop(d.id) freeFocus(false)
            if restore and active and cam then camera(freeReturn,{slot=freeReturnData and freeReturnData.slot,orbitReturn=true,force=true}) end
        end
        return {}
    elseif action=='stancePreview' then
        local s=WorkshopPresentation.session
        MX.require(s and s.id==d.id and s.vehicle==previewEntity and s.vehicleId==previewId,'SESSION')
        return {stance=exports['mx-freeroam-vehicles']:PreviewStance(s.vehicle,s.vehicleId,d.stance)}
    elseif action=='engineRev' then
        -- Keyboard NUI heartbeats must not overwrite a live analog trigger.
        if IsInputDisabled(0) then WorkshopPresentation.rev(d.id,d.pressed==true and not navigationModal) end
        return {}
    elseif action=='freeCamera' then return toggleFree()
    elseif action=='doors' then return WorkshopPresentation.toggleDoors(d.id)
    elseif action=='orbitInput' then
        MX.require(freeCamera and orbitState and orbitMotion,'CAMERA')
        if not WorkshopPresentation.session or d.id~=WorkshopPresentation.session.id then return {ignored=true} end
        MX.require(MX.number(d.sequence,1,2147483647,true),'CAMERA')
        if d.sequence<=(orbitMotion.inputSequence or 0) then return {ignored=true} end
        orbitMotion.inputSequence=d.sequence
        if d.stop then WorkshopOrbit.stop(orbitMotion,orbitState) return {} end
        MX.require(MX.number(d.yaw or 0,-.3,.3) and MX.number(d.pitch or 0,-.15,.15) and MX.number(d.zoom or 0,-1,1),'CAMERA')
        orbitState.yaw=orbitState.yaw+(d.yaw or 0) orbitState.elevation=orbitState.elevation+(d.pitch or 0) orbitState.distance=orbitState.distance+(d.zoom or 0) return {}
    elseif action=='camera' then camera(d.context,d) return {}
    elseif action=='observe' then
        MX.require(MX.number(d.angle,-0.45,0.45),'CAMERA')
        if not cam or not cameraBase then return {} end
        local b=cameraBase local dx,dy=b.position.x-b.target.x,b.position.y-b.target.y
        local ownCam=cam local ownGeneration=sceneGeneration
        local x=b.target.x+dx*math.cos(d.angle)-dy*math.sin(d.angle) local y=b.target.y+dx*math.sin(d.angle)+dy*math.cos(d.angle)
        local test=StartShapeTestCapsule(b.target.x,b.target.y,b.target.z,x,y,b.position.z,0.2,19,previewEntity,7)
        local deadline=GetGameTimer()+250 local status,hit
        repeat status,hit=GetShapeTestResult(test) if status==1 then Wait(0) end until status~=1 or GetGameTimer()>deadline
        if status==2 and hit==0 and cam==ownCam and sceneGeneration==ownGeneration then orbit=d.angle SetCamCoord(cam,x,y,b.position.z) end return {}
    end MX.fail('ACTION')
end)
CreateThread(function()
    while true do
        if active and personPoint.groundZ then
            local editor=WorkshopPresentation.session
            local actor=editor and editor.clone or PlayerPedId()
            WorkshopIdle.update(actor,sceneContext,not navigationModal and cameraContext~='face' and cameraContext~='character')
        else WorkshopIdle.stop() end
        if lobby then
            Wait(0) HideHudAndRadarThisFrame() DisableAllControlActions(0)
            if active then
                local p=ExperienceConfig.lobbyScene.car
                DrawLightWithRange(p.x+2,p.y+1,p.z+3,235,240,255,12.0,2.0)
                DrawLightWithRange(personPoint.x+1,personPoint.y-1,personPoint.z+2,255,235,215,5.0,1.3)
            end
        elseif active then
            Wait(0) HideHudAndRadarThisFrame() DisableAllControlActions(0)
            if sceneContext=='garage'then WorkshopDisplay.tick()end
            local editor=WorkshopPresentation.session
            if editor then
                local keyboard=IsInputDisabled(0)
                if editor.keyboard~=keyboard then editor.keyboard=keyboard WorkshopPresentation.rev(editor.id,false) TriggerEvent('mx:experience:input',{type='workshopInputDevice',device=keyboard and 'keyboard' or 'gamepad',style=ExperienceConfig.controllerIcons}) end
                if navigationModal then WorkshopPresentation.rev(editor.id,false) end
                if not keyboard and not navigationModal then
                    -- SCRIPT_RT is independent of the vehicle throttle we inject (71).
                    WorkshopPresentation.rev(editor.id,GetDisabledControlNormal(0,229))
                    if freeCamera and orbitState then
                        local x,y=GetDisabledControlNormal(0,220),GetDisabledControlNormal(0,221)
                        local dt=math.min(GetFrameTime(),.05)
                        if math.abs(x)>.15 then orbitState.yaw=orbitState.yaw-x*dt*1.8 end
                        if math.abs(y)>.15 then orbitState.elevation=orbitState.elevation+y*dt*.8 end
                        local zoom=GetDisabledControlNormal(0,219)
                        if math.abs(zoom)>.2 then orbitState.distance=orbitState.distance+zoom*dt*3.0 end
                    end
                end
            end
            WorkshopPresentation.tick(math.min(GetFrameTime(),0.05))
            if lightPreview and previewEntity~=0 and DoesEntityExist(previewEntity) then SetVehicleLights(previewEntity,2) end
            -- World ambient light is left intact; a local fill makes paint/face readable.
            local p=ExperienceConfig.scene.car DrawLightWithRange(p.x+2,p.y+1,p.z+3,235,240,255,12.0,2.0)
            local person=personPoint DrawLightWithRange(person.x+1,person.y-1,person.z+2,255,235,215,5.0,1.3)
            if not WorkshopCameraDev.session and freeCamera and orbitState and orbitMotion and cam and view and exports['mx-freeroam-experience']:OwnsView(view) then
                local car,width,length,height=geometry()
                local position,target=WorkshopOrbit.step(orbitMotion,car,width,length,height,orbitState,previewEntity,math.min(GetFrameTime(),.05))
                SetCamCoord(cam,position.x,position.y,position.z) PointCamAtCoord(cam,target.x,target.y,target.z)
            end
        else Wait(250) end
    end
end)
RegisterCommand('mxworkshopdebug',function()
    local s=WorkshopPresentation.session
    local data={active=active,editor=s~=nil,orbit=freeCamera,driverVisible=IsEntityVisible(PlayerPedId()),driverAlpha=GetEntityAlpha(PlayerPedId())}
    if cam and DoesCamExist(cam) then local p=GetCamCoord(cam) data.camera={context=cameraContext,fov=GetCamFov(cam),position={x=p.x,y=p.y,z=p.z}} end
    data.actorPoint=personPoint
    local idle=WorkshopIdle.session
    data.idle=idle and {sex=idle.sex,context=idle.context,actor=idle.ped,dict=idle.current and idle.current.dict,clip=idle.current and idle.current.clip} or false
    if s and DoesEntityExist(s.vehicle) and Entity(s.vehicle).state.mxVehicle==s.vehicleId then
        local p=GetEntityCoords(s.vehicle)
        data.rpm=GetVehicleCurrentRpm(s.vehicle) data.speed=GetEntitySpeed(s.vehicle) data.heading=GetEntityHeading(s.vehicle) data.position={x=p.x,y=p.y,z=p.z}
        data.externalVisible=s.clone and DoesEntityExist(s.clone) and IsEntityVisible(s.clone) or false
    end
    print(json.encode(data))
end,false)
WorkshopCameraDev.hooks={
    valid=function(s)return active and cam==s.cam and sceneGeneration==s.generation and view==s.view and exports['mx-freeroam-experience']:OwnsView(view)end,
    begin=function()
        if not active or not cam or not view or not exports['mx-freeroam-experience']:OwnsView(view)then return end
        -- Capture the image on screen BEFORE cancelling interpolation. The target
        -- handle can already contain a different pose/FOV from the rendered view.
        local p,r,fov=GetFinalRenderedCamCoord(),GetFinalRenderedCamRot(2),GetFinalRenderedCamFov()
        freeFocus(false) cameraSequence=cameraSequence+1
        for old in pairs(transitioning)do if DoesCamExist(old)then DestroyCam(old,false)end transitioning[old]=nil end
        local oldCam=cam
        cam=CreateCam('DEFAULT_SCRIPTED_CAMERA',false)
        SetCamCoord(cam,p.x+0.0,p.y+0.0,p.z+0.0)
        SetCamRot(cam,r.x+0.0,r.y+0.0,r.z+0.0,2) SetCamFov(cam,fov+0.0)
        SetCamActive(cam,true) RenderScriptCams(true,false,0,true,false)
        if DoesCamExist(oldCam)then DestroyCam(oldCam,false)end
        return {cam=cam,view=view,generation=sceneGeneration,context=sceneContext,viewName=cameraContext or 'main',target=cameraBase and cameraBase.target}
    end
}
WorkshopDisplay.hooks={
    token=function()return token end,
    valid=function(value)return active and sceneContext=='garage' and token~=nil and token==value end,
}
AddEventHandler('onClientResourceStop',function(r) if r==GetCurrentResourceName() then release() elseif (r=='mx-freeroam-menu' or r=='mx-freeroam-vehicles') and (active or lobby) then release() TriggerServerEvent('mx:experience:uiStopped') end end)
