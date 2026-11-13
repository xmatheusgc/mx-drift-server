# Retorno à garagem: recuperação e menu sem mouse

## Problemas encontrados no código

O servidor verificava as coordenadas imediatamente após o ACK de preparação da cena. Esse ACK não garante que a posição do ped já tenha sido replicada no OneSync. O erro dessa condição não tinha mensagem própria, resultando em `POSITION: POSITION`.

Depois da recuperação, `OpenGarage` executava `pause()` quando a requisição falhava fora da oficina. Isso podia congelar novamente ped/veículo e desabilitar controles. O aborto também retornava o ped ao ponto central de origem, sem reinseri-lo no carro, e a liberação não garantia colisão nem encerramento de `TaskStandStill`. Esses caminhos são compatíveis com o sintoma relatado; não houve reprodução em um cliente FiveM nesta entrega.

## Fluxo corrigido

1. `experience/prepareEntry` registra uma cópia local da identidade do carro original e de seu estado de congelamento, interrompe o movimento e desembarca o motorista.
2. O servidor aguarda o desembarque confirmado antes de trocar o bucket. A cena só é iniciada após essa confirmação.
3. Após o ACK da cena, aguarda a posição real no bucket correto, com prazo de 3 s. Não é um atraso fixo: conclui assim que a condição é satisfeita.
4. Uma falha limpa a apresentação, restaura o bucket público e chama `experience/abort`. O cliente tenta recuperar o mesmo veículo por net ID + identidade gerenciada e recolocar o motorista no banco original. Sem banco disponível, retorna ao lado do carro. Handles reutilizados não são modificados.
5. Colisão, tarefas, congelamento e controle do jogador são restaurados mesmo se carregar a colisão ou recolocar no banco falhar. A cópia temporária é descartada ao concluir ou recuperar. A falha não chama mais `pause()`.
6. A ponte NUI mantém a resposta de erro, solicita recuperação local adicional quando necessário e reabre o trainer com mensagem visível. Não publica sucesso sem confirmação.

O veículo público original só continua sendo removido pelo fluxo existente depois de preparar a apresentação. Criações salvas, personalizações, tabelas e migrations não foram alteradas.

## Entrada e erros do menu

Trainer usa `SetNuiFocus(true,false)` e mantém input do jogo. Não captura cursor; controles de olhar ao redor permanecem liberados. A NUI do trainer ignora ponteiro e não possui ações de clique ou botões de ajuste por mouse. Teclado e controle navegam, alteram valores, confirmam e voltam. Texto pode ser confirmado com Enter/cancelado com Esc; no controle é utilizado o teclado virtual nativo.

Lobby e garagem continuam com mouse. Não foi alterado o foco de suas interfaces.

Mensagens do trainer normalizam códigos repetidos, erros sem descrição e falhas de transporte/timeout. `POSITION` recebe explicação em português e mantém o código como referência, em vez de repeti-lo como texto. Mensagens específicas do servidor são preservadas.

## Verificações

Build/TypeScript, `check` e testes Lua/Fengari aprovados. Regressões dos handlers reais cobrem replicação atrasada, timeout, bucket público, retry, retorno ao motorista original, banco ocupado, identidade reutilizada, desembarque/colisão com falha, limpeza e a antiga chamada de `pause()` após erro. A ponte real do menu verifica cursor ausente e liberação dos eixos da câmera.

`test:ui` passou nas quatro resoluções, com toda a navegação do trainer por teclado, erro de garagem legível, confirmação de texto e cliques sem efeito. Captura `docs/evidence/trainer-garage-error-1280x720.png` inspecionada. Uma execução anterior foi interrompida pelo encerramento do Chromium e foi repetida com sucesso. As verificações de browser usam fixtures; as de Lua usam adapters de natives/rede.

Pendente no FiveM: entrada após dirigir, timing real de OneSync, retorno ao veículo em caso de falha, colisão/MLO, câmera de gameplay livre com menu aberto, teclado virtual e dois clientes disputando o banco/escopo de rede. Não houve reinício do servidor ativo nesta entrega.
