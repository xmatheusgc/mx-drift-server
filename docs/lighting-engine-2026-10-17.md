# Iluminação agrupada, prévia de neon e partida

Incremento na base existente, sem alterar schema ou dados salvos e sem reiniciar o perfil em uso.

## Organização

Iluminação & efeitos contém Neons, Faróis e as opções existentes de fumaça. Neons abre Cor do neon e Layout do neon. O layout conserva toggles por lado, check e Todos os neons. Faróis abre Farol de xenon, como toggle, e Cor dos faróis. Esta cor reutiliza o mesmo `ColorPanel` das pinturas, reunindo as cores nativas de xenon e os três campos RGB; selecionar uma cor indexada limpa o RGB anterior, e RGB conserva um índice nativo válido.

## Prévia transitória

Entrar em Neons ou editar sua cor mostra temporariamente os lados suportados pelo modelo, mesmo quando o layout salvo está desligado. Entrar em Layout do neon mostra os lados realmente selecionados, permitindo comparar os toggles. Confirmar apenas uma cor não liga permanentemente todos os lados. A prévia recebe separadamente o layout/cor confirmados para restaurá-los ao sair ou encerrar o editor.

O controlador força luzes e flags de neon durante essa prévia. `ExperienceConfig.neonPreview.engine=true` habilita alimentação em marcha lenta para modelos que necessitem do motor ligado; não injeta aceleração. Com `false`, mantém o motor desligado quando não estiver sendo testado e usa somente os natives de luz. O modo sem motor passou nos testes de chamadas, mas não foi avaliada a emissão real de luz por cada asset; por isso a alimentação em marcha lenta foi deixada habilitada como padrão. Nenhum efeito de luz foi simulado por textura ou marcador substituto.

O comando local `previewNeon` exige o ID da sessão atual, veículo ainda pertencente à apresentação e arrays válidos. A NUI aguarda a preparação do editor, serializa comandos locais e descarta atualizações obsoletas. Uma limpeza de editor antigo não altera o novo. Ao sair, os natives restauram a configuração confirmada; se o motor estava ligado apenas para a luz, ele desliga. Se o jogador estava testando o motor, mantém-se o timeout normal de marcha lenta.

## Partida e acelerador

O intervalo configurável de `ExperienceConfig.engineTest.startupDelay` passou de 650 para **250 ms**. Agora ele começa quando `GetIsVehicleEngineRunning` confirma o funcionamento, não quando se pede para ligar. Retornos booleanos e numéricos 0/1 são considerados corretamente.

Durante o arranque e essa espera, o controlador mantém acelerador/reverso bloqueados e aceleração injetada em zero. Não chama `SetVehicleCurrentRpm` nessa fase; a partida fica a cargo do native. Só depois libera a aceleração e o RPM de apresentação, com freio de mão mantido. Isso remove a injeção de RPM que existia durante a espera anterior. Não houve alteração de handling, transmissão ou veículos públicos.

## Verificações

- Typecheck, build Vite, check estático e testes Lua/Fengari aprovados; 54 arquivos Lua analisados. Não há script separado de lint.
- Dez regressões novas com natives simuladas: prévia com/sem alimentação, layout por lado, restauração, limpeza antiga ignorada, ausência de alimentação quando todos os lados estão desligados, arranque prolongado sem acelerador/RPM e liberação exata após confirmação do motor + 250 ms.
- `test:ui` aprovado em 1280×720, 1920×1080, 2560×1440 e 3440×1440: hierarquia, faróis RGB, cor do neon sem gravação de layout, toggles e retorno. Capturas `headlight-color-*` e `neon-toggles-*` inspecionadas visualmente; usam fundo neutro e não representam a iluminação de uma cena FiveM.
- Os testes existentes de extras, adesivos, persistência de confirmação e controle continuam aprovados.

**Não houve execução do jogo.** Conferir ainda no FiveM: emissão real do neon nos assets instalados, partida/som/trepidação e resposta física dos controles. Testes de natives e browser não aprovam esses aspectos. Para carregar as mudanças de Lua e NUI, reiniciar coordenadamente o perfil pelo txAdmin e reconectar.

Referência de contrato consultada: [VehicleModCollection no código oficial Cfx](https://github.com/citizenfx/fivem/blob/master/code/client/clrcore/External/VehicleModCollection.cs), que usa flags por lado e cor RGB para neon. Não foi incorporado código externo.
