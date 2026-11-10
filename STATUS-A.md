10/11/2026 18:50 (Brasília) · rodando · LW-085e: check_all no HEAD final (`1ff78a7`) do ramo `lw-085e-regras-e-decisoes`; só a A usa o Godot agora

# RELATÓRIO — LW-085a: A ponte cita só a `api/` do `npc`     Status: PRONTA PARA REVISÃO (já no `main` pela Fase B automática que Arthur autorizou)

## 1. Resumo
A ponte (`src/bridge`) citava 8 classes internas do `npc` fora da porta `api/` e nenhuma verificação percebia (achado I-1 da minha revisão e I1 da revisão C). Agora ela cita só classes de `src/sim/npc/api/`: três visões de dados puros novas, seis constantes reexportadas e duas consultas novas no `NpcModule`. A **regra D** do `tools/check_architecture` impede que volte. Nada mudou no comportamento do jogo.

## 2. Arquivos criados
- `src/sim/npc/api/npc_trace_view.gd` — visão do rastro de decisão (`NpcTraceView.of(explanation)`)
- `src/sim/npc/api/npc_memory_view.gd` — visão das memórias e traços (`NpcMemoryView.of(query)`)
- `src/sim/npc/api/npc_routine_view.gd` — visão da ação da rotina (`NpcRoutineView.of(query)`)
- `tests/unit/test_npc_api_door.gd` — 8 testes da porta
- 4 arquivos `.uid` dos scripts novos

## 3. Arquivos modificados
- `docs/modules/npc.md` (+13 linhas) e `docs/modules/bridge.md` (12 linhas trocadas): **contrato primeiro**, no commit `a6d554b`
- `src/sim/npc/api/npc_module.gd` (+17): 6 constantes reexportadas (`CODE_NOT_IN_S0`, `CODE_INVALID_POSITION`, `CODE_DEAD`, `CODE_RELATION_INVALID`, `CODE_RELATION_NOT_ALLOWED`, `LEVEL_S0`), `peek_level_of(npc_id)` e `peek_s0_count()`
- `src/bridge/bridge_npc_inspect.gd`, `bridge_replies.gd`, `bridge_inspect_replies.gd` (comentário): passam a usar só a `api/`; apaguei uma das 3 linhas em branco que sobravam entre duas funções (ficaram 2, o padrão do arquivo)
- `tools/check_architecture` (+16 −5): regra D; `tests/test_check_architecture.sh` (+20): casos da regra D
- `docs/ROADMAP_STATUS.md` (+1 linha de sub-tarefa; a contagem não muda) e `docs/backlog.md` (+3 itens)

## 4. Decisões técnicas
- **O desenho mudou em relação à minha proposta I-1, e Arthur aprovou.** Eu propunha trocar os tipos de retorno de `explain_decision`, `peek_memories` e `peek_routine_action`. Isso obrigaria a editar o oráculo (`test_npc_split_oracle.gd:188-198` declara variáveis com esses tipos) e cerca de dez testes, e a ordem era não editar o oráculo. Em vez disso: três visões na `api/` com construtor estático `of(...)`, e a ponte escreve `NpcTraceView.of(npc.explain_decision(id))`, sem nomear classe interna. Nenhuma assinatura pública mudou. A troca dos retornos ficou no backlog.
- **Regra D:** `src/bridge/` e `src/tools/` só citam, de um módulo de `src/sim` que tenha pasta `api/` (hoje só o `npc`), as classes que moram nessa pasta. Módulo sem `api/` (usa `internal/`, regra C), `src/app` e `src/persistence` ficam de fora. A mensagem final continua "nove verificações" (a D é mais uma letra da verificação de camadas).
- **Nomes das constantes:** `CODE_RELATION_INVALID` e `CODE_RELATION_NOT_ALLOWED` (e não `CODE_INVALID`/`CODE_NOT_ALLOWED`), para não confundir com `CODE_INVALID_SPEC` etc. que já existem no módulo.
- **Proposta de entrada para `DECISIONS.md`:** nenhuma.

## 5. Testes executados
- `tools/check_architecture`, `check_input_keys`, `check_literal_text` (antes do Godot): aprovados.
- `tests/test_check_architecture.sh`: aprovado; a regra D nova: 2 violações detectadas e 6 casos aceitos. Contra uma cópia do `main` anterior (`5e8f8b4`), a regra D acusa **12 linhas** da ponte (bem as de antes); na árvore nova passa.
- `godot --headless --path . --import`: saiu 0, sem erro.
- `tools/check_all` (rodada 1, árvore com o código): **VERDE**, 122 scripts, **1.188 testes (1.188 passando)**, 261.585 asserts, 307 scripts sem aviso de compilação.
- `tools/check_all` (rodada 2, no HEAD final `a9c68e1`): **VERDE**, os mesmos números.
- Bateria de identidade, `main` (`5e8f8b4`, checkout `lw-073c`) contra o ramo da 085a, um Godot de cada vez: oráculo (`test_npc_split_oracle.gd`), `tests/soak/run_npc_life_30d`, `tests/soak/run_npc_impasse_30d`, `tools/run_sim --days 7 --seed 1`, `2` e `3`.

