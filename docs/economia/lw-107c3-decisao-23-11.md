# LW-107c3: pacote de decisão da ativação do postador de encomendas (23/11/2026)

**Status:** PACOTE (só documento): **nada foi ativado**; `data/economy/contract_templates.json` segue `[]` e nenhum `src/`, dado, teste ou save mudou. Pedido de Arthur (23/11/2026): "Prepare a decisão de ativação da LW-107c3, com os testes, dependências, riscos e reversibilidade. Não ative o postador sem minha autorização." Medido em CÓPIAS descartáveis de `origin/main` 07b97d1 (`docs/economia/experimentos/preparar_copia.sh`): **V** = tabela vazia (o jogo de hoje; pasta `A` nos brutos) e **I** = `contract_templates.initial.json` copiado sobre `contract_templates.json` (pasta `B`); `tools/measure_economy --days 30 --seed S --markets`, S = 1, 2 e 3, com o `FoodStub` e 138 NPCs. Dados brutos, roteiros e o teste de reversibilidade: scratchpad `missao/agente_h/` (fora do repositório).

## 1. Resultado e recomendação
- **Efeito econômico mínimo:** só 4 de 82 colunas do medidor diferem entre V e I (`led_contract_escrow`, `led_contract_refund`, `money_market`, `money_other`, todas ligadas à custódia, o dinheiro que o mercado deixa retido enquanto a encomenda está aberta). Vivos (138), comida, produção, preços, salário e comerciantes (viagens e lucro) são **idênticos dia a dia**; dinheiro e bens fecham nos 31 dias das 6 execuções. A custódia fica entre 206 e 259 moedas no dia 30 (no máximo 1,5% do dinheiro dos mercados).
- **Mas ninguém cumpre nada:** 34, 48 e 38 contratos postados em 30 dias, **0 aceitos** (o `npc` só lê vagas até a LW-104), 30, 43 e 34 já venceram até o dia 30 (os 4 a 5 abertos vencem em seguida) e a custódia volta inteira ao emissor.
- **A tabela inicial tem um modelo inexequível e outro sem incentivo:** o grão posta 17 contratos por semente, só depois de 14 dias, quando o grão acabou (no dia 30 nenhum dos 3 mercados tem 10 grãos em s1 e s3; recompensa 50 contra 130 de custo); o pão dá prejuízo a quem compra no emissor (média -10 a -13 por entrega) e perde para a arbitragem comum (comprar barato e revender caro; no dia 30 de s1 o povoado C paga cerca de 17 por pão: ~85 pelos 5 contra 53 da recompensa). A farinha não posta nada.
- **Referências de hash (DEC-175): nenhuma fixada em teste muda** (as 9 impressões do oráculo, o hash do soak de 30 dias e o `run_sim` seguem iguais; só mudam os hashes informativos do mundo COM economia, seção 4); em compensação **36 testes em 17 scripts** (de 2292 em 286) afirmam o mundo sem contratos e falham com a ativação (na V, 0 falhas); seção 4.
- **Reversível, testado na cópia:** tabela vazia de volta = comportamento de hoje; um save feito COM contratos abertos e 1 aceito carrega com a tabela vazia, tudo vence em 3 dias, o escrow volta e o dinheiro não muda; um save ANTIGO carrega com a ativação.
- **Recomendo a (B):** ativar, em PR próprio, só com a sua autorização escrita e depois da sua validação visual do roteiro (17/11), os modelos iniciais **sem o `grain_shortage`**. Motivo: risco econômico desprezível e reversível, custo em referências pequeno e é a única forma de gerar a evidência que a S4 pediu (jogador aceitando e concluindo encomendas). O preço é um incentivo fraco, que só uma regra nova do postador (classe 3, seção 6) resolve e que não bloqueia a ativação. A (A) só difere por levar o grão inexequível ao jogador; a (D) deixaria a 107f (abandono, limite, interface) sem fonte de encomendas; a (C) é a alternativa de menor risco se preferir esperar a LW-094/095, ao custo de manter a LW-107 aberta e a aba vazia com texto enganoso.

## 2. Medição de 30 dias, dia 30 (sementes 1 / 2 / 3)
**ANTES (V, tabela vazia = `origin/main` de hoje)**

