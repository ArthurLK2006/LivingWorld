# LW-023 — Spike SP1: núcleo da simulação

- **Status:** concluído com ressalva (aprovado por Arthur). **Critério de pico de 10 ms: PARCIAL, ainda não confirmado.** Em release no Mac, 2 das 3 execuções exigidas pela DEC-113 passam em todos os itens da régua; falta a terceira. Em depuração, ver as seções "Medição de referência no Mac" e "seis medições". A medição de referência no Mac (Terminal normal, depuração) teve 7 passos acima de 10 ms e pior de 73,419 ms; ver as seções "Medição no Mac" e "Medição de referência no Mac". Causa ainda não isolada.
- **Pergunta (arquitetura 26.3):** GDScript aguenta relógio + agendador + EventBus + 1.000 NPCs "de mentira" em orçamento de milissegundos, 1 ano de jogo, sem janela?
- **Código descartável:** `tests/soak/sp1/` (`fake_npc_population.gd`, `run_sp1.gd`, teste de sanidade) e `tests/soak/run_sp1 [--days N] [--npcs N] [--seed S]`. NPCs com 3 necessidades e 4 ações, pensando a cada 5 a 15 min escalonados (anel de 16 listas, só processa quem vence), dados quentes em `PackedInt32Array`, ~2 eventos publicados por passo (carga pessimista do barramento). Cada passo = relógio + agendador + módulo + entrega de eventos.
- **Ambiente da medição (NÃO é o hardware de referência):** contêiner de nuvem, Intel Xeon, 4 vCPU, 16 GB, Godot 4.7.2 estável (binário oficial com editor, `--headless`). O hardware de referência (MacBook Air M3) **não foi usado**. Build de release: **executado depois**, com autorização de Arthur (modelos de exportação 4.7.2 de Linux numa pasta temporária fora do projeto; exportação a partir de uma cópia do projeto; ver seção Release).
- **Resultados, 1 ano (518.400 passos), um processo por vez, 1.000 NPCs:**

| Execução | Média/passo | p99 | p99,9 | Máximo | Passos >3 ms | Passos >10 ms |
|---|---|---|---|---|---|---|
| semente 1 (A) | 140,6 µs | 1.019 µs | 1.145 µs | 11,3 ms | 8 | 1 |
| semente 1 (B) | 136,7 µs | 994 µs | 1.104 µs | 10,5 ms | 9 | 1 |
| semente 2 | 137,3 µs | 1.002 µs | 1.110 µs | 9,7 ms | 9 | 0 |
| semente 1 (C) | 138,1 µs | 1.006 µs | 1.120 µs | 6,9 ms | 6 | 0 |
| semente 1 (D) | 136,7 µs | 999 µs | 1.110 µs | 15,9 ms | 17 | 3 |

  Tempo total do ano: ~71 s. Pensamentos de NPC: 51.886.979. Eventos publicados: 1.037.742. Memória estática: +900 bytes em 1 ano (sem crescimento). `validate()`: 0 problemas.
