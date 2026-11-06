#!/bin/sh
set -eu
project_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
fixture=$(mktemp -d "${TMPDIR:-/tmp}/lw012.XXXXXX")
trap 'rm -r "$fixture"' EXIT HUP INT TERM
mkdir -p "$fixture/src/core/rng" "$fixture/src/data" "$fixture/src/sim/world" "$fixture/src/presentation" "$fixture/src/app" "$fixture/src/persistence"
for dir in "$fixture/src/core" "$fixture/src/core/rng" "$fixture/src/data" "$fixture/src/sim" "$fixture/src/sim/world" "$fixture/src/presentation" "$fixture/src/app" "$fixture/src/persistence"; do
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
# LW-029A. Mesmo critério de `check_violation`, para o caso em que o projeto deve ser APROVADO.
check_passes() {
    label=$1
    if ! "$checker" "$fixture" > "$fixture/output" 2>&1; then
        echo "FALHA: $label deveria passar"; cat "$fixture/output"; exit 1
    fi
    echo "OK: $label"
}
# LW-029A. Escreve o conteúdo $2 em $fixture/$1, confere a violação (local $3, rótulo $4) e apaga o arquivo.
expect_violation() {
    mkdir -p "$(dirname "$fixture/$1")"
    printf '%s\n' "$2" > "$fixture/$1"
    check_violation "$4" "$3"
    rm "$fixture/$1"
    new_violations=$((new_violations + 1))
}
# LW-029A. Escreve o conteúdo $2 em $fixture/$1, confere que o projeto continua aprovado (rótulo $3) e apaga o arquivo.
expect_clean() {
    mkdir -p "$(dirname "$fixture/$1")"
    printf '%s\n' "$2" > "$fixture/$1"
    check_passes "$3"
    rm "$fixture/$1"
    new_clean=$((new_clean + 1))
}
new_violations=0
new_clean=0
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
printf '[application]\nconfig/name="X"\n\n[autoload]\n\nGameApp="*res://a.gd"\nSimulationHost="*res://b.gd"\nDebug="*res://c.gd"\nSettings="*res://d.gd"\n\n[debug]\nfoo=1\n' > "$fixture/project.godot"
"$checker" "$fixture" || { echo 'FALHA: autoloads permitidos deveriam passar'; exit 1; }
printf '[autoload]\n\nGameApp="*res://a.gd"\nRogue="*res://x.gd"\n' > "$fixture/project.godot"
check_violation 'autoload fora da lista' 'project.godot:4:'
rm "$fixture/project.godot"
# LW-029A (achado I2a): toda função de sorteio fora de core/rng é violação; nomes parecidos e core/rng não são.
for call in 'randi_range(1, 6)' 'randf_range(0.0, 1.0)' 'randfn(0.0, 1.0)' 'rand_from_seed(7)' 'items.shuffle()' 'items.pick_random()'; do
    expect_violation src/sim/world/violation.gd "func x(): return $call" 'violation.gd:1:' "aleatoriedade fora de rng: $call"
done
expect_clean src/sim/world/lookalike.gd 'func x(): return my_randi_range(1) + stream.range_int("a", 1, 2) + shuffled_order() + pick_random_name()' 'nomes parecidos com sorteio não são violação'
expect_clean src/core/rng/allowed_more.gd 'func x(): items.shuffle(); return randi_range(1, 6) + randf_range(0.0, 1.0)' 'sorteio dentro de core/rng é permitido'
# LW-029A (achado I2b): tempo do sistema e estado estático valem em todas as pastas onde a simulação mora.
for dir in core app data persistence sim; do
    expect_violation "src/$dir/violation.gd" 'func x(): return Time.get_ticks_msec()' 'violation.gd:1:' "tempo do sistema em src/$dir"
    expect_violation "src/$dir/violation.gd" 'static var estado = 0' 'violation.gd:1:' "estado estático em src/$dir"
