10/11/2026 20:38 (Brasília) — CONCLUÍDA: TAREFA 3 (ajuste dos meus rascunhos world.md e npc.md, ramo lw-087c) entregue: commit 187c20c enviado, check_all VERDE (1.194 de 1.194). Nada no main, sem Fase B, sem tag; main intocado (8dcc81d). Parei (regra 13), aguardando suas decisões (seção 9). Nada rodando.

# TAREFA 3 — RELATÓRIO — LW-087c: ajuste dos meus rascunhos `world.md` e `npc.md` depois das suas decisões (DOC)        Status: PRONTA PARA REVISÃO

Li antes: AGENTS (seções 0, 3, 8, 10, 14 e 15; versão 0.4), os meus dois rascunhos (diff contra o `main`), a minha revisão da Tarefa 2, e, para registrar o impacto de `miner` e `shepherd` com fatos e não de memória: `data/occupations.json`, `routine_blocks.json`, `population.json`, `income_stub.json`, `food_stub.json`, `data/world/places.json`, `population_plan.gd`, `routine_loader.gd`, `income_stub.gd` e `place.gd`. Decisões: DEC-022, 126 e 127 (APROVADAS); DEC-047, 049 e 054 seguem PROPOSTA no `DECISIONS.md` (o registro é seu).

## 1. RESUMO
Os dois rascunhos agora refletem as suas decisões de 10/11/2026 (Q10, Q19, Q22) e deixam **claro quem decidiu cada ponto**: o que é **seu** e o que é **padrão de trabalho do revisor** (PROPOSTA, que você pode aprovar ou trocar). `inicio_de_jogo` virou `game_start` (DEC-022), o impacto de `miner` e `shepherd` está registrado com números do `main` e entrou **uma pergunta nova** (Q23) que as suas decisões abriram. Só os dois arquivos mudaram; nada foi para o `main`, nada de Fase B, nada de tag.

## 2. ARQUIVOS CRIADOS
- Nenhum.

## 3. ARQUIVOS MODIFICADOS (só documentos; ramo `lw-087c-extensoes-world-npc`, commit `187c20c`)
- `docs/modules/world.md` — Q-W1 a Q-W6 de "em aberto" para "decididas" (origem escrita em cada uma); Q10 e o aviso de capacidade dos locais `work`; o `RouteStateChanged` ficou com `route_id` e `new_state`; a renomeação `market_reserved` → `market` na LW-093 detalhada.
- `docs/modules/npc.md` — seção 14 (14.2, 14.4, 14.6, 14.7, 14.8) e linhas LW-093, LW-097 e LW-104 da tabela da seção 12 atualizadas; **14.9** reescrita ("decididas e abertas", com a origem); **14.10 nova** (impacto de `miner` e `shepherd`).
- Neste commit: ≈ +43 e −31 linhas. Contra o `main`, o ramo difere **só** nesses dois arquivos (+105 e −2). O `main` não foi tocado (`8dcc81d`). Merge do `main` no ramo: só para ficar em dia (`9de1582`), sem a Fase B.

## 4. DECISÕES TÉCNICAS
**Quem decidiu o quê (como está escrito nos dois arquivos):**

| Ponto | Decisão | Origem |
|---|---|---|
| **Q10** ofícios e cadeias | criar `miner` e `shepherd` (só dados); 4 cadeias distribuídas pelos 3 povoados, **nenhum autossuficiente**; população do 3º povoado e hashes novos na LW-097, **com a sua aprovação dos valores novos** | **Arthur** |
| **Q19** como `buy` vira candidata | **A**: mesmo mecanismo de utilidade, por valor derivado (herda o alívio da necessidade que o bem atende, descontados preço e distância); sem rotina fixa e sem planejador | **Arthur** |
| **Q22** emprego | população inicial **nasce empregada** (`work_place_id` de dados, como hoje); vaga nova por `ContractOffered`, aceita por utilidade | **Arthur** |
| Q-W1 a Q-W5 | triângulo A–B, A–C e B–C; só `open` e `closed`; nenhum campo extra na rota; `market_reserved` → `market` na LW-093; não ampliar o terreno | **revisor** (PROPOSTA) |
| Q-W6 | aceitar a mudança de hash na LW-097 | **revisor** (PROPOSTA); o **aval aos valores novos é seu** (você o disse ao decidir a Q10) |
| Q18 | **A**: evento de pagamento alivia `income`; pagamento por hora de produção aos trabalhadores atribuídos | **revisor** (PROPOSTA) |
| Q20 | só comida na Fase 3 (`bread` e `grain` comestíveis) | **revisor** (PROPOSTA) |
| Q21 | **A**: o `npc` abre a conta pela `economy/api` ao criar o NPC; a economia faz o `mint` inicial (`game_start`); a economia é registrada **antes** do `npc` | **revisor** (PROPOSTA) |

