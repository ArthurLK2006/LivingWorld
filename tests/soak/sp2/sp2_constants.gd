class_name Sp2Constants
extends RefCounted
## LW-071 (SP2, DESCARTÁVEL): todas as constantes do spike num lugar só. Tudo marcado [HIP] é hipótese de trabalho do spike, não requisito
## de jogo, e entra na tabela do relatório (docs/decisions/0009-spike-sp2-corpos-e-lod.md). Nada aqui vai para data/ nem para src/.

## --- Referências lidas do jogo (não são [HIP] do spike; ficam aqui só para o spike ter um nome curto). ---
## Passo de andar do PlayerBody (src/presentation/player/player_body.gd): referência do passo natural do corpo (P1).
const PLAYER_WALK_MPS: float = PlayerBody.WALK_SPEED_MPS
## Passo de correr do PlayerBody: teto da política P2.
const PLAYER_RUN_MPS: float = PlayerBody.RUN_SPEED_MPS
## Limite de inclinação do PlayerBody (graus), usado pelas duas navegações.
const MAX_SLOPE_DEGREES: float = PlayerBody.MAX_WALKABLE_SLOPE_DEGREES
## Contrato da LW-070: relato de posições em lote no máximo a cada 6 quadros de física.
const REPORT_EVERY_PHYSICS_FRAMES: int = PlayerBody.REPORT_EVERY_PHYSICS_FRAMES
## Segundos reais por minuto de jogo a 1x (core.md: DEFAULT_REAL_MS_PER_MINUTE).
const REAL_SECONDS_PER_GAME_MINUTE: float = float(SimClock.DEFAULT_REAL_MS_PER_MINUTE) / 1000.0

## --- Corpo e políticas de velocidade [HIP]. Velocidades em metros por segundo REAL a 1x; o corpo multiplica pela velocidade do relógio. ---
const NATURAL_SPEED_MPS: float = PLAYER_WALK_MPS
## Piso da P2 [HIP]: abaixo disso o corpo parece parado.
const P2_FLOOR_MPS: float = 0.8
## Distância [HIP] em que o corpo dá a chegada por cumprida.
const ARRIVE_TOLERANCE_M: float = 0.3
## Tolerância [HIP] das invariantes de posição (nascimento e saída): 5 cm.
const POSITION_TOLERANCE_M: float = 0.05
## Detector de teleporte [HIP]: salto entre dois quadros de física > velocidade máxima x delta x 1,5 + 5 cm.
const TELEPORT_FACTOR: float = 1.5
const TELEPORT_SLACK_M: float = 0.05
## Pool [HIP]: corpos criados de antemão; cresce só se faltar.
const POOL_PREWARM: int = 60
## Invariantes conferidas a cada N quadros [HIP].
const CHECK_EVERY_FRAMES: int = 30

## --- Desenho do corpo (DEC-120: forma simples). ---
const BODY_RADIUS_M: float = 0.3
const BODY_HEIGHT_M: float = 1.7
const NOSE_SIZE_M: float = 0.18
const COLOR_WALKING: Color = Color(0.20, 0.55, 0.95)
const COLOR_ACTING: Color = Color(0.25, 0.80, 0.30)
const COLOR_IDLE: Color = Color(0.70, 0.70, 0.70)
const LABEL_FONT_SIZE: int = 48
const LABEL_HEIGHT_M: float = 2.2

## --- Navegação [HIP]. ---
## N1: distância entre amostras de altura ao conferir a inclinação de um trecho reto.
const N1_SAMPLE_STEP_M: float = 2.0
## N2: tamanho da célula da grade e margem em volta do retângulo da rota.
const N2_CELL_M: float = 4.0
const N2_MARGIN_M: float = 64.0
## Código de superfície que a N2 bloqueia (data/world/surface_types.json: rock = 3).
const ROCK_SURFACE_ID: String = "rock"

## --- População e diretor (rotina fixa, sem pensamento). ---
const PEOPLE_PER_HOME: int = 5
const SETTLEMENT_A: String = "test_settlement_a"
const SETTLEMENT_B: String = "test_settlement_b"
## Etapas da rotina: tipo de local e ação feita nele (casa -> trabalho -> convívio -> descanso -> casa).
const ROUTINE_KINDS: Array[String] = [Place.KIND_WORK, Place.KIND_SOCIAL, Place.KIND_REST, Place.KIND_HOME]
const ROUTINE_ACTIONS: Array[String] = ["work", "talk", "rest", "wait"]
const NAME_KEY: String = "npc.name.villager"
const WORLD_SEED: int = 71

## --- Focos e ensaios [HIP]. ---
## Foco fixo do ensaio de carga (centro do povoado B, data/world/settlements.json) e o seu ID (não colide com IDs de ator, que são pequenos).
const FIXED_FOCUS_ID: int = 900000
const LOAD_TEST_MAX_S0: int = 100
const LOAD_SECONDS: float = 30.0
const CLOCK_SEGMENT_SECONDS: float = 20.0
const CLOCK_SPEEDS: Array[int] = [1, 2, 4, 8]
const HYSTERESIS_SECONDS: float = 20.0
const VIEW_SECONDS: float = 180.0
## Rota do ensaio de alternância (x, z em metros), pelo caminho z = 513 m: entra e sai do raio do povoado A três vezes.
const ROUTE_WAYPOINTS: Array[Vector2] = [Vector2(330.0, 513.0), Vector2(490.0, 513.0), Vector2(330.0, 513.0), Vector2(490.0, 513.0), Vector2(330.0, 513.0)]
## Faixa de histerese: o jogador vai e volta entre estes dois pontos (a cerca de 90 a 100 m dos locais mais a leste do povoado A).
const HYSTERESIS_POINTS: Array[Vector2] = [Vector2(440.0, 513.0), Vector2(452.0, 513.0)]
const ROUTE_EXIT: Vector2 = Vector2(490.0, 513.0)
const WAYPOINT_REACHED_M: float = 3.0
## Execução sem janela: o mesmo ensaio, mais curto (só ida e volta do povoado A).
const HEADLESS_WAYPOINTS: Array[Vector2] = [Vector2(330.0, 513.0), Vector2(490.0, 513.0), Vector2(330.0, 513.0)]
## Rotas de comparação da navegação no terreno real (de, para), em metros: r1 dentro do povoado A, r2 de A a B (~495 m), r3 pelo lado
## íngreme do morro da LW-047A, r4 pela pedra da colina grande.
const BENCH_ROUTES: Array[Array] = [
	["r1 povoado A", Vector2(285.0, 542.0), Vector2(355.0, 570.0)],
	["r2 de A a B", Vector2(320.0, 540.0), Vector2(800.0, 660.0)],
	["r3 morro íngreme", Vector2(130.0, 469.0), Vector2(200.0, 469.0)],
	["r4 pedra", Vector2(520.0, 300.0), Vector2(880.0, 300.0)],
]
const BENCH_REPEATS: int = 5
const SETTLE_TIMEOUT_SECONDS: float = 30.0
const AFTER_SETTLE_SECONDS: float = 2.0
