# Drift recuperável e ER34N — 24/10/2026

Origem: relato do proprietário, F8 fornecido, arquivos locais e testes por Codex. O proprietário pediu que falhas recuperáveis de handling produzam diagnóstico/recuperação, sem impedir pegar, recriar ou trocar um veículo e sem apagar progresso.

## Diagnóstico

O arquivo atual `resources/[vehicles]/er34n/data/handling.meta` tinha três subtipos vazios em `SubHandlingData`. O erro fornecido informa que `CCarHandlingData.fBackEndPopUpBuildingImpulseMult` não confirmou 0.03 e retornou 0.0. A ausência do subtipo é uma causa concreta a corrigir; reset/retry não cria uma definição de modelo ausente. A leitura efetiva no FiveM continua sujeita a reteste depois de carregar o resource corrigido.

`drift_enabled` é a preferência salva da criação. Não é um handling parcialmente aplicado armazenado no banco. Ao recuperar um carro salvo, o cliente tentava aplicar essa preferência dentro de `vehicles/apply`; uma divergência no preset fazia a operação inteira falhar. O spawn removia o candidato e a troca pelo trainer podia já ter removido o carro anterior. Isso transformava a falha de uma opção de física em indisponibilidade do veículo.

## Alterações

- ER34N: declarado um `CCarHandlingData` com os três valores já autorizados no preset/XML (0.1, 0.03 e 0.6); demais slots declarados `NULL`. O bloco principal de `CHandlingData` não foi retunado. Referência do conteúdo anterior: `docs/evidence/er34n-handling-before-2026-10-24.meta`, reconstituída revertendo somente o bloco alterado.
- `VehicleDrift.set`/`audit` continuam estritos. Novo `VehicleDrift.ensure` captura falhas do módulo, tenta restaurar o snapshot original e permite uma nova tentativa de aplicação. A identidade da entidade continua obrigatória. Não se captura uma aplicação parcial como novo original.
- Falha persistente retorna `enabled=false`, `fallback=true`, estado da restauração, aviso, tentativas e detalhe técnico. Se o original foi confirmado, o carro segue com o baseline restaurado. Se não foi confirmado, o carro continua disponível com estado de handling incerto. Erros de aplicação e de restauração são mantidos no diagnóstico.
- `vehicles/apply` separa confirmação de personalização/entidade do resultado opcional do drift. Falha recuperável de drift não rejeita a retirada do carro da garagem, o spawn ou a troca. Falhas obrigatórias de identidade, modelo, personalização, ocupantes e ACK continuam protegidas.
- Reparar um carro também usa recuperação na reaplicação do drift. A falha opcional não desfaz o reparo nem invalida a confirmação do carro.
- O servidor separa `driftRequested`, `drift` efetivo e `handlingUncertain`, publicando o resultado efetivo aos observadores. A preferência salva não é desligada automaticamente por um fallback. Recriação mantém a intenção e pode tentar novamente.
- Toggle manual que não aplicou o preset retorna aviso com `persisted=false`; não declara sucesso nem altera o modo salvo. Toggle confirmado continua exigindo confirmação da persistência; falha de banco mantém o tratamento existente.
- Menu M preserva o aviso retornado, mostra desligado quando o original foi restaurado e `SEM CONFIRMAÇÃO` quando a restauração ficou incerta. Falhas de restauração não são repetidas a cada tick de polling.
- Drift ativo e handling incerto continuam impedindo modalidades competitivas. Treino e modo livre permanecem disponíveis. É uma restrição de integridade de resultado, sem bloquear recuperar/usar o carro.
- Diagnósticos locais usam `[MX:DRIFT]` no F8; o servidor recebe aviso estruturado `HANDLING_FALLBACK` com o modelo, identidade e detalhe. Uma recuperação não é reportada como `INTERNAL` do spawn.

## Verificação

- `npm.cmd --prefix development run build`: aprovado, incluindo TypeScript e bundle servido atualizado.
- `npm.cmd --prefix development run check`: aprovado.
- `npm.cmd --prefix development test`: **aprovado integralmente**, incluindo a checagem do subtipo ER34N que falhava na entrega anterior. Os 51 atributos do preset continuam iguais ao XML autorizado.
- Regressões novas: leitura de subtipo que permanece zero; restauração integral e uma nova tentativa; erro transitório recuperado; restauração sem confirmação; retry explícito; prevenção de repetição por polling; identidade de entidade reutilizada; callback real de `vehicles/apply` com drift indisponível; retirada, recriação, troca e reparo com fallback; preferência salva preservada; ausência de falsa persistência; ACK obrigatório ainda protegido; competição bloqueada apenas enquanto o handling estiver modificado/incerto.
- `test:ui` com Chrome instalado via `MX_CHROMIUM`: aprovado em 1280×720, 1920×1080, 2560×1440 e 3440×1440. O teste simula um toggle com fallback, confere o aviso sem erro bloqueante e permite uma nova tentativa. Captura 1280×720 também inspecionada visualmente: `docs/evidence/drift-fallback-1280x720.png`.

Testes Lua/Fengari, natives, SQL e transporte de browser são adaptadores. Não houve teste de dirigibilidade ou readback em cliente FiveM, restart do servidor, migration ou alteração de dados de jogador. A atualização anterior de oficina/rede não foi refeita.

Evidência: [handling-recovery-2026-10-24.json](evidence/handling-recovery-2026-10-24.json).

## Aplicação e próximo passo

Reiniciar o servidor completo pelo txAdmin e reconectar os clientes para carregar o handling.meta e recriar entidades com a definição nova. Repetir a saída com ER34N salvo em drift, troca pelo menu M e toggle desligar/ligar. Conferir `/mxhandling` no F8. Se a leitura continuar divergindo, o veículo deve permanecer utilizável e o diagnóstico deve mostrar a recuperação realizada, sem afirmar que o preset passou.

## Fontes e limites

Fonte principal do problema: F8 fornecido pelo usuário em 24/10/2026 e código local. A documentação oficial das natives descreve overrides por veículo e registra limitações de classe/suporte: [SetVehicleHandlingFloat](https://github.com/citizenfx/fivem/blob/master/ext/native-decls/SetVehicleHandlingFloat.md), [GetVehicleHandlingFloat](https://github.com/citizenfx/fivem/blob/master/ext/native-decls/GetVehicleHandlingFloat.md). Não se pressupõe que todo modelo/build exponha todos os campos; a recuperação existe também para esses casos. Não foram adicionados setters globais de handling.
