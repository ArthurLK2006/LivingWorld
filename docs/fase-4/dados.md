# Modelos de dados da Fase 4 (mundo, `npc`, facções, crônica e reputação, política e militar)

Estado: **PLANEJADO, aprovado por Arthur em 11/11/2026, com os ajustes da LW-117g (DEC-227 a DEC-233) e da LW-117h (revisão R3); ainda não incorporado ao `main`.** A Fase 3 não foi implementada e a Fase 4 só começa depois dela: **nenhum arquivo, esquema ou teste daqui existe**; a pasta `data/` é protegida e esta tarefa é só documento. As decisões que ele segue são as de Arthur de 11/11/2026 (**DEC-202 a DEC-212 e DEC-224 a DEC-233, APROVADAS**) e as técnicas do revisor (**DEC-213 a DEC-223, PROPOSTA**), registradas pela LW-117a (`docs/decisions/0013-pre-voo-da-fase-4.md`); o que não tem DEC é **[PROPOSTA]**; todo número é **[HIP]** (valor de trabalho, não é requisito; calibração na LW-112 e no soak da LW-142). Nomes de facções, culturas, províncias e lugares são **genéricos e provisórios** (DEC-100). Os eventos estão em `docs/events.md` (31 novos); a lista dos arquivos e o dono de cada dado estão nos contratos `docs/modules/factions.md`, `politics.md`, `military.md`, `chronicle.md` e nas extensões da Fase 4 de `world.md` e `npc.md`, **que mandam nos nomes**.

## Onde fica este documento (como o `docs/economy/dados.md`)

- **Contratos dos módulos:** a **lista** dos arquivos, a tarefa que cria cada um e o dono do dado. **Este documento:** as **colunas**, os tipos, as faixas, as regras de validação e as **linhas de partida** de cada tabela. Os **esquemas** (`DataSchema`) são declarados **em código**, na tarefa que cria cada tabela, e implementam o que está aqui.
- **Textos ao jogador** nunca vão nas tabelas: cada tabela leva uma chave `name_key` e o texto vai para `data/text/pt_br.json`, na tarefa que cria o dado.

## Regras comuns (do `data` e da arquitetura 16)

- **Uma lista de objetos, cada um com `id`** (texto `snake_case`, único na tabela, estável, nunca reutilizado). **Toda linha precisa de `id`**: nas tabelas de chave composta, o `id` é uma **convenção** (`<chave1>__<chave2>`), e a validação confere que ele **bate** com as colunas. O `data` rejeita campo desconhecido, ausente e de tipo errado.
- **Ordem de escrita dos dados [PROPOSTA, achado R3-I7]:** o que é citado vem **antes** de quem cita: `world` (províncias e culturas), `occupations.json` do `npc` (os ofícios `soldier` e `bandit`), as linhas de `population.json`, `factions`, `politics`, `military`, `chronicle`; um arquivo novo nasce **com a tarefa que o usa** (AGENTS 5.5) e a referência para um arquivo que ainda não existe é erro de dados.
- **Tabelas planas.** O `data` só aceita `STRING`, `INT`, `FLOAT`, `BOOL` e `INT_LIST`; **sem objetos nem listas aninhadas**. **Nenhum `FLOAT`** nestas tabelas (AGENTS 4.11): dinheiro e quantidades são `INT`, proporções são **pontos-base** (`_bp`, 10000 = 1,0).
- **Referências entre tabelas** (`set_ref`) só valem **dentro da mesma leitura**: o carregador de cada módulo lê **juntas** as tabelas do módulo; as que citam id de **outro módulo** são `STRING` livres conferidas à parte (a conferência de dados entre módulos, DEC-137, estende-se aos módulos da Fase 4). Nesta ficha, **(ref `x`)** é uma referência a uma tabela de `x`.
- **Pastas [PROPOSTA]:** `data/factions/`, `data/politics/`, `data/military/`, `data/chronicle/`, `data/world/` (já existe), `data/world/cultures.json` (o roadmap diz `data/cultures.json`; ele fica em `data/world/` com os outros arquivos do mundo, achado R3-M4) e os arquivos do `npc` em `data/` (como hoje).
- **Vocabulário fechado** (por exemplo, `kind`) e regras de mais de um campo ou de mais de uma linha **não** cabem no `DataSchema`: ficam em validação própria do módulo, apontando arquivo, item e campo.
- **Convenção dos ids de linha de partida:** abaixo, a coluna "Linhas de partida" traz o id inteiro e os valores; **todos os números são [HIP]**.

## 1. `world`: províncias, adjacência e culturas (LW-118; `world.md`, extensão da Fase 4)

**`provinces.json`** (`data/world/`)

| Coluna | Tipo | Regra |
|---|---|---|
| `id` | `STRING` | por convenção `province_<nome>` |
| `name_key` | `STRING` | chave de texto, não vazia |
| `kind` | `STRING` | `settled` (com pelo menos um povoado) ou `frontier` (sem nenhum) |

Linhas de partida (as 4 da DEC-207): `province_a` (`settled`), `province_b` (`settled`), `province_c` (`settled`) e `province_border` (`frontier`).

**`province_adjacency.json`** (`data/world/`): uma linha por **par sem direção**.

| Coluna | Tipo | Regra |
|---|---|---|
| `id` | `STRING` | `<a>__<b>`, com `a` antes de `b` na ordem alfabética (o par nunca se repete invertido) |
| `province_a_id`, `province_b_id` | `STRING` | (ref `provinces`); diferentes entre si |

Linhas de partida: `province_a__province_b`, `province_a__province_border`, `province_b__province_border` e `province_border__province_c` (a fronteira é o amortecedor entre os países; ponto 2 do `world.md`). **Validação:** grafo conexo; sem par repetido nem laço.

