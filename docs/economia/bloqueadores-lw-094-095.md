# LW-094 e LW-095: bloqueadores e dependências (17/11/2026)

Estado: **ORGANIZAÇÃO, não decisão.** Documento de leitura, a pedido de Arthur (17/11/2026): reúne o que já foi medido e escrito sobre o fim do `FoodStub` (LW-094) e do `IncomeStub` (LW-095). **Nada foi medido de novo**; nada aqui remove o `FoodStub`, cria dinheiro ou recurso, regrava hash, dado, teste ou roadmap. Base: `main` `9fd8949`. **[HIP]** = hipótese do projeto, não requisito. Objetivo de Arthur: comerciantes que transportam bens, têm lucro legítimo e abastecem o mundo, **sem mascarar** os problemas estruturais.

## 1. O que cada tarefa é e o estado de hoje
- **LW-095** (roadmap l.784): tira o `IncomeStub` (renda simbólica provisória, `TEMP-LW-066`) e põe salário de verdade: a cada hora em que o local produz, paga os trabalhadores pelo `Ledger` (tudo ou nada, evento `WagesPaid`); cada povoado ganha 2 postos de serviço (6 no total) para guardas e estalajadeiros, com a folha paga pela conta do mercado.
- **Hoje:** as partes a a d (folha dos locais e dos postos: `salary`, `NO_FUNDS`, `WagesPaid`; o `npc` alivia `income`; `PostLoader`) estão no `main` desde 11 e 12/11 (status l.254 e l.260), e a LW-096a (o local sem saldo **para e não demite**, DEC-169) foi aceita em 14/11. **Faltam:** `data/economy/service_posts.json` (não existe; o carregador o trata como opcional), a remoção do `IncomeStub` e a aprovação dos valores novos de oráculo e hash. **Não concluída** (FILA l.24).
- **LW-094** (l.783): tira o `FoodStub` (estoque provisório de comida por povoado, `TEMP-LW-065`); o NPC come do mercado ou do próprio inventário; faltou comida, aparece escassez e **nunca comida mágica**; os 30 dias sem jogador seguem verdes. Dependências do roadmap (LW-093, LW-065, LW-095 só o código do salário, LW-097 com DEC-236): **todas atendidas** (LW-093 e LW-097 aceitas em 14/11; código do salário no `main`).
- **Hoje:** `FoodStub` e `IncomeStub` seguem vivos: 18 arquivos com `TEMP-LW-` (2 de dados, 12 de `src/`, 4 de testes; `rg`, 17/11; `service_post_book.gd` só cita "sem marca"). Pelo roadmap nada impede a LW-094 de começar; **o que a segura é o resultado medido** (seção 2).
- **Destravam** (roadmap l.794, 799, 800, 804 a 806; FILA l.56): LW-104 (escassez; precisa da 094), LW-109 (conservação em soak; precisa de 095, 096 e 098), LW-114 (`check_temp`, que ainda não existe em `tools/`; zero marcas; precisa das duas) e, por elas, LW-110 (soak de 1 ano; precisa de 103, 104 e 109), LW-115 (revisão) e LW-116 (validação e tag `fase-3-concluida`).

