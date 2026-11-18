# LW-098h3c: medição controlada em release da curva de cotações (C6) e da memória por chamada (C2), 18/11/2026

**Status:** registro de MEDIÇÃO (só documento): nenhum código, dado, contrato, critério de aceite ou referência mudou. Pedido de Arthur (17/11/2026): depois de integrar C6 e C2, uma comparação controlada com a implementação anterior, com as condições da máquina registradas, sem tratar os 54 s estimados como resultado confirmado. Base: `docs/economia/medicao-098h-desempenho-17-11.md` (o planejamento comercial é cerca de 91% do custo extra) e `docs/economia/analise-3a-otimizacao-17-11.md` (a estimativa). Termos: **passo** = 1 minuto de jogo (43.200 em 30 dias); **base** = o mesmo mundo SEM comerciantes; **anterior** = o `main` sem a 098h3c; **nova** = com a curva (#134) e a memória (#135).

## 1. Resultado (leia primeiro)
1. **O ganho é REAL, mas menor que a estimativa.** Preço real dos dados, 6 comerciantes emulados, 30 dias: o soak foi de **73,6 s (anterior) para 57,9 s (nova): −21,3%**; o custo extra sobre a base (46,1 s) caiu de **27,5 s para 11,8 s: −57%**. A estimativa era 54 s (−27%, custo extra −71%): **os 54 s NÃO se confirmaram** (a extrapolação por contagens em depuração superestimou o ganho em release).
2. **Custo por passo:** média de 1,704 ms para 1,341 ms (base 1,068 ms), ou seja, o EXTRA por passo caiu de 0,637 ms para 0,273 ms. Por quadro (um passo a cada 75 quadros a 1x e a cada 9,4 a 8x): o extra médio é de 0,0085 ms para 0,0036 ms a 1x e de 0,068 ms para 0,029 ms a 8x.
3. **Os picos do planejamento sumiram da cauda:** p99 do passo de **12,3 ms para 4,5 ms** (base 3,7 ms) e p95 de 5,2 ms para 3,2 ms (base 2,4 ms); a mediana não mudou (1,06 ms; base 0,84 ms).
4. **Determinismo e conservação intactos:** o `state_hash` final é IDÊNTICO entre anterior e nova nas duas cenas (preço real `8a437b7b3b54…`; Q7 `6d3a526c3236…`), as mesmas chegadas e o mesmo lucro (30 e 970; 56 e 2.881), 6 de 6 vivos, dinheiro e bens conservados nos 30 dias e `validate` vazio em TODAS as 16 execuções.
5. **Aceite de desempenho (9.15.4):** lido como AUMENTO sobre a base, a nova não mostra aumento mensurável com esta precisão (seção 5); em valor absoluto o critério não é alcançável nem pela base neste ambiente. **Não afirmo "atendido" com margem:** o ruído do sistema é maior que o efeito nas contagens de passos.
6. **A guarda por impressão (C3) NÃO foi implementada e esta medição não a pede** (o extra restante é de 11,8 s em 30 dias e a cauda voltou ao nível da base); fica como alternativa só se uma medição futura mostrar problema.

## 2. Método
- **Binários:** release oficial do Godot 4.7.2 (já em `$HOME/lw-release-probe/bin`), com a cópia do projeto exportada pelo corredor `tests/soak/run_merchant_emulation --release` (cena principal trocada só na cópia, `.pck` exportado uma vez). **Anterior** = `ab3e8bf` (o `main` sem a 098h3c; `src/` idêntico ao de `ec9f0bf`). **Nova** = `528fe31`, cujo `src/`, `data/`, `tools/` e `tests/soak/` são IDÊNTICOS aos do `main` `7576219` (`git diff` vazio). Entre as duas: 4 arquivos de `src/sim/economy` (+159 −27).
- **Cena:** 6 comerciantes emulados (2 por povoado, no mercado, com a agenda real), semente 1, 30 dias, `--headless`, o custo do PASSO inteiro da simulação, sem renderização. **Preço real** dos dados (a cena que o aceite mede) e **Q7** (diferença de preço maior, sensibilidade). Comando: `emulation_release --headless -- --merchants N --days 30 --seed 1 --spread none|q7`.
- **Ordem contrabalançada:** base, A, B, B, A, A, B, base por cena (A = anterior, B = nova): 3 execuções de cada implementação e 2 da base por cena (16 no total), com 30 s de resfriamento.
- **Janela e validação:** o roteiro só mede com a fonte de energia travada no perfil da 1ª execução válida, a CPU ociosa em 80% ou mais em 3 amostras e o Mac sem ter acordado do sono nos 5 minutos anteriores (e espera, sem consumir CPU, até a janela existir); depois de cada execução invalida e refaz se o Mac dormiu no meio, a fonte mudou, o relógio da parede passou do tempo medido em mais de 20 s ou algum passo passou de 1 s. **Nenhuma das 16 foi invalidada.**

## 3. Condições da máquina
- **Perfil TOMADA** (AC Power, carregando; bateria de 33% a 56% durante as execuções) nas 16 execuções; modo de economia de energia desligado; **nenhum aviso térmico nem de desempenho** em nenhuma; CPU ociosa de 81% a 96% no começo de cada execução (carga média de 1 minuto entre 1,8 e 3,5); relógio da parede de cada execução coerente com o tempo medido (sem suspensão). Houve carga de fundo entre as execuções (o roteiro esperou a janela várias vezes: a CPU ociosa chegou a 47% a 80% em outros momentos), o que explica parte do ruído da base.
- **A 1ª tentativa (07:43) foi DESCARTADA:** o Mac dormiu no meio (um passo de 2,8 s e lacunas de horas no registro); parei o roteiro, guardei os logs à parte e nada dela entra nas tabelas. **O perfil BATERIA NÃO foi medido** (às 10:27 a bateria estava em 30% e descarregando; às 10:31, quando a janela surgiu, o Mac já estava na tomada): fica pendente, rotulado à parte e nunca misturado.

## 4. Resultados (média e faixa das execuções; tempo total em segundos, passo em milissegundos)
**Preço real (a cena do aceite):**
| | Base (0 comerciantes) | Anterior (6) | Nova (6) |
|---|---|---|---|
| Execuções | 2 | 3 | 3 |
| Tempo total do soak | 46,12 (45,23 a 47,02) | **73,63** (73,16 a 73,89) | **57,93** (55,58 a 59,96) |
| Custo extra sobre a base | n/a | 27,51 | **11,80 (−57%)** |
| Custo médio por passo | 1,068 | 1,704 | 1,341 |
| Mediana / p95 / p99 do passo | 0,841 / 2,366 / 3,651 | 1,065 / 5,207 / **12,327** | 1,064 / 3,220 / **4,484** |
| Máximo do passo (média) | 135,9 | 69,6 | 72,0 |
| Passos acima de 16,7 ms (cada execução) | 33,5 (20; 47) | 50,0 (47; 52; 51) | 20,3 (0; 27; 34) |
| Passos acima de 33 ms (cada execução) | 9,5 (7; 12) | 6,7 (6; 8; 6) | 4,3 (0; 7; 6) |

**Q7 (sensibilidade):**
| | Base | Anterior (6) | Nova (6) |
|---|---|---|---|
| Execuções | 2 | 3 | 3 |
| Tempo total do soak | 45,72 (45,16 a 46,29) | 68,84 (68,75 a 69,00) | 56,37 (55,86 a 56,94) |
| Custo extra sobre a base | n/a | 23,12 | 10,65 (−54%) |
| Custo médio por passo | 1,058 | 1,594 | 1,305 |
| Mediana / p95 / p99 do passo | 0,857 / 2,444 / 3,421 | 1,100 / 4,343 / 10,398 | 1,084 / 3,024 / 4,077 |
| Máximo do passo (média) | 62,1 | 30,0 | 38,8 |
| Passos acima de 16,7 ms (cada execução) | 12,5 (6; 19) | 27,7 (29; 22; 32) | 8,3 (5; 6; 14) |
| Passos acima de 33 ms (cada execução) | 2,5 (1; 4) | 0,3 (1; 0; 0) | 1,3 (1; 1; 2) |
Ganho do tempo total: preço real **−21,3%**, Q7 **−18,1%**.

## 5. O aceite de desempenho de 9.15.4 (nenhum passo acima de 33 ms e no máximo 5 acima de 16,7 ms em 30 dias, lido como AUMENTO sobre a base)
- **Neste ambiente a BASE já tem** de 20 a 47 passos acima de 16,7 ms e de 7 a 12 acima de 33 ms no preço real (e de 6 a 19 e de 1 a 4 na Q7): é o ruído do sistema (o Mac em uso), e ele é MAIOR que o efeito. Na medição de 17/11 a base tinha 7 e 0,5.
- **Aumento sobre a base (médias):** preço real, anterior +16,5 acima de 16,7 ms e −2,8 acima de 33 ms; nova −13,2 e −5,2. Q7: anterior +15,2 e −2,2; nova −4,2 e −1,2. Negativo significa que a execução com comerciantes teve MENOS passos acima do limite que a base, ou seja, **a diferença está dentro do ruído**.
- **Leitura honesta:** a anterior mostrava um aumento claro (cerca de 15 a 16 passos a mais acima de 16,7 ms, que o p99 de 12,3 ms contra 3,7 ms da base confirma); a nova NÃO mostra aumento mensurável e o p99 ficou a 0,8 ms da base. Isso é compatível com o critério lido como aumento, **mas não o demonstra com a margem de "+5 e 0" com 2 execuções de base e este ruído**. Para um número firme: repetir em ambiente mais quieto e também no perfil bateria, o que depende de Arthur (a janela e a bateria).

## 6. Limites (o que esta medição NÃO prova)
- Perfil tomada, uma semente, 3 execuções por implementação, **comerciantes EMULADOS e os dados de hoje**: com os dados da 098h5 (mais planos) o custo do planejamento muda e a medição deve ser refeita depois dela. Sem renderização: o quadro real não foi medido (o passo soma ao resto do quadro e à DEC-119). O ganho medido (−21%) é menor que o estimado (−27%) e o custo extra restante (11,8 s) inclui os 6 NPCs a mais (cerca de 2,4 s, pela decomposição de 17/11), a viagem e o que resta do planejamento.

## 7. Reprodução e dados brutos
Os roteiros (de uso único: `medir_098h3c_janela.sh`, `analisar_098h3c.sh`, `preparar_release.sh`) e os logs das 16 execuções e da tentativa descartada ficam FORA do Git, no scratchpad da sessão de 18/11/2026 (`scratchpad/medicao/`); os binários de release estão em `$HOME/lw-release-probe/merchant_emulation/20261118-073858` (anterior) e `20261118-074156` (nova). Para refazer: criar uma cópia de release de cada commit com `tests/soak/run_merchant_emulation --release --merchants 6 --days 0` e rodar os binários na ordem da seção 2, anotando a fonte de energia, a carga e o térmico antes de cada execução.
