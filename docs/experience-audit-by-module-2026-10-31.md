# Auditoria geral de erros e bloqueios da experiência — por módulo

Data: **31/10/2026**, horário de referência America/Sao_Paulo. Origem: solicitação do usuário para investigar toda a base, ampliando o relatório anterior da garagem. Autor: Codex, análise local de código, configuração, manifests e log. **Este relatório não propõe correções e não altera o comportamento do servidor.**

## Escopo e leitura dos resultados

Base examinada: `C:/FiveM/drift-server/txData/FiveMBasicServerCFXDefault_CAECC7.base`. A configuração de entrada usa `config/development.cfg`, que inclui `config/server.cfg`; este inicia as categorias de assets, `[mx]`, `oxmysql`, `pma-voice`, `mx-gearbox` e `mx-soundcore`. Arquivos de segredos e identidades de jogadores não foram reproduzidos. Legado arquivado fora dessa base não foi tratado como código ativo.

O inventário abrange **80 recursos com manifest**, **77 abrangidos pelo início configurado**, **389 arquivos de código/interface** e **7 arquivos compilados/minificados** incluídos somente no inventário de empacotamento. Foram localizados **1.486 pontos de rejeição, retorno de falha, espera, recuperação ou bloqueio de entrada**. Esse número **não significa 1.486 bugs**: há validações de segurança, regras de produto, tratamento de falhas e vários pontos de um mesmo fluxo. Recursos configurados não foram confirmados individualmente no processo em execução. A pasta recebeu novos mapas durante a investigação; os números correspondem ao inventário final salvo.

Este documento consolida **215 situações** por efeito para o jogador. A contagem de locais também inclui os recursos instalados fora do início configurado e o resource de testes, identificados separadamente. O [anexo técnico completo](experience-error-sites-2026-10-31.md) contém os locais individuais por recurso e arquivo, as referências de manifest sem correspondência e os grupos de eventos do log. O [inventário JSON](evidence/experience-audit-2026-10-31/inventory.json) preserva caminhos, linhas e hashes das fontes consultadas.

**Evidência:** **C** = condição/comportamento explícito no código ou configuração; **L** = ocorrência no log histórico local; **H** = efeito possível inferido do encadeamento do código, não reproduzido nesta sessão; **R** = bloqueio já removido no código em etapa anterior. Uma condição C pode ser intencional e legítima. Uma ocorrência L não prova que a falha continua presente na versão atual. Os códigos nas tabelas são os códigos do programa quando existem; os identificadores da primeira coluna pertencem apenas a este relatório.

**Limite de completude:** o levantamento cobre as condições identificáveis nas fontes acessíveis e nos registros disponíveis. Não foi executada uma sessão FiveM, uma carga multiplayer, uma conexão externa nem uma inspeção de malhas/colisões binárias. Scripts compilados e assets não permitem afirmar ausência de erros internos. Nenhum relatório estático consegue enumerar toda falha possível de rede, hardware, runtime ou serviço externo.

## 1. Inicialização, configuração, dependências e conexão externa

Fontes: `server.cfg`, `config/`, manifests dos recursos e `txData/default/logs/fxserver.log`.

| ID | Evidência | Condição/erro | Efeito para o jogador | Referência |
|---|---|---|---|---|
| BASE-01 | C/H | `LosSantosRemoved` é iniciado pela categoria `[maps]`; seu manifest declara remover o mapa padrão e usa `replace_level_meta "empty"`. Lobby, garagem, saída e destinos continuam em coordenadas de Los Santos/Sandy. | Possibilidade de cenário/solo ausente ou inadequado em locais usados pelo fluxo principal. A configuração e as coordenadas estão confirmadas; a relação com uma queda específica não foi testada no jogo. | `resources/[maps]/LosSantosRemoved/fxmanifest.lua`; `empty.meta`; `config/assets.cfg`; `experience/config.lua`; `world/tracks-config.lua` |
| BASE-02 | L | O serviço de listagem informa repetidamente que não conseguiu alcançar o servidor. | O servidor pode aparecer na lista e ainda assim não aceitar conexões de fora. Não foi testada a acessibilidade externa atual. | Log: 172 ocorrências classificadas como conectividade; exemplos nas linhas 4045 e 4621. |
| BASE-03 | L | Hitches de threads do servidor/sincronização. | Pausas ou atraso na simulação e nas confirmações de ações são possíveis. Há 29 avisos no arquivo; isso não mede a experiência de um cliente específico. | Log, categoria `hitch` no anexo. |
| BASE-04 | C | Manifests exigem recursos e versões do runtime; `oxmysql` requer `/server:12913`, voz requer `/onesync`, scripts MX encadeiam dependências. | Falha de início de uma dependência pode impedir iniciar módulos ou deixar suas ações indisponíveis. | `resources/[vendor]/oxmysql/fxmanifest.lua`; `pma-voice/fxmanifest.lua`; manifests `[mx]`. |
| BASE-05 | C | Perfil de produção desativa rascunhos; os destinos estáticos e a pista de teste estão marcados como não validados. | Destinos/atividade que aparecem no ambiente de desenvolvimento podem ficar indisponíveis ao mudar para produção. | `config/production.cfg`; `world/tracks-config.lua`; `activities/config.lua`. |
| BASE-06 | C | Criação de grupos e loja estão desabilitadas no lobby; Discord depende do convite configurado. O lateral de pausa mostra Discord desabilitado independentemente desse convite. | Funções visíveis não podem ser acionadas; não há erro de backend para esses botões. | `development/ui/src/Lobby.tsx`; `PauseMenu.tsx`; `config/server.cfg`. |
| BASE-07 | C | A configuração de desenvolvimento habilita o jogador fictício de teste no trainer. | A lista pode apresentar um alvo que não representa outro jogador real. | `config/development.cfg`; `development/ui/src/SessionMenu.tsx`. |

## 2. `mx-freeroam-core` — acesso, perfil, banco e comunicação

Diretório: `resources/[mx]/mx-freeroam-core/`.

| ID | Evidência | Condição/erro | Efeito para o jogador | Referência |
|---|---|---|---|---|
| CORE-01 | C | Banco ou versão de migrations não pronta (`DATABASE`). | Entrada recusada; operações dependentes de persistência não são confirmadas. | `server.lua:8`; `server.lua:101`; bloco `MySQL.ready`. |
| CORE-02 | C | Falta da licença da plataforma. | Conexão recusada antes de carregar o perfil. | `server.lua:103`. |
| CORE-03 | C | Módulo administrativo indisponível ou verificação de acesso lança erro. | Mesmo jogador sem banimento pode ter entrada recusada por indisponibilidade da verificação. | `server.lua:105–108`. |
| CORE-04 | C | Identidade já registrada em outra sessão. | Nova conexão recusada com mensagem de sessão existente. | `server.lua:109`. |
| CORE-05 | C | Consulta, transação, decodificação ou montagem do perfil falha durante a conexão. | Entrada recusada com mensagem de falha ao carregar perfil; dados existentes não são declarados perdidos. | `server.lua:111–121`. |
| CORE-06 | C | Mais de 40 requisições em 10 s ou mesma ação com intervalo inferior a 150 ms (`RATE`). | Pedidos de módulos distintos podem ser recusados pelo mesmo orçamento do jogador. | `config.lua`; `server.lua:23–29`; `shared.lua:72`. |
| CORE-07 | C | Outra operação detém o lock do jogador (`BUSY`). | Nova operação é recusada enquanto a anterior não retorna; o lock é compartilhado entre domínios que usam `Run`. | `server.lua:31–38`; `shared.lua`. |
| CORE-08 | C | Módulo solicitado não está iniciado (`UNAVAILABLE`). | Ação não é enviada ao servidor. | `client.lua:4`. |
| CORE-09 | C | Cliente não confirma RPC (`CLIENT_TIMEOUT`) ou responde com falha (`CLIENT_ERROR`/código de domínio). | Operação para, podendo acionar rollback do módulo chamador. Prazos: 12 s padrão, 35 s para modelo e 105 s para cena. | `server.lua:43–58`; `config.lua`. |
| CORE-10 | C | Requisição externa sem resposta em 240 s (`TIMEOUT`). | Jogador fica aguardando o resultado e recebe confirmação incerta; o prazo NUI é 245 s. | `client.lua:7`; `config.lua`; `development/ui/src/api.ts`. |
| CORE-11 | C | Payload malformado, acima de 16 KiB, ação inexistente, ID repetido, sessão/epoch trocado. | Rejeição da ação; respostas tardias ou inválidas não concluem a operação. | `shared.lua:69–75`; `server.lua:33,51,65`. |
| CORE-12 | C | Preferências inválidas ou revisão concorrente (`PREFERENCES`, `CONFLICT`). | Configuração não é salva; o cliente recebe erro ou precisa recarregar estado. | `server.lua:69–95`. |
| CORE-13 | C | Exceção inesperada é convertida em `UNAVAILABLE`. | Mensagem genérica de resultado não confirmado; o motivo técnico fica no diagnóstico local/servidor. | `shared.lua:6–10,83–86`. |
| CORE-14 | C | Reinício do core executa `DropPlayer` para perfis carregados. | Todos esses jogadores são desconectados. | `server.lua:146`. |
| CORE-15 | C/H | O evento de perfil depende da sessão de rede e da resposta a `mx:core:ready`; o cliente não contém uma rotina periódica de reenvio desse pedido. | Se a entrega do perfil não ocorrer, consumidores podem permanecer aguardando. É risco de fluxo, sem perda de evento reproduzida aqui. | `client.lua:13–18`; `experience/client.lua`, espera de 25 s. |

