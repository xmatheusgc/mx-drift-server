local K,M,C=DrivecamChase,DrivecamMath,DrivecamConfig
local function v(x,y,z)return {x=x,y=y,z=z}end
local function sample()return {forward=v(0,1,0),right=v(1,0,0),up=v(0,0,1),anchor=v(0,0,.5),velocity=v(0,20,0),wheelbase=2.6}end
local function heading(a,yaw)
    a.forward=v(math.cos(yaw),math.sin(yaw),0)a.right=v(math.sin(yaw),-math.cos(yaw),0)
end
local largestRatio=0
for _,fps in ipairs({30,60,144})do
    for _,frequency in ipairs({2.5,5})do
        local a=sample()local s=K.new(a)
        local previous=math.pi/2 local oldTurn=0 local oldView=previous
        local oldVelX,oldVelY=0,20
        local currentMin,currentMax,oldMin,oldMax=math.huge,-math.huge,math.huge,-math.huge
        for n=1,4*fps do
            local yaw=math.pi/2+math.rad(4)*math.sin(2*math.pi*frequency*n/fps)
            a.velocity=v(math.cos(yaw)*20,math.sin(yaw)*20,0)
            -- Chassis countersteer intentionally oscillates much more than travel.
            heading(a,math.pi/2+math.rad(25)*math.sin(2*math.pi*frequency*n/fps))
            local p=K.step(s,a,1/fps)
            -- Previous view predictor, using its actual filter constants.
            oldVelX=M.decay(oldVelX,a.velocity.x,.06,1/fps)
            oldVelY=M.decay(oldVelY,a.velocity.y,.06,1/fps)
            local travel=math.atan(oldVelY,oldVelX)
            local rate=M.clamp(M.angle(yaw-previous)*fps,-math.rad(100),math.rad(100))
            oldTurn=M.decay(oldTurn,rate,.14,1/fps)previous=yaw
            oldView=M.angleDecay(oldView,travel+M.clamp(oldTurn*.28,-math.rad(12),math.rad(12)),.09,1/fps)
            if n>fps then
                currentMin=math.min(currentMin,p.viewYaw)currentMax=math.max(currentMax,p.viewYaw)
                oldMin=math.min(oldMin,oldView)oldMax=math.max(oldMax,oldView)
                assert(math.abs(p.turnLead)<math.rad(.1),'rapid corrections do not trigger prediction')
            end
        end
        local swing=currentMax-currentMin local oldSwing=oldMax-oldMin
        assert(swing<oldSwing*.5,'keyboard oscillation reduced by more than half')
        assert(swing<math.rad(1.5),'small travel corrections have bounded view oscillation')
        largestRatio=math.max(largestRatio,swing/oldSwing)
    end
    local a=sample()local s=K.new(a)
    for n=1,2*fps do
        heading(a,math.pi/2+math.rad(35)*math.sin(n/fps*20))
        local p=K.step(s,a,1/fps)
        assert(math.abs(M.angle(p.viewYaw-math.pi/2))<1e-6,'chassis/steering oscillation alone cannot steer camera at speed')
    end
    -- Brief direction tap followed by straight: no lingering predictive kick.
    for n=1,4*fps do
        local t=n/fps local yaw=math.pi/2+(t<.12 and t*.4 or .048)
        a.velocity=v(math.cos(yaw)*20,math.sin(yaw)*20,0)
        local p=K.step(s,a,1/fps)
        assert(math.abs(p.turnLead)<math.rad(.1),'short tap does not confirm a bend')
    end
    -- Continuous turn is still anticipated; the camera must not become locked.
    for n=1,2*fps do
        local yaw=math.pi/2+.048+.6*n/fps
        a.velocity=v(math.cos(yaw)*20,math.sin(yaw)*20,0)
        local p=K.step(s,a,1/fps)
        if n>fps then assert(p.turnLead>C.maxTurnLead*.5,'sustained curve retains smoothly introduced road anticipation')end
    end
end
print(('Keyboard corrections: 2.5/5 Hz at 30/60/144 FPS, chassis-only countersteer, short taps and sustained turns passed; worst view swing %.0f%% of prior predictor.'):format(largestRatio*100))
