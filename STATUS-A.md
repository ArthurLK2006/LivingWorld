11/11/2026 19:41 (Brasília) · LW-093 PARTE 6 PRONTA: ramo `lw-093i-comprar-e-vender`: ações `buy`/`sell`, `NpcTrade`, conclusão da ação na economia e `eat` pelo inventário (sem escolha pelo pensador ainda); `check_all` VERDE (149 scripts, 1.314 testes), hashes e `run_sim` iguais; seguindo para a parte 7 (utilidade derivada do `buy` no pensador)

# RELATÓRIO — Fase B, correções (T1, T1b, T2), junção e LW-093 (partes 1 a 3)     Status: PARCIAL (PARADA: as ações `buy` e `sell` esbarram em testes existentes)

## 1. RESUMO
A Fase B está feita (status no `main`, `d1d3d8b`). As três correções foram juntadas no ramo `lw-092g-juncao-das-correcoes`, com `check_all` VERDE. A LW-093 avançou em três partes empilhadas sobre a junção: o NPC abre a conta na economia ao nascer (marco 2 de hash, valores que você aprovou), o dinheiro inicial nasce na abertura da conta com `request_consume`, e o jogo real passa a receber as definições da economia. **Parei antes das ações `buy` e `sell`**: acrescentá-las ao catálogo derruba 3 testes existentes que só você pode autorizar a trocar (item 7). As tarefas seguintes do marco 2 (LW-094, 095, 096 e 096a) não foram iniciadas.

## Declaração de leitura
- **Li:** `AGENTS.md` v0.4; a linha da LW-093 no roadmap; `docs/modules/economy.md` (consumo, comércio, produção, tabela de testes); `docs/modules/npc.md` 14.2 a 14.8; o item Q-W4 do `docs/modules/world.md`; os testes que citam `market_reserved` e as listas fechadas de ações e condições. **Decisões conferidas em `DECISIONS.md`:** DEC-145, 147, 153, 160, 163, 167, 168, 170 e 175, todas APROVADAS. **Não li** o GDD nem a arquitetura inteiros.

## 2. ARQUIVOS CRIADOS / 3. MODIFICADOS (por parte)
- **Junção `lw-092g` (`9df6aaa`):** merges de `lw-092d`, `lw-092e` e `lw-092f` sobre o `main` `d1d3d8b`. Conflito só em `economy_module.gd` e no `README.md` da economia: o `peek_quote(actor_id, ...)` e a tarifa da 092e foram para a classe de apoio onde a 092f os colocou (`EconomyQueries.peek_quote`; a tarifa fica no `TradeEngine`, que a 092f não moveu). **Único ajuste de teste:** no meu próprio teste novo da 092e (`test_trade_tariff_and_actor.gd`) o jogador (dono 3) passou a ter conta aberta, porque a cotação com ator passou a conferir que o ator existe (092d). Nenhum teste existente no `main` foi alterado.
- **Parte 1 `lw-093-contas-dos-npcs` (`35cfae0`):** `npc_lifecycle.gd`, `npc_module.gd` (porta `EconomyModule` pelo construtor, opcional), `game_modules.gd`, os 9 valores do oráculo e `test_npc_economy_account.gd` (2 testes). Mesmo conteúdo do ramo antigo `lw-093-npcs-no-mercado` (`fe97377`, do `main`), refeito sobre a junção aplicando o mesmo diff; **o ramo antigo ficou como está (não posso apagar ramos) e está obsoleto.**
- **Parte 2 `lw-093d-dinheiro-e-consumo` (`3bbcd60`):** `request_open_owner` faz o `mint` `game_start` do saldo inicial do tipo quando o dono é novo; `request_consume(owner_id, good_id, quantity)` novo (`support/economy_commands.gd`, `ConsumeResult`, código `ECON_NOT_CONSUMABLE`); `test_economy_start_money_and_consume.gd` (3 testes).
- **Parte 3 `lw-093e-jogo-real-com-economia` (`49a602b`):** `GameApp` lê o `EconomySetup`, `SimulationHost.start_new_game(..., economy_setup)` o entrega ao `GameModules` e guarda o módulo `economy`; `docs/modules/app.md`; `test_game_economy_wiring.gd` (2 testes). No jogo real nascem os mercados (IDs 1 e 2), os NPCs começam no ID 3 e cada um abre conta com 60.
- Branch local `lw-093c-dinheiro-inicial-e-consumo`: vazio, sem push, descartado (também não posso apagá-lo).

