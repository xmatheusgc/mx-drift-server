import {vehicleLabel,creationLabel} from './vehicle-label';
import {LoadingHint} from './LoadingHint';
import {ConfirmDialog} from './ConfirmDialog';
import {OptionStrip} from './OptionStrip';
import {focusNext,navigateControl,scrollAnchored} from './navigation';
import {TabBar} from './TabBar';
import {ControlHints} from './ControlHints';
import React,{useEffect,useRef,useState} from 'react';
import {api,nui,uuid} from './api';
import {LatestPreview} from './latest-preview';
import {HeatIcon} from './HeatIcon';
import {VehicleEditor} from './VehicleEditor';
import {CharacterEditor} from './CharacterEditor';
import {uiSound} from './ui-sound';
type Data=Record<string,any>;
const clone=<T,>(x:T):T=>structuredClone(x);
export function Workshop(){
 const [state,setState]=useState<Data|null>(null),[screen,setScreen]=useState('home'),[error,setError]=useState(''),[busy,setBusy]=useState(false),[page,setPage]=useState(0),[model,setModel]=useState<Data|null>(null),[preview,setPreview]=useState<Data|null>(null),[draft,setDraft]=useState<Data|null>(null),[caps,setCaps]=useState<Data|null>(null),[dirty,setDirty]=useState(false),[question,setQuestion]=useState(false),[name,setName]=useState('Minha criação'),[deleteRow,setDeleteRow]=useState<Data|null>(null),[renameRow,setRenameRow]=useState<Data|null>(null);
 const [replacing,setReplacing]=useState(false);
 const [characterMode,setCharacterMode]=useState<'clothes'|'appearance'>('appearance');
 const [brands,setBrands]=useState<string[]>([]);
 const [brand,setBrand]=useState<string|null>(null);
 const lastBrand=useRef<string|null>(null),[brandsToken,setBrandsToken]=useState('');
 const [catalogResult,setCatalogResult]=useState<{key:string;rows:Data[]}>({key:'',rows:[]});
 const catalogKey=JSON.stringify([state?.token,brand,page]);
 const catalogReady=brand?catalogResult.key===catalogKey:brandsToken===state?.token;
 const catalog=brand&&catalogResult.key===catalogKey?catalogResult.rows:[];
 const origin=useRef('home');
 const uncertain=useRef<(()=>Promise<void>)|null>(null);
 const editedVehicle=useRef<Data|null>(null),editorBarrier=useRef<()=>Promise<void>>(async()=>{});
 const characterDraft=useRef<Data|null>(null);
 const pending=useRef<(()=>void)|null>(null),retry=useRef<(()=>Promise<void>)|null>(null),lock=useRef(false),generation=useRef(0),latest=useRef({screen,dirty});
 latest.current={screen,dirty};
 const lobbyAction=useRef<()=>void>(()=>{});
 const focus=useRef<HTMLDivElement>(null),backAction=useRef<()=>void>(()=>{});
 const previews=useRef(new LatestPreview()),stateRef=useRef<Data|null>(state);
 const [previewBusy,setPreviewBusy]=useState(false),[previewTarget,setPreviewTarget]=useState(''),[garageTarget,setGarageTarget]=useState<Data|null>(null);
 stateRef.current=state;
 const local=(action:string,data:Data={})=>nui<Data>('experienceLocal',{action,...data});
 async function run(fn:()=>Promise<void>){if(lock.current)return;lock.current=true;setBusy(true);setError('');try{await previews.current.idle();await fn();retry.current=null;}catch(e){setError(e instanceof Error?e.message:String(e));}finally{setBusy(false);lock.current=false;}}
 function cancelPreview(notify=true){previews.current.cancel();setPreviewBusy(false);const token=stateRef.current?.token;return token&&notify?nui('previewIntent',{token,intent:uuid()}).catch(()=>{}):Promise.resolve();}
 async function requestPreview(data:Data){const intent=uuid(),token=stateRef.current?.token;await nui('previewIntent',{token,intent});return api('experience','preview',{...data,token,intent});}
 function changeBrand(next:string|null){void cancelPreview();setModel(null);setError('');retry.current=null;setPage(0);setBrand(next);if(next)lastBrand.current=next;}
 function choosePreview(row:Data,saved=false){
   uiSound();
   retry.current=null;
   const intent=uuid(),token=stateRef.current?.token;setError('');setPreviewBusy(true);setPreviewTarget(row.id);setModel(null);
   void previews.current.choose(()=>nui('previewIntent',{token,intent}),()=>api('experience','preview',{token,intent,...(saved?{id:row.id}:{model:row.id})}),p=>{setPreview(p);if(saved)setGarageTarget(row);else setModel(row);setPreviewBusy(false);},e=>{setError(String(e instanceof Error?e.message:e));setPreviewBusy(false);});
 }
 function applyState(s:Data){stateRef.current={...s,selected:s.current??s.selected,garage:Array.isArray(s.garage)?s.garage:[]};setState(stateRef.current);setPreview(s.preview??null);setGarageTarget(s.selected??null);setPreviewTarget(s.selected?.id??'');}
 function capability(value:Data){return {...value,mods:Array.isArray(value.mods)?value.mods:[],extras:Array.isArray(value.extras)?value.extras:[]};}
 async function refresh(){const s=await api('experience','state');applyState(s);uncertain.current=null;retry.current=null;setModel(null);setDraft(null);setDirty(false);setScreen(s.phase==='firstCar'?'catalog':s.characterCompleted?'home':'welcomeCharacter');}
 async function mutate(action:string,data:Data,keepEditor=false){
   if(!state)throw Error('Oficina indisponível');
   if(uncertain.current)throw Error('Há uma confirmação pendente. Use Tentar novamente para repetir a mesma operação ou Recarregar estado antes de iniciar outra gravação.');
   const request={...data,operation:uuid(),token:state.token};
   const returnTo=origin.current;
   const operation=async(recover=false)=>{
     const r=await api('experience',action,request);if(r.state)applyState(r.state);else await refresh();
     uncertain.current=null;
     if(keepEditor){
       if(action==='character'){
         if(!state.characterCompleted)origin.current='person';
         setDirty(JSON.stringify(characterDraft.current)!==JSON.stringify(stateRef.current?.appearance));
         return;
       }
       editedVehicle.current=stateRef.current?.current??editedVehicle.current;
       setDraft(clone(stateRef.current?.current?.properties??data.properties));setDirty(false);
       return;
     }
     if(!recover)return;
     if(action==='garage'&&data.action==='add'){setModel(null);setScreen('home');}
     if(action==='character'){setDirty(false);setDraft(null);setScreen(!state.characterCompleted?(state.vehicleCompleted?'home':'catalog'):'person');await camera(state.characterCompleted?'character':'main');}
     if(action==='garage'&&data.action==='save'){setDirty(false);setDraft(null);setScreen(returnTo);if(returnTo==='garage'){setGarageTarget(stateRef.current?.garage.find((r:Data)=>r.id===data.id)??null);setPreviewTarget(data.id);}await camera('main');}
     if(action==='garage'&&data.action==='rename')setRenameRow(null);
     if(action==='garage'&&data.action==='delete')setDeleteRow(null);
     if(action==='select')setScreen('home');
   };
   const repeat=()=>operation(true);uncertain.current=repeat;retry.current=repeat;await operation();
 }
 function ask(go:()=>void,replace=false){const changed=screen==='character'?JSON.stringify(characterDraft.current)!==JSON.stringify(stateRef.current?.appearance):dirty;if(changed){pending.current=go;setReplacing(replace);setQuestion(true);}else go();}
 async function restoreSelection(){if(screen==='vehicle'&&stateRef.current?.current){await api('experience','cosmetic',{token:stateRef.current.token,properties:stateRef.current.current.properties});return;}if((screen==='catalog'&&previewTarget!==state?.selected?.id)||(screen==='garage'&&garageTarget?.id!==state?.selected?.id)){const r=await api('experience','resetPreview',{token:state?.token});applyState(r.state);setModel(null);}}
 async function cancelVisuals(){await editorBarrier.current();await cancelPreview();}
 function navigate(next:string){if(next===screen)return;ask(()=>{const stop=cancelVisuals();void run(async()=>{await stop;generation.current++;await restoreSelection();if(next==='catalog'){setBrand(null);setPage(0);setModel(null);}setScreen(next);setDraft(null);setDirty(false);setGarageTarget(stateRef.current?.selected??null);await camera(next==='person'?'character':'main');});});}
 function goLobby(){ask(()=>{const stop=cancelVisuals();void run(async()=>{await stop;await restoreSelection();await local('lobby');});});}
 backAction.current=()=>{if(question){setQuestion(false);return;}if(deleteRow){setDeleteRow(null);return;}if(renameRow){setRenameRow(null);return;}if(screen==='vehicle'||screen==='character')navigate(needsInitialCharacter()?'welcomeCharacter':origin.current);else if(screen==='garage')navigate('home');else if(screen==='catalog'&&brand){changeBrand(null);}else goLobby();};
 lobbyAction.current=goLobby;
 function needsInitialCharacter(){return !state?.characterCompleted;}
 function completePending(){const next=pending.current;pending.current=null;setTimeout(()=>next?.(),0);}
 async function camera(context:string,data:Data={}){await local('camera',{context,...data});}
 async function editCharacter(entry='appearance'){if(!state)return;origin.current=state.characterCompleted?'person':'welcomeCharacter';setCharacterMode(entry==='clothes'?'clothes':'appearance');await camera(entry==='clothes'?'character':'face');const r=await local('capabilities');setCaps(r.capabilities);characterDraft.current=clone(state.appearance);setDraft(characterDraft.current);setDirty(false);setScreen('character');}
 async function editCar(row:Data=state?.selected){if(!row)return;origin.current=screen==='garage'?'garage':'home';editedVehicle.current=row;if(row.id&&row.id!==stateRef.current?.current?.id){await mutate('select',{id:row.id,revision:stateRef.current?.revision});}const restored=await api('experience','resetPreview',{token:stateRef.current?.token});applyState(restored.state);const p=restored.state.preview;setPreview(p);setCaps(capability(p.capabilities));setDraft(clone(p.properties));setDirty(false);setScreen('vehicle');await camera('main');}
 async function save(){
   if(!state||!draft)return;
   await editorBarrier.current();
   
   if(screen==='character'){await commitCharacter(characterDraft.current??draft);}
   else await mutate('garage',{action:'save',id:editedVehicle.current?.id??state.selected.id,revision:editedVehicle.current?.revision??state.selected.revision,stateRevision:state.revision,properties:draft});
   if(screen==='vehicle'&&origin.current==='garage'){setGarageTarget(stateRef.current?.garage.find((r:Data)=>r.id===editedVehicle.current?.id)??null);setPreviewTarget(editedVehicle.current?.id??'');}
   setDirty(false);setDraft(null);setScreen(screen==='character'?(!state.characterCompleted?(state.vehicleCompleted?'home':'catalog'):'person'):origin.current);await camera(screen==='character'&&state.characterCompleted?'character':'main');
 }
 async function commitCharacter(appearance:Data){
   if(uncertain.current)await uncertain.current();
   const s=stateRef.current;
   if(!s||latest.current.screen!=='character')throw Error('Edição do personagem encerrada.');
   if(s.characterCompleted&&JSON.stringify(s.appearance)===JSON.stringify(appearance))return;
   await mutate('character',{appearance:clone(appearance),revision:s.appearanceRevision},true);
 }
 async function applyCar(properties:Data){
  if(lock.current)throw Error('Aguarde a confirma\u00e7\u00e3o anterior.');
  lock.current=true;setBusy(true);setError('');
  try{await mutate('confirmCurrent',{id:uuid(),properties},true);return capability(stateRef.current?.preview?.capabilities??{});}
  catch(e){setError(e instanceof Error?e.message:String(e));throw e;}finally{lock.current=false;setBusy(false);}
 }
 function useModel(){ask(()=>void run(async()=>{await mutate('useCurrent',{id:uuid(),model:model?.id,name:model?.name});setModel(null);setScreen('home');}),true);}
 function useSaved(row:Data){ask(()=>void run(async()=>{await mutate('select',{id:row.id,revision:stateRef.current?.revision});setScreen('home');}),true);}
 async function discard(){generation.current++;if(screen==='character'){if(uncertain.current)throw Error('Resolva o salvamento pendente antes de descartar.');try{await editorBarrier.current();}catch{/* A rejected local preview still allows restoring the confirmed appearance. */}if(uncertain.current)throw Error('Resolva o salvamento pendente antes de descartar.');}else await editorBarrier.current();if(screen==='character')await local('characterCancel');else if(stateRef.current?.current?.id){const r=await api('experience','discardCurrent',{token:stateRef.current?.token});applyState(r.state);}else if(editedVehicle.current??state?.selected){const p=await requestPreview({id:(editedVehicle.current??state!.selected).id});setPreview(p);}setDraft(null);setDirty(false);await camera('main');}
 useEffect(()=>{
   function message(e:MessageEvent){const m=e.data;
     if(m.type==='lobby'&&m.data){cancelPreview(false);setState(null);}
     if(m.type==='workshopLobby'){lobbyAction.current();}
     if(m.type==='workshop'){generation.current++;cancelPreview(false);uncertain.current=null;if(m.state)applyState(m.state);else setState(null);setError('');setScreen(m.state?.phase==='character'||m.state?.phase==='characterRecovery'?'welcomeCharacter':m.state?.phase==='firstCar'?'catalog':'home');setDirty(false);setDraft(null);setModel(null);setPreview(m.state?.preview??null);}
     if(m.type==='workshopError'){setState(s=>s??{phase:'error'});setError(m.message);}
     // Window postMessage listeners can run before the editor/dialog listener.
     // The parent must explicitly yield navigation ownership, rather than rely
     // on stopImmediatePropagation in a listener registered later.
     if((m.type==='nav'||m.type==='workshopBack')&&(document.querySelector('[data-confirm-dialog]')||(latest.current.screen==='character'||latest.current.screen==='vehicle'&&focus.current?.querySelector('.heat-customization-bar'))))return;
     if(m.type==='workshopBack'){
       backAction.current();
     }
     if(m.type==='nav'&&document.querySelector('[data-confirm-dialog]'))return;
     if(m.type==='nav'&&focus.current&&(m.key==='back'||m.key==='escape')){backAction.current();return;}
     if(m.type==='nav'&&focus.current&&(latest.current.screen!=='vehicle'||!!focus.current.querySelector('[aria-modal=true]'))){const scope=focus.current.querySelector<HTMLElement>('[aria-modal=true]')??focus.current;if(m.key==='enter'){if(scope.contains(document.activeElement))(document.activeElement as HTMLElement)?.click();return;}if(['up','down','left','right'].includes(m.key)){navigateControl(focus.current,m.key);}}
   }
   const keyboard=(e:KeyboardEvent)=>{if(document.querySelector('[data-confirm-dialog]'))return;if(!stateRef.current||latest.current.screen==='character'||(latest.current.screen==='vehicle'&&!document.querySelector('.workshop-modal')))return;if(e.key==='Backspace'&&!(e.target instanceof HTMLInputElement)){e.preventDefault();backAction.current();return;}if(['ArrowUp','ArrowDown','ArrowLeft','ArrowRight'].includes(e.key)&&!(e.target instanceof HTMLInputElement)&&!(e.target instanceof HTMLSelectElement)){e.preventDefault();if(focus.current)focusNext(focus.current,e.key.slice(5).toLowerCase());}if(stateRef.current&&(e.key==='Escape'||e.key==='F1')){e.preventDefault();backAction.current();}};
   window.addEventListener('message',message);window.addEventListener('keydown',keyboard);return()=>{previews.current.cancel();window.removeEventListener('message',message);window.removeEventListener('keydown',keyboard);};
 },[]);
 useEffect(()=>{
   if(!state?.token||screen!=='catalog')return;
   const id=++generation.current,key=catalogKey,token=state.token;
   let requested=0;const load=async()=>{if(id!==generation.current)return;const sequence=++requested;try{
     if(brand){const rows=await api('vehicles','catalog',{page,brand});if(id===generation.current&&sequence===requested&&latest.current.screen==='catalog')setCatalogResult({key,rows:Array.isArray(rows)?rows:[]});}
     else{const makes=await api('vehicles','catalogBrands');if(id===generation.current&&sequence===requested&&latest.current.screen==='catalog'){setBrands(Array.isArray(makes)?makes:[]);setBrandsToken(token);}}
   }catch(e){if(id===generation.current){retry.current=load;setError(e instanceof Error?e.message:String(e));}}};
   const initial=setTimeout(()=>void load(),200),poll=setInterval(()=>void load(),5000);
   return()=>{clearTimeout(initial);clearInterval(poll);if(generation.current===id)generation.current++;};
 },[screen,page,brand,state?.token]);

 useEffect(()=>{if(state?.phase==='firstCar'&&screen==='home')setScreen('catalog');if(state?.phase==='character'&&screen==='home')setScreen('welcomeCharacter');},[state?.phase,screen]);
 useEffect(()=>{
   if(!state||question||deleteRow||renameRow||screen==='vehicle'||screen==='character'||(screen==='catalog'&&!catalogReady))return;
   const id=requestAnimationFrame(()=>{
     const container=focus.current?.querySelector('.workshop-modal')??focus.current;if(!container)return;
     if(screen==='catalog'){
       const items=Array.from(container.querySelectorAll<HTMLButtonElement>('.showroom-options button:not(:disabled)'));
       const restored=!brand?items.find(n=>n.dataset.brand===lastBrand.current):items.find(n=>n.dataset.model===previewTarget);
       (restored??items[0])?.focus({preventScroll:true});
     }else container.querySelector<HTMLElement>('button:not([disabled]):not([data-tab-bar] button),input,select')?.focus();
   });return()=>cancelAnimationFrame(id);
 },[screen,!!state,question,deleteRow,renameRow,brand,page,catalogReady]);
 useEffect(()=>{const root=focus.current;if(!root)return;const strips=Array.from(root.querySelectorAll<HTMLElement>('.heat-strip'));const align=(strip:HTMLElement)=>{const item=strip.contains(document.activeElement)?document.activeElement as HTMLElement:strip.querySelector<HTMLElement>('.selected');if(item)scrollAnchored(strip,item);};const observer=new ResizeObserver(entries=>entries.forEach(e=>align(e.target as HTMLElement)));strips.forEach(strip=>{align(strip);observer.observe(strip);});return()=>observer.disconnect();},[screen,previewTarget,brand,catalog.length,state?.garage?.length]);
 if(!state)return null;
 const button=(text:string,fn:()=>void,disabled=false)=><button disabled={busy||disabled} onClick={()=>{uiSound();fn();}}>{text}</button>;
 const title=screen==='person'?'Personagem':screen==='character'?'Seu personagem':screen==='vehicle'?'Sua assinatura':screen==='catalog'?'Escolha sua próxima criação':screen==='garage'?'Minha garagem':screen==='preferences'?'Preferências':'Sua oficina';

 return <div className="workshop" ref={focus} data-screen={screen} aria-busy={busy||previewBusy}>
   <header className="workshop-header"><b>MX <span>FREEROAM / JDM</span></b><span>{busy?'Confirmando…':previewBusy?'Preparando prévia…':'CRIAÇÕES SEM LIMITES'}</span></header>
   {state.characterCompleted&&state.vehicleCompleted&&!['character','vehicle'].includes(screen)&&<TabBar className="workshop-nav" label="Navegação da garagem">
    {[['home','Meu carro'],['catalog','Showroom'],['person','Personagem']].map(([id,label])=><button key={id} disabled={busy} className={screen===id||(id==='home'&&screen==='garage')?'selected':''} onClick={()=>navigate(id)}>{label}</button>)}
   </TabBar>}
   {screen!=='character'&&<div className="workshop-title"><small>{screen==='catalog'?'CATÁLOGO DE MODELOS':screen==='garage'?'SUAS CRIAÇÕES SALVAS':title}</small><h1>{screen==='home'?vehicleLabel(state.selected)||'SUA OFICINA':screen==='catalog'?model?.name??'ENCONTRE SEU ESTILO':screen==='garage'?creationLabel(garageTarget??state.selected)||'MINHA GARAGEM':title}</h1>{screen==='home'&&state.selected&&<span>{creationLabel(state.selected)} · {!state.current?.id?'N\u00e3o salvo':state.currentDirty?'Altera\u00e7\u00f5es pendentes':'Salvo'}</span>}<div className="heat-tag">{screen==='catalog'?'PRÉVIA TEMPORÁRIA · CONFIRME PARA USAR':screen==='garage'?`${state.garage?.length??0} CRIAÇÕES`:'STANDALONE / GRATUITO'}</div></div>}
   {error&&<aside role="alert" className="workshop-error">{error}<div>{button('Tentar novamente',()=>void run(async()=>{if(uncertain.current)await uncertain.current();else if(retry.current)await retry.current();else{const s=await api('experience','enter');applyState(s);setScreen(s.characterCompleted?'home':'welcomeCharacter');}}))}{button('Recarregar estado',()=>ask(()=>void run(refresh)))}</div></aside>}
   <main className={`workshop-panel ${screen==='home'?'workshop-home':''}`}>
   {screen==='welcomeCharacter'&&<><h2>{state.phase==='characterRecovery'?'Recuperar aparência':'Seu personagem. Seu estilo.'}</h2><p>{state.phase==='characterRecovery'?'A aparência salva não pôde ser interpretada. Sua garagem foi preservada. Confirmar substituirá a aparência por este preset; você também pode editá-lo ou retornar ao lobby.':'Confirme este preset ou edite sua aparência antes de escolher o primeiro carro.'}</p>{button('Confirmar personagem',()=>void run(async()=>{await mutate('character',{appearance:state.appearance,revision:state.appearanceRevision});setScreen(state.vehicleCompleted?'home':'catalog');}))}{button('Editar personagem',()=>void run(()=>editCharacter()))}</>}
   {(screen==='home'||screen==='person')&&<>
     <div className="heat-home-note">{screen==='person'?'ROUPAS / APARÊNCIA':state.selected?'Seu estilo. Sua criação. Pronto para a rua.':state.garage?.length?'Modelos indisponíveis. Suas criações continuam salvas.':'A garagem está vazia. Adicione um veículo para sair.'}</div>
     <div className={screen==='person'?'heat-home-grid character-entry-strip option-strip':'heat-home-grid'} aria-label={screen==='person'?'Personalizar personagem':undefined}>
       {screen==='home'&&button('JOGAR',()=>void run(async()=>{cancelPreview();await api('experience','play',{token:state.token});}),!state.selected||!state.characterCompleted||!state.vehicleCompleted)}
       {screen==='home'?<>{button('Performance · Em breve',()=>{},true)}{button('Customização',()=>void run(()=>editCar()),!state.selected)}{button('Carros salvos',()=>navigate('garage'))}{!state.selected&&button('Adicionar veículo',()=>navigate('catalog'))}</>:<>{button('Roupas & acessórios',()=>void run(()=>editCharacter('clothes')))}{button('Aparência',()=>void run(()=>editCharacter('appearance')))}</>}
     </div>
   </>}
   {screen==='catalog'&&<>
     {!catalogReady&&<p className="heat-empty" role="status">{brand?'Carregando modelos…':'Carregando marcas…'}</p>}
     {!brand&&catalogReady&&<OptionStrip className="heat-strip showroom-options" label="Marcas" count={brands.length}>{brands.map(make=><button className="heat-tile" data-brand={make} key={make} onClick={()=>changeBrand(make)}>{make}</button>)}</OptionStrip>}
     {catalogReady&&(!brand?brands.length===0:catalog.length===0)&&<p className="heat-empty" role="status">{brand?'Nenhum modelo disponível nesta marca.':'Catálogo vazio ou indisponível. Seu perfil foi preservado.'}</p>}
     {brand&&catalogReady&&<><OptionStrip className="heat-strip showroom-options" label="Modelos disponíveis" count={catalog.length}>{catalog.map(row=><button key={row.id} data-model={row.id} className="heat-tile" aria-pressed={previewTarget===row.id} disabled={!row.available||busy} onClick={()=>choosePreview(row)}><HeatIcon name="car"/><strong>{row.name}</strong><small>{row.available?row.category:'Indisponível'}</small></button>)}</OptionStrip>{(page>0||catalog.length===20)&&<div className="showroom-pagination">{button('‹',()=>setPage(p=>Math.max(0,p-1)),page===0)}<span>Página {page+1}</span>{button('›',()=>setPage(p=>p+1),catalog.length<20)}</div>}</>}
     {brand&&catalogReady&&model&&catalog.some(row=>row.id===model.id)&&!previewBusy&&<div className="heat-confirm">{!state.vehicleCompleted?<><label>Nome da criação<input maxLength={48} value={name} onChange={e=>setName(e.target.value)}/></label>{button('Escolher este carro',()=>void run(async()=>{await mutate('garage',{action:'add',id:uuid(),name,model:model.id,stateRevision:state.revision});setModel(null);setScreen('home');}),!name.trim())}</>:button('Usar este carro',useModel)}</div>}
   </>}
   {screen==='garage'&&<>
     {state.garage?.length===0?<p className="heat-empty">Nenhuma criação salva.</p>:<OptionStrip className="heat-strip" label="Criações salvas" count={state.garage?.length}>{state.garage?.map((row:Data)=><button key={row.id} className="heat-tile" disabled={busy} onClick={()=>{if(row.available)choosePreview(row,true);else{cancelPreview();setGarageTarget(row);setPreviewTarget(row.id);setError('Modelo indisponível. A prévia anterior foi mantida; esta criação pode ser renomeada ou excluída.');}}}><HeatIcon name="car"/><strong>{creationLabel(row)}</strong>{row.id===state.selected?.id&&<span className="equipped-badge" aria-label="Equipado">EQUIPADO</span>}<small>{vehicleLabel(row)}{row.available?'':' · Indisponível'}</small></button>)}</OptionStrip>}
     {(garageTarget??state.selected)&&(()=>{const row=garageTarget??state.selected;return <div className="heat-garage-actions">{button('PERSONALIZAR ESTA CRIAÇÃO',()=>ask(()=>void run(()=>editCar(row)),true),previewBusy||!row.available)}{button('USAR ESTA CRIAÇÃO',()=>void run(async()=>{await mutate('select',{id:row.id,revision:state.revision});setScreen('home');}),previewBusy||!row.available)}{button('Duplicar',()=>void run(async()=>{await mutate('garage',{action:'duplicate',id:uuid(),sourceId:row.id,stateRevision:state.revision});}),previewBusy||!row.available)}{button('Renomear',()=>{setRenameRow(row);setName(row.name);},previewBusy)}{button('Excluir',()=>setDeleteRow(row),previewBusy)}</div>;})()}
   </>}
   {screen==='character'&&draft&&<CharacterEditor mode={characterMode} draft={draft} confirmed={state.appearance} caps={caps} busy={busy||question} local={local} onChange={next=>{characterDraft.current=next;setDraft(next);setDirty(JSON.stringify(next)!==JSON.stringify(stateRef.current?.appearance));}} onCaps={setCaps} onError={setError} onExit={()=>navigate(needsInitialCharacter()?'welcomeCharacter':origin.current)} onSave={commitCharacter} barrier={editorBarrier}/>}
   {screen==='vehicle'&&draft&&<VehicleEditor draft={draft} caps={caps} local={local} camera={camera} busy={busy} barrier={editorBarrier} preview={async properties=>{const r=await api('experience','cosmetic',{token:state.token,properties});return capability(r.capabilities);}} apply={applyCar} onExit={()=>navigate(origin.current)}/>}
   </main>
   {!['vehicle','character'].includes(screen)&&<footer className="workshop-footer"><ControlHints/></footer>}
   <LoadingHint active={previewBusy}/>
   {question&&<ConfirmDialog title="Concluir edição do personagem?" busy={busy} onCancel={()=>setQuestion(false)} actions={[{id:'save',label:'Salvar e continuar',run:()=>void run(async()=>{await save();setQuestion(false);completePending();})},{id:'discard',label:'Descartar alterações',run:()=>void run(async()=>{await discard();setQuestion(false);completePending();})},{id:'continue',label:'Continuar editando',run:()=>setQuestion(false)}]}/>}
   {deleteRow&&<ConfirmDialog title={`Excluir “${deleteRow.name}”?`} detail="Esta criação será removida da sua garagem." busy={busy} onCancel={()=>setDeleteRow(null)} actions={[{id:'delete',label:'Excluir',run:()=>void run(async()=>{await mutate('garage',{action:'delete',id:deleteRow.id,revision:deleteRow.revision,stateRevision:state.revision});setDeleteRow(null);})},{id:'keep',label:'Manter',run:()=>setDeleteRow(null)}]}/>}
   {renameRow&&<ConfirmDialog title="Renomear criação" busy={busy} onCancel={()=>setRenameRow(null)} actions={[{id:'rename',label:'Confirmar nome',run:()=>void run(async()=>{await mutate('garage',{action:'rename',id:renameRow.id,revision:renameRow.revision,stateRevision:state.revision,name});setRenameRow(null);})},{id:'cancel',label:'Cancelar',run:()=>setRenameRow(null)}]}><input aria-label="Nome da criação" value={name} maxLength={48} onChange={e=>setName(e.target.value)}/></ConfirmDialog>}

 </div>;
}

