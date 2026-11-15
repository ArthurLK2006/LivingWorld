# Comparação dos renderizadores: Compatibility e Forward+

**Status:** **resultados de 13/11/2026** (executado com janela por ordem de Arthur: Apple M3, Godot 4.7.2, 1280 x 720, vsync desligado, uma execução por renderer). Cena demonstrativa isolada, sem modificar o `project.godot`. Nenhuma troca definitiva de renderer está autorizada; o jogo segue em Compatibility (`gl_compatibility`).

## Por que comparar
As três referências (DEC-280) dependem de efeitos que, pelo que se sabe, são de Forward+ ou Mobile: bloom, profundidade de campo, névoa volumétrica e oclusão ambiente em tempo real. O projeto está em Compatibility, sem decisão registrada que o justifique. O que o Compatibility aceita na Godot 4.7.2 **será confirmado por teste**, não por memória.

## Como rodar (1 comando, abre uma janela por cerca de 2 minutos)
`tools/visual/run_renderer_test [pasta-de-saída]`: roda a cena `scenes/demo/renderer_test.tscn` duas vezes, com `--rendering-method gl_compatibility` e depois `--rendering-method forward_plus`, em modo automático (3 predefinições de luz x 3 câmeras), e grava PNGs e `resumo.txt` por renderer. Não altera o `project.godot`.
Teclas na cena interativa: `1`, `2`, `3` luz (dia, hora dourada, crepúsculo); `Q`, `W`, `E` câmera (próxima, isométrica, estratégica); `B` bloom, `O` oclusão ambiente, `F` névoa, `D` profundidade de campo.

## Onde está o código
- Cena: `scenes/demo/renderer_test.tscn`; código: `tools/visual/renderer_test/` (3 componentes: predefinições, cena e modo automático) e, desde a ART-1, `src/presentation/world_view/plaza/` (6 componentes: kit de malhas, dados, materiais, chão, estruturas e fachada); executor: `tools/visual/run_renderer_test`; testes sem janela: `tests/unit/test_renderer_*.gd` e `tests/unit/test_plaza_*.gd` (7 arquivos, 22 testes). A cena demonstrativa fica FORA de `src/`: não lê a simulação nem a ponte, não é montada pelo jogo, não tem autoload e não altera o `project.godot` (o teste da LW-082h exige que `src/tools` só leia pela ponte, e o `tools/check_input_keys` proíbe teclas fixas em `src/`); os componentes da praça, em `src/presentation/world_view/plaza/`, também não leem a simulação nem a ponte e ainda não são montados pelo jogo.
- Teclas (1, 2, 3 luz; Q, W, E câmera; B, O, F, D efeitos): guardadas como `InputEventKey` na própria cena, porque o `project.godot` é protegido (não há ações novas para elas). A cena mede 63.948 triângulos, 10 materiais, 4 `MultiMeshInstance3D` e 7 luzes pontuais.
- Tamanho: entregue em 5 partes empilhadas (kit e predefinições; dados e materiais; chão e vegetação; barracas, casas e fachada; cena, modo automático e executor), cada uma dentro do limite do AGENTS 5.2 (a maior, a parte 5, tem 429 linhas, dentro da tolerância de 1,5x). A praça gerada é idêntica à da versão em um arquivo só (impressão digital SHA-256 igual antes e depois).

## Achados sem janela (13/11/2026, Godot 4.7.2, headless)
- Em headless, `get_current_rendering_method()` devolve `gl_compatibility`. A cena mede 63.948 triângulos, 80 nós, 66 malhas, 4 `MultiMeshInstance3D` (6.000 tufos de grama e 720 flores), 10 materiais e 7 luzes pontuais.
- Ao ligar no Compatibility, a engine IMPRIME ERRO para a névoa volumétrica ("só Forward+") e para a profundidade de campo ("só Forward+ ou Mobile"): confirmado por experimento. Para a oclusão ambiente e o bloom o setter não imprime nada, e isso NÃO prova que funcionem: só a janela mostra. A tabela de suporte da cena (`RendererPresets.SUPPORTED`) é hipótese [HIP] até a execução com janela; `--force-effects` liga tudo para conferir.

