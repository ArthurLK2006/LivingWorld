class_name CharacterLocomotion
extends RefCounted
## Escolha do clipe e da escala de reprodução de uma figura inteira que anda (ART-12, entrega 7a; só apresentação): funções estáticas PURAS (sem Node, sem relógio, sem acaso). `pick(speed_mps, speeds)` recebe a velocidade do corpo (m/s) e as da figura (`speeds`: clipe -> m/s em que o pé de apoio fica colado ao chão; só `walk` e `jog` contam, e valor não positivo ou não finito é ignorado) e devolve o clipe, a escala de reprodução e o deslize (m/s que o pé de apoio ainda desliza no chão). Corpo parado (velocidade não positiva ou não finita) = `idle`, escala 1, deslize 0. Sem nenhuma velocidade de figura válida (a figura sem o campo `locomotion`, que só toca idle e walk, sem escala) = `walk`, escala 1, deslize 0. Com elas, cada clipe candidato toca com a escala `velocidade / velocidade do clipe` LIMITADA a [`MIN_SCALE`, `MAX_SCALE`], o deslize é `|velocidade - escala * velocidade do clipe|` e vence o clipe de MENOR deslize; no empate (`is_equal_approx`, a tolerância de ponto flutuante do motor) vence o de menor velocidade de clipe (o `walk`). A saída nunca tem NaN. Contrato: docs/modules/presentation.md.

const IDLE: String = "idle"
const WALK: String = "walk"
const JOG: String = "jog"
## Os clipes que contam, na ordem em que são avaliados (o `walk` primeiro: se tudo empatar, ele fica).
const CLIPS: PackedStringArray = [WALK, JOG]
## [HIP] Os limites da escala de reprodução: abaixo de 0,7 o passo vira câmera lenta e acima de 1,6 vira passo de desenho animado; fora deles o pé desliza em vez de a animação ceder.
const MIN_SCALE: float = 0.7
const MAX_SCALE: float = 1.6


## O clipe, a escala e o deslize para o corpo andando a `speed_mps`, dadas as velocidades da figura (ver o cabeçalho).
static func pick(speed_mps: float, speeds: Dictionary[String, float]) -> Pick:
	if not is_finite(speed_mps) or speed_mps <= 0.0:
		return Pick.new(IDLE)
	var best: Pick = null
	var best_clip_speed: float = 0.0
	for clip: String in CLIPS:
		var clip_speed: float = speeds[clip] if speeds.has(clip) else 0.0
		if not is_finite(clip_speed) or clip_speed <= 0.0:
			continue
		var factor: float = clampf(speed_mps / clip_speed, MIN_SCALE, MAX_SCALE)
		var slide: float = absf(speed_mps - factor * clip_speed)
		if best == null or _beats(slide, clip_speed, best.slide_mps, best_clip_speed):
			best = Pick.new(clip, factor, slide)
			best_clip_speed = clip_speed
	return best if best != null else Pick.new(WALK)


## O candidato (deslize e velocidade de clipe) ganha do melhor até agora: deslize menor; no empate, velocidade de clipe menor.
static func _beats(slide: float, clip_speed: float, best_slide: float, best_clip_speed: float) -> bool:
	if is_equal_approx(slide, best_slide):
		return clip_speed < best_clip_speed
	return slide < best_slide


## A escolha: o clipe (`idle`, `walk` ou `jog`), a escala de reprodução e o deslize (m/s).
class Pick:
	extends RefCounted

	var clip: String
	var scale: float
	var slide_mps: float

	func _init(pick_clip: String = CharacterLocomotion.IDLE, pick_scale: float = 1.0, pick_slide_mps: float = 0.0) -> void:
		clip = pick_clip
		scale = pick_scale
		slide_mps = pick_slide_mps
