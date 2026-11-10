10/11/2026 15:11 (Brasília) · rodando · LW-085b e LW-085d: Godot pesado (--import, check_all, oráculo, soak de 30 dias, run_sim) e Fase B automática; o relatório abaixo é o da revisão anterior e será substituído ao parar

RELATÓRIO — REVISÃO CRUZADA PRÉ-LW-085 (núcleo do `npc` e LW-083)        Status: PRONTA PARA REVISÃO (revisão entregue; nada corrigido, por ordem)

Li antes: AGENTS (seções 0, 3, 11, 14, 15), a linha da LW-085 em `docs/DEVELOPMENT_ROADMAP.md:632`, `docs/modules/npc.md`, `docs/events.md`, `docs/ROADMAP_STATUS.md`, `docs/decisions/0009-spike-sp2-corpos-e-lod.md`, Anexo D do roadmap. Decisões de que dependo: DEC-119 e DEC-122 (APROVADAS; a 122 "por ora"), DEC-125 (já no `main`), DEC-083 (save congelado, não vale ainda).

1. RESUMO
O núcleo do `npc` e a conversa (LW-083) estão, no conjunto, em ordem para a LW-085: não achei defeito de código bloqueante. Achei 1 bloqueio de processo (a LW-084, soak de 300 NPCs por 1 ano, não existe e a LW-085 depende dela), 3 achados importantes e 9 menores. A revisão completa, com arquivo e linha de cada achado, está em `REVISAO-085-C.md` (mesmo ramo). Base: `origin/main` em `5e8f8b4` (a LW-073 entrou no `main` às 12:58, durante a revisão).

2. ARQUIVOS CRIADOS
- `REVISAO-085-C.md` e `STATUS-C.md`, só no ramo `status-c`. Nada no `main`.

3. ARQUIVOS MODIFICADOS
- Nenhum do projeto.

4. DECISÕES TÉCNICAS
- Nenhuma. Propostas de correção estão em `REVISAO-085-C.md` (cada uma com até ~300 linhas) e dependem de Arthur (seção 6 de lá).

5. TESTES EXECUTADOS
- `sh tools/check_architecture .` sobre a árvore extraída de `5e8f8b4`: "Arquitetura: nove verificações aprovadas."
- `sh tools/check_input_keys .`: "Teclas fixas: nenhuma encontrada em src/."
- `sh tools/check_literal_text .`: "Texto literal: nenhum texto de interface escrito direto em src/presentation e src/app."
- `tools/check_all`, oráculo, soaks e `run_sim`: **NÃO EXECUTADOS** (ordem de Arthur: sem Godot, a B está medindo tempo). Os números que cito do `check_all` (119 scripts, 1.166 testes, 260.989 asserts) vêm do relatório da LW-082, não os reproduzi.

6. RESULTADOS
Achados:
- **BLOQUEANTE (processo) B1:** LW-084 inexistente (`docs/modules/npc.md:216` a prevê em `tests/soak/test_npc_soak_1y.gd`, que não existe). Sem ela, "custo de memória e relações" fica sem medição de 1 ano.
- **IMPORTANTE I1:** a ponte cita classes internas do `npc` (`bridge_replies.gd:169-174`, `bridge_npc_inspect.gd:132,157`) e o `check_architecture` não tem regra da porta `api`. Correção proposta: ~80 linhas, 5 a 6 arquivos.
- **IMPORTANTE I2:** `npc_module.gd` 603 linhas (336 de código) e `npc_thinker.gd` 455 (328). Divisão proposta em 2 passos de movimento puro (~170 e ~140 linhas); as classes aninhadas do módulo (221 referências) não recomendo mover: pede decisão registrada. Também acima de 300: `action_runner.gd` 415, `sim_bridge.gd` 391, `npc_memory.gd` 325, `npc_notables.gd` 308 (sem divisão agora).
- **IMPORTANTE I3:** nenhum teste junta impasse e conversa (`talk_player` com corpo que não responde). Teste proposto: ≤ ~90 linhas.
- **MENORES M1 a M9:** comentários do oráculo desatualizados; `docs/events.md:12-13` fala de ouvintes que não existem; trava de desenvolvimento copiada 5 vezes; `NeedMath.add_pressure` como segundo escritor de `need_values`; ids de conteúdo em constantes; números repetidos; `validate()` do mundo inteiro no painel sem medição; `save_version` segue 2; save do `FoodStub`.
Critérios do roadmap: função única de efeitos OK; sem dinheiro e mercado antecipados OK; marcas `TEMP` OK (16 arquivos, Anexo D com LW-094 e LW-095); catálogo em dados OK com ressalva; ponte fina e limites do módulo com ressalva (I1 e I2); custo de memória sem medição; SP2 registrado (0009 e DEC-122), com pontos abertos.
Testes enfraquecidos: nenhum além da troca das 4 impressões do oráculo (LW-073b), que foi decisão de Arthur e está explicada em `npc.md:76`.

7. PROBLEMAS ENCONTRADOS
- Os tamanhos que Arthur citou (557 e 344) não batem com os que medi (603 e 391 em `5e8f8b4`); 455 e 308 batem.
- O `main` andou durante a revisão (`4f50f84` → `5e8f8b4`); refiz as leituras nos arquivos afetados.

8. RISCOS
- A ponte quebra se o `npc` for refatorado por dentro (I1).
- Se Arthur quiser conversar na janela (LW-086) antes de I3, o cruzamento impasse × conversa vai ser exercitado só na mão.

9. PENDÊNCIAS
- O que NÃO verifiquei (lista completa na seção 5 de `REVISAO-085-C.md`): nada rodado no Godot; `check_all` verde em `5e8f8b4` não confirmado por mim; causa exata da mudança das impressões do oráculo (li, não reproduzi); `src/app` (raiz de composição) não revisado; janela do jogo; custo e memória.
- Teste manual para Arthur: nenhum novo.

ACOMPANHAMENTO
- Avanço: revisão cruzada pré-LW-085 concluída (item 4 da mensagem de Arthur). Falta: decisões abaixo; a LW-085 em si não foi iniciada.
- Próxima tarefa recomendada: LW-084 (soak longo) antes da LW-085; ou, se Arthur preferir, I1 e I3 como tarefas pequenas primeiro. **Não iniciada.**
- Decisões que dependem de Arthur: (a) B1: fazer a LW-084 antes (recomendo); (b) I1: autorizar a regra nova no `check_architecture` (recomendo sim); (c) I2: autorizar os passos 1 e 2 e registrar decisão sobre as classes aninhadas (recomendo aceitar); (d) I3: autorizar o teste impasse × conversa (recomendo sim); (e) M8: linha em `docs/decisions/` sobre `save_version` antes do "save congelado" (recomendo).
- Git: nada commitado no projeto. Neste ramo, um commit "status c: revisão pré-LW-085, CONCLUÍDA" e push só de `status-c`. Nada foi enviado ao `main`. README e `docs/modules/README.md` ficam para a revisão da LW-085, como Arthur mandou.
