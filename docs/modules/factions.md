# Contrato — factions

Estado: **PLANEJADO, aprovado por Arthur em 11/11/2026, com os ajustes da LW-117g (DEC-227 a DEC-233) e da LW-117h (revisão R3); ainda não incorporado ao `main`.** A Fase 3 não foi implementada e a Fase 4 só começa depois dela: tudo abaixo é desenho, sem código, dado ou teste; a pasta `src/sim/factions/` hoje só tem o `README.md` de reserva, e o módulo nasce na LW-119 (AGENTS 5.5). Fontes: as decisões de Arthur de 11/11/2026 (**DEC-202 a DEC-212 e DEC-224 a DEC-226, APROVADAS**) e as técnicas do revisor (**DEC-213 a DEC-223, PROPOSTA**: padrão de trabalho, não obrigam), registradas pela LW-117a (`docs/decisions/0013-pre-voo-da-fase-4.md`); a DEC-050 e a DEC-051 (3 facções, 2 polities); arquitetura 12 e 13.5; GDD 10; roadmap LW-119 a LW-125; a seção 17 do `economy.md` (aprovada por Arthur em 11/11/2026). Rótulos: **decisão** (DEC APROVADA), **PROPOSTA** (DEC PROPOSTA ou desenho deste contrato sem DEC), **[HIP]** (número de trabalho, vai para `data/`), **[LIM]**, **[FUT]** e **[PEDIDO]** (o que este contrato pede a outro contrato). Nomes de campos, comandos, códigos `FACT_*`, arquivos de dados e testes são **PROPOSTA**. Nomes de facções, culturas e lugares são genéricos (DEC-100). **Não é deste contrato** (partes 117d a 117f): o `military` e o módulo `events` (crônica e reputação), o catálogo de eventos (`docs/events.md`) e as colunas dos arquivos de dados.

- **Responsabilidade:** as **facções** como atores coletivos que agem sem o jogador (DEC-045): membros, hierarquia, tesouro, influência nas províncias, relações entre facções, deliberação e **ordens** (contratos e pedidos de missão). É o **dono único** de: `Faction`, `Membership`, a **influência** de cada facção em cada província (DEC-213), a afinidade entre facções, o estado de moral, coesão e legitimidade, a lista de **líderes T3** e a cópia de leitura da reputação. **Não** faz política (leis, estabilidade, diplomacia e o **controle** das províncias são da `politics`), combate, forças e missões (`military`), crônica e reputação (`events`) nem dinheiro (é do `Ledger` da `economy`); **não** funda facção pelo jogador, nem faz intriga, sucessão complexa, rebelião ou diplomacia entre facções (DEC-054 e roadmap 4.J).
- **Entradas:** o passo do relógio (`tick`: **todo dia**, para os contadores e a deliberação provocada por evento, e **toda semana**, para a deliberação, a folha e a contribuição, **[HIP]**); dados de `data/factions/` (seção 11); comandos `request_*` (seção 9) do jogador (pela ponte), da `politics`, do `military` e de ferramentas de desenvolvimento; os eventos da seção 10.
- **Saídas:** consultas `peek_*` (cópias); contratos postados na `economy` (`request_post_contract`); pedidos de missão ao `military` **por evento**; os eventos da seção 10.
- **Dependências permitidas:** `core`, `data`, `world` (camada 2) e `economy` e `npc` (camada 3), **só pela `api`** de cada um (AGENTS 5.1). **Não importa** `politics`, `military`, `events` nem `combat`: as facções falam com eles **só por evento** (seção 1, regra das camadas). Camada 4.
- **Dados controlados:** tabela da seção 12.
- **Interfaces de comunicação:** seção 9 (`peek_*`, `request_*`, `on_*`) e seção 10 (eventos).
- **Testes necessários:** nomeados na seção 13, mais as regras gerais: mesma semente, mesmo hash (DEC-081); ida e volta de save; dado inválido falha apontando arquivo, item e campo; comando que falha não muda nada; **o jogador sujeito às mesmas verificações de qualquer NPC**; **dinheiro conservado** (nenhum teste desta ficha cria dinheiro fora do `Ledger`); sem janela (`--headless`).

## 1. Princípios, ciclo de vida, cadência e regra das camadas

