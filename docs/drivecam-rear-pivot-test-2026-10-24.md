# F7: teste de referência visual mais para trás

Data: 2026-10-24. Origem: captura e pedido do usuário. Relatou capô próximo ao centro e traseira indo para o canto durante drift; pediu experimentar um pivô mais traseiro, sem decisão definitiva sobre o resultado.

## Implementação experimental

Referência de enquadramento recuada 65 cm no sentido longitudinal da carroceria. A câmera continua na mesma posição: o solver ajusta apenas o rumo horizontal do olhar para essa referência. Distância base 4 m + meio entre-eixos, altura 0,85 m, pitch, FOV65, proteção de colisão e acompanhamento vertical são preservados.

O deslocamento mundial da referência é filtrado com meia-vida 0,30 s para conter movimentos de contravolante e suavizar a comparação ligado/desligado. Correção horizontal limitada a 10°. Órbita manual reduz a influência automaticamente; olhar para trás continua independente. Numa reta alinhada não há alteração de enquadramento.

O teste começa ligado ao iniciar o resource. Comando `/drivecampivot` alterna ligado/desligado com aviso pelo mecanismo existente. A escolha vale para a sessão do resource, sem gravação em KVP e sem alterar a preferência F7. Ao reiniciar o resource, o teste volta ligado.

Configuração em `resources/[mx]/mx-freeroam-drivecam/config.lua`: `rearPivotBack=0.65`, `pivotHalfLife=0.30`, `maxPivotAngle=math.rad(10)`. Definir `rearPivotBack=0` desativa o deslocamento como padrão. Não é mudança na física ou ponto físico do carro; é referência visual do olhar, sem mover o braço de colisão.

## Verificação

- `test:drivecam` e `check` aprovados.
- Novo `development/tests/drivecam-pivot.lua`: drift de ±55° em 30/60/144 FPS, comparação com perfil anterior. A traseira aproxima-se do centro e o envelope angular das duas pontas da carroceria fica menor; posição da câmera, pitch e FOV idênticos. Retorno suave ao perfil anterior e independência do olhar para trás aprovados.
- Testes anteriores de enquadramento/teclado são mantidos explicitamente como perfil A/B desligado, para preservar seu contrato. Perfil experimental é exercitado nos testes novos e no cliente real com natives simuladas.
- Cliente: comando liga/desliga o parâmetro sem alterar a preferência F7. Regressões de rampas, colisão/pitch, prioridade, teleporte e ciclo de vida passaram com teste ligado.

Sem avaliação visual no FiveM ou restart ao vivo nesta etapa. O teste prioriza mostrar o carro inteiro e pode mudar a percepção da direção da pista no drift; isso depende da comparação pelo usuário, não constitui aceite visual.

Carregar: `restart mx-freeroam-drivecam`. Dirigir com F7 e comparar usando `/drivecampivot` no chat ou `drivecampivot` no console F8, repetindo o mesmo trecho. Não requer build NUI ou migration.
