class_name EconomyModule
extends SimModule
## Casca do módulo `economy` (LW-088a; contrato em docs/modules/economy.md, seção 2). Existe só para a economia entrar no `World` ANTES do
## `npc` (o `npc` vai abrir as contas ao criar NPCs, LW-089) e para o bloco `economy` aparecer no save e no `state_hash` (DEC-172). Não tem
## estado, dado, evento nem comportamento: o `Ledger` é a LW-088 e os bens, a LW-089. Por isso só `serialize` e `on_load` são sobrescritos;
## o resto do ciclo de vida fica com o padrão inofensivo do `SimModule`. A pasta `api/` fica vazia (só um README) até existir a primeira
## consulta ou comando; o `npc` só poderá citar classes de lá (regra E do `tools/check_architecture`, DEC-171).

const CODE_INVALID_SAVE: String = "ECON_INVALID_SAVE"


## Bloco vazio: o que entra no save e no hash é a PRESENÇA do módulo, não um estado.
func serialize() -> Dictionary:
	return {}


## Aceita só o bloco vazio. Qualquer chave vem de um layout que esta casca não conhece (por exemplo, um save de uma versão com `Ledger`);
## rejeitar com mensagem clara é a regra para dado de arquivo (AGENTS 12.6).
func on_load(data: Dictionary) -> Result:
	if data.is_empty():
		return Result.success()
	var names: PackedStringArray = PackedStringArray()
	for key: Variant in data.keys():
		names.append(str(key))
	names.sort()
	return Result.failure(CODE_INVALID_SAVE, "EconomyModule.on_load: o bloco 'economy' do save tem %d chave(s) (%s); esperado vazio, porque a casca da economia (LW-088a) ainda não guarda estado." % [names.size(), ", ".join(names)])
