# Tunagem: câmeras, motor e stance — 24/10/2026

Projeto: Drift server FiveM, C:\FiveM\drift-server. Aplicativo: Codex. Origem: pedido do proprietário sobre foco das peças, órbita baixa, portas fluidas, aceleração natural e rodas bloqueadas.

Confirmada causa do log de rodas: setter retornava 1 com dimensão correta, mas comparação Lua exigia true. Corrigido para true/1 com readback obrigatório. Comparado WheelModScript.cs do vStancer; mesmos natives visuais, sem importar resource/C# ou modificar colisores. Prévia da suspensão passou a caminho local com validação de sessão/identidade/controle e sem debounce; manter/restaurar continuam pelo fluxo de confirmação existente. Fila interrompe timers cancelados e mantém ordem de aplicações em curso.

Câmeras de detalhe usam bones válidos/fallback, distâncias específicas e projeção do centro da peça a 38% da altura da tela. Órbita mais baixa, mira baixa, clearance menor e colisão preservada. C ativa/encerra órbita; H/botão alterna opções inicialmente ocultas. Câmeras principais aprovadas preservadas. Portas interpoladas em 650 ms a partir do ângulo observado, incluindo reversão.

Motor já tinha motorista real invisível e clone fora. Removidos RPM/limitador e atraso artificial por script. Controle do motorista habilitado temporariamente e acelerador nativo liberado, com demais inputs bloqueados, carro congelado e freio de mão. ACK de motor ligado continua necessário; gatilho analógico, liberação e expiração de heartbeat preservados. Idle de 4 para 15 s; estado anterior de controle restaurado ao terminar.

Verificação: build/typecheck/check/suíte completa aprovados, 50 verificações de stance; testes com natives/transportes simulados para geometria, portas intermediárias, motor sem escrita de RPM, export rápido e isolamento de sessão. Browser em quatro resoluções e capturas de interface; renderer/áudio reais dependem de FiveM. Sem restart, banco real ou dados de jogador alterados.

Próximo passo: reiniciar/reconectar e conferir no FiveM som/RPM natural, portas, enquadramento de mods, câmera baixa e diâmetro/largura com rodas de personalização. Relatório: docs/tuning-cameras-engine-stance-2026-10-24.md. Somente export local; base Obsidian compartilhada fora da permissão de escrita.
