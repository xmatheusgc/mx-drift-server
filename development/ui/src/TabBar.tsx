import {Children,cloneElement,isValidElement,useLayoutEffect,useRef,type ReactElement,type ReactNode} from 'react';
import {ControlGlyph,useInputDevice} from './ControlHints';
export function TabBar({children,className='',label}:{children:ReactNode;className?:string;label:string}){
 const root=useRef<HTMLElement>(null),device=useInputDevice();
 useLayoutEffect(()=>{
  const move=(direction:number)=>{
   const el=root.current;if(!el||!el.getClientRects().length||document.querySelector('[data-confirm-dialog],.session-confirm,[data-binding-capture]')||el.closest('[aria-busy=true]'))return false;
   const buttons=Array.from(el.querySelectorAll<HTMLButtonElement>('.tab-items>button:not(:disabled)'));
   if(!buttons.length)return false;
   const at=Math.max(0,buttons.findIndex(b=>b.classList.contains('selected')||b.getAttribute('aria-selected')==='true'));
   const next=buttons[(at+direction+buttons.length)%buttons.length];
   if(el.contains(document.activeElement))(document.activeElement as HTMLElement)?.blur();
   next?.scrollIntoView({block:'nearest',inline:'nearest'});next?.click();return true;
  };
  const keyboard=(e:KeyboardEvent)=>{
   if(e.target instanceof Element&&e.target.closest('input:not([type=range]):not([type=checkbox]):not([type=radio]):not([type=number]),textarea,[contenteditable=true]'))return;
   if(e.ctrlKey||e.altKey||e.metaKey||e.repeat)return;
   if((e.code==='KeyQ'||e.code==='KeyE')&&move(e.code==='KeyQ'?-1:1)){e.preventDefault();e.stopImmediatePropagation();}
  };
  const message=(e:MessageEvent)=>{if(e.data?.type==='tabNav'&&move(e.data.direction<0?-1:1))e.stopImmediatePropagation();};
  window.addEventListener('keydown',keyboard,true);window.addEventListener('message',message,true);
  return()=>{window.removeEventListener('keydown',keyboard,true);window.removeEventListener('message',message,true);};
 },[]);
 return <nav ref={root} className={className+' tab-bar'} data-tab-bar aria-label={label} onMouseDown={e=>e.preventDefault()}><span className="tab-end" title="Aba anterior"><ControlGlyph device={device} action="tabPrev"/></span><div className="tab-items">{Children.map(children,child=>isValidElement(child)?cloneElement(child as ReactElement<{tabIndex?:number}>,{tabIndex:-1}):child)}</div><span className="tab-end" title="Próxima aba"><ControlGlyph device={device} action="tabNext"/></span></nav>;
}