## 6. Resultados
- **Oráculo:** as 9 impressões saíram **iguais** (`6e12b3067120`, `506a4a23ce89`, `7008d3b19d38`, `84ca55684e34`, `ce14b1e45954`, `142733eb318f`, `00794d5a27b6`, `3e1d080d2eed`, `f9469ccc5a9d`). Não editei o oráculo.
- **Vida de 30 dias:** hash `d13b921112ce` nas 3 linhas, problemas 0; as 3 linhas são idênticas às do `main` fora do tempo em ms.
- **Soak de impasse de 30 dias:** 0 recuperações, 0 registros, hash `d13b921112ce`, igual ao `main`.
- **`run_sim` 7 dias, sementes 1, 2 e 3:** saídas **idênticas** às do `main` (diff vazio).
- Critério de aceite cumprido? **Sim**, pelo que mediu: a ponte não cita mais classe interna do `npc` (a regra D prova, na árvore real e no caso falso), sem mudar comportamento (oráculo, hash e `run_sim` iguais), sem `save_version`, sem evento, sem dado novo, sem editar o oráculo.
- Tamanho: cerca de 326 linhas de código e teste (sem comentário nem linha em branco), 10 arquivos; dentro do teto de 1,5x, então não dividi em 085a1 e 085a2.

## 7. Problemas encontrados
- A minha estimativa original de "≈ 30 linhas de ajuste de testes" estava errada para o desenho que eu propus (cerca de 60 referências em 10 arquivos, mais o oráculo): foi o que levou à mudança de desenho acima.
- O `run_sim` imprime "Módulos: 0": ele não registra o `npc`, então **não exercita esta mudança**; quem prova a identidade de comportamento é o oráculo e o soak de 30 dias.
- O GUT mostra "Warnings 1" no resumo (junto da linha `[DEPRECATED] wait_frames`, que o GUT imprime); nenhum arquivo da 085a usa `wait_frames`, mas **não comparei o número com o `main`**.
- Um deslize meu de shell no meio (um `echo ======` no zsh) perdeu uma saída; refiz o comando e não afetou nenhum resultado.

## 8. Riscos
- A regra D confere **nomes de classe**: não enxerga o tipo que volta de uma chamada sem nome nem de variável com tipo inferido (`:=`), nem classe interna de arquivo, nem `preload` por caminho. Está escrito no cabeçalho do script e no `npc.md`.
- Os retornos de `explain_decision`, `peek_memories` e `peek_routine_action` continuam de tipo interno; `SimBridge.peek_npc_bodies` ainda lê o membro público `lod` (`sim_bridge.gd:250-251`). Os dois no backlog.
- As constantes reexportadas referenciam outra classe em `const`; o Godot 4.7.2 aceitou (`check_all` verde).

## 9. Pendências
- **Teste manual curto para Arthur** (a ponte do painel mudou de caminho; os testes de ponte cobrem, mas a janela não foi vista): em build de desenvolvimento, abrir o painel (F3), escolher um NPC perto do jogador e conferir (1) o nível S0 na lista e no detalhe, (2) o contador de S0 no resumo, (3) com a tecla T marcado, o rastro aparece, (4) as memórias de um notável (depois de conversar) e a ação da rotina no detalhe. Nada deve parecer diferente de antes.
- Decisões que dependem de Arthur (as de antes seguem valendo): I-3 (script de medição do custo do painel), I-4 (autorização do `project.godot` pela 082g), M-1 (`last_player_talk_at` sem subir `save_version`) e o item novo do backlog (trocar os retornos por tipos da `api/`).

## ACOMPANHAMENTO
- Avanço: LW-085a pronta para revisão e já no `main`. A Fase 2 segue em 29 de 32 (90,6%) e o projeto em 84 de 192 (43,8%): sub-tarefa não entra na conta (conferido por grep antes e depois).
- Próxima tarefa recomendada: **LW-085** (revisão arquitetural da Fase 2), agora sem o achado da ponte. **Não iniciada**, como manda a regra 13.
- Git: `main` = `a9c68e1`, enviado **em avanço rápido** (`5e8f8b4..a9c68e1`, dry-run antes), **sem tag e sem `--force`**; ramo `lw-085a-ponte-porta-api` enviado (3 commits: `a6d554b` contrato, `71d0012` código e testes, `a9c68e1` status e backlog); este ramo (`status-a`) só com `STATUS-A.md` e `REVISAO-085-A.md`. Nada rodando em segundo plano da A (o único Godot ativo é o da B, em `lw-084b`); a pasta principal não foi tocada.
