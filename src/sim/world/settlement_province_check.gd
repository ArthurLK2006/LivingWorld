class_name SettlementProvinceCheck
extends RefCounted
## Confere os povoados contra as províncias e as culturas (LW-118c; docs/modules/world.md, "Extensão da Fase 4", validação): todo povoado tem `province_id` e `culture_id`, e os dois existem; uma
## província `settled` tem pelo menos um povoado e uma `frontier` não tem nenhum. Cada povoado tem uma coluna só, então não há "mais de uma província". Falha com `PROVINCE_DATA_INVALID`, apontando
## arquivo, item e campo (o arquivo é o de `base_dir` com os nomes padrão). É função pura: não lê arquivo nenhum e não guarda nada.

const MAX_LISTED_IDS: int = 8


static func check(base_dir: String, provinces: Array[Province], settlements: Array[Settlement], cultures: Array[Culture]) -> Result:
	var bundle: DataBundle = DataBundle.new()
	var settlements_path: String = base_dir.path_join(SettlementLoader.DEFAULT_SETTLEMENTS_FILE)
	var provinces_path: String = base_dir.path_join(ProvinceLoader.DEFAULT_PROVINCES_FILE)
	var province_by_id: Dictionary[String, Province] = {}
	for province: Province in provinces:
		province_by_id[province.id] = province
	var culture_ids: Array[String] = []
	for culture: Culture in cultures:
		culture_ids.append(culture.id)
	var count_by_province: Dictionary[String, int] = {}
	for settlement: Settlement in settlements:
		_check_province_of(bundle, settlements_path, settlement, province_by_id, count_by_province)
		_check_culture_of(bundle, settlements_path, settlement, culture_ids)
	var province_ids: Array[String] = []
	province_ids.assign(province_by_id.keys())
	province_ids.sort()
	for province_id: String in province_ids:
		var province: Province = province_by_id[province_id]
		var settled_count: int = count_by_province.get(province_id, 0)
		if province.kind == Province.KIND_SETTLED and settled_count == 0:
			bundle.add_issue(provinces_path, province_id, "kind", "província 'settled' sem povoado; esperado ao menos 1 povoado com province_id '%s' em %s" % [province_id, settlements_path.get_file()])
		elif province.kind == Province.KIND_FRONTIER and settled_count > 0:
			bundle.add_issue(provinces_path, province_id, "kind", "província 'frontier' com %d povoado(s); esperado nenhum (a fronteira não tem povoado)" % settled_count)
	if bundle.is_valid():
		return Result.success()
	return Result.failure(ProvinceLoader.CODE_INVALID, bundle.describe_issues())


static func _check_province_of(bundle: DataBundle, path: String, settlement: Settlement, province_by_id: Dictionary[String, Province], counts: Dictionary[String, int]) -> void:
	if settlement.province_id.is_empty():
		bundle.add_issue(path, settlement.id, "province_id", "campo obrigatório ausente; esperado o id de uma província de %s" % ProvinceLoader.DEFAULT_PROVINCES_FILE)
	elif not province_by_id.has(settlement.province_id):
		bundle.add_issue(path, settlement.id, "province_id", "referência a id inexistente '%s'; esperado um de: %s" % [settlement.province_id, _listed(province_by_id.keys())])
	else:
		counts[settlement.province_id] = counts.get(settlement.province_id, 0) + 1


static func _check_culture_of(bundle: DataBundle, path: String, settlement: Settlement, culture_ids: Array[String]) -> void:
	if settlement.culture_id.is_empty():
		bundle.add_issue(path, settlement.id, "culture_id", "campo obrigatório ausente; esperado o id de uma cultura de %s" % CultureLoader.DEFAULT_CULTURES_FILE)
	elif not culture_ids.has(settlement.culture_id):
		bundle.add_issue(path, settlement.id, "culture_id", "referência a id inexistente '%s'; esperado um de: %s" % [settlement.culture_id, _listed(culture_ids)])


static func _listed(ids: Array) -> String:
	var sorted_ids: Array[String] = []
	sorted_ids.assign(ids)
	sorted_ids.sort()
	var listed: Array[String] = sorted_ids.slice(0, MAX_LISTED_IDS)
	return ", ".join(listed) + ("" if sorted_ids.size() <= MAX_LISTED_IDS else " e mais %d" % (sorted_ids.size() - MAX_LISTED_IDS))
