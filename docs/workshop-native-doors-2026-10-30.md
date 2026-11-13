# Portas da oficina: retorno ao controle nativo — 2026-10-30

Pedido: corrigir portas/capô deslocados e oscilando ao abrir repetidamente na personalização, com retorno ao modo nativo autorizado pelo usuário.

## Diagnóstico e decisão

Em `resources/[mx]/mx-freeroam-experience/presentation.lua`, a apresentação usava `SetVehicleDoorControl` a cada quadro com interpolação própria de ângulo. `refreshDoors` também voltava a perseguir o ângulo final quando a leitura divergisse. Esse controle concorrente com a física é uma hipótese compatível com o relato; não foi reproduzido fisicamente fora do FiveM.

Removidos interpolação, escrita de ângulo por quadro e correções periódicas por leitura. A abertura usa `SetVehicleDoorOpen(vehicle, door, false, false)` e o fechamento usa `SetVehicleDoorShut(vehicle, door, false)`. O jogo controla o movimento; não há duração própria nem abertura instantânea solicitada. Referência primária: [CitizenFX — SetVehicleDoorOpen](https://github.com/citizenfx/natives/blob/master/VEHICLE/SetVehicleDoorOpen.md).

Comandos são emitidos somente quando muda o estado desejado ou após o evento explícito de aplicação de peças. Preservados: atalho de abrir/fechar todas, escolha manual sobrepondo contexto, abertura contextual de capô/porta-malas/porta do passageiro, filtragem de portas válidas, identidade da prévia e fechamento na limpeza. Removida configuração obsoleta `ExperienceConfig.doors.duration`.

## Verificação

- `node development/tests/presentation.mjs`: aprovado; 3213 verificações de apresentação/enquadramento, regressões de neon/partida/controle analógico e regressões de portas.
- Portas: 30 ciclos rápidos, ângulo intermediário mantido sem novas chamadas durante três segundos, contexto repetido sem comandos extras, reaplicação após peças, ausência de portas traseiras, evento de outra prévia, sessão antiga, handle reutilizado e limpeza.
- O adapter falha se o controlador voltar a chamar `SetVehicleDoorControl`; valida os parâmetros de abertura/fechamento animados.
- `npm.cmd --prefix development run check`: aprovado.

Testes usam natives simuladas; não comprovam física/animação em modelos reais. Sem build NUI necessário, reinício de resource, alteração SQL ou teste FiveM nesta etapa.

## Próximo passo

Recarregar `mx-freeroam-experience` em momento adequado e abrir uma nova prévia na oficina. Uma entidade já deformada pode exigir sair/reabrir a garagem ou trocar a prévia. Validar várias aberturas/fechamentos com ESPAÇO, navegação motor/interior/porta-malas e troca de peças nos carros afetados.
