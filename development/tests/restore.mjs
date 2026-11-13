import '../scripts/workspace.mjs';
import mysql from 'mysql2/promise';
import {spawn} from 'node:child_process';
import {mkdir,writeFile} from 'node:fs/promises';
import assert from 'node:assert/strict';
const url=process.env.MX_TEST_DATABASE_URL;
if(!url||!/^\/mx_freeroam_test(?:_[a-z0-9]+)?$/.test(new URL(url).pathname))throw Error('Banco de teste isolado obrigatório');
await mkdir('development/runtime',{recursive:true});await mkdir('docs/evidence',{recursive:true});
const suffix=Date.now(),target='mx_freeroam_test_r'+suffix,file=`development/runtime/restore-${suffix}.local.sql`;
const a=await mysql.createConnection(url);
let b;
const invoke=(mode,connection)=>new Promise((resolve,reject)=>{const child=spawn(process.execPath,['development/scripts/backup.mjs',mode,file],{env:{...process.env,MX_DATABASE_URL:connection},windowsHide:true,stdio:'inherit'});child.on('error',reject);child.on('close',code=>code===0?resolve(null):reject(Error(mode+' failed')));});
try{
  await a.query('CREATE DATABASE '+target+' CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci');
  const destination=new URL(url);destination.pathname='/'+target;
  await invoke('backup',url);await invoke('restore',destination.toString());
  b=await mysql.createConnection(destination.toString());
  const report=[];
  for(const table of ['schema_migrations','players','player_preferences','garage_presets','activity_results','activity_delivery','xp_ledger','player_progression','achievement_progress','challenge_claims']){
    const [left]=await a.query('SELECT * FROM '+table),[right]=await b.query('SELECT * FROM '+table);
    const canonical=rows=>rows.map(r=>JSON.stringify(r)).sort();
    assert.deepEqual(canonical(left),canonical(right),table+' conteúdo divergente');
    report.push({table,rows:right.length,equal:true});
  }
  await writeFile('docs/evidence/restore.json',JSON.stringify({source:new URL(url).pathname.slice(1),target,report},null,2));
  console.log('Backup/restore: conteúdo completo comparado em 10 tabelas; banco de origem preservado.');
}finally{await a.end();if(b)await b.end();}
