Atualização 17/10/2026: [teclado e mouse, Customizar, ações visíveis, câmeras e suspensão](customization-input-stance.md). Este incremento prevalece para input, F9/F10, rolagem e presets de câmera descritos anteriormente.

Incremento atual de lobby/garagem/câmeras: [implementação, contratos, evidências e validações pendentes](lobby-navigation.md). Schema 006; entrada inicial pelo lobby. Esta nota prevalece para esses fluxos sobre descrições anteriores.

Atualização de interface/entidades de 16/10/2026: [interface-rework.md](interface-rework.md) prevalece para os novos controles, coordenadas temporárias, fluxo de prévias e evidências de UI. Os aceites de jogo continuam pendentes.

Atualização 16/10/2026: o roteiro de entrada/personagem/garagem agora é o de [experience.md](experience.md). As verificações anteriores abaixo ficam como histórico do escopo inicial. Para recuperar a oficina use Tentar novamente/F6; mxrespawn continua dedicado ao respawn do mundo, não ao onboarding.

# Verificação

## Evidências executadas

`npm run build`: TypeScript strict e bundle Vite local. `npm run check`: manifests, fronteira do core, versões fixadas, ausência de física e integração interna não exposta à rede. `npm test`: análise sintática dos 32 arquivos Lua próprios e 43 checks de regras em Fengari. Os testes cobrem finitude, schema, mods proibidos, assinatura, transições, direção/interseção, filtragem de presença, convites, níveis, direitos e fronteiras de períodos.

`npm run test:db`: migrations repetidas, identidade única, consulta privada, CAS e recuperação de preset/preferência em outra conexão **SQL real**. Não simula cliente FiveM. `tests/restore.mjs`: dump/restore real com comparação integral de dez tabelas. Os dados de fixture e bancos de restore ficam isolados da aplicação. [Resultado do restore](evidence/restore.json).

`npm run test:ui`: browser real, sem API falsa. Envia mensagens de apresentação ao shell, confirma erro de desconexão, ajuda, abertura/fechamento e limites de viewport em 1920×1080, 2560×1440 e 3440×1440. [Resultado](evidence/ui.json), imagens `evidence/nui-*.png`. Isso não verifica foco nativo Cfx ou gamepad.

`node tests/run-lua.mjs --load`: 20 identidades sintéticas, 600 snapshots e 240 mil decisões usando a regra real de filtro. Nenhum pacote enviado, nenhum cliente de jogo. Hardware/motor/duração no [relatório sintético](evidence/load.json); não interpretar esse tempo como resmon/Cfx ou estimativa da rede.

## Testes dentro do FXServer

Foi usado FXServer 37175/OneSync, oxmysql 2.14.3 e MariaDB 10.4.32. Oito resources próprios e pma-voice iniciaram; core confirmou schema e activities confirmou configuração. [Boot de testes](evidence/boot.json), [boot da configuração entregue com usuário limitado](evidence/boot-delivered.json). Os testes de domínio são executados por exports reais no runtime, com fixtures SQL explicitamente rotuladas. Nenhum jogador, movimento ou corrida foi fabricado como prova de gameplay.

Em **banco de teste**, acrescente `ensure mx-verification` ao perfil de teste. O resource recusa bancos fora de `mx_freeroam_test*`. No console:

```text
stop mx-freeroam-progression
mxtest prepare
ensure mx-freeroam-progression
mxtest process
mxtest revoke
stop mx-freeroam-progression
restart mx-freeroam-activities
ensure mx-freeroam-progression
mxtest replay
```

Aguarde a conclusão de cada fase antes da próxima. Não use `process` após `revoke`; use `replay` para conferir que o saldo continua compensado. O relatório da última sequência está em [fxserver-tests.json](evidence/fxserver-tests.json): resultados com progressão parada, ausência de prêmio antecipado, rota válida versus drift/inválido, reprocessamento, semanal/expiração, recibos, conquista, cosmético autorizado/bloqueado, compensações, retirada de conquista, rollback de transação e restart sem repremiar. A query inválida de FK é intencional nesse teste e deve produzir um erro de transação seguido de PASS de rollback.

## Primeiro marco I0–I2 — ainda exige cliente

