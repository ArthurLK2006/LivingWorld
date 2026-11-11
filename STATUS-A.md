11/11/2026 18:57 (Brasília) · LW-093 PARTE 1 PRONTA sobre a junção: ramo `lw-093-contas-dos-npcs` (commit `35cfae0`): o NPC abre a conta na economia ao nascer; valores do marco 2 (aprovados) gravados nos 9 do oráculo; `check_all` VERDE (145 scripts, 1.300 testes), `run_sim` igual; seguindo para a parte 2 (dinheiro inicial e `request_consume`)

# RELATÓRIO — BLOCO 2 DA A: LW-088a (fechamento) e a economia do marco 1, LW-088 a LW-093a     Status: PRONTA PARA REVISÃO

## 1. RESUMO
Fechei a LW-088a (o 2º commit, com as três frases de documentação) e construí, em ramos empilhados, toda a economia do marco 1 até a LW-093a: o livro-razão do dinheiro (`Ledger`), os bens e o inventário, os mercados com preço em inteiros, o comércio (`request_trade`), os locais de produção (hora a hora, manutenção, eventos e save) e o verificador de ids de conteúdo dentro do `check_all`. **Nada disso muda o jogo de hoje:** o NPC ainda não usa a economia e a lista real de locais de produção (`production_sites.json`) está vazia até a LW-097. Cada ramo foi para o GitHub com `check_all` VERDE na sua ponta; o `main`, as tags e o `status-a` foram tratados como você mandou (só o `status-a` e os ramos desta fila foram enviados; nada no `main`). Dezesseis commits em 15 ramos, 141 scripts e 1.290 testes verdes no total; o `run_sim` ficou **igual** em toda a fila; a prova da causa dos hashes foi refeita no fim da LW-092 e deu certo (os 9 valores ORIGINAIS do oráculo voltam quando o bloco `economy` sai do hash).

### Quadro da fila (ramos empilhados; cada commit sobre o último da tarefa anterior)
| Tarefa | Ramo | Commit | Código (linhas) | Teste (linhas) | `check_all` (scripts / testes / asserts) |
|---|---|---|---|---|---|
| LW-088a (1) | `lw-088a-registro-economy` | `d1caae0` | 27 | 105 | 126 / 1.208 / 262.153 |
| LW-088a (2) | `lw-088a-registro-economy` | `26384ee` | só documentos (3 frases) | — | (sem código novo) |
| LW-088b | `lw-088b-ledger` | `c9a7e0f` | 164 | 147 | 127 / 1.215 / 268.278 |
| LW-088c | `lw-088c-porta-e-regra-f` | `5bc5cef` | 232 | 188 | 129 / 1.222 / 268.416 |
| LW-089 | `lw-089-bens-e-dados` | `370eda2` | 106 | 111 | 130 / 1.227 / 268.645 |
| LW-089b | `lw-089b-inventario` | `e28de7d` | 250 | 171 | 131 / 1.233 / 276.841 |
| LW-089c | `lw-089c-porta-dos-bens` | `d42a483` | 94 | 112 | 132 / 1.237 / 276.896 |
| LW-090 | `lw-090-precos` | `85ac0bf` | 174 | 174 | 134 / 1.246 / 290.323 |
| LW-090b | `lw-090b-estado-do-mercado` | `5941734` | 234 | 170 | 135 / 1.253 / 290.540 |
| LW-090c | `lw-090c-mercados-no-modulo` | `36d67af` | 161 | 149 | 136 / 1.259 / 290.614 |
| LW-091 | `lw-091-comercio` | `edce627` | 113 | 154 | 137 / 1.265 / 291.899 |
| LW-091b | `lw-091b-porta-do-comercio` | `8d9c417` | 59 | 100 | 138 / 1.269 / 291.958 |
| LW-092 | `lw-092-producao` | `3b27ba6` | 215 | 138 | 139 / 1.275 / 292.226 |
| LW-092b | `lw-092b-producao-hora-a-hora` | `13885c5` | 212 | 191 | 140 / 1.283 / 292.513 |
| LW-092c | `lw-092c-ligacao-ao-modulo` | `43d0b9a` | 232 | 200 | 141 / 1.290 / 292.667 |
| LW-093a | `lw-093a-verificador-de-ids` | `f7e141a` | 122 (verificador e o `check_all`) | 72 (teste de terminal) | 141 / 1.290 / 292.667 (+ o teste de terminal dentro do `check_all`) |