## Medições (13/11/2026; 180 quadros por captura depois de 30 de acomodação)
Compatibility: `opengl3`, efeitos ligados: bloom e névoa (a tabela [HIP] desliga oclusão ambiente, profundidade de campo e névoa volumétrica). Forward+: `metal`, todos os efeitos ligados.

| captura | Compat fps | Compat pior (ms) | F+ fps | F+ pior (ms) | Compat sat./brilho | F+ sat./brilho |
|---|---|---|---|---|---|---|
| dia, próxima | 276 | 8,4 | 132 | 17,9 | 0,33 / 0,78 | 0,36 / 0,67 |
| dia, isométrica | 167 | 11,8 | 77 | 26,4 | 0,23 / 0,79 | 0,24 / 0,69 |
| dia, estratégica | 245 | 11,7 | 506 | 3,0 | 0,10 / 0,81 | 0,10 / 0,76 |
| hora dourada, próxima | 348 | 7,2 | 82 | 25,0 | 0,72 / 0,74 | 0,85 / 0,60 |
| hora dourada, isométrica | 242 | 9,7 | 74 | 19,8 | 0,57 / 0,79 | 0,79 / 0,83 |
| hora dourada, estratégica | 324 | 8,2 | 188 | **38,1** | 0,41 / 0,96 | 0,77 / 0,89 |
| crepúsculo, próxima | 235 | 10,2 | 107 | 25,7 | 0,42 / 0,50 | 0,53 / 0,33 |
| crepúsculo, isométrica | 191 | 10,0 | 93 | 23,1 | 0,42 / 0,60 | 0,71 / 0,36 |
| crepúsculo, estratégica | 290 | 9,4 | 171 | 17,8 | 0,43 / 0,74 | 0,84 / 0,35 |

Chamadas de desenho: 150 a 408 (Compat) e 112 a 296 (F+); memória de vídeo: **22,8 MB** (Compat) contra **162,4 MB** (F+); 63.948 triângulos nos dois. As 18 capturas e os 2 `resumo.txt` ficaram FORA do repositório (pasta `.worktrees/capturas-arte-13-11/` no Mac de Arthur).

