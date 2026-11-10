10/11/2026 18:57 (Brasília) · PRONTA PARA REVISÃO · LW-085e: `check_all` verde no HEAD `b07771a` do ramo `lw-085e-regras-e-decisoes` (já empurrado); NÃO entrou no `main`: só com "APROVADO LW-085e"; o Godot da A está parado

# RELATÓRIO — LW-085e: Regras e decisões da revisão da Fase 2     Status: PRONTA PARA REVISÃO (NÃO está no `main`)

> **Em uma frase:** só texto, nenhum código. Abaixo estão o ANTES e o DEPOIS exatos das sete linhas do `AGENTS.md` que mudaram e as três entradas novas do `DECISIONS.md`. **Nada entra no `main` até você digitar, nesta conversa, exatamente: `APROVADO LW-085e`** (e a Fase B começa na hora, sem esperar mais nada, como você mandou).

## O que mudou no `AGENTS.md` (ANTES e DEPOIS, copiados do Git)

Sete linhas mudaram e nenhuma outra (conferido por `git diff` contra o `main` `497ab78`: 7 linhas acrescentadas e 7 removidas). Em palavras simples: o limite de ~300 linhas por arquivo e o de ~300 linhas e ~8 arquivos por tarefa passam a contar só código e teste, com folga de 1,5×; os itens 11 e 16.2 repetem a mesma contagem; o item 4.15 ganha uma frase dizendo que o `save_version` fica em 2 até o "save congelado"; e a versão sobe para 0.4 no cabeçalho e no rodapé.

### Cabeçalho (versão)

**ANTES:**

> **Versão 0.3 · 01/11/2026 (Brasília) · Leitura obrigatória para todo agente de programação (Codex ou outro).**

**DEPOIS:**

> **Versão 0.4 · 10/11/2026 (Brasília) · Leitura obrigatória para todo agente de programação (Codex ou outro).**

### Item 4.5 (tamanho de arquivo)

**ANTES:**

> 5. **Funções pequenas, uma responsabilidade.** Arquivo até ~300 linhas; passou disso, proponha divisão.

**DEPOIS:**

> 5. **Funções pequenas, uma responsabilidade.** Arquivo até ~300 linhas, contando só código e teste (sem comentário, linha em branco, `.uid` nem documento), com tolerância de 1,5× (~450 linhas); passou do teto, **PARE** e proponha a divisão (DEC-126).

### Item 4.15 (save_version)

**ANTES:**

> 15. **Estado novo exige** `serialize`/`on_load`, `validate()` e `debug_summary()`. Mudou o estado salvo → atualize `save_version` e o **teste de ida e volta**. Migração de save antigo só depois do "save congelado" (DEC-083); antes disso, save antigo é rejeitado com mensagem clara.

**DEPOIS:**

> 15. **Estado novo exige** `serialize`/`on_load`, `validate()` e `debug_summary()`. Mudou o estado salvo → atualize `save_version` e o **teste de ida e volta**. Migração de save antigo só depois do "save congelado" (DEC-083); antes disso, save antigo é rejeitado com mensagem clara. Enquanto o "save congelado" não existir, o `save_version` fica em 2 (DEC-127).

### Item 5.2 (tamanho de tarefa)

**ANTES:**

> 2. **Limite de tamanho:** até ~300 linhas alteradas e ~8 arquivos, contando testes. Passou? **PARE e proponha a divisão.**

**DEPOIS:**

> 2. **Limite de tamanho:** até ~300 linhas alteradas e ~8 arquivos, contando só código e teste (sem comentário, linha em branco, `.uid` nem documento), com tolerância de 1,5×. Passou do teto? **PARE e proponha a divisão** (DEC-126).

### Item 11 (autorrevisão, 1ª caixa)

**ANTES:**

> - [ ] Só tocou arquivos do escopo? Dentro de ~300 linhas e ~8 arquivos?

**DEPOIS:**

> - [ ] Só tocou arquivos do escopo? Dentro de ~300 linhas e ~8 arquivos (só código e teste, tolerância de 1,5×; ver 5.2)?

### Item 16.2 (quando parar)

**ANTES:**

> - passar de ~300 linhas / ~8 arquivos / mais de um módulo;

**DEPOIS:**

> - passar de ~300 linhas / ~8 arquivos (só código e teste, tolerância de 1,5×; ver 5.2) / mais de um módulo;

### Rodapé (versão)

**ANTES:**

> **Fim do AGENTS.md — versão 0.3.**

**DEPOIS:**

> **Fim do AGENTS.md — versão 0.4.**


## As três entradas novas do `DECISIONS.md` (em palavras simples)

Todas com status **APROVADA**, decisão sua de 10/11/2026, a partir de `docs/decisions/0011-revisao-fase-2.md`. O texto completo (contexto, decisão, justificativa, consequências, relações) está em `docs/DECISIONS.md` (DEC-126 a DEC-128, antes da seção 7 "Como acrescentar").

