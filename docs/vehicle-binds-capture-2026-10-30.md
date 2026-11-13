# Motor, setas e captura de atalhos — 2026-10-30

Origem: solicitação do usuário nesta conversa. Base ativa: `txData/FiveMBasicServerCFXDefault_CAECC7.base`.

- Motor: G no teclado; segurar D-pad esquerdo por 700 ms no controle. Mantém a ação existente de ligar/desligar, com serviço autorizado pelo servidor. Um acionamento por pressão, sem disparar ao sair de uma interface segurando o botão. Outro botão configurado para motor também exige o pressionamento longo no controle.
- Seta esquerda/direita: LEFT/RIGHT; pisca-alerta: DOWN. Sem controle atribuído por padrão. Repetir desliga; selecionar outro lado substitui o estado anterior. Somente motorista do veículo gerenciado do próprio jogador. Não invalida atividades por ser uma ação normal de direção.
- Estado das setas confirmado por ACK e publicado em `mxIndicators`, com identidade do veículo. Observadores aplicam ao receber/streamar; há proteção contra identidade reutilizada e eventos atrasados, além de reaplicação ao iniciar o recurso.
- Bloqueados no veículo: rádio 81–85, 332/333; seleção/roda de armas 37, 12–17 e 99/100. O bloqueio é por frame, inclusive para passageiros; cessa a pé. Direção, acelerador, freio e câmera permanecem disponíveis. G usado pelo motor consome também o lançamento de granada 58.
- Os binds são editáveis em Configurações > Atalhos do servidor (pausa e lobby). Novo editor captura a entrada física, sem teclado de texto. Aguarda neutralização inicial; captura somente o dispositivo escolhido, rejeita acordes ambíguos, cancela por ESC/botão na tela ou 15 s. Consome a liberação antes de reativar a navegação; usa as validações/conflitos e o KVP por perfil existentes. Não grava enquanto apenas captura.
- Migração KVP v3: antigos campos vazios de motor recebem G/LEFT se livres; remaps não vazios são mantidos. Após v3, remoções explícitas persistem. LEFT/RIGHT/UP/DOWN passam a ser teclas válidas fora dos menus; navegação nativa continua separada.
- Menu livre já usava 244 para VIEW. D-pad esquerdo/rádio 85 não pode ser interpretado como VIEW, mesmo que o layout reporte 244 junto. Controle nativo 0 só é consumido durante a entrada de menu efetiva, sem bloqueio permanente da troca de câmera. A identificação física Share/touchpad depende do driver; não foi confirmada em controle real.
- mx-gearbox ignora comandos de troca/embreagem com NUI/pausa em foco, inclusive durante captura.

Referências primárias: [controls do Cfx](https://docs.fivem.net/docs/game-references/controls/) (244 e 0 usam BACK na tabela Xbox), [SetVehicleIndicatorLights](https://github.com/citizenfx/natives/blob/master/VEHICLE/SetVehicleIndicatorLights.md) (índice 1 esquerdo, 0 direito).

## Verificação

Build (inclui TypeScript), check, test:controls e test:gearbox aprovados. Testes específicos cobrem defaults/migração/remoção, filtro D-pad, hold/teclado, isolamento de menus, bloqueios por contexto, captura física/liberação/cancelamento, setas e autorização/sincronização/identidade. test:pause aprovado nas quatro resoluções (1280x720, 1920x1080, 2560x1440, 3440x1440), incluindo captura de teclado/controle, cancelamento, ausência de entrada de texto e preservação de abas/editor. Captura 1280 inspecionada visualmente.

`npm test` foi executado e parou em `development/tests/orbit-client.lua:64`: espera FOV 73.5 para a câmera do lobby, enquanto `ExperienceConfig.mainCameras.lobby.fov` atualmente é 60. Esse teste/configuração de câmera não foram alterados nesta tarefa. As verificações específicas de veículos foram executadas separadamente, pois ficam depois desse ponto na suíte geral.

Sem reinício de recursos/servidor, SQL real, clientes FiveM ou controle físico. Pendente: carregar menu/vehicles/gearbox atualizados e validar PS4/Xbox, motor, setas vistas por outro jogador e captura em jogo, incluindo conflitos e reconexão.

Resultado adicional: test:lobby aprovado nas quatro resolucoes, sem erros JavaScript reportados.
