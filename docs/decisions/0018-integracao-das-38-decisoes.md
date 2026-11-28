# Integração das 38 decisões de design ao plano do v0.1

- **Status:** **PROPOSTA, em rascunho para a revisão de Arthur.** Este documento **não altera** DEC, GDD, roadmap, contrato, dado nem código. As emendas da seção 5 são **texto proposto**: só entram em arquivo protegido com o "APROVO" dele, por texto, em PR separado (classe 4). Cada contrato da seção 6 passa por aprovação própria.
- **Data e tarefa:** 28/11/2026 (Brasília). Auditoria de viabilidade e integração das 38 decisões de design (dossiê de 28/11/2026) e preparação do PR documental que Arthur autorizou no mesmo dia. Base: `main` em `95facf7`.
- **Fontes lidas (todas no `main`):** `docs/GDD.md` (6.2, 6.6, 6.7, 16.5, 24); `docs/DEVELOPMENT_ROADMAP.md` (Fases 4 e 5, Anexo E); `docs/DECISIONS.md` (DEC-003, 030, 054, 059, 060, 062, 064, 065, 084, 121, 172, 179 a 184, 190 a 194, 199, 200, 237 e 238); `docs/ROADMAP_STATUS.md`; `docs/fase-5/dados.md`; `docs/modules/*.md`; e o código citado em cada linha. O texto das 38 decisões está em `docs/decisions/0018-anexo-texto-das-38-decisoes.md`.
- **Rótulos:** **decisão de Arthur** (28/11/2026); **fato** (com a fonte); **recomendação** (minha; Arthur aprova ou troca); **pendente**; **[HIP]**.
- **Como ler:** cada item diz primeiro o **efeito** e depois o detalhe. D1 a D6 são as seis decisões que Arthur tomou ao ler a auditoria. "Expansão A a D" são os pacotes de decisões adiadas (seção 4.2).

## 0. O essencial em doze linhas

1. Arthur aprovou em 28/11/2026 a direção do plano: preservar o roadmap atual e fechar **um ciclo jogável completo** antes de expandir o jogo (D1 a D6, com a D5 sob ressalva obrigatória).
2. As 38 decisões são a **visão** do jogo, não autorização para implementar todas no v0.1. O que fica de fora está **adiado, não cancelado** (Expansões A a D, seção 4.2).
3. O v0.1 fecha este ciclo: explorar, encontrar um NPC, aceitar um trabalho, coletar, fabricar, vender, evoluir a proficiência, guardar recursos, descansar e salvar e carregar (seção 4.3).
4. Das 38 decisões: 22 já existem ou estão no plano (2 inteiras e 20 em parte), 10 são novas, 5 conflitavam com decisão aprovada e 1 precisava de esclarecimento. Os cinco conflitos estão resolvidos pelas decisões de Arthur (seção 3).
5. Corte do v0.1: 16 decisões já previstas no plano, 12 acréscimos mínimos para fechar o ciclo, 3 só se houver folga e 7 nas expansões (seção 4.1).
6. Acréscimo líquido de **12 a 21 tarefas** sobre as 61 de hoje (47 oficiais e 14 propostas). Custo extra: **zero**. Os números são ordens de grandeza, sem prazo (seção 8).
7. **Origens exclusivamente narrativas** (ressalva de Arthur à D5): nenhum atributo, bônus ou restrição por origem. Se a ficha de seis atributos entrar, todos começam neutros e iguais.
8. As Fases 3 e 4 e a LW-100 seguem sem interferência. Nada do que está em andamento muda.
9. Emendas propostas (seção 5): 9 itens para o `DECISIONS.md` e linhas do roadmap, do GDD e do `ROADMAP_STATUS.md`. **Nenhuma foi aplicada.**
10. Nove contratos, em ordem (seção 6). **Os contratos 1 a 5 não dependem da conclusão da Fase 4**; os **6, 7 e 9 dependem**; o 8 depende em parte.
11. As três verificações técnicas pendentes da auditoria estão **resolvidas por leitura** (seção 7). Nenhuma muda o corte; duas entram como texto nos contratos 2 e 5.
12. Este PR não faz merge de nada, não toca arquivo protegido e não cria sistema novo.

## 1. O que Arthur decidiu em 28/11/2026

**Decisão de Arthur (mensagem de 28/11/2026):** aprova a direção geral do plano, com estas decisões.

| Decisão | O que ficou decidido |
|---|---|
| D1, opção A | Magia e os sistemas que dependem dela ficam para a **Expansão A**. |
| D2, opção A | A **derrota sem perda substitui os dois modos** anteriores (DEC-181), preservando a **fraqueza temporária**. |
| D3, opção A | Um **ofício completo** de coleta, fabricação e venda **dentro da trajetória do mercador**, sem criar quarta carreira formal. |
| D4, opção A | O v0.1 mantém o **combate híbrido básico**. Bloqueio, esquiva e combate avançado ficam para expansão. |
| D5, opção A, **com ressalva obrigatória** | As **origens continuam exclusivamente narrativas** (Decisão 01). **Não há atributos determinados pela origem.** Se a ficha de seis atributos for incluída, **todos começam com valores neutros e iguais**, sem bônus nem restrição de origem. Pontos por marcos, talentos e redistribuição ficam para a **Expansão B**. |
| D6, opção A | **Casa funcional** desde o início, com **cama, armazenamento persistente e estação básica**. Compra de imóveis, chuva e transporte contratado ficam para expansões. |

**Diretrizes adicionais de Arthur:**

1. As 38 decisões representam a visão planejada do LivingWorld, não autorização para implementar todas no v0.1.
2. As decisões adiadas são preservadas integralmente no planejamento das expansões. Não são funcionalidades canceladas.
3. A prioridade é concluir um ciclo realmente jogável: explorar, encontrar NPC, aceitar trabalho, coletar, fabricar, vender, evoluir proficiência, guardar recursos, descansar e salvar e carregar.
4. As Fases 3 e 4 e a LW-100 seguem normalmente, sem interferências.
5. As três verificações técnicas pendentes da auditoria são registradas e resolvidas antes dos contratos que dependam delas (seção 7).
6. Valem o custo zero adicional, a integridade dos dados e as regras atuais de aprovação.

**Autorização desta etapa:** somente a preparação deste PR documental em rascunho (matriz, conflitos resolvidos, emendas propostas e divisão entre v0.1 e expansões). **Não** autoriza merge deste PR, alteração direta de GDD ou roadmap, desenvolvimento de sistema novo nem contratação de serviço. Cada contrato de implementação da LW-146 exige aprovação separada, com escopo, dependências, testes e critérios de aceite explícitos.

## 2. Matriz de aderência das 38 decisões

**Situação:** *Já existe* (feito e funcionando), *Existe em parte* (planejado ou parcialmente construído), *Nova* (sem tarefa nem código), *Conflito* (contradizia decisão aprovada), *Esclarecer*. **Destino:** *Núcleo* (já previsto no plano), *Acréscimo mínimo* (novo e necessário para fechar o ciclo), *Se houver folga*, ou a *Expansão* (A a D) que preserva a decisão. Os arquivos e linhas são do `main` em `95facf7`.

