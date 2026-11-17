# ART-12, 7c-1b: a ENERGIA e as EXECUÇÕES do medidor de quadros em release. Carregado com `. arquivo` pelo tests/soak/run_game_release e pelo tests/test_game_release_profile.sh (que põe um pmset FALSO no PATH).
# SÓ LEITURA: lê `pmset -g batt`, `pmset -g` (lowpowermode) e `pmset -g therm`; nada aqui altera configuração de energia, desliga proteção do macOS nem liga o baixo consumo. Se o baixo consumo está LIGADO, o
# medidor REGISTRA e o perfil vira outro ("bateria (baixo consumo LIGADO)"), que não se compara com o desligado. Os perfis bateria e tomada NUNCA se misturam: cada execução leva o seu rótulo.
# PERFIL: auto detecta pela 1ª linha do `pmset -g batt` e rotula; bateria ou tomada exigem essa fonte, senão o script RECUSA (nunca rotula errado). Travas [HIP] na bateria, por variável, SÓ para endurecer
# (valor mais frouxo que o piso/teto é RECUSADO, não ajustado em silêncio): BATERIA_MIN_INICIO=30 (piso 20, não começa abaixo disso, em %); BATERIA_MIN_PARADA=20 (piso 10, ao fim de uma execução abaixo
# disso as que faltam NÃO rodam); BATERIA_QUEDA_MAX=5 (teto 10, pontos que UMA execução pode gastar; mais que isso ela é inconclusiva e as que faltam NÃO rodam).
BATERIA_MIN_INICIO=${BATERIA_MIN_INICIO:-30}
BATERIA_MIN_PARADA=${BATERIA_MIN_PARADA:-20}
BATERIA_QUEDA_MAX=${BATERIA_QUEDA_MAX:-5}
PISO_MIN_INICIO=20
PISO_MIN_PARADA=10
TETO_QUEDA_MAX=10

# Lê a energia AGORA: E_SOURCE (bateria|tomada|desconhecida), E_PERCENT, E_STATE, E_LOW (lowpowermode 0|1) e E_THERM (as linhas inteiras do `pmset -g therm`).
energy_read() {
    batt=$(pmset -g batt 2> /dev/null || true)
    case "$(printf '%s\n' "$batt" | head -1)" in
        *"'Battery Power'"*) E_SOURCE=bateria;;
        *"'AC Power'"*) E_SOURCE=tomada;;
        *) E_SOURCE=desconhecida;;
    esac
    E_PERCENT=$(printf '%s\n' "$batt" | sed -n 's/.*[^0-9]\([0-9][0-9]*\)%.*/\1/p' | head -1)
    E_STATE=$(printf '%s\n' "$batt" | sed -n 's/.*%; *\([^;]*\);.*/\1/p' | head -1)
    E_LOW=$(pmset -g 2> /dev/null | sed -n 's/^ *lowpowermode *\([01]\).*/\1/p' | head -1)
    E_THERM=$(pmset -g therm 2> /dev/null || true)
}
energy_before() { energy_read; B_SOURCE=$E_SOURCE; B_PERCENT=$E_PERCENT; B_STATE=$E_STATE; B_LOW=$E_LOW; B_THERM=$E_THERM; }
energy_after() { energy_read; A_SOURCE=$E_SOURCE; A_PERCENT=$E_PERCENT; A_STATE=$E_STATE; A_LOW=$E_LOW; A_THERM=$E_THERM; }

# Confere os números das travas; devolve 1 com E_MESSAGE se algum é inválido ou mais frouxo que o piso/teto.
energy_check_limits() {
    case "$BATERIA_MIN_INICIO$BATERIA_MIN_PARADA$BATERIA_QUEDA_MAX" in *[!0-9]*) E_MESSAGE="BATERIA_MIN_INICIO, BATERIA_MIN_PARADA e BATERIA_QUEDA_MAX devem ser inteiros (recebi '$BATERIA_MIN_INICIO', '$BATERIA_MIN_PARADA', '$BATERIA_QUEDA_MAX')."; return 1;; esac
    if [ "$BATERIA_MIN_INICIO" -lt "$PISO_MIN_INICIO" ]; then E_MESSAGE="BATERIA_MIN_INICIO=$BATERIA_MIN_INICIO está abaixo do piso $PISO_MIN_INICIO: a variável só pode ENDURECER a trava."; return 1; fi
    if [ "$BATERIA_MIN_PARADA" -lt "$PISO_MIN_PARADA" ]; then E_MESSAGE="BATERIA_MIN_PARADA=$BATERIA_MIN_PARADA está abaixo do piso $PISO_MIN_PARADA: a variável só pode ENDURECER a trava."; return 1; fi
    if [ "$BATERIA_QUEDA_MAX" -gt "$TETO_QUEDA_MAX" ]; then E_MESSAGE="BATERIA_QUEDA_MAX=$BATERIA_QUEDA_MAX passa do teto $TETO_QUEDA_MAX: a variável só pode ENDURECER a trava."; return 1; fi
    return 0
}

