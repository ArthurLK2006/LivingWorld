# REVISÃO CRUZADA PRÉ-LW-085: núcleo do `npc` e LW-083 (conversa)

**Agente C, papel de REVISOR (AGENTS seção 11). Só leitura: nada foi implementado, nenhum código commitado, o Godot não foi executado.**
Data: 10/11/2026 13:13 (Brasília). Este arquivo mora no ramo `status-c`, que nunca vai para o `main`.

## 0. Base revisada e como li

- **Base:** `origin/main` em `5e8f8b4` (LW-073 e LW-082 já juntas; o `main` andou de `4f50f84` para `5e8f8b4` às 12:58 de 10/11, durante a revisão).
- **Como li:** extraí árvores com `git archive` (`4f50f84`, `1db3925` e `5e8f8b4`, na pasta de rascunho da sessão) e usei só `rg`, `wc`, `diff`, `sed`, `git log/show/merge-base`. Rodei apenas os três verificadores de shell que não usam o Godot (`tools/check_architecture`, `check_input_keys`, `check_literal_text`), todos verdes em `5e8f8b4`.
- **Números que não batem com os de Arthur:** `wc -l` em `5e8f8b4`: `npc_module.gd` **603** (336 sem comentário e linha vazia; em `4f50f84` eram 590; Arthur citou 557), `npc_thinker.gd` **455** (328), `sim_bridge.gd` **391** (236; Arthur citou 344), `npc_notables.gd` **308** (213). Dois batem (455 e 308); os outros dois não: provavelmente foram contados em outro commit.
- **Critérios:** a linha da LW-085 em `docs/DEVELOPMENT_ROADMAP.md:632` e a lista da seção 11 do AGENTS.

## 1. Veredito em uma frase

**Nenhum defeito de código bloqueante.** Há **1 bloqueio de processo** (a LW-084 não existe), **3 achados importantes** (a ponte cita classes internas do `npc` e a regra da porta `api` não é verificada por ninguém; `npc_module.gd` e `npc_thinker.gd` passaram muito de 300 linhas; falta teste que junte impasse e conversa) e **9 menores**. O que o roadmap pede para a LW-085 está, no conjunto, em ordem: marcas `TEMP`, ausência de dinheiro e mercado, função única de efeitos, catálogo em dados, eventos catalogados.

## 2. Achados

### BLOQUEANTE (de processo, não de código)

**B1. A LW-084 (soak longo, 300 NPCs por 1 ano) não existe, e é dependência declarada da LW-085.**
- Evidência: `DEVELOPMENT_ROADMAP.md:632` (a LW-085 depende de "LW-084, LW-075, LW-073, LW-082"); `docs/modules/npc.md:216` prevê `tests/soak/test_npc_soak_1y.gd` (300 NPCs, 1 ano) e esse arquivo **não existe** em `tests/soak/`; `docs/ROADMAP_STATUS.md` só traz linhas de tarefas já feitas e não tem a da LW-084 (ou seja, não foi iniciada).
- Efeito: o critério "custo de memória e relações" fica sem medição de 1 ano. Só tenho limites de projeto (`data/npc_params.json`: `memory_capacity` 24 e `relations_capacity` 16 por NPC) e os soaks de 100 NPCs por 30 dias. Crescimento de memória, pico de tick com 300 NPCs e custo do `validate()` do mundo ficam **NÃO MEDIDOS**.
- Proposta de correção: a própria LW-084, planejada antes (estimativa minha, **hipótese**: ~150 linhas de código e teste, reaproveitando o verificador `NpcLifeCheck` de `tests/soak/npc_life/`; falta ver como o jogo cria 300 NPCs, porque a população vem de `data/`). Alternativa, se Arthur quiser rodar a LW-085 antes: marcar o critério de custo como "sem medição" no relatório e abrir a LW-084 como pendência explícita. Decisão de Arthur.

### IMPORTANTES