| # | Decisão | Situação | O que já existe ou está previsto | Conflito ou risco, e como ficou | Destino no v0.1 |
|---|---|---|---|---|---|
| 01 | Origens e classes (A) | Existe em parte | Planejado: LW-149 (3 origens em dados, por lugar de nascimento, DEC-180) e DEC-003 (sem classes rígidas). Código: nenhum ainda; o módulo character só tem identidade, posição e orientação. | Nenhum conflito. **Ressalva de Arthur (D5): origem exclusivamente narrativa**, sem atributo, bônus nem restrição. A LW-149 também prevê itens e habilidades iniciais: ponto a fechar no contrato 1 (seção 3.3). | Núcleo |
| 02 | Progressão híbrida (B) | Existe em parte | Habilidades por uso: LW-147 (SkillUsed, ganho decrescente em dados), ainda sem código. Pontos de atributo em marcos: nova. | DEC-064 (proposta) diz “sem nível global”. Compatível se o marco não for um nível (ver 20). **Resolvido por D5: pontos por marco na Expansão B.** | Núcleo (uso); Expansão B (pontos por marco) |
| 03 | Árvores pequenas de talentos (B) | Nova | Nada: sem tarefa, decisão nem código. Só aparece “árvore social complexa [FUT]” no Anexo A do GDD. | Sem o que escolher: com 4 habilidades e sem pontos (20), as árvores ficam vazias. **Resolvido por D5: Expansão B.** | Expansão B |
| 04 | Profissões livres (B) | Existe em parte | NPCs têm ofícios em dados (lavrador, lenhador, artesão e outros). Jogador: só comércio (LW-147) e mentor (LW-161). “Sem turnos obrigatórios” já é a regra para encomendas (DEC-237). | “Produtor e artesão” está no backlog (Anexo E) e no GDD 24.2 como possibilidade futura (D3). Os patamares Aprendiz, Profissional e Mestre são novos: marcos de proficiência em dados. **Resolvido por D3: um ofício dentro do mercador.** | Acréscimo mínimo |
| 05 | Combate em tempo real (B) | Existe em parte | SP6 jogado por você em 07/11 (LW-152 concluída). LW-150 a 156 planejam golpe pesado, rápido e perfurante, arco, estamina e ferimento simples. Código de combate: nenhum (src/sim/combat só tem README). | Bloqueio e esquiva: DEC-182 (aprovada) deixa para depois, com novo playtest após a LW-155. Besta e arremesso: sem tarefa. Combos e aparadas já são expansão no dossiê. **Resolvido por D4: bloqueio e esquiva na Expansão C.** | Núcleo (SP6 e arco); Expansão C (bloqueio, esquiva, combos) |
| 06 | Magia inicial (B) | Conflito | Nada: sem código, tarefa nem contrato. A forma da magia (DEC-030) segue pendente. | DEC-179 (aprovada em 11/11): sistema de magia fora da Fase 5. DEC-054 (aprovada): magia ampla fora. GDD 24.5: primeiro item de corte. Sem sistema de partículas hoje. **Resolvido por D1: Expansão A.** | Expansão A |
| 07 | Categorias de equipamento (B) | Existe em parte | LW-148 (equipamento como instância) e LW-150 (tabelas em dados). Partida da Fase 5: espada, armadura leve e armadura pesada (docs/fase-5/dados.md). | O GDD 16.5 lista outras categorias (lanças, maças, bestas, adagas; tecido, couro, malha, placa). DEC-182 deixa “mais armas” para depois. Escudo precisa de bloqueio e cajado precisa de magia. **Resolvido por D4 e D1: escudo na Expansão C, cajado na Expansão A.** | Acréscimo mínimo (espada, machado, arco; 3 armaduras); Expansão C (escudo); Expansão A (cajado) |
| 08 | Criaturas ativas (B) | Existe em parte | LW-157 (3 tipos em dados: patrulhar, caçar, fugir; DEC-180), LW-155 (combate dos NPCs), LW-160 (covil). A pasta ecology ainda está vazia. | “Criaturas fantásticas” com ataque característico: DEC-179 deixa fora criaturas especiais e chefe. Drops: a regra “todo bem nasce de uma receita” (backlog 230) pede uma exceção formal. **Pelo corte: 3 tipos no v0.1; fantásticas e chefes na Expansão D.** | Núcleo (3 tipos); Expansão D (fantásticas e chefes) |
| 09 | Coleta pelo jogador (B) | Nova | Só NPCs coletam, por receitas de extração (mine_ore, cut_wood, grow_grain em data/economy/recipes.json). Nenhuma tarefa para o jogador; “regenera” não existe. GDD: nós de recurso simples [P1]. A DEC-237 (aprovada) já cita coletar e produzir entre as atividades do jogador por objetivos. | Cria bens: precisa seguir “um bem, uma receita” e a conservação (teste de ouro do Ledger). Compete com NPCs: nó com estoque finito e regeneração, para não desfazer o equilíbrio da economia. **Resolvido por D3.** | Acréscimo mínimo |
| 10 | Fabricação pelo jogador (B) | Existe em parte | LW-148 prevê UMA receita de ferreiro: a economia destrói o metal com motivo fechado, publica GoodsForged e o character cria a instância (DEC-193, proposta; economy.md 18.3). NPCs fabricam por receita (smelt_metal, forge_tool). | Passar a várias receitas, estações e qualidade é dado mais a sessão de produção (26 e 27). DEC-190 e DEC-193 ainda são propostas. **Resolvido por D3.** | Acréscimo mínimo |
| 11 | Alquimia (B) | Nova | Nada: o GDD só cita “alquimista [PREV]”. Hoje só “comer” tem efeito de consumo. | Poções de mana e de proteção elemental dependem de magia. Precisa de consumíveis com efeito no personagem e de ervas (coleta). **Resolvido por D1: Expansão A.** | Expansão A |
| 12 | Encantamento (B) | Conflito | Nada em tarefa, dado ou código. | Efeito mágico em item é “item de poder”: fora pela DEC-179. Depende de magia (06) e de qualidade (13). **Resolvido por D1: Expansão A.** | Expansão A |
| 13 | Qualidade e raridade (B) | Existe em parte | LW-148: instância com qualidade, durabilidade e peso; a qualidade é um número de 1 a 100 (docs/fase-5/dados.md). | A decisão pede 3 níveis (Comum, Bem-feito, Excelente) e raridade (Comum, Raro): os 3 níveis saem de faixas do número; raridade é um campo novo. GDD: categoria “mágico” é futura. **Resolvido por D3: 3 níveis no v0.1; raridade com afixos na Expansão D.** | Acréscimo mínimo (3 níveis); Expansão D (raridade com afixos) |
| 14 | Exploração e trabalhos orgânicos (B) | Existe em parte | Contratos (labor, delivery, vacancy: LW-096 e LW-107), pontos de interesse (LW-160), 8 eventos dinâmicos que geram demanda (LW-162), escolta (LW-139). GDD 497: “o mundo gera demandas”. | Recompensa em item e progressão: a LW-160 só dá conhecimento. Fica simples. | Núcleo |
| 15 | Facções e carreira militar voluntária (B) | Existe em parte | Fase 4 planejada: LW-120 (postos), LW-128 (reputação por facção, 5 faixas), LW-141 (ingresso e promoção do jogador), LW-136 (missões das forças). As pastas factions e military ainda estão vazias. | Nenhum: comando de tropas e facção criminosa completa já estão fora (DEC-179) e o dossiê também adia guerras grandes. | Núcleo (Fase 4) |
| 16 | Estado compartilhado do mundo (B) | Já existe | Economia fechada com Ledger e state_hash (DEC-172), contexto e IDs únicos, contratos, mercado e NPCs na mesma simulação (Fases 2 e 3). Coleta, fabricação, combate e facções entram pelo mesmo padrão. | Risco de disciplina: todo sistema novo precisa de serialize, validate e teste de conservação (já é a regra). | Núcleo |
| 17 | Combate híbrido (B) | Existe em parte | SP6: alvo por clique, ataque automático, habilidades com preparo e recuperação. LW-153 (jogador) e LW-153b (HUD, proposta). | Compatível com a DEC-182. “Interrompível” não foi confirmado no SP6; vira critério da LW-153. | Núcleo |
| 18 | Controles iniciais (A) | Conflito | project.godot tem mover, correr (Shift), pular (Espaço), interagir (E), pausa (P), olhar e zoom pelo mouse. Faltam teclas 1 a 4, ações de combate, esquiva e bloqueio. A LW-175 inclui remapeamento. | Espaço é “pular” hoje e “esquiva” na decisão. Esquiva e bloqueio são DEC-182 (depois). **Resolvido por D4: Espaço e botão direito ficam reservados (Expansão C).** | Acréscimo mínimo (clique, teclas 1 a 4, zoom); Expansão C (Espaço, botão direito) |
| 19 | Seis atributos (B) | Nova | Nada em código ou tarefa. GDD 6.2: “poucos e de apoio; hipótese de 4 a 6”. | **Ressalva de Arthur (D5):** se a ficha entrar, todos os atributos começam **neutros e iguais**, sem bônus nem restrição de origem. Sem magia, Inteligência e Sabedoria teriam pouco efeito. DEC-064 (proposta) trata a progressão sem nível global. | Se houver folga (ficha neutra) |
| 20 | Pontos de atributo por marcos (B) | Esclarecer | Nada. O próprio dossiê deixa valores, limites e frequência para balancear. | O que conta como “marco geral” sem nível global não está definido (DEC-064, proposta). **Resolvido por D5: Expansão B.** | Expansão B |
| 21 | Derrota sem perda de bens (A) | Conflito | Nada em código. Planejado: LW-156 e as propostas LW-148a, 156a, 156c, 156d e 156e (DEC-181). | DEC-181 (aprovada em 11/11): dois modos à escolha, com itens soltos no chão por um tempo ou volta ao autosave. A decisão 21 é um modo único sem perda e elimina 4 tarefas núcleo propostas. **Resolvido por D2: derrota única, com fraqueza temporária.** | Núcleo (derrota única) |
| 22 | Durabilidade e reparos (B) | Existe em parte | LW-148 e LW-156: durabilidade, ItemBroken e “item quebrado deixa de funcionar”. Reparo: DEC-193 (proposta) manda para depois; ferreiro NPC e reparo estão no backlog. | Reparo pelo jogador (materiais, estação, proficiência) é novo e depende do ofício. Qualidade reduzir o desgaste não está previsto. **Resolvido por D3: desgaste no v0.1; reparo na Expansão D.** | Acréscimo mínimo (desgaste, sem reparo); Expansão D (reparo) |
| 23 | Inventário e carga (B) | Existe em parte | Peso e capacidade por dono na economia (goods.json, GoodsStore: LW-089 concluída). LW-148 (instâncias com peso) e LW-148b (tela, proposta). Baú: um tipo de dono novo, no padrão do “flow”. | O GDD 16.5 diz que peso e carga afetam estamina e velocidade; a decisão não quer penalidade gradual (limite duro). Sigo a decisão e atualizo o GDD na LW-189. | Núcleo |
| 24 | Catálogo inicial compacto (A) | Nova | Ainda não há items.json nem weapons.json. Partida: espada e 2 armaduras. GDD 16.5 mira 5 a 6 armas e 3 a 4 níveis de armadura no protótipo. | Os 2 efeitos de encantamento dependem de magia (D1). Escudo e cajado dependem de bloqueio e magia. **Resolvido por D3 e D1.** | Acréscimo mínimo (só dados); Expansão A (2 efeitos de encantamento) |
| 25 | Aprendizado contextual de receitas (B) | Nova | Nada: recipes.json liga a receita ao ofício de NPC, não a uma “receita conhecida” do personagem. A LW-161 (mentor) ensina habilidade, não receita. | Cinco fontes (marcos, instrutores, livros, exploração e contratos) são demais para o v0.1. **Resolvido por D3: marco e instrutor no v0.1; livros e exploração na Expansão D.** | Acréscimo mínimo (marco e instrutor); Expansão D (livros e exploração) |
| 26 | Produção garantida (A) | Existe em parte | A produção dos NPCs é determinística e sem sorteio (production_book.gd). Para o jogador: nova. A pergunta 7 de docs/fase-5/dados.md (habilidade de forja) está aberta e recomendava qualidade só pela receita. | A decisão responde essa pergunta: a qualidade varia com a proficiência. Pede uma 5ª habilidade (forja) em skills.json. **Resolvido por D3.** | Acréscimo mínimo |
| 27 | Produção curta e visual (B) | Nova | NPCs produzem por hora (batch_progress_bp) e o estado do lote é salvo na economia. Jogador: sem sessão de produção, barra nem animação. | Principal risco do ciclo: interrupção (fechar o jogo no meio) sem duplicar nem perder item. Exige sessão persistente e teste de interrupção. **Resolvido por D3.** | Acréscimo mínimo |
| 28 | Diálogos contextuais simples (B) | Existe em parte | A conversa existe: interaction_view e npc_player_talk (LW-083c: promoção, relação e memória). Frases parametrizadas, sem IA generativa (GDD 8.8). O contexto “diálogo” está na LW-172. | Serviços do ofício e respostas por reputação dependem da Fase 4 (reputação) e do ofício (D3). | Núcleo |
| 29 | Diário e mapa contextual (B) | Existe em parte | Mapa com visibilidade por tipo (LW-169, 169a e 171; DEC-184), Crônica e “Por quê?” (Fase 4), painel de encomendas (LW-107f4), painéis da LW-173. | Falta o “objetivo acompanhado na interface”. É pequeno. | Núcleo |
| 30 | Transporte entre cidades (B) | Nova | Nada para passageiros. O GDD aceita viagem rápida “com custo, sem congelar o mundo” (linha 1578), compatível. As caravanas NPC existem e não levam passageiros. | As rotas atuais levam de 1,6 a 2,4 horas de jogo: o serviço rende pouco no mundo do v0.1. Exige estado de viagem salvo. **Resolvido por D6: Expansão D.** | Expansão D |
| 31 | Sobrevivência leve (B) | Nova | NPCs têm necessidades em dados (need_def.gd; lethal_after_hours decide se a necessidade mata). O jogador não tem. O GDD 6.7 já prevê fome e descanso leves, ligados à economia. | Nenhum: com lethal_after_hours igual a 0 o jogador não morre de fome. A assimetria é deliberada: NPCs podem morrer de fome (economia). **Entra se houver folga (D6, opção A).** | Se houver folga |
| 32 | Redistribuição de build (B) | Nova | Nada. Depende de atributos (19), pontos (20) e talentos (03). | Sem esses três, não há o que redistribuir. **Resolvido por D5: Expansão B.** | Expansão B |
| 33 | Moradia pessoal simples (B) | Conflito | A casa do jogador é um local home do mundo (DEC-179), exibida na LW-173. Baú e cama: novos. | DEC-179 (aprovada): casa sem compra, venda nem expansão; a decisão quer comprar, com custo real. GDD: casa [P1], compra ou aluguel [P2]. **Resolvido por D6: casa funcional; compra na Expansão D.** | Acréscimo mínimo (casa funcional); Expansão D (compra) |
| 34 | Ciclo temporal e clima leve (B) | Existe em parte | Relógio com hora do dia (SimClock), rotinas de NPC por horário (routine_table), ambiente e luz na apresentação (ambient_rig). Clima: nada. | DEC-060 (proposta) põe clima e estações fora; o GDD aceita clima simples se ela for rejeitada. Clima com efeito na simulação mexe em NPC e produção. **Resolvido por D6: dia e noite no v0.1; chuva na Expansão D.** | Núcleo (dia e noite); Expansão D (chuva) |
| 35 | Mundo pausado com o jogo fechado (A) | Já existe | O relógio só anda com o jogo aberto (simulation_runner, SimClock.set_paused). Prazos de contrato são minutos de simulação. O soak de 3 anos sem jogador é teste, não recurso do jogo. | Nenhum. Falta um teste de regressão: fechar e reabrir não avança o relógio nem vence contrato. | Núcleo |
| 36 | Salvamento robusto (B) | Existe em parte | save_store.gd: grava .tmp, confere, gira 3 backups e promove; carrega o primeiro íntegro; versão e migração (DEC-084). Planejado: LW-174 (completo), LW-176 (autosave e slots), LW-182. | “Salvar só quando seguro” e “autosave por eventos” são novos. Limitação documentada: sem fsync, uma queda de energia exatamente na gravação pode perder o save mais novo (o anterior fica). | Núcleo |
| 37 | Contratos normais e urgentes (B) | Existe em parte | ContractBook: labor, delivery e vacancy; prazo opcional (deadline 0 é sem prazo); abandono (LW-107f1, DEC-238); custódia da recompensa. Faltam: tipo urgente, prazo visível antes de aceitar, recompensa maior, perda leve de reputação (Fase 4). | DEC-238 fixou “sem penalidade de reputação nas encomendas simples nesta versão”: o urgente precisa ser uma modalidade separada. **Entra se houver folga.** | Se houver folga |
| 38 | Mercado com oferta e demanda (B) | Existe em parte | Preço em faixas (piso, teto, spread, profundidade: DEC-139, 150 e 177), mercado jogável aceito em 13/11 (LW-106), conservação de moeda e bens por teste. A base está pronta. | Faltam qualidade no valor do item e indicador de demanda. Qualidade entra como multiplicador no valor da instância, sem mexer em PriceMath e MarketBook (guarda de hash, DEC-175). “Comerciantes por ofício” é detalhe de contrato. | Núcleo (qualidade no valor: acréscimo mínimo) |

