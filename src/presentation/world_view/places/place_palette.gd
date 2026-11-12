class_name PlacePalette
extends RefCounted
## Cor e tamanho provisórios da caixa de cada tipo de local (LW-074), todos [HIP] (Arthur ajusta olhando a tela). Os tipos são os do
## vocabulário do `world`, copiados como texto porque a apresentação não pode citar classes de src/sim; tests/unit/test_place_boxes.gd
## confere que seguem iguais. O tipo `market` (antes `market_reserved`) não tem caixa: não está aqui.

const KIND_HOME: String = "home"
const KIND_WORK: String = "work"
const KIND_REST: String = "rest"
const KIND_SOCIAL: String = "social"
## Vermelho, azul, violeta e amarelo: longe do verde do terreno, do laranja do jogador e do ciano dos marcadores.
const COLORS: Dictionary[String, Color] = {
	KIND_HOME: Color(0.80, 0.30, 0.25),
	KIND_WORK: Color(0.20, 0.35, 0.80),
	KIND_REST: Color(0.60, 0.35, 0.80),
	KIND_SOCIAL: Color(0.95, 0.85, 0.20),
}
## Largura em x, altura e profundidade em z (metros). A maior caixa (8 m) cabe folgada nos 14 m entre os locais dos povoados de teste.
const SIZES: Dictionary[String, Vector3] = {
	KIND_HOME: Vector3(5.0, 3.0, 5.0),
	KIND_WORK: Vector3(8.0, 4.0, 6.0),
	KIND_REST: Vector3(4.0, 2.5, 4.0),
	KIND_SOCIAL: Vector3(7.0, 3.5, 7.0),
}


## Só os quatro tipos acima são desenhados.
static func is_drawn(kind: String) -> bool:
	return COLORS.has(kind) and SIZES.has(kind)
