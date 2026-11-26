# Pacote de decisão: aceites formais dos grupos A, B e D (26/11/2026)

Preparado em 26/11/2026 sobre o `main` f8a720c, com o CI do `main` verde (execução 45633727127). **Nenhuma tarefa foi marcada como aceita e o ROADMAP_STATUS não foi alterado: o aceite formal é de Arthur.** Esta é a versão curta e atualizada dos grupos A, B e D do [pacote de aceite 2](PACOTE_ACEITE_2.md) (23/11/2026), que segue valendo, sem mudança, para os grupos C, E, F e G (os que dependem da janela ou de decisão dele).

## Em uma tela
| Grupo | O que cobre | Testes refeitos hoje no `main` | Aceite sem olhar a janela? | Recomendação |
|---|---|---|---|---|
| **A** | LW-098b a 098g: o comerciante decide pelo lucro, a caravana compra, viaja e vende | 13 arquivos, **111 testes, 0 falhas** | **Sim** (tudo é lógica testada; nada aparece na tela) | **Aceitar** |
| **B** | LW-098h0a a 098h4: as ferramentas e correções que tornaram seguro ligar os comerciantes | 9 arquivos, **62 testes, 0 falhas** | **Sim**, **menos o critério de desempenho (9.15.4), que não é afirmado** | **Aceitar, registrando que o aceite de desempenho segue com você** |
| **D** | LW-107 sem tela: o ciclo das encomendas (aceitar, entregar, vencer, abandonar) na economia e na ponte | 18 arquivos, **123 testes, 0 falhas** | **Sim** (o que tem tela é o grupo E, à parte) | **Aceitar** |

**O que o aceite faz e não faz.** Registra no ROADMAP_STATUS que essas subtarefas estão formalmente aceitas. **Não muda o placar:** o roadmap conta tarefa numerada, e subtarefa com letra não entra; segue 98 de 192 (51,0%) e a Fase 3 em 11 de 30 (36,7%). A LW-098 só fecha com a 098h5 e a 098h6 (grupo C); a LW-107 só fecha com o grupo E e a decisão da 107c3.

## Conferência objetiva (26/11/2026): o que é plenamente elegível e o que depende de quê
| Classe | Itens | Por quê |
|---|---|---|
| **Plenamente elegíveis agora** (critério por teste, refeito no `main`; sem medição nova e sem janela) | **A:** 098b, 098c, 098d, 098e, 098f, 098g. **B:** 098h0a, 098h0, 098h1, 098h2, 098h4 (ferramentas, correção e testes) e as otimizações exatas 098h3a, 098h3b, 098h3c1 e 098h3c2 (critério: mesmas decisões e mesmos hashes, provado por teste). **D:** 107b1, 107b2, 107c1, 107c2a, 107c2b, 107d, 107f1, 107f2, 107f3, 107f5 e 107g | todos passam hoje (111, 62 e 123 testes, 0 falhas), nenhum hash muda, nada aparece na tela |
| **Dependem de DESEMPENHO** (medição em release, leitura sua) | o critério 9.15.4 da 098h (nenhum passo acima de 33 ms e no máximo 5 acima de 16,7 ms, "lido como aumento sobre a base") e, junto, a 098h5 e a 098h6 (grupo C) | a medição de 18/11 não afirma "atendido" nem "não atendido" (as faixas se sobrepõem e a base já passa do limite absoluto); **não impede aceitar as 9 subtarefas do B por teste** |
| **Dependem de VALIDAÇÃO VISUAL** (a janela; fora deste pacote) | grupo E (107e1, 107e2a, 107e2b, 107f4a a 107f4c e a interface de custo e margem da 107h), grupo F (LW-108), grupo G (ART-5b1 e ART-6a) e a LW-099 inteira (viagem visível: nada aceito) | só a janela prova que a tela está certa |
| **Dependem de DECISÃO sua** (nem janela nem medição) | 098h5 e 098h6 (a sustentabilidade da economia: `FoodStub` como resposta da Fase 3 ou LW-103 e LW-094), 107c3 (ligar o postador de encomendas) | são escolhas de design e de dados protegidos |

