# Refinamento da oficina

Implementado na base ativa do txAdmin, sem migrations nem alteracao de registros salvos.

## Ciclo de vida
A navegacao chamava resetPreview ao sair do catalogo/garagem; abertura de personagem/preferencias repetia a restauracao. O controlador Preview sempre carregava, removia e criava, inclusive para o mesmo modelo. Removidos os gatilhos de entidade da navegacao. Reabrir a oficina conserva a apresentacao valida. Edicao explicita da criacao salva continua restaurando sua configuracao, sem recriar quando o modelo coincide.

O controlador compara propriedades normalizadas e ponto: pedido identico retorna metadados; mesmo modelo aplica a configuracao completa no lugar; modelo diferente ou entidade invalida usa a substituicao coordenada existente. Aplicacao interrompida marca propriedades incertas, forcando reaplicacao completa posterior. Mantidas validacoes de geracao, contexto, posse e limpeza de candidatos obsoletos.

Export server mx-freeroam-vehicles:PreviewMetrics() retorna contadores created, removed, loaded, reused e unchanged (desde inicio do recurso). Compare antes/depois de navegar: created/removed/loaded devem permanecer constantes. Nao ha logs por quadro.

## Apresentacao
Barras finas globais com trilho discreto, thumb normal/hover/ativo e gutter estavel nos paineis verticais. Mantidos autoscroll e teclado.
Camera principal usa heading, comprimento e largura reais: frente/esquerda, altura 1.25m e FOV48; parametros em resources/[mx]/mx-freeroam-experience/config.lua, ExperienceConfig.framing. Cameras contextuais preservadas. Personagem usa wheel_rf valido, fallback de comprimento/largura, afastamento lateral 0.85m e consulta de solo; heading igual ao carro. Posicao recalculada ao mudar a apresentacao e reaplicada ao alterar personagem.
Clique sintetizado de ruido filtrado, envelope curto de22ms, ganho baixo e intervalo minimo65ms centralizado; sem audio de render/foco programatico. Acoes sem opcao ativa e limites de valores nao disparam clique no menu lateral.

## Verificacao
- Build com TypeScript e Vite aprovado; analise estrutural npm run check aprovada. Nao existe script ESLint.
- 45 arquivos Lua analisados;93 verificacoes de regras/experiencia/camera e30 do controlador com natives simuladas; fila LatestPreview aprovada.
- Playwright em1280x720,1920x1080,2560x1440 e3440x1440: teclado, selecao, valores, autoscroll, retorno e composicao. Novo teste alterna as cinco abas principais repetidamente e exige zero chamadas preview/resetPreview/cosmetic. Verifica estilo WebKit da barra.
- Inspecao visual do editor renderizado em1280x720. Capturas em docs/evidence; fundo de fixture sem cena GTA.
- Testes novos do controlador comprovam identidade da entidade, zero carga/criacao em pedido identico e zero criacao/remocao em configuracao diferente do mesmo modelo.

## Pendente no FiveM
Nao foi executado cliente de jogo nesta entrega. Validar enquadramento em compactos/coupes/SUVs e diferentes headings/resolucoes, wheel_rf e solo em assets personalizados, ausencia de clipping e espaco do personagem; timbre/volume do clique no CEF; cameras contextuais/foco/controles; alternancia de abas e contadores em sessao real; trocas rapidas, respostas atrasadas, fechamento durante carga, reinicio, reconexao e persistencia confirmada. Testes com natives simuladas e fixtures NUI nao validam rede, entidades ou cameras no FiveM. Nenhuma nova verificacao SQL foi executada, pois persistencia e schema nao mudaram.
