#!/bin/sh
# Prova que tools/filter_env_noise ignora só o ruído de ambiente e continua pegando erro real.
set -eu
project_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
filter="$project_dir/tools/filter_env_noise"
env_noise='ERROR: Could not create directory: '"'"'user://logs'"'"'.
   at: make_dir_recursive (core/io/dir_access.cpp:179)
ERROR: Error attempting to create data dir: /x/godot/app_userdata/Living World.
   at: ensure_user_data_dir (core/os/os.cpp:442)
ERROR: Failed to open log file for writing: user://logs/godot.log
   at: rotate_file (core/io/logger.cpp:169)
ERROR: Failed to load system certificates.
   at: load_certs (x.cpp:1)'
expect_pass() {
    label=$1; text=$2
    if ! printf '%s\n' "$text" | "$filter" > /dev/null 2> /tmp/lw_filter_err.$$; then
        echo "FALHA: $label deveria passar"; exit 1
    fi
    rm -f /tmp/lw_filter_err.$$
    echo "OK: $label"
}
expect_fail() {
    label=$1; text=$2; fragment=$3
    if out=$(printf '%s\n' "$text" | "$filter" 2> /dev/null); then
        echo "FALHA: $label deveria falhar"; exit 1
    fi
    printf '%s' "$out" | grep -F "$fragment" > /dev/null || { echo "FALHA: $label sem '$fragment' na saída: $out"; exit 1; }
    echo "OK: $label"
}
expect_pass 'saída limpa' 'Godot Engine v4.7.2'
expect_pass 'só ruído de ambiente' "$env_noise"
note=$(printf '%s\n' "$env_noise" | "$filter" 2>&1 >/dev/null || true)
printf '%s' "$note" | grep -F 'NOTA: 4 mensagem(ns) de ambiente ignorada(s)' > /dev/null || { echo "FALHA: aviso de ambiente ausente ou com contagem errada: $note"; exit 1; }
echo 'OK: aviso de ambiente informa a contagem'
expect_fail 'erro de script real' "$env_noise
SCRIPT ERROR: Invalid access to property or key 'x' on a base object of type 'Nil'.
          at: Foo.bar (res://src/foo.gd:7)" 'SCRIPT ERROR'
expect_fail 'erro de análise real' 'Parse Error: Identifier "x" not declared in the current scope.' 'Parse Error'
expect_fail 'erro genérico do motor' "$env_noise
ERROR: Invalid call. Nonexistent function 'foo' in base 'Node'.
   at: call (core/variant.cpp:9)" 'Nonexistent function'
expect_fail 'diretório do projeto não é ruído' "ERROR: Could not create directory: 'res://src/novo'." 'res://src/novo'
expect_fail 'log de erro citando arquivo do projeto' "ERROR: Failed to open log file for writing: res://x.log" 'res://x.log'
echo 'LW-021: filtro de ruído de ambiente: 2 casos limpos ou só de ambiente aprovados e 5 erros reais detectados.'
