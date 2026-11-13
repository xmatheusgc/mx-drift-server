# Jetta MK8 — lentes, vidro uniforme, aro, discos e brilho interno

Data: 2026-11-01. Blender 5.1.2 / Sollumz 2.9.0.
Arquivo atual: `jettamk8-polished.blend`. Fontes e revisões anteriores preservadas.

## Retorno do usuário sobre a revisão anterior

Confirmou discos visíveis, vidros normais quanto à transparência e ausência dos airbags bugados. Lanternas e colisões parecem funcionar bem, segundo seu relato. Pontos pedidos: película escurecendo lentes, desenhos mal mapeados nos vidros, roda cromada demais, discos lisos e emissão interna excessiva. O usuário levantou a possibilidade de influência do mod gráfico na iluminação.

## O que mudou

| Área | Revisão |
|---|---|
| Lentes | Três materiais de lentes passaram de vehicle_vehglass para vehicle_lights, mantendo transparência e a cadeia de shader de veículo. As lentes vermelhas/claras/fumês estão separadas das janelas. |
| Janelas | Só as janelas mantêm vehicle_vehglass/inner. Diffuse e dirt viraram texturas uniformes de 4 × 4, sem desenhos de atlas; média de cor/opacidade aproximada da textura anterior preservada. Os UVs válidos continuam para as oito quebras AUTO. |
| Aro | Albedo original e geometria do emblema VW preservados. ReflectivePower reduzido de 0.45 para 0.14; o mapa prateado foi substituído por máscara especular baseada na luminância do atlas (0.025–0.175). Shader vehicle_tire preservado. |
| Discos | Novos diffuse de desgaste radial e normal map DirectX de ranhuras concêntricas, com mipmaps. Mapeamento planar Y/Z calculado para cada disco em seus 18 LODs existentes. Specular/reflexão ajustados para aço acetinado. |
| Interior | EmissiveMultiplier de 1.0 para 0.10 nas duas telas e 0.035 na iluminação de ambiente. Não existem luzes point/spot embutidas no veículo; o ajuste foi nas superfícies emissivas. |

Os nomes no Blender foram padronizados como `mat_lens_clear`, `mat_lens_smoked`, `mat_lens_red`, `mat_window_clear`, `mat_window_tinted` e `mat_window_inner`. A identificação do material de origem foi mantida.

As texturas dos discos são um acabamento procedural novo, sem iluminação/reflexos pintados na imagem. O mapa especular do aro reduz o reflexo das áreas escuras para recuperar a leitura do desenho e do emblema.

## Preservação e verificação

Não houve alteração de vértices/peças, bones, suspensão, portas ou parâmetros de quebra. A comparação binária confirmou a mesma hierarquia de 87 bones, os mesmos tipos/limites/inércia/centros/volumes dos 25 bounds e a massa total de 1300 da versão anterior.

Passaram:

- exportação sem avisos e reimportação do par base/hi;
- oito janelas quebráveis no base, uma única roda física e mesmos IDs externos de luz;
- três materiais de lentes fora do shader de janelas;
- texturas de vidro realmente uniformes e de 4 × 4 pixels;
- UVs dos discos com variação nos dois eixos em todos os 18 LODs existentes;
- emissão interna com os novos valores;
- 47 shaders e 81 texturas embutidas, com YTD externo sincronizado;
- conferência dos hashes após a instalação.

`preview.png` e `wheel-detail.png` foram renderizados e inspecionados. Não são teste de GTA: película, resposta ao ambiente, exposição e bloom devem ser conferidos no jogo.

## Instalação e novo teste

Atualizados somente `jettamk8.yft`, `jettamk8_hi.yft` e `jettamk8.ytd` em `resources/[vehicles]/jettamk8/stream`. Nenhuma mudança em metas, handling, scripts ou mod gráfico. Nenhum restart/spawn executado pelo Codex.

Reinicie `jettamk8` e reconecte. Compare película desligada/escura para verificar que apenas as janelas são afetadas. Confira os vidros contra o céu, aro/VW sob diferentes reflexos, discos de perto e luz interna à noite. O resultado da nova revisão ainda depende desse teste.

O mod gráfico pode ampliar o brilho residual por exposição/bloom; sua influência não foi diagnosticada nem alterada. Caso necessário, os três EmissiveMultiplier ficam nos materiais `mat_display_*`. Após editar os números, execute o texto embutido `Atualizar preview dos parametros.py` para sincronizar o preview.

## Arquivos

- `polish-report.json`: alterações e valores.
- `native-validation.json`: dados nativos e reimportação.
- `visual-validation.json`: materiais, UVs e comparação física.
- `installation.json`: arquivos, hashes e backup.
- Scripts/logs: `C:/FiveM/drift-server/tools/jetta_finish2`.

As limitações anteriores de identificação da terceira luz de freio/indicadores traseiros e de quebra independente do teto permanecem documentadas na revisão anterior; não foram ampliadas nesta etapa.

## Referência

https://docs.sollumz.org/documentation/fragments.yft/vehicle-shaders

Backup: C:\FiveM\drift-server\txData\FiveMBasicServerCFXDefault_CAECC7.base\docs\evidence\jettamk8-before-lenses-wheel-detail-2026-11-01-172846
