<!-- Cópia fiel do briefing original de Arthur (texto recebido em 01/11/2026). Não editar: mudanças de decisão entram em DECISIONS.md. -->

# BRIEFING MESTRE — PROJETO LIVING WORLD

Você será responsável por atuar como uma equipe multidisciplinar de desenvolvimento de jogos, reunindo competências de:

- Game Director;
- Game Designer;
- World Designer;
- Narrative Designer;
- Systems Designer;
- Game Economy Designer;
- AI Designer;
- Software Architect;
- Technical Game Designer.

Sua missão é transformar o conceito abaixo em uma documentação profissional de desenvolvimento de jogos, com profundidade suficiente para orientar uma equipe de programação assistida por IA.

## 1. VISÃO DO PROJETO

Living World é um RPG sandbox 3D de fantasia, com simulação dinâmica de sociedade, economia, política, organizações, conflitos militares e exploração.

O objetivo é construir um mundo virtual que funcione como um ecossistema independente do jogador.

O jogador não é necessariamente um escolhido, herói ou personagem central da história. É um indivíduo que nasce em um mundo já existente, com culturas, sociedades, interesses, conflitos, economias e acontecimentos próprios.

O mundo deve continuar evoluindo mesmo quando o jogador não interfere.

O jogador poderá construir sua própria trajetória, sem depender de uma campanha linear ou de classes rígidas.

## 2. CARACTERÍSTICAS CONFIRMADAS

- Plataforma inicial: PC.
- Experiência inicial: single-player.
- Possibilidade de multiplayer futuramente, sem obrigação de implementá-lo no protótipo.
- Engine inicialmente escolhida: Godot 4.x.
- Linguagem: GDScript tipado.
- Visual: stylized low-poly.
- Câmera: terceira pessoa combinada com visão tática e estratégica.
- Transição de câmera: seamless, com transições fluidas entre diferentes escalas de visualização.
- Universo: original, misturando fantasia, história, política e culturas realistas.
- Escopo: começar com um protótipo pequeno, expansível ao longo do tempo.
- Filosofia: equilíbrio entre simulação profunda e jogabilidade divertida.
- IA dos NPCs: arquitetura híbrida, combinando simulação tradicional, sistemas comportamentais, memória e possibilidade de IA generativa opcional.

## 3. PILARES DO MUNDO

### Mundo vivo
O mundo possui regiões, cidades, vilas, recursos, culturas, governos, organizações, conflitos e acontecimentos autônomos.

### Liberdade
O jogador pode escolher diferentes profissões, objetivos e estilos de vida, sem classes obrigatórias.

### Sociedade
NPCs devem possuir interesses, necessidades, ocupações, relações, objetivos e capacidade de tomar decisões.

### Economia
Produção, comércio, transporte, consumo, estoques, preços e escassez devem estar conectados.

### Política
Facções, governos, alianças, disputas, influência, intrigas, rebeliões e mudanças de poder devem produzir consequências.

### Guerra
Conflitos podem surgir por território, recursos, interesses políticos, rivalidades e oportunidades estratégicas.

### Consequências
As ações e omissões do jogador devem poder alterar personagens, organizações, economias, regiões e acontecimentos.

### Exploração
O mundo deve oferecer descoberta, mistérios, tesouros, ambientes perigosos, criaturas, magia e oportunidades.

## 4. LIBERDADE DE TRAJETÓRIA

O jogador poderá desenvolver diferentes trajetórias, incluindo:

- Militar e soldado;
- Mercador e comerciante;
- Artesão, ferreiro e construtor;
- Minerador e coletor de recursos;
- Fazendeiro e produtor;
- Alquimista;
- Explorador;
- Aventureiro;
- Ladrão ou integrante de organizações criminosas;
- Líder de facção;
- Governante;
- Diplomata;
- Estrategista e comandante militar.

Essas trajetórias não devem ser classes mutuamente exclusivas. O jogador poderá combinar atividades e mudar de objetivos ao longo da experiência.

