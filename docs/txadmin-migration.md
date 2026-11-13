# Integração ao perfil CFX Default — 16/10/2026

Atualização posterior no mesmo dia: os arquivos legados foram arquivados a pedido do proprietário. Este documento registra a transferência original; para o estado atual veja [legacy-cleanup.md](legacy-cleanup.md). Os backups citados abaixo agora estão na pasta temporária de legado, sob `historico/` (caminhos exatos no relatório de limpeza).

A implementação foi transferida de `C:\FiveM\drift-server\freeroam` para `C:\FiveM\drift-server\txData\FiveMBasicServerCFXDefault_CAECC7.base`, a pedido do proprietário. Não é mais necessário iniciar uma instalação separada em freeroam.

## Inicialização habitual

O perfil `default` do txAdmin já aponta para esse diretório, usa `server.cfg` por default e tem OneSync `on` como default da versão instalada. O JSON do perfil e o atalho existente foram preservados. Inicie pelo txAdmin de costume; o server.cfg agora carrega:

```text
server.cfg
  -> config/development.cfg
     -> config/network.cfg           # endpoints anteriores, porta 30120
     -> config/server.cfg            # regras comuns e ensure dos resources MX
        -> config/secrets.local.cfg  # mesma licença, credencial e banco novos
        -> config/voice.cfg          # pma-voice opcional
        -> config/txadmin.local.cfg  # vínculos ACE preservados
```

`config/production.cfg` também usa os endpoints anteriores. Para selecionar produção no txAdmin, altere o exec do server.cfg depois dos testes de conteúdo/jogo. O script `scripts/start.cmd` permanece somente como alternativa de diagnóstico, usando a mesma pasta/porta; não o execute simultaneamente com o servidor iniciado pelo txAdmin.

## Conteúdo transferido e preservado

- Oito resources próprios em `resources/[mx]`, dependências instaladas em `[vendor]` e verificação isolada em `[tests]`. O resource de testes não é iniciado pelo server.cfg.
- Código React/TypeScript, dist compilado, migrations, scripts, testes, documentação, lockfiles, node_modules e Git agora estão na raiz desse diretório de dados.
- Resources legados em `[mx-scripts]`, mapas, packs, rodas, áudio, vMenu e demais pastas anteriores continuam em disco, sem alteração de seu código. A inicialização automática desses grupos foi retirada para evitar conflito com a base nova. A pasta `db` antiga também foi preservada.
- Licença/URI/credencial da base desenvolvida foram mantidas byte a byte. A aplicação continua usando `mx_freeroam_clean`, sem reset, importação do banco antigo ou reaplicação destrutiva de migrations.
- As linhas ACE do server.cfg anterior foram preservadas em arquivo local privado, com `group.admin` herdando `group.mxadmin`. A herança de `mx.inspect` foi confirmada pelo comando test_ace no runtime. Nenhum identificador pessoal foi incluído no Git.
- O Git ignora resources alheios, db/cache, configurações locais, vendor instalado e o antigo server.cfg.bkp, que pode conter segredo. O server.cfg novo versionado é apenas o bootstrap e não contém licença.

## Backup e reversão

Backup atualmente em `C:\FiveM\drift-server\temporario-legado-20261016\historico\migration-backups\mx-txadmin-20261016-000635`:

- `server.cfg.before`: configuração original completa do perfil, incluindo seus segredos; mantenha privado.
- `txadmin-config.before.json`: cópia do perfil; o arquivo original não foi alterado.
- `project-before/`: cópia do código/config/resources/Git antes da transferência, sem node_modules/caches.
- `runtime-from-freeroam/`: caches, logs e runtime da instalação isolada, retirados do diretório ativo. A pasta `freeroam` antiga não ficou como uma segunda base ativa.

Para voltar à configuração antiga após a limpeza posterior, pare o servidor, restaure os resources necessários da pasta temporária conforme `inventario.json` e então restaure `server.cfg.before`. As tabelas antigas agora também exigem restauração dos dumps em `temporario-legado-20261016/banco/`. Não apague a base nova nem sobrescreva o banco ativo para fazer essa reversão. Para voltar à instalação isolada, use o backup do projeto em outro diretório e reinstale node_modules pelo lockfile.

## Verificações desta transferência

- Build TypeScript/Vite no novo caminho: aprovado.
- Manifests/fronteira do core e exclusões de física: aprovados.
- Análise dos 32 arquivos Lua próprios e 43 regras objetivas: aprovadas.
- FXServer executado diretamente com `+set onesync on +exec server.cfg` no diretório do perfil: licença autenticada, MariaDB conectada, schema 004 reconhecido e oito resources MX/voz iniciados.
- Endpoint `127.0.0.1:30120/info.json`: resources esperados presentes; nenhum vMenu ou MX legado em execução. A leitura do endpoint não prova conectividade externa.
- Perfil txAdmin e arquivo privado de persistência comparados: caminho correto e credenciais/URI preservadas.
- `test_ace group.admin mx.inspect`: true; inspeção retornou todos os domínios iniciados.
- Processo de teste encerrado depois da validação, liberando a porta para a inicialização habitual.

Evidência: [txadmin-migration.json](evidence/txadmin-migration.json). O boot usou a configuração que o txAdmin irá carregar; não foi feita automação de login no painel txAdmin. Nenhum client FiveM foi conectado. As pendências de gameplay, reconexão, coordenadas, dois clientes, voz real e desempenho permanecem as descritas no relatório de cobertura.
