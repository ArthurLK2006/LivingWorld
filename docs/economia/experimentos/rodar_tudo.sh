#!/bin/sh
# Reproduz TODA a tabela do diagnóstico (docs/economia/diagnostico-economico-12-11.md): cada cenário, nas sementes 1 a 3, por 30 dias, sem o FoodStub
# (ramo da LW-094a) e, para três cenários, com o FoodStub (main); mais uma corrida de 90 dias do cenário que sustentou. Dura cerca de 15 minutos num Mac de 8 núcleos.
#   REPO=<repositório> TOOLS_SRC=<pasta com measure_economy> WORK=<pasta nova> SAIDA=<pasta> sh rodar_tudo.sh
# Antes: confira que não há outro Godot rodando (`pgrep -fl -i godot`). Variáveis: ver rodar_cenario.sh. Depois: python3 resumir.py <data do jogo> $SAIDA
set -eu
aqui=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ref_sem_stub=${REF_SEM_STUB:-origin/lw-094a-fim-do-foodstub-codigo}
ref_main=${REF_MAIN:-origin/main}
sementes="1 2 3"
rodar() { sh "$aqui/rodar_cenario.sh" "$@"; }
# Três cenários por vez (nove sessões do Godot); `wait` espera as três antes de seguir.
grupo() {
    for cenario in "$@"; do rodar "$cenario" s094a "$ref_sem_stub" 30 $sementes & done
    wait
}
grupo base art_saldos art_saldos_salario1
grupo art_precos est_postos est_postos_lotes
grupo est_postos_lotes_c est_postos_lotes_c_procura est_postos_lotes_c_folha_salario1
grupo est_postos_lotes_c_procura_folha_salario1 regra_spread
for cenario in base art_saldos_salario1 est_postos_lotes_c_folha_salario1; do rodar "$cenario" main "$ref_main" 30 $sementes & done
wait
rodar est_postos_lotes_c_folha_salario1 s094a_90dias "$ref_sem_stub" 90 1
