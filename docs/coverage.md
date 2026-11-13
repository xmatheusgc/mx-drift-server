Atualização 17/10/2026: [teclado e mouse, Customizar, ações visíveis, câmeras e suspensão](customization-input-stance.md). Este incremento prevalece para input, F9/F10, rolagem e presets de câmera descritos anteriormente.

Incremento atual de lobby/garagem/câmeras: [implementação, contratos, evidências e validações pendentes](lobby-navigation.md). Schema 006; entrada inicial pelo lobby. Esta nota prevalece para esses fluxos sobre descrições anteriores.

Atualização atual da personalização: [heat-customization.md](heat-customization.md) prevalece para barra inferior, prévia/rascunho, órbita, motor e personagem. Esses aceites continuam pendentes no jogo.

Atualização de interface/entidades de 16/10/2026: [interface-rework.md](interface-rework.md) registra os controles de freeroam, coordenadas temporárias, fluxo de prévias e evidências anteriores de UI. Os aceites de jogo continuam pendentes.

Atualização 16/10/2026: nova experiência em dois resources adicionais e migration 005. Veja [cobertura específica](experience.md). A matriz abaixo registra o escopo inicial e suas verificações anteriores; aceites de jogo continuam pendentes.

# Relatório de cobertura — 15/10/2026, America/Sao_Paulo

Atualização de instalação em 16/10/2026: base transferida para `txData/FiveMBasicServerCFXDefault_CAECC7.base`, integrada ao server.cfg do perfil existente, com porta 30120. Evidência específica e backup em [txadmin-migration.md](txadmin-migration.md). Os testes de gameplay pendentes abaixo permanecem pendentes.

**Entregue:** código standalone original em oito resources; NUI React/TS compilada com assets locais; quatro migrations ordenadas; configurações development/production/rede/voz/ACE; dependências pontuais instaladas e fixadas; banco novo com usuário runtime limitado; scripts de instalação, backup e restore; contratos, arquitetura e backlog T01–T40.

**Verificado:** build strict, fronteiras de módulo, análise sintática Lua, 43 regras objetivas, MariaDB real, boot FXServer 37175, 14 cenários persistentes via exports no runtime, restore integral de dez tabelas e shell NUI em três resoluções. A simulação de presença usa 20 identidades sintéticas e não envia rede.

**Não verificado no jogo:** zero clientes FiveM conectados. Entrada visual, reconexão FiveM, natives de personalização, colisões, owner migration, gamepad/foco, presença distante, duelo, voz e resmon permanecem pendentes. Os três destinos e a pista são rascunhos. Não houve publicação do servidor, ativação de packs antigos ou aprovação de desempenho.

