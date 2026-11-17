# LW-098h: o gargalo do planejamento comercial e a 3ª otimização, análise ISOLADA (17/11/2026)

**Status:** análise feita numa CÓPIA (ramo local, sem commit, PR nem push); **nenhum contrato, dado protegido ou critério de aceite mudou**. Só depuração (contagens e frações de tempo): **o ganho em release é EXTRAPOLAÇÃO** (a medição de tempo é do Maestro, numa janela quieta, depois de uma decisão de Arthur). Pedido de Arthur (17/11/2026): concluir a análise do gargalo e avaliar a 3ª otimização em ambiente isolado, sem alterar o contrato econômico sem autorização. Base: `docs/economia/medicao-098h-desempenho-17-11.md` (o planejamento é ~91% do custo extra).

## 1. Onde está o custo que resta (6 comerciantes, preço real, 30 dias)
- **9.816 chamadas de planejamento** (`peek_trade_plans`), **98,8% SEM plano**, 54,5 por comerciante-dia, quase todas de `haul_value` (9.772; as outras 44 são `complete`). Entre os 196.320 candidatos (bem x destino): **29,4%** não têm lote possível (nenhuma cotação), **61,6% morrem na pré-checagem** (4 cotações cada; 20% do tempo) e **9,1% sobrevivem e levam 78,5% do tempo** (77% deles ACHAM uma quantidade com lucro e só reprovam depois nos limiares).
- **Por fase do planejador:** pré-checagem 23,4%, busca binária do saldo 10,5%, **varredura de `q*` 61,8%** (78,6% dos passos de `price_at`: custo QUADRÁTICO, porque recota as q unidades a cada q), plano final 1,7%, o resto 2,5%. O caminho, as rotas e o risco são só 1,1%; **87,3% do planejador está dentro de `engine.quote`** (cerca de 12 µs fixos mais 2 µs por unidade).
- **Os picos:** o 1% de passos mais caros tem 86% de planejamento e 2,9 chamadas por passo.

## 2. Quanto desse cálculo se repete
- A **mesma entrada da chamada anterior do mesmo comerciante** em **83,2%** das chamadas (79,3% na Q7); por candidato, 90,5% (88,3% na Q7), cerca de 91% (87%) do tempo. A impressão mínima EXATA tem 12 campos por candidato (saldo e peso livre do comerciante; estoque, preço e estoque de referência da origem e do destino; saldo do mercado de destino; os trechos); **o relógio NÃO entra**; ler custa ~2,4% de uma chamada. Uma guarda por CONTADORES de versão acertaria menos (76,6% global, 83,2% por dono) e é mais invasiva.

## 3. Os candidatos (todos com 0 divergência em 9.816 chamadas e os 30 hashes diários, o ROW e o TOTAL IDÊNTICOS no preço real; a Q7 só em 2 combinações)
| Candidato | Cotações | `price_at` | Tempo de planejamento (cand/base) | Linhas | Contrato |
|---|---|---|---|---|---|
| **C1** reaproveitar a 1ª unidade e o `upper` entre a pré-checagem e a busca | -32,9% | -4,2% | 0,893 | +36 -6 | interno, exato |
| **C2** memoizar TODAS as cotações dentro de uma chamada | -43,9% | -25,4% | 0,742 | +36 -6 | interno, exato |
| **C6** a **curva de cotações** (`TradeEngine.quote_curve`: uma passada por lado em vez de recotar) | -57,4% | -87,0% | 0,314 | +68 -15 (4 arq.) | interno, exato; **toca a redação de `economy.md` 9.5 ("a única porta é `quote`") e 2 testes** |
| **C3** guarda por impressão CALCULADA (`PlanGuard`, novo) | -85,4% | -85,3% | 0,173 | +40 -3 (4 arq.) | **sem `serialize`, evento nem API; mas é ESTADO PRIVADO NOVO no `EconomyModule`, e 9.15.4 tratou a guarda por versão como mudança de 9.7: PRECISA da autorização de Arthur** |
| **C6 + C2** (sem estado) | -82,6% (Q7 -79,5%) | -90,2% | 0,218 (Q7 0,236) | +104 -21 | interno, exato |
| **C6 + C2 + C3** | -97,1% (Q7 -95,8%) | -98,6% | 0,061 (Q7 0,081) | +144 -24 (7 arq.) | o do C3 |
| C7 `settlement_of` O(1) | igual | igual | 1,008 | | **ganho NULO hoje** (só prepara mais povoados) |
| C4 encurtar a varredura | | | | | **não recomendado** (o `ceil` do risco e da tarifa e o teto do saldo exigem folga; depois da C6 a varredura é só aritmética) |
| C5 um plano por bloco `haul` | ~9.816 para ~400 chamadas (-96%) | | | | **NÃO é exata** (muda quando partem, as chegadas e os hashes): só com decisão de Arthur |
O modo da prova foi PAREADO (cada chamada roda o candidato e o planejador original em ordem alternada; o controle, original contra original, deu razão 1,006 e 0 divergência).

