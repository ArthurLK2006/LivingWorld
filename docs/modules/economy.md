# Contrato — economy

Estado: **RASCUNHO da LW-087b (10/11/2026), fora do `main`, não aprovado.** Arthur autorizou adiantar este documento enquanto a Fase 2 não fecha; ele só entra no `main` quando Arthur escrever que a Fase 2 fechou e que pode entrar. A Fase 3 não começou e nenhum código, dado ou teste dela existe: tudo abaixo é desenho. Fontes: arquitetura cap. 11 (mais 3.2, 6.4, 8.6, 15.4, 16, 17 e 18), GDD cap. 12 e 13, roadmap Fase 3 (3.A a 3.J, LW-087 a LW-116) e Anexo D. Rótulos: **decisão** (`DECISIONS.md`, APROVADA), **aprovado por Arthur em 10/11/2026** (aprovação dada em mensagem; o registro em `DECISIONS.md` é da LW-087a, e este arquivo não o edita), **[PROPOSTA]** (desenho deste rascunho, ainda não aprovado), **[HIP]** (número de trabalho, não é requisito: vai para `data/` ou constante nomeada), **[PENDENTE]**, **[LIM]** (limitação) e **[FUT]**. `[Qn]` remete aos pontos abertos da seção 15. Nomes de bens, ofícios e lugares são **provisórios e genéricos** (DEC-100, APROVADA); identificadores em inglês e texto ao jogador em português por chave (DEC-022).

**Decisões de Arthur incorporadas (10/11/2026).** (1) **DEC-047** (dinheiro e quantidades inteiros, com `Ledger`), **DEC-049** (`TradeRules` como única inversão de dependência, **só a versão neutra** na Fase 3) e **DEC-054** (uma só moeda) estão aprovadas. (2) **Escala [HIP]:** 3 povoados, 10 bens (`grain`, `flour`, `bread`, `wood`, `plank`, `ore`, `metal`, `tool`, `wool`, `fabric`) e 4 cadeias: grão → farinha → pão; madeira → tábua; minério + madeira → metal → ferramenta; lã → tecido (a madeira também é o combustível). (3) As seis recomendações da seção c do pré-voo valem: **(1)** a `economy` guarda as **quantidades** de bens de todo dono, por ID, e o equipamento em instâncias é do `character` (Fase 5); **(2)** o `TradeFlow` é abstração econômica por rota, sem depender de LOD S2; **(3)** o `npc` importa só `economy/api` e a economia **nunca** importa o `npc` (contrato de trabalho chega por evento); **(4)** o `mint` inicial entra na LW-093 (ou a LW-095 vem antes da LW-094); **(5)** o save **não** é congelado: a LW-111 rejeita save antigo com mensagem clara; **(6)** o `check_temp` vale só em `src/`, `data/`, `tests/`, `tools/` e `scenes/`, fora de `docs/`. Os menores **7 a 11** estão decididos: (7) na seção 5, (8) na 4, (9) na 9, (10) nas dependências abaixo e (11) na 5; o resumo está na seção 15. (4) Os arquivos grandes do `npc` **não serão divididos**; só o **verificador pequeno de ids de conteúdo** vem antes da LW-093, em tarefa à parte: é **pré-requisito da LW-093** (seção 7).

**Escala do protótipo:** 3 povoados (hoje existem 2; o terceiro nasce na LW-097), 10 bens, 4 cadeias, **uma moeda**, cerca de 100 a 300 NPCs individuais (DEC-040, PENDENTE: o número é [HIP] e a economia não depende dele). Sem T0 nem LOD S2/S3 (DEC-041, APROVADA). DEC-048 (comércio em duas escalas) segue PROPOSTA até o SP7 (LW-101).

- **Responsabilidade:** produção, estoque, preço, comércio, consumo, dinheiro e contratos, com efeitos observáveis (DEC-046, APROVADA). É o **dono único** de três coisas: **(a) as quantidades de bens** de todo dono (NPC, jogador, local de produção e mercado), por ID; **(b) o preço** de cada bem em cada mercado; **(c) o dinheiro** (contas e `Ledger`). **Não** faz política (tarifas e impostos reais ficam na Fase 4), facção, combate, equipamento em instâncias, propriedade complexa, mercado negro, múltiplas moedas, bancos, crédito, leilões, reputação, famílias e herança (roadmap 3.J, "Não fazer").
- **Entradas:** o passo do relógio (`tick`, na cadência da seção 1); dados de `data/economy/` (seção 13); comandos `request_*` (seção 10) vindos do `npc` (só por `economy/api`), da ponte (jogador) e de ferramentas de desenvolvimento; os eventos `NpcDied` e `RouteStateChanged` (e, só se a LW-102 existir, `LodChanged`); a implementação de `TradeRules` (a neutra, na Fase 3).
- **Saídas:** consultas `peek_*` (cópias); eventos de mercado, produção e contrato (seção 11 e `docs/events.md`); resultados de transação (`Result`); pedidos de trabalho ao `npc` **só por evento** (`ContractOffered`).
- **Dependências permitidas:** `core`, `data` e `world` (camadas 0 a 2: assentamentos, locais e, desde a LW-097, rotas). **Não importa** `npc`, `character`, `politics`, `factions`, `military` nem `combat` (a arquitetura 11.10 diz que usa `npc` e `factions` "somente por IDs e eventos"). O módulo `entities` (arquitetura 11.10) **não existe** e nenhuma tarefa da Fase 3 o cria: os IDs vêm de `ctx.ids`, como no `npc` e no `character` (menor 10, decidido). Quem importa a `economy` é o `npc` (**só** `economy/api`, mão única, mesma camada 3), a ponte e o `app`; a única inversão do projeto é a `TradeRules` (DEC-049). Camada 3 do AGENTS 5.1.
- **Dados controlados:** tabela da seção 12.
- **Interfaces de comunicação:** seção 10 (`peek_*`, `request_*`, `on_*`) e seção 11 (eventos).
- **Testes necessários:** um conjunto por tarefa, nomeado na seção 14, mais as regras gerais: **teste de ouro** do dinheiro (soma das contas = criado − destruído) em todo teste que mexa em dinheiro; mesma semente, mesmo hash (DEC-081); ida e volta de save pelo codec JSON; dado inválido falha apontando arquivo, item e campo; operação que falha não muda nada; sem janela (`--headless`).