**`settlements.json`** (já existe; **colunas novas**): `province_id` (`STRING`, (ref `provinces`), obrigatória) e `culture_id` (`STRING`, (ref `cultures`), obrigatória). Linhas de partida: `test_settlement_a` → `province_a`, `culture_trade`; `test_settlement_b` → `province_b`, `culture_trade`; `test_settlement_c` → `province_c`, `culture_tradition`. **Validação:** todo povoado tem uma província; `settled` tem povoado e `frontier` não.

**`cultures.json`** (`data/world/cultures.json`; DEC-203: duas culturas contrastantes, 4 parâmetros)

| Coluna | Tipo | Regra |
|---|---|---|
| `id` | `STRING` | `culture_trade` e `culture_tradition` |
| `name_key` | `STRING` | chave de texto |
| `trade_openness`, `foreigner_tolerance`, `martial_stance`, `authority_weight` | `INT` | 0 a 100 [HIP] |

Linhas de partida: **`culture_trade`** = 80, 60, 30, 40; **`culture_tradition`** = 30, 25, 65, 75 (a cultura mercantil e a tradicional; quais são de quais países e quais parâmetros: pontos 3 do `world.md`, **PROPOSTA**).

## 2. `npc`: T3, satisfação, rumores, protesto e ofícios novos (`npc.md` 16)

- **`npc_params.json`** (já existe, uma linha): coluna nova **`max_t3`** (`INT`, 1 ou mais; partida **8**: três líderes de facção, o governante do vizinho e folga). Separado de `max_t2` (16.2).
- **`satisfaction_params.json`** (`id` = `satisfaction`, uma linha; LW-131): `hunger_weight_bp`, `income_weight_bp` e `safety_weight_bp` (`INT`, 0 a 10000; **a soma é 10000**; partida 5000, 3000 e 2000), `urgency_levels` (`INT`, 1 ou mais; os níveis de urgência de `peek_npc`; partida 3, **a confirmar na LW-131**) e `neutral_value` (`INT`, 0 a 100; partida 50; o valor do povoado sem NPC).
- **`rumor_params.json`** (`id` = `rumors`, uma linha; LW-127): `max_rumors` (12), `min_confidence_bp` (2000), `loss_bp_per_hop` (1500), `max_hops` (3) e `rumor_speed_m_per_day` (400); todos `INT`, 1 ou mais (as confianças de 0 a 10000).
- **`rumor_sources.json`** (LW-127): `id`, `event_name` (`STRING`: um evento do catálogo), `settlement_field` (`STRING`: o campo da carga com o povoado), `min_witnesses` (`INT`, 0 ou mais) e `confidence_bp` (`INT`, 1 a 10000). Linha de partida: **`rumor_crime`** (`CrimeCommitted`, `settlement_id`, 1, 8000).
- **A ação `protest` em dados** (LW-131; a condição `unrest_active` é **código**, `npc.md` 16.5; as condições são **todas E**, então "fome **ou** renda" são **duas ações**): `actions.json` ganha **`protest`** e **`protest_poor`** (`duration_min` 60, `place_kind` `market`, `risk` 5, `interruptible` verdadeiro); `action_conditions.json`: `protest__unrest` e `protest_poor__unrest` (`kind` `unrest_active`), `protest__hunger` (`need_at_least`, `need_id` `hunger`, `min_value` 40) e `protest_poor__income` (`need_at_least`, `need_id` `income`, `min_value` 60); `action_effects.json`: `protest__social` e `protest_poor__social` (`need_id` `social`, `delta` −10); `action_trait_weights.json`: ambição +30 e sociabilidade +15 e cautela −30, nas duas ações. **Teste de dados:** toda condição tem `kind` do vocabulário (`unrest_active` entra no vocabulário fechado da seção 3 do `npc.md`).
- **Ofícios novos** (`occupations.json`; **[PROPOSTA; ponto 1 da seção 7]**): **`soldier`** (soldado, a guarnição) e **`bandit`** (bandido). **Sem local de trabalho** (não são atribuídos a posto nem a local de produção, `military.md` seção 2); o **tipo de local e a agenda** (`routine_blocks.json`) ficam em aberto. **`population.json`** (linhas novas **sem a coluna `work_place_id`**; achado R3-I7, **[PROPOSTA]**: a coluna só nasce na LW-097, o carregador do `npc` hoje rejeita a coluna e o `check_content_ids` reprova o valor vazio, mas pula a linha que não tem a coluna; **o verificador não é alterado aqui**; **a ordem dos dados:** o ofício entra em `occupations.json` **antes** da linha de população, senão o carregador rejeita o ofício): `soldier` em A (7) e em B (4) e `bandit` em B (4); **os membros iniciais da seção 3 não podem passar destas quantidades** (teste de dados).

## 3. `factions` (LW-119 a LW-125; `factions.md`)

**`factions.json`** (`data/factions/`)

| Coluna | Tipo | Regra |
|---|---|---|
| `id` | `STRING` | `faction_<nome>` |
| `name_key` | `STRING` | chave de texto |
| `type_id` | `STRING` | `authority`, `mercantile` ou `criminal` (DEC-050) |
| `culture_id` | `STRING` | id de `cultures` (outro módulo) |
| `player_can_join` | `BOOL` | **`criminal` é falso** (DEC-202); a validação recusa o contrário |
| `initial_treasury` | `INT` | 0 ou mais; o saldo inicial do tesouro, passado a `request_open_treasury(faction_id, initial_treasury)` (`economy.md` 17.2, DEC-227), que faz o `mint` `game_start`; **o da autoridade cobre a folha dos postos de A e B por pelo menos 30 dias** |
| `initial_morale`, `initial_cohesion`, `initial_legitimacy` | `INT` | 0 a 100 |

