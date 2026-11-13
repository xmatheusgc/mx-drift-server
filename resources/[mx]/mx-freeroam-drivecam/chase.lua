-- FiveM adaptation of the KirbyCam chase cam v1.0b-public (2021-10-20),
-- supplied by the user. Original credits: KirbyCam; portions based on x4fab.
-- Road framing and suspension use a GTA-specific rig. Native sampling and
-- collision ownership live in client.lua; AC is Y-up, while GTA is Z-up.
-- This solver uses plain vectors so it can be exercised without a game client.
DrivecamChase={}
local K,M,C=DrivecamChase,DrivecamMath,DrivecamConfig
local function v(x,y,z)return {x=x,y=y,z=z}end
local function add(a,b)return v(a.x+b.x,a.y+b.y,a.z+b.z)end
local function mul(a,s)return v(a.x*s,a.y*s,a.z*s)end
local function sub(a,b)return add(a,mul(b,-1))end
local function dot(a,b)return a.x*b.x+a.y*b.y+a.z*b.z end
local function length(a)return math.sqrt(dot(a,a))end
local function unit(a,fallback)local n=length(a) if n<1e-6 then return fallback end return mul(a,1/n)end
local function blend(a,b,half,dt)return v(M.decay(a.x,b.x,half,dt),M.decay(a.y,b.y,half,dt),M.decay(a.z,b.z,half,dt))end
local function soften(x)return x/math.sqrt(1+x*x)end -- sin(atan(x))
local worldUp=v(0,0,1)

function K.new(sample)
    local forward=sample.forward local velocity=sample.velocity
    local speed=math.sqrt(velocity.x^2+velocity.y^2)
    local yaw=speed>4 and math.atan(velocity.y,velocity.x) or math.atan(forward.y,forward.x)
    return {velocity=v(velocity.x,velocity.y,velocity.z),previousVelocity=v(velocity.x,velocity.y,velocity.z),
        speed=speed,yaw=yaw,viewYaw=yaw,travelYaw=yaw,rawYaw=speed>4 and yaw or nil,turnRate=0,
        turnSamples={},turnSign=0,turnAge=0,curveFollow=0,lead=0,pivotOffset=v(0,0,0),
        pitch=0,pitchRate=0,anchorZ=sample.anchor.z,heave=0,heaveVelocity=0,slow=v(0,0,0)}
end

