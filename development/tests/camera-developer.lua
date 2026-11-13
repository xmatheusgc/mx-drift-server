local T,D,A=AdminToolTest,WorkshopCameraDev,AdminTools local count=0
local function check(ok,label)assert(ok,label)count=count+1 end
local function reject(fn,code)local ok,err=pcall(fn)check(not ok and MX.error(err).code==code,'expected '..code)end
T.cam={position={x=135,y=-3030,z=8},rotation={x=-5,y=0,z=90},fov=60} T.writes=0 T.sceneActive=true T.viewOwned=true
function DoesCamExist(cam)return cam==99 end
function GetCamCoord()return MX.copy(T.cam.position)end
function GetCamRot()return MX.copy(T.cam.rotation)end
function GetCamFov()return T.cam.fov end
function StopCamPointing()T.pointingStopped=true end
function SetCamCoord(_,x,y,z)T.writes=T.writes+1 T.cam.position={x=x,y=y,z=z}end
function SetCamRot(_,x,y,z)T.rotationWrites=(T.rotationWrites or 0)+1 T.cam.rotation={x=x,y=y,z=z}end
function SetCamFov(_,value)T.fovWrites=(T.fovWrites or 0)+1 T.cam.fov=value end
function TriggerServerEvent(name)local old=source source=1 if T.events[name]then T.events[name]()end source=old end
D.hooks={valid=function(s)return T.sceneActive and T.viewOwned and s.cam==99 end,begin=function()if not T.sceneActive then return end return {cam=99,context='lobby',viewName='main',target={x=130,y=-3030,z=8}}end}
T.callbacks.experience={developerCamera=D.start}
T.private=true T.bucket=10001
reject(function()A.editor(1,{enabled=true})end,'FORBIDDEN')
T.ace['mx.admin']=true T.ace['mx.inspect']=true
check(A.editor(1,{enabled=true}).enabled and D.session and A.editors[1],'authorized authoring works in private lobby without public trainer guards')
local snapshot=D.snapshot()check(snapshot.context=='lobby'and snapshot.fov==60,'starts from actual current camera')
local original=MX.copy(T.cam)
local tiny=MX.copy(original)tiny.position.x=tiny.position.x+.01
D.action({action='update',pose=tiny})
check(math.abs(T.cam.position.x-original.position.x-.01)<.00001 and not T.rotationWrites and not T.fovWrites,'one-centimeter position edit never rewrites orientation or zoom')
D.action({action='reset'})
local desired={position={x=136,y=-3031,z=7.5},rotation={x=-10,y=3,z=120},fov=48}
local result=D.action({action='update',pose=desired})check(result.position.x==136 and result.rotation.y==3 and result.fov==48 and T.pointingStopped,'updates position, roll, gaze and FOV after releasing point-at native')
local exported=D.action({action='capture'})
check(exported.text:find('position=',1,true)and exported.text:find('rotation=',1,true)and exported.text:find('look=',1,true)and exported.text:find('fov=48.00',1,true),'Lua capture includes all values needed to reproduce view')
local code=load('return '..exported.text)check(code and code().context=='lobby','capture is valid Lua data')
check(math.abs(MX.distance(result.position,exported.look)-5)<.001,'look target follows current rotation and original aim distance')
local bad=MX.copy(desired)bad.position.x=10000 reject(function()D.action({action='update',pose=bad})end,'CAMERA')
check(T.cam.position.x==136,'rejected movement does not mutate camera')
bad=MX.copy(desired)bad.rotation.x=90 reject(function()D.action({action='update',pose=bad})end,'CAMERA')
bad=MX.copy(desired)bad.fov=0/0 reject(function()D.action({action='update',pose=bad})end,'CAMERA')
bad=MX.copy(desired)bad.position.entity=123 reject(function()D.action({action='update',pose=bad})end,'PAYLOAD')
D.action({action='reset'})check(T.cam.position.x==original.position.x and T.cam.fov==60 and D.session,'reset restores initial view while keeping editor open')
D.action({action='update',pose=desired})D.action({action='close',restore=false})
check(not D.session and T.cam.fov==48 and not A.editors[1],'keeping preview releases editor and server subscription without writing config')
A.editor(1,{enabled=true})D.action({action='update',pose={position={x=137,y=-3031,z=8},rotation={x=0,y=0,z=0},fov=70}})D.action({action='close',restore=true})
check(T.cam.position.x==136 and T.cam.fov==48,'restore returns to view present at this activation')
A.editor(1,{enabled=true})T.time=2000 A.refresh()check(D.session.expires==8000,'server renews only current authorized editor')
source=1 T.events['mx:experience:cameraDeveloperGrant'](false)check(D.session~=nil,'local forged grant cannot cancel server-owned lease')
T.ace['mx.inspect']=false A.refresh()check(not D.session and not A.editors[1],'permission revocation restores and closes editor')T.ace['mx.inspect']=true
A.editor(1,{enabled=true})T.time=8000 reject(function()D.action({action='capture'})end,'SESSION')D.stop(true)
check(not D.session,'expired session cannot apply camera updates')
A.editor(1,{enabled=true})T.sceneActive=false local writes=T.writes D.stop(true)
check(T.writes==writes,'stale scene cannot restore over a newer scene camera')
reject(function()A.editor(1,{enabled=true})end,'CAMERA')T.sceneActive=true
A.editor(1,{enabled=true})T.viewOwned=false writes=T.writes D.stop(true)check(T.writes==writes,'lost camera ownership never mutates another view')T.viewOwned=true
print(count..' camera developer checks passed: private-scene authorization, current native pose, Lua capture, bounds, reset/keep/restore, leases and stale ownership (adapters; no game).')
