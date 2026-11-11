# Contrato — combat

Estado: **PLANEJADO (LW-146b, 11/11/2026).** Nenhuma classe, dado, evento ou comando deste arquivo existe no código; é desenho para as LW-150 a LW-158 e para a LW-155a (o teste de tropas). Fontes: arquitetura 14 e 15; GDD 16; roadmap 5.D (LW-150 a LW-158 e a subseção "Tarefas novas propostas da Fase 5"); relatório do SP6 (`docs/decisions/0008-spike-sp6-combate.md`). Rótulos: **decisão** (APROVADA em `DECISIONS.md`, com o número da DEC), **[PROPOSTA]** (DEC PROPOSTA ou desenho deste contrato, ainda não aprovado), **[HIP]** (número de trabalho, não é requisito: vai para `data/`), **[EM ABERTO]** (ninguém decidiu) e **[FUT]**. Os **nomes** de comandos, consultas, eventos e códigos de erro são **[PROPOSTA]**. Os eventos novos **não** estão catalogados: entram em `docs/events.md` na LW-146f. Nomes de armas, habilidades e criaturas são genéricos e provisórios (DEC-100).

- **Responsabilidade:** as **regras do combate** da Fase 5: validar e resolver a **intenção de ataque** (alvo, habilidade, alcance, estamina, preparo e recuperação), calcular o dano pela fórmula do SP6, manter o **estado de encontro** de cada combatente, publicar ferimento e morte, pedir o desgaste do equipamento e dar corpos até o **orçamento de combatentes com corpo**. **Não** faz: decidir o que o NPC quer (é do `npc`, seção 6), guardar a vida e o "ferido" de quem tem `character` (é do `character`, seção 5), física, áreas de contato, animação, crime (DEC-195), política, economia, **bloqueio, esquiva, ferimento por golpe, magia, chefe e comando de tropas** (fora do protótipo, DEC-179 e DEC-182).
- **Entradas:** a intenção de ataque do jogador (pela ponte); a intenção de ataque do NPC e da criatura (por evento, DEC-199); pedidos de encontro do `military` (DEC-194); o avanço do tempo do encontro (seção 3); definições em `data/` (habilidades, armas, armaduras, parâmetros).
- **Saídas:** o resultado de cada intenção (`AttackResult`, uma cópia); consultas `peek_*`; os eventos `CombatantWounded`, `CombatantDied` e `CombatEnded` (catálogo na LW-146f); pedidos ao `character` (desgaste de item, vida).
- **Dependências permitidas:** `core`, `data`, `world` (posição e local), `character/api` (vida, equipamento e durabilidade) e `npc/api` (consultas). `combat` é **camada 4**; as camadas 3 e abaixo são permitidas, só pela `api`. **Não importa** `economy`, `military`, `factions`, `politics`, `events` nem `ecology`. **Quem importa o `combat`:** a ponte, o `military` (pede encontro) e a `ecology` (criaturas). O módulo `entities` não existe (DEC-141): os IDs vêm de `ctx.ids`.
- **Dados controlados:** o `CombatantState` e o `Encounter` (seção 5) e o relógio do encontro. Nada mais: vida de quem tem `character`, itens, dinheiro, reputação e crime são de outros donos.
- **Interfaces de comunicação:** seção 12 (`request_*`, `peek_*`) e seção 11 (eventos).
- **Testes necessários:** seção 14, por tarefa.

## 1. O que entra e o que não entra (DEC-179 e DEC-182)

- **Entra:** o combate **testado no SP6** (alvo por clique, ataque automático, habilidades com preparo e recuperação, estamina e posição; DEC-117 e DEC-121), o **inimigo que se posiciona e reage** (DEC-121, item 3), o **ferimento simples** ("ferido", recupera com o tempo) e o **arco** (LW-154, munição como item; **[EM ABERTO]** se é uma habilidade à distância por alvo ou um projétil físico, seção 15).
- **Fica para "depois":** bloqueio e esquiva, ferimento por golpe (sangramento, atordoamento), magias, mais armas e habilidades, chefe, comando de tropas. O que foi cortado não ganha campo, evento nem código "para depois" (AGENTS 5.2, regra 5).
- **Decisão técnica (DEC-192, PROPOSTA):** a ponte leva uma **intenção** (atacante, alvo, habilidade), **não** um `HitReport` por contato. A simulação valida e calcula; ela **nunca confia no cliente para o dano**.