## 3. `mx-freeroam-experience` — lobby, oficina, personagem e apresentação

Diretório: `resources/[mx]/mx-freeroam-experience/`. Prévia de carros e persistência de veículos também aparecem no módulo vehicles, na seção seguinte.

| ID | Evidência | Condição/erro | Efeito para o jogador | Referência |
|---|---|---|---|---|
| EXP-01 | C | Abrir lobby dentro de veículo a 0,5 m/s ou mais (`LOBBY`). | Lobby não abre; pede para parar. | `client.lua:34`. |
| EXP-02 | C | Personagem ainda não existe/replicou ao servidor (`PLAYER_NOT_READY`), prazo de entrada 6 s. | Entrada na oficina/lobby recusada. | `server.lua:102–111`; `config.lua`. |
| EXP-03 | C | Desembarque local ou confirmação no servidor não chega (`DRIVER`). | Entrada, troca de cena ou saída é interrompida. | `entry-transfer.lua:19–31`; `client.lua:301`; `server.lua:79–84,169`. |
| EXP-04 | C | Snapshot de entrada anterior ainda pendente (`BUSY`). | Outra transferência para a apresentação não começa. | `entry-transfer.lua:14`. |
| EXP-05 | C | `ps-tuners` parado, archetype do mapa ausente, interior/modelos/cena/colisão sem confirmação. | Oficina pode ficar preparando por até 90 s e depois recuperar a sessão com `SCENE_ASSET`/`SCENE_STREAM`. | `scene-streaming.lua`; `config.lua:3`. |
| EXP-06 | C | Posição/bucket de entrada não confirma a até 8 m no prazo de 6 s (`POSITION`). | Cena preparada pelo cliente pode ser cancelada pela conferência do servidor. | `server.lua:86–99,136,175`. |
| EXP-07 | C | Token/epoch inválido, sessão deixando a oficina ou cena substituída (`SESSION`, `OBSOLETE`). | Ações/edições tardias são recusadas. | `server.lua:21–23`; `client.lua:304,307`; `scene-streaming.lua:35`. |
| EXP-08 | C | Prévia de rede ainda não disponível ou com identidade divergente (`VEHICLE_SYNC`). | Cena não conclui a preparação do carro; aparece mensagem para reabrir garagem. | `client.lua:369–380`. |
| EXP-09 | C | Falha em qualquer estágio de entrada executa recuperação; primeira entrada permanece protegida no lobby. | Jogador não recebe controle do mundo; precisa de uma nova entrada. Recuperação pode não ser confirmada. | `server.lua:113–124`; `client.lua`, `abortEntry`. |
| EXP-10 | C | NUI não confirma duas renderizações/ACK do lobby em até 12 s. | Loading inicial não é encerrado automaticamente; o erro informa que a interface não respondeu. | `client.lua`, `showLobby` e `LobbyReady`. |
| EXP-11 | C | Perfil não chegou após 25 s. | Loading continua mostrando espera de sincronização; esse aviso não conclui nem aborta a entrada. | `client.lua`, thread `Wait(25000)`. |
| EXP-12 | C | Outro dono da câmera impede `AcquireView`; câmera de detalhe/livre não encontra trajeto ou espaço (`CAMERA`). | Enquadramento ou ação de edição retorna erro; em preparação inicial, pode interromper a cena. | `camera.lua`; `client.lua:122,181,246,251`. |
| EXP-13 | C | Modelo de personagem não carrega no prazo (`MODEL`). | Aplicação de aparência e os fluxos que a chamam não concluem. | `character.lua:20–29`. |
| EXP-14 | C | Roupa, textura, acessório ou overlay salvo não existe no modelo atual (`CLOTHES`, `APPEARANCE`). | Uma peça incompatível pode interromper a aplicação inteira do personagem. | `character.lua:43–46`. |
| EXP-15 | C | Formato/versão/modelo/cores/quantidade/intervalos da aparência inválidos. | Prévia ou gravação recusada antes de aplicar. | `rules.lua:13–26`. |
| EXP-16 | C | Aparência ou garagem mudou de revisão; operação/id reutilizado com outro conteúdo (`CONFLICT`, `OPERATION`, `PRESET`). | Gravação recusada, mantendo necessidade de reconciliar estado/resultado. | `server.lua:51–56,210,238,258`. |
| EXP-17 | C | Flags de personagem/carro incompletas, corrupção da aparência, carro não selecionado/salvo (`ONBOARDING`). | Fluxo direcionado à recuperação/primeira criação; prévia de carro e Jogar podem ser recusados. | `server.lua`, `state`, `character`, `preview`, `play`; `rules.lua`. |
| EXP-18 | C | Modelo fora do Showroom, preset indisponível ou modelo da prévia diferente do carro editado (`MODEL`, `VEHICLE`). | Escolha, troca ou salvamento da criação é interrompido. | `server.lua:236,253,282,284,297`. |
| EXP-19 | C | Clone da apresentação não nasce, ped não entra no banco, groundZ inválido (`CHARACTER`, `DRIVER`, `GROUND`). | Editor de veículo/apresentação externa não abre ou é encerrado. | `presentation.lua:73–100`. |
| EXP-20 | C | Prévia neon sem sessão, layout inválido ou bone inexistente (`SESSION`, `NEON`). | Prévia do neon recusada para aquela sessão/lado. | `presentation.lua:111–118`. |
| EXP-21 | C | Colisão no ponto físico de saída não confirma (`COLLISION`). | Jogar retorna erro e tenta reconstruir oficina; essa exigência ainda existe. | `client.lua:387`; `server.lua:344`. |
| EXP-22 | C | Motorista/veículo de saída não coincide, carro substituído, bucket errado ou carro a 12 m ou mais do ponto. | Saída é cancelada e o carro de gameplay pode ser removido no rollback. | `server.lua:347,351–362`. |
| EXP-23 | H | Conferência do banco do motorista é imediata após retorno do spawn. | Atraso de replicação pode ser interpretado como motorista ausente/incorreto. Não foi reproduzido nesta auditoria. | `server.lua:345–347`; `vehicles/server.lua`, `spawn`. |
| EXP-24 | C/H | Reconstrução da oficina no rollback de `play` usa `pcall` e ignora falhas de cena/prévia/recoverUI. | A falha original retorna mesmo quando parte da recuperação também falhou; estado visual incompleto é possível. | `server.lua:355–362`. |
| EXP-25 | C | Reiniciar menu/vehicles durante lobby/oficina dispara `uiStopped`; reiniciar experience também desconecta sessões privadas. | Jogador é expulso para reconectar. | `client.lua:611`; `server.lua:374–377`. |
| EXP-26 | C | Editor administrativo de câmera expira, cena muda ou pose/FOV ultrapassa limites. | Edição/atualização da câmera recusada; grant de edição tem prazo e renovação. | `camera-developer.lua:32–63`. |
| EXP-27 | R | Solo/colisão da apresentação não confirmava. | No código atual usa posição congelada; deixou de impedir acesso à garagem. | `client.lua`, `placeCharacter`; alteração anterior desta conversa. |
| EXP-28 | R | Cenário do lobby não carregava e botão Garagem era bloqueado por erro. | No código atual streaming do lobby pode falhar sem cancelar acesso; botão permanece habilitado. | `scene-streaming.lua`; `development/ui/src/Lobby.tsx`. |
| EXP-29 | R | `ENGINE_START` e ocupação do ponto de saída da garagem. | Exigência de motor ligado foi removida; a saída usa ghost em vez de disputa de vaga. Não confundir com SLOTS de outros fluxos. | `server.lua:349`; `vehicles/client.lua`, `depart`; `world/server.lua:21–25`. |

