10/11/2026 13:18 (Brasília) · CONCLUÍDA · Revisão cruzada pré-LW-085 (LW-082 e LW-083), só leitura

# REVISÃO CRUZADA PRÉ-LW-085 — LW-082 (painel de NPC) e LW-083 (conversa)

**Revisor:** agente de revisão (AGENTS §11). **Não implementei, não corrigi nada, não rodei o Godot** (ordem de Arthur: o Mac precisa ficar quieto durante a medição da outra conversa).
**Base lida:** `main` = `5e8f8b4` (este ramo `status-a` difere do `main` só pelos arquivos de status).
**O que revisei:** o que eu **não** escrevi: LW-082 (082a a 082h, commits `669f34a` a `df59815`) e LW-083 (083a a 083f, commits `3c61c5d` a `a2cf92c`). Método: leitura de código e documentos, `git show`, `git diff`, `grep`. Nenhum teste foi executado nesta revisão.

## 1. Resumo em palavras simples

- **Bloqueante: nenhum** achado (dentro do que leitura permite ver).
- **Importante: 4.** (I-1) a ponte usa 8 tipos internos do `npc`, fora da porta `api`, e a verificação automática de arquitetura **não enxerga isso**; (I-2) quatro arquivos passam muito de 300 linhas; (I-3) o custo do painel nunca foi medido; (I-4) o `project.godot` (arquivo protegido) foi alterado pela 082g e **não consigo ver a autorização no repositório**.
- **Menor: 8.**
- **Pontos bons confirmados:** o painel só escreve numa linha (a marcação do rastro); nenhum evento novo; nenhum teste foi enfraquecido; nenhum dinheiro nem mercado antecipado; nenhuma marca `TEMP` nova; a conversa não cria uma segunda função de efeitos; o painel nem é criado fora de build de desenvolvimento.
- O `check_all` verde que eu rodei na Fase B da LW-073 (1.180 testes, no `main` com tudo isso) mostra que os testes **passam**; não prova que testam o que deveriam.

## 2. Achados

### Bloqueantes
Nenhum.

### Importantes

**I-1. A ponte cita classes internas do `npc` (fora de `api/`), e a porta do `npc` devolve tipos internos.**
- **Onde:** `src/bridge/bridge_npc_inspect.gd:59` (`RoutineTable.RoutineQuery`), `:75` e `:157` (`npc.lod`, campo público, e `NpcLod.LEVEL_S0`), `:85`, `:89`, `:96` (`DecisionTracer.Explanation`, `.DecisionRecord`, `.CandidateRecord`), `:121` (`MemoryRecord`), `:132` (`NpcMemory.Trait`); `src/bridge/bridge_replies.gd:165-175` (`NpcLod.CODE_NOT_IN_S0`, `NpcTiers.CODE_DEAD`, `RelationGraph.CODE_INVALID`, `RelationGraph.CODE_NOT_ALLOWED`, `NpcLod.CODE_INVALID_POSITION`).
- **Regra:** AGENTS §5.1: um módulo só importa "**apenas a porta de entrada (`api`)**" dos outros. A pasta `src/sim/npc/api/` tem 5 classes (`NpcModule`, `NpcIntent`, `NpcActionResult`, `NpcRelationsQuery`, `NpcSpec`); as outras 50 classes do `npc` estão em `lod/`, `decision/`, `memory/`, `relations/`, `state/`, `routine/` etc. A ponte cita 7 delas no código (e `NpcState` só num comentário, `bridge_inspect_replies.gd:10`).
- **Evidência de que começou aqui:** no `fase-1-concluida` e em `3c61c5d^` (antes da LW-083a) a ponte não citava nenhuma delas.
- **Por que o `check_all` verde não pega:** a regra C de `tools/check_architecture` só protege classes declaradas em pasta `internal/` (linhas ~93-102 do script, com `[LIM]` declarado), e o `npc` não tem nenhuma pasta `internal/`. Além disso, `DecisionTracer.Explanation` e similares são classes internas de arquivo (`class X:`), que o script também não vê.
- **Efeito:** renomear ou mover `DecisionTracer`, `MemoryRecord`, `NpcLod`, `RelationGraph` ou `NpcTiers` obriga a editar a ponte (alerta de acoplamento do §5.2.4; integridade arquitetural é a prioridade nº 1 do §1).
- **Proposta de correção (≈ 200 a 260 linhas, 8 a 9 arquivos; mexe em contrato, então começa com tarefa de contrato, §5.2.6):**
  1. *Contrato primeiro* (`docs/modules/npc.md` e `bridge.md`, ≈ 30 linhas): a porta devolve só tipos de `api/`; lista os novos.
  2. Mover para `api/` os tipos de resposta que hoje vazam, no padrão do `NpcRelationsQuery`: um `NpcExplanationQuery` (com os registros e candidatos), `NpcRoutineQuery` e `NpcMemoriesQuery`/`NpcMemoryRecord` (≈ 120 linhas, cópias de dados puros; o `DecisionTracer` e o `NpcMemory` continuam internos e só preenchem esses tipos).
  3. Dois acessos novos em `NpcModule`: `peek_level_of(npc_id) -> int` e `peek_s0_count() -> int` (≈ 12 linhas), para a ponte parar de usar o campo `npc.lod`.
  4. Reexportar em `NpcModule` as constantes de código que a ponte mapeia (`CODE_NOT_IN_S0`, `CODE_DEAD`, `CODE_INVALID`, `CODE_NOT_ALLOWED`, `CODE_INVALID_POSITION`) como alias das originais (≈ 8 linhas), e trocar o `FAILURE_KEYS` para `NpcModule.CODE_*`.
  5. Regra D no `tools/check_architecture` (≈ 25 linhas): `src/bridge/` só cita `class_name` de `src/sim/*/api/` e de `src/sim/events`; com teste de que a regra pega um caso falso.
  6. Ajustar os testes que montam essas respostas (≈ 30 linhas, sem remover asserts).
  - **Alternativa, se Arthur preferir não mexer agora:** registrar um desvio autorizado (§16.3) dizendo que a ponte pode citar os *tipos de dados* do `npc` (não as lógicas), com a regra D listando exatamente quais. Minha recomendação é a correção, porque a regra D é barata e passa a proteger o resto da Fase 3 em diante.