- **`game_start`:** troquei `inicio_de_jogo` pelo nome em inglês (DEC-022) na tabela da LW-093 e em 14.4; as duas menções que sobram dizem de propósito que o roadmap escreve `inicio_de_jogo` (o roadmap é protegido).
- **Payload do `RouteStateChanged`:** tirei o estado anterior (`route_id`, `new_state`), igual à arquitetura 17.3 e ao catálogo da D (`docs/events.md`). Eu tinha prometido isso na revisão (achado 9).
- **Impacto de `miner` e `shepherd` (14.10), com fatos:** `occupations.json` +2 linhas; **rotina:** cada ofício tem agenda própria que cobre as 24 h (o `RoutineLoader` rejeita ofício sem agenda): cerca de **20 linhas novas** (`farmer` tem 9 blocos, `lumberjack` 10); **`income_stub.json` não exige linha** por ofício (sem linha, o ofício novo só não alivia `income` ao trabalhar enquanto o provisório existir); **população:** hoje a capacidade dos locais `work` é **exatamente igual** à população (A: 5 × 12 = 60 e B: 5 × 8 = 40), então qualquer NPC a mais pede locais `work` novos (senão `NPC_POPULATION_NO_ROOM`); **hashes:** o sorteio dos traços na criação usa o gerador do mundo, então NPCs a mais mudam o oráculo, o hash de 30 dias e o `run_sim`.
- **O que eu NÃO decidi e deixei escrito como pendente:** (a) **Q23, nova:** hoje o NPC recebe o **primeiro** local `work` com vaga, em ordem de `id`; nada liga `miner` à mina. **Recomendo** uma coluna opcional `work_place_id` em `data/population.json` (mudança de **formato de dado**: precisa da sua aprovação, AGENTS 16.2); (b) como `sell` vira candidata (a Q19 só tratou `buy`); (c) qual tarefa do `npc` implementa o aceite de vaga e como o emprego **termina**; (d) o evento de pagamento da Q18 não existe no catálogo da D.
- **Avisos de conflito com os rascunhos da B** (escritos nos meus arquivos, sem editar nada dela): a seção 6 do `economy.md` (salário na hora, por minuto) diverge da Q18; a seção 8 e a linha do `ContractOffered` em `docs/events.md` (aceitar contrato é [FUT]) **contradizem a sua Q22** (revisão cruzada, achados 1 e 2).
- **Proposta de entrada para `DECISIONS.md`:** nenhuma nova minha; o registro de Q10, Q19 e Q22 como decisões suas é da LW-087a.

## 5. TESTES EXECUTADOS
- `tools/check_all` **no HEAD final `187c20c`**: **VERDE**. Arquitetura (nove verificações aprovadas), GDScript **sem avisos** (313 scripts), dados válidos, **124 scripts, 1.194 testes (todos passando), 261.693 asserts**, 169,6 s (3 min 21 s no total). Mesmos números do `main`, como esperado para uma tarefa só de documentos.
- `godot --headless --path . --import`: **NÃO EXECUTADO** neste worktree (`godot` não está no PATH do meu terminal: saída 127). O `check_all` rodou sozinho e ficou verde.
- Conferências por busca: `inicio_de_jogo` só aparece nas 2 menções explicativas; `git diff origin/main...HEAD` lista só `npc.md` e `world.md`.
- NÃO EXECUTADO: oráculo, soak de 30 dias e `run_sim` contra os dados novos (os dados não foram criados: é desenho).

## 6. RESULTADOS
Aprovados: `check_all` inteiro (1.194 de 1.194). Falhos e pulados: 0. Critério da tarefa cumprido **por leitura do diff**: `game_start` no lugar de `inicio_de_jogo`; Q-W1 a Q-W6 e Q18 a Q22 como "decididas" com a origem certa; impacto de `miner` e `shepherd` registrado (ofício, rotina, população, hashes).

