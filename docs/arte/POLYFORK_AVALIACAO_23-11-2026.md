# Polyfork como biblioteca de recursos 3D: primeira avaliação (23/11/2026)

**Estado:** avaliação técnica feita só em `--headless`; **nenhum arquivo de terceiros está no repositório e nada foi integrado no jogo.** A aprovação da seleção e das licenças é de Arthur. A leitura visual no Godot (com janela) está pendente. Pedido de Arthur de 23/11/2026 (seção 5 da mensagem: Polyfork como biblioteca de recursos 3D do LivingWorld, com curadoria progressiva, licença verificada e testes isolados).

## 1. Como está organizado
- **Biblioteca privada FORA do repositório** (pasta `LivingWorld-ArtLibrary`, ao lado dele): uma pasta por categoria (Characters, Clothing, Weapons, Armor, Equipment, Buildings, Markets, Workshops, Nature, Props, Animals, Creatures, Transport, References); `catalogo.csv` (nome, id e endereço de origem, categoria, autor, licença e classe, formatos, triângulos, texturas, materiais, rig, animações, compatibilidade com o Godot, adaptação, prioridade e status: referência, candidato, aprovado, testado, integrado); `LICENCAS.md` (classes A a E, e B* = política geral conferida, página do item ainda não); um projeto Godot de teste isolado com a cena de comparação.
- **Quem faz o quê:** a pesquisa no catálogo é do `polyfork-scout` (Haiku, só ferramentas MCP de leitura; nunca baixa); a avaliação no Godot é de um agente de arte técnica (Sonnet); o download é uma etapa separada do Maestro, só de itens com licença conferida na página do item.
- **Ferramentas do servidor que NÃO se usam:** gerar variante, comprar plano e registrar pedido (podem custar ou gravar no servidor; custo zero além da assinatura).

## 2. Licença (conferida em polyfork.dev/licensing e na página de cada item baixado, em 23/11/2026; é leitura, não parecer jurídico)
- Os arquivos de malha dos modelos gratuitos de baixo polígono (GLB, FBX, USD, OBJ) valem sob duas licenças, à escolha de quem usa: **CC BY 4.0** (usar, modificar, compartilhar e vender, com crédito ao Polyfork e aviso de modificação) ou a **licença Polyfork** (uso comercial sem crédito, mas sem redistribuir o arquivo avulso; o jogo pode embuti-lo).
- **Consequência para o repositório PÚBLICO:** arquivo do Polyfork só entra com o crédito CC BY 4.0 registrado (`docs/arte/MANIFESTO_LICENCAS.md`) e a aprovação de Arthur; sem isso, fica só na biblioteca privada. Não são cobertos pela CC BY: módulos ES, edições HD, renders e miniaturas. É proibido usar o material para construir ou treinar gerador comercial de ativos 3D (não é o caso).
- **O catálogo do MCP não informa licença nem autor** (só `free` e `remixable`): a conferência é na página do item. Item não conferido fica na classe B* e NÃO é baixado.

## 3. O que o catálogo tem
- Cerca de 3,5 mil modelos gratuitos de baixo polígono e dezenas de kits; em cada kit, todas as peças compartilham paleta e escala.
- O **Medieval Village Kit** (60 peças, gratuito) cobre quase tudo da LW-099 e do povoado: comerciante, artesão, guarda, aldeão, carroça de duas e de quatro rodas, carrinho de mão, cavalo de tração, arado, barril, caixote, saco de grãos, feno, barraca de mercado, forja, bigorna, forno de pão, moinhos, casas, taverna, celeiro, capela, torre de vigia, muros, poço, árvores e terrenos.
- Descartados por estilo ou cultura: modelos japoneses, chineses, de faroeste, modernos, de feira ou infantis; as raças fantásticas do kit Mythic Character Vault (só as armas e os escudos interessam).

## 4. Seleção baixada e medida (13 modelos do Medieval Village Kit, 5,4 MB; Godot 4.7.2, importação sem aviso)
| Modelo | Triângulos | Malhas | Veredito (estilo, técnica, reuso de 1 a 5) |
|---|---|---|---|
| Merchant, Village Guard, Male Villager | 4.007, 4.355, 3.735 | 10, 9, 7 | adaptar (3, 4, 4) |
| Draft Horse | 3.939 | 3 | adaptar (3, 3, 3; face dupla, 2,55 m) |
| Wooden Cart, Four-Wheel Wagon | 1.746, 2.070 | 4, 6 | adaptar (3, 4, 4 e 3, 3, 3) |
| Wheelbarrow | 1.132 | 3 | adotar com ajuste de cor (3, 5, 3; é empurrado, fica à frente) |
| Barrel, Wooden Crate, Grain Sack | 564, 700, 448 | 2, 2, 1 | adotar com ajuste de cor (4, 5, 4) |
| Market Stall | 592 | 2 | adotar com ajuste de cor (3, 5, 3; menor que as barracas da praça) |
| Blacksmith Forge, Thatched Cottage | 1.668, 1.764 | 3, 2 | adotar com ajuste de cor (4, 4, 4 e 4, 5, 4) |

