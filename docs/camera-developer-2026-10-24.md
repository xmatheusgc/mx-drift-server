# Editor de câmera em jogo — 24/10/2026

O proprietário confirmou que esta ferramenta pertence ao Drift, para as câmeras do lobby/garagem. O NativeCore aparecia em uma aba do IDE e foi somente consultado antes dessa confirmação; nenhum arquivo daquele projeto foi alterado.

## Como usar

1. Reinicie o servidor completo pelo txAdmin e reconecte para carregar Lua e NUI novos.
2. No lobby ou garagem, aguarde a cena ficar pronta e clique em **DEV · CÂMERA**, no topo. Alternativa: abra F8 e execute `mxcamedit` (sem barra). O comando novamente também encerra/restaura o editor.
3. Clique na área livre: **W/A/S/D** move em relação à câmera, **Q/E** desce/sobe e **arrastar com mouse** altera inclinação/direção. **Shift** acelera 4×, **Ctrl** dá precisão de 0.25×. Escolha uma das quatro velocidades no painel.
4. Também é possível digitar X/Y/Z, inclinação, rolagem e direção: **Enter ou sair do campo aplica o valor completo**, inclusive ao usar as setinhas. FOV continua aplicado pelo controle deslizante. Câmera limitada a 100 m do ponto de partida; FOV 15–100°, pitch -89–89°.
5. Clique em **Capturar para copiar**. O bloco Lua aparece selecionado: use Ctrl+C se a cópia automática não estiver disponível no CEF. O mesmo bloco é impresso no F8 com `[MX:CAMERA]`. Cole o bloco na conversa para aplicar posteriormente.

**Restaurar câmera inicial** volta à pose da ativação e mantém o editor aberto. **Restaurar e fechar** cancela a prévia. **Manter prévia** fecha conservando a visão apenas localmente, até a próxima mudança de câmera/cena. Esc fecha primeiro a área de captura, quando aberta; depois restaura e encerra o editor. Em telas menores o painel tem rolagem interna para alcançar os botões finais.

O export contém `context`, `view`, `position`, `rotation`, `look` e `fov`. A rotação está em graus, ordem 2; o ponto de mira deriva da orientação atual e da distância original de observação. Não há gravação automática em config.lua, banco ou preferências. Não move personagem, carro ou mundo e não impõe colisão à câmera de autoria: é possível compor uma visão inadequada, restaurável pelo próprio editor.

## Integração