**I1. A ponte cita classes internas do `npc` (fora de `api/`), e nenhuma verificação pega isso.**
- Onde: `src/bridge/bridge_replies.gd:169` (`NpcLod.CODE_NOT_IN_S0`), `:170` (`NpcTiers.CODE_DEAD`), `:172-173` (`RelationGraph.CODE_INVALID`, `CODE_NOT_ALLOWED`), `:174` (`NpcLod.CODE_INVALID_POSITION`); `src/bridge/bridge_npc_inspect.gd:132` (`NpcMemory.Trait`) e `:157` (`NpcLod.LEVEL_S0`). Essas classes moram em `lod/`, `state/`, `relations/` e `memory/`, não em `src/sim/npc/api/`.
- Regra: AGENTS 5.1 ("apenas a porta de entrada (`api`)") e a regra 13; critério "ponte fina" da LW-085.
- Por que ninguém viu: `tools/check_architecture` só confere camadas, "apresentação só pela ponte", contratos README, eventos catalogados e autoloads; **não tem regra da porta `api`** (busca por "api" no script: nada). `src/bridge/bridge_inspect_replies.gd:10` mostra que alguém já tinha o cuidado certo (copia as constantes de camada "porque quem consome não pode citar `NpcState`"), então o resto é inconsistência, não decisão.
- Efeito: um refatoramento interno do `npc` (como o da LW-081a, que dividiu o `npc_module.gd`) pode quebrar a ponte. A apresentação e as ferramentas, por sua vez, **não** citam classe interna (busca limpa em `src/presentation` e `src/tools`): o problema é só da ponte.
- **Proposta de correção (~80 linhas de código e teste, 5 a 6 arquivos):** (a) `NpcModule` ganha constantes que repetem os códigos e o nível (`CODE_NOT_IN_S0`, `CODE_DEAD`, `CODE_RELATION_INVALID`, `CODE_RELATION_NOT_ALLOWED`, `CODE_INVALID_POSITION`, `LEVEL_S0`; ~8 linhas); (b) `bridge_replies.gd:169-174` e `bridge_npc_inspect.gd:157` passam a usar `NpcModule.*`; (c) para `NpcMemory.Trait` (`bridge_npc_inspect.gd:132`), dar à `api` um nome para o tipo (por exemplo uma constante de classe): **[a confirmar com teste curto no Godot 4.7.2 se uma constante serve de tipo]**, senão copiar os campos num tipo da `api`; (d) regra nova em `tools/check_architecture` ("`src/bridge`, `src/presentation` e `src/tools` só citam classes de `src/sim/<módulo>/api/`"; `src/app` fica de fora por ser a raiz de composição; ~25 linhas de shell) e dois casos em `tests/test_check_architecture.sh` (~20 linhas). Mexer em `check_architecture` não é arquivo protegido, mas muda a política de verificação: pedir o OK de Arthur.

**I2. `npc_module.gd` (603 linhas) e `npc_thinker.gd` (455) passaram muito do limite de ~300 (AGENTS 4.5 e 5.2).**
- Os outros acima de 300: `action_runner.gd` 415 (304 de código), `sim_bridge.gd` 391 (236), `npc_memory.gd` 325 (236), `npc_notables.gd` 308 (213). `terrain_view.gd` (322) é de outra fase e não entra.
- `npc_module.gd`: 5 comandos só de desenvolvimento (`request_record_memory` `:138`, `request_adjust_relation` `:169`, `request_raise_alarm` `:205`, `request_set_traced` `:226`, `request_set_food_stock` `:301`) repetem a mesma trava (`_definitions == null or not _definitions.is_development_build`, linhas `:139`, `:170`, `:206`, `:227`, `:302`); as classes de dados aninhadas ocupam `:456-603` (150 linhas: `Definitions` `:456`, `MemoriesQuery` `:488`, `OpinionQuery` `:502`, `ConverseResult` `:523`, `CreateResult` `:537`, `NpcQuery` `:549`).
- `npc_thinker.gd`: `ConditionProvider` (`:418-455`), a reação ao alarme (`react_to_alarm` `:96`, `_with_alarm_reactions` `:248`, `_apply_alarm_pressure` `:269-272`, `_nearest_place_id` `:273`, classe `Alarm` `:378`) e `Candidate` (`:392`).
- **Proposta de divisão (cada passo é uma tarefa pequena, só movimento de código; o oráculo `tests/integration/test_npc_split_oracle.gd`, o resumo de 30 dias e o `run_sim` provam que nada mudou):**
  1. `npc_thinker.gd` → tirar `ConditionProvider` para `decision/npc_condition_provider.gd` (~38 linhas) e a reação ao alarme para `decision/npc_alarm_reaction.gd` (~110 linhas). Sobra ~300. Atenção: `NpcThinker.FLEE_ACTION_ID` e `HELP_ACTION_ID` são citados em `npc_player_talk.gd:19`; manter as constantes ou atualizar essas 2 ou 3 referências. Custo: ~170 linhas movidas, 5 arquivos.
  2. `npc_module.gd` → mover os 5 comandos de desenvolvimento para `api/npc_dev_commands.gd` com a trava escrita **uma vez**; o módulo mantém funções de 1 linha que delegam (API pública igual). Tira ~120 linhas e some com as 5 cópias da trava. Custo: ~140 linhas, 3 arquivos.
  3. **Não recomendo** mover as classes aninhadas de `npc_module.gd` agora: no `main` de `4f50f84` há **221 referências** (`NpcModule.NpcQuery` 119, `CreateResult` 40, `Definitions` 38, `ConverseResult` 24); a renomeação passaria do limite de 8 arquivos. Peço a Arthur uma **decisão registrada**: aceitar `npc_module.gd` com ~480 linhas depois do passo 2 (as classes são o "vocabulário" da porta), ou autorizar a renomeação mecânica como tarefa própria.
  4. `action_runner.gd`, `sim_bridge.gd`, `npc_memory.gd`, `npc_notables.gd`: sem divisão agora (a conta só de código dá 304, 236, 236 e 213; coesão boa; sem alerta de acoplamento). O `action_runner.gd` já está como [LIM] aberto em `docs/modules/npc.md:209`.

