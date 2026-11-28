# LW-099f: curvas naturais das caravanas (experimento de 26/11/2026)

Documento para Arthur. Estado: EXPERIMENTAL, só apresentação, em PR isolado e em Draft; nada disto está ligado no jogo de hoje. Contrato oficial da viagem visível: `docs/economia/contrato-lw-099-viagem-visivel.md` (não foi alterado). Números do estudo da cadeia de corpos: medidos com o trecho reto inicial (`straight_m`, que só afeta o veículo comprido) em 26/11/2026, 11:43; as medidas sem esse trecho reto ficam no relatório do estudo (a tabela de antes do trecho reto).

## O que são e como ligar
Hoje, quando uma viagem tem dois trechos (A para C e depois C para B), a caravana vira a quina de uma vez, em cima do povoado. As curvas naturais trocam a quina por um arco de verdade: o comerciante e o carrinho são UM corpo rígido apoiado em dois pontos (os pés e o eixo do carrinho) que andam numa faixa a 1,2 m à direita do eixo da estrada; o corpo gira pela corda entre os dois apoios, sem deslizar, sem deformar e sem teletransportar. Só a posição e o giro mostrados mudam: a fração `u`, o tempo, a velocidade econômica, a ponte, os dados das estradas (`data/world/*`, `caravan_routes.json`), o relógio e os saves são os de sempre.
Dois interruptores, ambos DESLIGADOS por padrão, em `main_world_view.gd`: `caravans_visible` (a viagem visível) e `caravan_natural_curves` (as curvas; só vale com o primeiro ligado). O raio do CAMINHO do veículo é 6 m (referência de Arthur para o veículo comprido; para o carrinho de hoje 3 m bastaria: estimativa do estudo, não medida no jogo) e se varre com `CaravanBodiesView.set_curve_radius_m` (4,1, 8 e 10 m são os do estudo; 0 deixa a quina viva). O jogo de hoje só faz curva em viagem de vários trechos (estrada fechada: comando de desenvolvimento); os pontos de passagem do dado (`points_m`) são IGNORADOS hoje, nos dois modos, então nas viagens normais de um trecho nada muda. Uma volta de 180 graus no povoado de passagem (A para B e depois B para A) não tem arco possível: nesse caso a caravana usa o caminho de hoje (giro limitado por metro) pelo resto da viagem.

## O que o estudo mediu (3 cantos reais, 6 passagens, 4 raios)
Veículo comprido de referência (cavalo e carroça de 4 rodas, 9,1 m) e carrinho de hoje, com a faixa de 1,2 m e a rampa suave de 12 m. A virada é o ângulo do canto; "R" é o raio do caminho. Os cantos de 141,6° e 129,1° são fechados; o de 89,3° é o mais suave.

**Articulação máxima do veículo comprido (graus entre o cavalo e a carroça) e quanto ele se afasta da estrada oficial (m).** O carrinho de hoje é um corpo só: articulação 0°.

| Passagem (virada) | R 4,1 m | R 6 m | R 8 m | R 10 m |
|---|---|---|---|---|
| B para A para C (-141,6°) | 72,7° / 10,34 m | 55,2° / 13,72 m | 44,9° / 17,28 m | 38,3° / 20,84 m |
| C para A para B (141,6°) | 73,4° / 10,09 m | 53,8° / 13,47 m | 42,9° / 17,02 m | 35,5° / 20,58 m |
| A para B para C (129,1°) | 73,4° / 9,46 m | 53,7° / 12,55 m | 42,9° / 15,80 m | 35,5° / 19,05 m |
| C para B para A (-129,1°) | 72,7° / 9,86 m | 55,2° / 12,98 m | 44,9° / 16,23 m | 38,3° / 19,49 m |
| A para C para B (-89,3°) | 70,1° / 7,40 m | 53,3° / 9,36 m | 44,9° / 11,36 m | 38,3° / 13,32 m |
| B para C para A (89,3°) | 73,0° / 6,50 m | 53,7° / 8,17 m | 42,4° / 10,15 m | 35,5° / 12,11 m |

**Afastamento máximo da estrada oficial do carrinho de hoje (m)** (a curva natural corta o canto por dentro e abre por fora; quanto maior o raio, maior o afastamento):

| Passagem (virada) | R 4,1 m | R 6 m | R 8 m | R 10 m |
|---|---|---|---|---|
| B para A para C (-141,6°) | 9,11 m | 12,55 m | 16,11 m | 19,68 m |
| C para A para B (141,6°) | 8,92 m | 12,30 m | 15,86 m | 19,42 m |
| A para B para C (129,1°) | 8,09 m | 11,19 m | 14,44 m | 17,71 m |
| C para B para A (-129,1°) | 8,47 m | 11,63 m | 14,88 m | 18,14 m |
| A para C para B (-89,3°) | 5,79 m | 7,70 m | 9,74 m | 11,71 m |
| B para C para A (89,3°) | 5,06 m | 6,57 m | 8,52 m | 10,49 m |

