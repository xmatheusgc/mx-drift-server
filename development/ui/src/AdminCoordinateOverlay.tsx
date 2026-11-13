import React,{useEffect,useState} from 'react';
import {coordinateTargets,type Coordinate} from './admin-coordinates';
export function AdminCoordinateOverlay(){
 const [point,setPoint]=useState<Coordinate|null>(null);
 useEffect(()=>{const handler=(e:MessageEvent)=>{if(e.data.type==='adminCoordinates')setPoint(e.data.data||null);if((e.data.type==='workshop'&&e.data.state)||(e.data.type==='lobby'&&e.data.data))setPoint(null);};window.addEventListener('message',handler);return()=>window.removeEventListener('message',handler);},[]);
 if(!point)return null;
 const label=coordinateTargets.find(([id])=>id===point.target)?.[1]??'Personagem';
 return <aside className="admin-coordinate-overlay" aria-label="Coordenadas de administrador"><strong>COORDENADAS · {label}</strong>{point.error?<span>{point.error}</span>:<><div>{(['x','y','z','h'] as const).map(k=><span key={k}><small>{k==='h'?'HEADING':k.toUpperCase()}</small><b>{Number(point[k]).toFixed(k==='h'?2:3)}</b></span>)}</div>{point.model!==undefined&&<small>MODELO {point.name||point.model} · INTERIOR {point.interior??0} · NET {point.networkId??0}</small>}</>}</aside>;
}
