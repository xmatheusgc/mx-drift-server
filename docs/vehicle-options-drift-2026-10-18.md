# Opções do veículo e preset de drift

## Menu

**Opções do veículo** substitui **Meu veículo** no trainer e reúne:

- Reparar, limpar, desvirar, ligar/desligar motor e trancar/destrancar.
- **Portas**: esquerda/direita escolhe Todas, dianteiras, traseiras, capô ou porta-malas; Enter executa. Só aparecem as portas expostas pelo modelo.
- **Handling de drift**: Enter alterna o preset fornecido pelo proprietário do servidor.
- **Expulsar outros jogadores**: retira somente os outros jogadores que estão neste veículo; não expulsa o dono nem afeta ocupantes de outros carros.
- **Recriar veículo**: confirmação antes de substituir a entidade no mesmo local, preservar a configuração e sentar o dono ao volante.
- Parar o carro e personalizar na garagem.

As quatro funções novas também aparecem em **Controles**, sem teclas padrão, permitindo atribuir ou remover atalhos. R continua reparando. O menu permanece controlado por teclado/controle, sem mouse.

O estado é atualizado aproximadamente a cada segundo enquanto a seção está aberta. Ações sem contexto válido ficam desabilitadas e mostram o motivo. Abrir uma confirmação preserva a seleção anterior; a confirmação sempre começa em cancelar. Enter mantido não confirma repetidamente.

## Validações e rede

O cliente não escolhe entidade ou network ID. O servidor seleciona o carro a partir da frota do perfil e verifica identidade gerenciada, sessão, dimensão, distância de até 60 m, vida do personagem, edição e noclip. O ID opcional enviado pela interface apenas rejeita uma seleção obsoleta.

| Ação | Fora do carro | Em movimento | Restrições adicionais |
|---|---|---|---|
| Reparar / limpar | Sim | Sim | Carro ativo próximo |
| Motor / portas / trava | Sim | Sim | Carro ativo próximo e autoridade de rede disponível |
| Expulsar ocupantes | Sim | Sim | Somente outros jogadores dentro desse carro |
| Desvirar | Sim | Não | Outros ocupantes devem desembarcar |
| Recriar | Sim | Não | Sem outros ocupantes, sem estar em veículo alheio, cooldown existente de 5 s |
| Parar | Não | Sim | Dono ao volante, sem outros ocupantes |
| Handling de drift | Não | Não | Dono ao volante e modelo/build compatível |

O cliente revalida identidade e distância depois de adquirir controle de rede. As operações de handling, desvirar e parar têm guardas locais adicionais. A expulsão usa pedido autenticado ao cliente do ocupante e confirma sua saída no servidor; não tenta controlar o ped de outro jogador pelo cliente do dono.

Na recriação, o modelo/asset precisa estar disponível antes de remover o carro. O carro anterior é travado e congelado apenas durante a preparação, e o dono desembarca. A substituição só começa depois de confirmar que a entidade anterior foi removida. Falha de preparação/remoção libera a entidade original; não cria uma segunda entidade. Falha posterior de criação deixa mensagem explícita de recuperação pela garagem, sem descartar registros salvos. A recriação usa o spawn existente com `departure=false`: não herda o congelamento/freio de mão da saída da oficina. Preserva a personalização e o estado de drift; não cria ou duplica registros na garagem.

## Handling

O pedido atual autoriza uma exceção específica à exclusão original de física: **o preset fornecido**, em `resources/[mx]/mx-freeroam-vehicles/drift-config.lua`. O teste estático permite os setters exclusivamente em `drift-client.lua`; modificadores de potência/velocidade e setters globais continuam proibidos. Não houve alteração em mx-gearbox, mx-turbo ou nos arquivos dos veículos/handling.meta de assets.

Os valores físicos, vetores, inteiros, flags hexadecimais e os três campos `CCarHandlingData` do XML foram mantidos como fornecidos, incluindo tração máxima 1,07 / mínima 1,30 e as taxas de embreagem 20,8. O runtime guarda os valores anteriores da entidade antes da primeira alteração, verifica leitura após a escrita e restaura tudo ao desligar. Falha de aplicação executa rollback; falha de restauração pede recriação explicitamente. Alteração/reutilização de handle não autoriza restaurar dados sobre outro carro.

**Limites de metadados:** `handlingName=[VEH NAME]` identifica a definição do modelo; não é valor físico para substituir em runtime. `AIHandling=AVERAGE` é um enum de metadados sem setter enum suportado pelo caminho usado. Esses dois campos estão registrados no preset como referência e permanecem com os valores do asset. Os itens `NULL` também pertencem à estrutura do asset. Não há simulação de sucesso para esses campos. Modelos sem os campos necessários do subhandling não recebem uma aplicação parcial silenciosa: o preset fica indisponível ou informa o campo que não foi exposto.

O servidor publica `mxDrift={id,preset,enabled}` após autorizar a ação. Clientes aplicam o override à entidade correspondente quando ela está no streaming, inclusive após migração de autoridade; não se usa `SetHandlingFloat/Int/Vector` global. O estado pertence ao veículo ativo e é mantido ao recriá-lo. Não foi adicionado ao documento SQL das criações: reconectar, trocar de carro ou gerar outro pela garagem inicia com handling normal. Personalizações salvas continuam preservadas.

Ativar/desativar o preset invalida tentativas em andamento. O domínio de atividades consulta `Active().drift` e rejeita competição enquanto estiver ligado; prática/treino de drift permanecem permitidos. Não foi implementado julgamento definitivo de drift.

Referências técnicas primárias: [native de override por veículo](https://github.com/citizenfx/fivem/blob/master/ext/native-decls/SetVehicleHandlingFloat.md) e [implementação atual do loader e suporte a subhandling](https://github.com/citizenfx/fivem/blob/master/code/components/handling-loader-five/src/HandlingLoader.cpp). Consultadas para verificar suporte e conversões; não foi incorporado código de outro projeto.

## Verificação

Build de produção, typecheck, check estático, 67 arquivos Lua analisados e regressões existentes. Novos testes executam os módulos reais de frota/serviços e handling com adaptadores: dono versus terceiro, distância, dimensão, noclip, contexto a pé, portas individuais, trava, expulsão, ACK de drift, rollback, subtipo ausente, valores fornecidos, reutilização de identidade, falha de carregamento/preparação/remoção e recriação preservando peças e dono ao volante.

Browser Chromium em quatro resoluções exercita a nova seção, setas sem executar portas, Enter na porta escolhida, alternância de handling, confirmação de recriação, estado a pé e motor remoto. O transporte é explicitamente simulado; screenshots `vehicle-options-*` e `vehicle-options-on-foot-*` são evidência da interface, não da física.

**FiveM não foi executado, e o servidor ativo não foi reiniciado.** Ainda exigem jogo: comportamento físico e valores derivados/caches de transmissão de cada modelo; suporte do build aos campos/flags; restauração na migração de ownership/streaming; expulsão com duas contas; trava/portas/motor com dono a pé; recriação em terreno inclinado, com assets e colisão reais; resposta a desconexão durante operações. Compilar e passar testes com adaptadores não valida esses comportamentos no jogo.