Linhas de partida (todas na cultura `culture_trade`): **`faction_authority`** (`authority`, jogador pode entrar, tesouro 60000, 60/60/60), **`faction_guild`** (`mercantile`, pode entrar, 30000, 60/60/50) e **`faction_band`** (`criminal`, **não** pode, 6000, 50/50/20).

**`faction_doctrine.json`**: `id` (`<facção>__<eixo>`), `faction_id` (ref `factions`), `axis_id` (`STRING`: `commerce`, `order`, `expansion` ou `raiding`) e `weight_bp` (`INT`, 0 a 10000). Partida (`commerce`, `order`, `expansion`, `raiding`): **autoridade** 2000, 8000, 3000, 0; **guilda** 9000, 3000, 2000, 0; **bando** 1000, 0, 3000, 9000.

**`ranks.json`** (3 a 5 postos por tipo, GDD 10.6)

| Coluna | Tipo | Regra |
|---|---|---|
| `id` | `STRING` | `<tipo>_<posto>` |
| `type_id` | `STRING` | o tipo de facção |
| `order` | `INT` | 1 a 5; sem repetir dentro do tipo; 1 é o posto de entrada |
| `name_key` | `STRING` | chave de texto |
| `slots` | `INT` | 1 ou mais (vagas por facção) |
| `wage_per_week` | `INT` | 0 ou mais; o soldo (`faction_salary`), **não pago a quem recebe por posto de serviço** |
| `contribution_bp` | `INT` | 0 a 10000; a fatia semanal do saldo que o membro repassa (`factions.md` 6.2) |

Partida (`order`, vagas, soldo, contribuição): `authority_member` (1, 40, 70, 0), `authority_officer` (2, 6, 110, 0), `authority_captain` (3, 1, 160, 0); `guild_member` (1, 30, 0, 300), `guild_agent` (2, 8, 0, 450), `guild_master` (3, 1, 0, 600); `band_member` (1, 20, 20, 200), `band_lieutenant` (2, 4, 40, 300), `band_boss` (3, 1, 60, 400).

**`rank_requirements.json`**: `id` (`<posto>__<kind>`), `rank_id` (ref `ranks`), `kind` (`STRING`: `reputation_min`, `loyalty_min`, `contribution_min` ou `tenure_days`) e `value` (`INT`, 0 ou mais; `reputation_min` é o **número da faixa** de 0 a 4, `loyalty_min` de 0 a 100). **Regra:** `reputation_min` só vale para o **jogador** e `loyalty_min` só para NPC (`factions.md` 3). Partida: `authority_officer__reputation_min` 2, `authority_officer__loyalty_min` 60, `authority_officer__tenure_days` 14, `authority_captain__reputation_min` 3, `authority_captain__loyalty_min` 75, `authority_captain__tenure_days` 60, `guild_agent__contribution_min` 400, `guild_agent__reputation_min` 2, `guild_agent__loyalty_min` 55, `guild_master__contribution_min` 1500, `guild_master__reputation_min` 3, `guild_master__loyalty_min` 70, `band_lieutenant__loyalty_min` 60, `band_boss__loyalty_min` 75.

**`faction_options.json`** (a deliberação; **condição e efeito são vocabulários fechados**, `factions.md` 4)

| Coluna | Tipo | Regra |
|---|---|---|
| `id` | `STRING` | `<tipo>_<opção>` |
| `type_id` | `STRING` | o tipo que pode escolher |
| `cost` | `INT` | 0 ou mais; tem de caber no tesouro |
| `base_weight` | `INT` | 0 ou mais (0 nunca sai) |
| `doctrine_axis` | `STRING` | `commerce`, `order`, `expansion` ou `raiding`: o eixo que pondera |
| `condition_kind` | `STRING` | `always`, `treasury_at_least`, `shortage_declared`, `route_closed` ou `hostile_state` |
| `condition_value` | `INT` | o parâmetro da condição (0 se não usa) |
| `effect_kind` | `STRING` | `post_contract`, `order_mission`, `adjust_influence`, `promote_member`, `reduce_spending` ou `idle` |
| `effect_a` | `STRING` | o tipo do contrato (`escort`, `delivery`, `labor`) ou da missão (`patrol`, `attack`, `defend`); vazio se não usa |
| `effect_b` | `INT` | a recompensa do contrato, ou o passo de influência; 0 se não usa |

Partida: `authority_patrol` (`order_mission`, `patrol`, custo 300, peso 40, `order`, `always`), `authority_reinforce` (`adjust_influence`, +300, custo 500, 20, `order`, `treasury_at_least` 5000), `authority_promote` (`promote_member`, 0, 10, `order`, `always`), `authority_save` (`reduce_spending`, 0, 15, `order`, `treasury_at_least` 0, usado quando o tesouro está baixo), `authority_idle` (`idle`, peso 20); `guild_escort` (`post_contract`, `escort`, recompensa 400, custo 400, 50, `commerce`, `route_closed`), `guild_delivery` (`post_contract`, `delivery`, 250, 30, `commerce`, `shortage_declared`), `guild_save` (`reduce_spending`, 15), `guild_idle`; `band_raid` (`order_mission`, `attack`, custo 200, 50, `raiding`, `always`), `band_save` (`reduce_spending`, 15), `band_idle`. **Teste de dados:** opção nova com condição e efeito existentes passa só por JSON.

