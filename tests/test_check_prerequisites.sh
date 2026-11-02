#!/bin/sh
# Prova que o tools/check_all confere os pré-requisitos no início, para com UMA mensagem clara
# quando algo falta (ex.: rg, Godot, versão errada do Godot) e continua falhando nesse caso.
set -eu
project_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
checker="$project_dir/tools/check_prerequisites"
work=$(mktemp -d "${TMPDIR:-/tmp}/lwpre.XXXXXX")
trap 'rm -rf "$work"' EXIT HUP INT TERM
# PATHs de mentira só com as ferramentas básicas: um sem o rg e outro sem o awk.
make_path() {
    target=$1; skip=$2
    mkdir -p "$target"
    for tool in awk sed grep cut mktemp dirname cp rm mkdir cat head tr; do
        [ "$tool" = "$skip" ] && continue
        found=$(command -v "$tool" || true)
        case "$found" in /*) ln -s "$found" "$target/$tool";; esac
    done
}
make_path "$work/sem_rg" rg
make_path "$work/sem_awk" awk
ln -s "$(command -v rg)" "$work/sem_awk/rg"
fake_godot="$work/godot_falso"
printf '#!/bin/sh\necho 4.7.2.stable.official.deadbeef\n' > "$fake_godot"; chmod +x "$fake_godot"
old_godot="$work/godot_antigo"
printf '#!/bin/sh\necho 4.6.0.stable.official.deadbeef\n' > "$old_godot"; chmod +x "$old_godot"

out=""; status=0
capture() { out=$("$@" 2>&1) && status=0 || status=$?; }
must_contain() { printf '%s' "$out" | grep -F -- "$2" > /dev/null || { echo "FALHA: $1: faltou '$2' em: $out"; exit 1; }; }
must_not_contain() { if printf '%s' "$out" | grep -F -- "$2" > /dev/null; then echo "FALHA: $1: não deveria conter '$2' em: $out"; exit 1; fi; }
single_message() {
    count=$(printf '%s\n' "$out" | grep -c 'PRÉ-REQUISITOS AUSENTES' || true)
    [ "$count" = 1 ] || { echo "FALHA: $1: deveria haver UMA mensagem de pré-requisitos, houve $count"; exit 1; }
}

capture env GODOT_BIN="$fake_godot" "$checker"
[ "$status" = 0 ] || { echo "FALHA: com tudo presente deveria passar: $out"; exit 1; }
echo "OK: tudo presente passa"

capture env PATH="$work/sem_rg" GODOT_BIN="$fake_godot" "$checker"
[ "$status" = 1 ] || { echo "FALHA: sem rg deveria falhar"; exit 1; }
single_message "sem rg"; must_contain "sem rg" "rg (ripgrep)"; must_contain "sem rg" "brew install ripgrep"; must_not_contain "sem rg" "Godot"
echo "OK: falta o rg -> mensagem única com 'brew install ripgrep'"

capture env GODOT_BIN="$work/nao_existe" "$checker"
[ "$status" = 1 ] || { echo "FALHA: sem Godot deveria falhar"; exit 1; }
single_message "sem Godot"; must_contain "sem Godot" "Godot não encontrado"; must_contain "sem Godot" "GODOT_BIN"; must_not_contain "sem Godot" "ripgrep"
echo "OK: falta o Godot -> mensagem única com GODOT_BIN"

capture env GODOT_BIN="$old_godot" "$checker"
[ "$status" = 1 ] || { echo "FALHA: Godot de versão errada deveria falhar"; exit 1; }
single_message "versão errada"; must_contain "versão errada" "versão errada"; must_contain "versão errada" "4.6.0.stable"
echo "OK: Godot de versão errada é recusado"

capture env PATH="$work/sem_awk" GODOT_BIN="$fake_godot" "$checker"
[ "$status" = 1 ] || { echo "FALHA: sem awk deveria falhar"; exit 1; }
single_message "sem awk"; must_contain "sem awk" "awk"; must_contain "sem awk" "xcode-select --install"
echo "OK: ferramenta básica ausente -> mensagem única com xcode-select"

capture env PATH="$work/sem_rg" GODOT_BIN="$work/nao_existe" "$checker"
[ "$status" = 1 ] || { echo "FALHA: sem rg e sem Godot deveria falhar"; exit 1; }
single_message "tudo faltando"; must_contain "tudo faltando" "rg (ripgrep)"; must_contain "tudo faltando" "Godot não encontrado"
echo "OK: vários itens ausentes aparecem juntos, numa só mensagem"

# O check_all inteiro para logo no início e continua falhando (nada de testes rodando às cegas).
capture env PATH="$work/sem_rg" GODOT_BIN="$fake_godot" "$project_dir/tools/check_all"
[ "$status" = 1 ] || { echo "FALHA: check_all sem rg deveria sair com código 1, saiu com $status"; exit 1; }
single_message "check_all sem rg"; must_contain "check_all sem rg" "brew install ripgrep"; must_contain "check_all sem rg" "VERMELHO: pré-requisitos ausentes"
must_not_contain "check_all sem rg" "command not found"; must_not_contain "check_all sem rg" "Arquitetura:"; must_not_contain "check_all sem rg" "FALHA"
echo "OK: check_all sem rg para no início, com código 1 e sem o ruído antigo"
echo "LW-011: pré-requisitos: 1 caso completo aprovado e 6 casos de ausência detectados."
