# Recuperação de diâmetro/largura de roda — 24/10/2026

O proprietário relatou `MX:STANCE` ao aumentar o diâmetro no SC300A. O controlador convertia a recusa do native em falha de toda a personalização. O mesmo caminho era usado ao recriar um carro com stance salvo, podendo impedir seu uso. Também havia duas aplicações de stance no mesmo callback.

A documentação primária de [SetVehicleWheelSize](https://github.com/citizenfx/fivem/blob/master/ext/native-decls/SetVehicleWheelSize.md) e [SetVehicleWheelWidth](https://github.com/citizenfx/fivem/blob/master/ext/native-decls/SetVehicleWheelWidth.md) informa retorno booleano e restrição a rodas de personalização, não às rodas originais. Isso justifica verificar suporte por execução; não comprova qual detalhe do asset SC300A provocou o relato. Nenhum arquivo desse carro foi alterado e nenhum modelo foi colocado em blacklist.

## Comportamento implementado

- `VehicleStance.ensure` mantém a validação estrita e trata apenas recusas de tamanho/largura como limitações recuperáveis. A aplicação estrita tenta restaurar ambas as dimensões anteriores ao falhar. A recuperação lê a dimensão efetiva, normaliza somente o fator recusado e reaplica os demais ajustes. Há no máximo três passagens para resolver as duas dimensões.
- Diâmetro recusado não desativa largura, altura, cambagem ou afastamento. Rodas originais usam fatores 1. Modelos sem suporte ao controlador visual retornam stance desativado. Valores inválidos, entidade substituída e dimensão efetiva fora dos limites continuam falhando.
- A limitação é local à identidade/modelo do veículo e ao conjunto de rodas (família e índices dianteiro/traseiro). Ela evita repetir setters recusados a cada frame. Trocar o conjunto ou recriar o veículo permite verificar novamente. O primeiro diagnóstico de cada dimensão nesse contexto é registrado no F8 com `[MX:STANCE]`, entidade, modelo, rodas e valor pedido.
- `vehicles/apply` aplica stance uma vez e responde `stance={value,warning?}`. As capacidades incluem valor efetivo, `unavailable` por campo e aviso. A interface mostra a limitação, desabilita somente o campo afetado e substitui o rascunho pelo valor confirmado.
- Prévia, aplicação cosmética, spawn e editor legado incorporam o stance confirmado antes de publicar/guardar suas propriedades. O salvamento da experiência usa a prévia efetiva; não persiste o diâmetro recusado como se tivesse sido aceito. Carregar um preset antigo normaliza a entidade sem regravar automaticamente o SQL; um salvamento explícito passa a usar o valor efetivo.
- Posse, identidade, geração de seleção, ACK obrigatório, revisão e integridade dos outros cosméticos continuam protegidos. Não há fallback genérico que converta qualquer erro em sucesso.

## Verificação

`npm.cmd --prefix development test`, `run check`, `run typecheck` e `run build` aprovados. A suíte inclui 42 verificações de stance com natives simulados: recusa individual e dupla, preservação dos outros campos, valor efetivo, ACK malformado, cache de limitação, troca de rodas, identidade e payload inválido. O controlador de prévias foi exercitado com ACK normalizado nos caminhos de candidato e edição.

`run test:ui`, com Chrome instalado via `MX_CHROMIUM`, aprovado em 1280×720, 1920×1080, 2560×1440 e 3440×1440. A fixture simula recusa de diâmetro, confirma o campo desabilitado, permite largura e salva os fatores efetivos. Capturas `docs/evidence/stance-size-fallback-*.png`; inspeção visual da captura 1280×720. Esses testes não validam os natives no FiveM.

## Aplicação e pendências

Não houve restart, alteração de dados de jogador nem modificação de assets de veículos nesta etapa. Fazer reinício completo pelo txAdmin e reconectar os clientes para carregar os contratos Lua e o bundle novo em conjunto. Testar SC300A com as rodas do relato, aumentar diâmetro/largura, salvar outro ajuste e recriar o carro. O ajuste recusado deve voltar ao valor efetivo com aviso, mantendo o uso do carro. Conferir também rodas originais, outro conjunto de rodas e outro modelo modificado.

O suporte real ao redimensionamento no SC300A continua pendente de reteste em jogo. Esta entrega corrige o tratamento da recusa; não afirma ter corrigido o asset ou habilitado um native incompatível.

## Complemento — rodas já modificadas, 24/10/2026, 10:40

O proprietário esclareceu que as rodas do SC300A já haviam sido modificadas. Portanto, rodas originais na tentativa não explicam o relato. A investigação encontrou um defeito reproduzível no controlador: uma configuração visual feita antes da troca de rodas podia capturar tamanho/largura zero e conservar essa referência após instalar rodas modificadas. Multiplicar essa referência por qualquer fator continuava resultando em zero.

A implementação [upstream de VehicleExtraNatives.cpp](https://github.com/citizenfx/fivem/blob/master/code/components/extra-natives-five/src/VehicleExtraNatives.cpp), consultada nesta etapa, recusa zero e depende da estrutura gráfica `streamRenderGfx` disponível. Não há nesse setter uma blacklist por nome do modelo. Isso esclarece uma possível falha de inicialização/estado; não comprova que a versão carregada no PC do jogador percorreu esse caminho.

Corrigido `stance.lua` para inicializar separadamente tamanho/largura na primeira leitura positiva de rodas modificadas quando a referência anterior é zero/inválida. Referências já válidas permanecem estáveis; mudanças repetidas não acumulam escala e o retorno ao neutro restaura as medidas válidas. O diagnóstico passa a incluir baseline, solicitado, lido e retorno nativo antes da restauração, separando recusa de divergência de leitura.

A regressão original → modificada foi reproduzida em VM com a inicialização removida e passou com a correção. Suíte completa e check reexecutados e aprovados; agora são 47 verificações de stance (cinco novas). Natives simulados; sem cliente FiveM ou restart. UI/build não foram alterados nem reexecutados neste complemento. A causa do caso real SC300A continua pendente de reteste; não classificar o modelo como incompatível a partir do erro anterior.
