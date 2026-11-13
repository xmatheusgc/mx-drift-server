declare global { interface Window { GetParentResourceName?:()=>string } }
export type Reply<T=unknown>={ok:boolean;data?:T;code?:string;message?:string};
export async function nui<T>(action:string,data:unknown={}):Promise<T>{
  if(!window.GetParentResourceName) throw Error('NUI desconectada. Abra dentro do FiveM para usar dados reais.');
  const response=await fetch(`https://${window.GetParentResourceName()}/${action}`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(data),signal:AbortSignal.timeout(245000)});
  const result:Reply<T>=await response.json(); if(!result.ok) throw Error(`${result.code??'ERRO'}: ${result.message??'Ação não confirmada'}`); return result.data as T;
}
let requestTail:Promise<unknown>=Promise.resolve();
let lastCosmetic=0;
let lastCharacter=-10000;
const lastCatalogStart:Record<string,number>={};
const lastTrainerStart:Record<string,number>={};
export const api=<T=any>(domain:string,action:string,data:unknown={}):Promise<T>=>{
  const request=requestTail.catch(()=>{}).then(async()=>{
    const cosmetic=domain==='experience'&&action==='cosmetic';
    if(domain==='experience'&&action==='character'){
      const delay=500-(performance.now()-lastCharacter);if(delay>0)await new Promise(resolve=>setTimeout(resolve,delay));
      lastCharacter=performance.now();
    }
    if(domain==='vehicles'&&['catalog','catalogBrands'].includes(action)){
      const delay=160-(performance.now()-(lastCatalogStart[action]??-10000));if(delay>0)await new Promise(resolve=>setTimeout(resolve,delay));
      lastCatalogStart[action]=performance.now();
    }
    if(domain==='world'&&['trainerState','noclip','saveCheckpoint','returnCheckpoint','clearCheckpoint'].includes(action)){
      const delay=160-(performance.now()-(lastTrainerStart[action]??-10000));if(delay>0)await new Promise(resolve=>setTimeout(resolve,delay));
      lastTrainerStart[action]=performance.now();
    }
    if(cosmetic){const delay=500-(performance.now()-lastCosmetic);if(delay>0)await new Promise(resolve=>setTimeout(resolve,delay));}
    try{return await nui<T>('request',{domain,action,data});}
    finally{if(cosmetic)lastCosmetic=performance.now();}
  });
  requestTail=request;return request;
};
export const uuid=()=>crypto.randomUUID();
