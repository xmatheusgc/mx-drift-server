# Loading contextual e discreto — 25/10/2026

O usuário confirmou melhora do feedback, mas relatou duas interrupções na troca de carro: backdrop da prévia seguido de tela opaca “Preparando a próxima tela”. A segunda era disparada por `screenFade`, que representa o estado nativo da imagem, inclusive seu fade-in curto. Esse sinal não identifica uma nova operação de carregamento.

## Pesquisa e aplicação

A [NN/g descreve os limites de resposta de aproximadamente 0,1 s, 1 s e 10 s](https://www.nngroup.com/articles/response-times-3-important-limits/): respostas rápidas preservam o fluxo; esperas maiores precisam de feedback mais informativo. A [Apple recomenda contextualizar o carregamento e distinguir progresso conhecido de indeterminado](https://developer.apple.com/design/human-interface-guidelines/loading). O [componente oficial Material oferece atraso configurável para exibir indicadores](https://github.com/material-components/material-components-android/blob/master/docs/components/LoadingIndicator.md).

Aplicação ao projeto: feedback deve pertencer à operação, não a qualquer efeito visual. Preservar o cenário e a navegação quando a espera afeta somente o carro; esconder o mundo apenas quando a cena está em preparação. Não inventar percentual ou estimativa. Os limiares de 600 ms e 10 s abaixo são escolhas deste projeto, ajustáveis após avaliação no FiveM, e não regras universais dessas fontes.

| Situação | Comportamento implementado |
| --- | --- |
| Prévia em menos de 600 ms | Sem overlay, spinner central ou backdrop; seleção e estado dos controles continuam respondendo. |
| Prévia acima de 600 ms | Aviso pequeno no canto superior direito, sem cobrir a cena ou interceptar cliques. |
| Prévia acima de 10 s | Mesmo aviso acrescenta explicação da primeira visita e tempo decorrido. |
| Fade nativo de conclusão | Nenhuma nova tela de loading. Mantém os guards existentes de input durante o fade. |
| Preparação explícita de cena | Cobertura imediata para segurança; texto e spinner só aparecem após 600 ms. |
| Conclusão, erro ou saída da garagem | Cancela timers e remove o indicador. Resposta antiga não faz o aviso reaparecer. |

Não foi imposto tempo mínimo artificial de exibição ou atraso para entregar o resultado. O indicador é pequeno e tem entrada suave; assim, a conclusão remove o feedback imediatamente sem prolongar uma espera já terminada. Redução de movimento desliga sua animação de entrada. O tempo decorrido não é anunciado a cada segundo por leitor de tela.

## Código

- `development/ui/src/LoadingHint.tsx`: aviso de prévia vinculado ao estado real da operação, timers limpos e detalhamento progressivo.
- `Workshop.tsx`: substitui o overlay de tela inteira pelo aviso. Mantém cancelamento, última seleção e bloqueio das ações que exigem uma prévia confirmada.
- `screen-transition.ts`: cobertura opaca depende exclusivamente de `loadingStatus`, nunca de `screenFade`. Indicador de cena tem atraso de 600 ms; cobertura protetora não espera esse prazo.
- `style.css`: composição compacta sem captura de ponteiro; respeita redução de movimento.
- Bundle do menu reconstruído. Nenhuma mudança de prazos de streaming, critérios de prontidão, rollback, Lua, câmera ou persistência.

## Validação

Build/TypeScript e check estático passaram. Testes dedicados de loading passaram com quatro resoluções: 1280×720, 1920×1080, 2560×1440 e 3440×1440. Foram exercitados o componente e a tela Workshop reais com transporte simulado: resultado rápido cancela o indicador atrasado; espera longa informa sem backdrop; erro remove aviso e mostra mensagem; fechamento com resposta pendente não ressuscita o aviso; fade nativo não abre página opaca. Regressões anteriores de cold join/recuperação/RPC passaram nesta rodada.

Evidência: `docs/evidence/loading-feedback-2026-10-25.json` e `preview-discreet-*.png`. O fundo das capturas é uma fixture de navegador, não imagem do mundo FiveM. Esses testes não comprovam percepção de fluidez no jogo.

Também passaram `test:lobby` e `test:ui` em quatro resoluções. Captura de prévia em 1280×720 inspecionada, com texto legível e sem sobreposição à faixa inferior. A suíte Lua geral não foi repetida: o bloqueio preexistente de câmera/FOV continua fora do escopo desta alteração de apresentação.

Não houve reinício ao vivo. Após carregar o menu atualizado, validar no FiveM seleção rápida de vários carros, modelo sem cache, erro de modelo e entrada lobby → garagem. O jogador deve continuar vendo a cena nas prévias; a proteção opaca permanece nas mudanças reais de cenário. Este relatório substitui a decisão anterior de mostrar uma tela opaca para qualquer fade nativo.
