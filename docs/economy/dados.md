# Modelos de dados da economia (Fase 3)

Estado: **RASCUNHO da LW-087d (10/11/2026), fora do `main`, não aprovado.** Arthur autorizou adiantar este documento enquanto a Fase 2 não fechava; a Fase 2 fechou em 10/11/2026 (tag `fase-2-concluida`), mas só entra no `main` quando ele escrever que pode entrar. **Nenhum arquivo de `data/`, nenhum esquema em código e nenhum teste foi criado:** isto descreve os modelos que as tarefas LW-089, LW-090 e LW-092 vão criar. Rótulos: **decisão**, **aprovado por Arthur em 10/11/2026** (o registro em `DECISIONS.md` é da LW-087a), **decidido pelo revisor** (decisão de Claude na delegação de menores de Arthur, 10/11/2026: vale como [PROPOSTA]), **[PROPOSTA]**, **[HIP]** (número de trabalho, não é requisito) e **[LIM]**. Nomes de bens, receitas e ofícios são **genéricos e provisórios** (DEC-100, APROVADA). Os nomes de tabelas, de colunas e de ids são os do contrato `docs/modules/economy.md` (LW-087b, ramo `lw-087b-contrato-economy`), que este documento **não repete**: ele só acrescenta o nível de coluna.

## Onde fica este documento (o que o padrão do projeto manda)

- **Contrato do módulo** (`docs/modules/economy.md`, LW-087b): a **lista** dos arquivos de dados, a tarefa que cria cada um e o dono do dado, como o `npc.md` ("Arquivos de dados propostos", seção 11) e o `world.md` fazem. Fica lá porque o contrato é a fonte de verdade do módulo.
- **Este documento** (`docs/economy/dados.md`): as **colunas**, os tipos, as faixas e as regras de validação de cada tabela, mais a lista dos 10 bens e das 10 receitas. Fica numa pasta própria **e não dentro de `economy.md`** por duas razões: já há precedente de documento de dados por área (`docs/world/relevo-do-terreno-de-blockout.md`), e as duas tarefas, 087b e 087d, são ramos paralelos a partir do `main`, então escrever na mesma ficha geraria conflito de arquivo.
- **`data/economy/README.md`** (como o `data/world/README.md`): **não** é criado agora; nasce junto com os primeiros dados reais (LW-089), porque descreve arquivos que existem. A pasta `data/` é protegida e esta tarefa é só documento.
- **Textos ao jogador** nunca vão nas tabelas: cada tabela leva uma chave `name_key` e o texto vai para `data/text/pt_br.json` (arquitetura 16.4), na tarefa que cria o dado.
- **Esquemas** (`DataSchema`, `docs/modules/data.md`) são declarados **em código GDScript**, na tarefa que cria cada tabela; este documento é o que eles implementam.

## Regras comuns (do `data` e da arquitetura 16)

- JSON validado (DEC-082, aprovada só quanto ao JSON validado): **uma lista de objetos**, cada um com `id` (texto `snake_case`, único na tabela, estável, nunca reutilizado). Campos conhecidos: o `data` rejeita campo desconhecido, campo ausente e tipo errado, apontando arquivo, item e campo.
- **Tabelas planas.** O `data` só aceita `STRING`, `INT`, `FLOAT`, `BOOL` e lista de inteiros (`INT_LIST`); **não aceita objetos nem listas aninhadas** (decidido: tabelas planas, como no `npc` e no `world`). Por isso insumos e produtos de uma receita são **tabelas à parte**, uma linha por (receita, bem).
- **Dinheiro e quantidades são `INT`**; proporções em **pontos-base** (`_bp`, 10000 = 1,0), também `INT`. Nenhum `FLOAT` nestas tabelas (AGENTS 4.11).
- Referência entre tabelas (`set_ref`) só funciona **dentro da mesma leitura**: o carregador da economia lê as tabelas abaixo **juntas** (como o `npc` faz com as suas seis). Vocabulário fechado (por exemplo, `category`) e regras de mais de um campo ou de mais de uma linha (par único, mínimo menor que máximo) são conferidos **no carregador**, com `ECON_DATA_INVALID` e mensagem de arquivo, item e campo (padrão de `SETTLEMENT_DATA_INVALID`).
- Pasta: **`data/economy/`** [PROPOSTA], como `data/world/` (`data/` hoje tem os arquivos do `npc` soltos, e o `npc.md` já prevê subpasta como alternativa).
- **D1 (referências entre módulos): decidido pelo revisor, vale como [PROPOSTA].** Quatro colunas citam ids de **outro** módulo: `need_id` (de `needs`) e `occupation_id` (de `occupations`), tabelas do `npc`; `settlement_id` e `place_id` (de `world/settlements` e `world/places`); e, em `population.json`, o `work_place_id` que entra com a LW-097. A economia **não importa o `npc`** (decidido por Arthur), então o carregador **não** pede `set_ref` para as tabelas dos outros módulos: essas colunas são **`STRING` livres** no esquema da economia e uma **conferência de dados entre módulos** confere que cada id existe na tabela do dono. A conferência mora no **verificador LW-093a** (o verificador de ids de conteúdo, pré-requisito da LW-093, decidido por Arthur): o escopo dele **cresce** de cerca de **60** para cerca de **150 a 200 linhas de código e teste** (um arquivo de verificação e um de teste, com caso positivo e negativo para cada coluna), dentro do teto da DEC-126, e precisa vir **depois da LW-092** (quando as tabelas da economia existem) e antes da LW-093.

