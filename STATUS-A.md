10/11/2026 13:08 (Brasília) · CONCLUÍDA · LW-073, Fase B (refeita, opção A de Arthur)

# RELATÓRIO CURTO — LW-073, Fase B

**Resultado:** o `main` foi de `4f50f84` para **`5e8f8b4`** em avanço rápido, na primeira rodada. Sem tag, sem `--force`. A pilha da LW-073 (073a, 073b, 073c) está no `main`.

## B0: junção
- Ramo: `lw-073c-soak-30d-impasse` (topo da pilha). `origin/main` = `4f50f84` (já com a LW-082).
- Merge `5338cbc`. Único conflito: `docs/ROADMAP_STATUS.md`, **só a linha 3 (cabeçalho)**, que os dois lados alteraram. As linhas de tabela (a minha LW-073 e a LW-082 do main) juntaram sozinhas. O `npc_module.gd` e o `npc.md` juntaram sozinhos.
- Resolução: a linha do main + a LW-073 nas duas listas (e "da LW-060 à LW-073") + contagens **main + 1**. Conferido por `diff` contra cada pai: só o cabeçalho e a linha da tarefa do outro lado diferem; nenhuma linha se perdeu.
- Contagem por `grep`: main mostrava **28 de 32 (87,5%) e 83 de 192 (43,2%)**; depois: **29 de 32 (90,6%) e 84 de 192 (43,8%)**. README com os mesmos números (commit `5e8f8b4`), com a LW-082 acrescentada à lista.

## B2: bateria inteira (depois do `--import`)
- `check_all` **VERDE**: 121 scripts, 1.180 testes, 261.521 asserts, zero erro de script, zero avisos (303 scripts verificados).
- Oráculo: as 5 impressões que não podem mudar (`intents`, `alarm`, `resumed`, `switches`, `real_game`) **iguais**; as 4 constantes (`talk`, `save`, `demote`, `starved`) são as autorizadas por Arthur (valores completos conferidos) e o obtido é igual a elas.
- Vida de 30 dias: `d13b921112ce` nas 3 linhas, problemas 0, **igual ao main atual** (`4f50f84`, medido num checkout limpo).
- `run_sim` 7 dias, sementes 1, 2 e 3: **iguais ao main atual**. Tabela de 7 dias dos corpos: **idêntica**.
- Soak de impasse de 30 dias: **0 recuperações**, 0 registros, hash `d13b921112ce`.

## B3: envio
- `--dry-run` e push do ramo (`1db3925..5e8f8b4`); `merge-base --is-ancestor origin/main HEAD` verdadeiro; push `lw-073c-soak-30d-impasse:main` = `4f50f84..5e8f8b4`.

## Estado do Git
- `main` = `5e8f8b46e133`. `lw-073c-soak-30d-impasse` = `5e8f8b4`; `lw-073b-impasse-s0` = `5346091`; `lw-073a-detector-impasse` = `906887d`. Tags: só `fase-0-concluida` e `fase-1-concluida`.
- Este ramo (`status-a`) nunca vai para o main e só recebe `STATUS-A.md` e `REVISAO-085-A.md`.
- Nada rodando em segundo plano. A pasta principal não foi tocada.

## Riscos e não verificado
- Nada visto em janela. Em S0, a recuperação de um NPC solta e recoloca o corpo (só testado com apresentação simulada). A sequência de vencimentos e o registro somem ao carregar um save. Limite de 60 min e registro de 32 são **[HIP]**.
- A Fase B da LW-082 (outra conversa) entrou no main enquanto eu verificava; por isso a rodada foi refeita, como autorizado.

## Próximo passo
- Revisão cruzada pré-LW-085 (LW-082 e LW-083), só leitura, sem Godot. Resultado em `REVISAO-085-A.md`.
