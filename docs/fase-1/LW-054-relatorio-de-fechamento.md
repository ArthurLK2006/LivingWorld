# Relatório de fechamento da Fase 1 (LW-054)

Preparado em **07/11/2026, às 13:49** (horário de Brasília), na Fase A da LW-054. Todo fato abaixo vem de um documento do repositório, de um comando que eu executei ou de uma frase de Arthur, e a origem aparece no texto. Rótulos usados: **fato**, **decisão**, **proposta**, **hipótese**, **pendente**, **limitação**. A **validação** foi feita por Arthur, jogando; a **revisão** foi feita por Claude (`docs/fase-1/LW-053-parecer.md`). Eu só registro: não valido, não decido pelo Arthur e não corrijo o que ele escreveu.

```
RELATÓRIO — LW-054: Fechamento da Fase 1        Status: PRONTA PARA REVISÃO
```

## 1. RESUMO
A Fase 1 entregou o primeiro mundo que dá para percorrer: um terreno de teste de 1 km² com colisão, carregado só em volta do jogador, com céu, sol, névoa e dia e noite que seguem a hora simulada; árvores e pedras só visuais; uma cápsula laranja provisória que anda, corre e pula; câmera de terceira pessoa; limites do jogador (inclinação, borda do mapa, queda); dois pontos de interação com texto por chave; um HUD mínimo (data e hora, pausa, velocidade) e um teste de integração que roda sem janela (fonte: `README.md`, seção 5.1, e `docs/ROADMAP_STATUS.md`, tabela da Fase 1).

**Placar, depois da aprovação de Arthur desta tarefa:** **23 de 23 tarefas da Fase 1 concluídas (100%)** e **54 de 192 do projeto (28,1%)**; as 192 vêm de 31 + 23 + 32 + 30 + 29 + 47 (`README.md`, seção 5.3). **Hoje**, no `docs/ROADMAP_STATUS.md` do `main` (`ce430cf`), estão 22 de 23 (95,7%) e 53 de 192 (27,6%): a diferença é só a própria LW-054, que passa a "concluída" com a aprovação (Fase B). **Extras que não entram na conta:** LW-033A, LW-037A, LW-037B, LW-047A e LW-053A (`ROADMAP_STATUS.md`, tabela "Tarefas extras").

- **Revisão (LW-053):** APROVADO COM AJUSTES, 0 críticos, 3 importantes, 7 menores; aceita por Arthur em 07/11/2026 (`docs/fase-1/LW-053-parecer.md`).
- **Validação (LW-054):** Arthur jogou e **assinou em 07/11/2026** (painel de decisões, resposta "Assinar"), sem registrar problema, com a ressalva de que ainda atravessa árvores e pedras (seção 6).
- **Decisões novas:** DEC-119 (meta de quadros), **APROVADA** e já registrada; **DEC-120** (direção visual), aprovada por Arthur por escrito em 07/11/2026 e **ainda não registrada** em `DECISIONS.md` (só na Fase B).
- **Tag `fase-1-concluida`:** **não existe** (conferi com `git tag -l 'fase-*'` e `git ls-remote --tags origin 'fase-*'`: só aparece `fase-0-concluida`). Pelo roadmap (1.J), a fase só é dada como concluída com a tag no remoto; ela só nasce na Fase B, se Arthur escrever `APROVADO LW-054` (autorização A4 da tarefa).

## 2. ARQUIVOS CRIADOS / MODIFICADOS (Fase A)
- **Criado:** `docs/fase-1/LW-054-relatorio-de-fechamento.md` (este arquivo, 141 linhas).
- **Modificado:** `docs/backlog.md`, **só com linhas acrescentadas** (nada foi apagado): 4 linhas novas e 3 linhas existentes ampliadas com uma "Atualização (LW-054)" ao final, porque esses três assuntos já tinham linha.
- **Não tocados:** código, dados, `project.godot`, documentos protegidos, `docs/ROADMAP_STATUS.md` e `README.md` (só na Fase B). **0 arquivos de código** (teto da tarefa: 0).
- Trabalho feito na pasta `.worktrees/lw-054`, ramo `lw-054-fechamento-da-fase-1`, criado de `origin/main` (`ce430cf`).