## 7. PROBLEMAS ENCONTRADOS
- Os worktrees locais da B (`lw-087b`, `lw-087d`) estão **2 commits à frente do remoto, só por junção com o `main`**: o conteúdo dos três arquivos que revisei não mudou (conferido por `git diff --stat`).
- Os contratos da B e este arquivo ainda **se contradizem** em Q18 e Q22 (acima): precisa da B corrigir (revisão cruzada, achados 1 e 2) e da LW-087a alinhar.
- Os dois rascunhos citam o `STATUS-C.md` (ramo `status-c`) como fonte, como já citavam o `STATUS-B.md`: são referências a arquivos **fora do `main`**; limpar quando a revisão for registrada.

## 8. RISCOS
- **Q20 (só comida):** tábua, ferramenta e tecido ficam sem comprador entre os NPCs; hipótese de acúmulo de estoque e de o mercado ficar sem dinheiro (revisão cruzada, achado 3). Decisão de design **sua**; a minha PROPOSTA de só comida não a resolve.
- **Q23** muda o formato de `population.json`; sem ela o mineiro pode ser mandado para o local de trabalho errado.
- Os valores dos hashes só existem quando a LW-097 rodar; **você aprova os valores novos**, como combinou.

## 9. PENDÊNCIAS (decisões que dependem de Arthur, cada uma com a recomendação)
1. **Aprovar ou trocar** as minhas PROPOSTAs de trabalho: Q-W1 a Q-W6, Q18, Q20 e Q21 (**recomendo aprovar**, com a ressalva do item 2).
2. **Q20 e o risco do achado 3:** demanda mínima de bens que não são comida, um sumidouro simples, ou aceitar e provar no soak da LW-110 com plano B (**recomendo decidir antes da 087a**).
3. **Q23:** coluna opcional `work_place_id` em `data/population.json` (**recomendo**); alternativa: a economia designa os trabalhadores.
4. **`sell`:** o mesmo mecanismo de utilidade da Q19, definido na LW-093 (**recomendo**).
5. **Aceite de vaga e fim do emprego:** qual tarefa implementa (LW-104 ou uma própria depois da LW-096) e como o emprego termina (**recomendo** tarefa própria depois da LW-096).
6. **A B** corrigir `economy.md` (seções 6 e 8) e `docs/events.md` (linha do `ContractOffered`) conforme a revisão cruzada; **a LW-087a** registrar Q10, Q19 e Q22 e a lista de divergências do roadmap.
7. Teste manual: nenhum.

## ACOMPANHAMENTO
- Avanço: **Fase 2 CONCLUÍDA (32 de 32, 100%)**; projeto 87 de 192 (45,3%). **Fase 3 não iniciada**; os rascunhos 087b, 087c e 087d seguem **fora do `main`** até você escrever que podem entrar (a 087a, da A, não está no remoto e eu não a li).
- Próxima tarefa recomendada: **LW-087a (A)**. **Não iniciada.** Parei aqui (regra 13).
- Git: ramo `lw-087c-extensoes-world-npc` enviado (`187c20c`); `status-c` enviado; `main` = `8dcc81d`, intocado; nenhuma tag nova; nada de Fase B; sem `--force`.

---

# TAREFA 2 — REVISÃO CRUZADA (só leitura) dos rascunhos da B: LW-087b (`economy.md`) e LW-087d (`dados.md`, `events.md`)        Status: PRONTA PARA REVISÃO

**Papel:** revisão cruzada (AGENTS 11): **não implementei, não editei nada da B, nenhum commit nos ramos dela.** Li `docs/modules/economy.md` em `origin/lw-087b-contrato-economy` (`7747c1d`, 218 linhas) e `docs/economy/dados.md` (153 linhas) e `docs/events.md` em `origin/lw-087d-eventos-e-dados` (`98ca6c5`); conferi que os dois ramos **não mudaram** desde a leitura. Comparei com: GDD cap. 12 (12.3 inteiro) e 13 (13.1 a 13.5), arquitetura cap. 11 (11.1 a 11.10) e 17.3 a 17.5, roadmap 3.A a 3.J, DEC-022, 047, 049, 054, 100 e 127 (status conferido no `main` `8dcc81d`: DEC-047, 049 e 054 seguem PROPOSTA no `DECISIONS.md`; a B os rotula "aprovado por Arthur em 10/11/2026", o que está certo, e o registro é da LW-087a), e com os dados atuais (`places.json`, `occupations.json`, `population.json`, testes dos provisórios). **Não respondi as perguntas Q1 a Q14 nem a D1 da B.** Linhas abaixo: `economy.md:N`, `dados.md:N`, `events.md:N` (versão do ramo da B).

