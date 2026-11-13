# Carregamento e recuperação de entrada — 25/10/2026

O usuário relatou entrada demorada em outra rede, aviso prematuro para reconectar e tela preta após `SCENE_STREAM` na passagem do lobby para a oficina. A inspeção confirmou que a troca de contexto de uma sessão privada existente não tinha o rollback da primeira entrada: falhas de fade, cena ou prévia deixavam a sessão parcialmente alterada e a tela escurecida. A causa exata do atraso dos assets no outro PC ainda depende de diagnóstico no FiveM.

O streaming já posicionava e congelava o personagem no destino, definia o foco e solicitava uma esfera de carregamento antes de aguardar. Isso foi preservado, assim como a exigência de modelos, interior, cenário e colisão prontos. Não foi adotada uma liberação que aceitasse apenas o piso vanilla como prova de que a oficina customizada carregou.

## Alterações

- `experience/server.lua`: recuperação comum para primeira entrada, troca lobby/oficina e recuperação da prévia no mesmo contexto. Limpa prévia e sessão privada, devolve bucket e solicita rollback; protege contra epoch substituído. Confirma posição também na troca de contexto.
- `experience/client.lua`: invalida a geração e encerra streaming antes de aguardar o rollback. Remove status e fade na recuperação. A primeira entrada permanece congelada, com lobby opaco e opção de tentar novamente; uma tentativa nova cria sessão nova. O prazo de 25 segundos aguardando perfil agora informa espera, sem afirmar falha.
- `scene-streaming.lua`: espera até 90 segundos (antes 30), comunica as pendências uma vez por segundo e registra flags diagnósticas no timeout. Continua liberando foco/modelos/interior após falha ou cancelamento. Carregamento de modelo de veículo continua limitado a 30 segundos, informando o modelo selecionado durante a entrada.
- Prazos coordenados: 105 segundos para RPC de cena, 240 para requisição completa e 245 para fetch NUI. A diferença cobre personagem, cenário, prévia, replicação e recuperação em sequência.
- `core/shared.lua` e `core/server.lua`: ACK de falha transporta código/mensagem de domínio, com limite e validação no servidor. Nunca vira sucesso; erro sem envelope usa fallback compatível e exceções inesperadas mantêm detalhes técnicos locais. O jogador recebe a causa legível sem depender apenas do F8.
- Loading inicial: percentual somente dos recursos, etapas reais de arquivos/inicialização, tempo decorrido e explicação da primeira entrada. Silêncio por 60 segundos não vira diagnóstico de conexão. Após cinco minutos sem eventos oferece reconectar apenas se também não houver avanço no indicador de download do FiveM. Eventos novos removem o aviso antigo; erro confirmado permanece até nova etapa explícita.
- NUI: status acima do fade, spinner, etapa, duração e explicação de demora. Mantém bloqueio de input enquanto a cena está coberta. A troca de carro no catálogo também exibe uma explicação no overlay existente. Bundle servido reconstruído.

Os eventos de carregamento e o encerramento manual seguem a [documentação oficial Cfx](https://docs.fivem.net/docs/scripting-manual/nui-development/loading-screens/). O percentual do evento não mede o download total em bytes nem garante que o perfil, a oficina e o veículo estejam prontos; não há ETA inventado.

## Verificação local

Aprovados: build/TypeScript, check estático, cold-join, recuperação dos handlers reais com adaptadores, envelopes de erro RPC, `test:lobby` e `test:ui`. Browser nas resoluções 1280×720, 1920×1080, 2560×1440 e 3440×1440. Inspeção visual das capturas de loading e oficina em 1280×720, sem cortes.

Regressões: streaming simulado conclui aos 45 segundos; registro ausente, timeout e cancelamento liberam recursos; falhas no fade, cena e prévia da troca lobby → oficina recuperam sessão e permitem nova tentativa; cliente invalida callback antigo antes do rollback; entrada inicial continua protegida; interface cobre fade e remove status ao concluir. Relógio de browser simula silêncio de 65 e 305 segundos, retomada de eventos, erro confirmado e progresso de cena sem reiniciar a duração.

Evidências: `docs/evidence/loading-feedback-2026-10-25.json`, `loading-slow-*.png`, `workshop-slow-*.png`, `lobby.json` e `ui.json`. Os testes usam adaptadores/fixtures e não comprovam streaming nativo nem conexão remota.

`npm --prefix development test` analisa sintaxe Lua e executa várias suítes, mas ainda para em `orbit-client-lifecycle:64: lobby main uses the exact authored pose and FOV`, divergência preexistente registrada na memória. Nenhuma câmera foi alterada nesta entrega. Os testes específicos desta correção passaram separadamente.

Para repetir as regressões de loading, a partir da base:

```powershell
$env:MX_CHROMIUM='C:\FiveM\drift-server\tools\playwright-browsers\chromium-1248\chrome-win64\chrome.exe'
npm.cmd --prefix development run test:loading
```

## Validação pendente no jogo

Não houve restart, alteração de SQL, limpeza de cache ou teste com cliente FiveM nesta tarefa. Para carregar todos os scripts/configs compartilhados e a loadingscreen, fazer reinício completo do servidor e reconectar os clientes.

1. Repetir entrada no PC da outra rede: observar etapas, percentual de recursos e espera; não interpretar silêncio isolado como falha.
2. Entrar do lobby para a garagem pela primeira vez: verificar feedback durante download/streaming e oficina completa antes da exposição.
3. Se houver timeout, verificar retorno à interface com tentativa disponível, ausência de tela preta persistente e sucesso da nova tentativa após assets prontos.
4. Conferir também entrada a pé/dirigindo pelo mundo livre e troca de veículo ainda sem cache. Confirmar retorno e controles após falha.
5. Se continuar falhando, guardar a mensagem e o registro `action=streaming` do F8 com `scene`, `collision`, `models`, `interior`, `elapsed` e eventual `missingModel`; isso distingue o requisito pendente sem inferir sua causa apenas pelo tempo.
