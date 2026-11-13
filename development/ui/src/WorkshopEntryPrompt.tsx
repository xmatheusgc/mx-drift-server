import {useEffect,useState} from 'react';
import {ControlGlyph,useInputDevice} from './ControlHints';
export function WorkshopEntryPrompt(){
 const [visible,setVisible]=useState(false),device=useInputDevice();
 useEffect(()=>{const message=(e:MessageEvent)=>{if(e.data?.type==='workshopEntry')setVisible(e.data.visible===true);if((e.data?.type==='workshop'&&e.data.state)||(e.data?.type==='lobby'&&e.data.data)||(e.data?.type==='menu'&&e.data.open))setVisible(false);};window.addEventListener('message',message);return()=>window.removeEventListener('message',message);},[]);
 if(!visible)return null;
 return <aside className="workshop-entry-prompt" role="status"><span className="editor-control-hint"><ControlGlyph device={device} action={device==='keyboard'?'tabNext':'navigate'}/>{device!=='keyboard'&&<b aria-label="Direcional direito">→</b>}Entrar na oficina</span></aside>;
}
