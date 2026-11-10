# Modelos de dados da economia (Fase 3)

Estado: **RASCUNHO da LW-087d (10/11/2026), fora do `main`, não aprovado.** Arthur autorizou adiantar este documento enquanto a Fase 2 não fecha; só entra no `main` quando ele escrever que a Fase 2 fechou e que pode entrar. **Nenhum arquivo de `data/`, nenhum esquema em código e nenhum teste foi criado:** isto descreve os modelos que as tarefas LW-089, LW-090 e LW-092 vão criar. Rótulos: **decisão**, **aprovado por Arthur em 10/11/2026** (o registro em `DECISIONS.md` é da LW-087a), **[PROPOSTA]**, **[HIP]** (número de trabalho, não é requisito) e **[LIM]**. Nomes de bens, receitas e ofícios são **genéricos e provisórios** (DEC-100, APROVADA). Os nomes de tabelas, de colunas e de ids são os do contrato `docs/modules/economy.md` (LW-087b, ramo `lw-087b-contrato-economy`), que este documento **não repete**: ele só acrescenta o nível de coluna.

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
- **Ponto aberto D1 (referências entre módulos).** Quatro colunas citam ids de **outro** módulo: `need_id` (de `needs`, do `npc`), `occupation_id` (de `occupations`, do `npc`), `settlement_id` e `place_id` (de `world/settlements` e `world/places`). A economia **não importa o `npc`** (decidido), então o carregador **não** consegue pedir `set_ref` para as tabelas do `npc`. **Recomendo:** essas colunas são `STRING` livres no esquema da economia e uma **conferência de dados entre módulos** (no `app`, ao montar o jogo, e num teste) confere que cada id existe; ela combina com o **verificador pequeno de ids de conteúdo**, que já é pré-requisito da LW-093. As colunas `settlement_id` e `place_id` poderiam ser `set_ref` se o `world` publicar o esquema das suas tabelas (camada menor; permitido), mas a mesma conferência cobre os dois casos.

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

Regras: `need_id` e `need_relief` vêm **juntos** ou nenhum; todo bem tem uma receita que o produz (conferência cruzada com `recipe_outputs`). **Quais bens saciam o quê** não está decidido (contrato, Q9; recomendação: `bread` alivia `hunger` por inteiro e `grain` menos [HIP]).

## `owner_kinds.json` (LW-089): tipos de dono

Cinco linhas: `npc`, `player`, `site`, `market`, `contract`.

| Coluna | Tipo | Regra |
|---|---|---|
| `id` | `STRING` | um dos cinco tipos |
| `weight_capacity` | `INT` | 0 ou mais; **0 = sem inventário** (só o `contract`, que é só conta) |
| `initial_balance` | `INT` | 0 ou mais; vira o `mint` inicial `game_start` ao abrir o dono (contrato, seção 3); [HIP] |

[LIM] Um saldo inicial único por tipo; saldo por ofício ou por pessoa não está decidido (contrato, Q3 e Q10).

## `market_targets.json` (LW-090): estoque por (assentamento, bem)

| Coluna | Tipo | Regra |
|---|---|---|
| `id` | `STRING` | por convenção `mt_<settlement_id>_<good_id>` (único) |
| `settlement_id` | `STRING` | id de `world/settlements` (D1) |
| `good_id` | `STRING` | referência a `goods` (`set_ref`) |
| `target_stock` | `INT` | 0 ou mais; **0 = bem não negociado nesse mercado**; dado **fixo** na Fase 3 (decidido; "dias de consumo" é calibração, LW-112) |
| `initial_stock` | `INT` | 0 ou mais |

Regras (no carregador): o par (`settlement_id`, `good_id`) é **único**; todo assentamento tem pelo menos um bem com `target_stock` maior que 0. Com 3 povoados e 10 bens são até 30 linhas; **quais bens cada povoado negocia** é distribuição de conteúdo (contrato, Q10) e não está decidida.

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
| `occupation_id` | `STRING` | ofício que trabalha nela (id de `occupations`, D1) |
| `work_minutes` | `INT` | 1 ou mais; minutos de trabalho, somados de quem trabalhar, para um lote |
| `wage_per_minute` | `INT` | 0 ou mais; pago pela conta do local ao trabalhador (contrato, seção 6); [HIP] |

**`recipe_inputs.json`** e **`recipe_outputs.json`:** mesmo formato, uma linha por (receita, bem).

| Coluna | Tipo | Regra |
|---|---|---|
| `id` | `STRING` | por convenção `<recipe_id>_in_<good_id>` e `<recipe_id>_out_<good_id>` (único) |
| `recipe_id` | `STRING` | referência a `recipes` (`set_ref`) |
| `good_id` | `STRING` | referência a `goods` (`set_ref`) |
| `quantity` | `INT` | 1 ou mais |

Regras (no carregador e num teste de dados): o par (`recipe_id`, `good_id`) é **único** em cada tabela; toda receita tem **pelo menos uma saída**; as quatro de **extração** não têm nenhuma linha de insumo; nenhum bem é insumo e saída da mesma receita. **[PROPOSTA]** Regra de **margem**: em cada receita, o valor dos produtos (soma de `quantity` × `base_value`) é **maior** que o dos insumos mais o salário do lote (`work_minutes` × `wage_per_minute`), senão o local não consegue pagar o salário com a venda e para por `NO_FUNDS`; é condição necessária, não suficiente (o spread e o soak da LW-110 e da LW-112 dão a prova).

**As 10 receitas** (ids em inglês; a coluna de ofício é **[PROPOSTA]**, contrato Q10: só `farmer` e `lumberjack` existem hoje e já cobrem as duas primeiras; `miner` e `shepherd` seriam ofícios novos em dados; o restante reaproveita `artisan` ou ganha ofício novo, a decidir):

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
| `id` | `STRING` | por convenção `site_<settlement_id>_<recipe_id>` (único) |
| `settlement_id` | `STRING` | id de `world/settlements` (D1) |
| `place_id` | `STRING` | um local de tipo `work` de `world/places`, **um local por sítio** (D1) |
| `recipe_id` | `STRING` | referência a `recipes` (`set_ref`) |

Cada linha vira um local de produção (`site_id` inteiro de `ctx.ids`) em `on_new_game`. **Quantos locais, em quais povoados e com quais receitas** é distribuição de conteúdo (contrato, Q10), a decidir; pede locais `work` que talvez ainda não existam em `places.json` e muda `population.json` e os hashes do `npc` (LW-097). Este rascunho **não** escreve nenhuma linha.

## O que mais vem dos mesmos arquivos de contrato

`world/routes.json` (LW-097) é dado e contrato do `world` (LW-087c). Parâmetros de contrato (prazos mínimos, teto de recompensa) e de comerciante (LW-096 e LW-098) **não** são modelados aqui: ganham tabela quando o contrato da respectiva tarefa for escrito (AGENTS 5.6, contrato primeiro). As marcas **TEMP** `data/food_stub.json` e `data/income_stub.json` saem nas LW-094 e LW-095.

## Testes previstos para estes dados (nas tarefas que criam cada tabela)

Arquivo real carrega e devolve os objetos tipados; **dado inválido falha** apontando arquivo, item e campo (campo ausente, tipo errado, campo desconhecido, id repetido, referência quebrada, faixa inválida, vocabulário fora do fechado, par repetido, `min_factor_bp` maior que `max_factor_bp`); a regra de margem e a de "um bem, uma receita"; carregar duas vezes dá o mesmo resultado; `tools/validate_data` aceita a pasta `data/economy/` e roda dentro do `check_all`.
