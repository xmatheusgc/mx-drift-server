import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import './workspace.mjs';

const out='docs/evidence/experience-audit-2026-10-31';
fs.mkdirSync(out,{recursive:true});
const inventory=[],sites=[],bundles=[];
const extensions=new Set(['.lua','.js','.ts','.tsx','.html']);
const ignored=new Set(['node_modules','.git','cache']);
function files(dir){return fs.readdirSync(dir,{withFileTypes:true}).flatMap(x=>ignored.has(x.name)?[]:x.isDirectory()?files(path.join(dir,x.name)):[path.join(dir,x.name)]);}
const rules=[
 ['rejeicao',/MX\.(?:require|fail)\s*\(|\bthrow\s+|\berror\s*\(|\bassert\s*\(|DropPlayer\s*\(|deferrals\.done\s*\(/],
 ['falha-retorno',/return\s+(?:false|nil)\s*[,;}]|return\s*\{[^\n]*(?:ok\s*=\s*false|ready\s*=\s*false|reason\s*=)|notifyError\s*\(|setError\s*\(|logger\.(?:error|warn)\s*\(/],
 ['espera-recuperacao',/\b(?:timeout|Timeout|TIMEOUT|deadline|Deadline|expires|waitFor|AbortSignal|catch\s*\(|pcall\s*\()|while\s+(?:not\s+|true\b)/],
 ['entrada-estado',/DisableAllControlActions\s*\(|SetPlayerControl\s*\([^\n]*false|FreezeEntityPosition\s*\([^\n]*true|SetNuiFocus\s*\(|\bdisabled\s*=|\.available\[[^\]]+\]\s*=\s*false|if[^\n]+then\s+return\s+end/]
];
function scan(file,module,configured){
 const bytes=fs.readFileSync(file),source=bytes.toString('utf8'),lines=source.split(/\r?\n/);
 const bundled=file.replaceAll('\\','/').includes('/dist/')||file.replaceAll('\\','/').includes('/web/build/')||(path.extname(file)==='.js'&&lines.some(l=>l.length>2500));
 const info={file:file.replaceAll('\\','/'),module,configured,bytes:bytes.length,lines:lines.length,sha256:crypto.createHash('sha256').update(bytes).digest('hex'),bundled};
 inventory.push(info);
 if(bundled){bundles.push(info);return;}
 for(let n=0;n<lines.length;n++){
  const line=lines[n],trim=line.trim();
  if(!trim||/^(--|\/\/|\/\*|\*|<!--)/.test(trim))continue;
  const kinds=rules.filter(([,rx])=>rx.test(line)).map(([k])=>k);
  if(kinds.length)sites.push({module,configured,file:info.file,line:n+1,kinds,excerpt:line.trim().slice(0,1000)});
 }
}
const resources=[];
const manifestIssues=[];
for(const category of fs.readdirSync('resources',{withFileTypes:true}).filter(x=>x.isDirectory())){
 for(const dir of fs.readdirSync(path.join('resources',category.name),{withFileTypes:true}).filter(x=>x.isDirectory())){
  const root=path.join('resources',category.name,dir.name),all=files(root);
  const manifest=all.find(p=>path.dirname(p)===root&&['fxmanifest.lua','__resource.lua'].includes(path.basename(p)));
  if(!manifest)continue;
  const configured=category.name==='[mx-scripts]'?['mx-gearbox','mx-soundcore'].includes(dir.name):category.name!=='[tests]';
  const module=category.name+'/'+dir.name;
  resources.push({module,configured,manifest:manifest.replaceAll('\\','/'),files:all.length});
  const manifestSource=fs.readFileSync(manifest,'utf8').replace(/--\[\[[\s\S]*?\]\]|--[^\r\n]*/g,'');
  for(const match of manifestSource.matchAll(/['"]([^'"\r\n]+\.(?:lua|js|css|html|meta|xml|ymap|ytyp|dat|ogg|json|ytd|yft|rel))['"]/g)){
   const declared=match[1].replaceAll('\\','/');
   if(declared.startsWith('@')||declared.includes('://'))continue;
   const rx=new RegExp('^'+declared.split(/(\*\*\/|\*\*|\*|\?)/).map(x=>x==='**/'?'(?:.*/)?':x==='**'?'.*':x==='*'?'[^/]*':x==='?'?'.':x.replace(/[.+^${}()|[\]\\]/g,'\\$&')).join('')+'$','i');
   const relFiles=all.map(f=>path.relative(root,f).replaceAll('\\','/'));
   const audioRel=/\.dat$/i.test(declared)&&relFiles.some(f=>f.toLowerCase().startsWith(declared.toLowerCase())&&/^\d+\.rel$/i.test(f.slice(declared.length)));
   if(!audioRel&&!relFiles.some(f=>rx.test(f)))manifestIssues.push({module,configured,file:manifest.replaceAll('\\','/'),declared});
  }
  for(const file of all)if(extensions.has(path.extname(file).toLowerCase()))scan(file,module,configured);
 }
}
for(const file of files('development/ui/src'))if(extensions.has(path.extname(file)))scan(file,'NUI React (mx-freeroam-menu)',true);

const logPath=path.resolve('../default/logs/fxserver.log');
const logEvents=[];const logGroups=new Map();
if(fs.existsSync(logPath))for(const [i,line]of fs.readFileSync(logPath,'utf8').split(/\r?\n/).entries()){
 let category;
 if(/SCRIPT ERROR|"level":"error"|"code":"INTERNAL"/.test(line))category='script';
 else if(/could not find|couldn't find|missing.*(?:file|manifest)|does not have a resource manifest/i.test(line))category='arquivo/manifest';
 else if(/Asset .* uses .*MiB/.test(line))category='memoria-asset';
 else if(/failed to reach the server/i.test(line))category='conectividade';
 else if(/hitch warning/i.test(line))category='hitch';
 else if(/Warning:|warning:|Failed|error:|Error:|not found/i.test(line))category='aviso/outro';
 if(!category)continue;
 const safe=line.replace(/\b(?:\d{1,3}\.){3}\d{1,3}(?::\d+)?\b/g,'[endereco omitido]').replace(/license:[a-zA-Z0-9]+/g,'license:[omitida]').replace(/mysql:\/\/[^\s]+/gi,'mysql://[omitido]');
 logEvents.push({line:i+1,category,excerpt:safe.slice(0,1400)});
 const normalized=safe.replace(/table: [a-f0-9]+/g,'table: [handle]').replace(/timer interval of \d+ milliseconds/,'timer interval of [ms] milliseconds');
 const key=category+'|'+normalized;
 const group=logGroups.get(key)||{category,firstLine:i+1,lastLine:i+1,count:0,excerpt:normalized};group.count++;group.lastLine=i+1;logGroups.set(key,group);
}
const data={date:'2026-10-31',scope:'base CFX ativa; configurado nao significa verificado em execucao',resources,inventory,sites,bundles,manifestIssues,log:{path:'txData/default/logs/fxserver.log',events:logEvents,groups:[...logGroups.values()]}};
fs.writeFileSync(out+'/inventory.json',JSON.stringify(data,null,2)+'\n');
const md=['# Inventário de locais de falha, espera e bloqueio — 2026-10-31','',
 'Anexo técnico do relatório geral. Extração estática por padrões, sem execução do servidor. Uma ocorrência não equivale a um bug: inclui validações legítimas, cancelamentos, recuperação e travas de entrada. Os grupos do relatório principal explicam os efeitos. Comentários isolados foram excluídos; bundles compilados estão no inventário, sem atribuição de lógica de terceiros ao código-fonte autoral.','',
 `Recursos com manifest: **${resources.length}**; configurados para início: **${resources.filter(r=>r.configured).length}**; fontes inventariadas: **${inventory.length}**; arquivos compilados/minificados: **${bundles.length}**; locais detectados: **${sites.length}**.`,
 '', '## Recursos e cobertura','', '| Módulo | Configurado | Arquivos no recurso | Locais encontrados |','|---|---|---:|---:|',
 ...resources.map(r=>`| ${r.module} | ${r.configured?'Sim':'Não (instalado)'} | ${r.files} | ${sites.filter(s=>s.module===r.module).length} |`),''];
for(const module of [...new Set(sites.map(s=>s.module))]){
 md.push('## '+module,'');
 for(const file of [...new Set(sites.filter(s=>s.module===module).map(s=>s.file))]){
  md.push('### `'+file+'`','','```text');
  for(const s of sites.filter(s=>s.file===file))md.push(`${s.line} [${s.kinds.join(', ')}] ${s.excerpt.replaceAll('```','~~~')}`);
  md.push('```','');
 }
}
md.push('## Referências de manifest sem arquivo correspondente','','Verificação textual de caminhos/globs. Um wildcard vazio é uma ocorrência de empacotamento, não prova de falha fatal. Referências externas @resource são excluídas desta conferência. Nomes lógicos de áudio .dat com arquivo .datNN.rel correspondente também são excluídos.','','| Módulo | Referência | Manifest |','|---|---|---|',...manifestIssues.map(x=>`| ${x.module} | \`${x.declared}\` | \`${x.file}\` |`),'');
md.push('## Log histórico consultado','','Os grupos abaixo agregam repetições do arquivo local. Não provam persistência no processo atual. Endereços/identidades foram omitidos.','','| Categoria | Primeira linha | Última linha | Ocorrências | Registro |','|---|---:|---:|---:|---|',
 ...[...logGroups.values()].map(g=>`| ${g.category} | ${g.firstLine} | ${g.lastLine} | ${g.count} | ${g.excerpt.replaceAll('|','¦').replaceAll('`',"'")} |`),'');
fs.writeFileSync('docs/experience-error-sites-2026-10-31.md',md.join('\n'));
console.log(JSON.stringify({resources:resources.length,configured:resources.filter(r=>r.configured).length,sources:inventory.length,bundles:bundles.length,sites:sites.length,manifestIssues,logEvents:logEvents.length,logGroups:logGroups.size,byModule:Object.fromEntries([...new Set(sites.map(s=>s.module))].map(m=>[m,sites.filter(s=>s.module===m).length]))},null,2));