## Resumo em palavras simples
Os dois rascunhos estão **bem feitos e seguem as regras do projeto** (camadas, dono único, inteiros, nomes genéricos, `game_start` em inglês, 15 eventos contados certo, crônica igual à arquitetura 17.5). Achei **1 problema que impede aprovar como está** (o texto diz o contrário de uma decisão sua de hoje), **6 importantes** (um deles é uma **decisão de design que só você pode tomar**: o que acontece com as cadeias de madeira, metal e lã, que ninguém consome) e **5 menores**.

## BLOQUEANTE (1)
1. **Contradiz a sua decisão de hoje sobre vagas (Q22).** `economy.md:102` diz que o NPC aceitar contrato "não existe na Fase 3 … [FUT]"; `events.md:22` (linha do `ContractOffered`) repete: "aceitar contrato é [FUT]: não existe na Fase 3". Você decidiu o contrário: a **população inicial já nasce empregada** e **vaga nova é oferecida pela economia por evento (`ContractOffered`) e o NPC aceita por utilidade**. Os dois textos precisam mudar (a seção 8 inteira é de quem escreveu a B; eu só aponto): como uma vaga vira contrato `labor` (hoje `economy.md:99-101` só descreve `place_id` e `minutes`, com **um** aceitante), como o evento a anuncia e quem a aceita. Enquanto isso, o `npc.md` (meu, Tarefa 3) e o `economy.md` ficariam em **contradição** em cima do mesmo evento.

