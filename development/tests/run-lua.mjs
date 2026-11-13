import '../scripts/workspace.mjs';
import {lua,lauxlib,lualib,to_luastring,to_jsstring} from 'fengari';
import {readFile,readdir} from 'node:fs/promises';
import path from 'node:path';
import os from 'node:os';
import {writeFile} from 'node:fs/promises';
const L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);
function execute(code,name){if(lauxlib.luaL_loadbuffer(L,to_luastring(code),null,to_luastring(name))!==lua.LUA_OK||lua.lua_pcall(L,0,0,0)!==lua.LUA_OK)throw Error(to_jsstring(lauxlib.luaL_tolstring(L,-1)));}
async function walk(dir){let files=[];for(const f of await readdir(dir,{withFileTypes:true})){const p=path.join(dir,f.name);if(f.isDirectory())files.push(...await walk(p));else if(p.endsWith('.lua'))files.push(p);}return files;}
let count=0;for(const file of await walk('resources/[mx]')){const src=await readFile(file,'utf8');if(lauxlib.luaL_loadbuffer(L,to_luastring(src),null,to_luastring(file))!==lua.LUA_OK)throw Error(to_jsstring(lua.lua_tostring(L,-1)));lua.lua_pop(L,1);count++;}
execute('function IsDuplicityVersion() return false end; function GetConvarInt(_, d) return d end; exports={}; json={}; function RegisterNetEvent() end','environment');
for(const f of ['core/shared.lua','vehicles/config.lua','vehicles/stance-rules.lua','vehicles/properties.lua','social/config.lua','social/rules.lua','activities/config.lua','activities/rules.lua','progression/config.lua','progression/rules.lua'])execute(await readFile('resources/[mx]/mx-freeroam-'+f,'utf8'),f);
execute(await readFile('development/tests/rules.lua','utf8'),'rules');
execute(await readFile('development/tests/rpc-errors.lua','utf8'),'rpc-export-errors');
await import('./cold-join.mjs');
await import('./loading-recovery.mjs');
await import('./garage-exit.mjs');
await import('./workshop-display.mjs');
await import('./admin-tools.mjs');
await import('./menu-scene.mjs');
await import('./camera-developer.mjs');
await import('./drivecam.mjs');
await import('./wheel-recovery.mjs');
await import('./gearbox-drift.mjs');
await import('./menu-controller.mjs');
await import('./interface-navigation.mjs');
await import('./pause-hud.mjs');
for(const f of ['experience/config.lua','experience/rules.lua','drivecam/config.lua','drivecam/math.lua'])execute(await readFile('resources/[mx]/mx-freeroam-'+f,'utf8'),f);
execute(await readFile('development/tests/experience.lua','utf8'),'experience');
execute(await readFile('resources/[mx]/mx-freeroam-experience/camera.lua','utf8'),'camera');
execute(await readFile('development/tests/camera.lua','utf8'),'camera-tests');
execute(await readFile('resources/[mx]/mx-freeroam-vehicles/customization.lua','utf8'),'actual-customization');
execute(await readFile('development/tests/customization.lua','utf8'),'customization-contracts');
execute(await readFile('development/tests/stance-env.lua','utf8'),'stance-native-doubles');
execute(await readFile('resources/[mx]/mx-freeroam-vehicles/stance.lua','utf8'),'actual-stance');
execute(await readFile('development/tests/stance.lua','utf8'),'stance-contract-tests');
execute(await readFile('development/tests/stance-spawn.lua','utf8'),'stance-spawn-regressions');
execute(await readFile('development/tests/stance-streaming.lua','utf8'),'stance-streaming-regressions');
execute(await readFile('development/tests/preview-env.lua','utf8'),'preview-test-scheduler');
execute(await readFile('resources/[mx]/mx-freeroam-vehicles/preview-state.lua','utf8'),'preview-state');
execute(await readFile('resources/[mx]/mx-freeroam-vehicles/garage.lua','utf8'),'actual-preview-controller');
execute(await readFile('development/tests/workshop-display-query.lua','utf8'),'workshop-display-query');
execute(await readFile('development/tests/preview-lifecycle.lua','utf8'),'preview-lifecycle-tests');
execute(await readFile('development/tests/presentation-env.lua','utf8'),'presentation-native-doubles');
execute(await readFile('resources/[mx]/mx-freeroam-experience/framing.lua','utf8'),'actual-part-framing');
execute(await readFile('resources/[mx]/mx-freeroam-experience/orbit.lua','utf8'),'actual-orbit-controller');
execute(await readFile('development/tests/orbit.lua','utf8'),'orbit-regressions');
execute(await readFile('resources/[mx]/mx-freeroam-experience/idle.lua','utf8'),'actual-presentation-idles');
execute(await readFile('resources/[mx]/mx-freeroam-experience/presentation.lua','utf8'),'actual-presentation-controller');
execute(await readFile('development/tests/presentation.lua','utf8'),'presentation-contract-tests');
execute(await readFile('development/tests/neon-startup.lua','utf8'),'neon-startup-regressions');
execute(await readFile('development/tests/presentation-doors.lua','utf8'),'presentation-door-regressions');
execute(await readFile('development/tests/leave-env.lua','utf8'),'leave-environment');
execute('WorkshopStreaming={stop=function()end}', 'scene-cleanup-adapter');
execute(await readFile('resources/[mx]/mx-freeroam-experience/entry-transfer.lua','utf8'),'actual-entry-transfer');
execute(await readFile('resources/[mx]/mx-freeroam-experience/client.lua','utf8'),'actual-experience-client');
execute(await readFile('development/tests/leave.lua','utf8'),'actual-leave-handler');
execute(await readFile('development/tests/lobby-ack-env.lua','utf8'),'lobby-ack-adapters');
execute(await readFile('resources/[mx]/mx-freeroam-experience/client.lua','utf8'),'actual-lobby-client');
execute(await readFile('development/tests/lobby-ack.lua','utf8'),'lobby-ack-lifecycle');
execute(await readFile('development/tests/orbit-client.lua','utf8'),'orbit-client-lifecycle');
execute(await readFile('development/tests/menu-scene-client.lua','utf8'),'actual-menu-fixed-placement');
execute(await readFile('development/tests/network-scope-env.lua','utf8'),'network-scope-environment');
execute(await readFile('resources/[mx]/mx-freeroam-vehicles/network.lua','utf8'),'actual-vehicle-network-resolver');
execute(await readFile('development/tests/network-scope.lua','utf8'),'network-scope-tests');
execute(await readFile('resources/[mx]/mx-freeroam-menu/navigation.lua','utf8'),'actual-controller-gate');
execute(await readFile('development/tests/navigation.lua','utf8'),'controller-gate-regressions');
await import('./latest-preview.mjs');
await import('./api-pacing.mjs');
await import('./catalog.mjs');
execute(await readFile('development/tests/session-car-env.lua','utf8'),'session-car-adapters');
execute(await readFile('resources/[mx]/mx-freeroam-experience/server.lua','utf8'),'actual-experience-server');
execute(await readFile('development/tests/session-car.lua','utf8'),'session-car-integration');
execute(await readFile('development/tests/entry-server.lua','utf8'),'entry-server-replication-regressions');
execute(await readFile('development/tests/environment-env.lua','utf8'),'personal-environment-adapters');
execute(await readFile('resources/[mx]/mx-freeroam-world/environment.lua','utf8'),'actual-personal-environment');
execute(await readFile('development/tests/environment.lua','utf8'),'personal-environment-regressions');
execute(await readFile('development/tests/environment-cycle-env.lua','utf8'),'environment-cycle-adapters');
execute(await readFile('resources/[mx]/mx-freeroam-world/config.lua','utf8'),'actual-dynamic-world-config');
execute(await readFile('resources/[mx]/mx-freeroam-world/environment-server.lua','utf8'),'actual-environment-publisher');
execute(await readFile('development/tests/environment-cycle.lua','utf8'),'dynamic-environment-regressions');
execute(await readFile('development/tests/world-preview-env.lua','utf8'),'world-preview-adapters');
execute(await readFile('resources/[mx]/mx-freeroam-world/environment.lua','utf8'),'actual-world-environment');
execute(await readFile('resources/[mx]/mx-freeroam-world/client.lua','utf8'),'actual-world-client');
execute(await readFile('development/tests/world-preview.lua','utf8'),'world-preview-checks');
execute(await readFile('development/tests/vehicle-apply-env.lua','utf8'),'vehicle-apply-adapters');
execute(await readFile('resources/[mx]/mx-freeroam-vehicles/asset-loader.lua','utf8'),'actual-vehicle-assets');
execute(await readFile('resources/[mx]/mx-freeroam-vehicles/customization.lua','utf8'),'actual-customization-apply');
execute(await readFile('resources/[mx]/mx-freeroam-vehicles/respawn-client.lua','utf8'),'actual-vehicle-respawn-transfer');
execute(await readFile('resources/[mx]/mx-freeroam-vehicles/client.lua','utf8'),'actual-vehicle-client');
execute(await readFile('development/tests/vehicle-apply.lua','utf8'),'vehicle-apply-regressions');
execute(await readFile('development/tests/vehicle-services.lua','utf8'),'vehicle-service-regressions');
execute(await readFile('development/tests/departure.lua','utf8'),'departure-regressions');
execute(await readFile('resources/[mx]/mx-freeroam-world/trainer-config.lua','utf8'),'trainer-settings');
execute(await readFile('development/tests/trainer-env.lua','utf8'),'trainer-adapters');
execute(await readFile('resources/[mx]/mx-freeroam-world/trainer-server.lua','utf8'),'actual-trainer-server');
execute(await readFile('development/tests/trainer-server.lua','utf8'),'trainer-server-regressions');
execute(await readFile('resources/[mx]/mx-freeroam-world/trainer-client.lua','utf8'),'actual-trainer-client');
execute(await readFile('development/tests/trainer-client.lua','utf8'),'trainer-client-regressions');
execute(await readFile('resources/[mx]/mx-freeroam-world/client.lua','utf8'),'actual-checkpoint-world-client');
execute(await readFile('development/tests/checkpoint-client.lua','utf8'),'checkpoint-client-regressions');
execute(await readFile('development/tests/trainer-travel-env.lua','utf8'),'trainer-travel-adapters');
execute(await readFile('resources/[mx]/mx-freeroam-world/server.lua','utf8'),'actual-trainer-world-server');
execute(await readFile('development/tests/trainer-travel.lua','utf8'),'trainer-travel-regressions');
execute(await readFile('resources/[mx]/mx-freeroam-world/admin-travel.lua','utf8'),'actual-admin-world-export');
execute(await readFile('development/tests/admin-world-travel.lua','utf8'),'admin-actual-world-integration');
execute(await readFile('development/tests/trainer-menu-env.lua','utf8'),'trainer-menu-adapters');
execute(await readFile('resources/[mx]/mx-freeroam-menu/client.lua','utf8'),'actual-trainer-menu-bridge');
execute(await readFile('development/tests/trainer-menu.lua','utf8'),'trainer-menu-regressions');
execute(await readFile('development/tests/entry-transfer-env.lua','utf8'),'entry-transfer-adapters');
execute(await readFile('resources/[mx]/mx-freeroam-experience/entry-transfer.lua','utf8'),'actual-entry-transfer-cleanup');
execute(await readFile('development/tests/entry-transfer.lua','utf8'),'entry-transfer-regressions');
execute(await readFile('development/tests/entry-client-failure-env.lua','utf8'),'entry-client-failure-adapters');
execute(await readFile('resources/[mx]/mx-freeroam-experience/client.lua','utf8'),'actual-entry-client-failure');
execute(await readFile('development/tests/entry-client-failure.lua','utf8'),'entry-client-failure-regression');
console.log(`${count} arquivos Lua analisados; regras executadas em Fengari (não substitui runtime Cfx/Lua 5.4).`);
if(process.argv.includes('--load')){const start=performance.now();execute(await readFile('development/tests/load.lua','utf8'),'load');const elapsed=performance.now()-start;await writeFile('docs/evidence/load.json',JSON.stringify({kind:'synthetic_rule_filter_only',players:20,snapshots:600,comparisons:240000,elapsedMs:elapsed,engine:'Fengari 0.1.5 / Node '+process.version,cpu:os.cpus()[0].model,hardwareThreads:os.cpus().length,gameClients:0,networkPacketsMeasured:false},null,2));}