## 2. O laço do SP6 como regra

Os números abaixo são os do SP6 e seguem **[HIP]**: vão para `data/` e o módulo não os escreve no código (AGENTS 4.6).

- **Alvo e ataque automático:** o combatente escolhe um alvo; enquanto houver alvo no alcance, o **ataque automático** sai a cada intervalo fixo (1500 ms no SP6; dano 6; estamina 4). O relógio do intervalo corre sempre e para no limite.
- **Habilidades:** três no SP6, cada uma com **preparo** e **recuperação** (golpe pesado 700 e 900 ms, dano 30, estamina 30; rápido 200 e 400 ms, dano 10, estamina 12; perfurante 400 e 600 ms, dano 16, estamina 20, ignora 50% da redução da armadura). Apertar durante o preparo, ou antes dos últimos 200 ms da recuperação (o *buffer*), é ignorado sem mensagem.
- **Ordem das recusas** (nada é gasto numa recusa): sem alvo, depois sem estamina, depois longe demais (alcance 250 cm, tolerância de 50 cm no golpe). Habilidade durante preparo ou recuperação: "ocupado".
- **Estamina:** máximo 100; regenera 12 por segundo, começando 1000 ms depois do último gasto.
- **Posição:** a posição do atacante em relação ao alvo dá bônus: frente até 60° (100%), lado até 120° (125%), costas (150%).
- **Dano final**, em inteiros: `base × posição% × (100 − redução%) / 10.000`, divisão inteira, **mínimo 1**. Armadura: nenhuma 0%, leve 25%, pesada 50% (SP6).
- **Pausa:** o jogo pausado congela o relógio do encontro.
- **Sem sorteio:** a fórmula é determinística. Se um dia sortear, só por `ctx.rng` em fluxo nomeado (AGENTS 4.9); mesmo golpe, mesma semente, mesmo resultado.

## 3. Tempo do combate [EM ABERTO + PROPOSTA técnica]

**O problema (buraco encontrado no levantamento):** o combate do SP6 corre em milissegundos, mas a simulação avança em **passos de 1 minuto de jogo** (1 minuto = 1,25 s a 1x; DEC-078 e DEC-124). Nenhum documento diz qual relógio o `combat` usa.

- **[PROPOSTA técnica, a confirmar na LW-151]:** o `combat` tem um **relógio de encontro em milissegundos**, que só avança por `request_advance_encounters(dt_ms)`, chamado por quem avança o mundo (hoje o `SimulationHost`, que **não** é editado aqui), em **passos fixos [HIP: 50 ms]** e **só enquanto há encontro**. O relógio é do módulo (AGENTS 4.10: nada de `Time.get_*` em `src/sim/`) e pausa com o jogo. A ponte **não** avança o tempo (decisão de Arthur, 05/11/2026, em `bridge.md`).
- **Encontro em S1 (sem corpo):** a mesma regra, em passos maiores **[HIP]**, sem apresentação (a LW-155 exige que o combate rode em teste sem janela). **[PROPOSTA]**
- **[EM ABERTO]** a **cadência de decisão do NPC em combate** (em ms de encontro): hoje o `npc` pensa em minutos de simulação. É uma extensão do contrato do `npc` (LW-146f); sem ela o inimigo não "reage" em tempo real.

## 4. Intenção de ataque e resolução (DEC-192)

- **`request_attack(attacker_id, target_id, skill_id) -> AttackResult`:** valida, na ordem da seção 2, e aplica. Atacante e alvo precisam estar **vivos** e **no mesmo encontro**; o pedido do jogador vem pela ponte, que repassa **sem regra** e entrega o `actor_id` (nunca "o jogador" no singular; AGENTS 6).
- **`AttackResult`** (cópia): `result` (`Result` da `core`), `skill_id`, `damage`, `target_hp` (vida depois do golpe), `target_died`, `position_zone` (frente, lado ou costas), `phase_ends_ms` (quando o atacante fica livre). A apresentação toca animação e efeito pelo que volta.
- **Atômico:** pedido recusado **não muda nada** (estamina, recarga, alvo).
- **Fila de intenções da ponte:** a **primeira intenção concreta** da ponte é esta; ela define o **teto** da fila e **quem a consome** (aplicar os comandos no início do passo, arquitetura 6.5). Detalhe no `bridge.md` (LW-146e). **[PROPOSTA]**

