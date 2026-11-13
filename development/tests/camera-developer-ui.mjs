import '../scripts/workspace.mjs';
import {chromium} from 'playwright';
import {createServer} from 'node:http';
import {readFile,writeFile} from 'node:fs/promises';
import path from 'node:path';
import assert from 'node:assert/strict';
const root=path.resolve('resources/[mx]/mx-freeroam-menu/dist');
const server=createServer(async(req,res)=>{try{const p=path.resolve(root,'.'+decodeURIComponent(req.url==='/'?'/index.html':req.url.split('?')[0]));if(!p.startsWith(root+path.sep)){res.writeHead(403).end();return;}res.setHeader('Content-Type',p.endsWith('.js')?'application/javascript':p.endsWith('.css')?'text/css':'text/html');res.end(await readFile(p));}catch{res.writeHead(404).end();}});
await new Promise(r=>server.listen(0,'127.0.0.1',r));const browser=await chromium.launch({executablePath:process.env.MX_CHROMIUM,headless:true}),results=[];
try{for(const [width,height]of[[1280,720],[1920,1080],[2560,1440],[3440,1440]]){
 const page=await browser.newPage({viewport:{width,height}}),errors=[],calls=[];
 const original={context:'garage',view:'main',position:{x:135,y:-3030,z:8},rotation:{x:-5,y:0,z:90},fov:60};let current=structuredClone(original);
 page.on('pageerror',e=>errors.push(e.message));await page.addInitScript(()=>window.GetParentResourceName=()=> 'mx-freeroam-menu');
 await page.route('https://mx-freeroam-menu/**',async route=>{
  const action=new URL(route.request().url()).pathname.slice(1),d=route.request().postDataJSON()??{};calls.push({action,...d});let data={};
  if(action==='cameraDeveloper'){
   if(d.action==='update')current={...current,...d.pose};if(d.action==='reset')current=structuredClone(original);data=structuredClone(current);
   if(d.action==='capture')data.text=`{context="${current.context}", position={x=${current.position.x.toFixed(3)},y=${current.position.y.toFixed(3)},z=${current.position.z.toFixed(3)}}, rotation={x=${current.rotation.x},y=0,z=${current.rotation.z}}, fov=${current.fov}}`;
   if(d.action==='close'){if(d.restore)current=structuredClone(original);await page.evaluate(()=>window.postMessage({type:'cameraDeveloper',open:false},'*'));}
  }
  await route.fulfill({status:200,contentType:'application/json',body:JSON.stringify({ok:true,data})});
 });
 await page.goto(`http://127.0.0.1:${server.address().port}`);
 await page.evaluate(data=>window.postMessage({type:'cameraDeveloper',open:true,data},'*'),current);
 const editor=page.getByRole('dialog',{name:'Editor de câmera',exact:true});await editor.waitFor();
 await page.locator('.camera-dev-drag').focus();await page.keyboard.down('w');await page.waitForTimeout(400);await page.keyboard.up('w');await page.waitForTimeout(100);
 assert(current.position.x<134.98);assert(!calls.some(c=>c.action==='experienceLocal'),'camera movement never reaches workshop controls');
 const x=editor.getByLabel('X',{exact:true}),before=structuredClone(current);
 await x.fill('1');await page.waitForTimeout(80);assert.deepEqual(current,before,'partial coordinate never reaches native camera');
 await x.fill('135');await page.keyboard.press('Enter');await page.waitForTimeout(80);assert.equal(current.position.x,135);
 await x.focus();await page.keyboard.press('ArrowUp');await page.keyboard.press('Enter');await page.waitForTimeout(80);
 assert.equal(current.position.x,135.01);assert.deepEqual(current.rotation,original.rotation);assert.equal(current.fov,60);
 const surface=page.locator('.camera-dev-drag');await page.mouse.move(100,200);await page.mouse.down();await page.mouse.move(110,210);await page.mouse.up();await page.waitForTimeout(80);
 assert(Math.abs(current.rotation.x-original.rotation.x+.4)<1e-8);assert.equal(current.position.x,135.01);assert.equal(current.fov,60);
 await editor.getByLabel('X',{exact:true}).fill('136.25');await editor.getByLabel('Campo de visão').focus();await page.keyboard.press('Home');
 await editor.getByRole('button',{name:'Capturar para copiar',exact:true}).click();const text=editor.getByLabel('Configuração capturada');await text.waitFor();assert.match(await text.inputValue(),/x=136\.250/);assert.match(await text.inputValue(),/fov=15/);
 const box=await page.locator('.camera-dev-panel').boundingBox();assert(box.y+box.height<=height,'panel remains within viewport with scrollable content');
 await page.screenshot({path:`docs/evidence/camera-developer-${width}x${height}.png`});
 await editor.getByRole('button',{name:'Restaurar e fechar',exact:true}).click();await editor.waitFor({state:'detached'});assert.equal(current.fov,60);
 current={...structuredClone(original),context:'lobby'};await page.evaluate(data=>window.postMessage({type:'cameraDeveloper',open:true,data},'*'),current);await editor.waitFor();
 await page.locator('.camera-dev-drag').focus();await page.keyboard.press('Escape');await editor.waitFor({state:'detached'});assert.equal(calls.at(-1).action,'close');
 assert.deepEqual(errors,[]);results.push({width,height,cameraMovement:true,copyCapture:true,fov:true,viewport:true,restore:true,lobbyEscape:true});await page.close();
}await writeFile('docs/evidence/camera-developer-browser.json',JSON.stringify({date:'2026-10-24',kind:'browser fixtures; no FiveM/native/real clipboard',results},null,2));console.log('Camera editor browser: movement, input isolation, numeric pose/FOV, capture, panel bounds and restore/Esc passed in four resolutions (mocked transport).');}
finally{await browser.close();server.close();}
