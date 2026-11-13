# Destaque de seleção, equipado e Espaço — 18/10/2026

- Opções destacadas recebem `transform: scale(1.035)` com transição de 100 ms. O tamanho base do grid e a ordem de navegação permanecem; o cartão sobe na pilha visual para ampliar sobre seus vizinhos. Aplicado a botões da oficina/lobby, opções do menu lateral e linhas selecionadas de suspensão/preferências. A preferência de movimento reduzido do navegador remove a animação.
- Faixas roláveis ganham 6 px de respiro vertical para a ampliação. O espaçamento horizontal existente permanece.
- O CHECK foi substituído por **EQUIPADO**, em uma etiqueta verde com texto preto no canto superior esquerdo. A regra de equipamento continua baseada na configuração confirmada, incluindo extras e neons. Destacar uma prévia não troca a etiqueta de equipamento.
- **Espaço** substitui L-ALT para abrir/fechar portas na customização. O controle continua em **L3**. A dica usa um glifo sólido de barra de espaço desenhado no projeto. Campos de texto continuam aceitando espaços, e modais mantêm seu contexto de interação.

Verificações: build, typecheck, check estático e suites de browser de oficina/lobby nas resoluções existentes. O teste da etiqueta confere texto, cores e ampliação; o teste de atalhos usa Espaço e a mensagem equivalente do controle. As verificações de alinhamento do grid comparam a geometria de layout, pois a caixa visual de uma opção ampliada deve ser diferente.

Capturas: `docs/evidence/equipped-badge-*.png`. Relatório por resolução: `docs/evidence/ui.json`.

Não foi executado cliente FiveM. Conferir o efeito na NUI do jogo e a tecla física de portas. Nenhuma configuração salva ou regra de veículo foi alterada.
