# Pacote de aceite 2 — LW-098, LW-107, LW-108 e arte da praça: já no `main`, esperando o seu aceite

Preparado em 23/11/2026 sobre o `main` 8b88d7a. **Nenhuma tarefa foi marcada como aceita e o ROADMAP_STATUS não foi alterado:** o aceite formal é seu. Cada tarefa abaixo está **pronta para o seu aceite** ou diz o que falta. Levantei roadmap, contratos, fila, backlog e testes por leitura. O CI do `main` está verde no 699c345 (23/11); a execução do 8b88d7a, que só soma um teste e o backlog, estava em andamento quando conferi. Reexecutei 3 testes isolados (última seção). Nada foi medido em release nem visto na janela.

**Como o placar conta (leia antes das contas).** O ROADMAP_STATUS conta **tarefa numerada**; subtarefas com letra (098b, 107e2, 098h5…) **não entram**. Aceitar subtarefas não mexe no 98 de 192 (51,0%) até uma tarefa numerada inteira fechar: LW-098, LW-107 e LW-108 valem **1 cada**. ART-5b1 e ART-6a são da trilha de arte e **não estão nas 192**. Conferi a lista do levantamento de 21/11: está certa (nada daqui foi aceito; o último aceite registrado é o de 14/11, PR #40), mas ela listava subtarefas como se fossem tarefas.

| Grupo | Subtarefas (PRs) | Critério do roadmap | Proposta |
|---|---|---|---|
| A. Comerciante e caravana | 098b a 098g (10 PRs) | linha 788; teste automático | **aceitar** |
| B. Preparo da 098h | 098h0a, h0, h1, h2, h3a, h3b, h3c1, h3c2, h4 (10 PRs) | contrato 9.15.6; teste automático | **aceitar com ressalva** (desempenho) |
| C. Ativação dos 6 comerciantes | 098h5 (#139, #138, #141) | contrato 9.15.5 | **não aceitar agora** |
| D. Encomendas, sem tela | 107b1, b2, c1, c2a, c2b, d, f1, f2, f3, f5, g (11 PRs) | linha 797; teste automático | **aceitar** |
| E. Encomendas, com tela | 107e1, e2a, e2b, f4a, f4b, f4c (7 PRs) | linha 797 e o roteiro | **aceitar depois da sua conferência na janela** |
| F. Painel econômico | LW-108 (partes 108a a 108e) | linha 798; validação manual | **aceitar depois da sua conferência na janela** |
| G. Praças B e C | ART-5b1 (#38) e ART-6a (#39) | Mandato 1 e `presentation.md` | **aceitar depois da sua conferência na janela** |

## A. LW-098b a 098g — comerciante e caravana
- *Em linguagem de jogador:* o jogo calcula se compensa levar mercadoria de um povoado a outro (diferença de preço menos tempo e risco da estrada); a caravana compra, viaja, vende na chegada e o preço de destino cai; estrada fechada faz parar ou desviar; o NPC comerciante decide pelo lucro, e o lucro alivia a necessidade de renda.
- *Critério (linha 788):* só viaja com lucro esperado; chega, vende e o preço de destino cai; lucro e dinheiro passam pelo `Ledger`; conservação mantida.
- *Evidência:* 13 arquivos de teste, 111 testes (contei as funções `test_`): `test_trade_planner` (16: sem diferença maior que spread, tempo e risco, não há plano), `test_economy_caravan_trip` (8), `_property`, `_route_state` (14), `_start`, `_save`, `_wiring`, `test_npc_merchant` (13: não viaja sem lucro, não oscila), `_arrival` (12), `_data`, `test_caravan_params`, `test_route_cost`, `test_caravan_book`. PRs #46 e #45 (098b), #49 (098c, aprovado por você), #51, #52, #58 (098d), #53 (098e), #66, #72 (098f), #74 (098g). Os hashes do jogo real não mudaram até a 098h.
- *Ressalvas menores (backlog):* a `sell` do comerciante nunca vende comida; o contrato 9.5 diz busca binária e o código usa varredura exata; lacunas de teste da 098g. Nenhuma impede o aceite.
- **Proposta: aceitar.**

## B. LW-098h0a a 098h4 — o preparo antes de ligar os comerciantes
- *Em linguagem de jogador:* nada muda na tela. São as ferramentas e correções que tornaram seguro ligar os comerciantes: o verificador que não confunde viagem com NPC travado (#117), as colunas de comerciantes na medição (#118), a emulação (#119, #120), a correção do pensador (comerciante com comida na mochila não repete a compra; caso dos 120 pães, #122), os testes de "nada de comida infinita" (#123) e quatro otimizações exatas do planejador (#124, #125, #134, #135: mesmas decisões, mesmos hashes).
- *Critério (contrato 9.15.6, por teste):* `test_npc_life_check_transit` (11), `test_measure_merchant_cells` (5), `test_merchant_emulation` (12), `test_npc_merchant_food` (6), `test_npc_haul_single_query`, `test_trade_quote_curve`, `test_trade_planner_memo`; fora do `check_all`: `test_merchant_emulation_10d` e o V9 `test_npc_life_7d` (7 dias com os 6 comerciantes, 138 vivos).
- *Ressalva:* o critério de **desempenho** (9.15.4: nenhum passo acima de 33 ms e no máximo 5 acima de 16,7 ms em 30 dias, "lido como aumento sobre a base") **não está afirmado**. Com emulados, o soak caiu de 73,6 para 57,9 s (-21%, `medicao-098h3c-18-11.md`); com os 6 comerciantes reais, em bateria, subiu 27% e o p99 do passo foi de 3,2 para 4,2 ms; passos acima de 33 ms: média 2,7 na base e 5,3 com os reais, faixas que se sobrepõem (`medicao-098h5-real-18-11.md`). Aceitar este grupo **não decide o desempenho**; a leitura é sua.
- **Proposta: aceitar, registrando que o aceite de desempenho segue em aberto.**

## C. LW-098h5 — a ativação dos 6 comerciantes
- *Em linguagem de jogador:* 2 comerciantes por povoado (6 casas e 3 linhas novas de dados; 132 para 138 NPCs); salvar e carregar segue funcionando, e um save que cita casa inexistente é recusado com mensagem clara.
- *Evidência:* `test_merchant_world` (3), `test_merchant_saves` (3), `test_merchant_reversal_guard` (2), `test_save_places_guard`. Só a referência `real_game` foi regravada (DEC-175; você aprovou em 18/11): `48857919…` para `aaf2aed1…` (`docs/economia/referencias-098h5-18-11.md`).
- *Por que não agora (mesmo documento, seção 7):* (a) **sustentabilidade alimentar:** `run_npc_life_30d` **falha de propósito** (sua opção A de 18/11: 3 estalajadeiros do C morrem de fome 7,75 h antes de 30 dias); fecha com a LW-094; (b) cada comerciante fazer ao menos uma viagem: os 2 do A fazem 0 a 1 em 30 dias, que você aceitou em 17/11 (tratado como dispensado, a confirmar); (c) desempenho, como em B; (d) a 098h6 (nova medição de 30 dias em 3 sementes) não foi feita e depende de você.
- **Proposta: não aceitar agora.**
- **E a LW-098 no placar?** É uma só tarefa e a 098h faz parte dela (contrato 9.12). Saída 1 (**recomendada**): fecha depois da LW-094, com a 098h5 e a 098h6 aceitas. Saída 2: você declara que ela fecha agora com a ressalva da 098h, como fez com a LW-097. A escolha é sua; as contas mostram as duas.

## D. LW-107 sem tela e E. LW-107 com tela
- *Em linguagem de jogador:* o jogador vê as encomendas do mercado, aceita (limite de 3), entrega e recebe; prazo vencido devolve o dinheiro ao emissor; pode abandonar sem multa, com painel de confirmação.
- *Critério (linha 797):* aceitar, transportar e entregar paga a recompensa; falhar devolve a custódia ao emissor; texto por chaves.
- *Evidência D (sem tela):* 16 arquivos, 109 testes: `test_contract_cycle` (8), `test_contract_cycle_poster` (6), `test_bridge_player_contracts` (11), `test_bridge_contract_abandon` (11), `test_contract_abandon` (16), `test_contract_limits_data` (10), `test_contract_templates_data` (10), `test_contract_poster` (8) e mais 5 arquivos do postador, `test_contracts_view_model` (14) e `_abandon` (6), `test_contract_voluntary_world` (2). "Falhar devolve" também por `test_contract_expiry` e `test_contract_dead_issuer_custody` (LW-096, já aceita). PRs #47, #44, #75, #77, #84, #50, #56, #104, #105, #108, #114, mais #98 e #144.
- *Evidência E (com tela):* 7 arquivos, 60 testes sem janela (`test_contracts_tab`, `_layout`, `_actions`, `_page_abandon`, `_danger_tint`, `test_abandon_confirm`, `test_contracts_abandon_tab`); PRs #55, #57, #60, #65, #109, #110, #115. **A aparência nunca foi vista na janela.** Pontos a olhar (backlog): a lista se refaz a cada 1 s e a rolagem reinicia; o botão desativado tem contraste menor; o fundo do painel não escurece; prazo longo pode ser cortado com "…"; nomes provisórios ("contrato" e "encomenda").
- *Ressalvas de D e E:* o postador está **desligado** (`contract_templates.json` é `[]`): sem a LW-107c3 (decisão à parte, fora deste pacote) o jogo real não tem encomendas, e o backlog diz que **a LW-107 só fecha no placar com essa decisão**. Ainda não há poda de contratos terminados (cerca de 1,6 mil por ano de jogo, [HIP]).
- **Proposta: aceitar D agora; aceitar E depois do roteiro** de 14 itens, 15 a 20 min: [LW-107-roteiro-para-arthur.md](../economia/LW-107-roteiro-para-arthur.md).

## F. LW-108 — painel de depuração econômico (só leitura)
- *Em linguagem de jogador:* painel que só existe em build de desenvolvimento (Shift+Tab) e mostra preços, estoques, produção e se o dinheiro está conservado, sem mudar nada.
- *Critério (linha 798):* na janela, os números batem com as consultas; só lê; diz claramente se a conservação está ok.
- *Evidência:* 5 arquivos, 35 testes: `test_economy_debug_panel` (6; exercitar o painel não muda nada), `test_economy_inspector_model` (12; veredito verde e vermelho), `_panel` (8), `_activation` (6), `test_economy_debug_and_kinds` (3). Entrou no `main` em 12/11 por autorização antecipada. "Os números batem" só a janela prova.
- *Ressalva:* as cadeias de causa de escassez ficam de fora (dependem da LW-104; o critério de aceite não as exige).
- **Proposta: aceitar depois da conferência.**

## G. ART-5b1 e ART-6a — praças dos povoados B e C
- *Em linguagem de jogador:* em B e C as barracas deixam de ser a mesma tenda (toldo de uma água, mesa com guarda-sol, carroça de feira, com veio na madeira e remendos no pano) e a vegetação em volta muda (B arrumada, C rústica); a praça A não mudou. Só apresentação.
- *Evidência:* `test_plaza_stalls` (7), `test_plaza_vegetation` (5), `test_market_plaza_view` (12); impressão digital da demonstração idêntica e revisão independente aprovada, com ajustes aplicados (descrição do PR #39); triângulos por praça: A 2.808, B 3.341, C 2.881 (a fila registra margem de só 59 na B). O roadmap numerado não tem critério para arte: vale o seu aceite visual.
- *Ressalvas:* feitas em 14/11, **antes da diretriz de arte de 15/11**; cores e posições são [HIP]; já aparecem no jogo real.
- **Proposta: aceitar depois da conferência.**

## Roteiro curto na janela (sem teclas novas; nada vai para o repositório)
1. **Preparar:** o Maestro monta a pasta do `main` e diz o caminho; abra o jogo como na seção 3 do roteiro da LW-107 (W A S D, Shift corre, **E** interage, **P** pausa, **2** acelera). O mercado A fica a cerca de 45 s correndo.
2. **LW-108:** **Shift+Tab** abre o painel; veja o veredito de conservação; **P** pausa; anote preço e estoque do pão; chegue a menos de 3 m da praça, aperte **E**, aba Mercado: devem ser iguais.
3. **LW-107 (E):** os 14 itens do roteiro (para haver encomendas, copie `contract_templates.initial.json` só no seu computador, como ele ensina).
4. **ART:** B fica uns 500 m a leste e 100 m ao sul do mercado A, e C uns 250 m a leste e 300 m ao sul (conta minha sobre `data/world/places.json`; cerca de 1 min correndo a 7 m/s). O jogo não mostra coordenadas e não achei teletransporte (procurei só em `src/app` e `src/presentation`). Olhe as barracas e a vegetação.

## As contas (hoje: 98 de 192, 51,0%; Fase 3: 11 de 30, 36,7%)
Subtarefas por grupo: A 6 (10 PRs) · B 9 (10 PRs) · C 1 · D 11 · E 6 · F 1 tarefa numerada · G 2 (fora do placar) = **36**.

| Se você aceitar (acumulado) | Tarefa numerada que fecha | Placar | Fase 3 |
|---|---|---|---|
| A, B e D (as propostas "aceitar") | nenhuma (a LW-098 espera a 098h5; a LW-107 espera E e a 107c3) | 98 de 192 (51,0%) | 11 de 30 (36,7%) |
| mais F, depois da conferência | LW-108 | 99 de 192 (51,6%) | 12 de 30 (40,0%) |
| mais E e a decisão da 107c3 | LW-107 | 100 de 192 (52,1%) | 13 de 30 (43,3%) |
| mais a LW-098 (saída 1 ou 2) | LW-098 | **101 de 192 (52,6%)** | **14 de 30 (46,7%)** |

G não conta no placar (arte).

## Fora deste pacote
LW-107c3 (decisão à parte, em PR: `docs/economia/lw-107c3-decisao-23-11.md`), LW-094, LW-095, LW-098h6, LW-100, LW-103, ART-12 (a figura segue desligada) e ART-6b e ART-7 (suspensas).

## Como aceitar
- **Agora (sugestão):** "APROVADO LW-098b a 098g, LW-098h0a a 098h4 (o aceite de desempenho da 9.15.4 segue comigo) e as subtarefas da LW-107 sem tela (107b, 107c1, 107c2a, 107c2b, 107d, 107f1, 107f2, 107f3, 107f5 e 107g)".
- **Depois do roteiro:** "APROVADO LW-108"; "APROVADO as subtarefas da LW-107 com tela (107e1, 107e2a, 107e2b, 107f4a a 107f4c)"; "APROVADO ART-5b1 e ART-6a". **Sem aceite:** 098h5.
- Com o aceite, o Maestro atualiza o ROADMAP_STATUS. Nenhum valor de referência é regravado por este pacote: A, B, D, E, F e G não mudam hash; só a 098h5 mudou o `real_game`, que você já aprovou em 18/11.

## O que não verifiquei
Reexecutei só `test_contract_cycle` (8 de 8, 212 asserções), `test_economy_debug_panel` (6 de 6, 67) e `test_economy_caravan_trip` (8 de 8, 203), com `--headless` e `nice -n 10`. **Não rodei** a suíte inteira, o `check_all`, o `run_npc_life_30d` (falha conhecida; só li os documentos), nenhuma medição em release e nada na janela. Não achei teste específico de "texto por chaves" (a regra é do `check_literal_text`, dentro do `check_all`). `lw-107c3-decisao-23-11.md` ainda não está no `main`; não li.