## 1. Princípios, ciclo de vida, cadência e save

- **Dono único.** Nenhum outro módulo guarda saldo, quantidade de bem nem preço: o `NpcState` não ganha campo de dinheiro ou de bem, e o `character` não guarda quantidades (decidido, 3.1). Os outros leem por `peek_*` e pedem por `request_*`.
- **Inteiros.** Dinheiro na **menor unidade** e quantidades de bens, sempre `int` (AGENTS 4.11; DEC-047). Proporções em **pontos-base** (10000 = 1,0). Divisão inteira com arredondamento declarado em cada fórmula (para baixo, salvo onde se diz o contrário) e preço mínimo de 1. Nunca `float` em dinheiro ou quantidade.
- **IDs.** Donos e entidades da economia (mercado, local de produção, contrato) têm ID inteiro de `ctx.ids`, nunca reutilizado (AGENTS 4.12); bens, receitas e tipos de dono têm id de texto `snake_case` de `data/`. Entre módulos passa-se o **ID**. Como todo ID vem do mesmo gerador, a conta de um dono é indexada pelo próprio ID, sem colisão entre NPC, jogador, mercado, local e contrato.
- **Determinismo.** Regra do `MODELO.md`: donos, mercados, bens, locais e contratos são visitados **por ID ou chave em ordem crescente**, nunca pela ordem de um `Dictionary`; saves guardam coleções em lista ou com chave ordenada; o módulo copia `tests/unit/test_dictionary_order_after_load.gd`. A Fase 3 **não sorteia nada** (preço, produção e fluxo são regras); se um dia sortear, só por `ctx.rng` em fluxo nomeado.
- **Ciclo de vida** (`SimModule`, `core.md`): `setup(ctx)`, `post_setup()` (assina `NpcDied` e, quando existirem, `RouteStateChanged`), `on_new_game(world_seed)` (cria os mercados, os locais de produção e os donos do tipo `market` e `site`, com o `mint` inicial deles), `tick(elapsed_minutes)`, `serialize`, `on_load` (valida e rejeita com `Result`), `validate`, `debug_summary` e `teardown`. As definições entram **pelo construtor**, já lidas e validadas, sem global nem autoload (a economia não é autoload, arquitetura 4.3). A `economy` é registrada **antes** do `npc` na ordem do `World` (o `npc` abre contas ao criar NPCs, [Q1]).
- **Cadência [HIP, arquitetura 6.4].** Produção e venda dos locais a cada **hora** de simulação (60 minutos); preços, escassez e histórico ao **fim do dia**; caravanas (LW-098) avançam a cada passo. O `Scheduler` configura o módulo com custo declarado. Compra, venda e consumo **não esperam o tick**: valem na hora, dentro do passo de quem chama (comando do jogador entra no início do passo seguinte, arquitetura 17.6).
- **Save.** Bloco `economy` do `serialize()`: contas, totais do `Ledger` por motivo, quantidades por dono, mercados (estoque, preço, histórico, escassez), locais de produção, contratos e o mapa de IDs. Definições **não** entram. **`save_version` fica em 2 e o save não é congelado** (decidido, 3.5; `docs/decisions/0011-revisao-fase-2.md`, item 2): não há migração; save sem o bloco `economy` é rejeitado por `World.on_load` (`WORLD_MODULE_DATA_MISSING`, como já é hoje para os outros módulos) com mensagem clara, e a LW-111 prova a **rejeição**, em vez de "migra e carrega". Quem mudar o estado salvo atualiza o teste de ida e volta (AGENTS 4.15).
- **Falha visível.** Todo comando devolve `Result`; ID inexistente nunca derruba o jogo (AGENTS 13.1): erro tratado com código `ECON_*` e mensagem que diz o que falhou, onde e o que se esperava; a interface traduz o código em texto (arquitetura 17.6).

## 2. `Ledger` (LW-088) — o dinheiro

- **Contas.** Uma por dono, indexada pelo `owner_id`, com saldo inteiro **nunca negativo** (sem crédito, 3.J). A conta nasce em `request_open_owner` (seção 3).
- **Operações — a única forma de mexer em saldo:** `transfer(from_id, to_id, amount, reason)`, `mint(to_id, amount, reason)` (fonte, cria dinheiro) e `burn(from_id, amount, reason)` (sumidouro, destrói). `amount` é 1 ou mais. Falha devolve `Result` e **não muda nada**: `ECON_UNKNOWN_OWNER`, `ECON_OWNER_CLOSED`, `ECON_BAD_AMOUNT`, `ECON_INSUFFICIENT_FUNDS`.
- **Motivos (`reason`):** texto `snake_case` de um conjunto **fechado**, constantes nomeadas do módulo: `game_start` (mint inicial), `trade`, `salary`, `contract_escrow`, `contract_payout`, `contract_refund`. O roadmap escreve `inicio_de_jogo`; uso `game_start` pela DEC-022 (identificadores em inglês) [Q3]. **Nenhum `burn` é chamado no jogo da Fase 3** (o dinheiro só circula): `burn` existe e é testado, e os sumidouros do GDD 12.3 (desgaste, serviços, tributos) ficam para a Fase 4 em diante [LIM].
- **Histórico.** Em **modo de teste**, lista completa de lançamentos; no jogo, **só totais por motivo** (movimentado, criado e destruído), e é isso que vai ao save.
- **Teste de ouro (arquitetura 11.4):** a qualquer momento, **soma de todas as contas = criado − destruído** (o dinheiro inicial é um `mint` com motivo `game_start`). `peek_conservation()` devolve a soma, o criado, o destruído e `ok`; `validate()` o confere; o soak confere **a cada dia simulado** (LW-109).
- **Regra de arquitetura (LW-088):** o `tools/check_architecture` ganha uma regra que reprova qualquer alteração de saldo fora de `economy/ledger/`.

