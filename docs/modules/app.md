# Contrato — app

Estado: **LW-020 e LW-021 concluídas**. `SimulationRunner` tem a lógica; `SimulationHostNode` e `GameAppNode` são os scripts dos autoloads `SimulationHost` e `GameApp`.

- **Responsabilidade:** criar o mundo e avançá-lo (hoje sem janela). Ordem de cada passo: relógio avança 1 minuto, `Scheduler.step()` roda os módulos, `EventBus.dispatch()` entrega os eventos.
- **Entradas:** semente do mundo; módulos registrados antes de `start_new_game()`; tempo real do quadro (`advance_frame`).
- **Saídas:** `World` pronto e rodando; `describe_state()` (data simulada, módulos, problemas de validação).
- **Dependências permitidas:** `core`.
- **Interfaces:** `SimulationRunner.new(seed)`, `register_module`, `start_new_game`, `step_once`, `run_steps`, `run_days`, `advance_frame(delta_ms)` (teto `MAX_TICKS_PER_FRAME` = 60 **[HIP]**: acima disso os passos são descartados e o mundo desacelera), `finish`. `tools/run_sim --days N --seed S` roda sem janela e sai com 0 se o mundo validar.
- **Autoloads (registrados em `project.godot` com autorização de Arthur):** `SimulationHost` (`SimulationHostNode`): dono do mundo atual; `start_new_game(seed)` e `advance(delta_segundos)` repassam ao `SimulationRunner`; em `_process` avança a simulação. `GameApp` (`GameAppNode`): inicia um mundo de desenvolvimento (semente 1, provisória), monta `status_text()` (título, versão provisória `0.0.1-dev`, data simulada, velocidade ou PAUSADO, tecla), emite o sinal `status_changed(text)` só quando o texto muda e trata a tecla Espaço (`handle_key`) para pausar e continuar. Os nomes das classes diferem dos nomes dos autoloads porque não podem coincidir. A lista de autoloads é conferida pelo `check_architecture` (só `GameApp`, `SimulationHost`, `Debug`, `Settings`).
- **Apresentação:** `scenes/main.tscn` ganhou um `CanvasLayer` com um `Label` (`src/presentation/ui/status_overlay.gd`) que só exibe o texto do `GameApp`. Nenhum 3D novo. Limitação: a apresentação lê o `GameApp` diretamente porque a ponte (`bridge`) só existe na LW-036.
- **Testes:** `tests/unit/test_simulation_runner.gd`, `tests/test_run_sim.sh` (30 dias, hash, argumentos inválidos), `tests/unit/test_app_nodes.gd` (host, texto de estado, pausa, tecla, sinal, cena com os autoloads reais) e `tests/test_main_scene.sh` (cena por 60 quadros sem erro e `smoke_test`).
