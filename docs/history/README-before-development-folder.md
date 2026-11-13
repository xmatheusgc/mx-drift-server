Atualização 17/10/2026: [teclado e mouse, Customizar, ações visíveis, câmeras e suspensão](docs/customization-input-stance.md). Este incremento prevalece para input, F9/F10, rolagem e presets de câmera descritos anteriormente.

Editor atual: [barra inferior Heat, motor parado e órbita](docs/heat-customization.md). Na personalização: setas/Enter/Backspace navegam, Espaço controla o giro, F4 orbita, F9 salva e F10 cancela. Áudio, imobilização e enquadramentos ainda aguardam aceite no FiveM.

Atualização visual e de prévias: [interfaces Heat, controles e correção do ciclo de entidades](docs/interface-rework.md). F1 abre o menu compacto por teclado, sem cursor; F6 oficina e F7 câmera. Apresentação e saída temporárias estão centralizadas e separadas em experience/config.lua.

A experiência agora entra por loading → lobby → garagem, com abas contextuais e amizades persistentes. Consulte [uso, cobertura e pendências no jogo](docs/lobby-navigation.md). Migrations até 006 já aplicadas no banco ativo local; inicie o perfil normal pelo txAdmin.

# MX Freeroam JDM

Base standalone escrita do zero para o plano `../../plano-fivem-freeroam-jdm.md`, versão 0.2. O repositório fica neste diretório de dados do perfil CFX Default do txAdmin. Em 16/10/2026, os resources e arquivos obsoletos foram transferidos para `../../temporario-legado-20261016/`. `mx-gearbox` e `mx-turbo` permanecem intactos em `resources/[mx-scripts]`, sem inicialização automática até sua integração. Nenhuma base RP ou código desses projetos foi importado na base nova. Veja [limpeza e integrações pendentes](docs/legacy-cleanup.md).

**Estado:** dez resources implementados, NUI compilada, persistência real e boot verificados. Os aceites de direção, reconexão FiveM, dois clientes, voz e performance no jogo permanecem pendentes. Os destinos e a rota fornecidos são rascunhos. Veja [cobertura e evidências](docs/coverage.md) e [T01–T40](docs/backlog.md).

## Executar neste computador

Inicie pelo atalho habitual `start.exe.lnk` e pelo perfil existente do txAdmin. Ele já aponta para esta pasta e carrega `server.cfg`, que agora executa `config/development.cfg`. Não é necessário iniciar uma segunda base ou criar outro perfil. A porta habitual foi mantida em 30120; OneSync já é `on` por default nesse perfil do txAdmin.

O ambiente local usa `config/secrets.local.cfg`, ignorado pelo Git, banco `mx_freeroam_clean` e usuário limitado a SELECT/INSERT/UPDATE/DELETE. As seis tabelas da implementação antiga foram removidas de `mx_freeroam` e de quatro bancos de teste, com backup restaurado e conferido antes da remoção. O banco ativo foi preservado integralmente. Os testes usam `mx_freeroam_test`, separado da aplicação. Vínculos ACE anteriores ficam em `config/txadmin.local.cfg`, com herança para os cargos MX. [Detalhes da transferência](docs/txadmin-migration.md).

Alternativa sem txAdmin, para diagnóstico (use somente um iniciador por vez):

```powershell
Set-Location C:\FiveM\drift-server\txData\FiveMBasicServerCFXDefault_CAECC7.base
.\scripts\start.cmd -Profile development
```

No console F8 do cliente: `connect 127.0.0.1:30120`. Os endpoints anteriores `0.0.0.0:30120` foram preservados em `config/network.cfg`. Firewall e conectividade externa não foram certificados. O servidor de verificação é encerrado ao terminar os ensaios.

F1 abre/fecha o menu compacto por teclado, sem cursor. ↑/↓ selecionam, ←/→ ajustam valores, Enter confirma, Backspace volta e Esc recua/fecha na raiz. A seleção é preservada ao voltar. F2 não ativa mouse neste menu. Textos usam o teclado nativo do FiveM. F6 retorna à oficina e F7 alterna drivecam. F11 é o padrão de distância do pma-voice; /mxchat mensagem continua disponível. Aceite de foco/controle real permanece pendente no cliente FiveM.

No primeiro acesso, crie o personagem e salve o primeiro carro. A oficina será a entrada padrão nos próximos acessos: escolha uma criação, personalize e clique em Jogar. F6 retorna à oficina; F7 alterna a drivecam opcional. A garagem permite várias versões do mesmo modelo, renomeação, duplicação e exclusão. Passageiros precisam desembarcar antes do retorno, substituição, viagem ou reparo. O menu F1 conserva serviços, social, atividades, perfil e administração.

## Instalar do zero

