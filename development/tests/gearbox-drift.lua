local T=DriftTest
local loop=T.threads[#T.threads]
local function tick()local ok,err=coroutine.resume(loop)assert(ok,err)end
local function mode(value)T.commands.gear(nil,{value})end
local function count()return T.manualCreates,T.manualDestroys,T.manualUpdates,T.shifts end
tick()
assert(T.manualCreates==1 and T.cars[1].highGear==1,'normal handling allows manual')
T.commands.mx_shiftup()assert(T.shifts==1,'normal manual accepts shifts')
T.nui=true T.commands.mx_shiftup()T.commands['+mx_clutch']()
assert(T.shifts==1,'UI/capture blocks gearbox keyboard commands')T.nui=false
T.controller=true tick()
assert(T.controlBlocks>0 and T.shifts==2,'normal manual accepts controller shifts')
local controlBlocks=T.controlBlocks
VehicleDrift.set(1,'one',true)
assert(T.manualDestroys==1 and T.cars[1].highGear==5,'manual released synchronously before drift writes')
assert(VehicleDrift.isApplied(1) and VehicleDrift.audit(1,'one',true).mismatches==0,'drift owns confirmed local physics before replicated ACK')
local creates,destroys,updates,shifts=count()
for _=1,10 do tick()end
T.commands.mx_shiftup() T.commands.mx_shiftdown() T.commands['+mx_clutch']()
local ok,reason=T.gearExports.SetGear(1,3)
assert(not ok and reason=='drift' and not T.gearExports.SetUpgrade(1,'ecu','stock'),'exports reject changes during drift')
assert(T.manualCreates==creates and T.manualDestroys==destroys and T.manualUpdates==updates and T.shifts==shifts,'drift blocks creation, updates and input without repeated cleanup')
assert(T.controlBlocks==controlBlocks,'drift releases manual controller bindings')
T.controller=false
assert(T.gearExports.GetCurrentGear(1)==nil and T.gearExports.GetTransmissionData(1)==nil,'exports do not advertise active manual')
mode('manual') tick()assert(T.manualCreates==creates,'manual command cannot bypass drift')
VehicleDrift.set(1,'one',false)
assert(not VehicleDrift.isApplied(1) and T.cars[1].highGear==6 and T.cars[1].fields.fBrakeForce==2,'baseline captured after manual cleanup, including neutral brake effects')
tick()assert(T.manualCreates==creates+1,'manual preference resumes after confirmed restore')
T.events['mx:vehicles:beforeDriftHandling'](1,'stale')
assert(T.manualDestroys==destroys,'stale identity event does not destroy manual')
VehicleDrift.set(1,'one',true)
T.driving=2 tick()
assert(T.gearExports.GetCurrentGear(2)==1,'another car without drift still supports manual')
T.driving=1 tick()
assert(T.gearExports.GetCurrentGear(1)==nil,'returning to drift car keeps manual off')
T.wanted[1]={id='one',enabled=true}
VehicleDrift.set(1,'one',false)
creates=T.manualCreates tick()
assert(T.manualCreates==creates,'replicated drift blocks manual while awaiting disable ACK')
T.wanted[1]={id='one',enabled=false,uncertain=true}
tick()assert(T.manualCreates==creates,'uncertain rollback keeps manual disabled')
T.wanted[1]={id='one',enabled=false,uncertain=false}
tick()assert(T.manualCreates==creates+1,'confirmed replicated disable permits manual')
mode('automatic')
VehicleDrift.set(1,'one',true) VehicleDrift.set(1,'one',false)
creates=T.manualCreates tick()
assert(T.manualCreates==creates,'automatic preference is preserved through drift cycle')
T.wanted[1]={id='old-entity',enabled=true,uncertain=true}
mode('manual')tick()
assert(T.manualCreates==creates+1,'stale state identity cannot block unrelated vehicle')
T.exportFailure=true tick()
creates=T.manualCreates tick()assert(T.manualCreates==creates,'provider errors cannot permit conflicting manual')
T.exportFailure=false T.provider='missing' T.wanted[1]=nil
tick()assert(T.manualCreates==creates+1,'standalone gearbox still works without base provider')
T.wanted[1]={id='one',enabled=true}tick()
assert(T.gearExports.GetCurrentGear(1)==nil,'replicated state protects drift even if provider is stopped')
T.provider='started' T.wanted[1]=nil
tick()T.commands['+mx_clutch']()tick()assert(T.clutch==true,'clutch works on ordinary handling')
VehicleDrift.set(1,'one',true)
T.failRefresh=true
local result=VehicleDrift.ensure(1,'one',false,false)
assert(result.uncertain and VehicleDrift.isApplied(1),'failed restoration retains local block')
creates=T.manualCreates tick()assert(T.manualCreates==creates,'uncertain local physics cannot restart manual')
T.failRefresh=false
VehicleDrift.ensure(1,'one',false,false)tick()
assert(T.clutch==false and T.manualCreates==creates+1,'successful recovery resumes manual with clutch released')
TriggerEvent('mx:profile:local', {preferences={transmission='automatic'}})
tick()assert(T.gearExports.GetCurrentGear(1)==nil,'saved automatic disables manual immediately')
TriggerEvent('mx:profile:local', {preferences={transmission='manual'}})
tick()assert(T.gearExports.GetCurrentGear(1)~=nil,'saved manual resumes ordinary handling')
creates=T.manualCreates
TriggerEvent('mx:profile:local', {preferences={transmission='manual',hud=false}})
tick()assert(T.manualCreates==creates,'unrelated saves preserve the current transmission')
VehicleDrift.set(1,'one',true)
TriggerEvent('mx:profile:local', {preferences={transmission='manual'}})
tick()assert(T.gearExports.GetCurrentGear(1)==nil,'saved manual never bypasses drift guard')
VehicleDrift.set(1,'one',false)
TriggerEvent('mx:profile:local', {preferences={}})
tick()assert(T.gearExports.GetCurrentGear(1)==nil,'legacy profile defaults to automatic')
local oldResourceState=GetResourceState
function GetResourceState(name)if name=='mx-freeroam-core' then return 'started' end return oldResourceState(name)end
local stored={revision=7,preferences={transmission='manual',hud=false}}
local reject=false
exports['mx-freeroam-core']={Request=function(_,domain,action,data)
 assert(domain=='core')
 if action=='profile' then return {ok=true,data={revision=stored.revision,preferences={transmission=stored.preferences.transmission,hud=stored.preferences.hud}}} end
 assert(action=='preferences' and data.revision==stored.revision and data.preferences.hud==false,'command preserves profile and revision')
 if reject then return {ok=false,code='CONFLICT'} end
 stored={revision=stored.revision+1,preferences=data.preferences}
 return {ok=true,data=stored}
end}
T.events.onClientResourceStart(GetCurrentResourceName())
local ok,err=coroutine.resume(T.threads[#T.threads])assert(ok,err)
tick()assert(T.gearExports.GetCurrentGear(1)~=nil,'restart restores saved manual profile')
mode('automatic')ok,err=coroutine.resume(T.threads[#T.threads])assert(ok,err)
tick()assert(stored.preferences.transmission=='automatic' and T.gearExports.GetCurrentGear(1)==nil,'command persists automatic preference')
reject=true
mode('manual')ok,err=coroutine.resume(T.threads[#T.threads])assert(ok,err)
tick()assert(T.gearExports.GetCurrentGear(1)==nil,'failed save cannot change active mode')
T.events.onResourceStop(GetCurrentResourceName())
print('Gearbox/drift integration passed: synchronous baseline handoff, local/replicated/uncertain state, commands, exports, vehicle changes, preferences, optional provider and recovery (native/transmission doubles).')