**I-2. Quatro arquivos passam muito de ~300 linhas, sem proposta de divisão registrada.**
- **Onde (linhas hoje; quanto a 082/083 somou):** `src/sim/npc/api/npc_module.gd` **603** (+52), `src/sim/npc/decision/npc_thinker.gd` **455** (+4), `src/bridge/sim_bridge.gd` **391** (+81), `src/sim/npc/notables/npc_notables.gd` **308** (+8). No limite: `src/bridge/bridge_replies.gd` 298 (+29), `npc_inspector_model.gd` 287, `npc_state.gd` 282.
- **Regra:** AGENTS §4.5 ("passou disso, proponha divisão") e a linha da LW-085 ("limites do módulo `npc`"). Não achei proposta de divisão no `ROADMAP_STATUS.md` nem nos contratos.
- **Observação honesta:** `npc_module.gd` e `sim_bridge.gd` são fachadas (cada `peek_*`/`request_*` é uma delegação) e o GDScript não tem classe parcial; dividir não encurta a lista pública. `npc_thinker.gd` (455) é lógica de verdade.
- **Proposta (PROPOSTA DE DESVIO, §16.3, ≈ 150 linhas movidas na parte 2):**
  - *Opções:* (a) não desviar e dividir os quatro; (b) tratar as duas fachadas como isentas do limite de linhas (a regra passa a valer para a lógica, não para delegações) e dividir só `npc_thinker.gd` e `npc_notables.gd`.
  - *Recomendação:* (b). Dividir `npc_thinker.gd` pela fronteira "escolher a ação" × "reagir ao alarme e à urgência" (hipótese minha, não li o arquivo inteiro para confirmar o ponto de corte) em dois arquivos de ≈ 230 linhas, sem mudar comportamento; os nove hashes do oráculo e o `d13b921112ce` provam que não mudou nada.
  - *Reverter:* é mover código; reverter é desfazer a divisão.

