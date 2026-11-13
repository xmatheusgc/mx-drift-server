# Correção da aplicação de handling em runtime

## Encontrado

O controlador anterior escrevia os campos de handling e relia esses mesmos campos. Isso detectava falhas de escrita, mas não reconstruía a transmissão já inicializada no veículo. Portanto, ler `fInitialDriveForce=0.94` não demonstrava que a transmissão estava usando a força nova.

A documentação primária de [MODIFY_VEHICLE_TOP_SPEED](https://github.com/citizenfx/natives/blob/master/VEHICLE/ModifyVehicleTopSpeed.md) determina chamar esse native após alterar `fInitialDriveForce` e `fInitialDriveMaxFlatVel`: ele inicia novamente a configuração da transmissão. O código anterior não o chamava.

Também faltava atualizar as flags de rodas motrizes. O preset pede `fDriveBiasFront=0`, mas só mudar o número do handling não era uma verificação das rodas efetivamente habilitadas. O Cfx expõe [SetVehicleWheelIsPowered](https://github.com/citizenfx/fivem/blob/master/ext/native-decls/SetVehicleWheelIsPowered.md) e [GetVehicleWheelIsPowered](https://github.com/citizenfx/fivem/blob/master/ext/native-decls/GetVehicleWheelIsPowered.md) para esse estado.

## Correção

Após escrever os campos, `drift-client.lua` chama **ModifyVehicleTopSpeed(vehicle, 0.0)** para refazer a transmissão com variação percentual zero, configura **5 marchas** com SetVehicleHighGear e habilita força somente nas duas rodas traseiras. Não foi adicionado percentual extra de potência/velocidade.

A verificação dos 51 campos acontece **depois** dessa atualização, junto da leitura de marcha máxima e rodas motrizes. Ao desligar, são restaurados tanto os campos quanto a marcha máxima e as flags de tração anteriores, seguidos do mesmo recálculo. Falha de atualização executa rollback; não é considerada sucesso só porque os campos foram gravados.

O recálculo também ocorre após reparo e quando o cliente assume autoridade de rede. Ele não é repetido continuamente durante condução com ownership estável. O spawn que preserva drift força a aplicação final após peças e assento do jogador, mesmo que a sincronização de estado já tenha aplicado o preset antes. Uma nova aplicação conserva a baseline original e corrige divergências detectadas em vez de retornar sucesso incondicional.

O servidor exige confirmação de `transmissionRefreshed=true` para aceitar uma ativação. O diagnóstico continua sendo uma leitura do cliente; não é uma prova anticheat. Não houve alteração de arquivos dos modelos, mx-gearbox, mx-turbo, personalizações salvas ou migrations.

## Conferência do XML

`development/fixtures/drift-owner.xml` preserva os valores fornecidos. Um teste independente percorre todos os campos numéricos, vetores e flags do XML e compara os **51 atributos de runtime** com `drift-config.lua`. Nenhum desses valores foi retunado. `handlingName`, `AIHandling` e declarações NULL continuam metadados não sobrescritos, como já documentado.

Há uma particularidade do XML: **fTractionCurveMin=1.30 é maior que fTractionCurveMax=1.07**. A [implementação do Cfx](https://github.com/citizenfx/fivem/blob/master/code/components/handling-loader-five/src/HandlingLoader.cpp) trata esse caso atribuindo um valor especial ao fator interno da curva. Isso impede presumir equivalência física completa com um carregamento inicial de metadados apenas pela releitura dos dois números. Os valores foram mantidos; não foram invertidos nem ajustados sem teste de condução. Essa é uma hipótese adicional a investigar caso a sensação continue diferente após corrigir a transmissão.

O setter atual do Cfx limita `nInitialDriveGears` a 7. Baselines acima desse limite agora falham antes de qualquer alteração, pois não seria possível prometer restauração fiel com o mesmo setter. Modelos sem os campos de subhandling exigidos também continuam indisponíveis.

## Diagnóstico no jogo

1. Carregue os scripts atualizados e entre novamente com seu carro. O servidor ativo não foi reiniciado durante o desenvolvimento.
2. Pare, ative o handling de drift e observe no F8 o resumo `[MX:HANDLING]`: deve informar `checked:51`, `mismatches:0` e `transmissionRefreshed:true`.
3. No F8, execute **mxhandling**; pelo chat, use **/mxhandling**. O relatório inclui `fields` com classe, campo, valor esperado, valor lido e resultado da comparação, além de `drive.gear`, rodas motrizes e autoridade local. Com drift: marcha máxima 5 e rodas `[false,false,true,true]`.
4. Desative e execute novamente para comparar os valores originais. Quando esse cliente possui a baseline da entidade, os 51 campos também são comparados após desativar; um cliente que nunca aplicou o preset apenas informa as leituras atuais, sem inventar valores originais (`checked:0`).

O diagnóstico só lê o veículo ativo próximo do perfil, com validação de contexto no servidor. Não transfere autoridade de rede apenas para inspecionar e não altera handling. Uma leitura de campos coincidentes não valida física, transmissão efetiva ou todos os efeitos de flags/metadados no jogo.

## Reset/recriação

A correção utiliza a reinicialização de transmissão documentada no próprio veículo, sem destruir automaticamente a entidade ou alterar suas peças. **Recriar veículo** continua disponível para comparar uma entidade recém-criada: esse fluxo já mantém o preset e agora também executa o recálculo final. Não é apresentado como garantia de reconstruir todos os efeitos de um handling.meta carregado antes da criação do modelo.

## Verificação executada

- Build de produção, typecheck e check estático passaram. A guarda de física admite exclusivamente a chamada de refresh com `0.0` no controlador autorizado; percentuais arbitrários e setters globais permanecem proibidos.
- Testes passaram: 67 arquivos Lua analisados, regressões existentes, correspondência de todos os 51 campos com XML, cache de transmissão simulado que só muda ao chamar o native, RWD sobre baseline FWD, restauração de marcha/rodas, falha de refresh e rollback, diagnóstico por campo, reaplicação sem perder baseline, reparo, ownership e estabilidade sem resets periódicos.
- Servidor testado com adaptadores para rejeitar ACK antigo sem refresh e restringir diagnóstico à frota do solicitante.
- A interface não mudou; não foi necessário repetir a inspeção visual/browser da entrega anterior.

**Não executei FiveM nem um teste de condução.** Não é possível afirmar que o comportamento ficou igual ao XML no carro real. Ainda precisam de jogo: força efetiva, curva de tração invertida, caches de massa/inércia e flags, diferenças entre builds/modelos e comportamento após migração de rede. Os testes de caches usam adaptadores explícitos e não representam observação do motor GTA.
