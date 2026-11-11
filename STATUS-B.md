10/11/2026 21:20 (Brasília) — CONCLUÍDA: rodada 2 da LW-087b (`3eed5f8`) e da LW-087d (`4d49835`): PRONTAS PARA REVISÃO como RASCUNHO fora do `main`; `check_all` verde nos dois HEADs finais; 4 pontos novos em aberto (Q18 a Q21); parei (regra 13)

# RELATÓRIO — LW-087b e LW-087d, RODADA 2 (DOC): ajuste às suas novas decisões     Status: PRONTA PARA REVISÃO, **RASCUNHO (não está no `main`)**

**Antes de começar (AGENTS 2.3), em palavras simples.** Li: o `AGENTS.md` v0.4; os meus três arquivos como estavam; a revisão que a C fez deles (12 achados); o `npc.md` do ramo da C; e, no `main` `8dcc81d`, o `places.json`, a `population.json`, o `test_save_codec.gd` e o `world.gd`. DEC de que depende: **aprovadas por você hoje** (registro na LW-087a) DEC-047, 049 e 054 e as decisões 1 e 2 desta tarefa; **APROVADAS** DEC-046, 041, 100, 022, 126 e 127 (as DEC-082, 083 e 084 em parte); **PROPOSTA** DEC-048; **PENDENTE** DEC-040. Arquivos: `economy.md` (ramo 087b), `dados.md` e `events.md` (ramo 087d). Dúvidas: nenhuma que bloqueasse; os pontos novos entraram como perguntas (seção 7).

## 1. RESUMO
Apliquei as suas duas decisões (consumo = manutenção dos locais; postos de serviço pagos pelo mercado) e as do revisor (a a h). A ficha `economy.md` foi reescrita nas partes que mudam o desenho: manutenção com eficiência que cai por degrau e nunca zera, postos de serviço, "um trabalho, um pagamento", preço em inteiros, LW-088a, LW-096a, Q17 e distribuição das cadeias com os locais `work` contados. `dados.md` e `events.md` acompanham. Tirei todas as citações a arquivos de status. Só documentos.

## 2. ARQUIVOS CRIADOS
Nenhum.

## 3. ARQUIVOS MODIFICADOS
- **Ramo `lw-087b-contrato-economy`:** `docs/modules/economy.md`, em dois commits (`e013acd`, a rodada; `3eed5f8`, o risco do `fabric` e o ponto Q21). A ficha ficou com 285 linhas e 16 seções; a **seção 16** é nova (divergências do roadmap para a LW-087a registrar). `dados.md` ficou com 249 linhas.
- **Ramo `lw-087d-eventos-e-dados`:** `docs/economy/dados.md` (reescrito, 3 tabelas novas) e `docs/events.md` (`WagesPaid` com `workplace_id`), um commit (`4d49835`). O catálogo segue com **16 eventos** (6 existentes ou implementados e 10 planejados): recontado linha a linha.
- Nada protegido, nada em `data/`, código ou testes.