## 3. O QUE A FASE ENTREGOU
O que existe (`README.md`, 5.1, e `ROADMAP_STATUS.md`) e o que Arthur consegue fazer no jogo (`README.md`, seção 9, e `docs/fase-1/LW-054-roteiro-para-arthur.md`, seção 2):
- **Abrir o jogo com F5:** o terreno de teste de 1 km² (planície, colina, vale, caminho de areia e um morro íngreme de teste) aparece aos poucos em volta da cápsula, com árvores, pedras e o HUD. O jogo nasce à meia-noite (**pendente:** a hora de nascimento é decisão de Arthur, no backlog).
- **Andar, correr e pular:** W, A, S, D; Shift esquerdo corre; Espaço pula. **Câmera:** botão direito do mouse arrastado ou as setas giram; a roda dá zoom (de 4 a 40 m).
- **Limites:** não sai pela borda (margem de 1 m), não sobe encosta acima de 40° [HIP] e, se cair mais de 2 m abaixo do terreno, é reposto (LW-047).
- **Tempo:** céu e luz seguem a hora simulada; **P** pausa e congela o personagem; **1** e **2** mudam a velocidade.
- **Interagir:** perto de um dos dois marcos ciano (até 3 m [HIP]) aparece "[E] Interagir"; **E** mostra o texto por cerca de 5 s [HIP] (LW-049 e LW-050).
- **Por baixo:** a ponte `SimBridge`, o módulo `character`, o serviço de interação (evento `InteractionPerformed`), o teste de integração scriptado (LW-052) e o `tools/check_all` com 9 verificações de arquitetura, teclas fixas e texto de tela solto.
- **Não existe, de propósito:** NPCs, itens ou inventário, combate, menus, salvar pela tela, som, animação, água e clima (roteiro, item 8; roadmap 1.J, "Não fazer").

## 4. CRITÉRIOS DE ACEITAÇÃO 1.F E DEFINIÇÃO DE CONCLUÍDO 1.J
**Critérios 1.F** (`docs/DEVELOPMENT_ROADMAP.md`, 1.F). Situação: parecer da LW-053, tabela "Critérios de aceitação da Fase 1", e respostas de Arthur (seção 6). "Sem problema registrado" quer dizer que Arthur disse que testou tudo e não registrou PROBLEMA nem NÃO CONSEGUI.

| # | Critério (resumo) | Situação | Origem |
|---|---|---|---|
| 1 | Nasce no terreno, anda, corre e pula; não atravessa o chão, não sai do mapa, não sobe encosta acima do limite | **Cumprido.** Testes; no jogo, sem problema registrado | Parecer (critério 1); LW-045 e LW-047 no `ROADMAP_STATUS.md`; Arthur (seção 6) |
| 2 | Câmera não entra no terreno e não treme | **Cumprido.** Colisão por teste; "não treme": P2 = não treme | Parecer (critério 2); LW-046; Arthur, P2 |
| 3 | Dia e noite pela hora simulada; pausar congela tudo | **Cumprido.** Testes e LW-052; no jogo, sem problema registrado | Parecer (critério 3); Arthur |
| 4 | Aviso ao chegar perto e texto da chave de tradução | **Cumprido.** Testes; no jogo, sem problema registrado | Parecer (critério 4); LW-050; Arthur |
| 5 | Meta de quadros no hardware-alvo | **Cumprido** pela medição da LW-053A (média de 8,37 a 8,39 ms por quadro e nenhum quadro acima de 33 ms, em release e na tomada) e **decidido na DEC-119** (APROVADA). O texto do 1.F item 5 ainda diz "proposta [PEND]" (arquivo protegido; vale a DEC-119; está no backlog). Arthur: P1 = fluido | `ROADMAP_STATUS.md` (LW-053A); DEC-119; backlog |
| 6 | Mesmo hash sem janela; `check_architecture` verde | **Cumprido.** Cenário B da LW-052; `check_architecture` com 9 de 9 (revisor). Meu `check_all` está na seção 5 | Parecer (critério 6); seção 5 |
| 7 | Contagem de nós estável em deslocamento longo | **Cumprido no teste** (cenário C da LW-052). **Limitação:** a contagem de nós não foi medida durante a caminhada de Arthur | Parecer (critério 7); LW-052 |
| 8 | `check_all` verde; teste de integração verde | **Verde** no meu `check_all` (471 testes) e `3/3 passed.` no teste de integração (seção 5) | Seção 5 |

