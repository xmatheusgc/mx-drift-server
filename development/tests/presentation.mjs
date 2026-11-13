import '../scripts/workspace.mjs';
import {lua,lauxlib,lualib,to_luastring,to_jsstring} from 'fengari';
import {readFile} from 'node:fs/promises';
const L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);
function execute(code,name){
 if(lauxlib.luaL_loadbuffer(L,to_luastring(code),null,to_luastring(name))!==lua.LUA_OK||lua.lua_pcall(L,0,0,0)!==lua.LUA_OK)throw Error(to_jsstring(lauxlib.luaL_tolstring(L,-1)));
}
execute('function IsDuplicityVersion() return false end; function GetConvarInt(_, d) return d end; exports={}; json={}; function RegisterNetEvent() end','environment');
for(const file of [
 'resources/[mx]/mx-freeroam-core/shared.lua',
 'resources/[mx]/mx-freeroam-experience/config.lua',
 'development/tests/presentation-env.lua',
 'resources/[mx]/mx-freeroam-experience/framing.lua',
 'resources/[mx]/mx-freeroam-experience/idle.lua',
 'resources/[mx]/mx-freeroam-experience/presentation.lua',
 'development/tests/presentation.lua',
 'development/tests/neon-startup.lua',
 'development/tests/presentation-doors.lua',
])execute(await readFile(file,'utf8'),file);
