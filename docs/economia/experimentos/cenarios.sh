#!/bin/sh
# Definição dos cenários (só funções de shell que alteram a CÓPIA exportada; nada toca o repositório). Usado por rodar_cenario.sh.
# Cada função recebe a pasta da cópia. Dados: `jq` sobre data/economy/*.json. Regra: `sed` sobre o código da cópia (protótipo, marcado "regra_").

jq_edit() {
    arquivo=$1
    filtro=$2
    tmp=$(mktemp)
    jq --tab "$filtro" "$arquivo" > "$tmp" && mv "$tmp" "$arquivo"
}

# --- "artificiais": só mexem em números, sem mudar de onde o dinheiro sai nem para onde vai ---
aplicar_art_saldos() { # capital de giro dos locais de 200 para 1000
    jq_edit "$1/data/economy/owner_kinds.json" 'map(if .id == "site" then .initial_balance = 1000 else . end)'
}
aplicar_art_precos() { # todo valor-base dobrado
    jq_edit "$1/data/economy/goods.json" 'map(.base_value *= 2)'
}
aplicar_art_saldos_salario1() { # capital de giro 1000 e salário de 2 para 1 por hora
    aplicar_art_saldos "$1"
    jq_edit "$1/data/economy/recipes.json" 'map(.wage_per_hour = 1)'
}

# --- "estruturais": mudam o caminho do dinheiro ou a produtividade, com dados que o contrato já prevê ---
aplicar_est_postos() { # os 6 postos de serviço do contrato (seção 6), folha de 1 por hora paga pela conta do mercado
    cat > "$1/data/economy/service_posts.json" <<'JSON'
[
	{"id": "post_a_guard", "settlement_id": "test_settlement_a", "place_id": "a_work_06", "occupation_id": "guard", "workers_wanted": 8, "wage_per_hour": 1},
	{"id": "post_a_innkeeper", "settlement_id": "test_settlement_a", "place_id": "a_work_07", "occupation_id": "innkeeper", "workers_wanted": 6, "wage_per_hour": 1},
	{"id": "post_b_guard", "settlement_id": "test_settlement_b", "place_id": "b_work_07", "occupation_id": "guard", "workers_wanted": 5, "wage_per_hour": 1},
	{"id": "post_b_innkeeper", "settlement_id": "test_settlement_b", "place_id": "b_work_08", "occupation_id": "innkeeper", "workers_wanted": 3, "wage_per_hour": 1},
	{"id": "post_c_guard", "settlement_id": "test_settlement_c", "place_id": "c_work_04", "occupation_id": "guard", "workers_wanted": 5, "wage_per_hour": 1},
	{"id": "post_c_innkeeper", "settlement_id": "test_settlement_c", "place_id": "c_work_05", "occupation_id": "innkeeper", "workers_wanted": 3, "wage_per_hour": 1}
]
JSON
}
aplicar_est_lotes() { # todo trabalhador pago produz: lotes por hora = trabalhadores desejados / trabalhadores por lote (arredondado para cima)
    jq_edit "$1/data/economy/recipes.json" 'map(.max_batches_per_hour = ({"grow_grain":3,"cut_wood":3,"mine_ore":2,"shear_wool":1,"mill_flour":2,"bake_bread":1,"saw_plank":2,"smelt_metal":2,"forge_tool":2,"weave_fabric":1}[.id]))'
}
aplicar_est_postos_lotes() {
    aplicar_est_postos "$1"
    aplicar_est_lotes "$1"
}

aplicar_est_c_comida() { # a comida do povoado C passa a cobrir 30 dias (a regra do contrato, seção 6 e Q17): pão com alvo 800 e estoque inicial 1600 (2 x o alvo, como a farinha do B; mais que isso estoura a capacidade de peso de 5000 do mercado)
    jq_edit "$1/data/economy/market_targets.json" 'map(if .settlement_id == "test_settlement_c" and .good_id == "bread" then .target_stock = 800 | .initial_stock = 1600 else . end)'
}
aplicar_est_manut() { # procura de ferramenta, tábua e tecido pelos próprios locais: período de manutenção dividido por 3 (mínimo 1 dia); só dados (plano B 1 da Q22)
    jq_edit "$1/data/economy/site_upkeep.json" 'map(.period_days = ([((.period_days / 3) | floor), 1] | max))'
}
aplicar_est_postos_c() {
    aplicar_est_postos "$1"
    aplicar_est_c_comida "$1"
}
aplicar_est_postos_lotes_c() {
    aplicar_est_postos_lotes "$1"
    aplicar_est_c_comida "$1"
}
aplicar_est_tudo() { # postos + lotes + comida de 30 dias do C + procura de manutenção
    aplicar_est_postos_lotes_c "$1"
    aplicar_est_manut "$1"
}