**Fator de velocidade na tela (mínimo..máximo; 1,00 = a velocidade econômica), carrinho.** Por dentro da curva o corpo anda mais devagar que o da simulação, por fora mais depressa; o veículo comprido é parecido (diferença de uns 0,05 em qualquer valor). A conta da posição lógica e do tempo não muda.

| Passagem (virada) | R 4,1 m | R 6 m | R 8 m | R 10 m |
|---|---|---|---|---|
| B para A para C (-141,6°) | 0,997 a 1,277 | 0,997 a 1,202 | 0,997 a 1,153 | 0,997 a 1,123 |
| C para A para B (141,6°) | 0,772 a 1,015 | 0,831 a 1,015 | 0,867 a 1,015 | 0,890 a 1,015 |
| A para B para C (129,1°) | 0,772 a 1,015 | 0,830 a 1,015 | 0,866 a 1,015 | 0,890 a 1,015 |
| C para B para A (-129,1°) | 0,994 a 1,259 | 0,994 a 1,203 | 0,994 a 1,153 | 0,994 a 1,123 |
| A para C para B (-89,3°) | 0,994 a 1,172 | 0,994 a 1,182 | 0,994 a 1,153 | 0,994 a 1,123 |
| B para C para A (89,3°) | 0,835 a 1,014 | 0,835 a 1,014 | 0,866 a 1,014 | 0,890 a 1,014 |

**Razão de comprimento do trecho de saída (carrinho / veículo comprido):** o arco encurta ou alonga o trecho em relação à reta (regra do estudo: entre 0,90 e 1,10; todos cabem).

| Passagem (virada) | R 4,1 m | R 6 m | R 8 m | R 10 m |
|---|---|---|---|---|
| B para A para C (-141,6°) | 1,020 / 1,025 | 1,029 / 1,034 | 1,039 / 1,044 | 1,048 / 1,054 |
| C para A para B (141,6°) | 1,020 / 1,024 | 1,027 / 1,031 | 1,034 / 1,039 | 1,042 / 1,046 |
| A para B para C (129,1°) | 1,025 / 1,032 | 1,035 / 1,041 | 1,045 / 1,051 | 1,055 / 1,061 |
| C para B para A (-129,1°) | 1,012 / 1,016 | 1,018 / 1,022 | 1,024 / 1,028 | 1,030 / 1,034 |
| A para C para B (-89,3°) | 1,007 / 1,011 | 1,011 / 1,015 | 1,015 / 1,019 | 1,018 / 1,022 |
| B para C para A (89,3°) | 1,008 / 1,011 | 1,010 / 1,014 | 1,013 / 1,017 | 1,016 / 1,020 |

**Maior passo de um quadro** (em múltiplos de velocidade x tempo x fator real da faixa): de 0,89 a 1,00 nas 48 linhas (limite da regra: 1,02).

**Locais (casas, descanso, trabalho, social) que o veículo atravessa no canto.** O "hoje" é o giro limitado atual da vista; tem a mesma lista com e sem o limite.
- **B para A para C**: hoje 2 [a_home_12, a_rest_02]. Natural, veículo comprido: R 4,1: 2 [a_home_11, a_rest_02] | R 6: 2 [a_home_11, a_rest_02] | R 8: 3 [a_home_06, a_home_10, a_rest_02] | R 10: 3 [a_home_06, a_home_10, a_rest_02]. Carrinho (quantos locais, nos 4 raios): 2 / 2 / 1 / 2.
- **C para A para B**: hoje 1 [a_home_12]. Natural, veículo comprido: R 4,1: 2 [a_home_07, a_home_12] | R 6: 3 [a_home_12, a_social_01, a_social_02] | R 8: 3 [a_home_12, a_social_01, a_social_02] | R 10: 3 [a_home_12, a_social_01, a_social_02]. Carrinho (quantos locais, nos 4 raios): 2 / 2 / 3 / 3.
- **A para B para C**: hoje 3 [b_home_02, b_social_01, b_work_05]. Natural, veículo comprido: R 4,1: 3 [b_home_03, b_social_01, b_work_05] | R 6: 4 [b_home_03, b_home_06, b_social_01, b_work_05] | R 8: 3 [b_home_03, b_social_01, b_work_05] | R 10: 2 [b_social_01, b_work_05]. Carrinho (quantos locais, nos 4 raios): 3 / 4 / 4 / 2.
- **C para B para A**: hoje 2 [b_home_02, b_social_01]. Natural, veículo comprido: R 4,1: 3 [b_home_02, b_work_01, b_work_02] | R 6: 4 [b_home_02, b_work_01, b_work_02, b_work_03] | R 8: 3 [b_home_02, b_work_02, b_work_03] | R 10: 2 [b_home_02, b_work_03]. Carrinho (quantos locais, nos 4 raios): 3 / 4 / 3 / 2.
- **A para C para B**: hoje 2 [c_work_02, c_work_04]. Natural, veículo comprido: R 4,1: 2 [c_rest_01, c_work_02] | R 6: 2 [c_rest_01, c_work_02] | R 8: 2 [c_rest_01, c_work_02] | R 10: 2 [c_rest_01, c_work_02]. Carrinho (quantos locais, nos 4 raios): 1 / 2 / 2 / 2.
- **B para C para A**: hoje 2 [c_work_02, c_work_04]. Natural, veículo comprido: R 4,1: 3 [c_social_01, c_work_02, c_work_04] | R 6: 4 [c_social_01, c_work_01, c_work_02, c_work_04] | R 8: 3 [c_social_01, c_work_01, c_work_04] | R 10: 3 [c_social_01, c_work_01, c_work_04]. Carrinho (quantos locais, nos 4 raios): 2 / 3 / 3 / 3.

