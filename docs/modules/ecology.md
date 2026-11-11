# Contrato — ecology

Estado: **PLANEJADO (LW-146d, 11/11/2026).** Nenhuma classe, dado, evento ou comando deste arquivo existe no código; é desenho para as LW-157, LW-160 e LW-160a. Fontes: arquitetura 3.1 (ficha de módulo), 5.3 (LOD) e 6.4 (tick horário); GDD 17 (exploração, criaturas e descobertas) e 16.7; roadmap 5.D (LW-157, LW-160, LW-160a, LW-171); DEC-060, DEC-179, DEC-180, DEC-184, DEC-191, DEC-192, DEC-194, DEC-196 e DEC-199. Rótulos: **decisão** (APROVADA em `DECISIONS.md`, com o número da DEC), **[PROPOSTA]** (DEC PROPOSTA ou desenho deste contrato), **[HIP]** (número de partida, vai para `data/`), **[EM ABERTO]** (ninguém decidiu; nada é inventado aqui) e **[LIM]** (limitação conhecida). Nomes de criaturas e de pontos são **genéricos e provisórios** (DEC-100).

- **Responsabilidade:** as **criaturas** do mundo: nascimento por covil e por província, limite de população, comportamento (patrulhar, caçar, fugir), a alternância entre **S1** (sem corpo) e **S0** (com corpo) e o **estado dos covis**. Entrega a **ameaça** de cada província ao mapa de perigo. **Não** faz combate (é do `combat`), **não** guarda o mapa nem o que o jogador descobriu (`world` e `character`) e **não** cuida de clima, estações nem domesticação (fora do protótipo; DEC-060 e GDD 17.6).
- **Entradas:** o tick horário (arquitetura 6.4); o foco do LOD, que é o jogador (DEC-196); as posições dos corpos, relatadas pela ponte; o evento `CombatantDied` (uma criatura morreu); o pedido `request_spawn_creature` dos eventos dinâmicos (DEC-197); definições em `data/`.
- **Saídas:** consultas `peek_*` (cópias); a intenção de ataque da criatura (**evento**, seção 6); eventos do `combat` e da ponte que a ouvem. **Nenhum evento novo** é planejado para a `ecology` (seção 10).
- **Dependências permitidas:** `core`, `data` e `world` (camada 2). **Não importa** `combat` (camada 4: uma camada 3 não importa uma camada 4), `npc`, `economy`, `character` nem `events`. O módulo `entities` não existe (DEC-141): os IDs das criaturas vêm de `ctx.ids`, nunca reutilizados.
- **Dados controlados:** `CreatureState` (uma por criatura viva), `LairState` (um por covil), o contador de população por província e tipo (derivado) e o relógio do próximo nascimento. Nada mais: o **conteúdo** (tipos, covis) é de `data/`; a **posição fixa** dos pontos é do `world`; o que foi **descoberto** é do `character`; a **vida** em combate é do `combat` (DEC-199 e `combat.md`, seção 5).
- **Interfaces de comunicação:** seção 11.
- **Testes necessários:** seção 13, por tarefa.

## 1. O que entra e o que não entra (DEC-179 e DEC-180)

- **Entra:** **3 tipos de criatura** (DEC-180), os covis, a ameaça e a alternância S1 ↔ S0 com uma `CreatureView` provisória (LW-157). Os pontos de interesse do protótipo (ruína, covil, acampamento de bandidos, posto) são da LW-160; o **ponto de reconhecimento** (LW-160a) usa esta ficha só como lista de segredos (seção 8).
- **Fica para "depois":** chefe e criaturas únicas (cortados na DEC-179), magia, domesticação, migração entre províncias, fome e pressão por presas (GDD 17.3), clima e estações (DEC-060), NPCs que caçam por conta própria e **troféus e saque de criatura** (a LW-156b só trata de NPCs). O que foi cortado não ganha campo, evento nem código "para depois" (AGENTS 5.5).

## 2. Os três tipos de criatura [PROPOSTA]

Os três são **dados** (`creature_types`): quem muda o tipo muda uma linha, não o código. O comportamento é um vocabulário **fechado** de três valores, os da LW-157: `patrol` (patrulhar), `hunt` (caçar) e `flee` (fugir). Todos os números são **[HIP]**.

| Tipo (id genérico) | Comportamento | Em palavras |
|---|---|---|
| `creature_guardian` | `patrol` | territorial: anda em volta do covil, dentro de um raio de coleira, e ataca quem entra no raio de agressão |
| `creature_predator` | `hunt` | sai atrás de um alvo hostil dentro do raio de agressão, persegue até o limite da coleira e volta ao covil |
| `creature_prey` | `flee` | não ataca; foge de qualquer alvo hostil no raio de susto; é a presa do predador |

