# Estudo: como o dinheiro volta a circular (caixa dos mercados, saldo dos falecidos, LW-103 com o salário efetivo) (23/11/2026)

**Status:** ESTUDO (só documento). Pedido de Arthur de 23/11/2026. **Não autoriza implementar nada nem mudar o contrato da LW-103.**

**Orientação de design dele, que vale para tudo aqui:**
- não transformar atividades naturais (conversar, descansar) em cobranças artificiais;
- a 6ª necessidade fica **DESCARTADA por enquanto** (impacto nos saves e nas decisões existentes) e só aparece aqui para dizer isso;
- a taxa pela conversa ou pelo descanso, proposta na minha análise anterior (PR 154, hipótese H-K), também fica fora por essa orientação;
- nada pode criar moeda.

**De onde vêm os números:**
- o estudo `docs/economia/lw-094a-estudo-21-11.md` (chamado aqui de "estudo");
- os dados de `data/`;
- as saídas JÁ medidas do cenário g1, com as três regras de oferta, hoje no `main` `10f3a33` (scratchpad da força-tarefa, `missao/agente_a/exp/saida/g1__r6__d30__s1.csv`, 30 dias, semente 1) e do t1 (90 dias).

Nenhuma simulação nova. Conta ou suposição está marcada **[HIP]**.

## 1. Resumo (leia primeiro)
1. **Caixa dos mercados.** A longo prazo, o mercado só ganha o spread. O resto do caixa é um reservatório que ele recebeu uma vez: as 9.000 moedas iniciais mais a venda do estoque inicial.
   - Ele já devolve dinheiro, pelos postos (720 por dia), e por isso no g1 o caixa CAI 220 por dia depois do dia 10.
   - Nenhum canal do mercado sustenta sozinho 900 a 1.100 por dia. O fluxo só pode vir do gasto final, que nesta economia é a comida e a manutenção dos locais.
   - **Recomendação:** dois canais coerentes, sem moeda nova:
     - (C4) os postos pagam as horas de serviço da rotina, e não as 24 horas do dia;
     - (C3) obras e reparos do povoado comprados do produtor local que tem lote parado, só com o caixa acima de uma reserva.
   - Os contratos de entrega (C2) entram depois, quando a LW-104 deixar o NPC aceitá-los.
2. **Saldo dos falecidos.** A destinação mais simples e coerente é o **caixa do mercado do povoado como destino do espólio**, como a herança vacante que passa ao Município.
   - É uma transferência única pelo `Ledger`, no mesmo passo em que a conta se fecha, sem estado novo no save.
   - Muda a DEC-146 e não entra em "famílias e herança" entre pessoas.
   - No g1 ela devolveria só cerca de 100 moedas. No t1, até 11.108 das 21.520 moedas do mundo (52%), que hoje ficam presas.
3. **LW-103 com o salário efetivo.** O sinal que falta já existe e já vai no save: a pressão da necessidade `income` de cada NPC, que sobe sem salário e desce com o salário PAGO.
   - Combinada com o motivo de parada do local (`NO_FUNDS`, `OUTPUT_FULL`) e com o caixa do local, ela diz onde há renda, sem memória nova.
   - O preço entra só como sinal secundário.
   - **Recomendação:** estudar a LW-103 em dois lados:
     - a economia abre vaga onde há comprador e caixa;
     - o NPC sai de onde a pressão de renda mostra que não recebe.
   - Teste descrito na seção 4.6.

## 2. Estudo 1: o caixa dos mercados
### 2.1 O que se sabe hoje
- **O mundo tem 21.520 moedas fixas.** No dia 0: 9.720 com os NPCs, 2.800 com os locais e 9.000 com os mercados. As conferências de dinheiro deram ok em todas as execuções.
- **Como o caixa do mercado se moveu no g1:**
  - sobe de 9.000 para 12.515 até o dia 10, vendendo o estoque inicial (por exemplo, 1.600 pães no C);
  - depois cai 220 por dia (11.784 no dia 20, 9.585 no dia 30).
