# Relatório de fechamento da Fase 2 (LW-086) — RASCUNHO

**Rascunho escrito em 10/11/2026 (horário de Brasília), na LW-086a.** Ainda **não** é o relatório final: ele só vira final depois da LW-085 aprovada e da sua validação (LW-086). Segue o formato de `docs/fase-1/LW-054-relatorio-de-fechamento.md`. O roteiro do que você faz está em `docs/fase-2/LW-086-roteiro-para-arthur.md`. Rótulos: **fato** (com origem), **[HIP]** (valor de trabalho), **proposta**, **pendente**.

## 1. RESUMO (rascunho)
A Fase 2 ("primeira sociedade") entregou NPCs que **vivem sozinhos** (necessidades, rotina por ofício, decisão por utilidade, relações e memória nos notáveis), ganham **corpo** quando você chega perto, podem ser **vistos por dentro** no painel de depuração e **conversam** com você. Não há dinheiro, mercado nem facções: só dois provisórios marcados `TEMP`. **Placar de hoje:** **31 de 32 tarefas concluídas (96,9%)** e **86 de 192 do projeto (44,8%)**: a **LW-085** foi **aprovada por você em 10/11/2026**; falta a **LW-086** (esta validação). Aprovada ela: **32 de 32 (100%)** e **87 de 192 (45,3%)**. A tag `fase-2-concluida` **só com a sua autorização**.

## 2. NÚMEROS DA FASE (fatos)
- **Git, de `fase-1-concluida` (`ac4c61f`, 07/11/2026) até `origin/main` (`d1b0fa2`, 10/11/2026):** 156 commits; `git diff --shortstat`: **443 arquivos alterados, 36.240 linhas acrescentadas e 380 removidas** (inclui documentos, dados e testes). Em `src/`: 131 arquivos `.gd` e 15.651 linhas, das quais **7.551 no módulo `npc`**.
- **Testes:** **1.194 testes (124 scripts, 261.693 asserts)** no `check_all` verde da LW-085c (B, no `main` `d1b0fa2`); no fechamento da Fase 1 eram **471**. **No HEAD da LW-086a (`3fc9a04`, só documentos a mais):** `tools/check_all` **VERDE**, 124 scripts, 1.194 testes (todos passando), 261.693 asserts, 313 scripts sem aviso de compilação e 0 erros de script (3 min 31 s). O "Warnings 1 / Deprecated 1" do GUT já existia antes (`wait_frames` desde a LW-020/021; backlog).
- **Decisões:** DEC-122 (corpos e navegação, "por ora"), DEC-123 (direção P3), DEC-124 (velocidade 500 cm/min), DEC-125 (painel de depuração), mais os registros técnicos 0009 (SP2), 0010 (soak de 1 ano) e 0011 (revisão: três decisões suas).
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
| 8 | Painel de depuração de NPC e caixas dos locais | Feito (painel "concluída com ressalva": falta a sua passada na janela) | LW-082 e LW-074 |
| 9 | Interação do jogador com NPC (conversar) | Feito (falta a sua passada na janela) | LW-083 |
| 10 | `FoodStub` e `IncomeStub` marcados `TEMP` | Feito; Anexo D com remoção nas LW-094 e LW-095 | LW-065 e LW-066 |
| 11 | Testes de vida, equivalência, soak de 1 ano, relatório de revisão e checklist | Feito, menos a validação (LW-086) | LW-068, LW-075, LW-084 e LW-085 |

## 4. CRITÉRIOS DE ACEITAÇÃO 2.F E DEFINIÇÃO DE CONCLUÍDO 2.J

