11/11/2026 16:06 (Brasília) — FASE B da LW-146f PARCIAL CONCLUÍDA: `main` agora em `20a788f` (avanço rápido, sem tag); `check_all` verde (1203 de 1203); EM CURSO: as revisões R1 (economia da A, parte 2) e R2 (contratos da C), só leitura; a 146g só depois da LW-117 no `main` e do seu "vá".

# RELATÓRIO — LW-146a a LW-146e: registro das decisões da Fase 5 e contratos novos     Status: PRONTA PARA REVISÃO

**Antes de começar (AGENTS 2.3).** Declarei no chat: a tarefa; o que li (o ADENDO 2 do relatório anterior, que são as **suas** decisões, e a seção 6 do `0014`, ramo `lw-146-prevoo-fase-5`, `8a64980`); as DEC de que dependo e o status de cada; os arquivos; e que **não faria a Fase B**. Nenhuma DEC PENDENTE bloqueava, e nenhuma resposta sua contrariou uma DEC APROVADA (por isso não parei para perguntar).

## 1. RESUMO

As suas respostas do painel viraram **23 decisões no `DECISIONS.md`** (nove APROVADAS, 14 PROPOSTAS) e o roadmap e o escopo do protótipo foram alinhados a elas (146a). Depois escrevi, **só em texto**, os contratos que a Fase 5 pede: combate (146b), personagem (146c), ecologia e eventos dinâmicos (146d) e ponte, câmera e interface, e save (146e). Nada de código, dados, evento catalogado, GDD, arquitetura, AGENTS ou `project.godot` mudou, e **nenhum** dos arquivos que você proibiu foi tocado (confirmado pela lista de arquivos abaixo). Onde ninguém decidiu o jogo, **escrevi "EM ABERTO" com uma recomendação** em vez de inventar.

| Parte | Ramo (em cima do anterior) | Commit | Arquivos | Linhas | `check_all` |
|---|---|---|---|---|---|
| 146a registro | `lw-146a-registro-fase-5` | `11e179f` | 4 | +431 −41 | 1203/1203, 172,74 s |
| 146b `combat` | `lw-146b-combate` | `63e41d8` | 1 (novo) | +130 | 1203/1203, 175,43 s |
| 146c `character` | `lw-146c-character` | `3528d09` | 1 | +79 −1 | 1203/1203, 209,875 s |
| 146d ecologia e eventos | `lw-146d-ecologia-eventos` | `c53a079` | 3 (2 novos) | +219 −3 | 1203/1203, 187,507 s |
| 146e ponte, câmera, save | `lw-146e-ponte-camera` | `38e4c7e` | 6 | +85 −8 | 1203/1203, 180,126 s |

No total, contra o `main` (`9b4f6f0`): 11 arquivos, +1.211 −45. A 146a veio de `lw-146-prevoo-fase-5` com `git merge` do `main` (commit `f74db39`, sem rebase).

## 2. ARQUIVOS CRIADOS
- `docs/modules/combat.md` — contrato do combate (146b; 130 linhas).
- `docs/modules/ecology.md` — contrato da ecologia (146d; 108 linhas).
- `docs/modules/dynamic_events.md` — contrato dos eventos de mundo (146d; 108 linhas). **O nome evita colidir** com `docs/events.md` (catálogo de fatos) e com a crônica.
- (`docs/decisions/0014-pre-voo-da-fase-5.md` já era do ramo `lw-146-prevoo-fase-5`; só mudei o campo Status, e ele entra no `main` com a Fase B.)

## 3. ARQUIVOS MODIFICADOS
- **146a:** `docs/DECISIONS.md` (+376: DEC-179 a DEC-201, DEC-065 PENDENTE para APROVADA, notas de 11/11/2026 em DEC-053, 029, 030 e 066 **sem mudar o status**, totais recontados pelo método da LW-087a: APROVADA 130 (20 com ressalva), PROPOSTA 43, PENDENTE 17, DESCARTADA 10, SUBSTITUÍDA 1, total 201; versão 0.11); `docs/DEVELOPMENT_ROADMAP.md` (+76, **só a Fase 5**: tarefas marcadas como decididas e a subseção "Tarefas novas propostas da Fase 5", com 14 tarefas, 6 `[NÚCLEO]` e 8 `[EXTENSÃO]`; **total 192 e Fase 4 intactos**); `docs/ROADMAP_STATUS.md` (só "Itens dentro e fora do protótipo"; nenhuma contagem mudou); `docs/decisions/0014-pre-voo-da-fase-5.md` (só o Status).
- **146c:** `docs/modules/character.md` (+79: seção "Extensão da Fase 5", E1 a E8).
- **146d:** `docs/modules/combat.md` (3 linhas: **corrigi um erro meu da 146b**, ver seção 7).
- **146e:** `docs/modules/bridge.md` (+41, seção nova no fim, B1 a B6), `docs/modules/presentation.md` (+27, a "Extensão da Fase 5" no fim, P1 a P10), `docs/modules/persistence.md` (+16; a nota velha "DEC-084 segue PROPOSTA" estava errada, a DEC-084 é APROVADA; mais a extensão do save), e **três ajustes de consistência** nos meus contratos anteriores: `combat.md` (a frase da fila), `character.md` (`peek_visible`) e `ecology.md` (interruptor de corpos).

