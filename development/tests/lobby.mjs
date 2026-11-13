import '../scripts/workspace.mjs';
import {chromium} from 'playwright';
import {createServer} from 'node:http';
import {readFile,mkdir,writeFile} from 'node:fs/promises';
import path from 'node:path';
import assert from 'node:assert/strict';
const root=path.resolve('resources/[mx]/mx-freeroam-menu');
const server=createServer(async(req,res)=>{try{const file=path.resolve(root,'.'+decodeURIComponent(req.url==='/'?'/dist/index.html':req.url.startsWith('/fonts/')?'/dist'+req.url.split('?')[0]:req.url.split('?')[0]));if(!file.startsWith(root+path.sep)){res.writeHead(403).end();return;}res.setHeader('Content-Type',file.endsWith('.js')?'application/javascript':file.endsWith('.css')?'text/css':file.endsWith('.ttf')?'font/ttf':'text/html');res.end(await readFile(file));}catch{res.writeHead(404).end();}});
await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));
const browser=await chromium.launch({executablePath:process.env.MX_CHROMIUM,headless:true});
const reports=[];
const appearance={version:1,model:'mp_m_freemode_01',shapeFirst:0,shapeSecond:21,skinFirst:0,skinSecond:21,shapeMix:.5,skinMix:.5,features:Array(20).fill(0),overlays:Array.from({length:13},()=>({index:-1,opacity:1,color:1})),hairColor:1,hairHighlight:1,eyeColor:0,components:Array.from({length:12},()=>({drawable:0,texture:0})),props:Array.from({length:8},()=>({drawable:-1,texture:0}))};
try{
 await mkdir('docs/evidence',{recursive:true});
 for(const [width,height] of [[1280,720],[1920,1080],[2560,1440],[3440,1440]]){
  const page=await browser.newPage({viewport:{width,height}}),errors=[],calls=[];page.on('pageerror',e=>errors.push(e.message));
  page.setDefaultTimeout(12000);const baseURL=`http://127.0.0.1:${server.address().port}`;
  await page.goto(baseURL+'/loadscreen/index.html');
  assert.equal(await page.locator('body').evaluate(e=>getComputedStyle(e).backgroundColor),'rgb(0, 0, 0)');
  await page.evaluate(()=>window.postMessage({eventName:'loadProgress',loadFraction:.42},'*'));await page.getByText('Recursos 42%',{exact:true}).waitFor();
  assert.equal(await page.locator('progress').getAttribute('value'),'0.42');
  await page.evaluate(()=>window.postMessage({eventName:'loadProgress',loadFraction:1},'*'));await page.getByText('Preparando seu acesso…',{exact:true}).waitFor();
  assert.equal(await page.locator('progress').getAttribute('value'),null,'resource completion cannot claim full access is ready');
  await page.screenshot({path:`docs/evidence/loading-${width}x${height}.png`,animations:'disabled'});
  await page.evaluate(()=>window.postMessage({eventName:'mxStage',error:true,message:'Perfil indisponível'},'*'));await page.getByText('Perfil indisponível',{exact:true}).waitFor();assert.match(await page.locator('#help').textContent(),/Reconecte/);
  await page.addInitScript(()=>window.GetParentResourceName=()=> 'mx-freeroam-menu');
  let current={phase:'character',token:'BROWSER-CONTRACT-FIXTURE',revision:1,appearanceRevision:0,appearance,characterCompleted:false,vehicleCompleted:false,garage:[],selected:null};
  let lostAddResponse=true;
  let social={online:[{id:72,name:'Jogador online'}],friends:[],incoming:[{id:73,name:'Solicitante'}],outgoing:[]};
  const lobby={generation:1,resume:false};
  const post=(type,data)=>page.evaluate(({type,data})=>window.postMessage({type,...data},'*'),{type,data});
  await page.route('https://mx-freeroam-menu/**',async route=>{
   const action=new URL(route.request().url()).pathname.slice(1),body=route.request().postDataJSON()??{};calls.push({action,body});let data={},ok=true;
   if(action==='openGarage'){await post('workshop',{state:current});data=current;}
   else if(action==='experienceLocal'){
    if(body.action==='camera')await new Promise(resolve=>setTimeout(resolve,400));
    if(body.action==='lobby')await post('lobby',{data:lobby});
    else if(body.action==='resume')await post('lobby',{data:false});
    else if(body.action==='capabilities')data={capabilities:{components:[],props:[],overlays:[]}};
    else if(body.action==='preferences')data={reduceMotion:false};
    else if(body.action==='drivecam')data={enabled:false};
   }else if(action==='navigationContext'){await route.fulfill({status:200,contentType:'application/json',body:JSON.stringify({ok:true,data:{}})});return;}else if(action==='request'){
    if(body.domain==='experience'){
     if(body.action==='character'){current={...current,phase:current.vehicleCompleted?(current.selected?'workshop':'empty'):'firstCar',characterCompleted:true,appearanceRevision:1,revision:2};data={state:current};}
     else if(body.action==='garage'){const selected={id:body.data.id,model:'futo',name:body.data.name,revision:1,available:true};current={...current,phase:'workshop',vehicleCompleted:true,garage:[selected],selected,revision:3};data={state:current};if(lostAddResponse){lostAddResponse=false;ok=false;}} 
     else if(body.action==='resetPreview')data={state:current};
     else if(body.action==='preview')data={id:'managed-preview-fixture',model:'futo',properties:{},capabilities:{}};
     else if(body.action==='state')data=current;
     else ok=false;
    }else if(body.domain==='vehicles'&&body.action==='catalogBrands')data=['Coupe'];
    else if(body.domain==='vehicles'&&body.action==='catalog')data=[{id:'futo',name:'Karin Futo',category:'Coupe',available:true}];
    else if(body.domain==='core'&&body.action==='profile')data={name:'Browser',revision:1,preferences:{hud:true,units:'kmh',scale:1,volume:.3}};
    else if(body.domain==='social'){
     if(body.action==='friends')data=social;
     else if(body.action==='friendSend'){social={...social,online:[{id:72,name:'Jogador online',relation:'outgoing'}],outgoing:[{id:72,name:'Jogador online'}]};data={status:'pending'};}
     else if(body.action==='friendRespond'){social={...social,incoming:[],friends:body.data.accept?[{id:73,name:'Solicitante',online:false}]:[]};data={status:'accepted'};}
     else ok=false;
    }else ok=false;
   }else if(!['previewIntent','lobbyReady','navigationContext'].includes(action))ok=false;
   await route.fulfill({status:200,headers:{'Access-Control-Allow-Origin':'*'},contentType:'application/json',body:JSON.stringify(ok?{ok:true,data}:{ok:false,code:'FIXTURE',message:'Contrato não previsto'})});
  });
  await page.goto(baseURL+'/dist/index.html');await page.evaluate(()=>document.body.style.background='#292b30');await page.evaluate(()=>document.fonts.ready);
  await post('lobby',{data:{...lobby,initialLoading:true}});await page.locator('.lobby').waitFor({state:'attached'});
  assert.equal(await page.locator('.screen-transition').evaluate(e=>getComputedStyle(e).opacity),'1','loading handoff stays black until native shutdown');
  assert.equal(await page.locator('#root').evaluate(e=>getComputedStyle(e).visibility),'hidden','loading keeps the mounted interface invisible');
  if(width===1280)await page.screenshot({path:'docs/evidence/interface-hidden-loading-1280x720.png'});
  const opens=calls.filter(c=>c.action==='openGarage').length;
  await post('nav',{key:'enter'});await page.keyboard.press('Enter');
  await page.locator('.lobby [data-initial]').evaluate(e=>e.click());
  assert.equal(calls.filter(c=>c.action==='openGarage').length,opens,'hidden interface ignores gamepad, keyboard and synthetic click');
  await post('screenFade',{active:true});
  await post('loadingClosed',{});
  await page.waitForFunction(()=>getComputedStyle(document.querySelector('.screen-transition')).opacity==='0');
  assert.equal(await page.locator('#root').evaluate(e=>getComputedStyle(e).visibility),'hidden','native fade keeps NUI hidden after loading veil ends');
  await post('screenFade',{active:false});
  await page.getByRole('button',{name:'Garagem',exact:true}).waitFor();await page.waitForFunction(()=>document.activeElement?.textContent==='Garagem');
  const mounted=await page.locator('.lobby').elementHandle();
  await post('screenFade',{active:true});await post('screenFade',{active:false});
  assert(await mounted.evaluate(e=>e.isConnected),'native fades never unmount or reset the screen');
  const box=await page.locator('.lobby').boundingBox();assert.deepEqual(box,{x:0,y:0,width,height});assert.equal(await page.locator('.lobby').evaluate(e=>getComputedStyle(e).backgroundColor),'rgba(0, 0, 0, 0)');
  assert.equal(await page.locator('.lobby nav,.workshop').count(),0);assert(await page.getByRole('button',{name:/Criar grupo/}).isDisabled());assert(await page.getByRole('button',{name:/Loja/}).isDisabled());assert(await page.getByRole('button',{name:/Discord/}).isDisabled());
  await page.screenshot({path:`docs/evidence/lobby-${width}x${height}.png`,animations:'disabled'});
  await post('lobby',{data:{...lobby,sceneReady:false,error:'Entrada inicial indisponível'}});
  await page.getByRole('button',{name:'Tentar novamente',exact:true}).waitFor();
  await page.waitForFunction(()=>document.activeElement?.textContent==='Tentar novamente');
  assert.equal(await page.locator('.lobby').evaluate(e=>getComputedStyle(e).backgroundColor),'rgb(8, 10, 13)','failed initial preparation cannot expose the public world');
  assert(await page.getByRole('button',{name:'Garagem',exact:true}).isEnabled());
  await page.screenshot({path:`docs/evidence/lobby-entry-error-${width}x${height}.png`,animations:'disabled'});
  await page.keyboard.press('Enter');await page.getByRole('button',{name:'Garagem',exact:true}).waitFor({state:'visible'});
  await page.waitForFunction(()=>document.activeElement?.textContent==='Garagem');
  assert.equal(await page.locator('.lobby').evaluate(e=>getComputedStyle(e).backgroundColor),'rgba(0, 0, 0, 0)','successful retry restores the scene presentation');
  await page.keyboard.press('ArrowRight');assert.equal(await page.evaluate(()=>document.activeElement.textContent),'Configurações');await page.keyboard.press('Enter');await page.getByLabel('Velocímetro',{exact:true}).waitFor();await page.getByLabel('Unidades',{exact:true}).focus();await post('nav',{key:'right'});await page.waitForFunction(()=>document.querySelector('select[aria-label=Unidades]')?.value==='mph');await page.screenshot({path:`docs/evidence/settings-${width}x${height}.png`,animations:'disabled'});await page.keyboard.press('Escape');await page.getByRole('button',{name:'Garagem',exact:true}).waitFor();
  await page.getByRole('button',{name:'Jogadores e amigos',exact:true}).click();await page.getByRole('button',{name:'Adicionar amigo'}).click();await page.getByText('Solicitação enviada',{exact:true}).waitFor();await page.getByRole('button',{name:'Solicitações recebidas',exact:true}).click();await page.getByRole('button',{name:'Aceitar',exact:true}).click();await page.getByRole('button',{name:'Amigos',exact:true}).click();await page.getByText('Offline',{exact:true}).waitFor();await page.keyboard.press('Escape');
  await page.getByRole('button',{name:'Garagem',exact:true}).click();await page.getByRole('button',{name:'Confirmar personagem',exact:true}).waitFor();assert.equal(await page.locator('.workshop-nav').count(),0);assert.equal(calls.filter(c=>c.body.action==='character').length,0);
  await page.getByRole('button',{name:'VOLTAR',exact:true}).click();await page.getByRole('button',{name:'Garagem',exact:true}).click();await page.getByRole('button',{name:'Confirmar personagem',exact:true}).click();await page.getByRole('button',{name:'Coupe',exact:true}).waitFor();
  assert.equal(calls.filter(c=>c.body.action==='character').length,1);assert.equal(await page.locator('.workshop-nav').count(),0);
  await page.getByRole('button',{name:'VOLTAR',exact:true}).click();await page.getByRole('button',{name:'Garagem',exact:true}).click();await page.locator('.heat-tile').first().click();await page.locator('.heat-tile').first().click();await page.getByRole('button',{name:'Escolher este carro',exact:true}).click();await page.locator('.workshop-error').waitFor();await page.getByRole('button',{name:'Escolher este carro',exact:true}).click();assert.equal(calls.filter(c=>c.body.action==='garage'&&c.body.data?.action==='add').length,1,'primary confirmation cannot start a second uncertain save');await page.getByRole('button',{name:'Tentar novamente',exact:true}).click();await page.getByRole('button',{name:'JOGAR',exact:true}).waitFor();
  const adds=calls.filter(c=>c.body.action==='garage'&&c.body.data?.action==='add');assert.equal(adds.length,2);assert.equal(adds[0].body.data.id,adds[1].body.data.id);assert.equal(adds[0].body.data.operation,adds[1].body.data.operation);
  assert.deepEqual(await page.locator('.workshop-nav button').allTextContents(),['Meu carro','Personagem','Showroom','Ranking']);
  const layoutBox=async node=>node.evaluate(el=>{const r=el.getBoundingClientRect();return {x:r.left+r.width/2-el.offsetWidth/2,y:r.top+r.height/2-el.offsetHeight/2,width:el.offsetWidth};});const play=await layoutBox(page.getByRole('button',{name:'JOGAR',exact:true}));const previewCount=()=>calls.filter(c=>['preview','resetPreview','cosmetic'].includes(c.body.action)).length;const before=previewCount();
  await page.getByRole('button',{name:'Personagem',exact:true}).click();await page.getByRole('button',{name:'Roupas',exact:true}).waitFor();assert.equal(await page.getByRole('button',{name:'JOGAR',exact:true}).count(),0,'character tab only offers character actions');
  for(const tab of ['Ranking','Showroom','Meu carro'])await page.getByRole('button',{name:tab,exact:true}).click();assert.equal(previewCount(),before,'stable tabs do not touch the existing entity');
  await page.getByRole('button',{name:'Personagem',exact:true}).click();await page.getByRole('button',{name:'Aparência',exact:true}).click();await page.waitForFunction(()=>document.querySelector('.workshop')?.getAttribute('aria-busy')==='false');await page.keyboard.press('e');await page.waitForFunction(()=>document.querySelector('.heat-character-tabs .selected')?.textContent==='Traços');await page.keyboard.press('q');await page.getByLabel('Mistura do rosto').waitFor();await post('tabNav',{direction:1});await page.waitForFunction(()=>document.querySelector('.heat-character-tabs .selected')?.textContent==='Traços');await post('tabNav',{direction:-1});await page.getByLabel('Mistura do rosto').waitFor();await page.getByLabel('Mistura do rosto').fill('0.7');await page.keyboard.press('Escape');await page.locator('.workshop-modal').waitFor();await page.getByRole('button',{name:'Continuar editando',exact:true}).click();assert.equal(await page.locator('.workshop').getAttribute('data-screen'),'character');await page.keyboard.press('Escape');await page.getByRole('button',{name:'Descartar altera\u00e7\u00f5es',exact:true}).click();await page.getByRole('button',{name:'Roupas',exact:true}).waitFor();
  await page.waitForFunction(()=>document.querySelector('.workshop')?.getAttribute('aria-busy')==='false');await page.keyboard.press('Escape');await page.getByRole('button',{name:'Garagem',exact:true}).waitFor();await page.getByRole('button',{name:'Garagem',exact:true}).click();await page.getByRole('button',{name:'JOGAR',exact:true}).waitFor();assert(!(await page.getByRole('button',{name:'JOGAR',exact:true}).isDisabled()));
  // Simulated reconnect/empty states prove presentation selection only, not SQL.
  current={...current,garage:[],selected:null,phase:'empty'};await post('workshop',{state:current});await page.getByRole('button',{name:'Adicionar veículo',exact:true}).waitFor();assert.equal(await page.getByRole('button',{name:'Confirmar personagem',exact:true}).count(),0);assert(await page.getByRole('button',{name:'JOGAR',exact:true}).isDisabled());
  current={...current,phase:'characterRecovery',characterCompleted:false};await post('workshop',{state:current});await page.getByRole('heading',{name:'Recuperar aparência',exact:true}).waitFor();await page.getByRole('button',{name:'Confirmar personagem',exact:true}).click();await page.getByRole('button',{name:'Adicionar veículo',exact:true}).waitFor();assert.equal(await page.getByRole('button',{name:'Escolher este carro',exact:true}).count(),0,'appearance recovery does not reset initial vehicle completion');
  await post('lobby',{data:{...lobby,resume:true}});await page.locator('.lobby').waitFor();await page.keyboard.press('Escape');await page.locator('.lobby').waitFor({state:'detached'});
  assert(calls.some(c=>c.action==='lobbyReady'));assert.deepEqual(errors,[]);
  reports.push({width,height,opaqueLoadingAndTransparentLobby:true,resourceProgressNotGlobal100:true,lobbyKeyboard:true,stableTabs:true,onboardingResumeContracts:true,lostConfirmationReusesUuid:true,emptyGarageNoIntroduction:true,appearanceRecoveryPreservesCarFlag:true,characterWithoutPlay:true,dirtyCharacterResolution:true,friendsUIContracts:true,gameClients:0,scope:'browser fixtures only; no native camera/entity validation'});await page.close();
 }
 await writeFile('docs/evidence/lobby.json',JSON.stringify(reports,null,2));console.log('Lobby/loading/onboarding: contratos de browser aprovados em 4 resoluções; não valida transição nativa nem persistência FiveM.');
}finally{await browser.close();await new Promise(resolve=>server.close(resolve));}
