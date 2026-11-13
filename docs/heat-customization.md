Atualização 17/10/2026: [teclado e mouse, Customizar, ações visíveis, câmeras e suspensão](customization-input-stance.md). Este incremento prevalece para input, F9/F10, rolagem e presets de câmera descritos anteriormente.

# Editor inferior, apresentação e órbita — 16/10/2026

Este documento prevalece sobre a descrição anterior de painel lateral/câmera WASD em `vehicle-customization.md`. A base ativa continua sendo a montada pelo txAdmin. Não houve migration nem alteração em massa nos veículos salvos.

## Fluxo e controles

O editor usa uma única barra inferior, com rolagem horizontal. Cada slot visual realmente disponível tem entrada própria: aerofólio, para-choques, capô, saias, escapamento, interior e demais peças. Não existe uma categoria genérica de peças abrindo outro painel. Pintura, iluminação e detalhes usam a mesma barra; RGB e placa abrem controles compactos nessa região.

**Rodas → Sports / Esportivas → modelos de rodas** é um exemplo completo: confirmar a família consulta a quantidade real; navegar pelos modelos experimenta a peça na entidade existente; Enter seleciona no rascunho; voltar restaura o rascunho e preserva a posição da família. Reabrir a família já selecionada conserva o modelo/variação de pneus. Trocar a família experimentada não modifica o registro salvo.

| Comando | Ação |
| --- | --- |
| ←/→ ou ↑/↓ | Navegar no nível atual |
| Enter | Abrir nível ou selecionar opção no rascunho |
| Backspace/Esc | Voltar um nível; na raiz, sair com confirmação de alterações |
| Home/End, PageUp/PageDown | Início/fim e saltos de dez opções |
| Tab/Shift+Tab | Navegar pela barra; nos campos RGB/placa, alternar os campos |
| Espaço, segurado | Subir o giro do motor; soltar permite a queda |
| F4 | Alternar órbita; Esc/Backspace também sai da órbita primeiro |
| Mouse, durante órbita | Ângulo horizontal/altura; roda do mouse aproxima/afasta |
| F9 | Salvar o rascunho confirmado |
| F10 | Cancelar e recuperar a criação salva |

Uma opção destacada é apenas uma prévia. Enter altera o rascunho; F9 persiste esse rascunho, mesmo que outra opção esteja sendo experimentada. RGB/placa seguem a mesma distinção: Enter confirma o campo no rascunho, Esc descarta a edição temporária. A fila de prévias aplica uma por vez e descarta pedidos intermediários; salvar/cancelar aguardam e invalidam a fila antes de restaurar/gravar. A aplicação automática antiga de rascunhos da oficina foi desativada para veículos, evitando duas origens concorrentes de prévia.

## Motor e personagem

`experience/presentation.lua` gerencia uma sessão local com identidade própria:

1. Clona a aparência do ped confirmado que está na oficina. A cópia é local, congelada, sem colisão, invencível e sem eventos de gameplay.
2. Oculta o jogador real com visibilidade e alpha antes de colocá-lo como motorista da prévia. Só então mostra a representação externa, na posição calculada junto à roda dianteira direita.
3. Liga o motor real e usa `SetVehicleCurrentRpm` para subir/baixar o giro. Não há arquivo de áudio, loop genérico ou alteração de handling. Não é aplicado comando de acelerador/torque às rodas.
4. Mantém a carroceria congelada, freio de mão acionado e esterçamento zerado. Esses estados são transitórios da apresentação e não entram no documento salvo.
5. Ao sair/cancelar/trocar a prévia, remover um resource ou perder a entidade administrada, apaga somente sua cópia identificada, retira o motorista oculto e restaura visibilidade/alpha/colisão e posição externa do ped real. O encerramento da oficina restaura os controles e estados de gameplay já existentes.

Cada pulso de aceleração expira em 500 ms; soltar Espaço, perder foco ou editar texto encerra o comando. Chamadas antigas de encerramento não encerram uma sessão nova. Handles reutilizados de veículos ou personagens não autorizam remoção de entidades alheias.

**Não foi possível ouvir o motor no FiveM nesta entrega.** Os testes confirmam a sequência de chamadas e a curva de RPM calculada, mas não provam que o áudio de cada modelo responde ao RPM com a carroceria congelada. Esse é um aceite obrigatório no jogo, antes de considerar o mecanismo aprovado.

## Câmeras e composição

`experience/framing.lua` concentra o mapeamento de slots, referências, mira, direção, distância, altura, FOV e fallbacks. Correções principais:

- Aerofólio: traseira superior, em vez de frente.
- Capô: superfície dianteira vista de cima, com capô fechado; somente peças do cofre abrem o capô.
- Para-choques: frente/traseira em altura baixa adequada.
- Escapamento: saída traseira próxima e baixa, usando `exhaust` quando válido.
- Saias/para-lamas/portas: lateral correspondente; portas direitas observadas pela direita.
- Rodas: referência `wheel_lf`/`wheel_lr` quando válida, observador deslocado para fora da carroceria.
- Teto, porta-malas e interior: regiões específicas; o interior abre a porta dianteira esquerda, com câmera externa.

Bones são consultados e validados; encontrar um bone só altera a mira. A posição do observador é calculada pelas dimensões e heading e permanece fora do envelope da carroceria. O fallback não presume nomes adicionais de bones. Colisão de cenário não pode empurrar a câmera para dentro do carro; o enquadramento anterior é preservado quando necessário.