## 4. DECISÕES TÉCNICAS (propostas minhas; nenhuma é APROVADA)
1. **`npc` e `ecology` não importam o `combat`** (camada 3 não importa camada 4): publicam a **intenção de ataque por evento** e o `combat` escuta (DEC-199). O `combat` pode consultar `ecology/api`.
2. **Eventos dinâmicos: os efeitos chegam por uma interface injetada (`EffectPort`)**, com adaptadores finos em `src/app/`. Alternativas: (B) o `events` importa as `api` de todos (alerta de acoplamento do AGENTS 5.2.4: passa de 3 módulos); (C) cada módulo escuta o evento e aplica o próprio efeito. **Vocabulário fechado** de efeitos, porque o AGENTS 4.17 proíbe chamar comando "pelo nome escrito no dado". Recomendo A.
3. **Ponte: o ataque é repasse direto** (como `request_converse`), não a fila `submit_intent`. Motivo: o passo da simulação é de 1 minuto de jogo (1,25 s reais a 1x); uma fila consumida só nele atrasaria um golpe rápido em até 1,25 s. Alternativa: fila com teto **[HIP]**, consumida a cada passo do combate.
4. **Mapa sem regra na ponte:** `character.peek_visible(actor_id, type_id, entity_id)` diz se algo aparece; a ponte só aplica a resposta.
5. **Dados em tabelas planas** (o módulo `data` não aceita lista aninhada): três tabelas para os eventos (`events.json`, `event_effects.json`, `event_params.json`); o nome `events.json` é o da arquitetura.
6. **Save:** nada muda no codec nem no formato; o save de uma fase anterior é reconhecido porque falta o bloco de um módulo, e a mensagem diz o que fazer. Recomendo reaproveitar `SAVE_INVALID_PAYLOAD`.

**PROPOSTA DE DESVIO (AGENTS 16.3) — a arquitetura 17.6 e 17.7 contra o que escrevi.** *Regra afetada:* 17.7 diz "demais módulos só por eventos" e 17.6 diz que o comando do jogador "entra no início do próximo tick". *Problema real:* a DEC-197 e a LW-162 pedem efeitos por comandos públicos; o passo de 1 minuto é lento para combate. *Opções:* seguir a arquitetura à risca (efeitos por evento e ataque em fila) ou os itens 2 e 3 acima. *Recomendação:* itens 2 e 3. *Impacto:* só contratos; reversível; **a arquitetura não foi editada** (é protegida).

## 5. TESTES EXECUTADOS
- `git diff --check` em cada parte (`f74db39..11e179f`, `11e179f..63e41d8`, `63e41d8..3528d09`, `3528d09..c53a079`, `c53a079..38e4c7e`) — **limpo nas cinco** (saída 0).
- `tools/check_all`, no HEAD de cada parte, **um de cada vez**, em worktree separado: **VERDE nas cinco**. Números reais: `Tests 1203`, `Passing Tests 1203`; `Asserts 262120` (conferido nas partes c, d e e); tempos da tabela acima. Em cada execução apareceram as linhas `Warnings 1` e `Deprecated 1`; são **iguais em todas**, inclusive na 146a, e não vêm de documento (não investiguei a origem: fora do escopo).
- Nenhum teste foi removido, enfraquecido ou pulado. **NÃO EXECUTADO:** nada de jogo (não há código). **Observação:** na 146c o relógio do script marcou 72 min entre início (11:08) e fim (12:20), mas o tempo do teste em si foi de 209,875 s; não investiguei o intervalo (provável espera do Mac).

## 6. RESULTADOS
Critério de aceite (documentos): as respostas do painel estão registradas, os cinco contratos existem, cada arquivo tem até cerca de 130 linhas (limite 300), o `check_all` está verde e os arquivos proibidos **não** foram tocados (`git diff --name-only origin/main..38e4c7e`: DECISIONS, DEVELOPMENT_ROADMAP, ROADMAP_STATUS, `0014`, bridge, character, combat, dynamic_events, ecology, persistence, presentation). Sei porque conferi a lista de arquivos e rodei os comandos acima.

## 7. PROBLEMAS ENCONTRADOS (nada omitido)
1. **Erro meu, achado na 146d:** a 146b dizia que a `ecology` importa o `combat`, o que fere as camadas. Corrigi no `combat.md` (em 146d, 3 linhas) e na 146e. **Avisei aqui como manda o AGENTS 13.2.6.**
2. **Buraco de tempo no combate:** o combate do SP6 corre em milissegundos e a simulação avança em passos de 1 minuto de jogo. Nenhum documento diz quem avança o relógio do encontro. Proposta: `request_advance_encounters(dt_ms)`, chamado pelo anfitrião em passos fixos de 50 ms **[HIP]** (o `SimulationHost` não foi editado).
3. **Arco contra a DEC-192:** a LW-154 fala em projétil físico que acerta (contato), mas a DEC-192 manda **intenção sem contato**. Ou o arco é uma habilidade à distância por alvo, ou volta o contato.
4. **Cadência de decisão do NPC e da criatura em combate:** hoje o `npc` pensa em minutos; "reagir em tempo real" exige passo mais curto. Extensão do `npc`.
5. **A arquitetura 17.7 e a DEC-197 divergem** (seção 4, desvio).
6. **Nenhum caminho para vender item único a mercado:** a `economy` só negocia bens em quantidade; sem isso o contrabando por marca de origem não tem onde acontecer.
7. **Os comandos que "parecem servir" a um evento são só de desenvolvimento** (`request_set_stock`, `request_raise_alarm`, `request_record_memory`, `request_adjust_relation`): todo efeito é extensão de contrato.
8. **Fase 4 ainda não existe no `main`:** quatro dos 8 tipos de evento dependem de comandos de `politics`, `factions` e rumores **que não li** (marquei "a confirmar").
9. **A LW-142 (Fase 4)** manda migrar o save da Fase 3, o que contraria a DEC-186 e a DEC-134 (a DEC-186 já registra isso). **Não toquei a Fase 4.**
10. **Linhas antigas do `DECISIONS.md` que podem ter ficado desatualizadas e que não alterei:** §3.3 (a linha "Morte, ferimentos e derrota" ainda aponta a LW-146 como quem decide) e §4.1 (a situação "Aberta" de C2, trajetórias, e de C6, lista de corte, que as DEC-180 e DEC-179 resolveram). A LW-146a só mandava mudar o status da DEC-065 e acrescentar notas (no §5.2 e no §6.1 pus uma nota de acréscimo). Proponho uma tarefa de limpeza.
11. **O ramo local da 146 tem upstream no `main`:** por isso todos os pushes foram com `ramo:ramo` explícito (nunca `git push` sem argumento).