Linhas = só código e teste, sem comentário nem linha em branco (DEC-126); a LW-088a (1) tem também a mudança dos 9 valores do oráculo e das três listas de módulos que você aprovou. Todas as partes ficaram dentro da tolerância de ~450 linhas e ~12 arquivos de código e teste; **a LW-092b passou de 518 e foi dividida** (veja o item 7). A LW-092 (a primeira) tem 5 arquivos de código, 1 de teste e 6 de dados (7 com `pt_br.json`): 12 a 13 contando os dados, que são os que o `dados.md` atribui a ela.

## Declaração de leitura (a cada tarefa da fila)
- **Li:** `AGENTS.md` v0.4; a linha de cada tarefa em `docs/DEVELOPMENT_ROADMAP.md`; `docs/modules/economy.md` (seções da tarefa, 10 e 14); `docs/economy/dados.md`; `docs/events.md`; na LW-093a também `docs/DECISIONS.md` (DEC-137) e o backlog (M5 da revisão C). **Não li** os capítulos do GDD e da arquitetura inteiros: usei os trechos que o contrato cita (11, 17 e 18).
- **Decisões (todas APROVADAS):** DEC-126, 127, 132, 137, 138 a 178 nos pontos da economia (as 35 de 11/11/2026 em bloco), em especial DEC-145 a 152, 163, 165 a 178.

## 2. ARQUIVOS CRIADOS (por tarefa; `.uid` omitidos)
- **LW-088a:** `src/sim/economy/economy_module.gd` (a casca), `src/sim/economy/api/README.md`, `tests/unit/test_economy_module.gd`.
- **LW-088b:** `economy/owners/owner_book.gd`, `economy/ledger/ledger.gd`, `economy/api/economy_codes.gd`, `tests/unit/test_ledger.gd`.
- **LW-088c:** `economy/api/economy_module.gd` (a casca passou para a `api/`, o antigo foi apagado, ver 3), `economy/api/economy_replies.gd`, `economy/economy_json.gd`, `tests/unit/test_economy_api.gd`, `tests/unit/test_ledger_save.gd`.
- **LW-089:** `data/economy/goods.json`, `data/economy/owner_kinds.json`, `economy/goods/{good_def,owner_kind_def,goods_loader}.gd`, `tests/unit/test_goods_data.gd`.
- **LW-089b:** `economy/goods/goods_store.gd`, `tests/unit/test_goods_inventory.gd`.
- **LW-089c:** `economy/economy_definitions.gd`, `tests/unit/test_economy_goods_api.gd`.
- **LW-090:** `data/economy/market_targets.json`, `data/economy/price_params.json`, `economy/markets/{market_loader,market_target_def,price_params,price_math}.gd`, `tests/unit/test_market_data.gd`, `tests/unit/test_price_math.gd`.
- **LW-090b:** `economy/markets/market_book.gd`, `economy/events/{price_changed,shortage_declared,shortage_ended}.gd`, `tests/unit/test_markets.gd`.
- **LW-090c:** `src/app/economy_setup.gd`, `tests/unit/test_economy_markets_api.gd`.
- **LW-091:** `economy/rules/{trade_rules,trade_terms,neutral_trade_rules}.gd`, `economy/trade/trade_engine.gd`, `tests/unit/test_trade.gd`.
- **LW-091b:** `tests/unit/test_economy_trade_api.gd`.
- **LW-092:** `data/economy/{recipes,recipe_inputs,recipe_outputs,site_upkeep,site_params,production_sites}.json`, `economy/production/{recipe_def,upkeep_rule,site_params,site_def,production_loader}.gd`, `tests/unit/test_production_data.gd`.
- **LW-092b:** `economy/production/production_book.gd`, `economy/events/{production_stopped,production_resumed}.gd`, `tests/unit/test_production.gd`.
- **LW-092c:** `tests/unit/test_economy_production_api.gd`.
- **LW-093a:** `tools/check_content_ids` (8 linhas, o disparo), `tools/check_content_ids.gd` (o verificador), `tests/test_check_content_ids.sh`.

