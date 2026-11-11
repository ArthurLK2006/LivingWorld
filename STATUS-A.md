11/11/2026 09:44 (Brasília) · SEQUÊNCIA DA A: Partes 1 e 2 CONCLUÍDAS (`main` em `9b4f6f0`); Parte 3 (LW-088a) PARADA no seu PARE (2): o primeiro valor de referência mudou (oráculo `intents`, e os outros 8 também); nada commitado, nenhum valor esperado editado; espero o seu "aprovo os hashes do marco 1"

# RELATÓRIO — SEQUÊNCIA DA A: LW-093b (Fase B), LW-087 (fechamento) e LW-088a     Status: LW-093b e LW-087 PRONTAS PARA REVISÃO (já no `main`) · LW-088a PARCIAL (parada no PARE 2, sem commit)

## 1. RESUMO
**Parte 1 (LW-093b, Fase B):** o `main` entrou com o `APROVADO LW-093b`: junção com o `main`, uma linha de status e `check_all` verde, por avanço simples (`4ada136`). **Parte 2 (LW-087):** o GATE passou e as quatro partes (087a a 087d) foram fechadas no `main` (`9b4f6f0`), com o placar recontado por `grep`: Fase 3 = 1 de 30 e projeto = 88 de 192. **Parte 3 (LW-088a):** registrei a casca da `economy` no jogo e parei, como você mandou, no primeiro valor de referência que mudou. **Não há commit da LW-088a**, nenhum valor esperado foi editado e a fixture `save_v1` está intacta. A causa é uma só: o save do mundo ganhou o bloco vazio `"economy": {}`; sem ele, os nove valores do oráculo voltam aos antigos (prova abaixo). O `run_sim` não mudou.

## PARTE 3 — O PARE (2), com os números
**O primeiro valor que mudou:** oráculo `intents` (minuto 60): **antes `6e12b3067120…`, depois `223b8ec6a7ed…`**. Mudaram os nove:

| Fase do oráculo | Antes | Depois |
|---|---|---|
| intents (min 60) | `6e12b3067120` | `223b8ec6a7ed` |
| alarm (min 240) | `506a4a23ce89` | `dfe616868618` |
| resumed (min 250) | `7008d3b19d38` | `db2469cec836` |
| switches (min 310) | `84ca55684e34` | `888b1962d83b` |
| talk (min 740) | `ce14b1e45954` | `8b04890c8c9b` |
| save (min 870) | `142733eb318f` | `5673e2b3911b` |
| demote (min 1810) | `00794d5a27b6` | `62c86fea8233` |
| starved (min 6300) | `3e1d080d2eed` | `52c2d24b40fc` |
| real_game (min 1440) | `f9469ccc5a9d` | `edf6ebb03cb9` |

(Os valores completos de 64 caracteres, novos e antigos, estão na saída do teste; as constantes ficam em `tests/integration/test_npc_split_oracle.gd`, linhas 47 a 55, **sem mexer**.) Os soaks, que só **imprimem** o hash (não há valor fixo guardado): vida de 7 dias `dad2d10abf75` → `af5bdb5e1f21`; soak de 300 NPCs `31322f97796b` → `52b7851aefc0`; soak de 30 dias `d13b921112ce` → `82f81b239759`.

**Causa, em palavras simples:** o hash é a "impressão digital" do save do mundo inteiro. Ao registrar a `economy`, o save passou a ter um bloco a mais, `"economy": {}`, vazio. Um bloco a mais muda a impressão digital de **todo** jogo, mesmo que a economia não faça nada ainda. Nenhum NPC passou a se comportar diferente.

**Prova (temporária, desfeita):** tirei de propósito o bloco vazio do hash (e fiz o carregamento aceitar a falta dele) numa cópia de `src/core/world/world.gd` e rodei o oráculo: **2/2 passaram, com os nove valores antigos de volta**. Restaurei o arquivo e conferi que ficou **idêntico ao backup** (`cmp`; `git status` sem nada em `src/core`). Uma primeira tentativa, só com a parte do hash, deixou `save`, `demote` e `starved` diferentes, e eu a descartei como prova: o meu remendo quebrava o carregamento (o `World` exige o bloco), então esses três divergiam por culpa do remendo, não da economia; a segunda, completa, é a que vale.

**`run_sim` antes e depois (`--days 30 --seed 1`): IGUAIS.** `732907967efdba5f718687a0bbafbfe102ac51cabc9d15a7f0119a9e64ebc4d7` nos dois, 0 problemas (como o contrato previa: o `run_sim` não registra módulo).

**Fixture:** `tests/unit/test_save_codec.gd` rodou **primeiro**: 12/12 passaram; `git status tests/fixtures` vazio. Não preciso da autorização escrita para a fixture.

