# Drift server FiveM

Atualizado em: 2026-10-24 (cópia local no workspace).
Origem: síntese da conversa do usuário com Codex; código e documentação locais consultados em 2026-10-23. Datas de entregas abaixo seguem os relatórios, sem presumir novo aceite no jogo.

## Objetivo

Servidor FiveM de freeroam/JDM com base standalone própria, core enxuto, garagem persistente, personalização gratuita e ferramentas para diversão no modo livre. Preservar funcionalidades e dados existentes; não importar base pronta de RP nem concentrar regras de veículos, atividades ou progressão no core.

## Identificação e caminhos

- Workspace: `C:\FiveM\drift-server`.
- Base ativa de dados/resources: `C:\FiveM\drift-server\txData\FiveMBasicServerCFXDefault_CAECC7.base`.
- Os caminhos relativos abaixo partem dessa base, salvo indicação contrária.
- Resources próprios: `resources/[mx]/mx-freeroam-*`.
- Fontes NUI: `development/ui/src`; build servido: `resources/[mx]/mx-freeroam-menu/dist`.
- Ferramentas, testes e migrations: `development/scripts`, `development/tests`, `development/migrations`.
- Relatórios e evidências: `docs/`, `docs/evidence/`.
- Instalador de veículos: `C:\FiveM\drift-server\tools\FiveMVehicleInstaller` — assunto relacionado, com documentação e testes próprios.

Não usar a antiga pasta `/freeroam` como instalação principal nem ressuscitar caminhos de documentos antigos. O usuário solicitou explicitamente integrar a implementação à base CFX/txAdmin existente.

## Estado atual

Há implementação e testes locais para entrada/perfil, loading/lobby, personagem único, oficina privada, catálogo, carros salvos, personalização, saída Jogar, trainer, administração e outros domínios do plano original. Isso não significa aceite integral em jogo. O backlog T01–T40 mantém estados C/J/P em `docs/backlog.md`; muitos itens são J (código entregue, jogo pendente) ou P (verificação parcial).

Os relatórios mais recentes registram correções de pintura do S14, entrada inicial, clima/horário pessoal e dinâmico e recuperação da troca S14 → ER34N. Não há, depois dessas entregas nesta conversa, confirmação do usuário de que os casos passaram no jogo.

## Arquitetura e inicialização

| Domínio/resource | Responsabilidade principal |
| --- | --- |
| core | Identidade/perfil, acesso ao banco, RPC, rate limit e exclusão por sessão/epoch. |
| world | Mundo, reservas/teleportes, noclip/checkpoint, clima/horário. |
| vehicles | Catálogo, propriedades, carros salvos, entidades, peças e modo drift. |
| experience | Loading/lobby, onboarding, personagem, apresentação privada, garagem/saída. |
| menu | React/TypeScript, navegação, foco, componentes visuais e HUD. |
| drivecam | Câmera local de condução e preferência. |
| social | Presença, jogadores, amizades, grupos e comunicação. |
| activities | Pistas de atividade, tentativas, resultados, ranking e telemetria. |
| progression | Ledger, XP, conquistas e desafios. |
| admin | ACE, auditoria, moderação e autoria de conteúdo. |

Comunicação por contratos; NUI/client não autorizam ações administrativas nem substituem validação no servidor. ID de criação salva, identidade da entidade e net ID são conceitos diferentes. Epoch protege contra resposta atrasada para sessão/source reutilizado.

`config/server.cfg` inicia `oxmysql`, executa `config/assets.cfg`, usa `ensure [mx]` e carrega voz/configuração local do txAdmin. Dependências de ordem pertencem aos manifests. Conferir configuração efetiva antes de mudar start. MariaDB/oxmysql é a persistência SQL; `db/default` é armazenamento nativo/KVP e não deve ser tratado como lixo SQL. `cache` é gerado pelo FXServer.

Scripts preservados por pedido expresso: `resources/[mx-scripts]/mx-gearbox` e `mx-turbo`. Integração/ativação não deve ser presumida. Não apagar nem refazer esses scripts como parte de uma limpeza genérica.

## Decisões de produto e interface

Origem: pedidos sucessivos do usuário nesta conversa; estrutura atual conferida no código em 2026-10-23.

