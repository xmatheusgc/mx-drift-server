MX = {}
-- Cfx converts errors crossing exports to strings. Preserve domain errors there.
function MX.fail(code, message)
    error(setmetatable({code=code,message=message or code},{__tostring=function(e) return '[MX:'..e.code..'] '..e.message..' [/MX]' end}),0)
end
function MX.error(value)
    if type(value)=='table' and type(value.code)=='string' and type(value.message)=='string' then return {code=value.code,message=value.message,detail=value.detail} end
    local code,message=tostring(value):match('%[MX:([A-Z][A-Z0-9_]*)%] (.-) %[/MX%]')
    if code then return {code=code,message=message} end
    return {code='UNAVAILABLE',message='Não foi possível confirmar o resultado. Recarregue o estado antes de tentar novamente.'}
end
function MX.diagnostic(value)
    return tostring(value):gsub('mysql://[^%s"\']+','[DATABASE URI]'):gsub('cfxk_[%w_%-]+','[LICENSE]'):sub(1,2048)
end
function MX.require(ok, code, message) if not ok then MX.fail(code, message) end return ok end
-- Catch in the resource that owns the function, before Cfx's export/function
-- reference boundary can replace a thrown value with nil.
function MX.capture(fn,...)
    local ok,result=pcall(fn,...)
    if ok then return {ok=true,data=result} end
    local failure=MX.error(result)
    if failure.code=='UNAVAILABLE' then failure.detail=MX.diagnostic(failure.detail or result) end
    failure.ok=false return failure
end
function MX.unwrap(result)
    MX.require(type(result)=='table' and type(result.ok)=='boolean','UNAVAILABLE')
    if not result.ok then error(MX.error(result),0) end
    return result.data
end
function MX.number(x,lo,hi,integer)
    return type(x)=='number' and x==x and x~=math.huge and x~=-math.huge and x>=lo and x<=hi and (not integer or x%1==0)
end
function MX.text(x,lo,hi) return type(x)=='string' and #x>=lo and #x<=hi and not x:find('[%c<>]') end
function MX.name(x) return (tostring(x or ''):gsub('[%c<>]',''):gsub('%^%d',''):sub(1,48)) end
function MX.keys(t, allowed)
    if type(t)~='table' then return false end
    for k in pairs(t) do if not allowed[k] then return false end end
    return true
end
function MX.copy(t) return json.decode(json.encode(t)) end
function MX.canonical(v)
    if type(v)~='table' then return json.encode(v) end
    local keys={} for k in pairs(v) do keys[#keys+1]=k end
    table.sort(keys,function(a,b) return tostring(a)<tostring(b) end)
    local values={} for _,k in ipairs(keys) do values[#values+1]=json.encode(tostring(k))..':'..MX.canonical(v[k]) end
    return '{'..table.concat(values,',')..'}'
end
function MX.distance(a,b) local x,y,z=a.x-b.x,a.y-b.y,a.z-b.z return math.sqrt(x*x+y*y+z*z) end
function MX.segment(a,b,p)
    local x,y,z=b.x-a.x,b.y-a.y,b.z-a.z
    local d=x*x+y*y+z*z
    local t=d>0 and math.max(0,math.min(1,((p.x-a.x)*x+(p.y-a.y)*y+(p.z-a.z)*z)/d)) or 0
    return MX.distance({x=a.x+t*x,y=a.y+t*y,z=a.z+t*z},p)
end
function MX.online(resource) return GetResourceState(resource)=='started' end
if IsDuplicityVersion() then
    MX.db = function(sql, args) return exports['mx-freeroam-core']:Query(sql,args or {}) end
    MX.tx = function(queries) return exports['mx-freeroam-core']:Transaction(queries) end
    MX.uuid = function() return MX.db('SELECT UUID() AS id')[1].id end
    MX.actor = function(src) return exports['mx-freeroam-core']:Profile(src) end
    MX.callClient = function(src,domain,action,data) return MX.unwrap(exports['mx-freeroam-core']:ClientCall(src,domain,action,data)) end
    -- Um canal por domínio. Registro estático; não há descoberta dinâmica de plugins.
    function MX.routes(domain, handlers)
        local recent={}
        RegisterNetEvent('mx:'..domain..':request',function(id,action,data)
            local src=source
            local actor
            local ok,result=pcall(function()
                MX.require(MX.text(id,1,64) and MX.text(action,1,48) and type(data)=='table','PAYLOAD','Requisição inválida')
                MX.require(#json.encode(data)<=16384,'PAYLOAD','Payload excede limite')
                actor=MX.actor(src)
                MX.require(actor and exports['mx-freeroam-core']:Guard(src,domain..':'..action),'RATE','Aguarde e tente novamente')
                MX.require(handlers[action],'ACTION','Ação indisponível')
                recent[src]=recent[src] or {}
                MX.require(not recent[src][id],'DUPLICATE','Requisição repetida')
                recent[src][id]=GetGameTimer()
                local result=MX.unwrap(exports['mx-freeroam-core']:Run(src,actor.epoch,function()
                    return MX.capture(handlers[action],src,data,actor,id)
                end))
                return MX.unwrap(result)
            end)
            if not ok then
                local failure=MX.error(result)
                if failure.code=='UNAVAILABLE' then
                    print(json.encode({level='error',domain=domain,action=action,requestId=id,actor=actor and actor.id,code='INTERNAL',detail=MX.diagnostic(failure.detail or result)}))
                    failure.message=failure.message..' Referência: '..domain..'/'..action..'/'..tostring(id)
                end
                result=failure
            end
            if not actor or (MX.actor(src) and MX.actor(src).epoch==actor.epoch) then
                TriggerClientEvent('mx:response',src,id,ok and {ok=true,data=result} or {ok=false,code=result.code,message=result.message})
            end
        end)
        AddEventHandler('playerDropped',function() recent[source]=nil end)
        CreateThread(function() while true do Wait(30000) for _,requests in pairs(recent) do for id,t in pairs(requests) do if GetGameTimer()-t>30000 then requests[id]=nil end end end end end)
    end
else
    MX.request = function(domain,action,data) return exports['mx-freeroam-core']:Request(domain,action,data or {}) end
    function MX.clients(domain,handlers)
        RegisterNetEvent('mx:'..domain..':client',function(token,action,data)
            if source~=65535 then return end
            CreateThread(function()
                local ok,result=pcall(function() MX.require(handlers[action],'ACTION') return handlers[action](data) end)
                if not ok then
                    print(json.encode({level='error',domain=domain,action=action,code='CLIENT_ERROR',detail=MX.diagnostic(result)}))
                    local failure=MX.error(result)
                    result={failure={code=failure.code,message=failure.message}}
                end
                TriggerServerEvent('mx:core:ack',token,ok,result)
            end)
        end)
    end
end
