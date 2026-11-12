#!/bin/sh
# LW-093a: prova que o verificador de ids de conteúdo passa com os dados certos e falha, apontando o arquivo e o id, quando um id citado some ou é trocado (constante do
# código e cada coluna que cita o id de outro módulo: need_id, occupation_id, settlement_id, place_id, work_place_id e workers_wanted), e que volta a passar ao consertar.
set -eu
project_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
work=$(mktemp -d "${TMPDIR:-/tmp}/lw093a.XXXXXX")
trap 'rm -r "$work"' EXIT HUP INT TERM
verifier="$project_dir/tools/check_content_ids"
tree="$work/tree"
# Árvore limpa: os dados reais e as constantes reais do npc e da economia.
fresh() {
    rm -rf "$tree"
    mkdir -p "$tree/src/sim/npc" "$tree/src/sim/economy" "$tree/src/sim/world"
    cp -R "$project_dir/data" "$tree/data"
    cp "$project_dir/src/sim/npc/decision/npc_thinker.gd" "$project_dir/src/sim/npc/social/social_actions.gd" "$tree/src/sim/npc/"
    cp "$project_dir/src/sim/economy/production/production_book.gd" "$tree/src/sim/economy/"
}
edit() { sed "$2" "$tree/data/$1" > "$work/edit.tmp" && mv "$work/edit.tmp" "$tree/data/$1"; }
sites() { printf '[\n%s\n]\n' "$1" > "$tree/data/economy/production_sites.json"; }
site() { printf '{"id": "site_x", "settlement_id": "%s", "place_id": "%s", "recipe_id": "bake_bread", "workers_wanted": %s}' "$1" "$2" "$3"; }
expect_valid() {
    if ! "$verifier" "$tree" > "$work/output.log" 2>&1; then echo "FALHA: $1 deveria passar"; cat "$work/output.log"; exit 1; fi
    echo "OK: $1"
}
expect_invalid() {
    label=$1
    shift
    if "$verifier" "$tree" > "$work/output.log" 2>&1; then echo "FALHA: $label deveria falhar"; cat "$work/output.log"; exit 1; fi
    for fragment in "$@"; do
        if ! grep -F -- "$fragment" "$work/output.log" > /dev/null; then echo "FALHA: $label sem '$fragment' na mensagem"; cat "$work/output.log"; exit 1; fi
    done
    echo "OK: $label"
    fresh
}
fresh
expect_valid 'dados e constantes reais'
sites "$(site test_settlement_a a_work_01 4)"
edit population.json 's/"work_place_id": "a_work_01"/"work_place_id": "a_work_01"/'
expect_valid 'local de produção e work_place_id certos'
sites "$(site test_settlement_a a_work_01 12)"
expect_valid 'equipe desejada igual à capacidade do local'
sites "$(site test_settlement_a a_work_01 4)"
fresh
edit economy/goods.json 's/"need_id": "hunger"/"need_id": "ghost_need"/'
expect_invalid 'need_id que não existe' 'economy/goods.json' "campo 'need_id'" 'ghost_need'
edit economy/recipes.json 's/"occupation_id": "farmer"/"occupation_id": "ghost_job"/'
expect_invalid 'occupation_id que não existe' 'economy/recipes.json' "campo 'occupation_id'" 'ghost_job'
sites "$(site ghost_town a_work_01 4)"
expect_invalid 'settlement_id que não existe' 'economy/production_sites.json' "campo 'settlement_id'" 'ghost_town'
sites "$(site test_settlement_a ghost_place 4)"
expect_invalid 'place_id que não existe' 'economy/production_sites.json' "campo 'place_id'" 'ghost_place'
sites "$(site test_settlement_a a_home_01 4)"
expect_invalid 'place_id que não é local de trabalho' "o local 'a_home_01' é do tipo 'home'"
sites "$(site test_settlement_a b_work_01 4)"
expect_invalid 'place_id de outro povoado' "o local 'b_work_01' é do povoado 'test_settlement_b'"
sites "$(site test_settlement_a a_work_01 4),
$(site test_settlement_a a_work_01 4)"
expect_invalid 'dois locais de produção no mesmo local' 'um local de produção por local'
sites "$(site test_settlement_a a_work_01 13)"
expect_invalid 'workers_wanted acima da capacidade' "campo 'workers_wanted'" 'passa da capacidade (12)'
edit population.json 's/"work_place_id": "a_work_01"/"work_place_id": "ghost_place"/'
expect_invalid 'work_place_id que não existe' 'population.json' "campo 'work_place_id'" 'ghost_place'
grep -v '"id": "flee"' "$project_dir/data/actions.json" > "$tree/data/actions.json"
expect_invalid 'id removido de actions.json' 'npc_thinker.gd' 'FLEE_ACTION_ID' '"flee"' 'data/actions.json'
grep -v '"id": "site"' "$project_dir/data/economy/owner_kinds.json" > "$tree/data/economy/owner_kinds.json"
expect_invalid 'tipo de dono removido' 'production_book.gd' 'KIND_SITE' 'data/economy/owner_kinds.json'
grep -v '"id": "help_received"' "$project_dir/data/memory_kinds.json" | sed 's/},$/}/' > "$tree/data/memory_kinds.json"
expect_invalid 'tipo de memória removido' 'social_actions.gd' 'HELP_MEMORY_KIND' 'data/memory_kinds.json'
printf 'const GHOST_NEED_ID: String = "ghost_need"\n' > "$tree/src/sim/npc/ghost.gd"
expect_invalid 'constante de necessidade que não existe' 'ghost.gd:1' 'GHOST_NEED_ID' 'data/needs.json'
rm "$tree/data/economy/goods.json"
expect_invalid 'tabela ausente' 'data/economy/goods.json: arquivo ausente'
# Nomes que NÃO são ids de conteúdo passam: chave de save, código de erro e `KIND_` fora da economia (tipo de local do world).
printf 'const KEY_ACTION_ID: String = "action_id"\nconst CODE_UNKNOWN_MEMORY_KIND: String = "NPC_UNKNOWN_MEMORY_KIND"\n' > "$tree/src/sim/npc/keys.gd"
printf 'const KIND_HOME: String = "home"\n' > "$tree/src/sim/world/place.gd"
expect_valid 'nomes que não são ids de conteúdo'
echo 'LW-093a: 4 casos válidos e 14 quebras detectadas.'