## 4. DECISÕES TÉCNICAS
- Mint do dinheiro inicial dentro de `request_open_owner` (contrato 3.4), só para dono novo; mercados e locais de produção continuam recebendo o saldo na própria economia (`on_new_game`). Nenhum teste existente quebrou com isso.
- `request_consume` devolve também o `need_id` além do alívio (o `npc` precisa saber qual necessidade aliviar; a economia não conhece necessidades). O código `ECON_NOT_CONSUMABLE` é novo (o contrato deixa os códigos como [PROPOSTA]).
- O host recebe `economy_setup` como último parâmetro opcional; quem não passa continua com a economia sem definições (os testes que só precisam do `npc` e o oráculo não mudam).
- **Proposta de entrada para `DECISIONS.md` (I4; numeração provisória DEC-234, faixa da A; NÃO editei o `DECISIONS.md`):** *Título:* exceção pontual à DEC-107 e ao AGENTS 4.17: a economia lê `npc_id` do `NpcDied` pelo nome do campo. *Contexto:* a DEC-132 manda a economia nunca importar o `npc` e a DEC-146 manda fechar o dono ao ouvir `NpcDied`; para cumprir as duas, o `EconomyModule` assina `"NpcDied"` por texto e lê `event.get("npc_id")`, leitura por nome que a DEC-107 (DESCARTADA) e o AGENTS 4.17 proíbem. *Decisão proposta:* uma exceção única e nomeada: a economia pode ler um único campo inteiro (`npc_id`) do evento, com o tipo conferido (`TYPE_INT`); nenhuma chamada dinâmica, carga de código nem outro uso de reflexão; qualquer outra leitura por nome exige outra DEC. *Justificativa:* cumpre a DEC-132 e a DEC-146 sem mudar o `npc`; o risco (renomear o evento ou o campo sem erro de compilação) está coberto por `test_a_dead_npc_is_closed_by_the_event_and_keeps_money_and_goods_in_the_sum`, que usa o `NpcDied` real. *Consequências:* `docs/events.md` já diz "[PROPOSTA]" na linha do evento (trocar pelo número); revisar na LW-093 em diante, quando o `npc` puder chamar `request_close_owner` (opção b, sem reflexão).

## 5. TESTES EXECUTADOS (`tools/check_all`, resultados reais)
| Ponta | Ramo / commit | Scripts | Testes | Asserts | Resultado |
|---|---|---|---|---|---|
| Fase B (status) | `d1d3d8b` | 142 | 1.293 | 292.694 | VERDE (EXIT 0; 0 SCRIPT ERROR; "nove verificações aprovadas"; `run_sim` `732907967efd…`) |
| Junção | `lw-092g` `9df6aaa` | 144 | 1.298 | 292.805 | VERDE; hashes e `run_sim` iguais |
| Parte 1 | `lw-093-contas-dos-npcs` `35cfae0` | 145 | 1.300 | 292.817 | VERDE; hashes novos do marco 2 (abaixo); `run_sim` igual |
| Parte 2 | `lw-093d` `3bbcd60` | 146 | 1.303 | 292.859 | VERDE; hashes iguais aos da parte 1; `run_sim` igual |
| Parte 3 | `lw-093e` `49a602b` | 147 | 1.305 | 292.968 | VERDE; hashes iguais aos da parte 1; `run_sim` igual |
Também VERDES nos ramos T1 `lw-092d` (143 / 1.296), T1b `lw-092e` (143 / 1.295) e T2 `lw-092f` (142 / 1.293), relatados antes. Zero avisos de compilação em todas as pontas. **Controles de mutação:** parte 2, 6 mutações, todas pegas; as da parte 1 e da junção foram feitas antes (junção: o teste ajustado acima foi achado ao juntar).

