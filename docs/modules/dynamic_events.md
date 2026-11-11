# Contrato — eventos dinâmicos (parte `definitions` e `runtime` do módulo `events`)

Estado: **PLANEJADO (LW-146d, 11/11/2026).** Nenhuma classe, dado, evento ou comando deste arquivo existe no código; é desenho para a LW-162. Fontes: arquitetura 17.7 (ficha do `events`), 13.5 (cascata), 6.4 (tick) e 3.2; GDD 19 (eventos e acontecimentos dinâmicos) e 17.8; roadmap 5.D (LW-162) e 5.I (risco R5.6); DEC-069, DEC-070, DEC-100, DEC-179, DEC-180 e DEC-197. Rótulos: **decisão** (APROVADA, com o número da DEC), **[PROPOSTA]** (DEC PROPOSTA ou desenho deste contrato), **[HIP]**, **[EM ABERTO]** (nada é inventado aqui) e **[LIM]**. Nomes de tipos e de eventos são **genéricos e provisórios** (DEC-100).

**Qual "evento"? Três sentidos (GDD 19.1).** Este arquivo é só o sentido (3): o **evento de mundo** (seca, tumulto, aparição), um conteúdo em dados com condição, probabilidade e efeitos. O **fato no barramento** (`EventBus`, catálogo em `docs/events.md`) e a **crônica** são outras coisas; a crônica e a reputação são da Fase 4 e têm contrato próprio (`chronicle.md`, LW-126 em diante). O **arquivo de dados** se chama `events.json` por arquitetura (cap. 2 e 17.7), mas guarda **tipos de evento de mundo**, não o catálogo de fatos.

- **Responsabilidade:** criar e conduzir os **eventos de mundo** pelo ciclo do GDD 19.3 (semente, início, desenvolvimento, resposta, resolução, legado), aplicando os efeitos **só por comandos públicos** de outros módulos, declarados em dados (DEC-197). Entrega os **8 tipos iniciais** (DEC-180). **Não** é a crônica, **não** calcula reputação e **não** faz os efeitos por conta própria: cada efeito é um pedido ao módulo dono do dado.
- **Entradas:** o tick horário (arquitetura 17.7); a definição dos tipos em `data/`; eventos de outros módulos, quando um tipo nasce de um fato (seção 3); consultas `peek_*` para escolher o escopo.
- **Saídas:** os eventos `WorldEventStarted` e `WorldEventEnded` (seção 6); consultas `peek_*`; os pedidos de efeito aos módulos donos (seção 4).
- **Dependências permitidas:** `core`, `data`, `world` (camada 2). **Para os efeitos, nenhum import direto dos outros módulos:** a ligação é por uma interface injetada (seção 4, que também explica o porquê).
- **Dados controlados:** `EventInstance` (um evento ativo), o relógio de recarga por tipo e escopo e o contador de eventos ativos. Nada dos módulos que sofrem os efeitos.
- **Interfaces de comunicação:** seções 6 e 9.
- **Testes necessários:** seção 11 (LW-162).

## 1. O que entra e o que não entra

- **Entra:** o motor em dados, os 8 tipos da seção 5 e os dois eventos de ciclo de vida. **Ataque a caravana fica só na LW-139** (DEC-197); não é um dos 8.
- **Sem diretor (DEC-069, PENDENTE):** o GDD 19.5 recomenda **sem diretor** no protótipo, com **ferramenta de depuração** que mede a densidade de eventos. Não há mecanismo que ajuste a frequência para o jogador. **[PROPOSTA]** seguir a recomendação; a decisão é de Arthur e o roadmap a lista entre as pendentes.
- **Fora (depois):** clima e seca por precipitação (DEC-060: `poor_harvest` é um evento por sorteio, não por clima), eventos sobrenaturais (GDD 19.2), resolução por **intervenção do jogador**, deserção e invasão (ficam com a `military`) e mais tipos além dos 8 (DEC-070 fala em 8 a 12; a DEC-180 fixou 8).

## 2. O ciclo de vida, na ordem do GDD 19.3

