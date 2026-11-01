class_name SimModule
extends RefCounted
## Classe base de todo módulo da simulação (arquitetura 4.6). O `World` chama estas operações
## na mesma ordem para todos os módulos; cada módulo sobrescreve só o que precisa.
## Parâmetros sem uso levam `_`; `world_seed` evita o nome reservado `seed`.


## Criação: recebe o contexto com os serviços do núcleo (relógio, eventos, aleatoriedade, IDs).
func setup(_ctx: SimContext) -> void:
	pass


## Depois que todos os módulos existem: assinar eventos e conectar consultas.
func post_setup() -> void:
	pass


## Novo jogo: criar o estado inicial.
func on_new_game(_world_seed: int) -> void:
	pass


## Carregar: restaurar o estado a partir do que `serialize()` devolveu.
func on_load(_data: Dictionary) -> void:
	pass


## A cada passo de simulação, conforme a frequência do módulo.
func tick(_dt_sim: float) -> void:
	pass


## Salvar: estado em dados simples (números, texto, listas e dicionários).
func serialize() -> Dictionary:
	return {}


## Depois de carregar e em testes: lista de inconsistências (vazia se estiver tudo certo).
func validate() -> Array[String]:
	return []


## Resumo legível do estado para o painel de depuração.
func debug_summary() -> Dictionary:
	return {}


## Encerrar o mundo: soltar referências e cancelar assinaturas.
func teardown() -> void:
	pass
