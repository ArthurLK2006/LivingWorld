# LW-094b (nome de trabalho): contrato técnico das três regras de oferta (23/11/2026)

**Status:** PROPOSTA em ramo isolado (`lw-094b-regras-de-oferta`, criado de `lw-095-postos`). Autorização de Arthur de 23/11/2026: preparar e testar em ramo isolado as três regras do estudo LW-094a (`docs/economia/lw-094a-estudo-21-11.md`, seções 4, 4.1, 7 e 8), com contrato delimitado, testes de determinismo e conservação e comparação com o comportamento anterior. **NÃO** autoriza integrar as regras como definitivas nem regravar hashes. Nada aqui foi integrado; nenhum hash foi regravado.

## 1. Escopo
- **Dentro:** o `ProductionBook` (`src/sim/economy/production/`), a hora de produção da economia (`EconomyRuntime.run_production_hour`), o evento `WagesPaid` (só um campo opcional, ver 5) e o ouvinte do `npc` (`WageIncome.on_wages_paid`).
- **Fora (não muda):** os postos de serviço (`ServicePostBook`), o `FoodStub`, as necessidades do NPC (nada de 6ª necessidade), o formato do save, os dados (`data/`), os preços, o `TradeEngine`, o `Ledger`, o `WagePayer` (o tudo ou nada dele continua valendo para a lista que recebe), a manutenção (`end_of_day`) e o mercado de trabalho (`EconomyVacancies`).
- **Três regras independentes**, cada uma num commit (R, P, E), para medir e reverter uma a uma.

## 2. Definições
- **Hora absoluta `h`:** o número da hora cheia que a economia está processando, `h = minuto ÷ 60`, o mesmo `_last_hour` do `EconomyModule` (derivado do relógio; no carregar, `_last_hour = hora do relógio`). É a ÚNICA fonte da rotação: nenhum contador, nenhum sorteio, nenhum estado novo.
- **Estabelecimento:** um local de produção (`site`) do `ProductionBook`. Os postos de serviço NÃO são estabelecimentos para estas regras.
- **Equipe:** `workers_per_batch` trabalhadores da lista `worker_ids` do local. O local tem `t = min(max_batches_per_hour, ⌊trabalhadores ÷ workers_per_batch⌋)` equipes que produzem (`_batches_by_workers`, inalterado).
- **Equipe paga:** recebeu `wage_per_hour` por trabalhador, NESTA hora, pelo `Ledger` (motivo `salary`), antes de produzir.
- **Trabalho efetivamente realizado:** a equipe soma a eficiência do local ao progresso do lote nesta hora (`_run_batches`: `progresso += eficiência × equipes que rodam`) e esse progresso vira lote ou fica guardado (no máximo 9.999) para a hora seguinte. Na folha parcial o número de equipes pagas é limitado aos lotes que os insumos e o espaço do inventário deixam fazer nesta hora (`_batches_possible`, B): com `k ≤ B`, progresso `p ≤ 9.999` e eficiência `e ≤ 10.000`, o total `p + e·k ≤ 9.999 + 10.000·B`, então todo lote completo cabe nos insumos e o resto nunca passa do teto: nenhum trabalho pago se perde (revisão R3, D1). Com eficiência menor que 10.000 a equipe paga pode não fechar um lote na hora: o trabalho fica no progresso e conta na próxima.
- **Comprador do produto:** o mercado do POVOADO do local compraria AGORA um lote daquele bem: a cotação de venda do `TradeEngine` (`quote(mercado, bem, saída de um lote, sell, local)`, as mesmas conferências da venda: teto de compra, regras de comércio, tamanho da ordem) passa E o saldo do mercado paga o total cotado (o `MARKET_NO_FUNDS` da venda; revisão R3, D2). Escolhida por ser a de menor acoplamento: usa a cotação que a venda já faz, sem API nova. Os outros locais e os NPCs compram do mercado (não do local), então a procura deles aparece como espaço liberado no teto e dinheiro no caixa. Não existe comprador fora disso: nada de comprador ilimitado, nenhum outro mercado e nenhum comerciante "presumido".
- **Lote parado:** o local já tem no inventário pelo menos a saída de UM lote (`recipe.outputs[bem]`) que não conseguiu vender.