**`faction_seed.json`** (membros iniciais, LW-121): `id`, `faction_id` (ref `factions`), `settlement_id` (`STRING`, id de `world`), `occupation_id` (`STRING`, id de `npc`), `rank_id` (ref `ranks`) e `count` (`INT`, 1 ou mais). (`merchant` é o id **proposto** para o ofício do comerciante da LW-098; o id definitivo é o do contrato da LW-098.) Partida: `seed_auth_guard_a` (autoridade, A, `guard`, `authority_member`, 8) e `seed_auth_guard_b` (B, 5) (**os guardas dos postos**, pagos pelo posto); `seed_auth_soldier_a` (A, `soldier`, `authority_member`, 5), `seed_auth_officer_a` (A, `soldier`, `authority_officer`, 1), `seed_auth_captain_a` (A, `soldier`, `authority_captain`, 1) e `seed_auth_soldier_b` (B, `soldier`, `authority_member`, 4); `seed_guild_member_a` (guilda, A, `merchant`, `guild_member`, 2), `seed_guild_master_a` (A, `merchant`, `guild_master`, 1) e `seed_guild_agent_b` (B, `merchant`, `guild_agent`, 1); `seed_band_member_b` (bando, B, `bandit`, `band_member`, 3) e `seed_band_boss_b` (B, `bandit`, `band_boss`, 1). **Regras de teste de dados:** o **líder** de cada facção é o de maior posto (um só no topo); `count` não passa da população do ofício no povoado; **os membros de força não são os dos postos** (`military.md` 2).

**`faction_posts.json`**: `id` (`<facção>__<povoado>`), `faction_id` (ref `factions`) e `settlement_id` (`STRING`): os povoados cuja folha de postos a facção paga (`factions.md` 6.5). Partida: `faction_authority__test_settlement_a` e `faction_authority__test_settlement_b`; **o C segue com o mercado** (ponto 6 do `factions.md`).

**`faction_affinity_rules.json`** (LW-122): `id`, `rule_kind` (`STRING`: `type_pair` ou `culture_pair`), `key_a` e `key_b` (`STRING`: os dois tipos ou as duas culturas) e `value` (`INT`, −100 a 100). Partida: `type_authority_mercantile` +20, `type_authority_criminal` −60, `type_mercantile_criminal` −40, `culture_trade_trade` +10, `culture_trade_tradition` −10 e `culture_tradition_tradition` +15. A afinidade inicial de um par é a **soma** das regras que se aplicam, limitada a −100 e 100.

**`faction_params.json`** (`id` = `faction_params`, uma linha): `deliberation_period_days` (7), `event_cooldown_days` (1), `unpaid_weeks_limit` (3), `loyalty_unpaid_loss` (10), `loyalty_paid_gain` (2), `contribution_cap` (200, em moeda, por membro e por semana), `revenue_event_threshold_bp` (1000), `trace_depth` (8) e `relation_history_depth` (6); todos `INT`, 1 ou mais.

## 4. `events`: crônica e reputação (LW-126 e LW-128; `chronicle.md`)

**`chronicle_params.json`** (`id` = `chronicle`, uma linha): `chronicle_threshold` (40; **o limiar da DEC-221, em dados**), `milestone_severity` (80), `max_entries` (500), `max_aggregates` (200), `max_links` (4096) e `max_chain_length` (16); todos `INT`, 1 ou mais (as severidades de 0 a 100).

**`chronicle.json`** (quais eventos o módulo assina, com que severidade e escopo)

| Coluna | Tipo | Regra |
|---|---|---|
| `id` | `STRING` | o `event_name` em `snake_case` |
| `event_name` | `STRING` | o evento do catálogo (`docs/events.md`); **conferido por teste** |
| `base_severity` | `INT` | 0 a 100; **abaixo do limiar o evento é só elo** |
| `scope_kind` | `STRING` | `settlement`, `polity`, `faction` ou `none` |
| `scope_field` | `STRING` | o campo da carga com o escopo (vazio se `none`) |
| `text_key` | `STRING` | por convenção `chronicle.<event_name em snake_case>` |
| `param_a`, `param_b`, `param_c` | `STRING` | até três campos inteiros da carga usados no texto (vazio se não usa) |

Linhas de partida (`event_name`: severidade-base, escopo; os que não aparecem **não** são assinados, entre eles `WagesPaid`, `AlarmRaised`, `RelationChanged`, `LodChanged` e `RumorSpread`):

| Evento | Base | Escopo | Evento | Base | Escopo |
|---|---|---|---|---|---|
| `NpcDied` | 30 | nenhum | `TerritoryDisputeStarted` | 65 | nenhum |
| `RouteStateChanged` | 30 | nenhum | `TerritoryDisputeResolved` | 85 | nenhum |
| `PriceChanged` | 10 | povoado | `CaravanAttacked` | 30 | nenhum |
| `ShortageDeclared` | 60 | povoado | `RouteCargoLost` | 55 | nenhum |
| `ShortageEnded` | 50 | povoado | `CaravanArrived` | 10 | nenhum |
| `ProductionStopped` | 10 | povoado | `FactionDecided` | 20 | facção |
| `ProductionResumed` | 10 | povoado | `MemberJoined` | 20 | facção |
| `ContractOffered` | 30 | nenhum | `MemberPromoted` | 20 | facção |
| `ContractCompleted` | 30 | nenhum | `MemberExpelled` | 15 | facção |
| `ContractFailed` | 50 | nenhum | `FactionCollapsed` | 90 | facção |
| `CrimeCommitted` | 60 | povoado | `FactionRevenueChanged` | 10 | facção |
| `LawChanged` | 45 | país | `FactionRelationChanged` | 20 | nenhum |
| `UnrestRaised` | 70 | povoado | `MissionOrdered` | 10 | facção |
| `UnrestEnded` | 50 | povoado | `MissionCompleted` | 30 | nenhum |
| `RulerChanged` | 85 | país | `MissionFailed` | 30 | nenhum |
| `WarDeclared` | 95 | país | `ForceMoved` | 10 | nenhum |
| `TreatySigned` | 70 | país | `ForceEngaged` | 10 | nenhum |
| `TreatyBroken` | 80 | país | `BattleResolved` | 70 | nenhum |
| `ReputationChanged` | 45 | nenhum | `ForceDemoralized` | 15 | nenhum |
| `ForceDeserted` | 20 | nenhum | `ActReported` | 10 | povoado (o `place_id`, que o `world` converte em povoado) |

