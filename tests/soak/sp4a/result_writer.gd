class_name Sp4aResultWriter
extends RefCounted
## SPIKE descartável (LW-033/SP4a). Monta o quadro "RESULTADO PARA COLAR" (item 12 da tarefa) e
## salva texto + JSON em tests/soak/sp4a/resultados/ (ENTRAM no commit; nenhum dado pessoal).

const COLUMNS: Array[String] = [
	"Máquina", "Renderizador", "Nível", "Terreno", "Cenário", "FPS médio", "FPS mín",
	"1% pior", "p99 (ms)", "Engasgos >33 ms", "Memória (MB)", "Vídeo (MB)", "Observação",
]

var _rows: Array[Dictionary] = []
var _machine_label: String = ""
var _machine_headers: Array[Dictionary] = []


func set_machine_label(label: String) -> void:
	_machine_label = label


## Cabeçalho de máquina (item 9 da tarefa): um por processo/renderizador, acumulado entre eles.
func add_machine_header(header: Dictionary) -> void:
	_machine_headers.append(header)


func machine_headers() -> Array[Dictionary]:
	return _machine_headers


func add_row(renderer: String, level: String, terrain: String, scenario: String, stats: Dictionary, observation: String) -> void:
	_rows.append({
		"maquina": _machine_label,
		"renderizador": renderer,
		"nivel": level,
		"terreno": terrain,
		"cenario": scenario,
		"fps_medio": stats.get("fps_medio", 0.0),
		"fps_min": stats.get("fps_min", 0.0),
		"fps_1pct_pior": stats.get("fps_1pct_pior", 0.0),
		"p99_ms": stats.get("p99_ms", 0.0),
		"engasgos_33ms": stats.get("engasgos_33ms", 0),
		"memoria_mb": stats.get("memoria_mb", 0.0),
		"video_mb": stats.get("video_mb", 0.0),
		"observacao": observation,
	})


func rows() -> Array[Dictionary]:
	return _rows


func table_text() -> String:
	var lines: Array[String] = []
	lines.append(" | ".join(COLUMNS))
	for row: Dictionary in _rows:
		lines.append(" | ".join([
			str(row["maquina"]), str(row["renderizador"]), str(row["nivel"]), str(row["terreno"]), str(row["cenario"]),
			"%.1f" % row["fps_medio"], "%.1f" % row["fps_min"], "%.1f" % row["fps_1pct_pior"],
			"%.1f" % row["p99_ms"], str(row["engasgos_33ms"]), "%.1f" % row["memoria_mb"], "%.1f" % row["video_mb"],
			str(row["observacao"]),
		]))
	return "\n".join(lines)


func print_result_block() -> void:
	print("RESULTADO PARA COLAR")
	for header: Dictionary in _machine_headers:
		print("Máquina: ", JSON.stringify(header))
	print(table_text())


## run_id: identifica sistema e data, sem nome de computador/usuário (ex.: "windows_2026-11-04_143000").
static func build_run_id() -> String:
	var now: Dictionary = Time.get_datetime_dict_from_system()
	return "%s_%04d-%02d-%02d_%02d%02d%02d" % [
		OS.get_name().to_lower(), now["year"], now["month"], now["day"], now["hour"], now["minute"], now["second"],
	]


func save_files(output_dir: String, run_id: String) -> void:
	DirAccess.make_dir_recursive_absolute(output_dir)
	var text_path: String = "%s/sp4a_%s.txt" % [output_dir, run_id]
	var text_file: FileAccess = FileAccess.open(text_path, FileAccess.WRITE)
	var header_lines: String = ""
	for header: Dictionary in _machine_headers:
		header_lines += "Máquina: %s\n" % JSON.stringify(header)
	text_file.store_string("RESULTADO PARA COLAR\n" + header_lines + table_text() + "\n")
	text_file.close()

	var json_path: String = "%s/sp4a_%s.json" % [output_dir, run_id]
	var json_file: FileAccess = FileAccess.open(json_path, FileAccess.WRITE)
	json_file.store_string(JSON.stringify({"run_id": run_id, "cabecalhos_maquina": _machine_headers, "resultados": _rows}, "  "))
	json_file.close()
