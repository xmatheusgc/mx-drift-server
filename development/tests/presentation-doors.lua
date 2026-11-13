local T,P=PresentationTest,WorkshopPresentation
T.entities[10].id='preview' T.vehicle=nil
P.start('doors',10,'preview',{x=5,y=6,z=1.08,h=300,groundZ=0})
local function advance(ms)for _=1,math.ceil(ms/25)do T.time=T.time+25 P.tick(.025)end end
P.doorContext('engine')
assert(GetVehicleDoorAngleRatio(10,4)==1,'engine category requests native bonnet opening')
local calls=T.doorCalls
-- A hinge still moving or limited by an addon model must not trigger angle chasing.
T.entities[10].doors[4]=.45
advance(3000) P.doorContext('engine')
assert(T.doorCalls==calls and GetVehicleDoorAngleRatio(10,4)==.45,'ticks and unchanged context never reissue native commands')
T.entities[10].doors[4]=0
T.events['mx:vehicles:presentationApplied']('preview')
assert(GetVehicleDoorAngleRatio(10,4)==1,'piece application restores required door')
P.doorContext('interior')
assert(GetVehicleDoorAngleRatio(10,1)==1 and GetVehicleDoorAngleRatio(10,0)==0 and GetVehicleDoorAngleRatio(10,4)==0,'interior opens passenger door for right-side camera')
P.doorContext('trunk') assert(GetVehicleDoorAngleRatio(10,5)==1,'trunk view opens boot')
assert(P.toggleDoors('doors').open,'manual command opens all doors')
for door=0,5 do assert(GetVehicleDoorAngleRatio(10,door)==1,'all valid doors opened') end
T.entities[10].doors[1]=0 T.events['mx:vehicles:presentationApplied']('preview')
assert(GetVehicleDoorAngleRatio(10,1)==1,'manual state survives piece application')
assert(not P.toggleDoors('doors').open,'second command closes all doors')
P.doorContext('hood') assert(GetVehicleDoorAngleRatio(10,4)==0,'manual close remains authoritative across categories')
for _=1,30 do
 P.toggleDoors('doors') advance(25) P.toggleDoors('doors') advance(25)
 for door=0,5 do assert(GetVehicleDoorAngleRatio(10,door)==0,'repeated rapid toggles end closed') end
end
calls=T.doorCalls advance(3000)
assert(T.doorCalls==calls,'no periodic corrections after repeated toggles')
T.missingDoors={[2]=true,[3]=true}
calls=T.doorCalls P.toggleDoors('doors')
assert(T.doorCalls==calls+4,'models without rear doors only receive valid commands')
T.missingDoors=nil
T.entities[10].doors[4]=0 T.events['mx:vehicles:presentationApplied']('other-preview')
assert(GetVehicleDoorAngleRatio(10,4)==0,'unrelated apply cannot control this presentation')
assert(not pcall(P.toggleDoors,'old-editor'),'old editor cannot toggle current doors')
T.entities[10].id='unmanaged' calls=T.doorCalls
P.refreshDoors(true)
assert(T.doorCalls==calls,'reused vehicle handle cannot receive door commands')
T.entities[10].id='preview'
P.stop('doors')
for door=0,5 do assert(GetVehicleDoorAngleRatio(10,door)==0,'editor cleanup closes every presentation door') end
print('Presentation-door regressions passed: native commands, no angle chasing, rapid toggles, context, apply, missing doors, identity and cleanup; native doubles only.')
