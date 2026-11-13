# Som automotivo no menu livre — 2026-10-31

Pedido: estudar `resources/[mx-scripts]/mx-soundcore` e permitir seu uso básico pelo menu livre, deixando uma integração mais completa para depois.

## O que o resource faz

Inspeção local de manifest, config, client/api.lua, client/main.lua, server/main.lua, state.lua, permissions.lua e stream_resolver.js/lua. A NUI existente é um motor de áudio, sem painel de controle visível. Lua envia snapshots de veículos, ouvinte, portas/janelas, ambiente e oclusão; JavaScript processa reprodução e efeitos espaciais. Há fila, pausa/continuação, volume, metadados, busca e resolução de links via yt-dlp. Os loops usam frequências distintas e reduzem trabalho sem fontes ativas.

Estado de reprodução/fila por veículo em state bags; não é uma biblioteca persistente por perfil/criação da garagem. Não foi acrescentada persistência SQL, transferência da música entre entidades de carros nem redesenho da NUI. As permissões atuais aceitam ocupantes para iniciar/controlar (`OwnerOnly=false`, `OccupantCanControl=true`), com bypass administrativo ACE do próprio soundcore. Preservados os limites de fila, requisições e resolução do resource.

O backend Node procura `server/dependencies/yt-dlp.exe` (ou `yt-dlp`), independentemente do comentário legado sobre PATH. O executável Windows está presente; sua versão e a resolução real de plataformas não foram verificadas. Links diretos dependem do formato, acessibilidade e compatibilidade do motor de áudio do cliente. Busca de plataformas continua dependente do serviço externo e da disponibilidade do resolver.

## Integração entregue

Menu M → **Som do veículo**: tocar por nome/link, adicionar à fila, pausar/continuar, próxima faixa, volume 0–30 por setas ou entrada numérica, parar/limpar fila, faixa atual, estado e músicas da fila. Entrada de texto reutiliza o diálogo/teclado existentes (até 250 caracteres), com teclado e controle; retorno pelos comandos compartilhados, sem botão permanente.

Bridge `vehicleSound` no client do menu exige modo livre, resource iniciado, veículo atual existente/networked e mesmo net ID mostrado ao iniciar a ação. Mudança de veículo durante digitação rejeita o pedido. Usa apenas exports client, que passam pelas permissões originais do servidor. Valida ação, texto e volume. Volume inteiro 1 é enviado como 1 na escala 0–30 do export, preservando a normalização existente.

Estado atualizado a cada segundo; envio de pedido não é tratado como confirmação de reprodução. Mensagens originais de chat do soundcore são encaminhadas ao aviso/menu para exibir também recusas e falhas do resolver. O estado exibido é o estado publicado pelo soundcore, sem prova adicional de áudio audível. `IsPaused` e `GetPlaybackStatus` do script consultado referenciam `resolveVehicleEntity`, sem definição encontrada no client; a integração evita esses exports e lê os state bags existentes. Código do soundcore preservado.

`config/server.cfg` agora inclui `ensure mx-soundcore`. Build servido atualizado. Nenhum restart ou comando de console do servidor foi executado.

## Verificação e aceite no jogo

Build/TypeScript, check estático, test:controls e test:sound aprovados. Teste de bridge executa o client real com adapters de natives/exports: estado replicado, sete exports, payloads inválidos, troca de veículo, resource parado, jogador a pé, export recusado e feedback. Não comprova reprodução real nem permissões de servidor em sessão FiveM.

`test:ui` aprovado nas quatro resoluções (1280×720, 1920×1080, 2560×1440 e 3440×1440), incluindo tocar por nome, adicionar link à fila, pausar/continuar, volume numérico 1, parar e retornar pelo teclado. Usado Edge instalado via `MX_CHROMIUM`, pois o browser padrão do Playwright não estava instalado. Capturas `docs/evidence/soundcore-menu-*.png`; captura 1280×720 inspecionada. Fixtures de UI, sem reprodução de áudio. Regressões existentes do menu também passaram.

Para carregar sem reiniciar todo o servidor, no console do servidor: `ensure mx-soundcore`, depois `restart mx-freeroam-menu` em momento adequado. Entrar num carro, abrir M → Som do veículo e testar primeiro um link direto de áudio, depois nome/link de plataforma. Validar pausa, volume 0/1/30, fila, saída/entrada no carro, outro ocupante, audição por outro jogador, distância/portas/oclusão, recusa por limite e troca de veículo durante a digitação. Integração aprofundada e aceite acústico ficam pendentes.

## Bloqueio de child_process no FXServer — 2026-10-31

Usuário trouxe stack real de `ERR_ACCESS_DENIED` ao executar `GetYtdlpVersion`/`CheckAvailability`. O binário existe, mas o sandbox bloqueia criar o subprocesso. A [documentação oficial do Cfx](https://docs.fivem.net/docs/developers/sandbox/#unsafe-child-process-permission) especifica a configuração por resource:

```cfg
# Antes do ensure mx-soundcore; habilitar somente com autorização do operador.
add_unsafe_child_process_permission "mx-soundcore"
ensure mx-soundcore
```

Essa permissão é para o resource executar processos, não uma restrição ao único executável yt-dlp. Usuário autorizou explicitamente somente o mx-soundcore em 2026-10-31. Adicionada a permissão em config/server.cfg antes do ensure mx-soundcore. Sem alterar flags Node globais ou permissões de outros resources.

Correção independente entregue: todos os caminhos `execFile` do resolver agora capturam falha síncrona de spawn e entregam erro ao callback Lua, inclusive resolução após busca. A consulta inicial informa a causa sem stack não tratada; o resumo de inicialização diz indisponível em vez de assumir que falta o executável. Processos usam `windowsHide`, timeout de 15/20 segundos e 120 segundos para atualização explícita. Nenhum executável foi atualizado ou executado durante a correção.

Verificação: `test:sound`, `check` e parsing JS aprovados; testes VM simulam bloqueio de permissão em todos os exports, bloqueio no segundo estágio da busca, erro genérico, ENOENT e sucesso. Sem alteração NUI/build. Permissão salva na configuração; aplicação no servidor em execução, restart e busca efetiva pendentes. Para aplicar agora pelo console do servidor, executar `add_unsafe_child_process_permission "mx-soundcore"` e depois `restart mx-soundcore`. Não executar toda a configuração novamente para esse ajuste.
