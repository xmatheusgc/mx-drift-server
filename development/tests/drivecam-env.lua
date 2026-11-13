local mt={}
function vector3(x,y,z)return setmetatable({x=x,y=y,z=z},mt)end
mt.__add=function(a,b)return vector3(a.x+b.x,a.y+b.y,a.z+b.z)end
mt.__sub=function(a,b)return vector3(a.x-b.x,a.y-b.y,a.z-b.z)end
mt.__mul=function(a,b)return vector3(a.x*b,a.y*b,a.z*b)end
mt.__div=function(a,b)return vector3(a.x/b,a.y/b,a.z/b)end
mt.__len=function(a)return math.sqrt(a.x*a.x+a.y*a.y+a.z*a.z)end
T={now=1000,position=vector3(0,0,0),velocity=vector3(0,20,0),vehicle=7,driver=true,created=0,destroyed=0,renders={},queries={},nextQuery=0,commands={},handlers={},api={},owner=nil}
local chaseStep=DrivecamChase.step
DrivecamChase.step=function(state,sample,...)
    T.pivotBack=sample.pivotBack
    return chaseStep(state,sample,...)
end
MX={online=function()return true end}
local coordinator={}
function coordinator:DrivecamSuspended()return T.suspended end
function coordinator:AcquireView()if T.owner then return nil end T.token=(T.token or 0)+1 T.owner=T.token return T.owner end
function coordinator:OwnsView(token)return token==T.owner end
function coordinator:ReleaseView(token)if token==T.owner then T.owner=nil end end
exports=setmetatable({['mx-freeroam-experience']=coordinator},{__call=function(_,name,fn)T.api[name]=fn end})
function GetResourceKvpString()return nil end
json={encode=function()return 'preference' end}
function SetResourceKvp()T.persisted=true end
function TriggerEvent()end
function RegisterCommand(name,fn)T.commands[name]=fn end
function RegisterKeyMapping(_,_,_,key)assert(key=='F7')end
function AddEventHandler(name,fn)T.handlers[name]=fn end
function GetResourceState()return 'started' end
function GetCurrentResourceName()return 'mx-freeroam-drivecam' end
function GetConvarInt(_,default)return default end
function IsPauseMenuActive()return T.pause end
function IsNuiFocused()return T.nui end
function NetworkIsInSpectatorMode()return T.spectator end
function IsEntityDead()return T.dead end
function PlayerPedId()return 1 end
function GetVehiclePedIsIn()return T.vehicle end
function GetPedInVehicleSeat()return T.driver and 1 or 2 end
function IsThisModelACar()return true end
function GetEntityModel(v)return v end
function GetGameTimer()return T.now end
function GetEntityCoords()return T.position end
function GetEntityVelocity()return T.velocity end
function GetEntityMatrix()
    local slope=T.slope or 0
    return vector3(0,math.cos(slope),math.sin(slope)),vector3(1,0,0),vector3(0,-math.sin(slope),math.cos(slope)),T.position
end
function GetModelDimensions()return vector3(-1,-2,-.5),vector3(1,2,1)end
function GetEntityBoneIndexByName(_,name)
    if not T.bones then return -1 end
    return ({wheel_lf=1,wheel_rf=2,wheel_lr=3,wheel_rr=4})[name] or -1
end
function GetWorldPositionOfEntityBone(_,index)
    assert(T.bones,'missing bones must not be sampled')T.boneReads=(T.boneReads or 0)+1
    return T.position+vector3(index%2==1 and -.8 or .8,index<3 and 1.5 or -1.5,-.3)
end
function GetOffsetFromEntityGivenWorldCoords(_,x,y,z)return vector3(x,y,z)-T.position end
function GetOffsetFromEntityInWorldCoords(_,x,y,z)
    local slope=T.slope or 0
    return T.position+vector3(x,y*math.cos(slope)-z*math.sin(slope),y*math.sin(slope)+z*math.cos(slope))
end
function IsInputDisabled()return true end
function DisableControlAction()end
function GetDisabledControlNormal(_,key)return key==1 and (T.mouse or 0) or 0 end
function IsControlPressed()return T.back end
function StartShapeTestCapsule(x,y,z,tx,ty,tz)
    T.nextQuery=T.nextQuery+1 T.queries[T.nextQuery]={origin=vector3(x,y,z),target=vector3(tx,ty,tz)} return T.nextQuery
end
function GetShapeTestResult(handle)
    if T.pending then return 1,0,vector3(0,0,0)end
    local q=T.queries[handle] local ray=q.target-q.origin
    local hit=T.boolHit and (T.hit~=nil) or (T.hit and 1 or 0)
    return 2,hit,T.hit and q.origin+ray/#ray*T.hit or q.target
end
function CreateCam()T.created=T.created+1 return T.created end
function DestroyCam()T.destroyed=T.destroyed+1 end
function RenderScriptCams(active)T.renders[#T.renders+1]=active T.rendering=active end
function SetCamCoord(_,x,y,z)T.camera=vector3(x,y,z)end
function SetCamRot(_,x,y,z,order)assert(order==2)T.rotation={x=x,y=y,z=z}end
function SetCamFov(_,fov)T.fov=fov end
function Wait()coroutine.yield()end
function CreateThread(fn)T.thread=coroutine.create(fn)assert(coroutine.resume(T.thread))end
function T.step(frames,ms)
    ms=ms or 16
    for _=1,frames do
        T.now=T.now+ms T.position=T.position+T.velocity*(ms/1000)
        local ok,err=coroutine.resume(T.thread)assert(ok,err)
    end
end