## 4. DECISÕES TÉCNICAS
- **Manutenção (sua decisão 1; entra na LW-092).** Tabela `site_upkeep.json` (por receita: bem `tool` ou `plank`, quantidade e período em dias) e `site_params.json` (queda, recuperação e **piso de eficiência maior que 0**). O local compra as peças do mercado pelo mesmo `request_trade`; o gasto destrói bens com o motivo **`maintenance`**, no conjunto fechado de motivos e na conservação de bens. Sem peças a eficiência **cai por degrau e nunca zera**. O lote avança em pontos-base (`batch_progress_bp`), em inteiros. **Números de partida [HIP]:** `tool` de 1 a cada 3 a 10 dias e `plank` de 1 a cada 5 a 20 dias por receita; piso 3000 e passo 1000. Tábua e ferramenta: manutenção; tecido: só mercadoria; calibração da LW-112.
- **Postos de serviço (sua decisão 2; entra na LW-095).** `service_posts.json`: um posto por ofício e povoado (guarda e estalajadeiro), folha **da conta do mercado**, tudo ou nada por posto e por hora, `NO_FUNDS` sem fundos. O posto não é dono (sem conta), é pago **antes** dos locais de produção e **não** publica `ProductionStopped`.
- **Contagem dos locais `work` (números do `main`).** Hoje A tem 5 locais de 12 e B 5 de 8, capacidade **igual** à população (60 e 40). Com um local próprio por local de produção e por posto, a distribuição precisa de **20 locais `work`: 10 novos** (A +2, B +3, C +5). Os **lavradores forçam dois locais `grow_grain` por povoado** (24 e 16 passam da capacidade de um), então são **14 locais de produção** (não 12) e 6 postos. **Basta um posto por ofício e povoado** (8 e 6 cabem em 12; 5 e 3 cabem em 8). Campo novo `workers_wanted` (equipe desejada, no máximo a capacidade) nos locais e nos postos; coluna `work_place_id` em `population.json` na LW-097.
- **Preço (e).** Fórmula em inteiros com **estoque de referência** (`ref_stock`), `ask = P + ceil_div(P × spread_bp, 20000)` e `bid = max(1, P − ...)`: vale `1 ≤ bid ≤ P < ask`, `spread_bp` de **1 a 20000** (0 é recusado) e a ordem de `q` unidades soma degrau a degrau. Com isso, comprar e vender `q` no mesmo instante perde **pelo menos `q`** (os dois lados usam os mesmos degraus): é invariante testável. O "meio a meio" saiu do `dados.md`. O `ref_stock` é uma peça que **acrescentei** para a conta não depender do caminho.
- **Um trabalho, um pagamento (a).** `request_work_shift` só para contrato `labor` e recusado com **`ECON_WORKER_ALREADY_ASSIGNED`** se o trabalhador já é atribuído àquele local. O `WagesPaid` **fica**, com `workplace_id` no lugar de `site_id` para cobrir local e posto.
- **LW-088a (f).** Regra nova no `check_architecture`; hashes por marco (1: registro da `economy`; 2: população da LW-097); `run_sim` não muda. **Fixture `save_v1`:** pelo que li, o `test_save_codec.gd` monta o mundo com um módulo de teste (`walker`) e **não** com o `GameModules`, então a fixture não deveria mudar; **não executei**. A regra continua: ficou vermelho, a LW-088a **PARA** e pede a sua autorização escrita antes de tocar em `tests/fixtures`.
- **Q17 (c), mint (d), LW-096a (g), `sell` (h):** nos textos e na tabela de rastreio; o `mint` deixa de ser "a LW-087a escolhe".
- **Teste de dados "nenhum povoado se basta" (achado 7):** `test_economy_distribution.gd`, na LW-097, com `test_no_settlement_is_self_sufficient` e `test_every_needed_good_has_a_producer` (definições de `Produzido(P)` e `Necessário(P)` no contrato). Não entra na LW-093a (precisa do 3º povoado e lê só tabelas da economia).
- **Escopo da LW-093a:** cresce de cerca de **60** para cerca de **150 a 200 linhas de código e teste** (um arquivo de verificação e um de teste), dentro do teto da DEC-126; depois da LW-092 e antes da LW-093.
- **Proposta de entrada para o `DECISIONS.md`:** nenhuma nova minha.

## 5. TESTES EXECUTADOS
- `tools/check_all` em `e013acd` (087b): **VERDE**, 124 scripts, 1194 testes, 261.693 asserts, 171,7 s.
- `tools/check_all` em `4d49835` (087d): **VERDE**, os mesmos números, 176,3 s.
- `tools/check_all` em `3eed5f8` (087b, **HEAD final**, depois do último commit): **VERDE**, 124 scripts, 1194 testes, 261.693 asserts, 175,5 s.
- Em sequência (evita dois Godot no mesmo `user://`). `git diff --check` limpo. O `main` (`8dcc81d`) continua dentro dos dois ramos (a junção foi na rodada 1; **não** é Fase B).

## 6. RESULTADOS — os 12 achados da C