## 4. `mx-freeroam-vehicles` — catálogo, carros salvos, spawn, personalização e serviços

Diretório: `resources/[mx]/mx-freeroam-vehicles/`.

| ID | Evidência | Condição/erro | Efeito para o jogador | Referência |
|---|---|---|---|---|
| VEH-01 | C | Recurso do modelo parado, identidade de modelo em conflito, metadata ausente/ilegível ou índice de catálogo sem modelos. | Carros somem do Showroom, ficam indisponíveis ou não podem ser criados. Índice anterior pode permanecer após falha de reload. | `catalog.js`, `collect`, `discoverNative`, `reload`; `catalog.lua`. |
| VEH-02 | C | Modelo inválido/desconhecido ou sem carregar em até 30 s (`ASSET`, `MODEL`). | Prévia/spawn/troca recusados; seleção mais recente pode cancelar a carga anterior. | `asset-loader.lua`; `config.lua`; `server.lua:35,48`; `garage.lua:100,121`. |
| VEH-03 | C | Spawn novo antes do cooldown de 5 s. | Troca livre, recriação ou saída rápida pela garagem pode retornar `COOLDOWN`. | `server.lua:37,106`; `config.lua`. |
| VEH-04 | C | Edição ainda aberta (`EDIT`, `DRAFT`); jogador em carro de outro dono ou sem dirigir o próprio. | Spawn/entrada na oficina/serviços recusados. | `server.lua:38–42,82–85`; `services-server.lua`. |
| VEH-05 | C | Passageiros no carro que seria removido/substituído ou entrada de ocupante durante transferência (`PASSENGER`). | Troca, limpeza/remoção e entrada em oficina podem parar. | `server.lua:40,64,86–88,115`; `respawn-client.lua:36–51`. |
| VEH-06 | C | Nenhum destino aprovado com vaga a menos de 150 m (`SLOTS`). | Spawn livre não cria o carro, mesmo com modelo disponível. A saída especial da garagem não usa essa busca. | `server.lua:44`; `world/server.lua:27–32`. |
| VEH-07 | C | Criação nativa retorna entidade 0 (`SPAWN`) ou aplicação não retorna `applied=true` (`APPLY`). | Veículo recém-criado é descartado e operação retorna erro. | `server.lua:51,62–75`. |
| VEH-08 | C | Veículo não chega ao escopo/identidade local em 8 s (`VEHICLE_SYNC`), controle de rede não é adquirido (`OWNER`) ou identidade muda (`OBSOLETE`). | Aplicar, inspecionar, partir e diversos serviços param. | `client.lua:42–52`; `network.lua`. |
| VEH-09 | C | Prévia anterior ainda existe ou cliente não confirma remoção (`PREVIEW_DELETE`). | Nova prévia, troca de cena ou saída que pede remoção com ACK pode ser recusada. | `garage.lua:49–76`. |
| VEH-10 | C | Prévia está ocupada, cancelada, com intenção substituída ou contexto expirado (`BUSY`, `OBSOLETE`, `SESSION`). | Seleção anterior não conclui; a interface pode apresentar erro quando o resultado tardio chega. | `preview-state.lua`; `garage.lua:92–137,154–160`. |
| VEH-11 | C | ID salvo não encontrado/não pertencente ao jogador, revisão mudou, schema/modelo indisponível ou nome/ID inválido. | Carregar, renomear, duplicar, excluir ou salvar criação é recusado. | `garage.lua:22–24,201–218`; `properties.lua`. |
| VEH-12 | C | Limite de 30 criações atingido (`LIMIT`). | Não permite adicionar/duplicar mais carros salvos. | `config.lua`; `garage.lua:205`. |
| VEH-13 | C | Peça não confirma o valor lido, inclusive após aplicação (`APPLY`). | Um item cosmético pode abortar a aplicação global e, por consequência, o spawn. | `client.lua:81–85`. |
| VEH-14 | C | Leitura de extra retorna tipo inesperado, extra habilitado não existe, livery/placa/subwoofer/hidráulica não suportados. | Aplicação/edição retorna `EXTRA_NATIVE`, `EXTRA`, `LIVERY`, `PLATE`, `MOD` ou `TYRES`. | `customization.lua:9,99–104,189`. |
| VEH-15 | C | Família/índice de roda recusado; até a restauração original não confirma (`WHEELS`). | Aplicação aborta. Quando o fallback confirma, apenas informa aviso e mantém carro utilizável. | `customization.lua`, `installWheels`; `client.lua`, avisos de rodas. |
| VEH-16 | C | RGB/índice da pintura lido não corresponde ao solicitado (`APPLY`). | Personalização ou spawn recusado por confirmação de pintura. | `customization.lua:163–178`; `client.lua:80`. |
| VEH-17 | C | Geometria/dimensão de roda não confirma restauração (`STANCE_RESTORE`). | Ajuste ou reversão de stance pode retornar erro; alguns campos também ficam individualmente indisponíveis. | `stance.lua:132–168`; `stance-rules.lua`. |
| VEH-18 | C | Modelo não tem quatro rodas, transmissão original ainda não inicializou, campo de handling não exposto ou readback diverge. | Ativar drift pode falhar ou retornar fallback com handling original/incerto; não implica necessariamente cancelamento do carro. | `drift-client.lua:35–48,82–87,124–143,180–181`. |
| VEH-19 | C | Restauração do handling não confirma ou persistência do toggle drift falha. | Drift pode ser desativado/revertido, preferência não salva e estado marcado como incerto; manual e competição podem ficar indisponíveis. | `drift-client.lua:98–110,143`; `services-server.lua:105–130`. |
| VEH-20 | C | Carro ativo ausente, outra dimensão, mais de 60 m, personagem morto/privado, noclip ativo ou personalização aberta. | O conjunto de opções de veículo é desabilitado, incluindo serviços simples. | `services-server.lua:25–50`. |
| VEH-21 | C | Veículo ainda não está no cliente ao consultar opções. | Todas as ações ficam indisponíveis com mensagem para aguardar carregamento. | `services-server.lua:53–66`. |
| VEH-22 | C | Sem motorista para parar/drift/setas; carro em movimento para desvirar; passageiros para recriar/desvirar. | Ação correspondente recusada. | `services-server.lua:23–24,44–48`; `client.lua`, `service`. |
| VEH-23 | C | Passageiro não confirma desembarque ou servidor ainda o vê no carro (`EJECT`). | Expulsar passageiros retorna erro, mesmo após enviar o pedido. | `services-server.lua:92–102`. |
| VEH-24 | C | Setas não confirmam estado inteiro 0–3 (`ACK`). | Pedido de seta/pisca-alerta retorna erro e não publica confirmação. | `services-server.lua:133–137`. |
| VEH-25 | C | Recriação pendente, desembarque demora 2,5 s, ocupante aparece ou ped/carro muda (`BUSY`, `EXIT_TIMEOUT`, `OBSOLETE`). | Troca/recriação não prossegue; há tentativa de restaurar o carro anterior e watchdog de 10 s. | `respawn-client.lua`; `server.lua`, `respawn`. |
| VEH-26 | C | Substituição/recriação falha depois de remover o veículo anterior (`RESPAWN`). | O carro anterior já não existe e não há recriação automática de recuperação nesse ramo. A mensagem informa que as configurações salvas foram preservadas e remete à garagem. | `server.lua`, `respawn`, chamada `pcall(spawn)` após remoção. |
| VEH-27 | C | Falha de load/aplicação ou timeout das cópias locais da exposição. | Vagas podem ficar vazias ou sem atualização visual; retries são limitados. Não é, por si só, bloqueio de Jogar. | `display-client.lua`; controlador de display em experience. |
| VEH-28 | C | Ghost mantém proteção enquanto houver outro carro/pessoa do mesmo bucket a menos de 8 m. | Carro pode continuar sem colisão com veículos/peds mesmo sem interseção exata das malhas. Não há prazo máximo enquanto a área estiver ocupada. | `departure-ghost-server.lua`; `departure-ghost-client.lua`; `config.lua:2`. |
| VEH-29 | C | Serviços de veículo invalidam atividade antes de executar a ação, com exceção de setas/pisca-alerta. | Reparar, limpar, trancar e outras ações podem encerrar uma tentativa em andamento. | `services-server.lua:88`; `activities/server.lua`, `Invalidate`. |

