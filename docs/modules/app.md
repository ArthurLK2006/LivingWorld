# Contrato — app

Estado: **parcial (LW-020)**. Existe a lógica do `SimulationHost` em `SimulationRunner`; o autoload ainda não foi registrado.

- **Responsabilidade:** criar o mundo e avançá-lo (hoje sem janela). Ordem de cada passo: relógio avança 1 minuto, `Scheduler.step()` roda os módulos, `EventBus.dispatch()` entrega os eventos.
- **Entradas:** semente do mundo; módulos registrados antes de `start_new_game()`; tempo real do quadro (`advance_frame`).
- **Saídas:** `World` pronto e rodando; `describe_state()` (data simulada, módulos, problemas de validação).
- **Dependências permitidas:** `core`.
- **Interfaces:** `SimulationRunner.new(seed)`, `register_module`, `start_new_game`, `step_once`, `run_steps`, `run_days`, `advance_frame(delta_ms)` (teto `MAX_TICKS_PER_FRAME` = 60 **[HIP]**: acima disso os passos são descartados e o mundo desacelera), `finish`. `tools/run_sim --days N --seed S` roda sem janela e sai com 0 se o mundo validar.
- **Autoload:** o nome `SimulationHost` fica reservado ao autoload futuro (um `Node` fino sobre o `SimulationRunner`); por isso a classe tem outro nome. Confirmado em teste descartável (Godot 4.7.2) que um autoload é acessível a partir de `-s` (linha de comando). **Pendente:** registrar o autoload em `project.godot` (arquivo protegido; novo autoload exige autorização de Arthur).
- **Testes:** `tests/unit/test_simulation_runner.gd` e `tests/test_run_sim.sh` (30 dias, argumento inválido, dias negativos).