- **Quem é alvo [EM ABERTO]:** a lista `hostile_to` de cada tipo (jogador, NPCs, outros tipos de criatura) **não está decidida**. **Recomendação:** guardião e predador hostis a jogador e NPCs; a presa não é hostil a ninguém; predador também caça a presa. Sem decisão, nenhuma linha de dados nasce.
- **Vida e equipamento:** a vida de uma criatura em combate é do `CombatantState` (`combat.md`, seção 5); o **equipamento padrão por tipo** é dado do `combat` (DEC-199). A `ecology` guarda só o tipo. **[EM ABERTO]** a vida entre encontros: uma criatura ferida que foge e volta ao covil recupera por tempo ou fica ferida? **Recomendação:** recupera por tempo, em dados.

## 3. Nascimento, população e limite (LW-157)

- **Covil e província:** cada criatura nasce em um **covil** (`LairState`) e pertence à **província** dele (`province_id`, campo de dados do covil; as províncias nascem na LW-118). **[PROPOSTA]** a criatura **não muda de província** nesta fase (sem migração); ela anda só dentro da coleira do covil.
- **Regra:** a cada tick horário, para cada covil em ordem crescente de ID, se a população viva do tipo na província está **abaixo do limite** (`max_per_province`, [HIP]) e o intervalo de nascimento (`birth_interval_hours`, [HIP]) venceu, nasce **uma** criatura no covil. O limite **nunca é excedido** (teste obrigatório da LW-157). O sorteio, se houver, é só por `ctx.rng` em fluxo nomeado `ecology` (AGENTS 4.9).
- **Dinâmica simples (GDD 17.3):** caçar criaturas **reduz** a população; os nascimentos a repõem devagar. **[EM ABERTO]** (decisão de jogo, de Arthur): um covil cujas criaturas foram todas mortas **repovoa com o tempo** ou **fica vazio**? **Recomendação:** repovoar, para a exploração não se esgotar e a revisita valer. Sobrepopulação de presas atraindo predadores e fome (GDD 17.3) ficam fora.
- **Aparição fora do covil:** só pelo pedido dos eventos dinâmicos, `request_spawn_creature` (seção 11), que **respeita o mesmo limite** e devolve `ECOLOGY_AT_CAP` se não couber.

## 4. Covis e pontos de interesse: quem é dono de quê [PROPOSTA]

- **Um dono por dado.** O `world` guarda o ponto **estático** (id, tipo, posição; hoje `data/world/pois.json`, `world.md`). A `ecology` guarda o **estado do covil** (tipo de criatura, província, relógio do nascimento), ligado ao ponto pelo `poi_id` (texto). O `character` guarda **se o jogador descobriu** o ponto. Nenhum dos três escreve no dado do outro.
- **Ruína, acampamento de bandidos e posto (LW-160):** no protótipo **não têm estado que mude**: são dados do `world` (tipo e posição; o acampamento tem o `faction_id` da facção criminosa em dados) mais a descoberta no `character`. **[EM ABERTO]** a **recompensa** de uma ruína além do conhecimento (itens, informação): nenhum documento a descreve; a LW-160 só exige "descobrir registra conhecimento uma única vez". Não é inventada aqui.
- **Extensão de `world` (146f):** os tipos novos de ponto (`ruin`, `lair`, `camp`, `outpost`, `lookout`) e os campos opcionais (`province_id`, `faction_id`, `radius_m`). Este contrato **não** edita `world.md`.

## 5. LOD: S1 e S0, e a `CreatureView` (LW-157, DEC-196)

- **Foco = jogador** (DEC-196). **S1** (sem corpo): a criatura só tem posição lógica e estado; não anda. **S0** (com corpo): a criatura tem uma `CreatureView` provisória na apresentação, anda e luta. O nível é **derivado do foco e não é salvo**: ao carregar, todas nascem em S1 (como no `npc`).
- **Histerese [HIP]:** entra em S0 a até `lod_enter_radius_m` do foco mais próximo e só volta a S1 acima de `lod_exit_radius_m` (maior que a de entrada); limite `max_s0_creatures`, e acima dele ficam em S0 as mais próximas, desempate por ID crescente. Os raios e o limite são da `ecology`, em dados próprios (não lê os do `npc`).
- **Preservação:** ao entrar em S0 o corpo nasce na **posição lógica** da criatura; ao sair, o último relato do corpo vira a posição lógica. Alternar S1 ↔ S0 **não duplica nem perde** criatura (teste obrigatório).
- **Quem tem corpo agora:** a ponte pergunta por **consulta em lote** (`peek_creature_bodies`, DEC-196), sem `CreatureView` por criatura e sem evento de LOD **[PROPOSTA]**. O formato exato (posição, tipo, estado, tamanho do lote) é da LW-146e (`bridge.md`).