## 5. `mx-freeroam-world` — destinos, viagens, noclip, checkpoints e ambiente

Diretório: `resources/[mx]/mx-freeroam-world/`.

| ID | Evidência | Condição/erro | Efeito para o jogador | Referência |
|---|---|---|---|---|
| WORLD-01 | C | Destino não validado e rascunhos desabilitados, ou asset não iniciado (`DESTINATION`). | Viagem não começa; destino pode aparecer indisponível. | `server.lua:2–5`; `tracks-config.lua`; `config/production.cfg`. |
| WORLD-02 | C/L | Vagas/reservas próximas, veículo a menos de 5 m ou outro jogador a menos de 3 m (`SLOTS`). | Viagens, retorno ao checkpoint e spawns comuns podem ser recusados por ocupação. Existe ocorrência histórica SLOTS no log. | `server.lua:3–18`; log:1197. |
| WORLD-03 | C | Jogador na oficina, sem sessão, passageiro em viagem a pé ou carro com outro motorista/ocupantes. | Teleporte/recuperação/trainer recusado. | `server.lua:38–47`; `trainer-server.lua:7–17`; `vehicles`, `OwnedDriver`. |
| WORLD-04 | C | Cliente não confirma chegada ou servidor não vê entidade/posição/epoch esperado. | Viagem é revertida para ponto anterior, quando ainda há identidade válida. | `server.lua:51–64`; `client.lua:58–78`. |
| WORLD-05 | C | Spawn básico já concluído e personagem vivo (`RESPAWN`), entrada pendente (`BUSY`), chave inválida ou distância de 15 m ou mais. | Comando de respawn básico/ACK de entrada recusado. | `server.lua:77–87`. |
| WORLD-06 | C | Modelo do personagem ou colisão do spawn básico não carrega. | Spawn sem experience falha; há mensagem de falha de spawn seguro. | `client.lua:19,38–48`. |
| WORLD-07 | C | Encerramento do noclip sem `stopped=true` (`TRAINER`). | Operações que chamam StopTrainer, como entrar na garagem ou viajar, não prosseguem; autorização pode continuar pendente. | `trainer-server.lua:21–27,50–58`. |
| WORLD-08 | C | Carro muda durante noclip; entidade fora do escopo; outro ocupante entra; controle de rede é perdido. | Noclip não ativa, retorna erro ou é encerrado automaticamente. | `trainer-server.lua:48`; `trainer-client.lua:49–77`. |
| WORLD-09 | C | Noclip ligado ao criar checkpoint (`NOCLIP`), posição fora dos limites ou checkpoint inexistente/epoch antigo (`CHECKPOINT`). | Criar/retornar ao checkpoint recusado. | `trainer-server.lua:64–78`. |
| WORLD-10 | C | Morte, outro bucket, sessão privada ou configuração de velocidade/modo inválida. | Ferramentas de trainer não ficam disponíveis. | `trainer-server.lua:7–10,40–46`. |
| WORLD-11 | C | JSON de teleportes salvo inválido (`STORAGE`) ou gravação/leitura não confirma (`DISK`). | Pontos personalizados não são carregados e criação de novo ponto pode ser bloqueada. | `teleports.lua:8–20,32`. |
| WORLD-12 | C | Destino capturado/administrativo com coordenadas inválidas, outra dimensão ou sessão mudou. | Criação do ponto/teleporte administrativo recusado. | `teleports.lua:23–29`; `admin-travel.lua`. |
| WORLD-13 | C | Preferência de clima/horário sem identidade, origem incorreta, valores inválidos ou KVP não confirma. | Mudança de ambiente pessoal não é aplicada/salva. | `environment.lua:39–51`. |
| WORLD-14 | C | Configuração do relógio/transições/clima inválida. | Inicialização do ambiente dinâmico pode parar por `ENVIRONMENT`. | `environment-server.lua:6–21`. |
| WORLD-15 | C | Atividade é invalidada ao viajar, recuperar ou ativar noclip. | Tentativa em andamento é encerrada, inclusive quando uma etapa posterior da ação solicitada falha. | `server.lua:48`; `trainer-server.lua:49`. |
| WORLD-16 | C | Bloqueios globais de armas, dano, explosões e dispatch; wanted/HUD/radar também são controlados pelo mundo/menu. | Entradas e comportamentos nativos podem não produzir o resultado esperado. São regras explícitas do freeroam, não prova de erro. | `server.lua`, eventos de dano; `client.lua`, loop do mundo. |

## 6. `mx-freeroam-menu` e NUI React — menus, loading, inputs e configurações

Fontes: `resources/[mx]/mx-freeroam-menu/` e `development/ui/src/`. Linhas TSX do bundle servido correspondem ao código-fonte inventariado; não houve rebuild nesta tarefa.

| ID | Evidência | Condição/erro | Efeito para o jogador | Referência |
|---|---|---|---|---|
| UI-01 | C | NUI sem `GetParentResourceName`, fetch falha, JSON inválido, resposta `ok=false` ou prazo de 245 s. | Ação de interface retorna erro; conforme a tela, mantém ocupado até concluir a espera. | `api.ts:3–6`. |
| UI-02 | C/H | Todas as chamadas `api()` passam por uma fila global `requestTail`. | Uma operação lenta segura chamadas posteriores de outros módulos da mesma interface. O efeito é inferido da serialização explícita. | `api.ts:8–31`. |
| UI-03 | C | Loading/cortina ativa ignora teclado, cliques, scroll, navegação e retorno. | Tela fica intencionalmente sem interação enquanto aguarda os eventos de conclusão. | `screen-transition.ts`; `input-boundary.ts`. |
| UI-04 | H | Mensagem `loadingClosed`, fim do fade ou `loadingStatus=false` não chega. | Cortina/loading pode permanecer bloqueando a interface; esse controlador não tem prazo próprio de recuperação. | `screen-transition.ts`, `waitingForLoading`, `hidden`, `sync`. |
| UI-05 | C | Callbacks exigem contexto de menu/lobby/oficina específico (`SESSION`, `LOBBY`). | Abrir garagem, usar ambiente pessoal, câmera ou som pode ser recusado após mudança de tela. | `menu/client.lua:126–193,250–347`. |
| UI-06 | C | Navegação e botões ficam bloqueados durante busy, lock, diálogo, captura ou operação de prévia. | Retorno e novas ações podem ficar indisponíveis durante a operação atual; alguns handlers simplesmente retornam. | `Workshop.tsx`; `SessionMenu.tsx`; `PauseMenu.tsx`; `VehicleEditor.tsx`. |
| UI-07 | C | Resultado de gravação da oficina é incerto. | Novas gravações e certos descartes são bloqueados até repetir a operação ou recarregar estado. | `Workshop.tsx:54–55,117`. |
| UI-08 | C | Falha de prévia, câmera ou barreira de edição. | Troca de tela, salvamento ou descarte podem retornar erro; erro de roupa prévia tem tratamento específico que ainda permite descarte. | `Workshop.tsx`, `run`, `discard`; `VehicleEditor.tsx`, filas. |
| UI-09 | C | Modelo/família de rodas sem peças, extras dependentes, stance incompatível ou campos indisponíveis. | Opções são desabilitadas ou seleção retorna mensagem de incompatibilidade. | `VehicleEditor.tsx:80,168`; `StancePanel.tsx`; `customization.lua`. |
| UI-10 | C | Carregamento inicial das configurações falha em perfil, drivecam ou preferências locais. | Tela pode ficar sem perfil/controles de configuração, exibindo erro. | `Preferences.tsx`, `useEffect` inicial. |
| UI-11 | C | Preferências pendentes só são aplicadas pela ação contextual; conflito/erro de save mantém alteração pendente. | Alterações não persistem até confirmação bem-sucedida. | `Preferences.tsx`, `apply.current`; `core/server.lua`, `preferences`. |
| UI-12 | C | Atalho reservado, não suportado, já usado ou KVP não confirmado (`BIND`, `BIND_CONFLICT`, `DISK`). | Remapeamento/migração recusado. Captura também pode expirar/cancelar. | `menu/bindings.lua:40–47,103`; `binding-capture.lua`; `ServerBindings.tsx`. |
| UI-13 | C | Atalhos de gameplay suspensos por NUI, pausa, lobby/oficina, morte ou operação anterior; motor no controle exige segurar. | Tecla/botão pode não executar sem mensagem de erro. | `menu/client.lua:77–91,210–235`; `bindings.lua`. |
| UI-14 | H | Teclado nativo permanece com `UpdateOnscreenKeyboard()==0`. | Loop continua aguardando e mantém modo de teclado/foco suspenso; não há deadline próprio nesse callback. | `menu/client.lua:264–279`. |
| UI-15 | C | Presença expirada/localização não compartilhada (`POSITION`). | Criar rota até outro jogador é recusado. | `menu/client.lua`, callback `route`. |
| UI-16 | C | Refresh de opções do veículo falha. | Menu substitui disponibilidade por conjunto vazio e exibe erro; opções ficam sem ação até nova leitura válida. | `SessionMenu.tsx:104–108`. |
| UI-17 | C/H | Exceção React não capturada durante renderização. | Montagem da interface pode falhar; a raiz observada não instala ErrorBoundary. Não houve crash de render reproduzido nesta sessão. | `main.tsx`; tratamento local nas telas. |
| UI-18 | C | Rádio/roda de armas e controles conflitantes são bloqueados no veículo; menus e modais consomem outros controls. | Entradas nativas ficam sem efeito conforme contexto. | `vehicle-input.lua`; `menu/client.lua`; `navigation.lua`. |
| UI-19 | C | Preferências de HUD, minimapa e foto, ausência de carro ou contexto de oficina/lobby. | Velocímetro/radar podem desaparecer por configuração/contexto, sem ser falha de telemetria. | `hud.lua`; `main.tsx`; loop HUD em `menu/client.lua`. |
| UI-20 | C | Consulta ao gearbox falha. | HUD usa dados nativos de marcha/RPM, que podem diferir da apresentação manual esperada. Não bloqueia a condução. | `hud.lua:18–21`. |

