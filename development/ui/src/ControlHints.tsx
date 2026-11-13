import {useEffect,useState} from 'react';
import {inputIcons} from './input-icons';
export type InputDevice='keyboard'|'xbox'|'playstation';
export type ControlAction='saveCharacter'|'applySettings'|'back'|'view'|'rev'|'select'|'apply'|'navigate'|'tabPrev'|'tabNext'|'save'|'night'|'doors';
export function controllerFamily():InputDevice{
 const pads=navigator.getGamepads?.()??[];
 return Array.from(pads).some(p=>p&&/054c|sony|dualsense|dualshock|playstation/i.test(p.id))?'playstation':'xbox';
}
let lastDevice:InputDevice='keyboard';
let controllerStyle='auto';
export function useInputDevice(){
 const [device,setDevice]=useState(lastDevice);
 useEffect(()=>{
  const update=(value:InputDevice)=>{lastDevice=value;setDevice(value);};
  const keyboard=()=>update('keyboard');
  const message=(e:MessageEvent)=>{if(e.data?.type==='workshopInputDevice'){if(['auto','xbox','playstation'].includes(e.data.style))controllerStyle=e.data.style;update(e.data.device==='keyboard'?'keyboard':controllerStyle==='playstation'?'playstation':controllerStyle==='xbox'?'xbox':controllerFamily());}};
  window.addEventListener('keydown',keyboard,true);window.addEventListener('pointerdown',keyboard,true);window.addEventListener('message',message);
  return()=>{window.removeEventListener('keydown',keyboard,true);window.removeEventListener('pointerdown',keyboard,true);window.removeEventListener('message',message);};
 },[]);return device;
}
const symbols={keyboard:{saveCharacter:'keyboard_space',applySettings:'keyboard_space',doors:'keyboard_space',night:'keyboard_s',save:'keyboard_s',back:'keyboard_escape',view:'keyboard_c',rev:'keyboard_w',select:'keyboard_enter',apply:'keyboard_enter',navigate:'keyboard_arrows_all',tabPrev:'keyboard_q',tabNext:'keyboard_e'},xbox:{saveCharacter:'xbox_button_x',applySettings:'xbox_button_x',doors:'stick_press',night:'xbox_button_x',save:'xbox_button_x',back:'xbox_button_b',view:'xbox_button_y',rev:'xbox_rt',select:'xbox_button_a',apply:'xbox_button_a',navigate:'xbox_dpad_all',tabPrev:'xbox_lb',tabNext:'xbox_rb'},playstation:{saveCharacter:'playstation_button_square',applySettings:'playstation_button_square',doors:'stick_press',night:'playstation_button_square',save:'playstation_button_square',back:'playstation_button_circle',view:'playstation_button_triangle',rev:'playstation_trigger_r2',select:'playstation_button_cross',apply:'playstation_button_cross',navigate:'playstation_dpad_all',tabPrev:'playstation_trigger_l1',tabNext:'playstation_trigger_r1'}} as const;
const labels={saveCharacter:'Salvar',applySettings:'Aplicar alterações',doors:'Abrir / fechar portas',night:'Dia / noite',save:'Salvar ve\u00edculo',back:'Voltar',view:'Mudar visão',rev:'Testar motor',select:'Selecionar',apply:'Aplicar customização',navigate:'Navegar',tabPrev:'Aba anterior',tabNext:'Próxima aba'};
const accessible={keyboard:{saveCharacter:'ESPAÇO',applySettings:'ESPAÇO',doors:'ESPAÇO',night:'S',save:'Ctrl+S',back:'Esc',view:'C',rev:'W',select:'Enter',apply:'Enter',navigate:'Setas',tabPrev:'Q',tabNext:'E'},xbox:{saveCharacter:'X',applySettings:'X',doors:'L3',night:'X',save:'X',back:'B',view:'Y',rev:'RT',select:'A',apply:'A',navigate:'Direcional',tabPrev:'LB',tabNext:'RB'},playstation:{saveCharacter:'Quadrado',applySettings:'Quadrado',doors:'L3',night:'Quadrado',save:'Quadrado',back:'Círculo',view:'Triângulo',rev:'R2',select:'X',apply:'X',navigate:'Direcional',tabPrev:'L1',tabNext:'R1'}};
export function ControlGlyph({device,action}:{device:InputDevice;action:ControlAction}){
 return <img className="control-glyph" src={inputIcons[symbols[device][action]]} alt={accessible[device][action]}/>;
}
export function ControlHints({device:explicit,actions}:{device?:InputDevice;actions?:ControlAction[]}){
 const [settings,setSettings]=useState(false);
 useEffect(()=>{const handler=(e:Event)=>setSettings((e as CustomEvent).detail===true);window.addEventListener('settingsContext',handler);return()=>window.removeEventListener('settingsContext',handler);},[]);
 const current=useInputDevice(),device=explicit??current;
 const shown=actions??(settings?['navigate','select','applySettings','back'] as ControlAction[]:['navigate','select','back'] as ControlAction[]);
 return <div className="editor-control-hints" aria-label="Controles" data-device={device}>{shown.map(action=><span className="editor-control-hint" key={action}><ControlGlyph device={device} action={action}/>{labels[action]}</span>)}</div>;
}