## Critérios e leitura
| # | Critério | Compatibility | Forward+ |
|---|---|---|---|
| 1 | Fidelidade visual às referências | Reconhece-se as referências: o dia isométrico lembra a vila da referência 1 (chão ocre, manchas de grama, barracas de toldo colorido) e a hora dourada e o crepúsculo têm contraluz, bandeirolas e lampiões que brilham (bloom), como as referências 2 e 3. Faltam profundidade de campo, névoa volumétrica e oclusão ambiente. Formas facetadas nítidas. | Mais cinematográfico nas tomadas próximas (profundidade de campo e névoa volumétrica das referências 2 e 3) e cores do dia mais ricas; porém as tomadas próximas ficam mais escuras, enevoadas e com granulação no chão, e a nitidez facetada some no fundo desfocado. |
| 2 | Qualidade da iluminação | Sol direcional com sombras, névoa de profundidade e bloom funcionam (lampiões e bandeirolas brilham; a luz local forma uma poça quente). Sem névoa volumétrica nem oclusão ambiente. | Tudo do Compatibility mais oclusão ambiente, névoa volumétrica e profundidade de campo; a hora dourada fica pesada (brilho 0,60 na próxima). |
| 3 | Sombras e materiais | Sombras suaves e nítidas, sem vazamento visível; materiais facetados limpos. | Sombras de contato mais ricas (oclusão ambiente), mas aparece granulação no chão das tomadas próximas (causa não isolada: névoa volumétrica ou oclusão ambiente, a testar ligando um efeito de cada vez). |
| 4 | Vegetação e detalhes | Grama em lâminas (6.000 tufos), flores (720), árvores e adereços aparecem; o shader de vento compilou sem erro. | Igual: aparecem, sem erro de shader. A animação do vento NÃO foi conferida (as capturas são imagens estáticas). |
| 5 | Desempenho (DEC-119: média de 60 fps e nenhum quadro acima de 33 ms) | **Cumpre com folga nas 9 capturas**: 167 a 348 fps, pior quadro 7,2 a 11,8 ms, 22,8 MB de vídeo. | Média acima de 60 fps nas 9 (mínimo 74), mas **1 de 9 passa de 33 ms (38,1 ms)** e 5 de 9 passam de 20 ms; na próxima e na isométrica custa 2 a 4 vezes mais; 162 MB de vídeo (7 vezes). |
| 6 | Compatibilidade com as câmeras | Próxima, isométrica e estratégica leem bem; a isométrica é a mais próxima da referência 1. Na estratégica da hora dourada e do crepúsculo a névoa lava as cores, mas a praça segue legível. | Diferença visual na próxima (profundidade de campo e névoa) e na isométrica (só cor e oclusão). **Na estratégica o dia é quase igual, mas na hora dourada e no crepúsculo a névoa volumétrica e a escuridão engolem a praça, que fica quase ilegível**; é também onde está o quadro de 38,1 ms. |
| 7 | Complexidade de manutenção | É o renderer do projeto: nada muda. Não tem profundidade de campo, névoa volumétrica nem oclusão ambiente. | Exige trocar o `project.godot` (protegido: aprovação específica), reafinar luz e materiais para outra aparência (e manter os dois caminhos, se o jogo quiser suportar os dois), 7 vezes mais memória de vídeo e uma GPU com Metal, Vulkan ou D3D12. |

**Limites da medição:** uma execução por renderer, em build do editor (não de release); o pior quadro de 38,1 ms pode ser um quadro isolado (por exemplo, compilação de shader da troca de luz) e deve ser repetido com mais quadros antes de decidir; a causa da granulação do Forward+ é hipótese.

## Calibração das predefinições de luz (achado do teste, vale para os dois renderers)
Alvos medidos nas referências (saturação / brilho): dia 0,44 / 0,59; hora dourada 0,36 / 0,48. **O dia está claro e pálido demais** (Compatibility 0,23 a 0,33 de saturação e 0,78 a 0,81 de brilho; Forward+ chega a 0,67 a 0,76 de brilho) e **a hora dourada está saturada e clara demais** (Compatibility 0,41 a 0,72 e 0,74 a 0,96; Forward+ 0,77 a 0,85 e 0,60 a 0,89). Isso é calibração das luzes e do ambiente, não do renderer: o próximo passo natural é afinar essas duas predefinições (sol, ambiente e névoa) e medir de novo. **A densidade da névoa também precisa de ajuste por câmera**: na estratégica da hora dourada ela lava a praça no Compatibility e a faz sumir no Forward+, e no crepúsculo o Forward+ deixa a tomada quase preta.

## Como decidir depois dos resultados
- Se o Compatibility entregar o essencial das referências dentro da DEC-119, mantém-se e o guia usa só o que ele suporta.
- Se o ganho do Forward+ for grande e o custo de quadros couber na DEC-119, propõe-se a troca em PR separado (mexe no `project.godot`, arquivo protegido: precisa da aprovação específica de Arthur).
- Qualquer troca exige rodar o `tools/check_all` e a medição de quadros da LW-053A nos dois caminhos.