## 8. RISCOS
- Os cinco ramos estão **empilhados**: a Fase B os leva ao `main` **em ordem**. Outras conversas editam `DECISIONS.md` e o roadmap; pode haver conflito de merge, que se resolve na Fase B.
- Nada de código foi construído sobre estes contratos; **quase tudo é PROPOSTA** e Arthur pode trocar. Os números são **[HIP]**.
- Acoplamentos observados: o `events` (se escolher a opção B) importaria mais de 3 módulos; o construtor da ponte já tem 4 parâmetros opcionais e passa a 6 (proposta futura: um objeto `BridgeModules`).

## 9. PENDÊNCIAS
**Decisões suas (com a minha recomendação).** *Jogo:*
- **Quem ataca quem** (`ecology`): guardião e predador hostis ao jogador e a NPCs; presa não ataca ninguém e foge. Predador também caça a presa.
- **Covil sem criaturas repovoa com o tempo?** Recomendo que sim (a exploração não se esgota).
- **O que a ruína dá além do conhecimento:** recomendo só conhecimento no protótipo (nenhum documento descreve mais).
- **O que o mapa de perigo mostra:** a zona de ameaça por província e os covis descobertos; nunca criaturas soltas.
- **Efeito do "ferido" no combate:** recomendo o menor possível (menos estamina máxima).
- **Ao morrer (modo "renasce perto"):** o **dinheiro** não cai; renasce com a vida **cheia** (o custo já é perder os itens soltos); "itens de missão" = nenhum no protótipo (o roteiro não tem missões); o modo **não muda** depois de escolhido.
- **Os 8 tipos de evento** (genéricos, seção 5 de `dynamic_events.md`): aprovar, trocar ou cortar. **Diretor de eventos** (DEC-069): recomendo sem diretor.
- **Autosave:** slot separado com rotação; intervalo em dados, que você ajusta jogando.
- **O que o jogador vê dos eventos:** a crônica não filtra e a ponte decide pelo que ele presenciou.
- **Teste de tropas (SP9):** quais ordens e quantos soldados (a visão de Bannerlord e Total War é só referência).

*Técnicas:* ponte com repasse direto (recomendo); eventos por `EffectPort` (recomendo A); relógio do encontro pelo anfitrião; arco como habilidade à distância por alvo; **peso**: quem recusa por excesso (recomendo interface injetada no `character`); orçamento de corpóreos único (criaturas incluídas); rejeição do save com o código existente.

**Extensões pendentes ("146f", depois da LW-117; NÃO feitas aqui, texto proposto):**
- `economy.md`: tipo de dono "monte no chão" (bens que caem na morte, DEC-188); **motivo fechado novo** para destruir o metal ao forjar, mais o evento (nome na 146f); `request_apply_production_modifier(settlement_id, good_id, permille, ends_at)` e o desfazer (evento `poor_harvest`); caminho de **venda de instância**.
- `npc.md`: evento de promoção e de rebaixamento (o `character` precisa ouvir); evento de **intenção de ataque** (`attacker_id`, `target_id`, `skill_id`), compartilhado com a `ecology`; cadência de decisão em combate; memória de testemunha ao ouvir `ItemDropped` e `ItemTaken`; NPC pega item; `request_apply_need_pressure` e (Fase 4) `request_seed_rumor`.
- `world.md`: ponto de renascimento; tipos novos de ponto (`ruin`, `lair`, `camp`, `outpost`, `lookout`) com campos opcionais (`province_id`, `faction_id`, `radius_m`, `secret`); liberar `request_close_route` e `request_open_route` ao jogo com `cause_id`.
- `docs/events.md`: `CombatantWounded`, `CombatantDied`, `CombatEnded`, o de intenção, `ItemDropped`, `ItemTaken`, `ItemBroken`, `PlayerDefeated`, `WorldEventStarted`, `WorldEventEnded` (e os da economia e do `npc` acima).
- `app.md` (não estava na sua lista): anfitrião avança o relógio do encontro; autosave por tempo; carga pela derrota; salvar e carregar orquestrados.
- Fase 4: `military` pede encontro e ouve baixas; `politics` ou `events` ficam com a lista de atos em `laws.json` (agressão, roubo, morte e contrabando, DEC-195); comandos de estabilidade e de tensão.

**Testes manuais:** nenhum (só texto). Se quiser ler pouco: `combat.md` (seções 3, 8 e 9), `ecology.md` (seções 2 e 3), `dynamic_events.md` (seções 4 e 5) e esta seção.

