# LW-146 (pré-etapa) — Levantamento de pré-voo da Fase 5 (integração e protótipo)

- **Status:** **Registrado pela LW-146a** (as respostas de Arthur estão em `docs/DECISIONS.md`, DEC-179 a DEC-201; este arquivo entra no `main` com a Fase B). É um levantamento: **não decide nada**, não cria nem muda DEC e **não é o contrato da LW-146** (esse vem depois, com as respostas de Arthur). As perguntas da seção 4 são de Arthur (jogo) ou do revisor (técnica menor, como PROPOSTA). **Atualizado em 11/11/2026 (segundo commit):** Arthur respondeu às Q1 a Q10 no chat, pelo painel de escolhas. **Onde a seção 6 difere das recomendações das seções 0 a 5, vale a seção 6** (a Q4, a Q6, a Q7 e a Q8 mudaram). As respostas **estão** registradas em `DECISIONS.md` (DEC-179 a DEC-201, pela LW-146a).
- **Data e tarefa:** 11/11/2026 (Brasília), LW-146 (DOC), pré-etapa. Base: `main` em `4ada136`.
- **Fontes lidas (todas no `main`):** `DEVELOPMENT_ROADMAP.md` (RM: Fases 4 e 5, desvios 0.13-B, portões 0.13-C, anexos C e F); `DECISIONS.md` (as DEC da seção 1); `GDD.md` (3.2, 6, 7, 16, 17, 19, 20, 21, 24, 25 e anexos C e D); `TECHNICAL_ARCHITECTURE.md` (TA: 14, 15, 18, 19, 20 e 22); contratos `character`, `bridge`, `presentation`, `persistence`, `npc`, `world` e `economy`; `docs/decisions/0008-spike-sp6-combate.md`; `docs/backlog.md`. Não li código.
- **Rótulos:** **fato** (com a fonte), **recomendação** (minha, PROPOSTA: Arthur aprova ou troca), **buraco** (nenhuma fonte responde), **[HIP]**, **pendente**, **limitação**. "GDD 16.2" é o capítulo 16, seção 2.
- **Como ler:** cada item diz primeiro o **efeito** e depois o detalhe.
- **Termos:** **ponte** é o caminho entre o jogo que você vê e a simulação; **snapshot** é uma foto do estado da simulação, só para desenhar; **ViewModel** são os dados já prontos que uma tela lê; **LOD** é o nível de detalhe (S0 = NPC com corpo, S1 = sem corpo); **`t`** é o valor de 0 a 1 que diz o quanto a câmera subiu; **fixture** é um save de exemplo guardado para teste; **conservação** é a regra de que dinheiro e bens só mudam por regras (nada some nem aparece); **soak** é o teste de muitos dias sem jogador.

## 0. O essencial em doze linhas

1. A Fase 5 tem **47 tarefas** (LW-146 a LW-192). A LW-146 vem primeiro: sem ela nenhuma outra começa.
2. **Quatro decisões PENDENTES travam tarefas:** DEC-066 (sistema de combate), DEC-065 (derrota do jogador), DEC-053 (escala das batalhas) e DEC-029 (comando tático). Outras seis (DEC-030, 069, 024, 021, 010 e 040) têm recomendação simples e **não travam** se você aceitar o padrão.
3. Achei **14 contradições ou buracos** (seção 2). As cinco maiores: o **estilo do combate** (C1), a **derrota** (C2), o **equipamento** entre economia e personagem (C3), **crime sem lei** que o defina (C5) e o **save "congelado"** (C7).
4. A **DEC-121** (SP6) diz que bloqueio, esquiva e ferimento por golpe ficam para depois, mas o roadmap (LW-151, 153 e 156) e a arquitetura ainda os descrevem. O contrato do combate tem de partir da DEC-121.
5. Para **derrota**, o roadmap recomenda recarregar o último autosave; o GDD recomenda outra coisa (derrota raramente fatal). É decisão sua (Q4).
6. **Crime:** a Fase 4 cria só **uma** lei de crime ("pena") e nenhuma lista do que é crime; "roubo" não tem tarefa que crie a ação.
7. **Save:** o roadmap pede migrar saves antigos (LW-142 e LW-187), mas a DEC-134 e a DEC-127 dizem que **não se migra** até o "save congelado". Alguém precisa fixar a data (Q10).
8. A **ponte** foi desenhada fina e hoje não tem snapshot; a câmera com `t`, os marcadores e os painéis pedem snapshot e `ViewModel` (C6).
9. A **LW-146** deve ser dividida em **seis partes** (seção 3). Cerca de **doze** tarefas da fase provavelmente passam do limite de tamanho (estimativa por leitura, não medida).
10. **Perguntas:** 10 de **jogo** (Q1 a Q10, só você) e 10 **técnicas menores** (Q11 a Q20, o revisor decide como PROPOSTA). As quatro do roadmap estão em Q1, Q2, Q3 e Q4.
11. Das [REC] do roadmap, **concordo** com quase todas; **discordo** só de "propriedades fora" (Q1), porque o GDD manda manter a casa.
12. Nada disto muda código, dado ou evento.

## 1. Decisões de que a Fase 5 depende, com o status no `DECISIONS.md`