- Direção visual: composição de Need for Speed Heat, complementada por Unbound; veículo visível, interface nas bordas, tipografia condensada, seleção clara e poucas superfícies grandes. Evitar dashboard e cartões arredondados genéricos.
- Loading, lobby e garagem têm transições curtas de escurecer/aparecer; não aplicar esse fade a toda navegação interna.
- Lobby/garagem/oficina utilizáveis por teclado, mouse e controle. Exceção explícita: trainer do modo livre é apenas teclado/controle, sem cursor/captura do mouse.
- Abas superiores: Q/E no teclado, L1/R1 ou LB/RB no controle; clicáveis quando há mouse. Não exigir subir com o direcional para alcançá-las.
- Componentes compartilhados: ControlHints/ControlGlyph, TabBar, OptionStrip, ConfirmDialog, SettingsRow e StancePanel. Ícones de controles em versão solid, pequenos. Licença registrada em `docs/licenses/kenney-input-prompts.txt`.
- Seleção destacada tem escala maior. Etiqueta `EQUIPADO` no canto superior direito, fonte dos títulos/labels e verde `#2FB449`. Carro atual na lista de salvos usa etiqueta, sem parecer uma segunda seleção.
- Scrollbars invisíveis; continuidade de conteúdo parcialmente visível. Faixas inferiores começam afastadas da borda e permitem itens saírem da tela ao rolar. Contagem apenas nas listas de modificações efetivas.
- Veículos e peças gratuitos; não adicionar preços, dinheiro, monetização ou bloqueios de compra. Catálogo de modelos não é a coleção de criações salvas.
- Não recolocar botões globais Salvar/Descartar ou F9/F10. Confirmar uma peça aplica/persiste via contrato existente. Prévia não confirmada deve poder ser restaurada. Suspensão usa revisão em modal ao sair, para manter/resetar, sem botões permanentes de aplicar/restaurar.
- Customizar: **Peças e rodas**, **Pintura & liveries**, **Suspensão**, **Iluminação & efeitos**, **Interior & detalhes**. Rodas não pertencem à suspensão. Pintura reúne canais em abas superiores e adesivos em seu grupo. Extras/neons são toggles agrupados.
- Iluminação separa neons (cor/layout) e faróis (xenon/cor). Prévia deve mostrar as luzes; neon pode manter motor em marcha lenta para apresentação. Atalho dia/noite aparece no contexto de iluminação.
- Câmeras automáticas preferem o lado direito para evitar o personagem. Câmera livre própria orbital persiste entre submenus de Customizar e é desligada ao sair desse contexto. Mouse arrasta em área vazia; cancelar arraste ao perder foco/sair da viewport. Não selecionar textos da interface ao arrastar.
- Atalhos na oficina: C muda visão; ESPAÇO abre/fecha portas; testar motor por W/gatilho, com bloqueio curto de aceleração após partida. Não reaproveitar binds antigas de F4/L-ALT como estado atual.

## Coordenadas atuais

Fonte: posições fornecidas pelo proprietário e `resources/[mx]/mx-freeroam-experience/config.lua`, atualizados em 2026-10-24. Pontos independentes; não alterar um para mover o outro.

| Contexto | X | Y | Z | Heading |
| --- | ---: | ---: | ---: | ---: |
| Lobby — personagem | -950.165 | -3535.050 | 14.618 | 77.78 |
| Lobby — veículo | -949.463 | -3532.688 | 13.967 | 116.28 |
| Garagem — personagem | 133.303 | -3027.849 | 7.041 | 276.85 |
| Garagem — veículo | 135.962 | -3030.353 | 6.396 | 0.11 |
| Saída para modo livre | 163.2 | -3024.11 | 6.05 | 268.29 |

Lobby: 23:00 e FOGGY. Garagem mantém offsets próprios. Área de entrada: X 120–160, Y -3050–-3007, Z 6–10, com indicação de E/equivalente. `departureDelay=450` ms para ouvir a partida; saída prevista com motor ligado. `bucketStart=10000` define a base para apresentações privadas por jogador; não é o mundo aberto compartilhado.

## Trainer e controles

- M abre menu; R repara; F2 alterna noclip; F3 cria checkpoint; F4 retorna; F7 câmera de condução. Fonte: `menu/bindings.lua`.
- Menu **Controles** permite atribuir/remover binds e adicionar a ações sem padrão; KVP por perfil/cliente. Não desassociar comandos de outros resources.
- Noclip inspirado no vMenu: velocidades e orientação ajustáveis, transparência mantida (`ghostAlpha=80`), `ResetEntityAlpha` na desativação/limpeza. Correções de reativação e desligamento rápido estão implementadas; comportamento físico continua sujeito a validação.
- Checkpoint pessoal/temporário salva posição/direção para repetir manobras. Viagem para pista decide transporte pelo estado real: dirigindo carro próprio, leva-o; a pé, leva ped. Não recolocar submenu a pé/com carro ou bloqueio rígido de `HasCollisionLoadedAroundEntity` nesses fluxos. Manter posse, passageiros, bucket e posição validados.
- **Opções do veículo** reúne reparo/limpeza, motor, portas (escolher lateralmente e confirmar), travas, expulsão, recriação e drift. Motor/portas não exigem estar sentado se o proprietário está próximo. Não bloquear movimento por conveniência; desvirar continua exigindo parar.
- **Trocar de carro** permite escolher criação salva ou catálogo sem voltar à garagem. **Voltar para a garagem** deve abrir a oficina, não o lobby.
- Pistas estáticas: `world/tracks-config.lua`; autoria administrativa captura posição no servidor, nome/categoria e grava `teleports.json`. Moderação exige ACE administrativa e da ação no servidor. Admin do txAdmin não implica automaticamente ACE do jogo.
- `bans.json` e `teleports.json` são dados operacionais para preservar em backup; não publicar identidades. Jogador temporário de desenvolvimento é fixture explícita de UI, sem ações reais contra source inventado; conferir `mx_menuTestPlayer` antes de produção.

