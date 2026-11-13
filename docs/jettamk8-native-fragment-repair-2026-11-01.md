# Jetta MK8 — revisão de fragmento usando Kuruma

Data: 2026-11-01. Blender 5.1.2 / Sollumz 2.9.0.
Abra `jettamk8-kuruma-rig.blend`. Esta revisão substitui a estrutura de rig da entrega em `converted`, que continua preservada como fonte de materiais.

## Problemas confirmados

- Os YFTs instalados antes da revisão não tinham Physics/LOD1 nem colisões.
- Quatro pneus/rodas estavam no drawable principal com vertex groups. Faltava a roda única marcada como `Is Wheel Mesh` e ligada por constraint ao bone.
- Os wheel_* eram filhos de hub_*, e todos os bones recebiam flags de translação. O template fornecido usa rodas e hubs sob chassis e flags específicas.
- A origem do carro estava no chão; o template usa as rodas abaixo da origem do veículo.
- Os arquivos base e `_hi` instalados eram byte a byte idênticos.
- O manifest declarava `data/vehiclelayouts.meta`, inexistente na pasta atual. O layout indicado em vehicles.meta é nativo; não exige esse arquivo.

Esses defeitos foram encontrados independentemente do crash. O hash `chicken-fourteen-michigan`, GTA5_b3258.exe+63288B, está confirmado pela mensagem do usuário e pelo log local. Ele não identifica sozinho a causa exata. Não há confirmação de correção do crash sem reteste no FiveM.

## Correções

- Esqueleto de 87 bones do Kuruma fornecido: ordem, hierarquia, tags e flags preservadas; pivôs principais ajustados às peças do Jetta.
- Rodas/hubs diretamente sob chassis. Rodas, portas, capô, porta-malas, volante e helpers nativos presentes.
- Uma única roda exportável, `wheel_lf.child`, com pneu e aro, sem vertex groups, marcada como Is Wheel Mesh e vinculada por constraint ao wheel_lf.
- As outras três rodas visíveis no Blender são previews SollumType.NONE. Não são exportadas.
- 25 bounds e 25 filhos/grupos físicos; colisões do template ajustadas às medidas das peças. Massa total de 1300, alinhada ao handling atual.
- Colisões mod_col/misc_b sem peça equivalente foram excluídas da física; os helpers do esqueleto foram preservados.
- Origem vertical alinhada ao eixo nativo das rodas, com translação da geometria original de aproximadamente -0,719263 unidade em Z.
- VERYHIGH preserva o detalhamento original; HIGH, MEDIUM, LOW e VERYLOW foram gerados como malhas independentes. Base e _hi saem juntos da mesma exportação GEN8.
- Materiais e 79 texturas da conversão anterior preservados. Configuração de luzes continua para o acabamento do usuário.

As colisões são uma adaptação do template, não um acabamento físico completo. Helpers secundários, encaixe dos assentos, danos, vidros quebráveis e LODs gerados precisam de revisão no jogo. Shattermap automático foi desativado para separar esse acabamento da correção estrutural.

## Validação executada

- Exportação sem avisos do Sollumz.
- Leitura direta dos dois binários: física presente; massa positiva; grupos, tags, matrizes/filhos e bounds coerentes; uma única roda com drawable físico.
- Base e _hi diferentes por hash e geometria; 48 shaders e 79 texturas embutidas em cada um.
- Base: 143.619 triângulos HIGH, 50.186 MEDIUM, 16.056 LOW e 4.390 VERYLOW no drawable principal. _hi: 359.211 no principal. A geometria da roda física é contabilizada separadamente.
- Reimportação do par nativo: 87 bones, 25 colisões mais o composite e uma roda física.
- Render da revisão inspecionado em `preview.png`.
- Metadados XML do resource parseados e hashes dos YFTs instalados conferidos contra o staging.

## Resource atualizado

C:/FiveM/drift-server/txData/FiveMBasicServerCFXDefault_CAECC7.base/resources/[vehicles]/jettamk8

Foram substituídos somente os dois YFTs. O YTD existente foi preservado. No manifest, removida a declaração do layout inexistente. wheelScale/wheelScaleRear ajustados para 0.330398, medidos no pneu do modelo. Nenhum restart ou comando de spawn foi executado pelo Codex.

Para testar: reinicie o resource `jettamk8`, reconecte para carregar os arquivos novos e tente o spawn. Se o crash continuar, preserve o log novo para comparar a assinatura com a anterior. Não limpe caches ou reinstale arquivos como primeiro passo sem verificar qual revisão foi carregada.

## Reexportação

Selecione o Fragment jettamk8 e exporte para GTAV Legacy/GEN8. Mantenha a opção de exportar base e hi. Instale o par gerado; não faça uma cópia do base e a renomeie para _hi. As rodas de preview não devem ser convertidas em Drawable Models.

O script de reparo e os logs ficam em `C:/FiveM/drift-server/tools/jetta_repair`. O script lê o .blend de materiais em converted e o template Kuruma; não use para sobrescrever ajustes manuais sem preservá-los.

## Referências

- https://docs.sollumz.org/documentation/fragments.yft/vehicle-setup/wheels
- https://docs.sollumz.org/documentation/fragments.yft/collision-physics
- Kuruma fornecido pelo usuário: C:/Users/mathe/Documents/blender-projects/kuruma

Backup da instalação anterior: C:\FiveM\drift-server\txData\FiveMBasicServerCFXDefault_CAECC7.base\docs\evidence\jettamk8-before-native-rig-2026-11-01-155541
## Spawn sem crash confirmado — 2026-11-01

Origem: confirmação explícita do usuário nesta conversa, em resposta ao pedido de retestar a revisão instalada: “Spawnou sem crash”.
Estado atualizado: o Jetta revisado passou pelo teste de spawn no FiveM sem reproduzir o crash anterior. Isso substitui a pendência de confirmação do spawn registrada acima. A causa individual não foi isolada, pois física, rodas, rig e empacotamento foram corrigidos em conjunto.
Continuam pendentes a validação de direção, suspensão, colisões/danos, assentos, LODs e o acabamento de luzes/vidros. O sucesso do spawn não confirma esses outros comportamentos. Nenhuma nova mudança de assets ou configuração nesta etapa.
Próximo passo: validar o comportamento do veículo no jogo e continuar os ajustes específicos combinados com o usuário.
