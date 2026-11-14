# Brief visual de personagens do Living World

**Status:** PROPOSTA para o aceite de Arthur (14/11/2026), a partir da aprovação da direção "Mature Stylized Low Poly Fantasy" e do plano enxuto (mensagem de Arthur de 14/11/2026). Documento de arte: não altera código, dado, `project.godot` nem arquivo protegido. Valores marcados **[HIP]** são hipóteses a calibrar no protótipo; não são requisitos.

## 1. O que este brief faz
- Define a direção visual dos **personagens humanos** (habitantes, guardas, comerciantes, aldeões e, depois, o jogador).
- **Substitui a interpretação artística anterior dos habitantes** (ART-9, versões v1 a v8: corpos macios, cabeça grande, olhos e bochechas de brinquedo), rejeitada por Arthur como direção final. O código dessas versões (ramo `art-9-habitantes-prototipo`) fica preservado **só como estudo técnico e procedural**.
- **Não modifica a direção visual geral já aprovada para o mundo** (DEC-020, DEC-021 e DEC-280; `GUIA_VISUAL.md`): construções, vegetação, adereços, luz e câmeras seguem como estão. As formas "gordas" da seção 4 do guia valem para construções e adereços; **para personagens vale este brief**.

## 2. Direção em uma frase
**Mature Stylized Low Poly Fantasy:** humanos de fantasia medieval em low poly facetado e sofisticado, de anatomia estilizada e convincente, silhueta forte e traje elaborado. Nada de aparência infantil, chibi ou de brinquedo.

## 3. As quatro referências (prioritárias; enviadas por Arthur em 14/11/2026)
As imagens são de terceiros: **não entram no repositório** (ele é público) e servem só como referência de linguagem, nunca para copiar modelo, personagem ou arte de outros (DEC-280). Em palavras:
1. Ninja ou monge encapuzado e mascarado, modelo colorido e malha cinza lado a lado: torso atlético, capuz alto, máscara (só os olhos), faixa cruzada, bandagens, luvas sem dedos, calça bufante. Cerca de 1,5 a 2,5 mil triângulos (estimativa visual).
2. Guerreiro barbudo em T-pose, frente e costas: cerca de 7,5 cabeças, rosto natural e sério, peitoral, ombreiras, correias cruzadas com fivela, cinto com fivela hexagonal, saiote de couro com franjas, joelheiras em losango, botas de cano dobrado, machados curtos. Cerca de 3 a 4 mil triângulos.
3. Espadachim de armadura azul-petróleo: tronco largo, ombreiras enormes de placas escalonadas, túnica em tiras, tiracolo, bolsa de aba, grevas escalonadas, espada gigante, rosto anguloso com pintura de guerra. Cerca de 6 a 10 mil triângulos (referência de elite, não de multidão).
4. Maga: chapéu cônico, casaco longo vincado com padrão, cajado torcido e angular com anel e hexágono emissivo. Cerca de 3 mil triângulos; proporção mais esguia e paleta mais saturada que as outras (aproveitar o tratamento de pano e de adereço, não a saturação).

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
2. **Forma.** Facetada por padrão: planos retos, arestas vivas e chanfros pequenos, sem suavização de normais na roupa, na armadura e no corpo. Um suavizado local só se a aparência do protótipo o pedir e Arthur aceitar.
3. **Rosto.** Sóbrio, expressivo e proporcional: poucos planos legíveis (testa, arcada, nariz em cunha, maçã, mandíbula), olhos pequenos e escuros com pálpebra marcada, sobrancelha, boca por plano ou linha; barba e cabelo em blocos angulares; a idade vem de planos e linhas. Proibido: olho grande de brinquedo, bochecha rosada ou redonda como padrão, cabeça de boneco. Rostos encobertos (capuz, máscara, elmo, aba) são legítimos.
4. **Roupa e equipamento.** Camadas desenhadas, peças separadas com material próprio. Catálogo de partida: peitoral, gibão, ombreiras escalonadas, braçadeiras, luvas sem dedos, correias cruzadas com fivela, cintos, bolsas de aba, tabardo e saiote com franjas recortadas, calça, joelheiras e grevas, botas de cano dobrado, capuz, máscara, chapéu, capa. Tecido como planos dobrados e recortados (barras em ponta, tiras), nunca como tubo. Armas e ferramentas com desenho próprio (machado, espada, alabarda, cajado, cesto, ferramenta de ofício).
5. **Paleta e material.** Paleta restrita e dessaturada por personagem (4 a 6 cores) e um acento por ofício ou facção; peles naturais e variadas; cor por bloco de material. **Cor por vértice é o ponto de partida, mas texturas e materiais estilizados são permitidos se forem necessários para a qualidade** (sem foto-textura), decididos pela aparência no protótipo; toda fonte entra no manifesto com licença e custo zero. Metal só em detalhes (`GUIA_VISUAL.md`, seção 5).
6. **Leitura de classe e função.** Silhueta mais **uma peça de assinatura por papel** (guarda: ombreira e arma de haste ou espada; comerciante: capa, bolsa e carga; aldeão: avental, ferramenta ou cesto): legível a 40 m e recompensando o olhar a 4 m.
7. **Desempenho.** DEC-119 (média de 60 quadros por segundo ou mais, nenhum quadro acima de 33 ms, no Mac de referência, em release). Triângulos [HIP]: personagem de destaque de 3 a 8 mil no LOD 0 (as referências vão de 1,5 a 10 mil). **Triângulo é limite, não critério de qualidade.** LOD, multidão e variação não entram antes do aceite visual.

