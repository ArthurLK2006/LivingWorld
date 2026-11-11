class_name TradeTerms
extends RefCounted
## As condições que as regras de comércio (`TradeRules`) dão a um bem, num mercado, para um ator (LW-091; docs/modules/economy.md, seção 5): proibido ou não, a tarifa em pontos-base (10000 = 1,0) e se exige licença.
## Na Fase 3 a regra é a neutra: nada proibido, tarifa 0, sem licença. SÓ LEITURA depois de montada.

var banned: bool
var tariff_bp: int
var needs_license: bool


func _init(is_banned: bool = false, tariff_basis_points: int = 0, requires_license: bool = false) -> void:
	banned = is_banned
	tariff_bp = tariff_basis_points
	needs_license = requires_license
