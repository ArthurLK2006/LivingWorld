class_name ContractTemplateDef
extends RefCounted
## Uma linha de `data/economy/contract_templates.json` (LW-107c1; docs/economy/dados.md e docs/modules/economy.md, seção 8): um modelo de contrato de entrega do postador (`ContractPoster`, LW-107c2): o bem, a quantidade, o gatilho, o bônus em
## pontos-base sobre o valor-base do bem, o prazo em horas e o máximo de contratos do modelo abertos ao mesmo tempo, por mercado. SÓ LEITURA. Nenhum código o lê ainda; as faixas [HIP] e o vocabulário são conferidos pelo `ContractTemplateLoader`.

const TRIGGER_SHORTAGE: String = "shortage"
const TRIGGER_STANDING: String = "standing"
## Vocabulário fechado de `trigger`: `shortage` (o bem está com a escassez declarada no mercado) e `standing` (fixo: sempre que a regra anti-exploração permite).
const TRIGGERS: Array[String] = [TRIGGER_SHORTAGE, TRIGGER_STANDING]

var id: String
var kind: String
var good_id: String
var quantity: int
var trigger: String
var reward_margin_bp: int
var deadline_hours: int
var max_open: int


func _init(template_id: String, contract_kind: String, good: String, units: int, trigger_name: String, margin_bp: int, hours: int, open_cap: int) -> void:
	id = template_id
	kind = contract_kind
	good_id = good
	quantity = units
	trigger = trigger_name
	reward_margin_bp = margin_bp
	deadline_hours = hours
	max_open = open_cap
