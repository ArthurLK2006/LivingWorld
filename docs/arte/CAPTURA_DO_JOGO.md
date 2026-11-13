# Captura do jogo real (CAP)

**Status:** ferramenta de desenvolvimento para o aceite visual da arte (praça de mercado, atmosfera). Feita e testada SEM janela; a primeira captura de verdade precisa de janela e da autorização de Arthur. Não altera o jogo nem o `project.godot`.

## O que é
Abre o JOGO REAL (`scenes/main.tscn`, Compatibility, 1280 x 720), põe o jogador num local, força a hora do dia e a câmera, espera 30 quadros de acomodação e mede 180, e grava um PNG e as medidas da captura (fps médio, pior quadro, chamadas de desenho, primitivos, objetos, memória de vídeo, saturação e brilho médios), como a demonstração de renderizadores.

## Comando (abre uma janela do Godot por cerca de 1 a 3 minutos com os padrões; não mexa nela)
`tools/visual/run_game_capture [pasta-de-saída] [opções]` (sem pasta: uma nova sob `$TMPDIR`). Opções, separadas por vírgula:
- `--spots=market:a_market_01,spawn,xz:<x>,<z>`: onde o jogador fica. `market:<id>` é a posição do mercado lida da ponte; `xz:` são metros; `spawn` é o ponto de nascimento. Padrão: `market:a_market_01,spawn`.
- `--hours=12,17.5,19`: horas de 0 a 24 (exclusive); é o padrão. Às 19h a luz já é a da noite.
- `--cams=near,iso,strategic`: `near` 5 m e 12 graus, `iso` 22 m e 50, `strategic` 60 m e 70 (distância e ângulo da demonstração); é o padrão.

## Saída
`<pasta>/<hora>_<local>_<câmera>.png` (como `17h30_a_market_01_near.png`) e `<pasta>/resumo.txt` (renderer, janela, opções e uma linha de medidas por captura). Erro: mensagem no terminal e saída diferente de zero. Sem janela (`--headless`) recusa; a execução inteira tem limite de 15 minutos.

## Como funciona
O `PlayerBody` é movido pelo nó (o relato à ponte e o foco do terreno seguem sozinhos); espera a fila do terreno esvaziar (limite de 1200 quadros); a hora é forçada com `AmbientRig.apply_state(DayNightCycle.state_at(...))` com o `_process` do rig desligado; a câmera recebe distância, ângulo e giro pelas propriedades públicas.

## Limites
- Precisa de janela e de renderer de verdade; só a captura de imagem não é testada sem janela (`tests/unit/test_game_capture.gd` cobre o resto, inclusive o jogo montado sem desenhar).
- Mede o jogo INTEIRO (terreno, decoração, NPCs, HUD), não a praça isolada: o fps é "o jogo nessa vista".
- O HUD e a cápsula do jogador aparecem na imagem; o HUD e a simulação seguem a hora do jogo (que nasce à meia-noite), só a luz é forçada; NPCs se movem entre capturas.
- Código em `tools/visual/game_capture/` (reaproveita `RendererAutoRun` da demonstração).
