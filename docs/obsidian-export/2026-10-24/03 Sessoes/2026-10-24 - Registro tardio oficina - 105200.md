# Registro tardio da oficina

Data local: 24/10/2026, aproximadamente 10:52, America/Sao_Paulo. Projeto: C:\FiveM\drift-server. Origem: relato do proprietário, código local e testes por Codex.

Na primeira abertura, experience/scene falhou com SCENE_ASSET para denis3d_ts_shell; clicar novamente em GARAGEM no lobby funcionou. A verificação local exigia registro imediato do modelo mesmo com resource started. Manifest e YTYP instalados conferidos, sem alteração. Registro tardio é compatível com o relato, mas seu instante real não foi medido.

Corrigida espera de registro a cada 50 ms, dentro do prazo compartilhado da cena de 30 s. Só pedir modelo registrado, uma vez. Não confirmar oficina antes de modelo/cena/colisão/interior e estabilidade. Ausência até o prazo continua SCENE_ASSET; cancelamento/resource indisponível mantêm falha e limpeza. Callback core de 35 s preservado.

Suíte completa e check aprovados. Regressões com natives simulados: registro em 900 ms, pedido único, interior/estabilidade posteriores, cancelamento na espera, ausência permanente e limpeza. Sem rebuild de UI, alteração de dados, restart ou cliente FiveM.

Próximo passo: restart pelo txAdmin, reconexão e testar primeira entrada logo após boot, sem segundo clique. Relatório: docs/scene-registration-2026-10-24.md; JSON em docs/evidence.

Esta sessão e a nota de projeto foram salvas somente no export do workspace. A base Obsidian compartilhada não foi atualizada por falta de permissão de escrita.