**Definição de concluído 1.J:**

| # | Condição | Situação | Origem |
|---|---|---|---|
| 1 | As 23 tarefas concluídas | **22 concluídas hoje.** A 23ª é a LW-054, que passa a concluída com a aprovação de Arthur desta tarefa (Fase B) | `ROADMAP_STATUS.md` |
| 2 | Critérios de 1.F cumpridos | **Sim**, com as limitações dos itens 5 e 7 da tabela acima | Tabela acima |
| 3 | REV e VAL aprovadas, sem achado crítico aberto | **REV:** aceita em 07/11/2026, 0 críticos. **VAL:** assinada por Arthur em 07/11/2026. A aprovação **deste relatório** está pendente | Parecer; Arthur (seção 6) |
| 4 | Decisão do SP4a registrada | **Sim.** A DEC-057 está **APROVADA** (conferi o índice e a entrada em `DECISIONS.md`); resultado em `docs/decisions/0007-spike-sp4a-terreno.md` | `DECISIONS.md` |
| 5 | Tag `fase-1-concluida` criada (no remoto) | **Não** (estado real hoje). Só existe depois da Fase B | `git tag -l`; `git ls-remote` |
| 6 | `ROADMAP_STATUS.md` em 100% | **Não** (hoje 22 de 23, 95,7%). Passa a 23 de 23 na Fase B | `ROADMAP_STATUS.md` |

## 5. NÚMEROS DA FASE
**Git, desde a tag `fase-0-concluida` (`7ae6e8e`) até `origin/main` (`ce430cf`)**, com comandos que executei em 07/11/2026 na minha pasta:
- `git rev-list --count fase-0-concluida..origin/main`: **47 commits** (44 sem os 3 de junção). Dois deles são da LW-031A, extra pós-fechamento da Fase 0, que a conta desde a tag inclui.
- `git diff --shortstat fase-0-concluida..origin/main`: **232 arquivos alterados, 20.155 linhas acrescentadas e 214 removidas** (inclui documentos, dados e testes).
- **Até `6797563`** (base do parecer): **230 arquivos, +19.909 e −213**, **igual** ao esperado e ao número do parecer. A diferença para hoje (+2 arquivos, +246 e −1) vem dos dois commits da LW-053 (`834ae66` e `ce430cf`): o diff direto entre `6797563` e `ce430cf` mostra 7 arquivos (2 novos, o parecer e o roteiro; e `README.md`, `DECISIONS.md`, `ROADMAP_STATUS.md`, `backlog.md` e `tests/soak/README.md` editados), +256 e −11. O total acumulado desde a tag cresce menos porque algumas linhas editadas já eram da fase.
- **Datas dos commits (Brasília):** o primeiro é de 04/11/2026 12:38 (`622fecb`, LW-031A) e o último de 07/11/2026 12:07 (`ce430cf`); há commits em quatro datas (04, 05, 06 e 07/11/2026). Não calculo prazo de calendário.
- Esta tarefa acrescenta 2 arquivos (este relatório e o backlog); os números acima são de antes dela.

