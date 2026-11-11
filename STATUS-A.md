10/11/2026 21:31 (Brasília) · PRONTA PARA REVISÃO — RASCUNHO · LW-087a, rodada 3: commit `1ad022a` no ramo `lw-087a-registro-fase-3` empurrado; `check_all` verde; `main` sem mudança (`8dcc81d`); NÃO está no `main`, sem Fase B e sem tag; o Godot da A está parado

# RELATÓRIO — LW-087a, rodada 3: Q18 a Q21, nomes canônicos e três pontos pequenos     Status: PRONTA PARA REVISÃO — RASCUNHO (não está no `main`)

> **Em uma frase:** só texto, em **um** commit (`1ad022a`) no ramo `lw-087a-registro-fase-3`. Entraram as 4 decisões do revisor (DEC-174 a DEC-177, PROPOSTA); revi a DEC-152 (nomes canônicos) e a DEC-172 (três marcos de hash); acrescentei a nota curta da DEC-054 nas DEC-005, 045 e 053; o roadmap ganhou os ajustes das LW-088a, 090, 092, 095 e 097, do critério 3.F item 4 e do Anexo D. O `main` não andou (`8dcc81d`). **Sem Fase B, sem tag.** Parei (regra 13).

## Declaração de leitura (início da tarefa)
- **Li:** do contrato da `economy` (ramo `lw-087b`, `3eed5f8`): as seções 4, 6, 15 e 16 inteiras e o resto por busca; de `dados.md` e `events.md` (`4d49835`) e de `npc.md` e `world.md` (`f2913f9`): por busca de nomes e das linhas do salário; o resumo e os problemas dos dois STATUS, só para entender (**nenhum dos três STATUS é citado nos documentos do projeto**, conferido por busca). Reli o meu registro (DEC-129 a DEC-173, roadmap da Fase 3, 0012).
- **Decisões de que dependo e status:** DEC-164 e DEC-054 APROVADAS; DEC-152, 171, 172, 148 e 166 PROPOSTA (você disse que a DEC-148 vale; segue como padrão de trabalho).

## ANTES e DEPOIS dos totais (recontados por script; índice = cabeçalhos, sem número repetido)

| | APROVADA | (com ressalva) | PROPOSTA | PENDENTE | DESCARTADA | SUBSTITUÍDA | Total |
|---|---|---|---|---|---|---|---|
| **ANTES** (HEAD `86584d6`) | 84 | 20 | 60 | 18 | 10 | 1 | **173** |
| **DEPOIS** (HEAD `1ad022a`) | 84 | 20 | **64** | 18 | 10 | 1 | **177** |

Conta: PROPOSTA +4 (DEC-174 a DEC-177); nada mais muda. Saída do script: `índice=177 cabeçalhos=177 repetidos=nenhum só_no_índice=nenhum só_no_corpo=nenhum · CONFERE`; o status de cada entrada bate com a linha do índice (as 177). **Versão do documento: 0.8**; há linha 0.8 no histórico; o próximo número livre é **DEC-178**.

## Decisão → entrada / linha

| Decisão (sua ordem) | Entrada em `DECISIONS.md` | Roadmap e outros |
|---|---|---|
| **Q18** postos de serviço provisórios **sem marca** `TEMP-LW` | **DEC-174** | **Anexo D** (parágrafo novo "Provisório sem marca"); **critério 3.F item 4**; LW-095 |
| **Q19** três marcos de hash | **DEC-175**; **DEC-172 revista** | LW-088a (marco 1), LW-095 (marco 2), LW-097 (marco 3); 0012, seção 7.2 |
| **Q20** estoque inicial de 30 dias dos importados | **DEC-176**; DEC-166 aponta para ela | LW-097 |
| **Q21** teto de compra por bem | **DEC-177** | LW-090 |
| Nomes canônicos (`WagesPaid(workplace_id, amount_each)`, `peek_site`/`peek_post`) | **DEC-152 revista** | LW-095 |
| Distribuição proposta (14 locais de produção, 6 postos, 20 `work`, 10 novos: A +2, B +3, C +5; `workers_wanted`) | **sem entrada própria** (você pediu 4 entradas) | LW-092 (14 locais), LW-095 (6 postos), LW-097 (10 novos, 20 `work`, `test_economy_distribution.gd`); 0012, seção 8 |
| LW-092: conta **própria do local** (resolve a DEC-148) | DEC-148 (inalterada) | LW-092 |
| Notas "(DEC-054 aprovada em 10/11/2026)" | **DEC-005, DEC-045, DEC-053** (só a nota; a da DEC-034 já estava) | — |
| Divergências conferidas com a seção 16 da economia | — | nota sob a tabela 3.D (lista completa) |

