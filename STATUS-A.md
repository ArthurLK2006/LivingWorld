11/11/2026 14:11 (Brasília) · BLOCO 2 DA A, em andamento · LW-092 PRONTA em 3 partes (ramos `lw-092-producao`, `lw-092b-producao-hora-a-hora` e `lw-092c-ligacao-ao-modulo`); `check_all` VERDE na c: 141 scripts, 1.290 testes, 292.667 asserts; `run_sim` igual (732907967efd…); prova da causa dos hashes feita (sem o bloco `economy` os 9 valores ORIGINAIS do oráculo voltam); seguindo para a LW-093a (verificador de ids)

# RELATÓRIO — SEQUÊNCIA DA A: LW-093b (Fase B), LW-087 (fechamento) e LW-088a     Status: PRONTA PARA REVISÃO (Partes 1 e 2 já no `main`; Parte 3 só no ramo)

## 1. RESUMO
**Partes 1 e 2** (já informadas, no `main`): a LW-093b entrou (`4ada136`) e a LW-087, nas quatro partes, foi fechada (`9b4f6f0`), com Fase 3 = 1 de 30 e projeto = 88 de 192. **Parte 3 (LW-088a):** depois do seu "Aprovo os dois" (os hashes do marco 1 e a lista de módulos nos 3 testes), gravei os nove valores novos do oráculo, ajustei as três listas, acrescentei a regra E ao `check_architecture` (o `npc` cita só `economy/api`; a `economy` não cita o `npc`, com 4 casos de violação e 4 aceitos), criei o teste da casca (5 testes) e a documentação. Um commit (`d1caae0`), empurrado só o ramo. O `check_all` ficou verde, a fixture `save_v1` não foi tocada e o `run_sim` não mudou.

## Declaração de leitura (Parte 3, antes de mexer no código)
- **Li:** `AGENTS.md` v0.4; a linha da LW-088a e da LW-088 no roadmap; `docs/modules/economy.md` (seções 1, 2 e 14); `docs/modules/core.md`; `TECHNICAL_ARCHITECTURE` 11.1, 18.1–18.2 e 21.5 (**não li** os capítulos 17 e 21 inteiros; só esses trechos); `src/app/game_modules.gd`, `src/core/sim_module.gd`, `src/core/world/world.gd`, `src/sim/character/character_module.gd`, `tools/check_architecture`, `tests/test_check_architecture.sh`, `tools/run_sim` e `tests/test_run_sim.sh`.
- **Decisões (todas APROVADAS):** DEC-171, 172, 175, 132, 126, 127, 134 e 162.

## 2. ARQUIVOS CRIADOS (Parte 3, no commit `d1caae0`)
- `src/sim/economy/economy_module.gd` — a casca `EconomyModule`: `serialize()` devolve `{}` e `on_load` aceita só o bloco vazio (`ECON_INVALID_SAVE`); 26 linhas (13 de código). O `.uid` foi gerado pelo Godot.
- `src/sim/economy/api/README.md` — a `api/` vazia, só com o README.
- `tests/unit/test_economy_module.gd` — 5 testes, 33 asserts; 91 linhas (74 de código). O `.uid` também.

## 3. ARQUIVOS MODIFICADOS (Parte 3, no commit `d1caae0`)
- `src/app/game_modules.gd` — +13 −3: `ECONOMY_NAME`, o campo `economy` e o registro entre `character` e `npc`.
- `tools/check_architecture` — +8 −1: a regra E dentro do bloco de camadas (a mensagem "nove verificações" não mudou).
- `tests/test_check_architecture.sh` — +20: o bloco da regra E e a linha de resumo "LW-088a".
- `tests/integration/test_npc_split_oracle.gd` — os 9 hashes novos (os que você aprovou) e o comentário do marco 1.
- `tests/unit/test_npc_state.gd` (1 linha), `tests/unit/test_settlements.gd` (1 linha) e `tests/unit/test_sim_bridge_character.gd` (2 linhas e uma constante): a lista de módulos passou a `[character, economy, npc]`; nada foi enfraquecido.
- `src/sim/economy/README.md` e `docs/modules/economy.md`: a LW-088a passou a **IMPLEMENTADA em 11/11/2026** (seção 2, a conferência da fixture, o marco 1 aprovado e a linha do rastreio na seção 14).

