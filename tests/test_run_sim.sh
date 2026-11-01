#!/bin/sh
# LW-020: tools/run_sim roda o mundo sem janela, imprime a data final e rejeita argumentos ruins.
set -eu
project_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
output=$(mktemp "${TMPDIR:-/tmp}/lw020.XXXXXX")
trap 'rm -f "$output"' EXIT HUP INT TERM
runner="$project_dir/tools/run_sim"
if ! "$runner" --days 30 --seed 1 > "$output" 2>&1; then
    echo 'FALHA: run_sim --days 30 --seed 1 deveria terminar com código 0'; cat "$output"; exit 1
fi
for expected in 'Dias simulados: 30' 'ano 1, dia 31, 00:00 (43200 minutos simulados)' 'Semente: 1' 'Problemas de validação: 0'; do
    if ! grep -F "$expected" "$output" >/dev/null; then
        echo "FALHA: saída sem '$expected'"; cat "$output"; exit 1
    fi
done
echo 'OK: run_sim --days 30 --seed 1'
if "$runner" --days abc > "$output" 2>&1; then
    echo 'FALHA: argumento inválido deveria falhar'; exit 1
fi
grep -F 'ERRO: argumento inválido' "$output" >/dev/null || { echo 'FALHA: mensagem de argumento inválido ausente'; cat "$output"; exit 1; }
echo 'OK: argumento inválido rejeitado'
if "$runner" --days -3 > "$output" 2>&1; then
    echo 'FALHA: dias negativos deveriam falhar'; exit 1
fi
echo 'OK: dias negativos rejeitados'
echo 'LW-020: run_sim aprovado em 1 caso válido e 2 inválidos.'