## Os 10 bens e as 4 cadeias (decisão de Arthur, 10/11/2026; escala [HIP])

| id | Nome (`good.<id>.name`) | Categoria | Produzido por (receita) | Insumo de |
|---|---|---|---|---|
| `grain` | grão | `food` | `grow_grain` | `mill_flour` |
| `flour` | farinha | `processed` | `mill_flour` | `bake_bread` |
| `bread` | pão | `food` | `bake_bread` | consumo |
| `wood` | madeira | `raw_material` | `cut_wood` | `saw_plank`, `smelt_metal` (combustível) |
| `plank` | tábua | `processed` | `saw_plank` | consumo e venda |
| `ore` | minério | `raw_material` | `mine_ore` | `smelt_metal` |
| `metal` | metal | `processed` | `smelt_metal` | `forge_tool` |
| `tool` | ferramenta | `tool` | `forge_tool` | consumo e venda |
| `wool` | lã | `raw_material` | `shear_wool` | `weave_fabric` |
| `fabric` | tecido | `processed` | `weave_fabric` | consumo e venda |

**Cadeias:** (1) `grain` → `flour` → `bread`; (2) `wood` → `plank`; (3) `ore` + `wood` → `metal` → `tool`; (4) `wool` → `fabric`. A madeira também é o combustível da cadeia 3. Armas (demanda militar) e roupas **não** entram (decidido). Cada bem tem **exatamente uma** receita que o produz, e as quatro de **extração** (`grow_grain`, `cut_wood`, `mine_ore`, `shear_wool`) não têm insumo.

## `goods.json` (LW-089): `GoodDef`

| Coluna | Tipo | Regra |
|---|---|---|
| `id` | `STRING` | um dos 10 ids acima |
| `name_key` | `STRING` | `good.<id>.name`; o texto em `data/text/pt_br.json` |
| `category` | `STRING` | vocabulário fechado no carregador: `food`, `raw_material`, `processed`, `tool`; `weapon`, `luxury` e `magic` são **aceitos e reservados**, sem uso (GDD 12.3) |
| `base_value` | `INT` | 1 ou mais (menor unidade de moeda); valor [HIP] em dados, calibrado na LW-112 |
| `weight` | `INT` | 1 ou mais (unidade de peso [HIP]) |
| `perishability_days` | `INT` | 0 ou mais; **0 = não perece** e **sem comportamento na Fase 3** (contrato, Q11) |
| `need_id` | `STRING` (opcional) | só em bem de consumo; id de `needs` (D1); vazio nos demais |
| `need_relief` | `INT` (opcional) | só com `need_id`; 1 ou mais (quanto 1 unidade alivia, na escala de pressão 0 a 100 do `npc`); contrato, Q9 |

Regras: `need_id` e `need_relief` vêm **juntos** ou nenhum; todo bem tem uma receita que o produz (conferência cruzada com `recipe_outputs`). **Quais bens saciam o quê** (contrato, Q9, decidido pelo revisor): `bread` alivia `hunger` por inteiro e `grain` menos [HIP]; só esses dois levam `need_id` e `need_relief` na Fase 3 (Q20 do `npc.md`), os outros oito não.

## `owner_kinds.json` (LW-089): tipos de dono

