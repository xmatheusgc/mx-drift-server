import {watchInputBoundary} from './input-boundary';
import React,{useEffect,useState} from 'react';
import {createRoot} from 'react-dom/client';
import {SessionMenu} from './SessionMenu';
import {Speedometer} from './Speedometer';
import {PauseMenu} from './PauseMenu';
import {AdminCoordinateOverlay} from './AdminCoordinateOverlay';
import {CameraDeveloper} from './CameraDeveloper';
import {installCameraDeveloperInput} from './camera-developer-input';
import {Workshop} from './Workshop';
import {Lobby} from './Lobby';
import {WorkshopEntryPrompt} from './WorkshopEntryPrompt';
import './style.css';
import {setUiVolume} from './ui-sound';
import {installScreenTransitions} from './screen-transition';
installScreenTransitions();
installCameraDeveloperInput();
watchInputBoundary();
function Overlay(){
 const [hud,setHud]=useState<any>({}),[session,setSession]=useState<any>(null),[notice,setNotice]=useState(''),[workshop,setWorkshop]=useState(false),[lobby,setLobby]=useState(false);
 useEffect(()=>{const handler=(e:MessageEvent)=>{const m=e.data;if(m.type==='hud')setHud(m.data);if(m.type==='session')setSession(m.data);if(m.type==='notice')setNotice(String(m.message));if(m.type==='workshop'){setWorkshop(!!m.state);if(m.state)setLobby(false);}if(m.type==='lobby'){setLobby(!!m.data);if(m.data)setWorkshop(false);}if(m.type==='uiPreferences')setUiVolume(m.data.volume);};window.addEventListener('message',handler);return()=>window.removeEventListener('message',handler);},[]);
 useEffect(()=>{const t=setTimeout(()=>setNotice(''),6000);return()=>clearTimeout(t);},[notice]);
 return <>{!workshop&&!lobby&&hud.enabled&&<Speedometer data={hud}/>} {!workshop&&!lobby&&session&&<div className="hud activity-overlay" style={{transform:`scale(${hud.scale??1})`}}>{session&&<div className="activity-hud"><b>{session.mode} · {session.state}</b><span>{((session.elapsed??0)/1000).toFixed(2)} s · CP {session.checkpoint??0}/{session.total??0}</span>{session.bestMs&&<span>Melhor {(session.bestMs/1000).toFixed(2)} s</span>}{session.deltaMs!==undefined&&<span>Δ {(session.deltaMs/1000).toFixed(2)} s</span>}{session.reason&&<em>{session.reason}</em>}</div>}</div>}{notice&&<aside className="toast" role="status">{notice}</aside>}<WorkshopEntryPrompt/><SessionMenu/><PauseMenu/><Workshop/><Lobby/></>;
}
createRoot(document.getElementById('root')!).render(<><Overlay/><AdminCoordinateOverlay/><CameraDeveloper/></>);
