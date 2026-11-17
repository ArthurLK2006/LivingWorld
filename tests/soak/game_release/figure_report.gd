class_name FigureReport
extends RefCounted
## ART-12, 7c-1: o texto do relatório do medidor de quadros (game_release_node.gd) sobre a FIGURA do Ice Warrior. Funções PURAS (sem nó, relógio nem janela), para poderem ser testadas
## (tests/unit/test_game_release_figure_report.gd). O veredito do ensaio continua o da DEC-119 e as seções do quadro não mudam; a figura entra só como informação e como AVISO de que a
## rodada "com a figura" mediu cápsulas (a figura que não nasceu, o NPC dela sem corpo em S0 ou parado no ensaio POVOADO). Cada trecho do relatório é uma LISTA de linhas
## (`header_lines`, `summary_lines`): quem acrescentar outro assunto ao relatório (o perfil de energia, a classificação, 7c-1b) acrescenta linhas à lista, sem mexer nestas.

const NOTE: String = "o veredito é o da DEC-119 (média de 60 fps ou mais e nenhum quadro acima de 33 ms); o delta de UMA figura é só informativo (0,033 ms por figura no estudo, provavelmente abaixo do ruído)"
const WARN_NO_FIGURE: String = "  ATENÇÃO: a área local tem figura, mas há 0 figuras ativas neste ensaio (o NPC dela não teve corpo em S0): estes números NÃO medem a figura."
const WARN_NO_BODY_SETTLEMENT: String = "  ATENÇÃO: o NPC da figura NÃO teve corpo em S0 no ensaio POVOADO (0 figuras ativas): estes números NÃO medem a figura."
const WARN_CAPSULE: String = "  ATENÇÃO: o NPC da figura teve corpo, mas SEM figura (cápsula; veja os avisos do jogo acima): estes números NÃO medem a figura."
const WARN_NOT_WALKING: String = "  ATENÇÃO: o NPC da figura teve corpo e figura, mas NÃO andou no ensaio POVOADO (is_walking nunca visto): estes números NÃO medem a figura andando."


## O que o medidor viu das figuras durante UM ensaio (cada olhada entra em `record`).
class Seen:
	extends RefCounted
	## O máximo de corpos com figura (`NpcView.has_figure`) e o número na última olhada.
	var max_figures: int = 0
	var last_figures: int = 0
	## O máximo de corpos de NPCs da área (com ou sem figura) e o `npc_id` do último visto (NO_ID = nenhum).
	var area_bodies: int = 0
	var npc_id: int = IdGenerator.NO_ID
	## Algum NPC da área foi visto com `is_walking()`.
	var walked: bool = false


	func record(figures: int, area_bodies_now: int, area_npc_id: int, walking: bool) -> void:
		max_figures = maxi(max_figures, figures)
		last_figures = figures
		area_bodies = maxi(area_bodies, area_bodies_now)
		npc_id = area_npc_id if area_npc_id != IdGenerator.NO_ID else npc_id
		walked = walked or walking


## O trecho do CABEÇALHO sobre a figura: a carga da cena (à parte) e a linha da área local.
static func header_lines(load_text: String, area_is_empty: bool, figure_ids: PackedStringArray, area_failure: String) -> PackedStringArray:
	return PackedStringArray([load_text, area_line(area_is_empty, figure_ids, area_failure)])


## A linha que diz se a rodada é COM ou SEM a figura: a área local vazia (o padrão: só cápsulas), inválida (`failure`: tudo cápsula, com o motivo) ou com figura(s).
static func area_line(is_empty: bool, figure_ids: PackedStringArray, failure: String) -> String:
	if not failure.is_empty():
		return "figuras: a área local é INVÁLIDA e o jogo roda só com cápsulas: %s" % failure
	if is_empty:
		return "figuras: nenhuma (a área local está vazia; o jogo roda só com cápsulas)"
	return "figuras: a área local tem a figura '%s'; %s" % ["', '".join(figure_ids), NOTE]


## A CARGA da cena principal, FORA das seções do quadro: ler o arquivo da cena e instanciar e adicionar `main.tscn` (onde o preparo da figura acontece), para comparar com e sem figura.
static func load_line(file_ms: float, add_ms: float) -> String:
	return "carga da cena principal (fora das seções do quadro; o preparo da figura acontece aqui): ler o arquivo %.1f ms, instanciar e adicionar %.1f ms" % [file_ms, add_ms]


## O trecho do RESUMO de um ensaio sobre a figura: as "figuras ativas" (corpos com figura, no máximo e na última olhada, entre `max_bodies`) e os avisos. Vazio com a área sem figura:
## a rodada sem figura não imprime nada a mais.
static func summary_lines(area_has_figure: bool, is_settlement: bool, max_bodies: int, seen: Seen) -> PackedStringArray:
	var lines: PackedStringArray = PackedStringArray()
	if not area_has_figure:
		return lines
	var who: String = "NPC da figura: %d" % seen.npc_id if seen.npc_id != IdGenerator.NO_ID else "o NPC da figura não teve corpo"
	lines.append("  figuras ativas: máximo %d, no fim %d, de no máximo %d corpos; %s" % [seen.max_figures, seen.last_figures, max_bodies, who])
	lines.append_array(warnings(is_settlement, seen))
	return lines


## Os avisos de um ensaio (vazio = nada a avisar). Só o POVOADO exige o andar: nos outros ensaios a figura parada é normal.
static func warnings(is_settlement: bool, seen: Seen) -> PackedStringArray:
	var lines: PackedStringArray = PackedStringArray()
	if seen.area_bodies == 0:
		lines.append(WARN_NO_BODY_SETTLEMENT if is_settlement else WARN_NO_FIGURE)
	elif seen.max_figures == 0:
		lines.append(WARN_CAPSULE)
	elif is_settlement and not seen.walked:
		lines.append(WARN_NOT_WALKING)
	return lines
