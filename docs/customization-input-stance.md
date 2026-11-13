# Customizar: teclado, mouse, câmera e suspensão — 17/10/2026

Atualização posterior: [controles da garagem](garage-controls.md) substitui a organização de rodas, botões de apresentação, F4 e acionamento do motor descritos abaixo.

Esta entrega ajusta a base txAdmin existente. Prevalece sobre instruções anteriores que descreviam menu sem cursor, ações F9/F10 e presets antigos de câmera. Dados salvos, onboarding, lobby, permissões e controlador de prévias foram preservados. mx-gearbox e mx-turbo não foram modificados.

## Interface e navegação

- Lobby, garagem, editores e menu compacto F1 recebem foco NUI com cursor e teclado. `SetNuiFocusKeepInput(false)` mantém o input na interface enquanto aberta; ao fechar, o foco é liberado. Não há um modo de mouse separado que o jogador precise descobrir.
- No menu compacto, um clique abre/aciona a linha; controles −/+ alteram valores. Voltar e Fechar são botões. As caixas de busca, chat e administração agora usam formulário NUI com Confirmar/Cancelar, em vez de depender da confirmação do teclado virtual nativo.
- No editor de peças, um clique abre a categoria ou aplica a opção ao rascunho. Setas continuam experimentando opções; Enter confirma no rascunho. Tab percorre as ações visíveis, sem ficar preso à faixa de peças. O realce não depende de hover.
- A barra de ações contém **Voltar · Câmera livre/da peça · Acelerar · Descartar alterações · Salvar alterações**. F9/F10 foram removidos. Salvar também inclui o valor de um campo inline que ainda esteja aberto. Descartar recupera a configuração confirmada; Voltar continua oferecendo Salvar/Descartar/Continuar quando há rascunho.
- Câmera livre tem arraste na área da cena, roda do mouse e botões para girar, subir, descer e aproximar/afastar. Esses botões também funcionam com Tab/Enter. Acelerar funciona mantendo seu botão pressionado com mouse ou teclado. F4 permanece apenas como alternativa compatível, sem ser necessário para operar a interface.
- As instruções de navegação no rodapé da customização foram substituídas pelas ações. Não há textos F9/F10 nem a linha “Navegar / Enter Selecionar / Backspace Voltar”.

Todas as scrollbars da NUI foram ocultadas. As listas horizontais com mais itens apresentam cerca de 3,5 opções; itens adjacentes parcialmente visíveis indicam continuação. Roda do mouse, setas da faixa e teclado percorrem a lista. A seleção fica inteira no viewport. O menu compacto recorta a próxima linha, com altura de 8,5 linhas. Formulários continuam roláveis.

A rolagem automática distingue teclado de ponteiro: receber foco durante mouse-down não desloca a peça antes do mouse-up. Ao concluir o clique ou navegar por teclado, a opção selecionada pode ser centralizada. Isso evita perder cliques quando a lista muda de posição.

## Hierarquia e apresentação

```text
Customizar
├─ Carroceria: para-choques, saias, capô e demais peças do modelo
├─ Exterior: pintura/liveries, iluminação, detalhes/extras e acabamento interno
└─ Suspensão: rodas, altura, cambagem, afastamento, tamanho e largura
```

As capacidades nativas continuam determinando as peças disponíveis. Funcionalidades existentes foram reorganizadas, sem depender de vMenu ou importar outro editor. Desempenho permanece sujeito à configuração anterior, desabilitado por default.

O título principal da seção passou a **Customizar**. Todas as subseções usam a mesma classe `section-title`, maior e com tamanho padrão. O breadcrumb menor mostra a origem. Carroceria, Exterior e Suspensão usam os ícones locais já existentes; nenhuma textura de jogo foi extraída.

## Câmeras e movimento: causas encontradas

O código anterior tinha causas distintas que podiam somar seus efeitos:

1. A câmera livre reutilizava o camera handle e **não redefinia seu FOV**. Assim, herdava o enquadramento fechado da peça. Sua distância mínima limitava apenas a aproximação à carroceria, sem garantir enquadrar o carro completo.
2. Presets usavam FOVs estreitos e distâncias sem um cálculo do volume que precisava caber na tela. Havia também uma variável `length` da linha de mira que sombreava o comprimento do veículo nas verificações posteriores.
3. O realce das categorias solicitava mudanças de câmera. Repetir um contexto podia recriar a câmera e interpolar novamente. A cena principal ainda deslocava a mira periodicamente com seno do relógio.
4. Cada aplicação cosmética de apresentação chamava `SetVehicleOnGroundProperly`, mesmo com a mesma entidade já colocada no chão, e reaplicava mods de roda sem verificar se tinham mudado.
5. O personagem clonado iniciava uma animação de entrada de cenário depois de congelado. A colocação do personagem também calculava altura a partir do bounding box, sem medir os pés da pose real.