## IMPORTANTES (6)
2. **Salário: a B e a proposta Q18 divergem em três pontos** (Q18 é padrão de trabalho do revisor, **não** decisão sua). `economy.md:84` (e a linha da API, `:129`): o `npc` chama `request_work_shift(place_id, worker_id, minutes)` e a economia **paga na hora, por minuto**, a **qualquer** NPC que trabalhou no local; Q18 diz **pagamento por hora de produção aos trabalhadores designados**, com um **evento de pagamento** que alivia `income`. Divergem em (a) **quando** paga, (b) **quem** (o roadmap LW-092 fala em "trabalhadores (NPCs atribuídos)"), (c) **não há evento de pagamento** em `events.md:17-25` (e "compra, venda e consumo não publicam evento", `economy.md:138`). Além disso, (d) `economy.md:84`: sem saldo no local, os minutos **não contam** e o NPC trabalhou de graça; o contrato não diz o que o `npc` faz com esse erro no meio da ação. **Não escolho:** precisa de uma decisão (LW-087a) e de B e C escreverem a mesma coisa.
3. **Ninguém consome madeira, tábua, ferramenta e tecido na Fase 3, e isso pode quebrar a economia. Decisão de design sua.** `economy.md:48,51,53` marcam tábua, ferramenta e tecido como "consumo e venda", mas só a comida é consumida (`:91`, `:211`: só `bread` e `grain` têm `need_id`) e `burn` nunca é chamado (`:32`), sem desgaste nem perecibilidade (`:39`, Q11). O GDD 12.3 diz que a população consome "alimento, vestuário, ferramentas, luxo" e 13.2 põe "roupas (consumo e comércio)" no fim da cadeia 4. **Hipótese, não provada:** estoque dessas três cadeias só cresce até o local parar por `OUTPUT_FULL`; o preço cai para o piso (0,5×); o mercado **paga** os produtores (`:85`) e só recebe dinheiro de volta pelas compras de comida; ele pode ficar sem dinheiro (`ECON_MARKET_NO_FUNDS`, `:75`), os locais ficam sem receita, param por `NO_FUNDS` e o salário para (risco R3.3 do roadmap; critério 3.F item 3, "sem escassez crônica, sem colapso"). Parte disto é **minha**: a Q20 (só comida na Fase 3) é proposta de trabalho do revisor. **Recomendo** que você decida antes da LW-087a entre (a) uma demanda mínima de bens que não são comida (por exemplo, NPC compra ferramenta ou tecido de tempos em tempos; mexe na Q20), (b) um sumidouro simples (desgaste de ferramenta), ou (c) aceitar o risco e provar no soak da LW-110 com plano B escrito.
4. **Caso-limite que o teste vai pegar: preço mínimo 1 × `bid` arredondado para baixo × quantia mínima 1.** `economy.md:20` e `:65` (preço mínimo 1), `:66` (`bid` arredondado **para baixo**), `:31` (`amount` do `Ledger` é 1 ou mais) e `:67` (custo da ordem é a soma unidade a unidade). Com preço 1 (ou 2 e spread alto), o `bid` vira **0** e vender rende 0: o `Ledger` recusa (`ECON_BAD_AMOUNT`) ou o bem sai de graça. `dados.md:94` diz que com `spread_bp` menor que 20000 "o bid continua positivo" porque o contrato "propõe meio a meio", mas `economy.md:66` **não** diz meio a meio e a conta em inteiros não garante. Falta uma regra (por exemplo, `bid` mínimo 1 e `ask` maior que `bid`, ou `base_value` mínimo).
5. **Pagamento duplo possível no mesmo trabalho.** `economy.md:84` (`request_work_shift` soma minutos ao local e paga o salário) e `:101` (a mesma chamada "soma ao contrato" `labor`). Um NPC com contrato aceito num local que também é um local de produção: o minuto conta para os dois, e quem paga duas vezes? Falta a regra "um trabalho, um pagamento".
6. **Impacto de registrar o módulo `economy` nos hashes e na fixture de save, não tratado.** `economy.md:25` só fala da **rejeição** de save antigo (LW-111). Mas `World.serialize` grava uma entrada por módulo registrado e `World.on_load` rejeita save sem a entrada de algum (`src/core/world/world.gd:111`, `WORLD_MODULE_DATA_MISSING`): registrar `economy` (LW-088/089) **muda todo `state_hash`** e pode atingir `tests/unit/test_save_codec.gd:122` (migra a fixture `save_v1` e compara com `save_v1.expected_hash`). A fixture é **protegida** (AGENTS 12.5): mexer exige autorização sua. O contrato deveria dizer isso como risco da LW-088. **Li o código; não executei** (ver "não consegui verificar").
7. **"Nenhum povoado autossuficiente" (Q10, sua decisão) não virou regra conferível.** `dados.md:76` e `:145` deixam a distribuição "a decidir"; `economy.md:212` (Q10) só recomenda. Falta um **teste de dados** do tipo "nenhum povoado tem as quatro cadeias completas". Base atual (conferida no `main`): `places.json` tem **5 locais `work` em cada povoado** (A e B), `occupations.json` tem 5 ofícios e `population.json` tem 10 linhas (5 ofícios × 2 povoados); 10 receitas em 3 povoados, com `miner` e `shepherd` novos, **mudam população e hashes** (a B já diz isso em `dados.md:145`; está certo).

## MENORES (5)
8. `economy.md:63`: "local `market_reserved`" envelhece quando o tipo for renomeado para `market` (proposta Q-W4, LW-093); escrever "hoje `market_reserved`".
9. **Inconsistência entre ramos:** `events.md:25` põe `RouteStateChanged(route_id, new_state)` (igual à arquitetura 17.3); o meu `world.md` diz `route_id, from_state, to_state`. **Vou alinhar o meu à arquitetura e à D** na Tarefa 3 (só `route_id` e `new_state`), salvo ordem contrária.
10. `economy.md:74` e `:126`: `request_trade(actor_id, market_id, good_id, quantity, side)` acrescenta `actor_id` e `side` ao `request_trade(comprador, mercado, bem, quantidade)` do roadmap (LW-091). A mudança é justificada (a LW-093 precisa de venda), mas **não está na lista de divergências** do roadmap com suas decisões; incluir na LW-087a.
11. `economy.md:95`: "59 e 26 referências" aos testes dos provisórios **não reproduzo**: conto **19 e 13 funções `test_`** em `test_food_stub.gd` e `test_income_stub.gd`, e 110 e 29 linhas com a marca nesses dois arquivos (mais 12 e 7 em outros testes). Citar o critério da contagem ou tirar o número.
12. **Texto de estado:** `economy.md:3`, `dados.md:3` e `events.md:5,7` dizem "enquanto a Fase 2 não fecha". A Fase 2 **fechou** (10/11/2026, tag `fase-2-concluida`); na hora do merge trocar a frase. Também: `economy.md:5` (item 4) e `:94` deixam a ordem "mint na LW-093 ou LW-095 antes da LW-094" para a LW-087a, mas o roadmap LW-095 põe o `mint` **na LW-095** (e a minha Tarefa 3 trata como LW-093); entra na lista de divergências.

