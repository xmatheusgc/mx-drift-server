# Interfaces Heat e ciclo de prévias — 16/10/2026

## Entrega

Alterações na base existente do txAdmin. Nenhuma migration ou remoção de dados foi necessária nesta entrega. Personagem único, onboarding, criações salvas, confirmação/cancelamento de aparência e personalização, serviços, viagens, social, atividades, progressão, HUD e permissões administrativas continuam integrados aos mesmos domínios. mx-gearbox e mx-turbo permanecem preservados e sem alterações.

A oficina agora usa navegação superior compacta, composição aberta para a cena 3D, identificação do carro no canto, seleção branca/preta, títulos condensados em itálico e ações grandes na faixa inferior. Catálogo e criações salvas são faixas horizontais distintas. O editor usa categorias inferiores com ícones próprios e uma lista contextual estreita. Câmeras acompanham rodas, frente, traseira, luzes, corpo e rosto. A mira reserva espaço para a interface à esquerda. Personagem e câmeras usam offsets relativos ao heading do carro.

O menu de sessão foi substituído por `SessionMenu.tsx`: uma lista lateral pequena, uma linha selecionada, pilha de submenus, memória de seleção por caminho e rolagem automática. Não usa inputs, botões clicáveis, cursor ou hover. Textos necessários (chat, busca, ID, motivo administrativo) usam o teclado nativo do FiveM, inclusive para controle. O áudio curto da interface é sintetizado localmente e respeita o volume persistido; não há áudio extraído de NFS.

## O que as imagens determinaram

- Referência Heat de entrada: carro/personagem dominam o centro; navegação pequena no alto; bloco primário branco e duas fileiras de ações no terço inferior.
- Referência Heat de personalização: categorias com símbolos na faixa inferior; seleção clara/invertida; informações restritas ao canto e opções contextuais.
- Referência de configurações: lista de linhas retas, contraste alto, rótulo à esquerda e valor à direita, sem dashboard de cartões.
- Tipografia: títulos altos, condensados, pesados e inclinados, com texto secundário estreito. Foi usada Barlow Condensed licenciada, não uma fonte proprietária extraída do jogo.
- Unbound complementa hierarquia, organização por abas e leitura rápida; não foram adicionados preços, estatísticas inventadas, efeitos gráficos de condução ou restrições comerciais.

As capturas anexadas pelo usuário foram a referência principal. As capturas de browser desta entrega mostram somente a NUI sobre fundo de teste. Não são screenshots de GTA e não comprovam a composição completa com carro/personagem. O cenário temporário é o ponto solicitado no mundo; não foi recriado o estúdio com reflexos/luzes de NFS nem importado um MLO.

## Causa da sobreposição

Na implementação anterior, `vehicles/garage.lua` executava CreateVehicleServerSetter no ponto de apresentação, aguardava `ClientCall(apply)` e só depois apagava a prévia anterior. Portanto, duas entidades podiam existir no mesmo ponto enquanto a segunda era aplicada. A candidata também só entrava em `previews[src]` depois desse await. Cancelamento, disconnect ou stop durante a preparação podiam perder a referência da candidata. Não existia uma geração contextual conferida depois dos awaits.

## Correção

1. `PreviewState` mantém token, epoch, bucket, geração e vida da sessão. Há uma operação de preparação por controlador; chamadas concorrentes são rejeitadas.
2. A UI publica imediatamente a intenção mais recente, mesmo quando uma requisição anterior está em andamento. `LatestPreview` serializa as cargas e descarta pedidos intermediários e respostas antigas. As demais chamadas NUI ao servidor também respeitam a trava já existente do core.
3. O evento de intenção somente invalida trabalho visual; não grava, cria entidades ou concede autorização. Ele exige source autenticado, token e epoch da sessão vigente.
4. O modelo novo é carregado antes de remover o antigo. Falha nessa carga mantém a apresentação anterior.
5. Antes de criar a substituta, o servidor remove a anterior e observa sua exclusão. O cliente confirma que aquele ID/net ID já não corresponde a uma entidade existente. Não há sleep arbitrário para encobrir a troca. Prazos limitam a espera por uma condição observável.
6. Toda candidata é registrada antes do próximo await. Geração, sessão, bucket e identidade são revalidados depois de carga, remoção e aplicação. Operações obsoletas removem suas candidatas e não publicam resultado.
7. Limpeza usa apenas o registro desse domínio, com entidade, network ID e UUID conferidos. Handles reutilizados por outra entidade não são apagados. Nunca é feita limpeza por distância.
8. Um journal privado registra os IDs gerenciados e o boot do core para recuperação após restart do resource. Referências pendentes de exclusão permanecem rastreadas; a confirmação do cliente não é confundida com desaparecimento apenas no servidor.
9. Entrar no gameplay remove e confirma a remoção da apresentação **antes** de mudar o bucket e criar o carro público. Falha de saída reconstrói a oficina com a criação confirmada. Falha de aplicação/cliente pode exigir Tentar novamente; ela não é anunciada como gravação bem-sucedida.