- **Determinismo:** hash `6ed27f5c82950855b7bf45f1bb94688cf103c2e4831e182f292e4b1fd2df236d` idêntico em 4 execuções com semente 1; semente 2 deu `3638be5e…cc02c`, diferente. **Critério atingido.**
- **Escala:** com 3.000 NPCs a média foi 400 µs, p99 3,0 ms (5.236 passos acima de 3 ms), ~3x o custo de 1.000: custo linear em quem pensa.
- **Orçamento médio:** média de ~0,14 ms por passo contra ~3 ms por quadro de referência (arquitetura 20.1) **[HIP]**: folga de ~20x com 1.000 NPCs.
- **Picos:** a distribuição é estreita (p99,9 ≈ 1,1 ms), mas passos isolados chegaram a 6 a 16 ms. Nas execuções repetidas (mesmo trabalho, mesmo hash) os passos mais lentos caem em **índices diferentes** a cada vez, e agrupam-se em janelas, o que aponta para ruído do contêiner compartilhado e não para o código. Mesmo assim 3 de 5 execuções da tabela tiveram algum passo acima de 10 ms, então o critério "sem pico acima de ~10 ms" **não pode ser dado como cumprido sem ressalva neste ambiente**. Recomendação: repetir no Mac de referência (`tests/soak/run_sp1`) antes de fechar o critério; plano B (reduzir frequências, compactar dados) não foi necessário pelos números de média.
- **Release (build sem depuração, mesma máquina):** o binário de release ignora `-s`, então a cópia descartável usou o mesmo código do spike como cena principal. Duas execuções de 1 ano, 1.000 NPCs: média 106,5 e 105,2 µs; p99,9 866 e 853 µs; **máximo 5,5 ms e 6,5 ms; nenhum passo acima de 10 ms**; 5 passos acima de 3 ms em cada. Hash idêntico ao do binário de editor (`6ed27f5c…236d`): o determinismo vale entre os dois tipos de build. O release é ~25% mais rápido que o editor. A ressalva do pico de 10 ms continua aberta até a medição no Mac de referência.
- **Limitações:** NPCs de mentira (sem memória, relações nem rotas); eventos sem ouvintes caros; medição inclui o custo do próprio cronômetro (2 leituras por passo).
- **Relação com DEC-081 e arquitetura 26.3 (SP1).** Proposta de decisão: manter GDScript com este desenho (anel de vencimento + dados compactos) como base dos NPCs T1.

## Medição no Mac (relatada por Arthur em 02/11/2026)
- Mac de referência, executado pelo Codex, build de depuração, Godot 4.7.2, 1.000 NPCs, 360 dias: **51 passos acima de 3.000 µs, 13 acima de 10.000 µs, pico de 88,216 ms**; `state_hash` `6ed27f5c82950855b7bf45f1bb94688cf103c2e4831e182f292e4b1fd2df236d`, **idêntico** ao medido na nuvem (Linux, Xeon). **O critério de 10 ms NÃO foi cumprido nesta medição.**
- **Leitura:** o resultado do mundo é o mesmo nas duas plataformas; só o tempo difere. A distribuição média não foi informada. Nas execuções da nuvem, os passos mais lentos mudam de lugar a cada repetição (ruído). Falta saber se no Mac também mudam.
- **Como decidir a causa:** duas execuções seguidas e uma no Terminal normal, com `tests/soak/run_sp1 --days 360 --top 60`, comparadas com `tests/soak/compare_sp1_runs`. Mesmos passos = trabalho periódico no código (investigar); passos diferentes = ruído da máquina (medir o build de release no Mac).
- **Nenhum documento deve registrar este critério como confirmado.**
- **Linha de base na nuvem (02/11/2026, binário de editor, `--top 60`, mesmo código e mesmo hash `6ed27f5c…236d`):** execução 1: média 140,3 µs, máximo 20,4 ms, 21 passos > 3 ms, 2 passos > 10 ms; execução 2: média 138,8 µs, máximo 16,6 ms, 46 passos > 3 ms, 14 passos > 10 ms. Comparados com `tests/soak/compare_sp1_runs`: 0 de 60 picos no mesmo passo ou a até 2 passos de distância (ruído da máquina), e os picos não se concentram em nenhuma hora do dia simulado. Ou seja, o mesmo código oscila de 2 a 14 passos acima de 10 ms entre execuções nesta máquina; o resultado do Mac (13 passos) está nessa faixa, mas o pico de 88,216 ms é maior que o maior pico da nuvem (30,6 ms). **Isso não confirma o critério; só indica ruído como hipótese até chegarem as saídas do Mac.**

