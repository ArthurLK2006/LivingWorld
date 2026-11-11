class_name EconomySetup
extends RefCounted
## LW-090c: monta, a partir dos arquivos de `data/economy/`, TUDO o que o `EconomyModule` recebe pelo construtor (bens, tipos de dono, alvos de mercado, constantes de preço e produção), no mesmo padrão do `NpcSetup`: sem global e
## sem autoload, e qualquer arquivo ausente ou inválido vira UMA falha tratada (`result`, `ECONOMY_SETUP_INVALID`) com o assunto e a mensagem do carregador (arquivo, item e campo). Nunca lança erro nem escreve no log.

const CODE_INVALID: String = "ECONOMY_SETUP_INVALID"
const DEFAULT_DIR: String = "res://data/economy"

## Só vale se `result.ok`.
var result: Result = Result.success()
var definitions: EconomyDefinitions


## `is_development_build`: vem da fronteira do app (`OS.is_debug_build()`); a simulação nunca lê `OS`.
static func from_dir(data_dir: String = DEFAULT_DIR, is_development_build: bool = false) -> EconomySetup:
	var setup: EconomySetup = EconomySetup.new()
	var goods: GoodsLoader.LoadResult = GoodsLoader.load_dir(data_dir)
	if not goods.result.ok:
		return setup._fail("bens e tipos de dono", goods.result)
	var markets: MarketLoader.LoadResult = MarketLoader.load_dir(data_dir)
	if not markets.result.ok:
		return setup._fail("mercados e preços", markets.result)
	var production: ProductionLoader.LoadResult = ProductionLoader.load_dir(data_dir)
	if not production.result.ok:
		return setup._fail("produção", production.result)
	setup.definitions = EconomyDefinitions.new(goods.goods, goods.kinds, markets.targets, markets.params, is_development_build, null, production.recipes, production.params, production.sites)
	return setup


func _fail(subject: String, loaded: Result) -> EconomySetup:
	result = Result.failure(CODE_INVALID, "EconomySetup.from_dir: %s inválidos: %s" % [subject, loaded.message])
	return self