## 3. ARQUIVOS MODIFICADOS (por tarefa)
- **LW-088a:** `src/app/game_modules.gd` (registro da `economy` entre `character` e `npc`), `tools/check_architecture` (regra E), `tests/test_check_architecture.sh` (+20, só casos novos), `tests/integration/test_npc_split_oracle.gd` (os **9 valores** do marco 1, nada mais), `tests/unit/test_npc_state.gd`, `test_settlements.gd`, `test_sim_bridge_character.gd` (só a lista de módulos, o que você aprovou), `docs/modules/economy.md`, `src/sim/economy/README.md`. **2º commit (item 0):** `README.md`, `docs/modules/app.md`, `docs/modules/economy.md` (as três frases; "(rascunho da LW-087c)" virou "(LW-087c, já no main)" na linha 3 do `economy.md`).
- **LW-088b a 092c:** em cada uma, `docs/modules/economy.md` (só a linha "Estado" e as linhas da tarefa marcadas IMPLEMENTADA) e `src/sim/economy/README.md`; mais: 088c `economy_codes.gd`, `ledger.gd`, `owner_book.gd`, `tools/check_architecture` (regra F: só `ledger/` escreve saldo) e `tests/test_check_architecture.sh` (+20, positivo e negativo); 089b `economy_codes.gd`; 089c `economy_module.gd`, `economy_replies.gd`, `tools/check_architecture` (regra E ignora texto entre aspas) e `tests/test_check_architecture.sh` (+10, positivo e negativo); `data/text/pt_br.json` ganhou 10 chaves (089, bens) e 10 (092, receitas), só chaves novas; 090c `game_modules.gd`, `economy_codes.gd`, `economy_module.gd`, `economy_replies.gd`, `economy_definitions.gd`, `market_book.gd`; 090b e 092b `docs/events.md` (marca "implementado" nos 5 eventos); 091 `economy_codes.gd`, `goods_store.gd`, `ledger.gd`, `market_book.gd` (só consultas e `check_*`); 091b `economy_module.gd`, `economy_replies.gd`, `economy_definitions.gd`; 092b `goods_store.gd` (+`weight_per_unit`, +`has_room_for`); 092c `economy_module.gd` (453 linhas no arquivo, 331 de código), `economy_replies.gd`, `economy_definitions.gd`, `economy_setup.gd`, `production_book.gd` (+ o save).
- **LW-093a:** `tools/check_all` (só as duas linhas do verificador e do teste dele) e `docs/modules/economy.md`.
- **Removido:** só o `src/sim/economy/economy_module.gd` da casca, na LW-088c, que eu mesmo criei na 088a e que passou para `api/` (um arquivo meu; o conteúdo foi movido, não perdido).
- **Não toquei:** `tests/fixtures`, `tests/unit/test_save_codec.gd`, `src/sim/npc/`, `project.godot`, nenhum autoload, dependência ou ferramenta nova (o verificador é um script do próprio projeto, que você autorizou). Em `data/` só os arquivos que o `dados.md` atribui a cada tarefa.

