import '../scripts/workspace.mjs';
import {lua,lauxlib,lualib,to_luastring,to_jsstring} from 'fengari';
import {readFile} from 'node:fs/promises';
const L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);
function run(code,name){if(lauxlib.luaL_loadbuffer(L,to_luastring(code),null,to_luastring(name))!==lua.LUA_OK||lua.lua_pcall(L,0,0,0)!==lua.LUA_OK)throw Error(to_jsstring(lauxlib.luaL_tolstring(L,-1)));}
run("function IsDuplicityVersion()return false end;function GetConvarInt(_,d)return d end;function RegisterNetEvent()end;exports={};json={}",'environment');
for(const f of ['resources/[mx]/mx-freeroam-core/shared.lua','development/tests/trainer-menu-env.lua','resources/[mx]/mx-freeroam-menu/navigation.lua','resources/[mx]/mx-freeroam-menu/hud.lua','resources/[mx]/mx-freeroam-menu/client.lua','development/tests/pause-hud.lua'])run(await readFile(f,'utf8'),f);
const core=await readFile('resources/[mx]/mx-freeroam-core/server.lua','utf8');
const start=core.indexOf('local function validatePrefs'),end=core.indexOf("MX.routes('core'",start);
run('ValidatePreferences=(function() '+core.slice(start,end)+' return validatePrefs end)()','actual preference validation');
run(`local p={hud=true,share=true,uniform=false,photo=false,units='kmh',blips='all',invites='all',scale=1,volume=.3,appearance='driver',outfit=0,muted={}}
assert(ValidatePreferences(p).transmission=='automatic','legacy transmission defaults to automatic')p.transmission='manual' assert(ValidatePreferences(p).transmission=='manual','manual accepted')p.transmission='invalid' assert(not pcall(ValidatePreferences,p),'invalid transmission rejected')p.transmission='automatic'
assert(ValidatePreferences(p).minimap==true,'legacy default')p.minimap=false assert(ValidatePreferences(p).minimap==false,'explicit false')p.minimap='false' assert(not pcall(ValidatePreferences,p),'invalid type rejected')`,'preference compatibility');
console.log('Core preference backward compatibility and strict minimap validation passed.');
