# LW-117 (pré-etapa) — Pré-voo da Fase 4 (facções e conflitos): levantamento de 11/11/2026

- **Status:** **RASCUNHO, fora do `main`. Respostas de Arthur de 11/11/2026 (Q1 a Q22) registradas na seção 6.** Este documento **não é o contrato da LW-117**: é o levantamento que vem antes dele, como o pré-voo da Fase 3 (`0012`) veio antes da LW-087. Não decide nada. O que as fontes não dizem vira **pergunta**; o que é só técnico traz uma **recomendação** que o revisor registra como PROPOSTA depois das suas respostas.
- **Data e autoria:** 11/11/2026 (Brasília), feito a pedido de Arthur (LW-117, DOC, pré-etapa). `main` lido em `4ada136`.
- **Fontes lidas:** `DEVELOPMENT_ROADMAP.md` (Fase 4, 4.A a 4.J); `DECISIONS.md` (índice e as entradas citadas); `GDD.md` (caps. 5.1, 8.6, 10, 11, 14, 15, 19.4, 20, 24); `TECHNICAL_ARCHITECTURE.md` (5.2, 11.8, 12, 13, 14, 17.5, 17.7); contratos no `main` (`npc.md`, `world.md`, `economy.md`, `events.md`).
- **Rótulos:** **fato** (com a fonte), **recomendação** (minha, não decide), **[HIP]**, **pendente**. Fontes citadas como `arquivo seção`.

## 0. Resumo em palavras simples

A Fase 4 pode começar a ser preparada, **mas a LW-117 não deve ser escrita antes de você responder** as perguntas da seção 4. Achei **18 contradições ou buracos** (seção 2). Os seis que mais pesam: (1) **não está dito onde fica a polity vizinha** (nem quem mora nela); (2) **três documentos dão a três donos diferentes o "controle" de uma província**; (3) a economia **não sabe receber uma política real** (como `TradeRules` troca de neutra para real, para onde vai a tarifa, quem tem conta no `Ledger`); (4) **"pena de crime" é uma das 5 leis, mas nenhuma tarefa cria crime**; (5) **as facções, os rumores, a satisfação e as baixas de guerra exigem mudanças no `npc`** que a LW-117 não lista; (6) a LW-142 manda **migrar** o save, e você já decidiu que o save **não é congelado** (DEC-134). Há **3 decisões PENDENTES que travam tarefas** (DEC-053, DEC-055, DEC-040) e **6 PROPOSTAS** que valem como padrão de trabalho (DEC-038, 043, 052, 056, 077, 099). São **10 perguntas de jogo** (só você decide) e **11 técnicas** (o revisor decide, se você concordar).

**Atualização de 11/11/2026:** Arthur respondeu as 22 perguntas (as 10 de jogo, as 11 técnicas, uma a uma, e uma 22ª que nasceu ao cruzar as respostas). **As respostas estão na seção 6**; as seções 1 a 5 ficam como foram escritas antes delas, para guardar o raciocínio.

## 1. Decisões de que a Fase 4 depende (status no `DECISIONS.md` de 11/11/2026)

| DEC | Assunto | Status | Trava? |
|---|---|---|---|
| 050 | 3 facções (autoridade local, mercantil, criminosa) e 2 polities, uma simplificada. Detalhe "provisório por recomendação": a autoridade é o governo; a soberania sobre províncias é da polity | APROVADA (composição inicial) | Não; o detalhe vira Q4, Q10 e Q11 |
| 051 | Polity vizinha de baixa resolução, sem membros nem facções internas completas | APROVADA | Não; falta dizer **onde ela fica** (achado 1) |
| 045, 046, 047, 049 | Organizações agem sem o jogador; economia conectada; dinheiro inteiro com `Ledger`; `TradeRules` é o único ponto da política na economia | APROVADAS | Base de LW-119, 123, 130 |
| 054 | Fora do protótipo: cercos, exércitos grandes, intriga, sucessão, fundação de organização | APROVADA | Limita LW-132, 135 a 138 |
| 062, 100 | Meta de 3 trajetórias (mercador, soldado/guarda, aventureiro); nomes genéricos | APROVADAS | Q1, Q2 |
| 141, 164, 155, 157, 165, 169 | Da Fase 3: `TradeRules` entregue ao construtor; postos provisórios até a Fase 4; `CaravanAttacked` e perda de carga fora da Fase 3; contratos sem escolta; vaga | APROVADAS | A Fase 4 **muda** cada uma (achados 5 a 7, 15) |
| 083, 127, 134 | Persistência (só princípios); `save_version` 2 até o "save congelado"; a Fase 3 **rejeita** save antigo | APROVADAS | Conflita com a LW-142 (achado 17, Q8) |
| 038 | Quatro camadas de NPC, com T3 líder | **PROPOSTA** | **Trava LW-121 e LW-132** (T3) |
| 040 | Quantidade de NPCs (e, daí, o teto de T2 e T3) | **PENDENTE** | **Trava LW-121** (limite global) |
| 041 | Sem T0 no protótipo | APROVADA | Complica LW-131 (achado 10) |
| 043 | Memória, relações e rumores | **PROPOSTA** | **Trava LW-127** |
| 052 | Cinco escalas de conflito (incidente a guerra) | **PROPOSTA** | Guia LW-136 a 139 |
| 053 | Escala das batalhas: limite de combatentes, modo (tático ou abstrato) e se o jogador comanda | **PENDENTE** | **Trava LW-137** (o roadmap já supõe "abstrato") |
| 055 | Dimensões do mundo, inclusive o número de províncias | **PENDENTE** | **Trava LW-118** (Q6) |
| 056 | Mundo lógico separado do visual, com hierarquia espacial | **PROPOSTA** | LW-118 |
| 077 | `EventBus` próprio e `cause_id` (já em uso no código) | **PROPOSTA** | LW-126, 140, 143 (a cadeia do cap. 13.5) |
| 099 | Lista de corte: a "facção criminosa completa" é o 5º corte; crônica e "Por quê?" não se cortam | **PROPOSTA** | Molda a facção criminosa (Q1) |
| 033, 065, 066, 069, 070 | Lore; morte do jogador; combate definitivo; diretor de eventos; eventos dinâmicos (Fase 5) | PENDENTES e PROPOSTA | **Não trava** a Fase 4 (corpóreo e eventos são da Fase 5) |

