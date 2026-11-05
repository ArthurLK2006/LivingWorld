# LIVING WORLD — GAME DESIGN DOCUMENT (GDD)

**Versão do documento:** 0.3 (rascunho de design para orientar implementação; atualizado em 01/11/2026 após a revisão final e as diretrizes de Arthur, ver `docs/CONSISTENCY_REPORT.md`)
**Registro de alterações (a versão do documento não mudou):** 05/11/2026 (horário de Brasília), LW-033A: seções 16.2, 16.9, 21.1 e 21.4 atualizadas com as DEC-115, DEC-116 e DEC-117, aprovadas por Arthur.
**Status das decisões:** o registro oficial é `DECISIONS.md`. Os rótulos deste documento não substituem o status lá registrado.
**Título:** "Living World" é o **título de trabalho** do projeto, não um nome comercial definido.
**Escopo deste documento:** design, arquitetura de alto nível e planejamento. Não contém código.
**Público-alvo do documento:** o desenvolvedor solo e a IA responsável pela programação.

---

## 0. COMO LER ESTE DOCUMENTO

### 0.1 Rótulos de status

Cada afirmação relevante carrega, de forma explícita ou pelo contexto da seção, um destes status:

| Rótulo | Significado |
|---|---|
| **[CONF]** | Decisão confirmada pelo briefing mestre e registrada como **APROVADA** em `DECISIONS.md`. O rótulo sozinho não prova aprovação. Não deve ser alterada sem aprovação. Em capítulos marcados **[CONF/PROP]**, só o princípio é [CONF]; o resto é proposta. |
| **[PROP]** | Proposta de design. Sugestão do documento, aberta a aprovação ou rejeição. |
| **[HIP]** | Hipótese. Precisa ser validada por protótipo, medição ou teste de jogo. |
| **[PEND]** | Questão pendente. Exige decisão do desenvolvedor antes de implementar. |
| **[LIM]** | Limitação técnica ou de escopo conhecida. |

### 0.2 Rótulos de fase

| Rótulo | Significado |
|---|---|
| **[LP]** | Visão de longo prazo. Direção do jogo, sem compromisso de entrega. |
| **[PREV]** | Sistema previsto. Será construído depois do protótipo, e a arquitetura deve deixar espaço para ele. |
| **[P1]** | Sistema do primeiro protótipo. |
| **[FUT]** | Funcionalidade futura. Pode ser adiada ou descartada sem comprometer o jogo. |

Nada marcado como [LP], [PREV] ou [FUT] é requisito do protótipo.

### 0.3 Escalas de complexidade e prioridade

- **Complexidade:** Baixa, Média, Alta, Muito alta. Considera esforço de design, programação e ajuste fino por um desenvolvedor solo assistido por IA.
- **Prioridade:**
  - **P0:** sem isso o protótipo não prova a premissa.
  - **P1:** necessário para o protótipo ficar jogável e coerente.
  - **P2:** desejável no protótipo se houver tempo.
  - **P3:** depois do protótipo.

### 0.4 Estrutura padrão de cada sistema

Cada sistema importante é descrito com estes campos: **Objetivo; Funcionamento; Dados; Relações; Interações do jogador; Comportamento autônomo; Consequências; Complexidade e prioridade.** Quando o sistema atravessa fases, indica-se também o que entra no protótipo e o que fica para depois.

### 0.5 Nomes

Este documento **não define nomes definitivos** de raças, culturas, regiões, religiões ou personagens. Onde um exemplo exige nome, usa-se identificador genérico (ex.: "Cidade A", "Facção Mercantil", "Região Montanhosa"). Qualquer nome próprio sugerido é **[PROP]** e provisório.

### 0.6 Sumário

1. Visão geral e identidade do jogo
2. Fantasia central e experiência pretendida
3. Pilares fundamentais de design
4. Universo, geografia e estrutura do mundo
5. Regiões, culturas, sociedades e civilizações
6. Personagem do jogador e progressão
7. Liberdade de profissões e trajetórias
8. NPCs, personalidades, necessidades e relações
9. Rotinas, autonomia e comportamento dos NPCs
10. Facções, organizações e hierarquias
11. Política, diplomacia, influência e governança
12. Economia, produção, comércio e distribuição
13. Recursos, profissões e atividades produtivas
14. Sistema militar, exércitos e hierarquias
15. Guerras, conflitos, cercos e batalhas
16. Combate, equipamentos, armas e magia
17. Exploração, aventuras, criaturas e descobertas
18. Construção, propriedades e expansão territorial
19. Sistema de eventos e acontecimentos dinâmicos
20. Consequências das ações e omissões do jogador
21. Interface, experiência do usuário e câmera
22. Progressão e equilíbrio entre simulação e diversão
23. Experiência single-player e possibilidades futuras de multiplayer
24. Escopo do protótipo inicial
25. Critérios de qualidade e sucesso

Anexos: A) Matriz de sistemas; B) Dependências entre sistemas; C) Contradições e riscos; D) Questões pendentes; E) Glossário.

---

# 1. VISÃO GERAL E IDENTIDADE DO JOGO

## 1.1 Resumo em uma frase

Um RPG sandbox 3D de fantasia em que o mundo é um ecossistema de sociedades, economias, facções e conflitos que continua evoluindo com ou sem o jogador, e o jogador é um habitante entre outros, não o centro obrigatório da história. **[CONF]**

## 1.2 Ficha do jogo

| Item | Definição | Status |
|---|---|---|
| Gênero | RPG sandbox de simulação de mundo, fantasia | [CONF] |
| Plataforma inicial | PC | [CONF] |
| Modo | Single-player | [CONF] |
| Multiplayer | Possibilidade futura, não obrigatória no protótipo | [CONF] |
| Engine | Godot 4.x | [CONF] |
| Linguagem | GDScript tipado | [CONF] |
| Visual | Stylized low-poly | [CONF] |
| Câmera | Terceira pessoa combinada com visão tática e estratégica, transição contínua entre escalas | [CONF] |
| Universo | Original, mistura de fantasia, história, política e culturas realistas | [CONF] |
| Escopo | Protótipo pequeno, expansível | [CONF] |
| IA de NPCs | Híbrida: simulação determinística e sistemas comportamentais como base; IA generativa opcional | [CONF] |
| Narrativa | Emergente, sem campanha linear nem herói escolhido | [CONF] |
| Classes | Inexistentes; trajetórias combináveis | [CONF] |

## 1.3 Identidade do jogo

O que torna Living World diferente de um RPG de mundo aberto convencional:

1. **O mundo tem agenda própria.** Preços, guerras, colheitas e rivalidades andam sem esperar o jogador.
2. **Os sistemas se comunicam.** Economia afeta política, política afeta guerra, guerra afeta economia. Nenhum sistema é decoração.
3. **Não existe trilho.** Oportunidades surgem das necessidades do mundo, não de uma lista de missões desenhada em torno do jogador.
4. **As consequências persistem.** O que acontece fica registrado e altera o futuro.
5. **O jogador pode ser pequeno ou grande.** Pode viver como camponês anônimo ou tornar-se governante, e ambas as vidas devem ser válidas.

## 1.4 Público-alvo **[HIP]**

Jogadores que apreciam jogos de simulação emergente e sandbox de mundo (onde histórias surgem da interação de sistemas), de estratégia com camada de RPG e de exploração de baixa pressão. Esta é uma hipótese de posicionamento a validar com playtests. Não é pesquisa de mercado.

## 1.5 O que o jogo não é

- Não é uma campanha linear com mundo aberto de fundo.
- Não é um simulador de estratégia em que o jogador só vê o mapa. A terceira pessoa é central.
- Não é um simulador acadêmico de economia ou sociedade. A simulação existe para gerar situações interessantes, e a fidelidade total é um objetivo secundário.
- Não é um MMO nem exige conexão.

## 1.6 Referências de comparação **[PROP]**

Para alinhar vocabulário (não para copiar), podem ser úteis como pontos de comparação jogos de sandbox de simulação com mundos autônomos, RPGs de ação com facções e economias vivas, e jogos de estratégia com camada de personagem. A escolha das referências e a análise delas ficam como tarefa de pré-produção.

---

# 2. FANTASIA CENTRAL E EXPERIÊNCIA PRETENDIDA

## 2.1 A fantasia central **[CONF/PROP]**

> "Eu vivo em um mundo que existe de verdade. Posso escolher quem ser nele, e o que faço importa, mas o mundo não gira em torno de mim."

Isso se desdobra em três sensações que o jogo deve provocar:

1. **Pertencimento:** sou parte de uma sociedade com vizinhos, rivais, dívidas e reputação.
2. **Agência:** posso mudar a trajetória de pessoas, lugares e organizações, e vejo isso refletido.
3. **Descoberta:** ao voltar a um lugar, algo mudou sem que eu fizesse nada, e posso investigar por quê.

## 2.2 Ciclos de experiência **[PROP]**

| Escala | Duração aproximada **[HIP]** | O que o jogador faz | Satisfação-alvo |
|---|---|---|---|
| Momento | Segundos a minutos | Combate, negociação, coleta, exploração de um local | Ação responsiva e legível |
| Atividade | 10 a 30 min | Uma viagem comercial, uma expedição, um turno de ofício, uma escaramuça | Pequeno ciclo de risco, ação e recompensa |
| Sessão | 1 a 3 h | Cumprir um objetivo pessoal, reagir a um evento do mundo | Sensação de progresso e de mundo se movendo |
| Trajetória | Dezenas de horas | Construir posição social, riqueza, influência, organização | Narrativa pessoal emergente |
| Mundo | Centenas de horas **[LP]** | Ver reinos mudarem, guerras terminarem, gerações passarem | Sensação de história |

## 2.3 Exemplos de experiência pretendida

- **Ritmo calmo:** o jogador planta, colhe e vende no mercado local. Percebe que o preço do grão sobe depois de uma seca em outra região e decide estocar.
- **Ritmo tenso:** uma caravana que ele tentava acompanhar é emboscada. Ele pode intervir, fugir ou observar de longe, e cada escolha tem consequência.
- **Ritmo ambicioso:** o jogador se aproxima de uma facção, sobe de posto e passa a influenciar decisões que afetam centenas de NPCs.

## 2.4 Emoções-alvo e anti-emoções

**Buscar:** curiosidade, autonomia, ambição, tensão estratégica, admiração pela escala do mundo, senso de responsabilidade.
**Evitar:** tédio por repetição, frustração por perda inexplicável, sensação de ser irrelevante sem possibilidade de agir, paralisia por excesso de informação.

## 2.5 Tensão central a gerenciar **[LIM]**

"Mundo independente do jogador" e "jogo divertido" puxam em direções diferentes. Um mundo indiferente pode ser frustrante se o jogador sentir que nada que faz importa, ou que o mundo é caótico demais para ser lido. A solução de design está distribuída nos capítulos 19, 20 e 22: o mundo é autônomo, mas **legível**, com informação disponível ao jogador, causas rastreáveis e pontos de entrada para agir.

---

# 3. PILARES FUNDAMENTAIS DE DESIGN

Os oito pilares do briefing são **[CONF]**. Ao lado de cada um estão o critério de verificação **[PROP]** e uma consequência prática.

| # | Pilar | Significado operacional | Critério de verificação |
|---|---|---|---|
| 1 | Mundo vivo | Regiões, cidades, recursos, governos e conflitos mudam sem o jogador | Rodar a simulação sem jogador por N dias de jogo e observar mudanças significativas e registradas |
| 2 | Liberdade | Profissões e objetivos escolhidos, sem classes obrigatórias | Pelo menos 3 trajetórias distintas viáveis no protótipo e combináveis |
| 3 | Sociedade | NPCs com necessidades, ocupações, relações e decisões | NPCs relevantes mantêm rotinas e reagem a eventos sem script |
| 4 | Economia | Produção, comércio, transporte, consumo, estoque e preço conectados | Interromper uma rota produz escassez e variação de preço observáveis |
| 5 | Política | Facções, governos e alianças produzem consequências | Mudança de lei ou de poder altera comportamento de NPCs e economia |
| 6 | Guerra | Conflitos nascem de causas simuladas | Toda guerra tem causa rastreável nos dados |
| 7 | Consequências | Ações e omissões alteram o mundo de forma persistente | Ação do jogador deixa registro e efeito detectável horas depois |
| 8 | Exploração | Descoberta, mistérios, perigo, magia, oportunidade | Locais não visitados oferecem recompensas e riscos distintos |

## 3.1 Pilares auxiliares **[PROP]**

Dois princípios que o briefing implica e que merecem status próprio:

- **Legibilidade:** o jogador deve poder perguntar "por que isso aconteceu?" e obter resposta. Sem legibilidade, simulação profunda vira ruído.
- **Profundidade progressiva:** o jogo se joga bem no primeiro nível de complexidade, e as camadas políticas e estratégicas se revelam à medida que o jogador as busca.

## 3.2 Portão de design (as seis perguntas) **[CONF]**

Toda mecânica relevante deve responder, por escrito, antes de ser implementada:

1. O que acontece quando o jogador participa?
2. O que acontece quando o jogador não participa?
3. Como NPCs e organizações reagem?
4. Quais sistemas são afetados?
5. Quais consequências podem surgir?
6. Como o mundo registra e mantém essas consequências?

Este documento aplica o portão em cada sistema por meio dos campos "Interações do jogador", "Comportamento autônomo" e "Consequências".

## 3.3 Regras de precedência quando pilares conflitam **[PROP]**

1. Jogabilidade vence fidelidade de simulação, a menos que a simplificação quebre a causalidade (pilar de sistemas conectados).
2. Legibilidade vence profundidade, a menos que a profundidade seja opcional e oculta.
3. Viabilidade para desenvolvedor solo vence abrangência. É melhor um sistema pequeno e conectado que três grandes e isolados.
4. Determinismo e testabilidade vencem variedade em sistemas da simulação de base.

## 3.4 Anti-pilares **[CONF]**

Não fazer: progressão artificial; grind excessivo; repetição sem propósito; NPCs decorativos; sistemas isolados; economia cosmética; liberdade com trilhos; complexidade que prejudica a jogabilidade; sistemas inviáveis para um desenvolvedor solo assistido por IA.

---

# 4. UNIVERSO, GEOGRAFIA E ESTRUTURA DO MUNDO

## 4.1 Natureza do universo

- Universo **original** **[CONF]**, de fantasia com raízes históricas e culturas realistas **[CONF]**.
- **Nível tecnológico [PROP]:** pré-industrial, aproximadamente comparável a uma Idade Média/Antiguidade tardia em abstrato. Ferro, tração animal, vela, arco, besta e fortificação de pedra. Sem pólvora no protótipo. Pólvora é **[PEND]** como questão de longo prazo.
- **Fantasia [PROP]:** magia presente, porém rara, custosa e socialmente consequente (ver cap. 16). Criaturas e ruínas de eras anteriores são a maior fonte de fantasia explícita.
- **Cosmologia, deuses e história profunda: [PEND]**. O documento recomenda decidir apenas o necessário para dar coerência às culturas e às ruínas do protótipo, e adiar o resto.

## 4.2 Hierarquia espacial do mundo **[PROP]**

| Nível | Nome genérico | Descrição | Papel na simulação |
|---|---|---|---|
| 0 | Mundo | Conjunto de todos os continentes | Contexto narrativo, sem simulação própria no protótipo |
| 1 | Continente/Macrorregião | Grande massa com várias nações | [LP] Relações de longo alcance |
| 2 | Região | Território de clima e cultura relativamente homogêneos | Unidade de simulação agregada |
| 3 | Província/Célula | Subdivisão de uma região, base do mapa estratégico | Unidade de dados (recursos, população, controle) |
| 4 | Assentamento | Cidade, vila, forte, acampamento | Unidade de mercado, política local e população |
| 5 | Ponto de interesse | Ruína, caverna, ninho, mina, acampamento | Unidade de exploração e de eventos locais |

**Prototipagem:** o protótipo cobre **uma região** com cerca de 12 a 30 províncias **[HIP]**, o suficiente para rotas, fronteiras e escassez, e pequeno o bastante para ser simulado e construído.

## 4.3 Geografia e biomas **[PROP]**

A geografia no protótipo deve ser **desenhada à mão** (autoria controlada), com variação procedural limitada ao detalhe local (vegetação, pequenos objetos, conteúdo de ruínas). Motivo: sem geografia coerente, rotas, escassez e fronteiras não produzem situações interessantes, e geração procedural total custa muito ajuste fino.

Elementos mínimos para dar sentido à economia e à política:

- **Variedade de biomas** no protótipo: planície agrícola, floresta, terreno montanhoso, uma zona hostil ou selvagem.
- **Recursos distribuídos de forma desigual:** nenhuma região é autossuficiente, para criar motivo de comércio.
- **Rotas:** estradas, trilhas e possivelmente um rio. Cada rota tem distância, risco e capacidade.
- **Gargalos:** passagens estreitas, pontes e travessias, que são alvos naturais de conflito e de cobrança de pedágio.
- **Fronteiras políticas** que não coincidem exatamente com fronteiras naturais, para produzir disputas.

## 4.4 Tempo do mundo **[PROP]**

- Calendário simples: dia, estação, ano. Quatro estações influenciam produção agrícola, viagem e eventos. **[Nota v0.2]** No protótipo do roadmap, clima e estações ficam **fora** (DEC-060, PROPOSTA); o calendário usa dia e ano. Estações e clima permanecem como design de longo prazo.
- **Escala de tempo [HIP]:** um dia de jogo em torno de 20 a 40 minutos reais. A calibragem exata depende do ritmo desejado.
- **Controle de tempo do jogador:** pausa, velocidade normal e acelerada. Em tempo acelerado, a simulação mantém coerência, mas combate e interações detalhadas ficam bloqueados.
- **Passo de simulação:** os sistemas econômicos e políticos rodam em passos discretos, independentes da taxa de quadros. Exemplo ilustrativo **[HIP]**: economia por dia de jogo, política por dia ou semana, rotina de NPC por intervalos de minutos de jogo.

## 4.5 Simulação em níveis de detalhe (LOD de simulação) **[PROP, base da arquitetura]**

Esta é a decisão arquitetural que torna o "mundo vivo" viável para um desenvolvedor solo. Em vez de simular tudo em máximo detalhe, o mundo é simulado em camadas:

| Nível | Onde | O que é simulado | Custo |
|---|---|---|---|
| S0 | Em torno do jogador (raio de dezenas a centenas de metros **[HIP]**) | Agentes individuais com movimento, animação, percepção e combate | Alto |
| S1 | Assentamentos e rotas ativas ao alcance | Agentes em modo de rotina simplificada (posição discreta, atividade atual), caravanas como entidades | Médio |
| S2 | Resto da região | Grupos estatísticos, estoques e fluxos agregados; indivíduos notáveis (Tier 2 e 3) continuam com estado completo, mas sem movimento físico | Baixo |
| S3 | Fora da região | [LP] Variáveis abstratas (relações, preços de referência, eventos externos) | Muito baixo |

**Regras de consistência:**
- A transição entre níveis deve **preservar o estado importante**. Um NPC que sai de S0 para S1 não "esquece" o que fazia. Uma caravana que passa de S2 para S0 aparece em posição coerente com sua rota e velocidade.
- A simulação agregada e a detalhada devem produzir **resultados estatisticamente compatíveis** (a produção de uma fazenda em S2 equivale à soma do que os agricultores produziriam em S1).
- **Teste obrigatório:** comparar execuções do mesmo cenário com um trecho em S1 e em S2, verificando se os resultados convergem **[PROP]**.

**[LIM]** Esse é o ponto de maior risco técnico do projeto. Ver Anexo C.

**Nota v0.3 (nomes e escopo).** Os níveis de simulação são **S0 a S3**; os protótipos técnicos da arquitetura chamam-se **SP1 a SP8** (spikes), para não haver confusão. No primeiro protótipo existem **apenas S0 e S1** (DEC-041): o nível agregado (S2 e S3) e o tier T0 ficam como primeira expansão.

## 4.6 Relação com a câmera **[PROP]**

A câmera contínua (cap. 21) alterna a **apresentação**, não a simulação. A simulação decide o nível de detalhe com base na distância ao jogador e, em certos casos, em eventos relevantes (uma batalha em andamento fora do raio S0 pode ser simulada em S1 para poder ser observada pelo mapa tático).

## 4.7 Sistema do mundo (geografia): estrutura de dados e papéis

**Objetivo.** Fornecer o espaço, os recursos e as rotas sobre os quais toda a simulação opera.

**Funcionamento.** O mundo é um conjunto de províncias conectadas por rotas. Cada província possui terreno, bioma, recursos, população e controle político. Assentamentos e pontos de interesse existem dentro de províncias. Um terreno 3D jogável é gerado a partir da mesma estrutura.

**Dados envolvidos.** Província (id, bioma, vizinhas, recursos, fertilidade, risco, dono), Rota (extremos, distância, tipo, estado, risco), Assentamento (população por grupo, mercado, governo, estruturas), Ponto de interesse (tipo, estado, conteúdo, perigo).

**Relação com outros sistemas.** Base de economia (recursos, rotas), política (fronteiras), militar (terreno e logística), exploração (pontos de interesse), eventos (clima e desastres localizados).

**Interações do jogador.** Percorrer, mapear, descobrir recursos e rotas, modificar a paisagem por meio de construção (limitado), bloquear ou proteger rotas.

**Comportamento autônomo.** Estações alteram produtividade e viagem. Recursos se esgotam ou regeneram. Rotas ficam intransitáveis (cheia, nevasca, banditismo, guerra) e retornam ao normal.

**Consequências.** A perda de uma rota altera abastecimento, preços e relações políticas. A descoberta de um recurso novo altera o valor estratégico de uma província.

**Complexidade e prioridade.** Complexidade Média (dados) a Alta (terreno 3D, streaming). Prioridade **P0**. **[P1]** uma região autoral. **[PREV]** mais regiões e geração assistida. **[LP]** múltiplos continentes.

---

# 5. REGIÕES, CULTURAS, SOCIEDADES E CIVILIZAÇÕES

## 5.1 Abordagem: cultura como pacote de parâmetros **[PROP]**

Em vez de fixar nomes e lore agora, cada cultura é definida por um **conjunto de parâmetros** que a simulação consegue ler. A lore (nomes, mitos, aparência) é uma camada de apresentação aplicada depois.

**Parâmetros culturais sugeridos:**

| Parâmetro | Efeito na simulação |
|---|---|
| Valores (tradição × comércio, honra × pragmatismo, coletivo × indivíduo) | Pesos de decisão de NPCs e facções |
| Atitude diante de estrangeiros | Relações iniciais e comércio |
| Atitude diante de magia | Aceitação social, leis, perseguição |
| Doutrina militar | Composição e comportamento de exércitos |
| Estrutura de poder preferida | Tipo de governo e sucessão |
| Dieta e bens preferidos | Demanda de consumo |
| Estilo arquitetônico e de equipamento | Aparência (modelos low-poly) e estatísticas leves |
| Tabus e crimes culturais | Definição de delito e de reputação |
| Religião predominante (abstrata) | Legitimidade, festivais, conflitos |

## 5.2 Povos e espécies **[PEND]**

O briefing fala de "culturas realistas" e fantasia, mas **não decide** se existem espécies não humanas. As opções:

| Opção | Prós | Contras |
|---|---|---|
| A) Apenas humanos no protótipo, com várias culturas | Escopo menor, foco em simulação | Menos "fantasia" imediata |
| B) Humanos e uma ou duas espécies | Mais identidade fantástica | Mais modelos, regras, balanceamento |
| C) Muitas espécies | Visual rico | Escopo incompatível com solo dev no protótipo |

**Recomendação:** opção **A** no protótipo, com a fantasia vindo de criaturas, ruínas e magia. A arquitetura de cultura deve suportar espécies como parâmetro adicional no futuro **[PREV/FUT]**.

## 5.3 Tipologia de sociedades e governos **[PROP]**

Arquétipos genéricos (sem nome), a serem instanciados conforme a geografia:

- Cidade-estado comercial.
- Reino agrário feudal.
- Confederação tribal ou clânica.
- Teocracia ou ordem religiosa territorial.
- Domínio militarizado de fronteira.
- Liga mercantil.
- Nômades de planície **[FUT]**.

**Prototipagem:** **duas culturas contrastantes** na mesma região **[PROP]**. Por exemplo, uma agrária e hierárquica e outra mercantil e urbana, para que haja fricção natural (preços de grão contra bens manufaturados, leis diferentes, sentimentos de superioridade). Os nomes e a aparência ficam como tarefa criativa pendente.

## 5.4 Sistema de culturas e sociedades

**Objetivo.** Dar a cada grupo de NPCs e a cada polity uma identidade que influencia decisões, economia e relações.

**Funcionamento.** Cada NPC, assentamento e facção referencia uma cultura. A cultura contribui com pesos nos cálculos de decisão (ex.: probabilidade de aceitar um estrangeiro como parceiro de negócio, preferência por certas leis, nível de tolerância a certos crimes). Culturas se afetam lentamente por contato (comércio, conquista, casamento) **[FUT]**.

**Dados envolvidos.** Cultura (parâmetros acima), matriz de afinidade entre culturas, listas de bens preferidos, leis típicas, rótulos de crime e honra.

**Relação com outros sistemas.** Personalidade e valores de NPCs, economia (demanda), política (legitimidade), guerra (doutrina), combate (equipamento), UI (nomes e apresentação).

**Interações do jogador.** Respeitar ou violar costumes locais, aprender a cultura (afeta diálogo e reputação), mediar entre culturas, importar bens culturais.

**Comportamento autônomo.** Culturas diferentes reagem de forma diferente ao mesmo evento. Exemplo: uma fome em uma cultura coletivista provoca distribuição comunitária. Em uma individualista, provoca açambarcamento e mercado negro.

**Consequências.** Choques culturais viram conflitos comerciais ou políticos. Aculturação altera demanda.

**Complexidade e prioridade.** Média. Prioridade **P1**. **[P1]** duas culturas por parâmetros e matriz de afinidade. **[PREV]** contato cultural dinâmico. **[FUT]** espécies.

## 5.5 Religião e crença **[PROP]**

Tratada como **sistema de crenças com efeitos mecânicos** e não como lore definitiva: define festivais (eventos periódicos), legitimidade de governantes, tabus e instituições (uma organização religiosa é uma facção). O conteúdo teológico é **[PEND]**.

## 5.6 Exemplo emergente

> A Cultura Agrária tolera pouco comércio com estrangeiros. A Cultura Mercantil depende de importar grãos. Uma colheita ruim aumenta a dependência. A liga mercantil pressiona o reino por acesso, o reino aumenta tarifas por orgulho, o preço do pão sobe na cidade mercantil, surgem tumultos e um comerciante contrata o jogador para contrabandear grãos.

---

# 6. PERSONAGEM DO JOGADOR E PROGRESSÃO

## 6.1 Princípio **[CONF]**

O jogador **nasce em um mundo já existente**, sem ser escolhido ou central. Não há classe obrigatória nem campanha linear.

## 6.2 Criação do personagem **[PROP]**

Criação **curta**, em que as escolhas são sobretudo de **origem**, não de poder:

- **Origem social e local:** onde e em que família nasceu (campo, cidade, rota, fronteira). Define posses iniciais, relações iniciais e cultura natal.
- **Aparência:** limitada, compatível com o estilo low-poly.
- **Vantagens e desvantagens leves [HIP]:** inclinações iniciais, nunca barreiras.
- **Sem classes.** Habilidades iniciais refletem origem.

**Prototipagem:** **3 a 4 origens** pré-definidas e diferentes, para demonstrar a variedade de pontos de partida. A criação totalmente aberta fica para depois.

## 6.3 Anatomia do personagem

Para o jogador (e também NPCs de Tier 2/3, para reaproveitar sistemas):

| Camada | Conteúdo |
|---|---|
| Corpo | Vida, estamina, ferimentos, fadiga, fome e descanso (leves, ver 6.7) |
| Habilidades | Combate (armas, esquiva, defesa), ofícios (cultivo, mineração, forja, culinária, alquimia), sociais (persuasão, intimidação, comércio), sobrevivência (rastreamento, furtividade, navegação) |
| Atributos | Poucos e de apoio. Hipótese: 4 a 6 [HIP] |
| Conhecimento | Receitas, rotas, segredos, informações obtidas, idiomas/dialetos [FUT] |
| Patrimônio | Dinheiro, itens, propriedades, animais, contratos, dívidas |
| Capital social | Reputações por facção e assentamento, relações pessoais, cargos, títulos |

## 6.4 Progressão: quatro eixos **[PROP]**

O poder do jogador se expressa em quatro eixos independentes, evitando uma única barra de "nível":

1. **Habilidade:** melhora por uso e por instrução. Há retorno decrescente para impedir grind e incentivar diversidade. Mentores (NPCs) aceleram o aprendizado em troca de tempo, dinheiro ou favores.
2. **Equipamento e patrimônio:** itens melhores vêm de produção, comércio, descoberta ou aquisição. Têm manutenção (cap. 16 e 12).
3. **Posição social:** cargos, títulos, reputação, comando de pessoas. Dá poder de decisão sobre o mundo.
4. **Conhecimento:** informação sobre o mundo (rotas, preços, segredos, pessoas). Muitas vezes vale mais que ouro.

**Regra anti-grind [PROP]:** nenhuma atividade ofertada pelo jogo deve ser a melhor opção em todos os eixos ao mesmo tempo, e repetir uma ação de baixo risco deve render menos com o tempo (saturação de mercado, de oferta de treino, de conteúdo local).

## 6.5 Sem nível global **[PROP]**

Não existe "nível do personagem" que escala o mundo. O **mundo não escala** com o jogador. Áreas perigosas continuam perigosas, e o jogador deve ler o risco (avisos, rumores, aparência de inimigos) e decidir se arrisca. **[HIP]** Será necessário um bom sistema de **informação de perigo**, para não punir injustamente.

## 6.6 Morte, ferimentos e falha **[PEND]**

Decisão necessária, com impacto de design alto:

| Opção | Descrição | Efeito |
|---|---|---|
| A | Morte leva ao último salvamento | Simples, quebra imersão |
| B | Derrota raramente é fatal: captura, ferimento, perda de itens, dívida | Preserva trajetória e gera narrativa |
| C | Morte permanente com sucessor (herdeiro/parente) | Muito coerente com "mundo independente", exige sistema de família |

**Recomendação:** **B no protótipo** (captura, nocaute, ferimentos persistentes, prisão, dívida), com **C como [PREV/FUT]**. Mantém consequências sem perder progresso por acidente.

## 6.7 Necessidades do jogador **[PROP]**

Fome, descanso e saúde existem, mas **leves**, servindo para ancorar a economia (comida tem demanda real) sem transformar o jogo em simulação de sobrevivência exigente. Parâmetros ajustáveis por dificuldade.

## 6.8 Sistema de progressão do jogador

**Objetivo.** Dar sentido de crescimento sem trilhos nem nível global.

**Funcionamento.** Quatro eixos descritos acima; o jogo registra o histórico de ações para calcular reputação e oportunidades.

**Dados envolvidos.** Habilidades (valor, progresso), atributos, conhecimento (lista de itens de conhecimento obtidos), patrimônio, reputações (por entidade), relações, cargos, histórico de ações significativas.

**Relação com outros sistemas.** Tudo: economia (patrimônio), NPCs (relações), facções (cargos), combate (habilidades), exploração (conhecimento).

**Interações do jogador.** Treinar, estudar com mentores, trabalhar, empreender, cumprir contratos, ascender em organizações.

**Comportamento autônomo.** NPCs avaliam o jogador por reputação e histórico, oferecem ou retiram oportunidades. Mentores têm disponibilidade e agenda próprias.

**Consequências.** Reputação alta abre portas e fecha outras (ser querido por uma facção pode torná-lo suspeito para a rival). Dívidas e inimizades persistem.

**Complexidade e prioridade.** Média. Prioridade **P0**. **[P1]** habilidades por uso, 3 a 4 origens, reputação por facção e assentamento, aprendizado com mentor simples. **[PREV]** herdeiros, línguas, idade. **[FUT]** árvore social complexa.

---

# 7. LIBERDADE DE PROFISSÕES E TRAJETÓRIAS

## 7.1 Princípio **[CONF]**

Trajetórias não são classes mutuamente exclusivas. O jogador combina atividades e muda de rumo.

## 7.2 Modelo: atividades, não classes **[PROP]**

- **Atividade:** unidade básica do que o jogador pode fazer (cultivar, minerar, forjar, transportar mercadoria, patrulhar, caçar criatura, negociar, contrabandear, explorar ruína).
- **Ofício/Profissão:** conjunto de atividades relacionadas, com habilidades associadas e, às vezes, vínculos institucionais (guilda, licença).
- **Trajetória:** padrão emergente de atividades que o jogador pratica. Não é escolhida na criação e não bloqueia outras.

## 7.3 Mapa de trajetórias do briefing

