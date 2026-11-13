# Transições entre telas — 17/10/2026

Fade preto de 180 ms por etapa nas passagens menu inicial ↔ garagem. A tela anterior permanece até a resposta de destino chegar; somente então escurece, troca o conteúdo e revela após dois frames. Atualizações da mesma tela, abas, categorias e editores não acionam o efeito. Mensagens repetidas durante a troca são consolidadas.

No primeiro acesso, o lobby é pintado sob uma cobertura preta e confirma `lobbyReady`. A loading escurece antes do shutdown manual; `loadingClosed` libera a revelação do lobby. O fundo da loading continua opaco. A preferência do navegador por movimento reduzido elimina a animação; a configuração local de movimento reduzido também elimina o fade de saída da loading.

Implementação: `ui/src/screen-transition.ts`, estilos da NUI e loading, e handshake em `mx-freeroam-experience/client.lua`. Sem alterações de persistência, veículos ou câmeras.

Correção da tela preta: `loadingClosed` é enviado pelo callback `lobbyReady` no resource `mx-freeroam-menu`, após o export de experiência terminar o shutdown. `SendNUIMessage` só alcança a página do próprio resource; o envio anterior pelo resource de experiência não chegava à cobertura do menu. A análise estática verifica esse limite. O efeito usa fundo preto e `opacity`; não depende de filtros ou backdrop-filter.

Verificação: build com typecheck, análise estática, suíte Lua e testes de navegador. O teste de lobby cobre a retenção da cobertura até `loadingClosed`, além dos fluxos existentes em quatro resoluções. Fixtures de navegador não validam a composição entre as duas NUIs do FiveM; verificar conectando ao servidor e alternando lobby/garagem no jogo.
