# Plano de implementação — Experiência de entrada, oficina, personagem e câmeras do freeroam FiveM

**Data:** 16/10/2026  
**Destino:** agente de IA responsável pela implementação no repositório do servidor  
**Status:** decisões de produto consolidadas; solução técnica a adaptar ao projeto real  
**Referências de composição:** imagens `image(6).png` e `image(7).png`, fornecidas pelo usuário

## 1. Instrução para o agente

Implemente uma experiência integrada de entrada e personalização para um servidor FiveM freeroam de carros. O jogador terá um único personagem persistente, uma coleção de veículos salvos gratuitamente e uma oficina que funciona como menu principal. A interface deve se inspirar na composição de Need for Speed Heat e Unbound, com identidade própria do servidor.

Leia este documento inteiro, incluindo o Anexo A de câmera de corrida e drift. Inspecione o repositório, suas instruções e os recursos já existentes antes de propor mudanças. Reutilize as implementações de identidade, persistência, veículos, personagem, interface e câmeras quando forem adequadas.

Este plano detalha a experiência de entrada e oficina; complementa o plano geral do freeroam. Não autoriza reconstruir funcionalidades não relacionadas ou importar regras do projeto de servidor zumbi. Não presume que qualquer recurso de outro projeto exista neste repositório.

Entregue funcionalidades integradas e recuperáveis, com documentação e verificação. Não encerre a tarefa apenas com telas estáticas ou botões sem integração. Se algo depender de assets ausentes ou de testes dentro do FiveM, implemente o que for possível e registre precisamente a pendência.

Os nomes de recursos, campos e contratos abaixo são sugestões. As decisões de experiência identificadas como obrigatórias devem ser preservadas; a organização técnica deve seguir as convenções reais do projeto.

## 2. Decisões obrigatórias de produto

| Tema | Decisão consolidada |
| --- | --- |
| Entrada padrão | Todo acesso concluído abre a oficina principal depois das etapas iniciais necessárias. |
| Primeiro acesso | Criar personagem → escolher e salvar primeiro carro → oficina → Jogar. |
| Personagens | Um personagem persistente por jogador. Sem multicharacter, slots ou tela de seleção de personagens. |
| Aparência | Personagem inicial bem apresentado; edição completa disponível gratuitamente na oficina a qualquer momento. |
| Veículos | Não há compra de veículos. Catálogo gratuito para adicionar veículos à garagem. |
| Garagem | Exibe as configurações salvas pelo jogador, inclusive várias versões do mesmo modelo. |
| Primeiro carro | É um veículo salvo comum; pode ser mantido, alterado ou excluído. |
| Botão Jogar | Leva ao freeroam com o veículo exibido e a configuração confirmada. |
| Próximos acessos | Oficina com o personagem persistido e o último veículo selecionado válido. |
| Câmera de condução | Personalizada e opcional; original disponível; primeira instalação com a personalizada desligada. |
| Direção visual | Composição inspirada nas referências de NFS, com carro e personagem em destaque. |
| Física | Não alterar handling ou condução para produzir esta experiência. |

Não implementar preferência para pular a oficina ou entrar diretamente no freeroam nesta entrega: a decisão final do usuário é manter a oficina como entrada padrão. Tornar o início rápido por meio do botão Jogar, sem etapas extras de confirmação quando já existir um carro válido.

## 3. Objetivo da experiência

Ao entrar, o jogador deve reconhecer seu personagem e o carro que escolheu e personalizou. A oficina deve parecer um espaço do jogo, com cena 3D real, iluminação e enquadramento adequados, apoiado por uma interface clara nas bordas da tela.

O caminho comum precisa ser curto: carregar perfil, apresentar a oficina e clicar em Jogar. A criação de personagem e a escolha obrigatória do primeiro carro acontecem apenas enquanto ainda não tiverem sido concluídas com sucesso.

Não introduzir economia, concessionária, pagamentos, aluguel, garagem de RP ou requisitos de propriedade do mundo real. O foco é experimentar carros, salvar criações e dirigir com amigos.

## 4. Inspeção obrigatória antes de implementar

1. Ler `AGENTS.md`, instruções locais e documentação do projeto.
2. Identificar como o servidor reconhece e autentica o jogador, carrega o perfil e inicia o spawn.
3. Localizar persistência existente, migrações, validação de payloads e controle de concorrência.
4. Mapear catálogo, spawn/despawn, veículo ativo, propriedades salvas e personalização já implementados.
5. Mapear modelo de personagem, aparência, roupas, respawn e aplicação de dados após trocar o ped.
6. Localizar NUI, stack frontend, componentes, mensagens/callbacks, foco e tratamento de teclado/controle.
7. Mapear todos os sistemas que controlam câmera, streaming, visibilidade, minimapa e controles.
8. Verificar oficina/interior disponível, carregamento de assets, pontos de apresentação e pontos de saída.
9. Identificar dependências reais de vMenu ou outro menu e preservar funções administrativas ainda necessárias.
10. Registrar o que será reutilizado, modificado ou criado; não manter dois fluxos concorrentes para a mesma função.

Não adicionar ESX, QBCore ou um framework amplo apenas para atender este plano. A base do servidor deve continuar pequena, modular e escalável. Não remover recursos administrativos porque o novo menu assume a experiência comum do jogador.

## 5. Fluxo de acesso e retomada

### 5.1 Primeiro acesso

1. Aguardar identificação e carregamento válido do perfil.
2. Preparar uma cena protegida de criação de personagem, sem expor um ped provisório no mundo público.
3. Apresentar um preset inicial coerente e permitir editar a aparência.
4. Confirmar e persistir o personagem; somente após sucesso concluir essa etapa.
5. Abrir seleção do primeiro veículo, com prévia 3D e catálogo permitido pelo servidor.
6. Confirmar e salvar a configuração inicial; somente após sucesso concluir essa etapa.
7. Apresentar a oficina principal com personagem e veículo persistidos.
8. Disponibilizar Jogar imediatamente.

O criador pode reutilizar o cenário da oficina, com enquadramento dedicado ao personagem. A oficina principal, com sua navegação completa, só é liberada após as duas etapas iniciais. Não exigir texto introdutório longo, nome de RP, sobrenome, data de nascimento ou documentação fictícia.

### 5.2 Acessos seguintes

Resolver o estado a partir dos dados persistidos, sem confiar em flags enviadas pela NUI:

| Estado carregado | Destino |
| --- | --- |
| Perfil válido; criação ainda não concluída | Criador de personagem. |
| Personagem concluído; primeira escolha de carro pendente | Seleção inicial de veículo. |
| Ambas as etapas concluídas; veículo selecionado válido | Oficina com esse veículo. |
| Ambas concluídas; seleção inválida, mas existem outros salvos válidos | Escolher um fallback determinístico e abrir a oficina. |
| Ambas concluídas; garagem vazia | Oficina vazia com Escolher veículo em destaque. |
| Falha de carregamento ou dados incompatíveis | Recuperação/erro com opção de tentar novamente; não tratar como conta nova. |

Queda de rede, timeout ou erro de banco não são evidência de primeiro acesso. Não sobrescrever dados existentes com defaults nessas situações.

### 5.3 Estados persistentes

Sugestão de campos:

- `characterCreationCompleted`.
- `initialVehicleSelectionCompleted`.
- `selectedSavedVehicleId`, podendo ser nulo.
- Versão do formato de aparência, das propriedades do veículo e das preferências.

Salvar aparência e conclusão da criação de forma atômica no armazenamento escolhido. Salvar primeiro carro, seleção e conclusão da primeira escolha também de forma atômica. Se não houver transação entre os registros, usar operação idempotente e recuperação explícita para impedir flags sem dados ou veículos duplicados.

Se a persistência confirmar a operação e a resposta se perder, repetir a requisição deve recuperar o resultado, sem criar outra configuração. Uma desconexão depois da criação do personagem leva à escolha do carro no próximo acesso.

Excluir todos os veículos não apaga flags nem reabre a introdução. Se um registro de aparência estiver corrompido, encaminhar à recuperação do personagem sem apagar a garagem. Jogadores existentes precisam de migração compatível, baseada nos dados reais disponíveis.

## 6. Criador e editor do personagem

### 6.1 Identidade única

Cada perfil tem uma única aparência ativa. Não implementar lista de personagens, troca de identidade ou exclusão de personagem como fluxo comum. Editar a aparência atual não reinicia onboarding nem altera a identidade persistente.

Para uma base sem solução anterior, considerar os modelos freemode compatíveis com personalização como ponto de partida. Verificar o suporte real do projeto antes de escolher o formato. Não prometer que qualquer ped arbitrário suporta todos os controles.

### 6.2 Escopo do editor

Oferecer as categorias suportadas pela base de personagem escolhida:

- Modelo base e opções de herança/rosto quando aplicáveis.
- Traços faciais e tonalidade da pele.
- Cabelo, cores e sobrancelhas.
- Barba e opções de aparência do rosto suportadas.
- Olhos e sobreposições compatíveis, como maquiagem e marcas.
- Roupas por categoria e acessórios/props disponíveis.
- Presets iniciais coerentes para quem preferir começar rapidamente.

Apresentar o editor em categorias compreensíveis, sem expor índices técnicos de drawable, texture, collection ou hashes ao jogador. Validar opções e combinações disponíveis; mudanças de modelo devem atualizar as opções dependentes. Evitar peças incompatíveis, partes invisíveis e braços atravessando roupas. Um catálogo curado pode ser necessário para garantir bons presets.

Começar com poucos presets bem montados; não é necessário gerar dezenas de personagens aleatórios. Categorias sem suporte real devem ser omitidas e documentadas, em vez de exibir controles sem efeito.

### 6.3 Prévia e confirmação

- Alterações aparecem na cena enquanto o jogador edita.
- Salvar persiste a aparência após validação e confirmação do servidor.
- Cancelar restaura a aparência anterior e o enquadramento de origem.
- No primeiro acesso, voltar/cancelar não pode pular a criação; oferecer retorno ao preset ou permanência na etapa.
- Depois do onboarding, Meu personagem reabre o editor completo gratuitamente, quantas vezes o jogador quiser.
- Trocar o modelo do ped exige readquirir a referência e reaplicar os dados compatíveis; não conservar handles obsoletos.
- Respawn/reconexão devem reaplicar a aparência confirmada.

