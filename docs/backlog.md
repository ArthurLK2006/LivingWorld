# Backlog

Ideias fora do escopo atual entram aqui com o que é, por que importa e onde surgiu. Uma ideia só vira tarefa por decisão de Arthur.
- Regra no `check_architecture` que proíba chamar `SimClock.advance_step()` fora de `core` e `app`, para garantir que só o `SimulationHost` avance o relógio. Surgiu na LW-017 (SimContext).