| Tema | DEC (status) | Trava o quê |
|---|---|---|
| Combate | **066 PENDENTE** (sistema definitivo); 067 PROPOSTA; **117 APROVADA** (só a direção: por alvo e habilidades); **121 APROVADA** (só ponto de partida); **053 PENDENTE** (escala das batalhas e se o jogador comanda); 052 PROPOSTA; 080 APROVADA (SP6 antecipado, já feito) | **066:** LW-150, 151 e 153 a 158 (o RM 0.13-C põe o portão na LW-152; o SP6 rodou, mas a DEC-066 segue PENDENTE). **053:** LW-158 |
| Personagem | 062 APROVADA (só a meta de três trajetórias); 063 PROPOSTA (3 a 4 origens); 064 PROPOSTA (quatro eixos, sem nível); **065 PENDENTE** (morte e derrota) | **065:** LW-156 e LW-174 |
| Ecologia, magia e chefe | 068 PROPOSTA (3 a 4 criaturas e 1 chefe); 099 PROPOSTA (lista de corte); 030 PENDENTE (magia); 054 APROVADA (cercos, exércitos grandes, magia ampla, domesticação etc. fora); 034 PENDENTE (domesticação) | LW-146 (corte); LW-157 |
| Eventos dinâmicos | 070 PROPOSTA (8 a 12 tipos, na Fase 5); 069 PENDENTE (diretor de eventos) | LW-162 (a 069 não trava se valer "sem diretor") |
| Crime, reputação e justiça | **nenhuma DEC trata disso como sistema** (a DEC-050 cria a organização criminosa e a DEC-062 só diz que crime é consequência; o resto é GDD 20, [PROP], e RM LW-164 e LW-165); a Fase 4 cria a reputação (LW-128) e as 5 leis (LW-117 e LW-129) | LW-163 a LW-165 (buraco, C5) |
| Câmera e interface | 025, 026, 115, 116, 119 APROVADAS; 027 APROVADA (só o princípio); **028 PROPOSTA** (`t` e três faixas); **029 PENDENTE** (profundidade do comando); 024 PENDENTE (gamepad); 057 APROVADA, 058 PROPOSTA (terreno e chunks); 074 PROPOSTA (ponte) | **028:** LW-166. **029:** LW-172. 024: LW-175 |
| Save | 081 APROVADA; **083 APROVADA só nos princípios** (em aberto: estado inteiro ou diferenças, slots, autosave, backups, tamanho e poda, o "save congelado", modo sem recarregar após a morte); 084 APROVADA (JSON comprimido); **127 e 134 APROVADAS** (versão 2; sem migrar até congelar) | LW-174, 176 e 187 |
| Desempenho | 071 PROPOSTA (orçamentos); 119 APROVADA (quadros); 113 APROVADA (só a régua da LW-023); 016 APROVADA (só a referência); 040 PENDENTE (quantos NPCs); 041 APROVADA (sem T0) | LW-178 a 183 (nenhuma trava a escrita do contrato) |
| Escopo e entrega | 098 PROPOSTA (conteúdo e quatro hipóteses); 021 PENDENTE (arte e áudio: o protótipo usa formas simples); 010 PENDENTE (nome comercial); 060 PROPOSTA (sem clima) | LW-188 (nome do executável; ver Q20) |

## 2. Contradições e buracos

**C1 — O estilo do combate está escrito de dois jeitos.** *Efeito:* se o contrato da ponte nascer do texto antigo, o projeto constrói detecção de contato que o combate escolhido não usa.
- **Fontes:** RM 5.D, LW-153 ("golpe leve e pesado, bloqueio, esquiva [texto a revisar à luz da DEC-117]") e LW-151 (`HitReport`, "áreas de contato em arma e corpo"); GDD 16.2 (ataques leves e pesados; bloqueio, parada, esquiva); TA 15.2 e 15.3 (`resolve_hit` com golpe leve ou pesado e defesa ativa; janelas de bloqueio e esquiva em tempo real; "a arma W tocou a zona Z").
- **Contra:** DEC-117 (por alvo, ataque automático e habilidades) e DEC-121, item 4 ("bloqueio e esquiva, ferimentos por golpe, magias e armas ficam para depois"), mais 0008 e `backlog.md`.
- **Recomendação:** o contrato do `combat` parte da DEC-121; a ponte leva uma intenção (quem, alvo, habilidade) e a simulação valida alcance, estamina e recarga. `HitReport` e contato só se você pedir (Q5 e Q11).

**C2 — Derrota do jogador: o roadmap e o GDD recomendam coisas diferentes.** *Efeito:* a escolha muda quantos sistemas novos a Fase 5 tem.
- **Fontes:** RM LW-146 (d) e Anexo F n.º 11 ("recarregar o último autosave", a opção A do GDD 6.6); GDD 6.6 e Anexo D, D2 (recomendam **B**: captura, nocaute, ferimentos persistentes, prisão, dívida); DEC-065 PENDENTE; DEC-083 (deixa em aberto o "modo sem recarregar após a morte").
- **Custo de B:** prisão e dívida. A justiça da Fase 5 só tem multa ou hostilidade (LW-165) e a economia não tem crédito (`economy.md`, seção 2: saldo nunca negativo).
- **Recomendação:** A para o protótipo, com aviso; B como [PREV] (Q4).

**C3 — Equipamento: quem cria o item, entre economia e personagem.** *Efeito:* sem uma regra, o metal gasto e a espada criada quebram a conservação de bens ou o "um dono por dado".
- **Fontes:** DEC-130 e `economy.md` (seções 3 e 12: a economia guarda **quantidades** de todo dono, inclusive o jogador; instâncias são do `character`, Fase 5); RM LW-105 (inventário e peso do jogador na economia); TA 15.4 e 15.6 (o `character` depende da economia "só por IDs de bens"; "o ferreiro consome metal e produz uma instância"); RM LW-148 ("conversão bem → item para **uma** receita de ferreiro"; "peso e capacidade respeitados").
- **Buracos:** (a) quem decide a qualidade e cria a instância; (b) com que motivo o metal sai da conservação (os motivos de destruição são um conjunto fechado: `consumed`, `maintenance`, `spoiled`); (c) o jogador terá **duas** contas de peso (bens na economia e instâncias no `character`), mas o peso afeta a estamina (GDD 16.5); (d) o ferreiro-jogador está fora (GDD 7.3, DEC-062) e a receita `forge_tool` só faz `tool`: **de onde vêm as armas?** (kit de origem, saque, ferreiro NPC); (e) **reparo** (GDD 16.5, TA 15.2: "atividade da economia") não está em nenhuma tarefa, só a quebra (LW-156).
- **Recomendação:** um contrato de fronteira só; peso total = soma de duas consultas; reparo no backlog (Q12).