# Começa a série: lê a energia, fixa o perfil (PROFILE_SOURCE, PROFILE_LOW) e o RÓTULO (E_LABEL). Devolve 1 com E_MESSAGE se deve RECUSAR. $1 = PERFIL pedido (auto|bateria|tomada).
energy_start() {
    energy_check_limits || return 1
    case "$1" in auto|bateria|tomada) ;; *) E_MESSAGE="PERFIL deve ser auto, bateria ou tomada (recebi '$1')."; return 1;; esac
    energy_read
    if [ "$E_SOURCE" = desconhecida ]; then E_MESSAGE="Não consegui ler a fonte de energia (pmset -g batt): sem ela o perfil não pode ser rotulado."; return 1; fi
    if [ "$1" != auto ] && [ "$1" != "$E_SOURCE" ]; then E_MESSAGE="PERFIL=$1, mas o Mac está na fonte '$E_SOURCE': o medidor não rotula errado. Mude a fonte ou use PERFIL=auto."; return 1; fi
    if [ "$E_SOURCE" = bateria ]; then
        if [ -z "$E_PERCENT" ]; then E_MESSAGE="O Mac está na bateria, mas não consegui ler a porcentagem (pmset -g batt): sem ela as travas de segurança não valem."; return 1; fi
        if [ "$E_PERCENT" -lt "$BATERIA_MIN_INICIO" ]; then E_MESSAGE="A bateria está em $E_PERCENT%, abaixo do mínimo para começar ($BATERIA_MIN_INICIO%): carregue o Mac ou use o perfil tomada. Medir com a bateria baixa não vale e gasta o que falta."; return 1; fi
    fi
    PROFILE_SOURCE=$E_SOURCE; PROFILE_LOW=$E_LOW; E_LABEL=$E_SOURCE
    if [ "$E_LOW" = 1 ]; then E_LABEL="$E_SOURCE (baixo consumo LIGADO)"; fi
    return 0
}

# O motivo se o texto do `pmset -g therm` ($1) registra aviso térmico ou de desempenho, ou CPU_Scheduler_Limit/CPU_Speed_Limit abaixo de 100; nada impresso = normal.
energy_therm_issue() {
    warn=$(printf '%s\n' "$1" | grep -i 'warning level' | grep -vi 'has been recorded' | head -1 || true)
    if [ -n "$warn" ]; then printf 'aviso térmico ou de desempenho (%s)' "$warn"; return 0; fi
    for item in $(printf '%s\n' "$1" | sed -n -E 's/.*(CPU_Scheduler_Limit|CPU_Speed_Limit)[^0-9]*([0-9]+).*/\1=\2/p'); do
        if [ "${item#*=}" -lt 100 ]; then printf 'limitação de CPU (%s)' "$item"; return 0; fi
    done
    return 0
}

energy_reason() { E_REASONS="${E_REASONS:+$E_REASONS; }$1"; }

# Classifica a execução que acabou (compara B_* com A_*; $1 = código de saída do jogo, $2 = ensaios feitos, $3 = ensaios pedidos): E_CLASS = "válida" ou "inconclusiva (motivos)"; E_STOP = 1 se as
# execuções que faltam NÃO devem rodar (a bateria passou dos limites ou a fonte mudou).
energy_classify() {
    E_REASONS=''; E_STOP=0
    if [ "$1" != 0 ] || [ "$2" -lt "$3" ]; then energy_reason "o jogo não terminou os ensaios (código $1; $2 de $3 ensaios)"; fi
    if [ "$B_SOURCE" != "$PROFILE_SOURCE" ] || [ "$A_SOURCE" != "$PROFILE_SOURCE" ]; then energy_reason "a fonte de energia mudou (começou na $PROFILE_SOURCE; antes $B_SOURCE, depois $A_SOURCE): o perfil deixou de valer"; E_STOP=1; fi
    if [ "$B_LOW" != "$PROFILE_LOW" ] || [ "$A_LOW" != "$PROFILE_LOW" ]; then energy_reason "o modo de baixo consumo mudou (lowpowermode ${PROFILE_LOW:-?} no começo; ${B_LOW:-?} antes, ${A_LOW:-?} depois)"; fi
    if [ "$PROFILE_SOURCE" = bateria ]; then
        if [ -z "$B_PERCENT" ] || [ -z "$A_PERCENT" ]; then
            energy_reason "não consegui ler a porcentagem da bateria"
        else
            drop=$((B_PERCENT - A_PERCENT))
            if [ "$drop" -gt "$BATERIA_QUEDA_MAX" ]; then energy_reason "a bateria caiu $drop pontos (máximo $BATERIA_QUEDA_MAX)"; E_STOP=1; fi
            if [ "$A_PERCENT" -lt "$BATERIA_MIN_PARADA" ]; then energy_reason "a bateria passou do limite de parada ($A_PERCENT%, mínimo $BATERIA_MIN_PARADA%)"; E_STOP=1; fi
        fi
    fi
    issue=$(energy_therm_issue "$B_THERM"); if [ -n "$issue" ]; then energy_reason "estado térmico fora do normal ANTES: $issue"; fi
    issue=$(energy_therm_issue "$A_THERM"); if [ -n "$issue" ]; then energy_reason "estado térmico fora do normal DEPOIS: $issue"; fi
    if [ "$B_THERM" != "$A_THERM" ]; then energy_reason "o pmset -g therm mudou durante a execução"; fi
    if [ -z "$E_REASONS" ]; then E_CLASS='válida'; else E_CLASS="inconclusiva ($E_REASONS)"; fi
}

