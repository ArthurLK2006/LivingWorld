#!/bin/sh
# ART-12, 7c-1b: a ENERGIA e as EXECUÇÕES do medidor de quadros em release (tests/soak/game_release_energy.sh e as recusas do tests/soak/run_game_release), SEM janela, SEM Godot e SEM tocar na energia do Mac: um
# `pmset` FALSO no PATH imprime o que cada caso manda (só os três comandos de LEITURA; qualquer outro argumento derruba o teste), um `sysctl` FALSO só responde hw.ncpu e um jogo FALSO escreve ensaios de mentira
# e troca o estado do pmset no meio. As recusas do script rodam com GODOT_BIN=/nao/existe: se uma regredir, o script falha cedo com OUTRA mensagem (sem Godot, sem rede, sem download e sem janela).
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
cat > "$work/bin/sysctl" <<'FAKE'
#!/bin/sh
case "$*" in
    '-n hw.ncpu') echo "${FAKE_NCPU-8}";;
    *) exit 1;;
esac
FAKE
cat > "$work/bin/jogo_falso" <<'FAKE'
#!/bin/sh
if [ "${1:-}" = --version ]; then echo '4.7.2.stable.official.falso'; exit 0; fi
n=$(($(cat "$FAKE_STATE/contagem" 2> /dev/null || echo 0) + 1)); echo "$n" > "$FAKE_STATE/contagem"
if [ -d "$FAKE_AFTER/$n" ]; then cp "$FAKE_AFTER/$n"/* "$FAKE_STATE"/; fi
echo "ARGS $*"; echo "ENSAIO POVOADO de mentira (execução $n)"
exit "${FAKE_EXIT:-0}"
FAKE
chmod +x "$work/bin/pmset" "$work/bin/sysctl" "$work/bin/jogo_falso"
FAKE_STATE="$work/state"; FAKE_AFTER="$work/nada"; PATH="$work/bin:$PATH"; export FAKE_STATE FAKE_AFTER PATH
unset PERFIL LW_ART_SAMPLES CURTA RUNS ENSAIOS GAME_EXTRA LW_PROBE_COPY KEEP_DOWNLOAD GODOT_BIN FAKE_NCPU BATERIA_MIN_INICIO BATERIA_MIN_PARADA BATERIA_QUEDA_MAX LW_BUILD_ONLY LW_RUN_ONLY LW_RELEASE_BIN
. "$project_dir/tests/soak/game_release_energy.sh"
fail() { printf 'ERRO: %s\n' "$1" >&2; exit 1; }
expect() { [ "$2" = "$3" ] || { echo "FALHA: $1: esperado '$3', veio '$2'"; exit 1; }; echo "OK: $1"; }
expect_has() { case "$2" in *"$3"*) echo "OK: $1";; *) echo "FALHA: $1: sem '$3' em '$2'"; exit 1;; esac; }
expect_lacks() { case "$2" in *"$3"*) echo "FALHA: $1: não devia ter '$3'"; exit 1;; *) echo "OK: $1";; esac; }
set_state() { # $1 = pasta, $2 = bateria|tomada, $3 = %, $4 = estado, $5 = lowpowermode (0|1|2|lixo|ausente|tab0|tab1), $6 = normal|limite|aviso|novo|vazio|lixo|desconhecida|cpus4
    mkdir -p "$1"
    if [ "$2" = bateria ]; then echo "Now drawing from 'Battery Power'" > "$1/batt"; else echo "Now drawing from 'AC Power'" > "$1/batt"; fi
    printf ' -InternalBattery-0 (id=1)\t%s%%; %s; (no estimate) present: true\n' "$3" "$4" >> "$1/batt"
    case "$5" in
        ausente) printf ' sleep                1\n displaysleep         2\n' > "$1/settings";;
        tab0) printf ' lowpowermode\t0\n' > "$1/settings";;
        tab1) printf ' lowpowermode\t1\n' > "$1/settings";;
        *) printf ' lowpowermode         %s\n' "$5" > "$1/settings";;
    esac
    case "$6" in
        normal) printf 'Note: No thermal warning level has been recorded\nNote: No performance warning level has been recorded\nNote: No CPU power status has been recorded\n' > "$1/therm";;
        limite) printf 'Note: No thermal warning level has been recorded\nNote: No performance warning level has been recorded\nCPU_Scheduler_Limit \t= 70\nCPU_Available_CPUs \t= 8\nCPU_Speed_Limit \t= 70\n' > "$1/therm";;
        aviso) printf 'Thermal warning level: 2\nNote: No performance warning level has been recorded\n' > "$1/therm";;
        novo) printf 'Note: No thermal warning level has been recorded\nNote: No performance warning level has been recorded\nNote: No CPU power status has been recorded\nOutra_Linha_Nova = 3\n' > "$1/therm";;
        vazio) : > "$1/therm";;
        lixo) printf 'pmset: erro interno\n' > "$1/therm";;
        desconhecida) printf 'Note: No thermal warning level has been recorded\nNote: No performance warning level has been recorded\nCPU power status: limited\n' > "$1/therm";;
        cpus4) printf 'CPU_Scheduler_Limit \t= 100\nCPU_Available_CPUs \t= 4\nCPU_Speed_Limit \t= 100\n' > "$1/therm";;
    esac
}
start_ok() { energy_start "$1" || { echo "FALHA: energy_start $1 recusou: $E_MESSAGE"; exit 1; }; }
start_refused() { if energy_start "$1"; then echo "FALHA: energy_start $1 deveria recusar ($2)"; exit 1; fi; expect_has "recusa: $2" "$E_MESSAGE" "$3"; }
classify() { # $1 = estado ANTES e $2 = estado DEPOIS (argumentos do set_state numa palavra só), $3 = código do jogo
    set_state "$S" $1; start_ok auto; energy_before; set_state "$S" $2; energy_after; energy_classify "$3" 1 1
}
S="$work/state"

# 1) O perfil detectado, o rótulo e as recusas (nunca rotula errado; bateria baixa; piso das travas).
expect 'padrões das travas, sem variáveis: 30/20/5' "$BATERIA_MIN_INICIO/$BATERIA_MIN_PARADA/$BATERIA_QUEDA_MAX" '30/20/5'
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
echo "Now drawing from 'UPS Power'" > "$S/batt"; start_refused auto 'fonte desconhecida no começo' 'Não consegui ler a fonte de energia'
printf "Now drawing from 'Battery Power'\n -InternalBattery-0 (id=1)\t(no estimate) present: true\n" > "$S/batt"; start_refused auto 'bateria sem porcentagem legível' 'não consegui ler a porcentagem'
printf "Now drawing from 'Battery Power'\n -InternalBattery-0 (id=1)\t99999999999999999999%%; discharging; present: true\n" > "$S/batt"; start_refused auto 'porcentagem enorme' 'não consegui ler a porcentagem'

# 1b) Número enorme, lixo ou fora de 0 a 999 NUNCA desliga a trava (o `[ -lt/-gt ]` de um número enorme dá erro e o `if` o trata como falso): recusa; 999 passa pelo piso/teto e só pode ENDURECER.
set_state "$S" bateria 80 discharging 0 normal
for value in 99999999999999999999 1000 abc -5 ''; do
    BATERIA_MIN_INICIO=$value; start_refused auto "BATERIA_MIN_INICIO='$value'" 'devem ser inteiros de 0 a 999'; BATERIA_MIN_INICIO=30
    BATERIA_MIN_PARADA=$value; start_refused auto "BATERIA_MIN_PARADA='$value'" 'devem ser inteiros de 0 a 999'; BATERIA_MIN_PARADA=20
    BATERIA_QUEDA_MAX=$value; start_refused auto "BATERIA_QUEDA_MAX='$value'" 'devem ser inteiros de 0 a 999'; BATERIA_QUEDA_MAX=5
done
BATERIA_QUEDA_MAX=999; start_refused auto 'BATERIA_QUEDA_MAX=999 (mais frouxo que o teto)' 'passa do teto 10'; BATERIA_QUEDA_MAX=5
BATERIA_MIN_INICIO=999; start_refused auto 'BATERIA_MIN_INICIO=999 (só endurece)' 'abaixo do mínimo para começar (999%)'; BATERIA_MIN_INICIO=30
BATERIA_MIN_PARADA=999; classify 'bateria 80 discharging 0 normal' 'bateria 79 discharging 0 normal' 0; BATERIA_MIN_PARADA=20
expect_has 'BATERIA_MIN_PARADA=999 (só endurece): inconclusiva' "$E_CLASS" 'passou do limite de parada (79%, mínimo 999%)'; expect 'BATERIA_MIN_PARADA=999: as que faltam NÃO rodam' "$E_STOP" 1

# 2) A classificação de UMA execução (antes e depois, como o run_trials lê).
classify 'bateria 80 discharging 0 normal' 'bateria 78 discharging 0 normal' 0; expect 'queda de 2 pontos: válida e segue' "$E_CLASS/$E_STOP" 'válida/0'
classify 'tomada 100 charged 0 normal' 'tomada 100 charged 0 normal' 0; expect 'tomada estável: válida' "$E_CLASS" 'válida'
classify 'bateria 80 discharging 0 normal' 'bateria 75 discharging 0 normal' 0; expect 'queda de EXATAMENTE 5 pontos (padrão): válida e segue' "$E_CLASS/$E_STOP" 'válida/0'
classify 'bateria 80 discharging 0 normal' 'bateria 74 discharging 0 normal' 0
expect_has 'queda de 6 pontos: inconclusiva' "$E_CLASS" 'inconclusiva (a bateria caiu 6 pontos (máximo 5))'; expect 'queda de 6 pontos: as que faltam NÃO rodam' "$E_STOP" 1
BATERIA_MIN_INICIO=20; classify 'bateria 24 discharging 0 normal' 'bateria 19 discharging 0 normal' 0; BATERIA_MIN_INICIO=30
expect_has 'bateria abaixo do limite de parada: inconclusiva' "$E_CLASS" 'passou do limite de parada (19%, mínimo 20%)'; expect 'abaixo do limite: as que faltam NÃO rodam' "$E_STOP" 1
BATERIA_MIN_INICIO=20; classify 'bateria 25 discharging 0 normal' 'bateria 20 discharging 0 normal' 0; BATERIA_MIN_INICIO=30
expect 'bateria depois em EXATAMENTE 20% (limite de parada): válida e segue' "$E_CLASS/$E_STOP" 'válida/0'
classify 'bateria 80 discharging 0 normal' 'tomada 82 charging 0 normal' 0
expect_has 'fonte mudou no meio: inconclusiva' "$E_CLASS" 'a fonte de energia mudou (começou na bateria; antes bateria, depois tomada)'; expect 'fonte mudou: as que faltam NÃO rodam' "$E_STOP" 1
printf "Now drawing from 'Battery Power'\n -InternalBattery-0 (id=1)\t(no estimate) present: true\n" > "$work/depois_batt"; set_state "$S" bateria 80 discharging 0 normal; start_ok auto; energy_before
set_state "$S" bateria 79 discharging 0 normal; cp "$work/depois_batt" "$S/batt"; energy_after; energy_classify 0 1 1
expect_has 'porcentagem que some depois: inconclusiva' "$E_CLASS" 'inconclusiva (não consegui ler a porcentagem da bateria'; expect 'porcentagem que some: as que faltam NÃO rodam (sem ela a trava não vale)' "$E_STOP" 1
classify 'bateria 80 discharging 0 normal' 'bateria 79 discharging 0 limite' 0
expect_has 'CPU_Scheduler_Limit abaixo de 100: inconclusiva' "$E_CLASS" 'limitação de CPU (CPU_Scheduler_Limit=70)'; expect 'limitação térmica não interrompe a série' "$E_STOP" 0
classify 'bateria 80 discharging 0 normal' 'bateria 79 discharging 0 aviso' 0; expect_has 'aviso térmico registrado: inconclusiva' "$E_CLASS" 'aviso térmico ou de desempenho (Thermal warning level: 2)'
classify 'bateria 80 discharging 0 normal' 'bateria 79 discharging 0 novo' 0; expect_has 'o therm mudou para algo que o medidor não conhece: inconclusiva (rede de segurança)' "$E_CLASS" 'o pmset -g therm mudou durante a execução'
classify 'bateria 80 discharging 0 limite' 'bateria 79 discharging 0 normal' 0; expect_has 'térmico ruim só ANTES (depois normal): inconclusiva' "$E_CLASS" 'estado térmico fora do normal ANTES: limitação de CPU (CPU_Scheduler_Limit=70)'
classify 'bateria 80 discharging 0 normal' 'bateria 79 discharging 1 normal' 0; expect_has 'baixo consumo mudou no meio: inconclusiva' "$E_CLASS" 'o modo de baixo consumo mudou'
classify 'bateria 80 discharging 0 normal' 'bateria 79 discharging 0 normal' 1; expect_has 'o jogo não terminou: inconclusiva' "$E_CLASS" 'o jogo não terminou os ensaios (código 1; 1 de 1 ensaios)'

# 2b) FORMATO DESCONHECIDO nunca vira "válida": `pmset -g therm` vazio, com lixo ou com linha desconhecida (igual antes e depois) é inconclusivo; o formato REAL (as 3 linhas "No ... recorded") segue válido.
for therm in vazio lixo desconhecida; do
    classify "bateria 80 discharging 0 $therm" "bateria 79 discharging 0 $therm" 0
    expect_has "therm $therm, igual antes e depois: inconclusiva (ANTES)" "$E_CLASS" 'inconclusiva (estado térmico fora do normal ANTES: estado térmico ilegível ou em formato desconhecido ('
    expect_has "therm $therm, igual antes e depois: inconclusiva (DEPOIS)" "$E_CLASS" 'estado térmico fora do normal DEPOIS: estado térmico ilegível ou em formato desconhecido ('
done
classify 'bateria 80 discharging 0 normal' 'bateria 79 discharging 0 normal' 0; expect 'therm real (as 3 linhas "No ... recorded"): válida' "$E_CLASS" 'válida'
real=$(printf 'Note: No thermal warning level has been recorded\nNote: No performance warning level has been recorded\nNote: No CPU power status has been recorded')
expect 'therm real: nenhum motivo' "$(energy_therm_issue "$real")" ''
expect 'therm sem "Note:", com outras maiúsculas e espaços no fim: normal' "$(energy_therm_issue "$(printf 'no thermal warning level has been recorded\nNOTE: NO PERFORMANCE WARNING LEVEL HAS BEEN RECORDED \t\n\n  Note: No CPU power status has been recorded')")" ''
expect 'campos CPU_* em 100 e CPUs disponíveis = hw.ncpu: normal' "$(energy_therm_issue "$(printf 'CPU_Scheduler_Limit \t= 100\nCPU_Available_CPUs \t= 8\nCPU_Speed_Limit \t= 100\n')")" ''
expect_has 'therm vazio' "$(energy_therm_issue '')" 'estado térmico ilegível ou em formato desconhecido (saída vazia)'
expect_has 'therm só com linhas em branco' "$(energy_therm_issue "$(printf '\n  \n\t\n')")" 'formato desconhecido (saída vazia)'
expect_has 'therm com lixo' "$(energy_therm_issue 'pmset: erro interno')" 'formato desconhecido (pmset: erro interno)'
expect_has 'linha desconhecida no meio das normais' "$(energy_therm_issue "$real
CPU power status: limited")" 'formato desconhecido (CPU power status: limited)'
expect_has 'linha "warning level ... recorded" que não é uma das conhecidas' "$(energy_therm_issue 'Note: No fancy warning level has been recorded')" 'formato desconhecido (Note: No fancy warning level has been recorded)'
expect_has 'campo CPU_* com número enorme' "$(energy_therm_issue "$(printf 'CPU_Speed_Limit \t= 99999999999999999999')")" 'formato desconhecido (CPU_Speed_Limit'
expect_has 'campo CPU_* fora do formato (sem o sinal =)' "$(energy_therm_issue 'CPU_Speed_Limit: 70')" 'formato desconhecido (CPU_Speed_Limit: 70)'
classify 'bateria 80 discharging 0 normal' 'bateria 79 discharging 0 cpus4' 0
expect_has 'CPU_Available_CPUs abaixo do hw.ncpu: inconclusiva' "$E_CLASS" 'CPUs disponíveis (4 de 8)'; expect 'CPUs disponíveis: não interrompe a série' "$E_STOP" 0
for ncpu in 4 '' abc; do
    FAKE_NCPU=$ncpu; export FAKE_NCPU; classify 'bateria 80 discharging 0 cpus4' 'bateria 79 discharging 0 cpus4' 0
    expect "hw.ncpu '$ncpu' (igual ou sem número, não confere): válida" "$E_CLASS" 'válida'
done
unset FAKE_NCPU

# 2c) lowpowermode: só 0 ou 1 (espaço ou TAB); ausente, ilegível, 2 ou lixo é DESCONHECIDO: perfil PRÓPRIO, com AVISO, que continua e REGISTRA (nunca recusa, nunca troca a configuração).
for low in ausente 2 lixo 12 0x; do
    set_state "$S" bateria 80 discharging $low normal; start_ok auto
    expect "lowpowermode '$low': desconhecido, perfil próprio" "$E_LOW/$E_LABEL" '?/bateria (baixo consumo DESCONHECIDO)'; expect_has "lowpowermode '$low': AVISO" "$E_WARNING" 'não consegui ler o baixo consumo'
done
set_state "$S" tomada 100 charged ausente normal; start_ok auto; expect 'lowpowermode ausente na tomada' "$E_LABEL" 'tomada (baixo consumo DESCONHECIDO)'
set_state "$S" bateria 80 discharging tab0 normal; start_ok auto; expect 'lowpowermode separado por TAB, com 0: lido, sem aviso' "$E_LOW/$E_LABEL/$E_WARNING" '0/bateria/'
set_state "$S" bateria 80 discharging tab1 normal; start_ok auto; expect 'lowpowermode separado por TAB, com 1: LIGADO' "$E_LOW/$E_LABEL" '1/bateria (baixo consumo LIGADO)'
classify 'bateria 80 discharging ausente normal' 'bateria 79 discharging ausente normal' 0; expect '? no começo e ? depois NÃO é mudança: válida' "$E_CLASS" 'válida'
classify 'bateria 80 discharging ausente normal' 'bateria 79 discharging 0 normal' 0; expect_has '? virando 0: mudou' "$E_CLASS" 'o modo de baixo consumo mudou (lowpowermode ? no começo; ? antes, 0 depois)'
classify 'bateria 80 discharging 0 normal' 'bateria 79 discharging ausente normal' 0; expect_has '0 virando ?: mudou' "$E_CLASS" 'o modo de baixo consumo mudou (lowpowermode 0 no começo; 0 antes, ? depois)'
classify 'bateria 80 discharging 1 normal' 'bateria 79 discharging ausente normal' 0; expect_has '1 virando ?: mudou' "$E_CLASS" 'o modo de baixo consumo mudou (lowpowermode 1 no começo; 1 antes, ? depois)'

# 3) O script REAL recusa antes de criar a pasta de trabalho. Roda numa CÓPIA dos dois arquivos (sem art_samples/) e com GODOT_BIN=/nao/existe: se uma recusa regredir, o script falha cedo com OUTRA mensagem
# ("Godot não encontrado"), em segundos, sem rede, sem download e sem janela, e o teste reprova (antes, num Mac com o Godot no caminho padrão, ele seguia até baixar 1,28 GB, exportar e abrir janela).
mkdir -p "$work/proj/tests/soak"; cp "$project_dir/tests/soak/run_game_release" "$project_dir/tests/soak/game_release_energy.sh" "$work/proj/tests/soak/"; chmod +x "$work/proj/tests/soak/run_game_release"
script_run() { env GODOT_BIN=/nao/existe "$@" "$work/proj/tests/soak/run_game_release" "$work/pasta_nunca_criada" < /dev/null 2>&1; }
refusal() { # $1 = rótulo, $2 = trecho da mensagem; o resto = variáveis de ambiente do script
    label=$1; fragment=$2; shift 2
    if out=$(script_run "$@"); then echo "FALHA: $label: o script deveria recusar"; exit 1; fi
    expect_has "$label" "$out" "$fragment"
    [ ! -e "$work/pasta_nunca_criada" ] || { echo "FALHA: $label: o script criou a pasta de trabalho antes de recusar"; exit 1; }
}
set_state "$S" tomada 100 charged 0 normal; refusal 'script: PERFIL=bateria na tomada' 'não rotula errado' PERFIL=bateria
set_state "$S" bateria 25 discharging 0 normal; refusal 'script: bateria a 25%' 'abaixo do mínimo para começar' PERFIL=auto
set_state "$S" bateria 80 discharging 0 normal; refusal 'script: BATERIA_MIN_PARADA abaixo do piso' 'abaixo do piso 10' BATERIA_MIN_PARADA=5
refusal 'script: CURTA inválida' 'CURTA deve ser 0 ou 1' CURTA=2
refusal 'script: PERFIL desconhecido' 'PERFIL deve ser' PERFIL=xyz
refusal 'script: LW_ART_SAMPLES inválido' 'LW_ART_SAMPLES deve ser 0 ou 1' LW_ART_SAMPLES=2
refusal 'script: LW_ART_SAMPLES=1 sem a pasta art_samples' 'LW_ART_SAMPLES=1, mas falta' LW_ART_SAMPLES=1
for var in BATERIA_MIN_INICIO BATERIA_MIN_PARADA BATERIA_QUEDA_MAX; do
    for value in 99999999999999999999 1000; do refusal "script: $var=$value" 'devem ser inteiros de 0 a 999' "$var=$value"; done
done
if out=$(script_run); then echo 'FALHA: sem recusa e sem Godot o script deveria falhar cedo'; exit 1; fi
expect_has 'script sem recusa e sem Godot: falha cedo com OUTRA mensagem (e o teste reprova rápido)' "$out" "Godot não encontrado em '/nao/existe'"
[ ! -e "$work/pasta_nunca_criada" ] || { echo 'FALHA: o script criou a pasta de trabalho sem o Godot'; exit 1; }

# 3b) O script REAL até o fim no modo --editor com o jogo FALSO como GODOT_BIN (sem Godot, git, download nem janela): PERFIL vazio = auto, CURTA=1 e o AVISO do baixo consumo desconhecido.
editor_run() { dir=$1; shift; env GODOT_BIN="$work/bin/jogo_falso" "$@" "$work/proj/tests/soak/run_game_release" --editor "$work/$dir" < /dev/null 2>&1; }
set_state "$S" bateria 80 discharging 0 normal; echo 0 > "$S/contagem"
out=$(editor_run curta CURTA=1 RUNS=3 ENSAIOS=rota,parado,pausado PERFIL=)
expect_has 'CURTA=1 repassa o povoado e --segundos 10 ao jogo' "$out" '-- --ensaios povoado --segundos 10'; expect_lacks 'CURTA=1 força o povoado (sem rota)' "$out" '--ensaios rota'
expect_has 'CURTA=1 força RUNS=1' "$out" '1 execução(ões), 1 válida(s) e 0 inconclusiva(s)'
[ -f "$work/curta/game_editor_run_1.txt" ] && [ ! -f "$work/curta/game_editor_run_2.txt" ] || { echo 'FALHA: CURTA=1 devia fazer só a execução 1'; exit 1; }; echo 'OK: CURTA=1 fez só 1 execução'
expect_has 'PERFIL vazio vira auto (na bateria rotula bateria)' "$out" 'perfil de energia: bateria (fonte bateria'; expect_has 'a CURTA entra no cabeçalho do arquivo' "$(cat "$work/curta/game_editor_run_1.txt")" 'DURAÇÃO: CURTA de 10 s'
expect_lacks 'baixo consumo conhecido: sem AVISO' "$out" 'AVISO:'
out=$(editor_run duas RUNS=2 ENSAIOS=povoado); expect_has 'sem CURTA: 2 execuções com o ENSAIOS pedido' "$out" '2 execução(ões), 2 válida(s) e 0 inconclusiva(s)'; expect_lacks 'sem CURTA: sem --segundos' "$out" '--segundos'
set_state "$S" bateria 80 discharging ausente normal; out=$(editor_run baixo CURTA=1)
expect_has 'lowpowermode ausente: perfil DESCONHECIDO na primeira linha' "$out" 'perfil de energia: bateria (baixo consumo DESCONHECIDO) (fonte bateria'; expect_has 'lowpowermode ausente: AVISO no começo da série' "$out" 'AVISO: não consegui ler o baixo consumo'
expect_has 'lowpowermode ausente: o arquivo da execução leva o perfil próprio' "$(cat "$work/baixo/game_editor_run_1.txt")" 'PERFIL: bateria (baixo consumo DESCONHECIDO)'; expect_has 'lowpowermode ausente: a execução segue e é válida' "$out" 'RESUMO (bateria (baixo consumo DESCONHECIDO), FIGURA sem'

# 3c) As opções NOVAS do script (7c-1c): LW_BUILD_ONLY, LW_RUN_ONLY e LW_RELEASE_BIN. As recusas vêm ANTES do Godot e de qualquer download (GODOT_BIN=/nao/existe). Depois, com o Godot, o binário de release, o curl e o
# projeto FALSOS (um `git init` numa pasta temporária), o fluxo de SEMPRE (sem as opções: constrói e roda) e o novo: construir UMA vez (nada rodou) e rodar várias (nada baixado, copiado nem exportado).
set_state "$S" bateria 80 discharging 0 normal
refusal 'script: LW_BUILD_ONLY inválido' 'LW_BUILD_ONLY deve ser 0 ou 1' LW_BUILD_ONLY=2
refusal 'script: LW_RUN_ONLY inválido' 'LW_RUN_ONLY deve ser 0 ou 1' LW_RUN_ONLY=x
refusal 'script: LW_BUILD_ONLY e LW_RUN_ONLY juntas' 'NÃO podem ficar ligadas juntas' LW_BUILD_ONLY=1 LW_RUN_ONLY=1
refusal 'script: LW_RELEASE_BIN que não é executável' 'não é um arquivo executável' LW_RELEASE_BIN=/nao/existe
refusal 'script: LW_RUN_ONLY numa pasta que nunca foi construída' 'não tem o jogo construído' LW_RUN_ONLY=1
if out=$(env GODOT_BIN=/nao/existe LW_BUILD_ONLY=1 "$work/proj/tests/soak/run_game_release" --editor "$work/pasta_nunca_criada" < /dev/null 2>&1); then echo 'FALHA: LW_BUILD_ONLY no modo --editor deveria recusar'; exit 1; fi
expect_has 'script: as opções novas no modo --editor' "$out" 'só valem no modo release'; [ ! -e "$work/pasta_nunca_criada" ] || { echo 'FALHA: o modo --editor criou a pasta antes de recusar'; exit 1; }
cat > "$work/bin/godot_falso" <<'FAKE'
#!/bin/sh
case "$*" in
    --version) echo '4.7.2.stable.official.falso';;
    *--export-pack*) for last; do :; done; echo PCK > "$last";;
esac
exit 0
FAKE
printf '#!/bin/sh\necho "curl $*" >> "$FAKE_STATE/rede"\nexit 1\n' > "$work/bin/curl"; chmod +x "$work/bin/godot_falso" "$work/bin/curl"; cp "$work/bin/jogo_falso" "$work/bin/release_falso"
printf 'run/main_scene="res://scenes/antiga.tscn"\n' > "$work/proj/project.godot"; printf 'art_samples/\n' > "$work/proj/.gitignore"; mkdir -p "$work/proj/art_samples"; echo '{}' > "$work/proj/art_samples/character_area.json"; echo '{}' > "$work/proj/art_samples/character_catalog.json"
git init -q "$work/proj"
e2e() { dir=$1; shift; env GODOT_BIN="$work/bin/godot_falso" LW_PROBE_COPY=worktree RUNS=1 ENSAIOS=povoado "$@" "$work/proj/tests/soak/run_game_release" "$work/$dir" < /dev/null 2>&1; }
has_file() { [ -f "$work/$1" ] || { echo "FALHA: devia existir $1"; exit 1; }; echo "OK: existe $1"; }
no_file() { [ ! -e "$work/$1" ] || { echo "FALHA: NÃO devia existir $1"; exit 1; }; echo "OK: não existe $1"; }
echo 0 > "$S/contagem"; mkdir -p "$work/e2e_padrao/bin"; : > "$work/e2e_padrao/.lw-release-probe"; cp "$work/bin/release_falso" "$work/e2e_padrao/bin/godot_release_falso"
out=$(e2e e2e_padrao); expect_has 'sem as opções: o fluxo de sempre, reaproveitando o binário' "$out" 'Reaproveitando o binário de release já extraído'
expect_has 'sem as opções: exporta o pacote e roda o jogo (1 válida)' "$out" 'Pacote criado:'; expect_has 'sem as opções: roda o jogo' "$out" '1 execução(ões), 1 válida(s) e 0 inconclusiva(s)'
for f in projeto/project.godot game.pck execucao/game_release execucao/game_release.pck game_release_run_1.txt; do has_file "e2e_padrao/$f"; done
no_file e2e_padrao/execucao/figura.txt; expect 'sem as opções: o jogo rodou 1 vez' "$(cat "$S/contagem")" 1
expect_has 'a cena principal foi trocada SÓ na cópia' "$(cat "$work/e2e_padrao/projeto/project.godot")" 'run/main_scene="res://tests/soak/game_release/game_release_main.tscn"'
echo 0 > "$S/contagem"; out=$(e2e e2e_sem LW_BUILD_ONLY=1 LW_RELEASE_BIN="$work/bin/release_falso")
expect_has 'LW_BUILD_ONLY: usa o binário indicado, sem baixar' "$out" 'Usando o binário de release indicado em LW_RELEASE_BIN (nada será baixado)'; expect_has 'LW_BUILD_ONLY: diz que construiu e sai' "$out" 'está construído em'
expect_lacks 'LW_BUILD_ONLY: NÃO roda o jogo' "$out" 'ENSAIO POVOADO de mentira'; expect 'LW_BUILD_ONLY: o jogo não rodou nenhuma vez' "$(cat "$S/contagem")" 0
for f in projeto/project.godot game.pck execucao/game_release execucao/game_release.pck execucao/figura.txt; do has_file "e2e_sem/$f"; done
no_file e2e_sem/game_release_run_1.txt; no_file e2e_sem/projeto/art_samples; expect 'LW_BUILD_ONLY: grava a condição SEM a figura' "$(cat "$work/e2e_sem/execucao/figura.txt")" sem
touch "$work/e2e_sem/projeto/marcador"; out=$(e2e e2e_sem LW_RUN_ONLY=1 RUNS=2)
expect_has 'LW_RUN_ONLY: 2 execuções válidas, com FIGURA sem' "$out" '2 execução(ões), 2 válida(s) e 0 inconclusiva(s)'; expect 'LW_RUN_ONLY: o jogo rodou 2 vezes' "$(cat "$S/contagem")" 2
has_file e2e_sem/game_release_run_1.txt; has_file e2e_sem/game_release_run_2.txt; expect_has 'LW_RUN_ONLY: FIGURA sem no arquivo' "$(cat "$work/e2e_sem/game_release_run_2.txt")" 'FIGURA: sem'
has_file e2e_sem/projeto/marcador; expect_lacks 'LW_RUN_ONLY: não copia nem exporta' "$out" 'Pacote criado'; no_file state/rede
if out=$(e2e e2e_sem LW_RUN_ONLY=1 LW_ART_SAMPLES=1); then echo 'FALHA: rodar a construção SEM a figura como COM deveria recusar'; exit 1; fi; expect_has 'LW_RUN_ONLY: a condição de figura NUNCA erra (sem construído, com pedido)' "$out" 'foi construída sem a figura, mas esta execução é com a figura'
out=$(e2e e2e_com LW_BUILD_ONLY=1 LW_ART_SAMPLES=1 LW_RELEASE_BIN="$work/bin/release_falso"); has_file e2e_com/projeto/art_samples/character_area.json; expect 'LW_BUILD_ONLY com LW_ART_SAMPLES=1: grava COM' "$(cat "$work/e2e_com/execucao/figura.txt")" com
if out=$(e2e e2e_com LW_RUN_ONLY=1); then echo 'FALHA: rodar a construção COM a figura como SEM deveria recusar'; exit 1; fi; expect_has 'LW_RUN_ONLY: a condição de figura NUNCA erra (com construído, sem pedido)' "$out" 'foi construída com a figura, mas esta execução é sem a figura'
out=$(e2e e2e_com LW_RUN_ONLY=1 LW_ART_SAMPLES=1 CURTA=1); expect_has 'LW_RUN_ONLY + CURTA=1 (a validação do roteiro)' "$out" 'ARGS -- --ensaios povoado --segundos 10'; expect_has 'LW_RUN_ONLY com LW_ART_SAMPLES=1: FIGURA com e CURTA no arquivo' "$(cat "$work/e2e_com/game_release_run_1.txt")" 'FIGURA: com'
no_file state/rede; echo 'OK: nenhum curl (nenhum download) em nenhum dos fluxos'

# 4) As execuções do run_trials com o jogo FALSO: o registro, a classificação, o resumo (as inconclusivas fora da conta) e as paradas.
series() { # $1 = nome, $2 = RUNS, o resto = o estado DEPOIS de cada execução (argumentos do set_state numa palavra só); o ANTES é o estado atual
    name=$1; runs=$2; shift 2
    mkdir -p "$work/$name"; FAKE_AFTER="$work/after_$name"; echo 0 > "$S/contagem"
    i=0; for after in "$@"; do i=$((i + 1)); set_state "$FAKE_AFTER/$i" $after; done
    ( WORK="$work/$name"; RUNS=$runs; ENSAIOS=${SERIES_ENSAIOS:-povoado}; GAME_EXTRA="${SERIES_EXTRA:-}"; FIGURA=sem; DURACAO=completa; start_ok auto; run_trials game_release "$work/bin/jogo_falso" ) 2>&1 || rc=$?
}
rc=0; set_state "$S" bateria 80 discharging 0 normal
out=$(series saudavel 2 'bateria 79 discharging 0 normal' 'bateria 78 discharging 0 normal')
expect_has 'série saudável: 2 válidas, 0 inconclusivas' "$out" '2 execução(ões), 2 válida(s) e 0 inconclusiva(s)'
expect_has 'o resumo avisa para NÃO comparar os perfis' "$out" 'NÃO compare os perfis bateria e tomada como equivalentes'
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
SERIES_ENSAIOS=povoado,rota; out=$(series faltam 1 'bateria 79 discharging 0 normal'); SERIES_ENSAIOS=''
expect_has 'menos ensaios que o pedido: inconclusiva' "$out" 'CLASSIFICAÇÃO: inconclusiva (o jogo não terminou os ensaios (código 0; 1 de 2 ensaios))'
set_state "$S" bateria 80 discharging 0 normal
FAKE_EXIT=1; export FAKE_EXIT; rc=0; out=$(series erro 2 'bateria 79 discharging 0 normal'); unset FAKE_EXIT
expect_has 'jogo que falha: classificação no arquivo' "$(cat "$work/erro/game_release_run_1.txt")" 'CLASSIFICAÇÃO: inconclusiva (o jogo não terminou os ensaios (código 1'; expect_has 'jogo que falha: o script aborta' "$out" 'terminou com erro'

# 5) O script e a biblioteca: sintaxe, sem a exigência de tomada, SÓ leitura da energia e o README sem a exigência de tomada na régua.
sh -n "$project_dir/tests/soak/run_game_release" && sh -n "$project_dir/tests/soak/game_release_energy.sh" && echo 'OK: sh -n no script e na biblioteca'
if grep -v '^[[:space:]]*#' "$project_dir/tests/soak/run_game_release" | grep -q 'AC Power\|saiu da tomada'; then echo 'FALHA: o script ainda exige a tomada'; exit 1; fi; echo 'OK: o script não exige mais a tomada'
if cat "$project_dir/tests/soak/run_game_release" "$project_dir/tests/soak/game_release_energy.sh" | grep -v '^[[:space:]]*#' | grep -Eq 'sudo|powermetrics|caffeinate|pmset +(-a|-b|-c|set)'; then echo 'FALHA: o medidor altera a energia'; exit 1; fi; echo 'OK: o medidor só LÊ a energia'
regua=$(grep -F 'Corpos dos NPCs e custo por seção (LW-072g)' "$project_dir/tests/soak/README.md" | head -1 || true)
expect_has 'README (LW-072g): a régua da DEC-119 aplica só os critérios NUMÉRICOS, em qualquer perfil' "$regua" 'critérios NUMÉRICOS'; expect_has 'README (LW-072g): diz que NÃO exige tomada' "$regua" 'NÃO exige tomada'
expect_lacks 'README (LW-072g): sem a frase velha "no Mac na tomada"' "$regua" 'na tomada'
echo 'ART-12 7c-1b: perfis de energia, travas e classificação do medidor aprovados.'
