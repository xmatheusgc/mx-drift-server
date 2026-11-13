# Aparência do noclip — 2026-10-18

Atualização após teste do jogador: a limpeza funcionou. A pedido dele, a transparência foi restaurada (`ghostAlpha=80`) durante o noclip, mantendo `ResetEntityAlpha` na saída e a restauração da opacidade anterior. Testes de regressão e check passaram novamente, incluindo transparência ativa e ausência de override após desativar. A versão com transparência restaurada ainda depende de confirmação visual no FiveM. O relato abaixo descreve a etapa anterior de diagnóstico.

O noclip aplicava alpha 80/255 ao carro e ao personagem em cada frame. Essa transparência é uma causa compatível com a aparência embaçada relatada; o módulo não aplica filtros de blur. A persistência visual no GTA não foi reproduzida em um cliente nesta entrega.

Removida a alteração de alpha durante o noclip e a configuração ghostAlpha. O veículo continua visível localmente, oculto para outros jogadores e sem colisão enquanto o modo está ativo. Na saída, ResetEntityAlpha limpa o override de renderização antes de restaurar visibilidade. Se a entidade já tinha uma opacidade diferente antes do noclip, esse valor é preservado. Não há limpeza indiscriminada de outras entidades.

`npm ... test` e `npm ... run check` aprovados. Regressões executam o controlador real com adaptadores: opacidade normal durante noclip, reset de carro/personagem ao sair, preservação de alpha anterior e os ciclos de reativação existentes. Não houve alteração NUI nem repetição de build/browser nesta correção exclusivamente Lua.

Pendente no FiveM: verificar acabamento do carro, vidros, personagem e observação por outro cliente após ativar/desativar, perda de controle de rede e reinício do recurso. Reinicie o servidor e reconecte para carregar o código e descartar entidades com possível estado visual da versão antiga. Não foi executado reinício nesta entrega.

Referências: [SetEntityAlpha](https://github.com/citizenfx/natives/blob/master/ENTITY/SetEntityAlpha.md), [ResetEntityAlpha](https://github.com/citizenfx/natives/blob/master/ENTITY/ResetEntityAlpha.md) e [SetEntityLocallyVisible](https://github.com/citizenfx/natives/blob/master/NETWORK/SetEntityLocallyVisible.md).