**Linhas da Fase 5 que este arquivo ainda não tem (achado R3-M8):** o catálogo marca `CombatantDied`, `PlayerDefeated`, `WorldEventStarted` e `WorldEventEnded` como "Sim" ou "Se…", e o teste de integração exige que o catálogo concorde com `chronicle.json`. **Quem acrescenta a linha (e a regra de severidade, se a classe é "Se…") é a tarefa da Fase 5 que liga o evento à crônica:** `PlayerDefeated`, a **LW-156d**; `WorldEventStarted` e `WorldEventEnded`, a **LW-162**; `CombatantDied`, a **LW-164** (a morte do `combat`, criada na LW-156, entra na crônica e na reputação junto do crime). Até lá a coluna do catálogo desses quatro **não** é conferida contra os dados.

**`severity_rules.json`** (a gravidade que depende da carga; `docs/events.md` deriva daqui as classes **Se notável** e **Se grave**): `id`, `event_name`, `field` (`STRING`, campo da carga; pode ser o campo comum `severity` do evento, DEC-232: sem regra que o use, ele é ignorado), `op` (`STRING`: `eq`, `ne` ou `gte`), `value` (`INT`), `value_text` (`STRING`, para campo de texto; um dos dois é vazio) e `bonus` (`INT`, 1 a 100). Partida: `npc_died_notable` (`NpcDied`, `tier` `gte` 2, +30), `route_closed_grave` (`RouteStateChanged`, `new_state` `eq` `closed`, +30), `contract_offered_escort` (`ContractOffered`, `kind` `eq` `escort`, +30), `contract_completed_escort` (`ContractCompleted`, `kind` `eq` `escort`, +30), `faction_decided_active` (`FactionDecided`, `effect_kind` `ne` `idle`, +30), `member_joined_player` (`MemberJoined`, `actor_is_player` `eq` 1, +30), `member_promoted_player` (`MemberPromoted`, `actor_is_player` `eq` 1, +30), `member_promoted_leader` (`MemberPromoted`, `is_leader` `eq` 1, +30), `relation_big_change` (`FactionRelationChanged`, `abs_delta` `gte` 30, +30), `mission_completed_active` (`MissionCompleted`, `kind` `ne` `patrol`, +30), `mission_failed_active` (`MissionFailed`, `kind` `ne` `patrol`, +30) `caravan_attacked_success` (`CaravanAttacked`, `success` `eq` 1, +30) e **`shortage_declared_severe`** (`ShortageDeclared`, `severity` `gte` 80, +20: lê o **campo comum `severity`** que a economia já preenche, DEC-232; a base 60 sobe a 80, que é o limiar de marco, e **a classe do evento no catálogo não muda**). **Regra:** as bonificações **somam**, limitadas a 100; **a classe do catálogo** é **Sim** se a base já é de pelo menos o limiar, **Se notável** ou **Se grave** se só chega lá com uma regra, **Não** se nunca chega.

**`reputation_bands.json`** (DEC-208: 5 faixas nomeadas; **nomes genéricos propostos**, ponto 2 do `chronicle.md`): `id`, `name_key`, `band_index` (`INT`, 0 a 4, sem repetir) e `lower_bound` (`INT`, −100 a 100, **crescente com o índice**). Partida: `rep_hostile` (0, −100), `rep_wary` (1, −60), `rep_neutral` (2, −20), `rep_friendly` (3, 20) e `rep_trusted` (4, 60). **Regra:** o primeiro limite é −100 e os índices vão de 0 a 4.

**`reputation_params.json`** (`id` = `reputation`, uma linha): `decay_bp` (`INT`, 0 a 10000; 100), `publish_min_delta` (`INT`, 1 ou mais; 5) e `max_rumors_applied` (`INT`, 1 ou mais; o conjunto limitado de rumores já aplicados; 512).

**`reputation_rules.json`** (`chronicle.md` 4; **dois filtros**, descritos na `chronicle.md` seção 4, para a regra do contrato concluído pelo jogador): `id`, `event_name`, `actor_field` (o campo com o ator), `entity_kind` (`faction` ou `settlement`), `entity_field` (o campo com a entidade), `filter_field` e `filter_value` e `filter2_field` e `filter2_value` (todos `STRING`; a regra só vale se os campos têm esses valores; vazio = sem filtro), `delta` (`INT`, −100 a 100) e `needs_witness` (`BOOL`). Partida: `rep_contract_faction` (`ContractCompleted`, `acceptor_id`, `faction`, `issuer_id`, `issuer_kind` = `treasury`, `acceptor_is_player` = 1, +6, sem testemunha), `rep_join_faction` (`MemberJoined`, `actor_id`, `faction`, `faction_id`, `actor_is_player` = 1, +4), `rep_promoted_faction` (`MemberPromoted`, mesmo desenho, +6), `rep_crime_settlement` (`CrimeCommitted`, `actor_id`, `settlement`, `settlement_id`, `actor_is_player` = 1, −12, **com testemunha**) e `rep_crime_faction` (`CrimeCommitted`, `actor_id`, `faction`, `governing_faction_id`, `actor_is_player` = 1, −8, **com testemunha**).

## 5. `politics` (LW-129 a LW-134; `politics.md`)

**`polities.json`** (`data/politics/`)

| Coluna | Tipo | Regra |
|---|---|---|
| `id` | `STRING` | `polity_main` e `polity_neighbor` |
| `name_key` | `STRING` | chave de texto |
| `kind` | `STRING` | `main` ou `neighbor` (de baixa resolução, DEC-051) |
| `culture_id` | `STRING` | id de `cultures` |
| `governing_faction_id` | `STRING` | id de `factions` (outro módulo); **vazio no vizinho** |
| `initial_treasury` | `INT` | 0 ou mais; o saldo inicial do tesouro do país, passado a `request_open_treasury(polity_id, initial_treasury)` (`economy.md` 17.2, DEC-227) |
| `initial_stability`, `initial_legitimacy` | `INT` | 0 a 100 |
| `initial_diplomatic_state` | `STRING` | `neutrality`, `trade`, `hostility` ou `war`; o estado do par principal–vizinho (só na linha `polity_main`) |

