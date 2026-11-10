# Relatório de fechamento da Fase 2 (LW-086)

**Escrito em 10/11/2026 (horário de Brasília): o rascunho na LW-086a e o fechamento na LW-086, depois da assinatura de Arthur.** Segue o formato de `docs/fase-1/LW-054-relatorio-de-fechamento.md`. O roteiro que ele seguiu está em `docs/fase-2/LW-086-roteiro-para-arthur.md`. Rótulos: **fato** (com origem), **[HIP]** (valor de trabalho), **decisão** (de Arthur), **proposta**, **pendente**.

## 1. RESUMO
A Fase 2 ("primeira sociedade") entregou NPCs que **vivem sozinhos** (necessidades, rotina por ofício, decisão por utilidade, relações e memória nos notáveis), ganham **corpo** quando você chega perto, podem ser **vistos por dentro** no painel de depuração e **conversam** com você. Não há dinheiro, mercado nem facções: só dois provisórios marcados `TEMP`. **Placar:** **32 de 32 tarefas concluídas (100%)** e **87 de 192 do projeto (45,3%)**. A **LW-085** foi aprovada por Arthur em 10/11/2026 e a **LW-086 foi assinada por ele em 10/11/2026, por escrito, "com a ressalva de janela mais prova automática"** (como na Fase 1). **A Fase 2 fecha COM RESSALVA nos três critérios parciais de 2.F, por decisão dele, e as três estão com todas as letras na seção 4:** (1) critério 2: os picos acima de ~10 ms ficam **informativos**; (2) critério 3: o teleporte e os quadros fecham **pela janela dele**, sem teste automático do teleporte; (3) critério 8: "ofício novo só por JSON" não tem teste e vira uma **tarefa pequena só de teste antes da LW-093 (a LW-093b)**. A tag `fase-2-concluida` foi **autorizada por ele na mesma mensagem** e criada no commit final desta fase (`git rev-parse fase-2-concluida`).

## 2. NÚMEROS DA FASE (fatos)
- **Git, de `fase-1-concluida` (`ac4c61f`, 07/11/2026) até `origin/main` antes do commit de status desta fase (`9dbcebc`, 10/11/2026):** 169 commits; `git diff --shortstat`: **446 arquivos alterados, 36.633 linhas acrescentadas e 387 removidas** (inclui documentos, dados e testes). Em `src/`: 131 arquivos `.gd` e 15.651 linhas, das quais **7.551 no módulo `npc`** (medido com `git ls-files` e `cat`).
- **Testes:** **1.194 testes (124 scripts, 261.693 asserts)**; no fechamento da Fase 1 eram **471**. `tools/check_all` no `main` `9dbcebc` (10/11/2026): **VERDE**, 124 scripts, 1.194 testes (todos passando), 261.693 asserts, 313 scripts sem aviso de compilação e 0 erros de script. O "Warnings 1 / Deprecated 1" do GUT já existia antes (`wait_frames` desde a LW-020/021; backlog).
- **Decisões:** DEC-122 (corpos e navegação, "por ora"), DEC-123 (direção P3), DEC-124 (velocidade 500 cm/min), DEC-125 (painel de depuração) e, da revisão da LW-085, **DEC-126** (tamanho de arquivo e de tarefa: só código, folga de 1,5×), **DEC-127** (`save_version` em 2 até o "save congelado") e **DEC-128** (as cinco ações de entrada da 082g), as três **APROVADAS** e no `DECISIONS.md`; mais os registros técnicos 0009 (SP2), 0010 (soak de 1 ano) e 0011 (revisão).
- **Medições (LW-084, 10/11/2026):** 300 NPCs por 1 ano em 8 execuções: 300 vivos, 0 mortes, 0 erro de `validate()`, mesmo hash dentro de cada padrão; memória estática +1,9 MiB só nos primeiros 30 dias; save ~20 KiB comprimido; passo médio 2,3 a 2,7 ms (depuração) e 1,75 a 1,87 ms (release).