## 6. A criatura no combate (DEC-192, DEC-194, DEC-199)

- **Mesmas regras** de jogador e NPC: a criatura é um **combatente** do `combat`, com o mesmo ID. A `ecology` **decide** (atacar este alvo, fugir, voltar ao covil) e **publica a intenção de ataque como evento**; o `combat` **escuta e resolve**. É a regra do `npc` (DEC-199) aplicada à criatura. A `ecology` **não importa** o `combat` (uma camada 3 não importa uma camada 4); é o `combat` que consulta `ecology/api` para saber o tipo da criatura.
- **Nome e carga do evento de intenção:** da LW-146f (precisa de `attacker_id`, `target_id` e `skill_id`); o `npc` e a `ecology` **publicam o mesmo evento**.
- **Cadência de decisão em combate [EM ABERTO]:** a mesma pergunta aberta do `combat.md` (seção 3). A `ecology` avança no tick horário; "a criatura reage" em tempo de combate (milissegundos) exige que o `combat` ou o `SimulationHost` dê à `ecology` um passo mais curto enquanto há encontro. Não é decidido aqui.
- **Morte:** ao ouvir `CombatantDied` de uma criatura, a `ecology` a remove (população, alvo, relógio) **uma única vez** (o evento já é único).
- **Orçamento de corpóreos (DEC-194) [EM ABERTO]:** se as criaturas em encontro contam no mesmo **orçamento de cerca de 20 [HIP]** dos combatentes com corpo. **Recomendação:** sim, no mesmo orçamento (um número só em `data/`).
- **Criatura contra NPC fora do foco [EM ABERTO]:** o `combat.md` prevê encontro em S1 (seção 3). Decidir se a criatura **age sobre NPCs sem corpo** (mundo independente do jogador, ao custo de mais regra) ou só quando há corpo. **Recomendação:** só com corpo na Fase 5 [LIM]; a ação abstrata fica para "depois".

## 7. Ameaça e o mapa de perigo (LW-157, LW-171)

- **`peek_threat(province_id)`** devolve um inteiro de **0 a 100**: a soma do peso `threat` (dado do tipo, [HIP]) das criaturas hostis vivas da província, dividida por uma escala em dados e limitada ao intervalo. É **consulta**: a `ecology` **não publica evento de ameaça** e **não altera** o risco das rotas nem a economia (a arquitetura 3.1 fala em "eventos: ameaça, esgotamento", mas nenhuma tarefa da Fase 5 os pede, e criá-los seria antecipação). **[EM ABERTO]** se a ameaça deve mudar o `risk` de uma rota ou o preço (cascata); **recomendação:** não nesta fase.
- **O que o mapa mostra [EM ABERTO]:** a DEC-184 lista **covis escondidos** como segredo (só depois de descobertos), mas **não diz** se a zona de perigo (a ameaça da província) e as criaturas soltas aparecem sempre. **Recomendação:** mostrar só a **zona de ameaça** (por província) e os **covis descobertos**; **nunca** criaturas individuais. A regra por tipo e o filtro são da ponte (`bridge.md`, LW-146e).

## 8. Ponto de reconhecimento (LW-160a, DEC-184 e DEC-191)

- **O que a `ecology` faz:** só **expõe** o estado dos covis e das criaturas por consulta; **não** decide o que é revelado e **não** marca "descoberto" (`character/knowledge`, `request_reveal`; `character.md`, seção E5).
- **Quem lista os segredos dentro do raio** quando o jogador usa um ponto de reconhecimento (**resolvido na LW-146g**, pelo que a LW-146f escreveu no `world.md`). **Todo segredo é um ponto de interesse do `world`**, o covil incluído, e **não há campo `secret`**: o que só aparece depois de descoberto é **regra por tipo de ponto**, do `character` (`peek_visible`, `character.md` E5; DEC-184). O `character` escuta a interação com o ponto (`InteractionPerformed`, que já existe), pede ao `world` os pontos dentro do raio **[HIP]** (`peek_points_within`, `world.md`, extensão da Fase 5) e **filtra pelo tipo** (`ruin`, `lair`); a `ecology` só expõe o estado do covil. **Minério:** o tipo `ore_deposit` **não existe** no `world` enquanto você não decidir (`world.md`, **[EM ABERTO]**), então o minério escondido **não** é segredo do protótipo; a mina continua sendo local de produção (LW-160). Fica para a LW-160a.

## 9. Dados (formato na LW-146f; nomes [PROPOSTA])