## Leitura dos resultados (recomendação; a decisão é de Arthur)
- O Compatibility entrega o essencial das referências (formas facetadas, paleta quente, bloom nos emissivos, névoa) com folga na DEC-119 (167 fps ou mais, pior quadro de 11,8 ms). **Recomendação: manter o Compatibility como renderer do jogo** e usar o guia só com o que ele suporta.
- O Forward+ acrescenta profundidade de campo, névoa volumétrica e oclusão ambiente nas tomadas próximas, a 2 a 4 vezes o custo, com um quadro de 38,1 ms em uma das 9 capturas e 7 vezes a memória de vídeo; com a calibração atual, a câmera estratégica fica quase ilegível nele em 2 das 3 luzes. **Reavaliar** só se, depois de calibrar as luzes, as tomadas próximas ainda pedirem esses efeitos; a troca seria um PR à parte (mexe no `project.godot`) com a aprovação específica de Arthur.


## Renderer Mobile (M1, 15/11/2026): PR isolado, EM RASCUNHO, para decidir se o Mobile pode ser o renderer oficial
**Status:** avaliação preparada a pedido de Arthur (14/11/2026); **NÃO integrar no `main` antes do aceite dele**, e o jogo oficial segue em Compatibility até lá. Uma máquina (MacBook Air M3, Godot 4.7.2, 1280 x 720, vsync desligado, na bateria), build de depuração do editor e build de RELEASE (binário oficial do macOS, `.pck` exportado de uma cópia do projeto). Os scripts de medição são de desenvolvimento e ficaram FORA do repositório (pasta de trabalho do M1); as capturas e os resumos também.

### A mudança e a reversão
- `project.godot`: só `renderer/rendering_method` passou de `"gl_compatibility"` para `"mobile"`. A linha `renderer/rendering_method.mobile="gl_compatibility"` é a sobrescrita das plataformas móveis (Android e iOS) e **não** foi mexida.
- **Reversão, uma linha:** voltar `renderer/rendering_method="gl_compatibility"`. Sem editar o arquivo: `godot --rendering-method gl_compatibility ...`, `RENDERER=gl_compatibility tools/visual/run_game_capture` e `RENDERERS="gl_compatibility mobile" tools/visual/run_renderer_test`. O ajuste de luz do Mobile só vale com o Mobile (`RendererCalibration.renderer`): no Compatibility a luz é exatamente a do `AmbientConfig` (testado em `tests/unit/test_renderer_calibration.gd`), então a reversão não exige desfazer mais nada.
- `tools/check_all` VERDE com o Mobile (sem janela o motor só informa o nome do renderer, então os testes não cobrem o visual). A interface (HUD, tela do mercado e aba de contratos) renderiza igual: dentro do painel o erro médio por pixel contra o Compatibility é de 0,0019 (mercado) e 0,0014 (contratos), com 0,18% e 0% dos pixels acima de 4%; fora dele (o mundo 3D) é 0,016. O ruído entre duas execuções do Compatibility é de 0,0001 (dia) a 0,004 (noite).