## 3. Bens e inventário por dono (LW-089)

- **`GoodDef`** (de `data/economy/goods.json`, só leitura): `id`, `category`, `base_value` (inteiro, na menor unidade de moeda), `weight` (inteiro, unidade de peso [HIP]), `perishability_days` (0 = não perece; **sem comportamento na Fase 3**, [Q11]) e, para bem de consumo, `need_id` e `need_relief` (quanto da necessidade 1 unidade alivia, [Q9]). Categorias da Fase 3: `food`, `raw_material`, `processed`, `tool`; `weapon`, `luxury` e `magic` ficam **reservadas** sem uso (GDD 12.3). Valores de `base_value` e `weight` são [HIP] e ficam em dados (calibração na LW-112); o contrato só exige que, em toda receita, o valor dos produtos seja **maior** que o dos insumos (senão a cadeia não dá margem; teste de dados).
- **Os 10 bens (genéricos):**

| id | Nome | Categoria | Vem de | Entra em |
|---|---|---|---|---|
| `grain` | grão | `food` | extração (fazenda) | `flour` |
| `flour` | farinha | `processed` | `grain` | `bread` |
| `bread` | pão | `food` | `flour` | consumo |
| `wood` | madeira | `raw_material` | extração (floresta) | `plank`, `metal` (combustível) |
| `plank` | tábua | `processed` | `wood` | consumo e venda |
| `ore` | minério | `raw_material` | extração (mina) | `metal` |
| `metal` | metal | `processed` | `ore` + `wood` | `tool` |
| `tool` | ferramenta | `tool` | `metal` | consumo e venda |
| `wool` | lã | `raw_material` | extração (pasto) | `fabric` |
| `fabric` | tecido | `processed` | `wool` | consumo e venda |

- **Donos e tipos.** Todo dono tem um **tipo** (`owner_kinds.json`): `npc`, `player`, `site` (local de produção), `market` e `contract` (só conta, sem inventário). O tipo fixa a **capacidade de peso** e o saldo inicial. `request_open_owner(owner_id, kind)` é **idempotente**; abre a conta e o inventário e, se o tipo tem saldo inicial, faz o `mint` `game_start` (decidido, 3.4: o `mint` inicial dos NPCs entra na LW-093). Mercados e locais de produção são abertos pela própria economia em `on_new_game`; NPCs, pelo `npc` ao criá-los; o jogador, pela ponte (LW-105) [Q1].
- **Inventário** por dono: quantidade inteira por `good_id`; peso total = soma de quantidade × `weight`, **no máximo** a capacidade do tipo. Consulta devolve cópia, por `good_id` crescente.
- **Operações.** O jogo só **move** bens (`request_transfer_goods`, seção 10) ou os **cria e destrói** em dois pontos únicos do `GoodsStore`, com motivo, como `mint` e `burn`: criar (`produced`, `game_start`) e destruir (`consumed`, `spoiled` [reservado]). **Conservação de bens [PROPOSTA, Q13]:** para cada bem, soma de todos os donos = criado − destruído; `peek_goods_conservation()` o confere e o soak (LW-109) o verifica por dia. Falhas, sem mudar nada: `ECON_UNKNOWN_GOOD`, `ECON_BAD_QUANTITY`, `ECON_INSUFFICIENT_GOODS`, `ECON_CAPACITY_EXCEEDED`, `ECON_UNKNOWN_OWNER`, `ECON_OWNER_CLOSED`.
- **Dono morto [PROPOSTA, Q2].** Ao ouvir `NpcDied`, a economia **fecha** a conta e o inventário desse NPC: nenhuma operação é aceita, mas o saldo e os bens **continuam na soma** da conservação. Herança é "não fazer" (3.J).
- **Equipamento em instâncias** (espada com qualidade e durabilidade) **não** existe na Fase 3 e não é da economia: é do `character`, na Fase 5 (decidido, 3.1; arquitetura 15.4).

## 4. Mercados e preço (LW-090)

