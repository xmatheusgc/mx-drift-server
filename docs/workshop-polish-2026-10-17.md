# Ajustes de oficina, lobby e confirmação — 17/10/2026

Esta entrega substitui a semântica de salvamento manual descrita em `lobby-showroom-controls-2026-10-17.md`. Nenhum dado existente foi removido ou migrado, nenhum resource legado foi alterado e o servidor em uso não foi reiniciado automaticamente.

## Apresentação

- Lobby: 23:00 e FOGGY, apenas no cliente em apresentação. Câmera aproximada pelos offsets `forward=5.9`, `right=4.8`, `up=1.7`. Coordenadas continuam **-949.47, -3533.03, 13.94, heading 274.72**. Presets da garagem permanecem independentes.
- Suspensão: painel único de sliders e valores numéricos para altura, cambagem dianteira/traseira e afastamentos. Diâmetro/largura aparecem apenas quando suportados pelas rodas. Peça de suspensão do modkit e restauração original continuam acessíveis. Ajustar mostra prévia; confirmar aplica o conjunto e persiste.
- Pintura & adesivo: inclui liveries tradicionais, teto e slot 48 do modkit, quando disponíveis. Amostras sem números impressos. Clique numa amostra ou Enter/A/Cross confirma; setas mostram prévia. Correção de acabamentos RGB para `primaryFinish`/`secondaryFinish`, preservando a distinção entre tintas indexadas e RGB.
- Iluminação: faróis forçados durante a edição; confirmação de cor xenon habilita xenon, cor neon habilita seus lados. Alternância discreta de visão noturna no topo, por clique, Q/E ou LB/RB/L1/R1. Retorno e encerramento restauram o ambiente normal.
- Faixas: componente `OptionStrip`, sem setas, sem padding lateral, com itens mais largos e excedentes cortados pela tela. Contagem da seleção no título do editor. Scrollbars invisíveis e rolagem ancorada preservadas.
- Confirmação: componente `ConfirmDialog`, fundo escurecido, faixa de largura total e ações verticais. Uma seleção lógica atualizada imediatamente; foco acompanha a seleção. Teclado e mensagens do controle passam pelo mesmo manipulador, sem navegar também na tela de trás.
- Configurações: `SettingsRow` compartilhado, lista à esquerda, linha selecionada clara, valor à direita e descrição contextual ao lado. Selects e sliders funcionam com teclado, controle e mouse.
- `ControlHints` continua sendo o componente único de instruções: ícones solid de 21 px, escala compacta e mesmo estilo. Editor mostra ações no canto inferior direito em todos os níveis.

As referências visuais são as três imagens fornecidas nesta solicitação. Não foram incorporados assets gráficos nem código de NFS. Os ícones Kenney previamente licenciados permanecem sem alteração de licença.

## Catálogo de mods

O erro observado vinha da tentativa de consultar diretamente `[vehicles]` usando Node fs: a categoria não é um resource montado. A nova descoberta consulta resources registrados por `GetNumResources`/`GetResourceByFindIndex`, filtra `GetResourcePath` pela categoria autorizada e lê os metadados efetivos de manifest. Os pares `data_file`/`data_file_extra` fornecem tipo e caminho JSON, inclusive em manifests gerados com Lua. `LoadResourceFile` lê os arquivos literais sem fs direto. Globs enumeram apenas o resource montado correspondente, sem seguir links simbólicos ou aceitar caminhos que escapem dele.

O inventário offline desta instalação encontra **12 modelos**. Isso não comprova que todos carregam no cliente. O console passa a mostrar `[MX catalog] N authorized resources / N metadata files / N models`; erros são localizados por resource. O Showroom consulta novamente o índice a cada cinco segundos enquanto estiver aberto.

