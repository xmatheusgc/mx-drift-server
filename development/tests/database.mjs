import '../scripts/workspace.mjs';
import mysql from 'mysql2/promise';
import assert from 'node:assert/strict';
import {randomUUID} from 'node:crypto';
import {migrate} from '../scripts/migrate.mjs';
const url=process.env.MX_TEST_DATABASE_URL;
if(!url||!new URL(url).pathname.match(/^\/mx_freeroam_test(?:_[a-z0-9]+)?$/)) throw Error('MX_TEST_DATABASE_URL deve apontar exclusivamente para mx_freeroam_test[_sufixo]');
const db=await mysql.createConnection(url);
try{
  await migrate(db);await migrate(db);
  const id='test:'+randomUUID();
  await db.execute('INSERT INTO players(identifier,name) VALUES (?,?)',[id,'Teste']);
  const [[p]]=await db.execute('SELECT id FROM players WHERE identifier=?',[id]);
  await db.execute('INSERT INTO players(identifier,name) VALUES (?,?) ON DUPLICATE KEY UPDATE last_seen=CURRENT_TIMESTAMP(3)',[id,'Outro']);
  const [[identity]]=await db.execute('SELECT COUNT(*) AS n FROM players WHERE identifier=?',[id]);assert.equal(identity.n,1);
  await db.execute('INSERT INTO player_preferences(player_id,document) VALUES (?,?)',[p.id,JSON.stringify({units:'mph'})]);
  const vehicleDocument={schemaVersion:1,primary:70,secondary:12,pearlescent:5,wheelColor:0,wheelType:12,mods:{23:250,38:2,49:1},extras:{1:true},livery:-1,plate:'MX JDM',plateStyle:12,tint:2,xenon:true,xenonColor:255,neon:[true,true,false,false],neonColor:[20,30,40],smokeColor:[40,30,20],turbo:false,smoke:true,customTyres:true,customRearTyres:false,customPrimary:[12,34,56],customSecondary:false,primaryFinish:3,secondaryFinish:-1,interiorColor:12,dashboardColor:10,roofLivery:2,xenonCustom:[40,50,60],subwoofer:false,hydraulics:false,stance:{version:1,height:-.04,frontCamber:-6,rearCamber:-3,frontOffset:.04,rearOffset:.03,wheelSize:1.1,wheelWidth:1.2}};
  const preset=randomUUID();await db.execute('INSERT INTO garage_presets(id,player_id,name,model,properties) VALUES (?,?,?,?,?)',[preset,p.id,'Configuração','futo',JSON.stringify(vehicleDocument)]);
  const [[initialMode]]=await db.execute('SELECT drift_enabled FROM garage_presets WHERE id=?',[preset]);assert.equal(initialMode.drift_enabled,0);
  await db.execute('UPDATE garage_presets SET drift_enabled=1 WHERE id=? AND player_id=?',[preset,p.id]);
  const [foreignMode]=await db.execute('UPDATE garage_presets SET drift_enabled=0 WHERE id=? AND player_id=?',[preset,p.id+100000]);assert.equal(foreignMode.affectedRows,0);
  const [foreign]=await db.execute('SELECT * FROM garage_presets WHERE id=? AND player_id=?',[preset,p.id+100000]);assert.equal(foreign.length,0);
  const [updated]=await db.execute('UPDATE garage_presets SET name=?,revision=revision+1 WHERE id=? AND player_id=? AND revision=?',['Nova',preset,p.id,1]);assert.equal(updated.affectedRows,1);
  const [stale]=await db.execute('UPDATE garage_presets SET name=?,revision=revision+1 WHERE id=? AND player_id=? AND revision=?',['Obsoleta',preset,p.id,1]);assert.equal(stale.affectedRows,0);
  await db.end();
  const reopened=await mysql.createConnection(url);
  try{
    const [[saved]]=await reopened.execute('SELECT properties,name,drift_enabled FROM garage_presets WHERE id=? AND player_id=?',[preset,p.id]);assert.deepEqual(JSON.parse(saved.properties),vehicleDocument);assert.equal(saved.name,'Nova');assert.equal(saved.drift_enabled,1);
    await reopened.execute('UPDATE garage_presets SET drift_enabled=0 WHERE id=? AND player_id=?',[preset,p.id]);
    const second=await mysql.createConnection(url);
    try{const [[disabled]]=await second.execute('SELECT drift_enabled FROM garage_presets WHERE id=? AND player_id=?',[preset,p.id]);assert.equal(disabled.drift_enabled,0);}finally{await second.end();}
    const [[pref]]=await reopened.execute('SELECT document FROM player_preferences WHERE player_id=?',[p.id]);assert.equal(JSON.parse(pref.document).units,'mph');
  }finally{await reopened.end();}
  console.log('MariaDB real: migrations repetíveis, identidade única, propriedade, conflito de revisão e recuperação após nova conexão SQL aprovados. Isso não é reconexão de cliente FiveM.');
}finally{try{await db.end()}catch{}}