## 7. `mx-freeroam-activities` — treinos, contra-relógio, duelo e resultados

Diretório: `resources/[mx]/mx-freeroam-activities/`.

| ID | Evidência | Condição/erro | Efeito para o jogador | Referência |
|---|---|---|---|---|
| ACT-01 | C | Inicialização de pistas falha por banco, definição/revisão divergente ou configuração inválida. | `ready` permanece falso; pistas ficam indisponíveis. | `server.lua`, thread de inicialização; `rules.lua`. |
| ACT-02 | C | Pista não existe, asset parado ou rascunho fora dos modos/permissões aceitos (`TRACK`, `DRAFT`, `MODE`). | Atividade e ranking não abrem/iniciam. | `server.lua`, `track`, rotas `start`/`ranking`. |
| ACT-03 | C | Noclip, edição ou sessão ativa; sem dirigir carro próprio/vazio; drift ou handling incerto em modo competitivo. | Preparação da atividade é recusada. | `server.lua`, `candidate`. |
| ACT-04 | C | Veículo fora do raio de início ou velocidade de 2 m/s ou mais (`START`). | Atividade não começa. | `server.lua`, `candidate`; `config.lua`. |
| ACT-05 | C | Cliente não confirma veículo/preparação, jogador sai do início ou sessão muda durante contagem. | Tentativa vira inválida (`preparation_failed`, `early_start_or_departure`). Veículo pode ficar congelado durante preparação; há soltura local de 12 s. | `server.lua`, `prepare`; `client.lua:5–12`. |
| ACT-06 | C | Duelo com carro/preparação diferente, outro mundo ou regras alteradas (`CATEGORY`, `RULES`). | Convite/início de duelo é recusado. | `server.lua`, `describe`, `StartDuel`; `rules.lua`, `comparable`. |
| ACT-07 | C | Morte, troca de carro/configuração/motorista/bucket/condições ou identidade. | Tentativa ativa é invalidada, sem tempo elegível. | `server.lua`, loop de amostragem. |
| ACT-08 | C | Ping acima de 500 ms, gap acima de 1,5 s ou observação da configuração atrasada por mais de 4 s. | Tentativa é invalidada por `insufficient_sync`. | `server.lua`, loop de amostragem; `config.lua`. |
| ACT-09 | C | Velocidade inferida acima de 120 m/s, checkpoint fora de ordem ou mais de 10 min. | Tentativa é invalidada (`position_jump`, `checkpoint_out_of_order`, `timeout`). | `server.lua`, loop; `config.lua`. |
| ACT-10 | C | Um participante desiste/falha em duelo. | Tentativa do outro pode ser invalidada com razão `duel_peer_*`; sem vencedor por tempo. | `server.lua`, `finish`, `duelSummary`. |
| ACT-11 | C | Banco indisponível no final. | Resultado fica pendente no spool local e prêmio não é confirmado. | `server.lua`, `finish`, `persist`. |
| ACT-12 | C | Banco e diário local falham, ou spool salvo é inválido. | Resultado pode ficar sem confirmação durável; spool corrompido gera aviso de intervenção. | `server.lua:4–6`; `finish`. |
| ACT-13 | C | Treino/prática/drift sem elegibilidade competitiva; resultado revogado ou incompatível com filtro de carro/condições/regras. | Tempo não aparece no ranking competitivo e pode não gerar recompensa. | `server.lua`, construção de `eligible`, rota `ranking`; `progression/rules.lua`. |
| ACT-14 | C | Sem carro ativo para ranking ou página/modo inválido. | Consulta ao ranking é recusada. | `server.lua`, rota `ranking`. |
| ACT-15 | H | `newSession` ocorre antes da consulta SQL do melhor tempo; essa consulta não está no cleanup de `prepare`. | Se essa consulta falhar, a sessão pode permanecer criada/preparing e recusar outro início até ser encerrada. Não reproduzido nesta tarefa. | `server.lua`, rota `start`. |
| ACT-16 | C | Telemetria/configuração com sessão inválida, intervalo insuficiente ou campos fora do intervalo. | Amostra é recusada; divergência de assinatura invalida tentativa. | `server.lua`, rotas `telemetry`, `configuration`. |

## 8. `mx-freeroam-social` — presença, grupos, convites, amizade e chat

Diretório: `resources/[mx]/mx-freeroam-social/`.

| ID | Evidência | Condição/erro | Efeito para o jogador | Referência |
|---|---|---|---|---|
| SOC-01 | C | Outro bucket, compartilhamento desativado, filtro de marcadores ou presença expirada. | Jogador/posição/rota/marcador pode não aparecer; marcador é removido após expiração. | `rules.lua`; `server.lua`, `players`; `client.lua`, expiry. |
| SOC-02 | C | Destinatário não aceita convites, não existe ou está em outro contexto (`CONTACT`). | Convite de grupo/duelo recusado. | `server.lua`, `invite`; `rules.lua`, `canInvite`. |
| SOC-03 | C | Cooldown de convite, grupo cheio, remetente não líder ou destinatário já agrupado. | Não permite convidar/entrar no grupo. | `server.lua`, `invite`/`respond`; `config.lua`. |
| SOC-04 | C | Convite expirou, epoch mudou ou condições mudaram desde envio. | Aceitar convite retorna erro; o convite é removido antes de concluir algumas verificações. | `server.lua`, `respond`. |
| SOC-05 | C | Atividades indisponíveis ou elegibilidade/regras do duelo não confirmadas. | Convite/aceite de duelo falha. | `server.lua`, chamadas `DescribeDuel`/`StartDuel`. |
| SOC-06 | C | Amizade já aceita, solicitação na direção contrária, jogador offline ou convites bloqueados. | Nova solicitação é recusada ou retorna a existente. | `friends.lua`, `send`. |
| SOC-07 | C | Limite de 100 amizades/solicitações de qualquer uma das partes. | Não permite enviar outra solicitação. | `friends.lua`, consultas COUNT. |
| SOC-08 | C | Solicitação recebida não encontrada, alvo inválido ou registro mudou (`FRIEND`, `CONFLICT`). | Aceitar/recusar amizade falha. | `friends.lua`, `pair`/`respond`. |
| SOC-09 | C | Mensagem vazia/inválida/acima de 250 caracteres ou rate limit. | Chat não envia. | `server.lua`, rota `chat`. |
| SOC-10 | C | Jogador silenciado localmente, remetente fora do bucket ou reset do social. | Chat/voz/marcadores podem desaparecer por estado local/regras, não por falha no envio original. | `client.lua`, `muted`; `server.lua`, `chat`; `menu/client.lua`, `mute`. |
| SOC-11 | C | Banco de amizades falha; progresso público falha. | Lista de amizades pode retornar erro; para progresso público há fallback para nível/ícone padrão. | `friends.lua`; `server.lua`, `progression`. |
| SOC-12 | C | Grupos/convites existem somente em memória; saída/restart remove estado. | Grupo e convites não sobrevivem à desconexão/reinício do resource. | `server.lua`, tabelas iniciais e eventos de saída/stop. |

