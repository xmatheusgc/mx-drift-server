import {useEffect,useLayoutEffect,useRef,useState,type MutableRefObject} from 'react';
import {TabBar} from './TabBar';
import {OptionStrip} from './OptionStrip';
import {ControlHints} from './ControlHints';
import {ConfirmDialog} from './ConfirmDialog';
import {adjustControl,focusNext,scrollAnchored} from './navigation';
import {usesNativeNavigation} from './input-boundary';
import './character.css';
type Data=Record<string,any>;
type Region='head'|'torso'|'legs'|'feet';
type Slot={label:string;key:'components'|'props';index:number;region:Region};
const regions:[Region,string][]=[['head','Cabeça'],['torso','Tronco'],['legs','Pernas'],['feet','Pés']];
const slots:Slot[]=[
 {label:'Chapéus',key:'props',index:0,region:'head'},{label:'Óculos',key:'props',index:1,region:'head'},{label:'Brincos',key:'props',index:2,region:'head'},{label:'Máscaras',key:'components',index:1,region:'head'},
 {label:'Jaquetas',key:'components',index:11,region:'torso'},{label:'Camisetas',key:'components',index:8,region:'torso'},{label:'Braços e luvas',key:'components',index:3,region:'torso'},
 {label:'Colares',key:'components',index:7,region:'torso'},{label:'Mochilas',key:'components',index:5,region:'torso'},{label:'Coletes',key:'components',index:9,region:'torso'},{label:'Emblemas',key:'components',index:10,region:'torso'},
 {label:'Relógios',key:'props',index:6,region:'torso'},{label:'Pulseiras',key:'props',index:7,region:'torso'},
 {label:'Calças',key:'components',index:4,region:'legs'},{label:'Calçados',key:'components',index:6,region:'feet'}
];
const features=['Largura do nariz','Altura do nariz','Comprimento do nariz','Ponte nasal','Ponta do nariz','Assimetria nasal','Altura das sobrancelhas','Profundidade das sobrancelhas','Altura das maçãs','Largura das maçãs','Volume das bochechas','Abertura dos olhos','Espessura dos lábios','Largura da mandíbula','Formato da mandíbula','Altura do queixo','Comprimento do queixo','Largura do queixo','Formato do queixo','Largura do pescoço'];
const overlays=['Marcas','Barba','Sobrancelhas','Envelhecimento','Maquiagem','Blush','Pele','Danos do sol','Batom','Sardas','Pelos do peito','Marcas do corpo','Detalhes do corpo'];
const faceTabs=[['base','Genética'],['features','Traços faciais'],['skin','Pele'],['hair','Cabelo e barba'],['body','Corpo']];