1. Use Windows, FXServer compatível com Node 22 (mínimo 12913 para oxmysql), OneSync e MariaDB >= 10.4. O artefato testado foi 37175; o hash local está em [dependencies.lock.json](dependencies.lock.json). Não copie a pasta txData antiga para esta base.
2. Copie este repositório para o diretório de dados escolhido. Execute `npm ci --cache .cache/npm`, `npm run build` e `powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\install-dependencies.ps1`. O instalador confere SHA-256 de oxmysql 2.14.3 e pma-voice 6.6.2. Pacotes externos ficam em `resources/[vendor]`, separados do código próprio e fora do Git.
3. Crie um banco vazio `mx_freeroam_clean` com utf8mb4. Defina `MX_DATABASE_URL` com uma credencial de migrations e execute `npm run migrate`. As migrations são ordenadas, possuem checksum e não fazem reset no boot. DDL é retomável, mas não transacional no MariaDB.
4. Copie `config/secrets.cfg.example` para `config/secrets.local.cfg` e preencha chave Cfx e URI de um usuário limitado ao banco da aplicação. Copie também `config/txadmin.cfg.example` para `config/txadmin.local.cfg` e configure os vínculos ACE. Nunca use o usuário de testes em execução pública.
5. Alternativa local: defina `MX_ADMIN_DATABASE_URL` e `MX_LICENSE_KEY` no ambiente e execute `node scripts/setup-local.mjs`. Ele cria/migra o banco e gera usuário/senha aleatórios, recusando uma configuração local existente ou banco sem migrations MX. Não imprime os segredos.
6. No txAdmin, aponte o diretório de dados para esta pasta e a configuração para `server.cfg`, com OneSync ligado. Neste computador o perfil CFX Default já estava correto e não precisou ser alterado. A ordem de ensure está em `config/server.cfg`. Como alternativa de diagnóstico use `scripts/start.cmd -FxServer caminho\FXServer.exe -Profile development`; o wrapper não altera a política PowerShell global.
7. Verifique os destinos no jogo e publique uma revisão validada. Para produção no txAdmin, troque o exec em `server.cfg` para `config/production.cfg`; no iniciador de diagnóstico use `-Profile production`. Esse perfil bloqueia rascunhos e não constitui aprovação de conteúdo.

Voz é opcional: retire `exec config/voice.cfg` se não a instalar. Progressão, social, admin e menu podem ser removidos da ordem de ensure sem impedir a persistência da garagem e o treino básico via contratos. Não retire core, world ou vehicles das dependências obrigatórias correspondentes. Não instale vMenu/ESX/QBCore neste perfil.

## Configuração e conteúdo

| Conteúdo | Arquivo |
| --- | --- |
| Rede, banco local, ACE, ordem | `config/*.cfg` |
| Mundo e destinos | `resources/[mx]/mx-freeroam-world/config.lua` |
| Modelos, tags, revisões, limite de presets e desempenho nativo | `resources/[mx]/mx-freeroam-vehicles/config.lua` |
| Pistas, amostragem, retenção e drift | `resources/[mx]/mx-freeroam-activities/config.lua` |
| XP, níveis, ícones, títulos e semanas UTC | `resources/[mx]/mx-freeroam-progression/config.lua` |
| Convites, grupos, presença e expiração | `resources/[mx]/mx-freeroam-social/config.lua` |

O catálogo inicial contém apenas Futo, Elegy Retro, Elegy RH8, Sultan e Blista vanilla. São carros de desenvolvimento, sem promessa de equilíbrio. Para um asset autorizado, instale seu resource separadamente, adicione um item com `id`, `model`, `name`, `category`, `tags`, `revision` e `asset='nome-do-resource'`. `id` e modelo devem coincidir nesta versão. Asset ausente torna o item indisponível. A disponibilidade real do modelo ainda é confirmada no client com timeout. Não foram ativados nem revisados os packs JDM existentes na instalação antiga.

Destinos têm slots, heading, região, `validated` e dependência opcional `asset`. Verifique colisão, espaço e segurança de cada slot antes de marcar validado. Pistas têm revisões imutáveis, direção explícita, checkpoints e recuperações. `/mxtrack` captura e publica conteúdo com ACE; veja [operação](docs/operations.md). Alterar uma definição publicada exige nova revisão. O desafio semanal de exemplo está desligado porque a pista não foi validada.

## Verificações reproduzíveis

```powershell
npm run build
npm run check
npm test
$env:MX_TEST_DATABASE_URL='mysql://USUARIO:SENHA@127.0.0.1:3306/mx_freeroam_test'
npm run test:db
$env:MX_CHROMIUM='CAMINHO\chrome.exe'
npm run test:ui
node tests/run-lua.mjs --load
```

O teste SQL exige um banco de teste previamente criado. `tests/restore.mjs` exige usuário de teste capaz de criar outro banco isolado, além de `MX_MYSQLDUMP` e `MX_MYSQL`. A verificação no runtime está em [testing.md](docs/testing.md): ela insere fixtures declaradas no banco de teste, sem se apresentar como corrida ou cliente real. `resources/[tests]/mx-verification` nunca entra no ensure público.

Não há edição de handling, física, potência inventada, câmbio, economia, monetização ou fórmula competitiva de drift. Integrações futuras do câmbio devem consultar os contratos existentes de veículo/sessão e conservar a elegibilidade, sem acrescentar regras ao core.

## Documentação

- [Arquitetura, propriedade e restart](docs/architecture.md)
- [Contratos e eventos](docs/contracts.md)
- [Backlog T01–T40](docs/backlog.md)
- [Cobertura F01–F13 e limites reais](docs/coverage.md)
- [Teste do primeiro marco, dois clientes e carga](docs/testing.md)
- [Instalação, conteúdo, backup, restore e atualização](docs/operations.md)
- [Inventário e decisões](docs/decisions.md)
