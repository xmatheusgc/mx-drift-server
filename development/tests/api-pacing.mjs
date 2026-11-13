import '../scripts/workspace.mjs';
import {readFile} from 'node:fs/promises';
import assert from 'node:assert/strict';
import ts from 'typescript';
const js=ts.transpileModule(await readFile('development/ui/src/api.ts','utf8'),{compilerOptions:{target:ts.ScriptTarget.ES2022,module:ts.ModuleKind.ES2022}}).outputText;
const {api}=await import('data:text/javascript;base64,'+Buffer.from(js).toString('base64'));
const oldWindow=globalThis.window,oldFetch=globalThis.fetch,started=[],finished=[];let active=0;
globalThis.window={GetParentResourceName:()=> 'mx-freeroam-menu'};
globalThis.fetch=async()=>{assert.equal(active++,0,'only one cosmetic request in flight');started.push(performance.now());await new Promise(resolve=>setTimeout(resolve,35));return {json:async()=>{active--;finished.push(performance.now());return {ok:true,data:{applied:true}};}};};
try{
 await Promise.all([api('experience','cosmetic',{}),api('experience','cosmetic',{}),api('experience','cosmetic',{})]);
 for(let i=1;i<started.length;i++)assert(started[i]-finished[i-1]>=490,'minimum gap follows response completion, including transport latency');
 console.log('NUI cosmetic pacing: serial requests, >=500 ms response-to-next-request contract (timer tolerance 10 ms); mocked transport.');
 started.length=0;finished.length=0;
 await Promise.all([api('vehicles','catalog',{brand:'A'}),api('vehicles','catalog',{brand:'B'}),api('vehicles','catalog',{brand:'C'})]);
 for(let i=1;i<started.length;i++)assert(started[i]-started[i-1]>=150,'catalog changes respect server per-action guard even when queued');
 console.log('Catalog pacing: rapid queued brand changes preserve the server 150ms action interval; mocked transport.');
}finally{globalThis.window=oldWindow;globalThis.fetch=oldFetch;}
