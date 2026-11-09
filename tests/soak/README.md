Medições e simulações longas, sem janela. Hoje: `run_sp1` e `run_sp1_release` (spike SP1, núcleo da simulação), `compare_sp1_runs` (compara execuções do SP1), `run_sp5` (spike SP5, salvamento) e o código descartável em `sp1/` e `sp5/`. Os resultados estão em `docs/decisions/0004` e `0005`. Uso: seção 10 do `README.md` da raiz.

## Medição do jogo em release (LW-053A)

`run_game_release` mede os **quadros do jogo** (a cena principal real, com janela) no binário de **release**, que roda uma cópia do projeto com `tests/soak/game_release/game_release_main.tscn` como cena principal (a troca é feita só na cópia do `project.godot`; o do repositório não muda). Mesmo método do `run_sp1_release`: modelos de exportação oficiais do Godot 4.7.2 (~1,28 GB, SHA-512 conferido, só o binário de release do macOS é extraído e o download é apagado), `.pck` exportado com o Godot do editor e binário de release com o `.pck` ao lado, tudo em `$HOME/lw-release-probe` (nada em `~/Library`; a pasta não é apagada no fim).

Cada execução faz três ensaios, um depois do outro, e imprime média, mediana, percentil 99, pior quadro (sem os 3 primeiros), quadros acima de 16,7 ms e de 33 ms (com o instante de cada um), nós e chunks no começo, meio e fim, e as linhas "build de depuração: sim/não" e "Renderização: driver e método" (para provar o tipo de build): **rota** de 60 s a 7 m/s para o leste pelo caminho (entrada por ações do `InputMap`), **parado** por 30 s com o HUD visível e **pausado** por 30 s. O script de medição (`game_release_node.gd`) é de teste: usa o relógio do sistema só para medir e não acelera o relógio do motor nem muda valor do jogo. O script de terminal recusa rodar fora da tomada (`pmset -g batt` precisa dizer `AC Power`) e confere de novo no fim de cada execução; um quadro de mais de 1 s acusa possível suspensão do Mac.

```bash
tests/soak/run_game_release              # 3 execuções em release (cerca de 8 minutos, com janela)
tests/soak/run_game_release --editor     # a mesma medição no binário de DEPURAÇÃO do editor (a cena vai na linha de comando)
```

Variáveis: `RUNS` (3), `ENSAIOS` (`rota,parado,pausado`), `GODOT_BIN`, `KEEP_DOWNLOAD`. Deixe a janela em primeiro plano e não use o Mac durante a medição. A cópia do projeto sai do `git archive HEAD` (só o que está commitado). Os resultados de cada medição entram no relatório da tarefa que a fez.

**Corpos dos NPCs e custo por seção (LW-072g).** O jogo agora liga os corpos (LW-072f), então os três ensaios já rodam com a `NpcBodiesView` e o `NpcBodyDriver` ligados, e cada ensaio imprime uma linha a mais, "custo por seção, em ms por quadro (média / pior)": `NpcBodiesView`, `NpcBodyDriver` e o "resto do quadro" (o quadro menos as duas seções; o acumulador é `frame_sections.gd`, testado em `tests/unit/test_npc_frame_sections.gd`). Para medir, o script desliga o `_process` da view e o `_physics_process` do motorista e os chama ele mesmo, com o relógio de parede em volta e no mesmo ritmo. O ensaio novo **`povoado`** (30 s) religa o relógio (o `pausado` o deixa parado, e pausado ninguém vira S0), leva-o às 6h45 (só passos da simulação), põe o jogador no centro do povoado A e mede com os NPCs saindo de casa; o relatório mostra os corpos no começo, no meio e no fim e o máximo (no teste sem janela deu 50). O `run_game_release` não inclui o `povoado` por padrão: peça com `ENSAIOS=rota,parado,pausado,povoado tests/soak/run_game_release`. A régua é a DEC-119 (média de 60 quadros por segundo ou mais e nenhum quadro acima de 33 ms, no Mac na tomada, em release).

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

## Corpos contra o gêmeo sem corpos (LW-072h)

`run_npc_bodies_7d` roda, sem janela, **7 dias de jogo** do mesmo mundo em três modos (semente 11, os 100 NPCs reais, o jogador parado no centro de A, 40 NPCs de A promovidos a notáveis para existir consequência social): SOLO (nada em volta), S1 (corpos desligados, amostrado a cada minuto) e S0 (corpos ligados, o `NpcBodyDriver` levando os 50 NPCs mais perto a 4 m/s vezes a velocidade do relógio). A velocidade 8 do relógio só encurta a medição (o corpo anda os mesmos 5 m por minuto de jogo em qualquer velocidade) e a corrida leva cerca de um minuto. Imprime uma tabela S1 contra S0: ações canceladas por causa, o `rest` aplicado nos sonos cancelados, a diferença final das necessidades, o atraso do `DONE` e do `ARRIVED`, os Intents vencidos por caminhada longa, memórias e relações, e se o S1 gêmeo tem o mesmo hash do S1 sozinho. Só usa consultas (`peek_*`): não edita o `npc`. A versão curta (1 dia, no `tools/check_all`) é `npc_bodies/test_npc_bodies_twin.gd`. **[LIM]** o jogador fica parado; o efeito aplicado só é medido para o sono (o das outras ações se mistura com o `IncomeStub`); as necessidades finais são levadas ao último minuto sem o resto da conta (ruído de 1); a 8x o passo de física do corpo é maior (0,53 m).

```bash
tests/soak/run_npc_bodies_7d
```
