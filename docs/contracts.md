Atualização 17/10/2026: [teclado e mouse, Customizar, ações visíveis, câmeras e suspensão](customization-input-stance.md). Este incremento prevalece para input, F9/F10, rolagem e presets de câmera descritos anteriormente.

Incremento atual de lobby/garagem/câmeras: [implementação, contratos, evidências e validações pendentes](lobby-navigation.md). Schema 006; entrada inicial pelo lobby. Esta nota prevalece para esses fluxos sobre descrições anteriores.

Atualização de interface/entidades de 16/10/2026: [interface-rework.md](interface-rework.md) prevalece para os novos controles, coordenadas temporárias, fluxo de prévias e evidências de UI. Os aceites de jogo continuam pendentes.

Atualização 16/10/2026: experience acrescenta onboarding/oficina/aparência, journal idempotente e seleção durável; drivecam usa posse local. Contratos em [experience.md](experience.md). Os endpoints antigos de spawn/edição/CRUD da garagem respondem WORKSHOP quando a experiência está ativa; a NUI usa somente a oficina para essas operações. Serviços e viagens continuam no menu de sessão.

# Contratos v1

## Transporte público

Client → server: `mx:<domínio>:request(requestId, action, data)`. Resposta server → client: `mx:response(requestId, {ok, data? , code?, message?})`. Domínios conhecidos: `core`, `world`, `vehicles`, `social`, `activities`, `progression`, `admin`.

ID de até 64 caracteres, ação até 48 e payload de até 16 KiB. Valores financeiros, XP, autor, permissões, proprietário e tempo final não são aceitos. O source do evento determina o autor. Trava por sessão e rate limit globais protegem a chamada. O cliente espera no máximo 20 s; o callback NUI sempre responde, inclusive quando uma dependência está ausente. Não se deve repetir uma gravação após timeout sem reler seu ID/revisão.

Client usa `exports['mx-freeroam-core']:Request(domain,action,data)`. A NUI usa `POST https://mx-freeroam-menu/request` com `{domain,action,data}`, e callbacks locais `close`, `focus`, `route`, `mute`. Nenhum desses callbacks locais confere autoridade no servidor.

| Domínio / ação | Payload relevante | Retorno / regra |
| --- | --- | --- |
| core / profile | `{}` | ID interno, nome sanitizado, created, revision, epoch e preferências; não inclui license |
| core / preferences | `revision, preferences` | CAS; schema fechado, enums e limites; nenhum XP/cosmético desbloqueável |
| world / entry | `{}` | Slot reservado para primeiro spawn ou morte observada; não é teleporte arbitrário |
| world / entryDone | `key` | Confere reserva e posição observada antes de liberar |
| world / destinations | `{}` | Destinos/slots configurados, flags de disponibilidade |
| world / travel | `destination, withCar:boolean` | Apenas ID aprovado; responsabilidade, passageiro, reserva, colisão e confirmação |
| world / recover | `withCar:boolean` | Recuperação configurada da sessão ou destino principal; invalida tentativa |
| vehicles / catalog | `page?, search?, category?, favorites?` | Até 20 por página; tags, asset e favorito |
| vehicles / favorite | `id, value:boolean` | Chave única perfil/catálogo |
| vehicles / spawn | `model` | Allowlist, slot próximo, cooldown, confirmação; preserva anterior em falha |
| vehicles / garage | `page?` | Até 20 presets privados; total limitado a 30 por default |
| vehicles / restore | `id` | Consulta com dono; schema/modelo/propriedades validados |
| vehicles / save | `id:UUID, name, revision` | UUID estável gerado pela UI; revisão 0 cria; atualização exige revisão atual; salva apenas configuração confirmada do carro ativo |
| vehicles / rename, delete | `id,revision,name?` | Dono e CAS no WHERE da mutação |
| vehicles / duplicate | `id,newId:UUID` | Dono da origem, ID único no destino e limite de presets |
| vehicles / edit | `{}` | Snapshot e capacidades nativas do modelo atual |
| vehicles / preview | `properties` | Validação servidor, aplicação/rollback, capacidades atualizadas |
| vehicles / commit, cancel | `{}` | Confirma ou restaura snapshot; não grava preset por si só |
| vehicles / service | `kind:repair|clean|flip` | Próprio motorista, sem passageiros, velocidade < 2 m/s; invalida sessão |
| social / players | `{}` | Lista do mesmo bucket; localização/região omitidas quando não autorizadas |
| social / state | `{}` | Grupo, convites recebidos, encontros, anúncios e disponibilidade da voz |
| social / invite | `target,kind:group|duel,track?` | Preferência no servidor, mesmo bucket, cooldown, validade, regras visíveis |
| social / respond | `id,accept:boolean` | Somente destinatário/epoch; consome convite uma vez |
| social / leave | `{}` | Remove membro e transfere liderança ou encerra |
| social / chat | `message` | Até 250 caracteres, sem HTML/controles; mesmo bucket; rate limit |
| activities / tracks | `{}` | Catálogo de revisões e disponibilidade; competição exige validação/ativação |
| activities / start | `track,mode:practice|timeattack|drift` | Carro próprio parado no início; UUID de sessão server; não recebe tempo final |
| activities / stop | `{}` | Desistência; drift encerra treino; duelos limpam ambos com resultado explícito |
| activities / state | `{}` | Estado mínimo da sessão do autor |
| activities / telemetry | `id,speed,angle,rpm` | Apenas drift ativo, limites e retenção; informação client identificada como provisória |
| activities / configuration | `id,signature` | Observação técnica; divergência invalida, nunca autoriza novo resultado |
| activities / ranking | `track,mode?,page?` | Pista/revisão/direção/modalidade/regras/modelo/assinatura/condições exatos, até 20 |
| progression / profile | `{}` | XP derivado, nível, cosméticos, conquistas, histórico, estatísticas e desafio ativo |
| progression / cosmetics | `icon,title` | Catálogo público e direito persistido; grava no domínio de progressão |
| admin / permissions | `{}` | Flags ACE, sem dados privados |
| admin / inspect | `{}` | Exige algum cargo; detalhes de carro/sessão somente com mx.inspect |
| admin / revoke | `id,reason` | mx.invalidate; conserva resultado, entrega compensação durável |
| admin / cleanup | `{}` | mx.cleanup; somente entidades gerenciadas, respeitando outros ocupantes |
| admin / announce | `destination` | mx.announce; destino cadastrado, anúncio com prazo |

