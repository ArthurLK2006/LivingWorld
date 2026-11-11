11/11/2026 07:17 (Brasília) — CONCLUÍDA: rodada 4 da LW-087b (`16ddf1b`) e da LW-087d (`99dd70c`): Q22 (tecido na manutenção) e marcos de hash por bloco entraram; conferência contra a 087a (`28a0227`) e a 087c (`b7eb2ee`) feita; PRONTAS PARA REVISÃO como RASCUNHO fora do `main`; `check_all` verde nos dois HEADs finais; nenhuma pergunta aberta (só um plano B condicional); parei (regra 13)

# RELATÓRIO — LW-087b e LW-087d, RODADA 4 (DOC): tecido na manutenção dos locais (Q22), marcos de hash por bloco e vaga com salário e local     Status: PRONTA PARA REVISÃO, **RASCUNHO (não está no `main`)**

**Antes de começar (AGENTS 2.3), em palavras simples.** Li: o `AGENTS.md` v0.4; os meus três arquivos como estavam (`economy.md`, `dados.md`, `events.md`); o registro da LW-087a (índice e texto das DEC-129 a DEC-178, o diff do roadmap e o `0012`) e as extensões da LW-087c (`npc.md` e `world.md`). **Li os dois no início e de novo no fim:** a A estava em `1ad022a` quando comecei e **andou para `28a0227`** (a rodada 4 dela, com a DEC-178) enquanto eu preparava as edições, e a C andou de `b2d028d` para `b7eb2ee`; reli os dois e conferi tudo contra esses HEADs. No fim, **continuam em `28a0227` e `b7eb2ee`**, e o `main` em `8dcc81d`. Os arquivos de status delas só foram lidos, não citados em documento. DEC de que depende: no `main`, DEC-047, 049 e 054 seguem PROPOSTA (o registro da LW-087a as passa a APROVADA); no registro, **DEC-163 e DEC-178 APROVADAS** (a 178 é o tecido), DEC-164 APROVADA e as do revisor PROPOSTA (DEC-165, 169, 172, 174 a 177); PENDENTE DEC-040. Dúvidas: nenhuma que bloqueasse.

## 1. RESUMO
O **tecido entrou na manutenção dos locais** (decisão Q22): `site_upkeep` passa a `tool`, `plank` e `fabric`, com 8 linhas novas de números de partida, estoque inicial de tecido onde o povoado não tece (A 25, C 9) e uma **conta do tecelão e do pastor** que mostra quanto isso sustenta e onde fica fino, mais o **plano B** por escrito. Os **marcos de hash passam a ser por bloco** (marco 1 = LW-088a a LW-092; marco 2 = LW-093 a LW-096a; marco 3 = LW-097), a **LW-093b** entrou como pré-requisito da LW-093, e a **vaga** agora devolve o **salário por hora e o local** por consulta, como a 087c pediu. A seção 16 foi reescrita contra o registro atual e **não cita mais agente nem ramo**. Só documentos.

## 2. ARQUIVOS CRIADOS
Nenhum.

## 3. ARQUIVOS MODIFICADOS
- **Ramo `lw-087b-contrato-economy`** (`16ddf1b`): `docs/modules/economy.md` (+61 −50; 325 linhas).
- **Ramo `lw-087d-eventos-e-dados`** (`99dd70c`): `docs/economy/dados.md` (cerca de +59 −23; 299 linhas) e `docs/events.md` (+1 −1, só o rótulo "Q22 do `npc.md`"). **Recontei o catálogo: continuam 16 eventos** (6 existentes ou implementados e 10 planejados); nenhum evento mudou de nome, carga ou ouvinte.
- Nada protegido, nada em `data/`, código ou testes.

