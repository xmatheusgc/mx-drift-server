# Inventário e decisões — 15/10/2026, America/Sao_Paulo

Este registro descreve a implantação inicial isolada. Em 16/10/2026, a pedido do proprietário, o repositório/resources foram transferidos para o diretório do perfil CFX Default existente. Veja [migração txAdmin](txadmin-migration.md); os arquivos antigos foram preservados, e a configuração ativa passou a carregar a base nova.

## Inventário essencial

- Workspace inicialmente sem repositório Git na raiz. Nenhum `AGENTS.md` encontrado na raiz, nos pais ou no inventário de instruções do workspace.
- Windows/PowerShell; Node 24.18.0, npm 11.16.0, Git disponíveis. Python e executável Lua não estavam disponíveis no PATH. Fengari foi instalado apenas para testes/análise; scripts de jogo executam no Lua do Cfx.
- FXServer local preservado: build 37175 win32, identificado pelo endpoint info.json do boot; hash do executável no lock de dependências.
- MySQL local já ativo: MariaDB 10.4.32 em 127.0.0.1:3306. Aplicação nova usa `mx_freeroam_clean`; o banco `mx_freeroam` tinha tabelas alheias e foi preservado. Testes/restore ficaram em bancos `mx_freeroam_test*`.
- txData, carros/mapas/rodas existentes e ferramentas de câmbio foram apenas inventariados como conteúdo preexistente. Não foram importados, corrigidos, ativados nem usados para implementar as regras novas.
- Chromium local disponível em tools; usado por Playwright. Nenhum cliente FiveM foi conectado durante a execução.
- A primeira tentativa de boot não conseguiu autenticar sob restrição de rede. Com a execução autorizada com acesso à autenticação Cfx, a licença autenticou e os resources iniciaram. A chave não aparece nas evidências ou Git.

## Defaults adotados

| Decisão | Default |
| --- | --- |
| Base | Standalone original em `freeroam/`, oito resources e um Git novo dentro dessa pasta |
| Linguagem/UI | Lua client/server, React 19.3.1, TS 5.9.3, Vite 7.3.7; CSS local, sem CDN |
| Banco | MariaDB >= 10.4, oxmysql 2.14.3, usuário runtime sem DDL; migrations explícitas e checksums |
| Mundo | Compartilhado bucket 0, OneSync strict, sem população/armas/procurado; clima CLEAR às 14h, revisão fixa |
| Carros | Cinco vanilla permitidos, um ativo por jogador, 30 presets; 5 s entre trocas |
| Personalização | Schema 1; cosméticos nativos. Desempenho nativo desabilitado por padrão; nenhuma alteração de handling |
| Conteúdo | LSIA/encontro, Porto, Sandy e rota de Sandy como rascunhos; desenvolvimento permite treino; produção recusa rascunhos |
| Presença | Snapshot agregado por observador a cada 1 s, expiração 5 s; posição do servidor, sem aumentar culling |
| Social | Grupo até 6 pessoas, convite válido 30 s e cooldown 5 s; liderança passa ao primeiro membro restante |
| Atividades | Amostra 200 ms, contagem 3 s, limite 10 min; contrarrelógio/duelo por modelo e assinatura exatos |
| Drift | Treino e telemetria técnica versionada, máximo 120 amostras por resultado; sem pontuação oficial/XP de habilidade |
| Progressão | Tabela versionada; 100 XP na primeira rota válida, semanal configurado 50 XP; exemplo semanal desligado |
| Operação | ACE por ação, txAdmin operacional; retenção de auditoria 90 dias, telemetria 7 dias e evidência extensa inválida 30 dias |

## Dependências e manutenção

A seleção inicial CommunityOx 2.12.3 foi descartada na revisão: distribuição arquivada e mysql2 3.11.3 incluído. A entrega usa Overextended 2.14.3, distribuição mantida e mysql2 3.24.5 incluído, com origem/hash/licença fixados. Foi repetido o boot e o teste de persistência com essa versão. PMA 6.6.2 usa a voz Mumble do FiveM e é opcional. txAdmin continua sendo a ferramenta operacional do FXServer, sem um painel duplicado.

