# Pacote da 098h5, opção A: 6 comerciantes SEM mexer em preço (17/11/2026)

**Status:** documento de APRESENTAÇÃO para a aprovação ESPECÍFICA de Arthur. Feito numa CÓPIA do `main` `6d98e31` (3 sementes, 1, 2 e 3, × 30 dias, só `--headless`); **nada foi alterado em `data/`, em referências (hashes), em testes nem em contrato** (só a linha de estado da 098h5 em `economy.md` 9.15.6). "Hash" = a impressão digital do mundo inteiro. Este pacote **substitui** a última frase do ensaio (`ensaio-098h5-17-11.md`, "não investiguei por que o lavrador não compra"): a causa agora é conhecida (seção 4). Tabelas por semente, o Anexo D (os 41 testes, um por linha) e o Anexo E (os diffs EXATOS dos dados): `ensaio-098h5-anexo-17-11.md`.

**Preferência de Arthur (chat, 17/11/2026):** os resultados favorecem a **opção A: manter os preços atuais**; nenhuma diferença artificial de preço para forçar um lucro hipotético por origem; é aceitável que o comerciante **não viaje** quando não há oportunidade economicamente viável; a ativação da 098h5 **continua dependendo da aprovação específica dele**; nenhum dado protegido nem referência muda automaticamente.

## Resultado (leia primeiro)
1. A mudança é pequena: **9 linhas em 2 arquivos protegidos** (6 casas e 3 linhas de população). `market_targets.json` e todos os preços ficam como estão.
2. Os 6 comerciantes **vivem e viajam sozinhos**: 28 a 31 viagens em 30 dias e cerca de 1.100 moedas de lucro líquido; ninguém morre e a pior fome crítica é 3,0 h (o seu limite, D1: 24 h).
3. Com franqueza: o **lucro é baixo** (cerca de 6 moedas por comerciante por dia, 92% no povoado B) e o **efeito na comida é misto**: nos mercados, no dia 30, 38 / 142 / 160 hoje e 131 / 103 / 106 com eles (sementes 1 / 2 / 3), e a comida nas mochilas cai de 23 / 19 / 28 para 2 / 2 / 2.
4. **41 testes falham**: 31 só por **contagem** (NPCs, casas, vagas, ids) e 10 por **comportamento** (a agenda do comerciante: descansa no local de descanso em vez de dormir em casa). **Nenhum mostra mudança de regra para o NPC comum.** O `test_npc_buys_food` é efeito do id do lavrador, não de concorrência por pão (seção 4).
5. Os hashes mudam só pelos 6 NPCs a mais (seção 6); as 6 casas sozinhas não mudam nenhum.
6. Reversão exata em jogo novo, mas há um **achado inesperado**: desfazer as casas mata 3 NPCs em saves feitos com os comerciantes (seção 7). A opção B (pão ±30%) caiu pela D1: 41,3 h seguidas em fome crítica (semente 1).

## 1. Os dois arquivos protegidos propostos (diff exato no Anexo E)
- `data/world/places.json`, +6 `home` (capacidade 5): a_home_13 (28500, 58400), a_home_14 (29900, 58400), b_home_10 (77900, 70900), b_home_11 (79300, 70900), c_home_09 (53900, 89500), c_home_10 (55300, 89500).
- `data/population.json`, +3 linhas: `{"id": "pop_a_merchant", "settlement_id": "test_settlement_a", "occupation_id": "merchant", "count": 2, "work_place_id": "a_market_01"}`; igual para `b` (`b_market_01`) e `c` (`c_market_01`).
- As casas passam nas regras de terreno do projeto (chão plano, grama, a 10 m ou mais das outras, dentro do povoado). O A já estava cheio (12 casas × 5 = 60 vagas para 60 NPCs): daí as 2 do A. `validate_data`, `check_content_ids` e 4 testes de shell dos dados passam. (O contrato, 9.15, previa casas de capacidade 1; o ensaio usou 5, como as demais casas: o valor exato é decisão de Arthur.)

