class_name PresenceFade
extends RefCounted
## LW-099d (viagem visível; SÓ apresentação): a DISSOLUÇÃO de 0,4 s com que um corpo desaparece ou aparece na partida da caravana (opção A de Arthur, 24/11/2026): o comerciante parado some suavemente onde estava e a
## caravana surge suave no ponto de saída, sem deslocamento lateral e sem tocar no tempo nem na posição lógica da simulação. O tempo é REAL (`_process(delta)`; o projeto não usa `Engine.time_scale`).
## `transparency` é a propriedade de INSTÂNCIA do `GeometryInstance3D` (0 = opaco, 1 = invisível): não duplica material, vale para todo corpo de primitivas e para uma figura, e mantém as sombras. Pela documentação do Godot 4.x (NÃO conferida
## no 4.7.2: a documentação não vem no binário usado aqui) ela só vale no Forward+ e no Mobile, o renderer oficial do projeto; no Compatibility seria ignorada. Só estáticos: quem guarda o tempo decorrido é o dono do corpo
## (`NpcBodiesView` na despedida, `CaravanView` na aparição).

## [HIP] Duração da dissolução (s): a que Arthur escolheu ("aproximadamente 0,4 segundo"); afinar na janela dele.
const DURATION_S: float = 0.4
const OPAQUE: float = 0.0
const INVISIBLE: float = 1.0


## A transparência de quem APARECE depois de `elapsed_s` segundos: 1 (invisível) no começo e 0 (opaco) em `DURATION_S`, linear, presa entre os dois. Tempo negativo vale 0 s e NaN também.
static func in_amount(elapsed_s: float) -> float:
	return INVISIBLE - out_amount(elapsed_s)


## A transparência de quem DESAPARECE depois de `elapsed_s` segundos: 0 (opaco) no começo e 1 (invisível) em `DURATION_S`, linear, presa entre os dois. Tempo negativo vale 0 s e NaN também.
static func out_amount(elapsed_s: float) -> float:
	if is_nan(elapsed_s):
		return OPAQUE
	return clampf(elapsed_s / DURATION_S, OPAQUE, INVISIBLE)


## Põe a transparência `amount` (presa entre 0 e 1; NaN é ignorado) em TODO `GeometryInstance3D` de `root` e dos seus descendentes, em qualquer profundidade (o próprio `root` também, se for um). Não cria objeto nenhum:
## percorre a árvore pelo índice dos filhos. `root` nulo não faz nada.
static func apply(root: Node, amount: float) -> void:
	if root == null or is_nan(amount):
		return
	var value: float = clampf(amount, OPAQUE, INVISIBLE)
	if root is GeometryInstance3D:
		(root as GeometryInstance3D).transparency = value
	for index: int in root.get_child_count():
		apply(root.get_child(index), value)
