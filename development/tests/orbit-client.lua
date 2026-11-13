-- Exercise real LocalAction/toggleFree with explicit camera-native adapters.
local E=LobbyAckTest.exports
local function context(name,value,write)
    local seen={}
    local function find(fn)
        if seen[fn] then return end seen[fn]=true
        for i=1,60 do local key=debug.getupvalue(fn,i) if not key then break end
            if key==name then return fn,i end
        end
        for i=1,60 do local key,v=debug.getupvalue(fn,i) if not key then break end
            if type(v)=='function' then local owner,index=find(v) if owner then return owner,index end end
        end
    end
    local owner,index=find(E.LocalAction) assert(owner,'missing client context '..name)
    local _,v=debug.getupvalue(owner,index) if write then debug.setupvalue(owner,index,value) end return v
end
local cams,nextCam,interpolations,timeouts={},70,{},{}
local car=ExperienceConfig.presentation
cams[70]={position={x=car.x+6,y=car.y,z=car.z+2},fov=50}
function DoesCamExist(id)return cams[id]~=nil end
function GetCamCoord(id)return cams[id].position end
function GetAspectRatio()return 16/9 end
function CreateCam()nextCam=nextCam+1 cams[nextCam]={} return nextCam end
function SetCamCoord(id,x,y,z)cams[id].position={x=x,y=y,z=z}end
function SetCamFov(id,fov)cams[id].fov=fov end
function SetCamRot(id,x,y,z)cams[id].rotation={x=x,y=y,z=z}end
function PointCamAtCoord()end
function SetCamActiveWithInterp(to,from,ms)interpolations[#interpolations+1]={to=to,from=from,ms=ms}end
function SetTimeout(ms,fn)timeouts[#timeouts+1]={ms=ms,fn=fn}end
function DestroyCam(id)cams[id]=nil end
function RenderScriptCams()end
function StartShapeTestCapsule()return 1 end
function GetShapeTestResult()return 2,0 end
local views=exports['mx-freeroam-experience']
views.OwnsView=function()return true end
context('active',true,true) context('cam',70,true) context('view','orbit-test',true)
context('sceneContext','garage',true) context('previewEntity',0,true)
WorkshopPresentation.session=nil
assert(not E.LocalAction('freeCamera',{}).free,'free camera is unavailable outside vehicle customization')
WorkshopPresentation.session={id='orbit-test'}
local original=cams[70].position
assert(E.LocalAction('freeCamera',{}).free and E.FreeCameraActive(),'editor can enable free orbit')
assert(#interpolations==1 and interpolations[1].ms==350 and interpolations[1].from==70,'activation uses interpolated camera instead of teleport')
assert(cams[70].position==original and cams[71].fov==ExperienceConfig.orbit.fov,'activation preserves source camera pose and eases toward orbit FOV')
E.LocalAction('orbitInput',{id='orbit-test',sequence=1,yaw=.3})
E.LocalAction('orbitInput',{id='orbit-test',sequence=3,stop=true})
local input=context('orbitState') local stopped=input.yaw
assert(E.LocalAction('orbitInput',{id='orbit-test',sequence=2,yaw=.3}).ignored and input.yaw==stopped,'late movement cannot replay after a newer stop')
assert(E.LocalAction('orbitInput',{id='previous-editor',sequence=4,yaw=.3}).ignored,'previous editor cannot move current camera')
local created=nextCam
E.LocalAction('camera',{context='part',slot=2})
assert(nextCam==created and E.FreeCameraActive(),'piece camera request cannot replace manual orbit')
local stop=WorkshopPresentation.stop
WorkshopPresentation.stop=function()WorkshopPresentation.session=nil end
E.LocalAction('vehicleEditor',{id='orbit-test',enabled=false})
assert(not E.FreeCameraActive(),'leaving customization disables free camera automatically')
assert(not pcall(E.LocalAction,'orbitInput',{yaw=.1}),'late drag after leaving cannot move a released camera')
WorkshopPresentation.stop=stop
E.LocalAction('camera',{context='main',force=true})
assert(cams[nextCam].fov==ExperienceConfig.camera.fov,'main camera native FOV matches the scene FOV used for projection')
assert(cams[nextCam].position.x==138.5 and cams[nextCam].position.y==-3025.5 and cams[nextCam].position.z==7.2 and cams[nextCam].rotation.x==-2 and cams[nextCam].rotation.z==141,'garage main uses the exact authored pose')
context('sceneContext','lobby',true)
E.LocalAction('camera',{context='main',force=true})
assert(cams[nextCam].position.x==-944.5 and cams[nextCam].position.y==-3535.3 and cams[nextCam].position.z==14.5 and cams[nextCam].rotation.x==-2 and cams[nextCam].rotation.z==51 and cams[nextCam].fov==73.5,'lobby main uses the exact authored pose and FOV')
context('sceneContext','garage',true)
-- A scene change during collision validation cannot install the old camera.
WorkshopPresentation.session={id='orbit-stale'}
local changed=false
function GetShapeTestResult()if not changed then changed=true context('active',false,true) end return 2,0 end
created=nextCam
assert(not E.LocalAction('freeCamera',{}).free and nextCam==created,'late activation cannot publish after scene release')
-- Developer handoff must preserve the image mid-transition, rather than the
-- destination handle's future pose or its point-at rotation.
context('active',true,true)
local rendered={position={x=132,y=-3033,z=7.2},rotation={x=-8,y=1,z=42},fov=57.5}
function GetFinalRenderedCamCoord()return rendered.position end
function GetFinalRenderedCamRot(order)assert(order==2)return rendered.rotation end
function GetFinalRenderedCamFov()return rendered.fov end
function SetCamRot(id,x,y,z)cams[id].rotation={x=x,y=y,z=z}end
function SetCamActive(id,active)cams[id].active=active end
local old=context('cam')
local s=WorkshopCameraDev.hooks.begin()
assert(s.cam~=old and not cams[old] and cams[s.cam].active,'developer owns a fresh camera with no point-at or interpolation')
assert(cams[s.cam].position.x==132 and cams[s.cam].rotation.z==42 and cams[s.cam].fov==57.5,'handoff uses the rendered position, orientation and FOV without a first-edit jump')
local previousVehicles=exports['mx-freeroam-vehicles']
local previews=0
exports['mx-freeroam-vehicles']={PreviewStance=function(_,v,id,value)
 assert(v==10 and id=='fast-preview' and value.height==.04)previews=previews+1 return {value=value}
end}
context('previewEntity',10,true) context('previewId','fast-preview',true)
WorkshopPresentation.session={id='fast-editor',vehicle=10,vehicleId='fast-preview'}
assert(not pcall(E.LocalAction,'stancePreview',{id='old-editor',stance={height=.04}}),'stale editor cannot use local stance preview')
assert(E.LocalAction('stancePreview',{id='fast-editor',stance={height=.04}}).stance.value.height==.04 and previews==1,'current presentation can preview only its own stance')
context('previewId','new-preview',true)
assert(not pcall(E.LocalAction,'stancePreview',{id='fast-editor',stance={height=.04}}),'replaced preview cannot receive old slider updates')
exports['mx-freeroam-vehicles']=previousVehicles
WorkshopPresentation.session=nil
context('active',false,true) context('cam',nil,true) context('view',nil,true)
print('Real client orbit checks passed: transition, stale activation, ordered stop, editor identity and exit cleanup; native adapters, no game.')
