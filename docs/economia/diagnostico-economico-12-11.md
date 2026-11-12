# Diagnóstico econômico da Fase 3 (12/11/2026)

Estado: **ANÁLISE, não decisão.** Não altera regra, dado ou contrato: os cenários rodam em CÓPIAS exportadas com `git archive`. Números do jogo real (`start_default_game`), medidos por `tools/measure_economy`; fluxos do livro-razão por `experimentos/fluxos.gd.txt` (só na cópia). Referências: `main` 329b0f7 (com FoodStub) e o ramo `lw-094a-fim-do-foodstub-codigo` 8c47b4c (sem FoodStub, o estado-alvo). **[HIP]** = hipótese do projeto, não requisito. **Decisão do dono (12/11/2026, no chat; ainda sem entrada em `DECISIONS.md`):** manter o FoodStub provisoriamente; a regra de pagar hora parada **não** foi autorizada; direção: calibrar por dados as diferenças iniciais de preços entre povoados, sem alterar valores definitivos nem regras sem aprovação específica.

## Resumo em linguagem simples
- Cada local de produção paga mais salário por hora do que ganha vendendo (já ao preço de partida 4 de 14 dão prejuízo e 2 empatam; o resto vira prejuízo quando o preço cai com o estoque). Em 8 a 19 horas o capital de 200 acaba e o local para (`NO_FUNDS`).
- O mercado compra a 3 e vende a 5 (o spread tem piso de 1 por lado, enorme em bens de preço 4). Essa diferença **fica na conta do mercado** e nada a devolve: em 12 dias o mercado ganha 4.659 dos 19.720 do mundo e, no dia 30 sem FoodStub, guarda 89% (média de 3 sementes).
- Quem não vende comida não tem renda: os 30 guardas e estalajadeiros não têm posto (o arquivo `service_posts.json` não existe no `main`), e 52 NPCs (39%: madeira, tábua, minério, metal, ferramenta, lã, tecido) trabalham em cadeias sem comprador final. Sem renda, comem o dinheiro inicial (60) em cerca de 3 dias e, nos cenários com postos, morrem **com comida no mercado** (dia 9: 236 grãos no A e NPCs sem dinheiro morrendo).
- Subir saldos ou preços só adia (tabela abaixo). O que muda o resultado é o caminho do dinheiro: postos + produtividade + comida do C + **uma regra** (o mercado paga a folha das horas paradas, o "plano B" da Q22 estendido a todas as receitas) com salário de 1 por hora. Isso cumpre os 30 dias (132 de 132 vivos), **não** os 90: vivos 132 / 98 / 90 / 28 nos dias 30 / 40 / 60 / 90 (o C fica sem comida; a queda do A não foi investigada).

## Q1. Por que os mercados começam com preços praticamente idênticos?
- **Fórmula** (`src/sim/economy/markets/price_math.gd:17-34`; economy.md §4): `preço = base × clamp(10000 × alvo / estoque)`. Com estoque igual ao alvo o fator é 1,0 e o preço é o `base_value`, **em qualquer povoado**. Não há termo de lugar (distância, imposto, cultura): só o estoque separa os preços.
- **Dados** (`data/economy/market_targets.json`): `initial_stock == target_stock` em 28 dos 30 pares; as exceções são a farinha do B e a madeira do C (2 × o alvo). No dia 0, 8 dos 10 bens têm preço único nos 3 mercados e só farinha (6 e 3) e madeira (4 e 2) diferem: **0 de 60 pares bem+rota dão lucro** ao jogador (medição anterior, não refeita nesta sessão).
- **Não parece decisão de projeto.** Em economy.md e dados.md nenhum trecho pede "partida neutra" (não li o GDD nem toda a DECISIONS). O que existe é a regra de 30 dias de estoque para **importações** (DEC-176; economy.md §6) e o teto `initial_stock ≤ alvo × buy_cap_bp / 10000` (`docs/economy/dados.md:74`); sobre os bens que o povoado produz, `dados.md:93` diz "estoque e alvo [HIP] a propor na LW-090". A igualdade veio de copiar `initial_stock = target_stock`: **omissão de calibração dos dados**, corrigível só em dados.
- Depois de 30 dias os preços se separam (maior/menor entre povoados: pão 6x na base; grão 6x e ferramenta 2,9x no cenário que sustenta), mas por falta local (a comida acaba e o preço sobe ao teto de 3 x a base), não por comércio: as grandes oportunidades de viagem do dia 30 são de fome, não de calibração.