## O que conferi e está certo
Nomes de bens, receitas e ofícios **genéricos** (DEC-100); `game_start` em inglês em vez de `inicio_de_jogo` (DEC-022); dependências da `economy` só `core`, `data` e `world`, **sem `entities`** (decidido) e sem importar o `npc`; **dono único** (`economy.md:140-156`); dinheiro e quantidades `INT`, proporções em pontos-base, **tabelas planas** (`dados.md:16-17`); preço 0,5× a 3×, suavização, spread e profundidade conforme GDD 12.3 e arquitetura 11.5; `TradeRules` neutra (DEC-049); escopo "não fazer" do roadmap 3.J respeitado (sem bancos, tarifas reais, bandidos); `save_version` 2 e rejeição de save antigo (DEC-127, AGENTS 4.15); `CaravanAttacked`, `RouteCargoLost` e `BusinessBankrupt` **conscientemente fora** (`events.md:27`); **contagem do catálogo: 15 = 6 + 9** (`events.md:5`, conferido linha a linha); coluna "Crônica" igual à arquitetura 17.5 e as três divergências (`ProductionStopped`, `ProductionResumed`, `ContractFailed`) **rotuladas [PROPOSTA]**; todas as tarefas LW-088 a LW-116 têm linha no rastreio (`economy.md:178-197`); o verificador de ids pré-requisito da LW-093 existe no backlog (`docs/backlog.md:179`).

## Não consegui verificar
- **Por execução, nada:** só documentos; não rodei `check_all` nos ramos da B (não há código novo).
- **Achado 6** (efeito do módulo novo na fixture `save_v1` e nos hashes): li `world.gd` e o teste, **não executei**; pode haver uma saída que eu não vi (por exemplo, o teste da fixture montar o mundo sem o módulo novo).
- **Achado 3** é **hipótese**: não simulei o circuito de dinheiro (mercado, locais e NPCs); só a leitura das fórmulas.
- **Achado 4:** conta feita à mão sobre as fórmulas escritas; a curva e os valores reais só existem na LW-090 e na LW-112.
- Os números [HIP] de `price_params` e de `owner_kinds` (a B os deixa "a propor"): não há o que conferir ainda.
- Não conferi os textos de `data/text/pt_br.json` (as chaves `good.<id>.name` ainda não existem; nascem nas LW-089/092).

## Não fiz
Não respondi Q1 a Q14 nem D1; não editei nenhum arquivo da B nem de `main`; não commitei nos ramos `lw-087b-contrato-economy` e `lw-087d-eventos-e-dados`; não mexi no `DECISIONS.md`.

## Git
Só este `STATUS-C.md` (ramo `status-c`) mudou nesta tarefa. Próximo: **Tarefa 3** (meu `world.md` e `npc.md`, ramo `lw-087c-extensoes-world-npc`).

---

# TAREFA 1 — RELATÓRIO — LW-086: validação e fechamento da Fase 2        Status: PRONTA PARA REVISÃO (já no `main`; a auditoria de Arthur não foi feita)

Li antes: AGENTS (seções 0, 10, 12, 14 e 15 de novo; versão 0.4), `docs/fase-2/LW-086-roteiro-para-arthur.md` e `docs/fase-2/LW-086-relatorio-de-fechamento.md` (os dois, inteiros), `docs/DEVELOPMENT_ROADMAP.md` 2.F, 2.H e 2.J, `docs/ROADMAP_STATUS.md` (cabeçalho, bullets de ressalvas e as linhas da 082, 083 e 086a), o README (linhas 9, 140, 165, 170 e 274), os documentos que citam F3 e as duas tags anteriores (`git tag -n`, `git cat-file -t`). Decisões: DEC-122 (aceita "por ora"), DEC-126, DEC-127 e DEC-128 (APROVADAS, no `main`); DEC-047, 049 e 054 seguem PROPOSTA no `DECISIONS.md` (conferido).