- **DEC-126 — Tamanho de arquivo e de tarefa: contar só código, com tolerância de 1,5×.** O limite conta só código e teste (sem comentário, linha em branco, `.uid` nem documento), com folga de 1,5× (cerca de 450 linhas de código por arquivo). Passou do teto: **PARE** e proponha a divisão. A mesma contagem vale para a tarefa (~300 linhas e ~8 arquivos). **Nada é dividido agora.** Contexto: seis arquivos passavam de 300 linhas contando tudo (o maior, `npc_module.gd`, 603 linhas; 336 só de código); por esta contagem nenhum passa. Relações: DEC-087, DEC-093.
- **DEC-127 — `save_version` continua em 2 até o "save congelado".** O `AGENTS.md` (4.15) manda subir o número quando o estado salvo muda; a decisão é manter 2 até o congelamento. Quem protege os saves é o teste de ida e volta (roda no `check_all`) e a validação do `on_load`. Hoje não existe save de jogador, então nada se perde; o número não distingue os saves da Fase 2 entre si. Vale como exceção ao 4.15 (decisão APROVADA manda mais que o `AGENTS.md`). Relações: DEC-083, DEC-084.
- **DEC-128 — As cinco ações de entrada acrescentadas ao `project.godot` na LW-082g foram autorizadas.** `inspector_toggle` (F3), `inspector_toggle_alt` (Tab), `inspector_next` (N), `inspector_previous` (B) e `inspector_trace` (T): 25 linhas, só acréscimos (commit `89c8182`), cobertas pela sua autorização escrita da LW-082g ("só ADICIONAR ações de entrada"). Fica registrado para a auditoria; não é desvio. Qualquer outra mudança no `project.godot` continua exigindo autorização expressa. Relações: DEC-087, DEC-125.

Junto vieram (como na LW-071f, e você aprovou manter): as 3 linhas do índice na Área 10, os totais recontados (**128 entradas, 67 APROVADAS**, 19 com ressalva; PROPOSTA 32 · PENDENTE 18 · DESCARTADA 10 · SUBSTITUÍDA 1), a versão 0.5 do documento, a linha 0.5 do histórico e o "próximo número livre" (DEC-129). O índice tem 128 linhas e o corpo 128 entradas, sem número repetido. **Nenhuma entrada existente foi alterada:** as únicas linhas antigas removidas são a da versão, a dos totais (reescrita com a nova na frente) e a do "próximo número livre". O `DECISIONS.md` do `main` não tinha ganhado entrada nova (conferido), então a numeração ficou DEC-126 a DEC-128.

## 1. Resumo
As três decisões que você tomou na revisão da Fase 2 (`0011`) viraram DEC-126, DEC-127 e DEC-128 no `DECISIONS.md`. O `AGENTS.md` passou a contar tamanho só em código e teste com folga de 1,5× (itens 4.5, 5.2, 11 e 16.2), ganhou a frase do `save_version` no 4.15 e subiu para a versão 0.4. Corrigi duas linhas do `npc.md` (as nove impressões do oráculo são cinco de `5a7d453` e quatro da LW-073b), a frase do `0011` sobre DEC-083/084 e acrescentei quatro linhas ao meio do backlog. Juntei o `main` (`497ab78`) no ramo. Nenhum código foi tocado.

## 2. Arquivos criados
- Nenhum.

## 3. Arquivos modificados (contra o `main` `497ab78`)
- `AGENTS.md` — 7 linhas trocadas (as acima).
- `docs/DECISIONS.md` — +49 −3: três entradas, três linhas no índice, totais, versão 0.5, histórico, "próximo número".
- `docs/modules/npc.md` — 2 linhas (136 e 220): "nove impressões" agora diz cinco de `5a7d453` e quatro da LW-073b (commit `5346091`; a explicação está no item do detector de impasse).
- `docs/backlog.md` — +4 linhas no meio do arquivo: M4 da C (teste que lista quem escreve em `need_values`), M6 da C (`CM_PER_METER` repetido), M9 da C (a LW-094 deve avisar que remover o `FoodStub` muda o save) e o comentário de `npc_module.gd:418` ("não pode mudar enquanto não há impasse").
- `docs/ROADMAP_STATUS.md` — +1 linha (LW-085e, subtarefa; **a contagem não muda**).
- `docs/decisions/0011-revisao-fase-2.md` — 1 linha: DEC-083 e DEC-084 passam ao status do índice (APROVADAS com ressalva: a 083 só nos princípios; a 084 como formato de save do protótipo).

Commits no ramo `lw-085e-regras-e-decisoes`: `4eb495c`, `9402fd2`, `c19cdd3` (junção com o `main` `497ab78`), `1ff78a7`, `b07771a` (HEAD final).

