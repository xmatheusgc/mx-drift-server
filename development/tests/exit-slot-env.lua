ExitSlotTest={exports={}}
local T=ExitSlotTest
exports=setmetatable({},{__call=function(_,name,fn)T.exports[name]=fn end})
WorldTrainer={} WorldConfig={allowDrafts=false,destinations={}}
MX.copy=function(value)local copy={} for k,v in pairs(value)do copy[k]=v end return copy end
MX.routes=function()end
function CreateThread()end
function AddEventHandler()end
function GetGameTimer()return 0 end
function GetPlayerRoutingBucket()return 0 end
function GetAllVehicles()error('workshop exit cannot wait for traffic occupancy')end
function GetPlayers()error('workshop exit cannot wait for pedestrians')end
