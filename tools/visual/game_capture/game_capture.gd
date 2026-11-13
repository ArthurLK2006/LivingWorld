extends SceneTree
## CAP: ponto de entrada da captura do jogo real (ferramenta de desenvolvimento), lançado por tools/visual/run_game_capture com `-s` e os argumentos de usuário depois de `--`. O trabalho é da GameCaptureRun; aqui só o início e um
## limite de tempo, para uma falha inesperada (um erro de script para a captura sem encerrar o jogo) não deixar a janela aberta para sempre.

## Tempo máximo da execução inteira; os padrões levam poucos minutos, e passou disso o jogo encerra com erro.
const RUN_TIME_LIMIT_S: float = 900.0

var _run: GameCaptureRun
var _elapsed_s: float = 0.0


func _initialize() -> void:
	_run = GameCaptureRun.new()
	await _run.run(self, GameCaptureOptions.parse(OS.get_cmdline_user_args()))


func _process(delta: float) -> bool:
	_elapsed_s += delta
	if _elapsed_s < RUN_TIME_LIMIT_S:
		return false
	push_error("game_capture: a captura passou de %d s sem terminar; encerrando." % int(RUN_TIME_LIMIT_S))
	quit(1)
	return true
