import '../scripts/workspace.mjs';
import {createRequire} from 'node:module';
import {mkdir,writeFile,mkdtemp} from 'node:fs/promises';
import path from 'node:path';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import vm from 'node:vm';
const require=createRequire(import.meta.url),{discover}=require('../../resources/[mx]/mx-freeroam-vehicles/catalog.js');
await mkdir('development/runtime',{recursive:true});
const root=await mkdtemp(path.resolve('development/runtime/catalog-fixture-'));
async function file(name,text){const p=path.join(root,name);assert(p.startsWith(root+path.sep));await mkdir(path.dirname(p),{recursive:true});await writeFile(p,text);}
await file('nested/pack/fxmanifest.lua',"data_file 'VEHICLE_METADATA_FILE' 'data/*.meta'\n-- data_file 'VEHICLE_METADATA_FILE' 'ignored.meta'");
await file('nested/pack/data/cars.meta','<InitDatas><Item><modelName>addon1</modelName><vehicleMakeName>Nissan</vehicleMakeName><gameName>Model One</gameName></Item><Item><modelName>futo</modelName><vehicleMakeName /></Item></InitDatas>');
await file('nested/pack/ignored.meta','<modelName>outside</modelName>');
let r=discover(root);assert.deepEqual(r.rows.map(x=>x.id),['addon1','futo']);assert.equal(r.rows[0].brand,'NISSAN');assert.equal(r.rows[1].brand,'Sem marca');
assert(r.rows.every(x=>x.source==='vehicles'));assert.equal(r.rows[0].asset,'pack');
const testModels={
 'n180sx-n180sxse':{n180sx:'180SX',n180sxse:'180SX SE'},
 'nsilvias14k-nsilvias14z':{nsilvias14k:'Silvia S14 Kouki',nsilvias14z:'Silvia S14 Zenki'},
 'nskygttr34-nskygtrr34':{nskygttr34:'Skyline R34 GT-T',nskygtrr34:'Skyline R34 GT-R'}
};
for(const [resource,models] of Object.entries(testModels)){
 await file(resource+'/fxmanifest.lua',"data_file 'VEHICLE_METADATA_FILE' 'vehicles.meta'");
 await file(resource+'/vehicles.meta','<InitDatas>'+Object.keys(models).map(model=>'<Item><modelName>'+model+'</modelName><gameName>'+model+'</gameName><vehicleMakeName>TEST</vehicleMakeName></Item>').join('')+'</InitDatas>');
 const rows=discover(root).rows.filter(row=>row.asset===resource);
 assert.equal(rows.length,2,'each pack exposes both models');
 for(const row of rows){assert.equal(row.id,row.model);assert.equal(row.name,models[row.model]);assert.equal(row.brand,'NISSAN (TESTES)');assert.equal(row.category,row.brand);}
}
await file('ordinary/fxmanifest.lua',"data_file 'VEHICLE_METADATA_FILE' 'vehicles.meta'");
await file('ordinary/vehicles.meta','<modelName>n180sx</modelName><gameName>Ordinary</gameName><vehicleMakeName>OTHER</vehicleMakeName>');
const ordinary=discover(root,[{name:'ordinary',path:path.join(root,'ordinary')}]).rows[0];
assert.equal(ordinary.brand,'OTHER','test labels must not leak to other resources');assert.equal(ordinary.name,'Ordinary');
await file('other/fxmanifest.lua',"data_file 'VEHICLE_METADATA_FILE' 'vehicles.meta'");
await file('other/vehicles.meta','<modelName>addon1</modelName><vehicleMakeName>OTHER</vehicleMakeName>');
r=discover(root);assert.equal(r.rows.length,8);assert.equal(r.rows.find(x=>x.id==='addon1').conflict,true);assert.match(r.diagnostics.join(' '),/Conflicting model addon1/);
const actual=discover(path.resolve('resources/[vehicles]'));
assert(actual.rows.length>=12);assert(!actual.rows.some(x=>x.id==='elegy'));assert(actual.rows.some(x=>x.asset&&x.source==='vehicles'),'installed catalogue includes declared addon metadata');
for(const row of actual.rows)for(const tag of row.tags)assert(Buffer.byteLength(tag,'utf8')>=1&&Buffer.byteLength(tag,'utf8')<=24&&!/[\x00-\x1f\x7f<>]/.test(tag),'invalid installed asset tag: '+row.id);
// Keep this regression independent of which packs the owner currently installs.
await file('long-name/fxmanifest.lua',"data_file 'VEHICLE_METADATA_FILE' 'vehicles.meta'");
await file('long-name/vehicles.meta','<modelName>s15naoki</modelName><vehicleMakeName>Silvia S15 Naoki Nakamura</vehicleMakeName>');
const naoki=discover(root).rows.find(x=>x.id==='s15naoki');assert(naoki);assert.equal(naoki.brand,'SILVIA S15 NAOKI NAKAMURA');assert(!naoki.tags.includes(naoki.brand),'25-byte metadata must not become an invalid search tag');
const longResource='resource_with_more_than_24_bytes',tagRoot=path.resolve('development/runtime/catalog-tag-fixture');
await mkdir(path.join(tagRoot,longResource),{recursive:true});
await writeFile(path.join(tagRoot,longResource,'fxmanifest.lua'),"data_file 'VEHICLE_METADATA_FILE' 'vehicles.meta'");
await writeFile(path.join(tagRoot,longResource,'vehicles.meta'),'<modelName>longtags</modelName><gameName>Long Tags</gameName><vehicleMakeName>'+('é'.repeat(13))+'</vehicleMakeName>');
const longTags=discover(tagRoot).rows[0];assert.equal(longTags.asset,longResource);assert.equal(longTags.brand,'É'.repeat(13));assert.deepEqual(longTags.tags,['addon'],'UTF-8 tags are bounded by bytes; identities stay intact');
console.log('Catalog discovery: nested pack, multiple models, declared metadata only, vanilla replacement by origin, missing brand, conflicts and actual assets passed.');

