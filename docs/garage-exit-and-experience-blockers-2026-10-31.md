# Saída da garagem e revisão de bloqueios — 2026-10-31

Origem: usuário relatou ENGINE_START e saída bloqueada por outro jogador, pediu correções e uma varredura de condições que interrompem a experiência. Inspeção/implementação Codex na base CFX ativa. Os demais casos abaixo foram identificados no código; não são relatos de falhas reproduzidas em FiveM nesta sessão.

## Corrigido

- **Motor desligado ou partida demorada:** `vehicles/client.lua`, handler `depart`, tenta ligar e mantém apenas a apresentação breve configurada (450 ms), liberando freio/congelamento mesmo se `GetIsVehicleEngineRunning` continuar falso. `experience/server.lua`, rota `play`, deixou de exigir `running=true`. Veículo, motorista, identidade de rede e sessão continuam validados. A resposta informa o estado observado sem declarar uma partida que não ocorreu.
- **Outro carro/jogador na saída:** `world/server.lua`, export `ReservePresentationExit`, retorna o ponto configurado com `ghost=true`, sem consultar ocupação nem disputar reserva. Esta mudança é específica da saída da oficina.
- **Proteção ao nascer:** `vehicles/server.lua` publica `mxDepartureGhost` antes de aplicar propriedades/sentar o motorista. O prazo mínimo de 5 segundos começa após concluir o spawn. Enquanto houver outro veículo ou jogador do mesmo bucket a menos de 8 m, permanece ativo. Exige área livre por 1 segundo antes de remover. Durante aplicação/carregamento, também permanece protegido; o tempo de preparação não gasta o mínimo.
- **Todos os clientes:** `departure-ghost-client.lua` descobre o estado replicado e aplica `SetEntityNoCollisionEntity` nos dois sentidos, por frame, entre o carro protegido e veículos/peds próximos. O chão, os objetos e as paredes continuam com colisão. Quando o estado é removido ou a identidade muda, a supressão deixa de ser renovada. O servidor limpa o estado no encerramento normal do resource.
- **Concorrência:** saídas simultâneas não recusam uma à outra; cada veículo recebe proteção própria. Não há evento público para pedir modo fantasma ou escolher coordenadas de saída.