## 5. Técnica (decisão em aberto)
- Abordagem **híbrida**, com preferência inicial por **base modular própria** (corpo, rosto e peças em código, determinísticos por hash), mas **ainda não definitiva**.
- **Primeiro** uma pesquisa de leitura de modelos e kits CC0 (qualidade, proporção e animação); o resultado vai ao relatório de Arthur. Um kit só entra com CC0 comprovada na fonte e aparência próxima das referências.
- **Não forçar a geração procedural** se ela produzir resultado visualmente inferior: o kit pode servir de base, de doador de esqueleto e animações, ou só de estudo.
- Custo zero, licença registrada em `MANIFESTO_LICENCAS.md`, sem serviço de IA 3D de terceiros, sem download sem autorização.

## 6. Critério de aceite
- **Principal: a aparência.** Arthur decide pelo olhar se o personagem realmente se aproxima das referências, sem copiar modelos protegidos. Métricas geométricas ou quantitativas **não substituem** essa avaliação.
- Obrigatórios, porém insuficientes: DEC-119, determinismo, isolamento (nada em `sim`, `bridge` ou `app`), licenças registradas, testes verdes.
- Cada personagem é entregue com: frente, costas e perspectiva; comparação de proporções com as referências; rosto de perto; silhueta; materiais e equipamentos de perto.

## 7. Processo
1. Pesquisa de kits CC0 e este brief.
2. Primeiro protótipo isolado: **UM** adulto bem desenvolvido (guarda ou guerreiro).
3. Aceite visual de Arthur.
4. Só com o aceite: um comerciante e um aldeão.
5. Só com o aceite desses: variação (corpos, idades, constituições, ofícios), LOD, multidão, esqueleto e animação, e adoção no mundo em fatias de até 450 linhas, cada uma com contrato e aceite visual.

**Fora do escopo agora:** multidões, LOD, sistemas de variação, animação, adoção no mundo, criaturas e montarias.

## 8. Rastreio
- 13/11/2026: DEC-280 e o guia visual (identidade geral do mundo).
- 14/11/2026: DEC-021 aprovada (direção híbrida: kits CC0 ou procedural, o que atender melhor).
- 14/11/2026: ART-9 v1 a v8 (habitantes de corpo macio) rejeitadas como direção final; este brief as substitui; código preservado só como estudo.
- 14/11/2026: direção "Mature Stylized Low Poly Fantasy" e plano enxuto aprovados por Arthur, com as quatro referências como referência prioritária de personagens.