`npm audit` identificou Vite/mysql2/esbuild antigos na primeira instalação. Foram atualizados Vite, mysql2 de ferramentas e o lock transitivo do esbuild. Restam dois avisos moderados ligados a `sprintf-js`/Fengari, sem correção publicada indicada pelo npm: usados apenas em código de testes local, não servidos na NUI nem executados no servidor de jogo. O build runtime/NUI não contém Fengari. Não execute testes Lua fornecidos por terceiros sem revisão.

## Referências consultadas

- [OneSync, criação no servidor, culling e lockdown](https://docs.fivem.net/docs/scripting-reference/onesync/)
- [Segurança de eventos Cfx](https://docs.fivem.net/docs/developers/server-security/)
- [NUI e foco](https://docs.fivem.net/docs/scripting-manual/nui-development/full-screen-nui/)
- [oxmysql mantido](https://github.com/overextended/oxmysql), [release fixada](https://github.com/overextended/oxmysql/releases/tag/v2.14.3)
- [pma-voice](https://github.com/AvarianKnight/pma-voice), [manifest da versão](https://github.com/AvarianKnight/pma-voice/blob/v6.6.2/fxmanifest.lua)
- [React](https://react.dev/learn), [Vite](https://vite.dev/guide/), [MariaDB](https://mariadb.com/docs/server/)

As configurações de gameplay e os limites são defaults do projeto. A documentação das dependências não valida a experiência de direção ou o conteúdo geográfico.
# Exceção autorizada em 2026-10-18: preset de drift do trainer

O proprietário solicitou explicitamente aplicar o XML fornecido em Opções do veículo. A exclusão original de handling passa a admitir exclusivamente esse preset reversível por entidade, no domínio vehicles. A guarda estática mantém vedados setters globais e multiplicadores fora do módulo autorizado. Os valores não foram retunados; mx-gearbox e mx-turbo permanecem preservados. Ver `vehicle-options-drift-2026-10-18.md`, incluindo metadados não aplicáveis em runtime e validações pendentes no FiveM.

## Primeira entrada e prévias — 2026-10-23

Atualização de 24/10/2026, rodas: recusa nativa de diâmetro/largura é uma limitação por dimensão e conjunto de rodas, não motivo para rejeitar todo o veículo. Confirmar e usar o fator efetivo, preservar os demais ajustes, mostrar a limitação e não salvar o valor recusado como aplicado. Cache local por identidade/modelo/rodas; sem blacklist global de modelos. Payload, identidade, ACK e persistência permanecem estritos. Ver [stance-wheel-recovery-2026-10-24.md](stance-wheel-recovery-2026-10-24.md).

Atualização de 24/10/2026: o proprietário autorizou tratar falhas recuperáveis de drift como diagnóstico/recuperação, sem bloquear pegar/recriar/trocar o veículo. Aplicar → restaurar baseline → uma nova tentativa; falha persistente libera o carro sem afirmar sucesso do preset. Separar preferência salva de estado efetivo e handling incerto. Não apagar a preferência de drift em fallback nem declarar persistência de toggle que falhou. Posse, entidade, passageiros, ACK de personalização e integridade de banco permanecem protegidos. Detalhes e testes: [handling-recovery-2026-10-24.md](handling-recovery-2026-10-24.md).

Erros esperados nas rotas/exports corrigidos são resultados estruturados capturados no resource de origem; não depender de exceções atravessarem referências Cfx. Manter exclusão por jogador, epoch e geração de seleção. Carregar apenas o veículo solicitado, permitir cancelamento local da espera e dar ao pedido completo prazo maior que a sequência de ACKs. A entrada na oficina deve esperar cena, colisão, modelo do mapa e interior prontos sob fade antes de confirmar acesso; não usar apenas chão vanilla como prova. Implementação e limites de validação em [cold-join-preview-2026-10-23.md](cold-join-preview-2026-10-23.md).

