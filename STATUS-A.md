10/11/2026 21:11 (Brasília) · PRONTA PARA REVISÃO — RASCUNHO · LW-087a, rodada 2: commit `86584d6` no ramo `lw-087a-registro-fase-3` empurrado; `check_all` verde; `main` sem mudança (`8dcc81d`); NÃO está no `main`, sem Fase B e sem tag; o Godot da A está parado

# RELATÓRIO — LW-087a, rodada 2: registro da Fase 3 depois das revisões cruzadas e das suas novas decisões     Status: PRONTA PARA REVISÃO — RASCUNHO (não está no `main`)

> **Em uma frase:** só texto, em **um** commit (`86584d6`) no ramo `lw-087a-registro-fase-3`. Entraram 2 decisões suas (DEC-163 e DEC-164, APROVADAS) e 9 decisões do revisor (DEC-165 a DEC-173, PROPOSTA); revi 5 entradas (DEC-150, 151, 152, 153 e 159); o roadmap ganhou a LW-088a e a LW-096a e os ajustes das tarefas que você citou. O `main` não andou (`8dcc81d`). **Sem Fase B, sem tag.** Parei (regra 13).

## Declaração de leitura (início da tarefa)
- **Li, só para entender:** o `STATUS-B.md` e o `STATUS-C.md`; o contrato da `economy` ajustado (seções 4 a 8, 14 e 15), os eventos (`WagesPaid`, `RouteStateChanged`) e a D1 dos dados; as perguntas Q15 a Q17 e Q23. **Reli** o meu registro (DEC-129 a DEC-162, roadmap da Fase 3, 0012). **Nenhum dos dois STATUS é citado nos documentos do projeto** (conferido por busca em `DECISIONS.md`, roadmap, backlog e 0012; também tirei os rótulos "da B" e "da C": trocados por "contrato da `economy`", "do `world`" e "do `npc`").
- **Decisões de que dependo (status):** DEC-054, 047 e 049 APROVADAS; DEC-126 e 127 APROVADAS; DEC-133 APROVADA (com o "ou"); DEC-083 e 084 APROVADAS com ressalva; as minhas DEC-150 a 153 e 159, PROPOSTA (revistas).

## ANTES e DEPOIS dos totais (recontados por script; índice = cabeçalhos, sem número repetido)

| | APROVADA | (com ressalva) | PROPOSTA | PENDENTE | DESCARTADA | SUBSTITUÍDA | Total |
|---|---|---|---|---|---|---|---|
| **ANTES** (HEAD `44e29df`) | 82 | 20 | 51 | 18 | 10 | 1 | **162** |
| **DEPOIS** (HEAD `86584d6`) | **84** | 20 | **60** | 18 | 10 | 1 | **173** |

Conta: APROVADA +2 (DEC-163 e DEC-164); PROPOSTA +9 (DEC-165 a DEC-173); ressalvas, PENDENTE, DESCARTADA e SUBSTITUÍDA não mudam. Saída do script: `índice=173 cabeçalhos=173 repetidos=nenhum só_no_índice=nenhum só_no_corpo=nenhum · CONFERE`. Conferi também que o status de cada entrada bate com a linha do índice (as 173). **Versão do documento: 0.7**; há linha 0.7 no histórico; o próximo número livre é **DEC-174**.

## Tabela: decisão → entrada / linha

