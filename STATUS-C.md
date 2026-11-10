10/11/2026 16:22 (Brasília) — CONCLUÍDA: relatório final da LW-085 entregue (PRONTA PARA REVISÃO; a LW-085 NÃO é contada como concluída; 085c: pendente). Nada rodando; nada novo no `main`.

RELATÓRIO FINAL — LW-085: Revisão arquitetural da Fase 2        Status: PRONTA PARA REVISÃO (falta a sua auditoria e a sua frase de aprovação)

Li antes: AGENTS (inteiro), linha da LW-085 (`docs/DEVELOPMENT_ROADMAP.md:632`), as duas revisões (A: `REVISAO-085-A.md`, ramo `status-a`; C: `REVISAO-085-C.md`, ramo `status-c`), os relatórios da A (`STATUS-A.md`, LW-085a) e da B (`STATUS-B.md`, LW-084), `docs/decisions/` (0009, 0010, 0011), `docs/ROADMAP_STATUS.md` e `docs/events.md`. Decisões: DEC-119, 122 (APROVADA por ora), 123 (só a direção), 124, 125; DEC-083 e DEC-084 (save); DEC-040 e DEC-071 (PENDENTE/PROPOSTA, valores [HIP]). Base: `main` = `1dd2fb4`.

1. RESUMO
As duas revisões cruzadas (A e C, só leitura) não acharam defeito de código bloqueante. O que era importante foi corrigido ou registrado: a ponte só cita a `api/` do `npc` (085a, com regra nova no `check_architecture`), o cruzamento impasse × conversa ganhou teste (085b), as três decisões de Arthur estão registradas (0011) e a LW-084 mediu o custo de memória e relações em 1 ano com 300 NPCs (estável). **Falta só a 085c** (custo do painel de NPC): "085c: pendente". A LW-085 não está concluída: depende da sua auditoria e da sua frase.