Linhas de partida: **`polity_main`** (`main`, `culture_trade`, `faction_authority`, tesouro 20000, 60/60, `neutrality`) e **`polity_neighbor`** (`neighbor`, `culture_tradition`, sem facção, tesouro 15000, 60/50).

**`province_control.json`**: `id` (`control_<província>`), `province_id` (`STRING`, id de `world`) e `polity_id` (ref `polities`). Partida: `control_province_a` e `control_province_b` → `polity_main`; `control_province_c` → `polity_neighbor` (DEC-205 e DEC-207); **`control_province_border` → `polity_main` [PROPOSTA]: de quem é a fronteira não está decidido** (o `0013`, seção 6; ponto 8 do `politics.md`). **Validação:** toda província tem um controlador.

**`laws.json`** (`LawDef`, `politics.md` 3: as cinco leis do protótipo, DEC-204; a lei `license` tem **dois** valores, então são duas linhas)

| Coluna | Tipo | Regra |
|---|---|---|
| `id` | `STRING` | `tariff`, `entry_tax`, `conscription`, `crime_penalty`, `license_required` ou `license_fee` |
| `group_id` | `STRING` | a lei do roadmap (`tariff`, `entry_tax`, `conscription`, `crime_penalty` ou `license`) |
| `subject_kind` | `STRING` | `none`, `good` ou `act` |
| `min_value`, `max_value`, `step`, `default_value` | `INT` | `min` ≤ `default` ≤ `max`; `step` 1 ou mais |
| `unit` | `STRING` | `bp`, `money` ou `flag` |
| `changed_by` | `STRING` | `ruler` |

Linhas de partida (`subject_kind`, faixa, passo, padrão): `tariff` (`good`, 0 a 3000, 50, 0, `bp`), `entry_tax` (`none`, 0 a 2000, 50, 0, `bp`), `conscription` (`none`, 0 a 4000, 100, 0, `bp`), `crime_penalty` (`act`, 0 a 2000, 10, 0, `money`), `license_required` (`good`, 0 a 1, 1, 0, `flag`) e `license_fee` (`good`, 0 a 1000, 10, 0, `money`).

**`law_values.json`** (`LawState` de partida; **a ausência de linha vale o `default_value`**): `id` (`<país>__<lei>__<sujeito>`; o sujeito vazio vira `none`), `polity_id` (ref `polities`), `law_id` (ref `laws`), `subject_id` (`STRING`, o bem ou o ato; vazio se `none`) e `value` (`INT`, dentro da faixa da lei). Partida: `polity_main__tariff__tool` 300, `polity_neighbor__tariff__grain` 600, `polity_main__entry_tax__none` 200, `polity_neighbor__entry_tax__none` 400, `polity_main__conscription__none` 1500, `polity_neighbor__conscription__none` 0, e as multas do país principal (`crime_penalty`: `assault` 40, `robbery` 80, `killing` 200, `smuggling` 60) e do vizinho (60, 120, 300, 90).

**`act_sources.json`** (a tabela do **adaptador do crime**, `politics.md` 4; **PROPOSTA**, achado R3-I3; LW-164, Fase 5): `id`, `event_name` (`STRING`: `CombatantWounded`, `CombatantDied` ou `ItemTaken`), `act_id` (ref `acts`), `actor_field`, `victim_field` e `place_field` (`STRING`: o campo da carga do evento que dá o autor, a vítima e o local; **`victim_field` vazio** se o evento não traz vítima). Partida: `actsrc_wound` (`CombatantWounded`, `assault`, `attacker_id`, `target_id`, `place_id`), `actsrc_death` (`CombatantDied`, `killing`, `killer_id`, `combatant_id`, `place_id`) e `actsrc_item` (`ItemTaken`, `robbery`, `taker_id`, vazio, `place_id`). **O contrabando (`smuggling`) não tem linha:** não é um fato do `combat`, e a fonte dele é da LW-164. **Regra de dados:** `event_name` é um evento do catálogo e `act_id` existe em `acts.json`; o `ActReported` do comando de desenvolvimento **não** passa por esta tabela.

**`acts.json`**: `id` (`assault`, `robbery`, `killing`, `smuggling`; DEC-183 e DEC-204), `name_key` e `default_fine` (`INT`, 0 ou mais; usado quando falta a linha de `crime_penalty`).

**`banned_goods.json`** (a proibição da `TradeRules`; a lista do contrabando, DEC-183): `id` (`<país>__<bem>`), `polity_id` (ref `polities`) e `good_id` (`STRING`, id de `economy`). **Vazia de partida** (a Fase 4 não tem fonte de contrabando). **`license_seed.json`**: `id`, `polity_id`, `occupation_id` (`STRING`, id de `npc`) e `good_id`: o ofício que **nasce com a licença** do bem (`politics.md` 4). **Vazia de partida.**

**`stability_params.json`** (`id` = `stability`, uma linha; LW-131; a função é a de `politics.md` 6, **com estas constantes**): `satisfaction_weight_bp` (6000), `shortage_weight_bp` (2000), `tax_weight_bp` (1000) e `conscription_weight_bp` (1000) (a soma é 10000), `inertia_bp` (2000), `legitimacy_inertia_bp` (500), `unrest_raise_below` (35), `unrest_end_above` (50; **maior** que o anterior: a histerese), `unrest_days` (3) e `shortage_penalty` (10, por escassez declarada no povoado). **Regra:** `unrest_end_above` > `unrest_raise_below`.

