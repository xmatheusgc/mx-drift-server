# Recuperação de diâmetro no SC300A

Data local: 24/10/2026, aproximadamente 02:23, America/Sao_Paulo. Origem: relato/F8 do proprietário, código local, documentação primária Cfx e testes por Codex. Projeto: C:\FiveM\drift-server\txData\FiveMBasicServerCFXDefault_CAECC7.base.

O proprietário relatou erro STANCE ao aumentar o diâmetro no SC300A. O controlador abortava toda a aplicação ao receber recusa do native. Implementada recuperação por dimensão: tentar restaurar estado anterior, ler dimensão efetiva, preservar os demais ajustes e devolver stance efetivo no ACK. A interface mostra aviso e desabilita somente o campo recusado. Limitação local por identidade/modelo/conjunto de rodas evita repetição por frame; trocar rodas permite nova verificação. Sem blacklist de modelos e sem alteração do asset SC300A.

Prévia, spawn, edição e salvamento usam propriedades efetivas confirmadas; valor recusado não vira configuração salva bem-sucedida. Presets antigos não são regravados automaticamente ao carregar. Payload inválido, identidade, posse e ACK obrigatório continuam protegidos. Removida aplicação duplicada de stance no callback principal.

Suíte completa, 42 verificações de stance, regressões de ACK de prévias, build, typecheck e checks aprovados. Browser aprovado em quatro resoluções com fixture de recusa, edição de largura e salvamento efetivo; captura 1280×720 inspecionada. Não houve cliente FiveM, restart ou alteração de dados de jogador. Causa específica do asset e suporte nativo real do SC300A não confirmados.

Próximo passo: restart completo pelo txAdmin, reconexão e reteste SC300A com rodas do relato, salvamento/recriação e troca do conjunto de rodas. Relatório: docs/stance-wheel-recovery-2026-10-24.md; evidência JSON homônima em docs/evidence.

Registro salvo somente no export do workspace. A base Obsidian compartilhada está fora das permissões de escrita desta sessão e não foi atualizada.