## 5. Estado, vida e ferimento simples

- **`CombatantState`** (um por combatente em combate; dono: `combat`): `combatant_id`, `target_id`, `stamina`, `stamina_regen_at_ms`, fase (`idle`, `preparing`, `recovering`), `phase_ends_ms`, `auto_next_ms`, `weapon_id` e `armor_id` (por ID, não o objeto) e, **só para quem não tem `character`** (T1 e criaturas), `hp`.
- **`Encounter`** (dono: `combat`): `encounter_id` (de `ctx.ids`), participantes por lado, início, e quem está **com corpo** (seção 8).
- **Quem guarda a vida [PROPOSTA técnica]:** **um dono por entidade.** Para **jogador, T2 e T3** a vida e o estado **"ferido"** são do `character/body` (`BodyState`; contrato na LW-146c); o `combat` os **lê** por consulta e **pede** a mudança por `request_apply_damage(actor_id, amount, cause_id)`. Para **T1 e criaturas** (sem `character`), a vida é do `CombatantState` e o "ferido" não persiste além do encontro. A arquitetura (15.2 e 15.4) pôs vida nos dois lugares; esta regra tira a duplicação.
- **Ferimento simples (DEC-182):** abaixo de um **limiar de vida [HIP]**, em dados, o combatente fica **"ferido"**; a **recuperação por tempo** é do `character/body` (minutos de simulação). Efeito do "ferido" no combate (por exemplo, menos estamina máxima): **[EM ABERTO]**, valor de jogo que ninguém decidiu; entra como **[HIP]** quando Arthur disser qual.

## 6. Inimigo que reage; NPCs e criaturas (DEC-121, item 3; DEC-199)

- **Quem decide:** o **`npc` decide** (lutar, fugir, render-se, pedir ajuda) pelo **mesmo sistema de utilidade** e **publica a intenção**; o **`combat` escuta e resolve**. O `npc` não importa o `combat`; o `combat` só **consulta** o `npc` pela `api`, e a intenção chega **por evento** (AGENTS 4.13).
- **"Reagir e se posicionar" (DEC-121):** o inimigo **não deixa o jogador bater nas costas "sem mais nem menos"**. O `combat` entrega ao `npc` a **posição relativa** (frente, lado, costas) e o bônus que ela dá; quem escolhe virar-se ou recuar é a **utilidade do `npc`**. Critério de aceite da LW-155: em cenário idêntico, o NPC valente luta e o covarde foge, e nenhum NPC fica parado levando golpe pelas costas.
- **Criaturas** (`ecology`): mesma intenção, mesmas regras; o comportamento (patrulhar, caçar, fugir) é da `ecology` (contrato na LW-146d).
- **T1 sem `CharacterState`:** arma e armadura vêm de um **equipamento padrão por ofício** (ou por tipo de criatura), **em dados** (DEC-199). Só T2 e T3 têm instâncias (`character`).
- **Evento de intenção do NPC:** o nome e a carga ficam para a LW-146f; precisa de `attacker_id`, `target_id` e `skill_id`.

## 7. Ferimento, morte e durabilidade

- **`CombatantWounded`:** publicado quando um golpe causa dano (carga: `attacker_id`, `target_id`, `damage`, `place_id`, `skill_id`). **É a partir dele (e do `CombatantDied`) que `events` ou `politics` decide se houve crime** (DEC-195): o `combat` **só informa o fato** e **não** publica `CrimeCommitted`.
- **`CombatantDied`:** **uma única vez** por combatente (teste obrigatório). O `character` decide o que acontece com o jogador (os dois modos da DEC-181, contrato na LW-146c); a `ecology` trata a criatura; o `military` baixa a `Force` (seção 8).
- **`CombatEnded`:** o encontro acaba quando um lado não tem mais ninguém em condições de lutar, ou quando todos se afastam além de uma distância **[HIP]**.
- **Durabilidade:** o `combat` **pede** o desgaste (`request_wear_item(actor_id, item_id, amount)` no `character`); a durabilidade e o `ItemBroken` são do `character`. Item quebrado deixa de valer; **reparo** fica para "depois" (DEC-193).