A cena pode usar o ped do próprio jogador ou uma entidade de prévia conforme a arquitetura existente. Em qualquer caso, o rascunho deve ficar separado da aparência persistida e não vazar para a sessão pública.

## 7. Oficina como menu principal

### 7.1 Composição da cena

- Veículo selecionado em posição de apresentação, com espaço para órbita e aproximação de câmera.
- Personagem ao lado, em pose/animação ociosa discreta e compatível.
- Iluminação que permita avaliar a pintura, peças e roupas sem depender de filtros exagerados.
- Ambiente coerente de oficina, com props e decoração que não ocultem o carro.
- Movimento de câmera lento e limitado no estado ocioso, com opção de reduzir movimento.
- HUD de condução oculto enquanto a oficina possui a apresentação.

Oficina, iluminação e câmera fazem parte da entrega. Uma interface bonita sobre um cenário mal enquadrado não satisfaz o objetivo. Usar um interior já disponível e autorizado é uma opção válida; não inventar dependência de um MLO pago ou asset inexistente.

### 7.2 Navegação principal

| Opção | Ação |
| --- | --- |
| Jogar | Iniciar freeroam com veículo e aparência confirmados. |
| Minha garagem | Selecionar e organizar veículos salvos. |
| Personalizar veículo | Abrir as opções suportadas do carro exibido. |
| Meu personagem | Abrir editor da aparência atual. |
| Preferências | Ajustar câmera, interface, áudio disponível e controles suportados. |

Jogar é a ação principal e deve estar visível sem abrir um submenu. Não adicionar confirmação de saída rotineira. Se houver edição pendente, o usuário deve salvar ou descartar antes de continuar.

### 7.3 Garagem vazia

Manter a oficina e o personagem, sem instanciar silenciosamente um carro excluído. Mostrar mensagem curta e a ação Escolher veículo. Jogar não inicia uma sessão com veículo inválido; apresentar claramente que é necessário selecionar e salvar um carro.

Ao confirmar um novo veículo nessa situação, ele é salvo, selecionado e apresentado na oficina. As flags de primeiro acesso permanecem concluídas.

### 7.4 Voltar à oficina durante a sessão

Disponibilizar uma ação clara no menu de sessão, com tecla/comando conforme o padrão do projeto. Não obrigar o jogador a reconectar para personalizar novamente.

Para a primeira versão, permitir retorno voluntário em condições válidas e, quando estiver dirigindo, com veículo parado. Não sequestrar a sessão de passageiros nem transportar terceiros automaticamente: bloquear o retorno com explicação curta quando houver ocupantes, até que exista um fluxo específico para isso.

Capturar e guardar a referência do contexto público de retorno. O servidor deve controlar o destino e a retirada de entidades públicas pertinentes. Na saída da oficina, restaurar apenas os estados temporários necessários e respeitar o spawn escolhido, sem deixar o ped invencível ou congelado no freeroam.

## 8. Catálogo e veículos salvos

### 8.1 Conceitos separados

| Conceito | Significado |
| --- | --- |
| Catálogo | Modelos permitidos pelo servidor para iniciar uma nova configuração gratuita. |
| Veículo salvo | Identidade persistente de uma criação do jogador, com modelo, nome e propriedades. |
| Veículo selecionado | Registro salvo que será apresentado na oficina e usado ao clicar em Jogar. |
| Entidade de prévia | Representação temporária na cena, sem criar um novo veículo salvo. |
| Entidade de gameplay | Veículo ativo autorizado no mundo público. |

Um handle de entidade ou network ID não é a identidade persistente do veículo salvo. Não usar placa como única chave de propriedade. Cada criação deve ter seu próprio ID.

### 8.2 Operações obrigatórias

- Adicionar veículo pelo catálogo, com prévia antes de confirmar.
- Selecionar um salvo e atualizar a cena e a seleção persistida.
- Renomear uma configuração.
- Duplicar uma configuração, com novo ID.
- Excluir com confirmação, indicando o nome correto do item.
- Salvar aparência e propriedades permitidas do veículo.
- Manter várias configurações do mesmo modelo.
- Identificar visualmente o item selecionado.

As opções são gratuitas. Limites de quantidade podem existir por configuração operacional do servidor, sem moeda ou compra de slots. Se implementados, devem ser claros e razoáveis.

Ao excluir o selecionado, usar outro salvo válido: preferir o mais recentemente utilizado e aplicar um desempate estável. Persistir a nova seleção no mesmo fluxo de exclusão. Ao excluir o último, usar o estado de garagem vazia. Não bloquear exclusão porque o carro foi recebido no primeiro acesso.

### 8.3 Modelos indisponíveis

Se um add-on foi removido ou não carregou, não apagar a configuração automaticamente. Indicar indisponibilidade e permitir selecionar outro carro. Se todos os salvos estiverem indisponíveis, oferecer o catálogo sem repetir a introdução.

O primeiro acesso não pode exigir uma escolha em catálogo vazio: detectar essa configuração inválida e mostrar recuperação. Implementar timeout e erro para carregamento de modelo; nunca esperar indefinidamente.

### 8.4 Coleções grandes

Pesquisa por nome/modelo e carregamento progressivo são recomendados quando a quantidade justificar. Nunca criar todos os carros salvos como entidades simultâneas. Manter apenas a prévia necessária e descartar resultados atrasados quando o usuário muda rapidamente de seleção.

Miniaturas podem usar assets já existentes ou um fallback consistente; uma pipeline de fotografias automáticas de toda a garagem não é pré-requisito desta entrega.

## 9. Personalização do veículo

### 9.1 Categorias

Exibir somente opções reais para o modelo e o suporte disponível no projeto, como:

- Pintura principal/secundária e acabamentos suportados.
- Rodas e cores compatíveis.
- Para-choques, saias, aerofólios e outras peças disponíveis no mod kit.
- Liveries, extras e componentes suportados.
- Placa e opções cosméticas permitidas.
- Vidros, iluminação, neon e fumaça de pneus quando suportados e permitidos.

Esses exemplos não garantem que todos os carros possuam as opções. Descobrir e validar capacidades. Não exibir categorias vazias nem assumir que todo veículo add-on tem mod kit funcional.

Não incluir nesta entrega motor, transmissão, turbo, freios, aderência, handling, suspensão funcional, stance que altere a condução ou calibração do câmbio manual. Opções existentes desse tipo devem ser identificadas na inspeção e tratadas sem mudar a física por conta deste plano.

### 9.2 Rascunho e salvamento

1. Abrir o editor a partir da configuração confirmada.
2. Criar rascunho isolado.
3. Aplicar alterações visualmente na prévia.
4. Salvar após validação do servidor e confirmação da persistência.
5. Cancelar restaura a configuração confirmada completa.

Definir um limite claro de confirmação: na primeira versão, Salvar/Cancelar pertencem à sessão de edição do veículo; navegar entre categorias conserva o rascunho. Voltar ao menu principal ou clicar em Jogar com rascunho pendente exige escolher salvar, descartar ou continuar editando.

Não persistir a cada movimento do seletor. Não exibir sucesso antes da confirmação do servidor. Se salvar falhar, manter o rascunho para permitir nova tentativa. Aplicar o mesmo modelo ao personagem.

## 10. Direção visual e interação

### 10.1 Referências fornecidas

`image(6).png` mostra a composição geral: carro central, personagem ao lado, navegação superior e categorias na região inferior. `image(7).png` mostra edição contextual com opções em faixa horizontal inferior e a maior parte do cenário visível.

Usar essas relações de composição, hierarquia e navegação como referência. Se as imagens não estiverem disponíveis no ambiente do agente, seguir a descrição deste documento e registrar a falta; não afirmar que analisou imagens ausentes.

Criar identidade própria, sem reutilizar logos, música, assets ou textos proprietários da série. Não exigir shaders, personagem estilizado ou efeitos gráficos de Unbound para alcançar a referência de interface.

### 10.2 Regras de composição

- Carro e personagem ocupam a área principal, livres de painéis desnecessários.
- Navegação principal compacta; opções contextuais nas bordas ou faixa inferior.
- Tipografia expressiva nos títulos e legível nos controles, com suporte a português.
- Painéis escuros com transparência moderada e contraste suficiente.
- Estados selecionado, hover, foco, desabilitado e carregando claramente diferentes.
- Uma cor principal de destaque configurável; não tratar a paleta de um exemplo como identidade definitiva.
- Informações úteis: nome da configuração, modelo e posição na coleção.
- Sons curtos e discretos, com preferência de volume quando houver suporte real.
- Transições curtas, sem atrasar cada interação ou esconder a confirmação de ações.

Não reproduzir dinheiro, preços, cadeados de compra ou estatísticas fictícias porque aparecem nas referências. Não inventar barras de potência, velocidade ou aceleração sem uma fonte e uma metodologia adequadas. Evitar um dashboard de cartões que esconda o cenário.

### 10.3 Controles e acessibilidade

- Navegação consistente por mouse, teclado e controle.
- Indicadores de comando mudam conforme o dispositivo ativo.
- Foco visível e ordem previsível.
- Esc/Voltar fecha a camada atual antes de sair do fluxo; respeita alterações pendentes.
- Não usar apenas cor para comunicar erro ou seleção.
- Área segura e layout responsivo para 16:9 e ultrawide; validar resoluções menores.
- Controles de sliders com passos coerentes e valores visuais compreensíveis.
- Preferência para reduzir animações e movimento automático de câmera.
- Texto de erro curto e orientado à ação, sem stack traces ou nomes técnicos.

Usar a stack frontend existente. Se não houver nenhuma e não existir restrição no repositório, React + TypeScript é uma proposta adequada para a NUI. Tailwind e bibliotecas de componentes podem ser aproveitados, mas os componentes devem seguir a direção de interface de jogo definida aqui.