done
expect_clean src/core/static_function.gd 'static func helper() -> int: return 1' 'static func não é estado estático'
expect_clean src/presentation/clock_label.gd 'var started = Time.get_ticks_msec()' 'tempo do sistema na apresentação não é regra da simulação'
# LW-029A: a única exceção é Time.get_ticks_usec no scheduler.gd (medição que não entra no estado).
expect_clean src/core/scheduler/scheduler.gd 'var source = Time.get_ticks_usec' 'Time.get_ticks_usec no scheduler.gd é a exceção'
expect_violation src/core/scheduler/scheduler.gd 'var source = Time.get_ticks_msec()' 'scheduler.gd:1:' 'outro Time.get_* no scheduler.gd'
expect_violation src/core/scheduler/scheduler.gd 'var source = OS.get_ticks_msec()' 'scheduler.gd:1:' 'OS.get_* no scheduler.gd'
expect_violation src/core/other_clock.gd 'var source = Time.get_ticks_usec' 'other_clock.gd:1:' 'Time.get_ticks_usec fora do scheduler.gd'
# LW-029A (achado I2c): a regra de apresentação também vale para src/persistence. src/app fica de fora (proposta de desvio).
expect_violation src/persistence/violation.gd 'extends Node3D' 'violation.gd:1:' 'Node em src/persistence'
expect_violation src/persistence/violation.gd 'func x(): return get_node("/root/GameApp")' 'violation.gd:1:' 'get_node em src/persistence'
expect_clean src/persistence/clean.gd 'extends RefCounted' 'src/persistence sem Node'
expect_clean src/app/autoload_like.gd 'extends Node' 'autoload de src/app pode estender Node'
# LW-029A (achado I6): só core e app chamam o relógio e a entrega de eventos.
for call in 'ctx.clock.advance_step()' 'ctx.clock.set_paused(true)' 'ctx.clock.set_speed(2)' 'ctx.events.dispatch()'; do
    expect_violation src/sim/world/violation.gd "func x(): $call" 'violation.gd:1:' "relógio ou barramento fora de core e app: $call"
    expect_clean src/core/clock_user.gd "func x(): $call" "permitido em src/core: $call"
    expect_clean src/app/runner_like.gd "func x(): $call" "permitido em src/app: $call"
done
expect_violation src/persistence/violation.gd 'func x(): ctx.clock.advance_step()' 'violation.gd:1:' 'advance_step em src/persistence'
expect_violation src/presentation/violation.gd 'func x(): ctx.events.dispatch()' 'violation.gd:1:' 'dispatch em src/presentation'
expect_clean src/sim/world/definition.gd 'func set_speed(value: int) -> void: pass' 'declarar um método set_speed não é chamar o relógio'
expect_clean src/sim/world/publisher.gd 'func x(): ctx.events.publish(event)' 'publicar evento continua permitido'
# LW-036: regra de import fora das camadas. Classes de prova, uma por camada: ProbeCore (0), ProbeTerrain (2),
# ProbeBridge (6), ProbeView (7) e ProbeSecret (classe privada de sim/world, pasta internal/). Os contadores
# desta seção são separados para não mudar a mensagem da LW-029A.
lw029a_violations=$new_violations
lw029a_clean=$new_clean
mkdir -p "$fixture/src/bridge" "$fixture/src/sim/economy" "$fixture/src/sim/world/internal" "$fixture/src/tools"
for dir in bridge sim/economy tools; do
    printf 'Contrato de teste\n' > "$fixture/src/$dir/README.md"
