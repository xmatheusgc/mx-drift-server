# Drift server FiveM

Atualizado em: 2026-10-23.
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

Fonte: `resources/[mx]/mx-freeroam-experience/config.lua`, lido em 2026-10-23. Pontos independentes; não alterar um para mover o outro.

| Contexto | X | Y | Z | Heading |
| --- | ---: | ---: | ---: | ---: |
| Lobby | -949.47 | -3533.03 | 13.94 | 274.72 |
| Apresentação da garagem | 135.9 | -3030.47 | 6.4 | 359.72 |
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