| Trajetória | Atividades centrais | Fonte de renda | Risco | Conexão com o mundo | Fase |
|---|---|---|---|---|---|
| Fazendeiro/produtor | Cultivo, criação | Venda de alimento | Clima, saque | Alimenta a economia local | [P1] |
| Minerador/coletor | Extração, coleta | Venda de matéria-prima | Acidentes, esgotamento | Abastece ferreiros e construtores | [P1] |
| Artesão/ferreiro/construtor | Produção de itens, reparos | Venda e encomendas | Falta de insumo, concorrência | Equipa NPCs e exércitos | [P1] |
| Mercador | Arbitragem, transporte | Margem de preço | Roubo, rotas fechadas | Equilibra preços entre regiões | [P1] |
| Soldado/militar | Patrulha, combate | Soldo, saque | Ferimentos, guerra | Segurança e conflito | [P1] (simples) |
| Explorador/aventureiro | Exploração, caça | Tesouros, informação, contratos | Criaturas, hostilidade | Descoberta de recursos e ameaças | [P1] |
| Alquimista | Preparo de poções e compostos | Venda e encomendas | Insumos raros, perigo | Conecta recursos exóticos | [PREV] |
| Ladrão/crime organizado | Furto, contrabando, extorsão | Roubo, serviços ilícitos | Captura, retaliação | Lado sombrio da economia | [P1] (simples), [PREV] ampliar |
| Líder de facção | Recrutar, financiar, decidir | Contribuições, impostos | Traição, rivalidade | Atores políticos | [PREV] |
| Governante | Leis, tributação, defesa | Tributos | Rebelião, guerra | Moldam sociedades | [PREV] |
| Diplomata | Negociação, mediação | Comissões, favores | Reputação | Reduz ou cria guerras | [PREV] |
| Estrategista/comandante | Comandar tropas, planejar | Soldo, saque, glória | Derrota | Decide batalhas | [PREV] |

**Leitura v0.3 (DEC-062).** A tabela acima é a **visão** (e o teto de conteúdo). A **meta inicial do protótipo é de três trajetórias viáveis e combináveis**, adotadas provisoriamente: **mercador, soldado/guarda e aventureiro**; a confirmação final é da LW-146. A coluna "Fase" não é requisito. Crime existe como **consequência** (crime e justiça mínima), não como trajetória validada; produtor/artesão fica como possibilidade futura. Trajetória não é classe nem módulo de código: emerge das ações disponíveis.

## 7.4 Oportunidades emergem das necessidades do mundo **[PROP]**

Em vez de uma lista de missões, o mundo gera **demandas** reais: a guarnição precisa de armas, a cidade precisa de grãos, a rota está infestada de bandidos, o minerador precisa de escolta, a facção quer informação. Essas demandas são expostas ao jogador por **quadros de avisos, NPCs, rumores e contratos**. Se o jogador as ignora, o mundo tenta resolvê-las sozinho (ou falha).

**Contrato (estrutura genérica) [PROP]:** emissor, objetivo, recompensa, prazo, penalidade, requisitos, local, risco anunciado. NPCs também aceitam contratos uns dos outros.

## 7.5 Combinação e transição

Um jogador pode produzir ferro, vendê-lo, usar o lucro para equipar mercenários e comprar uma oficina. A transição entre trajetórias deve ser **suave**: habilidades de um ofício ajudam outro (ex.: mineração aumenta conhecimento de metais, ajudando no comércio de armas).

## 7.6 Sistema de profissões e atividades do jogador

**Objetivo.** Garantir liberdade real, com múltiplos caminhos viáveis e combináveis.

**Funcionamento.** Atividades definidas por dados (entradas, saídas, habilidade usada, tempo, risco, locais). Ofícios agrupam atividades e podem exigir licenças ou associação.

**Dados envolvidos.** Atividade (id, requisitos, insumos, produtos, habilidade, tempo, risco), Ofício (conjunto, licença), Contrato.

**Relação com outros sistemas.** Economia (insumos e produtos), facções (licenças, guildas), política (leis que restringem atividades), NPCs (competidores e clientes).

**Interações do jogador.** Executar atividades, aceitar e propor contratos, entrar em guilda, abrir negócio.

**Comportamento autônomo.** NPCs exercem as mesmas atividades pelas mesmas regras. O jogador compete e coopera com eles.

**Consequências.** Saturar um ofício reduz sua rentabilidade. Atividades ilegais acumulam procura pela lei. Falta de ofício gera oportunidade.

**Complexidade e prioridade.** Média. Prioridade **[P1]** (v0.3). **O primeiro protótipo não tem sistema genérico de atividades do jogador:** as ações do jogador são verbos definidos por fase (comprar, vender, transportar, servir em facção, explorar, combater) e as trajetórias emergem deles. O sistema descrito aqui é a visão, para quando a trajetória de produtor/artesão entrar.

## 7.7 Exemplo emergente

> Falta de ferramentas em uma vila após um incêndio na forja. O preço das ferramentas sobe, e o ferreiro NPC (o único) não consegue atender. O jogador, com minério e habilidade de forja, pode suprir o mercado, comprar a forja ou contratar o ferreiro. Se o jogador ignora, uma liga mercantil enviará uma caravana de ferramentas após alguns dias, a preço alto, e a vila perde recursos.

---

# 8. NPCs, PERSONALIDADES, NECESSIDADES E RELAÇÕES

## 8.1 Princípio **[CONF]**

NPCs possuem necessidades, ocupações, rotinas, relações, objetivos, personalidades, memória, recursos, decisões e reações.

## 8.2 Camadas de complexidade (tiers) **[PROP]**

Simular todos os NPCs no nível máximo é inviável **[LIM]**. Propõe-se uma hierarquia, vinculada aos níveis de simulação (cap. 4.5):

| Tier | Descrição | Estado guardado | Exemplo |
|---|---|---|---|
| T0 Massa | População agregada em grupos (ocupação, cultura, riqueza) | Contagens e médias | Camponeses de uma província |
| T1 Cidadão | Indivíduo simples com ocupação, casa, necessidades e relações básicas | Estado compacto | Padeiro, guarda raso |
| T2 Notável | Indivíduo com personalidade completa, memória, relações e objetivos | Estado completo | Dono de taverna, chefe de guilda local |
| T3 Líder | Notável com cargo de decisão em facção ou governo | Estado completo + planos | Governante, capitão, líder de organização |

**Nota v0.3 (DEC-041, aprovada):** o **T0 não existe no primeiro protótipo**; só T1, T2 e T3 individuais (cerca de 150 a 300 NPCs, **[HIP]**). O T0 fica como primeira expansão, e os exemplos de consumo agregado (como o do padeiro, cap. 9) descrevem a visão.

**Promoção e rebaixamento [PROP]:** um T1 vira T2 por interação com o jogador, evento marcante ou cargo. Um T2 sem relevância pode voltar a T1, com perda gradual de detalhe e preservação de relações-chave. O jogador pode "promover" um NPC ao interagir de forma significativa, e isso gera custo de simulação. É preciso limitar o número de T2/T3 simultâneos **[HIP: dezenas a poucas centenas no protótipo]**.

## 8.3 Necessidades **[PROP]**

Modelo simples e extensível, com pesos por personalidade:

| Grupo | Exemplos | Uso |
|---|---|---|
| Fisiológicas | Fome, sono, abrigo | Rotina e consumo econômico |
| Segurança | Proteção, estabilidade de renda | Decisão de migrar, enfileirar-se, fugir |
| Sociais | Companhia, pertencimento, status | Relações, facções, festas |
| Econômicas | Renda, propriedade | Escolha de ocupação, comércio |
| Realização | Ambição, honra, curiosidade | Objetivos de longo prazo |

Necessidades têm valor atual, urgência e preferências de satisfação (alimento específico, companhia específica).

## 8.4 Personalidade **[PROP]**

Conjunto pequeno de traços em espectro (exemplo ilustrativo **[HIP]**): ambição, cautela, sociabilidade, agressividade, honestidade, lealdade, curiosidade, ganância. Cada traço modifica pesos de decisão. Além disso, **valores** (ligados à cultura) e **temperamentos** de resposta a eventos (pânico, estoicismo). Poucos traços e bem testados valem mais que muitos.

## 8.5 Memória **[PROP]**

- **Memória episódica:** registros de eventos relevantes envolvendo o NPC (quem fez o quê, quando, qual impacto).
- **Atributos de cada registro:** tipo, atores, local, data, valência (positiva ou negativa), saliência (importância) e confiança.
- **Decaimento:** registros fracos desaparecem, fortes persistem e viram "traços de opinião" que afetam relações.
- **Compartilhamento:** NPCs trocam informações (rumores) com distorção e atraso, controlados por relações e distância. Isso alimenta o sistema de reputação (cap. 20).
- **Limite de memória** por NPC para proteger desempenho e tamanho de salvamento.

## 8.6 Relações **[PROP]**

Grafo de relações entre indivíduos, com dimensões numéricas: **afeição, confiança, respeito, medo, dívida** e rótulos (família, amigo, rival, empregador, mentor). Relações mudam por ações, tempo e boatos.

**Prototipagem:** relações para T2 e T3 e para relações com o jogador. T1 mantém poucos vínculos (casa, trabalho, grupo social).

## 8.7 Objetivos **[PROP]**

Objetivos de curto prazo (comer, trabalhar), médio (juntar dinheiro para uma oficina, casar) e longo (ascender na facção, vingar-se). Objetivos de médio e longo prazo existem apenas para T2/T3 no protótipo.

## 8.8 Diálogo e IA generativa **[CONF/PROP]**

- O jogo funciona **inteiramente sem IA generativa**. O diálogo base usa frases e intenções parametrizadas pelo estado do NPC (personalidade, relação, situação).
- **IA generativa é opcional [CONF]**, e o documento propõe usá-la apenas para **variação de linguagem** de falas e rumores, recebendo estado estruturado como entrada e retornando texto que **não altera o estado do mundo**. Qualquer mudança de estado passa por regras determinísticas. É **[FUT]**.

## 8.9 Sistema de NPCs

**Objetivo.** Povoar o mundo com indivíduos cuja vida pareça independente do jogador e cujas decisões alimentem os demais sistemas.

**Funcionamento.** Tiers, necessidades, personalidade, memória, relações, objetivos. A decisão de cada NPC é calculada a partir desses dados, por IA comportamental (cap. 9).

**Dados envolvidos.** Identidade, cultura, ocupação, casa, riqueza, necessidades, personalidade, relações, memórias, objetivos, tier, localização e atividade atual.

**Relação com outros sistemas.** Economia (consumo, produção, trabalho), política (apoio e rebelião), facções (membros), combate (participantes), eventos (reações), reputação (testemunhas e rumores).

**Interações do jogador.** Conversar, comerciar, contratar, ajudar, enganar, ameaçar, recrutar, romper relações. O jogador pode ser influenciado por NPCs (conselhos, pedidos, traições).

**Comportamento autônomo.** NPCs trabalham, comem, negociam, ficam doentes, fogem do perigo, protestam, migram, aceitam contratos, mudam de opinião.

**Consequências.** Mortes, mudanças de ocupação, migração, formação de grupos, lealdade ou traição alteram sistemas maiores.

**Complexidade e prioridade.** Alta. Prioridade **P0**. **[P1]** T1 e T2, necessidades, personalidade enxuta, memória limitada, relações básicas. **[PREV]** T3 com planos longos, famílias, demografia detalhada. **[FUT]** IA generativa de diálogo.

---

# 9. ROTINAS, AUTONOMIA E COMPORTAMENTO DOS NPCs

## 9.1 Princípio **[CONF]**

NPCs não ficam parados esperando o jogador. Combina-se simulação determinística, sistemas comportamentais, memória e, opcionalmente, IA generativa.

## 9.2 Arquitetura de decisão **[PROP]**

Três camadas combinadas:

1. **Rotina de ofício:** cada ocupação define um **modelo diário** (acordar, trabalhar em local X, comer, socializar, dormir). É a "base" que mantém o mundo funcionando com baixo custo.
2. **Decisão orientada por necessidades (utility-like):** quando uma necessidade fica urgente ou ocorre um estímulo (perigo, oportunidade), o NPC avalia ações possíveis por utilidade (benefício ponderado pela personalidade e pelo risco) e pode interromper a rotina.
3. **Planos de longo prazo (T2/T3):** objetivos de médio e longo prazo geram **sequências de ações** (juntar dinheiro, viajar, entrar em facção). Pode usar planejamento simples por etapas **[HIP]**.

**Regra de custo [PROP]:** decisões são **orientadas a eventos e a intervalos**, não a cada quadro. A rotina dá a maior parte do comportamento sem avaliar custo alto. O processamento pesado concentra-se nos poucos NPCs próximos ou relevantes.

## 9.3 Conceitos de rotina **[PROP]**

| Elemento | Descrição |
|---|---|
| Agenda | Blocos de tempo por ocupação, com variações por estação, dia da semana e festas |
| Locais | Casa, trabalho, mercado, taverna, templo, posto |
| Interrupções | Fome, perigo, convite, ordem de superior, evento do mundo |
| Reação | Fuga, defesa, ajuda, observação, indiferença (conforme personalidade) |
| Retomada | Retorno à rotina quando a interrupção termina |

## 9.4 Reações a eventos **[PROP]**

Cada evento do mundo (cap. 19) possui **alcance de percepção** (quem ouve, vê ou fica sabendo, e quando) e **tipo de resposta** por personalidade. Exemplo: um ataque à vila faz guardas combaterem, comerciantes fecharem lojas, camponeses fugirem, um curandeiro ajudar feridos.

## 9.5 Autonomia econômica

NPCs com ofício produzem e vendem. Desempregados procuram trabalho, migram ou recorrem ao crime. NPCs pobres consomem menos e adoecem mais. NPCs ricos investem (em prédios, mercadorias, mercenários) **[PREV]**.

## 9.6 Comportamento fora do alcance

Fora do alcance do jogador (S1/S2), a rotina é **abstrata**: o NPC "está" em uma atividade em um local, com evolução estatística da produção, consumo e relações. Ao entrar em S0, é posicionado de forma coerente com a atividade e o horário.

## 9.7 Falhas e modos de erro a evitar **[LIM]**

- NPCs "presos" em geometria ou em ciclos de decisão: deve haver **detector de impasse** e mecanismo de reinicialização para rotina.
- Todos agindo ao mesmo tempo (picos de custo): usar **escalonamento** das decisões.
- Comportamento incoerente após carregamento de save: o estado completo de rotina precisa ser salvo.
- NPCs "lendo a mente" do jogador ou reagindo a eventos que não perceberam: aplicar **percepção** com alcance e linha de visão simples.

## 9.8 Sistema de rotina e comportamento

**Objetivo.** Garantir que o mundo pareça habitado e funcione sem script.

**Funcionamento.** Rotina de ofício como base, utilidade para interrupções e planos longos para T2/T3. Percepção simples e propagação de informação.

**Dados envolvidos.** Agenda, estado atual (atividade, local, destino), necessidades, personalidade, percepção, plano atual, fila de interrupções.

**Relação com outros sistemas.** NPCs (cap. 8), economia (cap. 12), eventos (cap. 19), combate (cap. 16), construção (locais de trabalho), UI (indicadores de "o que ele está fazendo").

**Interações do jogador.** Observar rotinas, explorá-las (roubar quando o dono dorme, emboscar a caravana), influenciar (contratar, convocar, ameaçar), seguir NPCs.

**Comportamento autônomo.** Todo o ciclo diário e as reações descritas acima.

**Consequências.** Rotinas quebradas (guerra, praga, fechamento de rota) geram efeitos em cascata (desemprego, fome, crime).

**Complexidade e prioridade.** Alta. Prioridade **P0**. **[P1]** rotinas para 6 a 8 ocupações, interrupções por necessidade e perigo, percepção simples. **[PREV]** planos longos para T3, interações sociais ricas.

## 9.9 Exemplo emergente

> Um padeiro T1 depende de farinha. A rota do moinho é interrompida por bandidos. O estoque acaba, o padeiro para de produzir, a população de T0 consome menos pão, a fome aumenta e a satisfação cai. O padeiro procura outro fornecedor (decisão por utilidade), contrata o jogador como entregador (contrato) ou migra se o problema persiste.

---

# 10. FACÇÕES, ORGANIZAÇÕES E HIERARQUIAS

## 10.1 Princípio **[CONF]**

Organizações possuem recursos, objetivos, hierarquia, relações, interesses e capacidade de agir sem o jogador. O jogador pode integrá-las, ascender, liderar, fundar, financiar e aliar-se.

## 10.2 Tipos de organização **[PROP]**

