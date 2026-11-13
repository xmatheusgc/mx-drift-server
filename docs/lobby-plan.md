# Ajustes incrementais — Lobby, navegação da garagem e câmeras

**Data:** 16/10/2026  
**Destino:** agente responsável pela implementação atual do servidor FiveM  
**Escopo:** somente as decisões discutidas a partir da mensagem “Pontos de ajuste” sobre redundância dos botões e criação do lobby

## 1. Orientação para o agente

Implemente os ajustes abaixo sobre a versão atual. Inspecione o código e as instruções do repositório para localizar as telas, estados e controladores envolvidos. Reutilize os fluxos e funcionalidades já implementados; este documento não solicita reconstruir a experiência completa do servidor.

O objetivo desta entrega é reorganizar a navegação inspirada no Need for Speed Heat, introduzir um lobby anterior à garagem, integrar o primeiro acesso a essa navegação e corrigir a apresentação das câmeras.

Não incorporar planos anteriores inteiros como novo trabalho. Não recriar sistemas existentes ou acrescentar funcionalidades que não sejam necessárias aos ajustes descritos aqui.

## 2. Problema atual e organização desejada

O menu principal repete ações: Meu personagem, Catálogo de modelos e Preferências aparecem tanto no topo quanto na barra inferior. Eliminar essa redundância dando uma responsabilidade a cada nível:

| Nível | Responsabilidade |
| --- | --- |
| Carregamento | Preparar a entrada, cobrindo totalmente o fundo. |
| Lobby | Escolher a atividade geral: garagem, configurações, acesso social e demais ações descritas. |
| Barra superior da garagem | Selecionar o contexto: carro, personagem, catálogo ou ranking. |
| Barra inferior da garagem | Mostrar as ações pertinentes ao contexto selecionado. |

Usar a linguagem visual que já está sendo construída, com referência de composição e navegação do NFS Heat. A entrega é uma evolução da interface atual.

## 3. Loading screen

Ao entrar no servidor, mostrar uma loading screen com a identidade da interface existente e uma barra de progresso na parte inferior.

- O fundo deve ser totalmente opaco. Por enquanto, usar preto.
- Preparar a estrutura para substituir/complementar o fundo com imagens futuramente; não é necessário criar essas imagens agora.
- Cobrir toda a tela, inclusive proporções ultrawide.
- Não deixar cenário, personagem ou veículo aparecerem por trás, nem durante a passagem ao lobby.
- Relacionar o progresso às etapas/sinais reais disponíveis. Não chegar artificialmente a 100% enquanto o acesso ainda não está pronto.
- Quando não houver percentual confiável para uma etapa, comunicar preparação sem inventar precisão.
- Falhas de carregamento precisam de tratamento compreensível, sem deixar uma tela preta indefinida.

Ao terminar o carregamento necessário, apresentar o lobby já pronto e ainda com fundo totalmente opaco. Voltar ao lobby dentro da mesma sessão não deve repetir o carregamento inicial do servidor.

## 4. Lobby anterior à garagem

### 4.1 Layout

O lobby terá fundo preto por enquanto, preparado para imagens futuras. Aqui não mostramos a cena 3D da garagem.

**Não haverá botões no topo.** Usar a mesma linguagem da barra inferior da tela inicial atual, reorganizada em três grupos:

| Grupo | Botão principal | Botão menor abaixo |
| --- | --- | --- |
| Esquerda | **Garagem** | Criar grupo |
| Centro | **Discord** | Configurações |
| Direita | **Loja** | Jogadores e amigos |

Garagem recebe o foco inicial. Jogadores e amigos é a identificação proposta para a ação originalmente descrita como Procurar jogadores, incluindo a possibilidade de adicionar amigos.

Não repetir essas opções em uma segunda barra. Preservar navegação por teclado compatível com os controles existentes, com foco claro e apenas uma região ativa por vez.

### 4.2 Funções

- **Garagem:** verificar o progresso inicial e abrir a garagem ou a etapa pendente.
- **Criar grupo:** sem função nesta entrega. Exibir como desabilitado/Em breve, sem falsa confirmação de criação.
- **Discord:** abrir o convite do servidor definido em configuração. Não inventar um endereço. Sem link configurado, apresentar indisponibilidade de forma clara.
- **Configurações:** abrir as preferências já existentes, reaproveitando sua implementação. Esse passa a ser seu local na navegação principal.
- **Loja:** sem função nesta entrega. Exibir como desabilitado/Em breve.
- **Jogadores e amigos:** permitir procurar jogadores e adicionar amigos. Organizar o fluxo em jogadores online, amigos e solicitações, com envio e aceite de amizade persistentes. Reutilizar o que já existir; não simular sucesso sem gravar a relação.

Criar grupo e Loja continuam placeholders. Não ampliar este pedido para implementar grupos, compras ou outros sistemas sociais além da relação de amizade necessária.

## 5. Garagem: barra superior e ações inferiores

### 5.1 Abas superiores

Ao entrar na garagem, manter as opções superiores estáveis, na mesma ordem:

**Meu carro · Personagem · Showroom · Ranking**