**Critérios 2.F** (`docs/DEVELOPMENT_ROADMAP.md`, 2.F). Estado de hoje e o que falta:
| # | Critério | Estado de hoje | O que falta |
|---|---|---|---|
| 1 | Vida sem jogador: 100 NPCs por 30 dias e 300 por 1 ano, sem exceção, sem travado, todos vivos, mesmo resultado por semente | **Cumprido.** `run_npc_life_30d`: vivos no mínimo 100, maior tempo parado 0 min, hash `d13b921112ce` ×3; LW-084: 300 vivos, 0 mortes, hash repetido | Nada (os 300 NPCs são [HIP], DEC-040 PENDENTE) |
| 2 | Desempenho: tick médio no orçamento; sem pico acima de ~10 ms; sem crescimento de memória em 1 ano | **Parcial.** Média 2,3 a 2,7 ms (depuração) e 1,75 a 1,87 ms (release) contra ~3 ms [HIP, DEC-071 PROPOSTA]; **memória estável** (+1,9 MiB só até o dia 30). **Picos acima de ~10 ms existem** (0,1% a 0,4% dos passos; em release, inconclusivo contra o laço de controle) | **Decisão sua:** você já decidiu que os picos são só informativos; falta registrar isso no critério ou aceitar o "parcial". Régua de memória definitiva (0,5 MiB entre o dia 30 e o 360, proposta da B) |
| 3 | LOD sem defeitos: 100 cruzamentos sem duplicar (corpos = NPCs em S0), sem teleporte, meta de quadros | **Parcial.** Duplicação e sumiço têm teste (corpos = S0 a cada passo, 100 entradas e saídas); **teleporte só no spike SP2** (zero) e **quadros**: 3 de 13 ensaios fora da régua da DEC-119, causa dos trancos aberta | **A sua passada na janela (itens 2 e P1 a P3)**; a DEC-122 vale "por ora" (você aceitou) |
| 4 | Equivalência: ação em S1 e em S0 com o mesmo efeito | **Cumprido.** `test_action_equivalence.gd` (4 testes, 380 asserts) | Nada |
| 5 | Explicabilidade: o painel mostra por que o NPC escolheu a ação | **Cumprido nos testes** (`test_decision_trace.gd`, painel e ponte) | **A sua passada** (item 3) |
| 6 | Personalidade: mesmo cenário, NPCs diferentes reagem diferente, de forma repetível | **Cumprido.** `test_alarm.gd` (11 testes) | Nada |
| 7 | Notáveis: conversar promove a T2; memória e relação sobrevivem a salvar e recarregar; limite global de T2 | **Cumprido.** `test_player_npc_talk.gd` e `test_npc_tiers.gd` (o mundo real aceita 40 e recusa o 41º) | **A sua passada** (item 5) |
| 8 | Dados: adicionar uma ação ou um ofício só editando JSON funciona e é validado | **Parcial.** **Ação: provado** (`test_a_new_action_added_only_by_data_passes_validation`). **Ofício: não achei teste** que adicione um ofício novo só por JSON e faça um NPC viver com ele (as tabelas de ofício, rotina e população são lidas e validadas de `data/`, mas sem esse cenário) | Decidir: aceitar o parcial ou pedir um teste curto (uma tarefa pequena, só teste) |
| 9 | Provisórios: `FoodStub` e `IncomeStub` existem, marcados `TEMP`, listados no Anexo D | **Cumprido** (Anexo D, linhas dos dois, remoção na LW-094 e LW-095) | Nada |
| 10 | `check_all` e `check_architecture` verdes | **Verde** (1.194 testes; regra D nova na 085a) | Refazer no HEAD final |

**Definição de concluído 2.J:**
| # | Condição | Estado de hoje | O que falta |
|---|---|---|---|
| 1 | As 32 tarefas concluídas | **31 de 32** | LW-086 (validar) |
| 2 | Critérios de 2.F cumpridos | **7 cumpridos, 3 parciais** (2, 3 e 8) | A sua passada na janela (3), a decisão sobre picos (2) e sobre o ofício por JSON (8) |
| 3 | REV (LW-085) e VAL (LW-086) aprovadas, sem achado crítico aberto | **LW-085: aprovada por você em 10/11/2026, achados críticos abertos: nenhum.** LW-086: **não feita** | A sua validação |
| 4 | Decisão do SP2 registrada | **Feita**: DEC-122 APROVADA "por ora", DEC-123 (direção), DEC-124; registro 0009. Você aceitou o "por ora" e vai observar a fluidez | Reabrir só se a janela mostrar trancos |
| 5 | `FoodStub` e `IncomeStub` no Anexo D com tarefa de remoção | **Feita** | Nada |
| 6 | Tag `fase-2-concluida` no remoto | **Não criada** | **Só com a sua autorização** (AGENTS, seção 10) |
| 7 | Status em 100% para a fase | **96,9% (31 de 32)** | Vira 100% com a LW-086 concluída |

## 5. RESPOSTAS DE ARTHUR À CHECKLIST 2.H (LW-086)
*(a preencher depois da sua passada e das provas; formato na seção 5 do roteiro)*