## 3. As regras (no nível dos métodos)
### R. Rodízio da ordem dos estabelecimentos
- `ProductionBook.hour_step(hour: int = 0)`; a economia passa `h` (`run_production_hour` já recebe `now = h × 60`).
- Ordem da hora (`SupplyRules.rotated_order(ids, h)`): com os `n` IDs em ordem crescente, começa no índice `h mod n` e anda para a FRENTE quando `⌊h ÷ n⌋` é par, para TRÁS quando é ímpar (circular). Em cada janela de `2n` horas, cada local é o primeiro exatamente 2 vezes e, para QUALQUER par de locais, cada um vem antes do outro em exatamente `n` horas (prova: na ida o par troca de ordem em `d` das `n` horas, na volta em `n − d`). Com `h = 0` a ordem é a antiga (testes que chamam `hour_step()` sem hora não mudam).
- Corrige o mecanismo M1 (a 1ª de duas fazendas iguais sempre enche o teto de compra).

### P. Folha parcial por equipe (só quando a folha inteira não cabe)
- Se a folha inteira cabe (`_payer.can_pay` com todos os trabalhadores): **exatamente o comportamento antigo** (DEC-151 e DEC-152): todos recebem, `t` equipes rodam.
- Se não cabe: o local escolhe o MAIOR `k` de 1 a `min(t, B)` (B = lotes que os insumos e o espaço permitem nesta hora, seção 2) tal que as `k` equipes cabem (`can_pay` com os `k × workers_per_batch` escolhidos: saldo, contas abertas e o teto de saldo de quem recebe). Quem: a lista `worker_ids` (crescente) girada pela hora, começando no índice `h mod trabalhadores`, pegando os primeiros `k × workers_per_batch` (`SupplyRules.rotated_team`); se essa janela tem uma conta fechada ou no teto de saldo, tenta as janelas seguintes (`h + 1`, `h + 2`, …) antes de reduzir `k`. Paga esses, pelo mesmo `WagePayer.pay` (tudo ou nada PARA ESSA LISTA), anuncia UM `WagesPaid` com a lista dos pagos, e roda `k` equipes (`progresso += eficiência × k`).
- `k = 0` (nem uma equipe cabe): `NO_FUNDS`, ninguém recebe, nada roda (DEC-169: parar, sem demitir).
- Com `0 < k < t` o local está **rodando** (motivo vazio): não é `NO_FUNDS`.
- Corrige M2 (`NO_FUNDS` absorvente). Não cria dinheiro: só move o saldo do local para os pagos.
- **Pergunta aberta para Arthur (classe 3, NÃO mudada aqui):** a folha CHEIA é a regra antiga (DEC-151) e paga TODOS os atribuídos, mesmo os que não trabalham: (i) os excedentes além de `t × workers_per_batch` (a fazenda de 12 lavradores com 1 lote por hora paga 12 e trabalha com 4; no teste, 4 atribuídos e 1 equipe de 3: a folha cheia paga 4); (ii) a equipe ociosa por falta de insumo ou de espaço (9 trabalhadores, até 3 lotes, farinha para 1 lote e saldo para a folha inteira: paga 9 e só 3 trabalham; o trabalho das outras 2 equipes se perde no teto do progresso). Na folha parcial nada disso acontece, então a parcial da fazenda custa 8 por hora contra 24 da cheia, com a mesma produção. Opções: (a) manter (esta proposta); (b) pagar sempre só as equipes que rodam (corta a renda dos lavradores; muda muitos hashes); (c) dado: `workers_wanted` múltiplo de `max_batches × workers_per_batch`.