## 11. Câmeras da oficina

Definir presets por tarefa, adaptados ao tamanho do carro e à posição do personagem:

| Contexto | Enquadramento esperado |
| --- | --- |
| Oficina principal | Carro em três quartos e personagem ao lado. |
| Troca de veículo | Composição geral, reajustada ao modelo selecionado. |
| Pintura/livery | Carro inteiro e possibilidade de observação/orbita limitada. |
| Rodas | Aproximação da região da roda sem ocultar a seleção. |
| Peças dianteiras/traseiras | Vista da região correspondente. |
| Neon | Vista que permita observar a parte inferior. |
| Personagem geral/roupas | Corpo inteiro. |
| Rosto/cabelo | Aproximação do rosto com iluminação adequada. |

Interpolar movimentos sem atravessar o carro ou o cenário. Validar espaço e colisões dos caminhos; uma interpolação suave não garante trajetória segura. Adaptar offsets por dimensões, com ajustes manuais de cena e limites para veículos grandes.

Oferecer rotação/observação onde trouxer benefício; não tornar órbita obrigatória para usar o menu. Pausar movimentos automáticos durante observação manual. A interface precisa reservar área livre compatível com o enquadramento.

## 12. Câmera opcional de corrida e drift

Implementar o algoritmo e os requisitos completos do Anexo A, preservando:

- Câmera local do motorista, sem sincronização por quadro.
- Câmera original sempre disponível.
- Ativação opcional, tecla remapeável e preferência persistente.
- Primeira instalação com o modo personalizado desligado.
- Suavização temporal, trajetória/drift, colisões, entrada manual e tratamento de estados especiais.
- Nenhuma alteração na física do veículo para produzir efeitos de câmera.
- Parâmetros iniciais tratados como hipóteses de calibração, sujeitos a teste jogando.

Adicionar o controle de habilitação à seção Preferências da nova interface. Não expor todos os parâmetros matemáticos ao jogador. Manter comando/tecla como acesso rápido e diagnóstico separado para desenvolvimento.

O Anexo A adiava uma NUI sofisticada porque tratava somente da câmera. Este plano amplia expressamente a integração visual: a oficina e suas preferências agora fazem parte da entrega. Isso não exige reescrever o algoritmo nem adicionar outras modalidades, como replay, drone ou modo foto.

## 13. Coordenação de câmera e entradas

Reutilizar ou implementar um mecanismo pequeno de posse que sirva à oficina, ao criador e à condução, sem criar um framework genérico. Nenhum recurso deve disputar a visão reativando sua câmera a cada quadro.

- A câmera de condução só atua quando o jogador está elegível, fora da oficina e sem prioridade de outro contexto.
- O editor de personagem e a oficina solicitam posse dentro de seu fluxo de apresentação.
- Respawn, espectador e outros sistemas existentes precisam de uma política explícita de integração.
- Usar identificadores/tokens de posse ou suspensão que impeçam uma liberação antiga de desativar o contexto atual.
- Permitir múltiplos motivos de suspensão; remover um não libera os demais.
- Ao ceder posse, parar escritas e limpar apenas os próprios handles.
- Não usar limpeza global que destrua câmeras alheias.
- Preferência de drivecam ligada permanece ligada mesmo enquanto a oficina a suspende.
- Na saída, verificar novamente a preferência, a elegibilidade e o proprietário atual antes de retomar.

Aplicar a mesma disciplina a foco NUI, cursor, controles, HUD, congelamento, invencibilidade temporária, streaming e modificações locais de ambiente. Registrar o estado anterior e restaurar somente o que o módulo ainda controla; não substituir preferências ou alterações legítimas de outro sistema.

## 14. Sessão de oficina e isolamento

A apresentação de entrada é um contexto privado de menu. O jogador não deve ver carros de prévia de terceiros sobrepostos, ser atropelado enquanto edita ou publicar rascunhos de aparência no freeroam.

Definir a estratégia após inspecionar o cenário e a rede existentes. A documentação do OneSync cita telas de personagem como uso de routing buckets, mas desaconselha tratá-los como solução genérica para interiores. Diferenciar uma sessão privada de apresentação de uma oficina física compartilhada com visão para o exterior.

Se optar por bucket privado para a sessão de apresentação, o servidor controla a associação de jogador e entidades relevantes e conserva o contexto público de retorno. Validar compatibilidade com modos de lockdown: não criar prévias pelo cliente presumindo que um bucket estrito as permitirá.

Se optar por cena local ou outra estratégia, documentar como evita exposição e interferências. Usar entidades de prévia não implica automaticamente que o próprio ped do jogador esteja isolado.

Nesta primeira versão, oficinas sociais, visitas e edição conjunta ficam fora do escopo. Não carregar a cena privada de todos os jogadores em todos os clientes.

## 15. Botão Jogar e ciclo de vida do veículo

### 15.1 Preparação da saída

1. Bloquear cliques duplicados e mostrar estado curto de preparação.
2. Confirmar sessão, personagem salvo e veículo selecionado válido no servidor.
3. Resolver alterações pendentes antes do pedido de entrada.
4. Selecionar um ponto de spawn configurado e permitido, compatível com o veículo.
5. Verificar ocupação e reservar temporariamente o ponto no servidor; a reserva evita que duas saídas simultâneas escolham o mesmo espaço. A verificação física deve considerar entidades carregadas e a arquitetura disponível.
6. Preparar modelo, colisão e entidade na sequência compatível com a estratégia de rede e streaming adotada.
7. Aplicar a configuração confirmada e posicionar o jogador como motorista.
8. Confirmar que a transição está pronta antes de ocultar definitivamente o menu e liberar controles.
9. Liberar a câmera da oficina e retomar gameplay ou drivecam conforme a preferência e a posse atual.
10. Limpar prévias, reservas e a sessão privada de apresentação.

Uma transição curta com fade pode encobrir a troca de contexto. Não exigir animação física de portão ou percurso interno para a primeira versão. O resultado esperado é o jogador fora da oficina, no carro que estava sendo exibido.

### 15.2 Política de destinos

Usar pontos de saída previamente configurados para o primeiro acesso. Ao voltar à oficina durante uma sessão, preferir um destino público seguro próximo do contexto anterior, quando isso for suportado, ou usar a saída configurada como fallback. Não aceitar coordenadas arbitrárias da NUI.

Se não houver espaço, aguardar por um intervalo limitado ou testar outros pontos permitidos. Se a preparação falhar, manter/reconstruir uma oficina utilizável e permitir tentar novamente. Não concluir a transição com tela preta, ped congelado ou carro inválido.

### 15.3 Entidades e repetição

Separar criar um registro salvo de spawnar sua entidade. Clicar em Jogar não cria outro registro na garagem. Pedidos repetidos, timeout e reconexão não podem acumular veículos públicos.

Definir uma política de veículo ativo por jogador compatível com o freeroam. Para esta experiência, usar um único veículo ativo gerenciado por esse fluxo e substituir/remover o anterior apenas com validação de propriedade e ocupação. Não apagar veículos que não pertencem à sessão gerenciada.

Limpeza deve ser idempotente e cobrir saída normal, cancelamento, desconexão, restart/stop de recurso e erro de carregamento. Veículos de gameplay relevantes devem seguir a autoridade de servidor já definida no projeto. A posição da câmera continua local.

## 16. Dados e contratos sugeridos

### 16.1 Modelo lógico

| Registro | Dados essenciais |
| --- | --- |
| Perfil | ID interno, progresso inicial, seleção atual e revisões. |
| Aparência | Dono, versão de schema, modelo e propriedades compatíveis, revisão. |
| Veículo salvo | ID próprio, dono, modelo permitido, nome, propriedades versionadas, revisão e datas. |
| Preferências | Câmera ligada/desligada, opções suportadas de interface/áudio e versão. |
| Sessão temporária | Dono, fase, token, contexto de retorno e entidades/reservas administradas. |

Dados de identidade, progresso, aparência e garagem precisam sobreviver à reconexão e reinício do servidor. Reutilizar o armazenamento persistente existente. Preferências cosméticas locais e de câmera podem usar KVP local versionado; isso não substitui a persistência autoritativa da garagem e personagem.

Um schema lógico ilustrativo seria:

```json
{
  "onboarding": {
    "characterCreationCompleted": true,
    "initialVehicleSelectionCompleted": true
  },
  "selectedSavedVehicleId": "saved-vehicle-id",
  "revision": 7
}
```

### 16.2 Operações de domínio

Separar operações de carregar perfil, salvar aparência, confirmar primeiro carro, adicionar/duplicar/excluir salvo, selecionar, salvar personalização e entrar/sair da oficina. São responsabilidades, não nomes obrigatórios de eventos.

Nos pedidos de mutação, usar identificação de operação para idempotência quando necessária, versão esperada do registro e token de sessão quando houver uma sessão contextual. O servidor obtém a identidade do solicitante pelo canal autenticado e não pelo ID de dono enviado pela NUI.

Responder de forma estruturada com sucesso/erro, estado confirmado e revisão nova. Conflitos devem permitir recarregar o estado confirmado sem sobrescrever silenciosamente mudanças mais recentes. Não introduzir um sistema amplo de transações de inventário para resolver operações pequenas de garagem.

### 16.3 Validações e limites

- Propriedade de qualquer registro salvo.
- Modelos presentes no catálogo permitido.
- Valores e combinações válidos, tamanho de strings e payloads, limites numéricos e valores finitos.
- Etapa atual do fluxo e sessão válida.
- Taxa de pedidos e duplicação de callbacks/cliques.
- Quantidade de criações e permissões operacionais configuradas.
- Entidade ativa e destino de spawn permitidos.

O servidor valida significado, permissões e dados persistidos. A detecção visual de capacidades no cliente pode auxiliar a UI, mas não é uma autorização irrestrita para gravar qualquer propriedade ou executar eventos de spawn.

## 17. Arquitetura sugerida

Manter os domínios separados, com integração simples:

