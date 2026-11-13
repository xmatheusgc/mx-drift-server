import '../scripts/workspace.mjs';
import {lua,lauxlib,lualib,to_luastring,to_jsstring} from 'fengari';
import {readFile} from 'node:fs/promises';
const L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);
function run(code,name){if(lauxlib.luaL_loadbuffer(L,to_luastring(code),null,to_luastring(name))!==lua.LUA_OK||lua.lua_pcall(L,0,0,0)!==lua.LUA_OK)throw Error(to_jsstring(lauxlib.luaL_tolstring(L,-1)));}
run('function IsDuplicityVersion()return false end function GetConvarInt(_,d)return d end exports={} json={} function RegisterNetEvent()end function ClearPedTasksImmediately()end','base');
run(`local saved={} local seq=0
local function copy(v)if type(v)~='table'then return v end local r={}for k,x in pairs(v)do r[k]=copy(x)end return r end
json.encode=function(v)seq=seq+1 local key='json-'..seq saved[key]=copy(v)return key end
json.decode=function(key)return copy(saved[key])end`,'JSON adapter');
for(const file of ['resources/[mx]/mx-freeroam-core/shared.lua','resources/[mx]/mx-freeroam-vehicles/config.lua','resources/[mx]/mx-freeroam-vehicles/stance-rules.lua','resources/[mx]/mx-freeroam-vehicles/properties.lua','development/tests/vehicle-apply-env.lua','resources/[mx]/mx-freeroam-vehicles/asset-loader.lua','resources/[mx]/mx-freeroam-vehicles/customization.lua','resources/[mx]/mx-freeroam-vehicles/respawn-client.lua','resources/[mx]/mx-freeroam-vehicles/client.lua','development/tests/vehicle-apply.lua','development/tests/vehicle-services.lua'])run(await readFile(file,'utf8'),file);
for(const file of ['resources/[mx]/mx-freeroam-vehicles/drift-config.lua','development/tests/vehicle-options-env.lua','resources/[mx]/mx-freeroam-vehicles/services-server.lua','resources/[mx]/mx-freeroam-vehicles/server.lua','resources/[mx]/mx-freeroam-vehicles/garage.lua','development/tests/vehicle-options.lua'])run(await readFile(file,'utf8'),file);
run(`local T=VehicleOptionsTest
local call=MX.callClient
MX.callClient=function(src,domain,action,data)
 local result=call(src,domain,action,data)
 if data.kind=='indicatorLeft' or data.kind=='indicatorRight' or data.kind=='hazards' then result.indicators=3 end
 return result
end
local v=T.exports.Active(1)
T.peds[1].car=v.entity T.cars[v.entity].driver=1
for _,kind in ipairs({'indicatorLeft','indicatorRight','hazards'})do
 local result=T.routes.service(1,{kind=kind})
 assert(T.calls[#T.calls].data.kind==kind and T.calls[#T.calls].data.driver,'indicators require authorized driver dispatch')
 assert(Entity(v.entity).state.mxIndicators.id==v.id and Entity(v.entity).state.mxIndicators.mode==3,'confirmed indicator state is replicated with vehicle identity')
 T.peds[1].car=0 T.cars[v.entity].driver=0
 assert(not pcall(T.routes.service,1,{kind=kind}),'remote/passenger indicators rejected')
 T.peds[1].car=v.entity T.cars[v.entity].driver=1
end`,'actual signal authorization');
for(const file of ['resources/[mx]/mx-freeroam-vehicles/indicators.lua'])run(await readFile(file,'utf8'),file);
run(`local T=VehicleOptionsTest local v=T.exports.Active(1)
local writes=0
function SetVehicleIndicatorLights()writes=writes+1 end
assert(VehicleIndicators.apply(v.entity,{id=v.id,mode=3}) and writes==2,'observer applies both lights')
assert(not VehicleIndicators.apply(v.entity,{id='reused',mode=1}) and writes==2,'observer rejects stale identity')
assert(not VehicleIndicators.apply(v.entity,{id=v.id,mode=4}) and writes==2,'observer rejects invalid mode')`,'observer identity');
console.log('Vehicle signals: left/right/hazards toggles, driver-only ownership and existing services passed (native/RPC doubles).');
