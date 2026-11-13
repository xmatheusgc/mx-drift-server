WorldPreviewTest={threads={},exports={},handlers={},weather=nil,clock=nil,invoker='mx-freeroam-experience'}
local T=WorldPreviewTest
WorldConfig={traffic=0,pedestrians=0,hour=14,weather='EXTRASUNNY'}
exports=setmetatable({},{__call=function(_,name,fn)T.exports[name]=fn end})
function CreateThread(fn)T.threads[#T.threads+1]=coroutine.create(fn)end
function Wait()coroutine.yield()end
function AddEventHandler(name,fn)T.handlers[name]=fn end
function RegisterCommand()end
MX.clients=function()end
function GetInvokingResource()return T.invoker end
function SetVehiclePopulationBudget(value)T.vehicleBudget=value end
function SetPedPopulationBudget(value)T.pedBudget=value end
function SetReduceVehicleModelBudget(value)T.reduceVehicles=value end
function SetReducePedModelBudget(value)T.reducePeds=value end
function SetVehicleDensityMultiplierThisFrame()end
function SetRandomVehicleDensityMultiplierThisFrame()end
function SetParkedVehicleDensityMultiplierThisFrame()end
function SetPedDensityMultiplierThisFrame()end
function SetScenarioPedDensityMultiplierThisFrame()end
function DisableControlAction(_,control)if control==80 then T.cinematicBlocked=true end end
function SetCinematicButtonActive(value)T.cinematicButton=value end
T.cinematicActive=true
function IsCinematicCamRendering()return T.cinematicActive end
function SetCinematicModeActive(value)T.cinematicActive=value end
function GetCurrentResourceName()return 'mx-freeroam-world'end
function DisablePlayerFiring()end
function SetWeatherTypeNowPersist(v)T.weather=v end
function SetWeatherTypeTransition(a,b,f)T.blend={a=a,b=b,f=f}end
function NetworkOverrideClockTime(h,m,s)T.clock={h=h,m=m,s=s}end
