Atualização 17/10/2026: [teclado e mouse, Customizar, ações visíveis, câmeras e suspensão](customization-input-stance.md). Este incremento prevalece para input, F9/F10, rolagem e presets de câmera descritos anteriormente.

# Incremento de lobby, garagem e câmeras — 16/10/2026

Este relatório cobre somente [o novo plano incremental](lobby-plan.md). Prevalece sobre a navegação e a disposição de câmera/personagem descritas nos relatórios anteriores. A implementação permanece na base txAdmin existente; não há outro launcher nem nova base.

## Uso e configuração

Inicie o perfil normalmente pelo txAdmin. Para receber a nova loading screen, reconecte após o reinício coordenado do servidor; reiniciar só a NUI em uma conexão aberta não reproduz o carregamento inicial. O servidor principal não foi reiniciado nesta entrega.

Se menu/vehicles parar enquanto o lobby ou a oficina estiverem ativos, o cliente libera controles/pausa e solicita encerramento da própria conexão para recuperação limpa. Essa regra evita deixar o jogador congelado sem interface; não promete hot reload transparente. A confirmação desse cleanup com clientes permanece pendente.

- Conexão: loading → lobby opaco → Garagem → tarefa inicial pendente ou garagem principal.
- F6 ou `/mxworkshop`: lobby. Pare o veículo antes de abrir. Se estiver editando na garagem, a interface exige resolver alterações antes de sair.
- Lobby: setas navegam, Enter abre, Esc/Backspace volta. Cursor oculto. Garagem recebe o foco inicial.
- Abrir o lobby durante gameplay oferece **Retomar sessão**. O veículo controlado e parado é temporariamente congelado, preservando seu estado anterior; não é recriado ao retomar. Entrar efetivamente na garagem utiliza a transição privada já existente, com suas restrições de propriedade e passageiros.
- F1 continua sendo o menu compacto durante gameplay. F7 continua alternando drivecam. F4 continua controlando a câmera livre na oficina. Os editores e seus atalhos permanecem.
- Configure `set mx_discordInvite "https://discord.gg/SEU_CONVITE"` em `config/server.cfg` ou na configuração local carregada depois dela. O valor entregue pelo servidor só aceita HTTPS em discord.gg ou discord.com/invite. Nenhum convite foi inventado; o botão fica explicitamente indisponível enquanto vazio.
- **Loja** e **Criar grupo** permanecem desabilitados, com “Em breve”.

## Telas e fluxos

O lobby possui três grupos inferiores, sem navegação superior: Garagem/Criar grupo, Discord/Configurações, Loja/Jogadores e amigos. Preto opaco ocupa o viewport inteiro, incluindo ultrawide. `lobby-background` e `loading-background` reservam a camada de imagem futura sobre uma base preta permanente.

Na garagem, as abas estáveis são **Meu carro · Personagem · Showroom · Ranking**. Meu carro apresenta Jogar, Performance (Em breve), Customização e Trocar de carro. Personagem apresenta Jogar na mesma posição e largura, Roupas e Aparência. Showroom reutiliza o catálogo gratuito; Trocar de carro abre exclusivamente a coleção salva. A adição retorna ao carro selecionado, permitindo seguir imediatamente para Customização.

Abas só mudam o contexto/câmera quando a apresentação já é válida. Ao abandonar uma prévia diferente no Showroom ou na coleção, `resetPreview` recupera a seleção salva. Isso é uma restauração necessária; não acontece ao simplesmente circular entre abas sem trocar a prévia. O controlador de entidades com geração/fila e a autoridade do servidor foram preservados.

Ranking informa sua indisponibilidade **na garagem** e orienta para a classificação existente em F1. O endpoint atual exige veículo ativo público e pista, e separa resultados por modelo/configuração/condições. Não foram fabricados registros nem criadas novas regras de pontuação. Performance não adiciona handling ou física.

Roupas, Aparência e Customização usam os editores existentes. As abas superiores são recolhidas na edição. Voltar resolve os níveis do editor e depois retorna à origem. Salvar/Descartar/Continuar editando continua protegendo rascunhos. Esc na garagem principal retorna ao lobby, sem acionar Jogar automaticamente.

## Primeiro acesso e recuperação

Todos passam pelo lobby antes de entrar em uma tarefa obrigatória. A garagem apresenta o preset inicial com **Confirmar personagem** ou **Editar personagem**, depois o Showroom com **Escolher este carro**. A aparência passa pela validação nativa existente antes da transação SQL; nenhuma flag é concluída apenas por navegar.

Depois das confirmações, abre a garagem com Jogar disponível. Nos acessos seguintes, o editor mostra Salvar alterações/Cancelar e o Showroom mostra Adicionar à garagem. A navegação completa fica recolhida durante as etapas obrigatórias.