execute(await readFile('development/tests/trainer-management-env.lua','utf8'),'management-adapters');
execute(await readFile('resources/[mx]/mx-freeroam-admin/moderation.lua','utf8'),'actual-moderation');
execute(await readFile('development/tests/moderation.lua','utf8'),'moderation-regressions');
execute(await readFile('resources/[mx]/mx-freeroam-admin/moderation.lua','utf8'),'moderation-restart');
execute("assert(ManagementTest.exports.CheckConnection('license:target'),'ban survives resource reload');ManagementTest.commands.mxunban(1,{'license:target'});assert(not ManagementTest.exports.CheckConnection('license:target'),'authorized unban persists');ManagementTest.ace['1:mx.admin']=false",'ban-reload');
execute(await readFile('resources/[mx]/mx-freeroam-admin/tools-server.lua','utf8'),'actual-admin-read-tools');
execute(await readFile('resources/[mx]/mx-freeroam-admin/server.lua','utf8'),'actual-admin-routes');
execute("assert(not ManagementTest.routes.admin.permissions(1).ban,'per-action permission cannot bypass admin gate');assert(not pcall(ManagementTest.routes.admin.inspect,1),'diagnostics are server-protected');assert(not pcall(ManagementTest.routes.admin.createTeleport,1,{name='Track',category='Circuito'}),'teleport RPC is server-protected');ManagementTest.ace['1:mx.admin']=true;WorldConfig={destinations={}};ManagementTest.resource='mx-freeroam-world'",'admin-route-security');
execute(await readFile('resources/[mx]/mx-freeroam-world/teleports.lua','utf8'),'actual-teleport-authoring');
execute(await readFile('development/tests/teleports.lua','utf8'),'teleport-authoring-regressions');
execute('WorldConfig.destinations={}', 'reset-track-memory');
execute(await readFile('resources/[mx]/mx-freeroam-world/teleports.lua','utf8'),'teleport-restart');
execute("assert(WorldConfig.destinations[ManagementTest.trackId],'teleport survives resource reload')",'teleport-reload');
execute(await readFile('resources/[mx]/mx-freeroam-menu/bindings.lua','utf8'),'actual-bindings');
execute(await readFile('development/tests/bindings.lua','utf8'),'binding-regressions');

