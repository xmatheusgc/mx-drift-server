# Limpeza de legado — 16/10/2026

A pedido do proprietário, os arquivos antigos que não são usados pela base atual foram movidos para `C:\FiveM\drift-server\temporario-legado-20261016`. Não houve exclusão de arquivos. O proprietário pode decidir posteriormente o que guardar ou apagar.

## Arquivos

`temporario-legado-20261016/inventario.json` registra 25 movimentações com origem/destino. Foram arquivados vMenu, mx-drift, mx-smoketest, exemplos/managers CFX antigos, utilitários standalone, packs de carros/áudio/rodas, mapas, instalador antigo, diagnósticos, caches npm e backups históricos. O cache antigo do perfil foi retirado; o FXServer pode recriar cache com os resources atuais.

Os assets não foram apagados: estão em `temporario-legado-20261016/resources/`. A base atual continua usando seu catálogo vanilla. Assets autorizados poderão ser reintegrados individualmente no futuro, com validação de conteúdo.

Preservados nos caminhos originais:

- `resources/[mx-scripts]/mx-gearbox`
- `resources/[mx-scripts]/mx-turbo`

Os onze arquivos desses dois resources tiveram SHA-256 comparado antes/depois: nenhum mudou. A suíte `tools/powertrain-tests` foi mantida e ajustada somente para não procurar mx-drift e sua suíte arquivada. Resultado: dez arquivos Lua analisados e 223 verificações de powertrain aprovadas.

O Git agora inclui os dois resources preservados. Dependências instaladas, configurações privadas e caches continuam fora do Git. O FXServer, perfil/admins do txAdmin e navegadores usados para testes não foram movidos.

## Tabelas removidas

Foram removidas as seis tabelas da implementação anterior:

`mx_activity_runs`, `mx_ledger`, `mx_operations`, `mx_vehicles`, `mx_profiles`, `mx_schema_migrations`.

Elas existiam em cinco schemas: `mx_freeroam`, `mx_freeroam_test`, `mx_freeroam_test_r1792117187292`, `mx_freeroam_test_r1792118285379` e `mx_freeroam_test_restore`: **30 tabelas ao todo**. Não havia referência no código ativo, nos dois resources preservados, em tabelas mantidas ou em rotinas/eventos/triggers do banco.

Antes de qualquer DROP, foram gerados cinco dumps em `temporario-legado-20261016/banco/`. Cada dump foi restaurado em um banco temporário exclusivo; o conteúdo completo de cada tabela restaurada foi comparado com a origem. Só depois os DROPs foram executados, em ordem de dependências, sem desabilitar foreign keys.

O banco ativo `mx_freeroam_clean` não foi limpo, resetado ou migrado nesta operação. Todos os dados e tabelas foram comparados por contagem e hash antes/depois e permaneceram idênticos. As tabelas novas de testes/restore também foram mantidas. O schema antigo `mx_freeroam` ficou vazio; nenhum banco inteiro preexistente foi apagado.

O relatório privado `temporario-legado-20261016/database-cleanup.json` contém tabelas removidas, checksums, verificações de restore e hashes do banco ativo. Dumps/configurações/históricos podem conter dados pessoais ou segredos: a pasta temporária está fora do repositório e não deve ser publicada.

## Resquícios e integrações que permanecem

1. **mx-gearbox e mx-turbo:** preservados expressamente, sem alterações e ainda sem ensure automático. Hoje selecionam veículos pelo client e não consultam `vehicles:Active` nem `activities:State/Invalidate`. O câmbio escreve handling/torque e o turbo modifica a entrega de torque; isso ainda não compõe a assinatura competitiva da base nova. Ativação e integração precisam de uma entrega própria antes de comparar resultados.
2. **Chat/HUD/controles dos dois scripts:** ainda usam `chat:addMessage`, HUD próprio e seus comandos/key mappings. A base nova usa chat/avisos próprios, portanto mensagens, foco, HUD e conflitos de controles precisam ser integrados. Não foram modificados como parte desta limpeza.
3. **db/default:** armazenamento KVP/RocksDB nativo do FXServer, não tabelas SQL do framework antigo. Foi mantido porque pode guardar estado operacional. Não se deve tratá-lo como banco MySQL obsoleto ou apagá-lo sem inspeção específica.
4. **Histórico do txAdmin:** perfil, admins, logs e dados operacionais foram mantidos. Logs podem citar resources antigos, mas não os inicializam. Não foi apagado o histórico de administração.
5. **Backups/documentação histórica:** referências ao framework anterior continuam em relatórios históricos e nos arquivos da pasta temporária. Isso não é lógica ativa. Os backups da transferência agora estão em `temporario-legado-20261016/historico/migration-backups/`; backups antigos de gearbox estão em `historico/tools-backups/`.
6. **Bancos de testes/restore novos:** contêm fixtures e cópias da base atual, preservadas para evidências/testes. Não são tabelas antigas usadas pelo runtime público.

Não foi encontrada outra referência executável ativa a `mx-core`, `mx-garage`, `mx-progression`, mx-drift ou às seis tabelas removidas na base própria. A manutenção da lógica atual e suas pendências de gameplay continuam documentadas em coverage.md.

## Verificação após a limpeza

- Regras/análise estática da base atual: aprovadas, 32 arquivos Lua e 43 verificações.
- Powertrain preservado: 223 verificações aprovadas e hashes idênticos.
- Inventário SQL após remoção: zero tabelas legadas candidatas restantes; banco ativo idêntico.
- Boot isolado em `127.0.0.1:30131`: oito resources MX, oxmysql e pma-voice iniciados; schema 004 e banco prontos. A porta habitual 30120 estava ocupada; o processo existente não foi encerrado nem a configuração habitual alterada.
- Nenhum client FiveM participou. Boot não certifica gameplay, voz real ou integração do câmbio/turbo.

Evidência pública sem segredos em [evidence/legacy-cleanup.json](evidence/legacy-cleanup.json). Para restaurar arquivos, siga os caminhos de origem do inventário. Para recuperar tabelas antigas, restaure os dumps em banco separado e revise antes de reutilizar; não sobrescreva `mx_freeroam_clean`.
