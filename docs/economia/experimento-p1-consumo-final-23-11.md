# Experimento P1: consumo final dos NPCs (roupa de trabalho e cama), resultado de 23/11/2026

**Estado: medido; o consumo final de roupa de trabalho e cama NÃO cria demanda estável nem devolve circulação ao dinheiro. Veredito: (b) CIRCULAÇÃO CURTA, por ESCALA INSUFICIENTE; no S-A o pão caiu 14,5% (semente 1; pode ser em parte ruído de sorteio). O TETO reprovou C2 e C3: parada 3, sem o CENTRAL e sem 3ª calibração. Nada foi implementado no repositório.** Rodou só em CÓPIAS descartáveis do `main` (o mesmo código do C3 e do D1, `89d935d`), com a autorização de Arthur de 23/11/2026 (opção A: protótipo isolado de consumo final dos NPCs, sem 6ª necessidade, com critérios de sucesso e de encerramento). Critérios e parâmetros foram registrados ANTES da 1ª rodada. Os anteriores foram o [H-K](experimento-hk-23-11.md), o [C3](experimento-c3-23-11.md) e o [D1](experimento-d1-demanda-organica-23-11.md), todos negativos. **Conferência do Maestro:** os números da tabela da seção 4 (S-A, 90 dias) foram recalculados dos CSV brutos (caixa dos mercados, dinheiro de P, de F+O e de M, total conservado em 21.520, pão acumulado 708 contra 828, bolsos dos NPCs 99,51% contra 99,84%) e batem com o relatório do agente.

## 1. Os bens, a utilidade, a regra de compra e os parâmetros
| bem (material que já existe) | utilidade: parâmetro EXISTENTE que muda, só para quem TEM o bem | por que faz sentido |
|---|---|---|
| ROUPA DE TRABALHO = tecido (`fabric`, base 10) | o efeito do turno de trabalho sobre o cansaço (`work_rest`) cai de +5 para +3 | agasalho e luvas: o serviço no frio e na chuva cansa menos |
| CAMA = tábua (`plank`, base 8) | o efeito do sono sobre o cansaço (`sleep_rest`) vai de -100 para -125 | dormir em cama recupera mais que no chão |
- **Compra** (determinística, uma vez ao dia, por ordem de id, NPC vivo e não comerciante, no mercado do próprio povoado, pelo `TradeEngine`, motivo `trade`): só se o NPC NÃO tem o bem, o saldo cobre a RESERVA DE COMIDA mais o preço e o mercado tem as unidades. Sem sorteio, sem relógio novo, sem comprador fictício.
- **Desgaste por uso** (motivo `maintenance`, que já existe; sem estado novo): na virada do dia quem tem o bem perde um conjunto se (dia + id) mod VIDA = 0. Roupa e cama são usadas todo dia, então o desgaste corre com o tempo, não com o emprego. A 1ª reposição de cada NPC pode vir antes da vida inteira (declarado).
| parâmetros | roupa | cama | reserva de comida |
|---|---|---|---|
| TETO (o mais generoso defensável) | 2 unidades, vida 30 dias | 4 unidades, vida 90 dias | 40 moedas (2 dias de pão) |
| CENTRAL (realista; NÃO rodado, parada 3) | 1 unidade, vida 60 dias | 3 unidades, vida 180 dias | 60 moedas (3 dias de pão) |
- **Não é desgaste excessivo nem compra compulsória:** as vidas do TETO são os PISOS do Maestro (roupa 30 dias, cama 90; 1 dia de jogo = 30 minutos reais, ou seja, uma roupa dura 15 horas reais), o NPC só compra quando NÃO tem o bem e sobra dinheiro além da comida, e nada é destruído sem causa registrada. Consumo por NPC no TETO: 1,0 a 1,1 moeda por dia (6% a 7% do máximo que um trabalhador ganha, 16 por dia).
- Código só na cópia: 8 linhas no `ActionRunner` (efeito extra para quem tem o bem) e `tools/p1_consume.gd` (190 linhas, roda FORA do passo do jogo, às 05:45, hora de início do jogo). `needs.json`, `FoodStub`, folha dos postos e dos locais, motivos do `Ledger` e do `GoodsStore`: intactos (`diff` contra o `main`: só 4 arquivos de `src/` mudaram, com variáveis estáticas de medição e o gancho acima; `data/` igual, salvo o `food_stub.json` do S-B).