## Medição de referência no Mac (Terminal normal) e demais medições do Mac
- **Medição de referência no Mac (Terminal normal, sem ambiente restrito; build de depuração, Godot 4.7.2, 1.000 NPCs, 360 dias):** média 109,4 µs, p99,9 881 µs, **21 passos acima de 3 ms, 7 acima de 10 ms, pior passo 73,419 ms**, memória estável, `state_hash` 6ed27f5c82950855b7bf45f1bb94688cf103c2e4831e182f292e4b1fd2df236d (idêntico ao da nuvem), nenhuma linha de erro de logs ou certificados. Passos mais lentos: 372674, 492625, 279760, 279713, 492624, 279727, 492621, 372789. **O critério de 10 ms continua NÃO CONFIRMADO.**
- **Medições do Codex no Mac (ambiente restrito, depuração):** (1) 13 passos acima de 10 ms, pico de 88,216 ms; (2) 7 passos acima de 10 ms, pior 76,279 ms, passos mais lentos 59060, 53483, 460220, 453196, 460216, 513033, 460236, 59167; (3) 5 passos acima de 10 ms, pior 48,514 ms, passos mais lentos 418501, 418514, 341448, 162054, 462375, 462402, 418500, 418612.
- **Os picos mudam de lugar:** nas três execuções do Mac com lista de passos (Terminal normal e duas do Codex), nenhum passo coincide com outro a até 2 passos de distância (conferido com `tests/soak/compare_sp1_runs`). Dentro de cada execução, os 8 picos listados formam poucos grupos de passos vizinhos (3, 5 e 4 grupos, com picos a até 200 passos uns dos outros); a lista de 8 não basta para dizer se isso é um padrão (a lista de 60 da nuvem formou 38 a 43 grupos).
- **Hipótese vigente (substitui a anterior):** os engasgos vêm **da máquina ou do build de depuração; a confirmar com o build release.** Não há evidência de causa no código, mas também não há prova do contrário.
- **Evidência a favor do release:** o ramo `mac-snapshot` traz medições do Codex em build **release** no mesmo Mac (modelo macOS oficial): 5 execuções de 525.600 passos sem nenhum pico acima de 10 ms (máximo de 468 µs), enquanto as execuções de editor, no mesmo Mac e no mesmo dia, tiveram picos de 24 a 42 ms (e 87,7 ms na primeira). Ressalva: aquela simulação era bem mais leve (média 3,8 a 5,5 µs por passo, contra ~110 a 140 µs aqui), então não vale como prova para a nossa carga.
- **Efeito para o jogador (taxa por segundo de relógio real):** 7 engasgos acima de 10 ms em ~57 s de execução contínua dão **0,12 por segundo, cerca de 1 a cada 8 segundos** (7,4 por minuto). A 60 quadros por segundo, um quadro dura 16,7 ms: um engasgo de **50 ms equivale a 3 quadros perdidos e um de 90 ms a mais de 5** (5,4); a 30 quadros por segundo, de 1,5 a 2,7 quadros. Um engasgo de 10 ms vale 0,6 quadro. O pior do Mac (73,4 ms) é cerca de 4,4 quadros a 60 FPS. **Limites dessa conta:** é o pior caso, porque o teste ocupa 100% da CPU executando ~9.100 passos por segundo, enquanto o jogo real roda cerca de 0,8 passo por segundo a 1x (6,4 a 8x) e passa quase todo o tempo ocioso. Se os engasgos dependessem do número de passos, seriam 1 a cada ~74.000 passos (7 em 518.400), ou seja, cerca de 1 a cada 26 horas de jogo a 1x. O valor real deve ficar entre os dois extremos; o controle abaixo e a medição de release no Mac é que dizem qual extremo está mais perto.
- **Laço de controle (`run_sp1 --control`):** mesmo número de passos e mesma duração média por passo, só espera ocupada, sem o código do jogo. **Resultado na nuvem (Linux, depuração, 2 execuções de 1 ano):** o controle teve **2 passos acima de 10 ms em cada execução (cerca de 1,7 por minuto)**, máximo de 10,2 e 11,4 ms; a simulação, com código e hash idênticos, teve **0 numa execução e 12 na outra** (0 e 10,1 por minuto; máximo 9,8 e 15,0 ms). **Conclusão:** (a) a máquina sozinha produz engasgos acima de 10 ms, sem nenhum código do jogo; (b) a taxa da simulação variou mais entre duas execuções iguais (0 a 10 por minuto) do que da simulação contra o controle, então esta amostra não separa de forma confiável o que a nossa simulação acrescenta, se acrescenta algo; (c) os engasgos do controle são menores (~10 a 11 ms) que os maiores da simulação (15 ms) e muito menores que os do Mac (48 a 88 ms), de modo que **o controle precisa ser rodado no próprio Mac** para a comparação valer ali. **Não confirma o critério.**
- **Como medir o release no Mac:** `tests/soak/run_sp1_release` (ver `README.md`, seção 10): baixa os modelos oficiais para uma pasta fora do projeto, exporta o pacote e roda o SP1 em release, com controle, duas vezes.

