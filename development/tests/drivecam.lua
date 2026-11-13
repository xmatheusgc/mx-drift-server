local K,M,C=DrivecamChase,DrivecamMath,DrivecamConfig
local function v(x,y,z)return {x=x,y=y,z=z}end
local function sample(velocity)return {forward=v(0,1,0),right=v(1,0,0),up=v(0,0,1),anchor=v(0,0,.5),velocity=velocity or v(0,0,0),wheelbase=2.6}end
local function finite(p)
    for _,a in ipairs({p.position,p.aim})do for _,x in pairs(a)do assert(x==x and math.abs(x)<1e6,'finite camera pose')end end
    assert(p.fov>=1 and p.fov<=130)
end
local a=sample() local s=K.new(a) local p=K.step(s,a,1/60,0,0)
finite(p) assert(p.position.y< -4 and p.position.z>1,'rest: behind and above the vehicle')
assert(p.fov==65 and p.g.x==0 and p.g.y==0 and p.g.z==0,'initial state has no false acceleration')
local long=sample() long.wheelbase=4
assert(K.step(K.new(long),long,1/60).position.y<p.position.y,'wheelbase scales chase distance')
local results={}
for _,fps in ipairs({30,60,144})do
    local a=sample(v(0,20,0)) local s=K.new(a) local p
    a.velocity=v(20,20,0)
    for _=1,5*fps do p=K.step(s,a,1/fps) finite(p)end
    results[#results+1]=p
    assert(math.abs(M.angle(p.yaw-math.pi/4))<.04,'drift follows travel instead of old bounded slip correction')
end
for i=2,#results do assert(math.abs(results[i].yaw-results[1].yaw)<.002,'comparable drift tracking at 30/60/144 FPS')end
local a=sample(v(0,20,0)) local s=K.new(a)
a.forward=v(1,0,0) a.right=v(0,-1,0)
local p=K.step(s,a,1/60) assert(p.g.x==0 and p.g.y==0,'body rotation is not an acceleration impulse')
a.velocity=v(0,-20,0)
for _=1,600 do p=K.step(s,a,1/60)finite(p)end
assert(p.position.y>0,'sustained reverse smoothly moves chase to the front')
a.velocity=v(0,0,0)
for _=1,600 do p=K.step(s,a,1/60)finite(p)end
assert(p.position.x<0,'stopped camera returns to body heading')
a=sample(v(0,20,0)) s=K.new(a)
local neutral=K.step(s,a,1/60)
a.velocity=v(0,25,5) p=K.step(s,a,1/60)
assert(p.g.y>0 and p.g.z>0 and p.g.y<=6 and p.g.z<=6,'bounded acceleration and landing forces')
assert(p.position.z~=neutral.position.z,'vertical forces move the camera')
a.up=v(0,0,-1) a.right=v(1,0,0) a.forward=v(0,-1,0) a.velocity=v(1000,-1000,1000)
for _=1,120 do finite(K.step(s,a,1/30,math.pi,.3))end
local p=K.step(K.new(sample()),sample(),.1,math.pi,0) assert(p.position.y>0,'look behind reverses the orbit')
local s=K.new(sample(v(0,100,0))) a=sample(v(0,100,0))
assert(K.step(s,a,1/60).fov==65,'dynamic FOV off by default')
C.dynamicFov=true local p=K.step(s,a,1/60) assert(p.fov>65 and p.fov<95,'optional speed FOV') C.dynamicFov=false
print('Kirby chase solver: rest, wheelbase, drift, reverse, FPS, G forces, rollover, look behind and fixed/dynamic FOV passed.')
