#!/bin/sh
# LW-023: o comparador de picos distingue picos nos mesmos passos de picos que mudam de lugar.
set -eu
project_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
tool="$project_dir/tests/soak/compare_sp1_runs"
work=$(mktemp -d "${TMPDIR:-/tmp}/lw023cmp.XXXXXX")
trap 'rm -r "$work"' EXIT HUP INT TERM
line() { printf 'Passos mais lentos (indice:us): [%s]\n' "$1"; }
line '"100:9000", "5000:8000", "70000:7000", "200000:6500", "300000:6000"' > "$work/a.txt"
line '"100:9100", "5001:7900", "70000:7100", "200002:6400", "300000:6100"' > "$work/same.txt"
line '"11:9000", "999:8000", "123457:7000", "400001:6500", "500003:6000"' > "$work/other.txt"
line '"100:9000", "999:8000", "70000:7000", "400001:6500", "500003:6000"' > "$work/mixed.txt"
printf 'sem a linha esperada\n' > "$work/broken.txt"
expect() {
    label=$1; fragment=$2; shift 2
    out=$("$tool" "$@" 2>&1) || true
    printf '%s' "$out" | grep -F "$fragment" > /dev/null || { echo "FALHA: $label sem '$fragment' em: $out"; exit 1; }
    echo "OK: $label"
}
expect 'mesmos passos (inclui diferença de 1 e 2 passos)' 'MESMOS PASSOS' "$work/a.txt" "$work/same.txt"
expect 'picos que mudam de lugar' 'MUDAM DE LUGAR' "$work/a.txt" "$work/other.txt"
expect 'caso intermediário' 'INCONCLUSIVO' "$work/a.txt" "$work/mixed.txt"
expect 'arquivo sem a lista' 'ERRO: sem a linha' "$work/a.txt" "$work/broken.txt"
if "$tool" "$work/a.txt" > /dev/null 2>&1; then echo 'FALHA: com um só arquivo deveria falhar'; exit 1; fi
echo 'OK: um só arquivo é recusado'
echo 'LW-023: comparador de picos aprovado em 4 casos e 1 uso inválido.'