**C4 — `combat` e `military`: o orçamento de corpóreos e o sentido das dependências.** *Efeito:* sem isso, as duas fichas se importam uma à outra.
- **Fontes:** TA 14.3 e 14.4 (`military` envia "encontros para `combat`" e recebe "baixas vindas de combate em S0"); TA 15.6 (`combat` devolve "baixas para `military`"; nenhuma das duas lista a outra como dependência); AGENTS 5.1 (ambos são camada 4: só `api`, sem ciclo); RM LW-158 ("orçamento de corpóreos (dezenas **[HIP]**)", baixas voltam à `Force`; "compatível em média"); RM 4.J ("combate corpóreo: Fase 5"); DEC-053 PENDENTE.
- **Buracos:** (a) o ciclo; (b) a "batalha em blocos" (parte em S0, parte abstrata) não tem fórmula; (c) "compatível em média" não diz a tolerância; (d) o valor do orçamento e se o jogador comanda (DEC-053 e DEC-029).
- **Recomendação:** um sentido só: `military` pede o encontro; `combat` devolve as baixas por evento; o orçamento vai para dados (Q6 e Q13).

**C5 — Crime e reputação contra as leis da Fase 4.** *Efeito:* o jogo teria testemunha e reputação, mas ninguém define o que é crime.
- **Fontes:** RM LW-117 (as 5 leis: tarifa, imposto de entrada, conscrição, **pena de crime**, licença) e LW-129 (`LawDef`: faixa, quem altera, efeito); RM LW-164 ("violar uma lei (agressão, roubo)"; "sem testemunha... pode ser descoberto por regra") e LW-165 (multa ou hostilidade); GDD 20.3 e 20.6 ("lei local define crimes e penas"; vestígios; guardas investigam; multa, prisão, exílio, caça); GDD 16.4 (roubo); TA 15.3 (`combat` publica `CrimeCommitted`).
- **Buracos:** (a) a lei de "pena" tem a pena, mas **nenhuma lei lista os atos**; (b) **roubo**: nenhuma tarefa cria a ação de roubar (LW-163 só trata percepção); (c) a "regra" de descobrir crime sem testemunha não existe; (d) o dono de `CrimeCommitted` (TA 15.3: `combat`; o RM LW-164 não diz); (e) prisão, exílio e caça (GDD 20.6) não estão no roadmap; (f) **nenhuma DEC** trata de crime como sistema.
- **Recomendação:** a LW-117 (Fase 4, ainda não feita) inclui os **atos criminosos** nos dados de lei; crime = agressão no protótipo (Q7 e Q14).

**C6 — A câmera com `t` contra a ponte fina.** *Efeito:* marcadores, camadas e painéis precisam de dados que a ponte de hoje não entrega.
- **Fontes:** TA 19.2 a 19.5 (`CameraRig`; "snapshot"; `ViewModel` "montado pela ponte"; `SetFocus` sai da apresentação) e RM LW-166, 169 e 173; `bridge.md` (a ponte é "mínima", sem dados; **"não há snapshot de visão, sinais nem tradução de eventos ainda"**; o foco do LOD vem da posição guardada no personagem, nunca da apresentação); `presentation.md` (já existe a `ThirdPersonCamera`, LW-046; o foco do terreno vem direto da apresentação).
- **Buracos:** (a) snapshot e `ViewModel` por painel engordam a ponte; (b) na visão tática, a câmera é livre: o foco do LOD segue a câmera ou o jogador?; (c) **neblina de conhecimento** (GDD 17.5 e 21.1: o mapa mostra só o que o jogador descobriu): nenhuma tarefa filtra as camadas por conhecimento; (d) a "terceira pessoa da Fase 1 vira `t` baixo" (LW-166) refaz a câmera existente.
- **Recomendação:** consultas em lote por assunto (como `peek_npc_bodies`), foco do LOD continua o jogador (Q15) e neblina como pergunta sua (Q8).

**C7 — Salvamento completo contra o "save congelado" e as fixtures.** *Efeito:* a Fase 5 manda migrar saves que o projeto decidiu rejeitar.
- **Fontes:** DEC-083 e TA 18.6 (até o "save congelado", proposto para "depois da validação da Fase 4", save antigo é **rejeitado**); DEC-127 (versão 2 até congelar; fixar a política "é decisão de Arthur"); DEC-134 e RM LW-111 (a Fase 3 **rejeita** o save antigo); RM LW-142 ("`save_version` com migração simples e fixture; save da Fase 3 migra e carrega"); RM LW-187 ("migração das fixtures LW-026, LW-111 e LW-142"); `persistence.md` (versão 2; fixture `save_v1`); AGENTS 12.5 (`tests/fixtures/` é protegida).
- **Contradições:** (a) LW-142 manda migrar o save da Fase 3, que a DEC-134 manda rejeitar; (b) a "fixture da LW-111" é de uma versão **rejeitada**, então não há o que migrar; (c) ninguém fixou o marco do congelamento nem o número final da versão; (d) fixture nova exige a sua autorização escrita.
- **Recomendação:** Q10.

**C8 — Eventos dinâmicos: efeitos sem comandos para produzi-los.** *Efeito:* "colheita ruim" ou "praga" não têm como acontecer pelas portas públicas de hoje.
- **Fontes:** RM LW-162 ("efeitos só por **comandos públicos dos módulos**"; 8 tipos, por exemplo colheita ruim, ataque a caravana, disputa escalando, visita de mensageiro); GDD 19.2 e 24.2 (8 a 12 tipos, "começar com cerca de 6"); `economy.md` seção 10 e `bridge.md` (nenhum comando de efeito; o único que mexe em estoque é `request_set_stock`, só de depuração); RM LW-139 (Fase 4: `CaravanAttacked` por criminosos); DEC-070 PROPOSTA, DEC-069 PENDENTE.
- **Buracos:** (a) cada tipo de evento exige comandos novos em outros módulos (contrato a estender); (b) "ataque a caravana" aparece na LW-139 e na LW-162; (c) 8 contra "cerca de 6".
- **Recomendação:** cada tipo declara em dados os comandos que usa; os que faltam viram extensões de contrato na LW-146; o ataque a caravana fica na LW-139 (Q16).