1. RESUMO
A Fase 2 está fechada em texto e em Git: relatório de fechamento sem "rascunho", com as respostas de Arthur e as três ressalvas de 2.F com todas as letras; roteiro, README e contratos corrigidos para Tab (ou fn+F3); linha da LW-086 e placar (32 de 32 e 87 de 192) no status e no README; `check_all` verde no HEAD final; `main` por avanço simples; tag `fase-2-concluida` criada e enviada no commit final, depois do `check_all` verde e da fase em 32 de 32 no `main`.

2. ARQUIVOS CRIADOS
- Nenhum.

3. ARQUIVOS MODIFICADOS (7 documentos, 110 inserções e 77 remoções; nenhum protegido, nenhum código)
- `docs/fase-2/LW-086-relatorio-de-fechamento.md` — sem "RASCUNHO"; seção 1 (placar e as 3 ressalvas), 2 (números e DEC-126 a 128), 3 (entregáveis 8, 9 e 11), 4 (tabelas 2.F e 2.J), **5 (as respostas de Arthur, só as palavras dele)**, 6 (retrospectiva, com a lição da tecla F3 e a da estimativa de tempo), 7 (itens 4, 5, 10 e 11 decididos), 8 e 9.
- `docs/fase-2/LW-086-roteiro-para-arthur.md` — 11 pontos com F3 trocados para "Tab (ou fn+F3)", mais um aviso do Mac logo abaixo da tabela de teclas.
- `docs/ROADMAP_STATUS.md` — cabeçalho (CONCLUÍDA, 32 de 32, 100%, tag, 87 de 192, 45,3%), a linha da **LW-086** (concluída com ressalvas, **sem o placar no texto**), um bullet em "Pendências e ressalvas" e uma frase de atualização nas linhas da LW-082 e da LW-083.
- `README.md` — estado da Fase 2 (CONCLUÍDA), a LW-086, a tag, os números e a tecla do painel (Tab, ou fn+F3).
- `docs/modules/app.md` e `docs/modules/tools.md` — nota de que F3 sozinho é o Mission Control no Mac.
- `docs/backlog.md` — +1 linha **no meio do arquivo** (linha 180 de 213): a dica escrita no jogo ainda diz "F3 ou Tab fecha".

4. DECISÕES TÉCNICAS
- **As três ressalvas de 2.F, escritas com todas as letras** (relatório, seções 1, 4, 5, 7 e 8; linha da LW-086 e bullet no status): (1) critério 2: picos acima de ~10 ms **informativos**; (2) critério 3: teleporte e quadros **pela janela dele**, sem teste automático do teleporte; (3) critério 8: "ofício novo só por JSON" **sem teste**, vira a **LW-093b**, tarefa pequena só de teste antes da LW-093, a registrar pela A na LW-087a (conferido: hoje não consta no roadmap nem no status).
- **O placar não está dentro do texto da linha de status** (nem "32 de 32" nem "87 de 192"): a contagem por grep ficou limpa.
- **Fora da sua lista (pequeno, e digo qual):** (a) uma frase de atualização nas linhas da LW-082 e da LW-083 do status, porque diziam "não verificado na janela" e a sua passada fechou isso; (b) notas de F3 em `app.md` e `tools.md` (documentos de contrato, não protegidos); (c) no README, "a conversa vista na janela por Arthur" e a ressalva da LW-082 fechada. Se preferir sem, desfaço.
- **O hash da tag não está nos documentos** (a tag aponta para o commit que os contém). Na Fase 1 houve um commit seguinte, "registro da tag" (`307a9db`); aqui não o fiz, porque a sua ordem foi tag no commit final. Se quiser o registro, é um commit só de documentos, e preciso do seu pedido.
- Proposta de entrada para `DECISIONS.md`: nenhuma nova.

