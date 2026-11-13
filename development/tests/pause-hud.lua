local T=TrainerMenuTest
local pauseLoop,hudLoop=T.threads[#T.threads],T.threads[4]
local pressed=false local native=false local pauseControl=200
function PlayerPedId()return 1 end
function GetCurrentResourceName()return 'mx-freeroam-menu'end
function TriggerServerEvent()end
function IsPauseMenuActive()return native end
function IsDisabledControlJustPressed(_,c)return pressed and c==pauseControl end
function GetDisabledControlNormal()return 0 end
function ActivateFrontendMenu(hash,toggle,component)
 assert(hash=='FE_MENU_VERSION_MP_PAUSE' and toggle==false and component==-1)
 native=true
end
function joaat(v)return v end
exports['mx-freeroam-experience'].ControllerIcons=function()return 'xbox'end
assert(not T.bindings['+mx_session_select'] and not T.bindings['+mx_trainer_touch'],'pause does not register extra physical mappings')
T.tick(pauseLoop)pressed=true T.tick(pauseLoop)pressed=false
local pauseShown=false for _,message in ipairs(T.messages)do if message.type=='pauseMenu' and message.open then pauseShown=true end end
assert(T.focused and T.cursor and pauseShown,'ESC opens separate mouse-enabled menu')
assert(T.disabled[199] and T.disabled[200],'both native pause actions are intercepted')
assert(T.nui('pauseAction',{kind='close'}).ok)
T.disabled={}T.tick(pauseLoop)
assert(T.disabled[199] and T.disabled[200] and not T.focused,'pause controls remain consumed throughout close cooldown so ESC release cannot open native map')
T.time=T.time+500 pauseControl=199 pressed=true T.tick(pauseLoop)pressed=false
assert(T.focused and T.cursor,'native controller pause action opens the same menu')
pauseControl=200
assert(not T.nui('pauseAction',{kind='garage'}).ok and T.garageCalls==0,'garage requires confirmation')
assert(not T.nui('pauseAction',{kind='disconnect'}).ok and #T.requests==0,'disconnect requires confirmation')
assert(T.nui('pauseAction',{kind='native'}).ok and native and not T.focused,'native action releases NUI and opens map tab')
T.tick(pauseLoop)native=false T.time=T.time+500 T.tick(pauseLoop)
pressed=true T.tick(pauseLoop)assert(not T.focused,'closing native map cannot reopen overlay in same input edge')pressed=false
T.time=T.time+500 pressed=true T.tick(pauseLoop)pressed=false
assert(T.focused,'overlay can reopen after native map exit')
T.garageFail=true
assert(not T.nui('pauseAction',{kind='garage',confirmed=true}).ok and T.focused and T.cursor,'garage failure restores usable side menu')
T.garageFail=false
assert(T.nui('pauseAction',{kind='garage',confirmed=true}).ok and not T.focused,'confirmed garage releases side menu')
T.time=T.time+500 pressed=true T.tick(pauseLoop)pressed=false
assert(T.nui('pauseAction',{kind='disconnect',confirmed=true}).ok and T.requests[#T.requests].domain=='core' and T.requests[#T.requests].action=='disconnect','disconnect targets own authenticated core action')
assert(T.nui('pauseAction',{kind='close'}).ok and not T.focused,'close releases mouse')
-- Real HUD sampler with native input doubles and optional manual gearbox.
local position={x=0,y=0,z=0} local state={mxVehicle='hud-car'} local vehicle=10
function GetVehiclePedIsIn()return vehicle end
function Entity()return {state=state}end
function GetEntityCoords()return position end
function GetEntitySpeed()return 10 end
function GetEntitySpeedVector()return {y=-1}end
function GetVehicleCurrentGear()return 0 end
function GetVehicleCurrentRpm()return .7 end
function GetVehicleLightsState()return 1,1,0 end
function GetVehicleFuelLevel()return 55 end
function GetVehicleHandbrake()return true end
function GetVehicleEngineHealth()return 750 end
function GetResourceState()return 'missing'end
function DisplayRadar(v)T.radar=v end
local prefs={units='kmh',scale=1}
local sample=MenuVehicleHud.sample(10,prefs)
assert(sample.speed==36 and sample.rpm==.7 and sample.gear==-1 and sample.lowBeam and not sample.highBeam and sample.handbrake,'speed/RPM/reverse/lights use real telemetry')
T.time=T.time+100 position={x=10,y=0,z=0}
sample=MenuVehicleHud.sample(10,prefs)assert(math.abs(sample.odometer-.01)<.0001,'session odometer tracks motion')
T.time=T.time+100 position={x=10000,y=0,z=0}
assert(MenuVehicleHud.sample(10,prefs).odometer==sample.odometer,'teleports are excluded')
function GetResourceState()return 'started'end
exports['mx-gearbox']={GetTransmissionData=function()return {gear=3,normalizedRpm=.9}end}
sample=MenuVehicleHud.sample(10,{units='mph',scale=1})
assert(sample.gear==3 and sample.rpm==.9 and math.abs(sample.speed-22.36936)<.0001,'manual telemetry and mph are respected')
T.events['mx:profile:local']({preferences={hud=false,minimap=true,photo=false}})
T.tick(hudLoop)
assert(T.radar and not T.messages[#T.messages].data.enabled,'speedometer can be hidden without minimap')
T.events['mx:profile:local']({preferences={hud=true,minimap=false,photo=false,units='kmh'}})
T.tick(hudLoop)assert(not T.radar and T.messages[#T.messages].data.enabled,'minimap can be hidden without speedometer')
vehicle=0 T.tick(hudLoop)assert(not T.messages[#T.messages].data.enabled,'speedometer stays hidden on foot')
print('Pause/HUD: ESC, focus, native map, confirmation gates, garage recovery, self-disconnect route, real telemetry, odometer, manual gearbox and independent HUD/radar passed with native doubles.')