### Calibração da luz (o que Arthur aprovou é o Compatibility)
Método: o jogo real (`scenes/main.tscn`, `AmbientRig` e `ambient_default.tres`), 20 vistas (praça A e ponto de nascimento x 12 h, 17h30 e 19 h x próxima, isométrica e estratégica, mais a tela do mercado e a aba de contratos), a MESMA luz nos dois renderers, o Compatibility como referência. Medidas por imagem reduzida: erro médio por pixel (0 a 1), brilho V e saturação S médios.
| grupo (vistas) | erro por pixel, sem ajuste | com ajuste | dif. de brilho V, sem ajuste | com ajuste | dif. de saturação S, sem ajuste | com ajuste |
|---|---|---|---|---|---|---|
| dia, 12 h (6) | 0,134 | **0,019** | -0,137 | +0,009 | +0,069 | +0,019 |
| hora dourada, 17h30 (6) | 0,083 | **0,025** | -0,114 | -0,023 | -0,002 | -0,022 |
| noite com lampiões, 19 h (6) | 0,020 | **0,008** | -0,029 | -0,007 | -0,015 | -0,006 |
| tela do mercado e contratos (2) | 0,053 | **0,010** | -0,053 | +0,008 | +0,020 | -0,007 |
**Causa:** com o mesmo recurso o Mobile sai muito mais escuro que o Compatibility (brilho V de 0,64 contra 0,79 ao meio-dia): o sol e a luz ambiente rendem menos nele. **Valores trocados** (`assets/environment/renderer_calibration_mobile.tres`, lido pelo `AmbientRig` só quando o renderer é o Mobile): energia do sol **x 2,6** e energia ambiente **x 1,2** (antes: x 1 e x 1). Testados e SEM ganho (ficam neutros): exposição (x 0,9 a x 2), saturação (x 0,9 a x 1,3), contraste, brilho, modo de tonemap (linear, Reinhard, Filmic, ACES, AgX) e branco do tonemap, e o bloom (intensidade x 0,5 a x 3, força x 0,5 a x 3, limiar x 0,6 a x 1,4); as predefinições de luz, o bloom e os emissivos do `.tres` não mudaram. Resíduo: a vista estratégica da hora dourada fica 0,06 mais escura em V (a mais distante do ajuste), e a saturação do dia +0,02. Capturas lado a lado (Compatibility | Mobile sem ajuste | Mobile com ajuste): `m1_capturas/` na pasta de trabalho do M1. A cena demonstrativa de renderizadores (`renderer_test`, `RendererPresets`) NÃO foi calibrada: ela tem as próprias predefinições e só serve à comparação.

### Quadros frios acima de 33 ms (isolamento)
Cada quadro guarda o tempo, o tempo de render da CPU (`viewport_get_measured_render_time_cpu`) e o rótulo da captura (15.928 quadros por execução). O quadro de 31 a 39 ms por rodada da ART-12b e 12c **NÃO se reproduziu**: em 3 execuções do Mobile (3 x 9 capturas da praça, 18 do jogo e uma rota de 30 s cada) nenhum quadro medido passou de 33 ms e só 2 passaram de 20 ms (21,3 e 20,6 ms, na rota, ao carregar terreno). O Compatibility também teve quadros isolados (26,0 ms na praça e 38,7 ms na rota, na depuração): quadros esporádicos de 25 a 40 ms aparecem nos dois renderers com o Mac na bateria, o que aponta para ruído do sistema (hipótese, não provada).
| execução | praça, 3 x 9 capturas: pior (ms) / >20 / >33 | jogo, 18 capturas: pior / >20 / >33 | rota de 30 s: pior / >20 / >33 |
|---|---|---|---|
| depuração, Mobile (cache quente) | 10,1 / 0 / 0 | 10,7 / 0 / 0 | 14,2 / 0 / 0 |
| release, Mobile, 1ª execução (cache FRIO) | 13,2 / 0 / 0 | 13,2 / 0 / 0 | 21,3 / 2 / 0 |
| release, Mobile, 2ª execução com pré-aquecimento | 12,4 / 0 / 0 | 15,6 / 0 / 0 | 20,0 / 0 / 0 |
| depuração, Compatibility | 26,0 / 1 / 0 | 17,2 / 0 / 0 | 38,7 / 5 / 1 |
| release, Compatibility | 16,4 / 0 / 0 | 10,4 / 0 / 0 | 26,8 / 3 / 0 |
**O que existe de verdade é o custo de PRIMEIRA VEZ** (compilação de pipeline do Metal na CPU do render; a GPU não é medida): na 1ª execução do release (cache frio), o 1º quadro da praça custou 3.066 ms de CPU de render (11 ms em depuração com cache quente), o 1º quadro com os lampiões acesos (hora dourada) 25,7 ms e o 1º quadro com a tela do mercado aberta 32,6 ms. Na 2ª execução (cache quente) nenhum dos três se repete (4,4 ms, sem pico, sem pico). Esses custos ficam fora das janelas medidas pelos 30 quadros de acomodação, mas num jogo real caem no jogador: o 1º lançamento depois de instalar ou de mudar shader.
**Pré-aquecimento testado:** renderizar uma vez cada estado antes de jogar (praça: 9 combinações x 4 quadros = 307 ms; jogo: 2 locais x 3 horas x 3 câmeras x 4 quadros = 1,25 s). Na execução com ele não houve quadro medido acima de 20 ms (o único da execução, 21,8 ms, caiu dentro do próprio pré-aquecimento). **O que NÃO ficou provado:** o efeito dele num cache frio, porque a 2ª execução já tinha o cache quente da 1ª (confusão) e as 10 janelas autorizadas acabaram; o que se mostrou é que o custo de primeira vez existe, é de 25 a 33 ms por estado novo (3 s na cena inteira) e some com o cache quente. O motor 4.7.2 só expõe `rendering/rendering_device/pipeline_cache/enable` e `rendering/shader_compiler/shader_cache/enabled` (ambos ligados) e nenhuma opção de ubershader ou de pré-compilação nas configurações do projeto (listadas por script). **Se o Mobile for aceito:** um quadro de carregamento que percorra as 3 paletas, os lampiões acesos e apagados e a tela do mercado uma vez no 1º lançamento, e repetir a medição com cache frio, é a mitigação a validar.

