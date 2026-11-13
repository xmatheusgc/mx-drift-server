# Câmeras automáticas pela direita

Os observadores dos enquadramentos automáticos de peças ficam no semiplano direito do veículo, independentemente do heading. As vistas genéricas de laterais, saias, interior e rodas também miram o lado direito; as rodas usam `wheel_rf` e `wheel_rr`. Alvos específicos, como porta e para-lama esquerdos, mantêm sua identidade, com observação pela direita. A porta direita abre automaticamente na vista de interior.

Não foram alterados a posição do personagem, as cenas de lobby/garagem, os limites de distância/FOV ou os controles da câmera livre.

Validação: suíte Lua/Fengari e verificações estáticas aprovadas, incluindo geometria em diferentes headings/dimensões, observador à direita em todos os slots e abertura da porta correta. As natives são simuladas nesses testes. A visibilidade de peças do lado oposto, colisões com o cenário e enquadramento de veículos modificados ainda precisam ser conferidos no FiveM; a câmera livre permite ajustar a visão manualmente.
