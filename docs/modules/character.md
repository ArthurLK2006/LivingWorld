# Contrato — character

Estado: **LW-035 implementada.** Este contrato cobre só o estado mínimo do jogador que a Fase 1 usa (LW-035): identidade, posição e orientação. A ficha completa do módulo (habilidades, inventário, corpo, conhecimento — arquitetura 15.4 e 15.6) é a **extensão da Fase 5**, descrita na seção "Extensão da Fase 5 (LW-146c, PLANEJADA)" no fim deste arquivo; **nada dela existe no código**.

- **Responsabilidade:** guardar o estado lógico mínimo de cada personagem controlável (hoje, só o jogador): identidade, posição e orientação; validar pedidos de nascimento e de atualização de posição.
- **Entradas:** comando `request_spawn()`; comando `report_position(actor_id, pos, yaw)`; consulta ao `world` para validar "dentro do mapa".
- **Saídas:** `Result` de cada comando (o de `request_spawn()` também traz o `actor_id` novo, no mesmo padrão de `DecodedSave`/`HeightQuery` já usado em outros contratos — campo extra ao lado de um `Result`); consulta `peek_character(actor_id)` (posição e orientação atuais).
- **Dependências permitidas:** `core`, `world` (consulta de limites do mapa, para recusar posição fora dele). `character` é camada 3; `world` é camada 2 — import permitido (AGENTS cap. 5.1).
- **Dados controlados:** `CharacterState` (posição `Vector3`, orientação `yaw: float`) de cada personagem, guardado num `Dictionary` indexado por `actor_id`. Hoje só uma entrada existe (o jogador), mas o módulo já nasce indexado por ID, e não como um único objeto fixo, para não supor jogador único (AGENTS cap. 6: "nada de 'o jogador' no singular na simulação"; comandos tipados pelo identificador do ator). `Dictionary` com mais de uma entrada no futuro segue a regra de determinismo do `MODELO.md` (visitar por ID, nunca pela ordem natural).
- **Interfaces de comunicação:** `request_spawn()` — **decisão desta tarefa:** sem parâmetro de ator, porque o ID ainda não existe antes do nascimento; o próprio comando gera o ID pelo `core.IdGenerator` (`ctx.ids`, já usado por outros módulos) e o devolve no resultado. `report_position(actor_id, pos: Vector3, yaw: float)` — **decisão de Arthur (04/11/2026):** o nome é mantido; foge do padrão `request_*` de comando (AGENTS cap. 7) de propósito. Recusa posição fora do mapa, consultando `world`. `peek_character(actor_id)`. Nenhum evento nesta tarefa. Como todo estado novo (AGENTS 4.15 e critério da LW-035 no roadmap): `serialize()`/`on_load(data) -> Result`, `validate()` e `debug_summary()`, no mesmo padrão já usado por `core` e `app` (`docs/modules/core.md`); é pelo `serialize()` que o estado do personagem entra no `state_hash` do `World` (LW-022 já garante o mecanismo de hash; `character` só precisa participar dele). Os campos de `serialize()`/`on_load()` são os definidos em "Decisões técnicas da LW-035", abaixo.
- **Testes necessários:** nascer no ponto correto (igual ao `peek_spawn_point()` do `world`, critério do roadmap LW-035); posição fora do mapa é recusada (critério do roadmap); ida e volta de save preserva posição e orientação (critério do roadmap); entra no `state_hash` do `World` (critério do roadmap); `actor_id` desconhecido em `report_position`/`peek_character` devolve erro tratado, sem travar (AGENTS 13.1.4).

**Decisão de Arthur (04/11/2026):** `character` gera o próprio `actor_id` pelo `core.IdGenerator` até o módulo `entities` nascer (quando NPCs chegarem, na Fase 2). A arquitetura (cap. 3.5 e 5.1) lista `entities` como dependência de `character`, mas esse módulo ainda não existe — só a pasta reservada (`src/sim/entities/`). Se `entities` nascer com desenho diferente do que este contrato assume, `character.md` é revisado nessa ocasião.

