Medições e simulações longas, sem janela. Hoje: `run_sp1` e `run_sp1_release` (spike SP1, núcleo da simulação), `compare_sp1_runs` (compara execuções do SP1), `run_sp5` (spike SP5, salvamento) e o código descartável em `sp1/` e `sp5/`. Os resultados estão em `docs/decisions/0004` e `0005`. Uso: seção 10 do `README.md` da raiz.

## Medição do jogo em release (LW-053A)

`run_game_release` mede os **quadros do jogo** (a cena principal real, com janela) no binário de **release**, que roda uma cópia do projeto com `tests/soak/game_release/game_release_main.tscn` como cena principal (a troca é feita só na cópia do `project.godot`; o do repositório não muda). Mesmo método do `run_sp1_release`: modelos de exportação oficiais do Godot 4.7.2 (~1,28 GB, SHA-512 conferido, só o binário de release do macOS é extraído e o download é apagado), `.pck` exportado com o Godot do editor e binário de release com o `.pck` ao lado, tudo em `$HOME/lw-release-probe` (nada em `~/Library`; a pasta não é apagada no fim).

Cada execução faz três ensaios, um depois do outro, e imprime média, mediana, percentil 99, pior quadro (sem os 3 primeiros), quadros acima de 16,7 ms e de 33 ms (com o instante de cada um), nós e chunks no começo, meio e fim, e as linhas "build de depuração: sim/não" e "Renderização: driver e método" (para provar o tipo de build): **rota** de 60 s a 7 m/s para o leste pelo caminho (entrada por ações do `InputMap`), **parado** por 30 s com o HUD visível e **pausado** por 30 s. O script de medição (`game_release_node.gd`) é de teste: usa o relógio do sistema só para medir e não acelera o relógio do motor nem muda valor do jogo. O script de terminal recusa rodar fora da tomada (`pmset -g batt` precisa dizer `AC Power`) e confere de novo no fim de cada execução; um quadro de mais de 1 s acusa possível suspensão do Mac.

```bash
tests/soak/run_game_release              # 3 execuções em release (cerca de 8 minutos, com janela)
tests/soak/run_game_release --editor     # a mesma medição no binário de DEPURAÇÃO do editor (a cena vai na linha de comando)
```

Variáveis: `RUNS` (3), `ENSAIOS` (`rota,parado,pausado`), `GODOT_BIN`, `KEEP_DOWNLOAD`. Deixe a janela em primeiro plano e não use o Mac durante a medição. A cópia do projeto sai do `git archive HEAD` (só o que está commitado). Os resultados de cada medição entram no relatório da tarefa que a fez.

## Teste de combate (LW-152, spike SP6)

`run_sp6` abre o jogo real **com janela** e, por cima dele, um teste **descartável** de combate por alvo e habilidades (DEC-117) contra um boneco de treino parado, para Arthur jogar e dizer o que sentiu. O código está em `sp6/`: regras puras (`Sp6Rules`), constantes **[HIP]** (`Sp6Constants`), geometria, boneco, tela e a cena `sp6_main.tscn`. O teste das regras, `sp6/test_sp6_rules.gd`, roda sem janela e entra no `tools/check_all`. Ao fechar a janela, o script imprime o resumo da sessão (golpes, erros, dano total, menor estamina e pior quadro). Valores, roteiro de playtest e resultado: `docs/decisions/0008-spike-sp6-combate.md`.

```bash
tests/soak/run_sp6
```

## Vida dos NPCs sem jogador (LW-068)

`run_npc_life_30d` roda, sem janela, os **100 NPCs do jogo por 30 dias de jogo** (o mundo real: `GameModules`, terreno, pontos e dados de `data/`, sem personagem) e confere os invariantes: todos vivos, necessidades de 0 a 100, comida de 0 ao teto a cada passo, ninguém sem ação por mais de uma hora, `validate()` limpo ao fim de cada dia, pensamentos por passo dentro do teto. Faz três execuções (direta, repetida com a mesma semente e com salvar e carregar no dia 15) e exige o mesmo hash nas três. Leva cerca de 1 minuto e imprime o resumo de cada execução (inclusive quantos minutos a comida ficou em zero). A versão curta, de 7 dias (`npc_life/test_npc_life_7d.gd`, cerca de 17 s), roda no `tools/check_all`; o verificador comum é `npc_life/npc_life_check.gd`. O arquivo da versão longa não começa com `test_` de propósito, para o GUT não o achar sozinho.

```bash
tests/soak/run_npc_life_30d
```

## Corpos e LOD de NPCs (LW-071, spike SP2)

`run_sp2` abre o jogo real e, por cima dele, um teste **descartável** com 100 NPCs que ganham corpo perto do jogador (S0) e voltam a ser dados longe (S1): pool de corpos, navegação N1 (reta) e N2 (grade A\*), políticas de velocidade P1 e P2, invariantes (duplicado, órfão, teleporte) e quadros. O código está em `sp2/` e monta um mundo próprio com os dados reais, porque o jogo ainda não liga o LOD nem o protocolo S0. O teste `sp2/test_sp2_logic.gd` roda sem janela e entra no `tools/check_all`. Modos: `--ver` (Arthur anda 3 minutos; teclas N, M, B e H), `--medir` (ensaios em depuração, só para comparar), `--release` (oficial: reaproveita o binário de `$HOME/lw-release-probe/bin`, não baixa nada) e `--headless` (só contadores). Resultado: `docs/decisions/0009-spike-sp2-corpos-e-lod.md`.

```bash
tests/soak/run_sp2 --release
```
