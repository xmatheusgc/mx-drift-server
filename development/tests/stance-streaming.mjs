import '../scripts/workspace.mjs';
import {lua,lauxlib,lualib,to_luastring,to_jsstring} from 'fengari';
import {readFile} from 'node:fs/promises';
const L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);
function run(code,name){if(lauxlib.luaL_loadbuffer(L,to_luastring(code),null,to_luastring(name))!==lua.LUA_OK||lua.lua_pcall(L,0,0,0)!==lua.LUA_OK)throw Error(to_jsstring(lauxlib.luaL_tolstring(L,-1)));}
run('function IsDuplicityVersion()return false end;function GetConvarInt(_,v)return v end;function RegisterNetEvent()end;exports={};json={}','environment');
for(const name of ['core/shared.lua','vehicles/config.lua','vehicles/stance-rules.lua','vehicles/properties.lua','vehicles/customization.lua'])run(await readFile('resources/[mx]/mx-freeroam-'+name,'utf8'),name);
run(await readFile('development/tests/customization.lua','utf8'),'discovery-adapters-and-contracts');
run(await readFile('development/tests/stance-env.lua','utf8'),'stance-adapters');
run(await readFile('resources/[mx]/mx-freeroam-vehicles/stance.lua','utf8'),'actual-stance');
for(const name of ['stance','stance-spawn','stance-streaming'])run(await readFile(`development/tests/${name}.lua`,'utf8'),name);
