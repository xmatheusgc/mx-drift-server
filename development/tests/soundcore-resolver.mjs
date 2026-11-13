import '../scripts/workspace.mjs';
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import vm from 'node:vm';
import path from 'node:path';
const source=await readFile('resources/[mx-scripts]/mx-soundcore/server/stream_resolver.js','utf8');
let spawnImpl,spawnCalls=[];
const api={};
vm.runInNewContext(source,{
 require(name){
  if(name==='child_process')return {execFile(...args){spawnCalls.push(args);return spawnImpl(...args);}};
  if(name==='fs')return {existsSync:()=>true};
  if(name==='path')return path;
  if(name==='url'||name==='https')return {};
  throw Error('Unexpected module: '+name);
 },
 GetResourcePath:()=>'/fixture/mx-soundcore',GetCurrentResourceName:()=>'mx-soundcore',
 exports:(name,fn)=>api[name]=fn,URL
},{filename:'stream_resolver.js'});
const cases=[['GetYtdlpVersion',[]],['UpdateYtdlp',[]],['ResolveStream',['https://example.com/watch']],['SearchOnly',['song',5]],['SearchAndResolve',['song',1200,true]]];
for(const [name,args] of cases){
 let callbacks=0;
 spawnImpl=()=>{throw Object.assign(Error('Access to this API has been restricted'),{code:'ERR_ACCESS_DENIED',permission:'ChildProcess'});};
 assert.doesNotThrow(()=>api[name](...args,(value,error)=>{callbacks++;assert.equal(value,null);assert.match(error,/add_unsafe_child_process_permission "mx-soundcore"/);}));
 assert.equal(callbacks,1,name+' resolves its callback once on synchronous permission denial');
}
spawnImpl=(_file,_args,_options,cb)=>cb(null,'2026.fixture\n','');
api.GetYtdlpVersion((value,error)=>{assert.equal(value,'2026.fixture');assert.equal(error,null);});
assert.equal(spawnCalls.at(-1)[2].windowsHide,true);
assert.equal(spawnCalls.at(-1)[2].timeout,15000);
spawnImpl=(_file,_args,_options,cb)=>cb(Error('spawn ENOENT'),'','');
api.GetYtdlpVersion((value,error)=>{assert.equal(value,null);assert.match(error,/ENOENT/);});
spawnImpl=()=>{throw Error('Other spawn error');};
api.ResolveStream('https://example.com/watch',(value,error)=>{assert.equal(value,null);assert.equal(error,'Other spawn error');});
let stage=0,completed=0;
spawnImpl=(_file,_args,_options,cb)=>{
 if(stage++===0)cb(null,JSON.stringify({id:'abcdefghijk',title:'Fixture',webpage_url:'https://www.youtube.com/watch?v=abcdefghijk',duration:120}),'');
 else throw Object.assign(Error('Denied'),{code:'ERR_ACCESS_DENIED'});
};
api.SearchAndResolve('song',1200,true,(value,error)=>{completed++;assert.equal(value,null);assert.match(error,/add_unsafe_child_process_permission/);});
assert.equal(stage,2);assert.equal(completed,1,'second-stage denial also resolves search callback');
spawnImpl=(_file,_args,_options,cb)=>cb(null,'https://example.com/fixture.m4a\n','');
api.ResolveStream('https://example.com/watch',(value,error)=>{assert.equal(value,'https://example.com/fixture.m4a');assert.equal(error,null);});
console.log('Soundcore resolver: denied child processes handled across all exports and nested resolution, success, ENOENT, timeout and hidden-window options passed (no subprocess executed).');
