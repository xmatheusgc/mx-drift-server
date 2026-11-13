# Personagem: navegação por regiões e aparência

Data local: 2026-10-31. Origem: pedido e imagem de referência do usuário; implementação Codex na base ativa.

## Entrega

Abas da garagem: Meu carro, Showroom, Personagem. Ranking removido dessa navegação. Personagem abre uma faixa horizontal com Roupas & acessórios e Aparência; os nomes do usuário foram mantidos porque distinguem claramente vestuário de características físicas.

Ao entrar no vestuário, as abas da garagem e a faixa de entrada desaparecem. Cabeça, Tronco, Pernas e Pés são alvos rotulados com círculos ao lado do personagem. A posição é consultada localmente a partir de IDs de bones do ped atual e convertida em coordenadas de tela. Há limites de viewport e disposição de rótulos de reserva se a projeção falhar. A consulta não passa pelo servidor, é sequencial e só ocorre enquanto a seleção de regiões está visível.

Fluxo: região → tipo de peça → modelos. Uma única lista horizontal ocupa a faixa inferior a cada nível; a variação da peça fica no painel lateral quando disponível. Tipos incluem chapéus/óculos/brincos/máscaras, jaquetas/camisetas/braços e luvas/colares/mochilas/coletes/emblemas/relógios/pulseiras, calças e calçados. Capacidades do ped determinam a disponibilidade. A seleção pede prévia; confirmar o personagem persiste pelo contrato existente. ESC/B retorna um nível sem gravar.

Aparência possui abas Base, Cabelo e barba, Pele, Olhos, Nariz, Boca, Bochechas, Mandíbula e Corpo. Modelos/estilos/cores são seletores laterais. Traços, misturas e intensidades usam sliders de passo 0,01, com valor numérico editável e escala. Campo numérico confirma ao perder foco ou pressionar Enter, permitindo valores negativos sem interromper a digitação. A câmera usa rosto ou corpo e agora deriva a altura do enquadramento dos bones reais. Troca de modelo pede confirmação, inicialmente em Continuar editando.

## Decisões de UX

- Rótulos persistentes e áreas de clique com pelo menos 44 px de altura evitam depender de bolinhas pequenas ou hover.
- D-pad/setas percorrem regiões na ordem do corpo. As listas são horizontais e retornam passo a passo; as abas de aparência mantêm Q/E e o contrato nativo LB/RB/L1/R1.
- Um nível de carrossel por vez evita disputa entre várias listas. Título/caminho indicam região e tipo em edição.
- Modelos têm identificação numérica real; não foram inventadas miniaturas ou nomes de peças inexistentes. Catálogo visual de roupas continua sendo uma melhoria possível, fora desta entrega.
- GTA usa jaqueta, camiseta e braços independentes; o painel informa que precisam ser combinados para evitar sobreposições. Não foi inventada compatibilidade automática entre peças.
- Prévia é separada de confirmação. A fila é serializada e o salvamento espera a última prévia, inclusive se a edição ainda estiver no debounce. Falha da prévia impede persistência; descartar continua permitido e restaura o confirmado. Retry de confirmação reutiliza a operação existente.
- As mudanças de interface não resetam dados, atalhos, regras de ownership ou contratos de persistência.

## Referências consultadas

A imagem fornecida pelo usuário é a principal referência de seleção por regiões. O manual oficial de NFS Heat confirma a separação de edição de cabelo/roupas/calçados no contexto do personagem; o fluxo detalhado desta entrega é uma decisão local, não uma cópia comprovada dos controles internos do jogo.

- W3C, Slider Pattern: https://www.w3.org/WAI/ARIA/apg/patterns/slider/ — ajuste por setas, nomes e valores acessíveis.
- W3C, Developing a Keyboard Interface: https://www.w3.org/WAI/ARIA/apg/practices/keyboard-interface/ — ordem previsível e foco distinguível da seleção.
- Game Accessibility Guidelines: https://gameaccessibilityguidelines.com/ensure-that-all-areas-of-the-user-interface-can-be-accessed-using-the-same-input-method-as-the-gameplay/ — interface acessível pelo dispositivo usado no jogo.
- Manual oficial NFS Heat: https://eaassets-a.akamaihd.net/eahelp/manuals/nfs-heat-pc-ukanz.pdf
- Cfx, GET_PED_BONE_COORDS: https://github.com/citizenfx/natives/blob/master/PED/GetPedBoneCoords.md
- Cfx, GET_SCREEN_COORD_FROM_WORLD_COORD: https://github.com/citizenfx/natives/blob/master/GRAPHICS/GetScreenCoordFromWorldCoord.md

## Verificação

Build/TypeScript e check aprovados. test:controls aprovado. test:ui aprovado em quatro resoluções durante a implementação, com as expectativas da nova ordem das abas atualizadas; a limpeza posterior ficou restrita ao editor e à restauração do botão Voltar nas demais telas. test:character aprovado com o bundle final: adapters Lua do módulo real e browser em 1280×720, 1920×1080, 2560×1440 e 3440×1440. Cobertura: ordem das abas, dois acessos, regiões/sublistas/retorno, faixa com 140 modelos, atualização de texturas, passos de 0,01, isolamento DOM/nativo, salvamento imediato, falha de prévia, descarte após falha, confirmação de troca de modelo/cancelamento e retry com ID de operação preservado. Adapters exercitam ambos os modelos, valores assinados, remoção de props/overlays, capacidades, IDs de bones e visibilidade de projeção. O client Lua alterado também foi analisado sintaticamente.

