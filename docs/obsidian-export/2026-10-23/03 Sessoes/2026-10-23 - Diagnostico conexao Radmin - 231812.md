# Diagnóstico de conexão Radmin

Data: 2026-10-23, aproximadamente 23:18 (America/Sao_Paulo).
Projeto: Drift server FiveM — `C:\FiveM\drift-server`.
Aplicativo/IA: Codex.
Origem: relato do usuário, configuração e código locais, consultas HTTP/UDP ao runtime e documentação oficial Cfx.

- Usuário confirmou jogador pela Radmin VPN, sem erros relatados no F8 e parado em “Preparando seu acesso | Aguardando perfil e lobby”, com aviso genérico de demora abaixo.
- TCP/UDP 30120 escutando; HTTP local/LAN/Radmin responde; 53 resources anunciados. UDP getinfo responde em loopback e no endereço Radmin a partir do próprio host. Não comprova trajeto do PC remoto.
- Banco/schema prontos no log; regras de firewall Público para executável atual presentes. Nenhum listing override ativo encontrado na configuração consultada.
- Aviso Cfx diz respeito ao endereço público. Pode permanecer como pendência durante teste fechado por VPN; publicar requer validar acesso externo. Relação com loading não comprovada.
- Mensagem de demora é timer próprio de 60 s, sem diagnóstico de rede. O detalhe confirmado corresponde a progresso de 100% sem atualização posterior `mxStage`. Ausência do watchdog específico do perfil após 25 s sugere investigar execução dos scripts/sessão e log do cliente; causa raiz continua não confirmada.
- Não houve alteração operacional, restart, limpeza, atualização de recursos ou modificação do banco/firewall/configuração.
- Próximo passo: confirmar conexão direta ao endereço Radmin e coletar log da tentativa do cliente, incluindo linhas informativas, para correlacionar início dos resources, sessão, perfil e ACK da NUI.

Relatório: `txData/FiveMBasicServerCFXDefault_CAECC7.base/docs/connection-diagnosis-2026-10-23.md`.

Este arquivo foi salvo no workspace para transferência. A pasta compartilhada Obsidian não foi atualizada, pois está fora da permissão de escrita da sessão.
