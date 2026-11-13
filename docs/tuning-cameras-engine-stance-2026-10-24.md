# Tunagem: câmeras, portas, motor e resposta da suspensão — 24/10/2026

Origem: relato do proprietário sobre câmeras distantes/altas, portas instantâneas, aceleração sem som e diâmetro/largura bloqueados. Projeto Drift em C:\FiveM\drift-server. Os presets principais aprovados do lobby e garagem permanecem configurados como enviados.

## Rodas e comparação com vStancer

Os logs tinham retorno nativo `1` e diferenças de leitura inferiores a 0.00000002. O código exigia `resultado == true`, portanto rejeitava uma aplicação bem-sucedida. Agora aceita `true` ou `1` e mantém obrigatória a leitura da dimensão com tolerância 0.001. Retorno de sucesso com geometria divergente continua passando pela recuperação opcional; valores rejeitados não são confirmados como salvos.

Consultado [WheelModScript.cs do vStancer](https://github.com/carmineos/fivem-vstancer/blob/master/VStancer.Client/Scripts/WheelModScript.cs), especialmente leitura dos defaults após instalação da roda, setters de tamanho/largura e reaplicação após tuning. Ele usa os mesmos natives visuais `SetVehicleWheelSize` e `SetVehicleWheelWidth`. A correção deste caso é o contrato de retorno no Lua, não a necessidade de instalar outro resource. Defaults relativos, recuperação de baseline zero e reaplicação visual existentes foram preservados. O código C# do vStancer não foi importado; sua implementação inclui controles independentes de colisores que não foram acrescentados nesta mudança visual.

## Resposta da aba Suspensão

Sliders agora fazem prévia local somente da stance, via `experience/stancePreview` → export `vehicles/PreviewStance`. Sem consulta de todas as peças ou ida e volta ao servidor a cada incremento. O caminho valida sessão do editor, identidade do preview, resource chamador, controle de rede e regras de valores existentes. Não altera propriedades salvas ou state bags de autoridade.

A fila permanece serializada e descarta intermediários; este caminho usa atraso zero. Debounce pendente de outra prévia pode ser interrompido por uma seleção nova, mas uma aplicação já em execução precisa terminar para preservar a ordem. O pacing de 180 ms das prévias cosméticas que passam pelo servidor permanece. Manter/restaurar ao sair da aba usa o fluxo existente de confirmação/ACK; nenhuma confirmação local vira gravação por si só.

## Câmeras de tunagem e órbita

- Mira por bones válidos de rodas, escapamento (alternativas exhaust_2–4), para-choques, spoiler, capô, motor (alternativa bonnet), portas e porta-malas. Bone ausente ou fora do volume plausível usa geometria do modelo.
- Vistas de rodas/escapamento têm distâncias mínimas menores (1.6/1.5 m antes da escala), com raio de enquadramento específico da peça, FOV 55°, margem e limites por modelo/aspect ratio. Colisão e exclusão do interior da carroceria continuam validadas.
- A composição de detalhe projeta o centro da peça a 38% da altura da tela, deixando espaço para a faixa inferior. A compensação altera a mira, não a distância da câmera.
- Órbita aceita elevação -0.25 a 0.95 rad, clearance 0.4 m e posição mínima relativa à origem do carro de +0.12 m. Mira em 30% da altura do modelo. Consultas de colisão, cancelamento ordenado e renderização suavizada permanecem.
- Ao ativar C, painéis de opções ficam visíveis e editáveis. H ou o botão Mostrar/Ocultar opções alterna a interface sem sair da órbita. Reativar a câmera livre sempre volta a mostrar as opções. Painéis ocultos manualmente não recebem comandos de ajuste/confirmar. C retorna à câmera de peça; teclado e controle mantêm o comando de alternância existente.

## Portas

O carro de apresentação é congelado. Abertura/fechamento agora percorrem ângulos intermediários com curva suave durante 650 ms usando [SetVehicleDoorControl](https://github.com/citizenfx/natives/blob/master/VEHICLE/SetVehicleDoorControl.md). Inverter no meio parte do ângulo observado. O estado manual continua prevalecendo sobre categorias, e aplicar peças recupera o estado com animação. Não há envio instantâneo do ângulo final ao pressionar Espaço.

## Motor e aceleração

Já existia um motorista real invisível no banco; o personagem visível fora do carro é um clone local. O código antigo misturava acelerador nativo com RPM e limitador calculados por script. Além disso, a cena desativava globalmente o controle do jogador e desabilitava os controles de aceleração que tentava injetar.

Durante a apresentação, o motorista tem controle habilitado e o loop libera somente acelerador/freio de mão entre os inputs bloqueados. [SetControlNormal](https://github.com/citizenfx/natives/blob/master/PAD/SetControlNormal.md) recebe o acelerador de W ou gatilho analógico; RPM, limitador, subida/queda de giro e áudio ficam com GTA. O script não chama mais SetVehicleCurrentRpm nessa apresentação. O estado de controle anterior é restaurado ao terminar. Veículo continua congelado e com freio de mão.

Eliminado o delay artificial após a confirmação nativa de motor ligado; durante a partida sem confirmação o acelerador permanece zero. Inatividade passa de 4 para 15 segundos. Soltar W/gatilho libera imediatamente, com heartbeat expirável e suspensão por modal/teclado preservados. Neon continua podendo manter energia sem aceleração.

## Verificação e uso

Build/typecheck, check estrutural e suíte completa aprovados. Testes usam adaptadores, sem cliente FiveM:

- 50 verificações de stance, incluindo os valores do log com retorno inteiro 1 e sucesso sem readback correspondente.
- Export rápido rejeita chamador/identidade/controle incorretos; LocalAction rejeita editor antigo e preview substituído.
- Câmeras: bone válido/fallback, aproximação limitada, projeção acima da interface, órbita baixa sem atravessar o piso de referência ou o carro; presets principais existentes continuam exercitados.
- Portas: posições intermediárias, fechamento, reversão, reaplicação de peças e limpeza.
- Motor: ausência de escrita de RPM, controles liberados, ACK nativo sem atraso extra, gatilho parcial, liberação, partida e restauração de controle.
- Fila: última seleção, cancelamento, atraso zero local e pacing cosmético preservado.

Browser com transportes simulados em 1280×720, 1920×1080, 2560×1440 e 3440×1440: fluxo da suspensão, prévia local, manter/restaurar, limitação opcional, câmera C/H, opções ocultas e controles existentes. Capturas em docs/evidence/free-camera-ui-*.png e stance-editor-*.png; a cena GTA não aparece nesses testes.

Não houve reinício, FiveM, banco real ou mudança de dados de jogador nesta entrega. Reinicie o perfil pelo txAdmin e reconecte para carregar os três resources e NUI. Conferir no jogo rodas modificadas (incluindo o conjunto do log), som/retorno natural de RPM, portas congeladas e bones de mods diferentes. Ler/escrever natives em testes não confirma som ou animação real.

Memória somente no export local do workspace; base Obsidian compartilhada fora da permissão de escrita.

## Ajuste após reteste do proprietário — 24/10/2026, 14:56

O proprietário confirmou que a câmera livre melhorou, mas a interface oculta impedia alterar opções. Corrigido o padrão: cada ativação mostra a interface e libera sua navegação normal; ocultação exige H ou clique explícito. Limites e movimento da câmera não foram alterados nesta correção. Build/typecheck/check aprovados; regressão existente de browser cobre opções visíveis ao abrir, H ocultar/mostrar e navegação de peças durante órbita. Não houve restart nem cliente FiveM nesta correção.

Verificação final dessa correção: browser completo aprovado em 1280×720, 1920×1080, 2560×1440 e 3440×1440, com abertura visível e H nos dois sentidos exercitados no bundle final.