A órbita tem aproximação mínima pelas dimensões, alcance adicional de 3,5 m e limites de elevação. Não existe deslocamento livre pelo mapa. Sair dela usa um arco de 400 ms ao redor da carroceria, com consultas de colisão, em vez de atravessar o carro em linha reta; redução de movimentos continua respeitada. Categoria, opção, rascunho e câmera da peça são preservados.

A composição principal usa frente/esquerda em três quartos e mira ajustada para deixar o conjunto acima da barra inferior. A distância lateral do personagem aumentou; o solo é solicitado/aguardado e a posição considera o mínimo vertical do modelo do ped para evitar pés enterrados. Os parâmetros principais e da órbita ficam em `experience/config.lua`. Visibilidade de corpo inteiro, sombras/oclusão e ajuste fino de proporções ainda exigem inspeção no jogo.

## Foco, persistência e entidades

Durante o editor, a NUI recebe teclado com cursor oculto e entrada mantida para leitura do mouse pela órbita. O loop antigo de navegação nativa fica suspenso, evitando duplicar setas/Enter. Controles de gameplay permanecem bloqueados na oficina; Espaço só controla o RPM. Campos de texto/RGB e diálogos suspendem a aceleração e têm tratamento próprio de teclado.

O editor continua usando o domínio de veículos para aplicar propriedades na prévia existente e para persistir na garagem. O núcleo não recebeu regras de peças, motor ou câmera. Os controladores de substituição, cancelamento e identificação da prévia foram preservados. Navegar pela barra não solicita spawn, exclusão ou recarga de modelo; há apenas uma representação externa local adicional, sem criar veículo público ou registro salvo.

## Verificações executadas

- TypeScript/Vite: build aprovado; análise estrutural e `git diff --check` aprovados. Não há ESLint configurado.
- 48 arquivos Lua analisados; testes existentes de regras, personalização, posse de câmera, fila e controlador de prévias passaram.
- 1.197 verificações novas de apresentação/geometria com doubles: ocultação, representação local, subida/queda de RPM calculada, expiração/limpeza, sessões obsoletas, handles reutilizados, posições externas e arcos. A matriz inclui três tamanhos, quatro headings e todos os slots mapeados. Não executa física, áudio ou renderização GTA.
- Playwright em 1280×720, 1920×1080, 2560×1440 e 3440×1440: hierarquia inferior, família/modelos/retorno, índice 250, rascunho distinto de prévia, salvamento correto, RGB/placa, cancelamento, atalhos de órbita e aceleração, manutenção da seleção e zero solicitações de substituição de entidade durante a navegação. Fixtures de contrato, sem natives.
- Capturas do editor renderizado em 1280×720 e 1920×1080 inspecionadas. As imagens usam fundo neutro de teste, sem simular uma cena GTA validada.
- MariaDB real: recuperação integral do documento por nova conexão SQL, propriedade e revisão passaram. Não é reconexão de cliente FiveM.
- FXServer isolado na porta 30131: resources iniciados, banco pronto e 11 verificações com exports reais/SQL passaram. A falha de FK provocada no teste de rollback é esperada. Instância encerrada; servidor principal não reiniciado. Nenhum cliente de jogo conectado, portanto scripts client/GTA não foram executados nessa instância.

Evidências: `docs/evidence/ui.json`, `heat-presentation-runtime.json`, `heat-editor-*` e `heat-wheel-options-*`.

## Roteiro obrigatório dentro do FiveM

1. Abrir a criação na garagem; conferir somente um personagem externo e ausência de motorista visível em todas as câmeras.
2. Segurar/soltar Espaço; ouvir subida/queda do motor real. Comparar `/mxworkshopdebug` antes/durante/depois: RPM deve responder, velocidade deve permanecer zero, posição e heading devem permanecer iguais. O comando só imprime sob demanda; não gera logs por quadro.
3. Testar orbitando e navegando com teclado ao mesmo tempo; conferir zoom/altura, retorno à peça, rascunho e foco sem cursor. Conferir Esc em órbita, em opções, na raiz e no diálogo.
4. Conferir cada região em compacto, coupé e carro maior: roda, capô, para-choques, aerofólio, escapamento, saia, teto e interior. Conferir chão, corpo inteiro e barra inferior na composição principal.
5. Trocar opções rapidamente, salvar uma opção diferente da prévia destacada, cancelar e reconectar. Confirmar documento salvo e ausência de respawn por navegação.
6. Fechar durante respostas atrasadas; trocar modelo, sair para jogar e reiniciar menu/experience/vehicles. Conferir remoção da representação local, restauração do ped real e ausência de prévias abandonadas. Dois clientes continuam necessários para aceitar replicação visual no freeroam.

Referências técnicas consultadas: [ClonePed](https://github.com/citizenfx/natives/blob/master/PED/ClonePed.md), [SetVehicleCurrentRpm](https://github.com/citizenfx/fivem/blob/master/ext/native-decls/SetVehicleCurrentRpm.md), [FreezeEntityPosition](https://github.com/citizenfx/natives/blob/master/ENTITY/FreezeEntityPosition.md), [TaskLeaveVehicle](https://github.com/citizenfx/natives/blob/master/TASK/TaskLeaveVehicle.md) e [SetEntityCoordsNoOffset](https://github.com/citizenfx/natives/blob/master/ENTITY/SetEntityCoordsNoOffset.md). Composição baseada nas imagens Heat fornecidas pelo usuário; implementação própria.
