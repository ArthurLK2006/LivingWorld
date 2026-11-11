# Modelos de dados da Fase 5 (combate, personagem, ecologia, pontos do mundo e eventos dinâmicos)

Estado: **PROPOSTA da LW-146h, aprovada por Arthur em 11/11/2026 (nomes e números seguem PROPOSTA e [HIP]).** Nenhum arquivo, esquema ou teste daqui existe: a Fase 5 só começa depois das Fases 3 e 4 e a pasta `data/` é protegida; esta tarefa é só documento. Segue as decisões de Arthur de 11/11/2026 (**DEC-179 a DEC-187 e DEC-229, APROVADAS**; DEC-117 e DEC-121 só como ponto de partida) e as técnicas do revisor (**DEC-188 a DEC-201, PROPOSTA**, registradas pela LW-146a em `docs/decisions/0014-pre-voo-da-fase-5.md`); o que não tem DEC é **[PROPOSTA]**; todo número é **[HIP]** (valor de trabalho, não é requisito; os do combate vêm do SP6, `docs/decisions/0008-spike-sp6-combate.md`; os demais são valores de partida deste documento, para o playtest e o soak calibrarem). Nomes de criaturas, origens, itens e lugares são **genéricos e provisórios** (DEC-100). Os eventos estão em `docs/events.md`. **Os contratos mandam nos nomes:** `docs/modules/combat.md`, `character.md` (E1 a E8), `ecology.md`, `dynamic_events.md`, `world.md` (extensão da Fase 5), `npc.md` (15) e `economy.md` (18). Este documento só acrescenta **colunas, tipos, faixas, regras de validação e linhas de partida**. Onde um contrato deixou **[EM ABERTO]**, **não invento linha**: o ponto está na seção 9, com a recomendação.

## Onde fica este documento e regras comuns

- **Como os da Fase 3 e da Fase 4** (`docs/economy/dados.md`, `docs/fase-4/dados.md`): os contratos dizem **quais** arquivos e quem os cria; aqui estão as **colunas** e as **linhas de partida**. Os **esquemas** (`DataSchema`) são declarados **em código**, na tarefa que cria cada tabela. Valem **todas as regras comuns** do `docs/fase-4/dados.md`: lista de objetos, cada um com `id` (texto `snake_case`, único, estável, nunca reutilizado; em chave composta, `<chave1>__<chave2>`); tabelas planas (`STRING`, `INT`, `FLOAT`, `BOOL`, `INT_LIST`; **nenhum `FLOAT`**, AGENTS 4.11); `set_ref` só dentro da mesma leitura; ids de **outro** módulo são `STRING` livre, conferidos à parte (DEC-137); vocabulário fechado e regra de mais de uma linha ficam em validação própria do módulo, apontando arquivo, item e campo; **textos ao jogador nunca vão nas tabelas** (cada tabela leva `name_key`).
- **Pastas [PROPOSTA]:** `data/combat/`, `data/character/`, `data/ecology/` e `data/events/` (uma por módulo, como as da Fase 4). `data/world/`, `data/economy/` e os arquivos do `npc` em `data/` seguem onde estão. A arquitetura (2.1) e o roadmap desenham alguns arquivos soltos na raiz (`data/events.json`, `data/skills.json`); a pasta por módulo é só organização (ponto 12).
- **Unidades no nome da coluna:** `_ms` (relógio do encontro), `_cm`, `_m`, `_hours`, `_days`, `_bp` (10000 = 1,0), `_permille` (1000 = 100%) e **`_pct`** (porcentagem inteira). **Exceção declarada à regra dos pontos-base:** o combate usa `_pct` porque a fórmula do contrato (`combat.md` seção 2) e o SP6 que Arthur jogou são em porcentagem inteira; o "12%" da armadura leve contra o golpe perfurante é divisão inteira (25 × 50 / 100), e trocar para `_bp` daria 12,5% e **mudaria o arredondamento** (ponto 3).
- **Duas "habilidades" com o mesmo nome nas fichas.** No `combat.md`, `skill_id` é o **golpe** (pesado, rápido, perfurante); no `character.md` e no roadmap (LW-147), `skill` é a **habilidade que progride por uso** (corpo a corpo, arco, furtividade, comércio). Dois arquivos não podem se chamar `skills.json`. **[PROPOSTA]:** `data/character/skills.json` (progressão) e `data/combat/combat_skills.json` (golpes); a ligação entre os dois é a **arma** (`weapons.json`, coluna `skill_id`), não o golpe. **Nenhum contrato muda** (o `skill_id` do `request_attack` continua sendo o golpe).
- **Chaves de texto [PROPOSTA]:** `skill.<id>.name`, `combat_skill.<id>.name`, `item.<id>.name`, `origin.<id>.name`, `creature.<id>.name` e `event.<id>.name`, em `data/text/pt_br.json`, na tarefa que cria cada dado.
- **Conteúdo, não estado:** nada daqui entra no save nem no `state_hash`. O que muda o hash é registrar os módulos e criar o que os dados mandam (`docs/modules/app.md`, extensão da Fase 5); valor de hash novo só com a autorização de Arthur (AGENTS 9.5).
- **Ordem de escrita [PROPOSTA]:** o que é citado vem **antes** de quem cita: `skills`, `weapons`, `armors` → `items` → `forge_recipes`, `origins` e filhas; `provinces` (Fase 4) → `creature_types` → `pois` → `lairs`. Um arquivo nasce **com a tarefa que o usa** (AGENTS 5.5); referência a arquivo que ainda não existe é erro de dados.

