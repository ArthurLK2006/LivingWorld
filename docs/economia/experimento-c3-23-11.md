# Experimento C3: o mercado compra do produtor local que tem lote parado (resultado, 23/11/2026)

**Estado: medido; o C3 NÃO cria demanda real e ANTECIPA o colapso. Nada foi implementado no repositório.** O experimento rodou só em CÓPIAS descartáveis do `main` em `10f3a33` (o código é o mesmo do `89d935d`), com autorização de Arthur de 23/11/2026, sem tocar saves oficiais, contratos protegidos nem hashes. O canal C3 vem de [estudo-retorno-do-dinheiro-23-11.md](estudo-retorno-do-dinheiro-23-11.md); o anterior, o [H-K](experimento-hk-23-11.md), foi descartado. **Conferência do Maestro:** os totais gastos pelo C3, os dias em que os postos param e o caixa zera, os vivos do S-B e o estado dos 90 dias da base foram recalculados dos CSV brutos e batem; onde o relatório do agente diferia, vale o número daqui.

## 1. O que foi feito
- **A regra (59 linhas de jogo, só no `ProductionBook`):** a cada hora, quando um local está parado por falta de comprador (a regra E do LW-094b), o mercado do povoado compra TODO o produto parado dele, em ordens de até 50 unidades, pelo preço de compra do mercado (`bid`, a mesma curva do `TradeEngine`, sem o teto de compra), **só com o dinheiro ACIMA da reserva** (7 dias da folha dos postos daquele povoado: A 2.352, B 1.344, C 1.344). Pagamento por `Ledger.transfer(mercado → local, trade)` e bem por `GoodsStore.transfer`, tudo ou nada; nenhuma moeda é criada. Sem sorteio, sem relógio, sem estado salvo (no modo `stock`).
- **Dois destinos do bem (condição 6 de Arthur):** `stock` = o bem fica no estoque do mercado; `works` ("obras do povoado") = o mercado destrói, com o motivo `consumed` que já existe, o que passou do estoque-alvo, até 100 unidades por mercado e por dia.
- **Desvios do que o estudo K descreveu:** o C3 compra o produto parado INTEIRO (com um lote só o local continuaria sem comprador); no `works` as obras destruíram também grão, lã, minério, madeira e pão, e não só tábua, ferramenta e tecido; **uma versão fiel a K (só tábua, ferramenta e tecido) compraria cerca de 77 unidades em 90 dias, praticamente nada, por isso não foi refeita.** O destino dos bens foi calculado por diferença contra a base, não unidade a unidade.
- **Rodadas (semente 1, mesma semente e período em cada par):** S-A = jogo real COM `FoodStub`, 90 dias, `off`, `stock` e `works` (reserva 7); reserva de 3 dias em `works`; semente 2 (`off` contra `works`); S-B = SEM `FoodStub` (`start_stock` 0, `max_stock` 1, `work_yield` 0, como no LW-094b), 60 dias, `off`, `stock` e `works`. Conservação, determinismo e save conferidos. Medição na cópia: `Ledger`, `GoodsStore` e o medidor (estática, fora do save).