## 4. DECISÕES TÉCNICAS
- **Pilha de ramos e um commit por tarefa:** cada ramo sai do último commit da tarefa anterior; a fila tem sufixos livres (088b e c, 089b e c, 090b e c, 091b, 092b e c) onde passei do teto.
- **O dono do dinheiro é só o `Ledger`:** nenhum outro código escreve saldo (regra F do `check_architecture`, com caso positivo e negativo). O `GoodsStore` é o dono do inventário e do peso (capacidade comparada com a quantidade **antes** de multiplicar pelo peso, para não estourar).
- **Dados no lugar certo:** todo valor [HIP] (preços, spread, eficiência, manutenção, salário) está em `data/economy/`, nunca no código; o código recebe as definições **pelo construtor** (`EconomyDefinitions`, sem valor padrão).
- **Mercados só quando o jogo recebe as definições** (LW-090c): `GameModules.register` só cria mercados quando recebe um `EconomySetup`. Assim os testes antigos e os hashes do oráculo não mudam (criar mercado gasta IDs).
- **Relógio por hora (LW-092c):** a economia anda por hora cheia; se a hora vira um dia, o **fim do dia** (mercados, depois locais) vem antes da hora de produção. O teste de borda confere que o dia fecha exatamente na virada (1.439 e 1.440 minutos).
- **LW-092b dividida (teto):** o código e o teste do livro de produção deram 518 linhas (tolerância ~450). Tirei o save (`serialize`, `load_from`, `validate`) do livro e o levei para a LW-092c, junto da ligação ao módulo (403 e 432 linhas). Por isso, entre a 092b e a 092c o livro existia sem save: ele não está ligado a nada, então nenhum estado novo existe no jogo.
- **`register_site` só aceita dono do tipo `site` já aberto** (falha `ECON_UNKNOWN_OWNER`): reforço que não estava no contrato; só falha mais cedo.
- **Atribuição do NPC ao local:** só na **abertura** da conta e só no tipo `npc` (`request_open_owner(owner_id, kind, work_place_id)`, parâmetro opcional); abrir de novo não muda o emprego ("um trabalho, um pagamento"). Local sem local de produção: a conta abre e ninguém é atribuído.
- **`peek_site*` para local que não existe** devolve `ECON_UNKNOWN_OWNER` (não criei código novo).
- **LW-093a:** `tools/check_content_ids` (Godot sem janela, no mesmo padrão do `validate_data`) confere (1) constantes do código por nome (`*_ACTION_ID` e `GO_TO_PLACE_ID` contra `actions.json`, `*NEED_ID` contra `needs.json`, `*_MEMORY_KIND` contra `memory_kinds.json`, `KIND_*` da pasta da economia contra `owner_kinds.json`; nomes com `KEY_` e `CODE_` não são ids) e (2) as colunas `need_id`, `occupation_id`, `settlement_id`, `place_id` e `work_place_id`, mais: local de produção em local `work` do mesmo povoado, único, `workers_wanted` até a capacidade. 51 conferências na árvore real, zero problemas.
- **Proposta de entrada para `DECISIONS.md` / pedido de desvio:** nenhum.

## 5. TESTES EXECUTADOS
- **`tools/check_all` na ponta de cada ramo, VERDE** (`EXIT_CODE_CHECK_ALL=0`, 0 "SCRIPT ERROR", 0 "Parse Error", nove verificações de arquitetura): 088a 126/1.208, 088b 127/1.215, 088c 129/1.222, 089 130/1.227, 089b 131/1.233, 089c 132/1.237, 090 134/1.246, 090b 135/1.253, 090c 136/1.259, 091 137/1.265, 091b 138/1.269, 092 139/1.275, 092b 140/1.283, 092c 141/1.290, 093a 141/1.290 mais o teste de terminal da 093a (4 casos válidos e 14 quebras). Cada resultado acima é de execução real (logs guardados).
- **Testes novos (GUT):** 87 no total (088a 5; 088b 7; 088c 3 + 4; 089 5; 089b 6; 089c 4; 090 4 + 5; 090b 7; 090c 6; 091 6; 091b 4; 092 6; 092b 8; 092c 7). Cada tarefa cobre o aceite, um caso de erro e um caso-limite (a tabela da seção 18 do contrato).
- **Regra de arquitetura contra saldo fora do `Ledger` (LW-088c):** `tests/test_check_architecture.sh` com caso positivo e negativo; `tools/check_architecture`: "nove verificações aprovadas" (a mensagem não mudou).
- **Controles de mutação** (cópia, alteração, teste, restauração e `cmp`; nada ficou alterado): feitos em **todas** as tarefas; os que **sobreviveram** a princípio foram reforçados com asserções e repetidos até serem pegos. Números das três últimas: **092b** 27 mutações, 5 sobreviveram na 1ª rodada e todas foram pegas depois (equipe parcial, capacidade do 2º lote, ordem máxima, local repetido no save, `validate`); **092c** 31 mutações no módulo, no save e no `EconomySetup`: 1 sobreviveu (o fim do dia uma hora adiantado) e levou um teste novo de borda do dia, todas as demais foram pegas (antes da rodada eu já tinha acrescentado 6 casos de save inválido); **093a** 11 mutações do verificador, todas pegas (o caso de borda "equipe igual à capacidade" entrou antes da rodada).
- **`tools/check_gdscript_warnings`:** zero avisos em todas as pontas (363 scripts na última).
- **`tools/run_sim --days 30 --seed 1`:** `732907967efdba5f718687a0bbafbfe102ac51cabc9d15a7f0119a9e64ebc4d7`, 0 problemas, **igual em todas as tarefas** (antes e depois).
- **Soak de 30 dias (fora do `check_all`), `tests/soak/run_npc_life_30d`, na ponta da LW-093a:** 3 execuções, **hash `82f81b239759`** nas três, 43.200 min, vivos no mínimo 100, 0 minutos parados, 0 problemas, ~26 s por execução, `EXIT=0`.