**Não existe DEC sobre:** leis e penas; reputação; crônica; rumores; culturas; tipos e doutrinas das facções; para onde vai a tarifa; quem tem o "controle" de uma província. Tudo isso é **pergunta** (seção 4).

## 2. Contradições e buracos (cada achado: efeito, fontes, recomendação)

**1. Onde fica a polity vizinha.**
- *Efeito:* sem isso, não dá para fazer "tarifa", "tratado" nem "escolta" com ela.
- *Fontes:* `DEVELOPMENT_ROADMAP.md 4.B` (vizinha com "nenhum NPC T1 simulado"); DEC-051 (sem membros nem facções internas, **não** proíbe população); `world.md` (extensão: os 3 povoados A, B e C, todos com população, DEC-142, e o triângulo, DEC-158); `GDD.md 24.2`.
- *Recomendação:* **Q4**.

**2. Quem é dono do "controle" da província.**
- *Efeito:* três donos para o mesmo dado causam escrita cruzada (o que a REV da LW-144 proíbe).
- *Fontes:* `TECHNICAL_ARCHITECTURE.md 5.2` (`Province` tem "dono político", no `world`); DEC-050 (a soberania é da polity); `DEVELOPMENT_ROADMAP.md LW-117` ("território na facção") e LW-119, LW-138 ("vitória transfere o controle"); `GDD.md 10.3` (território na facção).
- *Recomendação:* **Q11**.

**3. `PolityState` não cabe na vizinha.**
- *Efeito:* a ficha diz que a polity é "ligada ao ID de uma facção de governo"; a vizinha, pela DEC-051, **não tem facção**.
- *Fontes:* `TECHNICAL_ARCHITECTURE.md 13.2`; DEC-051; `DEVELOPMENT_ROADMAP.md 4.B`.
- *Recomendação:* a polity ter ID próprio e a facção de governo apenas apontar para ela (resolve junto com o achado 2).

**4. Quantas províncias.**
- *Efeito:* 12 a 30 províncias [HIP] com 3 povoados, 3 rotas e terreno que não cresce seria quase tudo vazio.
- *Fontes:* `GDD.md 24.2`; `DEVELOPMENT_ROADMAP.md 4.B e LW-118`; DEC-055 (PENDENTE); DEC-158 e DEC-161 (3 povoados; terreno não ampliado).
- *Recomendação:* **Q6**.

**5. A economia não sabe receber uma política real.**
- *Efeito:* a política não consegue trocar a regra neutra nem cobrar tarifa.
- *Fontes:* `economy.md 5` (a regra é "entregue pronta ao construtor"; `peek_terms` devolve só `banned`, `tariff_bp` e `needs_license`; `TradeResult.tariff` é sempre 0; para onde vai a tarifa "é da Fase 4"); `DEVELOPMENT_ROADMAP.md LW-130` ("fornecida no `post_setup`"); `TECHNICAL_ARCHITECTURE.md 11.8` (quem entrega); DEC-141.
- *Recomendação:* **Q12**.

**6. Conta de facção no `Ledger`.**
- *Efeito:* a LW-119 cria "conta", mas o contrato da economia tem **tipos de dono fechados** e **motivos fechados**, e só dinheiro inicial como fonte.
- *Fontes:* `economy.md 2` (motivos: `game_start`, `trade`, `salary`, `contract_*`), `3` (donos: `npc`, `player`, `site`, `market`, `contract`); `DEVELOPMENT_ROADMAP.md LW-119, LW-123, LW-130`. A **fonte de dinheiro** das facções (principalmente a criminosa) não está definida em lugar nenhum.
- *Recomendação:* **Q13** e **Q9**.