| Grupo | s1 | s2 | s3 |
|---|---|---|---|
| Alimentação: vivos; comida nos mercados / nos NPCs | 138; 131 / 2 | 138; 103 / 2 | 138; 106 / 2 |
| Produção: locais rodando de 14 (sem fundos); pão feito / usado | 0 (13); 1110 / 977 | 0 (13); 1074 / 984 | 0 (12); 1074 / 975 |
| Comércio: dinheiro dos mercados; `led_trade`; comerciantes (viagens / lucro); pão máx / mín | 19932; 37790; 30 / 1417; 18 / 9 | 20400; 37028; 31 / 1283; 18 / 11 | 20217; 35715; 28 / 1160; 18 / 9 |
| Renda: `led_salary`; dinheiro dos NPCs vivos; total (criado / destruído) | 5308; 1541; 21520 (21520 / 0) | 5244; 1073; 21520 | 5252; 1255; 21520 |
| Contratos de entrega | 0 | 0 | 0 |

**DEPOIS (I, 3 modelos iniciais): "=" é idêntico ao ANTES**

| Grupo | s1 | s2 | s3 |
|---|---|---|---|
| Alimentação, produção, renda, `led_trade`, preços, comerciantes | = | = | = |
| Dinheiro dos mercados (diferença para o ANTES) | 19726 (-206) | 20141 (-259) | 20011 (-206) |
| Postados / aceitos / vencidos / abertos no dia 30 | 34 / 0 / 30 / 4 | 48 / 0 / 43 / 5 | 38 / 0 / 34 / 4 |
| Escrow movido / devolvido (`refund`) / custódia no dia 30 (= pico) | 1751 / 1545 / 206 | 2493 / 2234 / 259 | 1963 / 1757 / 206 |

Cada diferença do dinheiro dos mercados é igual à custódia (`money_other`): nada se cria nem some (`created` 21520 e `destroyed` 0 nas duas cópias).
**Linha de base de hoje (V), sem relação com o postador:** 0 dos 14 locais rodam no dia 30 (12 a 13 sem fundos); é o bloqueio da LW-094/095.

## 3. O que a tabela inicial posta no jogo real (cópia I)

| Modelo | Ofertas s1 / s2 / s3 | Quando | Custo para o jogador | Dá para cumprir? |
|---|---|---|---|---|
| `bread_standing` (5 pães, 48 h, 500 bp): 53 | 17 / 31 / 21 | povoados A e C às 06:00 do dia 1; B depois de 4 a 5 dias | no emissor custa 55 a 107 (perde 2 a 54) | sim, com prejuízo; ganho só comprando no mercado barato (o pão vai de 5 a 10 no mais barato e chega a 18 no mais caro) |
| `grain_shortage` (10 grãos, 2500 bp): 50 | 17 / 17 / 17 (povoados A e B, depois de 14 a 16 dias) | só com escassez declarada | 130 no emissor (ask 13) | **não**: o emissor não tem o lote em 17 de 17 ofertas (s1 e s3) e em 9 de 17 (s2); no dia 30 só o povoado B de s2 tinha 10 grãos (15; perda de 80) |
| `flour_shortage` (10 farinhas) | 0 / 0 / 0 | a farinha sobra (povoado B: 810 a 846, alvo 810) | - | sem efeito |

No jogo real o jogador veria a aba Contratos dos povoados A e C com "Entregar 5 x Pão, Recompensa: 53" a partir das 06:00 do dia 1 (roteiro LW-107, seção 4) e, depois de 14 dias, "Entregar 10 x Grão", que quase nunca consegue cumprir.

## 4. Referências (DEC-175) e testes