**Outros testes que o registro quebra (3, fora o oráculo):** os três conferem a lista exata de módulos registrados, que hoje é `[character, npc]` e passa a ser `[character, economy, npc]`: `tests/unit/test_npc_state.gd` linha 441 ("O npc é registrado depois do character"), `tests/unit/test_settlements.gd` linha 323 (as chaves do save) e `tests/unit/test_sim_bridge_character.gd` linhas 149 e 150. **Não editei** (AGENTS 9.5: teste existente só com pergunta); veja o pedido (B) na seção 9.

## 2. ARQUIVOS CRIADOS
- **Partes 1 e 2:** nenhum arquivo novo no `main` (a Parte 1 só trouxe o teste da LW-093b, que já existia no ramo).
- **Parte 3 (só no diretório de trabalho do ramo `lw-088a-registro-economy`, NÃO commitado e NÃO empurrado):** `src/sim/economy/economy_module.gd` (a casca: `serialize()` devolve `{}` e `on_load` aceita só o bloco vazio, com o código `ECON_INVALID_SAVE`) e o `.uid` dele (gerado pelo Godot).

## 3. ARQUIVOS MODIFICADOS
- **Parte 1 (no `main`):** `docs/ROADMAP_STATUS.md` +1 linha (a LW-093b em "Tarefas extras"; as contagens não mudam). Mais as duas junções com o `main` (`f54c657` e `4ada136`), que só trouxeram documentos.
- **Parte 2 (no `main`):** `docs/ROADMAP_STATUS.md` (+9 −3: cabeçalho, nova seção "Tarefas da Fase 3" com a LW-087, e uma frase da linha da LW-087a) e `docs/decisions/0012-pre-voo-da-fase-3.md` (1 palavra: "rascunho" virou "registrada no main em 11/11/2026").
- **Parte 3 (não commitado):** `src/app/game_modules.gd` (+11 −3: constante `ECONOMY_NAME`, campo `economy` e o registro entre `character` e `npc`).

## 4. DECISÕES TÉCNICAS
- **Interpretações minhas na Parte 3 (AGENTS 16.1, dentro do escopo):** (1) "onde quer que o `npc` seja registrado" = o `GameModules.register`, único ponto do jogo, do runner e dos testes de jogo inteiro; os cerca de 30 testes que montam um `World` só com o `npc` não foram tocados (mexer neles passaria muito de 8 arquivos); (2) ordem `character`, `economy`, `npc`; (3) o `on_load` da casca recusa qualquer bloco não vazio (AGENTS 12.6); (4) a regra nova do `check_architecture` entra no bloco de camadas como "regra E", e a mensagem "nove verificações" não muda (como na regra D). Ainda **não implementadas**: a regra E, os testes dela, o teste do módulo e a documentação.
- **Parte 2:** o recálculo do placar foi por contagem de linhas `| LW-NNN |` com estado concluída ou dispensada, por seção (31 + 23 + 32 + 1 antecipada + 1 da Fase 3 = 88). Acrescentei a seção "Tarefas da Fase 3" e uma frase no cabeçalho, porque o arquivo não tinha onde registrar a fase.
- **Proposta de entrada para `DECISIONS.md` / pedido de desvio:** nenhum.

## 5. TESTES EXECUTADOS
- **Parte 1:** `tools/check_all` em `5279f2c` (09:18 a 09:22) e de novo em `4ada136` (09:22 a 09:25, depois de o `main` andar): **VERDE** nas duas, 125 scripts, 1.203 testes, 262.120 asserts, hashes idênticos aos da base; `git ls-remote` conferido.
- **Parte 2:** GATE conferido em `origin/main`; `tools/check_all` em `9b4f6f0` (09:28 a 09:31): **VERDE** (125 / 1.203 / 262.120, mesmos hashes); `git ls-remote` conferido.
- **Parte 3 (antes de mexer):** `tools/run_sim --days 30 --seed 1`; `tests/soak/run_npc_life_30d` (`d13b921112ce`); valores do oráculo e dos soaks do último `check_all` verde.
- **Parte 3 (depois do registro, sem nenhuma edição de teste):** `tests/unit/test_save_codec.gd` 12/12; `test_npc_split_oracle.gd` 0/2 (os 9 hashes); `tools/run_sim` igual; `tools/check_all` **VERMELHO** (125 scripts, 1.203 testes, 1.198 passando, **5 falhando**: os 2 do oráculo e os 3 das listas de módulos; 315 scripts sem aviso; arquitetura: nove verificações aprovadas); `tests/soak/run_npc_life_30d` 1/1 (`82f81b239759`).
- **NÃO EXECUTADO** (a Parte 3 parou antes): a regra E do `check_architecture` e os testes dela, o teste do `EconomyModule` e a documentação.

