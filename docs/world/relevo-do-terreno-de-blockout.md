# Relevo do terreno de blockout

**Tarefa:** LW-037 · **Decisão de base:** DEC-118 (terreno de teste do protótipo, APROVADA) · **Arquivos:** `data/world/terrain.json` e `data/world/surface_types.json` · **Gerador:** `tools/make_blockout_terrain`

Este é o terreno **de teste** da Fase 1: um lugar simples para desenhar o chão (LW-038), colidir (LW-039), carregar por pedaços (LW-040) e andar. **Não** é o mundo do jogo: o tamanho final do mundo segue **PENDENTE** (DEC-055). Os arquivos são gerados por uma ferramenta, não desenhados à mão, e o jogo apenas os lê.

Rótulos usados aqui: **decisão** (de Arthur, 05/11/2026), **[HIP]** (hipótese: valor inicial para Arthur ajustar olhando a tela, na LW-038) e **limitação**.

## 1. Tamanho, grade e chunks (decisão)

| Item | Valor |
|---|---|
| Tamanho | 1.024 m × 1.024 m (cerca de 1,05 km²) |
| Células | 512 × 512 = 262.144, cada uma com 2 m de lado |
| Nós (pontos com altura) | 513 × 513 = 263.169 |
| Chunks | 16 × 16 = 256, cada um com 64 m (32 × 32 células) |

Os chunks vizinhos compartilham os nós da divisa, então não há emenda entre eles. O tamanho do chunk (`chunk_cells`) é **dado do arquivo**, não constante do código (DEC-118). Convenções completas (origem, eixos, ordem das listas): `docs/modules/world.md`.

**Eixos.** A origem fica no canto de menor `x` e menor `z`. `x` cresce de **oeste (0 m) para leste (1.024 m)**; `z` vai de 0 a 1.024 m (no desenho abaixo, `z = 0` está no topo). A altura (Y) é dada em metros pela simulação e guardada em centímetros inteiros no arquivo.

## 2. O que existe e onde (todos os números são [HIP])

| Elemento | Posição e forma | Altura |
|---|---|---|
| **Planície** | todo o resto do mapa | 10 m |
| **Colina** | centro em (700 m, 300 m), raio 160 m (ocupa de x = 540 a 860 m e de z = 140 a 460 m) | topo a **40 m** (+30 m sobre a planície) |
| **Vale** | centro em (300 m, 750 m), raio 140 m (ocupa de x = 160 a 440 m e de z = 610 a 890 m) | fundo a **−2 m** (−12 m sob a planície) |
| **Caminho** | faixa de **6 m** de largura, de oeste a leste (x de 0 a 1.024 m), com z de 510 m a 516 m | **10 m**, plano |

O vale é só uma depressão seca: não há água (fora de escopo da Fase 1). A colina e o vale têm forma suave: a altura sobe (ou desce) com a fórmula `amplitude × (1 − d²/R²)²`, onde `d` é a distância ao centro e `R` o raio. O topo é arredondado e a borda se funde ao chão sem degrau.

**Desenho** (cada caractere vale 16 m em x e 32 m em z; `z` cresce para baixo; esquema, não escala exata):

```
.  planície e grama      #  pedra       :  encosta da colina (grama)
~  vale (grama)          =  caminho (fina demais para a escala; desenhada na linha z = 512 m)

................................................................
................................................................
................................................................
................................................................
................................................................
.......................................:::::::::................
.....................................:::########:::.............
....................................::###:::::####::............
...................................::##:::####::##:::...........
...................................::##::#####::###::...........
...................................::###::###:::##:::...........
....................................::####:::####:::............
.....................................::::#####::::..............
........................................:::::::.................
................................................................
................................................................
================================================================
................................................................
................................................................
................................................................
................................................................
..............~~~~~~~~~.........................................
............~~~~~~~~~~~~~.......................................
............~~~~~~~~~~~~~~......................................
...........~~~~~~~~~~~~~~~......................................
............~~~~~~~~~~~~~~......................................
.............~~~~~~~~~~~~.......................................
...............~~~~~~~~.........................................
................................................................
................................................................
................................................................
................................................................
```

## 3. Caminho: por que 510 m a 516 m (decisão técnica)

