# Posições, câmeras e idles dos menus

Data local: 24/10/2026, aproximadamente 12:30, America/Sao_Paulo. Projeto: C:\FiveM\drift-server. IA: Codex. Origem: coordenadas do proprietário, esclarecimento sobre câmera e implementação/testes locais.

Aplicados quatro pontos independentes (personagem/veículo no lobby e garagem) enviados pelo usuário. Personagem deixa de ser reposicionado pelo tamanho do carro ou virado automaticamente à câmera. Confirma chão/colisão sem substituir XYZ/heading fixos; o clone mantém a posição. Saída de gameplay preservada.

Usuário não forneceu câmera absoluta; pediu proximidade e altura menor. Configurados offsets iniciais 3.8 frente, 3.1 direita e .85 acima da origem do carro, FOV 60. Enquadramento por projeção ajusta apenas distância horizontal para mostrar personagem e carro. Câmeras de detalhes mantidas.

Adicionadas variações masculinas/femininas por ped/clone real, quatro candidatos livres por sexo, alternância 18–32 s sem repetição consecutiva, blend1.5, loop/translação bloqueada. Pose feminina de parede fica configurável/desabilitada sem apoio. Carregamento não bloqueia cena; dicionário/clipe/start inválido gera diagnóstico e fallback/pose neutra. Pausa em rosto/personagem/modal e limpeza em mudanças/saída. Motorista invisível não recebe idle. mxworkshopdebug inclui animação.

Suíte completa e check aprovados. 111 testes novos de poses/enquadramento/idle com natives simulados e regressão da função real de colocação do cliente. Sem mudança de NUI/rebuild/browser, cliente FiveM, restart ou alteração de dados. Aceite visual/solo/interseções e animações reais pendentes.

Próximo passo: restart/reconexão e teste lobby/garagem, male/female, ciclos de idle, customização e carro grande. Relatório: docs/menu-poses-idles-2026-10-24.md; JSON correspondente em docs/evidence. Nota de projeto exportada atualizada com tabela de coordenadas.

Registro somente no export do workspace; Obsidian compartilhado não atualizado por restrição de escrita.