| Tipo | Função principal | Fase |
|---|---|---|
| Governo local | Leis, tributos, ordem | [P1] |
| Casa nobre/clã | Poder hereditário, terra | [PREV] |
| Guilda/liga mercantil | Comércio, rotas, preços | [P1] |
| Guilda de ofício | Padrão e acesso a profissões | [PREV] |
| Força militar/guarnição | Defesa e conquista | [P1] (guarnição) |
| Organização criminosa | Contrabando, extorsão, roubo | [P1] |
| Ordem religiosa | Legitimidade, cura, doutrina | [PREV] |
| Companhia de aventureiros/mercenários | Contratos armados | [PREV] |
| Organização fundada pelo jogador | Variável | [PREV] |

**Prototipagem:** **três facções** que formam um triângulo de interesses **[PROP]**: autoridade local, organização mercantil e organização criminosa. Esse arranjo gera tensão suficiente (lei, comércio, ilegalidade) com baixo custo.

**Como os conceitos se encaixam (v0.3, DEC-050).** *Organização* é o gênero: qualquer grupo com membros e hierarquia. *Facção* é a organização com vontade política própria (decide, tem território de influência, moral e finanças): é o que o protótipo simula, com **um só tipo no código** (`Faction`) e o tipo como dado (autoridade, mercantil, criminosa). *Governo* não é uma entidade: é o papel de quem exerce o poder numa polity, exercido pela facção de autoridade. *Polity* é a unidade política territorial (`PolityState`), dona das províncias, das leis e da diplomacia. No protótipo: **3 facções completas e 2 polities**, a principal (com a facção de autoridade como governo) e uma vizinha **simplificada** (relações, força e tarifa, sem membros). A soberania sobre uma província é da polity; as facções têm presença e influência nela.

## 10.3 Modelo de facção **[PROP]**

| Componente | Descrição |
|---|---|
| Identidade | Cultura, doutrina, valores, símbolos |
| Recursos | Dinheiro, bens, tropas, influência, informação |
| Território | Assentamentos, rotas, propriedades controladas |
| Membros | Lista de NPCs com posto, lealdade e papel |
| Hierarquia | Postos, requisitos, benefícios, deveres |
| Objetivos | Metas estratégicas ponderadas (expandir, enriquecer, proteger, converter, vingar) |
| Relações | Afinidade com outras facções e com o jogador |
| Estado | Moral, coesão, legitimidade, escassez |

## 10.4 Ciclo de decisão da facção **[PROP]**

A cada intervalo (ex.: semanal **[HIP]**), a facção "delibera":

1. **Avaliar estado:** recursos, ameaças, oportunidades, objetivos.
2. **Gerar opções:** expandir comércio, reforçar fronteira, atacar rival, buscar aliança, reduzir gastos, recrutar.
3. **Pontuar** por utilidade e pela personalidade coletiva (líder + doutrina).
4. **Alocar recursos** e emitir **ordens** a membros (que as executam como contratos ou tarefas).
5. **Registrar** a decisão (para consequências e histórico).

Isso mantém facções ativas a baixo custo, com decisões compreensíveis ao jogador.

## 10.5 Hierarquia e ascensão do jogador **[PROP]**

Postos têm requisitos (reputação, habilidade, contribuição, tempo), benefícios (acesso, salário, comando) e deveres (tarefas, lealdade). A ascensão exige **mérito demonstrado** e **vagas** (pois NPCs ocupam postos). Rivais internos podem competir. A traição de facção tem custo (perda de reputação, caça). **Fundar uma organização** é **[PREV]**, pois exige estrutura de recursos e membros.

## 10.6 Sistema de facções e organizações

**Objetivo.** Criar atores coletivos com agenda própria que sustentem política, guerra e economia.

**Funcionamento.** Ciclo de decisão periódico, modelo de recursos e hierarquia, execução por membros NPCs.

**Dados envolvidos.** Facção (recursos, território, objetivos, relações, doutrina), Posto, Membro, Ordem, Histórico de decisões.

**Relação com outros sistemas.** Política (cap. 11), economia (tributos, financiamento), militar (cap. 14), NPCs (membros), eventos (disputas), reputação.

**Interações do jogador.** Ingressar, cumprir tarefas, ascender, trair, financiar, sabotar, mediar, negociar, fundar [PREV].

**Comportamento autônomo.** Facções tomam decisões, firmam e rompem acordos, recrutam e perdem membros, disputam território e recursos.

**Consequências.** Crescimento ou queda de facções altera mercados, segurança, política e oportunidades do jogador.

**Complexidade e prioridade.** Alta. Prioridade **P1**. **[P1]** 3 facções com ciclo de decisão simples, hierarquia curta (3 a 5 postos), reputação do jogador. **[PREV]** facções do jogador, diplomacia entre facções, subfacções.

## 10.7 Exemplo emergente

> A facção criminosa perde receita porque a guarda reforçou patrulhas. Sua decisão por utilidade é mudar de alvo: extorquir comerciantes sob a facção mercantil. A facção mercantil perde lucro, contrata o jogador para escoltar caravanas e reduz impostos para a autoridade local, que fica com menos recursos para a guarda. O ciclo reverte parte do avanço da guarda.

---

# 11. POLÍTICA, DIPLOMACIA, INFLUÊNCIA E GOVERNANÇA

## 11.1 Princípio **[CONF]**

Facções, governos, alianças, disputas, influência, intrigas, rebeliões e mudanças de poder devem produzir consequências.

## 11.2 Conceitos centrais **[PROP]**

A relação entre organização, facção, governo e polity está no cap. 10.2.

| Conceito | Definição |
|---|---|
| Influência | Capital político acumulável e gastável, por ator e por local |
| Legitimidade | Aceitação do governante pelos governados, por cultura e resultados |
| Estabilidade | Equilíbrio entre satisfação, ordem e coesão em um assentamento ou polity |
| Lei | Conjunto de parâmetros (tributos, tarifas, conscrição, penas, licenças) |
| Cargo | Posição com poderes definidos (governante, conselheiro, juiz, capitão) |
| Sucessão | Regra de transição de poder (hereditária, eleição, escolha, força) |
| Relação diplomática | Estado entre polities (guerra, hostilidade, neutralidade, comércio, aliança, vassalagem) |

## 11.3 Governança local **[PROP]**

Cada assentamento tem um governante (T3) e leis. Decisões típicas: ajustar impostos, impor tarifas, recrutar guardas, abrir ou fechar mercado a estrangeiros, conceder licenças. Tomadas a partir da situação (orçamento, ameaças, satisfação) e da personalidade do governante.

**Ciclo de estabilidade [PROP]:** satisfação da população depende de abastecimento, segurança, renda, tributos e adesão cultural. Satisfação baixa por tempo prolongado leva a protestos, depois a rebelião e a mudança de poder.

## 11.4 Diplomacia **[PROP]**

Entre polities e facções: relações numéricas e rótulos, com eventos que mudam o estado (casamento, acordo, tributo, ofensa, guerra, resgate). Tratados têm termos (comércio, passagem, defesa mútua, cessão de território), prazo e condições de quebra. A **quebra** tem custo reputacional.

**Prototipagem:** **duas ou três polities** (por exemplo, a cidade mercantil, o reino agrário e uma facção de fronteira) com estados de relação básicos e **tratados comerciais simples**.

## 11.5 Intriga **[PREV/FUT]**

Espionagem, sabotagem, escândalos, conspiração e assassinato político. Todos dependem de um bom sistema de informação e de conhecimento (quem sabe o quê). Fora do protótipo, exceto um mecanismo mínimo de **boato político** que afeta legitimidade.

## 11.6 Rebeliões e mudança de poder **[PROP]**

- **Gatilhos:** fome, tributação alta, derrota militar, humilhação cultural, escândalo.
- **Estágios:** descontentamento, protestos, formação de liderança rebelde (T2/T3 que se destaca), confrontos, resolução (repressão, concessão, queda).
- **Resultados:** novo governante, novas leis, ressentimentos duradouros e memória coletiva.

**Prototipagem:** estágios até protestos e distúrbios ([P1]); queda de governante e sucessão por força [PREV].

## 11.7 Sistema de política e governança

**Objetivo.** Dar peso às decisões coletivas e criar oportunidades de influência para o jogador.

**Funcionamento.** Leis, influência, legitimidade, estabilidade e relações diplomáticas atualizadas por regras e eventos.

**Dados envolvidos.** Polity, Lei, Cargo, Influência por ator, Legitimidade, Estabilidade, Relação diplomática, Tratado.

**Relação com outros sistemas.** Economia (tributos, tarifas), facções, militar (conscrição), NPCs (satisfação, apoio), eventos (crises, sucessões), consequências (histórico).

**Interações do jogador.** Peticionar, subornar, aconselhar, apoiar candidatos, tomar cargos, propor leis, mediar tratados, incitar ou reprimir revoltas.

**Comportamento autônomo.** Governantes ajustam leis, polities negociam e rompem, rebeliões surgem de condições, sucessões ocorrem.

**Consequências.** Leis alteram economia e comportamento (tarifa alta gera contrabando). Instabilidade gera guerra civil ou invasão oportunista.

**Complexidade e prioridade.** Alta. Prioridade **P1**. **[P1]** leis de tributo, tarifa e conscrição, estabilidade, protestos, 2 a 3 polities, tratados comerciais simples. **[PREV]** sucessão, rebelião completa, cargos para o jogador. **[FUT]** intriga e espionagem.

## 11.8 Exemplo emergente

> A autoridade local sobe a tarifa de entrada para financiar a guarnição. Comerciantes estrangeiros reduzem visitas, o preço de bens importados sobe, a satisfação da população cai e o contrabando cresce. A facção criminosa ganha influência, enquanto o governante perde legitimidade. O jogador pode ser contratado para contrabandear, para combater contrabandistas ou para organizar uma petição.

---

# 12. ECONOMIA, PRODUÇÃO, COMÉRCIO E DISTRIBUIÇÃO

## 12.1 Princípio **[CONF]**

Produção, comércio, transporte, consumo, estoques, preços e escassez estão conectados e produzem efeitos observáveis.

## 12.2 Modelo conceitual **[PROP]**

A economia é uma **rede de fluxos** de bens entre produtores, mercados e consumidores:

```
Recursos naturais → Produção (cadeias) → Estoques → Mercados (preço) → Consumo
                                  ↑                    ↑
                        Transporte (rotas, caravanas)  Demanda (população, facções, exércitos)
```

## 12.3 Componentes

### Bens
Cada bem tem categoria (alimento, matéria-prima, processado, ferramenta, arma, luxo, mágico [FUT]), valor-base, peso/volume, perecibilidade e uso (consumo, insumo, equipamento).

### Cadeias de produção
Receitas (insumos → produto) executadas por construções de produção com trabalhadores. A eficiência depende de habilidade, insumos disponíveis e condições (estação, clima).

### Mercados
Cada assentamento tem **um mercado** com estoques por bem, **preço local** e fluxos de entrada e saída. O mercado calcula o preço por **razão entre estoque e estoque-alvo** (oferta e demanda local), com limites e suavização para evitar oscilações bruscas **[PROP]**.

**Regras de preço [PROP]:**
- Preço sobe quando o estoque fica abaixo do alvo e desce quando fica acima, dentro de uma faixa (ex.: de 0,5 a 3 vezes o valor-base **[HIP]**).
- A mudança é **suavizada** no tempo (inércia).
- Existe **spread** entre preço de compra e de venda, o que impede lucro infinito por compra e venda imediatas.
- Mercados têm **profundidade**: grandes volumes movem o preço contra quem opera.

### Transporte
Bens se movem por **caravanas e carregadores** (entidades), que consomem tempo, capacidade e pagam risco. Rotas têm distância, custo e risco, e podem ser interrompidas.

### Consumo e demanda
A população consome conforme necessidades (alimento, vestuário, ferramentas, luxo). Facções e exércitos consomem bens (armas, comida, madeira).

### Dinheiro
Uma moeda única no protótipo **[PROP]**. Múltiplas moedas, câmbio e inflação são **[FUT]**.

### Sumidouros e fontes de dinheiro **[PROP]**
Para evitar inflação descontrolada e exploração do jogador: sumidouros (manutenção de equipamentos, tributos que se convertem em despesas, deterioração de bens, custos de viagem, serviços) e fontes controladas (produção de valor, mineração de metais preciosos, saques).

## 12.4 Duas escalas de simulação **[PROP]**

- **Detalhada (S0/S1):** caravanas são agentes que viajam fisicamente. O jogador pode interceptá-las, escoltá-las ou emboscá-las.
- **Agregada (S2):** fluxos entre mercados distantes são calculados como **taxas** de transferência com atraso, risco e capacidade.

As duas devem produzir resultados equivalentes em média, conforme o princípio de consistência (cap. 4.5).

## 12.5 Sistema de economia

**Objetivo.** Produzir um mundo em que preços, escassez e riqueza mudem por causas rastreáveis, criando oportunidades e crises.

**Funcionamento.** Produção por cadeia, estoques por mercado, preços por razão estoque/alvo, transporte por caravanas e fluxos, consumo por população.

**Dados envolvidos.** Bem, Receita, Construção produtiva, Mercado (estoque, preço, alvo), Rota, Caravana, População consumidora, Orçamento de facção, Histórico de preços.

**Relação com outros sistemas.** Recursos (cap. 13), NPCs (trabalhadores, clientes), política (tributos, tarifas), militar (demanda, logística), eventos (secas, saques, pragas), construção (cap. 18).

**Interações do jogador.** Comprar, vender, produzir, transportar, investir, criar negócios, contrabandear, monopolizar (dentro de limites), sabotar.

**Comportamento autônomo.** Comerciantes NPC arbitram preços, produtores ajustam produção, caravanas partem e chegam, preços reagem, facções financiam operações.

**Consequências.** Escassez altera satisfação e estabilidade. Preços elevados criam oportunidades para o jogador e para NPCs. Falta de bens militares enfraquece exércitos.

**Complexidade e prioridade.** Muito alta (para equilibrar). Prioridade **P0**. **[P1]** 8 a 12 bens, 4 cadeias, 1 mercado por assentamento, caravanas de NPC em S0/S1 e fluxos em S2, preços por razão, tributos. **[PREV]** múltiplas moedas, crédito, investimento de NPCs ricos. **[FUT]** bolsa, bancos, inflação.

## 12.6 Exemplo emergente (o exemplo do briefing em detalhe)

> **1.** Um conflito territorial entre a polity do reino e uma facção de fronteira fecha a passagem de uma ponte. 
> **2.** A **rota comercial** que ligava a região agrícola à cidade mercantil fica intransitável. 
> **3.** O **estoque de grãos** na cidade cai abaixo do alvo, e o **preço** sobe. 
> **4.** **Comerciantes** que dependiam da rota perdem receita e **desistem ou desviam** por caminhos mais longos (custo maior). 
> **5.** A **facção mercantil** perde recursos e passa a **cobrar mais** dos associados. 
> **6.** A **satisfação** da população cai, o governante da cidade perde **legitimidade**. 
> **7.** A decisão política: reduzir tarifas ao reino agrário ou pagar mercenários para reabrir a ponte. 
> **8.** O **jogador** pode: escoltar caravanas por caminho alternativo, ser mercenário na ponte, contrabandear, comprar grão barato a oeste e vender caro, ou ignorar.

---

# 13. RECURSOS, PROFISSÕES E ATIVIDADES PRODUTIVAS

## 13.1 Categorias de recursos **[PROP]**

| Categoria | Exemplos genéricos | Regeneração |
|---|---|---|
| Alimentos | Grãos, vegetais, carne, laticínios, pescado | Sazonal, renovável |
| Materiais naturais | Madeira, pedra, fibras, couro, lã | Renovável (lento) ou finito |
| Minérios | Ferro, cobre, carvão, metais preciosos | Finito, esgotável |
| Processados | Metal, tábuas, tecido, farinha | Produzidos |
| Manufaturados | Ferramentas, armas, armaduras, roupas | Produzidos |
| Luxo | Joias, especiarias, tinturas | Raro, comerciado |
| Mágicos | Componentes, relíquias | [FUT] |

## 13.2 Profissões produtivas e cadeias de exemplo **[PROP]**

| Profissão | Insumo | Produto | Local |
|---|---|---|---|
| Agricultor | Terra, sementes, trabalho | Grãos, vegetais | Fazenda |
| Pastor | Pasto | Carne, lã, couro | Pasto |
| Lenhador | Árvores | Madeira | Floresta |
| Minerador | Veio | Minério, pedra | Mina |
| Moleiro/Padeiro | Grãos | Farinha, pão | Moinho, padaria |
| Fundidor | Minério, combustível | Metal | Forja |
| Ferreiro | Metal, combustível | Ferramentas, armas | Oficina |
| Tecelão/Alfaiate | Lã, fibras | Tecido, roupas | Tecelagem |
| Construtor | Madeira, pedra, trabalho | Estruturas | Canteiro |
| Mercador/Carregador | Bens | Transferência | Rotas |
| Alquimista | Plantas, minerais | Poções | Laboratório [PREV] |

