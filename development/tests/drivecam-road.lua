local K,M,C=DrivecamChase,DrivecamMath,DrivecamConfig
local function v(x,y,z)return {x=x,y=y,z=z}end
local function sample()return {forward=v(0,1,0),right=v(1,0,0),up=v(0,0,1),anchor=v(0,0,.5),velocity=v(0,15,0),wheelbase=2.6}end
local function carHeading(a,yaw)
    a.forward=v(math.cos(yaw),math.sin(yaw),0)a.right=v(math.sin(yaw),-math.cos(yaw),0)
end
local maxError,maxBodyOffset=0,0
local results={}
for _,fps in ipairs({30,60,144})do
    for _,sign in ipairs({-1,1})do
        local a=sample()local s=K.new(a)local oldYaw=math.pi/2 local worst=0 local last
        -- 15 m/s on an 8 m radius, 45 degree drift: a tight ~107 deg/s bend.
        for n=1,3*fps do
            local t=n/fps local yaw=math.pi/2+sign*15/8*t
            a.velocity=v(math.cos(yaw)*15,math.sin(yaw)*15,0)
            a.anchor=v(sign*8*(math.sin(yaw)-1),-sign*8*math.cos(yaw),.5)
            carHeading(a,yaw+sign*math.rad(45))
            last=K.step(s,a,1/fps)
            oldYaw=M.angleDecay(oldYaw,yaw,.693,1/fps)
            local error=math.abs(M.angle(last.viewYaw-yaw))
            if n>fps then
                worst=math.max(worst,error)
                assert(error<math.rad(20),'tight drift keeps view within 20 deg of road trajectory')
                assert(error<math.abs(M.angle(oldYaw-yaw))*.5,'less than half the old tight-turn error')
                local carYaw=math.atan(a.anchor.y-last.position.y,a.anchor.x-last.position.x)
                local offset=math.abs(M.angle(carYaw-last.viewYaw))
                assert(offset<math.rad(27),'car stays within bounded horizontal framing')
                maxBodyOffset=math.max(maxBodyOffset,offset)
            end
            assert(math.abs(last.turnLead)<=C.maxTurnLead+1e-9,'prediction capped')
            assert(math.abs(last.heave)<=C.maxHeave+.001,'no suspension travel explosion in a drift')
        end
        maxError=math.max(maxError,worst)
        if sign==1 then results[#results+1]=last.viewYaw end
        -- Releasing to a straight should remove the prediction instead of hunting.
        for _=1,4*fps do last=K.step(s,a,1/fps)end
        assert(math.abs(last.turnLead)<.0001,'prediction settles on a straight')
        local manual=K.step(s,a,1/fps,math.pi,0)
        assert(math.abs(M.angle(manual.viewYaw-s.yaw-math.pi))<.00001,'look behind has no automatic curve bias')
    end
end
for i=2,#results do assert(math.abs(M.angle(results[i]-results[1]))<math.rad(3),'road framing comparable across FPS during a 107 deg/s bend')end

for _,fps in ipairs({30,60,144})do
    local a=sample()local s=K.new(a)local base=K.step(s,a,1/fps)
    local maxMotion=0
    -- Small repeated road bumps, then a hard landing and recovery.
    for n=1,3*fps do
        local t=n/fps local phase=t*2*math.pi*6
        a.anchor.z=.5+.08*math.sin(phase)a.velocity=v(0,15,.08*2*math.pi*6*math.cos(phase))
        local p=K.step(s,a,1/fps)
        maxMotion=math.max(maxMotion,math.abs(p.position.z-base.position.z))
        assert(math.abs(p.roll)<=C.rollDegrees,'roll is subtle')
    end
    assert(maxMotion<.18,'road bumps damped without exaggerated vertical vibration')
    a.anchor.z=.5 a.velocity=v(0,15,-15)K.step(s,a,1/fps)
    a.velocity=v(0,15,0)
    local p
    for _=1,5*fps do p=K.step(s,a,1/fps)end
    assert(math.abs(p.heave)<.0001 and math.abs(p.position.z-base.position.z)<.001,'landing spring settles without residual vibration')
    -- Chassis banking no longer lifts the camera or tilts the horizon.
    a.up=v(.7,0,.714)a.right=v(.714,0,-.7)
    local banked=K.step(s,a,1/fps)
    assert(math.abs(banked.position.z-p.position.z)<.001,'banking does not pump camera height')
    -- Approved nominal distance survives full acceleration/braking.
    for _,speed in ipairs({0,40,0,60})do
        a.velocity=v(0,speed,0)local p=K.step(s,a,1/fps)
        local flat=math.sqrt((p.position.x-a.anchor.x)^2+(p.position.y-a.anchor.y)^2)
        assert(math.abs(flat-(C.distance+a.wheelbase/2))<.08,'acceleration does not pump chase distance')
    end
end
print(('Road framing: 8m-radius drift at 30/60/144 FPS, both directions; max road error %.1f deg, car offset %.1f deg. Bumps, landing recovery, horizon and fixed distance passed.'):format(math.deg(maxError),math.deg(maxBodyOffset)))