**C9 — Metas de desempenho com três réguas.** *Efeito:* a LW-180 pode "passar" ou "falhar" conforme a régua lida.
- **Fontes:** RM 5.F item 7 e LW-180 (tick médio ~3 ms normal e ~6 ms acelerado, "sem pico acima de ~10 ms"); TA 20.1 e DEC-113 (nenhum tick acima de 50 ms; no máximo 1 acima de 10 ms por minuto; **régua só da LW-023**); DEC-119 (média de 60 quadros e nenhum quadro acima de 33 ms, em release, no Mac de Arthur); TA 20.1 ("30 FPS de piso em aceleração"); DEC-071 PROPOSTA (orçamentos); TA 20.5 (cargas até 3.000 NPCs) contra RM LW-179 (até 1.000) e DEC-041.
- **Recomendação:** quadros pela DEC-119; ticks pelo RM como [HIP] e pela DEC-113 como mínimo; pedir a aprovação da DEC-071 **depois** da LW-179, com valores medidos; nada de 3.000 NPCs (Q17).

**C10 — Critérios de sucesso: o roadmap cobre menos que o GDD.** *Efeito:* a validação final pode aprovar o protótipo sem os critérios do GDD.
- **Fontes:** GDD 25.1 (seis critérios: mundo autônomo; **três cascatas** distintas; liberdade comprovada; consequências **horas depois**; viabilidade técnica; **diversão** e "histórias contáveis") e 25.3 (seis perguntas de playtest); RM 5.F e 5.H (quatro hipóteses e as seis perguntas do GDD 3.2); RM 4.F e LW-143 (**uma** cascata); GDD 24.1, hipótese 4 (LOD; RM desvio 2: só S0 e S1).
- **Recomendação:** Q9.

**C11 — NPC e personagem: quem tem equipamento e como o NPC combate sem importar `combat`.** *Efeito:* guardas, soldados e bandidos (T1) não teriam arma.
- **Fontes:** TA 15.4 (o `character` guarda jogador e **T2/T3**); RM LW-147 ("vale para jogador e T2/T3"); `npc.md` (seção "Dependências": **não importa** `character` e, depois da Fase 3, só `economy/api`; **não importa** `combat`); TA 15.6 (`combat` depende de `character` e `npc`); RM LW-155 (decisão de combate dos NPCs "pelo mesmo sistema de utilidade").
- **Buracos:** (a) quem cria o estado de T2/T3 no `character` e quando; (b) **T1** (guardas, soldados, bandidos) não tem `CharacterState`: de onde vêm arma e armadura no `CombatantState`?; (c) o `npc` decide lutar, mas não pode chamar o `combat` (camada 4); (d) em S1, sem corpo, como o NPC luta?
- **Recomendação:** o `npc` decide e publica a intenção; o `combat` escuta e resolve; equipamento padrão **por ofício**, em dados (Q18).

**C12 — A lista de corte, o roadmap e o GDD divergem em cinco pontos.**
- **Fontes:** RM LW-146 [REC] e GDD 24.5 e DEC-099 (PROPOSTA). (a) **Propriedades:** [REC] "fora"; GDD 24.5 "manter apenas a casa"; RM LW-173 já tem painel "propriedades (a casa)"; GDD 21.2 [P1]. (b) **Comando tático:** [REC] "fora, só consulta"; GDD 21.1 e 24.2 "visão tática simples"; DEC-029 PENDENTE; RM LW-172 "seleção tática". (c) **Chefe e magia:** GDD 24.2 (1 chefe, 0 a 2 efeitos) contra [REC] "fora". (d) **Números:** GDD 3 a 4 criaturas, 3 a 4 origens e 8 a 12 eventos contra RM 3, 3 e 8. (e) **Facção criminosa:** GDD 24.5, item 5, corta a "completa" e mantém a "mínima" (igual ao [REC] e à DEC-050).
- **Recomendação:** Q1 a Q3.

**C13 — Interface que o GDD pede e nenhuma tarefa da Fase 5 cria.** *Efeito:* o combate fica sem HUD de vida e estamina e o equipamento sem tela.
- **Fontes:** GDD 21.2 [P1] (HUD de vida, estamina, alvo, hora, dinheiro; inventário e equipamento; diário; painéis); RM: HUD só de data e hora (LW-051); mercado e contratos na Fase 3 (LW-106 a LW-108); na Fase 5 só mapa, relações, propriedades e conhecimento (LW-173), menus e ajuda (LW-175 e LW-186).
- **Recomendação:** acrescentar ao contrato da LW-146 o HUD de combate e a tela de inventário e equipamento (Q19).

**C14 — Descompassos pequenos de texto (para a parte 146a corrigir).**
- (a) `persistence.md` diz que a DEC-084 "segue PROPOSTA"; no `DECISIONS.md` ela é **APROVADA**.
- (b) TA 14.4, 15.6 e 18.8 listam `entities` como dependência; esse módulo **não existe** (DEC-141: os IDs vêm de `ctx.ids`).
- (c) `bridge.md` (Limitações): a fila de intenções "não tem tamanho máximo" e o teto, e quem a consome, ficam "para a tarefa que definir a primeira intenção concreta". **Essa tarefa será a do combate** (Q11): a LW-151 ou a LW-153 terá de definir o teto e o consumo da fila.
- (d) RM 0.13-C dá a DEC-066 como portão da LW-152, mas ela segue PENDENTE (DEC-121); a mesma tabela dá a DEC-053 como decidível na LW-146, ainda sem resposta.

## 3. Divisão sugerida da LW-146 e tarefas que provavelmente passam do limite

**Partes (um arquivo, um dono; as partes de contrato rodam em paralelo depois das suas respostas):**

| Parte | Arquivos | Fecha |
|---|---|---|
| **146a** (registro) | `DECISIONS.md` (as DEC novas), `ROADMAP_STATUS.md` (lista do que está **dentro** e **fora**), textos antigos do roadmap (LW-151, 153, 156, 158, 142 e 187) | decisões Q1 a Q10; C1, C2, C7, C10 e C12 no papel |
| **146b** (combate) | `docs/modules/combat.md` (novo) | C1, C4 (lado `combat`), C5 (lado `combat`) |
| **146c** (personagem) | `docs/modules/character.md` (extensão: habilidades, inventário de equipamentos, corpo, conhecimento, origem) e a fronteira com `economy.md` | C3 e C11 |
| **146d** (mundo vivo) | `docs/modules/ecology.md` (novo) e a seção de eventos dinâmicos no contrato de `events` (criado na LW-117) | C8 |
| **146e** (câmera e interface) | `docs/modules/presentation.md` e `docs/modules/bridge.md` (**só esta parte mexe na `bridge.md`**; a 146b entrega o texto da ponte de combate) | C6 e C13 |
| **146f** (dados e eventos) | `docs/events.md` e um `dados.md` por área (armas, armaduras, habilidades, origens, criaturas, eventos) | catálogo de eventos novos; formatos |

