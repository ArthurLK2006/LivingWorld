#!/bin/sh
# ART-12, 7c-1c: o ROTEIRO tests/soak/medir_figura, SEM janela, SEM Godot, SEM rede e SEM bateria: um run_game_release FALSO (LW_RUN_GAME_RELEASE) registra cada chamada e escreve arquivos de execução de mentira no formato do
# medidor; um compare FALSO (LW_COMPARE_GAME_RELEASE) registra os argumentos. Confere a ORDEM sem/com/sem/com/sem/com, a validação CURTA primeiro, a construção UMA vez por condição (2 chamadas de construção, não 6), a
# PARADA na primeira inconclusiva (e na validação, na recusa, na troca de perfil), a chamada final da comparação só com as pastas DESTA rodada e as variáveis de segurança passando adiante sem afrouxar. Um caso usa a
# comparação REAL sobre os arquivos falsos.
set -eu
project_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
work=$(mktemp -d "${TMPDIR:-/tmp}/lw_medir_test.XXXXXX")
trap 'rm -rf "$work"' EXIT HUP INT TERM
script="$project_dir/tests/soak/medir_figura"; real_compare="$project_dir/tests/soak/compare_game_release"
expect() { [ "$2" = "$3" ] || { echo "FALHA: $1: esperado '$3', veio '$2'"; exit 1; }; echo "OK: $1"; }
expect_has() { case "$2" in *"$3"*) echo "OK: $1";; *) echo "FALHA: $1: sem '$3' em '$2'"; exit 1;; esac; }
expect_lacks() { case "$2" in *"$3"*) echo "FALHA: $1: não devia ter '$3'"; exit 1;; *) echo "OK: $1";; esac; }
cat > "$work/run_falso" <<'FAKE'
#!/bin/sh
dir=$1; cond=$(basename "$dir")
printf 'BUILD=%s RUN=%s COND=%s ART=%s CURTA=%s ENSAIOS=%s RUNS=%s PERFIL=%s INICIO=%s BIN=%s\n' "${LW_BUILD_ONLY:-0}" "${LW_RUN_ONLY:-0}" "$cond" "${LW_ART_SAMPLES:-0}" "${CURTA:-0}" "${ENSAIOS:-}" "${RUNS:-}" "${PERFIL:-auto}" "${BATERIA_MIN_INICIO:-30}" "${LW_RELEASE_BIN:-}" >> "$FAKE_LOG"
if [ "${LW_BUILD_ONLY:-0}" = 1 ]; then
    if [ "${FAKE_BUILD_FAIL:-}" = "$cond" ]; then echo 'ERRO: construção recusada pelo falso' >&2; exit 1; fi
    mkdir -p "$dir/execucao"; echo "construído: $cond"; exit 0