## Handling de drift: exceção autorizada ao escopo inicial

O pedido inicial excluía handling/física e aperfeiçoamento do câmbio. Posteriormente o usuário forneceu um XML e autorizou explicitamente o toggle **Handling de drift**. Essa exceção não autoriza reescrever toda a física/câmbio.

Preset em `vehicles/drift-config.lua`, aplicação/restauração em `drift-client.lua`. Modo salvo por criação em `garage_presets.drift_enabled` (migration `007_vehicle_modes.sql`), recuperado no spawn. Não confundir flag da criação com handle/net ID nem sobrescrevê-la ao salvar cosméticos. Preset de drift bloqueia competição conforme guards existentes, preservando treino.

Há correção documentada do subtipo `CCarHandlingData` do ER34N e verificação dos 51 atributos do XML autorizado. Não presumir que readback de native comprova dirigibilidade. O usuário relatou diferenças de comportamento; a validação de física continua no jogo.

## Clima e horário atuais

Entrega registrada em 2026-10-21; código consultado em 2026-10-23.

- World é o único escritor de clima/relógio. Preferências pessoais de clima e tempo são independentes, fixas quando desligada a sincronização, em KVP por perfil/instalação do cliente.
- Servidor publica `GlobalState.mxEnvironment` a cada segundo real, com hora/minuto/segundo e origem/destino/proporção do clima.
- `secondsPerGameMinute=4`: dia de jogo em 96 minutos reais. Novo clima a cada 15 minutos reais, transição de 60 s; grafo coerente sem neve no padrão.
- Lobby/garagem prevalecem temporariamente; ao sair retoma estado corrente do mundo ou preferência pessoal.
- Configuração em `world/config.lua`, ciclo em `environment-server.lua`. Restart volta ao estado inicial configurado; não é hora civil nem persistência SQL do ciclo. Revisão `dynamic-environment-v1` substitui a antiga de horário fixo.

## Persistência e segurança para continuidade

Preservar perfis, criações, propriedades, revisões e journals de operações. Não substituir SQL real por mocks nem contornar confirmação incerta com mensagens de sucesso. Operação sem ACK não pode virar gravação confirmada; usar retry idempotente/recarregar estado conforme contrato.

Não fazer limpeza indiscriminada de carros próximos: remover só entidades administradas pela operação, com identidade revalidada depois de awaits. Última seleção deve prevalecer em previews; um registro salvo não é uma entidade de apresentação nem um veículo público.

Migrations presentes: 001–007 em `development/migrations`. Relatórios históricos documentam testes em MariaDB/boot; nenhuma consulta ao banco foi feita para esta memória. Configurações locais, segredos, banimentos e dumps não devem ir para memória pública.

## Pendências prioritárias e próximo passo

1. **Troca S14 → ER34N:** último relato do usuário foi erro RESPAWN e carro travado. Implementada recuperação local, portas destrancadas antes do desembarque, token por transferência e watchdog de 10 s; ainda sem reteste confirmado no FiveM. Ver `docs/trainer-switch-recovery-2026-10-21.md` e `vehicles/respawn-client.lua`.
2. **Pintura S14:** implementada ordem peças → acabamento/índices → RGB e confirmação por modo. Falha real continua bloqueando gravação; detalhes incluem esperado/observado. Ainda sem confirmação em jogo. Ver `docs/environment-entry-paint-2026-10-21.md`.
3. **Primeira entrada no lobby:** espera por ped replicado, epoch estrito, recuperação protegida e fundo opaco de erro. Falta cold join real com latência/reconexão.
4. **Ambiente dinâmico:** validar transições visuais, mesmo estado entre dois jogadores, escolhas pessoais e retorno das cenas.
5. Validar gamepad físico, foco, órbita, peças/portas, neon/som de partida, streaming de mods e mudanças de owner; sem transformar testes de browser em aceite de jogo.
6. Integração de mx-gearbox/mx-turbo e restante dos aceites T01–T40 dependem de trabalho próprio. Não reativar funções sociais removidas do trainer só porque ainda existem no domínio social.
7. Instalador: necessidade registrada pelo usuário de automatizar áudio/nome/marca e editar packs incrementalmente. O README atual já descreve WPF/.NET 10, importação DLC/RPF, packs próprios com `.fvpack.json`, edição/rollback e áudio em lote. Não foi auditado/testado nesta síntese; consultar README/PACKS/VALIDATION e código antes de propor como novidade algo já existente.

Próxima ação recomendada: confirmar se a versão com os novos manifests foi carregada e repetir no FiveM os casos de pintura S14 e troca para ER34N; registrar o resultado real, capturar diagnóstico atualizado se falhar e só então encerrar os aceites correspondentes.

## Verificação e fontes para retomar

Nesta sessão de 2026-10-23 houve apenas leitura, preparação e verificação dos arquivos de memória exportados; nenhum teste de aplicação foi reexecutado.

Evidências de 2026-10-21 registram build/typecheck/check/test aprovados; as de ambiente/entrada também registram browser em quatro resoluções. A correção de troca não alterou UI nem reexecutou browser. Todas registram ausência de cliente FiveM e de restart ao vivo nessas entregas. Não declarar servidor validado porque compilou.