Evidência: docs/evidence/character-ui-2026-10-31.json e character-{entry,regions,clothes,face}-RESOLUCAO.png. Inspecionadas capturas 1280×720 e regiões em 3440×1440. São fixtures de browser sem personagem 3D; não são imagens do FiveM.

## Arquivos principais e próximo passo

Fontes: development/ui/src/CharacterEditor.tsx, character.css e Workshop.tsx; resources/[mx]/mx-freeroam-experience/{character,client}.lua. Build servido em resources/[mx]/mx-freeroam-menu/dist. Runner novo: npm.cmd --prefix development run test:character (requer MX_CHROMIUM apontando para Chrome instalado neste ambiente).

Nenhum restart ou gravação SQL real executado. Carregar menu e experience atualizados em momento adequado e iniciar nova sessão da garagem. Validar no FiveM: posição/iluminação do corpo e rosto, projeção de cada marcador, roupa/textura nos dois modelos, retorno/cancelamento/confirmação/reconexão, gamepads físicos e correspondência entre peças do torso. A bateria geral Lua não foi declarada aprovada; a memória já registra uma divergência independente de FOV em orbit-client.lua:64.

## Revisão solicitada pelo usuário — 2026-10-31, 16:00 (São Paulo)

Esta revisão substitui o comportamento de conclusão, projeção contínua de bones e nove abas descritos na entrega inicial acima.

- Removido Concluir personagem. Roupas/acessórios e suas variações persistem ao equipar, após prévia válida. Salvar fica no rodapé como ação contextual: Espaço / X Xbox / Quadrado PS. Na aparência, salva e mantém a edição aberta. Ao sair com alterações, o modal oferece salvar, descartar e continuar editando.
- Persistência reaproveita a rota character, revisão e operação idempotente. ACK atualiza a base confirmada sem substituir uma seleção local mais recente. A fila serializa prévia e gravação; a API espaça gravações em 500 ms para respeitar o guard existente. Resultado incerto é repetido com a mesma operação; não é tratado como sucesso nem descartado silenciosamente.
- Marcadores usam a caixa estática do modelo (GetModelDimensions + projeção dos cantos), com distribuição proporcional pela altura e uma coluna à direita do personagem. Uma captura é feita após estabilizar a câmera; nova captura apenas ao redimensionar a viewport. Não há polling nem leitura de bones animados para os marcadores. Labels aparecem somente no foco e ficam à direita do círculo; área de interação mínima 44×46 px. Não foi exigido ajuste manual por personagem.
- Removidos os botões genéricos Voltar da oficina. Retorno permanece nos comandos; ações de destino, como Voltar para a garagem, são distintas. Regra explícita salva e verificada no AGENTS.md da raiz do workspace, para orientar próximas tarefas.
- Seletores laterais agora têm campo numérico (números exibidos de 1 a N; 0 significa Nenhum quando disponível) e ambos os sentidos dão volta entre primeiro/último. Campos aceitam digitação e confirmam ao sair do campo ou por Enter. Não abrir confirmação de troca de modelo ao apenas sair de um campo inalterado.
- Abas reduzidas a Genética, Traços faciais, Pele, Cabelo e barba, Corpo. Traços faciais tem seletor de região interna (olhos/sobrancelhas, nariz, boca, bochechas e mandíbula/queixo), sem novas abas superiores. Todos os vinte traços e os detalhes existentes continuam acessíveis.
- Diagnóstico confirmado do código anterior: Character.apply reexecutava blend/traços/overlays/todas as roupas/props a cada prévia e o client chamava placeCharacter, que limpa tarefas e reposiciona. Agora o módulo valida o documento inteiro antes de aplicar e altera somente os campos diferentes, com cache por ped/modelo. Revalidação idêntica do servidor não reaplica a aparência. placeCharacter fica condicionado à troca real de modelo nos fluxos de edição; entrada de cena e restauração explícita de gameplay mantêm reaplicação completa.

Verificação desta revisão: build/TypeScript, check, test:controls, test:character e test:ui aprovados. Browser em quatro resoluções verifica captura única/posições estáveis, labels no foco à direita, ausência dos botões removidos, autosave/variação, número digitado e wrap, cinco abas, precisão, Salvar sem sair, modal de saída, falha de prévia/descarte e retry idempotente. Adapters do módulo Lua real verificam ambos os modelos, bounds estáticos sem bones, ACK idêntico sem writes, alteração de uma peça ou traço sem reset global e rejeição do documento inválido sem aplicação parcial. Capturas character-fixed-regions e character-grouped-face em 1280×720 inspecionadas. Build final servido atualizado.

Fontes primárias para o posicionamento estático: https://github.com/citizenfx/natives/blob/master/MISC/GetModelDimensions.md e https://github.com/citizenfx/natives/blob/master/ENTITY/GetOffsetFromEntityInWorldCoords.md.

Limite: testes usam browser/natives/RPC simulados. O usuário confirmou por imagem que a versão anterior tinha marcadores deslocados e por relato que havia flicks. A correção atual ainda exige reteste visual no FiveM, incluindo respiração, enquadramento dos dois modelos, equipar e reconectar, navegação por controle físico e ausência de flicks. Não foi executado restart, SQL real ou alteração da câmera/física fora desses fluxos.
