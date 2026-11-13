# Backlog de execução T01–T40

Instalação atual: `txData/FiveMBasicServerCFXDefault_CAECC7.base`, integrada ao perfil txAdmin existente em 16/10/2026. A transferência preserva o estado dos aceites; detalhes em [txadmin-migration.md](txadmin-migration.md).

Status: **C** = implementação/verificação local concluída; **J** = código entregue, aceite de jogo pendente; **P** = verificação parcialmente executada por falta de clientes/carga/assets. Nenhum J/P é aprovação de gameplay. Prefixo dos resources abaixo: `resources/[mx]/mx-freeroam-`.

Evidências: **B** build/check; **L** 43 regras e análise Lua; **D** MariaDB/teste de reconexão SQL; **R** boot/exports no FXServer e 14 cenários persistentes; **U** browser em três resoluções; **BK** restore integral; **S** filtro sintético 20 pessoas. Arquivos e relatórios estão em testing.md e evidence/.

| ID | Estado | Arquivos/resources | Dependências | Regra implementada | Verificação | Pendência |
| --- | --- | --- | --- | --- | --- | --- |
| T01 | C | `.gitignore`, Git próprio, decisions.md | — | Base nova isolada; preservar txData/assets/banco alheio | Inventário, Git e namespace novo | — |
| T02 | C | package-lock, dependencies.lock, scripts/install-dependencies | T01 | Versões/origens/licenças/hash; oxmysql mantido e voz opcional | Instalação, auditoria, R | Avisos moderados de ferramenta local descritos |
| T03 | C | core + manifests dos oito módulos, config/*.cfg | T02 | Bootstrap enxuto; dependências declaradas e mundo compartilhado | B, R | Boot não prova entrada de cliente |
| T04 | C | migrations/001–004, scripts/migrate, setup-local | T03 | Schema/checksum, identidade única, índices, transações, usuário DML | D, R, BK | — |
| T05 | C | shared.lua, contracts.md, architecture.md | T03 | Contratos/domain ownership; core sem domínio de carros/XP/atividades | B, revisão, R | — |
| T06 | J | core/server.lua, client.lua | T04 | License privada, deferral, epoch, perfil/prefs CAS | D, R | Login/reconexão FiveM; concorrência de conexões |
| T07 | J | world/config.lua, client.lua, server.lua | T06 | Armas/procurado/PvP/população, lockdown e mundo independente da NUI | B, R | Bloqueios no jogo e compatibilidade de entidades |
| T08 | J | world/client.lua, entry/entryDone | T07 | Modelos/roupas aprovados, slot inicial, loading screen, morte/respawn | L, R | Colisão/coordenadas e aparência real |
| T09 | J | menu/dist, ui/src | T06 | Shell lateral local, categorias, loading/vazio/erro/pending | B, U | NUI no client |
| T10 | J | menu/client.lua, main.tsx | T09 | F1/F2/key mapping, foco único, navegação e limpeza | U, análise | Gamepad/Cfx, morte/restart com foco |
| T11 | J | vehicles/config.lua, catalog.lua/js, catalog/favorite | T05,T09 | Catálogo por origem autorizada em `[vehicles]`, metadados efetivos, marcas/filtros/páginas; vanilla legado preservado só em dados existentes | L, B, U; inventário offline de 12 modelos | Índice nativo, streaming e seleção de mods no jogo |
| T12 | J | vehicles/spawn, world/ReserveNearest | T11 | Slot reservado, UUID, server-created, ack/timeout, cooldown/trava | L, R | Dois spawns, falha de owner/modelo, assento |
| T13 | J | vehicles/active/retired journal | T12 | Um ativo; substituir após confirmação; aposentadoria com ocupantes | L, R | Passageiros, owner migration e restart ocupado |
| T14 | J | vehicles/properties.lua, client.lua, ui editor | T13 | Schema nativo, capacidades, preview/cancel/timeout, assinatura | L, B | Compatibilidade/readback de mods, extras e rodas |
| T15 | J | vehicles/garage/save/restore/CAS, migration001 | T14 | Dono na query, revisões, UUID persistente e limite | D, BK | Recuperação física após reconexão FiveM |
| T16 | J | world/destinations/travel/client collision | T12 | ID de destino, reserva, ack, rollback; passageiro não viaja carro alheio | B, R | Slots/colisão com dois clientes |
| T17 | J | vehicles/service, world/recover, activities/Recovery | T16 | Serviço seguro e recuperação configurada invalidam tentativa | L, R | Capotamento, passageiro e recuperação em pista |
| T18 | J | social/server.lua, rules.lua | T06,T16 | Posição server, lote 1 Hz, filtros antes do envio | L, S, R | Remotos fora do streaming e rede real |
| T19 | J | social/client.lua, progression/icons | T18 | Blip por sessão, timeout/reset, ícones liberados e uniformes | L, R | Sprites, alcance/zoom, source reutilizado |
| T20 | J | social/players, menu/route/lista | T19 | Busca, estado/região autorizada, rota de snapshot recente | U, L | Rota e privacidade de payload no jogo |
| T21 | J | social/invite/respond/rules | T18 | Cooldown, preferência, destinatário/epoch, expiração e consumo único | L, R | Duas pessoas, spam direto, recusa/expiração |
| T22 | J | social/groups/leave | T21 | Até 6, líder, entrada só no aceite, transferência/encerramento | L, análise | Aceites concorrentes e queda de líder |
| T23 | J | social/meets/announcements, admin/announce | T16,T22 | Contagem autorizada por região, anúncio ACE com prazo | R | Encontro real e mapa validado |
| T24 | J | social/chat, config/voice.cfg, pma-voice | T21 | Chat sanitizado/rate; voz proximidade opcional e mute local | R boot voz, B | Áudio real com dois clientes, mute e distâncias |
| T25 | J | core/preferences, social/contact/menu mute | T06,T21 | Contato all/none persistente; servidor não confia no frontend | D, L | Preferência e mute entre clientes/reconexão |
| T26 | J | activities/config/rules/Publish, admin/drafts | T05,T16 | Definição validada, revisão imutável, captura server, ativação explícita | L, D, R | Trajeto/slots; ativar revisão humana |
| T27 | J | activities/session state + prepare/go/release | T26,T13 | Estados no servidor, uma sessão, token/epoch, cleanup | L, R | Contagem, morte, desistência e restart ativo |
| T28 | J | activities/sample/segment/observação | T27 | Monotônico, interseção/direção, sequência, carro/bucket/regras/sync | L, R | Corrida legítima, CP pulado, atrasos e atalhos |
| T29 | J | activities/persist/outbox/ranking/history | T28,T04 | Resultado único, filtros comparáveis/páginas, treino separado | R, D, BK | Conclusão e ranking por sessão real |
| T30 | J | social/duel, activities/StartDuel/ghost | T21,T29 | Mesma regra/modelo/assinatura, largada coordenada, resumo/forfeit | L, R | Dois clientes, ghosting, empate e limpeza |
| T31 | J | activities/drift/telemetry/client | T27 | Treino com duração/distância/CP, amostras limitadas e versionadas | L, R | Coleta no carro e término; zona/rota no jogo |
| T32 | J | progression/ledger/levels/worker | T29 | Ledger único, nível derivado, processamento durável/recuperável | L, R, BK | Conclusão real gerando concessão |
| T33 | J | progression/achievements/cosmetics, migration004 | T32 | Direitos server, concessão/revogação derivada, domínio próprio | L, R | Seleção/reflexo em observadores no jogo |
| T34 | J | progression/weekly/challenge_claims | T32,T26 | Janela UTC, revisão, uma concessão; exemplo desligado | L, R | Habilitar conteúdo humano; fuso visual no jogo |
| T35 | J | progression/stats, menu/HUD/prefs/photo | T29,T32,T09 | Modalidades separadas, unidades/escala/volume, HUD prioritário | B, U, D | HUD, RPM/marcha reais e resmon |
| T36 | J | admin/server.lua, config ACE, audit_log | T05 | Permissões por ação, logs sem license, gestão via txAdmin | R, B | Usuário comum tentando endpoints/commands |
| T37 | C | activities/Revoke, progression/compensation | T29,T32,T36 | Ranking exclui revogado; compensações únicas e conquista reconciliada | R (inclui restart), BK | Interface/admin com cliente ainda pendente |
| T38 | C | core/boot, scripts/backup/restore, operations.md | T04,T36 | Falha explícita, backup e restore em banco vazio, retenção | D, R, BK | Falha de serviço durante jogo ainda pendente |
| T39 | P | tests/load.lua, testing.md | T18,T29,T35 | 20 identidades sintéticas com filtros reais; roteiro resmon/profiler | S, hardware registrado | Dois/20 clientes, pacotes e ms reais não disponíveis |
| T40 | C | README, architecture/contracts/coverage/backlog/testing/operations | T01–T39 | Relatório rastreável, distinção código/teste/jogo/assets | Revisão, B, L, D, R, U, BK | Aceites J/P continuam abertos, sem aprovação fictícia |

O primeiro marco I0–I2 foi implementado antes dos módulos sociais/atividades, com build, regras, persistência real e boot parcial verificados. A indisponibilidade de clientes impediu o aceite jogável; o trabalho independente continuou por I3–I7. Códigos J não devem ser convertidos em C até executar os roteiros respectivos.

## Incremento de experiência — 16/10/2026

Os IDs T01–T40 permanecem. T03–T06 recebem experience/drivecam e migration005; T08–T10 recebem onboarding, editor e oficina; T11–T15 recebem seleção durável, criações sem entidade pública, prévias privadas e journal; T12/T16 recebem saída Jogar e retorno; T39/T40 recebem nova matriz de aceites e documentação. Essas extensões estão em estado **J**: implementação e testes disponíveis entregues, validação com clientes pendente. Detalhes e evidências em [experience.md](experience.md).

### Retrabalho visual e de prévias — 16/10/2026

T09/T10: interface Heat e SessionMenu hierárquico por teclado; T12/T13: controlador único, gerações e remoção confirmada de prévias; T14/T15: listas contextuais e criações preservadas; T16: saída temporária reservada separada da apresentação; T37: inspeção de prévias protegida por ACE; T39/T40: testes determinísticos, browser e relatório. Estado das extensões: **J**, código/testes disponíveis entregues, sem aceite de entidades/câmeras no jogo. Veja [interface-rework.md](interface-rework.md).

### Personalização da garagem — 16/10/2026

T09/T10/T14/T15: editor por criação salva, descoberta de peças/nome nativo, cores/acabamentos, rodas e extras; T12/T13: aplicação sem recriar entidade; T16: câmeras por região e livre F4 com posse/foco preservados; T39/T40: testes de contrato, persistência MariaDB, exports no FXServer e relatório. Extensões em **J**, sem aceite com clientes de jogo. Ver [vehicle-customization.md](vehicle-customization.md).

### Editor inferior e apresentação Heat — 16/10/2026

T09/T10/T14/T15: barra inferior hierárquica e distinção entre prévia, rascunho e gravação; T12/T13: prévia existente preservada e ator externo local com limpeza por identidade; T16: mapa completo de enquadramentos, órbita e motorista oculto com RPM nativo; T39/T40: unidades de geometria/lifecycle, browser, SQL e roteiro de aceites. Estado **J**: áudio, imobilização, personagens e câmeras ainda dependem de cliente FiveM. [Relatório e controles](heat-customization.md).

## Incremento de lobby e navegação

T01–T40 mantidos, sem novos IDs. T03–T06: schema 006/contratos sociais e configuração de convite; T08–T10: loading/lobby, primeiro acesso e abas contextuais; T11–T16: restauração de seleção salva e retomada; T20/T21/T25: amizades persistentes no domínio social; T39/T40: testes de browser/SQL/geometria e relatório. Estado **J**: código e verificações disponíveis entregues, aceite com clientes FiveM pendente. [Cobertura deste incremento](lobby-navigation.md).

## Refinamento de input, câmeras e suspensão (17/10/2026)

IDs T01–T40 preservados. T09/T10: teclado e mouse, caixas de texto NUI e ações clicáveis; T14/T15: hierarquia de Customizar, stance visual validado/persistido e compatibilidade com documentos antigos; T39/T40: testes de input/preview/SQL/geometria, capturas e relatório. Estado **J** para os aceites de cliente, câmeras e sincronização visual ainda pendentes. [Cobertura e limitações](customization-input-stance.md).