## 6. RESULTADOS
- **`check_all` final (ponta da LW-093a, 14:17 a 14:21):** 141 scripts, **1.290 testes, 1.290 passando, 0 falhando, 0 pulados**, 292.667 asserts, 173 s; a linha "IDS DE CONTEÚDO: tudo existe (51 conferências)" e "LW-093a: 4 casos válidos e 14 quebras detectadas" aparecem no log. Contra a base da fila (126 / 1.208 / 262.153): +15 scripts, +82 testes, +30.514 asserts.
- **Hashes, antes e depois, por tarefa:** só a **LW-088a** mudou valores, e foram os que você aprovou ("Aprovo os dois"), por causa do bloco vazio `economy` no save: oráculo `intents` `6e12b3067120` → `223b8ec6a7ed`, `alarm` `506a4a23ce89` → `dfe616868618`, `resumed` `7008d3b19d38` → `db2469cec836`, `switches` `84ca55684e34` → `888b1962d83b`, `talk` `ce14b1e45954` → `8b04890c8c9b`, `save` `142733eb318f` → `5673e2b3911b`, `demote` `00794d5a27b6` → `62c86fea8233`, `starved` `3e1d080d2eed` → `52c2d24b40fc`, `real_game` `f9469ccc5a9d` → `edf6ebb03cb9`; soak de 30 dias `d13b921112ce` → `82f81b239759`. **Da LW-088b à LW-093a, todos esses valores ficaram idênticos** ao do marco 1 (o `check_all` comparou o oráculo, a vida de 7 dias e os 300 NPCs com o log da tarefa anterior em cada ponta, e o soak de 30 dias foi refeito no fim); `run_sim` igual.
- **Prova da causa dos hashes (fim da LW-092, como você mandou):** numa cópia temporária do oráculo, tirei o bloco `economy` do hash do mundo e pus os 9 valores ORIGINAIS como esperados: **2/2 passaram, os 9 valores originais voltaram** (`6e12b3067120`, `506a4a23ce89`, `7008d3b19d38`, `84ca55684e34`, `ce14b1e45954`, `142733eb318f`, `00794d5a27b6`, `3e1d080d2eed`, `f9469ccc5a9d`). Desfiz e confirmei com `cmp` contra o backup; o arquivo não tem diferença contra o `HEAD` e o oráculo volta a passar com os valores do marco 1. Ou seja: o NPC se comporta como antes; a única causa da mudança é o estado novo da economia.
- **Aceite:** o de cada linha do roadmap foi cumprido (conferido pelos testes acima). Na LW-093a: id removido ou trocado em `data/` faz o verificador falhar apontando o arquivo e o id (14 casos), com os ids certos passa, e ele roda dentro do `check_all` (o `check_all` fica VERMELHO se o verificador sair com código 1, pela linha `|| status=1`; mostrei o caso pelo teste de terminal, **não** rodei um `check_all` inteiro com um id quebrado de propósito).

