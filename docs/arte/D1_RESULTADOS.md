# D1: resultados, critérios artísticos e aprendizados (15/11/2026)

**Status:** REGISTRO do veredito de Arthur de 15/11/2026 sobre a demonstração D1 (guarda, praça e cena integrada), a pedido dele (registrar os critérios artísticos e o que aprendemos na D1). Documento de arte: não altera código, dado, contrato, roadmap, `project.godot`, `AGENTS.md` nem `DECISIONS.md`; não abre fila nova de arte. Valores marcados **[HIP]** são hipóteses.

## 1. O que foi a D1
Três estudos isolados (nada entrou no jogo), preservados em ramos sem PR, com as ferramentas:

| Estudo | Ramo (commit) | O que tem |
|---|---|---|
| D1-A, o guarda | `art-d1-guarda` (722a4c3) | `tools/visual/d1_guarda/`: passagem de facetamento sobre a base Quaternius (decimação por LOD, normal plana, cor por face e por bloco, um material) e peças rígidas com o `PlazaMeshKit`; duas camadas: perto (4.326 triângulos) e longe (1.176) |
| D1-B, a praça | `art-d1-mundo` (926680c) | variante de dados `d` na planta da A, barraca de encosto, poço e adereços com chanfros e camadas (`plaza_crafted.gd`, `plaza_style.gd` e quatro funções novas no `PlazaMeshKit`), `tools/visual/d1_mundo/` |
| D1-C, a cena | `art-d1-cena` (5323044) | `tools/visual/d1_cena/`: a praça atual com cápsulas ao lado da nova com o guarda, 12 pares de capturas e a medição por cenário |

As capturas e as malhas geradas ficam só localmente (fora do Git). As imagens de referência de terceiros nunca entram no repositório (público).

## 2. Veredito de Arthur
A D1 está **aprovada como prova de direção artística e de viabilidade técnica**, mas **não** como adoção definitiva de modelos, paleta ou iluminação no jogo principal, e não autoriza substituir assets em massa.
1. **Cenário: direção aprovada.** Barracas, telhados, vigas, poço e objetos com volumes mais elaborados são, nas palavras dele, "a direção de qualidade que quero preservar".
2. **Cor com intenção, não eliminada.** Estética madura não é falta de cor: mercados coloridos, vegetação vibrante, flores e decorações, iluminação quente, atmosferas diferentes, paletas próprias de cada região, cultura e bioma.
3. **Personagens: qualidade ainda não aprovada.** O Quaternius original (roupa verde) tem rosto, anatomia e acabamento superiores aos dois modelos facetados; o guarda central mostra uma direção interessante para roupas e armaduras, mas o rosto ficou angular demais; o modelo de LOD distante não serve de referência para o de perto. A referência artística segue sendo o guerreiro com espada. O alvo é um **meio-termo**: a qualidade facial e anatômica do Quaternius, a linguagem geométrica, as roupas, as armaduras e a silhueta do guerreiro de referência e a eficiência dos LODs, sem reduzir o rosto a poucos polígonos só por desempenho.
4. **Desempenho:** preservar os resultados e a infraestrutura; os números são promissores, mas não provam que o visual mais facetado seja superior em todas as situações; nenhuma investigação extensa nova agora.
5. **Prioridade:** o visual perfeito não atrasa o roadmap funcional. Consolidar os aprendizados; preservar protótipos e ferramentas; **não** iniciar uma D2 extensa; continuar a integração controlada dos personagens animados, respeitando o contrato atual e os aceites visuais; tratar os modelos atuais como **provisórios**; retomar o refinamento artístico numa frente pequena e isolada quando houver oportunidade, sem bloquear economia, contratos, caravanas e as demais fases.