| Sua decisão (item) | Quem | Entrada em `DECISIONS.md` | Roadmap e outros |
|---|---|---|---|
| 1. DEC-054 vale inteira | Arthur | DEC-054 **não mexida** (o texto da rodada 1 já a aprova inteira) | 0012, seções 6 e 7.1 |
| 2. Consumo = manutenção dos locais | Arthur (APROVADA) | **DEC-163**; DEC-153 revista | LW-092; **backlog (1 linha)**; LW-093 (só comida) |
| 3. Quem paga guardas e estalajadeiros (Q15) | Arthur (APROVADA) | **DEC-164** | LW-095 |
| a. Salário (Q18 A) como a economia escreveu; sem limitação; "um trabalho, um pagamento"; DEC-153 | revisor (PROPOSTA) | **DEC-152 reescrita**; **DEC-151 reescrita** (salário = passo 3 da hora do local; `request_work_shift` só para `labor`); DEC-153 revista | LW-095 (salário por hora, `WagesPaid`); LW-096 |
| b. Q16 `vacancy` | revisor | **DEC-165** | LW-096 |
| c. Q17 povoado C sem comida | revisor | **DEC-166** | LW-097, LW-098, LW-109, LW-110 |
| d. Q23 coluna `work_place_id` (formato de dado) | revisor; **você aprova na LW-097** | **DEC-167** | LW-097 |
| e. `sell` do NPC; divergência da LW-093 | revisor | **DEC-168** | LW-093; nota de divergências sob a tabela 3.D |
| f. LW-096a | revisor | **DEC-169** | **LW-096a (linha nova)**; diagrama |
| g. `mint` inicial na LW-093 | revisor | **DEC-170** (a DEC-133 aponta para ela) | LW-093, LW-094 (dependência), LW-095 |
| h. LW-088a: regra do `check_architecture`; fixture e hashes | revisor | **DEC-171** e **DEC-172** | **LW-088a (linha nova)**; diagrama; nota |
| i. `request_trade(actor_id, market_id, good_id, quantity, side)` | revisor | **DEC-173** | LW-091; nota de divergências |
| j. `RouteStateChanged` só com `route_id` e `new_state` | revisor | **DEC-159 revista** (**conferido: já estava assim** em `docs/events.md` e no contrato do `world`) | — |
| k. `bid` mínimo 1 e `ask` maior que o `bid` | revisor | **DEC-150 revista** | fórmula em `economy.md` (da B) |
| l. Ajustes de coerência confirmados | Arthur | (registrados no 0012, seção 7.1) | **mantidos**: 3.B, 3.F.9, 3.G, Anexo D, LW-094, LW-105, LW-111 |
| m. Nota "(DEC-054 aprovada em 10/11/2026)" | Arthur | **na DEC-034, não na DEC-031** (ver abaixo) | — |
| 5. Merge do `main` | — | — | `main` em `8dcc81d`, já dentro do ramo: **nada a juntar** (sem commit de junção) |

## O que quero que você veja
1. **A nota da DEC-054 foi para a DEC-034, e não para a DEC-031.** O meu relatório da rodada 1 errou o número (usei uma linha desatualizada): a frase "(DEC-054, proposta)" está na **DEC-034** (Domesticação de criaturas); a DEC-031 (Nível tecnológico e pólvora) nem cita a DEC-054. Pus a nota na DEC-034. **Outras três entradas ainda tratam a DEC-054 como proposta** (DEC-005, DEC-045 e DEC-053) e **não toquei nelas**: diga se quer a mesma nota.
2. **A LW-088a vai além da sua lista.** Você deu três regras; escrevi a tarefa como o **registro do módulo `economy` no `World`** (uma casca: `EconomyModule` com `api/` vazia), que é a ideia do pré-voo e a que faz o `state_hash` mudar. Se não era isso, é só tirar a casca da linha. A LW-088 e a LW-089 passam a vir depois dela **só na nota e no diagrama**: não editei a linha da LW-088.
3. **Corrigi um erro meu da rodada 1.** Na DEC-132 e na LW-095 eu tinha escrito "o vínculo de trabalho chega por evento". Pela sua Q22 e pela DEC-145, o vínculo da população inicial vem **na abertura da conta**; o que chega por evento é a **vaga** (`ContractOffered`). Os dois textos agora dizem isso.
4. **Mudei a LW-093 além do (e) e do (g):** o texto dizia "consumo de comida e outros bens", o que contradiz a sua decisão 2 (o NPC só come). Agora diz só comida.
5. **Divergências do texto original** (LW-091, LW-093 e LW-095) estão numa **nota sob a tabela 3.D**, além de em cada linha.
6. **Ficaram só nas entradas, não nas linhas do roadmap** (as suas instruções limitam o roadmap): o menor 9 (evento e fechar rota na LW-097), o renome `market_reserved` → `market` (LW-093) e a aprovação dos hashes por marco (a LW-088a e a LW-097 já dizem a parte dos hashes).
7. **A DEC-148 ("o local é dono de si") ainda destoa da linha da LW-092 ("conta do proprietário").** Não estava na sua lista e não toquei.
8. **Estimativa da LW-093a:** troquei a minha (cerca de 140 linhas) pela do contrato da `economy` (**150 a 200 linhas de código e teste**); entrou também o `work_place_id` de `population.json` na conferência.
9. **A forma dos dados de receitas** (tabelas planas) segue **pendente** no 0012, embora o contrato da `economy` já a use.