Correções implementadas:

- Peças usam FOV moderado explícito de **55°**, margem por região/modelo e distância calculada pelo volume e proporção de tela. A câmera livre define **60°** e limita a aproximação pela distância necessária para enquadrar o carro inteiro. Não herda zoom da peça.
- A câmera livre valida sua posição inicial contra cenário; se não houver espaço, mantém a apresentação anterior e informa erro. As consultas de colisão e a proteção contra transições pela carroceria continuam ativas.
- Realçar categorias não move câmera. Abrir uma peça/contexto pode mudar o enquadramento. Pedir novamente o mesmo contexto válido não recria a câmera. A oscilação automática da mira foi removida.
- Colocação no chão e desligamento inicial do motor acontecem uma vez por apresentação. Mods e família de rodas só são alterados quando necessário. A descoberta de famílias por modelo é reutilizada, evitando alterná-las a cada prévia.
- O ator externo não inicia animação de entrada de cenário. `WorkshopPresentation.ground` alinha os bones dos pés ao chão consultado, usa pose parada e congela após a colocação. Não soma novamente a altura do bounding box. Ragdoll do jogador é restaurado ao sair.

Calibração centralizada em `experience/config.lua`: `parts`, `orbit`, `actor`, `framing`. `/mxworkshopdebug` também mostra contexto/FOV/posição da câmera e ponto do ator, para conferência no jogo.

Essas são correções sustentadas pelo código e testes disponíveis. Sem cliente FiveM, não se afirma que clipping, posição visual dos pés ou enquadramento final foram aprovados no GTA.

## Suspensão e persistência

Implementação própria no domínio vehicles: `stance-rules.lua` valida o documento; `stance.lua` aplica os natives visuais e acompanha entidades gerenciadas. O core não recebeu regras de suspensão.

| Ajuste | Intervalo | Unidade |
| --- | --- | --- |
| Altura relativa | −0,15 a +0,15 | metros; positivo sobe, negativo abaixa |
| Cambagem dianteira/traseira | −12 a +12 | graus, espelhados entre lados |
| Afastamento dianteiro/traseiro | −0,12 a +0,20 | metros por roda; positivo para fora |
| Tamanho das rodas | 0,80 a 1,25 | multiplicador da referência nativa |
| Largura das rodas | 0,70 a 1,35 | multiplicador da referência nativa |

Esta versão admite carros com quatro rodas. Tamanho/largura exigem rodas de personalização instaladas; em rodas originais os controles mostram o motivo da indisponibilidade. “Restaurar suspensão original” restaura a referência da entidade. Não há alteração de handling, potência, torque, física de drift, toe ou caster.

O campo opcional `stance` fica no JSON de propriedades da garagem, com versão própria 1. Documentos antigos continuam válidos como `stance=false`; não foi necessária outra migration nem conversão dos registros existentes. Prévia, rascunho, Salvar/Descartar e replay por UUID continuam passando pelos contratos da oficina. A gravação exige validação servidor e aplicação nativa existente antes da confirmação.

O servidor publica `mxStance` junto ao marcador da entidade gerenciada. Clientes validam campos/limites, identidade e modelo antes de aplicar. Uma lista local de entidades acompanha streaming e aplica offset/cambagem por quadro, como exigem os natives. Tamanho/largura são recuperados se outros natives os resetarem. A referência permanece estável por identidade/modelo, evitando acumular ajustes ao trocar família de rodas. Respostas de estado antigas não substituem uma aplicação local autorizada que ainda aguarda confirmação correspondente.

Remoção/reuso de handle invalida o cache; a parada do resource restaura apenas referências ainda pertencentes à mesma entidade. Não há remoção indiscriminada de veículos. A assinatura mantém o formato anterior para carros sem stance e acrescenta os valores de stance quando usados, para não misturar configurações diferentes no ranking existente.

## Referências técnicas

