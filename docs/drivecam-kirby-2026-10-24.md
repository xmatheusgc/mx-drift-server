# Adaptação KirbyCam para o F7

Data: 2026-10-24. Origem: código KirbyCam chase cam v1.0b-public de 2021-10-20 fornecido pelo usuário nesta conversa. Créditos originais preservados: KirbyCam e partes baseadas em x4fab.

## Entrega

O resource existente `mx-freeroam-drivecam` agora usa o solver `chase.lua` no lugar da correção de slip limitada da câmera anterior. F7, `/drivecam`, o export `Preference`, a preferência KVP v1 e os controles cadastrados no menu continuam usando o mesmo resource. Instalação nova começa desligada; a preferência de quem já usa é mantida.

- Câmera acompanha a velocidade suavizada, com retorno ao rumo do carro ao parar e seguimento da trajetória ao fazer drift ou andar de ré.
- A distância usa base de 3,8 m + metade do entre-eixos; a altura usa 1 m e compensação de pitch de 8°. Parâmetros em `resources/[mx]/mx-freeroam-drivecam/config.lua`.
- FOV fixo 65 por padrão. `dynamicFov=true` habilita o aumento por velocidade do original.
- Aceleração lateral, longitudinal e vertical produz deslocamentos limitados, pequenas vibrações e roll sutil. O horizonte permanece utilizável durante capotamento.
- Mouse/stick controlam a órbita, com retorno automático; olhar para trás usa o controle GTA existente.
- Oficina, NUI, pause, morte, espectador e passageiro suspendem a câmera sem apagar a preferência. Limpeza não desliga uma câmera que já pertence à oficina.
- Teleporte, troca de veículo e pausa longa reinicializam filtros e consultas de colisão. Parede próxima retorna à câmera nativa; resultados pendentes nunca contam como caminho livre.
- A validação espacial de casts assíncronos admite deslocamento compatível com velocidade alta entre quadros, descontando esse deslocamento da distância segura. O teste cobre 324 km/h a aproximadamente 30 FPS.

## Diferenças em relação ao Assetto Corsa

É uma adaptação da lógica, sem executar a API `ac`. Os eixos mudam de Y vertical para Z vertical. Aceleração em G vem da derivada da velocidade mundial, projetada nos eixos do carro, e é limitada para impactos. Entre-eixos e centro horizontal usam os quatro bones de rodas; modelos sem bones válidos usam dimensões como fallback. A altura de referência aproxima o centro da carroceria pelas dimensões; não representa uma medição do CG do Assetto Corsa.

Suavizações usam decaimento exponencial por tempo, evitando o fator `dt*k` sem limite. Câmera conserva a prioridade e a proteção de colisão do FiveM. Replay do Assetto Corsa não se aplica. A sensação final de distância, atraso e forças precisa ser calibrada no jogo.

Natives conferidos na documentação oficial: [matriz da entidade](https://github.com/citizenfx/natives/blob/master/ENTITY/GetEntityMatrix.md), [posição de bone](https://github.com/citizenfx/natives/blob/master/ENTITY/GetWorldPositionOfEntityBone.md), [rotação da câmera](https://github.com/citizenfx/natives/blob/master/CAM/SetCamRot.md), [FOV](https://github.com/citizenfx/natives/blob/master/CAM/SetCamFov.md) e [controles](https://docs.fivem.net/docs/game-references/controls/).

## Verificação

- `npm.cmd --prefix development run test:drivecam`: aprovado. Solver: repouso, entre-eixos, drift, ré, 30/60/144 FPS, projeção de G, impacto, capotamento, olhar para trás e FOV. Cliente real com adapters de natives: ativação, velocidade alta, paredes, casts pendentes, teleporte, prioridade, troca de carro, NUI, passageiro, desligamento e resource stop.
- `npm.cmd --prefix development run check`: aprovado.
- Suíte geral `test`: executada; novos testes passaram. Interrompe na divergência já registrada de `orbit-client-lifecycle`, linha 64, sobre pose/FOV do lobby. Arquivos de pose do lobby não foram alterados nesta tarefa.
- Não houve cliente FiveM, restart ao vivo ou validação visual de dirigibilidade. Não exige build da NUI nem migration.

## Carregar e validar

No console do servidor: `restart mx-freeroam-drivecam`. No carro, motorista, pressionar F7. Conferir reta, aceleração/freio, drift para os dois lados, ré sustentada, rodada, lombadas/rampas, paredes/túneis, carro com bones ausentes, teleporte, troca de veículo, pause, garagem e F7 novamente. Comparar 30/60/144 FPS. Ajustar `directionHalfLife`, `distance`, `height` e intensidades após o primeiro teste visual.
