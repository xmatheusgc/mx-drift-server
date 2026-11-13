# Escala das opções selecionadas — 2026-10-18

A ampliação usa `transform: scale(1.07)` nas opções selecionadas ou com foco. A regra anterior ampliava apenas 3,5% e excluía botões desabilitados, fazendo o efeito desaparecer durante operações de prévia/aplicação.

A barra tinha também `padding: 0 !important`, que anulava o espaço vertical reservado para a escala. Com `overflow` ativo, a parte ampliada ficava cortada. A declaração conflitante foi removida e as barras recebem 10 px acima e abaixo, preservando o recuo horizontal e a rolagem existentes. A transformação não altera as dimensões usadas pelo layout.

O teste de interface mede a largura renderizada, exige ampliação superior a 6%, verifica que o item não seja cortado verticalmente e confirma que a ampliação permaneça quando o botão fica temporariamente desabilitado. O teste de recuo usa a posição de layout, independente da ampliação visual.

Validação executada: build (inclui TypeScript), verificações estáticas, testes de interface e de lobby nas quatro resoluções (1280×720, 1920×1080, 2560×1440 e 3440×1440) aprovados. Captura `docs/evidence/equipped-badge-1280x720.png` inspecionada visualmente.

Não foi executado cliente FiveM. Testes Chromium e capturas de interface não comprovam o comportamento no CEF da sessão do jogador.
