local T=TrainerTest local travel=T.handlers.world.travel
local checks=0
function HasCollisionLoadedAroundEntity() checks=checks+1 return false end
T.vehicle=10 T.driver=true T.control=true T.private=false
T.cars[10].id='owned-car'
local point={x=140,y=-3024,z=6.2,h=268,pitch=14,roll=-8}
local response=travel({net=110,id='owned-car',point=point,checkpoint=true})
assert(response.arrived and checks==0,'checkpoint return never requires HasCollisionLoadedAroundEntity')
assert(T.cars[10].x==140 and T.cars[10].pitch==14 and T.cars[10].roll==-8 and T.cars[10].h==268,'return applies saved position and slope without grounding/snapping')
assert(not T.cars[10].frozen and T.cars[10].velocity[1]==0,'return stops velocity and releases temporary freeze')
assert(not pcall(travel,{net=110,id='replaced',point=point,checkpoint=true}),'reused vehicle identity still rejects return')
T.cars[10].x=500
response=travel({net=110,id='owned-car',point=point})
assert(response.arrived and checks==0 and T.cars[10].x==140,'configured tracks also teleport without a collision acceptance gate')
assert(not T.cars[10].frozen,'track teleport releases temporary freeze')
local rotate=SetEntityRotation local failOnce=true
SetEntityRotation=function(...)if failOnce then failOnce=false error('native failed')end return rotate(...)end
T.cars[10].x=500
assert(not pcall(travel,{net=110,id='owned-car',point=point}) and T.cars[10].x==500 and not T.cars[10].frozen,'native failure restores original position and releases freeze')
SetEntityRotation=rotate
T.vehicle=0 T.cars[1].frozen=true
response=travel({point=point})
assert(response.arrived and T.cars[1].x==140 and T.cars[1].frozen,'on-foot travel preserves the previous freeze state')
T.cars[1].frozen=false
print('Actual world client: checkpoint and configured-track collision bypass, slope/heading, identity checks, foot travel and freeze restoration passed (native adapters).')