**Tarefas que provavelmente passam do limite de ~300 linhas e 8 arquivos (AGENTS 5.2 e DEC-126; estimativa por leitura, não medida):**

| Tarefa | Motivo | Divisão sugerida |
|---|---|---|
| LW-150 | estado, estamina, `resolve_hit` e 4 tabelas de dados | 150a estado e estamina; 150b `resolve_hit` e tabelas |
| LW-153 | simulação e apresentação juntas (AGENTS 5.2: um módulo por tarefa) | 153a regras e ponte; 153b alvo, habilidades e HUD |
| LW-155 | toca `npc` e `combat` | 155a decisão; 155b execução |
| LW-156 | ferimentos, morte, durabilidade e derrota | 156a ferimentos e morte; 156b durabilidade; 156c derrota |
| LW-158 | toca `military` e `combat` | 158a orçamento e encontro; 158b baixas |
| LW-162 | motor mais 8 tipos em dados | 162a motor; 162b conteúdo |
| LW-166 e 167 | câmera, curvas, histerese, terreno em altura e carga assíncrona | 166a `t` e curvas; 166b controle; 167a malha baixa; 167b chunks assíncronos |
| LW-173 | quatro painéis | 173a mapa e relações; 173b propriedades e conhecimento |
| LW-174 | `serialize` de **todos** os módulos (viola "um módulo por tarefa") | 174a ordem de carga e `validate`; 174b versão e módulo ausente |
| LW-185 e 187 | console sobre vários módulos; migrações com fixtures | por grupo de módulos; 187a cadeia de migração (conforme Q10) |

## 4. Perguntas para Arthur

**Decisões de JOGO (só você decide)**

**Q1 — O que fica de fora (lista de corte; GDD 24.5, DEC-099, RM LW-146 a).**
- **Pergunta:** quais sistemas a Fase 5 **não** faz?
- **Opções:** **A)** as [REC] do roadmap (magia, chefe, propriedades, comando tático só de consulta, facção criminosa mínima); **B)** A, mas **mantendo a casa do jogador**; **C)** B mais 1 efeito mágico simples (GDD 24.2 admite 0 a 2).
- **Recomendação: B.** Concordo com magia, chefe, comando tático e facção mínima; discordo de "propriedades fora": o GDD 24.5 manda manter a casa e a LW-173 já prevê o painel. A "casa" é um local `home` do mundo, sem compra, venda nem expansão.
- **O que muda:** A tira o painel "propriedades" e a casa da origem; B os mantém (pouco trabalho); C acrescenta um sistema inteiro (DEC-030): **não recomendo**.
- **Resposta de Arthur (11/11/2026):** magia, chefe, comando de tropas e facção criminosa completa **fora**; **a casa do jogador fica**. Magia e batalhas grandes viram **visão registrada** (Bannerlord, Total War Warhammer 3, sequência de magias). Igual à recomendação (B).

**Q2 — As três trajetórias (RM LW-146 b; DEC-062).**
- **Pergunta:** confirma mercador, soldado/guarda e aventureiro, com crime só como consequência?
- **Opções:** **A)** as [REC]; **B)** trocar soldado por produtor/artesão; **C)** quatro trajetórias.
- **Recomendação: A.** Cada uma já tem sistemas na fase (mercador: LW-105 e LW-139; soldado: LW-120, 139 e 153; aventureiro: LW-157, 160 e 161). B exigiria atividades de produção do jogador (GDD 7.6: o primeiro protótipo não as tem) e a receita de ferreiro do jogador.
- **O que muda:** B acrescenta produção do jogador e muda a LW-184; C é mais escopo (R5.4).
- **Resposta de Arthur (11/11/2026):** **A**, mercador, soldado/guarda e aventureiro. Igual à recomendação.

**Q3 — Conteúdo inicial: 3 criaturas, 3 origens, 8 eventos (RM LW-146 c).**
- **Pergunta:** são esses os números?
- **Opções:** **A)** 3/3/8 do roadmap; **B)** 3/3/6 (o GDD diz "começar com cerca de 6"); **C)** 4/4/10.
- **Recomendação: A**, com a origem **por lugar de nascimento** (campo, cidade, estrada), **não por trajetória** (GDD 6.2; DEC-063 conflita com a DEC-003 se a origem virar classe). Com o chefe fora (Q1), 3 criaturas bastam (patrulhar, caçar, fugir, como a LW-157). Os tipos concretos e os 8 eventos vêm no contrato, como PROPOSTA, com nomes genéricos (DEC-100).
- **O que muda:** B poupa 2 eventos em dados; C aumenta conteúdo e testes.
- **Resposta de Arthur (11/11/2026):** **A**, 3 criaturas, 3 origens (por lugar de nascimento) e 8 eventos. Igual à recomendação.

**Q4 — Derrota do jogador (RM LW-146 d; GDD 6.6; DEC-065; C2).**
- **Pergunta:** o que acontece quando o jogador perde a luta?
- **Opções:** **A)** recarregar o último autosave, com aviso; **B)** derrota raramente fatal (captura, nocaute, ferimentos persistentes, prisão, dívida); **C)** morte permanente com sucessor.
- **Recomendação: A**, com **B como [PREV]**. B exige prisão e dívida (dois sistemas novos) e C exige famílias (fora do protótipo, DEC-054). **Concordo com a [REC] do roadmap e discordo do GDD 6.6**; se escolher A, o GDD 6.6 e o Anexo D, D2, são atualizados na LW-189.
- **O que muda:** A exige autosave frequente (LW-176) e a mensagem; B abre tarefas em `politics` e `economy`.
- **Resposta de Arthur (11/11/2026) — MUDOU:** **dois modos à escolha ao começar.** (a) **Renasce perto**, sem recarregar: itens **soltos** ficam no chão por um tempo, NPCs podem pegá-los, o jogador **descobre qual NPC pegou** ou corre até o local antes de sumirem; itens **ligados ao personagem** ficam. (b) **Voltar ao último autosave.** A recomendação era só o (b).