Comandos, a partir da base: `npm.cmd --prefix development run build`, `run typecheck`, `run check`, `test`, `run test:ui`, `run test:lobby`; `test:db` é específico de banco. Não há script separado de lint. Não executar migrate/testes de banco sem conferir destino e instruções operacionais.

Fontes locais principais: `docs/architecture.md`, `contracts.md`, `coverage.md`, `backlog.md`, `server-layout.md`, `operations.md`, relatórios de 2026-10-21 e JSON correspondentes em `docs/evidence`. Documentos antigos têm decisões substituídas: conferir código/relatório mais recente.

Histórico de problemas e limites: [[04 Conhecimento/FiveM - Historico e limites de validacao]]. Sessão de consolidação: [[03 Sessoes/2026-10-23 - Sintese do chat FiveM - 221831]].

## Diagnóstico adicional — conexão por Radmin em 2026-10-23

Origem: relato do proprietário e verificações locais por Codex, aproximadamente 23:18 (America/Sao_Paulo). Esta atualização está na cópia exportada no workspace; não foi gravada na base Obsidian compartilhada.

Jogador usa Radmin VPN e fica em “Preparando seu acesso | Aguardando perfil e lobby”, sem erros relatados no F8. TCP/UDP 30120 escutam; HTTP e UDP getinfo respondem localmente pelo endereço Radmin; banco e schema prontos no log. Isso não comprova conectividade do PC remoto. Sem listing override ativo encontrado na configuração consultada. Aviso da lista Cfx relata acesso público e não está confirmado como causa do loading na VPN.

Aviso de demora é timer próprio do loading após 60 s sem sinal. Detalhe da tela confirmado corresponde a progresso de 100% sem atualização posterior do fluxo próprio; ausência do watchdog de perfil sugere investigar inicialização de scripts/sessão e log do cliente, sem causa raiz confirmada. Próximo passo: confirmar conexão direta pelo IP Radmin e coletar log completo da tentativa. Nenhum restart ou alteração operacional realizado. Relatório: `docs/connection-diagnosis-2026-10-23.md`. Sessão: [[03 Sessoes/2026-10-23 - Diagnostico conexao Radmin - 231812]].

## Atualização — oficina e prévias em 2026-10-23, 23:43

Origem: novo relato do proprietário, código e testes por Codex. O jogador conseguiu entrar pela Radmin, mas houve erros ao usar veículos/menus e oficina incompleta na primeira personalização. Corrigidos no código: resultados estruturados nos exports/rotas de Run/ClientCall/Preview/ApplyPreview; carregamento de modelo com 30 s e cancelamento por intenção; prazos externos compatíveis com as etapas; preparação de cena/colisão/modelo/interior antes de revelar a oficina; YTYP explícitos em ps-tuners. Exclusão por jogador, epoch e identidade de entidades preservados.

Build/typecheck, check e regressões novas aprovados. UI e lobby/loading aprovados em quatro resoluções com Chrome instalado. Suíte Lua executa os testes funcionais, mas o comando completo falha no handling ER34N instalado (três subtipos vazios, não alterado nesta tarefa). Nenhum restart ou alteração de banco/rede realizado. Próximo passo: restart completo pelo txAdmin e reteste com cliente remoto, sem afirmar aceite de streaming real. Relatório: `docs/cold-join-preview-2026-10-23.md`; sessão: [[03 Sessoes/2026-10-23 - Entrada oficina e previas - 234338]]. Atualização somente da cópia exportada no workspace, sem gravação na base Obsidian compartilhada.


## Recuperação de drift e ER34N — 2026-10-24

Origem: relato/F8 do proprietário em 24/10/2026, código local e testes por Codex. ER34N com drift salvo falhava em vehicles/apply e bloqueava saída/troca. O usuário autorizou diagnóstico e recuperação de handling opcional sem impedir usar o carro. Corrigido o subtipo CCarHandlingData ausente no arquivo atual do modelo, preservando o bloco principal.

Implementado reset do baseline e uma nova tentativa de drift; falha persistente libera o carro com aviso, mantendo a preferência salva. Estado efetivo, pedido salvo e restauração incerta são distintos. Toggle sem confirmação não grava nem declara sucesso. Identidade, posse, passageiros, ACKs obrigatórios e persistência continuam protegidos; handling incerto bloqueia competição, sem bloquear veículo/treino.

Build/typecheck, check, suíte completa e browser em quatro resoluções aprovados. A pendência do subtipo ER34N registrada em 23/10 foi corrigida no arquivo; o comportamento real continua pendente de restart completo, reconexão e teste FiveM. Não houve restart nem alteração de dados de jogador. Relatório: docs/handling-recovery-2026-10-24.md. Sessão: [[03 Sessoes/2026-10-24 - Recuperacao handling ER34N]].

Esta nota atualiza apenas a cópia exportada no workspace; a base Obsidian compartilhada permanece fora das permissões de escrita da sessão.

## Recuperação de diâmetro/largura — 2026-10-24

