EnvironmentTest={events={},exports={},kvp={},invoker='mx-freeroam-menu',oldCopy=MX.copy,oldJson=json}
local T=EnvironmentTest
local function copy(v)if type(v)~='table'then return v end local r={}for k,x in pairs(v)do r[k]=copy(x)end return r end
MX.copy=copy
local encoded={}local sequence=0
json={encode=function(v)sequence=sequence+1 local key='environment-json-'..sequence encoded[key]=copy(v)return key end,decode=function(v)assert(encoded[v],'invalid JSON')return copy(encoded[v])end}
WorldConfig={weather='CLEAR',hour=14,minute=0}
GlobalState={mxEnvironment={weather='OVERCAST',hour=18,minute=20}}
function GetInvokingResource()return T.invoker end
function GetResourceKvpString(key)return T.kvp[key]end
function SetResourceKvp(key,value)if not T.failWrite then T.kvp[key]=value end end
function AddEventHandler(name,fn)T.events[name]=fn end
exports=setmetatable({},{__call=function(_,name,fn)T.exports[name]=fn end})
