local T,F=TrainerTest,WorldTrainer
local function rejects(fn,code) local ok,err=pcall(fn) assert(not ok and (type(err)=='table' and err.code==code or tostring(err):find(code,1,true)),code) end
F.travel=function(src,id,withCar,point) T.trip={src=src,id=id,car=withCar,point=point} end
assert(not F.status(1).checkpoint and not F.status(1).noclip)
rejects(function() F.returnTo(1) end,'CHECKPOINT')
T.bucket=10001 rejects(function()F.save(1)end,'SESSION') T.bucket=0
T.private=true rejects(function()F.noclip(1,{enabled=true})end,'SESSION') T.private=false
T.vehicle=10 T.passengers=true rejects(function()F.save(1)end,'PASSENGER') T.passengers=false
T.cars[10].pitch=12 T.cars[10].roll=-7
local cp=F.save(1,{point={x=999,y=999,z=999}}).checkpoint
assert(cp.x==12 and cp.y==24 and cp.h==135,'checkpoint uses server entity coordinates, not client coordinates')
assert(cp.pitch==12 and cp.roll==-7,'checkpoint preserves the actual slope orientation')
T.cars[10].x=500 F.returnTo(1) assert(T.trip.car and T.trip.point.x==12,'return uses saved point with current owned car')
assert(F.noclip(1,{enabled=true,speed=3}).noclip and T.invalidations==1,'noclip invalidates eligible attempts before grant')
source=1 local token=F.sessions[1].token
T.events['mx:trainer:settings']('old',8,false) assert(F.status(1).speed==3,'old grant cannot change flight settings')
T.events['mx:trainer:settings'](token,9,false) assert(F.status(1).speed==3,'invalid speed cannot change flight settings')
T.events['mx:trainer:settings'](token,8,false) assert(F.status(1).speed==8 and not F.status(1).followCamera,'authorized flight hotkeys synchronize settings')
rejects(function()F.save(1)end,'NOCLIP')
assert(F.noclip(1,{enabled=false}).noclip==false)
assert(F.status(1).speed==8 and not F.status(1).followCamera,'speed and camera mode survive toggling noclip off')
T.failAck=true rejects(function()F.noclip(1,{enabled=true})end,'ACK lost')
assert(F.sessions[1],'lost acknowledgement retains grant until stop can be confirmed')
T.failAck=false F.stop(1) assert(not F.sessions[1])
T.vehicle=0 F.returnTo(1) assert(not T.trip.car,'return on foot does not summon or duplicate a vehicle')
T.epoch=2 assert(not F.status(1).checkpoint,'checkpoint cannot leak to a new profile epoch')
F.save(1) assert(not F.clear(1).checkpoint)
T.bucket=10 rejects(function()F.returnTo(1)end,'SESSION') T.bucket=0
local uuid=MX.uuid MX.uuid=function()error('noclip must not query SQL for a grant')end
assert(F.toggle(1).noclip and not F.toggle(1).noclip,'single-call server toggle is authorized without database UUID work') MX.uuid=uuid
print('Trainer server: private/bucket/driver/passenger guards, server-captured checkpoint, return contracts, epoch and ambiguous ACK regressions passed; runtime adapters only.')
