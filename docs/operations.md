# Operação

## Permissões e comandos

ACE nega por padrão. `config/server.cfg` oferece o grupo `group.mxadmin` com permissões separadas; o operador deve associar seu identificador localmente. Nunca versionar identificadores pessoais. Console é autor interno `console`; jogador autenticado é `profile:<id>` no audit, sem license completa.

| Permissão | Comando / ação |
| --- | --- |
| mx.inspect | `/mxinspect`: disponibilidade, entidades próprias e sessões |
| mx.invalidate | `/mxrevoke UUID motivo`; `/mxreprocess` |
| mx.cleanup | `/mxcleanup`: invalida tentativas e remove carros próprios sem outro ocupante |
| mx.announce | `/mxannounce destino` |
| mx.content | `/mxtrack begin id forward|reverse destino revisão`, `/mxtrack point`, `/mxtrack export`, `/mxtrack activate id confirmado-no-jogo`; `/mxdestination id nome` |

Kick, ban e gestão de processos ficam no txAdmin. A API pública de administração repete os checks ACE; esconder a categoria na NUI não é a proteção. Os comandos também conferem ACE explicitamente.

## Publicar conteúdo

Capture o início e cada checkpoint com `/mxtrack point`; a coordenada é obtida no servidor, não fornecida pelo usuário. Exporte com pelo menos dois pontos. O JSON em `mx-freeroam-admin/drafts/` é um rascunho privado, sem ranking. Revise nome, mapa necessário, heading, regiões, sentido, espaçamento e pontos de recuperação. Faça o percurso no jogo, nos dois sentidos cadastrados separadamente quando necessário.

Depois da validação humana, `activate ... confirmado-no-jogo` publica e registra a revisão imutável no banco. Uma revisão já existente com definição diferente é recusada; incremente a revisão. Reiniciar activities recarrega revisões ativas. Para ativar o exemplo de Sandy, publique uma revisão 2 verificada, não altere a revisão 1 já gravada. O agente não executou essa confirmação humana.

`/mxdestination` exporta um único slot rascunho. Acrescente slots realmente testados, importe em world/config.lua e marque validado após testar colisão e ocupação. Atualize a revisão de condições se a mudança afetar comparação competitiva. Use restart coordenado para alterações de mundo. Não habilite mapas/carros adicionais somente porque seu resource inicia.

## Banco e falhas

Migrations explícitas com credencial administrativa: `MX_DATABASE_URL` + `npm run migrate`. Runtime só verifica a última versão; schema ausente fecha conexões. Não modifica nem recria perfis em fallback. As queries usam placeholders; revisão e dono são critérios SQL da garagem. A aplicação local foi provisionada com privilégio somente DML no seu banco. MariaDB 10.4 é o mínimo efetivamente suportado; compatibilidade com MySQL 8 não foi alegada, pois a migration de colunas usa a sintaxe MariaDB `IF NOT EXISTS`.

Um preset só recebe confirmação depois do commit. Resultados aguardam em `activity_delivery` quando progression está desligada. Falha de banco na conclusão também conserva um diário local e mostra pendência; o worker só concede depois de persistência. Guarde esses diários junto dos dados de operação, sem servi-los por HTTP. Se o disco falhar também, o resultado fica explicitamente não confirmado.

## Backup e restore

```powershell
$env:MX_DATABASE_URL='mysql://BACKUP_USER:SENHA@127.0.0.1:3306/mx_freeroam_clean'
$env:MX_MYSQLDUMP='C:\xampp\mysql\bin\mysqldump.exe'
node scripts/backup.mjs backup backups/AAAA-MM-DD.sql
```

Crie a pasta de backups antes. O script usa snapshot InnoDB (`--single-transaction`), preserva rotinas/eventos, registra versão e SHA-256. Senha vai no ambiente do subprocesso, não na linha de comando. Confirme permissões locais de acesso aos backups, pois contêm identificadores e dados de jogadores. Não execute DDL durante o dump.

Para restaurar, crie **outro banco vazio** no namespace autorizado e defina a URI dele. Use `MX_MYSQL` apontando para mysql.exe e `node scripts/backup.mjs restore arquivo.sql`. O script recusa banco com tabelas e checksum divergente. Compare perfil, garagem, resultados e ledger antes de trocar a configuração do servidor. Não restaure por cima do banco em uso.

O teste `tests/restore.mjs` automatiza dump, criação de um banco de teste novo, restore e comparação integral de dez tabelas. Os bancos/arquivos de ensaio foram preservados para inspeção; nenhuma exclusão de banco preexistente foi executada.

## Atualização e rollback

1. Faça backup e restaure-o em banco separado; preserve também configs/diários locais.
2. Fixe origem, versão e hash do próximo FXServer/driver; atualize em ambiente de teste. O instalador não sobrescreve silenciosamente um vendor existente.
3. Aplique migrations em teste e execute build, regras, SQL e os cenários de runtime. Só depois aplique as migrations com janela operacional.
4. Pare coordenadamente, troque resources/build e confira dependências/migrations antes de permitir jogadores.
5. Para rollback da aplicação, preserve migrations aditivas e use uma versão que leia o schema atual. Não há down migration destrutiva automática. Para restaurar dados, use banco separado validado e troque a URI explicitamente.

O histórico do ledger e das revogações é conservado. O job remove telemetria detalhada após 7 dias, checkpoints extensos de inválidos após 30 e auditoria após 90; IDs, razões e concessões referenciadas não são apagados. Revogação em activities desliga ranking imediatamente; compensação em progression é recuperável e pode chegar após a disponibilidade do worker.

Para restart de veículos: `restart mx-freeroam-vehicles`, depois `ensure mx-freeroam-activities`. Para world, reinicie world e dê ensure em vehicles, social e activities, nessa ordem. Dependentes são parados pelo FiveM; precisam ser retomados explicitamente. Core/oxmysql continuam sujeitos a restart coordenado completo.

## Desempenho e limites

HUD local a 10 Hz quando habilitado; NUI fechada não recebe catálogo nem telemetria de menu. Presença a 1 Hz em lotes filtrados por destinatário. Checkpoints a 5 Hz por sessão ativa. Telemetria drift a 2 Hz no máximo, com 120 amostras por resultado. Não há SQL por frame nem varredura global de veículos no loop de renderização. Reservas consultam veículos somente nas operações de spawn/viagem.

Snapshot de presença contém metadados mínimos junto da posição; a versão inicial reenvia esses metadados no lote de 1 s, em vez de implementar deltas separados. Isso deve ser medido antes de ampliar população. A simulação disponível verifica filtros para 20 pessoas, sem medir Cfx, pacotes reais ou consumo de cliente. Nenhum orçamento de ms foi prometido. Veja o roteiro de profiler/resmon em testing.md.
