# Exposição local de carros na oficina — 24/10/2026, 16:35

Projeto: Drift server FiveM (`C:\FiveM\drift-server`). IA: Codex. Origem: proprietário confirmou MLO e autorizou implementar os sete pontos com carros salvos não interativos, priorizando desempenho e reversibilidade.

Implementada exposição de até sete presets locais, excluindo salvo da bancada, somente na garagem privada. Aparência/stance aplicadas antes de mostrar; carregamento sequencial, motor/neons/física/colisão desligados, LOD por carro de 55 m e escala temporária de LOD estendido 0,8 somente na garagem. Não altera o MLO/portals ou configurações gráficas persistentes; custo de modelos/texturas permanece. Não há benchmark nem ganho de oclusão confirmado.

Consulta de documentos limitada por proprietário/contexto/token/epoch, sem polling ou escrita nos salvos. Notificações de revisão/seleção atualizam exposição, mantendo slots inalterados. Limpeza em cancelamento/saída/parada com identidade, repetição de deleção falha e orçamento de entidades preservado. Falhas decorativas opcionais não bloqueiam a garagem.

F8: `mxdisplay 0..7` limita/remove/recarrega localmente; `mxdisplayinfo` informa estado/contadores. Reversão configurável por `ExperienceConfig.display.enabled=false`. Até sete vagas excluindo a bancada; com só um salvo atual não há carros de fundo.

Verificação: suíte completa e check aprovados com natives/SQL/scheduler simulados, incluindo cancelamento, timeout, falha cosmética, isolamento, handles reutilizados e deleções falhas sucessivas. Sem FiveM, restart, banco real ou build de NUI nesta etapa. Relatório: docs/workshop-display-2026-10-24.md.

Próximo passo: carregar recursos atualizados/reconectar e comparar 0/1/3/7 carros com mesma câmera; conferir FPS/GPU/streaming além do resmon, altura/heading/modelos/rodas e limpeza ao sair. MLO não auditado. Somente export local: permissões não permitem atualizar diretamente o Obsidian compartilhado.