| Requisito | Implementação | Evidência disponível | Aceite pendente |
| --- | --- | --- | --- |
| F01 Perfil/entrada/personagem | Identidade privada única, deferral fail closed, epoch, prefs CAS, roupas aprovadas, entrada/respawn por slot, loading screen e regras de mundo | SQL, boot e análise | Entrada/reconexão/morte; validação geográfica e cliente |
| F02 Catálogo/ciclo do carro | Allowlist/filtros/favoritos, criação server, reserva/trava/cooldown, UUID, ack e anterior preservado; aposentadoria respeitando ocupantes | Schema/regras, boot | Spawn duplo, owner migration, timeout real e passageiros |
| F03 Garagem/personalização | Schema nativo, capacidades por modelo, snapshot/apply/cancel, readback básico, CRUD privado com revisão, assinatura de competição | Regras, SQL/CAS/reconexão SQL e restore | Todas as propriedades no carro e reconexão FiveM |
| F04 Destinos/recuperação | Destino aprovado por ID, slots livres, ped/carro próprio, sem passageiros, colisão/rollback, recuperação server e invalidação | Código/boot | Coordenadas, colisão, dois clientes e capotamento |
| F05 Presença/blips/ícones | Posição sincronizada do server além do streaming; filtro de bucket/share/grupo/none antes do envio, região privada, epoch/TTL, sprites/cor/nível, uniformes | Regras reais e 240 mil decisões sintéticas | Streaming, bucket e privacidade de payload no jogo |
| F06 Social | Convites válidos/únicos, líder/grupo, encontros, anúncio ACE, chat e pma-voice opcional, AFK sem XP, mute local | Boot e regras | Duas pessoas, áudio e consentimento/contato |
| F07 Pistas/treino/tempo | Definição/rascunho/captura/ativação/revisão, máquina server, monotônico, segmento/direção/CP, sync/car/bucket, resultado/outbox e ranking comparável | Regras e persistência no runtime | Rota legítima, CP perdido, largada, latência e replay de rede |
| F08 Duelo | Convite com regras, mesmo modelo/preparação, contagem compartilhada, sem bucket extra, ghost local entre pilotos, tempo/empate/forfeit | Código e análise | Dois pilotos, colisão e limpeza de ambos |
| F09 Drift | Treino de rota, duração/distância, CP/fim/manualstop, telemetria técnica versionada/limitada e retenção; nenhuma fórmula oficial ou XP de habilidade | Regras de exclusão de drift do prêmio testadas no runtime | Telemetria e trajeto reais; nenhuma pontuação a calibrar foi inventada |
| F10 Progressão | Ledger/cache reconciliável, níveis, primeira rota, conquista, direitos cosméticos, semana UTC, claim único, outbox e compensação | Runtime com progressão parada/voltando, duplicação, semanal/expiração, bloqueio, compensação/restart | Resultado originado de corrida real e visualização cosmética |
| F11 HUD/preferências | Velocidade/unidades, marcha/RPM disponíveis, escala/volume, foto local, prioridade da sessão, clima global fixo/revisionado | Build, SQL e browser | Natives, foco/controles e custo real |
| F12 Administração/operação | ACE por ação, comandos/inspeção/captura/audit, revogação/compensação, diagnósticos, restore e política de atualização/retenção | Runtime, SQL e backup/restore | Negação a jogador comum e ferramentas no jogo; txAdmin do perfil novo |
| F13 Segurança/consistência | Schemas/finitude/limites, rate/trava, dono/CAS, IDs únicos, SQL parametrizado, React escapando conteúdo, source/epoch, lockdown, falha explícita e cleanup | Regras, SQL, static, runtime | Abuso por cliente e compatibilidade física/multiplayer; não é anticheat completo |

## Limites e escolhas explícitas

- A aplicação não usa mocks ou bancos em memória. Fixtures existem somente no resource de teste, restrito a banco de teste e fora do ensure público; não comprovam uma corrida ou cliente real.
- MariaDB é o alvo testado. Compatibilidade MySQL 8 não foi afirmada. Aplicação e ensaios usam bancos separados; o banco alheio preexistente foi preservado.
- O default é um carro gerenciado por jogador. `maxActivePerPlayer` permite 1..3; ao atingir o limite substitui o mais antigo após confirmação. O carro próprio atualmente dirigido se torna o selecionado para serviços/sessão. Valores acima de 1 também exigem ensaio com ocupantes; não foram testados no jogo.
- Presença usa snapshot por coordenadas com metadados mínimos a 1 Hz, sem alternar para blip por entidade nem implementar deltas separados. Isso cobre remotos sem forçar streaming; medição real continua necessária.
- Telemetria client e simulação sincronizada não tornam resultados à prova de cheats. A assinatura canônica é do servidor; observações client detectam divergências legítimas, mas um client adulterado pode mentir sobre natives. Os limites não concedem punição automática.
- O readback de aplicação confere cores/mods principais; consistência de extras, pinturas e iluminação entre owners precisa dos testes client especificados. Cancelamento/falha faz rollback por native e pode falhar se a entidade desaparecer.
- Diário de resultados cobre indisponibilidade de SQL com disco disponível. Falha simultânea de disco/banco não é apresentada como sucesso; queda abrupta no instante anterior ao diário não tem garantia inventada.
- Não foi implementada fórmula experimental de drift. Telemetria e revisão de instrumentação formam a infraestrutura; pontuação competitiva/estratégias de julgamento continuam explicitamente desativadas e dependem de calibração humana futura.
- Conteúdo de desenvolvimento não é conteúdo aprovado para produção. Perfis production recusam rascunhos, e o exemplo semanal está desligado. Não há tempo alvo difícil inventado para Sandy.
- Publicação, porta externa, voz real e carga com 20 jogadores não foram executadas. O aviso de listagem Cfx no ensaio local não foi interpretado como conectividade pública verificada.
- A auditoria npm residual está limitada às ferramentas de teste Fengari/sprintf-js, registrada em decisions.md. O vendor de banco foi trocado pela distribuição mantida e retestado.