# O registro de energia de uma execução: a linha de energia e as linhas INTEIRAS do `pmset -g therm`. $1 = B (antes) ou A (depois).
energy_lines() {
    if [ "$1" = B ]; then e_when=antes; e_src=$B_SOURCE; e_pct=$B_PERCENT; e_st=$B_STATE; e_low=$B_LOW; e_therm=$B_THERM; else e_when=depois; e_src=$A_SOURCE; e_pct=$A_PERCENT; e_st=$A_STATE; e_low=$A_LOW; e_therm=$A_THERM; fi
    printf 'energia (%s): fonte %s, bateria %s%% (%s), baixo consumo (lowpowermode) %s\n' "$e_when" "$e_src" "${e_pct:-?}" "${e_st:-?}" "${e_low:-?}"
    printf 'estado térmico (%s), pmset -g therm:\n' "$e_when"
    printf '%s\n' "$e_therm" | sed 's/^/  /'
}

# As execuções: $1 = prefixo do arquivo de saída; o resto = comando do jogo (cada palavra entre aspas: o caminho do Godot tem espaço). Usa WORK, RUNS, ENSAIOS, GAME_EXTRA, FIGURA, DURACAO e o perfil de
# energy_start. Cada arquivo leva o cabeçalho (perfil, figura, duração, máquina, energia e térmico ANTES), a saída do jogo, a energia DEPOIS e "CLASSIFICAÇÃO: válida" ou "inconclusiva (motivos)".
run_trials() {
    prefix=$1; shift
    last=0
    for existing_out in "$WORK"/"$prefix"_run_*.txt; do
        [ -f "$existing_out" ] || continue
        number=$(basename "$existing_out" .txt | sed "s/^${prefix}_run_//")
        case "$number" in ''|*[!0-9]*) continue;; esac
        [ "$number" -gt "$last" ] && last=$number
    done
    n=$((last + 1)); end=$((last + RUNS)); valid=0; inconclusive=0; listed=''
    expected=$(printf '%s' "$ENSAIOS" | tr ',' '\n' | grep -c . || true)
    while [ "$n" -le "$end" ]; do
        out=$WORK/${prefix}_run_$n.txt
        echo "--- execução $n (cerca de 2,5 minutos, com janela) -> $out"
        energy_before
        printf 'PERFIL: %s\nFIGURA: %s\nDURAÇÃO: %s\nDATA: %s\n' "$E_LABEL" "$FIGURA" "$DURACAO" "$(date '+%Y-%m-%d %H:%M:%S %z')" > "$out"
        printf 'MÁQUINA: %s, %s, macOS %s; binário %s\n' "$(sysctl -n hw.model 2> /dev/null || echo '?')" "$(sysctl -n machdep.cpu.brand_string 2> /dev/null || echo '?')" "$(sw_vers -productVersion 2> /dev/null || echo '?')" "$1" >> "$out"
        energy_lines B >> "$out"
        code=0
        "$@" -- --ensaios "$ENSAIOS" $GAME_EXTRA >> "$out" 2>&1 || code=$?
        energy_after
        energy_lines A >> "$out"
        energy_classify "$code" "$(grep -c '^ENSAIO ' "$out" || true)" "$expected"
        echo "CLASSIFICAÇÃO: $E_CLASS" >> "$out"
        [ "$code" = 0 ] || { cat "$out" >&2; fail "A execução $n terminou com erro (saída acima)."; }
        cat "$out"
        if [ "$E_CLASS" = 'válida' ]; then valid=$((valid + 1)); else inconclusive=$((inconclusive + 1)); listed="${listed:+$listed; }execução $n: ${E_CLASS#inconclusiva }"; fi
        if [ "$E_STOP" = 1 ]; then echo "INTERROMPIDO após a execução $n: $E_CLASS. As execuções que faltam NÃO serão feitas."; break; fi
        n=$((n + 1))
    done
    echo "RESUMO ($E_LABEL, FIGURA $FIGURA, duração $DURACAO): $((valid + inconclusive)) execução(ões), $valid válida(s) e $inconclusive inconclusiva(s)${listed:+ [$listed]}. As inconclusivas NÃO entram em nenhuma estatística; NÃO compare os perfis bateria e tomada como equivalentes."
}
