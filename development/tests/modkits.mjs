import '../scripts/workspace.mjs';
import {readdir,readFile,access} from 'node:fs/promises';
import path from 'node:path';
import assert from 'node:assert/strict';
async function walk(dir){let files=[];for(const e of await readdir(dir,{withFileTypes:true})){const f=path.join(dir,e.name);if(e.isDirectory())files.push(...await walk(f));else if(e.isFile()&&e.name.endsWith('.meta'))files.push(f);}return files;}
const kits=[];
for(const file of await walk('resources')){
 const xml=await readFile(file,'utf8');
 for(const match of xml.matchAll(/<kitName>\s*([^<]+?)\s*<\/kitName>\s*<id\b[^>]*\bvalue\s*=\s*["'](\d+)["']/g))kits.push({name:match[1],id:Number(match[2]),file});
}
const ids=new Map(),names=new Map();
for(const kit of kits){
 assert(kit.id>=0&&kit.id<=65535,`Modkit outside Cfx range: ${JSON.stringify(kit)}`);
 if(kit.id===0)continue;
 assert(!ids.has(kit.id),`Duplicate modkit ID ${kit.id}: ${ids.get(kit.id)?.file} / ${kit.file}`);
 assert(!names.has(kit.name),`Duplicate modkit name ${kit.name}`);
 ids.set(kit.id,kit);names.set(kit.name,kit);
}
const jzx=names.get('6190_jzx100_modkit'),chaser=names.get('3190_chaser_modkit');
assert(jzx&&chaser&&jzx.id!==chaser.id,'JZX100 and chaser require independent modkits');
const variations=await readFile('resources/[vehicles]/jzx100/data/common/data/carvariations.meta','utf8');
assert.match(variations,/<kits>\s*<Item>6190_jzx100_modkit<\/Item>\s*<\/kits>/);
const xml=await readFile(jzx.file,'utf8');
// Split on modelName instead: nested turnOffBones Items are not mod boundaries.
const models=xml.split('<modelName>').slice(1).map(block=>({name:block.split('</modelName>')[0],type:block.match(/<type>([^<]+)<\/type>/)?.[1]}));
const exhaustModels=models.filter(m=>m.type==='VMT_EXHAUST');
assert.equal(exhaustModels.length,4,'JZX100 really declares four exhaust alternatives, not zero');
for(const mod of models)await access(path.join('resources/[vehicles]/jzx100/stream',mod.name+'.yft'));
console.log(`Installed assets: ${kits.length} modkits checked, no duplicate nonzero IDs/names; JZX100 6190 vs chaser 3190, variation link and ${models.length} visual assets including 4 exhausts verified. No FiveM runtime validation.`);
