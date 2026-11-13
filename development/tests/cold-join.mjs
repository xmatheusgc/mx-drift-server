import '../scripts/workspace.mjs';
import {lua,lauxlib,lualib,to_luastring,to_jsstring} from 'fengari';
import {readFile} from 'node:fs/promises';
const L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);
function run(code,name){if(lauxlib.luaL_loadbuffer(L,to_luastring(code),null,to_luastring(name))!==lua.LUA_OK||lua.lua_pcall(L,0,0,0)!==lua.LUA_OK)throw Error(to_jsstring(lauxlib.luaL_tolstring(L,-1)));}
async function file(path){run(await readFile(path,'utf8'),path);}
run(`function IsDuplicityVersion()return false end;function RegisterNetEvent()end;exports={};json={};function AddEventHandler()end`, 'client-adapters');
await file('resources/[mx]/mx-freeroam-core/shared.lua');
await file('resources/[mx]/mx-freeroam-experience/config.lua');
await file('resources/[mx]/mx-freeroam-vehicles/config.lua');
await file('development/tests/cold-join-env.lua');
await file('resources/[mx]/mx-freeroam-experience/scene-streaming.lua');
await file('resources/[mx]/mx-freeroam-vehicles/asset-loader.lua');
await file('development/tests/cold-join.lua');
// A separate VM exercises the real core lock and routes across a simulated Cfx
// boundary that deliberately discards uncaught exceptions like the reported logs.
const C=lauxlib.luaL_newstate();lualib.luaL_openlibs(C);
function core(code,name){if(lauxlib.luaL_loadbuffer(C,to_luastring(code),null,to_luastring(name))!==lua.LUA_OK||lua.lua_pcall(C,0,0,0)!==lua.LUA_OK)throw Error(to_jsstring(lauxlib.luaL_tolstring(C,-1)));}
core(await readFile('development/tests/rpc-boundary-env.lua','utf8'),'core-adapters');
for(const path of ['resources/[mx]/mx-freeroam-core/shared.lua','resources/[mx]/mx-freeroam-core/config.lua','resources/[mx]/mx-freeroam-core/server.lua','development/tests/rpc-boundary.lua'])core(await readFile(path,'utf8'),path);