## Nome ou número → onde aparece na A, na B e na C

A = meus arquivos (`DECISIONS.md`, roadmap, 0012); B = contrato da `economy`, `dados.md`, `events.md`; C = `npc.md` e `world.md`. "—" = não aparece.

| Nome ou número | A (nesta rodada) | B | C |
|---|---|---|---|
| `workplace_id` | DEC-152; LW-095 | `economy.md` §6; `events.md` (linha do `WagesPaid`) | **— (usa `site_id`: ver divergência 1)** |
| `peek_site` / `peek_post` | DEC-152; LW-095 | `economy.md` §6; `events.md` | `peek_site` sim; **`peek_post` —** |
| `WagesPaid` | DEC-152; LW-095; nota 3.D | `economy.md` §6; `events.md` | `npc.md` (LW-095, 14.4, Q18), como `(site_id, amount_each)` |
| `vacancy` | DEC-165; LW-096 | `economy.md` §8; `events.md` (`ContractOffered`) | `npc.md` (LW-096a, 14.7) |
| LW-088a | linha própria; DEC-171, 172, 175 | `economy.md` §2 e §14 | `npc.md` (4 menções), `world.md` (1) |
| LW-096a | linha própria; DEC-169 | `economy.md` §8 e §14 | `npc.md` (várias; é a tarefa do `npc`) |
| `ECON_WORKER_ALREADY_ASSIGNED` | **DEC-151 (acrescentei agora)** | `economy.md` §6 (6 menções) | — (o `npc.md` não o cita) |
| 14 locais de produção / 6 postos / 20 `work` (10 novos) | LW-092 (14), LW-095 (6), LW-097 (10 novos e 20 `work`); 0012 §8 | `economy.md` §6 (tabela: 14 + 6 = 20; 10 a criar: A +2, B +3, C +5); `dados.md` | **— (`world.md` e `npc.md` não trazem a contagem)** |

## Divergências encontradas na B e na C (só listo; você as envia)
1. **C (`npc.md`, linhas 233 e 310):** o evento aparece como `WagesPaid (site_id, amount_each)` e a leitura dos trabalhadores só como `peek_site`. O nome canônico é `workplace_id` (`site_id` do local de produção **ou** `post_id` do posto) e `peek_post` para o posto.
2. **B (`economy.md` §15):** Q18 a Q21 ainda aparecem como "em aberto para Arthur decidir"; agora estão registradas como PROPOSTA (DEC-174 a DEC-177).
3. **B (`economy.md` §16):** a tabela **não tem a linha da LW-090** (teto de compra por bem) e a linha da LW-097 **não cita o estoque inicial dos importados** (Q20).
4. **B (`economy.md` §16, linha da LW-114 e do 3.F item 4):** diz que "os postos de serviço pedem decisão [Q18]"; a Q18 foi registrada como "sem marca" (DEC-174).
5. **C (`world.md` e `npc.md`):** não trazem a contagem da distribuição (14 locais de produção, 6 postos, 20 `work`, 10 novos); só o contrato da `economy` e o roadmap (LW-097) a trazem.

## Conferência linha a linha: seção 16 da `economy` × a nota de divergências do roadmap