## 6. RETROSPECTIVA (rascunho; em fatos)
**O que deu certo**
- **Contrato primeiro e spike antes da apresentação:** a LW-055 fixou contratos e eventos antes do código; o SP2 (LW-071) decidiu navegação e relógio contra corpo (DEC-122 a DEC-124) antes do `NpcView` definitivo.
- **O oráculo de 9 impressões digitais** (LW-081a) deixou dividir o `npc_module.gd` em cinco classes **sem mudar o comportamento**, e a **equivalência S1 × S0** (LW-075) deixou os dois modos usarem a mesma função de efeitos. O hash de 30 dias (`d13b921112ce`) ficou o mesmo por **várias junções seguidas**.
- **Dados em JSON:** uma ação nova entra só por dados e é validada.
- **Painel de depuração** (rastro, memórias, relações) tornou o comportamento **legível** antes de ajustar qualquer peso.
- **Revisão cruzada de leitura (A e C) + correção no mesmo dia:** 0 achados bloqueantes de código; a ponte passou a citar só a `api/` e ganhou regra automática (085a), o cruzamento impasse × conversa ganhou teste (085b) e os documentos foram alinhados ao código (085d).
- **Soak de 1 ano com 300 NPCs** limpo: 0 mortes, memória estável, hash repetível.

**O que não deu certo**
- **Arquivos acima do limite:** `npc_module.gd` com 620 linhas (346 de código) e `npc_thinker.gd` com 455 (328). Tema que **já tinha aparecido na Fase 1** (I3 e M1). Resolvido por decisão sua: contar só código, folga 1,5× (registro 0011); fica aberto que o AGENTS ainda diz "~300 linhas".
- **A ponte citou classes internas do `npc` sem nenhuma verificação automática** e só a revisão viu; a regra D nasceu na 085a, **depois** do problema. **Lição:** a verificação nasce junto do contrato.
- **Faltava um teste de cruzamento** (impasse × conversa) e a minha primeira premissa para ele estava errada (a sequência de vencimentos não começa na conversa: sem resposta do corpo a fome sobe e o NPC troca a ação por decisão). Só a execução mostrou.
- **O custo do painel só foi medido na revisão** (085c): o resumo a cada 1 s chama o `validate()` do mundo e com 300 NPCs dá ~20 ms por chamada (quadro de ~24 ms uma vez por segundo, só com o painel aberto).
- **Quadros do SP2 e da LW-072 não ficaram no repositório;** 3 de 13 ensaios fora da régua e a causa dos trancos ficou aberta. Aceito "por ora".
- **Muitos valores [HIP]:** 300 NPCs (DEC-040 PENDENTE), ~3 ms (DEC-071 PROPOSTA), 80 e 120 m de LOD, 50 corpos, 24 memórias e 16 relações por NPC, intervalos do painel.
- **Documentos do "estado atual" ficaram para trás:** `events.md` falava de ouvintes que não existiam, o README dizia que o jogo nascia à meia-noite (era 05:45 desde a LW-042b) e o índice de contratos não listava o `tools.md`.
- **Trabalho em várias conversas ao mesmo tempo, com um Mac só:** medições com ruído (B) e conflitos em `backlog.md` e `ROADMAP_STATUS.md`; resolvidos com regras (um Godot pesado por vez; linhas novas no meio do arquivo).
- **O painel e a conversa só serão vistos na janela agora**, na LW-086: antes disso só tinham teste.
- **Teste que parece rodar e não roda** (lição da Fase 1) **voltou:** um teste solto não imprimiu nada porque o cache de importação do Godot era mais velho que o arquivo; resolvido com `--import`.

**Lições**
1. Criar a **verificação automática junto do contrato** (como a regra D da porta `api/`).
2. **Medir o custo das ferramentas de depuração** na tarefa que as cria, não na revisão.
3. A tarefa que cria o **segundo** lado de um cruzamento (impasse × conversa) traz o **teste de cruzamento**.
4. **Atualizar README, `events.md` e índices na própria tarefa**, não na revisão.
5. **Guardar os números de quadros** (e o hardware) em `docs/decisions/`.
6. Linhas novas de backlog **no meio** do arquivo, não no fim.
7. Depois de atualizar a pasta, rodar `godot --headless --path . --import` **antes** de testes soltos; e "passou" só com `All tests passed`.