| Referência | V | I | Causa |
|---|---|---|---|
| Oráculo `test_npc_split_oracle.gd`, 9 impressões (`real_game` = `aaf2aed10ce460e57d38b05c6273fea5bffa837537655bf837f4d64cefff4e22`; as outras 8 em `tests/integration/test_npc_split_oracle.gd`, l.60 a 68) | as 9 passam | **iguais** (9 passam) | o oráculo roda sem a economia |
| Soak de 30 dias SEM economia, semente 11 (nenhum teste o fixa) | `b7f0a32f3235ad3f3a092c7418564c423071acd9151410676dc6d484b03df5e3` | **igual** | idem; `soak_npc_life_30d.gd` falha igual nas duas (135 vivos: 3 estalajadeiros do C morrem de fome, LW-094, não o postador) |
| Mundo real COM economia, semente 1, depois de 1 dia (`runner.run_days`; V = a cópia I com os modelos zerados em código; informativo, nenhum teste o fixa) | `ac821040b50114f39c59dd738f6c1ddce8013aeaaccdd40b9a16e4489646b44d` | `b3cfd8fdeb7e4dc9fa08221ac84c289677d935e59295aa9628c1ccb3d8e2287a` | os contratos e a custódia entram no estado do mundo (o 1º é postado às 06:00) |
| idem, 7 dias | `c00f7e66afe0d0059f59c48060f67caf387d625ac3eb42ebed39bd40f86af00e` | `ec52a0e5b753ca9feace4dddd64691a9562c8aa4825f763a1f7eef8d8eb0ee50` | idem |
| idem, 30 dias | `3d78521942444e810545600b96fad054ad33ebcce8fd889883a72507466b1b57` | `6aab51654080df865e4b09b6106edeb7e62801f7b38d120d0ec8cf0ad8e0846c` | idem |
| Soak de 30 dias COM economia, semente 1 (`NpcLifeCheck`, informativo) | `c1379311abceb89dcb83cf592af8f886b655a8b0ac1b34ddfcd095297c652bd3` (reproduz o registrado em 18/11) | não calculado (leva mais de 30 min de CPU) | idem |
| `run_sim --days 30`, sementes 1 e 2 | `732907967efdba5f718687a0bbafbfe102ac51cabc9d15a7f0119a9e64ebc4d7` e `3f852d2cdfc3d4171e6893b79b0a9908b364a11203bdb9db59b9f9057e084544` | **iguais** | não registra módulos (0) |

**Testes (`tests/unit` e `tests/integration`, 286 scripts, 2292 testes, só `--headless`):** V = 0 falhas (e os 8 pendentes de sempre, os do `ice_figure`); I = **36 falhas em 17 scripts** (a medição de 16/11 dizia cerca de 30; a da 107c2, 32 em 14). Todos afirmam o mundo SEM contratos; nenhum foi alterado nem apagado aqui, e atualizá-los é trabalho do PR de ativação, com a sua autorização (AGENTS.md 9.5).

| Causa | Scripts (testes) |
|---|---|
| O dado real traz 0 modelos / o jogo real não posta entrega | `test_contract_templates_data` (2), `test_contract_voluntary_world` (1: o que fixa 0 entregas em 1 dia) |
| O mundo real já tem contratos: quadro, contagem de vagas e IDs deslocados (o 1º do postador é o ID 156) | `test_bridge_contract_abandon` (2), `test_bridge_player_contracts` (3), `test_contracts_view_model` (4), `test_contracts_view_model_abandon` (2), `test_contracts_tab` (3), `test_contract_vacancies` (3), `test_npc_employment_by_work_place` (1), `test_economy_production_api` (1) |
| O escrow tira 53 do caixa do mercado (3000 vira 2947) e a devolução volta | `test_contract_dead_issuer_custody` (6), `test_contract_expiry` (1), `test_contract_cycle` (2), `test_economy_caravan_trip` (2), `test_npc_merchant_food` (1), `test_service_posts` (1) |
| O livro-razão ganha os motivos `contract_escrow` e `contract_refund` | `test_npc_buys_food` (1) |

## 5. Reversibilidade (teste GUT só na cópia I, `h_reversibility.gd`, 2/2 verdes, 52 asserções)
- **R1, salvar COM a ativação e carregar com a tabela vazia:** save com 1 contrato aberto e 1 aceito pelo jogador (hash do mundo igual ao carregar); 3 dias depois ambos venceram (o aceito vira `expired`, sem multa), `contract_refund` foi de 0 a 106 (o escrow voltou ao mercado emissor), nenhum contrato novo, dinheiro total 21620 = 21620, nada criado, `validate()` do mundo e da economia vazios e as duas conservações ok. O mesmo save com a ativação posta 2 novos no período.
- **R2, save ANTIGO (sem contratos; o bloco `economy` só tem `last_run` e `next_due`) com a ativação:** carrega com o mesmo hash, o postador volta a postar, tudo fecha.
- **Limites da reversão:** contrato fechado NUNCA sai do livro (`ContractBook` não apaga) e gastou IDs, então um mundo que já ativou não volta ao hash de um mundo que nunca ativou; um jogo NOVO com a tabela vazia reproduz exatamente o de hoje (é a cópia V). Trocar os modelos depois não invalida contrato já postado (cada um guarda o próprio objetivo).

## 6. Dependências e riscos (o que o agente E já levantou não foi refeito: `missao/agente_e/TABELA_LW107.md`)