Referência primária do native: [Cfx / citizenfx, SetEntityNoCollisionEntity](https://github.com/citizenfx/natives/blob/master/ENTITY/SetEntityNoCollisionEntity.md). A opção por frame evita deixar pares permanentemente sem colisão após o fim da proteção.

## Outros bloqueios encontrados e sugestões (ainda não implementadas)

| Prioridade | Condição no código | Por que merece revisão | Correção sugerida |
|---|---|---|---|
| Alta | `vehicles/client.lua:80–85`, `customization.lua:163–190`: pintura, peça ou extra não confirmado interrompe aplicação; spawn exige ACK global | Um detalhe visual recusado pode impedir sair com um veículo funcional. Há recuperação de rodas/peças inválidas, mas a confirmação final ainda pode abortar. | No spawn, tentar novamente por item e usar último valor confirmado/original com aviso discreto. Preservar a criação salva. Em uma gravação explícita, continuar exigindo confirmação do item que será persistido. |
| Alta | `vehicles/garage.lua:61–63`: PREVIEW_DELETE por timeout de remoção/ACK do cliente | A saída chama remoção com ACK antes de criar o carro de gameplay; uma cópia antiga atrasada pode bloquear a viagem. | Após revogar contexto e confirmar remoção no servidor, encerrar o fluxo visual antigo e limpar restos locais em segundo plano, por identidade. Manter rastreamento e nova tentativa de exclusão de órfãos. |
| Alta | `experience/server.lua:374–377`: reinício da interface/oficina chama DropPlayer | Reiniciar um menu desconecta uma pessoa que poderia recuperar o contexto. | Revogar token/epoch privado, remover prévia, restaurar bucket/posição e remontar UI quando disponível. Desconectar só se a recuperação segura realmente falhar. |
| Média | `vehicles/server.lua:37`: cooldown de spawn também incide em SpawnSavedAt | Voltar rapidamente à garagem e sair pode ser recusado pelo prazo de 5 s, apesar da sessão privada serializada. | Separar cooldown de troca livre e saída autorizada da garagem. Manter limites de entidades, serialização e proteção contra spam de solicitações. |
| Média | `world/server.lua:18,32`: todos os slots ocupados ou sem vaga aprovada bloqueiam destinos/spawn livre | A correção atual vale para saída da garagem; outros fluxos ainda podem recusar por trânsito. | Estender proteção de chegada aos destinos aprovados e procurar vaga próxima. Preservar validação do mapa/destino e proteção dos ocupantes de carros existentes. |
| Média | `experience/character.lua:43–46`: roupa, acessório ou overlay salvo indisponível aborta Character.apply | Um item visual removido por atualização pode impedir preparar personagem/cena/saída. | Validar e recuperar apenas o item ausente com padrão compatível; preservar os demais itens e o documento salvo até confirmação do usuário. Rejeitar payload inválido continua necessário. |
| Média | `experience/client.lua:122,181,246,251`: aquisição/sightline de câmera falha | Sem câmera de detalhe, a ação pode terminar em erro de experiência. Os testes de espaço são úteis, mas podem ter alternativa. | Manter a última câmera válida ou retornar à câmera principal; indisponibilizar apenas o movimento/ângulo sem espaço. Nunca tomar a câmera de outro fluxo à força. |
| Média | `experience/server.lua:347,351`: banco do motorista conferido imediatamente no servidor | Replicação pode chegar depois do ACK do cliente e aparentar motorista ausente. Isso é uma possibilidade inferida do código, não reproduzida aqui. | Aguardar por um prazo curto com identidade/bucket/epoch conferidos; falhar somente se o motorista continuar errado. Não eliminar a checagem de propriedade. |

## Bloqueios com justificativa que devem continuar

- Payload/identificador inválido, jogador sem autenticação, token/epoch obsoleto, propriedade de carro/preset incorreta e conflito de revisão na gravação: protegem autorização, integridade e dados persistidos.
- Carro inexistente/modelo realmente indisponível, outro motorista no veículo e troca da identidade durante uma operação: não há entidade correta para entregar ao jogador. Melhorar recuperação/espera não significa aceitar uma entidade alheia.
- Passagem de passageiros ao apagar/substituir um carro: evita apagar o veículo de outra pessoa durante o uso. Possível evolução é reter o carro ocupado até desembarcarem, com orçamento controlado.
- Colisão do **destino físico** em `experience/client.lua:387` ainda é exigida. Liberar física num local sem chão pode causar queda. Evolução sugerida: manter veículo/ped suspensos durante streaming e oferecer saída alternativa segura, sem obrigar a refazer a garagem. Não confundir com solo da apresentação, já tornado opcional na etapa anterior.
- Primeiro personagem/carro inexistente exige um estado jogável. Flags de onboarding inconsistentes devem ser reparadas a partir de dados válidos, sem inventar que houve gravação.

## Verificação e limites

- `npm.cmd --prefix development run test:exit`: motor lento/desligado, limpeza de freio/congelamento, motorista/identidade, spawn real com ghost antes de aplicação, rota real play sem motor, fechamento de sessão privada, saídas simultâneas/ocupadas, coordenadas inválidas, tempo mínimo, espera enquanto ocupado, estabilidade da liberação, buckets, reciclagem de entidade, limpeza no stop e observadores com estado replicado.
- `test:garage`, `test:wheels`, `test:loading` e `check` aprovados. Loading inclui navegador Chrome em quatro resoluções. Adapters de natives/RPC/SQL; não comprovam física nem latência reais.
- Nenhuma mudança de NUI nesta etapa; não foi necessário rebuild. Nenhum restart, SQL real ou teste dentro do FiveM. Próximo teste físico: duas pessoas saindo juntas, carro estacionado/pessoa a pé na saída, motor que não confirma, deslocamento para liberar proteção, observador remoto e retorno rápido à garagem.
- Configuração atual usa raio conservador de 8 m, não teste exato de malhas: pode prolongar o modo fantasma perto de um carro/ped mesmo sem sobreposição. Não existe expiração forçada enquanto a área permanece ocupada. Assets excepcionalmente longos exigem validar esse raio no jogo.