**I-3. O custo do painel nunca foi medido: o resumo chama `world.validate()` a cada ≈ 1 s e a lista inteira é refeita a cada 0,25 s.**
- **Onde:** `src/bridge/sim_bridge.gd:360` (`_host.runner.world.validate()` dentro de `peek_simulation_summary`); `src/bridge/bridge_npc_inspect.gd:9-25` (`peek_npc` por NPC, cada um copiando necessidades e traços); `src/tools/npc_inspector/npc_inspector_panel.gd:14-15` e `:177-185` (`REFRESH_INTERVAL_S` 0,25 e `SUMMARY_INTERVAL_S` 1,0; cada atualização faz 5 leituras na ponte: lista, detalhe, rastro, memórias, relações).
- **O próprio status da LW-082** (`docs/ROADMAP_STATUS.md:145`) diz que o custo do `validate()` "não foi verificado". É uma das coisas que a LW-085 pede ("custo").
- **Limite do risco (confirmado por leitura):** `NpcInspectorMount.mount` devolve nulo fora de build de desenvolvimento (`npc_inspector_mount.gd:12-14`) e o `main_world_view.gd:67` passa `OS.is_debug_build()`; então **em release o painel nem existe**. Não distorce a medição de quadros da LW-053A em release. Em build de depuração com o painel aberto, distorce.
- **Proposta (≈ 70 a 90 linhas, sem otimizar nada antes de medir, §4.18):** um script de medição em `tests/soak/` (fora do `check_all`, como os outros) que carrega o mundo de 30 dias dos 100 NPCs e imprime microssegundos médios e máximos de `validate()`, `peek_npc_roster`, `peek_npc_detail` e `peek_simulation_summary`. Com os números, a LW-085 decide: se `validate()` passar de uma fração do quadro, o resumo passa a recalcular a cada 5 s ou só por tecla. Medir exige Godot, por isso eu não fiz agora.

**I-4. `project.godot` (arquivo protegido, §12.5) foi alterado pela 082g sem autorização que eu consiga ver no repositório.**
- **Onde:** commit `89c8182` (LW-082g), `project.godot` +25 linhas: as cinco ações de entrada `inspector_toggle`, `inspector_toggle_alt`, `inspector_next`, `inspector_previous`, `inspector_trace` (F3, Tab, N, B, T). É o **único** commit de 082/083 que toca arquivo protegido (conferi `.gitignore`, `addons/`, `tests/fixtures/`, GDD, arquitetura, DECISIONS, ROADMAP e AGENTS: nenhum foi tocado).
- **O que vi sobre autorização:** a linha da LW-082 no roteiro (`docs/DEVELOPMENT_ROADMAP.md:629`) não fala de `project.godot`; o status (`docs/ROADMAP_STATUS.md:145`) diz "Autorizada por Arthur em 10/11/2026 (Fase B automática: o painel só lê, **com uma exceção declarada**)", e a exceção descrita é a marcação do rastro, não o `project.godot`. Já a 083e escolheu de propósito **não** mexer nele (`docs/modules/presentation.md:40`: "`project.godot` não muda").
- **Pode estar certo:** a autorização pode estar no texto da tarefa de outra conversa, que eu não vejo. Por isso a classificação é "importante, não verificado", não "violação".
- **Proposta (documento apenas, ≈ 10 linhas):** Arthur confirma por escrito; o agente da 082 registra a autorização na linha da LW-082 do `ROADMAP_STATUS.md` ("`project.godot`: +5 ações de entrada, autorizado em <data>"). Se Arthur não autorizou, o conserto é registrar o desvio em `docs/decisions/` e decidir se as ações voltam para o código (`InputActions`), sem tocar o arquivo.

### Menores

- **M-1. Campo novo salvo sem subir `save_version`.** `last_player_talk_at` (`src/sim/npc/state/npc_state.gd:155-156` grava só se diferente de -1; `:222-225` lê; `npc_persistence.gd:111-112` valida). AGENTS §4.15 pede subir `save_version` quando o estado salvo muda. Foi escolha documentada (`docs/modules/npc.md:26`: não entra no save de quem nunca conversou, para o hash não mudar) e há teste de ida e volta (`tests/integration/test_player_npc_talk.gd`). É compatível com os saves antigos; só não segue a letra da regra. Arthur decide se basta o registro.
- **M-2. Comentário afirma mais do que o código.** `src/sim/npc/actions/action_runner.gd:226` diz "A ÚNICA função que escreve efeitos de ação nas necessidades". Está certo para ações (`apply_effects` → `_apply_row`), mas `NeedMath.add_pressure` (`src/sim/npc/needs/need_math.gd:78-83`, chamado em `npc_thinker.gd:270`) também escreve em `need_values` (pressão do alarme, LW-076). Não é da 082/083; sugiro só acertar o texto na LW-085.
- **M-3. Alcance e cooldown da conversa estão em constantes do código, não em dados.** `src/sim/npc/social/npc_player_talk.gd:10` (`TALK_REACH_M` 3) e `:12` (`TALK_COOLDOWN_MIN` 60), ambos marcados [HIP]; é permitido pelo §4.6 (constante nomeada). Se a LW-085 quiser "tudo ajustável em dados", mover para `data/npc_params.json`.
- **M-4. O alcance de 3 m existe duas vezes.** `src/presentation/interaction/interaction_target.gd:10` (`NPC_REACH_M` 3.0) e `npc_player_talk.gd:10`; a apresentação não pode citar `sim/`. Há teste que confere a igualdade (`tests/integration/test_interaction_npc.gd:73`). Funciona; uma consulta `peek_talk_reach_m` na ponte eliminaria a duplicata.
- **M-5. `src/tools/` fica fora do `check_architecture` e do `check_literal_text`.** Já declarado no status da LW-082; a cobertura é só o teste 082h (varredura de `src/tools/`). Incluir a pasta nos dois scripts na LW-085.
- **M-6. Índice dos módulos incompleto.** `docs/modules/README.md` não lista `tools.md` (declarado no status da LW-082).
- **M-7. Estilo.** `src/bridge/bridge_npc_inspect.gd:80-82`: três linhas em branco seguidas.
- **M-8. `FAILURE_KEYS` mistura códigos de classes diferentes em 6 chaves** (`bridge_replies.gd:165-175`, dois pares de códigos viram a mesma chave). O fallback `FALLBACK_KEY` cobre códigos fora da tabela e o teste percorre todas as chaves (`tests/unit/test_sim_bridge_converse.gd:123,128`); só o acoplamento (I-1) incomoda.

