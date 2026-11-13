# Interface durante transições pretas — 24/10/2026

Origem: proprietário aprovou as transições pretas existentes e pediu para esconder a interface durante os carregamentos entre telas. Projeto Drift em C:\FiveM\drift-server.

O menu agora acompanha `IsScreenFadingOut`, `IsScreenFadedOut` e `IsScreenFadingIn`, enviando `screenFade` somente quando o estado muda. Poll por frame enquanto há menu aberto ou fade em andamento, e 100 ms fora desses contextos. O código aceita retorno booleano ou inteiro 0/1 dos natives.

O controlador NUI combina duas condições independentes: fade nativo e transição entre telas/entrega do loading inicial. A raiz visual React fica invisível enquanto qualquer condição estiver ativa, incluindo menus, HUD e overlays de desenvolvimento. O véu preto da NUI permanece fora dessa raiz. A interface volta após o fade terminar e a tela de destino ter sido montada/pintada.

Os componentes continuam montados: mensagens de estado e confirmações de carregamento continuam funcionando, sem limpar campos, seleção ou sessões por causa da ocultação. Foco anterior é recuperado quando ainda pertence à tela; caso a tela tenha sido trocada, usa um controle da nova tela. Durante a ocultação, teclado, ponteiro e mensagens de navegação do controle são interceptados. Trocas internas de aba/opções não passam a ganhar tela preta.

Mensagens `loadingClosed` atrasadas fora da entrega inicial são ignoradas, para não encerrar a cobertura de uma troca mais recente. Essa entrega inicial tem um único responsável por revelar a UI, evitando duas animações concorrentes liberarem a interface cedo.

Arquivos: `menu/client.lua`, NUI `screen-transition.ts` e `style.css`, bundle e regressões existentes `trainer-menu.lua`/`lobby.mjs`.

Verificação: build/typecheck, check e suíte completa com adaptadores aprovados. Ponte Lua exercita 0/1, começo do fade, preto sólido, fade de entrada, restauração e ausência de mensagens redundantes. Browser de lobby/loading em quatro resoluções exercita UI invisível mas montada, bloqueio de três formas de input, sobreposição de máscaras, foco e recuperação de erros. Navegação geral de UI também verificada em quatro resoluções. Testes de browser usam mensagens simuladas e não validam o fade real de FiveM.

Sem restart, cliente FiveM ou mudanças de dados de jogador. Próximo passo: reiniciar/reconectar e conferir lobby ↔ garagem e saída para modo livre, com interface reaparecendo apenas no fim da transição. Memória somente no export local; Obsidian compartilhado sem escrita permitida.

Após o ajuste final para evitar dois fades concorrentes na entrega inicial, build/typecheck/check e browser de lobby/loading foram repetidos com o bundle final nas quatro resoluções e passaram. O browser geral já havia passado antes desse último ajuste. Captura `docs/evidence/interface-hidden-loading-1280x720.png` inspecionada: somente preto, sem interface; capturas posteriores de lobby mostram a UI restaurada. A validação real no FiveM permanece pendente.