## As seis medições do Mac lado a lado (02/11/2026)
| # | Quem / onde | Ambiente | Média | p99,9 | Passos > 3 ms | **Passos > 10 ms** | Pior passo |
|---|---|---|---|---|---|---|---|
| 1 | Codex, Mac | restrito, depuração | não informada | não informado | não informado | **13** | 88,216 ms |
| 2 | Codex, Mac | restrito, depuração | não informada | não informado | não informado | **7** | 76,279 ms |
| 3 | Codex, Mac | restrito, depuração | não informada | não informado | não informado | **5** | 48,514 ms |
| 4 | Arthur, Mac (referência) | Terminal normal, depuração | 109,4 µs | 881 µs | 21 | **7** | 73,419 ms |
| A | Arthur, Mac | Terminal normal, depuração (`--top 60`) | 108,0 µs | 866 µs | 0 | **0** | 1,266 ms |
| B | Arthur, Mac | Terminal normal, depuração (`--top 60`) | 108,2 µs | 865 µs | 6 | **1** | 10,959 ms (passo 27325) |

Todas com Godot 4.7.2, 1.000 NPCs, 360 dias; `state_hash` 6ed27f5c82950855b7bf45f1bb94688cf103c2e4831e182f292e4b1fd2df236d nas que informaram o hash (idêntico ao da nuvem). A e B foram seguidas, no mesmo Terminal. O comparador deu "MUDAM DE LUGAR: ruído da máquina" entre A e B (2 de 60 picos no mesmo passo exato, 3% a até 2 passos de distância). **A diferença entre as seis, com o mesmo código e o mesmo hash, é descrita como "provavelmente carga ou temperatura da máquina, a confirmar".**

### Régua do registro 0006 aplicada às seis medições (informativo: são todas de depuração)
Execução de 1 ano = cerca de 57 s (518.400 passos x ~108 µs); para as três do Codex, que não informaram a média, suponho o mesmo tempo. Itens da régua: (1) hash idêntico; (2) média ≤ 1 ms e p99,9 ≤ 3 ms; (3) nenhum passo > 50 ms; (4) passos > 10 ms: no máximo 1 por minuto de execução contínua (ou até 1 por minuto acima do controle; não há controle nestas medições); (5) picos não se repetem nos mesmos passos.

| # | (1) hash | (2) média / p99,9 | (3) < 50 ms | (4) taxa > 10 ms | (5) picos | Resultado |
|---|---|---|---|---|---|---|
| 1 | ok | não informado | **falha** (88,2 ms) | **falha** (~13,7/min) | sem lista | **FALHA** |
| 2 | não informado | não informado | **falha** (76,3 ms) | **falha** (~7,4/min) | passa | **FALHA** |
| 3 | não informado | não informado | passa (48,5 ms, 1,5 ms de folga) | **falha** (~5,3/min) | passa | **FALHA** |
| 4 | ok | passa | **falha** (73,4 ms) | **falha** (7,4/min) | passa | **FALHA** |
| A | ok | passa | passa | passa (0/min) | passa | **PASSA** |
| B | ok | passa | passa | **falha por um fio** (1 passo em 56 s = 1,07/min) | passa | **FALHA** (só no item 4) |