**I3. Falta um teste que junte o detector de impasse e a conversa com o jogador.**
- Evidência: `rg -l 'Impasse' tests | xargs rg -l 'talk_player|request_converse'` não acha nenhum arquivo. A LW-083f (`tests/integration/test_player_npc_talk.gd`) faz o papel do corpo e relata `DONE`; os testes de impasse não conhecem `talk_player`.
- Por que importa: `talk_player` interrompe a ação em curso (`npc_decision_runtime.gd:76-96`) e entrega uma Intent a um corpo S0; se o corpo nunca responde (jogador se afasta, corpo devolvido ao pool), quem decide o destino do NPC passa a ser o `result_timeout` do detector. É o único caminho novo da fase em que as duas peças se cruzam, e ninguém o exercita. **Não sei se há defeito**: só sei que não há teste.
- **Proposta (≤ ~90 linhas, 1 arquivo de teste em `tests/integration/`):** montar o jogo real como o `test_player_npc_talk.gd`, começar uma conversa, **não** relatar `DONE`, avançar o relógio além do tempo limite da Intent e do limite do impasse; conferir (1) uma única `NpcImpasseRecovered` com `reason` `result_timeout`, (2) o NPC fora de `talk_player` e sem Intent pendente, (3) `last_player_talk_at` preservado e o cooldown ainda valendo, (4) `validate()` vazio. Se falhar, é bug real e vira tarefa de correção.

### MENORES

