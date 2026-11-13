-- Temporary authoring camera. The scene owns its native handle and view token.
WorkshopCameraDev={session=nil}
local D=WorkshopCameraDev
local function emit(open,data)TriggerEvent('mx:experience:cameraDeveloper',{open=open,data=data})end
local function valid(s)return D.hooks and D.hooks.valid(s) and DoesCamExist(s.cam)end
local function pose(cam)
    local p,r=GetCamCoord(cam),GetCamRot(cam,2)
    return {position={x=p.x,y=p.y,z=p.z},rotation={x=r.x,y=r.y,z=r.z},fov=GetCamFov(cam)}
end
local function apply(s,p)
    local previous=s.applied
    local function changed(key)
        if not previous then return true end
        local a,b=previous[key],p[key]
        return a.x~=b.x or a.y~=b.y or a.z~=b.z
    end
    if changed('position')then SetCamCoord(s.cam,p.position.x+0.0,p.position.y+0.0,p.position.z+0.0)end
    if changed('rotation')then
        StopCamPointing(s.cam)
        SetCamRot(s.cam,p.rotation.x+0.0,p.rotation.y+0.0,p.rotation.z+0.0,2)
    end
    if not previous or previous.fov~=p.fov then SetCamFov(s.cam,p.fov+0.0)end
    s.applied=MX.copy(p)
end
function D.stop(restore)
    local s=D.session if not s then return end D.session=nil
    if restore and valid(s) then apply(s,s.original) end
    TriggerServerEvent('mx:admin:cameraEditorClosed')
    emit(false)
end
function D.snapshot()
    local s=D.session MX.require(s and valid(s) and GetGameTimer()<s.expires,'SESSION','O editor de câmera expirou ou a cena mudou')
    local p=pose(s.cam) p.context=s.context p.view=s.viewName
    local pitch,yaw=math.rad(p.rotation.x),math.rad(p.rotation.z)
    p.look={x=p.position.x-math.sin(yaw)*math.cos(pitch)*s.distance,y=p.position.y+math.cos(yaw)*math.cos(pitch)*s.distance,z=p.position.z+math.sin(pitch)*s.distance}
    return p
end
function D.start(d)
    if not d.enabled then D.stop(true) return {enabled=false} end
    D.stop(true)
    MX.require(D.hooks,'CAMERA','Cena indisponível')
    local s=D.hooks.begin()
    MX.require(s and valid(s),'CAMERA','Abra o lobby ou a garagem e aguarde a câmera antes de editar')
    s.original=pose(s.cam) s.applied=MX.copy(s.original) s.expires=GetGameTimer()+6000
    s.distance=math.max(.5,s.target and MX.distance(s.original.position,s.target) or 5)
    D.session=s local result=D.snapshot() emit(true,result) return {enabled=true}
end
function D.action(d)
    local s=D.session
    MX.require(s and valid(s) and GetGameTimer()<s.expires,'SESSION','O editor de câmera expirou ou a cena mudou')
    if d.action=='close' then D.stop(d.restore~=false) return {} end
    if d.action=='reset' then apply(s,s.original) return D.snapshot() end
    if d.action=='snapshot' then return D.snapshot()end
    if d.action=='capture' then
        local p=D.snapshot()
        p.text=('{context=%q, view=%q, position={x=%.3f, y=%.3f, z=%.3f}, rotation={x=%.2f, y=%.2f, z=%.2f}, look={x=%.3f, y=%.3f, z=%.3f}, fov=%.2f}'):format(p.context,p.view,p.position.x,p.position.y,p.position.z,p.rotation.x,p.rotation.y,p.rotation.z,p.look.x,p.look.y,p.look.z,p.fov)
        print('[MX:CAMERA] '..p.text) return p
    end
    MX.require(d.action=='update' and MX.keys(d.pose,{position=true,rotation=true,fov=true}),'PAYLOAD')
    local p=d.pose
    MX.require(MX.keys(p.position,{x=true,y=true,z=true}) and MX.keys(p.rotation,{x=true,y=true,z=true}),'PAYLOAD')
    MX.require(MX.number(p.position.x,-20000,20000) and MX.number(p.position.y,-20000,20000) and MX.number(p.position.z,-100,3000) and MX.distance(p.position,s.original.position)<=100,'CAMERA','Mantenha a câmera até 100 m do ponto inicial')
    MX.require(MX.number(p.rotation.x,-89,89) and MX.number(p.rotation.y,-180,180) and MX.number(p.rotation.z,-360,360) and MX.number(p.fov,15,100),'CAMERA','Rotação ou FOV fora do limite')
    apply(s,p) return D.snapshot()
end
exports('DeveloperCamera',D.action)
RegisterNetEvent('mx:experience:cameraDeveloperGrant',function(enabled)
    if source~=65535 then return end
    if not enabled then D.stop(true) elseif D.session then D.session.expires=GetGameTimer()+6000 end
end)
CreateThread(function()while true do Wait(250)local s=D.session if s and (not valid(s) or GetGameTimer()>=s.expires)then D.stop(true)end end end)
RegisterCommand('mxcamedit',function()
    CreateThread(function()
        local response=MX.request('admin','cameraEditor',{enabled=D.session==nil})
        if not response.ok then TriggerEvent('mx:notice',response.message or 'Editor indisponível')end
    end)
end,false)
AddEventHandler('onClientResourceStop',function(name)if name==GetCurrentResourceName()or name=='mx-freeroam-menu'then D.stop(true)end end)