- **`MarketState`:** um por assentamento (`settlement_id` do `world`), com `market_id` inteiro de `ctx.ids` criado em `on_new_game` (o mapa assentamento → mercado é salvo) e dono do tipo `market` (tem conta e inventário). O local físico é o local `market_reserved` do povoado (`a_market_01` e `b_market_01` hoje); **a economia não confere presença**: quem chama (a ação do NPC naquele local, a interação do jogador pela ponte) garante que o ator está lá.
- **Estado por (mercado, bem):** estoque, **estoque-alvo** (**dado fixo por bem e mercado na Fase 3**, decidido, menor 8; "dias de consumo" da arquitetura 11.5 vira calibração na LW-112), preço atual, histórico curto (últimos `history_days` preços diários), dias seguidos abaixo do limiar de escassez e a marca de escassez declarada.
- **Preço [PROPOSTA, Q6].** Ao **fim de cada dia**, por bem: `factor_bp = clamp(10000 × alvo / max(estoque, 1), min_factor_bp, max_factor_bp)`; `preço_alvo = max(1, base_value × factor_bp / 10000)`; o preço atual **anda uma fração** em direção ao `preço_alvo` (`smoothing_bp`, anda ao menos 1 se houver diferença, nunca passa do alvo). Faixa **[HIP, GDD 12.3]:** de 0,5 a 3 vezes o valor-base (`min_factor_bp` = 5000 e `max_factor_bp` = 30000). Estoque baixo sobe o preço, estoque alto o desce; a **curva exata é calibração** (LW-112): o que vale como contrato são as propriedades testadas (dentro da faixa, monotônico, sem salto maior que a suavização).
- **Spread [PROPOSTA, Q7]:** o mercado **vende** (ask) por `preço` arredondado para cima e **compra** (bid) por `preço` arredondado para baixo, com diferença total `spread_bp` (em dados); invariante: `bid < ask` e comprar e vender a mesma quantidade no mesmo instante dá **prejuízo** ao operador.
- **Profundidade [PROPOSTA, Q7].** O custo de uma ordem de `q` unidades é a **soma unidade a unidade**, com o preço de cada unidade acompanhando o estoque que sobra depois das anteriores (a ordem "anda pela curva"), com `q` no máximo `max_order_quantity` [HIP]. Assim, ordem grande custa mais por unidade que ordem pequena e move o preço contra quem opera (GDD 12.3).
- **Escassez [HIP].** Bem com estoque abaixo de `shortage_threshold_bp` do alvo por `shortage_days` dias seguidos declara `ShortageDeclared` (uma vez); acima do limiar de novo, `ShortageEnded`. Exigência de teste (3.F, item 3): **mercado sem produtor por 60 dias declara escassez**, então `shortage_days` fica folgadamente abaixo de 60 e os estoques e o consumo iniciais são calibrados para isso.
- **Eventos.** `PriceChanged` **só** quando a variação em relação ao último preço publicado passa de `significant_change_bp` (nunca por centavo, arquitetura 17.4); `ShortageDeclared` e `ShortageEnded`. Nenhum evento por transação.
- **Constantes** (todas em dados, nenhuma no código; arquitetura 11.5): ver `price_params` e `market_targets` na seção 13.

## 5. Comércio e `TradeRules` (LW-091)

- **`request_trade(actor_id, market_id, good_id, quantity, side)`**, com `side` = `buy` (o ator compra do mercado) ou `sell` (o ator vende ao mercado). **Atômico:** valida tudo antes de mudar qualquer coisa (donos abertos; bem existe; `quantity` de 1 a `max_order_quantity`; `TradeRules`; custo calculado pela profundidade; fundos de quem paga; estoque do mercado na compra ou fundos do mercado na venda; capacidade do inventário de quem recebe) e só então aplica o `Ledger.transfer` (motivo `trade`) e a movimentação de bens. Se qualquer verificação falha, **nada muda** (teste: o estado antes e depois é igual). Devolve `TradeResult` (`result`, `quantity`, `total_cost`, `tariff`, sempre 0 na Fase 3).
- **Erros:** `ECON_UNKNOWN_MARKET`, `ECON_UNKNOWN_OWNER`, `ECON_OWNER_CLOSED`, `ECON_UNKNOWN_GOOD`, `ECON_BAD_QUANTITY`, `ECON_INSUFFICIENT_FUNDS`, `ECON_INSUFFICIENT_STOCK`, `ECON_MARKET_NO_FUNDS` ([Q5]), `ECON_CAPACITY_EXCEEDED`, `ECON_TRADE_BANNED`.
- **Consulta sem executar:** `peek_quote(market_id, good_id, quantity, side)` devolve o custo e o preço médio da mesma conta, para a interface (LW-106) e para o `npc` decidir antes de pedir.
- **`TradeRules` (`economy/rules/`, DEC-049):** a economia **define** a interface e usa uma implementação **neutra** (`NeutralTradeRules`: nada proibido, tarifa 0, sem licença). Pergunta: `peek_terms(good_id, market_id, actor_id)` devolve `banned`, `tariff_bp` e `needs_license`. A regra é **entregue pronta ao construtor** da economia; na Fase 4 o módulo `politics` fornece a sua. A divergência de texto entre a arquitetura 3.2 ("entregue pelo `app`") e a 11.8 ("a `SimContext` entrega") não tem efeito na Fase 3 (neutra) e fica para alinhar na Fase 4 (menor 11, decidido). **Tributos e tarifas reais ficam na Fase 4** (menor 7, decidido: o GDD 12.5 [P1] cita "tributos"; valem o roadmap 3.J e a DEC-049, "só a versão neutra"); para onde vai a tarifa é decisão da Fase 4 [FUT], por tarefa de contrato.
- Teste exigido: regra trocada em teste altera a tarifa **sem tocar** na economia; transação atômica; conservação de dinheiro e de bens mantida.

## 6. Produção e salário (LW-092, LW-095)

