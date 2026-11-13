Atualização 17/10/2026: [teclado e mouse, Customizar, ações visíveis, câmeras e suspensão](customization-input-stance.md). Este incremento prevalece para input, F9/F10, rolagem e presets de câmera descritos anteriormente.

# Personalização de veículos na garagem

**Fluxo atual:** a navegação inferior, órbita e representação do motorista foram retrabalhadas em [heat-customization.md](heat-customization.md), que prevalece sobre as descrições de interface e controles deste relatório anterior.

Implementada na base ativa do txAdmin. Em **Minha garagem**, selecione uma criação e use **PERSONALIZAR ESTA CRIAÇÃO**. O editor também permanece acessível pela oficina. Editar uma criação diferente da selecionada para jogar grava o ID escolhido, sem selecionar outro registro ou criar um carro público.

## Cobertura

| Grupo | Opções |
| --- | --- |
| Exterior | Slots visuais 0–10, placa/suporte, porta-malas, equipamento hidráulico 38, arcos, antenas, tanque, portas/acabamentos, livery do modkit 48 e barra de luzes 49 |
| Interior | Slots 27–36: acabamento, ornamentos, painel, instrumentos, alto-falantes, bancos, volante, alavanca, placas e áudio |
| Cofre do motor | Bloco decorativo, filtro e reforço, slots 39–41 |
| Rodas | Famílias 0–12 com peças disponíveis no modelo, peças dianteiras e traseiras/equipamento quando presentes, cor e variação de pneus independente por eixo |
| Pintura | Cores indexadas, acabamento normal/metálico/perolado/fosco/metal/cromado, RGB principal/secundário, perolado, livery tradicional e de teto quando disponíveis |
| Detalhes | Placa, 13 estilos no build 3258 configurado, películas, cores de interior/painel, extras realmente existentes, subwoofer e sistema hidráulico nativo quando detectados |
| Luzes | Xenon, cores indexadas/RGB, neon por região com bone existente, cor do neon e fumaça de pneus |
| Buzina | Slot 14, com as opções do modelo |

Os slots são consultados com modkit 0 e `GetNumVehicleMods`. Nomes usam `GetModTextLabel`/`GetLabelText`, com carregamento de `mod_mnu` e fallback de índice. Nomes extensos são consultados localmente ao focar o campo; não aumentam o contrato RPC limitado a 16 KiB. A lista de rodas é atualizada pela aplicação, e mudar de família restaura os índices originais e desmarca variações incompatíveis antes da nova prévia. A descoberta preserva família, índices e variações anteriores.

Desempenho continua **desabilitado** em `VehicleConfig.performance`: motor, freios, transmissão, suspensão, blindagem e turbo não são liberados por esta entrega. A interface respeita essa configuração. Não foram adicionados handling, baixa aderência, multiplicadores, nitro, invulnerabilidade, pneus à prova de balas ou física personalizada. Não há alteração em mx-gearbox/mx-turbo. Peças de outros modelos e assets ausentes não são inventadas.

## Câmeras e controles

- Focar/alterar uma peça solicita a região correspondente: frente, traseira, lateral, rodas, teto, interior ou cofre do motor. As câmeras usam orientação/dimensões e bones específicos quando válidos, com fallback geométrico. O capô é aberto para a vista do cofre e fechado ao sair dela.
- **CÂMERA LIVRE / F4** permite mover ao redor do carro: **WASD** desloca, **Q/E** muda altura, mouse olha e Shift acelera. **F4, Esc ou Backspace** volta à câmera da peça. Ao partir do interior, a câmera começa fora da carroceria e guarda a peça para o retorno.
- A câmera livre é local, limitada a 12 m, com limites de altura e consultas de colisão. Não move personagem nem veículo. Configuração em `ExperienceConfig.freeCamera`.
- Enquanto livre, a NUI perde foco/cursor e a navegação do menu fica suspensa. Ao voltar, o foco é restaurado. Mantida a posse de câmera da oficina e a suspensão da câmera de condução. Pedidos concorrentes de alternância são coordenados; fechamento invalida operações pendentes.
- Salvar ou cancelar mantém os contratos existentes. Sair do editor retorna à vista principal. Mudar telas continua sem spawn de prévia; aplicar cosméticos conserva a entidade.

## Persistência e compatibilidade

