# JZX100: conflito de modkit e dimensões de roda no spawn

Data: 2026-10-25. Origem: relatos do usuário de slot 4/índice 0/opções 0, inclusive em JZX100 original ao tentar rodas, e de diâmetro salvo aparecendo somente após mexer em Suspensão.

## Diagnóstico do JZX100

Encontrado conflito nos resources instalados e iniciados pela categoria `[vehicles]`:

| Resource | Kit anterior | ID | Peças visuais |
| --- | --- | --- | --- |
| chaser | 3190_chaser_modkit | 3190 | visibleMods vazio |
| jzx100 | 3190_jzx100_modkit | 3190 | 51 modelos, incluindo 4 VMT_EXHAUST |

Os dois manifests carregam carcols e carvariations. Os IDs de modkit são globais no jogo, não isolados pelo nome do resource; o [código Cfx de realocação](https://github.com/citizenfx/fivem/blob/master/code/components/gta-streaming-five/src/ModKitIdRelocation.cpp) usa uma tabela global de 65.536 índices. A duplicidade é um defeito confirmado nos arquivos. O kit vazio do Chaser e o kit completo do JZX100 disputarem o mesmo ID é compatível com o jogo informar zero escapamentos no JZX100, embora haja quatro declarados e os quatro YFT existam. O efeito preciso de ordem/carga ainda precisa ser confirmado após reinício no FiveM.

A seleção de roda reaplica o documento completo de propriedades (`VehicleEditor` → preview → vehicles/apply). A validação do escapamento falhava antes de concluir essa aplicação. Por isso um problema de modkit/slot 4 podia aparentar que nenhuma roda funcionava, mesmo em criação nova; não era prova de índice de roda salvo desatualizado.

A auditoria anterior do instalador já registrava a colisão 3190 entre chaser/jzx100 em `tools/FiveMVehicleInstaller/VALIDATION.md` e `artifacts/diagnostics/collection-result.md`. Exportação em resources separados não elimina uma colisão global quando ambos estão ativos. Não foi alterado o instalador nesta tarefa.

## Correção de metadados

Somente o JZX100 recebeu ID/nome novos: `6190_jzx100_modkit`, ID `6190`, em `resources/[vehicles]/jzx100/data/common/data/carcols.meta`; referência correspondente atualizada em `carvariations.meta`. Chaser permanece 3190. ID 6190 estava livre entre os modkits instalados.

Auditoria após a correção: 27 modkits, sem duplicidade não zero de ID ou nome; referência de variação válida; 51 arquivos de peças do JZX100 encontrados, incluindo os quatro escapamentos. Ambos os XML foram carregados pelo parser XML do .NET. Hashes anteriores/posteriores e substituições estão em `docs/evidence/jzx100-modkit-repair-2026-10-25.json`.

Os assets estão ignorados pelo Git do projeto; a correção está nos arquivos ativos e os dados exatos para rastreá-la constam nesta evidência. Reimportar o arquivo original do mod pode reintroduzir o ID antigo; `npm.cmd --prefix development run test:modkits` audita os assets locais instalados. Não houve reimportação, renomeação de modelo ou alteração dos índices das peças salvas.

## Proteção para peças realmente indisponíveis

Preflight atualiza o modkit e relê o slot uma vez. Se uma peça permitida com índice válido no esquema não existir mais no modelo, aplica -1 (original), avisa uma vez por entidade e verifica o resultado real. Não confirma uma restauração que o native recusou. Isso amplia a proteção anterior, limitada às rodas.

ACK `modsRecovered` só permite zerar para -1 slots permitidos que estavam explicitamente selecionados no pedido. Rejeita patches arbitrários, slots de roda por esse canal, peças não solicitadas e entradas fora do esquema. Propriedades efetivas chegam ao servidor; persistência ocorre na confirmação/salvamento normal. Não houve SQL/migration.

## Diâmetro/largura no spawn e streaming

Identificada lacuna do controlador: ao capturar dimensões zero no primeiro instante do spawn, a base ficava zero na atualização por quadro. Uma nova aplicação pela tela de Suspensão inicializava essa base e fazia a roda assumir o tamanho salvo, comportamento compatível com o relato.

- O dono aguarda por até 750 ms a disponibilidade inicial de rodas/dimensões, quando o preset exige escala. Identidade/modelo são revalidados durante a espera; tempo esgotado mantém o caminho de recuperação por quadro, sem espera ilimitada.
- A atualização por quadro inicializa dimensões-base ainda ausentes quando os dados aparecem e passa pelo caminho normal de verificação das dimensões; bases positivas continuam imutáveis para não multiplicar a escala a cada quadro.
- Repetir um state bag com a mesma assinatura também reaplica a geometria visual, em vez de apenas retornar.
- Reaplicação final após posicionamento no chão, assento, descoberta de famílias e handling reduz resets visuais no spawn/saída da garagem.
- Não envia dimensão zero como alvo de restauração. Dimensões que o native realmente recusa continuam sujeitas às limitações existentes.

Conforme a documentação Cfx de [GetVehicleWheelSize](https://github.com/citizenfx/fivem/blob/master/ext/native-decls/GetVehicleWheelSize.md) e [SetVehicleWheelSize](https://github.com/citizenfx/fivem/blob/master/ext/native-decls/SetVehicleWheelSize.md), o redimensionamento exige rodas de personalização; rodas originais não têm esse suporte. A sincronização visual usa o state bag existente e aplicação local em cada cliente.

## Verificação e próximo passo

`test:wheels`, `test:stance`, `test:modkits` e `check` aprovados. Cobrem slot 4 indisponível, ACK restrito, native recusando original, spawn do dono, state bag de observador, dimensões/mods chegando atrasados, reconstrução da malha, ordem após chão/handling, timeout/identidade da espera e não acumulação da escala. Natives são adapters, sem cliente real.

A suíte geral foi executada durante esta tarefa: personalização, novos casos, stance e previews passaram e a execução parou na divergência preexistente `orbit-client-lifecycle:64`, pose/FOV do lobby. Após os últimos ajustes de prontidão, os testes específicos acima foram reexecutados e passaram.

É necessário reinício completo do servidor e reconexão do FiveM para validar o kit reindexado sem o registro anterior em memória. Recriar o JZX100, testar roda/escapamento e conferir diâmetro sem abrir Suspensão, ao sair da garagem, ao reconectar e com observador próximo. Não houve restart ao vivo nem aceite de jogo nesta etapa.