## Como eu verifiquei hoje
Reexecutei cada arquivo de teste dos três grupos no `main` f8a720c, **só em modo `--headless`**, um arquivo por vez. Resultado: **todos passam, nenhum falha, nenhum ficou pendente, nenhum erro de script.** O CI do `main` (a suíte inteira, `check_all`) está verde na mesma versão. **Não fiz:** nenhuma medição de desempenho nova, nada na janela e nenhuma regravação de valor de referência (nenhum hash muda por A, B ou D; DEC-175 intacta).

## Grupo A: LW-098b a 098g (comerciante e caravana)
- **Tarefas:** 098b a 098g (6 subtarefas, 10 PRs: #45, #46, #49 (já aprovado por você), #51, #52, #53, #58, #66, #72, #74).
- **Critério do roadmap (linha 788):** o comerciante só viaja com lucro esperado; chega, vende e o preço de destino cai; lucro e dinheiro passam pelo `Ledger`; conservação mantida.
- **Evidência (refeita hoje, 111 testes):** `test_trade_planner` (16: sem diferença de preço maior que spread, tempo e risco, não há plano), `test_economy_caravan_trip` (8), `_property` (1), `_route_state` (14), `_start` (10), `_save` (4), `_wiring` (6), `test_npc_merchant` (13: não viaja sem lucro, não oscila), `_arrival` (12), `_data` (12), `test_caravan_params` (6), `test_route_cost` (4), `test_caravan_book` (5).
- **Ressalvas (nenhuma impede o aceite):** a venda do comerciante nunca vende comida; o contrato 9.5 diz busca binária e o código usa varredura exata; lacunas de teste da 098g (tudo no backlog).
- **Sem janela?** Sim. **Recomendação: aceitar.**

## Grupo B: LW-098h0a a 098h4 (o preparo antes de ligar os comerciantes)
- **Tarefas:** 098h0a, 098h0, 098h1, 098h2, 098h3a, 098h3b, 098h3c1, 098h3c2 e 098h4 (9 subtarefas, 10 PRs: #117 a #125, #134, #135). Nada muda na tela: são o verificador que não confunde viagem com NPC travado, as colunas de comerciantes na medição, a emulação, a correção do pensador (a compra repetida dos 120 pães), os testes de "nada de comida infinita" e quatro otimizações exatas do planejador (mesmas decisões, mesmos hashes).
- **Critério (contrato 9.15.6, por teste):** as ferramentas e correções passam nos seus testes; os soaks com os comerciantes emulados e reais fecham.
- **Evidência (refeita hoje, 62 testes):** `test_npc_life_check_transit` (11), `test_measure_merchant_cells` (5), `test_merchant_emulation` (12), `test_npc_merchant_food` (6), `test_npc_haul_single_query` (3), `test_trade_quote_curve` (8), `test_trade_planner_memo` (9), mais o soak de emulação de 10 dias (1) e o de vida de 7 dias com os 6 comerciantes e 138 vivos (7).
- **Ressalva que continua aberta (o critério de desempenho 9.15.4: nenhum passo acima de 33 ms e no máximo 5 acima de 16,7 ms em 30 dias, lido como aumento sobre a base):** com os 6 comerciantes reais, em bateria, o soak de 30 dias foi de 43,6 s para 55,4 s (+27%) e o p99 do passo de 3,2 para 4,2 ms; passos acima de 33 ms: 2,7 em média na base e 5,3 com os reais, **com faixas que se sobrepõem, e a base sozinha já ultrapassa o limite absoluto em 2 de 3 execuções** (`docs/economia/medicao-098h5-real-18-11.md`). Eu não afirmo "atendido" nem "não atendido": **a leitura do critério é sua.**
- **Sem janela?** Sim, para tudo, **exceto o aceite de desempenho**, que continua em aberto (não é questão de olhar a tela e sim de medir em release com o Mac livre). **Recomendação: aceitar as 9 subtarefas e registrar, na mesma linha, que o aceite de desempenho da 9.15.4 segue com você.**

## Grupo D: LW-107 sem tela (encomendas)
- **Tarefas:** 107b1, 107b2, 107c1, 107c2a, 107c2b, 107d, 107f1, 107f2, 107f3, 107f5 e 107g (11 subtarefas, 11 PRs: #44, #47, #50, #56, #75, #77, #84, #104, #105, #108, #114; mais #98 e #144). Na prática: o jogador (na economia e na ponte) vê as encomendas, aceita (limite de 3), entrega e recebe; o prazo vencido devolve o dinheiro ao emissor; abandonar não tem multa e pede confirmação.
- **Critério do roadmap (linha 797):** teste de integração: aceitar, transportar e entregar paga a recompensa; falhar devolve a custódia ao emissor; texto por chaves.
- **Evidência (refeita hoje, 123 testes):** `test_contract_cycle` (8) e `_poster` (6), `test_bridge_player_contracts` (11), `test_bridge_contract_abandon` (11), `test_contract_abandon` (16), `test_contract_limits_data` (10), `test_contract_templates_data` (10), `test_contract_poster` (8) e 4 arquivos do postador (3, 1, 1, 1), `test_contract_poster_residual_profit` (1), `test_contracts_view_model` (14) e `_abandon` (6), `test_contract_voluntary_world` (2), mais `test_contract_expiry` (6) e `test_contract_dead_issuer_custody` (8), que provam o "falhar devolve". "Texto por chaves" é regra do `check_literal_text`, que roda no `check_all` (verde).
- **Ressalvas:** o postador está **desligado** (`contract_templates.json` é `[]`): sem a decisão da LW-107c3 o jogo real não tem encomendas, e **a LW-107 só fecha no placar com essa decisão e com o grupo E**; não há poda de contratos terminados (cerca de 1,6 mil por ano de jogo, [HIP]). A tela das encomendas (grupo E, mais a interface de custo e margem da 107h, integrada em 24/11) nunca foi vista na janela: **não faz parte deste aceite.**
- **Sem janela?** Sim. **Recomendação: aceitar.**

## Frase de aceite pronta (copie, ajuste ou recuse)
"APROVADO LW-098b a 098g; APROVADO LW-098h0a a 098h4 (o aceite de desempenho da 9.15.4 segue comigo); APROVADO as subtarefas da LW-107 sem tela: 107b1, 107b2, 107c1, 107c2a, 107c2b, 107d, 107f1, 107f2, 107f3, 107f5 e 107g."
Com ela, o Maestro registra o aceite no ROADMAP_STATUS e na fila em um PR de documentos (classe 1, CI verde), sem mexer em contagem nem em valor de referência.

## O que isso abre, e o que continua dependendo de você
- **LW-098 (placar +1 quando fechar):** falta o grupo C (098h5 e 098h6). A sustentabilidade alimentar que o bloqueava foi tratada pela regra da refeição (o soak de 30 dias passa), mas a economia SEM o `FoodStub` segue colapsando no dia 30 (LW-094 aberta). Saída 1 (recomendada no pacote de 23/11): fechar depois da LW-094; saída 2: você declara que fecha agora com a ressalva. **Decisão que destrava o caminho crítico (fila):** aceitar o `FoodStub` como resposta da Fase 3 (a sustentabilidade vai à Fase 4) ou abrir a LW-103 e a LW-094 com contrato.
- **098h6 (nova medição de 30 dias em 3 sementes, só `--headless`):** posso rodar assim que você mandar; é a última medição que falta para a LW-098. Sem ela, nada é inventado.
- **LW-107 (placar +1 quando fechar):** falta o grupo E (14 itens, 15 a 20 min na janela) e a decisão da 107c3.
- **LW-108 e as praças B e C (grupos F e G):** dependem da janela. Nada disso muda por este pacote.