**7. Quem paga os guardas.**
- *Efeito:* risco de **pagar duas vezes** ou de o guarda ficar sem `income`.
- *Fontes:* DEC-164 e `economy.md 6` (a folha dos postos sai do mercado "até a Fase 4", quando passa a sair do tesouro); `DEVELOPMENT_ROADMAP.md LW-121` (guardas na autoridade) e `LW-123` (soldos e salários dos membros). Nenhuma tarefa faz a troca de pagador; o `WagesPaid` hoje só cobre locais de trabalho.
- *Recomendação:* **Q20**.

**8. "Pena de crime" não tem crime.**
- *Efeito:* uma das 5 leis não teria efeito nenhum.
- *Fontes:* `DEVELOPMENT_ROADMAP.md LW-117` (a lista de 5 leis); `GDD.md 20.6` e `20.9` (crime e justiça simples são [P1]); `TECHNICAL_ARCHITECTURE.md 17.5` (`CrimeCommitted`, publicado por `combat` ou `npc`); `npc.md` (nenhuma ação de crime). Nenhuma tarefa da Fase 4 publica crime.
- *Recomendação:* **Q3**.

**9. T3 não existe no `npc`.**
- *Efeito:* a LW-121 "estende" um comando que hoje recusa T3.
- *Fontes:* `npc.md 7` (`request_promote(npc_id, 2)` só entre T1 e T2; T3 dá `NPC_INVALID_TIER`; `max_t2` [HIP] 40); `DEVELOPMENT_ROADMAP.md LW-121`; DEC-038 (PROPOSTA); DEC-040 (PENDENTE).
- *Recomendação:* **Q15**.

**10. Satisfação sem T0.**
- *Efeito:* a estabilidade precisa de uma pergunta ao `npc` que não existe e pode ser cara.
- *Fontes:* `TECHNICAL_ARCHITECTURE.md 13.3` (agregado "de `PopulationGroup`") contra DEC-041 (sem T0); `DEVELOPMENT_ROADMAP.md LW-131` ("consulta agregada") e risco R4.5; `npc.md` (não descreve essa consulta nem a ação "protestar").
- *Recomendação:* **Q16**.

**11. Reputação está um andar acima de quem a usa.**
- *Efeito:* a facção não pode ler a reputação para negar um posto.
- *Fontes:* `TECHNICAL_ARCHITECTURE.md 17.7` (o módulo `events` fica na camada 5 e só recebe eventos); AGENTS 5.1 (a camada 4, de `factions`, **não importa** a 5); `GDD.md 10.5` (postos exigem reputação) e `DEVELOPMENT_ROADMAP.md LW-120`, `LW-128`. Além disso, "ação presenciada" (LW-128) precisa saber **quem viu**, e o `events` não importa o `npc`.
- *Recomendação:* **Q14**.

**12. Eventos: o roadmap e a arquitetura não batem; a crônica não tem limiar.**
- *Efeito:* eventos sem dono ou sem tarefa.
- *Fontes:* `TECHNICAL_ARCHITECTURE.md 12.5, 13.6, 14.4` (`MemberExpelled`, `FactionRelationChanged`, `FactionCollapsed`, `TreatySigned`, `ForceDeserted`, `ReputationChanged`) contra as tarefas LW-120 a LW-139, que não os citam; `events.md` (coluna "Entra na crônica?" com "Sim", "Não", "Se grave", "Se notável", sem número) e `DEVELOPMENT_ROADMAP.md LW-126` ("acima do limiar").
- *Recomendação:* **Q19**.

**13. Rumores e T1.**
- *Efeito:* o rumor "chega a mais NPCs", mas T1 não tem memória.
- *Fontes:* `npc.md 5 e 7` (memória só T2, só `WITNESSED`; rumor "fora"; relação só com T2 e o jogador); `DEVELOPMENT_ROADMAP.md LW-127`; `GDD.md 8.6 e 20.3`.
- *Recomendação:* **Q18**.

**14. Soldados são NPCs que continuam existindo no `npc`.**
- *Efeito:* sem regra, o soldado "em missão" também está no povoado, ou morre sem o `npc` saber.
- *Fontes:* `TECHNICAL_ARCHITECTURE.md 14.2` (membros são NPCs T1 e T2, "uma só vez"); `DEVELOPMENT_ROADMAP.md LW-135, LW-137` ("baixas aplicadas a indivíduos"); `npc.md` (a morte hoje só vem de fome; nenhum estado "em missão").
- *Recomendação:* **Q17**.