execute(await readFile('resources/[mx]/mx-freeroam-vehicles/drift-config.lua','utf8'),'actual-drift-preset');
execute(await readFile('development/tests/drift-env.lua','utf8'),'drift-native-adapters');
execute(await readFile('resources/[mx]/mx-freeroam-vehicles/drift-client.lua','utf8'),'actual-drift-controller');
execute(await readFile('development/tests/drift.lua','utf8'),'drift-regressions');
execute(await readFile('development/tests/drift-recovery.lua','utf8'),'drift-recovery-regressions');

execute(await readFile('development/tests/vehicle-options-env.lua','utf8'),'vehicle-options-server-adapters');
execute(await readFile('resources/[mx]/mx-freeroam-vehicles/services-server.lua','utf8'),'actual-vehicle-services-server');
execute(await readFile('resources/[mx]/mx-freeroam-vehicles/server.lua','utf8'),'actual-vehicle-fleet-server');
execute(await readFile('resources/[mx]/mx-freeroam-vehicles/garage.lua','utf8'),'actual-saved-creation-storage');
execute(await readFile('development/tests/vehicle-options.lua','utf8'),'vehicle-options-server-regressions');
execute(await readFile('development/tests/trainer-switch.lua','utf8'),'trainer-switch-regressions');
execute(await readFile('development/tests/drift-recovery-server.lua','utf8'),'drift-recovery-server-regressions');
execute(await readFile('development/tests/respawn-client-env.lua','utf8'),'respawn-client-adapters');
execute(await readFile('resources/[mx]/mx-freeroam-vehicles/respawn-client.lua','utf8'),'actual-respawn-client');
execute(await readFile('development/tests/respawn-client.lua','utf8'),'respawn-client-regressions');

