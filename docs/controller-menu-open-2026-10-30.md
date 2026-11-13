# Abertura do menu livre pelo controle — 2026-10-30

Pedido: abrir o menu livre pelo clique do touchpad no PS4 e botão equivalente no Xbox.

O menu tinha navegação por controle, mas o binding padrão de abertura tinha apenas M. Adicionado `VIEW` ao registro de bindings, associado a `INPUT_INTERACTION_MENU` (244): Back/View no Xbox e ação equivalente do touchpad em controle PlayStation reconhecido pelo jogo. [Referência oficial dos controles Cfx](https://docs.fivem.net/docs/game-references/controls/).

`bindings.lua`: menu inicia com teclado M e pad VIEW. Separada leitura de pad para evitar que a tecla nativa M contorne remapeamento de teclado e para deixar o teclado sob responsabilidade da NUI quando há foco. Abertura e fechamento pelo pad usam borda de pressionamento; segurar não repete. O poll consome interação nativa e troca de câmera (0) quando VIEW está atribuído ao menu e o dispositivo ativo é controle.

O poll permite somente a ação menu via controle enquanto o trainer tem foco; demais atalhos continuam bloqueados nesse contexto. Pausa, teclado virtual, modal de texto, câmera de desenvolvimento, lobby, garagem e foco de outra NUI impedem abertura/alternância pelo pad. Fechamento limpa o estado local de modal para não bloquear a próxima abertura. Movimento, aceleração e freio permanecem disponíveis no menu livre normal.

Perfis antigos sem botão do menu recebem VIEW na carga, com persistência versionada (`_version=2`). Teclas e botões já personalizados são preservados. Remoção ou remapeamento feitos após a atualização sobrevivem à reconexão. A interface permite VIEW na configuração e apresenta Touchpad nos hints PlayStation; fallback da interface também atualizado. Build servido atualizado.

Verificação: `node development/tests/menu-controller.mjs`, build/TypeScript e `npm.cmd --prefix development run check` aprovados. Runner específico reutiliza regressões de bindings e bridge do trainer, adicionando migração, remoção persistente, colisões, isolamento teclado/pad, controles habilitados/desabilitados, abrir/fechar, segurar, supressão de câmera e bloqueios de contexto. Incluído no runner geral Lua. Testes usam natives/input simulados; sem controle físico/FiveM e sem reiniciar resource nesta etapa.

Próximo passo: recarregar `mx-freeroam-menu`, reconectar para carregar bindings do perfil e testar clique no touchpad PS4 e View no Xbox, a pé e dirigindo. Confirmar ausência de troca da câmera e que remapeamento/remoção continuam salvos. Um toque abre e outro fecha; não precisa manter pressionado.
