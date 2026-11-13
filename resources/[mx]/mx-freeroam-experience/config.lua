ExperienceConfig={
    schema=1,bucketStart=10000,home='meet',maxPresets=30,timeout=10000,entrySyncTimeout=6000,
    streaming={timeout=90000,lobbyTimeout=2000,radius=60.0,stableMs=250,workshop={resource='ps-tuners',models={'denis3d_ts_shell'}}},
    -- Independently configurable presentation and gameplay exit.
    presentation={x=135.962,y=-3030.353,z=6.396,h=0.11},
    characterPoint={x=133.303,y=-3027.849,z=7.041,h=276.85,fixed=true},
    exit={x=163.2,y=-3024.11,z=6.05,h=268.29},
    entry={min={x=120.0,y=-3050.0,z=6.0},max={x=160.0,y=-3007.0,z=10.0}},
    departureDelay=450,
    offsets={ped={forward=1.3,right=-2.6,up=0.0},camera={forward=3.8,right=3.1,up=.85}},
}
function ExperienceConfig.offset(anchor,forward,right,up)
    local h=math.rad(anchor.h)
    return {x=anchor.x-math.sin(h)*forward+math.cos(h)*right,y=anchor.y+math.cos(h)*forward+math.sin(h)*right,z=anchor.z+(up or 0),h=anchor.h}
end
local c=ExperienceConfig.offsets.camera
ExperienceConfig.scene={car=ExperienceConfig.presentation,ped=ExperienceConfig.characterPoint}
ExperienceConfig.camera=ExperienceConfig.offset(ExperienceConfig.presentation,c.forward,c.right,c.up)
ExperienceConfig.camera.look=ExperienceConfig.offset(ExperienceConfig.presentation,0,0,0.65)
ExperienceConfig.camera.fov=60.0

-- Lobby is a separate private presentation; garage presets above stay unchanged.
ExperienceConfig.lobbyPresentation={x=-949.431,y=-3533.159,z=13.953,h=280.67}
ExperienceConfig.lobbyCharacterPoint={x=-947.610,y=-3530.367,z=14.618,h=185.96,fixed=true}
ExperienceConfig.lobbyTime={hour=23,minute=0}
ExperienceConfig.lobbyWeather='FOGGY'
ExperienceConfig.lobbyOffsets={ped={forward=1.1,right=-2.8,up=0},camera={forward=3.8,right=3.1,up=.85}}
local lc=ExperienceConfig.lobbyOffsets.camera
ExperienceConfig.lobbyScene={car=ExperienceConfig.lobbyPresentation,ped=ExperienceConfig.lobbyCharacterPoint}
ExperienceConfig.lobbyCamera=ExperienceConfig.offset(ExperienceConfig.lobbyPresentation,lc.forward,lc.right,lc.up)
ExperienceConfig.lobbyCamera.look=ExperienceConfig.offset(ExperienceConfig.lobbyPresentation,0,-.4,.7)
ExperienceConfig.lobbyCamera.fov=60.0

-- Main views authored in-game on 2026-10-24. Keep these exact; detail views
-- continue to use the model-relative framing below.
ExperienceConfig.mainCameras={
    lobby={position={x=-944.500,y=-3535.300,z=14.500},rotation={x=-2.00,y=0.00,z=51.00},look={x=-948.794,y=-3531.823,z=14.307},fov=60.00},
    garage={position={x=138.500,y=-3025.500,z=7.200},rotation={x=-2.00,y=0.00,z=141.00},look={x=135.174,y=-3029.608,z=7.015},fov=60.00},
}

-- Geometry ratios are relative to the current model; metres for clearances/heights.
ExperienceConfig.framing={frontRatio=1.15,rightRatio=2.0,height=1.65,aimHeight=0.55,aimRight=-0.65,fov=49.0,pedClearance=1.25,wheelRatio=0.30}
ExperienceConfig.orbit={fov=60.0,clearance=.4,range=10.0,minElevation=-.25,maxElevation=.95,minHeight=.12,aimHeight=.3,sensitivity=0.05,zoomStep=0.35,response=40.0,transitionMs=350,queryTimeout=250}
ExperienceConfig.actor={footClearance=.08}
-- Wall-supported poses are opt-in per scene; the current fixed points are free-standing.
ExperienceConfig.idles={minMs=18000,maxMs=32000,loadTimeout=2000,verifyMs=500,blend=1.5,wall={lobby=false,garage=false},
    male={
        {dict='anim@mp_corona_idles@male_c@idle_a',clip='idle_a'},
        {dict='anim@mp_corona_idles@male_d@idle_a',clip='idle_a'},
        {dict='anim@heists@heist_corona@team_idles@male_a',clip='idle'},
        {dict='anim@amb@carmeet@checkout_car@male_c@idles',clip='idle_a'},
    },
    female={
        {dict='anim@mp_corona_idles@female_b@idle_a',clip='idle_a'},
        {dict='anim@heists@heist_corona@team_idles@female_a',clip='idle'},
        {dict='amb@world_human_hang_out_street@female_arms_crossed@idle_a',clip='idle_a'},
        {dict='amb@world_human_hang_out_street@female_hold_arm@idle_a',clip='idle_a'},
        {dict='amb@world_human_leaning@female@wall@back@hand_up@idle_a',clip='idle_a',requiresWall=true},
    },
}
ExperienceConfig.engineTest={idleTimeout=15000}
-- Idle power is permitted only while previewing neon; never accelerates by itself.
ExperienceConfig.neonPreview={engine=true}
-- Auto uses the browser's USB identity. Emulated XInput pads may need an override.
ExperienceConfig.controllerIcons='auto' -- auto | xbox | playstation
ExperienceConfig.parts={fov=55.0,clearanceScale=1.0,frameMargin=1.15}
-- Local scenery only. Disable enabled to remove the display and its LOD tweak.
ExperienceConfig.display={enabled=true,maxVehicles=7,excludeCurrent=true,startDelay=1000,betweenCars=250,modelTimeout=5000,lodDistance=55,worldLodScale=.8,neon=false,
    points={
        {x=124.648,y=-3047.350,z=6.381,h=269.64},
        {x=124.648,y=-3040.890,z=6.381,h=269.64},
        {x=124.648,y=-3035.130,z=6.381,h=269.64},
        {x=124.648,y=-3022.980,z=6.381,h=269.64},
        {x=148.742,y=-3043.695,z=6.385,h=235.60},
        {x=144.540,y=-3045.477,z=6.385,h=25.45},
        {x=137.056,y=-3046.604,z=6.385,h=179.94},
    },
}