## 3. Conflitos e como ficaram resolvidos

### 3.1 Com decisões aprovadas

| Tema | Decisões do dossiê | Decisão anterior | Resolução |
|---|---|---|---|
| Magia e itens de poder | 06, 12, partes de 11 e 24 | DEC-179 e DEC-054 (aprovadas); GDD 24.5 (primeiro item de corte) | **D1:** Expansão A, com contrato próprio e ganchos de dados reservados. |
| Derrota do jogador | 21 | DEC-181 (aprovada): dois modos à escolha | **D2:** a derrota única sem perda substitui os dois modos. |
| Bloqueio e esquiva | 05, 18; escudo em 07 e 24 | DEC-182 e DEC-121 (aprovadas) | **D4:** fora do v0.1; ações de entrada reservadas; novo playtest após a LW-155 antes da Expansão C. |
| Casa com compra | 33 | DEC-179 (aprovada): casa sem compra, venda nem expansão | **D6:** casa funcional já dada; compra na Expansão D. |
| Criaturas fantásticas e chefe | 08 | DEC-179 e DEC-180 (aprovadas): 3 criaturas genéricas, sem chefe | Pelo corte: 3 tipos no v0.1; fantásticas e chefes na Expansão D. |
| Mais categorias de armas | 07, 24 | DEC-182: "mais armas e habilidades" depois | Pelo corte: só dados (espada, machado e arco; armaduras leve, média e pesada); escudo na Expansão C e cajado na A. |
| Trajetória de produtor | 04, 09, 10, 25 a 27 | DEC-062 (meta de 3 trajetórias) e Anexo E (backlog) | **D3:** um ofício dentro da trajetória do mercador, sem quarta carreira. |

