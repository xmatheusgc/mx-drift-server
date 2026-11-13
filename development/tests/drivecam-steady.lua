local K,M,C=DrivecamChase,DrivecamMath,DrivecamConfig
local function v(x,y,z)return {x=x,y=y,z=z}end
local function sample()return {forward=v(0,1,0),right=v(1,0,0),up=v(0,0,1),anchor=v(0,0,.5),velocity=v(0,20,0),wheelbase=2.6}end
-- Previous tuning, isolated per step so both rigs see identical input samples.
local previous={steadyDirectionHalfLife=.18,steadyViewHalfLife=.09,maxTurnLead=math.rad(8),leadHalfLife=.00001,lateralSway=.07,rollDegrees=.25,distance=3.8,height=1}
local function oldStep(s,a,dt)
    local saved={}for key,value in pairs(previous)do saved[key]=C[key]C[key]=value end
    local pose=K.step(s,a,dt)
    for key,value in pairs(saved)do C[key]=value end
    return pose
end
local worstOrbit,worstView=0,0
for _,fps in ipairs({30,60,144})do
    local a=sample()local current=K.new(a)local old=K.new(a)
    local lo,hi,oldLo,oldHi,viewLo,viewHi,oldViewLo,oldViewHi=10,-10,10,-10,10,-10,10,-10
    for n=1,8*fps do
        local yaw=math.pi/2+math.rad(6)*math.sin(2*math.pi*.8*n/fps)
        a.velocity=v(math.cos(yaw)*20,math.sin(yaw)*20,0)
        local p=K.step(current,a,1/fps)local before=oldStep(old,a,1/fps)
        if n>2*fps then
            lo=math.min(lo,p.yaw)hi=math.max(hi,p.yaw)oldLo=math.min(oldLo,before.yaw)oldHi=math.max(oldHi,before.yaw)
            viewLo=math.min(viewLo,p.viewYaw)viewHi=math.max(viewHi,p.viewYaw)
            oldViewLo=math.min(oldViewLo,before.viewYaw)oldViewHi=math.max(oldViewHi,before.viewYaw)
        end
        assert(math.abs(p.turnLead)<=C.maxTurnLead+1e-9,'subtle anticipation stays bounded')
    end
    local orbit=(hi-lo)/(oldHi-oldLo)local view=(viewHi-viewLo)/(oldViewHi-oldViewLo)
    assert(orbit<.8 and view<.8,'steadier orbit and view during small repeated corrections')
    worstOrbit=math.max(worstOrbit,orbit)worstView=math.max(worstView,view)
    local a=sample()local p=K.step(K.new(a),a,1/fps)local before=oldStep(K.new(a),a,1/fps)
    assert(math.abs(p.position.y-before.position.y+.2)<.001,'base distance increased by only 20 cm')
    local lower=before.position.z-p.position.z
    assert(lower>.12 and lower<.13,'net rest position about 12 cm lower after pitch compensation')
    assert(p.fov==before.fov,'FOV unchanged')
end
print(('Steady follow: orbit swing <= %.0f%% and view swing <= %.0f%% of prior tuning at 30/60/144 FPS; rest pose +20 cm distance, about -12 cm height passed.'):format(worstOrbit*100,worstView*100))
