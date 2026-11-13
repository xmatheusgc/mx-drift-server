let volume=.3,context:AudioContext|undefined,last=-Infinity;
export function setUiVolume(value:number){if(Number.isFinite(value))volume=Math.max(0,Math.min(1,value));}
export function uiSound(){
 const now=performance.now();if(volume<=0||now-last<65)return;last=now;
 try{context??=new AudioContext();void context.resume();
 const length=Math.ceil(context.sampleRate*.022),buffer=context.createBuffer(1,length,context.sampleRate),data=buffer.getChannelData(0);
 for(let i=0;i<length;i++)data[i]=(Math.random()*2-1)*Math.exp(-i/(length*.16));
 const source=context.createBufferSource(),filter=context.createBiquadFilter(),gain=context.createGain();
 source.buffer=buffer;filter.type='lowpass';filter.frequency.value=1100;gain.gain.value=volume*.055;
 source.connect(filter);filter.connect(gain);gain.connect(context.destination);source.start();source.onended=()=>{source.disconnect();filter.disconnect();gain.disconnect();};
 }catch{/* Audio must never block navigation. */}
}
