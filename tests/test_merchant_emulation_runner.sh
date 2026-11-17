#!/bin/sh
# LW-098h0a: o corredor tests/soak/run_merchant_emulation, SEM janela, SEM Godot de verdade, SEM rede e SEM bateria: um Godot FALSO (GODOT_BIN) e um binário de release FALSO (PROBE/bin) registram cada chamada e imprimem as linhas do corredor (com 0 comerciantes: 10 s,
# 2 passos acima de 16,7 ms e 0 acima de 33; com N: 15 s, 22 e 5); um curl, um wget e um pmset FALSOS no PATH registram o uso. O projeto também é de mentira (um repositório descartável com o corredor copiado), então a cópia do --release é pequena e o
# projeto real nunca é tocado. Confere: o padrão e os argumentos que passam ao Godot; o --compare roda a base (0 comerciantes) E a execução com N, nessa ordem, e imprime as diferenças certas; a recusa de argumento ruim; o --release SEM binário recusa, sem baixar nada
# (nem curl nem wget) e sem rodar o Godot; o --release COM binário exporta o .pck UMA vez, roda o binário de release (não o Godot) e troca a cena principal SÓ NA CÓPIA; e o aviso quando a fonte de energia muda.
set -eu
project_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
work=$(CDPATH= cd -- "$(mktemp -d "${TMPDIR:-/tmp}/lw_emulation_test.XXXXXX")" && pwd)
trap 'rm -rf "$work"' EXIT HUP INT TERM
expect() { [ "$2" = "$3" ] || { echo "FALHA: $1: esperado '$3', veio '$2'"; cat "$work/log" 2> /dev/null; exit 1; }; echo "OK: $1"; }
expect_has() { case "$2" in *"$3"*) echo "OK: $1" ;; *) echo "FALHA: $1: sem '$3' em '$2'"; exit 1 ;; esac; }
expect_lacks() { case "$2" in *"$3"*) echo "FALHA: $1: não devia ter '$3'"; exit 1 ;; *) echo "OK: $1" ;; esac; }
proj=$work/proj; scene=res://tests/soak/merchant_emulation/merchant_emulation_main.tscn
mkdir -p "$proj/tests/soak" "$work/path" "$work/probe_vazio" "$work/probe_cheio/bin"
cp "$project_dir/tests/soak/run_merchant_emulation" "$proj/tests/soak/"
printf 'config_version=5\n[application]\nrun/main_scene="res://scenes/main.tscn"\n' > "$proj/project.godot"
git -C "$proj" init -q 2> /dev/null; git -C "$proj" add -A
git -C "$proj" -c user.name=teste -c user.email=teste@teste -c commit.gpgsign=false commit -qm teste
cat > "$work/emit" <<'FAKE'
#!/bin/sh
build=$1; shift; m=0; d=30; s=1; sp=none
while [ "$#" -gt 0 ]; do case "$1" in --merchants) m=$2 ;; --days) d=$2 ;; --seed) s=$2 ;; --spread) sp=$2 ;; esac; shift; done
if [ "$m" = 0 ]; then t=10.000; a=2; b=0; else t=15.000; a=22; b=5; fi
printf 'EMULATION build=%s godot=falso merchants=%s days=%s seed=%s spread=%s\n' "$build" "$m" "$d" "$s" "$sp"
printf 'SUMMARY alive_merchants=%s/%s arrivals=0 profit=0\n' "$m" "$m"
printf 'STEPS n=1440 total_s=%s median_ms=1.000 p95_ms=2.000 p99_ms=3.000 max_ms=4.000 over_16_7ms=%s over_33ms=%s\n' "$t" "$a" "$b"
FAKE
printf '#!/bin/sh\necho "GODOT $*" >> "$FAKE_LOG"\ncase "$1" in --version) echo 4.7.2.stable.falso; exit 0 ;; esac\ncase "$*" in\n    *--import*) exit 0 ;;\n    *--export-pack*) for last; do :; done; echo pck > "$last"; exit 0 ;;\nesac\nexec "$FAKE_EMIT" debug "$@"\n' > "$work/godot_falso"
printf '#!/bin/sh\necho "RELEASE $*" >> "$FAKE_LOG"\nexec "$FAKE_EMIT" release "$@"\n' > "$work/probe_cheio/bin/godot_release_falso"
for net in curl wget; do printf '#!/bin/sh\necho "$0 $*" >> "$FAKE_NET"\nexit 1\n' > "$work/path/$net"; done
printf '#!/bin/sh\nn=$(cat "$FAKE_PM"); n=$((n + 1)); echo "$n" > "$FAKE_PM"\nif [ "$n" -ge "${FAKE_PM_SWITCH_AT:-999}" ]; then echo "Now drawing from '"'Battery Power'"'"; else echo "Now drawing from '"'AC Power'"'"; fi\n' > "$work/path/pmset"
chmod +x "$work/emit" "$work/godot_falso" "$work/probe_cheio/bin/godot_release_falso" "$work/path/curl" "$work/path/wget" "$work/path/pmset"
export FAKE_LOG="$work/log" FAKE_NET="$work/net" FAKE_PM="$work/pm" FAKE_EMIT="$work/emit" GODOT_BIN="$work/godot_falso" PROBE="$work/probe_vazio" PATH="$work/path:$PATH"
corridor() { # roda o corredor do projeto de mentira (contadores zerados); $out = a saída, $rc = o código
    : > "$work/log"; : > "$work/net"; echo 0 > "$work/pm"; rc=0; out=$("$proj/tests/soak/run_merchant_emulation" "$@" 2>&1) || rc=$?
}
godot_runs() { grep -c "merchant_emulation_main.tscn -- " "$work/log" || true; }

