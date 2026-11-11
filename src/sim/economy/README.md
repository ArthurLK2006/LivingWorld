Módulo `economy` (camada 3). Contrato em `docs/modules/economy.md`. Pastas planejadas, como na arquitetura 11.1: `api/` (porta de entrada), `goods/`, `markets/`, `production/`, `trade/`, `consumption/`, `ledger/`, `contracts/` e `rules/`; cada uma só nasce na tarefa que a usa.

Implementado (LW-088a, 11/11/2026): a casca, `EconomyModule` (`economy_module.gd`), sem estado, dado, evento nem comportamento. O `GameModules` a registra no `World` ANTES do `npc` (ordem `character`, `economy`, `npc`), porque o `npc` vai abrir as contas dela. O save ganha o bloco vazio `economy`, o que muda o `state_hash` de todo jogo (marco 1 de hash, DEC-172 e DEC-175). O `on_load` aceita só o bloco vazio e recusa o resto com `ECON_INVALID_SAVE`. A `api/` está vazia (só um README) até existir a primeira consulta ou comando.

Regra de arquitetura (DEC-171 e DEC-132; `tools/check_architecture`, regra E): o `npc` cita só classes de `economy/api/`, e a `economy` não cita nada do `npc`.

Planejado, ainda não existe: o `Ledger` (LW-088), bens e inventário por dono (LW-089), mercados e preço (LW-090) e o resto do contrato.
