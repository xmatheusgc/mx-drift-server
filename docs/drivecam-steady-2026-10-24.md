# F7: acompanhamento mais parado e enquadramento menor

Data: 2026-10-24. Origem: usuário pediu câmera mais parada, acompanhando o carro e ajudando a enxergar a curva, um pouco mais baixa e distante.

## Ajuste atual

- Distância base 3,8 -> 4,0 m, mantendo a adição de meio entre-eixos. Altura base 1,00 -> 0,85 m. Pitch base 8° e FOV 65 preservados. Em repouso e sem colisão, o afastamento cresce 20 cm e a posição fica cerca de 12 cm mais baixa, pois a compensação de pitch adiciona aproximadamente 3 cm ao afastar.
- Pequenas mudanças de trajetória usam amortecimento maior: meia-vida orbital 0,38 s e do olhar 0,20 s. Para erros sustentados de direção entre 8° e 24°, a resposta mistura progressivamente os valores de curva (0,18/0,09 s). A mistura também é amortecida, evitando troca brusca de regime.
- Antecipação máxima 8 -> 5°, com entrada e saída suavizadas por filtro de meia-vida 0,24 s. A confirmação de curva e os filtros de teclado anteriores continuam ativos.
- Movimento lateral máximo 7 -> 2 cm e roll máximo 0,25 -> 0,05°. Amortecimento vertical e limites de suspensão preservados.
- Sem alterações em física/handling, NUI, preferência, colisões, prioridade da garagem ou controles manuais.

Arquivos alterados: `resources/[mx]/mx-freeroam-drivecam/config.lua`, `chase.lua`, testes em `development/tests/drivecam-steady.lua`, `drivecam-keyboard.lua` e inclusão em `drivecam.mjs`.

## Verificação

`test:drivecam` e `check` aprovados.

Nova comparação com o ajuste anterior usando oscilações pequenas de trajetória de ±6° a 0,8 Hz, em 30/60/144 FPS: amplitude orbital até 57% e amplitude do olhar até 64% da versão anterior. Teste confere também afastamento de 20 cm, redução líquida de altura entre 12 e 13 cm e FOV preservado.

Regressões de correções rápidas de teclado (2,5/5 Hz), curvas sustentadas, retorno à reta, suspensão e cliente passaram. Na curva de raio de 8 m a 15 m/s, erro máximo do olhar para a trajetória foi 19,2°, e o carro permaneceu a até 18,8° do olhar. O comportamento privilegia estabilidade em pequenas mudanças; a antecipação entra mais gradualmente.

São resultados matemáticos/simulados, com natives em adapters. Sem avaliação visual no FiveM ou restart ao vivo nesta tarefa. Suíte geral não reexecutada; bloqueio anterior de pose/FOV do lobby continua documentado.

Carregar com `restart mx-freeroam-drivecam` no console do servidor e testar F7 em reta com pequenas correções, curvas sustentadas, drift e transições. Próxima calibração depende do retorno visual do usuário.
