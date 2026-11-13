# Clima pessoal, entrada inicial e pintura — 2026-10-21

## Pintura do S14

O erro recebido era disparado por uma comparação única de `GetVehicleColours` contra os índices salvos. Essa comparação também era usada para RGB, embora existam natives específicos para ler cores personalizadas. Além disso, a pintura era escrita antes das peças e os natives de acabamento eram executados depois dos índices, podendo alterar os índices recém-escritos.

A aplicação agora instala peças/extras/liveries antes da pintura, configura o acabamento, restaura os índices solicitados e aplica RGB por último. A confirmação distingue canais indexados e personalizados: índice e ausência de override para os primeiros; flag de cor personalizada e três canais RGB para os segundos. Uma recusa real continua impedindo a confirmação e agora informa canal, modelo, valor solicitado, valor observado e presença de RGB. Não foram alterados dados salvos nem removidas as proteções contra repetição de gravação incerta.

Há regressões com adaptadores reproduzindo alteração de índice por acabamento/peças, RGB com índice de base diferente e native que devolve RGB incorreto. Isso verifica a lógica, não demonstra a causa exata no asset S14 em execução. Se ainda houver recusa no jogo, o novo detalhe permite identificar a combinação que falhou. Após atualizar os recursos e reconectar, use **Recarregar estado** para descartar a prévia pendente e tente novamente a partir da criação confirmada.

## Entrada inicial no lobby

`waitEntry` tratava ped zero como troca de sessão. O servidor agora aguarda, por até `entrySyncTimeout` (6 segundos), um ped existente antes de capturar a posição pública e também durante a confirmação da cena. A identidade/epoch continua obrigatória; uma sessão diferente não recebe essa tolerância. Nenhuma coordenada de retorno é capturada de entidade zero.

Se a primeira entrada falhar, a recuperação mantém o personagem congelado e os controles bloqueados; não declara retorno ao modo livre antes da primeira saída concluída. A NUI apresenta fundo opaco e foco em **Tentar novamente** até obter cena pronta. Entradas posteriores preservam a recuperação do jogador para o modo livre.

## Clima e horário pessoais

Menu **M → Clima e horário**, usando a navegação existente por teclado/controle. Sincronização de clima e horário são independentes, com opção de restaurar ambas. Hora e minuto são fixos no modo pessoal. Configuração salva em KVP do resource world, por ID do perfil e instalação do cliente; não é sincronizada entre computadores.

O servidor publica `GlobalState.mxEnvironment` a partir de `WorldConfig.weather/hour/minute`. O padrão atual continua fixo, sem simulação de passagem do tempo. Preferências pessoais não alteram esse estado. Lobby e garagem têm prioridade visual temporária e o mundo livre recupera a preferência ao sair. Apenas o loop já existente de world escreve clima/relógio; nenhum segundo controlador foi adicionado.

Contrato local: NUI `personalEnvironment {}` consulta; `{patch:{syncWeather?,syncTime?,weather?,hour?,minute?}}` altera. Menu só aceita no modo livre aberto. World restringe o export de escrita ao menu, exige perfil, rejeita campos desconhecidos, valida clima/hora/minuto e confirma escrita KVP antes de publicar o novo estado local.

## Verificação e limites

Build, typecheck, check estático e suite de regras/Lua executados. Testes de browser exercitam o menu pessoal, navegação por teclado/mensagens de controle, retorno à sincronização e recuperação visual do lobby em 1280×720, 1920×1080, 2560×1440 e 3440×1440. Imagens de 1920×1080 inspecionadas em `docs/evidence/personal-environment-1920x1080.png` e `lobby-entry-error-1920x1080.png`.

Não houve execução de cliente FiveM, conexão real com dois clientes ou reinício do servidor. Permanecem pendentes: pintura indexada/RGB/acabamentos no S14, recuperação após reconexão, cold join com replicação real do ped e controle físico, isolamento de clima entre jogadores e retorno da iluminação após lobby/garagem. Nenhuma migration é necessária; banco e criações existentes foram preservados.

Referências primárias consultadas: [GetVehicleColours](https://docs.fivem.net/natives/?_0xA19435F193E081AC), [RGB personalizado](https://docs.fivem.net/natives/?_0xB64CF2CCA9D95F52), [SetVehicleModColor_1](https://docs.fivem.net/natives/?_0x43FEB945EE7F85B8), [state bags](https://docs.fivem.net/docs/scripting-manual/networking/state-bags/), [NetworkOverrideClockTime](https://raw.githubusercontent.com/citizenfx/natives/master/NETWORK/NetworkOverrideClockTime.md). Não foi incorporado código externo.
