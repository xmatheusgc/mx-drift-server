// Installed before component listeners so authoring cannot trigger the workshop.
let enabled=false;
export const setCameraDeveloperInput=(value:boolean)=>{enabled=value;};
export function installCameraDeveloperInput(){
 for(const type of ['keydown','keyup'] as const)window.addEventListener(type,e=>{
  if(!enabled)return;
  e.stopImmediatePropagation();
  const input=e.target instanceof Element&&!!e.target.closest('input,textarea,[contenteditable=true]');
  if(type==='keydown'&&e.code==='Enter'&&e.target instanceof HTMLInputElement&&e.target.type==='number'){
   e.preventDefault();e.target.blur();
  }
  if(!input&&['KeyW','KeyA','KeyS','KeyD','KeyQ','KeyE','Escape'].includes(e.code))e.preventDefault();
  window.dispatchEvent(new CustomEvent('cameraDeveloperKey',{detail:{code:e.code,down:type==='keydown',repeat:e.repeat,input,shift:e.shiftKey,ctrl:e.ctrlKey}}));
 },true);
 window.addEventListener('wheel',e=>{
  if(enabled&&e.target instanceof HTMLInputElement&&e.target.type==='number')e.preventDefault();
 },{capture:true,passive:false});
}