Registro salvo continua sendo uma criação SQL. Prévia é uma entidade privada transitória. Carro ativo continua no gerenciador de gameplay. Trocar uma prévia não cria registros nem chama spawn público.

## Coordenadas e controles

Arquivo central: `resources/[mx]/mx-freeroam-experience/config.lua`.

| Configuração | Valor atual |
| --- | --- |
| presentation | x=178.62, y=-3088.07, z=5.0, h=300.0 |
| exit | x=178.62, y=-3088.07, z=5.0, h=300.0 |

São duas tabelas independentes. Altere-as separadamente no local definitivo. `offsets` controla personagem e enquadramento geral. A saída usa reserva exclusiva no domínio world; não depende de aceitar coordenadas da NUI ou de escolher um destino antigo perto do contexto anterior. Se estiver ocupada, conserva/reconstrói a oficina e permite tentar novamente. Colisão, carro aplicado e motorista são preparados antes da liberação.

| Tecla | Menu de freeroam |
| --- | --- |
| F1 / mxmenu | Abrir/fechar |
| ↑ / ↓ | Selecionar uma linha; repetição controlada ao segurar |
| ← / → | Alterar checkbox, enum ou valor numérico |
| Enter | Executar/abrir submenu |
| Backspace | Voltar; na raiz fecha |
| Esc | Recuar; na raiz fecha |
| F6 / mxworkshop | Retornar à oficina nas condições existentes |
| F7 / drivecam | Câmera original/personalizada |

F2 não concede mais cursor ao menu de freeroam. A oficina pode usar mouse e seus controles de edição. Esc/F1 na oficina recua pela camada atual, resolve rascunhos e, na raiz com personagem/carro válidos, solicita a mesma saída de Jogar. O primeiro acesso não pode ser pulado. O menu comum conserva os controles de gameplay; apenas os comandos de navegação/telefone necessários são consumidos. O teclado nativo suspende drivecam enquanto captura texto. Stop limpa foco e suspensão temporária.

## Referências públicas e licenças

