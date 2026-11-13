import {useEffect,useRef} from 'react';
export type OrbitInput={yaw?:number;pitch?:number;zoom?:number;stop?:boolean};
export function OrbitSurface({move}:{move:(d:OrbitInput)=>void}){
 const surface=useRef<HTMLDivElement>(null);
 useEffect(()=>{surface.current?.focus({preventScroll:true});},[]);
 const pointer=useRef<{id:number;x:number;y:number;el:HTMLDivElement}|null>(null);
 const send=useRef(move),scheduled=useRef(0),pending=useRef({yaw:0,pitch:0,zoom:0});send.current=move;
 function flush(){scheduled.current=0;const p=pending.current;pending.current={yaw:0,pitch:0,zoom:0};send.current({yaw:Math.max(-.3,Math.min(.3,p.yaw)),pitch:Math.max(-.15,Math.min(.15,p.pitch)),zoom:Math.max(-1,Math.min(1,p.zoom))});}
 function stop(){const p=pointer.current;pointer.current=null;cancelAnimationFrame(scheduled.current);scheduled.current=0;pending.current={yaw:0,pitch:0,zoom:0};if(p){if(p.el.hasPointerCapture(p.id))p.el.releasePointerCapture(p.id);send.current({stop:true});}}
 function enqueue(d:OrbitInput){pending.current.yaw+=d.yaw??0;pending.current.pitch+=d.pitch??0;pending.current.zoom+=d.zoom??0;if(!scheduled.current)scheduled.current=requestAnimationFrame(flush);}
 useEffect(()=>{const outside=()=>{if(document.hidden)stop();};window.addEventListener('blur',stop);window.addEventListener('pointerup',stop);document.addEventListener('visibilitychange',outside);return()=>{stop();cancelAnimationFrame(scheduled.current);window.removeEventListener('blur',stop);window.removeEventListener('pointerup',stop);document.removeEventListener('visibilitychange',outside);};},[]);
 return <div ref={surface} tabIndex={-1} className="workshop-orbit-surface" aria-label="Arraste para observar o carro" onPointerDown={e=>{if(e.button!==0)return;e.preventDefault();e.currentTarget.focus({preventScroll:true});stop();pointer.current={id:e.pointerId,x:e.clientX,y:e.clientY,el:e.currentTarget};e.currentTarget.setPointerCapture(e.pointerId);}} onPointerMove={e=>{const p=pointer.current;if(!p||p.id!==e.pointerId)return;if(!(e.buttons&1)||e.clientX<=0||e.clientY<=0||e.clientX>=window.innerWidth-1||e.clientY>=window.innerHeight-1){stop();return;}e.preventDefault();enqueue({yaw:(p.x-e.clientX)*.005,pitch:(e.clientY-p.y)*.004});p.x=e.clientX;p.y=e.clientY;}} onPointerUp={stop} onPointerCancel={stop} onLostPointerCapture={stop} onPointerLeave={stop} onWheel={e=>enqueue({zoom:e.deltaY>0?.6:-.6})}/>;
}