function K.step(s,a,dt,lookYaw,lookPitch)
    dt=M.clamp(dt,0.0001,0.1)
    local forward,right,up=a.forward,a.right,a.up
    local raw=mul(sub(a.velocity,s.previousVelocity),1/(dt*9.81))
    s.previousVelocity=v(a.velocity.x,a.velocity.y,a.velocity.z)
    -- Project world acceleration into the current body axes. No false G spike
    -- when merely rotating a car whose world velocity has remained unchanged.
    local g=v(M.clamp(dot(raw,right),-6,6),M.clamp(dot(raw,forward),-6,6),M.clamp(dot(raw,up),-6,6))
    s.slow=blend(s.slow,g,C.forceHalfLife,dt)
    s.velocity=blend(s.velocity,a.velocity,C.velocityHalfLife,dt)
    local speed=math.sqrt(a.velocity.x^2+a.velocity.y^2)
    s.speed=M.decay(s.speed,speed,C.speedHalfLife,dt)
    local weight=M.clamp((s.speed-1)/3,0,1)
    local flatForward=unit(v(forward.x,forward.y,0),v(math.cos(s.yaw),math.sin(s.yaw),0))
    local velocityFlat=v(s.velocity.x,s.velocity.y,0)
    local wanted=add(mul(flatForward,math.max(1,length(a.velocity))*(1-weight)),mul(velocityFlat,weight))
    local measuredYaw=length(wanted)>0.05 and math.atan(wanted.y,wanted.x) or s.yaw
    -- Measure the change in travel direction, not chassis rotation/countersteer.
    -- Reject discontinuous reversals so a spin does not produce a look-ahead kick.
    local rawYaw=speed>4 and math.atan(a.velocity.y,a.velocity.x) or nil
    local delta=0
    if rawYaw and s.rawYaw then
        delta=M.angle(rawYaw-s.rawYaw)
        if math.abs(delta)>=math.rad(60) then delta=0 s.turnSamples={} s.turnRate=0 end
    end
    if not rawYaw then s.turnSamples={} end
    s.rawYaw=rawYaw
    local sign=math.abs(delta/dt)>C.turnMinRate and (delta>0 and 1 or -1) or 0
    s.turnAge=sign~=0 and sign==s.turnSign and s.turnAge+dt or 0
    s.turnSign=sign
    local samples=s.turnSamples
    samples[#samples+1]={dt=dt,angle=delta}
    local duration,net,movement=0,0,0
    for i=#samples,1,-1 do
        local part=math.min(samples[i].dt,math.max(0,C.turnWindow-duration))
        local angle=samples[i].angle*part/samples[i].dt
        duration=duration+part net=net+angle movement=movement+math.abs(angle)
        if part==0 then table.remove(samples,i) end
    end
    -- Alternating corrections cancel in the time window. Requiring a persistent
    -- sign also prevents the first short key tap from masquerading as a bend.
    local coherence=movement>1e-6 and M.clamp((math.abs(net)/movement-.55)/.35,0,1) or 0
    local confirmed=M.clamp((s.turnAge-C.turnConfirmTime)/C.turnConfirmTime,0,1)*coherence
    local turn=M.clamp(net/math.max(duration,dt),-C.maxTurnRate,C.maxTurnRate)*confirmed
    s.turnRate=M.decay(s.turnRate,turn,C.turnHalfLife,dt)
    -- A small angular deadband absorbs lane corrections; it fades on a confirmed
    -- bend so tight drift alignment remains responsive and has no heading steps.
    local difference=M.angle(measuredYaw-s.travelYaw)
    local deadzone=C.headingDeadzone*(1-confirmed)
    if math.abs(difference)>deadzone then s.travelYaw=s.travelYaw+difference-(difference>0 and deadzone or -deadzone) end
    local travelYaw=s.travelYaw
    -- Resist small course corrections without making sustained tight bends slow.
    -- Blend the response continuously from steady tracking to corner tracking.
    local error=math.abs(M.angle(travelYaw-s.yaw))
    local follow=M.clamp((error-C.curveFollowStart)/(C.curveFollowFull-C.curveFollowStart),0,1)
    follow=follow*follow*(3-2*follow)
    s.curveFollow=M.decay(s.curveFollow,follow,C.curveFollowHalfLife,dt)
    local orbitHalf=C.steadyDirectionHalfLife+(C.directionHalfLife-C.steadyDirectionHalfLife)*s.curveFollow
    local viewHalf=C.steadyViewHalfLife+(C.viewHalfLife-C.steadyViewHalfLife)*s.curveFollow
    s.yaw=M.angleDecay(s.yaw,travelYaw,orbitHalf,dt)
    local targetLead=M.clamp(s.turnRate*C.turnLeadTime,-C.maxTurnLead,C.maxTurnLead)*weight
    s.lead=M.decay(s.lead,targetLead,C.leadHalfLife,dt)
    local lead=s.lead
    s.viewYaw=M.angleDecay(s.viewYaw,travelYaw+lead,viewHalf,dt)
    local viewOffset=M.clamp(M.angle(s.viewYaw-s.yaw),-C.maxAimOffset,C.maxAimOffset)
    local trajectory=unit(s.velocity,forward)
    local bodyPitch=math.asin(M.clamp(forward.z,-1,1))*.25
    local travelPitch=math.asin(M.clamp(trajectory.z,-1,1))
    local slopeTarget=M.clamp(bodyPitch*(1-weight)+travelPitch*weight,-C.slopeLimit,C.slopeLimit)
    local slopeError=slopeTarget-s.pitch
    local targetRate=M.clamp(slopeError*math.log(2)/C.slopeHalfLife,-C.maxSlopeRate,C.maxSlopeRate)
    s.pitchRate=M.decay(s.pitchRate,targetRate,C.slopeRateHalfLife,dt)
    local slopeStep=s.pitchRate*dt
    if slopeStep*slopeError>=0 and math.abs(slopeStep)>=math.abs(slopeError) then
        s.pitch=slopeTarget s.pitchRate=0
    else s.pitch=M.clamp(s.pitch+slopeStep,-C.slopeLimit,C.slopeLimit) end
    local yaw=s.yaw+(lookYaw or 0)
    local slope=M.clamp(s.pitch,-C.slopeLimit,C.slopeLimit)
    local orbitPitch=M.clamp(slope+(lookPitch or 0),-math.rad(80),math.rad(80))
    local behind=v(math.cos(yaw)*math.cos(orbitPitch),math.sin(yaw)*math.cos(orbitPitch),math.sin(orbitPitch))
    local fovAdd=C.dynamicFov and 30*soften(s.speed/50) or 0
    local distance=M.clamp(C.distance+a.wheelbase/2,C.minDistance+0.5,C.maxDistance)
    -- Preserve the approved following distance: braking/acceleration no longer
    -- pump it in/out. The optional speed FOV retains its small compensation.
    distance=distance-fovAdd*.03
    local height=C.height+distance*math.tan(C.basePitch)
    s.anchorZ=M.clamp(M.decay(s.anchorZ,a.anchor.z,C.heightHalfLife,dt),a.anchor.z-C.maxHeightLag,a.anchor.z+C.maxHeightLag)
    local target=M.clamp(-s.slow.z*C.heavePerG,-C.maxHeave,C.maxHeave)
    -- Exact critically damped spring for a constant target over this frame.
    -- Unlike repeated raw acceleration offsets it settles without ringing.
    local omega=2*math.pi*C.heaveFrequency
    local error=s.heave-target local j=s.heaveVelocity+omega*error local decay=math.exp(-omega*dt)
    s.heave=target+(error+j*dt)*decay s.heaveVelocity=(s.heaveVelocity-omega*j*dt)*decay
    local flatRight=v(math.sin(s.yaw),-math.cos(s.yaw),0)
    local lateral=mul(flatRight,-soften(s.slow.x)*C.lateralSway)
    local anchor=v(a.anchor.x,a.anchor.y,s.anchorZ)
    local position=add(add(add(anchor,mul(behind,-distance)),mul(worldUp,height+s.heave)),lateral)
    local pitch=M.clamp(slope-C.basePitch+(lookPitch or 0),-math.rad(85),math.rad(85))
    -- Fade automatic anticipation while the player is deliberately looking away.
    local autoLook=1-M.clamp(math.abs(M.angle(lookYaw or 0))/math.rad(45),0,1)
    local viewYaw=yaw+viewOffset*autoLook
    -- Experimental framing reference behind the body centre. Shift the view
    -- horizontally rather than moving the collision arm or changing its pitch.
    -- Filter the world offset so countersteer and the comparison toggle are soft.
    local pivotBack=a.pivotBack~=nil and a.pivotBack or C.rearPivotBack
    s.pivotOffset=blend(s.pivotOffset,mul(flatForward,-pivotBack),C.pivotHalfLife,dt)
    local reference=add(v(math.cos(viewYaw)*distance,math.sin(viewYaw)*distance,0),s.pivotOffset)
    local pivotAngle=M.clamp(M.angle(math.atan(reference.y,reference.x)-viewYaw),-C.maxPivotAngle,C.maxPivotAngle)*autoLook
    viewYaw=viewYaw+pivotAngle
    local direction=v(math.cos(viewYaw)*math.cos(pitch),math.sin(viewYaw)*math.cos(pitch),math.sin(pitch))
    return {position=position,aim=add(position,mul(direction,distance)),fov=C.fov+fovAdd,
        roll=-soften(2*s.slow.x)*C.rollDegrees,speed=s.speed,yaw=s.yaw,g=g,
        viewYaw=viewYaw,turnLead=lead,heave=s.heave,pivotAngle=pivotAngle}
end