| Fonte | Uso / decisão |
| --- | --- |
| [Sailesh Vaghela — NFS Heat](https://saileshvaghela.com/nfsheat) | Material do artista de UI: hierarquia e contraste. Referência visual; nenhuma arte copiada. |
| [Sailesh Vaghela — NFS Unbound](https://saileshvaghela.com/nfsunbound) | Leitura rápida e preservação da visão do mundo. Referência visual; nenhuma arte copiada. |
| [Creative Pixels — UX/garage Unbound](https://creative-pixels.de/project/nfsunbound) | Abas, organização da garagem e relação entre UI e perspectivas de câmera. Material protegido de EA/Criterion; não redistribuído. |
| [TomGrobbe/vMenu](https://github.com/TomGrobbe/vMenu) / [licença legacy](https://github.com/TomGrobbe/vMenu/blob/legacy/LICENSE.md) | Referência funcional. Licença customizada exige atribuição e restringe venda de código derivado; nenhum código foi incorporado. |
| [TomGrobbe/MenuAPI](https://github.com/TomGrobbe/MenuAPI) / [licença](https://github.com/TomGrobbe/MenuAPI/blob/main/LICENSE.md) | Referência técnica de menus FiveM. Repositório atual informa LGPL-3.0-or-later; nenhuma biblioteca/código foi incorporada. |
| [Google Fonts — Barlow Condensed](https://github.com/google/fonts/tree/main/ofl/barlowcondensed) | Único asset externo novo incorporado: dois arquivos de fonte e OFL.txt, licença SIL Open Font License 1.1. Servidos localmente e declarados no manifest. |

Foram pesquisadas recriações públicas de Heat/Unbound, inclusive no GitHub. Não foi encontrada uma recriação de garagem com fidelidade e adequação suficientes para ser adotada. Repositórios de HUD, mod injectors e launchers não foram tratados como implementação dessa interface. Não há dependência de vMenu, MenuAPI, frameworks RP ou assets extraídos dos jogos. Os SVGs foram desenhados para este projeto.

## Verificação

- Typecheck e build Vite.
- `npm run check`: regras estáticas existentes de fronteiras, manifests, dependências e exclusão de física. Não há ESLint configurado; não se declara uma execução inexistente de ESLint.
- `npm test`: 45 arquivos Lua, 93 verificações anteriores de regras/experiência/câmera, 26 verificações novas do controlador real de prévias com natives simuladas, e teste da fila TypeScript (última seleção/cancelamento).
- Browser/Playwright em 1280×720, 1920×1080, 2560×1440 e 3440×1440: teclado sem mouse, submenus, seleção restaurada, ajuste ←/→, rolagem quando necessária, confirmação de descarte e Esc. Oficina, catálogo e editor renderizados/inspecionados. Os dados são fixtures explicitamente limitadas ao contrato de UI; não validam SQL, carregamento de modelos ou entidades.
- Boot no FXServer 37175, porta isolada 30131, banco de teste; dez verificações reais de persistência pelos exports/MariaDB repetidas com sucesso.
- Nenhuma conexão de cliente FiveM. A tentativa de testar uma reserva usando source 0 confirmou que esse ID não é um jogador válido; o harness agora exige um source conectado e registra **pendente** quando não há cliente, sem simular sucesso da native.

Evidências em [ui.json](evidence/ui.json), [interface-rework.json](evidence/interface-rework.json), [runtime SQL](evidence/interface-runtime.json) e capturas `heat-*` / `session-keyboard-*`. O teste de rollback SQL produz intencionalmente uma falha de FK. Não é uma falha normal de produção.

## Validação FiveM pendente e ativação

Reinicie o servidor **completo pelo txAdmin** para aplicar esta atualização. Isso também elimina entidades transitórias sem registro já deixadas pela versão anterior; um restart isolado não permite identificar com segurança todas as sobras antigas. Não foi feita limpeza indiscriminada dessas entidades e a instância existente na porta 30120 não foi interrompida.

Validar: 30+ trocas alternadas rápidas; cancelar/voltar durante carga; falha de asset/owner; resposta tardia; enter/exit repetidos; dois jogadores saindo no mesmo ponto; ponto público ocupado; persistência das alterações confirmadas; desconexão e stop/restart de vehicles/experience/menu; câmeras de cada categoria; usuário a pé/motorista/passageiro; gamepad/teclado nativo, ausência de cursor e conflitos de input; qualidade visual sobre o GTA e proporções de carro/personagem. Inspeção administrativa mostra contagem de entidades por apresentação, protegida por mx.inspect.

Não foi executado o cliente FiveM nesta entrega. A correção foi exercitada por testes determinísticos do código e boot real, mas ausência de sobreposição, comportamento de streaming e conforto/enquadramento de câmera precisam ser observados no jogo.

## Arquivos e integração

UI: SessionMenu.tsx, Workshop.tsx, main.tsx, HeatIcon.tsx, ui-sound.ts, latest-preview.ts, api.ts, style.css e fontes locais. Runtime: vehicles/garage.lua, preview-state.lua, client.lua e manifest; experience/config.lua, client.lua e server.lua; world/server.lua; menu/client.lua e manifest; admin/server.lua (inspeção protegida); progression/server.lua (catálogo de títulos autorizados para a UI, sem mudar concessão). Build em menu/dist. Testes, documentação e dependencies.lock atualizados. Transporte adicional: NUI previewIntent emite mx:experience:previewIntent(token,intentUUID); preview exige o mesmo intent. keyboard e toggleDrivecam são callbacks locais; nenhum deles concede autoridade SQL.
