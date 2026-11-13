# Nomes dos veículos nas interfaces

Data local: 2026-10-24 (America/Sao_Paulo).
Projeto: C:\FiveM\drift-server.
Origem: pedido do usuário no Codex, leitura dos metadados e alterações locais.

O catálogo já obtinha name de gameName e brand de vehicleMakeName. Foram removidas as correções antigas de nis15, s15naoki e er34 para respeitar os metadados configurados pelo usuário.

Saved e SavedList agora acrescentam modelLabel a partir do catálogo corrente, com fallback para o código do modelo quando não há metadados. Oficina, garagem e troca de carros salvos no trainer usam esse rótulo para apresentar o modelo. Nomes personalizados de criações permanecem preservados; nomes salvos iguais ao código técnico aparecem como o rótulo do veículo. Nenhuma migration ou alteração dos registros existentes foi necessária. Identidades técnicas e telas de diagnóstico administrativo continuam usando seus identificadores.

Verificação: build com TypeScript/Vite e check estático aprovados; teste de catálogo aprovado; execução isolada dos exports reais Saved/SavedList verificou rótulo, atualização de metadados, fallback e preservação de nome e modelo. Interface compilada conferida em Edge headless a 1920x1080: título 180SX, nome personalizado, rótulos da garagem e nome padrão antigo aprovados, sem erros JavaScript.

A suíte geral npm test interrompeu em development/tests/orbit-client.lua:64: o teste espera FOV 73.5 para o lobby, enquanto resources/[mx]/mx-freeroam-experience/config.lua configura 60.0. Esses arquivos não foram alterados nesta tarefa. Não houve teste no FiveM nem reinicialização de servidor/resources.

Próximo passo: reiniciar o servidor para carregar scripts e metadados atualizados e validar showroom, oficina, carros salvos e troca no trainer dentro do FiveM.

## Resumo para a memória compartilhada

Em 24/10/2026, Codex ajustou as interfaces de veículos do Drift server FiveM para apresentar gameName dos vehicles.meta, mantendo vehicleMakeName como marca e preservando nomes personalizados das criações. Removidos overrides antigos de nomes/marcas. Build, check, catálogo, exports de garagem e interface em navegador aprovados. Suíte geral encontrou divergência de FOV do lobby em arquivos não alterados; aceite no FiveM pendente após reinicialização. Fonte: este relatório e arquivos modificados na base ativa txData/FiveMBasicServerCFXDefault_CAECC7.base. A base Obsidian C:\Users\mathe\Documents\Memoria-IA foi consultada, mas não atualizada porque a sessão permite gravação apenas no workspace e temporários.