### 3.2 Com propostas abertas, com o texto do GDD e com regras da economia

| Ponto | Resolução proposta |
|---|---|
| DEC-064 (PROPOSTA, "sem nível global") e as decisões 19 e 20 | **D5:** ficha de seis atributos neutra, sem origem; pontos por marco só na Expansão B. A DEC-064 pode ser aprovada com esse ajuste (seção 5.1, item 8). |
| DEC-060 (PROPOSTA, clima e estações fora) e a decisão 34 | **D6:** chuva e clima ficam fora do v0.1 e preservados na Expansão D. A DEC-060 pode ser aprovada como "fora do v0.1" (item 7). |
| DEC-193 (PROPOSTA: fronteira entre equipamento e economia; reparo depois) e as decisões 10 e 22 | A fronteira serve a todas as receitas do jogador (contrato 4). O reparo fica na Expansão D (item 9). |
| GDD 16.5: "peso e carga influenciam estamina e velocidade" e a decisão 23 | Vale a decisão: **limite de carga duro, sem lentidão gradual**. O GDD é emendado (seção 5.3). |
| GDD 16.5: categorias de armas e armaduras e as decisões 07 e 24 | Vale a decisão, com o corte do v0.1. O GDD é emendado (seção 5.3). |
| GDD 24.2 ainda lista "magia, 0 a 2 efeitos" e "1 chefe", que a DEC-179 e a DEC-180 já retiraram | O GDD é emendado (seção 5.3). |
| `docs/fase-5/dados.md`, pergunta 7 (habilidade de forja; recomendava qualidade só pela receita) e a decisão 26 | A decisão 26 responde: a **qualidade varia com a proficiência**. Entra uma habilidade de ofício (forja) em `skills.json`, a fechar no contrato 4. |
| Regra da economia "todo bem nasce de exatamente uma receita" (`production_loader`, backlog 230) contra coleta e drops (08 e 09) | A coleta do jogador **executa a mesma receita de extração dos NPCs** (`mine_ore`, `cut_wood`, `grow_grain`) num nó com estoque finito e regeneração. Drops vão direto à mochila. O contrato 3 formaliza a exceção "fonte natural". |

