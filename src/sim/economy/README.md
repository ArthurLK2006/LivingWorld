Módulo `economy` (camada 3). Contrato em `docs/modules/economy.md`. Pastas planejadas, como na arquitetura 11.1: `api/` (porta de entrada), `goods/`, `markets/`, `production/`, `trade/`, `consumption/`, `ledger/`, `contracts/` e `rules/`; cada uma só nasce na tarefa que a usa. `owners/` (o cadastro de donos) é de apoio do contrato (seções 2 e 3).

Implementado (LW-088a, 11/11/2026): a casca, `EconomyModule`. O `GameModules` a registra no `World` ANTES do `npc` (ordem `character`, `economy`, `npc`), porque o `npc` vai abrir as contas dela. O save ganhou o bloco `economy` (marco 1 de hash, DEC-172 e DEC-175).

Implementado (LW-088b, 11/11/2026): o `OwnerBook` (`owners/`: quem existe, de que tipo e se está fechado) e o `Ledger` (`ledger/`: contas, `transfer`, `mint` e `burn` com motivo de um conjunto fechado, totais por motivo, conservação; histórico completo só em modo de teste), com os códigos de erro em `EconomyCodes` (`api/`).

Implementado (LW-088c, 11/11/2026): o save do cadastro e do livro (`serialize`/`load_from`, com `EconomyJson` para ler números e chaves do JSON) e a porta. O `EconomyModule` mora agora em `api/` e tem `request_open_owner`, `peek_balance`, `peek_conservation` e `peek_ledger_totals` (cópias em `EconomyReplies`); as operações de saldo NÃO são da porta. O bloco `economy` do save só ganha conteúdo quando há dono ou movimento: sem isso continua `{}`, e o hash do jogo não muda. O `on_load` recusa qualquer chave desconhecida (`ECON_INVALID_SAVE`).

Implementado (LW-089, 11/11/2026): os dados dos bens e dos tipos de dono (`data/economy/goods.json` e `owner_kinds.json`; os valores [HIP] ficam em dados) e, em `goods/`, `GoodDef`, `OwnerKindDef` e o `GoodsLoader` (valida e monta; falha com `ECON_DATA_INVALID`, arquivo, item e campo). Ainda NÃO estão ligados ao módulo.

Implementado (LW-089b, 11/11/2026): o `GoodsStore` (`goods/`): a quantidade de cada bem por dono do `OwnerBook`, peso total até a capacidade do tipo, criar e destruir bens só com motivo de um conjunto fechado (`produced`, `game_start`; `consumed`, `maintenance`, `spoiled`), mover sem criar nem destruir, conservação por bem e save. 

Implementado (LW-089c, 11/11/2026): o `EconomyModule` recebe as definições (`EconomyDefinitions`, bens e tipos de dono) pelo construtor e liga o `GoodsStore`: `request_open_owner` confere o tipo contra as definições, e a porta ganha `request_transfer_goods`, `peek_inventory` e `peek_goods_conservation` (cópias em `EconomyReplies`). O módulo ouve `NpcDied` pelo NOME do evento (a economia não cita o `npc`) e fecha o dono do NPC morto; o saldo e os bens dele continuam na soma. O bloco `goods` só entra no save quando há bens. Criar e destruir bens e dinheiro continua só das partes internas. O jogo ainda cria o módulo SEM definições (os mercados da LW-090 as ligam).

Regras de arquitetura (`tools/check_architecture`): regra E (DEC-171 e DEC-132), o `npc` cita só classes de `economy/api/` e a `economy` não cita nada do `npc`; regra F (LW-088c), só `ledger/` escreve saldo.

Planejado, ainda não existe: mercados e preço (LW-090) e o resto do contrato.
