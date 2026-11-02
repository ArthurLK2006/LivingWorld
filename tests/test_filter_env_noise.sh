#!/bin/sh
# Prova que tools/filter_env_noise ignora só o ruído de ambiente conhecido e continua pegando erro real.
set -eu
project_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
filter="$project_dir/tools/filter_env_noise"
err_file=$(mktemp "${TMPDIR:-/tmp}/lw_filter_err.XXXXXX")
trap 'rm -f "$err_file"' EXIT HUP INT TERM
linux_noise='ERROR: Could not create directory: '"'"'user://logs'"'"'.
   at: make_dir_recursive (core/io/dir_access.cpp:179)
ERROR: Error attempting to create data dir: /x/godot/app_userdata/Living World.
   at: ensure_user_data_dir (core/os/os.cpp:442)
ERROR: Failed to open log file for writing: user://logs/godot.log
   at: rotate_file (core/io/logger.cpp:169)'
mac_certificates='ERROR: Condition "ret != noErr" is true. Returning: ""
   at: get_system_ca_certificates (platform/macos/os_macos.mm:123)'
mac_log='ERROR: Failed to open '"'"'user://logs/godot2026-11-02T10.11.12.log'"'"'.
   at: open (core/io/dir_access.cpp:456)'
expect_pass() {
    label=$1; text=$2
    if ! printf '%s\n' "$text" | "$filter" > /dev/null 2> "$err_file"; then
        echo "FALHA: $label deveria passar"; exit 1
    fi
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
expect_note() {
    label=$1; text=$2; count=$3
    printf '%s\n' "$text" | "$filter" > /dev/null 2> "$err_file" || true
    grep -F "NOTA: $count mensagem(ns) de ambiente ignorada(s)" "$err_file" > /dev/null || { echo "FALHA: $label: aviso ausente ou com contagem errada: $(cat "$err_file")"; exit 1; }
    echo "OK: $label"
}
expect_pass 'saída limpa' 'Godot Engine v4.7.2'
expect_pass 'ruído de ambiente do Linux (3 mensagens)' "$linux_noise"
expect_pass 'certificados do macOS (duas linhas)' "$mac_certificates"
expect_pass 'abertura do log com data (duas linhas)' "$mac_log"
expect_pass 'tudo junto' "$linux_noise
$mac_certificates
$mac_log"
expect_note 'contagem do aviso: cada par conta como 1 mensagem' "$linux_noise
$mac_certificates
$mac_log" 5
# Erros reais continuam falhando, mesmo misturados ao ruído.
expect_fail 'erro de script real' "$mac_certificates
SCRIPT ERROR: Invalid access to property or key 'x' on a base object of type 'Nil'.
          at: Foo.bar (res://src/foo.gd:7)" 'SCRIPT ERROR'
expect_fail 'erro de análise real' 'Parse Error: Identifier "x" not declared in the current scope.' 'Parse Error'
expect_fail 'erro genérico do motor' "$linux_noise
ERROR: Invalid call. Nonexistent function 'foo' in base 'Node'.
   at: call (core/variant.cpp:9)" 'Nonexistent function'
expect_fail 'diretório do projeto não é ruído' "ERROR: Could not create directory: 'res://src/novo'." 'res://src/novo'
expect_fail 'log do projeto não é ruído' "ERROR: Failed to open log file for writing: res://x.log" 'res://x.log'
# Regras de duas linhas: a origem da linha "at:" precisa bater.
expect_fail 'ret != noErr com outra origem é erro real' 'ERROR: Condition "ret != noErr" is true. Returning: ""
   at: save_important_thing (platform/macos/os_macos.mm:999)' 'ret != noErr'
expect_fail 'ret != noErr sem linha at: (fim da saída) é erro real' 'ERROR: Condition "ret != noErr" is true. Returning: ""' 'ret != noErr'
expect_fail 'ret != noErr seguido de outro erro é erro real' 'ERROR: Condition "ret != noErr" is true. Returning: ""
ERROR: Invalid call. Nonexistent function '"'"'bar'"'"' in base '"'"'Node'"'"'.
   at: call (core/variant.cpp:9)' 'ret != noErr'
expect_fail 'ret != noErr citando res:// é erro real' 'ERROR: Condition "ret != noErr" is true. Returning: "res://x"
   at: get_system_ca_certificates (platform/macos/os_macos.mm:123)' 'res://x'
expect_fail 'abertura de log com outra origem é erro real' "ERROR: Failed to open 'user://logs/godot2026-11-02T10.11.12.log'.
   at: open (core/io/file_access.cpp:12)" 'user://logs'
expect_fail 'abertura de outro arquivo do usuário é erro real' "ERROR: Failed to open 'user://saves/slot1.lwsave'.
   at: open (core/io/dir_access.cpp:456)" 'user://saves'
expect_fail 'abertura de arquivo do projeto é erro real' "ERROR: Failed to open 'res://data/goods.json'.
   at: open (core/io/dir_access.cpp:456)" 'res://data'
# A regra genérica de "certificado" foi removida: mensagem solta sobre certificados agora é erro real.
expect_fail 'mensagem genérica de certificado deixou de ser ignorada' 'ERROR: Failed to load system certificates.
   at: load_certs (x.cpp:1)' 'certificates'
echo 'LW-021: filtro de ruído de ambiente: 5 casos limpos ou só de ambiente aprovados e 13 casos de erro real detectados.'