| Passo | Conferir | Estado |
| --- | --- | --- |
| Entrar na base nova | Deferral carrega identidade única; loading screen encerra; spawn seguro; introdução | Pendente FiveM client |
| F1/F2/Escape/controle | Navegação, foco só no texto, fechar libera controles/cursor | Pendente FiveM client |
| Escolher Futo original | Carro server-created, UUID distinto de net ID, assento e propriedades confirmados | Pendente FiveM client |
| Preview / cancelar | Cores, mods, extras, rodas, livery e snapshot compatíveis com o modelo | Pendente FiveM client |
| Aplicar e salvar | Salva somente estado confirmado; retorno após commit; limite/revisão/dono | SQL/regra testados; client pendente |
| Desconectar e reconectar | Mesmo perfil/preferências/favoritos/preset, entidade anterior limpa, destino seguro | SQL reconectado; reconexão FiveM pendente |
| Spawn duplicado | BUSY/DUPLICATE/cooldown e uma entidade ativa; preservar anterior no timeout | Código/regras; client pendente |
| Preset alheio / revisão obsoleta | NOT_FOUND/CONFLICT; nenhuma leitura ou escrita de outro dono | SQL testado; evento real pendente |
| Banco indisponível | Entrada recusada ou erro explícito; sem perfil vazio/sucesso falso | Transação rollback testada; interrupção de serviço com client pendente |

Use `/mxrespawn` para repetir entrada após resolver um erro inicial/colisão e aguardar a reserva expirar; o servidor recusa respawn arbitrário de um personagem já inicializado e vivo. Não marcar o marco jogável como aprovado só porque esta tabela tem código correspondente.

## Dois clientes

Todos os cenários abaixo estão **pendentes**, pois nenhum client FiveM estava conectado:

1. Entradas/spawns simultâneos, colisão/slot, passageiro em substituição/viagem/limpeza e timeout de modelo/owner. Confirmar que ninguém é apagado ou transportado involuntariamente.
2. Migração de owner, preview/cancelamento/restart e restauração após reconexão. Confirmar mods/extras reais, sem valores não suportados.
3. Presença perto/longe/fora do streaming; source reutilizado; desconexão; `share=false`; filtros grupo/ninguém; mudança de bucket. Inspecionar payload, inclusive ausência de região/posição para não autorizados. Nenhum blip próprio/duplicado/fantasma.
4. Ícone/nível alterado e revogado; marcadores uniformes; prioridade cor de grupo > atividade > ícone; conferir legenda e atualização sem reconectar.
5. Convite recusado/expirado/repetido, preferências de contato, líder saindo, encontro com contagem, texto e voz normal/sussurro/grito. Conferir mute local e reset após reconexão.
6. Rota validada: largada legítima e antecipada, checkpoints ordenados/pulados/retorno, atalhos detectáveis, ping alto, teleport, reparo, mod alterado e troca de carro. Conferir motivos e resultado único persistido.
7. Duelo com modelos/preparações iguais e diferentes, contagem coordenada, ghosting só entre participantes, empate, duas aceitações, desistência/desconexão e limpeza de ambos. Nunca converter inválido em tempo válido.
8. Treino drift com início/fim, duração/distância e amostras técnicas; ao sair, parar coleta. Confirmar ausência de ranking oficial/XP por drift.
9. Parar progressão com corrida em andamento e voltar: resultado continua durável e processa uma vez. Revogar resultado pelo admin; ranking e concessões devem refletir a retirada.
10. Chamar cada ação admin como usuário comum, diretamente pela rede/console de client. ACE precisa negar; botão escondido é apenas apresentação.
11. Restart de menu/social/vehicles/activities com foco, passageiros e duelo ativos. Conferir liberação de NUI, freezes, ghosting, blips e journal. Core/oxmysql exigem política coordenada.

## Conteúdo e carga real

Verifique LSIA, Porto, Sandy, cada slot, colisão e cada recuperação no build fixado. Valide uma rota sem usar os carros/mapas antigos; só depois publique uma revisão e habilite desafio semanal. Assets adicionais exigem revisão de licença, modelo, colisão, peças e mapa. O catálogo vanilla elimina dependência desses packs para desenvolvimento, não valida conteúdo ausente.

Para baseline real, registre CPU/GPU/RAM, versão de client, FXServer, quantidade de jogadores, mapa e intervalo de amostragem. Meça 60 s parado com menu fechado, aberto, editando garagem, encontro, atividade e presença distantes. Use resmon/profiler client e server, média/picos e pacotes/bytes. Repita com dois clientes e depois 20 pessoas; rotule separadamente qualquer carga sintética. Não aumentar culling para esconder problemas de presença. Nenhuma medição real de ms/pacotes/voz foi realizada nesta entrega.