**Decisões técnicas da LW-035 (implementação; as decisões do contrato acima não mudam):**
- **Tipos.** `CharacterState` (`position: Vector3` em metros e `yaw: float`; só dados); `CharacterModule` (`extends SimModule`, `Dictionary[int, CharacterState]` indexado por `actor_id`); `SpawnResult` (`result` e `actor_id`, que só vale se `result.ok`); `CharacterQuery` (`result`, `position`, `yaw`; devolve **cópia**, nunca o objeto interno).
- **(i) Terreno.** O `TerrainData` já carregado entra pelo **construtor** (`CharacterModule.new(terrain)`), sem global nem autoload; o módulo só usa as consultas `peek_*` e nunca altera o terreno. Em `setup()` ele confere `terrain.validate()` **uma vez** (a conferência varre a grade inteira, então não se repete a cada comando). Terreno nulo ou inválido, ou módulo que ainda não passou por `setup()`: os comandos devolvem `CHARACTER_NOT_READY`.
- **(ii) "Dentro do mapa".** Quem decide é `peek_height(x, z).result` do `world`, dono da regra de borda (intervalo fechado); o `character` não copia a regra. Recusa: `CHARACTER_OUT_OF_BOUNDS`. **[LIM]** `Vector3` tem 32 bits: num mapa cujo tamanho em metros não é exato em 32 bits, um ponto exatamente na borda pode chegar um pouco para fora e ser recusado.
- **(iii) Altura Y.** Só precisa ser número finito; não é comparada com o chão (o personagem pode estar no ar). Colisão e inclinação são da apresentação (LW-045 e LW-047).
- **(iv) Orientação.** `yaw` em radianos, finito, guardado como veio (**sem normalizar**). NaN e infinito, na posição ou no `yaw`, são recusados com `CHARACTER_INVALID_VALUE`. Quem nasce tem `yaw` 0 (`SPAWN_YAW`, **[HIP]**).
- **(v) Nascimentos.** Cada `request_spawn()` cria **outro** personagem, com ID novo de `ctx.ids`, no `peek_spawn_point()` do `world`. Sem limite de quantidade (o GDD não define). Contador de IDs esgotado: `CHARACTER_NO_ID`. ID novo que já pertence a um personagem carregado (save inconsistente): `CHARACTER_DUPLICATE_ID`, sem sobrescrever nada.
- **(vi) Salvamento.** `serialize()` devolve `{"characters": {"<id>": {"position": [x, y, z], "yaw": n}}}`, com o ID como texto (é assim que o JSON guarda chaves) e as chaves em ordem crescente do número; decimais de 64 bits, como no `core`. `on_load` converte e valida **tudo** antes de alterar o estado (campo ausente, tipo errado, chave que não é inteiro, ID fora de 1 a 2^53-1, dois textos para o mesmo ID, valor não finito: `CHARACTER_INVALID_SAVE`). Posição fora do mapa **não** é recusada ao carregar; é apontada por `validate()`.
- **(vii) Sem tick, sem evento.** `tick()` não faz nada; não há evento (`docs/events.md` não muda) nem outro `request_*`.
- **(viii) Erros.** `Result.failure` com código `CHARACTER_*` e mensagem com o que falhou, onde (ID e valores) e o esperado. ID inexistente (0, negativo, alto) devolve `CHARACTER_UNKNOWN_ACTOR`, sem derrubar o jogo.
- **`validate()`** aponta: ID fora da faixa, valor não finito, posição fora do mapa e terreno inválido. **`debug_summary()`:** quantidade, IDs em ordem e se o terreno está pronto.
- **Fora desta tarefa (LW-035).** O módulo **não** era registrado no jogo (`SimulationRunner`, `GameApp`) nem recebia o `TerrainData` lá: isso ficou para a ponte (LW-036 e LW-048). **Feito na LW-048, abaixo.**
- **Registro no jogo (LW-048).** Desde a LW-048 o mundo do jogo tem o módulo, sob o nome `character` (`GameModules.CHARACTER_NAME`, chave do módulo no save), registrado por **uma função única**, `GameModules.register(runner, terrain)` (`src/app/game_modules.gd`), que o `SimulationHost` chama ao iniciar jogo novo (com o `TerrainData` já lido, que entra pelo construtor) e que os testes de integração usam para montar o MESMO mundo. Quem pede o nascimento e guarda o `actor_id` é a apresentação (o `PlayerBody`), pela ponte (`request_spawn_character`, `request_report_position`, `peek_character`; `docs/modules/bridge.md`); a simulação não conhece "o jogador" e a ponte não é dona dele. **Efeito no save:** o `state_hash` e o conteúdo do save do jogo mudaram (o módulo `character` entra em `modules`, com zero personagens num jogo recém-criado). A **estrutura do arquivo** (`{world, scheduler}`, cabeçalho, checksum) **não mudou**, então `CURRENT_SAVE_VERSION` continua **2** (decisão da LW-048, pelo AGENTS 4.15: o que cresceu foi o conjunto de módulos do jogo, e `World.on_load` já recusa com mensagem clara, `WORLD_MODULE_DATA_MISSING` ou `WORLD_UNKNOWN_MODULE`) um save feito com outro conjunto de módulos; save antigo é rejeitado até o "save congelado", DEC-083). `tests/integration/test_game_world_save.gd` cobre a ida e volta (posição e giro exatos, hash igual) e as duas recusas.
- **Testes:** `tests/unit/test_character_module.gd`.