**Q5 — Combate: o que entra além do SP6 (DEC-121; C1).**
- **Pergunta:** a Fase 5 faz só o que você jogou no SP6 (alvo, habilidades, estamina) mais o inimigo que reage, ou também bloqueio, esquiva e ferimento por golpe? E o que é o "melhorado" da DEC-117?
- **Opções:** **A)** só o SP6 mais o inimigo que **reage e se posiciona** (pedido da DEC-121); ferimento = vida e uma condição simples "ferido" que se recupera com o tempo; **B)** A mais bloqueio e esquiva; **C)** A mais ferimentos por golpe (sangramento, atordoamento; GDD 16.2).
- **Recomendação: A**; B e C vão ao backlog até um **playtest seu** depois da LW-155. O "melhorado" continua em aberto: uma frase sua ajuda o contrato.
- **O que muda:** B e C mudam a LW-151, 153 e 156 e pedem novo playtest.
- **Resposta de Arthur (11/11/2026):** **A**, só o do SP6 mais o inimigo que reage; ferimento simples; bloqueio, esquiva e ferimento por golpe ficam para depois. Igual à recomendação.

**Q6 — Escala das batalhas e comando (DEC-053 e DEC-029; C4).**
- **Pergunta:** quantos combatentes com corpo ao mesmo tempo, e o jogador comanda tropas?
- **Opções:** **A)** o jogador **não comanda**; no máximo cerca de **20** [HIP] com corpo perto dele e o resto abstrato; a câmera tática só consulta; **B)** o jogador comanda um grupo pequeno; **C)** batalha toda abstrata, sem corpos.
- **Recomendação: A.** B exige interface de ordens (DEC-029) e C enfraquece a hipótese do LOD.
- **O que muda:** destrava a LW-158 e a LW-172; B cria tarefas de ordens.
- **Resposta de Arthur (11/11/2026) — MUDOU:** **sem comando no protótipo**, mais **um teste descartável** de comandar um grupo pequeno, no fim do bloco de combate. A recomendação era só A (sem comando e sem teste). Visão registrada: Bannerlord, Total War Warhammer 3, magias em sequência.

**Q7 — Crime: quais atos (C5).**
- **Pergunta:** o que conta como crime no protótipo?
- **Opções:** **A)** só **agressão** (nasce do combate); **B)** agressão e **roubo** (cria a ação de roubar e usa a furtividade); **C)** B mais contrabando.
- **Recomendação: A.** Nenhuma tarefa cria o roubo hoje e a agressão já prova a consequência (testemunha, reputação, guarda). Roubo vai ao backlog.
- **O que muda:** B acrescenta uma ação e um sistema de itens roubados.
- **Resposta de Arthur (11/11/2026) — MUDOU:** **agressão, roubo, morte e contrabando.** Contrabando = lista de bens proibidos por lei **mais** marca de origem nos itens únicos roubados ou saqueados; rastrear cada unidade fica para depois. Saque de mortos conta como roubo. A recomendação era só agressão.

**Q8 — Neblina de conhecimento no mapa (GDD 17.5 e 21.1; C6).**
- **Pergunta:** o mapa estratégico mostra tudo ou só o que o jogador descobriu?
- **Opções:** **A)** mostra tudo, marcado como **limitação [LIM]**; **B)** só o descoberto (ruína, assentamentos visitados, rumores).
- **Recomendação: A.** Nenhuma tarefa filtra as camadas por conhecimento e o custo é alto; a hipótese 4 não depende disso.
- **O que muda:** B pede que o `character/knowledge` registre lugares e que cada camada filtre.
- **Resposta de Arthur (11/11/2026) — MUDOU:** **estrutura sempre visível** (assentamentos, rotas, pontos de reconhecimento); **segredos só depois de descobertos** (ruínas, tesouros, minérios, covis escondidos), com a regra **por tipo, em dados**. A recomendação era mostrar tudo.

**Q9 — Critérios de sucesso do protótipo (C10).**
- **Pergunta:** valem só as quatro hipóteses do roadmap ou também critérios do GDD 25.1?
- **Opções:** **A)** as do roadmap; **B)** A mais "três cascatas distintas" e "diversão e histórias contáveis" no playtest; **C)** os seis do GDD 25.1.
- **Recomendação: B.** É barato: o soak mostra mais cascatas além da LW-143 e a diversão vira pergunta do playtest (GDD 25.3).
- **O que muda:** B acrescenta itens ao 5.F e à LW-191.
- **Resposta de Arthur (11/11/2026):** **B**, as quatro hipóteses mais três cascatas e diversão. Igual à recomendação.

**Q10 — Congelar o save (C7; DEC-127 diz que é decisão sua).**
- **Pergunta:** quando o save é "congelado" e saves antigos passam a ser migrados?
- **Opções:** **A)** no fim da Fase 4 (LW-142), como propõe a DEC-083; **B)** no fim da Fase 5 (LW-187); **C)** **não congelar no protótipo**: save antigo é sempre rejeitado com mensagem clara.
- **Recomendação: C.** Cada mudança de estado da Fase 5 (personagem, combate, criaturas, eventos) exigiria migração e fixture (fixture é protegida e pede autorização), e o protótipo não tem saves antigos de outras pessoas. A LW-187 vira "testes de rejeição clara e da cadeia que já existe (1 para 2)".
- **O que muda:** A e B mantêm o roadmap, mas exigem a LW-142 e a LW-187 como estão (C7); C troca os critérios 6 de 5.F e das LW-142 e LW-187.
- **Resposta de Arthur (11/11/2026):** **C**, não congelar o save no protótipo. Igual à recomendação.

**Técnicas menores (o revisor decide como PROPOSTA; você aprova ou troca)**