Enquanto uma confirmação está pendente, outro clique não gera uma nova operação. Tentar novamente reutiliza exatamente o UUID e o ID da criação originais; Recarregar estado consulta o servidor antes de permitir outra gravação e protege rascunhos com o diálogo existente. A recuperação de aparência incompatível é identificada explicitamente e preserva a conclusão anterior da escolha do carro.

Voltar ao lobby não conclui a tarefa. Ao entrar novamente, o servidor recarrega as flags persistidas. Aparência salva e primeiro carro usam o journal de UUID existente, inclusive para repetição de confirmação perdida. Excluir todos os carros depois da conclusão mostra garagem vazia com Adicionar veículo; não reinicia o personagem. Falhas de carga continuam sendo erros, sem converter dados válidos em primeiro acesso.

## Loading screen e passagem ao lobby

O manifest do menu declara `loadscreen` e `loadscreen_manual_shutdown`. A barra recebe `loadProgress.loadFraction` do FiveM, rotulada **Recursos X%**. Ao terminar essa etapa, muda para preparação indeterminada; não apresenta um percentual global inventado. A espera por perfil/configuração do lobby não equivale a acesso concluído.

O cliente entrega o lobby com uma geração. A NUI aguarda dois `requestAnimationFrame` e confirma `lobbyReady`. Somente a geração atual pode encerrar a loading screen, e o foco de teclado é reaplicado depois do shutdown. Entregas são repetidas por até 12 segundos enquanto a NUI monta. Os dois contextos React trocam mediante uma única mensagem, mantendo a cobertura opaca. Falha de entrada na garagem mantém o lobby visível durante o rollback.

Falha de perfil, ausência de resposta da NUI e espera prolongada têm mensagens compreensíveis, com orientação de reconexão e preservação dos dados. O timeout não aumenta artificialmente o progresso. Retornar ao lobby na mesma conexão não executa a loading screen novamente.

