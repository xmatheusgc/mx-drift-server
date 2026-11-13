import React,{useEffect,useRef,useState} from 'react';
import {api,nui} from './api';
import {setCameraDeveloperInput} from './camera-developer-input';
import {moveCamera,rotateCamera,type CameraPose} from './camera-developer-math';
type Snapshot=CameraPose&{context:string;view:string;text?:string};
function CameraNumber({value,step,label,commit,onFocus}:{value:number;step:number;label:string;commit:(value:number)=>void;onFocus:()=>void}){
 const [draft,setDraft]=useState(String(Number(value.toFixed(3)))),editing=useRef(false);
 useEffect(()=>{if(!editing.current)setDraft(String(Number(value.toFixed(3))));},[value]);
 return <label>{label}<input aria-label={label} type="number" step={step} value={draft} onFocus={()=>{editing.current=true;onFocus();}} onChange={e=>setDraft(e.target.value)} onBlur={()=>{editing.current=false;const n=Number(draft);if(draft.trim()&&Number.isFinite(n)){commit(n);}else setDraft(String(Number(value.toFixed(3))));}}/></label>;
}
export function CameraDeveloper(){
 const [data,setData]=useState<Snapshot|null>(null),[available,setAvailable]=useState(false),[error,setError]=useState(''),[capture,setCapture]=useState(''),[speed,setSpeed]=useState(.25);
 const current=useRef<Snapshot|null>(null),keys=useRef(new Set<string>()),pending=useRef<CameraPose|null>(null),sending=useRef(false),generation=useRef(0),sceneVersion=useRef(0),text=useRef<HTMLTextAreaElement>(null),drag=useRef<{x:number;y:number}|null>(null),speedRef=useRef(speed);speedRef.current=speed;
 async function flush(){
  if(sending.current||!pending.current)return;sending.current=true;const id=generation.current;
  try{while(pending.current&&current.current&&id===generation.current){const pose=pending.current;pending.current=null;await nui('cameraDeveloper',{action:'update',pose});}}
  catch(e){pending.current=null;keys.current.clear();if(id===generation.current){setError(String(e));try{const actual=await nui<Snapshot>('cameraDeveloper',{action:'snapshot'});if(id===generation.current){current.current=actual;setData(actual);}}catch{/* Scene expiry closes through its native event. */}}}
  finally{sending.current=false;}
 }
 function change(pose:CameraPose){if(!current.current)return;const next={...current.current,...pose};current.current=next;setData(next);pending.current={position:pose.position,rotation:pose.rotation,fov:pose.fov};void flush();}
 async function settle(){keys.current.clear();while(sending.current||pending.current){void flush();await new Promise(r=>setTimeout(r,10));}}
 async function command(action:'close'|'reset'|'capture',restore=true){
  setError('');try{await settle();const result=await nui<Snapshot>('cameraDeveloper',{action,restore});if(action==='close')return;if(action==='reset'){current.current=result;setData(result);setCapture('');}else{setCapture(result.text??'');try{await navigator.clipboard.writeText(result.text??'');}catch{/* Selected text supports Ctrl+C in CEF. */}}}catch(e){setError(String(e));}
 }
 useEffect(()=>{const handler=(e:MessageEvent)=>{
  const m=e.data;
  if(m.type==='cameraDeveloper'){
   generation.current++;keys.current.clear();drag.current=null;pending.current=null;current.current=m.open?m.data:null;setData(current.current);setCapture('');setError('');setCameraDeveloperInput(!!m.open);
  }
  if(m.type==='lobby'||m.type==='workshop'){
   const version=++sceneVersion.current;setAvailable(false);if(m.data||m.state)void api('admin','permissions').then(p=>{if(version===sceneVersion.current)setAvailable(!!p.admin&&!!p.inspect);}).catch(()=>{if(version===sceneVersion.current)setAvailable(false);});
  }
 };window.addEventListener('message',handler);return()=>{setCameraDeveloperInput(false);window.removeEventListener('message',handler);};},[]);
 useEffect(()=>{if(capture){text.current?.focus();text.current?.select();}},[capture]);
 useEffect(()=>{const key=(e:Event)=>{const d=(e as CustomEvent).detail;if(!current.current)return;if(d.code==='Escape'&&d.down&&!d.repeat){if(capture){setCapture('');}else void command('close');return;}if(d.input){if(!d.down)keys.current.delete(d.code);return;}if(d.down)keys.current.add(d.code);else keys.current.delete(d.code);};const blur=()=>{keys.current.clear();drag.current=null;};window.addEventListener('cameraDeveloperKey',key);window.addEventListener('blur',blur);return()=>{window.removeEventListener('cameraDeveloperKey',key);window.removeEventListener('blur',blur);};},[capture]);
 useEffect(()=>{let frame=0,last=performance.now();const tick=(now:number)=>{
  const moving=['KeyW','KeyA','KeyS','KeyD','KeyQ','KeyE'].some(key=>keys.current.has(key));
  if(current.current&&moving){if(now-last>=33){const dt=(now-last)/1000;last=now;change(moveCamera(current.current,keys.current,dt,speedRef.current));}}else last=now;
  frame=requestAnimationFrame(tick);
 };frame=requestAnimationFrame(tick);return()=>cancelAnimationFrame(frame);},[]);
 if(!data)return available?<button className="camera-dev-launch" onClick={()=>{setError('');void api('admin','cameraEditor',{enabled:true}).catch(e=>setError(String(e)));}}>DEV · CÂMERA{error&&<small>{error}</small>}</button>:null;
 const number=(group:'position'|'rotation',key:'x'|'y'|'z',label:string)=> <CameraNumber key={key} value={data[group][key]} step={group==='position'?.01:.1} label={label} onFocus={()=>keys.current.clear()} commit={value=>{if(!current.current)return;const pose=structuredClone(current.current);pose[group][key]=value;change(pose);}}/>;
 return <section className="camera-dev" role="dialog" aria-modal="true" aria-label="Editor de câmera">
  <div className="camera-dev-drag" aria-label="Arraste para girar a câmera" onContextMenu={e=>e.preventDefault()} onPointerDown={e=>{if(e.button!==0&&e.button!==2)return;e.currentTarget.setPointerCapture(e.pointerId);drag.current={x:e.clientX,y:e.clientY};e.currentTarget.focus();}} tabIndex={0} onPointerUp={()=>drag.current=null} onPointerCancel={()=>drag.current=null} onLostPointerCapture={()=>drag.current=null} onPointerMove={e=>{if(!drag.current||!current.current)return;if(!(e.buttons&3)){drag.current=null;return;}const dx=e.clientX-drag.current.x,dy=e.clientY-drag.current.y;drag.current={x:e.clientX,y:e.clientY};const pose=rotateCamera(current.current,dx,dy,e.ctrlKey);change(pose);}}/>
  <aside className="camera-dev-panel"><small>DESENVOLVIMENTO · {data.context} / {data.view}</small><h2>EDITOR DE CÂMERA</h2><p>WASD move · Q/E desce/sobe · arraste a área livre para olhar · Shift acelera · Ctrl dá precisão</p>
   <fieldset><legend>Posição</legend>{number('position','x','X')}{number('position','y','Y')}{number('position','z','Z')}</fieldset>
   <fieldset><legend>Rotação</legend>{number('rotation','x','Inclinação')}{number('rotation','y','Rolagem')}{number('rotation','z','Direção')}</fieldset>
   <small>Campos numéricos: Enter ou sair do campo aplica o valor completo. Ctrl ao arrastar faz o ajuste fino.</small>
   <label>Campo de visão<input aria-label="Campo de visão" type="range" min="15" max="100" step=".5" value={data.fov} onChange={e=>change({...current.current!,fov:Number(e.target.value)})}/><b>{data.fov.toFixed(1)}°</b></label>
   <label>Velocidade<select aria-label="Velocidade da câmera" value={speed} onChange={e=>setSpeed(Number(e.target.value))}><option value=".25">Muito lenta</option><option value="1">Lenta</option><option value="3">Normal</option><option value="6">Rápida</option></select></label>
   <button onClick={()=>void command('capture')}>Capturar para copiar</button><button onClick={()=>void command('reset')}>Restaurar câmera inicial</button>
   {capture&&<label>Configuração capturada<textarea ref={text} readOnly aria-label="Configuração capturada" value={capture}/><small>Ctrl+C copia. Também registrado no F8 como [MX:CAMERA].</small></label>}
   {error&&<p role="alert">{error}</p>}<footer><button onClick={()=>void command('close',false)}>Manter prévia</button><button onClick={()=>void command('close',true)}>Restaurar e fechar</button></footer><small>Prévia local; não altera a configuração salva. Esc restaura e fecha.</small>
  </aside>
 </section>;
}
