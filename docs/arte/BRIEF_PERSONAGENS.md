# Brief visual de personagens do Living World

**Status:** APROVADO por Arthur (direção em 14/11/2026; texto atualizado em 15/11/2026 e aprovado junto com o PR #54, que traz também a `DIRETRIZ_ARTE_GLOBAL.md`). Documento de arte: não altera código, dado, `project.godot` nem arquivo protegido. Valores marcados **[HIP]** são hipóteses a calibrar no protótipo; não são requisitos.

## 1. O que este brief faz
- Define a direção visual dos **personagens humanos** (habitantes, guardas, comerciantes, aldeões e, depois, o jogador).
- **Substitui a interpretação artística anterior dos habitantes** (ART-9, versões v1 a v8: corpos macios, cabeça grande, olhos e bochechas de brinquedo), rejeitada por Arthur como direção final. O código dessas versões (ramo `art-9-habitantes-prototipo`) fica preservado **só como estudo técnico e procedural**.
- **Segue a `DIRETRIZ_ARTE_GLOBAL.md` (15/11/2026)**, que estende a mesma linguagem ao mundo inteiro (construções, adereços, vegetação, rochas, caminhos, criaturas); aqui ficam só as regras de personagem.

## 2. Direção em uma frase
**Mature Stylized Low Poly Fantasy:** humanos de fantasia medieval em low poly facetado e maduro, de anatomia estilizada e convincente, silhueta forte e traje elaborado. Nada de aparência infantil, chibi ou de brinquedo. A referência é linguagem, não molde: culturas, regiões e facções têm variedade e identidade próprias dentro do mesmo estilo (`DIRETRIZ_ARTE_GLOBAL.md`, seção 1).

## 3. As quatro referências (prioritárias; enviadas por Arthur em 14/11/2026)
As imagens são de terceiros: **não entram no repositório** (ele é público) e servem só como referência de linguagem, nunca para copiar modelo, personagem ou arte de outros (DEC-280). Em palavras:
1. Ninja ou monge encapuzado e mascarado, modelo colorido e malha cinza lado a lado: torso atlético, capuz alto, máscara (só os olhos), faixa cruzada, bandagens, luvas sem dedos, calça bufante. Cerca de 1,5 a 2,5 mil triângulos (estimativa visual).
2. Guerreiro barbudo em T-pose, frente e costas: cerca de 7,5 cabeças, rosto natural e sério, peitoral, ombreiras, correias cruzadas com fivela, cinto com fivela hexagonal, saiote de couro com franjas, joelheiras em losango, botas de cano dobrado, machados curtos. Cerca de 3 a 4 mil triângulos (estimativa visual).
3. Espadachim de armadura azul-petróleo (a referência que Arthur indicou em 15/11/2026 como a identidade visual de todo o jogo): tronco largo, ombreiras enormes de placas escalonadas, túnica em tiras, tiracolo, bolsa de aba, grevas escalonadas, espada gigante, rosto anguloso com pintura de guerra. Cerca de 6 a 10 mil triângulos (estimativa visual; referência de elite, não de multidão).
4. Maga: chapéu cônico, casaco longo vincado com padrão, cajado torcido e angular com anel e hexágono emissivo. Cerca de 3 mil triângulos (estimativa visual); proporção mais esguia e paleta mais saturada que as outras (aproveitar o tratamento de pano e de adereço, não a saturação).

| Aspecto | Leitura comum |
|---|---|
| Proporção | Humana e heroica: 7,5 a 8 cabeças, cabeça pequena, ombros largos, tronco em V, mãos e pés legíveis |
| Linguagem de forma | Hard-surface facetado: planos retos, arestas vivas, chanfros, shading plano; cada peça (couro, metal, pano) é um sólido próprio sobre o corpo; pano em planos dobrados e recortados |
| Rosto | Sóbrio, de poucos planos; olhos pequenos e escuros; sem bochecha rosada; muitas vezes encoberto; a silhueta lê antes do rosto |
| Roupa e equipamento | Camadas desenhadas e peças separadas (peitoral, ombreiras escalonadas, correias, fivelas, bolsas, tabardo com franjas, joelheiras, botas dobradas, armas grandes e angulares) |
| Paleta | 4 a 6 cores dessaturadas (ardósia ou petróleo, couro marrom-vinho, creme ou areia, carvão), pele natural, um acento; cor por bloco |
| Rigidez | Alta; a estilização está nas proporções heroicas e no exagero de ombreira, luva e arma, não em arredondar |

## 4. Regras de linguagem (o que tem de ser verdade)
1. **Anatomia e proporção.** 7,5 a 8 cabeças é a referência para **adultos heroicos** (guarda, guerreiro), **não uma regra universal**. Os demais variam de verdade por idade, constituição e ofício (por exemplo: idoso mais baixo e curvado, jovem esguio, aldeão robusto, comerciante corpulento ou magro). A diferença é de **anatomia** (tronco, membros, cabeça), não uma escala uniforme do mesmo molde. A cabeça é sempre pequena em relação ao corpo; ombros, mãos e pés legíveis.
2. **Forma.** Facetada por padrão: planos retos, arestas vivas e chanfros pequenos, sem arredondamento fofo e sem suavização de normais na roupa, na armadura e no corpo. Um suavizado local só se a aparência do protótipo o pedir e Arthur aceitar.
3. **Rosto.** Sóbrio, expressivo e proporcional: poucos planos legíveis (testa, arcada, nariz em cunha, maçã, mandíbula), olhos pequenos e escuros com pálpebra marcada, sobrancelha, boca por plano ou linha; barba e cabelo em blocos angulares; a idade vem de planos e linhas. Proibido: olho grande de brinquedo, bochecha rosada ou redonda como padrão, cabeça de boneco, proporção chibi. Rostos encobertos (capuz, máscara, elmo, aba) são legítimos.
4. **Roupa e equipamento.** Camadas desenhadas, peças separadas com material próprio. Catálogo de partida: peitoral, gibão, ombreiras escalonadas, braçadeiras, luvas sem dedos, correias cruzadas com fivela, cintos, bolsas de aba, tabardo e saiote com franjas recortadas, calça, joelheiras e grevas, botas de cano dobrado, capuz, máscara, chapéu, capa. Tecido como planos dobrados e recortados (barras em ponta, tiras), nunca como tubo. Armas e ferramentas com desenho próprio (machado, espada, alabarda, cajado, cesto, ferramenta de ofício).
5. **Paleta e material.** Paleta restrita por personagem (4 a 6 cores, dessaturadas nas referências, mas a cor é usada com intenção: paletas por cultura, região e facção, sem eliminar o colorido) e um acento por ofício ou facção; peles naturais e variadas; cor por bloco de material. **Cor por vértice é o ponto de partida, mas texturas e materiais estilizados são permitidos se forem necessários para a qualidade** (sem foto-textura), decididos pela aparência no protótipo; toda fonte entra no manifesto com licença e custo zero. Metal só em detalhes (`GUIA_VISUAL.md`, seção 5). **Um material por personagem, se possível.**
6. **Leitura de classe e função.** Silhueta mais **uma peça de assinatura por papel** (guarda: ombreira e arma de haste ou espada; comerciante: capa, bolsa e carga; aldeão: avental, ferramenta ou cesto): legível a 40 m e recompensando o olhar a 4 m.
7. **Desempenho.** DEC-119 (média de 60 quadros por segundo ou mais, nenhum quadro acima de 33 ms, no Mac de referência, em release). Triângulos [HIP]: personagem de destaque de 3 a 8 mil no LOD 0 (as referências vão de 1,5 a 10 mil). **Triângulo é limite, não critério de qualidade.** Qualidade se compara por medição real (`DIRETRIZ_ARTE_GLOBAL.md`, seção 3).
8. **Duas camadas desde o desenho.** Perto da câmera, a versão rica; longe ou em multidão, a versão simplificada **do mesmo estilo** (mesma ficha, mesmas cores e mesma silhueta, com menos triângulos e animação mais barata). O desenho da segunda camada acompanha o primeiro personagem; a produção em série (LOD, multidão, variação) só vem depois do aceite visual dele.

## 5. Técnica
- Decisão de 14/11/2026: **base Quaternius CC0** (modular, esqueleto de 65 ossos e animações), abordagem **A agora, evoluindo aos poucos para a C híbrida**; não é um padrão definitivo e imutável. Serve como base técnica, modelo provisório ou recurso final adaptado, conforme a qualidade obtida (`DIRETRIZ_ARTE_GLOBAL.md`, seção 4).
- O visual original da Quaternius é semirrealista e suave; o que o aproxima das referências é uma hipótese [HIP] a demonstrar na D1: decimar com o LOD do importador, normais planas, cor por face em um material e peças rígidas de armadura sobre os ossos. Peças próprias só onde faltar (armadura de placas, capa, chapéus, rostos); nada de corpos e rostos próprios extensos agora.
- **Não forçar a geração procedural** se ela produzir resultado visualmente inferior. O protótipo procedural do guarda segue pausado.
- Custo zero, licença registrada em `MANIFESTO_LICENCAS.md`, sem serviço de IA 3D de terceiros, sem download sem autorização.
- **Veredito da D1 (Arthur, 15/11/2026):** o Quaternius original tem rosto, anatomia e acabamento superiores aos dois facetados; o rosto facetado ficou angular demais e o LOD longe não serve de referência para o de perto. O alvo é um **meio-termo**: a qualidade facial e anatômica do Quaternius com a linguagem geométrica, as roupas, as armaduras e a silhueta do guerreiro de referência e a eficiência dos LODs, sem reduzir o rosto a poucos polígonos só por desempenho. Os modelos atuais são provisórios (`D1_RESULTADOS.md`).

## 6. Critério de aceite
- **Principal: a aparência.** Arthur decide pelo olhar se o personagem realmente se aproxima das referências, sem copiar modelos protegidos. Métricas geométricas ou quantitativas **não substituem** essa avaliação.
- Obrigatórios, porém insuficientes: DEC-119, determinismo, isolamento (nada em `sim`, `bridge` ou `app`), licenças registradas, testes verdes.
- Cada personagem é entregue com: frente, costas e perspectiva; comparação de proporções com as referências (feita só localmente: as imagens de terceiros não vão ao repositório nem ao PR, que são públicos); rosto de perto; silhueta; materiais e equipamentos de perto; as duas camadas (perto e longe) lado a lado, com o custo medido de cada uma.

## 7. Processo
1. Este brief e a `DIRETRIZ_ARTE_GLOBAL.md` aceitos por Arthur.
2. **D1**, etapa de personagem: **UM** adulto representativo (o guarda), em duas camadas, isolado (nada entra no mundo real).
3. Aceite visual de Arthur.
4. Só com o aceite: o comerciante e o aldeão.
5. Só com o aceite desses: variação (corpos, idades, constituições, ofícios), LOD e multidão em série, e adoção no mundo em fatias de até 450 linhas, cada uma com contrato e aceite visual.

Estas são as etapas do personagem; elas se encaixam nas etapas 2 e 6 da `DIRETRIZ_ARTE_GLOBAL.md` (seção 6), e a D1 cobre as etapas 2 a 5 dela.

Já pronto no repositório e independente do visual final: ativos CC0 com manifesto, catálogo de peças, aparência determinística por NPC e paletas; em curso: montador de peças e barba opcional. **Retomados pelo veredito de Arthur (15/11/2026):** o shader de paleta de pano e a integração controlada dos personagens animados no mundo, com o visual original da Quaternius do contrato atual e o aceite visual dele.

**Fora do escopo agora:** multidões em série, criaturas e montarias.

## 8. Rastreio
- 13/11/2026: DEC-280 e o guia visual (identidade geral do mundo).
- 14/11/2026: DEC-021 aprovada (direção híbrida: kits CC0 ou procedural, o que atender melhor).
- 14/11/2026: ART-9 v1 a v8 (habitantes de corpo macio) rejeitadas como direção final; este brief as substitui; código preservado só como estudo.
- 14/11/2026: direção "Mature Stylized Low Poly Fantasy" e plano enxuto aprovados por Arthur, com as quatro referências como referência prioritária de personagens; base Quaternius CC0 aprovada (A agora, C depois).
- 15/11/2026: Arthur estendeu a direção ao jogo inteiro (`DIRETRIZ_ARTE_GLOBAL.md`).
