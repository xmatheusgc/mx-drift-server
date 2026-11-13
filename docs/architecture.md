Atualização 17/10/2026: [teclado e mouse, Customizar, ações visíveis, câmeras e suspensão](customization-input-stance.md). Este incremento prevalece para input, F9/F10, rolagem e presets de câmera descritos anteriormente.

Incremento atual de lobby/garagem/câmeras: [implementação, contratos, evidências e validações pendentes](lobby-navigation.md). Schema 006; entrada inicial pelo lobby. Esta nota prevalece para esses fluxos sobre descrições anteriores.

Atualização 16/10/2026: dez resources. Personagem/apresentação passaram a experience; world conserva respawn/reservas. Drivecam é local e usa o contrato de posse de experience. Detalhes dos dois módulos e das novas tabelas em [experience.md](experience.md).

# Arquitetura adotada

Dez resources conhecidos, no mesmo repositório, permitem reiniciar apresentação, presença e progressão sem tratar todos os domínios como um framework. A NUI não contém SQL nem autoridade. Não existe registro dinâmico de plugins nem um objeto de jogador com estados internos de todos os sistemas.

| Resource | Dados e responsabilidade | Dependências obrigatórias |
| --- | --- | --- |
| core | `players`, `player_preferences`, identidade, loading, consultas/transações, RPC, rate limit e exclusão de operações por sessão | oxmysql |
| world | Destinos em arquivo, slots/reservas transitórios, reservas de entrada, respawn, viagem, mundo e bloqueios de combate | core |
| vehicles | Catálogo em arquivo; `garage_presets`, `player_favorites`; entidades, edição/preview, responsabilidade e assinatura nativa | core, world |
| social | Grupos, convites, anúncios e presença transitórios; filtros de divulgação e chat | core, world |
| activities | `track_versions`, `activity_results`, `activity_delivery`; estados, relógio, checkpoints, duelos e telemetria | core, vehicles, world |
| progression | `xp_ledger`, `player_progression`, `achievement_progress`, `weekly_challenges`, `challenge_claims`, `progression_receipts`; seleção de ícones/títulos | core |
| admin | `audit_log`, captura de conteúdo, ações ACE; chama contratos dos outros domínios | core |
| experience | player_experience/player_appearance/experience_operations; onboarding, personagem, seleção, apresentação privada e posse local | core, world, vehicles |
| drivecam | Preferência KVP, câmera local, matemática e colisões; nenhum SQL ou rede por quadro | core, experience |
| menu | React/TS, navegação, foco único, notificações e HUD local; não é obrigatório para o núcleo | core |

O core não chama nenhum domínio e não consulta suas tabelas. As preferências de apresentação/contato não conferem direitos. Ícones, títulos e desbloqueios são gravados/validados exclusivamente em progression. World e vehicles chamam a invalidação de activities somente se ela estiver disponível. Social consulta os dados públicos da progressão por export opcional; sem ele usa marcador inicial e nível 1. Essas integrações não criam dependência circular de ensure.

## Ciclo de uma operação

Identidade `license` é única no banco e permanece privada. Source é apenas a conexão atual; `playerJoining` transfere o perfil carregado do ID de conexão para o definitivo. Cada sessão tem um epoch para impedir resposta atrasada a um source reutilizado. Banco/migrations ausentes fecham a entrada: não há fallback para perfil vazio. Uma segunda conexão da mesma identidade é recusada.

Requests passam por limites de tamanho/tipo, rate limit, requestId recente e trava por conexão/epoch. As mutações privadas usam o ID interno da identidade autenticada, nunca um autor fornecido pelo payload. Queries são parametrizadas. A operação libera a trava tanto em sucesso quanto em erro.

Spawn recebe um modelo de catálogo ou ID privado de preset. World reserva um slot próximo aprovado e livre; vehicles cria o carro no servidor, atribui UUID da operação e espera carregamento/aplicação com confirmação. O anterior só é removido depois de sucesso, sem passageiro. Timeout elimina a tentativa de carro novo e preserva o anterior. ID da operação é distinto de placa e net ID. Um carro por perfil é o default; `maxActivePerPlayer` aceita 1..3 e substitui o mais antigo quando cheio. Dirigir outro carro da própria frota seleciona esse carro para serviços/atividade. Limite de presets, cooldown e catálogo também são configuráveis.

Edição guarda snapshot confirmado e preview separado. Aplicar confirma o carro; Salvar é a gravação persistente. Cancelar, fechar, timeout ou stop tenta restaurar o snapshot local e no owner. Opções são descobertas por native e reavaliadas no preview; valores fora do schema são rejeitados no servidor. Extras padrão do modelo são normalizados na confirmação do spawn. Assinatura versionada inclui rodas/pneus e mods de desempenho permitidos; cores não dividem ranking.

