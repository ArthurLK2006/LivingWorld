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
# LW-085a: regra D. ProbeDoor mora na api/ de sim/npc (módulo com api/); ProbeInner mora em sim/npc/lod, fora da api/. A ponte e as ferramentas só citam a api/.
mkdir -p "$fixture/src/sim/npc/api" "$fixture/src/sim/npc/lod"
printf 'Contrato de teste\n' > "$fixture/src/sim/npc/README.md"
printf 'class_name ProbeDoor\nextends RefCounted\n' > "$fixture/src/sim/npc/api/probe_door.gd"
printf 'class_name ProbeInner\nextends RefCounted\n' > "$fixture/src/sim/npc/lod/probe_inner.gd"
check_passes 'classes de prova da api/ e do interior do módulo, sem citação, passam'
expect_violation src/bridge/violation.gd 'var inner: ProbeInner' 'violation.gd:1: "ProbeInner" (src/sim/npc/lod/probe_inner.gd) é interna de src/sim/npc/, que tem pasta api/' 'ponte cita classe interna de módulo com api/'
expect_violation src/tools/violation.gd 'var inner: ProbeInner' 'violation.gd:1: "ProbeInner" (src/sim/npc/lod/probe_inner.gd) é interna de src/sim/npc/, que tem pasta api/' 'tools cita classe interna de módulo com api/'
expect_clean src/bridge/clean.gd 'var door: ProbeDoor' 'ponte cita classe da api/'
expect_clean src/tools/clean.gd 'var door: ProbeDoor' 'tools cita classe da api/'
expect_clean src/sim/npc/lod/inside.gd 'var door: ProbeDoor = ProbeInner.new()' 'o interior do módulo cita a própria classe interna'
expect_clean src/app/composition.gd 'var inner: ProbeInner' 'src/app (raiz de composição) fica de fora da regra D'
expect_clean src/bridge/clean.gd 'var terrain: ProbeTerrain' 'módulo sem pasta api/ (sim/world) citado pela ponte continua permitido'
expect_clean src/bridge/commented.gd '## usa ProbeInner só em comentário' 'comentário de linha inteira não conta na regra D'
lw085a_violations=$((new_violations - lw029a_violations))
lw085a_clean=$((new_clean - lw029a_clean))
new_violations=$lw029a_violations
new_clean=$lw029a_clean
# LW-088a (DEC-171 e DEC-132): regra E. ProbeLedgerApi mora na api/ de sim/economy; ProbeLedgerInner mora em sim/economy/ledger, fora da api/. ProbeDoor e ProbeInner (acima) são do npc.
# O npc só cita a api/ da economy; a economy não cita nada do npc, nem a api/ dele. As duas são da camada 3: a regra A não pega entre pares.
mkdir -p "$fixture/src/sim/economy/api" "$fixture/src/sim/economy/ledger"
printf 'class_name ProbeLedgerApi\nextends RefCounted\n' > "$fixture/src/sim/economy/api/probe_ledger_api.gd"
printf 'class_name ProbeLedgerInner\nextends RefCounted\n' > "$fixture/src/sim/economy/ledger/probe_ledger_inner.gd"
check_passes 'classes de prova da economy, sem citação, passam'
expect_clean src/sim/npc/clean.gd 'var ledger: ProbeLedgerApi' 'o npc cita a api/ da economy'
expect_clean src/sim/economy/ledger/inside.gd 'var ledger: ProbeLedgerApi = ProbeLedgerInner.new()' 'a economy cita as próprias classes'
expect_clean src/bridge/clean.gd 'var ledger: ProbeLedgerApi' 'a ponte cita a api/ da economy'
expect_clean src/sim/npc/commented.gd '## usa ProbeLedgerInner só em comentário' 'comentário de linha inteira não conta na regra E'
expect_violation src/sim/npc/violation.gd 'var ledger: ProbeLedgerInner' 'violation.gd:1: "ProbeLedgerInner" (src/sim/economy/ledger/probe_ledger_inner.gd) é interna de src/sim/economy/' 'o npc cita classe interna da economy'
expect_violation src/sim/npc/violation.gd 'var ledger: ProbeLedgerInner # comentário no fim da linha' 'violation.gd:1: "ProbeLedgerInner"' 'comentário no fim da linha não isenta o npc na regra E'
expect_violation src/sim/economy/violation.gd 'var door: ProbeDoor' 'violation.gd:1: "ProbeDoor" (src/sim/npc/api/probe_door.gd) é do npc' 'a economy cita a api/ do npc'
expect_violation src/sim/economy/violation.gd 'var inner: ProbeInner' 'violation.gd:1: "ProbeInner" (src/sim/npc/lod/probe_inner.gd) é do npc' 'a economy cita classe interna do npc'
lw088a_violations=$((new_violations - lw029a_violations))
lw088a_clean=$((new_clean - lw029a_clean))
new_violations=$lw029a_violations
new_clean=$lw029a_clean
# LW-088 (arquitetura 11.4): regra F. Só src/sim/economy/ledger/ escreve saldo. `balance`, `balances` e `money` recebendo valor (atribuição, += ou -=, campo de outro objeto,
# `balances[id] = ...`) fora dessa pasta são violação; comparação, nome parecido, declaração e comentário não são.
expect_violation src/sim/npc/violation.gd 'func x(state): state.money = 5' 'violation.gd:1:' 'campo money de outro objeto recebe valor'
expect_violation src/sim/economy/violation.gd 'func x(): _balances[owner_id] -= amount' 'violation.gd:1:' 'subtrair de _balances fora do ledger'
expect_violation src/sim/economy/violation.gd 'func x(): balances[owner_id] = 10' 'violation.gd:1:' 'balances[id] recebe valor fora do ledger'
expect_violation src/sim/world/violation.gd 'func x(): balance += 3' 'violation.gd:1:' 'somar a balance fora do ledger'
expect_violation src/bridge/violation.gd 'func x(owner): owner.balance = 7' 'violation.gd:1:' 'campo balance de outro objeto recebe valor'
expect_violation src/sim/economy/violation.gd 'func x(): money *= 2 # comentário no fim' 'violation.gd:1:' 'comentário no fim da linha não isenta a regra F'
expect_clean src/sim/economy/ledger/inside.gd 'func x(): _balances[owner_id] -= amount; balance += 1; owner.money = 3' 'o próprio ledger escreve saldo'
expect_clean src/sim/economy/api/reply.gd 'var balance: int = 0
func _init(owner_balance: int) -> void:
    balance = owner_balance' 'declarar e inicializar um campo balance não é alterar saldo'
