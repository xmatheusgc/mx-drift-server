# Confirmação atrasada do lobby

Relato: `[MX:LOBBY] LOBBY` no export `LobbyReady`, chamado pelo callback NUI `lobbyReady`.

O export rejeitava com exceção qualquer confirmação cujo lobby/generation já não fosse atual. A NUI confirma após dois frames e o transporte é assíncrono, portanto um ACK pode chegar depois da mudança de tela. Além disso, o loop de entrega verificava contexto antes de `Wait(500)`, mas depois da espera só verificava se havia ACK. Se o jogador saísse nesse intervalo, o loop ainda podia reenviar a tela antiga. Essa condição está reproduzida em teste do cliente real com adaptadores de runtime simulados.

Correções em `experience/client.lua` e `menu/client.lua`:

- Revalidar lobby e generation depois da espera, inclusive antes de anunciar timeout.
- Ignorar recibo obsoleto com `accepted=false`, sem exceção. Validações de ações de negócio continuam intactas.
- Tratar ACK duplicado de forma idempotente; uma duplicata durante o fade não anuncia loading encerrada prematuramente.
- Revalidar contexto depois do fade antes de revelar a cena.
- Filtrar eventos de apresentação pela generation vigente antes de enviá-los à NUI.
- Alterar foco/emitir `loadingClosed` somente quando o ACK foi aceito, o lobby segue aberto e o loading realmente terminou.

Verificação: `npm --prefix development test`, `npm --prefix development run check` e `git diff --check` aprovados. Dez verificações adicionais executam os exports reais do cliente, cobrindo ACK antes do lobby, generation antiga, duplicata durante/após fade, confirmação depois da saída e saída durante o Wait do retry. SQL, NUI e natives são adaptadores simulados nesses testes. Não houve alteração de interface compilada, SQL ou dados salvos.

O servidor não foi reiniciado automaticamente; é necessário reiniciar o perfil e reconectar para carregar os scripts de cliente atualizados. Pendente: repetir Lobby → Garagem → Voltar no FiveM e confirmar ausência do erro e de retorno indevido de tela/foco. Não houve execução com cliente FiveM nesta rodada.