---

## Extensão da Fase 5 (LW-146c, PLANEJADA)

Estado: **PLANEJADA (11/11/2026).** Nada desta seção existe no código; o que está implementado é só o estado mínimo da LW-035, acima. Fontes: arquitetura 15.4 e 15.6; GDD 6, 7 e 16.5; roadmap 5.D (LW-147 a LW-149, LW-156, LW-160 a LW-163 e a subseção "Tarefas novas propostas da Fase 5"); `docs/modules/combat.md`; `docs/modules/economy.md`. Rótulos: **decisão** (APROVADA, com a DEC), **[PROPOSTA]**, **[HIP]**, **[EM ABERTO]** (ninguém decidiu) e **[FUT]**. Nomes de comandos, consultas, eventos e códigos são **[PROPOSTA]**; os eventos novos entram em `docs/events.md` na LW-146f. Nomes genéricos (DEC-100).

- **Responsabilidade (ampliada):** além da identidade, posição e orientação da LW-035: **habilidades** (progressão por uso), **equipamentos em instâncias**, **corpo** (vida e estado "ferido" de quem tem `character`), **conhecimento** (o que foi descoberto), **origem**, **morte e renascimento nos dois modos** (DEC-181) e o **estado de T2 e T3** (DEC-199). **Não** guarda quantidades de bens nem dinheiro (são da `economy`, DEC-130), nem decide o que o NPC quer (é do `npc`), nem calcula dano (é do `combat`).
- **Entradas:** comandos do jogador pela ponte (equipar, pegar item, aprender, escolher o modo de morte); pedidos do `combat` (vida, desgaste de item); eventos: `CombatantDied` (do `combat`), a promoção de NPC a T2 ou T3 (evento novo do `npc`, LW-146f) e o evento de bem consumido na fabricação (da `economy`, DEC-193).
- **Saídas:** consultas `peek_*` (cópias); eventos `SkillImproved`, `ItemEquipped`, `ItemBroken`, `KnowledgeGained` (arquitetura 15.6) e os novos `PlayerDefeated`, `PlayerRespawned`, `ItemDropped` e `ItemTaken`.
- **Dependências permitidas:** `core`, `data`, `world` (como hoje; camada 2). **Não importa** `npc`, `economy`, `combat` nem `ecology` (o `combat` e a `ecology` é que importam o `character`, só pela `api`). Tudo que vem de `npc` ou `economy` chega **por evento**; IDs de bens entram como texto livre de `data/`. O módulo `entities` não existe (DEC-141).
- **Dados controlados:** `Skills`, `Inventory` (instâncias e slots), `BodyState`, `Knowledge`, a origem aplicada e o **modo de morte** de cada personagem; os **itens no chão que são instâncias** (seção E3). **Um dono por dado:** a quantidade de bens (grão, minério) continua na `economy`.
- **Testes necessários:** seção E7.