Origem: relato/F8 do proprietário e código/testes por Codex, aproximadamente 02:23 (America/Sao_Paulo). SC300A recusou aumento de diâmetro; o erro antes abortava toda a personalização. Implementada recuperação da dimensão efetiva, mantendo os outros ajustes, aviso e bloqueio somente do campo recusado na interface. Limitação por identidade/modelo/conjunto de rodas; troca de rodas permite nova tentativa. Sem blacklist e sem alteração do asset SC300A. Causa específica e suporte real continuam sem confirmação em jogo.

ACK de vehicles/apply informa stance efetivo. Prévia, spawn, edição e salvamento incorporam esse valor; fator recusado não é salvo como aplicado. Presets antigos não são regravados automaticamente ao carregar. Validações de payload, identidade, posse e ACK permanecem estritas. Removida aplicação duplicada de stance.

Suíte completa, 42 verificações de stance, regressões de prévias, build/typecheck/check e browser em quatro resoluções aprovados com natives/transportes simulados. Nenhum restart nem alteração de dados de jogador. Próximo passo: restart completo, reconexão e reteste SC300A com rodas do relato, salvamento/recriação e outro conjunto de rodas. Relatório: docs/stance-wheel-recovery-2026-10-24.md; sessão: [[03 Sessoes/2026-10-24 - Recuperacao diametro SC300A]]. Atualização somente do export local, sem gravação na base compartilhada.

### Complemento de 24/10/2026, 10:40 — rodas já modificadas

O proprietário confirmou rodas modificadas na tentativa. Encontrado e reproduzido com natives simulados bug de referência zero capturada antes da troca e mantida depois, produzindo escala zero recusada pelo setter upstream Cfx. Corrigida inicialização por dimensão na primeira leitura positiva das rodas modificadas, mantendo referência válida estável. Diagnóstico agora registra baseline, solicitado, lido e retorno. Isso não comprova a causa do caso real SC300A nem incompatibilidade do modelo.

Suíte completa e check reexecutados e aprovados; 47 verificações de stance. Sem alteração/reexecução de UI/build neste complemento, sem restart, cliente FiveM ou alteração de dados de jogador. Próximo passo: restart/reconexão e retestar diâmetro com rodas modificadas; coletar novo diagnóstico se falhar. Relatório atualizado: docs/stance-wheel-recovery-2026-10-24.md. Sessão: [[03 Sessoes/2026-10-24 - Baseline zero rodas modificadas - 104032]]. Apenas export local atualizado.

## Registro da oficina na primeira tentativa — 24/10/2026, 10:52

Origem: relato/F8 do proprietário e código/testes por Codex. Ao abrir o servidor, experience/scene falhou porque denis3d_ts_shell não estava registrado; abrir GARAGEM novamente funcionou. O controlador rejeitava imediatamente a ausência no cliente. Manifest/YTYP presentes, sem alteração nesta etapa. Implementada espera por registro dentro dos 30 s já destinados à cena, pedido único somente após registro e mesmas condições de prontidão de modelo/cena/colisão/interior/estabilidade. Ausência permanente, cancelamento e resource indisponível continuam falhando com limpeza.

Suíte completa e check aprovados, incluindo registro tardio, cancelamento e ausência permanente com natives simulados. Sem restart, teste FiveM, alteração de dados ou rebuild de UI. A temporização real do registro não foi medida; o sucesso manual é compatível com atraso de registro. Próximo passo: restart/reconexão e primeira entrada logo após boot. Relatório: docs/scene-registration-2026-10-24.md; sessão: [[03 Sessoes/2026-10-24 - Registro tardio oficina - 105200]]. Apenas export local atualizado; base compartilhada sem permissão de escrita.

## Ferramentas administrativas — 24/10/2026, 11:40

Origem: pedido do proprietário para reduzir dependência do vMenu; prioridade adicional confirmada por ele: teleporte por coordenadas e marcador. Implementados M → Administração → Coordenadas e heading e Teleporte administrativo. Referências ped/veículo/câmera, painel contínuo independente do menu, captura vector3/vector4/tabela com cópia e campo selecionado, modelo/interior/net ID. Viagem aceita X/Y/Z/heading opcional ou marcador com busca de solo limitada a 8 s.

Leitura exige mx.admin + mx.inspect; teleporte exige mx.admin + mx.teleport (nova concessão ao group.mxadmin). Admin controla autorização/leitura e audit, world controla movimento. Painel renova autorização em 2 s e expira em 6 s. Teleporte reutiliza posse/motorista, passageiros, contexto público, reservas, ACK, confirmação de posição e rollback existentes. Coordenadas de captura não são autoridade para mutar entidade. VMenu preservado nesta etapa, substituição gradual.

Build/typecheck/check/suíte completa aprovados; 36 verificações novas de ferramentas, parser e integração do export com viagem real usando natives simulados. Browser aprovado em quatro resoluções; capturas 1280×720 de painel e teleporte inspecionadas. Sem restart, cliente FiveM, teleporte real ou alteração de dados de jogador. Próximo passo: restart/reconexão e validar solo distante, coordenadas/heading, carro sem passageiros, painel no noclip e clipboard no CEF. Relatório: docs/admin-coordinates-teleport-2026-10-24.md; sessão: [[03 Sessoes/2026-10-24 - Coordenadas e teleporte admin - 114032]]. Apenas export local atualizado; Obsidian compartilhado fora da permissão de escrita.

