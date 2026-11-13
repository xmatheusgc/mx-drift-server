# Carros salvos: veículo em uso e foco de navegação

O carro em uso (`state.selected.id`) recebe a mesma etiqueta `EQUIPADO` das peças, no canto superior direito, com verde `#2FB449`. O texto antigo `EM USO` foi substituído pela etiqueta.

A prévia (`previewTarget`) não atribui mais a classe visual `selected` ao cartão salvo. O fundo branco e a ampliação acompanham o foco de navegação; mover o foco não muda o veículo em uso. Os fluxos de prévia, uso, edição e persistência permanecem intactos.

O teste de interface verifica que somente o veículo em uso tenha a etiqueta e que focar outro cartão deixe apenas esse cartão branco. As capturas ficam em `docs/evidence/saved-cars-equipped-*.png`. São verificações de interface em Chromium, sem validação de entidades no FiveM.