{
 const source=await readFile('resources/[mx]/mx-freeroam-activities/server.lua','utf8');
 const start=source.indexOf('local function candidate('),end=source.indexOf('local function newSession(',start);
 if(start<0||end<0)throw Error('Activity candidate guard not found');
 execute("CompetitionDrift=true; exports['mx-freeroam-vehicles']={OwnedDriver=function()return {entity=99,drift=CompetitionDrift,handlingUncertain=CompetitionUncertain}end,Active=function()return {entity=99,drift=CompetitionDrift}end,IsEditing=function()return false end}; function GetEntityCoords()return {x=0,y=0,z=0}end; function GetEntitySpeed()return 0 end",'competition-adapters');
 execute('DriftCandidate=(function() local sessions={} '+source.slice(start,end)+' return candidate end)()', 'actual-activity-candidate');
 execute("local track={checkpoints={{x=0,y=0,z=0}},startRadius=10};assert(not pcall(DriftCandidate,1,track,'timeattack'));assert(not pcall(DriftCandidate,1,track,'duel'));assert(pcall(DriftCandidate,1,track,'practice'));assert(pcall(DriftCandidate,1,track,'drift'));CompetitionDrift=false;assert(pcall(DriftCandidate,1,track,'timeattack'));print('Actual activity candidate: drift preset blocks competition, preserves practice/training, and normal handling permits competition (adapters).')",'drift-competition-regressions');
}

