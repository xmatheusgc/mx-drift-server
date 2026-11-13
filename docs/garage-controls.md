# Controles da garagem — 17/10/2026

Atualização mais recente: [navegação, câmera e partida](garage-navigation-polish.md), incluindo tecla C, Q/E e shoulders.

Atualização posterior: [aplicação imediata e controles unificados](immediate-customization.md) substitui os glifos próprios e a barra Salvar/Descartar descritos neste histórico.

`Customizar > Peças e rodas` reúne modelos de rodas e peças do modkit. `Exterior` mantém pintura, iluminação e detalhes. `Suspensão` mantém altura, cambagem, afastamento, tamanho/largura e suspensão do modkit. Sem alterações de registros salvos ou formato das propriedades.

A faixa apresenta cerca de 6,5 itens, com mínimo de 112 px e a próxima opção parcialmente visível. Voltar/Câmera livre/Acelerar foram substituídos por indicações sem clique no mesmo estilo. Salvar e Descartar continuam clicáveis. Seta para baixo leva às ações, esquerda/direita alterna entre elas e seta para cima volta às opções.

| Ação | Teclado | Xbox | PlayStation |
| --- | --- | --- | --- |
| Voltar | Esc | B | Círculo |
| Mudar visão | Alt esquerdo | Y | Triângulo |
| Testar motor (manter pressionado) | W | RT | R2 |

O jogo informa o último dispositivo; a NUI identifica PlayStation pelo identificador USB quando disponível. Drivers que emulam XInput podem ocultá-lo: `ExperienceConfig.controllerIcons` permite `auto`, `xbox` ou `playstation`, afetando apenas os glifos quando um controle está em uso. Glifos CSS/SVG próprios, sem dependência externa. Referências pesquisadas: [Kenney Input Prompts, CC0](https://kenney.nl/assets/input-prompts) e [controles Cfx](https://docs.fivem.net/docs/game-references/controls/).

A visão livre usa câmera scriptada e geometria do veículo, não câmera de gameplay. Arrastar gira ao redor do carro; roda do mouse ajusta distância. Analógico direito gira/inclina. Mantidos limites de enquadramento e consultas de colisão; sair recupera a câmera da peça. Corrigido `workshopCamera`: agora enviado pelo resource `menu`, dono da `ui_page`, após o evento local de experiência. `SetNuiFocusKeepInput` só permanece ativo durante o editor; experiência desabilita gameplay por frame e consulta os controles desabilitados.

O motor de apresentação começa desligado, sem início automático. Acelerar solicita partida não instantânea; a rotação sobe até a faixa .94–1,0 para apresentar o limite de giro. Ao soltar, cai para marcha lenta e desliga após 4 segundos. `ExperienceConfig.engineTest` centraliza parâmetros. Apenas a entidade gerenciada recebe estado temporário, removido ao sair. Sem alterações de handling, transmissão ou física.

Verificações: build/typecheck, análise estática, suíte Lua (2491 verificações de apresentação/enquadramento, incluindo desligado inicial, limite, marcha lenta e timeout) e navegador em quatro resoluções para categorias, glifos, W/Alt, arraste e rascunhos. Capturas em `docs/evidence`. Testes de navegador usam fixtures; Lua simula natives. Pendente no FiveM: controle físico sob foco NUI, identificação USB/driver, partida e áudio no corte, câmera/colisão e retorno à peça. Não houve validação no jogo nesta entrega.
