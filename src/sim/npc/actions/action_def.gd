class_name ActionDef
extends RefCounted
## Definição de uma ação do catálogo (LW-059; conteúdo de data/actions.json e das tabelas irmãs, somente leitura depois de montado;
## contrato em docs/modules/npc.md, seção 3). Reúne a linha da ação e as linhas de efeitos, condições e pesos de personalidade que
## apontam para ela. Só DESCREVE: quem confere as condições e aplica os efeitos é o `ActionRunner` (LW-060). Nada aqui é salvo.

## ESPELHO do vocabulário de tipos de local do world (LW-056); unificar na LW-061. `market_reserved` é reservado e nenhuma ação da
## Fase 2 o usa. Vazio em `place_kind` = a ação vale em qualquer lugar.
const PLACE_KINDS: Array[String] = ["home", "work", "rest", "social", "market_reserved"]
## Tipos de condição aceitos (lista fechada; tipo novo é código). Aqui `has_food` é só um NOME: quem o avalia é a LW-060 (com a
## LW-065). A regra de comparação de cada tipo (limite inclusivo ou não, janela de horas que cruza a meia-noite) também é da LW-060.
const CONDITION_NEED_AT_LEAST: String = "need_at_least"
const CONDITION_NEED_AT_MOST: String = "need_at_most"
const CONDITION_HOUR_BETWEEN: String = "hour_between"
const CONDITION_PLACE_HAS_ROOM: String = "place_has_room"
const CONDITION_HAS_FOOD: String = "has_food"
const CONDITION_KINDS: Array[String] = [CONDITION_NEED_AT_LEAST, CONDITION_NEED_AT_MOST, CONDITION_HOUR_BETWEEN, CONDITION_PLACE_HAS_ROOM, CONDITION_HAS_FOOD]
## `min_value` ou `max_value` que a condição não tem (os valores válidos são todos de 0 para cima).
const ABSENT: int = -1

var id: String
## Minutos de simulação. 0 = duração calculada em execução (hoje só `go_to_place`: distância dividida pela velocidade de caminhada).
var duration_min: int
## Tipo de local necessário (um de PLACE_KINDS) ou "" para qualquer lugar.
var place_kind: String
## De 0 a 100; só pesa na utilidade e nas reações.
var risk: int
var interruptible: bool
var effects: Array[ActionEffect] = []
var conditions: Array[ActionCondition] = []
var trait_weights: Array[ActionTraitWeight] = []


func _init(action_id: String, action_duration_min: int, action_place_kind: String, action_risk: int, action_interruptible: bool) -> void:
	id = action_id
	duration_min = action_duration_min
	place_kind = action_place_kind
	risk = action_risk
	interruptible = action_interruptible


## Efeito de uma ação sobre uma necessidade: `delta` é somado à pressão (negativo alivia), proporcional ao progresso.
class ActionEffect:
	extends RefCounted

	var need_id: String
	var delta: int

	func _init(effect_need_id: String, effect_delta: int) -> void:
		need_id = effect_need_id
		delta = effect_delta


## Pré-condição de uma ação. `need_id` só vale nos tipos de necessidade; `min_value` e `max_value` valem conforme o tipo
## (need_at_least usa min_value, need_at_most usa max_value, hour_between usa os dois); o que não vale fica ABSENT.
class ActionCondition:
	extends RefCounted

	var kind: String
	var need_id: String
	var min_value: int
	var max_value: int

	func _init(condition_kind: String, condition_need_id: String, condition_min_value: int, condition_max_value: int) -> void:
		kind = condition_kind
		need_id = condition_need_id
		min_value = condition_min_value
		max_value = condition_max_value


## Peso de um traço de personalidade na pontuação da ação (a conta é da LW-062).
class ActionTraitWeight:
	extends RefCounted

	var trait_id: String
	var weight: int

	func _init(weight_trait_id: String, trait_weight: int) -> void:
		trait_id = weight_trait_id
		weight = trait_weight
