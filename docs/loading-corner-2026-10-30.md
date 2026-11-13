# Loading no canto — 30/10/2026

Pedido: manter o fundo escuro e reduzir a quantidade de texto, com spinner à direita e texto à esquerda, ambos no canto inferior direito. O usuário relatou que o feedback anterior funcionou bem.

## Pesquisa e decisões

- [NN/g — Progress indicators](https://www.nngroup.com/articles/progress-indicators/): a espera precisa de feedback; esperas longas se beneficiam de informação adicional e progresso real quando disponível. Não existe estimativa confiável de término do streaming local, portanto não foi criado percentual global ou prazo fictício.
- [Carbon — Inline loading](https://www.carbondesignsystem.com/building-blocks/core/components/inline-loading/guidelines): rótulos curtos descrevem a ação em andamento; detalhes são opcionais. Aplicado ao conteúdo do indicador, mantendo a cobertura de cenário própria do jogo.
- [W3C — Status messages](https://www.w3.org/WAI/WCAG22/Understanding/status-messages.html): estados acessíveis sem exigir foco e sem anúncios excessivos. Mantidos status sem mover foco, relógio fora dos anúncios e redução de movimento.

Os tempos de 600 ms, 10 s e 60 s são escolhas do projeto, não exigências universais das fontes.

## Resultado

- Entrada inicial e transições explícitas de cenário usam fundo preto, margens responsivas e bloco de até 400 px no canto inferior direito. Spinner de 24 px, à direita do texto.
- Removidos marca/slogan grandes e barra visual na entrada inicial. Percentual real de recursos e contagem de arquivos continuam aparecendo quando fornecidos pelo FiveM; o elemento semântico de progresso permanece acessível, sem barra visual. Concluir recursos não representa concluir o acesso.
- Mensagem principal curta; detalhes técnicos de preparação não aparecem no loading normal. Explicação de primeira entrada/visita somente após 10 s. Relógio somente após 60 s.
- Silêncio de eventos por 60 s não é erro. Após 300 s sem evento, orientação condicional pede conferir também o download do FiveM antes de reconectar. Eventos retomados limpam essa orientação.
- Erro confirmado mostra motivo e ação imediatamente; indicador deixa de girar e passa a exibir exclamação. Mensagens tardias de arquivos não sobrescrevem o erro.
- Cobertura de cenário continua imediata, com indicador atrasado em 600 ms e sem duração mínima artificial. Conclusão/erro continuam liberando a interface pelos fluxos existentes.
- Prévia de carro continua com aviso contextual sem fundo opaco, como na decisão de 25/10. Não foram alterados streaming, timeouts, rollback, câmera ou persistência.

## Verificação

Build/TypeScript e check estático aprovados. `test:loading` aprovado: adapters de cold join/recuperação/RPC e browser em 1280×720, 1920×1080, 2560×1440 e 3440×1440. Novas verificações cobrem canto/margens, ordem texto/spinner, espaço ocupado, mensagens progressivas, relógio, redução de movimento, erro sem animação e limpeza entre operações.

Playwright não tinha seu Chromium baixado neste ambiente; os testes usaram Chrome instalado por `MX_CHROMIUM`, sem instalação adicional. Capturas de espera curta e erro em 1280×720 inspecionadas. Evidências: `docs/evidence/loading-feedback-2026-10-30.json`, `loading-corner-short-*.png`, `loading-corner-error-*.png` e `workshop-corner-short-*.png`.

Bundle servido reconstruído. Sem restart de resources ou validação FiveM nesta tarefa. Próximo passo: carregar o menu atualizado e reconectar para avaliar também o loading inicial no jogo.
`test:lobby` também aprovado nas quatro resoluções (contratos de browser; sem transição nativa FiveM).