corridor --merchants 3 --days 1 --seed 2 --spread q7
expect 'depuração: código 0' "$rc" 0
expect 'o Godot recebe a cena e os argumentos, UMA vez' "$(grep -c -- "^GODOT --headless --path $proj $scene -- --merchants 3 --days 1 --seed 2 --spread q7\$" "$work/log")" 1
expect_has 'imprime as linhas do corredor' "$out" 'STEPS n=1440'; expect_has 'imprime a fonte de energia' "$out" 'ENERGIA fonte=AC Power'
expect_lacks 'sem aviso de energia quando ela não muda' "$out" 'AVISO'
corridor
expect 'o padrão são 0 comerciantes, 30 dias, semente 1, spread none' "$(grep -c -- '-- --merchants 0 --days 30 --seed 1 --spread none$' "$work/log")" 1
corridor --merchants 3 --days 1 --compare
expect 'o --compare roda a base (0) E a execução com N, nessa ordem' "$(grep -o -e '--merchants [0-9]*' "$work/log" | tr '\n' ' ')" '--merchants 0 --merchants 3 '
expect_has 'a diferença do tempo total' "$out" 'total_s: base=10.000 with=15.000 delta=+5.000 (+50.0%)'
expect_has 'a diferença dos passos acima de 16,7 ms' "$out" 'over_16_7ms: base=2 with=22 delta=+20'
expect_has 'a diferença dos passos acima de 33 ms' "$out" 'over_33ms: base=0 with=5 delta=+5'
expect_has 'a NOTA: o aceite vale como AUMENTO sobre a BASE' "$out" 'AUMENTO sobre a BASE'
for bad in '--foo' '--merchants abc' '--days' '--spread foo' '--compare' '--seed -1'; do
    corridor $bad
    expect "recusa '$bad' com código 1, sem rodar o Godot" "$rc $(godot_runs)" '1 0'
done
corridor --release --merchants 3 --days 1
expect 'release SEM binário: recusa com código 1' "$rc" 1
expect_has 'diz que NÃO baixa nada' "$out" 'NÃO baixa nada'
expect 'não rodou o Godot (nem importou nem exportou)' "$(grep -c -e '--import' -e '--export-pack' -e 'merchant_emulation_main' "$work/log" || true)" 0
expect 'nenhum curl nem wget' "$(wc -c < "$work/net" | tr -d ' ')" 0
PROBE="$work/probe_cheio" corridor --release --compare --merchants 3 --days 1
expect 'release COM binário: código 0' "$rc" 0
expect 'exporta o .pck UMA vez' "$(grep -c -e '--export-pack' "$work/log")" 1
expect 'roda o binário de release 2 vezes (base e N) e o Godot do editor nenhuma' "$(grep -c '^RELEASE --headless -- --merchants' "$work/log") $(godot_runs)" '2 0'
expect_has 'a saída é do build de release' "$out" 'EMULATION build=release'; expect_has 'e traz a comparação' "$out" 'delta=+5.000 (+50.0%)'
copy=$(ls -d "$work"/probe_cheio/merchant_emulation/*/projeto/project.godot)
expect 'o .pck exportado fica ao lado do binário de release da cópia' "$(cat "$(ls -d "$work"/probe_cheio/merchant_emulation/*/execucao/emulation_release.pck)")" pck
expect 'a cena principal é trocada na CÓPIA' "$(grep -c "^run/main_scene=\"$scene\"" "$copy")" 1
expect 'e o projeto de mentira NÃO muda' "$(grep -c 'res://scenes/main.tscn' "$proj/project.godot")" 1
expect 'nenhum curl nem wget no release' "$(wc -c < "$work/net" | tr -d ' ')" 0
export FAKE_PM_SWITCH_AT=1
corridor --merchants 1 --days 1
expect 'na bateria desde o começo: roda e NÃO recusa' "$rc" 0; expect_has 'a fonte impressa é a bateria' "$out" 'ENERGIA fonte=Battery Power'
expect_lacks 'sem aviso quando a bateria não muda' "$out" 'AVISO'
export FAKE_PM_SWITCH_AT=2
corridor --merchants 1 --days 1
expect 'a fonte de energia mudou no meio: avisa e NÃO recusa' "$rc" 0; expect_has 'o aviso de energia' "$out" 'AVISO: a fonte de energia mudou'
echo 'run_merchant_emulation: aprovado (depuração, --compare, 6 recusas, release sem e com binário, bateria sem recusa, aviso de energia).'
