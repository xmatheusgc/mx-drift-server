# Jetta MK8 — acabamento visual, rodas, vidros e lanternas

Entrega: 2026-11-01. Blender 5.1.2 / Sollumz 2.9.0.
Arquivo atual: `jettamk8-refined.blend`. A revisão anterior em `repaired` foi preservada.

## Aceite anterior do usuário

Spawn sem crash confirmado. O usuário também confirmou que suspensão, direção e portas funcionam perfeitamente na revisão anterior. Esses comportamentos não foram declarados novamente aprovados após esta atualização: o novo teste de jogo ainda está pendente.

## Alterações

| Área | Trabalho realizado |
|---|---|
| Pintura | Substituída a receita aproximada PBR por vehicle_paint1, com texturas de diffuse/specular e parâmetros do Kuruma fornecido. PRIMARY preservado. |
| Aros | O aro dentro da roda física usava vehicle_paint2. Agora aro e pneu usam vehicle_tire, com o formato de vértices apropriado ao renderer de rodas. O desenho e as cores de fábrica do aro foram preservados; o material do aro usa cor fixa para não tingir o atlas inteiro. |
| Discos | Discos vinculados aos hubs correspondentes em TODOS os LODs. As orientações auditadas tinham volume assinado positivo; não foi feita inversão generalizada de faces. |
| Vidros | Janelas usam diffuse/specular nativos de vidro automotivo, com shader externo e interno separados. Lentes vermelhas e transparentes das lanternas/faróis têm materiais próprios; não receberam o verde das janelas. |
| Airbags | Seis malhas de airbags removidas do arquivo de trabalho e, portanto, de todos os LODs exportados. Fontes originais preservadas. |
| Quebras | Oito janelas no YFT base com shattermaps AUTO gerados. Colisões de vidro reconstruídas como cascas convexas finas a partir das próprias superfícies externas. |
| Lanternas | IDs nativos de emissivo atribuídos a faróis/DRL, lanternas, freios, ré, indicadores dianteiros e placa. Multiplicadores antes zerados foram configurados. |

### UVs e grupos por LOD

Os UVs das janelas do GLB eram degenerados: UV0, UV1 e UV2 tinham todas as coordenadas no mesmo ponto. Foram reconstruídos por projeção planar compartilhada entre faces internas e externas, em cada nível de detalhe. Isso permitiu gerar as quebras.

Também havia nomes antigos de vertex groups em algumas malhas de LOD, embora o nível de maior detalhe já exibisse o nome novo. Os nomes e pesos foram recriados individualmente em 34 variantes de discos e vidros fixos. Os dois vidros triangulares traseiros ficam presos ao chassis, não às portas traseiras. Após a correção, os oito vidros são detectados pelo modo AUTO; nenhum fallback simples foi mantido.

### Lanternas e limites do acabamento

IDs efetivamente presentes nos binários: 0, 1, 2, 3, 4, 5, 6, 9, 10, 12 e 13. Os dummies relevantes foram reposicionados nas superfícies identificadas.

Não foi identificada uma superfície isolada para a terceira luz de freio ou para os indicadores traseiros, portanto sua configuração completa não é afirmada. A resposta visual das lanternas e projeção de luz ainda precisa de teste no jogo. A configuração respeita as superfícies que puderam ser identificadas pelo nome e geometria do modelo.

O teto de vidro permanece sem uma quebra física independente. As oito quebras configuradas são para para-brisa, vidro traseiro, quatro janelas de portas e dois vidros triangulares fixos.

## Colisões

As colisões principais de chassis/portas e o rig de suspensão aceitos anteriormente foram mantidos. As colisões de vidro foram refinadas. A auditoria nativa passou com 25 grupos, 25 filhos e 25 bounds, limites finitos/ordenados, volumes positivos e massa total de 1300. Isso não substitui testes de impacto, passagem de pedestres e danos dentro do FiveM.

## Verificação

- Exportação final sem avisos do Sollumz.
- Uma roda física exportável; ambos os materiais usam vehicle_tire em todos os LODs.
- Oito definições de vidro quebrável no arquivo base. O Sollumz mantém essas definições no base, e não as duplica no _hi; isso segue o exportador instalado.
- IDs de emissivo conferidos nos buffers de vértices dos dois arquivos.
- 47 shaders e 78 texturas embutidas por arquivo; YTD externo regenerado com as mesmas 78 texturas, evitando sobreposições de dados antigos.
- Reimportação do par base/_hi aprovada: 87 bones, 25 colisões mais o composite e uma roda física.
- Ausência de airbags e os 34 vínculos de LOD foram verificados na cena salva.
- Render em `preview.png` inspecionado. O render é referência visual; brilho e transparência finais devem ser avaliados no GTA.

## Instalação e teste

Os dois YFTs e o YTD foram instalados em `resources/[vehicles]/jettamk8/stream`, com backup e hashes conferidos. Nenhuma alteração nesta etapa em handling, vehicles.meta, carcols ou scripts do servidor. Nenhum restart/spawn executado pelo Codex.

Reinicie `jettamk8`, reconecte e confira: pintura sob iluminação do jogo; aro e disco nas quatro rodas; vidros por dentro/fora; ausência de airbags; faróis/lanternas à noite; freio, ré e indicadores dianteiros; quebra das oito janelas e colisões. O brilho também deve respeitar o acabamento de pintura selecionado no jogo.

## Arquivos e continuidade

`refinement-report.json`, `native-validation.json`, `lod-collision-validation.json` e `installation.json` registram as alterações/testes. Scripts e logs: `C:/FiveM/drift-server/tools/jetta_finish`.

Para repetir a preparação a partir da revisão anterior: refine.py → fix_window_uv.py → fix_lod_groups.py → validate.py → validate_details.py. Os scripts têm caminhos específicos deste projeto. O script finalize_windows.py é histórico de diagnóstico e não faz parte da versão final. Preserve seus ajustes manuais antes de executar novamente.

Após editar números dos shaders, use o texto embutido `Atualizar preview dos parametros.py` para sincronizar os nós de preview; os parâmetros de exportação permanecem nativos. Para reexportar, gere base e hi juntos em GEN8 e sincronize o YTD com as texturas atuais.

## Referências

- https://docs.sollumz.org/documentation/fragments.yft/vehicle-shaders
- https://docs.sollumz.org/documentation/fragments.yft/vehicle-setup/vehicle-windows
- https://docs.sollumz.org/documentation/fragments.yft/vehicle-setup/light-ids

Backup da revisão anterior: C:\FiveM\drift-server\txData\FiveMBasicServerCFXDefault_CAECC7.base\docs\evidence\jettamk8-before-visual-refinement-2026-11-01-165015
## Resultado do teste do usuário — 2026-11-01

Origem: resposta explícita do usuário nesta conversa após o pedido de testar a revisão refined instalada: a pintura ficou melhor, os vidros quebram e as rodas aparecem corretamente.
Confirmado no jogo: melhora da pintura, funcionamento das quebras de vidro e visibilidade das rodas. Não extrapolar esse relato para aprovação da transparência, dos discos, da ausência visual dos airbags, das lanternas ou de impactos/colisões; esses itens não foram confirmados individualmente nesta resposta. Os aceites anteriores de spawn, suspensão, direção e portas permanecem como histórico.
Nenhuma alteração de assets ou configuração nesta etapa. Próximo passo: avaliar os itens restantes conforme o usuário testar e relatar; indicadores traseiros, terceira luz de freio e quebra independente do teto continuam com as limitações documentadas.