| Linha da seção 16 (B) | Na nota do roadmap (A) |
|---|---|
| LW-087: partes 087a a 087d | ✅ igual |
| LW-088: antes dela a LW-088a | ✅ igual (com DEC-171, 172 e 175) |
| LW-089: inventário na `economy`, de acordo | ✅ igual (DEC-130) |
| LW-091: `request_trade` com `actor_id` e `side` | ✅ igual (DEC-173) |
| LW-092: conta do próprio local; manutenção; 14 locais | ✅ igual (DEC-148, DEC-163) |
| LW-093: só comida; `mint` `game_start` na LW-093; LW-093a | ✅ igual (DEC-147, 168 e 170) |
| LW-095: salário por hora e postos de serviço | ✅ igual, **com mais**: `workplace_id` e o provisório sem marca (DEC-152, 164 e 174) |
| LW-096: `vacancy` e LW-096a | ✅ igual (DEC-165 e 169) |
| LW-097: `RouteStateChanged`, 10 `work` novos, `work_place_id`, teste | ✅ igual, **com mais**: estoque inicial dos importados (DEC-176) |
| LW-111: rejeita save antigo | ✅ igual (DEC-134) |
| LW-114 e 3.F item 4: diretórios; postos pedem decisão | ✅ diretórios; **postos agora sem marca (DEC-174)** |
| *(não existe na B)* LW-090: teto de compra | **só na A** (DEC-177): divergência 3 acima |

## O que quero que você veja
1. **A DEC-171 não dizia "uma vez por marco"; só a DEC-172 dizia.** Ajustei a DEC-172 (três marcos) e a linha da LW-088a; também corrigi a mesma frase na seção 7.2 do 0012.
2. **A distribuição 14/6/20/10 não tem entrada própria**, porque você pediu quatro entradas. Ela consta na LW-092, LW-095 e LW-097 e no 0012 (seção 8), como proposta que você aprova ao preparar a LW-097. Se quiser uma entrada para ela, é a DEC-178.
3. **A linha da LW-097 ficou pesada:** carrega o 3º povoado, rotas, 10 locais `work` novos, `work_place_id`, estoque inicial dos importados, o teste de distribuição e o marco 3 de hash. É a tarefa com mais decisões suas; vale pensar em dividi-la ao preparar o prompt (não decidi isso).
4. **Acrescentei `ECON_WORKER_ALREADY_ASSIGNED` à DEC-151** (a A não tinha o nome; a B o usa) — alinhamento de nome, não decisão nova.
5. **A LW-092 diz "14 locais de produção", mas os dados dos povoados vêm com a LW-097** (escrevi isso na própria linha).
6. **O marco 2 de hash está na linha da LW-095** (a última das três tarefas do marco), e não repetido nas LW-093 e LW-094.
7. **Os postos "sem marca" não têm verificação automática:** nada impede de esquecê-los na Fase 4. Recomendo que a primeira tarefa da Fase 4 que mexa na folha cite a DEC-174.

## 1. Resumo
Registrei as quatro decisões novas do revisor (postos sem marca, três marcos de hash, estoque inicial dos importados, teto de compra), alinhei os nomes canônicos da B (`WagesPaid(workplace_id, amount_each)`, `peek_site` e `peek_post`), pus a nota da DEC-054 nas três entradas que faltavam e atualizei o roadmap nas linhas que você citou, incluindo o Anexo D e o critério 3.F item 4. Nenhum código, dado, teste, backlog, `ROADMAP_STATUS.md` ou `README.md` foi tocado.

## 2. Arquivos criados
- Nenhum.

## 3. Arquivos modificados (contra o commit anterior `86584d6`)
- `docs/DECISIONS.md` — +76 −15: DEC-174 a 177, DEC-152, 151, 166 e 172 revistas, notas nas DEC-005, 045 e 053, 4 linhas de índice, totais, versão 0.8, histórico, "próximo número".
- `docs/DEVELOPMENT_ROADMAP.md` — +9 −7: LW-088a, 090, 092, 095, 097, critério 3.F item 4, parágrafo novo no Anexo D e a nota de divergências (lista completa).
- `docs/decisions/0012-pre-voo-da-fase-3.md` — +15 −2: seção 8 "Rodada 3" e uma frase corrigida na seção 7.2.
- Não toquei em `docs/backlog.md`, `AGENTS.md`, GDD, arquitetura, `project.godot`, `data/`, `tests/`, `ROADMAP_STATUS.md` nem `README.md`.

## 4. Decisões técnicas
- **Uma entrada por decisão:** Q18, Q19, Q20 e Q21 viraram DEC-174, 175, 176 e 177, todas PROPOSTA com a frase "decidida pelo revisor … não é APROVADA". As revisões (DEC-152, 151 e 172) foram feitas **na própria entrada**, como na rodada 2.
- **Notas da DEC-054:** só a frase "(DEC-054 aprovada em 10/11/2026)" no fim da célula "Consequências" de cada uma das três; nada reescrito.
- **Anexo D:** o provisório sem marca entrou como **parágrafo**, e não como linha da tabela (a tabela é de provisórios com marca).
- **Proposta de entrada para `DECISIONS.md` / pedido de desvio:** nenhum.