**Q11 — Ponte de combate (C1).** Opções: **A)** intenção de ataque (atacante, alvo, habilidade); **B)** `HitReport` por contato. **Recomendação: A** (é o que a DEC-121 testou e a simulação continua sem confiar no cliente). Muda: LW-151 e LW-153; sem "áreas de contato". **Situação (11/11/2026):** recomendação mantida (PROPOSTA); a aprovar na 146a.

**Q12 — Fronteira equipamento e economia (C3).** Opções: **A)** a economia destrói o metal com um **motivo fechado novo** e publica um evento; o `character` cria a instância ao ouvir; **B)** o `character` chama a `economy/api` e cria a instância; **C)** o ferreiro NPC vende itens como **bens** (sem instância) no protótipo. **Recomendação: A** (mantém a conservação e "um dono por dado"); peso = soma de duas consultas; reparo no backlog. Muda: `economy.md` ganha 1 motivo e 1 evento; LW-148. **Situação (11/11/2026):** recomendação mantida (PROPOSTA). **Efeito novo:** o item no chão, o saque de mortos e a marca de origem entram nessa fronteira (6.3).

**Q13 — `combat` e `military` (C4).** Opções: **A)** um sentido: `military` pede o encontro e `combat` devolve baixas por evento; **B)** mão dupla pela `api`. **Recomendação: A**; orçamento de corpóreos em dados (o valor sai com a Q6). Muda: LW-158 e a ficha do `military`. **Situação (11/11/2026):** recomendação mantida (PROPOSTA). O orçamento de corpóreos segue [HIP]; o valor sai depois do teste de tropas.

**Q14 — Dono do crime (C5).** Opções: **A)** `combat` só informa o fato; `events` ou `politics` decide se é crime pela lista de atos em `laws.json` e publica `CrimeCommitted`; **B)** `combat` publica (TA 15.3). **Recomendação: A**, pedindo à LW-117 a lista de atos. Muda: LW-117, 164 e 165. **Situação (11/11/2026):** recomendação mantida (PROPOSTA). **Efeito novo:** os atos são agressão, roubo, morte e contrabando, não só agressão (6.3).

**Q15 — Ponte, snapshot e foco do LOD (C6).** Opções: **A)** consultas em lote por assunto e o foco do LOD continua o jogador; **B)** um `Snapshot` por quadro e o foco segue a câmera. **Recomendação: A** (menos mudança; S0 só perto do jogador; os marcadores cobrem o resto). Muda: LW-166 e LW-169. **Situação (11/11/2026):** recomendação mantida (PROPOSTA). **Efeito novo:** a regra de visibilidade por tipo (Q8) entra nas consultas em lote.

**Q16 — Eventos dinâmicos (C8).** Opções: **A)** cada tipo declara em dados os comandos que usa; os que faltam viram extensões de contrato; **B)** deixar `events` escrever direto nos outros módulos (proibido pela arquitetura). **Recomendação: A**; "ataque a caravana" fica só na LW-139. Muda: contratos de `economy`, `npc` e `world`; LW-162. **Situação (11/11/2026):** recomendação mantida (PROPOSTA); a aprovar na 146a.

**Q17 — Desempenho (C9).** Opções: **A)** quadros pela DEC-119; ticks pela meta do RM como [HIP] e pela DEC-113 como mínimo; aprovar a DEC-071 só depois da LW-179; cargas até 1.000 NPCs; **B)** adotar já os números do RM como regra. **Recomendação: A.** Muda: texto de 5.F e LW-179 e 180. **Situação (11/11/2026):** recomendação mantida (PROPOSTA); a aprovar na 146a.

**Q18 — T2/T3, T1 e combate (C11).** Opções: **A)** o `npc` decide e publica a intenção; o `combat` escuta e resolve; o `character` cria o estado de T2/T3 na promoção; T1 usa **equipamento padrão por ofício** em dados; **B)** o `npc` guarda o mínimo de combate. **Recomendação: A.** Muda: LW-147, 155 e 161. **Situação (11/11/2026):** recomendação mantida (PROPOSTA); a aprovar na 146a.

**Q19 — HUD de combate e inventário (C13).** Opções: **A)** acrescentar uma tarefa de HUD (vida, estamina, alvo) e uma de inventário e equipamento; **B)** usar só os painéis do roadmap. **Recomendação: A** (sem HUD o combate não é jogável). Muda: duas tarefas novas na Fase 5. **Situação (11/11/2026):** recomendação mantida (PROPOSTA); a aprovar na 146a.

**Q20 — Nome do executável (DEC-010 PENDENTE; LW-188).** Opções: **A)** "Living World" (o título de trabalho que já está no `project.godot`) como nome **provisório**; **B)** esperar a DEC-010. **Recomendação: A**: a DEC-010 não precisa ser fechada para exportar. **Situação (11/11/2026):** recomendação mantida (PROPOSTA); a aprovar na 146a.

## 5. Riscos para o protótipo (DEC-006: uma pessoa com IA) e o que adiar

**Riscos:**
- **R1.** Fase de 47 tarefas: cansaço e perda de rumo (RM R5.8). Mitigação: corte da Q1, blocos com revisão, tarefas de tamanho pequeno.
- **R2.** Combate sem "sensação": o SP6 só testou 1 contra 1 com boneco parado (0008). Mitigação: playtest seu depois da LW-155.
- **R3.** Contratos que mudam outros contratos (C3, C8 e C11 mexem em `economy`, `npc` e `world`): risco de reabrir a Fase 3. Mitigação: partes 146c e 146d só listam extensões pequenas e pedem a sua aprovação.
- **R4.** A ponte engordar e perder a regra "fina" (C6). Mitigação: consultas em lote e um dono só para a `bridge.md` (146e).
- **R5.** Save e migração: custo alto de fixtures protegidas (C7). Mitigação: Q10.
- **R6.** Soak de 3 anos com 3 sementes demora no `check_all`. Mitigação: medir na LW-179 antes de decidir o que roda sempre e o que roda sob pedido.
- **R7.** Decisões PENDENTES (066, 065, 053, 029) travarem blocos inteiros. Mitigação: respondê-las **antes** da 146a.