{
 const xml=await readFile('development/fixtures/drift-owner.xml','utf8');
 execute("CompetitionUncertain=true;local track={checkpoints={{x=0,y=0,z=0}},startRadius=10};assert(not pcall(DriftCandidate,1,track,'timeattack'));assert(pcall(DriftCandidate,1,track,'practice'));CompetitionUncertain=false;assert(pcall(DriftCandidate,1,track,'timeattack'));print('Unconfirmed handling blocks competition only; practice and confirmed normal physics remain available (adapters).')",'uncertain-handling-competition');
 const base=xml.split('<SubHandlingData>')[0];let count=0;
 for(const match of xml.matchAll(/<(f\w+|n\w+) value="([\d.\-]+)"/g)){
  const [,field,raw]=match;const group=base.includes(match[0])?(field.startsWith('n')?'ints':'floats'):'car';
  execute('assert(VehicleDriftPreset.'+group+'['+JSON.stringify(field)+']=='+Number(raw)+',"XML mismatch: '+field+'")','xml-preset-attribute');count++;
 }
 for(const [,field,x,y,z] of base.matchAll(/<(vec\w+) x="([\d.\-]+)" y="([\d.\-]+)" z="([\d.\-]+)"/g)){
  execute('local p=VehicleDriftPreset.vectors['+JSON.stringify(field)+'];assert(p.x=='+Number(x)+' and p.y=='+Number(y)+' and p.z=='+Number(z)+')','xml-preset-vector');count++;
 }
 for(const [,field,value] of base.matchAll(/<(str\w+)>([0-9a-fA-F]+)<\//g)){
  execute('assert(VehicleDriftPreset.ints['+JSON.stringify(field)+']=='+parseInt(value,16)+')','xml-preset-hex');count++;
 }
 if(count!==51)throw Error('Expected all 51 runtime XML attributes, found '+count);
 const er34=await readFile('resources/[vehicles]/er34n/data/handling.meta','utf8');
 const subtype=er34.match(/<Item type="CCarHandlingData">([\s\S]*?)<\/Item>/)?.[1];
 if(!subtype||/<Item type=""/.test(er34))throw Error('ER34N missing concrete subhandling or still has empty subtype declarations');
 for(const [field,value] of [['fBackEndPopUpCarImpulseMult',.1],['fBackEndPopUpBuildingImpulseMult',.03],['fBackEndPopUpMaxDeltaSpeed',.6]]){
  const match=subtype.match(new RegExp('<'+field+' value="([^"]+)"'));
  if(!match||Number(match[1])!==value)throw Error('ER34N subtype mismatch: '+field);
 }
 console.log('Owner XML: all 51 runtime fields match the supplied source, including vector and hexadecimal conversions.');
}