1. **Semente:** a cada tick horário, para cada tipo em ordem crescente de ID, se não há recarga e há vaga (seção 7), a condição do tipo é avaliada (seção 3).
2. **Início:** nasce uma `EventInstance` (ID de `ctx.ids`, nunca reutilizado) com tipo, escopo, `started_at` e `ends_at`; o `WorldEventStarted` é publicado e os efeitos de **início** são pedidos com o ID desse evento como `cause_id`.
3. **Desenvolvimento:** os efeitos **por passo** (a cada hora) enquanto o evento dura. **[PROPOSTA]** nenhum dos 8 tipos precisa deles; a coluna existe nos dados, vazia.
4. **Resposta:** NPCs e facções reagem **por conta própria**, escutando os fatos que os efeitos produzem. **Este módulo não escreve a resposta.**
5. **Resolução:** **por tempo** (`duration_hours`). Resolução por intervenção é **[EM ABERTO]** e fica para "depois". Publica `WorldEventEnded` e pede os efeitos de **fim** (por exemplo, desfazer o modificador de produção).
6. **Legado:** o efeito que persiste é do módulo dono; o registro histórico é da crônica (ela escuta os dois eventos).

## 3. Dados (formato na LW-146f; nomes [PROPOSTA])

- **Três tabelas planas** (o `data` não aceita objeto nem lista aninhada, `data.md`): `data/events.json` (um tipo por linha: id, `category`, `scope_kind`, `condition_kind`, parâmetros da condição, `chance_permille`, `duration_hours`, `cooldown_hours`, `severity`), `data/event_effects.json` (uma linha por efeito: `event_type_id`, `phase` = `start`, `tick` ou `end`, `effect_id` e parâmetros) e `data/event_params.json` (limite de eventos ativos e passo). **Tudo [HIP].**
- **Vocabulário fechado.** `condition_kind` vem de uma lista pequena: `chance` (probabilidade por hora) e `on_event` (nasce quando um fato listado é publicado). `effect_id` vem de uma lista fechada, **cada item ligado em código a um único comando público** (seção 4). **Por que fechado:** o AGENTS 4.17 proíbe reflexão e avaliação dinâmica; chamar um comando "pelo nome escrito no dado" seria isso. **Consequência [LIM]:** "tipo novo só por dados" vale **dentro do vocabulário**; efeito ou condição novos são uma tarefa de código com contrato.
- **Cada tipo declara os comandos que usa** (DEC-197): a coluna `effect_id` é a declaração, e o `check_architecture` (R5.6) confere que cada `effect_id` do código chama **só** um comando público (`request_*`) do módulo dono.
- **Escopo:** `scope_kind` é `settlement`, `route`, `poi` ou `province`; o alvo é sorteado, por `ctx.rng` em fluxo nomeado `events` (AGENTS 4.9), entre os existentes no `world`, **em ordem crescente de ID** antes do sorteio.

## 4. Como os efeitos chegam aos módulos [PROPOSTA técnica]

- **O problema:** a arquitetura 17.7 diz "demais módulos só por eventos"; a DEC-197 e a LW-162 dizem "comandos públicos". Se o `events` importasse as `api` de `economy`, `npc`, `ecology`, `world`, `politics` e `factions`, seriam **mais de 3 módulos importados** (alerta de acoplamento, AGENTS 5.2.4) e dependeria da Fase 4, que ainda não existe.
- **Recomendação (A):** o `events` define uma interface pequena, **`EffectPort`** (`apply(effect_id, scope_id, params, cause_id) -> Result`), e **recebe as implementações no construtor** (o mesmo padrão do `TradeRules`, DEC-141). Cada implementação é um adaptador fino em `src/app/` que traduz um `effect_id` **em um comando público** do módulo dono; o dono **continua o único que escreve** no seu dado. O adaptador **não tem regra de jogo**.
- **Alternativas:** (B) o `events` importa as `api` (simples, com o alerta acima); (C) cada módulo **escuta** `WorldEventStarted` e aplica o efeito sozinho, com dados próprios (zero acoplamento, mas os efeitos ficam espalhados em vários arquivos de dados e o "tipo novo só por dados" deixa de valer). **Escolha entre A, B e C: [EM ABERTO]**, antes da LW-162.
- **Efeito que falha [PROPOSTA]:** se um efeito de **início** devolve falha, o evento **não nasce** (nada é publicado) e o motivo vai ao log com contexto; se um efeito de **fim** falha, o evento termina assim mesmo e a falha é registrada. Nunca um estado pela metade.
- **Comandos que existem hoje são só de desenvolvimento** (`request_set_stock`, `request_raise_alarm`, `request_record_memory`, `request_adjust_relation`; AGENTS 12.6) e **não servem** a um evento do jogo. Todo efeito abaixo é uma **extensão de contrato** do módulo dono, pedida na LW-146f.

