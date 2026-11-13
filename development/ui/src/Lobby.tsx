import {focusNext,adjustControl,navigateControl} from './navigation';
import {TabBar} from './TabBar';
import {ControlHints} from './ControlHints';
import {useEffect,useRef,useState} from 'react';
import {api,nui} from './api';
import {Preferences} from './Preferences';
import {uiSound} from './ui-sound';
declare global {interface Window {invokeNative?:(name:string,value:string)=>void}}
export function Lobby(){
 const [data,setData]=useState<any>(null),[screen,setScreen]=useState('home'),[error,setError]=useState(''),[busy,setBusy]=useState(false),[social,setSocial]=useState<any>(null),[tab,setTab]=useState('online'),[query,setQuery]=useState('');
 const root=useRef<HTMLDivElement>(null),current=useRef({data,screen,busy});current.current={data,screen,busy};
 async function run(fn:()=>Promise<void>){setBusy(true);setError('');try{await fn();}catch(e){setError(String(e instanceof Error?e.message:e));}finally{setBusy(false);}}
 async function friends(){setSocial(await api('social','friends'));}
 useEffect(()=>{const handler=(e:MessageEvent)=>{if(e.data.type==='lobby'){setData(e.data.data||null);setScreen('home');setError(e.data.data?.error??'');setSocial(null);}if(e.data.type==='workshop'&&e.data.state)setData(null);};window.addEventListener('message',handler);return()=>window.removeEventListener('message',handler);},[]);
 useEffect(()=>{if(!data)return;let second=0;const first=requestAnimationFrame(()=>{second=requestAnimationFrame(()=>{root.current?.querySelector<HTMLButtonElement>('[data-initial]')?.focus();void nui('lobbyReady',{generation:data.generation}).catch(e=>setError(String(e)));});});return()=>{cancelAnimationFrame(first);cancelAnimationFrame(second);};},[data]);
 useEffect(()=>{if(!data)return;root.current?.querySelector<HTMLElement>('button:not(:disabled):not([data-tab-bar] button),input,select')?.focus();},[screen,data]);
 useEffect(()=>{if(!data||screen!=='social')return;const timer=setInterval(()=>{void friends().catch(e=>setError(String(e)));},10000);return()=>clearInterval(timer);},[data,screen]);
 useEffect(()=>{const key=(e:KeyboardEvent)=>{
  const c=current.current;if(!c.data||!root.current||c.busy)return;
  if(e.key==='Escape'||(e.key==='Backspace'&&!(e.target instanceof HTMLInputElement))||e.key==='F1'){if(root.current?.querySelector('[data-bindings-editor]'))return;e.preventDefault();if(c.screen!=='home'){setScreen('home');requestAnimationFrame(()=>root.current?.querySelector<HTMLButtonElement>('[data-initial]')?.focus());}else if(c.data.resume)void run(async()=>{await nui('experienceLocal',{action:'resume'});setData(null);});return;}
  if(!['ArrowUp','ArrowDown','ArrowLeft','ArrowRight'].includes(e.key))return;
  if(e.target instanceof HTMLInputElement&&!['range','checkbox'].includes(e.target.type))return;
  e.preventDefault();const direction=e.key.slice(5).toLowerCase();if(!adjustControl(document.activeElement,direction))focusNext(root.current,direction);
 };const nav=(e:MessageEvent)=>{if(e.data?.type!=='nav'||!current.current.data)return;if(e.data.key==='back'&&root.current?.querySelector('[data-bindings-editor]'))return;e.stopImmediatePropagation();const c=current.current;if(c.busy)return;const k=e.data.key;if(k==='enter'){(document.activeElement as HTMLElement)?.click();return;}if(['left','right','up','down'].includes(k)&&root.current){navigateControl(root.current,k);return;}key(new KeyboardEvent('keydown',{key:({up:'ArrowUp',down:'ArrowDown',left:'ArrowLeft',right:'ArrowRight',back:'Escape'} as Record<string,string>)[k]}));};window.addEventListener('keydown',key);window.addEventListener('message',nav);return()=>{window.removeEventListener('keydown',key);window.removeEventListener('message',nav);};},[]);
 if(!data)return null;
 const rows=social?.[tab]??[];
 return <div className="lobby" ref={root} data-screen={screen} data-scene-ready={!data.error&&data.sceneReady!==false} aria-busy={busy}><div className="lobby-background" aria-hidden="true"/><div className="lobby-brand"><small>FREEROAM / JDM</small><h1>MX</h1><p>{screen==='home'?'SEU PRÓXIMO DESTINO':screen==='preferences'?'CONFIGURAÇÕES':'JOGADORES E AMIGOS'}</p></div>
 {error&&<aside className="lobby-error" role="alert">{error}{data.error&&<button data-initial disabled={busy} onClick={()=>void run(async()=>{await nui('experienceLocal',{action:'lobby'});})}>Tentar novamente</button>}</aside>}
 {screen==='home'?<div className="lobby-groups"><div><button data-initial disabled={busy} onClick={()=>void run(async()=>{uiSound();await nui('openGarage');})}>Garagem</button><button disabled>Criar grupo <small>Em breve</small></button></div><div><button disabled={busy||!data.discord} title={!data.discord?'Convite do Discord não configurado':undefined} onClick={()=>{if(data.discord&&window.invokeNative)window.invokeNative('openUrl',data.discord);else setError('Discord disponível somente dentro do FiveM.');}}>Discord{!data.discord&&<small>Convite não configurado</small>}</button><button disabled={busy} onClick={()=>setScreen('preferences')}>Configurações</button></div><div><button disabled>Loja <small>Em breve</small></button><button disabled={busy} onClick={()=>void run(async()=>{await friends();setTab('online');setScreen('social');})}>Jogadores e amigos</button></div></div>:<section className="lobby-content">
 {screen==='preferences'?<Preferences/>:<><TabBar label="Listas sociais">{[['online','Online'],['friends','Amigos'],['incoming','Solicitações recebidas'],['outgoing','Solicitações enviadas']].map(([id,label])=><button key={id} className={tab===id?'selected':''} onClick={()=>setTab(id)}>{label}</button>)}</TabBar><label>Procurar jogador<input value={query} onChange={e=>setQuery(e.target.value)} placeholder="Nome do jogador" maxLength={64}/></label>
 <div className="friend-list">{rows.filter((r:any)=>r.name.toLocaleLowerCase().includes(query.toLocaleLowerCase())).map((r:any)=><div key={r.id}><span>{r.name}<small>{tab==='friends'?(r.online?'Online':'Offline'):r.relation==='friend'?'Amigo':r.relation==='outgoing'?'Solicitação enviada':r.relation==='incoming'?'Solicitação recebida':''}</small></span>{tab==='online'&&!r.relation&&<button disabled={busy} onClick={()=>void run(async()=>{await api('social','friendSend',{target:r.id});await friends();})}>Adicionar amigo</button>}{tab==='incoming'&&<>{[true,false].map(accept=><button key={String(accept)} disabled={busy} onClick={()=>void run(async()=>{await api('social','friendRespond',{target:r.id,accept});await friends();})}>{accept?'Aceitar':'Recusar'}</button>)}</>}</div>)}</div>{rows.length===0&&<p>Nenhum jogador nesta lista.</p>}<button disabled={busy} onClick={()=>void run(friends)}>Atualizar listas</button></>}
 </section>}
 <footer><ControlHints/></footer></div>;
}