## 2. Valores antigos e novos
| | Hoje | Opção A |
|---|---|---|
| NPCs (A / B / C) | 132 (60 / 44 / 28) | **138** (62 / 46 / 30) |
| Casas (A / B / C) e vagas | 29 (12 / 9 / 8) e 145 | **35** (14 / 11 / 10) e 175 |
| Locais em `places.json`; linhas de população | 60; 20 | 66; 23 |
| Comerciantes | 0 | **6** (2 por povoado, no mercado; 300 moedas cada) |
| Estoques e preços do dia 0 | n/a | **idênticos** (`market_targets.json` intocado) |
Dinheiro total do mundo: 19.720 hoje e 21.520 com eles (+1.800 = 6 × 300 da abertura das contas; nada é criado depois).

## 3. Justificativa dos seis comerciantes (opção A, sementes 1 / 2 / 3, 30 dias)
- **O que fazem:** quando a diferença de preço paga a viagem (cerca de 2 h), compram num mercado, levam ao outro e vendem; senão **esperam** (290 a 350 h dos 720 h). Dinheiro e bens ficam conservados; sem comida nem dinheiro de graça.
| | Hoje | Opção A |
|---|---|---|
| viagens concluídas; lucro líquido (com perdas) | 0; n/a | 30 / 31 / 28; 1.104 / 1.092 / 1.075 |
| pão movido (un.); grão movido | n/a | 429 / 369 / 304; 87 / 153 / 161 |
| dinheiro movido em compra e venda | 15.607 / 18.812 / 19.005 | 37.790 / 37.028 / 35.715 |
| comida nos mercados no dia 30; nas mochilas | 38 / 142 / 160; 23 / 19 / 28 | 131 / 103 / 106; 2 / 2 / 2 |
| mortos; pior fome crítica | 0; n/a | 0; 0 h / 3,0 h / 0 h |
- **Abastecimento, sem enfeitar:** o pão e o grão do B e do C circulam, mas o efeito é **misto**: melhora na semente 1 (+93 nos mercados) e piora nas 2 e 3 (−39 e −54); somando as três sementes, os mercados ficam iguais (340) e, com as mochilas, a comida total cai de 410 para 346 (−16%). Os 14 locais de produção estão parados por falta de dinheiro com ou sem comerciantes: eles não resolvem o problema estrutural (a D3 não exige que a 098h resolva sozinha a sustentabilidade).
- **Lucro legítimo, mas baixo:** B 942 a 1.096 por mês (cerca de 20 viagens); C 21 a 133 (7 a 11 viagens, com perdas ocasionais); **A: 0 a 1 viagem** (esperam e vivem normalmente; o verificador da 098h1 não os acusa de parados: no máximo 15 min sem ação, limite 60). Isto é o que a sua preferência aceita: sem oportunidade viável, o comerciante espera.
- **Por que 2 por povoado:** é a decisão do contrato (D3: seis comerciantes vivos). Os dados mostram que o B usa bem os 2 (cerca de 10 viagens cada, repartidas entre B→A e B→C) e o A não usa nenhum. **Não testei 1 nem 3 por povoado**: os dados não provam que 2 seja o número certo.

