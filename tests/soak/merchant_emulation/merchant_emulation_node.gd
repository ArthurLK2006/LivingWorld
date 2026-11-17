extends Node
## LW-098h0a: o ponto de entrada do corredor `tests/soak/run_merchant_emulation`, o MESMO nas duas versões do motor. Em depuração o corredor roda a cena `merchant_emulation_main.tscn` pela linha de comando do editor; em release ela é a CENA
## PRINCIPAL de uma cópia do projeto (o release ignora `-s`; mesmo método do `npc_year_release_node.gd`). Argumentos depois de `--`: `--merchants N` (0), `--days D` (30), `--seed S` (1) e `--spread none|q7` (none). Imprime o resumo do
## `MerchantEmulation.Report`; sai com 0, com 1 se o jogo não montou ou a conferência (conservação, `validate`) falhou, e com 2 se um argumento é inválido. Comerciante morto NÃO é erro da ferramenta: é o achado que ela existe para mostrar.

const DEFAULT_DAYS: int = 30
const DEFAULT_SEED: int = 1
const EXIT_PROBLEM: int = 1
const EXIT_BAD_ARGUMENT: int = 2


func _ready() -> void:
	get_tree().quit(_run(OS.get_cmdline_user_args()))


func _arg(args: PackedStringArray, flag: String, fallback: String) -> String:
	var at: int = args.find(flag)
	return args[at + 1] if at >= 0 and at + 1 < args.size() else fallback


## O número não negativo do argumento, ou -1 se o texto não for um inteiro de 0 ou mais.
func _count(args: PackedStringArray, flag: String, fallback: int) -> int:
	var text: String = _arg(args, flag, str(fallback))
	return text.to_int() if text.is_valid_int() and text.to_int() >= 0 else -1


func _run(args: PackedStringArray) -> int:
	var merchants: int = _count(args, "--merchants", 0)
	var days: int = _count(args, "--days", DEFAULT_DAYS)
	var world_seed: int = _count(args, "--seed", DEFAULT_SEED)
	var spread: String = _arg(args, "--spread", MerchantEmulation.SPREAD_NONE)
	if merchants < 0 or days < 0 or world_seed < 0:
		print("ERRO: argumento inválido; esperado --merchants, --days e --seed inteiros de 0 ou mais (recebido: %s)" % " ".join(args))
		return EXIT_BAD_ARGUMENT
	print("EMULATION build=%s godot=%s merchants=%d days=%d seed=%d spread=%s" % ["debug" if OS.is_debug_build() else "release", Engine.get_version_info()["string"], merchants, days, world_seed, spread])
	var emulation: MerchantEmulation = MerchantEmulation.new()
	var error: String = emulation.start(world_seed, spread)
	if error.is_empty():
		error = emulation.create_merchants(merchants)
	if not error.is_empty():
		print("ERRO: " + error)
		return EXIT_PROBLEM
	var report: MerchantEmulation.Report = emulation.run(days)
	print(report.summary())
	emulation.finish()
	return 0 if report.is_sound() else EXIT_PROBLEM
