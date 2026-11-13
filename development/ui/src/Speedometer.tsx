// Adapted from the owner's mx-hud Speedometer.jsx; no framework/status HUD dependency.
export type SpeedometerData={enabled?:boolean;speed?:number;units?:string;rpm?:number;gear?:number|string;fuel?:number;odometer?:number;highBeam?:boolean;lowBeam?:boolean;handbrake?:boolean;engineHealth?:number;abs?:boolean;tc?:boolean;scale?:number};
function Indicator({kind}:{kind:'light'|'traction'|'brake'|'engine'|'fuel'}){
 const paths={light:<><path d="M12 5c-5 0-8 3-8 7s3 7 8 7V5Z"/><path d="m16 6 5-2m-5 6 6-1m-6 5 6 1m-6 3 5 2"/></>,traction:<><path d="m5 12 2-6h10l2 6v5H5v-5Zm1 0h12M8 17v2m8-2v2M4 21l3 1m10-1 3 1"/><path d="M7 14h2m6 0h2"/></>,brake:<><circle cx="12" cy="12" r="7"/><path d="M4 5a10 10 0 0 0 0 14M20 5a10 10 0 0 1 0 14m-10-2V7h3a3 3 0 0 1 0 6h-3"/></>,engine:<><path d="M5 8h3V5h9v3h3v10H7l-2-3H2V9h3Zm5-5h6M22 9v8"/><path d="m13 8-2 5h4l-2 4"/></>,fuel:<><path d="M5 21V3h10v18M3 21h14M7 6h6v5H7Zm9 1 4 4v7c0 3-3 3-3 0v-4h-2"/><path d="m18 5 3 3v4"/></>};
 return <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">{paths[kind]}</svg>;
}
export function Speedometer({data}:{data:SpeedometerData}){
 const rpm=Math.max(0,Math.min(1,Number(data.rpm)||0)),t=Math.max(0,Math.min(1,(rpm-.82)/.13));
 const color=rpm<.82?'rgba(255,255,255,.9)':`rgb(${Math.round(254+t)},${Math.round(254-224*t)},${Math.round(12-12*t)})`;
 const circumference=2*Math.PI*80,arc=circumference*240/360;
 const gear=data.gear===-2?'P':data.gear===-1?'R':data.gear===0?'N':data.gear??'—';
 const fuel=Math.max(0,Math.min(100,data.fuel??0));
 return <div className="mx-speedometer" aria-label="Velocímetro" style={{transform:`scale(${data.scale??1})`}}>
  <div className="speedometer-dial">
   <svg className="speedometer-arc" viewBox="0 0 200 200" aria-hidden="true"><circle cx="100" cy="100" r="80" fill="none" stroke="rgba(255,255,255,.05)" strokeWidth="12" strokeDasharray={`${arc} ${circumference}`}/><circle className="speedometer-fill" cx="100" cy="100" r="80" fill="none" stroke={color} strokeWidth="12" strokeDasharray={`${arc} ${circumference}`} strokeDashoffset={arc*(1-rpm)}/></svg>
   <div className="speedometer-speed"><strong>{Math.max(0,Math.round(data.speed??0))}</strong><small>{data.units??'km/h'}</small></div>
   <div className="speedometer-indicators"><span title="Faróis" style={{color:data.highBeam?'#3b82f6':data.lowBeam?'#4ade80':undefined}}><Indicator kind="light"/></span><span title="ABS" className={data.abs?'warning':''}>ABS</span><span title="Tração" className={data.tc?'warning':''}><Indicator kind="traction"/></span><span title="Freio de mão" className={data.handbrake&&gear!=='N'?'critical':''}><Indicator kind="brake"/></span></div>
   <strong className={`speedometer-gear ${rpm>=.95?'redline':''}`} style={{color}} aria-label="Marcha">{gear}</strong>
   <div className="speedometer-rpm" style={{color}}><strong>{Math.round(rpm*8000)}</strong><small>rpm</small></div>
   <span className={`speedometer-engine ${(data.engineHealth??1000)<=800?'warning':''}`} title="Motor"><Indicator kind="engine"/></span>
   <div className="speedometer-odometer">{(data.odometer??0).toFixed(1)} km</div>
   <div className="speedometer-fuel"><Indicator kind="fuel"/><span>{Math.round(fuel)}%</span><div><i style={{width:`${fuel}%`}}/></div></div>
  </div>
 </div>;
}