**Largura necessária nas retas** (faixa + metade do veículo): carrinho 1,805 m, veículo comprido 2,205 m. Contra a meia-largura [HIP] da estrada de 2,0 m, o carrinho cabe com 0,195 m de folga e o comprido passa 0,205 m; a trilha da praça do mercado tem 1,6 m (os dois passam dela).

## O que foi verificado (só `--headless`; nenhuma janela foi aberta)
- Testes novos da vista (20, em 3 arquivos, mais um ajudante), com o modo desligado e ligado: faixa em smoothstep nas 3 estradas reais nos dois sentidos; apoio de trás SEMPRE sobre a faixa; os 6 cantos reais com quadros de 0,5 m, de 1 s e de 1/60 s (troca de trecho exata: 0 mm e até 0,002°; nenhum passo acima do andado vezes o fator da faixa; giro dentro do raio; sem NaN; um corpo só); raios 4,1, 8 e 10 m sem salto e raio 0 finito; pose igual por qualquer caminho de quadros; viagem sem memória; inclinação pelo eixo real; liga e desliga no meio da viagem (esquece a memória e o giro); trecho que sai de outro povoado não herda a chegada; volta de 180 graus (caminho de hoje pelo resto da viagem, sem estalo); rampa limitada em estrada curta; cena principal com os interruptores. Os 13 arquivos de teste de caravana que já existiam passam sem edição.
- Mutantes (defeitos plantados de propósito na vista e depois desfeitos): memória de chegada ignorada (6 testes reprovaram), faixa com o sinal trocado (3), apoio de trás do lado errado (1) e pela tangente em vez da corda (1), `s` pelo comprimento da polilinha antiga (1), raio do eixo sem a faixa (2), rampa sem o limite de meio trecho (1), giro pela tangente (2) e rodas por roda desligadas (1). Na 2ª rodada, depois da revisão independente, mais 9: caminho de hoje nunca escolhido (1 teste reprovou), escolhido em toda chegada herdada (7) e com a condição invertida (8), giro não guardado no quadro natural (1 e 1), religar sem esquecer a chegada (1), o giro (1) e o caminho de hoje (1), e chegada herdada de OUTRO povoado (1).
- Custo informativo, não é benchmark oficial: medida do agente da integração (headless, 5 medianas de 400 quadros, 6 caravanas no alcance); ninguém repetiu: 95 us por `reconcile` desligado e 269 us ligado.
- **NÃO verificado:** aparência e animação (ninguém viu na janela); desempenho real em release; a largura oficial das estradas; o veículo comprido NA VISTA (a vista usa só o carrinho de hoje; o comprido existe só no código de teste (`CaravanChain.wagon_spec`) e no estudo); revisão independente; a suíte inteira e o `check_all` (Maestro e CI).

## Decisões em aberto para Arthur
1. **Raio mínimo: 6 m ou 8 m.** Com 6 m o veículo comprido articula até 55° e se afasta da estrada oficial 8 a 14 m; com 8 m, até 45° e 10 a 17 m; o carrinho de hoje aguentaria 3 m (estimativa do estudo, não medida no jogo). Sugestão: decidir na janela, com os dois lado a lado (`set_curve_radius_m`).
2. **Meia-largura da estrada contra a faixa de 1,2 m.** Hoje a faixa e a largura são [HIP]: o comprido passa 0,205 m da meia-largura de 2,0 m. Opções: estrada mais larga (cerca de 2,25 m de meia-largura), faixa menor, ou aceitar.
3. **O canto do povoado.** (a) ATUAL: a curva natural varre por dentro das casas (2 a 4 locais por passagem no comprido; o "hoje" 1 a 3). (b) pontos de passagem no dado (`points_m`), desenhando o canto por fora das casas: HOJE `points_m` é IGNORADO (a vista não sabe o sentido do trecho em relação à rota), então esta opção exigiria o dado dos dois povoados da rota em `caravan_routes.json` (para a vista saber o sentido) e a correção de `_via_of`, sem mexer na ponte; (c) a ponte informar o trecho vizinho (de onde a caravana vem e para onde vai). (b) mexe no dado e em `_via_of`, (c) na ponte; AMBOS exigem autorização de Arthur.
4. **Onde mapear `u`.** Hoje `u` anda no comprimento do EIXO (o corpo por fora anda mais depressa e por dentro mais devagar: o fator de velocidade acima). A alternativa é mapear no comprimento da FAIXA: a velocidade na tela fica igual à da simulação, mas o corpo deixa de estar no ponto do eixo que a conta do tempo pressupõe.
5. **Ligar no `main`:** é classe 3 e só com a sua aprovação depois de ver o resultado na janela.