# --- protótipos de REGRA (mudam o contrato; só na cópia) ---
aplicar_regra_spread() { # a margem do spread deixa de ter piso de 1 (arredonda para baixo): o mercado não embolsa o arredondamento
    sed -i.bak 's/return ceil_div(price \* spread_bp, SPREAD_DENOMINATOR)/return IntMath.floor_div(price * spread_bp, SPREAD_DENOMINATOR)/' "$1/src/sim/economy/markets/price_math.gd"
    rm -f "$1/src/sim/economy/markets/price_math.gd.bak"
    grep -q 'IntMath.floor_div(price \* spread_bp' "$1/src/sim/economy/markets/price_math.gd" || { echo "ERRO: patch do spread não aplicou" >&2; exit 1; }
}

aplicar_est_tudo_spread() {
    aplicar_est_tudo "$1"
    aplicar_regra_spread "$1"
}
aplicar_est_tudo_saldos() { # a mesma base estrutural, mais o capital dos locais em 1000 (para ver o que o dinheiro extra acrescenta)
    aplicar_est_tudo "$1"
    aplicar_art_saldos "$1"
}

aplicar_regra_procura() { # protótipo: o povoado consome por dia 1/4 do alvo de cada bem que NÃO é comida (uso doméstico e obras); destrói do estoque do mercado (motivo `consumed`)
    arq="$1/src/sim/economy/support/economy_runtime.gd"
    python3 -I - "$arq" <<'PY'
import sys
path = sys.argv[1]
text = open(path, encoding="utf-8").read()
head = "static func close_day(state: EconomyState, events: EventBus) -> void:\n"
hook = head + (
    "\tfor market_id: int in state.markets.market_ids():\n"
    "\t\tfor good_id: String in state.markets.traded_goods(state.markets.settlement_of(market_id)):\n"
    "\t\t\tif good_id == \"grain\" or good_id == \"bread\":\n"
    "\t\t\t\tcontinue\n"
    "\t\t\tvar taken: int = mini(IntMath.floor_div(state.markets.target_of(market_id, good_id) + 3, 4), state.goods.quantity_of(market_id, good_id))\n"
    "\t\t\tif taken > 0:\n"
    "\t\t\t\tstate.goods.destroy(market_id, good_id, taken, GoodsStore.REASON_CONSUMED)\n"
)
if head not in text:
    sys.exit("ERRO: close_day não encontrado")
open(path, "w", encoding="utf-8").write(text.replace(head, hook, 1))
PY
    grep -q "GoodsStore.REASON_CONSUMED" "$arq" || { echo "ERRO: patch da procura não aplicou" >&2; exit 1; }
}
aplicar_est_postos_lotes_c_procura() {
    aplicar_est_postos_lotes_c "$1"
    aplicar_regra_procura "$1"
}
aplicar_est_tudo_procura() {
    aplicar_est_tudo "$1"
    aplicar_regra_procura "$1"
}
aplicar_est_postos_lotes_c_procura_spread() {
    aplicar_est_postos_lotes_c_procura "$1"
    aplicar_regra_spread "$1"
}
aplicar_est_postos_lotes_c_procura_saldos() {
    aplicar_est_postos_lotes_c_procura "$1"
    aplicar_art_saldos "$1"
}

