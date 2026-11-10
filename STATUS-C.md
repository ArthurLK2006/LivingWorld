10/11/2026 15:25 (Brasília) — PARADA: LW-085b e LW-085d no `main` (`8b910f1`, Fase B automática); espero a LW-084 (B) para o relatório final da LW-085. Godot pesado liberado.

RELATÓRIO — LW-085b e LW-085d (teste do impasse com a conversa; documentos da revisão da Fase 2)        Status: PRONTA PARA REVISÃO (já no `main` pela Fase B automática; a auditoria de Arthur não foi feita)

Li antes: AGENTS (inteiro), linha da LW-085 no roadmap (`docs/DEVELOPMENT_ROADMAP.md:632`), `docs/modules/npc.md`, `docs/events.md`, `docs/ROADMAP_STATUS.md`, `docs/decisions/` (MODELO e 0009), a revisão A (`REVISAO-085-A.md`, ramo `status-a`) e o relatório da B (`STATUS-B.md`). Decisões: DEC-083 e DEC-084 (save; a 083 só nos princípios), DEC-119/122/124/125. As três decisões novas são de Arthur (mensagem de 10/11/2026).

1. RESUMO
O teste que faltava (achado I3 da minha revisão: impasse × conversa) existe e passa; foi provado por mutação do código. Dois comentários foram acertados sem mexer em código. Os documentos da revisão estão no `main`: registro 0011 (três decisões de Arthur), nota do `project.godot` na linha da LW-082, ouvintes reais de eventos, índice de contratos, texto da 082/083 e hora inicial no README, e itens no backlog. `check_all` verde no HEAD final; oráculo, vida de 30 dias, impasse de 30 dias e `run_sim` iguais aos do `main`.

2. ARQUIVOS CRIADOS
- `tests/integration/test_impasse_conversation.gd` (+ `.uid`) — o teste novo (116 linhas de código; 2 testes, 83 asserts, 1,2 s)
- `docs/decisions/0011-revisao-fase-2.md` — registro das três decisões de Arthur (arquivos grandes, `save_version`, `project.godot` da 082g)

3. ARQUIVOS MODIFICADOS
- `tests/integration/test_npc_split_oracle.gd` — só comentário (+6 linhas): as impressões são cinco de `5a7d453` e quatro (`talk`, `save`, `demote`, `starved`) da LW-073b (`5346091`), por decisão de Arthur; o código sem comentários tem o mesmo SHA-256 e as nove impressões não mudaram
- `src/sim/npc/actions/action_runner.gd` — só comentário (+1 linha): `apply_effects` é a única função de EFEITOS DE AÇÃO; `NeedMath.settle` e `NeedMath.add_pressure` também escrevem em `need_values` (mesma prova do SHA-256)
- `docs/ROADMAP_STATUS.md` — nota do `project.godot` e correção do "índice e README pendentes" na linha da LW-082; duas linhas de subtarefa (085b, 085d). A contagem da Fase 2 não mudou (29 de 29 linhas de tarefa concluídas, por script, antes e depois)
- `docs/events.md` — linhas 12-13: `LodChanged` e `NpcDied` não têm ouvinte hoje (só o `AlarmRaised` tem, conferido por busca de `subscribe(`); parágrafo que define a coluna "Ouvintes"
- `docs/modules/README.md` — índice com o `tools.md` e o estado real do `npc` (já tem código)
- `README.md` — texto da 082 e da 083 em 5 pontos e a hora inicial do jogo (05:45, antes 'meia-noite'; conferido: `NEW_GAME_START_MINUTE` = 345, `SUNRISE_HOUR` = 6.0, 1250 ms por minuto de jogo). Contagens e porcentagens idênticas, comparadas por script
- `docs/backlog.md` — 5 linhas novas (alcance e cooldown da conversa em dados; 3 m duplicado; `src/tools/` fora dos dois verificadores; trava de desenvolvimento copiada 5 vezes; ids de conteúdo em constantes) e a linha do "Deprecated" atualizada (o `wait_frames` vem da LW-020/021, commit `d55bd29`)

4. DECISÕES TÉCNICAS
- **Premissa errada minha, corrigida no teste novo:** eu esperava que a sequência de vencimentos que fecha o impasse começasse no vencimento da conversa. A 1ª execução deu 70 min contra 227 desde a conversa. Depuração (teste temporário, apagado): sem resposta do corpo o NPC volta a trabalhar, a fome sobe e ele troca o trabalho por decisão, o que quebra a sequência. A asserção passou a exigir que a sequência dure ao menos o limite e não passe do tempo desde a conversa. Nenhum teste existente foi tocado.
- **Conflito evitado, não resolvido à mão:** a junção com o `main` (com a 085a) conflitou em `docs/backlog.md` (as duas pontas acrescentaram linhas no fim). A regra manda parar em conflito fora do `ROADMAP_STATUS`/README, então desfiz a junção e movi as 5 linhas novas para junto da linha do "Deprecated" (mesmo conteúdo, commit `15a90a7`); a junção ficou limpa. Se Arthur preferir que eu tivesse parado, é só dizer.
- Reaproveitei o cache de importação (`.godot`, ignorado pelo git) de um worktree idêntico ao `main` para rodar só o teste novo enquanto a A usava o Godot; depois rodei `--import` de verdade.
- **Proposta de entrada para DECISIONS.md** (não editei o arquivo): *Título:* "Decisões da revisão da Fase 2 (LW-085)". *Contexto:* revisões A e C. *Decisão (Arthur, 10/11/2026):* (1) o limite de ~300 linhas por arquivo (AGENTS 4.5) e de ~300 linhas e ~8 arquivos por tarefa (5.2) conta só código (e teste), sem comentário, linha em branco, `.uid` nem documento, com folga de 1,5×; nada é dividido agora e as classes aninhadas do `npc_module.gd` ficam onde estão; (2) `save_version` fica em 2 até o "save congelado" (a garantia é o teste de ida e volta e o `on_load`); (3) as cinco ações de entrada do `project.godot` na 082g foram autorizadas ("só ADICIONAR ações de entrada"). *Justificativa:* revisões A e C; dividir agora custaria ~310 linhas movidas sem ganho; não há save de jogador. *Consequências:* o AGENTS continua dizendo "~300 linhas" até Arthur atualizá-lo; antes do congelamento é preciso fixar o número final do save. Texto completo no `docs/decisions/0011-revisao-fase-2.md`.

