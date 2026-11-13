# Preferencias centralizadas e cambio por perfil - 2026-10-30

Origem: pedido do usuario para remover Controles do modo livre, mover Preferencias para o novo menu, remover a aba Navegacao e permitir automatico/manual no mx-gearbox.

## Resultado
- Menu livre sem entradas Preferencias/Controles; removidos os fluxos antigos e a consulta de perfil que servia apenas a eles.
- Configuracoes compartilhadas entre pausa e lobby preservam HUD, minimapa, unidades, escala e volume, camera e movimentos; recebem localizacao, marcadores uniformes, ocultacao de HUD/radar, filtro de marcadores e convites. Abas: Geral e Atalhos do servidor.
- Campo transmission no JSON de preferencias, automatic/manual, automatico para perfis antigos e novos. Validacao estrita no servidor, mesma revisao otimista e ACK; sem migracao SQL.
- Cambio obedece ao perfil publicado e busca o perfil quando seu recurso inicia. Salvar outras preferencias nao recria a transmissao. /gear manual e automatic tambem salvam pelo core quando disponivel; falha de gravacao nao muda o modo. Sem core, mantem uso autonomo.
- Drift continua suspendendo o manual sincronamente antes de escrever handling e durante estados locais/replicados/incertos; a escolha manual pode ser retomada apos desativar drift.
- config/server.cfg passa a iniciar mx-gearbox depois dos recursos MX. HUD proprio desligado por padrao para usar a marcha no velocimetro compartilhado. mx-turbo segue sem ensure.
- Aplicacao usa o atalho contextual existente, sem novos botoes permanentes. Recursos nao foram reiniciados nesta tarefa.

## Verificacao
Build, TypeScript, check, test:gearbox e test:controls aprovados. Test:pause aprovado em 1280x720, 1920x1080, 2560x1440 e 3440x1440, com alteracao/salvamento de cambio, marcadores e convites, abas, foco, rolagem e atalhos. Captura 1280 inspecionada. Testes de cambio incluem evento de perfil, perfil antigo, restart, comando persistente, conflito de gravacao e bloqueio drift. UI e natives usam fixtures/doubles; nao comprovam fisica/controle real ou SQL real.

## Pendente
Carregar config e recursos atualizados em momento adequado. Validar no FiveM manual/automatico, reconexao, troca de carro, retorno do drift, navegacao por teclado/controle e aplicacao das preferencias. Testes gerais de UI/lobby registrados ao terminar.

Resultado final: test:ui e test:lobby aprovados nas quatro resolucoes, sem erros JavaScript reportados.
