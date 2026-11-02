#!/bin/sh
# Prova que tools/check_gdscript_warnings falha com arquivo, linha e mensagem quando um script tem
# aviso de compilação do GDScript, e passa quando o script está limpo.
set -eu
project_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
checker="$project_dir/tools/check_gdscript_warnings"
work=$(mktemp -d "${TMPDIR:-/tmp}/lwwarn_test.XXXXXX")
trap 'rm -rf "$work"' EXIT HUP INT TERM
mkdir -p "$work/limpo" "$work/divisao" "$work/nome"
printf 'extends RefCounted\n\n\nfunc dobro(valor: int) -> int:\n\treturn valor * 2\n' > "$work/limpo/dobra.gd"
printf 'extends RefCounted\n\n\nfunc metade(valor: int) -> int:\n\treturn valor / 2\n' > "$work/divisao/divide.gd"
printf 'extends RefCounted\n\n\nfunc teste() -> int:\n\tvar log: int = 3\n\treturn log\n' > "$work/nome/nome.gd"
if ! "$checker" "$work/limpo" > /dev/null 2>&1; then echo "FALHA: script limpo deveria passar"; exit 1; fi
echo "OK: script limpo passa"
if out=$("$checker" "$work/divisao" 2>&1); then echo "FALHA: divisão inteira deveria falhar"; exit 1; fi
printf '%s' "$out" | grep -F "divide.gd:5" > /dev/null || { echo "FALHA: sem arquivo e linha na saída: $out"; exit 1; }
printf '%s' "$out" | grep -F "Integer division" > /dev/null || { echo "FALHA: sem a mensagem do aviso: $out"; exit 1; }
echo "OK: divisão inteira é acusada com arquivo e linha"
if out=$("$checker" "$work/nome" 2>&1); then echo "FALHA: nome igual ao de função do Godot deveria falhar"; exit 1; fi
printf '%s' "$out" | grep -F "nome.gd" > /dev/null || { echo "FALHA: sem o arquivo na saída: $out"; exit 1; }
echo "OK: nome que repete função do Godot é acusado"
echo "LW-011: avisos do GDScript: 1 caso limpo aprovado e 2 tipos de aviso detectados."
