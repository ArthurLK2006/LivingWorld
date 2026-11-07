class_name Sp6Constants
extends RefCounted
## LW-152 (SP6, DESCARTÁVEL): todos os valores do teste de combate. Cada um é uma hipótese [HIP] para Arthur ajustar jogando
## (AGENTS 3.3 e 4.6); nenhum é requisito nem decisão. Tempos em milissegundos, multiplicadores em porcentagem inteira.

## Habilidades, na ordem dos espaços da tela (Q, R, F): tabelas paralelas indexadas pela habilidade.
const SKILL_COUNT: int = 3
const NO_SKILL: int = -1
const SKILL_KEYS: Array[String] = ["Q", "R", "F"]
const SKILL_NAMES: Array[String] = ["Golpe pesado", "Golpe rápido", "Golpe perfurante"]
const SKILL_WINDUP_MS: Array[int] = [700, 200, 400]
const SKILL_RECOVERY_MS: Array[int] = [900, 400, 600]
const SKILL_DAMAGE: Array[int] = [30, 10, 16]
const SKILL_STAMINA: Array[int] = [30, 12, 20]
## Parte da redução da armadura que o golpe ignora, em %.
const SKILL_ARMOR_IGNORED_PCT: Array[int] = [0, 0, 50]

const AUTO_DAMAGE: int = 6
const AUTO_INTERVAL_MS: int = 1500
const AUTO_STAMINA: int = 4

const DUMMY_MAX_HP: int = 200
const DUMMY_RESPAWN_MS: int = 3000
## Frente do boneco: oeste, de frente para o nascimento (o jogador nasce a oeste dele).
const DUMMY_FRONT: Vector3 = Vector3(-1.0, 0.0, 0.0)
const DUMMY_DISTANCE_M: float = 8.0

const RANGE_CM: int = 250
const IMPACT_RANGE_GRACE_CM: int = 50
const INPUT_BUFFER_MS: int = 200

## Estamina guardada em milésimos de ponto: 12 por segundo = 12 milésimos por ms, sem perder fração.
const STAMINA_MAX: int = 100
const MILLI_PER_POINT: int = 1000
const STAMINA_REGEN_MILLI_PER_MS: int = 12
const STAMINA_REGEN_DELAY_MS: int = 1000

## Posição do atacante em relação à frente do boneco, pelo ângulo horizontal. Nos limites vale o grupo de MENOR bônus.
const POSITION_NAMES: Array[String] = ["Frente", "Lado", "Costas"]
const POSITION_PCT: Array[int] = [100, 125, 150]
const FRONT_MAX_ANGLE_DEG: float = 60.0
const SIDE_MAX_ANGLE_DEG: float = 120.0

## Armadura do boneco (tecla T troca, em ciclo).
const ARMOR_NAMES: Array[String] = ["nenhuma", "leve", "pesada"]
const ARMOR_REDUCTION_PCT: Array[int] = [0, 25, 50]

const PERCENT: int = 100
const DAMAGE_DIVISOR: int = 10000
const MIN_DAMAGE: int = 1

## Textos da tela, na ordem dos enums de Sp6Rules (SlotState e EventType); mensagem vazia = o evento não mostra mensagem.
const SLOT_STATE_NAMES: Array[String] = ["Pronto", "Preparo", "Recuperação", "Sem fôlego", "Longe demais", "Sem alvo", "Ocupado"]
const EVENT_MESSAGES: Array[String] = ["", "Errou", "Sem fôlego", "Longe demais", "Sem alvo", "Derrotado", ""]

## Apresentação (só visual): seleção por clique, brilho, número de dano e mensagem.
const PICK_RADIUS_M: float = 1.1
const PICK_HEIGHT_M: float = 0.9
const HIT_FLASH_MS: int = 100
const MESSAGE_MS: int = 800
const DAMAGE_NUMBER_MS: int = 900
const DAMAGE_NUMBER_RISE_MPS: float = 1.5
const MAX_STEP_MS: int = 250