## 4. DECISÕES TÉCNICAS
- **Q22 (sua decisão) no contrato e nos dados.** O tecido sai de "só mercadoria" e entra na manutenção: cabeçalho (decisão 10), tabela dos 10 bens, motivo `maintenance`, vocabulário fechado de `site_upkeep` (`tool`, `plank`, `fabric`), `Necessário(P)` do teste de distribuição, tabela das importações e o rastreio. Mantido o que você mandou manter: NPC só come, roupa fora, teto de compra (Q21) e "hora parada = ninguém recebe". A Q22 saiu de "em aberto" para "decididas por Arthur".
- **Números de partida do tecido [HIP]** (1 unidade a cada N dias): `grow_grain` 5, `cut_wood` 10, `mine_ore` 5, `shear_wool` 10, `mill_flour` 3, `bake_bread` 10, `smelt_metal` 10, `weave_fabric` 10; **serraria e forja sem linha**. Racional: lonas (lenha, mina, fornalha) e sacos (grão, farinha, pão). São **8 linhas novas** (a tabela passa a 28). Conferi os totais por frações exatas, não de cabeça: A 0,833 por dia, B 0,800, C 0,300, **total 1,933**; estoque de 30 dias **A 25 e C 9** (B tece e não importa), batendo com o método por regra do teste de dados.
- **A conta do tecido** (nova seção do `dados.md`, resumida na seção 6 do contrato). Com a suposição de trabalho **de 2 unidades por hora de produção** (um lote por hora, 4 trabalhadores; **não é dado**, as quantidades de verdade são da LW-092): o tecelão e o pastor trabalham **0,97 hora por dia** (1,93 ÷ 2); para a renda do dia igualar **um dia de comida de uma pessoa (`f`)**, o `wage_per_hour` dessas duas funções tem de ser cerca de **1,1 `f` por hora**, a lã perto de **2,5 `f`** e o tecido perto de **5 `f`** de valor-base; cada um rende **cerca de 1,06 `f` por dia**; o gasto total com tecido é cerca de **10 `f` por dia**, contra 100 `f` por dia de comida dos 100 NPCs de A e B. Achado útil: a folha **por unidade** (cerca de 2,1 `f`) **não depende do rendimento do lote**, só da procura diária. Até a LW-098, só o B consome o tecido que faz: **0,4 hora por dia** e 0,44 `f` por dia, então o soak de 30 dias da LW-097 vive do dinheiro inicial. Tudo **[HIP], ilustrativo**; a calibração é da LW-112.
- **Plano B da Q22** (seção 6 do contrato, a linha da LW-110 no rastreio e a seção 15): se o soak da LW-110 mostrar fome no tecelão ou no pastor, a decisão **volta a você**, com **(1)** mais consumo de tecido (só dados) ou **(2)** o mercado pagar as horas paradas dessas duas receitas. A calibração só em dados da LW-112 vem antes e não precisa de você.
- **Marcos de hash por bloco.** Escrevi como o registro da LW-087a já escreve (DEC-175): a **primeira** mudança de cada bloco **PARA** e mostra a você antes, depois e causa; depois do "aprovo os hashes do marco N" as outras tarefas do bloco só registram; **da LW-098 em diante**, valor já aprovado que mude faz a tarefa parar e perguntar; o primeiro valor de teste novo não é mudança; o **código** do `run_sim` não muda (muda o hash que ele imprime). Seção 2, o rastreio (LW-088a, 092, 093, 094, 095, 096a, 097) e a seção 15. O rótulo é **Q19 revista (revisor, [PROPOSTA])**.
- **LW-093b** entrou na seção 7 e no rastreio como pré-requisito da LW-093, **depois da 093a** (só teste: ofício novo só por JSON; nenhum código de jogo).
- **A vaga mostra salário e local** (pedido da 087c, 14.4). Nomes: `workplace_id`, **`place_id`**, `settlement_id`, `occupation_id`, **`wage_per_hour`**, `workers_wanted` e `workers_assigned`, devolvidos por **`peek_contracts`** (na `vacancy`), **`peek_site`** e **`peek_post`** (seções 8 e 10). **[LIM]** o salário é por hora **em que o local produz**, não por dia; quem pesa isso na utilidade é o `npc`.
- **Numeração.** Os meus "Q19" e "Q22" colidiam com os do `npc.md` (comprar por utilidade; população empregada). Passei os do `npc.md` a **"Q19 do `npc.md`"** e **"Q22 do `npc.md`"**; "Q19" e "Q22" sem qualificador são os seus (marcos e tecido).
- **Seção 16:** primeira tabela (divergências do roadmap) atualizada (tecido, LW-093b, marcos por bloco); segunda tabela agora é a **conferência contra o registro da LW-087a (DEC-129 a DEC-178)**, 15 linhas, todas "bate" ou "fora desta conferência" (as DEC-158 a 162 são do `world`); sem "falta ajustar", sem letra de agente, sem nome de ramo. O `dados.md` também perdeu a citação do nome do ramo.
- **Proposta de entrada para o `DECISIONS.md`:** nenhuma minha. A **DEC-178** e a **DEC-175 por bloco** já estão no registro.

