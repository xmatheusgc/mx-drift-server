import React,{useEffect,useState} from 'react';

// Visual feedback follows the operation, never extends its lifetime or blocks
// input. Rapid preview choices share one busy interval; cancellation clears it.
export function LoadingHint({active}:{active:boolean}){
 const [seconds,setSeconds]=useState<number|null>(null);
 useEffect(()=>{
  setSeconds(null);
  if(!active)return;
  const started=performance.now();
  const show=setTimeout(()=>setSeconds(Math.floor((performance.now()-started)/1000)),600);
  const tick=setInterval(()=>setSeconds(Math.floor((performance.now()-started)/1000)),1000);
  return()=>{clearTimeout(show);clearInterval(tick);};
 },[active]);
 if(!active||seconds===null)return null;
 return <aside className="preview-loading-hint" role="status" aria-label="Carregando carro">
  <span className="vehicle-loading-spinner" aria-hidden="true"/>
  <div><strong>Preparando carro…</strong>{seconds>=10&&<p>Na primeira visita, este veículo pode levar mais tempo para carregar.</p>}{seconds>=10&&<small aria-hidden="true">{Math.floor(seconds/60)}:{String(seconds%60).padStart(2,'0')} de espera</small>}</div>
 </aside>;
}
