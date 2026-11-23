# Experimento H-K: uma taxa pequena em `rest` paga ao caixa do mercado (resultado, 23/11/2026)

**Estado: DESCARTADO por Arthur em 23/11/2026** (não resolve a causa estrutural; só adia o colapso e prejudica alguns grupos de NPCs). **Nada foi implementado no repositório**: o experimento rodou só em CÓPIAS descartáveis do `main` em `10f3a33`, com autorização dele, sem tocar saves oficiais, contratos protegidos nem hashes de referência. Este documento só guarda o resultado. A hipótese vinha de [analise-demanda-final-lw103-x-sexta-necessidade.md](analise-demanda-final-lw103-x-sexta-necessidade.md), seção 6; o canal que ela tentava abrir está estudado em [estudo-retorno-do-dinheiro-23-11.md](estudo-retorno-do-dinheiro-23-11.md).

## 1. O que foi feito
- **A hipótese (H-K):** cobrar uma taxa inteira pequena por uma atividade comum, paga pelo NPC ao caixa do mercado do povoado (a conta que paga os 6 postos de serviço), daria destino à sobra guardada pelos portadores dos postos (guardas e estalajadeiros ganham 24 por dia e gastam uns 15 em comida), sem mudar o save e sem criar moeda. Critério da análise: nos dias 20 a 30 o caixa dos mercados cai menos de 50 por dia, o dinheiro dos NPCs vivos sobe menos de 50 por dia e as conferências de dinheiro e bens dão ok.
- **A cópia:** cerca de 25 linhas de jogo. O NPC que conclui a ação escolhida paga a taxa ao caixa do mercado pelo `Ledger` (tudo ou nada; sem saldo, a ação segue sem cobrança e a recusa é contada). Sem estado salvo novo, sem sorteio, sem relógio. A taxa e a ação vinham do ambiente (taxa 0 = sem H-K, idêntico à base: conferido em 83 colunas).
- **A ação:** contadas num curto teste, `talk` dá cerca de 350 conclusões por dia (quem faria quase todas seriam lavradores e os demais ofícios) e `rest` cerca de 135. Escolhida `rest`, **taxa 3** (cerca de 400 moedas por dia no 1º dia); `talk` com taxa 1 daria a mesma faixa, mas cobraria justamente de quem morre sem renda. Segundo valor (taxa 6) só no cenário com `FoodStub`.
- **Cenários:** S-A = o jogo real, COM `FoodStub`, semente 1, 30 dias; S-B = SEM `FoodStub` (`start_stock` 0, `max_stock` 1, `work_yield` 0, como na medição do LW-094b), semente 1, 60 dias, mais um par na semente 2. Grupos: P = guarda e estalajadeiro, F = lavrador, O = demais ofícios, M = comerciante.

## 2. S-A, COM `FoodStub`, semente 1, 30 dias (base | H-K `rest` 3)
| dia | vivos | mercados (a+b+c) | dinheiro de P | F | O | M | salário dos postos (720 = 6/6) | taxa do dia (recusas) | locais rodando |
|---|---|---|---|---|---|---|---|---|---|
| 1 | 138 \| 138 | 8145 \| 8474 | 2137 \| 2111 | 3144 \| 3120 | 4990 \| 4792 | 1837 \| 1756 | 720 \| 720 | 0 \| 399 (0) | 1/14 \| 1/14 |
| 7 | 138 \| 138 | 6366 \| 8989 | 4795 \| 4179 | 2884 \| 2772 | 4546 \| 3472 | 2048 \| 1272 | 720 \| 720 | 0 \| 351 (16) | 0 \| 2/14 |
| 14 | 138 \| 138 | 4998 \| 7726 | 6635 \| 7414 | 2828 \| 2575 | 4602 \| 2663 | 2074 \| 769 | 384 \| 720 | 0 \| 297 (42) | 0 \| 0 |
| 20 | 138 \| 138 | 2791 \| 6629 | 8939 \| 9550 | 2828 \| 2443 | 4602 \| 1994 | 2074 \| 608 | 384 \| 512 | 0 \| 243 (48) | 0 \| 0 |
| 30 | 138 \| 138 | 367 \| 4549 | 11427 \| 12835 | 2828 \| 2224 | 4610 \| 1288 | 2107 \| 432 | 192 \| 462 | 0 \| 156 (80) | 0 \| 0 |

