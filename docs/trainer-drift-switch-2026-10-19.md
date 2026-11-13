# ER34N, noclip e troca no trainer — 2026-10-19

## Handling do ER34N

`resources/[vehicles]/er34n/data/handling.meta` tinha três entradas `<Item type=""/>` no SubHandlingData. Não havia CCarHandlingData para receber os três campos do preset, incluindo fBackEndPopUpBuildingImpulseMult. O loader Cfx busca o subtipo existente; as natives não criam esse bloco. Leituras de falha podem chegar como zero, portanto uma leitura numérica não demonstrava suporte à escrita.

A definição foi corrigida para CCarHandlingData com os campos de pop-up 0.1/0.03/0.6, e duas entradas NULL. Os demais parâmetros desse asset foram preservados. A aplicação continua exigindo confirmação de todos os 51 atributos, com restauração em falha. O erro de leitura divergente agora registra classe, campo, esperado e observado, além de orientar recriar o carro após corrigir o resource. Não foram pulados campos para declarar sucesso.

Reinicie o servidor para carregar a definição atualizada e recrie o ER34N. Um carro criado com o subtipo ausente precisa de uma nova entidade; não foi realizado reinício nem teste no jogo nesta entrega.

Referência técnica: [HandlingLoader.cpp do Cfx](https://github.com/citizenfx/fivem/blob/master/code/components/handling-loader-five/src/HandlingLoader.cpp), busca de SubHandlingData no getter e setter. Não foi incorporado código externo.

## Noclip

O atalho anteriormente consultava trainerState e só depois solicitava ativação; ainda havia debounce global de 200 ms, geração de UUID por SQL e polling ocioso de 150 ms. A ativação agora usa `world/toggleNoclip` em uma única requisição, com token em memória por boot/seq e contexto autorizado no servidor. O loop local pode começar no próximo frame.

Desativar encerra o controlador local imediatamente por `StopLocalTrainer`, restaura colisão/alpha/congelamento e notifica o servidor com o token atual. A solicitação subsequente reconcilia um estado explicitamente desligado. Um segundo acionamento durante a autorização é enfileirado, em vez de descartado. A opção e o atalho na NUI usam `noclipToggle`, sem aguardar a fila de outras requisições da interface. Mantidos limites de requisição, controle de identidade, epoch, motorista e ausência de passageiros. Latência de rede e conflitos com operações protegidas do servidor ainda podem afetar a autorização; não se concede voo local antes dela.

A transparência 80 e ResetEntityAlpha ao sair foram preservados.

## Troca de carro

No menu principal: Trocar de carro > Carros salvos ou Catálogo de modelos > Marca. O catálogo tem páginas de até 20 modelos. Confirmar carrega o modelo antes de tocar no carro atual. A preparação interrompe seu movimento, trava/congela o carro e confirma o desembarque; só então remove a entidade antiga e cria a escolhida na posição final, com o jogador ao volante.

A posição é capturada depois do carregamento/preparação, permitindo iniciar a troca em movimento. Falha de carregamento preserva o carro anterior; falha de preparação libera o estado dele. Se a criação falhar após remoção confirmada, retorna erro e preserva os registros SQL existentes. Não existe promessa de recuperar a entidade antiga depois de sua exclusão. Uma criação salva recupera propriedades e drift_enabled por proprietário/ID. Um modelo do catálogo começa como carro de sessão, sem alterar ou criar registros salvos. Sem carro ativo, o servidor reserva a posição do personagem usando o domínio world. Mantido o cooldown existente de criação.

Contratos: `vehicles/trainerGarage {}` lista criações do próprio perfil; `vehicles/switch {presetId}` ou `{model}` escolhe exatamente uma origem. O servidor valida modelo/asset, proprietário, contexto público, personagem vivo, edição e ocupantes. Cliente não fornece coordenadas nem handles para a troca.

## Ações em movimento

Drift e recriação não exigem mais velocidade zero. A preparação da recriação/troca para o veículo de forma coordenada. Recriar um carro em movimento exige motorista. Desvirar continua exigindo parar, porque reposicionar a rotação em alta velocidade pode causar lançamentos ou interferir em terceiros. Reparar, limpar, motor, portas, trava, checkpoint e teleporte mantêm o uso em movimento onde seus contextos permitem. Regras de passageiros, veículo próprio e garagem privada permanecem.

## Validação

- Build (inclui TypeScript), typecheck e check estático aprovados; não existe comando separado de lint.
- Suíte Lua aprovada, 67 arquivos de produção analisados. Adaptadores de natives/rede/SQL cobrem drift em movimento, recriação, troca salva/catálogo, passageiro/proprietário, falha de loading, posição final após movimento, spawn a pé e preservação de registros.
- Testes do noclip cobrem uma requisição por ativação, ausência de UUID SQL, desligamento local e acionamento rápido pendente. Não é benchmark de latência no jogo.
- XML real do ER34N lido pelo parser XML do PowerShell e conferido na suíte contra os três valores e tipos concretos.
- Browser exercita troca salva e por marca, atalhos e navegação. Evidências de UI usam transporte simulado; não validam spawn ou física.

Ainda depende de FiveM: ativar/desativar o preset num ER34N recém-criado, conferir `mxhandling`, comportamento físico em movimento, noclip em rede, troca em rampa/alta velocidade, falta de controle de rede e observação com dois clientes. Não foram executados cliente FiveM, migração de banco ou reinício do servidor.