- **`RecipeDef`** (tabelas planas, seção 13): `id`, `occupation_id` (o ofício que trabalha nela), `work_minutes` (minutos de trabalho, somados de quem trabalhar, por lote) e `wage_per_minute` [HIP]; **insumos e produtos** em duas tabelas à parte (`recipe_inputs`, `recipe_outputs`: uma linha por bem e quantidade), porque o `data` não aceita listas aninhadas (decidido: tabelas planas, como no `npc` e no `world`). **As 10 receitas:** 4 de **extração**, sem insumo (`grow_grain`, `cut_wood`, `mine_ore`, `shear_wool`) e 6 de transformação (`mill_flour`, `bake_bread`, `saw_plank`, `smelt_metal` com `ore` + `wood`, `forge_tool`, `weave_fabric`). Extração **sem esgotamento** na Fase 3 [LIM]: nós de recurso finitos são [PREV] (GDD 13.3).
- **`ProductionSite`:** `site_id` (inteiro), `settlement_id`, `place_id` (um local `work` do `world`), `recipe_id`, dono do tipo `site` (**conta e inventário próprios**: insumos e produtos, [Q4]), `efficiency_bp` (fixo em 10000 na Fase 3; depender de habilidade e estação é [FUT]), minutos de trabalho acumulados e o **estado**: `running` ou `stopped` com o **motivo**.
- **Trabalho vem do `npc`.** Quando uma ação `work` do NPC progride ou termina no local do sítio, o `npc` chama `request_work_shift(place_id, worker_id, minutes)`: a economia soma os minutos ao sítio daquele local e **paga o salário na hora**, `transfer(site → worker, wage_per_minute × minutes, salary)`. Sem saldo no sítio: `ECON_INSUFFICIENT_FUNDS`, os minutos **não** contam e o sítio para por `NO_FUNDS`. Isso substitui o `IncomeStub` (LW-095); a necessidade `income` passa a ser atendida pelo dinheiro recebido (mapeamento no `npc`, extensão do `npc.md` na LW-087c) [Q8].
- **Hora a hora [PROPOSTA, Q8].** A cada hora, cada sítio **compra insumos** do mercado local e **vende o excedente** de produto ao mercado local, pelo mesmo `request_trade` (o sítio é um dono); depois, com minutos acumulados de trabalho e insumos presentes, executa os lotes possíveis: consome os insumos e cria os produtos (`consumed` e `produced` do `GoodsStore`). Assim o dinheiro da venda paga o salário e a cadeia anda dentro do mercado de cada povoado. Entre povoados, só os comerciantes (LW-098).
- **Motivo de parada (registrado, para o painel "Por quê?"):** `NO_INPUT` (sem insumo), `NO_WORK` (sem minutos de trabalho), `OUTPUT_FULL` (sem espaço para o produto) e `NO_FUNDS` (sem saldo para o salário). `ProductionStopped` e `ProductionResumed` saem **só na mudança** de estado, nunca por hora.
- **Produtores adaptativos** (LW-103): ajustam o que produzem aos preços com **limite e inércia**; seção própria quando a tarefa chegar, sem sorteio.

## 7. Consumo, NPCs no mercado e fim dos provisórios (LW-093, LW-094, LW-095)

- **Consumo:** `request_consume(owner_id, good_id, quantity)` **destrói** bens do inventário (`consumed`) e devolve o alívio total (`need_relief` × quantidade) para o `npc` aplicar à necessidade; falta de bem devolve `ECON_INSUFFICIENT_GOODS` e nada muda. A economia **não** conhece `NpcState` nem necessidades: só IDs e números. Quais bens saciam o quê e quanto é dado em `goods.json` [Q9].
- **NPCs no mercado (LW-093):** as ações de catálogo **comprar** e **vender** (do `npc`) chamam `request_trade` e a ação `eat` passa a consumir do **inventário do próprio NPC**; a decisão de comprar (o quê, quando, onde) é utilidade do `npc` (extensão do `npc.md`, LW-087c). A economia **nunca** importa o `npc`; o `npc` recebe a porta `economy/api` **pelo construtor**, como já recebe as definições.
- **Pré-requisito da LW-093 (decidido, item 4):** o **verificador pequeno de ids de conteúdo** (cada id escrito como constante no código existe em `data/`; backlog, achado M5 da revisão C), em **tarefa à parte**, antes da LW-093, porque a LW-093 cria ações novas (`buy`, `sell`) e a 095 mexe em `work`. **Não há** refatoração dos arquivos grandes do `npc` (decidido).
- **Dinheiro inicial (decidido, 3.4):** o `mint` inicial (`game_start`) entra **na LW-093**, ou a **LW-095 vem antes da LW-094**: sem dinheiro, quem não é lavrador (guarda, estalajadeiro, artesão, lenhador) não compra comida e a LW-094 não fecha os 30 dias verdes. A LW-087a escolhe a ordem; este contrato vale para as duas.
- **Fim dos provisórios:** `FoodStub` (TEMP-LW-065) sai na **LW-094** (a comida passa a vir do mercado ou do inventário; o estoque `food_stock` deixa o save do `npc` e save antigo é rejeitado, sem migração) e `IncomeStub` (TEMP-LW-066) na **LW-095** (salário pelo `Ledger`). A **LW-094 e a LW-095 apagam `test_food_stub.gd` e `test_income_stub.gd`** (59 e 26 referências): AGENTS 9.5 proíbe apagar teste sem explicar, então o texto de cada tarefa traz a **autorização escrita de Arthur** para isso. `tools/check_temp` (LW-114) vale só em `src/`, `data/`, `tests/`, `tools/` e `scenes/`, **fora de `docs/`** (decidido, 3.6: o Anexo D e o `npc.md` citam as marcas para sempre).

## 8. Contratos (LW-096, LW-107)

- **`Contract`:** `contract_id` (inteiro), `kind` (`labor` = trabalho avulso e `delivery` = entrega na Fase 3; escolta e recompensa são [FUT]), `issuer_id`, objetivo (`labor`: `place_id` e `minutes`; `delivery`: `good_id`, `quantity` e `destination_id`), `reward` (inteiro), `deadline` (minuto de simulação), requisitos (vazios na Fase 3), estado (`open`, `accepted`, `completed`, `failed`, `expired`) e `acceptor_id`. O contrato é dono de uma conta do tipo `contract` (a **custódia**).
- **`request_post_contract`:** valida (emissor aberto, recompensa de 1 ou mais, prazo no futuro, objetivo possível: local e destino existem, quantidade de 1 ou mais) e **retém** a recompensa: `transfer(issuer → contract, reward, contract_escrow)`. Impossível ou sem fundos: erro (`ECON_CONTRACT_IMPOSSIBLE`, `ECON_INSUFFICIENT_FUNDS`) e nada muda. **`request_accept_contract`:** só contrato `open`, um aceitante na Fase 3.
- **Conclusão:** `labor` quando o aceitante registra os `minutes` de trabalho no local dentro do prazo (`request_work_shift` soma ao contrato); `delivery` por `request_deliver_contract`, que move os bens do aceitante ao destino. Paga `transfer(contract → acceptor, reward, contract_payout)` e publica `ContractCompleted`. **Prazo vencido:** devolve ao emissor (`contract_refund`) e publica `ContractFailed` (motivo `expired`); a custódia nunca fica retida [Q14].
- **Contrato entre NPCs** (GDD 7.4, "NPCs também aceitam contratos uns dos outros"): `ContractOffered` é o canal (o `npc` o ouve); o **comportamento** do NPC aceitar contrato não existe na Fase 3 e depende de tarefa do `npc` [FUT].
- O quadro de contratos do jogador (LW-107) é apresentação, pela ponte; a economia só devolve `peek_contracts`.