### E. Produzir só com comprador
- Antes de comprar insumos, em cada local com mercado: se para TODO bem de saída o local já tem um lote parado E o mercado não compraria mais um lote (seção 2: a cotação de venda falha ou o caixa do mercado não paga), o local **não tem comprador**: não compra insumos (só a peça de manutenção vencida), não paga folha, não produz, motivo `OUTPUT_FULL` (o motivo existente; nenhum motivo novo, porque o motivo vai no save). Sem equipe, o motivo continua `NO_WORKER`. Ainda tenta vender o que tem (`_sell_surplus`), como antes.
- Volta na primeira hora em que o comprador reaparece (espaço no teto e dinheiro no caixa para um lote, ou o lote parado foi vendido). Local sem mercado: regra não se aplica (comportamento antigo).
- Corrige M3 (o local queima o capital pagando folha para o próprio estoque).

## 4. Invariantes (cada uma é teste)
1. **Dinheiro:** `peek_conservation().ok` em toda hora; nenhum saldo negativo; as regras só chamam `WagePayer.pay` e o `TradeEngine` (nada cria nem destrói moeda).
2. **Folha parcial:** em toda hora, para cada local: total pago = `wage_per_hour × pagos`; os pagos são todos (cheia) ou `k × workers_per_batch` (parcial), com `k` o MAIOR que cabe no dinheiro e `k ≤ B` (insumos e espaço); só as `k` equipes pagas trabalham (os lotes feitos = os das equipes pagas, nunca os das não pagas); `k = 0` ⇒ `NO_FUNDS` e nenhum pagamento. Testes: o de propriedade e os cenários A a E da revisão R3 (`test_d1_…`, `test_m2_m14_…`, `test_m12_…`, `test_m16_…`, `test_d2_…`), que matam os mutantes M2, M12, M14, M16 e os anteriores a D1 e D2 numa cópia.
3. **Bens:** `peek_goods_conservation().ok` em toda hora.
4. **Determinismo:** duas execuções iguais dão o mesmo `state_hash`; salvar e carregar no meio (no meio de uma janela de rodízio) dá o mesmo hash da execução direta (`SimulationRunner`).
5. **Sem estado novo no save:** as chaves do `serialize()` do `ProductionBook` (e de cada local) e as do bloco da economia são as de antes.
6. **Rodízio:** duas fazendas iguais no mesmo povoado, com o teto de compra que só cabe um lote por hora: em 30 dias o número de horas em que cada uma vende difere em no máximo 1 (antes: uma vendia todas e a outra nenhuma, ou quase).
7. **Comprador:** sem comprador (teto cheio OU mercado sem dinheiro para um lote) e com um lote parado, nem folha nem produção nem compra de insumo; com o comprador de volta, produz na mesma hora; com comprador nunca para por E; sem equipe o motivo é `NO_WORKER`.
8. **Nada mascara:** nenhum capital extra, nenhuma folha de hora parada, nenhum comprador ilimitado, critério de sobrevivência e `FoodStub` intocados (o diff não toca `data/` nem o `npc` além do ouvinte).

## 5. A armadilha do `WagesPaid` (decisão)
Hoje o `WagesPaid` é UM por local e hora (`workplace_id`, `amount_each`) e o `npc` alivia a `income` de TODOS os `worker_ids` do local (`peek_site`). Com a folha parcial, quem não recebeu seria aliviado como se tivesse recebido.
| Opção | Impacto | Problema |
|---|---|---|
| (A) o evento leva a lista dos pagos (`paid_worker_ids`, opcional; vazia = todos os do local, o caso dos postos) | 1 campo no evento + 3 linhas no ouvinte; continua UM evento por local e hora (sem laço quente) | muda um evento catalogado (`docs/events.md`) |
| (B) `peek_site` expõe os pagos da última hora | estado transitório novo no livro (fora do save) e campo novo na consulta | depende da ordem de entrega do evento; mais acoplamento |
| (C) "equipe efetiva" = a paga vira a `worker_ids` | nenhuma mudança de evento | muda o save, as vagas e o emprego (demite de fato: contraria DEC-169) |
**Escolha: (A).** É a de menor impacto e a única exata sem estado novo. Na folha cheia a lista também vai preenchida (igual à de `peek_site`, então o alívio não muda); os postos continuam mandando a lista vazia. **Classe 3:** muda o evento `WagesPaid` (catálogo `docs/events.md`, DEC-152). Implementado SÓ neste ramo, como proposta; `docs/events.md` NÃO foi alterado.

