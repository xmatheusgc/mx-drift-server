# Organização da base e inicialização — 17/10/2026

A pasta de dados do txAdmin e sua entrada `server.cfg` permanecem no mesmo local. O perfil existente não foi editado nem reiniciado.

## Inicialização por categoria

`config/server.cfg` mantém `ensure oxmysql`, executa `config/assets.cfg` e inicia `ensure [mx]`. Categorias são suportadas pelo FXServer; não se usa a ordem alfabética como contrato. Os manifests MX já declaram dependências entre core, world, vehicles e experiência; o manifest do menu foi completado com os módulos que usa, incluindo drivecam, para ficar pronto depois deles. O grafo foi verificado sem ciclos. Voz segue com `config/voice.cfg`.

Assets fornecidos pelo proprietário, configurados para o próximo start:

| Categoria | Resources |
| --- | ---: |
| `[standalone]` | 2 |
| `[audio]` | 4 |
| `[wheels]` | 1 |
| `[vehicles]` | 12 |
| `[maps]` | 7 |

`[tests]` e `[mx-scripts]` continuam fora do start por categoria. `mx-gearbox` e `mx-turbo` estão preservados e não foram ativados antecipadamente. Os assets não foram alterados, inclusive seus handlings. Iniciar um pack de veículos não adiciona automaticamente modelos ao catálogo MX, que continua explícito no domínio vehicles.

`gunsaitouge` exige a capacidade `/assetpacks`; seu entitlement deve ser confirmado pelo FXServer com a chave configurada. A verificação local não garante esse requisito, compatibilidade entre mapas, streaming, colisões ou áudio no jogo.

## Estrutura atual

```text
FiveMBasicServerCFXDefault_CAECC7.base/
├── server.cfg
├── config/                 # perfis, assets, rede, voz, ACE e segredos locais
├── resources/              # local servido pelo FXServer, preservado
├── cache/                  # gerado pelo FXServer, preservado
├── db/default/             # KVP/RocksDB do FXServer, preservado
├── development/
│   ├── ui/                 # fonte da NUI e seus assets de build
│   ├── scripts/            # build/test runner, start alternativo, SQL e instalação
│   ├── tests/
│   ├── migrations/         # mesmos arquivos/checksums; sem nova migration
│   ├── node_modules/       # ferramentas npm, não necessárias no start normal
│   ├── runtime/            # temporários/backups auxiliares, ignorados pelo Git
│   ├── package.json
│   ├── package-lock.json
│   ├── dependencies.lock.json
│   ├── tsconfig.json
│   └── vite.config.ts
├── docs/                   # documentação e evidências
└── README.md
```

`db/default` não é o MariaDB dos perfis e garagens. Nenhum dado nativo, banco ativo, chave Cfx, URI SQL, associação ACE, caminho de resources ou perfil do txAdmin foi movido ou apagado. O banco SQL continua acessado pela configuração local existente.

O build continua gerando `resources/[mx]/mx-freeroam-menu/dist`. Scripts Node normalizam o diretório de trabalho para a raiz da base; suas dependências são resolvidas em `development/node_modules`. Os scripts PowerShell tiveram o cálculo da raiz ajustado. `npm --prefix development` permite operar a partir da raiz, e `npm run ...` também funciona quando executado dentro de `development`. Use os comandos atuais do README; os caminhos de relatórios antigos são históricos. O README anterior foi preservado em `docs/history/README-before-development-folder.md`.

## Verificação

- Build/typecheck, análise estática e suítes Lua aprovadas com a nova localização.
- Testes de interface e lobby aprovados em quatro resoluções após a movimentação.
- Teste em MariaDB isolado `mx_freeroam_test_experience` aprovado: migrations repetíveis, propriedade, conflito de revisão e nova conexão SQL. Não foi usado o banco ativo para esse teste.
- Scripts PowerShell analisados sem erro de sintaxe; não foi iniciado outro FXServer.
- Inventário e análise sintática dos manifests instalados, dependências existentes e ausência de ciclos em `docs/evidence/startup-layout.json`.
- `git diff --check` aprovado. Cache e KVP nativos permanecem na raiz.

Essas verificações não são um boot real com os novos packs: o servidor já estava em execução e não foi reiniciado nesta entrega. Assets serão iniciados no próximo start normal do perfil; aceite de streaming, autorização e comportamento em jogo permanece pendente.

Referências oficiais: [categorias de resources](https://docs.fivem.net/docs/scripting-manual/introduction/introduction-to-resources/), [manifest e dependências](https://docs.fivem.net/docs/scripting-reference/resource-manifest/), [dados e perfis do txAdmin](https://docs.fivem.net/docs/resources/txAdmin/).