## 1. `combat` (LW-150 a LW-158; `combat.md` seções 2, 5, 8 e 10)

Todo o SP6 vira linha de partida **sem mudar um número**; o resto é [HIP].

**`combat_params.json`** (`data/combat/`; `id` = `combat_params`, uma linha; todos `INT`, 1 ou mais, salvo dito)

| Coluna | Partida | O que é |
|---|---|---|
| `auto_attack_damage`, `auto_attack_interval_ms`, `auto_attack_stamina` | 6, 1500, 4 | o ataque automático (SP6); o relógio do intervalo corre sempre e para no limite |
| `stamina_max`, `stamina_regen_per_s`, `stamina_regen_delay_ms` | 100, 12, 1000 | estamina: máximo, ganho por segundo e espera depois do último gasto (SP6) |
| `range_tolerance_cm`, `input_buffer_ms` | 50, 200 | tolerância de alcance no golpe e *buffer* do fim da recuperação (SP6) |
| `encounter_step_ms`, `s1_step_ms` | 50, 500 | passo fixo do relógio do encontro com corpo e do encontro sem corpo (`combat.md` 3, a confirmar na LW-151) |
| `wounded_below_permille` | 300 | abaixo desta vida (‰ do máximo) o combatente que **não** tem `character` fica "ferido" (`combat.md` 5); **duas fichas pedem este limiar** (ponto 4) |
| `max_embodied_combatants` | 20 | orçamento de combatentes com corpo (DEC-194) |
| `disengage_distance_cm` | 4000 | acima desta distância entre os lados o encontro acaba (`CombatEnded`, `combat.md` 7) |
| `think_interval_ms` | 500 | de quanto em quanto tempo o `combat` pede ao `npc` a decisão em combate (`npc.md` 15.4; só enquanto há encontro) |

**`combat_skills.json`** (os golpes; `id` do `request_attack`; o **ataque automático não tem linha**: `skill_id` vazio, `npc.md` 15.3)

| Coluna | Tipo | Regra |
|---|---|---|
| `id` | `STRING` | `heavy_strike`, `quick_strike`, `piercing_strike` |
| `name_key` | `STRING` | chave de texto |
| `prepare_ms`, `recover_ms` | `INT` | 1 ou mais |
| `damage`, `stamina_cost` | `INT` | 1 ou mais |
| `armor_pierce_pct` | `INT` | 0 a 100: a parte da redução da armadura que o golpe **ignora** |

Partida (SP6; preparo, recuperação, dano, estamina, perfura): `heavy_strike` 700, 900, 30, 30, 0; `quick_strike` 200, 400, 10, 12, 0; `piercing_strike` 400, 600, 16, 20, 50. **As teclas (Q, R, F) são da apresentação** (LW-153), não de dados.

**`weapons.json`**

| Coluna | Tipo | Regra |
|---|---|---|
| `id` | `STRING` | `weapon_<nome>` |
| `name_key` | `STRING` | chave de texto |
| `range_cm` | `INT` | 1 ou mais; alcance horizontal (SP6: 250) |
| `damage_pct` | `INT` | 1 ou mais; multiplica o dano **base** (do golpe ou do ataque automático) antes da posição e da armadura; 100 = o do SP6 |
| `skill_id` | `STRING` | id de `character/skills.json` que o uso treina (`SkillUsed`); **vazio** = não treina (criatura) |
| `wear_per_hit` | `INT` | 1 ou mais: o `amount` do `request_wear_item` por golpe dado (só vale para **instância**, ou seja, jogador, T2 e T3) |

Partida: `weapon_sword` (250, 100, `melee`, 1), `weapon_fists` (150, 50, `melee`, 1: o ofício sem arma, seção `default_loadouts`) e `weapon_claws` (200, 80, vazio, 1: as criaturas). **Arco e munição: sem linha** (ponto 9).

**`armors.json`**: `id` (`armor_none`, `armor_light`, `armor_heavy`), `name_key`, `reduction_pct` (`INT`, 0 a 100) e `wear_per_hit_taken` (`INT`, 1 ou mais; o `amount` do desgaste por golpe recebido). Partida (SP6): nenhuma 0, leve 25, pesada 50; desgaste 1 nas três.

**`position_zones.json`** (a posição do atacante em relação ao alvo, SP6): `id` (`front`, `side`, `back`), `max_angle_deg` (`INT`, 1 a 180) e `damage_pct` (`INT`, 1 ou mais). Partida: `front` 60, 100; `side` 120, 125; `back` 180, 150. **Regra:** os ângulos crescem de uma linha à outra e a última é 180; a zona de um golpe é a de **menor** `max_angle_deg` que cobre o ângulo.

**`default_loadouts.json`** (o equipamento padrão de quem **não** tem `character`, DEC-199; e a vida máxima dele, porque a vida de T1 e de criatura é do `CombatantState`, `combat.md` 5)

| Coluna | Tipo | Regra |
|---|---|---|
| `id` | `STRING` | `loadout_<nome>` |
| `subject_kind` | `STRING` | `occupation` (id de `occupations.json` do `npc`), `creature_type` (id de `creature_types.json`) ou `fallback` |
| `subject_id` | `STRING` | o id do sujeito; **vazio** só em `fallback` |
| `weapon_id`, `armor_id` | `STRING` | (ref `weapons`, `armors`); `weapon_id` **vazio** = não ataca (a presa) |
| `max_hp` | `INT` | 1 ou mais |