### 3.3 Ponto que a ressalva do D5 abre (a fechar no contrato 1)

**Pendente.** A LW-149 hoje prevê origens com "itens, habilidades, relações iniciais e local de partida" (`DEVELOPMENT_ROADMAP.md`, linha da LW-149). A ressalva de Arthur diz que as origens são **exclusivamente narrativas**. **Recomendação (minha):** a origem define local de partida, história e relações iniciais; o kit inicial é **igual para as três origens** e nenhuma origem dá nível inicial de habilidade. Arthur decide ao aprovar o contrato 1; até lá, nada de atributo, bônus ou restrição por origem.

## 4. O v0.1 e as expansões

### 4.1 Corte do v0.1

| Faixa | Decisões | O que significa |
|---|---|---|
| **Núcleo (16)**, já previsto no plano | 01, 02 (uso), 05, 08, 14, 15, 16, 17, 21 (derrota única), 23, 28, 29, 34 (dia e noite), 35, 36, 38 | O roadmap e as Fases 3 e 4 já entregam ou preparam. Sem acréscimo de tarefa além dos ajustes da seção 5. |
| **Acréscimo mínimo (12)**, para fechar o ciclo | 04, 07, 09, 10, 13, 18, 22, 24, 25, 26, 27, 33 | Giram em torno de **um ofício**: 2 coletas (madeira e minério), 1 oficina, 3 a 4 receitas, qualidade em 3 níveis, produção curta com barra, casa com cama, baú e estação. |
| **Se houver folga (3)** | 19 (ficha neutra de seis atributos), 31 (fome e fadiga leves), 37 (contratos urgentes) | Baratos e aprovados, mas o ciclo não depende deles. Entram um por vez, depois do teste do ciclo. |
| **Expansões (7 inteiras)** | 03, 06, 11, 12, 20, 30, 32 | Expansão A: 06, 11, 12. Expansão B: 03, 20, 32. Expansão D: 30. |

### 4.2 Expansões preservadas (adiadas, não canceladas)

| Expansão | Decisões preservadas | O que preservar do texto aprovado | Ganchos que os contratos do v0.1 não podem fechar | Porta de entrada |
|---|---|---|---|---|
| **A. Magia e ofícios mágicos** | 06, 11, 12; cajado (07) e 2 efeitos de encantamento (24) | 3 escolas (Fogo, Gelo e Cura), 1 a 2 magias por escola, mana, proficiência por uso e talentos simples. Alquimia com ervas e ingredientes de criaturas, poções de vida, mana e proteção elemental, estação própria. Encantamento como profissão evolutiva, um efeito por item, estação própria. | Campo opcional de efeito no item (vazio no v0.1); recurso de custo da habilidade em dados (hoje só a estamina); estação por tipo. | Decisão de Arthur sobre a forma da magia (DEC-030, pendente), contrato próprio e efeitos visuais (hoje não há sistema de partículas). |
| **B. Progressão por atributos e talentos** | 03, 20, 32 (e 19, se não entrar antes) | Árvores pequenas de talentos em marcos de proficiência; pontos limitados por marcos gerais de evolução, sem nível global tradicional; redistribuição em local seguro por custo monetário moderado, sem remover proficiências. **Ficha neutra e origens narrativas (ressalva do D5).** | Ficha com valores neutros e iguais; marcos de habilidade expostos em dados; "local seguro" definido (casa e estalagem). | Dados de jogo do ofício e das habilidades para equilibrar; definição de "marco geral". |
| **C. Combate avançado** | partes de 05 e 18; escudo (07 e 24) | Bloqueio (botão direito), esquiva com estamina (Espaço), combos, aparadas, besta e arremesso, reações a acertos. | Espaço e botão direito livres no v0.1 (hoje Espaço é "pular"; o remapeamento já está na LW-175); estados do combatente extensíveis. | Novo playtest de Arthur depois da LW-155 (DEC-182). |
| **D. Mundo e ofícios ampliados** | 30; chuva (34); compra de imóveis (33); criaturas fantásticas e chefes (08); mais categorias de armas (07 e 24); reparo pago e pelo jogador (22); livros e exploração como fonte de receita (25); raridade com afixos (13) | Transporte de passageiros entre locais já descobertos, com tarifa e bagagem; chuva com efeito leve; compra de casa; criaturas com ataque característico; reparo com materiais, estação e proficiência ou por serviço pago. | Estado de viagem no formato do save; campo de raridade em dado; "serviço" como tipo no mercado; estação por tipo. | v0.1 concluído e contrato próprio por item. |

### 4.3 O ciclo jogável (critério de aceite do v0.1)

**Decisão de Arthur (diretriz 3):** o v0.1 precisa fechar um ciclo realmente jogável. O roteiro, com as decisões que cada passo exercita:

1. **Explorar:** sair do povoado e descobrir um ponto de interesse (LW-160).
2. **Encontrar um NPC:** conversa com personalidade básica e serviço do ofício (28).
3. **Aceitar um trabalho:** encomenda do quadro de contratos, sem turno obrigatório (04, 37 normal, LW-107).
4. **Coletar:** dois recursos em nós persistentes, com ferramenta e proficiência, dentro do limite de carga (09, 23).
5. **Fabricar:** aprender uma receita (por marco ou instrutor), usar a oficina, produção curta com barra e animação, qualidade por proficiência (10, 13, 25, 26, 27).
6. **Vender:** a preço de mercado, com moeda e itens em sincronia, e valor por qualidade (38).
7. **Evoluir a proficiência:** a habilidade do ofício sobe pelo uso (02, 04); a reputação entra depois da Fase 4.
8. **Guardar recursos:** baú persistente da casa (23, 33).
9. **Descansar:** cama da casa, que recupera e passa o tempo (33).
10. **Salvar e carregar:** fechar e reabrir devolve o mesmo estado; o relógio não anda com o jogo fechado (35, 36).

**Verificações do cenário (teste scriptado):** (a) conservação de bens e de moeda (teste de ouro) com o jogador em ação; (b) `state_hash` igual depois de salvar e carregar; (c) fechar o jogo no meio da fabricação: ou o item foi entregue ou os materiais continuam, nunca os dois e nunca nenhum; (d) o mesmo para o comércio; (e) nenhum item duplicado; (f) valores de referência da economia sem jogador iguais aos de hoje (DEC-175). O cenário entra na LW-184 (playthrough) e no soak da LW-183.

## 5. Emendas documentais propostas (texto proposto; nada foi aplicado)