## 6. O que é classe 3 (precisa de Arthur)
- As três regras como um todo (balanceamento e design; mudam hashes e referências, rito da DEC-175).
- O campo novo do `WagesPaid` (seção 5).
- A folha parcial relativiza o "tudo ou nada" do local (R8-M1/DEC-169: o tudo ou nada passa a valer POR EQUIPE; ninguém é demitido).
- A pergunta aberta da folha cheia dos excedentes e da equipe ociosa por falta de insumo (seção 3.P).
- **Mudança de significado NÃO listada antes (revisão R3):** `OUTPUT_FULL` passa a significar também "sem comprador" em `peek_site`, na ponte e no painel econômico (LW-108), que hoje o leem como "inventário cheio".
- **Limitação:** conta fechada ou no teto de saldo dentro da equipe é tratada tentando as outras janelas do rodízio; não há teste que a alcance pela porta (a morte tira o trabalhador do local antes de fechar a conta, `economy_module.gd`), então o caminho é coberto só por leitura.

### 6.1 Texto que os documentos protegidos teriam de ganhar (NÃO editados aqui; só com o aceite de Arthur)
- `docs/events.md`, linha do `WagesPaid`, coluna dos campos, acrescentar: "`paid_worker_ids` (lista crescente dos que receberam nesta hora; o local de produção sempre preenche, e na folha parcial só as equipes pagas; vazia = todos os do local de trabalho, o caso dos postos); quem ouve alivia só esses". Coluna de quem ouve: "o `npc` alivia `income` só dos pagos".
- `docs/modules/economy.md`, item "Salário do local" (DEC-151), acrescentar ao fim: "**Folha parcial (LW-094b):** se o saldo não cobre a folha inteira, o local paga o maior número de equipes inteiras (`workers_per_batch`) que cabe e que os insumos e o espaço deixam rodar nesta hora, escolhidas pelo rodízio da hora absoluta; só elas trabalham; sem nenhuma, `NO_FUNDS`."
- `docs/modules/economy.md`, item "Hora a hora", trocar "em ordem de `site_id`" por "na ordem do rodízio pela hora absoluta (começa em `h mod n`, sentido alternado a cada `n` horas)" e acrescentar o passo "(0b) sem comprador (lote parado e o mercado não compraria outro: teto ou caixa), `OUTPUT_FULL` sem comprar, pagar nem produzir".
- `docs/modules/economy.md`, item "Motivo de parada", acrescentar: "`OUTPUT_FULL` também quando não há comprador para mais um lote (LW-094b)".

## 7. Dados e testes afetados (DEC-175)
Preenchida na seção 12 com o resultado real da suíte, do oráculo e dos soaks. Previsão: R muda a ordem em toda hora com `h mod n ≠ 0` (muda todo hash de mundo com economia e produção; não muda testes de livro que chamam `hour_step()` sem hora); P só muda quando um local não cobre a folha inteira; E só quando um local tem lote parado sem comprador.

## 8. Plano de testes e critérios de aceite
- Unidade por regra (`tests/unit/test_supply_rules.gd`): ordem e equidade do rodízio; escolha das equipes; comprador.
- Livro (`tests/unit/test_supply_rules_book.gd`): folha parcial com a lista do evento; E sem comprador/volta; invariantes 1 a 3 em cada hora em cenários aleatórios com semente fixa (saldos, equipes e estoques variados); chaves do save.
- Mundo (`tests/integration/test_supply_rules_world.gd`): duas fazendas iguais (invariante 6); determinismo e salvar/carregar no meio (invariante 4).
- **Aceite (para Arthur):** todas as invariantes verdes; lints limpos; a comparação (seção 11) sem conferência de dinheiro ou de bens falha; a lista DEC-175 completa; nenhum hash regravado.

## 9. Reverter
Cada regra é um commit: reverter o commit da regra (`git revert`) a desliga sem tocar as outras (E e P dependem da hora que R passa a receber; reverter R por último). Nada no save muda, então saves de um lado abrem do outro.

