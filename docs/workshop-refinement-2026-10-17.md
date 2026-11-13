# Refinamento da personalização e erros EXTRA/RATE

Esta etapa atualiza a organização descrita em `workshop-polish-2026-10-17.md`. Não houve alteração de schema nem remoção de criações existentes. O perfil em uso não foi reiniciado automaticamente.

## Aplicação de veículos

**EXTRA:** o preflight rejeitava qualquer chave de extra ausente, inclusive uma chave com valor `false`, e fazia isso antes de instalar as peças do documento. Extras podem depender dessas peças. A verificação agora ocorre depois dos mods; extras ausentes desligados não impedem a saída. Um extra solicitado ligado e realmente indisponível continua produzindo erro, mas a mensagem informa seu índice e orienta desativá-lo em Interior & detalhes > Extras. Entradas salvas ligadas que não constam das capacidades atuais também aparecem nessa lista: podem ser desligadas, e depois ficam indisponíveis para religar. A validação estrutural informa chave/tipo inválido e excesso de extras em vez de retornar apenas EXTRA.

Essas condições foram reproduzidas em adaptadores de natives, incluindo uma entidade nova que recebe as peças antes de ganhar o extra. A causa exata no ER34 instalado e a saída real após suas modificações ainda precisam ser confirmadas no jogo.

### Retorno numérico do native — correção posterior