## 5. Testes executados
- `git fetch origin '+refs/heads/main:refs/remotes/origin/main'`: `main` em `8dcc81d`; já dentro do ramo, **nada a juntar** (sem commit de junção).
- Script de recontagem: antes `173 · CONFERE`, depois `177 · CONFERE`. Conferência de coerência: status do índice = status de cada entrada (177); toda `DEC-NNN` citada no roadmap e no 0012 existe; toda seção do 0012 citada pelas entradas existe (inclusive a 8). Busca de `STATUS-A`, `STATUS-B`, `STATUS-C`, `status-a/b/c` e dos rótulos "da B" e "da C" nos três arquivos: **nenhuma ocorrência**.
- **`tools/check_all` no HEAD final `1ad022a` (21:27:01 a 21:30:33, 10/11/2026): VERDE** (`EXIT_CODE_CHECK_ALL=0`).
- **NÃO EXECUTADO:** oráculo, vida de 30 dias, `run_sim` (só documentos).

## 6. Resultados
- **`check_all`:** 124 scripts, **1.194 testes, 1.194 passando, 0 falhando**, 261.693 asserts, 179,8 s; 313 scripts sem aviso de compilação; nenhum "SCRIPT ERROR" nem "Parse Error".
- **Critério de aceite:** 1 (DEC-174 a 177; DEC-152 com `workplace_id` e `peek_post`; DEC-172 com os três marcos; notas nas DEC-005, 045 e 053; totais por script; versão 0.8) · 2 (LW-090, 092, 095, 097, Anexo D, 3.F item 4, marcos de hash e a conferência da seção 16) · 3 (0012, seção 8) · 4 (tabela de nomes e divergências, acima) · 5 (merge: nada a juntar).

## 7. Problemas encontrados
- As **divergências da B e da C** estão listadas acima (5), para você enviar.
- A DEC-171 não tinha a frase dos marcos (item 1 de "O que quero que você veja").
- **O contrato da `economy` ainda trata Q18 a Q21 como "em aberto"** (divergência 2): enquanto a B não atualizar, os dois textos discordam do registro.

## 8. Riscos
- **35 entradas minhas ainda são PROPOSTA** (31 das rodadas 1 e 2 e 4 desta): guiam o trabalho, mas você não as aprovou.
- **Três aprovações de hash** (LW-088a, LW-093 a LW-095, LW-097) significam três pontos em que o trabalho espera por você.
- **LW-097 pesada** (item 3) e **frente do `npc` com um agente só** (as LW-093 a LW-097 mexem nos mesmos arquivos).
- **Postos sem verificação automática** (item 7).
- **Valores [HIP]:** o teto de compra, os estoques iniciais e os salários dos postos são hipóteses; só o soak da LW-110 e a calibração (LW-112) os provam.

## 9. Pendências
- **Para você decidir (cada uma com a minha recomendação):** (1) aprovar ou trocar as 35 PROPOSTA — recomendo aprovar as DEC-174 a 177 (resolvem pontos que travariam o `check_temp`, os hashes e o soak); (2) uma entrada própria para a distribuição 14/6/20/10 — recomendo sim, ao preparar a LW-097; (3) dividir a LW-097 — recomendo decidir ao preparar o prompt.
- **Fase B:** não autorizada. A linha de status e o `README` entram só quando você mandar o rascunho para o `main`.
- **Teste manual:** nenhum (só texto).

## ACOMPANHAMENTO
- **Avanço:** a LW-087a segue como primeira parte da LW-087; a Fase 3 não começou (contagens do status inalteradas).
- **Próxima tarefa recomendada:** a sua revisão da rodada 3 e, se aprovada, a Fase B da LW-087a; depois a B e a C atualizam os rascunhos (087b, 087c e 087d) com as 5 divergências acima. **Não iniciada.**
- **Decisões que dependem de você:** as três acima.
- **Git:** **um** commit novo (`1ad022a`) no ramo `lw-087a-registro-fase-3`; empurrados **só** esse ramo e o `status-a`; nada no `main`, nenhuma tag, sem `--force`.
