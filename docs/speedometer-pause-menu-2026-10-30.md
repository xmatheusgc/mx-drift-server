# Velocímetro e menu lateral de sessão — 2026-10-30

Pedido do usuário: adaptar somente o velocímetro do seu `C:\FiveM\nativecore\txData\nativecore_23B050.base\resources\[scripts]\mx-hud`, permitir ocultar velocímetro/minimapa nas configurações do lobby e interceptar o acesso ao mapa com um menu lateral utilizável por teclado, mouse e controle.

## Entrega

- `Speedometer.tsx` e CSS reproduzem o mostrador de referência: arco de RPM de 240°, marcha central, velocidade, leitura visual de RPM em escala de 8000, mudança branco/amarelo/vermelho, indicadores do veículo, combustível e distância da sessão. Adaptado para React/TypeScript e CSS local; sem Tailwind, Font Awesome, HUD de necessidades ou instrumentos de voo.
- Fonte Anta servida localmente com licença OFL (`development/ui/public/fonts` e `docs/licenses/anta-OFL.txt`). Ícones de instrumentação em SVG local. Nenhuma dependência de CDN no jogo.
- `menu/hud.lua`: velocidade real, RPM normalizado, marcha nativa ou dados do mx-gearbox ativo, marcha à ré, luzes, freio de mão, saúde do motor e combustível. Combustível é percentual, pois a native não fornece litros. Hodômetro é da sessão, sem persistência e ignora saltos de teleporte; não é quilometragem histórica. ABS/TC só acendem se estados explícitos `absActive` / `tractionControlActive` estiverem publicados; não inventa atuação com heurísticas de velocidade.
- Velocímetro aparece somente em veículo no modo livre. HUD de atividade foi preservado e separado do mostrador. Sem alteração de handling, combustível ou física.
- `Preferences` compartilhado pelo lobby e menu lateral tem toggles separados de Velocímetro (`hud` existente) e Minimapa (`minimap`). Preferências usam o documento/revisão SQL existente. Perfis antigos recebem minimap=true em memória; o campo entra no documento na próxima gravação normal, sem migration/descarte. Campo opcional ausente normaliza para true; valores de tipo incorreto são rejeitados.
- `PauseMenu.tsx`: sombra em gradiente da esquerda para a direita e cinco opções solicitadas: **Mapa & opções do jogo** (frontend nativo), **Configurações** (mesmo componente do lobby), **Discord** desabilitado, **Voltar para a garagem** com confirmação e **Sair do servidor** com confirmação. Cancelar é a seleção inicial dos modais. Conteúdo atrás do modal fica inert.
- Saída usa ação autenticada `core:disconnect` para desconectar somente o próprio jogador. Não encerra o processo do GTA ou o servidor. Entrada na garagem reutiliza OpenGarage; falha recupera a cena e reabre o menu com erro.

## Controles e foco

- ESC e ação nativa de pausa (Options no PlayStation / Menu no Xbox) abrem o menu lateral no modo livre.
- Revisão após resposta do usuário: lateral usa somente os controls nativos 200 (INPUT_FRONTEND_PAUSE_ALTERNATE / ESC) e 199 (INPUT_FRONTEND_PAUSE / P, Start/Menu). Removidos os mappings físicos adicionais Share/View e touchpad.
- Menu livre mantém M e o binding de controle configurável existente (padrão View/touchpad via ação 244), com suas regras de remapeamento e remoção. Share/View não é forçado a abrir o lateral.
- Navegação por setas/direcional/analógico; Enter/X/A confirma; ESC/Círculo/B retorna. Mouse e cursor habilitados somente na tela lateral/configurações/modal; o trainer mantém seu comportamento de teclado/controle sem cursor.
- A tela lateral bloqueia ações de gameplay enquanto está aberta. Pausa nativa libera a NUI e abre `FE_MENU_VERSION_MP_PAUSE` com componente -1 (mapa); após fechar, há guarda curta para não reabrir o lateral com o mesmo pressionamento. Lobby/garagem/loading/teclado virtual e outra NUI mantêm seus contextos.

Fontes primárias: [controles nativos Cfx](https://docs.fivem.net/docs/game-references/controls/), [SELECT_INDEX / TOUCH_INDEX](https://docs.fivem.net/docs/game-references/input-mapper-parameter-ids/pad_digitalbutton/), [frontend nativo CitizenFX](https://github.com/citizenfx/natives/blob/master/HUD/ActivateFrontendMenu.md), [fonte Anta/OFL](https://github.com/google/fonts/tree/main/ofl/anta).

## Verificação

- Build/TypeScript e `npm.cmd --prefix development run check` aprovados; build servido atualizado.
- `npm.cmd --prefix development run test:pause`: natives simuladas para abertura/foco/entrada nativa, controls 199/200 e ausência de mappings físicos extras, confirmação obrigatória, recuperação de garagem, rota de saída, telemetria, compatibilidade com gearbox, hodômetro e independência HUD/radar; validação real das preferências extraída do core com casos legado/false/tipo inválido.
- Browser Playwright/Chrome instalado: 1280×720, 1920×1080, 2560×1440 e 3440×1440, com seleção por teclado e mensagens de controle, mouse, persistência simulada das configurações compartilhadas, cancelamento/aceite de confirmações, ação de mapa, Discord indisponível, fonte local e limites do viewport. Capturas de dial, menu, settings e confirmação em `docs/evidence`; 1280×720 inspecionado visualmente. Cenário de fundo é fixture, não captura FiveM.
- `node development/tests/menu-controller.mjs` e `npm.cmd --prefix development run test:ui` aprovados, preservando regressões do trainer/menu anterior.
- `npm.cmd --prefix development run test:lobby` aprovado em quatro resoluções, incluindo configurações compartilhadas, loading e onboarding.
- Resultados específicos: `docs/evidence/pause-hud-2026-10-30.json`.

Sem reinício de resource/servidor, alteração SQL ao vivo, desconexão real ou teste com controle físico/FiveM. Compatibilidade de driver e acesso ao frontend nativo ainda precisam de validação real.

## Próximo passo

Reiniciar o servidor em momento adequado e reconectar: o core ganhou validação de preferência e rota de saída; reiniciar só o core desconecta usuários por design existente. Testar mostrador a pé/dirigindo/manual/drift, salvar toggles no lobby e conferir após reconexão, abrir por ESC/Share/View/Options/Menu, navegar com os três dispositivos, abrir/fechar mapa nativo, cancelar/confirmar garagem e finalmente testar saída. Validar que touchpad continua no trainer e Share/View abre o lateral conforme o driver.

Revisão de controles validada com pause-hud.mjs, menu-controller.mjs e check. Alteração só em Lua/testes; sem novo build NUI necessário. Sem restart ou controle físico testado.