- **Quanto entra e quanto sai:**
  - a única saída grande é a folha dos postos: 30 postos × 1 moeda × 24 horas = **720 por dia** (`service_posts.json`);
  - a receita permanente do mercado é o **spread**: 5% de cada lado (`spread_bp` 1.000 em `price_params.json`), no mínimo 1 moeda por unidade;
  - com o grão no piso (2 moedas), o mercado compra a 1 e vende a 3;
  - o volume negociado no g1, nos dias 20 a 30, foi de cerca de 880 moedas por dia (somando compras e vendas). Isso dá ao spread algo entre **50 e 400 por dia [HIP]**.
- **Conclusão:** o mercado é um **repassador**. Ele pode devolver um estoque de dinheiro, mas só sustenta como fluxo o que o spread lhe dá. Os postos já gastam mais do que isso, e por isso o caixa se esvazia em semanas.
- **O vazamento verdadeiro está depois do mercado:** quem recebe dos postos ganha acima do que come e guarda a sobra. No g1, o dinheiro dos NPCs vivos SOBE 278 por dia enquanto eles morrem. São os 18 guardas e os 12 estalajadeiros, com 24 por dia contra cerca de 15 de comida.

### 2.2 Os canais, um a um
**C1. O mercado como comprador de última instância (estoque regulador)**
- **Mecanismo:** subir o teto de compra (`buy_cap_bp`, DEC-177) ou deixar o mercado comprar do local que tem lote parado (a regra E da LW-094b) mesmo acima do teto. O mercado estoca e revende quando o preço sobe.
- **Recebe:** o local, e por ele a equipe (folha).
- **Conservação:** `request_trade` de venda; o dinheiro só troca de conta.
- **Ordem de grandeza:** transitória. O que o mercado paga hoje volta quando ele revende; o saldo de longo prazo é zero. Sem consumo final, o estoque só cresce (o tecido só sai pela manutenção, cerca de 1,9 por dia).
- **Compatibilidade:** é dado (`market_targets.json`, protegido) e mexe numa decisão aprovada, a DEC-177. Cabe na LW-112 (calibração só por dados).
- **Risco:** o dinheiro vira pilha de bens sem uso e o caixa se esvazia mais cedo. O b1 (teto igual ao alvo, a direção oposta) não mudou os vivos.
- **Não se sabe:** se uma compra só contracíclica (só quando o preço está no piso) ajudaria. Não foi medido.