## ACOMPANHAMENTO
- **Avanço:** o pré-voo e os contratos da Fase 5 estão escritos; falta a Fase B (levar ao `main`) e a 146f (extensões dos outros módulos, depois da LW-117). Código da Fase 5: **0%**.
- **Próxima tarefa recomendada:** a **Fase B**, só com a sua frase **"APROVADO LW-146a a LW-146e"**; depois a 146f, quando a LW-117 estiver pronta. **Não iniciada.**
- **Git:** 5 commits, um por parte, todos com `Co-Authored-By`, em 5 ramos empilhados, **enviados** por `ramo:ramo` (`11e179f`, `63e41d8`, `3528d09`, `c53a079`, `38e4c7e`). **Nada no `main`, nenhuma tag, sem force, rebase ou reset.** Mensagens: "LW-146a: registro das decisões de jogo da Fase 5 (DEC-179 a DEC-201), roadmap e escopo"; "LW-146b: contrato do combat ..."; "LW-146c: extensão do contrato do character ..."; "LW-146d: contratos novos da ecologia e dos eventos dinâmicos"; "LW-146e: extensões da ponte, da câmera e interface e do save (Fase 5)".


## FASE B — LW-146a a LW-146e no `main` (11/11/2026, autorizada por escrito por Arthur)

**Efeito:** o `main` agora tem as 23 decisões da Fase 5 (DEC-179 a DEC-201), o roadmap e o escopo alinhados, o `0014` e os contratos novos e ampliados (`combat`, `ecology`, `dynamic_events`, `character`, `bridge`, `presentation`, `persistence`). Só documentos; nenhum código mudou.

**Passos, com o que vi:**
- **B0:** `git fetch`; `origin/main` seguia em `9b4f6f0` (como você previa). Nada a relatar.
- **B1:** conferi que `origin/lw-146e-ponte-camera` (`38e4c7e`) **contém os cinco ramos** (`lw-146-prevoo-fase-5`, 146a, 146b, 146c e 146d são todos ancestrais dele) e **descende de `origin/main`**. Fiz **um** commit, `ffb1e03` ("LW-146: Fase B, correção do Status do 0014 e linha de entrada no ROADMAP_STATUS"), só com: (a) a frase do Status do `0014` que se contradizia ("as respostas estão em `DECISIONS.md`" contra "as respostas ainda **não** estão em `DECISIONS.md`") agora diz que **estão** registradas (DEC-179 a DEC-201, LW-146a); (b) **uma linha** nova no fim de "Itens dentro e fora do protótipo" do `docs/ROADMAP_STATUS.md`, dizendo que a LW-146a a LW-146e entraram no `main` e que **não alteram contagens nem porcentagens** (não toquei em 88/192 nem no percentual de fase). O `git diff --staged` foi mostrado antes do commit: 2 arquivos, +3 −1; `git diff --check` limpo. Nenhum outro arquivo.
- **B2:** `tools/check_all` **uma vez**, no commit final `ffb1e03`: **VERDE**. `Tests 1203`, `Passing Tests 1203`, `Asserts 262120`, `Time 186,209 s` (início 13:03:38, fim 13:07:22). As linhas `Warnings 1` e `Deprecated 1` são as mesmas de todas as execuções anteriores.
- **B3:** `git fetch` de novo: `origin/main` ainda em `9b4f6f0` e fast-forward possível. Push: `lw-146e-ponte-camera:lw-146e-ponte-camera` (`38e4c7e..ffb1e03`) e `lw-146e-ponte-camera:main` (`9b4f6f0..ffb1e03`), **na primeira tentativa**, sem corrida. Conferi depois: `origin/main` = `ffb1e03`. **Tags:** nenhuma nova (as remotas continuam `fase-0-concluida`, `fase-1-concluida` e `fase-2-concluida`).

**Não fiz (proibido ou fora do escopo):** `--force`, rebase, reset, stash, tag, apagar ramo; DECISIONS, GDD, arquitetura, AGENTS, roadmap (`DEVELOPMENT_ROADMAP.md`), `project.godot`, `.gitignore`, `data/`, `addons/`, fixtures e os módulos `economy`, `npc`, `world`, `events`, `factions`, `politics`, `military`, `chronicle`. **A 146f não foi feita.**

**Git:** commit `ffb1e03` (um commit, com `Co-Authored-By`). Os cinco ramos antigos ficaram no GitHub como estavam (não apaguei nenhum; agora estão todos dentro do `main`).


## REVISÃO INDEPENDENTE DA A (11/11/2026, papel de revisor, AGENTS seção 11; somente leitura)

**Em uma frase:** não achei nada que impeça a A de seguir; o coração (Ledger, inventário, fórmulas de preço) está correto no que li e bate com o contrato; os cinco pontos importantes são de **fronteira, de regra de arquitetura e de itens que o AGENTS pede**, e nenhum deles muda o resultado do jogo hoje.

**Alvo e método.** Ramos `origin/...` na ordem (cada um é avanço direto do anterior, conferido): `lw-088a-registro-economy` (`26384ee`), `lw-088b-ledger` (`c9a7e0f`), `lw-088c-porta-e-regra-f` (`5bc5cef`), `lw-089-bens-e-dados` (`370eda2`), `lw-089b-inventario` (`e28de7d`), `lw-089c-porta-dos-bens` (`d42a483`) e `lw-090-precos` (`85ac0bf`), a partir de `9b4f6f0`. Usei só `git fetch`, `show`, `diff`, `log` e `grep` sobre os refs. Sem checkout, sem worktree, **não rodei nenhum teste**. Linhas citadas são do arquivo **na ponta (`lw-090-precos`)**, salvo onde disser outra coisa. Comparei com `docs/modules/economy.md` (seções 1 a 4 e 10), arquitetura cap. 11, `DECISIONS.md` (DEC-126, 127, 132, 146, 171, 172, 175: todas APROVADAS) e AGENTS 4, 5, 6, 9, 12 e 13.

