# Ambiente sincronizado dinâmico

O servidor é o único responsável pelo ciclo, implementado em `resources/[mx]/mx-freeroam-world/environment-server.lua`. `GlobalState.mxEnvironment` é substituído por um snapshot completo a cada segundo real, contendo hora, minuto, segundo, clima de origem/destino e proporção de transição. Clientes recém-conectados usam a mesma fase; não sorteiam um ciclo próprio.

## Configuração

Edite `resources/[mx]/mx-freeroam-world/config.lua`:

- `hour`, `minute`, `weather`: estado inicial ao iniciar/reiniciar o resource.
- `environment.secondsPerGameMinute=4`: um dia completo leva 96 minutos reais.
- `environment.weatherIntervalMinutes=15`: intervalo real entre escolhas de clima.
- `environment.weatherTransitionSeconds=60`: duração real da mistura gradual.
- `environment.weatherTransitions`: destinos possíveis para cada clima. Itens repetidos podem servir como pesos. Todos os destinos precisam ter sua própria lista, com ao menos um destino diferente.

O padrão transita entre sol, céu limpo, nuvens, névoa/neblina, encoberto, chuva, tempestade e melhora do tempo. Neve não participa do ciclo padrão; continua disponível como escolha pessoal. O relógio usa tempo real decorrido entre ticks, evitando desacelerar por atraso do agendamento, com tratamento da volta do timer de 32 bits.

Ao reiniciar o servidor/resource, o ciclo volta ao estado inicial da configuração. Não é sincronizado ao horário civil nem persistido no banco. A revisão de condições passa de `clear-14-v1` para `dynamic-environment-v1`; resultados antigos são preservados e não são apresentados como resultados do novo regime. A revisão identifica o regime dinâmico, não muda a cada minuto/clima.

## Preferências e cenas

Quem mantém **Sincronizar clima/horário** acompanha o ciclo automaticamente. Cada sincronização é independente. Desligar uma copia o valor atual do servidor e permite escolher um valor pessoal fixo; não altera outros jogadores. O menu atualiza seus valores enquanto permanece aberto. Lobby/garagem continuam tendo prioridade temporária; ao sair, world retoma a fase corrente do servidor ou a preferência pessoal.

O loop de renderização já existente de world continua sendo o único a escrever clima/relógio. Mistura de clima utiliza [SetWeatherTypeTransition](https://raw.githubusercontent.com/citizenfx/natives/master/MISC/SetWeatherTypeTransition.md); horário utiliza [NetworkOverrideClockTime](https://raw.githubusercontent.com/citizenfx/natives/master/NETWORK/NetworkOverrideClockTime.md), com limites validados.

## Verificação

Regressões exercitam o código real com adaptadores: velocidade e frações de tempo, dia/meia-noite, atraso e rollover do timer, configuração inválida, grafo e mistura de clima, snapshot no meio da transição, publicação pelo thread real, escolhas pessoais, retorno à sincronização e prioridade/restauração das cenas. Build, typecheck, check e testes foram executados; evidência em `docs/evidence/dynamic-environment-2026-10-21.json`.

Não houve execução/reinício de FXServer nem cliente FiveM nesta entrega. A aparência da mistura, passagem visual do relógio, replicação entre dois clientes e retorno das cenas precisam ser verificados no jogo. Para carregar o novo script do manifest, reinicie o servidor em um momento apropriado e reconecte.
