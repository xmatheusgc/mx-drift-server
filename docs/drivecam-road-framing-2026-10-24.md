# F7: enquadramento de drift e suspensão

Data: 2026-10-24. Origem: feedback do usuário após a adaptação KirbyCam. Distância aprovada; pouca visão da pista em curvas fechadas e efeitos de suspensão precisavam de ajuste.

## Comportamento implementado

A distância base continua em 3,8 m + metade do entre-eixos. FOV continua fixo em 65 por padrão. As mudanças estão no solver e configuração do resource `mx-freeroam-drivecam`; não exigem build da NUI ou banco.

- Seguimento da trajetória mais rápido: meia-vida de rotação de 0,693 s para 0,18 s, e filtro de velocidade de 0,10 s para 0,06 s.
- Direção do olhar separada da posição orbital. A câmera antecipa a curva pela mudança da direção de deslocamento, com horizonte de 0,28 s e limite de 12°. Não usa o contravolante ou a rotação da carroceria como indicação da saída da curva.
- Diferença entre olhar e posição orbital limitada a 24° para preservar enquadramento do carro. Antecipação reduzida ao usar órbita manual e anulada ao olhar para trás. Reversões abruptas não geram impulso de antecipação.
- Inicialização em movimento já considera a trajetória, evitando demorar a alinhar ao ativar F7 no meio de um drift.
- Suspensão adaptada ao GTA: altura mundial suavizada, atraso vertical máximo de 18 cm e mola criticamente amortecida a 2,2 Hz com deslocamento por G limitado a 8 cm. Removidas vibrações rápidas e a elevação causada pela inclinação lateral da carroceria.
- Deslocamento lateral limitado a 7 cm e roll sutil de até 0,25°. Pitch de terreno limitado a 25°, com influência reduzida da carroceria em baixa velocidade. Inclinação do terreno ainda é acompanhada pela trajetória suavizada.
- Aceleração/frenagem não alteram mais a distância da câmera; isso elimina o movimento de aproximação/afastamento gerado pelo efeito longitudinal anterior.
- Colisões, preferência KVP, F7, suspensão na garagem/NUI e limpeza continuam no cliente existente.

## Verificação

`npm.cmd --prefix development run test:drivecam`: aprovado, incluindo testes anteriores do solver e cliente com adapters de natives.

Adicionado `development/tests/drivecam-road.lua` com simulação de drift de 45° numa curva de raio de 8 m a 15 m/s, nos dois sentidos, a 30/60/144 FPS. Erro máximo do olhar em relação à trajetória: 12,4°; deslocamento angular máximo do carro em relação ao olhar: 23,3°. Nos trechos medidos, o erro ficou abaixo de metade do erro do filtro anterior de 0,693 s. Diferença entre resoluções temporais inferior a 3° nessa curva de aproximadamente 107°/s. Estes são resultados matemáticos do rig, não medição de imagem no FiveM.

Também passaram lombadas repetidas de 8 cm a 6 Hz, aterrissagem/recuperação, ausência de vibração residual, horizonte estável ao inclinar a carroceria, conservação da distância e retorno da antecipação a zero na reta.

`npm.cmd --prefix development run check`: aprovado. Não reexecutada a suíte geral, cujo bloqueio preexistente de pose/FOV do lobby continua registrado no relatório anterior.

Sem restart ao vivo nem avaliação visual no FiveM nesta etapa. Para carregar: `restart mx-freeroam-drivecam` no console do servidor. Validar F7 em curvas fechadas, transições de drift, reta, ré, lombadas, rampas e aterrissagens. Próxima calibração depende do feedback visual do usuário.
