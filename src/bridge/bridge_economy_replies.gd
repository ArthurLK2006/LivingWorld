class_name BridgeEconomyReplies
extends RefCounted
## Tipos de resposta da INSPEÇÃO da economia da ponte (LW-108b; contrato em docs/modules/bridge.md, "Inspeção da economia", e em docs/modules/tools.md, "Painel econômico"). Como em
## `BridgeInspectReplies`, cada resposta traz um `Result` e CÓPIAS dos valores, para quem consome (o painel econômico, em `src/tools/`) nunca precisar citar tipo de `sim/`. Todo dinheiro e
## toda quantidade são inteiros (AGENTS 4.11). Não tem estado nem método: é só o lugar dos tipos.


## Uma linha da conservação dos bens (`peek_economy_overview`): um bem que já teve movimento. `is_ok` é verdadeiro quando o que está em estoque é o criado menos o destruído.
class EconomyGoodsRow:
	extends RefCounted

	var good_id: String = ""
	var in_stock: int = 0
	var created: int = 0
	var destroyed: int = 0
	var is_ok: bool = true


## Uma linha do livro-razão (`peek_economy_overview`): o que um motivo já moveu, criou e destruiu em dinheiro.
class EconomyLedgerRow:
	extends RefCounted

	var reason: String = ""
	var moved: int = 0
	var created: int = 0
	var destroyed: int = 0


## Resposta de `peek_economy_overview`: os campos só valem se `result.ok`. `money_sum` é o dinheiro em circulação (a soma de todas as contas) e `is_money_ok` quer dizer soma = criado − destruído;
## `is_goods_ok` quer dizer que todas as linhas de `goods` fecham; `problems` é o `validate()` da economia (vazio quando está tudo são).
class EconomyOverviewReply:
	extends RefCounted

	var result: Result
	var money_sum: int = 0
	var money_created: int = 0
	var money_destroyed: int = 0
	var is_money_ok: bool = true
	var goods: Array[EconomyGoodsRow] = []
	var is_goods_ok: bool = true
	var ledger: Array[EconomyLedgerRow] = []
	var problems: Array[String] = []

	func _init(reply_result: Result) -> void:
		result = reply_result


## Uma linha de mercado: um bem negociado, com o estoque contra o alvo, o preço de tabela, a venda ao jogador (`ask`), a compra do jogador (`bid`) e se está em escassez.
class EconomyMarketRow:
	extends RefCounted

	var good_id: String = ""
	var stock: int = 0
	var target_stock: int = 0
	var price: int = 0
	var ask: int = 0
	var bid: int = 0
	var is_in_shortage: bool = false


## Um mercado: de qual assentamento, quanto dinheiro tem na conta e as linhas dos bens, por `good_id` crescente.
class EconomyMarketEntry:
	extends RefCounted

	var market_id: int = 0
	var settlement_id: String = ""
	var cash: int = 0
	var rows: Array[EconomyMarketRow] = []


## Resposta de `peek_economy_markets`: `markets` só vale se `result.ok`; em ordem crescente de `market_id`.
class EconomyMarketsReply:
	extends RefCounted

	var result: Result
	var markets: Array[EconomyMarketEntry] = []

	func _init(reply_result: Result, listed: Array[EconomyMarketEntry] = []) -> void:
		result = reply_result
		markets = listed


## Um local de produção. `reason` é `NO_WORKER`, `NO_INPUT`, `OUTPUT_FULL` ou `NO_FUNDS` quando parado e vazio quando roda; `efficiency_bp` e `batch_progress_bp` estão em pontos-base (10000 = 100%).
class EconomySiteEntry:
	extends RefCounted

	var site_id: int = 0
	var settlement_id: String = ""
	var place_id: String = ""
	var recipe_id: String = ""
	var occupation_id: String = ""
	var wage_per_hour: int = 0
	var workers_wanted: int = 0
	var workers_assigned: int = 0
	var is_running: bool = false
	var reason: String = ""
	var efficiency_bp: int = 0
	var batch_progress_bp: int = 0


## Resposta de `peek_economy_sites`: `sites` só vale se `result.ok`; em ordem crescente de `site_id`.
class EconomySitesReply:
	extends RefCounted

	var result: Result
	var sites: Array[EconomySiteEntry] = []

	func _init(reply_result: Result, listed: Array[EconomySiteEntry] = []) -> void:
		result = reply_result
		sites = listed
