# Lobby, controle, cores e carros salvos — 17/10/2026

> Histórico desta etapa. A semântica de salvar, a descoberta de catálogo e os ajustes visuais foram substituídos em [ajustes de oficina e confirmação](workshop-polish-2026-10-17.md).


Implementação incremental no perfil txAdmin existente. Não houve importação de base, remoção de dados, alteração de schema ou reinício automático do servidor. Este documento atualiza a semântica anterior de aplicação imediata: confirmar uma peça aplica ao carro da sessão; a coleção é gravada por Salvar veículo atual.

## Cena e transições

O lobby usa horário local fixo de **23:00**, configurável em `ExperienceConfig.lobbyTime`. O domínio world continua sendo o único responsável por aplicar o relógio, evitando disputa entre loops. Ao entrar na garagem ou sair da apresentação, o horário normal de `WorldConfig.hour` é retomado. As luzes locais de carro/personagem permanecem; o horário dos outros jogadores não é alterado. Aparência final da iluminação ainda depende de conferência no FiveM.

`resources/[mx]/mx-freeroam-experience/config.lua` contém `lobbyPresentation`, `lobbyOffsets`, `lobbyScene` e `lobbyCamera`. O veículo do lobby usa **-949.47, -3533.03, 13.94, heading 274.72**. O personagem fica fora da largura da carroceria, consulta o solo e recebe orientação calculada em direção à câmera. A cena da garagem mantém seus presets anteriores, incluindo a apresentação em **178.62, -3088.07, 5.0, heading 300**.

O servidor reutiliza o controlador existente de prévias e o bucket privado. A troca de contexto encerra a apresentação, confirma desembarque também no servidor e remove a prévia anterior antes de preparar outra. A seleção da sessão fica separada da entidade visível. Mover foco entre botões não recria a cena. Loading continua opaca até a preparação e o ACK da NUI; o lobby pronto tem fundo transparente para revelar o mundo. Sem carro válido, a composição fica vazia, com personagem, sem inserir um vanilla ou gravar uma criação automaticamente.

## Navegação: evidências e correções

O código anterior continha retorno circular nas faixas: direita no último item selecionava o primeiro; esquerda no primeiro selecionava o último. O lobby percorria a ordem do DOM, organizada por coluna, em vez da direção espacial. O editor ainda escrevia seleção tanto pelo comando quanto pelo `onFocus`; comandos rápidos podiam consultar o índice da renderização anterior.

Agora a seleção do editor usa identidade estável e referência atualizada no mesmo comando. Foco apenas acompanha essa seleção, com `preventScroll`. Listas horizontais param nas extremidades e ignoram itens desabilitados. Lobby e formulários usam geometria dos controles visíveis, excluindo abas globais; modais restringem o escopo de navegação.

`menu/navigation.lua` amostra um comando do controle por vez. Há limiar de entrada 0,6, retorno ao centro abaixo de 0,3, atraso inicial de 350 ms e repetição de 140 ms por relógio, sem acumular repetições atrasadas. A direção do analógico fica travada até centralizar, evitando oscilação diagonal. Confirmação, retorno, abas e salvamento exigem soltar o botão antes de outra ação. A NUI avisa quando muda o contexto de foco; o controle deve voltar ao neutro. O resource de experiência conserva leitura contínua de motor e órbita; a navegação discreta do lobby/garagem passa somente pelo resource de menu. O analógico usado para zoom em câmera livre não navega a lista simultaneamente. Modais suspendem motor e entrada da câmera.

Não foi reproduzida a inversão com hardware real nesta execução. Os comportamentos acima foram identificados no código e as regressões verificam os caminhos corrigidos; não se atribui todo relato físico a uma única causa presumida.

## Rolagem ancorada

`development/ui/src/navigation.ts` calcula o centro real do item no conteúdo e limita o deslocamento entre zero e `scrollWidth-clientWidth`. A referência é o centro da viewport. Não há preenchimento fictício nas extremidades. Uma animação de 140 ms substitui a anterior quando chega outro comando; a seleção lógica muda imediatamente. Foi removido o `scroll-snap` que alinhava os itens pelo início e disputava esse cálculo. O teste de navegador também detectou que o smooth scroll nativo demorava demais em saltos longos; a animação limitada substitui esse comportamento.

As faixas de customização, modelos e criações usam o mesmo cálculo; resize recalcula o posicionamento. Cores continuam em grade, com ordem própria. Teclado, controle e clique compartilham o estado; hover não reescreve a seleção.

## Interface e cores

Lobby e telas afetadas compartilham transparência, foco branco e hover sem borda extra, usando os tokens atuais. O botão redundante Lobby saiu da tela inicial da garagem; Esc/B/Círculo retorna pelo nível correto. As telas intermediárias conservam Voltar.

