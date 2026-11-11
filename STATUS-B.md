10/11/2026 21:36 (Brasília) — CONCLUÍDA: rodada 3 da LW-087b (`6b59a96`) e da LW-087d (`bfceb90`): Q18 a Q21 decididas, conferência contra a 087a e a 087c feita; PRONTAS PARA REVISÃO como RASCUNHO fora do `main`; `check_all` verde nos dois HEADs finais; 1 pergunta nova (Q22); parei (regra 13)

# RELATÓRIO — LW-087b e LW-087d, RODADA 3 (DOC): Q18 a Q21 decididas e conferência contra a 087a e a 087c     Status: PRONTA PARA REVISÃO, **RASCUNHO (não está no `main`)**

**Antes de começar (AGENTS 2.3), em palavras simples.** Li: o `AGENTS.md` v0.4; os meus três arquivos como estavam; no ramo da A (`86584d6`) o índice e o texto das DEC-129 a DEC-173, o diff do roadmap e o `0012`; no ramo da C (`f2913f9`) o `npc.md` e o `world.md`. DEC de que depende: no `main`, DEC-047, 049 e 054 seguem PROPOSTA (a 087a as passa a APROVADA); APROVADAS DEC-046, 041, 100, 022, 126 e 127; PROPOSTA DEC-048; PENDENTE DEC-040. Das DEC da A, usei as de números DEC-129 a DEC-173 como registro (sem editá-las). Arquivos: `economy.md` (ramo 087b), `dados.md` (ramo 087d); `events.md` só se mudasse (não mudou). Dúvidas: nenhuma que bloqueasse; o que achei da A e da C está só listado.

## 1. RESUMO
As suas quatro respostas entraram nas duas fichas: postos de serviço **sem marca `TEMP`**, **três marcos de hash**, **estoque inicial de 30 dias dos importados** (com tabela e teste) e **teto de compra por bem** (regra, passo em que age, linha da LW-090 e testes). A seção 16 do `economy.md` agora tem a tabela de divergências do roadmap e a conferência contra o registro da A. Achei, ao escrever o teto, um problema que ele não resolve e deixei como **pergunta nova, a Q22** (a cadeia do tecido). Só documentos.

## 2. ARQUIVOS CRIADOS
Nenhum.

## 3. ARQUIVOS MODIFICADOS
- **Ramo `lw-087b-contrato-economy`** (`6b59a96`): `docs/modules/economy.md` (+55 −27; 313 linhas).
- **Ramo `lw-087d-eventos-e-dados`** (`bfceb90`): `docs/economy/dados.md` (+19 −6; 263 linhas). `docs/events.md` **não mudou**; recontei o catálogo: **16 eventos** (6 existentes ou implementados e 10 planejados).
- Nada protegido, nada em `data/`, código ou testes.

## 4. DECISÕES TÉCNICAS
- **Q18 (postos sem `TEMP`).** Descritos como **regra de jogo até a Fase 4**, não código a remover: sem marca `TEMP-LW-`, sem entrada no Anexo D e **sem coluna `temp_mark`** em `service_posts.json`. O `check_temp` **continua exigindo zero marcas** ao fim da Fase 3 (critério 3.F item 4) e os postos não o atingem. É o mesmo que a DEC-164 da A já diz.
- **Q19 (três marcos de hash).** (1) LW-088a, (2) LW-093 a LW-095, (3) LW-097; você aprova os valores novos uma vez em cada. O `run_sim` não muda. Nas linhas de rastreio e na seção 2.
- **Q20 (estoque inicial dos importados).** Tabela no `economy.md` (seção 6) e no `dados.md` (`market_targets`): **comida no C** (decisão sua), **`tool` em A e B, `flour` e `plank` em B, `wood` e `plank` em C**. Números de partida [HIP] pequenos para a manutenção: **A 29 `tool`; B 29 `tool` e 21 `plank`; C 15 `plank`** (conta: A gasta 0,95 `tool` por dia nos 5 locais, B 0,95 `tool` e 0,7 `plank` nos 6, C 0,5 `plank` nos 3; 30 dias, para cima). `flour`, `wood` e a comida do C ficam como "30 × o consumo", porque as quantidades das receitas são [HIP] da LW-092 e a população do C é [PENDENTE, DEC-040]. **Conferência:** teste de dados `test_initial_stock_covers_30_days` (LW-097), para os bens que não são comida (`initial_stock` ≥ 30 × consumo por dia); a comida é provada pelo soak de 30 dias, sem morte, porque o consumo depende do `npc`.
- **Q21 (teto de compra).** Coluna **`buy_cap_bp`** em `market_targets` (por bem e mercado; [HIP], **partida 20000**, isto é, 2 vezes o alvo, que é onde o preço chega ao piso). **Regra:** o mercado não compra acima do teto; ordem de venda que passaria do teto é **recusada inteira** com **`ECON_MARKET_FULL`** (código novo, nome meu; entrou na lista de códigos). **Quando age:** em toda `request_trade` de venda, inclusive no passo 5 da hora do local, que vende até o espaço que sobra; o resto fica no inventário do local, que para por `OUTPUT_FULL` **sem perder eficiência** quando enche. A compra **do** mercado não é afetada. Linha da LW-090 no rastreio com cinco invariantes de propriedade (o estoque nunca passa do teto por vendas; ordem recusada não muda nada; `buy` intacta; `OUTPUT_FULL` sem perda de eficiência; conservação).
- **Q22, nova (o que o teto não resolve).** O teto protege a conta do mercado, mas o local de `weave_fabric` e o de `shear_wool`, sem comprador final, **param por `OUTPUT_FULL` e, pela regra "hora parada = ninguém recebe" (Q18 A, que você manteve), o tecelão e o pastor ficam sem salário**, não compram comida e, no soak de 1 ano, morrem. Opções na ficha: **(A)** a folha das horas paradas por `OUTPUT_FULL` sai da conta do mercado, como a dos postos; **(B)** consumo mínimo de tecido pelo NPC (contraria "roupa fora"); **(C)** aceitar e provar no soak da LW-110 com plano B. **Recomendo A.** Não decidi nada por você.
- **Seção 16 do `economy.md`** reescrita: tabela de divergências com o roadmap (12 linhas, com a LW-090 e a LW-097 atualizadas) e **tabela de registro na LW-087a** com os números de DEC.
- **Proposta de entrada para o `DECISIONS.md`:** nenhuma nova minha (a A registra; faltam DEC para Q20 e Q21).

