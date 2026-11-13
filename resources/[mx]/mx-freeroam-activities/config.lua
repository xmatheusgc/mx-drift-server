ActivityConfig={
    rules='native-time-v1',sampleMs=200,maxGap=1500,maxSpeed=120,maxDuration=600000,countdown=3000,tieMs=10,
    allowDraftPractice=GetConvarInt('mx_allowDrafts',0)==1,driftTelemetry=true,telemetryLimit=120,telemetryRetentionDays=7,
    invalidRetentionDays=30,competitiveDrift=false,driftTelemetryVersion='native-angle-v1',
    tracks={
        sandy_test={id='sandy_test',name='Sandy / rota de teste (rascunho)',revision=1,direction='forward',region='Sandy',destination='airstrip',
            validated=false,activated=false,drift=true,startRadius=18,checkpointRadius=15,
            checkpoints={{x=1740.0,y=3270.0,z=41.1},{x=1630.0,y=3235.0,z=40.4},{x=1510.0,y=3195.0,z=40.4},{x=1395.0,y=3154.0,z=40.5}},
            recoveries={{x=1748.0,y=3273.0,z=41.1,h=195.0},{x=1625.0,y=3245.0,z=40.5,h=195.0},{x=1505.0,y=3205.0,z=40.5,h=195.0},{x=1390.0,y=3165.0,z=40.5,h=195.0}}
        }
    }
}