- **Dono único e `ID + tabelas por módulo`** (arquitetura 12.2). Nenhum outro módulo guarda membro, posto, influência nem afinidade; os outros leem por `peek_*` e pedem por `request_*`. A facção **não tem posição, corpo nem inventário**: o que ela "tem" é dinheiro (`economy`, tesouro), pessoas (`npc`) e influência (aqui).
- **IDs.** `faction_id` inteiro de `ctx.ids`, nunca reutilizado (AGENTS 4.12); tipo de facção, posto e opção são **ids de texto** de `data/`. **O `owner_id` do tesouro é o próprio `faction_id`** (17.2 do `economy.md`: os IDs vêm do mesmo gerador, sem colisão). Quem age (NPC ou jogador) é um **`actor_id`**; a `Membership` não distingue os dois (arquitetura 12.4: o jogador é um membro como outro). **Id de dados × id de execução [PROPOSTA, achado R3-I6]:** em `data/` a facção tem **id de texto** (o `content_id`, por exemplo `faction_authority`); em execução tem o **`faction_id` inteiro**. `peek_faction` devolve também o `content_id`, e **`peek_faction_id_of(content_id)`** devolve o inteiro (erro tratado se o texto não existe). **Quem lê dado com id de facção em texto** (`polities.governing_faction_id` e `force_seed.owner_id`) **resolve para o inteiro no início** (`on_new_game`), com essa consulta, e guarda **só o inteiro**; a `factions` vem antes na ordem do `World`, então já existe. Província e povoado só têm id de texto.
- **Determinismo.** Facções, membros, postos e pares são visitados **por ID ou chave em ordem crescente**, nunca pela ordem de um `Dictionary`; o save guarda coleções em lista; copia o teste `test_dictionary_order_after_load.gd` (`MODELO.md`). O **único sorteio** é a escolha ponderada da deliberação (seção 4), por `ctx.rng` no fluxo nomeado `factions.deliberation`.
- **Ciclo de vida** (`SimModule`, `core.md`): `setup(ctx)`; `post_setup()` (assina os eventos da seção 10); `on_new_game(world_seed)` (cria as facções de `data/`, abre o tesouro de cada uma pela `economy` (`request_open_treasury`, DEC-227), **atribui os membros iniciais** e **promove os líderes a T3**, seção 5); `tick(elapsed_minutes)`; `serialize`; `on_load` (valida e rejeita com `Result`); `validate`; `debug_summary`; `teardown`. As definições entram **pelo construtor**, já lidas e validadas. **Ordem no `World`** (a única do projeto, **[PROPOSTA]**, achado R3-I9: os IDs nascem no `on_new_game` na ordem de registro, então ela decide os IDs e, por aí, o hash): `character`, `economy`, `npc`, `ecology`, `factions`, `politics`, `combat`, `military`, `events` (`ecology` e `combat` são da Fase 5). Esta ficha: **depois** de `economy`, `npc` e `ecology` (o `on_new_game` precisa dos NPCs e dos mercados) e **antes** de `politics`.
- **Regra das camadas, a que evita ciclo entre `factions`, `politics` e `military` (camada 4; PROPOSTA).** A dependência é de **mão única por `api`**: `politics` importa `factions/api` (consulta o líder e o tesouro, pede a promoção a T3), e `military` importa `factions/api` e `politics/api`. **`factions` nunca importa `politics` nem `military`**: o que ela precisa deles chega **por evento** (`MissionCompleted`, `MissionFailed`, `TerritoryDisputeResolved`) e o que ela manda vai **por evento** (`MissionOrdered`). Um teste do `check_architecture` confirma (seção 13).
- **Save.** Bloco `factions` do `serialize()`: facções, associações, influência, afinidades com o histórico de causas, líderes, ordens abertas, contadores de folha, cópia de reputação e o rastro curto de decisões. Definições **não** entram. **`save_version` continua em 2 e o save da Fase 3 é rejeitado com mensagem clara, sem migração** (DEC-127, DEC-134 e DEC-209).
- **Falha visível.** Todo comando devolve `Result` com código `FACT_*` (seção 9); ID inexistente nunca derruba o jogo (AGENTS 13.1).

## 2. Modelo de dados (arquitetura 12.2; DEC-202, 203, 213, 215, 217)