A recomendação inicial era "6 m de largura ao longo de z = 512 m". Só que 512 m cai **sobre uma linha da grade**, e uma faixa de células de 2 m centrada numa linha só pode ter 4 m ou 8 m. Para manter os **6 m** (3 células), o eixo ficou em **513 m** (meio de uma célula): o caminho cobre de 510 m a 516 m. A diferença para o pedido é de 1 m no eixo. Os nós dessa faixa são forçados à altura da planície, então o caminho continua plano mesmo que a colina ou o vale cresçam um dia até ele.

## 4. Tipos de superfície

| Código | Id | Onde |
|---|---|---|
| 1 | `grass` | todo o mapa, exceto o que está abaixo: 253.616 células |
| 2 | `path` | as 3 fileiras de células do caminho: 1.536 células |
| 3 | `rock` | 6.992 células, em dois lugares da colina (abaixo) |

**Pedra [HIP].** Uma célula fora do caminho vira `rock` se:
- a **inclinação média da célula passa de 27 %** (módulo do gradiente, que não depende da direção da encosta); ou
- o **topo da célula passa de 26 m acima da planície** (ou seja, acima de 36 m de altura).

Na prática: um **disco de pedra no topo** (até cerca de 43 m do centro da colina) e uma **faixa de pedra na encosta mais íngreme** (de 72 m a 111 m do centro). O vale (inclinação máxima de 13,5 %) e a planície ficam em grama. Os códigos `1`, `2` e `3` são os do arquivo `surface_types.json`; **cores e materiais não são definidos aqui** (LW-038).

## 5. Ponto de nascimento

(100 m, 512 m), sobre o caminho e a oeste, a 10 m de altura. Cai na faixa do caminho (a 2 m da borda de menor `z`), então a superfície ali é `path`.

## 6. Inclinação

Medida no arquivo gerado, entre nós vizinhos (passo de 2 m):

| Região | Inclinação máxima | Em graus |
|---|---|---|
| **Colina** | **29,0 %** (58 cm de desnível em 2 m) | cerca de 16° |
| Vale | 13,5 % (27 cm em 2 m) | cerca de 8° |
| Planície e caminho | 0 % | 0° |

A colina é a única parte que testa um limite de inclinação. **Informação para a LW-047** (inclinação máxima caminhável, ainda não decidida): se o limite for menor que 29 %, a faixa de pedra da encosta ficará intransponível andando; isso é esperado e serve de teste.

## 7. Como regenerar e como conferir

Precisa do Godot 4.7.2 (o script o procura como as outras ferramentas: variável `GODOT_BIN` ou o caminho padrão do Mac).

```bash
tools/make_blockout_terrain
```

Grava `data/world/terrain.json` (cerca de 2,2 MiB, 1.040 linhas) e `data/world/surface_types.json`, e imprime o resumo (tamanho, nós, células, chunks, alturas, superfícies e ponto de nascimento). A geração usa **só inteiros** e nenhuma aleatoriedade: rodar duas vezes dá arquivos **idênticos byte a byte**.

```bash
tools/make_blockout_terrain --check
```

Não grava nada: confere se os arquivos existentes são idênticos ao que a ferramenta geraria. Sai com código 0 se forem e 1 se não (apontando o arquivo diferente ou ausente). Opção extra: `--out <pasta>` escolhe outra pasta de saída (ela precisa existir; caminho relativo vale a partir da raiz do projeto). Opção desconhecida é recusada com mensagem.

**Para mudar o relevo:** ajuste as constantes `[HIP]` no topo de `tools/blockout_terrain_generator.gd`, rode `tools/make_blockout_terrain` e commite os dois arquivos gerados. O teste `tests/unit/test_blockout_terrain.gd` falha se os arquivos commitados ficarem diferentes do que a ferramenta gera, para ninguém esquecer de regenerar.

## 8. O que ainda é hipótese [HIP]

Tudo da seção 2 além do tamanho da grade: altura da planície (10 m); centro, raio e altura da colina; centro, raio e profundidade do vale; eixo e largura do caminho; a forma da fórmula; os dois limites da pedra (27 % e 26 m); o ponto de nascimento. Também são hipóteses os limites de segurança do formato (`chunk_cells` de 1 a 256, em `TerrainLoader`) e os códigos 1, 2 e 3. Os testes de relevo (`test_blockout_terrain.gd`) comparam **relações** (a colina é mais alta que a planície, o vale é mais baixo, o caminho é plano e tem a superfície `path`), não esses números, para a LW-038 poder ajustá-los sem quebrar testes.

**Limitação.** O terreno não tem rios, água, árvores, construções nem pontos de interesse (LW-043 e LW-049). Cada um desses entra na sua tarefa, sobre este chão.