| Item | Situação |
|---|---|
| LW-104 (roadmap l.794 e `economy.md` 107f (f)5: NPC aceitando contrato; depende da LW-094, ainda em decisão) | sem ela ninguém aceita: 0 de 120 contratos aceitos; o mundo não responde às encomendas |
| Feedback fora do mercado (E, "Jogabilidade" 3 e 7) | a aba vazia diz "os mercados estão abastecidos" (`ui.contracts.empty`) e não há HUD, diário nem aviso de oferta ou prazo |
| Compra circular (107c3-B, S4 de 16/11) | medido em 16/11: 11, 5 e 10 moedas em 30 dias; E, 720 h: -6, -54 e +13 por mercado (teto 300) |
| Anti-exploração (b) e incentivo | recompensa ≤ `ask` x lote: comprar no emissor nunca dá lucro, e o ganho possível (comprar barato noutro mercado e entregar) é menor que o da arbitragem comum (vender no mercado caro); emissor = destino (E, 5): sem jornada. Corrigir pede regra nova (destino ≠ emissor), classe 3 |
| Comerciantes e estoque | nenhum efeito medido (colunas idênticas); a entrega do jogador sobe o estoque do emissor e segura a repostagem (E, observação 1) |
| Livro de contratos | 34 a 48 por 30 dias, cerca de 414 a 584 por ano, e nunca é podado (cerca de 150 bytes cada, 60 a 90 KB por ano de jogo [estimativa, não medida no save]); o postador percorre o livro a cada hora cheia (custo não medido: sem benchmark) |
| Dado protegido | editar `contract_templates.json` e atualizar testes exige a autorização escrita de Arthur (AGENTS.md 12.5 e DEC-175, em PR separado) |

## 7. Opções

| Opção | Impacto | Custo em testes e referências | Reversibilidade |
|---|---|---|---|
| **A** ativar com os 3 modelos iniciais | o da seção 2; oferece 17 grãos por 30 dias que ninguém cumpre | 36 testes em 17 scripts a atualizar; nenhuma referência fixada muda | total (voltar `[]`); o livro mantém o histórico |
| **B** ativar com modelos ajustados (RECOMENDADA) | o mesmo, sem o contrato inexequível | igual à A | total |
| **C** adiar até a LW-104 e o HUD | nenhum; aba vazia com texto enganoso; a LW-107 não fecha | nenhum | n/a |
| **D** descartar o postador | a 107f (abandono, limite, interface) fica sem fonte de encomendas no jogo real | apagar o `ContractPoster`, a tabela e os testes dele: só com autorização (AGENTS.md 9.5) | só pelo histórico do git |

**Proposta de dado para a B (NÃO aplicada nem medida):** (1) remover `grain_shortage` do arquivo (inexequível hoje porque o grão acaba; voltar a avaliar quando a LW-094/095 consertarem a produção); (2) manter `bread_standing` (1 aberto por mercado, 48 h) e `flour_shortage` (dormente); (3) opcional só para demonstração, o ajuste do roteiro (`max_open` 3, prazo 16 h) triplica a custódia (até cerca de 480, 2,4% do dinheiro dos mercados). Nenhuma margem de dado cria lucro no emissor, porque a regra (b) limita a recompensa ao `ask`: o incentivo é decisão de regra, não de dado.
**Ordem sugerida se escolher a B:** sua validação visual do roteiro (que `docs/ROADMAP_STATUS.md` ainda não registra), depois um PR único com o dado, os testes atualizados, a medição repetida e o teste de reversibilidade desta análise como teste novo (`missao/agente_h/h_reversibility.gd`), no rito da DEC-175.

## 8. O que NÃO foi verificado
Desempenho (sem benchmark: custo de `peek_contracts` com milhares de contratos, tamanho do save); jogo real na janela (só `--headless`); o ciclo com o jogador no medidor (o `measure_economy` não tem jogador: o lucro do jogador vem do E, em 720 h); o efeito de NPCs aceitando (não existe até a LW-104); a suíte `tests/soak` inteira, os scripts de shell de `tests/` e a repetição das falhas uma a uma (as causas são IDs, saldos e contagens, não tempo).
**Reproduzir:** `preparar_copia.sh 07b97d1 <V>` e `<I>` (na I, `cp data/economy/contract_templates.initial.json data/economy/contract_templates.json`); `tools/measure_economy --days 30 --seed S --markets`; GUT com `-gtest=res://tests/integration/test_npc_split_oracle.gd` e `-gdir=res://tests/unit,res://tests/integration -ginclude_subdirs`.
