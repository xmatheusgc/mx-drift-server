import {nui} from './api';
let nativeNavigation=false;
export function usesNativeNavigation(){return nativeNavigation;}
export function watchInputBoundary(){
 let previous='';
 const textEditing=()=>{const el=document.activeElement;return el instanceof HTMLTextAreaElement||el instanceof HTMLElement&&el.isContentEditable||el instanceof HTMLInputElement&&!['range','checkbox','radio','button','submit'].includes(el.type);};
 const check=()=>{
  const root=document.querySelector<HTMLElement>('.pause-shell,.lobby,.workshop,.session-menu'),editor=root?.querySelector<HTMLElement>('[data-level]');
  const modal=!!root?.querySelector('[data-confirm-dialog],.session-confirm,[aria-modal=true]'),text=textEditing(),tabs=!!root?.querySelector('[data-tab-bar]')&&!modal;
  const character=!!root?.querySelector('[data-character-editor]')&&!modal;
  const context=[character,root?.className,root?.dataset.screen,root?.dataset.page,root?.querySelector('[data-settings-page]')?.getAttribute('data-settings-page'),editor?.dataset.level,editor?.dataset.color,modal,text,tabs].join(':');
  if(context===previous)return;previous=context;
  const settings=!!root?.querySelector('[data-settings-page=general]')&&!modal;
  window.dispatchEvent(new CustomEvent('settingsContext',{detail:settings}));
  void nui('navigationContext',{modal,text,tabs,settings,character}).catch(()=>{});
 };
 new MutationObserver(check).observe(document.body,{childList:true,subtree:true,attributes:true,attributeFilter:['data-screen','data-level','data-color','data-page','data-settings-page','aria-modal']});
 window.addEventListener('focusin',check);window.addEventListener('focusout',()=>queueMicrotask(check));
 window.addEventListener('message',e=>{if(e.data?.type==='nativeNavigation')nativeNavigation=e.data.enabled===true;});
 window.addEventListener('keydown',e=>{
  if(document.querySelector('[data-binding-capture]'))return;
  const navigationKey=['ArrowUp','ArrowDown','ArrowLeft','ArrowRight','Enter','Backspace','Escape'].includes(e.key)||!!document.querySelector('[data-settings-page=general],[data-character-editor]')&&e.code==='Space'||!!document.querySelector('[data-tab-bar]')&&['q','e'].includes(e.key.toLowerCase());
  if(nativeNavigation&&navigationKey&&!textEditing()&&!e.ctrlKey&&!e.altKey&&!e.metaKey||e.repeat&&(e.key==='Enter'||e.key===' ')){
   e.preventDefault();e.stopImmediatePropagation();
  }
 },true);
}