A implementação segue a [documentação oficial de loading screens](https://docs.fivem.net/docs/scripting-manual/nui-development/loading-screens/) e do [resource manifest](https://docs.fivem.net/docs/scripting-reference/resource-manifest/resource-manifest/). O snapshot de congelamento usa o [getter oficial de FreezeEntityPosition](https://github.com/citizenfx/fivem/blob/master/ext/native-decls/IsEntityPositionFrozen.md). Não foi incorporado código de recriações de terceiros neste incremento; a linguagem visual e as fontes locais licenciadas da interface atual foram reutilizadas.

## Amizades e persistência

`social/friends.lua` pertence ao domínio social. Migration **006_friendships.sql** acrescenta apenas `player_friendships`, sem alterar/excluir as tabelas anteriores. Pares são canônicos, únicos e vinculados aos IDs persistentes de players, nunca a sources reutilizáveis. O remetente fica registrado e apenas o destinatário pode aceitar/recusar. Aceites e reenvios confirmados são idempotentes; resultados são relidos para não anunciar um aceite que foi invalidado por concorrência.

Jogadores online, amigos, recebidas e enviadas são listas diferentes. A busca filtra os nomes disponíveis; amigos offline continuam na lista. Envio novo requer destinatário online e respeito à preferência de convites. Solicitações persistidas podem ser respondidas quando o remetente está offline. A interface atualiza ao abrir, após mutações e a cada dez segundos enquanto a lista está aberta. Não expõe license, coordenadas ou buckets.

Contratos autenticados existentes: `social/friends {}`, `social/friendSend {target: playerId}`, `social/friendRespond {target: playerId, accept: boolean}`. A identidade é a do ator autenticado. `experience/lobby {}` fornece somente a configuração pública do convite; não marca onboarding. Callbacks NUI locais acrescentados: `openGarage`, `lobbyReady`; ações locais `lobby` e `resume`.

A migration 006 foi aplicada no banco ativo local `mx_freeroam_clean`, após backup privado em `runtime/lobby-before006.local.sql`, e no banco isolado de testes. O core apenas exige a versão do schema; regras sociais permanecem no domínio social.

## Composição e câmeras

`experience/config.lua` centraliza proporções, distâncias e offsets da composição. `WorkshopFraming.main` posiciona a câmera no quadrante dianteiro **direito do carro**. `WorkshopFraming.person` coloca o personagem na dianteira **esquerda**, alinhado ao bone `wheel_lf`, com fallback por dimensões e afastamento lateral.

A direção do corpo é derivada do vetor personagem→carro usando a convenção GTA `forward=(-sin(h),cos(h))`. Não é um giro global arbitrário, nem um look-at só da cabeça. A colocação continua carregando colisão e consultando o chão antes da pose; o ator externo do editor reutiliza essa posição e heading.

Os presets de peças possuem distâncias mínimas por região, escaladas pelas dimensões do modelo e proporção de tela. Bones alteram o alvo, nunca substituem a posição do observador. Bone ausente/inválido amplia o enquadramento; a câmera respeita altura mínima e envelope da carroceria. A consulta de cenário não pode encurtar a distância abaixo do limite da categoria: conserva uma posição anterior segura ou informa indisponibilidade. Transições só interpolam caminhos consultados como livres; órbita/retorno mantêm os limites existentes. Selecionar uma peça não recria o carro.

## Arquivos principais e reutilização

| Arquivos | Alteração |
| --- | --- |
| `ui/src/Lobby.tsx`, `Preferences.tsx`, `main.tsx`, `style.css` | Lobby, listas sociais, preferências extraídas do fluxo anterior, cobertura opaca e foco. |
| `ui/src/Workshop.tsx`, `SessionMenu.tsx` | Abas, ações contextuais, origem dos editores, primeiro acesso e entrada no lobby. |
| `menu/client.lua`, `fxmanifest.lua`, `loadscreen/*` | Contratos NUI, foco sem cursor no lobby, loading e entrega de estado. |
| `experience/client.lua`, `server.lua`, `config.lua`, `framing.lua` | Handoff, pausa/retomada, rollback opaco e nova composição/presets. |
| `social/friends.lua`, `social/server.lua`, `social/fxmanifest.lua`, migration 006 | Amizades persistentes no domínio social. |
| `core/config.lua`, `config/server.cfg` | Versão exigida do schema e convite configurável. |

Aparência, garagem, journal, transição pública/privada, controlador de prévias, editor de peças, drivecam e permissões administrativas foram reutilizados. mx-gearbox e mx-turbo permanecem preservados. Não há migração destrutiva, economia, loja funcional ou novos sistemas de grupo.

## Verificações e limites

| Verificação | Resultado e alcance |
| --- | --- |
| `npm run build`, `npm run typecheck`, `npm run check` | TypeScript, bundle Vite, manifests e limites estruturais. O projeto não possui tarefa ESLint; `check` não é apresentado como lint completo. |
| `npm test` | 49 arquivos Lua analisados em Fengari; regras existentes, controlador de prévias, LatestPreview e 2.481 verificações de apresentação/geometria. Natives simuladas não comprovam o comportamento no jogo. |
| `npm run test:ui` | Menu compacto e editor existentes preservados; navegação, rascunhos, opções/rodas e retorno testados em 1280×720, 1920×1080, 2560×1440 e 3440×1440. |
| `npm run test:lobby` | Loading/progresso, cobertura opaca, lobby/teclado, etapas/retomada, confirmação perdida com UUID preservado, recuperação de aparência sem repetir escolha de carro, abas sem operações de entidade, Jogar consistente, rascunho e listas de amizade nas mesmas quatro resoluções. Resposta local de câmera atrasada deliberadamente no teste para verificar que o catálogo continua carregando. Fixtures de browser, explicitamente sem SQL/natives. |
| `npm run test:db` | MariaDB real: migrations repetíveis, identidade, propriedade, revisão e recuperação após nova conexão SQL. Não equivale a reconexão FiveM. |
| FXServer isolado em 30131 + MariaDB | Schema 006 pronto, resources iniciados; `mxtestfriends`: 11/11; `mxtestexperience`: 11/11. Rejeições e a falha de FK intencional exercitam os caminhos negativos. Servidor auxiliar encerrado. |
| Inspeção visual | Capturas de loading, lobby e garagem renderizadas foram inspecionadas; cenas 3D não fazem parte das capturas de browser. |

Evidências: [lobby/UI](evidence/lobby.json), [menu/editor](evidence/ui.json), [SQL/exports em FXServer](evidence/lobby-runtime.json), [lobby 1080p](evidence/lobby-1920x1080.png), [loading ultrawide](evidence/loading-3440x1440.png), [garagem 1080p](evidence/heat-home-1920x1080.png).

**Pendente no FiveM:** conexão real desde a loading screen, ausência de flashes no handoff nativo, retomada após reconexão em cada etapa, foco/teclas/controles, convite externo, pausa/retomada e rollback, descarte de prévias em todos os caminhos e enquadramento efetivo do carro/personagem/peças com chão, iluminação, colisão e assets reais. **Dois clientes:** envio novo para destinatário online, solicitação cruzada, privacidade/limites, aceite/recusa e recuperação após desconexão. O FXServer foi executado, mas havia zero clientes de jogo; entidades, câmeras e ausência de clipping não são declaradas validadas.