## 4. A recomendação e o que se espera em release (por conta; a razão varia cerca de ±30%)
- **Melhor combinação EXATA SEM estado novo: C6 + C2** (planejamento -78%): o soak de 30 dias iria de **74,26 s para ~54 s** (52 a 56), contra a base de 45,68 s. **Com a C3: ~49,7 s** (49 a 50), +8,8% sobre a base (sobram só os NPCs a mais, +2,43 s). **Picos** (depuração, extrapolação): 0 a 1 passo acima de 16,7 ms e 0 acima de 33 ms sobre o piso de ruído, **dentro do aceite (+5 e 0, lido como aumento sobre a base) nas duas combinações**.
- **Não sobra decisão de COMPORTAMENTO nem de 9.7** com C6 + C2; sobram a decisão sobre a C6 (redação de 9.5 e 2 testes) e a sobre a C3 (estado novo) e **a medição em release (do Maestro)**.

## 5. Testes e lints (cópia limpa com tudo, sem a sonda)
14 testes existentes de economia, caravana e `npc_merchant` e o oráculo (2/2) passam; `test_trade_planner` passa 14 de 16 com a C6 (C1 e C2: 15 de 16; C3 e C7: 16 de 16). **Os 2 que falham contam a IMPLEMENTAÇÃO, não o comportamento:** `test_the_precheck_spares_the_balance_search` (conta 8 chamadas a `engine.quote`; a memória e a curva as reduzem) e `test_the_precheck_keeps_what_the_search_finds_behind_a_first_unit_that_loses_money` (o `ScriptedEngine` só intercepta `quote`; a curva o contorna). **Nenhum teste foi alterado**; adaptá-los sem enfraquecer a asserção é parte da tarefa de implementação. `check_architecture`, `check_literal_text`, `check_content_ids` e `check_input_keys` verdes. **Não feito:** release; `check_gdscript_warnings`; os testes NOVOS que a implementação exige (a curva igual a `quote` para todo q; a guarda invalidando cada entrada); a Q7 por candidato isolado; mais de uma semente (a prova pareada vale para os estados atingidos nestes 30 dias).

## 6. A decisão que sobra para Arthur
Implementar de verdade (tarefa 098h3c, classe 2 ou 3, com as MESMAS condições das 098h3a e 098h3b: decisões e hashes idênticos, revisão independente e CI) **C6 + C2** (sem estado, toca a redação de 9.5 e 2 testes que contam implementação), **com ou sem a C3** (estado privado novo, a maior reserva, 83% a 90% das chamadas se repetem; é a que mais se alinha à diretriz de "calcular por mudança relevante"), e **depois** a medição em release numa janela quieta. Alternativas: aceitar o custo medido; manter a 098h5 parada. **Nada disto foi feito.**

## 7. Dados brutos
Fora do Git: `$HOME/lw-release-probe/analise_otim3/` (os diffs `cand_*.diff` sobre o `main` `fad1028`, as tabelas `q1q2_tables.txt` e a sonda), e o scratchpad da sessão (`h3c/`).