O relato subsequente no ER34N identificou outra falha no caminho de saída: depois de aplicar o veículo, `server.lua` substitui o mapa de extras pelo estado observado enviado pelo cliente e o valida. O cliente enviava diretamente `IsVehicleExtraTurnedOn`; o binding Lua de compatibilidade pode retornar `0`/`1`, enquanto OAL retorna booleanos. Isso faz o ACK falhar na validação estrutural mesmo com o extra correto. A diferença está descrita na [resposta do mantenedor Cfx](https://forum.cfx.re/t/vehicle-extra-native-weirdness-on-fxv2-oal/4810947/2).

`VehicleCustomization.extraEnabled` normaliza exclusivamente a fronteira do native: `true`/`1` viram `true`, `false`/`0` viram `false`. Baseline, comparação e ACK usam essa função. Não se usa `not not value`, pois zero é verdadeiro em Lua. Payloads numéricos recebidos como propriedades continuam rejeitados pelo servidor. Não foi necessário alterar o binding do resource, desligar extras ou modificar dados salvos.

Os testes anteriores simulavam apenas booleanos e não cobriam essa diferença. Foram acrescentadas 11 verificações sobre o handler real: retornos numéricos e booleanos, ACK aceito pela validação de saída, zero desligado, ausência de escritas repetidas e rejeição de retornos inesperados/payloads numéricos. `npm test`, `npm run check` e `git diff --check` passaram. Não houve execução de cliente FiveM; repetir a saída com a criação ER34N existente permanece necessário.

**Adesivos:** a aplicação chamava `SetVehicleLivery` incondicionalmente, até em veículos que só usam o slot 48 do modkit. Além disso, a descoberta das famílias de rodas modificava o veículo sem preservar seus adesivos. Agora a descoberta restaura slot 48, livery nativa e teto; a aplicação evita escritas sem mudança e usa a fonte de adesivo apropriada. Escolher adesivo de modkit desativa a seleção nativa; escolher um nativo retira o slot 48 conflitante do documento. Configurações antigas com slot 48 original e livery nativa válida permanecem aceitas. O índice de teto também só é reescrito quando muda.

Os testes executam o handler real de aplicação em um cenário de modkit, em outro de livery nativa, em trocas repetidas de rodas e em uma segunda entidade. Isso não prova o comportamento gráfico dos materiais do ER34 no runtime.

**RATE:** a interface enviava prévias em sequência sem intervalo mínimo, e confirmar fazia uma prévia seguida de outra aplicação dentro da rota de confirmação. O core continua com sua proteção de 150 ms por ação e 40 requisições por 10 s. O editor agora agrega escolhas rápidas por 180 ms, conserva a última intenção e espaça chamadas cosméticas em pelo menos 500 ms. Confirmar usa uma única aplicação validada pela rota persistente e recupera as capacidades desse resultado. Não foi removido o limitador nem transformada uma rejeição do servidor em sucesso. Há teste de 100 escolhas agregadas em uma requisição e teste de browser que rejeita prévias em menos de 150 ms.

## Organização e interação

Customizar contém:

- **Peças e rodas:** peças físicas externas e famílias/modelos de rodas. Variações de pneus são toggles, habilitados apenas com rodas compatíveis.
- **Pintura & liveries:** Pintura e Adesivo. Pintura abre o painel de cores com abas superiores Principal, Secundária, Perolado e Rodas. Principal/secundária reúnem paleta indexada, RGB e acabamento no mesmo painel. Adesivo lista os mecanismos disponíveis no modelo: modkit, nativo e teto.
- **Suspensão:** sliders de ajustes finos. Dimensões, tipografia e espaçamento foram reduzidos para aproximadamente 80%, sem `transform: scale`. Não há botões de aplicar/restaurar. Enter/A/Cross confirma; soltar o slider confirma a interação do mouse. Apenas focar um campo não grava. A peça nativa de suspensão, quando autorizada pela configuração de desempenho, permanece na lista de peças.
- **Iluminação & efeitos:** faróis, cores de luzes, neons e fumaça. Neons possuem lista com check por lado e opção Todos os neons. O atalho dia/noite é S/X/Quadrado, aparece somente nesse contexto e não ocupa mais o topo.
- **Interior & detalhes:** peças e acabamentos internos, instrumentos, buzina, placa, película, cores internas, extras e equipamentos suportados. Extras e demais opções booleanas usam cards de toggle com check, sem submenus Ligado/Desligado.

As contagens aparecem nas listas de modificações/opções e toggles, sem aparecer em Customizar, Peças e rodas ou famílias de rodas. As faixas continuam com viewport nas bordas; um espaço de conteúdo de 4vw acompanha a rolagem. No início as opções ficam afastadas da borda; ao avançar, esse espaço sai da tela e os itens podem atravessar a borda. O mesmo componente atende modelos, marcas, criações e peças.

Foram retirados o campo de pesquisa do Showroom, Adicionar nova criação em Carros salvos e o botão Voltar na tela inicial da garagem. Os atalhos de retorno permanecem.

## Teclado e controle

O amostrador anterior podia consumir a borda de um comando enquanto o native ainda reportava teclado, descartando a publicação para a NUI. Quando o dispositivo mudava para controle, aquela confirmação já estava marcada como segurada. A amostragem agora mantém o estado neutro durante entradas mapeadas de teclado e processa a borda de controle quando o dispositivo muda, sem duplicar a navegação DOM. A mudança de dispositivo também atualiza os ícones sem depender de uma ação de navegação aceita.

Foram preservados o retorno ao neutro entre contextos, a exigência de soltar confirmações e a repetição direcional por tempo. Os testes de alternância simulam o sinal do native; ainda é necessária conferência com controle físico. Q/E e LB/RB/L1/R1 continuam responsáveis pelas abas de pintura.

## Verificação

- Build Vite e typecheck aprovados; check estático e análise dos 54 arquivos Lua disponíveis. Não há script separado de lint.
- Testes de regras/controladores em Fengari, incluindo aplicação real do resource com natives substituídas por adaptadores explícitos.
- `test:ui`: hierarquia, rolagem, confirmação persistente, painéis RGB, toggles, ausência dos botões de suspensão, intervalo de prévias, retorno e modal em quatro resoluções. Capturas em `docs/evidence` usam fundo neutro, sem cena 3D.
- `test:lobby`: loading, primeiro acesso, personagem, configurações e retorno em quatro resoluções.
- Nenhum teste com cliente FiveM ou controle físico foi executado. Não houve alteração de migrations ou escrita diagnóstica em dados do jogador. A persistência continua pela mesma transação de confirmação; os testes de interface usam respostas de contrato, não banco ou jogo.

Aceites pendentes: carregar a criação ER34 existente e sair com suas peças/extras, comparar adesivos antes/depois de várias famílias de rodas, navegar rapidamente e alternar dispositivos reais, verificar material/iluminação/neons e reconectar para conferir o estado confirmado. Para carregar as alterações de resources e NUI, reinicie o perfil de forma coordenada pelo txAdmin e reconecte.