### E1. Quem é "personagem"

- **Jogador:** nasce por `request_spawn` (LW-035). **T2 e T3:** o `character` **cria o estado ao ouvir a promoção** do `npc`, com o **mesmo ID** do NPC (`actor_id` = `npc_id`; DEC-199, PROPOSTA). **T1** (guardas, soldados, bandidos) **não tem** `CharacterState`: arma e armadura vêm de um **equipamento padrão por ofício**, em dados, e a vida é do `combat`.
- **[EM ABERTO] rebaixar T2 para T1:** guardar ou descartar o estado e o equipamento. **Recomendação:** guardar (ninguém perde item por ser rebaixado) e ignorar fora de combate. A decisão é do contrato do `npc` (LW-146f).
- **Peso:** o `character` guarda o peso das **instâncias**; o peso dos **bens** é da `economy`. **[PROPOSTA técnica, DEC-193]:** peso total = soma das duas consultas, somada **pela ponte** (o `character` não importa a `economy`); a capacidade é uma só, vinda de `owner_kinds`. **[EM ABERTO]** se a ponte também recusa o pedido quando passa da capacidade (recomendado) ou se cada módulo confere a sua parte.

### E2. Equipamento em instâncias (LW-148, DEC-190)

- **`ItemInstance`:** `item_id` (de `ctx.ids`, nunca reutilizado), `def_id` (texto de `data/`), `quality`, `durability`, `weight` (inteiros), **`bound`** (booleano, DEC-190) e **`origin_owner_id`** (0 = sem marca; seção E4). Instância não é bem: **não** passa por `request_trade` nem entra na conservação de bens da `economy`.
- **Slots [PROPOSTA, HIP]:** `weapon` e `armor` (como no SP6: armadura nenhuma, leve ou pesada). Armadura em camadas (GDD 16.5) fica para "depois". **Munição** do arco: **[EM ABERTO]** (bem em quantidade ou item); depende do arco (`combat.md`, seção 15).
- **Comandos:** `request_equip(actor_id, item_id)`, `request_unequip(actor_id, slot)`, `request_transfer_item(from_id, to_id, item_id, cause)` e `request_wear_item(actor_id, item_id, amount)` (do `combat`). **"Um item, um lugar":** a instância está num inventário, equipada **ou** no chão, nunca em dois (teste).
- **Origem do item (DEC-193):** vem do **kit de origem**, do **saque** ou do **ferreiro**. A economia destrói o metal com um **motivo fechado novo** e publica um evento; o `character` **cria a instância ao ouvir** (qualidade pela receita e pela habilidade; regra no contrato da LW-148). **Reparo** fica para "depois".
- **Durabilidade:** cai por `request_wear_item`; zero = **quebrado**: `ItemBroken` **uma vez**, o item deixa de valer.

### E3. Morte e renascimento (DEC-181, DEC-065, DEC-188 a DEC-191)

