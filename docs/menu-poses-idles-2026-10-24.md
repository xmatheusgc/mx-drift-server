# Posições dos menus, câmera baixa e idles — 24/10/2026

Origem: coordenadas enviadas pelo proprietário e esclarecimento de que a câmera deve ficar mais próxima e baixa, sem posição absoluta específica. Implementação em `resources/[mx]/mx-freeroam-experience`.

## Posições

| Contexto | Entidade | X | Y | Z | Heading |
| --- | --- | ---: | ---: | ---: | ---: |
| Lobby | Personagem | -950.165 | -3535.050 | 14.618 | 77.78 |
| Lobby | Veículo | -949.463 | -3532.688 | 13.967 | 116.28 |
| Garagem | Personagem | 133.303 | -3027.849 | 7.041 | 276.85 |
| Garagem | Veículo | 135.962 | -3030.353 | 6.396 | 0.11 |

`scene.ped` e `lobbyScene.ped` são posições explícitas, com `fixed=true`; o cliente não recalcula afastamento conforme o carro nem gira o heading para a câmera. Mantém confirmação de chão/colisão, mas ela não sobrescreve o Z fornecido. O clone visível da personalização conserva a mesma posição, sem derivá-la dos ossos dos pés animados. Isso respeita a composição solicitada; carros excepcionalmente grandes podem exigir rever o ponto fixo se houver interseção com o personagem.

Carros usam os pontos novos na criação da prévia; a acomodação nativa das rodas no chão já existente permanece. A saída para o mundo continua configurada separadamente, em `163.2, -3024.11, 6.05, 268.29`.

## Câmeras

Complemento posterior em 24/10/2026: adicionado editor em jogo pelo botão DEV · CÂMERA ou `mxcamedit`, com captura para enviar novas composições. Corrigido também override legado que ainda aplicava FOV 49 à câmera principal; o native agora usa o FOV 60 da cena, coerente com a projeção. Ver [camera-developer-2026-10-24.md](camera-developer-2026-10-24.md).

Câmera principal do lobby e da garagem: offsets iniciais relativos ao carro de 3.8 m à frente, 3.1 m à direita e 0.85 m acima da origem, com FOV de 60 graus. A mira fica entre carro/personagem. O ajuste usa a projeção dos limites do veículo e do personagem, recuando horizontalmente em incrementos de 0.1 m apenas para caber; preserva altura baixa. O tamanho real do carro e a proporção da tela entram no cálculo.

Os testes com carro de 2×4.6×1.4 m confirmam câmera mais próxima que a composição anterior nas quatro proporções testadas e enquadramento de ambos. As câmeras de peças, rosto, personagem e órbita continuam com seus comportamentos próprios. Não há imagem do enquadramento dentro do FiveM nesta entrega; a geometria não comprova ausência de obstruções do cenário. As verificações existentes de visibilidade/obstrução continuam ativas.

Ao trocar de cena, `personPoint` recebe imediatamente o ponto novo antes da câmera inicial; não pode usar a posição anterior de outra região do mapa. A animação só começa depois da colocação confirmada do ator.

## Variações de idle

`config.lua`, `ExperienceConfig.idles`: quatro candidatos masculinos e quatro femininos livres, mais uma pose feminina de parede reservada para cenas com apoio habilitado. Masculinos incluem corona male_c/male_d, heist e checkout_car male_c; femininos incluem corona, heist, braços cruzados e segurar braço. O `idle_a` isolado fornecido é um nome de clipe: cada entrada guarda seu par dict/clip.

O sexo é lido do ped real ou do clone visível, não do nome do jogador. Seleção aleatória evita repetição consecutiva no mesmo contexto, variando a cada 18–32 s. Loop com blend de 1.5 e translação bloqueada, sem extração de deslocamento ou reorientação final. O ator fica na posição/heading configurados.

Poses de parede exigem `idles.wall.lobby` ou `idles.wall.garage` verdadeiro e um ponto alinhado a apoio real. Ambas estão desligadas nos pontos livres atuais para evitar apoiar o corpo no vazio. Não há objetos extras ou paredes criadas para a animação.

`idle.lua` é opcional e não bloqueia o ACK da cena: carrega dicionário sem espera síncrona, dá até 2 s, confere duração do clipe e verifica reprodução após 500 ms. Falhas geram diagnóstico `[MX:IDLE]` e permitem outro candidato/pose neutra. Erro inesperado de native é isolado do loop principal, com pausa de 5 s antes de tentar novamente.

Nas telas de rosto/personagem e em modal de entrada, pausa o idle para não dificultar a edição. Ao personalizar o carro, anima o clone externo; não substitui tarefas do motorista invisível usado no áudio. Saída, troca de cena/modelo, reposicionamento e destruição do clone/resource limpam a animação/dicionários, respeitando identidade para não atuar num handle reutilizado.

As combinações corona/heist/braços foram conferidas no [código original do dpemotes](https://github.com/andristum/dpemotes/blob/master/Client/AnimationList.lua). A referência de [TaskPlayAnim](https://github.com/citizenfx/natives/blob/master/TASK/TaskPlayAnim.md) documenta flags e transições. As entradas de carmeet e demais clipes são também verificadas em runtime; disponibilidade e resultado visual no build do cliente permanecem sujeitos a teste FiveM. Não foi importado um pacote de emotes.

## Verificação e aplicação

`npm.cmd --prefix development test` e `run check` aprovados. A suíte nova tem 111 verificações de posições, projeção próxima/baixa em quatro proporções, sexo, não repetição, clone, suspensão, falha de streaming/clipe/native e limpeza. Outra regressão executa a função real de posicionamento do cliente, confirmando XYZ/heading após chão/colisão nos dois contextos. A integração da experiência confere os pontos novos dos veículos. Testes usam natives simulados; não são aceite de animação/colisão/visual real.

Não houve alteração de NUI ou necessidade de rebuild/browser nesta etapa. Sem restart, cliente FiveM, alteração de progresso/banco ou assets. Fazer reinício completo pelo txAdmin e reconectar. Conferir lobby e garagem com personagens masculino e feminino, alguns ciclos de idle, mudança de aparência, entrada/saída da personalização, veículo grande e retorno ao modo livre. `mxworkshopdebug` no F8 inclui ator, câmera e animação atual para diagnóstico.

Relatório/evidência: `docs/evidence/menu-poses-idles-2026-10-24.json`. Memória atualizada apenas no export do workspace; base compartilhada Obsidian fora das permissões de escrita.
