# Ajustes de Sua sessão e Configurações — 2026-10-30

Origem: usuário pediu uniformidade dos botões, ESC fechando o lateral, abas sem foco de teclado/controle e com posição estável, destaques sem corte e remoção de botões permanentes de voltar/aplicar.

## Alterações

- Opções de Sua sessão têm altura fixa igual, com ou sem descrição: 72 px, ou 62 px em telas baixas. O painel usa âncoras superior/inferior fixas, sem centralização dependente da altura do conteúdo.
- Corrigida uma janela no polling de pausa: durante o cooldown após fechar o lateral, 199/200 deixavam de ser consumidos. Agora permanecem bloqueados nesse intervalo; somente abrir novamente depende do cooldown. Isso impede que a liberação de ESC seja entregue ao frontend nativo por esse caminho. Mapa nativo continua acessível pela opção explícita do lateral. O efeito físico ainda requer reteste FiveM.
- TabBar remove as abas da ordem de Tab (`tabIndex=-1`) e evita que o clique do mouse lhes transfira o foco. Foco inicial procura somente controles de conteúdo; Q/E, L1/R1 ou LB/RB continuam alternando abas. A aba ativa mantém indicação visual, sem outline/escala de foco.
- Configurações separa TabBar fixa e corpo com scroll. Gutter lateral/vertical comporta escala de seleção e outline. Focar uma opção traz a linha completa para a área visível, inclusive a última linha; scroll margin protege a borda. Trocar o conteúdo não muda a âncora das abas.
- Removidos botões permanentes Voltar, Voltar ao lobby, Voltar aos atalhos, Retomar sessão e Aplicar preferências nos contextos compartilhados. Retorno segue controles nativos e os modais mantêm suas ações próprias.
- Aplicar configurações é uma ação contextual da barra de controles: **Espaço / X (Xbox) / Quadrado (PlayStation)**, usando `INPUT_FRONTEND_X` (203). Aparece junto de Navegar, Selecionar e Voltar na aba Geral. Não é um novo atalho global nem altera controles da oficina.
- Alterações de preferências continuam aguardando aplicação/ACK do contrato existente, com estado pendente/sucesso/erro. Aplicação é protegida contra concorrência/repetição; controles ficam desabilitados durante o pedido e o foco retorna ao campo usado. A ação de aplicar não passa pela movimentação da seleção.

Não alterados dados SQL, atalhos salvos, manejo de veículos ou lógica de cena. Build NUI servido atualizado. Sem reinício de resources.

## Verificação

Build/TypeScript, `check`, `test:controls`, `test:pause`, `test:lobby` e `test:ui` aprovados. Browser em 1280×720, 1920×1080, 2560×1440 e 3440×1440. Cobertura inclui alturas iguais, ausência de foco em abas, âncora estável entre páginas, geometria do destaque ampliado dentro do gutter, foco no final da lista, ausência dos botões removidos, aplicar pelo teclado/mensagem nativa, restauração do foco e regressões de modais/garagem/pausa. Native doubles conferem bloqueio de ESC durante cooldown e ação 203 restrita ao contexto de configurações.

Capturas 1280×720 de Sua sessão e Configurações foram inspecionadas. Evidência atualizada: `docs/evidence/pause-hud-2026-10-30.json` e PNGs `pause-menu-*`, `pause-settings-*`, `native-navigation-*`.

Natives, input e persistência nos testes são simulados. Sem controle físico/FiveM, SQL ao vivo ou restart. Próximo passo: carregar mx-freeroam-menu atualizado e testar abrir/fechar por ESC, trocar abas, percorrer a lista até o fim e aplicar alterações pelo comando indicado na barra, nos três dispositivos.