fi
n=$(($(cat "$FAKE_COUNT") + 1)); echo "$n" > "$FAKE_COUNT"
if [ "${FAKE_REFUSE_AT:-}" = "$n" ]; then echo 'ERRO: execução recusada pelo falso' >&2; exit 1; fi
cls='válida'; [ "${FAKE_BAD_AT:-}" != "$n" ] || cls='inconclusiva (a bateria caiu 6 pontos (máximo 5))'
label=bateria; [ "${FAKE_LABEL_AT:-}" != "$n" ] || label='bateria (baixo consumo LIGADO)'
fig=sem; [ "${LW_ART_SAMPLES:-0}" != 1 ] || fig=com
dur=completa; [ "${CURTA:-0}" != 1 ] || dur='CURTA de 10 s (VALIDAÇÃO DO INSTRUMENTO: sem veredito DEC-119)'
k=$(ls "$dir"/game_release_run_*.txt 2> /dev/null | wc -l); k=$((k + 1)); out=$dir/game_release_run_$k.txt
{
    printf 'PERFIL: %s\nFIGURA: %s\nDURAÇÃO: %s\n' "$label" "$fig" "$dur"
    printf 'carga da cena principal (fora das seções do quadro; o preparo da figura acontece aqui): ler o arquivo 1.0 ms, instanciar e adicionar 100.0 ms\n'
    printf 'ENSAIO POVOADO 30 s com o jogador no centro de A, NPCs saindo de casa\n'
    printf '  quadros 1800, média 12.50 ms, mediana 12.00 ms, percentil 99 14.00 ms, pior (sem os 3 primeiros) 18.0 ms\n  acima de 16,7 ms: 100 · acima de 33 ms: 0\n'
    printf '  custo por seção, em ms por quadro (média / pior): NpcBodiesView 0.10 / 1.20 | NpcBodyDriver 0.20 / 2.30 | resto do quadro 12.20 / 28.00\n'
    printf '  VEREDITO DEC-119: PASSA (média 80.0 fps, 0 quadros acima de 33 ms; a DEC-119 exige média de 60 fps ou mais e nenhum quadro acima de 33 ms)\n'
    figs=${FAKE_FIGS:-1}; [ "${FAKE_NOFIG_AT:-}" != "$n" ] || figs=0
    [ "$fig" = sem ] || printf '  figuras ativas: máximo %s, no fim 1, de no máximo 50 corpos; NPC da figura: 33\n' "$figs"
    printf 'CLASSIFICAÇÃO: %s\n' "$cls"
} > "$out"
echo "perfil de energia: $label (fonte bateria)"; echo "--- execução $k -> $out"; cat "$out"
exit 0
FAKE
printf '#!/bin/sh\necho "$*" >> "$FAKE_COMPARE_LOG"\necho "COMPARAÇÃO FALSA"\nexit "${FAKE_COMPARE_EXIT:-0}"\n' > "$work/compare_falso"; chmod +x "$work/run_falso" "$work/compare_falso"
unset PERFIL BATERIA_MIN_INICIO BATERIA_MIN_PARADA BATERIA_QUEDA_MAX LW_ART_SAMPLES CURTA RUNS ENSAIOS GODOT_BIN LW_PROBE_COPY LW_BUILD_ONLY LW_RUN_ONLY LW_RELEASE_BIN FAKE_BAD_AT FAKE_NOFIG_AT FAKE_REFUSE_AT FAKE_LABEL_AT FAKE_FIGS FAKE_BUILD_FAIL
new_base() { mkdir -p "$work/base_$1/bin"; : > "$work/base_$1/bin/godot_release_falso"; chmod +x "$work/base_$1/bin/godot_release_falso"; : > "$work/log_$1"; echo 0 > "$work/count_$1"; : > "$work/cmp_$1"; }
roteiro() { # $1 = nome do caso; o resto = variáveis de ambiente do caso (o compare é o FALSO, salvo LW_COMPARE_GAME_RELEASE=...)
    name=$1; shift; base=$work/base_$name; [ -d "$base" ] || new_base "$name"
    rc=0; out=$(env FAKE_LOG="$work/log_$name" FAKE_COUNT="$work/count_$name" FAKE_COMPARE_LOG="$work/cmp_$name" LW_RUN_GAME_RELEASE="$work/run_falso" LW_COMPARE_GAME_RELEASE="$work/compare_falso" "$@" "$script" "$base" < /dev/null 2>&1) || rc=$?
}
seq_of() { awk '{ b = 0; c = ""; k = 0; for (i = 1; i <= NF; i++) { split($i, kv, "="); if (kv[1] == "BUILD") b = kv[2]; else if (kv[1] == "COND") c = kv[2]; else if (kv[1] == "CURTA") k = kv[2] } printf "%s%s", (NR > 1 ? " " : ""), (b == 1 ? "B:" c : "R:" c (k == 1 ? ":curta" : "")) } END { print "" }' "$work/log_$1"; }
full='B:com R:com:curta B:sem R:sem R:com R:sem R:com R:sem R:com'

