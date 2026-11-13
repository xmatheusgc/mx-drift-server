# Interface oculta nas transições — 24/10/2026

Projeto: Drift server FiveM, C:\FiveM\drift-server. IA: Codex. Origem: proprietário aprovou transições pretas e pediu ocultação da interface durante carregamentos entre telas.

Menu passa a publicar mudanças dos três estados de fade nativo; NUI combina esse estado com sua transição de telas/loading inicial. Raiz React invisível enquanto qualquer máscara estiver ativa, sem desmontar componentes ou limpar campos/seleções. Foco recuperado ao revelar. Teclado, ponteiro e navegação de controle bloqueados enquanto invisível. Loading inicial segue montando e enviando ACK; loadingClosed antigo não encerra outra transição. Abas internas continuam sem nova transição.

Build/typecheck/check/suíte completa aprovados; ponte Lua com 0/1 e ciclo completo de fade simulados. Browser de lobby/loading e navegação geral em quatro resoluções; sem cliente FiveM, restart ou dados de jogador alterados. Próximo passo: carregar/reconectar e conferir lobby/garagem/modo livre no jogo.

Relatório: docs/transition-interface-2026-10-24.md. Somente export local; Obsidian compartilhado fora da permissão de escrita.

Verificação final: após eliminar fade inicial concorrente, recompilado e repetido lobby/loading em quatro resoluções com bundle final, aprovado. Browser geral aprovado antes desse último ajuste. Captura de carregamento preto sem UI inspecionada. Sem teste no FiveM.