## 8. Corpos, orçamento e baixas (DEC-194, LW-158)

- **Um sentido só:** o **`military` pede o encontro** (`request_start_encounter`) e o **`combat` devolve as baixas por evento**. O `combat` **não** importa o `military`; o `military` importa só a `api` do `combat` (camada 4 para camada 4, mão única).
- **Orçamento:** `max_embodied_combatants`, em dados, **cerca de 20 [HIP]**. Quem ganha corpo é escolhido por distância ao foco e, no empate, por ID crescente (determinístico). O **excedente** é resolvido de forma **abstrata** pelo `military/resolution` (LW-137); o `combat` **nunca excede** o orçamento (teste).
- **Baixas:** cada `CombatantDied` volta à `Force` pelo evento; a soma das baixas individuais é a da força (teste da LW-158).
- **[EM ABERTO]** a **batalha em blocos** (parte em S0, parte abstrata, na mesma batalha; TA 14.3) **não tem fórmula**, e "compatível em média" (LW-158) não diz a **tolerância**. Ficam para a LW-158 e para o teste de tropas.

## 9. Teste descartável de tropas, o SP9 (DEC-187)

- **O que é:** um **spike novo**, **descartável como o SP6**, para Arthur jogar e decidir se comandar um **grupo pequeno** vira sistema. **Não** faz parte do módulo `combat`.
- **Quando e onde:** tarefa **LW-155a** [PROPOSTA], depois da LW-158 e antes da LW-159, no fim do bloco de combate. O código fica em `tests/soak/sp9/` (como o SP6) ou é apagado; não usa os módulos definitivos nem entra no `state_hash`; constantes em arquivo próprio, **[HIP]**.
- **O que decide:** as DEC-053 (escala das batalhas) e DEC-029 (profundidade do comando), que **seguem PENDENTES até o teste**.
- **[EM ABERTO] (escolha de Arthur):** quais **ordens** o jogador dá e **quantos** soldados entram. A visão registrada (Mount & Blade Bannerlord, Total War Warhammer 3, magias em sequência) é **referência**, **não** requisito do teste. O contrato do teste sai quando Arthur disser isso.

## 10. Dados que o módulo lê (formato na LW-146f)

`data/` (nomes [PROPOSTA]): habilidades (`skills`: preparo, recuperação, dano, estamina, alcance, bônus de armadura), `weapons.json`, `armors.json`, **equipamento padrão** por ofício e por criatura, e os parâmetros do módulo (intervalo do ataque automático, regeneração de estamina, *buffer*, limiar de "ferido", passo do encontro, orçamento de corpóreos). **Tudo [HIP].** Tabelas planas, sem lista aninhada, validadas com arquivo, item e campo; ids de outro módulo como texto livre e conferência de dados entre módulos (como no contrato da `economy`).

## 11. Eventos planejados (a catalogar em `docs/events.md`, LW-146f)

| Evento | Publica | Ouvem (previstos) | Carga |
|---|---|---|---|
| `CombatantWounded` | `combat` | `events` ou `politics` (crime), `npc` (reação), ponte | atacante, alvo, dano, local, habilidade |
| `CombatantDied` | `combat` | `character` (derrota), `ecology`, `military`, `npc`, `events` | combatente, causa (atacante), local |
| `CombatEnded` | `combat` | `military`, ponte | encontro, vencedor |

Nenhum evento por golpe em laço quente fora desses (AGENTS 4.14): o ataque automático e as habilidades **não** publicam evento próprio; o `CombatantWounded` é **agregado por encontro** quando o ritmo for alto **[HIP]**.

## 12. API (nomes [PROPOSTA])