- Ninguém morre nos dois lados. Postos pagando no dia 30: 2 de 6 na base e 4 de 6 com o H-K; o caixa dos mercados zera no dia 14 na base e no dia 20 com o H-K.
- Produção e comércio iguais: pão 828 \| 816, farinha 1718 \| 1718, grão 562 \| 578, `led_trade` 23845 \| 24844. Locais parados no dia 30: `NO_FUNDS` 4 \| 5, `OUTPUT_FULL` 9 \| 9, `NO_INPUT` 1 \| 0.
- **Os dois critérios da análise FALHAM:** nos dias 20 a 30 o caixa dos mercados cai 204 por dia (base: 255; o critério pedia menos de 50) e o dinheiro dos vivos sobe 213 por dia (base: 265; pedia menos de 50). Com a taxa 6 fica pior (−289 e +299; o valor cobrado cai a 228 por dia porque O e M já não têm saldo, com cerca de 1.000 recusas por grupo em 30 dias).

## 3. S-B, SEM `FoodStub`, semente 1, 60 dias (base | H-K `rest` 3)
| dia | vivos (P/F/O/M) | mercados | dinheiro dos vivos | dinheiro preso nos mortos | salário dos postos | taxa |
|---|---|---|---|---|---|---|
| 1 | 138 \| 138 | 9491 \| 9824 | 10850 \| 10517 | 0 \| 0 | 720 \| 720 | 0 \| 333 |
| 7 | 137 (30/40/61/6) \| 136 (30/40/60/6) | 14493 \| 16200 | 6180 \| 4104 | 8 \| 5 | 720 \| 720 | 0 \| 237 |
| 14 | 32 (21/5/4/2) \| 40 (30/4/4/2) | 15496 \| 17600 | 1564 \| 3373 | 4062 \| 139 | 504 \| 720 | 0 \| 108 |
| 20 | 20 (16/0/4/0) \| 14 (12/0/2/0) | 14508 \| 16508 | 1747 \| 897 | 4926 \| 3784 | 384 \| 299 | 0 \| 30 |
| 30 | 0 \| 8 (8/0/0/0) | 13452 \| 16506 | 0 \| 132 | 7845 \| 4682 | 0 \| 192 | 0 \| 24 |
| 45 | 0 \| 0 | 13561 \| 16162 | 0 \| 0 | 7845 \| 5251 | 0 \| 0 | 0 \| 0 |
| 60 | 0 \| 0 | 13610 \| 16211 | 0 \| 0 | 7845 \| 5251 | 0 \| 0 | 0 \| 0 |

- A base confere com a medição do LW-094b: 137, 32 e 0 vivos nos dias 7, 14 e 30. **Todos os 138 morrem nos dois lados:** o último vivo vai até o dia 28 na base e até o 37 com o H-K (semente 2: zero no dia 30 contra o 40). Pessoas-dias vividas: 1692 \| 1775 (+5%). O tempo a mais é de 8 a 10 portadores dos postos; F e O morrem até cerca do dia 14 nos dois lados (com o H-K os O morrem antes: 8 contra 13 no dia 10).
- Comida no mercado: zero no fim, nos dois lados. Os portadores morrem COM dinheiro (5.360 na base, 3.317 com o H-K, presos nos mortos) e o caixa dos mercados **cresce**: sem o `FoodStub`, o dinheiro sobra e o que falta é comida.