**Testes, executados por mim ao final da Fase A**, na pasta `.worktrees/lw-054` (`HEAD` `ce430cf` mais os 2 arquivos desta tarefa):
- `tools/check_all`: **VERDE** (13:46:33 a 13:48:02, Brasília), com a linha final "VERDE: arquitetura, dados e etapa de testes aprovadas.": **471 de 471 testes** (Scripts 52, Asserts 190.263); "Arquitetura: nove verificações aprovadas"; teclas fixas e texto de tela solto sem achados; 0 linhas de FALHA, VIOLAÇÃO ou "Nothing was run"; 1 aviso "Deprecated" do GUT (já conhecido, backlog). A saída traz 47 linhas "ERROR:" impressas por testes que exercitam caminhos de erro; as que vi vinham com `[ExpectedError]` do GUT, mas não conferi as 47 uma a uma, e nenhuma derrubou o `check_all`.
- `tools/check_gdscript_warnings`: "GDScript: sem avisos de compilação (SCRIPTS_VERIFICADOS: 136)."
- `tools/run_tests res://tests/integration/test_phase1_scripted.gd`: apareceram `3/3 passed.` e `---- All tests passed! ----` (Scripts 1, Tests 3, Asserts 85, 7,042 s); 0 ocorrências de "Nothing was run" e de "Parse Error". Valido só pelo texto, não pelo código de saída. É o resultado do **meu** teste, para o item 7 da seção 6.

## 6. RESPOSTAS DE ARTHUR À CHECKLIST 1.H (LW-054)
Arthur **não respondeu item por item** (1 a 8), como pedia o roteiro (`docs/fase-1/LW-054-roteiro-para-arthur.md`, seção 5). Depois de jogar, em 07/11/2026, ele escreveu (grafia dele, sem correção):

> Testei tudo, todos os movimentos fluidos, sem trancos, a camera fluida e nao treme, fiz tudo e ficou bem legal, nao vejoa. hora de tudo tomar as formas mesmo e ficar aprimorado. Uma coisa que percebi foi que eu atravessei as pedras e as arvores, nao sei se isso vai mudar no futuro.

**Leitura de Claude (o revisor), que Arthur confirmou ao assinar no painel de decisões de 07/11/2026:**

| Item | Leitura |
|---|---|
| 1 a 6 e 8 | **Sem problema registrado:** Arthur disse que testou tudo e não registrou nenhum PROBLEMA nem NÃO CONSEGUI. Não escrevo "OK" item por item, porque ele não respondeu assim |
| 7 (salvar e recarregar) | O teste foi rodado pelo dev anterior na pasta principal em 07/11/2026 e deu `3/3 passed.` e `---- All tests passed! ----` (relato dele; **não confirmado por mim**). Meu resultado está na seção 5 |
| 9 (agradável para explorar?) | **Sim** ("ficou bem legal") |
| P1 (movimento fluido ou aos trancos?) | **Fluido** ("todos os movimentos fluidos, sem trancos") |
| P2 (a câmera treme?) | **Não treme** ("a camera fluida e nao treme") |

- **Assinatura:** Arthur **assinou a LW-054 em 07/11/2026** (painel de decisões, resposta "Assinar").
- **Ressalva:** "eu atravessei as pedras e as arvores, nao sei se isso vai mudar no futuro". Isso **não é defeito**: está na lista "Não é defeito" do roteiro (item 2) e é a decisão **E4** de Arthur na LW-043 (árvores e pedras só visuais, sem colisão; `docs/modules/presentation.md` e `docs/modules/world.md`). Foi para o backlog (linha nova).
- **Pergunta de Arthur no mesmo dia, sem ação de código:** se a estética ficará parecida com Albion e RuneScape, sem o polimento e a complexidade de Diablo. **Resposta:** virou a **DEC-120** (direção visual simples, com a sensação desses jogos), aprovada por Arthur por escrito em 07/11/2026; o registro em `DECISIONS.md` é da Fase B.
- **Limitações:** eu não vi o jogo nem a tela de Arthur; o que está acima é só o que ele escreveu. Não há capturas de tela nem medição de quadros ou de nós feita durante a partida dele.

