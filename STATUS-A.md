10/11/2026 13:18 (Brasília) · CONCLUÍDA · Revisão cruzada pré-LW-085 (LW-082 e LW-083), só leitura

# RELATÓRIO — Revisão cruzada pré-LW-085 (agente revisor, AGENTS §11)

**Status:** CONCLUÍDA (revisão entregue). Não implementei nada, não corrigi nada e **não rodei o Godot** (a outra conversa está medindo tempo). A revisão completa, com arquivo e linha, está em **`REVISAO-085-A.md`** neste mesmo ramo.

## 1. Resumo
Revisei o que não escrevi: LW-082 (painel de NPC, 082a a 082h) e LW-083 (conversa, 083a a 083f), já no `main` (`5e8f8b4`). **Nenhum achado bloqueante. 4 importantes, 8 menores.** O painel só escreve numa linha (a marcação do rastro), não há evento novo, nenhum teste foi enfraquecido, não há dinheiro nem mercado antecipados, nenhuma marca `TEMP` nova.

## 2. Achados importantes (cada um com proposta de até ~300 linhas no arquivo da revisão)
- **I-1. A ponte cita classes internas do `npc`, fora da porta `api`** (`bridge_npc_inspect.gd:59,75,85,89,96,121,132,157`; `bridge_replies.gd:165-175`), e o `npc` devolve tipos internos. Antes da LW-083a a ponte não citava nenhuma. O `check_architecture` **não enxerga** (só protege pastas `internal/` e o `npc` não tem). Proposta: tipos de resposta em `api/`, dois acessos novos, constantes reexportadas e uma regra D no script (≈ 200 a 260 linhas, 8 a 9 arquivos, contrato primeiro).
- **I-2. Arquivos acima de ~300 linhas:** `npc_module.gd` 603 (+52 por 082/083), `npc_thinker.gd` 455, `sim_bridge.gd` 391 (+81), `npc_notables.gd` 308. Proposta de desvio: isentar as duas fachadas (só delegam) e dividir `npc_thinker.gd` (hipótese de corte minha, não conferida).
- **I-3. Custo do painel não medido:** `peek_simulation_summary` chama `world.validate()` a cada ≈ 1 s (`sim_bridge.gd:360`) e a lista é refeita a cada 0,25 s (`npc_inspector_panel.gd:14-15,177-185`). Em release o painel nem é criado (`npc_inspector_mount.gd:12-14`; `main_world_view.gd:67`). Proposta: script de medição em `tests/soak/` (≈ 70 a 90 linhas), só depois que a medição de quadros terminar.
- **I-4. `project.godot` (protegido) alterado pela 082g** (`89c8182`, +25 linhas, 5 ações de entrada) sem autorização visível no repositório; a 083e escolheu não mexer nele. Pode estar na tarefa de outra conversa. Proposta: Arthur confirma e o status da LW-082 registra.

## 3. Menores (resumo)
M-1 `last_player_talk_at` salvo sem subir `save_version` (documentado, compatível) · M-2 comentário "A ÚNICA função" de efeitos ignora `NeedMath.add_pressure` · M-3 alcance e cooldown da conversa em constantes, não em dados · M-4 alcance de 3 m duplicado na apresentação (guardado por teste) · M-5 `src/tools/` fora de `check_architecture` e `check_literal_text` · M-6 `docs/modules/README.md` sem `tools.md` · M-7 três linhas em branco (`bridge_npc_inspect.gd:80-82`) · M-8 `FAILURE_KEYS` junta códigos de classes diferentes.

## 4. Critérios da LW-085
Limites do `npc`: parcial (I-1, I-2) · catálogo em dados: OK (`data/actions.json:11`, `data/memory_kinds.json:2`) · função única de efeitos: OK para ações (`action_runner.gd:232`) · ponte fina: parcial · dinheiro e mercado: OK (nenhum) · marcas `TEMP`: só `TEMP-LW-065` e `TEMP-LW-066`, antigas · custo de memória e relações: limitado por dados (`max_t2` 40, `memory_capacity` 24, `relations_capacity` 16 → no máximo ≈ 960 memórias e ≈ 640 relações de notáveis, conta minha; bytes **não medidos**) · resultado do SP2: fora do que li.

## 5. Testes executados
**NÃO EXECUTADO** (por ordem: sem Godot). Só leitura: `git show`, `git diff`, `git log`, `grep`, `find`, `wc`. O `check_all` verde que cito (1.180 testes, no `main` `5e8f8b4`) é o da Fase B da LW-073, e mostra que os testes passam, não que testam o certo.

## 6. Não verificado
Painel na janela (critério do roadmap, para Arthur); custo em ms e bytes; autorização do `project.godot`; leitura linha a linha de `npc_inspector_model.gd`, do resto do painel, de `bridge_inspect_replies.gd`, `npc_notables.gd`, `npc_decision_runtime.gd` e dos 6 testes novos (só `grep`, tamanhos e diffs); SP2.

## 7. Estado do Git
- `main` = `5e8f8b4`, sem tag nova, sem `--force`; nada foi enviado ao `main` neste passo.
- Este ramo (`status-a`) tem só `STATUS-A.md` e `REVISAO-085-A.md` de diferença para o `main`; **nunca vai para o `main`**.
- Nada rodando em segundo plano; a pasta principal não foi tocada.

## 8. Decisões que dependem de Arthur (com a recomendação)
1. I-4: confirmar a alteração do `project.godot` pela 082g. *Recomendo confirmar e registrar.*
2. I-1: corrigir na LW-085 (com regra D no `check_architecture`) ou registrar desvio. *Recomendo corrigir.*
3. I-2: isentar as fachadas e dividir só `npc_thinker.gd`. *Recomendo.*
4. I-3: autorizar o script de medição após a medição de quadros. *Recomendo.*
5. M-1: manter o campo opcional registrado. *Recomendo manter.*

## ACOMPANHAMENTO
- Avanço: item 2 (revisão cruzada) concluído; **paro aqui**, como mandado.
- Próxima tarefa recomendada: LW-085 (revisão arquitetural da Fase 2), usando `REVISAO-085-A.md` como entrada. **Não iniciada.**
- Git: ramo `status-a` com um commit "status a: revisão cruzada pré-LW-085, CONCLUÍDA"; push só desse ramo.
