import '../scripts/workspace.mjs';
import {lua,lauxlib,lualib,to_luastring,to_jsstring} from 'fengari';
import {readFile} from 'node:fs/promises';
async function suite(files,setup=''){
 const L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);
 const run=(code,name)=>{if(lauxlib.luaL_loadbuffer(L,to_luastring(code),null,to_luastring(name))!==lua.LUA_OK||lua.lua_pcall(L,0,0,0)!==lua.LUA_OK)throw Error(to_jsstring(lauxlib.luaL_tolstring(L,-1)));};
 run('function IsDuplicityVersion()return false end;function RegisterNetEvent()end;exports={};json={}', 'bootstrap');
 run(await readFile('resources/[mx]/mx-freeroam-core/shared.lua','utf8'),'core');
 if(setup)run(setup,'setup');
 for(const file of files)run(await readFile(file,'utf8'),file);
}
const v='resources/[mx]/mx-freeroam-vehicles/';
await suite([v+'config.lua','development/tests/vehicle-apply-env.lua',v+'client.lua','development/tests/departure.lua'],
 'VehicleAssets={setIntent=function()end};VehicleCustomization={inspect=function()end}');
await suite([v+'config.lua','development/tests/departure-ghost-env.lua',v+'departure-ghost-server.lua','development/tests/departure-ghost-server.lua']);
await suite([v+'config.lua','development/tests/departure-ghost-env.lua',v+'departure-ghost-client.lua','development/tests/departure-ghost-client.lua']);
await suite([v+'config.lua',v+'stance-rules.lua',v+'properties.lua',v+'drift-config.lua','development/tests/vehicle-options-env.lua',v+'services-server.lua',v+'departure-ghost-server.lua',v+'server.lua','development/tests/garage-exit-spawn.lua']);
await suite(['resources/[mx]/mx-freeroam-experience/config.lua','resources/[mx]/mx-freeroam-experience/rules.lua','development/tests/session-car-env.lua','resources/[mx]/mx-freeroam-experience/server.lua','development/tests/garage-exit-server.lua']);
await suite(['development/tests/exit-slot-env.lua','resources/[mx]/mx-freeroam-world/server.lua','development/tests/exit-slot.lua']);
