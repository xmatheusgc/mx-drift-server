-- Static teleport points. Preserve meet: it is the existing home destination.
-- Add an id, name, category, validated, optional asset and slots {x,y,z,h}.
TrackTeleports={
        meet={id='meet',name='Encontro LSIA (rascunho)',category='Encontro',validated=false,radius=100,
            slots={{x=-1037.7,y=-2737.8,z=20.2,h=330.0},{x=-1030.0,y=-2733.0,z=20.2,h=330.0},{x=-1022.0,y=-2729.0,z=20.2,h=330.0}}},
        docks={id='docks',name='Porto (rascunho)',category='Prática',validated=false,radius=120,
            slots={{x=1204.0,y=-3104.0,z=5.5,h=90.0},{x=1204.0,y=-3113.0,z=5.5,h=90.0},{x=1204.0,y=-3122.0,z=5.5,h=90.0}}},
        airstrip={id='airstrip',name='Sandy Shores (rascunho)',category='Prática',validated=false,radius=120,
            slots={{x=1740.0,y=3270.0,z=41.1,h=195.0},{x=1748.0,y=3273.0,z=41.1,h=195.0},{x=1756.0,y=3276.0,z=41.1,h=195.0}}}
    }
WorldConfig.destinations=TrackTeleports
