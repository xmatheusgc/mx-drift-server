import './workspace.mjs';
import {spawn} from 'node:child_process';
import {createReadStream,createWriteStream} from 'node:fs';
import {readFile,writeFile} from 'node:fs/promises';
import {pipeline} from 'node:stream/promises';
import {createHash} from 'node:crypto';
import mysql from 'mysql2/promise';
const [mode,file]=process.argv.slice(2);
if(!['backup','restore'].includes(mode)||!file||!process.env.MX_DATABASE_URL)throw Error('Uso: MX_DATABASE_URL + node development/scripts/backup.mjs backup|restore arquivo.sql');
const url=new URL(process.env.MX_DATABASE_URL),dbName=url.pathname.slice(1);
if(!/^mx_freeroam(?:_clean)?(?:_test(?:_[a-z0-9]+)?)?$/.test(dbName))throw Error('Nome de banco fora do namespace MX');
const db=await mysql.createConnection(process.env.MX_DATABASE_URL);
try{
  const common=['--host='+url.hostname,'--port='+(url.port||3306),'--user='+decodeURIComponent(url.username),'--default-character-set=utf8mb4'];
  const env={...process.env,MYSQL_PWD:decodeURIComponent(url.password)};
  if(mode==='restore'){
    const [tables]=await db.query('SHOW TABLES');if(tables.length)throw Error('Restore exige banco vazio; prepare um banco separado e revise antes de trocar o servidor');
    const manifest=JSON.parse(await readFile(file+'.json','utf8'));
    const hash=createHash('sha256').update(await readFile(file)).digest('hex');if(hash!==manifest.sha256)throw Error('Checksum de backup divergente');
  }
  const binary=mode==='backup'?(process.env.MX_MYSQLDUMP||'mysqldump'):(process.env.MX_MYSQL||'mysql');
  const args=mode==='backup'?[...common,'--single-transaction','--routines','--events','--hex-blob','--skip-comments',dbName]:[...common,'--binary-mode',dbName];
  const child=spawn(binary,args,{env,windowsHide:true,stdio:['pipe','pipe','pipe']});
  child.stderr.resume();
  const exit=new Promise((resolve,reject)=>{child.on('error',reject);child.on('close',code=>code===0?resolve(null):reject(Error('Ferramenta SQL falhou; confira acesso e versão sem expor senha')));});
  if(mode==='backup'){child.stdin.end();await Promise.all([pipeline(child.stdout,createWriteStream(file,{flags:'wx'})),exit]);}
  else{child.stdout.resume();await Promise.all([pipeline(createReadStream(file),child.stdin),exit]);}
  if(mode==='backup'){
    const [[version]]=await db.query('SELECT VERSION() AS version');
    await writeFile(file+'.json',JSON.stringify({database:dbName,version:version.version,createdUtc:new Date().toISOString(),sha256:createHash('sha256').update(await readFile(file)).digest('hex')},null,2));
  }
  console.log(mode==='backup'?'Backup e checksum criados':'Restore concluído em banco vazio');
}finally{await db.end();}
