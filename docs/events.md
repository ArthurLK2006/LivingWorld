# Catálogo de eventos

Todo evento do projeto (classe que estende `SimEvent`) entra aqui **ao ser criado**, com o nome em `PascalCase`, no passado, na primeira coluna. O `tools/check_architecture` falha se um evento do código não estiver nesta tabela.

Eventos catalogados: 1 (`InteractionPerformed`, LW-049).

| Evento | Publicador | Ouvintes | Carga | Entra na crônica? |
|---|---|---|---|---|
| `InteractionPerformed` | `world` (`InteractionService`, `src/sim/world/`), quando uma interação com um ponto de interesse é aceita | nenhum ainda | `actor_id` (ID do ator), `poi_id` (id de conteúdo do ponto), `kind` (tipo do ponto); `cause_id` pelo `EventBus` (`NO_CAUSE` quando ninguém o provocou; o do evento em tratamento quando publicado dentro de um ouvinte) | Não |