Erros estáveis incluem `PAYLOAD`, `RATE`, `BUSY`, `DUPLICATE`, `SESSION`, `DATABASE`, `UNAVAILABLE`, `TIMEOUT`, `CONFLICT`, `NOT_FOUND`, `MODEL`, `ASSET`, `OWNER`, `PASSENGER`, `DRIVER`, `SLOTS`, `DRAFT`, `RULES`, `CATEGORY`, `LOCKED` e `FORBIDDEN`. A UI apresenta código/mensagem e oferece releitura; não mostra sucesso em caso de falha do SQL.

## Confirmações server → client

`core:ClientCall(src,domain,action,data)` emite `mx:<domain>:client(token,action,data)`. Cliente responde `mx:core:ack(token,ok,data)`. Token pendente está vinculado a source+epoch e expira em 12 s. Apenas a resposta do destinatário é aceita. Handlers client rejeitam eventos locais com source diferente de 65535.

Operações: world `travel`; vehicles `load`, `apply`, `inspect`, `service`; activities `prepare`. Uma confirmação client é necessária para natives/RPCs falíveis, mas não prova honestidade do cliente; posição, motorista, entidade, bucket, sequência e tempo continuam sendo conferidos no servidor.

## Exports internos — não são eventos de rede

| Resource | Exports |
| --- | --- |
| core | `Query(sql,args)`, `Transaction(queries)`, `Profile(src)`, `Profiles()`, `IsReady()`, `BootId()`, `Guard(src,action)`, `Run(src,epoch,fn)`, `ClientCall(...)` |
| world | `Reserve(src,destination,serverPoint?)`, `ReserveNearest(src)`, `Release(key,src)`, `Travel(src,destination,withCar,serverPoint?)`, `Destinations()`, `Conditions()` |
| vehicles | `OwnedDriver(src,requireNoPassengers)`, `Active(src)`, `IsEditing(src)`, `Inspect()`, `Cleanup()`; client: `ObservedSignature(netId)` |
| activities | `Invalidate(src,reason)`, `State(src)`, `Recovery(src)`, `DescribeDuel(src,target,track)`, `StartDuel(a,b,track,acceptedRules)`, `Publish(track)`, `Inspect()`, `Pending(limit)`, `Acknowledge(resultId,revokedRevision)`, `Result(id)`, `History(playerId)`, `Stats(playerId)`, `Revoke(id,reason)` |
| progression | `Public(playerId)`, `ValidateCosmetics(selection)`, `AuthorizeCosmetics(playerId,selection)`, `Reconcile(playerId)`, `Reprocess()` |
| social | `Group(src)`, `Announce(src,destination)` |

