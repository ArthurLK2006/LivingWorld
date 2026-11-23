# C4: os postos pagam 24 horas e a rotina dá 11 horas de serviço (análise, 23/11/2026)

**Estado: análise de leitura, a pedido de Arthur (23/11/2026); nada foi implementado, nenhuma simulação nova, nenhum salário, duração de trabalho ou regra foi alterado.** Base: `main` em `89d935d`. **[HIP]** marca conta ou suposição do autor. O canal C4 vem do [estudo do retorno do dinheiro](estudo-retorno-do-dinheiro-23-11.md), seção 2.2. Conferência feita pelo Maestro: a rotina dos dois ofícios, a ausência do relógio no `ServicePostBook`, a chamada em `economy_runtime.gd` e a validação inteira de `wage_per_hour` batem com o código.

## Respostas em uma frase
1. **Não é remuneração indevida, mas as 24 horas nunca foram decididas:** "a cada hora" é texto aprovado (Q15, Q18 A, DEC-164 e DEC-152); as 24 horas por dia são a consequência dele, sem exame antes dos estudos de 21 e 23/11, e na prática viram uma renda-base de 24 moedas por dia.
2. **Sim:** o código paga 24 vezes por dia; a rotina dá 11 horas de `work` ao guarda e ao estalajadeiro; não existe contador de "serviço executado".
3. **Hoje o portador ganha 24 e come cerca de 15 (sobra +9); 11 horas a 1 dão 11 (falta 4), a 2 dão 22 (sobra 7): nenhum valor inteiro fecha** (tabela na seção 3).
4. **Só dados (LW-112) não resolve:** a renda do dia só anda de 24 em 24; pagar o serviço pede código (máscara de horas: classe 3 com itens de classe 4); pagar pela ação `work` concluída viola a DEC-152.
5. **Recomendação:** não mudar nada agora; Arthur decide o princípio; se for "pagar o serviço", fazer uma tarefa própria antes da LW-112.

## 1. Regra deliberada ou remuneração indevida?
| Camada | O que diz | Estado |
|---|---|---|
| Aprovado | Postos, folha pela conta do mercado, salário por hora, provisório até a Fase 4: DEC-164 (10/11) e DEC-174 | APROVADA |
| Aprovado | Salário "sem depender de `work` terminar (em S0 dependeria do corpo)", "vale também para os postos": DEC-152, `npc.md` (Q18) | APROVADA em bloco, 11/11 |
| Aprovado | Cadência: locais "só nas horas em que produz", o posto "a cada hora" (`economy.md` seção 6, `npc.md`, `events.md`) | texto do contrato |
| Proposta/HIP | A ordem "postos antes dos locais (passo 0)" e os números: "[PROPOSTA/HIP], calibração na LW-112"; a aprovação em bloco "não transforma valor [HIP] em requisito" | PROPOSTA/HIP |
| Não examinado | "24 horas contra horas de serviço": nenhuma ocorrência em DEC, Q ou contratos (busca por palavra); a 1ª menção é o estudo `lw-094a-estudo-21-11.md` | consequência |
- O "sem depender de `work`" é escolha de desenho (desacopla a economia do corpo) e vale para o posto.
- O princípio da LW-094b ("trabalho efetivamente realizado") está escrito para EQUIPES de locais de produção (`contrato-lw-094b-regras-de-oferta.md`; `economy.md` seção 6: "nenhuma é paga sem poder produzir"). O posto não tem lote nem equipe: estendê-lo é decisão nova. Precedente de 23/11: Arthur manteve a folha CHEIA dos excedentes dos locais.
- **Franqueza:** em substância 54% da folha (390 de 720 moedas por dia) cai fora do serviço, o que se parece com a "folha das horas paradas". Em origem não é máscara: vem de 11/11 (LW-095), anterior a qualquer defeito de calibração, e o propósito era dar renda a ofícios sem receita (DEC-164). É uma **renda-base de fato, não declarada como tal**.
- Se a regra mudar, mudam o texto "a cada hora" (`economy.md` seções 6, `npc.md`, `events.md`) e a DEC-152; a DEC-164 e a DEC-174 (pagador e provisório) não.

