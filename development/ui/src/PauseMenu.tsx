import {useEffect,useRef,useState} from 'react';
import {nui} from './api';
import {Preferences} from './Preferences';
import {ConfirmDialog} from './ConfirmDialog';
import {ControlHints} from './ControlHints';
import {focusFirstContent,navigateControl} from './navigation';
export function PauseMenu(){
 const [open,setOpen]=useState(false),[screen,setScreen]=useState('home'),[confirm,setConfirm]=useState<'garage'|'disconnect'|null>(null),[busy,setBusy]=useState(false),[error,setError]=useState('');
 const root=useRef<HTMLDivElement>(null),openedAt=useRef(0),current=useRef({open,screen,confirm,busy});current.current={open,screen,confirm,busy};
 async function action(kind:string){setBusy(true);setError('');try{await nui('pauseAction',{kind,confirmed:kind==='garage'||kind==='disconnect'});}catch(e){setError(e instanceof Error?e.message:String(e));setConfirm(null);}finally{setBusy(false);}}
 const back=()=>{if(current.current.screen==='settings'){setScreen('home');return;}void action('close');};
 useEffect(()=>{
  const message=(e:MessageEvent)=>{const m=e.data;if(m.type==='pauseMenu'){setOpen(m.open===true);setScreen('home');setConfirm(null);setError('');setBusy(false);openedAt.current=performance.now();return;}
   if(m.type==='pauseError'){setError(String(m.message));return;}
   if(m.type!=='nav'||!current.current.open||current.current.confirm||current.current.busy)return;
   if(m.key==='back'){if(root.current?.querySelector('[data-bindings-editor]'))return;back();return;}if(m.key==='enter'){(document.activeElement as HTMLElement)?.click();return;}if(root.current&&['left','right','up','down'].includes(m.key))navigateControl(root.current,m.key);
  };
  const key=(e:KeyboardEvent)=>{const c=current.current;if(!c.open||c.confirm||c.busy)return;
   if(e.key==='Escape'||e.key==='Backspace'&&!(e.target instanceof HTMLInputElement)){if(root.current?.querySelector('[data-bindings-editor]'))return;e.preventDefault();if(!e.repeat&&performance.now()-openedAt.current>150)back();return;}
   if(e.key.startsWith('Arrow')&&root.current&&!(e.target instanceof HTMLInputElement&&e.target.type!=='range')){e.preventDefault();navigateControl(root.current,e.key.slice(5).toLowerCase());}
  };
  window.addEventListener('message',message);window.addEventListener('keydown',key);return()=>{window.removeEventListener('message',message);window.removeEventListener('keydown',key);};
 },[]);
 useEffect(()=>{if(open&&!confirm)focusFirstContent(root.current?.querySelector('[data-pause-content]')??null);},[open,screen,confirm]);
 if(!open)return null;
 return <div className="pause-shell" ref={root} data-screen={screen} aria-label="Menu de pausa do servidor" role="dialog" aria-modal="true">
  <div className="pause-shadow" aria-hidden="true"/>
  <section className={`pause-panel ${screen==='settings'?'pause-settings':''}`} inert={confirm?true:undefined}>
   <header><small>MX / MODO LIVRE</small><h1>{screen==='settings'?'CONFIGURAÇÕES':'SUA SESSÃO'}</h1></header>
   {error&&<p className="pause-error" role="alert">{error}</p>}
   <div data-pause-content inert={confirm?true:undefined}>
   {screen==='settings'?<Preferences/>:<nav aria-label="Opções da sessão">
    <button disabled={busy} onClick={()=>void action('native')}><span>MAPA &amp; OPÇÕES DO JOGO</span><small>Nativo do GTA V</small></button>
    <button disabled={busy} onClick={()=>setScreen('settings')}>CONFIGURAÇÕES <small>Servidor</small></button>
    <button disabled>DISCORD <small>Indisponível por enquanto</small></button>
    <button disabled={busy} onClick={()=>setConfirm('garage')}>VOLTAR PARA A GARAGEM</button>
    <button disabled={busy} onClick={()=>setConfirm('disconnect')}>SAIR DO SERVIDOR</button>
   </nav>}
   </div>
   <footer><ControlHints/></footer>
  </section>
  {confirm&&<ConfirmDialog title={confirm==='garage'?'Voltar para a garagem?':'Sair do servidor?'} detail={confirm==='garage'?'Você sairá do modo livre e abrirá sua garagem.':'Sua conexão com este servidor será encerrada.'} busy={busy} onCancel={()=>setConfirm(null)} actions={[{id:'cancel',label:'Cancelar',run:()=>setConfirm(null)},{id:'confirm',label:confirm==='garage'?'Voltar para a garagem':'Sair do servidor',run:()=>void action(confirm)}]}/>}
 </div>;
}