### BLOQUEANTES
Nenhum.

### IMPORTANTES
- **I1. O `EconomyModule` não tem `debug_summary()`.** AGENTS 4.15 e 11 exigem `serialize`, `on_load`, `validate` **e** `debug_summary` para estado novo, e o contrato (`economy.md:25`) o lista no ciclo de vida. O módulo ganhou estado na 088b (donos, saldos, bens), mas `grep debug_summary src/sim/economy` não acha nada: `economy_module.gd:97-105` termina em `validate` e vale o padrão do `SimModule` (devolve `{}`). Efeito: o painel de depuração mostra a economia vazia mesmo com contas e bens. Sugestão: nº de donos, soma dos saldos, criado, destruído e se a conservação fecha.
- **I2. A regra E é estreita demais para a promessa "só a porta (`api`)".** `tools/check_architecture:163-166` só cobre `npc` para `economy` e `economy` para `npc`; a regra D (linha ~160) só a ponte e `tools`; a regra A deixa passar camada igual ou menor. Logo, `character`, `ecology` e, na Fase 4, `factions`, `politics`, `military` e `combat` **podem citar** `Ledger`, `OwnerBook`, `GoodsStore` e `GoodsLoader` sem nenhuma regra reclamar. Isso também esvazia a regra F (só o Ledger escreve saldo). **Sobre a pergunta "a 089c enfraqueceu a E?": não.** O afinamento (tirar o texto entre aspas antes de procurar, `check_architecture:156`) está correto, e os 4 casos novos do `test_check_architecture.sh` (2 limpos, 2 violações) provam que o identificador fora das aspas continua pego. O problema é o **alcance** da regra, que já era assim desde a 088a. Recomendo generalizar: "arquivo fora de `src/sim/economy/` só cita classes de `economy/api/`".
- **I3. Save e `validate()` não conferem o tipo do dono contra `owner_kinds`.** `request_open_owner` confere (`economy_module.gd:108-116`), mas `on_load` (`:60-94`) e `OwnerBook.load_from`/`validate` (`owner_book.gd:75-103`) só exigem texto não vazio. Um save com `"kind": "wizard"` carrega e passa no `validate()` se o dono não tem bens (com bens só falha por acaso, por peso, porque `capacity_of` dá 0). AGENTS 12.6 manda validar referências. Falta o teste.
- **I4. O fechamento do dono lê o evento por nome e por reflexão.** `economy_module.gd:15` e `:40` assinam `"NpcDied"` em texto e `:151` lê `event.get("npc_id")` (`Object.get` por nome). O AGENTS 4.17 proíbe reflexão (DEC-107, descarte **proposto**), e renomear o evento ou o campo quebra o fechamento **sem erro de compilação nem de arquitetura**. Mitigação boa que existe: o teste usa o `NpcDied` **real** (`test_economy_goods_api.gd:106-110`). Há uma tensão real entre a DEC-132 (a economia nunca importa o `npc`) e o AGENTS 4.17, que pede **uma decisão** (por exemplo, classes de evento num lugar que a economia possa citar, ou registrar este canal como o sancionado). `docs/events.md:13` ainda diz "nenhum hoje (ninguém assina o evento)".
- **I5. A regra F tem furos que o próprio teste aceita.** `check_architecture:170` só reprova `+=`, `-=`, `*=`, `/=`, `x.balance =` / `x.money =` e `balances[id] =`. **Passam:** `balance = 5`, `money = 5`, `_balances = {}` (o teste `test_check_architecture.sh:198-200` marca `balance = owner_balance` como "limpo", de propósito, por causa da classe de resposta), `ledger._set_balance(...)` e `ledger._balances.erase(...)`. O `[LIM]` está declarado (`:105-107`) e a defesa de fundo é o teste de ouro, então **não é bloqueante**; fica importante por somar com I2.

