class_name FrameVerdict
extends RefCounted
## ART-12, 7c-1b: o VEREDITO da DEC-119 de um ensaio do medidor de quadros (game_release_node.gd). Puro e sem flexibilizar nada: PASSA com a média de 60 fps ou mais E nenhum quadro acima de 33 ms.
## Num ensaio CURTO (`--segundos`, CURTA=1 no script) só se valida o instrumento: a DEC-119 só vale com as durações completas, e a linha diz isso NO LUGAR do veredito.

const MIN_FPS: float = 60.0
const MS_PER_SECOND: float = 1000.0


## A linha do veredito. `mean_ms` = média do quadro; `frames_over_limit` = quadros acima de 33 ms; `short_seconds` > 0 = ensaio curto (sem veredito).
static func line(mean_ms: float, frames_over_limit: int, short_seconds: float) -> String:
	if short_seconds > 0.0:
		return "  VALIDAÇÃO DO INSTRUMENTO: sem veredito DEC-119 (ensaio CURTO de %d s; a DEC-119 só vale com as durações completas)" % roundi(short_seconds)
	var fps: float = MS_PER_SECOND / maxf(mean_ms, 0.001)
	var passes: bool = fps >= MIN_FPS and frames_over_limit == 0
	return "  VEREDITO DEC-119: %s (média %.1f fps, %d quadros acima de 33 ms; a DEC-119 exige média de 60 fps ou mais e nenhum quadro acima de 33 ms)" % ["PASSA" if passes else "FALHA", fps, frames_over_limit]