## 9. Rotas, comerciantes, caravanas e fluxo (LW-097 a LW-102): só reserva

Esta ficha **reserva** os nomes e as fronteiras; o contrato detalhado de cada parte vem antes da sua tarefa (AGENTS 5.6). **Rotas** são do `world` (LW-097: grafo, `RouteStateChanged`, comando de depuração de **fechar rota**, terceiro assentamento; a economia só ouve; menor 9, decidido). **`Caravan`** (LW-098): comerciante NPC com carga, rota, posição lógica e estado, em modo abstrato S1; a carga é o inventário do próprio comerciante (sem tipo de dono novo) e o lucro passa pelo `Ledger`. **`TradeFlow`** (LW-100): transferência **agregada** por rota (bem, quantidade por dia, atraso, risco por regra), uma **abstração econômica sem dependência de LOD S2** (decidido, 3.2); o SP7 (LW-101) decide se caravana e fluxo equivalem; a LW-102 (alternância por `LodChanged`) é condicional e **dispensada** se o SP7 decidir por um só modo. `CaravanAttacked`, `RouteCargoLost` e `BusinessBankrupt` (arquitetura 11.9) **não têm tarefa na Fase 3** (combate de caravanas, bandidos e propriedade complexa são "não fazer", 3.J) [Q12].

## 10. API pública

Padrão `peek_*` (consulta, devolve **cópia**), `request_*` (comando, devolve `Result`) e `on_*` (reação a evento). Os **tipos de resposta** ficam em `economy/api/` (lição da LW-085a: a porta não devolve tipo interno; a regra D do `check_architecture` já cobre qualquer módulo com pasta `api/`). Todos os `peek_*` listam por ID crescente.

| Nome | Tarefa | Descrição |
|---|---|---|
| `peek_balance(owner_id)` | 088 | saldo do dono; `ECON_UNKNOWN_OWNER` se não existe |
| `peek_conservation()` / `peek_ledger_totals()` | 088 | soma das contas, criado, destruído e `ok`; totais por motivo |
| `peek_inventory(owner_id)` | 089 | quantidades por bem, peso total e capacidade |
| `peek_goods_conservation()` | 089 | conferência de bens criados e destruídos por bem [Q13] |
| `peek_market_of(settlement_id)` / `peek_market(market_id)` | 090 | o mercado do assentamento; estoque, alvo, preço, ask, bid e escassez por bem |
| `peek_price(market_id, good_id)` / `peek_stock(market_id, good_id)` | 090 | preço atual e estoque (nomes da arquitetura 11.10) |
| `peek_quote(market_id, good_id, quantity, side)` | 091 | custo e preço médio de uma ordem, sem executar |
| `peek_terms(good_id, market_id, actor_id)` | 091 | a pergunta da `TradeRules` (a neutra devolve tudo livre) |
| `peek_site(site_id)` / `peek_site_at(place_id)` / `peek_sites_of(settlement_id)` | 092 | receita, estado, **motivo de parada**, minutos acumulados e estoques do local |
| `peek_contracts(filter)` | 096 | contratos por estado, emissor ou local |
| `request_open_owner(owner_id, kind)` | 088, 089 | abre conta e inventário; idempotente; o `mint` inicial do tipo (decidido, 3.4) |
| `request_trade(actor_id, market_id, good_id, quantity, side)` | 091 | seção 5; atômico |
| `request_transfer_goods(from_id, to_id, good_id, quantity)` | 089 | move bens entre donos (entrega, carga); sem criar nem destruir |
| `request_consume(owner_id, good_id, quantity)` | 093 | seção 7 |
| `request_work_shift(place_id, worker_id, minutes)` | 092, 095 | trabalho e salário (seção 6) |
| `request_post_contract(...)` / `request_accept_contract(contract_id, actor_id)` / `request_deliver_contract(contract_id)` | 096 | seção 8 |
| `request_set_stock(market_id, good_id, quantity)` | 090 | **só em build de desenvolvimento**, para testar escassez |
| `on_npc_died(event)` | 089 | fecha a conta e o inventário do NPC [Q2] |
| `on_route_state_changed(event)` | 098, 100 | rota fechada ou aberta (a economia só reage) |
| `on_lod_changed(event)` | 102 | só se a LW-102 existir (condicional) |

## 11. Eventos

Publica (todos **planejados**, nenhum existe; o catálogo com publicador, ouvintes, carga e crônica está em `docs/events.md`, LW-087d): `PriceChanged` e `ShortageDeclared`/`ShortageEnded` (LW-090), `ProductionStopped`/`ProductionResumed` (LW-092) e `ContractOffered`/`ContractCompleted`/`ContractFailed` (LW-096). Ouve: `NpcDied` (já existe, LW-081) e `RouteStateChanged` (do `world`, LW-097); `LodChanged` só se a LW-102 existir; `LawChanged` e `WarDeclared` são da Fase 4. Sem evento em laço quente: compra, venda e consumo **não** publicam evento. A cadeia de causas (`cause_id`) de preço e escassez é a do `EventBus` (LW-104).

## 12. Dado → dono