function Selector({label,value,min=0,max,onChange,disabled=false,names}:{label:string;value:number;min?:number;max:number;onChange:(n:number)=>void;disabled?:boolean;names?:string[]}){
 const move=(step:number)=>onChange(value+step<min?max:value+step>max?min:value+step);
 const text=value<0?'Nenhum':names?.[value]??`${value+1} / ${max+1}`;
 return <div className="character-setting"><strong>{label}</strong><div className="character-selector"><button tabIndex={-1} aria-label={label+': anterior'} disabled={disabled||max<min} onClick={()=>move(-1)}>‹</button><PreciseNumber label={label} value={value<0?0:value+1} min={min<0?0:1} max={max+1} disabled={disabled||max<min} step={1} choice description={text} onChange={v=>onChange(v===0?-1:Math.round(v)-1)}/><button tabIndex={-1} aria-label={label+': próximo'} disabled={disabled||max<min} onClick={()=>move(1)}>›</button></div></div>;
}
function FineSlider({label,value,min=-1,max=1,onChange,disabled}:{label:string;value:number;min?:number;max?:number;onChange:(n:number)=>void;disabled:boolean}){
 const set=(v:number)=>{if(Number.isFinite(v))onChange(Number(Math.min(max,Math.max(min,v)).toFixed(2)));};
 return <div className="character-setting character-slider"><strong>{label}</strong><input aria-label={label} type="range" min={min} max={max} step="0.01" value={value} disabled={disabled} onChange={e=>set(Number(e.target.value))}/><span className="character-extremes"><span>{min}</span><PreciseNumber label={label+': valor exato'} value={value} min={min} max={max} disabled={disabled} onChange={set}/><span>{max}</span></span></div>;
}
function PreciseNumber({label,value,min,max,disabled,onChange,step=.01,choice=false,description}:{label:string;value:number;min:number;max:number;disabled:boolean;onChange:(v:number)=>void;step?:number;choice?:boolean;description?:string}){
 const [text,setText]=useState(String(value)),editing=useRef(false);
 useEffect(()=>{setText(String(value));},[value]);
 return <span className={choice?'character-choice-value':'character-number'}><input data-character-choice={choice?'true':undefined} aria-label={label} aria-valuetext={description} title={description} type="number" min={min} max={max} step={step} disabled={disabled} value={text} onFocus={()=>{editing.current=true;}} onChange={e=>setText(e.target.value)} onBlur={()=>{editing.current=false;const n=Number(text);if(text.trim()&&Number.isFinite(n)){const v=Number(Math.max(min,Math.min(max,step===1?Math.round(n):n)).toFixed(2));if(v!==value)onChange(v);setText(String(v));}else setText(String(value));}} onKeyDown={e=>{if(e.key==='Enter'){e.preventDefault();e.stopPropagation();e.currentTarget.blur();}}}/>{choice&&<small aria-hidden="true">{description}</small>}</span>;
}
export function CharacterEditor({mode,draft,confirmed,caps,busy,local,onChange,onCaps,onError,onExit,onSave,barrier}:{mode:'clothes'|'appearance';draft:Data;confirmed:Data;caps:Data|null;busy:boolean;local:(action:string,data?:Data)=>Promise<Data>;onChange:(draft:Data)=>void;onCaps:(caps:Data)=>void;onError:(message:string)=>void;onExit:()=>void;onSave:(appearance:Data)=>Promise<void>;barrier:MutableRefObject<()=>Promise<void>>}){
 const root=useRef<HTMLDivElement>(null),[region,setRegion]=useState<Region|null>(null),[slot,setSlot]=useState<Slot|null>(null),[tab,setTab]=useState('base');
 const [facePart,setFacePart]=useState(0);
 const [anchors,setAnchors]=useState<Record<string,{x:number;y:number;visible:boolean}>>({}),[previewing,setPreviewing]=useState(false),[swapping,setSwapping]=useState(false),swappingRef=useRef(false);
 const [replaceModel,setReplaceModel]=useState<number|null>(null);
 const [saving,setSaving]=useState(false),[status,setStatus]=useState(''),saveLock=useRef(false),saved=useRef(JSON.stringify(confirmed));
 const current=useRef({draft,caps,busy,local,onChange,onCaps,onError,onExit,onSave,region,slot,tab,replaceModel});current.current={draft,caps,busy,local,onChange,onCaps,onError,onExit,onSave,region,slot,tab,replaceModel};
 const wanted=useRef(draft),applied=useRef(JSON.stringify(draft)),inflight=useRef<Promise<void>|null>(null),mounted=useRef(true),timer=useRef<ReturnType<typeof setTimeout>|undefined>(undefined);
 wanted.current=draft;
 useEffect(()=>{saved.current=JSON.stringify(confirmed);if(saved.current===JSON.stringify(wanted.current))setStatus(mode==='clothes'?'Peça equipada e salva':'Alterações salvas');},[confirmed]);
 async function flush(){
  clearTimeout(timer.current);
  if(inflight.current){await inflight.current;if(JSON.stringify(wanted.current)!==applied.current)return flush();return;}
  const work=async()=>{while(mounted.current&&(JSON.stringify(wanted.current)!==applied.current||mode==='clothes'&&JSON.stringify(wanted.current)!==saved.current)){
   const next=structuredClone(wanted.current),stamp=JSON.stringify(next);
   try{
    if(stamp!==applied.current){setPreviewing(true);const r=await current.current.local('characterPreview',{appearance:next});applied.current=stamp;if(mounted.current&&stamp===JSON.stringify(wanted.current))current.current.onCaps(r.capabilities);}
    if(mode==='clothes'&&stamp===JSON.stringify(wanted.current)&&stamp!==saved.current){setSaving(true);await current.current.onSave(next);saved.current=stamp;if(mounted.current)setStatus('Peça equipada e salva');}
   }catch(e){const err=e instanceof Error?e:new Error(String(e));if(mounted.current){setStatus('Alterações não salvas');current.current.onError(err.message);}throw err;}finally{if(mounted.current){setPreviewing(false);setSaving(false);}}
  }};
  const task=work();inflight.current=task;try{await task;}finally{if(inflight.current===task)inflight.current=null;}
 }
 barrier.current=flush;
 useEffect(()=>{mounted.current=true;return()=>{mounted.current=false;clearTimeout(timer.current);};},[]);
 useEffect(()=>{if(JSON.stringify(draft)!==applied.current){timer.current=setTimeout(()=>void flush().catch(()=>{}),100);}return()=>clearTimeout(timer.current);},[draft]);
 function emit(next:Data){if(JSON.stringify(next)===JSON.stringify(wanted.current))return;wanted.current=next;setStatus('Alterações pendentes');current.current.onChange(next);}
 function patch(key:string,value:any){emit({...wanted.current,[key]:value});}
 useEffect(()=>{
  if(mode!=='clothes')return;let alive=true,sequence=0;let timeout:ReturnType<typeof setTimeout>;
  const capture=async()=>{const id=++sequence;try{const r=await current.current.local('characterAnchors');if(alive&&id===sequence)setAnchors(r.anchors??{});}catch{/* Stable fallback placement is kept if the view is unavailable. */}};
  const resize=()=>{clearTimeout(timeout);timeout=setTimeout(()=>void capture(),150);};void capture();window.addEventListener('resize',resize);return()=>{alive=false;sequence++;clearTimeout(timeout);window.removeEventListener('resize',resize);};
 },[mode]);
 useLayoutEffect(()=>{const container=root.current;if(!container||replaceModel!==null)return;const nodes=Array.from(container.querySelectorAll<HTMLElement>('button:not(:disabled),input:not(:disabled)'));const selected=container.querySelector<HTMLElement>('.character-strip .selected:not(:disabled)');const next=selected??nodes.find(el=>el.tabIndex>=0&&!el.closest('[data-tab-bar]'));next?.focus({preventScroll:true});if(selected)scrollAnchored(selected.parentElement!,selected);},[region,slot?.index,slot?.key,tab,replaceModel]);
 useEffect(()=>{
  if(mode!=='appearance')return;
  void current.current.local('camera',{context:tab==='body'?'character':'face'}).catch(e=>current.current.onError(String(e)));
 },[mode,tab]);
 function back(){(document.activeElement as HTMLElement)?.blur();const c=current.current;if(c.replaceModel!==null){setReplaceModel(null);return;}if(mode==='clothes'&&c.slot){setSlot(null);return;}if(mode==='clothes'&&c.region){setRegion(null);return;}if(mode==='clothes'){void flush().catch(()=>{}).then(()=>current.current.onExit());}else c.onExit();}
 async function save(){if(saveLock.current||current.current.busy||swappingRef.current)return;saveLock.current=true;setSaving(true);try{(document.activeElement as HTMLElement)?.blur();await flush();await current.current.onSave(structuredClone(wanted.current));saved.current=JSON.stringify(wanted.current);setStatus('Alterações salvas');}catch(e){setStatus('Alterações não salvas');current.current.onError(String(e));}finally{saveLock.current=false;if(mounted.current)setSaving(false);}}
 function nav(key:string){
  const c=current.current;if(c.busy||swappingRef.current||document.querySelector('[data-confirm-dialog]'))return;
  if(key==='back'||key==='escape'){back();return;}
  if(key==='saveCharacter'){void save();return;}
  if(key==='enter'){if(root.current?.contains(document.activeElement))(document.activeElement as HTMLElement)?.click();return;}
  if(!['left','right','up','down'].includes(key)||!root.current)return;
  const el=document.activeElement as HTMLElement;
  if(el?.matches('[data-character-choice]')&&['left','right'].includes(key)){el.closest('.character-selector')?.querySelectorAll<HTMLButtonElement>('button')[key==='left'?0:1]?.click();return;}
  if(el&&root.current.contains(el)&&adjustControl(el,key))return;
  if(['up','down'].includes(key)){
   const nodes=Array.from(root.current.querySelectorAll<HTMLElement>('button:not(:disabled),input[type=range]:not(:disabled),input[data-character-choice]:not(:disabled)')).filter(n=>n.tabIndex>=0&&!n.closest('[data-tab-bar]'));
   const at=nodes.indexOf(el),next=nodes[Math.max(0,Math.min(nodes.length-1,at+(key==='down'?1:-1)))];next?.focus({preventScroll:true});next?.scrollIntoView({block:'nearest'});return;
  }
  focusNext(root.current,key);
 }
 useEffect(()=>{
  const message=(e:MessageEvent)=>{if(document.querySelector('[data-confirm-dialog]'))return;if(e.data?.type==='nav'||e.data?.type==='workshopBack'){e.stopImmediatePropagation();nav(e.data.type==='workshopBack'?'back':e.data.key);}};
  const keyboard=(e:KeyboardEvent)=>{if(document.querySelector('[data-confirm-dialog]'))return;const el=e.target as HTMLInputElement;if(e.code==='Space'&&!e.ctrlKey&&!e.altKey&&!e.metaKey){e.preventDefault();e.stopImmediatePropagation();if((!usesNativeNavigation()||el?.type==='number')&&!e.repeat)void save();return;}if(usesNativeNavigation()&&el?.type!=='number')return;const key=({ArrowUp:'up',ArrowDown:'down',ArrowLeft:'left',ArrowRight:'right',Enter:'enter',Escape:'back',Backspace:'back'} as Record<string,string>)[e.key];if(!key)return;if(el?.matches('[data-character-choice]')&&['left','right','up','down'].includes(key)){e.preventDefault();e.stopImmediatePropagation();nav(key);return;}if(el?.type==='number'&&e.key!=='Escape')return;e.preventDefault();e.stopImmediatePropagation();if(!e.repeat||!['enter','back'].includes(key))nav(key);};
  window.addEventListener('message',message,true);window.addEventListener('keydown',keyboard,true);return()=>{window.removeEventListener('message',message,true);window.removeEventListener('keydown',keyboard,true);};
 },[mode]);
 const available=slots.filter(s=>(caps?.[s.key]?.[s.index]?.count??0)>0);
 const regionLabel=regions.find(([key])=>key===region)?.[1];
 function chooseSlot(s:Slot){setSlot(s);}
 function choosePiece(s:Slot,index:number){const a=wanted.current[s.key];if(a[s.index].drawable===index)return;patch(s.key,a.map((v:Data,i:number)=>i===s.index?{drawable:index,texture:0}:v));}
 const item=slot?draft[slot.key][slot.index]:null,slotCaps=slot?caps?.[slot.key]?.[slot.index]:null;
 const select=(label:string,value:number,max:number,change:(v:number)=>void,min=0,names?:string[])=><Selector label={label} value={value} max={max} min={min} onChange={change} disabled={busy} names={names}/>;
 const slider=(label:string,value:number,change:(v:number)=>void,min=-1,max=1)=><FineSlider label={label} value={value} onChange={change} min={min} max={max} disabled={busy}/>;
 const trait=(index:number)=> <div key={'feature'+index}>{slider(features[index],draft.features[index],v=>patch('features',wanted.current.features.map((n:number,i:number)=>i===index?v:n)))}</div>;
 const overlay=(index:number)=>{const o=draft.overlays[index],count=caps?.overlays?.[index]??0;if(!count)return null;const set=(key:string,value:number)=>patch('overlays',wanted.current.overlays.map((n:Data,i:number)=>i===index?{...n,[key]:value}:n));return <section className="character-detail" key={'overlay'+index}><h3>{overlays[index]}</h3>{select('Estilo de '+overlays[index].toLocaleLowerCase(),o.index,count-1,v=>set('index',v),-1)}{o.index>=0&&<>{slider('Intensidade de '+overlays[index].toLocaleLowerCase(),o.opacity,v=>set('opacity',v),0,1)}{[1,2,4,5,8,10].includes(index)&&select('Cor de '+overlays[index].toLocaleLowerCase(),o.color,63,v=>set('color',v))}</>}</section>;};
 async function modelPreset(model:string){if(swappingRef.current)return;swappingRef.current=true;setSwapping(true);try{await flush();const r=await current.current.local('characterPreset',{model,outfit:0});applied.current=JSON.stringify(r.appearance);current.current.onCaps(r.capabilities);emit(r.appearance);setReplaceModel(null);await current.current.local('camera',{context:'face',force:true});}catch(e){current.current.onError(String(e));}finally{swappingRef.current=false;setSwapping(false);}}
 const modelNames=['Masculino','Feminino'],modelIndex=draft.model==='mp_f_freemode_01'?1:0;
 return <div className={'character-editor character-'+mode} ref={root} data-character-editor data-character-level={mode==='appearance'?tab:slot?'models':region?'types':'regions'} aria-busy={busy}>
  {mode==='clothes'?<>
   <div className="character-heading"><small>ROUPAS & ACESSÓRIOS</small><h2>{regionLabel??'SEU ESTILO'}</h2><p>{slot?`${regionLabel} / ${slot.label}`:region?'Escolha um tipo de peça':'Escolha uma parte do corpo'}</p></div>
   {!region&&<div className="character-hotspots" aria-label="Partes do corpo">{regions.map(([key,label],i)=>{const a=anchors[key],visible=a?.visible;const top=visible?Math.max(14,Math.min(86,a.y*100)):22+i*20;const left=visible?a.x*100:68;return <button key={key} aria-label={label} disabled={busy||!available.some(s=>s.region===key)} style={{top:top+'vh',left:`clamp(5vw, calc(${left}vw - 22px), calc(95vw - 180px))`}} onClick={()=>{setRegion(key);}} className="character-hotspot" data-region={key}><i aria-hidden="true"/><span>{label}</span></button>;})}</div>}
   {region&&!slot&&<OptionStrip className="character-strip heat-strip" label={'Peças de '+regionLabel}>{available.filter(s=>s.region===region).map(s=><button className="heat-tile" key={s.key+s.index} disabled={busy} onClick={()=>chooseSlot(s)}><strong>{s.label}</strong><small>Ver modelos</small></button>)}{!available.some(s=>s.region===region)&&<p>Nenhuma peça disponível nesta região.</p>}</OptionStrip>}
   {slot&&<>
    <div className="character-variation">{item.drawable>=0&&(slotCaps?.textures??0)>1&&<Selector label="Variação" value={item.texture} max={slotCaps.textures-1} disabled={busy||previewing||applied.current!==JSON.stringify(draft)} onChange={v=>patch(slot.key,wanted.current[slot.key].map((n:Data,i:number)=>i===slot.index?{...n,texture:v}:n))}/>}<p>{previewing?'Equipando…':saving?'Salvando peça…':'A peça é salva ao equipar.'}</p>{['Jaquetas','Camisetas','Braços e luvas'].includes(slot.label)&&<p>Combine jaqueta, camiseta e braços para evitar sobreposições.</p>}</div>
    <OptionStrip className="character-strip heat-strip" label={'Modelos de '+slot.label}>{Array.from({length:(slotCaps?.count??0)+(slot.key==='props'?1:0)},(_,i)=>i-(slot.key==='props'?1:0)).map(i=><button key={i} data-drawable={i} className={'heat-tile'+(item.drawable===i?' selected':'')} aria-pressed={item.drawable===i} disabled={busy} onFocus={e=>scrollAnchored(e.currentTarget.parentElement!,e.currentTarget)} onClick={()=>choosePiece(slot,i)}><strong>{i<0?'Nenhum':`Modelo ${i+1}`}</strong><small>{i===item.drawable?(saved.current===JSON.stringify(draft)?'Equipado':'Equipando…'):slot.label}</small></button>)}</OptionStrip>
   </>}
  </>:<>
   <div className="character-heading"><small>PERSONAGEM / APARÊNCIA</small><h2>SEUS TRAÇOS</h2></div>
   <TabBar className="character-face-tabs" label="Partes da aparência">{faceTabs.map(([id,label])=><button key={id} className={tab===id?'selected':''} disabled={busy} onClick={()=>{(document.activeElement as HTMLElement)?.blur();setTab(id);}}>{label}</button>)}</TabBar>
   <div className="character-face-panel" aria-label={faceTabs.find(([id])=>id===tab)?.[1]}>
    {tab==='base'&&<>{select('Modelo',modelIndex,1,v=>setReplaceModel(v),0,modelNames)}<p>A troca de modelo redefine o rosto e as roupas; você poderá cancelar antes de salvar.</p>{['shapeFirst','shapeSecond','skinFirst','skinSecond'].map((key,i)=><div key={key}>{select(['Herança facial A','Herança facial B','Tonalidade A','Tonalidade B'][i],draft[key],45,v=>patch(key,v))}</div>)}{slider('Mistura do rosto',draft.shapeMix,v=>patch('shapeMix',v),0,1)}{slider('Mistura da pele',draft.skinMix,v=>patch('skinMix',v),0,1)}</>}
    {tab==='hair'&&<>{select('Corte de cabelo',draft.components[2].drawable,(caps?.components?.[2]?.count??1)-1,v=>patch('components',wanted.current.components.map((n:Data,i:number)=>i===2?{drawable:v,texture:0}:n)))}{select('Cor do cabelo',draft.hairColor,63,v=>patch('hairColor',v))}{select('Reflexos do cabelo',draft.hairHighlight,63,v=>patch('hairHighlight',v))}{overlay(1)}{overlay(2)}</>}
    {tab==='skin'&&[0,3,6,7,9,4,5,8].map(overlay)}
    {tab==='features'&&<>{select('Região do rosto',facePart,4,setFacePart,0,['Olhos e sobrancelhas','Nariz','Boca','Bochechas','Mandíbula e queixo'])}<h3>{['Olhos e sobrancelhas','Nariz','Boca','Bochechas','Mandíbula e queixo'][facePart]}</h3>{facePart===0&&select('Cor dos olhos',draft.eyeColor,31,v=>patch('eyeColor',v))}{[[6,7,11],[0,1,2,3,4,5],[12],[8,9,10],[13,14,15,16,17,18,19]][facePart].map(trait)}</>}
    {tab==='body'&&[10,11,12].map(overlay)}
   </div>
   <p className="character-fine-hint">Setas: ajuste de 0,01 · Digite o valor para maior precisão</p>
  </>}
  <footer className="character-footer"><ControlHints actions={['navigate','select','saveCharacter','back']}/><span className="character-save-status" role="status">{saving?'Salvando…':previewing?'Atualizando…':status}</span></footer>
  {replaceModel!==null&&<ConfirmDialog title={'Trocar para '+modelNames[replaceModel]+'?'} detail="O rosto e as roupas em edição serão substituídos pelo conjunto inicial." busy={busy||previewing||swapping} onCancel={()=>setReplaceModel(null)} actions={[{id:'keep',label:'Continuar editando',run:()=>setReplaceModel(null)},{id:'replace',label:'Trocar modelo',run:()=>void modelPreset(replaceModel===1?'mp_f_freemode_01':'mp_m_freemode_01')}]} />}
 </div>;
}