`ColorPanel.tsx` substitui a faixa de opções durante a edição de principal/secundária, RGB, perolado, rodas, interior, painel, xenon, neon e fumaça. A composição segue a imagem anexada: painel compacto à esquerda, atual/recentes, grade e seleção evidente. Os acabamentos de pintura ficam dentro do painel, sem duplicar opções na faixa inferior. Efeitos RGB não recebem acabamentos de pintura. RGB exato continua disponível pelos três campos. Índices nativos, RGB, acabamentos e reset original mantêm suas propriedades distintas. Amostras de tintas indexadas são representativas: material, iluminação e resultado real são vistos na prévia do carro. A grade RGB representa os valores enviados.

Navegar mostra prévia; Enter/A/Cross ou Aplicar confirma no carro da sessão. Voltar sem confirmar reaplica o estado confirmado. Salvar não confirma uma amostra apenas destacada. Cabeçalhos sobrepostos e uma faixa vazia de modelos que interceptava cliques nas marcas foram corrigidos durante a inspeção/testes.

## Catálogo por origem

Correção de sandbox: no FXServer, o indexador enumera `GetNumResources` / `GetResourceByFindIndex` e usa `GetResourcePath` para selecionar os resources registrados dentro da categoria autorizada. Só esses diretórios de resources são enumerados/lidos. A categoria `[vehicles]` não é um resource montado: tentar `fs.existsSync` ou listar diretamente seu diretório causava `no device found` / `fs.read`. A varredura direta da categoria permanece somente na ferramenta de inventário/teste fora do FXServer. Não é necessário adicionar `--allow-fs-read`. Depois de instalar um resource novo, use `refresh` antes de iniciá-lo/recarregar o catálogo para registrá-lo no FXServer.

As falhas de leitura de um resource geram diagnóstico localizado; exceções no reload não escapam do timer. O teste executa o ramo real de inicialização JS com um adaptador de filesystem que proíbe consultar a categoria e resources de fora dela. Também confirma que uma falha de leitura não interrompe o timer. Isso não substitui repetir a inicialização no runtime FXServer.

`vehicles/catalog.js` lê somente a categoria configurada por `mx_vehicleCatalogFolder` (default `[vehicles]`), relativa a `resources`. Não segue links simbólicos, não executa manifests e mantém o caminho dentro de resources. Descobre declarações literais `VEHICLE_METADATA_FILE` em `fxmanifest.lua`/`__resource.lua`, incluindo glob, subpastas e vários modelos. Extrai `modelName`, `gameName` e `vehicleMakeName`; ausência de fabricante vira Sem marca. Declarações duplicadas tornam o modelo indisponível e geram diagnóstico.

O inventário real encontrou **12 modelos em 12 recursos**, incluindo `chaser` dentro de `toyotachaserjzx100` — o nome da pasta não foi tomado como modelo. O índice é recarregado na inicialização, após starts de resources (debounce) e pelo comando de console `mx_catalog_reload`. Start/stop também afeta disponibilidade consultada no servidor; um modelo que não carregar no cliente produz erro explícito. Recursos com manifests inteiramente dinâmicos precisam expor declarações literais para este indexador; não foram encontrados nesse formato no inventário atual.

`VehicleConfig.catalogLabels` permite corrigir apresentação sem alterar assets. Os packs nis15/s15naoki colocam Nissan em `gameName` e o modelo em `vehicleMakeName`: foram corrigidos explicitamente para NISSAN. O fabricante D1 do pack er34 fica Sem marca para revisão, sem inferência pelo nome técnico. `docs/evidence/catalog-discovery.json` conserva os metadados brutos anteriores a essas correções. O fluxo é Showroom → Marca → Modelos → Usar este carro.

Os cinco IDs vanilla anteriores permanecem válidos para dados legados; não entram no Showroom. Isso preserva, por exemplo, o Elegy já salvo sem ampliar o catálogo autorizado. Não há fallback vanilla silencioso.

## Carro da sessão e coleção

`experience/server.lua` orquestra `useCurrent`, `confirmCurrent`, `saveCurrent` e `discardCurrent`. Validação de propriedades, autoridade das entidades e preparação das consultas continuam no domínio vehicles. O estado distingue a criação atual (com ID salvo opcional), a prévia temporária e o veículo público. Abrir o catálogo ou navegar por prévias não substitui o snapshot atual.

Usar um modelo do Showroom deixa-o na sessão, sem SQL na coleção. O primeiro acesso conserva a confirmação inicial de carro existente. Confirmar uma peça atualiza o snapshot da sessão. Salvar veículo atual, na coleção ou no atalho, usa a mesma rota: carro novo recebe um ID; associado e modificado atualiza esse ID; associado sem alterações conserva a revisão e não duplica. O journal existente grava recibo e alterações na mesma transação e permite repetir confirmação perdida com o mesmo UUID. Falha preserva trabalho e bloqueia saída dependente; a interface pede resolver confirmação incerta antes de nova edição.