## Posições, câmeras e idles — 24/10/2026, 12:30

Origem: pontos explícitos enviados pelo proprietário e pedido de câmera mais próxima/baixa. Lobby e garagem agora têm personagem e veículo independentes conforme tabela atualizada. Removidos reposicionamento do personagem pelo tamanho do carro e heading voltado automaticamente à câmera. Chão/colisão continuam confirmados sem substituir o ponto fixo; clone externo preserva a posição. Saída para modo livre independente.

Câmeras principais: offset inicial frente 3.8/direita 3.1/altura .85 m sobre carro, FOV 60, ajuste por projeção mantendo altura baixa e ambos no quadro. Câmeras de detalhes preservadas. Idle por sexo real do ped/clone, quatro candidatos livres por sexo, variação 18–32 s sem repetição consecutiva, carregamento opcional com limite e diagnóstico. Pose feminina de parede configurável mas desligada nos pontos livres. Pausa em rosto/personagem/modal, limpeza ao sair/modelo/clone; não animar motorista invisível da personalização.

Suíte completa/check aprovados, incluindo 111 verificações de geometria/idle e execução da função real de posicionamento. Sem alteração de NUI, rebuild/browser, cliente FiveM, restart ou dados de jogador. Próximo passo: restart/reconexão, conferir pontos, câmera baixa e vários ciclos male/female, clone durante customização e veículo grande. Relatório: docs/menu-poses-idles-2026-10-24.md; sessão: [[03 Sessoes/2026-10-24 - Poses cameras e idles - 123000]]. Apenas export local atualizado; base compartilhada sem escrita permitida.

## Editor de câmera no jogo — 24/10/2026, 12:54

O proprietário confirmou explicitamente o Drift como destino desta ferramenta, apesar da aba do IDE estar no NativeCore. Nenhum arquivo NativeCore alterado. Implementado DEV · CÂMERA no lobby/garagem e comando F8 mxcamedit. Usa a câmera atual; WASD/QE, mouse, velocidade/precisão, campos de posição/rotação e FOV. Captura Lua com contexto/visão/posição/rotação/mira/FOV, tentativa de clipboard, texto selecionado/Ctrl+C e F8. Restaurar, manter prévia temporária ou fechar sem alterar config/banco.

Exige mx.admin + mx.inspect no servidor, permite a cena privada, lease renovado 2 s/expiração 6 s, cancelamento por cena/ownership/permissão. Inputs isolados dos atalhos/motor da oficina. Corrigido override de FOV principal 49 para usar o 60 configurado na cena. Build/check/suíte completa aprovados, 23 verificações novas de controlador e movimento em múltiplos FPS; browser completo e teste final dedicado aprovados em quatro resoluções. Captura 1280×720 inspecionada. Sem restart, cliente FiveM, validação real de clipboard ou alteração de dados.

Próximo passo: reiniciar/reconectar, ajustar lobby e garagem e enviar os blocos capturados para aplicação permanente. Relatório: docs/camera-developer-2026-10-24.md; sessão: [[03 Sessoes/2026-10-24 - Editor camera in game - 125427]]. Memória somente no export local; base compartilhada sem escrita permitida.

## Resmon e modo do cliente — 24/10/2026, 13:35

O proprietário pediu modo desenvolvimento para resmon. Conferido: server.cfg do Drift já carrega config/development.cfg; base configurada para Legacy build 3258. Documentação oficial exige iniciar cliente Legacy com +set moo 31337 para comandos de desenvolvimento; sv_devMode é mecanismo específico do Enhanced, não aplicado aqui.

Criado iniciador FiveM-Desenvolvimento.cmd na raiz do workspace. Resolve instalação padrão ou aceita arrastar FiveM.exe sobre ele; valida caminho e orienta fechar cliente anterior. Versão intermediária PowerShell descartada após política de execução bloquear VerifyOnly; política não alterada, teste não executado. CMD revisado, sem lançamento de FiveM. Não altera canal, CitizenFX.ini ou configuração do servidor. Caminho real do cliente não localizado, resmon em jogo ainda não confirmado.

Próximo passo: fechar FiveM, executar iniciador (arrastando FiveM.exe se necessário), conectar e F8 resmon true (resmon false para fechar). Relatório: docs/resmon-development-2026-10-24.md; sessão: [[03 Sessoes/2026-10-24 - Resmon cliente desenvolvimento - 133500]]. Apenas export local atualizado.

## Correção do editor de câmera — 24/10/2026, 13:55

Origem: proprietário relatou zoom/salto com mínimos ajustes. Editor agora inicia câmera independente a partir da pose/FOV renderizados antes de cancelar transições. Cada ajuste escreve somente os parâmetros alterados, com floats explícitos. Mouse 0.04 grau/pixel (Ctrl 0.01), movimento padrão 0.25 m/s; campos aplicam valor completo em Enter/blur. Arraste cancelado em blur/cancel/soltura e wheel numérico bloqueado.