### MENORES
- **M1. Tamanho (DEC-126; conto só código e teste, sem comentário, linha em branco, `.uid`, documento e `.json`):** 088a 132 linhas (9 arquivos), **088b 311**, **088c 420 (11 arquivos)**, 089 217, **089b 421**, 089c 206, **090 348**. A tolerância é ~450: **nenhuma passa**, mas 088b, 088c, 089b e 090 passam do teto de 300. A contagem **bruta** do `git diff --stat` (088c +561, 089b +529) passa de 450, porque inclui comentário e linha em branco. A 088c mistura três assuntos (save do Ledger, porta, regra F) e ainda move o módulo para `api/`.
- **M2. `OwnerBook.open_owner` aceita reabrir com outro tipo e ignora** (`owner_book.gd:43-46`): esconde um erro de quem chama.
- **M3. Os motivos do Ledger não são ligados à operação** (`ledger.gd:14-15`, `:206`): `mint(..., "trade")` e `burn(..., "salary")` passam, e o teste aleatório sorteia qualquer motivo. Além disso, o motivo inválido devolve `ECON_DATA_INVALID` (`:207`), que não está na lista de códigos do contrato (`economy.md` seção 2).
- **M4. `load_from` ignora chaves desconhecidas** dentro de `ledger` (`ledger.gd:156-188`), de `goods` (`goods_store.gd:154-174`) e de cada dono (`owner_book.gd:84-90`), enquanto o bloco `economy` as recusa (`economy_module.gd:68-70`). Inconsistente.
- **M5. Totais de bens sem teto de 2^53 − 1** (`goods_store.gd:234-237`), ao contrário do Ledger (`ledger.gd:51, 69, 88`). Só teórico, mas um total grande demais perderia o save.
- **M6. `Variant` sem comentário de justificativa** (AGENTS 4.2): `ledger.gd:160-166` e `goods_loader.gd:64`. Os outros têm.
- **M7. `validate()` percorre `Dictionary` na ordem natural** (`ledger.gd:193-197`, `goods_store.gd:179-183`): só a ordem das **mensagens** muda depois de carregar, não o estado. Regra do `MODELO.md`.
- **M8. `quote_buy` e `quote_sell` custam O(quantidade)** (`price_math.gd:65-77`) e `max_order_quantity` aceita até 1.000.000.000 (`market_loader.gd:33`): dado ruim vira laço enorme. Sugestão: faixa menor.
- **M9. Documentos desatualizados:** `economy.md:37` ainda põe o módulo na raiz e diz "`api/` vazia" (a 088c o moveu para `api/`); `docs/events.md:13` (I4).
- **M10. Truque em `GoodsStore.transfer`:** `_check(..., "", [""])` (`goods_store.gd:94`) para fingir um motivo vazio; um `_check` sem motivo seria mais claro.
- **M11. Código sem uso fora de teste:** o jogo real faz `EconomyModule.new()` **sem definições** (`src/app/game_modules.gd:40`), então hoje qualquer tipo de dono é aceito e nenhum bem existe; `GoodsLoader` e `MarketLoader` só rodam em teste, e o `tools/validate_data` não cobre `data/economy`. É o esperado até a ligação (LW-090c e LW-093), mas fica anotado.
- **M12. Cobertura:** o teste aleatório do inventário só usa os motivos `produced` e `maintenance` (`test_goods_inventory.gd:113-155`; `game_start`, `consumed` e `spoiled` só nos testes escritos à mão) e `test_price_math.gd` não testa os limites de estouro. Pela minha conta (valor-base até 1e9 vezes fator até 1e5, e preço vezes fator até ~1e15) **cabe** em 2^53, mas nada prova.
- **M13. `request_transfer_goods` aceita qualquer `from_id` de qualquer chamador** (`economy_module.gd:120-121`): sem checagem de quem pede. Cabe às LW-091 e LW-105 decidir.
- **M14. Pasta `owners/` e arquivos soltos** (`economy_json.gd`, `economy_definitions.gd`) fora da estrutura da arquitetura 11.1. Observação; não é pasta de topo, então não fere o AGENTS 5.7.
- **M15. Os números de `owner_kinds.json` e `price_params.json` são [HIP]** e estão em dados (bom); a calibração é da LW-112.

### O que conferi e está certo
Camadas: a economia **não** cita `npc`, `world`, `character` nem nada de camada acima (grep). Dinheiro e quantidades só em inteiro; nenhum `Time.`, `OS.`, `randf`, `randi`, `await`, `@warning_ignore` nem `print` em `src/sim/economy`; `float` só dentro de `EconomyJson` para conferir número de JSON. Tudo tipado. Falha devolve `Result` e **não muda nada**, com teste. O teste de ouro roda a cada operação contra um **modelo escrito à parte** (6.000 operações no Ledger; o do inventário também), com semente e fluxo nomeado do `core`. As fórmulas de `PriceMath` batem **linha a linha** com a seção 4 do contrato (piso, teto, fator, suavização mínima de 1 sem passar do alvo, `P(s)`, margem por `ceil_div`, `bid ≥ 1`), e as invariantes (i) a (v) têm teste. Save: ida e volta pelo JSON, recusa de dado inválido deixando o estado como estava, e a ordem dos módulos no `World` (economia antes do `npc`).

**Fixtures, hash e oráculo (o que você pediu):** `tests/fixtures`, `project.godot`, `.gitignore`, `addons`, `AGENTS.md`, GDD, arquitetura, `DECISIONS.md` e roadmap **não foram tocados** em nenhuma das sete partes. O **oráculo** mudou só na **088a**: os 9 hashes de `test_npc_split_oracle.gd` (marco 1, DEC-175 APROVADA; o relatório da A registra o seu "Aprovo os dois" e a fixture `save_v1` não foi tocada). Nas outras seis partes não há hash novo. A 088a também editou, de forma mecânica e sem enfraquecer, três testes existentes (`test_npc_state`, `test_settlements`, `test_sim_bridge_character`) só para incluir `economy` na lista de módulos. **Conflito com o `main` atual:** nenhum arquivo em comum entre a A e o que entrou depois de `9b4f6f0` (só conferi a lista de arquivos).

### O QUE NÃO CONSEGUI VERIFICAR
- **Execução:** não rodei `check_all`, nenhum teste nem o `tools/check_architecture`; não confirmo que estão verdes (o `STATUS-A.md` afirma 1.237 testes verdes na 089c; da 090 não li o resultado) e não conferi os valores dos 9 hashes novos nem a frase "só o bloco vazio mudou os nove".
- **Regra E e F:** li o `awk` e os casos de teste, mas **não os exercitei** com entradas reais; os furos de I5 vêm da leitura das expressões.
- **Testes lidos por inteiro:** `test_price_math`, `test_economy_goods_api`, a parte do hash do `test_economy_module`, o teste aleatório do `test_ledger` e a segunda metade do `test_goods_inventory`. **Só li os nomes** de `test_ledger_save`, `test_economy_api`, `test_goods_data`, `test_market_data` e da primeira metade dos outros.
- **Referências:** não reli o GDD 12 e 13 nesta revisão (usei o `economy.md`, que os cita); da arquitetura li o cap. 11 inteiro. Não li o código das LW-090b e LW-093b (fora do alvo).
- **Merge:** não simulei o merge com o `main` (só comparei listas de arquivos).
- **Comportamento do Godot** (por exemplo, `Object.get` devolver `null` para propriedade que não existe) vem do que sei da API, sem teste aqui.


