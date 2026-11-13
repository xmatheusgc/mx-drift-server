import {useState,useRef,type MutableRefObject} from 'react';
import {TabBar} from './TabBar';
import {ColorPanel} from './ColorPanel';
const channels=[['primary','Principal'],['secondary','Secundária'],['pearlescent','Perolado'],['wheelColor','Rodas']];
export function PaintPanel({value,busy,preview,apply,nav}:{value:Record<string,any>;busy:boolean;preview:(v:Record<string,any>)=>void;apply:(v:Record<string,any>)=>void;nav:MutableRefObject<(key:string)=>void>}){
 const [channel,setChannel]=useState('primary'),[candidate,setCandidate]=useState<Record<string,any>|null>(null),[finish,setFinish]=useState<number|undefined>();
 const child=useRef<(key:string)=>void>(()=>{});nav.current=key=>child.current(key);
 const main=channel==='primary'||channel==='secondary',rgbKey=channel==='primary'?'customPrimary':'customSecondary',finishKey=channel+'Finish';
 function patch(color:any){const next={...value,...candidate};if(Array.isArray(color))next[rgbKey]=color;else{next[channel]=color;if(main)next[rgbKey]=false;}if(main&&finish!==undefined)next[finishKey]=finish;return next;}
 return <div className="paint-workspace"><TabBar className="paint-tabs" label="Canais de pintura">{channels.map(([key,label])=><button key={key} className={key===channel?'selected':''} onClick={()=>{if(channel!==key){preview(value);setCandidate(null);setFinish(undefined);setChannel(key);}}}>{label}</button>)}</TabBar><ColorPanel key={channel} title={channels.find(c=>c[0]===channel)![1]} value={main&&value[rgbKey]||value[channel]} indexed={161} allowRgb={main} finish={finish??value[finishKey]} onFinish={main?v=>{setFinish(v);const next={...value,...candidate,[finishKey]:v};setCandidate(next);preview(next);}:undefined} onPreview={color=>{const next=patch(color);setCandidate(next);preview(next);}} onApply={color=>apply(patch(color))} nav={child} busy={busy}/></div>;
}