## 5. Os 8 tipos iniciais [PROPOSTA]

Genéricos e provisórios (DEC-100); a escolha final é de Arthur. A coluna "Comando" é o **nome proposto** do pedido; "Existe?" diz se o pedido já está em algum contrato.

| # | Tipo | Categoria (GDD 19.2) | Escopo | Em palavras | Comando (módulo) | Existe? |
|---|---|---|---|---|---|---|
| 1 | `poor_harvest` | natural | assentamento | a produção de um bem cai por alguns dias | `request_apply_production_modifier` (`economy`) | não |
| 2 | `route_landslide` | natural | rota | uma rota fecha por alguns dias e reabre | `request_close_route` e `request_open_route` (`world`) | **sim, mas só em desenvolvimento** (DEC-140) |
| 3 | `festival` | social | assentamento | a necessidade de convívio dos moradores é aliviada | `request_apply_need_pressure` (`npc`) | não |
| 4 | `unrest` | social | assentamento | a estabilidade do povoado cai | `request_adjust_stability` (`politics`) | **a confirmar** (Fase 4) |
| 5 | `messenger_visit` | social | assentamento | chega uma notícia que vira boato | `request_seed_rumor` (`npc`) | **a confirmar** (Fase 4) |
| 6 | `border_dispute_escalation` | político | província | a tensão entre duas facções sobe | `request_adjust_tension` (`factions`) | **a confirmar** (Fase 4) |
| 7 | `creature_sighting` | exploração | covil | uma criatura aparece perto de um covil | `request_spawn_creature` (`ecology`) | proposto em `ecology.md` |
| 8 | `ruin_rumor` | exploração | ponto | corre o boato de uma ruína (o jogador pode saber por NPCs) | `request_seed_rumor` (`npc`) | **a confirmar** (Fase 4) |

- **Honestidade sobre a Fase 4:** os contratos de `politics`, `factions` e de rumores ainda **não foram lidos** por este arquivo (não existem no `main`); os tipos 4, 5, 6 e 8 só valem **se** esses módulos entregarem um comando equivalente. Sem ele, o tipo é trocado por outro (por exemplo, mais um evento de `economy` ou `world`).
- **O encadeamento de causa** do GDD (a cadeia "Por quê?") vem do `cause_id`: o `WorldEventStarted` liga ao evento que o semeou (`on_event`) ou a nada, e os efeitos levam o ID dele.

## 6. Eventos publicados (a catalogar em `docs/events.md`, LW-146f)

| Evento | Publica | Ouvem (previstos) | Carga |
|---|---|---|---|
| `WorldEventStarted` | `events` | crônica, `npc`, `economy`, ponte | `instance_id`, `type_id`, `scope_kind`, `scope_id`, `severity` |
| `WorldEventEnded` | `events` | crônica, ponte | `instance_id`, `type_id`, `reason` (`expired`) |

Nenhum evento por passo (AGENTS 4.14). O `severity` (dado do tipo, **[HIP]**) é o que a crônica usa para o limiar (LW-126). Os nomes não colidem com os fatos que já existem; a 146f confere.

## 7. Frequência: vagas, recarga e densidade

- **Limite de eventos ativos** (`max_active_events`, **[HIP]**) e **recarga** por tipo e escopo (`cooldown_hours`): sem eles, uma sorte ruim vira avalanche (risco do soak, TA 17.7).
- **Densidade:** o `debug_summary()` conta eventos por tipo e janela; o **soak sem jogador** confere que a frequência fica **dentro da faixa** (arquitetura 17.7). A faixa é **[HIP]** e sai da medição, não daqui.
- **O mundo roda sem o jogador:** os eventos nascem da semente e do relógio da simulação, nunca da posição do jogador (princípio do GDD 19.1).

## 8. O jogador fica sabendo? (GDD 19.4) [EM ABERTO]

