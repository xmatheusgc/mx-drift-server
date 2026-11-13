# Acesso ao resmon — 24/10/2026

O proprietário pediu modo de desenvolvimento para usar o monitor de resources. A entrada do perfil Drift já executa `config/development.cfg`; não foi necessário trocar produção/desenvolvimento do projeto.

O build configurado é GTA V Legacy (3258). Conforme a [documentação oficial de comandos do cliente](https://docs.fivem.net/docs/client-manual/console-commands/#developer-commands), o modo de desenvolvimento para comandos como resmon é habilitado iniciando o cliente com `+set moo 31337`. O perfil development.cfg do projeto não altera os argumentos do cliente. A [documentação do Enhanced](https://docs.fivem.net/docs/developers/legacy-vs-enhanced/) distingue o mecanismo novo `sv_devMode`, específico daquela variante; ele não foi acrescentado à base Legacy.

Foi criado `C:\FiveM\drift-server\FiveM-Desenvolvimento.cmd`. Ele procura FiveM.exe na instalação padrão e também aceita arrastar o executável sobre o CMD. Valida o nome/caminho e instrui fechar a sessão anterior antes de iniciar o cliente com os argumentos fixos. Não grava em CitizenFX.ini nem troca canal de atualização. Uma versão intermediária em PowerShell foi descartada porque a execução de scripts está desabilitada no Windows; nenhuma política foi alterada.

Uso: fechar o cliente FiveM, abrir o iniciador (ou arrastar seu FiveM.exe sobre ele, se a instalação padrão não for encontrada), conectar ao Drift e executar `resmon true` no F8. `resmon false` fecha o monitor. O servidor pode continuar ligado. O monitor mostra CPU/memória dos resources no cliente; desempenho do servidor é objeto de profiling próprio.

Verificação: cadeia server.cfg → development.cfg → config/server.cfg conferida e argumentos fixos/validação de caminho do CMD revisados. O VerifyOnly da versão intermediária em PowerShell foi bloqueado pela política de execução e não foi executado. Executável do cliente não foi localizado nos caminhos consultados; deverá ser fornecido ao usar o iniciador. Não houve lançamento de processo FiveM, reinício de cliente/servidor, alteração de configuração ativa ou confirmação do resmon em jogo.

Memória registrada somente no export local do workspace, sem escrita na base Obsidian compartilhada.