## 4. Os 41 testes afetados (suíte inteira: 2.294 testes, 2.245 passam, 41 falham em 19 arquivos, 8 pendentes; nada editado)
| Arquivo (falhas) | Categoria | O que precisa |
|---|---|---|
| unit/test_population (7) | CONTAGEM | 132→138 (4); índices dos moradores e vagas do A, 60→70 (3) |
| unit/test_npc_setup (5) | CONTAGEM | 132→138 e próximo id 133→139 |
| unit/test_social_actions, npc_relations, npc_memory, npc_tiers (1 cada); npc_s0_wiring (2); npc_life_check_transit (1) | CONTAGEM | 132→138 ou `EXPECTED_POPULATION` |
| unit/test_settlements_data (1) | CONTAGEM | casas 12/9/8 → 14/11/10 |
| unit/test_alarm (1); integration/test_npc_s0_flow (1) | CONTAGEM | "os 60 do A" → 62 |
| unit/test_game_economy_wiring (1) | CONTAGEM | o comerciante abre a conta com 300 (tipo `merchant`), não 60 |
| integration/test_npc_s0_social, s0_flow, s0_reevaluation, test_npc_split_oracle (1 cada) | CONTAGEM | 132→138 (e regravar o `real_game`, seção 6) |
| soak/test_npc_life_7d (1); test_npc_year_short (2) | CONTAGEM | `EXPECTED_POPULATION` (414 = 138 × 3) |
| integration/test_npc_buys_food (1) | CONTAGEM indireta | reescrever sem depender do id (abaixo) |
| integration/test_npc_s0_flow (2), s0_reevaluation (6), bodies_switch (2) | COMPORTAMENTO | filtrar os comerciantes, sem afrouxar asserção |
- **`test_npc_buys_food`, a causa exata:** o teste espera que um lavrador **compre** pão nas 3 primeiras horas; com os 6 comerciantes ele não compra. **Não é concorrência, preço nem estoque:** o pão só começa a diminuir no minuto 14, os 2 comerciantes do A levam 2 a 4 pães em 3 h e o lavrador já decidira no minuto 8. **É o id dele:** todo NPC pensa pela 1ª vez `1 + (id mod 10)` minutos depois de nascer; os 6 NPCs a mais empurram o lavrador de teste do id 151 para o 157 e o 1º pensamento passa de 05:47 para 05:53. Pensando até 05:52 ele compra; a partir de 05:53 ele come o pão que já carrega. Provas: com os dados de HOJE e 6 NPCs extras antes dele (id 157) ele também não compra; com a opção A e 4 extras (id 161) ele compra; nos 10 atrasos possíveis compra até +7 min e não compra de +8 a +10; em 8 sementes compra 8/8 hoje e 0/8 com os comerciantes. **A regra do NPC comum não mudou; o teste dependia de um acaso do id.**
- **`rest` no lugar de `sleep`:** é a **agenda do comerciante** (`data/routine_blocks.json`): 0h às 6h e 21h às 24h ele faz `rest` (60 min no **local de descanso**, alivia 20 do cansaço), não `sleep` (480 min **em casa**, alivia 100). Sai para comer às 6h, 12h e 18h e passa o dia no mercado e na estrada. No jogo: ele passa a noite no local de descanso e a casa dele serve às refeições. Os testes de corpo esperavam que os 50 NPCs mais próximos do foco dormissem; 2 deles são comerciantes.

## 5. Contagem × comportamento
- **CONTAGEM (31):** só números mudam (NPCs, casas, vagas, ids, moeda inicial dos 6). **23** são o 132→138 que a A2 já cobre; **8** pedem outro número (casas, vagas, 62 moradores, 300 moedas, o id do lavrador) e precisam de autorização própria (A2 ampliada).
- **COMPORTAMENTO (10):** os 6 comerciantes têm agenda própria e os testes assumiam que todos dormem em casa. Ajuste de lógica sem enfraquecer (filtrar os comerciantes e, se quiser, **acrescentar** asserção sobre a agenda deles).
- Fora dos testes: o mesmo mundo ganha 6 habitantes (outro sorteio de traços e de decisões, pois o fluxo `npc.decision` inclui os pensamentos deles); o NPC comum segue a mesma regra no mesmo mercado.