## LW-146f (PARCIAL) — extensões de `world`, `npc`, `app` e do catálogo de eventos     Status: PRONTA PARA REVISÃO (a parte `economy` e a da Fase 4 NÃO foram feitas, de propósito)

**Antes de começar (AGENTS 2.3).** Declarei no chat a tarefa, o que ia ler, que a LW-117 **não** está no `main` (só a 117a e a 117b, fora dele) e que a 117b e a conversa A mexem no `economy.md`. Você respondeu pelo painel: **"Parcial agora"** (só o que não depende da Fase 4 nem do `economy.md`) e **"Autorizo o ramo e o commit"** (ramo `lw-146f-extensoes` a partir de `origin/main`, um commit, push só desse ramo e do `status-b`; sem merge no `main`, sem tag, sem force, sem rebase). As DEC de que dependo e o status de cada: **APROVADAS** DEC-181, DEC-184 e DEC-140; **PROPOSTAS** (padrão de trabalho, não decididas) DEC-199, DEC-197, DEC-189 e DEC-193. Nenhuma é PENDENTE, então nenhuma bloqueia.

### 1. RESUMO
Escrevi, **só em texto**, as extensões que os contratos novos da 146b a e pediam aos outros módulos, na parte que **não depende** da Fase 4 nem da `economy`: **`world.md`** (tipos novos de ponto, `peek_nearest_point`, `peek_points_within`, ponto de renascimento e `request_set_route_state` para o evento de rota), **`npc.md`** (seção 15: evento de promoção, decisão e intenção de combate, testemunha de item no chão e `request_apply_need_pressure`), **`app.md`** (relógio do encontro, módulos novos, salvar e carregar, carga pela derrota, adaptadores de efeito e ações de entrada) e **`docs/events.md`** (11 eventos novos, de 16 para **27**). Nada de código, dados, GDD, arquitetura, AGENTS, DECISIONS, roadmap nem `project.godot`.

### 2. ARQUIVOS CRIADOS
Nenhum.

### 3. ARQUIVOS MODIFICADOS (4; +71 −6; commit `961d2c4`)
- `docs/modules/world.md` (+19): seção "Extensão da Fase 5".
- `docs/modules/npc.md` (+18): seção 15.
- `docs/modules/app.md` (+23): "Extensão da Fase 5" (A1 a A6).
- `docs/events.md` (+17 −3): contagem (27), explicação da coluna "Situação", 11 linhas novas e a nota "Considerados": `NpcTierChanged` **saiu** da lista dos não incluídos (agora tem ouvinte), e entrou uma frase do que fica de fora por ora.

### 4. DECISÕES TÉCNICAS (propostas minhas; nenhuma é APROVADA)
1. **`NpcTierChanged`** (promoção e rebaixamento viram evento): o `character` precisa ouvi-lo para criar o estado de T2 e T3 (DEC-199). Antes não existia por falta de ouvinte.
2. **O mesmo `AttackIntended`** é publicado pelo `npc` e pela `ecology`; o `combat` escuta. O `npc` **não** importa o `combat` nem o `character`.
3. **Cadência de combate:** como o `combat` (camada 4) pode chamar o `npc` e o contrário não, o `combat` entrega uma **cópia da situação** e pede a decisão (`request_think_in_combat`); o `npc` responde publicando o evento.
4. **`world`:** em vez de campo `secret` por ponto, a visibilidade é **por tipo**, no `character` (DEC-184). Para a rota, um comando **novo** (`request_set_route_state`, com motivo de vocabulário fechado) em vez de liberar os de desenvolvimento (DEC-140 intacta).
5. **`app`:** o `SimulationHostNode` avança o relógio do encontro em passos fixos de 50 ms **[HIP]**; os adaptadores de efeito dos eventos moram em `src/app/` e chamam o comando **dentro do tratamento de `WorldEventStarted`**, para o `cause_id` sair certo.

### 5. TESTES EXECUTADOS
- `git diff --check` (staged e no commit): **limpo**.
- `tools/check_all` no commit `961d2c4`: **VERDE**. `Tests 1203`, `Passing Tests 1203`, `Asserts 262120`, `Time 178,743 s` (início 13:50:36, fim 13:54:12). As linhas `Warnings 1` e `Deprecated 1` são as mesmas de todas as execuções anteriores. Contei as linhas de evento do catálogo: **27**, e o teste do catálogo (todo evento do código consta na tabela) passou.
- Nada de jogo foi executado (não há código).

### 6. RESULTADOS
Critério (documentos): as extensões da parte autorizada existem; `events.md` tem 27 eventos; só os quatro arquivos autorizados mudaram (conferi com `git diff --stat origin/main HEAD`); `check_all` verde.

### 7. PROBLEMAS ENCONTRADOS
1. **A LW-117 não está no `main`** e a **117b já acrescenta 116 linhas ao `economy.md`**; por isso **não toquei** no `economy.md` (a A também o edita). Sem os contratos da Fase 4 (`politics`, `factions`, rumores), quatro dos oito tipos de evento seguem **[A CONFIRMAR]**.
2. **Inconsistência minha que deixei:** o `ecology.md` (seção 8) ainda fala em campo `secret` por ponto; o certo agora é a visibilidade por tipo (`world.md`). Não corrigi porque o `ecology.md` não estava nos quatro arquivos autorizados.
3. **A ponte e as views guardam os módulos do jogo antigo** (limitação da LW-070a): carregar um save troca o runner; documentei no `app.md` A4 e recomendei a ponte ler `host.*` a cada chamada.
4. **Hash:** cada módulo novo registrado muda o `state_hash` de todo jogo; pela DEC-175 e pelo AGENTS 9.5 isso exige a sua aprovação. Recomendei marcos por bloco.