- **`Faction`:** `faction_id`; `type_id` (`authority`, `mercantile` ou `criminal`, DEC-050; **um só tipo no código**, o resto é dado); `culture_id` (uma das duas, DEC-203); `doctrine` (pesos por eixo, dados); **`player_can_join`** (dado: `authority` e `mercantile` sim, `criminal` **não**, DEC-202); `leader_id` (um `actor_id` T3, ou 0); `morale`, `cohesion` e `legitimacy` (inteiros de 0 a 100 [HIP]); `state` (`active` ou `collapsed`). **O tesouro** é a conta do tipo `treasury` na `economy`, aberta com o `faction_id` (DEC-215); a facção guarda só o id, **nunca o saldo**. **Sem campo de território:** o "território" do roadmap (LW-119) vira **influência** (DEC-213).
- **Influência (DEC-213).** Tabela `(faction_id, province_id) → influence` (inteiro de 0 a 10000 [HIP]): a **presença** da facção na província. É **dela**; o **controle** (quem governa a província) é da `politics`. Muda por opções da deliberação e pelo evento `TerritoryDisputeResolved` (seção 10); nenhum outro módulo a escreve.
- **`Membership`:** `actor_id` (**uma facção por ator** na Fase 4), `faction_id`, `rank_id`, `loyalty` (0 a 100 [HIP]), `joined_minute`, `contribution` (pontos acumulados) e `unpaid_weeks` (semanas sem soldo). O jogador usa a mesma tabela.
- **`RankDef`** (`data/factions/ranks.json`): `rank_id`, `type_id`, `order` (de 3 a 5 postos por tipo, GDD 10.6), `slots` (vagas por facção), `wage_per_week` [HIP], `contribution_bp` (a fatia que o membro repassa, 6.2), e os **requisitos** em tabela à parte (`rank_requirements`: `rank_id`, `kind`, `value`). `kind` é um vocabulário **fechado**: `reputation_min` (faixa mínima da reputação, **só o jogador**), `loyalty_min` (**só NPC**), `contribution_min` e `tenure_days`. **Habilidade** como requisito é [FUT]: o `character` só chega na Fase 5.
- **`FactionRelation`:** afinidade **inteira** entre um par de facções (de −100 a 100 [HIP]), **simétrica**, com o **histórico curto de causas** (cada mudança guarda o `cause_id`); a inicial vem de cultura e doutrina (`faction_affinity_rules` em dados). Diplomacia **entre facções** é [PREV] (GDD 10.6); aqui a afinidade só alimenta a deliberação.
- **Líderes T3 (DEC-217).** A tabela `leader_links` (`npc_id`, `role` = `faction_leader` ou `ruler`, `entity_id`) guarda **quem é T3 e por quê**. O `npc` só marca o nível (T2 com vínculo de liderança, teto `max_t3`); **só a `factions` chama `request_promote(npc_id, 3)`** (seção 5).
- **Cópia de leitura da reputação (DEC-216).** Tabela `(entity_kind, entity_id, actor_id) → value, band`, preenchida **só** pelo evento `ReputationChanged` (o valor e a faixa vêm na carga). A `factions` **nunca** consulta o módulo `events` (camada 5, acima).
- **Ordens abertas:** `order_id`, `faction_id`, `kind` (`contract` ou `mission`), o id do contrato (`economy`) ou do pedido de missão, `state` (`open`, `done` ou `failed`) e o `cause_id` da decisão.

## 3. Hierarquia, entrar, subir e sair (LW-120; DEC-202)

- **`request_join(faction_id, actor_id)`:** recusa, **sem mudar nada**, se a facção não existe ou **colapsou** (`FACT_COLLAPSED`), se o ator já é membro de alguma (`FACT_ALREADY_MEMBER`), se é o **jogador** e a facção tem `player_can_join` falso (`FACT_NOT_JOINABLE`), se o posto de entrada **não tem vaga** (`FACT_NO_VACANCY`) ou se algum requisito não é atendido (`FACT_REQUIREMENT_NOT_MET`, com a **lista dos que faltam**, para o painel mostrar o motivo, LW-141). Aceito, publica `MemberJoined`.
- **`request_promote(actor_id)`:** sobe o membro ao posto seguinte, com as **mesmas** verificações (vaga e requisitos); no topo, `FACT_TOP_RANK`. Publica `MemberPromoted`. Vale para o jogador e para NPC; a deliberação promove NPC pelo mesmo comando (a opção `promote_member`, seção 4). **Vaga** é por posto e por facção; ao subir, o posto antigo libera a vaga.
- **`request_leave(actor_id)`:** o membro sai. **Sem custo de reputação na Fase 4** [PROPOSTA]: o custo da traição (GDD 10.5) entra quando houver caça e reputação por facção em uso; **alternativa:** `ReputationChanged` por sair (pedido à parte 117d).
- **Mesmas regras, requisitos de tipos diferentes.** O requisito `reputation_min` vale **só para o jogador** (a reputação é do jogador, DEC-208) e o `loyalty_min` **só para NPC**; os demais (`contribution_min`, `tenure_days`) valem para todos. Um posto pode ter os dois primeiros ao mesmo tempo. [PROPOSTA; ponto 3 de 15; alternativa: dar reputação ao NPC, que o GDD 20.3 e a DEC-208 não pedem.]
- **Facção colapsada** não aceita comando algum (`FACT_COLLAPSED`).

