WorkshopFraming={}
local F=WorkshopFraming
-- Targets use fractions of model dimensions, observer offsets use metres outside
-- the model envelope. Every visual mod slot has an explicit region mapping.
F.slots={ [0]='spoiler',[1]='front',[2]='rear',[3]='skirt',[4]='exhaust',[5]='side',[6]='front',[7]='hood',[8]='leftWing',[9]='rightWing',[10]='roof',[11]='engine',[12]='frontWheel',[13]='engine',[14]='front',[15]='frontWheel',[16]='side',[23]='frontWheel',[24]='rearWheel',[25]='rear',[26]='rear',[27]='interior',[28]='interior',[29]='interior',[30]='interior',[31]='interior',[32]='interior',[33]='interior',[34]='interior',[35]='interior',[36]='interior',[37]='trunk',[38]='rearWheel',[39]='engine',[40]='engine',[41]='engine',[42]='side',[43]='roof',[44]='side',[45]='rear',[46]='leftDoor',[47]='rightDoor',[48]='side',[49]='roof'}
F.regions={
 front={f=.5,r=0,z=.35,of=1.9,orr=.7,up=.55,bone='bumper_f'},
 rear={f=-.5,r=0,z=.35,of=-1.9,orr=.7,up=.55,bone='bumper_r'},
 spoiler={f=-.4,r=0,z=.85,of=-1.8,orr=1.0,up=.65,bone='spoiler'},
 exhaust={f=-.48,r=.25,z=.16,of=-1.5,orr=.65,up=.2,bone='exhaust',bones={'exhaust','exhaust_2','exhaust_3','exhaust_4'}},
 hood={f=.28,r=0,z=.8,of=1.3,orr=.9,up=1.1,bone='bonnet'},
 engine={f=.28,r=0,z=.6,of=1.3,orr=.9,up=1.1,bone='engine',bones={'engine','bonnet'}},
 roof={f=0,r=0,z=1,of=1.1,orr=2.3,up=2.0},
 frontWheel={f=.3,r=.5,z=.22,of=.25,orr=1.65,up=.18,bone='wheel_rf',bones={'wheel_rf','wheel_lf'}},
 rearWheel={f=-.3,r=.5,z=.22,of=.25,orr=1.65,up=.18,bone='wheel_rr',bones={'wheel_rr','wheel_lr'}},
 skirt={f=0,r=.5,z=.2,of=0,orr=2.1,up=.6},
 side={f=0,r=.4,z=.5,of=.4,orr=2.5,up=1.0},
 leftWing={f=.3,r=-.5,z=.5,of=.8,orr=-1.9,up=1.0},
 rightWing={f=.3,r=.5,z=.5,of=.8,orr=1.9,up=1.0},
 leftDoor={f=0,r=-.5,z=.55,of=.3,orr=-1.9,up=1.1,bone='door_dside_f'},
 rightDoor={f=0,r=.5,z=.55,of=.3,orr=1.9,up=1.1,bone='door_pside_f'},
 trunk={f=-.4,r=0,z=.75,of=-2.0,orr=1.0,up=.7,bone='boot'},
 interior={f=0,r=.2,z=.65,of=.2,orr=1.1,up=1.1},
}
-- Minimum observer-to-part distances are metres, then scaled by dimensions and
-- vertical field of view. Narrow screens need extra horizontal framing space.
F.clearances={front=2.2,rear=2.2,spoiler=1.9,exhaust=1.5,hood=2.0,engine=2.0,roof=3.2,frontWheel=1.6,rearWheel=1.6,skirt=2.8,side=3.3,leftWing=2.2,rightWing=2.2,leftDoor=2.5,rightDoor=2.5,trunk=2.4,interior=2.4}
function F.fit(radius,fov,aspect)
 local vertical=math.rad(fov)/2 local horizontal=math.atan(math.tan(vertical)*(aspect or 16/9))
 return radius/math.sin(math.min(vertical,horizontal))*ExperienceConfig.parts.frameMargin
end
function F.compose(position,part,fov)
 -- Put the selected part at 38% of screen height, above the bottom option strip.
 local x,y,z=part.x-position.x,part.y-position.y,part.z-position.z
 local horizontal=math.sqrt(x*x+y*y) local distance=math.sqrt(horizontal*horizontal+z*z)
 local yaw=math.atan(y,x) local pitch=math.atan(z,horizontal)-math.atan(math.tan(math.rad(fov)/2)*.24)
 return {x=position.x+math.cos(yaw)*math.cos(pitch)*distance,y=position.y+math.sin(yaw)*math.cos(pitch)*distance,z=position.z+math.sin(pitch)*distance}