## 1. Resumo
Registrei as suas decisões da rodada 2 (consumo = manutenção dos locais; postos de serviço para guardas e estalajadeiros; DEC-054 inteira; ajustes de coerência confirmados) e as do revisor (salário por hora, vaga, povoado C, coluna `work_place_id`, `sell`, LW-096a, `mint` na LW-093, LW-088a, `request_trade`, `bid` e `ask`). O roadmap passou a dizer isso nas linhas que você citou e ganhou duas subtarefas. Nenhum código, dado, teste, `ROADMAP_STATUS.md` ou `README.md` foi tocado.

## 2. Arquivos criados
- Nenhum.

## 3. Arquivos modificados (contra o commit anterior `44e29df`)
- `docs/DECISIONS.md` — +247 −81: 11 entradas novas (DEC-163 a DEC-173), 5 entradas revistas (DEC-150 a 153 e 159), frases em DEC-132, 133 e 137, nota na DEC-034, 11 linhas de índice, totais, versão 0.7, histórico, "próximo número". **68 trechos do diff**, a maioria **mecânica**: a troca dos rótulos "da B" e "da C" nas células de origem das entradas 129 a 162.
- `docs/DEVELOPMENT_ROADMAP.md` — +21 −12: LW-088a e LW-096a (linhas novas), LW-091, 092, 093, 093a, 094, 095, 096, 097, 098, 109 e 110, nota e diagrama de 3.E.
- `docs/decisions/0012-pre-voo-da-fase-3.md` — +36 −19: seção 7 "Rodada 2", sem citações a `STATUS-B.md`, `STATUS-C.md` ou rótulos de agente.
- `docs/backlog.md` — +1 linha, no meio do arquivo (consumo de roupa e ferramenta pessoal pelo NPC, fora da Fase 3).
- Não toquei em `AGENTS.md`, GDD, arquitetura, `project.godot`, `data/`, `tests/`, `README.md` nem `ROADMAP_STATUS.md`.

## 4. Decisões técnicas
- **Onde agrupei (você pediu "só o que for óbvio"):** o item (j) (payload do `RouteStateChanged`) foi **para dentro da DEC-159** (rota só `open` e `closed`), e o item (k) (`bid` e `ask`) **para dentro da DEC-150** (forma do preço), porque são o mesmo assunto; (h) deu **duas** entradas (regra do `check_architecture` na DEC-171; fixture e hashes na DEC-172, onde juntei "para e pede autorização" com "hashes uma vez por marco"). Os demais itens têm **uma entrada cada**.
- **Revistas, em vez de novas:** a DEC-151 e a DEC-152 foram **reescritas** (são PROPOSTA minha e ainda não entraram no `main`), como você mandou; a "limitação" sumiu.
- **O item (g)** virou uma entrada própria (DEC-170, PROPOSTA) e **não** mudou a DEC-133 (APROVADA, com o "ou"): a DEC-133 só ganhou uma frase apontando para a DEC-170.
- **LW-096a e LW-088a** são subtarefas: não entram na contagem das 30 tarefas (nota sob 3.D).
- **Proposta de entrada para `DECISIONS.md` / pedido de desvio:** nenhum.

## 5. Testes executados
- `git fetch origin '+refs/heads/main:refs/remotes/origin/main'`: `main` em `8dcc81d` (o esperado); `git merge-base --is-ancestor origin/main HEAD`: já dentro do ramo, **nada a juntar**.
- Script de recontagem (`python3 -I recount_decisions.py docs/DECISIONS.md`): antes `162 · CONFERE` e depois `173 · CONFERE`, com os totais acima. Script de coerência: status do índice = status de cada entrada (173), toda `DEC-NNN` citada no roadmap, no 0012 e no backlog existe, toda seção do 0012 citada pelas entradas existe.
- Busca de `STATUS-B`, `STATUS-C`, `status-b`, `status-c`, "da B" e "da C" nos quatro arquivos: **nenhuma ocorrência**.
- **`tools/check_all` no HEAD final `86584d6` (21:07:22 a 21:10:47, 10/11/2026): VERDE** (`EXIT_CODE_CHECK_ALL=0`).
- **NÃO EXECUTADO:** oráculo, vida de 30 dias, `run_sim` (só documentos).