- [VStancer, carmineos](https://github.com/carmineos/fivem-vstancer): referência de organização de ajustes e aplicação visual por roda. [Licença MIT verificada](https://github.com/carmineos/fivem-vstancer/blob/master/LICENSE). Não foi importado seu código C#, MenuAPI ou outro resource.
- [WheelScript do VStancer](https://github.com/carmineos/fivem-vstancer/blob/master/VStancer.Client/Scripts/WheelScript.cs): referência para atualização local das rodas e comportamento entre clientes.
- Cfx: [offset por quadro](https://github.com/citizenfx/fivem/blob/master/ext/native-decls/SetVehicleWheelXOffset.md), [rotação/cambagem](https://github.com/citizenfx/fivem/blob/master/ext/native-decls/SetVehicleWheelYRotation.md), [altura visual](https://github.com/citizenfx/fivem/blob/master/ext/native-decls/SetVehicleSuspensionHeight.md), [tamanho](https://github.com/citizenfx/fivem/blob/master/ext/native-decls/SetVehicleWheelSize.md) e [largura](https://github.com/citizenfx/fivem/blob/master/ext/native-decls/SetVehicleWheelWidth.md).
- Cfx: [ClonePed](https://github.com/citizenfx/natives/blob/master/PED/ClonePed.md) e [animação de entrada de cenário](https://github.com/citizenfx/natives/blob/master/TASK/TaskStartScenarioInPlace.md).

A altura do native é visual: a colisão não acompanha essa alteração. A entrega preserva esse limite; não simula mudança física de suspensão.

## Arquivos e verificações

| Área | Arquivos principais |
| --- | --- |
| Input/foco | `menu/client.lua`, `SessionMenu.tsx`, `Lobby.tsx` |
| Editor/ações/rolagem | `VehicleEditor.tsx`, `OrbitSurface.tsx`, `style.css` |
| Câmera/personagem | `experience/client.lua`, `framing.lua`, `presentation.lua`, `config.lua` |
| Suspensão/propriedades | `vehicles/stance-rules.lua`, `stance.lua`, `properties.lua`, `customization.lua`, `client.lua`, `fxmanifest.lua` |
| Verificação | `tests/stance*.lua`, `presentation*.lua`, `ui.mjs`, `database.mjs`, `mx-verification/experience.lua` |

Executados: build Vite e typecheck, `npm run check`, `npm test`, `npm run test:db`, `npm run test:ui`, `npm run test:lobby` e `git diff --check`. O projeto não tem tarefa ESLint; `check` é verificação estrutural, não lint completo.

- **51 arquivos Lua** analisados; **24 verificações de stance**, **2.487 de apresentação/geometria**, regras existentes, controlador de prévias e LatestPreview. Natives simuladas estão identificadas como testes unitários.
- Browser em **1280×720, 1920×1080, 2560×1440 e 3440×1440**: teclado/mouse no menu compacto, caixa de texto confirmável, clique em peças, preservação da seleção, roda de índice 250, campos RGB/placa, sliders, descarte, Salvar incluindo campo inline, órbita por arraste/botões, seleção inteira no viewport, scrollbars ocultas e nenhuma solicitação de câmera ao apenas realçar categorias. Capturas renderizadas inspecionadas.
- MariaDB real: JSON de stance gravado e recuperado por nova conexão SQL. FXServer isolado em 30131: **11/11 verificações de experiência/garagem**, incluindo stance por exports reais. O servidor auxiliar foi encerrado; o principal não foi reiniciado. A falha de FK esperada exercita rollback.
- Uma execução do navegador de loading/lobby encerrou durante captura; a repetição isolada concluiu as quatro resoluções. Nenhuma aprovação de jogo foi inferida desse teste.

Evidências: [UI](evidence/ui.json), [lobby](evidence/lobby.json), [persistência no FXServer](evidence/stance-runtime.json), [Customizar](evidence/heat-editor-1920x1080.png), [lista de rodas](evidence/heat-wheel-options-1280x720.png), [ajuste de altura](evidence/stance-editor-1920x1080.png), [controles da câmera livre](evidence/free-camera-ui-1920x1080.png).

**Pendente no FiveM:** conferir FOV real de peças e órbita, chão/pés do ator, ausência de movimento ao navegar, foco/cursor/input, prévia e descarte em todos os modelos, rodas compatíveis/incompatíveis, reparo/reentrada/restart e recuperação visual após reconexão. **Dois clientes:** sincronização de stance, streaming e troca de owner. Os testes de servidor tiveram zero clientes de jogo. Reinicie coordenadamente o perfil txAdmin e reconecte para carregar os scripts atualizados.

## Atualização de 24/10/2026

Veja [câmeras, portas, motor e suspensão](tuning-cameras-engine-stance-2026-10-24.md) para o comportamento atual: mira por bones e composição acima da faixa inferior; órbita mais baixa com opções ocultáveis por H; portas interpoladas em 650 ms; acelerador nativo sem escrita artificial de RPM e motor desligando após 15 s de inatividade; correção do retorno BOOL inteiro 1 nos natives das rodas; prévia local de stance sem debounce, mantendo confirmação/salvamento existentes. As verificações históricas de banco descritas acima não foram repetidas nessa atualização.