# 1) A rodada completa: a validação CURTA primeiro, a construção UMA vez por condição, a ordem sem/com/sem/com/sem/com e a comparação por último, só com as pastas DESTA rodada (uma rodada antiga existe e não entra).
new_base cheio; mkdir -p "$work/base_cheio/figura_antiga/sem"; echo 'PERFIL: tomada' > "$work/base_cheio/figura_antiga/sem/game_release_run_1.txt"
roteiro cheio PERFIL=bateria BATERIA_MIN_INICIO=40
expect 'rodada completa: código 0' "$rc" 0
expect 'a ordem: CURTA primeiro, construção de cada condição, depois sem/com/sem/com/sem/com' "$(seq_of cheio)" "$full"
expect 'a construção roda 2 vezes (uma por condição), não 6' "$(grep -c '^BUILD=1 ' "$work/log_cheio")" 2
expect 'a validação CURTA vem antes de qualquer execução da comparação' "$(sed -n '2p' "$work/log_cheio" | grep -c 'CURTA=1')" 1
expect 'as 6 execuções da comparação são do ensaio povoado, 1 por chamada, sem CURTA' "$(grep '^BUILD=0 RUN=1 ' "$work/log_cheio" | grep -c 'CURTA=0 ENSAIOS=povoado RUNS=1 ')" 6
expect 'COM a figura: LW_ART_SAMPLES=1 na construção, na CURTA e nas 3 execuções com' "$(grep -c 'COND=com ART=1 ' "$work/log_cheio")" 5
expect 'SEM a figura: LW_ART_SAMPLES=0 na construção e nas 3 execuções sem' "$(grep -c 'COND=sem ART=0 ' "$work/log_cheio")" 4
expect 'o binário de release já extraído vai para as 2 construções (nada baixado)' "$(grep '^BUILD=1 ' "$work/log_cheio" | grep -c "BIN=$work/base_cheio/bin/godot_release_falso\$")" 2
expect 'as variáveis de segurança (PERFIL e BATERIA_MIN_INICIO) passam por TODAS as 9 chamadas, sem afrouxar' "$(grep -c 'PERFIL=bateria INICIO=40 ' "$work/log_cheio")" 9
expect 'a comparação roda UMA vez' "$(wc -l < "$work/cmp_cheio" | tr -d ' ')" 1
case "$(cat "$work/cmp_cheio")" in "$work/base_cheio"/figura_2*/sem\ "$work/base_cheio"/figura_2*/com) echo 'OK: a comparação recebe SÓ as pastas sem/ e com/ desta rodada (a antiga não entra)';; *) echo "FALHA: argumentos da comparação: $(cat "$work/cmp_cheio")"; exit 1;; esac
expect_has 'a comparação vem DEPOIS da última execução' "${out%%COMPARAÇÃO FALSA*}" 'Execução 6 de 6: com a figura (par 3 de 3)'
expect_has 'diz quantas rodou' "$out" 'Rodou 6 de 6 execuções da comparação.'; expect_has 'diz que não exige tomada' "$out" 'não exige tomada'

# 2) Com a comparação REAL sobre os arquivos falsos (iguais com e sem): a CURTA fica fora, 3 válidas por condição e o delta dentro da dispersão.
roteiro real LW_COMPARE_GAME_RELEASE="$real_compare"
expect 'comparação real: código 0' "$rc" 0; expect_has 'comparação real: o aviso dos perfis' "$out" 'NÃO compare os perfis bateria e tomada como equivalentes: cada perfil tem a sua tabela.'
expect_has 'comparação real: sem 3 válidas' "$out" 'FIGURA sem: 3 execução(ões): 3 válida(s) e 0 inconclusiva(s)'; expect_has 'comparação real: com 3 válidas (a CURTA não conta)' "$out" 'FIGURA com: 3 execução(ões): 3 válida(s) e 0 inconclusiva(s)'
expect_has 'comparação real: a CURTA é ignorada' "$out" 'IGNORADA(s): 1'; expect_has 'comparação real: o delta' "$out" 'abaixo do ruído (3 execuções por condição)'

# 3) PARA na primeira execução inconclusiva e diz quantas rodou (a comparação ainda lê o que rodou).
roteiro para3 FAKE_BAD_AT=4
expect 'inconclusiva na 3ª da comparação: código 1' "$rc" 1
expect 'para na primeira inconclusiva: nada roda depois dela' "$(seq_of para3)" 'B:com R:com:curta B:sem R:sem R:com R:sem'
expect_has 'diz quantas rodou e por quê' "$out" 'Rodou 3 de 6 execuções da comparação; PARADO: a execução 3 (sem a figura) saiu INCONCLUSIVA (CLASSIFICAÇÃO: inconclusiva (a bateria caiu 6 pontos'
expect 'a comparação lê o que rodou (UMA chamada)' "$(wc -l < "$work/cmp_para3" | tr -d ' ')" 1
roteiro para1 FAKE_BAD_AT=2; expect 'inconclusiva na 1ª da comparação: para ali' "$(seq_of para1)" 'B:com R:com:curta B:sem R:sem'; expect_has 'rodou 1 de 6' "$out" 'Rodou 1 de 6 execuções'
roteiro semfig FAKE_NOFIG_AT=3; expect 'execução COM sem figura ativa: para (as que faltam não gastam bateria)' "$(seq_of semfig)" 'B:com R:com:curta B:sem R:sem R:com'
expect_has 'execução COM sem figura ativa: diz quantas rodou e por quê' "$out" 'Rodou 2 de 6 execuções da comparação; PARADO: a execução 2 (com a figura) não mostrou nenhuma figura ativa'
roteiro muda FAKE_LABEL_AT=4; expect 'o perfil de energia mudou entre as execuções: para' "$(seq_of muda)" 'B:com R:com:curta B:sem R:sem R:com R:sem'
expect_has 'perfis diferentes não se misturam' "$out" "o perfil de energia mudou entre as execuções (de 'bateria' para 'bateria (baixo consumo LIGADO)')"
roteiro recusa FAKE_REFUSE_AT=3; expect 'execução recusada: para' "$(seq_of recusa)" 'B:com R:com:curta B:sem R:sem R:com'; expect_has 'execução recusada: diz RECUSADA e quantas rodou' "$out" 'Rodou 1 de 6 execuções da comparação; PARADO: a execução 2 (com a figura) foi RECUSADA'

