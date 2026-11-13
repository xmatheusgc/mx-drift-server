# Recuperação de rodas salvas indisponíveis

Data: 2026-10-24. Origem: usuário relatou `CLIENT_ERROR`, `vehicles/apply`, `[MX:MOD] Peça indisponível neste modelo/família de rodas`. Suspeita relatada: instalação de pack de rodas teria mudado os índices. O erro antigo não identificava o slot; a relação com rodas não foi confirmada no cliente real.

## Comportamento

- Preflight dos slots 23/24 atualiza modkit/família e relê a disponibilidade uma vez antes de considerar inválida uma roda salva. O cache de famílias do modelo é invalidado nessa recuperação.
- Índice ainda indisponível restaura ambas as rodas originais: família 0, slots 23/24 em -1, pneus personalizados desligados. Não tenta adivinhar outro índice ou outra roda do pack.
- Aplicação verifica a família, os índices e a variação dos pneus. Uma recusa do native tenta reaplicar uma vez; recusa persistente usa originais e verifica o resultado. Se nem a restauração original for confirmada, a operação continua sendo erro real.
- Instalação das rodas ocorre antes das peças, liveries e pintura, para que resets de família não apaguem essas modificações. A recuperação se limita às rodas; outras peças inválidas continuam rejeitadas, agora com slot, índice e quantidade de opções na mensagem.
- O documento solicitado é copiado antes de normalizar. ACK `wheels` informa somente a recuperação para originais. O servidor aceita exclusivamente essa forma restrita e incorpora o resultado em previews e veículos ativos pelo mecanismo existente de aceite de aplicação. Nenhuma alteração arbitrária de pintura/peças é aceita nesse ACK.
- Aviso ao jogador uma vez por entidade quando houver recuperação. A prévia/veículo ativo recebe a configuração corrigida; o registro salvo no banco só muda no fluxo normal de confirmação/salvamento. Não foi feita escrita SQL ou migration nesta tarefa.

Índices que continuam válidos mas passaram a apontar para outra roda não podem ser identificados semanticamente só pelo índice anterior. Não foi adicionado catálogo de identidades persistentes de rodas nesta correção.

## Arquivos

`resources/[mx]/mx-freeroam-vehicles/customization.lua`, `client.lua`, `properties.lua`. Novo teste `development/tests/wheel-recovery.mjs`, `wheel-recovery.lua`, `wheel-recovery-preview.lua`; comando `npm.cmd --prefix development run test:wheels` e inclusão na suíte geral. Teste antigo de preflight ajustado para a recuperação autorizada.

## Verificação

- `test:wheels`: aprovado. Cliente real com adapters: índices removidos dianteiros/traseiros, chaves numéricas legadas, pneus personalizados, reaplicação após leitura desatualizada/recusa transitória, recuperação original após recusa persistente, falha real se originais recusados, aviso sem spam, imutabilidade da solicitação, preservação de peças/pintura/liveries e ACK restrito.
- Servidor real `Preview`/`ApplyPreview`: ACK de recuperação atualiza propriedades expostas para confirmação, sem reescrever documento de entrada nem escrever SQL no teste.
- Regressões anteriores de pintura, extras, liveries e aplicação em entidade nova aprovadas.
- `check`: aprovado.
- Suíte geral executada: novos testes e personalização/stance/previews passaram; interrompe na divergência preexistente `orbit-client-lifecycle:64`, pose/FOV do lobby. Nenhuma alteração no lobby nesta tarefa.

Sem execução FiveM, restart ao vivo ou validação no carro específico relatado. Após recarregar o servidor/resources, selecionar o carro novamente, conferir aviso/rodas originais, escolher outra roda e confirmar normalmente. Se o erro for de outra peça, a nova mensagem permite identificar o slot.