## 5. TESTES EXECUTADOS
- `git diff --check` em cada ramo antes do commit — **limpo** nos dois.
- `tools/check_all` em **`16ddf1b` (087b)**, começou 07:08, terminou 07:11 — **VERDE**: "Arquitetura: nove verificações aprovadas"; GUT: **Tests 1194, Passing Tests 1194, Asserts 261693**, Time 170,286 s; Warnings 1 e Deprecated 1 (iguais aos das execuções anteriores); linha final "VERDE: arquitetura, dados e etapa de testes aprovadas"; código de saída 0.
- `tools/check_all` em **`99dd70c` (087d)**, terminou 07:15 — **VERDE**, mesmos números (1194 de 1194, 261693 asserts, 170,344 s); código de saída 0.
- Rodados **em sequência**, não juntos. O `main` (`8dcc81d`) já estava dentro dos dois ramos; **não** houve junção nesta rodada. São só documentos, então o resultado confirma que nada de código, dado ou teste foi tocado.
- **Conta do tecido:** conferida por frações exatas (script de Python descartável, no diretório de temporários, não versionado). O script não foi guardado no projeto.
- **NÃO EXECUTADO:** nada mais. O `test_save_codec.gd` e a fixture `save_v1` **continuam sem execução** (é o que a LW-088a roda primeiro).

## 6. RESULTADOS
**Aceite, item a item.**

| Você pediu | Onde ficou |
|---|---|
| Q22: tecido na manutenção; sai "só mercadoria"; sai "só tool e plank" | `economy.md`: cabeçalho (8) e (10), seção 3 (tabela e motivo `maintenance`), seção 6 (manutenção, limitação trocada, tabela de importações, `Necessário(P)`), seção 7, seção 13, seção 15; `dados.md`: bens, estoque inicial, `site_upkeep` (vocabulário e tabela), testes |
| Marcos por bloco (seção 2 e rastreio) | `economy.md`: seção 2 (item 3), linhas LW-088a, 092, 093, 094, 095, 096a, 097 do rastreio, seção 15; `dados.md` (LW-097) |
| LW-093b como pré-requisito junto da 093a | `economy.md`: seção 7 e linha nova do rastreio |
| A vaga lê salário e local por consulta | `economy.md`: seção 8 (bullet novo), seção 10 (`peek_site`, `peek_post`, `peek_contracts`) |
| `dados.md`: vocabulário, linhas de tecido, cálculo, estoque de 30 dias, testes | seções `site_upkeep`, "A conta do tecido", Q20 (A 25 e C 9) e os dois testes de distribuição |
| Plano B | `economy.md` seção 6, rastreio da LW-110 e seção 15; `dados.md` (conta, item 5) |
| Seção 16 e tabelas de conferência | `economy.md` seção 16 |
| `events.md` só se mudasse | só o rótulo Q22; 16 eventos |

**Conferência contra a 087a (`28a0227`) e a 087c (`b7eb2ee`).**

| # | Item | Minha ficha | 087a (A) | 087c (C) | Situação |
|---|---|---|---|---|---|
| 1 | Tecido na manutenção (`tool`, `plank`, `fabric`) | seções 3, 6, 13 e `dados.md` | **DEC-178 APROVADA**, amplia a DEC-163; roadmap LW-092 diz "ferramenta, tábua e tecido" | `npc.md`: cabeçalho (9) e Q20 já dizem que o tecido entra (DEC-178) | **Bate**, com resíduos listados abaixo |
| 2 | Estoque inicial com tecido (A 25, C 9) | seção 6 e `dados.md` | DEC-178 (Consequências) e roadmap LW-097 ("inclusive tecido onde o povoado não tece") | não cita | **Bate** (os números 25 e 9 são só meus) |
| 3 | Marcos por bloco, regra de parar | seção 2 | DEC-172 e DEC-175 (por bloco) e linhas do roadmap | `npc.md` 14.8 e linhas 088a a 097 (por bloco) | **Bate** |
| 4 | LW-093b antes da LW-093 | seção 7 | DEC-137 e roadmap (LW-093 depende da 093a e da 093b) | linha da LW-093 | **Bate** |
| 5 | Vaga: salário e local por consulta | seções 8 e 10 | não trata | `npc.md` 14.4 pede e marca **[PENDENTE, pedido à B]** | **Respondido na minha ficha; a C atualiza o texto** |
| 6 | `WagesPaid(workplace_id, amount_each)` | seção 6 e `events.md` | DEC-152 já usa `workplace_id` | `npc.md` 14.4 | **Bate** (o `0012` da A ainda diz `site_id`; item 3 do PROBLEMAS) |
| 7 | `vacancy` em local de produção **ou posto** | seção 8 | DEC-165 já diz "local de trabalho" | `npc.md` | **Bate** |
| 8 | Postos sem `TEMP`; teto de compra; LW-088a | seções 6, 4 e 2 | DEC-164 e 174; DEC-177; DEC-171 e 172 | `npc.md` e `world.md` | **Bate** |
| 9 | Q19 e Q22: numeração | "do `npc.md`" quando é o do `npc.md` | usa nomes de tarefa | usa Q19 e Q22 no sentido do `npc.md` | **Sem conflito** |
| 10 | LW-094 em duas partes (094a e 094b) | não trato | uma tarefa só | propõe duas partes | **A e C decidem** (já estava assim na rodada 3) |

