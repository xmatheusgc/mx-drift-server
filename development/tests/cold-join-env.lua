ColdJoinTest={time=0,sceneAt=0,interiorAt=0,modelAt=0,collisionAt=0,stops=0,clears=0,unpins=0,registered=true,mapStarted=true}
local T=ColdJoinTest
T.progress={}
function TriggerEvent(name,data)if name=='mx:loadingProgress' then T.progress[#T.progress+1]=data end end
json.encode=function()return 'streaming timeout diagnostic (test adapter)' end
function GetGameTimer()return T.time end
function Wait(ms)T.time=T.time+ms if T.onWait then T.onWait() end end
function GetCurrentResourceName()return 'unit-experience' end
function GetResourceState()return T.mapStarted and 'started' or 'stopped' end
function PlayerPedId()return 1 end
function FreezeEntityPosition(_,value)T.frozen=value end
function SetEntityCoordsNoOffset()end
function SetEntityHeading()end
function SetFocusPosAndVel()T.focus=true end
function ClearFocus()T.clears=T.clears+1 T.focus=false end
function NewLoadSceneStartSphere()return true end
function NewLoadSceneStop()T.stops=T.stops+1 end
function IsNewLoadSceneLoaded()return T.time>=T.sceneAt end
function RequestCollisionAtCoord()end
function HasCollisionLoadedAroundEntity()return T.time>=T.collisionAt end
function joaat(name)return name end
function RequestModel(hash)assert(IsModelInCdimage(hash),'unknown model must not be requested') T.requested=hash T.requestedAt=T.time T.requests=(T.requests or 0)+1 end
function HasModelLoaded()return T.time>=T.modelAt end
function IsModelInCdimage()return T.registered and T.time>=(T.registrationAt or 0) end
function IsModelAVehicle()return true end
function SetModelAsNoLongerNeeded()T.released=true end
function GetInteriorAtCoords()return T.time>=T.interiorAt and 42 or 0 end
function PinInteriorInMemory(id)T.pinned=id end
function UnpinInterior()T.unpins=T.unpins+1 T.pinned=nil end
function IsInteriorReady()return T.time>=T.interiorAt end
