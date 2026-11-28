class_name CaravanTrack
extends RefCounted
## O que a view guarda de UMA caravana vista: o trecho (rota e povoados) cuja estrada está montada, a pose (x, z e giro) do último quadro, se está no alcance, se o corpo que ela tem agora já recebeu a primeira pose e em que
## consulta foi vista (quem não foi vista na última chegou).

var seen: int = 0
var inside: bool = false
var posed: bool = false
## O giro já tem um valor de uma amostra anterior (a primeira amostra de uma caravana não é limitada).
var has_yaw: bool = false
var route_id: String = ""
var from_id: String = ""
var to_id: String = ""
var path: CaravanPath
var position: Vector2 = Vector2.ZERO
var yaw: float = 0.0
## CURVAS NATURAIS (nada disto é lido no modo de sempre): a estrada com arcos do trecho, a distância andada sobre o EIXO dela, a última fração `u` vista e a direção de chegada que o trecho herdou (zero: nenhuma).
var road: CaravanRoad
var s_m: float = 0.0
var last_u: float = 0.0
var arrival: Vector2 = Vector2.ZERO
## O trecho (e o resto da viagem desta caravana) usa o caminho de HOJE: a volta de cerca de 180 graus no povoado de passagem não tem arco (ver `ENTRY_MIN_FIT_SHARE`). Fica ligado até a caravana sumir da consulta ou o modo ser trocado.
var legacy: bool = false
