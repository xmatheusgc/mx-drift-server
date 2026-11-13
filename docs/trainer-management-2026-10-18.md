# Trainer: controles, pistas e administração

Atualização 24/10/2026: adicionados **Administração → Coordenadas e heading** (personagem/veículo/câmera, painel contínuo, captura vector3/vector4/tabela e inspeção) e **Teleporte administrativo** (coordenadas/heading e marcador). Teleporte exige a nova ACE mx.teleport, concedida ao group.mxadmin na configuração. Detalhes, formatos e limites de validação em [admin-coordinates-teleport-2026-10-24.md](admin-coordinates-teleport-2026-10-24.md).

## Uso

O menu continua sem captura do mouse. Ordem: **Meu veículo → Pilotagem livre → Pistas → Voltar para a garagem → Jogadores → Preferências → Controles → Administração**. A última opção só aparece para administradores autorizados. Os indicadores de velocidade, marcha e RPM agora são elementos separados. Os diagnósticos administrativos também foram separados por recursos, veículos, apresentações e sessões.

**R repara o veículo**, usando o serviço existente que valida motorista e posse no servidor e permite reparo em movimento. M, F2, F3, F4 e F7 continuam como padrões para menu, noclip, checkpoint, retorno e câmera de condução.

Em **Controles**, escolha uma função e configure **Tecla do teclado** ou **Botão do controle**. Há opções próprias para remover cada atribuição; funções sem atalho também podem receber um. A gravação é imediata, em KVP do cliente, separada pelo ID do perfil. Não altera preferências ou personalizações existentes no banco. `/mxmenu` continua disponível mesmo se a tecla de abrir o menu for removida.

Teclas aceitas: A–Z, 0–9, F1–F12, exceto F8, SHIFT, SPACE e TAB. Enter, Esc, Backspace e setas permanecem reservados à navegação. Não há combinações com modificadores. Botões aceitos: LB/L1, RB/R1, LS/L3, RS/R3, A/cruz, B/círculo, X/quadrado, Y/triângulo e direcional. Digite os nomes Xbox apresentados no editor; os indicadores do noclip adaptam os nomes ao dispositivo. Atalhos de controle executam com o menu fechado; dentro dele permanecem o direcional, confirmar e voltar. No noclip, os padrões são A/cruz para velocidade, RB/R1 para subir, direcional abaixo para descer e direcional direito para orientação. Todos esses quatro atalhos podem ser removidos ou alterados.

Há 18 ações atribuíveis: menu; reparar, limpar, desvirar, motor, portas e parar veículo; garagem; recuperar a pé; noclip, velocidade, subir, descer e orientação; criar, retornar e remover checkpoint; câmera de condução. Ações administrativas e ações dirigidas a um jogador continuam em seus menus, com alvo, motivo e confirmação. W/S e A/D/analógico são controles de movimento do jogo. O editor rejeita duplicidades dentro do trainer e não desassocia teclas de outros recursos. Recursos externos ainda podem usar a mesma tecla; a integração física de teclado e controle precisa ser conferida no FiveM.

## Pistas

Configuração manual: `resources/[mx]/mx-freeroam-world/tracks-config.lua`. Foram preservados os destinos e slots anteriores, inclusive `meet`, usado como ponto inicial. Para adicionar:

```lua
minha_pista={
    id='minha_pista', name='Minha pista', category='Touge',
    validated=true, radius=100,
    slots={{x=163.2,y=-3024.11,z=6.05,h=268.29}}
},
```

As coordenadas acima são apenas um exemplo de estrutura. Use coordenadas da sua pista e teste o local antes de marcá-lo como validado. `asset='nome-do-resource'` é opcional. Pontos sem validação continuam sujeitos ao `mx_allowDrafts` existente; assets indisponíveis desabilitam o destino.

**Administração → Criar ponto de pista aqui** solicita nome e categoria. Somente a posição e o heading sincronizados no servidor são usados; coordenadas fornecidas pelo cliente não são aceitas. A captura exige mundo aberto e permissões administrativas. O ponto é publicado imediatamente na lista de Pistas, por categoria, e gravado em `resources/[mx]/mx-freeroam-world/teleports.json`. IDs `custom_*` evitam substituir os pontos estáticos. Reabra a lista para atualizá-la. Este fluxo cria teleporte; não cria checkpoints de competição nem modifica o comando `mxtrack` existente.