- **M1. Comentários e texto de documento desatualizados sobre o oráculo.** `tests/integration/test_npc_split_oracle.gd:6-8` e `:42` dizem que os valores saíram do commit `5a7d453`, mas `talk`, `save`, `demote` e `starved` (`:48-51`) foram trocados na LW-073b (`5346091`), por decisão de Arthur de 10/11/2026, porque o NPC "LATE" (corpo 40 min atrasado, tempo limite de 30) passou a ser recuperado. Isso **está explicado** em `docs/modules/npc.md:76` e `ROADMAP_STATUS.md:135`, mas `npc.md:135` e `:209` ainda falam em "nove impressões tiradas de `5a7d453`", e `npc_module.gd:400-401` diz que o resumo "não pode mudar enquanto não há impasse" (a explicação é que havia impasse no cenário LATE). Correção: ~6 linhas de comentário e texto (docs não contam na regra de tamanho).
- **M2. `docs/events.md:12-13` diz que a apresentação, "pela ponte", ouve `LodChanged` e `NpcDied`.** No código só existe **um** assinante do `EventBus` (`npc_module.gd:199`, `AlarmRaised`); a apresentação lê por `peek_*` e Intents. As linhas `:14` e `:16` ("o painel lê") estão certas no sentido de consulta, mas a coluna se chama "Ouvintes". Todos os 5 eventos publicados (`LodChanged` `npc_bodies.gd:105`, `NpcDied` `npc_lifecycle.gd:89`, `AlarmRaised` `npc_module.gd:210`, `RelationChanged` `npc_notables.gd:113`, `NpcImpasseRecovered` `npc_impasse.gd:152`) estão no catálogo, em `PascalCase` e no passado. Correção: reescrever a coluna "Ouvintes" (~5 linhas de doc).
- **M3. A trava "só em build de desenvolvimento" aparece 5 vezes copiada** (`npc_module.gd:139,170,206,227,302`). Resolvida junto com o passo 2 da I2.
- **M4. Segundo escritor de `need_values`.** `NeedMath.add_pressure` (`need_math.gd:78-84`, chamado por `npc_thinker.gd:269-272`) soma pressão em `safety` fora do `ActionRunner.apply_effects`. Não dá divergência S0/S1 (a reação ao alarme roda antes do corpo, igual nos dois), então **não é violação da função única de efeitos**, mas o teste `test_action_single_path.gd` (lista `EFFECT_ROW_FILES` na linha `:9`, já ampliada duas vezes: LW-062 e LW-063) não olha esse segundo caminho, e `npc.md` não o descreve como exceção. Correção (~30 linhas de teste e 2 de doc): teste que lista os arquivos que escrevem `need_values` (`need_math.gd`, `action_runner.gd`, `npc_state.gd`, população) e falha se aparecer outro.
- **M5. Ids de conteúdo escritos no código** (constantes nomeadas, então dentro do AGENTS 4.6): `npc_thinker.gd:16-21` (`wait`, `flee`, `help`, `safety`), `npc_player_talk.gd:18-19` (`sleep` e a lista `BUSY_ACTION_IDS`, decisão P2 de Arthur), `npc_decision_runtime.gd:9` (`talk_player`), `income_stub.gd` (`income`, `work`, provisório), `action_runner.gd:23,27`. Para o catálogo ser mesmo "em dados", "quem ocupa o NPC" poderia virar uma marca da ação em `data/`. Isso muda formato de dados: **PARE e pergunta (AGENTS 16.2)**; só registro para a Fase 3.
- **M6. Números repetidos.** Alcance de 3 m em `npc_player_talk.gd:10` e `interaction_target.gd` (guardado por `test_interaction_npc.gd:73`); `CM_PER_METER` repetido em `npc_thinker.gd:22` (`CM_PER_METER_INT`) e `npc_player_talk.gd:12`, havendo `TerrainData.CM_PER_METER` (que o `npc_impasse.gd:165-166` já usa).
- **M7. `peek_simulation_summary` chama `world.validate()` inteiro** (`sim_bridge.gd:360`) uma vez por segundo com o painel aberto; o custo **não foi medido** (o próprio código marca [LIM] em `:353`). Só afeta build de desenvolvimento; a LW-084 (B1) mede.
- **M8. `save_version` segue 2 desde a LW-026**, embora o estado salvo do `npc` tenha crescido (LW-052 em diante; `last_player_talk_at` opcional na LW-083b, `npc_state.gd:155-156`, `:225`; validação em `npc_persistence.gd:111`). `npc.md:76` registra "`save_version` segue 2" de propósito, e o campo opcional não quebra save antigo; mas AGENTS 4.15 pede atualizar o `save_version` quando o estado salvo muda. Pedir a Arthur uma linha em `docs/decisions/` dizendo como a regra vale **antes** do "save congelado" (DEC-083). Teste de ida e volta existe e cobre o campo (`tests/unit/test_npc_player_talk.gd:163-184`, mais o fluxo inteiro em `tests/integration/test_player_npc_talk.gd`).
- **M9. Provisório salvo no jogo.** O estoque do `FoodStub` entra no save (`npc_persistence.gd` carrega a marca `TEMP-LW-065`); a remoção na LW-094 muda o formato do save. Sem problema antes do "save congelado", mas vale a LW-094 dizer isso.

## 3. Critérios da LW-085, um a um