| Responsabilidade | Conteúdo |
| --- | --- |
| Perfil/onboarding | Identidade, progresso e retomada. |
| Personagem | Aparência, presets, validação e aplicação. |
| Garagem/veículos | Catálogo, configurações salvas e ciclo de entidade ativa. |
| Oficina | Sessão de apresentação, cena e transições para o mundo. |
| Interface | Navegação, rascunhos, preferências e callbacks. |
| Coordenação de câmera | Posse e suspensão entre contextos. |
| Drivecam | Algoritmo local do Anexo A. |

Podem ser módulos dentro dos recursos existentes. Não criar um resource para cada linha sem necessidade. Nomes como `mx-garage`, `mx-character`, `mx-workshop` e `mx-drivecam` são apenas sugestões, sujeitas às convenções reais.

Não integrar persistência diretamente aos componentes visuais. Não permitir que o frontend seja a fonte autoritativa do progresso. Não enviar transformações de câmera por rede nem reconstruir toda a cena a cada render da NUI.

## 18. Estados de interface e falhas

Definir estados explícitos para carregamento, edição, salvamento, preparação de saída, recuperação e encerramento. Uma operação assíncrona de seleção deve carregar um identificador de geração/contexto para que uma resposta antiga não substitua a escolha mais recente.

| Falha | Comportamento esperado |
| --- | --- |
| Erro ao carregar perfil | Tentar novamente sem criar dados novos por engano. |
| Erro ao salvar aparência/configuração | Manter rascunho e permitir retry. |
| Modelo indisponível | Avisar e oferecer outra seleção, preservando o salvo. |
| Catálogo vazio | Mostrar erro de configuração recuperável; não travar a etapa. |
| Todos os spawns ocupados | Espera limitada/fallback e retorno utilizável à oficina. |
| Resposta antiga após troca de tela | Descartar efeito visual fora do contexto atual. |
| Resource da câmera encerra | Devolver visão sem destruir câmera de outro sistema. |
| Resource da oficina encerra | Liberar foco/controles e executar recuperação segura suportada. |
| Desconexão durante onboarding | Retomar da última etapa persistida. |
| Confirmação perdida após gravação | Retry idempotente recupera resultado, sem duplicar. |

Registrar os erros com contexto suficiente para diagnóstico, sem logs por quadro. Não mostrar informações internas ou credenciais na NUI.

## 19. Plano incremental de implementação

### Etapa 1 — Inspeção, estados e persistência

- Mapear recursos, assets e fluxo de spawn existentes.
- Implementar schemas/migrações e regras de retomada.
- Integrar identidade e armazenamento durável.
- Definir contratos de câmera, sessão e mutações.

**Aceite:** diferentes estados persistidos conduzem à etapa correta; falhas de carga não recriam o perfil.

### Etapa 2 — Personagem único

- Implementar presets, editor, prévia e confirmação.
- Persistir aparência e progresso com segurança.
- Reaplicar na reconexão e no respawn.

**Aceite:** criar uma vez, retomar após desconexão e editar depois sem criar outra identidade.

### Etapa 3 — Catálogo, primeiro carro e garagem

- Implementar prévia e salvamento gratuito.
- Adicionar seleção, nome, duplicação, exclusão e estado vazio.
- Tratar modelos removidos e operações repetidas.

**Aceite:** primeiro carro comum, várias versões do mesmo modelo e seleção persistente correta.

### Etapa 4 — Oficina e Jogar

- Preparar cena, enquadramento geral e personagem.
- Implementar menu principal e transição segura para gameplay.
- Implementar retorno voluntário à oficina.
- Limpar sessões, prévias e reservas sem duplicar veículos.

**Aceite:** entrar no servidor, ver oficina, clicar em Jogar e sair dirigindo o carro correto.

### Etapa 5 — Personalização e acabamento visual

- Implementar categorias reais, rascunho e salvar/cancelar.
- Integrar câmeras contextuais de carro e personagem.
- Aplicar identidade visual, sons e transições.
- Validar teclado, controle, proporções de tela e redução de movimento.

**Aceite:** edição integrada ao mundo 3D, sem categorias fictícias e com cancelamento fiel.

### Etapa 6 — Drivecam opcional

- Executar as etapas técnicas do Anexo A.
- Integrar habilitação às Preferências e ao controle de posse.
- Verificar suspensão e retomada em oficina, morte, respawn e outros contextos existentes.

**Aceite:** original e personalizada coexistem; oficina nunca disputa a visão com condução.

### Etapa 7 — Robustez e entrega

- Executar verificações automatizáveis relevantes.
- Validar cenários reais no FiveM quando houver acesso.
- Documentar instalação, parâmetros, limitações, decisões e pendências de calibração.

Não declarar etapa visual concluída somente porque o frontend compilou. As etapas representam dependências e pontos de validação, não uma estimativa fechada de prazo.

## 20. Verificação e critérios de aceitação

### 20.1 Verificações automatizáveis

Priorizar testes de lógica e integração com valor real:

- Roteamento de primeiro acesso, progresso parcial e contas existentes.
- Atomicidade/idempotência das conclusões de etapa.
- Perda de resposta depois de salvar sem duplicar carro.
- Propriedade e validação de pedidos de mutação.
- Concorrência entre seleção/exclusão e operações com revisão antiga.
- Exclusão do selecionado e do último veículo.
- Separação entre rascunho, cancelamento e estado confirmado.
- Descarte de respostas antigas e liberação de múltiplos motivos de suspensão.
- Testes matemáticos e de ciclo de vida especificados no Anexo A.

Reutilizar a infraestrutura disponível. Não criar testes que apenas repitam constantes de UI ou copiem a implementação. Compilação, typecheck e lint devem ser executados conforme os scripts reais do projeto.

### 20.2 Matriz de teste no FiveM

| Cenário | Resultado esperado |
| --- | --- |
| Conta nova | Criador → primeiro carro → oficina, na ordem definida. |
| Desconectar no criador antes de salvar | Voltar à criação sem flag concluída. |
| Desconectar após salvar personagem | Retomar na escolha do carro. |
| Desconectar após confirmar primeiro carro | Próximo acesso abre a oficina com o salvo. |
| Reconectar com perfil completo | Mesma aparência e último carro selecionado. |
| Editar personagem e cancelar | Aparência anterior restaurada integralmente. |
| Editar personagem e salvar | Persistência e reaplicação após respawn/reconexão. |
| Editar várias categorias do carro | Rascunho preservado entre categorias. |
| Cancelar edição de carro | Todas as alterações de prévia revertidas. |
| Salvar edição de carro | Mesmas propriedades no veículo de gameplay e na reconexão. |
| Duplicar modelo salvo | Duas criações independentes com IDs diferentes. |
| Excluir carro inicial | Operação permitida, sem reiniciar onboarding. |
| Excluir selecionado | Outro salvo válido selecionado e exibido. |
| Excluir último carro | Oficina vazia com escolha acessível; sem resurrectar o excluído. |
| Add-on removido | Registro preservado e indisponibilidade compreensível. |
| Trocar rapidamente entre carros | Última escolha prevalece, sem prévias vazando. |
| Dois jogadores no mesmo momento | Cenas privadas sem sobreposição; saídas sem colisão de spawn. |
| Clique repetido em Jogar | Uma transição e um veículo ativo gerenciado. |
| Falha durante saída | Oficina recuperável, controles e foco coerentes. |
| Retornar à oficina e sair novamente | Sem duplicar entidades ou perder configuração. |
| Retorno com passageiro | Sem transportar terceiro ou apagar seu contexto silenciosamente. |
| Drivecam ligada ao abrir oficina | Suspensa durante a oficina; retomada somente se elegível. |
| Câmera original selecionada | Continua original após a saída. |
| Restart/stop de recurso em tela de edição | Recuperação sem câmera presa, cursor ou invencibilidade residual. |
| Compacto, esportivo e carro grande | Enquadramentos adequados e sem clipping relevante. |
| Teclado/mouse e controle | Navegação e ações principais completas. |
| 16:9, ultrawide e resolução menor | Texto legível e carro/personagem sem oclusão indevida. |
| Sessões repetidas de oficina | Sem crescimento progressivo de handles, entidades ou callbacks. |

Executar também a matriz de condução do Anexo A, que cobre drift, colisão, ré, saltos, capotamento e variação de FPS.

### 20.3 Definição de pronto

- [ ] Um único personagem persistente e editor reaberto pela oficina.
- [ ] Presets iniciais coerentes e categorias suportadas funcionando.
- [ ] Primeiro carro gratuito e salvo antes de concluir a etapa.
- [ ] Retomada correta em qualquer progresso parcial.
- [ ] Oficina padrão em todos os acessos concluídos.
- [ ] Personagem e veículo corretos na apresentação 3D.
- [ ] Catálogo separado da coleção de criações.
- [ ] Seleção, nome, duplicação, exclusão e garagem vazia funcionando.
- [ ] Personalização com prévia e confirmação/cancelamento confiáveis.
- [ ] Jogar coloca o jogador fora da oficina dirigindo o carro exibido.
- [ ] Retorno à oficina disponível e seguro.
- [ ] Sem compra de veículos, multicharacter ou alterações de handling introduzidas.
- [ ] Câmeras contextuais integradas à UI e à posse de visão.
- [ ] Drivecam opcional, preferência persistida e original disponível.
- [ ] Autoridade, validação, concorrência e idempotência verificadas.
- [ ] Limpeza de entidades e estados temporários implementada.
- [ ] Build e verificações relevantes executados.
- [ ] Cenários jogados registrados; o que não foi testado está marcado como pendente.

## 21. Fora do escopo

- Multicharacter, economia, concessionária e compra de carros.
- Balanceamento, handling, calibração de drift e sensação de condução.
- Aprimoramento do câmbio manual.
- Modos de corrida, matchmaking, ranking ou progressão adicional.
- Editor livre de adesivos comparável ao dos jogos comerciais; usar liveries suportadas nesta entrega.
- Construção de MLO do zero ou aquisição implícita de assets pagos.
- Oficina social, visitas e personalização compartilhada.
- Replay, drone, modo foto completo e editor cinematográfico.
- Efeitos gráficos estilizados de condução equivalentes aos de Unbound.