Build/typecheck/check/suíte completa e browser dedicado em quatro resoluções aprovados. Regressões cobrem handoff com interpolação, alteração de 1 cm sem zoom/rotação, campos parciais, Enter, incremento e mouse. Sem restart ou FiveM; causa visual exata ainda depende do renderer real. Próximo passo: reiniciar/reconectar, verificar lobby e garagem e capturar composições. Relatório: docs/camera-developer-2026-10-24.md; sessão: [[03 Sessoes/2026-10-24 - Correcao editor camera - 135500]]. Somente export local atualizado; base compartilhada sem escrita permitida.

## Câmeras principais aprovadas — 24/10/2026

Origem: proprietário enviou as capturas e pediu aplicação por ora. Config ExperienceConfig.mainCameras: lobby posição (-955, -3532.6, 14.5), rotação (-1.5, 0, -100), FOV 66.5; garagem posição (138.5, -3025.5, 7.2), rotação (-2, 0, 141), FOV 60. Look capturado preservado. Principais fixas, sem reenquadramento automático; câmeras de detalhe continuam no comportamento existente. Retorno da órbita restaura rotação explícita.

Suíte completa/check aprovados com regressão dos dois presets no controlador real e natives simulados. Sem restart ou FiveM. Próximo passo: reiniciar/reconectar e conferir as duas cenas. Relatório: docs/camera-developer-2026-10-24.md; sessão: [[03 Sessoes/2026-10-24 - Cameras aprovadas lobby garagem - 141500]]. Somente export local atualizado; base compartilhada sem escrita permitida.

## Tunagem: câmeras, portas, motor e stance — 24/10/2026

Origem: pedido e logs do proprietário. Corrigida rejeição de diâmetro/largura quando native retorna 1 com readback correto; true/1 agora aceitos, geometria divergente continua rejeitada. VStancer WheelModScript consultado, mesmos natives visuais, sem importação de código/resource ou mudança de colisores. Prévia de stance local, sem debounce/round-trip de servidor, com guards de sessão/preview/caller/ownership; confirmação e salvar permanecem existentes. Timers cancelados não atrasam novas prévias.

Detalhes focam bones válidos/fallback com distâncias específicas e peça a 38% da altura da tela. Órbita permite vista baixa sem atravessar o piso de referência/carro, com opções ocultas inicialmente e H/botão para alternar. Presets principais aprovados preservados. Portas interpoladas 650 ms e reversão do ângulo atual. Motor usa motorista real invisível já existente, controle/acelerador nativo habilitados temporariamente e nenhum RPM/limitador artificial. Sem delay extra após ACK de motor; inatividade 15 s, gatilho e release preservados, restauração de controle ao sair.

Build/typecheck/check/suíte completa aprovados; 50 verificações de stance e regressões de integração/geométricas com natives simulados. Browser em quatro resoluções; sem FiveM, restart ou banco real. Próximo passo: reiniciar/reconectar e confirmar som/RPM, portas, bones de mods, órbita baixa e rodas. Relatório: docs/tuning-cameras-engine-stance-2026-10-24.md; sessão: [[03 Sessoes/2026-10-24 - Tunagem cameras motor e stance - 144800]]. Memória somente no export local, base compartilhada sem escrita permitida.

## Interface da câmera livre — 24/10/2026, 14:56

Verificação final: browser completo aprovado em quatro resoluções (1280×720, 1920×1080, 2560×1440 e 3440×1440) com opções visíveis por padrão e H nos dois sentidos.

Origem: proprietário confirmou melhora da câmera livre, mas a interface oculta impedia editar opções. Corrigido padrão do VehicleEditor: opções visíveis/editáveis em toda ativação; H/botão oculta somente por escolha explícita. Movimento/limites da câmera preservados. Build/typecheck/check aprovados, regressão de browser cobre abertura visível, H nos dois sentidos e navegação enquanto orbita. Sem restart ou FiveM. Próximo passo: carregar NUI atualizada e conferir edição com câmera livre. Não há confirmação do usuário sobre motor/portas/stance nesta resposta. Relatório: docs/tuning-cameras-engine-stance-2026-10-24.md; sessão: [[03 Sessoes/2026-10-24 - Interface editavel na camera livre - 145600]]. Somente export local atualizado; Obsidian compartilhado sem escrita permitida.

## Novas posições do lobby — 24/10/2026, 15:01

Origem: coordenadas enviadas pelo proprietário. Personagem agora (-947.610,-3530.367,14.618), heading 185.96; veículo (-949.431,-3533.159,13.953), heading 280.67. Config e verificações existentes atualizados; suíte completa/check aprovados. Câmera principal permanece fixa no preset (-955,-3532.6,14.5), rotação (-1.5,0,-100), FOV 66.5; não acompanha automaticamente a nova composição. Sem restart ou FiveM. Próximo passo: carregar e conferir enquadramento; nova captura pelo mxcamedit somente se necessário. Sessão: [[03 Sessoes/2026-10-24 - Novas poses do lobby - 150100]]. Somente export local, Obsidian compartilhado sem escrita permitida.