2. TABELA DOS 8 CRITÉRIOS (linha da LW-085, `docs/DEVELOPMENT_ROADMAP.md:632`)
| # | Critério | Resultado | Evidência |
|---|---|---|---|
| 1 | Limites do módulo `npc` | **OK, com ressalvas registradas** | Porta `src/sim/npc/api/` (8 classes, 3 delas as visões da 085a); a ponte só cita a `api/` (regra D: acusava 12 linhas no `main` anterior, hoje 0). Tamanho pela regra do 0011 (só código, folga 1,5× ≈ 450): o maior é `npc_module.gd` com 346 linhas de código (620 no total), depois `npc_thinker.gd` 328, `action_runner.gd` 304. Ressalvas: classes aninhadas do módulo ficam onde estão (decisão); retornos de `explain_decision`, `peek_memories` e `peek_routine_action` seguem de tipo interno (a ponte lê pelas visões) e `peek_npc_bodies` ainda lê o membro público `lod` (backlog) |
| 2 | Catálogo em dados | **OK, com ressalva** | Ações (incluindo `talk_player`), necessidades, ofícios, tipos de memória, parâmetros do `npc`, estoque e renda em `data/*.json`. Ressalva: ids de conteúdo repetidos como constantes (`"work"` em 3 arquivos, `"help"` em 2…) e alcance (3 m) e cooldown (60 min) da conversa em constantes [HIP]; os dois estão no backlog |
| 3 | Função única de efeitos | **OK** | `ActionRunner.apply_effects` é o único ponto que aplica efeitos de ação, nos dois modos (S1 e S0), guardado por `test_action_single_path.gd` e provado equivalente pela LW-075. `talk_player` não tem efeitos. O comentário agora diz a verdade: `NeedMath.settle` e `NeedMath.add_pressure` (alarme) também escrevem em `need_values`, mas não são efeito de ação |
| 4 | Ponte fina | **OK (depois da 085a)** | `SimBridge` só delega e formata; cita só `api/`; a regra D guarda. Ressalva: `sim_bridge.gd` 391 linhas (236 de código) e o resumo do painel chama `world.validate()` do mundo inteiro a cada ~1 s: o custo é a 085c (pendente) |
| 5 | Sem dinheiro e mercado antecipados | **OK** | Busca por `ledger`, `money`, `price`, `market`, `trade`, `gold`, `wage` em `src/sim/npc` e `data/*.json`: só os comentários dos dois stubs ("sem dinheiro, preço, Ledger ou mercado"); `market_reserved` é vocabulário de local que já existia |
| 6 | Marcas `TEMP` | **OK** | Só `TEMP-LW-065` (`FoodStub`, sai na LW-094) e `TEMP-LW-066` (`IncomeStub`, sai na LW-095), no código, nos dados e no Anexo D; nenhuma marca nova nas LW-082 a LW-085; zero `TODO`, `print(`, `await`, `@warning_ignore` e `static var` em `src/sim`, `src/bridge` e `src/tools`. Ressalva: o estoque do `FoodStub` entra no save, então a LW-094 muda o formato dele |
| 7 | Custo de memória e relações | **OK, medido** | LW-084: 300 NPCs [HIP], 40 notáveis, 8 execuções de 1 ano em depuração: 300 vivos o tempo todo, **0 mortes, 0 erro de `validate()`**, hash igual dentro de cada padrão (`5141d7e7a84b` e `50af223b6f51`). Memória estática +1,83 a +1,92 MiB **só nos primeiros 30 dias**; do dia 30 ao 360, 0 a 0,1 MiB; objetos estáveis (4.175 a 4.226). Save 19,6 a 20,4 KiB comprimido (338 a 345 KiB sem comprimir), estável. Passo: média 2,3 a 2,7 ms em depuração e 1,75 a 1,87 ms em release (régua [HIP] ~3 ms); passos acima de 10 ms existem (0,1 a 0,4%) e são só informativos por decisão sua. Os 40 notáveis saturam: memórias 24/24 (teto), relações 8 a 16 de 16, traços 0 (o limiar 80 nunca é atingido). **Limites:** corpo falso, conversa do jogador fora do soak, ano em release não rodado, e o custo do painel é a 085c |
| 8 | Resultado do SP2 | **Registrado, com pontos abertos** | `docs/decisions/0009-spike-sp2-corpos-e-lod.md` (proposta) e DEC-122 (APROVADA por ora), DEC-123 (só a direção), DEC-124. Abertos: a régua oficial falhou em 3 de 13 ensaios e a causa dos trancos ficou aberta; a navegação N1 é reta e atravessa pedra (backlog); toda caminhada em S0 chega atrasada em relação ao S1; os números de quadros não estão no repositório. A LW-084 **não** mede isso (corpo falso) |

3. O QUE FOI CORRIGIDO
- **LW-084 (B)** — resolveu o bloqueio de processo B1 da revisão C: o soak de 300 NPCs por 1 ano existe e rodou limpo.
- **LW-085a (A)** — a ponte cita só a `api/` do `npc` (visões de dados puros + 6 constantes reexportadas + `peek_level_of` e `peek_s0_count`) e a regra D do `tools/check_architecture` impede a volta (I-1 da A, I1 da C). Sem mudança de comportamento: oráculo, hashes e `run_sim` iguais.
- **LW-085b (C)** — teste do impasse com a conversa (I3 da C): `test_impasse_conversation.gd`, com controle de mutação (quatro defeitos injetados foram pegos); comentários do oráculo (cinco impressões de `5a7d453`, quatro da LW-073b) e de `ActionRunner.apply_effects` acertados (M1 em parte e M4 da C, M-2 da A), sem mudar código.
- **LW-085d (C)** — `docs/events.md` com os ouvintes reais (M2), índice de contratos com o `tools.md` (M-6 da A), texto da 082 e da 083 e hora inicial 05:45 no README, nota do `project.godot` na linha da LW-082, backlog.