**`ruler_options.json`** (as decisões do governante, `politics.md` 7; condição e efeito são vocabulários fechados): `id`, `law_id` (ref `laws`), `step` (`INT`, com sinal; o sentido e o tamanho da mudança, múltiplo do passo da lei), `condition_kind` (`always`, `unrest_active`, `shortage_active`, `treasury_below` ou `hostile_state`), `condition_value` (`INT`), `base_weight` (`INT`, 0 ou mais) e `trait_axis` (`STRING`: `caution`, `sociability`, `ambition` ou `loyalty`, ou vazio). Partida: `rulopt_lower_tariff_unrest` (`tariff`, −100, `unrest_active`, 40, `caution`), `rulopt_raise_tariff_poor` (`tariff`, +100, `treasury_below` 5000, 40, `ambition`), `rulopt_raise_entry_hostile` (`entry_tax`, +100, `hostile_state`, 30, `ambition`), `rulopt_lower_entry_calm` (`entry_tax`, −100, `always`, 10, `sociability`) e `rulopt_idle` (`conscription`, 0, `always`, 20, vazio).

**`ruler_candidates.json`** (só o país vizinho): `id`, `polity_id` (ref `polities`), `settlement_id` e `occupation_id` (`STRING`; o menor ID entre os NPCs do ofício no povoado). Partida: `candidate_neighbor` (`polity_neighbor`, `test_settlement_c`, `guard`).

**`diplomacy_transitions.json`**: `id`, `from_state` e `to_state` (`neutrality`, `trade`, `hostility` ou `war`), `trigger` (`agreement`, `breach`, `offense`, `war_declared`, `defeat` ou `armistice`) e `min_days_in_state` (`INT`, 0 ou mais). Partida: `neutrality__agreement` → `trade`; `trade__breach` → `hostility`; `neutrality__offense` e `trade__offense` → `hostility`; `hostility__agreement` → `neutrality`; `hostility__war_declared` → `war` (7 dias parado antes); `war__defeat` e `war__armistice` → `hostility`. **Regra:** par `(from, trigger)` único. **`treaty_kinds.json`**: `id` (`trade`), `name_key`, `default_duration_days` (`INT`, 1 ou mais; 180) e, em **`treaty_terms.json`**, os termos: `id`, `treaty_kind_id`, `term_kind` (`tariff_discount_bp`; **`free_passage` fica fora**, ponto 6 do `politics.md`) e `value` (`INT`; partida: `trade__tariff_discount_bp` 500).

**`politics_params.json`** (`id` = `politics_params`, uma linha): `ruler_period_days` (7), `law_cooldown_days` (14), `war_max_days` (60), `fine_policy` (`STRING`: `up_to_balance` ou `all_or_nothing`; partida `up_to_balance`, `politics.md` 4), `affinity_on_breach` (−25), `affinity_on_agreement` (+15), `affinity_on_offense` (−15), `affinity_on_defeat` (−10) e `trace_depth` (8).

## 6. `military` (LW-135 a LW-139; `military.md`)

**`unit_types.json`** (`data/military/`; 3 tipos, GDD 14.3): `id` (`light_infantry`, `archer`, `militia`), `name_key`, `strength` (`INT`, 1 ou mais; 10, 8 e 5) e `supply_per_day` (`INT`, 0 ou mais; 3, 3 e 2).

**`rank_unit_types.json`**: `id` (o do posto), `rank_id` (`STRING`, id de `factions`) e `unit_type_id` (ref `unit_types`). Partida: `authority_member` → `light_infantry`, `authority_officer` e `authority_captain` → `light_infantry`, `band_member` → `militia`, `band_lieutenant` e `band_boss` → `archer`; **posto sem linha não entra em força**.

**`doctrines.json`** (a doutrina **padrão** da força sem comandante, por tipo de facção): `id`, `type_id` (`authority`, `mercantile` ou `criminal`), `engagement_rule` (`avoid` ou `engage`) e `engage_ratio_bp` (`INT`, 0 a 20000; a razão de poder acima da qual ela engaja). Partida: `doctrine_authority` (`engage`, 9000), `doctrine_mercantile` (`avoid`, 15000) e `doctrine_criminal` (`engage`, 12000). **Linha extra** `doctrine_polity_neighbor` (`engage`, 10000) para a força do país vizinho.

**`force_seed.json`** (forças iniciais, LW-135): `id`, `owner_kind` (`faction` ou `polity`), `owner_id` (`STRING`), `settlement_id` (`STRING`, o povoado de partida), `member_count` (`INT`, 0 ou mais; **0 na força de país**), `strength` e `max_strength` e `regen_per_day` (`INT`, 0 ou mais; **só** na força de país, `military.md` 2). Partida: `force_authority_a` (`faction_authority`, A, 6), `force_authority_b` (B, 4), `force_band_b` (`faction_band`, B, 3) e `force_neighbor_c` (`polity` `polity_neighbor`, C, 0 membros, força 300, máxima 300, regeneração 10). **Teste de dados:** `member_count` não passa dos membros livres da facção no povoado (`faction_seed.json` menos os dos postos).

**`military_params.json`** (`id` = `military_params`, uma linha): `force_speed_m_per_day` (600), `supply_low_days` (3), `supply_buy_days` (7), `unpaid_morale_loss` (10), `defeat_morale_loss` (20), `rest_morale_gain` (2), `demoralized_below` (30), `desertion_below` (20), `desertion_bp` (500), `max_desertions_per_day` (1), `occupation_days` (2), `hostility_threshold` (−40; a afinidade abaixo da qual duas facções são hostis), `commander_min_rank_order` (2), `command_bonus_bp_per_order` (500), `max_force_size` (20) e `battle_history_depth` (12); todos `INT`.

