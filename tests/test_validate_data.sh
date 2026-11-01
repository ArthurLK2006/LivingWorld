#!/bin/sh
# LW-025: prova que a validação de dados falha com mensagem legível ao quebrar um dado
# e volta a passar ao consertar, e que editar um dado válido não quebra o restante.
set -eu
project_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
work=$(mktemp -d "${TMPDIR:-/tmp}/lw025.XXXXXX")
trap 'rm -r "$work"' EXIT HUP INT TERM
cp "$project_dir"/tests/fixtures/data/frozen/*.json "$work/"
validator="$project_dir/tools/validate_data"
expect_valid() {
    label=$1
    if ! "$validator" "$work" > "$work/output.log" 2>&1; then
        echo "FALHA: $label deveria passar"; cat "$work/output.log"; exit 1
    fi
    echo "OK: $label"
}
expect_invalid() {
    label=$1
    shift
    if "$validator" "$work" > "$work/output.log" 2>&1; then
        echo "FALHA: $label deveria falhar"; exit 1
    fi
    for fragment in "$@"; do
        if ! grep -F "$fragment" "$work/output.log" >/dev/null; then
            echo "FALHA: $label sem '$fragment' na mensagem"; cat "$work/output.log"; exit 1
        fi
    done
    echo "OK: $label"
}
expect_valid 'dados de teste originais'
# Edição válida: novo bem e nova oferta que o cita não quebram o resto.
printf '[\n{"id": "test_good_a", "name_key": "k", "base_price": 10},\n{"id": "test_good_b", "name_key": "k", "base_price": 25},\n{"id": "test_good_c", "name_key": "k", "base_price": 7}\n]\n' > "$work/goods.json"
printf '[\n{"id": "test_offer_a", "good": "test_good_c", "price_multiplier": 1.0, "source_recipe": "test_recipe_a"}\n]\n' > "$work/offers.json"
expect_valid 'edição válida (bem e oferta novos)'
# Quebra 1: referência a bem inexistente.
printf '[\n{"id": "test_offer_a", "good": "ghost_good", "price_multiplier": 1.0}\n]\n' > "$work/offers.json"
expect_invalid 'referência quebrada' 'offers.json' "item 'test_offer_a'" "campo 'good'" 'ghost_good'
# Quebra 2: valor fora da faixa.
printf '[\n{"id": "test_offer_a", "good": "test_good_a", "price_multiplier": 9}\n]\n' > "$work/offers.json"
expect_invalid 'valor fora da faixa' 'offers.json' "campo 'price_multiplier'" 'acima do máximo'
# Conserto: volta a passar.
cp "$project_dir/tests/fixtures/data/frozen/offers.json" "$work/offers.json"
expect_valid 'dado consertado'
echo 'LW-025: 3 casos válidos e 2 quebras detectadas.'
