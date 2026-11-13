import '../scripts/workspace.mjs';
import {readFile,readdir,access,writeFile,mkdir} from 'node:fs/promises';
import {lua,lauxlib,to_luastring,to_jsstring} from 'fengari';
import assert from 'node:assert/strict';
const assets=['[standalone]','[audio]','[wheels]','[vehicles]','[maps]'];
const configuration=await readFile('config/server.cfg','utf8');
assert.match(configuration,/^ensure \[mx\]\s*$/m);
assert(!/^ensure mx-freeroam-/m.test(configuration));
assert(configuration.indexOf('ensure oxmysql')<configuration.indexOf('ensure [mx]'));
assert.match(configuration,/^exec config\/assets.cfg\s*$/m);
const assetConfig=await readFile('config/assets.cfg','utf8');
assert.deepEqual([...assetConfig.matchAll(/^ensure (.+?)\s*$/gm)].map(m=>m[1]),assets);
assert(!/^ensure \[(?:tests|mx-scripts)\]/m.test(configuration+'\n'+assetConfig));
const resources=new Map(),report=[],capabilities=[];
const L=lauxlib.luaL_newstate();
function dependencies(source){
 return [...source.matchAll(/\bdependency\s*(?:\(\s*)?['"]([^'"]+)['"]/g)].map(m=>m[1]).concat([...source.matchAll(/\bdependencies\s*\{([^}]+)\}/g)].flatMap(m=>[...m[1].matchAll(/['"]([^'"]+)['"]/g)].map(v=>v[1])));
}
for(const category of ['[vendor]','[mx]',...assets]){
 const names=[];
 for(const item of await readdir('resources/'+category,{withFileTypes:true})){
  if(!item.isDirectory())continue;
  assert(!resources.has(item.name),'Duplicate resource: '+item.name);
  const dir='resources/'+category+'/'+item.name;
  let manifest='fxmanifest.lua';try{await access(dir+'/'+manifest);}catch{manifest='__resource.lua';await access(dir+'/'+manifest);}
  const source=await readFile(dir+'/'+manifest,'utf8');
  assert.equal(lauxlib.luaL_loadbuffer(L,to_luastring(source),null,to_luastring(dir+'/'+manifest)),lua.LUA_OK,dir+': '+(lua.lua_isstring(L,-1)?to_jsstring(lua.lua_tostring(L,-1)):''));lua.lua_pop(L,1);
  resources.set(item.name,dependencies(source));names.push(item.name);
 }
 report.push({category,count:names.length,resources:names.sort()});
}
const visiting=new Set(),visited=new Set(),order=[];
function visit(name){
 if(visited.has(name))return;
 assert(!visiting.has(name),'Cyclic startup dependencies: '+name);visiting.add(name);
 for(const dependency of resources.get(name)){
  if(dependency.startsWith('/')){capabilities.push({resource:name,capability:dependency});continue;}
  assert(resources.has(dependency),'Missing dependency '+dependency+' for '+name);visit(dependency);
 }
 visiting.delete(name);visited.add(name);order.push(name);
}
for(const name of resources.keys())visit(name);
const menu=resources.get('mx-freeroam-menu');
for(const name of resources.keys())if(name.startsWith('mx-freeroam-')&&name!=='mx-freeroam-menu')assert(menu.includes(name),'Menu startup contract missing '+name);
const generatedDirectories={};
for(const directory of ['cache','db/default']){try{await access(directory);generatedDirectories[directory]=true;}catch{generatedDirectories[directory]=false;}}
await access('development/node_modules');
await mkdir('docs/evidence',{recursive:true});
await writeFile('docs/evidence/startup-layout.json',JSON.stringify({categories:report,dependencyOrder:order,capabilities,generatedDirectories,scope:'Filesystem and manifest verification only; live server was not restarted; no FiveM asset validation'},null,2));
console.log('Startup: categories, manifests and dependency graph verified; native cache/db preserved. Asset entitlements and streaming require FiveM.');
