import '../scripts/workspace.mjs';
import {lua,lauxlib,lualib,to_luastring,to_jsstring} from 'fengari';
import {readFile} from 'node:fs/promises';
async function suite(files){
 const L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);
 function run(code,name){if(lauxlib.luaL_loadbuffer(L,to_luastring(code),null,to_luastring(name))!==lua.LUA_OK||lua.lua_pcall(L,0,0,0)!==lua.LUA_OK)throw Error(to_jsstring(lauxlib.luaL_tolstring(L,-1)));}
 run("function IsDuplicityVersion()return false end;function GetConvarInt(_,v)return v end;function RegisterNetEvent()end;function RegisterCommand()end;exports={};json={encode=function()return '{}'end}",'environment');
 for(const file of ['resources/[mx]/mx-freeroam-core/shared.lua','resources/[mx]/mx-freeroam-vehicles/drift-config.lua','development/tests/drift-env.lua','resources/[mx]/mx-freeroam-vehicles/drift-client.lua',...files]){
  run(await readFile(file,'utf8'),file);
  if(file.endsWith('core/shared.lua'))run('function MX.copy(v)if type(v)~="table"then return v end local r={}for k,x in pairs(v)do r[k]=MX.copy(x)end return r end','copy adapter');
 }
}
await suite(['development/tests/drift.lua','development/tests/drift-recovery.lua']);
await suite(['resources/[mx-scripts]/mx-gearbox/shared/config.lua','development/tests/gearbox-drift-env.lua','resources/[mx-scripts]/mx-gearbox/client/main.lua','development/tests/gearbox-drift.lua']);
