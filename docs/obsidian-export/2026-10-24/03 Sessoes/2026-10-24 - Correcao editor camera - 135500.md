# Correção do editor de câmera — 24/10/2026, 13:55

Projeto: Drift server FiveM, C:\FiveM\drift-server. Origem: relato do proprietário sobre saltos/zoom com mouse e campos numéricos.

Editor passou a criar câmera independente a partir da imagem renderizada antes de cancelar transições. Atualizações escrevem somente posição, rotação ou FOV alterados; floats explícitos nos natives. Mouse 0.04 grau/pixel, Ctrl 0.01; velocidade padrão 0.25 m/s. Campos aplicam valor completo em Enter/blur, não valores parciais digitados. Cancelamento de arraste e proteção contra wheel acidental adicionados.

Confirmado: build/typecheck/check/suíte completa e browser dedicado em quatro resoluções aprovados. Regressões de handoff durante interpolação, 1 cm sem alterar zoom/rotação, rascunho numérico, Enter, incremento 0.01 e mouse. Sem restart, FiveM ou confirmação visual do sintoma. Não foi possível concluir qual caminho gerava o zoom no renderer real.

Próximo passo: reiniciar pelo txAdmin/reconectar e verificar ajustes pequenos no lobby/garagem; depois capturar composições. Relatório: docs/camera-developer-2026-10-24.md. Base Obsidian compartilhada fora da permissão de escrita; este arquivo é somente export local.