# 4) A validação CURTA primeiro e a parada nela: inconclusiva, sem figura ativa, recusada e a construção que falha. Nada da comparação roda (o compare falso não foi chamado) e o código é 1.
stopped() { expect "$1: código 1" "$rc" 1; [ ! -s "$work/cmp_$2" ] || { echo "FALHA: $1: a comparação rodou"; exit 1; }; echo "OK: $1: nenhuma comparação"; }
roteiro v1 FAKE_BAD_AT=1; expect 'CURTA inconclusiva: só a construção COM e a CURTA' "$(seq_of v1)" 'B:com R:com:curta'; expect_has 'CURTA inconclusiva: diz o motivo' "$out" 'a medição CURTA saiu INCONCLUSIVA'; stopped 'CURTA inconclusiva' v1
roteiro v2 FAKE_FIGS=0; expect 'CURTA sem figura ativa: para' "$(seq_of v2)" 'B:com R:com:curta'; expect_has 'CURTA sem figura ativa: diz o motivo' "$out" 'a medição CURTA não mostrou nenhuma figura ativa'; stopped 'CURTA sem figura' v2
roteiro v3 FAKE_REFUSE_AT=1; expect 'CURTA recusada: para' "$(seq_of v3)" 'B:com R:com:curta'; expect_has 'CURTA recusada: diz o motivo' "$out" 'a medição CURTA foi RECUSADA ou falhou'; stopped 'CURTA recusada' v3
roteiro v4 FAKE_BUILD_FAIL=com; expect 'construção COM que falha: nada mais roda' "$(seq_of v4)" 'B:com'; expect_has 'construção COM que falha: diz o motivo' "$out" 'a construção COM a figura falhou ou foi RECUSADA'; stopped 'construção COM' v4
roteiro v5 FAKE_BUILD_FAIL=sem; expect 'construção SEM que falha: só a validação rodou' "$(seq_of v5)" 'B:com R:com:curta B:sem'; expect_has 'construção SEM que falha: diz o motivo' "$out" 'a construção SEM a figura falhou'; stopped 'construção SEM' v5
roteiro cmpfalha FAKE_COMPARE_EXIT=1; expect 'a comparação que acusa grupo sem execução válida: código 1' "$rc" 1

# 5) Sem o binário de release o roteiro NÃO baixa nada: recusa antes de qualquer chamada; uso errado dá 2.
mkdir -p "$work/base_sembin"; : > "$work/log_sembin"; rc=0; out=$(env FAKE_LOG="$work/log_sembin" FAKE_COUNT="$work/count_sembin" LW_RUN_GAME_RELEASE="$work/run_falso" "$script" "$work/base_sembin" < /dev/null 2>&1) || rc=$?
expect 'sem o binário de release: código 1' "$rc" 1; expect_has 'sem o binário: diz que NÃO baixa nada' "$out" 'NÃO baixa nada'; expect 'sem o binário: nenhuma chamada' "$(wc -c < "$work/log_sembin" | tr -d ' ')" 0
rc=0; "$script" um dois < /dev/null > /dev/null 2>&1 || rc=$?; expect 'dois argumentos: código 2' "$rc" 2

# 6) O roteiro não mexe na energia do Mac, é executável e tem sintaxe válida.
sh -n "$script" && echo 'OK: sh -n no roteiro'
if grep -v '^[[:space:]]*#' "$script" | grep -Eq 'sudo|powermetrics|caffeinate|pmset|curl|git '; then echo 'FALHA: o roteiro altera a energia, baixa ou usa o git'; exit 1; fi; echo 'OK: o roteiro não altera a energia, não baixa nada e não usa o git'
[ -x "$script" ] && echo 'OK: o roteiro é executável' || { echo 'FALHA: o roteiro não é executável'; exit 1; }
echo 'ART-12 7c-1c: o roteiro da comparação com e sem a figura aprovado.'
