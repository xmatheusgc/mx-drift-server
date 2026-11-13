# Referência zero após modificar rodas

Data: 2026-10-24, aproximadamente 10:40, America/Sao_Paulo. Projeto: C:\FiveM\drift-server. Origem: esclarecimento do proprietário, inspeção do controlador, código upstream Cfx e testes por Codex.

O proprietário confirmou que já havia modificado as rodas quando o diâmetro falhou no SC300A. Rodas originais na tentativa deixam de explicar o relato; o modelo não foi comprovado incompatível.

Encontrado e reproduzido com natives simulados um bug: stance pode capturar tamanho/largura zero antes da troca de rodas e manter essa referência após instalar rodas modificadas, gerando pedido de escala zero. O setter upstream do Cfx recusa zero. Corrigida inicialização por dimensão na primeira leitura positiva das rodas modificadas, sem sobrescrever referência já válida ou acumular escala. Diagnóstico inclui baseline, solicitado, lido e retorno nativo.

Regressão reproduzida removendo a inicialização em VM e aprovada com a correção; suíte completa e check aprovados, agora 47 verificações de stance. Nenhum arquivo de UI/asset alterado neste complemento; build/browser anteriores não foram reexecutados. Sem restart, cliente FiveM ou alteração de dados de jogador. Ainda não confirmado que esse bug causou a tentativa real do proprietário.

Próximo passo: reinício completo/reconexão e testar diâmetro no SC300A após rodas modificadas; se repetir, coletar diagnóstico detalhado. Relatório atualizado: docs/stance-wheel-recovery-2026-10-24.md, complemento 10:40.

Registro apenas no export local do workspace; base compartilhada Obsidian não atualizada por falta de permissão de escrita.