## 5. TESTES EXECUTADOS
- `tools/check_all` em `6b59a96` (087b): **VERDE**, 124 scripts, 1194 testes, 261.693 asserts, 176,7 s; sem aviso novo (o "Warnings 1 / Deprecated 1" do GUT é o de sempre).
- `tools/check_all` em `bfceb90` (087d): **VERDE**, 124 scripts, 1194 testes, 261.693 asserts, 171,0 s; sem aviso novo (o "Warnings 1 / Deprecated 1" do GUT é o de sempre).
- Em sequência (evita dois Godot no mesmo `user://`); `git diff --check` limpo; o `main` (`8dcc81d`) já estava dentro dos dois ramos (junção da rodada 1, **não** é Fase B).

## 6. RESULTADOS — a conferência contra a 087a (A, `86584d6`) e a 087c (C, `f2913f9`)

| # | Item | Minha ficha (canônico) | 087a (A) | 087c (C) | Situação |
|---|---|---|---|---|---|
| 1 | Números de DEC | citadas só as do `main` e, na seção 16, as DEC-129 a DEC-173 | DEC-047, 049 e 054 viram APROVADA; DEC-129 a DEC-173 novas | cita DEC-022, 126, 127 | **Bate** |
| 2 | `WagesPaid` (carga) | `workplace_id` e `amount_each` (cobre local e posto) | DEC-152 e `0012` (linha 120): `site_id` e `amount_each` | `npc.md` 14.4 e 14.9 (Q18): `site_id`; lê a lista por `peek_site` | **Diverge: A e C ajustam** (e a C acrescenta `peek_post`) |
| 3 | LW-088a (regra nova, fixture protegida) | seção 2 e linha do rastreio | DEC-171, DEC-172 e linha do roadmap | `npc.md` 14.1 e `world.md` Q-W6 | **Bate** |
| 4 | Marcos de hash | **três**: LW-088a; LW-093 a LW-095; LW-097 | DEC-172 lista **dois** (registro da `economy`; população da LW-097) | `npc.md` 14.8 lista os **três** | **A ajusta**; a C já bate |
| 5 | LW-096a | seção 8 e rastreio | DEC-169 e linha do roadmap | linha da LW-096a (ainda "proposta; registro é da LW-087a") | **Bate**; a C atualiza a citação (DEC-169) |
| 6 | Postos de serviço sem `TEMP` | seção 6 e `dados.md` | DEC-164: "não é marca `TEMP-LW-`" | `npc.md` 14.4: "uma receita sem insumo nem produto", "opção A da Q15 do `economy.md`" | **A bate; a C ajusta** (o posto é **sem receita**, e a Q15 virou decisão) |
| 7 | Contagens 14 / 6 / 20 / 10 | seção 6 e `dados.md` | sem contagem; LW-097 não as cita | sem contagem; diz "cada local e cada posto ocupa um local `work` próprio" | **Sem divergência**; a A pode acrescentar à LW-097 |
| 8 | Códigos de erro | `ECON_*` (lista na seção 10), com `ECON_WORKER_ALREADY_ASSIGNED` e o novo `ECON_MARKET_FULL` | DEC-149 cita `ECON_MARKET_NO_FUNDS`; DEC-151 não dá o código | sem códigos `ECON_` | **Sem conflito**; a A pode registrar os dois códigos |
| 9 | `mint` inicial na LW-093, `game_start` | seções 3 e 7 | DEC-147, DEC-170 e linha da LW-093 | `npc.md` 14.4 | **Bate** |
| 10 | `request_trade(actor_id, market_id, good_id, quantity, side)` | seção 5 | DEC-173 | `npc.md` 14.2 | **Bate** |
| 11 | `vacancy` | seção 8 | DEC-165 | `npc.md` 14.4 | **Bate** |
| 12 | Local de produção com "conta do proprietário" | conta do próprio local (Q4) | DEC-148 diz "dono de si", mas a **linha da LW-092 do roadmap ainda diz "conta do proprietário"** | local dono do que produz | **A ajusta a linha da LW-092** |
| 13 | LW-097: o que entra | comando de fechar rota, `RouteStateChanged`, 10 locais `work`, `work_place_id`, estoque dos importados, testes de dados, marco 3 | a linha lista só estoque de comida do C e `work_place_id`; ainda diz "se preciso ampliar o terreno" (DEC-161 diz **não** ampliar) | `world.md` já tem as rotas | **A ajusta a linha da LW-097** |
| 14 | Teto de compra (Q21) e estoque dos importados (Q20) | decididos nesta rodada | **sem DEC e sem linha** na LW-090 e na LW-097 | não citados | **A registra** (nasceram agora) |
| 15 | Escopo da LW-093a | cerca de 150 a 200 linhas | linha do roadmap (DEC-137) bate | `npc.md` bate | **Bate** |
| 16 | `RouteStateChanged` (`route_id`, `new_state`) e `closed` = "bloqueada" | `events.md` | DEC-159 | `world.md` já alinhado | **Bate** |
| 17 | `market_reserved` → `market` na LW-093 | seção 4 ("hoje `market_reserved`") | DEC-160 | `world.md` | **Bate** |
| 18 | LW-094 em duas partes (094a, 094b) | não trato | uma tarefa só | `npc.md` 14.5 propõe 094a e 094b | **A e C decidem** (nenhuma das duas é minha) |