## Resultado e entrega durável

Activities valida a sessão com relógio monotônico, motorista, veículo estável, modelo, assinatura, bucket, condições, sequência e interseção de segmentos. A observação client de mods é diagnóstica e pode invalidar divergências; não substitui os checks do servidor. Dados de sincronização insuficientes encerram sem punição automática.

Ao terminar, activities escreve resultado e `activity_delivery` na mesma transação, com UUID único. Antes da query registra um diário local de resultados; se o banco falhar, a UI anuncia pendência e nenhum prêmio é confirmado. O diário é reenviado de forma idempotente. Se banco e disco falharem, a mensagem é de resultado não confirmado. Não existe garantia de durabilidade sob falha simultânea dos dois meios ou perda abrupta antes do diário.

Progression consulta `activities:Pending`, grava ledger/conquista/claim/recibo em uma transação e chama `Acknowledge`. Uma falha entre commit e ack repete o processamento sem duplicar a origem única. A revogação volta a entrega para pendente; uma atualização de ack condicionada ao estado revogado evita consumir a revisão errada. O worker pode voltar depois de um período desligado. Eventos internos apenas aceleram o worker; o backlog está no banco.

A política inicial concede 100 XP uma vez por perfil/pista/revisão/direção e 50 XP por desafio semanal habilitado. Não há XP por tempo conectado, distância irrestrita, AFK ou drift experimental. Revogação gera uma compensação negativa única por concessão original, conserva histórico e recalcula conquistas. Uma origem revogada não é premiada outra vez nem transferida retroativamente para outro resultado; claims semanais permanecem como histórico. Total/cache pode ser reconciliado a partir do ledger.

## Restart e limpeza

| Resource | Política |
| --- | --- |
| core / oxmysql | Reinício coordenado do servidor recomendado. Core derruba conexões para recarregar identidade; não promete hot reload universal. |
| world | Libera freezes locais; entrada/respawn reobtém perfil e slot. Activities invalida sessões quando a dependência para. Alterações de mundo exigem nova revisão operacional. |
| vehicles | Cancela previews locais; sessões tornam-se inválidas. Apaga somente carros próprios vazios; ocupados entram em aposentadoria até desembarque. Um diário transitório confirmado pelo boot do core conserva a responsabilidade no restart isolado. Nunca se usa só uma state bag replicada como autorização para apagar. |
| social | Grupos/convites são encerrados; clientes limpam blips. Novo snapshot recompõe presença em até 1 s. |
| activities | Encerra/invalida sessões, solta freeze e ghosting, conserva resultados/entregas e carrega diário pendente. Corrida em curso não é retomada. |
| progression | Ledger e fila permanecem; worker reprocessa ao voltar. Não impede garagem/treino. |
| admin | Perde apenas rascunho ainda não exportado; JSON exportado e auditoria permanecem. |
| menu | Libera foco/cursor/controles; ao voltar solicita perfil. Não controla regras do mundo. |

Diários `*.local.json` não são arquivos públicos da NUI e não entram no Git. A aposentadoria de entidades é válida apenas durante o mesmo boot do core, com handle, net ID, modelo e operação conhecidos pelo servidor; net IDs nunca são tratados como persistência entre reinícios do FXServer. A perda de disco durante stop exige revisão operacional ou restart completo.

Restart sem clientes foi verificado. Limpeza com passageiros, owner migration e foco em clientes são aceites ainda pendentes.

O FiveM também para dependentes obrigatórios: reiniciar vehicles para activities; reiniciar world pode parar vehicles, activities e social. Depois de iniciar a dependência, use `ensure` nos dependentes na ordem documentada. `restart` não inicia um resource já parado. Esse comportamento foi observado no ensaio e não é hot reload automático de toda a cadeia.

## Componentes de apresentação compartilhados

A NUI usa ControlHints/ControlGlyph, TabBar, OptionStrip, ConfirmDialog, SettingsRow e StancePanel. Modais possuem seleção lógica própria; faixas usam a mesma rolagem ancorada. A fila cosmética do editor deve encerrar antes de invalidar a geração do modelo. O domínio world permanece o escritor único do clima/relógio; experience solicita overrides locais e restaura ao sair. Persistência de opções confirmadas continua nos contratos de vehicles + journal de experience; core não recebe regras novas.


## Trainer do modo livre

O menu compacto usa os componentes visuais compartilhados. Noclip e checkpoint pertencem a world; posse e servicos de carro pertencem a vehicles; retorno privado pertence a experience. Core permanece inalterado. Ver [implementacao e limites](freeroam-trainer-2026-10-18.md).