// Execute the actual FXServer branch, with a sandbox that denies the category root.
const pack=path.join(root,'nested/pack'),currentPath=path.join(root,'[mx]/mx-freeroam-vehicles');
const registered=[{name:'mx-freeroam-vehicles',path:currentPath},{name:'pack',path:pack},{name:'other',path:path.join(root,'other')}];
const reads=[],emitted=[],timers=[],warnings=[],errors=[];let failPack=false;
function guard(p){const resolved=path.resolve(p);reads.push(resolved);assert(resolved===pack||resolved.startsWith(pack+path.sep),'runtime attempted category/unrelated filesystem access: '+resolved);if(failPack)throw Error('simulated unreadable resource');}
const restricted={existsSync(){throw Error('runtime must not stat category directories');},readdirSync(p,options){guard(p);return fs.readdirSync(p,options);},readFileSync(p,encoding){guard(p);return fs.readFileSync(p,encoding);}};
let pattern='data/cars.meta';
const sandbox={require:name=>name==='fs'?restricted:require(name),GetCurrentResourceName:()=>registered[0].name,GetResourcePath:name=>registered.find(r=>r.name===name)?.path,GetConvar:()=> 'nested',GetNumResources:()=>registered.length,GetResourceByFindIndex:i=>registered[i]?.name,GetNumResourceMetadata:()=>1,GetResourceMetadata:(_,key)=>key==='data_file'?'VEHICLE_METADATA_FILE':JSON.stringify(pattern),LoadResourceFile:(resource,file)=>{assert.equal(resource,'pack');if(failPack)return null;return fs.readFileSync(path.join(pack,file),'utf8');},emit:(event,json)=>emitted.push({event,data:JSON.parse(json)}),on(){},RegisterCommand(){},setTimeout:fn=>{timers.push(fn);return timers.length;},clearTimeout(){},console:{log(){},warn:m=>warnings.push(m),error:m=>errors.push(m)}};
vm.runInNewContext(fs.readFileSync('resources/[mx]/mx-freeroam-vehicles/catalog.js','utf8'),sandbox);
assert.equal(timers.length,1);timers[0]();
assert.deepEqual(emitted[0].data.rows.map(r=>r.id),['addon1','futo']);assert.equal(errors.length,0);assert.equal(reads.length,0,'literal metadata uses only resource-native reads');
pattern='data/*.meta';timers[0]();assert(reads.length>0);assert.equal(emitted[1].data.rows.length,2);
failPack=true;assert.doesNotThrow(()=>timers[0]());assert(warnings.some(m=>m.includes('simulated unreadable resource')));assert.equal(errors.length,0,'localized read error must not escape timer');
pattern='../escape.meta';failPack=false;timers[0]();assert(warnings.some(m=>m.includes('leaves resource')));
console.log('Catalog runtime branch: effective metadata, native reads, mounted-resource globs, forbidden category access, path traversal and localized failures passed (sandbox adapter, not FXServer).');
