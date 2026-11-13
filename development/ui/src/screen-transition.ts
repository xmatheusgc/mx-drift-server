// Only screen-boundary messages pass through this veil. Tabs/editor updates do not.
export function installScreenTransitions(){
 const veil=document.createElement('div');
 veil.className='screen-transition';veil.setAttribute('aria-hidden','true');
 document.body.append(veil);
 const status=document.createElement('div');status.className='loading-status';status.hidden=true;
 status.innerHTML='<div><div class="loading-copy"><strong role="status" aria-live="polite"></strong><p role="status" hidden></p><small aria-hidden="true" hidden></small></div><span class="vehicle-loading-spinner" aria-hidden="true"></span></div>';
 document.body.append(status);
 const title=status.querySelector('strong')!,hint=status.querySelector('p')!,elapsed=status.querySelector('small')!;
 let statusActive=false,statusMessage='',startedAt=0,statusTimer:ReturnType<typeof setTimeout>|undefined;
 const updateStatus=()=>{
  const seconds=Math.floor((performance.now()-startedAt)/1000);
  // Keep native streaming details out of the player-facing status.
  const message=/veículo/i.test(statusMessage)?'Preparando carro…':/oficina|garagem/i.test(statusMessage)?'Preparando garagem…':/lobby/i.test(statusMessage)?'Preparando lobby…':'Carregando…';
  if(title.textContent!==message)title.textContent=message;
  const explanation=seconds>=10?'A primeira visita pode levar mais tempo.':'';
  if(hint.textContent!==explanation)hint.textContent=explanation;
  hint.hidden=!explanation;
  elapsed.hidden=seconds<60;
  elapsed.textContent=seconds>=60?`${Math.floor(seconds/60)}:${String(seconds%60).padStart(2,'0')} de espera`:'';
 };
 setInterval(()=>{if(!status.hidden)updateStatus();},1000);
 let screen='',version=0,waitingForLoading=false,pending:any=null;
 let nativeLoading=false,boundaryLoading=false;
 const hidden=()=>nativeLoading||boundaryLoading||statusActive;
 let wasHidden=false,savedFocus:HTMLElement|null=null;
 const sync=()=>{
  const hide=hidden();
  if(hide&&!wasHidden)savedFocus=document.activeElement instanceof HTMLElement?document.activeElement:null;
  document.documentElement.toggleAttribute('data-screen-loading',statusActive||boundaryLoading||(nativeLoading&&screen!=='garage'));
  // Only an explicit scene operation owns the opaque cover. Native fades also
  // occur after ordinary previews and must never create a second loading page.
  const showStatus=statusActive;
  if(showStatus&&status.hidden){
   startedAt=performance.now();status.dataset.pending='true';
   statusTimer=setTimeout(()=>{delete status.dataset.pending;updateStatus();},600);
  }
  if(!showStatus){clearTimeout(statusTimer);delete status.dataset.pending;}
  status.hidden=!showStatus;
  if(showStatus)updateStatus();
  if(!hide&&wasHidden){
   const previous=savedFocus;
   requestAnimationFrame(()=>{
    if(hidden())return;
    const target=previous?.isConnected&&previous.closest('#root')?previous:document.querySelector<HTMLElement>('.lobby [data-initial]:not(:disabled),.workshop [aria-selected=true]:not(:disabled),.workshop button:not(:disabled),.session-row[aria-selected=true]');
    target?.focus({preventScroll:true});
   });
   savedFocus=null;
  }
  wasHidden=hide;
 };
 const replayed=new WeakSet<Event>();
 const duration=()=>matchMedia('(prefers-reduced-motion: reduce)').matches?0:180;
 async function fade(opacity:number){
  const from=getComputedStyle(veil).opacity;
  veil.getAnimations().forEach(a=>a.cancel());
  veil.style.opacity=String(opacity);
  await veil.animate([{opacity:from},{opacity}],{duration:duration(),easing:'ease-in-out'}).finished.catch(()=>{});
 }
 const paint=()=>new Promise<void>(resolve=>requestAnimationFrame(()=>requestAnimationFrame(()=>resolve())));
 const dispatch=(data:unknown)=>{const event=new MessageEvent('message',{data});replayed.add(event);window.dispatchEvent(event);};
 window.addEventListener('message',event=>{
  if(replayed.has(event))return;
  const m=event.data;
  if(m?.type==='loadingStatus'){
   statusActive=m.active===true;statusMessage=statusActive?String(m.message||'Preparando seu acesso'):'';sync();return;
  }
  if(m?.type==='screenFade'){nativeLoading=m.active===true;sync();return;}
  if(hidden()&&['nav','tabNav','workshopBack','lobbyBack'].includes(m?.type)){event.stopImmediatePropagation();return;}
  if(m?.type==='loadingClosed'){
   if(!waitingForLoading)return;
   waitingForLoading=false;const current=version;
   void fade(0).then(()=>{if(current===version){boundaryLoading=false;sync();veil.style.pointerEvents='none';}});return;
  }
  const target=m?.type==='lobby'&&m.data?'lobby':m?.type==='workshop'&&m.state?'garage':'';
  if(!target){
   if((m?.type==='lobby'&&!m.data&&screen==='lobby')||(m?.type==='workshop'&&!m.state&&screen==='garage')){
    screen='';version++;pending=null;waitingForLoading=false;veil.getAnimations().forEach(a=>a.cancel());veil.style.opacity='0';veil.style.pointerEvents='none';
    boundaryLoading=false;sync();
   }
   return;
  }
  if(target===screen){if(pending){pending=m;event.stopImmediatePropagation();}return;}
  const previous=screen;screen=target;const current=++version;
  waitingForLoading=target==='lobby'&&m.data.initialLoading===true;
  const loadingHandoff=waitingForLoading;
  if(!previous&&!waitingForLoading)return;
  pending=m;event.stopImmediatePropagation();veil.style.pointerEvents='auto';boundaryLoading=true;sync();
  void (async()=>{
   if(loadingHandoff)veil.style.opacity='1';else await fade(1);
   if(current!==version)return;
   const next=pending;pending=null;dispatch(next);await paint();
   if(current!==version||loadingHandoff)return;
   await fade(0);if(current===version){boundaryLoading=false;sync();veil.style.pointerEvents='none';}
  })();
 },true);
 // Prevent an extra keyboard action while the destination is being painted.
 window.addEventListener('keydown',event=>{if(hidden()||pending||waitingForLoading){event.preventDefault();event.stopImmediatePropagation();}},true);
 for(const type of ['pointerdown','click','dblclick','wheel'])window.addEventListener(type,event=>{
  if(hidden()){event.preventDefault();event.stopImmediatePropagation();}
 },{capture:true,passive:false});
}
