ManagementTest={events={},exports={},commands={},files={},ace={},players={[1]='license:admin',[2]='license:target'},actor={id=10,epoch='admin-epoch'},writes=0,drops={},notices={},routes={}}
local T=ManagementTest
local function copy(v) if type(v)~='table' then return v end local r={} for k,x in pairs(v) do r[k]=copy(x) end return r end
MX.copy=copy
MX.actor=function()return T.actor end
MX.online=function() return true end
MX.db=function()return {} end
MX.routes=function(domain,routes) T.routes[domain]=routes end
json={encode=function(v) T.seq=(T.seq or 0)+1 local key='encoded-'..T.seq T[key]=copy(v) return key end,decode=function(v) assert(T[v],'bad json') return copy(T[v]) end}
function GetCurrentResourceName()return T.resource or 'mx-freeroam-admin' end
function GetInvokingResource()return T.invoker or 'mx-freeroam-admin' end
function LoadResourceFile(resource,path)return T.files[resource..'/'..path] end
function SaveResourceFile(resource,path,value) if T.failDisk then return false end T.writes=T.writes+1 T.files[resource..'/'..path]=value return true end
function IsPlayerAceAllowed(src,ace)return T.ace[src..':'..ace]==true end
function GetPlayerName(src) return T.players[src] and 'Player '..src end
function GetPlayerIdentifierByType(src) return T.players[src] end
function DropPlayer(src,message) T.drops[#T.drops+1]={src=src,message=message} end
function TriggerClientEvent(name,src,message) T.notices[#T.notices+1]={name=name,src=src,message=message} end
function RegisterCommand(name,fn)T.commands[name]=fn end
function AddEventHandler(name,fn)T.events[name]=fn end
function CreateThread()end
function GetResourceState()return 'started' end
function GetPlayerRoutingBucket()return T.bucket or 0 end
function GetPlayerPed()return 101 end
function DoesEntityExist()return true end
function GetEntityCoords()return {x=100,y=200,z=6} end
function GetEntityHeading()return 90 end
exports=setmetatable({}, {__call=function(_,name,fn) T.exports[name]=fn end})
function T.grant(src,action)T.ace[src..':mx.'..action]=true end