## 2. Há mesmo 24 horas pagas contra 11 de serviço?
| Ofício (portadores) | `work` | Refeição | Sono | Descanso e conversa |
|---|---|---|---|---|
| Guarda (18 = 8 + 5 + 5) | 11 h (7-13 e 15-20) | 3 h | 8 h | 2 h (14-15 e 21-22) |
| Estalajadeiro (12 = 6 + 3 + 3) | 11 h (9-14 e 15-21) | 3 h | 8 h | 2 h (7-9) |
- Fonte: `data/routine_blocks.json` (por ofício, sem exceção por NPC no arquivo); o pensador pode tirar o NPC da rotina por necessidade urgente; a ação `work` dura 240 minutos (`data/actions.json`).
- Das 720 moedas por dia: serviço 330 (46%), sono 240 (33%), refeição 90 (12%), descanso e conversa 60 (8%).
- Código: `ServicePostBook.hour_step()` não recebe a hora e "nunca olha o relógio"; `economy_runtime.gd` o chama toda hora cheia; os locais de produção recebem a hora absoluta, só para o rodízio. O mesmo desenho "hora da economia, não do corpo" vale para os locais: a folha é por hora de produção, não de rotina. A diferença é que a produção limita as horas (insumo, espaço, comprador, caixa), e o posto, sem produção, só é limitado pelo caixa do mercado.
- **Serviço executado:** nada em `src/` ou `data/` (busca por `WorkCompleted`, `hours_worked`, `service_done` e parecidos); `events.md` só tem `WagesPaid`. O mais próximo é a conclusão da ação `work` no `npc` (a economia não é avisada) e a tabela da rotina (agenda, não execução). Para o posto, "estar" e "servir" são a mesma coisa.
- **Não contado:** quantas horas de `work` o portador de fato executa por dia (viagem, fome urgente, ações de 240 minutos).

## 3. Impacto nos saldos (aritmética; sem simulação nova)
Premissas: 30 portadores; `wage_per_hour` inteiro e maior ou igual a 0 (validação do `ServicePostBook`); comida de 15 moedas por dia **[HIP]** (a fome sobe 5 por hora, uma refeição tira 60, logo 2 refeições por dia; pão de 5 a 10 moedas dá 10 a 20; os estudos usam 15); saldo inicial de cerca de 71 por portador (2.137 ÷ 30).
| Hipótese | Horas × valor | Renda por dia | Folha por dia | Sobra (renda − 15) | Grupo P por dia | Saída do caixa a menos que hoje | Sem `FoodStub` |
|---|---|---|---|---|---|---|---|
| H0 hoje | 24 × 1 | 24 | 720 | +9 | +270 | 0 | **medido:** portadores vivos 30, 21, 16 e 0 nos dias 7, 14, 20 e 29; morrem com cerca de 179 moedas cada: falta comida, não dinheiro |
| H1 | 11 × 1 | 11 | 330 | −4 | −120 | 390 (54%) | **[HIP]** o dinheiro zera no dia ~18 (71 ÷ 4); a falta de comida já decide antes |
| H2 | 11 × 2 | 22 | 660 | +7 | +210 | 60 (8%) | **[HIP]** igual a H0 |
| H3 (fecha 15) | 11 × 1,36 | 15 | 450 | 0 | 0 | 270 (38%) | não existe em inteiro |
- **Granularidade:** com 24 horas a renda só é 0, 24, 48...; 24 já é o menor valor positivo. Com 11 horas só 11 ou 22. 11 contra 15 e 22 contra 15 não fecham: ou o caixa melhora (H1) ou o portador come com folga (H2), não os dois.
- Medido (H-K, S-A, semente 1, com `FoodStub`, base; [experimento-hk-23-11.md](experimento-hk-23-11.md)): caixa dos mercados 8.145 → 367 em 30 dias; folha efetivamente paga 13.002 (não 21.600: os postos pararam por `NO_FUNDS`); dinheiro de P 2.137 → 11.427 (+9.290).
- Caixa **[HIP, linear, não simulado]**: no cenário g1 já medido (com as três regras de oferta, 30 dias, semente 1; veja o estudo do retorno do dinheiro) o caixa dos mercados caía cerca de 220 por dia com a folha de 720; H1 cortaria 390 de saída (o caixa para de cair), H2 só 60 (cai uns 160 por dia): a 2 por hora o C4 quase não ajuda o caixa.
- `income`: cada moeda alivia 1 ponto e a necessidade sobe 2 por hora (48 por dia): o alívio de 24 vira 11 ou 22. Não é letal, mas alimenta a LW-096a (vagas) **[não medido]**.

