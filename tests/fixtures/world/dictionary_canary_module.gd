extends SimModule
## Módulo-CANÁRIO de determinismo (LW-029A; DEC-081; arquitetura 18.3). Só existe em testes.
## Guarda o estado num Dictionary cuja ordem de INSERÇÃO é diferente da ordem ORDENADA e usa a
## ordem em que visita as chaves para repartir os sorteios. O Godot preserva a ordem de inserção,
## mas o JSON do save volta com as chaves ordenadas: depois de carregar, a ordem "natural" muda.
## - `sorted_iteration = true`: visita por chaves ordenadas (o jeito certo); salvar e carregar no
##   meio NÃO muda o hash final.
## - `sorted_iteration = false`: visita pela ordem natural (o erro); o hash final muda, e o teste
##   que usa este módulo tem de acusar isso.
## Não leva `class_name`: só `tests/unit/test_dictionary_order_after_load.gd` o usa, por `preload`.

const ENTRY_KEYS_IN_INSERTION_ORDER: Array[String] = ["npc_30", "npc_10", "npc_50", "npc_20", "npc_40"]
const RNG_STREAM: String = "canary"
const MAX_DRAW: int = 1000000
const KEY_ENTRIES: String = "entries"
const ERROR_CODE: String = "CANARY_INVALID_SAVE"

var is_sorted_iteration: bool
var _ctx: SimContext
var _entries: Dictionary[String, int] = {}


func _init(sorted_iteration: bool) -> void:
	is_sorted_iteration = sorted_iteration


func setup(context: SimContext) -> void:
	_ctx = context


func on_new_game(_world_seed: int) -> void:
	_entries = {}
	for key: String in ENTRY_KEYS_IN_INSERTION_ORDER:
		_entries[key] = 0


## Cada chave recebe o próximo sorteio do fluxo: se a ordem de visita muda, o estado muda.
func tick(_elapsed_minutes: int) -> void:
	for key: String in _keys_in_visiting_order():
		_entries[key] = _entries[key] + _ctx.rng.range_int(RNG_STREAM, 1, MAX_DRAW)


func serialize() -> Dictionary:
	var entries: Dictionary = {}
	# A ordem não importa aqui: o JSON canônico grava as chaves ordenadas de qualquer jeito.
	for key: String in _entries:
		entries[key] = _entries[key]
	return {KEY_ENTRIES: entries}


## Só altera o estado se o dado for válido. Reconstrói o Dictionary na ordem em que o JSON o entrega
## (ordenada), que é justamente a ordem "natural" depois de carregar.
func on_load(data: Dictionary) -> Result:
	var raw_entries: Variant = data.get(KEY_ENTRIES)
	if typeof(raw_entries) != TYPE_DICTIONARY:
		return _invalid("'%s' ausente ou não é um objeto." % KEY_ENTRIES)
	var saved: Dictionary = raw_entries
	var restored: Dictionary[String, int] = {}
	for key: Variant in saved.keys():
		# Variant: valor cru do JSON, que grava todo número como decimal.
		var raw_value: Variant = saved[key]
		if typeof(key) != TYPE_STRING or not _is_whole_number(raw_value):
			return _invalid("entrada '%s' deve ter chave em texto e valor inteiro." % str(key))
		restored[str(key)] = int(raw_value)
	if restored.size() != ENTRY_KEYS_IN_INSERTION_ORDER.size():
		return _invalid("esperadas %d entradas, vieram %d." % [ENTRY_KEYS_IN_INSERTION_ORDER.size(), restored.size()])
	for expected_key: String in ENTRY_KEYS_IN_INSERTION_ORDER:
		if not restored.has(expected_key):
			return _invalid("falta a entrada '%s'." % expected_key)
	_entries = restored
	return Result.success()


func validate() -> Array[String]:
	var problems: Array[String] = []
	for key: String in ENTRY_KEYS_IN_INSERTION_ORDER:
		if not _entries.has(key):
			problems.append("DictionaryCanaryModule: falta a entrada '%s'." % key)
	return problems


func debug_summary() -> Dictionary:
	return {"entries": _entries.size(), "sorted_iteration": is_sorted_iteration}


func _keys_in_visiting_order() -> Array[String]:
	var names: Array[String] = []
	for key: Variant in _entries.keys():
		names.append(str(key))
	if is_sorted_iteration:
		names.sort()
	return names


func _is_whole_number(raw: Variant) -> bool:
	return typeof(raw) == TYPE_INT or (typeof(raw) == TYPE_FLOAT and raw == floorf(raw))


func _invalid(reason: String) -> Result:
	return Result.failure(ERROR_CODE, "DictionaryCanaryModule.on_load: %s" % reason)