Partida: `loadout_guard` (`occupation` `guard`, `weapon_sword`, `armor_light`, 100), `loadout_soldier` (`soldier`, `weapon_sword`, `armor_light`, 110), `loadout_bandit` (`bandit`, `weapon_sword`, `armor_none`, 90) e **`loadout_civilian`** (`fallback`, `weapon_fists`, `armor_none`, 60: **todo ofício sem linha própria** luta assim, porque o `npc` pode decidir lutar em qualquer ofício); `loadout_guardian` (`creature_type` `creature_guardian`, `weapon_claws`, `armor_light`, 150), `loadout_predator` (`creature_predator`, `weapon_claws`, `armor_none`, 100) e `loadout_prey` (`creature_prey`, vazio, `armor_none`, 40). **Regras de teste:** exatamente **um** `fallback`; um sujeito não tem duas linhas; `weapon_id` vazio só em criatura de comportamento `flee`. As linhas de ofício nascem na **LW-155** (`soldier` e `bandit` são da Fase 4); as de criatura, na **LW-157**. T1 e criatura **não gastam durabilidade** (não têm instância). Vida e dano de T1 e de criatura são [HIP]: o SP6 só testou um boneco parado de 200 de vida.

## 2. `character` (LW-147 a LW-149, LW-156 a LW-156c, LW-160; `character.md` E1 a E6)

**`skills.json`** (`data/character/`; as 4 habilidades que progridem por uso, roadmap LW-147)

| Coluna | Tipo | Regra |
|---|---|---|
| `id` | `STRING` | `melee`, `bow`, `stealth`, `trade` |
| `name_key` | `STRING` | chave de texto |
| `max_level` | `INT` | 1 ou mais |
| `cost_base`, `cost_step` | `INT` | `cost_base` 1 ou mais, `cost_step` 0 ou mais: os **pontos** para passar do nível `n` ao seguinte são `cost_base + cost_step × n` (cada nível custa mais: retorno decrescente, GDD 6.4) |
| `gain_base` | `INT` | 1 ou mais: pontos ganhos por uso quando a dificuldade é **igual** ao nível |
| `harder_bonus_pct`, `easier_penalty_pct` | `INT` | 0 ou mais, **a segunda de 0 a 100**: o ganho sobe `harder_bonus_pct` por ponto de dificuldade **acima** do nível e cai `easier_penalty_pct` por ponto **abaixo**, nunca abaixo de `min_gain` |
| `min_gain` | `INT` | 1 ou mais |

Partida (todas as quatro iguais): `max_level` 100, `cost_base` 10, `cost_step` 2, `gain_base` 4, `harder_bonus_pct` 25, `easier_penalty_pct` 20, `min_gain` 1. **A forma da conta é [PROPOSTA]; a fórmula exata é da LW-147** (o contrato só exige: ganho diminui com o nível e dificuldade acima do nível rende mais). **O que cada nível faz no jogo não está em nenhum documento** (ponto 5).

**`items.json`** (as definições de item; a **instância** é do `character`, E2)

| Coluna | Tipo | Regra |
|---|---|---|
| `id` | `STRING` | `item_<nome>`; é o `def_id` da instância |
| `name_key` | `STRING` | chave de texto |
| `slot` | `STRING` | `weapon` ou `armor` (E2) |
| `combat_def_id` | `STRING` | id de `weapons.json` (se `weapon`) ou de `armors.json` (se `armor`) |
| `weight` | `INT` | 0 ou mais (a mesma unidade dos bens: `goods.json`) |
| `base_value` | `INT` | 1 ou mais; o valor da recompra parte dele (E4) |
| `durability_max` | `INT` | 1 ou mais |

Partida: `item_sword` (`weapon`, `weapon_sword`, peso 4, valor 60, durabilidade 100), `item_armor_light` (`armor`, `armor_light`, 6, 70, 80) e `item_armor_heavy` (`armor`, `armor_heavy`, 12, 140, 120). **`bound` não é coluna daqui [PROPOSTA]:** é dado da **instância** e nasce de `origin_items.bound` (equipamento de origem, DEC-190); o que sai da forja ou do saque nasce `bound` falso (E2 e E3). O texto da DEC-190 ("campo `bound` nos dados do item") admite as duas leituras (ponto 6).

**`forge_recipes.json`** (a receita do ferreiro; o `character` a lê **ao ouvir** `GoodsForged`, `economy.md` 18.3)

`id` (`forge_<item>`), `item_def_id` (ref `items`), `good_id` (`STRING`, id de `economy`), `quantity` (`INT`, 1 ou mais; quanto do bem a ponte pede a `request_forge_goods`) e `quality` (`INT`, 1 a 100; a qualidade da instância). Partida: `forge_sword` (`item_sword`, `metal`, 3, 50), `forge_armor_light` (`item_armor_light`, `metal`, 4, 50) e `forge_armor_heavy` (`item_armor_heavy`, `metal`, 8, 50). **Regra:** o `good_id` está em `forgeable_goods.json` (seção 6). **Não há habilidade de forja entre as quatro** (a LW-148 diz "qualidade pela habilidade"): a qualidade sai só da receita (ponto 7). O NPC ferreiro segue [EM ABERTO] (DEC-193).

**`origins.json`** (3 origens **por lugar de nascimento**, não por trajetória; DEC-180) e as tabelas filhas, **uma por tipo de conteúdo** (tabela plana)