O GDD diz que o evento **não** é conhecido automaticamente: a informação chega por testemunha, boato, mensageiro ou mudança visível. Nenhuma DEC define **o que o painel da crônica mostra ao jogador**: tudo, ou só o que ele presenciou ou ouviu. **Recomendação:** o `events` **não filtra** (entrega `peek_active_events` sem filtro) e a **ponte** decide pelo que o jogador sabe, na mesma regra por tipo do mapa (DEC-184). Decisão de jogo, de Arthur.

## 9. API (nomes [PROPOSTA])

| Nome | Tarefa | O que faz |
|---|---|---|
| `peek_active_events(scope_kind, scope_id)` / `peek_event(instance_id)` | 162 | eventos ativos e um evento (cópia; ordem crescente de ID) |
| `request_trigger_event(type_id, scope_id, cause_id)` | 162 | **só em build de desenvolvimento** (AGENTS 12.6): dispara um tipo na hora, para teste e para a ferramenta de depuração |

**Códigos** (prefixo `WEVENT_`): `WEVENT_UNKNOWN_TYPE`, `WEVENT_BAD_SCOPE`, `WEVENT_AT_LIMIT`, `WEVENT_ON_COOLDOWN`, `WEVENT_EFFECT_FAILED`, `WEVENT_DATA_INVALID`, `WEVENT_INVALID_SAVE`. Há **só** o comando de desenvolvimento: nenhum comando de jogo (os eventos nascem do tick).

## 10. Save, validação e determinismo

- **`serialize`/`on_load`/`validate`/`debug_summary`** (AGENTS 4.15): guarda as instâncias ativas, as recargas e o contador, em **ordem crescente de ID**. `validate()` aponta evento de tipo desconhecido, `ends_at` antes de `started_at`, mais ativos que o limite e escopo que não existe no `world`. `on_load` valida **tudo** antes de alterar o estado. Save antigo: **rejeitado** com mensagem clara (DEC-186).
- **Determinismo:** só inteiros; sorteio só por `ctx.rng`, fluxo `events`, e o estado do gerador entra no save do `core`; tipos e escopos visitados por **ID crescente**, nunca pela ordem natural de um `Dictionary` (`MODELO.md`). Mesma semente, mesmos eventos.

## 11. Testes necessários (LW-162)

- **Condição:** o evento só ocorre quando a condição vale (`chance` com `chance_permille` zero nunca dispara; com o máximo, dispara na recarga); `on_event` só nasce com o fato listado.
- **Efeitos só por comando público:** o `check_architecture` reprova um `effect_id` que chame algo fora de `request_*` de outro módulo; falha de efeito de início **não cria** o evento; falha de efeito de fim termina e registra.
- **Ciclo:** semente, início, fim por tempo; o `WorldEventEnded` vem **uma vez**; os efeitos de fim desfazem o de início (cenário com um adaptador falso).
- **Limites:** vagas e recarga respeitadas; escopo inexistente é recusado; **tipo novo só por dados** (uma linha nova de `events.json` com `effect_id` já existente funciona sem mudar o código).
- **Determinismo e save:** ida e volta de save no meio de um evento; mesma semente, mesmo `state_hash`; roda **sem janela**; frequência dentro da faixa no soak.

## 12. Extensões pendentes e pontos em aberto

- **Extensões de outros módulos (LW-146f):** `economy` (`request_apply_production_modifier`, com o desfazer), `world` (liberar `request_close_route` e `request_open_route` ao jogo, com `cause_id`), `npc` (`request_apply_need_pressure` e, da Fase 4, `request_seed_rumor`), `politics` e `factions` (comandos de estabilidade e de tensão, **a confirmar nos contratos da Fase 4**), `ecology` (`request_spawn_creature`, já proposto em `ecology.md`) e `docs/events.md` (os dois eventos acima). Este contrato **não** edita esses arquivos.
- **Em aberto (técnico):** a ligação dos efeitos, A, B ou C (seção 4); o conflito de texto entre a arquitetura 17.7 ("só por eventos") e a DEC-197 ("comandos públicos"), a registrar em decisão.
- **Em aberto (decisão de jogo, de Arthur):** os 8 tipos (seção 5); o diretor de eventos (DEC-069); o que o jogador vê dos eventos (seção 8).
