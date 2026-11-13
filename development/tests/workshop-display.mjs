import '../scripts/workspace.mjs';
import {lua,lauxlib,lualib,to_luastring,to_jsstring} from 'fengari';
import {readFile} from 'node:fs/promises';
const L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);
function run(code,name){if(lauxlib.luaL_loadbuffer(L,to_luastring(code),null,to_luastring(name))!==lua.LUA_OK||lua.lua_pcall(L,0,0,0)!==lua.LUA_OK)throw Error(to_jsstring(lauxlib.luaL_tolstring(L,-1)));}
for(const p of ['development/tests/workshop-display-env.lua','resources/[mx]/mx-freeroam-core/shared.lua','resources/[mx]/mx-freeroam-experience/config.lua','resources/[mx]/mx-freeroam-vehicles/display-client.lua','development/tests/workshop-display.lua','resources/[mx]/mx-freeroam-experience/display.lua','development/tests/workshop-display-controller.lua','development/tests/workshop-display-swap.lua'])run(await readFile(p,'utf8'),p);