| Coluna de `origins.json` | Tipo | Regra |
|---|---|---|
| `id` | `STRING` | `origin_field`, `origin_city`, `origin_road` |
| `name_key` | `STRING` | chave de texto |
| `birthplace_kind` | `STRING` | `field`, `city` ou `road`; **sem repetir** entre as linhas |
| `start_place_id` | `STRING` | id de `places.json` do `world`: o local de partida |

Partida: `origin_field` (`field`, `a_home_01`), `origin_city` (`city`, `b_market_01`) e `origin_road` (`road`, `b_rest_01`: **[EM ABERTO]**, não existe local "na estrada", ponto 9).

**`origin_items.json`**: `id` (`<origem>__<item>`), `origin_id` (ref `origins`), `item_def_id` (ref `items`), `count` (`INT`, 1 ou mais) e `bound` (`BOOL`; **verdadeiro** para todo equipamento de origem, DEC-190). Partida: `origin_field__item_sword`, `origin_city__item_armor_light` e `origin_road__item_sword`, todos `count` 1 e `bound` verdadeiro. **`origin_skills.json`**: `id` (`<origem>__<habilidade>`), `origin_id`, `skill_id` (ref `skills`) e `level` (`INT`, 0 a `max_level`). Partida: `origin_field__melee` 10, `origin_field__stealth` 10, `origin_city__trade` 15, `origin_city__melee` 5, `origin_road__stealth` 15 e `origin_road__melee` 5. **As relações iniciais** (roadmap LW-149) **não têm tabela**: o contrato não diz com quem nem por qual comando, e o `character` não importa o `npc` (ponto 8). A origem é conteúdo de **jogo** (o que cada uma dá é decisão de Arthur): as linhas são só ponto de partida. **Teste de dados:** o conjunto de itens e habilidades de cada origem é exatamente o dos dados (critério da LW-149).

**`body_params.json`** (`id` = `body`, uma linha; LW-156; jogador, T2 e T3, `character.md` E1): `max_hp` (`INT`, 1 ou mais; 100), `wounded_below_permille` (`INT`, 1 a 999; **300**, **igual** ao de `combat_params`: teste de dados exige os dois iguais, ponto 4) e `recover_hp_per_hour` (`INT`, 0 ou mais; 4: a recuperação do "ferido" por tempo é do `character/body`, DEC-182). **O efeito de "ferido" no combate e a vida com que se renasce são [EM ABERTO]** (`combat.md` 5; `character.md` E3): sem coluna.

**`character_params.json`** (`id` = `character`, uma linha): `ground_item_lifetime_hours` (`INT`, 1 ou mais; **24**, DEC-188: a instância solta some depois disso) e `pickup_reach_cm` (`INT`, 1 ou mais; 200: o alcance de `request_pickup_item`, que recusa com `CHARACTER_TOO_FAR`). **Regra:** `ground_item_lifetime_hours` é **igual** a `pile_lifetime_hours` da economia (seção 6): a mesma regra de 24 horas para o monte de bens e para a instância (teste de dados).

**`knowledge_types.json`** (a regra por tipo do mapa; DEC-184; `peek_visible`, E5)

`id` (o tipo do ponto, igual ao `kind` de `pois.json`, mais `settlement` e `route`) e `visibility` (`STRING`: `always` ou `discovered`). Partida: **decididas** (DEC-184): `settlement`, `route` e `lookout` = `always`; `ruin` e `lair` = `discovered`. **Recomendação (PROPOSTA; a DEC não diz):** `outpost` = `always` (um posto visível é estrutura), `camp` = `discovered` (esconderijo) e `respawn` = `always`. Se Arthur não aprovar, as três linhas **não nascem**, e então `camp`, `outpost` e `respawn` **não podem entrar em `pois.json`** (o teste abaixo falharia): não invento um valor padrão para tipo sem linha (ponto 10). **Teste de dados:** todo `kind` de `pois.json` tem linha, **exceto `test_marker`** (o marcador de teste da Fase 1).

## 3. `ecology` (LW-157 e LW-160; `ecology.md` seções 2, 3, 5, 7 e 9)

**`creature_types.json`** (`data/ecology/`; as 3 criaturas, DEC-180)

| Coluna | Tipo | Regra |
|---|---|---|
| `id` | `STRING` | `creature_guardian`, `creature_predator`, `creature_prey` |
| `name_key` | `STRING` | chave de texto |
| `behavior` | `STRING` | `patrol`, `hunt` ou `flee` (vocabulário fechado, LW-157) |
| `max_per_province` | `INT` | 1 ou mais; **nunca excedido** (teste da LW-157) |
| `birth_interval_hours` | `INT` | 1 ou mais |
| `aggro_radius_m`, `leash_radius_m`, `flee_radius_m` | `INT` | 0 ou mais; **`leash` sempre maior que 0**; `aggro` maior que 0 em `patrol` e `hunt`; `flee` maior que 0 em `flee` |
| `threat` | `INT` | 0 ou mais; o peso da criatura em `peek_threat` |

Partida (`behavior`, máx. por província, nascimento em horas, agressão, coleira, fuga, ameaça): `creature_guardian` (`patrol`, 3, 72, 25, 60, 0, 30); `creature_predator` (`hunt`, 4, 48, 40, 150, 0, 40); `creature_prey` (`flee`, 8, 24, 0, 100, 30, 0). **Vida e equipamento são do `combat`** (`default_loadouts`); a `ecology` guarda só o tipo.