## 2. Bloqueadores reais
Tipo: **DADO** = exige autorização de dados (AGENTS 12.5); **CÓDIGO** = muda módulo; **DECISÃO** = regra de jogo. Números de 30 dias e 3 sementes **sem** `FoodStub` vêm do ramo `lw-094a` (só cópia); onde diz `main`, é o jogo de hoje.
- **B1. A comida só existe porque o `FoodStub` a cria fora da economia** [DECISÃO + CÓDIGO + DADO]. Sem ele: 44 vivos no dia 7 e 0 no dia 14; com ele, 132, mas o estoque fica em zero cerca de 80% do tempo (backlog l.153), zera de noite e o pão do mercado de A chega a zero (economy.md 9.15.2; o dia exato não está confirmado no repositório). Fonte: `resultados-30-dias.md`, economy.md 9.15.2, FILA l.55. Decide: Arthur (manter o `FoodStub` é ordem dele, 12 e 14/11).
- **B2. A comida do C dura cerca de 4 dias** [DADO]. Pão 200 e grão 10 para 28 NPCs a 2 pães por dia (o contrato diz 30 dias, DEC-166); os 6.000 provisórios [HIP] escondem isso (ressalva de Arthur na LW-097). No melhor cenário medido (1.600 pães e a regra da folha, não autorizada) o C chega ao dia 30 sem comida e a população cai de 132 para 98 entre os dias 30 e 40. Fonte: diagnóstico Q3, economy.md 9.13 D5, status l.270. Decide: Arthur.
- **B3. A folha é maior que a receita** [DECISÃO + DADO]. No preço de partida 4 de 14 locais dão prejuízo e 2 empatam; 200 de capital cobrem 8 a 19 horas; no dia 1 do `main` 10 de 14 param por `NO_FUNDS`, no dia 7 os 14. Subir saldo, salário ou preço só adia (0 a 12 vivos no dia 30). O que chegou a 132 vivos foi o mercado pagar a folha das horas paradas, que contraria "hora parada = ninguém recebe" (economy.md §6) e **não está autorizado**. Fonte: diagnóstico Q3 e Q5. Decide: Arthur.
- **B4. O dinheiro fica preso nos mercados** [DECISÃO]. No grão (preço 4) o mercado compra a 3 e vende a 5: a diferença tem piso de 1 por lado e nada a devolve; no dia 30 os mercados guardam 89% do dinheiro (média de 3 sementes) e 82% no `main`; `Ledger.burn` nunca é chamado (sumidouros são da Fase 4). O comerciante não resolve isso sozinho e acumula lucro sem sumidouro (9.13 D4 e D7). Fonte: diagnóstico Q2, FILA l.55, economy.md 9.13. Decide: Arthur.
- **B5. Faltam os postos de serviço** [DADO]. Sem `service_posts.json`, os 30 guardas e estalajadeiros não têm renda; era a saída prevista para o dinheiro do mercado. É o dado que falta à LW-095 e **muda hash** (a tarefa PARA e mostra antes, depois e causa; FILA l.56). Postos, lotes e comida do C juntos: 42 a 50 vivos. Decide: Arthur.
- **B6. Cadeias sem comprador final** [DECISÃO]. 52 NPCs (39%: madeira, tábua, minério, metal, ferramenta, lã, tecido) sem renda comem os 60 iniciais em cerca de 3 dias e levam a produção de comida junto (`NO_WORKER`). Nenhuma combinação só de dados passou de 50 de 132 vivos (a premissa "só dados" da LW-112 está em risco); a "procura final" testada foi inconclusiva. Fonte: diagnóstico Q3 e Q5, economy.md 9.13 D3. Decide: Arthur.
- **B7. Sintoma comum: 0 de 14 locais de produção rodando no dia 30** (consequência de B3, B4 e B6). Com o `FoodStub` (todos parados desde o dia 7, medição de 14/11) e sem ele (0 a 1 nos melhores cenários): 132 vivos não provam economia sustentável. Ameaça o aceite da LW-094 ("30 dias verde") e a LW-110 ("sem escassez crônica"). Fonte: status l.270, FILA l.55, diagnóstico Q5.
- **B8. HIPÓTESE a CONFIRMAR: o consumo de comida pode estar inflado** [CÓDIGO ou DADO]. O bloco `eat` de 1 hora da agenda gera até 3 refeições seguidas: cada `eat` de 20 minutos consome 1 unidade mesmo com a fome em 0 (no teste A2 os 3 pães saem às 12:31, 12:51 e 13:11); se valer para todo NPC, o consumo (inventário e `FoodStub`) pode ser até 3 vezes o previsto. **Nada foi mudado.** Onde olhar: `data/actions.json` (`eat`, 20 min), `data/action_effects.json` (`eat_hunger`, -60), `data/action_conditions.json` (`eat_has_food`), `data/routine_blocks.json` (blocos `eat` de 1 h, três por dia), `NpcThinker` (`_routine_action_id`, `_candidates`), `ActionRunner` (l.260), `NpcTrade` (l.159), `FoodStub.request_consume`. Mudar isso muda resultados e hashes. Fonte: PR #123, `tests/unit/test_npc_merchant_food.gd` l.225-237. Decide: Arthur (mandar investigar na LW-094).
- **B9. O laço do pensador, `buy` contra `eat`** [CÓDIGO + DECISÃO]. A `buy` ignora a comida já na mochila e `plan_food` ignora a capacidade: o `npc` 151 morreu de fome com 120 pães e 505 moedas. A correção localizada no comerciante é a 098h0 (PR #122, aberto; 9.15 D5); a correção GERAL foi reservada por Arthur à LW-094: hoje é benigna (0 mortes em 30 dias) mas frequente (223 escolhas de `buy` com comida na mochila, 11% das compras) e **muda** o `measure_economy` em 30 de 31 dias (`led_trade` +4,0% no dia 30) e os hashes diários. Fonte: economy.md 9.15.0 e 9.15.2. Decide: Arthur.
- **B10. Referências e hashes (DEC-175)** [DECISÃO]. O roadmap põe a LW-095 no marco 2 e a LW-094 no marco 3 de hash (DEC-236), mas Arthur já aprovou esses marcos em 14/11 sem os postos e sem o fim do `FoodStub`. Desde a LW-098, valor já aprovado que mude faz a tarefa PARAR e mostrar antigo, novo e causa. A 098h5 também muda (132 para 138 NPCs, 9 impressões do oráculo, hash de 30 dias; o `run_sim` não). Fonte: status l.270, `docs/operacao/PACOTE_ACEITE_1.md`, DEC-175 e DEC-236. Decide: Arthur.
- **B11. Dados e save protegidos** [DADO]. `data/` fora do escopo da tarefa é protegido (AGENTS 12.5): a LW-095 cria `service_posts.json` e apaga `income_stub.json`; a LW-094 apaga `food_stub.json` e pode mexer em `market_targets.json`; tirar o `FoodStub` **muda o formato do save** (o estoque entra nele; backlog l.108; AGENTS 16.2). Decide: Arthur (autorização de dados).
- **B12. Preços iguais no dia 0** [DADO]. 28 dos 30 pares (mercado, bem) começam com estoque igual ao alvo: 0 de 60 pares bem × rota dão lucro (medição anterior, não refeita). A 098h5 propõe diferenciar até 6 pares, no máximo 30% (9.15 D4, aprovado só como limite de planejamento). Fonte: diagnóstico Q1, economy.md 9.13 D2. Decide: Arthur (valores na 098h5).

Por tipo: **DADO** B2, B5, B11, B12; **CÓDIGO** B8 (se a causa estiver no `npc`) e B9; **DECISÃO** B1, B3, B4, B6, B10 (B7 é consequência).

## 3. Dependências e ordem proposta (proposta; Arthur decide)
```
no main: 098h0a (#119, #120) · 098h1 (#117) · 098h4 (#118) · 098h2 (#123) · 098h3a (#124)
em PR:    098h0 (#122) · 098h3b (#125, otimização 2)      condição: 098h1 a 098h4 no main, CI verde
        v
098h5 ATIVAÇÃO: PARA antes. Precisa de A1 (dados: population, places, market_targets/initial_stock) e A2 (testes
        |       132 -> 138 e referências). Mostra valor antigo, novo, causa, preços (9.15 D4), desempenho e reversão.
        v
098h6 NOVA MEDIÇÃO: 30 dias x 3 sementes, antes e depois, em 4 registros separados (seção 6)
        v
AVALIAÇÃO DE ARTHUR: decide B1 a B12 (ponto de reavaliação 1 da FILA)
        v
LW-095 (postos + fim do IncomeStub) -> LW-094 (fim do FoodStub; correção geral do pensador, se autorizada)
        |   cada uma precisa de: autorização de dados, DEC-175 (antigo, novo, causa), aprovação dos hashes, testes
        v
LW-114 · LW-104 (precisa da 094) · LW-109 (precisa da 095, 096, 098)  ->  LW-110 (precisa também da 103)
        v
LW-115 (precisa também de 113, 108, 101)  ->  LW-116 (validação e tag fase-3-concluida)
```
- **Testes que mudam.** 098h5: `EXPECTED_POPULATION`, os testes com 132 (`rg -n '\b132\b' tests`), `test_npc_split_oracle.gd`, o hash do soak de 30 dias, mais o novo `test_merchant_world.gd`. LW-094 e LW-095: os testes com marca `TEMP-LW-` (`test_food_stub.gd`, `test_income_stub.gd`, `test_npc_setup.gd`, `test_npc_split_oracle.gd`) e as referências; a lista exata sai da tarefa e só com autorização.
- A recomendação D6 de economy.md 9.13 (LW-094 **antes** da 098h) foi superada pela ordem de 17/11 (098h primeiro): por isso a LW-094 vai mudar valores já aprovados e PARA para pedir aprovação.
- Fora desta lista, mas no mesmo problema (`OUTPUT_FULL`): LW-103 e LW-100, ainda sem ordem (FILA l.21; pontos de reavaliação depois da 098, da 103 e da 100, l.56).

## 4. O que a 098h resolve e o que NÃO resolve sozinha
**Resolve** (números já obtidos):
- O comércio entre povoados existe: 6 comerciantes emulados, semente 1, 30 dias, preços reais: 27 chegadas e lucro de 1.207, 6 de 6 vivos, dinheiro e bens conservados (PR #124); com a diferença de preços Q7 (emulada): 48 chegadas e 3.175.
- A morte do comerciante emulado **era defeito do pensador** (B9), não da economia: com a 098h0, 3 de 3 vivos nas sementes 1 a 3 em 10 dias (pior fome crítica 11,5 h, semente 3; o limite de Arthur é 24 h) e 6 de 6 em 30 dias (PR #122).
- Ferramentas: verificador de NPC travado (098h1), 6 colunas `merchants_*` no medidor (098h4), testes "nada de comida infinita" (098h2) e a otimização 1 (098h3a).

**NÃO resolve:**
- O abastecimento de comida em A e C: a hora em fome crítica que sobra (79 a 93%) é `eat` bloqueada por falta de comida NO POVOADO (mochila vazia, `FoodStub` zerado de noite, pão de A em zero), visível de propósito (9.15 D1: sem comida grátis).
- B3 a B7: Arthur aceitou que a 098h "não precisa resolver sozinha a sustentabilidade" (9.15 D3); a melhora é relatada, não exigida.
- Custo: 6 NPCs a mais custam +14% a 15% do soak de 30 dias só por existirem (mesmo com custo de plano zero) e +52,8% com o planejador (release 42,92 para 65,58 s; economy.md 9.15.4). A base sem comerciantes já tem 2 passos acima de 16,7 ms e 1 acima de 33 ms: a regra de aceite (no máximo 5 e nenhum; DEC-119) lê-se como **aumento sobre a base** (PR #120). Medições reais em release só com o "PODE MEDIR AGORA" dele (ordem no chat; não achei em documento do repositório).

## 5. O que NÃO se pode fazer sem autorização de Arthur
- Remover ou alterar o `FoodStub` e o `IncomeStub` fora da LW-094 e da LW-095 e antes da ordem dele.
- Criar dinheiro, subsídio, salário artificial, comida grátis, teleporte ou qualquer recurso artificial (Q9; economy.md 9.15 "O que NÃO entra").
- Regravar hash ou valor de referência (oráculo, hash de 30 dias, `tests/fixtures/`), nem "automaticamente".
- Tocar dados protegidos (`data/` fora do escopo) e os arquivos protegidos (AGENTS 12.5).
- Alterar o pensador do NPC comum (correção geral) e mexer no consumo de comida (B8).
- Reformulação econômica ampla: folha das horas paradas, tributo ou sumidouro, `PriceMath`, spread, salário, preços definitivos.
- Ativar os comerciantes no jogo real (098h5) e medir em release ou benchmark.

## 6. Decisões que dependerão dele e o que medir depois da 098h
Decisões (só a lista): (1) aprovar ou não a 098h5 (dados, estoques, preços D4, 132 para 138, hashes novos); (2) a ordem da LW-095 e da LW-094, e se esperam a LW-103 e a LW-100; (3) a saída para o dinheiro preso (B4): postos, folha das horas paradas, tributo ou outra; (4) os 6 postos de serviço e seus valores [HIP]; (5) o que fazer com os 52 NPCs de cadeias sem comprador final (B6); (6) o estoque de comida do C no lugar dos 6.000 provisórios (B2); (7) a correção GERAL do pensador, com a LW-094 e a remedição (B9); (8) mandar investigar as "3 refeições seguidas" (B8) e, se confirmar, se a correção é dado ou código; (9) sumidouro e limite de capital do comerciante (9.13 D7), antes ou na Fase 4; (10) a troca do formato do save e dos hashes quando a LW-094 e a LW-095 chegarem (B10, B11).

**Pendências de coerência** (roadmap protegido, não tocado): (a) a LW-094 pede "30 dias verde com a economia real" e o ramo sem `FoodStub` tem 0 vivos no dia 14: o aceite só fecha com decisões de B3 a B6; (b) LW-094 e LW-095 estão nos marcos 3 e 2, já aprovados (B10); (c) o comentário de `service_post_book.gd` l.6 contém `TEMP-LW-` sem número: o `check_temp` (LW-114) pode acusá-lo (a conferir).

**O que medir** (`tools/measure_economy --days 30 --seed S`, S = 1, 2, 3; antes e depois dos dados da 098h5; dias 0, 10, 20 e 30; só `--headless`), em registros SEPARADOS (9.15 D3):
- **Alimentação:** `food_market_*`, `food_npcs_*`, `alive`, `alive_a|b|c`, mortes e horas em fome crítica.
- **Produção:** `made_*`, `used_*`, `sites_running`. **Comércio:** `led_trade`, `merchants_trips`, `merchants_profit`, `merchants_alive|travelling|held`.
- **Renda:** `money_npc_alive`, `money_market`, saldos e a folha (`led_*`); mais `pmax_*`, `pmin_*`, `problems`, `money_ok`, `goods_ok` e o custo dos 6 NPCs.
- **Faltam** (decisão da 098h6): `merchants_balance`, `merchants_dead`, `merchants_critical` e as HORAS em fome crítica (`critical_since` não sai da API: amostrar de hora em hora ou campo novo no `npc`).
- **Para a LW-094 e a LW-095:** repetir, só em cópia, `base` e `est_postos_lotes_c` do ramo `lw-094a` COM comerciantes (FILA l.56) e contar refeições por NPC e por dia (B8; a conferir se alguma coluna já mostra).

## 7. Fontes (somente leitura)
- `docs/DEVELOPMENT_ROADMAP.md` (protegido) l.783-784, 786-788, 794, 799-800, 804-806, 1560-1561 e a nota do Anexo D (TEMP); `docs/ROADMAP_STATUS.md` l.3, 254, 260, 270.
- `docs/economia/diagnostico-economico-12-11.md` (Q1 a Q5) e `docs/economia/experimentos/resultados-30-dias.md`.
- `docs/modules/economy.md` 9.13 (l.272-283), 9.15.0 (l.303), 9.15.2 (l.310-317), 9.15.4 (l.321), 9.15.5 (l.322, 325), 9.15.6 (l.337-338), 9.15.7 (l.340-342).
- `docs/operacao/FILA.md` l.21, 24, 54-57 e `PACOTE_ACEITE_1.md`; `docs/backlog.md` l.108, 153, 264; `docs/DECISIONS.md` DEC-166 (l.2510), 169 (l.2552), 175 (l.2636), 236 (l.3490); `AGENTS.md` 12.5 e 16.2.
- PRs: #117, #118, #119, #120, #123 e #124 (no `main`); #122 e #125 (em PR no momento da escrita; o estado vale o do GitHub).
- Código e dados: `data/{actions,action_effects,action_conditions,routine_blocks,needs}.json`, `src/sim/npc/{decision/npc_thinker,actions/action_runner,trade/npc_trade,food/food_stub}.gd`, `tests/unit/test_npc_merchant_food.gd`.