Cinco linhas: `npc`, `player`, `site`, `market`, `contract`.

| Coluna | Tipo | Regra |
|---|---|---|
| `id` | `STRING` | um dos cinco tipos |
| `weight_capacity` | `INT` | 0 ou mais; **0 = sem inventário** (só o `contract`, que é só conta) |
| `initial_balance` | `INT` | 0 ou mais; vira o `mint` inicial `game_start` ao abrir o dono (contrato, seção 3); [HIP] |

[LIM] Um saldo inicial único por tipo; saldo por ofício ou por pessoa não está decidido (contrato, Q3 e Q15).

## `market_targets.json` (LW-090): estoque por (assentamento, bem)

| Coluna | Tipo | Regra |
|---|---|---|
| `id` | `STRING` | por convenção `mt_<settlement_id>_<good_id>` (único) |
| `settlement_id` | `STRING` | id de `world/settlements` (D1) |
| `good_id` | `STRING` | referência a `goods` (`set_ref`) |
| `target_stock` | `INT` | 0 ou mais; **0 = bem não negociado nesse mercado**; dado **fixo** na Fase 3 (decidido; "dias de consumo" é calibração, LW-112) |
| `initial_stock` | `INT` | 0 ou mais |

Regras (no carregador): o par (`settlement_id`, `good_id`) é **único**; todo assentamento tem pelo menos um bem com `target_stock` maior que 0. Com 3 povoados e 10 bens são **30 linhas**: cada mercado negocia os **10 bens** (`target_stock` maior que 0), para a importação poder ser comprada [PROPOSTA]; **quem produz o quê** está em `production_sites` (abaixo).

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

Faixas e regras (no carregador): colunas `_bp` de 0 a 100000; **`min_factor_bp` de 1 ou mais e menor que ou igual a `max_factor_bp`**; `spread_bp` menor que 20000 (se o spread é repartido meio a meio em torno do preço, como o contrato propõe na seção 4, o bid continua positivo); `max_order_quantity` e `history_days` de 1 ou mais; `shortage_days` de 1 a 59.

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

Regras (no carregador e num teste de dados): o par (`recipe_id`, `good_id`) é **único** em cada tabela; toda receita tem **pelo menos uma saída**; as quatro de **extração** não têm nenhuma linha de insumo; nenhum bem é insumo e saída da mesma receita. **[PROPOSTA]** Regra de **margem**: em cada receita, o valor dos produtos (soma de `quantity` × `base_value`) é **maior** que o dos insumos mais o salário do lote (`workers_per_batch` × `wage_per_hour`), senão o local não consegue pagar o salário com a venda e para por `NO_FUNDS`; é condição necessária, não suficiente (o spread e o soak da LW-110 e da LW-112 dão a prova).

**As 10 receitas** (ids em inglês). Os ofícios **`miner` e `shepherd` foram decididos por Arthur** (só em dados); a coluna de ofício das demais é **[PROPOSTA]**: `farmer` e `lumberjack` já existem e o resto reaproveita `artisan`:

| id | Nome (`recipe.<id>.name`) | Tipo | Insumos | Produtos | Ofício [PROPOSTA] |
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

**As quantidades** de cada linha (quanto de insumo por quanto de produto) são **[HIP] a propor na LW-092** e calibrar na LW-112; este rascunho **não as inventa**.

## `production_sites.json` (LW-092): os locais de produção

| Coluna | Tipo | Regra |
|---|---|---|
| `id` | `STRING` | por convenção `site_<a, b ou c>_<recipe_id>` (único) |
| `settlement_id` | `STRING` | id de `world/settlements` (D1) |
| `place_id` | `STRING` | um local de tipo `work` de `world/places` do mesmo povoado, **um por local de produção** (D1) |
| `recipe_id` | `STRING` | referência a `recipes` (`set_ref`) |

Cada linha vira um local de produção (`site_id` inteiro de `ctx.ids`) em `on_new_game`, dono do tipo `site` (conta e inventário próprios, contrato Q4).

**Distribuição das 4 cadeias pelos 3 povoados.** Arthur decidiu o princípio (**nenhum povoado se baste sozinho**) e a criação dos ofícios `miner` e `shepherd`; **a tabela é [PROPOSTA/HIP]**, com nomes genéricos (DEC-100), para ele aprovar na LW-087a. São **12 locais de produção**, e o `place_id` de cada um é escolhido na LW-092 e na LW-097:

