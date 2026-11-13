import {PaintPanel} from './PaintPanel';
import {resetStanceForWheelChange} from './wheel-stance';
import {ConfirmDialog} from './ConfirmDialog';
import {TabBar} from './TabBar';
import {StancePanel} from './StancePanel';
import {OptionStrip} from './OptionStrip';
import {ColorPanel} from './ColorPanel';
import {anchoredScroll,scrollAnchored} from './navigation';
import React,{useEffect,useRef,useState} from 'react';
import {HeatIcon} from './HeatIcon';
import {LatestPreview} from './latest-preview';
import {uiSound} from './ui-sound';
import {uuid} from './api';
import {OrbitSurface,type OrbitInput} from './OrbitSurface';
import {ControlHints,useInputDevice} from './ControlHints';
type Data=Record<string,any>;
type Item={id:string;label:string;slot?:number;field?:string;value?:any;kind?:string;disabled?:boolean};
type Frame={id:string;title:string;kind:string;items:Item[];base?:Data;field?:string;slot?:number};
const names:Record<number,string>={0:'Aerofólio',1:'Para-choque dianteiro',2:'Para-choque traseiro',3:'Saias',4:'Escapamento',5:'Chassi',6:'Grade',7:'Capô',8:'Para-lama esquerdo',9:'Para-lama direito',10:'Teto',11:'Motor',12:'Freios',13:'Transmissão',14:'Buzina',15:'Suspensão',16:'Blindagem',23:'Rodas dianteiras',24:'Rodas traseiras / equipamento',25:'Suporte de placa',26:'Placa decorativa',27:'Acabamento interno',28:'Ornamentos',29:'Painel',30:'Instrumentos',31:'Alto-falantes',32:'Bancos',33:'Volante',34:'Alavanca',35:'Placa interna',36:'Áudio',37:'Porta-malas',38:'Equipamento hidráulico',39:'Bloco do motor',40:'Filtro de ar',41:'Reforço do motor',42:'Arcos',43:'Antena',44:'Acabamento externo',45:'Tanque',46:'Porta esquerda',47:'Porta direita',48:'Livery do modkit',49:'Barra de luzes'};
const wheels=['Sports / Esportivas','Muscle','Lowrider','SUV','Off-road','Tuner','Moto','High End / Luxo','Benny’s originais','Benny’s especiais','Open Wheel','Street','Track'];
const numeric=(n:number,start=0,prefix='Opção'):Item[]=>Array.from({length:n},(_,i)=>({id:String(i+start),label:`${prefix} ${i+start}`,value:i+start}));
const field=(id:string,label:string,kind='indexed'):Item=>({id,label,field:id,kind});
export function VehicleEditor({draft,caps,local,camera,preview,barrier,apply,onExit,busy}:{draft:Data;caps:Data|null;local:(a:string,d?:Data)=>Promise<Data>;camera:(c:string,d?:Data)=>Promise<void>;preview:(properties:Data)=>Promise<Data>;barrier:React.MutableRefObject<()=>Promise<void>>;apply:(properties:Data)=>Promise<Data>;onExit:()=>void;busy:boolean}){
 const [frames,setFrames]=useState<Frame[]>([]),[memory,storeMemory]=useState<Record<string,string>>({}),[available,setAvailable]=useState(caps),[error,setError]=useState(''),[loading,setLoading]=useState(false),[free,setFree]=useState(false),[input,setInput]=useState<any>(null),[edges,setEdges]=useState({left:false,right:false});
 const memoryRef=useRef(memory);function setMemory(update:(v:Record<string,string>)=>Record<string,string>){const next=update(memoryRef.current);memoryRef.current=next;storeMemory(next);}
 const [color,setColor]=useState<any>(null);const colorNav=useRef<(key:string)=>void>(()=>{});
 const presentationReady=useRef<Promise<Data>>(Promise.resolve({})),neonQueue=useRef(Promise.resolve()),neonGeneration=useRef(0);
 const [night,setNight]=useState(false),[hideFreeUi,setHideFreeUi]=useState(false);const stanceNav=useRef<(key:string)=>void>(()=>{});
 const stanceDraft=useRef<Data|null>(null),[stanceQuestion,setStanceQuestion]=useState(false);
 const [stanceDisplay,setStanceDisplay]=useState<Data|false|null>(null),[stanceWarning,setStanceWarning]=useState('');
 const priorFrame=useRef(''),modality=useRef('keyboard');
 const device=useInputDevice();
 const session=useRef(uuid()),queue=useRef(new LatestPreview(180)),draftRef=useRef(draft),nav=useRef<(key:string)=>void>(()=>{}),held=useRef(false),alive=useRef(true),lock=useRef(false),strip=useRef<HTMLDivElement>(null),inputRef=useRef<HTMLInputElement>(null);
 draftRef.current=draft;
 const visualMods:Item[]=(available?.mods??[]).filter((m:Data)=>![23,24,48].includes(m.slot)).map((m:Data)=>({id:`mod:${m.slot}`,label:names[m.slot]??m.label??`Peça ${m.slot}`,slot:m.slot,kind:'mod'}));
 const wheelItem:Item={id:'wheels',label:'Rodas',kind:'wheels'};
 const root:Frame={id:'root',title:'Customizar',kind:'root',items:[{id:'body',label:'Peças e rodas',kind:'body'},{id:'exterior',label:'Pintura & liveries',kind:'exterior'},{id:'stance',label:'Suspensão',kind:'stance'},{id:'lights',label:'Iluminação & efeitos',kind:'lights'},{id:'details',label:'Interior & detalhes',kind:'details'}]};
 const stanceDefaults={version:1,height:0,frontCamber:0,rearCamber:0,frontOffset:0,rearOffset:0,wheelSize:1,wheelWidth:1};
 const stanceNames:Record<string,string>={height:'Altura',frontCamber:'Cambagem dianteira',rearCamber:'Cambagem traseira',frontOffset:'Afastamento dianteiro',rearOffset:'Afastamento traseiro',wheelSize:'Tamanho das rodas',wheelWidth:'Largura das rodas'};
 const inputSequence=useRef(0);
 const move=(d:OrbitInput)=>void local('orbitInput',{...d,id:session.current,sequence:++inputSequence.current}).catch(e=>alive.current&&setError(String(e)));

 const lighting=frames.some(f=>f.id==='lights'||f.id==='neons');
 const frame=frames.at(-1)??root,selected=Math.max(0,frame.items.findIndex(i=>i.id===memory[frame.id])),item=frame.items[selected];
 const view=(slot?:number,context='main')=>void camera(context,slot===undefined?{}:{slot}).catch(e=>alive.current&&setError(String(e)));
 function show(p:Data,stanceOnly=false){void queue.current.choose(()=>Promise.resolve(),()=>stanceOnly?local('stancePreview',{id:session.current,stance:p.stance}):preview(p),r=>{if(alive.current){setAvailable(previous=>stanceOnly?{...previous,stance:r.stance}:r);setStanceWarning(r.stance?.warning??'');if(r.stance&&'value' in r.stance){setStanceDisplay(r.stance.value);if(frame.kind==='stance'&&stanceDraft.current)stanceDraft.current=r.stance.value;}}},e=>{if(alive.current)setError(String(e));},stanceOnly?0:180);}
 async function settle(){queue.current.cancel();await queue.current.idle();}
 async function run(fn:()=>Promise<void>){if(lock.current||busy)return;lock.current=true;setLoading(true);setError('');try{await fn();}catch(e){if(alive.current)setError(String(e));}finally{lock.current=false;if(alive.current)setLoading(false);}}
 async function commit(p:Data){await settle();const capabilities=await apply(p);if(!alive.current)return;setAvailable(capabilities);const actual=capabilities.stance&&'value' in capabilities.stance?{...p,stance:capabilities.stance.value}:p;draftRef.current=actual;setStanceDisplay(actual.stance??false);setStanceWarning(capabilities.stance?.warning??'');setFrames(v=>v.map((f,n)=>n===v.length-1&&f.kind==='options'?{...f,base:actual}:f));}
 function push(f:Frame){setFrames(v=>[...v,f]);}
 function icon(i:Item){
  if(i.kind==='stanceReset')return 'reset';
  if(i.kind==='stance')return 'suspension';
  if(i.field?.startsWith('stance.')){const k=i.field.slice(7).toLowerCase();return k==='height'?'height':k.includes('camber')?'camber':k.includes('offset')?'track':k==='wheelsize'?'diameter':'tyreWidth';}
  const slot=i.slot??frame.slot;
  if(i.kind==='wheels'||frame.id==='families'||slot===23||slot===24)return 'wheel';
  if(slot===15||slot===38)return 'suspension';
  if(slot!==undefined&&[11,13,39,40,41].includes(slot))return 'engine';
  if(slot!==undefined&&slot>=27&&slot<=36)return 'seat';
  if(slot===49||['lights','neons','neonLayout','headlights'].includes(i.kind??'')||i.field?.match(/xenon|neon/))return 'light';
  if(slot===48||i.kind==='paint'||i.kind==='exterior'||i.field?.match(/primary|secondary|Color|Finish|livery/i))return 'paint';
  if(i.field?.startsWith('plate')||slot===25||slot===26)return 'plate';
  return 'tools';
 }
 function values(i:Item):Item[]{
  if(i.kind==='toggle'&&((i.field==='customTyres'&&(draftRef.current.mods?.['23']??-1)<0)||(i.field==='customRearTyres'&&(draftRef.current.mods?.['24']??-1)<0)))return [{id:'off',label:'Original (selecione rodas para habilitar a variação)',value:false}];
  if(i.kind==='toggle')return [{id:'off',label:'Desligado / original',value:false},{id:'on',label:'Ligado',value:true}];
  if(i.field?.endsWith('Finish'))return ['Original da cor','Normal','Metálico','Perolado','Fosco','Metal','Cromado'].map((label,n)=>({id:String(n-1),label,value:n-1}));
  if(i.field==='tint')return ['Original','Sem película','Preto total','Escuro','Claro','Original alternativo','Limousine','Verde'].map((label,n)=>({id:String(n-1),label,value:n-1}));
  if(i.field==='xenonColor')return [...numeric(13,0,'Cor xenon'),{id:'255',label:'Xenon original',value:255}];
  if(i.field==='plateStyle')return numeric(available?.plateStyles??6,0,'Estilo');
  const n=i.field==='livery'?available?.liveries:i.field==='roofLivery'?available?.roofLiveries:161;
  return [...(['livery','roofLivery','interiorColor','dashboardColor'].includes(i.field??'')?[{id:'-1',label:'Original',value:-1}]:[]),...numeric(n??0,0,'Cor / opção')];
 }
 function candidate(choice:Item){const p=structuredClone(frame.base??draftRef.current);if(frame.slot!==undefined){p.mods={...p.mods,[frame.slot]:choice.value};if(frame.slot===48)p.livery=-1;if(choice.value<0&&frame.slot===23)p.customTyres=false;if(choice.value<0&&frame.slot===24)p.customRearTyres=false;}else if(frame.field?.startsWith('extra:'))p.extras={...p.extras,[frame.field.slice(6)]:choice.value};else if(frame.field?.startsWith('neon:'))p.neon=p.neon.map((v:boolean,i:number)=>i===Number(frame.field!.slice(5))?choice.value:v);else if(frame.field){p[frame.field]=choice.value;if(frame.field==='livery'){p.mods={...p.mods};delete p.mods['48'];}}return resetStanceForWheelChange(draftRef.current,p);}
 function confirmed(i:Item){if(frame.slot!==undefined)return (draft.mods?.[frame.slot]??-1)===i.value&&(frame.base?.wheelType??draft.wheelType)===draft.wheelType;if(frame.field?.startsWith('extra:'))return !!draft.extras?.[frame.field.slice(6)]===i.value;if(frame.field?.startsWith('neon:'))return draft.neon?.[Number(frame.field.slice(5))]===i.value;return frame.field?draft[frame.field]===i.value:false;}
 async function mods(slot:number,base=draftRef.current,title=names[slot]){
  base=resetStanceForWheelChange(draftRef.current,base);
  await settle();const current=await preview(base);if(!alive.current)return;setAvailable(current);
  const mod=(current.mods??[]).find((m:Data)=>m.slot===slot);if(!mod||mod.count<1)throw Error('Esta família/modelo não possui peças neste eixo.');
  const labels=await local('vehicleOptions',{slot});if(!alive.current)return;
  const items=[{id:'-1',label:'Original',value:-1},...numeric(mod.count).map((i,n)=>({...i,label:labels.names?.[n]??`Opção ${n+1}`}))];
  setMemory(v=>({...v,[`options:${slot}`]:String(base.mods?.[slot]??-1)}));push({id:`options:${slot}`,title,kind:'options',slot,base,items});view(slot,'part');
 }
 function fields(kind:string):Item[]{
  if(kind==='decals')return [...(available?.mods?.some((m:Data)=>m.slot===48)?[{id:'mod:48',label:'Adesivos do modelo',slot:48,kind:'mod'}]:[]),...(available?.liveries>0?[field('livery','Adesivo tradicional')]:[]),...(available?.roofLiveries>0?[field('roofLivery','Adesivo do teto')]:[])];
  if(kind==='lights')return [{id:'neons',label:'Neons',kind:'neons'},{id:'headlights',label:'Faróis',kind:'headlights'},field('smoke','Fumaça de pneus','toggle'),field('smokeColor','Cor da fumaça','rgb')];
  return [field('plate','Texto da placa','text'),field('plateStyle','Estilo da placa'),field('tint','Película'),field('interiorColor','Cor do interior'),field('dashboardColor','Cor do painel'),{id:'extras',label:'Extras',kind:'extras'},...(available?.subwoofer?[field('subwoofer','Subwoofer','toggle')]:[]),...(available?.hydraulics?[field('hydraulics','Sistema hidráulico','toggle')]:[]),...(available?.performance?[field('turbo','Turbo nativo','toggle')]:[]),...visualMods.filter(i=>(i.slot!>=27&&i.slot!<=36)||i.slot===14)];
 }
 function isDisabled(i:Item){return !!i.disabled||(!!i.field?.startsWith('extra:')&&!(available?.extras??[]).includes(Number(i.field.slice(6)))&&!enabled(i))||(i.field==='customTyres'&&(draftRef.current.mods?.['23']??-1)<0)||(i.field==='customRearTyres'&&(draftRef.current.mods?.['24']??-1)<0);}
 function enabled(i:Item){const p=draftRef.current;if(i.field==='neonAll')return (available?.neon??[true,true,true,true]).every((valid:boolean,n:number)=>!valid||p.neon[n]);if(i.field?.startsWith('extra:'))return !!(p.extras?.[i.field.slice(6)]??p.extras?.[Number(i.field.slice(6))]);if(i.field?.startsWith('neon:'))return !!p.neon?.[Number(i.field.slice(5))];return !!p[i.field!];}
 function toggle(i:Item){const p=structuredClone(draftRef.current),value=!enabled(i);if(i.field==='neonAll')p.neon=(available?.neon??[true,true,true,true]).map((valid:boolean)=>valid&&value);else if(i.field?.startsWith('neon:'))p.neon=p.neon.map((v:boolean,n:number)=>n===Number(i.field!.slice(5))?value:v);else if(i.field?.startsWith('extra:'))p.extras={...p.extras,[i.field.slice(6)]:value};else p[i.field!]=value;void run(()=>commit(p));}
 function fieldCamera(i:Item){view(i.slot,i.field?.includes('interior')||i.field==='dashboardColor'?'interior':i.field?.startsWith('xenon')?'front':i.field?.startsWith('plate')?'rear':i.field==='roofLivery'?'roof':i.field?.startsWith('neon')?'low':'main');}
 function activate(choice:Item=item){const item=choice;if(!item||isDisabled(item))return;
  if(item.kind==='body'){push({id:'body',title:'Peças e rodas',kind:'body',items:[wheelItem,...visualMods.filter(i=>!(i.slot!>=27&&i.slot!<=36)&&i.slot!==14)]});return;}
  if(item.kind==='exterior'){push({id:'exterior',title:'Pintura & liveries',kind:'exterior',items:[{id:'paint',label:'Pintura',kind:'paint'},{id:'decals',label:'Adesivo',kind:'decals'}]});return;}
  if(item.kind==='paint'){push({id:'paint',title:'Pintura',kind:'paint',items:[]});view();return;}
  if(item.kind==='extras'){push({id:'extras',title:'Extras',kind:'toggles',items:Array.from(new Set<number>([...(available?.extras??[]),...Object.entries(draftRef.current.extras??{}).filter(([,value])=>value===true).map(([id])=>Number(id)).filter(id=>Number.isInteger(id)&&id>=0&&id<=20)])).sort((a,b)=>a-b).map(id=>field('extra:'+id,'Extra '+id,'toggle'))});return;}
  if(item.kind==='neons'){push({id:'neons',title:'Neons',kind:'fields',items:[field('neonColor','Cor do neon','rgb'),{id:'neonLayout',label:'Layout do neon',kind:'neonLayout'}]});view(undefined,'low');return;}
  if(item.kind==='headlights'){push({id:'headlights',title:'Faróis',kind:'fields',items:[field('xenon','Farol de xenon','toggle'),field('xenonColor','Cor dos faróis')]});view(undefined,'front');return;}
  if(item.kind==='neonLayout'){push({id:'neonLayout',title:'Layout do neon',kind:'toggles',items:[field('neonAll','Todos os neons','toggle'),...[0,1,2,3].filter(i=>available?.neon?.[i]!==false).map(i=>field('neon:'+i,['Esquerdo','Direito','Dianteiro','Traseiro'][i],'toggle'))]});return;}
  if(item.kind==='toggle'){toggle(item);return;}
  if(item.kind==='stance'){setStanceDisplay(draftRef.current.stance??false);view(undefined,'wheels');push({id:'stance',title:'Suspensão',kind:'stance',items:[...Object.entries(stanceNames).map(([key,label])=>({id:'stance.'+key,field:'stance.'+key,label,kind:'stanceField',disabled:!available?.stance?.available||(['wheelSize','wheelWidth'].includes(key)&&!available?.stance?.tuningWheels)})),...visualMods.filter(i=>i.slot===15),{id:'stanceReset',label:'Restaurar suspensão original',kind:'stanceReset',disabled:!available?.stance?.available}]});return;}
  if(item.kind==='stanceReset'){void run(()=>commit({...draftRef.current,stance:false}));return;}
  if(item.kind==='stanceField'){const key=item.field!.slice(7),range=available?.stance?.ranges?.[key];if(!range)return;setInput({field:item.field,title:item.label,kind:'number',value:(draftRef.current.stance||stanceDefaults)[key],min:range[0],max:range[1],step:range[2]});view(key.includes('rear')?24:23,'part');return;}
  if(frame.kind==='options'){const p=candidate(item);void run(()=>commit(p));return;}
  if(item.kind==='mod'){void run(()=>mods(item.slot!));return;}
  if(item.kind==='wheels'){push({id:'families',title:'Rodas',kind:'families',items:[...(available?.wheelTypes??[]).map((i:number)=>({id:`family:${i}`,label:wheels[i],value:i,kind:'family'})),field('wheelColor','Cor das rodas'),field('customTyres','Pneus dianteiros personalizados','toggle'),...((available?.mods??[]).some((m:Data)=>m.slot===24)?[{id:'rearWheels',label:'Modelos traseiros',kind:'rearWheels'},field('customRearTyres','Pneus traseiros personalizados','toggle')]:[])]});view(23,'part');return;}
  if(item.kind==='family'){void run(async()=>{await mods(23,item.value===draftRef.current.wheelType?structuredClone(draftRef.current):{...draftRef.current,wheelType:item.value,mods:{...draftRef.current.mods,23:-1,24:-1},customTyres:false,customRearTyres:false},item.label);});return;}
  if(item.kind==='rearWheels'){void run(()=>mods(24));return;}
  if(['decals','lights','details'].includes(item.kind??'')){push({id:item.kind!,title:item.label,kind:'fields',items:fields(item.kind!)});fieldCamera(item);return;}
  if(item.kind==='rgb'||['primary','secondary','pearlescent','wheelColor','interiorColor','dashboardColor','xenonColor'].includes(item.field??'')){setColor({field:item.field,title:item.label,rgb:item.kind==='rgb',value:item.field==='xenonColor'?(draftRef.current.xenonCustom||draftRef.current.xenonColor):draftRef.current[item.field!]});fieldCamera(item);return;}
  if(item.kind==='rgb'||item.kind==='text'){held.current=false;void local('engineRev',{id:session.current,pressed:false});setInput({field:item.field,title:item.label,kind:item.kind,value:item.kind==='rgb'?(Array.isArray(draftRef.current[item.field!])?[...draftRef.current[item.field!]]:[255,255,255]):draftRef.current[item.field!]});fieldCamera(item);return;}
  if(item.field){const items=values(item),value=item.field.startsWith('extra:')?draftRef.current.extras?.[item.field.slice(6)]:item.field.startsWith('neon:')?draftRef.current.neon?.[Number(item.field.slice(5))]:draftRef.current[item.field];setMemory(v=>({...v,[item.field!]:items.find(i=>i.value===value)?.id??items[0]?.id}));push({id:item.field,title:item.label,kind:'options',field:item.field,base:structuredClone(draftRef.current),items});fieldCamera(item);}
 }
 function back(){if(color){setColor(null);show(draftRef.current);return;}if(input){setInput(null);show(draftRef.current);return;}if(frame.kind==='stance'&&stanceDraft.current&&Object.keys(stanceDefaults).some(k=>stanceDraft.current![k]!==({...stanceDefaults,...(draftRef.current.stance||{})} as Data)[k])){held.current=false;void local('engineRev',{id:session.current,pressed:false});setStanceQuestion(true);return;}if(frames.length){stanceDraft.current=null;setFrames(v=>v.slice(0,-1));show(draftRef.current);const parent=frames.length>1?frames[frames.length-2]:root;const i=parent.items.find(i=>i.id===memory[parent.id]);i?.slot!==undefined?view(i.slot,'part'):view(undefined,parent.id==='families'?'wheels':'main');}else onExit();}
 function resolveStance(keep:boolean){void run(async()=>{if(keep)await commit({...draftRef.current,stance:stanceDraft.current});else{await settle();setAvailable(await preview(draftRef.current));}stanceDraft.current=null;setStanceQuestion(false);setFrames(v=>v.slice(0,-1));view();});}
 nav.current=(key)=>{
  if(key==='spaceDown'){if(!input){held.current=true;void local('engineRev',{id:session.current,pressed:true}).catch(()=>{});}return;}if(key==='spaceUp'){held.current=false;void local('engineRev',{id:session.current,pressed:false}).catch(()=>{});return;}
  if(key==='doors'){void local('doors',{id:session.current}).catch(e=>setError(String(e)));return;}
  if(key==='interface'){if(free)setHideFreeUi(v=>!v);return;}if(key==='orbit'){void local('freeCamera').catch(e=>setError(String(e)));return;}
  if(free&&hideFreeUi&&['enter','left','right','up','down','home','end','pageDown','pageUp'].includes(key))return;
  if(key==='back'||key==='escape'){if(!loading&&!busy)back();return;}if(loading||busy)return;
  if(key==='night'||key==='save'){if(lighting){const enabled=!night;void local('previewNight',{enabled}).then(()=>setNight(enabled)).catch(e=>setError(String(e)));}return;}if(frame.kind==='stance'){stanceNav.current(key);return;}if(frame.kind==='paint'){colorNav.current(key);return;}if(color){colorNav.current(key);return;}if(input){if(key==='enter')confirmInput();else if(['left','right'].includes(key)&&input.kind==='number')editInput(Math.max(input.min,Math.min(input.max,input.value+(key==='right'?1:-1)*input.step)));else if(['left','right'].includes(key)&&input.kind==='rgb'){const at=Array.from(document.querySelectorAll('.heat-inline-edit input')).indexOf(document.activeElement as HTMLInputElement);editInput(input.value.map((v:number,i:number)=>i===Math.max(0,at)?Math.max(0,Math.min(255,v+(key==='right'?1:-1))):v));}return;}
  if(key==='enter'){uiSound();activate();return;}
  if(['left','right','up','down','home','end','pageDown','pageUp'].includes(key)&&frame.items.length){const selected=Math.max(0,frame.items.findIndex(i=>i.id===memoryRef.current[frame.id]));let index=key==='home'?0:key==='end'?frame.items.length-1:key==='pageDown'?Math.min(frame.items.length-1,selected+10):key==='pageUp'?Math.max(0,selected-10):(selected+(['left','up'].includes(key)?-1:1)+frame.items.length)%frame.items.length;const step=['left','up','home','pageUp'].includes(key)?-1:1;for(let skipped=0;skipped<frame.items.length&&isDisabled(frame.items[index]);skipped++)index=(index+step+frame.items.length)%frame.items.length;const next=frame.items[index];if(!next||isDisabled(next)||index===selected)return;setMemory(v=>({...v,[frame.id]:next.id}));uiSound();if(frame.kind==='options')show(candidate(next));}
 };
 useEffect(()=>{
  alive.current=true;barrier.current=settle;const ready=local('vehicleEditor',{id:session.current,enabled:true});presentationReady.current=ready;void ready.catch(e=>alive.current&&setError(String(e)));
  const pulse=setInterval(()=>{if(held.current)void local('engineRev',{id:session.current,pressed:true}).catch(()=>{});},150);
  function keyboard(e:KeyboardEvent){
   modality.current='keyboard';
   if(document.querySelector('[data-confirm-dialog]')){held.current=false;return;}
   if(e.ctrlKey&&e.code==='KeyS'){e.preventDefault();e.stopImmediatePropagation();if(!e.repeat)nav.current('save');return;}
   if(e.target instanceof Element&&e.target.closest('[data-tab-bar]')&&e.key==='Enter')return;
   if(e.code==='KeyS'&&!e.ctrlKey&&!(e.target instanceof HTMLInputElement)){e.preventDefault();e.stopImmediatePropagation();if(!e.repeat)nav.current('night');return;}
   if(e.code==='Space'&&!(e.target instanceof Element&&e.target.closest('input:not([type=range]):not([type=number]),textarea,[contenteditable=true]'))){e.preventDefault();e.stopImmediatePropagation();if(!e.repeat)nav.current('doors');return;}
   if(e.code==='KeyH'&&!(e.target instanceof HTMLInputElement)){e.preventDefault();e.stopImmediatePropagation();if(!e.repeat)nav.current('interface');return;}
   if(e.code==='KeyC'&&!(e.target instanceof Element&&e.target.closest('input:not([type=range]):not([type=number]),textarea,[contenteditable=true]'))){e.preventDefault();e.stopImmediatePropagation();if(!e.repeat)nav.current('orbit');return;}
   if(e.code==='KeyW'&&!(e.target instanceof HTMLInputElement)){e.preventDefault();e.stopImmediatePropagation();if(!e.repeat)nav.current('spaceDown');return;}
   if(e.target instanceof Element&&e.target.closest('.stance-panel input[type=number]')&&e.key==='Enter'){e.preventDefault();e.stopImmediatePropagation();nav.current('enter');return;}
   if(e.target instanceof Element&&e.target.closest('.heat-inline-edit,.stance-panel input[type=number]')){if(e.key==='Escape'){e.preventDefault();e.stopImmediatePropagation();nav.current('back');}return;}
   if(e.target instanceof Element&&e.target.closest('.heat-editor-actions,.heat-strip-scroll')){if(['Escape','Backspace'].includes(e.key)){e.preventDefault();e.stopImmediatePropagation();if(!e.repeat)nav.current('back');}return;}
   const k=({Home:'home',End:'end',PageDown:'pageDown',PageUp:'pageUp',ArrowLeft:'left',ArrowRight:'right',ArrowUp:'up',ArrowDown:'down',Enter:'enter',Backspace:'back',Escape:'escape',F1:'escape',} as Record<string,string>)[e.key];if(k){e.preventDefault();e.stopImmediatePropagation();if(!e.repeat||['left','right','up','down'].includes(k))nav.current(k);}
  }
  const up=(e:KeyboardEvent)=>{if(e.code==='KeyW')nav.current('spaceUp');},blur=()=>nav.current('spaceUp');
  const message=(e:MessageEvent)=>{if(e.data.type==='workshopInputDevice'&&e.data.device==='gamepad')held.current=false;if(e.data.type==='workshopCamera'){setFree(e.data.free===true);if(e.data.free===true)setHideFreeUi(false);}if(e.data.type==='nav'&&e.data.key==='enter'&&document.querySelector('.heat-inline-edit')){e.stopImmediatePropagation();document.querySelector<HTMLFormElement>('.heat-inline-edit')?.requestSubmit();return;}if(e.data.type==='nav'||e.data.type==='workshopBack'){if(document.querySelector('.workshop-modal'))return;e.stopImmediatePropagation();nav.current(e.data.type==='workshopBack'?'back':e.data.key);}};
  window.addEventListener('keydown',keyboard,true);window.addEventListener('keyup',up,true);window.addEventListener('blur',blur);window.addEventListener('message',message,true);
  return()=>{alive.current=false;held.current=false;clearInterval(pulse);queue.current.cancel();barrier.current=async()=>{};void local('vehicleEditor',{id:session.current,enabled:false}).catch(()=>{});void local('previewNight',{enabled:false}).catch(()=>{});void local('previewLights',{enabled:false}).catch(()=>{});void local('previewNeon',{id:session.current,enabled:false}).catch(()=>{});window.removeEventListener('keydown',keyboard,true);window.removeEventListener('keyup',up,true);window.removeEventListener('blur',blur);window.removeEventListener('message',message,true);};
 },[]);
 useEffect(()=>{const node=strip.current?.querySelector<HTMLButtonElement>('[aria-selected="true"]');if(node&&strip.current)scrollAnchored(strip.current,node);if(priorFrame.current!==frame.id||document.activeElement===document.body||document.activeElement?.closest('.heat-customization-strip'))node?.focus({preventScroll:true});priorFrame.current=frame.id;},[selected,frame.id]);
 useEffect(()=>{const el=strip.current;if(!el)return;const check=()=>setEdges({left:el.scrollLeft>1,right:el.scrollLeft+el.clientWidth<el.scrollWidth-1});const observer=new ResizeObserver(()=>{check();const selected=el.querySelector<HTMLElement>('[aria-selected=true]');if(selected)el.scrollLeft=anchoredScroll(el,selected);});observer.observe(el);el.addEventListener('scroll',check);check();return()=>{el.removeEventListener('scroll',check);observer.disconnect();};},[frame.id,frame.items.length,!!input]);
 useEffect(()=>{if(input)inputRef.current?.focus();},[!!input]);
 useEffect(()=>setError(''),[draft]);
 useEffect(()=>{void local('previewLights',{enabled:frames.some(f=>f.id==='headlights')}).catch(()=>{});},[frame.id,color?.field]);
 useEffect(()=>{const enabled=frames.some(f=>f.id==='neons'),layout=frame.id==='neonLayout'?draft.neon:(available?.neon??[true,true,true,true]).map((v:boolean)=>v!==false);const generation=++neonGeneration.current;neonQueue.current=neonQueue.current.catch(()=>{}).then(async()=>{await presentationReady.current;if(!alive.current||generation!==neonGeneration.current)return;await local('previewNeon',{id:session.current,enabled,layout,color:color?.field==='neonColor'?color.value:draft.neonColor,restore:draft.neon,restoreColor:draft.neonColor});}).catch(e=>{if(enabled&&alive.current&&generation===neonGeneration.current)setError(String(e instanceof Error?e.message:e));});return()=>{neonGeneration.current++;};},[frame.id,color?.field,color?.value,draft.neon,draft.neonColor]);

 function colorPatch(value:any){const key=color.field,p:Data={...draftRef.current,[key]:value};if(key==='xenonColor'){if(Array.isArray(value)){p.xenonCustom=value;p.xenonColor=draftRef.current.xenonColor;}else p.xenonCustom=false;}if(color.finish!==undefined)p[key.toLowerCase().includes('primary')?'primaryFinish':'secondaryFinish']=color.finish;if(key==='primary'||key==='secondary')p[key==='primary'?'customPrimary':'customSecondary']=false;if(key.startsWith('xenon'))p.xenon=true;return p;}
 function inputPatch(value:any){return input.field.startsWith('stance.')?{stance:{...(draftRef.current.stance||stanceDefaults),[input.field.slice(7)]:value}}:{[input.field]:value};}
 function editInput(value:any){setInput({...input,value});show({...draftRef.current,...inputPatch(value)});}
 const confirmInput=()=>{const p={...draftRef.current,...inputPatch(input.value)};void run(async()=>{await commit(p);setInput(null);});};
 
 return <section className="heat-customization-bar" data-color={!!color||frame.kind==='paint'} aria-label="Customizar" data-free={free&&hideFreeUi} onPointerDownCapture={()=>{modality.current='pointer';}} data-level={frame.id} aria-busy={loading||busy}>
  {free&&<><OrbitSurface move={move}/><button className="orbit-ui-toggle" onClick={()=>setHideFreeUi(v=>!v)}>{hideFreeUi?'Mostrar op\u00e7\u00f5es (H)':'Ocultar op\u00e7\u00f5es (H)'}</button></>}
  <div className="heat-customization-path"><div><small>{frames.length?['Customizar',...frames.slice(0,-1).map(f=>f.title)].join(' / '):'GARAGEM'}</small><h2 className="section-title">{frame.title}{!color&&!input&&['options','toggles'].includes(frame.kind)&&<small className="option-counter">{selected+1}/{frame.items.length}</small>}</h2></div><span>{loading?'Preparando opções…':frame.kind==='stance'?'AJUSTE E VOLTE PARA REVISAR':frame.kind==='options'?'PRÉVIA TEMPORÁRIA':'CONFIRME PARA APLICAR'}</span></div>
  {error&&<p className="heat-customization-error" role="alert">{error}</p>}
  {stanceWarning&&<p className="heat-customization-warning" role="status">{stanceWarning}</p>}
  {frame.kind==='paint'?<PaintPanel value={draft} busy={loading||busy} preview={show} apply={p=>void run(()=>commit(p))} nav={colorNav}/>:color?<ColorPanel key={color.field} title={color.title} allowRgb={color.field==='xenonColor'} palette={color.field==='xenonColor'?'xenon':'paint'} value={color.value} indexed={color.rgb?undefined:color.field==='xenonColor'?13:161} finish={color.finish??draft[color.field.toLowerCase().includes('primary')?'primaryFinish':'secondaryFinish']} onFinish={['primary','secondary','customPrimary','customSecondary'].includes(color.field)?value=>{const p={...colorPatch(color.value),[color.field.toLowerCase().includes('primary')?'primaryFinish':'secondaryFinish']:value};setColor({...color,finish:value});show(p);}:undefined} onPreview={value=>{setColor({...color,value});show(colorPatch(value));}} onApply={value=>void run(()=>commit(colorPatch(value)))} onOriginal={!['neonColor','smokeColor'].includes(color.field)?()=>void run(()=>commit(color.field==='xenonColor'?colorPatch(255):{...draftRef.current,[color.field]:color.rgb?false:color.field==='xenonColor'?255:['interiorColor','dashboardColor'].includes(color.field)?-1:0})):undefined} nav={colorNav} busy={loading||busy}/>:frame.kind==='stance'?<StancePanel value={stanceDisplay??draft.stance} unavailable={available?.stance?.unavailable} ranges={available?.stance?.ranges??{}} tuningWheels={!!available?.stance?.tuningWheels} busy={loading||busy} nav={stanceNav} preview={stance=>{stanceDraft.current=stance;setStanceDisplay(stance);show({...draftRef.current,stance},true);}}/>:input?<form className="heat-inline-edit" onSubmit={e=>{e.preventDefault();confirmInput();}}><strong>{input.title}</strong>{input.kind==='number'?<label>{input.title}<input ref={inputRef} aria-label={input.title} type="range" min={input.min} max={input.max} step={input.step} value={input.value} onChange={e=>editInput(Number(e.target.value))}/><input aria-label={input.title+' valor'} type="number" min={input.min} max={input.max} step={input.step} value={input.value} onChange={e=>editInput(Math.max(input.min,Math.min(input.max,Number(e.target.value))))}/></label>:input.kind==='rgb'?input.value.map((v:number,i:number)=><label key={i}>{['R','G','B'][i]}<input ref={i===0?inputRef:undefined} aria-label={['R','G','B'][i]} type="number" min={0} max={255} value={v} onChange={e=>editInput(input.value.map((n:number,j:number)=>i===j?Math.max(0,Math.min(255,Number(e.target.value))):n))}/></label>):<input ref={inputRef} aria-label={input.title} maxLength={8} value={input.value} onChange={e=>editInput(e.target.value.toUpperCase().replace(/[^A-Z0-9 ]/g,''))}/>}<button type="submit">Aplicar customização</button>{input.kind==='rgb'&&!['neonColor','smokeColor'].includes(input.field)&&<button type="button" onClick={()=>{const p={...draftRef.current,[input.field]:false};void run(async()=>{await commit(p);setInput(null);});}}>Cor original</button>}</form>:<OptionStrip ref={strip} className="heat-customization-strip" label={frame.title} count={frame.items.length} role="listbox">{frame.items.map((i,n)=><button key={i.id} disabled={isDisabled(i)||loading||busy} tabIndex={n===selected?0:-1} role="option" aria-selected={n===selected} className={n===selected?'selected':''}  onClick={()=>{setMemory(v=>({...v,[frame.id]:i.id}));uiSound();activate(i);}}><HeatIcon name={icon(i)}/><strong>{i.label}</strong>{((i.kind==='toggle'&&enabled(i))||(frame.kind==='options'&&confirmed(i)))&&<span className="equipped-badge" aria-label="Equipado">EQUIPADO</span>}{isDisabled(i)&&<small>{i.field?.startsWith('extra:')?'Não disponível com estas peças':available?.stance?.available?'Instale rodas de personalização':'Modelo não compatível'}</small>}{frame.kind==='options'&&<small>{confirmed(i)?'APLICADO':'EXPERIMENTAR'}</small>}</button>)}</OptionStrip>}
  {!stanceQuestion&&<div className="heat-editor-actions"><ControlHints device={device} actions={[...(frame.kind==='stance'?[]:[color||input||frame.kind==='options'||frame.kind==='paint'?'apply' as const:'select' as const]),'back','view','doors','rev',...(lighting?['night' as const]:[])]}/></div>}

 {stanceQuestion&&<ConfirmDialog title="Manter os ajustes de suspensão?" detail="Mantenha os ajustes ou restaure a configuração anterior." busy={loading||busy} onCancel={()=>setStanceQuestion(false)} actions={[{id:'keep',label:'Manter alterações',run:()=>resolveStance(true)},{id:'reset',label:'Restaurar anterior',run:()=>resolveStance(false)}]}/>}
 </section>;
}