4. O QUE FOI REGISTRADO
- `docs/decisions/0011-revisao-fase-2.md` (três decisões de Arthur): (1) arquivos grandes aceitos, contando só código, folga 1,5×, nada dividido agora, classes aninhadas do `npc_module.gd` ficam; (2) `save_version` em 2 até o "save congelado"; (3) as cinco ações de entrada (F3, Tab, N, B, T) no `project.godot` da 082g, autorizadas ("só ADICIONAR ações de entrada").
- `docs/decisions/0010-soak-longo-300-npcs.md` (B): resultados, rótulos e proposta de régua de memória.
- Linha da LW-082 no `ROADMAP_STATUS.md` com o registro do `project.godot`.

5. O QUE FOI PARA O BACKLOG (`docs/backlog.md`, já no `main`)
- C/085d: alcance e cooldown da conversa em dados; alcance de 3 m duplicado (sim e apresentação); `src/tools/` fora de `check_architecture` e `check_literal_text`; trava de desenvolvimento copiada 5 vezes em `npc_module.gd`; ids de conteúdo em constantes; "Deprecated 1" do GUT (`wait_frames`, desde a LW-020/021).
- A/085a: trocar os retornos de `explain_decision`, `peek_memories` e `peek_routine_action` por tipos da `api/`; `peek_npc_bodies` lê o membro público `lod`; a regra D só vale para módulos com pasta `api/` e deixa `src/app` e `src/persistence` de fora.
- B/084: ano em release; dividir o medidor (330 linhas); laço de controle intercalado; notáveis no teto de memórias.
- Antes: navegação com curvas e desvio de obstáculos (N1, DEC-122); o NPC se virar para o jogador; ação interrompida pela conversa não é retomada; teto de 40 do T2.

6. AINDA ABERTO SEM LINHA NO BACKLOG (proposta minha; não editei o `main`)
- **M4:** teste que lista os arquivos que escrevem em `need_values` e falha se aparecer outro (~30 linhas); hoje `test_action_single_path.gd` só olha os efeitos de ação.
- **M1 (resto):** `docs/modules/npc.md` (linhas 136 e 220) ainda diz "nove impressões tiradas de `5a7d453`" e o comentário de `npc_module.gd` (linha 418) diz que o resumo "não pode mudar enquanto não há impasse"; ficaram fora do que você autorizou.
- **M6:** `CM_PER_METER` repetido em `npc_thinker.gd` e `npc_player_talk.gd`, havendo `TerrainData.CM_PER_METER`.
- **M9:** a LW-094 deve dizer que remover o `FoodStub` muda o save.
- **085c (custo do painel; I-3 da A, M7 da C):** pendente.

7. ARQUIVOS DESTA ENTREGA
- Criados: nenhum no projeto (este relatório fica só no ramo `status-c`).
- Modificados: nenhum no `main`. **Preparei, sem enviar,** a linha da LW-085 no `ROADMAP_STATUS.md` (estado "em auditoria"; não conta como concluída; a contagem continua 30 de 32 e a conferência por script deu 31 linhas de tarefa, 30 concluídas): ramo local `lw-085-final` (commit `5574c11`, só em `.worktrees/lw-085-fb`), nunca enviado. Texto: "Relatório final entregue em 10/11/2026; a LW-085 NÃO está concluída e não entra na conta: falta a auditoria e a frase de aprovação de Arthur", com corrigido, registrado, medido, pendente e limite.

8. TESTES EXECUTADOS
- Nenhum novo nesta etapa (relatório). Os resultados que cito são de execuções minhas e dos outros: `check_all` VERDE em `8b910f1` (123 scripts, 1.190 testes, 261.668 asserts) e VERDE em `1dd2fb4` pela B (124 scripts, 1.194 testes, 261.693 asserts); oráculo, vida de 30 dias e `run_sim` iguais nas três junções (A, C e B). Reconferi por busca (sem Godot) os critérios 1, 4, 5 e 6 em `1dd2fb4`: `rg` na ponte sem classe interna do `npc`, sem dinheiro e mercado, sem `TODO`, `print(` ou `await`.
- **NÃO EXECUTADO** (por não caber numa revisão e por ordem): o painel e a conversa na janela; frames do SP2; o custo do painel (085c); o ano em release.