## 9. `mx-freeroam-progression` — XP, conquistas, títulos e desafios

Diretório: `resources/[mx]/mx-freeroam-progression/`.

| ID | Evidência | Condição/erro | Efeito para o jogador | Referência |
|---|---|---|---|---|
| PROG-01 | C | Banco/configuração de níveis/ícones/desafios inválida ou definição de desafio alterada sem revisão compatível. | Loop periódico de progressão não inicia; log informa processamento fechado. | `server.lua`, thread final. |
| PROG-02 | C | Atividades indisponíveis ou processamento já em andamento. | Worker retorna sem processar naquela chamada. | `server.lua`, `drain`. |
| PROG-03 | C | Consulta/transação/ACK da entrega falha (`PENDING_RETRY`). | XP/conquista pode chegar depois; entrega não é confirmada naquela passagem. | `server.lua`, `drain`/`process`. |
| PROG-04 | C | Resultado não elegível, revogado, regra/revisão incompatível ou desafio fora da janela UTC. | Não concede prêmio competitivo/desafio, ou compensa XP anteriormente concedido. | `rules.lua`; `server.lua`, `process`. |
| PROG-05 | C | Ícone/título fora do catálogo ou ainda bloqueado (`ICON`, `TITLE`, `COSMETIC`, `LOCKED`). | Não permite equipar cosmético de progressão. | `server.lua:44–53`, rota `cosmetics`. |
| PROG-06 | C | Consulta de resumo/histórico/conquistas falha. | Tela de perfil/progressão não carrega ou retorna erro; presença social pode cair no padrão. | `server.lua`, `summary`/`profile`; `social/server.lua`. |

## 10. `mx-freeroam-admin` — acesso, moderação, ferramentas e conteúdo

Diretório: `resources/[mx]/mx-freeroam-admin/`. Ações administrativas podem afetar usuários comuns; restrições de uso das ferramentas também estão incluídas.

| ID | Evidência | Condição/erro | Efeito para o jogador | Referência |
|---|---|---|---|---|
| ADM-01 | C | Arquivo de bans inválido ou impossível de interpretar (`STORAGE`). | `CheckConnection` falha e pode recusar entrada de todos os jogadores, não só de banidos. | `moderation.lua:4–28`; `core/server.lua:105–108`. |
| ADM-02 | C | Banimento existente ou ação kick/ban aplicada. | Entrada recusada ou conexão encerrada com motivo. | `moderation.lua`, `CheckConnection`, `apply`. |
| ADM-03 | C | ACE ausente, sessão administrativa mudou, alvo é admin protegido, identidade indisponível ou jogador saiu. | Ferramenta/moderação retorna `FORBIDDEN`, `SESSION`, `PLAYER` ou `IDENTITY`. | `moderation.lua`; `server.lua`, `authorize`. |
| ADM-04 | C | Auditoria SQL ou gravação/leitura de bans falha. | Ação administrativa pode ser recusada antes da mutação; falha de registro posterior também pode retornar erro. | `server.lua`, `audit`, `revoke`; `moderation.lua`, `persist`. |
| ADM-05 | C | Limpeza administrativa invalida atividades e apaga carros sem passageiros. | Tentativa e carro de outros jogadores podem desaparecer por uma ação autorizada de administração. | `server.lua`, `cleanup`; `vehicles/server.lua`, `Cleanup`. |
| ADM-06 | C | Teleporte/ferramenta no modo privado, morto ou fora do mundo público. | Captura/teleporte/overlay não abre ou para. | `tools-server.lua`, `check`; `world/admin-travel.lua`. |
| ADM-07 | C | Sem waypoint, loader não inicia ou solo não é encontrado em 8 s (`WAYPOINT`, `STREAM`, `GROUND`). | Teleporte administrativo por marcador não acontece. | `tools-client.lua`, `waypoint`. |
| ADM-08 | C | Alvo de captura veículo inexistente, ACK de painel não confirmado ou grant expira após 6 s sem renovação. | Painel não abre ou some; captura retorna erro. | `tools-client.lua`; `tools-server.lua`. |
| ADM-09 | C | Rascunho ausente/incompleto, export não grava, revisão conflitante, confirmação de ativação ausente. | Pista/destino não é publicado; rascunho permanece fora da experiência pública. | `server.lua`, comandos `mxtrack`/`mxdestination`; `activities/server.lua`, `Publish`. |
| ADM-10 | C | Resultado inexistente/revogação inválida ou módulo requerido parado. | Inspeção, revogação, anúncio e ações de conteúdo retornam erro. | `server.lua`, `requireModule`, `revoke`, `announce`; `activities/server.lua`, `Revoke`. |

## 11. `mx-freeroam-drivecam` — câmera de condução

Diretório: `resources/[mx]/mx-freeroam-drivecam/`.

| ID | Evidência | Condição/erro | Efeito para o jogador | Referência |
|---|---|---|---|---|
| CAM-01 | C | Preferência desligada, experience parado, câmera suspensa, pausa/NUI, espectador ou morte. | Câmera personalizada não ativa ou devolve a câmera nativa, sem erro obrigatório. | `client.lua:32–35`. |
| CAM-02 | C | Jogador passageiro, sem veículo ou modelo não reconhecido como carro. | Drivecam não funciona nesse veículo/contexto. | `client.lua:34–35`. |
| CAM-03 | C | Troca de veículo, salto de posição, frame acima de 0,25 s ou token de câmera perdido. | Rig/câmera reinicia; pode haver mudança visível de enquadramento. | `client.lua:78–81`. |
| CAM-04 | C | Consulta de colisão pendente/bloqueada, distância segura insuficiente ou aquisição da view recusada. | Câmera encurta, usa fallback ou não ativa enquanto não houver condição válida. | `client.lua`, loop de shape test e `fallbackUntil`; `experience/camera.lua`. |
| CAM-05 | C | KVP inválido ignora preferência; persistência não tem conferência de readback neste módulo. | Preferência pode iniciar desligada ou não sobreviver ao reinício se o armazenamento falhar. | `client.lua:3–4,20–22`. |

## 12. `mx-gearbox` — câmbio e comandos de marcha

Diretório: `resources/[mx-scripts]/mx-gearbox/`.

| ID | Evidência | Condição/erro | Efeito para o jogador | Referência |
|---|---|---|---|---|
| GEAR-01 | C | Drift aplicado ou restauração de handling incerta. | Manual/trocas/embreagem/upgrades são suspensos; preferência permanece salva. | `client/main.lua`, `driftBlocked` e exports. |
| GEAR-02 | C | NUI ou pausa focada; jogador não é motorista; transmissão inativa. | Comandos de troca/embreagem retornam sem executar. | `client/main.lua:59–77`; `client/gearbox.lua:189`. |
| GEAR-03 | C | Comando `/gear` não consegue carregar/salvar perfil, conflito de revisão ou resposta de erro. | Modo solicitado não é aplicado por esse caminho; informa falha de salvamento. | `client/main.lua`, comando `gear`. |
| GEAR-04 | C | Perfil não chega na inicialização ou pedido de perfil falha. | Preferência persistida pode não ser aplicada naquele início até outro evento de perfil. | `client/main.lua:35–45`. |
| GEAR-05 | C | Marcha fora do intervalo, alvo inválido, veículo inativo ou upgrade desconhecido. | Export/solicitação retorna `false` (`invalid_gear`, `inactive`, `drift`) ou não aplica upgrade. | `client/gearbox.lua:187–190,363`; exports em `main.lua`. |
| GEAR-06 | C | Configuração de controles desligada ou dispositivo/contexto não corresponde. | Botões de troca do controle não são lidos; teclado segue caminho próprio. | `client/main.lua`, `controller`. |