**Cadeias do protótipo [PROP]:**
1. Grão → Farinha → Pão (alimento).
2. Minério + Combustível → Metal → Ferramentas → Armas (equipamento e demanda militar).
3. Madeira → Tábuas → Construção (expansão).
4. Lã/Fibra → Tecido → Roupas (consumo e comércio).

## 13.3 Recursos finitos e renováveis

Minas se esgotam, florestas regeneram devagar, terras férteis rendem conforme estação e manejo. Isso gera **motivos para expansão** (buscar novas jazidas), conflito e comércio.

## 13.4 Construções produtivas **[PROP]**

Oficinas e fazendas têm **capacidade**, **trabalhadores**, **eficiência** e **manutenção**. O jogador pode possuir ou alugar algumas e contratar NPCs.

## 13.5 Sistema de recursos e produção

**Objetivo.** Dar substância material à economia e à exploração.

**Funcionamento.** Nós de recurso em províncias e locais, extraídos por atividades. Cadeias de produção em construções.

**Dados envolvidos.** Nó de recurso (tipo, quantidade, regeneração), Construção produtiva (receita, capacidade, trabalhadores, estado), Atividade.

**Relação com outros sistemas.** Economia, NPCs (trabalho), exploração (novos nós), eventos (secas, incêndios), militar (suprimento), construção.

**Interações do jogador.** Extrair, coletar, produzir, descobrir nós, proteger, sabotar.

**Comportamento autônomo.** NPCs extraem e produzem, nós se esgotam e regeneram, produtores adaptam o que produzem conforme preços.

**Consequências.** Esgotamento de uma mina levanta preços e abre expedições. Incêndio em oficina interrompe cadeia.

**Complexidade e prioridade.** Média a Alta. Prioridade **P0**. **[P1]** nós de recurso simples e 4 cadeias. **[PREV]** ofícios avançados, alquimia, recursos mágicos.

---

# 14. SISTEMA MILITAR, EXÉRCITOS E HIERARQUIAS

## 14.1 Objetivo geral

Representar a força armada de polities e facções como um sistema com custo, logística e comando, que se conecta à economia e à política, em vez de "exércitos" mágicos que surgem do nada.

## 14.2 Estrutura de forças **[PROP]**

| Nível | Descrição | Exemplo genérico |
|---|---|---|
| Unidade | Grupo pequeno | Esquadra de 5 a 10 |
| Companhia | Várias unidades sob um capitão | 30 a 100 |
| Exército/Hoste | Várias companhias sob comando | 200+ |
| Guarnição | Força fixa em local | Guarda de cidade, fortaleza |

**[HIP]** Os números reais dependem do orçamento de desempenho em S0 (ver cap. 15).

## 14.3 Tipos de unidades **[PROP]**

Infantaria leve e pesada, arqueiros, cavalaria leve, milícia e, **[PREV]**, unidades de cerco e de magia. No protótipo, 3 a 4 tipos bastam.

## 14.4 Recrutamento e sustento **[PROP]**

- **Fontes:** voluntários, conscrição (lei), mercenários contratados, milícia local.
- **Custos:** soldo, comida, equipamento, manutenção. Tudo vem do orçamento da facção, ligado à economia.
- **Moral e lealdade:** pagamento atrasado, derrotas e fome reduzem moral, geram deserção e motins.

## 14.5 Hierarquia e comando **[PROP]**

- **Postos:** soldado, sargento, oficial, comandante, comandante-geral. Ocupados por NPCs T2/T3.
- **Traços de comandante:** agressividade, cautela, logística, carisma. Influenciam decisões e eficácia.
- **Doutrina:** vinda da cultura (cap. 5): defensiva, ofensiva, mercenária, guerrilha.

## 14.6 Logística **[PROP]**

Exércitos consomem suprimento por dia de marcha ou combate. A falta de suprimento reduz moral e eficácia. Isso conecta guerra e economia (caravanas de suprimento são alvos).

## 14.7 Sistema militar

**Objetivo.** Fazer do militar um sistema material e organizacional integrado.

**Funcionamento.** Facções mantêm forças com custo e comando. Forças podem ser enviadas a missões (patrulha, escolta, repressão, ataque, defesa).

**Dados envolvidos.** Unidade (composição, moral, suprimento, posição, comandante), Posto, Orçamento militar, Doutrina, Missão.

**Relação com outros sistemas.** Economia (custos, demanda por armas), política (conscrição, decisões de guerra), combate (cap. 16), guerra (cap. 15), NPCs (soldados).

**Interações do jogador.** Alistar-se, ascender, liderar, contratar mercenários, fornecer suprimentos, desertar, sabotar, cobrar soldo, aconselhar.

**Comportamento autônomo.** Forças patrulham, respondem a ameaças, mantêm moral, consomem suprimento, desertam quando estão mal.

**Consequências.** Fraqueza militar convida a invasões. Excesso de gasto militar prejudica a economia e a estabilidade.

**Complexidade e prioridade.** Alta. Prioridade **P1**. **[P1]** guarnição e patrulhas, pequenos grupos de mercenários/bandidos, custo e moral simples, 3 tipos de unidade. **[PREV]** exércitos grandes, comandantes com traços completos, logística detalhada. **[FUT]** unidades de cerco e mágicas.

## 14.8 Exemplo emergente

> Uma guarnição não recebe soldo por três semanas porque o tesouro foi esvaziado pela perda de uma rota. A moral cai, parte dos soldados deserta e vira bandido, e a rota fica ainda mais perigosa. O governante precisa decidir entre aumentar impostos (risco de protesto) ou contratar mercenários (custo imediato). O jogador pode ser contratado, assaltar os desertores ou unir-se a eles.

---

# 15. GUERRAS, CONFLITOS, CERCOS E BATALHAS

## 15.1 Princípio **[CONF]**

Conflitos surgem por território, recursos, interesses políticos, rivalidades e oportunidades estratégicas. Incluem invasões, cercos e batalhas de diferentes escalas.

## 15.2 Escala de conflitos **[PROP]**

| Escala | Descrição | Resolução |
|---|---|---|
| Incidente | Briga, roubo, emboscada | Jogador e NPCs em tempo real (S0) |
| Escaramuça | Pequenos grupos, patrulhas, ataques a caravana | Tempo real (S0/S1) |
| Batalha | Forças organizadas em campo | Tático em tempo real limitado **[HIP]** ou resolução abstrata |
| Cerco | Ataque prolongado a fortificação | Fases com desgaste, suprimento e assalto |
| Guerra | Conjunto de operações entre polities | Simulação estratégica agregada |

## 15.3 Causas de guerra (casus belli) **[PROP]**

Cada guerra possui **causa registrada** nos dados, escolhida do conjunto abaixo e combinada:

- Território ou rota estratégica.
- Recurso (mina, terra fértil).
- Rivalidade ou vingança (memória coletiva).
- Oportunismo (vizinho enfraquecido).
- Legitimidade ou sucessão.
- Defesa de aliado.
- Conversão ou ideologia **[PREV]**.

**Decisão de declarar guerra [PROP]:** utilidade calculada com: razão de forças, capacidade econômica de sustentar, cansaço de guerra, apoio interno, aliados, custo diplomático e personalidade do governante. A guerra **não** é aleatória.

## 15.4 Fases de uma guerra **[PROP]**

1. **Tensão:** relações caem, incidentes aumentam.
2. **Mobilização:** recrutamento, estocagem, reposicionamento (visível ao jogador).
3. **Operações:** marchas, bloqueio de rotas, saques, escaramuças, batalhas, cercos.
4. **Desgaste:** moral, suprimento, economia e política interna.
5. **Resolução:** vitória, derrota, trégua, tratado (cessão de território, tributo, reparações).
6. **Legado:** memória coletiva, ressentimento, mudanças de fronteira e de leis.

## 15.5 Batalhas: estratégia técnica **[LIM/HIP]**

Batalhas grandes em tempo real em Godot com um desenvolvedor solo são arriscadas. A proposta é uma abordagem escalonada:

- **Nível jogador (S0):** o jogador participa fisicamente de um recorte da batalha (poucas dezenas de combatentes em volta).
- **Nível tático:** a visão de câmera tática permite ver e (em papéis de comando) dar **ordens de alto nível** a grupos, sem controlar cada soldado.
- **Resolução agregada:** o resultado global é calculado por regras (forças, moral, terreno, comandantes, suprimento), e o recorte do jogador é uma amostra visual coerente.
- **Orçamento de agentes em tempo real [HIP]:** número máximo de combatentes simulados em detalhe a ser definido por perfilagem. O restante é representado por grupos (blocos).

## 15.6 Cercos **[PROP, PREV]**

Fortificações têm **muralhas, portões, suprimento, guarnição e moral**. Fases: bloqueio, desgaste por fome e doença, tentativas de brecha ou sabotagem, assalto ou rendição. O jogador pode ser sitiante, defensor, sabotador, abastecedor ou negociador. **Fora do protótipo.**

## 15.7 Efeitos econômicos e políticos **[CONF/PROP]**

Guerras interrompem rotas, destroem produção, deslocam população (refugiados), aumentam demanda por bens militares e podem derrubar governantes. O pós-guerra altera fronteiras e leis.

## 15.8 Sistema de guerra e batalhas

**Objetivo.** Gerar conflitos significativos, rastreáveis e com consequências sistêmicas.

**Funcionamento.** Facções avaliam, declaram e conduzem guerra por fases, com operações resolvidas em tempo real próximo ao jogador e de forma agregada no restante.

**Dados envolvidos.** Guerra (partes, causa, estado, fase, objetivos), Operação (força, alvo, tipo), Batalha (participantes, terreno, resultado), Cerco (fortificação, estado), Tratado.

**Relação com outros sistemas.** Política, economia (bloqueios, demanda, destruição), militar (forças), NPCs (refugiados, soldados), eventos, reputação e histórico.

**Interações do jogador.** Participar, comandar (em níveis permitidos), abastecer, espionar, sabotar, mediar, lucrar, desertar.

**Comportamento autônomo.** Guerras começam, evoluem e terminam sem o jogador, com operações e batalhas resolvidas de forma agregada.

**Consequências.** Mudança de fronteiras, de leis e de população. Escassez, inflação de bens militares, ressentimento persistente.

**Complexidade e prioridade.** Muito alta. Prioridade **P2** (conflito mínimo entra no protótipo). **[P1]** **conflito armado em escala pequena**: escaramuças e ataques entre facções e bandos, pequenas batalhas resolvidas por regras e participação do jogador. **[PREV]** guerras entre polities, cercos, comando tático. **[FUT]** campanhas multirregionais.

## 15.9 Exemplo emergente

> A facção criminosa cresce na região de fronteira. A guarnição reage com operação de repressão. A ação desloca bandidos para outra rota, onde a facção mercantil sofre perdas e pede reforço. O governante, sem fundos, aumenta tributos; protestos surgem. O jogador pode participar de qualquer lado ou explorar o caos.

---

# 16. COMBATE, EQUIPAMENTOS, ARMAS E MAGIA

## 16.1 Princípios **[CONF/PROP]**

O combate deve ser **interessante e integrado ao mundo**, não uma atividade isolada. Usa as mesmas regras para jogador, NPCs e criaturas.

## 16.2 Combate corpo a corpo **[PROP]**

Ação em tempo real em terceira pessoa:

- **Ataques:** leves e pesados, com tempo de preparo e recuperação.
- **Defesa:** bloqueio, parada e esquiva, com custo de estamina.
- **Estamina e posicionamento** importam mais que "números de dano".
- **Alvo e habilidades (DEC-117, APROVADA somente quanto à direção):** o jogador seleciona o inimigo clicando nele, o ataque é automático contra o alvo e as habilidades são acionadas pelo jogador, "mas melhorado". O que significa o "melhorado" está **em aberto** e será explorado no SP6.
- **Lesões:** modelo simples de **vida + estados de ferimento** (sangramento, membro ferido, atordoamento), com cura demorada e custo econômico (curandeiros).

**[HIP]** O ritmo exato (mais acessível ou mais exigente) precisa ser testado, e dificuldade ajustável deve existir.

Os demais itens desta seção continuam [PROP] e serão revistos no SP6 à luz da DEC-117.

## 16.3 Combate à distância **[PROP]**

Arcos e bestas (no protótipo), arremesso. Munição como bem econômico. Mira simples com queda de projétil moderada.

## 16.4 Furtividade **[PROP]**

Visibilidade (luz, ruído, movimento), percepção de NPCs por cone de visão e audição, ações silenciosas (ataque furtivo, roubo, infiltração). Integra-se com crime (cap. 20), com NPCs e rotinas (cap. 9).

## 16.5 Equipamentos **[PROP]**

- **Categorias de armas:** espadas curtas e longas, machados, lanças, maças, arcos, bestas, adagas. Cada categoria muda alcance, velocidade, dano e eficiência contra armaduras.
- **Armaduras em camadas** simples (cabeça, torso, membros), com tipo (tecido, couro, malha, placa) afetando peso, defesa e ruído.
- **Qualidade e durabilidade:** itens produzidos por NPCs ou pelo jogador têm qualidade variável e desgaste. **Reparo** exige ferreiros (economia).
- **Peso e carga:** influenciam estamina e velocidade.

**Prototipagem:** 5 a 6 armas, 3 a 4 níveis de armadura, durabilidade e reparo.

## 16.6 Magia **[PEND/PROP]**

Origem, regras e escopo são decisões pendentes. Proposta de abordagem **de baixo risco**:

- **Raridade e custo:** poucos praticantes, aprendizado exigente (mentor, tempo, itens). Magia não é um "botão de poder" gratuito.
- **Recurso limitado:** energia que se recupera devagar, ou custo em materiais. Uso excessivo gera fadiga ou risco.
- **Consequência social:** atitude cultural (cap. 5) afeta tolerância e perseguição.
- **Escopo do protótipo [PROP]:** **zero a dois efeitos simples**, apenas para validar integração (ex.: um efeito utilitário e um efeito de combate). Recomenda-se não construir um sistema completo de magia antes de comprovar o resto.
- **Magia e economia:** reagentes e relíquias são bens comerciáveis **[FUT]**.

## 16.7 Criaturas e combate **[PROP]**

Criaturas usam o mesmo sistema de combate com variações (ataques, comportamento, fraquezas). Chefes têm fases e áreas próprias (cap. 17).

## 16.8 IA de combate **[PROP]**

NPCs avaliam risco antes de combater (comparação de força, moral, posição, personalidade) e podem fugir, render-se, pedir ajuda ou negociar. Combate em grupo exige coordenação simples (flanquear, cobrir, manter formação em nível de unidade).

## 16.9 Sistema de combate e equipamentos

**Objetivo.** Dar ação direta ao jogo, integrada à economia e ao mundo.

**Funcionamento.** Combate em tempo real em terceira pessoa, com estamina, ferimentos, durabilidade e IA que avalia risco. O estilo de controle é por alvo e habilidades (DEC-117), com os detalhes em aberto.

**Dados envolvidos.** Arma (tipo, dano, alcance, velocidade, durabilidade), Armadura, Combatente (vida, estamina, ferimentos, moral), Habilidades de combate, Criatura (comportamento, fraquezas).

**Relação com outros sistemas.** Economia (equipamento, reparo, munição), NPCs, facções e exército, exploração (criaturas), crimes e consequências (violência tem testemunhas).

**Interações do jogador.** Lutar, esquivar-se, usar furtividade, equipar-se, reparar, fugir, negociar, render-se.

**Comportamento autônomo.** NPCs lutam entre si e com criaturas, bandidos assaltam, guardas intervêm.

**Consequências.** Mortes e ferimentos persistentes, perda de equipamento, reputação, crimes registrados.

**Complexidade e prioridade.** Alta. Prioridade **P0** (núcleo da jogabilidade de ação). **[P1]** corpo a corpo, arco, furtividade básica, ferimentos, durabilidade, 0 a 2 efeitos mágicos. **[PREV]** magia ampla, mais armas, combate montado. **[FUT]** domesticação com combate cooperativo.

## 16.10 Exemplo emergente

> Um grupo de bandidos desertores ataca uma caravana. Os guardas contratados fogem por medo (personalidade e moral), e o jogador, que observava, decide intervir. Ele vence, recebe pagamento do comerciante e uma reputação melhor com a facção mercantil, enquanto a guarnição passa a vê-lo como possível testemunha de um desertor que ela procurava.