## 4. Deliberação (LW-124; arquitetura 12.3; DEC-221)

- **Cadência:** **semanal** [HIP] e também **quando um evento relevante chega** (escassez, rota fechada, guerra, fim de ordem), **no máximo uma vez por dia** por facção (sem laço quente).
- **Opções em dados** (`data/factions/faction_options.json`, **tabela plana**): `option_id`, `type_id`, `cost` (inteiro, [HIP]), `base_weight`, `doctrine_axis` (que eixo da doutrina pondera), `condition_kind` e `condition_value`, `effect_kind` e os parâmetros do efeito. **`condition_kind` e `effect_kind` são vocabulários fechados** (código): condição nova ou efeito novo exige código; **opção nova com condição e efeito existentes entra só por JSON** (critério 8 de 4.F). Condições de partida [PROPOSTA]: tesouro mínimo, escassez declarada num povoado, rota fechada, estado diplomático hostil. Efeitos de partida: `post_contract`, `order_mission`, `adjust_influence`, `promote_member`, `reduce_spending`, `idle`.
- **Passos (determinísticos):** (1) **avalia** a situação **só por consulta** (saldo, influência, ameaças, preços, afinidades, membros livres); (2) **gera** as opções cuja condição vale e cujo `cost` **cabe no tesouro** (**facção sem dinheiro não escolhe opção que não pode pagar**); (3) **pontua** por peso-base, doutrina e **personalidade do líder T3**; (4) **sorteia** uma, ponderada, por `ctx.rng` (peso 0 nunca sai); (5) **aloca** o custo e executa o efeito (seção 6); (6) **registra** a decisão. Sem opção possível, registra `idle`.
- **Registro e "Por quê?":** cada decisão publica `FactionDecided(faction_id, option_id, cause_id)` e guarda no **rastro curto** (as últimas N, [HIP]) a lista de opções avaliadas e a escolhida; `peek_decision_trace` a devolve para o painel (LW-140). O `cause_id` liga o evento que **provocou** a deliberação ao que ela **causou** (a cadeia do cap. 13.5 da arquitetura).
- **Fora:** planejar vários passos, intriga e negociação com o jogador (GDD 10.6 [PREV]).

## 5. Membros iniciais e líderes (LW-121; DEC-217)

- **Atribuição inicial por dados** (`faction_seed.json`: `faction_id`, `settlement_id`, `occupation_id`, `rank_id`, `count` [HIP]): em `on_new_game`, a `factions` escolhe, **por ID crescente**, `count` NPCs do ofício naquele povoado (guardas na autoridade, comerciantes na mercantil, poucos na criminosa) e cria as `Membership`. Mesma semente, mesmo resultado. O `npc` devolve a **lista de IDs por ofício e povoado** por `peek_npc_ids_of(occupation_id, settlement_id)` (`npc.md` 16.3; o `peek_npc_ids()` sem argumento, que já existe, é outro).
- **Cultura aplicada à população** (LW-121) é dado de `world` e `npc` (parte 117e); aqui só o `culture_id` da facção.
- **Líder = T3 (DEC-217).** Em `on_new_game`, para cada facção, o líder é o membro de **maior posto e, no empate, menor ID**; a `factions` chama **`request_promote(npc_id, 3)`** do `npc` e grava o `leader_link`. O **limite** `max_t3` é do `npc` (em dados, [HIP]); cheio, o `npc` devolve erro e o `on_new_game` **falha com mensagem clara** (dado incoerente, não jogo).
- **`request_appoint_t3(npc_id, role, entity_id)`** é o **único** caminho para T3 (só a `factions` promove): serve às facções e à `politics`, que pede a promoção do **governante do país vizinho** (`role` = `ruler`), que **não tem facção** (DEC-051). Erros: `FACT_UNKNOWN_ACTOR`, `FACT_BAD_ROLE` e o do `npc` repassado.
- **Morte do líder (`NpcDied`):** a `factions` escolhe o novo líder pela mesma regra entre os membros restantes e promove; **sem membros**, a facção **colapsa** (seção 6.3). O líder do **governo** é o governante do país principal (`politics`, DEC-211), então a troca chega à `politics` pelo `MemberPromoted` do novo líder.

