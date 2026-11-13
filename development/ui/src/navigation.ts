// Focus never defines logical order by scroll position. Option strips wrap at either end.
export function focusFirstContent(root:HTMLElement|null){
 const nodes=root?.querySelectorAll<HTMLElement>('button:not(:disabled),input:not(:disabled),select:not(:disabled)');
 Array.from(nodes??[]).find(el=>el.getClientRects().length&&!el.closest('[data-tab-bar],[inert]'))?.focus({preventScroll:true});
}
export function anchoredScroll(viewport:HTMLElement,item:HTMLElement){
 const box=viewport.getBoundingClientRect(),child=item.getBoundingClientRect();
 const center=child.left-box.left-viewport.clientLeft+viewport.scrollLeft+child.width/2;
 return Math.max(0,Math.min(viewport.scrollWidth-viewport.clientWidth,center-viewport.clientWidth/2));
}
const scrolling=new WeakMap<HTMLElement,number>();
export function scrollAnchored(viewport:HTMLElement,item:HTMLElement){
 const old=scrolling.get(viewport);if(old)cancelAnimationFrame(old);
 const target=anchoredScroll(viewport,item),from=viewport.scrollLeft,start=performance.now();
 if(matchMedia('(prefers-reduced-motion: reduce)').matches){viewport.scrollLeft=target;return;}
 const tick=(time:number)=>{const t=Math.max(0,Math.min(1,(time-start)/140));viewport.scrollLeft=from+(target-from)*(1-(1-t)**3);if(t<1)scrolling.set(viewport,requestAnimationFrame(tick));else scrolling.delete(viewport);};
 scrolling.set(viewport,requestAnimationFrame(tick));
}
export function focusNext(root:HTMLElement,key:string){
 const scope=root.querySelector<HTMLElement>('[aria-modal=true]')??root;
 const nodes=Array.from(scope.querySelectorAll<HTMLElement>('button:not(:disabled),input:not(:disabled),select:not(:disabled)')).filter(el=>el.getClientRects().length>0&&!el.closest('[data-tab-bar],[inert]'));
 const active=document.activeElement as HTMLElement,at=nodes.indexOf(active);
 if(!nodes.length)return;
 if(at<0){nodes[0].focus({preventScroll:true});const strip=nodes[0].closest<HTMLElement>('.heat-strip,.heat-customization-strip');if(strip)scrollAnchored(strip,nodes[0]);return;}
 const stripScope=active.closest<HTMLElement>('.option-strip,.heat-home-grid');
 if(stripScope&&['left','right'].includes(key)){
  const items=nodes.filter(n=>stripScope.contains(n)),index=items.indexOf(active);
  const next=items[(index+(key==='right'?1:-1)+items.length)%items.length];
  next?.focus({preventScroll:true});if(next)scrollAnchored(stripScope,next);return;
 }
 const a=active.getBoundingClientRect(),horizontal=key==='left'||key==='right',forward=key==='right'||key==='down';
 const x=a.left+a.width/2,y=a.top+a.height/2;
 const candidates=nodes.filter(n=>n!==active).map(n=>{const b=n.getBoundingClientRect(),dx=b.left+b.width/2-x,dy=b.top+b.height/2-y;return {n,along:horizontal?dx:dy,cross:Math.abs(horizontal?dy:dx)};}).filter(p=>forward?p.along>2:p.along< -2).sort((a,b)=>a.cross-b.cross||Math.abs(a.along)-Math.abs(b.along));
 const next=candidates[0]?.n;if(!next)return;
 next.focus({preventScroll:true});
 const strip=next.closest<HTMLElement>('.heat-strip,.heat-customization-strip');
 if(strip)scrollAnchored(strip,next);else next.scrollIntoView({block:'nearest',inline:'nearest'});
}
export function navigateControl(root:HTMLElement,key:string){
 const scope=root.querySelector<HTMLElement>('[aria-modal=true]')??root;
 const active=document.activeElement;
 // A hidden/background input must not consume the first controller arrow.
 if(active&&scope.contains(active)&&active.getClientRects().length&&!active.closest('[data-tab-bar],[inert]')&&adjustControl(active,key))return;
 focusNext(root,key);
}
export function adjustControl(el:Element|null,key:string){
 if(key!=='left'&&key!=='right')return false;
 const step=key==='right'?1:-1;
 if(el instanceof HTMLSelectElement){el.selectedIndex=Math.max(0,Math.min(el.options.length-1,el.selectedIndex+step));el.dispatchEvent(new Event('change',{bubbles:true}));return true;}
 if(el instanceof HTMLInputElement&&['range','number'].includes(el.type)){
  const setter=Object.getOwnPropertyDescriptor(HTMLInputElement.prototype,'value')?.set;
  const v=Math.max(Number(el.min||-Infinity),Math.min(Number(el.max||Infinity),Number(el.value)+step*Number(el.step||1)));
  setter?.call(el,String(v));el.dispatchEvent(new Event('input',{bubbles:true}));return true;
 }
 return false;
}