---

# 17. EXPLORAÇÃO, AVENTURAS, CRIATURAS E DESCOBERTAS

## 17.1 Princípio **[CONF]**

O mundo oferece descoberta, mistérios, tesouros, ambientes perigosos, criaturas, magia e oportunidades.

## 17.2 Pontos de interesse **[PROP]**

| Tipo | Características | Recompensas |
|---|---|---|
| Ruína | Estrutura antiga, perigos, mistérios | Tesouros, informações, receitas, relíquias |
| Caverna/mina | Recursos e ameaças | Minério, criaturas |
| Covil/ninho | Criaturas e perigo | Troféus, materiais raros |
| Acampamento | Bandidos, nômades, expedições | Saque, informação, contratos |
| Marco natural | Vista, local sagrado | Conhecimento, eventos |

**Conteúdo:** locais autorais com **conteúdo variável** (tipo e quantidade de criaturas, loot e estado), o que mantém o valor de revisita sem gerar mundo inteiro por procedural.

## 17.3 Ecologia de criaturas **[PROP]**

- **Habitat e população:** cada criatura tem bioma, território e população por província.
- **Comportamento:** predadores, herbívoros, bandos, solitários, territoriais.
- **Dinâmica:** caça excessiva reduz população. Criaturas ameaçam rotas e vilas se a pressão ou a fome aumentar.
- **Chefes e criaturas únicas:** entidades específicas, com território, comportamento e consequências ao serem eliminadas (a ameaça some, mas o local muda de status).

**Prototipagem:** 3 a 4 tipos de criatura, um chefe, e a dinâmica de população simples.

## 17.4 Descobertas **[PROP]**

Categorias: **informação** (mapas, rumores, segredos), **recursos** (novos nós), **conhecimento** (receitas, técnicas), **itens** (equipamento, relíquias), **lugares** (rotas, atalhos). Descobertas têm **valor no mundo**: informações podem ser vendidas, recursos geram trabalho e conflitos.

## 17.5 Conhecimento e mapa do jogador **[PROP]**

O mapa do jogador revela-se por exploração, compra de mapas e informações. O jogador **só sabe o que descobriu** (neblina de conhecimento), enquanto NPCs têm o conhecimento que o seu papel justifica.

## 17.6 Domesticação de criaturas **[PEND/FUT]**

Viabilidade condicional (conforme o briefing). Exige IA de criatura com dono, necessidades, lealdade e função (montaria, guarda, carga), além de animações e equilíbrio. **Recomendação:** não incluir no protótipo e reavaliar após a validação do combate e da IA de criaturas.

## 17.7 Perigos ambientais **[PROP]**

Clima, terreno, escuridão, venenos, armadilhas. No protótipo: terreno perigoso e armadilhas; clima simples só se DEC-060 (clima e estações fora do protótipo, PROPOSTA) for rejeitada.

## 17.8 Sistema de exploração

**Objetivo.** Dar motivos físicos para sair do assentamento e descobrir coisas que movem o mundo.

**Funcionamento.** Pontos de interesse com conteúdo variável, criaturas com ecologia simples, descobertas com valor econômico e informacional.

**Dados envolvidos.** Ponto de interesse (tipo, estado, conteúdo, perigo), Criatura (tipo, habitat, população), Descoberta (tipo, valor, conhecimento), Mapa do jogador.

**Relação com outros sistemas.** Economia (loot, recursos, informação), combate, NPCs (expedições, caçadores), eventos (monstros que ameaçam rotas), política (propriedade de ruínas e minas).

**Interações do jogador.** Explorar, mapear, caçar, saquear, escoltar expedições, vender informação.

**Comportamento autônomo.** NPCs exploram e caçam, criaturas migram e atacam, locais mudam de estado (esgotado, ocupado, descoberto).

**Consequências.** Descobrir uma mina nova muda uma província. Eliminar um predador reabre rotas, e superpopulação de presas atrai outros predadores.

**Complexidade e prioridade.** Média a Alta. Prioridade **P1**. **[P1]** 4 a 6 locais, 3 a 4 tipos de criatura, 1 chefe, descobertas simples. **[PREV]** ecologia mais rica, mais biomas. **[FUT]** domesticação, ruínas mágicas profundas.

## 17.9 Exemplo emergente

> O jogador descobre uma ruína com minério raro. Se vende a informação à facção mercantil, ela organiza uma expedição, financia mineradores e fortifica o local. A facção criminosa fica sabendo (rumor), planeja um assalto. O jogador pode proteger, trair ou explorar a ruína sozinho antes de todos.

---

# 18. CONSTRUÇÃO, PROPRIEDADES E EXPANSÃO TERRITORIAL

## 18.1 Princípio **[CONF]**

O jogador pode construir negócios, redes comerciais, conquistar territórios e fundar organizações **[CONF]**. NPCs e facções também constroem e expandem **[PROP]** (o briefing diz que as organizações agem sem o jogador, sem detalhar construção).

## 18.2 Tipos de propriedade **[PROP]**

| Tipo | Função | Fase |
|---|---|---|
| Casa | Moradia, armazenamento, descanso | [P1] |
| Oficina/fazenda | Produção | [P1] |
| Loja/taverna | Comércio e serviços | [PREV] |
| Armazém | Estoque e logística | [PREV] |
| Fortificação/torre | Defesa e controle de área | [PREV] |
| Propriedade rural/mansão | Produção e prestígio | [PREV] |
| Assentamento próprio | Expansão territorial | [FUT] |

## 18.3 Modelo de construção **[PROP]**

**Construção modular em "encaixes" (slots)** em vez de construção livre. O jogador escolhe terreno elegível, tipo de estrutura e melhorias, e o jogo posiciona módulos pré-fabricados. Justificativa: construção livre exige física estrutural, validação de navegação, salvamento complexo e arte em grande quantidade **[LIM]**.

**Requisitos de construção [PROP]:** materiais (economia), mão de obra (NPCs construtores), tempo, permissão (leis), terreno (propriedade).

## 18.4 Propriedade e jurisdição **[PROP]**

Cada terreno tem dono (indivíduo, facção, polity), e a lei local determina o que pode ser construído, taxado ou expropriado. Construir sem licença gera multa ou demolição. O jogador compra, aluga, herda ou conquista.

## 18.5 Expansão territorial **[PREV/FUT]**

- Reivindicação de terras livres, fundação de postos e vilas, anexação por conquista, cessão por tratado.
- Territórios geram renda e custos (defesa, administração).
- Governança de territórios do jogador se apoia no sistema político (cap. 11).

**Fora do protótipo.** No protótipo, o jogador possui **uma casa e uma estrutura produtiva**.

## 18.6 Sistema de construção e propriedades

**Objetivo.** Dar ao jogador raízes e capital produtivo, e ao mundo capacidade de crescer.

**Funcionamento.** Módulos em slots, materiais, mão de obra, licenças.

**Dados envolvidos.** Propriedade (id, dono, local, tipo, estado, módulos), Projeto de construção (materiais, progresso, trabalhadores), Licença, Imposto.

**Relação com outros sistemas.** Economia, NPCs (construtores, empregados), política (leis, impostos), militar (fortificações), eventos (incêndios, saques).

**Interações do jogador.** Comprar, alugar, construir, melhorar, empregar, defender, vender.

**Comportamento autônomo.** NPCs e facções constroem e expandem, propriedades se deterioram sem manutenção, são tomadas em guerra ou por dívida.

**Consequências.** Propriedade aumenta renda e responsabilidades (impostos, defesa), é alvo de crime e conflito, e entra no histórico de reputação.

**Complexidade e prioridade.** Alta (por conta de arte e validação). Prioridade **P2**. **[P1]** casa e uma estrutura produtiva por compra ou aluguel, ampliação básica por módulos. **[PREV]** lojas, armazéns, fortificações. **[FUT]** fundação de assentamentos.

## 18.7 Exemplo emergente

> O jogador constrói uma oficina em uma vila. A guilda local cobra taxa, e a vizinhança, que já dependia de um único ferreiro, reage com desconfiança. O ferreiro rival reduz preços, a guilda pressiona por licença e o jogador decide entre pagar, vender mais barato ou transferir a produção.

---

# 19. SISTEMA DE EVENTOS E ACONTECIMENTOS DINÂMICOS

## 19.1 Princípio **[PROP]**

Eventos são **mudanças de estado do mundo com causa, desenvolvimento e legado**, e não "missões". Surgem de condições dos sistemas, de forma probabilística ou determinística, e podem acontecer longe do jogador.

**"Evento" tem três sentidos neste projeto (v0.3):** (1) o **fato** publicado no barramento da simulação, que explica causa e efeito e existe desde a Fase 0; (2) o **registro da crônica**, a memória histórica dos fatos importantes; (3) o **evento de mundo** deste capítulo (seca, surto, ataque), um conteúdo em dados com condições, probabilidade e efeitos. Quando o texto diz "evento dinâmico", é o sentido (3).

## 19.2 Categorias de eventos **[PROP]**

| Categoria | Exemplos | Fase |
|---|---|---|
| Natural | Seca, inundação, praga, incêndio florestal | [P1] (alguns) |
| Social | Festival, tumulto, migração, boato | [P1] (alguns) |
| Econômico | Escassez, boom, quebra de rota, falência | [P1] |
| Político | Mudança de lei, escândalo, sucessão, rebelião | [P1] (simples), [PREV] |
| Militar | Ataque de bandidos, invasão, deserção | [P1] (simples) |
| Exploração | Aparição de criatura, descoberta de ruína | [P1] |
| Sobrenatural | Eventos mágicos, aparições | [FUT] |

## 19.3 Ciclo de vida de um evento **[PROP]**

1. **Semente:** condição ou probabilidade que cria o evento (ex.: precipitação baixa por semanas).
2. **Início:** o evento é criado com escopo (local, atores, duração).
3. **Desenvolvimento:** efeitos aplicados em passos (produção reduzida, preço sobe, migração).
4. **Resposta:** NPCs e facções reagem (cap. 9 e 10).
5. **Resolução:** termina por tempo, por intervenção ou por consequência.
6. **Legado:** efeitos persistentes e registro histórico (cap. 20).

## 19.4 Propagação de informação **[PROP]**

Eventos não são automaticamente conhecidos pelo jogador. A informação chega por **testemunhas, rumores, mensageiros, quadros de avisos, preços e mudanças visíveis**. Isso mantém o mundo "independente do jogador", sem torná-lo opaco.

## 19.5 Ritmo e "diretor" **[PEND]**

Pergunta de design: o mundo deve ter um mecanismo que controle a frequência de eventos (como um "narrador" que evita períodos mortos ou caos demais)?

| Opção | Prós | Contras |
|---|---|---|
| Sem diretor (puramente emergente) | Fiel ao princípio, previsível | Pode produzir períodos vazios ou colapsos |
| Diretor leve (ajusta probabilidades globais) | Equilibra ritmo | Pode ser percebido como "mundo que gira em torno do jogador" |

**Recomendação:** **sem diretor no protótipo**, com **ferramenta de depuração** que mede densidade de eventos. Se necessário, adicionar diretor leve que apenas ajusta **probabilidades de eventos de fundo**, sem tocar na posição do jogador.

## 19.6 Sistema de eventos

**Objetivo.** Fazer o mundo produzir acontecimentos com causa e consequência, dando razão a ações e reações.

**Funcionamento.** Condições monitoram o estado, criam eventos, que aplicam efeitos ao longo do tempo e deixam legado.

**Dados envolvidos.** Evento (tipo, escopo, atores, estado, duração, efeitos, causas), Condição/semente, Registro histórico.

**Relação com outros sistemas.** Todos: clima, economia, política, militar, NPCs, exploração.

**Interações do jogador.** Perceber, investigar, intervir, explorar oportunidades, causar eventos (por ação) ou evitá-los.

**Comportamento autônomo.** Eventos nascem e evoluem independentemente, afetando NPCs e facções.

**Consequências.** Legado nos dados do mundo, atualizações de relações e histórico.

**Complexidade e prioridade.** Alta. Prioridade **P0**. **[P1]** 8 a 12 tipos de evento, ciclo de vida completo, propagação por rumor. **[PREV]** eventos encadeados mais longos, eventos sobrenaturais. **[FUT]** diretor.

## 19.7 Exemplos emergentes

**Cascata econômica e política (exemplo do briefing, expandido):**

> 1. Disputa de fronteira fecha a ponte → 2. rota comercial interrompida → 3. grãos escassos na cidade → 4. preço do pão dobra → 5. comerciantes perdem margem e reduzem compras → 6. a facção mercantil perde receita e reduz o financiamento da guarda → 7. a guarda enfraquecida deixa a estrada vulnerável → 8. bandidos ganham espaço e a facção criminosa cresce → 9. o governante reduz tarifas ao reino agrário, buscando reabrir o comércio → 10. nova rota é aberta e a ponte perde importância estratégica. 
> O jogador pode agir em qualquer ponto e alterar a cascata.

**Praga:**

> Uma praga atinge um assentamento. A produção cai, os preços de remédios sobem e a facção religiosa oferece cura em troca de influência. O jogador pode coletar ervas, transportar remédios, tirar proveito ou ignorar. Se ignora, o assentamento perde população, e a cultura local guarda ressentimento contra quem lucrou com a crise.

---

# 20. CONSEQUÊNCIAS DAS AÇÕES E OMISSÕES DO JOGADOR

## 20.1 Princípio **[CONF]**

As ações **e omissões** do jogador devem poder alterar personagens, organizações, economias, regiões e acontecimentos, e o mundo registra e mantém essas consequências.

## 20.2 Memória do mundo (Crônica) **[PROP]**

Um **registro histórico estruturado** de eventos significativos: **quem, o quê, onde, quando, por quê, efeitos**. A Crônica alimenta:

- reputação (quem sabe o quê),
- memória de NPCs,
- consulta do jogador (diário, "o que aconteceu aqui"),
- explicabilidade ("por que o preço subiu?").

Para controlar tamanho **[LIM]**, eventos antigos e pouco relevantes são **resumidos em agregados** (estatísticas e "marcos"), mantendo relações-chave.

## 20.3 Reputação e conhecimento **[PROP]**

Reputação **não é um número global**. É **por entidade** (facção, assentamento, indivíduo) e **depende de quem sabe**. Uma ação sem testemunhas não gera reputação, mas pode deixar vestígios (itens, rastros, rumores). Rumores se propagam com atraso e distorção.

**Dimensões [HIP]:** honra/confiabilidade, competência, medo, utilidade. Cada entidade pondera de forma diferente conforme sua cultura.

## 20.4 Tipos de consequência **[PROP]**

| Tipo | Descrição | Persistência |
|---|---|---|
| Direta | Efeito imediato (morte, dano, ganho) | Alta |
| Relacional | Mudança de opinião e relação | Média a alta |
| Econômica | Mudança de preços, estoques, rotas | Média (se sustentada) |
| Política | Leis, poder, legitimidade | Alta |
| Territorial | Controle e estado de locais | Alta |
| Informacional | O que é sabido e por quem | Alta |
| Por omissão | O mundo resolve (ou falha em resolver) sem o jogador | Média a alta |

## 20.5 Consequências por omissão **[PROP]**

O mundo continua sem o jogador, e isso precisa ser **perceptível**. Exemplos:

- **Ignorar uma praga:** população cai, assentamento fica menos produtivo, uma facção religiosa ganha influência.
- **Não proteger uma rota:** a caravana é atacada, o comerciante falha e fecha negócio.
- **Não pagar dívida:** NPCs credores ou facções ameaçam, retomam propriedade ou contratam cobradores.

## 20.6 Justiça e crime **[PROP]**

- **Lei local** define crimes e penas.
- **Testemunhas e provas** determinam a descoberta. Guardas investigam por rumores e vestígios.
- **Respostas:** multa, prisão, exílio, caça (recompensa), retaliação de facções.
- **Anistia e perdão:** reputação e influência podem reduzir penas.

## 20.7 Propagação e amortecimento **[PROP]**

Para evitar cascatas descontroladas (e exploits), efeitos se propagam com **amortecimento**: cada elo reduz intensidade, e há **limites** de magnitude por tipo de efeito. A estrutura de causas deve ser **registrada** para permitir explicação e depuração.

## 20.8 Legibilidade das consequências **[PROP]**

Sem explicação, consequências parecem arbitrárias. Mecanismos:

- **Painel "Por quê?":** mostra cadeia causal (ex.: preço do pão subiu porque a ponte foi fechada, que causou escassez de grãos).
- **Mensageiros e rumores** que antecipam efeitos.
- **Diário/Crônica** consultável.

