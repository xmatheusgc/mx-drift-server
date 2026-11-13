import '../scripts/workspace.mjs';
import {chromium} from 'playwright';
import {createServer} from 'node:http';
import {readFile,writeFile} from 'node:fs/promises';
import path from 'node:path';
import assert from 'node:assert/strict';
const root=path.resolve('resources/[mx]/mx-freeroam-menu');
const server=createServer(async(req,res)=>{try{
 const url=req.url==='/'?'/dist/index.html':req.url.startsWith('/fonts/')?'/dist'+req.url:req.url;
 const file=path.resolve(root,'.'+decodeURIComponent(url.split('?')[0]));
 if(!file.startsWith(root+path.sep)){res.writeHead(403).end();return;}
 res.setHeader('Content-Type',file.endsWith('.js')?'application/javascript':file.endsWith('.css')?'text/css':file.endsWith('.ttf')?'font/ttf':'text/html');res.end(await readFile(file));
}catch{res.writeHead(404).end();}});
await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));
const browser=await chromium.launch({executablePath:process.env.MX_CHROMIUM,headless:true});

try{
 for(const [width,height] of [[1280,720],[1920,1080],[2560,1440],[3440,1440]]){
  const page=await browser.newPage({viewport:{width,height}});let opened=0;
  await page.addInitScript(()=>window.GetParentResourceName=()=> 'mx-freeroam-menu');
  await page.route('https://mx-freeroam-menu/**',async route=>{
   if(new URL(route.request().url()).pathname==='/openGarage')opened++;
   await route.fulfill({status:200,contentType:'application/json',body:JSON.stringify({ok:true,data:{}})});
  });
  await page.goto('http://127.0.0.1:'+server.address().port+'/dist/index.html');
  await page.evaluate(()=>window.postMessage({type:'lobby',data:{generation:1,sceneReady:false,error:'Lobby unavailable (fixture)'}},'*'));
  const garage=page.getByRole('button',{name:'Garagem',exact:true});await garage.waitFor();
  assert(await garage.isEnabled(),'garage remains available after failed lobby preparation');
  assert.equal(await page.locator('.lobby').evaluate(e=>getComputedStyle(e).backgroundColor),'rgb(8, 10, 13)','unloaded lobby world remains covered');
  await garage.click();await page.waitForFunction(()=>document.querySelector('.lobby')?.getAttribute('aria-busy')==='false');
  assert.equal(opened,1,'click reaches independent garage entry');await page.close();
 }
 console.log('Lobby fallback: garage entry stays enabled and invokes openGarage after lobby error at four resolutions (browser transport adapter).');
}finally{await browser.close();await new Promise(resolve=>server.close(resolve));}
