Conteúdo de `data/world`: `terrain.json` e `surface_types.json`; formato e convenções em `docs/modules/world.md`.

Hoje há aqui o **terreno de blockout** (LW-037, DEC-118): 1.024 m × 1.024 m, células de 2 m, chunks de 64 m. Os dois arquivos são **gerados** por `tools/make_blockout_terrain` e não devem ser editados à mão (os números são listas enormes). Para mudar o relevo, ajuste as constantes `[HIP]` em `tools/blockout_terrain_generator.gd`, rode `tools/make_blockout_terrain` e commite o resultado. `tools/make_blockout_terrain --check` confere, sem gravar, se os arquivos estão idênticos ao que a ferramenta geraria. Descrição do relevo: `docs/world/relevo-do-terreno-de-blockout.md`.

Este terreno é de **teste**: não fixa o tamanho final do mundo (DEC-055, PENDENTE).
