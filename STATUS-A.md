12/11/2026 07:02 (Brasília) · Arthur AUTORIZOU a lista da LW-094 (12/11, 07:00), mas a LW-094 só começa com a LW-097 da C no `main` (DEC-236): o `main` segue em 885615c e a Fase B da C está bloqueada por 2 testes da economia da A, à espera do seu "autorizo trocar os números desses 2 testes". Sem a produção nos dados o jogo real e o soak de 7 dias morrem de fome. Premissas e plano no topo do relatório

# RELATÓRIO — LW-095 (só código), LW-096 (partes a a e), LW-096a, 093k e as duas Fases B     Status: PRONTA PARA REVISÃO

## 1. RESUMO
Cumpri o bloco v10 na ordem. (1) A LW-093 (partes 1 a 7) entrou no `main` por avanço simples, com `check_all` verde, os 9 valores do oráculo e o `run_sim` iguais e sem tag. (2) A 093k ajustou a revisão R6. (3) A LW-095 ficou completa **só em código** (salário dos locais, postos de serviço, consulta dos postos, o `npc` aliviando `income`), sem dado novo e com o `IncomeStub` no lugar. (4) A LW-096 ficou completa em cinco partes (livro de contratos com custódia, porta, conclusão, prazo, vagas) e a LW-096a fez o NPC aceitar vaga pela utilidade, com histerese. (5) A linha inteira (093k, 095a a d, 096a a e e 096a) entrou no `main` por autorização antecipada, também por avanço simples, sem tag e sem mudar nenhuma constante. **O `main` está em `885615c`.** A LW-094, o `service_posts.json` e o resto da LW-095 não foram tocados.

## Declaração de leitura
Li: `AGENTS.md` v0.4; os blocos A v8 e v10; `economy.md` seções 6, 8 e 16; `npc.md` 14.2, 14.4 e 14.9; `events.md`; a revisão R6 (no `STATUS-B.md`); as ramificações da C (097a a 097e, só leitura, para a preparação da manhã). **Decisões usadas:** DEC-151, 152, 164, 165, 169, 174, 234 (PROPOSTA, já registrada no `main`), 235 e 236 (APROVADAS).

## 2. ARQUIVOS (ramos empilhados, todos enviados; linhas e arquivos contam código, teste e dados; sem docs, README e `.uid`)
| Parte | Ramo / commit | O que é | Arquivos / linhas |
|---|---|---|---|
| LW-095a | `lw-095a-salario-dos-locais` `df01eb1` | `WagePayer`, passo 3 da hora, `NO_FUNDS`, `WagesPaid` | 8 / 284 |
| LW-095b | `lw-095b-postos-de-servico` `ea5ed94` | `ServicePostBook`, `PostDef`, folha pela conta do mercado antes dos locais, save | 8 / 452 (no limite) |
| LW-095c | `lw-095c-consulta-dos-postos` `9d1b0f6` | `peek_post`, `peek_post_at`, `peek_posts_of` | 4 / 172 |
| LW-095d | `lw-095d-npc-ouve-salario` `2c8525b` | `WageIncome` (o `npc` ouve `WagesPaid`) | 5 / 218 |
| LW-096 a | `lw-096a-contratos-nucleo` `ebd0a06` | `ContractBook`: postar com custódia, aceitar, save | 5 / 426 |
| 093k | `lw-093k-ajustes-da-r6` `8ae5bb3` | R6-I1 (validar a necessidade antes da economia), R6-M1, R6-I2 como [LIM], R6-M2 a M5 no backlog | 5 / 135 |
| LW-096 b | `lw-096b-porta-dos-contratos` `bfbc9a3` | `request_post_contract`, `request_accept_contract`, `peek_contract(s)`, `ContractOffered` | 5 / 315 |
| LW-096 c | `lw-096c-conclusao-dos-contratos` `bc733af` | `request_work_shift`, `request_deliver_contract`, `ContractCompleted` | 7 / 344 |
| LW-096 d | `lw-096d-prazo-dos-contratos` `45bb31b` | prazo, devolução da custódia, `ContractFailed` | 5 / 205 |
| LW-096 e | `lw-096e-vagas` `1ea1b22` | `EconomyVacancies`: vagas postadas pela economia e aceitas por NPC | 6 / 395 |
| LW-096a | `lw-096f-npc-aceita-vaga` `d544daa` | `NpcEmployment`: o NPC aceita vaga pela utilidade, com histerese | 3 / 450 (no limite) |
| Fase B (LW-093) | `lw-093j-pensador-compra` `f2bcb4c` → `main` | junção com o `main` (conflito só em `docs/backlog.md`), linha de status | docs |
| Fase B (resto do marco 2) | `lw-096g-junta-com-o-main` `885615c` → `main` | junção (conflito só em `docs/backlog.md` e `docs/events.md`), linha de status | docs |
Ramos locais vazios ou obsoletos que ficam (não posso apagar): `lw-093-npcs-no-mercado`, `lw-093c-dinheiro-inicial-e-consumo`.

