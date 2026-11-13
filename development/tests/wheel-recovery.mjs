import '../scripts/workspace.mjs';
import {lua,lauxlib,lualib,to_luastring,to_jsstring} from 'fengari';
import {readFile} from 'node:fs/promises';
const L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);
function run(code,name){if(lauxlib.luaL_loadbuffer(L,to_luastring(code),null,to_luastring(name))!==lua.LUA_OK||lua.lua_pcall(L,0,0,0)!==lua.LUA_OK)throw Error(to_jsstring(lauxlib.luaL_tolstring(L,-1)));}
run("function IsDuplicityVersion()return false end;function GetConvarInt(_,v)return v end;function RegisterNetEvent()end;exports={};json={encode=function()return '{}' end}",'environment');
for(const name of ['core/shared.lua','vehicles/config.lua','vehicles/stance-rules.lua','vehicles/properties.lua','vehicles/customization.lua'])run(await readFile('resources/[mx]/mx-freeroam-'+name,'utf8'),name);
run('function MX.copy(value) if type(value)~="table" then return value end local result={} for k,v in pairs(value)do result[k]=MX.copy(v)end return result end','document-copy-adapter');
run(await readFile('development/tests/vehicle-apply-env.lua','utf8'),'apply-adapters');
run('function TriggerEvent()end','notice-adapter');
for(const name of ['asset-loader','respawn-client','client'])run(await readFile(`resources/[mx]/mx-freeroam-vehicles/${name}.lua`,'utf8'),name);
run(await readFile('development/tests/vehicle-apply.lua','utf8'),'existing-apply-regressions');
run(await readFile('development/tests/wheel-recovery.lua','utf8'),'wheel-recovery');
run(await readFile('development/tests/preview-env.lua','utf8'),'preview-server-adapters');
for(const name of ['preview-state','garage'])run(await readFile(`resources/[mx]/mx-freeroam-vehicles/${name}.lua`,'utf8'),name);
run(await readFile('development/tests/wheel-recovery-preview.lua','utf8'),'wheel-recovery-preview-ack');