## 3. O QUE A FASE ENTREGOU (entregáveis de 2.C, estado de hoje)
| # | Entregável | Estado | Onde |
|---|---|---|---|
| 1 | Contratos do `npc`, extensão do `world` e `docs/events.md` | Feito | LW-055; `docs/modules/npc.md`, `docs/events.md` |
| 2 | Assentamentos e locais no `world` | Feito (2 povoados de teste, 38 locais, 36 com caixa na tela em 4 cores; os 2 `market_reserved` não têm caixa) | LW-056 e LW-074 |
| 3 | Módulo `npc`: estado T1/T2, necessidades, ações em dados, executor, rotinas, decisão por utilidade, fila de pensamento e rastro | Feito | LW-057 a LW-064 |
| 4 | População por dados e ofícios | Feito (100 NPCs, 5 ofícios) | LW-067 e LW-068 |
| 5 | LOD S1/S0, Intents, `NpcView` em pool com navegação, detector de impasse e SP2 | Feito; navegação reta (N1, DEC-122 "por ora") | LW-069 a LW-073 |
| 6 | Notáveis (T2): promoção, memória, relações, ações sociais | Feito | LW-077 a LW-080 |
| 7 | Personalidade, alarme e consequências de necessidade crítica | Feito | LW-076 e LW-081 |
| 8 | Painel de depuração de NPC e caixas dos locais | Feito; **visto na janela por Arthur em 10/11/2026** (item 3 OK; abriu com Tab) | LW-082 e LW-074 |
| 9 | Interação do jogador com NPC (conversar) | Feito; **vista na janela por Arthur em 10/11/2026** (item 5 OK: para e conversa; depois reconhece) | LW-083 |
| 10 | `FoodStub` e `IncomeStub` marcados `TEMP` | Feito; Anexo D com remoção nas LW-094 e LW-095 | LW-065 e LW-066 |
| 11 | Testes de vida, equivalência, soak de 1 ano, relatório de revisão e checklist | Feito; validação assinada (LW-086) | LW-068, LW-075, LW-084, LW-085 e LW-086 |

## 4. CRITÉRIOS DE ACEITAÇÃO 2.F E DEFINIÇÃO DE CONCLUÍDO 2.J

