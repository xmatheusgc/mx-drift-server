import '../scripts/workspace.mjs';
import {chromium} from 'playwright';
import {createServer} from 'node:http';
import {readFile,mkdir,writeFile} from 'node:fs/promises';
import path from 'node:path';
import assert from 'node:assert/strict';
const root=path.resolve('resources/[mx]/mx-freeroam-menu/dist');
const server=createServer(async(req,res)=>{try{const file=path.resolve(root,'.'+decodeURIComponent(req.url==='/'?'/index.html':req.url.split('?')[0]));if(!file.startsWith(root+path.sep)){res.writeHead(403).end();return;}res.setHeader('Content-Type',file.endsWith('.js')?'application/javascript':file.endsWith('.css')?'text/css':file.endsWith('.ttf')?'font/ttf':'text/html');res.end(await readFile(file));}catch{res.writeHead(404).end();}});
await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));
const browser=await chromium.launch({executablePath:process.env.MX_CHROMIUM,headless:true});
const report=[];
const properties={schemaVersion:1,primary:0,secondary:0,pearlescent:0,wheelColor:0,wheelType:0,mods:{},extras:{},livery:-1,plate:'MX JDM',plateStyle:0,tint:-1,xenon:false,xenonColor:255,neon:[false,false,false,false],neonColor:[255,255,255],smokeColor:[255,255,255],turbo:false,smoke:false,customTyres:false};
const profile={name:'UI Fixture',revision:1,preferences:{hud:true,share:true,uniform:false,photo:false,units:'kmh',blips:'all',invites:'all',scale:1,volume:.3,appearance:'driver',outfit:0,muted:[]}};
const garage=[{id:'11111111-1111-1111-1111-111111111111',name:'Minha criação azul',model:'futo',revision:1,available:true}];
const models=['futo','elegy','elegy2','sultan','blista'].map((id,i)=>({id,model:id,name:['Karin Futo','Elegy Retro Custom','Elegy RH8','Karin Sultan','Dinka Blista'][i],brand:i<4?'JDM':'OUTRA',category:i===0?'Coupe':'JDM',tags:['vanilla'],available:true}));
garage.push({...garage[0],id:'22222222-2222-2222-2222-222222222222',name:'Segunda criação'});
const fixtureCaps={stance:{available:true,tuningWheels:false,ranges:{height:[-.15,.15,.005],frontCamber:[-12,12,.5],rearCamber:[-12,12,.5],frontOffset:[-.12,.2,.005],rearOffset:[-.12,.2,.005],wheelSize:[.8,1.25,.01],wheelWidth:[.7,1.35,.01]}},mods:[{slot:0,count:3},{slot:1,count:4},{slot:2,count:3},{slot:23,count:300},{slot:38,count:3},{slot:49,count:2},{slot:33,count:2}],extras:[1,2],liveries:3,roofLiveries:2,plateStyles:13,wheelTypes:[0,12],neon:[true,true,true,true],dimensions:{length:4.2}};
const state={phase:'workshop',token:'UI-FIXTURE-NOT-A-SESSION',characterCompleted:true,vehicleCompleted:true,selected:garage[0],garage,revision:1};
try{
 await mkdir('docs/evidence',{recursive:true});
 for(const [width,height] of [[1280,720],[1920,1080],[2560,1440],[3440,1440]]){
  const page=await browser.newPage({viewport:{width,height}}),errors=[],calls=[];let adminEnabled=false;let vehicleOnFoot=false,vehicleDrift=false;const vehicleActions=['repair','clean','flip','engine','doors','stop','lock','eject','respawn','drift'];let bindingValues=[['menu','Menu do modo livre','M'],['repair','Reparar veículo','R'],['noclip','Alternar noclip','F2'],['saveCheckpoint','Criar checkpoint','F3'],['returnCheckpoint','Voltar ao checkpoint','F4'],['clean','Limpar veículo',''],['cycleSpeed','Noclip: velocidade','SHIFT'],['up','Noclip: subir','Q'],['down','Noclip: descer','Z'],['cameraMode','Noclip: orientação','H']].map(([id,label,key])=>({id,label,key,pad:'',default:key}));let trainerState={noclip:false,speed:3,followCamera:true,checkpoint:false},shown=properties,orbital=false,loseNextSave=false,delayNextCosmetic=false,cosmeticPending=false,invalidatedDuringCosmetic=false;const savedProperties=new Map([[garage[0].id,structuredClone(properties)]]),operations=new Map();state.current={...garage[0],properties:structuredClone(properties)};state.currentDirty=false;state.preview={id:'ui-entity-fixture',model:'futo',properties:state.current.properties,capabilities:fixtureCaps};page.on('pageerror',e=>errors.push(e.message));
  // Browser contract fixtures ONLY. No FiveM/native/SQL success is implied.
  let rejectNextDrift=true;
  const cameraOriginal={context:'garage',view:'main',position:{x:135,y:-3030,z:8},rotation:{x:-5,y:0,z:90},fov:60};let cameraFixture=structuredClone(cameraOriginal);
  let missingAdminWaypoint=true;
  const adminCoordinate={target:'ped',x:135.9,y:-3030.47,z:6.4,h:359.72,model:225514697,interior:42,networkId:501};
  let resizeCase=false,sizeBlocked=false;
  function stanceCapabilities(){
   if(!resizeCase)return fixtureCaps;
   const effective=structuredClone(shown.stance);
   if(effective.wheelSize!==1){sizeBlocked=true;effective.wheelSize=1;}
   shown={...shown,stance:effective};
   return {...fixtureCaps,stance:{...fixtureCaps.stance,tuningWheels:true,value:effective,unavailable:sizeBlocked?{wheelSize:'Este conjunto de rodas não permite alterar o diâmetro.'}:{},warning:sizeBlocked?'Diâmetro indisponível; os demais ajustes continuam disponíveis.':undefined}};
  }
  await page.addInitScript(()=>{window.GetParentResourceName=()=> 'mx-freeroam-menu';});
  await page.route('https://mx-freeroam-menu/**',async route=>{
   const action=new URL(route.request().url()).pathname.slice(1),body=route.request().postDataJSON()??{};calls.push({action,body});
   let data={};let ok=true;
   if(action==='vehicleSound'){
    page.soundFixture??={vehicleId:55,status:'playing',active:true,paused:false,volume:15,meta:{title:'Faixa de teste',uploader:'Artista de teste'},queue:[{meta:{title:'Próxima faixa'}}]};
    if(body.action==='volume')page.soundFixture.volume=body.volume;
    if(body.action==='pause'){page.soundFixture.paused=true;page.soundFixture.status='paused';}
    if(body.action==='resume'){page.soundFixture.paused=false;page.soundFixture.status='playing';}
    if(body.action==='stop'){page.soundFixture.active=false;page.soundFixture.status='idle';page.soundFixture.queue=[];page.soundFixture.meta=null;}
    data=page.soundFixture;
   }
   else if(action==='personalEnvironment'){
    page.environmentFixture??={syncWeather:true,syncTime:true,weather:'CLEAR',hour:14,minute:0,server:{weather:'CLEAR',hour:14,minute:0},choices:[{id:'CLEAR',label:'Limpo'},{id:'FOGGY',label:'Neblina'}]};
    page.environmentFixture={...page.environmentFixture,...body.patch};data=page.environmentFixture;
   }
   else if(action==='navigationContext'){await route.fulfill({status:200,contentType:'application/json',body:JSON.stringify({ok:true,data:{}})});return;}
   else if(action==='cameraDeveloper'){
    if(body.action==='update')cameraFixture={...cameraFixture,...body.pose};
    if(body.action==='reset')cameraFixture=structuredClone(cameraOriginal);
    data={...cameraFixture};
    if(body.action==='capture')data.text=`{context="garage", view="main", position={x=${cameraFixture.position.x.toFixed(3)}, y=${cameraFixture.position.y.toFixed(3)}, z=${cameraFixture.position.z.toFixed(3)}}, rotation={x=${cameraFixture.rotation.x.toFixed(2)}, y=0, z=${cameraFixture.rotation.z.toFixed(2)}}, fov=${cameraFixture.fov.toFixed(2)}}`;
    if(body.action==='close'){if(body.restore)cameraFixture=structuredClone(cameraOriginal);await page.evaluate(()=>window.postMessage({type:'cameraDeveloper',open:false},'*'));}
   }
   else if(action==='request'){
    const key=body.domain+':'+body.action;
    const responses={'core:profile':profile,'admin:permissions':{admin:adminEnabled,inspect:adminEnabled,content:adminEnabled,warn:adminEnabled,kick:adminEnabled,ban:adminEnabled},'vehicles:catalogBrands':['JDM','OUTRA'],'social:players':[{source:72,name:'Jogador de teste',state:'freeroam',level:1}]};
    if(key==='vehicles:options')data={id:'managed-ui-fixture',driver:!vehicleOnFoot,near:true,exists:true,drift:vehicleDrift,doors:[0,1,4,5],available:Object.fromEntries(vehicleActions.map(k=>[k,!vehicleOnFoot||!['stop','drift'].includes(k)])),reasons:vehicleOnFoot?{stop:'Entre no banco do motorista',drift:'Entre no banco do motorista'}:{}};
    else if(key==='admin:inspect')data={permissions:{inspect:true,content:true,teleport:true},resources:{core:'started'},vehicles:[],presentations:[],sessions:[]};
    else if(key==='admin:coordinates')data={...adminCoordinate,target:body.data.target};
    else if(key==='admin:coordinateOverlay'){data={enabled:body.data.enabled,target:body.data.target};await page.evaluate(p=>window.postMessage({type:'adminCoordinates',data:p},'*'),body.data.enabled?{...adminCoordinate,target:body.data.target}:false);}
    else if(key==='admin:cameraEditor'){data={enabled:true};await page.evaluate(p=>window.postMessage({type:'cameraDeveloper',open:true,data:p},'*'),cameraFixture);}
    else if(key==='admin:teleport'){
     if(body.data.mode==='waypoint'&&missingAdminWaypoint){await route.fulfill({status:200,contentType:'application/json',body:JSON.stringify({ok:false,code:'WAYPOINT',message:'Marque um destino no mapa antes de teleportar'})});return;}
     data={point:body.data.point??{x:1000,y:2000,z:41,h:359.72},destination:'admin'};
    }
    else if(key==='admin:moderate'||key==='admin:createTeleport')data={applied:true};
    else if(key==='world:destinations')data=[{id:'test-circuit',name:'Circuito de teste',category:'Circuito',available:true,validated:true}];
    else if(key==='world:travel')data={destination:body.data.destination};
    else if(key==='world:trainerState')data=trainerState;
    else if(key==='world:noclip'){trainerState={...trainerState,noclip:body.data.enabled,speed:body.data.speed??trainerState.speed,followCamera:body.data.followCamera??trainerState.followCamera};data=trainerState;}
    else if(key==='world:saveCheckpoint'){trainerState={...trainerState,checkpoint:{x:135,y:-3030,z:6,h:0}};data=trainerState;}
    else if(key==='world:returnCheckpoint'){trainerState={...trainerState,noclip:false};data=trainerState;}
    else if(key==='world:clearCheckpoint'){trainerState={...trainerState,checkpoint:false};data=trainerState;}
    else if(key==='vehicles:service'){if(body.data.kind==='drift'&&rejectNextDrift){rejectNextDrift=false;data={enabled:false,persisted:false,warning:'Drift indisponível; carro preservado'};}else{if(body.data.kind==='drift')vehicleDrift=body.data.enabled;data={enabled:vehicleDrift};}}
    else if(key==='vehicles:trainerGarage')data=garage;
    else if(key==='vehicles:switch')data={model:body.data.model??'futo',id:'managed-switched'};
    else if(key in responses)data=responses[key];
    else if(key==='vehicles:catalog'){assert(body.data.brand,'showroom must not fetch an unfiltered model list');data=models.filter(m=>m.brand===body.data.brand);await new Promise(resolve=>setTimeout(resolve,body.data.brand==='JDM'?300:80));}
    else if(key==='experience:preview')data={id:'ui-entity-fixture',net:0,model:body.data.model??'futo',properties:savedProperties.get(body.data.id)??properties,capabilities:fixtureCaps};
    else if(key==='experience:cosmetic'){const now=Date.now();if(calls.filter(c=>c.body.action==='cosmetic'&&c.at&&now-c.at<150).length)throw Error('cosmetic request exceeded server interval');calls.at(-1).at=now;if(delayNextCosmetic){delayNextCosmetic=false;cosmeticPending=true;await new Promise(resolve=>setTimeout(resolve,180));cosmeticPending=false;}shown=body.data.properties;data={applied:true,capabilities:stanceCapabilities()};}
    else if(key==='experience:garage'){
     const d=body.data;
     if(d.action==='save'){
      if(!operations.has(d.operation)){
       const row=garage.find(r=>r.id===d.id);assert.equal(d.revision,row.revision,'each apply uses latest saved vehicle revision');assert.equal(d.stateRevision,state.revision,'each apply uses latest garage revision');
       row.revision++;state.revision++;savedProperties.set(d.id,structuredClone(d.properties));operations.set(d.operation,true);
      }
      if(loseNextSave){loseNextSave=false;ok=false;}
     }
     data={state};
    }
    else if(key==='experience:useCurrent'){state.current={id:body.data.id,revision:1,model:body.data.model,name:body.data.model,properties:structuredClone(properties),available:true};garage.push({...state.current});savedProperties.set(state.current.id,structuredClone(properties));state.currentDirty=false;data={state};}
    else if(key==='experience:discardCurrent'){state.current.properties=structuredClone(savedProperties.get(state.current.id));state.currentDirty=false;state.preview.properties=state.current.properties;data={state};}
    else if(key==='experience:confirmCurrent'){const d=body.data;if(!operations.has(d.operation)){state.current.properties=structuredClone(d.properties);state.current.revision++;state.currentDirty=false;state.preview.properties=state.current.properties;savedProperties.set(state.current.id,structuredClone(d.properties));operations.set(d.operation,true);}data={state};if(loseNextSave){loseNextSave=false;ok=false;}}
    else if(key==='experience:saveCurrent'){const d=body.data;if(!operations.has(d.operation)){if(!state.current.id){state.current={...state.current,id:d.id,revision:1};garage.push({...state.current});}savedProperties.set(state.current.id,structuredClone(state.current.properties));state.currentDirty=false;operations.set(d.operation,true);}data={state};if(loseNextSave){loseNextSave=false;ok=false;}}
    else if(key==='experience:state')data=state;
    else if(key==='experience:resetPreview'){state.preview={id:'ui-entity-fixture',model:state.current.model,properties:state.current.properties,capabilities:fixtureCaps};data={state};}
    else {ok=false;data={};}
   }else if(action==='experienceLocal'&&body.action==='stancePreview'){shown={...shown,stance:body.stance};data={stance:stanceCapabilities().stance};}else if(action==='experienceLocal'){data=body.action==='vehicleOptions'?{slot:body.slot,wheelType:shown.wheelType,names:['Native wheel name']}:body.action==='freeCamera'?{free:(orbital=!orbital)}:{enabled:false,reduceMotion:false};}
   else if(action==='bindings')data=bindingValues;
   else if(action==='setBinding'){bindingValues=bindingValues.map(b=>b.id===body.action?{...b,[body.kind]:body.value.toUpperCase()}:b);data=bindingValues;}
   else if(action==='trainerOptions')data={testPlayer:true};
   else if(action==='noclipToggle'){trainerState={...trainerState,noclip:!trainerState.noclip};data=trainerState;}
   else if(action==='openWorkshop'){ok=false;data={};}
   else if(action==='close'){await page.evaluate(()=>window.postMessage({type:'menu',open:false},'*'));}
   else if(action==='previewIntent'){if(cosmeticPending)invalidatedDuringCosmetic=true;}else {ok=false;}
   if(action==='experienceLocal'&&body.action==='vehicleEditor'&&body.enabled===false){orbital=false;await page.evaluate(()=>window.postMessage({type:'workshopCamera',free:false},'*'));}
   if(action==='experienceLocal'&&body.action==='freeCamera')await page.evaluate(free=>window.postMessage({type:'workshopCamera',free},'*'),orbital);
   await route.fulfill({status:200,headers:{'Access-Control-Allow-Origin':'*','Access-Control-Allow-Headers':'Content-Type'},contentType:'application/json',body:JSON.stringify(ok?{ok:true,data}:{ok:false,code:action==='openWorkshop'?'POSITION':'UI_FIXTURE',message:action==='openWorkshop'?'POSITION':'Mutação não executada neste teste de browser'})});
  });
  page.setDefaultTimeout(12000);await page.goto(`http://127.0.0.1:${server.address().port}`);await page.evaluate(()=>document.body.style.background='#292b30');await page.evaluate(()=>document.fonts.ready);
  await page.evaluate(()=>{window.postMessage({type:'workshopEntry',visible:true},'*');window.postMessage({type:'workshopInputDevice',device:'keyboard'},'*');});await page.locator('.workshop-entry-prompt').waitFor();assert.equal(await page.locator('.workshop-entry-prompt img').getAttribute('alt'),'E');await page.screenshot({path:'docs/evidence/workshop-entry-'+width+'x'+height+'.png'});
  await page.evaluate(()=>window.postMessage({type:'workshopInputDevice',device:'gamepad',style:'playstation'},'*'));await page.locator('.workshop-entry-prompt [aria-label="Direcional direito"]').waitFor();await page.evaluate(()=>window.postMessage({type:'workshopEntry',visible:false},'*'));await page.locator('.workshop-entry-prompt').waitFor({state:'detached'});
  await page.evaluate(()=>window.postMessage({type:'hud',data:{enabled:true,speed:108,units:'km/h',gear:3,rpm:.8,scale:1}},'*'));await page.locator('.mx-speedometer').waitFor();assert.equal(await page.locator('.speedometer-gear').textContent(),'3');await page.screenshot({path:'docs/evidence/trainer-indicators-'+width+'x'+height+'.png'});await page.evaluate(()=>window.postMessage({type:'hud',data:{enabled:false}},'*'));
  await page.evaluate(()=>window.postMessage({type:'menu',open:true},'*'));
  const menu=page.locator('.session-menu');await menu.waitFor();await page.waitForFunction(()=>document.querySelector('.session-menu')?.getAttribute('aria-busy')==='false');
  async function menuReady(){await page.waitForFunction(()=>document.querySelector('.session-menu')?.getAttribute('aria-busy')==='false');}
  async function menuSelect(label,activate=true){await menuReady();for(let n=0;n<30;n++){if(await menu.locator('.session-row[aria-selected=true]>span>span').textContent()===label){if(activate)await page.keyboard.press('Enter');return;}await page.keyboard.press('ArrowDown');}throw Error('Missing trainer row '+label);}
  await menuSelect('Clima e horário');await menuReady();
  assert.equal(await menu.locator('.session-row').filter({has:page.locator('span>span',{hasText:/^Clima$/})}).getAttribute('aria-disabled'),'true');
  await menuSelect('Sincronizar clima');await menuReady();
  await menuSelect('Clima',false);await page.keyboard.press('ArrowRight');await menuReady();assert.match(await menu.locator('[aria-selected=true]').textContent(),/Neblina/);
  await menuSelect('Sincronizar horário');await menuReady();
  await menuSelect('Hora',false);await page.evaluate(()=>window.postMessage({type:'nav',key:'right'},'*'));
  await page.waitForFunction(()=>document.querySelector('.session-row[aria-selected=true]')?.textContent?.includes('15'));await menuReady();
  assert.equal(page.environmentFixture.hour,15,'controller changes personal hour');
  await page.screenshot({path:`docs/evidence/personal-environment-${width}x${height}.png`});
  await menuSelect('Usar clima e horário do servidor');await menuReady();
  assert(page.environmentFixture.syncTime&&page.environmentFixture.syncWeather,'both independent preferences can resync');
  await page.keyboard.press('Backspace');await menuReady();
  await menuSelect('Som do veículo');await menuReady();assert.match(await menu.textContent(),/Faixa de teste/);
  await menuSelect('Tocar música');await page.getByRole('textbox').fill('Teste por nome');await page.keyboard.press('Enter');await menuReady();
  assert(calls.some(c=>c.action==='vehicleSound'&&c.body.action==='play'&&c.body.vehicleId===55&&c.body.input==='Teste por nome'));
  await menuSelect('Adicionar à fila');await page.getByRole('textbox').fill('https://example.com/test.ogg');await page.keyboard.press('Enter');await menuReady();
  assert(calls.some(c=>c.action==='vehicleSound'&&c.body.action==='queue'&&c.body.input==='https://example.com/test.ogg'));
  await menuSelect('Pausar');await menuReady();assert.match(await menu.textContent(),/Continuar/);await menuSelect('Continuar');await menuReady();
  await menuSelect('Volume');await page.getByRole('textbox').fill('1');await page.keyboard.press('Enter');await menuReady();assert.equal(page.soundFixture.volume,1);
  await page.screenshot({path:`docs/evidence/soundcore-menu-${width}x${height}.png`});
  await menuSelect('Parar e limpar fila');await menuReady();assert.equal(page.soundFixture.active,false);await page.keyboard.press('Backspace');await menuReady();
  await menuSelect('Voltar para a garagem');await menu.getByRole('alert').waitFor();assert.match(await menu.getByRole('alert').textContent(),/confirmar a posi/);assert.doesNotMatch(await menu.getByRole('alert').textContent(),/POSITION: POSITION/);
  await page.screenshot({path:'docs/evidence/trainer-garage-error-'+width+'x'+height+'.png'});
  await menuSelect('Opções do veículo');await page.waitForFunction(()=>document.querySelector('.session-menu')?.getAttribute('data-page')==='vehicle');await menuReady();
  await page.keyboard.press('ArrowDown');assert.match(await page.locator('.session-row[aria-selected=true]').textContent(),/Limpar/);
  await menuSelect('Portas',false);const beforeDoor=calls.filter(c=>c.body.action==='service'&&c.body.data.kind==='doors').length;
  await page.keyboard.press('ArrowRight');assert.match(await menu.locator('[aria-selected=true]').textContent(),/Dianteira esquerda/);assert.equal(calls.filter(c=>c.body.action==='service'&&c.body.data.kind==='doors').length,beforeDoor,'door arrows choose without executing');
  await page.keyboard.press('Enter');await menuReady();assert(calls.some(c=>c.body.action==='service'&&c.body.data.kind==='doors'&&c.body.data.door===0),'Enter executes selected existing door');
  await menuSelect('Handling de drift');await menuReady();assert.match(await menu.locator('[aria-selected=true]').textContent(),/DESLIGADO/);assert.match(await menu.locator('.session-detail').textContent(),/Drift indisponível; carro preservado/);assert.equal(await menu.locator('.session-detail').getAttribute('role'),'status','recovered optional failure is a warning, not a blocking error');
  await page.screenshot({path:'docs/evidence/drift-fallback-'+width+'x'+height+'.png'});
  await menuSelect('Handling de drift');await menuReady();assert.match(await menu.locator('[aria-selected=true]').textContent(),/LIGADO/);
  await menuSelect('Recriar veículo');assert.match(await menu.locator('.session-heading').textContent(),/Confirmar/);await page.keyboard.press('Backspace');
  await page.screenshot({path:'docs/evidence/vehicle-options-'+width+'x'+height+'.png'});
  vehicleOnFoot=true;await page.waitForFunction(()=>document.querySelector('.session-row[aria-disabled=true]')?.textContent?.includes('Handling')||Array.from(document.querySelectorAll('.session-row[aria-disabled=true]')).some(el=>el.textContent?.includes('Handling')));
  await menuSelect('Handling de drift',false);assert.equal(await menu.locator('[aria-selected=true]').getAttribute('aria-disabled'),'true');
  const beforeDisabled=calls.filter(c=>c.body.action==='service'&&c.body.data.kind==='drift').length;await page.keyboard.press('Enter');assert.equal(calls.filter(c=>c.body.action==='service'&&c.body.data.kind==='drift').length,beforeDisabled,'disabled handling cannot execute on foot');
  await menuSelect('Ligar / desligar motor');await menuReady();assert(calls.some(c=>c.body.action==='service'&&c.body.data.kind==='engine'),'engine remains usable on foot');
  await page.screenshot({path:'docs/evidence/vehicle-options-on-foot-'+width+'x'+height+'.png'});
  vehicleOnFoot=false;await menuSelect('Limpar',false);

  await page.keyboard.press('Backspace');await page.waitForFunction(()=>document.querySelector('.session-menu')?.getAttribute('data-page')==='root'&&document.querySelector('.session-menu')?.getAttribute('aria-busy')==='false');assert.match(await page.locator('.session-row[aria-selected=true]').textContent(),/Opções do veículo/);
  await menuSelect('Trocar de carro');await menuSelect('Carros salvos');await menuSelect('Minha criação azul');await menuReady();
  assert(calls.some(c=>c.body.domain==='vehicles'&&c.body.action==='switch'&&c.body.data.presetId===garage[0].id),'trainer can switch to a saved creation');
  assert.match(await menu.locator('.session-detail').textContent(),/Carro trocado/);
  await page.keyboard.press('Backspace');await menuSelect('Catálogo de modelos');await menuSelect('JDM');await menuSelect('Karin Futo');await menuReady();
  assert(calls.some(c=>c.body.domain==='vehicles'&&c.body.action==='switch'&&c.body.data.model==='futo'),'trainer can switch directly to a catalog model');
  await page.screenshot({path:'docs/evidence/trainer-switch-car-'+width+'x'+height+'.png'});
  await page.keyboard.press('Backspace');await page.keyboard.press('Backspace');await page.keyboard.press('Backspace');await menuReady();
  assert(!/Preferências|Controles/.test(await menu.locator('.session-rows').textContent()),'preferences and controls moved to pause settings');
  const bounds=await menu.boundingBox();assert(bounds.width<=355&&bounds.x>=0&&bounds.y>=0&&bounds.y+bounds.height<=height);assert.equal(await menu.getByRole('button').count(),0,'trainer has no clickable buttons');assert.equal(await menu.evaluate(el=>getComputedStyle(el).pointerEvents),'none');
  await page.screenshot({animations: 'disabled',path:`docs/evidence/session-keyboard-${width}x${height}.png`});
  assert(!/Social e voz|Atividades|Meu perfil/.test(await menu.locator('.session-rows').textContent()),'trainer omits encounter/competition/progression menus');
  const beforeMouse=await menu.locator('[aria-selected=true]').textContent();await menu.locator('.session-row').first().evaluate(el=>el.click());assert.equal(await menu.locator('[aria-selected=true]').textContent(),beforeMouse,'mouse click does not select/activate trainer rows');await menuSelect('Pilotagem livre');
  await page.waitForFunction(()=>document.querySelector('.session-menu')?.getAttribute('data-page')==='trainer'&&document.querySelector('.session-menu')?.getAttribute('aria-busy')==='false');
  await page.keyboard.press('F3');await page.waitForFunction(()=>document.querySelector('.session-detail')?.textContent==='Confirmado');
  await page.keyboard.press('F2');await page.waitForFunction(()=>document.querySelector('.trainer-active')?.textContent==='LIGADO');
  await menuSelect('Velocidade do noclip',false);for(let step=0;step<5;step++){await page.keyboard.press('ArrowRight');await menuReady();}
  assert.match(await menu.locator('[aria-selected=true]').textContent(),/Máximo/);
  await menuSelect('Orientação do noclip');await menuReady();assert.match(await menu.locator('[aria-selected=true]').textContent(),/Fixa/);
  await page.keyboard.press('m');await menu.waitFor({state:'detached'});await page.locator('.trainer-indicator').waitFor();
  assert.match(await page.locator('.trainer-indicator').textContent(),/Q \/ Z/);await page.screenshot({path:'docs/evidence/noclip-guide-'+width+'x'+height+'.png'});
  await page.evaluate(()=>window.postMessage({type:'menu',open:true},'*'));await menu.waitFor();await menuReady();

  await page.keyboard.press('F4');await page.waitForFunction(()=>!document.querySelector('.trainer-active'));
  assert(calls.some(c=>c.body.domain==='world'&&c.body.action==='saveCheckpoint')&&calls.some(c=>c.body.action==='returnCheckpoint'));
  await page.screenshot({path:'docs/evidence/trainer-tools-'+width+'x'+height+'.png'});
  await page.keyboard.press('Backspace');await page.waitForFunction(()=>document.querySelector('.session-menu')?.getAttribute('data-page')==='root'&&document.querySelector('.session-menu')?.getAttribute('aria-busy')==='false');

  assert(!await menu.locator('.session-rows').textContent().then(t=>t.includes('Administração')),'non-admin cannot see administration');
  await menuSelect('Pistas');await menuSelect('Circuito');
  const travelCount=calls.filter(c=>c.body.domain==='world'&&c.body.action==='travel').length;
  await menuSelect('Circuito de teste');await menuReady();
  const travelCalls=calls.filter(c=>c.body.domain==='world'&&c.body.action==='travel');
  assert.equal(travelCalls.length,travelCount+1,'confirming track immediately sends a single teleport request');
  assert.deepEqual(travelCalls.at(-1).body.data,{destination:'test-circuit'},'travel mode is determined on the server');
  assert.match(await menu.locator('.session-detail').textContent(),/Teleporte confirmado/,'successful track confirmation is shown in the existing menu');
  assert(!/Ir a pé|Ir com meu carro/.test(await menu.locator('.session-rows').textContent()),'no intermediate travel mode submenu');
  await page.screenshot({path:'docs/evidence/track-direct-teleport-'+width+'x'+height+'.png'});
  await page.keyboard.press('Backspace');await page.keyboard.press('Backspace');await menuReady();
  adminEnabled=true;await page.keyboard.press('m');await menu.waitFor({state:'detached'});await page.evaluate(()=>window.postMessage({type:'menu',open:true},'*'));await menu.waitFor();await menuReady();
  await menu.locator('.session-row').filter({hasText:'Administração'}).waitFor();await menuSelect('Administração');await menuSelect('Diagnósticos');assert.match(await menu.locator('.session-rows').textContent(),/Recursos.*Veículos ativos.*Apresentações da oficina.*Sessões de atividade/);await page.keyboard.press('Backspace');await menuReady();
  await menuSelect('Coordenadas e heading');await menuReady();assert.match(await menu.locator('.session-rows').textContent(),/135\.900.*-3030\.470.*6\.400.*359\.72/);
  await menuSelect('Mostrar coordenadas na tela');await page.getByLabel('Coordenadas de administrador').waitFor();
  await page.keyboard.press('m');await menu.waitFor({state:'detached'});assert(await page.getByLabel('Coordenadas de administrador').isVisible(),'admin coordinates remain visible with menu closed');
  await page.evaluate(()=>window.postMessage({type:'menu',open:true},'*'));await menu.waitFor();await menuReady();
  await menuSelect('Capturar vector4 + heading');const capture=page.getByRole('textbox',{name:'Captura vector4',exact:true});await capture.waitFor();assert.equal(await capture.inputValue(),'vector4(135.900, -3030.470, 6.400, 359.72)');assert(await capture.getAttribute('readonly')!==null,'capture is immutable and selectable');await page.keyboard.press('Escape');await menuReady();
  await page.screenshot({path:`docs/evidence/admin-coordinates-${width}x${height}.png`});
  await menuSelect('Mostrar coordenadas na tela');await page.getByLabel('Coordenadas de administrador').waitFor({state:'detached'});
  await page.keyboard.press('Backspace');await menuReady();await menuSelect('Teleporte administrativo');
  const adminTrips=()=>calls.filter(c=>c.body.domain==='admin'&&c.body.action==='teleport');const tripsBefore=adminTrips().length;
  await menuSelect('Ir para coordenadas');await page.getByRole('textbox').fill('NaN, 2, 3');await page.keyboard.press('Enter');await menuReady();assert.equal(adminTrips().length,tripsBefore,'invalid coordinates do not send a teleport');
  await menuSelect('Ir para coordenadas');await page.getByRole('textbox').fill('vector4(135.9, -3030.47, 6.4, 90)');await page.keyboard.press('Enter');await menuReady();assert.deepEqual(adminTrips().at(-1).body.data,{mode:'coordinates',point:{x:135.9,y:-3030.47,z:6.4,h:90}});
  await menuSelect('Ir para marcador do mapa');await menuReady();assert.match(await menu.locator('.session-detail').textContent(),/Marque um destino/);missingAdminWaypoint=false;
  await menuSelect('Ir para marcador do mapa');await menuReady();assert.match(await menu.locator('.session-detail').textContent(),/Teleporte confirmado/);
  await page.screenshot({path:`docs/evidence/admin-teleport-${width}x${height}.png`});await page.keyboard.press('Backspace');await menuReady();
  await menuSelect('Criar ponto de pista aqui');await page.getByRole('textbox').fill('Minha pista');await page.keyboard.press('Enter');await page.getByRole('textbox').fill('Touge');await page.keyboard.press('Enter');await menuReady();assert(calls.some(c=>c.body.action==='createTeleport'&&c.body.data.name==='Minha pista'&&c.body.data.category==='Touge'&&!('position' in c.body.data)));
  await menuSelect('Moderação de jogadores');await menuSelect('[TESTE] Piloto temporário');await menuSelect('Banir permanentemente');await page.getByRole('textbox').fill('Teste da interface');await page.keyboard.press('Enter');await menuReady();
  assert.match(await menu.locator('.session-rows').textContent(),/TESTE/);await page.keyboard.press('ArrowDown');await page.keyboard.press('Enter');await menuReady();assert(!calls.some(c=>c.body.action==='moderate'),'temporary mock never sends real moderation requests');assert.match(await menu.locator('.session-detail').textContent(),/simulada/);
  await page.screenshot({path:'docs/evidence/trainer-player-test-'+width+'x'+height+'.png'});
  await page.keyboard.press('Backspace');await menuSelect('Jogador de teste');await menuSelect('Enviar aviso');await page.getByRole('textbox').fill('Aviso de teste');await page.keyboard.press('Enter');await menuReady();await page.keyboard.press('ArrowDown');await page.keyboard.press('Enter');await menuReady();assert(calls.some(c=>c.body.action==='moderate'&&c.body.data.target===72&&c.body.data.action==='warn'));
  await page.keyboard.press('Backspace');await page.keyboard.press('Backspace');await page.keyboard.press('Backspace');await menuReady();
  await menuSelect('Opções do veículo');await page.waitForFunction(()=>document.querySelector('.session-menu')?.getAttribute('data-page')==='vehicle');await page.keyboard.press('Backspace');await page.waitForFunction(()=>document.querySelector('.session-menu')?.getAttribute('data-page')==='root'&&document.querySelector('.session-menu')?.getAttribute('aria-busy')==='false');assert.match(await menu.locator('[aria-selected=true]').textContent(),/Opções do veículo/);await menuSelect('Jogadores');await page.waitForFunction(()=>document.querySelector('.session-menu')?.getAttribute('data-page')==='players'&&document.querySelector('.session-menu')?.getAttribute('aria-busy')==='false');await menuSelect('Buscar jogador');await page.getByRole('dialog',{name:'Buscar',exact:true}).waitFor();await page.getByRole('textbox',{name:'Buscar',exact:true}).fill('Jogador');await page.keyboard.press('Enter');await page.getByRole('dialog').waitFor({state:'detached'});assert.match(await menu.locator('.session-rows').textContent(),/Jogador de teste/);await page.keyboard.press('m');await menu.waitFor({state:'detached'});
  await page.evaluate(s=>window.postMessage({type:'workshop',state:s},'*'),state);
  await page.getByRole('button',{name:'JOGAR',exact:true}).waitFor();assert(!(await page.getByRole('button',{name:'JOGAR',exact:true}).isDisabled()));
  await page.getByRole('button',{name:'Personagem',exact:true}).click();await page.waitForFunction(()=>document.querySelector('.workshop')?.getAttribute('aria-busy')==='false');assert.equal(await page.getByRole('button',{name:'JOGAR',exact:true}).count(),0);await page.getByRole('button',{name:'Meu carro',exact:true}).click();await page.waitForFunction(()=>document.querySelector('.workshop')?.getAttribute('aria-busy')==='false');
  await page.evaluate(()=>window.dispatchEvent(new MessageEvent('message',{data:{type:'screenFade',active:true}})));assert(await page.locator('.loading-status').isHidden(),'native fade alone does not create a loading page');assert.equal(await page.locator('#root').evaluate(el=>getComputedStyle(el).visibility),'visible');await page.evaluate(()=>window.postMessage({type:'screenFade',active:false},'*'));
  await page.getByRole('button',{name:'Showroom',exact:true}).click();await page.locator('.heat-tile').first().waitFor();
  const strip=page.locator('.showroom-options');assert(await strip.evaluate(el=>{const width=el.style.width;el.style.width='180px';el.scrollLeft=0;el.dispatchEvent(new WheelEvent('wheel',{bubbles:true,cancelable:true,deltaY:160}));const moved=el.scrollLeft>0;el.style.width=width;el.scrollLeft=0;return moved;}),'mouse wheel scrolls showroom');await strip.locator('button').first().focus();await page.keyboard.press('ArrowLeft');assert(await strip.locator('button').last().evaluate(el=>el===document.activeElement));await page.keyboard.press('ArrowRight');assert(await strip.locator('button').first().evaluate(el=>el===document.activeElement));
  await page.locator('.heat-tile').nth(0).click();await page.locator('.heat-tile').nth(3).click();await page.getByRole('button',{name:'Usar este carro',exact:true}).waitFor();
  await page.screenshot({animations: 'disabled',path:`docs/evidence/heat-catalog-${width}x${height}.png`});
  assert.equal(await page.locator('.heat-search').count(),0,'no brand/filter toolbar');assert.equal(await page.getByRole('button',{name:'Marcas',exact:true}).count(),0);
  await page.keyboard.press('Escape');await page.locator('.showroom-options[aria-label=Marcas]').waitFor();await page.waitForFunction(()=>document.activeElement?.getAttribute('data-brand')==='JDM');await page.evaluate(()=>{document.activeElement?.blur();window.postMessage({type:'nav',key:'right'},'*');});
  await page.waitForFunction(()=>document.activeElement?.getAttribute('data-brand')==='JDM');await page.waitForFunction(()=>document.activeElement?.getAttribute('data-brand')==='JDM'&&getComputedStyle(document.activeElement).backgroundColor==='rgb(242, 246, 250)');const controllerBg=await page.locator('[data-brand=JDM]').evaluate(el=>getComputedStyle(el).backgroundColor);await page.keyboard.press('ArrowRight');await page.waitForFunction(()=>document.activeElement?.getAttribute('data-brand')==='OUTRA'&&getComputedStyle(document.activeElement).backgroundColor==='rgb(242, 246, 250)');const keyboardBg=await page.locator('[data-brand=OUTRA]').evaluate(el=>getComputedStyle(el).backgroundColor);assert.equal(controllerBg,keyboardBg,'controller and keyboard selection share actual computed style');assert.equal(controllerBg,'rgb(242, 246, 250)','selection must be white, not merely two equally unreadable dark backgrounds');assert.equal(await page.locator('[data-brand=OUTRA]').evaluate(el=>getComputedStyle(el).color),'rgb(17, 18, 21)','selected text has dark high-contrast ink');
  await page.keyboard.press('ArrowLeft');await page.evaluate(()=>window.postMessage({type:'nav',key:'enter'},'*'));await page.locator('[data-model=futo]').waitFor();assert.equal(await page.locator('[data-model=blista]').count(),0,'cached JDM view cannot include other brand models');
  await page.evaluate(()=>window.postMessage({type:'nav',key:'back'},'*'));await page.locator('[data-brand=OUTRA]').click();await page.getByText('Carregando modelos\u2026',{exact:true}).waitFor();assert.equal(await page.locator('[data-model]').count(),0,'old models are hidden during brand load');await page.locator('[data-model=blista]').waitFor();await page.waitForTimeout(400);assert.deepEqual(await page.locator('[data-model]').evaluateAll(nodes=>nodes.map(n=>n.dataset.model)),['blista'],'late JDM response cannot replace OUTRA models');
  await page.waitForFunction(()=>document.activeElement?.getAttribute('data-model')==='blista');await page.evaluate(()=>{document.activeElement?.blur();window.postMessage({type:'nav',key:'left'},'*');});await page.waitForFunction(()=>document.activeElement?.getAttribute('data-model')==='blista');await page.waitForFunction(()=>document.activeElement?.getAttribute('data-model')==='blista'&&getComputedStyle(document.activeElement).backgroundColor==='rgb(242, 246, 250)');assert.equal(await page.locator('[data-model=blista]').evaluate(el=>getComputedStyle(el).backgroundColor),keyboardBg,'first controller arrow selects model after mouse focus is lost');await page.screenshot({path:'docs/evidence/showroom-controller-'+width+'x'+height+'.png'});
  const entityCalls=()=>calls.filter(c=>c.action==='request'&&c.body.domain==='experience'&&['preview','resetPreview','cosmetic'].includes(c.body.action)).length;
  await page.getByRole('button',{name:'Meu carro',exact:true}).click();
  await page.waitForFunction(()=>document.querySelector('.workshop')?.getAttribute('data-screen')==='home'&&document.querySelector('.workshop')?.getAttribute('aria-busy')==='false');
  assert(calls.some(c=>c.body.action==='resetPreview'),'leaving unconfirmed showroom restores saved selection');

  await page.getByRole('button',{name:'Meu carro',exact:true}).click();await page.waitForFunction(()=>document.querySelector('.workshop')?.getAttribute('aria-busy')==='false');await page.keyboard.press('e');await page.waitForFunction(()=>document.querySelector('.workshop')?.getAttribute('data-screen')==='catalog');await page.waitForFunction(()=>document.querySelector('.workshop')?.getAttribute('aria-busy')==='false');await page.keyboard.press('q');await page.waitForFunction(()=>document.querySelector('.workshop')?.getAttribute('data-screen')==='home');
  await page.waitForFunction(()=>document.querySelector('.workshop')?.getAttribute('aria-busy')==='false');await page.waitForFunction(()=>document.querySelector('.workshop')?.getAttribute('aria-busy')==='false');await page.evaluate(()=>window.postMessage({type:'tabNav',direction:1},'*'));await page.waitForFunction(()=>document.querySelector('.workshop')?.getAttribute('data-screen')==='catalog');await page.waitForFunction(()=>document.querySelector('.workshop')?.getAttribute('aria-busy')==='false');await page.evaluate(()=>window.postMessage({type:'tabNav',direction:-1},'*'));await page.waitForFunction(()=>document.querySelector('.workshop')?.getAttribute('data-screen')==='home');
  await page.getByRole('button',{name:'Customiza\u00e7\u00e3o',exact:true}).focus();await page.evaluate(()=>window.postMessage({type:'nav',key:'up'},'*'));assert.equal(await page.evaluate(()=>!!document.activeElement?.closest('[data-tab-bar]')),false,'directional navigation excludes top tabs');
  assert.equal(await page.locator('.workshop-nav .tab-end').count(),2);
  const beforeTabs=entityCalls();
  for(let i=0;i<3;i++)for(const name of ['Meu carro','Showroom','Personagem'])await page.getByRole('button',{name,exact:true}).click();
  assert.equal(entityCalls(),beforeTabs,'tab navigation must never request preview/reset/cosmetic');
  assert.equal(await page.locator('.workshop-nav').evaluate(el=>getComputedStyle(el,'::-webkit-scrollbar').display),'none');
  await page.getByRole('button',{name:'Meu carro',exact:true}).click();await page.evaluate(()=>new Promise(resolve=>requestAnimationFrame(()=>requestAnimationFrame(resolve))));await page.getByRole('button',{name:'Meu carro',exact:true}).focus();const optionBackground=await page.getByRole('button',{name:'Customiza\u00e7\u00e3o',exact:true}).evaluate(el=>getComputedStyle(el).backgroundColor);await page.waitForFunction(()=>{const b=document.querySelectorAll('.heat-home-grid button');return b.length>2&&getComputedStyle(b[0]).backgroundColor===getComputedStyle(b[2]).backgroundColor;});const homeMetrics=await page.locator('.heat-home-grid button').evaluateAll(buttons=>buttons.map(b=>({w:b.offsetWidth,h:b.offsetHeight,bg:getComputedStyle(b).backgroundColor})));assert(homeMetrics.every(m=>Math.abs(m.w-homeMetrics[0].w)<1&&m.h===homeMetrics[0].h),'home buttons have equal dimensions');assert.equal(homeMetrics[0].bg,homeMetrics[2].bg,'unfocused Play uses shared option background');await page.screenshot({path:'docs/evidence/garage-home-refined-'+width+'x'+height+'.png'});await page.getByRole('button',{name:'Customização',exact:true}).click();


  const bar=page.locator('.heat-customization-bar');await bar.waitFor();
  await page.getByRole('button',{name:'DEV · CÂMERA',exact:true}).click();const cameraEditor=page.getByRole('dialog',{name:'Editor de câmera',exact:true});await cameraEditor.waitFor();
  const revBefore=calls.filter(c=>c.action==='experienceLocal'&&c.body.action==='engineRev').length;
  await page.locator('.camera-dev-drag').focus();await page.keyboard.down('w');await page.waitForTimeout(400);await page.keyboard.up('w');await page.waitForTimeout(100);
  assert(cameraFixture.position.x<134.98,'W moves along current camera heading at the precision default');assert.equal(calls.filter(c=>c.action==='experienceLocal'&&c.body.action==='engineRev').length,revBefore,'authoring W must not rev the presentation engine');
  await cameraEditor.getByLabel('X',{exact:true}).fill('136.25');await page.waitForFunction(()=>document.querySelector('.camera-dev input[aria-label="X"]')?.value==='136.25');
  await cameraEditor.getByLabel('Campo de visão').focus();await page.keyboard.press('Home');await page.waitForTimeout(100);
  await cameraEditor.getByRole('button',{name:'Capturar para copiar',exact:true}).click();const cameraText=cameraEditor.getByLabel('Configuração capturada',{exact:true});await cameraText.waitFor();assert.match(await cameraText.inputValue(),/x=136\.250/);assert.match(await cameraText.inputValue(),/fov=15\.00/);assert(await cameraText.getAttribute('readonly')!==null);
  await page.screenshot({path:`docs/evidence/camera-developer-${width}x${height}.png`});
  await cameraEditor.getByRole('button',{name:'Restaurar câmera inicial',exact:true}).click();await page.waitForFunction(()=>document.querySelector('.camera-dev input[aria-label="X"]')?.value==='135');
  await cameraEditor.getByRole('button',{name:'Restaurar e fechar',exact:true}).click();await cameraEditor.waitFor({state:'detached'});assert.equal(cameraFixture.fov,60,'closing with restore returns to starting FOV');
  async function ready(){await page.waitForFunction(()=>document.querySelector('.heat-customization-bar')?.getAttribute('aria-busy')==='false');}
  async function select(label){await ready();await page.keyboard.press('Home');await bar.locator('[aria-selected=true]').focus();for(let n=0;n<40;n++){if(await bar.locator('[aria-selected=true] strong').textContent()===label){await page.keyboard.press('Enter');await ready();return;}await page.keyboard.press('ArrowRight');}throw Error('Entry missing: '+label);}
  const saveCalls=()=>calls.filter(c=>c.body.action==='confirmCurrent');
  assert.equal(await bar.getByRole('option',{name:'Pintura & liveries',exact:true}).evaluate(el=>getComputedStyle(el).backgroundColor),optionBackground,'home and submenu options share opacity');
  assert((await bar.locator('.editor-control-hints .control-glyph').first().boundingBox()).width<=25);
  assert.deepEqual(await bar.locator('[role=option] strong').allTextContents(),['Pe\u00e7as e rodas','Pintura & liveries','Suspens\u00e3o','Iluminação & efeitos','Interior & detalhes']);
  assert.equal(await bar.locator('.option-counter').count(),0);assert.equal(await bar.locator('.preview-tools').count(),0);assert(await bar.getByRole('option').first().evaluate((el,width)=>{const r=el.getBoundingClientRect();return r.left+(r.width-el.offsetWidth)/2>=width*.039;},width),'strip keeps its layout inset independently of selection scale');assert.equal(await bar.locator('.editor-control-hint').count(),5);assert.equal(await bar.getByRole('button',{name:/Salv/}).count(),0);
  for(const [style,alt] of [['playstation','X'],['xbox','A']]){await page.evaluate(style=>window.postMessage({type:'workshopInputDevice',device:'gamepad',style},'*'),style);await page.waitForFunction(style=>document.querySelector('.heat-editor-actions .editor-control-hints')?.getAttribute('data-device')===style,style);assert.equal(await bar.locator('.editor-control-hints .control-glyph').first().getAttribute('alt'),alt);}
  await page.keyboard.press('ArrowRight');await page.keyboard.press('ArrowLeft');
  assert(await bar.locator('.editor-control-hints .control-glyph').first().evaluate(e=>e.complete&&e.naturalWidth>0));
  await page.screenshot({animations:'disabled',path:'docs/evidence/heat-editor-'+width+'x'+height+'.png'});
  const before=saveCalls().length;assert.equal(await page.getByRole('button',{name:'ADICIONAR NOVA CRIAÇÃO',exact:true}).count(),0);
  await select('Pe\u00e7as e rodas');await select('Para-choque traseiro');assert.equal(await bar.getAttribute('data-level'),'options:2');
  await bar.locator('[aria-selected=true]').focus();await page.keyboard.down('Escape');for(let n=0;n<5;n++)await page.keyboard.down('Escape');
  assert.equal(await bar.getAttribute('data-level'),'body','held keyboard back returns one level only');await page.keyboard.up('Escape');
  await select('Para-choque dianteiro');assert.equal(await bar.getAttribute('data-level'),'options:1');
  await page.evaluate(()=>window.postMessage({type:'workshopBack'},'*'));await page.waitForFunction(()=>document.querySelector('.heat-customization-bar')?.dataset.level==='body');
  await select('Rodas');await select('Sports / Esportivas');assert.equal(await bar.locator('.option-counter').count(),1);
  await page.keyboard.press('ArrowRight');await page.waitForTimeout(100);assert.equal(saveCalls().length,before,'highlight is preview only');
  await page.keyboard.press('Enter');await ready();assert.equal(saveCalls().length,before+1);assert.match(await bar.locator('[aria-selected=true]').textContent(),/APLICADO/);assert.equal(await bar.locator('[aria-selected=true] [aria-label=Equipado]').count(),1,'confirmed part has EQUIPADO badge');assert.equal(await bar.getAttribute('data-level'),'options:23','apply keeps editor open');const badge=bar.locator('[aria-selected=true] [aria-label=Equipado]');assert.equal(await badge.textContent(),'EQUIPADO');assert.equal(await badge.evaluate(el=>getComputedStyle(el).backgroundColor),'rgb(47, 180, 73)');assert.equal(await badge.evaluate(el=>getComputedStyle(el).color),'rgb(8, 12, 6)');await page.waitForFunction(()=>{const el=document.querySelector('.heat-customization-strip [aria-selected=true]');return el&&new DOMMatrix(getComputedStyle(el).transform).a>1.03;});await page.screenshot({path:'docs/evidence/equipped-badge-'+width+'x'+height+'.png'});
  // Check actual painted dimensions, including the disabled state used while applying a preview.
  const selectedTile=bar.locator('.heat-customization-strip [aria-selected=true]');
  await page.waitForFunction(()=>{const el=document.querySelector('.heat-customization-strip [aria-selected=true]');return el&&new DOMMatrix(getComputedStyle(el).transform).a>1.069;});
  const lift=await selectedTile.evaluate(el=>{
   const strip=el.parentElement.getBoundingClientRect(),box=el.getBoundingClientRect();
   return {ratio:box.width/el.offsetWidth,top:box.top-strip.top,bottom:strip.bottom-box.bottom};
  });
  assert(lift.ratio>1.06&&lift.top>=0&&lift.bottom>=0,'selection grows visibly without vertical clipping: '+JSON.stringify(lift));
  await selectedTile.evaluate(el=>{el.disabled=true;});
  await page.waitForTimeout(150);
  assert(await selectedTile.evaluate(el=>el.getBoundingClientRect().width/el.offsetWidth>1.06),'temporary loading must retain selection scale');
  await selectedTile.evaluate(el=>{el.disabled=false;});
  await bar.getByRole('option').nth(3).click();await ready();assert.equal(saveCalls().length,before+2);assert.equal(saveCalls().at(-1).body.data.properties.mods['23'],2,'mouse confirmation applies to session only');
  await page.keyboard.press('Backspace');await select('Track');await page.keyboard.press('Home');for(let i=0;i<25;i++)await page.keyboard.press('PageDown');await page.keyboard.press('ArrowRight');await page.waitForTimeout(900);
  assert(calls.some(c=>c.body.action==='cosmetic'&&c.body.data?.properties?.mods?.['23']===250));
  await page.screenshot({animations:'disabled',path:'docs/evidence/heat-wheel-options-'+width+'x'+height+'.png'});
  await page.keyboard.press('Home');for(let n=0;n<35;n++){await page.evaluate(()=>window.postMessage({type:'nav',key:'right'},'*'));await page.waitForFunction(n=>Array.from(document.querySelector('.heat-customization-strip').children).indexOf(document.querySelector('.heat-customization-strip [aria-selected=true]'))===n+1,n);}await page.waitForTimeout(400);const geometry=await bar.locator('.heat-customization-strip').evaluate(el=>{const b=el.getBoundingClientRect(),n=el.querySelector('[aria-selected=true]').getBoundingClientRect();return {error:Math.abs(n.left+n.width/2-b.left-b.width/2),scroll:el.scrollLeft};});assert(geometry.scroll>0&&geometry.error<4,'selected item stays on the viewport anchor: '+JSON.stringify(geometry));for(let n=34;n>=0;n--){await page.evaluate(()=>window.postMessage({type:'nav',key:'left'},'*'));}await page.waitForFunction(()=>document.querySelector('.heat-customization-strip [aria-selected=true] strong')?.textContent==='Original');await page.evaluate(()=>window.postMessage({type:'nav',key:'left'},'*'));assert.equal(await bar.locator('[aria-selected=true] strong').textContent(),'Op\u00e7\u00e3o 300','wrap from first to last');await page.keyboard.press('ArrowRight');assert.equal(await bar.locator('[aria-selected=true] strong').textContent(),'Original','wrap from last to first');
  const confirmed=saveCalls().length;await page.keyboard.press('Escape');assert.equal(saveCalls().length,confirmed,'back does not save highlighted wheel');
  await page.keyboard.press('c');await page.locator('.workshop-orbit-surface').waitFor();await page.mouse.move(width*.65,height*.3);await page.mouse.down();await page.mouse.move(width*.7,height*.33,{steps:3});await page.mouse.up();
  assert.equal(await bar.locator('.orbit-controls').count(),0);
  const actions=await bar.locator('.heat-editor-actions').boundingBox();const x=actions.x+actions.width*.75,y=actions.y+actions.height*.5;
  assert.equal(await page.evaluate(({x,y})=>document.elementFromPoint(x,y)?.className,{x,y}),'workshop-orbit-surface','transparent action row passes mouse to orbit surface');
  await page.mouse.move(x,y);await page.mouse.down();await page.mouse.move(x-40,y-20,{steps:3});await page.mouse.up();assert.equal(await page.evaluate(()=>getSelection()?.toString()),'');
  await page.mouse.wheel(0,-300);await page.waitForTimeout(100);assert(calls.some(c=>c.action==='experienceLocal'&&c.body.action==='orbitInput'&&c.body.zoom<0));
  assert.equal(await bar.getAttribute('data-free'),'false','orbit opens with editable options visible');assert.equal(await bar.locator('.heat-customization-strip').evaluate(el=>getComputedStyle(el).visibility),'visible');await page.keyboard.press('h');assert.equal(await bar.getAttribute('data-free'),'true');assert.equal(await bar.locator('.heat-customization-strip').evaluate(el=>getComputedStyle(el).visibility),'hidden','free inspection clears the option strip');assert.equal(await bar.locator('.heat-customization-path').evaluate(el=>getComputedStyle(el).visibility),'hidden','free inspection hides obstructing options');
  await page.screenshot({animations:'disabled',path:'docs/evidence/free-camera-ui-'+width+'x'+height+'.png'});await page.keyboard.press('h');assert.equal(await bar.getAttribute('data-free'),'false','H restores options without leaving orbit');
  await page.keyboard.press('c');
  await Promise.all([page.waitForResponse(r=>r.request().postDataJSON()?.action==='engineRev'&&r.request().postDataJSON()?.pressed===true),page.keyboard.down('w')]);await page.keyboard.up('w');
  await page.keyboard.press('Escape');await page.keyboard.press('Escape');
  await select('Suspens\u00e3o');assert.equal(await bar.locator('.stance-fields label').count(),5);assert.equal(await bar.getByRole('option',{name:'Rodas',exact:true}).count(),0);assert.equal(await bar.locator('.stance-panel button').count(),0);await Promise.all([page.waitForResponse(r=>r.request().postDataJSON()?.action==='stancePreview'),page.getByLabel('Altura',{exact:true}).fill('-0.04')]);
  await page.screenshot({animations:'disabled',path:'docs/evidence/stance-editor-'+width+'x'+height+'.png'});
  assert(calls.some(c=>c.action==='experienceLocal'&&c.body.action==='stancePreview'),'stance sliders use local preview transport');const stanceSaves=saveCalls().length;await page.keyboard.press('Enter');assert.equal(saveCalls().length,stanceSaves,'Enter on slider does not persist');
  await page.getByLabel('Cambagem dianteira',{exact:true}).fill('-4');await page.getByLabel('Cambagem dianteira',{exact:true}).dispatchEvent('pointerup');assert.equal(saveCalls().length,stanceSaves,'mouse release remains preview');
  await page.keyboard.press('Escape');await page.getByRole('dialog').waitFor();await page.screenshot({path:'docs/evidence/stance-review-'+width+'x'+height+'.png'});
  await page.evaluate(()=>window.postMessage({type:'nav',key:'back'},'*'));await page.getByRole('dialog').waitFor({state:'detached'});assert.equal(await page.getByLabel('Altura',{exact:true}).inputValue(),'-0.04','cancel review preserves editing');
  await page.evaluate(()=>window.postMessage({type:'nav',key:'back'},'*'));await page.getByRole('dialog').waitFor();await page.evaluate(()=>window.postMessage({type:'nav',key:'enter'},'*'));await page.getByRole('dialog').waitFor({state:'detached'});await ready();assert.equal(savedProperties.get(state.current.id).stance.height,-.04);assert.equal(savedProperties.get(state.current.id).stance.frontCamber,-4);
  resizeCase=true;await select('Suspensão');await page.getByLabel('Altura',{exact:true}).fill('-0.045');
  const diameter=page.getByLabel('Diâmetro da roda',{exact:true});await diameter.waitFor();await diameter.fill('1.1');
  await page.waitForFunction(()=>document.querySelector('input[aria-label="Diâmetro da roda"]')?.disabled===true);
  assert.equal(await diameter.inputValue(),'1','refused diameter is reset to acknowledged geometry');
  assert.match(await bar.getByRole('status').textContent(),/Diâmetro indisponível/);
  assert.equal(await page.getByLabel('Altura',{exact:true}).inputValue(),'-0.045','other stance adjustments survive diameter refusal');
  await page.getByLabel('Largura da roda',{exact:true}).fill('1.1');
  await page.waitForTimeout(800);await page.screenshot({path:'docs/evidence/stance-size-fallback-'+width+'x'+height+'.png'});
  await page.keyboard.press('Escape');await page.getByRole('dialog').waitFor();await page.getByRole('button',{name:'Manter alterações',exact:true}).click();await ready();
  assert.equal(savedProperties.get(state.current.id).stance.wheelSize,1,'commit does not persist refused diameter');
  assert.equal(savedProperties.get(state.current.id).stance.wheelWidth,1.1,'other accepted wheel dimension remains persistent');
  resizeCase=false;sizeBlocked=false;
  const confirmedStanceHeight=savedProperties.get(state.current.id).stance.height;
  await select('Suspens\u00e3o');await page.getByLabel('Altura',{exact:true}).fill('0.08');await page.keyboard.press('Escape');await page.getByRole('dialog').waitFor();await page.getByRole('button',{name:'Restaurar anterior',exact:true}).click();await page.getByRole('dialog').waitFor({state:'detached'});await ready();assert.equal(savedProperties.get(state.current.id).stance.height,confirmedStanceHeight,'reset keeps last confirmed configuration');assert.equal(shown.stance.height,confirmedStanceHeight,'reset restores visible preview');
  await select('Suspens\u00e3o');
  await page.keyboard.press('Escape');await select('Pintura & liveries');await select('Pintura');await page.locator('.vehicle-color-panel').waitFor();assert.equal(await bar.locator('.heat-customization-strip').count(),0);const n=await page.locator('.color-grid [aria-selected=true]').evaluate(el=>Array.from(el.parentElement.children).indexOf(el));await page.evaluate(()=>window.postMessage({type:'nav',key:'right'},'*'));await page.waitForFunction(n=>Array.from(document.querySelector('.color-grid').children).indexOf(document.querySelector('.color-grid [aria-selected=true]'))===n+1,n);await page.keyboard.press('Enter');await ready();assert.equal(saveCalls().at(-1).body.data.properties.primary,1);await page.getByLabel('R',{exact:true}).fill('20');await page.getByLabel('G',{exact:true}).fill('30');await page.getByLabel('B',{exact:true}).fill('40');await page.keyboard.press('Enter');await ready();assert.deepEqual(saveCalls().at(-1).body.data.properties.customPrimary,[20,30,40]);await page.screenshot({animations:'disabled',path:'docs/evidence/color-panel-'+width+'x'+height+'.png'});
  await page.keyboard.press('Escape');await page.keyboard.press('Escape');await select('Interior & detalhes');await select('Texto da placa');await page.getByLabel('Texto da placa',{exact:true}).fill('MX TEST');
  const durableCalls=saveCalls;loseNextSave=true;await page.keyboard.press('Enter');await page.locator('.workshop-error').waitFor();await ready();const operation=durableCalls().at(-1).body.data.operation;await page.getByRole('button',{name:'Tentar novamente',exact:true}).click();await ready();assert.equal(durableCalls().at(-1).body.data.operation,operation);assert.equal(savedProperties.get(garage[0].id).plate,'MX TEST');
  await page.keyboard.press('Escape');await page.keyboard.press('Escape');await page.keyboard.press('Escape');await page.keyboard.press('Escape');await page.getByRole('button',{name:'JOGAR',exact:true}).waitFor();assert.equal(await page.locator('.workshop-modal').count(),0,'confirmed pieces never trigger save/discard prompt');
  await page.getByRole('button',{name:'Customiza\u00e7\u00e3o',exact:true}).click();await bar.waitFor();await select('Interior & detalhes');await select('Texto da placa');assert.equal(await page.getByLabel('Texto da placa',{exact:true}).inputValue(),'MX TEST','reopening restores fixture persisted selection');
  assert(await page.evaluate(()=>document.fonts.check('italic 800 20px Barlow')));
  for(let n=0;n<4;n++)await page.keyboard.press('Escape');await page.getByRole('button',{name:'JOGAR',exact:true}).waitFor();
  await page.getByRole('button',{name:'Showroom',exact:true}).click();await page.locator('.heat-strip[aria-label=Marcas] button').first().click();await page.locator('.heat-strip[aria-label="Modelos dispon\u00edveis"] button').first().click();await page.getByRole('button',{name:'Usar este carro',exact:true}).click();await page.getByRole('button',{name:'JOGAR',exact:true}).waitFor();assert(state.current.id,'explicit use persists the chosen creation');
  await page.getByRole('button',{name:'Customiza\u00e7\u00e3o',exact:true}).click();await select('Pintura & liveries');await select('Pintura');await page.getByLabel('R',{exact:true}).fill('123');await page.keyboard.press('Enter');await ready();const newId=state.current.id;assert.equal(savedProperties.get(newId).customPrimary[0],123);assert.equal(await bar.getAttribute('data-level'),'paint','confirmation preserves colour panel');
  await page.getByLabel('R',{exact:true}).fill('22');for(let n=0;n<4;n++)await page.keyboard.press('Escape');await page.getByRole('button',{name:'JOGAR',exact:true}).waitFor();assert.equal(savedProperties.get(newId).customPrimary[0],123,'unconfirmed colour is not persisted');assert.equal(shown.customPrimary[0],123,'back restores confirmed baseline');
  await page.getByRole('button',{name:'Carros salvos',exact:true}).click();assert.equal(await page.getByRole('button',{name:'VOLTAR',exact:true}).count(),0,'saved cars has shortcut only');
  const savedStrip=page.locator('.option-strip[aria-label="Cria\u00e7\u00f5es salvas"]');
  await savedStrip.waitFor();await savedStrip.locator('button:not(:disabled)').first().waitFor();
  assert.equal(await savedStrip.locator('.equipped-badge').count(),1,'only the car in use has the equipped badge');
  assert.equal(await savedStrip.locator('button.selected').count(),0,'saved records do not create a second navigation selection');
  const equippedCar=savedStrip.locator('button').filter({has:page.locator('[aria-label=Equipado]')});
  const otherCar=savedStrip.locator('button').filter({hasNot:page.locator('[aria-label=Equipado]')}).first();
  await otherCar.focus();
  await page.waitForFunction(el=>getComputedStyle(el).backgroundColor==='rgb(242, 246, 250)',await otherCar.elementHandle());
  assert.equal(await otherCar.evaluate(el=>getComputedStyle(el).backgroundColor),'rgb(242, 246, 250)');
  assert.notEqual(await equippedCar.evaluate(el=>getComputedStyle(el).backgroundColor),'rgb(242, 246, 250)','car in use is not highlighted when another car has focus');
  assert.equal(await equippedCar.locator('[aria-label=Equipado]').evaluate(el=>getComputedStyle(el).backgroundColor),'rgb(47, 180, 73)');
  await page.screenshot({path:'docs/evidence/saved-cars-equipped-'+width+'x'+height+'.png'});

await page.getByRole('button',{name:'Excluir',exact:true}).click();await page.getByRole('dialog').waitFor();await page.evaluate(()=>window.postMessage({type:'nav',key:'down'},'*'));await page.waitForFunction(()=>document.querySelector('.confirm-actions .selected')?.textContent==='Manter');await page.evaluate(()=>window.postMessage({type:'nav',key:'up'},'*'));await page.waitForFunction(()=>document.querySelector('.confirm-actions .selected')?.textContent==='Excluir');await page.evaluate(()=>window.postMessage({type:'nav',key:'down'},'*'));await page.screenshot({animations:'disabled',path:'docs/evidence/confirm-modal-'+width+'x'+height+'.png'});await page.evaluate(()=>window.postMessage({type:'nav',key:'enter'},'*'));await page.getByRole('dialog').waitFor({state:'detached'});
  await page.getByRole('button',{name:'Meu carro',exact:true}).click();await page.getByRole('button',{name:'Customiza\u00e7\u00e3o',exact:true}).click();await select('Pe\u00e7as e rodas');await select('Rodas');await select('Sports / Esportivas');delayNextCosmetic=true;await page.keyboard.press('ArrowRight');await page.waitForFunction(()=>document.querySelector('.heat-customization-strip [aria-selected=true] strong')?.textContent!=='Original');await page.waitForTimeout(40);for(const level of ['families','body','root','closed']){await page.evaluate(()=>window.postMessage({type:'workshopBack'},'*'));await page.waitForFunction(level=>level==='closed'?!document.querySelector('.heat-customization-bar'):document.querySelector('.heat-customization-bar')?.getAttribute('data-level')===level,level);}await page.getByRole('button',{name:'JOGAR',exact:true}).waitFor();assert.equal(invalidatedDuringCosmetic,false,'controller exit waits cosmetic queue before publishing model invalidation');assert.equal(await page.locator('.workshop-error').count(),0,'keyboard to controller back has no OBSOLETE error');
  await page.getByRole('button',{name:'Customiza\u00e7\u00e3o',exact:true}).click();await select('Iluminação & efeitos');await select('Faróis');await select('Cor dos far\u00f3is');assert(calls.some(c=>c.body.action==='previewLights'&&c.body.enabled===true));await Promise.all([page.waitForResponse(r=>r.request().postDataJSON()?.action==='previewNight'&&r.request().postDataJSON()?.enabled===true),page.keyboard.press('s')]);assert(calls.some(c=>c.body.action==='previewNight'&&c.body.enabled===true));assert.equal(await page.locator('.color-grid small').count(),0);await page.locator('.color-grid button').nth(2).click();await ready();assert.equal(saveCalls().at(-1).body.data.properties.xenonColor,2);assert.equal(saveCalls().at(-1).body.data.properties.xenon,true,'light colour confirmation enables xenon');await page.getByLabel('R',{exact:true}).fill('80');await page.getByLabel('G',{exact:true}).fill('120');await page.getByLabel('B',{exact:true}).fill('200');await page.keyboard.press('Enter');await ready();assert.deepEqual(saveCalls().at(-1).body.data.properties.xenonCustom,[80,120,200]);await page.screenshot({path:`docs/evidence/headlight-color-${width}x${height}.png`});await page.keyboard.press('Escape');await page.keyboard.press('Escape');await select('Neons');const savedBeforeNeon=saveCalls().length;await select('Cor do neon');await page.getByLabel('R',{exact:true}).fill('30');await page.getByLabel('G',{exact:true}).fill('70');await page.getByLabel('B',{exact:true}).fill('160');await page.waitForTimeout(100);assert(calls.some(c=>c.body.action==='previewNeon'&&c.body.enabled&&c.body.color?.[0]===30));assert.equal(saveCalls().length,savedBeforeNeon,'neon viewing does not persist layout');await page.keyboard.press('Enter');await ready();assert.deepEqual(saveCalls().at(-1).body.data.properties.neonColor,[30,70,160]);assert.deepEqual(saveCalls().at(-1).body.data.properties.neon,[false,false,false,false],'confirm colour preserves saved layout');await page.keyboard.press('Escape');await select('Layout do neon');await select('Todos os neons');assert.equal(await bar.getByRole('option',{name:/Todos os neons/}).locator('[aria-label=Equipado]').count(),1);await page.screenshot({path:`docs/evidence/neon-toggles-${width}x${height}.png`});for(let n=0;n<4;n++)await page.keyboard.press('Escape');await page.getByRole('button',{name:'JOGAR',exact:true}).waitFor();assert(calls.some(c=>c.body.action==='previewLights'&&c.body.enabled===false));
  state.current.properties.extras['9']=true;await page.getByRole('button',{name:'Customiza\u00e7\u00e3o',exact:true}).click();await select('Interior & detalhes');await select('Extras');await select('Extra 9');assert.equal(savedProperties.get(state.current.id).extras['9'],false);assert(await bar.getByRole('option',{name:/Extra 9/}).isDisabled(),'unavailable saved extra can be disabled but not enabled');await select('Extra 1');assert.equal(savedProperties.get(state.current.id).extras['1'],true);assert.equal(await bar.getByRole('option',{name:/Extra 1/}).locator('[aria-label=Equipado]').count(),1);const previewCount=calls.filter(c=>c.body.action==='cosmetic').length;await page.keyboard.press('ArrowRight');await page.waitForTimeout(250);assert.equal(calls.filter(c=>c.body.action==='cosmetic').length,previewCount,'highlighting a toggle never applies it');await bar.getByRole('option',{name:/Extra 1/}).click();await ready();assert.equal(savedProperties.get(state.current.id).extras['1'],false);for(let n=0;n<3;n++)await page.keyboard.press('Escape');await page.getByRole('button',{name:'JOGAR',exact:true}).waitFor();
  await page.getByRole('button',{name:'Customiza\u00e7\u00e3o',exact:true}).click();await bar.waitFor();await page.keyboard.press('c');await page.locator('.workshop-orbit-surface').waitFor();
  await select('Pe\u00e7as e rodas');await select('Para-choque dianteiro');const toggles=calls.filter(c=>c.body.action==='freeCamera').length;
  await page.evaluate(()=>window.postMessage({type:'nav',key:'back'},'*'));await page.waitForFunction(()=>document.querySelector('.heat-customization-bar')?.dataset.level==='body');assert.equal(await page.locator('.workshop-orbit-surface').count(),1,'controller back navigates without disabling orbit');
  await page.keyboard.press('Escape');assert.equal(await bar.getAttribute('data-level'),'root');assert.equal(calls.filter(c=>c.body.action==='freeCamera').length,toggles,'back does not send camera toggle');
  await select('Suspens\u00e3o');await page.getByLabel('Altura',{exact:true}).focus();await page.keyboard.press('c');await page.locator('.workshop-orbit-surface').waitFor({state:'detached'});await page.keyboard.press('c');await page.locator('.workshop-orbit-surface').waitFor();
  await page.keyboard.press('Escape');assert.equal(await bar.getAttribute('data-level'),'root');assert.equal(await page.locator('.workshop-orbit-surface').count(),1,'orbit survives stance back');
  const orbitCalls=calls.filter(c=>c.body.action==='orbitInput').length;await page.mouse.move(width*.65,height*.3);await page.mouse.down();await page.evaluate(({x,y})=>{const el=document.querySelector('.workshop-orbit-surface');for(let i=1;i<=30;i++)el.dispatchEvent(new PointerEvent('pointermove',{pointerId:1,clientX:x+i*7,clientY:y,buttons:1,bubbles:true}));},{x:width*.65,y:height*.3});await page.waitForTimeout(40);await page.mouse.up();await page.waitForTimeout(120);
  const burst=calls.filter(c=>c.body.action==='orbitInput').slice(orbitCalls);assert(burst.length>0&&burst.length<=4,'pointer bursts are coalesced per animation frame');assert(burst.filter(c=>!c.body.stop).every(c=>Math.abs(c.body.yaw??0)<=.3&&Math.abs(c.body.pitch??0)<=.15),'each fast-drag frame respects native input bounds; no assumption about browser-generated pointer corrections');
  assert.equal(burst.at(-1).body.stop,true,'release sends ordered cancellation');const afterStop=calls.filter(c=>c.body.action==='orbitInput').length;await page.waitForTimeout(150);assert.equal(calls.filter(c=>c.body.action==='orbitInput').length,afterStop,'no queued drag packets after release');
  await page.mouse.move(width*.65,height*.3);await page.mouse.down();await page.evaluate(()=>window.dispatchEvent(new Event('blur')));await page.mouse.up();await page.waitForTimeout(60);assert.equal(calls.filter(c=>c.body.action==='orbitInput').at(-1).body.stop,true,'blur cancels drag');
  await page.mouse.move(width*.65,height*.3);await page.mouse.down();await page.mouse.move(width-1,height*.3);await page.waitForTimeout(60);await page.mouse.up();assert.equal(calls.filter(c=>c.body.action==='orbitInput').at(-1).body.stop,true,'viewport edge cancels drag');
  const beforeDoors=calls.filter(c=>c.body.action==='doors').length;await page.keyboard.press('Space');await page.evaluate(()=>window.postMessage({type:'nav',key:'doors'},'*'));await page.waitForTimeout(60);assert.equal(calls.filter(c=>c.body.action==='doors').length,beforeDoors+2,'keyboard and controller door shortcuts share action');
  await page.keyboard.press('Escape');await page.getByRole('button',{name:'JOGAR',exact:true}).waitFor();assert.equal(await page.locator('.workshop-orbit-surface').count(),0,'leaving editor removes manual camera surface');await page.waitForFunction(()=>!document.querySelector('.heat-customization-bar'));assert.equal(orbital,false,'editor cleanup requests camera release');
  await page.evaluate(()=>window.postMessage({type:'workshop',state:false},'*'));await page.locator('.workshop').waitFor({state:'detached'});
  assert.deepEqual(errors,[]);report.push({width,height,keyboardHierarchy:true,selectionRestored:true,leftRightValues:true,autoScroll:true,backAndEscape:true,keyboardAndMouse:true,showroomKeyedBrandResults:true,showroomLateResponseIgnored:true,showroomNoFilterToolbar:true,controllerFocusFromBody:true,controllerFocusStyleMatchesKeyboard:true,workshopEntryKeyboardAndControllerHint:true,localFonts:true,garageRecordEditing:true,nativePieceLabels:true,wheelIndex250:true,wheelFamilyReset:true,partCameraRequests:true,bottomHierarchy:true,compactRgbAndText:true,unconfirmedPreviewNotSaved:true,temporaryPreviewDistinctFromDraft:true,orbitPreservesSelection:true,revKeyContracts:true,freeCameraC:true,mouseOrbit:true,orbitPersistsAcrossSubmenus:true,orbitAvailableOnSliders:true,orbitReleasedOnEditorExit:true,orbitPointerBatching:true,orbitNoResidualQueue:true,orbitBlurAndEdgeCancel:true,doorShortcuts:true,vehicleOptions:true,vehicleDoorSelector:true,vehicleRemoteEngine:true,vehicleContextDisabled:true,driftToggle:true,respawnConfirmation:true,uniformHomeButtons:true,savedCarsNoBackButton:true,mouseParts:true,stanceSliders:true,confirmPersistsSameIdentity:true,colorPanel:true,confirmationModalNoSkippedOptions:true,keyboardToControllerBackQueue:true,nightAndLightsPreviewContracts:true,neonNestedColorAndLayout:true,headlightIndexedAndRgb:true,neonPreviewDoesNotPersistLayout:true,groupedToggles:true,paintTabsAndMergedRgb:true,stanceWithoutButtons:true,stanceExitReview:true,stanceResetAndCancel:true,heldBackSingleLevel:true,equippedPieceCheck:true,previewRatePaced:true,mouseColorConfirms:true,confirmationPreservesColorPanel:true,backRestoresConfirmedSnapshot:true,applyIncludesInlineField:true,mouseTextDialog:true,noCameraOnHighlight:true,hiddenScrollbars:true,presentationFixturesOnly:true,gameClients:0,jsErrors:0});await page.close();
 }
 await writeFile('docs/evidence/ui.json',JSON.stringify(report,null,2));console.log('Browser: menu por teclado, submenus, seleção preservada, valores ←→, rolagem, retorno/Esc e composição Heat em 4 resoluções. Fixtures de UI; não valida natives ou entidades FiveM.');
}finally{await browser.close();await new Promise(resolve=>server.close(resolve));}

