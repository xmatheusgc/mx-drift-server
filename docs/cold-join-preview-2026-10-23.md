# Primeira entrada, oficina e prévias — 23/10/2026

Origem: logs e relatos fornecidos pelo proprietário, inspeção do código e testes locais por Codex. O proprietário confirmou que o outro jogador conseguiu entrar pela Radmin VPN, mas encontrou erros ao usar veículos/menus e viu a oficina incompleta na primeira personalização. A correção abaixo está em disco; ainda não foi aplicada por reinício nem validada em cliente FiveM.

## Diagnóstico confirmado

- `OBSOLETE` em `vehicles/garage.lua` é a proteção que recusa uma seleção substituída enquanto o modelo ou a entidade carregava. A proteção deve permanecer. O defeito era lançar essa exceção através de exports e referências de função Cfx: os logs mostram o valor original substituído por `nil` e a resposta virando `INTERNAL`.
- `BUSY` é a exclusão por jogador do core, que impede operações concorrentes. Também atravessava esse caminho como exceção e perdia o código. Não foi removida a exclusão nem autorizado executar mutações em paralelo.
- O modelo tinha somente 8 s para carregar. O pedido completo expirava em 20 s no cliente Lua e 24 s no fetch NUI, embora pudesse executar várias chamadas ao cliente de até 12 s em sequência. Isso permitia a interface iniciar outra ação enquanto o servidor ainda concluía a anterior. Carregamento lento aumenta essa janela; os logs não demonstram que era a única causa de todos os cancelamentos.
- A preparação da oficina usava colisão ao redor do ped. Colisão de chão vanilla não certifica que o MLO, os modelos e o interior customizado chegaram ao cliente. O manifest de `ps-tuners` não tinha registro explícito dos seus YTYP.
- O aviso oxmysql de 392 ms é de consulta lenta, sem erro SQL nesse trecho. `player_id` é chave primária no schema versionado de `player_experience`; não foi feita alteração de banco ou índice com base em uma amostra.
- O aviso Cfx continua sendo sobre consulta do endereço público; não explica as falhas próprias de prévia/lock. O acesso do jogador pela VPN foi confirmado pelo proprietário.

## Correções

### Resultado estruturado nos exports

`MX.capture` captura o erro no resource proprietário da função, antes de cruzar a fronteira Cfx. `MX.unwrap` recupera o resultado no resource chamador. `Run`, seu callback de rota, `ClientCall`, `Preview` e `ApplyPreview` usam esse contrato nos caminhos corrigidos. Erros esperados mantêm os códigos; exceções inesperadas continuam gerando diagnóstico interno sem expor detalhes técnicos ao jogador. Epoch, ownership e exclusão por jogador permanecem obrigatórios.

### Veículos e limites de espera

`vehicles/asset-loader.lua` carrega apenas o veículo solicitado, com limite de 30 s. Uma nova intenção de prévia é comunicada também ao loader local, cancelando a espera anterior no próximo ciclo. Prévias automáticas de lobby/garagem não dependem de intenção enviada pela interface; continuam sujeitas à geração do contexto no servidor. Falha de carregamento preserva a prévia anterior; respostas antigas não podem publicar uma entidade nova.

Chamadas de carregamento do modelo e da cena têm limite de 35 s no servidor; as demais continuam em 12 s. O pedido completo tem limite de 120 s, e o fetch NUI de 125 s, para cobrir a sequência de preparação e ACKs. Esses limites não equivalem a uma espera fixa: sucesso confirmado retorna imediatamente. A interface já usa estado de prévia em carregamento e só oferece o modelo depois da confirmação.

### Oficina antes de revelar o jogador

`experience/scene-streaming.lua` prepara a área com foco de streaming e `NewLoadSceneStartSphere`. No contexto da garagem, exige o resource `ps-tuners`, o modelo instalado `denis3d_ts_shell`, interior não zero/pronto e colisão. A condição precisa permanecer pronta por 250 ms; o limite total é de 30 s. O lobby externo não exige interior da oficina.

O fluxo mantém o fade e o ped congelado enquanto prepara a cena. Falha não retorna ACK de prontidão. Foco, pedido de cena, modelos e pin do interior têm limpeza explícita em falha, cancelamento, saída e parada do resource. O interior da oficina fica fixado durante a apresentação e é liberado ao sair. O manifest de `ps-tuners` agora declara `DLC_ITYP_REQUEST` para seus YTYP.