| Dado | Dono | Observação |
|---|---|---|
| Contas e saldos (todo dono) | `economy` (`Ledger`) | salvo; entra no `state_hash`; **único** lugar que escreve saldo |
| Totais do `Ledger` por motivo | `economy` | salvo |
| Quantidades de bens por dono | `economy` (`GoodsStore`) | salvo; nenhum outro módulo guarda quantidade |
| Preço, estoque, alvo e histórico por (mercado, bem) | `economy` (`MarketState`) | salvo (o alvo vem de `data/`) |
| Locais de produção e seus minutos acumulados e motivo de parada | `economy` | salvo |
| Contratos e a conta de custódia | `economy` | salvo |
| Mapa assentamento → mercado | `economy` | salvo |
| Definições: bens, receitas, parâmetros de preço, alvos, tipos de dono | arquivos de `data/economy/` (conteúdo) | o `data` lê e valida; a economia só lê; não salvo |
| `Settlement`, `Place`, rotas | `world` | conteúdo; a economia só consulta |
| Quem trabalha onde, ofício, necessidades | `npc` | a economia só recebe IDs e minutos |
| Equipamento em instâncias | `character` | Fase 5 |
| Regras de tarifa e proibição | `TradeRules` (neutra agora; `politics` na Fase 4) | entregue ao construtor |
| Contador de IDs, sorteio, relógio, fila de eventos | `core` | a economia só usa `ctx` |

## 13. Arquivos de dados

JSON em `data/economy/` (subpasta, como `data/world/`), uma lista de objetos com `id`, **tabelas planas sem listas aninhadas** (`data.md`: o `data` só aceita lista de inteiros), lidas **juntas** pelo carregador da economia para a conferência de referências (como o `npc` faz com as suas seis tabelas). Formato **[PROPOSTA]**, DEC-082 (só o JSON validado é APROVADO). Nada disto é criado nesta tarefa; **colunas, tipos, faixas e a lista dos bens e das receitas** estão em `docs/economy/dados.md` (LW-087d). Cada arquivo nasce na tarefa que o usa:

| Arquivo | Tarefa | O que é |
|---|---|---|
| `goods.json` | 089 | os 10 bens (`GoodDef`) |
| `owner_kinds.json` | 089 | tipos de dono: capacidade de peso e saldo inicial |
| `market_targets.json` | 090 | estoque-alvo e estoque inicial por (assentamento, bem) |
| `price_params.json` | 090 | constantes de preço, spread, escassez e limite de ordem (uma linha) |
| `recipes.json`, `recipe_inputs.json`, `recipe_outputs.json` | 092 | as 10 receitas, com insumos e produtos em tabelas à parte |
| `production_sites.json` | 092 | os locais de produção: assentamento, local, receita |
| `world/routes.json` | 097 | rotas (dado do `world`, contrato do `world`) |

Marcas **TEMP** (`data/food_stub.json` e `data/income_stub.json`) saem nas LW-094 e LW-095.

## 14. Rastreio: tarefa → seção → teste previsto

Nomes de teste são **[PROPOSTA]**; todos rodam sem janela e dentro do `check_all`, e cada tarefa traz o caso do critério de aceite, um caso de erro e um caso-limite (AGENTS 9.10).

| Tarefa | Seção | Testes previstos |
|---|---|---|
| LW-087a (DOC) | 15 | respostas dos pontos abertos; registro das DEC-047, DEC-049 e DEC-054 em `DECISIONS.md` (é da 087a, não deste rascunho) |
| LW-087b (este arquivo), 087c, 087d | todas | só documentos: contrato, extensões do `world.md` e do `npc.md`, `docs/events.md` e `docs/economy/dados.md` |
| Verificador de ids de conteúdo (tarefa à parte; **pré-requisito da LW-093**) | 7 | cada id de constante do código existe no catálogo; id removido do dado faz o verificador falhar |
| LW-088 | 2 | `test_ledger.gd`: teste de ouro após milhares de operações aleatórias (propriedade); transferência sem saldo devolve erro sem mudar nada; `mint` e `burn` somam e subtraem; ida e volta de save; a regra nova do `check_architecture` reprova saldo fora do `Ledger` (positivo e negativo) |
| LW-089 | 3 | `test_goods_inventory.gd`: validação de bens (faixas, referências, id repetido); adicionar, remover e transferir; peso e capacidade respeitados; conservação de bens; dono morto fica fechado e continua na soma; dono duplicado em `request_open_owner` é idempotente; ida e volta |
| LW-090 | 4 | `test_markets.gd`: preço dentro da faixa; estoque baixo sobe e alto desce; suavização sem salto; ordem grande move o preço contra o operador; comprar e vender na hora dá prejuízo (spread); `PriceChanged` só acima do limiar; escassez declarada e encerrada; **mercado sem produtor por 60 dias declara escassez**; ida e volta |
| LW-091 | 5 | `test_trade.gd`: transação atômica (tudo ou nada); saldo, estoque ou capacidade insuficiente devolve erro sem alterar nada; `TradeRules` trocada em teste altera a tarifa sem tocar a economia; conservação de dinheiro e de bens mantida |
| LW-092 | 6 | `test_production.gd`: produz conforme a receita; falta de insumo, de trabalho, de espaço ou de saldo para e **registra o motivo**; retoma quando volta; determinístico; ida e volta |
| LW-093 | 7 | `test_npc_market.gd`: NPC faminto com dinheiro compra e come; sem dinheiro não compra; produtor vende excedente; nenhum caminho altera saldo fora do `Ledger`; o `mint` inicial aparece na conta |
| LW-094 | 7 | `FoodStub` não existe; a busca por `TEMP-LW-065` em `src/`, `data/`, `tests/`, `tools/` e `scenes/` é vazia; vida sem jogador de 30 dias verde com a economia real; se falta comida, aparece escassez e não "comida mágica" |
| LW-095 | 6, 7 | `IncomeStub` não existe; a busca por `TEMP-LW-066` é vazia; trabalhador recebe salário; empregador sem saldo para a produção e registra o motivo; teste de ouro verde |
| LW-096 | 8 | `test_contracts.gd`: recompensa retida ao postar e paga ao concluir; prazo vencido devolve ao emissor; contrato impossível é recusado; conservação mantida |
| LW-097 a LW-102 | 9 | rotas e caminho (do `world`); `Caravan` só viaja com lucro esperado; `TradeFlow` move estoque com atraso e para com rota fechada; SP7; alternância sem perder nem criar bens (se existir) |
| LW-103, LW-104 | 6, 4 | produtores se ajustam dentro do limite e sem oscilar; fechar rota gera escassez, alta de preço e reação, e a cadeia de causas é consultável |
| LW-105 a LW-108 | 3, 10 | jogador compra e vende com peso e saldo corretos; a tela mostra o mesmo preço da consulta; o painel econômico só **lê** e mostra a conservação |
| LW-109 a LW-113 | 1 a 8 | soak de 1 ano: teste de ouro de dinheiro **e de bens** a cada dia, preços na faixa, sem hiperinflação nem escassez crônica; hash repetível por semente; save exato e **rejeição** de save antigo com mensagem clara; calibração só em `data/`; cenário de integração do jogador |
| LW-114 | 7 | `tools/check_temp` falha com marca `TEMP-LW-` em `src/`, `data/`, `tests/`, `tools/` ou `scenes/` e **não** olha `docs/` |
| LW-115, LW-116 | todas | revisão: dono único de estoque, preço e dinheiro; `TradeRules` como única inversão; nenhum saldo fora do `Ledger`; economia sem importar internos do `npc`; validação do jogador |

