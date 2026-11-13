import {useEffect,useRef,useState} from 'react';
import {nui} from './api';
import {useInputDevice} from './ControlHints';
type Binding={id:string;label:string;key:string;pad:string};
export function ServerBindings(){
 const [bindings,setBindings]=useState<Binding[]>([]),[active,setActive]=useState<string|null>(null),[busy,setBusy]=useState(false),[error,setError]=useState('');
 const [capture,setCapture]=useState<'key'|'pad'|null>(null),capturing=useRef(false);
 capturing.current=capture!==null;
 const device=useInputDevice();const binding=bindings.find(b=>b.id===active);
 const root=useRef<HTMLElement>(null),editing=useRef(false);editing.current=!!binding;
 useEffect(()=>{if(!busy)root.current?.querySelector<HTMLButtonElement>('button:not(:disabled)')?.focus({preventScroll:true});},[active,busy]);
 useEffect(()=>{
  const back=(e:MessageEvent)=>{if(capturing.current&&(e.data?.type==='nav'||e.data?.type==='tabNav')){e.stopImmediatePropagation();return;}if(editing.current&&e.data?.type==='nav'&&e.data.key==='back'){e.stopImmediatePropagation();setActive(null);}};
  const keyboard=(e:KeyboardEvent)=>{if(capturing.current){e.preventDefault();e.stopImmediatePropagation();if(e.key==='Escape')void nui('cancelBindingCapture');return;}if(editing.current&&['Escape','Backspace'].includes(e.key)){e.preventDefault();e.stopImmediatePropagation();setActive(null);}};
  window.addEventListener('message',back,true);window.addEventListener('keydown',keyboard,true);return()=>{window.removeEventListener('message',back,true);window.removeEventListener('keydown',keyboard,true);};
 },[]);
 async function load(){setBusy(true);try{setBindings(await nui<Binding[]>('bindings'));}catch(e){setError(String(e));}finally{setBusy(false);}}
 useEffect(()=>{void load();},[]);
 async function change(kind:'key'|'pad',remove=false){if(!binding)return;setBusy(true);setError('');try{
  let value='';if(!remove){setCapture(kind);const r=await nui<{value?:string;cancelled:boolean}>('captureBinding',{kind});if(r.cancelled)return;value=r.value??'';}
  setBindings(await nui<Binding[]>('setBinding',{action:binding.id,kind,value}));
 }catch(e){setError(e instanceof Error?e.message:String(e));}finally{setCapture(null);setBusy(false);}}
 const padLabel=(pad:string)=>device==='playstation'?({VIEW:'Touchpad',A:'X',B:'Círculo',X:'Quadrado',Y:'Triângulo',LB:'L1',RB:'R1',LS:'L3',RS:'R3'} as Record<string,string>)[pad]??pad:pad;
 return <><section className="server-bindings" aria-label="Atalhos do servidor" aria-busy={busy} ref={root} inert={capture?true:undefined} data-bindings-editor={binding?'true':undefined}>{error&&<p role="alert">{error}</p>}
 {binding?<><h3>{binding.label}</h3><p>Selecione o dispositivo e pressione a tecla ou botão desejado. ESC cancela a captura.{binding.id==='engine'?' No controle, segure o botão por 0,7 segundo para alternar o motor.':''}</p>
 <button disabled={busy} onClick={()=>void change('key')}>Tecla do teclado <b>{binding.key||'Sem tecla'}</b></button>
 <button disabled={busy} onClick={()=>void change('pad')}>Botão do controle <b>{padLabel(binding.pad)||'Sem botão'}</b></button>
 <button disabled={busy||!binding.key} onClick={()=>void change('key',true)}>Remover tecla</button><button disabled={busy||!binding.pad} onClick={()=>void change('pad',true)}>Remover botão</button>
 </>:<><p>Somente funções do servidor. Selecione uma ação para alterar ou remover o atalho.</p>{bindings.map(b=><button key={b.id} disabled={busy} onClick={()=>setActive(b.id)}>{b.label}<b>{b.key||'—'}{b.pad?` / ${padLabel(b.pad)}`:''}</b></button>)}</>}
 </section>{capture&&<div className="workshop-modal confirm-overlay" data-binding-capture role="dialog" aria-modal="true" aria-label="Capturar atalho"><div className="confirm-band"><h2>{capture==='key'?'PRESSIONE UMA TECLA':'PRESSIONE UM BOTÃO'}</h2><p>Solte os botões antes de escolher. ESC cancela; a captura expira em 15 segundos.</p><div className="confirm-actions"><button onClick={()=>void nui('cancelBindingCapture')}>Cancelar captura</button></div></div></div>}</>;
}
