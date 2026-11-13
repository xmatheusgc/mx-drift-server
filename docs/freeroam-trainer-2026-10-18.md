# Menu do modo livre: trainer pessoal

## Interface e escopo

Menu lateral compacto com tipografia Barlow, fundos translúcidos, seleção branca ampliada, ícones originais e `ControlHints` compartilhados com a garagem. Mouse, teclado e direcional do controle continuam disponíveis; seleção e submenus são preservados ao voltar. Scrollbars invisíveis, rolagem automática e contador de itens.

Categorias: garagem, veículo, trainer pessoal, destinos, jogadores, preferências e ajuda. Administração só aparece com permissão; rotas administrativas mantêm a autorização no servidor. Encontros, grupos, atividades e progressão foram removidos da superfície deste menu. Os respectivos módulos, dados e tabelas permanecem intactos. Jogadores mantém busca, rota e mute, sem convite a encontros/grupos.

O retorno usa `experience:OpenGarage()` diretamente, e propaga sua resposta, inclusive erros. Antes era disparado `mx:experience:open`, que abre o lobby. O primeiro acesso continua começando no lobby. A garagem mantém sua dimensão privada e recebe o veículo atual pelo fluxo existente.

## Atalhos padrão

| Tecla | Comando | Ação |
| --- | --- | --- |
| M | `mxtrainer` | Abrir/fechar o trainer |
| F2 | `mxnoclip` | Alternar noclip |
| F3 | `mxcheckpoint` | Substituir o checkpoint pessoal pela posição atual |
| F4 | `mxcheckpointreturn` | Retornar ao checkpoint |