### 8. RISCOS
- O ramo `lw-146f-extensoes` tem **upstream no `main`**: nunca usei `git push` sem argumento.
- Conflito de merge possível em `docs/events.md` (a conversa C também cataloga eventos da Fase 4) e em `npc.md` (a Fase 4 pode estender o `npc`); resolve-se no merge.
- Tudo é **PROPOSTA**; nomes e números ([HIP]) trocam sem custo.

### 9. PENDÊNCIAS
**Fica para a 146g, depois da LW-117 chegar ao `main`:** (a) `economy.md`: "monte no chão" como tipo de dono (DEC-188), motivo fechado de destruição do metal e o evento dele (DEC-193), `request_apply_production_modifier` e o desfazer, e a venda de instância; (b) os comandos de `politics`, `factions` e rumores para os 4 tipos de evento que dependem deles; (c) o ajuste do `ecology.md` (`secret`).
**Decisões suas, com a minha recomendação** (as que a 146f abriu): `skill_id` do NPC (recomendo só ataque automático na Fase 5); como o NPC pega **instância** de item (recomendo: o `npc` publica a intenção e o `character` resolve); a velocidade do relógio do encontro (recomendo sempre tempo real); marcos de hash da Fase 5; o tipo `ore_deposit` (só se você quiser minério escondido); segurança do ponto de renascimento (recomendo dentro de povoado).
**Testes manuais:** nenhum (só texto).

### ACOMPANHAMENTO
- **Avanço:** pré-voo e contratos da Fase 5 escritos e no `main` (146a a e); a 146f está **pela metade** (a parte sem `economy` e sem Fase 4, num ramo fora do `main`). Código da Fase 5: **0%**.
- **Próxima tarefa recomendada:** a **Fase B da 146f parcial** (levar o ramo ao `main`, só com a sua frase de aprovação e o passo a passo) e, depois da LW-117, a **146g**. **Não iniciadas.**
- **Git:** 1 commit `961d2c4` ("LW-146f: extensões de world, npc, app e catálogo de eventos para a Fase 5 (parte sem economy nem Fase 4)") com `Co-Authored-By`, no ramo `lw-146f-extensoes`, **enviado** por `ramo:ramo` (a partir de `ffb1e03`). Nada no `main`, nenhuma tag, sem force, rebase ou reset.

## FASE B — LW-146f PARCIAL no `main` (11/11/2026, autorizada por escrito por Arthur: "APROVADO LW-146f (parcial)")

**Efeito:** o `main` agora tem as extensões de `world`, `npc` e `app` e o catálogo de eventos (11 eventos planejados novos, de 16 para 27). Só documentos; nenhum código mudou. **A parte `economy` e a dos comandos da Fase 4 (146g) continua pendente.**

**Passos, com o que vi:**
- **B0:** `git fetch --all --tags --prune`; `origin/main` seguia em `ffb1e03` (a conversa A não levou a economia antes). O ramo `lw-146f-extensoes` (`961d2c4`) descende dele: avanço rápido possível, **sem merge e sem conflito** (o conflito esperado em `docs/events.md` não aconteceu).
- **B1:** um commit, `20a788f` ("LW-146f: Fase B, linha de entrada da parte parcial no ROADMAP_STATUS"), só com `docs/ROADMAP_STATUS.md` (+2 linhas: o parágrafo e a linha em branco antes dele). Ele diz que a 146f parcial entrou no `main` e que a 146g segue pendente; **não altera contagens nem porcentagens**. `git diff --check` limpo. Commit com `Co-Authored-By`.
- **B2:** `tools/check_all` **uma vez**, no commit final `20a788f`: **VERDE**, código de saída 0 ("VERDE: arquitetura, dados e etapa de testes aprovadas."). `Scripts 125`, `Tests 1203`, `Passing Tests 1203`, `Asserts 262120`, `Time 177,037 s` (início 16:00:59, fim 16:04:34). `Warnings 1` e `Deprecated 1` são **idênticos** aos das três execuções anteriores. O `Deprecated` vem de um teste que já existia (`tests/unit/test_app_nodes.gd:78` usa `wait_frames`, que o GUT marca como substituído por `wait_physics_frames`); a origem do `Warnings 1` **não identifiquei**. Nenhum dos dois é desta mudança (só mudaram documentos).
- **B3:** `git fetch` de novo: `origin/main` ainda em `ffb1e03`. Push do ramo `lw-146f-extensoes:lw-146f-extensoes` (`961d2c4..20a788f`) e depois `lw-146f-extensoes:main` (`ffb1e03..20a788f`), **na primeira tentativa**, só avanço rápido, sem `--force`. Conferi depois: `origin/main` = `origin/lw-146f-extensoes` = `20a788f`. **Tags:** nenhuma criada (as remotas continuam `fase-0-concluida`, `fase-1-concluida` e `fase-2-concluida`).

**Não fiz:** `--force`, rebase, reset, stash, tag, apagar ramo; nada em `DECISIONS.md`, GDD, arquitetura, AGENTS, roadmap, `project.godot`, `.gitignore`, `data/`, `addons/`, fixtures nem em módulos. **A 146g não foi iniciada.**

**Git:** o `main` do seu clone principal (`/Users/arthurlk/LivingWorld`) **não foi atualizado por mim** e segue em `ce430cf`: só o remoto avançou. Se quiser, é um `git pull --ff-only` seu lá.