## 7. PROBLEMAS ENCONTRADOS
- **Vermelhos que eu mesmo causei e corrigi dentro de 3 tentativas:** (a) 089c: minha regra E acusou o texto `"NpcDied"` entre aspas na economia; a regra passou a ignorar texto entre aspas, com caso positivo e negativo; (b) 090: aviso de divisão inteira num teste (usei `IntMath.floor_div`); (c) 090b: variável local com o nome de uma função (renomeada); (d) 090c: criar mercados no jogo real gastava IDs e mudou os hashes e o `test_npc_setup.gd`: refiz o desenho (mercados só quando o jogo recebe um `EconomySetup`) e o arquivo do oráculo voltou ao `HEAD`; (e) 092c e 093a: o `.uid` do arquivo novo só aparece depois de `godot --headless --path . --import` (rodei e versionei).
- **LW-092b passou do teto** (518 linhas): dividi o save para a 092c (item 4).
- **Tamanho de arquivo:** `economy_module.gd` tem 453 linhas no arquivo e 331 de código; `production_book.gd` 334 e 257. Passam do teto de ~300 de código no módulo (dentro de 450). **Proposta:** dividir o `EconomyModule` (a porta `peek_*` num arquivo à parte) numa tarefa própria, antes de a LW-093 mexer nele.
- **Achados de calibração [HIP] (não é bug):** um local de pão com 200 de saldo inicial gasta o dinheiro em cerca de 5 lotes, porque compra a farinha pelo preço de venda e vende o pão pelo de compra, com inclinação; sem recomposição ele fica sem insumo (`NO_INPUT`) no 1º dia. A calibração é da LW-112; os testes de módulo usam saldo alto de propósito.
- **Sem equipe máxima na atribuição:** o NPC é atribuído mesmo acima de `workers_wanted` (o contrato não diz que recusa). A vaga e o limite são da LW-096.
- **Não coberto por teste isolado:** a **ordem** fim-do-dia, depois hora, dentro da hora que vira dia (não muda nada no resultado dos testes); o ramo "bem desconhecido" do `has_room_for` (a rota real já valida o bem antes); o `request_open_owner` com `work_place_id` em tipo diferente de `npc` é ignorado (documentado no comentário).
- **Ruído esperado do `check_all`** continua ("Decompression failed" e o aviso `wait_frames` do GUT); não são meus.
- **Documentos:** nenhuma contradição nova. Atualizei só a linha "Estado" do `economy.md` e as linhas das tarefas; o `README.md` da economia foi atualizado a cada parte (é o README da pasta, AGENTS 8.1) e o `docs/events.md` ganhou a marca "implementado" nos 5 eventos (090b e 092b), mais a contagem do cabeçalho.

## 8. RISCOS
- **A economia ainda roda só em teste:** a lista real de locais está vazia (LW-097) e o NPC não usa mercado (LW-093 em diante); o comportamento no jogo inteiro só aparece depois. O soak de 30 dias e o oráculo provam que nada mudou até agora.
- **O `EconomyModule` está grande** (item 7) e a LW-093 vai mexer nele; sem dividir, passa do teto.
- **Espiral de morte (R3.3 do roadmap):** com folha de pagamento e manutenção a calibrar, um local pode ficar parado; a LW-095 e a LW-112 tratam isso.
- **Nada foi medido em jogo (câmera, sensação):** não há mudança visível; sem testes manuais.

## 9. PENDÊNCIAS
- **Para você:** a auditoria dos 16 commits e o seu **"APROVADO LW-088a a LW-093a"**; só então começo a **Fase B** (juntar ao `main`), e você me manda os passos um a um. **Não fiz a Fase B e não comecei a LW-093.**
- **Testes manuais que você deve fazer:** nenhum (nada muda no jogo); se quiser conferir, rode `tools/check_all` na ponta do ramo `lw-093a-verificador-de-ids` (espere "VERDE", 1.290 testes e a linha "IDS DE CONTEÚDO: tudo existe").

## ACOMPANHAMENTO
- **Avanço:** Fase 3 (economia): LW-088a a LW-093a prontas para revisão no marco 1; falta o resto do marco 1 após o seu aval (a Fase B) e a LW-093 em diante (marco 2).
- **Próxima tarefa recomendada:** a Fase B (junção ao `main`) depois do seu "APROVADO LW-088a a LW-093a"; em seguida a LW-093 (NPCs no mercado). Não iniciadas.
- **Decisões que dependem de você:** (1) dividir o `EconomyModule` antes da LW-093 (minha recomendação: sim, numa tarefa curta de refatoração sem mudar comportamento); (2) se a atribuição do NPC deve ser limitada a `workers_wanted` (recomendação: não agora; a vaga na LW-096 decide).
- **Git:** 16 commits em 15 ramos empilhados (a LW-088a tem 2 commits), todos **enviados** ao GitHub por referência explícita (`ramo:ramo`), mais o `status-a`; **nada** no `main`, nenhum merge, tag, `--force`, rebase, reset ou stash. Os commits trazem a mensagem `LW-NNN: resumo` e o trailer de coautoria.
