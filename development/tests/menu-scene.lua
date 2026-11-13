local T,I,C,F=ScenePoseTest,WorkshopIdle,ExperienceConfig,WorkshopFraming local n=0
local function check(ok,label)assert(ok,label)n=n+1 end
local function close(a,b)return math.abs(a-b)<.00001 end
check(C.scene.ped.x==133.303 and C.scene.ped.y==-3027.849 and C.scene.ped.z==7.041 and C.scene.ped.h==276.85,'authored garage actor pose')
check(C.lobbyScene.ped.x==-947.610 and C.lobbyScene.ped.y==-3530.367 and C.lobbyScene.ped.z==14.618 and C.lobbyScene.ped.h==185.96,'authored lobby actor pose')
check(C.scene.car.x==135.962 and C.scene.car.y==-3030.353 and C.scene.car.z==6.396 and C.scene.car.h==.11,'authored garage car pose')
check(C.lobbyScene.car.x==-949.431 and C.lobbyScene.car.y==-3533.159 and C.lobbyScene.car.z==13.953 and C.lobbyScene.car.h==280.67,'authored lobby car pose')
check(C.exit.x==163.2 and C.exit.h==268.29,'gameplay exit stays independently configured')
for _,context in ipairs({'garage','lobby'})do
 local scene=context=='lobby'and C.lobbyScene or C.scene
 for _,aspect in ipairs({1280/720,1920/1080,2560/1440,3440/1440})do
  local position,target=F.scene(scene.car,scene.ped,2,4.6,aspect,context,1.4)
  check(close(position.z,scene.car.z+.85),'main camera stays at authored low height')
  local old=F.main(scene.car,2,4.6,aspect)
  check(MX.distance(position,scene.car)<(context=='lobby'and 7.6 or MX.distance(old,scene.car)),'normal car camera is closer than previous composition')
  local vx,vy,vz=target.x-position.x,target.y-position.y,target.z-position.z local norm=math.sqrt(vx*vx+vy*vy+vz*vz)vx,vy,vz=vx/norm,vy/norm,vz/norm
  local flat=math.sqrt(vx*vx+vy*vy)local rx,ry=vy/flat,-vx/flat
  local function inside(p)
   local x,y,z=p.x-position.x,p.y-position.y,p.z-position.z local depth=x*vx+y*vy+z*vz
   return depth>0 and math.abs(x*rx+y*ry)<depth*math.tan(math.rad(60)/2)*aspect and math.abs(x*ry*vz-y*rx*vz+z*flat)<depth*math.tan(math.rad(60)/2)
  end
  check(inside({x=scene.ped.x,y=scene.ped.y,z=scene.ped.z+.9})and inside({x=scene.ped.x,y=scene.ped.y,z=scene.ped.z-.9}),'actor upper/lower bounds fit the close view')
  for _,f in ipairs({-2.3,2.3})do for _,r in ipairs({-1,1})do for _,h in ipairs({0,1.4})do check(inside(C.offset(scene.car,f,r,h)),'car corners fit main view')end end end
 end
 local before=T.bones local p=WorkshopPresentation.ground(1,scene.ped,scene.car.z-1)
 check(p.x==scene.ped.x and p.y==scene.ped.y and p.z==scene.ped.z and p.h==scene.ped.h and p.fixed,'ground confirmation cannot overwrite explicit actor XYZ/heading')
 check(T.bones==before,'authored Z does not depend on a transient animated foot bone')
end
math.randomseed(42)
I.update(1,'lobby',true)T.time=250 I.update(1,'lobby',true)
local first=T.plays[#T.plays]
check(first and first.ped==1 and first.dict:find('male',1,true)and not first.dict:find('female',1,true),'male pool selected from actual ped')
check(first.flag==1 and first.lock and first.blend==1.5,'loop blends without extracted translation')
T.time=I.session.nextAt I.update(1,'lobby',true)T.time=T.time+250 I.update(1,'lobby',true)
check(I.session.current.dict~=first.dict,'successive idle choices do not repeat the previous clip')
I.update(2,'garage',true)T.time=T.time+250 I.update(2,'garage',true)
check(T.plays[#T.plays].ped==2 and T.plays[#T.plays].dict:find('female',1,true),'local visible clone uses its female pool')
check(not I.session.current.requiresWall,'wall poses excluded without scene support')
I.update(2,'garage',false)check(not I.session and not T.entities[2].playing,'character editor/modal suspension releases only owned idle')
T.entities[1].male=false T.entities[1].model=11
I.update(1,'lobby',true)T.time=T.time+250 I.update(1,'lobby',true)
check(I.session.sex=='female','changed player model gets new idle profile')
I.stop()T.time=0 T.delay=10000 I.update(1,'garage',true)
T.time=2000 I.update(1,'garage',true)
check(not I.session.pending and next(I.session.failed),'animation loading timeout is optional and bounded')
T.delay=0 T.time=2250 I.update(1,'garage',true)T.time=2500 I.update(1,'garage',true)
check(I.session.current~=nil,'another idle can succeed after optional loading failure')
I.stop()T.invalidClip=true T.time=0 I.update(1,'lobby',true)T.time=250 I.update(1,'lobby',true)
check(not I.session.current and next(I.session.failed),'missing clip is diagnosed without claiming animation success')
I.stop()T.invalidClip=false T.playFailure=true T.time=0 I.update(1,'lobby',true)T.time=250 I.update(1,'lobby',true)T.time=750 I.update(1,'lobby',true)
check(not I.session.current and next(I.session.failed),'native start failure cannot become confirmed playback')
I.stop()T.playFailure=false T.time=0 I.update(2,'garage',true)T.time=250 I.update(2,'garage',true)
local stopped=T.stopped T.entities[2].tag='reused' I.stop()
check(T.stopped==stopped,'reused clone identity is never given a stop task')
T.entities[2].tag='actor'I.update(2,'garage',true)T.time=500 I.update(2,'garage',true)
T.events.onClientResourceStop('mx-freeroam-experience')check(not I.session,'resource stop clears idle session and dictionaries')
local native=TaskPlayAnim TaskPlayAnim=function()error('simulated animation native failure')end
T.time=1000 I.update(1,'garage',true)T.time=1250
check(pcall(I.update,1,'garage',true) and not I.session and I.retryAt==6250,'unexpected animation native failure cannot terminate the presentation render loop')
TaskPlayAnim=native
print(n..' scene/idle checks passed: authored poses, close low camera projection, male/female variation, clone identity, bounded optional failures and cleanup (native adapters; no game).')