## 4. DECISÕES TÉCNICAS
- **Onde registrar:** só em `GameModules.register`, que é o único ponto do jogo, do runner e dos testes de jogo inteiro. Os cerca de 30 testes que montam um `World` só com o `npc` não foram tocados. Ordem: `character`, `economy`, `npc`.
- **A casca só sobrescreve `serialize` e `on_load`.** O contrato dizia "com `serialize`, `on_load`, `validate` e `debug_summary`", mas sem estado `validate` e `debug_summary` ficam com o padrão do `SimModule`; escrevi isso na seção 2 do contrato e no README.
- **`ECON_INVALID_SAVE`** é um código novo (mesmo padrão do `CHARACTER_INVALID_SAVE`), só da casca; não está na tabela da seção 10 do contrato.
- **A regra E** fica no mesmo bloco das regras A a D, com o mesmo formato de mensagem. Segunda metade: a `economy` não cita nenhuma classe do `npc`, **nem a `api/` dele**.
- **O teste negativo da regra usa a pasta temporária do próprio script**, então nenhum arquivo foi criado em `tests/fixtures`.
- **Proposta de entrada para `DECISIONS.md` / pedido de desvio:** nenhum.

## 5. TESTES EXECUTADOS
- `tools/run_tests` nos quatro arquivos editados: oráculo 2/2, `test_npc_state` 20/20, `test_settlements` 23/23, `test_sim_bridge_character` 13/13; no novo, `test_economy_module` 5/5.
- `sh tests/test_check_architecture.sh`: passa (LW-088a: 4 violações detectadas e 4 casos aceitos); `tools/check_architecture` na árvore real: nove verificações aprovadas.
- **Controles de mutação** (em cópia, desfeitos, arquivo idêntico ao backup): regra E sem ver o `npc` citando classe interna da economy, **pega** ("o npc cita classe interna da economy não foi detectada"); regra E sem ver a `economy` citando o `npc`, **pega**; `on_load` aceitando tudo, 4/5; `serialize` com um campo, 3/5; economy registrada **depois** do `npc`, 4/5.
- **`tools/check_all` na árvore final** (10:20:54 a 10:24:21; a árvore não mudou entre o `check_all` e o commit `d1caae0`): **VERDE** (`EXIT_CODE_CHECK_ALL=0`).
- `tools/run_sim --days 30 --seed 1` e `tests/soak/run_npc_life_30d` na árvore final.

## 6. RESULTADOS
- **`check_all`:** 126 scripts, **1.208 testes, 1.208 passando, 0 falhando**, 262.153 asserts, 172,0 s; 316 scripts sem aviso de compilação; 0 "SCRIPT ERROR" e 0 "Parse Error". Contra a base (125 / 1.203 / 262.120): +1 script, +5 testes, +33 asserts, que são exatamente o `test_economy_module.gd`.
- **`run_sim` (`--days 30 --seed 1`), antes e depois: IGUAIS** — `732907967efdba5f718687a0bbafbfe102ac51cabc9d15a7f0119a9e64ebc4d7`, 0 problemas.
- **Os hashes do marco 1 gravados (os que você aprovou):** o oráculo `intents` `223b8ec6a7ed`, `alarm` `dfe616868618`, `resumed` `db2469cec836`, `switches` `888b1962d83b`, `talk` `8b04890c8c9b`, `save` `5673e2b3911b`, `demote` `62c86fea8233`, `starved` `52c2d24b40fc` e `real_game` `edf6ebb03cb9` (valores completos no teste). Os soaks **só imprimem**: vida de 7 dias `af5bdb5e1f21`, 300 NPCs `52b7851aefc0` e 30 dias `82f81b239759` (os mesmos da parada, repetidos na árvore final).
- **Fixture:** `test_save_codec.gd` 12/12, rodado primeiro; `tests/fixtures`, `data/`, `project.godot` e os arquivos protegidos ficaram intactos.
- **Tamanho (DEC-126):** 132 linhas de código e teste (teto ~300), em **9 arquivos de código e teste** (o módulo, `game_modules.gd`, o `check_architecture`, o teste dele, o teste novo, o oráculo e as três listas): **acima de ~8, mas dentro da tolerância de 1,5×** (até ~12).
- **Aceite:** cumprido nos três pontos do roadmap: a regra reprova nos dois sentidos (positivo e negativo), o `check_all` está verde e os valores novos foram aprovados por você; o relatório mostra o `run_sim` antes e depois.

