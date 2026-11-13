# Noclip, drift persistente e câmera nativa — 2026-10-18

O noclip podia ser encerrado pelo callback de parada durante `Wait(0)`. Ao retomar, a rotina acessava `current=nil` e morria. A próxima ativação ainda ocultava/congelava a entidade, mas não tinha rotina de movimento. A identidade agora aceita sessão ausente e o frame só processa uma sessão existente após a espera. Reativações usam a sessão atual; tokens encerrados continuam rejeitados. A restauração de colisão, visibilidade e congelamento permanece limitada às entidades desta sessão.

O binding SHIFT reconhece os códigos genérico, esquerdo e direito (16/160/161). Cada pressão avança um dos oito níveis de velocidade, como a referência do vMenu; manter pressionado não percorre continuamente os níveis. Remapeamento e remoção do atalho continuam respeitados. O controle mantém o botão configurado para velocidade.

## Persistência

A migration aditiva `007_vehicle_modes.sql` acrescenta `garage_presets.drift_enabled`, inicialmente 0. O core só verifica a versão da migration; as regras continuam em vehicles. Isso substitui a limitação anterior, documentada em vehicle-options-drift, de modo drift restrito à entidade ativa.

O veículo público mantém `presetId` separado de seu UUID de entidade. O toggle exige contexto autorizado pelo servidor, confirmação do cliente e confirmação SQL. Falha SQL restaura o estado anterior e solicita restauração ao cliente; falha de ACK não grava o novo modo. A sincronização `mxDrift` continua vinculada à identidade da entidade. Falhas de confirmação após um commit podem ter resultado durável incerto: o ID é mantido para que uma tentativa posterior reutilize a mesma criação.

O próximo spawn de uma criação relê seu modo no banco, inclusive quando a sessão da oficina contém uma cópia antiga. Recriar pelo trainer mantém o ID salvo; voltar à oficina recupera a criação correta pelo ID, mesmo com várias criações do mesmo modelo. Alterar cosméticos ou renomear não apaga a coluna independente nem muda a revisão cosmética por um toggle. Duplicar uma criação copia seu modo. A primeira ativação em um carro de sessão ainda não salvo cria uma única configuração na garagem, sujeita ao limite existente; toggles posteriores reutilizam esse registro. Os valores do preset e o recálculo de transmissão da entrega anterior foram preservados.

## Câmera cinematográfica

O domínio world desativa o botão cinematográfico e bloqueia `INPUT_VEH_CIN_CAM` (80, R/B) em cada frame. Também encerra uma câmera cinematográfica nativa já ativa. Não encerra as câmeras programadas da garagem ou drivecam. Ao parar o recurso, libera a política do botão. O atalho de reparo continua no registro de binds do menu.

## Verificações executadas

- `npm ... run build`, `run typecheck`, `run check` e `test`: aprovados. Não existe comando separado de lint no projeto; `check` executa as restrições estáticas.
- 67 arquivos Lua analisados. Regressões executam os módulos reais com adaptadores de natives/rede/SQL: parada entre frames e quatro ciclos de reativação, movimento posterior, restauração local, Shift genérico/esquerdo/direito e remoção do binding, bloqueio/liberação da câmera nativa, ACK e SQL com falha, recuperação de flag atualizada, vínculo de criação após respawn, duplicação e carro inicialmente sem registro.
- MariaDB real, banco isolado `mx_freeroam_test_modes20261018`: migration repetível, default desligado, escrita protegida por proprietário, ativação e desativação recuperadas em novas conexões, cosméticos preservados.
- Migration aplicada e repetida no banco local configurado. Comparação integral dos campos existentes de seis criações antes/depois sem alterações. Evidência: `evidence/noclip-drift-database-2026-10-18.json`. Nenhuma criação existente foi ativada automaticamente.
- NUI não foi alterada; build gerou os mesmos bundles. Não foi necessário repetir capturas do browser nesta entrega.

Não houve reinício do servidor nem execução de cliente FiveM. Ainda é necessário testar no jogo: ligar/desligar/religar noclip com carro e a pé, Shift físico, botões do controle, transparência/colisão e outros observadores; ativar drift, recriar, voltar à garagem, reconectar e reiniciar o servidor; desativar e repetir a recuperação; pressionar R dirigindo e verificar reparo sem câmera cinematográfica. Os testes SQL não equivalem a reconexão de cliente FiveM nem demonstram comportamento físico do handling.

Para carregar o código atualizado, reinicie o servidor pelo txAdmin e reconecte o cliente. A migration já foi aplicada neste ambiente. Em outra instalação, execute a migration com uma conta de migração antes de iniciar o novo core; não amplie as permissões SQL da conta de aplicação.

## Referências

- [vMenu Noclip.cs](https://github.com/TomGrobbe/vMenu/blob/legacy/vMenu/Noclip.cs): ciclo de níveis de velocidade e interação. Consulta de comportamento; nenhum código incorporado.
- [Cfx InputNatives.cpp](https://github.com/citizenfx/fivem/blob/master/code/components/extra-natives-five/src/InputNatives.cpp): diferença entre tecla mantida e borda de pressão.
- [Controles FiveM](https://docs.fivem.net/docs/game-references/controls/): ação 80 e conflito R/B.
- [SetCinematicButtonActive](https://github.com/citizenfx/natives/blob/master/CAM/SetCinematicButtonActive.md), [IsCinematicCamRendering](https://github.com/citizenfx/natives/blob/master/CAM/IsCinematicCamRendering.md) e [SetCinematicModeActive](https://github.com/citizenfx/natives/blob/master/CAM/SetCinematicModeActive.md): API nativa de câmera cinematográfica.