## 6. Finanças, ordens e colapso (LW-123 e LW-125; DEC-210, 215, 222 e 223)

6.1 **O tesouro e quem o usa.** A conta é da `economy`; **só a `factions` movimenta o tesouro de facção**, pelos comandos da seção 17 do `economy.md` (`request_pay`, `request_spend`, `request_post_contract`). Os outros módulos pedem **a ela** (`request_fund_supply`, seção 9): assim há **um dono** da política de gasto. A conservação é a do `Ledger`: nenhum comando daqui cria dinheiro.

6.2 **Receitas.** **Contribuição dos membros (DEC-210):** a cada semana cada membro repassa ao tesouro a fatia `contribution_bp` do seu posto (de **uma parte** do saldo, com teto, [HIP]), por `request_pay(membro → tesouro)`. Como a facção mercantil tem membros ricos (comerciantes), a receita **cai quando o comércio cai**, o que alimenta a cascata do cap. 13.5. Outras fontes: a tarifa e a multa que a `politics` manda ao tesouro do governo, e o **saque** que o assalto leva à criminosa (DEC-212; a economia o transfere). **Vendas** como receita do roadmap **não existem**: o tesouro não tem inventário (17.2) [LIM]. **[PEDIDO à parte 117b]:** a seção 17.3 do `economy.md` só tem o motivo `tax` para quem paga a um tesouro; a contribuição precisa de motivo **próprio** (`contribution`) ou **aceitar `tax`**. Até lá, este contrato usa `tax`. `FactionRevenueChanged` sai quando a receita semanal muda além do limiar em dados.

6.3 **Gastos e a falta de dinheiro (LW-123).** **(a) Soldo e salário** (`faction_salary`, `request_pay(tesouro → membro)`, semanal, `wage_per_week` do posto), **não pago a quem já recebe por um posto de serviço** (**sem pagamento duplo**, DEC-222): antes de pagar, a `factions` lê os trabalhadores atribuídos dos postos (`peek_posts_of`) e os pula. **(b) Suprimento** de força (`upkeep`, sumidouro, DEC-224) por `request_fund_supply`. **(c) Contratos e missões** que a facção ordena (6.4). **Sem saldo para a folha:** a facção **reduz gastos** (a opção `reduce_spending` passa a pesar mais e as caras deixam de caber), o membro não pago soma `unpaid_weeks`, perde `loyalty` e, passado `unpaid_weeks_limit` [HIP], **sai** (`MemberExpelled`, motivo `unpaid`). **Sem membros:** a facção **colapsa**: `state` = `collapsed`, ordens abertas canceladas, deliberação parada, `FactionCollapsed`; **o saldo do tesouro fica parado na conta e continua na soma** (ponto 4 de 17.11 do `economy.md`, aprovado): **nenhum dinheiro some** e não há comando de fechamento.

6.4 **Ordens (LW-125; arquitetura 12.3).** O efeito de uma decisão vira **dois** tipos de ordem: **(i) contrato** na economia (`request_post_contract`, emissor = o tesouro; `labor`, `delivery` ou **`escort`**, DEC-223), **só se o tesouro cobre a recompensa** (**contrato sem fundos não é postado**); o NPC aceita pela utilidade (seção 8 do `economy.md`) e o fim chega por `ContractCompleted` ou `ContractFailed` (a ordem fecha); **(ii) pedido de missão** ao `military`, **por evento** (`MissionOrdered(order_id, faction_id, kind, target_id, cause_id)`, **evento novo, PROPOSTA**, catálogo na parte 117f); a missão termina por `MissionCompleted` ou `MissionFailed` (a ordem fecha) e, se a missão é de escolta com contrato aceito, **quem resolve o contrato é o `military`** (`request_resolve_escort`, `economy.md` 17.6). O "pedido a membros" do roadmap **não é uma terceira forma**: é um contrato aberto a quem quiser aceitar (a economia não confere facção, que ela não conhece) [PROPOSTA; ponto 5 de 15].

