class_name StraightRoads
extends RefCounted
## LW-099g (ajudante dos testes da vista das caravanas): o dado de apresentação do jogo SEM docas, pontos de passagem nem `settlement_a_id`, isto é, a estrada RETA de mercado a mercado (o dado de antes da opção B), derivado do arquivo real.
## Os testes que medem a MECÂNICA da vista (deslocamento lateral, giro, alcance, inclinação, parada, chegada) em cima de uma estrada reta de expectativas simples usam este dado; o dado real (docas e pontos) é medido pelos testes da LW-099g
## (`test_caravan_bodies_view_waypoints`, `test_caravan_route_clearance`, `test_caravan_bodies_view_determinism` e `test_caravan_waypoints_nothing_changes`).


## Lê o arquivo real e tira dele as docas e, de cada rota, `points_m` e `settlement_a_id`; o resto (vista, cargas e rotas) é o do jogo.
static func from_real_file() -> CaravanRoutesReader.LoadResult:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CaravanRoutesReader.DEFAULT_PATH))  # Variant: fronteira com o JSON, conferido abaixo
	var root: Dictionary = parsed
	root.erase(CaravanRoutesReader.DOCKS)
	for row: Dictionary in root[CaravanRoutesReader.ROUTES]:
		row.erase(CaravanRoutesReader.POINTS)
		row.erase(CaravanRoutesReader.SETTLEMENT_A)
	return CaravanRoutesReader.from_json(JSON.stringify(root), "dado de apresentação sem docas nem pontos (estrada reta)")