## 3. ARQUIVOS MODIFICADOS QUE JÁ EXISTIAM (só o que você autorizou)
- `tests/unit/test_economy_production_api.gd`: **só as linhas 181 e 182**, pela sua autorização (ratificada no v10, item 2a): a mensagem passou a listar `NO_FUNDS` e o motivo inválido de exemplo passou a `NO_SPACE`.
- `src/sim/economy/events/wages_paid.gd` → `src/sim/economy/api/wages_paid.gd` (0 linhas alteradas; ratificado no v10, item 2c).
- Nenhum outro teste existente foi alterado.

## 4. DECISÕES TÉCNICAS
- **Dados:** nenhum dado novo (sem `service_posts.json`); as definições dos postos só existem montadas à mão nos testes (`EconomyDefinitions.service_posts`). As constantes [HIP] ficaram NOMEADAS no código: `WageIncome.RELIEF_PER_COIN` (1) e, em `NpcEmployment`, `PAID_HOURS_PER_DAY` (8), `COMMUTES_PER_DAY` (2), `OCCUPATION_MATCH_BONUS` (10) e `HYSTERESIS` (20).
- **Eventos citados pelo `npc`** (`WagesPaid`, `ContractOffered`, `ContractCompleted`, `ContractFailed`) moram em `economy/api/`, para cumprir a regra E sem leitura por nome.
- **Vagas (proposta de implementação, sem decisão do GDD):** no máximo UMA vaga aberta por local de trabalho, conferência a cada hora, vaga que deixou de fazer falta falha em silêncio, e aceitar tira o emprego anterior (a vaga que isso abre nasce na hora seguinte).
- **Prazo:** vence na hora cheia seguinte ao prazo (até 59 minutos de atraso); **[LIM]** emissor morto não recebe a custódia de volta e ela fica na conta do contrato (o dinheiro continua contado; o `validate()` aceita).
- **Utilidade da vaga:** salário por hora × 8 horas, menos a caminhada de casa ao trabalho, mais o bônus de ofício; o desempregado aceita se positiva; o empregado só troca acima da histerese e se a vaga for positiva; empate pelo menor ID; nunca sorteia.
- **DESVIO da 093k (R6-I1), a seu critério:** fiz a parte atômica (o runner pergunta ao provedor a necessidade ANTES de chamar a economia: `completion_need_id`), com o teste novo que você pediu. **Não removi o sinalizador `_food_from_inventory`** porque isso exige trocar `test_the_food_stub_only_consumes_when_the_food_did_not_come_from_the_inventory` (`test_npc_trade.gd:179`), que chama o provedor direto e depende dele, e nenhum teste existente está autorizado. Além disso o vazamento que a R6 descreveu não acontece (o sinalizador é reescrito a cada `complete_action`); o teste novo prova que ele não fica ligado. **Peço autorização para trocar esse teste e tirar o sinalizador** (está no `docs/backlog.md`).
- **Propostas de entrada para `DECISIONS.md` (numeração provisória DEC-237 a DEC-241; NÃO editei o `DECISIONS.md`):** (237) as vagas: uma aberta por local, conferência por hora, silêncio ao falhar; (238) a utilidade da vaga e as 4 constantes [HIP]; (239) `income` alivia 1 ponto por moeda de salário [HIP]; (240) o prazo de contrato e a limitação do emissor morto; (241) as classes de evento que o `npc` cita ficam em `economy/api/`.