## 2. S-A, COM `FoodStub`, 90 dias (base | `stock` | `works`)
| dia | caixa dos mercados | dinheiro de P (guarda e estalajadeiro) | dinheiro de F e O | dinheiro dos locais | postos pagos (de 6) |
|---|---|---|---|---|---|
| 1 | 8145 \| 7582 \| 7199 | 2137 \| 2189 \| 2189 | 8134 \| 9152 \| 9448 | 1267 \| 760 \| 847 | 6 \| 6 \| 6 |
| 7 | 6366 \| 5590 \| 4685 | 4795 \| 5136 \| 5230 | 7430 \| 8576 \| 9449 | 881 \| 50 \| 60 | 6 \| 6 \| 6 |
| 14 | 4998 \| 3965 \| 3065 | 6635 \| 7089 \| 7121 | 7430 \| 8460 \| 9377 | 383 \| 28 \| 20 | 4 \| 4 \| 4 |
| 20 | 2791 \| 1541 \| 761 | 8939 \| 9463 \| 9425 | 7430 \| 8460 \| 9377 | 286 \| 28 \| 20 | 4 \| 4 \| 4 |
| 30 | 367 \| 5 \| 6 | 11427 \| 10999 \| 10180 | 7438 \| 8460 \| 9377 | 181 \| 28 \| 20 | 2 \| 0 \| 0 |
| 90 | 3 \| 5 \| 6 | 11941 \| 10999 \| 10180 | 7438 \| 8460 \| 9377 | 31 \| 28 \| 20 | 0 \| 0 \| 0 |
- **Ninguém morre em nenhum dos três (138 vivos no dia 90).**
- **Gasto do C3:** `stock` comprou 1.129 unidades por 2.284 moedas; `works`, 1.724 por 3.885. **Só nos dias 1 a 7:** depois o caixa fica abaixo da reserva e o C3 se desliga sozinho (cerca de 6.400 recusas por reserva).
- **O que foi comprado (`stock`):** grão 430, lã 274, minério 136, pão 132, madeira 80, tecido, farinha e ferramenta 77 no total. Quase tudo é matéria-prima barata (grão, madeira e lã estão no piso de 1 a 4 moedas por unidade): por isso o C3 move pouco dinheiro por unidade.
- **O caixa zera ANTES:** o 1º dia com o caixa dos mercados abaixo de 50 é o 32 na base, o 28 no `stock` e o 23 no `works`; os postos deixam de ser pagos (0 de 6) no dia **33 na base, 28 no `stock` e 23 no `works`**, isto é, 5 e 10 dias mais cedo. Folha dos postos em 90 dias: 13.516 \| 11.940 \| 11.115.
- **Reserva de 3 dias (`works`):** gasta 5.107, ainda só na 1ª semana; os postos caem para 4 de 6 já no dia 7 e param no dia 24. **Semente 2:** o mesmo desenho; o C3 gasta 4.256 e o caixa dos mercados no dia 30 é 409 na base contra 8.

## 3. S-B, SEM `FoodStub`, 60 dias (base | `stock` | `works`)
| dia | vivos | caixa dos mercados | dinheiro dos NPCs vivos | dinheiro preso nos mortos |
|---|---|---|---|---|
| 1 | 138 \| 138 \| 138 | 9491 \| 8916 \| 8888 | 10850 \| 11692 \| 11724 | 0 |
| 7 | 137 \| 137 \| 137 | 14493 \| 11465 \| 13041 | 6180 \| 9977 \| 8400 | 8 |
| 14 | 32 \| 23 \| 26 | 15496 \| 12410 \| 12551 | 1564 \| 2541 \| 2820 | 4062 \| 6549 \| 6118 |
| 20 | 20 \| 9 \| 0 | 14508 \| 12478 \| 11640 | 1747 \| 213 \| 0 | 4926 \| 8809 \| 9849 |
| 30 | 0 \| 0 \| 0 | 13452 \| 11964 \| 11646 | 0 | 7845 \| 9536 \| 9849 |
- Todos os 138 estão mortos no dia **29 na base, 29 no `stock` e 20 no `works`**. O C3 gastou 6.408 e 6.644, só nos dias 1 a 7. **Piorou:** pão produzido em 60 dias 1.254 \| 1.026 \| 1.104; pão vendido aos NPCs −211 e −83 contra a base; no dia 7 os locais sem dinheiro (`NO_FUNDS`) passam de 6 para 12. No `works` as obras destruíram 709 de grão e 87 de pão em plena fome.
- O caixa dos mercados CRESCE nos dois lados: sem o `FoodStub` o dinheiro sobra e o que falta é comida.

## 4. Para onde foi o dinheiro e os bens (condições 5, 6 e 7)
- **O dinheiro:** cerca de 70 a 90% do que o C3 paga vira folha dos lavradores e dos demais ofícios na mesma semana (+2.000 a +3.800 de folha dos locais). **Não volta ao mercado:** razão de retorno (receita extra do mercado ÷ gasto do C3) de 0,00 a 0,35 no S-A e negativa no S-B. No fim o C3 só trocou de mãos uns 1.000 a 2.000 moedas, de P para F e O; o dinheiro total preso nos NPCs vivos é o mesmo da base (±30).
- **Os bens (`stock`, 90 dias):** de 1.129 unidades compradas, só cerca de 60 chegam a algum NPC (pão e grão); o saldo para os locais é cerca de 0. Cerca de 1.000 ficam acumuladas no estoque do mercado, acima do teto, e não saem em 90 dias: **o estoque parado só mudou de dono**. O pão comprado só tomou o lugar de vendas que a padaria faria depois (as vendas normais dela caem 138).
- **Os bens (`works`):** 965 unidades destruídas "em obra". Não há uso de jogo por trás (a manutenção dos locais NÃO aumentou: −16 a −24 peças); é um ralo, e no S-B inclui comida.
- **Condição 5 (só dinheiro existente, reserva preservada): cumprida**, mas a reserva só impede o C3 de gastar; quem esvazia o caixa é a folha dos postos, que segue sendo paga até o caixa zerar.