## 5. Achados técnicos (headless; o headless não desenha, então nada visual foi medido)
- **Esqueletos:** o GLB declara uma "skin" por malha (7 a 10 por pessoa), mas o Godot as funde em UM `Skeleton3D` de 31 ossos (cavalo, 24). O custo real são 7 a 10 malhas por pessoa: 50 NPCs em S0 seriam cerca de 201.600 triângulos e 433 malhas (50 Ice Warriors: cerca de 400.000 triângulos e 50 malhas). Fundir as malhas é uma adaptação possível.
- **Cor:** as malhas trazem cor por vértice, mas o material importado a deixa DESLIGADA: sem ajuste os modelos saem brancos (ligar o uso da cor por vértice como albedo; conferir sRGB ou linear na janela).
- **Forma e escala:** 100% facetado (sombreamento plano); humanos de 1,70 a 1,75 m; frente +Z (girar 180 graus); origem nos pés ou no centro da base.
- **Animação:** Idle, Walk e Run no lugar e sem laço (ligar `LOOP_LINEAR`); Walk perto de 1 m/s e Run perto de 7,5 m/s (estimativa), logo não cobrem 2,8 a 4 m/s sem deslize. O pipeline atual (`CharacterRetarget` e `CharacterFigure`) assume 65 ossos da UAL; usar os 31 ossos do Polyfork exigiria retarget.
- **Caravana montada em script (LW-099):** carrinho com comerciante e 3 cargas: 7.211 triângulos e 18 malhas; carroça com cavalo: 11.728 e 24; seis caravanas: 43.266 e 70.368 triângulos. Rodas com pivôs limpos (girar por velocidade ÷ raio); varas e timão rígidos a poucos centímetros do chão (engate a resolver); só 3 volumes de carga contra 10 bens do jogo.
- **Câmera:** a câmera real do jogo é perspectiva elevada de terceira pessoa (12 m, 35 graus, campo de visão 75), não isométrica.

## 6. Lacunas e candidatos ainda NÃO baixados (classe B*)
- Carga: pilha de lenha (madeira), pilha de lingotes (metal), monte de minério, cesto com pão, jarros de barro, fardo de palha (substituto da lã). Transporte: carroça de mão puxada, carroça de boi, boi, burro e mula de carga. Ofícios e interiores: baú com ferragens, caldeirão sobre brasas, mó de mão, fogão de barro, banco de tora, gabarito de trançado, placa pintada, escada, martelo hidráulico.
- **Sem peça no catálogo:** mesa, cadeira, cama e estante medievais; panelas e canecas; pá de forno; martelo, tenaz, serrote e plaina; tear e roca; enxada, foice, forcado e prensa; pilha de tábuas; rolo de tecido; fardo de lã; caixa de ferramentas; lona; arreios avulsos. Não há outro kit medieval europeu com a mesma paleta.

## 7. Aderência à direção artística (leitura provisória, só por geometria e pela página do site)
O estilo é facetado e blocado, na família do POLYGON Fantasy Kingdom (referência aprovada de linguagem e qualidade), com personagens mais simples (cerca de 4 mil triângulos, poucas cores por malha) que o Ice Warrior (padrão dos personagens principais). Recomendação: usar para cenário, objetos, caravana e, talvez, NPCs de fundo; não substituir os personagens principais. O juízo visual final depende da janela do Godot.

## 8. Próximos passos e decisões de Arthur
1. Autorizar capturas com janela do Godot na cena de comparação (já preparada no projeto de teste) ou abri-la ele mesmo.
2. Aprovar ou recusar a seleção e as licenças (classe B, crédito CC BY 4.0) antes de qualquer arquivo entrar no repositório.
3. Decidir como adotar (ajuste de cor, laço dos clipes, giro, fusão de malhas, retarget) e como preencher as lacunas (peças próprias ou outro conjunto).
