local K,M,C=DrivecamChase,DrivecamMath,DrivecamConfig
local function v(x,y,z)return {x=x,y=y,z=z}end
local function sample(sign)
    local yaw=math.pi/2+(sign or 0)*math.rad(55)
    return {forward=v(math.cos(yaw),math.sin(yaw),0),right=v(math.sin(yaw),-math.cos(yaw),0),up=v(0,0,1),anchor=v(0,0,.5),velocity=v(0,15,0),wheelbase=2.6}
end
local function pitch(p)
    local x,y,z=p.aim.x-p.position.x,p.aim.y-p.position.y,p.aim.z-p.position.z
    return math.atan(z,math.sqrt(x*x+y*y))
end
local function rearEdge(p,a)
    local rear=v(a.anchor.x-a.forward.x*2.2,a.anchor.y-a.forward.y*2.2,a.anchor.z)
    return math.abs(M.angle(math.atan(rear.y-p.position.y,rear.x-p.position.x)-p.viewYaw))
end
local function fullBodyEdge(p,a)
    local front=v(a.anchor.x+a.forward.x*2.2,a.anchor.y+a.forward.y*2.2,a.anchor.z)
    local frontAngle=math.abs(M.angle(math.atan(front.y-p.position.y,front.x-p.position.x)-p.viewYaw))
    return math.max(frontAngle,rearEdge(p,a))
end
for _,fps in ipairs({30,60,144})do
    for _,sign in ipairs({-1,1})do
        local a=sample(sign)local on,off=K.new(a),K.new(a)local p,before
        for _=1,4*fps do
            a.pivotBack=nil p=K.step(on,a,1/fps)
            a.pivotBack=0 before=K.step(off,a,1/fps)
        end
        assert(rearEdge(p,a)<rearEdge(before,a)-math.rad(3),'rear end moves toward image centre in either drift direction')
        assert(fullBodyEdge(p,a)<fullBodyEdge(before,a),'both ends fit into a smaller horizontal framing envelope')
        for _,axis in ipairs({'x','y','z'})do assert(math.abs(p.position[axis]-before.position[axis])<1e-9,'rear framing does not move camera')end
        assert(math.abs(pitch(p)-pitch(before))<1e-9 and p.fov==before.fov,'height, pitch and FOV unchanged')
        assert(math.abs(p.pivotAngle)<=C.maxPivotAngle,'rear framing angle bounded')
        local previous=p.pivotAngle
        for _=1,5*fps do
            a.pivotBack=0 p=K.step(on,a,1/fps)
            assert(math.abs(p.pivotAngle-previous)<math.rad(1),'disabling experiment blends without a snap')
            previous=p.pivotAngle
        end
        assert(math.abs(p.pivotAngle)<.00001,'disabled profile returns to prior framing')
        a.pivotBack=C.rearPivotBack
        for _=1,3*fps do p=K.step(on,a,1/fps)end
        p=K.step(on,a,1/fps,math.pi,0)
        assert(p.pivotAngle==0,'manual look behind remains independent')
    end
    local a=sample(0)local s=K.new(a)local p
    for _=1,3*fps do p=K.step(s,a,1/fps)end
    assert(math.abs(p.pivotAngle)<1e-9,'straight following has no framing shift')
end
print('Experimental rear pivot: rear-edge centring in both drift directions at 30/60/144 FPS, unchanged camera position/pitch/FOV, smooth disable and manual look passed.')
