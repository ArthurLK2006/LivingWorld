# Experimento D1: demanda final orgânica (manutenção e equipamento), resultado de 23/11/2026

**Estado: medido; o consumo orgânico de manutenção e equipamento NÃO cria demanda estável (veredito: adiamento ou piora). Nada foi implementado no repositório.** Rodou só em CÓPIAS descartáveis do `main` (código do `89d935d`), com autorização de Arthur de 23/11/2026: protótipo de consumo "economicamente justificado de itens e serviços já existentes, com utilidade ou desgaste verificável, sem nova barra de necessidade, sem destruir mercadoria arbitrariamente e sem modificar saves ou o `main`". Os anteriores foram o [H-K](experimento-hk-23-11.md) e o [C3](experimento-c3-23-11.md), ambos negativos. **Conferência do Maestro:** os números das tabelas das seções 2 (S-A e S-B) foram recalculados dos CSV brutos e batem.

## 1. O que foi feito
- **Mecanismo A (só dados, escopo da LW-112):** recalibra `data/economy/site_upkeep.json` (as mesmas 28 regras; só mudam `quantity` e `period_days`, então o save segue compatível) por uma vida útil em "dias-trabalhador" dividida pela equipe média da receita.

| nível | vida útil (dias-trabalhador) | unidades por dia (ferramenta, tábua, tecido) | valor nominal por dia |
|---|---|---|---|
| base atual | implícita, de 18 a 120, sem coerência entre receitas | 2,6 / 1,8 / 1,9 | cerca de 102 moedas |
| A1 "realista" | 30, 60 e 30 | 3,4 / 1,7 / 3,0 | cerca de 133 |
| A2 "alto" (só sensibilidade) | 10, 20 e 10 | 10 / 5,3 / 9 | cerca de 392 |
- **Mecanismo B (cerca de 75 linhas de GDScript na cópia): ferramenta pessoal do trabalhador.** Utilidade: em cada hora o lote rende 50% mais 50% vezes a fração da equipe paga que tem ferramenta (a mecânica de eficiência que já existe; sem ferramenta a equipe rende metade, mas não para). Desgaste por uso: no fim do dia, quem foi PAGO naquele dia e tem `(dia + id) mod 30 = 0` perde 1 ferramenta (motivo `maintenance`, que já existe; vida média de 30 dias trabalhados; quem não trabalhou não gasta). Compra: o trabalhador sem ferramenta compra 1 no mercado do povoado pelo `TradeEngine` (motivo `trade`) se o saldo cobrir uma reserva de comida de 70 moedas (hipótese do agente: 3 a 6 dias de comida) mais o preço. Regra determinística, sem sorteio, em ordem de id. Não é imposto: o NPC só paga quando não tem a ferramenta, recebe um bem que fica no inventário e o bem só se gasta trabalhando.
- **De fora:** roupa (tecido), porque não há mecânica de jogo que a use (sem utilidade verificável), e "serviço" novo (a estalagem e a guarda não têm mecânica de cliente). Os dados atuais já embutem uma vida de 18 a 120 dias-trabalhador, isto é, de 200 a 1.300 horas de uso: já é desgaste acelerado.
- **Limitação herdada:** na regra atual o prazo da manutenção corre até com o local PARADO; o desgaste não depende do uso, e o A não muda isso.

## 2. Resultados (semente 1)
**S-A, COM `FoodStub`, 90 dias** (nos cinco casos ninguém morre: 138 vivos no dia 90):
| rodada | postos rodando d14/d20/d30 | caixa dos mercados d30 | dinheiro de P e de F+O no d90 | pão e grão produzidos | manutenção destruída (ferr./tábua/tecido) | ferramentas compradas por NPCs |
|---|---|---|---|---|---|---|
| base | 4/4/2 | 367 | 11.941 e 7.438 | 828 e 562 | 25/22/25 | 0 |
| A1 | 4/4/2 | 521 | 11.973 e 7.380 | 840 e 578 | 24/18/26 | 0 |
| A2 | 4/4/2 | 274 | 11.929 e 7.444 | 792 e 522 | 26/22/31 | 0 |
| B | 4/2/0 | 3 | 11.806 e 7.470 | 390 e 402 | 5/9/10 | 29 (690 moedas) |
| B, reserva 0 (sensibilidade) | 4/4/4 | 2.908 | 16.067 e 3.152 | 708 e 554 | 8/16/18 | 106 (5.205 moedas) |

**S-B, SEM `FoodStub`, 60 dias:**
| rodada | vivos d7/d14/d30 | zera no dia | pão e grão produzidos | ferramentas de NPCs |
|---|---|---|---|---|
| base | 137/32/0 | 29 | 1.254 e 2.354 | 0 |
| A1 | 136/21/9 | 36 | 1.332 e 1.666 | 0 |
| A2 | 96/20/9 | 35 | 1.392 e 1.010 | 0 |
| B | 96/20/10 | 35 | 1.326 e 578 | 11 (353 moedas) |
| B, reserva 0 | 93/37/0 | 24 | 852 e 2.066 | 106 (5.608 moedas) |
- No S-B, "zera mais tarde" (35 contra 29) se deve a 8 a 10 guardas e estalajadeiros pagos pelos postos; os trabalhadores (F e O) morrem tão cedo quanto na base ou mais cedo (no dia 7 eram 96 vivos com A2 e B, contra 137 na base).