## 6. Hashes antigos e novos (DEC-175; nenhum foi regravado)
| Referência | Hoje | Opção A | Causa |
|---|---|---|---|
| `run_sim` 30 d, 0 módulos (sementes 1 / 2) | `732907967efd…` / `3f852d2cdfc3…` | iguais | não lê esses dados |
| Oráculo, 8 das 9 impressões | (as do arquivo) | iguais | usam só 5 NPCs de teste |
| Oráculo `real_game` | `48857919c5ff…` | `aaf2aed10ce4…` | 6 NPCs a mais: ids 132→138, nomes e traços de quem vem depois (B e C), pensamentos deles no mesmo sorteio |
| Soak 30 d sem economia (s11) | `2b0f8a2917c1…` | `b7f0a32f3235…` (3 NPCs morrem) | idem; sem economia o comerciante não se sustenta |
| Soak 7 d sem / com economia (s11) | `18c422f098d0…` / `8663ffa76285…` | `3bdd83d62f61…` / `67f2546aae63…` (138 vivos) | idem |
| Soak 30 d com economia (s1) | `64f1a2af0d79…` | `c1379311abce…` | idem |
| Medição 30 d, md5 de 77 colunas (s1 / s2 / s3) | `5e124e5e` / `4a317ecb` / `43a76680` | `92dcc246` / `f0770dc8` / `e418d9d5` | idem |
| Jogo real 30 d, sonda do ensaio (s1 / s2 / s3) | `7e9618536281` / `f535e25576a3` / `e175d3868b8e` | `3d7852194244` / `10b27cd9f47b` / `a3fefb64f275` | idem |
| `EXPECTED_POPULATION` | 132 | 138 | 6 comerciantes |
Só as 6 casas: **todos iguais** (não entram no hash). Determinismo: salvar no dia 15 e carregar dá o mesmo hash do dia 30 que a execução direta (`c1379311abce…`, semente 1). Os valores completos (64 caracteres) saem na própria 098h5, que PARA e os mostra antes de regravar (DEC-175).

## 7. Reversibilidade
- **Desfazer:** as 3 linhas de `population.json`; as 6 de `places.json`; as trocas nos 41 testes e `EXPECTED_POPULATION` 138→132; as referências da seção 6.
- **Prova, jogo novo:** com os arquivos de volta (md5 iguais aos originais), `run_sim`, o oráculo (2/2, 9 impressões) e o soak voltam **exatamente**. **Save antigo** (feito com os dados de hoje) carrega com os dados novos: 132 NPCs, 0 comerciantes, mesmo hash ao carregar e, no dia 30, o mesmo da execução sem interrupção.
- **Achado inesperado (relatado, não consertado):** um save feito COM os comerciantes e carregado com os dados ORIGINAIS perde **3 NPCs por fome** até o dia 30: os 2 comerciantes do A e o último pastor do B, que moram em a_home_13 e b_home_10, casas que deixam de existir. Com as 6 casas mantidas e só a população revertida, o mesmo save carrega com 138 vivos; e as casas sozinhas não mudam nenhum hash. **O desfazer seguro é só o `population.json`**; tirar também as casas só é seguro se nenhum save com comerciantes precisar carregar.

## 8. O que NÃO foi verificado
- Suíte inteira só na opção A, sem linha de base do passo 0 e sem o `check_all` inteiro (lints). Os 31 de contagem são pelo texto do erro; não editei nada para confirmar.
- **Desempenho:** não medido aqui; o aceite (9.15.4) **NÃO foi atendido** hoje (o planejamento é 91,5% do custo extra); a 098h3c (C6 + C2, autorizada) e a medição em release vêm antes de pedir a 098h5.
- Uma execução de 30 dias por semente e cenário; a causa da queda de comida em 2 de 3 sementes e a dos 3 NPCs que morrem no soak de 30 dias sem economia não foram investigadas.

## 9. A decisão que vai a Arthur e a ordem proposta
1. **Antes:** 098h3c1 e 098h3c2 no `main`, a medição em release comparada com a implementação anterior e o resultado dela no relatório. Só então se pede a 098h5.
2. **A pedir (específico):** **A1 reduzida a DOIS arquivos** (`data/population.json` e `data/world/places.json`; `market_targets.json` fica intocado na opção A) e **A2 ampliada** (os 23 de 132→138; os 8 de outro número; os 10 de comportamento, sem afrouxar asserção; o `test_npc_buys_food` reescrito sem depender do id). Também o valor da capacidade das casas (5, como as do jogo, ou 1, como o contrato previa).
3. **A 098h5 PARA** com o diff, os testes ajustados e os valores completos antigo e novo de cada hash; Arthur aprova o valor novo naquele momento (DEC-175); só depois as referências são regravadas.