## Rodas salvas no spawn e nova câmera — 24/10/2026, 15:58

Proprietário confirmou diâmetro editável; aplicação visual no spawn relatada como tardia. Corrigidos ordem e refresh: descoberta de capacidades agora reafirma stance após percorrer/restaurar famílias, e o loop visual reaplica dimensões personalizadas aceitas mesmo quando getters já coincidem. Sem composição de fatores ou mudança de persistência; identidade/modelo/rodas modificadas/limitações continuam protegidos. Nova regressão executa stance+descoberta reais com malha separada de getters, frio/quente, dimensões e handle reutilizado. Suíte completa/check aprovados; sem FiveM, restart ou banco.

Câmera principal do lobby agora posição (-944.5,-3535.3,14.5), rotação (-2,0,51), look (-948.794,-3531.823,14.307), FOV 73.5, conforme nova captura enviada. Próximo passo: carregar/reconectar e conferir rodas imediatamente ao spawn sem tocar em Suspensão e câmera do lobby. Relatório: docs/stance-spawn-2026-10-24.md; sessão: [[03 Sessoes/2026-10-24 - Rodas salvas no spawn e camera lobby - 155800]]. Apenas export local, Obsidian compartilhado sem escrita permitida.

## Interface oculta nas transições — 24/10/2026, 16:10

Verificação final: build/typecheck/check e browser de lobby/loading repetidos após ajuste final do handoff inicial, aprovados em quatro resoluções. Browser geral aprovado antes desse ajuste. Captura de loading preto sem UI inspecionada; FiveM ainda pendente.

Origem: proprietário aprovou os fades pretos e pediu ocultar interface nos carregamentos. Ponte do menu acompanha fades nativos (0/1 ou booleanos), NUI combina com sua máscara de troca de telas/loading inicial. Raiz React invisível até ambos terminarem, sem desmontar telas/limpar campos ou seleção. Foco restaurado ao revelar; teclado, ponteiro e navegação de controle bloqueados durante ocultação. LoadingClosed obsoleto não encerra outra transição; abas internas sem novos fades.

Build/typecheck/check/suíte completa aprovados, regressões da ponte e browser de lobby/navegação em quatro resoluções com transportes simulados. Sem FiveM, restart ou dados de jogador. Próximo passo: reiniciar/reconectar e conferir lobby/garagem/modo livre. Relatório: docs/transition-interface-2026-10-24.md; sessão: [[03 Sessoes/2026-10-24 - Interface oculta nas transicoes - 161000]]. Somente export local; base Obsidian compartilhada sem escrita permitida.

## Consulta sobre exposição de sete carros — 24/10/2026, 16:16

Proprietário enviou sete pontos na oficina para possível exposição dos veículos salvos e pediu somente explicação sobre desempenho/otimização, sem implementar. Pontos preservados em [[03 Sessoes/2026-10-24 - Consulta exposicao de carros na oficina - 161600]]. Pesquisa primária: rooms/portals MLO, LOD por entidade/escala global e foco de streaming existem; bucket não descarrega mapa base. Pack da oficina ainda sem auditoria de rooms/portals e sem benchmark. Foco temporário já existe no preparo de scene-streaming.lua, não equivale a recorte permanente do exterior.

Proposta para eventual etapa autorizada: veículos locais/inertes, LODs adequados e carregamento gradual, avaliar oclusão do interior e comparar 1/3/7 carros em FPS/GPU/memória de streaming e resmon. Nenhum script/configuração alterado ou veículo criado nesta consulta. Obsidian compartilhado sem escrita permitida; somente export local.

## Exposição local na oficina autorizada e implementada — 24/10/2026, 16:35

Origem: proprietário confirmou MLO e autorizou implementar os sete pontos como cenário não interativo. Até sete presets locais, excluindo o salvo da bancada, carregados gradualmente somente na garagem privada. Aparência/stance salvas, sem física/colisão/motor/neons, LOD por entidade 55 m e escala temporária de LOD estendido 0,8 durante a garagem. Exposição não altera progresso/salvos. Consulta limitada por dono/contexto/token/epoch, sem polling; atualização por revisão/seleção, reuso de slots e limpeza com identidade e orçamento de entidades preservado mesmo em falhas repetidas de deleção.

F8 `mxdisplay 0..7` para comparar/desligar/recarregar localmente; `mxdisplayinfo` para estado. Configuração `ExperienceConfig.display.enabled=false` desliga exposição e ajuste de LOD. Testes completos e check aprovados com adaptadores, sem cliente FiveM, restart, banco real ou nova NUI. Custo gráfico de sete mods permanece pendente de medição; MLO/portals não auditados ou editados. Próximo passo: reconectar com recursos atualizados, comparar 0/1/3/7 carros, conferir posições/rodas/limpeza e FPS/GPU/streaming além do resmon. Relatório: docs/workshop-display-2026-10-24.md; sessão: [[03 Sessoes/2026-10-24 - Exposicao local de carros na oficina - 163500]]. Somente export local; Obsidian compartilhado sem escrita permitida.