## 3. O consumo e o circuito
| rodada | dias 1 a 7 | dias 8 a 14 | dias 15 a 20 | dias 21 a 30 | dias 31 a 90 |
|---|---|---|---|---|---|
| base (manutenção, moedas por dia) | cerca de 34 | 56 | 28 | 11 | 1 a 6 |
| A1 | 41 | 51 | 29 | 5 | 0 a 7 |
| A2 | 117 | 28 | 18 | 4 | 0 |
| B (manutenção + ferramenta de NPC) | 14 + 99 | 11 + 0 | 2 + 0 | 4 + 0 | 0 a 4 |
| B, reserva 0 | 39 + 744 | 24 + 0 | 3 + 0 | 9 + 0 | 0 a 4 |
- **É uma RAJADA na primeira semana e depois para, em todas as rodadas.** A manutenção só é paga por um local que tem caixa e peças, e os locais ficam sem dinheiro (`NO_FUNDS`) ou sem comprador (`OUTPUT_FULL`) entre os dias 7 e 14; no B o desgaste só ocorre com trabalho, e sem folha ninguém trabalha, nenhuma ferramenta se gasta e ninguém compra outra.
- **O A não aumenta o consumo de verdade:** em 90 dias o A1 destruiu 68 unidades e o A2 79, contra 72 da base; desgaste devido e não pago só vira eficiência menor.
- **O B (reserva 70) quase não compra:** 29 ferramentas no S-A; lavradores e demais ofícios têm em média 60 a 80 moedas, abaixo de 96. O dinheiro parado está com P (guardas e estalajadeiros, 11.800 de 21.486), que não trabalham em local e por isso não usam ferramenta de ofício.
- **Circuito do B (S-A, 90 dias):** os NPCs gastaram 690 em ferramentas e a receita dos mercados CAIU 6.452 (com metade do rendimento, os locais compraram e venderam menos). **Com reserva 0:** 5.205 moedas saíram de F e O (de 7.438 para 3.152), passaram pelo mercado e acabaram em P pela folha dos postos (P de 11.941 para 16.067): os postos duraram mais (4 rodando no dia 30, contra 2), mas a folha dos locais parou no dia 17: **transferência de bolso para bolso, sem demanda nova.** O entesouramento de P não foi drenado em nenhuma rodada.

## 4. A utilidade
Existe e se verifica, mas aparece como PERDA: B no S-A, pão −53% (390 contra 828) e grão −28%; no S-B, grão −75%, com mais mortes cedo. A2: grão −7% no S-A e −57% no S-B. A1: neutro (±3%). **Nenhum mecanismo aumentou a produção, porque a produção não esbarra em equipamento: esbarra em comprador e em caixa.**

## 5. Conservação, determinismo e save
- `money_ok` e `goods_ok` verdadeiros em TODOS os dias das 10 rodadas longas; toda unidade destruída teve o motivo `maintenance`; nenhum motivo novo no `Ledger` nem no `GoodsStore`; `needs.json`, `FoodStub`, folha dos postos e folha cheia dos locais intactos.
- Determinismo: a repetição do B por 30 dias deu CSV idêntico. Save: o save antigo carrega com B e com A2 (`load_ok true true`); ida e volta com hash igual; `serialize()` sem chave nova; o save do B carrega no build sem o protótipo. **O B exigiria 1 campo novo no save** (quem trabalhou no dia, ou horas de uso) para ficar exato depois de um save no meio do dia; o A não exige nada.

## 6. Veredito e escala
- **(c) ADIAMENTO ou PIORA: não é demanda real estável e mal chega a circulação curta.** O A1 é neutro; o A2 e o B pioram a produção e, no S-B, a sobrevivência dos trabalhadores; o B com reserva 0 é uma rajada de uma semana que só desloca dinheiro de F e O para P.
- **Escala:** seria preciso absorver de 250 a 320 moedas por dia do entesouramento de P e manter mais de 1.000 por dia de folha dos locais. Foi absorvido de 30 a 120 por dia na 1ª semana e menos de 10 por dia depois do dia 20 (744 por dia só na 1ª semana, no melhor caso). Fechar a conta só com ferramentas (26 moedas) exigiria uma durar cerca de 2,6 dias de trabalho (e ainda cerca de 8 dias para 300 por dia): implausível, e mesmo assim exigiria locais RODANDO, que é justamente o que falta.
- **Causa estrutural:** ferramenta, tábua e tecido são bens de capital e insumos; a demanda por eles é DERIVADA da produção, que por sua vez não tem comprador final. **O consumo orgânico desses bens não basta.** O que falta é um comprador final que GASTE o dinheiro parado de P e de F e O, isto é, consumo dos próprios NPCs, o que esbarra na DEC-153 e na DEC-163 ("o NPC só come na Fase 3") e fica para decisão de Arthur.

## 7. Poderia virar regra de jogo?
- **A1, como calibração de dados (LW-112):** legítima pela coerência (vida útil por trabalhador), não pela economia; precisaria da decisão de Arthur sobre a vida útil, da aceitação de mudança de hash e referências (DEC-175) e, de preferência, de desgaste só com o local rodando (mudança de código e de contrato).
- **B, como regra:** precisaria de contrato novo (equipamento pessoal e efeito na eficiência), de um campo no save, de uma DEC sobre quem paga e de referências regravadas; só faria sentido depois que a economia tivesse demanda final; hoje piora a produção.

## 8. O que NÃO foi verificado
Semente 2; o B com vida útil de 10 dias (quase não houve desgaste); suíte de testes e lints na cópia; janela; comerciantes reais levando ferramentas entre povoados além do que a base já faz; o desgaste "só com o local rodando"; desempenho. A reserva de 70 moedas é hipótese do agente.