**15. Escolta e ataque a caravana.**
- *Efeito:* a LW-139 precisa de um tipo de contrato e de uma perda de carga que a economia ainda não tem.
- *Fontes:* `economy.md 8` ("escolta e recompensa são [FUT]"); DEC-155 (`CaravanAttacked` e `RouteCargoLost` ficaram fora da Fase 3); `TECHNICAL_ARCHITECTURE.md 17.5` (publicador "economy/combat"); `world.md` (rota só `open` ou `closed`, DEC-159; `risk` existe como dado).
- *Recomendação:* **Q21**.

**16. O escopo da LW-117 está pequeno.**
- *Efeito:* os achados 5, 6, 9, 10, 13, 14 e 15 pedem mudança nos contratos de `economy`, `npc` e `world`, que a LW-117 não lista.
- *Fontes:* `DEVELOPMENT_ROADMAP.md LW-117` (lista `factions`, `politics`, `military`, `events`, `npc/rumors`, `world/Province`).
- *Recomendação:* a divisão da seção 3.

**17. Save.**
- *Efeito:* a LW-142 manda migrar o save da Fase 3; você decidiu rejeitar (a Fase 3 trocou "migra" por "rejeita").
- *Fontes:* `DEVELOPMENT_ROADMAP.md LW-142`; DEC-127 e DEC-134; DEC-083 (o "save congelado" segue pendente).
- *Recomendação:* **Q8**.

**18. GDD e roadmap divergem em quatro pontos de escopo.**
- *Efeito:* risco de a LW-117 escrever o que o GDD marca como adiado.
- *Fontes:* governante **por assentamento** (`GDD.md 11.3`) contra **por polity** (`TECHNICAL_ARCHITECTURE.md 13.2`, LW-132); **guerra entre polities** é [PREV] (`GDD.md 15.8`) mas a LW-133 cria o estado "guerra" e o `WarDeclared`; diplomacia **entre facções** é [PREV] (`GDD.md 10.6`) mas a LW-122 cria afinidade entre facções; rebelião é [PREV] (`GDD.md 11.6`) e o roadmap (4.J) a proíbe, de acordo.
- *Recomendação:* **Q5** e **Q10**.

## 3. Divisão sugerida da LW-117 (como 087a a 087d; sugestão, você e o revisor atribuem)

| Parte | O que escreve | Arquivos | Dono sugerido (por papel) |
|---|---|---|---|
| 117a | Registro: `DECISIONS.md` (as respostas desta seção 4), correções do roadmap (divergências: LW-142, LW-117, LW-119, LW-130) e o registro da fase | `DECISIONS.md`, `DEVELOPMENT_ROADMAP.md`, `docs/decisions/0014-…` | quem faz o registro |
| 117b | Extensão da **economia** para a Fase 4: contas de facção, motivos do `Ledger`, troca da `TradeRules` e destino da tarifa, contrato `escort`, perda de carga, folha dos postos | `economy.md` (só a seção nova) | dona da economia |
| 117c | Contratos novos de **`factions`** e **`politics`** (a interface `TradeRules` com a economia) | `factions.md`, `politics.md` | dona da economia e dos dados |
| 117d | Contratos novos de **`military`** e do módulo **`events`** (crônica e reputação); sugiro nome de arquivo que **não** colida com `docs/events.md` (por exemplo `chronicle.md`) | `military.md`, `chronicle.md` | quem faz o registro |
| 117e | Extensões de **`world`** (`Province`, culturas) e de **`npc`** (T3, rumores, satisfação, baixas, "em missão") | `world.md`, `npc.md` | dona do mundo e do NPC |
| 117f | Catálogo de eventos da Fase 4 (**depois** das 117b a 117e) e modelos de dados (`factions.json`, `ranks.json`, `faction_options.json`, `laws.json`, `cultures.json`, `provinces.json`) | `docs/events.md`, `docs/faction/dados.md` | dona da economia e dos dados |

Regras: um arquivo, um escritor; 117a primeiro (registra as respostas), 117f por último (precisa dos contratos). Cada parte só entra no `main` por ordem sua.

**Tarefas que provavelmente passam do limite (AGENTS 5.2: um módulo, cerca de 300 linhas de código e teste, até 8 arquivos; DEC-126):**
- **Tocam mais de um módulo:** LW-119 (factions e a conta na economia), LW-121 (factions, npc e cultura), LW-125 (factions e contratos da economia), LW-130 (politics e economia), LW-131 (politics, npc e uma ação nova), LW-134 (politics, economia e world), LW-135 (military, factions e economia), LW-138 (factions, military, world e economia), LW-139 (military, economia e factions).
- **Grandes por conteúdo:** LW-124 (deliberação com opções em dados), LW-137 (resolução e baixas), LW-142 (soak e save), LW-141 (painel com ingresso e promoção).
- **Sugestão:** o revisor divide ao preparar o prompt (como a LW-094): 119a/b (estado e conta), 130a/b (regra e tarifa ao tesouro), 131a/b/c (consulta do `npc`, estabilidade, protesto), 138a/b (disputa e efeito na economia), 142a/b (soak e save).

