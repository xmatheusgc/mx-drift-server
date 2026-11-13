RpcBoundaryTest={exports={},events={},printed={},sent={},timers={},time=0}
local T=RpcBoundaryTest
function IsDuplicityVersion()return true end
function GetConvar(_,default)return default end
function GetGameTimer()return T.time end
function Wait()end
function GetPlayerName()return 'Test driver' end
function GetPlayerIdentifierByType()return 'license:fixture' end
function GetCurrentResourceName()return 'mx-freeroam-core' end
function GetResourceState()return 'started' end
function RegisterNetEvent(name,fn)T.events[name]=fn end
function AddEventHandler(name,fn)T.events[name]=fn end
function CreateThread()end
function SetTimeout(ms,fn)T.timers[#T.timers+1]={ms=ms,fn=fn} end
function TriggerEvent()end
function TriggerClientEvent(event,src,id,result)T.sent[#T.sent+1]={event=event,src=src,id=id,result=result}end
json={encode=function(value)return value end,decode=function(value)return type(value)=='table' and value or {}end}
function print(value)T.printed[#T.printed+1]=value end
MySQL={query={await=function(sql)
    if sql:find('schema_migrations',1,true)then return {{version='007_vehicle_modes.sql'}}end
    if sql:find('INSERT INTO players',1,true)then return {affectedRows=1}end
    if sql:find('SELECT id,name,created_at',1,true)then return {{id=1,name='Test driver'}}end
    if sql:find('SELECT document,revision',1,true)then return {{document='{}',revision=1}}end
    return {}
end},ready=function(fn)fn()end}
exports=setmetatable({['mx-freeroam-admin']={CheckConnection=function()end}},{__call=function(_,name,fn)
    T.exports[name]=fn
    exports['mx-freeroam-core']=exports['mx-freeroam-core'] or {}
    exports['mx-freeroam-core'][name]=function(_,...)local ok,value=pcall(fn,...)if ok then return value end return nil end
end})