## 5. O que os 90 dias da base mostram (dado novo, conferido nos CSV)
O S-A só tinha sido medido até 30 dias. A base (sem C3), com o `FoodStub`:
- **Ninguém morre em 90 dias, mas a economia PARA.** O pão deixa de ser produzido no dia 8 e de ser comprado no dia 20; os locais quase nunca rodam; o caixa dos mercados fica abaixo de 50 desde o dia 32 e a folha dos postos para no dia 33 (0 de 6).
- **No dia 90, 21.486 das 21.520 moedas do mundo (99,8%) estão nos bolsos dos NPCs vivos** (P 11.941, F e O 7.438 e os comerciantes cerca de 2.100); os mercados têm 3 moedas e os locais 31. Os mercados mantêm 246 pães em estoque desde o dia 14, e ninguém os compra desde o dia 20.
- Inferência (a única outra fonte de comida é o `FoodStub`): com zero compras de comida há 70 dias, é o `FoodStub` que mantém todos vivos. **Estabilidade com alimentação provisória não é sustentabilidade econômica.** (Sem o `FoodStub`, S-B, todos morrem no dia 29.)

## 6. Conservação, determinismo e save
- `money_ok` e `goods_ok` = 1 em TODOS os dias de todas as 11 rodadas, com `problems` 0. Com o modo `off` a cópia é igual à base intacta (83 colunas iguais em 2 dias).
- Determinismo: o `works` repetido por 30 dias deu CSV idêntico (237 colunas, 0 diferenças).
- Save: o save antigo `save_main.bin` carrega no build do C3. **`stock`:** salvar e carregar dá hash igual e o save carrega no build OFICIAL (não há chave nem motivo novos: só `trade` e `consumed`). **`works`:** o determinismo NÃO se preserva depois de salvar e carregar (hash carregado igual, fim da rodada diferente), provavelmente por causa do contador de obras do dia, que não vai para o save; como regra de jogo o `works` exigiria estado salvo novo, isto é, mudar o formato do save (decisão de Arthur). A causa exata não foi isolada com teste próprio.

## 7. Veredito e o que faltaria para o C3 virar regra de jogo
- **(a) Demanda real: NÃO** (cerca de 60 de 1.129 unidades chegam a um uso; o dinheiro não volta; o `works` só consome porque destrói). **(b) Circulação: SIM, curta** (uma semana de produção e folha extras, paga com o caixa que iria aos postos). **(c) Adiamento: NÃO, é ANTECIPAÇÃO:** no S-A os postos param 5 a 10 dias mais cedo; no S-B todos morrem no mesmo dia (`stock`) ou 9 dias antes (`works`).
- **Não como está.** Faltaria decidir: um destino legítimo para os bens (obras com efeito no jogo, ligadas ao GDD 12.3 "tributos que se convertem em despesas", e nunca sobre comida); uma reserva que proteja os POSTOS (com 14 dias a reserva de A, 4.704, já passa o caixa inicial dele e o C3 mal dispara); o preço acima do teto; o contador de obras no save; e, sobretudo, **um canal de RETORNO do dinheiro guardado pelos NPCs** (demanda final por bens dos locais). Sem esse canal, qualquer compra do mercado só esvazia o caixa mais cedo.
- **O que o C3 não muda:** quem morre sem renda; a folha dos postos (que piora); o dinheiro preso nos mortos (no S-B sobe de 7.845 para 9.536 a 9.849); o entesouramento.

## 8. O que NÃO foi verificado
Atribuição unidade a unidade (FIFO); o S-B com a 2ª reserva e com a semente 2; o `works` sem limite diário e só sobre tábua, ferramenta e tecido; o C3 com as regras do LW-094b desligadas; suíte de testes e lints na cópia; a causa exata da divergência do save no `works`; desempenho.