**`creature_hostility.json`** (quem é alvo de quem; **[PROPOSTA pela recomendação de `ecology.md` seção 2]**: o contrato diz "sem decisão, nenhuma linha nasce")

`id` (`<tipo>__<alvo>`), `type_id` (ref `creature_types`), `target_kind` (`player`, `npc` ou `creature_type`) e `target_id` (`STRING`; vazio, salvo em `creature_type`, onde é ref `creature_types`). Partida **pela recomendação**: `creature_guardian__player`, `creature_guardian__npc`, `creature_predator__player`, `creature_predator__npc` e `creature_predator__creature_prey` (o predador caça a presa); **a presa não é hostil a ninguém**. **Se Arthur não aprovar a recomendação, a tabela nasce vazia e nenhuma criatura ataca ninguém.** `npc` vale para todo NPC, de qualquer tier.

**`lairs.json`** (o covil; o ponto estático é do `world`, `pois.json`): `id` (`lair_<nome>`), `poi_id` (`STRING`, id de `pois.json` de `kind` `lair`), `type_id` (ref `creature_types`) e `province_id` (`STRING`, id de `provinces.json` da Fase 4). Partida: `lair_guardian_1` (`poi_lair_1`, `creature_guardian`, `province_border`), `lair_predator_1` (`poi_lair_2`, `creature_predator`, `province_border`) e `lair_prey_1` (`poi_lair_3`, `creature_prey`, `province_a`). **Regra:** o `province_id` da linha é **igual** ao do ponto `poi_id` no `pois.json` (o dado está nos dois lugares porque os dois contratos o pedem; recomendação: guardar só no ponto, ponto 11).

**`ecology_params.json`** (`id` = `ecology`, uma linha; `INT`, 1 ou mais): `lod_enter_radius_m` 80, `lod_exit_radius_m` 120 (**maior** que o de entrada: a histerese), `max_s0_creatures` 10 e `threat_scale` 3 (`peek_threat` = soma do `threat` das criaturas hostis vivas da província ÷ `threat_scale`, limitada a 0..100). **Se a recomendação de `ecology.md` seção 6 for aprovada** (criaturas no mesmo orçamento de corpóreos), `max_s0_creatures` não passa de `max_embodied_combatants` (teste). **[EM ABERTO] sem coluna:** a vida de criatura entre encontros e se o covil esvaziado repovoa (a regra do nascimento já repovoa se a recomendação valer).

## 4. `world`: pontos de interesse e renascimento (LW-156c, LW-160 e LW-160a; `world.md` extensão da Fase 5)

**`pois.json`** (já existe, só com `test_marker`; **colunas novas, opcionais**, e **tipos novos**)

| Coluna | Tipo | Regra |
|---|---|---|
| `kind` | `STRING` | vocabulário fechado: `test_marker` (já existe), `ruin`, `lair`, `camp`, `outpost`, `lookout`, `respawn` |
| `province_id` | `STRING` | só em `lair` (**obrigatória**); (ref `provinces`, Fase 4) |
| `faction_id` | `STRING` | só em `camp` e `outpost` (**obrigatória**); id de `factions.json` (outro módulo) |
| `radius_m` | `INT` | só em `lookout` (**obrigatória**): o raio em que revela segredos (DEC-191); 1 ou mais |

Campo exigido que falta, ou presente em tipo que não o usa, é erro de dados. **Não há campo `secret`** (a visibilidade é regra por tipo, `knowledge_types.json`). Todo ponto dentro do mapa. **`ore_deposit` não existe** (ponto 9). Linhas de partida, com `x_cm` e `z_cm` **provisórios**: o desenho do mapa é da LW-160 e do playtest, aqui só garanto (conferi pela fórmula da distância) que cabem no mapa (0 a 102400 cm) e que **cada `respawn` fica a mais de 300 m de todo `lair` e `camp`** (o menor valor é 302 m); os povoados A e B estão em (32000, 54000) e (80000, 66000):

| `id` | `kind` | `x_cm`, `z_cm` | extra |
|---|---|---|---|
| `poi_respawn_a` | `respawn` | 31000, 57000 | |
| `poi_respawn_b` | `respawn` | 79000, 69000 | |
| `poi_lookout_a` | `lookout` | 45000, 50000 | `radius_m` 200 |
| `poi_ruin_a` | `ruin` | 20000, 36000 | |
| `poi_lair_1` | `lair` | 56000, 40000 | `province_border` |
| `poi_lair_2` | `lair` | 60000, 96000 | `province_border` |
| `poi_lair_3` | `lair` | 30000, 90000 | `province_a` |
| `poi_camp_b` | `camp` | 96000, 98000 | `faction_band` |
| `poi_outpost_a` | `outpost` | 38000, 58000 | `faction_authority` |

**`poi_params.json`** (`data/world/`; `id` = `poi_params`, uma linha): `respawn_min_distance_m` (`INT`, 1 ou mais; 300). **Regra de teste (LW-156c):** nenhum `respawn` fica a menos dessa distância de um `lair` ou de um `camp`, e existe ao menos um `respawn`; recomendação de `world.md` (o ponto de renascimento **dentro de um povoado**, [EM ABERTO] se precisa ser seguro).

## 5. `events`: eventos de mundo (LW-162; `dynamic_events.md` seções 3 a 7)

