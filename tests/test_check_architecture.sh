#!/bin/sh
set -eu
project_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
fixture=$(mktemp -d "${TMPDIR:-/tmp}/lw012.XXXXXX")
trap 'rm -r "$fixture"' EXIT HUP INT TERM
mkdir -p "$fixture/src/core/rng" "$fixture/src/data" "$fixture/src/sim/world" "$fixture/src/presentation"
for dir in "$fixture/src/core" "$fixture/src/core/rng" "$fixture/src/data" "$fixture/src/sim" "$fixture/src/sim/world" "$fixture/src/presentation"; do
    printf 'Contrato de teste\n' > "$dir/README.md"
done
checker="$project_dir/tools/check_architecture"
printf 'func next():\n    return randi()\n' > "$fixture/src/core/rng/allowed.gd"
"$checker" "$fixture" || { echo 'FALHA: caso válido'; exit 1; }
check_violation() {
    label=$1
    expected=$2
    if "$checker" "$fixture" > "$fixture/output" 2>&1; then
        echo "FALHA: $label não foi detectada"; exit 1
    fi
    if ! grep -F "$expected" "$fixture/output" >/dev/null; then
        echo "FALHA: $label sem localização esperada"; cat "$fixture/output"; exit 1
    fi
    echo "OK: $label"
}
printf 'extends Node3D\n' > "$fixture/src/sim/world/violation.gd"
check_violation 'simulação usa Node' 'violation.gd:1:'
printf 'func x(): return randf()\n' > "$fixture/src/sim/world/violation.gd"
check_violation 'aleatoriedade fora de rng' 'violation.gd:1:'
printf 'func x(): return Time.get_ticks_msec()\n' > "$fixture/src/sim/world/violation.gd"
check_violation 'tempo do sistema' 'violation.gd:1:'
printf 'static var estado = 0\n' > "$fixture/src/sim/world/violation.gd"
check_violation 'estado estático' 'violation.gd:1:'
rm "$fixture/src/sim/world/violation.gd"
mkdir -p "$fixture/docs"
printf '| Evento | Publicador |\n|---|---|\n| `Declared` | world |\n' > "$fixture/docs/events.md"
printf 'class_name Declared\nextends SimEvent\nfunc _init() -> void:\n    super("Declared")\n' > "$fixture/src/sim/world/declared.gd"
"$checker" "$fixture" || { echo 'FALHA: evento catalogado deveria passar'; exit 1; }
printf 'class_name Rogue\nextends SimEvent\nfunc _init() -> void:\n    super("Rogue")\n' > "$fixture/src/sim/world/rogue.gd"
check_violation 'evento fora do catálogo' 'rogue.gd:1:'
printf 'class_name Declared\nextends SimEvent\nfunc _init() -> void:\n    super("Renamed")\n' > "$fixture/src/sim/world/rogue.gd"
check_violation 'nome de super() fora do catálogo' 'rogue.gd:4:'
rm "$fixture/src/sim/world/rogue.gd" "$fixture/src/sim/world/declared.gd"
rm "$fixture/src/sim/world/README.md"
check_violation 'contrato ausente' 'world/README.md'
echo 'LW-012: 1 caso válido e 5 violações detectadas.'
echo 'LW-016: 1 evento catalogado aprovado e 2 eventos fora do catálogo detectados.'