9. PROBLEMAS ENCONTRADOS
- Dois conflitos de `docs/backlog.md` quase aconteceram na mesma tarde (comigo e com a B: as duas pontas acrescentam linhas no fim). Pela sua regra, cada um moveu as próprias linhas para o meio do arquivo em vez de resolver à mão. Isso tende a se repetir.
- A premissa errada do meu teste (a sequência de vencimentos não começa na conversa) foi corrigida na 085b e está explicada lá.
- O `status-a` carrega a árvore inteira do projeto (e o `status-c`, o meu, também): só os arquivos de status diferem do `main`.

10. RISCOS
- A 085c pode mostrar que o `validate()` do mundo, chamado a cada ~1 s com o painel aberto, é caro com 300 NPCs; só afeta build de desenvolvimento.
- Os 40 notáveis saturam as memórias em 1 ano: se a Fase 3 quiser memória que não sature, tetos e limiar de traços precisam de decisão.
- A janela do jogo ainda não viu o painel (F3) nem a conversa (E perto de um NPC), e a ponte do painel mudou de caminho na 085a.
- O soak da B usa corpo falso e foco que "teletransporta": o custo de S0 é o do protocolo e do LOD, não de física, navegação ou desenho.

11. PENDÊNCIAS
- **085c:** pendente (B está medindo; sem ramo no remoto às 16:16).
- **Teste manual para você (janela, em build de desenvolvimento):** (1) F3 ou Tab abre o painel; (2) N e B trocam de NPC e a lista mostra S0/S1; (3) T marca o rastro e o rastro aparece; (4) perto de um NPC, E conversa: ele para, a conversa mostra o texto provisório e o painel mostra a memória e a relação; (5) nada deve parecer diferente do que era antes da 085a.

ACOMPANHAMENTO
- Avanço: LW-085 com relatório final entregue; Fase 2 segue em 30 de 32 (93,8%); a LW-085 NÃO está contada. Falta a auditoria e a sua frase, a 085c e a LW-086 (validação sua).
- Próxima tarefa recomendada: auditoria da LW-085 e, depois da sua frase, a LW-086. **Não iniciadas.**
- Decisões que dependem de Arthur (com a minha recomendação): (1) aprovar a LW-085 depois da auditoria, esperando ou não a 085c (recomendo esperar: é curta e é o único critério sem número); (2) registrar a proposta de entrada para o `DECISIONS.md` com as três decisões do 0011 (recomendo); (3) atualizar o AGENTS 4.5 e 5.2 com a contagem de 1,5× (recomendo); (4) aceitar o SP2 "por ora" (DEC-122) com os pontos abertos ou pedir medição de quadros na LW-086 (recomendo medir na janela durante a LW-086); (5) a régua definitiva de memória da B (no máximo 0,5 MiB entre o dia 30 e o 360; observado 0 a 0,1) e o que fazer com a saturação das memórias dos notáveis; (6) liberar a resolução automática de conflito só de acréscimo em `docs/backlog.md` (recomendo; já aconteceu duas vezes hoje); (7) quais itens do backlog (ids em dados, alcance e cooldown em dados, tipos da `api/`) entram antes da Fase 3 (recomendo ids e tipos da `api/`).
- Git: nada novo no `main` nesta etapa (`main` = `1dd2fb4`). Ramo local `lw-085-final` (`5574c11`) com a linha da LW-085 em auditoria, **nunca enviado**. Neste ramo `status-c`: só `STATUS-C.md` e `REVISAO-085-C.md`.
