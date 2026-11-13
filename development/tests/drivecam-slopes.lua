local K,M,C=DrivecamChase,DrivecamMath,DrivecamConfig
local function v(x,y,z)return {x=x,y=y,z=z}end
local function sample()return {forward=v(0,1,0),right=v(1,0,0),up=v(0,0,1),anchor=v(0,0,.5),velocity=v(0,20,0),wheelbase=2.6}end
local function viewPitch(p)
    local x,y,z=p.aim.x-p.position.x,p.aim.y-p.position.y,p.aim.z-p.position.z
    return math.atan(z,math.sqrt(x*x+y*y))
end
local worst=0
for _,fps in ipairs({30,60,144})do
    local a=sample()local s=K.new(a)local previous=viewPitch(K.step(s,a,1/fps))
    for _,degrees in ipairs({20,-20,0,25,-25,0})do
        local slope=math.rad(degrees)
        a.forward=v(0,math.cos(slope),math.sin(slope))a.up=v(0,-math.sin(slope),math.cos(slope))
        a.velocity=v(0,20,20*math.tan(slope))
        for _=1,4*fps do
            a.anchor.y=a.anchor.y+20/fps a.anchor.z=a.anchor.z+a.velocity.z/fps
            local p=K.step(s,a,1/fps)local pitch=viewPitch(p)
            local rate=math.abs(pitch-previous)*fps
            assert(rate<=C.maxSlopeRate+1e-8,'crest/dip pitch rate remains bounded')
            worst=math.max(worst,rate)previous=pitch
            assert(math.abs(s.pitch)<=C.slopeLimit+1e-8,'terrain pitch stays within limits')
        end
        assert(math.abs(s.pitch-slope)<math.rad(.2),'sustained ascent/descent is still followed')
    end
    -- Vertical velocity noise from suspension cannot kick the viewing angle.
    for n=1,3*fps do
        a.velocity=v(0,20,n%2==0 and 8 or -8)
        local p=K.step(s,a,1/fps)local pitch=viewPitch(p)
        assert(math.abs(pitch-previous)*fps<=C.maxSlopeRate+1e-8,'vertical velocity spikes do not bypass slope limiter')
        previous=pitch
    end
end
print(('Slopes: ascent/descent, crests/dips and vertical velocity noise at 30/60/144 FPS passed; peak automatic pitch rate %.1f deg/s.'):format(math.deg(worst)))
