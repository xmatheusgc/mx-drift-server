# Câmera livre da customização

Atualização de resposta, cancelamento e protocolo de entrada: [refinamento de 18/10/2026](refinements-camera-doors-2026-10-18.md). O relatório abaixo registra a primeira implementação.

## Comportamento

- C / Y / Triângulo alterna entre enquadramento da peça e câmera livre durante a customização. C também funciona com foco nos sliders e campos numéricos; campos de texto continuam recebendo caracteres normalmente.
- Esc / B / Círculo volta um nível no editor sem desligar a câmera livre. A câmera permanece ativa entre categorias, opções, cores e suspensão. Sair da customização desativa o modo e devolve a câmera ao enquadramento de destino.
- Ativação calcula yaw, inclinação e distância a partir da posição atual, em vez de impor inclinação fixa de 0,22 radianos. Se limites de segurança/FOV exigirem mudança, uma nova câmera interpola posição, orientação e FOV por 350 ms. A preferência de reduzir movimento continua respeitada. Validamos visada e trajeto antes da transição; uma cena ou câmera substituída durante a consulta não recebe uma ativação atrasada.

## Fluidez

O código anterior atualizava a câmera somente ao concluir a consulta de colisão, iniciando a consulta seguinte em outro frame. Assim, a atualização visual dependia da cadência das consultas. Além disso, cada evento de movimento do mouse gerava uma chamada NUI.

`orbit.lua` mantém destino aprovado por colisão e posição visual separados. A posição visual recebe amortecimento exponencial a cada frame, com resposta independente do FPS. As consultas assíncronas de visada e trajeto mantêm resultados concluídos em cache, e a próxima consulta pode começar no mesmo frame da conclusão. Resultado bloqueado ou expirado não aprova o novo destino. Passos angulares limitados e verificação do envelope do veículo evitam atalhos pela carroceria; orbit parado não aloca consultas continuamente.

`OrbitSurface.tsx` acumula deltas e envia no máximo um lote por animation frame. Limites por mensagem preservam o restante para o próximo frame, em vez de perder deslocamento de arrastes rápidos. O componente cancela lotes pendentes ao desmontar.

Configuração em `ExperienceConfig.orbit`: `response=14.0`, `transitionMs=350`, `queryTimeout=250`. Limites de zoom e inclinação existentes permanecem configuráveis.

## Verificação e limites

- Testes executam o controlador real com tempo e consultas de colisão simulados: movimento continua entre conclusões, resultados atrasados não são publicados antes de terminar, consultas assimétricas são lidas uma vez, bloqueio/timeout conservam destino aprovado e resposta matemática coincide a 30/60/144 FPS.
- Testes do `LocalAction` real verificam escopo de customização, transição nativa solicitada, preservação da câmera ao selecionar peças, limpeza ao sair e rejeição de ativação obsoleta. Adapters de câmera substituem os natives nesses testes.
- Browser exercita navegação por teclado e mensagens de controle, câmera persistente entre submenus, C com foco no slider, limpeza ao sair e agregação de 30 movimentos de mouse sem perder o deslocamento acumulado. Relatório por resolução em `docs/evidence/ui.json`.
- Build, typecheck, checks estáticos e testes locais não medem FPS real nem demonstram suavidade no motor do jogo.

Nenhum cliente FiveM foi executado. Validar no jogo a sensação de resposta com mouse/analógico, transições entre FOVs, limites de zoom, paredes/teto do ps-tuners e ausência de clipping em modelos com dimensões diferentes. As consultas continuam necessárias: perto de obstáculo, o avanço pode parar no último destino aprovado.