| # | Achado da C | Situação | Onde |
|---|---|---|---|
| 1 | **Bloqueante:** a ficha dizia que aceitar contrato é [FUT], contra a sua Q22 | **Resolvido** | `economy.md` seção 8 (`vacancy`, LW-096a); `events.md` (`ContractOffered` e `ContractCompleted` com a vaga) |
| 2 | Salário: minutos, quem recebe, evento ausente | **Resolvido** | seções 6 e 11; `events.md` (`WagesPaid`); `request_work_shift` só `labor`; sem saldo o local para por `NO_FUNDS` e ninguém recebe |
| 3 | Ninguém consome madeira, tábua, ferramenta e tecido (decisão de design) | **Em parte.** Resolvido para `tool` e `plank` (manutenção, sua decisão 1). **Não resolvido para `fabric`:** sem comprador, o estoque cresce, o preço cai ao piso e o mercado pode ficar sem fundos (e sem pagar os postos) | seção 6 (limitação), pergunta **Q21** (teto de compra do mercado) |
| 4 | Preço mínimo 1 × `bid` arredondado × quantia mínima 1 | **Resolvido** | seção 4 (fórmula e invariantes); `dados.md` (`spread_bp` 1 a 20000) |
| 5 | Pagamento duplo no mesmo trabalho | **Resolvido** | seções 6 e 8 (`ECON_WORKER_ALREADY_ASSIGNED`) |
| 6 | Hash e fixture protegida ao registrar a `economy` | **Resolvido no texto; não executado.** Li o teste: usa um módulo de teste, a fixture não deveria mudar | seção 2 (LW-088a, itens 2 e 3) e linha da LW-088a no rastreio |
| 7 | "Nenhum povoado autossuficiente" sem teste | **Resolvido** | seção 6 e `dados.md`: `test_economy_distribution.gd` (LW-097) |
| 8 | "`market_reserved`" envelhece | **Resolvido** | seção 4 ("hoje `market_reserved`") |
| 9 | `RouteStateChanged`: carga diferente entre ramos | **Resolvido pela C** (alinhou o `world.md`); o meu `events.md` já estava com `route_id` e `new_state` | `events.md` |
| 10 | `request_trade` com `actor_id` e `side` fora da lista de divergências | **Resolvido** | seção 5 e **seção 16** (tabela de divergências) |
| 11 | "59 e 26 referências" não reproduzível | **Resolvido** | seção 7: "19 e 13 testes (funções `test_` de cada arquivo no `main` `8dcc81d`)" |
| 12 | "enquanto a Fase 2 não fecha"; ordem do `mint` entregue à 087a | **Resolvido** | cabeçalhos dos 3 arquivos ("a Fase 2 fechou em 10/11/2026; este arquivo entra no `main` quando Arthur escrever"); `mint` na LW-093 (seções 7 e 16) |

## 7. PROBLEMAS ENCONTRADOS (todos na seção 15 da ficha)
- **Q18, os postos de serviço e o Anexo D.** Provisório "até a Fase 4" pelo Anexo D pede marca `TEMP-LW-NNN` e entrada na tabela; o `check_temp` e o critério 3.F item 4 exigem **zero marcas** ao fim da Fase 3. **Recomendo** registrar como provisório **sem marca**. Decisão sua.
- **Q19, hashes.** Você citou dois marcos; as LW-093 a 095 também mudam o comportamento do `npc`. **Recomendo um terceiro marco.**
- **Q20, importações até o comerciante.** Só a comida do C é decisão sua; **recomendo** estoque inicial de 30 dias também para `tool` (A e B), `flour` e `plank` (B) e `wood` e `plank` (C).
- **Q21, o `fabric` sem comprador** (acima): **recomendo** um teto de compra do mercado, em dados.
- **Nome divergente na 087c:** o `npc.md` da C (`f2913f9`, linha 310) ainda escreve `WagesPaid (site_id, amount_each)`; o meu contrato usa **`workplace_id`**, porque o evento cobre local e posto. É da C ajustar (ou eu volto a `site_id`, se você preferir).
- **A 087a (A) já existe** no remoto (`86584d6`, DEC-129 a DEC-173): **não li**; os três rascunhos precisam ser conferidos contra ela depois.
- Os números de manutenção e de eficiência são **[HIP] meus** (você pediu "números pequenos"); nada foi calibrado.

## 8. RISCOS
- **Espiral de morte** se a folha parar (a hora parada não paga ninguém) e o mercado ficar sem fundos: ele paga produtores **e** postos com uma conta só. Pontos 3 e Q21.
- **Troca de emprego em laço** pela vaga: a LW-096a precisa de histerese.
- **Volume de dado novo:** 14 locais de produção, 6 postos, 10 locais `work`, 2 ofícios novos e a coluna `work_place_id` (muda o formato de `population.json` e os hashes).
- O `ref_stock` e a conta de degraus são desenho meu: a LW-090 confirma por teste de propriedade.

## 9. PENDÊNCIAS
Suas decisões: **Q18, Q19, Q20 e Q21**; aprovar (ou trocar) a **tabela de distribuição**, os números de manutenção e as **decisões do revisor**. Nenhum teste manual.

## ACOMPANHAMENTO
- **Avanço:** Fase 2 fechada (32 de 32); Fase 3 não iniciada; três rascunhos de documento (087b, 087c, 087d) e a 087a **fora do `main`**.
- **Próxima tarefa recomendada:** nenhuma minha (regra 13). Quando você mandar entrar: conferir 087b e 087d contra a 087a (A) e a 087c (C).
- **Git:** `lw-087b-contrato-economy` em `3eed5f8` e `lw-087d-eventos-e-dados` em `4d49835`, publicados só como ramos; **nada no `main`, sem tag, sem Fase B, sem `--force`**. O `main` seguiu em `8dcc81d`.
