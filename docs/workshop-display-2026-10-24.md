# Exposição local na oficina — 24/10/2026

Origem: proprietário confirmou uso de MLO e autorizou expor carros salvos como cenário, priorizando desempenho e reversão simples. Projeto: `C:\FiveM\drift-server`.

## Comportamento

- Até sete carros salvos nos sete pontos fornecidos, apenas no cliente do dono, enquanto estiver na garagem privada. Não aparecem no lobby/modo livre nem para outros jogadores.
- Exclui o salvo atualmente na bancada. Com apenas esse salvo, não há carros de fundo. Seleção dos demais: criação mais recente primeiro, ID como desempate; até sete presets, podendo repetir modelo se houver criações distintas.
- Modelos são solicitados um por vez, após 1 s de preparação da bancada, com intervalo de 250 ms e timeout de 5 s por modelo. A interface não aguarda a exposição.
- Restaura aparência salva, incluindo rodas e stance, antes de revelar o carro. Sem preset de drift para cenário estático. Neons desligados por padrão.
- Carros congelados, motor/luzes desligados, trancados, sem colisão e sem dinâmica. Nenhuma escrita nos presets, progresso ou seleção do jogador.
- Limite de LOD por entidade de 55 m. Escala temporária de LOD estendido de 0,8 por frame na garagem; não altera configurações gráficas persistentes nem garante recortar somente o exterior do MLO. Pode mudar a distância de detalhe de objetos visíveis; use `worldLodScale=1.0` para neutralizar esse ajuste.
- Consulta de documentos única e limitada por proprietário/contexto/token/epoch, sem polling SQL. Lista filtra assets indisponíveis/documentos inválidos. Alteração de revisão/seleção atualiza a exposição; slots inalterados reutilizam entidades. Consulta examina no máximo 21 documentos, portanto muitos salvos inválidos recentes podem deixar vagas mesmo existindo salvos antigos válidos.
- Sair/trocar de cena, cancelar ou parar recursos limpa as entidades e libera pedidos de modelos. Identidade exclusiva protege handles reutilizados. Falha de deleção mantém registro para nova tentativa e consome o mesmo limite de sete entidades.
- Falha opcional é registrada com `[MX:DISPLAY]`, sem bloquear a garagem. Um slot com erro tenta novamente em nova revisão, nova entrada ou comando de atualização.

## Controle e reversão

Configuração: `resources/[mx]/mx-freeroam-experience/config.lua`, tabela `ExperienceConfig.display`.

No F8 do cliente, dentro da garagem:

```text
mxdisplay 0
mxdisplay 1
mxdisplay 3
mxdisplay 7
mxdisplayinfo
```

`0` remove a exposição e interrompe o ajuste de LOD. Os demais limitam a quantidade e recarregam a exposição, sem alterar salvos. Override local dura até reiniciar o recurso/cliente. `mxdisplayinfo` informa quantidade existente, pendências de limpeza, carregamento e contadores. Para desligar por configuração, use `enabled=false`; para reduzir permanentemente, altere `maxVehicles`. Configuração deve ser recarregada nos recursos.

## Verificação

`npm.cmd --prefix development test` e `npm.cmd --prefix development run check` aprovados. Novas regressões executam controladores/export/rota reais com adaptadores Lua de natives, scheduler e SQL. Cobrem limite, localidade, propriedades antes da visibilidade, reuso/revisão, token/epoch/contexto, consulta por proprietário, cancelamento durante streaming, atualização concorrente, timeout, falha cosmética, entidade inesperadamente em rede, handle reutilizado e repetidas falhas de deleção sem perder identidades/exceder orçamento. Também verificam coalescência, tentativas BUSY limitadas, comandos e escopo do LOD.

Não houve restart do servidor, cliente FiveM, benchmark, migração ou escrita em dados dos jogadores. Nenhuma alteração de NUI; não requer novo bundle.

## Aceite no jogo

Após carregar os recursos atualizados e reconectar, comparar `mxdisplay 0`, `1`, `3`, `7` na mesma câmera. Conferir FPS/GPU/memória de streaming e resmon, carregamento inicial e modelos pesados; resmon isoladamente não mede custo gráfico. Conferir altura/heading de cada modelo, cores/rodas, saída/retorno, seleção de outro salvo e ausência de duplicação da bancada. A mesma Z pode exigir ajuste para modelos de altura/origem diferentes.

Sete mods ainda podem custar muita VRAM e draw calls. Serem inertes reduz física/interação/rede; geometria e texturas continuam com custo. Rooms/portals/LODs do MLO não foram auditados nem editados, portanto não há ganho de oclusão confirmado.

Referências primárias consultadas: [CreateVehicle](https://github.com/citizenfx/natives/blob/master/VEHICLE/CreateVehicle.md), [SetEntityDynamic](https://github.com/citizenfx/natives/blob/master/ENTITY/SetEntityDynamic.md) e [OverrideLodscaleThisFrame](https://github.com/citizenfx/natives/blob/master/STREAMING/OverrideLodscaleThisFrame.md).
