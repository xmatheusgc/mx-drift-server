# Dimensões salvas das rodas no spawn — 24/10/2026

Origem: o proprietário confirmou que consegue editar diâmetro, mas relatou que o valor só parece ser aplicado ao interagir com a suspensão após spawn, principalmente na garagem. Não houve acesso a cliente FiveM para reproduzir visualmente.

## Causa tratada

Na ordem real de `vehicles/apply`, a stance era aplicada antes da descoberta de capacidades. A primeira descoberta de cada modelo em `VehicleCustomization.inspect` percorre as 13 famílias de rodas, restaurando família/índices ao terminar. A escala personalizada não era reaplicada nesse ponto. Além disso, o refresh de stance só chamava setters se os getters diferissem dos valores esperados, o que não cobre um reset apenas da malha visual.

Agora `inspect` chama `VehicleStance.refresh` após concluir/restaurar a descoberta, antes de retornar as capacidades. Isso também ocorre depois dos passos de apresentação/assentamento e banco do motorista no callback de spawn. O refresh reafirma diâmetro/largura personalizados e aceitos nas rodas modificadas, mesmo com getters numericamente iguais. Usa a mesma baseline original; não multiplica dimensões já modificadas. Mantidos os guards de identidade, modelo, dimensões positivas, rodas modificadas e campos indisponíveis.

A manutenção continua no loop local já existente para veículos ativos próximos; não adiciona consulta SQL/RPC ou redescoberta de famílias a cada frame. O fluxo de confirmar/salvar e os fatores persistidos não foram alterados.

O [vStancer, WheelModScript.cs](https://github.com/carmineos/fivem-vstancer/blob/master/VStancer.Client/Scripts/WheelModScript.cs), em `UpdateVehicleUsingData`, também reafirma tamanho/largura sem depender de diferença do getter. Referência consultada; nenhum código/resource importado. A [referência Cfx do setter](https://github.com/citizenfx/fivem/blob/master/ext/native-decls/SetVehicleWheelSize.md) mantém a limitação a rodas de personalização.

## Câmera do lobby

Aplicado o novo bloco enviado pelo proprietário em `ExperienceConfig.mainCameras.lobby`:

```lua
{position={x=-944.500,y=-3535.300,z=14.500},rotation={x=-2.00,y=0.00,z=51.00},look={x=-948.794,y=-3531.823,z=14.307},fov=73.50}
```

As posições mais recentes de personagem/veículo do lobby e o preset da garagem continuam configurados como aprovados.

## Verificação

Suíte completa e check aprovados. Nova regressão `development/tests/stance-spawn.lua` executa os controladores reais de stance e descoberta com natives simulados: 13 famílias na descoberta fria, cache quente, restauração de família/índice e dimensões visuais, reset de malha com getters ainda corretos, refresh sem composição de fatores e proteção de identidade reutilizada. A regressão da câmera verifica a nova posição/rotação/FOV.

Sem NUI alterada/rebuild, banco, restart ou FiveM. Próximo passo: reiniciar/reconectar e conferir a roda imediatamente ao aparecer no lobby/garagem e no carro de gameplay, sem abrir Suspensão; testar também retorno ao veículo/reparo. As simulações não comprovam o resultado visual real.

Memória apenas no export local; base Obsidian compartilhada fora da permissão de escrita.
