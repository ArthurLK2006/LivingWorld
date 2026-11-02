# Backlog

Ideias fora do escopo atual entram aqui com o que é, por que importa e onde surgiu. Uma ideia só vira tarefa por decisão de Arthur.
- Regra no `check_architecture` que proíba chamar `SimClock.advance_step()` fora de `core` e `app`, para garantir que só o `SimulationHost` avance o relógio. Surgiu na LW-017 (SimContext).
- Textos da interface (`GameApp.status_text`) por chave de tradução (`tr`), como recomenda a arquitetura 16.4; hoje o texto de desenvolvimento está fixo em português. Surgiu na LW-021.
- Semente do mundo novo e versão do jogo definidas por tela de novo jogo e por `application/config/version`; hoje são constantes provisórias do `GameApp`. Surgiu na LW-021.
- Módulo de NPCs real: dar a cada NPC uma fase própria e fixa de pensamento, para não formar ondas; o módulo de teste do spike SP1 junta 818 dos 1.000 NPCs no mesmo passo a cada 99 passos. Surgiu na análise dos picos do SP1.
