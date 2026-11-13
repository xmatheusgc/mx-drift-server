import '../scripts/workspace.mjs';
import {readFile,readdir,access} from 'node:fs/promises';
import assert from 'node:assert/strict';
const domains=['core','world','vehicles','social','activities','progression','admin','menu','experience','drivecam'];
for(const domain of domains){
  const dir=`resources/[mx]/mx-freeroam-${domain}/`,manifest=await readFile(dir+'fxmanifest.lua','utf8');
  assert.match(manifest,/fx_version 'cerulean'/);assert.match(manifest,/game 'gta5'/);
  if(domain!=='core')assert.match(manifest,/'mx-freeroam-core'/);
  for(const file of await readdir(dir))if(file.endsWith('.lua')){
    const src=await readFile(dir+file,'utf8');
    // Owner explicitly authorized the supplied drift preset on 2026-10-18.
    // Keep all other physics changes and model-global handling setters forbidden.
    assert(!/SetVehicleEnginePowerMultiplier|\bSetHandling(?:Float|Int|Vector)/.test(src),'Física global ou multiplicadores fora do escopo');
    assert(!/SetVehicleHandling/.test(src)||(domain==='vehicles'&&file==='drift-client.lua'),'Handling fora do módulo de preset autorizado');
    if(/ModifyVehicleTopSpeed/.test(src)){
      assert(domain==='vehicles'&&file==='drift-client.lua','Refresh de transmissão fora do preset autorizado');
      assert.equal((src.match(/ModifyVehicleTopSpeed\s*\(/g)||[]).length,1);
      assert.match(src,/ModifyVehicleTopSpeed\(v,0\.0\)/,'Refresh deve usar zero por cento, sem aumento de potência');
    }
    if(domain==='core')assert(!/garage_presets|activity_results|xp_ledger|drift|track_versions|mx-freeroam-progression/.test(src),'Core invadiu domínio');
    assert(!/RegisterNetEvent\(['"]mx:activities:result/.test(src),'Integração interna exposta à rede');
  }
}
await access('resources/[mx]/mx-freeroam-menu/dist/index.html');
// FiveM routes SendNUIMessage to the calling resource, not to another UI.
const experienceClient=await readFile('resources/[mx]/mx-freeroam-experience/client.lua','utf8');
const menuClient=await readFile('resources/[mx]/mx-freeroam-menu/client.lua','utf8');
assert(!/SendNUIMessage\(\{type='loadingClosed'/.test(experienceClient),'Loading reveal must originate in the resource owning ui_page');
assert(!/SendNUIMessage\(\{type='workshopCamera'/.test(experienceClient),'Camera UI state must originate in the resource owning ui_page');
assert.match(menuClient,/AddEventHandler\('mx:experience:freeCamera',[^\n]+SendNUIMessage\(\{type='workshopCamera'/);
assert.match(menuClient,/callback\('lobbyReady',[\s\S]*?exports\['mx-freeroam-experience'\]:LobbyReady\(d.generation\)[\s\S]*?SendNUIMessage\(\{type='loadingClosed'\}\)/);
const deps=JSON.parse(await readFile('development/package.json','utf8'));
await import('./startup.mjs');
for(const v of Object.values({...deps.dependencies,...deps.devDependencies}))assert(/^[0-9]+\.[0-9]+\.[0-9]+$/.test(v),'Versão não fixada');
console.log('Limites de módulo, manifests, build local, versões e restrições de física e preset autorizado aprovados.');