Manter a arquitetura compatível com expansões, sem implementar antecipadamente esses sistemas.

## 22. Entrega esperada do agente

1. Código integrado ao repositório real, com relação dos arquivos alterados.
2. Migrações e formatos persistidos versionados, sem perda de dados existentes.
3. Configuração de catálogo, presets, cena, câmeras e pontos de saída.
4. Interface funcional, com estados de carregamento, vazio, erro e edição pendente.
5. Documentação de instalação, build, controles, persistência e integrações.
6. Registro de testes executados e resultados, separando verificação de código de validação jogando.
7. Assets/dependências necessários claramente identificados.
8. Limitações concretas e parâmetros que ainda exigem calibração visual.

Se não puder executar FiveM, entregar implementação e testes de lógica disponíveis, informar a limitação e fornecer roteiro objetivo para validação pelo usuário. Não declarar conforto de câmera, iluminação ou compatibilidade de roupas como testados sem execução real.

## 23. Referências técnicas e precedência

- FiveM — NUI: https://docs.fivem.net/docs/scripting-manual/nui-development/
- FiveM — Fullscreen NUI: https://docs.fivem.net/docs/scripting-manual/nui-development/full-screen-nui/
- FiveM — OneSync e routing buckets: https://docs.fivem.net/docs/scripting-reference/onesync/
- FiveM — Native Reference: https://docs.fivem.net/natives/
- Imagens fornecidas: `image(6).png` e `image(7).png`.

Consultar documentação atual e comportamento real do projeto ao implementar assinaturas, capacidades e streaming. As escolhas arquiteturais deste plano são propostas de engenharia; não comprovam uma reprodução do funcionamento interno de NFS.

O Anexo A incorpora integralmente o plano técnico de câmera fornecido pelo usuário para que este documento seja suficiente como instrução textual única. Em decisões de experiência e integração de interface, as seções 1–23 prevalecem. Em algoritmo, colisão, entrada e robustez da drivecam, preservar os requisitos detalhados do anexo. A ampliação de NUI da seção 12 é intencional; não altera a escolha de manter a drivecam opcional e desligada por padrão.

---

## Anexo A — Especificação completa da câmera de corrida e drift

Conteúdo do documento fornecido `plano-camera-corrida-drift-fivem(1).md`, preservado abaixo, com os níveis de título ajustados para inclusão neste plano.

### Plano de implementação — Câmera de corrida e drift para FiveM

**Data:** 16/10/2026  
**Tipo:** especificação para implementação por agente de IA  
**Nome sugerido do recurso:** `mx-drivecam`, sujeito às convenções do repositório  
**Escopo inicial:** câmera externa para o motorista de automóveis

#### 1. Instrução para o agente

Implemente um modo opcional de câmera externa para condução no FiveM, com acompanhamento suave e previsível durante corrida, condução livre e drift. Leia este documento inteiro, inspecione o repositório e adapte a solução à arquitetura existente antes de editar arquivos.

O resultado deve ser uma funcionalidade utilizável, com configuração, integração, tratamento de estados especiais e documentação. Não entregue apenas uma câmera posicionada atrás do carro ou uma demonstração que funciona somente em uma reta.

Use uma implementação incremental. Mantenha a câmera original disponível e permita desativar o recurso. Não altere handling, aderência, potência, direção, suspensão, câmbio, física do veículo ou animações de condução para produzir efeitos de câmera.

As fórmulas e os valores deste documento são uma proposta de engenharia e pontos de partida para calibração. Não constituem uma reprodução do código de Forza, CarX ou Need for Speed. A semelhança visual e o conforto precisam ser avaliados dentro do jogo.

#### 2. O que queremos alcançar

Queremos que dirigir tenha um enquadramento semelhante ao encontrado em jogos de corrida: o veículo permanece legível, a estrada à frente continua visível e a câmera responde com suavidade a curvas e derrapagens.

Durante um drift, a câmera deve considerar tanto a direção para a qual a frente do carro aponta quanto a direção real de deslocamento. Isso permite ver parte da lateral do carro e entender sua trajetória, sem obrigar a câmera a ficar rigidamente alinhada à carroceria.

O comportamento deve priorizar:

1. Visibilidade do caminho à frente e leitura da posição do carro.
2. Transições contínuas ao iniciar, sustentar, inverter e encerrar uma derrapagem.
3. Horizonte estável, com pouca influência dos balanços da suspensão.
4. Controle manual de visão por mouse e controle.
5. Proteção contra atravessar paredes, chão e obstáculos.
6. Comportamento consistente em diferentes taxas de quadros.
7. Integração segura com outros sistemas que usam câmera.

Não é necessário implementar uma câmera cinematográfica para gravação, drone, replay, perseguição de outro jogador ou edição de cenas.

#### 3. Escopo e decisões iniciais

##### Obrigatório na primeira entrega

- Recurso local no cliente, sem sincronização de posições de câmera entre jogadores.
- Ativação opcional pelo jogador, com comando e tecla remapeável.
- Acompanhamento de orientação e trajetória com influência configurável de drift.
- Suavização baseada no tempo decorrido, separada por componente.
- Ponto de mira com antecipação limitada.
- Horizonte predominantemente estável.
- Correção de colisões.
- Olhar ao redor, olhar para trás e recentralização suave.
- Preferência local persistente e configuração validada.
- Tratamento de baixa velocidade, ré, saltos, rodadas, capotamento, morte, troca de veículo e interrupção do recurso.
- Diagnóstico de desenvolvimento e instruções de teste.

##### Adiado ou opcional

- FOV variável por velocidade, configurável e desligado por padrão no primeiro ajuste.
- Efeitos de aceleração, frenagem, nitro e impactos.
- Tremores, motion blur e inclinação artística de horizonte.
- Presets individuais por modelo de veículo.
- Motocicletas, barcos, aeronaves e câmera em primeira pessoa.
- Integração visual sofisticada com menus ou NUI.

Não adicionar dependências de ESX, QBCore, vMenu, banco de dados ou NUI apenas para implementar a câmera. Reutilizar o que existir no projeto quando isso trouxer integração real.

#### 4. Inspeção obrigatória do repositório

Antes de implementar:

1. Ler as instruções locais, incluindo `AGENTS.md`, quando presente.
2. Identificar linguagem, organização de recursos, configuração, comandos e persistência já utilizados.
3. Localizar scripts que criam câmeras ou alteram visão, FOV, minimapa, controles ou foco de streaming.
4. Verificar menus de veículo, garagem, personalização, modo foto, espectador, respawn e telas de seleção.
5. Verificar como o projeto trata foco de NUI e prioridades de entrada.
6. Identificar os veículos e controles contemplados pela primeira versão.
7. Reutilizar um gerenciador de câmera existente, se houver. Caso não exista, criar somente o mecanismo mínimo de posse necessário ao recurso.

Não presumir que o comportamento observado em outro servidor ou resource esteja presente neste repositório. Não sobrescrever implementações existentes sem entender sua função.

#### 5. Arquitetura sugerida

Separar responsabilidades, sem transformar a funcionalidade em um framework geral.

| Componente | Responsabilidade |
| --- | --- |
| Ciclo de vida e integração | Elegibilidade, ativação, suspensão, retomada, limpeza e posse da câmera. |
| Leitura do veículo | Posição, base local, velocidade, dimensões e informações de contato/orientação. |
| Matemática e política de acompanhamento | Derrapagem, direção de referência, enquadramento e limites. |
| Suavização | Estado temporal de ângulos, distância, altura, mira e entrada manual. |
| Colisão | Consultas, validação de resultados e restrição da posição final. |
| Entrada e preferências | Teclas, mouse, controle, recentralização e persistência local. |
| Diagnóstico | Telemetria e ajuste de desenvolvimento, desativados por padrão. |

Estrutura ilustrativa, se compatível com o projeto:

```text
mx-drivecam/
  fxmanifest.lua
  config.lua
  client/
    main.lua
    camera.lua
    vehicle.lua
    math.lua
    collision.lua
    input.lua
    preferences.lua
    debug.lua
  README.md
```

Os nomes e a quantidade de arquivos não são requisitos. Evitar arquivos artificiais com poucas linhas e dependências circulares. Não criar um script de servidor sem uma necessidade concreta do projeto.

#### 6. Dados e convenções matemáticas

##### 6.1 Dados de entrada

Obter somente os dados necessários do veículo local:

- Transformação atual e vetores de frente, direita e cima.
- Posição de referência e dimensões do modelo.
- Vetor de velocidade linear.
- Velocidade angular, apenas se utilizada por algum efeito.
- Velocidade longitudinal relativa ao carro.
- Condição de motorista, existência da entidade e estados relevantes.
- Tempo decorrido desde a atualização anterior, em segundos.

Utilizar as posições locais disponíveis no cliente. Não consultar o servidor para atualizar a câmera a cada quadro. Armazenar dimensões por modelo; evitar recalcular ou consultar dados estáticos em todas as atualizações.

##### 6.2 Convenções explícitas

- Distância e altura em metros.
- Velocidade interna em metros por segundo; converter km/h apenas na configuração e apresentação.
- Tempo em segundos; converter milissegundos somente nas interfaces que exigirem isso.
- Preferir radianos na matemática e graus nas chamadas que exigirem graus.
- Definir uma única função para normalizar diferenças angulares ao menor arco, por exemplo no intervalo `[-π, π)`.

Não misturar diretamente o heading do GTA com o resultado de `atan2` sem converter convenções. Uma abordagem segura é calcular os dois ângulos a partir dos vetores no mesmo sistema matemático.

Para as fórmulas abaixo, adotar `θ = atan2(y, x)` e `direcao(θ) = (cos θ, sin θ, 0)`. Converter a orientação final para a convenção das natives ao renderizar. Validar empiricamente o sinal com curvas e derrapagens para os dois lados.

#### 7. Receita de acompanhamento

##### 7.1 Construir uma referência estável