## 4. Perguntas

### 4.1 Decisões de JOGO (só você decide)

**Q1 — As 3 facções (o roadmap deixa para você).** A DEC-050 **já fixa os tipos** (autoridade, mercantil, criminosa); falta decidir os nomes genéricos (DEC-100), a doutrina de cada uma e **em quais o jogador pode entrar**.
- *Opções:* (A) o jogador entra só na autoridade e na mercantil; (B) nas três.
- *Recomendo (A):* o GDD 24.2 deixa "crime como trajetória" para o futuro e a DEC-062 fixa 3 trajetórias (mercador, soldado/guarda, aventureiro); a criminosa fica "em forma mínima" (DEC-099, 5º corte).
- *Muda:* (A) a LW-141 só mostra duas facções ao jogador; (B) a criminosa precisa de hierarquia completa e de reputação própria.

**Q2 — As 2 culturas genéricas (o roadmap deixa para você).** O GDD 5.1 lista parâmetros (valores, atitude com estrangeiros, doutrina militar, estrutura de poder, tabus e crimes).
- *Opções:* (A) duas culturas **contrastantes**, descritas por você em palavras (por exemplo uma mais mercantil e outra mais tradicional), usando só 4 parâmetros na Fase 4; (B) duas culturas quase iguais, para só testar o mecanismo; (C) você me passa a lista de parâmetros.
- *Recomendo (A):* contraste é o que faz facções e polities reagirem diferente ao mesmo fato.
- *Muda:* (A) afinidade inicial e doutrina têm efeito visível; (B) a cultura vira enfeite.

**Q3 — As 5 leis (o roadmap deixa para você) e o crime.** Roadmap: tarifa, imposto de entrada, conscrição, pena de crime, licença.
- *Opções:* (A) as 5, com **um crime simples** (por exemplo contrabando de bem proibido) e a "pena" como multa: exige criar a fonte do crime (tarefa nova); (B) trocar "pena de crime" por **proibição de bem** (a economia já sabe aplicar); (C) 4 leis, sem pena.
- *Recomendo (B):* reaproveita a `TradeRules` e não cria um sistema de justiça (o GDD 20.9 pede "justiça simples", mas o roadmap 4.J proíbe ir além das 5 leis).
- *Muda:* (A) +1 tarefa e +1 módulo tocado; (B) nenhuma tarefa nova; (C) o checklist 4.H perde "lei".

**Q4 — Onde fica a polity vizinha (achado 1).**
- *Opções:* (A) sem lugar no mapa: só relação, força e tarifa; nenhum bem atravessa; (B) o **povoado C** é dela (tem população, o que relaxa o "nenhum NPC T1" do roadmap, **não** a DEC-051); (C) uma 4ª povoação abstrata, sem NPCs, com um mercado fictício.
- *Recomendo (B):* os efeitos de tarifa, tratado, escolta e disputa passam a aparecer nas rotas e mercados que a Fase 3 já criou, sem conceito novo.
- *Muda:* (A) a tarifa e o tratado não têm onde agir (o item de checklist "tratado reduz a tarifa" fica sem teste real); (B) o C passa a pertencer à vizinha; (C) +1 povoação, +1 mercado sem produtor nem consumidor (conceito novo na economia).

**Q5 — Guerra no protótipo.** O GDD (15.8) marca guerra entre polities como [PREV]; a LW-133 cria o estado "guerra".
- *Opções:* (A) o estado existe e libera **ataques em escala pequena** entre forças das duas polities, sem cerco nem exército grande (DEC-054); (B) o maior estado é "hostilidade", e as disputas são só entre facções; (C) guerra completa (contraria a DEC-054).
- *Recomendo (A) com a DEC-053 respondida como "abstrato; o jogador não comanda na Fase 4" (corpóreo é da Fase 5).*
- *Muda:* (A) a LW-138 e a LW-139 têm o que resolver; (B) a LW-133 perde o estado "guerra" e o critério 4.F-7 (disputa territorial) fica mais fraco.

**Q6 — Quantas províncias (DEC-055, achado 4).**
- *Opções:* (A) **4** (uma por povoado, mais uma de fronteira); (B) 6 a 8; (C) 12 a 30 do GDD.
- *Recomendo (A)* e registrar como decisão do protótipo (como a DEC-118 fez com o terreno): o terreno não cresce (DEC-161).
- *Muda:* (A) a LW-118 é pequena; (C) 8 a 26 províncias sem nada dentro e disputas sem sentido.

**Q7 — Reputação: dimensões e faixas.** O GDD (20.3) sugere 4 dimensões [HIP] e (20.9) só pede "reputação por facção e assentamento" no [P1].
- *Opções:* (A) **um número** por entidade, em 5 faixas nomeadas; (B) 2 dimensões (confiança e medo); (C) as 4 do GDD.
- *Recomendo (A):* é o que o painel (LW-141) consegue mostrar com clareza.
- *Muda:* (B) e (C) aumentam dados, testes e interface.

