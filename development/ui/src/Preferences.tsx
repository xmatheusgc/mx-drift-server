import {useEffect,useRef,useState} from 'react';
import {api,nui} from './api';
import {SettingsRow} from './SettingsRow';
import {TabBar} from './TabBar';
import {ServerBindings} from './ServerBindings';
import {focusFirstContent} from './navigation';
import {usesNativeNavigation} from './input-boundary';
export function Preferences(){
 const [page,setPage]=useState('general');
 const [profile,setProfile]=useState<any>(null),[drive,setDrive]=useState(false),[reduce,setReduce]=useState(false),[busy,setBusy]=useState(false),[error,setError]=useState('');
 const [dirty,setDirty]=useState(false),[status,setStatus]=useState('');
 const root=useRef<HTMLElement>(null),focused=useRef(false),locked=useRef(false),apply=useRef(()=>{});
 useEffect(()=>{focused.current=false;},[page]);
 useEffect(()=>{if(profile&&!busy&&!focused.current){focusFirstContent(root.current?.querySelector('.preferences-body')??null);focused.current=true;}},[profile,busy,page]);
 const local=(action:string,data:object={})=>nui<any>('experienceLocal',{action,...data});
 async function run(fn:()=>Promise<void>){if(locked.current)return;const prior=document.activeElement instanceof HTMLElement&&root.current?.contains(document.activeElement)?document.activeElement:null;locked.current=true;setBusy(true);setError('');try{await fn();}catch(e){setError(String(e instanceof Error?e.message:e));}finally{locked.current=false;setBusy(false);requestAnimationFrame(()=>{if(prior?.isConnected&&!prior.hasAttribute('disabled')&&!prior.closest('[data-tab-bar]'))prior.focus({preventScroll:true});});}}
 useEffect(()=>{void run(async()=>{const p=await api('core','profile'),d=await local('drivecam'),r=await local('preferences');setProfile(p);setDrive(d.enabled);setReduce(r.reduceMotion);});},[]);
 const patch=(key:string,value:unknown)=>{setProfile((p:any)=>({...p,preferences:{...p.preferences,[key]:value}}));setDirty(true);setStatus('');};
 apply.current=()=>{if(page!=='general'||!profile||!dirty||busy)return;void run(async()=>{const p=await api('core','preferences',{revision:profile.revision,preferences:profile.preferences});setProfile(p);setDirty(false);setStatus('Alterações aplicadas');});};
 useEffect(()=>{
  const message=(e:MessageEvent)=>{if(e.data?.type==='nav'&&e.data.key==='applySettings'&&!document.querySelector('[data-confirm-dialog]'))apply.current();};
  const key=(e:KeyboardEvent)=>{if(usesNativeNavigation()||e.code!=='Space'||e.ctrlKey||e.altKey||e.metaKey||document.querySelector('[data-confirm-dialog],[data-binding-capture]'))return;e.preventDefault();e.stopImmediatePropagation();if(!e.repeat)apply.current();};
  window.addEventListener('message',message);window.addEventListener('keydown',key,true);return()=>{window.removeEventListener('message',message);window.removeEventListener('keydown',key,true);};
 },[]);
 const toggle=(label:string,value:boolean,change:(v:boolean)=>void)=><select aria-label={label} disabled={busy} value={value?'on':'off'} onChange={e=>change(e.target.value==='on')}><option value="off">Desligado</option><option value="on">Ligado</option></select>;
 return <section className="preferences-fields settings-list" aria-busy={busy} ref={root} data-settings-page={page} onFocus={e=>{const surface=(e.target as HTMLElement).closest<HTMLElement>('.settings-row,.server-bindings button');if(surface)requestAnimationFrame(()=>surface.isConnected&&surface.scrollIntoView({block:'nearest',inline:'nearest'}));}}>
 <TabBar label="Seções das configurações">{[['general','Geral'],['bindings','Atalhos do servidor']].map(([id,label])=><button key={id} className={page===id?'selected':''} onClick={()=>setPage(id)}>{label}</button>)}</TabBar>
 <div className="preferences-body">{page==='bindings'?<ServerBindings/>:<>{error&&<p role="alert">{error}</p>}
 <SettingsRow label="Câmera de condução" description="Usa a câmera personalizada durante a condução. Também pode ser alternada com F7.">{toggle('Câmera de condução personalizada',drive,value=>void run(async()=>setDrive((await local('drivecam',{value})).enabled)))}</SettingsRow>
 <SettingsRow label="Reduzir movimentos" description="Reduz os movimentos de apresentação nas telas de garagem.">{toggle('Reduzir movimentos de apresentação',reduce,value=>void run(async()=>{await local('reduceMotion',{value});setReduce(value);}))}</SettingsRow>
 {profile&&<><SettingsRow label="Velocímetro" description="Exibe velocidade, marcha e informações do veículo ao dirigir.">{toggle('Velocímetro',profile.preferences.hud,value=>patch('hud',value))}</SettingsRow>
 <SettingsRow label="Minimapa" description="Exibe o radar no canto da tela durante o modo livre.">{toggle('Minimapa',profile.preferences.minimap!==false,value=>patch('minimap',value))}</SettingsRow>
 <SettingsRow label="Câmbio" description="Escolha o modo do mx-gearbox. Com handling de drift, o manual fica suspenso até o drift ser desativado."><select disabled={busy} aria-label="Câmbio" value={profile.preferences.transmission??'automatic'} onChange={e=>patch('transmission',e.target.value)}><option value="automatic">Automático</option><option value="manual">Manual</option></select></SettingsRow>
 {([['share','Compartilhar localização','Permite compartilhar sua posição com outros jogadores.'],['uniform','Marcadores uniformes','Usa a mesma apresentação para os marcadores.'],['photo','Ocultar HUD e radar','Oculta os elementos de condução para fotografar.']] as const).map(([key,label,description])=><SettingsRow key={key} label={label} description={description}>{toggle(label,profile.preferences[key]===true,value=>patch(key,value))}</SettingsRow>)}
 <SettingsRow label="Marcadores" description="Escolha quais jogadores aparecem no mapa."><select disabled={busy} aria-label="Marcadores" value={profile.preferences.blips??'all'} onChange={e=>patch('blips',e.target.value)}><option value="all">Todos</option><option value="group">Grupo</option><option value="none">Nenhum</option></select></SettingsRow>
 <SettingsRow label="Convites" description="Escolha quem pode enviar convites."><select disabled={busy} aria-label="Convites" value={profile.preferences.invites??'all'} onChange={e=>patch('invites',e.target.value)}><option value="all">Todos</option><option value="none">Nenhum</option></select></SettingsRow>
 <SettingsRow label="Unidades" description="Unidade usada para apresentar a velocidade do veículo."><select disabled={busy} aria-label="Unidades" value={profile.preferences.units} onChange={e=>patch('units',e.target.value)}><option value="kmh">km/h</option><option value="mph">mph</option></select></SettingsRow>
 {(['scale','volume'] as const).map(key=><SettingsRow key={key} label={key==='scale'?'Tamanho da interface':'Volume dos avisos'} description={key==='scale'?'Ajusta o tamanho do menu compacto de freeroam.':'Ajusta o volume dos avisos da interface.'}><input disabled={busy} aria-label={key==='scale'?'Tamanho da interface de sessão':'Volume dos avisos'} type="range" min={key==='scale'?.75:0} max={key==='scale'?1.5:1} step={.05} value={profile.preferences[key]} onChange={e=>patch(key,Number(e.target.value))}/><output>{Math.round(profile.preferences[key]*100)}%</output></SettingsRow>)}
 </>}
 </>}</div>{page==='general'&&<p className="settings-status" role="status">{busy?'Aguarde…':dirty?'Alterações pendentes':status}</p>}</section>;
}