## Q2. Por que o dinheiro sai dos NPCs e não volta?
Dinheiro movido nos 12 primeiros dias, `main` (histórico do `Ledger`; o total 19.720 é conservado todo dia, `validate()` vazio, `burn` nunca chamado):

| motivo | de → para | valor | o que é |
|---|---|---|---|
| game_start | mint → NPC / mercado / local | 7.920 / 9.000 / 2.800 | 60 por NPC, 3.000 por mercado, 200 por local |
| trade | NPC → mercado | 6.289 | comida comprada a `ask` |
| trade | mercado → local | 4.258 | o mercado paga a produção a `bid` |
| trade | local → mercado | 2.628 | insumos e manutenção |
| salary | local → NPC | 4.400 | folha (3.100 só no dia 1) |

- Variação em 12 dias: **mercado +4.659**, NPCs −1.889, locais −2.770 (de 2.800 a 30). Dia 1: os locais pagam 3.100 de folha e recebem 812 líquidos (2.773 − 1.961 de insumos): vão de 2.800 a 512.
- **Para onde vai:** dia 11 (`main`): mercados 13.659 (69%), NPCs 6.031, locais 30 e nada se move mais. Sem FoodStub, dia 30 (média de 3 sementes): mercados 17.507 (89%), contas fechadas de NPCs mortos 2.172 (11%), vivos 0, locais 40.
- **Por quê:** (1) o spread: `margem = ceil_div(P × spread_bp, 20000)` (`price_math.gd:50-51`) tem piso de 1, então o grão (4) compra a 5 e vende a 3, o mercado fica com 40%; (2) a única saída de dinheiro do mercado é comprar dos locais (para quando o local para) e pagar os postos, que **não existem nos dados**; (3) a morte fecha a conta do NPC sem esvaziá-la (`economy_module.gd:300-312`).

## Q3. Por que a produção deixa de funcionar?
- **Linha do tempo** (`main`, locais rodando de 14): dia 0: 14; dia 1: 2 (10 `NO_FUNDS`, 2 `NO_INPUT`); dia 3: 0; dia 7 em diante: 14 `NO_FUNDS`. Sem FoodStub, a partir do dia 6 entra `NO_WORKER` (os trabalhadores morreram). Em cenários com mais folga aparece `OUTPUT_FULL` (o mercado chega ao teto de 2 × alvo e para de comprar).
- **Capital de giro:** a hora de um local custa a folha (12 a 24) mais os insumos comprados a `ask`; a venda do lote entra na mesma hora, mas é menor. Ao preço de partida, margem por hora **depois da folha** (bid de saída − ask de insumos − folha): A grão 0, A madeira −2, A farinha −12, A tábua −14, C fundição −5; B grão +8, B madeira +2, B pão +4, B tecido +4, B lã +8, C minério +4, C forja +2. Com o estoque subindo, o preço cai até 0,5 × base e o `bid` do grão chega a 1: todos ficam negativos. 200 de capital cobrem 8 a 19 horas de folha (dia 1, `main`).
- **Equipe paga que não produz:** `workers_per_batch` 4 e `max_batches_per_hour` 1 com 12 trabalhadores: 3 pagos para 1 lote (A grão).
- **Demanda que absorve:** `buy_cap_bp` 20000 (2 × alvo; A grão 240); o NPC perde 5 pontos de fome/hora, isto é, come 4 grãos (ou 2 pães) por dia. Com a produtividade ajustada (3 lotes/h; cenário `est_postos_lotes_c_procura`, dia 6) o mercado do A satura: o 2º local de grão fica em `OUTPUT_FULL` e paga 288 de folha em 6 dias contra 1.968 do 1º ("hora parada = ninguém recebe", §6): 12 lavradores sem renda enquanto os outros 12 ganham.
- **Sem comprador final:** madeira, tábua, minério, metal, ferramenta, lã e tecido só são comprados como insumo ou manutenção (2,6 ferramentas, 1,8 tábuas e 1,9 tecidos por dia nos 14 locais); 52 NPCs vivem disso.
- **Comida do C:** pão 200 + grão 10 para 28 NPCs a 2 pães/dia = **cerca de 4 dias** (o contrato diz 30, DEC-166). O FoodStub do C (6.000) escondia isso; sem ele o C morre nos dias 5 a 9, mesmo com todos os outros ajustes.