## 20.9 Sistema de consequências, reputação e crônica

**Objetivo.** Garantir que o mundo "lembre" e responda de forma coerente e compreensível.

**Funcionamento.** Crônica de eventos, reputação por entidade, memória de NPCs, justiça, propagação com amortecimento.

**Dados envolvidos.** Registro histórico, Reputação (entidade × entidade), Memória de NPC, Crime, Dívida, Cadeia causal.

**Relação com outros sistemas.** Todos, especialmente NPCs, facções, política, economia, eventos.

**Interações do jogador.** Fazer, não fazer, esconder, confessar, compensar, vingar, perdoar.

**Comportamento autônomo.** NPCs lembram e reagem, facções ajustam relações, a Lei investiga, eventos de longo prazo se formam.

**Consequências.** Todas as listadas, em escalas variadas.

**Complexidade e prioridade.** Muito alta (pela abrangência). Prioridade **P0** (mínimo viável). **[P1]** Crônica básica, reputação por facção e assentamento, memória de T2, crime e justiça simples, painel "Por quê?" para preço e escassez. **[PREV]** reputação multidimensional completa, causalidade longa, vendetas e legado hereditário.

## 20.10 Exemplo emergente

> O jogador rouba um comerciante e é visto por uma criança. A criança conta à mãe, que conta ao guarda. A reputação do jogador com a facção mercantil cai. Dias depois, uma caravana da facção recusa contratá-lo. O jogador volta, paga a dívida e compensa o comerciante. A reputação melhora, mas **o comerciante ainda se lembra** (memória persistente) e cobra preço maior nas próximas transações.

---

# 21. INTERFACE, EXPERIÊNCIA DO USUÁRIO E CÂMERA

## 21.1 Câmera **[CONF/PROP]**

A câmera combina **terceira pessoa** com **visão tática e estratégica**, com **transição contínua (seamless)** entre escalas **[CONF]**.

**Câmera padrão (DEC-115, APROVADA):** terceira pessoa elevada, de altura média. É uma câmera única, que gira 360° em volta do personagem e tem zoom para perto e para longe. A altura e a inclinação são **[HIP]** e são calibradas na LW-046.

**Modelo proposto [PROP]:** uma câmera controlada por um parâmetro contínuo de **altitude/escala**, em vez de modos separados:

| Faixa de escala | Nome | O que o jogador vê e faz |
|---|---|---|
| Baixa | Terceira pessoa | Controle direto do personagem, ação e exploração |
| Média | Tática local | Visão elevada de um local (cidade, batalha), identificação de grupos, ordens simples |
| Alta | Estratégica regional | Mapa com camadas (política, economia, militar, recursos, ameaças), gestão e planejamento |

**Comportamentos de transição [PROP]:**

- À medida que a câmera sobe, a **apresentação muda**: detalhes de pequeno porte somem (LOD visual), símbolos de grupos aparecem, a interface muda de camadas.
- O **controle** muda por contexto: em terceira pessoa o jogador controla o personagem. Na visão tática/estratégica as ações são **ordens e consultas**, o personagem pode ficar parado ou seguir ordens simples.
- **Regras de segurança:** o jogador não deve poder "usar o mapa" para ver tudo. A visão estratégica mostra apenas **informação conhecida** pelo jogador (cap. 17.5), e a visão de áreas não conhecidas fica "enevoada".

**[LIM]** Fazer essa transição fluida em Godot exige: terreno em chunks com LOD, representação por impostors/proxies para objetos distantes, e mudança de camadas de dados. O estilo low-poly estilizado reduz o custo, mas a decisão técnica (streaming, culling, LOD de simulação sincronizado) é um dos maiores riscos. Ver Anexo C.

## 21.2 Interface **[PROP]**

Princípios: **minimalista** em terceira pessoa, **informativa** no mapa, **explicável** em decisões.

**Elementos principais:**

| Elemento | Função | Fase |
|---|---|---|
| HUD mínimo | Vida, estamina, alvo, hora, dinheiro | [P1] |
| Inventário e equipamento | Gestão de itens | [P1] |
| Diálogo e contratos | Conversas, ofertas | [P1] |
| Diário/Crônica | Histórico, rumores, contratos ativos | [P1] |
| Mapa estratégico com camadas | Política, economia (preços, rotas), militar, recursos, perigo | [P1] (camadas básicas) |
| Painel "Por quê?" | Explica causas (preços, escassez, relações) | [P1] (mínimo) |
| Painel de relações/reputação | Sentimentos e dívidas | [P1] |
| Painel de propriedades e negócios | Produção, estoque, funcionários | [P1] (simples) |
| Painel de facção e cargos | Para papéis de liderança | [PREV] |
| Interface de comando tático | Ordens a grupos | [PREV] |

## 21.3 Gestão de informação **[PROP]**

Com uma simulação profunda, o risco principal de UX é **excesso de informação**. Estratégias:

- **Camadas opcionais:** a informação detalhada só aparece por solicitação (mapa, painéis).
- **Indicadores resumidos:** ícones e cores para "escassez", "perigo", "tensão".
- **Alertas contextuais** (ex.: "o preço do grão subiu 40%") com caminho direto ao "Por quê?".
- **Filtros** e níveis de detalhe ajustáveis.

## 21.4 Entradas e acessibilidade **[PROP/PEND]**

- **Teclado e mouse** como entrada primária (PC) **[PROP]** (o briefing fixa a plataforma PC, não o esquema de entrada) e **gamepad** como possibilidade **[PEND]** (DEC-024). O movimento do personagem é por W, A, S e D (DEC-116, APROVADA).
- **Acessibilidade:** legendas, tamanho de texto, daltonismo em camadas de mapa, remapeamento de teclas. Prioridade P2.

## 21.5 Introdução e aprendizado **[PROP]**

Sem tutorial linear forçado. **Dicas contextuais** na primeira vez que um sistema é relevante, e um **ambiente inicial seguro** (a origem escolhida oferece um primeiro conjunto de interações simples). A complexidade se revela com o uso (profundidade progressiva).

## 21.6 Áudio e feedback **[PROP]**

Feedback sonoro e visual claro de ações, clima, ambiente e eventos. Detalhes de áudio fora deste documento.

## 21.7 Sistema de interface e câmera

**Objetivo.** Dar acesso legível ao mundo em todas as escalas, preservando o controle direto do personagem.

**Funcionamento.** Câmera contínua, interface por camadas, painéis de explicação.

**Dados envolvidos.** Estado de câmera (escala, foco), conhecimento do jogador, camadas de mapa, configurações de interface.

**Relação com outros sistemas.** Simulação (LOD), conhecimento/exploração, economia (painéis), política, militar (ordens).

**Interações do jogador.** Navegar, consultar, ordenar, planejar.

**Comportamento autônomo.** Alertas e notificações de eventos relevantes, ajuste automático de LOD.

**Consequências.** Quanto melhor a informação, melhor o jogador decide e mais vivo parece o mundo.

**Complexidade e prioridade.** Alta (câmera contínua e UI de simulação). Prioridade **P0** (terceira pessoa e mapa), **P1** (painéis de explicação), **P2** (comando tático). **[P1]** terceira pessoa + tática simples + mapa estratégico com camadas. **[PREV]** comando tático avançado, mais camadas. **[FUT]** replay de eventos, ferramentas de análise.

---

# 22. PROGRESSÃO E EQUILÍBRIO ENTRE SIMULAÇÃO E DIVERSÃO

## 22.1 Princípio **[CONF/PROP]**

"Equilíbrio entre simulação profunda e jogabilidade divertida" **[CONF]**. Formulação operacional **[PROP]**:

> **A simulação fornece contexto e causalidade. O jogo fornece momentos.** A simulação nunca deve impedir que haja algo interessante para fazer, e o jogador nunca deve precisar entender a simulação completa para agir bem.

## 22.2 Ferramentas de equilíbrio **[PROP]**

| Ferramenta | Função |
|---|---|
| Controle de tempo | Pausa, velocidade, avanço rápido, para tolerar ritmos diferentes |
| Viagem rápida | Permitida com custo (tempo de simulação que continua e risco), nunca "congela" o mundo |
| Informação | Rumores, quadros de avisos, mapa com camadas, "Por quê?" |
| Dificuldade ajustável | Intensidade de necessidades, de combate, de eventos hostis, da economia |
| Oportunidades abundantes | A simulação deve gerar mais demandas do que o jogador pode atender |
| Alívio de perda | Derrota raramente significa perda total (captura, dívida, ferimento) |

## 22.3 Amplitude de agência **[PROP]**

O impacto do jogador cresce com sua posição, não apenas com seu nível de habilidade:

- **Pequeno agente:** altera preços locais, relações com poucos NPCs, pequenos eventos.
- **Agente médio:** altera uma facção, uma cadeia produtiva, uma região.
- **Grande agente:** altera guerras, leis e rotas.

Cada degrau deve ser **alcançável** com esforço, e **cada degrau deve ser divertido por si**.

## 22.4 Anti-exploits **[PROP]**

- **Arbitragem infinita:** profundidade e spread de mercado.
- **Dinheiro infinito:** sumidouros (cap. 12).
- **Treino repetitivo:** retornos decrescentes (cap. 6).
- **Salvar/recarregar para manipular o mundo:** o simulador é determinístico dado um estado, mas a variabilidade deve vir de uma semente de simulação **armazenada no save**, para tornar o "salvar e testar" menos eficaz **[HIP]**. Se o determinismo total for desejado, é decisão **[PEND]**.
- **Conhecimento perfeito do mapa:** neblina de conhecimento.

## 22.5 Testes de estabilidade da simulação **[PROP, essencial]**

- **Teste sem jogador (soak test):** rodar o mundo por muitos "anos" de jogo, verificando: população não extingue nem explode, preços ficam em faixa, nenhuma facção domina totalmente sem causa, não há colapso econômico sem evento. Falhas ajustam parâmetros.
- **Teste de perturbação:** introduzir choques (fechar rota, remover líder) e observar resposta (recuperação, cascata, colapso).
- **Teste de equivalência de LOD:** (ver cap. 4.5).
- **Ferramentas de inspeção em tempo real:** painéis de depuração (preços, estoques, decisões, eventos) são **requisito de desenvolvimento**, não luxo.

## 22.6 Ritmo de jogo **[HIP]**

Métrica de referência: **a cada poucos minutos reais, deve existir ao menos uma decisão ou descoberta significativa disponível**. Esse número deve ser calibrado em playtests.

## 22.7 Contradições e tensões de design **[PROP: apresentadas conforme o briefing]**

| Tensão | Consequência | Direção proposta |
|---|---|---|
| Mundo independente × jogador relevante | Risco de irrelevância | Escalas de agência, informação e oportunidades abundantes |
| Simulação profunda × legibilidade | Risco de opacidade | "Por quê?", camadas de informação |
| Liberdade total × consequências coerentes | Risco de exploração | Amortecimento, limites, retornos decrescentes |
| Simulação em escala × solo dev | Risco de escopo | LOD de simulação, tiers, protótipo pequeno |
| Câmera contínua × desempenho | Risco técnico | Chunks, LOD, impostors |
| IA generativa opcional × coerência | Risco de contradição | Somente apresentação, nunca estado |
| Combate em tempo real × batalhas grandes | Risco técnico | Escalas de resolução |

## 22.8 Sistema de equilíbrio e progressão global

**Objetivo.** Preservar diversão sem trair a simulação.

**Funcionamento.** Ferramentas descritas, testes automatizados e parâmetros configuráveis em arquivos de dados.

**Dados envolvidos.** Parâmetros de balanceamento, métricas de simulação, telemetria local, configurações de dificuldade.

**Relação com outros sistemas.** Todos.

**Interações do jogador.** Ajustar dificuldade e velocidade, usar ferramentas informativas.

**Comportamento autônomo.** Mundo se autorregula dentro dos limites calibrados.

**Consequências.** Qualidade percebida do jogo.

**Complexidade e prioridade.** Muito alta (contínua). Prioridade **P0** (soak tests e ferramentas de inspeção). **[P1]** dificuldade ajustável, controle de tempo, soak tests, depuração. **[PREV]** telemetria de playtest, diretor leve **[PEND]**.

---

# 23. EXPERIÊNCIA SINGLE-PLAYER E POSSIBILIDADES FUTURAS DE MULTIPLAYER

## 23.1 Single-player **[CONF]**

- Experiência offline completa, sem dependência de rede nem de IA generativa.
- **Salvamento [PROP]:** estado completo do mundo (entidades, estoques, relações, crônica, semente), com salvamentos manuais e automáticos. O briefing não trata de salvamento; o modelo definitivo de persistência está **PENDENTE** (DEC-083).
- **Tamanho do save [LIM]:** crônica e memórias exigem poda e agregação (cap. 20.2).
- **Modos de jogo [PROP]:** padrão (mundo vivo completo), **modo "sandbox livre"** (menos pressão de necessidades) e **parâmetros do mundo** (frequência de guerras, severidade de eventos) como opções de início. [PREV].

## 23.2 Multiplayer: princípio **[CONF]**

Possibilidade futura, **sem obrigação** de implementar no protótipo.

## 23.3 Modelos possíveis **[FUT]**

| Modelo | Descrição | Dificuldade |
|---|---|---|
| Cooperativo com anfitrião | Um jogador hospeda o mundo, outros entram como habitantes | Alta |
| Servidor persistente pequeno | Mundo hospedado continuamente, poucos jogadores | Muito alta |
| Mundo compartilhado em larga escala | Muitos jogadores | Inviável para solo dev **[LIM]** |

**Recomendação:** não perseguir multiplayer antes de validar o single-player. Se for o caso, cooperativo com anfitrião é o menor passo.

## 23.4 Premissas arquiteturais baratas que preservam o futuro **[PROP]**

Mesmo sem implementar multiplayer, o design deve respeitar:

1. **Separação entre simulação e apresentação:** a simulação não depende de câmera, UI ou renderização.
2. **Ações do jogador como comandos de dados** (não chamadas diretas a funções espalhadas), o que facilita validação, replay e rede.
3. **Identificadores estáveis** para todas as entidades.
4. **Estado centralizado e serializável**, sem lógica escondida em objetos de cena.
5. **Passo de simulação com taxa fixa**, independente de quadros.
6. **Semente de aleatoriedade** controlada.

**[LIM]** Determinismo estrito entre máquinas (necessário para certos modelos de rede) é difícil em GDScript (ponto flutuante, ordem de execução). Em modelos com **servidor autoritativo** isso não é requisito, mas o custo de transmissão do estado do mundo é.

## 23.5 Sistema (single-player e preparo para multiplayer)

**Objetivo.** Entregar uma experiência single-player completa, mantendo o caminho aberto ao multiplayer.

**Funcionamento.** Salvamento completo, modos e parâmetros, arquitetura desacoplada.

**Dados envolvidos.** Save (estado serializável), Semente, Configurações.

**Relação com outros sistemas.** Todos (por arquitetura).

**Interações do jogador.** Salvar, carregar, configurar, jogar.

**Comportamento autônomo.** Autosave, poda de histórico.

**Consequências.** Confiabilidade e longevidade do mundo.

**Complexidade e prioridade.** Média (single-player) / Muito alta (multiplayer). Prioridade **P0** (salvamento e separação sim/apresentação), **P3** (multiplayer). **[P1]** salvamento completo e arquitetura desacoplada. **[FUT]** qualquer modo multiplayer.

---

# 24. ESCOPO DO PROTÓTIPO INICIAL

## 24.1 Objetivo do protótipo **[PROP]**

Provar **quatro hipóteses**:

1. **O mundo funciona sem o jogador** (simulação estável e interessante).
2. **Os sistemas se comunicam** (cascatas econômicas, políticas e militares observáveis).
3. **O jogador tem opções reais** (pelo menos três trajetórias viáveis e combináveis) **e deixa marcas persistentes**.
4. **A câmera contínua e a simulação em LOD são tecnicamente viáveis** em Godot com um desenvolvedor solo.

O protótipo **não** tem o objetivo de ser bonito, completo ou longo.

## 24.2 Conteúdo do protótipo **[PROP, valores [HIP]]**