## 5. SOCIEDADES E ORGANIZAÇÕES

O jogador poderá:

- Integrar facções existentes;
- Construir reputação e influência;
- Ascender hierarquicamente;
- Assumir posições de liderança;
- Fundar organizações;
- Formar alianças;
- Conquistar territórios;
- Participar de guerras;
- Financiar organizações;
- Construir negócios e redes comerciais.

As organizações também devem possuir recursos, objetivos, hierarquia, relações, interesses e capacidade de agir sem intervenção do jogador.

## 6. ECONOMIA FUNCIONAL

A economia deve representar relações entre produção, distribuição e consumo.

Exemplos:

- Agricultores produzem alimentos;
- Mineradores extraem recursos;
- Ferreiros fabricam ferramentas e armas;
- Comerciantes compram e vendem mercadorias;
- Transportadores movimentam produtos;
- Populações consomem bens;
- Guerras interrompem rotas comerciais;
- Escassez afeta preços e estabilidade;
- Organizações dependem de recursos e financiamento.

As relações econômicas precisam produzir efeitos observáveis no mundo.

## 7. NPCs E INTELIGÊNCIA

NPCs não devem ser simples personagens parados esperando o jogador.

Devem possuir diferentes níveis de complexidade, com:

- Necessidades;
- Ocupações;
- Rotinas;
- Relações;
- Objetivos;
- Personalidades;
- Memória;
- Recursos;
- Decisões;
- Reações aos acontecimentos.

A IA deve ser híbrida. Simulação determinística e sistemas comportamentais serão a base. IA generativa será opcional, utilizada somente quando agregar valor e sem ser necessária para o funcionamento do jogo.

## 8. COMBATE E AVENTURA

O jogo poderá incluir:

- Combate físico;
- Armas variadas;
- Magia;
- Furtividade;
- Criaturas e monstros;
- Chefes;
- Exploração de ruínas;
- Tesouros;
- Invasões;
- Cercos;
- Batalhas de diferentes escalas;
- Domesticação de criaturas, caso seja viável no design.

O combate deve ser interessante e integrado ao mundo, não uma atividade isolada.

## 9. DIRETRIZES DE DESIGN

Evite:

- Progressão artificial;
- Grind excessivo;
- Repetição sem propósito;
- NPCs decorativos;
- Sistemas que não se comunicam;
- Economia meramente cosmética;
- Liberdade prometida, mas limitada por trilhos;
- Complexidade que prejudique a jogabilidade;
- Sistemas caros ou inviáveis para um desenvolvedor solo assistido por IA.

Busque:

- Sistemas conectados;
- Consequências emergentes;
- Jogabilidade intuitiva;
- Profundidade progressiva;
- Modularidade;
- Escalabilidade;
- Eficiência computacional;
- Possibilidade de expansão.

## 10. PRINCÍPIO FUNDAMENTAL

O mundo não deve existir somente para servir ao jogador.

O jogador é parte do mundo, não o centro obrigatório dele.

Toda mecânica relevante deve responder:

1. O que acontece quando o jogador participa?
2. O que acontece quando o jogador não participa?
3. Como NPCs e organizações reagem?
4. Quais sistemas são afetados?
5. Quais consequências podem surgir?
6. Como o mundo registra e mantém essas consequências?

## 11. SUA RESPONSABILIDADE

Não invente decisões e apresente-as como se já tivessem sido aprovadas.

Diferencie sempre:

- Decisão confirmada;
- Proposta de design;
- Hipótese;
- Questão pendente;
- Limitação técnica.

Se identificar contradições, apresente-as.

Se uma ideia for tecnicamente inviável ou excessivamente cara, explique e proponha alternativas.

A documentação deverá ser suficientemente detalhada para orientar outra IA responsável pela programação do jogo.

Não tente desenvolver o código. Seu trabalho é produzir a documentação de design, arquitetura e planejamento.