Definir uma âncora próxima ao centro visual do veículo, usando as dimensões do modelo e um pequeno deslocamento configurável. Evitar usar um ponto que reproduza desnecessariamente animações do personagem ou oscilações de um osso.

Usar a vertical do mundo como referência inicial de horizonte. Projetar o vetor de frente do veículo no plano horizontal antes de calcular o yaw. Se essa projeção ficar muito pequena, como em uma posição quase vertical, preservar a última orientação válida ou entrar no tratamento de capotamento.

A câmera deve ter posição própria. Não depender exclusivamente de uma câmera rigidamente anexada que herde toda a rotação da carroceria.

Separar a âncora física do veículo de uma eventual âncora visual filtrada. Se a câmera ainda reproduzir todas as pequenas oscilações verticais, filtrar moderadamente a altura da âncora visual, com limite de erro e resposta adequada a rampas. Suavizar apenas o offset de altura não filtra o movimento vertical da própria âncora. Manter a origem das consultas de colisão ligada a uma referência física atual e aplicar a restrição de segurança depois do filtro. Não introduzir atraso horizontal excessivo para corrigir um problema vertical.

##### 7.2 Calcular a direção do movimento e a derrapagem

Considerar inicialmente apenas a velocidade horizontal:

```text
vHorizontal = (velocidade.x, velocidade.y, 0)
velocidadeHorizontal = comprimento(vHorizontal)
yawCarro = atan2(frenteHorizontal.y, frenteHorizontal.x)
```

Quando a velocidade horizontal for suficiente:

```text
yawMovimento = atan2(vHorizontal.y, vHorizontal.x)
slip = menorDiferencaAngular(yawMovimento - yawCarro)
```

`slip` é o ângulo assinado entre a frente do carro e sua trajetória horizontal. Não normalizar um vetor quase nulo e não usar uma velocidade vertical de salto para decidir a orientação lateral.

Abaixo da faixa de velocidade configurada, reduzir progressivamente a influência da trajetória até zero. Preservar valores anteriores válidos quando necessário.

##### 7.3 Misturar as duas direções

Calcular um peso contínuo entre carroceria e trajetória:

```text
fatorVelocidade = smoothstep(velocidadeInicial, velocidadePlena, velocidadeHorizontal)
fatorDrift = smoothstep(anguloInicial, anguloPleno, abs(slip))
peso = fatorVelocidade * interpolar(pesoNormal, pesoDrift, fatorDrift)
correcao = limitar(peso * slip, -correcaoMaxima, +correcaoMaxima)
yawDesejado = yawCarro + correcao
```

Regras:

- `pesoNormal` pequeno mantém alguma leitura de trajetória em curvas comuns.
- `pesoDrift` maior permite visualizar melhor a lateral e o caminho durante derrapagem.
- `correcaoMaxima` impede rotações exageradas.
- `smoothstep` exige limites diferentes e ordenados; validar a configuração.
- Suavizar a resposta final e evitar múltiplos filtros redundantes que criem atraso excessivo.
- Tratar ré e rodada antes de aplicar a fórmula normal.

Se for necessário um estado discreto de drift, usar histerese: entrar acima de um limiar e sair abaixo de outro menor, com pequenas confirmações temporais. O estado não deve causar um salto no enquadramento; a influência visual continua gradual.

**Não basear o modo drift apenas na velocidade angular.** Um carro pode sustentar grande derrapagem com pouca rotação instantânea. Velocidade angular pode contribuir para antecipação limitada, depois que a base estiver correta.

##### 7.4 Definir posição e ponto de mira separadamente

Definir distância e altura relativas à âncora:

```text
posicaoDesejada = ancora
                 - direcao(yawAcompanhamento) * distancia
                 + verticalMundo * altura

pontoDeMira = ancora
             + direcao(yawReferenciaMira) * antecipacao
             + verticalMundo * ajusteVerticalMira
```

A direção usada na mira pode ter um peso e uma resposta diferentes da direção usada para posicionar a câmera. Começar compartilhando a mesma referência e separar somente se houver benefício perceptível.

A antecipação é uma distância limitada à frente do carro. Pode aumentar suavemente com a velocidade, mas deve preservar a visibilidade do veículo e da pista próxima. Não usar `posição + velocidade * tempo` sem limitar o deslocamento resultante.

Não prometer antecipação de curvas ainda não iniciadas: prever a geometria da pista exigiria dados adicionais de rota ou estrada, fora do escopo inicial.

##### 7.5 Adaptar enquadramento ao veículo

Usar dimensões do modelo para evitar que uma mesma distância coloque a câmera dentro de uma caminhonete ou excessivamente longe de um carro compacto.

- Calcular enquadramento base por dimensões, com limites e ajustes configuráveis.
- Evitar câmera dentro do veículo ou junto ao teto.
- Manter a maior parte útil do carro visível durante drift.
- Limitar antecipação para não retirar o veículo da tela.
- Recalcular a referência ao trocar de modelo.

A relação entre distância, altura, ponto de mira e FOV precisa ser ajustada em conjunto. A dimensão do modelo não substitui a validação visual.

#### 8. Suavização e estabilidade temporal

##### 8.1 Abordagem inicial recomendada

Usar amortecimento exponencial por meia-vida para a primeira versão. É uma base pequena, previsível e fácil de ajustar:

```text
alpha = 1 - 2 ^ (-dt / meiaVida)
novo = atual + (alvo - atual) * alpha
```

Para ângulos:

```text
novoAngulo = atualAngulo + menorDiferencaAngular(alvoAngulo - atualAngulo) * alpha
```

Se `meiaVida <= 0`, aplicar o alvo diretamente. Configuração inválida deve ser corrigida ou rejeitada com mensagem clara, sem produzir divisão por zero, infinito ou NaN.

Essa expressão é exata para aproximar um alvo constante durante o intervalo. Com um alvo em movimento e amostras diferentes por FPS, ainda haverá diferenças de discretização; validar se são pequenas e aceitáveis. Não afirmar equivalência absoluta da câmera inteira em qualquer FPS.

##### 8.2 O que suavizar

Manter estados separados para:

- Yaw de acompanhamento e pitch controlado.
- Distância e altura relativas.
- Antecipação e ajuste da mira.
- Entrada manual e recentralização.
- Retorno da distância após colisão.
- FOV, se ativado.

Evitar aplicar um filtro lento à posição absoluta no mundo e outro filtro lento à orientação sem necessidade. Isso pode acumular atraso e afastar demais a câmera do carro em alta velocidade. Priorizar uma órbita relativa à âncora atual, com componentes suavizados e limites de enquadramento.

##### 8.3 Alternativa de mola

Uma mola com amortecimento crítico pode substituir componentes específicos se melhorar a resposta. Nesse caso:

- Utilizar solução analítica ou integrador com estabilidade demonstrada.
- Guardar posição e velocidade do estado da mola.
- Tratar menor arco angular.
- Reinicializar estados após teleporte ou troca de entidade.
- Não adicionar oscilação perceptível por padrão.

Não implementar uma mola por Euler ingênuo com parâmetros arbitrários. Também não combinar mola e vários filtros adicionais para esconder um problema de origem.

##### 8.4 Quedas de FPS e descontinuidades

- Atualizar o posicionamento visual por quadro enquanto a câmera estiver ativa.
- Usar tempo decorrido real nas respostas temporais.
- Tratar pausas longas e retomadas como casos próprios; não acumular uma sequência enorme de correções.
- Detectar teleporte com limiar configurável compatível com velocidade e tempo decorrido.
- Ao reiniciar, descartar consultas de colisão antigas e limpar estados temporais.
- Testar travessia de `179°` para `-179°` sem giro completo.

#### 9. Horizonte, rampas, saltos e capotamento

A rotação lateral da carroceria não deve ser transferida integralmente à câmera.

Padrão desejado:

- Roll próximo de zero em relação à vertical do mundo.
- Pitch limitado e suavizado para manter carro e estrada no enquadramento.
- Sem mergulhar a mira por causa da velocidade vertical durante um salto.
- Pequenas irregularidades não devem gerar sacudidas grandes.
- Rampas e descidas devem continuar visíveis; horizonte estável não significa travar a altura ou impedir adaptação vertical.

Durante um salto, reduzir a influência de dados instáveis e preservar uma referência horizontal válida. Durante capotamento ou quando a base horizontal do carro degenerar, suspender a política normal de drift e usar uma referência estável limitada. Se não houver enquadramento seguro, retornar de forma controlada à câmera original.

A retomada deve usar confirmação temporal e limites diferentes de entrada e saída quando necessário, evitando alternância rápida entre estados.

#### 10. Colisão da câmera

##### 10.1 Estratégia

1. Calcular a posição desejada com os componentes relativos já suavizados.
2. Consultar obstáculos entre uma origem segura próxima à âncora e a posição candidata.
3. Utilizar volume com raio, como teste de cápsula ou esfera varrida, em vez de depender apenas de uma linha infinitamente fina.
4. Limitar a distância a uma posição válida antes do obstáculo, considerando a semântica do resultado e uma margem adicional.
5. Corrigir rapidamente a aproximação a obstáculos.
6. Recuperar a distância normal mais lentamente quando o espaço estiver livre.
7. Aplicar a restrição de segurança por último, depois de offsets e efeitos que possam mover a câmera.

Não presumir que criar uma câmera via native reproduz automaticamente toda a colisão da câmera original do GTA.

##### 10.2 Cuidados de implementação

- Ignorar o próprio veículo sem ignorar paredes, chão, props e outros veículos relevantes.
- Confirmar os flags e a semântica das natives na documentação atual e em testes locais.
- Se a native ignora apenas uma entidade, não presumir que veículo e motorista foram ambos excluídos. Resolver autoacertos pela origem, flags e filtragem adequadas.
- Diferenciar consulta pendente, concluída e inválida; resultado pendente não significa caminho livre.
- Evitar espera ocupada e consultas síncronas caras repetidas por quadro.
- Manter poucas consultas assíncronas em voo; armazenar origem, destino, raio, entidade e geração de ativação de cada consulta.
- Descartar resultados de outro veículo ou de uma ativação anterior. Descartar resultados com divergência espacial grande.
- Manter uma solução conservadora para resultados atrasados e aproximação rápida de obstáculos, sem supor que um resultado antigo garante segurança atual.
- Confirmar a restrição da posição final. Uma interpolação posterior não pode levar a câmera de volta para dentro da parede.
- Investigar plano próximo e cantos da imagem se o centro estiver fora do obstáculo, mas ainda houver clipping nas bordas.