## 10. Riscos e o que NÃO está provado
- As regras sozinhas NÃO fecham a LW-094 (o estudo mediu 50 a 52 vivos sem o stub); falta o sumidouro (estudo, seção 7.3).
- A folha parcial cria uma descontinuidade com a cheia (3.P).
- A equidade do rodízio é por janela de `2n` horas; num horizonte curto pode haver vantagem de 1 hora.
- O passo de várias horas (cadência > 1 minuto) usa a hora de cada hora atrasada (o mesmo `_last_hour`), então a ordem é a mesma; não medido além dos testes.

## 11. Comparação com o comportamento anterior (medição funcional, 23/11/2026)
Método: cópias com `git archive` e `docs/economia/experimentos/preparar_copia.sh`, só `--headless`, `tools/measure_economy --days 30 --seed S --markets`, um processo por vez com `nice`. ANTES = `lw-095-postos` no momento da cópia (`540c35a`, que difere do ponto de partida `6a5da27` deste ramo só em documentos); R = `20b5eb3`; TODAS = `6fc37ae`; P sozinha e E sozinha = `6fc37ae` com as outras duas desligadas por troca de UMA linha na cópia (R: `site_ids()` no lugar do rodízio; E: `has_buyer = true`; P: o laço das equipes vazio). "Sem stub" = `food_stub.json` com `start_stock` 0, `max_stock` 1 e `work_yield` 0 (os 6 postos e a regra da refeição já estão no ramo; SEM os "lotes por trabalhador" e a comida de 30 dias do C do t1 do estudo, então não é o t1). Valores do dia 30 (estado dos 14 locais no instante da medição); dinheiro total 21.520 em todos; `money_ok` e `goods_ok` verdadeiros em TODOS os dias de TODAS as execuções.
| Execução | Vivos d7/d14/d30 | Locais: NO_FUNDS / OUTPUT_FULL / NO_INPUT | Folha (`led_salary`) | Comércio (`led_trade`) | Dinheiro locais / mercados | Comida (mercados + NPCs) |
|---|---|---|---|---|---|---|
| ANTES s1 | 138/138/138 | 13 / 0 / 1 | 17.031 | 23.056 | 44 / 371 | 659 |
| TODAS s1 | 138/138/138 | 4 / 9 / 1 | 16.572 | 23.845 | 181 / 367 | 660 |
| ANTES s2 | 138/138/138 | 14 / 0 / 0 | 18.556 | 25.063 | 33 / 349 | 531 |
| TODAS s2 | 138/138/138 | 5 / 9 / 0 | 16.281 | 22.718 | 183 / 409 | 665 |
| ANTES s3 | 138/138/138 | 13 / 0 / 1 | 18.504 | 22.871 | 45 / 7 | 531 |
| TODAS s3 | 138/138/138 | 5 / 9 / 0 | 17.896 | 24.286 | 186 / 218 | 540 |
| só R s1 | 138/138/138 | 12 / 0 / 2 | 16.997 | 23.518 | 28 / 457 | 653 |
| só P s1 | 138/138/138 | 12 / 0 / 2 | 17.217 | 22.522 | 36 / 287 | 633 |
| só E s1 | 138/138/138 | 5 / 8 / 1 | 16.473 | 24.097 | 210 / 464 | 669 |
| ANTES sem stub s1 | 73/14/0 | (todos mortos) | 14.693 | 35.922 | 35 / 12.817 | 0 |
| TODAS sem stub s1 | 137/32/0 | (todos mortos) | 19.958 | 50.958 | 223 / 13.452 | 0 |
Leitura: com o stub, os vivos não mudam (138). A regra E é a que move o estado dos locais: em vez de 13 a 14 locais quebrados em `NO_FUNDS` no dia 30, 4 a 5 ficam em `NO_FUNDS` e 8 a 9 param SEM comprador guardando o capital (o dinheiro dos locais vai de 33 a 45 para 181 a 210). A folha total cai de 3% a 12% (menos folha paga para estoque sem comprador) e o comércio varia de −9% a +6%. R e P sozinhas mudam pouco no agregado. Sem o stub as regras atrasam o colapso (137 contra 73 no d7, 32 contra 14 no d14) mas NÃO o evitam (0 no d30 nos dois), como o estudo previa (seção 1.4): falta o sumidouro, e o caixa dos mercados (12.817 e 13.452) continua sendo o destino do dinheiro. Saídas: `missao/agente_j/cmp/out_*.csv` no scratchpad da sessão (fora do repositório).