### Limite de luzes (verificado de verdade, Mobile e Compatibility)
Contagem no jogo real às 19 h (lampiões acesos), as luzes pontuais por malha (caixa da luz, centro mais ou menos o alcance, contra a caixa da malha, que é o critério do motor): praça A, 7 luzes, no máximo **7 por malha** (os 2 blocos de terreno sob a praça; 89 malhas tocadas); praças B e C, o mesmo (14 luzes na cena com duas praças carregadas, 10 blocos de terreno com 7 e nenhuma malha com 8). Teste que acrescenta luzes até estourar (tira de chão, 16 luzes de alcance curto em fila): **8 omni por malha e 8 spot por malha, separados**; a 9ª omni e as seguintes **somem SEM erro, aviso nem queda de quadros** (com 9 a de uma ponta some; com 16 acendem as 8 do meio); 8 omni + 8 spot na mesma malha acendem as 16; a mesma tira partida em 8 lajotas acende as 16 omni. O Compatibility dá o **mesmo resultado**, então o limite não é regressão. **Margem: 1 luz por malha** (7 de 8). Mitigação: ao acrescentar luz perto da praça, partir a malha do chão (ou do bloco de terreno), usar spot para o excedente ou emissivo, e manter no máximo 8 omni por malha.

### Release e personagens animados no mundo real
Release: binário oficial de release do macOS (o já extraído pela LW-053A, sem download), `.pck` exportado de uma cópia do projeto com um `export_presets.cfg` local (não versionado), uma cópia nova do binário por execução. Mac na BATERIA (64 a 78%), não na tomada como o `run_game_release` pede (não foi possível ligar). Com o Mobile a taxa apresentada trava em 120 quadros por segundo (taxa da tela, mesmo com o vsync desligado), então a capacidade vem da **vazão** (os quadros desenhados sem esperar a tela, como na ART-12c).
| praça A, 9 capturas, depuração e release | Compatibility | Mobile |
|---|---|---|
| fps apresentado (média das passadas) | 218 (dep.), 210 (rel.) | 120 (dep. e rel.) |
| vazão: mediana por quadro (ms) | 2,8 a 6,2 (dep.), 4,3 a 7,1 (rel.) | 0,70 a 1,35 (rel.) |
| jogo real, 18 capturas: fps / p99 (ms) | 218 / 8,3 (dep.), 172 / 7,8 (rel.) | 120 / 9,8 (dep.), 120 / 10,2 (rel.) |
| jogo real, vazão: mediana (ms) | 5,4 a 7,4 (dep.), 3,7 a 7,3 (rel.) | 1,0 a 1,2 (rel.) |
| memória de vídeo (praça; jogo) | 22,8 MB; 34 MB | 101 MB; 123 MB |
**Personagens Quaternius animados (provisório) DENTRO do jogo real** (praça A, 12 h, câmera isométrica, simulação e NPCs do jogo rodando, Idle, Walk e Jog em grade de 2,6 m; script de desenvolvimento fora do PR):
| N animados | Compatibility, release: ms por quadro (fps) / pior | Mobile, release: vazão ms (fps) / pior; apresentado | Compatibility, depuração (ms) | Mobile, depuração apresentado |
|---|---|---|---|---|
| 0 | 5,9 (166) / 8,9 | 1,26 (777) / 1,7; 120 fps, pior 11,7 | 5,5 | 120 fps, pior 12,7 |
| 10 | 23,0 (42) / 30,2 | 1,66 (601) / 2,2; 120 fps, pior 9,6 | 22,9 | 120 fps, pior 10,2 |
| 25 | 54,7 (18) / 59,3 | 2,34 (421) / 3,2; 120 fps, pior 9,7 | 52,1 | 120 fps, pior 9,8 |
| 50 | 107,1 (10) / 112,7 | 3,62 (268) / 4,7; 120 fps, pior 9,8 | 107,1 | 120 fps, pior 10,2 |
Custo por personagem: cerca de 0,05 ms no Mobile e 2,0 ms no Compatibility (os números da ART-12b se repetem integrados). **Limites do teste:** só N <= 50 (centenas NÃO estão provadas); personagens parados no lugar (sem navegação, física nem LOD), sem fusão de malhas, com os materiais simples (o sombreador de PALETA, que muda de matiz entre os renderers, NÃO foi testado nem resolvido); os glTF foram carregados em tempo de execução, sem compressão de textura (a memória de vídeo de 4 GB é artefato disso, não de N).

