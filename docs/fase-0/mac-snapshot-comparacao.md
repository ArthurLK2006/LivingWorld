# Comparação (só leitura) entre `mac-snapshot` e o ramo de trabalho

Feita em 02/11/2026 com `git fetch origin mac-snapshot` e `git diff`/`git log` sobre `origin/mac-snapshot` e `origin/claude/living-world-coordination-umft1k`. **Nenhum dos dois ramos nem a `main` foi alterado.** A junção fica para depois do fechamento da Fase 0.

## Resumo
- `mac-snapshot` é **um único commit** (`f1a9192`, "snapshot do trabalho local do Mac, não revisado") em cima de `95bc4c4` (LW-012). O ramo de trabalho tem 29 commits em cima do mesmo ponto (na hora da comparação eram 27).
- O snapshot é uma **implementação paralela do núcleo** (cerca de 510 linhas em `src/`, 6 arquivos de teste), feita antes do ramo de trabalho (cerca de 1886 linhas em `src/`, 16 arquivos de teste de unidade, mais dados, salvamento e spikes).
- O `ROADMAP_STATUS.md` do snapshot já marca LW-013 a LW-022 como "concluída", e a LW-023 como "bloqueada"; é uma segunda versão da verdade que precisará ser reconciliada.

## O que é DUPLICADO (mesma função, implementada nos dois)
| Assunto | No snapshot | No ramo de trabalho |
|---|---|---|
| IDs, resultado, relógio, barramento de eventos, módulo/contexto, mundo, agendador | `src/core/ids.gd`, `result.gd`, `sim_clock.gd`, `event_bus.gd`, `sim_module.gd`, `sim_context.gd`, `world.gd`, `scheduler.gd` (arquivos planos) | `src/core/ids/`, `clock/`, `event_bus/`, `world/`, `scheduler/` etc. (subpastas), mais testes extensos |
| Gerador aleatório | `src/core/rng/world_rng.gd` (52 linhas) | `src/core/rng/world_rng.gd` (129 linhas, fluxos por SHA-256, estado salvo como texto) |
| Host, runner, app | `src/app/simulation_host.gd`, `simulation_runner.gd`, `game_app.gd` | os mesmos nomes, com outro conteúdo |
| `run_sim`, hash de estado | `tools/run_sim(.gd)`, `tests/unit/test_world_hash.gd` | `tools/run_sim(.gd)`, `World.state_hash()` |
| Autoloads | `project.godot` (+5 linhas: `SimulationHost`, `GameApp`) | idem (mesmas duas linhas) |
| Regras do `check_architecture` (autoload e catálogo de eventos) | duas verificações novas | regras 5 e 8 (equivalentes) |
| Medição do SP1 | `tests/spikes/sp1_benchmark.gd` + `docs/decisions/0003-sp1-medicao-preliminar.md` | `tests/soak/sp1/` + `docs/decisions/0004-spike-sp1-nucleo-da-simulacao.md` |

**Arquivos com o MESMO CAMINHO nos dois ramos (conflito certo numa junção):** `docs/ROADMAP_STATUS.md`, `docs/events.md`, `docs/modules/core.md`, `project.godot`, `scenes/main.tscn`, `src/app/game_app.gd`, `simulation_host.gd`, `simulation_runner.gd`, `src/core/result.gd`, `rng/world_rng.gd`, `sim_context.gd`, `sim_module.gd`, `tests/test_check_architecture.sh`, `tests/unit/test_scheduler.gd`, `test_simulation_runner.gd`, `tools/check_architecture`, `tools/run_sim`, `tools/run_sim.gd`. Além disso, há **colisão de numeração** em `docs/decisions/0003` (dados no ramo de trabalho; SP1 preliminar no snapshot).

## O que é ÚNICO do snapshot
- **Ponte e tela inicial:** `src/bridge/initial_bridge.gd` (um `Node` que lê o `SimulationHost` e monta o texto "Dia N · hh:mm · estado") e `src/presentation/initial_status.gd` (um `Label` que mostra "Living World · v0.1", o estado e "Esc: pausar"). Equivalem, de forma mínima, ao que o ramo de trabalho faz com `GameApp` + `StatusOverlay` (tecla Espaço), mas **já separam apresentação e ponte** (o ramo de trabalho leu o `GameApp` direto, por não ter ponte). Antecipam parte da LW-036.
- **Experimento de terceira pessoa:** `experiments/third_person/` (`player.gd`, `third_person.tscn`, `README.md`): personagem com mouse, WASD e pulo, descartável, "não conclui as tarefas LW-045 ou LW-046". Observação de regra: `experiments/` é uma **pasta de topo nova** (AGENTS 5.7 exige autorização) e antecipa a Fase 1.
- **Medições de release no Mac** (em `0003-sp1-medicao-preliminar.md`): 5 execuções em release sem nenhum passo acima de 10 ms (máximo 468 µs) e execuções de editor com picos de 24 a 42 ms (e 87,7 ms na primeira), com uma simulação mais leve que a do ramo de trabalho. É o dado mais valioso do snapshot para a LW-023.
- `tests/spikes/sp1_benchmark.gd` (benchmark do SP1 em outra pasta), `tests/unit/test_core_foundation.gd`, `test_core_lifecycle.gd`, `test_world_hash.gd`.

## O que é ÚNICO do ramo de trabalho (não existe no snapshot)
Leitor e validador de dados (LW-024/025) e pasta congelada; codec de save, migração e armazenamento com backups (LW-026/027); spikes SP3 e SP5; laço de controle, comparador de picos e script de release; filtro de ruído de ambiente; contratos de módulo e README atualizados; pacote da LW-029, resumo da LW-030 e rascunho da LW-031.

## Pontos a decidir depois do fechamento da Fase 0 (sugestões, não ações)
1. **Qual núcleo manter:** o do ramo de trabalho é mais completo e testado; o do snapshot é enxuto. Recomendo manter o do ramo de trabalho e trazer do snapshot só o que é único.
2. **Trazer:** as medições de release (como registro), a separação ponte/tela inicial (candidata à LW-036) e, se Arthur quiser, o experimento de terceira pessoa (fora de `experiments/`, na Fase 1).
3. **Reconciliar:** `ROADMAP_STATUS.md`, `events.md` e a numeração de `docs/decisions/`.
