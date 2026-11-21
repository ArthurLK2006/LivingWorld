# LW-095: o pacote para a decisão de Arthur (postos de serviço e fim do `IncomeStub`; 18/11/2026)

**Status:** PACOTE de apresentação (só documento): **nada foi implementado nem alterado**; reúne o que a LW-095 entrega, o que ela muda e as autorizações que ela pede. Pedido de Arthur (18/11/2026, decisões finais da LW-098h5, item 5): depois da LW-094, a LW-095 e a conclusão dos sistemas econômicos; a ordem proposta no diagnóstico (`docs/economia/lw-094-diagnostico-18-11.md`) põe a LW-095 ANTES da LW-094, porque os postos são o único circuito de renda que fecha hoje. Base: `main` `151b53c`; levantamento de leitura de 18/11 (`rg`, sem executar). **[HIP]** = hipótese do projeto, não requisito. Classe 3 (dado protegido novo, apagar dado e testes, referências de oráculo e de hash).

## 1. O que a LW-095 é e o que já está no `main`
- **Roadmap (l.784):** remove o `IncomeStub` (renda simbólica provisória, `TEMP-LW-066`) e põe salário de verdade: a cada hora em que o local produz, paga os trabalhadores pelo `Ledger` (tudo ou nada; um `WagesPaid` por local e hora); cada povoado ganha **2 postos de serviço** (guardas e estalajadeiros; 6 no total), com a folha paga pela **conta do mercado** do povoado, provisórios até a Fase 4 e sem marca `TEMP-LW`.
- **Já no `main` (partes a a d, 11 e 12/11; LW-096a, 14/11):** a folha dos locais e dos postos (`ServicePostBook`, `PostLoader`, `WagesPaid`), o `npc` aliviando a necessidade `income` ao receber (`WageIncome`, assinado em `npc_module.gd` só com economia) e a regra "o local sem saldo para e NÃO demite" (DEC-169).
- **O que falta (o que a LW-095 entrega):** (1) o dado `data/economy/service_posts.json` (**não existe hoje**: sem ele o `PostLoader` devolve lista vazia e nenhum posto nasce; o cabeçalho do carregador diz que o arquivo só entra "com o aviso de Arthur por escrito"); (2) a remoção do `IncomeStub`; (3) os valores NOVOS do oráculo e do hash de 30 dias, aprovados por ele (DEC-175).

## 2. O dado proposto (A1: arquivo protegido NOVO; só com a autorização escrita e específica dele)
Os 6 postos do contrato (**APROVADO por Arthur em 14/11/2026**; `docs/economy/dados.md`, tabela `service_posts.json`; as mesmas contagens de `population.json`), salário de **1 por hora [HIP]**, pago pela conta do mercado, **provisório até a Fase 4 e sem marca `TEMP`** (DEC-164 e DEC-174):
| Posto (`id` pela convenção `post_<a, b ou c>_<guard ou inn>`) | Povoado | Local de trabalho | Ofício | Vagas | Salário por hora |
|---|---|---|---|---|---|
| `post_a_guard` | A | `a_work_06` | `guard` | 8 | 1 |
| `post_a_inn` | A | `a_work_07` | `innkeeper` | 6 | 1 |
| `post_b_guard` | B | `b_work_07` | `guard` | 5 | 1 |
| `post_b_inn` | B | `b_work_08` | `innkeeper` | 3 | 1 |
| `post_c_guard` | C | `c_work_04` | `guard` | 5 | 1 |
| `post_c_inn` | C | `c_work_05` | `innkeeper` | 3 | 1 |

Formato aceito pelo carregador: `id`, `settlement_id`, `place_id`, `occupation_id` (texto não vazio), `workers_wanted` (1 ou mais, até a capacidade do local) e `wage_per_hour` (0 ou mais); um posto por `place_id`; falha com `ECON_DATA_INVALID`. Regra do contrato: folha **tudo ou nada por posto e por hora**; o mercado sem fundos faz o posto parar com `NO_FUNDS` e ninguém recebe naquela hora. O valor 1 por hora vem dos experimentos de 12/11 e 18/11 e é **[HIP]**: é ele que decide a renda de 30 NPCs.

