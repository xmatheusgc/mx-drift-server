# Análise das interfaces e direção para o personagem

Data: 2026-10-31. Origem: pedido do usuário, memória do projeto, inspeção do código local e capturas existentes. Escopo desta etapa: análise e vocabulário; nenhuma alteração funcional, build ou restart.

## Identidade existente

A direção registrada pelo usuário é NFS Heat com complemento de Unbound. Código e capturas mostram interface nas bordas e espaço central para a cena 3D, títulos em Barlow Condensed Bold Italic, textos em Barlow Condensed SemiBold, superfícies retas escuras com transparência, branco como destaque de seleção e amarelo-lima como acento. Verde identifica EQUIPADO no contexto de veículos. O velocímetro tem linguagem própria, com Anta e arco laranja; não precisa ditar o estilo do editor.

A composição favorece poucas áreas bem definidas: abas, título, painel de ajustes, faixa de opções e comandos no rodapé. As configurações mais recentes já usam ações contextuais e abas fora do scroll. Essas características são melhores referências para evoluir o personagem que aumentar o formulário atual.

## Estado confirmado do personagem

O editor está em development/ui/src/Workshop.tsx. Há primeira entrada com confirmação de preset ou edição; após a criação, Personagem oferece Roupas e Aparência. O editor contém Rosto, Traços, Cabelo, Aparência, Roupas e Acessórios.

Rosto reúne modelo masculino/feminino, dois presets, heranças/tonalidades, misturas e olhos. Traços lista vinte ajustes. Cabelo possui corte, cor e reflexos. Aparência percorre treze tipos de detalhes, conforme capacidades do ped, com opção/intensidade/cor. Roupas e acessórios mostram modelo e variação conforme capacidades. Há prévia, salvamento com revisão e cancelamento; preservar esses contratos na implementação futura.

O código pede câmera de rosto nas primeiras quatro categorias e de personagem nas duas últimas. Isso não comprova enquadramento, iluminação ou operação visual no FiveM.

## Problemas e oportunidades identificados

- Escolhas são descritas genericamente como Opção N, inclusive cores. Isso dificulta reconhecer e comparar estilos. Paletas visuais e nomes úteis seriam mais legíveis; miniaturas reais exigem ativos ou captura própria.
- Traços é uma lista de vinte sliders; Aparência repete controles por detalhe. Recomenda-se agrupar traços por nariz, olhos/sobrancelhas, bochechas, boca e mandíbula/queixo; abrir apenas os ajustes do grupo escolhido.
- Rosto e Aparência têm significados próximos. Sugestão a validar: chamar o primeiro de Base e o segundo de Pele e detalhes; manter Cabelo e barba juntos pode reduzir procura.
- As abas atuais ficam dentro do painel estreito, com CSS sticky. Recomenda-se colocá-las em uma faixa superior estável como nos editores mais recentes, fora da área rolável.
- O personagem ainda tem botões permanentes de salvar, cancelar e voltar. As telas recentes usam mais o rodapé contextual. Recomenda-se harmonizar a apresentação sem decidir antecipadamente persistência automática: confirmar personagem inicial e revisar alterações posteriores são contextos distintos.
- O botão de preset substitui a aparência em edição. Recomenda-se tornar esse efeito explícito e proteger alterações em andamento.
- Recomenda-se câmera por região e comando de girar/aproximar com indicação no rodapé. Confirmar as capacidades e o comportamento real antes de implementar.

## Vocabulário compartilhado

| Nome simples | Como reconhecer / exemplo |
| --- | --- |
| Tela | Um contexto completo: garagem, personagem ou configurações. |
| Aba | Categoria no topo: Rosto, Cabelo, Roupas. |
| Barra de abas | Faixa que reúne as abas; componente TabBar. |
| Painel lateral | Área com os ajustes, ao lado da cena. |
| Linha de ajuste | Nome e controle na mesma linha; referência SettingsRow. |
| Seletor lateral | Valor que muda para esquerda/direita: ‹ Opção ›. |
| Lista suspensa | Campo que abre opções ao clicar; select atual. |
| Controle deslizante / slider | Barra de menos a mais, como altura da suspensão. |
| Paleta de cores | Conjunto de amostras clicáveis, como na pintura. |
| Miniatura | Pequena imagem de um corte, peça ou preset. Ainda não há catálogo visual desses itens no personagem. |
| Bloco de opção / tile | Retângulo selecionável, como os carros do showroom. |
| Faixa de opções / carrossel | Lista horizontal rolável desses blocos; OptionStrip. |
| Foco | Item que receberá o próximo comando de teclado/controle. |
| Selecionado / ativo | Categoria ou valor escolhido. Não é necessariamente o foco atual. |
| Etiqueta / badge | Texto pequeno de estado, como EQUIPADO. |
| Rodapé de comandos | Ícones de teclas/botões e ações, como Selecionar e Voltar; ControlHints. |
| Ação contextual | Comando disponível naquela tela, mostrado no rodapé. |
| Modal de confirmação | Janela sobre a tela que pede uma decisão; ConfirmDialog. |
| Prévia | Resultado temporário mostrado antes da confirmação. |
| Enquadramento | Posição e distância da câmera em relação ao personagem. |
| Órbita | Câmera girando ao redor do personagem. |
| Área rolável / scroll | Trecho da lista que se move para revelar os demais ajustes. |

Exemplos de pedido: “deixe as abas fixas no topo”; “use um seletor lateral na linha de corte”; “troque a lista de cores por uma paleta”; “aumente o destaque do item em foco”; “coloque concluir no rodapé de comandos”; “aproxime o enquadramento ao editar os olhos”. Não é necessário decorar nomes técnicos: localização, aparência e efeito desejado também bastam.

## Proposta para a próxima etapa (não aprovada nem implementada)

Manter personagem em destaque na cena, categorias fixas no topo e painel de ajustes à esquerda. Separar escolha de categoria de edição detalhada; usar seletores para modelos, sliders com extremos claros para traços e paletas para cores. Preservar confirmação inicial, prévia reversível, revisões/ACK e dados atuais. Definir o fluxo de conclusão posterior com base no padrão contextual já adotado.

## Evidência e limites

Fontes: development/ui/src/{Workshop,TabBar,OptionStrip,SettingsRow,StancePanel,ConfirmDialog,ControlHints,Lobby}.tsx, style.css e resources/[mx]/mx-freeroam-experience/character.lua. Inspecionadas as capturas docs/evidence/garage-home-refined-1280x720.png, stance-editor-1280x720.png, pause-settings-1280x720.png e color-panel-1280x720.png. São evidências históricas de browser com fundo de teste, não capturas atuais do personagem dentro do jogo. A análise do personagem nesta etapa é do código. Sem testes funcionais, pois não houve mudança executável.