## 7. PROBLEMAS ENCONTRADOS
Só listados; não editei nenhum ramo da A nem da C.
- **A (`28a0227`):** (1) **DEC-153**, campo Decisão, ainda diz "o tecido é só mercadoria de comércio"; (2) **DEC-163**, campo Decisão (APROVADA), ainda diz "o tecido fica só como mercadoria"; as Consequências já remetem à DEC-178, mas a frase da Decisão ficou; (3) o **`0012`** ainda tem o texto antigo em três pontos: linha 115 (tecido só mercadoria), linha 120 (`WagesPaid` com `site_id`) e linha 133 (Q19 com "três marcos" por tarefa, LW-093 a LW-095); (4) o parágrafo de divergências do roadmap cita a LW-093a e **não** a LW-093b na linha da LW-093; (5) a **DEC-176** lista os importados sem o tecido (coberto pela DEC-178 e pelo roadmap da LW-097).
- **C (`b7eb2ee`):** (1) `npc.md` 14.4, bullet do emprego (Q22 do `npc.md`): ainda diz que o `economy.md` "não lista o salário" **[PENDENTE, pedido à B]**; agora lista (seções 8 e 10, `place_id` e `wage_per_hour`); (2) `npc.md`, Q20: o parêntese do mecanismo da manutenção ainda diz "`tool` ou `plank`"; (3) a divisão da LW-094 em duas partes, que a A não adotou.
- **Meu:** o erro de numeração (Q19 e Q22 duplicados) que achei nas minhas próprias fichas e corrigi. Um script de edição parou na primeira execução por um prefixo ambíguo (duas linhas começavam igual); **nada foi gravado** nessa tentativa e a segunda passou.

## 8. RISCOS
- **A cadeia do tecido é fina.** Duas funções vivem de cerca de **1 hora de trabalho por dia** (0,4 até a LW-098): tudo depende de `wage_per_hour` perto de 1,1 `f` e de valores-base altos para a lã e o tecido; a regra de margem fecha com **folga pequena** (10 `f` contra 9,4 `f`).
- **Preço do tecido abaixo do custo.** O preço cai quando o estoque passa do alvo e o piso (0,5 × valor-base, cerca de 2,5 `f`) fica **abaixo do custo de 4,8 `f`** do tecelão: se o estoque ficar acima do alvo, ele vende com prejuízo. A LW-112 tem de acertar alvo e estoque inicial; o teto de compra evita o pior (acima dele o mercado não compra).
- **A conta é ilustrativa:** 2 unidades por hora, 4 trabalhadores, spread de 10% e o símbolo `f` são suposições minhas, **não dados**. O que vale como requisito é só a forma (a folha por unidade depende da procura diária).
- Seguem de antes: `ref_stock` e degraus de preço são desenho meu, a confirmar por teste de propriedade na LW-090; soaks de 1 ano dependem da LW-098; o estoque de 30 dias só cobre o soak da LW-097; **LW-088a: a fixture `save_v1` não foi executada** (pelo que li, o `test_save_codec.gd` usa um módulo de teste, mas **não executei**).

## 9. PENDÊNCIAS
- **Suas:** aprovar, ou trocar, as decisões do revisor (agora com os **marcos de hash por bloco**, a **LW-093b** e os **nomes dos campos da vaga**), a tabela de distribuição e os números [HIP], inclusive a tabela de tecido e a conta; mandar os itens do PROBLEMAS à A e à C, se concordar; **o plano B da Q22 só volta a você se o soak da LW-110 mostrar fome**.
- **Do que não está feito:** nada de código, dado ou teste (é só documento). Nenhum teste manual.

## ACOMPANHAMENTO
- **Avanço:** Fase 2 fechada (32 de 32); Fase 3 não iniciada; rascunhos 087a, 087b, 087c e 087d **fora do `main`**. Sem pergunta aberta nas minhas fichas.
- **Próxima tarefa recomendada:** nenhuma minha (regra 13). Quando você aprovar o conjunto, a próxima do roadmap é a **LW-088a**, que **não iniciei**.
- **Decisões que dependem de Arthur:** (a) aprovar as propostas do revisor (recomendo aprovar, com atenção à tabela de tecido, que é a mais frágil); (b) plano B da Q22 só se a LW-110 pedir.
- **Git:** `lw-087b-contrato-economy` em `16ddf1b` e `lw-087d-eventos-e-dados` em `99dd70c`, **publicados só como ramos** (refspec explícita); este relatório vai só no `status-b`. **Nada no `main`, sem tag, sem Fase B, sem `--force`, sem `merge` no `main`.** O `main` seguiu em `8dcc81d`. Relatório da rodada 3: commit `03b6867` do `status-b`.
