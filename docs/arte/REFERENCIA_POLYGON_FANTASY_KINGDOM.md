# Referência visual POLYGON Fantasy Kingdom: registro da direção de Arthur (17/11/2026)

**Status:** REGISTRO da direção de Arthur de 17/11/2026 (chat). Documento de arte: não altera código, dado, contrato, roadmap, `project.godot`, `AGENTS.md` nem `DECISIONS.md`; DEC nova só por pedido expresso dele. **A imagem que ele citou NÃO chegou** (só o texto): nada aqui foi inferido dela. Se vier, fica SÓ LOCAL e nunca entra no repositório nem no PR (o repositório é público e a arte é de terceiros), como já se faz com as referências do `BRIEF_PERSONAGENS.md` (seção 3). Este documento não abre fila de arte e não reabre o que já está aprovado.

## 1. A direção (de Arthur, resumida)
- A qualidade e a linguagem visual de **POLYGON Fantasy Kingdom** são a referência para personagens, cenários, equipamentos e construções do Living World, **preservando a identidade original** do universo.
- Low poly estilizado, de geometria facetada e intencional. Personagens de proporções convincentes, **sem** aparência chibi ou infantil; roupas, armaduras e equipamentos em camadas e de silhuetas variadas.
- Construções medievais com detalhe arquitetônico; ferrarias, mercados, tavernas, oficinas e outros estabelecimentos visualmente ricos; madeira, pedra, metal e tecido bem diferenciados; iluminação expressiva e coerente com cada ambiente; cores vivas e bem combinadas, **sem** obrigar paleta escura ou dessaturada; identidade consistente entre personagens, objetos e cenários.
- O **Ice Warrior** segue como a principal referência de personagem, já aprovada. Os futuros habitantes, comerciantes, ferreiros, soldados e aventureiros devem ter qualidade e coerência semelhantes, cada um com as suas características: **não** o mesmo corpo, roupa ou silhueta.
- É referência de linguagem e qualidade, **não** autorização para reproduzir modelos ou materiais de terceiros. **O padrão ainda NÃO foi atingido** (cenários provisórios, sistemas visuais incompletos, personagens por evoluir). A imagem orientará as FASES futuras de produção visual; o trabalho artístico **não paralisa** o gameplay nem a economia.

## 2. O que já está aprovado e é compatível (comparado, sem reabrir)
Siglas, todas em `docs/arte/`: DIR = `DIRETRIZ_ARTE_GLOBAL.md`; GUIA = `GUIA_VISUAL.md`; BRIEF = `BRIEF_PERSONAGENS.md`; D1 = `D1_RESULTADOS.md`.