Embora um dos exemplos iniciais omitisse Showroom ao selecionar Personagem, a solução definida mantém todas as abas para evitar que os botões desapareçam ou mudem de posição durante a navegação.

A aba selecionada altera a apresentação e as ações da barra inferior, sem duplicar os próprios atalhos superiores.

### 5.2 Mapeamento

| Aba superior | Apresentação | Ações na barra inferior |
| --- | --- | --- |
| **Meu carro** | Carro selecionado em destaque, com personagem na cena. | **Jogar**, Performance, Customização, Trocar de carro. |
| **Personagem** | Personagem em destaque, com enquadramento apropriado. | **Jogar**, Roupas, Aparência. |
| **Showroom** | Prévia do modelo destacado no catálogo. | Adicionar à garagem e filtros/ações pertinentes ao catálogo existente. |
| **Ranking** | Classificação ou estado de indisponibilidade, conforme a implementação real. | Somente filtros e ações que correspondam a funcionalidades existentes. |

O botão Jogar é maior e fica na mesma posição nas abas Meu carro e Personagem. Ele utiliza o veículo salvo selecionado, independentemente da aba.

Reutilizar as funções atuais de roupas, aparência, customização e troca de carro. Performance e Ranking não autorizam criar novos sistemas de física ou pontuação: preservar o que existir e indicar Em breve quando não houver implementação disponível.

### 5.3 Showroom e Trocar de carro

Definir destinos diferentes para evitar nova redundância:

- **Showroom:** catálogo gratuito para escolher um modelo e adicionar uma nova criação à garagem.
- **Trocar de carro:** coleção dos veículos/configurações que o jogador já salvou.

O antigo Catálogo de modelos passa a ser acessado pelo Showroom, sem botão equivalente repetido no rodapé principal. Nesta organização, Showroom não é uma exposição de carros da comunidade.

Navegar pelo catálogo somente apresenta uma prévia. Adicionar à garagem confirma o salvamento e permite seguir para a customização do novo carro. Voltar sem confirmar recupera a seleção salva anterior.

### 5.4 Entrada em edição e retorno

Ao entrar em Customização, Roupas ou Aparência, reutilizar os editores existentes. A barra superior pode ser recolhida durante a edição para liberar a cena, com indicação compacta do contexto.

Voltar primeiro percorre os níveis do editor e depois retorna à aba de origem. Antes de abandonar alterações pendentes, permitir salvar, descartar ou continuar editando. Não descartar silenciosamente.

Voltar da garagem principal leva ao lobby. Se o lobby foi aberto durante uma sessão de gameplay, preservar uma forma contextual de retomar essa sessão, sem criar uma nova barra superior no lobby nem repetir o carregamento de conexão.

Trocar de aba deve alterar somente o contexto da interface e a apresentação necessária. Preservar a correção existente que impede recriação desnecessária do veículo.

## 6. Primeiro acesso dentro dessa nova navegação

### 6.1 Fluxo

**Carregamento → Lobby → selecionar Garagem → confirmar personagem → escolher primeiro carro → garagem principal → Jogar.**

Todos os jogadores começam pelo mesmo lobby. As etapas obrigatórias só são resolvidas ao selecionar Garagem; não abrir automaticamente o criador antes do lobby.

Usar o criador e a seleção de carro existentes, adaptando sua entrada e retorno. Não solicitar novamente sua implementação completa.

### 6.2 Experiência rápida

- Apresentar um preset inicial de personagem coerente.
- Permitir confirmar esse preset ou editá-lo antes de continuar.
- Depois, permitir visualizar e confirmar um primeiro carro gratuito.
- Não obrigar ajustes detalhados de aparência ou customização do veículo para começar a dirigir.
- Ao concluir as duas etapas, mostrar a garagem principal com personagem e carro confirmados e Jogar em destaque.

### 6.3 Mesmas telas, ações contextuais

| Tela reaproveitada | Primeiro acesso | Acesso posterior |
| --- | --- | --- |
| Editor de personagem | **Confirmar personagem**, concluindo a etapa após salvar. | **Salvar alterações** e **Cancelar**. |
| Showroom | **Escolher este carro**, salvando e selecionando o primeiro veículo. | **Adicionar à garagem**. |

Durante as etapas obrigatórias, recolher a navegação completa da garagem. Mostrar somente a tarefa atual e os controles necessários, sem oferecer Meu carro antes de existir um carro salvo.

### 6.4 Voltar, desconexão e conclusão

Voltar durante a etapa inicial permite retornar ao lobby sem marcar a etapa como concluída. Havendo rascunho, resolver seu descarte/continuação de forma explícita. Na próxima entrada em Garagem, retomar da última confirmação persistida.

| Estado do jogador ao selecionar Garagem | Destino |
| --- | --- |
| Personagem não confirmado | Criador de personagem. |
| Personagem confirmado e primeiro carro pendente | Seleção inicial no Showroom. |
| Ambos concluídos | Garagem principal com seleção salva válida. |
| Ambos concluídos, mas todos os carros foram excluídos depois | Garagem vazia com **Adicionar veículo**, sem repetir a introdução. |

