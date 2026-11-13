# Teleporte direto para pistas — 2026-10-18

Confirmar o nome em Pistas > Categoria agora envia uma única requisição `world/travel {destination}`. Removido o submenu de escolha a pé/com carro. O servidor consulta o ped e seleciona automaticamente a entidade: a pé, move o personagem; dirigindo o próprio veículo gerenciado, leva o carro. A escolha legada `withCar` de clientes antigos não determina o modo desta rota. As regras existentes de motorista/propriedade e desembarque de outros passageiros continuam validadas pelo servidor.

O erro de colisão vinha de `loadCollision`, que exigia `HasCollisionLoadedAroundEntity` antes de aceitar pistas configuradas. O callback de viagens agora usa o mesmo princípio dos checkpoints: solicita streaming com `RequestCollisionAtCoord`, aplica posição/rotação e restaura o congelamento anterior, sem usar o carregamento da colisão como condição de aprovação. Falhas reais de natives restauram a posição local; falha de confirmação restaura a posição no servidor e libera a reserva.

O servidor aguarda até dois segundos pela replicação da posição, em vez de uma espera fixa de 500 ms. Antes de confirmar ou restaurar posição verifica sessão e identidade da entidade. Destinos não aprovados, assets indisponíveis e vagas ocupadas continuam bloqueados. O fluxo inicial de spawn e a entrada/saída da oficina mantêm suas verificações próprias.

Build, typecheck, check estático e regressões Lua aprovados. Os testes executam os módulos reais com adaptadores: pista/checkpoint sem colisão carregada, falha real de native, restauração de congelamento, ida a pé/com carro escolhida no servidor mesmo com payload legado contrário, passageiros/motorista, vagas e rollback/repetição. A fixture de distância do teste de viagens foi corrigida para calcular distância geométrica, em vez de herdar um stub constante de outro domínio.

O teste de browser verifica confirmação direta por teclado, uma única chamada sem `withCar` e ausência do submenu intermediário. As evidências são `track-direct-teleport-<resolução>.png` e o relatório `ui.json` após conclusão da suíte.

Não foi executado cliente FiveM nem reinício do servidor. Falta verificar streaming/colisão real dos mapas de pista, replicação e teleporte com controle físico. Solicitar streaming sem esperar a colisão não comprova que cada asset já esteja pronto ao chegar. As coordenadas continuam sendo responsabilidade da configuração em `resources/[mx]/mx-freeroam-world/tracks-config.lua` e dos pontos administrativos persistidos.
