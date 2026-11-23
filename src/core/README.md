Módulo `core` (camada 0). Contrato em `docs/modules/core.md`.

Implementado: `result.gd` (`Result`), `ids/id_generator.gd` (`IdGenerator`), `rng/world_rng.gd` (`WorldRng`), `clock/sim_clock.gd` (`SimClock`), `event_bus/` (`SimEvent`, `EventBus`), `sim_module.gd` (`SimModule`), `sim_context.gd` (`SimContext`), `world/world.gd` (`World`) e `scheduler/scheduler.gd` (`Scheduler`). O `SimulationHost` está em `src/app/`. LW-099b1: `SimClock.step_fraction()` devolve, só para leitura, a fração do minuto simulado já decorrida, em [0, 1) (não entra no save nem no hash).