Tudo abaixo é **proposta**. Aplicar exige o "APROVO" de Arthur, por texto, em PR separado de classe 4 (arquivos protegidos: AGENTS 12.5). Os números das DEC novas serão atribuídos na integração.

### 5.1 `docs/DECISIONS.md` (9 itens)

| # | Item | Texto proposto |
|---|---|---|
| 1 | **Emenda à DEC-181** (derrota e morte do jogador) | "Com vida zero, o jogador reaparece no último local seguro, mantém equipamento, dinheiro e recursos e sofre uma fraqueza temporária leve. Não há cadáver recuperável, itens soltos no chão por perda nem escolha de modo. Substitui os dois modos (renasce perto e volta ao autosave). A DEC-065 passa a refletir esta regra." |
| 2 | **Emenda à DEC-179** (corte do protótipo) | "A casa do jogador deixa de ser só um local do mundo: é uma casa funcional desde o início, com cama, armazenamento persistente e estação básica, ainda sem compra, venda nem expansão. Magia e itens de poder continuam fora da Fase 5 e ficam preservados como Expansão A." |
| 3 | **Emenda à DEC-182** (combate da Fase 5) | "O v0.1 mantém o combate híbrido básico: o primeiro clique seleciona o alvo; o segundo clique ou um comando inicia o ataque automático, que pode ser interrompido; habilidades nas teclas 1 a 4; estamina, posição e ferimento simples. Bloqueio, esquiva, combos, aparadas e escudo ficam como Expansão C, depois do novo playtest que a DEC-182 já exige." |
| 4 | **DEC nova:** o ofício do jogador no v0.1 | "O v0.1 inclui um ofício completo do jogador (coletar, fabricar e vender) dentro da trajetória do mercador, sem quarta trajetória formal; a DEC-062 mantém a meta de três. Coleta de 2 recursos, 3 a 4 receitas, 2 formas de aprender (marco e instrutor), produção curta e qualidade por proficiência." |
| 5 | **DEC nova:** origens narrativas e ficha neutra | "As origens são exclusivamente narrativas: nenhum atributo, bônus ou restrição é determinado pela origem. Se a ficha de seis atributos entrar, todos começam neutros e iguais. Pontos por marcos, talentos e redistribuição ficam na Expansão B." |
| 6 | **DEC nova:** visão, expansões e critério de aceite | "As 38 decisões de 28/11/2026 são a visão do jogo, não autorização para implementar todas no v0.1. As decisões adiadas ficam preservadas nas Expansões A a D. O critério de aceite do v0.1 é o ciclo jogável da seção 4.3 deste registro." |
| 7 | **DEC-060** (PROPOSTA): clima e estações | Aprovar com o ajuste: "fora do v0.1; preservado como Expansão D". |
| 8 | **DEC-064** (PROPOSTA): progressão sem nível global | Aprovar com o ajuste: "compatível com a ficha neutra de atributos; pontos por marco só na Expansão B". |
| 9 | **DEC-193** (PROPOSTA): fronteira entre equipamento e economia | Aprovar com o ajuste: "vale para todas as receitas do jogador (contrato 4); reparo na Expansão D". |

### 5.2 `docs/DEVELOPMENT_ROADMAP.md`

| Linha | Hoje | Proposta |
|---|---|---|
| LW-146 (nota) | Contratos e corte de escopo | Acrescentar nota: as 38 decisões de 28/11/2026 entram como emendas; contratos 1 a 9 (seção 6). |
| LW-147 | 4 habilidades por uso (corpo a corpo, arco, furtividade, comércio) | Acrescentar as habilidades do ofício (coleta e forja), a fechar nos contratos 3 e 4. |
| LW-148 | Instâncias com qualidade, durabilidade e peso; uma receita de ferreiro | Qualidade em 3 níveis (Comum, Bem-feito, Excelente), pilhas, limite de carga duro; a fronteira da DEC-193 serve a todas as receitas do jogador. |
| LW-148a, 156a, 156c, 156d, 156e (propostas) | Itens ligados, itens no chão, modo "renasce perto", modo "voltar ao autosave", "quem pegou o item" | **Retirar das propostas** (D2). O texto fica no histórico; "itens no chão" fica no backlog como ideia. |
| LW-148b | Tela de inventário e equipamento | Mantém; inclui o baú. |
| LW-149 | 3 origens com itens, habilidades, relações e local de partida | Origens exclusivamente narrativas; sem atributo, bônus nem restrição (D5). Kit e habilidades iniciais: seção 3.3. |
| LW-153 | Alvo por clique, ataque automático e habilidades do SP6 | Início do ataque automático por segundo clique ou comando e interrupção por comando; teclas 1 a 4; zoom por rolagem; sem bloqueio nem esquiva (D4). |
| LW-156 | Dois modos de derrota à escolha | Derrota única sem perda, com fraqueza temporária (D2). Item com durabilidade 0 para de funcionar e não é destruído. |
| LW-160 | Mina e floresta ligadas à produção | Nós de recurso coletáveis pelo jogador (2 recursos), com estoque finito e regeneração. |
| LW-161 | Mentor ensina uma habilidade | Também ensina uma receita. |
| LW-173 | Painéis, inclusive "propriedades (a casa)" | A casa funcional (cama, baú, estação) não depende do painel. |
| LW-175 | Novo jogo com escolha de origem e do modo de morte | Sem escolha do modo de morte. |
| LW-176 | Autosave frequente para o modo "voltar ao autosave" | Autosave periódico e por eventos; salvar manual só quando seguro. |
| LW-184 | Playthrough das três trajetórias | Inclui o ciclo do ofício dentro da trajetória do mercador, com interrupção da fabricação e do comércio (seção 4.3). |
| Anexo E | "Produtor e artesão": backlog "se você escolher esta trajetória na LW-146" | Resolvido pela D3: ofício dentro do mercador. A quarta trajetória segue no backlog. |
| **Tarefas novas propostas** (sem ID oficial) | 14 propostas hoje | Retirar 5 (acima). Acrescentar cerca de 17, até 26 se alguma se dividir pelo limite de tamanho (AGENTS 5.2): nó de recurso e estado regenerável; comando de coleta; local oficina e estação; sessão de produção; interrupção e save no meio da sessão; receitas conhecidas; aprender por marco e por instrutor; qualidade por proficiência; valor por qualidade e recompra; interface da coleta; interface da oficina; teste do ciclo do ofício; cama e descanso; baú persistente; estação da casa; início e interrupção do ataque automático; qualidade em 3 níveis. |

### 5.3 `docs/GDD.md`

| Seção | Hoje | Proposta |
|---|---|---|
| 6.2 (atributos) | "Poucos e de apoio. Hipótese: 4 a 6" | Seis atributos (Força, Destreza, Constituição, Inteligência, Sabedoria e Carisma), distintos das habilidades; se incluídos, neutros e iguais no início; a origem não os altera. |
| 6.6 (derrota) | Opções A, B e C | Adotar a derrota única sem perda, com fraqueza temporária. |
| 16.5 (peso) | "Peso e carga influenciam estamina e velocidade" | Limite de carga duro, sem lentidão gradual. |
| 16.5 (armas e armaduras) | Lista de categorias do GDD | v0.1: espada, machado e arco; armaduras leve, média e pesada. Demais categorias nas expansões. |
| 24.2 | Magia 0 a 2 efeitos; 1 chefe; 3 a 4 origens | Magia 0; sem chefe; 3 origens exclusivamente narrativas. |
| 24.2 (trajetórias) | Produtor e artesão: possibilidade futura | Ofício completo dentro da trajetória do mercador. |
| Notas de clima | "Clima simples só se a DEC-060 for rejeitada" | Clima fora do v0.1, preservado na Expansão D. |