## Q4. Mecanismos que deveriam sustentar o fluxo
| mecanismo | existe no `main`? onde | papel | situação |
|---|---|---|---|
| Preço por estoque, suavização, teto de compra | sim, `markets/price_math.gd`, `market_book.gd` | leva preço e produção ao equilíbrio local | funciona; mas o teto (2 ×) bloqueia o produtor e o preço só reage ao estoque local |
| Spread `ask`/`bid` | sim, `price_math.gd:50-61` | margem do mercado | vira fuga de dinheiro sem retorno |
| Folha dos locais (`WagePayer`) | sim, `production_book.gd`, tudo ou nada | renda do NPC | só paga hora em que o local vende; para por `NO_FUNDS` |
| Postos de serviço (folha pelo mercado) | **código sim; dados não** (`post_loader.gd:5`; sem `service_posts.json`) | devolve o dinheiro do mercado a guardas e estalajadeiros | inativo: era a saída prevista para o spread |
| Manutenção (`site_upkeep`) | sim | compra de ferramenta, tábua e tecido | procura minúscula (2,6 ferramentas, 1,8 tábuas, 1,9 tecidos por dia nos 14 locais) |
| Contratos e vagas (LW-096, 096a) | sim | pagam tarefas e vagas | sem movimento nas corridas (`led_contract_*` = 0) |
| Sumidouros (`Ledger.burn`, desgaste, tributos) | `burn` existe, **nunca chamado** (§2) | tira dinheiro do mundo | Fase 4 |
| FoodStub | sim (TEMP-LW-065) | alimenta NPC sem passar pela economia | esconde tudo acima; sai na LW-094 |
| Comerciante e `Caravan` (LW-098) | **não** (roadmap) | move bem e dinheiro entre povoados, iguala preços | sem ele nenhum bem cruza povoado (§9) |
| `TradeFlow` (LW-100) | **não** | fluxo agregado por rota | ausente |
| Produtores adaptativos (LW-103) | **não** | levam mão de obra ao bem escasso | ausente; é o que falta contra `OUTPUT_FULL` |
| Escassez e reação (LW-104) | eventos sim (`events/`), reação **não** | NPC reage à escassez | parcial |
| Calibração só em dados (LW-112) | **não** | afina números | premissa em risco (Q5) |

## Q5. Mudanças mínimas: o que sustenta 30 dias e o que só adia
Tabela (30 dias; sementes 1 a 3; **sem FoodStub** = ramo da LW-094a, salvo linhas `main`; "vivos" = mínimo-máximo entre sementes; nenhuma corrida teve `validate()` com problema nem conservação quebrada):

