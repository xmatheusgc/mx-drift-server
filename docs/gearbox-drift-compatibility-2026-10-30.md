# Compatibilidade mx-gearbox / handling de drift — 2026-10-30

Pedido do usuário: impedir o câmbio manual de funcionar enquanto o handling de drift estiver aplicado.

## Comportamento

O manual fica temporariamente suspenso no carro com drift ativo ou restauração do handling sem confirmação. Preferência manual/automático permanece; após o handling original ser restaurado e o estado replicado confirmar drift desligado, o manual pode voltar no próximo quadro de condução. Outro veículo sem drift continua elegível. `/gear manual` durante drift explica o bloqueio e mantém a preferência para depois. Teclado, controle, embreagem e exports de troca/upgrade respeitam o bloqueio; consultas não anunciam uma transmissão manual ativa durante o drift.

O turbo continua no fluxo existente, usando os dados da transmissão nativa quando não existe transmissão manual. Não houve alteração no preset de drift, em `gearbox.lua`, no algoritmo do turbo ou na inicialização dos resources.

## Coordenação

- `vehicles/drift-client.lua`: evento local síncrono `mx:vehicles:beforeDriftHandling(vehicle, id)` antes de preflight/captura/escritas ao ligar ou reaplicar drift. O gearbox restaura marchas, relações e efeitos de embreagem/neutral antes da captura da base original, evitando restaurá-los sobre o preset posteriormente.
- `VehicleDrift.isApplied` consulta o snapshot local com identidade conferida; snapshot retido por rollback sem confirmação também bloqueia o manual.
- `vehicles/client.lua`: export `IsDriftHandlingApplied(vehicle)` expõe essa consulta.
- `mx-gearbox/client/main.lua`: consulta tanto estado local aplicado quanto `mxDrift` replicado, validando `mxVehicle`. Estados `enabled` ou `uncertain` bloqueiam o manual. Erro de consulta com o provider iniciado também mantém o bloqueio; ausência do provider permite o uso independente do gearbox, respeitando estado replicado se existir.
- Sem dependência obrigatória entre resources e sem novo evento de rede.

## Validação

`npm.cmd --prefix development run test:gearbox` aprovado: regressões existentes dos 51 atributos do drift, reaplicação, ownership, rollback e recuperação; integração dos controladores reais de drift e main do gearbox com natives/transmissão simuladas. Inclui ordem de restauração antes da captura, 10 quadros sem recriação/update do manual, teclado/controle/embreagem, exports, troca de carro, identidade obsoleta, preferência automática, ACK atrasado, provider ausente/com erro e restauração incerta seguida de recuperação. Incorporado também ao runner geral de Lua.

`npm.cmd --prefix development run check` aprovado. Sem teste de dirigibilidade no FiveM, SQL, build NUI ou reinício nesta etapa. O teste simula a transmissão e não comprova o comportamento físico da `Gearbox:Destroy` no jogo.

Próximo passo: recarregar `mx-freeroam-vehicles` e `mx-gearbox` em momento adequado, recriar o veículo e testar normal/manual → drift → normal, além de entrar em carro já salvo com drift. Conferir que relações, número de marchas e resposta original voltam ao desligar o drift. A ativação automática de mx-gearbox no server.cfg não foi alterada.
