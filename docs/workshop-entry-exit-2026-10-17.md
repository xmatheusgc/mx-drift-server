# Entrada e saída da oficina

Configuração central em `resources/[mx]/mx-freeroam-experience/config.lua`:

- Saída: **163.2, -3024.11, 6.05**, heading **268.29**.
- Entrada (limites inclusivos): X **120–160**, Y **-3050–-3007**, Z **6–10**.
- Espera mínima da partida: `departureDelay=450` ms, contados desde o pedido de partida. Um motor que demora mais não recebe outra espera completa após ligar. Falta de confirmação por 3 segundos é erro, com recuperação da garagem.

Lobby e apresentação do carro dentro da oficina permanecem nas posições próprias. A saída está fora da área de entrada para não mostrar o convite imediatamente após sair.

## Entrada

`entry.lua` observa a área no mundo livre. Exibe uma indicação NUI com os controles existentes: **E** no teclado e **direcional direito** no controle (`INPUT_CONTEXT`, 51). Não exibe em garagem/lobby, pausa, NUI com foco, personagem morto ou durante pedido de entrada. O aviso não captura o cursor. O evento passa pelo resource da NUI, que é o proprietário de `SendNUIMessage`.

O atalho abre diretamente a garagem pelo mesmo fluxo de personagem, carro atual e bucket privado. `experience/enterFromArea` verifica novamente a posição real no servidor, bucket público 0 e ausência de sessão privada. Mantém as verificações existentes de motorista, carro parado, passageiros e edição. Uma tentativa rejeitada mostra a mensagem sem pausar o freeroam.

## Jogar e partida

O servidor remove a prévia, reserva uma saída livre, prepara colisão e cria o veículo ativo no bucket público. Somente esse spawn recebe `departure=true`: é mantido parado, com freio de mão e partida automática desabilitada ao sentar o motorista.

Ainda durante a transição escura e com controles bloqueados, a câmera de apresentação é liberada para que o áudio acompanhe o motorista no veículo de gameplay. `vehicles/depart` aciona a partida nativa sem aceleração, espera confirmação de motor ligado e o mínimo de 450 ms, e libera o carro ligado. Identidade de entidade, controle de rede e motorista são revalidados durante a espera. O servidor confere a identidade do carro ativo novamente antes de finalizar a transição.

Falha recupera a oficina pelo caminho existente. Não modifica registros salvos nem aplica física/handling. Outros spawns mantêm seu comportamento anterior.

## Verificação

- `test`: limites dos três eixos, rota real de entrada com posição/bucket simulados, recusa de entrada repetida e handler real de partida com natives simuladas (espera mínima, motor lento, timeout, motorista e identidade).
- `build`, `typecheck`, `check`, `diff --check`.
- `test:ui`: aviso por teclado/controle e remoção ao sair da área, junto às regressões existentes; resultados em `docs/evidence/ui.json`, capturas `workshop-entry-*`.

Nenhum cliente FiveM foi executado. Confirmar dentro do jogo volume/duração do som de partida, comportamento em ER34N e outros modelos, colisão/altura da nova saída, botão físico do controle, entrada com carro parado e saídas concorrentes de dois jogadores. O teste no navegador injeta mensagens e não mede áudio, rede ou entidades do FiveM.
