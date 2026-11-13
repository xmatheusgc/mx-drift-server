import '../scripts/workspace.mjs';
import {lua,lauxlib,lualib,to_luastring,to_jsstring} from 'fengari';
import {readFile} from 'node:fs/promises';
const L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);
function run(code,name){if(lauxlib.luaL_loadbuffer(L,to_luastring(code),null,to_luastring(name))!==lua.LUA_OK||lua.lua_pcall(L,0,0,0)!==lua.LUA_OK)throw Error(to_jsstring(lauxlib.luaL_tolstring(L,-1)));}
run('function IsDuplicityVersion()return false end;function GetConvarInt(_,d)return d end;function RegisterNetEvent()end;exports={};json={}','bootstrap');
for(const f of ['resources/[mx]/mx-freeroam-core/shared.lua','resources/[mx]/mx-freeroam-experience/config.lua','resources/[mx]/mx-freeroam-experience/rules.lua'])run(await readFile(f,'utf8'),f);
run('function MX.copy(v)if type(v)~="table"then return v end local r={}for k,x in pairs(v)do r[k]=MX.copy(x)end return r end','copy adapter');
for(const f of ['development/tests/session-car-env.lua','resources/[mx]/mx-freeroam-experience/server.lua','development/tests/session-car.lua'])run(await readFile(f,'utf8'),f);