aplicar_regra_folha() { # protótipo (plano B da Q22, para TODAS as receitas): hora em que o local para (NO_INPUT, OUTPUT_FULL ou NO_FUNDS) mas tem equipe, a folha é paga pela conta do MERCADO do povoado, como a dos postos
    arq="$1/src/sim/economy/production/production_book.gd"
    python3 -I - "$arq" <<'PY'
import sys
path = sys.argv[1]
text = open(path, encoding="utf-8").read()
anchor = "\t\t_sell_surplus(site_id, state, recipe)\n\t\tvar was_stopped: bool = state[KEY_STOPPED]\n"
hook = "\t\t_sell_surplus(site_id, state, recipe)\n" + (
    "\t\tif not reason.is_empty() and reason != NO_WORKER and _payer != null and recipe.wage_per_hour > 0:\n"
    "\t\t\tvar idle_market_id: int = _markets.market_of(state[KEY_SETTLEMENT])\n"
    "\t\t\tif idle_market_id != IdGenerator.NO_ID and _payer.can_pay(idle_market_id, recipe.wage_per_hour, state[KEY_WORKERS]):\n"
    "\t\t\t\t_payer.pay(idle_market_id, recipe.wage_per_hour, state[KEY_WORKERS])\n"
) + "\t\tvar was_stopped: bool = state[KEY_STOPPED]\n"
if anchor not in text:
    sys.exit("ERRO: âncora do hour_step não encontrada")
open(path, "w", encoding="utf-8").write(text.replace(anchor, hook, 1))
PY
    grep -q "idle_market_id" "$arq" || { echo "ERRO: patch da folha parada não aplicou" >&2; exit 1; }
}
aplicar_est_postos_lotes_c_folha() {
    aplicar_est_postos_lotes_c "$1"
    aplicar_regra_folha "$1"
}
aplicar_est_postos_lotes_c_folha_salario1() {
    aplicar_est_postos_lotes_c_folha "$1"
    jq_edit "$1/data/economy/recipes.json" 'map(.wage_per_hour = 1)'
}
aplicar_est_postos_lotes_c_procura_folha() {
    aplicar_est_postos_lotes_c_procura "$1"
    aplicar_regra_folha "$1"
}
aplicar_est_postos_lotes_c_procura_folha_salario1() {
    aplicar_est_postos_lotes_c_procura_folha "$1"
    jq_edit "$1/data/economy/recipes.json" 'map(.wage_per_hour = 1)'
}

aplicar_cenario() { # nome pasta
    case "$1" in
        base) ;;
        art_saldos) aplicar_art_saldos "$2" ;;
        art_precos) aplicar_art_precos "$2" ;;
        art_saldos_salario1) aplicar_art_saldos_salario1 "$2" ;;
        est_postos) aplicar_est_postos "$2" ;;
        est_lotes) aplicar_est_lotes "$2" ;;
        est_postos_lotes) aplicar_est_postos_lotes "$2" ;;
        est_c_comida) aplicar_est_c_comida "$2" ;;
        est_manut) aplicar_est_manut "$2" ;;
        est_postos_c) aplicar_est_postos_c "$2" ;;
        est_postos_lotes_c) aplicar_est_postos_lotes_c "$2" ;;
        est_tudo) aplicar_est_tudo "$2" ;;
        est_tudo_spread) aplicar_est_tudo_spread "$2" ;;
        est_tudo_saldos) aplicar_est_tudo_saldos "$2" ;;
        regra_procura) aplicar_regra_procura "$2" ;;
        est_postos_lotes_c_procura) aplicar_est_postos_lotes_c_procura "$2" ;;
        est_tudo_procura) aplicar_est_tudo_procura "$2" ;;
        est_postos_lotes_c_procura_spread) aplicar_est_postos_lotes_c_procura_spread "$2" ;;
        est_postos_lotes_c_procura_saldos) aplicar_est_postos_lotes_c_procura_saldos "$2" ;;
        regra_folha) aplicar_regra_folha "$2" ;;
        est_postos_lotes_c_folha) aplicar_est_postos_lotes_c_folha "$2" ;;
        est_postos_lotes_c_folha_salario1) aplicar_est_postos_lotes_c_folha_salario1 "$2" ;;
        est_postos_lotes_c_procura_folha) aplicar_est_postos_lotes_c_procura_folha "$2" ;;
        est_postos_lotes_c_procura_folha_salario1) aplicar_est_postos_lotes_c_procura_folha_salario1 "$2" ;;
        regra_spread) aplicar_regra_spread "$2" ;;
        *) echo "ERRO: cenário desconhecido: $1" >&2; exit 1 ;;
    esac
}
