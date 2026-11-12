#!/bin/sh
# Diagnóstico econômico (12/11/2026): tools/measure_economy roda o jogo real sem janela e imprime o cabeçalho mais UMA linha CSV por dia,
# aceita semente, é determinista, concorda com a partida padrão, imprime o estado dos mercados com --markets e rejeita argumento ruim.
set -eu
project_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
output=$(mktemp "${TMPDIR:-/tmp}/measure_economy.XXXXXX")
second=$(mktemp "${TMPDIR:-/tmp}/measure_economy.XXXXXX")
trap 'rm -f "$output" "$second"' EXIT HUP INT TERM
runner="$project_dir/tools/measure_economy"
# Só as linhas da tabela: o cabeçalho (começa com "day,") e as de dado (começam com número); o resto é ruído do Godot ou linhas de comentário "#".
table_of() { grep -E '^(day|[0-9]+),' "$1"; }
if ! "$runner" --days 3 --seed 1 < /dev/null > "$output" 2>&1; then
    echo 'FALHA: measure_economy --days 3 --seed 1 deveria terminar com código 0'; cat "$output"; exit 1
fi
table_of "$output" > "$second"
rows=$(grep -cE '^[0-9]+,' "$second")
[ "$rows" -eq 4 ] || { echo "FALHA: esperava 4 linhas de dado (dias 0 a 3), vieram $rows"; cat "$output"; exit 1; }
columns=$(head -n 1 "$second" | awk -F, '{ print NF }')
bad=$(awk -F, -v n="$columns" 'NR > 1 && NF != n { count += 1 } END { print count + 0 }' "$second")
[ "$bad" -eq 0 ] || { echo "FALHA: $bad linha(s) com número de colunas diferente do cabeçalho ($columns)"; exit 1; }
for expected in 'day,alive,dead,' ',led_trade,' ',led_salary,' ',money_npc_alive,' ',money_site,' ',money_market,' ',sites_running,' ',food_market_' ',pmax_grain,pmin_grain,' ',problems,money_ok,goods_ok'; do
    head -n 1 "$second" | grep -F -- "$expected" > /dev/null || { echo "FALHA: cabeçalho sem '$expected'"; head -n 1 "$second"; exit 1; }
done
echo 'OK: cabeçalho e 4 linhas (dias 0 a 3), todas com o mesmo número de colunas'
# Cada dia fecha sem problema de validação, com o dinheiro e os bens conservados, e o dinheiro total nunca muda (nenhum burn na Fase 3).
header=$(head -n 1 "$second")
awk -F, -v header="$header" 'BEGIN { n = split(header, names, ",") ; for (i = 1; i <= n; i++) col[names[i]] = i }
    NR > 1 { if ($col["problems"] != 0 || $col["money_ok"] != 1 || $col["goods_ok"] != 1) { bad += 1 }
             if (NR == 2) { total = $col["money_total"] } else if ($col["money_total"] != total) { bad += 1 } }
    END { exit (bad > 0) }' "$second" || { echo 'FALHA: algum dia com problema de validação, conservação quebrada ou dinheiro total variando'; exit 1; }
echo 'OK: validate() vazio, dinheiro e bens conservados e dinheiro total constante em todos os dias'
"$runner" --days 3 --seed 1 < /dev/null > "$output" 2>&1
table_of "$output" > "$second.again"
cmp -s "$second" "$second.again" || { rm -f "$second.again"; echo 'FALHA: a mesma semente deveria dar a mesma tabela'; exit 1; }
rm -f "$second.again"
echo 'OK: mesma semente, mesma tabela'
"$runner" --days 3 < /dev/null > "$output" 2>&1
table_of "$output" > "$second.default"
cmp -s "$second" "$second.default" || { rm -f "$second.default"; echo 'FALHA: --seed 1 deveria dar a mesma tabela da partida padrão (start_default_game)'; exit 1; }
rm -f "$second.default"
echo 'OK: --seed 1 e a partida padrão (start_default_game) dão a mesma tabela'
"$runner" --days 6 --seed 2 < /dev/null > "$output" 2>&1
table_of "$output" | tail -n 1 > "$second.s2"
"$runner" --days 6 --seed 1 < /dev/null > "$output" 2>&1
table_of "$output" | tail -n 1 > "$second.s1"
if cmp -s "$second.s1" "$second.s2"; then rm -f "$second.s1" "$second.s2"; echo 'FALHA: sementes diferentes deveriam dar tabelas diferentes no dia 6'; exit 1; fi
rm -f "$second.s1" "$second.s2"
echo 'OK: semente diferente, tabela diferente'
"$runner" --days 1 --markets < /dev/null > "$output" 2>&1
[ "$(grep -c '^#market_money,' "$output")" -ge 1 ] && [ "$(grep -c '^#market,' "$output")" -ge 10 ] || { echo 'FALHA: --markets deveria imprimir #market_money e #market'; cat "$output"; exit 1; }
echo 'OK: --markets imprime o estado dos mercados'
if "$runner" --days abc < /dev/null > "$output" 2>&1; then
    echo 'FALHA: argumento inválido deveria falhar'; exit 1
fi
grep -F 'ERRO: argumento inválido' "$output" > /dev/null || { echo 'FALHA: mensagem de argumento inválido ausente'; cat "$output"; exit 1; }
if "$runner" --days -3 < /dev/null > "$output" 2>&1; then
    echo 'FALHA: dias negativos deveriam falhar'; exit 1
fi
if "$runner" --verbose < /dev/null > "$output" 2>&1; then
    echo 'FALHA: opção desconhecida deveria falhar'; exit 1
fi
echo 'OK: argumento inválido, dias negativos e opção desconhecida rejeitados'
echo 'measure_economy: aprovado em 6 casos válidos e 3 inválidos.'
