-- Server owns progression. Clients receive complete snapshots, including the
-- weather blend, so late joiners do not restart transitions independently.
WorldCycle={}
function WorldCycle.create(config,random)
    local options=config.environment
    MX.require(type(options)=='table' and MX.number(options.secondsPerGameMinute,0.1,3600),'ENVIRONMENT','Velocidade do relógio inválida')
    MX.require(MX.number(options.weatherIntervalMinutes,1,1440) and MX.number(options.weatherTransitionSeconds,1,3600)
        and options.weatherTransitionSeconds<options.weatherIntervalMinutes*60,'ENVIRONMENT','Intervalos de clima inválidos')
    MX.require(MX.number(config.hour,0,23,true) and MX.number(config.minute or 0,0,59,true),'ENVIRONMENT','Horário inicial inválido')
    local known={EXTRASUNNY=true,CLEAR=true,CLOUDS=true,OVERCAST=true,FOGGY=true,SMOG=true,RAIN=true,THUNDER=true,CLEARING=true,NEUTRAL=true,SNOW=true,SNOWLIGHT=true,BLIZZARD=true,XMAS=true}
    local graph=options.weatherTransitions
    MX.require(type(graph)=='table' and known[config.weather] and type(graph[config.weather])=='table','ENVIRONMENT','Clima inicial sem transições')
    for weather,nextValues in pairs(graph) do
        MX.require(known[weather] and type(nextValues)=='table' and #nextValues>0,'ENVIRONMENT','Lista de climas inválida')
        for _,nextWeather in ipairs(nextValues) do MX.require(known[nextWeather] and nextWeather~=weather and type(graph[nextWeather])=='table','ENVIRONMENT','Destino de clima inválido') end
    end
    local elapsed,step,current,previous=0,0,config.weather,config.weather
    local interval=options.weatherIntervalMinutes*60000
    random=random or math.random
    return {advance=function(dt)
        MX.require(MX.number(dt,0,4294967295),'ENVIRONMENT','Intervalo de atualização inválido')
        elapsed=elapsed+dt
        while step<math.floor(elapsed/interval) do
            previous=current local candidates=graph[current]
            current=candidates[random(#candidates)] step=step+1
        end
        local total=math.floor((config.hour*3600+(config.minute or 0)*60+elapsed/1000*60/options.secondsPerGameMinute)%86400)
        local blend=step==0 and 1 or math.min(1,(elapsed-step*interval)/(options.weatherTransitionSeconds*1000))
        return {weather=current,weatherFrom=blend<1 and previous or current,weatherBlend=blend,
            hour=math.floor(total/3600),minute=math.floor(total/60)%60,second=total%60,revision=config.revision}
    end}
end
CreateThread(function()
    local cycle=WorldCycle.create(WorldConfig)
    local last=GetGameTimer()
    GlobalState.mxEnvironment=cycle.advance(0)
    while true do
        Wait(1000)
        local now=GetGameTimer()
        -- GetGameTimer wraps at 32 bits; scheduling delays must not slow the clock.
        local elapsed=(now-last)%4294967296 last=now
        GlobalState.mxEnvironment=cycle.advance(elapsed)
    end
end)
