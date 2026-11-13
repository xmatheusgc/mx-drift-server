# Oficina: navegação, acelerador e confirmação de suspensão

## Alterações

- O menu da garagem cede explicitamente os eventos `nav` e `workshopBack` ao editor ou ao modal aberto. Um listener de `message` registrado anteriormente podia tratar o retorno antes do listener do editor e sair para a tela principal. Não dependemos mais da ordem dos listeners para impedir isso.
- Esc/Backspace na faixa de opções consomem o evento e ignoram repetição de tecla, preservando o retorno de um nível e a seleção do menu anterior.
- Peças confirmadas recebem o mesmo CHECK dos extras e neons. Destacar uma prévia não muda a indicação da configuração confirmada.
- Suspensão fica em prévia enquanto os sliders são ajustados. Ao voltar com alterações, o modal oferece **Manter alterações** ou **Restaurar anterior**. Esc/B cancela o modal e continua a edição. Manter usa a persistência existente; restaurar reaplica a última configuração confirmada, sem gravá-la novamente. Falhas mantêm o modal aberto e mostram o erro. Não há aplicação por Enter ou soltura do mouse no slider.
- O gatilho passa a usar intensidade de 0 a 1, com zona morta de 0,05. A leitura usa `INPUT_SCRIPT_RT` (229), separada da saída de aceleração (71), evitando realimentar o controle injetado. Heartbeats da NUI para W são ignorados enquanto o dispositivo ativo é o controle.
- A partida bloqueia aceleração e injeção de RPM até o native informar motor em funcionamento, mais **150 ms** configuráveis em `ExperienceConfig.engineTest.startupDelay` (antes: 250 ms). O freio de mão permanece aplicado. O limitador só é simulado na apresentação com gatilho praticamente completo; gatilho parcial mantém intensidade proporcional. Nenhuma alteração de handling ou transmissão.

Referência de identificação dos controles: [documentação oficial Cfx](https://docs.fivem.net/docs/game-references/controls/).

## Verificação

- `npm.cmd --prefix development test`: passou; regressões de aceleração parcial, zero, ruído, saturação, bloqueio da partida e separação entre NUI e controle. Natives e transporte são simulados.
- `npm.cmd --prefix development run build`: passou, incluindo TypeScript e bundle NUI.
- `npm.cmd --prefix development run typecheck` e `run check`: passaram.
- `npm.cmd --prefix development run test:ui`: fluxos de retorno por teclado/controle, CHECK confirmado e suspensão com manutenção, restauração e cancelamento. Resultado por resolução em `docs/evidence/ui.json`; capturas `stance-review-*` e `heat-wheel-options-*`.

Não foi executado um cliente FiveM. Testes de navegador usam mensagens de controle e respostas de persistência controladas: não comprovam leitura de um gamepad físico, áudio de partida/corte, vibração da carroceria, física ou streaming de um veículo modificado. Confirmar esses pontos no jogo, incluindo ER34N, alternância entre W e gatilho, pressões parciais e reconexão após manter a suspensão.