## 2. A conta de escala da Fase 0 (papel, antes de rodar; detalhes em `FASE0.md`)
| consumo estável por dia = NPCs x unidades / vida x preço | roupa | cama | soma | % de 250 | rajada inicial |
|---|---|---|---|---|---|
| TETO, os 138 compram (preços 10 e 8, até +10%) | 92 a 101 | 49 a 54 | 141 a 155 | 56% a 62% | 7.176 a 7.894 |
| CENTRAL, os 138 compram | 23 a 25 | 18 a 20 | 41 a 46 | 17% a 18% | 4.692 a 5.161 |
| TETO, só P pode pagar (30 NPCs com 398 cada) | 20 a 22 | 11 a 12 | 31 a 34 | 12% a 13% | |
- A parada 1 (abaixo de 62,5 por dia) NÃO disparou (141 a 155). A cadeia de produção sustentaria só 54 a 59 moedas de folha por dia (5% a 6% da meta de 1.000). Base por grupo (renda e gasto por NPC por dia, dias 1-7 / 8-14 / 15-30): P 24,0 / 15,1 / 10,0 e 9,7 / 6,3 / 0; F 3,1 / 0,2 / 0 e 1,3 / 0,4 / 0; O 5,7 / 0,35 / 0 e 3,8 / 0,2 / 0; depois do dia 33 ninguém tem renda. Bolso médio no dia 90: P 398, F 71, O 74 (F e O só têm 1.318 acima da reserva). Previsão registrada antes de rodar: o TETO falha C2 porque só P tem folga.

## 3. C1, a utilidade isolada (30 dias, S-A, sem compras; bem entregue por fora, registrado, à metade dos NPCs: id mod 4)
| medida (dias 2-30; 957 NPC-dias por coorte) | ROUPA com / sem | dif | CAMA com / sem | dif |
|---|---|---|---|---|
| cansaço médio (0 a 100) | 36,69 / 40,16 | -3,47 (-8,6%) | 37,26 / 39,59 | -2,33 (-5,9%) |
| horas por dia com cansaço urgente (75 ou mais) | 1,86 / 2,51 | -26% | 2,06 / 2,31 | -10,7% |
| horas de trabalho por NPC por dia | 10,33 / 10,31 | +0,2% | 10,32 / 10,32 | 0,0% |
| ruído: mesma conta SEM entrega (as 4 coortes) | +0,08 (+0,2%) | | +0,58 (+1,5%) | |
- **Os dois bens passam o C1** (efeito >= 5% e >= 1 ponto; descontado o ruído das coortes: roupa -8,9%, cama -7,3%; sem piora das horas de trabalho; 138 vivos). **Limite da utilidade:** ela existe só dentro da necessidade `rest`; horas trabalhadas, produção e sobrevivência não melhoram (a produção não esbarra em cansaço: esbarra em comprador e em caixa).
- **Alerta de produção:** no C1 o pão do dia 30 foi 756 contra 828 da base (-8,7%) e o grão 554 contra 562. Entrega com efeito ZERO (só o peso do bem): pão 828, igual à base, então a diferença vem do efeito sobre o cansaço (muda o ritmo de descanso e o caminho dos sorteios nos 8 dias em que os locais trabalham). Com a semente 2 (C1 repetido) o pão ficou igual à base (816 e 816) e o grão +1,4%: a queda de 8,7% da semente 1 não se repetiu, então tem cara de ruído de sorteio e não de prejuízo sistemático; o C1 fica aprovado, com este registro.