## 3. Critérios da linha da LW-085, um a um

| Critério | Resultado |
|---|---|
| Limites do módulo `npc` | **Parcial.** `NpcPlayerTalk` (117 linhas) e o painel (3 arquivos, 555 linhas no total) estão dentro do tamanho; a conversa entra pela porta `request_converse` e não cria módulo novo. Pendências: I-1 (porta com tipos internos) e I-2 (tamanhos). |
| Catálogo em dados | **OK, com ressalva.** `talk_player` está em `data/actions.json:11` (6 min, sem local, `risk` 0) e o tipo de memória `conversation` em `data/memory_kinds.json:2`. As duas constantes de jogo da conversa ficam no código (M-3). Não conferi se o texto `"talk_player"` também aparece como constante solta em `NpcDecisionRuntime.begin_talk_player`. |
| Função única de efeitos | **OK para ações.** `ActionRunner.apply_effects` (`action_runner.gd:232`) segue sendo o único ponto que aplica efeitos de ação; `talk_player` não tem efeitos; a conversa só mexe em relação (mesma conta `capped_gain` da conversa entre NPCs, `npc_player_talk.gd:31,78`) e em memória. Ressalva M-2. |
| Ponte fina | **Parcial.** Os copiadores são finos e a única escrita do painel passa por `request_set_npc_traced` (`sim_bridge.gd`, que só repassa para `NpcModule.request_set_traced`). Mas a ponte cita tipos internos (I-1), tem 391 linhas (I-2) e chama `world.validate()` (I-3). |
| Ausência de dinheiro e mercado antecipados | **OK.** Procurei `ledger`, `money`, `price`, `market`, `gold`, `wage` e equivalentes em português no painel, na ponte, em `npc_player_talk.gd` e na tela de interação: nada. No `src/sim/npc` só aparecem os comentários "sem dinheiro, preço ou mercado" dos dois stubs provisórios e o tipo de local `market_reserved` que já existia no `world`. |
| Marcas `TEMP` | **OK.** Só existem `TEMP-LW-065` (FoodStub, sai na LW-094) e `TEMP-LW-066` (IncomeStub, sai na LW-095), ambas anteriores à 082/083. Nenhuma marca nova; nenhum `TODO`, `FIXME` nem `print(` em `src/`, nenhum `await` em `src/sim`, `src/bridge` e `src/tools`, e nenhum código comentado nos arquivos principais da 082/083 (painel, ponte, `npc_player_talk.gd`, tela de interação). |
| Custo de memória e relações | **Limitado por dados, não medido.** `data/npc_params.json`: `max_t2` 40, `memory_capacity` 24, `relations_capacity` 16. Conta minha (hipótese): no máximo 40 × 24 = 960 memórias e 40 × 16 = 640 relações de notáveis; o `RelationGraph` expulsa a mais fraca quando o NPC enche (`relation_graph.gd:111-115`). Bytes reais **não medidos**. O custo de *ler* isso no painel é o I-3. |
| Resultado do SP2 | **Fora do que li.** O que vejo no `main`: DEC-123/DEC-124 aprovadas e a velocidade de caminhada de 500 cm/min. Não revisei o relatório do SP2. |

## 4. Lista do §11, item a item