| Critério (roadmap `:632`) | Resultado | Evidência |
|---|---|---|
| Limites do módulo `npc` | **Com ressalva** (I1, I2) | `src/sim/npc/api/` é a porta; subpastas bem separadas; mas 2 arquivos muito acima de 300 linhas e a ponte cita classes internas |
| Catálogo em dados | **Ok com ressalva** (M5) | ações, necessidades, ofícios, memórias, relações, estoque e renda em `data/*.json`; só ids de conteúdo em constantes |
| Função única de efeitos | **Ok** (M4 como observação) | `ActionRunner.apply_effects` `:231` é a única; `test_action_single_path.gd` guarda; `test_action_equivalence.gd` (LW-075: 4 testes, 351 asserts, status `:136`) compara S1 e S0 |
| Ponte fina | **Com ressalva** (I1) | `SimBridge` só delega e `BridgeReplies` só formata; mas cita 5 classes internas |
| Sem dinheiro e mercado antecipados | **Ok** | busca por `ledger`, `price`, `money`, `trade`, `market` em `src/sim/npc` e `data/*.json` só acha comentários e o README do `IncomeStub`; `market_reserved` é vocabulário de local vindo de `data/world/places.json:16,30` |
| Marcas `TEMP` | **Ok** | `TEMP-LW-065` e `TEMP-LW-066` em 16 arquivos (código, dados e docs); Anexo D (`DEVELOPMENT_ROADMAP.md:1495`) lista as duas com remoção na LW-094 e na LW-095 e o verificador LW-114 |
| Custo de memória e relações | **Sem medição** (B1, M7) | limites 24 e 16 por NPC em `data/npc_params.json`; leitura do código (`RelationGraph`, `NpcMemory`) mostra estruturas de tamanho fixo e remoção do mais fraco; não há medição de 1 ano |
| Resultado do SP2 | **Registrado, com pontos abertos** | `docs/decisions/0009-spike-sp2-corpos-e-lod.md` e DEC-122 (APROVADA por ora); a régua oficial falhou em 3 de 13 ensaios e a causa dos trancos ficou aberta (LW-072); `ROADMAP_STATUS.md:134` diz que a diferença S0 × S1 em quadros segue aberta e que os números de quadros não ficam no repositório |

## 4. Lista da seção 11 do AGENTS

- **Camadas e porta `api`:** camadas verdes (`check_architecture`: nove verificações aprovadas em `5e8f8b4`); porta `api` violada só na ponte (I1).
- **Três canais:** `peek_*` devolve cópias (conferi `NpcQuery`, `MemoriesQuery`, `NpcRelationsQuery`); `request_*` devolve `Result`; 5 eventos, todos catalogados. Único assinante: `npc_module.gd:199`.
- **Um dono por dado:** o `npc` é dono de tudo o que escreve. Vários subobjetos do módulo escrevem em `NpcState` (`NpcBodies`, `ActionRunner`, `NpcImpasse` em `npc_impasse.gd:156-167`, `NpcLifecycle`); é dentro do mesmo módulo, o que a regra permite.
- **Sem `Node` na simulação, sem aleatoriedade solta, sem tempo solto:** buscas em `src/sim`, `src/core`, `src/data`: zero `Time.get_`/`OS.`, zero `randf/randi/randomize/RandomNumberGenerator` fora de `core`, zero `await`, zero `Node`/`get_node`. O sorteio do pensador usa o fluxo do `core` (`RNG_STREAM` em `npc_thinker.gd:15`).
- **Sem `static var`, `@warning_ignore`, `print(` ou `TODO` soltos:** buscas limpas em `src` e `tests`.
- **Contratos e `docs/events.md` contra o código:** diferenças só de texto (M1, M2).
- **Tamanho de arquivo:** I2.
- **Testes enfraquecidos ou removidos:** **nenhum achado.** Histórico lido: a única troca de valor esperado foi a do oráculo (LW-073b, decisão de Arthur, explicada em `npc.md:76`); `test_action_single_path.gd:9` teve a lista `EFFECT_ROW_FILES` ampliada na LW-062 (`8a3492b`, `utility_scorer.gd`) e na LW-063 (`52a5537`, `npc_thinker.gd`), com a mensagem de falha explicando por quê; `test_action_catalog.gd` teve 2 linhas editadas na LW-083a (lista e contagem, citado em `ROADMAP_STATUS.md:147`).
- **Qualidade dos testes da LW-083:** 8 arquivos (`test_npc_player_talk` 7 testes e 44 asserts; `_effects` 7 e 38; `test_sim_bridge_converse` 5 e 28; `test_sim_bridge_interaction` 8 e 53; `test_interaction_view` 13 e 75; `test_interaction_npc` 5 e 31; `test_npc_talk_player` 6 e 35; `test_player_npc_talk` 1 e 35). Cobrem o aceite, as recusas na ordem e sem rastro, o alcance inclusivo, o cooldown nos dois lados do limite, a ida e volta do campo novo (e a rejeição de `-5`, `test_npc_player_talk.gd:184`) e o fluxo completo com salvar e carregar no meio da conversa. A lacuna é a I3.