Os **8 tipos** da DEC-180, em três tabelas planas (o `data` não aceita objeto nem lista aninhada). Todos os números são [HIP]; **a faixa de frequência sai do soak**, não daqui.

**`events.json`** (`data/events/`)

| Coluna | Tipo | Regra |
|---|---|---|
| `id` | `STRING` | o tipo (a lista abaixo) |
| `name_key` | `STRING` | chave de texto |
| `category` | `STRING` | `natural`, `social`, `political` ou `exploration` (GDD 19.2; o sobrenatural é [FUT]) |
| `scope_kind` | `STRING` | `settlement`, `route`, `poi` ou `province` |
| `scope_poi_kind` | `STRING` | **coluna que o contrato não lista**: o `kind` do ponto, só quando `scope_kind` é `poi` (`lair` ou `ruin`); vazio nos outros |
| `condition_kind` | `STRING` | `chance` ou `on_event` (vocabulário fechado) |
| `condition_event` | `STRING` | o evento do catálogo que faz o tipo nascer; vazio em `chance` (**nenhum dos 8 usa `on_event`**; o vocabulário existe no contrato) |
| `chance_permille` | `INT` | 0 a 1000: a chance **por hora** (0 nunca dispara) |
| `duration_hours`, `cooldown_hours` | `INT` | `duration` 1 ou mais; `cooldown` 0 ou mais |
| `severity` | `INT` | 0 a 100; é o que a crônica usa para o limiar (`WorldEventStarted`) |

Partida (`categoria`, escopo, chance‰/h, duração em horas, recarga em horas, gravidade): `poor_harvest` (`natural`, `settlement`, 2, 120, 720, 50); `route_landslide` (`natural`, `route`, 1, 72, 480, 40); `festival` (`social`, `settlement`, 3, 24, 360, 20); `unrest` (`social`, `settlement`, 1, 96, 720, 60); `messenger_visit` (`social`, `settlement`, 2, 12, 240, 30); `border_dispute_escalation` (`political`, `province`, 1, 24, 720, 65); `creature_sighting` (`exploration`, `poi` de `lair`, 3, 24, 240, 30); `ruin_rumor` (`exploration`, `poi` de `ruin`, 2, 24, 360, 25). Os tipos 4 a 6 e 8 **só valem quando os módulos da Fase 4 existirem no código** (`dynamic_events.md` seção 5): na ordem do roadmap a Fase 4 vem antes, então a regra só pesa se alguém antecipar a LW-162, e nesse caso `chance_permille` fica 0 neles.

**`event_effects.json`** (um efeito por linha; `effect_id` é **vocabulário fechado**, cada valor ligado em código a **um** comando público, DEC-197)

| Coluna | Tipo | Regra |
|---|---|---|
| `id` | `STRING` | `<tipo>__<fase>` |
| `event_type_id` | `STRING` | (ref `events`) |
| `phase` | `STRING` | `start`, `tick` ou `end`; **nenhum dos 8 usa `tick`** (a coluna existe, sem linha) |
| `effect_id` | `STRING` | os da tabela abaixo |
| `arg_text`, `arg_int` | `STRING`, `INT` | os dois argumentos do efeito (vazio e 0 se não usa) |

| `effect_id` | Comando (módulo) | `arg_text` | `arg_int` | Faixa |
|---|---|---|---|---|
| `apply_production_modifier` / `remove_production_modifier` | `request_apply_production_modifier` / `request_remove_production_modifier` (`economy` 18.4) | o bem | `factor_bp` | 0 a 10000 (o remover repete só o bem) |
| `set_route_closed` / `set_route_open` | `request_set_route_state`, motivo `world_event` (`world`, DEC-229) | vazio | 0 | |
| `apply_need_pressure` | `request_apply_need_pressure` (`npc` 15.7) | a necessidade | `delta` | −100 a 100 |
| `apply_stability_modifier` / `remove_stability_modifier` | `request_apply_stability_modifier` / `request_remove_stability_modifier` (`politics` 6) | vazio | `delta` (só o aplicar) | −100 a 100 |
| `seed_rumor` | `request_seed_rumor` (`npc` 15.8) | vazio | `confidence_bp` | 1 a 10000 |
| `raise_tension` | `request_raise_tension`, motivo `world_event` (`factions` 7) | vazio | `amount` | 1 a 100 |
| `spawn_creature` | `request_spawn_creature` (`ecology`) | o tipo de criatura | 0 | |

Partida: `poor_harvest__start` (`apply_production_modifier`, `grain`, 5000) e `poor_harvest__end` (`remove_production_modifier`, `grain`, 0); `route_landslide__start` (`set_route_closed`) e `route_landslide__end` (`set_route_open`); `festival__start` (`apply_need_pressure`, `social`, −20); `unrest__start` (`apply_stability_modifier`, vazio, −15) e `unrest__end` (`remove_stability_modifier`); `messenger_visit__start` (`seed_rumor`, vazio, 6000); `border_dispute_escalation__start` (`raise_tension`, vazio, 10); `creature_sighting__start` (`spawn_creature`, `creature_predator`, 0); `ruin_rumor__start` (`seed_rumor`, vazio, 5000). **Os `days` dos modificadores saem da duração do tipo** (`duration_hours` ÷ 24, para cima), e o `source_id` é o `instance_id` do evento (`dynamic_events.md` 4): nenhum dos dois é coluna. **Regras de teste:** todo efeito `apply_*` com duração tem o seu `remove_*` na fase `end` do **mesmo** tipo, com o mesmo bem; os argumentos estão na faixa; `arg_text` existe no módulo dono (bem em `goods.json`, necessidade em `needs.json`, tipo em `creature_types.json`); **tipo novo só por dados** passa se usar efeito que já existe (critério da LW-162).

