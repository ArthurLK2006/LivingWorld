class_name Sp4aQualityLevels
extends RefCounted
## SPIKE descartável (LW-033/SP4a). Três níveis de qualidade, todos [HIP] — nenhum vira requisito
## do jogo aqui. Ponto de partida: o próprio texto da tarefa. Justificativa da escolha (minha):
## a distância de visão em chunks de 64 m cobre, no nível médio, ~320 m ao redor do jogador —
## compatível com o raio S0 de "dezenas a centenas de metros" da arquitetura (cap. 5.3) — e o
## espaçamento de vértice (4/2/1 m) é uma progressão simples de dobrar o detalhe a cada nível.

const LEVELS: Dictionary = {
	"baixo": {
		"largura": 1280, "altura": 720,
		"distancia_chunks": 3, "espaco_vertice": 4.0,
		"sombras": false, "msaa": 0,
	},
	"medio": {
		"largura": 1920, "altura": 1080,
		"distancia_chunks": 5, "espaco_vertice": 2.0,
		"sombras": true, "msaa": 0,
	},
	"alto": {
		"largura": 2560, "altura": 1440,
		"distancia_chunks": 8, "espaco_vertice": 1.0,
		"sombras": true, "msaa": 4,
	},
}

const ORDER: Array[String] = ["baixo", "medio", "alto"]


static func get_level(name: String) -> Dictionary:
	return LEVELS.get(name, {})


static func is_valid(name: String) -> bool:
	return LEVELS.has(name)