As mudanças do GDD entram na LW-189 (documentação as-built) ou antes, por aprovação dele.

### 5.4 `docs/ROADMAP_STATUS.md` (tabela "Itens dentro e fora do protótipo")

| Linha | Proposta |
|---|---|
| "Dois modos de morte à escolha (DEC-181)" | "Derrota única sem perda, com fraqueza temporária (emenda à DEC-181)". |
| "A casa do jogador, sem compra, venda nem expansão (DEC-179)" | "Casa funcional com cama, baú e estação, sem compra, venda nem expansão". |
| Dentro | Acrescentar "ofício completo do jogador (coletar, fabricar e vender) dentro do mercador". |
| Fora | Acrescentar "Expansões A a D, preservadas"; trocar "clima e estações" por "chuva e clima (Expansão D)". |

### 5.5 Contratos de módulo (`docs/modules/*.md`)

Cada emenda de contrato só aparece no PR do respectivo contrato (seção 6), com aprovação própria.

## 6. Sequência recomendada dos contratos de implementação

### 6.1 O que cada contrato precisa trazer

Cada contrato é um PR de documento com aprovação separada de Arthur e contém: **escopo** e **fora de escopo**; **dependências**; dados, comandos, consultas, eventos e erros; **testes** (unitários, mutantes, integração, guarda dos valores de referência da economia, DEC-175); **critérios de aceite** objetivos; riscos; e a declaração de **custo zero** (sem serviço, API nem asset pago).

### 6.2 Os nove contratos, em ordem

| Ordem | Contrato (arquivo; tarefas) | Fecha | Depende de | Depende da conclusão da Fase 4? | Observação |
|---|---|---|---|---|---|
| 1 | **`character`: itens, inventário, habilidades e origem** (`character.md`; LW-147, 148, 148b e 149) | 01, 02 (uso), 07, 13, 19 (ficha neutra, opcional), 22 (desgaste), 23, 24 (dados) | LW-089 e LW-105 (feitas); DEC-193 aprovada | **Não** | Fecha o ponto da seção 3.3 (kit inicial da origem). |
| 2 | **`combat`, `ecology` e `presentation`: combate básico, controles, HUD, derrota única e criaturas** (`combat.md`, `ecology.md`, `presentation.md`; LW-150 a 157 e 153b) | 05, 08, 17, 18, 21 | Contrato 1 | **Não.** Ficam de fora e dependem da Fase 4: LW-158 (`military` e `combat`) e LW-164 e 165 (crime e justiça). | Traz a verificação 1 (seção 7): início e interrupção do ataque automático. |
| 3 | **`economy` 18 e `world`: coleta e nós de recurso** (`economy.md`, `world.md`; LW-160) | 09 | Contrato 1; contrato da LW-160 | **Não** | Formaliza a exceção "fonte natural" à regra "um bem, uma receita". |
| 4 | **`economy` 18 e `character`: receitas, oficina e sessão de produção** (`economy.md` 18.3, `character.md`; LW-148 e 161) | 04, 10, 25, 26, 27 | Contratos 1 e 3 | **Não** | A sessão persistente é o ponto de maior risco do ciclo (interrupção sem duplicar nem perder). |
| 5 | **`economy` 18.4 e `world`: venda, valor por qualidade, baú e casa** (`economy.md` 18.4, `world.md`; LW-173) | 13, 33, 38 | Contratos 1 e 4; interface `TradeRules` (contrato da LW-117b) | **Não** para redigir. O teste de aceite com tarifas reais só roda depois da LW-130. | Traz a verificação 3 (seção 7): vendedor por ofício. A casa funcional não depende do painel da LW-173 (que depende de LW-140 e 141). |
| 6 | **`persistence`: autosave por tempo e por eventos, salvar só quando seguro, interrupções** (`persistence.md`; LW-174, 176 e 182) | 35, 36 | Contratos 2 a 5; formatos de save dos módulos da Fase 4 | **Sim** | Lista todos os módulos a salvar, inclusive facções, política e militar. |
| 7 | **`npc` e `economy` 8: diálogo com serviços e reputação; contratos urgentes** (`npc.md`, `economy.md`; LW-107, 127, 128 e 161) | 14, 28, 37 | Contrato 5; LW-127 e LW-128 | **Sim** | A reputação por facção e por povoado e os rumores vêm da Fase 4. |
| 8 | **`character` e `world`: vida do jogador** (`character.md`, `world.md`, `presentation.md`) | 29 (objetivo acompanhado), 31, 19 | Contrato 5 | **Em parte.** O objetivo acompanhado reaproveita o painel de encomendas; a ligação com a Crônica (LW-140) é da Fase 4. | Só entra se houver folga (31 e 19). O dia e noite (34) já está resolvido (seção 7, verificação 2). |
| 9 | **Teste do ciclo jogável** (LW-184 ampliada e LW-183) | critério da seção 4.3 | Contratos 1 a 6 (e 7, se entrar) | **Sim** (soak e cascata da Fase 4: LW-142 e 143; a LW-183 depende de LW-180 e 181) | Fecha o v0.1. |

### 6.3 Quando redigir

- **Contratos 1 a 5:** podem ser redigidos **enquanto a Fase 4 corre**, porque tocam `character`, a economia da Fase 5 e o `world`, e são só documento. **Recomendação:** um por vez, no ritmo que Arthur escolher, para não competir com a LW-099, a LW-100 e a Fase 4.
- **Contratos 6, 7 e 9:** só **depois da conclusão da Fase 4**, porque enumeram módulos e usam reputação, rumores e o soak político que a Fase 4 entrega.
- **Contrato 8:** o trecho do objetivo acompanhado pode vir com os primeiros; o restante só se houver folga.
- As decisões 15 (facções e carreira militar) e 16 (estado compartilhado) não ganham contrato novo: já pertencem à Fase 4 e ao padrão atual.

## 7. Verificações técnicas pendentes da auditoria (as três), resolvidas por leitura