end
function F.main(car,width,length,aspect)
 local f=ExperienceConfig.framing local margin=math.max(1,(16/9)/(aspect or 16/9))
 return ExperienceConfig.offset(car,math.max(4.2,length*f.frontRatio)*margin,math.max(3.5,width*f.rightRatio)*margin,f.height),ExperienceConfig.offset(car,0,f.aimRight,f.aimHeight)
end
function F.scene(car,ped,width,length,aspect,context,height)
 local cfg=context=='lobby' and ExperienceConfig.lobbyCamera or ExperienceConfig.camera
 local offsets=context=='lobby' and ExperienceConfig.lobbyOffsets.camera or ExperienceConfig.offsets.camera
 local position=ExperienceConfig.offset(car,offsets.forward,offsets.right,offsets.up)
 local target={x=(car.x+ped.x)/2,y=(car.y+ped.y)/2,z=(car.z+.65+ped.z+.1)/2}
 local corners={}
 for _,f in ipairs({-length/2,length/2}) do for _,r in ipairs({-width/2,width/2}) do
  corners[#corners+1]=ExperienceConfig.offset(car,f,r,0) corners[#corners+1]=ExperienceConfig.offset(car,f,r,height or 1.7)
 end end
 corners[#corners+1]={x=ped.x,y=ped.y,z=ped.z-.9} corners[#corners+1]={x=ped.x,y=ped.y,z=ped.z+.9}
 local dx,dy=position.x-target.x,position.y-target.y local distance=math.sqrt(dx*dx+dy*dy)
 local ux,uy=dx/math.max(.01,distance),dy/math.max(.01,distance)
 local tanV=math.tan(math.rad(cfg.fov)/2) local tanH=tanV*(aspect or 16/9)
 -- Fit actual projected bounds instead of a sphere that unnecessarily backs
 -- the camera away. Recede horizontally only, preserving the requested low view.
 for step=0,200 do
  local d=distance+step*.1 position={x=target.x+ux*d,y=target.y+uy*d,z=car.z+offsets.up}
  local vx,vy,vz=target.x-position.x,target.y-position.y,target.z-position.z
  local norm=math.sqrt(vx*vx+vy*vy+vz*vz) vx,vy,vz=vx/norm,vy/norm,vz/norm
  local flat=math.sqrt(vx*vx+vy*vy) local rx,ry=vy/flat,-vx/flat
  local fits=true
  for _,p in ipairs(corners) do
   local x,y,z=p.x-position.x,p.y-position.y,p.z-position.z
   local depth=x*vx+y*vy+z*vz local horizontal=x*rx+y*ry local vertical=x*ry*vz-y*rx*vz+z*flat
   if depth<=.15 or math.abs(horizontal)*1.15>depth*tanH or math.abs(vertical)*1.15>depth*tanV then fits=false break end
  end
  if fits then break end
 end
 return position,target
end
function F.person(car,width,length,wheel)
 local f=ExperienceConfig.framing local forward=length*f.wheelRatio
 if wheel and wheel.x<0 and wheel.y>0 and wheel.y<length then forward=wheel.y end
 local p=ExperienceConfig.offset(car,forward,-(width/2+f.pedClearance),0)
 local aim=ExperienceConfig.offset(car,forward,0,0)
 -- GTA heading points along (-sin(h),cos(h)); derive the body direction from
 -- a vector toward the car, independent of world heading and camera position.
 p.h=math.deg(math.atan(-(aim.x-p.x),aim.y-p.y))%360
 return p
end
function F.frame(car,width,length,height,region,bone,aspect)
 local s=F.regions[region] or F.regions.side
 local target=ExperienceConfig.offset(car,length*s.f,width*s.r,height*s.z)
 local valid=bone and MX.distance(bone,car)<=math.sqrt(length*length+width*width+height*height)/2+.25
 if valid then target={x=bone.x,y=bone.y,z=bone.z} end
 -- Observe every automatic part view from the right; left-specific targets retain their identity.
 local forward=length*s.f+s.of local right=math.abs(width*s.r+s.orr)
 -- Never put the observer inside the bounding rectangle, even with a valid bone.
 if math.abs(forward)<length/2+.2 and math.abs(right)<width/2+.2 then right=(right<0 and -1 or 1)*(width/2+math.max(.8,math.abs(s.orr))) end
 local position=ExperienceConfig.offset(car,forward,right,math.max(.35,s.up))
 if valid then position=ExperienceConfig.offset({x=target.x,y=target.y,z=target.z,h=car.h},s.of,math.abs(s.orr),s.up)end
 if not F.outside(car,width,length,height,position)then
  local h=math.rad(car.h) local x,y=position.x-car.x,position.y-car.y
  position=ExperienceConfig.offset(car,-math.sin(h)*x+math.cos(h)*y,width/2+.45,position.z-car.z)
 end
 position.z=math.max(position.z,target.z+.18)
 local dx,dy,dz=position.x-target.x,position.y-target.y,position.z-target.z
 local distance=math.sqrt(dx*dx+dy*dy+dz*dz)
 local scale=math.max(1,width/2.0,length/4.7,height/1.7)
 local fov=ExperienceConfig.parts.fov
 local radius=(region=='frontWheel' or region=='rearWheel') and .55*scale or region=='exhaust' and .45*scale or (region=='side' or region=='skirt' or region=='roof') and math.max(length*.43,width*.55) or (region=='hood' or region=='engine') and math.max(length*.22,width*.5) or math.max(width*.55,height*.4)
 local minimum=math.max((F.clearances[region] or 3.8)*scale*ExperienceConfig.parts.clearanceScale*math.max(1,(16/9)/(aspect or 16/9)),F.fit(radius,fov,aspect))
 if s.bone and not valid then minimum=minimum*1.2 end
 if distance<minimum then local factor=minimum/math.max(.01,distance) position={x=target.x+dx*factor,y=target.y+dy*factor,z=target.z+dz*factor} end
 position.z=math.max(car.z+.35,position.z)
 return position,target,fov,minimum
end
function F.orbit(car,width,length,height,yaw,elevation,distance,aspect)
 local cfg=ExperienceConfig.orbit
 elevation=math.max(cfg.minElevation,math.min(cfg.maxElevation,elevation))
 -- Detail zoom uses the ray's intersection with the expanded model rectangle.
 -- Full-car framing remains the default view, not a restriction on manual zoom.
 local h=math.rad(car.h)
 local forward=math.abs(-math.sin(h)*math.cos(yaw)+math.cos(h)*math.sin(yaw))
 local right=math.abs(math.cos(h)*math.cos(yaw)+math.sin(h)*math.sin(yaw))
 local min=math.min((length/2+cfg.clearance)/math.max(.001,forward),(width/2+cfg.clearance)/math.max(.001,right))/math.cos(elevation)
 distance=math.max(min,math.min(min+cfg.range,distance))
 local target=ExperienceConfig.offset(car,0,0,height*cfg.aimHeight)
 -- Allow low inspection while keeping the observer above the scene floor.
 local floor=car.z+cfg.minHeight
 if target.z+distance*math.sin(elevation)<floor then elevation=math.asin(math.max(-1,math.min(1,(floor-target.z)/distance)))end
 local horizontal=distance*math.cos(elevation)
 return {x=target.x+math.cos(yaw)*horizontal,y=target.y+math.sin(yaw)*horizontal,z=target.z+distance*math.sin(elevation)},target,distance,elevation
end
function F.outside(car,width,length,height,p)
 local h=math.rad(car.h) local dx,dy=p.x-car.x,p.y-car.y
 local forward=-math.sin(h)*dx+math.cos(h)*dy local right=math.cos(h)*dx+math.sin(h)*dy
 return math.abs(forward)>length/2+.15 or math.abs(right)>width/2+.15 or p.z>car.z+height+.2
end
-- Exponential response is independent of input-message rate and frame rate.
function F.dampPoint(current,target,dt,response)
 local alpha=1-math.exp(-math.max(0,dt)*response)
 return {x=current.x+(target.x-current.x)*alpha,y=current.y+(target.y-current.y)*alpha,z=current.z+(target.z-current.z)*alpha}
end
function F.arc(car,width,length,a,b,t)
 local ax,ay=a.x-car.x,a.y-car.y local bx,by=b.x-car.x,b.y-car.y
 local from,to=math.atan(ay,ax),math.atan(by,bx)
 local delta=(to-from+math.pi)%(2*math.pi)-math.pi
 local angle=from+delta*t local radius=math.sqrt(ax*ax+ay*ay)*(1-t)+math.sqrt(bx*bx+by*by)*t
 local h=math.rad(car.h) local forward=math.abs(-math.sin(h)*math.cos(angle)+math.cos(h)*math.sin(angle)) local right=math.abs(math.cos(h)*math.cos(angle)+math.sin(h)*math.sin(angle))
 local clearance=math.min((length/2+.3)/math.max(.001,forward),(width/2+.3)/math.max(.001,right))
 radius=math.max(radius,clearance)
 return {x=car.x+math.cos(angle)*radius,y=car.y+math.sin(angle)*radius,z=a.z*(1-t)+b.z*t}
end
