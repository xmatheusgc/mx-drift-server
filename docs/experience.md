Atualização de interface/entidades de 16/10/2026: [interface-rework.md](interface-rework.md) prevalece para os novos controles, coordenadas temporárias, fluxo de prévias e evidências de UI. Os aceites de jogo continuam pendentes.

# Experiência de entrada, oficina e câmera — 16/10/2026

Implementação na própria base txAdmin. A especificação está em [experience-plan.md](experience-plan.md). As imagens image(6).png e image(7).png não estavam disponíveis; a composição segue a descrição textual, com identidade MX.

## Uso

Inicie normalmente o perfil do txAdmin. Não é necessário usar outro diretório ou um launcher separado. A configuração já inclui os dois novos resources. A migration 005 foi aplicada em `mx_freeroam_clean`, com backup anterior em `runtime/experience-before-005.sql` (privado, não publicar).

Fluxo atualizado: loading → lobby → selecionar Garagem → personagem/primeiro carro pendente ou garagem principal → Jogar. Todos entram pelo lobby, inclusive contas existentes. Confirmações, aparência e garagem continuam persistentes. Veja [o incremento atual](lobby-navigation.md), que prevalece para navegação e composição das câmeras.

- F6 ou `/mxworkshop`: abrir lobby (com veículo parado). Garagem, dentro do lobby, conserva os requisitos de motorista/propriedade e ausência de passageiros do fluxo privado.
- F1: menu de sessão no freeroam. Na oficina, conserva o contexto de apresentação.
- F7 ou `/drivecam`: alternar câmera original/personalizada. Desligada na primeira instalação; preferência KVP local versionada.
- `/drivecamdebug`: diagnóstico local, somente com `mx_allowDrafts=1`.
- Mouse/teclado e navegação enviada pelo controle; Esc volta pela interface e exige resolver rascunhos.

Jogar usa a seleção persistida, não cria outro registro salvo. O retorno prefere um destino configurado próximo do contexto anterior e usa `meet` como fallback. Coordenadas arbitrárias da NUI não são aceitas. O servidor atual continua usando destinos rascunho; em produção eles devem ser validados como já documentado.

## Módulos e contratos

| Módulo | Responsabilidade |
| --- | --- |
| core | Identidade, transporte, SQL, transações e trava por conexão. Nenhuma regra nova de personagem, garagem ou câmera. Exige migration 005. |
| experience | Onboarding, aparência única, sessão privada, cena, seleção persistente e transição Jogar. Editor e aplicação da aparência em arquivos próprios. |
| vehicles/garage.lua | Criações salvas, validação do modelo/propriedades, prévias server-created e preparação das mutações SQL da garagem. |
| world | Reservas, destinos, colisão de viagem e respawn; aplica aparência confirmada pelo contrato de experience. |
| experience/camera.lua | Posse local por token e suspensão por múltiplos motivos. Oficina tem prioridade sobre drivecam. |
| drivecam | Matemática, câmera local, entrada manual, colisões e preferência. Sem script de servidor ou eventos de rede por quadro. |
| menu + Workshop.tsx | Foco NUI, apresentação, navegação, rascunhos e erros. Mantém menu de sessão/administração existente. |

Client → server segue `mx:experience:request` pelo transporte existente. Ações: `enter`, `state`, `character`, `preview`, `resetPreview`, `select`, `garage`, `cosmetic`, `play`. Mutações duráveis exigem UUID `operation`; operações contextuais exigem token da oficina. Revisão de aparência, criação ou estado é conferida conforme o domínio. Identidade vem exclusivamente do source autenticado.

`garage` aceita `add`, `duplicate`, `rename`, `delete`, `save`. O journal registra requisição canônica e resultado na mesma transação dos dados. Repetir a operação, inclusive com novo token de conexão, retorna o resultado confirmado; reutilizar o UUID para outro conteúdo falha. O token não faz parte da comparação durável, mas continua obrigatório para autorizar a sessão atual. `CommitOperation` é export interno, não evento de rede.

Preview não cria registro persistente. Rascunho só grava ao Salvar. Mudanças de seleção/exclusão atualizam seleção e revisão de experiência na transação. Fallback usa última utilização, criação e ID como desempate. Não há cobrança, multicharacter ou slots pagos. Limite configurado de 30 criações.

## Persistência e recuperação

Migration 005 adiciona `player_experience`, `player_appearance`, `experience_operations`, `garage_usage`. As tabelas anteriores não são removidas. Flags e aparência/primeiro carro têm confirmação atômica. Aparência incompatível abre recuperação do personagem, mantendo a garagem. Falha de SQL não é tratada como conta nova. Excluir o último carro mantém onboarding concluído. Modelos indisponíveis permanecem registrados.

O journal retém recibos duráveis. Uma política operacional de retenção pode ser adicionada depois, com uma janela explícita de idempotência; não há purge automático de dados nesta entrega.

Preferências da câmera ficam no KVP do resource de condução; reduzir movimento pertence ao KVP de experience. Essas preferências não substituem a persistência SQL de personagem/garagem.

## Cena e ciclo de vida

