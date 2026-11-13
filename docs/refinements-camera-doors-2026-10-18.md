# Câmera, portas e botões da oficina — 18/10/2026

Atualização posterior: o atalho de portas passou para **Espaço / L3**, conforme [seleção e etiqueta de equipamento](selection-equipped-space-2026-10-18.md). L-ALT abaixo registra o atalho original desta entrega.

## Câmera

O amortecimento anterior (`response=14`) somava-se aos passos pequenos do controlador e à fila de deltas excedentes no navegador. Arrastar rápido podia deixar trabalho pendente para vários frames após terminar o gesto.

- `response=40` reduz o tempo de aproximação ao destino aprovado. Na matemática isolada, um passo percorre mais de 85% em 50 ms; isso não é uma medição de latência do FiveM.
- Movimento do mouse é limitado e agregado no frame atual. O excesso não vira uma fila de movimentos futuros. A contrapartida é limitar a velocidade máxima de uma amostra muito grande.
- Soltar, cancelar, perder captura/foco ou atingir a borda do viewport cancela o lote não enviado e envia `stop`. Movimentos sem botão pressionado são ignorados.
- Cada mensagem leva a identidade do editor e um número crescente. Mensagens que chegam depois de um `stop` mais novo são ignoradas, assim como mensagens de outro editor.
- `stop` descarta a consulta de colisão pendente e usa a posição visual atual como destino, encerrando a cauda do amortecimento. A câmera fica parada até receber novo movimento.
- Passos do controlador acompanham melhor os deltas permitidos sem remover as consultas de colisão nem os limites externos ao carro. A transição de ativação e a câmera livre entre submenus permanecem.

## Portas

A abertura dependia de uma troca de câmera. A aplicação/inspeção de peças podia fechar portas sem nova troca de enquadramento; em câmera livre, o retorno antecipado também impedia atualizar o contexto.

O estado agora pertence à apresentação temporária: contexto de capô/motor, porta-malas, interior e portas laterais determina quais abrir. `vehicles/apply` emite o contrato local `mx:vehicles:presentationApplied` após aplicar e inspecionar a prévia. A apresentação reabre suas portas nesse ponto e verifica novamente a cada 250 ms. A atualização de contexto ocorre antes do cache e da verificação de câmera livre.

**L-ALT / L3** alterna abrir e fechar todas as portas válidas, incluindo capô e porta-malas. A escolha manual prevalece entre categorias durante esse editor. Ao sair, fecha todas as portas gerenciadas; nada é persistido no carro salvo. Veículo e identidade da apresentação são verificados antes das operações. Portas inexistentes são ignoradas.

O L3 usa `INPUT_SCRIPT_LS` (230), conforme a [documentação Cfx de controles](https://docs.fivem.net/docs/game-references/controls/). A existência da porta é consultada por [GetIsDoorValid](https://raw.githubusercontent.com/citizenfx/natives/master/VEHICLE/GetIsDoorValid.md). O pequeno glifo sólido L3 foi desenhado no projeto; os demais continuam com os assets existentes.

## Interface

Removidas as exceções de cor branca permanente, largura e fonte de Jogar. O grid principal usa colunas iguais e a seleção compartilha o estado visual comum. Carros salvos mantém o indicador de atalho e o retorno por teclado/controle; o botão Voltar duplicado foi removido.

## Verificações e limites

- Build, typecheck, checks estáticos, testes de lógica e `diff --check` passaram (aviso preexistente de normalização CRLF em `server.cfg`).
- Testes do controlador real com natives simuladas: cancelamento de consulta e amortecimento, rejeição de sequência antiga/editor antigo, abertura por contexto, restauração após aplicação, alternância manual, isolamento de identidade e fechamento na saída.
- Browser nas quatro resoluções existentes: arraste rápido limitado, fim da fila após soltura, blur e borda, atalhos de portas, medidas/cores dos botões e ausência do Voltar duplicado. Respostas NUI são fixtures; relatório `docs/evidence/ui.json`.
- Inspeção visual: `docs/evidence/garage-home-refined-1280x720.png`.

Nenhum cliente FiveM foi executado. Conferir resposta percebida, saída física do mouse da janela, perda de foco do FiveM, analog stick e animações das portas em modelos vanilla e ER34N. Não houve alteração de dados persistidos, handling, câmbio ou física.