5. TESTES EXECUTADOS
- `tools/check_all` no `main` `9dbcebc` (antes de editar, para citar no relatório): **VERDE**, 124 scripts, 1.194 testes, 261.693 asserts, 313 scripts sem aviso, 0 erros de script, 170 s.
- `tools/check_all` **no HEAD final `8dcc81d`**: **VERDE**, 124 scripts, **1.194 testes (todos passando)**, 261.693 asserts, 313 scripts sem aviso de compilação, 0 erros de script, 3 min 27 s ("Warnings 1 / Deprecated 1" do GUT, o de sempre).
- `check_architecture`, `check_input_keys`, `check_literal_text`: verdes.
- Contagem **por grep, antes** (status/README): `31 de 32` 1/2, `86 de 192` 1/2, `96,9` 1/2, `44,8` 1/2, `32 de 32` 0/0, `87 de 192` 0/0, `45,3` 0/0. **Depois, no arquivo e no `main` remoto (`git show origin/main:…`):** `32 de 32` 1/2, `87 de 192` 1/2, `45,3` 1/2, e os quatro antigos 0/0; 32 de 32 linhas de tarefa da Fase 2 concluídas (script) e 32 IDs únicos na lista do cabeçalho.
- NÃO EXECUTADO: oráculo, soak de 30 dias e `run_sim` contra o `main` (só documentos; nada em `src/`, `data/` ou `tests/`).

6. RESULTADOS (Fase B)
B0: `git fetch origin '+refs/heads/main:refs/remotes/origin/main'`; o `main` não andou (`9dbcebc`); **só o `main`**, nenhum ramo `lw-087*` foi juntado. B1: um commit (`8dcc81d`). B2: verde. B3: `git push origin HEAD:refs/heads/main` (`9dbcebc..8dcc81d`, avanço simples, sem `--force`) e ramo `lw-086-fechamento-fase-2`. **Tag:** `git tag fase-2-concluida 8dcc81d` (tag **leve**, `git cat-file -t` = `commit`, como `fase-0-concluida` e `fase-1-concluida`; `git tag -n` mostra o assunto do commit) e `git push origin refs/tags/fase-2-concluida`; `git ls-remote --tags` lista as três. A tag aponta para o commit final do `main`. Nenhuma tag além dessa.

7. PROBLEMAS ENCONTRADOS
- **F3 (levantamento, só leitura):** no **jogo**, o texto da dica do painel diz F3: `data/text/pt_br.json:27` (`tools.npc_inspector.hint`: "F3 ou Tab fecha · N próximo · B anterior · T marca o rastro"). O HUD e o código de `src/presentation` não citam F3. Também citam F3, sem mudar nada: comentários de `src/app/input_actions.gd:27` e `src/tools/npc_inspector/npc_inspector_panel.gd:125`, os testes `test_npc_inspector_activation.gd` e `test_input_actions.gd` (a tecla ligada é F3 de fato, `KEY_F3`). **Anotado em `docs/backlog.md` (linha 180) e aqui; nenhum código nem dado do jogo foi mexido.**
- **Protegidos que citam F3 e não toquei:** `DECISIONS.md` (DEC-125, "Abre e fecha com F3 (e Tab)", e o texto da DEC-128 sobre a tecla ligada) e `docs/decisions/0011-revisao-fase-2.md` descrevem a tecla ligada (continua verdadeiro); `DEVELOPMENT_ROADMAP.md` só tem nós de um diagrama chamados "F3".
- A sua mensagem chegou duas vezes na conversa (a primeira cortada no meio da Tarefa 3); tratei como uma só, com o texto completo da segunda.

8. RISCOS
- A tag está no `main` e no remoto; apagar ou mover tag exige o seu pedido (AGENTS 10.6).
- A dica do painel no jogo ainda diz F3: quem ler só a tela vai tentar F3 no Mac.

9. PENDÊNCIAS
- LW-093b no roadmap (A, LW-087a). Registro no `DECISIONS.md` de DEC-047/049/054 e da escala da Fase 3 (seu). Divergências do roadmap com decisões suas (LW-097, LW-111, LW-114, `mint`). Texto da dica (backlog).
- Teste manual: nenhum novo.

ACOMPANHAMENTO
- Avanço: **Fase 2 CONCLUÍDA, 32 de 32 (100%)**; projeto 87 de 192 (45,3%). Fase 3 não iniciada.
- Próxima tarefa recomendada: LW-087a (A). **Não iniciada.**
- Git: `main` = `8dcc81d`; tag `fase-2-concluida` = `8dcc81d` (leve), enviada; ramo `lw-086-fechamento-fase-2` enviado; worktree `.worktrees/lw-086`. Neste ramo `status-c`: só `STATUS-C.md` e `REVISAO-085-C.md`.
