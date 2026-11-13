import '../scripts/workspace.mjs';
import {lua,lauxlib,lualib,to_luastring,to_jsstring} from 'fengari';
import {readFile} from 'node:fs/promises';
const L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);
function run(code,name){if(lauxlib.luaL_loadbuffer(L,to_luastring(code),null,to_luastring(name))!==lua.LUA_OK||lua.lua_pcall(L,0,0,0)!==lua.LUA_OK)throw Error(to_jsstring(lauxlib.luaL_tolstring(L,-1)));}
for(const name of ['config','math','chase'])run(await readFile(`resources/[mx]/mx-freeroam-drivecam/${name}.lua`,'utf8'),name);
// Keep the established road/keyboard framing contracts as the disabled A/B
// profile. Exercise the experimental enabled profile explicitly below.
run('DrivecamPivotDefault=DrivecamConfig.rearPivotBack; DrivecamConfig.rearPivotBack=0','pivot-disabled-profile');
run(await readFile('development/tests/drivecam.lua','utf8'),'drivecam-solver');
run(await readFile('development/tests/drivecam-road.lua','utf8'),'drivecam-road-framing');
run(await readFile('development/tests/drivecam-keyboard.lua','utf8'),'drivecam-keyboard-corrections');
run(await readFile('development/tests/drivecam-steady.lua','utf8'),'drivecam-steady-follow');
run(await readFile('development/tests/drivecam-slopes.lua','utf8'),'drivecam-slopes');
run('DrivecamConfig.rearPivotBack=DrivecamPivotDefault','pivot-enabled-profile');
run(await readFile('development/tests/drivecam-pivot.lua','utf8'),'drivecam-rear-pivot');
run(await readFile('development/tests/drivecam-env.lua','utf8'),'drivecam-native-adapters');
run(await readFile('resources/[mx]/mx-freeroam-drivecam/client.lua','utf8'),'actual-drivecam-client');
run(await readFile('development/tests/drivecam-client.lua','utf8'),'drivecam-lifecycle');