## 6. RESULTADOS
- **Partes 1 e 2:** cumpridas; `main` = `9b4f6f0`; placar **88 de 192 (45,8%)** e **Fase 3: 1 de 30 (3,3%)**.
- **Parte 3:** o aceite **não** foi cumprido (a tarefa parou). O que está provado: a casca não mexe no comportamento (nove valores voltam sem o bloco vazio); a fixture protegida não é atingida; o `run_sim` não muda.

## 7. PROBLEMAS ENCONTRADOS
- O `main` **andou durante a Parte 1**: você disse `e3f715e` (14 commits à frente); quando fiz o `fetch` estava em `7179975` (27 commits) e depois em `ce0cbed`. Só vieram documentos. O `main` andou entre a primeira junção com `check_all` e o push, então refiz uma vez (junção e `check_all`); nenhum push foi recusado, e o push passou na primeira tentativa.
- **Frase velha do `README.md`:** a linha 9 ainda diz "avanço total do projeto: 87 de 192 tarefas (45,3%)", e agora o `ROADMAP_STATUS.md` diz 88. Você mandou o commit da Parte 2 só nos dois arquivos citados, então **não mexi no `README.md`**; fica para você decidir.
- **`docs/modules/economy.md`:** a linha "Estado" ainda diz que "nenhum código, dado ou teste existe" e a Parte 3 tornará isso falso. Pretendo corrigir com uma frase junto da LW-088a (veja pedido C).
- Ruído esperado no `check_all`: "Decompression failed" (já estava na base) e o aviso de `wait_frames` do GUT em `test_app_nodes.gd` (não é meu).

## 8. RISCOS
- Se aprovar os hashes **e** os três ajustes, a Parte 3 mexe em **9 arquivos de código e teste** (o módulo, `game_modules.gd`, `check_architecture`, o teste dele, o teste novo do módulo, o oráculo e as três listas): acima de ~8, mas dentro da tolerância de 1,5× da DEC-126 (até ~12); as linhas ficam perto de 150, bem abaixo de ~300.
- Os valores novos dos soaks (vida de 7 dias, 300 NPCs e 30 dias) **não** estão guardados em nenhum teste (só são impressos); mesmo assim peço que o seu "aprovo" os cubra, porque são hashes do marco 1.
- O soak de 30 dias roda fora do `check_all` (cerca de 80 s); o `check_all` não o pega.

## 9. PENDÊNCIAS (o que eu preciso de você, com a minha recomendação)
- **(A) "aprovo os hashes do marco 1"** (os nove do oráculo e os três dos soaks, tabela acima). **Recomendo aprovar:** a causa é só o bloco vazio e a prova mostra que o comportamento não mudou. Só depois disso grave os valores novos no oráculo e termino.
- **(B) Os três testes de lista de módulos** (`test_npc_state.gd:441`, `test_settlements.gd:323` e `test_sim_bridge_character.gd:149`): trocar `[character, npc]` por `[character, economy, npc]`. **Recomendo autorizar:** é consequência direta do registro que você mandou, e o texto dos testes continua dizendo o que querem dizer. Escreva por exemplo "aprovo os hashes do marco 1 e a lista de módulos nos 3 testes".
- **(C) Uma frase no `docs/modules/economy.md`** (linha "Estado": a casca da economia passa a existir; o resto segue PLANEJADO), além de marcar a LW-088a como IMPLEMENTADA; **recomendo** deixar.
- **(D) O `README.md` linha 9** (87 → 88 e 45,3% → 45,8%): fora do que você autorizou; **recomendo** um commit curto só disso.
- **Teste manual:** nenhum.

## ACOMPANHAMENTO
- **Avanço:** Fase 3 = 1 de 30 (3,3%); projeto = 88 de 192 (45,8%). A LW-088a é subtarefa e não entra na conta.
- **Próxima tarefa recomendada:** terminar a LW-088a assim que você responder (A) e (B); depois a LW-088. **Não iniciada.**
- **Decisões que dependem de você:** (A), (B), (C) e (D) acima.
- **Git:** `main` = `9b4f6f0` (Partes 1 e 2). Ramos empurrados: `lw-093b-oficio-so-por-json` (`4ada136`) e `lw-087-fechamento` (`9b4f6f0`). **`lw-088a-registro-economy`: só local, sem commit** (3 arquivos no diretório de trabalho, descritos na seção 2 e 3). Nenhuma tag, sem `--force`, `tests/fixtures` intacto, nenhum Godot meu em execução.