## 3. O que aprendemos
**Cenário.** O pipeline procedural (malhas facetadas por script, cor por vértice) chega à linguagem nova só com parâmetros, dados e quatro funções de kit, sem reescrever gerador: o poço ganhou fiadas de pedra e telhado de telhas; a barraca, postes, vigas, nervuras e barra em ponta; caixotes e barris, tábuas e aros. Tábua, chanfro e aro só leem até uns 6 a 8 m (a 22 m viram massa de cor). Triângulos da praça: 63.948 para 71.482 (+11,8%; estruturas 2.676 para 10.210); o custo de render ficou no ruído (CPU 0,23 para 0,21 ms; vídeo 97,5 para 97,9 MB); o custo é triângulo. Limites: a barraca de encosto tem silhueta baixa e retangular; os sacos de ponta lembram cebola; casas, árvores, rochas e grama só mudaram de cor.
**Luz.** A luz decide a leitura da paleta: de dia a imagem fica mais sóbria (saturação média 0,37 para 0,18), mas na hora dourada fica igual (0,74 contra 0,73) e no crepúsculo sobe (0,43 para 0,55); sem as bandeirolas emissivas o crepúsculo da praça nova perde vida (falta uma regra de acento luminoso); o contraluz da hora dourada apaga a paleta nos dois lados.
**Personagens.** O facetamento sobre a malha orgânica do Quaternius dá facetas miúdas e irregulares (estilo "scan"), não planos desenhados; mãos e cotovelos seguem orgânicos; a decimação trava nas bordas (pisos de triângulos por peça); a camada longe (1.176 triângulos) deforma a cabeça se vista a menos de uns 20 m; a identidade veio em boa parte das peças próprias de armadura, botas, tabardo e espada. A 20 m o guarda lê como gente (é o elemento mais saturado da praça); a 60 m ninguém lê bem; na hora dourada o guarda some a 20 m contra o chão escuro.
**Custo (depuração, Mobile, M3 na tomada; release NÃO medido).** Por personagem: original 31.314 triângulos e 14 superfícies; perto 4.326 e 1; longe 1.176 e 1; custo por personagem 0,068, 0,017 e 0,008 ms. Praça com 25 habitantes, vazão mediana: 25 cápsulas 1,14 ms; 25 Quaternius originais 2,09 ms; 5 perto + 20 longe 1,39 ms; 50 longe 1,72 ms (dispersão entre execuções de uns 0,2 ms). Os custos por personagem vêm da medição do guarda isolado ((N=50 menos N=1)/49) e os da praça, da medição da cena (vazão total da praça com os habitantes); por isso não se somam.

## 4. Critérios artísticos para as próximas fatias
1. Geometria do cenário: robusta e angular, com camadas visíveis (vigas, fiadas, tábuas, telhas); é a direção a preservar.
2. Cor com intenção artística: paleta própria por região, cultura, facção e bioma; a sobriedade é escolha por região, não regra global.
3. Personagens: rosto e anatomia no nível do Quaternius; roupas, armaduras e silhueta na linguagem do guerreiro de referência; a camada longe é do mesmo estilo, mas não é referência para a de perto.
4. Desempenho e estética avaliados juntos; nenhum rosto é reduzido a poucos polígonos só para ganhar quadros.
5. Nada visível entra no jogo principal sem o aceite visual de Arthur; nenhuma substituição em massa; os modelos atuais são provisórios.

## 5. Próximos passos (sem fila nova de arte)
- A integração controlada dos personagens animados segue com o visual **original** da Quaternius do contrato atual (sem normais planas, sem trocar texturas), com captura para o aceite visual de Arthur antes de aparecer no jogo.
- Qualquer adoção da linguagem facetada nos personagens exigiria um aditivo ao contrato (classe 3, com o aceite dele): não está proposta.
- O refinamento artístico retoma numa frente pequena e isolada quando houver oportunidade; entre as pontas soltas da D1 (sem compromisso nem fila) estão a regra de luz e de acento luminoso da hora dourada e do crepúsculo, o teste de casas, vegetação e rochas na nova linguagem, e a legibilidade do personagem a 20 m na luz baixa.
