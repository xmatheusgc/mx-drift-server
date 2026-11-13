# Coordenadas e teleporte administrativo — 24/10/2026

O proprietário pediu mais ferramentas administrativas para substituir o uso do vMenu, priorizando coordenadas com heading. Na consulta de prioridades, escolheu teleporte por coordenadas e marcador. Foram adicionados dois submenus em **M → Administração**.

## Uso

| Opção | Comportamento |
| --- | --- |
| Coordenadas e heading → Referência | Alterna personagem, veículo ocupado e câmera renderizada. |
| Mostrar coordenadas na tela | Painel de X/Y/Z/heading atualizado localmente a cada 100 ms, inclusive com menu fechado/noclip. Inicia desligado, sem KVP persistente. |
| Atualizar captura | Atualiza a leitura no submenu; sem painel ligado os valores são uma captura, não uma atualização contínua. |
| Capturar vector3 / vector4 + heading / tabela Lua | Faz nova leitura; tenta copiar e abre campo somente leitura, selecionado, para Ctrl+C caso a área de transferência não esteja disponível no CEF. Enter/Esc volta. |
| Modelo, interior, ID de rede | Informações da entidade da referência personagem/veículo; câmera não inventa dados de entidade. |
| Teleporte administrativo → Ir para coordenadas | Aceita `X, Y, Z, heading`, `vector4(...)` ou três coordenadas. Ponto nos decimais; heading omitido mantém direção real do ped/carro no servidor. |
| Ir para marcador do mapa | Usa o marcador já colocado no mapa. Prepara streaming e busca solo antes de viajar, com limite de 8 s. Sem marcador/solo, falha e não inicia viagem. |

Formatos de captura usam três casas nas posições e duas no heading. Personagem, veículo e câmera podem produzir posições diferentes; escolha a referência desejada antes de capturar. Captura da câmera normaliza yaw para 0–360 graus.

Marcador usa solo encontrado +1 m, sem aceitar água como superfície. A função de solo depende de streaming na região; interiores, pontes, mapas elevados ou locais sem solo podem exigir coordenadas com Z explícito. Não há fallback silencioso para Z=0. Referências primárias: [GetGroundZFor_3dCoord](https://github.com/citizenfx/natives/blob/master/MISC/GetGroundZFor_3dCoord.md), [SetFocusPosAndVel](https://github.com/citizenfx/natives/blob/master/STREAMING/SetFocusPosAndVel.md).

## Permissões e integração

Administração continua exigindo `mx.admin`. Leitura/painel exigem também `mx.inspect`; teleporte exige `mx.teleport`, acrescentada a `group.mxadmin` em `config/server.cfg`. Admin do painel txAdmin continua independente das ACEs do jogo. As ferramentas são para o modo livre; não operam na apresentação privada da garagem/lobby.

`admin/coordinates {target}` pede leitura local autenticada; dados não concedem autoridade sobre entidades. `admin/coordinateOverlay {enabled,target}` configura painel com renovação de autorização a cada 2 s e expiração local em 6 s sem renovação. Mudança de perfil, perda da ACE, entrada em cena privada e parada do resource limpam o painel. Desligar o próprio painel continua permitido para liberar estado mesmo após perder acesso.

`admin/teleport {mode:'coordinates',point}` ou `{mode:'waypoint'}` registra intenção em audit_log e revalida epoch depois do audit. Encaminha ao export estruturado `world:AdminTravel`, restrito ao resource admin, que verifica novamente ACE/contexto, limites e estado após buscar o marcador. X/Y entre ±20000, Z entre -100 e 3000, heading opcional entre 0 e 360; campos desconhecidos rejeitados.

World reutiliza o fluxo de viagem existente: encerra noclip, escolhe o veículo gerenciado dirigido ou ped, reserva posição, protege ocupantes/destinos ocupados, exige ACK, confere posição replicada e recupera posição anterior em falha. Veículos de terceiros e passageiros não são movidos. Atividades são invalidadas pela viagem existente. Não há remoção indiscriminada de entidades ou alteração de carros salvos.

Arquivos principais: `admin/tools-client.lua`, `admin/tools-server.lua`, `admin/server.lua`, `world/admin-travel.lua`, manifests, ponte NUI em `menu/client.lua`, `SessionMenu.tsx`, `AdminCoordinateOverlay.tsx` e `admin-coordinates.ts`. Bundle de produção atualizado. O acesso à inspeção administrativa também aceita administrador que tenha apenas uma permissão específica, incluindo teleporte/moderação.

## Verificação

- `npm.cmd --prefix development run build`: aprovado, incluindo TypeScript e bundle.
- `npm.cmd --prefix development run check`: aprovado, manifests/fronteiras/dependências.
- `npm.cmd --prefix development test`: suíte completa aprovada. Há 36 verificações novas de referências/ACE/epoch/painel/marcador/viagem com natives simulados; parser/formatador rejeitam valores inválidos e mantêm heading opcional. Integração adicional executa o export novo com o fluxo real de world, cobrindo carro/a pé, heading, ocupação, passageiros, falha de ACK/rollback e repetição.
- `run test:ui` usando Chrome instalado: aprovado em 1280×720, 1920×1080, 2560×1440 e 3440×1440. Menu por teclado, captura somente leitura, painel com menu fechado, desligamento, rejeição de coordenadas inválidas, payload vector4, erro de marcador ausente e confirmação de viagem simulada. Capturas `docs/evidence/admin-coordinates-*.png` e `admin-teleport-*.png`; ambas de 1280×720 inspecionadas visualmente.

Os testes não certificam funcionamento físico de controle, solo real nem área de transferência do CEF. Não houve cliente FiveM, reinício ativo, teleporte real ou alteração de dados de jogador nesta implementação. O vMenu não foi removido/desabilitado; o pedido foi atendido com ferramentas próprias para permitir a substituição gradual.

Próximo passo: reiniciar servidor completo pelo txAdmin, reconectar e testar M → Administração, painel durante noclip, captura/Ctrl+C, coordenadas com heading, marcador em área distante, ausência de marcador e teleporte com carro próprio sem passageiros. Validar outras funções ainda usadas do vMenu antes de retirar sua inicialização.
