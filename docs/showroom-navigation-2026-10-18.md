# Showroom e troca de dispositivo — 18/10/2026

## Catálogo

O botão superior Marcas e a barra de filtros foram removidos. O showroom abre na lista de marcas, lembra a última marca para restaurar o foco ao voltar e usa o retorno normal da interface para sair dos modelos. A paginação permanece discreta abaixo da lista apenas quando necessária; não é um filtro.

O flash de todos os carros vinha da reutilização do array do catálogo anterior durante a troca de marca, antes de a consulta filtrada terminar. A interface agora vincula cada resultado a **token da sessão + marca + página**. Resultados de outra chave não são renderizados. Só buscamos modelos quando uma marca está escolhida; na lista de marcas, buscamos apenas as marcas. Não há consulta inicial de modelos sem marca.

Ao trocar, uma lista incompatível desaparece imediatamente e é substituída por Carregando modelos. Dados já carregados para a mesma chave podem ser mostrados enquanto são atualizados. Geração da navegação e sequência da consulta impedem que uma resposta anterior substitua a lista atual. A confirmação de um modelo também depende de ele pertencer à página exibida.

Solicitações iniciais usam debounce de 200 ms. `api.ts` espaça leituras de catalog/catalogBrands em pelo menos 160 ms por ação, inclusive quando aguardam outras chamadas na fila, respeitando a proteção de 150 ms do servidor sem aumentar seus limites.

## Foco e estilo

`:focus-visible` depende da modalidade reconhecida pelo navegador. Uma mudança programática por mensagem do controle após usar mouse podia ter foco real sem o destaque visual que aparecia após uma tecla física.

Botões da oficina e lobby agora compartilham a seleção também por `:focus`. No showroom, o carro de prévia continua identificado por `aria-pressed`, e o destaque acompanha a opção focada; um alvo de prévia antigo não deixa outra caixa branca simultaneamente.

Uma regra antiga de `.heat-tile` com `background: ... !important` também anulava o fundo branco do foco e deixava texto escuro sobre fundo escuro. Essa exceção e a borda exclusiva de `:focus-visible` foram removidas. Os testes conferem explicitamente fundo claro e texto escuro após a transição, além da igualdade entre modalidades.

`navigateControl` só permite que campos visíveis pertencentes ao contexto atual consumam esquerda/direita. Sem foco válido, a primeira seta foca a primeira opção disponível. A descoberta de opções usa retângulos visíveis, incluindo elementos fixos que podem não ter offsetParent. Abas superiores continuam fora das setas direcionais: Q/E e bumpers mantêm sua função.

## Verificação

- Build, typecheck, testes de lógica/pacing e checks estáticos.
- Browser da oficina: duas marcas, resposta artificialmente atrasada, ausência de modelos antigos enquanto carrega, ausência de consulta sem marca e de toolbar de filtros, estilos computados de foco equivalentes e primeira seta do controle após remover o foco com mouse. Preservadas regressões de garagem, editor, câmeras e persistência por fixtures.
- Browser de lobby/loading/onboarding nas quatro resoluções. A expectativa antiga de largura idêntica de Jogar entre grids de telas distintas foi ajustada ao comportamento aprovado anteriormente: Jogar tem a mesma largura dos botões irmãos em cada tela.
- Inspeção visual: `docs/evidence/showroom-controller-1920x1080.png`. Relatórios detalhados de browser em `docs/evidence/ui.json` e evidências da suíte lobby.

Nenhum cliente FiveM ou controle físico foi executado. As mensagens do controle e as respostas de transporte são simuladas no browser. Validar no jogo alternância mouse/teclado/controle, primeira seta após usar mouse, navegação por marcas/páginas e assets reais. Nenhum dado salvo, catálogo de assets ou permissão administrativa foi removido.
