#!/bin/sh
# Roda UM cenário: exporta o ref, aplica o ajuste do cenário na cópia, roda o medidor (uma sessão do Godot por semente, em paralelo) e grava os CSVs.
#   rodar_cenario.sh <cenario> <rotulo-do-ref> <ref-git> <dias> <semente>...
# Variáveis: WORK (pasta de trabalho, obrigatória: as cópias ficam em $WORK/<cenario>__<rotulo>), SAIDA (padrão: ./saida ao lado do script),
# REPO, TOOLS_SRC, GODOT_BIN, CACHE_SRC (ver preparar_copia.sh). Saída: $SAIDA/<cenario>__<rotulo>__s<semente>.csv (com as linhas `#market` do último dia).
set -eu
cenario=$1
rotulo=$2
ref=$3
dias=$4
shift 4
aqui=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$aqui/cenarios.sh"
trabalho=${WORK:?defina WORK (pasta de trabalho)}
saida=${SAIDA:-$aqui/saida}
godot_bin=${GODOT_BIN:-/Applications/Godot 2.app/Contents/MacOS/Godot}
mkdir -p "$saida"
copia="$trabalho/${cenario}__$rotulo"
sh "$aqui/preparar_copia.sh" "$ref" "$copia"
aplicar_cenario "$cenario" "$copia"
for semente in "$@"; do
    ( HOME="$copia/.home_$semente" GODOT_BIN="$godot_bin" "$copia/tools/measure_economy" --days "$dias" --seed "$semente" --markets < /dev/null > "$saida/${cenario}__${rotulo}__s$semente.csv" 2> "$saida/${cenario}__${rotulo}__s$semente.err" ) &
done
wait