- **Modo de morte:** o jogador escolhe **ao começar o jogo** (LW-156d, menu da LW-175): `respawn_near` ou `reload_autosave`; fica guardado no personagem. **[EM ABERTO]** se pode mudar no meio do jogo (Arthur disse "ao começar"; recomendação: não).
- **Gatilho:** `CombatantDied` de um personagem **jogador**. O `character` **só executa o que é dele**; **carregar o save** é da ponte e do `app` (`bridge.md`), não do `character`.
- **`reload_autosave`:** o `character` publica `PlayerDefeated` (com o modo) e a ponte pede o carregamento do último autosave, com aviso. Exige autosave frequente (LW-176).
- **`respawn_near`:** (1) o jogador **renasce no ponto de renascimento mais perto** do local da morte; **[PROPOSTA]** pontos de renascimento são **locais do `world`** (extensão de `world`, LW-146f; hoje só existe o ponto de nascimento, `peek_spawn_point`); (2) as instâncias **não ligadas** (`bound` falso), equipadas ou não, **viram itens no chão** no local da morte, com **duração de 24 horas de jogo [HIP]** (DEC-188); depois **somem**; (3) as instâncias **ligadas** (`bound` verdadeiro: equipamento de origem e itens de missão; DEC-190) **ficam com o jogador**; (4) os **bens em quantidade** do jogador (materiais, minérios) também caem, em um "monte no chão" **da `economy`** (tipo de dono novo, LW-146f; motivo de destruição `spoiled` ao sumir, DEC-156).
- **[EM ABERTO] (ninguém decidiu):** o que acontece com o **dinheiro** ao morrer; a **vida** com que se renasce e se renasce "ferido"; o que são **"itens de missão"** (o roteiro de jogo não tem missões; talvez itens de contrato ou de entrega em andamento).
- **Itens no chão (instâncias):** guardados pelo `character` (`GroundItem`: `item_id`, posição em cm, `dropped_at`, `expires_at`). **`request_pickup_item(actor_id, item_id)`** valida distância e capacidade. A expiração roda no tick do `character` e remove a instância (`ItemDropped` a publica ao largar; `ItemTaken`, ao pegar).
- **Quem pegou (DEC-189):** o `character` publica `ItemTaken(item_id, taker_id, place_id)`; quem transforma isso em **memória de testemunha** é o `npc` (T2 por perto; extensão da LW-146f). O jogador **pergunta a NPCs por perto**; quem viu **responde com o nome**; sem testemunha, só **encontrando o NPC**. **[PROPOSTA técnica]** item único (instância) só é pego por quem tem `character` (jogador, T2 e T3); **T1 pega só bens em quantidade** (economia). **[EM ABERTO]** se T1 também pega instâncias (exigiria estado de inventário para T1).

### E4. Marca de origem e contrabando (DEC-183)

- **Marca:** `request_transfer_item(..., cause)` com `cause` = `theft` (roubo, LW-163a) ou `loot` (saque de morto, LW-156b) grava `origin_owner_id` = o dono de quem o item saiu. Vender um item **marcado** numa loja **legal** é crime (a decisão é de `events` ou `politics`, DEC-195; o `character` só **informa** a marca).
- **[EM ABERTO] venda de item único a mercado:** hoje **não existe** caminho: a `economy` só negocia **bens em quantidade** (`request_trade`). Para a marca valer, precisa existir um caminho de venda de instância (extensão de `economy` e `character`, LW-146f). Sem ele, o contrabando por marca não tem onde acontecer.
- **Lista de bens proibidos** (a outra metade do contrabando) é de `politics` (`TradeRules`); o `character` não participa. **Rastrear cada unidade de mercadoria** fica para "depois" (DEC-183).

### E5. Conhecimento e o mapa (DEC-184, DEC-191)

- **`Knowledge`:** conjunto de `(type_id, entity_id)` descobertos. **Regra por tipo, em dados** [PROPOSTA]: `visibility` = `always` (assentamentos, rotas, pontos de reconhecimento) ou `discovered` (ruínas, tesouros, minérios, covis escondidos).
- **Comandos:** `request_discover(actor_id, type_id, entity_id, source)` — **idempotente** (descobrir de novo não muda nada e não repete o evento); `request_reveal(actor_id, entities)` — quem visita um **ponto de reconhecimento** (a `ecology` ou o `world`) passa a lista dos segredos **dentro do raio [HIP]** (DEC-191); o `character` só **registra**. `peek_known(actor_id, type_id)` devolve cópia, em ordem crescente de ID.
- **Quem filtra o mapa:** a **ponte** cruza o que o `world` e a `ecology` conhecem com o `peek_known` e a regra do tipo (`bridge.md`, LW-146e); o `character` não conhece o mapa.

