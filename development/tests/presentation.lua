local T=PresentationTest local P=WorkshopPresentation local F=WorkshopFraming local checks=0
local function check(v,name) assert(v,name) checks=checks+1 end
local point={x=5,y=6,z=1.08,h=300,groundZ=0}
P.start('a',10,'preview',point)
P.tick(.05) check(not T.entities[10].engine,'opening editor never starts engine')
check(not T.entities[1].visible and T.entities[1].alpha==0,'real driver hidden before rendering')
local clone=P.session.clone check(T.entities[clone].visible and not T.cloneFlags[1],'one visible local stand-in')
check(T.entities[clone].collision==false and T.entities[clone].frozen and T.entities[clone].h==300,'external actor inert and aligned')
P.rev('a',true)
for _=1,2 do T.time=T.time+50 P.tick(.05) end
check(T.entities[10].engine and T.rpmWrites==nil and T.controls[71]==1 and T.playerControl and T.enabled[71],'enabled native driver receives throttle immediately when engine runs, without forced RPM')
check(T.controls[76]==1,'native handbrake input held during engine test')
for _=1,20 do P.rev('a',true) T.time=T.time+50 P.tick(.05) end
check(T.controls[71]==1 and T.rpmWrites==nil,'held throttle leaves RPM and limiter to GTA')
check(T.entities[10].frozen and T.entities[10].handbrake and T.entities[10].steering==0 and T.entities[10].x==1,'owned presentation locked; no world displacement calls')
P.rev('a',false) for _=1,20 do T.time=T.time+50 P.tick(.05) end
check(T.controls[71]==0 and T.rpmWrites==nil,'release sends zero throttle without forcing RPM decay')
check(T.entities[10].engine,'short release keeps engine idling')
for _=1,math.ceil(ExperienceConfig.engineTest.idleTimeout/50) do T.time=T.time+50 P.tick(.05) end
check(not T.entities[10].engine,'engine stops after idle timeout without heartbeat')
P.rev('a',true) T.events['mx:experience:keyboard'](true) P.tick(.1) check(P.session.revUntil==0,'text entry suspends rev')
P.stop('other') check(P.session~=nil,'stale editor cannot clean current session')
P.stop('a') check(P.session==nil and not T.entities[clone] and T.entities[1].visible and T.entities[1].alpha==255,'cleanup removes stand-in and restores visible real ped')
check(T.entities[1].x==5 and not T.entities[10].engine and not T.entities[10].handbrake and not T.playerControl,'outside pose and previous player-control state restored')
P.start('b',10,'preview',point) clone=P.session.clone T.entities[10].id='unmanaged'
P.tick(.05) check(P.session==nil and not T.entities[clone] and not T.entities[10].engine,'lost identity cleans actor without changing unrelated vehicle')
T.entities[10].id='preview' P.start('c',10,'preview',point) clone=P.session.clone
T.events.onClientResourceStop('mx-freeroam-menu') check(not P.session and not T.entities[clone],'menu resource stop removes stand-in')
P.start('d',10,'preview',point) clone=P.session.clone T.entities[clone].state.mxWorkshopActor='unmanaged'
P.tick(.05) check(not P.session and T.entities[clone],'reused/unmanaged actor handle is not deleted') T.entities[clone]=nil
check(F.regions.frontWheel.bone=='wheel_rf' and F.regions.rearWheel.bone=='wheel_rr','wheel cameras target right-side wheel bones')
for _,size in ipairs({{1.6,3.6,1.2},{2,4.8,1.5},{2.5,6.5,2.4}}) do for _,heading in ipairs({0,90,180,300}) do
 local car={x=178.62,y=-3088.07,z=5,h=heading}
 for slot,region in pairs(F.slots) do
  local camera,target,fov=F.frame(car,size[1],size[2],size[3],region)
  local h=math.rad(heading) local dx,dy=camera.x-car.x,camera.y-car.y
  local forward=-math.sin(h)*dx+math.cos(h)*dy local right=math.cos(h)*dx+math.sin(h)*dy
  check(right>0,'automatic part camera stays on the right for slot '..slot)
  check(math.abs(forward)>size[2]/2 or math.abs(right)>size[1]/2,'camera outside body for slot '..slot)
  check(fov>=30 and fov<=60 and target.z>=car.z,'bounded framing for slot '..slot)
 end
 local camera,_,distance,elevation=F.orbit(car,size[1],size[2],size[3],.8,-100,-100)
 check(F.outside(car,size[1],size[2],size[3],camera) and elevation>=ExperienceConfig.orbit.minElevation and camera.z>=car.z+ExperienceConfig.orbit.minHeight-.0001,'low manual zoom remains outside model envelope and above floor')
 local _,_,far,high=F.orbit(car,size[1],size[2],size[3],.8,100,100)
 local _,_,highMinimum=F.orbit(car,size[1],size[2],size[3],.8,high,0)
 check(far<=highMinimum+ExperienceConfig.orbit.range and high==ExperienceConfig.orbit.maxElevation,'orbit range and height bounded')
end end
check(F.slots[0]=='spoiler' and F.slots[7]=='hood' and F.slots[4]=='exhaust','spoiler rear / hood surface / exhaust mappings')
check(not F.outside({x=0,y=0,z=0,h=90},2,4,1.5,{x=0,y=0,z=1}),'collision clipping cannot place observer in body')
check(F.outside({x=0,y=0,z=0,h=90},2,4,1.5,{x=3,y=0,z=1}),'outside observer passes in rotated frame')
for _,foot in ipairs({-1.2,-.4,.2}) do
 T.entities[1].footOffset=foot
 local grounded=P.ground(1,{x=5,y=6,z=12,h=300},10)
 check(math.abs(grounded.z+foot-(10+ExperienceConfig.actor.footClearance))<.00001,'feet aligned to ground independent of model origin')
