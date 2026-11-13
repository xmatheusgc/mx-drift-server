import '../scripts/workspace.mjs';
import {lua,lauxlib,lualib,to_luastring,to_jsstring} from 'fengari';
import {readFile} from 'node:fs/promises';
const L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);
function run(src,name){if(lauxlib.luaL_loadbuffer(L,to_luastring(src),null,to_luastring(name))!==lua.LUA_OK||lua.lua_pcall(L,0,0,0)!==lua.LUA_OK)throw Error(to_jsstring(lauxlib.luaL_tolstring(L,-1)));}
run('function IsDuplicityVersion()return false end;function RegisterNetEvent()end;exports={};json={}', 'runtime-adapters');
for(const p of ['resources/[mx]/mx-freeroam-core/shared.lua','resources/[mx]/mx-freeroam-experience/config.lua','development/tests/menu-scene-env.lua','resources/[mx]/mx-freeroam-experience/framing.lua','resources/[mx]/mx-freeroam-experience/idle.lua','resources/[mx]/mx-freeroam-experience/presentation.lua','development/tests/menu-scene.lua'])run(await readFile(p,'utf8'),p);