## Primeiro marco e próximos aceites

O fluxo foi escrito e a parte verificável sem client passou: migrations → perfil/prefs SQL → menu compilado → contrato de carro → propriedades validadas → preset privado/CAS → recuperação por outra conexão SQL. O boot correspondente foi executado antes de acrescentar os demais incrementos. **O marco de entrar, dirigir, salvar e reconectar no FiveM não foi marcado como aprovado.** O roteiro exato está em testing.md e as tarefas dependentes de client continuam J no backlog.

Próximos testes necessários: cliente inicial com a base limpa, segundo cliente para ocupantes/presença/duelo/voz, validação geográfica e publicação de revisão, baseline resmon/profiler e ensaio real de 20 pessoas. Handlings, física, câmbio manual e julgamento final de drift continuam fora desta entrega.
# Atualização: editor Heat

Barra inferior por teclado, prévia separada do rascunho, órbita, mapa de peças e representação externa local implementados. Ver [heat-customization.md](heat-customization.md) para evidências e limites. Aceite de áudio real com veículo congelado, motorista oculto, solo, enquadramentos e restauração permanece **pendente no jogo**; testes de contrato/geometria/SQL não aprovam esses comportamentos.

## Oficina, confirmação e lobby com neblina

Implementação, causas identificadas, regressões e limites em [workshop-polish-2026-10-17.md](workshop-polish-2026-10-17.md). Confirmação agora persiste; as descrições anteriores de salvamento manual são históricas. Evidências de navegador e SQL não aprovam entidades, câmeras ou controle físico dentro do FiveM.


## Trainer do modo livre (2026-10-18)

Interface, atalhos M/F2/F3/F4, noclip autorizado, checkpoint pessoal, servicos em movimento e retorno direto a garagem implementados. Testes de controlador e browser usam adapters/fixtures explicitos; nao comprovam movimento, colisao, foco nem sincronizacao no FiveM. [Relatorio e verificacoes pendentes](freeroam-trainer-2026-10-18.md).


## Correcao do retorno a garagem e trainer sem mouse

Desembarque coordenado, espera por posicao replicada, recuperacao do carro/controles, erro descritivo e foco apenas de teclado no trainer. [Fluxo, contratos e limites](trainer-entry-recovery-2026-10-18.md). Lobby e garagem preservam o mouse.


## Noclip e checkpoint: revisao atual

Oito velocidades, modo fixo/camera, Shift/Q/Z/H e apresentacao translucida. Checkpoint restaura inclinacao sem condicionar retorno a colisao carregada; viagens comuns mantem suas regras. [Implementacao, referencia vMenu e limites](noclip-checkpoint-2026-10-18.md).
# Incremento de trainer — 2026-10-18

R para reparo; Controles com 18 ações atribuíveis, remoção, teclado e controle; Pilotagem livre; Pistas por categoria; captura administrativa de teleportes; indicadores separados; warning/kick/ban com ACE no servidor e persistência de banimentos por licença. Fixture temporária explícita em desenvolvimento. Detalhes e limitações em `trainer-management-2026-10-18.md`.

Regressões de produção com adaptadores para autorização, source/epoch reutilizados, falha de disco, recarga, remoção/conflito de binds e alvos mockados. Browser usa transporte simulado. Requer validação física de teclado/controle e ensaio FiveM com duas contas para moderação/conexão e rede. Não houve moderação real nem reinício do servidor durante a implementação.

