# MX Freeroam JDM

Base standalone no diretório de dados CFX Default do txAdmin. O servidor continua iniciando pelo perfil/atalho habitual, usando server.cfg. Não é necessário um segundo servidor ou outro perfil.

## Estrutura

- server.cfg: entrada do txAdmin; carrega config/development.cfg.
- config/: rede, perfis, segredos locais, ACE, voz e assets.cfg.
- resources/: resources MX, dependências pontuais e assets instalados pelo proprietário.
- cache/ e db/: arquivos gerados pelo FXServer. db/default é persistência KVP/RocksDB do servidor; não é o banco MariaDB dos jogadores. Não foram movidos ou apagados.
- development/: fontes da NUI, node_modules, package.json/lock, configurações de build, scripts, testes, migrations, arquivos temporários e backups locais de desenvolvimento.
- docs/: arquitetura, contratos, backlog T01–T40, operação e evidências.

A interface compilada continua em resources/[mx]/mx-freeroam-menu/dist. FXServer usa essa saída; as ferramentas npm não precisam rodar para iniciar o jogo. Recursos e configuração continuam dentro desta base.

## Inicialização

config/server.cfg inicia oxmysql, executa config/assets.cfg e usa ensure [mx]. Os manifests MX declaram suas dependências; não se depende da ordem alfabética dos diretórios. Voz continua em config/voice.cfg.

config/assets.cfg inclui [standalone], [audio], [wheels], [vehicles] e [maps]. Os 26 resources presentes foram inventariados em docs/evidence/startup-layout.json. Isso configura o próximo start; não houve restart da instância em execução. Streaming, compatibilidade e autorização /assetpacks de gunsaitouge precisam de verificação no FXServer/FiveM.

[tests] e [mx-scripts] não são iniciados em grupo. mx-gearbox e mx-turbo foram preservados, sem ativar integrações pendentes. Assets iniciados não entram automaticamente no catálogo: os modelos continuam declarados em resources/[mx]/mx-freeroam-vehicles/config.lua.

## Desenvolvimento

Execute a partir desta pasta:

```powershell
npm.cmd --prefix development ci --cache development/.cache/npm
npm.cmd --prefix development run build
npm.cmd --prefix development run check
npm.cmd --prefix development test
npm.cmd --prefix development run test:ui
npm.cmd --prefix development run test:lobby
```

Para os testes de navegador, MX_CHROMIUM pode apontar para o Chromium local. Para testes SQL, MX_TEST_DATABASE_URL deve apontar exclusivamente para um banco mx_freeroam_test[_sufixo]. Migrações: configure MX_DATABASE_URL e execute npm.cmd --prefix development run migrate. Nenhuma migration foi alterada nesta reorganização.

Ferramentas diretas: development/scripts/install-dependencies.ps1, development/scripts/setup-local.mjs e development/scripts/backup.mjs. Segredos permanecem em config/*.local.cfg, fora do Git. Arquivos de development/runtime também não são versionados.

Diagnóstico sem txAdmin (use somente um iniciador):

```powershell
.\development\scripts\start.cmd -Profile development
```

## Documentação e validação

[Organização e inicialização](docs/server-layout.md), [cobertura](docs/coverage.md), [backlog](docs/backlog.md), [arquitetura](docs/architecture.md), [contratos](docs/contracts.md), [lobby, controle, cores e carros salvos — fluxo atual](docs/lobby-showroom-controls-2026-10-17.md).

Confirmar uma peça aplica **e persiste** na criação atual. Navegar apenas mostra prévias; voltar restaura o último estado confirmado. Não há botão ou atalho de salvar o carro. Usar um modelo do Showroom cria sua configuração salva; editar uma criação atualiza o mesmo ID. Lobby noturno com neblina e enquadramento próprio fica em `ExperienceConfig`; a garagem mantém sua posição independente. Consulte os [ajustes de apresentação e confirmação](docs/workshop-polish-2026-10-17.md) e o [refinamento de personalização, extras e controle](docs/workshop-refinement-2026-10-17.md).

Build e testes automatizados não substituem validação no FiveM. O banco dos jogadores, cache, KVP e configurações locais foram preservados. Documentos históricos podem citar os caminhos anteriores à pasta development; as instruções desta página prevalecem. O README anterior foi preservado em docs/history/README-before-development-folder.md.