| cenário | ref | sementes | vivos d7 / d14 / d30 | locais rodando d30 (de 14) | dinheiro d30: NPC vivo / NPC morto / locais / mercados | maior razão de preço entre povoados | melhor viagem (lucro, rota) | conferência |
|---|---|---|---|---|---|---|---|---|
| base | s094a | 3 | 44 / 0 / 0 | 0 | 0 / 2172 / 40 / 17507 | 6.0x bread | 350 ($350, breadB→A (16 un.)) | ok |
| art_saldos | s094a | 3 | 104 / 16-19 / 0 | 0 | 0 / 5123 / 2403 / 23393 | 3.8x fabric | 131-157 ($131, breadB→A (8 un.)) | ok |
| art_saldos_salario1 | s094a | 3 | 111-112 / 25-30 / 0 | 0 | 0 / 300 / 5935 / 24684 | 6.0x grain | 350 ($350, breadB→C (16 un.)) | ok |
| art_precos | s094a | 3 | 62-66 / 24 / 12 | 0-1 | 378 / 443 / 1944 / 16954 | 6.0x grain | 152 ($152, breadB→C (9 un.)) | ok |
| est_postos | s094a | 3 | 44-45 / 10-12 / 0 | 0 | 0 / 5136 / 39 / 14544 | 2.5x wool | 39 ($39, toolC→A (6 un.)) | ok |
| est_postos_lotes | s094a | 3 | 112 / 46 / 26-42 | 0 | 7074 / 1789 / 480 / 10375 | 3.8x fabric | 80 ($80, toolC→A (6 un.)) | ok |
| est_postos_lotes_c | s094a | 3 | 120 / 53-54 / 42-50 | 0 | 8277 / 126 / 500 / 10816 | 3.8x fabric | 70-80 ($80, toolC→A (6 un.)) | ok |
| est_postos_lotes_c_procura | s094a | 3 | 132 / 70-82 / 8-20 | 0-1 | 827 / 6183 / 1564 / 11144 | 2.1x bread | 78-166 ($78, breadC→A (6 un.)) | ok |
| est_postos_lotes_c_folha_salario1 | s094a | 3 | 132 / 132 / 132 | 0-1 | 9412 / 0 / 6066 / 4241 | 6.0x grain | 269-270 ($269, breadB→C (13 un.)) | ok |
| est_postos_lotes_c_procura_folha_salario1 | s094a | 3 | 132 / 132 / 28 | 1 | 745 / 14322 / 509 / 4142 | 6.0x ore | 50 ($50, woodB→C (12 un.)) | ok |
| regra_spread | s094a | 3 | 44-45 / 30-32 / 8 | 0 | 4156 / 3585 / 35 / 11943 | 6.0x grain | 350 ($350, breadB→A (16 un.)) | ok |
| base | main | 3 | 132 / 132 / 132 | 0 | 3211 / 0 / 31 / 16477 | 2.5x wool | 78-350 ($78, breadC→A (6 un.)) | ok |
| art_saldos_salario1 | main | 3 | 132 / 132 / 132 | 0 | 2373 / 0 / 5396 / 23150 | 4.5x plank | 137 ($137, toolC→A (6 un.)) | ok |
| est_postos_lotes_c_folha_salario1 | main | 3 | 132 / 132 / 132 | 0 | 12626 / 0 / 3852 / 3241 | 4.4x fabric | 29 ($29, fabricB→C (6 un.)) | ok |