**Q8 — Save na Fase 4 (achado 17).**
- *Opções:* (A) continuar sem congelar: a LW-142 **rejeita** o save da Fase 3, como a LW-111; (B) congelar o save ao fim da Fase 4 e só depois migrar; (C) congelar já e migrar na LW-142.
- *Recomendo (A):* DEC-127 e DEC-134 já valem; congelar cedo trava a evolução do estado.
- *Muda:* (C) a LW-142 vira uma tarefa grande de migração com fixture.

**Q9 — De onde vem o dinheiro da facção criminosa (e das outras).**
- *Opções:* (A) assaltos a caravana (LW-139) e contribuição dos membros; extorsão fica fora; (B) extorsão de mercados (um pagamento forçado: ação e reação novas); (C) só o dinheiro inicial.
- *Recomendo (A):* já está no plano.
- *Muda:* (B) +1 ação nova no `npc` e +1 regra na economia; (C) a criminosa **quebra** no soak de 1 ano e some.

**Q10 — Quem governa: por povoado ou por polity (achado 18).**
- *Opções:* (A) **um governante T3 por polity** (2 no total); (B) um por povoado (3, mais o da vizinha).
- *Recomendo (A):* é o que o roadmap e a arquitetura já descrevem e usa menos T3 (DEC-040 pendente).
- *Muda:* (B) leis locais diferentes por povoado e mais T3 a simular.

### 4.2 Técnicas menores (o revisor decide como PROPOSTA, se você concordar)

**Q11 — Dono do controle da província (achado 2).**
- *Opções:* (A) a `politics` guarda quem **controla** cada província; as `factions` guardam a **influência**; o `world` guarda só a estrutura; (B) o `world` guarda o "dono político" (arquitetura 5.2) e a `politics` pede a mudança; (C) a facção guarda o território (texto da LW-117).
- *Recomendo (A):* segue a DEC-050 e dá um dono por dado.
- *Muda:* (B) o `world` ganha estado mutável de política; (C) contraria a DEC-050.

**Q12 — Troca da `TradeRules` e destino da tarifa (achado 5).**
- *Opções:* (A) a economia recebe, no construtor, um **interruptor** (neutra de início) e a `politics` coloca a regra real no `post_setup`; (B) um comando `request_set_trade_rules` na `economy/api`; (C) construir a `politics` antes (quebra as camadas).
- *Recomendo (A)* e `peek_terms` passar a devolver **quem recebe** a tarifa (a economia faz a transferência, motivo novo `tariff`).
- *Muda:* contrato da economia (+1 campo e +1 motivo).

**Q13 — Contas de facção e de polity (achado 6).**
- *Opções:* (A) **um tipo de dono** `treasury` para facção e para polity; (B) dois tipos (`faction` e `polity`).
- *Recomendo (A):* menos tipos; ambos com dinheiro inicial `game_start` e motivos novos (`tariff`, `tax`, `upkeep`, `faction_salary`).
- *Muda:* contrato da economia (tipos e motivos fechados).

**Q14 — Reputação para quem exige reputação (achado 11).**
- *Opções:* (A) o módulo `events` publica `ReputationChanged` e a `factions` guarda uma **cópia só de leitura** dos valores de que precisa; (B) uma segunda inversão de dependência como a `TradeRules` (contraria a DEC-049: "única"); (C) a reputação sai do `events` para uma camada abaixo.
- *Recomendo (A).* Para "quem viu", o `npc` publica a contagem de testemunhas no evento.
- *Muda:* (C) mexe na arquitetura 17.7.

**Q15 — T3 no `npc` (achado 9).**
- *Opções:* (A) T3 = T2 com um **vínculo de liderança** e teto próprio em dados (`max_t3`), sem "planos" [PREV]; (B) T3 completo com planos (GDD 8.2, adiado).
- *Recomendo (A)* e `request_promote(npc_id, 3)` só para a `factions`.
- *Muda:* (B) +1 sistema grande no `npc`.

**Q16 — Satisfação e protesto (achado 10).**
- *Opções:* (A) uma consulta nova do `npc` por povoado, **calculada uma vez por dia** e guardada em cache; (B) a `politics` lê `PriceChanged` e `ShortageDeclared` e deduz.
- *Recomendo (A)* e o `npc` ouvir `UnrestRaised` para a ação "protestar" (condição nova = código, o resto em dados).
- *Muda:* (B) o NPC não reage a fome nem a renda.

**Q17 — Soldado: baixas e ausência (achado 14).**
- *Opções:* (A) o `npc` ganha `request_apply_casualty(npc_id, motivo)` e o estado "em missão" (sai da rotina do povoado enquanto a força estiver fora); (B) a `Force` guarda cópias (duplica pessoas: proibido).
- *Recomendo (A).*
- *Muda:* contrato do `npc` (+1 comando, +1 estado).

