# Contrato — nome do módulo

- **Responsabilidade:**
- **Entradas:**
- **Saídas:**
- **Dependências permitidas:**
- **Dados controlados:**
- **Interfaces de comunicação:** consultas, comandos, eventos publicados e ouvidos.
- **Testes necessários:**

**Regra de determinismo e salvamento (vale para todo módulo que guarda estado):** o Godot preserva a ordem de inserção dos `Dictionary`, mas o JSON do save volta com as chaves ordenadas, então a ordem "natural" muda depois de carregar. Por isso a ordem de um `Dictionary` nunca decide nada (quem recebe o próximo sorteio, desempate, primeiro da fila): visite sempre por IDs ou chaves ordenadas, ou guarde a coleção em lista ou `Packed*Array`. Chaves salvas são texto; todo número volta do JSON como decimal e é convertido para inteiro em `on_load`; sorteio só por `ctx.rng`, em fluxo nomeado; o relógio e a entrega de eventos não são do módulo (`advance_step`, `set_paused`, `set_speed` e `dispatch` são do `core` e do `app`, e o `check_architecture` reprova o resto). Módulo com `Dictionary` copia o teste-modelo `tests/unit/test_dictionary_order_after_load.gd` (módulo-canário em `tests/fixtures/world/dictionary_canary_module.gd`): ele prova que salvar e carregar no meio muda o hash quando se visita pela ordem natural e não muda quando se visita por chaves ordenadas.