Cena vanilla em LS Customs, configurada em experience/config.lua. Não requer MLO, pack antigo ou asset pago. É uma apresentação privada por jogador, não uma oficina física compartilhada. Bucket estrito, população desabilitada e prévias criadas pelo servidor; o ped do jogador também muda de bucket. Não há prévia pública do rascunho. O contexto anterior é capturado pelo servidor.

O carro anterior só é removido após preparar a cena privada. A saída reserva um slot público, carrega colisão, cria um carro gerenciado, aplica as propriedades e confere motorista, posição e bucket. Falha reconstrói a oficina e sua UI. O servidor gerencia as entidades; handles e network IDs não são IDs persistentes de criação.

Fechar/reiniciar experience ou perder a interface durante uma apresentação encerra a conexão para recuperar uma sessão limpa na reconexão, sem apagar dados. O cliente limpa apenas sua câmera e seu foco. Não há promessa de hot reload transparente de toda a experiência. Após atualização de servidor, prefira reinício coordenado pelo txAdmin.

Há luzes locais de preenchimento, enquadramentos de carro, rodas, dianteira/traseira, corpo e rosto; enquadramento geral considera dimensões. Observação limitada consulta colisão. Não há órbita livre, MLO construído, modo foto ou animação de portão.

## Drivecam

Yaw calculado a partir de vetores horizontais na mesma convenção atan2; slip mistura carroceria e trajetória com peso contínuo e limite angular. Suavização exponencial por meia-vida, mira com antecipação limitada e distância adaptada ao modelo. Ré confirmada temporalmente, rodadas, baixa velocidade, salto e capotamento reduzem a política normal de drift. Teleporte/troca de entidade/pausa longa reinicializam filtros.

Mouse usa deslocamento sem multiplicação indiscriminada por dt; controle usa taxa angular e zona morta. Olhar para trás e recentramento usam menor arco. Suspende por oficina, NUI, pausa, morte e espectador. Outros resources de câmera devem usar AcquireView/ReleaseView/OwnsView e SuspendDrivecam; detectar uma câmera externa não é contrato de integração.

Colisão usa cápsula assíncrona, uma consulta acompanhada por vez, ignora o próprio carro, diferencia pendente/inválida/concluída e rejeita resultados antigos por geração, entidade, idade e diferença espacial. Aproximação rápida e recuperação amortecida; falta de solução segura usa câmera original. Restrição é aplicada por último. FOV fixo 65°, tremor/roll artístico/FOV dinâmico desligados. Parâmetros são hipóteses para calibração, não conforto comprovado.

Nenhum arquivo de mx-gearbox/mx-turbo foi alterado ou ativado. Não foram adicionadas alterações de handling, física ou transmissão. Hidráulica e aprimoramentos de desempenho não são oferecidos na oficina nova.

## Verificação e cobertura

| Parte | Verificado | Ainda depende de runtime com jogador |
| --- | --- | --- |
| Schemas e journal | MariaDB real, migration repetível, rollback, retry sem regravação, divergência de payload, persistência SQL | Desconectar nas etapas reais e reconectar pelo FiveM |
| Garagem | Exports reais no FXServer: propriedade, duplicação, revisão antiga, exclusão e flags mantidas | Prévia/modelos, aplicação de mods, seleção/saída e retomada visual |
| Câmera | 38 testes de estados/matemática + 12 testes de posse/suspensão/consultas, sintaxe Lua | Drift dos dois lados, obstáculos, ré, salto/capotamento, 30/60/144 FPS, resmon e conforto |
| UI | TypeScript/Vite, browser em 1280×720, 1920×1080, 2560×1440, 3440×1440; estados vazios/criação/erro, sem interceptar API | Foco Cfx, controle real, texto/cores sobre a cena 3D e rascunhos completos |
| Cena/isolamento | Resources inicializam no FXServer; código de bucket/limpeza | Dois clientes simultâneos, passageiro, falhas de spawn, iluminação, espaço/câmeras e compatibilidade visual de roupas |

O teste de browser usa apenas mensagens de apresentação, sem fingir sucesso de backend. Capturas têm fundo transparente sem GTA; não são screenshots do jogo. O teste SQL não substitui reconexão FiveM. O smoke test usa porta 30131 e banco de teste isolado; não interrompe o processo existente na 30120.

Roteiro obrigatório no jogo: conta nova; desconectar antes/depois de cada confirmação; reconectar perfil completo; editar/cancelar/salvar personagem e carro; duplicar/selecionar/excluir selecionado e último; modelo removido; catálogo vazio; retorno parado/com passageiro; dois jogadores saindo juntos; cliques repetidos; falha de saída; restart de cada resource; drivecam em curvas/drift/ré/rodada/rampas/túnel/paredes/capotamento e variação de FPS; teclado/mouse/controle; ultrawide. Registrar resultado e calibrar presets/câmeras antes de marcar aceite visual.

Evidências finais: [boot e resumo](evidence/experience.json), [dez checks de domínio no FXServer/MariaDB](evidence/experience-runtime.json), [browser em quatro resoluções](evidence/ui.json). O erro de foreign key observado no teste é injetado intencionalmente para verificar rollback.