### Plataformas-alvo
DEC-014: PC é a plataforma inicial (consoles e celulares fora do escopo); DEC-015: macOS inicial, sistemas do PC em aberto. **macOS (Metal):** testado aqui (Apple M3, `Metal 4.0 - Forward Mobile`). **Windows:** Vulkan por padrão (`rendering_device/driver.windows`; D3D12 é opcional); a máquina Windows da SP-4a (AMD Radeon RX 9060 XT) rodou em Compatibility; o Mobile NÃO foi testado. **Linux:** Vulkan; NÃO testado (DEC-015 em aberto). **Android e iOS:** a linha `renderer/rendering_method.mobile` fica em Compatibility (fora do escopo, DEC-014). **Web:** o Mobile não existe lá (só o Compatibility) e a Web está fora do escopo. GPU sem Vulkan, D3D12 ou Metal: o motor cai sozinho para OpenGL3 (`fallback_to_vulkan`, `fallback_to_d3d12` e `fallback_to_opengl3` estão ligados) e, como o ajuste de luz é escolhido pelo nome do renderer em uso, nele a luz volta a ser a do Compatibility.

### O que NÃO foi verificado
Windows e Linux (Vulkan e D3D12) e outras GPUs (AMD, NVIDIA, Intel); medição na tomada; o efeito do pré-aquecimento num cache frio; centenas de NPCs animados e o sombreador de paleta; sessão longa de jogo (soak) e salvar e carregar no Mobile; profundidade de campo, névoa volumétrica e oclusão ambiente (não fazem parte do jogo); a cena demonstrativa `renderer_test` (não calibrada). **Leitura (a decisão é de Arthur):** no Mac M3 o Mobile fecha a paridade visual dentro de 0,025 de erro por pixel, é de 4 a 6 vezes mais barato por quadro e cerca de 40 vezes mais barato com personagens animados, sem quadro de regime acima de 20 ms; o que falta para ser o renderer oficial é o teste no Windows (a plataforma provável do público), o pré-aquecimento validado em cache frio e a margem de 1 luz por malha respeitada.