- `admin/cameraEditor {enabled}` exige **mx.admin + mx.inspect** para ativar. Ao contrário das ferramentas de teleporte do modo livre, aceita apresentação privada; o cliente só inicia sobre uma câmera de cena existente e autorizada pelo contrato de ownership.
- O servidor revalida epoch/permissão após o ACK. Renova a autorização a cada 2 s; a sessão local expira em 6 s sem renovação. Fechamento libera a inscrição do servidor. Revogação, mudança de cena/handle/token ou parada do resource limpam o editor; uma cena obsoleta nunca restaura valores sobre outra câmera.
- `camera-developer.lua` usa o handle da apresentação. Ao entrar, suspende órbita e cancela transições anteriores. Ajustes liberam o apontamento nativo antes de aplicar posição/rotação/FOV, conforme [StopCamPointing](https://github.com/citizenfx/natives/blob/master/CAM/StopCamPointing.md) e [GetCamRot](https://github.com/citizenfx/natives/blob/master/CAM/GetCamRot.md).
- A NUI tem uma fronteira de teclado instalada antes dos handlers da oficina: WASD/Q/E não acionam garagem, menu, motor ou atalhos. O mouse fica no editor; navegação por controle dos menus é suspensa enquanto ele está aberto. Esta ferramenta de desenvolvimento usa teclado/mouse.
- Atualizações locais são serializadas e coalescidas; não geram uma requisição de servidor por frame. Movimento usa tempo decorrido, normaliza diagonal e pausa ao editar campos/perder foco. Falha de validação reconcilia a interface com a pose real.
- Corrigido o FOV aplicado na câmera principal: um override antigo ainda forçava `framing.fov=49` apesar de o enquadramento calcular com o FOV da cena de 60°. Agora o native recebe o FOV da cena, inclusive antes de abrir o editor. Há regressão executando a criação real da câmera com adaptadores.

Arquivos principais: `experience/camera-developer.lua`, integração em `experience/client.lua`/manifest; `admin/tools-server.lua`/rotas; ponte em `menu/client.lua`; NUI `CameraDeveloper.tsx`, `camera-developer-input.ts`, `camera-developer-math.ts`, main/style e bundle.

## Verificação

- Build com TypeScript e bundle, check de manifests/fronteiras e suíte completa aprovados.
- 23 verificações novas com controlador real e adaptadores: acesso em cena privada, pose nativa inicial, Lua exportável, ponto de mira, limites/valores inválidos, restaurar/manter/resetar, lease, revogação, cena/ownership obsoletos. Movimento em 30/60/144 FPS, diagonal, precisão e aceleração exercitados separadamente.
- `test:ui` aprovado em 1280×720, 1920×1080, 2560×1440 e 3440×1440, incluindo regressão W versus aceleração do motor, campos numéricos, FOV, captura e restauração durante a oficina.
- Após ajustes finais de layout, `node development/tests/camera-developer-ui.mjs` aprovado nas mesmas quatro resoluções com o bundle final. Verifica posição/FOV, captura, painel dentro da viewport com rolagem, restauração e Esc no lobby. Captura final 1280×720 inspecionada visualmente. `MX_CHROMIUM` apontou para Chrome instalado.

Os transportes/natives são simulados. A imagem de browser não contém a cena real do GTA. Não houve cliente FiveM, validação de clipboard CEF, reinício ativo, modificação de dados de jogador ou gravação permanente de câmera nesta entrega. Próximo passo: testar no FiveM lobby e garagem, capturar cada composição e enviar os blocos; verificar também restauração e saída/troca de cena.

Memória registrada somente no export local do workspace, pois a base Obsidian compartilhada continua sem permissão de escrita nesta sessão.

## Correção de saltos e sensibilidade — 24/10/2026, 13:55

Origem: usuário relatou zoom/salto com alterações mínimas tanto pelo mouse quanto pelos campos. Confirmado no código: o editor reutilizava o handle apontado/interpolado da cena e reaplicava todos os natives para qualquer mudança; a interface também enviava cada valor parcial digitado. Sem cliente FiveM, não foi possível atribuir conclusivamente o sintoma visual a um desses caminhos.

O início agora captura posição, rotação e FOV da imagem efetivamente renderizada antes de cancelar transições, cria uma câmera independente sem point-at e descarta a anterior. Mantém ownership e ciclo de vida da cena. Atualizações comparam a pose anterior: mudar somente posição não escreve rotação/FOV; os argumentos nativos de câmera são explicitamente floats. Restauração mantém a imagem capturada ao abrir.

Mouse reduzido de 0.15 para 0.04 grau/pixel, ou 0.01 com Ctrl. Movimento começa em 0.25 m/s. Arraste termina ao perder foco/captura, receber cancelamento ou detectar botão solto. Campos numéricos mantêm rascunho local até Enter/blur; roda do mouse sobre esses campos não altera valores por acidente.

Build/typecheck, check e suíte completa aprovados. Controlador: 24 verificações, incluindo alteração de 1 cm sem escrever zoom/rotação. Integração real da criação de câmera exercitada com rendered pose diferente do handle de destino durante transição. Matemática: mouse suave/preciso, limites e posição/FOV preservados. Browser dedicado aprovado em quatro resoluções com o bundle final: digitação parcial sem update, Enter, incremento 0.01, arraste e FOV preservado, captura/restauração. Capturas e JSON dedicados atualizados. O teste amplo de browser não foi reexecutado nesta correção; seu limiar de movimento foi ajustado à nova velocidade padrão.

Não houve restart nem cliente FiveM. Ainda é necessário reiniciar/reconectar e confirmar visualmente lobby/garagem no jogo; testes simulados não reproduzem o renderer GTA. Nenhuma posição permanente, banco de jogador ou arquivo do NativeCore alterado nesta correção.

## Enquadramentos aprovados pelo proprietário — 24/10/2026

Aplicados os dois blocos capturados enviados pelo usuário em `ExperienceConfig.mainCameras`, no config.lua de mx-freeroam-experience:

```lua
lobby={position={x=-955.000,y=-3532.600,z=14.500},rotation={x=-1.50,y=0.00,z=-100.00},look={x=-949.735,y=-3533.529,z=14.360},fov=66.50}
garage={position={x=138.500,y=-3025.500,z=7.200},rotation={x=-2.00,y=0.00,z=141.00},look={x=135.174,y=-3029.608,z=7.015},fov=60.00}
```

As vistas principais usam posição e rotação explícitas, sem reenquadramento por dimensão do carro/aspect ratio ou ajuste automático de posição por colisão. A mira capturada permanece como referência para transições/órbita; a rotação é a autoridade para reproduzir o enquadramento sem erro de arredondamento do look. Ao concluir a volta da órbita, a rotação explícita também é restaurada. Vistas de detalhes continuam no cálculo existente.

Suíte completa e check aprovados; regressão existente de criação real de câmera estendida para verificar os dois presets com adaptadores nativos. Sem mudança NUI, rebuild, restart ou validação visual no FiveM. Próximo passo: reiniciar/reconectar e conferir ambos os enquadramentos.
