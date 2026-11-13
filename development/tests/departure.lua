-- Actual vehicles/depart handler, native runtime adapters only.
local T=VehicleApplyTest local now=0 local crank=100 local run=true local swapped=false
local engine,brake,frozen,driver=false,false,false,true
function GetGameTimer()return now end
function Wait()now=now+25 if swapped and now>=100 then T.cars[71].id='unrelated' end end
function PlayerPedId()return 1 end
function GetPedInVehicleSeat()return driver and 1 or 0 end
function SetVehicleEngineOn(_,enabled)engine=enabled end
function GetIsVehicleEngineRunning()return engine and run and now>=crank and 1 or 0 end
function FreezeEntityPosition(_,enabled)frozen=enabled end
function SetVehicleHandbrake(_,enabled)brake=enabled end
function DisableControlAction()end
function SetControlNormal(_,_,value)assert(value==0,'departure cannot accelerate during starter hold')end
local function start()return T.handlers.depart({net=71,id='test:71',minimumMs=450})end
assert(start().running and now==450 and engine and not frozen and not brake,'brief starter hold releases with engine running')
now=0 crank=700
assert(not start().running and now==450 and not frozen and not brake,'slow starter does not hold departure')
now=0 crank=0 run=false
assert(not start().running and now==450 and engine and not frozen and not brake,'failed starter releases departure without treating engine state as failure')
now=0 run=true driver=false
assert(not pcall(start) and now==0,'passenger cannot start departure')
driver=true now=0 swapped=true
assert(not pcall(start) and now==100 and T.cars[71].id=='unrelated','identity change aborts instead of touching a recycled entity')
T.cars[71].id='test:71'
print('Departure handler passed: brief hold, optional engine state, release on failed/slow starter, driver and identity; native adapters only.')
