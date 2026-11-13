# Recuperação do handling ER34N

Data: 2026-10-24 (America/Sao_Paulo).
Projeto: Drift server FiveM — `C:\FiveM\drift-server`.
Aplicativo/IA: Codex.
Origem: novo relato/F8 do proprietário, código local e testes automatizados.

- Usuário relatou que drift salvo bloqueava saída com ER34N e troca de carro pelo menu M. Autorizou tratar handling recuperável com diagnóstico/reset/retry, sem indisponibilizar o carro ou apagar progresso.
- Arquivo atual do ER34N tinha três subtipos vazios. Declarado CCarHandlingData com os três valores já autorizados no preset; bloco principal não retunado. Conteúdo anterior de referência em `docs/evidence/er34n-handling-before-2026-10-24.meta`.
- Implementado ensure para drift: strict set/audit preservados, reset do baseline e uma nova tentativa. Falha opcional não rejeita apply/spawn/respawn/switch/repair. Estado efetivo separado da preferência salva, com sinalização de restauração incerta. Toggle sem sucesso retorna persisted=false e aviso. Não apagar preferência salva por falha temporária.
- Menu mostra aviso recuperável; diagnóstico exato preservado no F8 e aviso estruturado no servidor. Restauração incerta protege apenas competição; veículo e treino continuam disponíveis. Identidade/posse/ocupantes/ACK obrigatórios continuam validados.
- Build/typecheck, check, suíte completa e UI em quatro resoluções aprovados. A checagem de ER34N da entrega anterior agora passa. Adaptadores não certificam readback/dirigibilidade no FiveM.
- Sem restart nem alteração de dados de jogador/banco. Próximo passo: restart completo pelo txAdmin, reconectar e validar saída do ER34N, troca pelo M, toggle e /mxhandling.

Relatório: `docs/handling-recovery-2026-10-24.md` na base ativa.

Resumo salvo no workspace para transferência. A pasta Obsidian compartilhada não foi atualizada porque está fora da permissão de escrita desta sessão.