Propriedades novas são campos aditivos do documento JSON schema 1. Documentos existentes recebem defaults apenas ao serem lidos/validados; nenhuma migration ou regravação em massa foi necessária. Índices de peças/liveries agora aceitam até 1023, com verificação adicional da quantidade real no cliente antes de aplicar. Tipos, RGB, chaves, limites e política de desempenho continuam validados no servidor. IDs, propriedade do jogador e revisões continuam obrigatórios.

RGB principal/secundário é removido explicitamente ao restaurar cores indexadas. Cores internas e livery de teto podem voltar ao padrão original capturado para aquela entidade. O antigo campo de variação de pneus mantém a variação traseira quando o documento legado também possui rodas traseiras. Slots legados 19–22 em `mods` permanecem legíveis, mas os toggles são aplicados por seus campos próprios, evitando usar `SetVehicleMod` para um toggle.

O native CFX de xenon RGB não replica a cor sozinho. O servidor publica `mxXenon` somente após aplicar propriedades validadas; cada cliente reaplica o estado ao receber o veículo, com checagem do ID administrado. Reiniciar o resource também recupera o estado das entidades já transmitidas. Essa sincronização ainda exige aceite com dois clientes.

## Referências consultadas

- [vMenu — VehicleOptions](https://github.com/TomGrobbe/vMenu/blob/master/vMenu/menus/VehicleOptions.cs): referência para descoberta dinâmica, nomes de peças e atualização da lista ao trocar rodas. [Licença legacy](https://github.com/TomGrobbe/vMenu/blob/legacy/LICENSE.md) consultada. Não foi copiado código, incorporada dependência ou criada integração com vMenu/MenuAPI.
- [CitizenFX — slots de SET_VEHICLE_MOD](https://github.com/citizenfx/natives/blob/master/VEHICLE/SetVehicleMod.md), [acabamentos](https://github.com/citizenfx/natives/blob/master/VEHICLE/SetVehicleModColor_1.md), [liveries de teto](https://github.com/citizenfx/natives/blob/master/VEHICLE/GetVehicleRoofLiveryCount.md) e [controles](https://docs.fivem.net/docs/game-references/controls/).
- [CitizenFX — VehicleModCollection](https://github.com/citizenfx/fivem/blob/master/code/client/clrcore/External/VehicleModCollection.cs): referência de tipos de mods e bones de neon.
- [CitizenFX — xenon RGB](https://github.com/citizenfx/fivem/blob/master/ext/native-decls/SetVehicleXenonLightsCustomColor.md): documenta a necessidade de sincronização própria.

## Verificação executada

- Build TypeScript/Vite e análise estrutural aprovados. O projeto não configura ESLint.
- 46 arquivos Lua analisados; 28 verificações novas de propriedades/descoberta/aplicação com natives simuladas, além de 93 verificações existentes, 30 do controlador de prévias e testes de fila LatestPreview.
- Playwright em 1280×720, 1920×1080, 2560×1440 e 3440×1440: editor, rótulos de peças, índice 250, reset ao trocar família, chamadas de câmera por peça, botão/F4 da câmera livre e gravação do ID de uma criação diferente da selecionada. Mantidos testes de teclado, rolagem e alternância de abas. São fixtures de contrato, sem natives GTA.
- MariaDB real: documento ampliado preservado integralmente após nova conexão SQL, controle de proprietário e revisão.
- FXServer isolado na porta 30131: resources iniciados e banco pronto; 11 verificações de exports reais/SQL passaram, incluindo `PrepareSaved`/`Saved` com novos campos. O erro de FK provocado no teste de rollback é esperado. Fixtures removidas pelo teste. Instância encerrada; o servidor principal não foi reiniciado.
- Captura renderizada do editor em 1280×720 inspecionada. Evidências em `docs/evidence/ui.json` e `customization-runtime.json`.

## Aceites ainda pendentes

Não houve cliente FiveM nesta entrega. Verificar por modelo: nomes/modkit, acabamentos e RGB, extras, liveries tradicionais/modkit/teto, variações de pneus, contagens das rodas, interior e iluminação. Conferir câmeras de cada peça, abertura/fechamento de capô, colisões/altura da câmera livre, teclado/foco, ida e volta durante respostas atrasadas e reinício de recursos. Confirmar salvamento, cancelamento e recuperação após reconexão de jogo, mantendo uma única prévia. Com dois clientes, verificar xenon RGB, streaming e troca para cores indexadas. Testes de navegador, SQL e natives simuladas não equivalem a esses aceites.
