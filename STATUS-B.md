12/11/2026 10:57 (Brasília) — BLOCO B v8 EM ANDAMENTO, sem BLOQUEADA minha. **A enviou o `lw-096n` (custódia do emissor morto, opção B de Arthur; REVISADO, R28, sem bloqueio): só o teste `test_contract_expiry.gd` foi trocado, como Arthur autorizou, e ficou mais forte; minha verificação do `main` atual + A até 096n: `check_all` VERDE 179 scripts/1.512 testes/298.629 asserts, `run_sim` igual, 30 dias do jogo real idêntico (132 vivos, 0 mortes, 0 `ContractOffered`); R15-I1 RESOLVIDO.** `main` em `4db060f`; A deve juntar `4db060f` e tentar a entrada do conjunto 096h a 096n (item 3) e depois a LW-094; vigia armado desde 10:50 (batimento a conferir). Resumo anterior: BLOCO B v8 EM ANDAMENTO, sem BLOQUEADA minha. **Arthur AUTORIZOU a troca do `test_contract_expiry.gd:113` (item 2 da A, custódia do emissor morto; seção final; a B não repassa à A).** `main` em `4db060f`, nada novo no GitHub desde as 09:57; vigia com batimento 10:37. Resumo anterior: BLOCO B v8 (manhã, limite 13:00) EM ANDAMENTO, sem BLOQUEADA minha. `main` em `4db060f` (LW-118 da C, auditada: SÃ; falha minha de vigia 07:48 a 09:35, auditoria fora do prazo). **A (`status-a` 10:05): 096m pronto (junção com `81ce7f4` e os 2 testes dela consertados; R23-I1 e R24-I1 resolvidos) e 096n (custódia do emissor morto, opção B) PARADO por autorização de 1 teste existente (`test_contract_expiry.gd:113`): itens 3 (entrada 096h a 096n) e 4 (LW-094) não iniciados.** Verificação MINHA do `main` atual + A até 096m (cópia temporária): `check_all` VERDE 178/1.504/298.544, `run_sim` igual, 30 dias do jogo real idêntico (132 vivos, 0 mortes, 0 `ContractOffered`, 0 NPC mudou de posto) e experimento de morte forçada: a vaga nasce e NENHUM NPC de posto a pega (R18-I1 provado no jogo real). Vaga fica aberta 30 dias (R27-M2). Vigia religado 09:57. Autorizações e decisões de Arthur registradas (seções anteriores).

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


## REVISÃO INDEPENDENTE DA A, PARTE 2 (R1) — `lw-090b` a `lw-093a` e `lw-088d` (11/11/2026, papel de revisor, AGENTS seção 11; sem implementar nada)

**Em uma frase:** não achei nada que bloqueie; os quatro itens que você mandou conferir (I1, I2, I3 e I5) **estão resolvidos de verdade**, e o que sobra são três decisões que convém tomar **antes** de o NPC e a Fase 4 começarem a usar a economia (a decisão do I4, a fórmula da tarifa e o `peek_quote` sem ator).

**Alvo e método.** Ramos `origin/...`, cada um avanço direto do anterior: `lw-090b-estado-do-mercado` (`5941734`), `lw-090c-mercados-no-modulo` (`36d67af`), `lw-091-comercio` (`edce627`), `lw-091b-porta-do-comercio` (`8d9c417`), `lw-092-producao` (`3b27ba6`), `lw-092b-producao-hora-a-hora` (`13885c5`), `lw-092c-ligacao-ao-modulo` (`43d0b9a`), `lw-093a-verificador-de-ids` (`f7e141a`) e `lw-088d-correcoes-da-revisao-b` (`f3054f1` e `9e9fc7c`, em cima da 093a). Li o código e o diff de cada parte; comparei com `docs/modules/economy.md` (seções 4 a 6 e 10), arquitetura cap. 11 e AGENTS 4, 5, 9, 12 e 13. **Desta vez rodei coisas**, só numa **cópia exportada** da ponta (`git archive` para a pasta temporária; não é checkout nem worktree, e nenhum arquivo do projeto foi tocado). Linhas citadas são da ponta `9e9fc7c`.

### Execução (o que a revisão anterior não pôde fazer)
- `tools/check_all` na cópia da ponta `9e9fc7c`: **VERDE**, código 0. `Scripts 142`, `Tests 1293`, `Passing Tests 1293`, `Asserts 292694`, `Time 183,59 s`; `Warnings 1` e `Deprecated 1` iguais aos do `main`. O verificador novo disse "IDS DE CONTEÚDO: tudo existe (51 conferências)". **A primeira tentativa deu vermelho por defeito meu** (a cópia não é repositório Git e o passo de importar o projeto foi pulado; o Godot não achou as classes); descartei e refiz com o import.
- **Regras E e F exercitadas** com arquivos de sonda que escrevi na cópia (e apaguei): um arquivo de `character` citando `Ledger` e `OwnerBook` **foi reprovado** (2 violações); `balance = 5`, `money = money + 1` e `outro.balance = 9` fora do Ledger **foram reprovados** (3 violações); `wallet["balances"] = 1` e `total_balance = 4` **passaram**, como devem. Com as sondas fora, `check_architecture` voltou a "nove verificações aprovadas". O `tests/test_check_architecture.sh` passou inteiro (inclui os 13 casos novos da 088d).

### BLOQUEANTES
Nenhum.

### Os quatro itens que você pediu (e o I4)
- **I1 (`debug_summary`): RESOLVIDO.** `economy_module.gd:193-203` devolve donos, soma dos saldos, criado, destruído, conservação do dinheiro e dos bens e nº de locais; o teste novo (`test_economy_debug_and_kinds.gd`) confere os valores exatos e que `serialize()` não muda depois de chamar o resumo.
- **I2 (alcance da regra E): RESOLVIDO.** `tools/check_architecture` agora vale para **qualquer arquivo fora de `src/sim/economy/`** (menos `src/app`, a raiz de composição); provei com a sonda acima. Resta o [LIM] já declarado (referência por `preload("res://...")` não é vista).
- **I3 (tipo do dono no save): RESOLVIDO.** `on_load` (`economy_module.gd:134-136`) recusa o save com tipo fora de `owner_kinds.json`, **antes** de trocar o estado (o teste prova que o módulo continua como estava), e `validate()` (`:177-178`) aponta o dono e o tipo. Sem tipos nas definições, qualquer tipo vale (como na abertura de conta; tem teste).
- **I5 (furos da regra F): RESOLVIDO** no que a regra pode ver (atribuição simples, `+=`, `x.balance =`, `_balances` e `_set_balance` fora do Ledger). Ficam de fora, **por ser busca de texto**: passar o nome por `call("...")` ou string, e guardar o saldo em outro nome. Único ponto novo: a atribuição simples `balance = ...` é aceita em **qualquer arquivo** de `src/sim/economy/api/` (menor N9).
- **I4 (reflexão no `NpcDied`): AINDA ABERTO, e não estava na sua lista.** `economy_module.gd:351` lê `event.get("npc_id")` e `:19` e `:55` assinam `"NpcDied"` pelo texto. A A só registrou em `docs/events.md:13` que isso é "exceção **[PROPOSTA]** à DEC-107, a registrar". **Falta a sua decisão** (registrar a exceção como DEC, ou mover as classes de evento para um lugar que a economia possa citar). Importante, mas não trava nada hoje.
- **Fixtures, hash e oráculo:** nenhum arquivo protegido foi tocado de `85ac0bf` a `9e9fc7c` (AGENTS, GDD, arquitetura, DECISIONS, roadmap, `project.godot`, `.gitignore`, `addons`, `tests/fixtures`). Nenhum teste de oráculo ou de soak mudou, **nenhum hash novo**: o jogo real continua sem os mercados, porque `GameModules.register` só os cria se receber um `EconomySetup` (`game_modules.gd`, comentário da LW-090c: ligar é da LW-093 e gastaria os primeiros IDs do `core`). Único teste existente alterado: `tests/test_check_architecture.sh`, **só com acréscimos** (nenhuma linha removida).

### IMPORTANTES
- **R1-I1. Fórmula da tarifa e `peek_quote` sem ator** divergem do contrato da Fase 4. Detalhe em **R2-I2 e R2-I3**, porque dependem de você escolher entre a A e a C. Convém decidir **antes da LW-093** (o NPC passa a chamar `peek_quote`).
- **R1-I2. O I4 acima** (precisa de uma DEC).

### MENORES
- **N1. Tamanho (DEC-126; só código e teste, sem comentário, linha em branco, `.uid`, documento e `.json`; conto linhas acrescentadas):** 090 348 (confere com a revisão anterior), **090b 404**, 090c 310, 091 267, 091b 159, **092 353**, **092b 403**, **092c 432**, 093a 194, 088d 134. **Nenhuma passa de 450** (a tolerância), mas 090b, 092b e 092c ficam perto; a 092c (432, 6 arquivos) é a mais apertada. Nº de arquivos de código e teste: 4 a 9 (a 091 tem 9, no limite).
- **N2. `economy_module.gd` tem 358 linhas de código** (alvo ~300, teto 450) e as próximas tarefas (LW-093 a 097: consumo, salário, postos, contratos) acrescentam `request_*` e `peek_*` **no mesmo arquivo**. Vai passar de 450 em breve: vale planejar a divisão (por exemplo, a parte de produção e a de mercado em classes de apoio) **antes**, e não no meio da LW-095.
- **N3. `TradeEngine.execute` engole o resultado** das duas movimentações (`trade_engine.gd:68-69`: `_ledger.transfer(...)` e `_goods.transfer(...)` sem conferir `ok`); hoje é seguro porque a pré-conferência usa a mesma função, mas AGENTS 13.1.1 pede "nada de erro engolido" e, se um dia divergirem, o comércio vira meio-feito sem aviso. Além disso, o comentário do arquivo diz que o **ator** é conferido antes do estoque e do teto, mas o código confere **depois** (`:48-53`): ator desconhecido comprando sem estoque recebe `ECON_INSUFFICIENT_STOCK`, não `ECON_UNKNOWN_OWNER`.
- **N4. Parada falsa por espaço, no limite.** `ProductionBook._stop_reason` usa `has_room_for` (`production_book.gd:233`), que **não desconta o peso dos insumos que o lote libera**, mas `_batch_is_possible` (`:250-260`) desconta. No limite exato da capacidade o local para com `OUTPUT_FULL` mesmo podendo produzir. Conservador, não perde dinheiro; só deixa a parada mais cedo do que o necessário.
- **N5. A equipe não é conferida.** `assign_worker` (`:89-96`) não olha `workers_wanted` nem se o trabalhador é um NPC aberto; `load_from` e `validate` (`:186-191`, `:313-320`) só exigem IDs positivos em ordem. Inofensivo até a folha (LW-095); depois, um ID morto na lista seria pago.
- **N6. `MarketBook.validate()` só confere o tipo do dono** (`market_book.gd:243-248`); preço fora da faixa e histórico fora do tamanho só são conferidos ao **carregar** (`:264-278`), e `ref_stock`/`days_below` não têm teto nem coerência com `declared` (`:269-271`). O estado em jogo nunca viola isso hoje; é cinto de segurança.
- **N7. Dados:** `ProductionLoader` aceita quantidade e valor até 1e9 (`production_loader.gd:14`) e soma `quantidade × valor` sem teto (`:116`, `:120`, `:127`): dado absurdo estoura o inteiro e engana a regra de margem (mesma família do M8 anterior). E a regra "todo bem é produzido por **exatamente uma** receita" (`:130-133`) vai **barrar** bens de saque e o "monte no chão" da Fase 5 (DEC-188) se forem declarados em `goods.json`: decidir antes se esses bens ficam fora dessa regra.
- **N8. Documentos desatualizados (M9 só em parte):** `docs/events.md:13` foi corrigido; **`economy.md:37` ainda diz** "`api/` vazia" e "`debug_summary` com o padrão do `SimModule`", e a última linha de `src/sim/economy/README.md` ainda diz "Planejado, ainda não existe: o comércio (LW-091)".
- **N9. Regra F:** `balance = ...` simples vale em qualquer arquivo de `economy/api/`; o certo seria só `economy_replies.gd` (as respostas guardam cópia do saldo).
- **Reconferido sem problema:** `MarketBook` (preço anda ao fim do dia; escassez só depois de `shortage_days`; ordem por ID e `good_id`), a hora de produção (compra, confere, produz, vende; eventos só na mudança), a manutenção (cai por degrau e **nunca zera**), o relógio (`tick` por hora, dia depois dos mercados), o verificador `check_content_ids` (os 14 casos de quebra do teste batem com o que ele promete) e `EconomySetup`.

### O QUE NÃO CONSEGUI VERIFICAR (R1)
- **Só li por nome ou por trecho** os testes `test_markets`, `test_economy_markets_api`, `test_trade`, `test_economy_trade_api`, `test_production*`, `test_economy_production_api`; a prova de que passam é a execução verde, **não** uma leitura crítica deles (se testam o que deveriam).
- Não li `goods_store.gd` e `ledger.gd` de novo por inteiro (só os diffs da 091 e 092b), nem `economy_replies.gd`.
- A execução foi na **cópia**, não no worktree da A: o resultado vale para o conteúdo do commit, mas não prova o estado dos worktrees deles.
- Não conferi os desempenhos (tempo por hora de produção); `settlement_of` ordena a lista a cada chamada (`market_book.gd:87-91`), trivial com 3 povoados, **sem medição** não recomendo mexer.

---

## REVISÃO DOS CONTRATOS DA C (R2) — `lw-117a` a `lw-117d` (11/11/2026, papel de revisor; só leitura)

**Em uma frase:** os quatro contratos estão **bem amarrados entre si** (camadas sem ciclo, um dono por dado, estado de cada DEC citado correto), mas na **comparação com o que a A construiu** achei **seis pontos importantes**: dois deles são exatamente os que você pediu (a aridade do `request_open_owner` e a tarifa) e um é **defeito meu** na 146f.

**Alvo e método.** `lw-117a-registro-fase-4` (`4a46ae7`), `lw-117b-economia-fase-4` (`9d541a3`), `lw-117c-factions-politics` (`e1ca88d`) e `lw-117d-military-chronicle` (`c752dcc`), cadeia sobre `9b4f6f0` (ou seja, **sem** a Fase 5 nem a 146f). Li por inteiro `economy.md` seção 17, `factions.md`, `politics.md`, `military.md` e `chronicle.md`; do `DECISIONS.md` só o índice de DEC-202 a DEC-226. Comparei com o **código** da A (`9e9fc7c`), o `EventBus` e o `SimEvent`. A 117e (`world`/`npc`) está **fora do alvo**; só olhei o que ela diz das rotas.

### BLOQUEANTES
Nenhum (são rascunhos de texto, sem código).

### IMPORTANTES
- **R2-I1. Aridade de `request_open_owner` (o que você pediu).** **A:** 3 argumentos, `request_open_owner(owner_id: int, kind: String, work_place_id: String = "")` (`economy_module.gd:207`; `economy.md` seções 3, 10 e 15). **C:** `request_open_owner(owner_id, kind, work_place_id, initial_balance)`, com o 4º opcional e **só para `treasury`** (`economy.md` 17.2). É compatível com quem chama com 3 (o novo é opcional e vem no fim), **mas** (a) `politics.md:18` escreve `request_open_owner(polity_id, "treasury", 0, initial_balance)`, com **`0` no lugar do `work_place_id`**, que é `String` no código: o GDScript tipado não aceita (deveria ser `""`); (b) "omitido, vale o saldo do tipo" exige um **valor-sentinela** (o `0` não serve, porque 0 é um saldo possível, e o GDScript não tem argumento nomeado) → número mágico; (c) o `work_place_id` não tem sentido para tesouro (a A o ignora em silêncio), então quem abre tesouro passa um vazio de enchimento; (d) as seções 3, 10 e 15 da C seguem com 3 argumentos (a C não editou seções existentes) e quem implementar vê duas aridades. **Recomendação: um comando próprio, `request_open_treasury(owner_id, initial_balance)`**, e `request_open_owner` fica como está (3 argumentos, o que o `npc` da LW-093 vai usar). Alternativa: manter o 4º argumento com uma constante `NO_INITIAL_BALANCE = -1` e escrever `""` nos exemplos. Quem corrige: a C (117b e 117c).
- **R2-I2. Tarifa: `floor` na A, `ceil` na C (o que você pediu).** **A:** `trade_engine.gd:42` calcula `IntMath.floor_div(total * tariff_bp, 10000)` e o teste `test_trade.gd:159` espera exatamente isso (5% de uma ordem); a tarifa é **calculada e devolvida, mas não cobrada** (os fundos só olham o `total`, `:59`). **C (17.4):** `ceil_div(total × tariff_bp, 10000)`, "pelo menos 1 se `tariff_bp` > 0", **cobrada do ator nos dois lados**, na mesma transação, com os fundos conferidos **com** a tarifa (DEC-225, APROVADA, decide **quem paga**; a **fórmula** é DEC-214, PROPOSTA). Com `floor`, uma ordem pequena paga 0 (5% de um total abaixo de 20 não paga nada) e **quem divide a compra em ordens miúdas foge da tarifa**; o `PriceMath` da própria A já arredonda para cima a margem do `ask` (`price_math.gd:51`). **Recomendo `ceil` com mínimo 1, como a C**, e mudar **já na A** (uma linha em `trade_engine.gd:42` e a linha `test_trade.gd:159`, **o que exige a sua autorização para mexer nesse teste**, AGENTS 9.5) para o código da Fase 3 já bater com o contrato; a **cobrança** e os fundos ficam para a LW-130. Se você preferir `floor`, quem muda é a C (17.4). **Decisão sua.**
- **R2-I3. `peek_quote` não recebe o ator.** `economy_module.gd:253-257` chama `_engine.quote(...)` sem ator (o motor usa `NO_ID`); o contrato da A (`peek_quote(market_id, good_id, quantity, side)`) também não tem. Mas a regra real da `politics` **depende do ator** (sobretaxa de estrangeiro, desconto de tratado, licença: `politics.md:58`), e a C (17.4) diz que `peek_quote` "devolve o mesmo valor" da tarifa cobrada: **impossível** sem o ator. **Recomendo `peek_quote(actor_id, market_id, good_id, quantity, side)`** (a mudança é barata agora e cara depois que a LW-093, a 094 e a interface LW-106 já chamarem). Quem corrige: a A, no contrato e na 091b.
- **R2-I4. `needs_license` não tem efeito em lugar nenhum.** `politics.md:50` pede à 117b que `needs_license` verdadeiro **recuse a ordem**; a seção 17.4 **não** diz isso (só empurra a pergunta para a 117c) e o motor da A só confere `banned` (`trade_engine.gd:34`); o campo `TradeTerms.needs_license` existe e **ninguém o lê**. Sem a frase e sem a conferência, a lei de licença (uma das cinco) não faz nada. Recomendo recusar com um código próprio (`ECON_LICENSE_REQUIRED`) em vez de reusar `ECON_TRADE_BANNED`, para o painel "Por quê?" dizer o motivo certo. Quem corrige: a C (17.4) e, na LW-130, o motor.
- **R2-I5. Rota bloqueada: três desenhos para o mesmo comando, e um é meu.** (a) **Minha 146f, já no `main`** (`world.md:98`): `request_set_route_state(route_id, new_state, reason)`, `reason` fechado (`world_event`; a Fase 4 acrescentaria `hostile_force`), **sem parâmetro de causa**; (b) **117e** (`world.md`, ponto 5): um par novo, `request_block_route` e `request_unblock_route`, e deixa os dois antigos só de desenvolvimento; (c) **`military.md`** (117d: seção 6 item c, tabela da seção 8 e ponto 7 de 15) ainda diz que o `military` chama `request_close_route` e `request_open_route` **em produção** ("PEDIDO à 117e"); a 117e respondeu com o par (b) e deixou o ajuste do `military.md` "para uma rodada da 117d", **que não foi feita**. **E um defeito meu:** a crônica (`chronicle.md` seção 1, confirmada no código: `event_bus.gd`, `publish`) diz que quem age **fora do tratamento de um evento** tem de gravar o `cause_id` à mão, e o `military` fecha e reabre a rota **no `tick`**; meu comando **não aceita causa**, então a cadeia da cascata ("… missão → rota reaberta", LW-143) **quebraria** nesse elo. Eu desenhei só para o caso do evento de mundo (dentro de um ouvinte) e não pensei no `military`. **Recomendo um comando só:** o meu, com um **`cause_id` opcional** no fim (`request_set_route_state(route_id, new_state, reason, cause_id = NO_CAUSE)`), `reason` fechado (`world_event`, `hostile_force`); a 117e retira o par novo e a 117d corrige o `military.md`. **Eu corrijo o `world.md` na 146g** (o defeito é meu). Alternativa: ficar com o par da C e eu tirar o meu (o desabamento de rota usaria o par).
- **R2-I6. A crônica ignora o campo `severity` que o `SimEvent` já tem.** `sim_event.gd` define `severity` ("importância de 0 a 100; define se vai para a crônica e se o jogador é avisado", arquitetura 17.3) e a A **já o preenche** em `ShortageDeclared` (`market_book.gd:189`, quanto falta do alvo). O `chronicle.md` seção 2 calcula a severidade **só por dados** (`chronicle.json` e `severity_rules.json`) e **não diz o que faz com o campo do evento**: ficam duas fontes de "gravidade", com sentidos diferentes. **Recomendo:** os dados decidem a entrada na crônica, e o campo do evento vira **insumo** (`severity_rules.json` pode ler `field = severity`); escrever uma frase no contrato. Quem corrige: a C (117d).

### Merge da C com o `main` (previsão; não executei nenhum merge)
Pela lista de arquivos e por `git merge-tree --trivial-merge` (só imprime, não escreve nada): juntar a **117a a 117d** ao `main` atual dá **28 trechos em conflito, todos em `docs/DECISIONS.md`** (os índices por área e os totais: os dois lados acrescentam linhas nos mesmos lugares; a C reservou DEC-179 a DEC-201 para mim, então **os números não colidem**, só o texto). `DEVELOPMENT_ROADMAP.md` e `economy.md` **mesclam sem conflito** (a A e a C editam regiões diferentes do `economy.md`: a A as linhas 3, 37 a 39 e 236 a 243, a C só acrescenta da 334 em diante). Os totais precisam ser **recontados** pelo método da LW-033A (a C diz 203; o `main` diz 201; **pelas minhas contas o total junto é 226**). A **117e** conflita ainda em `world.md` e `npc.md` (um trecho cada) **com a minha 146f**.

### MENORES
- **M1. Pedidos pendurados em contratos que ainda não existem:** `peek_caravans_on` e o evento `CaravanArrived` (o `military` precisa; a seção 9 da A é "só reserva" até a LW-098); `ContractCompleted` com `issuer_id` e `issuer_kind` (a A tem `contract_id`, `acceptor_id`, `reward`; a crônica e a reputação precisam); motivo `contribution` (a C usa `tax` até lá); e, da 117e, `peek_satisfaction`, `request_set_on_mission`, lista de NPC por ofício e povoado, `source_event_id` no `RumorSpread` e `witness_count`. Devem entrar na lista da 117f.
- **M2. "Só a `factions` promove a T3" e "só a `politics` chama `request_appoint_t3`" são convenção**, sem verificação: `request_promote(npc, 3)` é público no `npc` e `request_appoint_t3` na `factions`. Falta uma regra no `check_architecture` ou uma checagem de chamador (mesma família do M13 da revisão anterior).
- **M3. Acoplamento:** `politics` importa 4 módulos e `military` 5 (e 6 na Fase 5, quando importar o `combat`); a C já sinalizou (AGENTS 5.2) e deixou para a LW-144.
- **M4. Ordem de registro no `World`.** A C: `character`, `economy`, `npc`, `factions`, `politics`, `military`, `events` por último. A **minha** `app.md` A2 (146f) lista `character`, `economy`, `npc`, `ecology`, `combat`, `events`, **sem os de Fase 4**. É preciso uma ordem só (provável: `character`, `economy`, `npc`, `factions`, `politics`, `military`, `ecology`, `combat`, `events`); eu corrijo na 146g.
- **M5. Duas verdades no `economy.md` da C:** a seção 17 diz "para a Fase 4 vale esta seção", mas as seções 3, 5, 10 e 15 continuam com 3 argumentos, tarifa 0 e folha pelo mercado. Aceitável como rascunho; a versão final precisa unir.
- **M6. Cascata e fila do barramento:** `event_bus.gd` entrega no máximo `MAX_ROUNDS_PER_DISPATCH = 8` rodadas por vez e o excedente fica na fila, e `validate()` reclama de evento pendente (isso trava salvar, `app.md` A3). A cascata de 6 ou mais elos da LW-143 só tem risco se muitos elos reagirem **no mesmo passo**; nenhum dos quatro contratos cita o limite. Anotar no teste da LW-143.
- **M7. `cause_id` aparece ora como campo de carga** (`LawChanged(..., cause_id)`), **ora como parâmetro de comando** (`request_transfer_province(..., cause_id)`); no código é o campo comum do `SimEvent`, preenchido pelo barramento (ou à mão fora de ouvinte). Padronizar a frase.
- **M8. Consulta reversa:** `military.md` e `factions.md` usam `peek_posts_of(settlement_id)` e `peek_sites_of` para descobrir se **um** ator já tem posto; uma `peek_workplace_of(actor_id)` seria mais simples (custo O(postos) por recrutamento, sem importância hoje).

### O que conferi e está certo (R2)
O estado de cada DEC citada bate com o índice do `DECISIONS.md` da C (**DEC-202 a DEC-212 e DEC-224 a DEC-226: APROVADA; DEC-213 a DEC-223: PROPOSTA**). Os fatos do barramento que a crônica usa **são verdadeiros no código** (assina por nome de evento; sem assinatura geral; sem histórico; `cause_id` automático só dentro do tratamento e à mão é respeitado). Camadas sem ciclo: `factions` → `economy`, `npc`, `world`; `politics` → também `factions`; `military` → também `politics`; `events` só `core`, `data` e `world`; a `economy` nunca importa a `politics` (interruptor). Um dono por dado em todas as tabelas "Dado → dono". Todo número de jogo está marcado [HIP] e vai para `data/`. As quatro fichas só mexem em `docs/` (a 117a edita `DECISIONS.md` e o roadmap, que são protegidos: ver abaixo).

### O QUE NÃO CONSEGUI VERIFICAR (R2)
- **Se a LW-117a tinha autorização escrita** para editar `DECISIONS.md` e `DEVELOPMENT_ROADMAP.md` (arquivos protegidos); não vi o prompt dela, e não li o `0013` por inteiro (só o que as fichas citam dele).
- **As fichas contra o GDD (10, 11, 14, 15, 20) e a arquitetura (12 a 14, 17):** não os reli; usei o que as próprias fichas citam e o **código** como árbitro.
- **A 117e** só na parte das rotas; **a 117f** (catálogo e colunas de dados) **não existe** ainda.
- O merge foi **previsto**, não feito: a previsão vem do `merge-tree`, e o resultado real pode mudar se o `main` andar.

---

## ACOMPANHAMENTO DAS DUAS REVISÕES (R1 e R2)
**Nada foi alterado nos ramos da A nem da C** (só leitura; as sondas e a cópia ficaram na pasta temporária). **Decisões que dependem de você, com a minha recomendação** (cada uma tem um dono):
1. **Tarifa: `ceil` com mínimo 1** (como a C) e já na A, com a sua autorização para ajustar `test_trade.gd:159`. *(A e C)*
2. **Abrir tesouro por comando próprio** (`request_open_treasury`), e `request_open_owner` fica com 3 argumentos. *(C)*
3. **`peek_quote` com `actor_id`**, antes da LW-093. *(A)*
4. **`needs_license` recusa a ordem**, com código próprio. *(C e, na LW-130, o motor)*
5. **Rota: um comando só** (`request_set_route_state` com `cause_id` opcional); a C retira o par novo e corrige o `military.md`; eu corrijo o `world.md` na 146g. *(C e eu)*
6. **Severidade: os dados decidem e o campo do evento vira insumo.** *(C)*
7. **I4: registrar a exceção do `NpcDied` por nome como DEC** (ou mover as classes de evento). *(você, depois a A)*
8. **Ordem de integração:** sugiro a C entrar no `main` **antes** da 146g (assim eu escrevo o `economy.md` e a ordem do `World` já sobre o texto final), sabendo que o merge terá **28 trechos em conflito no `DECISIONS.md`**; quem faz a junção deve recontar os totais (226).
**Próxima tarefa recomendada:** a 146g **só** quando a LW-117 estiver no `main` e você mandar. **Não iniciada.**
**Git:** nenhum commit nos ramos de código; commit só no `status-b` (este relatório). Nenhum push no `main`, nenhuma tag, sem force/rebase/reset.


## REVISÃO R3 — LW-117e e LW-117f da C, e a junção `0760c5c` da A (11/11/2026, papel de revisor, AGENTS seção 11; só leitura, nada implementado)

**Em uma frase:** a junção da A está limpa (nada protegido tocado, catálogo certo, `check_all` verde no `main`) e o catálogo juntado **dá mesmo 58 eventos, sem nome repetido**; mas achei **nove pontos importantes** de conflito ou de ambiguidade entre a Fase 4 (C), a Fase 5 (minha) e o código, e **dois deles são defeitos meus** (a morte de NPC em combate e a seção 15 do `npc.md`).

**Alvo e método.** `origin/lw-117e-world-npc` (`b665ca7`), `origin/lw-117f-eventos-e-dados` (`5e6da5c`, em cima da 117e; `0015`, `docs/fase-4/dados.md` e `docs/events.md`) e `origin/main` = `0760c5c`. Li o diff inteiro da 117e e o `dados.md` inteiro; do catálogo, extraí as linhas por script (não por leitura). Comparei com o **código** do `main`, com as minhas fichas já no `main` (`combat`, `character`, `ecology`, `dynamic_events`, `app`, `npc` 15, `world`, `events.md`) e com o contrato da economia. Exportei o `main` e os dois ramos para a pasta temporária (`git archive`; nenhum checkout nem worktree). **Conferi os nomes com script:** eventos (catálogo × citações nas fichas), comandos e consultas (Fase 5 × Fase 4) e DEC (definidas × citadas). Linhas citadas são do arquivo no ramo indicado.

### R3(b) A junção `0760c5c` (A leva a economia ao `main`)
- **O que é:** merge de `9e9fc7c` (088d) com `20a788f`; 127 arquivos, +6125 −43 contra `20a788f`. **Nenhum arquivo protegido** foi tocado (conferi a lista contra o AGENTS 12.5: AGENTS, GDD, arquitetura, `DECISIONS.md`, roadmap, `project.godot`, `.gitignore`, `addons`, `tests/fixtures`). Único teste de referência que mudou é o `test_npc_split_oracle.gd` (22 linhas): é o **marco 1 da DEC-175**, que você aprovou e eu já tinha visto na primeira revisão; **não reconferi os 9 valores**.
- **Conflitos resolvidos só em `docs/events.md` e `docs/modules/app.md`.** `events.md`: **27 linhas de evento, 27 nomes distintos, nenhum repetido** (16 + 11 da Fase 5; o cabeçalho diz 27 e 6+10+11 = 27); as **11 da Fase 5 estão todas lá**; as 5 da economia aparecem como `implementado, LW-090b` e `LW-092b` e as de comércio e contrato seguem `planejado`. `app.md`: **as seis seções A1 a A6 da 146f intactas** e a linha da economia do `GameModules` presente.
- **Execução:** `tools/check_all` numa cópia exportada do `main` `0760c5c`: **VERDE**, código 0, `Scripts 142`, `Tests 1293`, `Passing 1293`, `Asserts 292694`, 183,9 s; `Warnings 1` e `Deprecated 1` iguais; "IDS DE CONTEÚDO: tudo existe (51 conferências)". Os números são **idênticos aos da ponta da A** (`9e9fc7c`), como devia ser, já que o que entrou da minha parte é só texto.
- **Nenhum achado** contra a junção. Anotação: a A **não** registrou nenhuma DEC (o `DECISIONS.md` do `main` não mudou), então a proposta do I4 ainda vai chegar.

### R3(a) 117e e 117f

#### BLOQUEANTES
Nenhum (são rascunhos de texto).

#### IMPORTANTES
- **R3-I1. `peek_npc_ids` já existe com outra assinatura.** `src/sim/npc/api/npc_module.gd:251` tem `peek_npc_ids() -> Array[int]` (todos os IDs, LW-057; contrato em `npc.md:115`). A 117e (`npc.md:354`, em `lw-117e`) cria **`peek_npc_ids(occupation_id, settlement_id)`**, com o **mesmo nome**. O GDScript **não tem sobrecarga**: ou o nome novo quebra quem chama sem argumento (`src/bridge/bridge_npc_inspect.gd` e 8 arquivos de teste de integração e de soak chamam `peek_npc_ids()` hoje) ou vira um argumento opcional que esconde duas funções. **Recomendo renomear** a nova (`peek_npc_ids_of(occupation_id, settlement_id)`). Corrigem: a C (117e e `factions.md`, que a cita).
- **R3-I2. Seção 15 do `npc.md` em duplicidade, e as citações ficam ambíguas (defeito meu e da C).** Os dois lados criaram **`## 15.` na linha 328 do `npc.md`** (a minha no `main`, "Extensão da Fase 5"; a da 117e, "Extensão da Fase 4"): é o 1 trecho em conflito que a C previu. Além do conflito, as citações "`npc.md` 15.x" passam a apontar para dois textos: a C cita a dela em `events.md`, `dados.md`, `0015` e `world.md`; o `main` cita a minha em `events.md` e `app.md`. E um erro dentro da própria 117e: `world.md:96` manda ver "`npc.md` seção 15.2" para o povoado de moradia, mas na 117e isso é a **15.3** (a 15.2 é o T3; e, depois da junção, a 15.2 do `main` é o `NpcTierChanged`). **Recomendo renumerar a da Fase 4 para a seção 16** (como a C entra primeiro, ela troca as suas citações; eu troco as minhas só se você preferir o contrário).
- **R3-I3. `ActReported` (C) × `CombatantWounded` e `CombatantDied` (minha).** A 117f catalogou `ActReported` (`events.md:35`) com publicador "**Fase 5: o `combat`**" e `act_id` já classificado (`assault`, `robbery`, `killing`, `smuggling`); `politics.md:51` diz o mesmo. A **minha** `combat.md:64` diz que o `combat` **só publica ferimento e morte** e **não** classifica crime (DEC-195), e `combat.md:92` não lista `ActReported`. Quem implementar a LW-164 vai encontrar dois desenhos. **Recomendo:** `ActReported` é uma **entrada normalizada da `politics`**, produzida por um adaptador que ouve `CombatantWounded` (agressão), `CombatantDied` (morte) e `ItemTaken` (roubo), com a tabela de mapeamento **em dados**; o comando de desenvolvimento a publica direto. Isso mantém a DEC-195 e a `combat.md`. Corrijo a `combat.md` e o catálogo na 146g; a C troca o publicador na linha 35.
- **R3-I4. A morte do NPC em combate tem dois caminhos (o defeito é meu).** `combat.md:92` lista o **`npc` como ouvinte** do `CombatantDied` (e o `military` baixa a `Force` pelo evento, `:73`), mas **a minha seção 15 do `npc.md` não descreve esse tratamento**. A 117e criou o **comando** `request_apply_casualty(npc_id, reason)` (`npc.md:386`: "só o `military` a chama"), e `military.md:61` manda **uma chamada por baixa**. Num encontro pedido pelo `military` na Fase 5 as duas coisas disparariam: **morte em dobro** (a segunda dá `NPC_DEAD`) ou conta em dobro das baixas. **Recomendo um caminho só, o do comando:** o `combat` (camada 4) chama `request_apply_casualty` no `npc` (camada 3) ao publicar o `CombatantDied`; o motivo ganha `combat` ao lado de `battle`; a regra "só o `military` a chama" vira "só `military` e `combat`"; o `npc` **não** ouve o `CombatantDied` por nome (o mesmo problema do I4 da economia). Corrijo a minha parte na 146g; a C ajusta a regra na 117e.
- **R3-I5. `request_set_on_mission` com duas aridades dentro da própria C.** `npc.md:387` (117e): `request_set_on_mission(npc_id, on_mission, settlement_id)` (3 argumentos; o `settlement_id` só vale ao desmarcar). `military.md:37` e `:76` (117d): `request_set_on_mission(npc_id, on_mission)` (2). O `military` não conseguiria dizer onde o soldado reaparece. Corrige a C (`military.md`).
- **R3-I6. Id de dados (texto) × id de execução (inteiro) para facções e países, sem ponte.** Os dados usam texto (`faction_authority`, `polity_main`: `dados.md:75`, `:184`; `faction_seed.faction_id`, `polities.governing_faction_id` e `force_seed.owner_id` são `STRING`, `dados.md:225`), mas em execução o `faction_id` e o `polity_id` são **inteiros de `ctx.ids`** (`factions.md:16`, `politics.md:16`) e todos os comandos os recebem em inteiro (`request_set_payroll_source(settlement_id, faction_id)`). **Nenhuma ficha diz como a `politics` ou o `military` resolvem o texto para o inteiro** (não há campo `content_id` nem consulta). Recomendo `peek_faction` e `peek_polity` devolverem o `content_id` e uma consulta `peek_faction_id_of(content_id)` (e a igual para país). Província e povoado não têm esse problema (são só texto).
- **R3-I7. `work_place_id` vazio nas linhas novas de população.** `dados.md:59` manda `population.json` ganhar `soldier` e `bandit` "com `work_place_id` vazio". **Provado na cópia do `main`:** (1) com `"work_place_id": ""`, o verificador da A (`tools/check_content_ids.gd:70-78`) **reprova** ("o id '' não existe em `data/world/places.json`"), porque só pula a linha que **não tem** a coluna; (2) hoje o carregador do `npc` **rejeita a coluna** ("campo desconhecido": ela só nasce na LW-097); (3) sem a coluna, o verificador passa, mas o carregador rejeita o ofício `soldier` enquanto ele não estiver em `occupations.json`. Ou seja, a ordem dos dados e o significado de "vazio" precisam ser escritos: **a coluna opcional no esquema e o verificador ignorando `""`** (mudança pequena no arquivo da A), ou a coluna omitida nas linhas sem trabalho. Defino na 117f ou em rodada da C; o ajuste do verificador é da A.
- **R3-I8. Números de DEC: sem colisão hoje, com três pontos de atrito.** As definidas são **201 no `main` e 203 na C; a união cobre 1 a 226, contínua, sem repetição** (a C reservou 179 a 201 para a Fase 5, e as DEC citadas nas fichas da 117e e da 117f **existem todas**). Mas: (a) a linha "**próximo número livre**" diz **`DEC-202`** no `main` (`DECISIONS.md:3160`) e **`DEC-179`** na C (`:3188`, desatualizada): depois da junção tem de dizer **`DEC-227`**; (b) **três lotes pedem números a partir de 227 ao mesmo tempo**: a proposta do I4 (A), as suas oito confirmações de hoje (alguém tem de registrá-las) mais a DEC dos marcos de hash do `0015` (C) e as da 146g (eu). **Recomendo reservar faixas** (por exemplo A 227 a 229, C 230 a 239, eu 240 a 249) ou "quem entra primeiro no `main` pega o próximo e os outros renumeram na junção"; a escolha é sua.
- **R3-I9. Ordem de registro no `World`: cinco afirmações, nenhuma completa.** C: `factions` "depois de `economy` e `npc`, antes de `politics`" (`factions.md:18`), `politics` depois de `factions` (`politics.md:18`), `military` depois de `politics` (`military.md:18`), `events` "por último" (`chronicle.md:19`). Minha: `character`, `economy`, `npc`, `ecology`, `combat`, `events` (`app.md:42`, sem os de Fase 4). Código: `character`, `economy`, `npc`. **Isso importa mais do que parece:** o `World.serialize` indexa por **nome** (o hash não depende da ordem), mas **os IDs são alocados no `on_new_game`, na ordem de registro** (a economia já pede `ids.next_id()` ali), então a ordem decide os IDs dos NPCs e dos mercados e, por aí, o hash dos marcos. **Recomendo uma ordem só, por dependência:** `character`, `economy`, `npc`, `ecology`, `factions`, `politics`, `combat`, `military`, `events` (o `military` importa o `combat` na Fase 5, então o `combat` vem antes). Corrijo o `app.md` A2 na 146g.

#### MENORES
- **R3-M1. Catálogo juntado: 58 está certo.** 16 linhas comuns + 31 só da 117f + 11 só do `main` = **58**, **nenhum nome repetido** e nenhum evento citado nas fichas da C que não esteja no catálogo (as únicas exceções são `NpcDecided`, já "não incluído", e `WitnessesCounted`, só uma alternativa). Mas os **textos de cabeçalho divergem** (C: 47, "31 da Fase 4"; `main`: 27) e vão conflitar (os 2 trechos de `events.md` que a C citou): a junção deve recontar. **Cuidado na junção:** a linha do `NpcDied` da C ainda diz "ouvintes: nenhum hoje", o que **contradiz a da A** (a economia a assina); vale a da A com a carga da C (`battle`). A linha do `RouteStateChanged` da C ainda cita `request_block_route` (superada pela sua decisão 5).
- **R3-M2. Nomes de comando.** Fora o R3-I1, **só há coincidência nos pares já decididos** (`request_close_route` e `request_open_route`, que ficam só de desenvolvimento) e em `request_promote` e `request_demote`, em que a 117e **estende** a faixa para o T3 (compatível; a minha 15.2 dizia "T3 [A CONFIRMAR]", que agora a 117e confirma: atualizo na 146g). `peek_npc` e `request_trade` só são **usados** pelos dois lados.
- **R3-M3. Duas noções de "testemunha".** A 117e (`npc.md` 15.6) conta **NPCs vivos no mesmo local lógico**, menos os que dormem ou estão em missão (`peek_witness_count`, para a reputação); a minha (`npc.md` 15.5 no `main`) faz **T2 a menos de um raio** gravar memória `item_taken`. Regras diferentes com a mesma palavra: dar nomes diferentes ou definir uma só.
- **R3-M4. Dados.** (a) `faction_doctrine.json` está no `dados.md` mas **não** na lista de arquivos do `factions.md` seção 11 (a C diz que as fichas mandam nos nomes); (b) `data/cultures.json` fica na raiz de `data/`, os demais de mundo em `data/world/`; (c) `merchant` é um id **proposto** (depende do contrato da LW-098); (d) o `dados.md` diz que a conferência de ids (DEC-137) "se estende" à Fase 4, mas **não lista as colunas novas** que o `check_content_ids` precisa conhecer (`occupation_id`, `settlement_id`, `culture_id`, `faction_id` e outras).
- **R3-M5. Redundâncias com o código.** `peek_npc` já devolve `traits` (a personalidade), `home_place_id` e `need_urgencies` (`npc_module.gd:566-600`): `peek_personality` e parte de `peek_home_settlement` repetem o que existe. Não é erro; vale a pergunta "precisa mesmo?".
- **R3-M6. `ContractCompleted` já traz o que a crônica pediu** (`kind`, `issuer_id`, `issuer_kind`, `acceptor_is_player`, na linha da 117f): **atende o M1 da R2**; falta o `economy.md` da A (seção 11) adotar os campos antes da LW-096.
- **R3-M7. A decisão 6 de hoje (severidade) ainda não chegou ao `dados.md`:** nenhuma linha de `severity_rules.json` lê o campo `severity` do evento (a `ShortageDeclared` da A já o preenche).
- **R3-M8. A coluna "Entra na crônica?" da Fase 5.** O `main` marca `CombatantDied`, `PlayerDefeated`, `WorldEventStarted` e `WorldEventEnded` como "Sim" ou "Se…", mas o `chronicle.json` do `dados.md` **não tem linha** para eles, e o teste da C exige que o catálogo concorde com os dados: **falta dizer quem acrescenta** (LW-156d, LW-162 e LW-164 devem levar a linha).
- **R3-M9. A rota da 117e (`world.md`) ficou obsoleta** pela decisão 5 (um comando só); a C a retira. Ela já avisou.

#### O que conferi e está certo
Os **onze** eventos da Fase 5 e os 31 da Fase 4 **não têm nome repetido nem parecido**; os `.json` citados pelos dois lados **não colidem** (só `events.json` é nomeado pelos dois, e a C o atribui à minha tabela de eventos de mundo, de propósito); as DEC citadas na 117e e na 117f **existem** e o status delas bate com o índice; a 117e **não toca arquivo protegido** (só `npc.md` e `world.md`) e a 117f só cria `0015`, `dados.md` e mexe em `events.md`; o desenho da 117e **salva campo novo só quando não vazio**, o que de fato protege o hash do jogo sem Fase 4; `need_urgencies` (urgência de 0 a 3), `NpcDied.cause`, `NpcLifecycle.kill` e `request_promote` **existem como a 117e diz**; as contagens de arquivos do `dados.md` (9, 6, 14 e 8) batem com as listas dos contratos, **exceto** `faction_doctrine.json` (R3-M4 a).

### O QUE NÃO CONSEGUI VERIFICAR (R3)
- **Execução** só no `main` (verde) e na prova pontual do `work_place_id`; **não rodei** nada sobre a 117e e a 117f (são só texto) e não simulei o merge delas com o `main` (usei a previsão de antes).
- **`dados.md` linha por linha:** li tudo, mas **não conferi cada número** contra as fichas (por exemplo, que `count` de cada `faction_seed` caiba na população: somei só os de `soldier`, `bandit` e `guard`, que cabem).
- **As fichas da Fase 4 contra o GDD e a arquitetura** (como na R2): não reli esses capítulos.
- **O `0015` (marcos de hash)** só li; não comparei com o plano de marcos da Fase 5 do meu `app.md` A2 (também em aberto) nem com o `0013`.
- **Se o `world.peek_routes_of`** (usado pelos rumores) existe: **não existe no código** (é da LW-097, Fase 3); a 117e depende dela.
- **`witness`, `rumor` e `protest`** de verdade: não há código; li só o desenho.

---

## ACOMPANHAMENTO DA R3
**Nada foi alterado em nenhum ramo da A, da C nem no `main`** (só leitura; as cópias e as sondas ficaram na pasta temporária). **Não repassei nada às conversas A e C**, como você mandou.
**Decisões que dependem de você, com a minha recomendação:** (1) renomear a consulta nova (`peek_npc_ids_of`); (2) renumerar a seção 15 da Fase 4 para 16; (3) `ActReported` como entrada normalizada da `politics`, com adaptador e tabela em dados; (4) morte de NPC em combate **só por `request_apply_casualty`**, chamado por `military` e `combat`; (5) `request_set_on_mission` com 3 argumentos nos dois contratos; (6) `content_id` e consulta de id inteiro por texto para facção e país; (7) `work_place_id` opcional no esquema e o verificador ignorando `""`; (8) faixas de DEC (A 227-229, C 230-239, eu 240-249) e "próximo livre = 227"; (9) a ordem única de registro `character, economy, npc, ecology, factions, politics, combat, military, events`.
**O que eu corrijo na 146g (meu):** o R3-I3 (`combat.md`, catálogo), o R3-I4 (a minha parte da morte de NPC), o R3-I9 (`app.md` A2), o R3-M2 (T3 confirmado), a rota (`cause_id` opcional, da R2) e, se você preferir, o R3-I2 pelo meu lado.
**Próxima tarefa recomendada:** a 146g **só** depois da LW-117 no `main` e do seu "vá". **Não iniciada.**
**Git:** **nenhum commit nem push.** Este relatório está só no arquivo `STATUS-B.md` do worktree `status-b` (alteração **não commitada**). Mensagem de commit sugerida: `status b: revisão R3 (117e, 117f e a junção 0760c5c da A)`. Arquivo: `STATUS-B.md`.


## REVISÃO R4 — correções da A (092d, 092e, 092f e a junção 092g) e a 117g da C (11/11/2026, papel de revisor, AGENTS seção 11; só leitura, nada implementado)

**Em uma frase:** as três correções da A fazem o que prometem (a 092f não perdeu nada), os testes antigos só mudaram onde você autorizou, a 117g da C aplica as suas seis decisões, e a **junção 092g (que apareceu no GitHub enquanto eu revisava) preservou a mudança da 092e** nos dois lugares em que ela tinha de estar; o que sobra são **uma armadilha que a junção resolveu mudando um teste**, um rótulo de status que preciso que você confirme e a lista do que a 117h ainda tem de fazer.

**Alvo e método.** (a) `origin/main`; (b) `lw-092d-correcoes-da-revisao` (`a19ac0f`), `lw-092e-ajustes-de-contrato` (`f15405e`) e `lw-092f-divide-economy-module` (`47aa88f`), os três **em paralelo** sobre `d1d3d8b`; (c) `lw-117g-ajustes-das-fichas` (`c84c0fe`); (d) `lw-092g-juncao-das-correcoes` (`9df6aaa`, **existe agora**) e a 117h (**não existe**). Linhas citadas são da ponta do ramo indicado (a da 092g quando digo "na junção"). Li os diffs inteiros, comparei função por função a 092f com o módulo antigo, contei com script (tamanho DEC-126, funções públicas, linhas removidas dos testes) e **rodei o `tools/check_all` numa cópia exportada da ponta de cada ramo** (`git archive` para a pasta temporária; nenhum checkout nem worktree; o import do projeto roda antes). Montei também, na pasta temporária, **duas junções simuladas** para prever o que a 092g teria de resolver.

### (a) O `main`
`origin/main` = `d1d3d8b` ("LW-093a: status da Fase 3"). Contra `0760c5c` mudou **só `docs/ROADMAP_STATUS.md`** (+10 −1). Confirmado.

### (b) As três correções da A (cada uma isolada, sobre `d1d3d8b`)
| Ramo | Linhas de código e teste (DEC-126) | Arquivos | `check_all` na ponta |
|---|---|---|---|
| **092d** `a19ac0f` | 91 | 2 | **VERDE**, `Tests 1296`, `Passing 1296` (1293 + 3 novos), `Asserts 292765`, 180 s |
| **092e** `f15405e` | 82 | 5 | **VERDE**, `Tests 1295`, `Passing 1295` (1293 + 2 novos), `Asserts 292734`, 186 s |
| **092f** `47aa88f` | 342 (código movido) | 5 | **VERDE**, `Tests 1293`, `Passing 1293`, **`Asserts 292694` (idêntico ao do `main`)**, 186 s |
Nos três: `Warnings 1` e `Deprecated 1` iguais, "nove verificações aprovadas", "IDS DE CONTEÚDO: tudo existe (51)". **Nenhum arquivo protegido** foi tocado (conferi a lista do AGENTS 12.5), e `tests/test_check_architecture.sh` ficou **como estava**.

- **092d (acertos da revisão): comportamento igual onde devia.** O `TradeEngine.execute` agora confere o `Result` das duas movimentações (`trade_engine.gd:74-82`: se o pagamento falha, devolve a falha sem mover bens; se a entrega dos bens falha depois do pagamento, **devolve o dinheiro** e diz na mensagem se nem isso deu), e a ordem das conferências passa a ser a do comentário (ator **antes** do estoque e do teto: `_quote`, `:34`). Mudança de comportamento **intencional**: ator inexistente comprando sem estoque agora recebe `ECON_UNKNOWN_OWNER`, não `ECON_INSUFFICIENT_STOCK` (tem teste). Só **arquivos novos** de teste (`test_trade_engine_results.gd`, 3 testes, com duplos de `Ledger` e `GoodsStore` que falham) e **nenhum teste antigo tocado**. Também escreveu no `docs/backlog.md` os menores da minha revisão anterior (R1) e corrigiu o `economy.md:37` e a última linha do `README` da economia (**M9/N8 resolvidos**).
- **092e (tarifa e `peek_quote`): idêntica à decisão.** `trade_engine.gd:90` calcula `ceil_div(total × tariff_bp, 10000)` (com `tariff_bp` ≤ 0 devolve 0) e `peek_quote(actor_id, market_id, good_id, quantity, side)` (`economy_module.gd:253`) passa o ator ao motor. **Testes antigos: só o que você autorizou.** Linhas removidas, todas: as **3 chamadas de `peek_quote`** em `test_economy_trade_api.gd` (ganharam o primeiro argumento) e a **`test_trade.gd:159`** (`floor_div` virou `ceil_div`, com o texto da mensagem ajustado). O teste novo prova o arredondamento (11 × 1/10000 sobe a 1; 3,3 sobe a 4; 100% dá 11), que a tarifa **continua sem ser cobrada**, que dividir a compra em cinco ordens paga 5 (a fuga que eu apontei fecha) e que a cotação depende do ator (taxado × livre; `tool` proibido só para um).
- **092f (divisão): não perdeu nada, pelo que consegui provar.** `EconomyModule` foi de **358 para 134 linhas de código** (resolve o N2 da R1) e o resto foi para `support/`: `EconomyState`, `EconomyQueries`, `EconomyRuntime` e `EconomyPersistence`. Conferi: **as 27 funções públicas continuam, com as assinaturas idênticas**; as constantes `KEY_*` do módulo apontam para as da `EconomyPersistence` (mesmos valores); li as quatro classes novas contra o módulo antigo e a lógica é a mesma (jogo novo, hora e fim do dia, `serialize` e `on_load` com a mesma ordem de conferências e troca do estado só no fim, `validate`, `debug_summary` e cada `peek_*`); **o `Asserts 292694` é exatamente o do `main`**, e o número de testes também (1293), sem nenhum teste tocado. Como a 092f não mexe em teste, o verde dela prova que o comportamento que os testes cobrem ficou igual; **o que os testes não cobrem eu só pude conferir lendo.**

### (d) A junção `lw-092g-juncao-das-correcoes` (`9df6aaa`; apareceu durante a revisão)
- **Estrutura:** três merges em sequência, na ordem 092d, 092e e 092f, sobre `d1d3d8b`; contém as três pontas (`is-ancestor` conferido) e descende do `main`. 20 arquivos contra o `main`, nenhum protegido.
- **Respondendo à sua pergunta: sim, o conflito em `api/economy_module.gd` foi resolvido sem perder a mudança da 092e,** e **a mudança também foi levada para onde o Git não avisa**. Eu tinha **previsto** o que a junção teria de fazer (por `merge-tree` e montando a junção mínima na pasta temporária): o conflito de texto em `economy_module.gd` (o `peek_quote`, que a 092f transformou em delegação e a 092e mudou de assinatura) e a mudança **silenciosa** em `support/economy_queries.gd` (o `peek_quote` dali precisava de `actor_id` e de passar o ator ao `engine.quote`; é arquivo novo da 092f, então **nenhum conflito o assinala**). A 092g tem **as duas**: `economy_module.gd:155` com `actor_id` primeiro e `EconomyQueries.peek_quote(_state, actor_id, ...)`. **A minha junção simulada e a real são iguais no código** (só o texto de dois comentários difere).
- **Armadilha que a junção resolveu mudando um teste.** Sem nenhum conflito de texto, a **composição 092d + 092e** deixa **vermelho o teste novo da própria 092e** (`test_the_quote_is_for_the_actor_because_the_rule_can_depend_on_who_buys`, linhas 87 e 89): o teste cota para um ator "que não abriu conta" (dono 3), e a 092d passou a recusar ator inexistente (`ECON_UNKNOWN_OWNER`). **Provei na pasta temporária:** composição, 1 falha em 1298; com a conta do dono 3 aberta, 2 de 2 passam. A **092g fez exatamente isso**: abriu o dono 3 como `player` no `_module` do teste e reescreveu o comentário do cabeçalho. É a correção certa (a DEC-230 diz que a cotação é a mesma que a ordem cobraria desse ator, e a ordem de um ator sem conta falha), **mas é edição de teste para fazê-lo passar**: pelo AGENTS 9.5 convém você saber (o teste é novo da própria A, não é um teste antigo, e o que mudou é o cenário, não a asserção).
- **`check_all` da ponta da 092g:** **VERDE**, código 0 (início 19:06:03, fim 19:10:37): `Scripts 144`, `Tests 1298`, `Passing Tests 1298` (1293 + 3 da 092d + 2 da 092e), `Asserts 292805`, 197 s; `Warnings 1` e `Deprecated 1` iguais; "nove verificações aprovadas"; "IDS DE CONTEÚDO: tudo existe (51)". O número de asserts **é o mesmo** da minha junção simulada com o teste ajustado.
- **A 117h não existe** no GitHub. Existem ramos novos da A (`lw-093-contas-dos-npcs`, `lw-093-npcs-no-mercado` e `lw-093d-dinheiro-e-consumo`) que **não estão no alvo** e **não li**.

### (c) A 117g da C (`c84c0fe`, em cima da 117f; só documentos)
**Aplicou as suas seis decisões da R2**, todas escritas com DEC própria no `DECISIONS.md` (versão 0.14; totais 141 APROVADA, 40 PROPOSTA, 18 PENDENTE, 10 DESCARTADA, 1 SUBSTITUÍDA, **total 210** = 203 + 7, a conta fecha):
1. **Tesouro:** DEC-227, `request_open_treasury(owner_id, initial_balance)` com saldo **obrigatório**; `request_open_owner` fica com 3 argumentos e **não abre** `treasury`; `economy.md` 17.2 e as fichas `factions.md` e `politics.md` (o exemplo com `0` no lugar do `work_place_id`, que eu apontei, foi substituído) trocadas.
2. **Tarifa:** DEC-228, para cima com mínimo 1 (17.4).
3. **Rota:** DEC-229, `request_set_route_state(route_id, new_state, reason, cause_id)` com `cause_id` opcional e motivos `world_event` e `hostile_force`; o par da 117e foi **retirado** do `world.md`, do `military.md` (seção 6 c, tabela da seção 8 e ponto 7) e da linha do `RouteStateChanged` no catálogo.
4. **`peek_quote`:** DEC-230, ator primeiro, "mesma tarifa que a ordem cobraria". **Bate com o código da 092e** (assinatura, ordem dos argumentos e o teste do mesmo valor).
5. **Licença:** DEC-231, `ECON_LICENSE_REQUIRED` (17.3 e 17.4; a `politics.md` marca o pedido como atendido).
6. **Severidade:** DEC-232, o campo `severity` do evento é insumo (`field` = `severity` em `severity_rules.json`; `dados.md` e `chronicle.md` dizem isso). **Casa com a minha linha do `WorldEventStarted`** (crônica "se a `severity` passar do limiar").
Mais: `request_set_on_mission` com **3 argumentos** em `military.md` (seção 3 e tabela da seção 8), como em `npc.md` 15.8 (**R3-I5 resolvido**); `ActReported` ganhou `witness_count` e `actor_is_player`; a DEC-233 registra os três marcos de hash. **Choque com a Fase 5: nenhum novo.** Os pontos da R3 que **não** estavam na 117g (e são da 117h, como você disse) **seguem como estavam**: `peek_npc_ids` (2 argumentos), a seção 15 do `npc.md` (ainda "15" na linha 328), o adaptador de `ActReported` (R3-I3), `request_apply_casualty` por `combat` e `military` (R3-I4), `content_id` (R3-I6), `work_place_id` vazio (R3-I7) e a ordem única de registro (R3-I9: as fichas ainda trazem as quatro afirmações antigas).

### BLOQUEANTES
Nenhum.

### IMPORTANTES
- **R4-I1. Rótulo "APROVADA" e "aprovado por Arthur" na 117g, que eu não consigo confirmar.** A 117g escreve as DEC-227 a DEC-233 como "**APROVADA por Arthur em 11/11/2026**" e troca o cabeçalho das seis fichas (`economy`, `factions`, `politics`, `military`, `chronicle`, `world`) de "rascunho" para "**PLANEJADO, aprovado por Arthur em 11/11/2026**", e a seção "pontos em aberto" vira "pontos da revisão, aprovados". A **sua mensagem para mim** disse que as decisões de R2 valem "**PROPOSTA até o lote ser aprovado**" e que a C as recebe "direto de você, nos blocos dela". Pode ser que você tenha aprovado o lote à C; **eu não vi essa autorização** e **só você muda status** (AGENTS 3.2 e 8.4). Peço que confirme: se o lote ainda **não** foi aprovado, as seis fichas e as sete DEC estão **rotuladas acima do que valem**, e quem implementar tomaria por obrigatório o que ainda é padrão de trabalho (nomes de campo, de comando e de código seguem PROPOSTA em qualquer caso, e a própria 117g diz isso).

### MENORES
- **R4-M1. O estorno da 092d conta em dobro nos totais do `Ledger`.** O estorno usa `_ledger.transfer(payee, payer, total, REASON_TRADE)` (`trade_engine.gd:80`) e o `Ledger` soma toda transferência no total do motivo (`ledger.gd:64`), então um comércio estornado deixa o total `trade` com o **dobro**. A conservação fecha (o teste confere), é o caminho "não deveria acontecer", mas o total vai para o save e para o hash; um motivo próprio (`trade_undo`) no conjunto fechado resolveria, se você quiser.
- **R4-M2. Regra consultada antes de o ator ser conferido.** Na ordem do `_quote`, a `TradeRules` é chamada **antes** do ator (`trade_engine.gd:38` chama a regra e `:42` confere o ator, na ponta da 092g): a regra real da `politics` (LW-130) receberia um ator que pode nem existir e teria de tolerar isso. Conferir o ator antes das regras é barato e mais seguro; o comentário do arquivo e o teste novo fixam a ordem atual, então é uma decisão pequena sua e da A.
- **R4-M3. Tarifa fora da faixa some em silêncio.** `_tariff_of` (`trade_engine.gd:103`, na ponta da 092g) trata `tariff_bp` ≤ 0 como "sem tarifa" e **não** confere o teto de 10000; a C (17.4) quer `ECON_DATA_INVALID` ("nunca tarifa perdida em silêncio"). Hoje só a regra neutra existe; fica para a LW-130.
- **R4-M4. Textos desatualizados depois da 092e.** A 117g diz em 17.4 que "o código da Fase 3 arredonda para baixo e só muda com a autorização escrita dele"; **isso já mudou**. Atualizar na junção do `economy.md` (Fase B). O `economy.md` da C continua com as seções 3, 5, 10 e 15 antigas (a união fica "para a Fase B", como o cabeçalho avisa).
- **R4-M5. Item do backlog que depende de você.** A 092d **não** apertou a regra F (só `economy_replies.gd` poder atribuir `balance`) porque isso reprova o caso `src/sim/economy/api/reply.gd` de `tests/test_check_architecture.sh`, que **não pode ser editado sem a sua autorização** (a A escreveu isso no backlog). Autoriza trocar o caminho desse caso?
- **R4-M6. A 117g ainda diz "próximo número livre: `DEC-179`"** (`DECISIONS.md:3293` da 117g; o `main` diz `DEC-202`); na junção deve virar **`DEC-234`**, como você definiu (a 117g tem 7 DEC novas, 227 a 233). E a pilha da C com o `main` atual vai dar **29 trechos em conflito no `DECISIONS.md`**, 2 em `events.md`, 1 em `npc.md` e 1 em `world.md`, como a C avisou (previsão por `merge-tree`, não executei o merge).
- **R4-M7. Tamanho (DEC-126):** 092d 91, 092e 82, 092f 342 linhas (código movido, 5 arquivos), nenhuma passa de 450; o maior arquivo da economia agora tem **258** linhas de código (`goods_store.gd`).

### O que conferi e está certo
As três pontas e a junção compilam e passam no `check_all` (a 092g está acima), com os mesmos `Warnings 1` e `Deprecated 1` de sempre; `ShortageDeclared`, preços, produção e save **não mudaram** (nenhum teste da economia foi alterado além dos autorizados); as classes novas de `support/` não são citáveis de fora (regra E) e o módulo continua sendo a única classe da `api/` que o resto do jogo vê; o `LW-092f` registrou o que fez no `README` da economia.

### O QUE NÃO CONSEGUI VERIFICAR (R4)
- **A autorização** da C para os rótulos "aprovado" (R4-I1) e para editar `DECISIONS.md` e o roadmap (como na R2).
- **Comportamento da 092f que nenhum teste cobre:** conferi por leitura e pelo `Asserts` idêntico, mas não escrevi testes novos nem exercitei o save de um jogo longo.
- **A 092g em pontos fora do `economy_module.gd`:** comparei a **árvore** com a minha junção simulada (iguais no código); **não li** o diff de `docs/modules/economy.md` e do `README` da junção linha a linha (só vi que existem e que o `check_all` passa).
- **Os ramos `lw-093-*`**, que não estavam no alvo.
- **A 117g contra o GDD e a arquitetura** (como nas revisões anteriores) e **o conteúdo integral** do `DECISIONS.md` da 117g (li só as sete entradas novas, o cabeçalho e os totais).
- Os resultados de execução valem **para o conteúdo dos commits** (cópias exportadas), não para o estado dos worktrees da A.

---

## ACOMPANHAMENTO DA R4
**Nada foi alterado em nenhum ramo** da A, da C nem no `main` (só leitura; as cópias e as simulações ficaram na pasta temporária). **Não repassei nada às conversas A e C.**
**Decisões que dependem de você:** (1) confirmar se o lote da Fase 4 já está aprovado (R4-I1); (2) autorizar a troca do caminho do caso em `tests/test_check_architecture.sh` (R4-M5); (3) estorno com motivo próprio e ator antes das regras (R4-M1 e R4-M2): recomendo as duas, nenhuma urgente.
**Próxima tarefa recomendada:** a **Fase B da A** (levar a 092g ao `main`, depois de você confirmar o resultado do `check_all` dela) e a **117h da C**; a 146g **só** depois da LW-117 no `main` e do seu "vá". **Não iniciadas.**
**Git:** só este commit no `status-b` (`STATUS-B.md`), avanço simples, sem tag.


## REVISÃO R5 — a LW-117h da C e a entrada da LW-117 (117a a 117h) no `main` `0e20369` (11/11/2026, papel de revisor, AGENTS seção 11; só leitura, nada implementado)

**Em uma frase:** a 117h aplicou **as nove recomendações da R3** (mais os três desvios, registrados no `0016`) e a junção da C no `main` está **limpa** (nenhum marcador de conflito, nada da A nem da Fase 5 perdido, catálogo com **58 eventos sem repetição**, DEC 1 a 233 contínuas e sem colisão, totais certos, `check_all` verde); achei **um defeito de marcação na DEC-053** e **três coisas que dependem de mim ou de você**; nada bloqueante.

**Alvo e método.** `origin/main` = `0e20369` ("LW-117h: status da Fase B"), que contém `459e186` (a 117h: "ajustes da revisão R3 e registro dos 3 desvios"), `b1db754` (a junção com `d1d3d8b`) e as partes 117a a 117g (12 commits sobre `d1d3d8b`, entrada por **avanço rápido**: `d1d3d8b` é ancestral). Exportei o `main` para a pasta temporária (`git archive`; nenhum checkout nem worktree) e conferi **por script**: marcadores de conflito, linhas e células de `docs/events.md`, continuidade, duplicidade, status e totais das DEC, títulos repetidos, citações cruzadas de `npc.md`, e o que a junção **removeu** contra `d1d3d8b` (linha a linha). Rodei o `tools/check_all` na cópia. Li o `0016` inteiro e as linhas novas da 117h nas seis fichas.

### A entrada no `main`
- **Execução:** `check_all` na cópia do `main` `0e20369`: **VERDE**, código 0 (19:15:15 a 19:19:34), `Scripts 142`, `Tests 1293`, `Passing 1293`, `Asserts 292694` (**idênticos aos de `d1d3d8b`**, como devia ser, porque só entraram documentos), `Warnings 1` e `Deprecated 1` iguais; "nove verificações aprovadas"; "IDS DE CONTEÚDO: tudo existe (51)".
- **Protegidos:** a entrada toca **`docs/DECISIONS.md`** e **`docs/DEVELOPMENT_ROADMAP.md`** (as outras 15 alterações são de contratos, catálogo, registros e status); nenhum arquivo de código, `data/`, `project.godot`, `addons` ou `tests/fixtures`. **Eu não consigo ver a sua autorização para essa Fase B** (o `ROADMAP_STATUS` diz que foi "pela Fase B, sem tag"; as **tags** continuam só `fase-0`, `fase-1` e `fase-2`).
- **Nada da A nem da Fase 5 foi perdido:** contra `d1d3d8b`, o `npc.md` (+90) e o `world.md` (+28) e o `economy.md` (+116) **só ganharam linhas**; `events.md` perdeu 10 linhas: **8 linhas de evento** reescritas com campos novos e os 2 parágrafos do cabeçalho; e as **minhas** seções 15 do `npc.md` e "Extensão da Fase 5" do `world.md`, os 11 eventos da Fase 5, o A1 a A6 do `app.md` e as notas da 146a continuam. Linha do `NpcDied`: **a da A** (a economia o ouve, "implementado") **com a carga da C** (`battle` e `combat`). As 5 linhas de economia seguem `implementado, LW-090b` e `LW-092b`.
- **Catálogo:** **58 linhas, 58 nomes distintos, nenhum repetido, nenhuma com número de células errado**; o cabeçalho (58 = 6 + 10 + 11 da Fase 5 + 31 da Fase 4) **bate com a conta** (a previsão da C e a minha da R3 se confirmaram).
- **DEC:** definidas **233, contínuas de 1 a 233**, nenhuma repetida no índice, **nenhum status mudou** em DEC que já existia; totais **APROVADA 151 (20 com ressalva, que conferi) · PROPOSTA 54 · PENDENTE 17 · DESCARTADA 10 · SUBSTITUÍDA 1 = 233, exatamente a conta do cabeçalho** (conferi também as 13 entradas "APROVADA (somente…)" que um primeiro leitor simples não pega). "**Próximo número livre: `DEC-234`**" e as faixas (**A 234 a 239, B 240 a 259, C 260 a 279**) estão escritas, **como você definiu**; DEC-213 a DEC-223 **seguem PROPOSTA** e o cabeçalho registra que as DEC-227 a DEC-233 foram "confirmadas por Arthur por escrito". **Isso fecha o R4-I1** na parte das DEC (continuo sem ver a sua mensagem à C).

### As nove recomendações da R3 e os três desvios
| R3 | Aplicada? | Onde |
|---|---|---|
| I1 `peek_npc_ids` | **Sim** | `npc.md:370` (`peek_npc_ids_of(occupation_id, settlement_id)`); `factions.md:52` diz que o sem argumento "já existe, é outro" |
| I2 seção 15 do `npc.md` | **Sim** | a da Fase 4 virou **16** (`npc.md:344`, subseções 16.1 a 16.10); **28 citações "`npc.md` 15 ou 16" conferidas, nenhuma aponta para seção inexistente**; as 4 que ainda dizem 15 em `events.md` são as **minhas** (Fase 5) e existem |
| I3 `ActReported` | **Sim** | `politics.md` seção 4 (entrada normalizada, **adaptador da `politics`** na Fase 5) e `act_sources.json` em `dados.md`; linha 35 do catálogo |
| I4 morte em combate | **Sim** | `npc.md` 16.8 (`battle` e `combat`, "um caminho só"), `military.md` |
| I5 `request_set_on_mission` | **Sim** (117g) | 3 argumentos em `npc.md` e `military.md` |
| I6 `content_id` | **Sim** | `peek_faction_id_of` e `peek_polity_id_of` (`factions.md:88`, `politics.md:95`; `military.md` os usa para `force_seed.owner_id`) |
| I7 `work_place_id` | **Sim** | `dados.md`: linhas novas **sem a coluna**, ordem dos dados escrita, "o verificador não é alterado aqui" (como você mandou) |
| I8 DEC | **Sim** | acima |
| I9 ordem de registro | **Sim, nas fichas da C** | as quatro fichas dizem a mesma ordem única: `character, economy, npc, ecology, factions, politics, combat, military, events`; **o `app.md` A2 (meu) ainda tem a ordem antiga** |
| M2, M3, M4, M8 | **Sim** | T3 e "testemunha" × "observação de item" (`npc.md` 16.6), `faction_doctrine.json` em `factions.md`, `cultures.json` em `data/world/`, colunas novas do `check_content_ids` em `dados.md`, linhas da Fase 5 do `chronicle.json` (marcadas como "que este arquivo ainda não tem") |
Os **três desvios** (`0016`, no formato do AGENTS 16.3 com regra afetada, problema real, opções, recomendação e impacto): (a) o **país tem ID próprio** (`polity_id`; diverge da arquitetura 13.2, arquivo protegido **não alterado**), (b) a `politics` importa **4** módulos e (c) o `military` importa **5** (6 com o `combat` na Fase 5); o registro diz "**aprovado por Arthur em 11/11/2026**, por autorização escrita na LW-117h", e que a LW-144 os reavalia.

### BLOQUEANTES
Nenhum.

### IMPORTANTES
Nenhum **novo**. O que segue importante já estava aberto e **é meu ou seu**:
- **R5-I1 (meu, 146g). A Fase 5 ainda diz o contrário da decisão 4 da R3.** `combat.md:92` e a minha linha do `CombatantDied` no catálogo ainda listam o **`npc` como ouvinte** do evento; pela decisão (e pelo `npc.md` 16.8) o `npc` **não** o ouve: o `combat` chama `request_apply_casualty` com o motivo `combat`. Junto com o `app.md` A2 (ordem única), o `request_set_route_state` com `cause_id` opcional e `hostile_force` (DEC-229: o `world.md` da Fase 5 ainda diz "só `world_event`" e sem causa), o T3 já confirmado (minha 15.2 diz "[A CONFIRMAR]") e a extensão da economia, **é o que a 146g tem de corrigir**; nada disso está no `main` ainda.
- **R5-I2 (seu, a DEC do I4).** O adaptador de crime da `politics` e a economia **ouvem evento por nome e leem a carga por campo** (`politics.md` seção 4: "ouve por nome"; `economy_module.gd:351` no `main` lê `npc_id`, e a linha 222 na 092f): é a **exceção à regra 4.17 do AGENTS** que a A prometeu propor (DEC **234 a 239**). Enquanto não houver essa DEC, as duas fichas dependem de uma exceção que **não está aprovada**.

### MENORES
- **R5-M1. Marcação quebrada na DEC-053 (efeito da junção).** `DECISIONS.md:1023` (linha "Consequências" da DEC-053): onde as duas notas se encontraram, o `**` que abria a nota da LW-146a virou ` |*` e a linha acabou com **5 `|` em vez de 3** (`… (DEC-054 aprovada em 10/11/2026) |*Nota de 11/11/2026 (LW-146a):** … |*Nota de 11/11/2026 (LW-117a):** … |`). **O texto das duas notas está íntegro**; a tabela é que renderiza com colunas a mais e o negrito partido. Varri o arquivo: **é a única** (`|*Nota` aparece uma vez). Conserto de uma linha: restaurar `**Nota …**` nas duas, sem `|` no meio. Como é arquivo protegido, **você autoriza** (ou a C numa próxima rodada).
- **R5-M2. Rótulo "aprovado por Arthur" nos cabeçalhos das fichas.** As seis fichas (e o `0016`) dizem "PLANEJADO, aprovado por Arthur em 11/11/2026, com os ajustes da 117g e da 117h"; **dentro** delas os itens da R3 estão marcados `[PROPOSTA]` (e você me disse "PROPOSTA de trabalho"). Os dois rótulos convivem e quem lê só o cabeçalho toma tudo por aprovado; o `DECISIONS.md` registra a confirmação só das **DEC-227 a DEC-233**.
- **R5-M3. Eventos implementados com campo novo previsto.** O catálogo põe `settlement_id` em `PriceChanged`, `ShortageDeclared` e `ShortageEnded` ("Fase 4, LW-117f"), mas as três classes **já existem no código** da A sem esse campo (LW-090b): a LW-126 vai mudar evento já catalogado e implementado (AGENTS 16.2: parar e perguntar). Vale uma linha no contrato da economia da A.
- **R5-M4. Texto velho do catálogo, da A.** A linha do `PriceChanged` ainda diz "ouvintes: nenhum hoje (**não existe no código**)" com situação "implementado, LW-090b" (contradição que já vinha da A, não da junção).
- **R5-M5. `peek_personality`** continua no `npc.md` 16.3 embora o `peek_npc` já devolva `traits` (R3-M5, ficou como pergunta).
- **R5-M6. Previsão para a Fase B da A:** levar a **092g** ao `main` atual dá **1 trecho em conflito só, em `docs/backlog.md`** (os dois lados acrescentam no fim); `economy.md` e o código **mesclam sem conflito** (previsão por `merge-tree`, não executei).

### O que conferi e está certo
O avanço rápido do `main`, sem merge commit no topo do `main` além do `b1db754`; **sem marcador de conflito em nenhum arquivo do repositório**; sem título repetido em `npc.md`, `world.md`, `economy.md`, `events.md` e roadmap; o parágrafo "Considerados e não incluídos" diz que o `NpcTierChanged` **entrou na Fase 5**; as linhas do `ROADMAP_STATUS` e do `backlog` da entrada falam de 233 DEC, versão 0.15 e "sem tag"; o `0016` segue o formato do AGENTS 16.3.

### O QUE NÃO CONSEGUI VERIFICAR (R5)
- **A autorização** para a Fase B da C (inclui `DECISIONS.md` e o roadmap) e para os rótulos "aprovado" e "confirmado por Arthur por escrito": **não vi essas mensagens**.
- **O conteúdo integral** de `DECISIONS.md` (233 entradas) e do roadmap: conferi estrutura, status, totais e o que a junção **removeu**; **não reli** cada entrada nova nem comparei o roadmap linha a linha com a arquitetura.
- **As fichas da Fase 4 contra o GDD e a arquitetura** (como nas revisões anteriores) e o `0013` e o `dados.md` por inteiro (li as partes que as correções da R3 tocam).
- **Se o `check_architecture` já tem as regras novas** que as fichas propõem (só o `military` e o `combat` chamam `request_apply_casualty`, só a `factions` promove a T3): são propostas, **não existem**.
- As execuções valem para o **conteúdo do commit** (cópia exportada), não para os worktrees.

---

## ACOMPANHAMENTO DA R5
**Nada foi alterado em nenhum ramo** nem no `main` (só leitura; a cópia e os scripts ficaram na pasta temporária). **Não repassei nada às conversas A e C.**
**Decisões e pedidos para você:** (1) **autorizar o conserto de uma linha da DEC-053** (R5-M1), por mim ou pela C; (2) **a ordem das próximas entradas**: a **092g** da A (conflito só no `backlog`) e depois a **146g** minha, que **só começa quando você mandar** (a condição da LW-117 no `main` **já foi cumprida**); (3) quando a A mandar a DEC do I4 (234 a 239), ela destrava o R5-I2.
**Próxima tarefa recomendada:** a **146g** (economia da Fase 5 e a correção do que listei no R5-I1) e a **Fase B da A** com a 092g. **Não iniciadas.**
**Git:** **nenhum commit nem push.** Este relatório está só no arquivo `STATUS-B.md` do worktree `status-b` (alteração **não commitada**). Mensagem de commit sugerida: `status b: revisão R5 (117h e a entrada da LW-117 no main)`.


## RELATÓRIO — LW-146g: extensões da economia da Fase 5, comandos dos eventos de mundo e correções das fichas     Status: PRONTA PARA REVISÃO

**Antes de começar (AGENTS 2.3).** Declarei no chat: a tarefa; o que li; as DEC de que dependo e o status de cada (nenhuma PENDENTE: DEC-156, 181 e 183 APROVADAS; DEC-188, 189, 193, 195, 197 e 199 PROPOSTA); os arquivos; e as duas dúvidas de design. Você respondeu pelo painel: **venda de item = recompra simples (a versão completa fica para depois)**, **três comandos novos para os 4 tipos de evento da Fase 4** e **Git: "ramo, commit e push"** (ramo `lw-146g-extensoes` a partir de `origin/main` `0e20369`, **um commit**, push só desse ramo e do `status-b`, sem merge no `main`, sem tag, sem force).

### 1. RESUMO
Escrevi, **só em texto**, o que a Fase 5 ainda pedia da economia e dos outros módulos: a seção 18 do `economy.md` (monte no chão, metal forjado, modificador de produção e recompra de item), os três comandos que faltavam para os 4 tipos de evento de mundo que dependem da Fase 4 (`politics`, `npc` e `factions`), e as correções que você mandou depois da R3 e da R5 (`combat.md`, `world.md`, `app.md`, `npc.md`, `ecology.md`, catálogo). Nada de código, dados, GDD, arquitetura, AGENTS, `DECISIONS.md`, roadmap, `project.godot` nem módulos.

### 2. ARQUIVOS CRIADOS
Nenhum.

### 3. ARQUIVOS MODIFICADOS (13, todos em `docs/`; +147 −42; commit `a9fd5c1`)
- `docs/modules/economy.md` (+87): **seção 18 nova**, no fim (como a 17), com 18.1 a 18.9 (resumo, monte, metal, modificador, recompra, conservação e save, dado → dono, rastreio por tarefa e pontos em aberto). As seções existentes **não foram editadas**.
- `docs/modules/npc.md` (15.2, 15.6, 15.7; **15.8 e 15.9 novos**): T3 confirmado; o NPC pega do monte; o **boato nascido de evento de mundo** (`request_seed_rumor`) e o pedido de `cause_id` opcional em `request_apply_casualty`.
- `docs/modules/politics.md` e `docs/modules/factions.md`: **`request_apply_stability_modifier`**/`request_remove_stability_modifier` (seção 6) e **`request_raise_tension`** (seção 7), com os códigos de erro novos; `ItemSold` no adaptador do crime.
- `docs/modules/character.md`: a venda de item único **fechou** (E4): `peek_item_value`, a causa `sale` e o `ItemSold`; lista de extensões e de pontos em aberto atualizada.
- `docs/modules/combat.md`, `world.md`, `app.md`, `ecology.md`, `dynamic_events.md`: as correções da R3 e da R5 (abaixo).
- `docs/events.md` (**58 → 60 eventos**: `GoodsForged` e `ItemSold`; ouvintes do `CombatantWounded` e do `CombatantDied`), `docs/fase-4/dados.md` (`ItemSold` e a coluna `require_field` em `act_sources.json`) e `docs/backlog.md` (5 ideias para "depois").

### 4. DECISÕES TÉCNICAS (todas **PROPOSTA**; nenhuma entra em `DECISIONS.md` por mim)
- **Correções que você já tinha decidido.** (a) `combat.md` e catálogo: o `npc` **não** ouve o `CombatantDied`; o `combat` chama `request_apply_casualty(npc_id, "combat")` (R3-I4, R5-I1); (b) `world.md`: `request_set_route_state(route_id, new_state, reason, cause_id = NO_CAUSE)`, `reason` = `world_event` ou `hostile_force` (DEC-229, APROVADA); (c) `app.md` A2: a **ordem única de registro** (`character, economy, npc, ecology, factions, politics, combat, military, events`) e A5: a tabela dos 8 tipos com o comando de cada um; (d) `npc.md` 15.2: T3 confirmado; (e) `ecology.md`: sem campo `secret`, a visibilidade é por tipo (`peek_visible` e `peek_points_within`).
- **Monte no chão (18.2).** Tipo de dono `ground_pile` (só inventário, sem saldo); a economia o abre (`request_open_pile(x_cm, z_cm)`), os bens entram e saem por `request_transfer_goods`; **some em 24 horas [HIP]** com o motivo `spoiled` e é fechado; teto `max_piles`; consultas `peek_pile` e `peek_piles_near`. **Sem evento** (de propósito). *Alternativa:* um monte por bem ou um evento por queda (mais eventos, sem ganho).
- **Metal forjado (18.3).** Motivo novo `forged` e `request_forge_goods(owner_id, good_id, quantity, item_def_id)`, só bens de uma lista em dados (partida: `metal`) e só o jogador; publica `GoodsForged`; o `character` ouve e cria a instância. A economia repassa o `item_def_id` sem conhecer o item. *Alternativa:* o `character` importar a economia (quebra a fronteira da DEC-193).
- **Modificador de produção (18.4).** `request_apply_production_modifier(settlement_id, good_id, factor_bp, source_id, days)` e o `remove`; **idempotente por `source_id`**, vence sozinho; só reduz (0 a 10000); entra no progresso do lote, **não** é parada. *Alternativa:* mexer na eficiência (mistura com a manutenção).
- **Recompra de item (18.5; sua escolha).** Três chamadas da ponte, **nesta ordem**: `character.peek_item_value` → `economy.request_buy_back` (o mercado paga `valor × buyback_bp`, motivo `item_sale`, só transfere) → `character.request_transfer_item(..., sale)` (o item **some** e sai o `ItemSold`, com a marca de origem). O crime por marca é da `politics`, pelo adaptador. **Sem revenda nem estoque de instâncias**; a versão completa foi para o backlog, como você pediu.
- **Comandos dos 4 tipos da Fase 4.** `unrest`: modificador de estabilidade (quinta entrada da conta, antes da inércia e da histerese); `messenger_visit` e `ruin_rumor`: `request_seed_rumor(settlement_id, source_event_id, event_name, confidence_bp, subject_id)`, boato sem fato presenciado, sem efeito na reputação; `border_dispute_escalation`: `request_raise_tension(province_id, amount, reason, cause_id)`, em que **a `factions` escolhe o par** (as duas de mais influência) e o motivo é só `world_event`. Todos **só valem quando os módulos da Fase 4 existirem**.
- **Proposta de entrada para `DECISIONS.md` (faixa B, 240 a 259; sugestão, quem registra é você ou a conversa que você mandar).** **DEC-240:** *Venda de item único por recompra simples* (contexto: a economia só negocia bens; decisão: o mercado paga e o item some; justificativa: o mais simples que dá lugar ao crime por marca; consequências: motivo `item_sale`, evento `ItemSold`, tarefa nova antes da LW-165b). **DEC-241:** *Três comandos de efeito dos eventos de mundo nos módulos da Fase 4* (`request_apply_stability_modifier`, `request_seed_rumor`, `request_raise_tension`). **DEC-242:** *Morte de NPC em combate por um comando só* (`request_apply_casualty` com o motivo `combat`, e o `cause_id` opcional nele e na rota). **DEC-243:** *Ordem única de registro dos módulos no `World`.*
- **Pedido de desvio:** nenhum.

### 5. TESTES EXECUTADOS
- `tools/check_all` (worktree `lw-146x`, commit final `a9fd5c1`): **VERDE**, código 0 (19:33:35 a 19:37:53): `Scripts 142`, `Tests 1293`, `Passing Tests 1293`, `Asserts 292694`, 192 s; `Warnings 1` e `Deprecated 1` iguais aos de sempre; "IDS DE CONTEÚDO: tudo existe (51 conferências)". *(Só mudaram documentos; o resultado confirma que nada quebrou.)*
- `git diff --check`: limpo. **Conferências por script:** as citações "`economy.md` 18.x" e "`npc.md` 15.x" apontam todas para subseção que existe; **nenhum dos 26 nomes novos** (comandos, consultas, eventos, motivos e códigos) existe no código, nos dados ou nos testes do `main`, nem nos ramos `lw-092g`, `lw-093d`, `lw-093e` e `lw-093g` da A; o catálogo tem **60 eventos, 60 distintos, todas as linhas com 6 células**.
- **Previsão de merge (não executei):** com a 092g e com os três ramos `lw-093*` da A, **só `docs/backlog.md` conflita** (os dois lados acrescentam no fim); `economy.md` e o resto mesclam.

### 6. RESULTADOS
`check_all` verde, 1293 de 1293. **Critério de aceite (documentos):** as extensões existem e dizem quem implementa, os testes previstos e o que fica em aberto; as correções da R3 e da R5 estão feitas; só os 13 arquivos autorizados mudaram (conferi com `git diff --name-only`); **nenhum arquivo de código ou protegido** foi tocado.

### 7. PROBLEMAS ENCONTRADOS
1. **Editei texto das fichas da C** (`politics.md`, `factions.md`, `dados.md` e o `npc.md` 16.7 por referência): os três comandos novos **são** extensões dos módulos dela. Estão marcados como PROPOSTA e dentro de blocos "LW-146g", mas **a conversa C deve saber**.
2. **A morte de NPC em combate pede mais um ajuste à C:** o `cause_id` opcional em `request_apply_casualty` (npc 16.8). Pedi em `npc.md` 15.9; a C ainda não o tem.
3. **A exceção da regra 4.17** (ouvir evento por nome) sustenta o `GoodsForged` e o adaptador do crime; **segue sem DEC** (a conversa A vai propor, faixa 234 a 239).
4. **`DECISIONS.md` linha 1023 (DEC-053)** continua com a marcação quebrada que apontei na R5: é arquivo protegido e **não toquei**.
5. A economia agora tem **três blocos empilhados** (seções 3 a 16 da A, 17 da C e 18 minha) sem a união final: ficou como a 17 deixou, e os leitores precisam ler os três.

### 8. RISCOS
Tudo é **PROPOSTA**: nomes e números ([HIP]) trocam sem custo. Os quatro tipos de evento da Fase 4 ficam **desligados** até o código da Fase 4 existir. A recompra precisa de uma **tarefa nova** no roadmap (protegido, é sua) antes da LW-165b. O `GoodsForged` e a venda cruzam três módulos pela **ponte**: se a ordem das chamadas não for seguida, o metal ou o item se perde (a ordem está escrita).

### 9. PENDÊNCIAS
**Decisões suas, com a minha recomendação** (18.9): (1) **quais bens em quantidade caem ao morrer** (recomendo todos, num monte, nenhum dinheiro); (2) **saque de bem de NPC morto** (muda a DEC-146; recomendo só instâncias); (3) **NPC ferreiro** (recomendo só o jogador agora); (4) **registrar a tarefa nova da recompra** no roadmap; (5) a DEC do I4; (6) o conserto da linha da DEC-053. **Testes manuais:** nenhum (só texto).

### ACOMPANHAMENTO
- **Avanço:** pré-voo e contratos da Fase 5 **no `main`** (146a a f) e agora **o resto em revisão** (146g, no ramo, fora do `main`). Código da Fase 5: **0%**.
- **Próxima tarefa recomendada:** a **Fase B da 146g** (levar o ramo ao `main`), só com a sua frase de aprovação e o passo a passo. Não iniciada.
- **Git:** **um commit**, `a9fd5c1` ("LW-146g: economia da Fase 5 (monte, metal, modificador, recompra), comandos dos eventos de mundo e correções das fichas"), com `Co-Authored-By`, no ramo `lw-146g-extensoes` (a partir de `0e20369`, **sem upstream**). Push **só** de `lw-146g-extensoes` e de `status-b`, por `ramo:ramo`. Nada no `main`, nenhuma tag, sem force, rebase ou reset.


## FASE B — LW-146g no `main` (11/11/2026, autorizada por escrito por Arthur: "Sim nos itens 1 a 5, sem tag")

**Efeito:** o `main` agora tem a seção 18 do `economy.md` (monte no chão, metal forjado, modificador de produção e recompra de item), os três comandos dos eventos de mundo da Fase 4 (`politics`, `npc` e `factions`), as correções das fichas (`combat`, `world`, `app`, `npc`, `ecology`, `character`, `dynamic_events`) e o catálogo com **60 eventos**. Só documentos; nenhum código mudou.

**Passos, com o que vi:**
- **B0:** `git fetch --all --tags --prune`; `origin/main` seguia em `0e20369`; o ramo `lw-146g-extensoes` (`a9fd5c1`) descende dele: avanço rápido possível, **sem merge e sem conflito** (o `docs/backlog.md`, que eu previa em conflito com os ramos da A, só conflitaria **com eles**, não com o `main`).
- **B1:** um commit, `a07492c` ("LW-146g: Fase B, linha de entrada no ROADMAP_STATUS"), só com `docs/ROADMAP_STATUS.md` (+2 linhas: o parágrafo e a linha em branco antes dele). Diz que a 146g entrou no `main`, sem tag, e que **fecha a pendência da LW-146f parcial**; **não altera contagens nem porcentagens**. `git diff --check` limpo. Commit com `Co-Authored-By`.
- **B2:** `tools/check_all` **uma vez**, no commit final `a07492c` (a primeira linha da saída o confirma): **VERDE**, código 0 (19:40:55 a 19:44:57), `Scripts 142`, `Tests 1293`, `Passing Tests 1293`, `Asserts 292694`, `Time 179,45 s`; `Warnings 1` e `Deprecated 1` iguais aos de sempre; "IDS DE CONTEÚDO: tudo existe (51 conferências)"; nenhum `SCRIPT ERROR` nem `Parse Error`. Havia **outro processo do Godot** rodando no Mac no início (de outra conversa, provavelmente); o resultado não foi afetado.
- **B3:** `git fetch` de novo: `origin/main` ainda em `0e20369`. Push do ramo `lw-146g-extensoes:lw-146g-extensoes` (`a9fd5c1..a07492c`) e depois `lw-146g-extensoes:main` (`0e20369..a07492c`), **na primeira tentativa**, só avanço rápido, sem `--force`. Conferi depois: `origin/main` = `origin/lw-146g-extensoes` = `a07492c`. **Tags:** nenhuma criada (as remotas continuam `fase-0-concluida`, `fase-1-concluida` e `fase-2-concluida`).

**Não fiz:** `--force`, rebase, reset, stash, tag, apagar ramo; nada em `DECISIONS.md`, GDD, arquitetura, AGENTS, roadmap, `project.godot`, `data/`, código nem módulos.

**Pendências que seguem abertas (da seção 18.9 e do relatório da 146g), todas suas:** os bens em quantidade que caem ao morrer; o saque de bem de NPC morto (DEC-146); o NPC ferreiro; a **tarefa nova da recompra** no roadmap; a DEC do I4 (conversa A); o conserto da linha da DEC-053 (`DECISIONS.md:1023`). **A conversa C ainda não sabe** que editei `politics.md`, `factions.md` e `dados.md` (blocos "LW-146g") nem do pedido do `cause_id` opcional em `request_apply_casualty` (`npc.md` 15.9): **não repassei nada**.

**Git:** `main` em `a07492c` (dois commits novos: `a9fd5c1` e `a07492c`); o ramo `lw-146g-extensoes` ficou igual ao `main`.


## LW-146h e FASE B — dados da Fase 5 no `main` (11/11/2026, autorizada por escrito por Arthur: "Aprovo, Fase B" e, no painel, "Sim, itens 1 a 5, sem tag")

**Efeito:** o `main` agora tem `docs/fase-5/dados.md` (264 linhas, só documento): colunas, tipos, faixas, regras de validação e linhas de partida de **27 tabelas novas** da Fase 5 (6 de `combat`, 9 de `character`, 4 de `ecology`, 1 de `world`, 3 de eventos dinâmicos e 4 de `economy`), mais colunas e linhas novas em tabelas que já existem. Nenhum código nem dado mudou. **A tarefa:** a LW-146h não existia nos documentos; Arthur a definiu no painel como "Dados da Fase 5". O documento termina com **15 pontos para ele decidir** (seção 9), cada um com recomendação; os de maior peso são o **5** (o que o nível de cada habilidade faz no jogo; decisão de jogo), o **9** e o **10** (o que ficou sem linha por falta de decisão: arco e munição, efeito de "ferido", minério escondido, onde começa quem vem da estrada, visibilidade de `outpost`, `camp` e `respawn`) e o **13** (as ações `fight`, `surrender` e `take_item` pedem uma extensão de contrato do `npc` antes da LW-155).

**Passos, com o que vi:**
- **Antes (autorizado: "Ramo, commit e push"):** ramo `lw-146h-dados-fase-5` a partir de `origin/main`, sem upstream; commit `aad7be9` só com `docs/fase-5/dados.md`; push do ramo por refspec explícito.
- **B0:** `git fetch --all --tags --prune`; `origin/main` seguia em `a07492c`; o ramo descende dele: avanço rápido possível, **sem merge e sem conflito**.
- **B1:** um commit, `7efbb84` ("LW-146h: Fase B, linha de entrada no ROADMAP_STATUS"), só com `docs/ROADMAP_STATUS.md` (+2 linhas: o parágrafo e a linha em branco antes dele). Diz que a 146h entrou no `main`, aprovada por Arthur, sem tag; que os nomes de campos e de arquivos seguem PROPOSTA, todo número segue [HIP] e os 15 pontos seguem como recomendações; e que **não altera contagens nem porcentagens**. `git diff --check` limpo. Commit com `Co-Authored-By`.
- **B2:** `tools/check_all` **uma vez**, no commit final `7efbb84` (a primeira linha da saída o confirma): **VERDE**, código 0 (20:31:05 a 20:35:36), `Scripts 142`, `Tests 1293`, `Passing Tests 1293`, `Asserts 292694`, `Time 205,9 s`; `Warnings 1` e `Deprecated 1` iguais aos de sempre; "IDS DE CONTEÚDO: tudo existe (51 conferências)"; **0** `SCRIPT ERROR` e **0** `Parse Error`. A saída tem 68 linhas `ERROR` e 9 com "falhou/failed": comparei com a rodada da 146g e são **idênticas, tipo por tipo e em contagem** (mensagens que os testes provocam de propósito, como "recusado de propósito", e nomes de teste); o número de verificações é o mesmo, como esperado para uma mudança só de documentos.
- **B3:** `git fetch` de novo: `origin/main` ainda em `a07492c`. Push do ramo `lw-146h-dados-fase-5:lw-146h-dados-fase-5` (`aad7be9..7efbb84`) e depois `lw-146h-dados-fase-5:main` (`a07492c..7efbb84`), **na primeira tentativa**, só avanço rápido, sem `--force`. Conferi depois: `origin/main` = `origin/lw-146h-dados-fase-5` = `7efbb84`. **Tags:** nenhuma criada (as remotas continuam `fase-0-concluida`, `fase-1-concluida` e `fase-2-concluida`).

**Problemas que tive (todos meus, sem efeito no resultado):**
1. **Lancei o `check_all` duas vezes por engano.** O primeiro lançador, que eu achava morto, sobreviveu; o segundo, que lancei depois, ficou na fila (o script espera o Mac ficar sem Godot). Encerrei a **segunda** cadeia (processos 53944 e 53950) antes de ela começar a rodar; **só uma** execução do `check_all` aconteceu, e é a da cadeia original, no commit `7efbb84`. Encerrei também um vigia meu que ficaria esperando para sempre.
2. **Havia um `check_all` de outra conversa** rodando ao mesmo tempo, em outra árvore de processos (não é meu; não mexi nele). Como na 146g, o resultado não foi afetado: é o mesmo número de testes e de verificações.
3. **O cabeçalho do `docs/fase-5/dados.md` está desatualizado no `main`:** ele ainda diz "PROPOSTA da LW-146h, aguardando a aprovação de Arthur", enquanto o `ROADMAP_STATUS.md` diz que a 146h entrou aprovada. Eu **não** o alterei: seu item 3 autorizava **uma** linha só no `ROADMAP_STATUS.md`. **Proposta (precisa da sua autorização):** trocar só a palavra de estado do cabeçalho, em um commit de uma linha, na próxima parte da série.

**Não fiz:** `--force`, rebase, reset, stash, tag, apagar ramo; nada em `DECISIONS.md`, GDD, arquitetura, AGENTS, roadmap (`DEVELOPMENT_ROADMAP.md`), `project.godot`, `data/`, código, módulos nem fichas de contrato. O `main` do seu clone principal (`/Users/arthurlk/LivingWorld`) **não foi atualizado por mim**: só o `origin/main` mudou.

**Pendências, todas suas:** os 15 pontos da seção 9 de `docs/fase-5/dados.md`; o conserto de uma linha da DEC-053 (`DECISIONS.md:1023`); a **tarefa nova da recompra** no roadmap; a DEC do I4 (conversa A); os bens em quantidade que caem ao morrer, o saque de bem de NPC morto (DEC-146) e o NPC ferreiro (da 146g). A conversa C ainda não sabe das mudanças que a 146g fez nas fichas dela; **não repassei nada**.

**Git:** `main` em `7efbb84` (dois commits novos: `aad7be9` e `7efbb84`); o ramo `lw-146h-dados-fase-5` ficou igual ao `main`.
**Próxima tarefa recomendada:** a extensão do contrato do `npc` para as condições de combate (ponto 13), antes da LW-155, **só quando você mandar**. Não iniciada.


## BLOCO B v4 — item 1 (ajuste de uma palavra no `dados.md`) e revisões R6 e R7 (11/11/2026; o "bloco B v3" ficou superado, como o Arthur mandou)

**Autorizado por escrito por Arthur:** (1) trocar a palavra de estado do cabeçalho do `docs/fase-5/dados.md`, **um commit de uma linha**, `check_all` verde e **avanço simples ao `main`** (B0 a B3 curtos, sem tag); (2) duas revisões **só de leitura** (R6 e R7); **commit e push do `status-b`**. "Nada mais: sem outros ramos, sem merge, sem tag, sem `--force`, sem apagar ramo."

### Item 1 — o ajuste no `main`
**Efeito:** o cabeçalho do `docs/fase-5/dados.md` (linha 3) agora diz "**PROPOSTA da LW-146h, aprovada por Arthur em 11/11/2026 (nomes e números seguem PROPOSTA e [HIP])**". Resolve o problema 3 que eu tinha registrado na Fase B da 146h. **Nenhuma outra palavra de nenhum documento mudou** (o `ROADMAP_STATUS.md` não foi tocado). **Como li a ordem:** a frase pedida ("PROPOSTA, aguardando a aprovação de Arthur") não existe literalmente (o texto era "PROPOSTA da LW-146h (11/11/2026), aguardando a aprovação de Arthur."); troquei só o estado, **mantive "da LW-146h"** e tirei a data duplicada de dentro dos parênteses, porque agora ela aparece na frase nova.
- **B0:** `git fetch --all --tags --prune`; `origin/main` seguia em `7efbb84`; o ramo local `lw-146h-dados-fase-5` (que já existia e estava igual ao `main`) descende dele. **Não criei ramo novo.** Um commit, `ca86f87` ("LW-146h: cabeçalho do dados.md com o estado aprovado por Arthur"), **+1 −1 em 1 arquivo**, com `Co-Authored-By`; `git diff --check` limpo.
- **B2:** `tools/check_all` **uma vez**, no commit final `ca86f87` (a primeira linha da saída o confirma): **VERDE**, código 0 (20:57:45 a 21:01:56), `Scripts 142`, `Tests 1293`, `Passing Tests 1293`, `Asserts 292694`, `Time 187,2 s`; `Warnings 1` e `Deprecated 1` iguais aos de sempre; "IDS DE CONTEÚDO: tudo existe (51 conferências)"; **0** `SCRIPT ERROR` e **0** `Parse Error`; as 68 linhas `ERROR` e as 9 de "falhou/failed" são **idênticas, tipo por tipo**, às da rodada anterior (mensagens que os testes provocam de propósito). Havia `check_all` de **outras conversas** rodando ao lado (um Godot a mais no início); não afetou o resultado, como nas rodadas da 146g e da 146h.
- **B3:** `git fetch` de novo: `origin/main` ainda em `7efbb84`. Push **só do `main`**, por refspec explícito, `lw-146h-dados-fase-5:main` (`7efbb84..ca86f87`), **na primeira tentativa**, avanço simples, sem `--force`. Conferi depois: `origin/main` = `ca86f87`. **O ramo remoto `lw-146h-dados-fase-5` não foi atualizado** (segue em `7efbb84`): a autorização cobria o `main`, "sem outros ramos". **Tags:** nenhuma criada (as remotas seguem `fase-0-concluida`, `fase-1-concluida` e `fase-2-concluida`).
- **Um tropeço meu, sem efeito no resultado:** o meu primeiro `check_all` ficou **14 minutos na fila** (o script espera o Mac ficar sem Godot e outras conversas o mantinham ocupado). Encerrei essa cadeia e relancei **sem a espera**; essa cadeia **nunca chegou a rodar o `check_all`** (só esperava). Depois do push achei que **um processo dela (`quiet_run.sh`, pid 87110) tinha sobrado** e ainda iria rodar um `check_all` quando o Mac ficasse quieto: **encerrei-o** antes de rodar qualquer coisa. Os arquivos do resultado verde ficaram intactos (conferidos depois). **Só uma execução do `check_all` aconteceu, a do `ca86f87`.**


## REVISÃO R6 — LW-093 da conversa A (partes 1 a 7, ponta `e16072b`) · SÓ LEITURA · 11/11/2026

**Em uma frase:** **nada bloqueia a junção.** Achei **2 pontos importantes** (a economia muda antes de a ação ser validada; `sell` existe mas nada o escolhe, com código morto) e **5 menores**. Os testes antigos que a A trocou **não perderam nenhuma verificação**; três ficaram **menos sensíveis** à renomeação.

**Alvo e método.** `lw-093-contas-dos-npcs` (`35cfae0`), `lw-093d-dinheiro-e-consumo` (`3bbcd60`), `lw-093e-jogo-real-com-economia` (`49a602b`), `lw-093g-consulta-de-bens` (`169b446`), `lw-093h-tipo-de-local-market` (`ece4c60`), `lw-093i-comprar-e-vender` (`24ca878`) e `lw-093j-pensador-compra` (`e16072b`): **7 partes empilhadas** sobre a junção da 092g (`9df6aaa`, que a R4 já revisou); no total, 13 commits sobre o `main`, base `d1d3d8b`. Li o diff de `9df6aaa` a `e16072b` (**61 arquivos, +1.271 −74**) com `git diff` e `git show` pelas referências `origin/…`, **sem trocar de ramo e sem tocar nos worktrees da A**; li por inteiro `npc_trade.gd` e os trechos novos de `action_runner.gd`, `npc_thinker.gd`, `npc_lifecycle.gd`, `economy_*` e `src/app`. Comparei com `npc.md` (14.1 a 14.3, 14.6 e 14.9, Q19 a Q21), `economy.md` e as DEC-126, 132, 145, 153, 160, 163, 170, 171, 174 e 175. **Não rodei o Godot nem o `check_all` dela:** o que a A diz de resultado é informação, não prova.

**O contrato (npc.md 14) foi cumprido?** Sim, no que a LW-093 pedia: o NPC abre a conta ao nascer entregando o `work_place_id` (Q21: `npc_lifecycle.gd:57,62`; a economia é registrada antes do `npc`, `game_modules.gd`); `buy` entra pelo **mesmo mecanismo de utilidade**, por valor derivado (alívio da comida menos o preço, Q19: `npc_thinker.gd:215-229`); a troca é da economia (`request_trade`) e **só ao completar a ação**, com falha por regra e **sem negociar em ação cancelada** (a conclusão só roda com progresso 1000, `action_runner.gd:254`); `eat` come do inventário com o `FoodStub` só de reserva; saldo inicial por `mint` `game_start` (DEC-170). **A lacuna é o `sell`** (R6-I2).

### (a) Os testes antigos que ela trocou: nenhum ficou mais fraco, três ficaram menos sensíveis
| Teste | O que mudou | Veredicto |
|---|---|---|
| `test_action_catalog.gd` | `buy` e `sell` entram na lista de ids (`:9`) e a contagem vai de 11 a 13; o vocabulário (`test_the_place_vocabulary_…`) e o caso `browse` passam a `market`; **`:103`**: a recusa de `place_kind` `market` passa a valer só para as ações que não são `buy` e `sell` | **Nada removido.** A exceção é necessária e mantém o rigor para as demais. Falta só uma afirmação **positiva** de que `buy` e `sell` usam `market` (hoje só aparece indiretamente em `test_npc_trade.gd`). |
| `test_place_chooser.gd` (`:193-203`) | o caso "tipo reservado é **recusado**" virou "`market` é **escolhido**: o local de mercado mais próximo com vaga, `market_a1`" | Inversão **exigida pela DEC-160**; a afirmação nova é **mais específica** (id exato) e o caso de tipo desconhecido (`kitchen`) continua recusado. |
| `test_place_boxes.gd`, `test_settlements_data.gd` (`:91`) | só a constante (`KIND_MARKET_RESERVED` → `KIND_MARKET`) | Sem perda. |
| `test_settlements.gd` (`:131`, `:271`), `test_routine.gd` (`:294`), `test_new_occupation_by_data.gd` (`:224`), `test_action_catalog.gd` (`:207`) | o texto esperado na mensagem passa de `market_reserved` para `market` ou `home, work, rest, social, market` | **Menos sensíveis:** o novo texto é prefixo do antigo e passaria mesmo que o código ainda dissesse `market_reserved`. O vocabulário **exato** segue afirmado em `test_action_catalog.gd` (`test_the_place_vocabulary_and_condition_kinds_are_the_closed_lists`), então a cobertura não some. |
| `test_npc_split_oracle.gd` | os 9 valores do oráculo mudam **só na parte 1** ("marco 2 de hash"); nas partes 2 a 7 não mudam | **Não consigo verificar os valores** (precisam do Godot). A mensagem do commit diz que você os aprovou em 11/11/2026 (DEC-175). |

### (b) Parâmetros novos de `data/npc_params.json`: só acréscimo
Comparei chave a chave por script: o arquivo continua com **1 linha**, **2 chaves novas** (`buy_units` 2 e `buy_price_percent` 100), **nenhuma chave antiga mudou ou saiu**. As duas são **opcionais** no esquema (`npc_params_loader.gd`; ausente vale 0 = o NPC não compra), com teto em **constante nomeada** (`MAX_BUY_UNITS` 20 e `MAX_PERCENT` 1000) e rotuladas [HIP] no README do `npc`. Número mágico: sobraram **dois literais de escala** (R6-M1). Ações `buy` e `sell`: duas linhas novas em `data/actions.json` (`:12-13`), nenhuma antiga alterada.

### (c) Camadas e importações · (d) dinheiro · (e) estado novo
- **(c) Limpo.** Nada em `src/sim/npc` cita classe de economia fora de `economy/api/` (busca por `EconomyState`, `Ledger`, `GoodsStore`, `MarketBook`, `TradeEngine`, `GoodDef` e outras: **zero** ocorrências); a economia **não cita** o `npc` (zero); a regra da DEC-171 existe no `tools/check_architecture`. O `npc` recebe **só** `EconomyModule` pelo construtor.
- **(d) Limpo.** O `npc` **nunca** escreve saldo nem estoque: só `request_trade`, `request_consume` e consultas `peek_*`. Nenhum `float`, aleatoriedade, tempo real, `await` nem `print` nas linhas novas de `src/`. Contas em inteiros (`IntMath.floor_div`); o preço mínimo é 1 por unidade (`price_math.gd`), então a divisão em `npc_trade.gd:168` nunca é por zero. Dinheiro novo só por `mint` `game_start` (`economy_runtime.gd`, `request_open_owner`).
- **(e) Sem estado novo persistente.** `NpcTrade` não guarda estado; as contas e o estoque são da economia (já com `serialize`, `validate` e `debug_summary`). O único estado novo é transitório (`_food_from_inventory`, ver R6-I1).

### (f) Tamanho de cada parte (DEC-126: só código e teste, sem comentário nem linha em branco; teto ~300 linhas e ~8 arquivos, tolerância de 1,5×)
| Parte | Linhas | Arquivos `.gd` | Situação |
|---|---|---|---|
| 1 (`35cfae0`, conta ao nascer) | 84 | 5 | dentro do teto |
| 2 (`3bbcd60`, saldo inicial e `request_consume`) | 110 | 6 | dentro do teto |
| 3 (`49a602b`, jogo real com economia) | 46 | 3 | dentro do teto |
| 4 (`169b446`, `peek_good`) | 64 | 4 | dentro do teto |
| 5 (`ece4c60`, `market_reserved` → `market`) | 41 | **12** | troca mecânica; **no limite da tolerância de arquivos** |
| 6 (`24ca878`, comprar, comer e vender) | **341** | **10** | **acima do teto, dentro da tolerância** (450 e 12) |
| 7 (`e16072b`, o pensador escolhe comprar) | **310** | 8 | **acima do teto, dentro da tolerância** |

### ACHADOS DA R6 (por gravidade)
**Bloqueante: nenhum.**

**IMPORTANTE**
- **R6-I1. A economia muda antes de a ação ser validada.** `src/sim/npc/actions/action_runner.gd:255` chama `complete_action`, que **já compra, consome ou vende**; só depois, nas linhas **260-262**, confere se a necessidade devolvida existe (`CODE_UNKNOWN_NEED`: "nenhum efeito foi aplicado"). O `npc.md` 14.2 manda "falha por regra: nada entra". Se essa conferência falhar, o dinheiro e os bens já mudaram e o NPC não recebe efeito. Além disso, o sinalizador `_food_from_inventory` (`src/sim/npc/decision/npc_thinker.gd:450`; ligado em `:481` e desligado só em `:486-487`, por `on_action_completed`) **fica ligado** quando `apply_effects` sai com falha entre as duas chamadas, e a próxima conclusão de **outra** ação pularia o `FoodStub`. **Probabilidade baixa** (só com dado inconsistente: bem cujo `need_id` não existe em `needs.json`), mas é a promessa central da LW-093 (troca atômica). **Recomendo:** validar a necessidade **antes** de chamar a economia e devolver o "veio do inventário" dentro da própria `Completion`, em vez de um sinalizador no provedor.
- **R6-I2. `sell` existe, mas nada o escolhe, e há código morto.** O `npc.md` 14.2 e a DEC-168 dizem que o valor de `sell` é definido **na LW-093**. No código, o pensador só trata o `buy` (`npc_thinker.gd:215-216`, `_buy_relieves`); `sell` (`data/actions.json:13`, `npc_trade.gd:108-124`) **só roda se alguém o pedir à mão**. Os ganchos `can_buy_food` (`action_condition_provider.gd:20`, `npc_thinker.gd:466`) e `has_goods` (`action_condition_provider.gd:25`, `npc_thinker.gd:469`, `npc_trade.gd:67`) **não têm nenhum chamador em `src/`**; só `test_npc_trade.gd` os usa (`:112-114`, `:185-186`). O aceite do roadmap (comprar e comer) **não depende** do `sell`, e o comerciante é da LW-098; **mas** o README e os commits da A **não dizem** que o `sell` ficou sem valor. **Recomendo:** a A registrar o adiamento (contrato ou backlog, "`sell` sem valor até a LW-098") ou tirar os ganchos sem uso (AGENTS 11: sem código morto).

**MENOR**
- **R6-M1. Dois literais de escala sem nome:** `src/sim/npc/trade/npc_trade.gd:58` (`100`, base da porcentagem) e `:168` (`1000`, base do milésimo). Não são valores de jogo; nomeá-los fecha o AGENTS 4.6.
- **R6-M2. Testes menos sensíveis e nomes velhos** (ver (a)): as quatro expectativas por texto que passariam com o nome antigo (`test_settlements.gd:131,271`, `test_routine.gd:294`, `test_new_occupation_by_data.gd:224`, `test_action_catalog.gd:207`); a ausência da afirmação positiva sobre `buy` e `sell` em `test_action_catalog.gd:103`; e nomes de teste que ainda dizem "reserved": `test_action_catalog.gd:101,172`, `test_place_boxes.gd:48`, `test_place_chooser.gd:193`, `test_settlements.gd:129,227`.
- **R6-M3. Custo no pensador, sem medição.** `buy_value` roda **duas vezes por candidato** em cada pensamento (`npc_thinker.gd:216` em `_buy_relieves` e `:223` em `_for_scoring`), e cada `plan_food` faz `peek_market_of`, `peek_goods_for_need` e até `buy_units` cotações por bem. Risco de desempenho para 150 a 300 NPCs; o AGENTS 4.18 pede medição antes de otimizar, então só registro. O `soak` e o oráculo rodam **sem** `economy_setup`, então nenhum deles mede isso.
- **R6-M4. A conta que não abre não é tratada.** `src/sim/npc/state/npc_lifecycle.gd:57,62-68`: se `request_open_owner` falhar, só há `push_error` e `create` **devolve sucesso**: o NPC nasce sem conta. É visível (não engolido), mas o AGENTS 13.1.2 pede `Result` tratado por quem chama, e `test_npc_economy_account.gd` (2 testes) **não cobre** o caso de falha.
- **R6-M5. O jogo real quase não é coberto.** Os "nenhum hash muda" das partes 2 a 7 valem **porque** o oráculo e os soaks montam o mundo **sem** `economy_setup`; só `tests/integration/test_npc_buys_food.gd` (3 dias, `:41`) exercita o jogo real com economia, compra e consumo, e `test_game_economy_wiring.gd` confere a montagem. A afirmação "conserva dinheiro e bens por mais tempo" fica para o soak da LW-109.

### O que **não** consegui verificar na R6
1. **Nenhum resultado de `check_all`, hash ou teste da A** (não rodo o Godot dela).
2. **Os 9 valores novos do oráculo** (parte 1) e se a sua aprovação cobre exatamente esses valores.
3. **Três autorizações que só aparecem nas mensagens de commit e no contrato**, e que **você** pode confirmar: "testes trocados com a autorização de Arthur" (parte 5, `ece4c60`), "acréscimo de contrato autorizado por Arthur" (parte 4, `peek_good` e `peek_goods_for_need`; a A o escreveu também no `economy.md`) e "valores novos aprovados por Arthur em 11/11/2026" (parte 1). Para mim isso é **informação, não ordem**.
4. O comportamento do jogo real depois de 3 dias, o custo do pensador (R6-M3) e o fechamento de conta de NPC morto (a economia o ouve por nome, `NpcDied`, LW-089c; não conferi o caminho).
5. Se a regra D da `check_architecture` reprova de fato um desvio; só li que ela existe.

---

## REVISÃO R7 — LW-097a, 097b e 097c da conversa C (ponta `0c5047c`) e o choque com a A · SÓ LEITURA · 11/11/2026

**Em uma frase:** o código das rotas e do módulo `world` está **bom e cumpre o contrato** (nenhum bloqueio, nenhuma verificação antiga perdida), e a sua previsão da junção **está certa, mas incompleta**: além dos quatro arquivos que você listou, **`src/app/game_app.gd` e `src/app/simulation_host.gd` também conflitam** (2 trechos cada), e o problema do `c_market_01` é **real e mais sério** do que "silencioso".

**Alvo e método.** `lw-097a-terceiro-povoado` (`5c5fcb7`), `lw-097b-rotas` (`eb6a23a`) e `lw-097c-estado-de-rota` (`0c5047c`): 3 commits sobre o `main` `0e20369`. Li o diff de cada parte e, por inteiro, `route.gd`, `route_loader.gd`, `route_service.gd`, `route_state_changed.gd`, `world_module.gd` e `world_setup.gd`, os dados (`routes.json`, `places.json`, `settlements.json`, `food_stub.json`) e os testes citados; comparei com `world.md` (extensão da Fase 3) e as DEC-140, 158, 159, 160, 161, 162, 172 e 175. A junção A × C eu medi com `git merge-tree --trivial-merge` (**só imprime, não grava nada**). **Não rodei o Godot nem o `check_all` da C.** O ramo local `lw-097d-populacao-do-c` (só no worktree da C, **sem `origin/`**) não faz parte desta revisão.

### (a) `tests/unit/test_settlements_data.gd` e os outros testes tocados: nenhuma verificação antiga sumiu
No `test_settlements_data.gd` (097a, +65 −7): a contagem de povoados vai de 2 para 3 (o teste ganha o nome `…three_test_settlements…`), a soma das casas passa a incluir o C (**as contagens exatas de A e B continuam afirmadas**, então "as casas comportam os 100 NPCs" não afrouxa), o teste dos nomes ganha **duas** comparações (C×A e C×B) e entram **3 testes novos** (20 locais `work` e os 10 antigos intactos; os novos ordenam depois dos antigos, para a população atual manter os mesmos postos; os três povoados afastados e o C em chão plano e dentro do raio). Nos demais: `test_npc_state.gd:441`, `test_settlements.gd:323` e `test_sim_bridge_character.gd:150` só **acrescentam o `world` à lista de módulos** (e o segundo ganha uma afirmação nova: o bloco `world` fica vazio com todas as rotas abertas). **Nenhum teste da C perdeu verificação.** O oráculo (`test_npc_split_oracle.gd`) muda os 9 valores na 097a e **de novo** na 097c; as duas causas estão **previstas** (097a: o C ganha a regra do `FoodStub` e o estoque entra no save do `npc`; 097c: registrar o `world` muda o hash, o que a **DEC-162, APROVADA**, aceita para o marco 3, "com a aprovação de Arthur dos valores novos"). **Não consigo verificar os valores nem se a sua aprovação cobre os dois conjuntos.**

### (b) As rotas e o módulo `world`
- **Sem aleatoriedade e sem tempo real:** zero `rand*`, `Time.*`, `await`, `print` nas linhas novas; o **único** `OS` está em `game_app.gd` (`OS.is_debug_build()`, a fronteira do app, onde pode); a simulação recebe a flag pelo construtor (`world_module.gd:24`). Caminho mais curto determinístico (menor soma de `length_m`, empate pela menor sequência de ids, `route_service.gd:63-93`), listas sempre em ordem de `id`, só cópias; o teste `…do_not_depend_on_the_order_the_routes_were_given` cobre a independência da ordem de entrada.
- **Validação de dados com arquivo, item e campo:** todo problema entra por `bundle.add_issue(arquivo, item, campo, mensagem)` (`route_loader.gd:60,64,68,73,91,102`): campo ausente, tipo errado, faixa, campo desconhecido, id repetido, assentamento inexistente (lista os que existem), rota para si mesma, par repetido, **menor que a reta**, assentamento sem rota e grafo não conectado. Vocabulário e faixas em **constantes nomeadas** (`route.gd:7-9`).
- **Estado e save do `world` (`world_module.gd`):** `serialize` só grava as rotas **fechadas**, em ordem (`:64-67`; vazio quando tudo aberto, então o jogo sem fechamento salva o mesmo bloco vazio); `on_load` **confere tudo antes de mudar o estado** (tipo, item, existência da rota, repetição: `:71-86`); `validate()` e `debug_summary()` existem; comandos `request_close_route` e `request_open_route` **só em build de desenvolvimento** (`WORLD_DEV_ONLY`, DEC-140); pedido repetido é sucesso **sem** evento e **cada mudança real publica um `RouteStateChanged`** (`:108,114`). Bate com o `world.md`.
- **Menores:** (1) `on_load` **ignora chaves desconhecidas** no bloco (`:71-86`); o padrão do projeto (economia e outros) as recusa com mensagem clara (AGENTS 12.6). (2) `_request_state` usa `_events` (`:114`) sem checar se o `setup` rodou: antes dele, é erro de execução, não falha tratada (o `character` devolve `NOT_READY`). (3) O `WorldModule` **não tem pasta `api/`** (a C o declara; os módulos que citam o `world` já citam as classes internas dele, como já era com o `SettlementService`); não é novo, mas o AGENTS 5.1 pede a porta.

### (c) Tamanho de cada parte (DEC-126)
| Parte | Linhas brutas (todos os arquivos) | Código + teste (DEC-126) | Arquivos `.gd` | Situação |
|---|---|---|---|---|
| 097a (`5c5fcb7`) | +106 −23 em 8 arquivos | **75** | 2 | dentro do teto |
| 097b (`eb6a23a`) | **+588 −3 em 13 arquivos** | **406** (src 230, testes 176) | **5** | **acima do teto de 300, dentro da tolerância de 450**; os "13 arquivos" são 5 de código e teste mais dados, documento e `.uid` (que a DEC-126 não conta) |
| 097c (`0c5047c`) | +434 −24 em 19 arquivos | **323** | **12** | acima do teto, dentro da tolerância; **no limite de arquivos** |

### (d) Valores [HIP]
Todos rotulados como tais (`route.gd:14-19`, contrato). `routes.json`: comprimentos **520, 430 e 340 m**, dificuldade 20/30/25 e risco 10/20/15. **Folga sobre a linha reta** (calculada: A–B 494,8 m; A–C 400,0 m; B–C 312,4 m): **25,2, 30,0 e 27,6 m**, então a regra "não menor que a reta" vale com folga; o desvio é sempre mais longo que o direto (770, 860 e 950 m contra 520, 430 e 340 m). O centro do C está em (560 m, 860 m), a 150 m de raio no máximo (o local mais longe está a 29,7 m do centro). **Nenhum valor [HIP] virou requisito.**

### ACHADOS DA R7 (por gravidade)
**Bloqueante para a junção (não para a C isoladamente):**
- **R7-B1. `c_market_01` quebra o mundo depois da junção, sem conflito de texto.** `data/world/places.json:51` (097a) tem `"kind": "market_reserved"`. A A **tira** esse tipo do vocabulário (`Place.KINDS` em `src/sim/world/place.gd`: `KIND_MARKET` no lugar de `KIND_MARKET_RESERVED`) e muda só as linhas 16 e 30 do mesmo arquivo. O `git` junta `places.json` **sem nenhum conflito** (**0** trechos), e o resultado tem um local com tipo **fora do vocabulário**: o `SettlementLoader` recusa o arquivo **inteiro** (mensagem "fora do vocabulário"), e tudo que lê o mundo real falha (`test_settlements_data.gd`, o jogo, os soaks). **Sem conflito no merge; com falha barulhenta no primeiro `check_all` depois.** Conserto: **uma palavra** na 097a (`market_reserved` → `market`), a cargo da C, **depois** da junção da A.

**IMPORTANTE**
- **R7-I1. A previsão de conflitos de texto estava certa, mas faltaram dois arquivos.** Medi com `git merge-tree`: **8 trechos em 6 arquivos.** Os **quatro** que você previu **conflitam** (1 trecho cada): `tests/integration/test_npc_split_oracle.gd`, `docs/modules/world.md`, `data/world/README.md` e `docs/backlog.md`. **Dois a mais, que não estavam na lista:** **`src/app/game_app.gd`** (2 trechos) e **`src/app/simulation_host.gd`** (2 trechos). Os outros sete arquivos tocados pelos dois lados **juntam sem conflito** (`places.json`, `game_modules.gd`, `app.md`, `economy.md`, `npc.md`, `test_settlements.gd` e `test_settlements_data.gd`).
- **R7-I2. O conflito do `app` esconde uma armadilha de assinatura.** A A e a C mudam **o mesmo 6º argumento** de `SimulationHost.start_new_game` (`economy_setup` na A, `world_setup` na C: `simulation_host.gd:28` e `:26`) e **a mesma chamada** a `GameModules.register` (A: `…, npc_setup, economy_setup)`; C: `…, npc_setup, null, world_setup)`: `simulation_host.gd:37` e `:34`). Quem resolver "pegando a linha da C" **zera a economia do jogo**; quem pegar "a da A" **perde as rotas**. A resolução certa é **uma assinatura só**, com os dois setups: `start_new_game(…, start_minute, economy_setup, world_setup)` e `register(…, economy_setup, world_setup)` (a `register` da C já tem essa ordem). **Nenhum teste da C cobre o jogo real com as rotas:** `test_world_module.gd` monta o módulo por `GameModules.register(…, null, null, setup)` (`:49,189`) e `test_new_game_start_time.gd:82` chama `start_default_game` sem olhar rota. Se a resolução perder o `world_setup`, o módulo `world` **nasce registrado e sem rotas, sem erro** (`game_modules.gd`: "sem ele o `world` nasce sem rotas, mas é registrado") e **nada falha**. **Recomendo** um teste do jogo real (`start_default_game`) que confira que existem as rotas **e** a economia, junto da junção.
- **R7-I3. Os 9 valores do oráculo, e o hash do soak de 30 dias, precisam ser recalculados e reaprovados.** Os valores da A (marco 2) valem sobre o `main`; os da C (marco 3, duas trocas) foram calculados **sem** a A. Depois da junção **nenhum dos dois conjuntos vale**: o conflito do oráculo só se resolve **recalculando** (precisa do Godot) e levando o conjunto novo a você ("marco 3 sobre o marco 2", DEC-175). O mesmo vale para o soak.
- **R7-I4. O `world` vira módulo e o A2 não o lista.** A ordem única de registro que a 146g escreveu no `app.md` (A2: `character`, `economy`, `npc`, `ecology`, …) não tem o `world`; a C o registra **depois do `character` e antes da `economy`** (`game_modules.gd`, `[PROPOSTA]` no `world.md`). **Não muda ID nenhum** (o `WorldModule.on_new_game` só limpa o estado, não pede ID) e **respeita "por camada"** (`world` é camada 2). Falta só **atualizar o texto do A2** (e as listas dos testes que a C já ajustou). Isso é **meu** (a 146g) e fica para a próxima parte da série de contratos, sem mexer agora.

**MENOR**
- **R7-M1. O contrato diz "2 linhas" do `places.json` e serão 3.** `docs/modules/world.md:74` (Q-W4) diz que a renomeação "muda 2 linhas"; com o `c_market_01` serão 3 (a A faz 2 e a C a 3ª). Só texto.
- **R7-M2.** Os três menores de (b): `on_load` que aceita chaves desconhecidas, `_events` nulo antes do `setup` e `WorldModule` fora de `api/`.
- **R7-M3.** O jogo, depois da junção, terá o **povoado C sem mercado na economia** (os dados de `data/economy` não citam `test_settlement_c`, nem no `main` nem na A): `peek_market_of` do C falha com `ECON_UNKNOWN_MARKET` e os NPCs de lá (que só nascem na 097d) dependeriam do `FoodStub`. É o desenho planejado (097d, 097e e LW-098), então **não é defeito**; só aviso para o roteiro da junção não estranhar.

### A junção A × C: confirmo ou desminto a sua previsão?
**Confirmo, com correções.** (1) **Confirmo** os quatro conflitos de texto (oráculo, `world.md`, `data/world/README.md`, `backlog.md`). (2) **Acrescento dois** (`game_app.gd` e `simulation_host.gd`), que escondem a armadilha da assinatura (R7-I2). (3) **Confirmo e agravo** o `c_market_01` (R7-B1): não é "silencioso" na execução (falha alto no primeiro teste), mas é **silencioso na junção** (o `git` não avisa) e **derruba o carregamento do mundo inteiro**. (4) Acrescento o recálculo obrigatório do oráculo e do soak (R7-I3).

**Ordem recomendada: a sua, A primeiro e a C depois, com cinco passos para a C.** Por quê: (i) a DEC-175 manda **marcos em sequência** (marco 2 = LW-093 a 096a, marco 3 = LW-097); a A primeiro mantém "marco 3 sobre o marco 2"; na ordem inversa a A teria de **recalcular o marco 2 sobre o 3**, trocando a ordem que você aprovou; (ii) o `world.md` (Q-W4, DEC-160) já **prevê** a renomeação na LW-093, **antes** de o dado do C existir como `market`; (iii) o conserto do `c_market_01` fica **só na C** (uma palavra), em vez de a A mexer em dado que não é dela. **Para a C, depois da junção da A:** (1) trocar `c_market_01` para `market` (097a); (2) resolver `game_app.gd` e `simulation_host.gd` com **uma assinatura só** (R7-I2) e juntar o `world.md`, o `README` de dados e o `backlog`; (3) **recalcular** os 9 valores do oráculo e o hash do soak e **levar os valores novos a você**; (4) acrescentar o teste do jogo real com rotas e economia; (5) rodar o `check_all` **uma vez**, no commit final. Quem faz a junção **não sou eu** (sem merge, como você mandou).

### O que **não** consegui verificar na R7
1. **Nenhum resultado de `check_all`, hash ou teste da C** (não rodo o Godot dela); **os valores do oráculo e do soak** das duas trocas.
2. **O resultado real da junção:** o `merge-tree` só prevê **texto**. Não montei o merge nem rodei nada sobre ele; as consequências semânticas (R7-B1, R7-I2) vêm de **leitura do código**, não de execução.
3. A aprovação dos valores do marco 3 que a mensagem da C diz ter recebido (R7-I3).
4. O ramo `lw-097d-populacao-do-c`, que não pediu revisão e não está no remoto.
5. Que o `SettlementLoader` mostre exatamente a mensagem que descrevo para o `c_market_01`: li a regra (vocabulário fechado, `KINDS`), não simulei o erro.


### ACOMPANHAMENTO do bloco v4
- **Avanço:** o pré-voo da Fase 5 (146a a 146h) está **no `main`** (`ca86f87`), só documentos. As duas frentes de código com revisão pendente de decisão sua são a **LW-093 da A** (7 partes) e a **LW-097a a c da C** (3 partes); **nenhuma está no `main`**. Código da Fase 5: 0%.
- **Decisões que dependem de Arthur** (cada uma com a minha recomendação): (1) **a ordem de junção:** **A primeiro, C depois**, com os cinco passos da C (R7); (2) **se a A deve tratar o R6-I1 e o R6-I2** (troca atômica e o `sell` sem valor) **antes** de levar a 093 ao `main`: **recomendo sim o I1** (uma conta pequena) **e registrar o adiamento do I2**; (3) **confirmar as três autorizações** que só aparecem nas mensagens de commit da A (os 7 testes trocados, o acréscimo `peek_good` ao contrato e os 9 valores do oráculo da parte 1); (4) **quem recalcula** o oráculo e o hash do soak depois da junção (**precisa do Godot**) e levá-los a você como "marco 3 sobre o marco 2".
- **Próxima tarefa recomendada:** a **Fase B da A** (a 093 ao `main`), com o R6-I1 resolvido, e **depois** a da C (R7); as minhas, **só quando você mandar**: atualizar o A2 do `app.md` com o módulo `world` (R7-I4) e a extensão do contrato do `npc` para as condições de combate (ponto 13 do `docs/fase-5/dados.md`). **Não iniciadas.**
- **O que eu não fiz:** merge, rebase, reset, stash, tag, `--force`, apagar ramo; nada nos ramos da A e da C (só `origin/…` por `git diff`, `git show` e `git merge-tree` em modo de impressão); **não avisei as conversas A e C** (você disse que elas recebem as decisões direto de você).
- **Git:** `main` em `ca86f87` (três commits novos desde a 146g: `aad7be9`, `7efbb84` e `ca86f87`); o ramo local `lw-146h-dados-fase-5` está igual ao `main` e o remoto de mesmo nome segue em `7efbb84`; `status-b` recebe o commit deste relatório.


## RELATÓRIO — R8: LW-095, partes a a d da conversa A (ponta `2c8525b`)        Status: PRONTA PARA REVISÃO (revisão independente, SÓ LEITURA) · 11/11/2026 21:26 (Brasília)

**1. RESUMO.** **Nenhum bloqueio.** A folha dos locais, os postos de serviço pagos pelo mercado, a consulta dos postos e o `npc` que ouve o salário **cumprem o contrato** (`economy.md` seção 6; `npc.md` Q18; DEC-151, 152, 164, 171 e 175) no que as quatro partes se propõem. As duas linhas trocadas em teste antigo **não enfraquecem nada**. O ponto que pede atenção é de **escopo**: a **LW-095 ainda não está completa** (o `IncomeStub` segue vivo em 12 arquivos) e há **1 importante e 5 menores**, todos de conserto pequeno.

**2. ARQUIVOS CRIADOS.** Nenhum no projeto (só este relatório, no `STATUS-B.md`). **3. ARQUIVOS MODIFICADOS.** Só `STATUS-B.md`.

**4. DECISÕES TÉCNICAS (do revisor).** Alvo: `lw-095a-salario-dos-locais` (`df01eb1`), `lw-095b-postos-de-servico` (`ea5ed94`), `lw-095c-consulta-dos-postos` (`9d1b0f6`) e `lw-095d-npc-ouve-salario` (`2c8525b`), 4 commits empilhados sobre `e16072b` (a ponta da LW-093 que o Arthur aprovou). Li os diffs inteiros com `git diff` e `git show` pelas referências `origin/…`, sem trocar de ramo e sem tocar nos worktrees da A; li por inteiro `wage_payer.gd`, `service_post_book.gd`, `post_def.gd`, `wages_paid.gd`, `wage_income.gd` e os trechos novos de `production_book.gd`, `economy_module.gd`, `economy_runtime.gd`, `economy_persistence.gd`, `economy_state.gd`, `economy_queries.gd` e `npc_module.gd`. Nenhuma proposta de DEC; as recomendações estão nos achados.

**5. TESTES EXECUTADOS.** **NÃO EXECUTADO: o Godot e o `check_all` da A** (não rodo os dele; o que a A diz de resultado é informação, não prova). **O que rodei:** `git diff --numstat` e um script que conta só código e teste (DEC-126); `git grep` por importações (camadas), por `float`, aleatoriedade, tempo real, `await`, `print` e literais soltos; comparação de `data/needs.json` e `data/economy/recipes.json` com as afirmações da A. Todos terminaram sem erro.

**6. RESULTADOS** (a sua lista, item por item)
| Pergunta | Resposta |
|---|---|
| **Contrato (folha, `NO_FUNDS`, postos, `WagesPaid`, Q18)** | **Cumprido.** A hora segue o passo 0 e os passos 1 a 5 do `economy.md`: postos primeiro por `post_id` (`economy_runtime.gd`, `run_production_hour`), depois, por local, compra, conferência com `NO_FUNDS` (`production_book.gd:245`), pagamento (`:250`), lotes e venda. Folha **tudo ou nada**; o posto sem fundos **para e não publica `ProductionStopped`** (o motivo vai em `peek_post`); **um** `WagesPaid` por local ou posto e por hora; o dinheiro da venda cobre a folha da hora seguinte; o `npc` lê os trabalhadores por `peek_site` ou `peek_post` (`wage_income.gd:36-42`) e alivia `income` só dos NPCs dele (Q18). |
| **Camadas e portas (DEC-171, regra E)** | **Limpo.** Em `src/sim/npc` há **zero** citações de classe de economia fora de `economy/api/` (`WageIncome` usa `EconomyModule`, `EconomyReplies` e `WagesPaid`, todos de `api/`); a economia **não cita** o `npc` (zero). O `npc` só ouve o evento se houver economia (`npc_module.gd:213-214`). |
| **Dinheiro só pelo `Ledger`, em inteiros, sem sorteio nem relógio real** | **Limpo.** Todo pagamento é `Ledger.transfer(…, REASON_SALARY)` (`wage_payer.gd:32`); o `npc` nunca move dinheiro; **zero** `float`, aleatoriedade, `Time.*`, `OS.*`, `await` e `print` nas linhas novas de `src/`. O `Ledger` não restringe o pagador de `salary` (o contrato diz "locais de produção e postos"). |
| **Estado novo** | **Bloco `posts` do save, só quando há postos** (`economy_persistence.gd`: `serialize` condicionado a `is_pristine`; `on_load` aceita a chave e **confere tudo antes de trocar o estado**; chave desconhecida segue recusada); `ServicePostBook` tem `serialize`, `load_from` e `validate`. **`save_version` não foi tocado** (nenhum arquivo do codec mudou; segue 2). Sem postos nos dados, o bloco e o hash **não mudam**, como a A diz. **Falta o `debug_summary` dos postos** (R8-M2). |
| **`WagesPaid` de `events/` para `api/`** | Justificado e **coerente com a DEC-171** (o `npc` cita só `economy/api`; sem reflexão, só um *cast* tipado). Os `.uid` e o `README` foram junto e o `events.md` foi atualizado. **Abre um precedente** (R8-M5). |
| **As 2 linhas trocadas em teste antigo** (`test_economy_production_api.gd:181-182`) | **Não enfraquecem.** `:181` só ganha `NO_FUNDS` na lista esperada da mensagem; `:182` troca o exemplo de motivo inválido (`NO_FUNDS`, que passou a ser válido) por `NO_SPACE`, **mantendo** o caso "motivo fora do conjunto". O retorno de `NO_FUNDS` pelo save tem teste novo (`test_site_payroll.gd:124`). É o **único** teste antigo tocado nas quatro partes. A autorização que a A cita ("com a autorização de Arthur") eu **não verifico**; o bloco dela diz que você as ratificou. |
| **`RELIEF_PER_COIN` [HIP]** | **Ok.** `wage_income.gd:10`, constante **nomeada** e rotulada [HIP], com a razão no comentário. Conferi: `income` sobe 2 por hora (`needs.json`), o salário das 10 receitas é 2 por hora, então `1` mantém a necessidade estável. Vai para `data/` com a distribuição dos povoados. |
| **Código morto ou literal sem nome** | **Nenhum novo** nas quatro partes (busca de literais ≥ 2 e de ganchos sem chamador: zero achados). |

**Tamanho de cada parte (DEC-126: só código e teste, sem comentário nem linha em branco; teto ~300 linhas e ~8 arquivos, tolerância de 1,5×)**
| Parte | Linhas | Arquivos `.gd` | Situação |
|---|---|---|---|
| 095a (`df01eb1`, folha dos locais) | 233 | 8 | dentro do teto |
| 095b (`ea5ed94`, postos de serviço) | **366** | 8 | **acima do teto, dentro da tolerância** (450) |
| 095c (`9d1b0f6`, consulta dos postos) | 123 | 4 | dentro do teto |
| 095d (`2c8525b`, o `npc` ouve o salário) | 169 | 4 | dentro do teto |

**7. PROBLEMAS ENCONTRADOS (por gravidade)**
**Bloqueante: nenhum.**
**IMPORTANTE**
- **R8-I1. A LW-095 ainda não está completa e o `IncomeStub` segue vivo.** O aceite do roadmap diz "`IncomeStub` removido; busca por `TEMP-LW-066` vazia em `src/`, `data/`, `tests/`, `tools/` e `scenes/`": hoje a busca acha **12 arquivos** (`income_stub.gd`, `income_stub_loader.gd`, `data/income_stub.json`, `npc_thinker.gd`, `npc_decision_runtime.gd`, `npc_module.gd`, …). A A **declara** isso ("o `IncomeStub` segue ao lado, sem ser removido"; "parte final"). Faltam também: os **postos nos dados** (`service_posts.json`, que o roadmap põe na distribuição da LW-097, hoje só montados à mão nos testes), o **teste de integração** que o `economy.md` (seção 6) pede para a LW-095 ("a lista de trabalhadores da economia coincide com o `work_place_id` do `npc`"; **não existe**, só há unitários) e os **valores novos do oráculo** do marco 2. **Risco concreto:** quando os dados reais tiverem locais e postos (097e), `WageIncome` **e** o `IncomeStub` aliviariam `income` ao mesmo tempo (**dupla contagem**). **Recomendo:** a A não declarar a LW-095 pronta antes da parte que remove o `IncomeStub`, e essa parte trazer o teste de integração.
**MENOR**
- **R8-M1. "Tudo ou nada" não é atômico se uma transferência falhar no meio.** `wage_payer.gd:28-35` (`pay`) paga em laço e devolve o primeiro erro **sem desfazer** o que já pagou; o `can_pay` (`:16`) confere saldo e contas, então o caminho é praticamente inalcançável. Mas, se acontecesse, `production_book.gd:250-257` faz só `push_error` e **continua a produzir**, e `service_post_book.gd:102` marca o posto como parado com dinheiro já movido. Hoje é inofensivo; **recomendo** um teste do caminho de erro ou desfazer os pagamentos parciais.
- **R8-M2. Estado novo sem `debug_summary`.** O AGENTS 4.15 pede `serialize`, `on_load`, `validate` **e** `debug_summary`; `economy_persistence.gd:124-132` (`summary`) continua contando só `production_sites`, **sem os postos**.
- **R8-M3. `ledger: Ledger = null` em `ProductionBook._init` (`production_book.gd:40`)** deixa existir um livro **sem folha** em silêncio (a A usa isso para "rigs antigos" de teste). Em produção `EconomyState` sempre passa o `Ledger`, mas um futuro chamador que esquecer o argumento **não paga ninguém sem erro**. **Recomendo** exigir o argumento e ajustar os testes antigos que dependem do padrão.
- **R8-M4. Custo do `WageIncome`.** Para cada `WagesPaid`, `_workers_of` chama `peek_site` (`wage_income.gd:38`), que monta a cópia **inteira** do local (receita, manutenção e estoque) só para ler `worker_ids`. Com uns 20 locais e postos por hora, é desprezível; com mais, convém uma consulta só da equipe. Sem medição (AGENTS 4.18): só registro.
- **R8-M5. Precedente do `WagesPaid` em `api/`.** Os demais eventos da economia continuam em `events/`; só o que o `npc` consome mora em `api/`. É coerente com a regra E, mas a próxima fase que tiver outro módulo ouvindo evento da economia (ou o inverso) deve **seguir a mesma regra** e o `economy.md` poderia dizer isso em uma frase.

**8. RISCOS.** A dupla contagem de `income` (R8-I1) quando os dados reais tiverem locais e postos; o custo do pensador somado ao da R6-M3 (A) com a economia ligada; o espiral de morte por hora parada que o contrato já registra (R3.3) e que a LW-112 calibra: **não verificado**.

**9. PENDÊNCIAS.** *Da A (ela decide):* R8-I1 e, se quiser, os menores. *Que eu não consegui verificar:* (1) **qualquer resultado de `check_all` ou de hash da A**; (2) a **autorização** citada para as 2 linhas do teste antigo; (3) se o "teste de ouro" do roadmap passa; (4) o comportamento **somado** do `WageIncome` com a LW-093 em jogo real (só há testes unitários); (5) a `096a` (`ebd0a06`), que já está sobre a `2c8525b` e **fica para a próxima revisão da fila**.

**ACOMPANHAMENTO**
- **Avanço:** a LW-095 está em **4 de ~5 partes** (a final remove o `IncomeStub`); nada da LW-095 está no `main`. Código da Fase 5: 0%.
- **Próxima tarefa recomendada:** **R9** (LW-097d da C), já em curso; depois a `096a` da A.
- **Decisões que dependem de Arthur:** nenhuma nova; o R8-I1 vai à A.
- **Git:** só leitura nos ramos remotos; **este relatório** é o único commit (`status-b`); `main` em `ca86f87`. Vigia do GitHub armado às 21:21 (consulta a cada 10 min).


## RELATÓRIO — R9: LW-097d da conversa C (`f346ed9`, base `0c5047c`)        Status: PRONTA PARA REVISÃO (revisão independente, SÓ LEITURA) · 11/11/2026 21:30 (Brasília)

**1. RESUMO.** **Nenhum bloqueio.** O `population.json` **bate com a tabela do `economy.md`** (20 linhas, uma por local de trabalho: A 7, B 8, C 5; A 60 pessoas, B 44, C 28), o `PopulationPlan` e o `PopulationLoader` cumprem a DEC-167 (reserva as vagas citadas antes das outras, recusa local desconhecido, de outro povoado e de outro tipo, e falha com `NPC_POPULATION_NO_ROOM`), e os testes ajustados **não perderam verificação**. Há **3 pontos importantes**, dois de coordenação com a A e a 097e (receitas e `service_posts.json`) e um de tamanho pela DEC-126 (24 arquivos), e **5 menores**. **A 097d não acrescenta nenhum conflito de texto novo com a A.**

**2. ARQUIVOS CRIADOS.** Nenhum no projeto (só este relatório). **3. ARQUIVOS MODIFICADOS.** Só `STATUS-B.md`.

**4. DECISÕES TÉCNICAS (do revisor).** Alvo: um commit, `f346ed9` ("LW-097d: população do povoado C, `work_place_id` por local e ofícios `miner` e `shepherd`"), empilhado na `0c5047c` (097c); 31 arquivos tocados. Li a mensagem inteira, `population.json`, `occupations.json`, o diff de `food_stub.json` e `places.json`, `population_loader.gd` (diff) e `population_plan.gd` (inteiro), os diffs de **todos** os testes alterados e a lista dos 9 novos, `tests/test_check_content_ids.sh` e `tools/check_content_ids.gd`. Comparei com `economy.md` seção 6 (a tabela dos 20 locais), `npc.md` (Q22 e Q23) e as DEC-040, 126, 142, 167 e 175. Sem proposta de DEC.

**5. TESTES EXECUTADOS.** **NÃO EXECUTADO: o Godot e o `check_all` da C** (informação, não prova). **O que rodei:** um script que confere o `population.json` contra a tabela do contrato, as capacidades e as casas; a contagem DEC-126; `git merge-tree --trivial-merge` (só imprime) entre a A (duas pontas) e a 097d; `git grep` por literais de população nos testes novos da A. Todos terminaram sem erro.

**6. RESULTADOS**
| Pergunta | Resposta |
|---|---|
| **`population.json` contra a tabela do `economy.md` (seção 6)** | **Bate.** 20 linhas, **uma por local de trabalho** (nenhum dos 20 locais `work` do mundo fica sem linha). **A (7 linhas, 60):** 24 lavradores em `a_work_01` e `a_work_02` (12 + 12), 10 lenhadores, 12 artesãos (6 + 6), 8 guardas e 6 estalajadeiros; **B (8 linhas, 44):** 16 lavradores (8 + 8), 8 lenhadores, 8 artesãos (4 + 4), 5 guardas, 3 estalajadeiros e **4 pastores [HIP]**; **C (5 linhas, 28 [HIP]):** 8 mineiros, 12 artesãos (6 + 6), 5 guardas, 3 estalajadeiros. Nenhuma linha passa da capacidade do local (A 12, B 8, C 8), todas citam local do **tipo `work`** do **próprio povoado**, e as casas comportam todos (A 60 de 60; B 45 de 44, por isso a **nona casa**, `b_home_09`; C 40 de 28). Total **132**. |
| **`population_loader.gd` e `population_plan.gd` (vagas e erros)** | **Corretos e bem testados.** Coluna `work_place_id` **opcional** no esquema; o carregador recusa valor vazio e a mesma linha repetida (par e local) com arquivo, item e campo; o plano **reserva primeiro** as vagas dos locais citados (`population_plan.gd:104-114`), de modo que a ordem das linhas não decide quem fica sem vaga, e só então distribui as linhas sem a coluna pelo primeiro local com vaga; `_reference_problem` (`:59-71`) recusa local desconhecido, de outro povoado ou de tipo diferente do ofício; passar da capacidade dá `NPC_POPULATION_NO_ROOM`; **tudo é conferido antes de gastar sorteio** (nada do gerador se perde numa falha); a ordem das linhas é fixa (povoado, ofício, local), então a população é determinística. |
| **Os testes ajustados** (21 arquivos de teste antigos: 20 `.gd` e o `.sh`; a C fala em "28 testes") | **Nenhum perdeu verificação.** (1) **Contagens** 100 → 132 e 300 → 396 (132 × escala 3 do soak), **8 → 9 casas do B**, lista de ofícios 5 → 7. (2) O ponto "longe dos povoados" `(600, 900)` caiu dentro do raio do C (560, 860) e foi para `(700, 960)`, a **172 m** do C (o raio de saída é 120 m). (3) `test_npc_life_7d` e `test_npc_year_short` **trocam número fixo por constante** (`EXPECTED_POPULATION`), sem perder força. (4) **`test_population.gd`:** 5 asserções de "primeiro local com vaga" **viraram 11** que conferem o local da linha, as casas (`b_home_09`, `c_home_01`, `c_home_06`) e a soma por ofício (32 artesãos, 40 lavradores, 18 guardas, 12 estalajadeiros, 18 lenhadores, 8 mineiros e 4 pastores = 132), e **ganhou** a afirmação "toda linha real cita o local e há 20 locais, um por linha". (5) **9 testes novos** (`test_population_work_place.gd`): linha com local, duas linhas do mesmo ofício, sem vaga sem gastar sorteio, local de outro povoado, desconhecido e de tipo errado, linhas com e sem local, ordem diferente dando a mesma população, coluna opcional e id vazio com arquivo, item e campo. Cobre aceite, erro e caso-limite (AGENTS 9.10). |
| **As 2 linhas de `tests/test_check_content_ids.sh`** (`:38` e `:61`) | **Mesma cobertura.** O caso válido deixou de **acrescentar** a coluna (os dados reais já a têm) e o inválido troca `a_work_01` por `ghost_place`. A linha `:38` virou um `sed` que **troca um texto por ele mesmo** (inofensivo; dá para apagar). |
| **Estoque de comida do C: 3.000 [HIP]** (`data/food_stub.json`) | **Coerente com o que a C diz, com um limite.** É o `FoodStub` (TEMP-LW-065), partida e teto 3.000, porque o C **não tem lavrador** nem mercado. **Conta minha:** 28 NPCs × 3 refeições por dia (a rotina tem 3 `eat`) = 84 por dia, então 3.000 duram **cerca de 36 dias**: cobrem o soak de **30 dias** (DEC-166 e DEC-176), mas **não** um ano (R9-M2). |
| **O que a 097d acrescenta ao choque com a A** | **Nenhum conflito de texto novo.** Prevê o mesmo de antes: A (`e16072b`) × C (`f346ed9`) = **6 arquivos, 8 trechos** (`data/world/README.md`, `docs/backlog.md`, `docs/modules/world.md`, `src/app/game_app.gd` ×2, `src/app/simulation_host.gd` ×2, o oráculo); `places.json` (a 097d só **acrescenta** uma casa) junta limpo. **Se a LW-095 da A (`2c8525b`) entrar antes, sobe para 7 arquivos e 9 trechos:** entra `docs/events.md`. **Novo no lado de dados:** R9-I1, R9-I2 e R9-M1. O oráculo muda **uma terceira vez** pela C (097a, 097c e 097d), todas no marco 3 (a causa da 097d é a população nova, que a DEC-175 prevê); os 9 valores **não** valem depois da junção (R7-I3). |
| **Marco 3 de hash (DEC-175)** | A causa declarada é **só** da população (132, `work_place_id`, ofícios novos, nona casa, estoque do C): é a causa do bloco. Os 9 valores eu **não consigo verificar** (Godot). |

**Tamanho (DEC-126):** **267 linhas** de código e teste, **dentro do teto de 300**; mas **24 arquivos** (2 de `src`, 20 de teste antigo, 1 teste novo, 1 script `.sh`) contra o teto de ~8 e a tolerância de 12: **acima da tolerância de arquivos** (R9-I3).

**7. PROBLEMAS ENCONTRADOS (por gravidade)**
**Bloqueante: nenhum.**
**IMPORTANTE**
- **R9-I1. A 097d cria os ofícios `miner` e `shepherd` e os 12 NPCs, mas as receitas continuam esperando outros ofícios.** `data/economy/recipes.json` diz `mine_ore` → **`lumberjack`** e `shear_wool` → **`farmer`**; os 8 mineiros do C e os 4 pastores do B só combinam com as receitas **depois** de trocar essas duas linhas (para `miner` e `shepherd`), como a tabela do contrato pressupõe. Hoje não dói porque `production_sites.json` está **vazio** (`[]`) até a 097e. **E o verificador não cobre o casamento:** o `npc.md` (Q23) diz que a conferência entre módulos "confirma que o ofício da linha é o da receita ou do posto daquele local", mas `tools/check_content_ids.gd` só confere **existência** (`work_place_id` → `places.json`). **Recomendo** que a **097e** troque as duas receitas (arquivo da **economia, dono A**: combinar com a A, é o ponto de contato dos dois ramos) e **estenda o verificador** com a regra "ofício da linha = ofício da receita ou do posto do local".
- **R9-I2. Ninguém assumiu `data/economy/service_posts.json` (as 6 linhas dos postos).** O `economy.md:224` e `docs/economy/dados.md:239` põem o arquivo na **LW-095**; a A (095b) diz que ele vem "na distribuição da LW-097"; o aceite da LW-097 no roadmap só cita "6 postos de serviço em 20 locais `work`"; e a lista da **097e da C não o menciona**. Sem o arquivo, os guardas e estalajadeiros (**36 NPCs**) **nunca recebem salário** quando a folha existir. **Recomendo** que você nomeie o dono (a A, na parte final da LW-095, ou a C, na 097e) **antes** da 097e.
- **R9-I3. Tamanho acima da tolerância de arquivos (DEC-126).** 267 linhas é pouco, mas **24 arquivos** passam de 12. A causa é **mecânica e inevitável num commit verde** (100 → 132 em muitos testes), e a mensagem da C cita "ordens escritas de Arthur"; **não vejo** registro de que a tolerância de **arquivos** tenha sido aprovada. **Recomendo** aceitar esta exceção por escrito e, para não repetir em toda mudança de população, **ler a população de uma constante só** (`NpcLifeCheck.EXPECTED_POPULATION` já existe; hoje o 132 está repetido em cerca de 14 arquivos).
**MENOR**
- **R9-M1. `miner` e `shepherd` sem linha no `IncomeStub`.** `data/income_stub.json` (TEMP-LW-066, **não tocado**) cobre só os cinco ofícios antigos, então os **12** NPCs novos **não têm nenhum alívio de `income`** enquanto o `IncomeStub` for a única fonte (`income` sobe 2 por hora e chega a crítico em cerca de 32 horas). Sem consequência de morte (só a fome mata), mas muda o comportamento deles. **Recomendo** duas linhas TEMP ou aceitar até a LW-095 trocar a fonte (o `WageIncome` da A já existe, R8).
- **R9-M2. O estoque de 3.000 do C acaba em ~36 dias** (conta acima). Para o soak de 30 dias serve; o soak de **um ano** (`soak_npc_year.gd`, fora do `check_all`) veria **fome no C** depois do dia 36, porque o C não tem lavrador nem mercado na economia (os dados de `data/economy` não citam `test_settlement_c`). Registrar como limitação até a LW-094 e o mercado do C.
- **R9-M3. Comentários velhos:** `population_plan.gd:10` ("A escala de 100 NPCs é provisória"; agora são 132) e `test_settlements_data.gd` ("locais de trabalho para os cinco ofícios"); o `sed` sem efeito em `test_check_content_ids.sh:38`.
- **R9-M4. Ordem natural de `Dictionary` só para uma mensagem.** `population_plan.gd:110` percorre `used` (um `Dictionary`) para achar o **primeiro** local acima da capacidade; o estado não depende disso, mas a **mensagem** de erro pode variar com a ordem de inserção (regra do `MODELO.md`). Ordenar por id.
- **R9-M5. O mesmo 132 duplicado em muitos testes** (ver R9-I3).

**8. RISCOS.** A 097e vai mexer em **dados da economia da A** (receitas) e em dois arquivos que a A também edita (`docs/modules/economy.md`, `data/economy/`): risco de conflito de coordenação (R9-I1 e R9-I2); o oráculo e o soak de 30 dias **dependem da ordem da junção** e precisam ser recalculados na Fase B da C (já decidido); o `IncomeStub` e o `WageIncome` coexistem (R8-I1).

**9. PENDÊNCIAS.** *Suas:* nomear o dono de `service_posts.json` (R9-I2); aceitar ou recusar a exceção de arquivos (R9-I3). *Da C:* R9-I1 na 097e e os menores. *Que eu não consegui verificar:* (1) **o `check_all` e os 9 valores do oráculo** (nem o terceiro conjunto); (2) a aprovação de Arthur que a mensagem cita para a população (132, A 60, B 44, C 28 [HIP]); (3) o resultado **real** da junção (o `merge-tree` só prevê texto); (4) o **número de 28 testes** (conto 21 arquivos; a C conta por função); (5) a 097e, ainda não publicada no remoto.

**ACOMPANHAMENTO**
- **Avanço:** a LW-097 está em **4 de 5 partes** (a, b, c e d revisadas; a 097e vem); nada dela está no `main`. Código da Fase 5: 0%.
- **Próxima tarefa recomendada:** **`096a` da A** (`ebd0a06`, já no remoto sobre a `2c8525b`), que entra na fila agora; o vigia do GitHub segue armado.
- **Decisões que dependem de Arthur:** (1) **dono de `service_posts.json`** (recomendo a A, na parte final da LW-095, porque o `economy.md` o põe lá e o arquivo é da economia); (2) **exceção de tamanho da 097d** (recomendo aceitar por escrito e centralizar a constante da população).
- **Git:** só leitura nos ramos remotos; este relatório é o único commit (`status-b`); `main` em `ca86f87`.


## AUDITORIA DE ENTRADA NO `main` — A: LW-093 (partes 1 a 7), `ca86f87` → `f2bcb4c` · push às 21:21, detectado às 21:31, auditado às 11/11/2026 21:37 (Brasília; dentro dos 20 minutos)

**Veredito: SÃ. Nada fugiu do combinado.** Ordem **A primeiro, C depois**: cumprida (a C ainda não entrou).

| Item | Resultado |
|---|---|
| **Forma da entrada** | **Avanço simples:** o `main` antigo (`ca86f87`) é ancestral do novo (`f2bcb4c`); sem `--force`. São 15 commits: a junção das correções da 092 (`092d` a `092g`, que a R4 revisou), as 7 partes da 093 (ponta `e16072b`, que a R6 revisou), uma **junção do `main` dentro do ramo da A** (`0abcc5f`, feita **antes** do push) e um commit de status (`f2bcb4c`). |
| **O que a junção e o status trouxeram além do que revisei** | **Só `docs/ROADMAP_STATUS.md`** (+1 parágrafo): a LW-093 "entrou pela Fase B, aprovada por Arthur, sem tag"; **"não altera contagens nem porcentagens: o marco 2 de hash só fecha na LW-096a"**. Nenhum outro arquivo mudou fora do trabalho da A. |
| **Conflitos resolvidos na junção** | 5 documentos (`backlog.md`, `app.md`, `economy.md`, `npc.md`, `world.md`). Conferi **linha por linha o que foi removido** do `main` antigo: só as reescritas intencionais da A (renomeação `market_reserved` → `market`, `peek_quote` com o ator, o status da LW-088a). **Nada da 146g e da 146h se perdeu.** Nenhum marcador de conflito esquecido (`<<<<<<<`) em lugar nenhum. |
| **Arquivos protegidos (AGENTS 12.5)** | **Nenhum alterado** (`AGENTS.md`, `GDD.md`, `TECHNICAL_ARCHITECTURE.md`, `DECISIONS.md`, `DEVELOPMENT_ROADMAP.md`, `project.godot`, `.gitignore`, `addons/`, `tests/fixtures/`). |
| **Tags** | **Nenhuma** nova (as remotas seguem `fase-0-concluida`, `fase-1-concluida` e `fase-2-concluida`). |
| **Testes antigos alterados** (contra o `main` anterior) | **10 arquivos**, todos já revisados: os 7 da R6 (`test_action_catalog`, `test_place_boxes`, `test_place_chooser`, `test_routine`, `test_settlements`, `test_settlements_data`, `test_new_occupation_by_data`), o oráculo e os 2 da 092e na R4 (`test_economy_trade_api`, `test_trade`), mais o `README` de integração. Nenhum teste antigo novo depois da ponta revisada. 9 testes novos. |
| **Oráculo e soak** | O oráculo (`test_npc_split_oracle.gd`) é **idêntico** ao da ponta `e16072b`: os 9 valores mudaram **só na parte 1** (marco 2, causa: as contas dos NPCs entram no bloco `economy`), e a **ratificação** que você deu à A cobre isso. Nada mudou depois. O soak curto roda dentro do `check_all` (abaixo). |
| **`check_all` independente do `main` novo** (cópia exportada por `git archive` no meu scratchpad; nada escrito no repositório nem nos worktrees alheios) | **VERDE.** Código 0 (21:32:26 a 21:36:49), `Scripts 151`, `Tests 1322`, `Passing Tests 1322`, `Asserts 293484`, `Time 192,9 s`; `Warnings 1` e `Deprecated 1` iguais aos de sempre; "IDS DE CONTEÚDO: tudo existe (55 conferências)"; **0** `SCRIPT ERROR` e **0** `Parse Error`; as 68 linhas `ERROR` são **idênticas, tipo por tipo**, às do `main` anterior; as de "falhou/failed" sobem de 9 para 11 porque entraram **dois nomes de teste** (`test_a_failed_delivery_…` e `test_a_failed_payment_…`). Isso **prova que os valores do oráculo e do soak batem com o código do `main`**. |
| **Junção "sã" (rotas e economia, uma assinatura, `c_market_01`)** | **Não se aplica a esta entrada** (é da C). A economia **está** no jogo real (`test_game_economy_wiring` e `test_npc_buys_food` passam). |
| **Pendências conhecidas que entraram junto** | **R6-I1** (a economia muda antes de a ação ser validada) e **R6-I2** (`sell` sem valor, código morto): **vão para a A** (você decidiu); **seguem abertas** no `main`. Nenhuma é bloqueio. |

**O que eu NÃO consegui verificar:** (1) o `check_all` **da A** (rodei o meu, independente, sobre o mesmo commit); (2) **quando** o `main` andou, só vejo os horários dos commits (21:21) e a minha detecção (21:31); (3) se a Fase B da A tinha **autorização** própria para o push no `main` (o seu bloco diz que você aprovou a LW-093; **o push eu não vi**).

**Próximo:** `lw-097e-producao-e-estoque` (`4e614b5`, publicada às 21:30) e depois `lw-096a-contratos-nucleo` (`ebd0a06`). `main` agora em **`f2bcb4c`**. Vigia do GitHub **rearmado** com a nova linha de base.


## AUDITORIA DE ENTRADA NO `main` — C: LW-117i (só documentos), `f2bcb4c` → `4372f7f` · commits às 21:35, detectado às 21:44, auditado às 11/11/2026 21:46 (Brasília; dentro dos 20 minutos)

**Veredito: SÃ. Nada fugiu do combinado.** Ordem "A primeiro, C depois": respeitada (a 117i é só documento e entrou **depois** da LW-093; a junção da LW-097 ainda **não** aconteceu).

| Item | Resultado |
|---|---|
| **Forma da entrada** | **Avanço simples** (o `main` anterior, `f2bcb4c`, é ancestral); **2 commits**, sem merge: `5a53963` (o registro) e `4372f7f` (a linha de status). |
| **O que mudou** | **12 arquivos, todos em `docs/`** (+64 −14). **Nenhum arquivo de `src/`, `tools/`, `tests/`, `data/`, `scenes/` ou `addons/`.** |
| **Arquivos protegidos (AGENTS 12.5)** | **Dois alterados:** `docs/DECISIONS.md` (+50 −4) e `docs/DEVELOPMENT_ROADMAP.md` (1 linha). A C diz "por ordem escrita de Arthur" (a mensagem do commit); **eu não vejo essa ordem**, mas o conteúdo bate com o plano (abaixo). Nenhum outro protegido tocado. |
| **`DECISIONS.md`** | Versão **0.16**. **Entradas novas (3):** **DEC-234 PROPOSTA** (a exceção pontual à DEC-107 e ao AGENTS 4.17: leitura de campo de evento pelo nome em **três pontos fechados**; "nunca APROVADA sem outra ordem escrita"), **DEC-235 APROVADA** (a tabela do `economy.md` seção 6: 14 locais de produção, 6 postos, 20 locais `work`) e **DEC-236 APROVADA** (a LW-097 e o salário, LW-095 só código, vêm antes da LW-094, que vai junto do marco 3 de hash). **Status antigo: nenhum alterado** (conferi as linhas removidas: só versão, totais, a nota da DEC-053 e a nota de faixas). **Totais recontados por mim: 153 APROVADA · 55 PROPOSTA · 17 PENDENTE · 10 DESCARTADA · 1 SUBSTITUÍDA = 236, igual ao declarado.** A nota da DEC-053 foi restaurada (a correção é só trocar dois `|` por `*`: o achado R5-M1). Faixas: A passa a DEC-237 a 239. |
| **Roadmap** | Só a linha da **LW-094**: dependências passam a incluir a LW-095 (só o código do salário) e a LW-097, e o aceite "ainda no marco 2" vira "marco 3, entregue junto dele e só pela causa fim do `FoodStub`" (DEC-236). |
| **Correções de texto** | As dos meus achados **R4-M4** (`economy.md`: o código já arredonda a tarifa para cima), **R5-M2** (cabeçalhos das fichas da Fase 4: "aprovado por Arthur **apenas quanto às DEC-227 a DEC-233**"), **R5-M3** (nota dos eventos que já existem) e **R5-M4** (`events.md`: o `PriceChanged` existe e só os testes o ouvem), mais o registro `0016`. |
| **`ROADMAP_STATUS.md`** | +1 parágrafo: a 117i "entrou pela Fase B curta"; **nenhuma contagem muda**. |
| **Tags** | **Nenhuma** nova. |
| **Testes, oráculo e soak** | **Inalterados por construção** (nenhum código, teste ou dado mudou; `git diff --stat` de `src tools tests data scenes` vazio). O **único** verificador do `check_all` que lê documento é a regra 8 do `check_architecture` (todo evento consta na primeira coluna de `docs/events.md`): conferi que a primeira coluna tem os **mesmos 60 eventos** antes e depois. **`check_all`: NÃO EXECUTADO** nesta entrada (só documentos; a última rodada, no `f2bcb4c`, foi verde e o código é idêntico). |
| **Junção "sã" (rotas e economia; uma assinatura; `c_market_01`)** | **Não se aplica** (é da LW-097, que ainda não entrou). |

**Efeitos para o que vem (meus achados anteriores):** (1) a **DEC-235 responde o R9-I2**: "os 6 postos de serviço são da **LW-095**", então `data/economy/service_posts.json` é **da A**, na parte final da LW-095; (2) a **DEC-236** fixa que a LW-094 (fim do `FoodStub`) vai **com o marco 3**, o que pesa no R9-M2 (o estoque de comida do C) e na ordem dos hashes; (3) a **DEC-234** fecha, como PROPOSTA, a exceção de leitura de evento pelo nome que eu tinha deixado pendente (R6/146g).

**O que eu NÃO consegui verificar:** (1) a **ordem escrita de Arthur** que a C cita para DEC-235, DEC-236 (APROVADAS) e para as duas mudanças em arquivo protegido; (2) o `check_all` desta entrada (não rodei); (3) a hora exata do push (só vejo os horários dos commits, 21:35, e a minha detecção, 21:44).

**Próximo:** fechar o relatório da **097e** (R10) e depois `lw-093k-ajustes-da-r6` (A), `lw-096a-contratos-nucleo` e `lw-096b-porta-dos-contratos` (A). `main` em **`4372f7f`**. Vigia a rearmar.


## RELATÓRIO — R10: LW-097e da conversa C (`4e614b5`, base `f346ed9`)        Status: PRONTA PARA REVISÃO (revisão independente, SÓ LEITURA) · 11/11/2026 21:47 (Brasília)

**1. RESUMO.** **Nenhum bloqueio.** Os 14 locais de produção, o mercado do C (10 linhas) e o estoque de 30 dias **batem com a tabela do `economy.md`** e com a DEC-235; a conta dos 30 dias que a C escreveu à mão no teste **bate, número por número, com o meu recálculo independente**; as 14 expectativas de teste atualizadas **não perderam verificação**; e o `check_all` que **eu** rodei na cópia exportada da 097e está **VERDE** (1344 de 1344). Há **4 pontos importantes**, dois deles são os R9-I1 e R9-I2 **que a 097e não resolveu** (o R9-I2 agora tem resposta na DEC-235), um é a **comida do C** e um é um **aviso sobre a junção** com o `main` novo.

**2. ARQUIVOS CRIADOS.** Nenhum no projeto. **3. ARQUIVOS MODIFICADOS.** Só `STATUS-B.md`.

**4. DECISÕES TÉCNICAS (do revisor).** Alvo: um commit, `4e614b5` ("LW-097e: locais de produção, estoque inicial de 30 dias e testes de distribuição"; publicado às 21:30), sobre a 097d; 16 arquivos. Li os dados novos, as duas mudanças em `src` (só comentários), os dois testes novos **inteiros**, o diff de **todos** os testes antigos tocados e dos dois documentos. Comparei com `economy.md` seção 6 e `docs/economy/dados.md`, DEC-142, 166, 176, 235 e 236 e o roadmap (aceite da LW-097). **Novidade desta rodada:** como a 097e é a parte que mexe nos dados da economia da A, **rodei o `check_all` dela numa cópia exportada** (`git archive` no meu scratchpad; nada escrito no repositório nem em worktree alheio). Sem proposta de DEC.

**5. TESTES EXECUTADOS.** **`tools/check_all` na cópia exportada da 097e (`4e614b5`): VERDE**, código 0 (21:39:44 a 21:44:21), `Scripts 148`, `Tests 1344`, `Passing Tests 1344`, `Asserts 296179`, `Time 205,7 s`; `Warnings 1` e `Deprecated 1` como sempre; "IDS DE CONTEÚDO: tudo existe (123 conferências)"; **0** `SCRIPT ERROR`, **0** `Parse Error`; as 68 `ERROR` e as 9 de "falhou/failed" são as de sempre (mensagens que os testes provocam). Isso confirma o que a C diz, **só da 097e sozinha** (sem a A). Também rodei: script de recálculo dos 30 dias (e de peso e de ofício), contagem DEC-126, `git merge-tree --trivial-merge` (só imprime) contra o `main` novo e contra a ponta `095d` da A.

**6. RESULTADOS**
| Pergunta | Resposta |
|---|---|
| **`production_sites.json`** | **14 linhas** (A 5, B 6, C 3) **como a tabela** (DEC-235); cada `place_id` é o da linha de população da 097d e cada `workers_wanted` **é igual** à equipe dessa linha (A: 12, 12, 10, 6, 6; B: 8, 8, 8, 4, 4, 4; C: 8, 6, 6). O `test_economy_distribution.gd` confere isso, mais "nenhum povoado se basta" (A depende de pão, tecido e ferramenta; B, de farinha, tábua e ferramenta; C, de pão, tecido, tábua e madeira) e "todo bem necessário tem produtor", e **testa os próprios testes** (cadeia que se basta; bem que ninguém faz). |
| **Mercado do C** | **10 linhas** (os 10 bens), 30 no total; **o estoque inicial é igual ao alvo** (teto de compra 20000 = 2× o alvo), exceto a **farinha do B** (alvo 810, inicial **1.620**) e a **madeira do C** (alvo 270, inicial **540**), que a C põe na **metade do inicial** para o teto de compra caber no peso do mercado. |
| **Estoque de 30 dias: a conta** | **Bate.** Recalculei do zero com `recipes`, `recipe_inputs`, `site_upkeep`, `production_sites` e a agenda (lavrador 10 h, lenhador 9 h, artesão 9 h; manutenção arredondada para cima uma vez): **A** tecido 25 e ferramenta 29; **B** farinha 1.620, tábua 21 e ferramenta 29; **C** tecido 9, tábua 15 e madeira 540. **Os mesmos números da tabela escrita à mão no teste** e **todos cobertos** pelo `initial_stock`. |
| **Cabe no mercado?** | **Sim, com folga curta.** Peso inicial: **A 1.003 (20%)**, **B 3.952 (79%)** e **C 3.573 (71%)** da capacidade de **5.000**. A maior parte do B é a farinha (3.240) e a do C é a madeira (2.700). |
| **As 14 expectativas de teste existentes** | **Nenhuma perdeu verificação.** Seis arquivos: `test_economy_debug_and_kinds`, `test_economy_markets_api`, `test_economy_production_api`, `test_market_data`, `test_markets` e `test_production_data`. Só mudam contagens e IDs (mercados 2 → 3; locais 0 → 14; `owners` 2 → 17; dinheiro criado 6.000 → 11.800 = 3 × 3.000 + 14 × 200; pão 60 + 40 → 60 + 40 + 200; tábua 51 → 66; locais dos testes de save renumerados `"3"` → `"4"`). **Fortalecidos:** o `production_api` ganhou um caso do **jogo real** (5 locais no A, 17 IDs gastos, bloco `production` no save, `validate()` vazio). |
| **Testes novos** | 2 arquivos: `test_economy_distribution.gd` (5 testes) e `test_initial_stock_covers_30_days.gd` (4: cobertura real, tabela à mão, "falta uma unidade" e arredondamento, e lotes por hora). Cobre aceite, erro e caso-limite. |
| **Hash e causas (DEC-175)** | **A 097e não toca o oráculo** (`test_npc_split_oracle.gd` fora da lista de arquivos) e **não muda hash**: o oráculo monta o mundo por `GameModules.register(…)` **sem** `economy_setup`, então os dados de economia não o alcançam (a mesma razão do "nenhum hash muda" da A). **Causa:** nenhuma. |
| **Tamanho (DEC-126)** | **321 linhas** de código e teste (só teste: os 2 arquivos de `src` mudam só comentário), em **10 arquivos `.gd`** (2 de `src`, 6 de teste antigo, 2 de teste novo): **acima do teto de 300, dentro da tolerância de 450 e de 12 arquivos.** |

**7. PROBLEMAS ENCONTRADOS (por gravidade)**
**Bloqueante: nenhum.**
**IMPORTANTE**
- **R10-I1. O R9-I1 continua e agora tem locais de produção reais por trás.** `recipes.json` **não foi tocado**: `mine_ore` ainda espera **`lumberjack`** e `shear_wool` **`farmer`**, mas a população põe **mineiros** em `site_c_mine_ore` e **pastores** em `site_b_shear_wool` (confirmei por script: **2 dos 14 locais divergem**). Hoje não muda número nenhum (as horas coincidem: mineiro 9 = lenhador 9; pastor 10 = lavrador 10), e o `test_economy_distribution` confere a **equipe** mas **não o ofício**; o verificador (`check_content_ids`) não foi estendido. **Recomendo** trocar as **duas** linhas de `recipes.json` (`miner` e `shepherd`; arquivo da **economia, dono A**) e acrescentar a regra "o ofício da linha de população é o da receita do local". Hoje o teste dos 30 dias usa o ofício **esperado** da receita para as horas, então quando a receita mudar ele passa a ler a agenda do mineiro e do pastor (já existem), sem risco.
- **R10-I2. Os 6 postos de serviço continuam sem dados, mas agora o dono está definido.** A **DEC-235 (APROVADA, na 117i)** diz "os 6 postos de serviço são da **LW-095**": logo `data/economy/service_posts.json` (6 linhas) é **da A**, na parte final da LW-095. A 097e **não** o cria (correto). Falta a A fazer; sem o arquivo, os **36** NPCs de guarda e estalajadeiro seguem sem salário. **Recomendo** que o teste de distribuição passe a conferir também os postos quando o arquivo existir.
- **R10-I3. A comida do C não é de 30 dias, e o fim do `FoodStub` (DEC-236) vai exigir uma decisão.** O aceite da LW-097 pede "estoque de 30 dias dos bens que importa (**comida no C**)", mas 30 dias de pão dos 28 do C são **2.520 unidades** e o mercado do C passaria de **5.893** de peso (capacidade 5.000). A C põe só **200** de pão (≈ 2,4 dias) e 10 de grão, **exclui a comida do teste de dados** ("quem prova é o soak de 30 dias sem morte") e **deixa o `FoodStub` de 3.000 (097d) segurar a fome** (≈ 36 dias). Está **escrito** em `docs/economy/dados.md`, então é transparente; mas a **DEC-236** manda a LW-094 (que **remove** o `FoodStub`) para o **marco 3**: a partir daí o C **não tem** de onde comer sem o comerciante (LW-098) ou sem um mercado maior. **Decisão sua, antes da LW-094:** subir a capacidade de peso do mercado do C, trocar o pão por um bem mais leve, ou aceitar escassez no C até a LW-098. **Recomendo** registrar a pergunta agora (backlog ou DEC PROPOSTA).
- **R10-I4. AVISO sobre a junção com o `main` novo (A já está nele).** (a) **Conflitos de texto previstos** entre o `main` (`f2bcb4c`, com a LW-093) e a 097e: **7 arquivos, 9 trechos** (`data/world/README.md`, `docs/events.md`, `docs/modules/world.md`, `src/app/game_app.gd` ×2, `src/app/simulation_host.gd` ×2, `src/sim/economy/README.md`, o oráculo); `docs/events.md` e o `README` da economia **não** estão na lista de conflitos que o bloco da C prevê (são documentos); o `docs/backlog.md` **deixou** de conflitar. (b) **Se a LW-095 da A (`2c8525b`) entrar no `main` antes da Fase B da C**, sobe para **9 arquivos e 11 trechos** e entra **`tests/unit/test_economy_production_api.gd`**, um **arquivo de teste** (a C reescreveu todas as linhas dos casos de save para `"4"`; a A trocou as linhas `:181-182`); **recomendo** a C fazer a Fase B **antes** de a 095 entrar, ou você autorizar de antemão esse arquivo. (c) **Efeito semântico, não de texto:** com o jogo real tendo **3 mercados e 14 locais**, o teste da A `tests/unit/test_game_economy_wiring.gd` **vai falhar** em **`:31`** (`npc_ids[0] == 3`: o primeiro NPC passa a ser o **18**, porque 3 mercados e 14 locais gastam 17 IDs) e **`:35`** (dinheiro criado `6000 + 60 × NPCs` passa a **3 × 3.000 + 14 × 200 + 60 × 132 = 19.720**); `:28` (`[1, 2]`) segue válido. São **duas asserções** de teste **existente**; pelo bloco da C (que só autoriza alterar os 9 valores do oráculo, o hash do soak e o já listado) ela teria de **parar**. **Recomendo** você **autorizar de antemão** o ajuste dessas duas linhas na Fase B da C. (Isto vem da leitura do código; **não montei a junção**.)
**MENOR**
- **R10-M1. Pouca folga de peso** no B (79%) e no C (71%): o comerciante (LW-098) e o crescimento da produção vão comer o resto; cada bem novo de importação já não cabe sem subir a capacidade.
- **R10-M2. `PERIOD_LCM = 2520`** no teste dos 30 dias (`test_initial_stock_covers_30_days.gd:15`) é uma constante **bem explicada** e o teste **falha com mensagem clara** se um período novo não dividir; só registro que a manutenção nova precisa subir a constante.
- **R10-M3. Estoque inicial = teto de compra** na farinha do B e na madeira do C (preço começa no piso até o estoque descer ao alvo, texto da C em `docs/economy/dados.md`, **[HIP]**): é escolha de jogo da C, documentada; fica para a calibração (LW-112).

**8. RISCOS.** O R10-I4(c) é o mais provável de **parar a Fase B da C de madrugada**; o R10-I3 vira problema real só na LW-094; a 097e e a economia da A passam a compartilhar `recipes.json` e `market_targets.json` (risco de coordenação, R9-I1).

**9. PENDÊNCIAS.** *Suas:* R10-I3 (o que fazer com a comida do C); autorizar de antemão as duas asserções de `test_game_economy_wiring.gd` (R10-I4c); decidir se a C faz a Fase B antes da LW-095 da A entrar (R10-I4b). *Da A:* `service_posts.json` (R10-I2). *Da C:* `recipes.json` e a regra do verificador (R10-I1). *Que eu não consegui verificar:* (1) o `check_all` **da C** (rodei um meu, independente, **só da 097e**: **não** prova a junção); (2) a "autorização de Arthur" para as 14 expectativas (a mensagem diz que existe); (3) o resultado **real** da junção (o `merge-tree` só prevê texto; a falha de `test_game_economy_wiring` é **leitura de código**, não execução).

**ACOMPANHAMENTO**
- **Avanço:** a LW-097 está em **5 de 5 partes** (a a e) nos ramos da C; **nada** dela está no `main`; a Fase B (a junção) é o passo seguinte. Código da Fase 5: 0%.
- **Próxima tarefa recomendada:** as revisões da fila (`093k`, `096a`, `096b` da A) e, se o vigia avisar, a auditoria da Fase B da C.
- **Decisões que dependem de Arthur:** R10-I3, R10-I4(b) e R10-I4(c) (cada uma com a recomendação acima).
- **Git:** só leitura nos ramos remotos; este relatório é o único commit (`status-b`); `main` em `4372f7f`.


## RELATÓRIO — R11 a R13: ramos novos da conversa A (093k `8ae5bb3`, 096a `ebd0a06`, 096b `bfbc9a3`)        Status: PRONTA PARA REVISÃO (revisão independente, SÓ LEITURA) · 11/11/2026 21:50 (Brasília)

**1. RESUMO.** **Nenhum bloqueio.** **R11 (`lw-093k-ajustes-da-r6`)** resolve o que eu apontei na R6: a troca de `eat` passa a ser **atômica** (a economia só mexe depois de a necessidade ser conferida), as duas escalas ganham nome, o `sell` sem valor vira **[LIM] escrita** e os menores vão para o backlog. **R12 (`lw-096a-contratos-nucleo`)** entrega o livro de contratos com **custódia** e cumpre a seção 8 do `economy.md` no que a parte propõe. **R13 (`lw-096b-porta-dos-contratos`)** entrega a porta (`request_post_contract`, `request_accept_contract`, `peek_contract` e `peek_contracts`) e o evento `ContractOffered`; tem **1 ponto importante** (uma recusa gasta um ID e muda o `state_hash`). Nenhum teste existente foi alterado em nenhum dos três. A pilha é **linear** e inteira sobre a ponta antiga `e16072b`: **095a → 095b → 095c → 095d → 096a → 093k → 096b**.

**2. ARQUIVOS CRIADOS.** Nenhum no projeto. **3. ARQUIVOS MODIFICADOS.** Só `STATUS-B.md`.

**4. DECISÕES TÉCNICAS (do revisor).** Alvo: 3 commits (um por ramo) sobre `2c8525b` (R8): `ebd0a06` (21:21, 096a), `8ae5bb3` (21:32, 093k) e `bfbc9a3` (21:38, 096b). Li os diffs de `src` inteiros, o `ContractBook` (234 linhas) **inteiro**, os casos dos testes novos e o `npc.md` e o backlog. Comparei com `economy.md` seção 8 e `npc.md` 14.2, 14.9 e com os meus achados da R6 e da R8. Sem proposta de DEC.

**5. TESTES EXECUTADOS.** **NÃO EXECUTADO: o Godot e o `check_all` da A** (nesta rodada não exportei os três ramos: são só da A e a parte que mexe na economia que a C toca já foi coberta na R10). **O que rodei:** contagem DEC-126 por ramo; `git grep` de importações, `float`, tempo e literais; `git merge-tree --trivial-merge` (só imprime) da pilha da A contra o `main` novo e contra a 097e. Todos terminaram sem erro.

**6. RESULTADOS**
| Ramo | O que traz | Veredito |
|---|---|---|
| **R11 · 093k** (`8ae5bb3`; 106 linhas, 5 `.gd`) | **R6-I1:** o `ActionRunner` pergunta ao provedor `completion_need_id` **antes** de `complete_action` (`action_runner.gd`, 3 linhas; `npc_trade.gd`, `completion_need_id`, só consulta) e falha **sem mexer em saldo, inventário nem conservação** se a necessidade não existe; teste novo `test_npc_trade_atomicity.gd` (3 casos: necessidade desconhecida não muda nada nem liga o sinalizador; com a necessidade o `eat` come; a pergunta nomeia a necessidade da comida). **R6-M1:** `PERCENT_SCALE` (100) e `PERMILLE_SCALE` (1000) em `npc_trade.gd`. **R6-I2:** `[LIM]` no `npc.md` 14.2 e 14.9 e no backlog ("`sell` sem valor até a LW-098; `can_buy_food` e `has_goods` sem chamador até lá"). **R6-M2 a M5:** uma linha cada no backlog (com o arquivo e a linha). **Nenhum teste existente alterado.** | **Resolve o R6-I1 na parte atômica**, o R6-I2 como limitação **escrita** (a opção que eu dei) e o R6-M1; M2 a M5 **registrados, não corrigidos** (exigem autorização por teste). |
| **R12 · 096a** (`ebd0a06`; 352 linhas, 5 `.gd`) | `ContractBook` (`contracts/`): **postar** `labor` e `delivery` tudo ou nada (emissor aberto, recompensa ≥ 1, prazo depois de agora, objetivo possível: local de trabalho **conhecido** por local de produção ou posto, destino aberto), **retendo** a recompensa na custódia (conta do tipo `contract`, `contract_escrow`); **aceitar** só `open`, um aceitante aberto que não é o emissor; estado e save (bloco `contracts` **só quando há contratos**, sem mudar o hash de quem não tem); `validate()` impõe que a custódia guarda a recompensa inteira **só** enquanto aberto ou aceito; códigos novos `ECON_CONTRACT_IMPOSSIBLE`, `ECON_UNKNOWN_CONTRACT`, `ECON_CONTRACT_NOT_OPEN`. 6 testes (postar `labor` e `delivery`; impossível ou sem fundos não muda nada; aceitar; save e bloco ruim; invariante da custódia). Sem aleatoriedade nem relógio (quem chama passa o `now`); só economia (camadas limpas). | **Cumpre** o contrato no escopo da parte. |
| **R13 · 096b** (`bfbc9a3`; 245 linhas, 5 `.gd`) | `request_post_contract(kind, issuer_id, reward, deadline, objective)` (devolve o `contract_id` e publica **um** `ContractOffered`), `request_accept_contract`, `peek_contract` e `peek_contracts(state, issuer, place)` (cópias, por ID crescente); `ContractOffered` em **`economy/api/`** (o `npc` cita, regra E, como o `WagesPaid`); sem `setup` do `World` nada é postado. 6 testes (postar e publicar um evento; mostra bem, quantidade e destino; recusas; aceitar; filtro; save). | **Cumpre**, com o **R13-I1** abaixo. |

**Tamanho (DEC-126):** 093k **106** (5 `.gd`); 096a **352** (**acima do teto de 300, dentro da tolerância de 450**; 5 `.gd`); 096b **245** (5 `.gd`).

**7. PROBLEMAS ENCONTRADOS (por gravidade)**
**Bloqueante: nenhum.**
**IMPORTANTE**
- **R13-I1. Uma recusa de `request_post_contract` gasta um ID e muda o `state_hash`.** `economy_module.gd` (`request_post_contract`) chama `_ids.next_id()` **antes** de `contracts.post(...)` validar: as **7 recusas** do teste `test_a_refused_contract_changes_nothing…` (`:86-110`) gastam **7 IDs** do gerador do `core`, cujo contador entra no `state_hash`. A mensagem da A ("as recusas não mudam nada") e o `economy.md` seção 8 ("erro e nada muda") **não valem para o contador de IDs**; o teste afirma saldo, eventos e número de contratos, **não** o contador. Efeito: uma interface ou um NPC que tente postar e seja recusado **muda o hash e desloca os IDs seguintes**, em jogo. **Recomendo:** validar **antes** de pedir o ID (separar a validação do `post`) e acrescentar ao teste a comparação do `ids.serialize()` (ou do `state_hash`) antes e depois das recusas.
**MENOR**
- **R12-M1. `post` pode deixar a custódia aberta se a transferência falhar** (`contract_book.gd:73-77`): abre o dono do tipo `contract` e só depois transfere; se a transferência falhasse, o dono fica aberto **sem contrato** (o saldo é conferido antes, então o caminho é praticamente inalcançável). Mesmo desenho do R8-M1; **recomendo** um teste do caminho ou desfazer a abertura.
- **R12-M2. Um save com contrato `labor` ou `delivery` de recompensa 0 passa.** `_parse_contract` (`:216`) aceita `reward` 0 em qualquer tipo ("só a vaga é 0") e `validate()` **pula** recompensa 0 (`:154-155`), então a regra "recompensa de 1 ou mais" só vale ao postar. **Recomendo** exigir por tipo também no `load_from`.
- **R12-M3. `accept` não confere o prazo** (`:86-101`): enquanto a parte do prazo não existe, um contrato vencido ainda se aceita. É a divisão declarada da A (o prazo vem em parte seguinte); só registro para **não levar a 096a ao `main` sozinha**.
- **R12-M4. Estado novo sem `debug_summary`.** Como no R8-M2: `economy_persistence.gd` (`summary`) não conta os contratos (AGENTS 4.15).
- **R12-M5. Vocabulário e campos "para depois".** `VACANCY` já está em `CONTRACT_TYPES` e `ContractQuery` (096b) declara seis campos da vaga (`workplace_id`, `settlement_id`, `occupation_id`, `wage_per_hour`, `workers_wanted`, `workers_assigned`) que **nenhum caminho preenche** (a vaga é parte seguinte): AGENTS 5.5 pede não criar campo para depois. A A o documenta; é inofensivo.
- **R13-M1. `peek_contracts(..., place_id)` só casa o `labor`** (`economy_queries.gd`: `delivery` e a vaga não têm `place_id`): o filtro por "local de trabalho" ainda não diz o que fazer com a vaga (que usa `workplace_id`); será preciso na parte das vagas.
- **R11-M1. Resíduo da 093k.** A checagem de necessidade desconhecida **dos efeitos extras** (do `IncomeStub`) segue **depois** de `complete_action` (`action_runner.gd`, laço dos `extras`): só falharia com dado inconsistente do stub, que é temporário; e o sinalizador `_food_from_inventory` **segue** (a A explica: tirá-lo exige trocar o `test_the_food_stub_only_consumes…`, e "nenhum teste existente está autorizado"; está no backlog).

**Juntando com o `main` (previsão por `merge-tree`, só texto):** a **pilha inteira da A** (`bfbc9a3`) × `main` novo (`4372f7f`): **4 arquivos tocados pelos dois lados, 2 conflitos, ambos em documento** (`docs/backlog.md` e `docs/events.md`); `economy.md` e `npc.md` juntam limpos. A **A precisa juntar o `main` na pilha antes do push**, porque a pilha está sobre a `e16072b`. **E o cruzamento com a C (097e) piora:** A (`096b`) × C (`097e`) = **10 arquivos, 12 trechos**, **dois a mais do que o `main` novo × 097e** (7 e 9): entram **`docs/modules/npc.md`** (da 093k) e **`tests/unit/test_economy_production_api.gd`** (um **teste**, o que o R10-I4(b) previu). **Quem entra primeiro no `main` muda o que o segundo tem de resolver.**

**8. RISCOS.** O R13-I1 só aparece com quem **poste** contratos (hoje ninguém: a LW-096a do NPC e a LW-104 virão depois); a pilha da A cresce sem parar e cada entrada nova no `main` muda a Fase B da C (ver acima); a 096a **sozinha** deixaria o prazo sem tratar (R12-M3).

**9. PENDÊNCIAS.** *Da A:* R13-I1 e os menores (ela decide); juntar o `main` antes do push. *Suas:* (1) **a ordem de entrada da A (095/096/093k) e da Fase B da C no `main`** (recomendo a C **primeiro**, enquanto o conflito com a A é só de documento; depois a A resolve os dela); (2) autorizar de uma vez as linhas de teste do R6-M2 (7 linhas) para a A as corrigir. *Que eu não consegui verificar:* (1) o `check_all` **da A** (não rodei estes três); (2) o resultado **real** das junções (o `merge-tree` só prevê texto); (3) se a 096a precisa de **parte seguinte** para ser entregue (o prazo e a conclusão).

**ACOMPANHAMENTO**
- **Avanço:** LW-095 em 4 partes e LW-096 em 2 (a, b) nos ramos da A; **nada** disso no `main`; as partes que faltam: conclusão, prazo e vagas (LW-096), `service_posts.json` e remoção do `IncomeStub` (LW-095).
- **Próxima tarefa recomendada:** as revisões da fila, se o vigia avisar; e as auditorias de entrada no `main`.
- **Decisões que dependem de Arthur:** a **ordem de entrada A × C** (recomendo a C primeiro) e a **autorização das 7 linhas de teste** do R6-M2.
- **Git:** só leitura nos ramos remotos; este relatório é o único commit (`status-b`); `main` em `4372f7f`.


## RELATÓRIO — R14: ramo novo da conversa A (`lw-096c-conclusao-dos-contratos`, `bc733af`, LW-096 parte c)        Status: PRONTA PARA REVISÃO (revisão independente, SÓ LEITURA) · 11/11/2026 21:53 (Brasília)

**1. RESUMO.** **Nenhum bloqueio.** A parte c entrega a **conclusão** dos contratos: `request_work_shift` (soma os minutos do turno ao `labor` aceito; ao completar, dentro do prazo, a custódia paga) e `request_deliver_contract` (confere os bens **e** o pagamento antes de mover qualquer coisa, move os bens ao destino e paga), mais o evento `ContractCompleted` (classe em `economy/api/`, regra E). A regra "um trabalho, um pagamento" (DEC-151) está no código: quem já é atribuído ao local é **recusado** com `ECON_WORKER_ALREADY_ASSIGNED`. **Nenhum teste existente alterado; nenhum arquivo protegido; nenhum hash muda** (ninguém posta contrato no jogo). O **R13-I1** (recusa que gasta ID) **continua** no `request_post_contract` desta ponta. É 1 commit, empilhado na 096b (`bfbc9a3`), que por sua vez está sobre a pilha da A (base `e16072b`).

**2. ARQUIVOS CRIADOS / 3. MODIFICADOS.** Nenhum no projeto; só `STATUS-B.md`.

**4. DECISÕES TÉCNICAS (do revisor).** Li o diff **inteiro** (12 arquivos: 7 `.gd`, 2 `.uid`, 3 documentos), o teste novo **inteiro** (180 linhas) e as funções que ele usa (`GoodsStore.check_transfer`, `Ledger.check_transfer`, `ProductionBook.site_at`, `ServicePostBook.post_at`, `OwnerBook.check_open`: **todas existem** e já eram do `main`/da pilha). Sem proposta de DEC.

**5. TESTES EXECUTADOS.** **NÃO EXECUTADO: o Godot e o `check_all` da A** (não exportei este ramo; o tempo desta rodada foi para a leitura e a previsão de junção). Rodei: contagem DEC-126, `git grep` das funções usadas, `git merge-tree --trivial-merge` (só imprime) contra o `main` e contra a 097e.

**6. RESULTADOS**
| Item | Resultado |
|---|---|
| **Tamanho (DEC-126)** | **346 linhas** (344 acrescentadas + 2 trocadas) em **7 `.gd`**: **acima do teto de 300, dentro da tolerância de 450** (a 096a foi 352 e a 096b 245: três partes da LW-096 já passam de 900) |
| **Cumpre `economy.md` seção 8?** | **Sim:** `labor` só por `request_work_shift` com `ECON_WORKER_ALREADY_ASSIGNED`; `delivery` por `request_deliver_contract`; `contract_payout` pela custódia; **um** `ContractCompleted` por conclusão |
| **Tudo ou nada** | **Sim** (conferi o código): `work_shift` só muda o estado depois de conferir minutos, local, prazo, aceite e (ao completar) o pagamento; `deliver` confere **bens e pagamento antes** de mover (`check_transfer` de `goods` e do `ledger`, depois `transfer` e `_complete`); o `GoodsStore` aceita destino igual à origem sem mudar nada |
| **Camadas, tempo, aleatoriedade, `float`, dinheiro** | Limpos: só economia; `now` vem do relógio do módulo (`_clock.total_minutes()`), não de `Time`; dinheiro só em `Ledger`; sem `float` |
| **Save** | `worked_minutes` entra no save **só do `labor`** e há teste de ida e volta (12 min sobrevivem e o resto completa); sem contrato, o bloco e o hash **não mudam** |
| **Testes novos (6)** | completa por turnos (meio caminho, passar dos minutos, 1 evento, custódia vazia, conservação, `validate()`); atribuído ao posto é recusado (e quem não é atribuído trabalha); sem contrato, minuto 0, dono desconhecido, outro local, outro trabalhador, depois do prazo, módulo sem `setup`; entrega (aberto ainda, sem bens, com bens, bens no destino, conservação, repetida, `labor` não se entrega, ID inexistente); save; entrega depois do prazo |
| **Eventos** | `ContractCompleted` em `docs/events.md` (publicador marcado); classe em `economy/api/`; um evento só por conclusão (o `progress` e as falhas **não** publicam) |

**7. PROBLEMAS ENCONTRADOS**
**Bloqueante: nenhum.**
**IMPORTANTE**
- **R14-I1. O R13-I1 continua aberto e agora há uma prova escrita contra o código:** `economy.md` seção 8 (parte b) diz que o ID **"só se consome ao postar"**, e `request_post_contract` (`economy_module.gd`, 1ª linha depois da checagem de `setup`) chama `_ids.next_id()` **antes** de validar. Toda recusa gasta um ID e muda o `state_hash`. Nenhum teste da 096c olha o contador. **Recomendo** o mesmo conserto (validar antes de pedir o ID) e um teste que compare o contador antes e depois de uma recusa.
**MENOR**
- **R14-M1. Sem o prazo (parte d), a 096c deixa dinheiro preso:** depois do prazo `work_shift` e `deliver` **recusam** e o contrato fica `accepted` com a custódia retida; o mesmo acontece se o aceitante ou o destino morrer. É a divisão declarada da A; **não leve a 096 ao `main` sem a parte do prazo** (ver R15, se o vigia trouxe a 096d).
- **R14-M2. `request_deliver_contract(contract_id)` não recebe o ator.** Qualquer chamador pode disparar a entrega **dos bens do aceitante** (o contrato do `economy.md` já é assim, então **cumpre**); lembro só que o AGENTS 6 pede o ator nos comandos de jogador: o `npc` (LW-104) vai chamar pelo aceitante.
- **R14-M3. `validate()` e `_parse_contract` não impõem `worked_minutes` ≤ `minutes`** nem "contrato `completed` com `worked_minutes` = `minutes`": um save editado à mão com `worked_minutes` maior passa e o próximo turno completa o contrato.
- **R14-M4. Um save feito pela 096b com `labor` é recusado pela 096c** (`worked_minutes` agora é obrigatório no `labor`). Sem efeito real (nenhum jogo posta contrato e o save antigo é rejeitado antes do "save congelado", DEC-083), mas fica o aviso.
- **R14-M5. Lacunas de teste:** não há caso de **entrega com o destino fechado ou cheio** (`ECON_OWNER_CLOSED`, `ECON_CAPACITY_EXCEEDED`, que a documentação promete), de **dois `labor` aceitos pelo mesmo trabalhador no mesmo local** (a regra "o menor ID" não é exercida), nem de trabalhador atribuído a um **local de produção** (só o caso do posto é testado; a função trata os dois).
- **R14-M6. `docs/events.md`:** `ContractCompleted` continua "planejado, LW-096" na coluna da situação (e `ContractOffered`, também, embora o publicador exista desde a 096b) e o cabeçalho de contagem não menciona os implementados: é só rótulo, mas a tabela fica atrás do código (o `tools/check_architecture` olha só a presença do nome).

**Junção (previsão por `merge-tree`, só texto):** a ponta `bc733af` × `main` novo (`4372f7f`): **2 trechos, os dois em documento** (`docs/backlog.md` e `docs/events.md`); `economy.md` e `npc.md` juntam **limpos**. A ponta × **097e da C**: **12 trechos em 10 arquivos, exatamente os mesmos da 096b** (inclui **dois testes**: `test_npc_split_oracle.gd` e `test_economy_production_api.gd`, e `game_app.gd` e `simulation_host.gd` com 2 trechos cada); a 096c **não piora** o cruzamento.

**8. RISCOS.** O mesmo da R11 a R13: a pilha da A cresce e a ordem de entrada A × C define quem resolve os 12 trechos. A 096c sozinha deixaria contratos aceitos sem saída (R14-M1).

**9. PENDÊNCIAS.** *Da A:* R14-I1 (e o R13-I1, que é o mesmo defeito) e os menores. *Que não consegui verificar:* o `check_all` **da A**; a junção real; e se os 6 testes novos **passam** no Godot (li os asserts, não rodei).

**ACOMPANHAMENTO.** *Avanço:* LW-096 em 3 partes nos ramos da A (a, b, c); faltam o prazo (a 096d acabou de aparecer no GitHub: será a R15), as vagas, e a LW-095 final. *Próxima:* R15 (`lw-096d-prazo-dos-contratos`, `45bb31b`). *Decisões de Arthur:* as mesmas da R11 a R13 (ordem A × C; 7 linhas de teste do R6-M2). *Git:* só leitura nos ramos remotos; este relatório é o único commit (`status-b`); `main` em `4372f7f`.


## RELATÓRIO — R15: ramo novo da conversa A (`lw-096d-prazo-dos-contratos`, `45bb31b`, LW-096 parte d)        Status: PRONTA PARA REVISÃO (revisão independente, SÓ LEITURA) · 11/11/2026 21:55 (Brasília)

**1. RESUMO.** **Nenhum bloqueio.** A parte d entrega o **prazo**: a cada hora cheia, depois dos postos e dos locais de produção, a economia vence o contrato `labor` ou `delivery` (aberto ou aceito) cujo prazo passou: a custódia **volta ao emissor** (`contract_refund`), o estado vira `expired` e sai um `ContractFailed` (classe em `economy/api/`, regra E), por ID crescente; o concluído não é tocado. Com ela a LW-096 **fecha o ciclo de vida** que a R14-M1 pedia (nenhum contrato fica preso para sempre, **salvo** o caso do emissor morto, abaixo). **Nenhum teste existente alterado; nenhum protegido; nenhum hash muda** (sem contrato, `expire` não faz nada). Empilhado na 096c (`bc733af`), 1 commit.

**2. ARQUIVOS CRIADOS / 3. MODIFICADOS.** Nenhum no projeto; só `STATUS-B.md`.

**4. DECISÕES TÉCNICAS (do revisor).** Li o diff **inteiro** (10 arquivos: 5 `.gd`, 2 `.uid`, 3 documentos), o teste novo **inteiro** (146 linhas, e refiz as contas dos saldos do teste 3: trabalhador 60+25−25+25 = 85, emissor 60−25−25+25 = 35, destino 60−25 = 35: **conferem**), `OwnerBook.close_owner` e `is_closed`, o único chamador de `run_production_hour` (`economy_module.gd:76`) e o construtor do `NpcDied` (o teste usa `("test", 0)` como os outros testes). Sem proposta de DEC.

**5. TESTES EXECUTADOS.** **NÃO EXECUTADO: o Godot e o `check_all` da A.** Rodei: contagem DEC-126, `git grep` dos chamadores, `merge-tree --trivial-merge` (só imprime). Todos terminaram sem erro.

**6. RESULTADOS**
| Item | Resultado |
|---|---|
| **Tamanho (DEC-126)** | **214 linhas** em **5 `.gd`** (+ 205, − 9): **dentro do teto** |
| **Cumpre a seção 8 do `economy.md`?** | **Em parte:** o prazo e a devolução ao emissor **sim**; a frase "a custódia **nunca** fica retida [Q14]" **não** vale para emissor morto (R15-I1) |
| **Limiar do prazo** | `expire` vence quando `agora >= prazo`, **o mesmo limiar** de `work_shift` e `deliver` (recusam com `agora >= prazo`): não há janela em que o contrato esteja "vencido para uns e vivo para outros", exceto até 59 min (a cadência é a hora; A documenta) |
| **Tudo ou nada / ordem** | A devolução confere o emissor aberto e o saldo antes de transferir; se falhasse (caminho praticamente inalcançável) a A registra `push_error` e **ainda** marca `expired`, e o `validate()` **acusa** (o emissor está vivo); a ordem é por ID crescente, estável |
| **Sem contrato, nada muda** | **Sim:** `expire` não mexe em estado sem contrato; a mudança de assinatura de `run_production_hour` tem **um** chamador (o módulo) e **nenhum teste** a chama (conferi com `git grep`) |
| **Camadas, tempo, aleatoriedade, `float`, dinheiro** | Limpos: o `now` vem do relógio do módulo; só `Ledger`; sem `float` |
| **Testes novos (5)** | vence aberto (antes não, na hora cheia sim, uma vez só, depois não se aceita); aceito também vence e o trabalho incompleto não paga; concluído nunca vence, ordem por ID, aberto com prazo maior fica; **emissor morto** não recebe e a recompensa fica na conta do contrato (conservação e `validate()` verdes); save do `expired` |
| **Eventos** | `ContractFailed` publicado **uma vez** por contrato vencido; `reason` = `expired` (constante nomeada); `docs/events.md` atualizado (publicador marcado) |

**7. PROBLEMAS ENCONTRADOS (por gravidade)**
**Bloqueante: nenhum.**
**IMPORTANTE**
- **R15-I1. Emissor morto: a recompensa fica presa e o contrato (`economy.md`, "Conclusão") diz o contrário.** O código **não devolve** a custódia a emissor fechado e o `validate()` passou a **aceitar** "contrato não retido, emissor fechado e custódia = recompensa" (`retained_by_dead_issuer`); a A marca **[LIM]** nos documentos e no commit. Mas a **mesma seção** ainda diz "a custódia nunca fica retida [Q14]" (a linha da Conclusão não foi tocada): o documento **se contradiz**. Duas ressalvas a favor da A: (a) é **coerente com o que a economia já faz** com o dinheiro de quem morre (`close_owner` só marca `closed`; o saldo fica na conta fechada e continua contado), então não é um buraco novo; (b) é **hash-neutro hoje** (ninguém posta contrato). Contra: é uma escolha de **design** (para onde vai o dinheiro de um contrato cujo emissor morreu) tomada sem perguntar (AGENTS 16.2). **Recomendo:** manter como [LIM] **e** corrigir a frase de Q14 ("nunca fica retida, **salvo emissor morto**, [LIM]") **e** pôr a pergunta para Arthur (opções: ficar na conta do contrato como hoje; ir para a conta do mercado do povoado do emissor; ser destruída pelo `Ledger`); **recomendação minha:** a conta do mercado, que mantém o dinheiro em circulação (a LW-098 vai precisar de moeda circulando).
**MENOR**
- **R15-M1. Contratos terminais nunca saem do livro.** `completed` e `expired` ficam para sempre no estado, no save e na varredura horária de `expire` (laço sobre **todos** os contratos, 24 vezes por dia de jogo). Hoje não há contrato; com o `npc` postando (LW-104) o livro só cresce. **Backlog:** poda de contratos terminais antigos (precisa de decisão sobre a crônica, que lê `ContractCompleted`/`ContractFailed`).
- **R15-M2. `accept` ainda não confere o prazo** (era o R12-M3): um contrato já vencido mas ainda não varrido (até 59 min) **pode ser aceito**, e o aceitante não consegue trabalhar nem entregar nele (ambos recusam por prazo). Efeito pequeno (ele só perde a vez); o conserto é uma linha em `accept` + um teste.
- **R15-M3. Lacunas de teste:** o vencimento de contrato **`delivery`** não é testado (o código trata igual ao `labor`; só o `labor` aparece nos 5 testes); falta um prazo **no meio da hora** (todos os testes usam prazo em hora cheia, então "até 59 minutos de atraso" não é exercido); e o `push_error` do caminho de falha da devolução não tem teste.
- **R15-M4. `events.md`:** o rótulo da coluna "Situação" de `ContractFailed` continua "planejado, LW-096" (como o de `ContractOffered` e `ContractCompleted`, R14-M6): a tabela fica atrás do código.
- **R15-M5. O R13-I1 / R14-I1 (recusa que gasta ID) continua aberto** nesta ponta (`request_post_contract` não mudou).

**Junção (previsão por `merge-tree`, só texto):** a ponta `45bb31b` × `main` novo (`4372f7f`): **2 trechos, os dois em documento** (`docs/backlog.md` e `docs/events.md`); × **097e da C**: **12 trechos em 10 arquivos, os mesmos da 096b e da 096c** (a 096d não mexe em nenhum arquivo novo da C; o `test_economy_production_api.gd`, `test_npc_split_oracle.gd`, `game_app.gd` e `simulation_host.gd` seguem como o ponto de atrito).

**8. RISCOS.** A pilha da A tem agora **9 ramos** (095a–d, 096a–d, 093k) e **nada no `main`**; quanto mais cresce, mais a Fase B da C (R10-I4) e a da A têm de reconciliar; o R15-I1 precisa de resposta de Arthur **antes** de a LW-104 fazer NPC postar contrato (o emissor pode morrer).

**9. PENDÊNCIAS.** *Da A:* R13-I1 (ID gasto), R15-I1 (frase de Q14 e a pergunta a Arthur), M1 a M5. *De Arthur:* a pergunta do R15-I1 (para onde vai a custódia de emissor morto). *Que não consegui verificar:* o `check_all` **da A**; que os 5 testes novos **passam**; a junção real.

**ACOMPANHAMENTO.** *Avanço:* a LW-096 está **completa no que o `economy.md` pede para `labor` e `delivery`** (a, b, c, d); faltam as **vagas** (parte e) e, na LW-095, `service_posts.json` e a retirada do `IncomeStub`. *Próxima:* o que o vigia trouxer (096e/vagas, 096a do NPC, 095e, ramos da C: 118a…) e toda entrada no `main`. *Decisões de Arthur:* ordem A × C (recomendo a C primeiro), as 7 linhas de teste do R6-M2 e a pergunta do R15-I1. *Git:* só leitura nos ramos remotos; único commit é o `status-b`; `main` em `4372f7f`.


## RELATÓRIO — R16: ramo novo da conversa A (`lw-096e-vagas`, `1ea1b22`, LW-096 parte e)        Status: PRONTA PARA REVISÃO (revisão independente, SÓ LEITURA) · 11/11/2026 22:10 (Brasília)

**1. RESUMO.** **Nenhum bloqueio.** A parte e entrega as **vagas** (DEC-165 e DEC-169): a cada hora cheia a economia confere cada local de produção e posto (por ID crescente) e, se falta gente e não há vaga aberta, **posta UMA `vacancy`** (emissor: o local; recompensa 0; sem prazo; sem custódia) e publica `ContractOffered`; `request_accept_contract` numa vaga **só aceita NPC aberto**, atribui ao local, tira o emprego anterior, conclui na hora e publica `ContractCompleted`; `peek_contract(s)` mostra os nomes de `peek_site` e `peek_post`. Com ela a LW-096 cobre `labor`, `delivery` e `vacancy`. **Nenhum teste existente alterado; nenhum protegido; nenhum hash muda NA PILHA DA A** (`data/economy/production_sites.json` é `[]` e `service_posts.json` ainda não existe). Mas há **1 risco de junção com a C** (R16-I1). Empilhado na 096d (`45bb31b`), 1 commit.

**2. ARQUIVOS CRIADOS / 3. MODIFICADOS.** Nenhum no projeto; só `STATUS-B.md`.

**4. DECISÕES TÉCNICAS (do revisor).** Li o diff **inteiro** (11 arquivos: 6 `.gd`, 2 `.uid`, 3 documentos), o `economy_vacancies.gd` (84 linhas) **inteiro**, os 8 testes novos **inteiros** (241 linhas) e `assign_worker`/`remove_worker` dos dois livros (`ProductionBook` e `ServicePostBook`: **existem** e só falham para local inexistente, que o `accept` confere antes). Para o R16-I1 li `data/population.json` e `data/economy/production_sites.json` **do ramo da C (097e)**. Sem proposta de DEC.

**5. TESTES EXECUTADOS.** **NÃO EXECUTADO: o Godot e o `check_all` da A.** Rodei: contagem DEC-126; `git grep` das funções usadas; um script de conferência (equipe de cada local de produção x `workers_wanted`, dados da C); `git merge-tree --trivial-merge` (só imprime). Todos terminaram sem erro.

**6. RESULTADOS**
| Item | Resultado |
|---|---|
| **Tamanho (DEC-126)** | **400 linhas** (+395 −5) em **6 `.gd`**: **acima do teto de 300, dentro da tolerância de 450**. A LW-096 fica com 5 partes (352, 245, 346, 214 e 400 linhas) e **3 delas acima de 300** |
| **Cumpre a seção 8 e a DEC-169?** | **Sim:** a vaga nasce quando falta gente; o NPC a aceita; o aceite **atribui, tira a atribuição anterior e conclui na hora**; o emprego só muda por morte ou por aceitar outra vaga; o local **sem dinheiro para a folha PARA e não demite** (teste) |
| **Tudo ou nada no `accept`** | **Sim** (li o código): estado, aceitante aberto e do tipo `npc`, local existente, "já trabalha ali" e "ainda falta gente" são conferidos **antes** de `_leave_current_workplace` e `_assign` |
| **Determinismo e IDs** | A vaga só consome ID **ao postar** (a hora é a cadência, a ordem é por ID crescente); `post_vacancy` não tem recusa que gaste ID (**ao contrário do R13-I1**) |
| **Camadas, tempo, aleatoriedade, `float`, dinheiro** | Limpos: só economia; sem `float`; a vaga **não tem custódia** (nenhuma conta nova) |
| **Save** | A vaga vai e volta (teste de ida e volta com o JSON); `_parse_contract` agora exige `workplace_id` positivo e **recusa vaga com recompensa ou prazo** (teste) |
| **Testes novos (8)** | vaga única por local com os nomes de `peek_site`/`peek_post` e sem conta; equipe completa não posta e **morte** abre vaga na hora seguinte; aceitar atribui, conclui e nasce outra se ainda falta; troca de emprego deixa vaga no local antigo; vaga que ninguém precisa falha e não se aceita; recusas (dono desconhecido, não é NPC, já trabalha ali, morto) **não mudam nada**; local sem dinheiro; save; conferência da hora falha a vaga já preenchida |
| **Eventos** | `ContractOffered` (publicador de vaga marcado em `docs/events.md`) e `ContractCompleted` com recompensa 0; **nenhum evento novo** |

**7. PROBLEMAS ENCONTRADOS (por gravidade)**
**Bloqueante: nenhum.**
**IMPORTANTE**
- **R16-I1. Risco de junção A x C: a vaga é uma NOVA causa de mudança de oráculo e soak, fora das quatro que Arthur autorizou à C.** Na pilha da A não há local de produção, então nada muda. Na junção (marco 3) entram os **14 locais de produção da C** (102 vagas de trabalho: A 46, B 36, C 20) e, **a partir daí, qualquer morte de NPC ou troca de emprego posta uma vaga**: `ContractOffered` publicado, **um ID consumido** (os IDs seguintes se deslocam, como o R10-I4 já avisava para o primeiro NPC) e o bloco `contracts` passa a existir no `state_hash`. **O que conferi:** no `data/population.json` da C, **todos os 14 locais de produção têm exatamente `workers_wanted` NPCs** (nenhum local nasce com falta), então **não nasce vaga na hora 1**. **O que NÃO consegui verificar:** se algum NPC **morre** (fome, por exemplo) dentro da janela do oráculo e do soak do `main` novo. Se morrer, o valor da junção difere do valor "só da C" e da "só da A" por uma causa que a condição (d) do bloco da C **não** lista, e a Fase B dela deve **PARAR** em vez de aprovar por antecipação. Como o `main` novo seria "A + C", **a C precisa conferir se há morte/troca de emprego no oráculo e no soak antes de aprovar** (ela já relata os três conjuntos: A, C e junção). Os 6 postos de serviço ainda não têm `service_posts.json` (cai na LW-095, da A): quando entrar, o mesmo teste vale para eles (a população tem 8, 6, 5, 3, 5 e 3 NPCs nos locais de posto).
**MENOR**
- **R16-M1. Decisão de design sem GDD, assumida pela A como proposta:** "no máximo UMA vaga aberta por local; conferência por hora" (a A a rotulou **[PROPOSTA de implementação]** no commit e no `economy.md`). Efeito: um local que perdeu 3 NPCs só reabre **1 vaga por hora**, e a vaga nasce **até 59 minutos depois da morte** (testado). Peço a **Arthur** que a ratifique ou ajuste (AGENTS 16.2: regra de jogo não descrita no GDD).
- **R16-M2. Uma recusa que muda estado.** `EconomyVacancies.accept`, ao ver a vaga já preenchida ou o local inexistente, **recusa e faz a vaga `failed`** (`cancel_vacancy`). O teste cobre e o efeito é saudável, mas a mensagem do commit diz "as recusas não mudam nada": vale só para as outras recusas.
- **R16-M3. Terminais acumulam e a varredura cresce.** Cada preenchimento e cada vaga que falha deixam um contrato **para sempre** (R15-M1, agora criado **pela própria economia**, sem comando) e `open_vacancy_of` varre **todos** os contratos para **cada** local de trabalho, a cada hora (20 locais x N contratos x 24 por dia). Hoje N é pequeno; **medir antes de otimizar** (AGENTS 4.18) e registrar a poda no backlog.
- **R16-M4. A economia muda o emprego e o `npc` ainda não sabe.** O `accept` reatribui na economia, mas o `work_place_id` do estado do NPC só muda quando a LW-096a (do `npc`) ouvir `ContractCompleted`. Hoje **ninguém aceita vaga** (não há chamador), então não há inconsistência; fica registrado para a revisão da 096a.
- **R16-M5. `_assign` ignora o `Result` de `assign_worker`.** O código pré-confere o local, então a falha é inalcançável; só lembro que o AGENTS 13.2 manda tratar o retorno.
- **R16-M6. Lacuna de teste:** `peek_contracts(..., place_id)` agora **casa a vaga** (o `place_id` dela é preenchido), o que corrige o R13-M1 **na prática**, mas nenhum teste filtra por local com a vaga; e não há teste de **vaga de local de produção com o salário vindo da receita** além do `bake_bread` montado à mão (só ele e o posto).
- **R16-M7. O R13-I1/R14-I1 (recusa de `request_post_contract` gasta ID) e o R15-I1 continuam abertos** nesta ponta.

**Junção (previsão por `merge-tree`, só texto):** a ponta `1ea1b22` × `main` novo (`4372f7f`): **2 trechos, os dois em documento** (`docs/backlog.md` e `docs/events.md`); × **097e da C**: **12 trechos em 10 arquivos, os mesmos da 096b a 096d**; × **118a da C**: **13 trechos em 11 arquivos** (os mesmos, mais `src/sim/world/README.md`).

**8. RISCOS.** O R16-I1 (acima) é o principal: junta duas frentes que cada uma isolada está sã. A pilha da A tem **10 ramos** (095a–d, 093k, 096a–e) e nada no `main`.

**9. PENDÊNCIAS.** *Da A:* R16-M1 a M7. *Da C (na Fase B, se a A entrar antes):* o teste de morte e troca de emprego no oráculo e no soak (R16-I1). *De Arthur:* ratificar a vaga única por local e por hora (R16-M1). *Que não consegui verificar:* o `check_all` **da A**; que os 8 testes novos passam; a junção real; e se há morte de NPC no oráculo e no soak.

**ACOMPANHAMENTO.** *Avanço:* a LW-096 está **completa no que o `economy.md` pede** (a a e); faltam, na A, a **LW-096a (o NPC aceita a vaga)**, a **LW-095** final (`service_posts.json`, retirada do `IncomeStub`) e a **Fase B**. *Próxima:* o que o vigia trouxer e toda entrada no `main`. *Decisões de Arthur:* ordem A x C (recomendo a C primeiro; o R16-I1 é **mais um motivo**: se a C entra antes, a vaga só aparece na Fase B da A, onde a A mede a diferença sozinha), as 7 linhas de teste do R6-M2, a pergunta do R15-I1 e a vaga única (R16-M1). *Git:* só leitura nos ramos remotos; único commit é o `status-b`; `main` em `4372f7f`.


## RELATÓRIO — R17: ramo novo da conversa C (`lw-118a-culturas`, `6eb1ba0`, LW-118 parte a)        Status: PRONTA PARA REVISÃO (revisão independente, SÓ LEITURA) · 11/11/2026 22:11 (Brasília)

**1. RESUMO.** **Nenhum bloqueio.** A parte a da LW-118 entrega **só conteúdo**: `Culture` (4 parâmetros inteiros de 0 a 100 **[HIP]**), `CultureLoader` (lê e valida `data/world/cultures.json` pelo módulo `data`, apontando arquivo, item e campo) e o arquivo com as **duas culturas genéricas e contrastantes** da DEC-203 (aprovada por Arthur). O `world` **não usa** os parâmetros; as classes ficam soltas até a LW-118c/d. **Nada de save, de hash, de módulo registrado, de evento nem de autoload.** Nenhum teste existente alterado; nenhum arquivo protegido; nenhuma tag; nenhum `main`. Empilhado na 097e (`4e614b5`), 1 commit; **o ramo não vai ao `main`** (como mandou Arthur).

**2. ARQUIVOS CRIADOS / 3. MODIFICADOS.** Nenhum no projeto; só `STATUS-B.md`.

**4. DECISÕES TÉCNICAS (do revisor).** Li o diff **inteiro** (11 arquivos: 3 `.gd`, 3 `.uid`, 2 de dados, 3 documentos), `culture.gd`, `culture_loader.gd` e o teste novo **inteiros** (128 linhas), e conferi que as funções do módulo `data` que o carregador usa (`DataSchema.add_field`, `Field.set_range`, `DataBundle.add_issue`, `is_valid`, `describe_issues`) **existem** no ramo, que `docs/fase-4/dados.md` (citado no comentário do carregador) **existe** no ramo e que `DirAccess.create_temp` tem **4 precedentes** nos testes. Sem proposta de DEC.

**5. TESTES EXECUTADOS.** **NÃO EXECUTADO: o Godot e o `check_all` da C** (o ramo é só dado e dois arquivos de classe; não exportei). Rodei: contagem DEC-126, `git grep` das funções usadas, `merge-tree --trivial-merge` (só imprime).

**6. RESULTADOS**
| Item | Resultado |
|---|---|
| **Tamanho (DEC-126)** | **214 linhas** em **3 `.gd`** (+ 214, − 0): **dentro do teto** |
| **Cumpre a DEC-203 e o `world.md` (Extensão da Fase 4)?** | **Sim:** duas culturas, quatro parâmetros (`trade_openness`, `foreigner_tolerance`, `martial_stance`, `authority_weight`), **contrastantes** (mercantil 80/60/30/40 contra tradicional 30/25/65/75), valores marcados **[HIP]** no código, no README e na ficha; arquivo em `data/world/` (a ficha já fixou isso, R3-M4) |
| **Nomes genéricos (DEC-100)** | `culture_trade` e `culture_tradition`, "Cultura mercantil" e "Cultura tradicional": **genéricos**; os nomes dos campos seguem **PROPOSTA** (dito no comentário) |
| **Hash e save** | **Não mudam:** `Culture` e o carregador não são lidos por nenhum código do jogo (só pelo teste); o `world` não os registra |
| **Validação** | Cobre campo ausente, desconhecido, tipo errado (decimal e texto), fora da faixa (101 e −1; **bordas 0 e 100 válidas**), `id` repetido, nome vazio, lista vazia, JSON malformado e arquivo ausente, **todos com arquivo, item e campo na mensagem**; e uma terceira cultura entra **só por dado** |
| **Camadas, tempo, aleatoriedade, `float`, dinheiro, autoload** | Limpos (nenhum `Node`, nenhum relógio, nenhum sorteio, nada de `float`; 4 parâmetros como `int`) |
| **Testes novos (10)** | arquivo real (duas culturas, ordem, valores); contraste e faixa; nomes existem no texto e diferem; carregar duas vezes dá o mesmo; ausente/desconhecido; tipo; faixa e bordas; repetido/vazio/lista vazia; JSON ruim e arquivo ausente; terceira cultura por dado |

**7. PROBLEMAS ENCONTRADOS (por gravidade)**
**Bloqueante e importante: nenhum.**
**MENOR**
- **R17-M1. `cultures.json` ainda não é lido pelo jogo.** Até a LW-118d o arquivo **não passa pela validação do início do jogo** (AGENTS 13.1.7: dado inválido deve parar o jogo): quem o estraga só é pego pelo teste do arquivo real no `check_all`. É a divisão declarada (as consultas na 118c e a ligação na 118d).
- **R17-M2. Chave em arquivo que o bloco não nomeou.** A parte acrescenta **2 chaves em `data/text/pt_br.json`** (os nomes das culturas); o bloco da C (item 5) nomeia `provinces.json` e `cultures.json`, **não** o `pt_br.json`. É conteúdo do próprio escopo (o `name_key` precisa de texto, como o dos povoados) e nenhum teste existente mudou, mas fica registrado: o `tests/soak/sp6/sp6_hud.gd` mostra que **mexer no `pt_br.json` já exigiu autorização expressa de Arthur** em outra tarefa; confirme que ele considera isto coberto.
- **R17-M3. Classes soltas.** `Culture` e `CultureLoader` não têm chamador no jogo até a 118c/d (AGENTS 5.5 pede não criar "para depois"); aqui é **a divisão da LW-118 em partes pequenas** que a própria tarefa pede, e o README e a ficha declaram. Sem ação.
- **R17-M4. Nome para exibição não rotulado como proposta.** O comentário do código diz que os nomes **dos campos** seguem PROPOSTA; os dois **nomes de cultura** ("Cultura mercantil" e "Cultura tradicional") não levam rótulo no `pt_br.json` (JSON não aceita comentário); o rótulo está só na ficha ("genéricas"). Basta Arthur saber que são provisórios.

**Junção (previsão por `merge-tree`, só texto):** a ponta `6eb1ba0` × `main` novo (`4372f7f`): **11 trechos em 8 arquivos** (os 9 da 097e e mais **2** pela 118a: um segundo trecho em `docs/modules/world.md` e um em `src/sim/world/README.md`; **todos em documento, no `app` ou no teste do oráculo, nenhum em dado novo**). Nenhum conflito em `cultures.json` nem em `pt_br.json`.

**8. RISCOS.** O ramo cresce em cima da 097e e a Fase B da C (que ainda espera a A no `main`, R10-I4 e R16-I1) vai levar tudo junto; o risco da 118a em si é **baixo** (dado e classes soltas).

**9. PENDÊNCIAS.** *Da C:* nada obrigatório; R17-M1 a M4 para ciência. *De Arthur:* confirmar o `pt_br.json` (R17-M2). *Que não consegui verificar:* o `check_all` **da C**; que os 10 testes novos passam; se a validação de dados do `check_all` aceita um arquivo novo em `data/world/` sem esquema registrado (não achei nenhuma lista de arquivos em `tools/`).

**ACOMPANHAMENTO.** *Avanço:* LW-118 **parte a feita** em ramo (culturas); faltam as partes b a d (províncias, adjacência, ligação povoado → província, consultas) e a validação no início do jogo. *Próxima:* o que o vigia trouxer (118b…, 095e e a 096a da A, entrada no `main`). *Decisões de Arthur:* as mesmas das rodadas anteriores e o `pt_br.json` (R17-M2). *Git:* só leitura nos ramos remotos; único commit é o `status-b`; `main` em `4372f7f`.


## RELATÓRIO — R18: ramo novo da conversa A (`lw-096f-npc-aceita-vaga`, `d544daa`, LW-096a: o NPC aceita vaga)        Status: PRONTA PARA REVISÃO (revisão independente, SÓ LEITURA) · 11/11/2026 22:13 (Brasília)

**1. RESUMO.** **Nenhum bloqueio.** O `npc` passa a ouvir `ContractOffered`; para cada **vaga**, `NpcEmployment` (`npc/employment/`) pontua a vaga para os NPCs vivos **do mesmo povoado**, em ordem de ID, e o **melhor** a aceita por `request_accept_contract` (empate: o menor ID; **nunca sorteia**); aceitar muda o `work_place_id` do NPC **na mesma passagem** (o `npc` é dono do `work_place_id`; a economia, da lista de trabalhadores). Utilidade = `wage_per_hour` × 8 − caminhada de casa ao trabalho (custo de distância × distância × 2) + 10 se o ofício coincide; o desempregado aceita se a utilidade for positiva; o empregado só **troca** se a vaga passar do emprego atual por mais que **20** (histerese). As 4 constantes são **[HIP]** e ficam **nomeadas no código** (sem dado novo). **Nenhum teste existente alterado; nenhum protegido; nenhum estado novo (nada no save nem no hash na pilha da A).** Mas há **1 achado importante de junção com a C** (R18-I1). Empilhado na 096e (`1ea1b22`), 1 commit. Na ordem dos ramos da A esta parte aparece como **096f** no GitHub (a "LW-096a" do `npc`).

**2. ARQUIVOS CRIADOS / 3. MODIFICADOS.** Nenhum no projeto; só `STATUS-B.md`.

**4. DECISÕES TÉCNICAS (do revisor).** Li o diff **inteiro** (7 arquivos: 3 `.gd`, 2 `.uid`, 2 documentos), `npc_employment.gd` (117 linhas) **inteiro**, os **11 testes** pelos nomes e os 5 primeiros e o do determinismo **por inteiro** (refiz as contas dos testes de histerese: 4×8+0 = 32 contra 2×8+10 = 26, margem 6 < 20, **não troca**; 6×8 = 48 contra 26, margem 22 > 20, **troca**: conferem), o `npc_params.json` real (`distance_cost_per_100m` = **2**; os testes usam 1) e `data/population.json` e `production_sites.json` **do ramo da C (097e)**. Sem proposta de DEC.

**5. TESTES EXECUTADOS.** **NÃO EXECUTADO: o Godot e o `check_all` da A.** Rodei: contagem DEC-126; `git grep` de precedentes e campos usados (`peek_site_at`, `peek_post_at`, `distance_cost_per_100m`, `NpcState.settlement_id` e `work_place_id` **existem**); um script de contagem dos NPCs de postos nos dados da C; `merge-tree --trivial-merge` (só imprime).

**6. RESULTADOS**
| Item | Resultado |
|---|---|
| **Tamanho (DEC-126)** | **450 linhas** em **3 `.gd`** (117 + 13 + 320 de teste): **no limite exato da tolerância de 450** (teto 300). Qualquer linha a mais exigiria dividir |
| **Cumpre `npc.md` 14.4 (Q22, DEC-165, DEC-169)?** | **Sim:** utilidade com histerese; o emprego só termina por morte ou por aceitar outra vaga; um dono por dado (`work_place_id` do `npc`); o local sem dinheiro **não demite** (teste) |
| **Camadas (DEC-171)** | **Limpo:** o `npc` importa só `economy/api` (`EconomyModule`, `EconomyReplies`, `ContractOffered`); lê `ContractOffered` **por classe tipada** (`as ContractOffered`), não por nome de campo; sem economia, não ouve o evento |
| **Determinismo** | Ordem por ID crescente, empate pelo menor ID, nada de sorteio nem de relógio; há teste "mesmo mundo, mesmo resultado" (duas execuções, `JSON.stringify` igual) |
| **Estado e save** | **Nenhum estado novo** (a histerese é só a comparação de utilidades; o `NpcEmployment` não é salvo): sem `serialize`/`validate`/`debug_summary` a acrescentar |
| **Testes novos (11)** | desempregado ocupa a vaga de uma morte e o `work_place_id` acompanha; histerese (6 a mais **não** troca, 22 a mais **troca**); sem laço em 48 h; melhor por distância, ofício e **empate pelo menor ID**; outro povoado, morto e quem já trabalha ali ficam de fora; local sem dinheiro não demite; `work_place_id` x lista da economia **coincidem** e determinismo; módulo sem economia ignora; vaga de posto na hora 1; emprego melhor mas ainda negativo não move quem mora longe; morto na tabela nunca vence |

**7. PROBLEMAS ENCONTRADOS (por gravidade)**
**Bloqueante: nenhum.**
**IMPORTANTE**
- **R18-I1. "Desempregado" é decidido pela lista da economia, não pelo `work_place_id`: com os dados da C, 30 NPCs de posto contariam como desempregados.** `_current_employment` só considera o NPC empregado se `peek_site_at` ou `peek_post_at` do `work_place_id` dele o **lista**. Quem tem `work_place_id` num local que **a economia não conhece** (nem local de produção, nem posto) vira "desempregado, utilidade 0". Nos dados da C (`data/population.json`, 097e) **30 NPCs** moram nessa situação **até existir `service_posts.json`** (ele não existe em nenhum ramo ou no `main`; é da LW-095, da A, DEC-235): `a_work_06` 8 guardas, `a_work_07` 6 estalajadeiros, `b_work_07` 5 guardas, `b_work_08` 3 estalajadeiros, `c_work_04` 5 guardas, `c_work_05` 3 estalajadeiros. **Efeito na junção (marco 3):** na **primeira morte** em um local de produção, a vaga que nasce é **aceita por um desses guardas ou estalajadeiros** (utilidade positiva, "emprego atual" 0), que **abandona o posto dele** (`work_place_id` muda). O teste da pilha da A só cobre o desempregado com `work_place_id` **vazio**. **Recomendo à A:** tratar como desempregado só quem tem `work_place_id` **vazio** (dado do próprio `npc`), ou ignorar quem tem `work_place_id` num local sem local de produção nem posto conhecido; e um teste para esse caso. **Para a C (Fase B):** o mesmo cuidado do R16-I1 (conferir se há morte no oráculo e no soak) vale em dobro, porque agora a morte **muda o `work_place_id` de NPCs vivos** e pode encadear trocas.
**MENOR**
- **R18-M1. Cascata de trocas.** Cada troca abre uma vaga no local antigo, que outro NPC pode ocupar na hora seguinte; termina (cada troca sobe a utilidade de quem troca em mais de 20), mas **quantas horas dura** depende dos dados (com `distance_cost_per_100m` = 2 e 2 caminhadas, 100 m custam 4 por dia, então só locais **muito** distantes ou salários bem diferentes passam da histerese). O teste cobre 1 troca e 48 h estáveis, **não** uma cadeia de 3 locais.
- **R18-M2. A conta de distância difere do precedente.** `_commute_cost` subtrai as posições **em ponto flutuante** e só depois multiplica por 100 e arredonda (`roundi((home.x − work.x) × CM_PER_METER)`); `action_runner.gd` e `npc_thinker.gd` arredondam **cada posição** para centímetros e subtraem **inteiros**. Com coordenadas de 2 casas o resultado é igual na prática, mas o precedente é mais robusto e **o mesmo cálculo** (`ceili(sqrt(float(...)))`) já existe lá; sugiro reaproveitar a função.
- **R18-M3. O ofício do NPC não muda.** Quem passa de `artisan` para um posto de `guard` continua com `occupation_id` = `artisan` (e ganha o bônus de ofício só em vagas de `artisan`). É coerente com "o emprego só termina por morte ou por outra vaga", mas **não está dito** na ficha: pergunta de design para Arthur (o ofício acompanha o emprego?).
- **R18-M4. NPC no meio de uma ação.** O `work_place_id` muda enquanto o NPC pode estar **andando para o local antigo** ou **em `work` lá**; o código não cancela a ação nem refaz a rotina. Nenhum teste olha o corpo (S0/S1); só o estado. **Verificar na Fase B** (comportamento no jogo real).
- **R18-M5. `consider` varre todos os NPCs a cada oferta.** 132 NPCs x cada vaga: barato hoje; com cascata de trocas multiplica. **Medir antes de otimizar** (AGENTS 4.18).
- **R18-M6. Lacunas de teste:** não há caso de `ContractOffered` de **`labor` ou `delivery`** (o `npc` os ignora; só se testa a ausência de economia), nem de NPC **sem `home_place_id`** (a caminhada custa 0 e o NPC ganha vantagem sobre os outros), nem do caso do R18-I1.
- **R18-M7. O R13-I1/R14-I1 e o R15-I1 continuam abertos**, assim como o R16-I1 (a vaga é causa nova de mudança de oráculo/soak) agora **ampliado** pelo R18-I1.

**Junção (previsão por `merge-tree`, só texto):** a ponta `d544daa` × `main` novo (`4372f7f`): **2 trechos, os dois em documento** (`docs/backlog.md` e `docs/events.md`); × **097e da C**: **12 trechos em 10 arquivos, os mesmos da 096b a 096e** (inclui `docs/modules/npc.md`, que esta parte também edita); × **118a da C**: **13 trechos em 11 arquivos**.

**8. RISCOS.** O R18-I1 é o principal e só aparece na junção; a A sozinha está sã. A pilha da A tem agora **11 ramos** (095a–d, 093k, 096a–f) e nada no `main`; a A ainda tem de fazer o **`service_posts.json`** e **retirar o `IncomeStub`** (LW-095 final) e a **Fase B**.

**9. PENDÊNCIAS.** *Da A:* R18-I1 e M1 a M7. *Da C (Fase B):* conferir mortes e trocas de emprego no oráculo e no soak (R16-I1 + R18-I1). *De Arthur:* o ofício acompanha o emprego? (R18-M3). *Que não consegui verificar:* o `check_all` **da A**; que os 11 testes novos passam; o comportamento do corpo do NPC ao trocar (R18-M4); a junção real.

**ACOMPANHAMENTO.** *Avanço:* a LW-096 e a LW-096a estão **feitas em ramo**; faltam, na A, a LW-095 final (`service_posts.json`, `IncomeStub`) e a Fase B; na C, a Fase B da 097 (esperando a A) e a LW-118b a d. *Próxima:* o que o vigia trouxer e toda entrada no `main`. *Decisões de Arthur:* ordem A x C (recomendo a C primeiro; mas se a C entrar antes **sem** o `service_posts.json`, o R18-I1 aparece na Fase B da A), as 7 linhas de teste do R6-M2, a pergunta do R15-I1, a vaga única (R16-M1) e o ofício (R18-M3). *Git:* só leitura nos ramos remotos; único commit é o `status-b`; `main` em `4372f7f`.


## AUDITORIA DE ENTRADA NO `main` — conversa A, `885615c` (resto do marco 2: 093k, LW-095 a–d, LW-096 a–e e LW-096a)        Veredito: **SÃ** · 11/11/2026 22:19 (Brasília; a entrada apareceu entre 22:07 e 22:13; auditoria iniciada às 22:14)

| Pergunta de Arthur | Resultado (conferido) |
|---|---|
| **Avanço simples?** | **Sim:** `4372f7f` é ancestral de `885615c`. Sem `--force`, sem apagar ramo; as 3 tags remotas **iguais** (`fase-0/1/2-concluida`) |
| **O que entrou** | 14 commits (`df01eb1` … `885615c`), incluindo **1 merge** (`ff2d44f`, a junção com o `main` `4372f7f`) e 1 commit de status; **68 arquivos, +3.444 −37**: `src` 40 arquivos (+1.429 −29), `tests` 23 (+1.997 −2), `docs` 5 (+18 −6, fora o que veio do `main`), **`data/` 0, `tools/` 0, `project.godot` 0, `src/app` 0** |
| **Código novo** | 11 `.gd` novos em `src` (`ContractBook`, `ServicePostBook`, `PostDef`, `WagePayer`, `EconomyVacancies`, `NpcEmployment`, `WageIncome` e os 4 eventos `WagesPaid`, `ContractOffered`, `ContractCompleted`, `ContractFailed`) e 11 arquivos de teste novos |
| **Teste antigo alterado** | **1 arquivo, 2 linhas:** `tests/unit/test_economy_production_api.gd:181-182` (commit `df01eb1`, LW-095a): a lista esperada da mensagem ganha `NO_FUNDS` e o exemplo de motivo inválido troca `NO_FUNDS` por `NO_SPACE`. **É o que a R8 já registrou** (não enfraquece; mantém o caso "motivo fora do conjunto") e uma das 3 autorizações da A que Arthur ratificou no bloco v6. **Nenhum outro teste existente mudou** (−2 linhas em `tests`: só estas) |
| **Arquivos protegidos** | **Nenhum tocado** (`AGENTS.md`, `GDD`, `TECHNICAL_ARCHITECTURE`, `DECISIONS`, `DEVELOPMENT_ROADMAP`, `project.godot`, `.gitignore`, `addons/`, `tests/fixtures/`). `docs/ROADMAP_STATUS.md`: **só 1 parágrafo acrescentado**, sem contagem nem porcentagem mudada |
| **Evento já catalogado alterado?** | **`ProductionStopped`:** só o **comentário** (ganha `NO_FUNDS`; a classe e a carga **não** mudam). Os outros 4 eventos são **novos** e estão em `docs/events.md` |
| **Junção sã (docs)?** | **Sim.** O `main` novo = ponta `d544daa` (a que revi na R18) **+ 23 arquivos de documento** do `main` anterior (DECISIONS, ROADMAP, fichas da Fase 4, `docs/fase-4/dados.md`…): `git diff d544daa 885615c` **só tem documento**, então **nenhum código foi acrescentado pela junção**. Conferi os dois conflitos resolvidos à mão: `docs/events.md` tem **60 eventos antes e 60 depois, nenhum perdido**, e os 4 de contrato mantêm o texto da A **e** o "Fase 4" do `main`; `docs/backlog.md` tem **239 itens do `main` anterior, todos presentes**, mais os da A |
| **Rotas E economia no jogo real; uma assinatura; `c_market_01`** | **Não se aplicam a esta entrada** (a LW-097 da C não está no `main`). O que vale: `src/app` **não mudou**, `start_new_game(…, economy_setup)` e `register(…, economy_setup)` seguem com **uma assinatura só** e `game_app.gd` continua passando `_load_economy_setup()` |
| **Oráculo e soak mudaram?** | **Não:** nenhum arquivo do oráculo, de soak ou de hash foi tocado (nenhum `tests/integration` nem `tests/soak` no diff) **e o `check_all` independente fechou VERDE** (abaixo), com o oráculo e o soak curto dentro dele |
| **`check_all` independente (meu)** | **VERDE** numa cópia exportada de `885615c` (`git archive`, **nenhuma escrita no repositório**): **162 scripts, 1.391 testes, 1.391 passando, 294.336 asserts**, 183,5 s; arquitetura e dados OK. **Iguais** aos números que a A relatou (162 / 1.391). As linhas `ERROR`/`WARNING` que o GUT imprime nos testes de caminho de erro são **as mesmas do `main` anterior** (68 e 37 nas duas execuções; 0 `SCRIPT ERROR`) |
| **Hash e save** | `save_version` **não aparece** no diff; sem `production_sites.json` nem `service_posts.json` o jogo real não cria local de trabalho, contrato nem vaga: **nenhum hash muda** (confirmado pelo `check_all` verde) |

**O que o `main` novo já carrega (achados que eu tinha levantado nos ramos e que a A decide):** R13-I1/R14-I1 (recusa de `request_post_contract` gasta ID; o `economy.md` diz o contrário), R15-I1 (custódia de emissor morto fica presa; pergunta a Arthur), **R16-I1 + R18-I1** (a vaga muda oráculo e soak na junção com a C **se houver morte de NPC**; e, com os dados da C, 30 NPCs de posto contam como desempregados até existir `service_posts.json`) e as lacunas menores. **Nenhum é bloqueante para esta entrada** porque o jogo real não tem local de trabalho nos dados da A.

**Efeito sobre a C (bloqueada desde 21:52, `status-c`):** a causa que ela relatou (2 testes da A que falham na junção por IDs e dinheiro: `test_game_economy_wiring` e `test_economy_start_money_and_consume`) é **a que eu previ na R10-I4**. Com a A agora no `main`, **a prova do oráculo da C ("só A") precisa ser refeita sobre `885615c`** (ela a fez sobre `4372f7f`, que não tinha as vagas nem o `npc` aceitando emprego) e a junção passa a incluir o código de vaga e de emprego: **conferir mortes de NPC no oráculo e no soak** antes de aprovar valores (R16-I1 e R18-I1). Ela continua aguardando a **sua** autorização para trocar os números dos 2 testes.

**O que NÃO consegui verificar:** (1) a **autorização** da A para entrar no `main` (vejo o texto "por autorização antecipada de Arthur" no commit e no status dela, não o bloco original); (2) o comportamento no **jogo real em tela** (só testes); (3) soak **longo** (o `check_all` roda o curto); (4) se há **morte de NPC** no oráculo e no soak (R16-I1); (5) a conferência de `tools/check_architecture` ao pé da letra além do que o `check_all` já reporta verde.


## RELATÓRIO — R19: ramo novo da conversa C (`lw-118b-provincias`, `5f352a7`, LW-118 parte b)        Status: PRONTA PARA REVISÃO (revisão independente, SÓ LEITURA) · 11/11/2026 22:20 (Brasília)

**1. RESUMO.** **Nenhum bloqueio, mas 1 achado importante de tamanho (R19-I1).** A parte b entrega as **4 províncias da DEC-207** (`province_a`, `province_b`, `province_c` e `province_border`) e a **adjacência de partida** em `data/world/`, com `Province`, `ProvinceLink`, `ProvinceLoader` (valida o grafo: ligação com ela mesma, par repetido **inclusive invertido**, pontas fora de ordem, `id` que não bate com as colunas, referência quebrada, grafo **não conexo**) e `ProvinceService` (consultas `peek_province`, `peek_provinces` e `peek_adjacent_provinces`, **cópias**, em ordem crescente de `id`, falha tratada `PROVINCE_UNKNOWN`). **Só conteúdo e classes soltas:** nada de save, hash, módulo registrado, evento ou autoload; **nenhum teste existente alterado; nenhum protegido; nenhuma tag; nada no `main`.** Empilhado na 118a (`6eb1ba0`), 1 commit.

**2. ARQUIVOS CRIADOS / 3. MODIFICADOS.** Nenhum no projeto; só `STATUS-B.md`.

**4. DECISÕES TÉCNICAS (do revisor).** Li o diff **inteiro** (18 arquivos: 6 `.gd`, 4 `.uid`, 3 de dados, 3 documentos, `pt_br.json`), `province.gd`, `province_link.gd`, `province_service.gd` e `province_loader.gd` **inteiros**, e os **19 testes pelos nomes**; conferi os dados contra `docs/fase-4/dados.md` seção 1 ("Linhas de partida": as 4 províncias e as 4 ligações `a__b`, `a__border`, `b__border` e `border__c`) e que `DataSchema.set_ref` **existe**. Sem proposta de DEC.

**5. TESTES EXECUTADOS.** **NÃO EXECUTADO: o Godot e o `check_all` da C** (não exportei este ramo). Rodei: contagem DEC-126, `git grep` da API do módulo `data`, `merge-tree --trivial-merge` (só imprime).

**6. RESULTADOS**
| Item | Resultado |
|---|---|
| **Tamanho (DEC-126)** | **526 linhas** em **6 `.gd`** (281 de código: 20 + 23 + 131 + 107; 245 de teste: 121 + 124): **ACIMA do teto de 300 e ACIMA da tolerância de 450** (**+76**, 17%). **Só esta parte passou da tolerância em toda a noite** (a 096e da A ficou em 400 e a 096a do `npc` em 450 exatos) |
| **Cumpre a ficha (`world.md`, DEC-207, `fase-4/dados.md`)?** | **Sim:** 4 províncias com `kind` (`settled` x3, `frontier` x1), adjacência **sem direção**, o grafo de partida é o da ficha (a fronteira é o amortecedor: A e B chegam a C **só pela fronteira**, e há teste) |
| **Hash e save** | **Não mudam:** nada é lido por código do jogo (só pelos testes); `ProvinceService` não guarda estado salvo; tem `validate()` e `debug_summary()` mesmo assim |
| **Validação** | Todos os casos citados acima com **arquivo, item e campo**; uma 5ª província entra **só por dado** (teste) |
| **Consultas** | Cópias (alterar uma resposta não muda nada), ordem crescente de `id`, **independentes da ordem do conteúdo** (teste), `PROVINCE_UNKNOWN` com os ids conhecidos na mensagem |
| **Camadas, tempo, aleatoriedade, `float`, dinheiro, autoload** | Limpos (nada de `Node`, relógio, sorteio ou `float`; `Dictionary[String, Array]` tipado) |
| **Testes novos (19)** | `test_provinces` (8): arquivo real, adjacência de partida, sem direção e conexo, cópias, desconhecida, ordem independente, serviço acusa repetida e ligação quebrada, nomes existem e diferem; `test_provinces_data` (11): campo ausente/desconhecido, tipo/`id` repetido/nome vazio/`kind` fora do vocabulário, lista vazia, referência quebrada, ligação com ela mesma, par repetido (inclusive invertido), ordem das pontas e `id` que não bate, não conexo, província única, JSON ruim e arquivo ausente, 4ª província por dado |

**7. PROBLEMAS ENCONTRADOS (por gravidade)**
**Bloqueante: nenhum.**
**IMPORTANTE**
- **R19-I1. A parte passou da tolerância de tamanho (526 > 450).** O AGENTS 5.2 manda **PARAR e propor a divisão** quando passa de ~300 linhas; a DEC-126 só tolera até 1,5x, e o bloco da C (item 5) pede "partes pequenas (DEC-126)". Não há pedido de desvio no commit nem no relatório que eu possa ver. **Recomendo à C:** dividir em **118b** (Province, ProvinceLink, ProvinceLoader, dados e `test_provinces_data`: 20 + 23 + 131 + 124 = **298**) e **118b2** (ProvinceService e `test_provinces`: 107 + 121 = **228**), o que dá duas partes **dentro do teto**, ou então registrar o desvio (AGENTS 16.3) para Arthur aprovar. É conserto de organização de ramos, **não** de código.
**MENOR**
- **R19-M1 a M3 (os mesmos do R17):** o arquivo `provinces.json` e `province_adjacency.json` **só são lidos pelo teste** até a LW-118d (nenhuma validação no início do jogo); o `data/text/pt_br.json` ganhou **mais 4 chaves** (nomes das províncias) sem estar nomeado no bloco da C (ver R17-M2); nomes de exibição ("Província A", "Fronteira") não levam rótulo de proposta.
- **R19-M4. `ProvinceService` copia o conteúdo na entrada?** Não: o construtor **guarda os objetos recebidos** (diz o comentário "não deve alterá-los depois") e só as **respostas** são cópias. Basta o carregador nunca reaproveitar os objetos; hoje é o caso. Sem ação.
- **R19-M5. A ordem das pontas é cobrada no dado** (`province_a_id` antes de `province_b_id` por ordem alfabética, `id` = `a__b`): exatamente o que a ficha manda; só lembro que **uma província nova** (por dado) com nome que quebre a convenção alfabética vai ser recusada com mensagem clara.

**Junção (previsão por `merge-tree`, só texto; o `main` agora é `885615c`, com a pilha da A):** a ponta `5f352a7` × `main`: **14 trechos em 10 arquivos** (a 097e sozinha dá **12 em 9**; a 118a e a 118b acrescentam um em `world.md` e um em `src/sim/world/README.md`). **Entre eles estão 4 arquivos de código e teste:** `src/app/game_app.gd` (2), `src/app/simulation_host.gd` (2), `tests/integration/test_npc_split_oracle.gd` (1) e **`tests/unit/test_economy_production_api.gd` (1, o teste que a A alterou na LW-095a)**; este último **não está** na lista de conflitos esperados do bloco da C (item 4, B0), então a Fase B dela deve **PARAR** nele, como o R10-I4(b) previu.

**8. RISCOS.** O risco do ramo em si é **baixo** (dado e classes soltas); o do **tamanho** é o R19-I1; o da junção com o `main` é o de sempre (a Fase B da C continua BLOQUEADA, esperando Arthur).

**9. PENDÊNCIAS.** *Da C:* R19-I1 (dividir ou pedir o desvio) e M1 a M5 para ciência. *De Arthur:* o `pt_br.json` (R17-M2) e, se a C pedir, o desvio de tamanho. *Que não consegui verificar:* o `check_all` **da C**; que os 19 testes novos passam; a junção real.

**ACOMPANHAMENTO.** *Avanço:* LW-118 partes **a e b** feitas em ramo; a **118c** (`lw-118c-povoado-e-provincia`, `4e8ce98`) acabou de aparecer no GitHub: será a R20. *Decisões de Arthur:* as mesmas das rodadas anteriores. *Git:* só leitura nos ramos remotos; único commit é o `status-b`; `main` em `885615c`.


## RELATÓRIO — R20: ramo novo da conversa C (`lw-118c-povoado-e-provincia`, `4e8ce98`, LW-118 parte c)        Status: PRONTA PARA REVISÃO (revisão independente, SÓ LEITURA) · 11/11/2026 22:21 (Brasília)

**1. RESUMO.** **Nenhum bloqueio, nenhum achado importante.** A parte c liga o **povoado à província e à cultura**: as colunas `province_id` e `culture_id` entram em `settlements.json` (A e B: `province_a`/`province_b` e `culture_trade`; C: `province_c` e `culture_tradition`), `SettlementProvinceCheck` confere tudo (coluna ausente, referência quebrada, província `settled` **sem** povoado, `frontier` **com** povoado), `ProvinceService` ganha `peek_province_of` e os **ids dos povoados** em `peek_province`, e o novo `CultureService` traz `peek_culture`, `peek_cultures` e `peek_culture_of`. **Diferente das partes a e b, esta mexe em arquivos que já existiam** (`Settlement`, `SettlementLoader`, `settlements.json`), mas de forma **compatível** (colunas opcionais no carregador, parâmetros com valor padrão no construtor). **Nenhum teste existente alterado; nenhum protegido; sem save, hash, evento, módulo registrado ou autoload; nada no `main`.** Empilhado na 118b (`5f352a7`), 1 commit.

**2. ARQUIVOS CRIADOS / 3. MODIFICADOS.** Nenhum no projeto; só `STATUS-B.md`.

**4. DECISÕES TÉCNICAS (do revisor).** Li o diff **inteiro** (13 arquivos: 6 `.gd`, 3 `.uid`, 1 dado, 3 documentos), `culture_service.gd` e `settlement_province_check.gd` **inteiros**, os diffs de `province_service.gd`, `settlement.gd` e `settlement_loader.gd`, e os **10 testes pelos nomes**; conferi quem lê `settlements.json` nos testes existentes (`test_population`, `test_new_occupation_by_data`, `test_food_stub`, `test_settlements`, os soaks `game_release` e `sp2`: **só leem ids e coordenadas**, que **não mudaram**) e que **nenhum código fora dos testes chama** os serviços novos (`git grep` em `src` e `tools`). Sem proposta de DEC.

**5. TESTES EXECUTADOS.** **NÃO EXECUTADO: o Godot e o `check_all` da C** (não exportei este ramo). Rodei: contagem DEC-126, `git grep` dos usos, `merge-tree --trivial-merge` (só imprime).

**6. RESULTADOS**
| Item | Resultado |
|---|---|
| **Tamanho (DEC-126)** | **370 linhas** (+362 −8) em **6 `.gd`** (103 + 40 + 8 + 5 + 60 de código e 154 de teste): **acima do teto de 300, dentro da tolerância de 450** |
| **Cumpre `world.md` e `fase-4/dados.md`?** | **Sim:** as 3 linhas de partida batem com a ficha (A e B em `province_a`/`province_b` com `culture_trade`; C em `province_c` com `culture_tradition`); a fronteira **sem povoado**; consultas e códigos (`PROVINCE_UNKNOWN`, `CULTURE_UNKNOWN`, `SETTLEMENT_UNKNOWN`, este **reaproveitado** do `SettlementService`) como a ficha manda |
| **Compatibilidade com o que existe** | Colunas **opcionais** no esquema (arquivos antigos e de teste seguem carregando: há teste "sem as colunas funciona; com elas, chegam"); `Settlement._init` ganha **2 parâmetros com valor padrão** (`""`), então nenhum chamador existente quebra |
| **Hash e save** | **Não mudam:** `settlements.json` é conteúdo (não entra no save nem no hash); as coordenadas **não mudaram**, então o oráculo e os soaks que leem posição não deveriam mudar (a prova é o `check_all` dela, que **não vi**) |
| **Cópias, ordem e erros** | Respostas são **cópias**; listas em ordem crescente de `id`; falhas com código e mensagem que diz o que falhou, onde e o esperado (teste) |
| **Camadas, tempo, aleatoriedade, `float`, dinheiro, autoload** | Limpos |
| **Testes novos (10)** | arquivo real passa a conferência e todo povoado tem província e cultura; cada povoado na sua província e a fronteira sem nenhum; culturas A/B mercantil e C tradicional; cópias; ids desconhecidos com os códigos; carregador sem as colunas e com elas; povoado sem província ou cultura (arquivo, item e campo); referência quebrada com os ids conhecidos; `settled` sem povoado e `frontier` com povoado; vários problemas juntos e um mundo válido |

**7. PROBLEMAS ENCONTRADOS (por gravidade)**
**Bloqueante e importante: nenhum.**
**MENOR**
- **R20-M1. A conferência ainda não roda no início do jogo** (a ligação no módulo é da 118d): `SettlementProvinceCheck.check` só é chamado pelos testes; quem quebrar as colunas reais só é pego pelo `check_all` (mesma situação do R17-M1).
- **R20-M2. "Obrigatória" na ficha, "opcional" no esquema.** `fase-4/dados.md` diz que `province_id` e `culture_id` são **obrigatórias**; o esquema as marca opcionais (para não quebrar arquivos antigos) e a obrigação fica no `SettlementProvinceCheck`. É uma escolha de implementação razoável e **documentada no código**; só registro que a regra só vale depois da 118d.
- **R20-M3. Os serviços não impedem `id` de povoado repetido** (`_settlement_ids` acumula): quem garante a unicidade é o `SettlementLoader` (esquema), então hoje não ocorre.
- **R20-M4. `ProvinceService` aceita o terceiro argumento opcional `settlements`** (`= []`): quem o construir sem povoados terá `peek_province_of` falhando com `SETTLEMENT_UNKNOWN` para todos; é o comportamento certo, mas a 118d precisa lembrar de passá-los.

**Junção (previsão por `merge-tree`, só texto; `main` = `885615c`):** a ponta `4e8ce98` × `main`: **14 trechos em 10 arquivos, os mesmos da 118b** (nenhum arquivo novo em conflito: `settlements.json` **não** conflita, a A não o tocou). Continuam entre eles os 4 de código e teste (`game_app.gd` ×2, `simulation_host.gd` ×2, `test_npc_split_oracle.gd` e **`test_economy_production_api.gd`**, este fora da lista esperada do bloco da C).

**8. RISCOS.** Baixo; é a primeira parte da LW-118 que **altera** arquivo existente, então o `check_all` dela (que não vi) é a prova que importa; a Fase B da C segue BLOQUEADA aguardando Arthur.

**9. PENDÊNCIAS.** *Da C:* nada obrigatório (R19-I1, da parte anterior, segue aberto); M1 a M4 para ciência. *Que não consegui verificar:* o `check_all` **da C** (em especial que `test_settlements`, `test_population` e os soaks seguem verdes com as colunas novas); que os 10 testes novos passam; a junção real.

**ACOMPANHAMENTO.** *Avanço:* LW-118 partes **a, b e c** feitas em ramo; falta a **118d** (ligação no módulo e a validação no início do jogo). *Próxima:* o que o vigia trouxer. *Decisões de Arthur:* as mesmas das rodadas anteriores. *Git:* só leitura nos ramos remotos; único commit é o `status-b`; `main` em `885615c`.


## RELATÓRIO — R21: ramo novo da conversa C (`lw-118d-world-ligado`, `15b95d4`, LW-118 parte d, a última)        Status: PRONTA PARA REVISÃO (revisão independente, SÓ LEITURA) · 11/11/2026 22:35 (Brasília)

**1. RESUMO.** **Nenhum bloqueio, nenhum achado importante nesta parte.** A 118d **liga a estrutura ao jogo**: o `WorldSetup` (em `src/app/`) passa a ler e conferir `provinces.json`, `province_adjacency.json` e `cultures.json` e a conferir os povoados contra eles (`SettlementProvinceCheck`); falha vira **uma** falha tratada (`WORLD_SETUP_INVALID`, com arquivo, item e campo); o `WorldModule` responde `peek_province`, `peek_provinces`, `peek_province_of`, `peek_adjacent_provinces`, `peek_culture` e `peek_culture_of` (cópias) e o `validate()` dele acusa as inconsistências; o `GameModules` entrega os serviços ao módulo. **Fecha a LW-118** (a a d, só em ramos). **Nada no save nem no `state_hash`** (teste); **nenhum teste existente alterado**; nenhum protegido; nenhuma tag; nada no `main`. Empilhado na 118c (`4e8ce98`), 1 commit. A C **parou** aqui (fim da cadeia da noite, `status-c` das 22:25).

**2. ARQUIVOS CRIADOS / 3. MODIFICADOS.** Nenhum no projeto; só `STATUS-B.md`.

**4. DECISÕES TÉCNICAS (do revisor).** Li o diff **inteiro** (7 arquivos: 4 `.gd`, 1 `.uid`, 2 documentos), o `world_setup.gd` **inteiro**, o diff de `world_module.gd` e `game_modules.gd`, e os **7 testes pelos nomes**. Conferi os **quatro chamadores** de `WorldSetup.from_dir` (`game_app.gd` e os testes `test_world_module`, `test_world_province_queries`): o `test_world_module.gd` **antigo** carrega os povoados **do diretório real** (que já têm as colunas desde a 118c) e o caso "pasta que não existe" falha **antes**, nas rotas (a mensagem ainda cita `routes.json`): **os testes antigos seguem compatíveis sem mudança**. Conferi também o que a ficha diz do `check_content_ids` (as colunas que ele "precisará conhecer" são as de **outros** módulos; `province_id` e `culture_id` do povoado são do próprio `world` e são conferidas no carregamento): **a C não precisava alterar o verificador**.

**5. TESTES EXECUTADOS.** **NÃO EXECUTADO: o Godot e o `check_all` da C.** A C relata `check_all` VERDE na 118d (**153 scripts, 1.390 testes, 296.671 asserts**) e "nenhum hash mudou"; **não conferi** esses números. Rodei: contagem DEC-126, `git grep` dos chamadores, leitura da ficha, `merge-tree --trivial-merge` (só imprime).

**6. RESULTADOS**
| Item | Resultado |
|---|---|
| **Tamanho (DEC-126)** | **221 linhas** (+217 −4) em **4 `.gd`**: **dentro do teto** |
| **Hash e save** | **Não mudam** (a estrutura é conteúdo; testes: "não entra no save nem no hash" e "um jogo salvo carregado num mundo novo dá as mesmas consultas"). O registro do `world` e a população nova (que **mudam** o hash) já eram da LW-097, da C, e **continuam fora do `main`** |
| **Compatibilidade** | `WorldModule._init` ganha **2 parâmetros com valor padrão** (`null` = sem províncias nem culturas, o módulo segue funcionando: teste); `validate()` só **acrescenta** os problemas dos serviços |
| **Dados inválidos no início (AGENTS 13.1.7)** | **Cumprido:** o jogo não inicia com `provinces.json`, `province_adjacency.json`, `cultures.json` ou `settlements.json` incoerentes (uma falha tratada com arquivo, item e campo; testes de arquivo ausente, inválido e povoado que não bate) |
| **Camadas, tempo, aleatoriedade, `float`, dinheiro, autoload** | Limpos; `src/app` só orquestra, a regra mora em `src/sim/world` |
| **Testes novos (7)** | o módulo responde as seis consultas com os dados reais; ids desconhecidos com os códigos; mundo registrado **sem** a estrutura funciona; a estrutura **não entra** no save nem no hash; jogo salvo carrega num mundo novo e dá as mesmas consultas; o `setup` falha com **um** erro tratado (arquivo ausente ou inválido); falha quando um povoado não bate com as províncias ou as culturas |

**7. PROBLEMAS ENCONTRADOS (por gravidade)**
**Bloqueante e importante: nenhum nesta parte.** (O **R19-I1**, o tamanho da 118b, **continua aberto** na parte anterior.)
**MENOR**
- **R21-M1. `WorldSetup` ficou mais estrito com o diretório de dados:** qualquer teste, ferramenta ou soak futuro que o chame com um diretório que **não tenha** as três tabelas novas passa a falhar. Hoje os 4 chamadores usam o diretório real (ou um que falha antes), então nada quebra.
- **R21-M2. `debug_summary` do `WorldModule` não ganhou a contagem de províncias e culturas** (os serviços têm o `debug_summary` deles). Como é conteúdo, não é exigência do AGENTS 4.15; só facilitaria a depuração.
- **R21-M3. A ordem das conferências** (rotas, províncias, culturas, povoados) devolve **o primeiro** erro, não todos; é o padrão dos outros carregadores.

**Junção (previsão por `merge-tree`, só texto; `main` = `885615c`):** a ponta `15b95d4` × `main`: **14 trechos em 10 arquivos, os mesmos da 118b e da 118c** (a 118d **não** acrescenta nenhum arquivo em conflito). Os de código e teste continuam: `game_app.gd` ×2, `simulation_host.gd` ×2, `test_npc_split_oracle.gd` e **`test_economy_production_api.gd`** (este fora da lista esperada do bloco da C).

**8. RISCOS.** Baixo nesta parte. O que pesa na C é a **Fase B da LW-097** (BLOQUEADA, espera Arthur) e a junção sobre o `main` novo.

**9. PENDÊNCIAS.** *Da C:* nada novo; R19-I1 (tamanho da 118b); R21-M1 a M3 para ciência. *De Arthur:* as da seção final. *Que não consegui verificar:* o `check_all` **da C** (aceito o relato dela); que os 7 testes novos passam; a junção real.

**ACOMPANHAMENTO.** *Avanço:* **LW-118 completa em ramos (a a d)**; nada dela no `main`. *Git:* só leitura nos ramos remotos; único commit é o `status-b`; `main` em `885615c`.


## RELATÓRIO FINAL DA NOITE (bloco B v6) — revisões R8 a R21 e 3 auditorias de entrada no `main`        Status: PRONTA PARA REVISÃO (SÓ LEITURA; nada além do `status-b`) · 11/11/2026 22:36 (Brasília)

**1. RESUMO.** **Parei por "nada mais novo" (regra 13):** a A concluiu o bloco v10 às 22:15 (`main` em `885615c`, avanço simples) e a C fechou a LW-118 às 22:25 (só em ramos) e declarou que parou; o vigia do GitHub (consulta a cada 10 min, **sem gastar rodada enquanto nada mudava**) não viu mais nada depois da 118d, e **desliguei o vigia**. **Nenhum bloqueio meu; nada fugiu do combinado** (nenhuma tag, nenhum `--force`, nenhum `main` tocado por mim, nenhum documento do repositório editado). Revi **14 relatórios** (21 ramos e partes) e auditei **as 3 entradas no `main`** da noite, cada uma **em menos de 20 minutos**. **Os 3 `main` novos estão SÃOS**, com `check_all` **meu**, independente, em cópia exportada (sem escrever no repositório), verde nos dois que mexem em código.

**2. O QUE FOI FEITO (tudo em `STATUS-B.md`, ramo `status-b`)**
| Parte | Alvo | Resultado |
|---|---|---|
| R8 | A: LW-095 a–d | sem bloqueio; 1 importante (o `IncomeStub` segue vivo: a A declara que falta a parte final) |
| R9, R10 | C: 097d e 097e | sem bloqueio; importantes sobre ofícios x receitas, **dono do `service_posts.json`** (hoje da A, DEC-235), comida do C e o aviso da junção |
| Entrada no `main` #1 | A: LW-093 (`f2bcb4c`) | **SÃ** (`check_all` meu: 151 scripts, 1.322 testes, verde) |
| Entrada no `main` #2 | C: LW-117i (`4372f7f`, só documentos) | **SÃ** (conferida por inspeção; sem código) |
| R11 a R13 | A: 093k, 096a, 096b | sem bloqueio; **R13-I1** (recusa de `request_post_contract` gasta um ID, contrário do `economy.md`) |
| R14, R15 | A: 096c (conclusão) e 096d (prazo) | sem bloqueio; **R15-I1** (custódia de emissor morto fica presa) |
| R16 | A: 096e (vagas) | sem bloqueio; **R16-I1** (a vaga é causa **nova** de mudança de oráculo e soak na junção com a C) |
| R18 | A: LW-096a (NPC aceita vaga) | sem bloqueio; **R18-I1** (30 NPCs de posto da C contam como desempregados sem `service_posts.json`) |
| Entrada no `main` #3 | A: resto do marco 2 (`885615c`) | **SÃ** (`check_all` meu: **162 scripts, 1.391 testes, 294.336 asserts, verde**; iguais aos da A; oráculo e soak sem arquivo tocado; 1 teste antigo com 2 linhas trocadas, já autorizado) |
| R17, R19, R20, R21 | C: LW-118 a, b, c, d | sem bloqueio; **R19-I1** (a 118b passou da tolerância de tamanho: 526 > 450 linhas) |

**3. ACHADOS ABERTOS (nenhum é bloqueante; o `main` novo já carrega os da A)**
- **Da A** (já no `main`; o jogo real não tem local de trabalho nos dados da A, então hoje **nada muda**): **R13-I1/R14-I1** (validar antes de pedir o ID; um teste do contador), **R15-I1** (a frase "a custódia nunca fica retida" do `economy.md` não vale para emissor morto), **R18-I1** (desempregado = `work_place_id` vazio, não "não listado pela economia"), além dos menores (R12-M2/M3, R14-M3/M5, R15-M1/M2, R16-M2/M3, R18-M2 a M6).
- **Da C** (só em ramos): **R19-I1** (tamanho da 118b), **R10-I1** (2 dos 14 locais de produção têm ofício diferente da receita: `mine_ore` e `shear_wool`), **R10-I3** (30 dias de comida no C não cabem: 5.893 de peso contra 5.000), **R9-I3** (24 arquivos na 097d, acima da tolerância de arquivos).
- **Das duas, na junção (a Fase B da C):** **R10-I4 e R16-I1/R18-I1.** A C está **BLOQUEADA** (`status-c`, 21:52) porque 2 testes **da A** (`test_game_economy_wiring` e `test_economy_start_money_and_consume`) falham na junção por IDs e dinheiro; a junção prevista sobre o `main` novo tem **14 trechos em 10 arquivos**, e 1 deles é **um teste** (`test_economy_production_api.gd`, que a A alterou) **fora da lista de conflitos que o bloco da C aceita** (o bloco manda PARAR). A prova do oráculo da C foi feita sobre `4372f7f`; **precisa ser refeita sobre `885615c`** e conferir se há morte de NPC no oráculo e no soak (a vaga e o emprego mudam o resultado se houver).

**4. DECISÕES QUE DEPENDEM DE ARTHUR (cada uma com a minha recomendação)**
1. **Fase B da C:** autorizar a troca dos números dos 2 testes (patch pronto, segundo a C). **Recomendo autorizar** só **depois** de (a) refazer a prova do oráculo sobre `885615c`, (b) conferir morte de NPC no oráculo e no soak e (c) **autorizar por escrito o conflito em `test_economy_production_api.gd`** (ou mandar a A fazer a junção desse teste).
2. **`service_posts.json` antes da Fase B da C:** recomendo que a A o crie (parte final da LW-095, DEC-235) **antes** de a C juntar, e que a A corrija o R18-I1; sem os dois, o primeiro NPC que morrer num local de produção faz um guarda ou estalajadeiro abandonar o posto.
3. **R15-I1:** para onde vai a recompensa de um contrato cujo emissor morreu (hoje fica na conta do contrato; o dinheiro de quem morre já fica na conta fechada). **Recomendo** a conta do mercado do povoado do emissor, que mantém o dinheiro em circulação.
4. **R16-M1:** ratificar "no máximo **uma** vaga aberta por local, conferida **por hora**" (proposta da A, sem decisão no GDD).
5. **R18-M3:** o ofício do NPC acompanha o emprego? (hoje não: o artesão que vira guarda continua artesão).
6. **R19-I1:** aceitar o desvio de tamanho da 118b (526 linhas, só conteúdo e classes soltas) ou mandar a C dividir. **Recomendo aceitar por escrito** (as outras três partes ficaram em 214, 370 e 221).
7. **`data/text/pt_br.json`:** a C acrescentou 6 chaves (culturas e províncias) sem o bloco nomear o arquivo (R17-M2, R19-M1). **Recomendo** considerar coberto (são os nomes dos próprios dados).
8. **Em aberto das noites anteriores:** as **7 linhas de teste** do R6-M2 (a A pede autorização) e a **tolerância de arquivos** da 097d (R9-I3).

**5. CORREÇÃO DE UM ERRO MEU.** No **R9-I2** e no **R10-I2** escrevi "**36** NPCs de guarda e estalajadeiro" sem `service_posts.json`. **O número certo é 30** (por script, em `data/population.json` da 097d/097e: 8 + 6 + 5 + 3 + 5 + 3 = **30**; os outros 102 trabalham nos 14 locais de produção, total 132). **A conclusão não muda** (o R18-I1 já usa 30). Descoberto e corrigido nesta rodada; nada foi publicado fora do `STATUS-B`.

**6. TESTES EXECUTADOS (meus).** `check_all` **independente** em cópia exportada (`git archive`, **nenhuma escrita no repositório**): `main` `f2bcb4c` **VERDE** (151 scripts, 1.322 testes); ramo da C 097e **VERDE**; `main` `885615c` **VERDE** (162 scripts, 1.391 testes, 294.336 asserts, 183,5 s; os `ERROR`/`WARNING` que o GUT imprime nos testes de caminho de erro são **os mesmos** do `main` anterior: 68 e 37). Fora esses: contagens DEC-126, `git grep`, scripts de conferência dos dados (equipe x `workers_wanted`, população x postos) e `git merge-tree --trivial-merge` (só imprime). **NÃO EXECUTADO:** o `check_all` de cada ramo das partes 095, 096, 093k, 096a e 118a a 118d (aceitei os relatos das duas conversas: 162/1.391 pela A; 153/1.390 pela C na 118d).

**7. O QUE NÃO CONSEGUI VERIFICAR.** (1) **As autorizações** das duas conversas para entrar no `main` e alterar o teste antigo (li os textos que elas citam, não os blocos originais); (2) se há **morte de NPC** no oráculo e no soak (decide o R16-I1); (3) o comportamento do **corpo** do NPC ao trocar de emprego no meio de uma ação (R18-M4) e o jogo **em tela**; (4) o **soak longo** (o `check_all` roda o curto); (5) a **junção real** (o `merge-tree` só prevê **texto**); (6) se os testes novos de cada ramo passam (li os asserts, não rodei).

**8. GIT.** Único alvo de escrita: o ramo `status-b` (commit e push a cada revisão, **sem outras referências**, **sem tag, sem `--force`, sem merge, sem apagar ramo**). `main` em `885615c` (não toquei). Tags remotas iguais às de antes (`fase-0/1/2-concluida`). Só leitura nos ramos `origin/...` das duas conversas; nenhum worktree alheio mexido.

**ACOMPANHAMENTO.** *Avanço:* os dois marcos da A (2 em código, 3 sem posto/IncomeStub) e a LW-118 da C estão **revisados**; faltam, na A, a **LW-095 final** (`service_posts.json`, retirada do `IncomeStub`) e a **LW-094** (não iniciada); na C, a **Fase B da LW-097** (bloqueada). *Próxima tarefa recomendada:* a decisão 1 e 2 acima (junção da C sobre `885615c`). **Não iniciada.** *Git:* nada para commitar além deste arquivo; `status-b` publicado.


## DECISÃO DE ARTHUR REGISTRADA — Fase B da LW-097 (conversa C)        12/11/2026 07:03 (Brasília) · registro a pedido de Arthur, feito pela conversa B

**A decisão (palavras de Arthur, pelo painel do chat):** à pergunta "Autoriza a Fase B da C depois de refazer a prova do oráculo sobre 885615c?", Arthur respondeu **"Autorizo, com condições"**. **Ele não detalhou as condições.**

**Entendimento da B sobre as condições (NÃO são palavras de Arthur; são as 3 da recomendação do relatório final, seção 4, item 1):**
1. **(a)** a C refaz a prova do oráculo sobre o `main` de agora (`885615c`); a anterior foi feita sobre `4372f7f`;
2. **(b)** a C confere se algum NPC morre no oráculo e no soak (R16-I1 e R18-I1); se morrer, a causa não está entre as autorizadas e a aprovação por antecipação não vale;
3. **(c)** o conflito em `tests/unit/test_economy_production_api.gd` não está na lista de conflitos que o bloco da C aceita; **este "Autorizo" não o cobre por si só**: precisa de autorização escrita de Arthur que cite o arquivo, ou a A faz a junção desse teste.

**O que este registro NÃO faz:**
- **Não** autoriza a troca dos números dos 2 testes da A (`test_game_economy_wiring` e `test_economy_start_money_and_consume`) que o `status-c` pede; Arthur não disse isso.
- **Não** decide o `service_posts.json` nem a correção do R18-I1 pela A antes da junção (decisão 2 do relatório final).
- **Não** é uma instrução da B à C ou à A: elas recebem as decisões direto de Arthur (regra de 11/11/2026). A B só registra o que ele decidiu.

**Estado:** nenhum documento do repositório foi editado; `main` em `885615c`; A e C paradas; a B não iniciou nenhuma tarefa nova (regra 13).


## BLOCO B v7 — MANHÃ (12/11/2026, 07:10; limite 13:00): decisões de Arthur registradas, estado das frentes e vigia        12/11/2026 07:17 (Brasília)

**Declaração do início (AGENTS 2.3).** *Li:* o bloco v7 de Arthur; a primeira linha e o relatório de `origin/status-a` e `origin/status-c` (só leitura); `docs/fase-5/dados.md`, seção 9, **no `main`** (`885615c`). *Tarefa:* religar o vigia; registrar as decisões dele; fazer a revisão cruzada quando a C empurrar a Fase B da LW-097 ou a A empurrar `lw-096h-…`. *Git:* só commit e push do `status-b`; **nenhum documento do repositório editado**, nada no `main`.

### A. Decisões técnicas de Arthur sobre a minha lista de decisões abertas (12/11, 07:10; rótulo dele: **PROPOSTA**)
| Item da lista | Decisão de Arthur | Quem executa e o que a B confere depois |
|---|---|---|
| **R13-I1/R14-I1** (recusa de `request_post_contract` gasta ID) | A **A corrige em ramo agora** | A, ramo `lw-096h-…`; a B confere que a validação vem **antes** de pedir o ID e que há teste do contador |
| **R18-I1** (desempregado = lista da economia) | A **A corrige em ramo agora** | A, mesmo ramo; a B confere que quem tem `work_place_id` em local sem local de produção nem posto **não** conta como desempregado, com teste |
| **`service_posts.json`** | **Só entra depois da LW-097 no `main`**; o `PostLoader` entra **antes, só em código** | A |
| **R16-M1** (vaga única por local e por hora) | **Fica como está** | — |
| **R19-I1** (118b com 526 linhas) | **Exceção única aceita** | — |
| **`pt_br.json`** (6 chaves da C, R17-M2/R19-M1) | **Vão para o backlog da C** | C |
| **R6-M2** (7 linhas de teste) | **Ficam no backlog**; nenhum teste existente é editado por elas | — |
| **R9-I3** (tolerância de arquivos da 097d) | **Ratificada** | — |
| **R15-I1** (custódia de emissor morto) | **SEM decisão ainda** (ele avisa) | — |
| **R18-M3** (o ofício acompanha o emprego?) | **SEM decisão ainda** (ele avisa) | — |

### B. Decisões de Arthur sobre `docs/fase-5/dados.md`, seção 9 (12/11, 07:05)
Aprovou as **recomendações técnicas** dos pontos **1, 2, 3, 4, 6, 7, 8, 10, 11, 12, 13 e 14**; o ponto 15 só diz que todo número é **[HIP]**.
| Ponto | Texto resumido da recomendação | Decisão |
|---|---|---|
| 1 | Dois arquivos de habilidades (`skills.json` e `combat_skills.json`), sem mexer no `skill_id` do contrato do `combat` | **APROVADA** |
| 2 | A arma liga o golpe à habilidade (`weapons.skill_id`, não uma coluna no golpe) | **APROVADA** |
| 3 | Porcentagem inteira no combate (`_pct`) em vez de pontos-base | **APROVADA** |
| 4 | Limiar de "ferido" em **dois** valores (`combat.md` seção 10 e `character.md` E7) com teste de igualdade | **APROVADA** |
| 5 | O que o nível de cada habilidade faz | **Decisão de jogo dele: só a furtividade tem efeito** (LW-163); **corpo a corpo, arco e comércio só registram o nível** (sem bônus de dano por nível) |
| 6 | `bound` na **instância** do item (nasce de `origin_items.bound`) | **APROVADA** |
| 7 | Sem habilidade de forja (qualidade só pela receita na Fase 5); a qualidade só muda o valor de venda, em fórmula da LW-148 | **APROVADA** |
| 8 | Três origens do protótipo **sem relações iniciais** | **APROVADA** |
| 9 | **Sem linha, por falta de decisão:** arco e munição; efeito de "ferido"; vida ao renascer; minério escondido (`ore_deposit`); recompensa da ruína; onde começa quem vem da estrada | **SEM DECISÃO** (continuam em aberto) |
| 10 | Visibilidade: `outpost` = `always`, `camp` = `discovered`, `respawn` = `always` | **APROVADA** |
| 11 | Província do covil guardada **só no ponto** (a `ecology` lê do `world`); hoje o `dados.md` a mantém nos dois arquivos com teste de igualdade | **APROVADA** (a mudança no `dados.md` fica para a tarefa DOC dele) |
| 12 | Pasta por módulo (`data/events/` etc.) e **um só** `dados.md` | **APROVADA** |
| 13 | `fight`, `surrender` e `take_item` em dados pedem condições novas no vocabulário do `npc`: **uma parte nova da série de contratos antes da LW-155** | **APROVADA** |
| 14 | Coluna `scope_poi_kind` em `events.json` e tabela `forgeable_goods` com `owner_kind_id` | **APROVADA** |
| 15 | Todo número é **[HIP]** | só registro |

**O que a B NÃO fez, por ordem dele:** não registrou nada em `DECISIONS.md`; não mudou o cabeçalho do `dados.md`; não editou nenhum documento. **Isso vira tarefa DOC dele depois das junções.** A B só registra aqui o que ele decidiu; **não repassa** nada à A nem à C.

### C. Estado das frentes às 07:15 (só leitura)
- **`main`:** `885615c` (nada novo desde a entrada da A); as 3 tags iguais.
- **A** (`status-a`, 07:02): a lista da LW-094 foi autorizada, mas a LW-094 **só começa com a LW-097 no `main`** (DEC-236); sem a produção nos dados o jogo real e o soak de 7 dias morrem de fome. **Nenhum ramo novo** desde as 22:37 (nenhum `lw-096h-…` ainda).
- **C** (`status-c`, 07:12): **BLOQUEADA** na 2ª tentativa da Fase B da LW-097 (contra `885615c`, com as 2 autorizações dele: os 2 testes da A e o conflito de `test_economy_production_api.gd`). Oráculo **provado e estável** (9 valores novos da junção; duas execuções iguais; neutralizando as causas da C os 9 voltam **exatamente** aos da A), conflitos resolvidos, `c_market_01` = `market`, teste novo do jogo real. **Mas o `check_all` da junção dá 32 falhas** (1.444 testes, 1.412 aprovados) em **7 arquivos de teste** que o bloco dela não lista. **Nada commitado nem enviado; `main` intocado; ela pede autorização por escrito para ajustar esses 7 arquivos.** (O push dela ainda **não** aconteceu: não há código para revisar.)

### D. Leitura de apoio à decisão dele: o que são os 7 ajustes que a C propõe (a partir do relatório dela; **não é a revisão de código**, que só posso fazer quando houver push)
| Arquivo | Falhas | O ajuste proposto pela C | Só número? | Verificado por ela? |
|---|---|---|---|---|
| `tests/unit/test_site_payroll.gd` (A) | 5 | `SITE_BREAD` 3 → 4 | **Sim** (ID) | Sim, 7 de 7 |
| `tests/unit/test_contract_vacancies.gd` (A) | 9 | `SITE` 3 → 4 e `POST` 4 → 5 | **Sim** (IDs) | Sim, 9 de 9 |
| `tests/unit/test_npc_vacancy.gd` (A) | 9 | `SITE` 3 → 4 e `POST` 4 → 5 | **Sim** (IDs) | Sim, 11 de 11 |
| `tests/unit/test_service_posts.gd` (A) | 5 | acrescentar `production_sites = []` em `_definitions` | **Não:** muda a **montagem** do teste (tira os 14 locais reais) | **Não** |
| `tests/unit/test_service_post_queries.gd` (A) | 2 | idem | **Não:** idem | **Não** |
| `tests/integration/test_npc_buys_food.gd` (A) | 1 | passar a **esperar também o motivo `salary`** (com comentário) | **Não:** **amplia** uma expectativa (os 3 dias de jogo real agora têm salário) | **Não** |
| `tests/unit/test_economy_production_api.gd` (da 097e, da C) | 1 | próximo ID livre 18 → 32 (3 mercados + 14 locais + 14 vagas = 31 usados) | **Sim** (número do teste dela) | **Não** |

**Minhas observações, para ele decidir (nenhuma é achado de código):**
1. **Só 4 dos 7 são só número** (3 de ID e 1 número da própria C); **3 mudam outra coisa** (2 de montagem, 1 amplia uma lista esperada). Todos preservam o objetivo do teste segundo a C, mas o critério dele ("os testes antigos trocados são só números") **não vale para esses 3**: a autorização precisa ser **explícita para eles**.
2. **4 dos 7 ajustes não foram verificados** por ela (`test_service_posts`, `test_service_post_queries`, `test_npc_buys_food` e `test_economy_production_api`).
3. **A conta de IDs bate** (3 mercados + 14 locais + 14 vagas = 31 usados, próximo livre = 32; antes 3 + 14 = 17, próximo 18): as **14 vagas** vêm de um mundo de teste **sem NPCs**, onde nenhum local tem equipe; com os **132 NPCs** do jogo real cada local de produção nasce com exatamente `workers_wanted` (conferi nos dados da C, R16-I1), **então não deve nascer vaga na hora 1**. **Isto precisa ser conferido no soak de 30 dias quando houver push** (critério dele: nenhum `ContractOffered`).
4. **Confirma o que a B previu** (R10-I4 e R16-I1): o `main` com a pilha da A + a LW-097 desloca IDs e liga o salário nos testes que usam os dados reais.
5. **Não vi, no relatório dela, a conferência de "nenhum NPC morre"** (nova condição dele); a conferir quando a Fase B for empurrada.

### E. Vigia
**Religado às 07:15** (`watch_gh.sh`, consulta a cada 10 min, **sem gastar rodada enquanto nada muda**; limite 12:50; linha de base de 153 referências, `main` em `885615c`). *Quando a C empurrar a Fase B* (ramo ou `main`) ou a A empurrar `lw-096h-…`: **revisão cruzada só de leitura**, um commit e push do `status-b` por revisão. *Se a LW-097 entrar no `main`* (auditoria em até 20 minutos): avanço simples e tags; rotas **e** economia no jogo real (`start_default_game`); uma assinatura de `start_new_game` e de `register`; `c_market_01` = `market`; os **9 valores do oráculo** e o **hash do soak** só pelas causas que ele autorizou; **nenhum NPC morrendo**; **nenhum `ContractOffered` no soak de 30 dias**; conservação; se os testes antigos trocados são **só números**; `check_all` **meu**, independente, em cópia exportada. *Se a A empurrar o `lw-096h`:* conferir o R13-I1/R14-I1 e o R18-I1 como na tabela A.

**O que não consegui verificar ainda:** tudo o que depende de push (código da Fase B, `check_all` da junção, oráculo e soak no `main`); o relatório da C é a única fonte do que está no diretório de trabalho dela.


## AUDITORIA DE ENTRADA NO `main` — conversa C, `81ce7f4` (Fase B da LW-097: partes 097a a 097e e a junção)        Veredito parcial: **SÃ NA ESTRUTURA; `check_all` e diagnóstico independentes em execução (adendo abaixo)** · 12/11/2026 07:43 (Brasília; commits da C às 07:27 e 07:28, o vigia viu às 07:38, auditoria iniciada às 07:38:48)

| Pergunta de Arthur | Resultado (conferido por mim) |
|---|---|
| **Avanço simples?** | **Sim:** `885615c` é ancestral de `81ce7f4`. As 3 tags remotas **iguais** (`fase-0/1/2-concluida`); nenhum arquivo apagado (62 modificados, 27 novos) |
| **O que entrou** | 7 commits: `5c5fcb7` (097a), `eb6a23a` (097b), `0c5047c` (097c), `f346ed9` (097d), `4e614b5` (097e), **o merge `d5661a4`** (junção com `885615c`) e `81ce7f4` (linha de status); **89 arquivos, +1.899 −187**: `src` 20, `tests` 52, `data` 11, `docs` 6, `tools` 0. **A LW-118 não entrou** (segue só em ramos, como mandou) |
| **Arquivos protegidos** | **Nenhum tocado.** `docs/ROADMAP_STATUS.md`: **só 1 parágrafo acrescentado**, nenhuma contagem mudou |
| **Rotas E economia no jogo real** | **Sim:** `GameApp.start_default_game` passa `_load_economy_setup()` **e** `_load_world_setup()`; o teste **novo** `tests/integration/test_real_game_has_routes_and_economy.gd` confere as 3 rotas abertas no `world` **e** 3 mercados e 14 locais de produção na economia |
| **Uma assinatura só** | **Sim:** `SimulationHost.start_new_game(…, economy_setup, world_setup)` e `GameModules.register(…, economy_setup, world_setup)` (uma de cada) |
| **`c_market_01`** | **`market`** (`data/world/places.json:52`) |
| **Os 9 valores do oráculo** | Os 9 do `test_npc_split_oracle.gd` no `main` **batem com a tabela da C** ("junção, estoque do C 6.000": `28802dfa9d06`, `916683019e46`, `a2b476e37a0c`, `b4c379eaad55`, `a96d78a9a82f`, `5c885dbc09ee`, `c5b515175b72`, `d2533a12fd05`, `48857919c5ff`), e os que saíram são **exatamente os da A** (`8670b52b8ff6` … `76a65b9cfc8a`, os do `main` `885615c`). Causas: população de 132, rotas, módulo `world` e o **estoque de comida do C** (3.000 → **6.000**, `data/food_stub.json`, o único dado alterado depois da 097e), **todas as que Arthur autorizou**. A **prova por neutralização** (as causas da C desligadas devolvem os 9 da A) é **relato dela; não a refiz** |
| **Hash do soak** | **Nenhum hash de soak está gravado em arquivo** (os soaks só mudaram **constantes**: população 100 → 132, e um ponto de amostra do soak de 1 ano). O `run_sim --days 30 --seed 1` dá `732907967efd` antes e depois, **segundo a C**: a **minha** execução está no adendo |
| **Testes antigos trocados: só números?** | **39 arquivos existentes alterados, nenhum teste removido** (4 funções **renomeadas** por 2 → 3 mercados e por `work_place_id`; **67 linhas de `assert`/`func test_` removidas contra 357 acrescentadas; nenhum arquivo ficou com menos**). Dos **9 da junção** (leitura linha a linha): **3 são só números** (`test_site_payroll`, `test_contract_vacancies`, `test_npc_vacancy`: IDs 3→4 e 4→5); **2 mais** os **números de IDs** (`test_service_posts`, `test_service_post_queries`) **e 2 linhas de montagem** (`production_sites` vazio) e textos; **1 acrescenta um elemento** a uma lista esperada (`test_npc_buys_food`: `["game_start", "salary", "trade"]`, ainda igualdade exata); **2 números autorizados na 1ª rodada** (`test_game_economy_wiring`: mercados `[1, 2, 3]`, primeiro NPC 3 → 18, dinheiro `9000 + 14 × 200 + 60 × N`; `test_economy_start_money_and_consume`: 6000 → 11800 e 6160 → 11960); **1 número do teste da própria C** (`test_economy_production_api`: 18 → 32). **Os 3 que não são só número (service_posts, service_post_queries, buys_food) a C os declara com honestidade** e cita a resposta de Arthur "Autorizo os 7 ajustes" (12/11) |
| **Nenhum NPC morrendo; nenhum `ContractOffered` no soak de 30 dias** | **Relato da C** (jogo real, `start_default_game` + 30 dias, fora do repositório): com o estoque do C em **3.000 morreram 28 NPCs (os do C, dias 19 a 21) e saíram 7 `ContractOffered`** (**a minha previsão do R16-I1 se confirmou**); ela parou, Arthur autorizou **6.000**, e então **0 mortes, 0 `ContractOffered`**, 319 `WagesPaid`, conservação e `validate()` ok. **O soak e o oráculo que já existem NÃO carregam a economia** (`GameModules.register` sem `economy_setup`), então **não exercitam vaga, salário nem fome do C**: a condição de Arthur só é provada por esse diagnóstico fora do repositório. **O meu, independente, está no adendo** |
| **Conservação** | Relato da C: dinheiro e bens ok; **o meu diagnóstico confirma ou não no adendo** |
| **`check_all` independente (meu)** | **em execução** numa cópia exportada de `81ce7f4` (`git archive`, **nenhuma escrita no repositório**), iniciado às 07:38:59; o resultado vai no adendo. A C relata **VERDE**: 169 scripts, 1.444 testes, 297.868 asserts |
| **Camadas e regras** | `src/` +602 −23: mudanças na estrutura do `world`, `npc` (população por `work_place_id`), `app` (assinaturas) e dados; **nenhum `project.godot`, nenhum autoload, nenhum `tools/`** |

**Observações (nenhuma bloqueia a entrada):** (1) o **FoodStub do C em 6.000 é [HIP] provisório**: a C diz que o mercado do C tem só 200 de pão e 10 de grão e que **o fim do `FoodStub` (LW-094) precisa de uma fonte de comida para o C** (o R10-I3 que eu levantei); (2) o cabeçalho de contagem de `docs/events.md` continua dizendo "5 implementados" na Fase 3 com mais na tabela (a C só acrescentou o `RouteStateChanged`); (3) as 6 chaves de `pt_br.json` da LW-118 e a constante 132 repetida vão para o backlog da C (decisão de Arthur); (4) **as autorizações "Autorizo os 7 ajustes" e "Autorizo 6.000" são respostas de Arthur à C no chat: não as vi, só o texto que a C cita.**

**O que NÃO consegui verificar (até aqui):** a prova por neutralização do oráculo; as autorizações originais; o soak longo; o resultado do `check_all` e do diagnóstico (adendo).


### Adendo 1 à auditoria de `81ce7f4`: o `check_all` e o `run_sim` independentes · 12/11/2026 07:44 (Brasília)
| Item | Resultado |
|---|---|
| **`check_all` independente (meu)** | **VERDE.** Cópia exportada de `81ce7f4` (`git archive`, nenhuma escrita no repositório), iniciado 07:38:59 e terminado 07:43:52, código 0: arquitetura e dados OK, "IDS DE CONTEÚDO: tudo existe (129 conferências)", **169 scripts, 1.444 testes, 1.444 aprovados, 297.868 asserts**, 219,6 s. **Os números são exatamente os que a C relatou** (169 / 1.444 / 297.868). As linhas `ERROR` e `WARNING` que o GUT imprime nos testes de caminho de erro são as de sempre (68 e 37, as mesmas dos `main` anteriores) |
| **Hash do soak (`run_sim --days 30 --seed 1`)** | **`732907967efd…`** na **minha** execução (`tools/run_sim`, mesma cópia exportada; "Módulos: 0", "Problemas de validação: 0"): **igual ao que a C relatou antes e depois da junção** (o mundo sem módulos não muda) |
| **Oráculo e soaks que existem** | **Passam** dentro do `check_all` verde, com os 9 valores novos e os soaks de 7 dias com 132 NPCs |
| **Pendente** | o **diagnóstico de 30 dias do jogo real com economia e mundo** (mortes, `ContractOffered`, conservação), que escrevi fora do repositório e está rodando: adendo 2 |


## RELATÓRIO — R22 e R23: ramos novos da conversa A (`lw-096h-ids-sem-gasto` `0c8e73a` e `lw-096i-empregado-pelo-work-place` `7e39b80`)        Status: PRONTA PARA REVISÃO (revisão independente, SÓ LEITURA) · 12/11/2026 07:45 (Brasília)

**1. RESUMO.** **Nenhum bloqueio.** Os dois ramos executam a decisão de Arthur de hoje ("a A corrige o R13/R14 e o R18-I1 em ramo agora"). **R22 (096h):** `request_post_contract` passa a validar **antes** de pedir o ID (`ContractBook.check_post`, extraído de `post`, **mesmas falhas e códigos**), então **a recusa nunca gasta ID**; teste novo compara o contador de IDs antes e depois de **7 recusas** e depois de um post que dá certo (gasta exatamente **1**); a frase do `economy.md` ("o ID só se consome ao postar") **agora é verdade**. **R23 (096i):** **empregado é quem tem `work_place_id` preenchido** (o `npc` é o dono), mesmo que a economia não conheça o local (o posto de um povoado sem `service_posts.json`); a utilidade desse emprego vale 0 e **a histerese vale**; 3 testes novos; `npc.md` atualizado com "decisão de Arthur de 12/11/2026". **Nenhum teste existente alterado, nenhum protegido, nenhum hash muda, nenhum dado novo.** Os dois estão **sobre `885615c`**, ainda **sem o `main` novo** (`81ce7f4`, com a LW-097 da C), e **fundem sem conflito de texto** com ele (0 trechos nos dois, conferido por `merge-tree`, só imprime). A 096i está sobre a 096h.

**2. ARQUIVOS CRIADOS / 3. MODIFICADOS.** Nenhum no projeto; só `STATUS-B.md`.

**4. DECISÕES TÉCNICAS (do revisor).** Li os dois diffs **inteiros** (096h: 5 arquivos, 3 `.gd`; 096i: mais 4, 2 `.gd`), `check_post` e a chamada no módulo, `npc_employment.gd` (`_current_employment`), os 5 testes novos **pelos nomes** e o teste do contador **por inteiro**, os salários reais (`data/economy/recipes.json`: **todas as 10 receitas pagam 2 por hora**) e o `SITE = 3` fixo do teste novo da 096i.

**5. TESTES EXECUTADOS.** **NÃO EXECUTADO: o Godot e o `check_all` da A** (não exportei estes ramos). Rodei: contagem DEC-126, leitura e `git grep`, `merge-tree --trivial-merge` (só imprime).

**6. RESULTADOS**
| Item | Resultado |
|---|---|
| **Tamanho (DEC-126)** | 096h: **116 linhas** em 3 `.gd`; 096i: **+122** em 2 `.gd` (e o ramo todo, 5 `.gd`, **+221 −17**): **dentro do teto** |
| **R13-I1/R14-I1 resolvidos?** | **Sim:** `request_post_contract` chama `check_post` **antes** de `_ids.next_id()`; o teste exige `ids.serialize()` **igual** antes e depois de 7 recusas (emissor inexistente, recompensa 0, prazo 0, local desconhecido, entrega com quantidade 0, saldo insuficiente e tipo `vacancy`) e `contract_id` = **o próximo ID que havia**, sem buraco. `post()` ainda chama `check_post` (validação repetida, **inofensiva**) e o resto continua igual |
| **R18-I1 resolvido?** | **Sim para os dados reais:** o guarda de posto de um povoado sem posto na economia **não** vira desempregado; a vaga de um local de produção vale `2 × 8 = 16` para ele (ofício diferente, sem bônus de 10), **abaixo da histerese de 20**, então ele **não** a pega. Conferi que **todas as 10 receitas pagam 2 por hora** e que **nenhuma receita é de `guard` ou `innkeeper`**: com os dados atuais **esse NPC nunca passa dos 20**. O desempregado de verdade (sem `work_place_id`) pega a mesma vaga |
| **Hash, save, camadas** | Nenhum estado novo; nada de `float`, sorteio ou relógio; só `economy` e `npc` pela porta (`economy/api`) |
| **Testes novos (5)** | `test_contract_post_ids` (2: contador de IDs nas recusas e no post; a validação sozinha não muda nada e os códigos são os mesmos) e `test_npc_employment_by_work_place` (3: local desconhecido é emprego e a histerese vale; o desempregado sem `work_place_id` pega a mesma vaga e o guarda fica; **o mesmo local desconhecido TROCA quando o ganho passa da histerese**, 26 contra 20, "é a histerese, não uma exclusão") |

**7. PROBLEMAS ENCONTRADOS (por gravidade)**
**Bloqueante: nenhum.**
**IMPORTANTE**
- **R23-I1. O teste novo `test_npc_employment_by_work_place.gd` tem `SITE = 3` fixo e vai FALHAR quando a A juntar o `main` novo.** Com a LW-097 no `main` os dados reais têm **3 mercados** (IDs 1 a 3), então o local de produção montado à mão passa a ser o **4** (é a mesma troca que a C teve de fazer em `test_site_payroll`, `test_contract_vacancies` e `test_npc_vacancy`: 3 → 4). O teste é **novo da A** (não é "teste existente alterado"), mas o `check_all` da A só fica verde depois de trocar `SITE` para 4 (e o `test_contract_post_ids` **não** tem ID fixo, então não é afetado). **Recomendo** que a A, ao juntar o `main`, troque a constante (ou derive o ID de `peek_site_at`).
**MENOR**
- **R23-M1. A correção é por histerese, não por exclusão.** Quem tem `work_place_id` num local desconhecido **ainda pode trocar** se a vaga passar de 20 (o teste 3 prova); com os salários e ofícios de hoje isso **não ocorre** para guardas e estalajadeiros, mas **mudar um salário para 3 ou pôr uma receita de `guard`** reabre o caso. Só aviso.
- **R23-M2. Doc:** o `npc.md` diz "a utilidade do emprego dele vale 0" para o NPC com local desconhecido; vale registrar quando o `service_posts.json` entrar (depois da LW-097, decisão de Arthur) que **esse caminho deixa de existir** para os 6 postos.
- **R22-M1. O R12-M1 continua** (`post()` abre a custódia antes de transferir; inalcançável porque `check_post` já conferiu o saldo) e o **R15-I1** segue **sem decisão** de Arthur.

**8. RISCOS.** Baixo; o R23-I1 é fácil e previsível. **A pilha da A está sobre `885615c`**: precisa juntar `81ce7f4` antes de empurrar (sem conflito de texto, mas com o ajuste do R23-I1).

**9. PENDÊNCIAS.** *Da A:* R23-I1 ao juntar o `main`. *Que não consegui verificar:* o `check_all` **da A** (e que os 5 testes novos passam); a junção real com o `main` novo.

**ACOMPANHAMENTO.** *Avanço:* as duas correções que Arthur mandou a A fazer **estão em ramo**; falta a A as juntar ao `main` (**só depois** de juntar `81ce7f4`). *Git:* só leitura nos ramos remotos; único commit é o `status-b`; `main` em `81ce7f4`.


### Adendo 2 à auditoria de `81ce7f4`: o diagnóstico independente de 30 dias do jogo real · 12/11/2026 07:45 (Brasília) · **VEREDITO FINAL: SÃ**
Escrevi **fora do repositório** (na pasta temporária da sessão, nenhuma escrita no repositório) um script de diagnóstico que monta o **jogo real** como o `GameApp` (semente **1**, início **345** min, dados reais de `data/`, `EconomySetup` **e** `WorldSetup`, os mesmos módulos) e roda **30 dias** sem jogador, na cópia exportada de `81ce7f4`. Resultado (59 s):
| Critério de Arthur | Resultado | A C relatou |
|---|---|---|
| **NPCs** | **132 no total, 132 vivos** | 132 |
| **Nenhum NPC morrendo** | **0 `NpcDied`** | 0 mortes |
| **Nenhum `ContractOffered` no soak de 30 dias** | **0** (`ContractCompleted` 0, `ContractFailed` 0) | 0 |
| **Folha de pagamento** | **319 `WagesPaid`** | 319 |
| **Conservação do dinheiro e dos bens** | **ok** nos dois; dinheiro criado **19.720** = soma **19.720** | ok |
| **Dinheiro por motivo** | `game_start` **19.720**, `salary` **4.400** (movido), `trade` **15.607** (movido), nada destruído | `game_start` 19.720, `salary` 4.400, `trade` 15.607 |
| **`validate()`** | **economia, `npc` e mundo com 0 problemas** | 0 problemas |
**Os números batem com os da C exatamente** (319, 19.720, 4.400, 15.607), o que confirma, por uma segunda execução **independente**, que o estoque de comida do C em 6.000 mantém todos vivos nos 30 dias. **Conclusão da auditoria:** a entrada da LW-097 no `main` (`81ce7f4`) está **SÃ**: avanço simples, sem tag, sem arquivo protegido, **rotas E economia no jogo real**, **uma** assinatura, `c_market_01` = `market`, 9 valores do oráculo só pelas causas autorizadas (a prova por neutralização é relato dela), `check_all` meu **VERDE** (169 / 1.444 / 297.868), hash do `run_sim` igual, 0 teste removido (**3 dos 9 testes da junção não são só número**, declarados por ela e cobertos pela autorização que ela cita), 0 mortes, 0 `ContractOffered`, conservação ok. **Fica de fora o que não pude verificar:** as autorizações originais, a prova por neutralização, o soak longo (365 dias) e o jogo em tela. *(A previsão do R16-I1 se confirmou: com 3.000 de comida no C, as mortes abriam vagas; a correção para 6.000 é provisória, até a LW-094.)*


## RELATÓRIO — R24 e R25: ramos novos da conversa A (`lw-096j-resumo-dos-postos-e-folha` `00481f1` e `lw-096k-sinalizador-da-comida` `542220b`)        Status: PRONTA PARA REVISÃO (revisão independente, SÓ LEITURA) · 12/11/2026 07:52 (Brasília)

**1. RESUMO.** **Nenhum bloqueio.** A A segue a minha lista de menores, em ramos empilhados (096h → 096i → 096j → 096k, todos sobre `885615c`, **ainda sem o `main` novo**). **R24 (096j):** (a) **R8-M1:** `WagePayer.pay` fica **tudo ou nada** também no caminho de erro (confere o saldo da folha inteira **e** cada transferência antes de mover a primeira) e `can_pay` já recusa o que o `Ledger` recusaria; (b) **R8-M2:** o `debug_summary()` da economia mostra `service_posts` (a quantidade de postos), **só quando há postos** (para não mudar um teste existente que compara o resumo inteiro); (c) **R15-I1:** a **frase** do `economy.md` ("a custódia nunca fica retida") passa a dizer o que o **código** faz ([LIM]: emissor morto, a custódia fica na conta fechada); **o código não mudou e a pergunta de design segue sem decisão de Arthur** (a A a levou ao `STATUS-A`). **R25 (096k):** **R6-I1 completo:** o sinalizador `_food_from_inventory` **sai** do `ConditionProvider`; o `ActionRunner` guarda o resultado da conclusão (`Completion.consumed_from_inventory`) e **nem chama** o gancho do `FoodStub` quando a comida saiu do inventário. **Nenhum hash muda.** **Um teste existente é TROCADO** (R25), com a autorização que a A cita. Os dois fundem com o `main` novo com **1 conflito de texto**, só em documento (`src/sim/economy/README.md`), mas **a 096j traz um teste que vai falhar na junção** (R24-I1).

**2. ARQUIVOS CRIADOS / 3. MODIFICADOS.** Nenhum no projeto; só `STATUS-B.md`.

**4. DECISÕES TÉCNICAS (do revisor).** Li os dois diffs **inteiros**, o `wage_payer.gd` **inteiro**, o trecho do `economy_persistence.gd`, as quatro conferências dos testes da 096j (pelos nomes e o do resumo por inteiro), o diff de `action_runner.gd`, `npc_thinker.gd` e `action_condition_provider.gd` e a **troca** do teste `test_npc_trade.gd`; conferi o teto de saldo do `Ledger` (**`MAX_AMOUNT = 2^53 − 1`**, ou seja, o teto de saldo de quem recebe é inalcançável na prática).

**5. TESTES EXECUTADOS.** **NÃO EXECUTADO: o Godot e o `check_all` da A.** Rodei: contagem DEC-126, leitura, `git grep` e `merge-tree --trivial-merge` (só imprime).

**6. RESULTADOS**
| Item | R24 (096j) | R25 (096k) |
|---|---|---|
| **Tamanho (DEC-126)** | **114 linhas** em 3 `.gd` | **~30 linhas de código** em 3 `.gd` + **12 de teste** (1 teste trocado): **dentro do teto** |
| **Cumpre o que promete?** | **Sim:** `pay` confere saldo e cada transferência **antes** de mover; `can_pay` e `pay` dizem o mesmo; o posto com um trabalhador que o `Ledger` recusaria **para sem pagar os outros e sem publicar `WagesPaid`**; o resumo mostra os postos só com postos; a frase da custódia agora **bate com o código** | **Sim:** um caminho só, **sem estado no provedor** (o sinalizador antigo podia ficar ligado se a conclusão falhasse no meio; agora é uma variável local do `apply_effects`); o gancho do `FoodStub` só roda se a comida **não** saiu do inventário |
| **Teste existente alterado** | **Nenhum** | **1 TROCADO:** `test_npc_trade.gd` · `test_the_food_stub_only_consumes_when_the_food_did_not_come_from_the_inventory`: antes chamava o provedor direto; agora passa pelo **`ActionRunner`** (`begin`/`advance`), e **acrescenta** a verificação de que o inventário ficou vazio depois da segunda refeição (o resto das expectativas continua: `spy.completed` 1 depois da 1ª refeição e 1 depois da 2ª). A autorização é a que a A cita ("Arthur autorizou por escrito em 12/11/2026, item 6 do bloco v11"), **que eu não vi** |
| **Hash e save** | Não mudam (sem local de trabalho nos dados da A; o resumo de depuração não vai ao save nem ao hash) | Não mudam (o oráculo e os soaks não carregam a economia) |
| **Camadas, tempo, aleatoriedade, `float`, dinheiro** | Limpos | Limpos |
| **Testes novos** | `test_wage_payer_atomic` (4): folha que falharia no meio não paga ninguém e `can_pay` já diz não; `pay` confere o saldo sozinho, sem `can_pay`; posto com trabalhador que o `Ledger` recusa para sem pagar nem publicar; resumo só com postos | a troca de teste acima (a A diz que as mutações "gancho sempre", "nunca" e "sinalizador não ligado" são pegas; **não rodei**) |

**7. PROBLEMAS ENCONTRADOS (por gravidade)**
**Bloqueante: nenhum.**
**IMPORTANTE**
- **R24-I1. O teste novo do resumo vai FALHAR quando a A juntar o `main` novo (mesma família do R23-I1).** `test_the_economy_debug_summary_shows_the_posts_only_when_there_are_posts` monta a economia com os **dados reais** e só troca `service_posts`; ele afirma `[owners, production_sites, money_conserved] == [2, 0, true]`. Com a LW-097 no `main` os dados reais têm **3 mercados e 14 locais de produção**: o valor passa a ser **`[17, 14, true]`** (3 + 14 donos, 14 locais). **Recomendo** que a A, ao juntar o `main`, **esvazie `production_sites` no teste** (como a C fez em `test_service_posts`) em vez de trocar números. O `_rig` dos outros 3 testes monta os livros à mão (ID fixos e explícitos) e **não** é afetado.
**MENOR**
- **R24-M1. Rótulo do motivo de parada.** Se um trabalhador estivesse no teto de saldo, o local para por **`NO_FUNDS`** e **ninguém** é pago (a A o diz no commit e no teste); o motivo "falta de fundos" **não descreve** o teto. Como o teto vale **2^53 − 1**, o caso é **inalcançável**; só registro.
- **R24-M2. O R15-I1 segue em aberto de verdade:** a A só corrigiu a **frase**; a **escolha de design** (para onde vai a custódia de emissor morto) continua **sem decisão de Arthur**.
- **R24-M3. A chave `service_posts` só aparece com postos** (para não mudar um teste existente): `debug_summary()` tem chaves **diferentes** conforme o estado; quando o `service_posts.json` entrar (depois da LW-097, decisão de Arthur) o resumo passa a ter a chave sempre, e vale trocar aquele teste **com autorização**.
- **R25-M1. O teste trocado não é "só número"** (muda a forma do teste, acrescenta uma verificação): por isso a A cita a autorização; vale Arthur saber que **este é o único teste existente que a pilha 096h a 096k altera**.
- **R25-M2. O R6-I1 está completo**; o que sobra da lista R6 (M2 a M5) é o backlog que Arthur já decidiu manter.

**Junção (previsão por `merge-tree`, só texto):** 096j e 096k × `main` novo (`81ce7f4`): **1 conflito de texto cada, só em documento** (`src/sim/economy/README.md`: os dois lados acrescentam um parágrafo). A pilha **096h–096k** inteira ainda **não contém o `main` novo**.

**8. RISCOS.** Baixo. O previsível: ao juntar o `main` novo a A precisa ajustar **2 testes novos dela** (R23-I1: `SITE = 3`; R24-I1: `[2, 0, true]`), ambos por IDs e contagens da LW-097.

**9. PENDÊNCIAS.** *Da A:* R23-I1 e R24-I1 ao juntar o `main`. *De Arthur:* R15-I1 e R18-M3 (ainda sem decisão). *Que não consegui verificar:* o `check_all` **da A**; a autorização da troca do teste; que os testes novos passam; a junção real.

**ACOMPANHAMENTO.** *Avanço:* a A tem **4 ramos de ajuste** (096h a 096k) prontos para juntar; **nada** deles no `main` ainda. *Próxima:* o que o vigia trouxer; se a A empurrar para o `main`, audito em até 20 minutos (`check_all` meu + os 2 testes acima). *Git:* só leitura nos ramos remotos; único commit é o `status-b`; `main` em `81ce7f4`.


## BLOCO B v8 — MANHÃ (12/11/2026, 07:58; limite 13:00): autorizações confirmadas e decisões de Arthur registradas        12/11/2026 07:58 (Brasília)

**Declaração do início (AGENTS 2.3).** *Li:* o bloco v8 de Arthur. *Tarefa:* registrar o que ele confirmou e decidiu; revisar o **096l (PostLoader)** agora, só leitura; auditar em até 20 minutos cada entrada nova no `main` (A: conjunto 096h a 096n; depois A: LW-094) com o `check_all` independente e o diagnóstico de 30 dias. *Git:* só commit e push do `status-b`; **nenhum documento do repositório editado**, nada no `main`. *Vigia:* segue armado.

### A. Autorizações que Arthur CONFIRMA por escrito (como dono do produto, 12/11/2026, 07:58)
Na **conversa da C**, em 12/11/2026, Arthur escreveu: **"Autorizo os 7 ajustes"** (os 7 testes antigos da tabela da C, **incluindo os 3 que acrescentam linhas de montagem ou o motivo `salary`**: `test_service_posts`, `test_service_post_queries` e `test_npc_buys_food`), **"Autorizo 6.000"** (subir o estoque provisório de comida do C, `data/food_stub.json`, de 3.000 para 6.000), e também **"Autorizo a troca"** e **"Autorizo a resolução"** (os 2 testes da A e o conflito de `test_economy_production_api.gd`). **A B não as viu (estão no chat da C); registro aqui porque ele mandou.** Com isso, o que a minha auditoria da entrada `81ce7f4` deixou como "não consegui verificar: as autorizações originais" **fica confirmado pelo próprio Arthur**, e os 3 testes que **não eram só número** (o R25-M1 e a tabela da auditoria) **estavam autorizados**.
**A entrada da LW-097 obedeceu ao combinado** (palavras dele): as **4 condições do v11b** valeram **depois** de a C parar na condição (i) com o estoque do C em **3.000** (28 NPCs mortos e 7 `ContractOffered` no jogo de 30 dias) e Arthur autorizar **6.000**. O meu diagnóstico independente de 30 dias confirmou o resultado final (132 vivos, 0 mortes, 0 `ContractOffered`).

### B. Decisões de Arthur (12/11, 07:58) — **não vão para `DECISIONS.md` agora**
| Ponto | Decisão |
|---|---|
| **(a) R15-I1: custódia de emissor morto** | **Opção B:** a recompensa **volta ao mercado do povoado do contrato**; se o **povoado for desconhecido, fica retida [LIM]** (como hoje). *Nota da B, para a revisão quando houver código:* o `labor` tem `place_id` (que dá o povoado), mas o `delivery` tem `destination_id` (um dono, que pode ser NPC ou mercado): **a regra de qual é "o povoado do contrato" no `delivery` precisa estar no código e no teste** |
| **(b) Rumo ao `main`** | A **A vai tentar levar ao `main`, por antecipação e sob condições**, **primeiro o conjunto 096h a 096n** e **depois a LW-094** (fim do `FoodStub`). Condições: `check_all` **verde**, oráculo e `run_sim` **iguais**, **30 dias com 132 vivos, 0 mortes, 0 `ContractOffered`, conservação** |

### C. O que a B vai conferir (pedido dele)
1. **096l (PostLoader):** revisar **agora**, só leitura (revisão R26, abaixo).
2. **Cada entrada nova no `main`** (096h a 096n; depois LW-094), **em até 20 minutos**: o que mudou (arquivos, testes antigos alterados, protegidos, tags, avanço simples), a junção (rotas e economia no jogo real, uma assinatura), oráculo e soak só pelas causas autorizadas, e o diagnóstico independente de 30 dias.
3. **Atenção especial:** (i) o 096l ainda sem revisão; (ii) **o jogo real depois do 096i e 096j: nenhum NPC de posto deve deixar o posto e nenhum NPC deve morrer** (o diagnóstico vai olhar também o `work_place_id` de cada NPC no começo e no fim); (iii) **na LW-094: se o 3º povoado (C) passa fome sem o estoque provisório** (mercado do C com só 200 de pão e 10 de grão e nenhum lavrador) **e se a A parou como Arthur mandou**.


## RELATÓRIO — R26: ramo novo da conversa A (`lw-096l-post-loader`, `e6bc3ec`, LW-095: o carregador dos postos de serviço)        Status: PRONTA PARA REVISÃO (revisão independente, SÓ LEITURA) · 12/11/2026 09:36 (Brasília)

**1. RESUMO.** **Nenhum bloqueio.** O `PostLoader` (`economy/posts/`) lê e valida `data/economy/service_posts.json` pelo módulo `data` (`settlement_id`, `place_id` e `occupation_id` não vazios; `workers_wanted` 1 ou mais; `wage_per_hour` 0 ou mais; **um posto por local**; falha `ECON_DATA_INVALID` com arquivo, item e campo). **O arquivo é OPCIONAL: sem ele, lista vazia**, então `data/economy` de hoje e o jogo ficam **exatamente como estão**. O `EconomySetup` leva os postos às definições e **recusa o local que tem posto e local de produção**. **Nenhum dado novo** (cumpre a decisão de Arthur: "o `service_posts.json` só entra depois da LW-097 no `main`; o `PostLoader` antes, só em código"), **nenhum teste existente alterado, nenhum protegido, nenhum hash muda.** Empilhado na 096k (`542220b`), 1 commit, **ainda sobre `885615c`**. O `status-a` (07:52) diz que os 5 ramos 096h a 096l têm `check_all` verde (a ponta: 166 scripts, 1.405 testes), oráculo e `run_sim` iguais e **nada no `main`**; confere com o que revi.

**2. ARQUIVOS CRIADOS / 3. MODIFICADOS.** Nenhum no projeto; só `STATUS-B.md`.

**4. DECISÕES TÉCNICAS (do revisor).** Li o diff **inteiro** (7 arquivos: 3 `.gd`, 2 `.uid`, 2 documentos), `post_loader.gd` **inteiro**, o diff do `economy_setup.gd` e o teste novo **inteiro** (5 testes). Conferi se o `tools/check_content_ids` e o `ServicePostBook` cobrem as referências dos postos.

**5. TESTES EXECUTADOS.** **NÃO EXECUTADO: o Godot e o `check_all` da A** (aceito o relato dela). Rodei: contagem DEC-126, `git grep`, `merge-tree --trivial-merge` (só imprime).

**6. RESULTADOS**
| Item | Resultado |
|---|---|
| **Tamanho (DEC-126)** | **210 linhas** (+210 −1) em **3 `.gd`** (80 do carregador, 16 do `EconomySetup`, 114 de teste): **dentro do teto** |
| **Cumpre o combinado?** | **Sim:** só código; arquivo opcional; mensagens com arquivo, item e campo; recusa de local duplicado em **dois** níveis (dois postos no mesmo local, e posto + local de produção) |
| **Hash e save** | Não mudam (sem arquivo, as definições ficam sem posto) |
| **Camadas e regras** | Usa só o módulo `data` e as classes da economia; sem `float`, sorteio ou relógio; nenhum autoload |
| **Testes novos (5)** | sem o arquivo não há posto e o setup real carrega; linhas válidas viram `PostDef` na ordem do arquivo (tabela vazia vale; salário 0 vale); 6 casos inválidos apontam arquivo, item e campo + local repetido; arquivo em disco é lido e o setup leva os postos às definições (e um inválido derruba o setup com a mensagem); um local serve a um posto **ou** a um local de produção, nunca aos dois |

**7. PROBLEMAS ENCONTRADOS (por gravidade)**
**Bloqueante: nenhum.**
**IMPORTANTE**
- **R26-I1. O teste novo `test_without_the_file_there_are_no_posts_and_the_real_economy_setup_still_loads` vai quebrar no dia em que o `service_posts.json` entrar.** Ele afirma que o arquivo **não existe** em `data/economy` e que `definitions.service_posts.size() == 0`. A decisão de Arthur é que o arquivo entre **depois da LW-097 no `main`** (que **já está** no `main` desde 07:28) e "com o aviso dele por escrito". Quando entrar, esse teste falha e precisa ser reescrito: se o 096l já estiver no `main` nesse dia, **será a alteração de um teste existente e pedirá autorização dele de novo.** **Recomendo** (a) a A reescrever o caso agora para usar uma **pasta temporária sem o arquivo** (em vez do `data/economy` real), ou (b) Arthur incluir essa troca na mesma autorização que libera o arquivo.
**MENOR**
- **R26-M1. As referências do arquivo não são conferidas por nada.** `settlement_id`, `place_id` e `occupation_id` dos postos **não** estão na tabela `REFERENCES` do `tools/check_content_ids` (só as colunas da economia e de `population.json`), e o `ServicePostBook` só recusa local repetido: **um erro de digitação nas 6 linhas passaria até o jogo**. A ficha (`fase-4/dados.md`) manda que a mudança no verificador seja **da tarefa que cria o arquivo**: então **quando o arquivo entrar**, o verificador (ou um teste do arquivo real contra `places.json`, `settlements.json` e `occupations.json`) tem de entrar junto.
- **R26-M2. Primeiro `FileAccess` direto em `src/sim`.** `PostLoader.load_dir` chama `FileAccess.file_exists` (para o arquivo opcional); os outros carregadores deixam a leitura ao módulo `data`. O `check_architecture` não reclamou (segundo a A), mas o lugar natural seria o `EconomySetup` (camada do app, que faz entrada e saída) ou o módulo `data`.
- **R26-M3. O teste escreve numa cópia de `data/economy` em `res://.godot/`** (cache ignorado pelo Git, apagada no `after_each`), enquanto os outros 4 testes que precisam de pasta usam `DirAccess.create_temp`. Funciona em desenvolvimento e sem janela; só destoa.

**Junção (previsão por `merge-tree`, só texto):** a ponta `e6bc3ec` × `main` novo (`81ce7f4`): **1 conflito de texto, só em documento** (`src/sim/economy/README.md`). Dos ajustes que a A deve fazer ao juntar o `main` (R23-I1 e R24-I1), **o 096l não acrescenta nenhum** (nenhum ID fixo nos testes novos).

**8. RISCOS.** Baixo. O R26-I1 é de **processo** (autorização futura), não de código.

**9. PENDÊNCIAS.** *Da A:* R26-I1 (reescrever o caso agora ou pedir a autorização junto com a liberação do arquivo), R26-M1 quando o arquivo entrar, e as duas correções de teste ao juntar o `main` (R23-I1, R24-I1). *De Arthur:* o aviso por escrito para o `service_posts.json` (a condição "depois da LW-097 no `main`" **já vale**). *Que não consegui verificar:* o `check_all` **da A**; que os 5 testes novos passam.

**ACOMPANHAMENTO.** *Avanço:* a A tem **5 ramos de ajuste (096h a 096l)** prontos e, segundo Arthur, vai levar ao `main` o conjunto **096h a 096n** (ainda **não existem** 096m e 096n no GitHub) e depois a LW-094. *Próxima:* o que o vigia trouxer; **auditar em até 20 minutos** cada entrada no `main`, com `check_all` e diagnóstico de 30 dias meus (inclusive o `work_place_id` de cada NPC no começo e no fim, e a fome do povoado C na LW-094). *Git:* só leitura nos ramos remotos; único commit é o `status-b`; `main` em `81ce7f4`.


## VERIFICAÇÃO ANTECIPADA — a pilha 096h a 096l da A (ainda fora do `main`) montada SOBRE o `main` novo (`81ce7f4`), em cópia temporária        12/11/2026 09:43 (Brasília) · pedido de Arthur: "atenção especial (ii): o jogo real depois do 096i e 096j"

**Método (nenhuma escrita no repositório).** Na pasta temporária da sessão: `git archive` do `origin/main` (`81ce7f4`) + `git apply` do diff da pilha da A (`885615c` → ponta do 096l, 905 linhas de patch; deixei de fora só os **2 documentos** que conflitam em texto, `src/sim/economy/README.md` e `docs/backlog.md`). Isto **não é a junção que a A fará** (ela pode mudar testes e acrescentar o 096m e o 096n); é a **previsão do que o `check_all` dela vai encontrar**.

**Resultado do `check_all` (VERMELHO, e era o esperado):** arquitetura OK, dados OK ("IDS DE CONTEÚDO: tudo existe, 129 conferências"), **173 scripts, 1.458 testes, 1.454 aprovados, 4 falhos**, asserts 298.048 de 298.052, 218,6 s. **Os 4 falhos são exatamente os que eu previra (R23-I1 e R24-I1):**
| Teste (novo da A) | Falhas | Causa | O que a A faz |
|---|---|---|---|
| `tests/unit/test_npc_employment_by_work_place.gd` (R23-I1) | **3 de 3** | `SITE = 3` fixo; com os 3 mercados da LW-097 o local de produção montado à mão é o **4** (`[] != [5]`, `[false, "a_work_01"] != [true, "a_work_01"]` ×2) | trocar `SITE` para 4 (ou derivar o ID) |
| `tests/unit/test_wage_payer_atomic.gd` · `…debug_summary_shows_the_posts_only_when_there_are_posts` (R24-I1) | **1 de 4** | o teste afirma `[owners, production_sites, money_conserved] == [2, 0, true]` e a economia real dá **`[17, 14, true]`** (3 mercados + 14 locais), **o mesmo valor que eu havia previsto** | esvaziar `production_sites` no teste (como a C fez em `test_service_posts`) |
**Os outros 1.454 testes passam**, inclusive o oráculo, os soaks de 7 dias e os 9 valores do oráculo; **nenhum outro teste novo ou antigo quebra**. Com as duas correções de teste **dela** (testes **novos** dela, não "existentes alterados") a junção deve ficar **verde**.

**Diagnóstico independente de 30 dias do jogo real (mesma cópia, semente 1, início 345; agora também comparando o `work_place_id` de CADA NPC no começo e no fim):**
| Critério de Arthur | Resultado |
|---|---|
| NPCs | **132 no total, 132 vivos** |
| **Nenhum NPC morrendo** | **0 `NpcDied`** |
| **Nenhum `ContractOffered`** | **0** (também 0 `ContractCompleted` e 0 `ContractFailed`) |
| **Nenhum NPC de posto deixa o posto** | **`work_place_id` mudou em 0 NPC; dos 30 NPCs de posto (guardas e estalajadeiros), 0 deixaram o posto** |
| Folha e dinheiro | **319 `WagesPaid`**; criado 19.720 = soma 19.720; `game_start` 19.720, `salary` 4.400, `trade` 15.607: **iguais ao `main`** |
| Conservação e `validate()` | dinheiro e bens **ok**; economia, `npc` e mundo com **0 problemas** |
| Hash do estado | `7e9618536281`, **igual** ao do mesmo diagnóstico no `main` `81ce7f4`: **a pilha não muda o jogo real** (sem posto nos dados: "postos nas definições da economia: 0") |
**Limite desta prova:** em 30 dias **ninguém morre**, então **nunca nasce vaga** e o caminho do R18-I1 (o NPC de posto que **não** pega a vaga) **não é exercitado no jogo real**: só os testes da própria 096i o exercitam. Um experimento com **uma morte forçada** num local de produção é o passo seguinte (adendo, se rodar a tempo).


## AUDITORIA DE ENTRADA NO `main` — conversa C, `4db060f` (LW-118, partes 118a a 118d e a junção)        Veredito parcial: **SÃ NA ESTRUTURA; `check_all`, `run_sim` e diagnóstico independentes em execução (adendo)** · 12/11/2026 09:44 (Brasília)

**FALHA MINHA, dita antes de tudo: esta auditoria saiu FORA do prazo de 20 minutos.** Os commits da C são das **07:58:49**; só vi a entrada às **09:35**, e comecei a auditar às **09:43:36** (cerca de 1h45 depois). **O vigia parou de bater às 07:48** (o último batimento gravado é `12/11 07:48:59`; a máquina deve ter ficado parada, e o processo seguiu "rodando" sem consultar o GitHub). **Eu escrevi "vigia armado" às 07:58 sem conferir o batimento**: estava errado de 07:48 até 09:35, quando percebi, desliguei o antigo e religuei um novo (09:36). **Nenhuma outra entrada se perdeu** (o `main` só andou esta vez; as 5 linhas de ramos da A e o 096l eu revi à mão).

| Pergunta de Arthur | Resultado (conferido por mim) |
|---|---|
| **Avanço simples?** | **Sim:** `81ce7f4` é ancestral de `4db060f`. As 3 tags remotas **iguais**; nenhum arquivo apagado (29 novos, 11 modificados) |
| **O que entrou** | 6 commits: `6eb1ba0` (118a), `5f352a7` (118b), `4e8ce98` (118c), `15b95d4` (118d), **o merge `f2b415b`** (junção com `81ce7f4`) e `4db060f` (linha de status); **40 arquivos, +1.363 −11**: `src` 22 (+645 −6), `tests` 10 (+689 −0), `data` 6 (+26 −4), `docs` 2, `tools` 0 |
| **Arquivos protegidos** | **Nenhum tocado.** `docs/ROADMAP_STATUS.md`: **só 1 parágrafo acrescentado**, nenhuma contagem mudou |
| **Testes antigos alterados** | **Nenhum** (só **5 testes novos**: `test_cultures`, `test_provinces`, `test_provinces_data`, `test_province_settlements`, `test_world_province_queries`; **0 linha removida em `tests/`**) |
| **Oráculo e soak** | **Nenhum arquivo do oráculo nem dos soaks foi tocado** (diff vazio). A LW-118 é conteúdo, fora do save e do `state_hash` |
| **Junção sã** | **Sim.** O merge `f2b415b` resolveu à mão só **4 arquivos**: `data/world/README.md`, `docs/modules/world.md`, `src/sim/world/README.md` (documentos) e **`src/app/game_modules.gd`** (código): ficou `WorldModule.new(world_setup.routes, world_setup.is_development_build, world_setup.provinces, world_setup.cultures)`, **coerente** com o `WorldSetup` da 118d. A C diz "3 conflitos, todos de documento"; o 4º é a combinação automática em `game_modules.gd` e está certa |
| **Rotas E economia no jogo real; uma assinatura; `c_market_01`** | `src/app` só mudou `game_modules.gd` e `world_setup.gd` (a 118d); `start_new_game(…, economy_setup, world_setup)` e `register(…, economy_setup, world_setup)` seguem com **uma assinatura**; `c_market_01` = **`market`**; o `WorldSetup` agora **lê e confere** províncias, adjacência e culturas e o jogo **não inicia** se os dados não batem (R20-M1 resolvido) |
| **Dados** | `settlements.json` (as colunas `province_id` e `culture_id`), `cultures.json`, `provinces.json`, `province_adjacency.json` novos, e as **6 chaves** de `data/text/pt_br.json` (decisão de Arthur: a cobertura por teste delas vai para o backlog da C) |
| **Tamanho da 118b (526 linhas)** | **Exceção única aceita por Arthur** (12/11, 07:10) |
| **Autorização** | A C cita **"Aprovo a LW-118" e "Junte ao main" (12/11/2026)**, escritos por Arthur **na conversa dela** (`status-c`, 09:39); **eu não as vi** |
| **`check_all` da C (relato)** | VERDE: 174 scripts, 1.490 testes, 298.360 asserts, "nenhum hash mudou" |
| **`check_all` independente (meu)** | **em execução** numa cópia exportada de `4db060f` (`git archive`, nenhuma escrita no repositório), iniciado 09:43:xx; o resultado, o `run_sim` e o diagnóstico de 30 dias vão no adendo |

**O que NÃO consegui verificar (até aqui):** as autorizações originais; o resultado do `check_all` e do diagnóstico (adendo).


### Adendo à auditoria de `4db060f` (LW-118): `check_all`, `run_sim` e diagnóstico independentes · 12/11/2026 09:50 (Brasília) · **VEREDITO FINAL: SÃ (fora do prazo, por falha do meu vigia)**
| Item | Resultado |
|---|---|
| **`check_all` independente (meu)** | **VERDE.** Cópia exportada de `4db060f` (`git archive`, nenhuma escrita no repositório), código 0: arquitetura e dados OK ("IDS DE CONTEÚDO: tudo existe, 129 conferências"), **174 scripts, 1.490 testes, 1.490 aprovados, 298.360 asserts**, 231,3 s. **Exatamente os números da C** (174 / 1.490 / 298.360); os 46 testes a mais que o `main` anterior (1.444) são os 5 arquivos novos da LW-118. `ERROR`/`WARNING` do GUT nos testes de caminho de erro: 68 e 37, **os mesmos** de sempre |
| **`run_sim --days 30 --seed 1`** | **`732907967efd…`**: **igual** ao dos `main` anteriores ("Módulos: 0", 0 problemas) |
| **Diagnóstico de 30 dias do jogo real** (`WorldSetup` agora lê províncias, adjacência e culturas) | **132 vivos, 0 mortes, 0 `ContractOffered`, 319 `WagesPaid`**, `work_place_id` **mudou em 0 NPC** (dos 30 de posto, 0 saíram), conservação do dinheiro e dos bens **ok**, dinheiro por motivo **igual** (`game_start` 19.720, `salary` 4.400, `trade` 15.607), `validate()` da economia, do `npc` e do mundo **vazios**, hash **`7e9618536281`: igual ao do `main` `81ce7f4`**: **a LW-118 não muda o jogo real** (é conteúdo, fora do save e do hash, como a C disse) |
**Conclusão:** a entrada da LW-118 no `main` está **SÃ**: avanço simples, sem tag, sem arquivo protegido, **0 teste antigo alterado**, oráculo e soak intocados, uma assinatura, `c_market_01` = `market`, `check_all` meu verde com os mesmos números da C, hash do `run_sim` igual, e o jogo real de 30 dias **idêntico** ao do `main` anterior. **Fica de fora o que não pude verificar:** as autorizações "Aprovo a LW-118" e "Junte ao main" (estão no chat da C), e o soak longo. **Lembrete do que segue aberto:** a pilha 096h a 096l da A (e o 096m e o 096n) **ainda não está no `main`**; ela vai precisar dos 2 ajustes de teste (R23-I1 e R24-I1) ao juntar o `main` novo, que **agora já tem a LW-118 também** (o meu `merge-tree` anterior foi sobre `81ce7f4`; refaço sobre `4db060f` quando ela empurrar).


## RELATÓRIO — R27: ramo novo da conversa A (`lw-096m-junta-com-o-main`, `4116294`: a junção com o `main` e o conserto dos 2 testes dela) e verificação do `main` ATUAL mais as mudanças da A        Status: PRONTA PARA REVISÃO (revisão independente, SÓ LEITURA) · 12/11/2026 10:06 (Brasília)

**1. RESUMO.** **Nenhum bloqueio.** O 096m é a pilha **096h a 096l** + a **junção com o `main` `81ce7f4`** (a LW-097 da C; commit `9fd706a`, conflito só em `src/sim/economy/README.md`, mantidos os dois lados) + **o conserto dos 2 testes novos dela** que a LW-097 quebrava (`4116294`): **R23-I1** (`test_npc_employment_by_work_place.gd` passa a **ler o ID do local** por `peek_site_at(SITE_PLACE).workplace_id`, em vez de fixar `SITE = 3`) e **R24-I1** (`test_wage_payer_atomic.gd` esvazia `production_sites` e espera `MARKETS = 3` donos). **Os dois achados importantes meus ficam resolvidos.** Ponto de atenção: o ramo contém `81ce7f4`, **mas não o `main` atual `4db060f`** (a LW-118 da C, de 07:58): ela precisará juntar de novo antes do avanço simples (o meu `merge-tree` dá **0 conflitos de texto**). O `status-a` (10:05): item 1 pronto; **item 2 (custódia do emissor morto, opção B de Arthur) implementado no ramo local `lw-096n`, PARADO e NÃO enviado** por precisar da autorização escrita de Arthur para trocar **1 teste existente** (ver 7); itens 3 (entrada no `main`) e 4 (LW-094) **não iniciados**.

**2. ARQUIVOS CRIADOS / 3. MODIFICADOS.** Nenhum no projeto; só `STATUS-B.md`.

**4. DECISÕES TÉCNICAS (do revisor).** Li o diff do conserto (`4116294`) **inteiro**, a resolução do merge, e o diff da A sobre o `main` que ela juntou (`81ce7f4` → 096m: **24 arquivos, +577 −42**, 15 `.gd` +563 −37). **Montei na pasta temporária o `main` ATUAL (`4db060f`) com as mudanças da A por cima** (`git archive` + `git apply` do diff dela, sem os 5 documentos que conflitam; **nenhuma escrita no repositório**) e rodei o `check_all`, o `run_sim` e dois diagnósticos de 30 dias do jogo real.

**5. TESTES EXECUTADOS (meus, na cópia temporária `4db060f` + A até 096m)**
| Comando | Resultado |
|---|---|
| `tools/check_all` | **VERDE:** **178 scripts, 1.504 testes, 1.504 aprovados, 298.544 asserts**, 226,0 s, "IDS DE CONTEÚDO: tudo existe (129 conferências)"; 0 falha. (178 = os 173 do 096m da A + os 5 testes novos da LW-118; 1.504 = 1.458 + 46: **bate com o que a A relatou, 173 / 1.458**) |
| `tools/run_sim --days 30 --seed 1` | `732907967efd…`, **igual** ao do `main` ("Módulos: 0", 0 problemas) |
| **Diagnóstico de 30 dias do jogo real** | **132 vivos, 0 mortes, 0 `ContractOffered`, 319 `WagesPaid`**, `work_place_id` mudou em **0** NPC (dos 30 de posto, **0** saíram), conservação do dinheiro e dos bens **ok**, `validate()` da economia, do `npc` e do mundo **vazios**, hash **`7e9618536281`** (**igual** ao do `main`): **a pilha não muda o jogo real** |
| **Experimento de morte forçada** (o que o diagnóstico acima **não** exercita) | Matei o **NPC 30, lavrador de `a_work_01`**, no começo e rodei 30 dias: **1 `NpcDied`, 1 `ContractOffered` (a vaga), 0 `ContractCompleted`; `work_place_id` mudou em 0 NPC e dos 30 de posto, 0 deixaram o posto**; conservação ok; `validate()` vazio; hash `42c6e0612e2e` (outro, como esperado depois de uma morte). **O caminho do R18-I1 está provado no jogo real: a vaga nasce e os guardas e estalajadeiros NÃO a pegam** |

**6. RESULTADOS.** O oráculo e os soaks **não foram tocados** (diff vazio contra o `main`; o `test_npc_split_oracle.gd` é idêntico); `data/`, `tools/` e `project.godot` **intocados**; `src/app` só em `economy_setup.gd` (a ligação do `PostLoader`). **Único teste existente alterado pela pilha: `test_npc_trade.gd`** (a troca autorizada por Arthur no item 6 do v11, R25-M1). Sem arquivo protegido.

**7. PROBLEMAS E OBSERVAÇÕES**
- **Bloqueante e importante: nenhum.** **R23-I1 e R24-I1: RESOLVIDOS** (a previsão e a verificação antecipada de 09:43 se confirmaram: eram exatamente esses 4 testes).
- **R27-M1. O ramo está atrasado em uma entrada:** contém `81ce7f4`, não `4db060f`; precisa de uma segunda junção (sem conflito de texto previsto). Os 5 testes e arquivos da LW-118 **não** interagem com a pilha (confirmado: o `check_all` da composição é verde).
- **R27-M2. A vaga do experimento fica ABERTA por 30 dias:** nenhum NPC empregado tem utilidade acima da histerese de 20 (todas as receitas pagam 2 por hora), e **não há desempregados nem nascimentos**; então um local que perde gente **fica com a equipe menor para sempre**. É o desenho da DEC-169 (o emprego só termina por morte ou por outra vaga), mas vale Arthur saber **antes da LW-094/098**: a vaga, na prática, **não se preenche** com os dados de hoje.
- **R27-M3. O item 2 da A (custódia, opção B) parou** por precisar de autorização para trocar **só** `tests/unit/test_contract_expiry.gd:113` (`test_a_dead_issuer_gets_nothing_back_and_the_reward_stays_in_the_contract_account`, que fixa o comportamento **antigo**): o código da opção B (`ContractRefundMarket`; `labor` = povoado do local de trabalho; `delivery` = povoado do destino; destino NPC ou mercado fechado: retida [LIM]) está no ramo **local** `23b7c8c`, **não enviado**; ela **recomenda autorizar** (o teste novo é mais forte). **Resposta a uma das perguntas que eu deixara:** a regra do "povoado do contrato" no `delivery` **está definida** (o povoado do destino). **A decisão é de Arthur; a B não repassa.** Enquanto não houver, **os itens 3 e 4 da A (entrada do conjunto 096h a 096n e LW-094) seguem parados**, e **nada novo entra no `main`**.

**8. RISCOS.** Baixo. O que pesa é de processo: a A está parada esperando uma autorização; a pilha **096h a 096m** já está verificada por mim sobre o `main` atual.

**9. PENDÊNCIAS.** *De Arthur:* a autorização do teste `test_contract_expiry.gd:113` (item 2 da A). *Da A:* juntar `4db060f` (sem conflito previsto) e enviar o 096n quando houver autorização. *Que não consegui verificar:* o `check_all` **da A** para o 096n (não existe no GitHub); a autorização.

**ACOMPANHAMENTO.** *Avanço:* a A tem **096h a 096m** prontos (verificados) e o **096n parado**; a C parou (LW-118 no `main`). *Próxima:* o que o vigia trouxer (vigia religado às 09:57, batimento a conferir a cada turno). *Git:* só leitura nos ramos remotos; único commit é o `status-b`; `main` em `4db060f`.


## DECISÃO DE ARTHUR REGISTRADA — troca do teste `test_contract_expiry.gd:113` (item 2 da A, custódia do emissor morto)        12/11/2026 10:38 (Brasília)

**A decisão (palavras de Arthur, pelo painel do chat):** à pergunta "Autoriza a A a trocar só `test_contract_expiry.gd:113` (custódia, opção B)?", Arthur respondeu **"Autorizo a troca"**.

**O que isto cobre (segundo o pedido que a A fez no `status-a`, 10:05; entendimento da B, não palavras de Arthur):** trocar **só** esse teste existente, `test_a_dead_issuer_gets_nothing_back_and_the_reward_stays_in_the_contract_account`, por `test_a_dead_issuer_custody_goes_to_the_market_of_the_contract_settlement`: mesmo cenário e mesmas conferências de conservação e de `validate()`, a primeira asserção passa a esperar `["expired", 0, 1]` e **acrescenta** a do mercado do povoado A (saldo antes + 25). Nenhum outro teste existente.

**O que este registro NÃO faz:** **não** é uma instrução da B à A (ela recebe as decisões direto de Arthur; a B não repassa) e **não** autoriza mais nada além desse teste (a entrada do conjunto 096h a 096n no `main` e a LW-094 já seguem as condições do bloco v8 dele).

**O que a B fará quando a A empurrar:** revisar o 096n (a opção B: `ContractRefundMarket`, regra do povoado do contrato no `labor` e no `delivery`, destino NPC e mercado fechado retidos [LIM], `validate()`), conferir que **só esse teste** foi trocado e que ele ficou **mais forte** (as asserções antigas mantidas mais a do mercado), e, se houver entrada no `main`, auditar em até 20 minutos com o `check_all` e o diagnóstico de 30 dias.

**Estado às 10:38:** `main` em `4db060f`; **nada novo no GitHub** desde as 09:57; vigia com batimento das 10:37:49.


## RELATÓRIO — R28: ramo novo da conversa A (`lw-096n-custodia-do-emissor-morto`, `517b874`: a custódia do emissor morto, opção B de Arthur)        Status: PRONTA PARA REVISÃO (revisão independente, SÓ LEITURA) · 12/11/2026 10:57 (Brasília)

**1. RESUMO.** **Nenhum bloqueio.** O 096n implementa a **opção B** que Arthur decidiu (12/11, 07:58): se o **emissor** de um contrato que **vence** está **morto**, a custódia vai para a **conta do mercado do povoado do contrato** (pelo mesmo `Ledger.transfer` com o motivo `contract_refund`: **sem evento novo, sem motivo novo, sem queimar nada**); se o **povoado é desconhecido** (destino que é um NPC) ou o mercado está fechado, ela **continua retida [LIM]**. **Dois commits** sobre o 096m: `23b7c8c` (o código, 09:54) e `517b874` (**a troca do teste existente**, 10:38:28, **depois do "Autorizo a troca" de Arthur**). **O único teste existente alterado é `test_contract_expiry.gd`**, como autorizado. O ramo ainda tem a base `81ce7f4` (sem a LW-118, `4db060f`).

**2. ARQUIVOS CRIADOS / 3. MODIFICADOS.** Nenhum no projeto; só `STATUS-B.md`.

**4. DECISÕES TÉCNICAS (do revisor).** Li o diff de `src` **inteiro** (`contract_book.gd`, o novo `contract_refund_market.gd` de 47 linhas, `economy_persistence.gd`, `economy_state.gd`), a troca do teste **linha a linha** e os **nomes dos 8 testes novos**; montei na pasta temporária o `main` **atual** (`4db060f`) com as mudanças da A por cima (como na R27) e rodei o `check_all`, o `run_sim` e o diagnóstico de 30 dias.

**5. TESTES EXECUTADOS (meus, cópia temporária `4db060f` + A até 096n)**
| Comando | Resultado |
|---|---|
| `tools/check_all` | **VERDE:** **179 scripts, 1.512 testes, 1.512 aprovados, 298.629 asserts**, 221,3 s, "IDS DE CONTEÚDO: tudo existe (129 conferências)"; 0 falha. (179 = 178 da R27 + o arquivo novo; 1.512 = 1.504 + os **8 testes novos**) |
| `tools/run_sim --days 30 --seed 1` | `732907967efd…`, **igual** ao do `main` |
| **Diagnóstico de 30 dias do jogo real** | **132 vivos, 0 mortes, 0 `ContractOffered`, 319 `WagesPaid`**, 0 NPC mudou de `work_place_id`, conservação ok, `validate()` vazios, hash `7e9618536281` (**igual** ao do `main`): o 096n **não muda o jogo real** (não há contrato nos dados) |

**6. RESULTADOS**
| Item | Resultado |
|---|---|
| **Cumpre a opção B?** | **Sim:** `ContractBook.expire` escolhe o recebedor: **o emissor, se aberto; senão o mercado do povoado do contrato (`ContractRefundMarket`); senão ninguém (retido)**. No `labor` o povoado é o do **local de trabalho** (local de produção ou posto); no `delivery` é o do **destino** (o próprio mercado ou um local de produção); **destino NPC = sem povoado = retido [LIM]** |
| **A troca do teste existente** | `test_a_dead_issuer_gets_nothing_back_and_the_reward_stays_in_the_contract_account` → **`test_a_dead_issuer_custody_goes_to_the_market_of_the_contract_settlement`** (**o nome que a A pediu**). **Mesmo cenário**, e **todas as conferências antigas ficam** (estado `expired`, evento `ContractFailed` 1, conservação do dinheiro, `validate()` vazio); a primeira asserção passa a esperar custódia **0** (antes 25) e **acrescenta** que o **mercado do povoado A recebeu +25**. **O teste ficou mais forte, não mais fraco.** Nenhum outro teste existente mudou (conferi o diff de `tests/` contra o 096m) |
| **`validate()`** | Só tolera custódia retida **quando o povoado é desconhecido** (`_refund_market_of(state) == NO_ID`) **e** o saldo é a recompensa inteira; um save adulterado com custódia retida de povoado **conhecido** é **acusado** (teste) |
| **Compatibilidade** | `ContractBook.new(..., market_book = null)`: o parâmetro novo é **opcional**; `EconomyState.create` e `EconomyPersistence.load_into` passam os mercados; os testes que constroem o livro à mão seguem compilando |
| **Testes novos (8)** | emissor vivo recebe como antes e os mercados não se mexem; emissor morto com `labor` (mercado do povoado do local de trabalho), com `delivery` ao mercado, com `delivery` a um local de produção; contrato **aceito** que vence; `delivery` a um NPC **retém** (povoado desconhecido); a devolução ao mercado **sobrevive ao save**; `validate()` acusa retenção de povoado conhecido. Usam povoados e locais **reais** de `A` e `B` (`b_work_01`, `b_work_02`), sem ID de dono ou de local fixo (só os de NPC, 100 a 102) |
| **Tamanho (DEC-126)** | **315 linhas** (+300 −15) em **6 `.gd`** (225 de teste novo): **acima do teto de 300, dentro da tolerância de 450** |
| **Camadas, tempo, aleatoriedade, `float`, dinheiro** | Limpos; dinheiro só pelo `Ledger`; sem novo estado salvo (o recebedor se calcula na hora) |
| **Docs** | `economy.md` (2 passagens): a frase da custódia e o [LIM] agora descrevem a opção B (a pergunta R15-I1 **fecha**) |

**7. PROBLEMAS E OBSERVAÇÕES**
- **Bloqueante e importante: nenhum.** **R15-I1: RESOLVIDO** no código e nos documentos (decisão de Arthur, opção B), **fora do `DECISIONS.md`** como ele mandou.
- **R28-M1. "Povoado do contrato" no `delivery` é o do DESTINO, não o do emissor.** É a regra que a A definiu (e que eu pedira que ficasse explícita); com ela, um emissor morto do povoado A cujo `delivery` ia para o mercado B **paga o mercado de B**. Coerente com "o mercado do povoado do contrato", mas Arthur pode preferir o do emissor (que o `economy` não conhece: o NPC não tem povoado na economia). Só registro.
- **R28-M2. O R27-M1 continua:** o ramo está atrasado em uma entrada (`4db060f`); a A precisa juntar de novo (0 conflitos de texto previstos; a minha composição `4db060f` + A até 096n é **verde**).
- **R28-M3. Não rodei as "mutações" que a A relata** (8 de 9 pegas; a que sobra é a guarda de mercado fechado, inalcançável pela API); aceito o relato.
- **R28-M4. A vaga que fica aberta (R27-M2)** segue sendo observação para Arthur antes da LW-094/098.

**8. RISCOS.** Baixo.

**9. PENDÊNCIAS.** *Da A:* o item 3 (levar o conjunto 096h a 096n ao `main`, por antecipação e sob as condições do v8) e o item 4 (LW-094, **só depois**); antes, **juntar `4db060f`**. *Que não consegui verificar:* o `check_all` **da A** para o 096n (ela o roda na Fase B); as mutações.

**ACOMPANHAMENTO.** *Avanço:* a A tem **096h a 096n verificados por mim** sobre o `main` atual (**178 e 179 scripts verdes**, jogo real idêntico). *Próxima:* se a A empurrar para o `main`, **audito em até 20 minutos** (o meu `check_all` já está pré-verificado; o diagnóstico de morte forçada também). *Git:* só leitura nos ramos remotos; único commit é o `status-b`; `main` em `4db060f`.