## 13. `mx-soundcore` — música, busca, fila e áudio espacial

Diretório: `resources/[mx-scripts]/mx-soundcore/`; integração no callback `vehicleSound` do menu.

| ID | Evidência | Condição/erro | Efeito para o jogador | Referência |
|---|---|---|---|---|
| SOUND-01 | C | Resource parado, jogador fora do menu livre, sem carro de rede ou carro mudou durante texto. | Menu recusa enviar comando de som. | `menu/client.lua`, callback `vehicleSound`. |
| SOUND-02 | C | Usuário não ocupa o carro, não é dono/ocupante autorizado ou ACE não permite. | Tocar/controlar som é negado. Com configuração atual, ocupantes podem tocar/controlar. | `server/permissions.lua:127–181`; `config.lua`. |
| SOUND-03 | C | Trocas de música antes de 3 s, penalidade progressiva ou resolução anterior ainda ativa. | Novo pedido é recusado/adiado com aviso de espera. | `server/permissions.lua`, `CheckRateLimit`, `CheckResolveLock`; `config.lua`. |
| SOUND-04 | C | Limite de fila por carro/jogador ou limite global de resolves concorrentes. | Música/fila recusada como cheia ou servidor ocupado. | `server/permissions.lua`; `server/state.lua:347`; `server/stream_resolver.lua:289,347`. |
| SOUND-05 | C | URL/nome vazio, longo, caracteres inválidos, domínio/protocolo/plataforma não aceitos. | Música não inicia; pesquisa retorna erro. | `server/permissions.lua`, `ValidateUrl`; `server/stream_resolver.lua`. |
| SOUND-06 | C | Live bloqueada ou duração acima de 1.200 s. | Música/pesquisa é recusada pela política atual. | `config.lua`, `Security`; `server/stream_resolver.lua:388–401`. |
| SOUND-07 | C/L | Execução de yt-dlp negada pelo runtime; executável/resolvedor indisponível, timeout ou subprocesso falha. | Busca/resolução não produz áudio. Houve SCRIPT ERROR histórico de permissão; configuração e tratamento foram alterados em etapa anterior, sem validação externa atual. | `server/stream_resolver.js`; `stream_resolver.lua`; `config/server.cfg`; log:1779,1794. |
| SOUND-08 | C | Busca sem resultado, conteúdo privado/excluído/indisponível ou retorno inválido do resolvedor. | Estado vira `not_found`/`error`; música não toca. | `server/main.lua:210–217`; `stream_resolver.lua`; `stream_resolver.js`. |
| SOUND-09 | C | Veículo some enquanto resolve, net ID inválido ou estado rejeita operação. | Pedido não é aplicado; pode aparecer `Vehicle no longer exists` ou erro de entidade. | `server/main.lua:49–59,223`; `server/state.lua`. |
| SOUND-10 | C | Não existe som ativo para pausar/retomar, fila vazia ou volume/seek inválido. | Comando de controle retorna erro ou não muda reprodução. | `server/state.lua`; `server/main.lua`, handlers de controle/seek. |
| SOUND-11 | C | `HTMLMediaElement.play()` rejeita, formato não suportado ou erro de mídia/rede. | Reprodução falha; cliente reporta `error`/`not_found`. O código tenta resolver de novo em parte dos erros. | `ui/js/audio_engine.js:225–277`. |
| SOUND-12 | C | AudioContext não inicia/retoma ou inicialização do motor de áudio falha. | Áudio fica sem reprodução, mesmo que exista pedido aceito no Lua. | `ui/js/main.js:75–94`; `ui/js/audio_engine.js`. |
| SOUND-13 | C | Distância fora da faixa, emissor fora dos oito priorizados, oclusão/interior/porta reduz ganho. | Som pode desaparecer, atrasar entrada ou ficar muito baixo sem erro de comando. | `config.lua`, `Distance`/`MaxEmitters`; `client/vehicle_scanner.lua`; `ui/js/mixer.js`. |
| SOUND-14 | C | Dono desconecta e `KeepSoundOnDisconnect=false`. | Reprodução é encerrada, mesmo com outros jogadores próximos. | `config.lua`; handlers de desconexão em `server/main.lua`. |
| SOUND-15 | C/H | Exports legados `IsPaused` e `GetPlaybackStatus` chamam `resolveVehicleEntity`, sem definição local correspondente encontrada nesse arquivo. | Chamadores desses exports podem receber erro Lua. A integração atual do menu evita esse caminho e lê state bags. | `client/api.lua`, `IsPaused`, `GetPlaybackStatus`; `menu/client.lua`. |
| SOUND-16 | C | Exports de comando confirmam envio do evento, não conclusão da reprodução. | Interface pode mostrar “pedido enviado” enquanto a busca/áudio falha depois; êxito do envio não comprova som tocando. | `client/api.lua`, `PlaySound`/`AddToQueue`; `SessionMenu.tsx`, som. |

## 14. `pma-voice` — voz por proximidade, mute e canais

Diretório: `resources/[vendor]/pma-voice/`; configuração em `config/voice.cfg`.

| ID | Evidência | Condição/erro | Efeito para o jogador | Referência |
|---|---|---|---|---|
| VOICE-01 | C | Mumble não conectado. | Thread de proximidade aguarda conexão; voz não fica pronta nesse período. | `client/init/proximity.lua:95`. |
| VOICE-02 | C | Estado de voz diferente de proximity/channel ou tipos de API inválidos. | Erro interrompe aquela chamada/configuração de voz. | `client/init/proximity.lua:127`; `shared.lua:90`; `client/init/main.lua:28`. |
| VOICE-03 | C | Mute administrativo/local ou override de volume/proximidade. | Jogador pode não ouvir/falar como esperado sem falha da conexão de jogo. | `server/mute.js`; `client/commands.lua`; `menu/client.lua`, `mute`. |
| VOICE-04 | C | Radios, telefones e UI da voz desabilitados na configuração atual. | Recursos/indicadores de rádio/telefone não estão disponíveis; proximidade usa caminho próprio. | `config/voice.cfg`. |
| VOICE-05 | C | KVP de voz inválido. | Preferências de voz são resetadas para padrão, com aviso no console. | `client/init/init.lua:16–23`. |
| VOICE-06 | C | `voice_externalDisallowJoin=1`, se configurado. | pma-voice recusa a conexão inteira. Não está habilitado no `voice.cfg` consultado. | `server/main.lua:116–122`. |
| VOICE-07 | C | API de rádio/telefone recebe tipo inválido ou recurso que fornece validação reinicia. | Chamada é rejeitada ou regras/callbacks voltam ao padrão. Rádio/telefone estão desligados no perfil atual. | `server/module/radio.lua`; `phone.lua`; `client/init/proximity.lua:152`. |

## 15. `oxmysql` — dependência de persistência

Diretório: `resources/[vendor]/oxmysql/`. O servidor principal é um bundle compilado; seus internals não foram apresentados como bugs reproduzidos.

| ID | Evidência | Condição/erro | Efeito para o jogador | Referência |
|---|---|---|---|---|
| DB-01 | C | Resource não inicia, runtime mínimo não atende ou biblioteca MySQL não fica pronta. | Módulos MX dependentes de dados não ficam operacionais e entrada pode ser fechada pelo core. | `fxmanifest.lua`; `lib/MySQL.lua`; `core/server.lua`. |
| DB-02 | C | Consulta ou transação falha, banco indisponível ou resultado não confirmado. | Perfil, garagem, amizades, progresso, atividades, preferências e auditoria podem retornar `DATABASE`. | Chamadas `MX.db`/`MX.tx`; wrappers do core. |
| DB-03 | C | Transação/revisão não afeta a linha esperada. | Escrita é recusada como conflito ou operação sem confirmação; jogador não recebe persistência confirmada. | `core/server.lua`, `preferences`; journals em experience/vehicles. |
| DB-04 | H | Consulta demora sem completar. | Core mantém o lock/operação aguardando até os limites externos correspondentes; outras operações podem ser recusadas ou enfileiradas. Não houve consulta real nesta tarefa. | `core/server.lua`, `query`, `ClientCall`, `Run`; NUI `api.ts`. |

## 16. Mapas, carros, rodas e áudio de motores — empacotamento e streaming