## 4. Pagar só o serviço executado, e o escopo da LW-112
(A LW-112 é "calibração por dados, nenhuma alteração de código".)
| Opção | Só dados? | Código e classe | S0 e S1 | Dinheiro, save e eventos | Testes e hashes | Tarefa dona |
|---|---|---|---|---|---|---|
| A. dados: `wage_per_hour` (0, 1, 2) ou `workers_wanted` | sim | nenhum; classe 3 (balanceamento em `data/`) | igual | sem moeda nova; `workers_wanted` menor deixa portador sem posto e sem salário | soak e oráculo mudam (DEC-175) | LW-112 ("salários" está no texto); não fecha 15 |
| B. máscara de horas por posto em dados, lida pelo `ServicePostBook` com a hora da simulação | não | `PostDef`, carregador, `hour_step(hora)`, `economy_runtime.gd`; classe 3 (contrato, design) com itens de classe 4 (emendar DEC-164 e DEC-152 e o roadmap, protegidos; regravar referências) | preserva: usa só o minuto da simulação | fora do turno não paga nem para (`stopped` falso, não `NO_FUNDS`); `WagesPaid` só nas horas pagas; sem save novo se a máscara ficar nas definições (formato novo é proibido sem Arthur) | `test_service_posts*.gd`, `test_service_post_data.gd`, `test_service_posts_game_data.gd`, o oráculo (provável: talk, save, demote, starved, real_game) e o soak de 30 dias; DEC-175: PARAR e mostrar valor antigo, novo e causa | tarefa nova, antes da LW-112 |
| C. pagar quando a ação `work` conclui | não | o `npc` avisaria a economia | **viola:** em S0 depende do corpo; a DEC-152 aprovada diz o contrário | n/a | n/a | nenhuma: rejeitar |
| D. o `npc` entrega a lista de plantão pela rotina (por posto e hora) | não | comando ou evento novo entre módulos; classe 3, provável 4 | preserva (agenda, não corpo) | laço novo por hora; contrato e `events.md` | os mesmos | tarefa nova, maior |
| E. diária explícita (um pagamento por dia, valor inteiro livre, por exemplo 15) | não | cadência nova; classe 3 | preserva | `WagesPaid` diário | os mesmos | tarefa nova |
- B repete as horas da rotina num segundo dado (`routine_blocks.json` é do `npc`; a economia não importa o `npc`): se a rotina mudar, a máscara não acompanha. D evita isso ao custo de um contrato novo. E resolve o inteiro, mas abandona a ideia de "serviço".
- A classe final é decidida no contrato da tarefa (AGENTS.md: "na dúvida, sobe"); as classes acima são a leitura do autor da análise.

## 5. Recomendação e decisões de Arthur
**Recomendação (uma):** não mudar o posto agora. Se Arthur quiser pagar o serviço, fazer a B como tarefa pequena e própria (não dentro da LW-112, que proíbe código), depois contar as horas reais de `work` (a medição que faltou) e só então calibrar o valor na LW-112, ciente do inteiro.
**Ficam com Arthur:** (1) o princípio: posto = renda-base declarada (manter as 24 horas e documentar), serviço por hora (B ou D) ou diária (E); (2) quais horas: o bloco `work` (11), o plantão sem sono ou outro; (3) o valor (1 subpaga, 2 sobrepaga, ou uma unidade mais fina: decisão de design); (4) emendar as DEC-164 e DEC-152 e o contrato; (5) aprovar as referências novas (DEC-175).
**O C4 NÃO resolve:** o saldo dos mortos (P: cerca de 5.360 presos no S-B), a demanda final por bens dos locais, `NO_FUNDS` e `OUTPUT_FULL` dos locais, a morte sem `FoodStub` (falta comida), nem o mercado viver só do spread (50 a 400 por dia [HIP] contra uma folha de 330 a 720): o C4 adia o fim do caixa, não o evita.

## O que NÃO foi verificado
Horas de `work` realmente executadas (o Godot não foi rodado); testes e hashes (não abertos; a lista é provável); `production_book.gd` por inteiro; onde ficam as definições dos postos (se a máscara caberia fora do save); a comida de 15 (estimativa); o efeito no `income` e nas vagas; a semente 2 e o S-A além de 30 dias.