6.5 **Folha dos postos de serviço (DEC-222).** No `on_new_game`, a `factions` chama **`request_set_payroll_source(settlement_id, faction_id)`**, uma vez por povoado listado em `faction_posts` (dado: quais povoados a facção de autoridade paga). **Sem a chamada** a economia paga pelo mercado, como na Fase 3. **O povoado C, do país vizinho (que não tem facção), segue pagando pelo mercado** na Fase 4 [PROPOSTA; ponto 6 de 15].

## 7. Relações entre facções (LW-122)

- **Afinidade** simétrica por par, de −100 a 100 [HIP], inicial por cultura e doutrina (`faction_affinity_rules`). `request_adjust_affinity` **não é público**: ela muda por **eventos** que a `factions` ouve (fim de ordem, disputa resolvida) e pelo efeito de opções. Cada mudança registra a **causa** (`cause_id`), respeita os limites (satura em −100 e 100) e publica `FactionRelationChanged(a, b, new_value, cause_id)`; a deliberação **lê** a afinidade como insumo.
- **Diplomacia entre facções** (alianças, tratados) é [PREV]; a diplomacia que existe na Fase 4 é **entre os dois países** e é da `politics`.

## 8. Reputação e o jogador (LW-120 e LW-128; DEC-208 e DEC-216)

- A reputação é **um número por entidade** (facção ou povoado) **do jogador**, em **5 faixas nomeadas**, e **é do módulo `events`** (parte 117d). A `factions` mantém a **cópia de leitura** (seção 2) e a usa **só** para o requisito `reputation_min` do jogador (3). `peek_reputation_view(actor_id, faction_id)` a devolve ao painel.
- **Atendido pela `chronicle.md` (seção 4):** a carga de `ReputationChanged` leva `entity_kind`, `entity_id`, `actor_id`, `value`, **`band`** (o número da faixa) e `cause_id`, para a `factions` não precisar dos limites das faixas (que são do `events`).
- **Fundar facção, financiar e trair** (arquitetura 12.4) são [PREV]; o jogador **entra, sobe, recebe contratos e sai**.

## 9. API pública

Padrão `peek_*` (cópia), `request_*` (`Result`) e `on_*`. Os **tipos de resposta** ficam em `factions/api/` (lição da LW-085a). Todo `peek_*` lista por ID crescente.

| Nome | Tarefa | Descrição |
|---|---|---|
| `peek_faction(faction_id)` / `peek_factions()` | 119 | o `content_id` (o id de texto de `data/`), tipo, cultura, id do tesouro, líder, moral, coesão, legitimidade, estado e número de membros; os ids |
| `peek_faction_id_of(content_id)` | 119 | o `faction_id` inteiro do id de texto de `data/`; erro tratado se desconhecido |
| `peek_membership(actor_id)` / `peek_members(faction_id)` | 119 | a associação do ator; os membros em ordem de ID |
| `peek_ranks(faction_id)` | 120 | os postos, as vagas ocupadas e livres e os requisitos |
| `peek_join_check(faction_id, actor_id)` / `peek_promotion_check(actor_id)` | 120 | a mesma verificação do comando, **sem executar**, com a lista de requisitos que faltam (painel da LW-141) |
| `peek_influence(faction_id, province_id)` / `peek_influence_in(province_id)` | 119 | a influência de uma facção ou de todas numa província |
| `peek_relation(a, b)` | 122 | afinidade e as últimas causas |
| `peek_leader_links()` | 121 | quem é T3, o papel e a entidade |
| `peek_reputation_view(actor_id, faction_id)` | 120 | a cópia de leitura (valor e faixa) |
| `peek_decision_trace(faction_id)` | 124 | as últimas decisões e as opções avaliadas (painel "Por quê?") |
| `request_join(faction_id, actor_id)` / `request_leave(actor_id)` / `request_promote(actor_id)` | 120 | seção 3 |
| `request_appoint_t3(npc_id, role, entity_id)` | 121 | seção 5; **só a `politics` e a própria `factions`** chamam (o `npc` só aceita a promoção a T3 vinda daqui) |
| `request_fund_supply(faction_id, amount)` | 135 | o `military` pede o suprimento de uma força; a `factions` o gasta do tesouro (`upkeep`, sumidouro) ou devolve `FACT_INSUFFICIENT_TREASURY` |
| `on_npc_died(event)` | 119 | tira o membro; se era o líder, escolhe o novo (seção 5) |
| `on_reputation_changed(event)` | 120 | atualiza a cópia de leitura |
| `on_contract_event(event)` | 125 | `ContractCompleted` e `ContractFailed` fecham a ordem |
| `on_mission_finished(event)` | 125 | `MissionCompleted` e `MissionFailed` fecham a ordem |
| `on_territory_dispute_resolved(event)` | 138 | muda a influência (seção 2) |