end
T.entities[1].footOffset=nil
for _,aspect in ipairs({4/3,16/9,21/9}) do
 local car={x=0,y=0,z=0,h=0} local width,length,height=2,4.8,1.5
 local _,_,distance=F.orbit(car,width,length,height,0,.22,0,aspect)
 check(distance<F.fit(math.sqrt(width^2+length^2+height^2)/2,ExperienceConfig.orbit.fov,aspect),'manual orbit can zoom closer than full-car framing')
end
for _,size in ipairs({{1.6,3.6,1.2},{2,4.8,1.5},{2.5,6.5,2.4}}) do for _,heading in ipairs({0,90,180,300}) do
 local car={x=12,y=32,z=5,h=heading} local h=math.rad(heading)
 local function relative(p) local dx,dy=p.x-car.x,p.y-car.y return -math.sin(h)*dx+math.cos(h)*dy,math.cos(h)*dx+math.sin(h)*dy end
 local person=F.person(car,size[1],size[2],{x=-size[1]/2,y=size[2]*.3}) local front,left=relative(person)
 check(front>0 and left<-size[1]/2-1,'actor forward-left with clearance at every heading')
 local toward=ExperienceConfig.offset(car,front,0,0) local facing=math.rad(person.h)
 check((-math.sin(facing)*(toward.x-person.x)+math.cos(facing)*(toward.y-person.y))>0.99*MX.distance(toward,person),'whole actor heading faces car rather than forward')
 for _,aspect in ipairs({4/3,16/9,21/9}) do
  local main=F.main(car,size[1],size[2],aspect) local forward,right=relative(main)
  check(forward>size[2]/2 and right>size[1]/2,'main camera front-right in car axes')
  for region in pairs(F.regions) do
   local camera,target=F.frame(car,size[1],size[2],size[3],region,nil,aspect)
   local minimum=F.clearances[region]*math.max(1,size[1]/2,size[2]/4.7,size[3]/1.7)*math.max(1,(16/9)/aspect)
   check(MX.distance(camera,target)>=minimum-.001,'category distance/dimension/aspect margin '..region)
   check(F.outside(car,size[1],size[2],size[3],camera) and camera.z>=car.z+.35,'outside body and minimum height '..region)
  end
 end
end end
for i=0,100 do local car={x=0,y=0,z=0,h=0} local p=F.arc(car,2,4,{x=-3,y=2,z=1},{x=3,y=-2,z=1},i/100) check(F.outside(car,2,4,1.5,p),'orbit return arc stays outside body') end
for _,size in ipairs({{1.6,3.6,1.2},{2.5,6.5,2.4}}) do for _,heading in ipairs({0,90,180,300}) do
 local car={x=178.62,y=-3088.07,z=5,h=heading}
 for step=0,7 do for _,elevation in ipairs({.12,.35,.65}) do
  local camera=F.orbit(car,size[1],size[2],size[3],step*math.pi/4,elevation,-100)
  check(F.outside(car,size[1],size[2],size[3],camera),'closest orbital zoom stays outside body at every tested heading/yaw/elevation')
 end end
end end
print(checks..' verificações de apresentação e enquadramento (geometria + natives simuladas; sem áudio/jogo)')
-- Valid part bones frame the actual piece, with bounded, closer inspection.
local car={x=0,y=0,z=5,h=0}
for _,region in ipairs({'frontWheel','rearWheel','exhaust','hood'})do
 local spec=F.regions[region]
 local bone=ExperienceConfig.offset(car,4.7*spec.f,2*spec.r,1.5*spec.z)
 local p,target,_,minimum=F.frame(car,2,4.7,1.5,region,bone,16/9)
 assert(MX.distance(target,bone)<.000001,'valid bone is the part focus')
 local look=F.compose(p,target,55)
 local flat=math.sqrt((target.x-p.x)^2+(target.y-p.y)^2)
 local lookFlat=math.sqrt((look.x-p.x)^2+(look.y-p.y)^2)
 local difference=math.atan(target.z-p.z,flat)-math.atan(look.z-p.z,lookFlat)
 assert(math.abs(math.tan(difference)/math.tan(math.rad(55)/2)-.24)<.000001,'piece center projects above the bottom option strip')
 assert(MX.distance(p,target)>=minimum-.001 and F.outside(car,2,4.7,1.5,p),'detail never zooms inside part/body')
 if region=='frontWheel' or region=='exhaust' then assert(MX.distance(p,target)<2.5,'wheel/exhaust stays focused rather than framing whole vehicle')end
 local _,fallback=F.frame(car,2,4.7,1.5,region,{x=100,y=100,z=100},16/9)
 assert(MX.distance(fallback,bone)<.000001,'invalid distant bone falls back to model geometry')
end
local low,aim=F.orbit(car,2,4.7,1.5,0,-1,0)
assert(low.z<car.z+.3 and low.z>=car.z+ExperienceConfig.orbit.minHeight-.00001,'manual view reaches low parts without going under floor')
assert(aim.z<car.z+1.5*.5,'lower aim lifts vehicle above bottom UI')
assert(ExperienceConfig.engineTest.idleTimeout==15000,'longer engine idle is configured')