| Nome | Tarefa | O que faz |
|---|---|---|
| `request_attack(attacker_id, target_id, skill_id)` | 150, 151 | seção 4; atômico |
| `request_select_target(actor_id, target_id)` | 151, 153 | escolhe ou solta o alvo; valida que existe e está vivo |
| `request_start_encounter(participants)` / `request_end_encounter(encounter_id)` | 155, 158 | cria e encerra encontros; o `military` e a `ecology` usam |
| `request_advance_encounters(dt_ms)` | 151 | avança o relógio do encontro em passos fixos (seção 3) |
| `peek_combatant(id)` / `peek_encounter(id)` | 150 | estado (cópia): fase, estamina, alvo, vida, corpóreo ou não |
| `peek_embodied(encounter_id)` | 158 | quem tem corpo agora, em ordem crescente de ID |

**Códigos de erro** (`Result.code`, prefixo `COMBAT_`): `COMBAT_UNKNOWN_ACTOR`, `COMBAT_DEAD`, `COMBAT_NO_TARGET`, `COMBAT_NO_STAMINA`, `COMBAT_OUT_OF_RANGE`, `COMBAT_BUSY`, `COMBAT_NOT_IN_ENCOUNTER`, `COMBAT_BUDGET_FULL` (corpo recusado por orçamento) e `COMBAT_DATA_INVALID`. ID inexistente nunca derruba o jogo (AGENTS 13.1).

## 13. Save, validação e determinismo

- **`serialize`/`on_load`/`validate`/`debug_summary`** (AGENTS 4.15): o save guarda encontros e `CombatantState` em ordem crescente de ID; **não** guarda animação nem corpos. `validate()` aponta combatente morto em encontro, alvo inexistente e estamina fora da faixa. `on_load` valida tudo antes de mudar o estado.
- **Determinismo:** só inteiros; sem `Dictionary` na ordem natural; mesmo estado e mesma sequência de passos, mesmo `state_hash`.
- **Save antigo:** rejeitado com mensagem clara (DEC-186); o `save_version` segue como a DEC-127 diz.

## 14. Testes necessários, por tarefa

- **LW-150** (`rules`): mesmo golpe e mesma semente, mesmo resultado; **armadura** reduz dano pela tabela; **estamina esgotada** impede a ação; dano mínimo 1; recusa **não gasta** nada.
- **LW-151** (ponte): intenção válida gera resultado; fora de alcance é recusada; a simulação **não aceita dano vindo do cliente**; ordem das recusas; fila de intenções com teto e consumo.
- **LW-153** (jogador): sequência scriptada de golpes reduz a vida do alvo como previsto; estamina limita as ações; posição (frente, lado, costas) muda o dano.
- **LW-154** (arco): um projétil que acerta gera **um único** pedido; sem munição não dispara.
- **LW-155** (NPC e inimigo que reage): covarde foge e valente luta no mesmo cenário; NPC gravemente ferido tende a fugir; **ninguém leva golpe pelas costas parado**; roda **sem apresentação**.
- **LW-156** (ferimento e morte): morte dispara **uma só vez**; "ferido" e recuperação por tempo; item quebrado deixa de valer; save preserva os ferimentos.
- **LW-158** (militar): baixas individuais somam as da força; orçamento de corpóreos **nunca excedido**; resultado em S0 e abstrato compatíveis dentro da tolerância **[EM ABERTO]**.

## 15. Extensões pendentes e pontos em aberto

- **Extensões de outros módulos (LW-146f):** `npc` (cadência de decisão em combate; evento de intenção; memória de testemunha); `economy` (itens no chão, motivo de destruição do metal); `docs/events.md` (os três eventos acima e os de intenção). Este contrato **não** edita esses arquivos.
- **Em aberto:** o **arco** (a LW-154 diz "projétil na apresentação, pedido ao acertar", mas as DEC-117 e DEC-182 só falam de alvo e habilidades: ou o arco é uma habilidade à distância por alvo, ou o projétil físico volta a ser contato, o que contraria a DEC-192); relógio do encontro (seção 3); efeito do "ferido" no combate (seção 5); batalha em blocos e tolerância (seção 8); ordens e tamanho do grupo do SP9 (seção 9).
- **Fora (depois):** bloqueio e esquiva, ferimento por golpe, magia, chefe, comando de tropas, reparo de equipamento (DEC-179, DEC-182 e DEC-193).