`Active` fornece ID estável da operação, entidade/net ID atuais, modelo, assinatura e propriedades confirmadas. `State` fornece somente ID, modalidade e estado. Esses contratos reais são o limite reservado para futura integração do câmbio; não existe adaptador de transmissão vazio habilitado.

Fatos server-only: `mx:profile:changed`, `mx:profile:dropped`, `mx:activities:result`, `mx:activities:revoked`, `mx:progression:changed`. São `AddEventHandler`/`TriggerEvent`, não `RegisterNetEvent`. Resultados continuam recuperáveis sem esses fatos em memória.

Mensagens server → client: `mx:profile`, `mx:notify`, `mx:social:presence`, `mx:social:remove`, `mx:social:reset`, `mx:social:chat`, `mx:activities:state`, `mx:activities:go`, `mx:activities:release`, `mx:activities:ghost`. Presença é agregada, filtrada antes do envio e não depende de `GetActivePlayers`. Usa uma identidade por source+epoch; blips por coordenada permanecem fora do streaming. A expiração elimina marcadores obsoletos; não há aumento de culling ou persistência contínua de posições.

## Carro da sessão e Showroom — 17/10/2026

`experience/state` inclui `current` (modelo, propriedades confirmadas, ID salvo opcional e revisão) e `currentDirty`. `preview` é a entidade temporária; `selected` continua sendo a referência persistida da seleção. A NUI apresenta `current` como carro atual, sem confundir o ID da entidade com o da criação.

Rotas privadas `experience/useCurrent {token,operation,id,model,name?}` e `confirmCurrent {token,operation,id,properties}` usam o journal transacional. Usar explicitamente um modelo cria sua configuração persistida; confirmar uma peça atualiza a criação associada, com validação e preparação SQL no domínio vehicles. `id` é um UUID candidato; uma criação já associada conserva seu ID. O recibo e a alteração são gravados na mesma transação; repetição usa o mesmo `operation` e conteúdo. A NUI bloqueia outra confirmação enquanto o resultado estiver incerto. `cosmetic` continua sendo prévia sem gravação. `resetPreview` restaura as propriedades confirmadas. `saveCurrent` permanece apenas como compatibilidade interna, sem botão/atalho na interface. Primeiro acesso e duplicar/renomear/excluir continuam disponíveis.

`vehicles/catalogBrands` e `vehicles/catalog {page,search,brand}` retornam somente origem autorizada `source=vehicles`, com disponibilidade por resource e conflitos. `vehicles/ShowroomModel(model)` é export server-only de autorização; dados legados aceitos em Carros salvos não ampliam o Showroom. `mx:vehicles:catalogIndex` é um evento local de servidor, emitido pelo indexador de manifests, sem registro de evento de rede.

NUI `navigationContext {modal}` apenas reinicia a detecção de borda do controle e informa bloqueio de câmera/motor por modal; não autoriza alterações de veículo ou persistência. Detalhes e verificações em [lobby, controle, cores e carros salvos](lobby-showroom-controls-2026-10-17.md).

Atualização: NUI local `previewNight {enabled}` e `previewLights {enabled}` alteram somente a apresentação ativa. `world:SetLobbyTime(hour?,minute?,weather?)` aceita chamadas de experience; ausência de hora restaura os padrões. Lobby usa FOGGY; prévia noturna da garagem mantém o clima normal. Parar experience remove a substituição. O indexador usa os metadados efetivos `data_file`/`data_file_extra` e `LoadResourceFile`; glob enumera somente o resource montado. Ver [contratos e regressões atuais](workshop-polish-2026-10-17.md).

Refinamento posterior: o editor agrega prévias cosméticas por 180 ms e aguarda 500 ms desde a resposta cosmética anterior. Confirmar não faz uma prévia redundante: a rota transacional valida/aplica e fornece capacidades pelo estado retornado. Extras ligados são conferidos após as peças, extras ausentes desligados são aceitos; modkit 48 e livery nativa têm prioridade explícita e não se sobrescrevem durante navegação. O comando NUI `nav/night` usa S/X/Quadrado apenas no contexto de iluminação. Ver [refinamento de extras, adesivos e controle](workshop-refinement-2026-10-17.md).