## 7. PROBLEMAS ENCONTRADOS
- **As três frases desatualizadas foram corrigidas depois, com o seu "Autorizo as três" (10:30 a 10:38), mas ainda SEM commit** (veja "Atualização" no fim): (C) a linha "Estado" do `docs/modules/economy.md` (a Fase 3 está em andamento e só a casca da economia, LW-088a, está IMPLEMENTADA, no ramo, fora do `main`); (D) o `README.md`: **achei a mesma contagem em dois lugares**, a linha 9 e a linha 170 (parágrafo da Fase 2), e corrigi as duas (87 de 192, 45,3% → 88 de 192, 45,8%, contando a LW-087); (E) `docs/modules/app.md`, linha 12 (`GameModules` agora lista `character`, `economy` e `npc`, na ordem, e o resultado traz os três). A linha 170 do README é a única coisa além do que eu tinha listado.
- O ruído esperado do `check_all` continua: "Decompression failed" e o aviso de `wait_frames` do GUT (não são meus).
- Uma prova de causa que descartei por erro meu: a primeira tentativa não deixava o carregamento aceitar a falta do bloco, e três fases do oráculo divergiram por culpa do remendo; a segunda, completa, fez os nove valores voltarem (2/2).

## 8. RISCOS
- **A LW-088 em diante:** o bloco `economy` ganha conteúdo; `on_load` hoje recusa tudo que não for vazio, então a LW-088 precisa trocar essa regra (e o teste `test_economy_module.gd`, que a prova) junto com o estado novo.
- O marco 1 vale até a LW-092: dali em diante só se **registram** os valores novos no relatório; da LW-093 começa o marco 2 e a primeira mudança volta a **parar** (DEC-175).
- Os soaks de 7 e 30 dias e o de 300 NPCs não guardam valor fixo; só o oráculo trava os hashes.
- A Fase B da LW-088a **só depois** da aprovação do bloco inteiro (LW-088a a LW-092), como você mandou.

## 9. PENDÊNCIAS
- **A sua auditoria** do ramo `lw-088a-registro-economy` (`d1caae0`).
- **Preciso de você: autorizar o commit e o push do ramo `lw-088a-registro-economy` com as três frases.** A sua autorização da sequência dizia "1 commit" para a Parte 3 e eu já o usei; o "Autorizo as três" cobre as edições, e eu não quis presumir o commit. **Recomendo** um segundo commit no mesmo ramo, "LW-088a: atualiza três frases de documentação (economy.md, README e app.md)", e o push só do ramo. Ressalva: a correção do `README.md` (87 → 88) trata do estado do `main` (a LW-087), mas só chegaria ao `main` com a Fase B da LW-088a; se preferir que ela entre antes, diga e eu a faço num commit à parte no `main`, só com a sua autorização.
- **Teste manual:** nenhum.

## ACOMPANHAMENTO
- **Avanço:** Fase 3 = 1 de 30 (3,3%); projeto = 88 de 192 (45,8%). A LW-088a é subtarefa e não entra na conta.
- **Próxima tarefa recomendada:** a sua auditoria; depois a LW-088 (`Ledger`). **Não iniciada.**
- **Decisões que dependem de você:** autorizar o commit e o push do ramo com as três frases (pendência acima).
- **Git:** `main` = `9b4f6f0` (não tocado na Parte 3). Ramo `lw-088a-registro-economy` = `d1caae0`, **empurrado só ele** e o `status-a`; um commit ("LW-088a: registro do módulo economy e regra de arquitetura"). Sem tag, sem `--force`; nenhum Godot meu em execução.

## ATUALIZAÇÃO (11/11/2026 10:39): as três frases de documentação (C, D e E) que você autorizou
- **O que mudou, sem commit, no diretório do ramo `lw-088a-registro-economy`** (em cima de `d1caae0`): `docs/modules/economy.md` (linha 3, "Estado"), `README.md` (linhas 9 e 170: 87 → 88 de 192 e 45,3% → 45,8%, contando a LW-087, a primeira da Fase 3) e `docs/modules/app.md` (linha 12: a lista do `GameModules` e o resultado com `character`, `economy` e `npc`). Só texto: 3 arquivos, 4 linhas.
- **`tools/check_all` na árvore com as quatro edições (10:34:32 a 10:38:00): VERDE** (`EXIT_CODE_CHECK_ALL=0`): 126 scripts, 1.208 testes, 262.153 asserts, 316 scripts sem aviso, 0 "SCRIPT ERROR"; as linhas com hash (oráculo, vida de 7 dias e 300 NPCs) **idênticas** às do `check_all` anterior. Uma rodada anterior (10:30 a 10:34), com só as três frases, também ficou verde.
- **Mensagem de commit sugerida:** "LW-088a: atualiza três frases de documentação (economy.md, README e app.md)". **Arquivos:** `README.md`, `docs/modules/app.md`, `docs/modules/economy.md`.
- **Git:** nada commitado nem empurrado por esta atualização; o ramo segue em `d1caae0`; `main` = `9b4f6f0`.