## 5. TESTES EXECUTADOS (`tools/check_all`, resultados reais; todos EXIT 0, zero avisos de compilação)
| Ponta | Commit | Scripts | Testes | Asserts |
|---|---|---|---|---|
| 093 (Fase B 1, no `main`) | `f2bcb4c` | 151 | 1.322 | 293.484 |
| 095a | `df01eb1` | 152 | 1.329 | 293.561 |
| 095b | `ea5ed94` | 153 | 1.336 | 293.631 |
| 095c | `9d1b0f6` | 154 | 1.339 | 293.660 |
| 095d | `2c8525b` | 155 | 1.345 | 293.708 |
| 096 a | `ebd0a06` | 156 | 1.351 | 293.857 |
| 093k | `8ae5bb3` | 157 | 1.354 | 293.889 |
| 096 b | `bfbc9a3` | 158 | 1.360 | 293.974 |
| 096 c | `bc733af` | 159 | 1.366 | 294.067 |
| 096 d | `45bb31b` | 160 | 1.371 | 294.128 |
| 096 e | `1ea1b22` | 161 | 1.380 | 294.214 |
| 096a (NPC) | `d544daa` | 162 | 1.391 | 294.336 |
| Fase B 2 (no `main`) | `885615c` | 162 | 1.391 | 294.336 |
**Vermelhos que corrigi (3, todos meus, nenhum teste existente tocado):** (1) parte 7 da LW-093 (já no `main`): aviso de divisão inteira no meu teste novo; (2) 095d: pus `WageIncome` na pasta `income/`, onde `test_income_stub.gd` exige a marca `TEMP` em todo arquivo; movi para `needs/`; (3) 096 a: o `check_content_ids` reserva `KIND_` para tipos de dono; renomeei as constantes dos tipos de contrato (`LABOR`, `DELIVERY`, `VACANCY`). **Mutações:** em cada parte rodei de 5 a 14 mutantes e todos foram pegos, depois de acrescentar testes para os que sobreviveram (hysteresis, prazo da entrega, vaga que se preenche); os que sobraram são equivalentes (guarda duplicada de `buy_value`, a checagem de mercado ausente nos postos, a escala `PERMILLE_SCALE`).

## 6. RESULTADOS: valores de referência
**Nenhuma constante mudou.** Os 9 valores do oráculo, conferidos no arquivo e sem diferença para o `main`: `intents` `8670b52b8ff6`, `alarm` `b62628f049b0`, `resumed` `1251aaf06e2d`, `switches` `6889619788b5`, `talk` `a8a97e95f464`, `save` `781066cec584`, `demote` `ed884fc6fb21`, `starved` `f11a33ea9ab0`, `real_game` `76a65b9cfc8a`. Os prints dos soaks (7 dias `d7266f48286e`, 300 NPCs `f31f5186abf5`) também. **`run_sim --days 30 --seed 1`: `732907967efdba5f718687a0bbafbfe102ac51cabc9d15a7f0119a9e64ebc4d7`, igual em todas as pontas.** O jogo real não tem local de produção nem posto nos dados, então a folha, os contratos e as vagas nunca rodam nele e nada muda no estado salvo.

## 7. PROBLEMAS E OCORRÊNCIAS
- **Deslize meu, já avisado:** usei `git branch -D` num ramo local vazio que eu tinha criado segundos antes (sem commit, nunca enviado). Não repeti.
- A parte 095b ficou com 452 linhas e a 096a com 450 (no limite da DEC-126); nenhuma passou de 12 arquivos.
- O ID de contrato é consumido mesmo quando o `request_post_contract` falha (os IDs não se reutilizam).
- **Limitações [LIM]:** `sell` sem valor no pensador até a LW-098; `can_buy_food` e `has_goods` sem chamador até lá; emissor morto não recebe a custódia de volta; vaga só nasce da economia (sem nascimento); `income` ainda tem o `IncomeStub` em paralelo (a folha só roda com locais de produção).