**Códigos de erro (`Result.code`, prefixo `FACT_`):** `FACT_UNKNOWN_FACTION`, `FACT_UNKNOWN_ACTOR`, `FACT_COLLAPSED`, `FACT_ALREADY_MEMBER`, `FACT_NOT_MEMBER`, `FACT_NOT_JOINABLE`, `FACT_NO_VACANCY`, `FACT_REQUIREMENT_NOT_MET`, `FACT_TOP_RANK`, `FACT_BAD_ROLE`, `FACT_INSUFFICIENT_TREASURY` e `FACT_DATA_INVALID` (dado inválido, apontando arquivo, item e campo). Os erros da `economy` (`ECON_*`) e do `npc` são **repassados** com a mensagem original.

## 10. Eventos

**Publica** (todos **planejados**, nenhum existe; o catálogo com publicador, ouvintes, carga e crônica é da LW-117f): `FactionDecided`, `MemberJoined` e `MemberPromoted` (LW-120), `MemberExpelled`, `FactionCollapsed` e `FactionRevenueChanged` (LW-123), `FactionRelationChanged` (LW-122), **`MissionOrdered`** (LW-125, evento novo PROPOSTA). **Ouve:** `NpcDied` (já existe, LW-081), `ReputationChanged` (`events`), `ContractCompleted` e `ContractFailed` (`economy`), `MissionCompleted` e `MissionFailed` (`military`), `TerritoryDisputeResolved` (`military`). **Sem evento em laço quente:** contribuição, soldo e membro que entra num dia calmo **não** publicam evento por pessoa (a receita é **agregada** por semana).

## 11. Arquivos de dados (nomes; colunas e faixas são da LW-117f)

JSON em `data/factions/` (subpasta, como `data/economy/` e `data/world/`), **tabelas planas sem listas aninhadas**, lidas **juntas** pelo carregador do módulo para conferir referências. Formato **PROPOSTA** (DEC-082): `factions.json` (as 3 facções: tipo, cultura, `player_can_join`, saldo inicial do tesouro), `faction_doctrine.json` (os pesos de doutrina por eixo, a `doctrine` da seção 2), `ranks.json` e `rank_requirements.json`, `faction_options.json`, `faction_seed.json` (membros iniciais), `faction_posts.json` (povoados cuja folha a facção paga), `faction_affinity_rules.json` e `faction_params.json` (limites, semanas sem soldo, tamanho dos rastros; uma linha). Cada arquivo nasce na tarefa que o usa.

## 12. Dado → dono

| Dado | Dono | Observação |
|---|---|---|
| `Faction`, `Membership`, hierarquia, vagas | `factions` | salvo; entra no `state_hash` |
| Influência por (facção, província) | `factions` | salvo; **o controle é da `politics`** (DEC-213) |
| Afinidade e o histórico de causas | `factions` | salvo |
| Líderes T3 (o papel e a entidade) | `factions` | salvo; o `npc` guarda só o nível |
| Cópia de leitura da reputação | `factions` | salvo; **o dono é o `events`** |
| Ordens abertas e o rastro de decisões | `factions` | salvo |
| Saldo do tesouro | `economy` (`Ledger`) | a `factions` só lê e movimenta pelos comandos |
| NPC, necessidades, nível | `npc` | a `factions` só consulta e pede a promoção |
| Definições: tipos, postos, opções, afinidade | arquivos de `data/factions/` | só leitura; não salvo |

## 13. Rastreio: tarefa → seção → teste previsto (nomes **PROPOSTA**)

