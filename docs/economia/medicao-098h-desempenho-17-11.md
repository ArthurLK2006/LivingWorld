# LW-098h: a medição de DESEMPENHO dos seis comerciantes em release (17/11/2026)

**Status:** medição real autorizada por Arthur ("PODE MEDIR AGORA" e a ordem de concluir a análise e achar a causa), **sem mudar critério de aceite nem dado protegido**. Resultado: **o aceite de desempenho NÃO foi atendido**; as duas otimizações (098h3a e 098h3b) reduziram o custo extra em 20% a 29% e os picos em 69% a 87%, mas **o planejamento comercial (`peek_trade_plans`) é cerca de 91% do custo que resta** e sozinho explica o que falta. A decisão sobre o que fazer a seguir é de Arthur (seção 6).

## 1. Como se mediu (e o que isto NÃO é)
- **O que:** o corredor `tests/soak/run_merchant_emulation` (PRs #119 e #120), **headless, em RELEASE** (binário oficial do Godot 4.7.2, `$HOME/lw-release-probe`), 30 dias de jogo (43.200 passos de 1 minuto), semente 1, 6 comerciantes EMULADOS (2 por povoado) contra a base de 0. Mede o **passo INTEIRO** da simulação (não só a parte do comerciante) e **NÃO tem renderização**: o custo por quadro abaixo é DERIVADO (o passo cai a cada 75 quadros a 1x e a cada 37,5 a 2x).
- **Duas diferenças de preço:** o preço real dos dados (`none`) e a **Q7** da emulação (pão, lã e madeira rotacionados, até 50%: NÃO é a proposta da 098h5, que varia no máximo 30%).
- **Variantes** (cópias DESCARTÁVEIS do `main`, fora do Git, nunca vão para PR): **NOVO** = o `main` atual; **VELHO** = o `main` sem as duas otimizações (reversão dos PRs #124 e #125); **PLAN** = os comerciantes PLANEJAM mas o valor da `haul` é sempre 0 (nunca viajam); **ZERO** = nunca planejam (só o custo dos NPCs a mais). O NOVO e o VELHO dão o MESMO estado (hash `8a437b7b…` no preço real e `6d3a526c…` na Q7: as otimizações não mudam decisão nenhuma), com 30 chegadas e lucro 970 (preço real) e 56 e 2.881 (Q7).
- **Ordem simétrica** (NOVO, VELHO, PLAN, ZERO, ZERO, PLAN, VELHO, NOVO; depois NOVO, VELHO, VELHO, NOVO na Q7) e 20 s de resfriamento para cancelar a deriva térmica; a ociosidade da CPU foi registrada e o roteiro esperava o Mac ficar quieto antes de cada execução.
- **Perfil de energia:** TOMADA (carregando), sem janela; uma leitura de "bateria" apareceu no início de uma execução da primeira rodada (a fonte oscilou) e foi registrada. **NÃO há medição na bateria.**

## 2. Os números (média de 2 execuções; total em segundos, passos acima de 16,7 ms e de 33 ms em 43.200)
| Cenário (preço real) | Total | Mediana | p95 | p99 | > 16,7 ms | > 33 ms |
|---|---|---|---|---|---|---|
| **BASE** (0 comerciantes) | 45,68 | 0,855 ms | 2,36 | 3,56 | 7 | 0,5 |
| ZERO (6, sem planejar) | 48,11 | 0,909 | 2,51 | 3,42 | 2,5 | 0 |
| PLAN (6, planeja sem viajar) | 79,52 | 1,046 | 6,86 | 13,15 | 140,5 | 3,5 |
| **NOVO** (6, otimizações atuais) | **74,26** | 1,073 | 5,27 | 12,46 | **53** | **3** |
| VELHO (6, sem as 2 otimizações) | 81,27 | 1,075 | 6,22 | 14,05 | 172 | 6 |

| Cenário (Q7) | Total | p95 | p99 | > 16,7 ms | > 33 ms |
|---|---|---|---|---|---|
| BASE (0) | 45,92 | 2,47 | 3,51 | 6 | 1 |
| **NOVO** | **70,26** | 4,49 | 10,59 | **37,5** | **2** |
| VELHO | 80,24 | 5,94 | 13,06 | 273 | 15 |

## 3. A causa: o PLANEJAMENTO comercial (preço real)
- **NPCs adicionais:** ZERO menos BASE = **+2,43 s (+5,3%)** (8,5% do custo extra). Os seis NPCs a mais, pensando, comendo e dormindo, quase não pesam.
- **Planejamento e viagem:** NOVO menos ZERO = **+26,15 s (91,5% do custo extra de 28,58 s)**; o planejamento sozinho, sem viagem (PLAN menos ZERO), dá +31,40 s (limite superior: sem viajar o comerciante planeja mais vezes). **A mecânica da viagem e do comércio (partida, chegada, venda) não aparece acima do ruído** (o planejamento absorve praticamente tudo).
- **O custo é concentrado em poucos passos:** a mediana do passo sobe só 0,22 ms (0,855 para 1,073), mas o p99 vai de 3,6 para 12,5 ms: são os passos em que os comerciantes planejam (a cada 10 minutos de jogo nas horas de `haul`).
- **Custo médio extra:** **0,66 ms por passo** (0,56 na Q7); **por quadro**, +0,009 ms a 1x e +0,018 ms a 2x (desprezível na média). **O que pesa são os PICOS:** a 1x (43.200 passos = 15 horas de jogo) são **cerca de 3,5 passos acima de 16,7 ms por hora e 1 acima de 33 ms a cada ~5 horas** (a 2x, o dobro).

## 4. O efeito das otimizações 098h3a e 098h3b (NOVO contra VELHO)
- **Total:** -7,0 s (-8,6%) no preço real e -10,0 s (-12,4%) na Q7; **-19,7% e -29,1% do custo extra**.
- **Picos:** passos acima de 16,7 ms de 172 para 53 (-69%) e de 273 para 37,5 (-86%); acima de 33 ms de 6 para 3 e de 15 para 2.
- **Mesmas decisões:** estado e hash idênticos (as otimizações são exatas).

## 5. O aceite e se o resultado é conclusivo
- **O aceite (9.15.4: nenhum passo acima de 33 ms e no máximo 5 acima de 16,7 ms em 30 dias, LIDO como aumento sobre a base, porque o passo inteiro da base já tem passos acima):** **NÃO atendido.** O aumento sobre a base é de **+46 passos acima de 16,7 ms e +2,5 acima de 33 ms** no preço real, e +31,5 e +1 na Q7. **Os limites não foram alterados.**
- **Carga de fundo.** A **1ª bateria** (8 execuções) rodou com uma atualização do macOS em segundo plano (CPU de 39% a 68% ociosa no preço real e de 77% a 85% na Q7): inflou o total em 3% a 7% e os picos em 1,6 a 2,1 vezes (NOVO no preço real: 79,4 s, 110 e 12,5 passos, contra 74,3 s, 53 e 3 com o Mac quieto); **ela NÃO vale**. A **decomposição** rodou com o Mac quieto (ociosidade de 85% a 91% em 10 das 12 execuções; 61% e 65% nas outras duas).
- **Conclusivo:** (a) **os totais e a decomposição SIM** (os pares de execuções diferem de 0,1% a 2% no total; o NOVO e o VELHO dão os mesmos hashes); (b) **as contagens de passos acima dos limites valem como ordem de grandeza** (variam até cerca de 25% entre repetições; 2 execuções por variante); (c) **os máximos NÃO são conclusivos** (20 a 265 ms, com 3 execuções acima de 100 ms que parecem eventos do sistema).
- **O que NÃO prova:** uma semente só (1); os comerciantes são EMULADOS (os dados reais só entram na 098h5); sem renderização (o quadro é derivado); só o perfil TOMADA; a Q7 varia mais do que a proposta de 30%.

## 6. A decisão que sobra para Arthur
O custo extra está quase todo no planejamento (`peek_trade_plans`), e as duas otimizações exatas já foram aplicadas. Para atender o aceite seria preciso reduzir QUANTAS VEZES os comerciantes planejam ou o custo de cada plano, o que **pode mudar o contrato da economia** (por exemplo, guardar o plano até o preço mudar, a guarda por versão de preço que 9.15.4 deixou de fora por mudar o contrato 9.7). Alternativas: (a) autorizar um estudo e a implementação de uma 3ª otimização que mude o contrato; (b) manter o aceite pendente e a 098h5 parada; (c) aceitar o custo medido (1 passo acima de 33 ms a cada cerca de 5 horas a 1x) com uma decisão EXPRESSA dele. Nada disto foi feito: **nenhum critério e nenhum dado protegido mudou.**

## 7. Dados brutos
Fora do Git: `$HOME/lw-release-probe/merchant_emulation/` (os binários e pacotes de cada variante) e, no scratchpad da sessão, os roteiros e os 24 arquivos de saída (`medicao/02_098h.log`, `medicao/05_decomp.log`, `r_*.txt`, `dec_*.txt`).