## 4. As rodadas (semente 1, TETO; 9 execuções no total: as de 60 e 90 dias e 7 de 30 dias)
**S-A, COM `FoodStub`, 90 dias** (138 vivos em todos os dias, P/F/O/M = 30/40/62/6; base entre parênteses):
| dia | caixa dos mercados | dinheiro de P | de F+O | locais rodando / sem caixa / sem comprador | postos | folha dos locais (por dia) | consumo (moedas no dia) | NPCs com roupa / cama |
|---|---|---|---|---|---|---|---|---|
| 1 | 9.677 (8.145) | 1.910 | 6.829 | 1 / 2 / 11 | 6 | 2.544 | 1.532 | 32 / 12 |
| 7 | 8.700 (6.366) | 3.114 | 5.383 | 0 / 4 / 10 | 6 | 160 | 69 | 93 / 45 |
| 14 | 6.066 (4.998) | 6.181 | 5.469 | 0 / 5 / 9 | 4 | 0 | 12 | 86 / 42 |
| 20 | 4.496 (2.791) | 7.682 | 5.513 | 0 / 5 / 9 | 4 | 48 | 40 | 75 / 38 |
| 30 | 1.481 (367) | 10.847 | 5.794 | 0 / 6 / 8 | 4 (2) | 24 | 42 | 62 / 27 |
| 45 | 2 (5) | 12.582 | 5.914 | 0 / 6 / 7 | 0 | 0 | 0 | 46 / 17 |
| 60 | 21 (3) | 12.734 | 5.772 | 0 / 6 / 7 | 1 (0) | 0 | 16 | 28 / 4 |
| 90 | 68 (3) | 13.277 (11.941) | 5.286 (7.438) | 0 / 6 / 7 | 0 | 0 | 64 | 20 / 0 |
- Produção em 90 dias: pão 708 (828, -14,5%), grão 546 (562, -2,8%), tecido 424 (108), tábua 186 (98). Estoque e preço no mercado: a tábua acaba no dia 14 (estoque 2, preço 24, o triplo da base) e o tecido no dia 90 (estoque 0, preço 30); sem caixa o mercado não compra dos locais, e sem produção não há o que vender.
**S-B, SEM `FoodStub`, 60 dias** (TETO; base entre parênteses): vivos nos dias 1/7/14/20/30/45: 138 (138) / 136 (137) / 41 (32) / 14 (20) / 7 (0) / 0 (0); 1ª morte no dia 7 (7); zera no dia 31 (29); consumo de 3.438 moedas (3.288 de 1ª compra), 458 por dia na 1ª semana, 7 por dia nos dias 8-14, 12 nos dias 15-30 e 0 depois; caixa dos mercados 15.017 no dia 60 (13.610); dinheiro dos mortos 6.448 (7.845); os NPCs pagaram 3.816 moedas a mais de compras (os 3.438 do consumo e 378 de comida, provavelmente porque vivem 2 dias a mais).

## 5. O consumo e o circuito (S-A, 90 dias, contra a base)
| janela | consumo por dia (1ª compra / reposição) | folha dos locais por dia (base) | folha dos postos por dia (base) |
|---|---|---|---|
| dias 1-7 | 762 (737 / 25) | 641 (478) | 720 (720) |
| dias 8-14 | 12 (0 / 12) | 22 (31) | 640 (453) |
| dias 15-30 | 54 (12 / 42) | 34 (0,5) | 430 (300) |
| dias 31-60 | 14 | 6 (0) | 70 (17) |
| dias 61-90 | 23 (0 / 23) | 0 (0) | 25 (0,7) |
- Total 7.381 moedas (5.368 de 1ª compra, 2.013 de reposição), 400 unidades de tecido e 180 de tábua, 72% na 1ª semana; pagaram P 2.864, F 1.323, O 3.194. **Reposição:** o desgaste destruiu 360 unidades de tecido e 180 de tábua, e só 27% do dinheiro gasto (2.013 de 7.381) foi reposição: no dia 90 só 20 NPCs têm roupa e nenhum tem cama (pico de 93 e 45).
- **Para onde foi o dinheiro** (em relação à base): receita extra dos locais 3.341 (45% do consumo; 1.544 voltaram como compra de insumo), folha extra dos locais 1.790 (24%, a única parte que chega a F e O) e folha extra dos postos 5.724 (78%): o caixa do mercado paga os postos, e os postos pagam P. Destino no dia 90: P +1.336 (11.941 para 13.277), F -1.063, O -1.089, M +744. **O consumo deslocou 2.152 moedas de F e O para P e M; o entesouramento de P cresceu, não foi drenado** (bolsos de NPCs 99,51% do dinheiro, base 99,84%).

## 6. Conservação, determinismo e save
- `money_ok` e `goods_ok` verdadeiros em TODOS os dias das 9 rodadas (controle, C1, TETO S-A e S-B, repetição); `problems` 0; todo desgaste com o motivo `maintenance`; entrega do C1 com o motivo `game_start` (só no teste); nenhum motivo novo.
- Controle com o consumo desligado reproduz a base: 0 diferenças em 237 colunas (S-A e S-B, 30 dias). Determinismo: repetição de 30 dias do TETO S-A, 268 colunas, 0 diferenças.
- Save: o save antigo de teste carrega no build P1 e no oficial limpo (`load_ok true true`, mesmos hashes); o save do TETO no dia 90 (NPCs com roupa e cama) carrega nos dois builds com os mesmos hashes. `serialize()` NÃO ganhou chave nem motivo; os mapas de "quem tem o bem" são só de execução (o protótipo recalcula na virada do dia).