## 8. RISCOS
- Tudo isso é testado com definições montadas à mão; o primeiro uso no jogo real será quando a C entregar os dados (LW-097). O equilíbrio de dinheiro (a folha de 28, 16 e 16 moedas por hora dos postos contra os 3.000 iniciais do mercado, [HIP]) só se mede lá (R3.3, calibração na LW-112).
- A economia depende de `economy/api/` com cinco classes de evento citadas pelo `npc`; qualquer renome quebra na compilação (bom), mas exige mexer em dois módulos.
- `npc_module.gd` tem agora 647 linhas (já passava das 300 antes); proponho dividir quando você mandar.

## 9. PENDÊNCIAS (suas)
1. **Autorizar a lista de testes da LW-094 e do `IncomeStub`** (preparada abaixo) quando a LW-097 estiver no `main`.
2. Autorizar a troca do teste `test_npc_trade.gd:179` e a retirada do sinalizador `_food_from_inventory` (R6-I1 completo).
3. Registrar as DEC-237 a DEC-241 propostas no item 4, se concordar.
4. A C junta a LW-097 depois; os valores do oráculo e do soak serão os dela (não toquei).

# AUTORIZAÇÃO DA LISTA DA LW-094 (12/11/2026, 07:00) E O QUE A SEGURA
Arthur escreveu: "Autorizo a lista da LW-094" (a lista do item 6(a) e 6(c) abaixo: 1 arquivo de teste apagado, 8 alterados e a troca dos 9 valores do oráculo e dos soaks pela causa "fim do FoodStub"; a do `IncomeStub` é a 6(c), a executar em seguida se ele mandar). **A LW-094 NÃO foi iniciada, e a razão é o pré-requisito dele, não falta de autorização:** a DEC-236 e o bloco v8 põem a LW-097 da C no `main` ANTES da LW-094, e o `main` segue em `885615c` sem ela (a Fase B da C está BLOQUEADA por 2 testes existentes da economia da A, à espera do "autorizo trocar os números desses 2 testes" dele, patch pronto no `STATUS-C.md`). **Razão técnica:** sem os locais de produção nos dados o jogo real e o soak de 7 dias ficam sem comida (medido: os 100 NPCs morrem em 6 dias sem o `FoodStub`), então a LW-094 não fecha `check_all` verde em cima do `main` de agora.
**Premissas que vou seguir (me avise se discordar):** (1) os mundos de teste sem economia passam a usar a economia real e os locais de produção da C; (2) `Definitions.food` e `has_food(settlement)` ficam como interface. **Começo no dia em que a LW-097 estiver no `main`**, em duas partes (código e dados; depois os testes da lista), cada uma com `check_all` verde e com os valores novos mostrados (antigo, novo e causa).