**Para o backlog (uma linha cada; fora da Fase 5 se você concordar):** magia; chefe e criaturas especiais; propriedades além da casa; comando tático; bloqueio e esquiva; ferimento por golpe (sangramento, atordoamento); roubo e contrabando; prisão, exílio e caça; dívida e derrota do tipo B; morte permanente com sucessor; neblina de conhecimento no mapa; reparo de equipamento; bestas e mais armas (GDD 16.5 pede 5 a 6, o roadmap só o arco); gamepad (DEC-024); acessibilidade (legendas, daltonismo; GDD 21.4, P2); diretor de eventos; domesticação; clima e estações; cargas de 3.000 NPCs e T0; save binário.

**O que não consegui verificar:** o tamanho real das tarefas (estimativa por leitura); o código (não li); se o `ROADMAP_STATUS.md` já tem a seção "Itens dentro e fora do protótipo" (o roadmap diz que a LW-146 a preenche; não a achei); a existência do `docs/decisions/0013` (não há no `main`).

## 6. Respostas de Arthur (11/11/2026) e o que elas mudam

**6.1 Resumo das respostas.** Feitas no chat, pelo painel de escolhas. Iguais à recomendação: Q1, Q2, Q3, Q5, Q9 e Q10. **Mudaram:** Q4 (morte), Q6 (tropas), Q7 (crime) e Q8 (mapa). Também pediu **marcar "protótipo" e "depois"** (6.4). As técnicas Q11 a Q20 ele **não reabriu**: seguem como PROPOSTA do revisor.

**6.2 O que cada resposta resolve nas contradições da seção 2.**
- **C1 (estilo do combate):** resolvida em direção: Q5 A (alvo e habilidades; bloqueio, esquiva e ferimento por golpe depois). O contrato parte da DEC-121.
- **C2 (derrota):** resolvida: **dois modos** (Q4). O GDD 6.6 e o Anexo D, D2, são atualizados na LW-189. Prisão e dívida ficam fora; a economia continua sem crédito.
- **C4 (combate e tropas):** DEC-053 e DEC-029 **seguem PENDENTES até o teste de tropas**; sem comando no protótipo.
- **C5 (crime):** a lista de atos cresce para **agressão, roubo, morte e contrabando**; a LW-117 (Fase 4) precisa dela (Q14).
- **C6 (neblina de conhecimento):** resolvida pela Q8: regra de visibilidade por tipo, em dados.
- **C7 (save):** Q10 C: a LW-142 e a LW-187 passam a testar rejeição clara, não migração.
- **C10 (critérios):** Q9 B: o 5.F e a LW-191 ganham "três cascatas" e "diversão".
- **C12 (corte):** Q1; os números de conteúdo ficam 3/3/8.
- **Seguem como estavam:** C3, C8, C9, C11, C13 e C14.

**6.3 Buracos novos que as respostas criam (para o contrato da LW-146 fechar).**
- **(a) Itens no chão e em corpos.** Pede um **novo tipo de dono** para quantidades de bens e para instâncias; o tempo no chão e a "perda por sumiço" usam o motivo de destruição já reservado (`spoiled`) sem quebrar a conservação; NPC pegar item é ação nova do NPC; descobrir **qual NPC pegou** usa memória ou rumor e uma consulta. Um só sistema serve à morte do jogador, ao saque de mortos e ao roubo.
- **(b) "Item ligado ao personagem" sem magia.** Com a magia fora, o que é um item ligado? Ele pediu "poder ou maldição" (magia, agora "depois"). Sem resposta.
- **(c) Dois modos de morte.** A escolha entra no menu de novo jogo (LW-175); "voltar ao autosave" depende de autosave frequente (LW-176); "renasce perto" precisa de **ponto de renascimento** (hoje só existe o ponto de nascimento do `world`) e de regra do que se perde.
- **(d) Crime ampliado.** Morte de NPC com testemunha; **roubo** e **saque** são ações novas (usam a furtividade da LW-163); **contrabando** = bens proibidos por polity (o `TradeRules` já tem `banned` e licença; é neutro até a LW-130) mais **marca de origem** num campo da instância do `character` (itens únicos); quem fiscaliza são os guardas (LW-165).
- **(e) Mapa.** Regra de visibilidade por tipo; o `character/knowledge` registra o que foi descoberto; falta definir o que um **ponto de reconhecimento** revela.
- **(f) Teste de tropas.** É um **spike novo** (descartável, como o SP6). A DEC-080 só aprova a antecipação dos testes de combate e de câmera: o spike novo precisa de **registro** (146a), de lugar no roadmap (depois da LW-155 e antes da LW-159) e de número.

**6.4 Protótipo e depois.**
- **Protótipo (entra na Fase 5):** combate do SP6 com inimigo que reage; três trajetórias; 3 criaturas, 3 origens e 8 eventos; casa do jogador; morte com dois modos, itens no chão e descoberta de quem pegou; crime (agressão, roubo, morte, contrabando simples); mapa com estrutura sempre e segredos descobertos; teste descartável de tropas; critérios da Q9; save sem congelar; mais as técnicas Q11 a Q20 (PROPOSTA).
- **Depois (visão registrada):** sistema de magia, itens de poder ou maldição, chefe, comando de tropas (Bannerlord, Total War Warhammer 3, sequência de magias: "um sistema novo único"), bloqueio e esquiva, ferimento por golpe, prisão e dívida, rastreio de cada unidade de mercadoria, morte permanente com sucessor.
- **Tarefas novas, estimativa do revisor [HIP], não medida:** itens no chão e corpos (2 a 3), dois modos de morte e renascimento (2), descobrir quem pegou (1), roubo e saque (2), contrabando com lista e marca (2), mapa por tipo (1 a 2) e o teste de tropas (1): **cerca de 11 a 14** a mais que as 47 (uns 25%). Entram nas partes 146b, 146c, 146d e 146e; a 146a registra.

**6.5 Perguntas que ficam em aberto (curtas):** quanto tempo o item fica no chão; como se descobre o NPC que pegou; o que é "item ligado" sem magia; o que um ponto de reconhecimento revela.