## 7. Veredito e escala
| critério (TETO) | S-A | S-B |
|---|---|---|
| C1 utilidade | passa (com o alerta de produção) | |
| C2 demanda estável >= 150/dia nos dias 60-90, semanas >= 50% | REPROVA: 22,6 por dia (100% reposição); 7 de 8 semanas abaixo | n/a |
| C3 circulação (bolsos <= 90%, locais >= 4 e >= 3, folha >= 2x e >= 100) | REPROVA: 99,51%, 0 e 0 locais, folha 0 | n/a |
| C4 sem dano | REPROVA no pão com a semente 1 (708 contra 787 mínimos); 138 vivos | passa (1ª morte 7, zera 31) |
| C5 integridade | passa | passa |
- **(b) CIRCULAÇÃO CURTA**, com queda do pão no S-A (-14,5%, semente 1; pode ser em parte ruído, seção 3) e ADIAMENTO de 2 dias no S-B. **Escala:** medido 22,6 moedas por dia nos dias 60-90 (9% dos 250 necessários) e 0 de folha dos locais (meta mais de 1.000); a média dos 90 dias foi 82 por dia, mas 72% veio na 1ª semana. No papel, nem o teto de 155 por dia fecha a conta; com os NPCs que podem pagar, 31 a 34.
- **Por quê (conta):** (1) poder de compra: F e O não têm renda depois do dia 8 e terminam com 44 (F) e 57 (O) moedas por NPC, perto da reserva de 40; (2) o caixa do mercado é esvaziado pela folha dos postos (24 moedas por dia por guarda ou estalajadeiro), que vai para P, o grupo que já guarda 398 por NPC; (3) sem caixa o mercado não compra dos locais, a oferta acaba (preço 3x) e a reposição trava por falta de oferta, não de vontade. A parada 3 vale: uma calibração mais fraca e legítima (CENTRAL: 41 a 46 por dia no papel) faria pior.
- **O que mudaria a conclusão:** (a) comida: no S-B os NPCs pagaram 2.130 moedas por dia ao mercado na 1ª semana (15 por NPC por dia), 14 vezes o teto dos bens duráveis e 8 vezes a meta; o `FoodStub` entrega esse consumo de graça (LW-094 aberta); (b) salários contra preços: o máximo de renda é 16 por dia contra 15 a 20 de comida por dia, então sem emprego contínuo nada sobra para roupa; (c) um sumidouro ou fonte para o dinheiro de P voltar a F e O (tesouraria, imposto sobre a folha dos postos, comércio externo da Fase 4). Nada disso foi implementado ou proposto aqui.
- **Poderia virar regra de jogo?** Roupa e cama seriam conteúdo legítimo (o backlog já guarda "consumo de roupa e de ferramenta pessoal pelo NPC, GDD 12.3", fora da Fase 3 pelas DEC-153 e DEC-163), mas NÃO resolvem a economia. Exigiriam: DEC revendo a 153 e a 163; contrato novo em `npc.md` 14.3 e `economy.md`; código (efeito por posse, compra diária, desgaste); save sem chave nova só enquanto o desgaste for `(dia + id) mod vida` (vida exata por peça pede 1 campo novo e migração, AGENTS 12.6); hash novo (DEC-175). Decisões de Arthur: trazer o consumo pessoal do backlog para uma fase; as vidas (30 e 90 do piso, ou as realistas); desgaste por tempo ou por uso; aceitar o ganho pequeno (cansaço -6% a -9%) e a piora do pão; referências novas.

## 8. O que NÃO foi verificado
CENTRAL (parada 3); semente 2 do TETO (só o C1 teve uma rodada de semente 2); causa exata da queda do pão (ritmo de descanso x caixa; só separei o peso do bem); comerciantes fora do consumo; efeitos do bem em outras mecânicas (social, fome); serviços e reparo (a estalagem e a guarda não têm mecânica de cliente); suíte de testes e lints na cópia; desempenho; janela; desgaste exato por peça (usei `(dia + id) mod vida`, 1ª reposição antecipada). A reserva de 40 e 60 moedas é hipótese do agente (3 a 6 dias de pão seria outra).