- **Camadas e `api`:** direção das camadas sem violação (nada de `Node` nem de apresentação em `src/sim`, `src/core`, `src/data`; a apresentação só fala com `SimBridge`). **Violação do "só `api`" pela ponte: I-1.**
- **Três canais:** consultas `peek_*` (lista, detalhe, resumo, rastro, memórias, relações, rotina), comandos `request_*` (`request_converse`, `request_set_npc_traced`); **nenhum evento novo** em 082/083.
- **Um dono por dado:** a única escrita do painel é a marcação do rastro (decisão de Arthur, declarada). O teste 082h prova "só lê" com jogos gêmeos, ponte espiã e varredura de `src/tools/`. A conversa escreve `last_player_talk_at` dentro do próprio módulo (`npc_player_talk.gd:58`) e a relação/memória pelos caminhos internos do `npc` (`NpcNotables`).
- **Sem `Node` na simulação; sem aleatoriedade ou tempo soltos:** `grep` limpo em `src/sim`, `src/core`, `src/data` e `src/bridge`; não há `await` novo.
- **Contratos e `docs/events.md` × código:** as 6 classes que estendem `SimEvent` (`AlarmRaised`, `InteractionPerformed`, `LodChanged`, `NpcDied`, `NpcImpasseRecovered`, `RelationChanged`) são exatamente as 6 de `docs/events.md`. Os contratos `npc.md`, `bridge.md`, `tools.md` e `presentation.md` descrevem `request_converse`, `last_player_talk_at`, o painel e a tecla `interact`. **Não comparei cada parágrafo dos contratos com cada assinatura**, só os pontos acima.
- **Tamanhos:** I-2.
- **Qualidade dos testes (algum enfraquecido?):** **nenhum.** As commits de 082/083 removem só 3 linhas de teste, todas trocadas por versões maiores: `tests/unit/test_action_catalog.gd` (a lista de ações ganhou `talk_player` e a contagem foi de 10 para 11) e `tests/unit/test_input_actions.gd` (`ACTION_COUNT` de 17 para 22 mais as 5 teclas esperadas). Procurei padrões fracos (`assert_true(true`, `pending`, `skip`) nos 6 arquivos de teste novos principais: nenhum. **Não li cada assert um a um**; "o assert é significativo" além do `grep` não foi verificado.
- **Documentação acompanha:** sim, com as lacunas M-5 e M-6.

## 5. O que eu NÃO consegui verificar

1. **Nada foi executado.** Sem Godot e sem `check_all` novo (ordem de Arthur). O resultado verde que cito é o da Fase B da LW-073.
2. **O painel na janela** (o critério do roadmap pede "na janela, selecionar um NPC mostra os dados"): fica para Arthur. O clique no corpo do NPC (082i) está no backlog.
3. **Custo em milissegundos** de `validate()`, da lista e do detalhe (I-3) e **bytes** de memória e relações.
4. **Leitura completa de todos os arquivos.** Li inteiros: `bridge_npc_inspect.gd`, `npc_inspector_mount.gd`, `interaction_target.gd`; em trechos: `sim_bridge.gd`, `bridge_replies.gd`, `npc_player_talk.gd`, `interaction_view.gd`, `npc_inspector_panel.gd`, `action_runner.gd`, `need_math.gd`. **Não li linha a linha** `npc_inspector_model.gd` (287), o restante de `npc_inspector_panel.gd` (247), `bridge_inspect_replies.gd` (200), `npc_notables.gd`, `npc_decision_runtime.gd` e os 6 arquivos de teste novos; para esses, só `grep`, tamanhos e diffs.
5. **A autorização do `project.godot`** (I-4), que pode existir fora do repositório.
6. **O SP2** (fora do escopo da leitura).

## 6. Decisões que dependem de Arthur (com a recomendação)

1. **I-4:** confirmar por escrito que a 082g podia alterar o `project.godot`. *Recomendo confirmar e registrar na linha da LW-082.*
2. **I-1:** corrigir agora (tarefa de contrato + 8 a 9 arquivos, ≈ 200 a 260 linhas) ou registrar desvio. *Recomendo corrigir na LW-085, com a regra D no `check_architecture`.*
3. **I-2:** isentar as duas fachadas do limite de linhas e dividir só `npc_thinker.gd`. *Recomendo.*
4. **I-3:** autorizar o script de medição do custo do painel (precisa do Godot rodando, então só depois que a medição de quadros terminar). *Recomendo.*
5. **M-1:** basta o registro do campo opcional ou sobe-se o `save_version`? *Recomendo deixar como está, registrado.*

## 7. Git

Nada foi alterado fora deste ramo. `main` = `5e8f8b4`, sem tags novas, sem `--force`. Este arquivo e o `STATUS-A.md` são os únicos arquivos do ramo `status-a` que diferem do `main`.