Carros salvos lista as criações por ID, preservando duplicar/renomear/excluir. Salvar fica separado dessas entradas. O estado Não salvo/Alterações pendentes/Salvo é visível. Ao sair do editor ou substituir o carro, os alertas distinguem carro novo de salvo modificado. Sair sem salvar conserva o novo carro só na sessão; trocar sem salvar confirma sua substituição. Descartar de um salvo recupera a versão persistida. O snapshot da sessão atravessa Lobby ↔ Garagem e Jogar; não se promete recuperação de um carro não salvo após reconexão.

### Comandos

| Ação | Teclado | Xbox | PlayStation |
| --- | --- | --- | --- |
| Navegar | Setas | Direcional/analógico esquerdo | Direcional/analógico esquerdo |
| Abas globais | Q / E | LB / RB | L1 / R1 |
| Confirmar/aplicar | Enter | A | Cross |
| Voltar | Esc / Backspace | B | Círculo |
| Salvar carro atual, no editor | Ctrl+S ou botão | X ou botão | Quadrado ou botão |
| Mudar visão | C | Y | Triângulo |

Atalho de salvamento funciona também no painel de cores, sem sair dele. Ícones adicionais reutilizam os vetores Kenney já presentes, sob CC0. Não foi incorporado código de vMenu ou de outro projeto.

## Arquivos e contratos principais

- `resources/[mx]/mx-freeroam-experience/{config,client,server}.lua`: presets independentes, transição, snapshot da sessão e operações de coleção.
- `resources/[mx]/mx-freeroam-menu/{navigation,client}.lua` e manifest: amostragem única, repetição e fronteira de foco.
- `resources/[mx]/mx-freeroam-vehicles/{catalog.js,catalog.lua,config.lua,server.lua,garage.lua}` e manifest: descoberta, marcas, disponibilidade e inclusão de propriedades na criação nova.
- `development/ui/src/{Workshop,Lobby,VehicleEditor,ColorPanel,ControlHints}.tsx`, `navigation.ts`, `input-boundary.ts`, `main.tsx`, ícones e CSS: fluxos, foco, rolagem, cores e visual.
- `development/tests/{navigation.lua,session-car-env.lua,session-car.lua,catalog.mjs,ui.mjs,lobby.mjs,run-lua.mjs}`: regressões e contratos. O dist entregue foi reconstruído.

## Verificações e roteiro no jogo

Comandos: `npm --prefix development run build` (inclui typecheck), `npm --prefix development run check`, `npm --prefix development test`, `test:ui`, `test:lobby` e `test:db` com banco exclusivamente de teste. O projeto não possui script separado de lint; check e diff check são as verificações estáticas disponíveis. Os resultados finais desta rodada estão em `docs/evidence/lobby-showroom-controls-2026-10-17.json`.

Os testes de Lua incluem 16 verificações da amostragem de controle e 17 das rotas reais de sessão com adaptadores SQL/natives simulados. Descoberta foi testada em packs de fixture e na pasta real. Browser verifica quatro resoluções, sequência exata de vizinhos, comandos rápidos, limites, ancoragem, modal, RGB, confirmação e retry de salvamento. MariaDB isolado verifica persistência e recuperação por conexão SQL; não é reconexão FiveM. Screenshots do painel foram inspecionados, sem imagem 3D de jogo.

**Não houve execução com cliente FiveM ou controle físico nesta rodada.** Pendentes: streaming/colisão no novo local, enquadramento e pés/rosto do personagem, fidelidade das cores materiais, mapeamento real de cada controle, replicação/destruição de entidades e transição/loading com runtime Cfx.

Depois de reiniciar o perfil e reconectar:

1. Conferir Loading → Lobby novo → Garagem antiga → Voltar repetidas vezes; observar direção do personagem e ausência de prévias abandonadas.
2. Percorrer faixas longas nos dois sentidos com toque e pressão, analógico e direcional; testar Q/E/LB/RB, modais, cor e câmera livre sem ações simultâneas.
3. Usar um modelo sem salvar; personalizar e sair sem salvar; voltar e conferir o carro da sessão. Testar salvar/trocar/cancelar, editar salvo e descartar. Salvar duas vezes e reconectar: conferir mesmo ID, propriedades e ausência de duplicatas.

Referências oficiais consultadas: [controles Cfx](https://docs.fivem.net/docs/game-references/controls/), [manifest](https://docs.fivem.net/docs/scripting-reference/resource-manifest/) e [cores nativas](https://docs.fivem.net/docs/game-references/vehicle-references/vehicle-colors/). A referência visual principal foi a imagem anexada pelo usuário.
