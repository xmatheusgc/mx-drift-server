# FiveM — histórico e limites de validação

Consolidado em: 2026-10-23. Projeto: [[02 Projetos/Drift server FiveM]].
Origem: chat fornecido pelo usuário, código atual e relatórios de `C:\FiveM\drift-server\txData\FiveMBasicServerCFXDefault_CAECC7.base\docs`.

Esta nota orienta diagnóstico futuro. Um relato identifica sintoma; uma mudança de código pode corrigir um defeito sem demonstrar a causa exata no runtime/modelo. Não reclassificar como resolvido no jogo sem reteste confirmado.

## Evolução que não deve ser perdida

- Base começou standalone limpa; por pedido do usuário foi integrada ao diretório CFX/txAdmin. O ambiente atual é a base em `txData`, com ferramentas em `development`, não uma instalação paralela `/freeroam`.
- O trainer foi simplificado em relação aos primeiros menus. Existem domínios sociais/atividades no repositório, mas isso não autoriza recolocar encontros e funções descartadas no menu principal.
- Interface da oficina evoluiu para composição Heat, componentes comuns, prévia e confirmação por peça. Salvar/Descartar globais, F9/F10, barra de navegação redundante e antigos botões inferiores de câmera não são o destino atual.
- A proibição inicial de handling foi substituída apenas para o preset de drift fornecido e explicitamente solicitado depois. Não é autorização geral para reformular física/câmbio.

## Histórico de falhas relatadas e implementação correspondente

| Sintoma relatado no chat | Registro/caminho de continuidade |
| --- | --- |
| UNAVAILABLE ao Jogar/Garagem; aviso de net ID 65534 | Relatórios `garage-unavailable.md`, contratos de identidade/rede e catálogo. Não atribuir automaticamente toda falha nova ao banco só por UNAVAILABLE. |
| STANCE: modelo não aceitou tamanho/largura | Capacidade/readback de rodas e stance são por modelo. Revisar `stance.lua`, `stance-rules.lua`, `customization.lua`; não aceitar toda modificação ignorando native. |
| Tela preta após loading; depois entrada em limbo com SESSION | Relatórios de ACK/transições e `environment-entry-paint-2026-10-21.md`. Última correção separa ped temporariamente zero de epoch alterado e mantém erro inicial protegido. |
| Modelos mods ausentes no showroom; filesystem fs.read restrito | Catálogo em `catalog.lua/js`, descoberta de metadados efetivos por resource. Há testes com adaptadores e relatório `catalog-discovery.json`; verificar runtime/streaming real. Não ampliar leitura arbitrária do disco por reflexo. |
| LOBBY em require | Relatório `lobby-showroom-controls-2026-10-17.md` e fluxo de contexto independente lobby/garagem. Coordenada atual X do lobby é negativa. |
| Tag inválida no catálogo | Validação de metadados/tags no domínio vehicles. Diagnóstico deve identificar modelo/campo; não relaxar schema indiscriminadamente. |
| EXTRA/extra 1 impedia sair com ER34N | Normalização de retorno native 0/1 para booleano e extras condicionais às peças. Tests `vehicle-apply.lua`; manter payload estrito no servidor. |
| RATE ao passar rodas rapidamente; adesivo mudava ao navegar | Fila cosmética serial/coalescida, preview separado da gravação e preservação de slot 48/livery. Não resolver só com atrasos arbitrários nem persistir cada destaque. |
| Controle invertia/pulava itens, ignorava troca mouse → gamepad | Navegação/deduplicação/foco lógico e componentes comuns; testes com mensagens simuladas não provam dispositivo físico. |
| Câmera muito perto, arraste atrasado/residual, personagem voava | Relatórios de free camera, refinements-camera-doors e câmeras do lado direito. Revalidar geração/veículo após operações assíncronas; limpar input ao perder foco. |
| POSITION ao voltar à garagem em movimento | `trainer-entry-recovery-2026-10-18.md` e transferência com rollback. Não congelar novamente jogador já recuperado após erro. |
| COLLISION em checkpoint/pistas | `track-direct-teleport-2026-10-18.md`; solicitação de streaming é dica, não gate rígido nesses teleportes. Servidor ainda decide transporte e valida autorização/posição. |
| Noclip falhava na segunda ativação, nil local s; Shift sem efeito; transparência persistia | Registros de noclip/persistent-drift/opacity; sessão revalidada após yield, teclas Shift físicas, transparência preservada durante voo e ResetEntityAlpha na saída. |
| ER34N: drift recusado em fBackEndPopUpBuildingImpulseMult | `trainer-drift-switch-2026-10-19.md`, subtipo CCarHandlingData no asset e drift-client. Verificação dos atributos não comprova sensação de drift. |
| S14: Cores não confirmadas; confirmação pendente | Correção registrada em 2026-10-21: ordem de pintura e leitura RGB/indexada separadas. Sintoma exato no asset não reproduzido no FiveM; reteste prioritário. |
| S14 → ER34N salvo: RESPAWN e travamento, sem erro F8 | Último relato de gameplay do usuário nesta conversa. `prepareRespawn` retornava false sem lançar erro; havia freeze/lock antes de saída e recuperação remota ignorada. Correção de 2026-10-21 usa snapshot/token, recuperação local e watchdog; reteste prioritário. |

Os itens antigos acima são rastros de diagnóstico, não uma lista de bugs todos ainda ativos nem de problemas todos já aceitos como resolvidos. Conferir os relatórios e o comportamento atual antes de mexer.

## Limpeza e dados históricos

`docs/legacy-cleanup.md` registra que arquivos antigos foram arquivados e tabelas legadas removidas após backup/restore, preservando o banco ativo. É um relato histórico de 2026-10-16, não autorização para nova exclusão.

O caminho de arquivo temporário citado no relatório, `C:\FiveM\drift-server\temporario-legado-20261016`, **não foi encontrado na consulta de 2026-10-23**. Não se sabe nesta síntese se foi movido ou apagado; não afirmar disponibilidade atual dos dumps nem executar restauração com base apenas no texto antigo. Gearbox/turbo permanecem como preservação explícita do usuário.

## Escala de evidência

1. **Fonte/código presente:** confirma implementação e configuração, sem execução.
2. **Regras/Lua com adaptadores:** verifica lógica executada e cenários simulados; não comprova bindings Cfx, autoridade de rede ou material de asset.
3. **Browser/Playwright:** confirma renderização/NUI e contratos simulados; não comprova foco/controle físico, câmera ou entidades no GTA.
4. **MariaDB isolado:** pode comprovar queries, migrations, revisões e nova conexão SQL; não equivale a reconectar jogador no FiveM.
5. **Boot/exports no FXServer:** confirma carga dos resources naquele ensaio; não equivale a gameplay.
6. **Cliente(s) reais:** necessários para peça/material, som/neon, câmera, físicas, streaming, latência, isolamento entre jogadores, posse/migração e limpeza/reconexão.

As entregas recentes de ambiente, pintura e recuperação de troca têm evidências locais, sem cliente FiveM nem restart ao vivo registrado. No novo atendimento, capturar relato/erro atual e identificar qual versão está carregada. Não executar automaticamente correções antigas outra vez nem prometer que compilar resolveu um sintoma de jogo.