## 15. Pontos em aberto (recomendação completa) e decididos

**Decididos por Arthur (10/11/2026):** menores 7 a 11 e as decisões (1) a (4) do cabeçalho; ver as seções 1, 3, 4, 5, 7 e 9. **Nenhum ponto abaixo está decidido: cada um é uma `[PROPOSTA]` deste rascunho, com a recomendação, para Arthur responder na LW-087a. Não encontrei ponto de design que impeça de escrever o contrato; por isso não parei, e os pontos entram como proposta rotulada, para você decidir antes da LW-087a.**

- **Q1 Quem abre as contas.** O dono abre a sua: a economia abre `market`, `site` e `contract`; o `npc`, cada NPC ao criá-lo (por isso a economia é registrada antes); a ponte, o jogador. **Recomendo** `request_open_owner(owner_id, kind)` idempotente, com o `mint` inicial do tipo.
- **Q2 Dono morto.** **Recomendo** fechar a conta e o inventário ao ouvir `NpcDied`, mantendo-os na soma da conservação; herança é "não fazer".
- **Q3 Vocabulário dos motivos e dinheiro inicial.** **Recomendo** `game_start` (inglês, DEC-022) em lugar de `inicio_de_jogo` do roadmap, conjunto fechado de motivos em constantes, e os saldos iniciais por tipo em `owner_kinds.json` [HIP].
- **Q4 Quem é o dono de um local de produção.** O roadmap diz "conta do proprietário" (LW-092), mas "propriedade complexa" é "não fazer" (3.J). **Recomendo** o próprio local como dono (conta e inventário próprios), com `mint` inicial `game_start` e receita das vendas.
- **Q5 Dinheiro do mercado.** O mercado paga o produtor com a sua conta; sem fundos, `ECON_MARKET_NO_FUNDS`. **Recomendo** conta de mercado com `mint` inicial e receita das vendas (o spread deixa margem); sem sumidouro na Fase 3.
- **Q6 Curva do preço.** **Recomendo** a forma da seção 4 (inversa do estoque sobre o alvo, limitada à faixa e suavizada), com **testes por propriedade**; a curva exata é calibração (LW-112).
- **Q7 Spread e profundidade.** **Recomendo** as formas da seção 4 (spread em pontos-base, ordem percorrendo a curva unidade a unidade, com teto de ordem).
- **Q8 Trabalho, salário e vendas dos locais.** **Recomendo** `request_work_shift(place_id, ...)` com salário na hora e, uma vez por hora, compra de insumos e venda de excedente do local ao mercado do povoado (seção 6).
- **Q9 Quais bens saciam o quê.** Nenhum documento define. **Recomendo** `need_id` e `need_relief` em `goods.json`: `bread` sacia `hunger` com o alívio cheio e `grain` com alívio menor [HIP] (o GDD 12.3 põe grão na categoria alimento); os demais não são de consumo na Fase 3.
- **Q10 Ofícios, locais e distribuição das cadeias.** Os ofícios de hoje são `farmer`, `lumberjack`, `artisan`, `guard` e `innkeeper`; faltam quem minere e quem crie ovelhas, e cada povoado precisa de locais `work` suficientes. **Recomendo** reaproveitar `farmer`, `lumberjack` e `artisan` onde couber, criar `miner` e `shepherd` em dados, **distribuir as cadeias** de modo que nenhum povoado seja autossuficiente (cria motivo para comerciar) e tratar locais e população do terceiro povoado na LW-097. Isso muda `population.json` e os hashes do `npc`.
- **Q11 Perecibilidade.** **Recomendo** o campo existir (0 = não perece) sem comportamento na Fase 3.
- **Q12 Eventos da arquitetura 11.9 sem tarefa** (`CaravanAttacked`, `RouteCargoLost`, `BusinessBankrupt`). **Recomendo** não criar na Fase 3 (3.J) e deixá-los como "considerados e não incluídos".
- **Q13 Conservação de bens.** **Recomendo** a regra simétrica à do dinheiro: bens só nascem por produção e `game_start`, só morrem por consumo (e `spoiled`, reservado), e o soak confere por dia.
- **Q14 Contratos.** **Recomendo** `labor` = minutos de trabalho num local e `delivery` = bem no destino (seção 8); abandono por quem aceitou espera o prazo e devolve ao emissor.

Menores decididos (10/11/2026): **(7)** tributos na Fase 4; **(8)** alvo de estoque como dado fixo; **(9)** `RouteStateChanged` e o comando de fechar rota na LW-097; **(10)** sem `entities`, IDs de `ctx.ids`; **(11)** `TradeRules` entregue ao construtor, alinhar o texto na Fase 4.