## 4. Decisões técnicas
- **Junção com o `main` (`497ab78`).** Dois conflitos, ambos de linhas acrescentadas (`docs/backlog.md` e `docs/ROADMAP_STATUS.md`); mantive as duas partes em cada um. Nenhum outro conflito. O `README.md` entrou sem conflito.
- **Frase do 4.15.** Acrescentei no fim do item: "Enquanto o "save congelado" não existir, o `save_version` fica em 2 (DEC-127)." Não mexi no resto do item. Ele ainda começa com "Mudou o estado salvo → atualize `save_version`"; a frase nova é a exceção. **Dúvida sua:** se prefere que a frase diga "exceção" com todas as letras (ver Decisões que dependem de você).
- **Itens 11 e 16.2.** Acrescentei entre parênteses "(só código e teste, tolerância de 1,5×; ver 5.2)", sem outra mudança.
- **Textos de DEC-126 e DEC-127.** Escritos antes da sua resposta, diziam que os itens 11, 16.2 e 4.15 ficavam como proposta; atualizei para dizer que foram alinhados (commit `b07771a`).
- **Placar.** Depois da junção, por `grep`: `ROADMAP_STATUS.md` 1 vez "31 de 32" e 1 vez "86 de 192"; `README.md` 2 e 2. Igual ao `main`. A minha linha não escreve o placar.
- **Proposta de entrada para `DECISIONS.md`:** nenhuma além das três já incluídas por ordem sua.

## 5. Testes executados
Tudo no worktree `lw-085e`, no HEAD final `b07771a` (depois da junção com o `main` `497ab78` e de todos os commits da tarefa).

- `git fetch origin` e `git merge --no-ff origin/main` — 2 conflitos (só linhas acrescentadas em `docs/backlog.md` e `docs/ROADMAP_STATUS.md`), resolvidos mantendo as duas partes; `grep` de marcadores `<<<<<<<` e `>>>>>>>` em `AGENTS.md`, `docs/` e `README.md` — nenhum sobrou.
- `grep -c` do placar em `docs/ROADMAP_STATUS.md` e `README.md` (antes no `main`, depois da junção, depois dos commits finais) — iguais nas três vezes: status 1 "31 de 32" e 1 "86 de 192"; README 2 e 2.
- Contagem das entradas do `DECISIONS.md` por script de shell: 128 linhas de índice, 128 cabeçalhos, 0 números repetidos.
- `git diff -U0 origin/main HEAD -- AGENTS.md` — exatamente 7 linhas trocadas (cabeçalho, 4.5, 4.15, 5.2, 11, 16.2 e rodapé); `git diff --numstat origin/main HEAD -- docs/DECISIONS.md` — 49 acrescentadas e 3 removidas (versão, totais e "próximo número").
- `tools/check_architecture` — "nove verificações aprovadas"; `tools/check_input_keys` e `tools/check_literal_text` — aprovados.
- `"/Applications/Godot 2.app/Contents/MacOS/Godot" --headless --path . --import` — concluiu e criou `.godot`.
- **`tools/check_all` (rodada que vale, 18:52:31 a 18:56:00 de 10/11/2026, Brasília, HEAD `b07771a`) — `VERDE: arquitetura, dados e etapa de testes aprovadas.` (saída 0).** Antes dela houve duas tentativas que **não valem** e não rodaram teste (explicadas em "Problemas encontrados"): uma parada por mim e uma vermelha em 14 s por eu ter chamado `godot` fora do PATH.
- Bateria de identidade (oráculo, vida de 30 dias, impasse de 30 dias, `run_sim`): **NÃO EXECUTADA** — a tarefa não toca código, `data/` nem testes; a diferença para o `main` é só texto.
- Testes manuais: nenhum (não há o que jogar; é só texto).

## 6. Resultados
- **`tools/check_all` verde:** 124 scripts, **1.194 testes, 1.194 passando, 0 falhando**, 261.693 asserts, 173 s; 313 scripts sem aviso de compilação; dados e `run_sim` aprovados; nenhum "SCRIPT ERROR" nem "Parse Error" na saída. O resumo do GUT mostra "Warnings 1" e "Deprecated 1" (o "Deprecated" é o que o backlog já cita; esta tarefa não toca código). As linhas `_test_the_scripts` na saída são o rastro das mensagens de erro que os próprios testes provocam e esperam ("ExpectedError").
- **Critério de aceite (cada item da sua ordem):** (1) DEC-126, DEC-127 e DEC-128 acrescentadas, APROVADA, 10/11/2026, no número livre seguinte, sem alterar entrada existente — conferido por contagem de índice e por `git diff` (só versão, totais e "próximo número" saíram). (2) `AGENTS.md`: 4.5, 5.2, 11, 16.2, 4.15, cabeçalho e rodapé; nenhuma outra linha — conferido por `git diff` (7 e 7). (3) `npc.md`: 2 linhas, sem código. (4) Quatro linhas no meio do backlog. (5) Linha da LW-085e como subtarefa; contagem igual por `grep`. (6) `0011`: frase de DEC-083 e DEC-084 no status do índice. (7) Junção com o `main` `497ab78`: 2 conflitos só de linhas acrescentadas; placar igual ao `main`; o `DECISIONS.md` do `main` não ganhou entrada.
- **Não verificado:** nada além do que está em "Testes executados" como NÃO EXECUTADO. Não comparei os números do `check_all` com os do `main`; o ramo não muda código.