## 6. RESULTADOS: valores de referência do marco 2 (antigo → novo, causa)
**Causa única (provada):** o bloco `economy` do save passa a ter as contas dos NPCs. **Prova:** numa cópia temporária do oráculo tirei o bloco `economy` do hash e os 9 valores ORIGINAIS (`6e12b3067120`, `506a4a23ce89`, `7008d3b19d38`, `84ca55684e34`, `ce14b1e45954`, `142733eb318f`, `00794d5a27b6`, `3e1d080d2eed`, `f9469ccc5a9d`) voltaram; desfeito e conferido com `cmp`. Só as 9 constantes do oráculo foram trocadas (9 linhas no diff).
| Constante | Antigo (marco 1) | Novo |
|---|---|---|
| `intents` | `223b8ec6a7ed` | `8670b52b8ff6` |
| `alarm` | `dfe616868618` | `b62628f049b0` |
| `resumed` | `db2469cec836` | `1251aaf06e2d` |
| `switches` | `888b1962d83b` | `6889619788b5` |
| `talk` | `8b04890c8c9b` | `a8a97e95f464` |
| `save` | `5673e2b3911b` | `781066cec584` |
| `demote` | `62c86fea8233` | `ed884fc6fb21` |
| `starved` | `52c2d24b40fc` | `f11a33ea9ab0` |
| `real_game` | `edf6ebb03cb9` | `76a65b9cfc8a` |
Soaks (só imprimem; o teste do soak de 30 dias não tem constante): vida de 7 dias `af5bdb5e1f21` → `d7266f48286e`; 300 NPCs `52b7851aefc0` → `f31f5186abf5`; 30 dias `82f81b239759` → `706f065740c5`. `run_sim` (`--days 30 --seed 1`): `732907967efdba5f718687a0bbafbfe102ac51cabc9d15a7f0119a9e64ebc4d7`, **igual** em todas as partes. As partes 2 e 3 não mudaram nenhum valor (o oráculo e os soaks não passam pelo host e usam a economia sem definições).

## 7. PROBLEMAS ENCONTRADOS E PARADA
- **As ações `buy` e `sell` (e o renomear `market_reserved` para `market`, DEC-160) quebram testes existentes que eu não posso alterar sem autorização.** Evidência: acrescentei só `buy` a `data/actions.json` numa cópia temporária (desfeita, `cmp` ok) e `test_action_catalog.gd` ficou com 3 falhas: a lista exata de ids das ações, a contagem 11 contra 12 e "nenhuma ação usa o mercado-reservado". Outros testes fixam o nome antigo ou as listas fechadas e precisariam mudar junto: `test_action_catalog.gd` (a lista de tipos de local, a lista de condições, linhas 103, 109 e 174), `test_place_chooser.gd` (linhas 32 e 201: o `PlaceChooser` recusa `market_reserved`), `test_settlements_data.gd` (linha 91), `test_place_boxes.gd` (linhas 39, 54 e 74) e `test_routine.gd` só se o vocabulário mudar. **Preciso da sua autorização escrita, com a lista exata de testes e linhas.**
- **Decisão de design que o contrato não fecha:** o `eat` consome do inventário (14.3) mas o `FoodStub` só sai na LW-094. Proponho: na LW-093 o `eat` come do inventário quando o NPC tem comida e, senão, do `FoodStub` (que segue de reserva até a LW-094). Preciso do seu "sim" ou de outra regra.
- Rede caiu uma vez durante um push; repeti e funcionou. O ramo antigo `lw-093-npcs-no-mercado` e o local vazio `lw-093c-dinheiro-inicial-e-consumo` ficam, porque não posso apagar ramos.

## 8. RISCOS
- A LW-093 completa ainda tem: ações `buy` e `sell` com utilidade derivada (alívio da necessidade menos preço e distância), condições novas ("tem dinheiro para", "tem o bem"), `eat` pelo inventário e o renomear do tipo de local; depois LW-094, 095, 096 e 096a. Cada uma muda o comportamento do NPC no jogo real e mexe nos hashes do marco 2 (já aprovados com esta causa); o oráculo só será refeito se mudar pela causa aprovada.
- Dinheiro inicial dos NPCs só vale no jogo real (partes 2 e 3); sem `buy` o NPC ainda não tem como gastar.

## 9. PENDÊNCIAS (suas)
1. Autorizar, por escrito, a troca dos testes existentes listados no item 7 (ou mandar outro caminho para as ações).
2. Dizer se o `eat` deve comer do inventário e, senão, do `FoodStub` até a LW-094.
3. Registrar a DEC do I4 (proposta no item 4, DEC-234 provisória); autorizar o ajuste do caso `reply.gd` para fechar o N9 (T1, item pendente).
4. O `README.md` do projeto ainda diz 88 de 192.

## ACOMPANHAMENTO
- **Avanço:** LW-093 (parte do comércio): contas, dinheiro inicial, consumo e jogo real prontos; faltam as ações e a utilidade. Marco 2 aberto, valores aprovados.
- **Git:** `main` em `d1d3d8b` (só o commit de status); ramos enviados: `lw-092d`, `lw-092e`, `lw-092f`, `lw-092g`, `lw-093-contas-dos-npcs`, `lw-093d-dinheiro-e-consumo`, `lw-093e-jogo-real-com-economia` e o `status-a`. Sem tag, sem `--force`, sem rebase nem reset; `stash` não foi necessário.