| Área | Escopo proposto |
|---|---|
| Região | 1 região autoral, 12 a 30 províncias lógicas, parte delas jogável em 3D detalhado |
| Assentamentos | 1 cidade, 2 a 3 vilas, 1 forte ou posto |
| Pontos de interesse | 1 mina, 1 floresta produtiva, 1 ruína, 1 covil, 1 acampamento de bandidos |
| Culturas | 2 (por parâmetros) |
| População | 150 a 300 indivíduos T1/T2 simulados em detalhe; **T0 agregado fora do primeiro protótipo** (DEC-041) |
| Facções | 3 (autoridade local, organização mercantil, organização criminosa) |
| Polities | **2**: a principal e uma vizinha simplificada (DEC-050 e DEC-051); a terceira fica no backlog |
| Bens | 8 a 12 |
| Cadeias de produção | 4 |
| Mercados | 1 por assentamento, caravanas NPC |
| Eventos | 8 a 12 tipos **[HIP]**; começar com cerca de 6, pois o número é conteúdo em dados |
| Combate | Corpo a corpo, arco, furtividade básica, ferimentos, durabilidade |
| Magia | 0 a 2 efeitos simples **[PEND]** |
| Criaturas | 3 a 4 tipos e 1 chefe |
| Jogador | 3 a 4 origens, habilidades por uso, reputação, mentor simples |
| Trajetórias jogáveis | **Meta de 3** (DEC-062): mercador, soldado/guarda e aventureiro. Produtor/artesão e crime como trajetória: possibilidades futuras |
| Câmera | Terceira pessoa, visão tática simples e mapa estratégico com camadas |
| Interface | Painéis básicos, Crônica, "Por quê?" mínimo |
| Salvamento | Completo |

**Leitura v0.3 do escopo.** *No protótipo:* a tabela acima, com as alterações marcadas em negrito. *Sob corte, nesta ordem de sacrifício (lista 24.5):* magia, chefe, propriedades além da casa, comando tático. *Adiado, preservado no design:* T0 e nível agregado, produtor/artesão, 3ª polity, fundação de facção pelo jogador e tudo o que o cap. 24.3 lista. O que é [HIP] não é requisito.

**Validação cedo (DEC-080).** O teste de combate (SP6) roda logo depois da Fase 1 e o teste de subida de câmera faz parte do SP4a, para não construir quatro fases sem validar a experiência jogável. Na hipótese 4, "LOD de simulação" vale para S0 e S1 no primeiro protótipo.

## 24.3 O que fica fora do protótipo **[CONF/PROP]**

Fundação de organizações pelo jogador, cercos, exércitos grandes, intriga e espionagem, sucessão política complexa, magia ampla, domesticação, múltiplas moedas, famílias e herança, multiplayer, IA generativa, vários continentes, geração procedural de mundo.

## 24.4 Marcos sugeridos **[PROP]**

| Marco | Entrega | Critério de aceite |
|---|---|---|
| M0 Fundações | Passo de simulação, entidades, dados, salvamento, ferramentas de inspeção | Simulação roda e salva sem cena visual |
| M1 Economia | Bens, mercados, produção, caravanas, preços | Soak test econômico estável |
| M2 Sociedade | NPCs T0/T1/T2, necessidades, rotinas | População vive sem intervenção |
| M3 Mundo físico | Terreno, assentamentos, terceira pessoa, LOD de simulação | NPCs aparecem e somem coerentemente |
| M4 Facções, política e eventos | 3 facções, leis, eventos, rumores | Cascatas observáveis |
| M5 Jogador e combate | Combate, atividades, contratos, reputação, crônica | 3 trajetórias viáveis |
| M6 Câmera e UI | Tática, mapa estratégico, "Por quê?" | Transição contínua estável |
| M7 Polimento e validação | Soak tests, playtests, ajuste | Critérios do cap. 25 atendidos |

**Observação:** M0 a M2 podem ser validados **sem gráficos**. Isso reduz risco e acelera a depuração.

## 24.5 Lista de corte (ordem de sacrifício, se o tempo apertar) **[PROP]**

1. Efeitos mágicos.
2. Chefe e criaturas especiais.
3. Construção/expansão de propriedades (manter apenas a casa).
4. Comando tático (manter mapa estratégico de consulta).
5. Facção criminosa completa (manter forma mínima).
6. Eventos de menor impacto.

**Não cortar:** economia conectada, NPCs com rotina, ciclo de facções, crônica/"Por quê?", combate básico, LOD de simulação, salvamento.

## 24.6 Prioridade global dos sistemas (síntese)

| Sistema | Capítulo | Prioridade | Complexidade |
|---|---|---|---|
| Mundo e geografia | 4 | P0 | Média/Alta |
| Cultura | 5 | P1 | Média |
| Jogador e progressão | 6 | P0 | Média |
| Atividades e profissões | 7 | P0 | Média |
| NPCs | 8 | P0 | Alta |
| Rotinas | 9 | P0 | Alta |
| Facções | 10 | P1 | Alta |
| Política | 11 | P1 | Alta |
| Economia | 12 | P0 | Muito alta |
| Recursos e produção | 13 | P0 | Média/Alta |
| Militar | 14 | P1 | Alta |
| Guerra | 15 | P2 | Muito alta |
| Combate | 16 | P0 | Alta |
| Exploração | 17 | P1 | Média/Alta |
| Construção | 18 | P2 | Alta |
| Eventos | 19 | P0 | Alta |
| Consequências | 20 | P0 (mínimo) | Muito alta |
| Interface e câmera | 21 | P0/P1 | Alta |
| Equilíbrio e testes | 22 | P0 | Muito alta |
| Single-player e arquitetura | 23 | P0 | Média |

---

# 25. CRITÉRIOS DE QUALIDADE E SUCESSO

## 25.1 Critérios de sucesso do protótipo (go/no-go) **[PROP]**

O protótipo é bem-sucedido se:

1. **Mundo autônomo:** ao rodar a simulação por um período equivalente a **vários anos de jogo** sem jogador, o mundo permanece estável (sem extinção ou explosão populacional, sem preços fora de faixa, sem facção invencível sem causa), e produz **eventos registrados** com causas rastreáveis.
2. **Sistemas conectados:** ao menos **três cascatas** distintas (como as descritas nos caps. 12, 14 e 19) ocorrem de forma emergente, e o painel "Por quê?" consegue explicá-las.
3. **Liberdade comprovada:** em playtests, jogadores conseguem seguir **três trajetórias** diferentes, combiná-las e se sentirem recompensados por cada uma.
4. **Consequências persistentes:** uma ação do jogador (positiva ou negativa) produz efeito detectável pelo próprio jogador **horas depois**.
5. **Viabilidade técnica:** o jogo roda com a câmera contínua e o LOD de simulação em **hardware-alvo [PEND]** com desempenho aceitável.
6. **Diversão:** jogadores relatam vontade de continuar jogando **por motivos próprios** (não por tarefa), e o jogo gera **histórias contáveis**.

## 25.2 Métricas e metas **[HIP: valores a calibrar]**

| Dimensão | Métrica | Meta proposta |
|---|---|---|
| Desempenho | Quadros por segundo no hardware mínimo | A definir [PEND] (ex.: estável em hardware intermediário) |
| Desempenho | Custo do passo de simulação | Dentro de um orçamento por quadro, sem picos perceptíveis |
| Estabilidade | Soak tests sem jogador | Aprovação em todos os cenários-padrão |
| Estabilidade | Cascatas descontroladas | Nenhuma em testes de perturbação |
| Rastreabilidade | Eventos com causa registrada | 100% dos eventos principais |
| Legibilidade | Jogadores que explicam corretamente uma cascata em playtest | A maioria (a calibrar) |
| Liberdade | Trajetórias distintas viáveis | Pelo menos 3 |
| Persistência | Salvamento e carregamento | Sem perda ou incoerência de estado |
| Ritmo | Decisão ou descoberta significativa por janela de tempo | Dentro da faixa calibrada em playtests |
| Ausência de defeitos | NPCs presos, bloqueios de rotina | Detecção e correção automáticas ou raras |

## 25.3 Perguntas de playtest **[PROP]**

- Você notou algo mudar no mundo sem que você fizesse nada? O que foi?
- Conseguiu descobrir por que algo aconteceu?
- Houve uma situação em que você sentiu que o mundo respondeu a uma decisão sua?
- Qual trajetória você escolheu e por quê? Outras pareciam viáveis?
- Houve momentos de tédio ou de confusão? Quando?
- Que história você contaria a um amigo sobre sua sessão?

## 25.4 Critérios de qualidade de design e documentação **[PROP]**

- Todo sistema passa pelo **portão das seis perguntas** (cap. 3.2).
- Todo parâmetro de balanceamento fica em **dados configuráveis**, não espalhado em lógica.
- Toda decisão relevante tem **status** (confirmada, proposta, hipótese, pendente, limitação).
- Toda decisão pendente tem **dono e prazo** antes da fase em que bloqueia.

---

# ANEXO A. MATRIZ DE SISTEMAS POR FASE

| Sistema | [P1] Protótipo | [PREV] Previsto | [FUT] Futuro | [LP] Longo prazo |
|---|---|---|---|---|
| Mundo | 1 região autoral | Mais regiões | Geração assistida | Múltiplos continentes |
| Culturas | 2 por parâmetros | Contato cultural dinâmico | Espécies | Evolução cultural |
| Jogador | Origens, habilidades por uso, reputação | Herdeiros, línguas | Árvore social complexa | Gerações |
| NPCs | T0/T1/T2, memória limitada | T3 com planos longos, família | IA generativa de fala | Demografia completa |
| Facções | 3 | Facção do jogador, subfacções | Facções transregionais | Instituições históricas |
| Política | Leis, estabilidade, protestos | Sucessão, rebelião, cargos | Intriga, espionagem | Reinos e impérios |
| Economia | 4 cadeias, mercados, caravanas | Crédito, investimento | Bolsa, bancos, inflação | Economias interregionais |
| Militar | Guarnição, patrulhas, bandos | Exércitos, comandantes | Cerco e magia | Campanhas |
| Guerra | Escaramuças, pequenas batalhas | Guerras entre polities | Cercos completos | Guerras multirregionais |
| Combate | Corpo a corpo, arco, furtividade | Magia ampla | Domesticação cooperativa | — |
| Exploração | 4 a 6 locais, 3 a 4 criaturas | Ecologia rica | Domesticação | Mundo imenso |
| Construção | Casa e uma estrutura | Lojas, armazéns, fortificações | Fundação de assentamentos | Cidades do jogador |
| Eventos | 8 a 12 tipos | Eventos encadeados | Sobrenaturais, diretor | História processual |
| Consequências | Crônica, reputação, justiça simples | Reputação multidimensional | Vendetas hereditárias | Legado |
| Câmera/UI | Terceira pessoa, mapa, "Por quê?" | Comando tático | Replay de eventos | — |
| Multiplayer | — | — | Cooperativo com anfitrião | Servidor persistente |

---

# ANEXO B. DEPENDÊNCIAS ENTRE SISTEMAS

Leitura: "A → B" significa que B depende de A (ou é afetado por A).

| Origem | Destinos principais |
|---|---|
| Geografia/Recursos | Economia, Política (fronteiras), Militar (terreno), Exploração |
| Economia | Satisfação (NPCs), Política (tributos), Militar (custos), Facções (financiamento) |
| NPCs/Rotinas | Economia (trabalho e consumo), Eventos (reações), Facções (membros) |
| Política | Economia (leis), Militar (conscrição), Guerra, Estabilidade |
| Facções | Economia, Política, Militar, Exploração (expedições) |
| Militar/Guerra | Economia (destruição, demanda), Política (poder), NPCs (refugiados) |
| Eventos | Todos |
| Crônica/Reputação | NPCs (memória), Facções (relações), Justiça, UI |
| Combate | Economia (equipamento), NPCs (mortes e ferimentos), Crime |
| Exploração | Economia (loot e recursos), Facções (informação), Combate |

**Ordem de construção sugerida [PROP]:** Dados e salvamento → Economia → NPCs e rotinas → Mundo físico e LOD → Facções, política e eventos → Jogador e combate → Câmera e UI.

---

# ANEXO C. CONTRADIÇÕES, RISCOS E LIMITAÇÕES IDENTIFICADAS

| # | Tema | Descrição | Tipo | Mitigação proposta |
|---|---|---|---|---|
| 1 | Escala da simulação | Simular todos os NPCs em detalhe é inviável para dev solo | [LIM] | LOD de simulação, tiers de NPCs |
| 2 | Consistência entre níveis | Agregar e detalhar podem divergir | [LIM] | Testes de equivalência e regras compartilhadas |
| 3 | Câmera contínua | Terreno e LOD em Godot exigem engenharia específica | [LIM] | Chunks, impostors, estilo low-poly; protótipo técnico cedo |
| 4 | Batalhas grandes | Muitos agentes em tempo real são custosos | [LIM] | Resolução agregada e recorte do jogador |
| 5 | Economia emergente | Economias simuladas tendem a colapsar ou explodir | [HIP/Risco] | Suavização, limites, sumidouros, soak tests |
| 6 | Legibilidade | Simulação profunda sem explicação parece arbitrária | [Risco] | "Por quê?", Crônica, rumores |
| 7 | Mundo independente × agência | Pode parecer que nada importa | [Risco] | Escalas de agência, oportunidades abundantes |
| 8 | Magia | Escopo indefinido pode explodir o projeto | [PEND] | Escopo mínimo no protótipo |
| 9 | Multiplayer | Determinismo e rede custam caro | [LIM] | Preservar apenas premissas arquiteturais |
| 10 | IA generativa | Pode contradizer o estado do mundo | [Risco] | Usar só na apresentação, nunca no estado |
| 11 | Salvamento | Crônica e memórias crescem | [LIM] | Poda e agregação |
| 12 | Conteúdo artístico | Muitos tipos de local, criatura e construção exigem arte | [LIM] | Modularidade, estilo low-poly, reaproveitamento |
| 13 | Ajuste fino | Muitos parâmetros interligados | [Risco] | Dados externos, ferramentas de inspeção, soak tests |

---

# ANEXO D. QUESTÕES PENDENTES (DECISÕES DO DESENVOLVEDOR)

| # | Questão | Capítulo | Opções | Recomendação | Necessária antes de |
|---|---|---|---|---|---|
| D1 | Existem espécies não humanas? | 5 | A/B/C | A (apenas humanos no protótipo) | M3 |
| D2 | Modelo de morte e derrota | 6 | A/B/C | B no protótipo, C depois | M5 |
| D3 | Escopo da magia no protótipo | 16 | 0, 1 ou 2 efeitos, ou sistema completo | 0 a 2 efeitos | M5 |
| D4 | Haverá diretor de eventos? | 19 | Sem diretor / leve | Sem diretor no protótipo | M4 |
| D5 | Determinismo dos saves | 22 | Mesmo ambiente / universal | **Decidido (DEC-081):** determinismo no mesmo ambiente, sem replay universal | M0 |
| D6 | Suporte a gamepad | 21 | Sim / não | Não no protótipo | M6 |
| D7 | Hardware-alvo | 25 | Referência / mínimo | **Referência decidida (DEC-016):** a máquina macOS do desenvolvimento. Mínimo: só após o teste de carga | M0 |
| D8 | Domesticação de criaturas | 17 | Incluir / adiar | Adiar | Pós-protótipo |
| D9 | Pólvora e tecnologia avançada | 4 | Sim / não | Não | Pós-protótipo |
| D10 | Nomes, lore e cosmologia | 4, 5 | Definir agora / depois | Definir só o mínimo necessário às culturas e ruínas do protótipo | M3 |

---

# ANEXO E. GLOSSÁRIO

| Termo | Definição |
|---|---|
| Agente | Entidade simulada que decide e age (NPC, caravana, facção) |
| Atividade | Unidade de ação que o jogador ou NPC pode executar |
| Crônica | Registro histórico estruturado de eventos significativos |
| Cascata | Sequência de efeitos entre sistemas disparada por um evento |
| LOD de simulação | Níveis de detalhe da simulação conforme a relevância para o jogador (S0 a S3; só S0 e S1 no protótipo) |
| Organização | Grupo com membros e hierarquia (o gênero). Sem classe própria no protótipo |
| Facção | Organização com vontade política própria (código: `Faction`) |
| Governo | Papel de quem exerce o poder numa polity, exercido pela facção de autoridade. Não é entidade |
| Polity | Unidade política territorial, dona de províncias, leis e diplomacia (código: `PolityState`) |
| Evento | Três sentidos: fato no barramento, registro da crônica, evento de mundo (cap. 19.1) |
| Spike | Protótipo técnico descartável da arquitetura, nomeado SP1 a SP8 |
| Soak test | Teste de longa duração sem jogador, para verificar a estabilidade do mundo |
| Tier | Nível de complexidade de um NPC (T0 a T3; sem T0 no protótipo) |
| Utility | Método de decisão que pontua ações por benefício ponderado |

---

**Fim do documento — versão 0.3.**