**Critérios 2.F** (`docs/DEVELOPMENT_ROADMAP.md`, 2.F), no fechamento. **Três deles fecham COM RESSALVA, por decisão de Arthur (10/11/2026, por escrito); cada ressalva está escrita por inteiro na última coluna.**
| # | Critério | Estado no fechamento | Ressalva (decisão de Arthur) |
|---|---|---|---|
| 1 | Vida sem jogador: 100 NPCs por 30 dias e 300 por 1 ano, sem exceção, sem travado, todos vivos, mesmo resultado por semente | **Cumprido.** `run_npc_life_30d`: vivos no mínimo 100, maior tempo parado 0 min, hash `d13b921112ce` ×3 (de novo na passada de hoje); LW-084: 300 vivos, 0 mortes, hash repetido | Nenhuma (os 300 NPCs são [HIP], DEC-040 PENDENTE) |
| 2 | Desempenho: tick médio no orçamento; sem pico acima de ~10 ms; sem crescimento de memória em 1 ano | **Cumprido COM RESSALVA.** Média 2,3 a 2,7 ms (depuração) e 1,75 a 1,87 ms (release) contra ~3 ms [HIP, DEC-071 PROPOSTA]; **memória estável** (+1,9 MiB só até o dia 30). **Picos acima de ~10 ms existem** (0,1% a 0,4% dos passos; em release, inconclusivo contra o laço de controle) | **RESSALVA 1: os picos acima de ~10 ms ficam INFORMATIVOS** (não reprovam o critério). A régua de memória definitiva (0,5 MiB entre o dia 30 e o 360, proposta da B) segue em aberto (seção 7, item 6) |
| 3 | LOD sem defeitos: 100 cruzamentos sem duplicar (corpos = NPCs em S0), sem teleporte, meta de quadros | **Cumprido PELA JANELA DE ARTHUR, COM RESSALVA.** Duplicar e sumir têm teste (corpos = S0 a cada passo; 100 entradas e saídas). Na janela (10/11/2026): item 2 OK (\"sem duplicar, sumir perto nem teleportar\"); **P1 fluido, P2 a câmera não treme, P3 NPCs fluidos, nenhum saltou nem ficou preso** | **RESSALVA 2: o teleporte e os quadros fecham PELA JANELA DELE.** **Não há teste automático permanente do teleporte** (só o spike SP2, descartável, que achou zero). A causa dos trancos do SP2 (3 de 13 ensaios fora da régua da DEC-119) segue sem causa; a DEC-122 vale \"por ora\" |
| 4 | Equivalência: ação em S1 e em S0 com o mesmo efeito | **Cumprido.** `test_action_equivalence.gd` (4 testes, 380 asserts) | Nenhuma |
| 5 | Explicabilidade: o painel mostra por que o NPC escolheu a ação | **Cumprido.** `test_decision_trace.gd`, painel e ponte; **na janela, item 3 OK** (marcou 3 NPCs e entendeu o porquê de cada um) | Nenhuma |
| 6 | Personalidade: mesmo cenário, NPCs diferentes reagem diferente, de forma repetível | **Cumprido.** `test_alarm.gd` (11 testes); **prova automática aceita por Arthur** (item 4) | Nenhuma |
| 7 | Notáveis: conversar promove a T2; memória e relação sobrevivem a salvar e recarregar; limite global de T2 | **Cumprido.** `test_player_npc_talk.gd` e `test_npc_tiers.gd` (o mundo real aceita 40 e recusa o 41º); **na janela, item 5 OK** (para e conversa; depois reconhece) | Nenhuma |
| 8 | Dados: adicionar uma ação ou um ofício só editando JSON funciona e é validado | **Cumprido COM RESSALVA.** **Ação: provado** (`test_a_new_action_added_only_by_data_passes_validation`). **Ofício: não há teste** que adicione um ofício novo só por JSON e faça um NPC viver com ele | **RESSALVA 3: \"ofício novo só por JSON\" vira uma TAREFA PEQUENA SÓ DE TESTE antes da LW-093 (a LW-093b)**, que a conversa A registra no roadmap na LW-087a (conferido em 10/11/2026: ainda não está no `DEVELOPMENT_ROADMAP.md` nem no status) |
| 9 | Provisórios: `FoodStub` e `IncomeStub` existem, marcados `TEMP`, listados no Anexo D | **Cumprido** (Anexo D, linhas dos dois, remoção na LW-094 e LW-095) | Nenhuma |
| 10 | `check_all` e `check_architecture` verdes | **Verde.** `tools/check_all` no `main` `9dbcebc` (o commit de status desta fase só acrescenta documentos): **VERDE**, 124 scripts, **1.194 testes (todos passando)**, 261.693 asserts, 313 scripts sem aviso de compilação e 0 erros de script (170 s de testes). O "Warnings 1 / Deprecated 1" do GUT já existia (`wait_frames` desde a LW-020/021; backlog). O `check_all` no HEAD final consta do relatório da tarefa | Nenhuma |

**Definição de concluído 2.J:**
| # | Condição | Estado no fechamento |
|---|---|---|
| 1 | As 32 tarefas concluídas | **32 de 32**: a LW-085 aprovada e a LW-086 assinada, ambas em 10/11/2026 |
| 2 | Critérios de 2.F cumpridos | **7 cumpridos e 3 cumpridos COM RESSALVA** (2, 3 e 8), por decisão de Arthur (tabela acima) |
| 3 | REV (LW-085) e VAL (LW-086) aprovadas, sem achado crítico aberto | **LW-085: aprovada em 10/11/2026, nenhum achado crítico aberto. LW-086: assinada em 10/11/2026, com a ressalva de janela mais prova automática** |
| 4 | Decisão do SP2 registrada | **Feita**: DEC-122 APROVADA \"por ora\", DEC-123 (direção), DEC-124; registro 0009. Arthur aceitou o \"por ora\" e **observou a fluidez na janela** (P1 a P4 sem problema) |
| 5 | `FoodStub` e `IncomeStub` no Anexo D com tarefa de remoção | **Feita** (remoção nas LW-094 e LW-095) |
| 6 | Tag `fase-2-concluida` no remoto | **Autorizada por Arthur em 10/11/2026** (só essa tag, no commit final do `main`, depois do `check_all` verde e da fase em 32 de 32) e **criada no commit final desta fase**; tag leve, como as da Fase 0 e da Fase 1. O hash: `git rev-parse fase-2-concluida` |
| 7 | Status em 100% para a fase | **100% (32 de 32)** no `ROADMAP_STATUS.md` e no `README.md` |

## 5. RESPOSTAS DE ARTHUR À CHECKLIST 2.H (LW-086)
**Assinatura (Arthur, 10/11/2026, Brasília, por escrito):** \"LW-086 assinada, com a ressalva de janela mais prova automática.\"

**Passada na janela:** feita por Arthur em 10/11/2026, de cerca de 19:00 a 20:10 (relato dele; o roteiro estimava cerca de 13 minutos para a sessão, uma conta e não uma medição). As respostas abaixo são as palavras dele, sem acréscimo.

| Item | Resposta de Arthur |
|---|---|
| 1 | **OK** (viu sair, trabalhar, comer, conversar e dormir) |
| 2 | **OK** (sem duplicar, sumir perto nem teleportar) |
| 3 | **OK.** Na 1ª tentativa o F3 não abriu o painel porque, no Mac, F3 é o Mission Control; com Tab abriu; marcou 3 NPCs e entendeu o porquê de cada um |
| 4, 6 e 7 | **Aceita a prova automática:** alarme 11/11; 30 dias ×3 com o mesmo hash; comida a zero 17/17 e 19/19 |
| 5 | **OK** (para e conversa; depois reconhece) |
| 8 | **OK** (nada de dinheiro, loja, mercado, inventário, facção ou lei) |
| 9 | **Sim**, agradável para continuar |
| P1 | fluido |
| P2 | a câmera não treme |
| P3 | NPCs fluidos, nenhum saltou nem ficou preso |
| P4 | não notou tranco com o painel aberto |

**Decisões de Arthur para o fechamento (por escrito, valem só para a LW-086):**
- **(a)** Fechar a Fase 2 **COM RESSALVA nos 3 critérios parciais de 2.F:** os picos acima de ~10 ms (critério 2) ficam **informativos**; o teleporte e os quadros (critério 3) fecham **pela janela dele**; \"ofício novo só por JSON\" (critério 8) vira **tarefa pequena só de teste antes da LW-093** (a LW-093b, que a conversa A registra no roadmap na LW-087a).
- **(b)** **Autorizou a criação e o envio da tag `fase-2-concluida`**, só essa tag, no commit final do `main`, depois do `check_all` verde e de a Fase 2 estar em 32 de 32 no `main`, sem `--force`.

**Conferência por comando do que a prova automática mostra hoje** (provas aceitas pelos itens 4, 6 e 7; as demais estão no roteiro, seção 6): `test_alarm.gd` 11/11; `run_npc_life_30d` com o hash `d13b921112ce` nas 3 linhas; `test_critical_need.gd` 17/17 e `test_food_stub.gd` 19/19 (todas executadas em 10/11/2026, antes da passada dele; ver o roteiro).

**O que a passada mostrou além do checklist:** o roteiro dizia F3 para abrir o painel e, no Mac, F3 sozinho abre o Mission Control. O roteiro, o README, `app.md` e `tools.md` passaram a dizer Tab (ou fn+F3). **A dica escrita no próprio painel (`data/text/pt_br.json`, chave `tools.npc_inspector.hint`) ainda diz \"F3 ou Tab fecha\":** é texto do jogo, ficou no `docs/backlog.md`, e **nenhum código nem dado do jogo foi alterado**; também citam F3 comentários de `src/app/input_actions.gd` e de `src/tools/npc_inspector/npc_inspector_panel.gd` e dois testes (a tecla ligada segue sendo F3).

## 6. RETROSPECTIVA (em fatos)
**O que deu certo**
- **Contrato primeiro e spike antes da apresentação:** a LW-055 fixou contratos e eventos antes do código; o SP2 (LW-071) decidiu navegação e relógio contra corpo (DEC-122 a DEC-124) antes do `NpcView` definitivo.
- **O oráculo de 9 impressões digitais** (LW-081a) deixou dividir o `npc_module.gd` em cinco classes **sem mudar o comportamento**, e a **equivalência S1 × S0** (LW-075) deixou os dois modos usarem a mesma função de efeitos. O hash de 30 dias (`d13b921112ce`) ficou o mesmo por **várias junções seguidas**.
- **Dados em JSON:** uma ação nova entra só por dados e é validada.
- **Painel de depuração** (rastro, memórias, relações) tornou o comportamento **legível** antes de ajustar qualquer peso.
- **Revisão cruzada de leitura (A e C) + correção no mesmo dia:** 0 achados bloqueantes de código; a ponte passou a citar só a `api/` e ganhou regra automática (085a), o cruzamento impasse × conversa ganhou teste (085b) e os documentos foram alinhados ao código (085d).
- **Soak de 1 ano com 300 NPCs** limpo: 0 mortes, memória estável, hash repetível.

**O que não deu certo**
- **Arquivos acima do limite:** `npc_module.gd` com 620 linhas (346 de código) e `npc_thinker.gd` com 455 (328). Tema que **já tinha aparecido na Fase 1** (I3 e M1). Resolvido por decisão sua: contar só código, folga 1,5× (registro 0011); registrado como **DEC-126** e o `AGENTS.md` (versão 0.4) já diz isso.
- **A ponte citou classes internas do `npc` sem nenhuma verificação automática** e só a revisão viu; a regra D nasceu na 085a, **depois** do problema. **Lição:** a verificação nasce junto do contrato.
- **Faltava um teste de cruzamento** (impasse × conversa) e a minha primeira premissa para ele estava errada (a sequência de vencimentos não começa na conversa: sem resposta do corpo a fome sobe e o NPC troca a ação por decisão). Só a execução mostrou.
- **O custo do painel só foi medido na revisão** (085c): o resumo a cada 1 s chama o `validate()` do mundo e com 300 NPCs dá ~20 ms por chamada (quadro de ~24 ms uma vez por segundo, só com o painel aberto).
- **Quadros do SP2 e da LW-072 não ficaram no repositório;** 3 de 13 ensaios fora da régua e a causa dos trancos ficou aberta. Aceito "por ora".
- **Muitos valores [HIP]:** 300 NPCs (DEC-040 PENDENTE), ~3 ms (DEC-071 PROPOSTA), 80 e 120 m de LOD, 50 corpos, 24 memórias e 16 relações por NPC, intervalos do painel.
- **Documentos do "estado atual" ficaram para trás:** `events.md` falava de ouvintes que não existiam, o README dizia que o jogo nascia à meia-noite (era 05:45 desde a LW-042b) e o índice de contratos não listava o `tools.md`.
- **Trabalho em várias conversas ao mesmo tempo, com um Mac só:** medições com ruído (B) e conflitos em `backlog.md` e `ROADMAP_STATUS.md`; resolvidos com regras (um Godot pesado por vez; linhas novas no meio do arquivo).
- **O painel e a conversa só foram vistos na janela na LW-086** (Arthur, 10/11/2026): até lá só tinham teste. **E o roteiro dizia F3 para abrir o painel, que no Mac é o Mission Control:** o painel abriu com Tab (relato de Arthur); a dica escrita no jogo ainda diz F3 (backlog). Conferir as teclas no Mac antes de escrever o roteiro teria evitado.
- **Teste que parece rodar e não roda** (lição da Fase 1) **voltou:** um teste solto não imprimiu nada porque o cache de importação do Godot era mais velho que o arquivo; resolvido com `--import`.

**Lições**
1. Criar a **verificação automática junto do contrato** (como a regra D da porta `api/`).
2. **Medir o custo das ferramentas de depuração** na tarefa que as cria, não na revisão.
3. A tarefa que cria o **segundo** lado de um cruzamento (impasse × conversa) traz o **teste de cruzamento**.
4. **Atualizar README, `events.md` e índices na própria tarefa**, não na revisão.
5. **Guardar os números de quadros** (e o hardware) em `docs/decisions/`.
6. Linhas novas de backlog **no meio** do arquivo, não no fim.
7. Depois de atualizar a pasta, rodar `godot --headless --path . --import` **antes** de testes soltos; e "passou" só com `All tests passed`.
8. **Conferir no Mac as teclas que o roteiro manda apertar** (F3 abre o Mission Control; Tab ou fn+F3 funcionam).
9. **A estimativa de tempo da janela foi uma conta, não uma medição:** o roteiro dizia cerca de 13 minutos e a passada foi registrada de cerca de 19:00 a 20:10; na próxima fase, pedir o tempo real e usar na seguinte.

## 7. O QUE PRECISA SER DECIDIDO ANTES DA FASE 3 (estado depois da assinatura)
| # | Assunto | Estado | Recomendação ou o que falta |
|---|---|---|---|
| 1 | **Ids de conteúdo em dados** (`"work"` em 3 arquivos, `"help"` em 2, `"flee"`, `"sleep"`, `"talk_player"`...; alcance e cooldown da conversa em constantes) | **Aberto** (no backlog) | Uma **conferência de dados** barata (cada id de constante tem de existir no catálogo) antes da LW-087; mover alcance e cooldown para `data/npc_params.json` |
| 2 | **Tipos da `api/`** (retornos de `explain_decision`, `peek_memories` e `peek_routine_action` ainda de tipo interno; `peek_npc_bodies` lê o membro público `lod`) | **Aberto** (no backlog, 085a) | Fazer **antes** de a Fase 3 acrescentar consultas à ponte |
| 3 | **Saturação das memórias dos notáveis:** em 1 ano os 40 T2 chegam a 24 de 24 memórias, 8 a 16 de 16 relações e **0 traços permanentes** (o limiar 80 nunca é atingido) | **Aberto** (medido na LW-084) | Aceitar a saturação (o desenho esquece por valor), mas **rever o limiar de traços (80)** antes de a Fase 3 depender de reputação |
| 4 | **`FoodStub` e `IncomeStub`:** LW-094 remove o `FoodStub` (o estoque dele **está no save**) e a LW-095 o `IncomeStub` | **DECIDIDO por Arthur em 10/11/2026** (mensagem da LW-087c): remoção na LW-094 (parte 094b) e na LW-095; `mint` inicial na LW-093; **não se congela o save** e a LW-111 rejeita save antigo com mensagem clara; `check_temp` fora de `docs/`. O plano está no **rascunho da LW-087c** (ramo `lw-087c-extensoes-world-npc`, fora do `main`) | **Falta:** registrar no `DECISIONS.md` (ainda não está) e **autorizar por escrito** a remoção dos testes dos provisórios no texto da LW-094b e da LW-095 (AGENTS 9.5) |
| 5 | **`save_version` em 2 e \"save congelado\"** | **DECIDIDO: DEC-127 (APROVADA)**: `save_version` fica em 2 até o \"save congelado\"; DEC-083 e DEC-084 seguem como estão | Fixar o número final e a política antes do congelamento (proposta: depois da validação da Fase 4) |
| 6 | **Régua de memória** (0,5 MiB entre o dia 30 e o 360, proposta da B) e **régua de picos** (~10 ms) | **Picos: DECIDIDO** (informativos, ressalva 1). **Memória: aberto** | Aprovar a régua de memória; medir picos em release com laço de controle intercalado |
| 7 | **Custo do painel:** resumo de 1 s para ~5 s [HIP] ou `validate()` só sob demanda (proposta da 085c) | **Aberto.** Na janela, com os 100 NPCs do jogo, Arthur **não notou tranco** com o painel aberto (P4) | Mudar para ~5 s (uma linha) quando mexer no painel |
| 8 | **SP2 \"por ora\" (DEC-122):** navegação reta que atravessa pedra e casa; caminhada em S0 atrasa em relação a S1 | **Fechado pela janela** (ressalva 2): P1 a P3 sem problema | Reabrir só se voltar tranco; navegação com desvio entra na Fase 3 ou depois |
| 9 | **DEC-040** (quantidade de NPCs, PENDENTE) e **DEC-071** (orçamento, PROPOSTA) | **Pendentes** | Decidir junto da primeira medição de economia (Fase 3) |
| 10 | **AGENTS 4.5 e 5.2** (contar só código, folga de 1,5×) e a **entrada no `DECISIONS.md`** com as decisões do 0011 | **FEITO** (LW-085e): `AGENTS.md` versão 0.4 e **DEC-126, DEC-127 e DEC-128** APROVADAS | Nada |
| 11 | **Ofício novo só por JSON** (2.F, critério 8): sem teste | **DECIDIDO** (ressalva 3): tarefa pequena só de teste, a **LW-093b**, antes da LW-093 | A conversa A registra a LW-093b no roadmap na LW-087a (hoje ainda não está) |

## 8. PENDÊNCIAS E RESSALVAS ABERTAS
- **Ressalvas de fechamento (decisão de Arthur, seção 4):** (1) picos acima de ~10 ms **informativos**; (2) teleporte e quadros fechados **pela janela dele**, sem teste automático do teleporte; (3) \"ofício novo só por JSON\" **sem teste** até a **LW-093b**.
- **LW-093b:** a conversa A a registra no roadmap na LW-087a; **hoje não consta** no `DEVELOPMENT_ROADMAP.md` (arquivo protegido) nem no status.
- **Registro no `DECISIONS.md` (ainda pendente, é de Arthur):** DEC-047, DEC-049 e DEC-054 seguem como PROPOSTA no arquivo (ele as aprovou em 10/11/2026) e a entrada com a escala e as regras do protótipo da Fase 3.
- **Texto do jogo:** a dica do painel ainda diz \"F3 ou Tab fecha\" (`data/text/pt_br.json`); no backlog; decisão de Arthur.
- **Divergências do roadmap com decisões dele** (arquivo protegido; a mudança é dele): a linha da LW-097 não cita o evento nem o comando de fechar rota; a LW-111 diz que o save \"migra\" e a decisão é \"rejeita\"; a LW-114 diz \"no repositório\" e a decisão exclui `docs/`; o `mint` inicial está na LW-095 no roadmap e na LW-093 na decisão.
- **Rascunhos da Fase 3** (ramos `lw-087b-contrato-economy`, `lw-087c-extensoes-world-npc` e `lw-087d-eventos-e-dados`): **não estão no `main`**; a Fase 3 só começa quando Arthur mandar.
- **Tag `fase-2-concluida`:** criada no commit final desta fase. Na Fase 1 houve um commit seguinte, \"registro da tag\", que escreveu o hash no status; aqui o hash não está nos documentos (a tag aponta para o commit que os contém): se Arthur quiser o registro, é um commit só de documentos, que deve ser pedido.

## 9. PRÓXIMO PASSO
A **Fase 2 está fechada** (32 de 32, com as três ressalvas). Nada da Fase 3 foi iniciado nem entra no `main` antes da ordem de Arthur: o primeiro passo é a **LW-087a** (as respostas às perguntas de design dos rascunhos e a lista dos 10 bens), seguida pelas decisões da seção 7 que seguem abertas (itens 1, 2, 3, 6, 7 e 9) e pelo registro da LW-093b no roadmap.