**C2. Contratos de entrega e de trabalho avulso pagos pelo mercado**
- **Mecanismo:** o postador (LW-107c2; a ativação é a LW-107c3, preparada no PR #152, opção B, com `bread_standing` e `flour_shortage`) posta encomendas com a recompensa retida do caixa do mercado. Quem entrega recebe.
- **Recebe:** hoje só o jogador. Com a LW-104 ("aceitar trabalho" entre as reações à escassez; `economy.md`, seção 8), também o NPC e o comerciante. Isso é, na prática, a contratação de frete.
- **Conservação:** custódia pelo `Ledger` (`contract_escrow`, `contract_payout`, `contract_refund`); nada nasce.
- **Ordem de grandeza:** o #152 mede de 30 a 39 contratos em 30 dias sem jogador, cerca de 1 por dia. A recompensa vai no máximo até `ask` × lote. Isso dá de **20 a 80 por dia [HIP]**, e só se alguém entregar. Hoje, sem a LW-104 e sem jogador, a custódia volta e o efeito é 0.
- **Compatibilidade:** sem save novo; contratos já aprovados. A ativação depende de Arthur (5 condições do #152). O aceite pelo NPC é a LW-104.
- **Risco:** a recompensa do pão dá prejuízo em 45% das ofertas (#152). O trabalho avulso pago pelo mercado só é legítimo se o trabalho servir ao mercado (por exemplo, carregar ou trazer estoque).
- **Não se sabe:** o efeito com NPCs aceitando (nunca medido).

**C3. Obras e reparos do povoado comprados do produtor local (o tesouro H-T, refeito)**
- **Mecanismo:** quando o caixa do mercado passa de uma reserva (por exemplo, 7 dias de folha dos postos, 5.040 moedas), o povoado encomenda uma obra (reparo, cerca, ponte). Ela consome tábua, ferramenta e tecido COMPRADOS do produtor local vivo que tem lote parado, pelo preço de compra do mercado. A obra nunca usa estoque abaixo do alvo, que fica para a manutenção dos locais.
- **Por que o H-T deu 35 a 61 vivos (e de 8 a 53 nos g5 a g8):** o protótipo (`missao/agente_a/patches/lw094a_tesouro.patch`) **destruía o estoque do próprio mercado**. Nenhuma moeda ia diretamente a produtor algum. E ele consumia a ferramenta importada de que os locais precisam, que só comerciante mortos repunham.
- **O que mudaria agora:**
  - a compra é feita diretamente a quem produziu;
  - só se o produtor tem lote parado (o "comprador" da regra E já define isso);
  - nunca abaixo do alvo;
  - as três regras de oferta já estão no `main`.
- **Recebe:** o local produtor e a equipe dele, isto é, os ofícios que não fazem comida, os únicos sem comprador.
- **Conservação:** `transfer(mercado → local, trade)`; os bens são destruídos com o motivo `consumed`, que já existe. Nenhuma moeda nasce nem morre.
- **Ordem de grandeza:**
  - no começo: o excedente sobre a reserva, de 4.000 a 7.000 moedas uma vez só;
  - depois: o que o spread repõe, de 50 a 400 por dia **[HIP]**;
  - **não cobre 900 a 1.100 de forma permanente**; é ponte, não fonte.
- **Compatibilidade:** sem save novo **[HIP]** (a reserva é dado e a decisão sai do estado de hoje). Regra nova, classe 3, nenhuma tarefa numerada. Não contraria a DEC-153, que trata do consumo do NPC, mas é desenho novo. O GDD 12.3 cita "tributos que se convertem em despesas" entre os sumidouros, como proposta.
- **Risco:** esvaziar o caixa que paga os postos (por isso a reserva) e disputar com a manutenção (por isso "nunca abaixo do alvo").

**C4. Postos: pagar as horas de serviço, não as 24 horas**
- **Mecanismo:** hoje o posto paga a cada hora do dia, inclusive enquanto o guarda dorme. A rotina dá 11 horas de trabalho ao guarda (7 às 13 e 15 às 20) e 11 ao estalajadeiro (9 às 14 e 15 às 21) (`routine_blocks.json`).
- **A coerência:** pagar as horas de serviço segue a mesma ideia do "trabalho efetivamente realizado" da LW-094b e da proibição de "folha das horas paradas".
- **Recebe:** os mesmos 30 NPCs, menos por dia.
- **Conservação:** a saída do caixa diminui; nada nasce.
- **Ordem de grandeza:** a 1 moeda por hora, 330 por dia em vez de 720, mas 11 por dia não paga a comida (cerca de 15). A 2 moedas por hora, 660 por dia, 22 por NPC e ainda 7 de sobra. O número certo é calibração (LW-112). O efeito que importa é **estancar o vazamento** de cerca de 270 por dia (a sobra guardada) e prolongar o caixa.
- **Compatibilidade:** o passo 0 da hora (a folha dos postos) é PROPOSTA/HIP no `economy.md`, seção 6. A DEC-164 e a DEC-174 (posto pago pelo mercado, sem marca TEMP) não mudam. Sem save novo **[HIP]**. Mudam o oráculo e o hash do soak (rito da DEC-175).
- **Risco:** com o salário inteiro, ou sobra ou falta. O mínimo é 1 por hora.

**C5. Mais serviços públicos (outros postos)**
- **Medido:** o h1 (20 guardas a mais) deu 34 vivos, e o caixa caiu a 5.962. Mais postos sem receita só aceleram o esvaziamento.
- **Recomendação:** não usar como canal. Os 6 postos de hoje já são o serviço público possível.

**C6. Tributo e sumidouros da Fase 4**
- **O que muda:** a folha dos postos passa ao tesouro da autoridade (DEC-222, PROPOSTA) e entram tarifa, imposto e soldo (`economy.md`, seção 17). O motivo `upkeep` do tesouro **destrói** moeda (DEC-224, APROVADA).
- **O efeito:** é redistribuição e sumidouro, não retorno.
- **Fora da Fase 3:** "impostos e tarifas reais" estão no "não fazer" (roadmap 3.J). Não cabe agora.

### 2.3 Recomendação do estudo 1 e decisões
- **Recomendação:**
  - estudar primeiro o **C4** (é o vazamento medido, sem regra nova de gasto);
  - depois o **C3** com as três salvaguardas (só lote parado, nunca abaixo do alvo, reserva dos postos);
  - o **C2** quando a LW-104 existir;
  - não usar C1, C5 nem C6.
- **Dito com franqueza:** sem a 6ª necessidade e sem cobranças artificiais, a folha que a economia sustenta tem como teto o gasto final, que é a comida mais a manutenção. Os ofícios que não fazem comida terão de ser menos numerosos. É exatamente o que a LW-103 faria (estudo 3).
- **Decisões de Arthur:**
  - (a) pagar os postos pelas horas da rotina (C4);
  - (b) aceitar a obra do povoado como gasto público legítimo, com reserva (C3);
  - (c) a ativação do #152 e, depois, a LW-104 (C2).

## 3. Estudo 2: o saldo dos falecidos
### 3.1 Hoje
- **A regra (DEC-146, APROVADA):** "A economia fecha a conta e o inventário do dono ao ouvir `NpcDied`, mantendo-os na soma da conservação. Herança é 'não fazer' (roadmap 3.J)".
- **O código:** `EconomyModule._on_npc_died` (`src/sim/economy/api/economy_module.gd`) tira o NPC dos locais e postos, apaga a caravana e chama `close_owner`.
- **O roadmap, 3.J, "Não fazer nesta fase":** cita, entre outros, "propriedade complexa" e "famílias e herança".
- **Os dados disponíveis:**
  - o `NpcDied` traz só `npc_id`, `cause` e `tier` (`npc_lifecycle.gd`, linha 105);
  - a economia não sabe a casa nem o povoado de um NPC desempregado;
  - não existem cônjuge, parente nem dívida no jogo (não há crédito, 3.J).

### 3.2 As opções
| Opção | O que exige | Cabe no "não fazer"? |
|---|---|---|
| H1. Quem mora na mesma casa (o vivo de menor ID com o mesmo `home_place_id`) | o `npc` escolhe o herdeiro (só ele conhece a casa) e o informa (campo novo no `NpcDied` ou comando novo na economia); os bens não cabem no inventário do herdeiro (peso 40) | não: é herança entre pessoas, perto de "famílias e herança" |
| H2. Cônjuge ou parente | famílias não existem | não (famílias são "não fazer") |
| H3. **O caixa do mercado do povoado como destino do espólio** | o povoado do morto (pelo local de trabalho, que a economia conhece, ou por um campo novo no evento para o desempregado); o mercado tem conta e inventário de peso 5.000 | **sim**: não é herança entre pessoas; é o destino da herança vacante (no Direito brasileiro, a herança vacante passa ao Município) |
| H4. Fundo comum do povoado | um tipo de dono novo (estado novo no save); é o tesouro da Fase 4 adiantado | não agora (DEC-215 é PROPOSTA da Fase 4) |
| H5. Partilha entre vizinhos | regra de divisão, restos de divisão inteira, várias transferências | não: é propriedade complexa |
| H6. Pagar dívidas | não há dívidas nem crédito | não se aplica |

### 3.3 Conservação na opção H3 (como não apagar nem duplicar)
- **Uma transferência única, pelo `Ledger`, dentro do mesmo `_on_npc_died`, ANTES de `close_owner`:** `transfer(morto → mercado do povoado, saldo inteiro, motivo novo "estate")`. Depois disso, a conta se fecha vazia.
- **Os bens:** o inventário vai para o inventário do mercado por `request_transfer_goods`, que já existe. Se não couber no peso, o resto fica na conta fechada, que continua na soma.
- **Ordem:** os mortos da mesma hora são tratados na ordem em que o `npc` publica os `NpcDied`, que é determinística. O herdeiro é o mercado, que não morre: não existe o caso de "o herdeiro morreu na mesma hora".
- **Sem povoado conhecido** (desempregado): fica como hoje (conta fechada, na soma) ou o evento ganha o `settlement_id` (mudança de evento catalogado, AGENTS 16.2).
- **Motivos do `Ledger`:** o conjunto é fechado (DEC-147). Um motivo novo é mudança de contrato.
- **Save:** sem estado novo. A transferência acontece no momento da morte. Um save antigo com mortos que têm saldo carrega e continua igual.
- **Testes e referências:**
  - mudam os testes de conservação e de morte da economia;
  - no jogo real com o `FoodStub` quase não há morte, então o oráculo e o hash do soak de 30 dias (138 vivos) provavelmente não mudam **[HIP: confirmar com o rito da DEC-175]**;
  - a DEC-146 tem de ser emendada.

### 3.4 Quanto devolveria (números já medidos)
- **g1 (três regras de oferta):** só 102 moedas nos mortos no dia 30. Quem morre ali morre pobre: o efeito é desprezível na primeira onda.
- **t1:** 120 moedas nos mortos no dia 30, 5.908 no dia 35 e 11.108 no dia 50 (52% do mundo). Essa segunda onda morre COM dinheiro, por falta física de comida (estudo, M2).
- **Leitura:** a herança não evita a primeira onda. Ela impede que metade do dinheiro do mundo saia de circulação para sempre.
- **Ressalva:** no H3 o dinheiro volta ao caixa do mercado, que só circula pelos canais do estudo 1 (C3, C4). Uma coisa depende da outra.

### 3.5 Recomendação e decisões
- **Recomendação:** H3, o mercado do povoado como destino do espólio. É a mais simples, não cria estado no save, não entra em "famílias e herança" e devolve o dinheiro a quem já paga os postos e as obras.
- **Decisões de Arthur:**
  - (a) emendar a DEC-146;
  - (b) aprovar o motivo novo do `Ledger`;
  - (c) o que fazer com o desempregado: deixar como hoje ou acrescentar `settlement_id` ao `NpcDied`.

## 4. Estudo 3: a LW-103 com o salário efetivo
### 4.1 Onde isso vive hoje
- **A utilidade do emprego:** `src/sim/npc/employment/npc_employment.gd`, `_utility` = `wage_per_hour` × 8 − custo da caminhada + 10 se é o próprio ofício. O emprego atual é avaliado pela mesma conta, com o salário PROMETIDO.
- **Só há avaliação quando sai uma vaga** (`ContractOffered`).
- **A vaga só nasce quando faltam trabalhadores** em relação a `workers_wanted`, que é dado fixo (`production_sites.json`). Na prática, só quando alguém morre.
- **Troca de emprego:** só com ganho acima da histerese (20). O emprego só termina por morte ou por outra vaga, e o local parado não demite (DEC-169).
- **O texto da LW-103** (roadmap, linha 793) pede "limite e inércia", "sem oscilação a cada dia" e determinismo.

### 4.2 Os sinais disponíveis
| Sinal | De onde vem hoje | Precisa de memória nova no save? | Ressalva |
|---|---|---|---|
| **Salário efetivo** | a pressão de `income` do NPC (`need_values`, já salva): sobe 2 por hora e desce 1 ponto por moeda RECEBIDA (`WageIncome`; só os pagos, `WagesPaid.paid_worker_ids` da folha parcial) | **não**: a pressão já é uma memória do que ele recebeu nas últimas horas | é ruidosa por hora; usar limiares (`attention` 50, `urgent` 75) |
| Local paga agora? | `peek_site`: `running` e `reason` (`NO_FUNDS`, `OUTPUT_FULL`, `NO_INPUT`, `NO_WORKER`), salvos | não | mostra só o instante |
| Caixa do local | `peek_balance(site_id)` | não | dá quantas horas de folha cabem |
| Comprador do produto | a regra E (`OUTPUT_FULL` sem comprador) e `peek_quote` (`ECON_MARKET_FULL`, `MARKET_NO_FUNDS`) | não | é o sinal mais honesto de demanda |
| Preço | `MarketState`: preço e histórico de 7 dias (`history_days`), salvos | não | **engana**: a ferramenta a 3 vezes a base tem volume de 2,6 por dia |
| Vagas e equipe | `workers_wanted` e `workers_assigned`; a equipe útil é `workers_per_batch` × `max_batches_per_hour` (fazenda: 12 desejados, 4 trabalham) | não, se a equipe-alvo for CALCULADA a cada dia a partir do estado | um `workers_wanted` que muda e fica guardado seria estado novo |

### 4.3 Como se combinariam (descrição, não proposta de contrato)
- **Lado da economia (abrir vaga), uma vez por dia, a uma hora fixa, em ordem de ID:**
  - o local abre no máximo 1 vaga por dia se (i) produziu com comprador no dia, (ii) o caixa cobre pelo menos N horas de folha da equipe útil e (iii) tem menos que a equipe útil;
  - o local em `OUTPUT_FULL` ou `NO_FUNDS` não abre vaga e não demite (DEC-169);
  - o preço só desempata entre locais que passam os três testes.
- **Lado do NPC (sair):**
  - o emprego atual vale o salário prometido vezes uma fração que cai com a pressão de `income` (por exemplo, vale 0 quando a pressão passa de `urgent`);
  - a histerese de 20 e o limite de 1 vaga por local por dia dão a inércia e o limite que o roadmap pede;
  - a pressão de `income` sobe devagar (2 por hora), o que já é inércia natural.
- **Determinismo:** só inteiros, ordem de ID, hora absoluta (como as regras da LW-094b), nenhum sorteio.
- **O que mudaria nos contratos (sem propor mudar):**
  - `npc.md` 14.4 (o texto da utilidade);
  - `economy.md` seção 8 (quando a vaga é postada);
  - provavelmente a constante [HIP] `PAID_HOURS_PER_DAY`.

### 4.4 Relação com a LW-104
- **LW-104** é reação curta à escassez: comprar mais, buscar outro mercado, aceitar trabalho avulso ou entrega.
- **LW-103** é a troca de emprego de médio prazo.
- As duas leem os mesmos sinais (escassez, comprador). A LW-103 não depende da LW-104, e a LW-110 depende das duas.

### 4.5 O que NÃO se sabe
- **Se haverá para onde ir.** A equipe útil de todos os locais soma cerca de 50 vagas, mais 30 postos, para 138 NPCs **[HIP: conta sobre `recipes.json` e `production_sites.json`]**. Mudar de emprego não aumenta a folha total, que tem como teto a receita (estudo 1).
- Se a pressão de `income` separa bem "parado por pouco tempo" de "parado de vez".
- Quantas trocas por mês o jogo aguenta sem parecer arbitrário.

### 4.6 Hipótese de teste (descrita, NÃO executada)
- **H-103:** numa cópia do `main` `10f3a33` sem o stub (como o t1, com as três regras), um protótipo de cerca de 40 linhas faz duas coisas:
  - (a) o emprego atual vale 0 quando a pressão de `income` passa de 75;
  - (b) a vaga diária da seção 4.3.
- **A rodada:** 30 dias, semente 1, duas execuções.
- **Passa se:**
  - nos dias 20 a 30, os NPCs com `income` acima de 75 caem pelo menos 30% em relação ao g1;
  - nenhum NPC troca de emprego mais de 2 vezes em 30 dias;
  - as duas execuções dão o mesmo hash;
  - as conferências de dinheiro e de bens dão ok.
- **O que mede:** se o sinal move gente para onde há renda. NÃO mede se a economia fecha.

## 5. Decisões que dependem de Arthur
| # | Decisão | Estudo |
|---|---|---|
| 1 | Postos pagos pelas horas de serviço da rotina (C4) e o salário por hora deles (LW-112) | 1 |
| 2 | Obra do povoado comprada do produtor local, com reserva (C3) | 1 |
| 3 | Ativar o #152 e, depois, a LW-104 (C2) | 1 |
| 4 | Emendar a DEC-146: espólio ao mercado do povoado (H3), motivo novo do `Ledger`, o caso do desempregado | 2 |
| 5 | Autorizar estudar o contrato da LW-103 com os sinais da seção 4.3 e o teste H-103 | 3 |

**Não se sabe, no conjunto:**
- nada aqui foi medido de novo;
- os números do g1 são de 1 semente e 30 dias, em debug;
- o spread de 50 a 400 por dia, a equipe útil de cerca de 50 e os efeitos de C3 e C4 são estimativas.