**Leitura (o que cada alavanca faz, em linguagem simples):**
- **Artificial: sobe saldo (200→1.000), salário 1 ou preço ×2.** Só adia: 104 a 112 vivos no dia 7 (62 a 66 com preço ×2), 16 a 30 no dia 14 e 0 a 12 no dia 30. O dinheiro extra do capital (+11.200) **foi parar nos mercados** (23.393 no dia 30): é o mesmo ralo do spread. Cada local ganha 800 a mais, que a folha gasta em poucos dias porque o que ele vende rende menos que o que ele paga.
- **Estrutural só em dados** (compatível sem mudar contrato): (1) `service_posts.json` com os 6 postos do contrato, folha de 1/h pela conta do mercado: devolve parte do spread a 30 NPCs; (2) `max_batches_per_hour` igual ao que a equipe paga consegue fazer (3,3,2,1,2,1,2,2,2,1): todo trabalhador pago produz; (3) pão do C com alvo 800 e estoque 1.600 (30 dias, a regra da DEC-166; mais que isso estoura os 5.000 de peso do mercado). **Juntos** deixam 42 a 50 vivos no dia 30: a fome do C e dos guardas some, mas quem trabalha em cadeia sem comprador final fica sem renda, morre, e leva a produção de comida junto (`NO_WORKER`).
- **Estrutural com uma regra de contrato** (§6, plano B da Q22 estendido): **o mercado paga a folha das horas em que o local para** (`NO_INPUT`, `OUTPUT_FULL`, `NO_FUNDS`). Com os 3 ajustes de dados e salário 1/h: **132 de 132 vivos no dia 30 nas 3 sementes**, 9,4 mil em NPCs (71 por cabeça); o dinheiro do spread volta a circular (mercados 4,2 mil, locais 6,1 mil). Com salário 2/h a mesma regra (`est_postos_lotes_c_folha`, só semente 1, fora da tabela) dá 132, 132 e 3 vivos nos dias 7, 14 e 30 e deixa o mercado com 111 no dia 30: o salário precisa ficar perto de um dia de comida (20) por 24 h, isto é, 1/h.
- **Com o FoodStub (`main`)** os 132 NPCs vivem em **todos** os cenários, inclusive na base, e 0 de 14 locais produzem no dia 30: o FoodStub alimenta a população fora da economia e esconde o colapso (a corrida de 30 dias da base com FoodStub é falsamente verde). As mudanças só aparecem no dinheiro dos NPCs (3,2 mil na base; 12,6 mil no cenário estrutural) e na melhor viagem (78 a 350 na base).
- **Não ajudou:** a "procura final" (protótipo grosseiro: o povoado consome por dia 1/4 do alvo de todo bem que não é grão nem pão, **inclusive** os insumos farinha, madeira, minério, metal e lã): 8 a 20 vivos sozinha e 28 com a folha (contra 132 sem ela). **Inconclusivo**: o protótipo pode estar comendo os insumos da própria cadeia. Isolar o spread (piso de margem 0) também não basta: 8 vivos.
- **Efeito para quem joga:** NPCs vivos e com dinheiro (média 71 cada) em vez de mortos; mercados com comida (A e B) e preços que se separam (ferramenta 13 a 38; pão do C sobe a 30 quando a comida dele acaba): **melhor viagem de 1 trecho ≈ 270 de lucro** (13 pães do B ao C) contra 0 no dia 0 (medição anterior) e 70 a 80 nos cenários só de dados; **mas** só 0 a 1 de 14 locais produzem no dia 30 (6 em `OUTPUT_FULL`): o mundo vive de transferência, não de produção, e a população cai depois do dia 30 (ver 90 dias).
- **90 dias: o melhor cenário NÃO se sustenta** (semente 1): vivos nos dias 30 / 40 / 60 / 90 = 132 / 98 / 90 / 28; no dia 90, por povoado A/B/C = 0/28/0; dinheiro: NPCs vivos 2681, NPCs mortos 4878, locais 9136, mercados 3025; locais rodando 0 de 14; problemas de validação 0.
- **O que a regra não resolve:** (a) o C chega ao dia 30 com 0 de comida no mercado (1.600 pães duram cerca de 28 dias) e a corrida de 90 dias mostra a queda logo depois (132 → 98 vivos entre os dias 30 e 40; o C tem 28 NPCs); sem o comerciante (LW-098; DEC-166 prevê só 30 dias) isso era esperado; a queda do A entre os dias 60 e 90 **não foi investigada** (o dinheiro dos NPCs vinha caindo cerca de 130 por dia: 12,1 mil no dia 9 a 9,4 mil no dia 30, semente 1); (b) pagar hora parada **contraria "hora parada = ninguém recebe"** (economy.md §6, risco R3.3) e é decisão de Arthur; (c) a LW-112 prevê "só dados": **nenhuma combinação só de dados passou de 50 de 132 vivos**, então a premissa está em risco. Proposta, não decisão: antes da LW-112, decidir esta regra (ou os postos para todas as cadeias) por tarefa de contrato.

## Como reproduzir
```
export REPO=<repositório> TOOLS_SRC=$REPO/tools WORK=<pasta nova> SAIDA=<pasta>   # Godot só em --headless; antes: pgrep -fl -i godot
tools/measure_economy --days 30 --seed 1 --markets                  # o jogo real, uma linha CSV por dia (sem gravar nada)
sh docs/economia/experimentos/rodar_cenario.sh est_postos_lotes_c_folha_salario1 s094a origin/lw-094a-fim-do-foodstub-codigo 30 1 2 3
sh docs/economia/experimentos/rodar_tudo.sh                         # toda a tabela (cerca de 15 a 40 min, conforme a carga da máquina)
python3 -I docs/economia/experimentos/resumir.py <data do jogo> $SAIDA     # tabela; melhor viagem por viagem.py
sh docs/economia/experimentos/preparar_copia.sh origin/main <pasta> --historico   # + fluxos.gd.txt: fluxo por motivo e par de donos
```
As saídas brutas (CSV) não são versionadas: `rodar_tudo.sh` as regenera; só a corrida de 90 dias (semente 1), a mais demorada, está em `experimentos/saida/`.
Cenários (`cenarios.sh`): `jq` sobre `data/economy/*.json` da cópia; protótipos de regra (`regra_*`) por `sed`/`python3` só na cópia. **Limites:** 3 sementes variam só os traços e as decisões dos NPCs (a economia não sorteia); `start_default_game` não aceita semente, então `--seed` repete os carregadores do `GameApp` (o teste confere que `--seed 1` = partida padrão); amostra às 05:45; a viagem usa o preço do fim do dia e 4 m/s [HIP].
