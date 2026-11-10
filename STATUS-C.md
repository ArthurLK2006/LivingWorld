10/11/2026 20:28 (Brasília) — CONCLUÍDA: TAREFA 2 (revisão cruzada, só leitura, dos rascunhos da B) entregue abaixo: 1 bloqueante, 6 importantes, 5 menores; Q1 a Q14 e D1 não respondidas. Nada foi mudado nos ramos da B. Seguindo para a Tarefa 3 (meu world.md e npc.md no ramo lw-087c). Nada rodando.

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
