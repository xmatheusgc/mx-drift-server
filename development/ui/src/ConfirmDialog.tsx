import {useEffect,useLayoutEffect,useRef,useState,type ReactNode} from 'react';
import {ControlHints} from './ControlHints';
type Action={id:string;label:string;run:()=>void;disabled?:boolean};
export function ConfirmDialog({title,detail,actions,onCancel,busy=false,children}:{title:string;detail?:string;actions:Action[];onCancel:()=>void;busy?:boolean;children?:ReactNode}){
 const root=useRef<HTMLDivElement>(null),[selected,setSelected]=useState(0),selection=useRef(0),latest=useRef({actions,onCancel,busy});latest.current={actions,onCancel,busy};
 function select(n:number){selection.current=n;setSelected(n);}
 useLayoutEffect(()=>{root.current?.querySelectorAll<HTMLButtonElement>('[data-dialog-action]')[selected]?.focus({preventScroll:true});},[selected]);
 useEffect(()=>{
  const handle=(key:string)=>{const c=latest.current;if(c.busy)return;if(key==='back'||key==='escape'){c.onCancel();return;}if(key==='enter'){c.actions[selection.current]?.run();return;}if(['up','down','left','right'].includes(key)){const step=key==='up'||key==='left'?-1:1;let next=selection.current+step;while(c.actions[next]?.disabled)next+=step;if(c.actions[next])select(next);}};
  const keyboard=(e:KeyboardEvent)=>{if(e.target instanceof HTMLInputElement&&!['Escape','Enter'].includes(e.key))return;const key=({ArrowUp:'up',ArrowDown:'down',ArrowLeft:'left',ArrowRight:'right',Enter:'enter',Escape:'escape',Backspace:'back'} as Record<string,string>)[e.key];if(key){e.preventDefault();e.stopImmediatePropagation();if(!e.repeat)handle(key);}};
  const message=(e:MessageEvent)=>{if(e.data?.type==='nav'||e.data?.type==='workshopBack'){e.stopImmediatePropagation();handle(e.data.type==='workshopBack'?'back':e.data.key);}};
  window.addEventListener('keydown',keyboard,true);window.addEventListener('message',message,true);return()=>{window.removeEventListener('keydown',keyboard,true);window.removeEventListener('message',message,true);};
 },[]);
 return <div className="workshop-modal confirm-overlay" data-confirm-dialog role="dialog" aria-modal="true" aria-label={title} ref={root}><div className="confirm-band"><h2>{title}</h2>{detail&&<p>{detail}</p>}{children}<div className="confirm-actions">{actions.map((a,i)=><button data-dialog-action key={a.id} disabled={busy||a.disabled} className={i===selected?'selected':''} onFocus={()=>{if(selection.current!==i)select(i);}} onPointerDown={()=>select(i)} onClick={()=>{select(i);if(!busy)a.run();}}>{a.label}</button>)}</div></div><ControlHints actions={['select','back']}/></div>;
}
