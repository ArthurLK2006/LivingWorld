# Resultados dos cenários (30 dias)

Gerado por `resumir.py` sobre as saídas de `rodar_tudo.sh`; ver o diagnóstico.

| cenário | ref | sementes | vivos d7 / d14 / d30 | locais rodando d30 (de 14) | dinheiro d30: NPC vivo / NPC morto / locais / mercados | maior razão de preço entre povoados | melhor viagem (lucro, rota) | conferência |
|---|---|---|---|---|---|---|---|---|
| base | s094a | 3 | 44 / 0 / 0 | 0 | 0 / 2172 / 40 / 17507 | 6.0x bread | 350 ($350, breadB→A (16 un.)) | ok |
| art_saldos | s094a | 3 | 104 / 16-19 / 0 | 0 | 0 / 5123 / 2403 / 23393 | 3.8x fabric | 131-157 ($131, breadB→A (8 un.)) | ok |
| art_saldos_salario1 | s094a | 3 | 111-112 / 25-30 / 0 | 0 | 0 / 300 / 5935 / 24684 | 6.0x grain | 350 ($350, breadB→C (16 un.)) | ok |
| art_precos | s094a | 3 | 62-66 / 24 / 12 | 0-1 | 378 / 443 / 1944 / 16954 | 6.0x grain | 152 ($152, breadB→C (9 un.)) | ok |
| est_postos | s094a | 3 | 44-45 / 10-12 / 0 | 0 | 0 / 5136 / 39 / 14544 | 2.5x wool | 39 ($39, toolC→A (6 un.)) | ok |
| est_postos_lotes | s094a | 3 | 112 / 46 / 26-42 | 0 | 7074 / 1789 / 480 / 10375 | 3.8x fabric | 80 ($80, toolC→A (6 un.)) | ok |
| est_postos_lotes_c | s094a | 3 | 120 / 53-54 / 42-50 | 0 | 8277 / 126 / 500 / 10816 | 3.8x fabric | 70-80 ($80, toolC→A (6 un.)) | ok |
| est_postos_lotes_c_procura | s094a | 3 | 132 / 70-82 / 8-20 | 0-1 | 827 / 6183 / 1564 / 11144 | 2.1x bread | 78-166 ($78, breadC→A (6 un.)) | ok |
| est_postos_lotes_c_folha_salario1 | s094a | 3 | 132 / 132 / 132 | 0-1 | 9412 / 0 / 6066 / 4241 | 6.0x grain | 269-270 ($269, breadB→C (13 un.)) | ok |
| est_postos_lotes_c_procura_folha_salario1 | s094a | 3 | 132 / 132 / 28 | 1 | 745 / 14322 / 509 / 4142 | 6.0x ore | 50 ($50, woodB→C (12 un.)) | ok |
| regra_spread | s094a | 3 | 44-45 / 30-32 / 8 | 0 | 4156 / 3585 / 35 / 11943 | 6.0x grain | 350 ($350, breadB→A (16 un.)) | ok |
| base | main | 3 | 132 / 132 / 132 | 0 | 3211 / 0 / 31 / 16477 | 2.5x wool | 78-350 ($78, breadC→A (6 un.)) | ok |
| art_saldos_salario1 | main | 3 | 132 / 132 / 132 | 0 | 2373 / 0 / 5396 / 23150 | 4.5x plank | 137 ($137, toolC→A (6 un.)) | ok |
| est_postos_lotes_c_folha_salario1 | main | 3 | 132 / 132 / 132 | 0 | 12626 / 0 / 3852 / 3241 | 4.4x fabric | 29 ($29, fabricB→C (6 un.)) | ok |