### E6. Habilidades, origem e mentor (LW-147, LW-149, LW-161)

- **Habilidades:** `SkillUsed(actor, skill, difficulty)` → ganho com **retorno decrescente** (dificuldade acima do nível rende mais), números em dados; quatro no protótipo (corpo a corpo, arco, furtividade e comércio; roadmap LW-147); vale para jogador, T2 e T3; `peek_skill`.
- **Origem:** **3 origens por lugar de nascimento** (campo, cidade, estrada; DEC-180), em dados: itens, habilidades, relações iniciais e local de partida, aplicados em `on_new_game`; origem **não** é classe. O **equipamento de origem é `bound`** (DEC-190).
- **Mentor:** `request_learn(actor_id, mentor_npc_id, skill_id)`; o mentor é NPC T2 e o `character` **não importa o `npc`**: os dados do mentor (habilidade e limite) chegam **pela ponte** **[PROPOSTA]**.

### E7. API, save e testes

| Nome | Tarefa | O que faz |
|---|---|---|
| `peek_character(actor_id)` (ampliada) / `peek_body` / `peek_inventory` / `peek_skill` / `peek_known` | 147, 148, 156, 160 | consultas (cópias) |
| `request_equip` / `request_unequip` / `request_transfer_item` / `request_wear_item` | 148 | seção E2 |
| `request_apply_damage(actor_id, amount, cause_id)` | 156 | do `combat`; vida e "ferido" de quem tem `character` |
| `request_set_death_mode(actor_id, mode)` | 156d | escolha ao começar |
| `request_pickup_item(actor_id, item_id)` | 156a | pega item do chão |
| `request_discover` / `request_reveal` | 160, 160a | seção E5 |
| `request_learn(actor_id, mentor_npc_id, skill_id)` | 161 | seção E6 |

**Códigos** (prefixo `CHARACTER_`, além dos da LW-035): `CHARACTER_ITEM_UNKNOWN`, `CHARACTER_ITEM_NOT_HERE`, `CHARACTER_ITEM_BOUND`, `CHARACTER_SLOT_INVALID`, `CHARACTER_TOO_HEAVY`, `CHARACTER_TOO_FAR`, `CHARACTER_MODE_INVALID` e `CHARACTER_DATA_INVALID`.

**Save:** `serialize`/`on_load`/`validate`/`debug_summary` ampliados (AGENTS 4.15); ordem crescente de ID; `validate()` aponta item em dois lugares, item no chão vencido, peso fora da faixa, `bound` no chão e slot com item de outro dono. Save antigo: **rejeitado** com mensagem clara (DEC-186).

**Testes (por tarefa):** **LW-147** ganho diminui com o nível, dificuldade maior rende mais, ida e volta, vale para T2 e T3. **LW-148** item não está em dois lugares, peso e capacidade, a instância nasce com qualidade pela regra do contrato, save preserva instâncias. **LW-148a** `bound` mantido ao morrer. **LW-149** cada origem aplica exatamente os dados; origem inexistente é recusada. **LW-156** ferido e recuperação por tempo; morte **uma vez**. **LW-156a, c, d** itens soltos caem no chão e somem em 24 h; ligados ficam; os dois modos; escolha guardada no save. **LW-156e** `ItemTaken` com o nome certo. **LW-160, 160a** descobrir é **idempotente**; o raio revela só segredos dentro dele. **LW-163a** a marca de origem aparece na instância roubada.

### E8. Extensões pendentes e pontos em aberto

- **Extensões de outros módulos (LW-146f):** `npc` (evento de promoção; memória de testemunha de item pego; NPC pega item), `economy` (monte no chão como tipo de dono; motivo de destruição do metal e o evento; **venda de instância**), `world` (ponto de renascimento), `docs/events.md` (os eventos acima).
- **Em aberto:** dinheiro ao morrer; vida com que se renasce; "itens de missão"; rebaixar T2; munição do arco; venda de item único; se T1 pega instância; se o modo de morte muda no meio do jogo.
