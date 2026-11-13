# Registro tardio da oficina na primeira entrada — 24/10/2026

Relato do proprietário: ao abrir o servidor houve `experience/scene`, `MX:SCENE_ASSET`, modelo `denis3d_ts_shell` não registrado. Clicar novamente em GARAGEM no lobby abriu a oficina normalmente. Origem: conversa de 24/10/2026, aproximadamente 10:50, America/Sao_Paulo.

## Diagnóstico e correção

O arquivo `scene-streaming.lua` exigia `IsModelInCdimage` verdadeiro imediatamente após iniciar a preparação da cena. Se o resource já estivesse started e o modelo ainda não constasse no cliente, a operação falhava antes da espera de streaming. O sucesso na segunda tentativa é compatível com registro tardio; não houve captura do instante de registro no cliente real.

O mapa instalado `resources/[maps]/ps-tuners` possui os três YTYP e seu manifest já os declara em `files` e `DLC_ITYP_REQUEST`. Não foi necessário alterar o manifest ou o asset nesta correção. A função [IsModelInCdimage](https://github.com/citizenfx/natives/blob/master/STREAMING/IsModelInCdimage.md) consulta a presença do modelo; resultado falso naquele instante não foi tratado como prova definitiva de arquivo ausente.

A preparação agora verifica o registro a cada 50 ms dentro do prazo compartilhado da cena (30 s). Cada modelo é solicitado uma única vez, somente após registrado. O callback só confirma prontidão depois de todos os modelos carregados, cena, colisão, interior e estabilidade de 250 ms. Enquanto aguarda, mantém as proteções de entrada existentes; não libera o jogador numa oficina incompleta.

Modelo que continuar sem registro ao fim do prazo gera `SCENE_ASSET` com seu nome. Outros atrasos de streaming mantêm `SCENE_STREAM`. Não há repetição ilimitada nem aumento do prazo: o callback continua abaixo dos 35 s reservados pelo core. Resource ausente/parado continua falhando, inclusive se parar durante a espera. Cancelamento invalida a operação e faz a limpeza do foco/cena/modelos/interior.

## Verificação e limites

Suíte completa `npm.cmd --prefix development test` e `run check` aprovadas. Regressões novas com controlador real e natives simulados cobrem registro atrasado de 900 ms, pedido único após registro, espera adicional do interior/modelo/estabilidade, cancelamento antes do registro, ausência permanente até o prazo e limpeza sem ACK de prontidão. Os testes anteriores de timeout, cancelamento e resource ausente continuam aprovados.

Não houve mudança de UI, rebuild, alteração de banco, restart ou conexão de cliente FiveM nesta etapa. O relato confirma uma recuperação manual bem-sucedida; a entrada automática com a correção ainda precisa ser testada no cliente real.

Próximo passo: reiniciar pelo txAdmin, reconectar e testar a primeira entrada na garagem logo após o boot. Esperado: o carregamento aguarda o registro e abre a oficina sem exigir um segundo clique. Se houver falha após os 30 s, coletar o novo F8 para distinguir ausência permanente do modelo de atraso de interior/colisão.
