# Consulta: exposição de carros na oficina — 24/10/2026

Projeto: Drift server FiveM, C:\FiveM\drift-server. IA: Codex. Origem: proprietário propôs mostrar veículos salvos dentro da oficina, questionou desempenho e redução de renderização do exterior. Pedido explícito: apenas explicar, sem implementar ainda.

Pontos propostos, não aplicados:

```lua
{x=124.648,y=-3047.350,z=6.381,h=269.64}
{x=124.648,y=-3040.890,z=6.381,h=269.64}
{x=124.648,y=-3035.130,z=6.381,h=269.64}
{x=124.648,y=-3022.980,z=6.381,h=269.64}
{x=148.742,y=-3043.695,z=6.385,h=235.60}
{x=144.540,y=-3045.477,z=6.385,h=25.45}
{x=137.056,y=-3046.604,z=6.385,h=179.94}
```

Pesquisa em fontes primárias: MLO define rooms/portals (Sollumz, https://docs.sollumz.org/tutorials/creating-interiors/create-ytyp); distância de LOD pode ser controlada por entidade e escala de LOD por frame (citizenfx/natives, SetEntityLodDist.md e OverrideLodscaleThisFrame.md). SetFocusPosAndVel orienta área de streaming/render do terreno; não é promessa de descarregar tudo fora da oficina. Código local scene-streaming.lua já usa foco temporariamente no preparo e depois ClearFocus. Não foi auditada a configuração de rooms/portals do pack da oficina.

Orientação proposta, sem decisão de implementar: avaliar interior/oclusão, LODs reais dos assets, veículos de exposição locais/inertes, carregamento gradual e redução de qualidade dos veículos de fundo. Desenhar menos exterior pode aliviar GPU, mas sete modelos/texturas pesados continuam podendo consumir memória e causar carga no cliente. Bucket privado isola entidades/sessões, não remove o mapa base. Sem benchmark ou limite de carros afirmado.

Medição futura: comparar 1/3/7 carros e FPS/GPU/streaming (cl_drawperf, strmem), junto de resmon para CPU/memória dos resources; fontes oficiais https://docs.fivem.net/docs/client-manual/console-commands/ e https://docs.fivem.net/docs/scripting-reference/onesync/.

Nenhum script/configuração alterado, nenhum carro criado ou teste de desempenho executado. Próximo passo depende de autorização futura para implementar/avaliar a exposição. Somente export local; memória Obsidian compartilhada sem escrita permitida.
