#!/bin/sh
# ART-12, 7c-1b: a ENERGIA e as EXECUÇÕES do medidor de quadros em release (tests/soak/game_release_energy.sh e as recusas do tests/soak/run_game_release), SEM janela, SEM Godot e SEM tocar na energia do Mac: um
# `pmset` FALSO no PATH imprime o que cada caso manda (só os três comandos de LEITURA; qualquer outro argumento derruba o teste) e um jogo FALSO escreve ensaios de mentira e troca o estado do pmset no meio.
set -eu
project_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
work=$(mktemp -d "${TMPDIR:-/tmp}/lw_energy_test.XXXXXX")
trap 'rm -rf "$work"' EXIT HUP INT TERM
mkdir "$work/bin" "$work/state"
cat > "$work/bin/pmset" <<'FAKE'
#!/bin/sh
case "$*" in
    '-g batt') cat "$FAKE_STATE/batt";;
    '-g therm') cat "$FAKE_STATE/therm";;
    '-g') cat "$FAKE_STATE/settings";;
    *) echo "pmset falso: argumento inesperado '$*' (o medidor só pode LER)" >&2; exit 2;;
esac
FAKE
cat > "$work/bin/jogo_falso" <<'FAKE'
#!/bin/sh
n=$(($(cat "$FAKE_STATE/contagem" 2> /dev/null || echo 0) + 1)); echo "$n" > "$FAKE_STATE/contagem"
if [ -d "$FAKE_AFTER/$n" ]; then cp "$FAKE_AFTER/$n"/* "$FAKE_STATE"/; fi
echo "ARGS $*"; echo "ENSAIO POVOADO de mentira (execução $n)"
exit "${FAKE_EXIT:-0}"
FAKE
chmod +x "$work/bin/pmset" "$work/bin/jogo_falso"
FAKE_STATE="$work/state"; FAKE_AFTER="$work/nada"; PATH="$work/bin:$PATH"; export FAKE_STATE FAKE_AFTER PATH
. "$project_dir/tests/soak/game_release_energy.sh"
fail() { printf 'ERRO: %s\n' "$1" >&2; exit 1; }
expect() { [ "$2" = "$3" ] || { echo "FALHA: $1: esperado '$3', veio '$2'"; exit 1; }; echo "OK: $1"; }
expect_has() { case "$2" in *"$3"*) echo "OK: $1";; *) echo "FALHA: $1: sem '$3' em '$2'"; exit 1;; esac; }
expect_lacks() { case "$2" in *"$3"*) echo "FALHA: $1: não devia ter '$3'"; exit 1;; *) echo "OK: $1";; esac; }
set_state() { # $1 = pasta, $2 = bateria|tomada, $3 = %, $4 = estado, $5 = lowpowermode, $6 = normal|limite|aviso
    mkdir -p "$1"
    if [ "$2" = bateria ]; then echo "Now drawing from 'Battery Power'" > "$1/batt"; else echo "Now drawing from 'AC Power'" > "$1/batt"; fi
    printf ' -InternalBattery-0 (id=1)\t%s%%; %s; (no estimate) present: true\n' "$3" "$4" >> "$1/batt"
    printf ' lowpowermode         %s\n' "$5" > "$1/settings"
    case "$6" in
        normal) printf 'Note: No thermal warning level has been recorded\nNote: No performance warning level has been recorded\nNote: No CPU power status has been recorded\n' > "$1/therm";;
        limite) printf 'Note: No thermal warning level has been recorded\nNote: No performance warning level has been recorded\nCPU_Scheduler_Limit \t= 70\nCPU_Available_CPUs \t= 8\nCPU_Speed_Limit \t= 70\n' > "$1/therm";;
        aviso) printf 'Thermal warning level: 2\nNote: No performance warning level has been recorded\n' > "$1/therm";;
        novo) printf 'Note: No thermal warning level has been recorded\nNote: No performance warning level has been recorded\nNote: No CPU power status has been recorded\nOutra_Linha_Nova = 3\n' > "$1/therm";;
    esac
}
start_ok() { energy_start "$1" || { echo "FALHA: energy_start $1 recusou: $E_MESSAGE"; exit 1; }; }
start_refused() { if energy_start "$1"; then echo "FALHA: energy_start $1 deveria recusar ($2)"; exit 1; fi; expect_has "recusa: $2" "$E_MESSAGE" "$3"; }
S="$work/state"

# 1) O perfil detectado, o rótulo e as recusas (nunca rotula errado; bateria baixa; piso das travas).
set_state "$S" bateria 80 discharging 0 normal; start_ok auto
expect 'auto na bateria a 80%: perfil, porcentagem e estado' "$E_LABEL/$E_PERCENT/$E_STATE" 'bateria/80/discharging'
set_state "$S" bateria 80 discharging 1 normal; start_ok auto
expect 'baixo consumo LIGADO vira outro perfil (só lido, nada alterado)' "$E_LABEL" 'bateria (baixo consumo LIGADO)'
set_state "$S" tomada 100 charged 0 normal; start_ok auto
expect 'auto na tomada' "$E_LABEL" tomada; start_ok tomada
start_refused bateria 'PERFIL=bateria na tomada' 'não rotula errado'
set_state "$S" bateria 80 discharging 0 normal
start_refused tomada 'PERFIL=tomada na bateria' 'não rotula errado'
start_refused xyz 'PERFIL desconhecido' 'PERFIL deve ser'
set_state "$S" bateria 25 discharging 0 normal
start_refused auto 'bateria a 25%' 'abaixo do mínimo para começar (30%)'
BATERIA_MIN_INICIO=10; start_refused auto 'BATERIA_MIN_INICIO abaixo do piso' 'abaixo do piso 20'
BATERIA_MIN_INICIO=85; set_state "$S" bateria 80 discharging 0 normal; start_refused auto 'variável que ENDURECE a trava' 'abaixo do mínimo para começar (85%)'
BATERIA_MIN_INICIO=30; BATERIA_QUEDA_MAX=11; start_refused auto 'BATERIA_QUEDA_MAX acima do teto' 'passa do teto 10'; BATERIA_QUEDA_MAX=5

# 2) A classificação de UMA execução (antes e depois, como o run_trials lê).
classify() { # $1 = estado ANTES e $2 = estado DEPOIS (argumentos do set_state numa palavra só), $3 = código do jogo
    set_state "$S" $1; start_ok auto; energy_before; set_state "$S" $2; energy_after; energy_classify "$3" 1 1
}
classify 'bateria 80 discharging 0 normal' 'bateria 78 discharging 0 normal' 0; expect 'queda de 2 pontos: válida e segue' "$E_CLASS/$E_STOP" 'válida/0'
classify 'tomada 100 charged 0 normal' 'tomada 100 charged 0 normal' 0; expect 'tomada estável: válida' "$E_CLASS" 'válida'
classify 'bateria 80 discharging 0 normal' 'bateria 74 discharging 0 normal' 0
expect_has 'queda de 6 pontos: inconclusiva' "$E_CLASS" 'inconclusiva (a bateria caiu 6 pontos (máximo 5))'; expect 'queda de 6 pontos: as que faltam NÃO rodam' "$E_STOP" 1
BATERIA_MIN_INICIO=20; classify 'bateria 24 discharging 0 normal' 'bateria 19 discharging 0 normal' 0; BATERIA_MIN_INICIO=30
expect_has 'bateria abaixo do limite de parada: inconclusiva' "$E_CLASS" 'passou do limite de parada (19%, mínimo 20%)'; expect 'abaixo do limite: as que faltam NÃO rodam' "$E_STOP" 1
classify 'bateria 80 discharging 0 normal' 'tomada 82 charging 0 normal' 0
expect_has 'fonte mudou no meio: inconclusiva' "$E_CLASS" 'a fonte de energia mudou (começou na bateria; antes bateria, depois tomada)'; expect 'fonte mudou: as que faltam NÃO rodam' "$E_STOP" 1
classify 'bateria 80 discharging 0 normal' 'bateria 79 discharging 0 limite' 0
expect_has 'CPU_Scheduler_Limit abaixo de 100: inconclusiva' "$E_CLASS" 'limitação de CPU (CPU_Scheduler_Limit=70)'; expect 'limitação térmica não interrompe a série' "$E_STOP" 0
classify 'bateria 80 discharging 0 normal' 'bateria 79 discharging 0 aviso' 0; expect_has 'aviso térmico registrado: inconclusiva' "$E_CLASS" 'aviso térmico ou de desempenho (Thermal warning level: 2)'
classify 'bateria 80 discharging 0 normal' 'bateria 79 discharging 0 novo' 0; expect_has 'o therm mudou para algo que o medidor não conhece: inconclusiva (rede de segurança)' "$E_CLASS" 'o pmset -g therm mudou durante a execução'
classify 'bateria 80 discharging 0 normal' 'bateria 79 discharging 1 normal' 0; expect_has 'baixo consumo mudou no meio: inconclusiva' "$E_CLASS" 'o modo de baixo consumo mudou'
classify 'bateria 80 discharging 0 normal' 'bateria 79 discharging 0 normal' 1; expect_has 'o jogo não terminou: inconclusiva' "$E_CLASS" 'o jogo não terminou os ensaios (código 1; 1 de 1 ensaios)'

# 3) O script REAL recusa antes de criar a pasta de trabalho (sem Godot, sem download, sem janela).
refusal() { # $1 = rótulo, $2 = trecho da mensagem; o resto = variáveis de ambiente do script
    label=$1; fragment=$2; shift 2
    if out=$(env "$@" "$project_dir/tests/soak/run_game_release" "$work/pasta_nunca_criada" < /dev/null 2>&1); then echo "FALHA: $label: o script deveria recusar"; exit 1; fi
    expect_has "$label" "$out" "$fragment"
    [ ! -e "$work/pasta_nunca_criada" ] || { echo "FALHA: $label: o script criou a pasta de trabalho antes de recusar"; exit 1; }
}
set_state "$S" tomada 100 charged 0 normal; refusal 'script: PERFIL=bateria na tomada' 'não rotula errado' PERFIL=bateria
set_state "$S" bateria 25 discharging 0 normal; refusal 'script: bateria a 25%' 'abaixo do mínimo para começar' PERFIL=auto
set_state "$S" bateria 80 discharging 0 normal; refusal 'script: BATERIA_MIN_PARADA abaixo do piso' 'abaixo do piso 10' BATERIA_MIN_PARADA=5
refusal 'script: CURTA inválida' 'CURTA deve ser 0 ou 1' CURTA=2

# 4) As execuções do run_trials com o jogo FALSO: o registro, a classificação, o resumo (as inconclusivas fora da conta) e as paradas.
series() { # $1 = nome, $2 = RUNS, o resto = o estado DEPOIS de cada execução (argumentos do set_state numa palavra só); o ANTES é o estado atual
    name=$1; runs=$2; shift 2
    mkdir -p "$work/$name"; FAKE_AFTER="$work/after_$name"; echo 0 > "$S/contagem"
    i=0; for after in "$@"; do i=$((i + 1)); set_state "$FAKE_AFTER/$i" $after; done
    ( WORK="$work/$name"; RUNS=$runs; ENSAIOS=povoado; GAME_EXTRA="${SERIES_EXTRA:-}"; FIGURA=sem; DURACAO=completa; start_ok auto; run_trials game_release "$work/bin/jogo_falso" ) 2>&1 || rc=$?
}
rc=0; set_state "$S" bateria 80 discharging 0 normal
out=$(series saudavel 2 'bateria 79 discharging 0 normal' 'bateria 78 discharging 0 normal')
expect_has 'série saudável: 2 válidas, 0 inconclusivas' "$out" '2 execução(ões), 2 válida(s) e 0 inconclusiva(s)'
run1=$(cat "$work/saudavel/game_release_run_1.txt")
for line in 'PERFIL: bateria' 'FIGURA: sem' 'DURAÇÃO: completa' 'energia (antes): fonte bateria, bateria 80% (discharging), baixo consumo (lowpowermode) 0' 'estado térmico (depois), pmset -g therm:' '  Note: No thermal warning level has been recorded' 'ENSAIO POVOADO de mentira' 'CLASSIFICAÇÃO: válida'; do expect_has "arquivo da execução tem '$line'" "$run1" "$line"; done
set_state "$S" bateria 80 discharging 0 normal
out=$(series fonte 3 'tomada 82 charging 0 normal'); expect_has 'fonte que muda: execução inconclusiva' "$out" 'CLASSIFICAÇÃO: inconclusiva (a fonte de energia mudou'
expect_has 'fonte que muda: resumo' "$out" '1 execução(ões), 0 válida(s) e 1 inconclusiva(s)'; expect_has 'fonte que muda: INTERROMPE' "$out" 'INTERROMPIDO após a execução 1'
[ ! -f "$work/fonte/game_release_run_2.txt" ] || { echo 'FALHA: a execução 2 rodou depois da fonte mudar'; exit 1; }; echo 'OK: a execução 2 NÃO rodou'
set_state "$S" bateria 80 discharging 0 normal
out=$(series queda 3 'bateria 74 discharging 0 normal'); expect_has 'bateria que cai 6 pontos: INTERROMPE' "$out" 'INTERROMPIDO após a execução 1: inconclusiva (a bateria caiu 6 pontos'
set_state "$S" bateria 80 discharging 0 normal
out=$(series termico 2 'bateria 79 discharging 0 normal' 'bateria 78 discharging 0 limite')
expect_has 'inconclusiva NÃO entra na conta: 1 válida e 1 inconclusiva' "$out" '2 execução(ões), 1 válida(s) e 1 inconclusiva(s) [execução 2: (estado térmico fora do normal DEPOIS'; expect_has 'o resumo lista o motivo térmico' "$out" 'limitação de CPU (CPU_Scheduler_Limit=70)'
expect_lacks 'limitação térmica não interrompe a série' "$out" INTERROMPIDO
set_state "$S" bateria 80 discharging 0 normal
SERIES_EXTRA='--segundos 10'; out=$(series curta 1 'bateria 79 discharging 0 normal'); SERIES_EXTRA=''; expect_has 'a CURTA repassa --segundos ao jogo' "$out" 'ARGS -- --ensaios povoado --segundos 10'
set_state "$S" bateria 80 discharging 0 normal
FAKE_EXIT=1; export FAKE_EXIT; rc=0; out=$(series erro 2 'bateria 79 discharging 0 normal'); unset FAKE_EXIT
expect_has 'jogo que falha: classificação no arquivo' "$(cat "$work/erro/game_release_run_1.txt")" 'CLASSIFICAÇÃO: inconclusiva (o jogo não terminou os ensaios (código 1'; expect_has 'jogo que falha: o script aborta' "$out" 'terminou com erro'

# 5) O script e a biblioteca: sintaxe, sem a exigência de tomada e SÓ leitura da energia.
sh -n "$project_dir/tests/soak/run_game_release" && sh -n "$project_dir/tests/soak/game_release_energy.sh" && echo 'OK: sh -n no script e na biblioteca'
if grep -v '^[[:space:]]*#' "$project_dir/tests/soak/run_game_release" | grep -q 'AC Power\|saiu da tomada'; then echo 'FALHA: o script ainda exige a tomada'; exit 1; fi; echo 'OK: o script não exige mais a tomada'
if cat "$project_dir/tests/soak/run_game_release" "$project_dir/tests/soak/game_release_energy.sh" | grep -v '^[[:space:]]*#' | grep -Eq 'sudo|powermetrics|caffeinate|pmset +(-a|-b|-c|set)'; then echo 'FALHA: o medidor altera a energia'; exit 1; fi; echo 'OK: o medidor só LÊ a energia'
echo 'ART-12 7c-1b: perfis de energia, travas e classificação do medidor aprovados.'