**`event_params.json`** (`id` = `event_params`, uma linha; `INT`, 1 ou mais): `max_active_events` 3 e `evaluation_step_hours` 1 (o passo; a cada hora cheia, `dynamic_events.md` 2). **[EM ABERTO] sem coluna:** o diretor de eventos (DEC-069 PENDENTE; a recomendação é não ter) e o que o jogador vê dos eventos (seção 8 do contrato).

## 6. `economy`: acréscimos da LW-146g (`economy.md` seção 18) e `politics`

Tabelas e linhas que a seção 18 prometeu sem formato. **O dono é a `economy`**; entram com a tarefa que cada uma cita.

- **`owner_kinds.json`** (já existe, com 5 linhas hoje; a do tesouro entra na Fase 4): **linha nova `ground_pile`**, a sétima (LW-156a, `economy.md` 18.2): `weight_capacity` 100000 [HIP] (grande: o monte não é depósito) e `initial_balance` 0. Nenhuma coluna nova.
- **`pile_params.json`** (`id` = `piles`; LW-156a; `INT`, 1 ou mais): `pile_lifetime_hours` **24** (DEC-188) e `max_piles` 20.
- **`modifier_params.json`** (`id` = `modifiers`; LW-162): `max_modifier_days` (`INT`, 1 ou mais; 30). **O mesmo limite da `politics`** entra como **coluna nova** `max_modifier_days` (30) em `stability_params.json` (seção 5 do `docs/fase-4/dados.md`; [PROPOSTA]): dois donos, dois arquivos.
- **`forgeable_goods.json`** (LW-148): `id` (`forge_<bem>__<tipo de dono>`), `good_id` (ref `goods`) e `owner_kind_id` (ref `owner_kinds`): **o bem que um tipo de dono pode forjar**. Partida: `forge_metal__player` (`metal`, `player`). **[PROPOSTA]:** uma tabela só diz o bem e quem pode, **sem coluna nova em `owner_kinds.json`** (o contrato, 18.3, não diz como o dado é guardado). O NPC ferreiro seria uma linha nova.
- **`buyback_params.json`** (`id` = `buyback`; tarefa nova da recompra, `economy.md` 18.5): `buyback_bp` (`INT`, 0 a 10000; 5000: o mercado paga metade do valor do item).

**`npc`** (`data/`, já existem): **`memory_kinds.json`** ganha **`item_taken`** (`valence` −10, `salience` 40, `decay_per_day` 3; LW-156e, `npc.md` 15.5) e **`npc_params.json`** ganha a coluna **`witness_radius_m`** (`INT`, 1 ou mais; 20: o raio em que um T2 testemunha `ItemDropped` e `ItemTaken`). **As linhas das ações `fight`, `surrender` e `take_item` NÃO são escritas aqui:** sem condições a ação ficaria sempre elegível (todo NPC lutaria), e as condições que leem a situação do combate (vida, zona, distância) **não existem** no vocabulário fechado do `npc` (ponto 13).

## 7. Resumo e arquivos por tarefa

**27 arquivos novos** (cada um nasce com a tarefa que o usa, AGENTS 5.5): **LW-147:** `skills`. **LW-148:** `items`, `forge_recipes`, `forgeable_goods`. **LW-149:** `origins`, `origin_items`, `origin_skills`. **LW-150:** `combat_params`, `combat_skills`, `weapons`, `armors`, `position_zones`. **LW-155:** `default_loadouts` (os ofícios e o `fallback`; a LW-157 acrescenta as criaturas). **LW-156:** `body_params`. **LW-156a:** `pile_params` e a linha `ground_pile`; `character_params`. **LW-156c:** `poi_params` e os dois `respawn`. **LW-157:** `creature_types`, `creature_hostility`, `ecology_params`. **LW-160 e LW-160a:** `lairs` e `knowledge_types` (as colunas e as linhas de `pois.json` entram na LW-160). **LW-162:** `events`, `event_effects`, `event_params`, `modifier_params`. **Tarefa nova da recompra:** `buyback_params`. **Além dos arquivos novos:** **3 colunas opcionais** em `pois.json`, **1 coluna** em `npc_params.json`, **1** em `stability_params.json`, **1 linha** em `memory_kinds.json` e **1 linha** em `owner_kinds.json`.

**Colunas que o `check_content_ids` precisará conhecer** (**PROPOSTA**; a mudança no verificador é da tarefa que cria cada arquivo, não desta): `items.combat_def_id` (→ `weapons` ou `armors`, conforme `slot`); `weapons.skill_id` (→ `skills`); `default_loadouts.subject_id` (→ `occupations.json` ou `creature_types`, conforme `subject_kind`), `weapon_id` e `armor_id`; `forge_recipes.good_id` (→ `goods.json`) e `item_def_id`; `forgeable_goods.good_id` e `owner_kind_id`; `origin_*.item_def_id` e `skill_id`; `origins.start_place_id` (→ `places.json`); `lairs.poi_id` (→ `pois.json`) e `province_id` (→ `provinces.json`); `pois.province_id` e `faction_id`; `creature_hostility.target_id` (conforme `target_kind`); `event_effects.arg_text` (conforme `effect_id`) e `events.scope_poi_kind` (→ os `kind` de `pois.json`). As **condicionais** (dependem de outra coluna da mesma linha) a tabela atual do verificador não sabe expressar, como na Fase 4.

