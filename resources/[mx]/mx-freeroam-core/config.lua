CoreConfig = {
    schema='007_vehicle_modes.sql',requestLimit=40,requestWindow=10000,clientTimeout=12000,
    -- A cold join can stream a scene, load a selected model and apply it in sequence.
    requestTimeout=240000,
    clientTimeouts={['vehicles:load']=35000,['experience:scene']=105000}
}