## 6. Resultados
- **`check_all`:** 124 scripts, **1.194 testes, 1.194 passando, 0 falhando**, 261.693 asserts, 172,5 s; 313 scripts sem aviso de compilação; nenhum "SCRIPT ERROR" nem "Parse Error".
- **Critério de aceite, item a item:** 1 (DEC-152 e 153 revisadas, DEC-163 e 164 novas APROVADAS, PROPOSTAS de b a k, nota na DEC-034, totais por script, versão 0.7) · 2 (LW-088a, 091, 092, 093, 095, 096, 096a, 097, 098, 109 e 110; nada renumerado) · 3 (0012, seção 7) · 4 (backlog, uma linha) · 5 (merge: nada a juntar).

## 7. Problemas encontrados
- **O erro da DEC-031** (acima): o número veio do meu relatório da rodada 1.
- **O "vínculo por evento"** (acima): texto meu da rodada 1, corrigido.
- **Citações a documentos fora do `main`:** o 0012 e as entradas citavam o pré-voo como `STATUS-B.md` e a origem das perguntas como "B" e "C"; limpei.
- **Duas regras da sua lista dependem de estados futuros:** a regra do `check_architecture` (LW-088a) só funciona se a regra D atual de fato não cobrir "a economia não cita o `npc`" (a B e a ficha dizem que não cobre; **não reconferi no código**, é a conferência que a LW-088a faz).

## 8. Riscos
- **31 entradas minhas ainda são PROPOSTA** (22 da rodada 1 e 9 desta): guiam o trabalho, mas você não as aprovou; os contratos da B e da C já escritos seguem as mesmas decisões.
- **A LW-093, a LW-094, a LW-095, a LW-096a e a LW-097 mexem nos mesmos arquivos do `npc`** (`npc_module.gd`, `action_runner.gd`, `npc_persistence.gd`, o carregador da população): a frente do `npc` deve ficar com um agente só.
- **A LW-097 concentra hashes novos, formato de dado novo (`work_place_id`) e o povoado C:** é a tarefa mais pesada em decisões suas; vale revê-la antes de preparar o prompt.
- **O `check_temp` olhando `tools/` e `tests/`** continua com a limitação de não se acionar sozinho (0012, 2.6).

## 9. Pendências
- **Para você decidir (cada uma com a minha recomendação):** (1) aprovar ou trocar as **31 PROPOSTA** — recomendo aprovar depois de ler o 0012, seção 7.2; (2) a **DEC-167** (formato de `population.json`) só quando a LW-097 for preparada; (3) a **casca na LW-088a** — recomendo manter; (4) a **nota da DEC-054** nas DEC-005, 045 e 053 — recomendo acrescentar a mesma nota curta; (5) **DEC-148 × linha da LW-092** — recomendo ajustar a linha da LW-092 numa próxima rodada.
- **Fase B:** não autorizada. A linha de status e o `README` entram só quando você mandar o rascunho para o `main`.
- **Teste manual:** nenhum (só texto). Basta ler a tabela acima e o 0012, seção 7.

## ACOMPANHAMENTO
- **Avanço:** a LW-087a é a primeira parte da LW-087; a Fase 3 não começou (contagens do status inalteradas).
- **Próxima tarefa recomendada:** a sua revisão da rodada 2 e, se aprovada, a Fase B da LW-087a; depois os rascunhos 087b, 087c e 087d (da B e da C) entram na ordem que você escolher. **Não iniciada.**
- **Decisões que dependem de você:** as cinco acima.
- **Git:** **um** commit novo (`86584d6`) no ramo `lw-087a-registro-fase-3`; empurrados **só** esse ramo e o `status-a`; nada no `main`, nenhuma tag, sem `--force`.