## 7. Problemas encontrados
- **Meu vigia esperou à toa cerca de 45 minutos (de 18:03, quando a C parou, até 18:49).** Ele procurava a palavra "rodando" em qualquer lugar da primeira linha do `STATUS-C.md`, e a C escreveu "Nada rodando" (negado). Você já fixou a regra: "rodando" só vale como estado ("· rodando ·"). Não rodei Godot nesse tempo.
- **Rodadas de `check_all` que não valem.** (1) Parei a primeira por mim mesmo, com cerca de um minuto, ao perceber que DEC-126 e DEC-127 ainda diziam que 11, 16.2 e 4.15 ficavam como proposta; corrigi, commitei e comecei de novo. (2) A segunda voltou **VERMELHA em 14 s por erro do meu comando:** o `godot` não existe no PATH desta shell, então a importação não rodou, o cache de classes não foi criado e todo `class_name` deu "Could not find type"; nenhum teste foi executado. O Godot do projeto é `/Applications/Godot 2.app/Contents/MacOS/Godot` (`GODOT_BIN`, como em `tools/check_prerequisites`). (3) A terceira, com a importação feita pelo Godot certo, é a que vale (abaixo). Foi mais de uma rodada, e não a "uma vez" que você pediu; as duas primeiras não chegaram a rodar teste. Depois você liberou o Mac ("aguenta tudo ao mesmo tempo") e mandou ignorar o "rodando" e o "janela livre"; a rodada válida já estava feita e verde.
- **Divergência antiga, já resolvida pela sua decisão:** o `0011` dizia DEC-083 e DEC-084 "pendentes e PROPOSTA" e o índice diz APROVADA com ressalva; o `0011` agora segue o índice.

## 8. Riscos
- O 4.15 do `AGENTS.md` diz "atualize `save_version`" e, na frase seguinte, que fica em 2. Quem ler só a primeira metade pode subir o número; a DEC-127 e a frase nova cobrem, mas a leitura fica mais pesada.
- A tolerância de 1,5× foi escrita no 5.2 sem dizer se vale também para os ~8 arquivos (12?) ou só para as linhas. O 5.2 diz "tolerância de 1,5×" no fim da frase dos dois limites, como na sua ordem.
- O `AGENTS.md` e o `DECISIONS.md` são arquivos protegidos: só entram no `main` com o seu `APROVADO LW-085e`.
- O comentário de `src/sim/npc/api/npc_module.gd:418` continua dizendo "não pode mudar enquanto não há impasse" (fora desta tarefa; está no backlog).

## 9. Pendências
- **Fase B, na hora em que você digitar `APROVADO LW-085e` aqui (sem esperar "janela livre"; a regra do "rodando" você mandou ignorar):** junção com o `main` sem conflito, `check_all` verde, nenhum arquivo protegido além de `DECISIONS.md` e `AGENTS.md` nos trechos citados, contagem por `grep` inalterada, sem tag; depois paro.
- **Para você conferir (não é teste de jogo):** ler o ANTES e o DEPOIS acima (sete linhas) e as três entradas; dizer se a frase do 4.15 está como você queria.

## ACOMPANHAMENTO
- **Avanço:** a LW-085e é subtarefa e não entra na conta; a Fase 2 e o projeto seguem como no `main` (31 de 32 e 86 de 192, conferidos por `grep` neste ramo).
- **Próxima tarefa recomendada:** a LW-086 (validação da Fase 2, sua passada na janela). Não iniciada.
- **Decisões que dependem de você:** (1) `APROVADO LW-085e` para a Fase B (recomendo aprovar: só texto, nenhum código, `check_all` verde). (2) A frase do 4.15 deve dizer "exceção"? Recomendo deixar como está (curta, como você pediu). (3) A tolerância de 1,5× vale também para o número de arquivos da tarefa? Recomendo dizer isso no 5.2 se for essa a sua intenção.
- **Git:** 5 commits no ramo `lw-085e-regras-e-decisoes` (HEAD `b07771a`), empurrados **só** o ramo da tarefa e o `status-a`; nada no `main`, nenhuma tag, sem `--force`.