| Tarefa | Seção | Testes previstos |
|---|---|---|
| LW-119 (estado, conta) | 1, 2, 12 | `test_faction_state` (facção criada por dados; influência só em província existente; ida e volta; `state_hash`); `test_faction_treasury` (a conta `treasury` abre com o `faction_id`; aparece no teste de ouro); `test_factions_dictionary_order` |
| LW-120 (hierarquia) | 3 | `test_hierarchy` (posto sem vaga recusado; requisito faltando recusado **inclusive para o jogador**; `player_can_join` falso recusa; promoção respeita a ordem); `test_join_check_peek` (o `peek` e o comando dizem o mesmo) |
| LW-121 (membros e líderes) | 5 | `test_faction_seed` (contagens por facção; mesma semente, mesmo resultado); `test_leaders_are_t3` (todo líder é T3 e membro; `max_t3` respeitado; só a `factions` promove) |
| LW-122 (relações) | 7 | `test_faction_relations` (simétrica; satura; cada mudança registra a causa) |
| LW-123 (finanças) | 6.2, 6.3 | `test_faction_finance` (sem pagamento o membro sai depois do limite; sem membros colapsa sem erro e **sem dinheiro perdido**; conservação; **sem pagamento duplo** a quem recebe pelo posto) |
| LW-124 (deliberação) | 4 | `test_deliberation` (mesma semente, mesma decisão; opção nova só por dados passa; sem dinheiro não escolhe opção cara; `FactionDecided` com `cause_id`) |
| LW-125 (ordens) | 6.4, 6.5 | `test_faction_orders` (a decisão "escoltar" posta o contrato; NPC aceita e cumpre; contrato sem fundos não é postado; a ordem fecha por evento); `test_payroll_source_set` (a folha do posto sai do tesouro) |
| LW-135 (forças, suprimento) | 9 | `test_fund_supply` (gasta do tesouro como `upkeep`; sem saldo devolve o erro) |
| LW-138 (disputas) | 2, 10 | `test_influence_from_dispute` (o evento muda a influência; a `factions` não escreve em dado alheio) |
| Arquitetura | 1 | no `check_architecture` (**PROPOSTA**, LW-119): a `factions` não cita `politics`, `military`, `events` nem `combat`; só `economy/api` e `npc/api` |

## 14. Decididos

- **Decididos por Arthur (APROVADAS):** 3 facções e 2 polities, uma simplificada (DEC-050 e DEC-051); **o jogador só entra na autoridade e na mercantil**, a criminosa fica em forma mínima (DEC-202); duas culturas contrastantes, 4 parâmetros (DEC-203); a **criminosa vive de assaltos e da contribuição dos membros**, sem extorsão (DEC-210); **um governante por país** (DEC-211); o **assalto leva uma fração do dinheiro** (DEC-212 e DEC-226); o **`upkeep` é sumidouro** (DEC-224); o save não congela (DEC-209); a seção 17 do `economy.md`, que este contrato usa.
- **Do revisor (PROPOSTA, DEC-213 a DEC-223):** a influência é daqui e o controle da `politics` (213); o tesouro é do tipo `treasury` (215); a reputação chega por evento e fica numa cópia (216); T3 é T2 com vínculo, e só as facções promovem (217); os soldados têm "baixa" e "em missão" (219); os seis eventos da arquitetura (221); a folha dos postos passa ao tesouro da autoridade (222); o contrato `escort` (223).

## 15. Pontos da revisão, aprovados por Arthur em 11/11/2026 (as recomendações valem; nomes de campos, comandos, códigos e arquivos seguem PROPOSTA)

1. **Contribuição dos membros como receita** (6.2): uma fatia semanal do saldo, com teto. **Recomendo.** Alternativa: valor fixo por posto (mais simples, mas a receita não acompanha o comércio).
2. **A criminosa também paga contribuição e soldo** como as outras. **Recomendo** (uma regra só); alternativa: ela só vive do saque, e então **quebra** no soak de 1 ano se o assalto for raro (DEC-210 manda os dois: assalto **e** contribuição).
3. **Reputação só do jogador; o NPC usa lealdade** (3). **Recomendo.** Alternativa: dar reputação ao NPC (mais dados e mais eventos).
4. **Uma facção por ator** na Fase 4. **Recomendo.** Alternativa: várias (exige regra de conflito de lealdade, que não existe).
5. **"Pedido a membros" é um contrato aberto** e não uma terceira forma de ordem (6.4). **Recomendo.** Alternativa: um comando direto ao NPC (muda o `npc`).
6. **O povoado C segue com a folha pelo mercado** (6.5): o país vizinho não tem facção. **Alternativa:** a `politics` apontar a folha do C para o tesouro do **país** vizinho (precisa de um ajuste da seção 17.5 do `economy.md`, que hoje diz "tesouro da autoridade").
7. **Motivo próprio para a contribuição** (`contribution`), em vez de `tax` (6.2): **[PEDIDO à parte 117b]**.
8. **Quem escolhe o líder quando há empate:** menor ID (5). **Recomendo**; é só uma regra de desempate.
9. **Os valores [HIP]** (limites de moral, coesão e lealdade; semanas sem soldo; contribuição; custos das opções) seguem [HIP], em dados.