expect_clean src/sim/npc/comparison.gd 'func x(state): return state.money == 5 and balance != 3 and balance >= 2' 'comparação não é atribuição'
expect_clean src/sim/npc/lookalike.gd 'func x(): my_balance += 1; balance_sum -= 2; state.money_total = 4; peek_balance = 3' 'nome parecido não é saldo (palavra inteira)'
expect_clean src/sim/npc/commented.gd '# money = 5 só em comentário' 'comentário de linha inteira não conta na regra F'
lw088_violations=$((new_violations - lw029a_violations))
lw088_clean=$((new_clean - lw029a_clean))
new_violations=$lw029a_violations
new_clean=$lw029a_clean
# LW-089c: a regra E olha o IDENTIFICADOR, não o texto entre aspas (a economy ouve o evento do npc pelo NOME). ProbeDoor (npc/api) e ProbeLedgerInner (economy interna) são as classes de prova.
expect_clean src/sim/economy/listener.gd 'const EVENT: String = "ProbeDoor"' 'texto com o nome de uma classe do npc não é citação da economy'
expect_clean src/sim/npc/names.gd 'var kind: String = "ProbeLedgerInner" + "ProbeLedgerApi"' 'texto com o nome de uma classe interna da economy não é citação do npc'
expect_violation src/sim/economy/violation.gd 'var door: ProbeDoor = null # "texto"' 'violation.gd:1: "ProbeDoor"' 'a classe do npc fora das aspas continua sendo citação'
expect_violation src/sim/npc/violation.gd 'var inner = ProbeLedgerInner.new("ProbeLedgerApi")' 'violation.gd:1: "ProbeLedgerInner"' 'a classe interna da economy fora das aspas continua sendo citação'
lw089c_violations=$((new_violations - lw029a_violations))
lw089c_clean=$((new_clean - lw029a_clean))
new_violations=$lw029a_violations
new_clean=$lw029a_clean
# LW-088d (revisão independente, I2 e I5): a regra E vale para QUALQUER arquivo fora da economy (não só o npc) e a regra F pega também a atribuição simples e os membros privados do Ledger.
mkdir -p "$fixture/src/sim/ecology" "$fixture/src/sim/politics"
printf '# ecology (sonda)\n' > "$fixture/src/sim/ecology/README.md"
printf '# politics (sonda)\n' > "$fixture/src/sim/politics/README.md"
expect_violation src/sim/politics/violation.gd 'var ledger: ProbeLedgerInner' 'violation.gd:1: "ProbeLedgerInner" (src/sim/economy/ledger/probe_ledger_inner.gd) é interna de src/sim/economy/' 'um módulo de camada maior cita classe interna da economy'
expect_violation src/sim/ecology/violation.gd 'var ledger: ProbeLedgerInner' 'violation.gd:1: "ProbeLedgerInner"' 'um módulo de camada igual cita classe interna da economy'
expect_clean src/sim/politics/clean.gd 'var ledger: ProbeLedgerApi' 'qualquer módulo cita a api/ da economy'
expect_clean src/sim/politics/names.gd 'var kind: String = "ProbeLedgerInner"' 'texto com o nome de uma classe interna da economy não é citação de outro módulo'
expect_clean src/app/setup.gd 'var inner: ProbeLedgerInner' 'src/app, a raiz de composição, fica de fora da regra E'
expect_violation src/sim/world/violation.gd 'func x(): balance = 5' 'violation.gd:1:' 'atribuição simples a balance fora do ledger'
expect_violation src/sim/npc/violation.gd 'func x(): money = 5' 'violation.gd:1:' 'atribuição simples a money fora do ledger'
expect_violation src/sim/economy/violation.gd 'func x(): _balances = {}' 'violation.gd:1:' 'trocar _balances fora do ledger'
expect_violation src/sim/npc/violation.gd 'func x(ledger): ledger._balances.erase(owner_id)' 'violation.gd:1:' 'apagar de _balances por fora do ledger'
expect_violation src/bridge/violation.gd 'func x(ledger): ledger._set_balance(owner_id, 5)' 'violation.gd:1:' 'chamar _set_balance por fora do ledger'
expect_clean src/sim/economy/ledger/inside.gd 'func x(): balance = 5; _set_balance(owner_id, 1); _balances = {}' 'o próprio ledger usa os membros privados'
expect_clean src/sim/npc/declared.gd 'func x(): var balance: int = 3; var money := 4; return balance == money' 'declaração com tipo não é atribuição a saldo'
expect_clean src/sim/npc/quoted.gd 'var text: String = "balance = 5 e _balances e _set_balance"' 'texto entre aspas não é atribuição a saldo'
lw088d_violations=$((new_violations - lw029a_violations))
lw088d_clean=$((new_clean - lw029a_clean))
new_violations=$lw029a_violations
new_clean=$lw029a_clean
rm "$fixture/src/sim/economy/api/probe_ledger_api.gd" "$fixture/src/sim/economy/ledger/probe_ledger_inner.gd"
rm "$fixture/src/sim/npc/api/probe_door.gd" "$fixture/src/sim/npc/lod/probe_inner.gd" "$fixture/src/sim/npc/README.md"
rm "$fixture/src/core/probe_core.gd" "$fixture/src/sim/world/probe_terrain.gd" "$fixture/src/bridge/probe_bridge.gd" "$fixture/src/presentation/probe_view.gd" "$fixture/src/sim/world/internal/probe_secret.gd"
rm "$fixture/src/sim/ecology/README.md" "$fixture/src/sim/politics/README.md"
rm "$fixture/src/sim/world/README.md"
check_violation 'contrato ausente' 'world/README.md'
echo 'LW-012: 1 caso válido e 5 violações detectadas.'
echo 'LW-016: 1 evento catalogado aprovado e 2 eventos fora do catálogo detectados.'
echo 'LW-021: autoloads permitidos aprovados e 1 autoload extra detectado.'
echo "LW-029A: $new_violations violações detectadas e $new_clean casos aceitos (sorteio, tempo, estático, Node em persistence, relógio e barramento)."
echo "LW-036: $lw036_violations violações detectadas e $lw036_clean casos aceitos (camada superior, apresentação, classe privada de internal/, comentário) e a árvore real aprovada."
echo "LW-085a: $lw085a_violations violações detectadas e $lw085a_clean casos aceitos (regra D: a ponte e tools só citam a api/ de um módulo que tem api/; módulo sem api/, src/app e comentário ficam de fora)."
echo "LW-088a: $lw088a_violations violações detectadas e $lw088a_clean casos aceitos (regra E: o npc cita só a api/ da economy e a economy não cita o npc; comentário fica de fora)."
echo "LW-088: $lw088_violations violações detectadas e $lw088_clean casos aceitos (regra F: só o Ledger escreve saldo; comparação, nome parecido, declaração e comentário ficam de fora)."
echo "LW-089c: $lw089c_violations violações detectadas e $lw089c_clean casos aceitos (regra E: texto entre aspas não é citação; o identificador continua sendo)."
echo "LW-088d: $lw088d_violations violações detectadas e $lw088d_clean casos aceitos (regra E para qualquer arquivo fora da economy, src/app de fora; regra F com atribuição simples e membros privados do Ledger)."