done
printf 'class_name ProbeCore\nextends RefCounted\n' > "$fixture/src/core/probe_core.gd"
printf 'class_name ProbeTerrain\nextends RefCounted\n' > "$fixture/src/sim/world/probe_terrain.gd"
printf 'class_name ProbeBridge\nextends RefCounted\n' > "$fixture/src/bridge/probe_bridge.gd"
printf 'class_name ProbeView\nextends RefCounted\n' > "$fixture/src/presentation/probe_view.gd"
printf 'class_name ProbeSecret\nextends RefCounted\n' > "$fixture/src/sim/world/internal/probe_secret.gd"
check_passes 'classes de prova de camadas, sem nenhuma citação, passam'
# (a) camada superior: o arquivo aponta a classe, a linha e a camada.
expect_violation src/sim/world/violation.gd 'var bridge: ProbeBridge' 'violation.gd:1: "ProbeBridge"' 'camada: sim/world (2) cita bridge (6)'
expect_violation src/core/violation.gd 'var terrain: ProbeTerrain' 'violation.gd:1: "ProbeTerrain"' 'camada: core (0) cita sim/world (2)'
expect_violation src/bridge/violation.gd 'var view: ProbeView' 'violation.gd:1: "ProbeView"' 'camada: bridge (6) cita presentation (7)'
printf 'extends RefCounted\n\nvar bridge: ProbeBridge\n' > "$fixture/src/sim/world/violation.gd"
check_violation 'camada: a linha apontada é a da citação (linha 3)' 'violation.gd:3: "ProbeBridge"'
rm "$fixture/src/sim/world/violation.gd"
new_violations=$((new_violations + 1))
expect_clean src/persistence/clean.gd 'var bridge: ProbeBridge' 'mesma camada (persistence cita bridge) é permitida'
expect_clean src/bridge/clean.gd 'var terrain: ProbeTerrain' 'camada maior cita menor (bridge cita sim/world)'
expect_clean src/sim/world/clean.gd 'var core: ProbeCore' 'sim/world cita core'
expect_clean src/sim/world/lookalike.gd 'var x: ProbeBridgeExtra = MyProbeBridge.new()' 'nome parecido não é citação (palavra inteira)'
expect_clean src/tools/clean.gd 'var view: ProbeView' 'pasta sem camada (src/tools) fica de fora'
# (b) a apresentação não cita classe de src/sim.
expect_violation src/presentation/violation.gd 'var terrain: ProbeTerrain' 'violation.gd:1: "ProbeTerrain" (src/sim/world/probe_terrain.gd) citada pela apresentação' 'apresentação cita classe de sim/'
expect_clean src/presentation/clean.gd 'var bridge: ProbeBridge = ProbeCore.new()' 'apresentação cita a ponte e o core'
# (c) classe de internal/ só dentro do módulo dono.
expect_violation src/sim/economy/violation.gd 'var secret: ProbeSecret' 'violation.gd:1: "ProbeSecret" (src/sim/world/internal/probe_secret.gd) é privada de src/sim/world/' 'classe de internal/ citada por outro módulo'
expect_clean src/sim/world/inside_module.gd 'var secret: ProbeSecret' 'classe de internal/ citada dentro do módulo'
expect_clean src/sim/world/internal/sibling.gd 'var secret: ProbeSecret' 'classe de internal/ citada por vizinha da mesma pasta'
# (d) linha inteira de comentário não conta; código com comentário no fim continua varrido.
expect_clean src/sim/world/commented.gd '# usa ProbeBridge só no comentário' 'comentário de linha inteira não conta'
expect_clean src/sim/world/commented.gd '    ## ProbeBridge e ProbeView em documentação' 'comentário de documentação indentado não conta'
expect_violation src/sim/world/violation.gd 'var bridge: ProbeBridge # comentário no fim da linha' 'violation.gd:1: "ProbeBridge"' 'comentário no fim da linha não isenta o código'
if ! "$checker" "$project_dir" > "$fixture/output" 2>&1 || ! grep -F 'nove verificações aprovadas' "$fixture/output" >/dev/null; then
    echo 'FALHA: a árvore real deveria passar com nove verificações'; cat "$fixture/output"; exit 1
fi
echo 'OK: árvore real passa'
lw036_violations=$((new_violations - lw029a_violations))
lw036_clean=$((new_clean - lw029a_clean))
new_violations=$lw029a_violations
new_clean=$lw029a_clean
rm "$fixture/src/core/probe_core.gd" "$fixture/src/sim/world/probe_terrain.gd" "$fixture/src/bridge/probe_bridge.gd" "$fixture/src/presentation/probe_view.gd" "$fixture/src/sim/world/internal/probe_secret.gd"
rm "$fixture/src/sim/world/README.md"
check_violation 'contrato ausente' 'world/README.md'
echo 'LW-012: 1 caso válido e 5 violações detectadas.'
echo 'LW-016: 1 evento catalogado aprovado e 2 eventos fora do catálogo detectados.'
echo 'LW-021: autoloads permitidos aprovados e 1 autoload extra detectado.'
echo "LW-029A: $new_violations violações detectadas e $new_clean casos aceitos (sorteio, tempo, estático, Node em persistence, relógio e barramento)."
echo "LW-036: $lw036_violations violações detectadas e $lw036_clean casos aceitos (camada superior, apresentação, classe privada de internal/, comentário) e a árvore real aprovada."