**Testes de dados previstos** (nas tarefas que criam cada tabela): arquivo real carrega e devolve os objetos tipados; **dado inválido falha** apontando arquivo, item e campo (campo ausente, tipo errado, campo desconhecido, `id` repetido, referência quebrada, faixa inválida, vocabulário fora do fechado, campo exigido que falta e campo de outro tipo presente em `pois.json`, histerese invertida, `fallback` repetido ou ausente, ângulos das zonas fora de ordem, `bound` ausente em item de origem); dois valores que são **a mesma regra** em dois módulos batem (`wounded_below_permille` e as 24 horas); todo `kind` de `pois.json` tem linha em `knowledge_types`; toda origem aplica **exatamente** o que os dados dizem; efeito de início com duração tem o seu de fim; criatura, golpe, arma, armadura, origem, tipo de evento e efeito **novos só por JSON** passam na validação (critérios das LW-149, 150, 157 e 162).

## 8. O que este documento **não** faz

Não edita contrato, `DECISIONS.md`, GDD, arquitetura, roadmap, `data/` nem código. Não cria evento (o catálogo é o `docs/events.md`). **Não decide** o que é [EM ABERTO] nos contratos: a seção 9 só repete cada ponto com a recomendação, para você aprovar ou mandar mudar.

## 9. Pontos da revisão para Arthur (as recomendações valem se você aprovar; nomes de campos e de arquivos seguem PROPOSTA)

1. **Dois arquivos de habilidades** (`skills.json` e `combat_skills.json`): **recomendo**; sem mexer no `skill_id` do contrato do `combat`.
2. **A arma liga o golpe à habilidade** (`weapons.skill_id`, não uma coluna no golpe): **recomendo** (o mesmo golpe com outra arma treina outra habilidade). Corrige o que declarei ao abrir a tarefa (eu dissera "coluna no golpe").
3. **Porcentagem inteira no combate** (`_pct`) em vez de pontos-base: **recomendo**, para manter o resultado do SP6; a LW-150 pode trocar se medir diferença.
4. **O limiar de "ferido" aparece em duas fichas** (`combat.md` seção 10 e `character.md` E7: quem não tem `character` e quem tem): **recomendo** manter **dois** valores com teste de igualdade; a alternativa (um só, lido pelo `combat` no `character`) muda o contrato.
5. **O que o nível de cada habilidade faz.** A LW-147 só pede o ganho. **Recomendo:** só a **furtividade** tem efeito (LW-163); corpo a corpo, arco e comércio **registram**, sem efeito no protótipo. A alternativa é um bônus de dano por nível (colunas novas em `skills`). **Decisão de jogo, sua.**
6. **`bound` na instância** (nasce de `origin_items.bound`) ou **no item** (`items.json`): **recomendo a instância**, porque a mesma espada pode ser de origem (ligada) ou forjada (solta).
7. **Habilidade de forja.** Não existe entre as quatro: **recomendo** qualidade só pela receita na Fase 5 (a quinta habilidade seria linha nova de `skills.json`, por sua decisão). A **fórmula do valor por qualidade** (`peek_item_value`, "ajustado pela qualidade") também não existe: **recomendo** que a qualidade só mude o valor de venda, em fórmula da LW-148.
8. **Relações iniciais da origem.** O `character` não importa o `npc` e nenhum comando as cria: **recomendo** deixar **sem relações** nas três origens do protótipo (a reputação da Fase 4 já dá o capital social); a alternativa é a ponte aplicá-las no jogo novo, o que pede um contrato.
9. **Sem linha, por falta de decisão sua:** o **arco** e a **munição** (as fichas divergem: habilidade à distância por alvo ou projétil físico, `combat.md` 15; `weapon_bow` e uma munição só nascem depois disso); o **efeito de "ferido"** e a **vida ao renascer**; o **minério escondido** (`ore_deposit`); a **recompensa da ruína**; **onde começa quem vem da estrada** (`b_rest_01` é só um lugar existente; **recomendo** um local de descanso na borda de um povoado).
10. **Visibilidade de `outpost`, `camp` e `respawn`** (a DEC-184 não diz): **recomendo** `always`, `discovered` e `always`.
11. **A província do covil nos dois arquivos** (`pois.json` e `lairs.json`): **recomendo** guardar só no ponto, e a `ecology` ler do `world`; mantive nos dois com teste de igualdade porque os dois contratos o pedem.
12. **Pasta por módulo** (`data/events/` etc.) contra os arquivos soltos que a arquitetura e o roadmap desenham: **recomendo** a pasta, como na Fase 4. **Um arquivo só** (este) em vez de "um `dados.md` por área" (registro `0014`): **recomendo**, como a Fase 4.
13. **Ações `fight`, `surrender` e `take_item` em dados** dependem de **condições novas** no vocabulário fechado do `npc` (vida própria e do alvo, zona, distância): é **extensão de contrato do `npc`**, não de dados; **recomendo** uma parte nova da série de contratos antes da LW-155.
14. **A coluna `scope_poi_kind`** em `events.json` e a tabela `forgeable_goods` com `owner_kind_id` (sem coluna nova em `owner_kinds`): **recomendo**.
15. **Todo número** (dano, vida, alcance, chances, durações, valores de item) é **[HIP]**: nada aqui é requisito; o playtest e o soak calibram.
