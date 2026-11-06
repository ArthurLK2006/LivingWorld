Módulo `app`. Contrato em `docs/modules/app.md`.

Implementado: `simulation_runner.gd` (lógica do mundo; LW-020), `simulation_host.gd` e `game_app.gd` (scripts dos autoloads `SimulationHost` e `GameApp`; LW-020 e LW-021). LW-036: `request_pause` e `request_speed` no host. LW-044: `input_actions.gd` (nomes das ações de entrada; as teclas ficam no `[input]` do `project.godot`) e a pausa do `GameApp` pela ação `pause`. LW-037B: `GameAppNode.peek_bridge()` cria (na primeira chamada, lendo o terreno de `data/world`) e guarda a `SimBridge`; sem autoload novo.
