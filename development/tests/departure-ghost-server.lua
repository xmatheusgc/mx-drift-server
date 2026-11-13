local T=GhostTest local G=VehicleDepartureGhost local car={id='departure',entity=10}
local function ghost()return T.entities[10].state.mxDepartureGhost~=nil end
G.start(car) assert(ghost(),'server publishes protection before spawn application')
T.time=30000 G.tick() assert(ghost(),'model/application delay does not spend minimum departure protection')
G.arm(car)
T.time=40000 G.tick() assert(ghost(),'occupied exit stays ghosted beyond the minimum')
T.entities[20].x=100 T.entities[2].x=100
T.time=40250 G.tick() assert(ghost(),'clearance needs stable interval')
T.time=41000 G.tick() assert(ghost(),'protection cannot expire during clearance interval')
T.entities[2].x=0 T.time=41250 G.tick() assert(ghost(),'new pedestrian overlap resets clearance')
T.entities[2].bucket=1
T.time=41500 G.tick() T.time=42500 G.tick() assert(not ghost(),'different bucket cannot hold protection; clear area restores collision')
T.time=0 G.start(car) G.arm(car) G.tick()
T.time=4999 G.tick() assert(ghost(),'empty exit still protects for minimum five seconds')
T.time=5000 G.tick() assert(not ghost(),'minimum ends when area has remained clear')
T.entities[20].x=0 T.time=6000 G.start(car) G.arm(car)
T.entities[10].state.mxVehicle='recycled' T.entities[10].state.mxDepartureGhost={id='other'}
G.tick() assert(T.entities[10].state.mxDepartureGhost.id=='other','cleanup never writes to reused entity')
T.entities[10].state.mxVehicle='departure' G.start(car)
T.events.onResourceStop('test-vehicles') assert(not ghost(),'resource stop clears only its owned protection')
print('Departure ghost server: pre-spawn publication, minimum, persistent traffic/pedestrian overlap, stable clearance, bucket isolation, recycled identity and stop cleanup passed (adapters).')