**`resolution_params.json`** (`id` = `resolution`, uma linha; LW-137; a curva é calibração, o contrato exige só as propriedades): `morale_weight_bp` (5000), `supply_weight_bp` (3000), `casualty_loser_bp` (3000), `casualty_winner_bp` (1000) e `win_slope_bp` (a inclinação da chance de vitória pelo poder relativo; 15000); todos `INT`, 0 ou mais. **`terrain_bonus.json`:** `id` (`<tipo>_<nó>`), `node_kind` (`settlement` ou `route`), `node_id` (`STRING`) e `defender_bonus_bp` (`INT`, 0 a 10000). Partida: `settlement_test_settlement_a` e os outros dois povoados 1500; as rotas, 500.

**`raid_params.json`** (`id` = `raid_params`, uma linha; LW-139): `base_risk_bp_per_point` (o risco-base por ponto de `risk` da rota; 20), `hostile_presence_bonus_bp` (800), `patrol_reduction_bp` (600), `raid_max_bp` (3000), `escort_strength_bp` (2500), `player_escort_strength_bp` (2000), `success_base_bp` (6000), `cash_share_bp` (**5000**, DEC-226) e `cargo_share_bp` (**10000**, DEC-212 e DEC-223); todos `INT`, 0 a 10000 (os dois últimos, 0 a 10000 por contrato).

## 7. Resumo, arquivos por tarefa e pontos em aberto

**Arquivos novos e a tarefa que cria cada um** (cada um nasce com a tarefa que o usa, AGENTS 5.5): **LW-118:** `provinces`, `province_adjacency`, `cultures` e as colunas de `settlements`. **LW-119 a LW-125:** `factions`, `faction_doctrine`, `ranks`, `rank_requirements`, `faction_options`, `faction_seed`, `faction_posts`, `faction_affinity_rules` e `faction_params`. **LW-126 e LW-128:** os seis de `data/chronicle/`. **LW-121, LW-127 e LW-131:** os arquivos e as linhas do `npc` (seção 2), e os ofícios `soldier` e `bandit` com as linhas de população. **LW-129 a LW-134:** os 15 de `data/politics/` (os 14 do contrato, com `act_sources`, mais `treaty_terms`). **LW-135 a LW-139:** os 8 de `data/military/`. Os **dados** da Fase 4 não mudam o `state_hash` (conteúdo); o que muda é registrar os módulos e a população nova (`docs/decisions/0015-marcos-de-hash-da-fase-4.md`).

**Colunas novas que o `check_content_ids` precisará conhecer** (achado R3-M4; **PROPOSTA**; hoje a tabela `REFERENCES` do verificador cobre só as colunas da economia e `population.json`; **a mudança no verificador é da tarefa que cria cada arquivo e da frente da economia, não desta**): as que citam id de **outro** módulo, em texto livre: `occupation_id` (em `faction_seed`, `license_seed` e `ruler_candidates` → `occupations.json`); `settlement_id` (em `faction_seed`, `faction_posts`, `ruler_candidates` e `force_seed` → `world/settlements.json`); `culture_id` (em `factions` e `polities` → `world/cultures.json`); `faction_id` (em `polities.governing_faction_id`, vazio no vizinho, e `force_seed.owner_id` quando `owner_kind` é `faction` → `factions/factions.json`); `owner_id` com `owner_kind` `polity` → `politics/polities.json`; `province_id` (em `province_control` → `world/provinces.json`); `good_id` (em `banned_goods` e `license_seed` → `economy/goods.json`); `rank_id` (em `rank_unit_types` → `factions/ranks.json`); `node_id` (em `terrain_bonus`, conforme `node_kind` → `world/settlements.json` ou `world/routes.json`); `subject_id` (em `law_values`, conforme `subject_kind` → `economy/goods.json` ou `politics/acts.json`). As duas últimas são **condicionais** (dependem de outra coluna da mesma linha), o que a tabela atual não sabe expressar.

**Testes de dados previstos** (nas tarefas que criam cada tabela): arquivo real carrega e devolve os objetos tipados; **dado inválido falha** apontando arquivo, item e campo (campo ausente, tipo errado, campo desconhecido, `id` repetido, `id` de linha que não bate com as colunas, referência quebrada, faixa inválida, vocabulário fora do fechado, soma de pesos diferente de 10000, histerese invertida, par de adjacência repetido); `player_can_join` verdadeiro na criminosa é recusado; `chronicle.json` só cita eventos do catálogo e **a coluna "Entra na crônica?" de `docs/events.md` concorda com `chronicle.json` e `severity_rules.json`**; os membros iniciais e as forças não passam da população; opção de facção, lei, posto ou regra de reputação **novos só por JSON** passam na validação (critério 8 de 4.F).

**Pontos da revisão, aprovados por Arthur em 11/11/2026 (as recomendações valem; nomes de campos, comandos, códigos e arquivos seguem PROPOSTA):**
1. **Os ofícios `soldier` e `bandit`** (e as linhas de população) para que haja membros livres para as forças: **recomendo**; a **agenda** e o **tipo de local** deles ficam para a LW-121. **Alternativa:** tirar os guardas dos postos (cria vaga no posto).
2. **Os quatro parâmetros e as duas culturas** (seção 1) e **a fronteira controlada pelo país principal** (seção 5, `control_province_border`): ambas **PROPOSTA**; nada disso estava decidido.
3. **Dois filtros na regra de reputação** (seção 4), em vez de um, e os campos `actor_is_player`, `acceptor_is_player`, `issuer_kind` e `is_leader` nas cargas dos eventos (`docs/events.md`): **recomendo**. A `chronicle.md` (seção 4) descreve os dois filtros (LW-117g).
4. **A severidade-base e o limiar da crônica** (seção 4): os números são **[HIP]** e a classe de cada evento no catálogo vem deles; a calibração é do soak.
5. **Os valores [HIP]** (tesouros, soldos, pesos, riscos, frações) seguem [HIP], em dados.