Prévia local `previewNeon {id,enabled,layout,color,restore,restoreColor}` usa o ID do editor atual, não grava propriedades e atua apenas na entidade de apresentação. Layout/restore são quatro booleanos; color/restoreColor são RGB. Comandos obsoletos são ignorados e a saída restaura a configuração confirmada. Detalhes de alimentação em marcha lenta e partida em [iluminação e motor](lighting-engine-2026-10-17.md).


## Trainer pessoal

Novas rotas world: trainerState, noclip, saveCheckpoint, returnCheckpoint e clearCheckpoint. O servidor captura a posicao e autoriza o noclip por token; vehicles valida os servicos e experience encerra o modo antes da garagem. [Contratos detalhados](freeroam-trainer-2026-10-18.md#contratos).


## Correcao do retorno a garagem e trainer sem mouse

Desembarque coordenado, espera por posicao replicada, recuperacao do carro/controles, erro descritivo e foco apenas de teclado no trainer. [Fluxo, contratos e limites](trainer-entry-recovery-2026-10-18.md). Lobby e garagem preservam o mouse.


## Noclip e checkpoint: revisao atual

Oito velocidades, modo fixo/camera, Shift/Q/Z/H e apresentacao translucida. Checkpoint restaura inclinacao sem condicionar retorno a colisao carregada; viagens comuns mantem suas regras. [Implementacao, referencia vMenu e limites](noclip-checkpoint-2026-10-18.md).
# Trainer: administração, pistas e controles (2026-10-18)

Editor de câmera de desenvolvimento, 24/10/2026: `admin/cameraEditor {enabled}` autoriza mx.admin + mx.inspect inclusive nas cenas privadas. Callback autenticado `experience/developerCamera` inicia/encerra uma concessão sobre o handle/view/generation atuais. NUI `cameraDeveloper {action,pose?,restore?}` aceita update/snapshot/reset/capture/close só durante a concessão. Export `experience:DeveloperCamera` não concede ativação por conta própria. `mx:experience:cameraDeveloper` transporta estado local até o resource NUI; renew do servidor usa `mx:experience:cameraDeveloperGrant` com filtro de origem. Captura é Lua local com contexto/visão/posição/rotação/mira/FOV, sem persistência. Detalhes: [camera-developer-2026-10-24.md](camera-developer-2026-10-24.md).

Apresentação atualizada em 24/10/2026: `scene.ped`/`lobbyScene.ped` são pontos explícitos com `fixed=true`; confirmação de chão não substitui XYZ/heading. `WorkshopPresentation.ground` preserva a marca no clone. `WorkshopIdle` controla somente ator visível local, sem bloquear ACKs, e cancela por identidade/contexto/edição/saída. Câmeras principais projetam limites do carro/personagem mantendo altura baixa; câmeras de detalhe preservadas. Pontos e testes: [menu-poses-idles-2026-10-24.md](menu-poses-idles-2026-10-24.md).

Atualização 24/10/2026: `admin/coordinates {target:'ped'|'vehicle'|'camera'}` retorna posição/heading local com dados opcionais de entidade. `admin/coordinateOverlay {enabled,target}` configura leitura contínua com concessão temporária (renovação 2 s, expiração 6 s); ambas exigem mx.admin + mx.inspect e modo livre. `admin/teleport {mode:'coordinates',point:{x,y,z,h?}}` ou `{mode:'waypoint'}` exige mx.admin + mx.teleport, audita intenção e usa `world:AdminTravel`. O export retorna envelope MX.capture, aceita apenas origem admin e revalida ACE/contexto/epoch. Viagem usa o fluxo existente, com posse, passageiros, reserva, ACK, posição e rollback. Snapshot nunca autoriza alvo de mutação. Ver [ferramentas e validação](admin-coordinates-teleport-2026-10-24.md).

- `admin/permissions`: inclui `admin`; todas as permissões de ação exigem também `mx.admin`.
- `admin/moderate {target,action,reason}`: `warn|kick|ban`, alvo real numérico, motivo obrigatório, proteção de administradores, revalidação de identidade e sessão depois do audit SQL. Ban persistido antes de DropPlayer.
- `admin/createTeleport {name,category}` → `world:CreateTeleport(src,name,category)`: world valida o recurso chamador e as ACEs novamente. Coordenadas pertencem ao estado sincronizado do servidor, nunca ao payload do cliente.
- `admin:CheckConnection(license)` retorna motivo de rejeição ou nil; core consulta esse contrato durante a conexão. Falha de serviço bloqueia a entrada. Dados e regras de moderação permanecem em admin.
- `world/destinations` e `world/travel` preservados: pontos estáticos de `tracks-config.lua` e pontos persistidos de `teleports.json` compartilham reserva, validação de assets e viagem existentes. UI agrupa a lista em Pistas/categoria/ponto.
- NUI local `bindings`, `setBinding {action,kind,value}`, `trainerOptions`; ações e teclas em whitelist, KVP por perfil, remoção por string vazia. `menu:BindingInput(action,held)` integra noclip ao mesmo registro. Nenhum ExecuteCommand ou unbind derivado de texto do jogador.
- Fixture `[TESTE]` local opcional: não pertence ao contrato social real. Rotas reais de moderação rejeitam seu identificador textual. Nunca emite sucesso real de moderação.

# Opções do veículo — 2026-10-18

- `vehicles/options {}`: estado do carro ativo do perfil, `available[kind]`, `reasons[kind]`, `doors`, `driver`, `drift`, `locked`. Nenhuma seleção de entidade enviada pelo cliente é aceita como autoridade.
- `vehicles/service {kind,vehicleId?,door?,enabled?}`: repair/clean/flip/engine/doors/stop/lock/eject/respawn/drift. `door=-1` significa todas, 0..5 é individual; `enabled` boolean obrigatório em drift. Guards de contexto repetidos no servidor.
- Callbacks autenticados `vehicles/serviceInfo`, `prepareRespawn`, `resumeRespawn`, `eject` e `service`: identidade/net fornecidos pelo servidor. `serviceInfo` só informa capacidades locais; não concede autorização.
- `Active(src).drift` permite ao domínio de atividades excluir o preset de competição. `OwnedDriver` continua exigindo motorista para os contratos que precisam dele.
- `mxDrift={id,preset,enabled}`: estado publicado pelo domínio vehicles, aplicado por entidade em cada cliente. Snapshots locais pertencem à identidade gerenciada; são restaurados ao desativar/parar o recurso e descartados quando a entidade deixa de existir ou muda de identidade.
- `preparedSlot.departure=false` é a recriação do trainer; a saída da oficina mantém seu fluxo anterior de partida. Presets SQL não são recriados por essas operações.

# Atualização física de drift — 2026-10-18

`vehicles/handlingAudit {}` retorna as leituras do veículo ativo próximo: 51 campos esperados/lidos, divergências, marcha máxima, rodas motrizes, metadados excluídos e controle local de rede. Exposto pelo comando local `mxhandling`; não aceita alvo arbitrário e não concede permissões com base na leitura do cliente. Ativação de drift exige ACK com `transmissionRefreshed=true`. Recálculo autorizado de transmissão usa exclusivamente `ModifyVehicleTopSpeed(v,0.0)` no controlador do preset, incluindo restauração, reparo e migração de ownership.


# Noclip e modo drift persistente ? 2026-10-18

`Active(src).presetId` identifica a criação salva, separada de `id` da entidade. `vehicles/service {kind="drift",enabled}` só confirma sucesso após ACK de aplicação e gravação em `garage_presets.drift_enabled`; resposta inclui `persisted` e `presetId`. SpawnSavedAt relê o modo por proprietário/ID. Cosméticos não sobrescrevem a flag. Ver `noclip-persistent-drift-2026-10-18.md`, que substitui a limitação anterior de drift apenas na entidade ativa.

# Teleporte direto para pistas - 2026-10-18

`world/travel {destination}` escolhe a entidade pelo estado real do ped no servidor; `withCar` legado não controla essa rota. Confirmar a pista executa a viagem sem submenu. O callback autenticado `world/travel` solicita streaming sem gate de `HasCollisionLoadedAroundEntity`; ACK, posição replicada, identidade, sessão, motorista, passageiros e reservas continuam verificados. Export Travel e recuperação mantêm seus parâmetros internos. Ver `track-direct-teleport-2026-10-18.md`.

# Exports protegidos e primeira entrada — 2026-10-23

Atualização de stance em 24/10/2026: `vehicles/apply` retorna também `stance={value,warning?}`, onde `value` é a configuração visual efetiva ou `false`. `capabilities.stance` contém `value`, `unavailable={wheelSize?:motivo,wheelWidth?:motivo}` e aviso opcional, além de available/tuningWheels/ranges. Recusa de uma dimensão não confirma o fator pedido: `VehicleProperties.acceptStance` valida e incorpora o valor efetivo antes de publicar/guardar. A UI reconcilia rascunho e capacidades; o salvamento usa a prévia confirmada. Ausência do campo stance mantém compatibilidade com ACKs antigos estritos; campo presente sem value válido é erro. Ver [recuperação das rodas](stance-wheel-recovery-2026-10-24.md).

Atualização de drift opcional em 24/10/2026: `vehicles/apply` pode retornar `{applied:true,...,drift:{enabled:false,fallback:true,recovered,uncertain,warning,detail}}`. `applied` confirma a personalização obrigatória/entidade, não o preset opcional. O servidor publica `mxDrift.enabled` efetivo, `requested` e `uncertain`. Active/options expõem estado efetivo e aviso; preferência SQL continua independente. `vehicles/service {kind:'drift'}` retorna `{enabled,persisted:false,warning}` em fallback; não gravar nem apresentar isso como toggle confirmado. `handlingAudit` inclui `recovery` com o último diagnóstico local. Ver [política de recuperação](handling-recovery-2026-10-24.md).

Os exports internos `core:Run`, `core:ClientCall`, `vehicles:Preview` e `vehicles:ApplyPreview` retornam `{ok:true,data}` ou `{ok:false,code,message,detail?}`. O chamador usa `MX.unwrap` dentro do próprio resource; não usar o retorno diretamente como dados de sucesso. O callback passado a `Run` também retorna um envelope capturado no resource que registra a rota; `MX.routes` cuida das duas fronteiras. `detail` é interno e não faz parte da resposta NUI. `BUSY`/`OBSOLETE` mantêm seus códigos; não autorizam gravação nem confirmação de seleção substituída.

Callback `vehicles/load {model,intent?}` retorna `{loaded,cancelled?}`. Apenas intenções originadas na interface usam cancelamento local; prévias automáticas continuam vinculadas à geração no servidor. `experience/scene` confirma `{ready:true}` somente depois de preparar streaming, colisão e, para a garagem, mapa/modelo/interior. Prazos e verificações em [cold-join-preview-2026-10-23.md](cold-join-preview-2026-10-23.md). A implantação requer reinício completo e reconexão dos clientes por mudar contratos compartilhados.

# Trainer: troca e noclip - 2026-10-19

Preparação de troca/recriação (2026-10-21): callbacks internos `vehicles/prepareRespawn` e `vehicles/resumeRespawn` recebem `{net,id,transfer}`. `transfer` é exclusivo da operação, gerado no servidor. Preparação responde `{ready:true}` ou `{ready:false,reason:'EXIT_TIMEOUT',recovered:true}`; erro nativo restaura localmente antes de propagar. Rollback antigo responde `{resumed:false,obsolete:true}` e não altera a operação atual. O servidor verifica o ACK de recuperação. Consulte [recuperação de troca](trainer-switch-recovery-2026-10-21.md).

Atualização de ambiente dinâmico: `GlobalState.mxEnvironment` inclui `second`, `weatherFrom` e `weatherBlend` (0–1), publicados pelo servidor a cada segundo real junto de `weather/hour/minute/revision`. Clientes validam os campos adicionais e usam o clima fixo como fallback. Preferências pessoais e cenas não escrevem no estado global. Ver [configuração e ciclo](dynamic-environment-2026-10-21.md).

Contrato adicional de ambiente pessoal (2026-10-21): NUI `personalEnvironment {}` lê; `{patch:{syncWeather?,syncTime?,weather?,hour?,minute?}}` grava via exports de world. Apenas menu aberto em modo livre; world verifica origem, perfil e campos. `GlobalState.mxEnvironment` é publicado pelo servidor; KVP pessoal não o modifica. Cena de apresentação prevalece até sua liberação. Consulte [detalhes e limites](environment-entry-paint-2026-10-21.md).

`vehicles/trainerGarage {}` lista criações do perfil. `vehicles/switch {presetId}` ou `{model}` valida exatamente uma seleção, resolve propriedades no servidor e troca a entidade coordenadamente no local; não aceita coordenadas do cliente. Catálogo reutiliza catalogBrands/catalog com marca e paginação. `world/toggleNoclip {}` decide o estado no servidor em uma requisição. `world:StopLocalTrainer()` apenas encerra a própria sessão local e notifica o token; não autoriza ativação. Callback NUI `noclipToggle` usa esse desligamento e reconcilia o estado no servidor. Drift e recriação permitem movimento; desvirar continua exigindo parar. Detalhes: `trainer-drift-switch-2026-10-19.md`.
