class_name SimEvent
extends RefCounted
## Base de todo evento da simulação (arquitetura 17.3): um fato já ocorrido, com carga pequena.
## Cada tipo de evento é uma subclasse própria, nomeada no passado em PascalCase, que chama
## `super("NomeDoEvento")` e consta em `docs/events.md`. `id`, `time` e `cause_id` são
## preenchidos pelo EventBus ao publicar; quem publica não os define.

## Valor de `cause_id` quando o evento não foi provocado por outro.
const NO_CAUSE: int = 0

var id: int = 0
var type: String
var time: int = 0
var cause_id: int = NO_CAUSE
## Importância de 0 a 100; define se vai para a crônica e se o jogador é avisado.
var severity: int = 0


func _init(event_type: String) -> void:
	type = event_type
