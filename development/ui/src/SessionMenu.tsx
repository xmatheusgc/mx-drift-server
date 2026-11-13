import {vehicleLabel,creationLabel} from './vehicle-label';
import {ControlHints,useInputDevice} from './ControlHints';
import {HeatIcon} from './HeatIcon';
import {usesNativeNavigation} from './input-boundary';
import React,{useEffect,useRef,useState} from 'react';
import {api,nui} from './api';
import {uiSound} from './ui-sound';
import {coordinateTargets,coordinateText,parseCoordinates,type Coordinate} from './admin-coordinates';
type Data=Record<string,any>;
type Binding={id:string;label:string;key:string;pad:string;default:string};
const fallbackBindings:Binding[]=[['menu','Menu do modo livre','M'],['repair','Reparar veículo','R'],['noclip','Alternar noclip','F2'],['saveCheckpoint','Criar checkpoint','F3'],['returnCheckpoint','Voltar ao checkpoint','F4'],['clean','Limpar veículo',''],['flip','Desvirar veículo',''],['engine','Ligar / desligar motor',''],['doors','Abrir / fechar portas',''],['stop','Parar o carro',''],['lock','Trancar / destrancar veículo',''],['eject','Expulsar ocupantes',''],['respawn','Recriar veículo',''],['drift','Handling de drift',''],['garage','Voltar para a garagem',''],['recover','Recuperar a pé',''],['clearCheckpoint','Remover checkpoint',''],['drivecam','Câmera de condução','F7'],['cycleSpeed','Noclip: velocidade','SHIFT'],['up','Noclip: subir','Q'],['down','Noclip: descer','Z'],['cameraMode','Noclip: orientação','H']].map(([id,label,key])=>({id,label,key,pad:({menu:'VIEW',cycleSpeed:'A',up:'RB',down:'DOWN',cameraMode:'RIGHT'} as Record<string,string>)[id]??'',default:key}));
const testPlayer:Data={source:'test-player',name:'[TESTE] Piloto temporário',state:'Simulação local',level:1,mock:true};
type Frame={id:string;title:string;data?:Data};
type Row={id:string;label:string;value?:string;detail?:string;disabled?:boolean;activate?:()=>void;adjust?:(delta:number)=>void};
const array=(value:any):Data[]=>Array.isArray(value)?value:[];
const strings=(value:any):string[]=>Array.isArray(value)?value.filter(v=>typeof v==='string'):[];
const clamp=(v:number,min:number,max:number)=>Math.max(min,Math.min(max,v));
function menuError(value:unknown){
 const text=value instanceof Error?value.message:String(value);
 if(/Failed to fetch|NetworkError|timed out|timeout|aborted/i.test(text))return 'A interface não recebeu a resposta a tempo. Feche e reabra o menu para atualizar o estado antes de repetir a ação.';
 const match=text.replace(/^Error:\s*/,'').match(/^([A-Z_]+):\s*(.*)$/s);
 if(!match)return text;
 const [,code,detail]=match;
 const fallback:Record<string,string>={POSITION:'Não foi possível confirmar a posição. A entrada foi cancelada; tente novamente.',COLLISION:'O cenário não terminou de carregar. Tente entrar na garagem novamente.',DRIVER:'A ação exige você no banco do motorista do seu carro.',PASSENGER:'Peça aos passageiros para desembarcarem antes de continuar.',BUSY:'Há uma ação em andamento. Aguarde sua conclusão.',RATE:'Aguarde um instante antes de repetir a ação.',UNAVAILABLE:'O serviço não respondeu. Feche e reabra o menu para atualizar o estado.'};
 return `${detail&&detail!==code?detail:fallback[code]??'A ação não foi concluída.'} [${code}]`;
}
export function SessionMenu(){
 const [coordinateTarget,setCoordinateTarget]=useState('ped'),[coordinatePoint,setCoordinatePoint]=useState<Coordinate|null>(null),[coordinateOverlay,setCoordinateOverlay]=useState(false);
 async function captureCoordinate(format:'vector3'|'vector4'|'table'){
   const value=await api<Coordinate>('admin','coordinates',{target:coordinateTarget});setCoordinatePoint(value);
   const rendered=coordinateText(value,format);
   let copied=false;try{await navigator.clipboard.writeText(rendered);copied=true;}catch{/* The selected read-only field also supports Ctrl+C in CEF. */}
   textAnswer.current=()=>{};setTextDialog({label:`Captura ${format}`,value:rendered,max:250,readOnly:true});
   setNotice(copied?'Coordenadas copiadas':'Texto selecionado; pressione Ctrl+C para copiar');
 }
 async function changeCoordinateTarget(delta:number){
   const ids=coordinateTargets.map(([id])=>id as string),target=ids[(ids.indexOf(coordinateTarget)+delta+ids.length)%ids.length];
   if(coordinateOverlay)await api('admin','coordinateOverlay',{enabled:true,target});
   const point=await api<Coordinate>('admin','coordinates',{target});setCoordinateTarget(target);setCoordinatePoint(point);
 }
 const device=useInputDevice();
 const [doorIndex,setDoorIndex]=useState(0);
 const [showTestPlayer,setShowTestPlayer]=useState(false);
 const [bindings,setBindings]=useState<Binding[]>(fallbackBindings);
 const bindingRef=useRef(bindings);bindingRef.current=bindings;
 const shortcutLabel=(id:string)=>bindings.find(b=>b.id===id)?.key||'Sem tecla';
 const inputLabel=(id:string)=>{const b=bindings.find(b=>b.id===id);if(device==='keyboard')return b?.key||'Sem tecla';const pad=b?.pad||'Sem botão';return device==='playstation'?({VIEW:'Touchpad',A:'X',B:'Círculo',X:'Quadrado',Y:'Triângulo',LB:'L1',RB:'R1',LS:'L3',RS:'R3'} as Record<string,string>)[pad]??pad:pad;};
 const simulate=()=>void run(async()=>{},'TESTE: ação simulada; nenhum jogador real foi afetado.');
 function moderate(player:Data,kind:'warn'|'kick'|'ban'){
   void run(async()=>{const reason=await text('Motivo (obrigatório)','',120);if(!reason)return;setConfirm({title:
   (player.mock?'[TESTE] ':'')+(kind==='warn'?'Enviar aviso para ':kind==='kick'?'Expulsar ':'Banir permanentemente ')+player.name+'?',detail:'Motivo: '+reason,run:async()=>{
     if(player.mock){setNotice('TESTE: moderação simulada; nenhum registro ou jogador real foi alterado.');return;}
     await api('admin','moderate',{target:player.source,action:kind,reason});
   }});},'');
 }
 const defaultSpeedLabels=['Muito lento','Lento','Normal','Rápido','Muito rápido','Extremo','Extremo+','Máximo'];
 const [trainer,setTrainer]=useState<Data>({noclip:false,speed:3,followCamera:true,checkpoint:false});
 const flightPending=useRef(false),flightQueued=useRef(false);
 function toggleFlight(){
   if(flightPending.current){flightQueued.current=!flightQueued.current;return;}
   flightPending.current=true;setError('');
   void nui<Data>('noclipToggle').then(value=>{setTrainer(value);setNotice(value.noclip?'Noclip ativado':'Noclip desativado');}).catch(e=>setError(menuError(e))).finally(()=>{
     flightPending.current=false;
     if(flightQueued.current){flightQueued.current=false;toggleFlight();}
   });
 }
 const [textDialog,setTextDialog]=useState<{label:string;value:string;max:number;readOnly?:boolean}|null>(null),textAnswer=useRef<((value:string|null)=>void)|null>(null),textInput=useRef<HTMLInputElement>(null);
 function answerText(value:string|null){const resolve=textAnswer.current;textAnswer.current=null;setTextDialog(null);resolve?.(value);}
 const [open,setOpen]=useState(false),[frames,setFrames]=useState<Frame[]>([{id:'root',title:'Freeroam'}]),[revision,setRevision]=useState(0),[busy,setBusy]=useState(false),[error,setError]=useState(''),[notice,setNotice]=useState(''),[permissions,setPermissions]=useState<Data>({}),[content,setContent]=useState<any>(null),[confirm,setConfirm]=useState<{title:string;detail?:string;run:()=>Promise<unknown>}|null>(null),[filter,setFilter]=useState('');
 const previousConfirm=useRef<typeof confirm>(null);
 const memory=useRef<Record<string,string>>({}),lock=useRef(false),generation=useRef(0),rowRef=useRef<Row[]>([]),navigation=useRef<(key:string)=>void>(()=>{}),list=useRef<HTMLDivElement>(null),openRef=useRef(false);
 const frame=frames[frames.length-1],framePath=frames.map(f=>f.id+(f.data?.id??f.data?.track??f.data?.brand??'')+':'+(f.data?.page??'')).join('/'),path=framePath+(confirm?'/confirm':'');
 if(confirm&&previousConfirm.current!==confirm)memory.current[path]='cancel';previousConfirm.current=confirm;
 openRef.current=open;
 function repaint(){setRevision(r=>r+1);}
 async function run(fn:()=>Promise<unknown>,message='Confirmado'){
   if(lock.current)return;lock.current=true;setBusy(true);setError('');
   try{const result=await fn();const warning=result&&typeof result==='object'&&'warning' in result&&typeof result.warning==='string'?result.warning:null;if(warning)setNotice(warning);else if(message)setNotice(message);}catch(e){setNotice('');setError(menuError(e));}finally{lock.current=false;setBusy(false);}
 }
 function push(id:string,title:string,data?:Data){generation.current++;setBusy(true);setContent(null);setNotice('');setError('');setFrames(f=>[...f,{id,title,data}]);}
 function back(closeAtRoot=false){
   if(confirm){setConfirm(null);return;}
   if(frames.length>1){generation.current++;setContent(null);setFrames(f=>f.slice(0,-1));}else if(closeAtRoot)void nui('close').catch(()=>{});
 }
 async function text(label:string,initial='',maxLength=48){if(device!=='keyboard'){const result=await nui<{value:string|null;cancelled:boolean}>('keyboard',{initial,maxLength});return result.cancelled?null:result.value;}return new Promise<string|null>(resolve=>{textAnswer.current=resolve;setTextDialog({label,value:initial,max:maxLength});});}
 useEffect(()=>{if(textDialog){textInput.current?.focus();if(textDialog.readOnly)textInput.current?.select();}},[textDialog?.label]);
 const action=(domain:string,name:string,data:Data={},message?:string)=>void run(async()=>{const result=await api(domain,name,data);await load(frame);return result;},message);
 const tool=(name:string,data:Data={},message='Confirmado')=>void run(async()=>{setTrainer(await api('world',name,data));},message);
 async function load(f:Frame){
   const id=++generation.current;
   if(f.id==='adminCoordinates'){const point=await api<Coordinate>('admin','coordinates',{target:coordinateTarget});if(id===generation.current&&openRef.current)setCoordinatePoint(point);return;}
   if(f.id==='root'||f.id==='trainer'){const value=await api('world','trainerState');if(id===generation.current&&openRef.current)setTrainer(value);return;}
   const requests:Record<string,()=>Promise<any>>={
     sound:()=>nui('vehicleSound',{action:'state'}),environment:()=>nui('personalEnvironment'),vehicle:()=>api('vehicles','options'),switchSaved:()=>api('vehicles','trainerGarage'),switchCatalog:()=>api('vehicles','catalogBrands'),switchModels:()=>api('vehicles','catalog',{brand:f.data?.brand,page:f.data?.page??0}),destinations:()=>api('world','destinations'),players:()=>api('social','players'),admin:()=>api('admin','inspect'),
   };
   if(requests[f.id]){const value=await requests[f.id]();if(id===generation.current&&openRef.current)setContent(value);}
 }
 useEffect(()=>{
   if(!open)return;
   let alive=true;setBusy(frame.id!=='root');setError('');
   void load(frame).catch(e=>{if(alive)setError(menuError(e));}).finally(()=>{if(alive)setBusy(false);});
   return()=>{alive=false;};
 },[open,framePath]);
 useEffect(()=>{
   if(!open||!['vehicle','environment','sound'].includes(frame.id)||confirm)return;
   let stopped=false;let timer:ReturnType<typeof setTimeout>;
   const refresh=async()=>{if(!stopped&&!lock.current){try{await load(frame);}catch(e){if(!stopped){setContent({available:{},reasons:{}});setError(menuError(e));}}}if(!stopped)timer=setTimeout(refresh,1000);};
   timer=setTimeout(refresh,1000);return()=>{stopped=true;clearTimeout(timer);};
 },[open,framePath,!!confirm]);
 useEffect(()=>{const handler=(e:MessageEvent)=>{if(e.data.type==='adminCoordinates'){const data=e.data.data;setCoordinateOverlay(!!data);if(data&&!data.error){setCoordinatePoint(data);setCoordinateTarget(data.target);}}};window.addEventListener('message',handler);return()=>window.removeEventListener('message',handler);},[]);
 useEffect(()=>{
   function message(e:MessageEvent){const m=e.data;if(m.type==='menu'){
     if(!m.open)answerText(null);generation.current++;setOpen(m.open);setError('');setConfirm(null);
     if(m.open){void nui<Data>('trainerOptions').then(o=>setShowTestPlayer(o.testPlayer===true)).catch(()=>setShowTestPlayer(false));void nui<Binding[]>('bindings').then(value=>{if(Array.isArray(value))setBindings(value);}).catch(()=>{});setContent(null);setPermissions({});void api('admin','permissions').then(setPermissions).catch(()=>setPermissions({}));}
   }else if(m.type==='soundFeedback'){setNotice(m.message);}else if(m.type==='bindings'){if(Array.isArray(m.data))setBindings(m.data);}else if(m.type==='menuError'){setNotice('');setError(menuError(`${m.code??'ERRO'}: ${m.message??m.code??''}`));}else if(m.type==='trainer')setTrainer(t=>({...t,...m.data}));else if(m.type==='nav'&&openRef.current)navigation.current(m.key);else if(m.type==='workshop'&&m.state)setOpen(false);}
   function keyboard(e:KeyboardEvent){if(!openRef.current)return;if(e.repeat&&['Enter','Backspace','Escape'].includes(e.key))return;if(textAnswer.current){if(e.key==='Escape'){e.preventDefault();answerText(null);}return;}if(usesNativeNavigation())return;if(e.target instanceof Element&&e.target.closest('button')&&['Enter',' '].includes(e.key))return;const key:Record<string,string>={ArrowUp:'up',ArrowDown:'down',ArrowLeft:'left',ArrowRight:'right',Enter:'enter',Backspace:'back',Escape:'escape'};const match=bindingRef.current.find(b=>b.key&&b.key===(e.key===' '?'SPACE':e.key.toUpperCase()));if(match&&!e.repeat){e.preventDefault();navigation.current(match.id==='menu'?'close':'shortcut:'+match.id);return;}if(key[e.key]){e.preventDefault();navigation.current(key[e.key]);}}
   window.addEventListener('message',message);window.addEventListener('keydown',keyboard);return()=>{window.removeEventListener('message',message);window.removeEventListener('keydown',keyboard);};
 },[]);
 useEffect(()=>{const timer=setTimeout(()=>setNotice(''),3500);return()=>clearTimeout(timer);},[notice]);
 function row(id:string,label:string,activate?:()=>void,value?:string,detail?:string,adjust?:(d:number)=>void,disabled=false):Row{return {id,label,activate,value,detail,adjust,disabled};}
 const rows:Row[]=[];
 const add=(...values:Row[])=>rows.push(...values);
 const child=(id:string,label:string,data?:Data)=>row(id,label,()=>push(id,label,data),'›');
 const command=(id:string,label:string,domain:string,name:string,data:Data={},disabled=false)=>row(id,label,()=>action(domain,name,data),undefined,undefined,undefined,disabled);
 const info=(id:string,label:string,value?:string,detail?:string)=>row(id,label,undefined,value,detail);
 if(confirm){add(row('cancel','Manter / voltar',()=>setConfirm(null),undefined,confirm.detail),row('confirm',confirm.title,()=>void run(async()=>{await confirm.run();setConfirm(null);},confirm.title.startsWith('[TESTE]')?'TESTE: ação simulada; nenhum jogador real afetado.':'Confirmado')));}
 else switch(frame.id){
 case 'root':
   add(child('vehicle','Opções do veículo'),child('switchCar','Trocar de carro'),child('sound','Som do veículo'),child('trainer','Pilotagem livre'),child('destinations','Pistas'),child('environment','Clima e horário'),row('workshop','Voltar para a garagem',()=>void run(()=>nui('openWorkshop'),'Abrindo garagem…'),undefined,'Oficina privada, com seu carro atual. Passageiros devem desembarcar.'),child('players','Jogadores'));
   if(permissions.admin)add(child('admin','Administração'));
   break;
 case 'vehicle':{
   const context=content??{},available=context.available??{},reasons=context.reasons??{};
   const service=(kind:string,label:string,extra:Data={},value?:string,detail?:string)=>row(kind,label,()=>action('vehicles','service',{kind,vehicleId:context.id,...extra}),value,reasons[kind]??detail,undefined,!available[kind]);
   add(service('repair','Reparar'),service('clean','Limpar'),service('flip','Desvirar'),service('engine','Ligar / desligar motor',{},undefined,'Pode ser usado fora do seu carro, a até 60 m.'),service('lock','Trancar / destrancar',{},context.locked?'TRANCADO':'DESTRANCADO'));
   const choices=[-1,...(Array.isArray(context.doors)?context.doors.filter((d:unknown)=>Number.isInteger(d)&&Number(d)>=0&&Number(d)<=5):[])];
   const selectedDoor=choices[Math.min(doorIndex,choices.length-1)];
   const doorLabels=['Dianteira esquerda','Dianteira direita','Traseira esquerda','Traseira direita','Capô','Porta-malas'];
   add({...service('doors','Portas',{door:selectedDoor},selectedDoor===-1?'Todas':doorLabels[selectedDoor],'← → escolhem a porta. Enter abre/fecha a selecionada.'),adjust:(delta:number)=>{uiSound();setDoorIndex(i=>(Math.min(i,choices.length-1)+delta+choices.length)%choices.length);}},
   service('drift','Handling de drift',{enabled:!context.drift},context.handlingUncertain?'SEM CONFIRMAÇÃO':context.drift?'LIGADO':'DESLIGADO',context.handlingWarning??'Aplica o preset de drift neste carro, inclusive em movimento. Desativar restaura o original.'),
   service('eject','Expulsar outros jogadores',{},undefined,'Retira somente os outros jogadores que estão no seu veículo.'),
   row('respawn','Recriar veículo',()=>setConfirm({title:'Recriar o veículo atual?',detail:'Seu carro será substituído no mesmo local, com você ao volante. A configuração será mantida.',run:async()=>{await api('vehicles','service',{kind:'respawn',vehicleId:context.id});await load(frame);}}),undefined,reasons.respawn,undefined,!available.respawn),
   service('stop','Parar o carro'),row('customize','Personalizar na garagem',()=>void run(()=>nui('openWorkshop'),''),'›'));
   break;}
 case 'sound':{
   const context=content??{},ready=Number.isInteger(context.vehicleId);
   const statuses:Record<string,string>={idle:'Parado',loading:'Buscando música',buffering:'Carregando áudio',playing:'Tocando',paused:'Pausado',error:'Erro',not_found:'Não encontrada'};
   const request=(name:string,extra:Data={})=>void run(async()=>{await nui('vehicleSound',{action:name,vehicleId:context.vehicleId,...extra});await load(frame);},'Pedido enviado ao sistema de som');
   const music=(name:'play'|'queue')=>void run(async()=>{
     const input=await text(name==='play'?'Tocar: nome da música ou link':'Adicionar à fila: nome ou link','',250);
     if(!input?.trim())return;
     await nui('vehicleSound',{action:name,vehicleId:context.vehicleId,input:input.trim()});await load(frame);setNotice('Pedido enviado ao sistema de som');
   },'');
   add(info('status','Estado',ready?(statuses[context.status]??context.status):'Indisponível',context.error??'Entre em um veículo. Nomes e links de plataformas dependem do serviço de busca; links diretos de áudio também são aceitos.'),
     info('track','Faixa atual',context.meta?.title??(context.active?'Áudio por link':'Nenhuma'),context.meta?.uploader),
     row('play','Tocar música',()=>music('play'),undefined,undefined,undefined,!ready),
     row('queue','Adicionar à fila',()=>music('queue'),undefined,undefined,undefined,!ready),
     row('pause',context.paused?'Continuar':'Pausar',()=>request(context.paused?'resume':'pause'),undefined,undefined,undefined,!ready||!context.active),
     row('skip','Próxima música',()=>request('skip'),undefined,undefined,undefined,!ready||!array(context.queue).length),
     row('volume','Volume',()=>void run(async()=>{const value=await text('Volume de 0 a 30',String(context.volume??15),2);if(value===null)return;if(!/^\d{1,2}$/.test(value)||Number(value)>30)throw Error('Informe um volume inteiro de 0 a 30.');await nui('vehicleSound',{action:'volume',vehicleId:context.vehicleId,volume:Number(value)});await load(frame);setNotice('Pedido de volume enviado');},''),String(context.volume??15)+' / 30','← → ajustam; confirmar permite digitar.',delta=>request('volume',{volume:clamp(Number(context.volume??15)+delta,0,30)}),!ready),
     row('stop','Parar e limpar fila',()=>request('stop'),undefined,undefined,undefined,!ready||(!context.active&&!array(context.queue).length)),
     ...array(context.queue).map((track,index)=>info('queued:'+index,`${index+1}. ${track.meta?.title??'Música na fila'}`,undefined,track.meta?.uploader)));
   break;}
 case 'switchCar':
   add(child('switchSaved','Carros salvos'),child('switchCatalog','Catálogo de modelos'));break;
 case 'switchSaved':
   add(...array(content).map(car=>row(car.id,creationLabel(car),()=>action('vehicles','switch',{presetId:car.id},'Carro trocado'),vehicleLabel(car),'Mantém a personalização e o modo drift desta criação.',undefined,!car.available)));break;
 case 'switchCatalog':
   add(...strings(content).map(brand=>row('brand:'+brand,brand,()=>push('switchModels',brand,{brand,page:0}),'›')));break;
 case 'switchModels':{
   const page=Number(frame.data?.page??0),brand=frame.data?.brand;
   add(...array(content).map(car=>row(car.id,car.name,()=>action('vehicles','switch',{model:car.model},'Carro trocado'),undefined,'Modelo do catálogo. Suas criações salvas são preservadas.',undefined,!car.available)));
   const change=(next:number)=>{generation.current++;setContent(null);setFrames(f=>[...f.slice(0,-1),{id:'switchModels',title:frame.title,data:{brand,page:next}}]);};
   if(page>0)add(row('previous','Página anterior',()=>change(page-1)));
   if(array(content).length===20)add(row('next','Próxima página',()=>change(page+1)));
   break;}
 case 'trainer':{
   const levels=strings(trainer.speedLabels).length?strings(trainer.speedLabels):defaultSpeedLabels;
   const changeSpeed=(delta:number)=>tool('noclip',{enabled:true,speed:clamp(Number(trainer.speed??3)+delta,1,levels.length)},'Velocidade atualizada');
   add(row('noclip','Noclip',toggleFlight,trainer.noclip?'LIGADO':'DESLIGADO',`${inputLabel('noclip')} alterna. W/S ou analógico move; ${inputLabel('cycleSpeed')} troca a velocidade; ${inputLabel('up')}/${inputLabel('down')} sobe/desce; ${inputLabel('cameraMode')} alterna a visão. No modo fixo, A/D gira.`),row('speed','Velocidade do noclip',()=>changeSpeed(1),levels[Number(trainer.speed??3)-1],undefined,changeSpeed,!trainer.noclip),row('cameraMode','Orientação do noclip',()=>tool('noclip',{enabled:true,speed:trainer.speed,followCamera:trainer.followCamera===false},'Modo atualizado'),trainer.followCamera===false?'Fixa':'Segue câmera',`${inputLabel('cameraMode')} alterna durante o voo.`,()=>tool('noclip',{enabled:true,speed:trainer.speed,followCamera:trainer.followCamera===false},'Modo atualizado'),!trainer.noclip),row('checkpoint','Criar checkpoint',()=>tool('saveCheckpoint',{},'Checkpoint criado'),shortcutLabel('saveCheckpoint'),'Salva posição e direção atuais. Pessoal e temporário, até desconectar.'),row('return','Voltar ao checkpoint',()=>tool('returnCheckpoint',{},'Retorno confirmado'),shortcutLabel('returnCheckpoint'),'Retorna a pé ou com seu carro, sem passageiros. Velocidade zerada. Se o local estiver ocupado, tente novamente.',undefined,!trainer.checkpoint),command('recover','Recuperar a pé','world','recover',{withCar:false}),row('clear','Remover checkpoint',()=>tool('clearCheckpoint',{},'Checkpoint removido'),undefined,undefined,undefined,!trainer.checkpoint));
   break;}
 case 'destinations':
   add(...[...new Set(array(content).map(d=>String(d.category||'Outras')))].sort().map(category=>row(category,category,()=>push('trackCategory',category,{id:category,points:array(content).filter(d=>(d.category||'Outras')===category)}),'›')));break;
 case 'environment':{
   if(!content)break;
   const p=content,server=p.server??{},choices=array(p.choices);
   const update=(patch:Data)=>void run(async()=>setContent(await nui('personalEnvironment',{patch})),'Configuração pessoal aplicada');
   const weather=p.syncWeather?server.weather:p.weather,weatherIndex=choices.findIndex(c=>c.id===weather);
   const choose=(delta:number)=>{if(choices.length)update({weather:choices[(Math.max(0,weatherIndex)+delta+choices.length)%choices.length].id});};
   const hour=Number(p.syncTime?server.hour:p.hour),minute=Number(p.syncTime?server.minute:p.minute);
   add(row('syncWeather','Sincronizar clima',()=>update({syncWeather:!p.syncWeather}),p.syncWeather?'SERVIDOR':'PESSOAL','Afeta somente sua visão do mundo livre.',()=>update({syncWeather:!p.syncWeather})),
    row('weather','Clima',()=>choose(1),choices[weatherIndex]?.label??weather,'Desative a sincronização de clima para escolher.',choose,!!p.syncWeather),
    row('syncTime','Sincronizar horário',()=>update({syncTime:!p.syncTime}),p.syncTime?'SERVIDOR':'PESSOAL','Lobby e garagem mantêm a iluminação própria.',()=>update({syncTime:!p.syncTime})),
    row('hour','Hora',()=>update({hour:(hour+1)%24}),String(hour).padStart(2,'0'),'Horário pessoal fixo, de 00 a 23.',d=>update({hour:(hour+d+24)%24}),!!p.syncTime),
    row('minute','Minuto',()=>update({minute:(minute+1)%60}),String(minute).padStart(2,'0'),undefined,d=>update({minute:(minute+d+60)%60}),!!p.syncTime),
    row('serverEnvironment','Usar clima e horário do servidor',()=>update({syncWeather:true,syncTime:true}),undefined,'Volta a acompanhar as duas configurações do servidor.'));
   break;}
 case 'trackCategory':
   add(...array(frame.data?.points).map(d=>row(d.id,d.name,()=>action('world','travel',{destination:d.id},'Teleporte confirmado'),undefined,d.available?'Confirmar para viajar. Seu veículo acompanha você se estiver dirigindo.':'Mapa indisponível ou coordenadas aguardam validação',undefined,!d.available)));break;
 case 'players':
   add(row('search','Buscar jogador',()=>void run(async()=>{const value=await text('Buscar',filter);if(value!==null)setFilter(value);},''),filter||'Todos'));
   add(...[...array(content),...(showTestPlayer?[testPlayer]:[])].filter(p=>(p.name+' '+p.source).toLowerCase().includes(filter.toLowerCase())).map(p=>row(String(p.source),p.name,()=>push('player',p.name,p),'›',`${p.state} · nível ${p.level} · ${p.region??'Localização privada'}`)));break;
 case 'player':{
   const p=frame.data!;add(info('status',p.state,`Nível ${p.level}`),row('mute','Silenciar / ouvir voz e chat',()=>p.mock?simulate():void run(()=>nui('mute',{source:p.source}))),row('route','Marcar rota',()=>p.mock?simulate():void run(()=>nui('route',{source:p.source})),undefined,undefined,undefined,!p.mock&&!p.position));
   if(permissions.admin)for(const [kind,label] of [['warn','Enviar aviso'],['kick','Expulsar'],['ban','Banir permanentemente']] as const)if(permissions[kind])add(row(kind,label,()=>moderate(p,kind),undefined,p.mock?'TESTE: esta ação será apenas simulada.':'Exige motivo e confirmação; permissão validada no servidor.'));
   break;}
 case 'admin':{
   const a=content??{},p=a.permissions??permissions;
   if(!permissions.admin){add(info('denied','Acesso restrito'));break;}
   add(child('players','Moderação de jogadores'));
   if(p.inspect)add(child('adminCoordinates','Coordenadas e heading'));
   if(p.teleport)add(child('adminTeleport','Teleporte administrativo'));
   if(p.content)add(row('createTeleport','Criar ponto de pista aqui',()=>void run(async()=>{const name=await text('Nome da pista','',48);if(!name)return;const category=await text('Categoria: touge, circuito, urbano…','Circuito',24);if(!category)return;await api('admin','createTeleport',{name,category});},'Ponto gravado e disponível em Pistas')));
   if(p.inspect)add(child('diagnostics','Diagnósticos',{snapshot:a}));
   if(p.cleanup)add(row('cleanup','Limpar carros gerenciados vazios',()=>setConfirm({title:'Confirmar limpeza gerenciada',run:()=>api('admin','cleanup')})));
   if(p.invalidate)add(row('revoke','Invalidar resultado',()=>void run(async()=>{const id=await text('ID do resultado','',36);if(!id)return;const reason=await text('Motivo','Revisão administrativa',120);if(reason)await api('admin','revoke',{id,reason});})));
   break;}
 case 'adminCoordinates':{
   const p=coordinatePoint;
   const label=coordinateTargets.find(([id])=>id===coordinateTarget)?.[1]??'Personagem';
   add(row('reference','Referência',()=>void run(()=>changeCoordinateTarget(1),''),label,'Personagem, veículo ocupado ou câmera de renderização.',d=>void run(()=>changeCoordinateTarget(d),'')),
   row('overlay','Mostrar coordenadas na tela',()=>void run(async()=>{const result=await api('admin','coordinateOverlay',{enabled:!coordinateOverlay,target:coordinateTarget});setCoordinateOverlay(result.enabled);},''),coordinateOverlay?'Ligado':'Desligado','Permanece visível com o menu fechado, inclusive no noclip.'),
   row('refreshCoordinates','Atualizar captura',()=>void run(()=>load(frame),'')));
   if(p&&!p.error){
     for(const k of ['x','y','z','h'] as const)add(info(k,k==='h'?'Heading':k.toUpperCase(),Number(p[k]).toFixed(k==='h'?2:3)));
     if(p.model!==undefined)add(info('model','Modelo',p.name||String(p.model)),info('interior','Interior',String(p.interior??0)),info('network','ID de rede',String(p.networkId??0)));
   }
   for(const [format,label] of [['vector3','Capturar vector3'],['vector4','Capturar vector4 + heading'],['table','Capturar tabela Lua']] as const)add(row(format,label,()=>void run(()=>captureCoordinate(format),''),undefined,'Captura a posição atual. Copia quando permitido e abre o texto selecionado para Ctrl+C.'));
   break;}
 case 'adminTeleport':{
   add(row('coordinates','Ir para coordenadas',()=>void run(async()=>{const value=await text('X, Y, Z, heading opcional — decimais com ponto','',120);if(value===null)return;const point=parseCoordinates(value);await api('admin','teleport',{mode:'coordinates',point});},'Teleporte confirmado'),undefined,'Aceita X, Y, Z, heading ou vector4. Sem heading mantém a direção atual.'),
   row('waypoint','Ir para marcador do mapa',()=>void run(()=>api('admin','teleport',{mode:'waypoint'}),'Teleporte confirmado'),undefined,'Marque no mapa antes de abrir o menu. Aguarda solo; em interiores use Z explícito.'),
   info('transport','Transporte','Automático','Leva o carro gerenciado que você dirige. Passageiros devem desembarcar. A pé, leva seu personagem.'));
   break;}
 case 'diagnostics':{
   const snapshot=frame.data?.snapshot??{};
   add(child('resources','Recursos',{snapshot}),child('managedCars','Veículos ativos',{snapshot}),child('presentations','Apresentações da oficina',{snapshot}),child('sessions','Sessões de atividade',{snapshot}));break;}
 case 'resources':for(const [name,state] of Object.entries(frame.data?.snapshot?.resources??{}))add(info(name,name,String(state)));break;
 case 'managedCars':for(const v of array(frame.data?.snapshot?.vehicles))add(info('car:'+v.id,`Carro #${v.source}`,v.model,v.id));break;
 case 'presentations':for(const p of array(frame.data?.snapshot?.presentations))add(info('preview:'+p.source,`Oficina #${p.source}`,`${p.count} entidade(s)`,p.busy?'Preparando apresentação':'Apresentação estável'));break;
 case 'sessions':for(const s of array(frame.data?.snapshot?.sessions))add(info('session:'+s.id,`Sessão #${s.source}`,s.mode,s.id));break;

 }
 if(!rows.length)add(info('empty',busy?'Carregando…':'Nenhum item disponível'));
 rowRef.current=rows;
 let selected=rows.findIndex(r=>r.id===memory.current[path]);if(selected<0)selected=0;
 const current=rows[selected];
 navigation.current=(key)=>{
   if(textDialog){if(key==='enter')answerText(textDialog.value);else if(key==='back'||key==='escape')answerText(null);return;}

   if(key.startsWith('shortcut:')){
     const id=key.slice(9);
     if(id==='repair'||id==='clean'||id==='flip'||id==='engine'||id==='doors'||id==='stop'||id==='lock'||id==='eject'||id==='respawn')action('vehicles','service',{kind:id});
     else if(id==='drift')void run(async()=>{const status=await api('vehicles','options');const result=await api('vehicles','service',{kind:'drift',vehicleId:status.id,enabled:!status.drift});if(frame.id==='vehicle')await load(frame);return result;});
     else if(id==='recover')action('world','recover',{withCar:false});
     else if(id==='garage')void run(()=>nui('openWorkshop'),'');
     else if(id==='drivecam')void run(()=>nui('toggleDrivecam'));
     else if(id==='noclip')toggleFlight();
     else if(['saveCheckpoint','returnCheckpoint','clearCheckpoint'].includes(id))tool(id,{});
     return;
   }
   if(key==='noclip'){toggleFlight();return;}
   if(['saveCheckpoint','returnCheckpoint'].includes(key)){tool(key,{});return;}
   if(key==='close'){uiSound();void nui('close').catch(()=>{});return;}
   if(key==='back'||key==='escape'){uiSound();back(true);return;}
   if(busy)return;
   const options=rowRef.current;let index=options.findIndex(r=>r.id===memory.current[path]);if(index<0)index=0;
   if(key==='up'||key==='down'){if(options.length<2)return;uiSound();index=(index+(key==='down'?1:-1)+options.length)%options.length;memory.current[path]=options[index].id;repaint();}
   else if(key==='left'||key==='right'){if(!options[index].disabled&&options[index].adjust){options[index].adjust?.(key==='right'?1:-1);}}
   else if(key==='enter'&&!options[index].disabled&&options[index].activate){if(!options[index].adjust)uiSound();options[index].activate?.();}
 };
 useEffect(()=>{const node=list.current?.querySelector<HTMLElement>('[aria-selected="true"]');node?.scrollIntoView({block:'nearest'});if(document.activeElement===document.body||document.activeElement?.closest('.session-menu'))node?.focus();},[selected,path,revision]);
 if(!open)return trainer.noclip?<aside className="trainer-indicator" role="status"><strong>NOCLIP · {(strings(trainer.speedLabels).length?strings(trainer.speedLabels):defaultSpeedLabels)[Number(trainer.speed??3)-1]}</strong><span>{trainer.followCamera===false?'Orientação fixa':'Segue a câmera'}</span><span>{`${inputLabel('cycleSpeed')}: velocidade · ${inputLabel('up')} / ${inputLabel('down')}: altura · ${inputLabel('cameraMode')}: visão · ${inputLabel('noclip')}: sair`}</span></aside>:null;
 return <aside className="session-menu" aria-label="Menu de freeroam" data-page={frame.id} aria-busy={busy}>
   {textDialog&&<div className="session-input-backdrop"><form className="session-input-dialog" role="dialog" aria-modal="true" aria-label={textDialog.label} onSubmit={e=>{e.preventDefault();answerText(textDialog.value);}}><h2 className="section-title">{textDialog.label}</h2><input ref={textInput} aria-label={textDialog.label} readOnly={textDialog.readOnly} maxLength={textDialog.max} value={textDialog.value} onChange={e=>setTextDialog({...textDialog,value:e.target.value})}/><div className="session-text-hints">{textDialog.readOnly?'Ctrl+C: copiar · Enter / Esc: voltar':'Enter: confirmar · Esc: cancelar'}</div></form></div>}
   <div className="session-brand"><b>MX</b><span>FREEROAM / TRAINER</span><small>{shortcutLabel('menu')}</small></div>
   <div className="session-heading"><strong>{confirm?'Confirmar':frame.title}</strong><span>{selected+1} / {rows.length}</span></div>
   <div className="session-rows" role="listbox" aria-label={frame.title} ref={list}>
    {rows.map((r,i)=><div key={r.id} role="option" tabIndex={i===selected?0:-1} aria-selected={i===selected} aria-disabled={r.disabled} onFocus={()=>{memory.current[path]=r.id;repaint();}}  className={`session-row ${i===selected?'selected':''} ${r.disabled?'unavailable':''}`}><span><HeatIcon name={r.id==='vehicle'?'car':r.id==='workshop'?'garage':r.id==='preferences'?'settings':r.id==='trainer'||r.id==='noclip'||r.id==='speed'?'flight':r.id==='players'||frame.id==='players'?'person':r.id==='checkpoint'||r.id==='return'||r.id==='clear'?'checkpoint':r.id==='destinations'||frame.id==='destinations'?'track':r.id==='lock'?'lock':r.id==='eject'?'person':r.id==='respawn'?'reset':r.id==='drift'?'wheel':r.id==='engine'?'engine':r.id==='doors'?'door':r.id==='clean'?'paint':'tools'}/><span>{r.label}</span></span><b className={r.id==='noclip'&&trainer.noclip?'trainer-active':''}>{r.adjust&&<span aria-hidden="true">‹</span>}{r.value??(r.activate?'›':'')}{r.adjust&&<span aria-hidden="true">›</span>}</b></div>)}
   </div>
   <p className="session-detail" role={error?'alert':'status'}>{busy?'Aguardando confirmação…':error||notice||current.detail||'Enter seleciona · ← → ajustam valores'}</p>
   <ControlHints/>
 </aside>;
}
