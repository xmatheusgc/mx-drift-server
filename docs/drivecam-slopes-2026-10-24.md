# F7: flicks em subidas e descidas

Data: 2026-10-24. Usuário confirmou melhora significativa do acompanhamento, mas relatou flicks nas subidas/descidas.

## Reprodução e correção

Adicionado teste ao cliente real com natives simuladas: subida/descida de 20° e obstrução moderada que encurta o braço da câmera, sem exigir retorno à câmera nativa. Antes da alteração, o teste falhou porque a inclinação do olhar mudava ao comprimir o braço.

O cliente calculava a direção de visão como `aim - final`, usando o alvo do braço completo a partir da posição corrigida pela colisão. A correção usa `aim - desiredPosition`: a colisão continua ajustando a posição segura, mas não inventa uma nova inclinação de visão. Resultados de colisão booleanos e numéricos (`true`/`1`) são aceitos; antes apenas `1` contava como impacto.

O solver também passou a amortecer a velocidade de pitch de terreno e limitá-la a 22°/s, preservando o limite de inclinação de 25°. Isso contém respostas rápidas à velocidade vertical nas mudanças de inclinação. Controle manual de pitch continua separado.

Distância base 4 m + meio entre-eixos, altura 0,85 m, FOV 65, configuração de estabilidade horizontal e antecipação foram preservados. Não há alteração de handling, NUI ou banco. Colisão próxima ou consulta inválida continua podendo retornar à câmera nativa conforme a política existente.

## Verificação

- `test:drivecam`: aprovado. O caso antes falho passou em subida e descida, incluindo alternância da distância de obstrução entre 3,2 e 4,2 m, sem mudança de câmera ou salto de pitch. Impactos booleanos e numéricos são testados.
- Novo teste `development/tests/drivecam-slopes.lua`: subidas/descidas de ±20/25°, cristas/vales e ruído de velocidade vertical em 30/60/144 FPS. Pitch automático limitado a 22°/s e acompanhamento de inclinação sustentada aprovados.
- Regressões de drift, teclado, enquadramento estável, distância/altura, suspensão, colisões e ciclo de vida passaram.
- `check`: aprovado. Suíte geral não reexecutada; divergência preexistente de pose/FOV do lobby continua registrada nos relatórios anteriores.

São simulações/adapters, sem cliente FiveM ou restart ao vivo. Há uma causa reproduzida e corrigida; isso não comprova que todos os flicks da pista real tenham a mesma origem. Carregar com `restart mx-freeroam-drivecam` e repetir o trecho relatado usando F7.

Contrato da native conferido na [documentação oficial de GetShapeTestResult](https://github.com/citizenfx/natives/blob/master/SHAPETEST/GetShapeTestResult.md): campo `hit` é BOOL e valores adicionais só são definidos quando a consulta termina com status 2.
