# F7: estabilidade nas correções de teclado

Data: 2026-10-24. Origem: usuário relatou que a câmera parecia acompanhar as rodas e oscilava com correções rápidas no teclado.

O solver não lê ângulo de esterço ou teclas de direção. O ajuste anterior antecipava a curva pela derivada da direção de deslocamento, que podia amplificar pequenas alternâncias de trajetória produzidas pelo teclado.

## Ajuste

- Taxa de curva calculada sobre janela temporal de 0,28 s, com confiança reduzida quando mudanças de sentido se cancelam.
- Antecipação começa após pelo menos 0,18 s de mudança consistente de direção e cresce progressivamente durante mais 0,18 s.
- Pequena tolerância angular de 1,25° absorve correções de enquadramento; essa tolerância diminui numa curva confirmada, preservando alinhamento no drift fechado.
- Antecipação máxima reduzida de 12° para 8°, horizonte de previsão de 0,28 s para 0,18 s e amortecimento da taxa aumentado de 0,14 s para 0,18 s.
- Distância nominal, FOV, suspensão, controles manuais, colisões e prioridade da garagem preservados.

Arquivos: `resources/[mx]/mx-freeroam-drivecam/chase.lua` e `config.lua`. Teste novo: `development/tests/drivecam-keyboard.lua`, integrado ao comando `test:drivecam`.

## Verificação

`npm.cmd --prefix development run test:drivecam` e `npm.cmd --prefix development run check`: aprovados.

Teste de trajetória alternando ±4° a 2,5/5 Hz com carroceria alternando ±25°, em 30/60/144 FPS: oscilação do olhar inferior a 1,5° de pico a pico e no máximo 22% da oscilação do preditor anterior, sem ativar antecipação. Rotação da carroceria sozinha em velocidade constante não gira o olhar; toques curtos não confirmam curvas, e curvas sustentadas continuam sendo antecipadas.

Regressão da curva fechada de raio de 8 m: erro máximo para a trajetória 14,5°, deslocamento angular do carro até 21,2°. Testes anteriores de suspensão, ré, teleporte, colisão e ciclo de vida também passaram. Números são simulações do solver e natives do cliente usam adapters; sem avaliação visual ou restart do FiveM nesta etapa.

Para carregar, executar `restart mx-freeroam-drivecam` no console do servidor e testar F7 com pequenas correções A/D na reta, drift com contravolante e transição entre curvas. A nova confirmação pode retardar o início da antecipação ao entrar numa curva; o seguimento normal da trajetória permanece ativo durante esse intervalo.
