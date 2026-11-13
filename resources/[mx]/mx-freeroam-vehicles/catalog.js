// Runtime consumes Cfx manifest metadata, without parsing or evaluating manifest Lua.
const fs=require('fs'),path=require('path');
const {Buffer}=require('node:buffer');
// Presentation overrides are scoped to resource + model; spawn identities stay in metadata.
// These packs are under evaluation and must remain visibly separate from production Nissan cars.
const testPacks={
 'n180sx-n180sxse':{n180sx:'180SX',n180sxse:'180SX SE'},
 'nsilvias14k-nsilvias14z':{nsilvias14k:'Silvia S14 Kouki',nsilvias14z:'Silvia S14 Zenki'},
 'nskygttr34-nskygtrr34':{nskygttr34:'Skyline R34 GT-T',nskygtrr34:'Skyline R34 GT-R'}
};
// Search tags follow MX.text's byte limit; asset/model identities are never shortened.
function searchTags(...values){const tags=[...new Set(values)].filter(v=>typeof v==='string'&&Buffer.byteLength(v,'utf8')>=1&&Buffer.byteLength(v,'utf8')<=24&&!/[\x00-\x1f\x7f<>]/.test(v));return tags.length?tags:['addon'];}
function walk(root,reader=fs){return reader.readdirSync(root,{withFileTypes:true}).sort((a,b)=>a.name.localeCompare(b.name)).flatMap(e=>e.isSymbolicLink()?[]:e.isDirectory()?walk(path.join(root,e.name),reader):[path.join(root,e.name)]);}
function inside(root,dir){const rel=path.relative(root,dir);return rel!==''&&rel!=='..'&&!rel.startsWith('..'+path.sep)&&!path.isAbsolute(rel);}
function glob(pattern){return new RegExp('^'+pattern.split(/(\*\*\/|\*\*|\*)/).map(x=>x==='**/'?'(?:.*/)?':x==='**'?'.*':x==='*'?'[^/]*':x.replace(/[.+?^${}()|[\]\\]/g,'\\$&')).join('')+'$','i');}
function collect(xml,resource,result){
 for(const m of xml.matchAll(/<modelName>\s*([^<]+)\s*<\/modelName>([\s\S]*?)(?=<modelName>|$)/gi)){
  const model=m[1].trim().toLowerCase();if(!/^[a-z0-9_]{1,64}$/.test(model)){result.diagnostics.push(resource+': invalid model');continue;}
  const tag=n=>m[2].match(new RegExp('<'+n+'>\\s*([^<]*)\\s*</'+n+'>','i'))?.[1].trim()??'';
  const label=testPacks[resource]?.[model];
  const make=tag('vehicleMakeName'),brand=label?'NISSAN (TESTES)':make&&!/^(null|none|carnotfound)$/i.test(make)?make.replace(/\s+/g,' ').toUpperCase():'Sem marca';
  const prior=result.rows.find(r=>r.id===model);
  if(prior){prior.conflict=true;result.diagnostics.push('Conflicting model '+model+': '+prior.asset+' / '+resource);continue;}
  result.rows.push({id:model,model,name:label||tag('gameName')||model,brand,category:brand,asset:resource,source:'vehicles',tags:searchTags(brand,resource),revision:1});
 }
}
function discoverNative(root,api){
 const result={rows:[],diagnostics:[],resources:0,metadata:0};
 for(let n=0;n<api.count();n++){
  const resource=api.name(n),location=resource&&api.location(resource);if(!location||!inside(root,path.resolve(location)))continue;
  result.resources++;const visited=new Set();
  try{
   for(let i=0;i<api.metadataCount(resource,'data_file');i++){
    if(api.metadata(resource,'data_file',i)!=='VEHICLE_METADATA_FILE')continue;
    // Cfx pairs the data-file type with a JSON string path in data_file_extra.
    const pattern=JSON.parse(api.metadata(resource,'data_file_extra',i));
    if(typeof pattern!=='string')throw Error('invalid data_file_extra');
    const normalized=pattern.replaceAll('\\','/');
    if(normalized.startsWith('/')||normalized.startsWith('@')||/^[a-z]:/i.test(normalized)||normalized.split('/').includes('..'))throw Error('metadata path leaves resource');
    const files=normalized.includes('*')?api.files(resource,location).filter(f=>glob(normalized).test(f)):[normalized];
    if(!files.length)result.diagnostics.push(resource+': metadata glob matched no files: '+normalized);
    for(const file of files){
     if(visited.has(file))continue;visited.add(file);
     const xml=api.load(resource,file);
     if(!xml){result.diagnostics.push(resource+': metadata unavailable: '+file);continue;}
     result.metadata++;collect(xml,resource,result);
    }
   }
  }catch(error){result.diagnostics.push(resource+': '+error.message);}
 }
 if(!result.rows.length)result.diagnostics.push('Showroom empty: '+result.resources+' authorized resources, '+result.metadata+' readable vehicle metadata files');
 return result;
}
// Direct filesystem discovery is only for offline tooling and fixtures.
function discover(root,registered,reader=fs){
 const result={rows:[],diagnostics:[]};let files=[];
 if(registered){for(const r of registered.filter(r=>r.path&&inside(root,r.path)))try{files.push(...walk(r.path,reader));}catch(e){result.diagnostics.push(r.name+': cannot read registered resource: '+e.message);}}
 else{if(!reader.existsSync(root))return {rows:[],diagnostics:['Authorized vehicle folder is missing: '+root]};files=walk(root,reader);}
 const manifests=files.filter(f=>/[/\\](fxmanifest|__resource)\.lua$/i.test(f)&&(!registered||registered.some(r=>path.resolve(r.path)===path.dirname(path.resolve(f)))));
 for(const manifest of manifests){
  const dir=path.dirname(manifest),resource=registered?.find(r=>path.resolve(r.path)===dir)?.name??path.basename(dir);
  try{
   const text=reader.readFileSync(manifest,'utf8').replace(/--\[\[[\s\S]*?\]\]|--[^\r\n]*/g,'');
   const patterns=[...text.matchAll(/data_file\s*(?:\(\s*)?['"]VEHICLE_METADATA_FILE['"]\s*,?\s*['"]([^'"]+)['"]/gi)].map(m=>m[1].replaceAll('\\','/'));
   const metas=files.filter(f=>f.startsWith(dir+path.sep)&&patterns.some(p=>glob(p).test(path.relative(dir,f).replaceAll('\\','/'))));
   if(!metas.length)result.diagnostics.push(resource+': no declared vehicle metadata found');
   for(const file of metas)collect(reader.readFileSync(file,'utf8'),resource,result);
  }catch(e){result.diagnostics.push(resource+': '+e.message);}
 }
 return result;
}
if(typeof GetCurrentResourceName==='function'){
 const current=GetCurrentResourceName();let timer;
 function reload(){try{
  const allowed=path.resolve(GetResourcePath(current),'../..'),root=path.resolve(allowed,GetConvar('mx_vehicleCatalogFolder','[vehicles]'));
  if(!inside(allowed,root))throw Error('Vehicle category must stay inside resources');
  const result=discoverNative(root,{count:GetNumResources,name:GetResourceByFindIndex,location:GetResourcePath,metadataCount:GetNumResourceMetadata,metadata:GetResourceMetadata,load:LoadResourceFile,files:(_,location)=>walk(location).map(f=>path.relative(location,f).replaceAll('\\','/'))});
  emit('mx:vehicles:catalogIndex',JSON.stringify(result));
  console.log('[MX catalog] '+result.resources+' authorized resources / '+result.metadata+' metadata files / '+result.rows.length+' models');
  for(const message of result.diagnostics)console.warn('[MX catalog] '+message);
 }catch(e){console.error('[MX catalog] Reload failed; previous index retained: '+e.message);}}
 const schedule=()=>{clearTimeout(timer);timer=setTimeout(reload,500);};
 on('onResourceStart',schedule);on('onResourceStop',schedule);
 RegisterCommand('mx_catalog_reload',source=>{if(source===0||IsPlayerAceAllowed(String(source),'mx.admin'))reload();},false);
 setTimeout(reload,0);
}else module.exports={discover,discoverNative};
