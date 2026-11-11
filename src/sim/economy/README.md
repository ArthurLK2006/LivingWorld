Módulo `economy` (camada 3). Contrato em `docs/modules/economy.md`. Pastas planejadas, como na arquitetura 11.1: `api/` (porta de entrada), `goods/`, `markets/`, `production/`, `trade/`, `consumption/`, `ledger/`, `contracts/` e `rules/`; cada uma só nasce na tarefa que a usa. `owners/` (o cadastro de donos) é de apoio do contrato (seções 2 e 3).

Implementado (LW-088a, 11/11/2026): a casca, `EconomyModule` (`economy_module.gd`), sem estado, dado, evento nem comportamento. O `GameModules` a registra no `World` ANTES do `npc` (ordem `character`, `economy`, `npc`), porque o `npc` vai abrir as contas dela. O save ganhou o bloco vazio `economy` (marco 1 de hash, DEC-172 e DEC-175).

Implementado (LW-088b, 11/11/2026): o `OwnerBook` (`owners/`: quem existe, de que tipo e se está fechado) e o `Ledger` (`ledger/`: contas, `transfer`, `mint` e `burn` com motivo de um conjunto fechado, totais por motivo, conservação; histórico completo só em modo de teste), com os códigos de erro em `EconomyCodes` (`api/`). São classes soltas: ainda NÃO estão ligadas ao `EconomyModule` nem ao save (isso é a LW-088c), então o jogo e o hash não mudam.

Regra de arquitetura (DEC-171 e DEC-132; `tools/check_architecture`, regra E): o `npc` cita só classes de `economy/api/`, e a `economy` não cita nada do `npc`.

Planejado, ainda não existe: o save do livro, a porta do módulo (`peek_balance`...) e a regra contra saldo fora do `Ledger` (LW-088c), bens e inventário por dono (LW-089), mercados e preço (LW-090) e o resto do contrato.
