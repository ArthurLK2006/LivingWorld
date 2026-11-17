# Modelos de dados da economia (Fase 3)

Estado: **LW-107a (14/11/2026, só documento) acrescentou a seção `contract_templates.json` (formato, faixas e a regra anti-exploração do postador de contratos de entrega; implementado na LW-107c1; contrato APROVADO por Arthur em 14/11/2026 (PR #33): proteção só na postagem e quadro vazio aceitável).** **PLANEJADO, incorporado ao `main` em 11/11/2026** (LW-087d, rodada 5). As decisões do pré-voo da Fase 3 que ele segue estão **aprovadas por Arthur** (as de 10/11/2026 e as 35 de 11/11/2026, em bloco); o que não tem DEC segue como **[PROPOSTA]**. A Fase 2 fechou em 10/11/2026 (tag `fase-2-concluida`); este arquivo foi incorporado ao `main` em 11/11/2026. **Nenhum arquivo de `data/`, nenhum esquema em código e nenhum teste foi criado:** isto descreve os modelos **PLANEJADOS** que as tarefas LW-089, LW-090, LW-092, LW-095 e LW-097 vão criar. Rótulos: **decisão**, **aprovada por Arthur em 10/11/2026** ou **em 11/11/2026 (DEC-NNN)** (registradas no `DECISIONS.md` pela LW-087a; as 35 de 11/11/2026 foram aprovadas em bloco, com o texto do revisor de 10/11/2026), **decidido pelo revisor** (decisão de Claude na delegação de menores de Arthur, 10/11/2026: [PROPOSTA]; só resta nos pontos sem DEC), **[PROPOSTA]** (desenho sem DEC), **[HIP]** (número de trabalho, não é requisito) e **[LIM]**. Nomes de bens, receitas e ofícios são **genéricos e provisórios** (DEC-100, APROVADA). Os nomes de tabelas, de colunas, de ids e de códigos de erro são os do contrato `docs/modules/economy.md` (LW-087b), que este documento **não repete**: ele só acrescenta o nível de coluna.

## Onde fica este documento (o que o padrão do projeto manda)

- **Contrato do módulo** (`docs/modules/economy.md`, LW-087b): a **lista** dos arquivos de dados, a tarefa que cria cada um e o dono do dado (seções 12 e 13), como o `npc.md` ("Arquivos de dados propostos", seção 11) e o `world.md` fazem. Fica lá porque o contrato é a fonte de verdade do módulo.
- **Este documento** (`docs/economy/dados.md`): as **colunas**, os tipos, as faixas e as regras de validação de cada tabela, mais a lista dos 10 bens, das 10 receitas e da distribuição proposta. Fica numa pasta própria **e não dentro de `economy.md`** por duas razões: já há precedente de documento de dados por área (`docs/world/relevo-do-terreno-de-blockout.md`), e as duas tarefas, 087b e 087d, são ramos paralelos a partir do `main`, então escrever na mesma ficha geraria conflito de arquivo.
- **`data/economy/README.md`** (como o `data/world/README.md`): **não** é criado agora; nasce junto com os primeiros dados reais (LW-089), porque descreve arquivos que existem. A pasta `data/` é protegida e esta tarefa é só documento.
- **Textos ao jogador** nunca vão nas tabelas: cada tabela leva uma chave `name_key` e o texto vai para `data/text/pt_br.json` (arquitetura 16.4), na tarefa que cria o dado.
- **Esquemas** (`DataSchema`, `docs/modules/data.md`) são declarados **em código GDScript**, na tarefa que cria cada tabela; este documento é o que eles implementam.

## Regras comuns (do `data` e da arquitetura 16)

- JSON validado (DEC-082, aprovada só quanto ao JSON validado): **uma lista de objetos**, cada um com `id` (texto `snake_case`, único na tabela, estável, nunca reutilizado). Campos conhecidos: o `data` rejeita campo desconhecido, campo ausente e tipo errado, apontando arquivo, item e campo.
- **Tabelas planas.** O `data` só aceita `STRING`, `INT`, `FLOAT`, `BOOL` e lista de inteiros (`INT_LIST`); **não aceita objetos nem listas aninhadas** (decidido: tabelas planas, como no `npc` e no `world`). Por isso insumos e produtos de uma receita são **tabelas à parte**, uma linha por (receita, bem).
- **Dinheiro e quantidades são `INT`**; proporções em **pontos-base** (`_bp`, 10000 = 1,0), também `INT`. Nenhum `FLOAT` nestas tabelas (AGENTS 4.11).
- Referência entre tabelas (`set_ref`) só funciona **dentro da mesma leitura**: o carregador da economia lê as tabelas abaixo **juntas** (como o `npc` faz com as suas seis). Vocabulário fechado (por exemplo, `category`) e regras de mais de um campo ou de mais de uma linha (par único, mínimo menor que máximo) são conferidos **no carregador**, com `ECON_DATA_INVALID` e mensagem de arquivo, item e campo (padrão de `SETTLEMENT_DATA_INVALID`).
- Pasta: **`data/economy/`** [PROPOSTA], como `data/world/` (`data/` hoje tem os arquivos do `npc` soltos, e o `npc.md` já prevê subpasta como alternativa).
- **D1 (referências entre módulos): a conferência na LW-093a é a DEC-137 (aprovada por Arthur em 10/11/2026); o desenho das colunas como `STRING` livres segue [PROPOSTA], sem DEC.** Colunas que citam ids de **outro** módulo: `need_id` (de `needs`) e `occupation_id` (de `occupations`), tabelas do `npc`; `settlement_id` e `place_id` (de `world/settlements` e `world/places`); e, em `population.json`, o `work_place_id` que entra com a LW-097. A economia **não importa o `npc`** (decidido por Arthur), então o carregador **não** pede `set_ref` para as tabelas dos outros módulos: essas colunas são **`STRING` livres** no esquema da economia e uma **conferência de dados entre módulos** confere que cada id existe na tabela do dono. A conferência mora no **verificador LW-093a** (o verificador de ids de conteúdo, pré-requisito da LW-093, decidido por Arthur): o escopo dele **cresce** de cerca de **60** para cerca de **150 a 200 linhas de código e teste** (um arquivo de verificação e um de teste, com caso positivo e negativo para cada coluna), dentro do teto da DEC-126, e vem **depois da LW-092** (quando as tabelas da economia existem) e antes da LW-093. Ela também confere que o `place_id` de cada local de produção e de cada posto é de tipo `work`, do mesmo povoado, **único**, e que `workers_wanted` não passa da capacidade do local. O teste "nenhum povoado se basta" **não** entra na 093a (ele lê só tabelas da economia e precisa do 3º povoado): é o `test_economy_distribution.gd`, da LW-097.

## Os 10 bens e as 4 cadeias (decisão de Arthur, 10/11/2026; escala [HIP])

| id | Nome (`good.<id>.name`) | Categoria | Produzido por (receita) | Para que serve na Fase 3 |
|---|---|---|---|---|
| `grain` | grão | `food` | `grow_grain` | insumo de `mill_flour`; o NPC o come (alivia menos que `bread`) |
| `flour` | farinha | `processed` | `mill_flour` | insumo de `bake_bread` |
| `bread` | pão | `food` | `bake_bread` | o NPC o come (alívio cheio) |
| `wood` | madeira | `raw_material` | `cut_wood` | insumo de `saw_plank` e combustível de `smelt_metal` |
| `plank` | tábua | `processed` | `saw_plank` | **manutenção dos locais de produção** e venda |
| `ore` | minério | `raw_material` | `mine_ore` | insumo de `smelt_metal` |
| `metal` | metal | `processed` | `smelt_metal` | insumo de `forge_tool` |
| `tool` | ferramenta | `tool` | `forge_tool` | **manutenção dos locais de produção** e venda |
| `wool` | lã | `raw_material` | `shear_wool` | insumo de `weave_fabric` |
| `fabric` | tecido | `processed` | `weave_fabric` | **manutenção dos locais de produção** (lonas e sacos; Q22) e venda; nenhum NPC o consome |

**Cadeias:** (1) `grain` → `flour` → `bread`; (2) `wood` → `plank`; (3) `ore` + `wood` → `metal` → `tool`; (4) `wool` → `fabric`. A madeira também é o combustível da cadeia 3. Armas (demanda militar), roupas e ferramenta pessoal do NPC **não** entram (decidido). Cada bem tem **exatamente uma** receita que o produz, e as quatro de **extração** (`grow_grain`, `cut_wood`, `mine_ore`, `shear_wool`) não têm insumo.

## `goods.json` (LW-089): `GoodDef`

| Coluna | Tipo | Regra |
|---|---|---|
| `id` | `STRING` | um dos 10 ids acima |
| `name_key` | `STRING` | `good.<id>.name`; o texto em `data/text/pt_br.json` |
| `category` | `STRING` | vocabulário fechado no carregador: `food`, `raw_material`, `processed`, `tool`; `weapon`, `luxury` e `magic` são **aceitos e reservados**, sem uso (GDD 12.3) |
| `base_value` | `INT` | 1 ou mais (menor unidade de moeda); valor [HIP] em dados, calibrado na LW-112 |
| `weight` | `INT` | 1 ou mais (unidade de peso [HIP]) |
| `perishability_days` | `INT` | 0 ou mais; **0 = não perece** e **sem comportamento na Fase 3** (contrato, Q11) |
| `need_id` | `STRING` (opcional) | só em bem de consumo do NPC; id de `needs` (D1); vazio nos demais |
| `need_relief` | `INT` (opcional) | só com `need_id`; 1 ou mais (quanto 1 unidade alivia, na escala de pressão 0 a 100 do `npc`); contrato, Q9 |

Regras: `need_id` e `need_relief` vêm **juntos** ou nenhum; todo bem tem uma receita que o produz (conferência cruzada com `recipe_outputs`). **Quais bens saciam o quê** (contrato, Q9, e Q20 do `npc.md`, aprovados por Arthur em 11/11/2026, DEC-153): `bread` alivia `hunger` por inteiro e `grain` menos [HIP]; **só esses dois levam `need_id` e `need_relief`**, os outros oito não (decisão de Arthur: o NPC só consome comida; `tool`, `plank` e `fabric` são manutenção dos locais).

## `owner_kinds.json` (LW-089): tipos de dono

Seis linhas: `npc`, `player`, `site`, `market`, `contract` e `merchant` (a sexta, do comerciante, entra na LW-098c por decisão de Arthur de 14/11/2026; antes eram cinco).

| Coluna | Tipo | Regra |
|---|---|---|
| `id` | `STRING` | um dos seis tipos (o sexto, `merchant`: capacidade de peso 120 e saldo inicial 300 [HIP], resposta de Arthur à Q2 em 14/11/2026; `economy.md`, 9.14) |
| `weight_capacity` | `INT` | 0 ou mais; **0 = sem inventário** (só o `contract`, que é só conta) |
| `initial_balance` | `INT` | 0 ou mais; vira o `mint` inicial `game_start` ao abrir o dono (contrato, seção 3; para o `npc`, na **LW-093**); [HIP] |

[LIM] Um saldo inicial único por tipo; saldo por ofício ou por pessoa não está decidido. O **mercado** também paga a folha dos postos de serviço (decisão de Arthur), então o `initial_balance` do tipo `market` tem de cobrir a folha dos primeiros dias além das compras de produto (calibração na LW-112). Os postos de serviço **não** são donos (não têm conta).

## `market_targets.json` (LW-090): estoque por (assentamento, bem)

| Coluna | Tipo | Regra |
|---|---|---|
| `id` | `STRING` | por convenção `mt_<settlement_id>_<good_id>` (único) |
| `settlement_id` | `STRING` | id de `world/settlements` (D1) |
| `good_id` | `STRING` | referência a `goods` (`set_ref`) |
| `target_stock` | `INT` | 0 ou mais; **0 = bem não negociado nesse mercado**; dado **fixo** na Fase 3 (aprovado por Arthur em 11/11/2026, DEC-139; "dias de consumo" é calibração, LW-112) |
| `initial_stock` | `INT` | 0 ou mais; **não maior que o teto de compra** (`target_stock` × `buy_cap_bp` ÷ 10000) |
| `buy_cap_bp` | `INT` | 10000 ou mais; **teto de compra** em pontos-base do `target_stock` (Q21, aprovado por Arthur em 11/11/2026, DEC-177; entra na LW-090); [HIP], **partida 20000** (2 vezes o alvo, onde o preço chega ao piso com `min_factor_bp` 5000) |

Regras (no carregador): o par (`settlement_id`, `good_id`) é **único**; todo assentamento tem pelo menos um bem com `target_stock` maior que 0. Com 3 povoados e 10 bens são **30 linhas**: cada mercado negocia os **10 bens** (`target_stock` maior que 0), para a importação poder ser comprada [PROPOSTA]; **quem produz o quê** está em `production_sites` (abaixo). **Teto de compra (contrato, seção 4):** acima de `target_stock × buy_cap_bp ÷ 10000` o mercado **não compra**: a ordem de venda é recusada inteira com `ECON_MARKET_FULL` e o local de produção vende só até o espaço que sobra, parando por `OUTPUT_FULL` (sem perder eficiência) quando o inventário dele enche; a compra **do** mercado (`buy`) não é afetada.

**Estoque inicial até o comerciante (Q17, aprovada por Arthur em 11/11/2026, DEC-166; Q20, aprovada por Arthur em 11/11/2026, DEC-176, e o tecido, DEC-178, de 10/11/2026; dado na LW-097).** O comerciante só chega na **LW-098**; até lá, o que um povoado importa vem do `initial_stock` do próprio mercado, **dimensionado para 30 dias** (o horizonte do soak da LW-097). Os **soaks de 1 ano** (LW-109 e LW-110) **só rodam depois da LW-098**. Linhas de `market_targets` que levam estoque de bem importado (números [HIP], pequenos):

| Povoado | `good_id` | Para quê | `initial_stock` (30 dias) | `target_stock` | `buy_cap_bp` |
|---|---|---|---|---|---|
| A | `tool` | manutenção dos 5 locais | 29 | 29 | 20000 |
| A | `fabric` | manutenção dos 4 locais que o gastam (A não tece) | 25 | 25 | 20000 |
| B | `tool` | manutenção dos 6 locais | 29 | 29 | 20000 |
| B | `plank` | manutenção dos 6 locais | 21 | 21 | 20000 |
| B | `flour` | insumo de `bake_bread` | 1620 (30 dias × 6 por lote × 1 lote por hora × 9 h de trabalho; LW-097e) | **810**, metade do inicial: com `buy_cap_bp` 20000 o teto de compra (1620) já cabe no peso do mercado; o preço começa no piso até o estoque descer ao alvo [HIP] | 20000 |
| C | `plank` | manutenção dos 3 locais | 15 | 15 | 20000 |
| C | `wood` | combustível de `smelt_metal` | 540 (30 dias × 2 por lote × 1 lote por hora × 9 h de trabalho; LW-097e) | **270**, metade do inicial, pelo mesmo motivo do `flour` do B [HIP] | 20000 |
| C | `fabric` | manutenção dos 2 locais que o gastam (C não tece) | 9 | 9 | 20000 |
| C | `bread` e `grain` | comida dos NPCs do C | **LW-097e: valor pequeno [HIP], `bread` 200 e `grain` 10**; 30 dias de pão dos 28 do C (3 refeições por dia: 2520) não cabem junto com a madeira no peso do mercado (5000). Até a LW-094 o `FoodStub` alimenta o C; o tamanho de verdade da comida do C sai no soak, com a população do C ainda [PENDENTE, DEC-040] | igual | 20000 |

Os outros bens de cada mercado (os que o povoado produz) começam com estoque e alvo [HIP] a propor na LW-090. **Conta dos números 29, 29, 21, 15, 25 e 9** (a partir de `site_upkeep`, abaixo): A gasta 0,95 `tool` por dia nos 5 locais (29 em 30 dias, arredondado para cima); B gasta 0,95 `tool` e 0,7 `plank` por dia nos 6 locais; C gasta 0,5 `plank` por dia nos 3 locais; **tecido (Q22):** A gasta 0,83 por dia (os 2 locais `grow_grain` a 1 a cada 5 dias, `mill_flour` a 1 a cada 3 e `cut_wood` a 1 a cada 10: 12 + 10 + 3 = **25** em 30 dias) e C gasta 0,3 por dia (`mine_ore` a 1 a cada 5 e `smelt_metal` a 1 a cada 10: 6 + 3 = **9**); **B tece o próprio tecido e não importa**. **Conferência (LW-097, `test_initial_stock_covers_30_days`; a regra de 30 dias é a DEC-176, aprovada por Arthur em 11/11/2026; a formulação e o nome do teste seguem [PROPOSTA], sem DEC):** para os bens que **não** são comida, `initial_stock` é **no mínimo 30 vezes o consumo por dia**, arredondado para cima, com o consumo por dia igual à soma, nos locais do povoado, de `quantity` ÷ `period_days` (`site_upkeep`) e de `quantity` das linhas de `recipe_inputs` × lotes por hora × **horas de trabalho por dia** (lotes por hora = `min(max_batches_per_hour, workers_wanted ÷ workers_per_batch)`, com divisão inteira; as horas são as da ação `work` na agenda do ofício esperado da receita, 9 ou 10). **Correção da LW-097e (aprovada por Arthur em 11/11/2026):** a conta do rascunho multiplicava por 24 h, o que pede 4.320 `flour` no B (peso 8.640) e 1.440 `wood` no C (peso 7.200) contra 5.000 de capacidade do mercado; com as horas de trabalho saem 1.620 e 540. A regra vale para os bens que o povoado **não produz** (os importados da tabela acima); os que ele produz repõem o próprio estoque. A **comida não tem teste de dados** (o consumo depende do `npc`): quem prova é o **soak de 30 dias, sem morte**.

## `price_params.json` (LW-090): constantes de preço (uma linha só, `id` = `price_defaults`)

Todas **em dados, nenhuma no código** (arquitetura 11.5). Somente dois números vêm de documento; os outros são **[HIP] a propor na LW-090** e calibrar na LW-112 (nenhum é requisito).

| Coluna | Tipo | O que é | Valor |
|---|---|---|---|
| `min_factor_bp` | `INT` | piso do preço, em pontos-base do valor-base | **5000** [HIP, GDD 12.3: 0,5 vez] |
| `max_factor_bp` | `INT` | teto do preço | **30000** [HIP, GDD 12.3: 3 vezes] |
| `smoothing_bp` | `INT` | fração da diferença que o preço fecha por dia | [HIP] a propor |
| `spread_bp` | `INT` | diferença total entre compra e venda | [HIP] a propor |
| `significant_change_bp` | `INT` | variação mínima para publicar `PriceChanged` | [HIP] a propor |
| `max_order_quantity` | `INT` | teto de unidades por ordem (a conta unidade a unidade tem custo proporcional) | [HIP] a propor |
| `history_days` | `INT` | dias do histórico curto de preços | [HIP] a propor |
| `shortage_threshold_bp` | `INT` | fração do alvo abaixo da qual o estoque conta como escasso | [HIP] a propor |
| `shortage_days` | `INT` | dias seguidos abaixo do limiar para declarar escassez | [HIP]; **folgadamente menor que 60** (exigência de teste: mercado sem produtor por 60 dias declara escassez) |

Faixas e regras (no carregador): colunas `_bp` de 0 a 100000; **`min_factor_bp` de 1 ou mais e menor que ou igual a `max_factor_bp`**; **`spread_bp` de 1 a 20000** (aprovado por Arthur em 11/11/2026, DEC-150); `max_order_quantity` e `history_days` de 1 ou mais; `shortage_days` de 1 a 59. **As fórmulas em inteiros estão na seção 4 do contrato.** Em resumo, com `margem(P) = ceil_div(P × spread_bp, 20000)`: `ask(P) = P + margem(P)` e `bid(P) = max(1, P − margem(P))`, de modo que vale **`1 ≤ bid(P) ≤ P < ask(P)`** para todo preço `P` de 1 ou mais e todo `spread_bp` de 1 a 20000; o `bid` **nunca é 0**, e **`spread_bp` 0 é recusado** (daria `ask` igual a `bid`).

## `recipes.json`, `recipe_inputs.json` e `recipe_outputs.json` (LW-092)

**`recipes.json`:** uma linha por receita (as 10).

| Coluna | Tipo | Regra |
|---|---|---|
| `id` | `STRING` | um dos 10 ids abaixo |
| `name_key` | `STRING` | `recipe.<id>.name`; texto em `pt_br.json` |
| `occupation_id` | `STRING` | ofício **esperado** nela (id de `occupations`, D1); a economia não confere o ofício de quem é atribuído (isso é do `npc`) |
| `workers_per_batch` | `INT` | 1 ou mais; quantos trabalhadores atribuídos fazem um lote por hora; [HIP] |
| `max_batches_per_hour` | `INT` | 1 ou mais; teto de lotes por hora; [HIP] |
| `wage_per_hour` | `INT` | 0 ou mais; pago a cada trabalhador atribuído, por hora em que o local produz, pela conta do local (contrato, seção 6; Q18 A do `npc.md`); [HIP] |

**`recipe_inputs.json`** e **`recipe_outputs.json`:** mesmo formato, uma linha por (receita, bem).

| Coluna | Tipo | Regra |
|---|---|---|
| `id` | `STRING` | por convenção `<recipe_id>_in_<good_id>` e `<recipe_id>_out_<good_id>` (único) |
| `recipe_id` | `STRING` | referência a `recipes` (`set_ref`) |
| `good_id` | `STRING` | referência a `goods` (`set_ref`) |
| `quantity` | `INT` | 1 ou mais |

Regras (no carregador e num teste de dados): o par (`recipe_id`, `good_id`) é **único** em cada tabela; toda receita tem **pelo menos uma saída**; as quatro de **extração** não têm nenhuma linha de insumo; nenhum bem é insumo e saída da mesma receita. **[PROPOSTA]** Regra de **margem**: em cada receita, o valor dos produtos (soma de `quantity` × `base_value`) é **maior** que o dos insumos mais o salário do lote (`workers_per_batch` × `wage_per_hour`), senão o local não consegue pagar o salário com a venda e para por `NO_FUNDS`; é condição necessária, não suficiente (o spread, a manutenção e o soak da LW-110 e da LW-112 dão a prova).

**As 10 receitas** (ids em inglês). Os ofícios **`miner` e `shepherd` foram decididos por Arthur** (só em dados; DEC-142, aprovada em 10/11/2026); a coluna de ofício das demais é **[PROPOSTA]**: `farmer` e `lumberjack` já existem e o resto reaproveita `artisan`:

| id | Nome (`recipe.<id>.name`) | Tipo | Insumos | Produtos | Ofício esperado |
|---|---|---|---|---|---|
| `grow_grain` | cultivar grão | extração | nenhum | `grain` | `farmer` |
| `cut_wood` | cortar madeira | extração | nenhum | `wood` | `lumberjack` |
| `mine_ore` | extrair minério | extração | nenhum | `ore` | `miner` (novo) |
| `shear_wool` | tosquiar lã | extração | nenhum | `wool` | `shepherd` (novo) |
| `mill_flour` | moer farinha | transformação | `grain` | `flour` | `artisan` |
| `bake_bread` | assar pão | transformação | `flour` | `bread` | `artisan` |
| `saw_plank` | serrar tábuas | transformação | `wood` | `plank` | `artisan` |
| `smelt_metal` | fundir metal | transformação | `ore` e `wood` (combustível) | `metal` | `artisan` |
| `forge_tool` | forjar ferramenta | transformação | `metal` | `tool` | `artisan` |
| `weave_fabric` | tecer tecido | transformação | `wool` | `fabric` | `artisan` |

**As quantidades** de cada linha (quanto de insumo por quanto de produto) são **[HIP] a propor na LW-092** e calibrar na LW-112; este documento **não as inventa**.

## `site_upkeep.json` (LW-092): manutenção dos locais de produção

**Decisão de Arthur: consumo = manutenção dos locais.** Os locais de produção **gastam `tool`, `plank` e `fabric` aos poucos** para funcionar (o tecido, lonas e sacos, entrou por **decisão de Arthur**, Q22; DEC-178 da LW-087a); o NPC só consome comida. Uma linha por (receita, bem de manutenção). Os postos de serviço **não** têm manutenção.

| Coluna | Tipo | Regra |
|---|---|---|
| `id` | `STRING` | por convenção `upkeep_<recipe_id>_<good_id>` (único) |
| `recipe_id` | `STRING` | referência a `recipes` (`set_ref`) |
| `good_id` | `STRING` | referência a `goods` (`set_ref`); vocabulário fechado no carregador: **`tool`, `plank` ou `fabric`** na Fase 3 |
| `quantity` | `INT` | 1 ou mais; unidades gastas a cada período |
| `period_days` | `INT` | 1 ou mais; "gasto por dia" = `quantity` ÷ `period_days` |

Regras (no carregador): o par (`recipe_id`, `good_id`) é **único**. **Números de partida [HIP, pequenos, calibração na LW-112]:**

| Receita | `tool` (1 unidade a cada N dias) | `plank` (1 unidade a cada N dias) | `fabric` (1 unidade a cada N dias) |
|---|---|---|---|
| `grow_grain` | 5 | 10 | 5 |
| `cut_wood` | 4 | 10 | 10 |
| `mine_ore` | 3 | 5 | 5 |
| `shear_wool` | 10 | 10 | 10 |
| `mill_flour` | 10 | 5 | 3 |
| `bake_bread` | 10 | 5 | 10 |
| `saw_plank` | 5 | 20 | sem linha |
| `smelt_metal` | 5 | 5 | 10 |
| `forge_tool` | 5 | 10 | sem linha |
| `weave_fabric` | 10 | 10 | 10 |

**Por que o tecido está onde está [HIP].** São lonas (para cobrir a lenha, a mina e a fornalha) e sacos (para o grão, a farinha e o pão): o moinho gasta mais (1 a cada 3 dias) e a lavoura, a mina e o forno vêm depois; a serraria e a forja **não** levam linha de `fabric`. A tabela completa tem **28 linhas** (10 de `tool`, 10 de `plank` e 8 de `fabric`). A conta do que isso rende ao tecelão e ao pastor está na seção seguinte.

**Como o gasto funciona (contrato, seção 6).** O local **compra** do mercado local o bem da regra vencida, pelo mesmo `request_trade`; ao fim do dia, a regra vencida e paga **destrói** as peças com o motivo `maintenance` (conjunto fechado de motivos e conservação de bens). **Sem manutenção a produção cai por degrau, não para:** a eficiência do local cai a cada dia com regra vencida e não paga, até um piso maior que 0 (`site_params`), e volta quando a manutenção é paga. **Testes (nas tarefas que criam a tabela):** de dados (o bem existe e é `tool`, `plank` ou `fabric`; par único) e **de propriedade** (sem peças a eficiência cai até o piso e nunca zera; com peças volta a 10000; a conservação de bens fecha com `maintenance`; mesma semente, mesmo resultado).

## A conta do tecido (Q22): o que sustenta o tecelão e o pastor [HIP, ilustrativa]

**Decisão de Arthur (Q22; DEC-178 da LW-087a):** o tecido entra na manutenção dos locais, para ter comprador. Esta conta mostra **quanto isso sustenta** a cadeia da lã e do tecido e **onde ela é fina**. Todos os números são **[HIP] e ilustrativos**: servem para dimensionar `site_upkeep`, `wage_per_hour` e `base_value`; **a calibração é da LW-112** e a prova é o soak da LW-110. O símbolo **`f`** é o custo de **um dia de comida de uma pessoa** (vira número na LW-112, a partir do `base_value` de `bread` e de `grain`).

**1. Quanto tecido os locais gastam por dia** (uma unidade a cada N dias é 1 ÷ N por dia, tabela acima):

| Povoado | Locais que gastam tecido | Conta | Tecido por dia |
|---|---|---|---|
| A | `grow_grain` ×2 (N = 5), `mill_flour` (N = 3), `cut_wood` (N = 10); a serraria não gasta | 0,400 + 0,333 + 0,100 | **0,833** |
| B | `grow_grain` ×2 (5), `cut_wood` (10), `bake_bread` (10), `shear_wool` (10), `weave_fabric` (10) | 0,400 + 0,100 + 0,100 + 0,100 + 0,100 | **0,800** |
| C | `mine_ore` (5), `smelt_metal` (10); a forja não gasta | 0,200 + 0,100 | **0,300** |
| **Total** | 12 dos 14 locais | | **1,933** |

**2. Quantas horas por dia o tecelão e o pastor trabalham.** Suposição de trabalho da conta, **que não é dado** (as quantidades de verdade são da LW-092): um lote de `weave_fabric` por hora, feito por 4 trabalhadores, dá **2 `fabric`** a partir de **2 `wool`**; um lote de `shear_wool` por hora, com 4 trabalhadores, dá **2 `wool`**. O local só produz o que o mercado absorve (o teto de compra, Q21, e a manutenção são a procura), então as horas por dia são a procura ÷ o rendimento do lote:

| Situação | Tecido por dia | Horas do tecelão por dia | Lã por dia (1 `wool` por `fabric`) | Horas do pastor por dia |
|---|---|---|---|---|
| Depois da LW-098 (o comerciante leva tecido do B a A e C) | 1,93 | **0,97** | 1,93 | **0,97** |
| Até a LW-098 (só o B consome o próprio tecido) | 0,80 | **0,40** | 0,80 | **0,40** |

**3. O que rende ao trabalhador.** Pela regra "hora parada = ninguém recebe" (Q18 A), só se ganha nas horas em que o local produz. Para a renda do dia igualar `f` com 0,97 hora de produção, o `wage_per_hour` precisa ser **f ÷ 0,97 ≈ 1,03 f**; a conta adota **1,1 f** (cerca de **um dia de comida por hora de produção**, 6% de sobra):

- **Folha** por hora de produção: 4 × 1,1 f = **4,4 f**; por unidade (2 por hora): **2,2 f**. A folha por unidade é cerca de 4 f ÷ 1,93 e **não depende do rendimento do lote**, só da procura diária (com 1 unidade por hora, o tecelão trabalharia 1,93 hora por dia e o `wage_per_hour` cairia para cerca de 0,5 f; com 4 unidades, 0,48 hora e cerca de 2,1 f).
- **Lã:** o pastor vende ao `bid`. Com `spread_bp` de 1000 [HIP] (`bid` = 0,95 e `ask` = 1,05 do preço), o preço da lã tem de ser **2,2 f ÷ 0,95 ≈ 2,3 f** ou mais: `base_value` de `wool` perto de **2,5 f**.
- **Tecido:** o tecelão compra a lã ao `ask` (1,05 × 2,5 f ≈ 2,6 f) e paga a folha (2,2 f): **4,8 f** por unidade, vendida ao `bid`; o preço tem de ser **4,8 f ÷ 0,95 ≈ 5,1 f** ou mais: `base_value` de `fabric` perto de **5 f**.
- **Regra de margem** (seção das receitas): tecido, 2 × 5 f = 10 f **maior que** 2 × 2,5 f + 4,4 f = 9,4 f; lã, 2 × 2,5 f = 5 f **maior que** 4,4 f. Fecha, **com folga pequena**.
- **Rende:** 0,97 hora × 1,1 f ≈ **1,06 f por dia** para cada trabalhador das duas funções (um dia de comida e 6% de sobra). Até a LW-098 seriam 0,40 hora × 1,1 f = 0,44 f por dia: **só o dinheiro inicial** sustenta esses trabalhadores nos 30 dias da LW-097.

**4. Peso no mercado.** O gasto total com tecido é cerca de 1,93 × 5 f ≈ **10 f por dia** nos três povoados, contra **100 f por dia** só de comida dos 100 NPCs de A e B (1 f por pessoa por dia): pequeno para o mercado, mas é **a única procura** pelo tecido.

**5. Onde a conta é fina, e o plano B.** Duas funções vivem de cerca de uma hora de trabalho por dia, então tudo depende de `wage_per_hour` perto de 1,1 f e de valores-base altos para a lã e o tecido (e de a LW-112 acertá-los). **Se o soak da LW-110 mostrar fome** no tecelão ou no pastor, a decisão **volta a Arthur** (`economy.md`, seção 6, plano B da Q22), com duas opções: **(1)** aumentar o consumo de tecido (mais linhas ou `period_days` menores em `site_upkeep`; só dados) ou **(2)** o mercado pagar as horas paradas dessas duas receitas, como paga a folha dos postos. A calibração só em dados da LW-112 vem antes e **não** precisa dele.

## `site_params.json` (LW-092): eficiência dos locais (uma linha só, `id` = `site_defaults`)

| Coluna | Tipo | O que é | Valor |
|---|---|---|---|
| `efficiency_step_bp` | `INT` | queda da eficiência por dia com manutenção vencida e não paga | [HIP] a propor (partida: 1000) |
| `efficiency_recover_bp` | `INT` | subida da eficiência por dia sem manutenção vencida e não paga | [HIP] a propor (partida: 1000) |
| `min_efficiency_bp` | `INT` | piso da eficiência: **a produção nunca zera por falta de manutenção** | [HIP] a propor (partida: 3000) |

Faixas e regras (no carregador): `min_efficiency_bp` de **1 a 10000** (maior que 0: evita a espiral de morte); `efficiency_step_bp` e `efficiency_recover_bp` de 1 a 10000.

## `production_sites.json` (LW-092): os locais de produção

| Coluna | Tipo | Regra |
|---|---|---|
| `id` | `STRING` | por convenção `site_<a, b ou c>_<recipe_id>`, com `_1` e `_2` quando a receita se repete no povoado (único) |
| `settlement_id` | `STRING` | id de `world/settlements` (D1) |
| `place_id` | `STRING` | um local de tipo `work` de `world/places` do mesmo povoado, **um por local de produção ou posto** (D1) |
| `recipe_id` | `STRING` | referência a `recipes` (`set_ref`) |
| `workers_wanted` | `INT` | 1 ou mais; a equipe desejada, **não maior que a capacidade do local** (D1); abaixo disso a economia posta uma vaga |

Cada linha vira um local de produção (`site_id` inteiro de `ctx.ids`) em `on_new_game`, dono do tipo `site` (conta e inventário próprios, contrato Q4).

## `service_posts.json` (LW-095): os postos de serviço

**Decisão de Arthur (Q15):** cada povoado tem **postos de serviço**, um local de trabalho **sem receita** para guarda e estalajadeiro; a **folha é paga pela conta do mercado do povoado**; **provisório até a Fase 4**.

| Coluna | Tipo | Regra |
|---|---|---|
| `id` | `STRING` | por convenção `post_<a, b ou c>_<guard ou inn>` (único) |
| `settlement_id` | `STRING` | id de `world/settlements` (D1) |
| `place_id` | `STRING` | um local de tipo `work` do mesmo povoado, **um por local de produção ou posto** (D1) |
| `occupation_id` | `STRING` | ofício esperado (`guard` ou `innkeeper`; id de `occupations`, D1) |
| `workers_wanted` | `INT` | 1 ou mais; não maior que a capacidade do local (D1) |
| `wage_per_hour` | `INT` | 0 ou mais; pago a cada trabalhador atribuído, por hora, pela conta do **mercado** do povoado; [HIP] |

Regra de funcionamento (contrato, seção 6): folha **tudo ou nada por posto e por hora**; mercado sem fundos para a folha do posto: o posto **para com `NO_FUNDS` e ninguém recebe naquela hora**. **Provisório sem marca `TEMP` (Q18, aprovada por Arthur em 11/11/2026, DEC-174; a DEC-164, aprovada por Arthur em 10/11/2026, fixa o provisório até a Fase 4):** é regra de jogo até a Fase 4, não código a remover; **não há coluna `temp_mark` nesta tabela** (as linhas de `food_stub.json` e `income_stub.json` a têm porque aqueles provisórios saem do código). O `tools/check_temp` continua exigindo **zero marcas** ao fim da Fase 3 e os postos não o atingem.

## `contract_templates.json` (LW-107a, formato; implementado na LW-107c1): os modelos do postador de contratos de entrega

Contrato **APROVADO por Arthur em 14/11/2026** (PR #33); todos os números são [HIP] e os nomes de arquivo, coluna e teste são [PROPOSTA técnica]. Cada linha é um modelo que o `ContractPoster` (`economy.md`, seção 8) usa, por mercado e a cada hora cheia, para postar um contrato `delivery` cujo emissor e cujo destino são o próprio mercado. **Arquivo OPCIONAL** (como `service_posts.json`): sem ele não há modelo e nada é postado; a tabela, se existe, pode estar vazia. **Padrão do jogo desde a LW-107c2: a tabela VAZIA (`[]`), medida TEMPORÁRIA de integração segura (decisão de Arthur de 15/11/2026; NÃO é decisão de manter os contratos inativos): os 3 modelos iniciais (tabela abaixo) ficam em `data/economy/contract_templates.initial.json`, arquivo de exemplo que o jogo NÃO lê; a ativação é a pendência LW-107c3 (`docs/backlog.md`).** **Sem texto ao jogador na tabela:** a tela monta "Entregar N x Bem" por chaves (`ui.contracts.*` e `good.<id>.name`).

| Coluna | Tipo | Regra |
|---|---|---|
| `id` | `STRING` | por convenção `<bem>_<gatilho>` (por exemplo, `bread_standing`); único |
| `kind` | `STRING` | só `delivery` nesta etapa (o `labor` por tempo é de categorias futuras, DEC-237; a LW-107f são as encomendas de entrega) |
| `good_id` | `STRING` | id de `goods.json` (mesma leitura); **um modelo por bem** (o postador reconhece o contrato "do modelo" pelo bem) |
| `quantity` | `INT` | 1 ou mais; o lote cabe no inventário do jogador: `quantity × weight` do bem não passa da `weight_capacity` do tipo `player` em `owner_kinds.json` (60 hoje, [HIP]) **[PROPOSTA]** |
| `trigger` | `STRING` | `shortage` (o bem está com a escassez declarada no mercado) ou `standing` (fixo: sempre que o espaço e a regra anti-exploração permitem) |
| `reward_margin_bp` | `INT` | bônus sobre o valor-base do bem, em pontos-base: `reward = ceil_div(quantity × base_value × (10000 + reward_margin_bp), 10000)`. **Faixas [HIP]:** `shortage` de **0 a 5000** (0 a 50%; referência 2500, isto é, 25%) e `standing` de **0 a 1000** (0 a 10%) |
| `deadline_hours` | `INT` | 1 a 168 **[HIP]**; o prazo é `(agora - agora % 60) + deadline_hours × 60` minutos de simulação, isto é, conta do INÍCIO da hora cheia da publicação (decisão de Arthur de 15/11/2026), e não do minuto em que o evento horário é processado: o prazo fica igual com passos de 1, 7 ou 60 minutos (a 1x, 48 h de jogo valem 60 minutos reais) |
| `max_open` | `INT` | 1 a 3 **[HIP]**; no máximo tantos contratos do modelo em `open` ou `accepted` ao mesmo tempo, por mercado |

**Regras e faixas (no carregador, `ECON_DATA_INVALID` com arquivo, item e campo):** `id` único; `kind` igual a `delivery`; `good_id` existe em `goods.json` e não se repete na tabela; `trigger` do vocabulário fechado (`shortage`, `standing`); `reward_margin_bp` dentro da faixa **do gatilho do próprio modelo**; `quantity` de 1 ou mais e o lote cabe no jogador; `deadline_hours` e `max_open` nas faixas. Nenhum `FLOAT` (AGENTS 4.11).

**Regra anti-exploração (decisão de Arthur de 14/11/2026; `economy.md`, seção 8, tem a regra completa).** **A proteção atua na POSTAGEM do contrato; o aceite NÃO ganha nenhuma restrição econômica nova** (nem conferência de custo nem da regra (b) no `accept`; a de prazo existe na ponte e na economia: contrato vencido não se aceita, correção da LW-096 de 14/11/2026). Quatro camadas: **(a)** as faixas acima, no carregador; **(b)** o postador NÃO publica contrato cuja recompensa seja maior que o custo de comprar o mesmo lote no próprio mercado emissor (`reward` menor ou igual ao `ask` de hoje do bem naquele mercado vezes `quantity`; o custo real, a soma por degrau, é maior ou igual), então comprar e entregar no mesmo mercado não dá lucro na hora de postar; **(c)** um teste de propriedade com os dados reais prova (b) em todos os mercados e modelos (`tests/unit/test_contract_poster_no_profit.gd`); **(d)** para o risco residual de lucro fácil (o preço do emissor cair depois de postar), um teste de 30 dias de jogo, `tests/integration/test_contract_poster_residual_profit.gd` (LW-107c2, **[PROPOSTA técnica]**; de integração, porque simula 720 horas com ações do jogador, AGENTS 9.3; a estimativa de tempo no `check_all` está em `economy.md`, seção 8): o lucro acumulado por mercado de comprar no emissor, aceitar e entregar em ciclos repetidos tem de ficar abaixo de um teto [HIP] pequeno, 10% do saldo inicial do tipo `market` (300 hoje; `economy.md`, seção 8, traz a conta); passou do teto, a 107c2 PARA e mostra a Arthur. O `ask` já inclui o `spread_bp` (1000, 10%): por isso a faixa do `standing` termina em 1000. Consequência: em mercado farto (preço de tabela abaixo do valor-base) um modelo `standing` pode não postar, e o quadro pode ficar sem esse contrato, até **temporariamente vazio, o que é ACEITÁVEL** (decisão de Arthur de 14/11/2026): sem contrato economicamente viável a tela explica com `ui.contracts.empty` ("Nenhum contrato agora: os mercados estão abastecidos"), e nenhuma faixa nem regra se afrouxa só para encher o quadro.

**Dados iniciais sugeridos [HIP]** (em `contract_templates.initial.json`; 3 modelos de comida; no começo do jogo, com o estoque no alvo, o pão vale 10 e o `ask` 11; no máximo 178 de recompensa retida por mercado, 6% do saldo inicial de 3000 do tipo `market`):

| `id` | `good_id` | `quantity` | `trigger` | `reward_margin_bp` | `deadline_hours` | `max_open` | recompensa (valor-base) |
|---|---|---|---|---|---|---|---|
| `bread_standing` | `bread` | 5 | `standing` | 500 | 48 | 1 | 53 (10); cabe nos 55 do `ask` de hoje |
| `flour_shortage` | `flour` | 10 | `shortage` | 2500 | 48 | 1 | 75 (6) |
| `grain_shortage` | `grain` | 10 | `shortage` | 2500 | 48 | 1 | 50 (4) |

Conta de exemplo da referência de 25%: 5 pães a 2500 bp valem `ceil_div(5 × 10 × 12500, 10000)` = 63 e só nascem com o `ask` do pão em 13 ou mais.

## `contract_limits.json` (LW-107f2; contrato de 16/11/2026, D1 aprovado por Arthur): o limite de encomendas aceitas ao mesmo tempo, por categoria

Cada linha é o máximo de contratos de UMA categoria (`kind`) que o jogador pode ter ACEITOS ao mesmo tempo (`economy.md`, seção 8, item (c)). O número é **PROVISÓRIO do primeiro recorte** (valor aprovado por Arthur em 16/11/2026) e **[HIP]**; a regra NÃO é global: vale só para a categoria da linha, e a categoria sem linha não herda o limite de outra. **Arquivo OPCIONAL** (como `contract_templates.json`): arquivo ausente, tabela vazia ou categoria sem linha = SEM limite definido por este dado (`EconomyModule.peek_contract_limit(kind)` devolve 0). **Quem aplica é a ponte, no `accept` do jogador** (LW-107f3, contando os `accepted` do ator ainda não vencidos); a economia só informa o número, e o `ContractBook.accept` segue sem teto para qualquer aceitante (um NPC, os testes e as ferramentas aceitam sem limite). **Sem texto ao jogador na tabela.** Formato: uma lista de objetos na raiz (como as outras tabelas; o nome da tabela no esquema é `contract_limits`).

| Coluna | Tipo | Regra |
|---|---|---|
| `id` | `STRING` | por convenção `<kind>_limit` (por exemplo, `delivery_limit`); único. O `id` é o campo implícito que o `data` exige em todo registro (DEC-082): o exemplo de linha do contrato (`economy.md`, item (c)) cita só `kind` e `max_accepted` |
| `kind` | `STRING` | a categoria: um de `labor`, `delivery` e `vacancy` (o vocabulário de `ContractBook.CONTRACT_TYPES`); **uma linha por categoria** (não se repete) |
| `max_accepted` | `INT` | 1 a 20 **[HIP]**; 0 não é linha válida, porque "sem limite" é a categoria SEM linha |

**Regras e faixas (no carregador, `ContractLimitLoader`, `ECON_DATA_INVALID` com arquivo, item e campo):** `id` único; `kind` do vocabulário e sem repetição (o item citado é a linha repetida); `max_accepted` inteiro de 1 a 20; campo desconhecido, ausente ou de tipo errado, linha que não é objeto e JSON malformado falham. Nenhum `FLOAT` (AGENTS 4.11).

**Dado inicial (o arquivo REAL do jogo):** uma linha, `{"id": "delivery_limit", "kind": "delivery", "max_accepted": 3}`, isto é, no máximo 3 encomendas de entrega aceitas ao mesmo tempo (D1 de Arthur); `labor` e `vacancy` ficam sem linha. Teste: `tests/unit/test_contract_limits_data.gd`.

## Distribuição das 4 cadeias pelos 3 povoados, com os locais `work` contados [PROPOSTA/HIP]

Arthur decidiu o princípio (**nenhum povoado se baste sozinho**) e a criação dos ofícios `miner` e `shepherd` (DEC-142, aprovada em 10/11/2026); **a tabela é [PROPOSTA/HIP], sem DEC no registro da LW-087a, para ele aprovar**, com nomes genéricos (DEC-100). **Cada local de produção e cada posto ocupa um local `work` próprio.** Os números de capacidade e de população são os do `main`:

| Povoado | Locais de produção (receita × quantidade) | Postos | Locais `work` precisos | Existem hoje | A criar |
|---|---|---|---|---|---|
| A (`test_settlement_a`) | `grow_grain` ×2, `mill_flour`, `cut_wood`, `saw_plank` (5) | `guard`, `innkeeper` (2) | 7 | 5 de capacidade 12 | **2** |
| B (`test_settlement_b`) | `grow_grain` ×2, `cut_wood`, `bake_bread`, `shear_wool`, `weave_fabric` (6) | `guard`, `innkeeper` (2) | 8 | 5 de capacidade 8 | **3** |
| C (3º povoado, LW-097) | `mine_ore`, `smelt_metal`, `forge_tool` (3) | `guard`, `innkeeper` (2) | 5 | 0 | **5** |
| **Total** | **14** | **6** | **20** | **10** | **10** |

**Capacidade contra pessoas.** Hoje a capacidade dos locais `work` é **exatamente igual** à população (A: 5 × 12 = 60 pessoas; B: 5 × 8 = 40) e a população os preenche **por vaga, sem ligar ofício a local**. Com a distribuição proposta e as pessoas de hoje (`population.json`):

| Povoado | Ofício (pessoas hoje) | Onde trabalha | `workers_wanted` | Capacidade do local |
|---|---|---|---|---|
| A | `farmer` (24) | `site_a_grow_grain_1` e `_2` | 12 e 12 | 12 e 12 |
| A | `lumberjack` (10) | `site_a_cut_wood` | 10 | 12 |
| A | `artisan` (12) | `site_a_mill_flour` e `site_a_saw_plank` | 6 e 6 | 12 e 12 |
| A | `guard` (8) | `post_a_guard` | 8 | 12 |
| A | `innkeeper` (6) | `post_a_inn` | 6 | 12 |
| B | `farmer` (16) | `site_b_grow_grain_1` e `_2` | 8 e 8 | 8 e 8 |
| B | `lumberjack` (8) | `site_b_cut_wood` | 8 | 8 |
| B | `artisan` (8) | `site_b_bake_bread` e `site_b_weave_fabric` | 4 e 4 | 8 e 8 |
| B | `shepherd` (**novo**, quantidade [HIP] a decidir na LW-097) | `site_b_shear_wool` | [HIP] 4 | 8 |
| B | `guard` (5) | `post_b_guard` | 5 | 8 |
| B | `innkeeper` (3) | `post_b_inn` | 3 | 8 |
| C | `miner` (novo), `artisan`, `guard`, `innkeeper` | os 3 locais de produção e os 2 postos | **[PENDENTE, DEC-040]** | a criar (capacidade [HIP]) |

**Basta um posto por ofício e por povoado** (8 guardas e 6 estalajadeiros cabem em locais de 12; 5 e 3, em locais de 8). Só os locais `grow_grain` precisam de **dois locais cada**, porque 24 e 16 lavradores passam da capacidade de um local. Isso exige **10 locais `work` novos** e a coluna **`work_place_id` em `population.json`** (decisão de Arthur, DEC-144, de 10/11/2026: a população inicial nasce empregada por dados; a coluna `work_place_id` é a DEC-167, aprovada por Arthur em 11/11/2026; o carregador do `npc` passa a aceitar a coluna, mudança pequena de código). A população do 3º povoado e os **hashes novos** (o oráculo e o soak de 30 dias; o `run_sim` não muda, porque não registra módulos) são da LW-097 (**marco 3** de hash, por bloco: `economy.md`, seção 2; o `run_sim` não muda, nem o hash que ele imprime), **com a aprovação de Arthur dos valores novos**.

**Quem depende de quem:** A não faz `bread` nem `fabric` (do B) nem `tool` (do C); B não faz `flour` nem `plank` (do A) nem `tool` (do C); C não faz `wood` (do A ou do B), comida (`grain` do A ou do B, `bread` do B), `plank` nem `fabric`.

**Teste de dados `test_economy_distribution.gd` (LW-097; o princípio é a DEC-142, aprovada por Arthur em 10/11/2026; a formulação e o nome do teste seguem [PROPOSTA], sem DEC).** Seja `Produzido(P)` o conjunto de bens que os locais de produção do povoado `P` produzem (`production_sites` + `recipe_outputs`) e `Necessário(P)` a união dos insumos das receitas de `P` (`recipe_inputs`), dos bens de manutenção dos locais de `P` (`site_upkeep`) e de `bread`. **`test_no_settlement_is_self_sufficient`:** para todo povoado `P`, `Necessário(P)` **menos** `Produzido(P)` **não é vazio**. **`test_every_needed_good_has_a_producer`:** todo bem de algum `Necessário(P)` é produzido por algum local de algum povoado. Com a distribuição proposta: A depende de `tool`, `fabric` e `bread`; B, de `flour`, `tool` e `plank` (B tece o próprio tecido); C, de `wood`, `plank`, `fabric` e `bread`. O tecido conta como bem necessário porque `site_upkeep` o lista (Q22). O teste lê só tabelas da economia e vem **com os dados do 3º povoado, na LW-097**.

## `caravan_params.json` (LW-098b): parâmetros do comerciante e da caravana [HIP; formato autorizado por Arthur em 14/11/2026]

Uma linha só, `id` = `caravan_defaults` (como `price_defaults` e `site_defaults`; a especificação da LW-098a escrevia `default`). Todas as colunas são `INT`; dinheiro na menor unidade e proporções em pontos-base (`_bp`). São parâmetros de **decisão e de tempo**: nenhum move dinheiro (o comerciante não paga custo de viagem; `economy.md`, 9.6). O esquema é declarado em código, na 098b; a formulação em que cada coluna entra é `economy.md`, 9.3 (tempo do trecho) e 9.5 (planejador). Nasce na 098b; o formato inicial foi **autorizado por Arthur em 14/11/2026** (AGENTS 16.2), limitado ao contrato, com testes de serialização, compatibilidade e determinismo (abaixo).

| Coluna | Tipo | Regra | Partida [HIP] | Para que serve |
|---|---|---|---|---|
| `id` | `STRING` | `caravan_defaults` | | a única linha |
| `speed_cm_per_min` | `INT` | 1 a 100.000 | 400 | velocidade da caravana (4 m por minuto de jogo; a caminhada do NPC é 500 cm por minuto) |
| `difficulty_slowdown_bp` | `INT` | 0 a 10.000 | 50 | lentidão do trecho por ponto de dificuldade da rota |
| `risk_bp_per_point` | `INT` | 0 a 10.000 | 25 | desconto de decisão por ponto de risco da rota, sobre a receita (Q3: sem perda real) |
| `time_cost_per_hour` | `INT` | 0 ou mais | 2 | custo de oportunidade do tempo de viagem (igual ao `time_cost_per_hour` de `npc_params.json`) |
| `fixed_cost` | `INT` | 0 ou mais | 5 | custo fixo de decisão por viagem |
| `min_net_profit` | `INT` | 0 ou mais | 20 | lucro mínimo esperado para partir |
| `min_margin_bp` | `INT` | 0 a 100.000 | 500 | margem mínima do lucro sobre o custo da compra (5%) |
| `origin_reserve_bp` | `INT` | 0 a 10.000 | 5000 | fração do **alvo** de estoque que o comerciante nunca tira do mercado de origem (Q8) |

Conta de conferência (as rotas reais, com estes [HIP]): o trecho de 520 m com dificuldade 20 leva `ceil_div(52000 × 11000, 400 × 10000)` = **143 minutos**; 430 m e dificuldade 30, **124**; 340 m e dificuldade 25, **96**. O custo de tempo de uma viagem A–B é `ceil_div(143 × 2, 60) + 5` = 10. **Testes de dados (098b):** arquivo real carrega; campo ausente, tipo errado, campo desconhecido, mais de uma linha, `id` diferente de `caravan_defaults` e faixa inválida falham apontando arquivo, item e campo (`ECON_DATA_INVALID`); carregar duas vezes dá o mesmo resultado. **Serialização, compatibilidade e determinismo (exigidos por Arthur em 14/11/2026):** a linha reescrita e relida dá o mesmo objeto; `EconomySetup.from_dir` carrega a pasta real `data/economy/` com o arquivo novo, `check_content_ids` verde e nenhum outro carregador alterado; a mesma entrada dá o mesmo resultado. Textos ao jogador nunca vão nesta tabela.

## Ofícios novos (dado do `npc`)

`occupations.json` ganha **`miner`** (mineiro) e **`shepherd`** (pastor), cada um com `work_place_kind` `work`, **só em dados** (decisão de Arthur). Entram com a LW-092 ou a LW-097. Cada ofício novo também precisa de **agenda própria** em `routine_blocks.json` (o carregador de rotina rejeita ofício sem agenda): dado, mas escrito pelo `npc` (extensão do `npc.md`). Os nomes são genéricos e provisórios (DEC-100).

**O comerciante em outros arquivos (LW-098c, LW-098f1, LW-098f2 e LW-098h; contrato aprovado por Arthur em 14/11/2026; `economy.md` 9.9 e `npc.md` 14.11).** **Autorizado, limitado a este contrato, com testes de serialização, compatibilidade e determinismo:** (a) `owner_kinds.json` ganha a linha `merchant` (`weight_capacity` 120 e `initial_balance` 300 [HIP]) **na 098c**, no mesmo commit da constante `KIND_MERCHANT` (o `check_content_ids` a exige), com o `test_goods_data.gd` passando de 5 para 6 tipos; (b) **na 098f1**, `occupations.json` ganha `{"id":"merchant","work_place_kind":"market"}` e a coluna opcional `owner_kind` (`STRING`, id de `economy/owner_kinds.json`, conferido pelo verificador de ids como as outras referências entre módulos, D1, por uma linha nova em `REFERENCES` de `tools/check_content_ids.gd`; sem a coluna vale `npc`), com a agenda em `routine_blocks.json` (ainda sem `haul`, que só nasce na 098f2: as horas de trabalho entram como `rest` [HIP]); (c) **na 098f1**, `npc_params.json` ganha dois campos opcionais, ambos `INT` com faixa de 0 a 1.000: `haul_value_percent` (partida 100 [HIP]: um ponto de utilidade por moeda de lucro esperado) e `sell_value_percent` (partida 100 [HIP]: um ponto por moeda do total da cotação de venda da sobra); sem eles o valor vale 0 e o arquivo antigo carrega como hoje; (d) **na 098f2**, `actions.json` ganha a ação `haul` e as horas de trabalho da agenda passam a ela; os ofícios antigos seguem iguais. **Fora do mandato, só na 098h (aprovação específica de Arthur, DEC-175):** `population.json` ganha as linhas do ofício (**dois comerciantes por povoado, seis no total**, `count` 2 em cada, `work_place_id` = o local de mercado: `a_market_01`, `b_market_01`, `c_market_01`); `world/places.json` ganha **as seis casas** (uma por comerciante; o A está com 60 de 60 e o B com 44 de 45, e sem casa vale `NPC_POPULATION_NO_ROOM`; capacidade e posição [HIP]); `market_targets.json` ganha os **preços iniciais diferenciados** (Q7: diferenças de `initial_stock` entre mercados nos bens que o comerciante leva, respeitando `initial_stock` no máximo `target_stock` × `buy_cap_bp` ÷ 10000 e a regra de 30 dias da DEC-176). Tudo isso muda os hashes e **PARA** (DEC-175), e `data/` só se altera onde o texto da tarefa mandar expressamente (AGENTS 12.5). O `check_content_ids` e o `PopulationPlan` podem recusar `merchant` num `work_place_id` de mercado (risco T3, `economy.md` 9.13).

## O que mais vem dos mesmos arquivos de contrato

`world/routes.json` (LW-097) é dado e contrato do `world`. Parâmetros de contrato (prazos mínimos, teto de recompensa; LW-096) **não** são modelados aqui: ganham tabela quando o contrato da respectiva tarefa for escrito (AGENTS 5.6, contrato primeiro); **os do comerciante (LW-098) estão em `caravan_params.json`, acima (contrato aprovado por Arthur em 14/11/2026)**. As marcas **TEMP** `data/food_stub.json` e `data/income_stub.json` saem nas LW-094 e LW-095. **LW-107a:** os modelos de contrato do postador (bem, quantidade, gatilho, bônus, prazo em horas e máximo de abertos) ganharam a seção `contract_templates.json` acima; prazo mínimo e teto de recompensa seguem sem tabela (o teto prático é a regra anti-exploração (b)).

## Testes previstos para estes dados (nas tarefas que criam cada tabela)

Arquivo real carrega e devolve os objetos tipados; **dado inválido falha** apontando arquivo, item e campo (campo ausente, tipo errado, campo desconhecido, id repetido, referência quebrada, faixa inválida, vocabulário fora do fechado, par repetido, `min_factor_bp` maior que `max_factor_bp`, `spread_bp` 0, `min_efficiency_bp` 0); a regra de margem e a de "um bem, uma receita"; **manutenção** (testes de dados e de propriedade, acima; o vocabulário de `site_upkeep` é `tool`, `plank` e `fabric`; o tecido entra em `test_initial_stock_covers_30_days` e em `test_every_needed_good_has_a_producer`); **`test_economy_distribution.gd`** e **`test_initial_stock_covers_30_days.gd`** (LW-097e); **teto de compra** (`buy_cap_bp` de 10000 ou mais; `initial_stock` dentro do teto); a conferência entre módulos do verificador LW-093a (um caso negativo para `need_id`, `occupation_id`, `settlement_id`, `place_id`, `work_place_id` e `workers_wanted`); carregar duas vezes dá o mesmo resultado; `tools/validate_data` aceita a pasta `data/economy/` e roda dentro do `check_all`. **`contract_templates.json` (LW-107c1; `tests/unit/test_contract_templates_data.gd`):** o arquivo real (agora `[]`) carrega e o exemplo `contract_templates.initial.json` carrega com os 3 modelos iniciais; falham, cada um com o seu caso negativo e apontando arquivo, item e campo, `id` repetido, `kind` diferente de `delivery`, `good_id` desconhecido ou repetido, `trigger` fora do vocabulário, `reward_margin_bp` negativo ou fora da faixa do gatilho (`shortage` acima de 5000, `standing` acima de 1000), `quantity` 0 e lote mais pesado do que o jogador carrega, `deadline_hours` e `max_open` fora das faixas; o arquivo ausente dá lista vazia; **(LW-107c2b, PR empilhado sobre a 107c2a; `tests/unit/test_contract_poster_no_profit.gd`)** a propriedade da regra (b), com os dados reais, em todos os mercados e modelos.