Correção posterior de `Tag inválida`: o fabricante bruto de `s15naoki`, `SILVIA S15 NAOKI NAKAMURA`, possui 25 bytes. As tags auxiliares geradas agora respeitam o contrato de 1–24 bytes UTF-8 e excluem caracteres de controle/markup. Marca e identidade do resource/modelo não são truncadas; quando nenhuma tag cabe, usa-se `addon`. A validação do servidor continua ativa e identifica o modelo em eventuais novos erros. Regressões cobrem os assets instalados e fabricante Unicode/resource longo; `npm test` e `npm run check` passaram. Boot atualizado no FXServer ainda precisa ser repetido.

Depois de atualizar e reiniciar o perfil coordenadamente, confira essa linha. Para assets novos: `refresh`, inicie a categoria autorizada e execute `mx_catalog_reload` no console do servidor. Não foi ampliada a permissão de leitura com `--allow-fs-read`. Modelos legados salvos continuam válidos sem aparecer como novos modelos do Showroom.

Referências técnicas oficiais: [sandbox FiveM](https://docs.fivem.net/docs/developers/sandbox/), [implementação Cfx dos pares de metadados de data_file](https://github.com/citizenfx/fivem/blob/master/code/components/citizen-resources-gta/src/ResourcesTest.cpp). Foram usadas para consultar o contrato, sem copiar implementação.

## Retorno OBSOLETE

Foi identificada uma corrida no código: sair do editor emitia uma nova intenção de modelo antes de aguardar a aplicação cosmética pendente. `vehicles:ApplyPreview` revalida a geração após seu RPC assíncrono, então a intenção de saída tornava obsoleta uma aplicação que ainda estava terminando. O erro não era causado necessariamente pela marca do controle.

A saída agora cancela a fila visual do editor, aguarda o pedido em andamento e somente depois publica a invalidação do modelo e restaura o estado confirmado. Mensagens de mudança de cena vindas do servidor cancelam a fila local sem emitir uma invalidação adicional. A validação de geração no servidor foi preservada; erros reais não são escondidos como sucesso. Há regressão de browser para entrar com teclado, atrasar uma prévia e retornar com mensagens de controle.

## Confirmação e persistência

Não existem botões Salvar veículo atual ou Descartar alterações do carro, nem Ctrl+S no editor. Confirmar peça/cor/ajustes chama `confirmCurrent` com UUID estável de operação. O domínio vehicles valida, aplica e prepara as consultas; experience compõe a seleção persistida e o recibo no journal transacional. Editar um carro salvo preserva seu ID e atualiza sua revisão. A confirmação explícita Usar este carro no Showroom cria uma configuração salva; apenas examinar os modelos não cria registros.

Falha de SQL não avança o snapshot confirmado. Uma resposta perdida pode ser repetida pelo mesmo UUID, sem duplicar o registro ou reaplicar a revisão. A interface mantém Tentar novamente/Recarregar estado para confirmações incertas. Primeiro acesso, personagem único e gerenciamento das criações permanecem disponíveis. O modal de salvar/descartar continua válido para a aparência do personagem, cujo fluxo não foi substituído por este pedido.

## Verificação e limites

Resultados objetivos estão em `evidence/workshop-polish-2026-10-17.json`, `ui.json` e `lobby.json`. Há capturas dos painéis, faixas, cores, configurações e confirmação em 1280×720, 1920×1080, 2560×1440 e 3440×1440. As capturas de browser têm fundo neutro: não representam uma cena 3D do FiveM.

Build inclui TypeScript; também foram executados o check estático, testes Lua/Fengari, contratos NUI/React com Chromium e testes MariaDB em banco isolado `mx_freeroam_test_experience`. O projeto não possui comando separado de lint. Os testes de rotas Lua usam adaptadores de SQL/natives; o teste MariaDB verifica armazenamento, revisão e leitura após nova conexão, sem executar entidades FiveM.

Ainda dependem do jogo: neblina e iluminação no cenário instalado, enquadramento real do carro/personagem, streaming de cada mod, comportamento físico dos sliders aceitos, som do motor, foco/câmeras em entrada/saída repetida e navegação com controle físico. Nenhum cliente FiveM foi executado nesta entrega; não se declara o comportamento de entidades, câmeras ou reconexão no jogo como validado.