**Em palavras simples:** só a execução A passa em tudo. A execução B passa em tudo menos na taxa, e falha por **um único passo lento** numa execução de menos de um minuto. As execuções 1, 2 e 4 quebram o limite duro de 50 ms (de 3 a 5 quadros perdidos) e também a taxa. A execução 3 respeita os 50 ms por pouco, mas falha na taxa. Como são builds de depuração, a régua as trata como informativas: não aprovam nem reprovam.

**Ponto em aberto da régua (a decidir ANTES de medir o release, sem relação com o resultado):** o item 4 diz "no máximo 1 por minuto". Numa execução de ~1 minuto, isso significa que **um único passo lento já reprova** (caso da execução B). Definição (a), literal: por execução. Definição (b): acumulado nas 3 execuções (~3 minutos); com B, seria 1 passo em ~2,8 min, ou 0,36 por minuto. Os limites (1 por minuto, 50 ms etc.) **não mudam** em nenhuma das duas; muda só como se conta. Recomendação minha: (b), porque (a) deixa um único evento decidir o resultado e não distingue uma execução azarada de um problema do código. Fica registrado que, se o release falhar, investiga-se e os números não são ajustados para caber.

## O que roda a cada 99 passos
- **O que roda a cada 99 passos (execução A: passos 12372, 12471, 12570, de ~0,9 ms cada):** é o **módulo de NPCs de mentira do spike**, não o motor. Medido por dentro (201 de 201 intervalos de exatamente 99 passos): nesses passos **818 dos 1.000 NPCs "pensam" de uma vez**, contra ~100 nos demais. A regra de próximo pensamento (`5 + (id + minuto) mod 11` minutos) acaba juntando quase todos os NPCs no mesmo minuto a cada 9 x 11 passos. Isso é 1,01% dos passos e explica o p99 de ~1 ms (8x a média). **Não explica os picos acima de 10 ms** (que mudam de lugar a cada execução). Lição para o módulo de NPCs de verdade: cada NPC precisa de uma fase própria e fixa para não formar ondas (registrado no backlog). Não alterei o spike, porque mudar o módulo mudaria o hash e quebraria a comparação com as medições já feitas no Mac.

## `check_all` no Mac
- Antes: falhava só por falta do `rg` (8 mensagens "rg: command not found" em `tools/check_architecture` e "FALHA: caso válido" em `tests/test_check_architecture.sh`). Depois de `brew install ripgrep` (15.2.0): **VERDE, 141 testes**, numa rodada que ainda incluía as alterações locais do Codex no filtro de ruído (agora incorporadas e testadas aqui com os textos reais dele). Para não repetir o problema, o `check_all` passou a conferir os pré-requisitos no início (`tools/check_prerequisites`) e a parar com uma mensagem única.

## Medições de release do `mac-snapshot` (Codex, mesmo Mac)
- 5 execuções em build **release** (modelo macOS oficial) de 525.600 passos, **nenhuma com passo acima de 10 ms** (máximos de 468, 160, 180, 300 e 191 µs); as execuções de editor no mesmo Mac e dia tiveram picos de 24 a 42 ms (e 87,7 ms na primeira). **Ressalva: a simulação daquela medição era bem mais leve** (média de 3,8 µs por passo no release e 5,5 µs no editor, contra ~108 µs aqui), então ela não prova que a nossa carga passa em release. Comparação completa em `docs/fase-0/mac-snapshot-comparacao.md`.

## Release no Mac (régua da DEC-113) — 02/11/2026
Mac de referência (Apple M3), **build de release** (modelo oficial macOS 4.7.2; o `Motor` informa "build de depuração: não"), carregador ligado, Godot fechado e sem uso durante a medição; commit `6d0e882`; script `tests/soak/run_sp1_release` (download conferido por SHA-512). Linhas brutas, coladas por Arthur:

```
== 4/4 Rodando o SP1 em release (2 vez(es), 360 dias, 1.000 NPCs, com controle)
--- execução 1
Motor: 4.7.2-stable (official) | build de depuração: não
Tempo por passo (us): média 75.1 | p50 69 | p99 577 | p99,9 598 | máximo 2398
Passos acima de 3000 us: 0 | acima de 10000 us: 0
Tempo total: 38.94 s | pensamentos de NPC: 51886979 | eventos de fome: 1037742
state_hash: 6ed27f5c82950855b7bf45f1bb94688cf103c2e4831e182f292e4b1fd2df236d (calculado em 0.6 ms)
Engasgos acima de 10000 us por minuto de execução contínua: simulação 0.00 | controle 0.00
Conclusão do controle: nenhum engasgo acima do limite nesta execução, nem na simulação nem no controle (repita para confirmar).
--- execução 2
Motor: 4.7.2-stable (official) | build de depuração: não
Tempo por passo (us): média 75.1 | p50 69 | p99 578 | p99,9 598 | máximo 2857
Passos acima de 3000 us: 0 | acima de 10000 us: 0
Tempo total: 38.97 s | pensamentos de NPC: 51886979 | eventos de fome: 1037742
state_hash: 6ed27f5c82950855b7bf45f1bb94688cf103c2e4831e182f292e4b1fd2df236d (calculado em 0.6 ms)
Engasgos acima de 10000 us por minuto de execução contínua: simulação 0.00 | controle 0.00
Conclusão do controle: nenhum engasgo acima do limite nesta execução, nem na simulação nem no controle (repita para confirmar).
== Comparação dos picos entre as execuções
  picos listados: 60 e 60
  mesmo passo exato: 0 | até 2 passos de distância: 0 (0%) | mesmo minuto do dia: 15
  VEREDITO: MUDAM DE LUGAR: ruído da máquina
```

**Régua aplicada (2 das 3 execuções exigidas):**
| Item da régua | Execução 1 | Execução 2 | Resultado |
|---|---|---|---|
| (1) hash idêntico | `6ed27f5c…236d` | `6ed27f5c…236d` | **passa** (e igual ao da nuvem e ao da depuração no Mac) |
| (2) média ≤ 1 ms e p99,9 ≤ 3 ms | 0,075 ms / 0,598 ms | 0,075 ms / 0,598 ms | **passa** |
| (3) nenhum passo > 50 ms | máximo 2,398 ms | máximo 2,857 ms | **passa** (nem 3 ms foi ultrapassado) |
| (4) passos > 10 ms, **acumulado** (soma ÷ total de minutos) | 0 | 0 | **passa**: 0 passos em 77,91 s (1,30 min) = 0,00 por minuto; o controle também teve 0 |
| (5) picos não se repetem nos mesmos passos | — | — | **passa**: 0 no mesmo passo exato e 0 a até 2 passos de distância (de 60 listados) |

- **A régua pede 3 execuções e o script fez 2: falta uma.** Até a terceira, o critério **não é dado como confirmado** (e a LW-023 segue "concluída com ressalva"). Para a terceira: `git pull` e `RUNS=1 tests/soak/run_sp1_release` (reaproveita o binário, não baixa de novo, grava `release_run_3.txt` sem sobrescrever as anteriores e compara as três), nas mesmas condições.
- **"Mesmo minuto do dia: 15" (de 60):** previsão a confirmar com as linhas brutas. Em release silencioso, os 60 passos mais lentos de cada execução são em sua maioria os passos de "onda" do módulo de teste (818 NPCs a cada 99 passos, ~0,58 ms, ver acima), que só podem cair em 160 minutos do dia diferentes; com isso, ~25% de coincidência (15 de 60) é esperado por acaso e **não indica** trabalho periódico novo. O item 5 da régua mede passos exatos, não minuto do dia.
- **Leitura:** em release, no mesmo Mac, a média é ~30% menor que em depuração (75 contra 108 µs) e não há nenhum passo acima de 3 ms. As condições (carregador, Godot fechado, sem uso) foram mais silenciosas que as de algumas medições de depuração; a execução A de depuração, nas mesmas condições de Terminal normal, também teve 0. Portanto **não dá para atribuir a melhora só ao build de release**: pode ser build e/ou máquina sem carga. A régua da DEC-113 decide pelo release, não pela causa.