## 7. O QUE PRECISA SER DECIDIDO ANTES DA FASE 3 (com a minha recomendação)
| # | Assunto | Situação | Recomendação |
|---|---|---|---|
| 1 | **Ids de conteúdo em dados** (`"work"` em 3 arquivos, `"help"` em 2, `"flee"`, `"sleep"`, `"talk_player"`...; alcance e cooldown da conversa em constantes) | No backlog | Uma **conferência de dados** barata (cada id de constante tem de existir no catálogo) antes da LW-087; mover alcance e cooldown para `data/npc_params.json` |
| 2 | **Tipos da `api/`** (retornos de `explain_decision`, `peek_memories` e `peek_routine_action` ainda de tipo interno; `peek_npc_bodies` lê o membro público `lod`) | No backlog (085a) | Fazer **antes** de a Fase 3 acrescentar consultas à ponte |
| 3 | **Saturação das memórias dos notáveis:** em 1 ano os 40 T2 chegam a 24 de 24 memórias, 8 a 16 de 16 relações e **0 traços permanentes** (o limiar 80 nunca é atingido) | Medido na LW-084 | Aceitar a saturação (o desenho esquece por valor), mas **rever o limiar de traços (80)** antes de a Fase 3 depender de reputação |
| 4 | **`FoodStub` e `IncomeStub`:** LW-094 remove o `FoodStub` (o estoque dele **está no save**, então muda o formato) e a LW-095 o `IncomeStub` (salários pelo `Ledger`); verificador na LW-114 | Anexo D | Decidir **antes da LW-087** o que acontece com os 100 NPCs de teste e com os saves de teste; não começar a economia sem isso |
| 5 | **`save_version` em 2 e "save congelado"** (DEC-083 e DEC-084 seguem PENDENTE/PROPOSTA) | Registro 0011 | Fixar o número final e a política antes do congelamento (proposta: depois da validação da Fase 4) |
| 6 | **Régua de memória** (0,5 MiB entre o dia 30 e o 360, proposta da B) e **régua de picos** (~10 ms, hoje só informativa) | Proposta | Aprovar a régua de memória; manter os picos informativos e medir em release com laço de controle intercalado |
| 7 | **Custo do painel:** resumo de 1 s para ~5 s [HIP] ou `validate()` só sob demanda (proposta da 085c) | Proposta | Mudar para ~5 s (uma linha) quando mexer no painel |
| 8 | **SP2 "por ora" (DEC-122):** navegação reta que atravessa pedra e casa; caminhada em S0 atrasa em relação a S1 | Aceito por você | Reabrir só se a janela mostrar trancos; navegação com desvio entra na Fase 3 ou depois |
| 9 | **DEC-040** (quantidade de NPCs, PENDENTE) e **DEC-071** (orçamento, PROPOSTA) | Pendentes | Decidir junto da primeira medição de economia (Fase 3) |
| 10 | **AGENTS 4.5 e 5.2** (contar só código, folga de 1,5×) e a **entrada no `DECISIONS.md`** com as três decisões do 0011 | Proposta nos relatórios da LW-085 | Registrar as duas |
| 11 | **Ofício novo só por JSON** (2.F, critério 8): sem teste | Parcial | Uma tarefa pequena, só teste, antes da Fase 3 (a Fase 3 vai mexer nos ofícios) |

## 8. PENDÊNCIAS E RESSALVAS ABERTAS
- **LW-085:** aprovada por você em 10/11/2026 (a 085c, custo do painel, já estava no `main`).
- **A sua validação (LW-086):** roteiro pronto; assinatura **com a ressalva** de janela mais prova automática.
- **Teleporte:** sem teste permanente; só o SP2 e a sua janela (roteiro, item 2).
- **Item 8 da checklist (sem dinheiro, mercado nem facções):** sem teste GUT; a prova é a busca por texto e a sua janela.
- **Tag `fase-2-concluida`:** só com a sua autorização.

## 9. PRÓXIMO PASSO (nada foi iniciado)
Sua passada na janela (cerca de 13 minutos) e a conferência das provas do roteiro; depois, **"LW-086 assinada"** (ou a lista do que falhou). Só então: tag `fase-2-concluida`, status em 100% e a **Fase 3** (LW-087 em diante), começando pelas decisões da seção 7.