## 7. RETROSPECTIVA CURTA (o que atrasou ou deu errado, em fatos)
- **Tetos de arquivos:** a LW-048 (13 arquivos contra 9), a LW-049 (15 contra 10) e a LW-051 (14 contra 7) passaram do teto sem parar (AGENTS 5.2 e 16.2); parte da causa era o envio contar documentos no teto (parecer, I3). **Decisão:** nos próximos envios o teto de arquivos conta só arquivos de código e há a linha "PARE se passar".
- **Pasta de rascunho da sessão fora da raiz** (AGENTS 12.1): no Lote 4, na LW-053A e na LW-053 (Fase A). Relatado e apagado nas três vezes; sem efeito no projeto (parecer, M3, para as duas primeiras; a terceira consta do relato da própria Fase A da LW-053).
- **Medição de quadros:** em depuração e na bateria (Lote 4) o pior quadro chegou a 34,9 a 52,1 ms; em release e na tomada (LW-053A) nenhum quadro passou de 33 ms (`docs/backlog.md`; `ROADMAP_STATUS.md`). Lição: a régua de quadros é release, na tomada (DEC-119).
- **120 quadros por segundo numa tela de 60 Hz** (parecer, I1): causa **não confirmada**. Arthur respondeu P1 = fluido e P2 = não treme; a investigação só será aberta se ele voltar a sentir trancos (DEC-119); segue no backlog.
- **Teste que parece rodar e não roda:** `tools/run_tests` sai com código 0 mesmo quando o GUT diz "Nothing was run" (Parse Error por cache `.godot/` velho depois de atualizar a pasta principal). Achado na preparação da LW-054 (07/11/2026). Conferi no código: `tools/run_tests` (linhas 10 e 12) chama o GUT direto, sem conferir o texto da saída; o `check_all` pega o erro por busca de texto (`tools/check_all`, linha 25: `SCRIPT ERROR|Parse Error`). Lição: só vale teste com "N/N passed." escrito.
- **Linha que não existia:** o envio da LW-053 mandava "atualizar a linha da LW-053" no status, mas essa linha não existia (a tabela da Fase 1 terminava na LW-052). O dev perguntou e a linha foi criada. Lição: criar a linha da tarefa REV ou VAL quando ela abre.
- **O que a revisão da LW-053 achou:** 0 bloqueantes, 3 importantes e 7 menores (texto completo no parecer; destino em `ROADMAP_STATUS.md` e `docs/backlog.md`):

| ID | Assunto (resumo) | Destino |
|---|---|---|
| I1 | 120 quadros por segundo numa tela de 60 Hz | Decidido: esperar a LW-054; só reabrir se Arthur sentir trancos (P1 = fluido); backlog |
| I2 | Meta de quadros ainda proposta | Decidido na **DEC-119** (APROVADA) |
| I3 | Tetos de arquivos ultrapassados sem parar | Decidido: teto só de código e "PARE se passar" nos próximos envios; backlog |
| M1 | `sim_bridge.gd` (357 linhas) e `terrain_view.gd` (322) acima de 300 | Registrado no backlog; dividir a ponte antes da Fase 2 |
| M2 | Evento na fila com o relógio pausado | Registrado no backlog (caso de teste da futura tela de salvar) |
| M3 | Pasta de rascunho fora da raiz | Fica no parecer; reforço proposto na seção 8 (b) |
| M4 | Texto do backlog mais forte que a evidência | **Corrigido** na LW-053 (backlog) |
| M5 | `tests/soak/README.md` com linha em branco no fim | **Corrigido** na LW-053 |
| M6 | LW-053A passou 1% do teto de linhas | Fica no parecer |
| M7 | Pasta `$HOME/lw-release-probe` (340 MB) no Mac | Fica no parecer; Arthur apaga quando quiser |

## 8. PROPOSTAS PARA OS MODELOS (só **propostas**; nada foi aplicado; Arthur decide)
- **(a)** No modelo de envio: o teto de arquivos conta só arquivos de código, com a linha "PARE se passar".
- **(b)** No modelo de envio: reforçar o AGENTS 12.1 ("nem para guardar saída de teste").
- **(c)** No `README.md` (seção 8) e no roteiro de validação: "depois de atualizar a pasta, rodar `--import` antes dos testes". Hoje os dois só pedem o `--import` em clone ou pasta nova.
- **(d)** Uma tarefa para o `tools/run_tests` sair com código diferente de zero quando nada rodar (linha nova no backlog).

