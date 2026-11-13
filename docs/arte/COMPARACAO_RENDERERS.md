# Comparação dos renderizadores: Compatibility e Forward+

**Status:** método pronto; **resultados PENDENTES** (exigem janela aberta; ver "Como rodar"). Autorizado por Arthur em 13/11/2026 para uma cena demonstrativa isolada, sem modificar o `project.godot`. Nenhuma troca definitiva de renderer está autorizada; o jogo segue em Compatibility (`gl_compatibility`).

## Por que comparar
As três referências (DEC-280) dependem de efeitos que, pelo que se sabe, são de Forward+ ou Mobile: bloom, profundidade de campo, névoa volumétrica e oclusão ambiente em tempo real. O projeto está em Compatibility, sem decisão registrada que o justifique. O que o Compatibility aceita na Godot 4.7.2 **será confirmado por teste**, não por memória.

## Como rodar (1 comando, abre uma janela por cerca de 2 minutos)
`tools/visual/run_renderer_test [pasta-de-saída]`: roda a cena `scenes/demo/renderer_test.tscn` duas vezes, com `--rendering-method gl_compatibility` e depois `--rendering-method forward_plus`, em modo automático (3 predefinições de luz x 3 câmeras), e grava PNGs e `resumo.txt` por renderer. Não altera o `project.godot`.
Teclas na cena interativa: `1`, `2`, `3` luz (dia, hora dourada, crepúsculo); `Q`, `W`, `E` câmera (próxima, isométrica, estratégica); `B` bloom, `O` oclusão ambiente, `F` névoa, `D` profundidade de campo.

## Onde está o código
- Cena: `scenes/demo/renderer_test.tscn`; código: `tools/visual/renderer_test/` (9 componentes: kit de malhas, predefinições, dados, materiais, chão, estruturas, fachada, cena e modo automático); executor: `tools/visual/run_renderer_test`; testes sem janela: `tests/unit/test_renderer_*.gd` (6 arquivos, 28 testes com os de apoio). Fica FORA de `src/`: não lê a simulação nem a ponte, não é montada pelo jogo, não tem autoload e não altera o `project.godot` (o teste da LW-082h exige que `src/tools` só leia pela ponte, e o `tools/check_input_keys` proíbe teclas fixas em `src/`).
- Teclas (1, 2, 3 luz; Q, W, E câmera; B, O, F, D efeitos): guardadas como `InputEventKey` na própria cena, porque o `project.godot` é protegido (não há ações novas para elas). A cena mede 63.948 triângulos, 10 materiais, 4 `MultiMeshInstance3D` e 7 luzes pontuais.
- Tamanho: entregue em 5 partes empilhadas (kit e predefinições; dados e materiais; chão e vegetação; barracas, casas e fachada; cena, modo automático e executor), cada uma dentro do limite do AGENTS 5.2 (a maior, a parte 5, tem 429 linhas, dentro da tolerância de 1,5x). A praça gerada é idêntica à da versão em um arquivo só (impressão digital SHA-256 igual antes e depois).

## Achados sem janela (13/11/2026, Godot 4.7.2, headless)
- Em headless, `get_current_rendering_method()` devolve `gl_compatibility`. A cena mede 63.948 triângulos, 80 nós, 66 malhas, 4 `MultiMeshInstance3D` (6.000 tufos de grama e 720 flores), 10 materiais e 7 luzes pontuais.
- Ao ligar no Compatibility, a engine IMPRIME ERRO para a névoa volumétrica ("só Forward+") e para a profundidade de campo ("só Forward+ ou Mobile"): confirmado por experimento. Para a oclusão ambiente e o bloom o setter não imprime nada, e isso NÃO prova que funcionem: só a janela mostra. A tabela de suporte da cena (`RendererPresets.SUPPORTED`) é hipótese [HIP] até a execução com janela; `--force-effects` liga tudo para conferir.

## Critérios e preenchimento
| # | Critério | Como medir | Compatibility | Forward+ |
|---|---|---|---|---|
| 1 | Fidelidade visual às referências | leitura lado a lado dos PNGs com as 3 imagens, por predefinição | pendente | pendente |
| 2 | Qualidade da iluminação | sol, ambiente, lampiões, névoa e bloom: o que liga e como fica | pendente | pendente |
| 3 | Sombras e materiais | suavidade, cascatas, vazamento; brilho e rim dos materiais | pendente | pendente |
| 4 | Vegetação e detalhes | grama em lâminas, árvores, adereços pequenos; densidade suportada | pendente | pendente |
| 5 | Desempenho | média de quadros por segundo, pior quadro, chamadas de desenho, primitivos, memória (DEC-119: 60 fps e nenhum quadro acima de 33 ms) | pendente | pendente |
| 6 | Compatibilidade com as câmeras do jogo | próxima, isométrica e estratégica: efeitos e qualidade em cada uma | pendente | pendente |
| 7 | Complexidade de manutenção | o que muda no projeto, nos shaders e nos testes; risco de divergência entre os dois | pendente | pendente |

## Como decidir depois dos resultados
- Se o Compatibility entregar o essencial das referências dentro da DEC-119, mantém-se e o guia usa só o que ele suporta.
- Se o ganho do Forward+ for grande e o custo de quadros couber na DEC-119, propõe-se a troca em PR separado (mexe no `project.godot`, arquivo protegido: precisa da aprovação específica de Arthur).
- Qualquer troca exige rodar o `tools/check_all` e a medição de quadros da LW-053A nos dois caminhos.
