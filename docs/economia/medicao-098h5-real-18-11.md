# LW-098h5: medição em release com os comerciantes REAIS (perfil BATERIA), 18/11/2026

**Status:** registro de MEDIÇÃO (só documento): nenhum código, dado, contrato, critério de aceite ou referência mudou. Pedido de Arthur (18/11/2026, decisões finais da LW-098h5): depois de integrar os comerciantes, repetir a medição representativa em release com os comerciantes REAIS (a estimativa com emulados não é a validação final), preservando os critérios e as condições de teste. Base: `docs/economia/medicao-098h3c-18-11.md` (6 comerciantes emulados, perfil TOMADA) e `docs/modules/economy.md` 9.15.4. Termos: **passo** = 1 minuto de jogo (43.200 em 30 dias); **base** = o mundo de antes da 098h5 (dados antigos, 132 NPCs, sem comerciantes); **real** = o mundo da 098h5 (138 NPCs, 6 comerciantes dos dados, 2 por povoado).

## 1. Resultado (leia primeiro)
1. **O custo extra dos 6 comerciantes reais é de +11,8 s no soak de 30 dias (+27%):** de **43,58 s (base)** para **55,40 s (real)**, 3 execuções de cada. Por passo: média de 1,009 ms para 1,282 ms (**+0,274 ms**); mediana de 0,827 para 1,053 ms; p95 de 2,25 para 3,00 ms; p99 de 3,16 para 4,19 ms.
2. **A estimativa com emulados foi boa:** o custo extra medido com 6 comerciantes emulados (098h3c, TOMADA) foi de 11,8 s; o medido agora com os REAIS (BATERIA) foi de 11,82 s. **Os perfis são diferentes e não se misturam** (a base era 46,1 s na tomada e é 43,6 s na bateria): só se registra que a ordem de grandeza se confirma; nenhum valor de um perfil entra na tabela do outro.
3. **Por quadro** (um passo a cada 75 quadros a 1x e a cada 9,4 a 8x): o passo médio custa 0,0171 ms por quadro a 1x (base 0,0135) e 0,137 ms a 8x (base 0,108); o extra é de 0,0036 ms e 0,029 ms. Esta medição é do passo, sem renderização: o critério de quadros da DEC-119 NÃO é medido aqui.
4. **Picos (critério 9.15.4: no máximo 5 passos acima de 16,7 ms e nenhum acima de 33 ms; lido como AUMENTO sobre a base, PR #120):** passos acima de 16,7 ms: base 7,7 em média (0, 11 e 12), real 15,3 (10, 17 e 19); acima de 33 ms: base 2,7 (0, 3 e 5), real 5,3 (4, 6 e 6). **A média dos reais é maior nos dois, mas as faixas se sobrepõem** (nos dois critérios há execução da base igual ou maior que a real mais baixa) **e a base sozinha já ultrapassa o limite absoluto** em 2 de 3 execuções neste ambiente. O maior passo foi de 113 ms numa execução real e de 54 a 56 ms em duas da base; a execução 4 da base não teve passo acima de 15,4 ms: os picos aparecem e somem sem relação com o código, ou seja, **o ruído do sistema é maior que o efeito nas contagens, com 3 execuções de cada**. **Não afirmo "atendido" nem "não atendido" com margem; a leitura do critério (aumento sobre a base) e o aceite de desempenho são de Arthur.**
5. **Determinismo e conservação intactos:** o `state_hash` final é IDÊNTICO nas 3 execuções de cada mundo (base `7e9618536281…`, real `3d7852194244…`); `money_conserved=true`, `goods_conserved=true` (30 verificações, uma por dia) e `validate_problems=0` nas 6 execuções.
6. **A guarda por impressão (C3) NÃO foi implementada e esta medição não a pede** (o extra de 11,8 s em 30 dias e a cauda de 4,2 ms no p99 não pedem). A LW-094 e a LW-095 mudam o custo (postos de serviço, mais comércio e outra alimentação): a medição se repete depois delas.

## 2. Método
- **Binários:** release oficial do Godot 4.7.2 (`$HOME/lw-release-probe/bin`), com a cópia do projeto exportada pelo corredor `tests/soak/run_merchant_emulation --release` (cena principal trocada só na cópia, `.pck` exportado uma vez). **Base** = `265087b` (o `main` depois do PR #138, com os dados antigos; o `src/` é o mesmo do real). **Real** = `da9f4ef`, cuja árvore é IDÊNTICA à do `main` `721be98` (`git diff` vazio, a fusão do PR #139). Entre as duas: só `data/population.json`, `data/world/places.json` e testes.
- **Cena:** o jogo real inteiro (economia e rotas dos dados, semente 1 e hora do jogo novo do `GameApp`), 30 dias, `--headless`, custo do PASSO inteiro da simulação, sem renderização; preço real dos dados (`--spread none`); `--merchants 0` nos dois (nenhum comerciante emulado: os seis do real vêm dos dados). Comando: `emulation_release --headless -- --merchants 0 --days 30 --seed 1 --spread none`.
- **Ordem contrabalançada:** base, real, real, base, base, real (3 execuções de cada), com 30 s de resfriamento. Só o preço real e a semente 1: o Q7 (diferença de preço artificial) não se aplica à opção A e não foi medido.
- **Janela e validação** (as da 098h3c): o roteiro só mede com a fonte de energia travada no perfil da 1ª execução válida, a CPU ociosa em 80% ou mais em 3 amostras e o Mac sem ter acordado do sono nos 5 minutos anteriores; depois de cada execução invalida e refaz se o Mac dormiu no meio, a fonte mudou, o relógio da parede passou do tempo medido em mais de 20 s ou algum passo passou de 1 s. **Nenhuma das 6 foi invalidada.** O corte de bateria mínima do roteiro foi reduzido de 60% para 30% (o Mac estava em 42%).

## 3. Condições da máquina
- **Perfil BATERIA** (Battery Power, descarregando) nas 6 execuções, com a bateria de 42% a 34%; modo de economia de energia desligado (`lowpowermode 0`); **nenhum aviso térmico nem de desempenho**; CPU ociosa de 82,7% a 97,0% no começo de cada execução (carga média de 1 minuto entre 1,7 e 4,8); o Mac também rodava a sessão do Claude (uso leve) e o CI do GitHub era remoto. **O Mac dormiu depois da 5ª execução** (17:12): o roteiro esperou, sem consumir CPU, a janela válida voltar (17:17 a 17:26) e só então fez a 6ª, que é válida.
- **O perfil TOMADA NÃO foi medido agora** (Arthur: bateria primeiro, tomada depois, rotulados e nunca misturados); fica opcional, em outra rodada.

## 4. Resultados (cada execução; tempo total em segundos, passo em milissegundos)
| # | Mundo | Início | Bateria | Ociosa | Total (s) | Média/passo | Mediana | p95 | p99 | Máximo | > 16,7 ms | > 33 ms |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | base | 17:04 | 42% | 82,7% | 44,376 | 1,027 | 0,833 | 2,288 | 3,267 | 56,135 | 12 | 5 |
| 2 | real | 17:06 | 41% | 87,1% | 55,034 | 1,274 | 1,049 | 2,964 | 4,144 | 68,297 | 17 | 4 |
| 3 | real | 17:08 | 40% | 97,0% | 55,793 | 1,292 | 1,056 | 3,028 | 4,240 | 59,496 | 19 | 6 |
| 4 | base | 17:10 | 39% | 95,1% | 42,765 | 0,990 | 0,820 | 2,215 | 3,058 | 15,393 | 0 | 0 |
| 5 | base | 17:12 | 38% | 84,3% | 43,610 | 1,009 | 0,828 | 2,239 | 3,148 | 54,274 | 11 | 3 |
| 6 | real | 17:26 | 34% | 88,3% | 55,371 | 1,282 | 1,054 | 3,018 | 4,184 | 113,011 | 10 | 6 |

| | Base (132 NPCs, 0 comerciantes) | Real (138 NPCs, 6 comerciantes) | Diferença |
|---|---|---|---|
| Execuções | 3 | 3 | |
| Tempo total do soak | **43,58** (42,77 a 44,38) | **55,40** (55,03 a 55,79) | **+11,82 s (+27,1%)** |
| Custo médio por passo | 1,009 | 1,282 | +0,274 |
| Mediana / p95 / p99 do passo | 0,827 / 2,247 / 3,158 | 1,053 / 3,003 / 4,189 | +0,226 / +0,756 / +1,031 |
| Máximo do passo (média; faixa) | 41,9 (15,4 a 56,1) | 80,3 (59,5 a 113,0) | ruído |
| Passos acima de 16,7 ms (média; cada) | 7,7 (12; 0; 11) | 15,3 (17; 19; 10) | faixas se sobrepõem |
| Passos acima de 33 ms (média; cada) | 2,7 (5; 0; 3) | 5,3 (4; 6; 6) | faixas se sobrepõem |
| `state_hash` | `7e9618536281e5a9…` (as 3 iguais) | `3d78521942444e81…` (as 3 iguais) | mundos diferentes |

## 5. O que isto NÃO diz e o que falta
- **Não diz** que o critério de desempenho da LW-098h está atendido com margem (seção 1, item 4): com 3 execuções de cada, o ruído do sistema é maior que o efeito nas contagens de picos. A conclusão sólida é a do custo médio e da cauda: **+27% no tempo do passo, +33% no p99**.
- **Falta:** o perfil TOMADA (opcional, rotulado à parte); a repetição depois da LW-094 e da LW-095 (postos de serviço e outra alimentação mudam o custo); o aceite de desempenho (a leitura "aumento sobre a base" é de Arthur); e a medição de quadros com renderização (DEC-119), que é a do medidor de quadros em release (ART-12, 7c-1), não a desta.
- **Reversibilidade** (9.15.5): inalterada; o corredor e os binários dessa medição ficam fora do repositório (`$HOME/lw-release-probe/merchant_emulation/20261118-170304` e `…-170316`).
