# Vagas estáveis e troca visual de carros salvos — 2026-10-30

Origem: usuário relatou recarga de todas as vagas ao trocar carro e duplicação de uma criação entre a oficina e o cenário durante seleção ainda não confirmada. Pediu trocar rapidamente o carro da vaga com o atual.

## Diagnóstico

O servidor excluía das vagas `s.current.id` (criação confirmada), sem identificar qual criação salva estava na prévia efetivamente visível. A invalidação do cenário incluía o ID confirmado e a ordem de SavedList, alterada pelo uso. No cliente, o resultado compacto do banco determinava o índice físico das vagas; mudar uma exclusão podia mudar várias posições/chaves e reconstruir vários carros.

## Implementação

- Servidor mantém `displayVehicle`, com identidade da criação salva e propriedades efetivas da prévia, separado do ID de entidade da apresentação e da escolha confirmada. `previewChanged` entrega essa informação e a criação confirmada ao controlador local. Prévia de catálogo não ganha identidade salva por coincidência de modelo.
- `displayVehicles` exclui a criação efetivamente exibida e retorna metadados dela/seleção. Associação também acompanha confirmação/salvamento de criação nova, sem converter uma mera prévia em seleção persistida.
- Stamp do cenário considera IDs, revisões e disponibilidade ordenados por identidade. Troca de seleção/ordem de uso, isoladamente, não invalida toda a coleção.
- `WorkshopDisplay` mantém as vagas em cache por sessão. Quando a criação escolhida ocupa uma vaga, o carro salvo que saiu da oficina assume essa vaga; as outras posições permanecem. Cancelar volta a colocar o carro confirmado no centro. Seleções sucessivas mantêm coerência visual sem gravar escolha ou propriedades no SQL.
- Vagas têm índice explícito, inclusive quando há espaços vazios, impedindo compactação/deslocamento das seguintes. Snapshot atualizado do servidor reconcilia por identidade, preservando as posições já ocupadas e atualizando só dados alterados.
- Trocas comuns usam cache e não pedem novamente `displayVehicles`. Alterações reais da coleção continuam podendo atualizar o snapshot. Se a resposta chegar após uma nova prévia, é descartada e buscada novamente para não desfazer a troca recente.
- No resource de veículos, itens desejados inalterados preservam também a referência durante carregamento; sync idêntico não cancela/reinicia streaming. Handles removidos/reutilizados são revalidados. Entidades próprias são ocultadas antes da exclusão; falha de DeleteEntity deixa órfão oculto para o reaper, evitando cópia visível.

A troca é visual entre a prévia administrada e as cópias locais do cenário. Não promove cópia local a veículo público, não altera ownership/bucket, não apaga carros por proximidade e não reescreve o ciclo de vida da entidade principal. Em uma troca com sete vagas, somente a cópia da vaga envolvida é substituída; as outras seis entidades ficam intactas.

## Verificação

`npm.cmd --prefix development run test:garage` aprovado, incluindo testes anteriores do display e rotas de sessão:

- cenário com sete carros: uma troca cria só uma cópia e mantém exatamente os outros seis handles;
- prévia/cancelamento sem novo RPC de vagas nem gravação de seleção; confirmação não recria cenário;
- três seleções rápidas afetam somente suas três vagas;
- ordem diferente do snapshot não desloca/recria carros; uma revisão alterada reconstrói só sua vaga;
- snapshot atrasado não substitui a identidade da prévia mais recente;
- vagas esparsas e rejeição de índice duplicado; sync idêntico não reinicia modelo em carregamento;
- exclusão baseada na prévia salva não confirmada, isolamento da escolha persistida, restauração da exclusão ao cancelar e ausência de invalidação por seleção;
- orçamento máximo, modelos/timeout, cleanup, órfãos ocultos, identidade reutilizada, token/source/epoch e leitura limitada por proprietário preservados.

`npm.cmd --prefix development run check`, `loading-recovery.mjs` e `wheel-recovery.mjs` também aprovados. Logs de falhas esperadas nos testes são adapters de timeout/props/delete/cleanup; não são falhas reais de runtime.

Testes usam natives, RPC e SQL simulados. Contagens de criação/reuso não são medição de FPS ou tempo real de streaming. Sem SQL ao vivo, reinício de servidor/resources ou validação FiveM. Sem mudança NUI/build necessário.

## Próximo passo

Carregar `mx-freeroam-vehicles` e `mx-freeroam-experience` atualizados em momento adequado e abrir nova sessão de garagem. Validar Y → prévia X (Y aparece na vaga de X), cancelar e confirmar; repetir rapidamente X/Z e com criações do mesmo modelo, conferir que vagas alheias permanecem paradas e sem piscadas. Usar `mxdisplayinfo` para acompanhar métricas de criação/reuso. Validar também sair/reentrar, exclusão/salvamento de criações e recuperação de erro.
