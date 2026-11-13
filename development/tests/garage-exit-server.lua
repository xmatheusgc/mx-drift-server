local T=SessionTest local R=T.routes local V=exports['mx-freeroam-vehicles']
local W=exports['mx-freeroam-world'] local finished=false
local live={entity=99,id='gameplay-car',net=99}
function W:ReservePresentationExit(_,point)return {point=point,ghost=true}end
function W:Release()end
function V:SpawnSavedAt(_,row,slot)assert(slot.ghost) T.live=live return {net=99}end
function V:Active()return T.live end
function GetPedInVehicleSeat()return 1 end
function DoesEntityExist(e)return e==1 or e==99 end
MX.callClient=function(_,domain,action)
 if action=='depart' then return {running=false}end
 if action=='finish' then finished=true end
 return {ready=true}
end
local s=R.enter(1,{},T.actor)
assert(R.play(1,{token=s.token},T.actor).playing and finished and T.buckets[1]==0,'real experience play completes without engine-running confirmation')
assert(R.state(1,{},T.actor).token==nil,'successful departure closes private session even when engine is off')
-- Mandatory identity/driver checks still reject an invalid spawn before release.
T.live=nil finished=false
s=R.enter(1,{},T.actor)
function GetPedInVehicleSeat()return 2 end
local ok,err=pcall(R.play,1,{token=s.token},T.actor)
assert(not ok and err.code=='DRIVER' and not finished,'foreign driver remains a real safety failure')
print('Garage exit real route: engine off succeeds, public bucket/session completes, foreign driver rejected (adapters).')
