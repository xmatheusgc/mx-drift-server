import '../scripts/workspace.mjs';
import {lua,lauxlib,lualib,to_luastring,to_jsstring} from 'fengari';
import {readFile} from 'node:fs/promises';
const L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);
function run(code,name){if(lauxlib.luaL_loadbuffer(L,to_luastring(code),null,to_luastring(name))!==lua.LUA_OK||lua.lua_pcall(L,0,0,0)!==lua.LUA_OK)throw Error(to_jsstring(lauxlib.luaL_tolstring(L,-1)));}
run(`function IsDuplicityVersion()return false end function GetConvarInt(_,d)return d end function RegisterNetEvent()end
local encoded={} local seq=0
local function copy(v)if type(v)~='table'then return v end local r={}for k,x in pairs(v)do r[k]=copy(x)end return r end
json={encode=function(v)seq=seq+1 local k='fixture-'..seq encoded[k]=copy(v) return k end,decode=function(k)return copy(encoded[k])end}
ManagementTest={events={}}
function AddEventHandler(k,fn)ManagementTest.events[k]=fn end
exports=setmetatable({},{__call=function()end})`,'base adapters');
for(const file of ['resources/[mx]/mx-freeroam-core/shared.lua','resources/[mx]/mx-freeroam-menu/bindings.lua','development/tests/bindings.lua'])run(await readFile(file,'utf8'),file);
for(const file of ['resources/[mx]/mx-freeroam-menu/binding-capture.lua','development/tests/binding-capture.lua'])run(await readFile(file,'utf8'),file);
run("MenuBindings=nil;function PlayerPedId()return 1 end;function GetCurrentResourceName()return 'mx-freeroam-menu' end;function TriggerServerEvent()end",'reset for existing menu regressions');
for(const file of ['development/tests/trainer-menu-env.lua','resources/[mx]/mx-freeroam-menu/navigation.lua','resources/[mx]/mx-freeroam-menu/client.lua','development/tests/trainer-menu.lua','development/tests/menu-controller.lua'])run(await readFile(file,'utf8'),file);
for(const file of ['resources/[mx]/mx-freeroam-menu/vehicle-input.lua','development/tests/vehicle-input.lua'])run(await readFile(file,'utf8'),file);