Se a distância disponível for insuficiente para um enquadramento externo utilizável, usar um fallback explícito. Preferir retorno seguro à câmera original a uma câmera dentro da carroceria ou presa na parede. Evitar oscilações contínuas entre fallback e modo customizado.

#### 11. Entrada manual e preferências

##### 11.1 Ativação

- Comando sugerido: `/drivecam`.
- Tecla remapeável por `RegisterKeyMapping`, se adequado ao projeto.
- Primeira instalação com modo desligado; persistir a escolha do jogador depois da ativação.
- Ativar a câmera apenas em veículo elegível e com o jogador como motorista.
- Suspender ao sair do veículo; manter a preferência para uma próxima entrada elegível.
- Passageiros continuam na câmera original na primeira versão.

Usar `RegisterCommand` e APIs equivalentes conforme a linguagem e as convenções existentes. Não impor uma tecla já ocupada.

##### 11.2 Mouse e controle

- Suportar mouse e analógico com sensibilidade e zona morta apropriadas.
- Não multiplicar indiscriminadamente o delta do mouse por `dt`; verificar se a entrada representa deslocamento por quadro ou taxa. Para taxa angular de analógico, aplicar o tempo decorrido.
- Quando o jogador olhar ao redor, a entrada manual tem prioridade sobre o recentramento automático.
- Após inatividade configurável, retornar suavemente à referência de acompanhamento.
- Oferecer olhar para trás, mantendo o comportamento estável enquanto o comando estiver pressionado.
- Tratar o retorno de olhar para trás como transição, com menor arco e sem giro desnecessário.
- Respeitar pausa, foco de NUI, menus e prioridades de controles existentes.
- Não bloquear direção, acelerador ou freio para operar a câmera.

##### 11.3 Persistência

Preferir persistência local, como KVP do resource, para habilitação, preset e ajustes permitidos. Versionar o formato, validar valores carregados e aplicar defaults a campos ausentes ou inválidos.

O encerramento do resource não deve apagar a preferência. Suspender por garagem, morte ou modo foto não significa que o jogador desativou voluntariamente a funcionalidade.

#### 12. Estados e regras especiais

Separar estado de ciclo de vida de condição de condução, evitando uma enumeração com todas as combinações possíveis.

##### Ciclo de vida

| Estado | Comportamento |
| --- | --- |
| Desabilitado | Preferência desligada; nenhuma câmera própria ativa. |
| Aguardando elegibilidade | Preferência ligada, mas fora de um automóvel elegível ou sem ser motorista. |
| Ativo | Possui a câmera e executa o acompanhamento. |
| Suspenso | Outro sistema ou condição exige prioridade; não escreve na câmera concorrente. |
| Encerrando | Limpeza curta e idempotente; devolve controle quando ainda possui a câmera. |

##### Condições de condução

| Condição | Política inicial |
| --- | --- |
| Parado ou muito lento | Reduzir influência da trajetória; manter orientação estável. |
| Condução normal | Peso pequeno de trajetória e antecipação limitada. |
| Drift | Aumentar progressivamente a contribuição da trajetória, com limite angular. |
| Ré | Manter enquadramento externo estável atrás do carro; não girar automaticamente 180°. Olhar para trás permanece disponível. |
| Rodada ou movimento fortemente para trás | Reduzir a política normal de drift e preservar/recuperar referência estável. Não atravessar a descontinuidade angular de forma abrupta. |
| No ar | Evitar influência da velocidade vertical e de orientação instável. |
| Capotando | Limitar rotação e usar política estável ou fallback. |
| Teleporte ou troca de entidade | Reinicializar filtros e invalidar consultas antigas. |

Detectar ré pela componente longitudinal e confirmação temporal, sem usar apenas a diferença entre yaw do carro e da velocidade. Uma derrapagem lateral não deve ser confundida imediatamente com ré. O comportamento automático de câmera de ré pode ser estudado depois, como opção separada.

#### 13. Posse da câmera e compatibilidade

A câmera customizada precisa conviver com garagem, personalização, modo foto, espectador e respawn.

- Usar a coordenação existente do projeto, se disponível.
- Caso seja necessário um mecanismo mínimo, permitir suspensão por múltiplos motivos/identificadores; uma liberação não deve apagar a suspensão solicitada por outro sistema.
- Não criar, destruir ou reativar câmeras repetidamente para disputar prioridade.
- Não chamar limpeza global que destrua câmeras de outros recursos.
- Restaurar câmera de gameplay somente quando o recurso ainda for o proprietário da visão.
- Ao ceder posse, destruir seu próprio handle e interromper as escritas. Se outro sistema já assumiu, não executar uma chamada tardia que o desative.
- Ao retomar, verificar novamente elegibilidade e preferência; construir estado novo a partir da situação atual.
- Registrar integrações necessárias explicitamente; detectar uma câmera de outro script não substitui um protocolo de coordenação confiável.

A limpeza deve ser idempotente: chamar mais de uma vez não gera exceção nem altera uma câmera alheia.

Se o recurso modificar minimapa, FOV global, foco de streaming ou controles persistentes, registrar essa responsabilidade e restaurá-la sem interferir em outro proprietário. Para uma câmera próxima ao jogador, não deslocar o foco de streaming para um ponto distante sem uma razão demonstrada.

#### 14. Configuração inicial sugerida

**Os valores abaixo são hipóteses de calibração, não resultados de testes no servidor.** Centralizar em configuração e permitir ajuste em desenvolvimento. Não expor todos os parâmetros técnicos no menu comum do jogador.

| Parâmetro | Valor inicial ilustrativo | Observação |
| --- | --- | --- |
| Distância base | 6,0 m | Ajustar pelas dimensões do modelo e limitar a uma faixa segura. |
| Altura relativa à âncora | 1,5 m | Depende da definição da âncora. |
| FOV base | 65° | Ponto de partida; validar enquadramento e proporção de tela. |
| FOV dinâmico | Desligado | Primeiro acertar a câmera básica. |
| Início da influência de trajetória | 10 km/h | Converter para m/s internamente. |
| Influência de velocidade plena | 35 km/h | Transição gradual entre os dois valores. |
| Peso de trajetória normal | 0,15 | Faixa válida de 0 a 1. |
| Peso de trajetória em drift | 0,70 | Sujeito ao limite angular de correção. |
| Início da influência de drift | 12° | Para cálculo contínuo. |
| Influência de drift plena | 45° | Não confundir com detecção de rodada. |
| Correção angular máxima | 35° | Limite inicial relativo à carroceria no regime normal. |
| Meia-vida de yaw | 0,12 s | Regular conforme resposta e conforto. |
| Meia-vida de distância | 0,18 s | Não deve comprometer a correção de colisão. |
| Meia-vida de altura | 0,22 s | Equilibrar filtragem de piso e visibilidade em rampas. |
| Meia-vida de antecipação | 0,10 s | Limitar deslocamento total. |
| Antecipação | 0,5 a 2,5 m | Variável com velocidade, mantendo o carro visível. |
| Raio de colisão | 0,30 m | Validar contra clipping e espaços apertados. |
| Margem adicional de colisão | 0,10 m | Não descontar o raio duas vezes sem verificar a native. |
| Retorno após colisão | Meia-vida de 0,20 s | Aproximação do obstáculo continua rápida e restrita. |
| Atraso de recentralização | 1,0 s | Após cessar entrada manual. |
| Tremores e roll artístico | Desligados | Opcionais após validação da base. |

Definir também limites validados para pitch, sensibilidade, distância mínima/máxima, pausa longa, teleporte e elegibilidade. Se houver detector discreto de drift, um exemplo de histerese seria entrar acima de 12° e sair abaixo de 8°, com confirmação temporal ajustável. Esses limiares não substituem a redução por baixa velocidade nem a detecção de ré/rodada.

#### 15. Pipeline por atualização

Pseudocódigo de intenção; não é código pronto para executar:

```text
verificar preferência, elegibilidade e posse
se não puder operar:
    suspender ou limpar somente os recursos próprios
    encerrar a atualização

obter dt e ler veículo/entrada
tratar troca de entidade, teleporte e pausa longa
classificar condições de condução
calcular referência horizontal e influência de trajetória
aplicar política de ré, rodada, salto ou capotamento
combinar entrada manual e recentralização
atualizar componentes relativos com suavização temporal
construir posição candidata e ponto de mira
aplicar efeitos opcionais e seus limites, se habilitados
processar/agendar colisão e restringir a posição final
calcular orientação final com horizonte estável
atualizar a câmera existente
enviar diagnóstico somente se habilitado
```

Criar a câmera ao adquirir posse, não em todas as atualizações. Não acumular handles, threads, callbacks, key mappings ou consultas a cada ativação.

#### 16. Etapas de implementação

##### Etapa A — Integração e ciclo de vida

- Mapear conflitos e convenções do projeto.
- Criar recurso ou módulo apropriado.
- Implementar ativação, elegibilidade, preferência, suspensão e limpeza.
- Criar enquadramento externo básico com câmera original disponível.

**Saída esperada:** ativar, desativar, sair/entrar no carro e parar o resource sem prender a visão.

##### Etapa B — Acompanhamento e drift

- Implementar vetores, convenções angulares, trajetória e slip.
- Adicionar mistura gradual, limites e redução em baixa velocidade.
- Implementar suavização por tempo, mira e adaptação por dimensões.
- Manter horizonte estável e tratar ré/rodada.

**Saída esperada:** curvas e transições de drift legíveis para os dois lados, sem dependência perceptível de FPS.