Cada recurso e todas as ocorrências extraídas do log aparecem individualmente no anexo/inventário. Os cenários abaixo agrupam os efeitos; ausência de mensagem Lua não significa que um asset carregou corretamente.

| ID | Evidência | Condição/erro | Efeito para o jogador | Referência |
|---|---|---|---|---|
| ASSET-01 | C/H | Remoção do mapa padrão em conjunto com pontos funcionais que dependem dele. | Localização configurada pode existir numericamente sem cenário/solo correspondente. Não foi confirmada a extensão espacial no jogo. | BASE-01; `resources/[maps]/LosSantosRemoved/`. |
| ASSET-02 | C | `ikebukuro_moved_release` declara `IkebukuroRoadYmap.ymap` e `IkebukuroRoadDecalYmap.ymap`, sem arquivo correspondente encontrado. | Referências de mapa sem conteúdo no pacote; efeito visual/colisão específico não foi reproduzido. | `resources/[maps]/ikebukuro_moved_release/__resource.lua`. |
| ASSET-03 | C | `Shuto_betsy` declara `Tokyo_night.ymap` e `DaikoExitNew.ymap`, sem arquivo correspondente encontrado. | Partes declaradas não estão disponíveis sob esses nomes. | `resources/[maps]/Shuto_betsy/__resource.lua`. |
| ASSET-04 | C | `SunCityTerrainRoad` declara `SunCityGrassAdd.ytyp.ymap` e `SunCityGrassAdd.ytyp.ytyp`, sem correspondência encontrada. | Referências de cenário/archetype ausentes no pacote. | `resources/[maps]/SunCityTerrainRoad/__resource.lua`. |
| ASSET-05 | C | `SunCityLights` usa `stream/*.ytyp`, mas esse glob não encontra arquivo no pacote. | Não há archetype para essa declaração. O recurso contém YMAPs; isso isoladamente não prova ausência das luzes. | `resources/[maps]/SunCityLights/fxmanifest.lua`. |
| ASSET-06 | C | `jettagli25` declara `data/vehiclelayouts.meta`, sem arquivo correspondente. | Layout adicional declarado não pode ser carregado por esse caminho; efeito no modelo não foi testado. | `resources/[vehicles]/jettagli25/fxmanifest.lua`. |
| ASSET-07 | L | 3.516 avisos históricos de memória física de assets, com repetições entre boots e modelos. | Pressão de streaming, demora e degradação são riscos associados; o log não comprova crash/FPS de um jogador. | Log, categoria `memoria-asset`; detalhes por arquivo no anexo. |
| ASSET-08 | L | Avisos de `client.lua` ausente em Irohazaka, nagao e tsubakline, cinco vezes cada. | Os scripts declarados não foram encontrados naqueles boots. Esses três recursos não constam do inventário atual; ocorrência histórica, sem atribuição ao pacote atual. | Log:486,513,573 e repetições. |
| ASSET-09 | C | Recurso existe/inicia, mas modelo/archetype/interior ainda não está registrado ou carregado no cliente. | Prévia/cena/spawn pode aguardar e depois falhar; `started` não garante prontidão visual/física. | `experience/scene-streaming.lua`; `vehicles/asset-loader.lua`; `vehicles/catalog.js`. |
| ASSET-10 | H | Mapas/veículos/rodas/áudios binários incompatíveis, layouts/handling/bones inadequados ou malhas sobrepostas. | Aparência, condução, som ou colisão podem divergir sem uma rejeição explícita. O inventário não interpreta binários e não confirmou esses defeitos em cada asset. | Conteúdo binário dos 80 recursos; verificações nativas em customization/drift/stance. |

## 17. `bob74_ipl` e `limits` — cenário nativo e limites do mundo

Diretório: `resources/[standalone]/`. Ambos são abrangidos pelo início da categoria.

| ID | Evidência | Condição/erro | Efeito para o jogador | Referência |
|---|---|---|---|---|
| IPL-01 | C | bob74_ipl solicita/ativa diversos interiores e IPLs padrão na inicialização. | Conteúdo visual depende desses pedidos; não há confirmação global ao usuário de que todos terminaram. | `bob74_ipl/client.lua`; funções de IPL. |
| IPL-02 | C | Render target, textura, scaleform ou headshot não fica pronto em 5 s. | Helpers retornam `false` ou `-1`; o conteúdo que depende deles pode não aparecer. Esses loops possuem timeout, não foram classificados como espera infinita. | `bob74_ipl/lib/common.lua:140–247`. |
| IPL-03 | H | IPLs padrão ativados junto de um pacote que remove o mapa base. | Combinação pode produzir cenário diferente do esperado; não há compatibilidade física confirmada nesta auditoria. | `bob74_ipl/client.lua`; `LosSantosRemoved/fxmanifest.lua`. |
| IPL-04 | C | limits expande limites do mundo a cada frame. | A expansão não fornece solo nem valida destinos; locais fora do mapa podem continuar sem superfície. Não foi encontrado erro explícito de rejeição nesse resource. | `limits/cl_bounds.lua`. |

## 18. Recursos instalados que não fazem parte do início atual

| ID | Evidência | Recurso | Efeito/limite de atribuição | Referência |
|---|---|---|---|---|
| OFF-01 | C | `mx-turbo` | Sem `ensure` no perfil atual. Seus guards de veículo/transmissão existem nas fontes, mas não foram atribuídos como bloqueio ativo. | `resources/[mx-scripts]/mx-turbo/`; `config/server.cfg`. |
| OFF-02 | C | `vMenu` | Instalado e com código compilado; sem início no perfil consultado. Suas restrições internas não foram apresentadas como falhas atuais do menu MX. | `resources/[mx-scripts]/vMenu/`; inventário de manifests. |
| OFF-03 | C | `mx-verification` | Resource de testes fora das categorias iniciadas pelo perfil. Seus asserts/erros não devem ser confundidos com erros da experiência pública. | `resources/[tests]/mx-verification/`; `config/server.cfg`. |

## 19. Registros históricos e situação das alterações anteriores

O arquivo local de log contém múltiplos boots e não carimba uma versão de código para cada erro. Foram agrupados **3.737 eventos** em **518 registros distintos**: 172 de conectividade, 3.516 de memória de assets, 15 de arquivo/manifest ausente, 29 de hitch e 5 de script. Esses totais pertencem ao recorte salvo no inventário, até a linha 4731; o arquivo de log pode continuar recebendo registros. O anexo conserva primeira/última linha e quantidade de cada registro, com endereço de rede omitido.

Os cinco registros de script são: SLOTS no mundo (linha 1197); falha em export `ReservePresentationExit` na ação play (1203); falha em `SpawnSavedAt` na ação play (1204); erro do runtime ao executar subprocesso no soundcore (1779); erro subsequente do resolvedor Lua (1794). O log de `SpawnSavedAt` apresenta uma exceção encapsulada e não permite identificar sozinho qual condição interna a causou.

Motor como requisito da saída, ocupação da saída especial e solo da apresentação já foram alterados no código em etapas anteriores. Não foram reiniciados recursos nesta auditoria nem comprovada a aplicação desses arquivos em todos os clientes. As tabelas mantêm esses itens como **R**, para não apresentá-los como bloqueios ainda existentes no código atual.

## 20. Verificação do relatório

- Inventário de arquivos, manifests, fontes e pontos detectados salvo em JSON e anexo Markdown. Cada fonte inventariada possui SHA-256 para delimitar a versão consultada.
- Referências de manifest conferidas contra arquivos locais, incluindo globs. Nomes lógicos de áudio `.dat` com arquivos `.datNN.rel` correspondentes não foram contabilizados como arquivos ausentes.
- Leitura de código dos módulos MX, NUI, gearbox, soundcore, integração de voz, entradas das dependências e arquivos de cenário/configuração citados nas tabelas.
- Leitura e agregação do log local, sem conexão com banco real, sem execução de comandos de administração e sem restart.
- Nenhuma condição listada foi removida ou modificada nesta etapa. O levantamento registra efeitos e limitações; não contém uma proposta de implementação.

Anexos: [locais individuais e log agrupado](experience-error-sites-2026-10-31.md), [inventário com hashes](evidence/experience-audit-2026-10-31/inventory.json). O relatório anterior [saída da garagem](garage-exit-and-experience-blockers-2026-10-31.md) permanece como histórico de uma investigação de escopo menor.