**Q18 — Rumores e T1 (achado 13).**
- *Opções:* (A) um quadro de rumores **por povoado**, dono `npc`, com capacidade e perda de confiança por lote; (B) memória em todo T1 (custo alto).
- *Recomendo (A)* (a LW-127 já fala em "lote por povoado").
- *Muda:* (B) muda a memória do T1 e o tamanho do save.

**Q19 — Eventos e limiar da crônica (achado 12).**
- *Opções:* (A) adotar os 6 eventos que a arquitetura lista e o roadmap omite, cada um na tarefa que o publica, e pôr o limiar de severidade **em dados** (`chronicle.json`); (B) só os do roadmap.
- *Recomendo (A):* sem `FactionCollapsed` o "colapso limpo" (LW-123) não tem registro.
- *Muda:* +6 linhas no catálogo; crônica configurável.

**Q20 — Folha dos guardas (achado 7).**
- *Opções:* (A) os postos **continuam**; só o pagador muda (do mercado para o tesouro da autoridade, motivo `salary`), e o `WagesPaid` segue o mesmo; (B) os guardas saem dos postos e viram membros pagos pela facção.
- *Recomendo (A):* mudança mínima e sem pagamento duplo.
- *Muda:* (B) o `npc` perde o `income` por posto e a LW-123 vira folha geral.

**Q21 — Escolta e perda de carga (achado 15).**
- *Opções:* (A) contrato novo `escort` na economia; a carga perdida é **destruída** com motivo `lost` (conservação de bens fecha); (B) a carga vai para o inventário do atacante.
- *Recomendo (A):* mais simples; (B) cria venda de produto roubado.
- *Muda:* (B) +1 regra de saque e conta de bens da facção criminosa.

## 5. Riscos para o protótipo (DEC-006: um desenvolvedor, com IA) e o que adiar

- **Escopo:** 29 tarefas, 3 módulos novos e 3 extensões; a Fase 4 é a mais larga. *Mitigação:* as divisões da seção 3 e as respostas antes da LW-117.
- **Cascata do cap. 13.5:** 8 elos em 6 módulos, com `cause_id` em todos; basta um elo mal ligado para a LW-143 falhar. *Mitigação:* testar a cascata cedo, com dublês.
- **Três módulos na mesma camada** (`factions`, `politics`, `military`): importam a `api` uns dos outros e podem formar ciclo. *Mitigação:* estender o `check_architecture` (como a LW-088a fez com `npc` e `economy`).
- **Dinheiro conservado com tesouros:** facção sem fonte quebra; facção com fonte demais gera inflação (R3.2 de novo). *Mitigação:* Q9 e o soak de 1 ano.
- **Estabilidade e protesto:** histerese e calibração por dados; risco de espiral (como a R3.3).
- **Custo do tick** (diário e semanal, 3 módulos, satisfação por povoado): medir antes de otimizar (AGENTS 4.18).
- **Hashes novos de novo:** cada módulo registrado muda o `state_hash`; repetir a regra dos marcos por bloco da Fase 3 (DEC-175).
- **Painéis** (LW-140 e LW-141): UI feita por quem não é de UI; manter o mínimo.

**Backlog prévio (uma linha cada):** T0 e satisfação agregada real; crime e justiça completos; rebelião e queda de governante; sucessão; cerco e exército grande; diplomacia entre facções e alianças; intriga e espionagem; reputação multidimensional; mercado negro e extorsão; fundação de facção pelo jogador; contato cultural dinâmico; traços de comandante e logística detalhada; estado de rota "perigosa" (arquitetura 5.2); terceira polity.

## 6. Respostas de Arthur (11/11/2026)

Dadas pelo painel de decisões, em lotes, na mesma conversa. **Q1 a Q10 e Q22 são decisões dele.** **Q11 a Q21 eram recomendações do revisor; ele quis vê-las uma a uma e escolheu cada uma**, então valem como escolhidas por ele. O registro no `DECISIONS.md` e as correções do roadmap são da parte 117a (seção 3); este documento só guarda as respostas.

