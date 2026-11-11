11/11/2026 12:52 (Brasília) — APROVADO por Arthur: LW-146a a LW-146e (frase recebida); Fase B (merge no `main`) NÃO iniciada: aguardo o passo a passo dele (regra 13); os 5 ramos seguem fora do `main`, `check_all` verde em cada um (1203 de 1203)

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
