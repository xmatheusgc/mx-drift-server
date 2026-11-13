# Coordenadas e teleporte administrativo

Data local: 24/10/2026, aproximadamente 11:40, America/Sao_Paulo. Projeto: C:\FiveM\drift-server. IA: Codex. Origem: pedido do proprietário, resposta de prioridade, código e testes locais.

O proprietário quer mais opções administrativas para substituir uso do vMenu, principalmente coordenadas com heading; escolheu teleporte por coordenadas/marcador como prioridade adicional. Entregues dois submenus em M → Administração, painel contínuo com menu fechado/noclip, referências personagem/veículo/câmera, captura vector3/vector4/tabela com campo selecionado/Ctrl+C e tentativa de clipboard, modelo/interior/net ID. Teleporte por posição com heading opcional e por marcador com busca de solo até 8 s.

Admin conserva autorização/audit/leitura, world realiza movimento pelo fluxo existente (driver/posse/passageiros/reservas/ACK/posição/rollback). ACE mx.inspect para leitura, nova mx.teleport para viagens, ambas também exigem mx.admin. Nova ACE concedida ao group.mxadmin. Painel usa renovação de autorização/epoch e expiração local. Sem operações de jogo na oficina privada. VMenu não removido nem desabilitado nesta entrega.

Build com TypeScript, check e suíte completa aprovados. Novos testes incluem 36 verificações de ferramentas, parser/formatador e integração com viagem real de world usando natives/adaptadores. Browser em quatro resoluções aprovado com transporte simulado; capturas de coordenadas e teleporte 1280×720 inspecionadas. Não houve cliente FiveM, restart, teleporte real, alteração de dados ou validação real do clipboard/solo distante.

Próximo passo: reiniciar/reconectar e testar M → Administração, painel no noclip, referências e cópia no CEF, coordenadas/heading, marcador distante, ausência de marcador e carro sem passageiros. Relatório: docs/admin-coordinates-teleport-2026-10-24.md; evidência JSON homônima em docs/evidence.

Memória salva somente no export do workspace. A base Obsidian compartilhada não foi atualizada por falta de permissão de escrita.