## 5. O que eu NÃO consegui verificar

1. **Nada foi executado no Godot** (ordem de Arthur): não rodei `tools/check_all`, o oráculo, os soaks, nem o `run_sim`. Só repito números que os relatórios e o `ROADMAP_STATUS.md` já traziam (por exemplo `check_all` 119 scripts, 1.166 testes e 260.989 asserts na LW-082; hash de 30 dias `d13b921112ce`); **não os reproduzi**.
2. **O `main` `5e8f8b4` como um todo:** só li o texto; não sei se o `check_all` está verde nele (o relatório da junção diz que sim; não confirmei).
3. **A causa exata da mudança das 4 impressões do oráculo:** li a explicação documentada (o NPC LATE passou a ser recuperado) mas não reproduzi o cenário para ver o `peek_impasse_records()`.
4. **I3 (impasse × conversa):** não sei se o comportamento está certo; sei só que não há teste.
5. **Custo e memória:** nada medido (B1); a leitura do `RelationGraph` e do `NpcMemory` é de código, não de números.
6. **Janela do jogo:** nada. A conferência de Arthur da LW-082 na janela segue pendente (`ROADMAP_STATUS`); os números de quadros do SP2 e da LW-072 não estão no repositório.
7. **Rastro do `rng`:** conferi que o sorteio do pensador usa o fluxo do `core`, mas não repassei toda chamada de `rng` em `ActionRunner` e `NpcLod` (o teste `test_the_runner_never_rolls_dice` cobre o runner).
8. **`src/app` (raiz de composição):** não revisei as classes internas do `npc` que `src/app/npc_setup.gd` cita; assumi que a regra da porta `api` não vale para a raiz de composição (confirmar no contrato do `app`).
9. **Combinação dos ramos de Arthur:** ramos `lw-073*` e `lw-082*` já estão no `main`; não conferi se algum outro ramo remoto (por exemplo de B) toca `npc_module.gd`, `npc_thinker.gd` ou `sim_bridge.gd` e vai conflitar com as divisões da I2.

## 6. Decisões que dependem de Arthur (com recomendação)

1. **B1:** fazer a LW-084 antes da LW-085 (recomendo) ou rodar a LW-085 com o critério de custo marcado "sem medição".
2. **I1:** autorizar a regra nova em `tools/check_architecture` (recomendo sim; protege a ponte para sempre).
3. **I2:** autorizar os passos 1 e 2 como tarefas separadas (recomendo) e **registrar decisão** sobre as classes aninhadas do `npc_module.gd` (recomendo aceitar, não renomear 221 referências).
4. **I3:** autorizar o teste impasse × conversa (recomendo sim, antes da LW-086 porque é o roteiro de Arthur: conversar na janela).
5. **M8:** uma linha em `docs/decisions/` sobre `save_version` antes do "save congelado" (recomendo).

## Anexo: comandos usados (todos de leitura)

`git fetch`, `git log`, `git show`, `git diff --stat`, `git merge-base`, `git merge-tree` (simulação, sem gravar), `git archive | tar -x` para a pasta de rascunho; `rg`, `wc -l`, `sed -n`, `diff -rq`; `sh tools/check_architecture .`, `sh tools/check_input_keys .`, `sh tools/check_literal_text .` sobre a árvore extraída (sem Godot).