**Para mandar à A:** itens 2 (DEC-152 e `0012`: `site_id` → `workplace_id`), 4 (DEC-172: três marcos), 12 (linha da LW-092), 13 (linha da LW-097), 14 (DEC para Q20 e Q21 e as linhas da LW-090 e da LW-097) e, se você decidir, a Q22. **Para mandar à C:** itens 2 (`WagesPaid` com `workplace_id` e `peek_post`), 5 (citar a DEC-169) e 6 (o posto é **sem receita**; a Q15 do `economy.md` não existe mais como pergunta).

## 7. PROBLEMAS ENCONTRADOS
- **Q22** (acima): é consequência do desenho que você mandou (tecido só mercadoria, "hora parada = ninguém recebe", teto de compra). Sem demanda para o tecido, a cadeia dele não sustenta o emprego.
- Os números de estoque inicial dos bens que dependem de quantidades de receita e da população do C ficaram como fórmula, não como número: inventá-los seria desenho meu.
- Os itens 2, 4, 12, 13 e 14 da tabela são da A; os 2, 5 e 6 são da C. Não editei nenhum ramo delas.

## 8. RISCOS
Espiral de morte nas cadeias sem comprador (Q22); o `ref_stock` e a conta de degraus da seção 4 seguem desenho meu, a confirmar por teste de propriedade na LW-090; os soaks de 1 ano dependem da LW-098; o estoque inicial de 30 dias só cobre o soak da LW-097, não um ano.

## 9. PENDÊNCIAS
Sua decisão sobre a **Q22**; aprovar, ou trocar, as decisões do revisor, a tabela de distribuição, os números [HIP] e o teto de compra; mandar os itens à A e à C. Nenhum teste manual.

## ACOMPANHAMENTO
- **Avanço:** Fase 2 fechada (32 de 32); Fase 3 não iniciada; rascunhos 087a, 087b, 087c e 087d **fora do `main`**.
- **Próxima tarefa recomendada:** nenhuma minha (regra 13).
- **Git:** `lw-087b-contrato-economy` em `6b59a96` e `lw-087d-eventos-e-dados` em `bfceb90`, publicados só como ramos; **nada no `main`, sem tag, sem Fase B, sem `--force`**. O `main` seguiu em `8dcc81d`. Relatório da rodada 2: commit `c21659a` do `status-b`.
