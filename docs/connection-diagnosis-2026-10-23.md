# Diagnóstico de conexão — 23/10/2026

Atualização posterior do proprietário: o jogador conseguiu entrar pela Radmin. Relatou erros de seleção/menus e oficina incompleta depois da entrada; a investigação e correção desses caminhos estão em [cold-join-preview-2026-10-23.md](cold-join-preview-2026-10-23.md). Isso não certifica acesso pelo IP público.

Origem: relato do proprietário, leitura da configuração/código, documentação oficial Cfx e consultas locais ao runtime por Codex. Horário de referência: America/Sao_Paulo, aproximadamente 23:18. Diagnóstico sem restart ou alteração de configuração, firewall, banco ou resources.

## Evidências

- O proprietário confirmou que o jogador usa Radmin VPN e relatou ausência de erros no F8. Depois confirmou a tela exata: **Preparando seu acesso | Aguardando perfil e lobby**, com o aviso genérico de demora abaixo.
- O perfil default do txAdmin aponta para esta base. `server.cfg` executa `config/development.cfg`, que carrega `config/network.cfg` e `config/server.cfg`.
- `config/network.cfg` configura TCP e UDP em `0.0.0.0:30120`. O processo FXServer efetivamente escuta os dois protocolos nessa porta.
- Não foram encontradas diretivas ativas `sv_listingIpOverride`, `sv_listingHostOverride`, `sv_endpoints`, `sv_forceIndirectListing`, `sv_requestParanoia` ou fileserver override na configuração consultada.
- `info.json` respondeu HTTP 200 em loopback, LAN e Radmin. Loopback e Radmin anunciaram 53 resources, incluindo os dez domínios MX.
- Consultas UDP `getinfo` responderam em loopback e no endereço Radmin do próprio host. São verificações locais; não certificam o caminho remoto do jogador.
- Firewall ativo no perfil Público, com regras habilitadas de entrada TCP/UDP para o executável atual do FXServer.
- O log atual confirma oxmysql conectado, schema `007_vehicle_modes.sql` pronto e resources MX iniciados. Repete falha de consulta Cfx ao IP público informado pelo proprietário.
- A tentativa HTTP ao IP público a partir do próprio servidor falhou. Esse teste não distingue bloqueio externo de ausência de NAT loopback; não certifica a causa no roteador/provedor.
- Existem conexões TCP recentes pelo adaptador Radmin. Não foi inspecionado o computador do jogador.

## Interpretação

O aviso da lista Cfx relata falha para alcançar o endereço público. Durante testes fechados por Radmin, pode permanecer como pendência de publicação, desde que os jogadores usem o endereço da VPN. Não está comprovado como causa do loading. Para acesso público, validar encaminhamento da porta TCP/UDP, firewall, WAN/CGNAT e teste por rede externa. Não configurar override com IP da VPN como tentativa de corrigir a publicação pública.

O aviso “O carregamento está demorando...” vem de `resources/[mx]/mx-freeroam-menu/loadscreen/loading.js`, após 60 segundos sem sinal tratado pelo script. Não mede conexão, ping, perda ou vazão. A mensagem também pode substituir a ajuda de erro anterior; o detalhe da etapa permanece disponível.

O título “Preparando seu acesso” é usado em dois caminhos:

1. `loadProgress` chega a 100%: detalhe **Aguardando perfil e lobby**. Não comprova sessão de jogo pronta nem execução dos scripts do cliente.
2. Evento próprio `mxStage`: detalhe específico, como **Carregando configurações do lobby**. Nesse caso o cliente já chegou ao fluxo próprio.

O core do cliente aguarda `NetworkIsSessionStarted()`, envia `mx:core:ready` e recebe o perfil; experience abre o lobby e espera confirmação da NUI antes de fechar o loading. Esse caminho exige diagnóstico do cliente para apontar a espera exata. Sem logs do cliente, não há causa raiz confirmada.

## Próximo passo

O detalhe confirmado indica que o loading recebeu progresso de 100% e ainda não recebeu atualização `mxStage` que substitua essa mensagem. O watchdog de perfil em `experience/client.lua` deveria enviar um erro específico após 25 s de execução se o perfil não chegasse. Sua ausência sugere investigar inicialização dos scripts/sessão, entrega de mensagens e carregamento do jogo, sem afirmar qual é a causa. Não há evidência para atribuir o caso à criação de perfil no banco.

Confirmar conexão direta pelo endereço Radmin do host (`connect IP_RADMIN:30120`). Coletar o log CitizenFX da tentativa do jogador, inclusive linhas informativas de inicialização, streaming e rede. Se necessário, testar `http://IP_RADMIN:30120/info.json` no PC dele. Sucesso HTTP remoto não certifica UDP. Correlacionar inicialização dos resources do cliente, sessão, recebimento do perfil e ACK da interface antes de alterar código.

## Referências

- https://docs.fivem.net/docs/support/server-issues/
- https://docs.fivem.net/docs/server-manual/server-commands/#sv_listingipoverride-ip
- https://docs.fivem.net/docs/server-manual/proxy-setup/
- Código local: `resources/[mx]/mx-freeroam-menu/loadscreen/loading.js`, `resources/[mx]/mx-freeroam-core/client.lua`, `resources/[mx]/mx-freeroam-experience/client.lua`.

## Memória compartilhada

A base Obsidian foi consultada. A permissão de escrita desta sessão abrange o workspace; a pasta Obsidian fica fora dele. Resumo para salvar e atualização da cópia local da nota do projeto ficam em `docs/obsidian-export/2026-10-23`. Isso não representa atualização da base compartilhada.
