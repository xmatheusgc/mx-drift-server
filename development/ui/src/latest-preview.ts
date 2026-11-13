// One HTTP preview at a time. Intent invalidation bypasses that queue so the
// server can stop an older native/model load before its callback completes.
export class LatestPreview {
  constructor(private readonly delay=0){}
  private generation=0;
  private interruptDelay:(()=>void)|undefined;
  private tail:Promise<void>=Promise.resolve();
  cancel(){this.generation++;this.interruptDelay?.();}
  idle(){return this.tail;}
  choose<T>(invalidate:()=>Promise<unknown>,load:()=>Promise<T>,apply:(value:T)=>void,fail:(error:unknown)=>void,delay=this.delay){
    const generation=++this.generation;
    this.interruptDelay?.();
    const intent=invalidate(); // sent immediately, never wait behind an old load
    this.tail=this.tail.catch(()=>{}).then(async()=>{
      await intent;
      if(generation!==this.generation)return;
      if(delay){
        await new Promise<void>(resolve=>{
          const finish=()=>{clearTimeout(timer);if(this.interruptDelay===finish)this.interruptDelay=undefined;resolve();};
          const timer=setTimeout(finish,delay);this.interruptDelay=finish;
        });
        if(generation!==this.generation)return;
      }
      try{const value=await load();if(generation===this.generation)apply(value);}
      catch(error){if(generation===this.generation)fail(error);}
    }).catch(error=>{if(generation===this.generation)fail(error);});
    return this.tail;
  }
}