## 9. PENDÊNCIAS E RESSALVAS ABERTAS
- **Tag `fase-1-concluida`:** não existe. Fase B, só com `APROVADO LW-054`: status, README, índice de decisões e DEC-120, depois a tag leve e um commit que a registra.
- **I1 (120 quadros por segundo numa tela de 60 Hz):** P1 = fluido; só reabrir se Arthur sentir trancos (DEC-119). A causa nunca foi testada; backlog.
- **Árvores e pedras sólidas:** Arthur atravessa; decisão E4 da LW-043. Avaliar com formas simples de colisão, junto do combate (SP6), medindo contra a DEC-119. Backlog (linha nova).
- **DEC-021 (origem da arte)** continua **PENDENTE**; **DEC-055** (tamanho do mundo) continua **PENDENTE**; **DEC-071** (orçamento por passo de simulação) continua **PROPOSTA** (`DECISIONS.md`).
- **M1:** dividir `sim_bridge.gd` **antes** de a Fase 2 mexer na ponte. **M2:** esvaziar a fila de eventos antes de salvar (os dois no backlog).
- **35 ocorrências de valores [HIP]** em 22 arquivos de `src/`, todas em constantes nomeadas (parecer, item 9); nenhuma virou decisão.
- **Documentos defasados** (protegidos; tarefa DOC no backlog): `DEVELOPMENT_ROADMAP.md` 1.F item 5 ainda diz "proposta [PEND]"; `DECISIONS.md`, seções 5.2 e 8 e a linha de totais (118 entradas, sem a DEC-119 e a DEC-120).
- **Outros pontos novos no backlog:** `tools/run_tests` com código 0 sem rodar nada; `--import` depois de atualizar a pasta; `.worktrees/` não rastreada na pasta principal; direção visual (DEC-120).
- **Testes manuais que cabem a Arthur:** nenhum novo nesta tarefa (só documentos).

## 10. PRÓXIMO PASSO (nada foi iniciado)
- **Próxima tarefa do roadmap:** a primeira da Fase 2 é a **LW-055** (DOC: contratos do módulo `npc`, da extensão de `world` e catálogo inicial de `docs/events.md`), que depende da LW-054 **e da LW-152** (`DEVELOPMENT_ROADMAP.md`, tabela da Fase 2).
- **SP6:** o roadmap (1.J) diz que o SP6 é "um teste descartável que roda depois da LW-054", e a LW-152 está descrita como "executado logo depois da LW-054, antes da Fase 2" (DEC-080, antecipação aprovada).
- **Decisão de Arthur (painel de decisões, 07/11/2026):** o SP6 (LW-152) vem **logo depois do fechamento**, com envio próprio. **Não iniciei nada**: a LW-152 e a LW-055 só começam quando Arthur mandar.

## ACOMPANHAMENTO (obrigatório)
- **Avanço:** Fase 1 com 22 de 23 hoje; depois da aprovação desta tarefa, 23 de 23 (100%) e projeto com 54 de 192 (28,1%). Pelo roadmap, a fase só está concluída com a tag no remoto.
- **Próxima tarefa recomendada:** LW-152 (SP6), por decisão de Arthur; a LW-055 só depois dela. **Não iniciada.**
- **Decisões que dependem de Arthur:** aprovar esta tarefa com a mensagem exata `APROVADO LW-054` (libera a Fase B: status, README, linhas de índice da DEC-119 e da DEC-120, entrada da DEC-120 e tag leve `fase-1-concluida`); aprovar ou recusar as propostas da seção 8; decidir o destino de `.worktrees/` (`.gitignore` ou deixar) e da pasta `$HOME/lw-release-probe` (parecer, M7).
- **Git:** ramo `lw-054-fechamento-da-fase-1`, criado de `origin/main` (`ce430cf`); um commit com a mensagem "LW-054: relatório de fechamento da Fase 1 e backlog"; push do ramo autorizado por Arthur; sem push para o `main`, sem tag, pasta principal intocada.
