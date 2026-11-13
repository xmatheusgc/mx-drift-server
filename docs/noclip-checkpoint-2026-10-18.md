# Noclip e retorno ao checkpoint

## Referência

Consultados o [Noclip.cs original do vMenu, de Tom Grobbe](https://github.com/TomGrobbe/vMenu/blob/master/vMenu/Noclip.cs) e a [licença do projeto](https://github.com/TomGrobbe/vMenu/blob/master/LICENSE.md). A licença exige atribuição e restringe venda de código derivado. Nenhum código do vMenu foi incorporado: a implementação Lua continua própria, usando a referência de comportamento (oito níveis, Shift para alternar velocidade, Q/Z para altura, H para orientação e apresentação translúcida).

Os equivalentes de controle vêm da [tabela oficial Cfx](https://docs.fivem.net/docs/game-references/controls/). A visualização local utiliza a native documentada [SetEntityLocallyVisible](https://github.com/citizenfx/natives/blob/master/NETWORK/SetEntityLocallyVisible.md), reativada por frame.

## Noclip

- F2 continua ativando/desativando.
- W/S ou analógico vertical movem para frente/trás em um plano horizontal; olhar para cima/baixo não altera a altura.
- Q sobe e Z desce. No controle, RB/R1 sobe e direcional para baixo desce.
- Shift alterna os oito níveis; A no Xbox ou X no PlayStation é o equivalente nativo. Não há repetição enquanto a tecla permanece segurada.
- H alterna entre seguir a direção da câmera e orientação fixa; no controle, direcional para a direita. Em orientação fixa, A/D ou eixo horizontal do analógico giram a entidade. Mouse/analógico direito continuam olhando ao redor.
- Níveis: 2, 5, 10, 25, 50, 100, 200 e 400 m/s. Padrão: Normal, 10 m/s. São velocidades próprias, independentes de FPS; não reproduzem a fórmula de velocidade do vMenu.
- Configuração central em `resources/[mx]/mx-freeroam-world/trainer-config.lua`.
- Menu permite escolher velocidade e orientação. O indicador mostra nível, modo e controles do dispositivo. O trainer continua sem interação por mouse.

Colisão permanece desativada durante o voo, sem alternância entre frames. A entidade fica translúcida para o usuário; no carro, a mesma apresentação é aplicada ao motorista. Alpha, visibilidade, colisão e estado original de congelamento são restaurados ao sair, inclusive em limpeza por perda de controle/recurso/contexto. A câmera de condução opcional continua sendo suspensa pelo contrato existente.

Servidor mantém autorização por token e regras de posse, motorista, passageiros e contexto público. O evento `mx:trainer:settings {token,speed,followCamera}` apenas sincroniza opções de uma autorização atual, com validação de época, token, bucket e limites. Velocidade e orientação são preservadas ao desligar/ligar dentro da mesma sessão; não são gravadas no banco.

## Checkpoint

O bloqueio relatado vinha do retorno depender de `HasCollisionLoadedAroundEntity`, não de uma regra explícita de inclinação. Essa condição foi removida **apenas do retorno ao checkpoint**. `RequestCollisionAtCoord` é enviado como solicitação de streaming, sem espera nem reprovação por seu resultado. Viagens normais e preparação da garagem mantêm suas políticas próprias de carregamento.

O servidor passa `checkpoint=true` no contrato de viagem. O cliente aplica posição, heading, pitch e roll capturados pelo servidor, zera velocidade e libera o congelamento temporário. Não usa ajuste ao solo nem altura recalculada, preservando o ponto em rampas/declives. Não cria outro veículo. A reserva desse ponto pessoal também deixou de depender de o destino inicial do mapa estar aprovado.

Permanecem posse, motorista, passageiros, bucket público, identidade de rede e ocupação por terceiros. O servidor aguarda a posição replicada com prazo limitado. Falhas reais de transporte/entidade/teleporte continuam tendo recuperação; ausência da colisão carregada não gera mais `COLLISION` nesse caminho.

Não houve alteração de schema ou personalizações salvas. Checkpoint continua pessoal e temporário; F3 recria o ponto depois de recarregar world.

## Verificação

Build/TypeScript, verificações estáticas e suíte Lua/Fengari aprovados. Regressões exercitam o controlador real com natives/rede simuladas: teclas por borda, oito níveis, modo fixo, altura independente do pitch da câmera, apresentação/restauração, pausa por foco, tokens, sincronização autorizada e deslocamento equivalente em 30/120 FPS.

O handler real de checkpoint foi executado com `HasCollisionLoadedAroundEntity` sempre falso: concluiu sem consultar essa condição, preservou a inclinação e continuou validando identidade. A viagem comum ainda falha e recupera sob essa mesma simulação. Testes server-side cobrem ponto inicial em rascunho, ocupação, retorno sem colisão pronta, erro real de teleporte e retry.

Browser verifica os oito níveis, modo de câmera, indicador e submenus; suas respostas são fixtures explícitas. Captura `docs/evidence/noclip-guide-1280x720.png` inspecionada. **Não foi executado FiveM nem reiniciado o servidor.** Visibilidade para outros jogadores, transparência, sensação do voo com mouse/controle e retorno físico em rampas/MLO ainda exigem validação no jogo, incluindo dois clientes.
