# Entrada, oficina e prévias

Data: 2026-10-23, 23:43 (America/Sao_Paulo).
Projeto: Drift server FiveM — `C:\FiveM\drift-server`.
Aplicativo/IA: Codex.
Origem: logs/relatos do proprietário, código local e testes automatizados.

- Proprietário confirmou que o jogador entrou pela Radmin. Depois relatou `OBSOLETE`, `BUSY` transformados em `INTERNAL`, falhas ao selecionar veículos e oficina incompleta na primeira personalização.
- Corrigido transporte de resultados nos exports/rotas envolvidos, capturando erro antes da fronteira Cfx. Mantidas exclusão, epoch e validação de seleção/entidades.
- Modelo solicitado tem até 30 s para carregar e pode ter a espera cancelada por uma seleção nova. Prévias automáticas continuam funcionando sem intenção da NUI. Prazos: chamada de modelo/cena 35 s, demais ACKs 12 s, pedido completo 120 s, fetch NUI 125 s.
- Oficina agora aguarda cena, colisão, modelo principal e interior prontos sob fade. Preparação tem timeout/limpeza e 250 ms de estabilidade. Manifest de ps-tuners passou a registrar explicitamente YTYP.
- Build/typecheck, check e testes novos de atraso/cancelamento/exports aprovados. UI e lobby/loading aprovados em quatro resoluções com Chrome instalado. A suíte Lua executou os testes funcionais, mas o comando falha na verificação final do handling ER34N instalado, com três subtipos vazios; esse asset não foi alterado na tarefa.
- Não houve restart, mudança de banco/migrations, firewall ou rede. Streaming real e cold join por outro PC continuam pendentes de reteste após restart completo pelo txAdmin.
- Próximo passo: aplicar em janela combinada, reconectar clientes e repetir personagem/oficina e troca rápida de mods; tratar pendência ER34N separadamente.

Relatório: `docs/cold-join-preview-2026-10-23.md` na base ativa.

Resumo salvo no workspace para transferência: a pasta Obsidian compartilhada está fora da permissão de escrita desta sessão e não foi atualizada.