Reutilizar as flags/estados persistentes existentes; nomes sugeridos, se necessários, são `characterCreationCompleted` e `initialVehicleSelectionCompleted`. Concluir cada etapa somente depois do salvamento confirmado pelo servidor.

Desconectar depois de salvar o personagem não exige recriá-lo. Desconectar depois de confirmar o carro não exige escolhê-lo novamente. Repetir uma confirmação cuja resposta se perdeu não pode duplicar o registro salvo. Falha de carga não pode ser interpretada como primeiro acesso nem sobrescrever dados válidos.

## 7. Corrigir a aproximação excessiva das câmeras de peças

### 7.1 Problema

Durante a personalização, vários enquadramentos aproximam tanto a câmera que ela quase entra na carroceria e a peça deixa de ser visível. Corrigir o conjunto dos presets afetados, não apenas um exemplo.

### 7.2 Comportamento esperado

- Cada categoria usa distância, altura, ponto de mira e FOV adequados à região observada.
- A peça deve aparecer inteira, com margem e contexto suficientes para avaliar a alteração.
- O bone serve como referência da peça, não como posição pronta da câmera.
- A câmera permanece fora da carroceria, do chão e do cenário.
- Adaptar os enquadramentos às dimensões do modelo e à proporção de tela.
- Não aplicar um único offset muito curto a todas as categorias.
- Definir limites de aproximação por categoria, sem tratar uma constante como garantia universal contra clipping.
- Evitar atravessar a geometria durante o movimento entre presets, não apenas no destino final.
- Quando não houver bone/referência confiável, usar um enquadramento mais aberto e seguro da região correspondente.

Verificar rodas, capô, frente, traseira, saias e escapamento em carros de tamanhos diferentes. Ajustar distância, mira e FOV em conjunto; não corrigir tudo apenas com FOV exagerado.

Manter o veículo existente ao trocar de categoria. Essa correção não é um pedido para reconstruir a câmera de condução ou a infraestrutura já funcional de personalização.

## 8. Inverter a composição da câmera principal e do personagem

Esta é a nova orientação da cena principal e substitui a disposição anterior.

**Os lados abaixo são sempre os lados do próprio carro, olhando no sentido da sua frente, e não os lados da tela.**

| Elemento | Posição/orientação desejada |
| --- | --- |
| Câmera principal | Quadrante dianteiro direito do carro, olhando diagonalmente para ele. |
| Composição | Manter a linguagem do Heat, com carro e personagem bem apresentados e sem cortes provocados pela interface. |
| Personagem | Lado esquerdo do carro, alinhado à roda dianteira esquerda e com afastamento lateral adequado. |
| Direção do personagem | Olhando para o carro, aproximadamente 90° em relação ao sentido longitudinal do veículo. |
| Relação visual | O personagem fica com sua frente/rosto visíveis pela câmera posicionada do outro lado, enquanto olha para o carro. |

O personagem não deve continuar olhando no sentido da marcha. Virar seu corpo para o carro; não apenas girar a cabeça ou obrigá-lo a olhar diretamente para a lente. Validar o sinal da rotação pelo sistema de orientação do projeto, sem somar 90° arbitrariamente em coordenadas globais.

Usar posições relativas ao carro e, quando disponível, referência da roda dianteira. Prever fallback pelas dimensões do modelo. Garantir pés no chão, corpo visível e ausência de interseção com roda/carroceria.

A câmera continua baixa e relativamente próxima na composição geral, mas precisa enquadrar o conjunto de forma utilizável. A proximidade artística da cena principal não elimina os limites de segurança dos enquadramentos de peças.

Centralizar os ajustes de composição para facilitar calibração posterior, reutilizando a representação atual do personagem e a infraestrutura de cena existente.

## 9. Verificação e entrega

Executar as verificações disponíveis do projeto e validar os fluxos alterados. Priorizar:

- Loading cobrindo integralmente o fundo e passagem ao lobby sem flashes.
- Lobby com os três grupos inferiores, sem navegação superior.
- Ausência de atalhos redundantes.
- Mudança de aba alterando corretamente a barra inferior.
- Jogar consistente nas abas Meu carro e Personagem.
- Showroom separado da coleção de veículos salvos.
- Primeiro acesso iniciando no lobby e reaproveitando as telas atuais.
- Retorno ao lobby, desconexão e retomada em cada etapa inicial.
- Garagem vazia sem reinício da introdução.
- Câmeras de peças sem aproximação excessiva ou passagem pela carroceria.
- Câmera principal dianteira direita e personagem dianteiro esquerdo olhando para o carro.
- Navegação sem regressão de foco, rascunho ou ciclo de vida do veículo.

Ao concluir, informar quais arquivos e fluxos foram alterados, o que foi reutilizado e quais verificações foram executadas. Se não puder executar o FiveM, separar claramente as verificações de código dos ajustes de composição e câmera que ainda dependem de validação dentro do jogo.

Não reapresentar sistemas antigos como novas entregas. Este documento solicita apenas o incremento especificado acima.
