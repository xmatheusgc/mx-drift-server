DrivecamConfig={
    -- KirbyCam: base distance + half wheelbase; fixed FOV unless explicitly enabled.
    distance=4.0,minDistance=2.0,maxDistance=10.0,height=0.85,fov=65.0,dynamicFov=false,
    basePitch=math.rad(8),slopeLimit=math.rad(25),
    -- Experimental rear framing reference (metres). 0 restores prior framing.
    rearPivotBack=0.65,pivotHalfLife=0.30,maxPivotAngle=math.rad(10),
    -- Follow travel promptly; turn prediction only affects the view, not distance.
    velocityHalfLife=0.06,speedHalfLife=0.22,directionHalfLife=0.18,
    steadyDirectionHalfLife=0.38,steadyViewHalfLife=0.20,
    curveFollowStart=math.rad(8),curveFollowFull=math.rad(24),curveFollowHalfLife=0.12,
    viewHalfLife=0.09,turnHalfLife=0.18,turnLeadTime=0.18,
    maxTurnLead=math.rad(5),leadHalfLife=0.24,maxAimOffset=math.rad(24),maxTurnRate=math.rad(100),
    -- Predict sustained bends only; keyboard countersteer must not kick the view.
    turnWindow=0.28,turnConfirmTime=0.18,turnMinRate=math.rad(5),
    headingDeadzone=math.rad(1.25),
    -- GTA road motion: stable world horizon, bounded vertical lag and damped heave.
    forceHalfLife=0.16,slopeHalfLife=0.25,heightHalfLife=0.10,maxHeightLag=0.18,
    maxSlopeRate=math.rad(22),slopeRateHalfLife=0.12,
    heavePerG=0.045,maxHeave=0.08,heaveFrequency=2.2,
    lateralSway=0.02,rollDegrees=0.05,
    collisionReturn=0.20,
    radius=0.30,margin=0.10,recenterDelay=1.0,mouseSensitivity=0.035,
    stickRate=2.2,deadzone=0.12,pitchMin=-0.25,pitchMax=0.65,
    teleportDistance=35.0,
    debug=false
}
