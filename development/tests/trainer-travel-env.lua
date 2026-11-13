local T=TrainerTest
MX.distance=function(a,b)return math.sqrt((a.x-b.x)^2+(a.y-b.y)^2+(a.z-b.z)^2)end
WorldConfig.destinations={home={id='home',validated=true,slots={{x=12,y=24,z=6,h=135}}}}
MX.routes=function(domain,handlers) T.routes=handlers end
function GetAllVehicles() return T.blocked and {10,20} or {10} end
function GetPlayers() return {'1'} end
function GetEntityRoutingBucket() return 0 end
function SetEntityCoords(e,x,y,z) SetEntityCoordsNoOffset(e,x,y,z) end
T.cars[20]={x=12,y=24,z=6,h=0}
local actual=MX.callClient
MX.callClient=function(src,domain,action,data)
 if domain=='world' and action=='travel' then
  local e=data.net and NetToVeh(data.net) or GetPlayerPed(src)
  T.lastTravel=data
  if T.teleportFailure then return {arrived=false} end
  SetEntityCoords(e,data.point.x,data.point.y,data.point.z) SetEntityHeading(e,data.point.h)
  return {arrived=true}
 end
 return actual(src,domain,action,data)
end