5. TESTES EXECUTADOS
- Teste novo sozinho (`-gtest=res://tests/integration/test_impasse_conversation.gd`): 2/2, 83 asserts. A 1ª execução falhou (item 4) e foi corrigida.
- Mutações temporárias no worktree de integração (sem commit, revertidas): recuperação apagando `last_player_talk_at` — PEGA; recuperação rebaixando a T1 — PEGA; vencimento do Intent apagando o minuto da conversa — PEGA (e a 2ª conversa foi aceita, o que também reprova); vencimento do Intent rebaixando a T1 — PEGA. Uma mutação num caminho que o jogo não usa (`NpcDecisionRuntime.cancel_action`) passou: era o lugar errado, refeita no certo.
- `sh tools/check_architecture .`, `tools/check_input_keys`, `tools/check_literal_text`, `tests/test_check_architecture.sh`: verdes.
- `godot --headless --path . --import`: ok; gerou só o `.uid` do teste novo.
- `tools/check_all` no HEAD de integração `3b3a07b` e de novo no HEAD final `8b910f1` (só documentos de diferença): **VERDE**, 123 scripts, **1.190 testes (1.190 passando)**, 261.668 asserts, 308 scripts sem aviso de compilação, 0 erros de script. O `main` anterior (`a9c68e1`) tinha 122 scripts e 1.188 testes: a diferença é exatamente o meu script e os meus 2 testes. ("Warnings 1 / Deprecated 1" do GUT já existia antes, B também o viu.)
- Comparação com o `main` `a9c68e1` (worktree-base): oráculo (9 impressões), vida de 30 dias (`d13b921112ce`, 3 execuções), impasse de 30 dias (`d13b921112ce`, 0 recuperações) e `run_sim` 30 dias das sementes 1 a 3 (`732907967efd…`, `3f852d2cdfc3…`, `59aa7f9949f2…`): **idênticos**; só muda o relógio em ms.

6. RESULTADOS
Todas as condições da Fase B conferem: junção sem conflito; `check_all` verde no HEAD final; oráculo, hash de 30 dias e `run_sim` iguais; nenhum teste removido, enfraquecido ou pulado (só acréscimo; no oráculo, só comentário); nenhum arquivo protegido além do que Arthur citou (`project.godot`, AGENTS, GDD, arquitetura, DECISIONS e roadmap intocados); as linhas 085b e 085d não mudam a contagem. Tamanho da 085b: 116 linhas de código (teto 1,5× da proposta de ~90 = 135); a 085d é só documento.

7. PROBLEMAS ENCONTRADOS
- A premissa errada e o conflito do backlog (item 4).
- O `status-a` carrega a árvore inteira do projeto, e não só os arquivos de status (vi ao ler a revisão A); não toquei.
- Na revisão A, M-6 (índice sem o `tools.md`) e M-7 (3 linhas em branco em `bridge_npc_inspect.gd:80-82`): a M-6 está resolvida aqui; a M-7 é código e ficou de fora (só comentários em `src/`).

8. RISCOS
- A regra de 1,5× vale por decisão de Arthur, mas o AGENTS ainda diz o contrário.
- O teste novo depende da dinâmica do jogo real (semente 5, 07:00): se a rotina mudar, o NPC escolhido ou o tempo até a recuperação mudam (a asserção usa limites, e não valores fixos, de propósito).

9. PENDÊNCIAS
- **Relatório final da LW-085:** espera a LW-084 (B) entrar no `main`; a 085a já entrou (`a9c68e1`); a 085c fica "pendente" se não existir. Vou esperar com `sleep 600` e `git fetch`, até 18 vezes.
- Nada para Arthur testar na janela por causa destas duas tarefas.

ACOMPANHAMENTO
- Avanço: LW-085b e LW-085d feitas e no `main`; LW-085 (revisão) em andamento: falta o relatório final. A LW-085 não é contada como concluída.
- Próxima tarefa recomendada: o relatório final da LW-085 (minha) quando a LW-084 entrar no `main`; depois a LW-086 (validação de Arthur). Não iniciada.
- Decisões que dependem de Arthur: (a) registrar ou não a proposta de entrada para o `DECISIONS.md` (recomendo registrar, é uma entrada só); (b) atualizar o AGENTS (4.5 e 5.2) com a regra de contagem de 1,5× (recomendo); (c) o conflito do backlog: concordo com a minha saída (mover as linhas)? (recomendo manter).
- Git: `main` = `8b910f1` (avanço rápido de `a9c68e1`, sem `--force`, sem tag); ramos `lw-085b-teste-impasse-conversa` (`cc90445`, `a415021`, `2789ed8`) e `lw-085d-documentos` (`cbf3e7d`, `5d9cb6d`, `15a90a7`) enviados; o ramo `lw-085-fase-b` (integração) ficou só local. Neste ramo `status-c`: só `STATUS-C.md` e `REVISAO-085-C.md`.