`data/creature_types.json` (id, `behavior`, `max_per_province`, `birth_interval_hours`, `aggro_radius_m`, `leash_radius_m`, `flee_radius_m`, `threat`), `data/lairs.json` (id, `poi_id`, `type_id`, `province_id`) e `data/ecology_params.json` (histerese, `max_s0_creatures`, escala da ameaça). **Tudo [HIP].** Tabelas **planas**, sem lista aninhada (`data.md`), validadas com arquivo, item e campo; referências a `poi_id` e `province_id` conferidas contra o `world`; **dado inválido para o jogo no início** (AGENTS 13.1.7).

## 10. Eventos

**Nenhum evento novo** da `ecology` (o catálogo `docs/events.md` não muda por este contrato). Ela **ouve** `CombatantDied` e **publica** só a intenção de ataque, que a 146f cataloga com o `npc`. Se uma tarefa futura precisar de um fato novo (por exemplo, "covil esvaziado" para a crônica), ele nasce nela, não aqui.

## 11. API (nomes [PROPOSTA])

| Nome | Tarefa | O que faz |
|---|---|---|
| `request_set_focus(actor_id, x_cm, z_cm)` / `request_clear_focus(actor_id)` | 157 | foco do LOD (a ponte passa a posição do jogador; mesmo padrão do `npc`) |
| `request_report_creature_positions(positions)` | 157 | posições dos corpos em S0, em lote |
| `request_set_bodies_available(available)` | 157 | interruptor de corpos, como o do `npc`: o jogo nasce **sem** corpos e quem liga é a apresentação |
| `request_spawn_creature(type_id, lair_id, cause_id)` | 162 | nasce **uma** criatura; respeita o limite; devolve `Result`; usado pelos eventos dinâmicos |
| `peek_creature(creature_id)` | 157 | tipo, covil, província, posição, alvo (cópia) |
| `peek_creature_bodies()` | 157 | quem tem corpo agora, em ordem crescente de ID |
| `peek_lair(lair_id)` / `peek_lairs()` | 160 | estado do covil; lista em ordem crescente |
| `peek_population(province_id, type_id)` / `peek_threat(province_id)` | 157 | contagem e ameaça (seção 7) |

**Códigos** (`Result.code`, prefixo `ECOLOGY_`): `ECOLOGY_UNKNOWN_CREATURE`, `ECOLOGY_UNKNOWN_TYPE`, `ECOLOGY_UNKNOWN_LAIR`, `ECOLOGY_AT_CAP`, `ECOLOGY_DATA_INVALID` e `ECOLOGY_INVALID_SAVE`. ID inexistente nunca derruba o jogo (AGENTS 13.1).

## 12. Save, validação e determinismo

- **`serialize`/`on_load`/`validate`/`debug_summary`** (AGENTS 4.15): o save guarda criaturas e covis em **ordem crescente de ID**; **não** guarda nível de LOD, corpos nem posição da apresentação. `validate()` aponta criatura de tipo ou covil desconhecido, população acima do limite, criatura morta no estado e posição fora do mapa. `on_load` valida **tudo** antes de alterar o estado. Save antigo: **rejeitado** com mensagem clara (DEC-186).
- **Determinismo:** só inteiros; sem `Dictionary` na ordem natural (regra do `MODELO.md`); sorteio só por `ctx.rng`; mesma semente e mesma sequência de passos, mesmo `state_hash`.

## 13. Testes necessários, por tarefa

- **LW-157:** o limite por província **nunca é excedido**, mesmo com muitos nascimentos e com `request_spawn_creature`; alternar S1 ↔ S0 **não duplica nem perde** criatura; criatura ataca pelas **mesmas regras** do `combat` (cenário com o `combat`); a morte remove a criatura **uma vez**; `peek_threat` fica entre 0 e 100 e cai quando a criatura morre; ida e volta de save; mesma semente, mesmo hash; roda **sem janela**.
- **LW-160:** cada covil existente nos dados e referenciado no `world`; `poi_id` ou `province_id` quebrado falha apontando arquivo, item e campo.
- **LW-160a:** só confere o que a `ecology` entrega (a lista de segredos é da regra da seção 8).

## 14. Extensões pendentes e pontos em aberto

- **Extensões de outros módulos (LW-146f):** `world` (tipos novos de ponto e campos opcionais; ponto de reconhecimento), `npc` e `docs/events.md` (o evento de intenção de ataque, compartilhado). Este contrato **não** edita esses arquivos.
- **Em aberto (decisão de jogo, de Arthur):** quem é alvo de quem (seção 2); covil esvaziado repovoa ou não (seção 3); recompensa de ruína (seção 4); o que o mapa de perigo mostra (seção 7).
- **Em aberto (técnico):** cadência de decisão em combate (seção 6); orçamento de corpóreos e criatura contra NPC fora do foco (seção 6); quem lista os segredos no raio (seção 8); vida entre encontros (seção 2).
- **Fora (depois):** chefe, domesticação, migração, fome e sobrepopulação, clima, caça por NPCs, troféus (seção 1).