| # | Pergunta | Contrato que depende | Resultado (28/11/2026) | O que muda no contrato |
|---|---|---|---|---|
| 1 | O ataque automático do SP6 é interrompível? | 2 | **Em parte.** O ataque automático sai sozinho enquanto há alvo, no alcance, fora de preparo e recuperação de habilidade, com o intervalo cumprido e estamina (`tests/soak/sp6/sp6_rules.gd`, linhas 250 a 258; `docs/modules/combat.md`, linha 23). Ele **começa ao selecionar o alvo** (`select_target`, linha 69) e **para** ao soltar o alvo por tecla ou ao clicar no vazio (`clear_target`, linha 74; `sp6_main.gd`, linhas 80 e 127 a 133), ao sair do alcance, durante preparo e recuperação e sem estamina. **Não há segundo clique nem comando para iniciar.** | A decisão 17 (segundo clique ou comando inicia) é um acréscimo **pequeno** à LW-153: um marcador de ataque automático ligado e desligado. Os números do SP6 não mudam. |
| 2 | A luz varia com a hora do dia? | 8 (e a decisão 34) | **Sim.** `AmbientRig.refresh` lê a hora simulada pela ponte (`peek_time`) a cada quadro e aplica a curva de dia e noite (`DayNightCycle.state_at`), com a fração do minuto e congelando em pausa (`src/presentation/world_view/environment/ambient_rig.gd`, linhas 49, 53 e 69; `day_night_cycle.gd`, linha 45). Está ligada à cena principal (`scenes/main.tscn`, linha 22; `main_world_view.gd`, linha 99). Os lampiões acendem pelo `lamp_factor` (ART-5a). As rotinas de NPC por horário também existem (`routine_table.gd`). A DEC-059 (dia e noite) segue PROPOSTA. | Nenhum trabalho novo de luz: a parte "iluminação e atmosfera" da decisão 34 **já existe**. Só a chuva (Expansão D) é nova. |
| 3 | O comerciante de hoje filtra bens por ofício? | 5 | **Não.** O filtro é **por mercado**: `data/economy/market_targets.json` lista os bens que cada povoado negocia e `traded_goods(settlement_id)` os devolve (`src/sim/economy/markets/market_book.gd`, linha 53). A interface do jogador negocia com o **mercado**, não com um NPC (`src/presentation/interaction/interaction_view.gd`, linha 196, `peek_market_in_reach`). As barracas da praça são cenário (`plaza_builder.gd`, linha 34). | O contrato 5 decide o "vendedor por ofício". **Recomendação:** rótulo de vendedor por categoria de bem na interface, **sem** NPC vendedor com estoque próprio (que seria sistema novo e mexeria na economia). |

## 8. Estimativa de impacto e custo

| Pacote | Decisões | Tamanho | Tarefas pequenas (ordem de grandeza) | Risco principal | Custo extra |
|---|---|---|---|---|---|
| Registro e contratos (documentos) | todas | P | 6 a 9 contratos | Decisões protegidas pedem o "APROVO" | R$ 0 |
| Personagem e itens | 01, 02, 13, 21, 22, 23 | M | 6 a 8 (LW-147, 148, 149, a tela, a qualidade e o baú) | Item em dois lugares; valor de referência | R$ 0 |
| Combate jogável | 05, 08, 17, 18 | M | 8 a 10 (já planejadas; a derrota única dispensa 4 propostas) | Equilíbrio; HUD | R$ 0 |
| Ofício do jogador | 04, 09, 10, 25, 26, 27 | G | 12 a 20 | Interrupção sem duplicar; economia | R$ 0 |
| Casa e descanso | 33 | P | 2 a 3 | Baú como novo dono de bens | R$ 0 |
| Se houver folga | 19, 31, 37 | P a M | 5 a 8 | Depende da reputação (Fase 4) | R$ 0 |
| Expansão A: magia e ofícios mágicos | 06, 11, 12 | GG | 20 a 30 | Maior sistema novo; efeitos visuais | R$ 0 |
| Expansão B: progressão | 03, 20, 32 | M | 6 a 10 | Equilíbrio sem dados de jogo | R$ 0 |
| Expansão C: combate avançado | partes de 05 e 18 | M | 6 a 10 | Estados novos; NPCs que reagem | R$ 0 |
| Expansão D: mundo ampliado | 30, chuva, compra da casa, fantásticas | G | 10 a 16 | Salvar no meio da viagem; valor de referência por clima | R$ 0 |

**Acréscimo líquido do corte recomendado:** de 17 a 26 tarefas novas (ofício, casa, qualidade, baú e controles) menos 5 que a derrota única dispensa: **de 12 a 21** sobre as 61 de hoje (47 oficiais e 14 propostas). As tarefas já planejadas (LW-147 a 156 e 153b) não contam como acréscimo. Tudo junto, sem corte, somaria de 60 a 100.

**Incertezas.** Tamanho relativo: P pequeno, M médio, G grande, GG muito grande. Tarefa pequena é uma tarefa de cerca de 300 linhas, no critério do AGENTS 5.2. Os números têm incerteza de cerca de 50%, foram calibrados na LW-100 (1 contrato e 8 tarefas para um fluxo de comércio só de simulação) e **não são prazos**: não há série de dados do ritmo da Fase 5. A magia é a maior incerteza.

**Custo.** Nenhum serviço, API, asset ou assinatura nova. O único recurso consumido é a cota da assinatura, cerca de 2% da cota semanal por tarefa de código revisada (medido na LW-100b). Arte provisória: formas simples e animações reaproveitadas (por exemplo, o golpe de martelo usa a animação de ataque), sem comprar assets.

## 9. O que este PR não faz e o que vem depois

**Este PR não:** integra nada no `main` (Arthur quer revisar antes); altera `DECISIONS.md`, GDD, roadmap, `ROADMAP_STATUS.md` ou qualquer arquivo protegido; cria contrato, tarefa, dado, evento ou código; contrata serviço.

**Depois, nesta ordem:**

1. Arthur revisa este PR e pede os ajustes que quiser.
2. "Aprovado" dele e ordem de merge deste PR (merge commit, só com o CI verde). Ainda sem alterar arquivo protegido.
3. "APROVO" dele, por texto, para as emendas da seção 5, em PR separado de classe 4.
4. Os contratos 1 a 9, **um por vez**, cada um com seu "Aprovado" (seção 6).
5. Só depois de cada contrato, as tarefas de código correspondentes, na ordem do roadmap e com revisão independente, CI verde e o "APROVADO" dele (classe 3).

## 10. Referências

- Decisões: DEC-003, 030, 054, 059, 060, 062, 064, 065, 084, 121, 172, 179 a 184, 190 a 194, 199, 200, 237 e 238 (`docs/DECISIONS.md`).
- GDD: 6.2, 6.6, 6.7, 16.5 e 24 (`docs/GDD.md`).
- Roadmap: 4.D, 5.D (tarefas novas propostas) e Anexo E (`docs/DEVELOPMENT_ROADMAP.md`); tabela "Itens dentro e fora do protótipo" (`docs/ROADMAP_STATUS.md`).
- Contratos e dados: `docs/modules/character.md`, `combat.md`, `economy.md` (seção 18), `presentation.md`; `docs/fase-5/dados.md`.
- Código: `data/economy/recipes.json`, `data/economy/market_targets.json`, `src/sim/economy/contracts/contract_book.gd`, `src/persistence/save_store.gd`, `src/sim/npc/needs/need_def.gd`, `tests/soak/sp6/`, `src/presentation/world_view/environment/`.
- Texto das 38 decisões: `docs/decisions/0018-anexo-texto-das-38-decisoes.md`.
