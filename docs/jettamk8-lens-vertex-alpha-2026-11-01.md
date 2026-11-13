# Jetta MK8 — máscara alfa das lentes

Data: 2026-11-01. Arquivo atual: `jettamk8-lens-tint-fix.blend`.

## Retorno do usuário

As rodas ficaram boas. Os desenhos desapareceram dos vidros. As lentes continuaram escurecendo com a película na revisão anterior; portanto a troca isolada para vehicle_lights não resolveu esse comportamento.

## Resposta sobre a textura dos vidros

Na revisão polished, o atlas com desenhos que havia sido aplicado às janelas foi substituído por diffuse e dirt uniformes de 4 × 4 pixels. Não foi um remapeamento daquele atlas. Os UVs planares válidos da etapa anterior foram mantidos para os vidros e para o gerador de quebras. As imagens de origem continuam nas pastas originais, sem exclusão.

## Correção desta etapa

A comparação com o Kuruma fornecido mostrou alfa zero em 40 vértices das lentes dianteiras. As lentes do Jetta estavam com alfa 255, inclusive depois da troca de shader.

As três classes mat_lens_* agora usam vehicle_vehglass com alfa de vértice zero, seguindo a convenção da referência. Foram ajustadas 39 variantes de LOD. Esse é o canal Color 1 no Blender, Colour0 no YFT; o alfa das texturas, que controla a aparência transparente, não foi alterado.

Somente as faces dos materiais de lentes receberam esse ajuste. As janelas mantêm alfa 255 e os emissores mantêm seus IDs de luz. Rodas, discos, pintura, texturas uniformes, brilho interno, bones e física da revisão anterior foram preservados.

## Validação

Os dois binários foram conferidos: conjunto de alfa das lentes igual a {0}, e das janelas igual a {255}. Exportação e reimportação passaram. Permanecem oito vidros quebráveis, 87 bones, 25 colisões mais o composite, uma roda física e os IDs externos de emissivo. YTD sincronizado com as mesmas 81 texturas.

Isso confirma que a nova máscara chegou aos arquivos. A independência da película ainda precisa de novo teste no GTA; não é afirmada como resolvida apenas pela leitura binária.

## Instalação e teste

YFT base, YFT hi e YTD instalados no resource jettamk8, com backup e hashes conferidos. Não houve restart/spawn pelo Codex nem alteração de metas/scripts/mod gráfico.

Reinicie jettamk8, reconecte e compare película desligada e escura sobre faróis/lanternas. Informe se as lentes ainda mudam junto com os vidros.

Relatórios: lens-report.json, native-validation.json e installation.json. Scripts/logs: C:/FiveM/drift-server/tools/jetta_tint. Referência: C:/Users/mathe/Documents/blender-projects/kuruma.

Backup: C:\FiveM\drift-server\txData\FiveMBasicServerCFXDefault_CAECC7.base\docs\evidence\jettamk8-before-lens-alpha-2026-11-01-180833
## Lentes claras com película: confirmado pelo usuário — 2026-11-01

Origem: resposta explícita do usuário ao teste comparando película desligada/escura após a revisão lens-tint-fix: lentes ficaram claras.
Estado atualizado: correção do escurecimento indevido das lentes com a película confirmada no jogo pelo usuário. A revisão usa alfa de vértice 0 nas lentes e 255 nas janelas; a troca de shader isolada da revisão anterior não bastou.
Sem alterações de assets ou configuração nesta etapa. Registrar a confirmação na revisão atual, preservando as pendências não abrangidas por este teste, incluindo intensidade interna e os acabamentos de iluminação anteriormente documentados.
