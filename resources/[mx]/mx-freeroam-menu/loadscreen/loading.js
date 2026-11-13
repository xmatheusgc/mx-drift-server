const bar=document.getElementById('progress'),stage=document.getElementById('stage'),detail=document.getElementById('detail'),help=document.getElementById('help'),timing=document.getElementById('timing');
const started=Date.now();
let preparing=false,failed=false,lastSignal=started,files=0,totalFiles=0,lastFraction=-1;
const signal=()=>{lastSignal=Date.now();};
function feedback(){
 const now=Date.now(),seconds=Math.floor((now-started)/1000),quiet=Math.floor((now-lastSignal)/1000);
 timing.hidden=seconds<60||failed;
 timing.textContent=seconds>=60&&!failed?`${Math.floor(seconds/60)}:${String(seconds%60).padStart(2,'0')} de espera`:'';
 detail.hidden=!detail.textContent;
 const message=failed?'Reconecte para tentar novamente.':quiet>=300
  ?'Sem avanço? Confira o download do FiveM. Se ele também estiver parado há alguns minutos, tente reconectar.'
  :quiet>=60?'Ainda aguardando uma atualização. O FiveM pode estar preparando arquivos.'
  :seconds>=10?'A primeira entrada pode levar mais tempo.':'';
 if(help.textContent!==message)help.textContent=message;
 help.hidden=!message;
 document.body.toggleAttribute('data-failed',failed);
}
window.addEventListener('message',({data:m})=>{
 if(!m||typeof m!=='object')return;
 if(m.eventName==='mxFadeOut'){
  document.body.style.setProperty('--fade-duration',`${m.duration===0?0:180}ms`);
  document.body.classList.add('leaving');return;
 }
 if(m.eventName==='mxStage'){
  preparing=true;failed=m.error===true;signal();bar.removeAttribute('value');
  stage.textContent=failed?'Não foi possível entrar':'Preparando seu acesso…';
  // Native readiness diagnostics remain in the client logs. Only confirmed
  // errors need their full explanation here; normal heartbeats stay quiet.
  detail.textContent=failed?String(m.message||'A preparação não foi concluída.'):'';
  feedback();return;
 }
 if(preparing||failed)return;
 if(m.eventName==='loadProgress'&&Number.isFinite(m.loadFraction)){
  const fraction=Math.max(0,Math.min(1,m.loadFraction));
  if(fraction!==lastFraction){lastFraction=fraction;signal();}
  if(fraction<1){bar.value=fraction;stage.textContent='Carregando recursos…';detail.textContent=`Recursos ${Math.floor(fraction*100)}%`;
  }else{bar.removeAttribute('value');stage.textContent='Preparando seu acesso…';detail.textContent='';}
 }
 if(m.eventName==='startDataFileEntries'){
  totalFiles=Number.isFinite(m.count)?Math.max(0,m.count):0;files=0;signal();bar.removeAttribute('value');stage.textContent='Preparando arquivos…';
  detail.textContent='';
 }
 if(m.eventName==='onDataFileEntry'){
  files++;signal();stage.textContent='Preparando arquivos…';
  detail.textContent=totalFiles>0?`${Math.min(files,totalFiles)} de ${totalFiles} arquivos`:'';
 }
 if(m.eventName==='endDataFileEntries'){
  signal();totalFiles=0;bar.removeAttribute('value');stage.textContent='Preparando o mundo…';detail.textContent='';
 }
 if(['startInitFunction','startInitFunctionOrder','initFunctionInvoking','initFunctionInvoked','endInitFunction'].includes(m.eventName)){
  signal();bar.removeAttribute('value');stage.textContent='Iniciando o jogo…';detail.textContent='';
 }
 feedback();
});
feedback();setInterval(feedback,1000);