| Ponto da direção | Onde já está coberto |
|---|---|
| Referência de linguagem, não cópia; originalidade | DEC-280 (consequências); DIR seção 1; GUIA seção 2 ("é proibido copiar modelo, personagem, marca ou arte de outros jogos") |
| Low poly facetado e intencional | DIR seção 2 (Geometria: planos angulares, arestas vivas, chanfros pequenos); D1 seção 4, item 1 (geometria do cenário "robusta e angular, com camadas visíveis": a direção a preservar) |
| Proporções convincentes, sem chibi | BRIEF seção 4, regras 1 e 3 (7,5 a 8 cabeças só para adultos heroicos; os demais variam por idade, constituição e ofício; chibi e olho de brinquedo proibidos); DIR seção 2 (Anatomia) |
| Roupa e equipamento em camadas, silhuetas | BRIEF seção 4, regras 4 e 6 (catálogo de peças de partida; uma peça de assinatura por papel); DIR seção 2 |
| Construções medievais e mercado | DIR seção 2 (Arquitetura: vigas, fiadas de pedra, beirais, telhas); GUIA seções 4, 8 e 12; D1 seções 2 e 3 (poço e barraca: "a direção de qualidade que quero preservar") |
| Materiais | GUIA seção 5 (cor por vértice, atlas ou textura estilizada; até cerca de 12 materiais por cena; metal só em detalhes); BRIEF 4.5; DIR seção 2 (couro, metal e pano como peças separadas) |
| Iluminação | GUIA seção 6 (dia, hora dourada e crepúsculo; lampiões e emissivos); `COMPARACAO_RENDERERS.md` (renderer Mobile oficial e luz calibrada) |
| Cores vivas, sem paleta escura obrigatória | DIR seção 2 (Paleta: "cor com intenção artística, nunca eliminada"; a sobriedade é escolha por região); D1 seção 2, item 2. A tabela da seção 3 do BRIEF diz "dessaturadas" ao descrever as imagens antigas: é descrição, e a regra 5 da seção 4 já a corrige |
| Identidade única no jogo inteiro | DIR seções 1 e 2 (Câmeras: cada peça vale em terceira pessoa, isométrica e estratégica) |
| Ice Warrior como referência principal | DIR seção 10 (confirmado em 15/11/2026; o Ranger da Quaternius e o guarda facetado da D1 são provisórios); `docs/modules/presentation.md` (contrato de "figura inteira", PR #76) |
| Padrão ainda não atingido | DEC-280 (a cena de cones, cápsulas e caixas é provisória); D1 seção 4, item 5 (modelos atuais provisórios); `docs/operacao/FILA.md` (o visual dos NPCs no mundo ainda não existe); `presentation.md`, entrega 7 (o Ice Warrior não está ativo no jogo: a integração de UM NPC está preparada e desligada, e a ativação exige o aceite específico de Arthur) |
| Fases futuras; não paralisa o gameplay | D1 seção 2, item 5 ("o visual perfeito não atrasa o roadmap funcional"; sem D2 extensa); DIR seções 6 e 7 (uma fatia por vez, em paralelo ao roadmap funcional; nada visível entra sem o aceite dele) |
| Licenças e custo zero | `MANIFESTO_LICENCAS.md` seção 1 (política); DEC-021 |
| Como se prova | BRIEF seção 6 (decide o olhar de Arthur; métrica não substitui); `CAPTURA_DO_JOGO.md` (`tools/visual/run_game_capture`: capturas em 3 câmeras, com janela e a autorização dele) e `tools/visual/run_renderer_test` (cena isolada) |

**Onde a produção visual está agendada:** o `DEVELOPMENT_ROADMAP.md` (protegido) não tem tarefas ART-*: trata a arte final como fora do protótipo (linha 193) e os placeholders como decisão de escopo (linha 1567). A produção corre pela "Trilha de arte" de `docs/operacao/FILA.md` (Frente C, só apresentação, por contrato e aceite de Arthur): ART-12 (personagens animados e Ice Warrior) em execução; ART-6b e ART-7 (caminhos, mistura de terreno e adereços de povoado) em espera pela paleta e pelas regras de forma; ART-10 (carrinho, com a LW-099) e, em fases futuras, ART-11, ART-13 e ART-14 (só nomeadas ali; conteúdo a confirmar).

## 3. Lacunas relevantes (só o que o aprovado NÃO cobre; cada uma é decisão futura, sem ação agora)
1. **Variedade de corpos e silhuetas por tipo de NPC** (ferreiro, soldado, comerciante, aventureiro, habitante) com a qualidade do Ice Warrior: kit, base própria ou híbrido? O contrato atual cobre UM Ice Warrior e adia a variedade (`presentation.md`, figura inteira; DIR seção 10); a base Quaternius segue provisória (DIR seção 10) e o pacote modular avaliado em privado está sem licença esclarecida.
2. **Linguagem por tipo de estabelecimento** (ferraria, taverna, oficina, moinho, padaria): só o mercado tem composição (GUIA seções 8 e 12); os demais locais são caixas por tipo (`PlacePalette`: casa, trabalho, descanso, convívio e mercado), embora a economia já separe o ofício de cada local (`data/economy/production_sites.json`: `forge_tool`, `bake_bread`) e o GDD proponha taverna, templo, forja e oficina (seções 9.3 e 13.2).
3. **Classes de material** (madeira, pedra, metal, tecido): como cada uma se distingue dentro do limite de poucos materiais; hoje há só "rugosidade de 0,7 a 0,95", "metal só em detalhes" e "cor por bloco" (GUIA seção 5; BRIEF 4.5, "um material por personagem, se possível").
4. **Iluminação por ambiente** (forja, taverna, mercado, floresta, noite), além das três predefinições do ciclo do dia: a regra de acento luminoso é ponta solta da D1 (seção 5) e o limite de 8 luzes por malha, com margem de 1 (`COMPARACAO_RENDERERS.md`), pesa nas luzes locais; não achei decisão sobre interiores de construções (a confirmar).
5. **Coerência do conjunto personagem, objeto e cenário:** convivem três acabamentos (cenário procedural facetado com cor por vértice, DIR seção 5; Ice Warrior com normais planas em cerca de 93% e paleta própria, `presentation.md`; Quaternius suave e provisório). Falta o critério de aceite do CONJUNTO com o Ice Warrior na praça de linguagem nova (a D1 usou o guarda facetado, não adotado) e a decisão sobre o aditivo ao contrato dos personagens (DIR seção 4; classe 3, com o aceite de Arthur).

## 4. O que NÃO fazer agora
- Nenhuma nova fase extensa de pesquisa artística, nenhuma remodelagem e nenhuma substituição de ativos (a substituição em massa segue suspensa: DIR seção 5; D1 seção 2); nenhuma D2 extensa.
- Não reescrever a DIR, o GUIA, o BRIEF nem a D1: seguem valendo. Nada visível entra no jogo sem o aceite visual e funcional de Arthur.
- Não baixar, comprar nem importar o pacote POLYGON (nem outro de terceiros) como ativo (custo zero e só CC0 no repositório: `MANIFESTO_LICENCAS.md` seção 1); a imagem, se vier, não vai ao repositório nem ao PR.
- Não paralisar o gameplay nem a economia por causa da arte; nenhuma DEC nova sem pedido expresso dele.

## 5. Licenças e originalidade
Só entra no repositório ativo CC0 com licença confirmada e registrada (`MANIFESTO_LICENCAS.md` seção 1: sem versões pagas, sem licença própria nem CC BY, sem assets de jogos comerciais; DEC-021 e DEC-280). O Ice Warrior (HaydzBooter) é CC BY 4.0: pede crédito e lista de alterações, e o original e a versão preparada ficam FORA do Git até um aceite separado (`presentation.md`); o manifesto ainda não tem a linha dele (a confirmar quando registrar).
