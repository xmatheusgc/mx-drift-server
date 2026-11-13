import './workspace.mjs';
import mysql from 'mysql2/promise';
import {randomBytes} from 'node:crypto';
import {writeFile,access} from 'node:fs/promises';
import {migrate} from './migrate.mjs';
async function setup(){
if(!process.env.MX_ADMIN_DATABASE_URL||!process.env.MX_LICENSE_KEY)throw Error('Defina MX_ADMIN_DATABASE_URL e MX_LICENSE_KEY localmente; valores não serão impressos');
try{await access('config/secrets.local.cfg');throw Error('Configuração local já existe; preservada');}catch(e){if(e.code!=='ENOENT')throw e;}
const adminUrl=new URL(process.env.MX_ADMIN_DATABASE_URL);
if(!['127.0.0.1','localhost'].includes(adminUrl.hostname))throw Error('Provisionamento automático restrito ao banco local');
const admin=await mysql.createConnection(adminUrl.toString());
const user='mxapp_'+randomBytes(4).toString('hex'),password=randomBytes(24).toString('hex');
try{
  await admin.query('CREATE DATABASE IF NOT EXISTS mx_freeroam_clean CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci');
  const [tables]=await admin.query("SELECT TABLE_NAME FROM information_schema.TABLES WHERE TABLE_SCHEMA='mx_freeroam_clean'");
  if(tables.length&&!tables.some(t=>t.TABLE_NAME==='schema_migrations'))throw Error('Banco existente sem migrations MX; recusado');
  adminUrl.pathname='/mx_freeroam_clean';const schema=await mysql.createConnection(adminUrl.toString());
  try{await migrate(schema);}finally{await schema.end();}
  await admin.query('CREATE USER ?@? IDENTIFIED BY ?',[user,'127.0.0.1',password]);
  await admin.query('GRANT SELECT,INSERT,UPDATE,DELETE ON mx_freeroam_clean.* TO ?@?',[user,'127.0.0.1']);
  const uri=`mysql://${user}:${password}@127.0.0.1:${adminUrl.port||3306}/mx_freeroam_clean?charset=utf8mb4`;
  const check=await mysql.createConnection(uri);await check.query('SELECT COUNT(*) FROM schema_migrations');await check.end();
  await writeFile('config/secrets.local.cfg',`sv_licenseKey "${process.env.MX_LICENSE_KEY.replace(/["\r\n]/g,'')}"\nset mysql_connection_string "${uri}"\n`,{flag:'wx'});
  console.log('Banco mx_freeroam_clean migrado, usuário de aplicação limitado e configuração local criados. Segredos não versionados.');
}finally{await admin.end();}
}
setup().catch(e=>{console.error('Provisionamento não confirmado: '+(e.code||'VALIDATION')+'. Confira parâmetros locais e permissões; credenciais foram omitidas.');process.exitCode=1;});