## 4. O dinheiro cobrado volta aos NPCs que precisam? (condição 5 de Arthur)
**Não.** No S-A (30 dias, H-K menos base):
- Quem pagou os 8.631 de taxa: P 2.649 (31%), O 3.336 (39%), M 1.968 (23%) e F 678 (8%). As 1.238 recusas vêm quase todas de O e M; P teve 8.
- Para onde foi: caixa dos mercados +4.182; salário dos postos +5.674, que por construção vai só a P; o salário dos locais não mudou (F 952 contra 920, O 2.634 contra 2.650); o mercado não comprou mais dos locais (os 14 locais param até o dia 14 nos dois lados).
- Saldo final por grupo: P +1.408, O −3.322 (−72%), M −1.675, F −604, mercados +4.182, locais +11; a soma dá 0.
- A taxa tira dinheiro de O, M e F e o leva aos mercados e a P; **não volta a quem vive dos locais**, e a sobra guardada de P (cerca de 280 por dia: 2.137 no dia 1, 12.835 no dia 30) não foi tocada. No S-B o efeito é o mesmo.

## 5. Conservação, determinismo e save
- `money_ok` e `goods_ok` deram 1 em todos os dias das 8 rodadas, com `problems` 0; o dinheiro total ficou em 21.520, constante.
- Duas execuções iguais do H-K deram CSV idênticos. O save antigo do `main` carrega na cópia (`load_ok true true`); gravar e ler no mesmo build deu hash igual.
- O `serialize()` não ganhou chave no topo, mas `ledger.moved` ganhou a entrada de um motivo novo (`activity_fee`): **um save feito com o H-K seria recusado pelo build oficial** ("Ledger.load_from: 'moved' tem a entrada 'activity_fee' inválida"). Se alguma variante com motivo novo voltar a ser considerada, isto precisa de decisão de save (AGENTS.md, item 15, contra DEC-127).

## 6. Conclusão: adia, não resolve
- **Caixa dos mercados (S-A):** a queda fica mais lenta, mas não para; o mercado zera 6 dias depois e há 2 postos a mais pagando no dia 30. É adiamento.
- **Postos:** ficam pagos por mais tempo só enquanto houver O e M com saldo para cobrar; quando acaba, as recusas sobem.
- **Sobra guardada:** não resolve; quem guarda é P, que paga só 31%.
- **S-B:** adia 9 a 10 dias, só para os últimos 8 a 10 portadores dos postos; a causa ali não é dinheiro, é comida, e os locais param por falta de trabalhador depois das mortes.
- **O que NÃO muda:** quem morre sem renda (F e O); os locais parados (`OUTPUT_FULL` ou `NO_FUNDS` no S-A, `NO_WORKER` no S-B); a produção de comida; o dinheiro preso nos mortos.

## 7. O efeito vem do canal, não da cobrança
- O que o experimento mexeu foi o **canal**: dinheiro voltando ao caixa que paga os postos. A cobrança em si só piora a distribuição, porque não escolhe quem acumula e atinge quem já tem pouco (em linha com a orientação de Arthur: não transformar conversar ou descansar em cobrança artificial só para equilibrar a economia).
- Mesmo pelo canal certo, o H-K fecha só o circuito curto portador do posto, mercado, portador do posto. O circuito que falta é o mercado comprar dos locais, os locais pagarem F e O, e F e O comprarem do mercado.
- O canal mais coerente, sem implementar: **demanda final dos NPCs com saldo por bens produzidos pelos locais parados** (na linha da LW-103), ou o mercado comprar com dinheiro existente do produtor que tem lote parado (canal C3 do [estudo do retorno do dinheiro](estudo-retorno-do-dinheiro-23-11.md); medido em outro experimento). Nenhum canal de dinheiro resolve o S-B: sem comida produzida, não há dinheiro que baste.

## 8. O que NÃO foi verificado
Suíte de testes, lints e `check_architecture` na cópia; a semente 2 no S-A; `talk` como ação alternativa (só contada); a taxa 6 no S-B; o S-A além de 30 dias; a hora exata da 1ª morte (a medição é por dia: no S-B a 1ª morte é no dia 7 nos dois lados); a causa de cada morte individual; os hashes de referência oficiais.