## 3. O que as medições dizem sobre os postos (diagnóstico da LW-094, cópias do `main`)
- Sem o `FoodStub`, **os postos são o único circuito de renda que fecha**: os 30 titulares (guardas e estalajadeiros) sobrevivem em TODAS as execuções e, no A e no B, enriquecem (276 a 406 moedas nos dias 20 e 30), porque o caixa do mercado paga o posto e a comida que eles compram devolve o dinheiro ao mercado.
- **Mas só 30 de 138 (22%) vivem de posto:** com a regra da refeição por dado, os postos, os lotes e a comida do C, o mundo fecha em 50 vivos (os 30 mais 20 lavradores). O resto depende da calibração coordenada (o estudo LW-094a, proposto no diagnóstico).
- **Risco a medir na tarefa:** sem o `IncomeStub` a necessidade `income` só é aliviada por salário recebido; NPCs sem salário (artesãos, lenhadores, mineiros) deixam a `income` subir a crítica (95): o efeito no comportamento deles não foi medido.

## 4. O que muda (o inventário, com arquivo e linha)
- **Código a remover ou ajustar:** `src/sim/npc/income/income_stub.gd` e `income_stub_loader.gd` (apagar); `npc_thinker.gd` (l.482-552, o `IncomeStub` opcional e o `extra_effects`); `npc_module.gd` (l.525-526, o campo `income` de `Definitions`); `src/app/npc_setup.gd` (l.43-45, a carga e a falha "IncomeStub (TEMP-LW-066)"); `npc_decision_runtime.gd` (l.168, texto); comentários em `action_condition_provider.gd` (l.76) e `wage_income.gd` (l.6).
- **Dado:** apagar `data/income_stub.json` (5 linhas) e criar `data/economy/service_posts.json` (A1).
- **Testes:** apagar `tests/unit/test_income_stub.gd` (13 testes; **AGENTS 9.5 exige a autorização escrita dele para apagar teste**); adaptar `test_critical_need.gd` (l.285-318 e 467-483), `test_npc_setup.gd` (l.59), `test_food_stub.gd` (l.512, uma string de marca) e o comentário de `npc_bodies_twin.gd` (l.288).
- **Referências (DEC-175):** as impressões fixas do oráculo (`tests/integration/test_npc_split_oracle.gd`, l.56-68, entre elas o `real_game`) e o hash do soak de 30 dias podem mudar (os postos pagam e o `income` deixa de ser aliviado pelo stub): **a tarefa PARA antes de regravar e apresenta valor antigo, novo e causa, e só regrava o que ele aceitar.**
- **Aceite (roadmap):** busca por `TEMP-LW-066` vazia em `src/`, `data/`, `tests/`, `tools/` e `scenes/`; salário por hora de produção; local sem saldo para e não demite; guardas e estalajadeiros pagos pela conta do mercado; teste de ouro verde; valores novos do oráculo e do hash de 30 dias aprovados por ele.

## 5. Tarefas propostas (cada uma com revisão independente e CI; limites do CLAUDE.md)
1. **095e (dado, PARA e apresenta):** `service_posts.json` com os 6 postos; medição de 30 dias em 3 sementes antes e depois (alimentação, produção, comércio e renda em registros separados); valores novos de oráculo e hash, antigo, novo e causa. Só com a autorização A1.
2. **095f (remoção do stub):** código, dado e testes do `IncomeStub`, com a autorização para apagar o `test_income_stub.gd`; a busca `TEMP-LW-066` vazia.
3. A **LW-114** (`check_temp`) depende desta e da LW-094.

## 6. Decisões que dependem de Arthur
1. **Autorizar o dado novo `service_posts.json`** com os 6 postos e o salário de 1 por hora [HIP] (ou outro valor).
2. **Autorizar apagar `data/income_stub.json` e `tests/unit/test_income_stub.gd`** (AGENTS 9.5) na 095f.
3. **Aceitar o rito da DEC-175** (a tarefa PARA e apresenta antes de qualquer hash).
4. **Confirmar a ordem:** LW-095, depois o estudo LW-094a, depois a LW-094.
