# LW-085 — Revisão da Fase 2: três decisões de Arthur sobre os achados das revisões A e C

- **Status:** **decisões de Arthur, por escrito, em 10/11/2026** (mensagem que autorizou as subtarefas LW-085b e LW-085d), registradas aqui pela LW-085d. **Ainda sem entrada em `DECISIONS.md`**: a proposta de entrada vai no relatório da LW-085d (Arthur a registra, se quiser).
- **Data e tarefa:** 10/11/2026 (Brasília), LW-085 (revisão arquitetural da Fase 2, `docs/DEVELOPMENT_ROADMAP.md`, linha da LW-085), subtarefa LW-085d. Origem: revisão A (I-2, I-4 e M-1) e revisão C (I2 e M8; `REVISAO-085-C.md`, no ramo `status-c`). Medido em `origin/main` `5e8f8b4`.
- **Rótulos:** **fato** (com origem), **decisão** (de Arthur), **limitação**.

## 1. Arquivos grandes: aceitar, contando só código, com folga de 1,5×

- **Contexto (fato):** o AGENTS pede arquivos de até ~300 linhas (4.5) e tarefas de ~300 linhas e ~8 arquivos (5.2). Seis arquivos de `src/npc` e `src/bridge` passam disso contando tudo (total, só código): `npc_module.gd` 603 (336), `npc_thinker.gd` 455 (328), `action_runner.gd` 415 (304), `sim_bridge.gd` 391 (236), `npc_memory.gd` 325 (236) e `npc_notables.gd` 308 (213). Em `npc_module.gd` as classes aninhadas (linhas ~456 a 603) têm 221 referências no projeto.
- **Opções:** (a) dividir já: o pensador em duas classes (~170 linhas movidas) e os comandos de depuração do módulo em outro arquivo (~140); (b) aceitar com uma regra de contagem; (c) deixar como está sem registrar.
- **Decisão:** **(b).** O limite conta **só código** (sem comentário nem linha em branco) com **tolerância de 1,5×** (cerca de 450 linhas de código por arquivo). **Nada é dividido agora**, e as classes aninhadas do `npc_module.gd` ficam onde estão. A mesma contagem (só código e teste, sem comentário, linha em branco, `.uid` nem documento, teto de 1,5×) vale para o tamanho de cada tarefa (~300 linhas e ~8 arquivos).
- **Consequências:** por essa regra nenhum arquivo de `src/` passa do limite (o maior tem 336 linhas de código). **Limitação:** o AGENTS continua dizendo "~300 linhas" (4.5 e 5.2); a regra vale por esta decisão até Arthur atualizar o AGENTS (só ele o altera). Se um desses arquivos crescer perto de 450 linhas de código, a divisão volta à pauta; a divisão está descrita na revisão C (I2).

## 2. `save_version` continua em 2 até o "save congelado"

- **Contexto (fato):** o AGENTS (4.15) manda atualizar `save_version` quando o estado salvo muda. `CURRENT_SAVE_VERSION` vale 2 desde a LW-026 (`src/persistence/json_save_codec.gd:9`) e o estado salvo do `npc` cresceu depois disso (por exemplo `last_player_talk_at`, LW-083b, gravado só quando difere de -1). A DEC-083 (princípios aprovados) e a arquitetura (cap. 18, "proporcionalidade") deixam a migração para depois do "save congelado" (proposta: depois da validação da Fase 4). Não existe tela de salvar: os únicos saves hoje são os dos testes.
- **Opções:** (a) subir o número a cada mudança, como o AGENTS manda; (b) manter 2 até o congelamento; (c) subir só uma vez, agora.
- **Decisão:** **(b).** O número fica em 2 até o "save congelado". A garantia de cada mudança de estado é o teste de ida e volta (que existe e roda no `check_all`) e a validação de `on_load`.
- **Consequências e risco:** o número **não distingue** os saves da Fase 2 entre si; quem protege é o `on_load` (confere tipos, faixas e campos, com mensagem clara) e o teste de ida e volta. Como não há save de jogador, nada se perde hoje. Antes do congelamento é preciso fixar o número final e a política (DEC-083 e DEC-084 seguem pendentes e PROPOSTA); isso é decisão de Arthur.

## 3. `project.godot` recebeu cinco ações de entrada na LW-082g, com autorização

- **Contexto (fato):** `project.godot` é arquivo protegido (AGENTS 12.5: só se a tarefa mandar). A 082g (commit `89c8182`) acrescentou **25 linhas**, as ações `inspector_toggle` (F3), `inspector_toggle_alt` (Tab), `inspector_next` (N), `inspector_previous` (B) e `inspector_trace` (T), sem remover nem alterar nada do arquivo. A revisão A (I-4) apontou o arquivo protegido.
- **Decisão:** Arthur **autorizou por escrito** na 082g: "só ADICIONAR ações de entrada". O que foi feito cabe exatamente nisso (verificado em `git show 89c8182 -- project.godot`: só linhas acrescentadas, todas das cinco ações). Não é desvio: fica registrado para a auditoria.
- **Consequências:** as teclas são [HIP] e entram só como ações nomeadas (`InputActions`); o painel só abre em build de desenvolvimento. A linha da LW-082 no `ROADMAP_STATUS.md` leva o mesmo registro. Qualquer outra mudança em `project.godot` continua exigindo autorização expressa.

## Validação e referências

- Medidas: `wc -l` e contagem sem linhas em branco e sem linhas de comentário, em `origin/main` `5e8f8b4`; `git show 89c8182 -- project.godot`.
- Relação com: DEC-083 e DEC-084 (salvamento), AGENTS 4.5, 4.15, 5.2 e 12.5, `docs/decisions/0009-spike-sp2-corpos-e-lod.md` (a DEC-122, "por ora", segue como está; a revisão final da LW-085 trata dela).
