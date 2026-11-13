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
const preset=(model='mp_m_freemode_01')=>({version:1,model,shapeFirst:0,shapeSecond:21,skinFirst:0,skinSecond:21,shapeMix:.5,skinMix:.5,features:Array(20).fill(0),overlays:Array.from({length:13},()=>({index:-1,opacity:1,color:0})),hairColor:1,hairHighlight:1,eyeColor:0,components:Array.from({length:12},()=>({drawable:0,texture:0})),props:Array.from({length:8},()=>({drawable:-1,texture:0}))});
const capabilities=a=>({components:a.components.map((c,i)=>({count:i===11?140:8,textures:c.drawable===1?3:1})),props:a.props.map(c=>({count:5,textures:c.drawable>=0?2:0})),overlays:Array(13).fill(8)});
const report=[];
try{
 await mkdir('docs/evidence',{recursive:true});
 for(const [width,height] of [[1280,720],[1920,1080],[2560,1440],[3440,1440]]){
  const page=await browser.newPage({viewport:{width,height}}),errors=[],calls=[];page.on('pageerror',e=>errors.push(e.message));
  let confirmed=preset(),shown=structuredClone(confirmed),rejectPreview=false,rejectSave=false,loseAck=false,pending=false,maxConcurrent=0,concurrent=0;
  const operations=new Map();
  const state=()=>({phase:'workshop',token:'CHARACTER-UI-FIXTURE',characterCompleted:true,vehicleCompleted:true,appearance:confirmed,appearanceRevision:1,garage:[],revision:1});
  await page.route('https://mx-freeroam-menu/**',async route=>{
   const body=route.request().postDataJSON()??{},action=new URL(route.request().url()).pathname.slice(1);calls.push({action,body});let data={},ok=true,message='Fixture failure';
   if(action==='experienceLocal'){
    if(body.action==='capabilities')data={capabilities:capabilities(shown)};
    if(body.action==='characterAnchors')data={anchors:Object.fromEntries(['head','torso','legs','feet'].map((id,i)=>[id,{visible:true,x:.55,y:.23+i*.15}]))};
    if(body.action==='characterPreview'){
     concurrent++;maxConcurrent=Math.max(concurrent,maxConcurrent);pending=true;await new Promise(r=>setTimeout(r,55));pending=false;concurrent--;
     if(rejectPreview){ok=false;message='Peça indisponível para este personagem';}else{shown=structuredClone(body.appearance);data={capabilities:capabilities(shown)};}
    }
    if(body.action==='characterCancel'){shown=structuredClone(confirmed);data={capabilities:capabilities(shown)};}
    if(body.action==='characterPreset'){shown=preset(body.model);data={appearance:shown,capabilities:capabilities(shown)};}
   }else if(action==='request'){
    if(body.action==='character'){
     assert.equal(pending,false,'save must await the local preview');
     if(rejectSave){ok=false;message='Não foi possível salvar o personagem';}
     else if(operations.has(body.data.operation))data=operations.get(body.data.operation);
     else{assert.deepEqual(body.data.appearance,shown,'save and final preview must match');confirmed=structuredClone(body.data.appearance);data={state:state()};operations.set(body.data.operation,data);}
     if(loseAck){loseAck=false;ok=false;message='Confirmação não recebida';}
    }else if(['state','enter'].includes(body.action))data=state();
    else if(['catalogBrands','catalog'].includes(body.action))data=[];
    else if(body.action==='permissions')data={};
    else throw Error('Unexpected fixture API '+body.action);
   }
   await route.fulfill({status:200,headers:{'Access-Control-Allow-Origin':'*'},contentType:'application/json',body:JSON.stringify(ok?{ok:true,data}:{ok:false,code:'CHARACTER_FIXTURE',message})});
  });
  await page.addInitScript(()=>window.GetParentResourceName=()=>'mx-freeroam-menu');
  page.setDefaultTimeout(12000);
  await page.goto(`http://127.0.0.1:${server.address().port}`);await page.evaluate(()=>document.body.style.background='#292b30');await page.evaluate(()=>document.fonts.ready);
  await page.evaluate(state=>window.postMessage({type:'workshop',state},'*'),state());
  async function action(key){await page.evaluate(key=>window.dispatchEvent(new MessageEvent('message',{data:{type:'nav',key}})),key);}
  async function save(){await action('saveCharacter');await page.waitForFunction(()=>document.querySelector('.character-save-status')?.textContent==='Alterações salvas');}
  async function equip(fn){const ack=page.waitForResponse(r=>r.url().endsWith('/request')&&r.request().postDataJSON()?.action==='character');await fn();await ack;await page.waitForFunction(()=>document.querySelector('.character-save-status')?.textContent==='Peça equipada e salva');}
  async function enterAppearance(){await page.getByRole('button',{name:'Aparência',exact:true}).click();await page.locator('.character-face-panel').waitFor();}
  async function noseGroup(){await page.getByRole('button',{name:'Traços faciais',exact:true}).click();await page.getByRole('spinbutton',{name:'Região do rosto',exact:true}).fill('2');await page.keyboard.press('Enter');await page.getByRole('slider',{name:'Largura do nariz',exact:true}).waitFor();}
  await page.getByRole('button',{name:'Personagem',exact:true}).click();await page.locator('.character-entry-strip').waitFor();
  await page.waitForFunction(()=>document.querySelector('.workshop')?.getAttribute('aria-busy')==='false');
  assert.deepEqual(await page.locator('.workshop-nav .tab-items>button').allTextContents(),['Meu carro','Showroom','Personagem']);
  assert.deepEqual(await page.locator('.character-entry-strip>button').allTextContents(),['Roupas & acessórios','Aparência']);
  assert.equal(await page.getByRole('button',{name:'VOLTAR',exact:true}).count(),0,'return is only in control hints');
  await page.getByRole('button',{name:'Roupas & acessórios',exact:true}).click();const editor=page.locator('.character-editor');await editor.waitFor();
  assert.equal(await page.getByRole('button',{name:'Concluir personagem',exact:true}).count(),0);
  await page.waitForTimeout(100);
  const markerBoxes=()=>page.locator('.character-hotspot').evaluateAll(nodes=>nodes.map(n=>{const b=n.getBoundingClientRect();const dot=n.querySelector('i').getBoundingClientRect(),label=n.querySelector('span').getBoundingClientRect();return {x:b.x,y:b.y,w:b.width,h:b.height,dotRight:dot.right,labelLeft:label.left,visible:getComputedStyle(n.querySelector('span')).visibility};}));
  const initial=await markerBoxes();assert.equal(initial.filter(b=>b.visible==='visible').length,1,'only focused marker has a label');
  for(let i=0;i<initial.length;i++){const b=initial[i];assert(b.w>=44&&b.h>=44&&b.x>=0&&b.x+b.w<=width);assert(b.labelLeft>b.dotRight,'labels are right of circles');if(i)assert(b.y-initial[i-1].y>=44,'regions do not overlap');}
  await page.waitForTimeout(650);assert.deepEqual(await markerBoxes(),initial,'markers never poll or drift with breathing');assert.equal(calls.filter(c=>c.body.action==='characterAnchors').length,1);
  await page.screenshot({path:`docs/evidence/character-fixed-regions-${width}x${height}.png`});
  await page.keyboard.press('ArrowDown');assert.equal(await page.evaluate(()=>document.activeElement.dataset.region),'torso');
  await action('enter');await page.getByRole('button',{name:'Jaquetas Ver modelos'}).click();
  assert.equal(await page.locator('.character-strip').count(),1);
  await equip(()=>page.locator('[data-drawable="1"]').click());assert.equal(confirmed.components[11].drawable,1,'equipping persists without leaving editor');
  const variation=page.getByRole('spinbutton',{name:'Variação',exact:true});await variation.focus();await equip(()=>action('right'));assert.equal(confirmed.components[11].texture,1);
  await variation.fill('1');await equip(()=>page.keyboard.press('Enter'));assert.equal(confirmed.components[11].texture,0,'number selects the displayed variation');
  await variation.focus();await equip(()=>action('left'));assert.equal(confirmed.components[11].texture,2,'first wraps to last');
  await variation.focus();await equip(()=>action('right'));assert.equal(confirmed.components[11].texture,0,'last wraps to first');
  await page.locator('[data-drawable="139"]').focus();await page.waitForTimeout(200);const last=await page.locator('[data-drawable="139"]').boundingBox();assert(last.x>=0&&last.x+last.width<=width+1);
  await page.keyboard.press('Escape');await page.keyboard.press('Escape');await page.keyboard.press('Escape');await page.locator('.character-entry-strip').waitFor();assert.equal(await page.getByRole('dialog').count(),0,'saved clothes leave without a prompt');
  await enterAppearance();assert.deepEqual(await page.locator('.character-face-tabs .tab-items>button').allTextContents(),['Genética','Traços faciais','Pele','Cabelo e barba','Corpo']);
  const heredity=page.getByRole('spinbutton',{name:'Herança facial A',exact:true});await heredity.focus();await action('left');await page.waitForFunction(()=>document.querySelector('[aria-label="Herança facial A"]').value==='46');assert.equal(await heredity.inputValue(),'46','native selector wraps');
  await heredity.fill('1');await page.keyboard.press('Enter');
  await noseGroup();const nose=page.getByRole('slider',{name:'Largura do nariz',exact:true});await nose.focus();await page.keyboard.press('ArrowRight');assert.equal(await nose.inputValue(),'0.01');
  await page.evaluate(()=>window.dispatchEvent(new MessageEvent('message',{data:{type:'nativeNavigation',enabled:true}})));await page.keyboard.press('ArrowRight');assert.equal(await nose.inputValue(),'0.01','native boundary blocks duplicate DOM navigation');await action('right');await page.waitForFunction(()=>document.querySelector('[aria-label="Largura do nariz"]').value==='0.02');await page.evaluate(()=>window.dispatchEvent(new MessageEvent('message',{data:{type:'nativeNavigation',enabled:false}})));
  const exact=page.getByRole('spinbutton',{name:'Largura do nariz: valor exato',exact:true});await exact.fill('-0.37');await page.keyboard.press('Enter');await page.waitForFunction(()=>document.querySelector('[aria-label="Largura do nariz"]').value==='-0.37');
  await page.screenshot({path:`docs/evidence/character-grouped-face-${width}x${height}.png`});
  await nose.fill('0.39');await save();assert.equal(confirmed.features[0],.39);assert.equal(await editor.count(),1,'save action stays in editor');assert.equal(maxConcurrent,1);
  await nose.fill('0.4');await page.keyboard.press('Space');await page.waitForFunction(()=>document.querySelector('.character-save-status')?.textContent==='Alterações salvas');assert.equal(confirmed.features[0],.4,'Space saves from footer action');
  await nose.fill('0.42');await page.keyboard.press('Escape');await page.getByRole('dialog').waitFor();await page.getByRole('button',{name:'Continuar editando',exact:true}).click();assert.equal(await editor.count(),1);
  await page.keyboard.press('Escape');await page.getByRole('button',{name:'Descartar alterações',exact:true}).click();await page.locator('.character-entry-strip').waitFor();assert.deepEqual(shown,confirmed);
  await enterAppearance();await noseGroup();await page.getByRole('slider',{name:'Largura do nariz',exact:true}).fill('0.43');await page.keyboard.press('Escape');await page.getByRole('button',{name:'Salvar e continuar',exact:true}).click();await page.locator('.character-entry-strip').waitFor();assert.equal(confirmed.features[0],.43,'exit modal saves only when requested');
  await enterAppearance();await noseGroup();rejectPreview=true;await page.getByRole('slider',{name:'Largura do nariz',exact:true}).fill('0.8');await page.getByRole('alert').waitFor();const savesBefore=calls.filter(c=>c.action==='request'&&c.body.action==='character').length;
  await action('saveCharacter');await page.waitForTimeout(160);assert.equal(calls.filter(c=>c.action==='request'&&c.body.action==='character').length,savesBefore);
  await page.keyboard.press('Escape');await page.getByRole('button',{name:'Descartar alterações',exact:true}).click();await page.locator('.character-entry-strip').waitFor();assert.deepEqual(shown,confirmed);rejectPreview=false;
  await enterAppearance();await page.getByRole('spinbutton',{name:'Modelo',exact:true}).focus();await action('right');await page.getByRole('dialog').waitFor();assert.match(await page.evaluate(()=>document.activeElement.textContent),/Continuar editando/);await page.keyboard.press('Escape');
  await noseGroup();await page.getByRole('slider',{name:'Largura do nariz',exact:true}).fill('0.44');rejectSave=true;await action('saveCharacter');await page.getByRole('alert').waitFor();assert.equal(await editor.count(),1);rejectSave=false;await page.getByRole('button',{name:'Tentar novamente',exact:true}).click();await page.waitForTimeout(550);assert.equal(confirmed.features[0],.44);assert.equal(await editor.count(),1);
  await page.getByRole('slider',{name:'Largura do nariz',exact:true}).fill('0.45');loseAck=true;await action('saveCharacter');await page.getByRole('alert').waitFor();await save();const lastSaves=calls.filter(c=>c.action==='request'&&c.body.action==='character').slice(-2);assert.equal(lastSaves[0].body.data.operation,lastSaves[1].body.data.operation,'uncertain result repeats exact operation');
  assert.deepEqual(errors,[]);report.push({width,height,errors,previewsSerialized:true,discard:true,precision:.01,retry:true});await page.close();
 }
 await writeFile('docs/evidence/character-ui-2026-10-31.json',JSON.stringify(report,null,2));console.log('Character UI: 4 resolutions, fixed markers, focus labels, autosave clothes, numeric wrap, five tabs, contextual save/modal and idempotent retry passed (browser fixtures).');
}finally{await browser.close();await new Promise(resolve=>server.close(resolve));}






