# Navegação nativa e atalhos do servidor — 2026-10-30

Origem: usuário aprovou usar controls originais do jogo para navegar pela interface e manter configuráveis somente as ações próprias do servidor.

## Comportamento entregue

`InterfaceNavigation.read`, em `menu/navigation.lua`, centraliza leitura/consumo dos controls de frontend para teclado e controle: 187–190 (direções), 201 (confirmar), 202/200 (voltar), 205/206 (abas). Pausa mantém 199/200; 199 também retorna no lateral. Analógico e direcional usam o mesmo gate de pressão/repetição e exigem neutralização ao mudar de contexto.

Lobby, oficina, trainer e lateral usam esse caminho compartilhado. A NUI informa foco de texto, presença de abas e modal para evitar navegação atrás de campos/confirmações. Em jogo, as mensagens nativas substituem o processamento DOM duplicado das teclas básicas; digitação, caret e controles HTML de texto permanecem no CEF. Browser de desenvolvimento mantém fallback por teclado. O editor administrativo de câmera mantém seu próprio contexto, sem ser bloqueado pelo novo bridge.

Com uma interface focada, atalhos de gameplay não são despachados pelo poll de bindings nem pelo teclado do trainer em modo nativo. O atalho de menu é usado para abrir; voltar/fechar a interface usa o control nativo de cancelar, evitando que um binding de servidor em A/X interfira com confirmar. Atalhos contextuais de edição da oficina e a lógica de condução/noclip não foram reescritos.

Configurações compartilhadas de lobby/lateral têm três seções: **Geral**, **Navegação** e **Atalhos do servidor**. Navegação é referência sem edição, com ícones do dispositivo e pausa ESC/P ou Options/Menu. Atalhos permite alterar/remover teclado/pad das funções existentes e reutiliza o mesmo registro, validação e KVP por perfil. Para entrada do atalho, usa o teclado nativo já disponível. Nenhum atalho salvo foi removido/resetado e nenhuma tecla de outro resource foi desassociada.

Em **Controles** do trainer, a referência **Navegação** e a lista **Atalhos do servidor** também ficam em grupos separados. Edição de atalho usa retorno próprio antes de sair das configurações; modais continuam com prioridade de foco. Navegação nativa não é registrada como ação editável no backend.

Referência primária dos IDs e padrões: [Cfx — Controls](https://docs.fivem.net/docs/game-references/controls/). Os ícones locais mostram os padrões por família do dispositivo; não foi implementada uma tradução dinâmica dos glyphs de todo remapeamento possível das configurações do GTA.

## Verificação

- Build/TypeScript e `npm.cmd --prefix development run check` aprovados; build servido atualizado.
- `npm.cmd --prefix development run test:controls`: gate anterior + navegação nativa nos dois dispositivos, aceitar/cancelar, abas somente no contexto, isolamento de texto, repetição e confirmação segurada entre telas; testes existentes de bindings/trainer com prioridade do cancel nativo atualizados e aprovados.
- `npm.cmd --prefix development run test:pause`: bridge nativo, confirmações/recuperação/telemetria existentes e browser em 1280×720, 1920×1080, 2560×1440 e 3440×1440. Inclui referência sem edição, remapeamento de função do servidor, troca de abas, ausência de navegação DOM duplicada com bridge nativo ativo, retorno de editor e preservação das preferências gerais.
- `test:ui` aprovado em quatro resoluções com a nova hierarquia de controles; `test:lobby` aprovado em quatro resoluções com as configurações compartilhadas.
- Captura final `docs/evidence/native-navigation-1280x720.png` inspecionada visualmente. A barra de abas foi corrigida para não herdar a disposição vertical do menu lateral. Relatório de browser: `docs/evidence/pause-hud-2026-10-30.json`.

Testes usam natives/input/persistência simulados e browser; sem controle físico, SQL ao vivo ou FiveM. Nenhum resource/servidor reiniciado. O teste não comprova as particularidades dos drivers de controle nem do foco CEF em execução real.

Próximo passo: recarregar `mx-freeroam-menu` e reconectar se necessário; testar navegação básica nos quatro contextos, digitação e cancelamento, Q/E ou L1/R1/LB/RB nas abas, atalho de servidor remapeado para um botão de confirmar, teclado virtual e persistência do binding ao reconectar. Ações de gameplay devem voltar a responder ao sair do menu.
