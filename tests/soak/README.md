Medições e simulações longas, sem janela. Hoje: `run_sp1` e `run_sp1_release` (spike SP1, núcleo da simulação), `compare_sp1_runs` (compara execuções do SP1), `run_sp5` (spike SP5, salvamento) e o código descartável em `sp1/` e `sp5/`. Os resultados estão em `docs/decisions/0004` e `0005`. Uso: seção 10 do `README.md` da raiz.

## Medição do jogo em release (LW-053A)

`run_game_release` mede os **quadros do jogo** (a cena principal real, com janela) no binário de **release**, que roda uma cópia do projeto com `tests/soak/game_release/game_release_main.tscn` como cena principal (a troca é feita só na cópia do `project.godot`; o do repositório não muda). Mesmo método do `run_sp1_release`: modelos de exportação oficiais do Godot 4.7.2 (~1,28 GB, SHA-512 conferido, só o binário de release do macOS é extraído e o download é apagado), `.pck` exportado com o Godot do editor e binário de release com o `.pck` ao lado, tudo em `$HOME/lw-release-probe` (nada em `~/Library`; a pasta não é apagada no fim).

Cada execução faz três ensaios, um depois do outro, e imprime média, mediana, percentil 99, pior quadro (sem os 3 primeiros), quadros acima de 16,7 ms e de 33 ms (com o instante de cada um), nós e chunks no começo, meio e fim, e as linhas "build de depuração: sim/não" e "Renderização: driver e método" (para provar o tipo de build): **rota** de 60 s a 7 m/s para o leste pelo caminho (entrada por ações do `InputMap`), **parado** por 30 s com o HUD visível e **pausado** por 30 s. O script de medição (`game_release_node.gd`) é de teste: usa o relógio do sistema só para medir e não acelera o relógio do motor nem muda valor do jogo. O script de terminal recusa rodar fora da tomada (`pmset -g batt` precisa dizer `AC Power`) e confere de novo no fim de cada execução; um quadro de mais de 1 s acusa possível suspensão do Mac.

```bash
tests/soak/run_game_release              # 3 execuções em release (cerca de 8 minutos, com janela)
tests/soak/run_game_release --editor     # a mesma medição no binário de DEPURAÇÃO do editor (a cena vai na linha de comando)
```

Variáveis: `RUNS` (3), `ENSAIOS` (`rota,parado,pausado`), `GODOT_BIN`, `KEEP_DOWNLOAD`. Deixe a janela em primeiro plano e não use o Mac durante a medição. A cópia do projeto sai do `git archive HEAD` (só o que está commitado). Os resultados de cada medição entram no relatório da tarefa que a fez.
