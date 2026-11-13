import {ControlGlyph,useInputDevice} from './ControlHints';
export function NavigationReference(){
 const device=useInputDevice();
 return <section className="navigation-reference" aria-label="Navegação da interface"><p>A navegação acompanha os controles do GTA V. Os atalhos das funções do servidor ficam na lista separada.</p>
 {([['navigate','Mover seleção'],['select','Confirmar'],['back','Voltar'],['tabPrev','Aba anterior'],['tabNext','Próxima aba']] as const).map(([action,label])=><div key={action}><span>{label}</span><ControlGlyph device={device} action={action}/></div>)}
 <div><span>Menu de pausa</span><b>{device==='keyboard'?'ESC / P':device==='playstation'?'Options':'Menu'}</b></div>
 </section>;
}