| id (convenção) | Povoado | Receita | Ofício esperado |
|---|---|---|---|
| `site_a_grow_grain` | A (`test_settlement_a`) | `grow_grain` | `farmer` |
| `site_a_mill_flour` | A | `mill_flour` | `artisan` |
| `site_a_cut_wood` | A | `cut_wood` | `lumberjack` |
| `site_a_saw_plank` | A | `saw_plank` | `artisan` |
| `site_b_grow_grain` | B (`test_settlement_b`) | `grow_grain` | `farmer` |
| `site_b_cut_wood` | B | `cut_wood` | `lumberjack` |
| `site_b_bake_bread` | B | `bake_bread` | `artisan` |
| `site_b_shear_wool` | B | `shear_wool` | `shepherd` |
| `site_b_weave_fabric` | B | `weave_fabric` | `artisan` |
| `site_c_mine_ore` | C (3º povoado, `test_settlement_c`, LW-097) | `mine_ore` | `miner` |
| `site_c_smelt_metal` | C | `smelt_metal` | `artisan` |
| `site_c_forge_tool` | C | `forge_tool` | `artisan` |

**Quem depende de quem:** A não faz `bread` nem `fabric` (do B) nem `metal` e `tool` (do C); B não faz `flour` nem `plank` (do A) nem `metal` e `tool` (do C); C não faz `wood` (do A ou do B), comida (`grain` do A ou do B, `bread` do B), `plank` nem `fabric`.

**Regras (no carregador e num teste de dados) [PROPOSTA]:** `place_id` único; o local é de tipo `work` e do mesmo povoado (conferência entre módulos, D1); **para cada povoado existe pelo menos um bem de consumo ou insumo que só outros povoados produzem**; todo bem tem pelo menos um local que o produza e toda receita é usada por pelo menos um local.

**Locais `work` e população (dados de outros módulos, que a LW-097 muda).** Hoje A e B têm 5 locais `work` cada (capacidade 12 e 8) e a população os preenche **por vaga, sem ligar ofício a local**; a distribuição pede 12 locais de produção, cada um com um local `work` próprio e capacidade para a equipe. A **LW-097 acrescenta** os locais `work` que faltam e o terceiro povoado, e as linhas de `population.json` passam a trazer o **`work_place_id`** (coluna nova, decisão de Arthur de a população nascer empregada por dados; o carregador do `npc` passa a aceitar a coluna, mudança pequena de código) [PROPOSTA]. A população do 3º povoado e os **hashes novos** (o oráculo e o soak de 30 dias; o `run_sim` não muda, porque não registra módulos) são da LW-097, **com a aprovação de Arthur dos valores novos**. Guardas e estalajadeiros não têm local de produção (contrato, Q15) e o povoado C não produz comida (contrato, Q17).

## Ofícios novos (dado do `npc`)

`occupations.json` ganha **`miner`** (mineiro) e **`shepherd`** (pastor), cada um com `work_place_kind` `work`, **só em dados** (decisão de Arthur). Entram com a LW-092 ou a LW-097. Os nomes são genéricos e provisórios (DEC-100).

## O que mais vem dos mesmos arquivos de contrato

`world/routes.json` (LW-097) é dado e contrato do `world` (LW-087c). Parâmetros de contrato (prazos mínimos, teto de recompensa) e de comerciante (LW-096 e LW-098) **não** são modelados aqui: ganham tabela quando o contrato da respectiva tarefa for escrito (AGENTS 5.6, contrato primeiro). As marcas **TEMP** `data/food_stub.json` e `data/income_stub.json` saem nas LW-094 e LW-095.

## Testes previstos para estes dados (nas tarefas que criam cada tabela)

Arquivo real carrega e devolve os objetos tipados; **dado inválido falha** apontando arquivo, item e campo (campo ausente, tipo errado, campo desconhecido, id repetido, referência quebrada, faixa inválida, vocabulário fora do fechado, par repetido, `min_factor_bp` maior que `max_factor_bp`); a regra de margem e a de "um bem, uma receita"; **nenhum povoado se basta** e o local único por `place_id`; a conferência entre módulos do verificador LW-093a (um caso negativo para `need_id`, `occupation_id`, `settlement_id`, `place_id` e `work_place_id`); carregar duas vezes dá o mesmo resultado; `tools/validate_data` aceita a pasta `data/economy/` e roda dentro do `check_all`.