São mapeamentos `RegisterKeyMapping`. Podem ser personalizados nas configurações de teclas do FiveM. O comando antigo `mxmenu` continua como alias; uma associação F1 salva anteriormente pelo cliente pode continuar ativa até ser removida nas configurações. O novo comando usa M sem sobrescrever escolhas já salvas. Referência: [declaração oficial de RegisterKeyMapping](https://github.com/citizenfx/fivem/blob/master/ext/native-decls/RegisterKeyMapping.md).

Os comandos nativos não executam novamente quando a NUI possui o foco: a própria interface trata M/F2/F3/F4. Atalhos não atuam enquanto se digita nos campos de texto, durante pausa, lobby ou garagem. No controle, as ferramentas são acessíveis pelas linhas do menu; não foram atribuídas novas combinações globais que conflitem com a condução.

## Veículo e condução

Reparar e limpar não exigem mais carro parado e preservam sua velocidade. Motor e portas podem ser alternados no menu. Desvirar e parar zeram a velocidade deliberadamente. Os serviços exigem o motorista do veículo gerenciado; operações que deslocam o veículo exigem ausência de passageiros. O cliente revalida identidade, controle de rede e motorista antes de aplicar.

A entrada na garagem deixou de exigir velocidade inferior a 0,5 m/s; continuam as regras de posse, motorista, passageiros e rascunho legado. É uma transferência para a apresentação privada pelo fluxo existente, sem criação de veículo público adicional.

O trainer normal não bloqueia mais todos os controles do jogo: aceleração, freio e direção permanecem disponíveis. São consumidos apenas comandos da navegação, mouse/câmera e ações que conflitam com a interface. Digitar em um modal bloqueia o gameplay até encerrar a entrada de texto.

## Noclip e checkpoint

Responsabilidade de `mx-freeroam-world`, em `trainer-server.lua` e `trainer-client.lua`. `mx-freeroam-menu` apenas apresenta as ações e os atalhos; `vehicles` mantém serviços e posse; `experience` encerra o noclip antes da transferência para a garagem. Nenhuma regra nova foi concentrada no core.

Noclip requer personagem vivo no bucket público, a pé ou dirigindo seu próprio carro sem passageiros. O servidor autoriza uma sessão com token e invalida a tentativa competitiva atual. A movimentação usa delta de tempo, eixos analógicos normalizados e câmera de gameplay. Há quatro velocidades (2/7/18/40 m/s), com Shift como multiplicador 3×. W/A/S/D ou analógico movem; Espaço/controle de salto sobe; Ctrl/controle de agachar desce. A câmera continua livre para orientar o movimento. O menu ou a pausa suspendem o movimento, sem perder o modo ativo.

Ao parar, restaura colisão e libera o congelamento da entidade administrada. Morte, mudança de veículo, passageiros, perda de controle de rede, entrada em contexto privado ou parada dos recursos encerram o modo. IDs e tokens antigos não podem controlar outra sessão. Falha ambígua de ACK mantém a autorização no servidor até ser possível confirmar a limpeza. O servidor impede iniciar atividades enquanto o noclip estiver ativo.

O checkpoint é único, pessoal e temporário: contém posição e heading capturados pelo servidor, vinculados à época do perfil, e desaparece ao desconectar/reiniciar world. Não contém modelo, propriedades ou registros de garagem e não precisa de migration. Não pode ser marcado em noclip ou em apresentações privadas. F3 substitui o ponto; o menu também permite removê-lo.

F4 retorna a pé ou com o carro que o jogador estiver dirigindo, com velocidade zerada, sem invocar, duplicar ou trocar o modelo. Usa o contrato de viagem existente: reserva do destino, checagem de outros jogadores/veículos, carregamento de colisão, confirmação de posição pelo servidor e rollback se falhar. O próprio carro não bloqueia sua vaga de retorno; carros de terceiros continuam bloqueando. A tentativa competitiva é invalidada.

## Contratos

Durante o noclip, a câmera de condução opcional é suspensa pelo contrato `experience:SuspendDrivecam('trainer',true)` e liberada na limpeza, sem alterar a preferência salva. Ativações atrasadas de tokens já encerrados são rejeitadas no cliente.

`world/trainerState {}` → `{noclip,speed,checkpoint}`.

`world/noclip {enabled:boolean,speed?:1..4}` → estado do trainer. `enabled=false` exige confirmação da limpeza local.

`world/saveCheckpoint {}`, `world/returnCheckpoint {}` e `world/clearCheckpoint {}` → estado atualizado. Coordenadas recebidas de NUI não são usadas.

Canal servidor→cliente `trainer/start {token,net?,id?,speed}` e `trainer/stop {token}`; segue o ACK e a validação de origem do core. `mx:trainer:stopped` só encerra a autorização que tenha o token correspondente. A NUI recebe o evento local `trainer` para atualizar a indicação do modo.

`vehicles/service {kind}` aceita `repair`, `clean`, `flip`, `engine`, `doors`, `stop`, com validações de contexto/posse no domínio vehicles. Não altera propriedades salvas de personalização, handling ou câmbio.

## Verificações e limites

Build inclui TypeScript; verificações estáticas e suíte Fengari exercitam os controladores reais com adapters de natives/rede. Regressões cobrem posição capturada no servidor, contexto privado, época do perfil, motorista/passageiros, ACK perdido, movimento, pausa por foco, tokens obsoletos, controle de rede, limpeza, retorno à própria vaga, bloqueio por terceiros, rollback e retry de colisão, serviços em movimento e a ponte real do menu/garagem.

Testes Chromium verificam teclado, mouse, mensagens de navegação do controle, F2/F3/F4, submenus, valores, seleção preservada, erros JavaScript e composição em 1280×720, 1920×1080, 2560×1440 e 3440×1440. Capturas em `docs/evidence/session-keyboard-*.png` e `trainer-tools-*.png`. Esses dados de navegador são fixtures explícitas de contrato, não mocks usados pelo servidor entregue.

Não foi executado cliente FiveM nesta entrega. Validar dentro do jogo: manter direção/acelerador com menu aberto; transição real de foco mouse/teclado/controle; voo e restauração de colisão; terreno/MLO/streaming no checkpoint; troca de owner e passageiros com dois clientes; entrada na garagem em movimento e recuperação do carro confirmado; binds personalizados antigos e conflitos com recursos externos. Não houve reinício do servidor ativo.

Resultado final: build/TypeScript, `check`, suíte Lua/Fengari (58 arquivos Lua analisados) e `test:ui` nas quatro resoluções aprovados. Capturas do trainer em 1280×720 e do menu em 1920×1080 inspecionadas. O projeto não possui comando de lint separado; `check` executa suas verificações estáticas existentes. Não foram executados testes de banco, pois esta entrega não altera schema ou persistência. O teste de ACK perdido emite intencionalmente um diagnóstico de encerramento não confirmado.
