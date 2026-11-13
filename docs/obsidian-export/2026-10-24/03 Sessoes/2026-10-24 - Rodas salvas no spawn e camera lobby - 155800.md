# Rodas salvas no spawn e câmera do lobby — 24/10/2026

Projeto: Drift server FiveM, C:\FiveM\drift-server. IA: Codex. Origem: proprietário confirmou edição de diâmetro funcionando, relatou aplicação visual tardia no spawn e enviou nova câmera.

Confirmado no código: capabilities.inspect percorre famílias de rodas depois de aplicar stance, restaurava índices sem reafirmar escala. Refresh só escrevia tamanho/largura se getters fossem diferentes. Corrigidos os dois pontos: refresh após descoberta e reaplicação visual dos fatores personalizados/aceitos, mesmo com getters iguais. Baseline imutável e guards existentes preservados; sem alterar dados salvos.

Câmera principal do lobby atualizada: posição (-944.5,-3535.3,14.5), rotação (-2,0,51), look (-948.794,-3531.823,14.307), FOV 73.5. Poses atuais do lobby e câmera da garagem preservadas.

Suíte completa/check aprovados, nova integração real de stance+descoberta exercita reset apenas visual, frio/quente e identidade com natives simulados. Câmera verificada pelo teste existente. Sem restart, FiveM, banco ou NUI. Próximo passo: carregar/reconectar e confirmar dimensão já no spawn, sem tocar no menu Suspensão; conferir câmera.

Relatório: docs/stance-spawn-2026-10-24.md. Apenas export local verificado; memória Obsidian compartilhada sem escrita permitida.