# PREPARAÇÃO DA MANHÃ (só relatório; NADA foi escrito em código, em dado ou em teste)
## (a) O que a LW-094 apagaria ou alteraria nos testes, com antes e depois
**Premissa de menor dano:** a LW-094 remove `FoodStub`, `FoodStubLoader`, `data/food_stub.json`, `peek_food_stock`, `request_set_food_stock`, a chave `food_stock` do save do `npc` e a ligação no `NpcSetup`, e **mantém** `Definitions.food` e `ActionConditionProvider.has_food(settlement)` como interface (provedor de teste, não stub). Assim os testes com `FakeFood` e `provider.food` (`test_decision_flow`, `test_critical_need`, `test_decision_trace`, `test_action_runner`, `test_npc_intents`, `test_npc_intent_completion_hook`, `test_action_equivalence`) **não mudam**. **Causa de hash: "fim do FoodStub"** (o bloco do `npc` perde `food_stock`, e os mundos de teste sem economia ficam sem comida), a ser medida no marco 3.
| Arquivo e linha | Antes | Depois |
|---|---|---|
| `tests/unit/test_food_stub.gd` (566 linhas, 19 testes) | testa o `FoodStub`, o carregador, a marca `TEMP-LW-065`, `peek_food_stock` e `request_set_food_stock` | **apagar o arquivo** |
| `tests/unit/test_npc_setup.gd:52-53` | `var food: FoodStub = definitions.food as FoodStub; assert_not_null(food, "O provedor de comida do jogo é o FoodStub (TEMP-LW-065).")` | `assert_null(definitions.food, ...)` (o jogo não tem estoque provisório) |
| `tests/unit/test_npc_setup.gd:112` | `assert_true(npc_data.has(FoodStub.SAVE_KEY), ...)` | `assert_false(npc_data.has("food_stock"), ...)` |
| `tests/unit/test_npc_setup.gd:146-150` | laço com `peek_food_stock` e a faixa do estoque | apagar o laço |
| `tests/integration/test_npc_split_oracle.gd:194` | `str([routine.result.ok, routine.action_id, rig.npc.peek_food_stock(SETTLEMENT).stock])` | `str([routine.result.ok, routine.action_id])` |
| `tests/integration/test_npc_split_oracle.gd:280` | `assert_true(live.npc.request_set_food_stock(SETTLEMENT, 0).ok)` | apagar a linha |
| `tests/integration/test_npc_split_oracle.gd:49-57` | os 9 valores atuais | os 9 valores novos (a medir; causa "fim do FoodStub") |
| `tests/integration/test_npc_bodies_view.gd:73-76` | cenário `deadly`: zera o estoque de cada povoado (`request_set_food_stock`) | **decisão sua:** sem estoque, todo mundo passa fome; o cenário não letal precisa de uma fonte de comida (economia montada à mão ou um provedor de teste) |
| `tests/integration/test_npc_s0_reevaluation.gd:122-124` | cenário `STARVING`: idem | mesma decisão |
| `tests/soak/npc_life/npc_life_check.gd:5,118-130,164` | `check_food` com `FoodStub.StockQuery` e os campos `food_min` e `food_zero_minutes` do relatório | apagar `check_food` e os dois campos; os prints do soak perdem "comida mínima" |
| `tests/soak/npc_life/test_npc_life_7d.gd:44-52,109-122` | `_tiny_food`, `_tiny_module(food)` e `test_the_checker_flags_a_food_stock_outside_its_range...` | apagar o teste e o ajudante |
| `tests/unit/test_income_stub.gd:368` | `wrong_mark["temp_mark"] = "TEMP-LW-065"` | outro texto de marca errada (por exemplo `TEMP-LW-999`), para a busca por `TEMP-LW-065` em `tests/` ficar vazia |
| Meus testes (comentários e mensagens): `test_npc_trade.gd:3,25,120,179`, `test_npc_trade_atomicity.gd:14`, `test_npc_buys_food.gd:45` | citam o `FoodStub` e `request_set_food_stock(..., 0)` | trocar o texto; remover a chamada de `test_npc_buys_food.gd:45` |
**Resumo:** 1 arquivo apagado, 8 arquivos alterados (uns 16 pontos), 1 troca dos 9 valores do oráculo. **O resultado muda os hashes dos soaks e do oráculo; o `run_sim` não muda.** A parte de código (apagar a classe, o dado e a ligação) e a de testes ficam em duas partes, cada uma abaixo de 450 linhas.
**Decisões que dependem de você:** (1) de onde vem a comida dos mundos de teste sem economia (cenários não letais de `test_npc_bodies_view` e `test_npc_s0_reevaluation`; o oráculo e os soaks); recomendo montar a economia real e os locais de produção da C nesses mundos, como o jogo real, e aceitar os valores novos; (2) se `has_food(settlement)` fica na interface (recomendo que sim).