| Q | Assunto | Resposta de Arthur |
|---|---|---|
| 1 | Facções em que o jogador entra | **Autoridade e mercantil.** A criminosa fica em forma mínima, sem o jogador dentro. Nomes e doutrina das três: o revisor propõe, genéricos (DEC-100) |
| 2 | 2 culturas genéricas | **Duas contrastantes** (por exemplo uma mais mercantil e outra mais tradicional), só com 4 parâmetros na Fase 4 |
| 3 | As 5 leis | **"Pena de crime" sai e entra "proibição de bem".** As 5: tarifa, imposto de entrada, conscrição, proibição de bem e licença |
| 4 | Onde fica o país vizinho | **O povoado C é dele** |
| 5 | Guerra e DEC-053 | **Guerra em escala pequena** entre as forças dos dois países, sem cerco nem exército grande. Resposta à DEC-053: **resolução abstrata e o jogador não comanda na Fase 4**; o limite de combatentes com corpo é da Fase 5 |
| 6 | Províncias (DEC-055) | **4**: uma por povoado (A, B e C) mais uma de fronteira. Vale como decisão do protótipo; a DEC-055 segue pendente para o mundo final |
| 7 | Reputação | **Um número por entidade, em 5 faixas nomeadas** |
| 8 | Save | **Continua sem congelar:** a LW-142 **rejeita** o save da Fase 3 com mensagem clara (DEC-127 e DEC-134) |
| 9 | Dinheiro da facção criminosa | **Assaltos a caravana e contribuição dos membros;** extorsão fica fora |
| 10 | Quem governa | **Um governante por país** (2 no total) |
| 11 | Controle da província | **A `politics` guarda o controle;** as `factions` guardam a influência; o `world` guarda só a estrutura |
| 12 | `TradeRules` e tarifa | **Interruptor na economia** (neutra de início; a política põe a real ao iniciar); a consulta passa a dizer **quem recebe** a tarifa e a economia faz a transferência (motivo `tariff`) |
| 13 | Contas de tesouro | **Um tipo de dono `treasury`** para facção e país; motivos novos (`tariff`, `tax`, `upkeep`, `faction_salary`) e dinheiro inicial |
| 14 | Reputação nas facções | **Aviso por evento (`ReputationChanged`) e cópia só de leitura** na `factions`; o `npc` informa a contagem de testemunhas |
| 15 | T3 | **T2 com vínculo de liderança,** teto próprio em dados (`max_t3`), sem "planos"; só as facções promovem a T3 |
| 16 | Satisfação e protesto | **Consulta nova do `npc`, calculada uma vez por dia;** o `npc` ouve a agitação (`UnrestRaised`) e "protestar" fica em dados |
| 17 | Soldados | **O `npc` ganha "baixa" e "em missão";** a mesma pessoa existe uma só vez |
| 18 | Rumores | **Quadro de rumores por povoado,** dono `npc`, com capacidade e perda de confiança por lote |
| 19 | Eventos e crônica | **Adotar os 6 eventos** que a arquitetura lista e o roadmap omite; **limiar de importância da crônica em dados** |
| 20 | Guardas | **Os postos continuam;** só o pagador muda (do mercado para o tesouro da autoridade), com o mesmo evento de pagamento |
| 21 | Escolta e carga | **Contrato novo `escort`** na economia; a carga perdida é **destruída** (motivo `lost`) |
| 22 | Assalto a caravana (nova) | **O assalto leva o dinheiro do comerciante** (transferência para a facção criminosa) **e a carga é destruída;** isso resolve a contradição entre Q9 e Q21 |

**O que as respostas mudam no roadmap (para a parte 117a registrar como divergência):** a lista de 5 leis da LW-117 (sai "pena de crime", entra "proibição de bem"); a LW-142 **rejeita** o save em vez de migrar; a LW-118 passa a ter 4 províncias e o C ligado à província do vizinho; a LW-130 usa o interruptor da economia e a tarifa tem destinatário; a LW-119 usa o tipo `treasury`; a LW-121 promove a T3 como "T2 com vínculo"; a LW-127 usa o quadro de rumores; a LW-131 e a LW-135 pedem as extensões do `npc` (consulta diária, "protestar", "baixa", "em missão"); a LW-139 usa o contrato `escort` e o assalto que transfere dinheiro (motivo novo no `Ledger`). **A divisão da seção 3 continua valendo:** as extensões de `economy`, `npc` e `world` seguem fora da lista da LW-117 e entram nas partes 117b e 117e.

**O que as respostas deixam em aberto (pequeno; o revisor propõe, nada foi decidido aqui):**
- **Cultura de cada país:** a Q2 não diz qual das duas culturas é do país principal e qual é do vizinho.
- **Província de fronteira (Q6):** de quem ela é e se tem povoado.
- **"Imposto de entrada" (Q3):** como ele difere da tarifa (a economia só tem uma consulta de regra por bem, mercado e comprador).
- **Nomes e doutrina das 3 facções (Q1):** propostas genéricas do revisor (DEC-100).

## Validação e referências

- Todas as DEC citadas foram conferidas no `DECISIONS.md` do `main` (`4ada136`, 11/11/2026). Os trechos do GDD, da arquitetura, do roadmap e dos contratos foram lidos nas versões do `main` da mesma data.
- Este documento não cria arquivo de dados, evento, contrato nem código, e não altera `docs/events.md`.
- Próximo passo: a parte 117a registra as respostas da seção 6 no `DECISIONS.md` e no roadmap; depois, as partes 117b a 117f (seção 3), por ordem de Arthur. **Este rascunho continua fora do `main`.**