##### Etapa C — Robustez de cenário e entrada

- Implementar colisão e recuperação de distância.
- Tratar rampas, saltos, capotamento, teleporte e troca de veículo.
- Adicionar mouse, controle, olhar para trás e recentralização.
- Integrar posse com outros sistemas de câmera.

**Saída esperada:** funcionamento consistente fora de um cenário ideal de pista aberta.

##### Etapa D — Calibração e entrega

- Adicionar ajuste de desenvolvimento, sem exigir uma NUI nova.
- Validar veículos e proporções de tela diferentes.
- Medir comportamento ativo/inativo.
- Documentar instalação, parâmetros, limitações, testes e integrações.
- Adicionar efeitos opcionais somente depois que a base passar nos critérios.

Não considerar nenhuma etapa visual validada apenas porque o código compila.

#### 17. Diagnóstico e desempenho

Quando habilitado em desenvolvimento, mostrar ou registrar de forma controlada:

- Estado do ciclo de vida e motivo de suspensão.
- Modelo e entidade atuais.
- Velocidade horizontal e longitudinal.
- Slip bruto, peso de trajetória e correção angular.
- Yaw desejado e aplicado.
- Distância solicitada e distância permitida pela colisão.
- Idade/validade da consulta de colisão.
- FOV e tempo de quadro.

Evitar logs por quadro no console. Atualizar a apresentação de diagnóstico em frequência menor e usar desenho auxiliar apenas quando solicitado.

Requisitos de desempenho:

- Inativo: sem consultas de colisão e sem atualização de câmera; evitar loop pesado de verificação.
- Ativo: um ciclo visual principal e número limitado de shape tests.
- Nenhum evento de rede por quadro.
- Dados estáticos em cache.
- Sem crescimento progressivo de memória, handles ou consultas após alternar o modo repetidamente.
- Medir com ferramentas do FiveM disponíveis no projeto e registrar o cenário. Não prometer um custo fixo de CPU antes de medir.

#### 18. Verificação e critérios de aceitação

##### 18.1 Testes de matemática e estado

Criar testes pequenos para lógica pura quando houver infraestrutura adequada, ou um harness simples independente das natives. Priorizar falhas que seriam difíceis de perceber somente por inspeção:

- Menor arco: `179° → -179°` resulta em aproximadamente `+2°` na convenção adotada, e não em uma volta completa.
- Menor arco nos dois sentidos e próximo de `±180°`.
- Velocidade quase zero não produz NaN nem orientação aleatória.
- Slip e correção simétricos para esquerda e direita.
- Pesos e limites permanecem nas faixas válidas.
- Suavização exponencial com alvo constante produz resultados equivalentes em tempos iguais com passos de 30, 60 e 144 Hz, dentro de tolerância numérica.
- Entrada manual impede recentramento enquanto estiver ativa.
- Múltiplos motivos de suspensão não são liberados por uma única retomada.
- Resultados de colisão de uma geração antiga são descartados.

Não criar testes que apenas repitam constantes ou copiem a implementação. Testes matemáticos não demonstram conforto nem qualidade visual.

##### 18.2 Matriz de validação dentro do jogo

| Cenário | Resultado esperado |
| --- | --- |
| Parado e manobras lentas | Sem tremor por ruído de velocidade; direção estável. |
| Reta em alta velocidade | Distância controlada; veículo não escapa do enquadramento. |
| Curvas comuns dos dois lados | Acompanhamento suave e simétrico. |
| Drift sustentado | Estrada e veículo legíveis; lateral do carro perceptível. |
| Transição de drift esquerda/direita | Sem corte, giro completo ou chicote excessivo. |
| Saída do drift | Retorno progressivo, sem encaixe repentino na traseira. |
| Ré e mudança frente/ré | Sem inversão automática brusca de 180°. |
| Rodada e recuperação | Sem oscilação descontrolada ou falha angular. |
| Lombadas e piso irregular | Horizonte e enquadramento estáveis dentro do possível. |
| Rampas e descidas | Estrada próxima visível, sem câmera enterrada. |
| Salto e pouso | Velocidade vertical não desvia lateralmente a câmera. |
| Capotamento | Sem rotação ilimitada ou valores inválidos. |
| Paredes, túneis, teto baixo e props | Correção de distância; sem clipping persistente. |
| Outro veículo próximo | Colisão conforme política definida, sem autoacerto contínuo no próprio carro. |
| Compacto, esportivo e caminhonete | Enquadramento adequado às dimensões. |
| Mouse e controle | Movimento manual utilizável, olhar para trás e retorno suave. |
| Menu ou NUI com foco | Sem movimento indevido ou bloqueio de controles de condução. |
| Garagem, personalização e modo foto | Posse cedida sem disputa e retomada apropriada. |
| Morte, respawn, saída e troca de carro | Visão devolvida e estado reinicializado. |
| Teleporte | Sem deslocamento longo da câmera atravessando o mapa. |
| Restart/stop do resource ativo | Sem câmera presa ou destruição de câmera alheia. |
| Alternância repetida | Sem vazamento de recursos ou threads duplicadas. |
| 30, 60 e 144 FPS, quando disponíveis | Resposta temporal semelhante, sem depender de um fator fixo por quadro. |
| 16:9 e ultrawide, quando disponíveis | Carro e estrada bem enquadrados. |

##### 18.3 Definição de pronto

- [ ] Instalação e integração documentadas.
- [ ] Modo opcional, tecla remapeável e preferência persistente funcionando.
- [ ] Acompanhamento e drift corretos para os dois lados.
- [ ] Horizonte, suavização e limites implementados.
- [ ] Ré, baixa velocidade e descontinuidades tratadas.
- [ ] Entrada manual e recentralização funcionando.
- [ ] Colisão implementada com tratamento de resultados pendentes e antigos.
- [ ] Posse de câmera e limpeza verificadas.
- [ ] Sem alterações de handling ou física.
- [ ] Diagnóstico desligado por padrão.
- [ ] Testes automatizáveis executados quando aplicáveis.
- [ ] Cenários jogados e resultados registrados, ou explicitamente marcados como pendentes.

**Se o agente não puder executar o FiveM, deve informar essa limitação na entrega.** Pode concluir a implementação e os testes de lógica disponíveis, mas não declarar como testados os cenários visuais. Entregar roteiro objetivo para a validação pelo usuário e destacar os parâmetros ainda não calibrados.

#### 19. O que o agente deve entregar

1. Implementação integrada às convenções reais do repositório.
2. Configuração comentada com unidades, limites e defaults.
3. Instruções de instalação e ativação.
4. Documentação de comandos, controles, preferências e suspensão/retomada.
5. Explicação curta do algoritmo escolhido e das decisões relevantes.
6. Registro dos testes executados, resultados e cenários pendentes.
7. Limitações conhecidas e ajustes sugeridos após teste jogando.
8. Relação de arquivos alterados e dependências adicionadas, se houver.

Evitar ampliar o escopo para física de drift, sistema de corridas, placares, interface completa de veículo ou gerenciamento geral do servidor.

#### 20. Referências técnicas

Estas fontes fundamentam técnicas e APIs. Não comprovam uma implementação idêntica em todos os jogos comerciais. Consultar as versões atuais antes de adotar assinaturas e detalhes das natives.

1. **Unity — Cinemachine Follow:** modos de referência, exclusão de pitch/roll e amortecimento por eixo.  
   https://docs.unity3d.com/Packages/com.unity.cinemachine@3.1/manual/CinemachineFollow.html

2. **Unity — Cinemachine Third Person Follow:** posição relativa, raio de câmera e respostas separadas de correção/retorno de colisão.  
   https://docs.unity3d.com/Packages/com.unity.cinemachine@3.1/manual/CinemachineThirdPersonFollow.html

3. **Ryan Juckett — Damped Springs:** motivação, derivação e código para molas amortecidas usadas em câmeras.  
   https://www.ryanjuckett.com/damped-springs/

4. **Daniel Holden — Spring-It-On: The Game Developer's Spring-Roll-Call:** amortecimento exponencial, meia-vida e modelos de mola.  
   https://theorangeduck.com/page/spring-roll-call

5. **GDC — Math for Game Programmers: Juicing Your Cameras With Math:** referência de apresentação sobre enquadramento, suavização e efeitos de câmera.  
   https://gdcvault.com/play/1023146/Math-for-Game-Programmers-Juicing

6. **C.H.A.S.E.R — camera_tunables.lua:** exemplo de parâmetros para câmera de condução no GTA, incluindo ângulo de drift, foco em estrada/carro, retorno e órbita. Não presumir compatibilidade direta desse mod com FiveM.  
   https://legacydmc.gitbook.io/chaser/the-config-folder/camera_tunables.lua

7. **Shrimpey — FiveM Enhanced Camera:** implementação pública de câmera customizada, útil para estudar integração e parâmetros. É um projeto antigo; não presumir que sua lógica ou compatibilidade resolvam todos os requisitos deste documento.  
   https://github.com/Shrimpey/FiveM-Enhanced-Camera

8. **CitizenFX — CreateCam e RenderScriptCams:** criação, ativação, transições e retorno de câmeras de script.  
   https://github.com/citizenfx/natives/blob/master/CAM/CreateCam.md  
   https://github.com/citizenfx/natives/blob/master/CAM/RenderScriptCams.md

9. **CitizenFX — GetEntityVelocity:** leitura do vetor de velocidade.  
   https://github.com/citizenfx/natives/blob/master/ENTITY/GetEntityVelocity.md

10. **CitizenFX — StartShapeTestCapsule e GetShapeTestResult:** consulta com volume e leitura do resultado; confirmar flags, estados e limitações.  
    https://github.com/citizenfx/natives/blob/master/SHAPETEST/StartShapeTestCapsule.md  
    https://docs.fivem.net/natives/?_0x3D87450E15D98694=

Estudar conceitos é permitido; incorporar código externo exige verificar licença, atribuição e compatibilidade. Não carregar Cinemachine ou componentes da Unity no FiveM: reproduzir as técnicas matemáticas necessárias com as APIs locais.
