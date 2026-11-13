local E=PreviewTest.exports
local ack={applied=true,wheels={wheelType=0,front=-1,rear=-1,customTyres=false,customRearTyres=false},modsRecovered={['4']=-1},capabilities={mods={},extras={}}}
local p=VehicleProperties.validate(VehicleProperties.defaults())p.wheelType=12 p.mods['23']=250 p.customTyres=true p.mods['4']=0
E.RegisterPreviewContext(7,'wheel-token','epoch',10007)
local co=coroutine.create(function()return MX.unwrap(E.Preview(7,'futo',p,{x=1,y=2,z=3,h=0}))end)
local ok,action=coroutine.resume(co)assert(ok and action=='load')
ok,action=coroutine.resume(co,{loaded=true})assert(ok and action=='apply')
local done,result=coroutine.resume(co,ack)
assert(done and result.properties.wheelType==0 and result.properties.mods['23']==-1 and not result.properties.customTyres,'new preview publishes effective original wheels')
assert(p.mods['23']==250 and p.wheelType==12,'server does not rewrite the saved input record while previewing')
local current=E.CurrentPreview(7)
assert(current.properties.mods['23']==-1 and current.properties.mods['4']==-1,'server current preview uses corrected wheels and exhaust for confirmation')
local apply=coroutine.create(function()return MX.unwrap(E.ApplyPreview(7,p))end)
ok,action=coroutine.resume(apply)assert(ok and action=='apply')
ok,result=coroutine.resume(apply,ack)
assert(ok and result.applied and E.CurrentPreview(7).properties.mods['23']==-1,'subsequent preview confirmation keeps recovered wheels')
print('Server preview recovery: actual Preview/ApplyPreview consume verified wheel ACKs and expose corrected properties for the existing save contract (no SQL write).')