## Administração e persistência

Exige ACE **mx.admin** e a permissão específica: **mx.warn**, **mx.kick**, **mx.ban**, **mx.content**, ou as permissões de diagnóstico já existentes. O `config/server.cfg` concede essas permissões a `group.mxadmin`. Associe a identidade do administrador a esse grupo na configuração local de permissões. Ser administrador do painel txAdmin, isoladamente, não concede automaticamente essas ACEs do jogo.

Em **Jogadores**, administradores autorizados podem enviar aviso, expulsar ou banir permanentemente, sempre com motivo e confirmação. O servidor valida alvo, identidade estável, sessão administrativa e permissões novamente após a gravação da intenção em `audit_log`. Bloqueia automoderação e alvos com ACE `mx.admin`. A interface não concede autorização. Pedidos diretos às rotas também são verificados.

Banimentos ficam em `resources/[mx]/mx-freeroam-admin/bans.json`, indexados pela licença da plataforma. O arquivo é escrito e relido antes de expulsar o alvo. Falha de gravação não resulta em mensagem de banimento confirmado. Na conexão, o core consulta o contrato `admin:CheckConnection`; a regra de banimento pertence ao domínio administrativo. Moderação indisponível ou arquivo inválido bloqueiam novas conexões com mensagem de erro. Console ou administrador com `mx.admin` + `mx.ban` pode remover o banimento usando `mxunban license:identificador`.

**Inclua `bans.json` e `teleports.json` nos backups** e preserve-os ao atualizar os resources. São dados operacionais ignorados pelo Git, sem distribuição aos clientes. Não foi necessária migration SQL; `audit_log` já existe e permanece utilizado. Os arquivos novos só aparecem depois da primeira gravação real. Testes não escrevem banimentos ou pistas operacionais.

## Jogador temporário

`config/development.cfg` habilita **setr mx_menuTestPlayer 1**. O jogador **[TESTE] Piloto temporário** é uma fixture local explícita; silenciar, rota e moderação só simulam resultado. Não utiliza um source numérico nem chama serviços reais de moderação. As opções administrativas permanecem condicionadas às permissões reais de quem testa. Desative com **setr mx_menuTestPlayer 0**; o padrão sem configuração é desativado. Não há jogador sintético conectado ao servidor nem registro falso no banco.

## Verificação e limites

- `npm --prefix development run build`: TypeScript e bundle de produção.
- `npm --prefix development run typecheck` e `run check`: tipos, manifests, dependências e limites de módulos; não há script de lint separado.
- `npm --prefix development test`: suites existentes e regressões executando os módulos reais de moderação, teleporte e bindings com adaptadores de natives/KVP/disco. Cobrem ACE, fonte reutilizada, sessão alterada, administrador protegido, falha de disco, restauração após recarga, remoção de bind e rejeição de comandos injetados.
- Browser Chromium: menu por teclado, reatribuição e remoção de atalhos, função sem bind padrão, categorias de pistas, diagnóstico separado, formulários de criação, moderação simulada sem RPC real e aviso sobre alvo real da fixture. Quatro resoluções: 1280×720, 1920×1080, 2560×1440 e 3440×1440. Transporte simulado explicitamente.

Não foi executado cliente FiveM nem reiniciado o servidor ativo. Pendentes: R em movimento com autoridade de rede real; persistência KVP após reiniciar o cliente; alternância física teclado/controle e possíveis conflitos externos; criação/teleporte em mapas carregados; warning/kick/ban e reconexão com duas contas reais; recuperação de gravação e export entre resources no runtime Cfx. Nenhuma expulsão, aviso ou banimento real foi executado durante o desenvolvimento.

Referências técnicas oficiais: [bindings do Cfx](https://docs.fivem.net/docs/cookbook/2020/01/06/using-the-new-console-key-bindings/), [estado de tecla pressionada](https://github.com/citizenfx/fivem/blob/master/ext/native-decls/IsRawKeyPressed.md) e [tecla mantida](https://github.com/citizenfx/fivem/blob/master/ext/native-decls/IsRawKeyDown.md). O registro próprio de ações usa os estados de tecla e KVP; evita executar `unbind`, que poderia remover comandos de outros recursos.
