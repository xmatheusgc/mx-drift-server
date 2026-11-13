# População ambiente ativada por padrão — 2026-10-30

Origem: usuário pediu tráfego de veículos e NPCs ligado por padrão, com densidade e variedade máximas, para o mundo compartilhado.

Alterações:

- `config/server.cfg`: `set onesync_population true` explícito.
- `world/config.lua`: `traffic=1.0` e `pedestrians=1.0`. O loop existente aplica os valores para veículos em movimento, aleatórios, estacionados, pedestres e cenários a cada quadro.
- `world/server.lua`: população do bucket público 0 habilitada; lockdown passa de `strict` para `relaxed` para permitir população ambiente nativa mantendo bloqueio de entidades pertencentes a scripts criadas pelos clientes.
- `world/client.lua`: orçamento de veículos/pedestres em 3 e redução de orçamento de modelos desligada, inicializados com o loop de renderização.

Variedade usa o orçamento completo da população nativa; a seleção efetiva depende da região, horário, streaming e regras do GTA. Isso não injeta os carros addon do catálogo nas listas de tráfego nem cria navegação para mapas customizados sem suporte de população. Lobby e garagem mantêm buckets privados com população desligada e lockdown strict. Polícia/wanted e despachos continuam desativados conforme regras existentes.

Verificação: `npm.cmd --prefix development run check` aprovado. Regressões existentes de `world-preview.lua` executadas com Fengari e natives simuladas, incluindo orçamento completo e restauração de clima/horário; configuração real de densidades e sintaxe dos três arquivos Lua alterados conferidas. Sem teste de spawn/população ou desempenho no FiveM. Nenhum reinício executado. Próximo passo: reiniciar servidor e reconectar; validar carros e pedestres em região urbana do mapa base com dois jogadores.

Fontes primárias: [densidade de veículos](https://github.com/citizenfx/natives/blob/master/VEHICLE/SetVehicleDensityMultiplierThisFrame.md), [orçamento de pedestres](https://github.com/citizenfx/natives/blob/master/STREAMING/SetPedPopulationBudget.md), [OneSync e lockdown](https://docs.fivem.net/docs/scripting-reference/onesync/), [onesync_population](https://docs.fivem.net/docs/server-manual/server-commands/#onesync_population-truefalse).
