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
- **Trabalho efetivamente realizado:** a equipe soma a eficiência do local ao progresso do lote nesta hora (`_run_batches`: `progresso += eficiência × equipes que rodam`). É a mesma unidade de trabalho que a folha cheia já pagava; só uma equipe paga trabalha, e toda equipe que trabalha foi paga.
- **Comprador do produto:** o espaço no teto de compra do mercado do POVOADO do local para aquele bem, `buy_cap_of(mercado, bem) − estoque do mercado`. Os outros locais e os NPCs compram do mercado (não do local), então a procura deles aparece como espaço liberado no teto. Não existe comprador fora disso: nada de comprador ilimitado, nenhum outro mercado e nenhum comerciante "presumido".
- **Lote parado:** o local já tem no inventário pelo menos a saída de UM lote (`recipe.outputs[bem]`) que não conseguiu vender.

## 3. As regras (no nível dos métodos)
### R. Rodízio da ordem dos estabelecimentos
- `ProductionBook.hour_step(hour: int = 0)`; a economia passa `h` (`run_production_hour` já recebe `now = h × 60`).
- Ordem da hora (`SupplyRules.rotated_order(ids, h)`): com os `n` IDs em ordem crescente, começa no índice `h mod n` e anda para a FRENTE quando `⌊h ÷ n⌋` é par, para TRÁS quando é ímpar (circular). Em cada janela de `2n` horas, cada local é o primeiro exatamente 2 vezes e, para QUALQUER par de locais, cada um vem antes do outro em exatamente `n` horas (prova: na ida o par troca de ordem em `d` das `n` horas, na volta em `n − d`). Com `h = 0` a ordem é a antiga (testes que chamam `hour_step()` sem hora não mudam).
- Corrige o mecanismo M1 (a 1ª de duas fazendas iguais sempre enche o teto de compra).

### P. Folha parcial por equipe (só quando a folha inteira não cabe)
- Se a folha inteira cabe (`_payer.can_pay` com todos os trabalhadores): **exatamente o comportamento antigo** (DEC-151 e DEC-152): todos recebem, `t` equipes rodam.
- Se não cabe: o local escolhe o MAIOR `k` de 1 a `t` tal que as `k` equipes cabem (`can_pay` com os `k × workers_per_batch` escolhidos: saldo, contas abertas e o teto de saldo de quem recebe). Quem: a lista `worker_ids` (crescente) girada pela hora, começando no índice `h mod trabalhadores`, pegando os primeiros `k × workers_per_batch` (`SupplyRules.rotated_team`). Paga esses, pelo mesmo `WagePayer.pay` (tudo ou nada PARA ESSA LISTA), anuncia UM `WagesPaid` com a lista dos pagos, e roda `k` equipes (`progresso += eficiência × k`).
- `k = 0` (nem uma equipe cabe): `NO_FUNDS`, ninguém recebe, nada roda (DEC-169: parar, sem demitir).
- Com `0 < k < t` o local está **rodando** (motivo vazio): não é `NO_FUNDS`.
- Corrige M2 (`NO_FUNDS` absorvente). Não cria dinheiro: só move o saldo do local para os pagos.
- **Pergunta aberta para Arthur (classe 3, NÃO mudada aqui):** na folha cheia o local paga TODOS os atribuídos, inclusive os que excedem `t × workers_per_batch` (a fazenda de 12 lavradores com 1 lote por hora paga 12 e trabalha com 4). Isso é regra antiga (DEC-151), fora do escopo; na folha parcial só as equipes que rodam recebem, então a folha parcial da fazenda custa 8 por hora contra 24 da cheia, com a mesma produção. Opções: (a) manter (esta proposta); (b) pagar sempre só as equipes que rodam (corta a renda dos lavradores; muda muitos hashes); (c) dado: `workers_wanted` múltiplo de `max_batches × workers_per_batch`.

### E. Produzir só com comprador
- Antes de comprar insumos, em cada local com mercado: se para TODO bem de saída o local já tem um lote parado E o espaço do comprador é menor que a saída de um lote, o local **não tem comprador**: não compra insumos (só a peça de manutenção vencida), não paga folha, não produz, motivo `OUTPUT_FULL` (o motivo existente; nenhum motivo novo, porque o motivo vai no save). Ainda tenta vender o que tem (`_sell_surplus`), como antes.
- Volta na primeira hora em que o comprador reaparece (espaço ≥ saída de um lote, ou o lote parado foi vendido). Local sem mercado: regra não se aplica (comportamento antigo).
- Corrige M3 (o local queima o capital pagando folha para o próprio estoque).

## 4. Invariantes (cada uma é teste)
1. **Dinheiro:** `peek_conservation().ok` em toda hora; nenhum saldo negativo; as regras só chamam `WagePayer.pay` e o `TradeEngine` (nada cria nem destrói moeda).
2. **Folha parcial:** em toda hora, para cada local: total pago = `wage_per_hour × pagos`; os pagos são `k × workers_per_batch` (parcial) ou todos (cheia); o progresso cresce exatamente `eficiência × equipes que rodam` (nenhuma equipe trabalha sem receber, nenhum pago sem equipe rodando); `k = 0` ⇒ `NO_FUNDS` e nenhum pagamento.
3. **Bens:** `peek_goods_conservation().ok` em toda hora.
4. **Determinismo:** duas execuções iguais dão o mesmo `state_hash`; salvar e carregar no meio (no meio de uma janela de rodízio) dá o mesmo hash da execução direta (`SimulationRunner`).
5. **Sem estado novo no save:** as chaves do `serialize()` do `ProductionBook` (e de cada local) e as do bloco da economia são as de antes.
6. **Rodízio:** duas fazendas iguais no mesmo povoado, com o teto de compra que só cabe um lote por hora: em 30 dias o número de horas em que cada uma vende difere em no máximo 1 (antes: uma vendia todas e a outra nenhuma, ou quase).
7. **Comprador:** sem comprador e com um lote parado, nem folha nem produção nem compra de insumo; com o comprador de volta, produz na mesma hora; com comprador nunca para por E.
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
- A pergunta aberta da folha cheia dos excedentes (seção 3.P).

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