## Verificação

- `npm.cmd --prefix development run build`: aprovado, incluindo TypeScript e novo bundle NUI.
- `npm.cmd --prefix development run check`: aprovado, incluindo manifests, ordem/dependências e fronteiras de domínio.
- `node development/tests/cold-join.mjs`: aprovado. Exercita modelo que demora 15 s, cancelamento imediato, limites de espera, chão disponível antes do interior, timeout sem ACK e limpeza. Também executa core/rotas reais com adaptador de export que descarta exceções não capturadas, verificando `BUSY`, `OBSOLETE`, epoch e diagnóstico inesperado.
- A suíte Lua executou os testes funcionais e analisou os 72 arquivos Lua, incluindo 32 verificações de prévias, entrada, saída, persistência simulada e respawn. **O comando completo termina com falha** na checagem final do handling ER34N instalado: `resources/[vehicles]/er34n/data/handling.meta` contém três `Item type=""` e não contém o `CCarHandlingData` esperado. Esse arquivo não foi alterado nesta tarefa. Não declarar a suíte completa aprovada.
- Testes de catálogo foram desacoplados dos nomes antigos de packs instalados (Chaser/Naoki); a regressão de marca longa agora tem fixture própria e a pasta de fixture usa nome único por execução.
- `test:ui` e `test:lobby`: aprovados em quatro resoluções com `MX_CHROMIUM` apontando para o Chrome instalado. O Chromium padrão do Playwright não estava instalado; não foi necessário baixar um navegador. Evidências: `docs/evidence/ui.json`, `docs/evidence/lobby.json`.

Os testes usam Fengari/adaptadores e browser com transporte simulado. Não certificam streaming real, assets completos, velocidade da VPN ou primeira entrada de outro PC. Nenhum banco foi consultado/modificado, nenhuma migration aplicada e nenhum servidor reiniciado nesta correção.

Resumo de execução: [cold-join-preview-2026-10-23.json](evidence/cold-join-preview-2026-10-23.json).

## Aplicação e próximo passo

Complemento em 24/10/2026: o proprietário relatou `denis3d_ts_shell` não registrado na primeira tentativa e sucesso ao abrir GARAGEM novamente. Corrigida a rejeição imediata do registro: aguardar dentro dos 30 s compartilhados da cena e só solicitar modelos registrados, preservando todas as condições de prontidão. Suíte completa e check reexecutados e aprovados nesta etapa. Ver [scene-registration-2026-10-24.md](scene-registration-2026-10-24.md). A falha histórica de handling descrita acima foi tratada separadamente em [handling-recovery-2026-10-24.md](handling-recovery-2026-10-24.md).

Reiniciar o servidor completo pelo txAdmin em janela combinada e reconectar os clientes. A atualização muda contratos compartilhados e manifests de mapa/resources; não aplicar apenas um restart isolado de vehicles.

Repetir primeira entrada pela VPN: abrir garagem/personagem, conferir oficina antes do fade, selecionar um mod ainda não usado, trocar rapidamente entre modelos e navegar de volta às marcas durante o carregamento. Conferir que somente a última seleção aparece, que falha preserva a prévia válida e que cancelamentos não se tornam `INTERNAL`. Registrar F8/console se persistir `SCENE_STREAM`, `SCENE_ASSET` ou timeout. A pendência de handling ER34N precisa de tratamento próprio, preservando a autorização existente para o preset de drift.

## Referências técnicas

- [Manifest e data_file](https://docs.fivem.net/docs/scripting-reference/resource-manifest/)
- [Tipos de data files, incluindo DLC_ITYP_REQUEST](https://docs.fivem.net/docs/game-references/data-files/)
- [RequestModel e espera de HasModelLoaded](https://docs.fivem.net/docs/scripting-manual/introduction/creating-your-first-script/)
- Natives oficiais: [NewLoadSceneStartSphere](https://github.com/citizenfx/natives/blob/master/STREAMING/NewLoadSceneStartSphere.md), [IsNewLoadSceneLoaded](https://github.com/citizenfx/natives/blob/master/STREAMING/IsNewLoadSceneLoaded.md), [IsInteriorReady](https://github.com/citizenfx/natives/blob/master/INTERIOR/IsInteriorReady.md).