## (b) Rascunho do `data/economy/service_posts.json` (6 linhas, locais da 097a e da população da 097d; `wage_per_hour` 2 [HIP], igual ao das receitas)
```
[
	{"id": "post_a_guard", "settlement_id": "test_settlement_a", "place_id": "a_work_06", "occupation_id": "guard", "workers_wanted": 8, "wage_per_hour": 2},
	{"id": "post_a_inn", "settlement_id": "test_settlement_a", "place_id": "a_work_07", "occupation_id": "innkeeper", "workers_wanted": 6, "wage_per_hour": 2},
	{"id": "post_b_guard", "settlement_id": "test_settlement_b", "place_id": "b_work_07", "occupation_id": "guard", "workers_wanted": 5, "wage_per_hour": 2},
	{"id": "post_b_inn", "settlement_id": "test_settlement_b", "place_id": "b_work_08", "occupation_id": "innkeeper", "workers_wanted": 3, "wage_per_hour": 2},
	{"id": "post_c_guard", "settlement_id": "test_settlement_c", "place_id": "c_work_04", "occupation_id": "guard", "workers_wanted": 5, "wage_per_hour": 2},
	{"id": "post_c_inn", "settlement_id": "test_settlement_c", "place_id": "c_work_05", "occupation_id": "innkeeper", "workers_wanted": 3, "wage_per_hour": 2}
]
```
Folha por hora: A 28, B 16, C 16 moedas (672, 384 e 384 por dia) contra o saldo inicial de 3.000 do mercado: **dura de 4 a 8 dias sem a venda de produto**; é o risco R3.3, e o número é [HIP] para a LW-112. **O que falta no código para esse arquivo existir:** `PostLoader` (esquema `service_posts`, um posto por local) e a ligação no `EconomySetup` (o conflito de local entre posto e local de produção); escrevi e desfiz esse trecho no v8 e o refaço em minutos quando você mandar. O `check_content_ids` e o `test_economy_distribution.gd` da C devem passar a ler a tabela.

## (c) Plano da remoção do `IncomeStub` (resto da LW-095; NÃO executado)
1. **Código a apagar:** `src/sim/npc/income/income_stub.gd` e `income_stub_loader.gd`, `data/income_stub.json`, `NpcSetup` (carregamento), `NpcModule.Definitions.income`, `NpcDecisionRuntime` e `ConditionProvider.extra_effects` (o gancho `ActionConditionProvider.extra_effects` pode ficar como interface). O `WageIncome` (já entregue) passa a ser a única fonte de alívio de `income`.
2. **Testes que mudam:** apagar `tests/unit/test_income_stub.gd` (412 linhas, 13 testes); `tests/unit/test_npc_setup.gd:59` (`assert_gt(definitions.income.peek_relief("farmer"), 0, ...)`: apagar a linha); `tests/unit/test_critical_need.gd:285-318` (o provedor de teste que repassa `IncomeStub.extra_effects`: trocar por um efeito extra montado à mão para o teste de efeito proporcional continuar provando a mesma coisa); `tests/integration/test_action_equivalence.gd:42` e `tests/soak/npc_bodies/npc_bodies_twin.gd:288` só mudam se o gancho `extra_effects` sair (comentário e espião).
3. **Causa de hash: "fim do IncomeStub"** (o `income` deixa de cair por trabalhar; só cai com `WagesPaid`, que só existe com locais de produção e postos nos dados). O oráculo e os soaks mudam de novo, **por causa diferente da do FoodStub**: proponho entregar as duas remoções no mesmo marco 3 ou em dois valores relatados separados, a seu critério.
4. **Ordem proposta:** LW-097 da C no `main`; `service_posts.json` e o `PostLoader`; LW-094; `IncomeStub`; o teste de ouro e o soak de 30 dias com a economia real (a morte por fome precisa ficar em zero: a comida sai do mercado, que o local de produção reabastece e a folha mantém o dinheiro dos NPCs).
5. **Critério de aceite:** busca por `TEMP-LW-065` e `TEMP-LW-066` vazia em `src/`, `data/`, `tests/`, `tools/` e `scenes/`; `check_all` verde; 30 dias com os 132 NPCs vivos.

## ACOMPANHAMENTO
- **Avanço:** marco 2 em código completo e no `main` (aguardando a sua auditoria); falta a LW-097 da C no `main`, depois LW-094 e o resto da LW-095 com a sua lista.
- **Próxima tarefa recomendada:** LW-094, só com a sua autorização escrita da lista acima. **Não iniciada.**
- **Git:** `main` em `885615c`; sem tag; nenhum `--force`, rebase, reset ou ramo apagado (a não ser o deslize já avisado); push no `main` só nos itens 1 e 5, por avanço simples.