**Refeita depois das correções D1 e D2 da revisão R3 (`704878c`):** TODAS nas sementes 1 a 3, P sozinha, E sozinha e TODAS sem stub na semente 1 (R sozinha não mudou: é o mesmo `20b5eb3`). Os CSVs de 30 dias saíram **idênticos linha a linha** aos da tabela acima (`missao/agente_j/cmp2/`), com `money_ok` e `goods_ok` ok em todos os dias. Causa: nos dados atuais toda receita tem `max_batches_per_hour` = 1, então B ≥ 1 sempre que o local roda e o limite de D1 nunca corta uma equipe; e nenhum local chegou a ter um lote parado diante de um mercado com espaço e sem caixa para um lote. As duas correções só agem fora dos dados atuais (lotes por hora maiores, mercado quebrado), onde os testes de unidade as cobrem.

## 12. Lista DEC-175 (executada no `6fc37ae` e de novo depois das correções da R3, no `704878c` + comentários; NENHUM hash regravado)
| Teste ou hash | Antes (`lw-095-postos`, `540c35a`) | Depois (as três regras) | Por quê |
|---|---|---|---|
| Suíte inteira (`tools/run_tests`) | — | antes das correções da R3: 2.369 testes, 2.361 passando, 0 falhas, 8 pendentes; depois (com o `main` fundido em `96ae515` e as correções): **2.374 testes, 2.366 passando, 0 falhas, 8 pendentes** (testes de ativo de personagem; não conferi se também ficam pendentes no ramo de partida) | — |
| Oráculo (`test_npc_split_oracle.gd`, as 9 impressões, inclusive `real_game` `f9da6f1a8616`) | passa | passa, MESMOS valores | o horizonte do oráculo não chega a uma hora em que a ordem, a folha parcial ou o comprador mudem o estado |
| `tests/soak/run_npc_life_30d` (sem economia) | hash `647c5f4dea03`, 138 vivos | `647c5f4dea03`, 138 vivos | sem economia não há locais de produção |
| `run_npc_life_90d_with_economy` com `LW_SOAK_DAYS=30`, semente 11 (impressão, sem valor fixado em teste) | `035a2e963832`; 13 chegadas de caravana; comida mínima do C 4.536 | `e6cd1cd8a64c` nas três execuções (direta, recarga no dia 15 e recarga em trânsito); 16 chegadas; comida mínima do C 4.516; 138 vivos; 0 problemas | as três regras mudam a ordem das vendas, a folha e as paradas dos locais; o hash igual nas três execuções confirma o determinismo com recarga |
| `test_production.gd`, `test_the_stop_reason_is_published_once_on_the_change_and_the_resume_once_when_it_runs_again` (ADAPTADO, commit `183450a`) | depois do inventário cheio o local vendia ao mercado até o teto e voltava (`ProductionResumed`) | com o mercado no teto e lotes parados ele CONTINUA em `OUTPUT_FULL` (asserção nova, mais forte); volta quando o pão do mercado é consumido | a regra E contradiz de propósito a retomada sem comprador; a asserção da retomada foi mantida, agora com o comprador presente |
Depois das correções da R3 o oráculo, o `run_npc_life_30d` (`647c5f4dea03`, 138 vivos) e o soak com economia de 30 dias, semente 11 (`e6cd1cd8a64c` nas três execuções, 16 chegadas, 138 vivos, 0 problemas) deram os MESMOS valores da tabela. Nenhum outro teste existente mudou. Os testes novos são `tests/unit/test_supply_rules.gd` (o teste do comprador passou a usar "o mercado compraria um lote" no lugar do espaço; mesma força), `tests/unit/test_supply_rules_book.gd`, `tests/integration/test_supply_rules_world.gd` e um teste a mais em `tests/unit/test_wage_income.gd`.
