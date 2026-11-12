#!/bin/sh
# Prepara uma CÓPIA descartável do jogo para um experimento (nada é alterado no repositório):
#   preparar_copia.sh <ref-git> <pasta-destino> [--historico]
# Exporta o ref com `git archive`, põe nela o medidor (tools/measure_economy*) e, só se pedido, liga o histórico do Ledger NA CÓPIA e instala
# tools/fluxos.gd (a partir de fluxos.gd.txt; rode com: Godot --headless --path <copia> -s res://tools/fluxos.gd -- --days 12).
# Variáveis: REPO (repositório com o ref; padrão: o do diretório atual), TOOLS_SRC (pasta com measure_economy e measure_economy.gd; padrão $REPO/tools),
# GODOT_BIN (padrão do macOS do projeto), CACHE_SRC (pasta .godot já importada para copiar e pular a importação; opcional).
set -eu
ref=$1
dest=$2
history=${3:-}
repo=${REPO:-$(git rev-parse --show-toplevel)}
tools_src=${TOOLS_SRC:-$repo/tools}
godot_bin=${GODOT_BIN:-/Applications/Godot 2.app/Contents/MacOS/Godot}
if [ -e "$dest" ]; then echo "ERRO: o destino $dest já existe; apague-o você mesmo (este script não apaga nada)." >&2; exit 1; fi
mkdir -p "$dest"
git -C "$repo" archive "$ref" | tar -x -C "$dest"
cp "$tools_src/measure_economy" "$tools_src/measure_economy.gd" "$dest/tools/"
chmod +x "$dest/tools/measure_economy"
if [ "$history" = "--historico" ]; then
    sed -i.bak 's/EconomyModule.new(false, economy_setup.definitions)/EconomyModule.new(true, economy_setup.definitions)/' "$dest/src/app/game_modules.gd"
    rm -f "$dest/src/app/game_modules.gd.bak"
    grep -q 'EconomyModule.new(true' "$dest/src/app/game_modules.gd" || { echo "ERRO: patch do histórico não aplicou" >&2; exit 1; }
    cp "$(dirname -- "$0")/fluxos.gd.txt" "$dest/tools/fluxos.gd"
fi
if [ -n "${CACHE_SRC:-}" ] && [ -d "$CACHE_SRC" ]; then
    cp -R "$CACHE_SRC" "$dest/.godot"
else
    HOME="${EXP_HOME:-$dest/.home}" "$godot_bin" --headless --path "$dest" --import < /dev/null > /dev/null 2>&1
fi