# Opções do veículo e drift — 2026-10-18

Seção agrupada, portas com seletor lateral e execução separada, trava, expulsão de outros ocupantes, recriação coordenada com dono ao volante, disponibilidade contextual e preset reversível autorizado. Cobertura automatizada de módulos reais com adaptadores e interface renderizada; física/rede/duas contas continuam dependentes de FiveM. Detalhes em `vehicle-options-drift-2026-10-18.md`.

# Correção de atualização do handling — 2026-10-18

Releitura de atributos agora ocorre após reconstrução da transmissão e atualização das rodas motrizes. Teste independente compara os 51 campos de runtime ao XML fornecido; regressões cobrem caches simulados, marcha/tração originais, reparo e ownership. Comando `mxhandling` permite inspecionar divergências no carro real. Física ainda não validada no FiveM; ver `drift-runtime-refresh-2026-10-18.md` e a particularidade Min 1.30 > Max 1.07 do XML original.


# Noclip, drift persistente e câmera nativa ? 2026-10-18

Corrigida sessão nula entre frames, Shift genérico/esquerdo/direito e conflito cinematográfico R/B. Drift persiste por criação salva, inclusive após despawn; rollback em falha SQL, nova leitura no spawn e identidade de criação na oficina. Migration 007 aplicada no MariaDB local, seis criações existentes preservadas; persistência ON/OFF em novas conexões SQL validada em banco isolado. Build/typecheck/check/regressões aprovados. Natives, física, controles reais e reconexão/reinício FiveM continuam pendentes. Relatório: `noclip-persistent-drift-2026-10-18.md`; evidências JSON correspondentes.

# Pistas: confirmação direta e colisão - 2026-10-18

Removido o submenu a pé/com carro; servidor decide o transporte. Viagens para pistas não dependem de HasCollisionLoadedAroundEntity. Testes reais de módulos com adaptadores cobrem transporte automático, payload legado, proteção de ocupantes, falha de native, restauração e reservas. Build/typecheck/check/test aprovados; browser exercita confirmação direta com transporte simulado. Streaming e rede continuam pendentes no FiveM. Detalhes: `track-direct-teleport-2026-10-18.md`.

# ER34N e trainer - 2026-10-19

Correção posterior de travamento na troca: [recuperação de respawn — 2026-10-21](trainer-switch-recovery-2026-10-21.md). Saída com portas destrancadas, rollback local, watchdog e tokens de operação cobertos por testes com adaptadores. Troca S14 → ER34N no jogo permanece pendente.

Ambiente sincronizado agora dinâmico: [ciclo de horário/clima — 2026-10-21](dynamic-environment-2026-10-21.md). Testes de progressão, publicação, transição e prioridade de cenas usam adaptadores; visual e replicação real continuam pendentes no FiveM. Substitui o padrão fixo descrito na entrega de ambiente pessoal.

Ver também a entrega posterior: [Clima pessoal, entrada inicial e pintura — 2026-10-21](environment-entry-paint-2026-10-21.md). Regressores cobrem espera de ped ausente, epoch diferente, timeout, recuperação inicial protegida, preferências KVP independentes e confirmação de pintura indexada/RGB. Evidências de browser em quatro resoluções; natives do S14, cold join e isolamento entre clientes seguem pendentes no FiveM.

Corrigidas entradas vazias de SubHandlingData no asset ER34N. Toggle de noclip sem consulta anterior, sem UUID SQL e com desligamento local imediato. Troca de carro salvo ou do catálogo no trainer; drift e recriação em movimento. Build/typecheck/check/test aprovados. Browser em quatro resoluções cobriu troca salva e de catálogo com transporte simulado; imagem 1920x1080 inspecionada. XML do asset analisado; natives e física ainda dependem de FiveM, especialmente com um ER34N recriado após recarregar a definição. Ver `trainer-drift-switch-2026-10-19.md`.
