# LW-071 — Spike SP2: corpos e LOD de NPCs

- **Status:** **proposta (Fase A pronta para revisão e para a medição de Arthur).** Ramo `spike-lw-071`, a partir de `origin/lw-069-lod-e-intencoes` em `f40209d` (o `main`, em `d7e233a`, ainda não continha a LW-069/LW-070 em 08/11/2026).
- **Data e tarefa:** 08/11/2026 (Brasília), LW-071 (roadmap Fase 2; arquitetura 6.2, 15.3 e 26.3, linha do SP2).
- **Rótulos:** **fato** (com origem), **[HIP]** (valor de trabalho do spike), **interpretação** (leitura minha de ponto aberto), **limitação**, **NÃO MEDIDO**.
- **Teto de código:** o envio estimava cerca de 1.200 linhas (parada em 1.560, +30%); o código ficou com **1.807 linhas em 13 arquivos `.gd`**. O teto era uma **estimativa de Claude**; Arthur **aceitou por escrito** em 08/11/2026 e fixou o novo teto de parada em 1.900 linhas e 16 arquivos.

## Contexto e problema (pergunta e critério)

Dá para alternar NPCs entre S1 (sem corpo) e S0 (com corpo e navegação) sem teleporte, sem duplicação e sem queda de quadros, antes do `NpcView` definitivo (LW-072)? Critério do roadmap: sem duplicar, sem teleporte, quadros estáveis (régua da **DEC-119, APROVADA**: média ≥ 60 quadros/s e nenhum quadro > 33 ms, no Mac de Arthur, na tomada, em release), abordagem de navegação escolhida e decisão registrada. Plano B (26.3): reduzir o raio S0, simplificar a navegação, menos NPCs corpóreos. Perguntas:

- **P-a** duplicação, corpo órfão, teleporte; **P-b** quadros e custo por NPC; **P-c** a navegação mais simples que passa; **P-d** passo do corpo × relógio e tempo limite; **P-e** raio S0 × terreno; **P-f** corpo quando o Intent vence ou o NPC sai de S0.

Decisões citadas: DEC-016 APROVADA (só o hardware de referência), DEC-035 APROVADA, DEC-039 PROPOSTA, **DEC-040 PENDENTE** (os 100 NPCs são [HIP] do spike, não fixam número), DEC-057 APROVADA, DEC-119 APROVADA, DEC-120 APROVADA.

## Método

- **Código descartável** em `tests/soak/sp2/` (13 `.gd` + `sp2_main.tscn`) e `tests/soak/run_sp2`. Nada em `src/`, `data/`, `scenes/`, `project.godot`, contratos, eventos ou autoloads.
- **Mundo próprio do spike (fato):** o jogo real registra o `npc`, mas não liga o LOD nem o protocolo S0 nem entrega o `npc` à ponte (limitações 3 e 5 da LW-069/LW-070 em `docs/modules/npc.md`). Ligar isso exigiria mexer em `src/`. O spike monta um `SimulationRunner` com o `NpcModule` (precedente `tests/unit/test_npc_intents.gd`) e os dados **reais** (terreno, locais, necessidades, catálogo, `lod_params.json`, `intent_params.json`) e chama só a API pública: `request_create_npc`, `request_set_focus`, `create_action_runner`, `configure_intents`, `peek_pending_intents`, `request_report_npc_result`, `request_report_npc_positions`, `intents.begin_embodied`, `lod.position_of/s0_ids` e `lod.place_position_cm` (membro público que "quem monta o módulo liga"). A cena real (`scenes/main.tscn`) dá chão, câmera e jogador. O relógio do mundo do spike **copia a pausa e a velocidade** do relógio do jogo (`peek_time`). **Consequência:** o custo medido é o do jogo **mais** um segundo mundo pequeno; a ponte não é exercitada (ela só repassa; testada na LW-070).
- **População e diretor:** 100 NPCs por `request_create_npc` (60 em A, 12 casas × 5; 40 em B, 8 × 5; locais de `data/world/places.json`). Rotina fixa trabalho → convívio → descanso → casa (`go_to_place`, `work`, `talk`, `rest`, `wait`), etapas desencontradas pelo índice (sem sorteio). S1 usa `begin`/`advance` do runner; S0 usa `begin_embodied` e só termina com o resultado do corpo.
- **Corpos e pool:** cápsula com nariz e cor por estado, sem física, altura por `TerrainData.peek_height`; pool pré-aquecido; relato de posições em lote a cada 6 quadros de física; resultados ARRIVED, DONE, BLOCKED com o `action_serial`.
- **Invariantes** (a cada 30 quadros e ao fim) e **detector de teleporte** (a cada quadro de física), como pedido.
- **Ensaios:** `alternancia` (rota pelo povoado A, 3 entradas e 3 saídas, mais 20 s na faixa de histerese), `carga` (max_s0 = 100 em código; dois focos; depois os 100 nascidos em A), `relogio` (1x, 2x, 4x, 8x e pausa, P1 depois P2), `ver` (3 min livres) e `headless`.

## Máquina e build

- Mac de Arthur (DEC-016), Godot 4.7.2 estável. **O que eu rodei:** só sem janela e em **depuração** (`build de depuração: sim`, driver opengl3 / gl_compatibility no headless). **Release, janela e tomada: NÃO EXECUTADOS** (são de Arthur). Binário de release encontrado: `$HOME/lw-release-probe/bin/godot_macos_release.universal`.

## Constantes [HIP] (todas em `Sp2Constants`)

| Grupo | Valor |
|---|---|
| Passo natural (P1) | 4 m/s × velocidade do relógio (= `PlayerBody.WALK_SPEED_MPS`) |
| P2 | teto 7 m/s × vel. (= `RUN_SPEED_MPS`), piso 0,8 m/s × vel. |
| Chegada / tolerância das invariantes | 0,3 m / 0,05 m |
| Teleporte | vel. máx. × delta × 1,5 + 0,05 m |
| Pool | 60 corpos pré-aquecidos |
| Invariantes | a cada 30 quadros |
| N1 | amostra a cada 2 m; limite 40° (`MAX_WALKABLE_SLOPE_DEGREES`) |
| N2 | célula 4 m, margem 64 m; bloqueia 40° e `rock` |
| Ensaios | carga 30 s; relógio 20 s por segmento; histerese 20 s; ver 180 s |
| Rota de alternância | pelo caminho z = 513 m: x 330 → 490 → 330 → 490 → 330; histerese entre x 440 e 452 |
| Foco fixo da carga | (800, 660) m, ID 900000 |

## Resultados (o que eu medi, sem janela, depuração)

Duas execuções de `--headless` (alternância curta: x 330 → 490 → 330, cerca de 77 s):

| | Execução 1 | Execução 2 |
|---|---|---|
| Quadros: média / p99 / pior | 6,96 / 9,47 / 96,7 ms | 6,90 / 8,43 / 9,9 ms |
| Acima de 33 ms | 5 (20,7 s; 38,0 s; 41,9 s; 42,0 s; 42,1 s) | 0 |
| Invariantes | 0 em tudo (382 conferências) | 0 em tudo (385 conferências) |
| Pool | criados 60, retirados 114, devolvidos 64, pool vazio 0, perdidos 0 | igual |
| Corpos | 15 chegadas, 15 atrasadas, levado/previsto 2,00, 3,99 m/s | igual |
| Custo dos corpos | 135,5 µs por quadro de física | 40,2 µs (pior 0,66 ms) |
| Custo do mundo do spike | 436,3 µs por quadro | 160,0 µs (pior 3,88 ms) |

- **P-a (fato, teste e headless):** zero duplicados, órfãos, teleportes e posições fora (nascimento e saída). O teste (a) faz 20 ciclos de entrada e saída dos 100 NPCs sem nenhuma violação; corpos ativos == NPCs em S0 em todos os passos.
- **P-b:** custo por NPC, só depuração sem janela: com cerca de 50 em S0, 40 a 136 µs por quadro de física para todos (≈ 1 a 3 µs por NPC) mais 160 a 436 µs do mundo do spike. **Quadros em release: NÃO MEDIDO.** Comparação com a LW-053A (8,37 a 8,39 ms em release) fica para Arthur.
- **(c) Os 5 quadros acima de 33 ms da execução 1:** o pool **não** criou corpo novo (criados 60 = o pré-aquecimento, "pool vazio 0"; o pico foi 52). Os corpos foram reaproveitados ou saíram do pré-aquecimento. A causa dos quadros lentos **não sei**: não medi por seção naquele instante (o pior custo por seção só foi medido na execução 2, onde não houve quadro lento). Nos instantes 20,7 s e cerca de 42 s o jogador entrava no raio do povoado A (interpretação pelo tempo da rota).
- **max_s0 = 50** (dados) com 60 NPCs em A: 10 ficam em S1 mesmo perto; o limite trocou vagas no mesmo passo (pico de 52 corpos antes de eu passar a tratar as saídas antes das entradas).

## Navegação (P-c)

Rotas no terreno real (5 repetições; a 1ª N2 de cada trecho preenche o cache de células). Esta tabela é da execução 2; o r4 foi depois mudado para (520, 300) → (880, 300), porque o destino antigo caía na pedra. **r4 novo: NÃO MEDIDO.**

| Rota | N1 (reta) | N2 (grade A*) |
|---|---|---|
| r1 povoado A (75 m) | chega · 0,11 ms (pior 0,12) | chega, 81 m · média 6,57 ms, pior 31,70 ms |
| r2 de A a B (495 m) | chega · 0,66 ms (pior 0,69) | chega, 531 m · média 26,45 ms, pior 126,56 ms |
| r3 morro íngreme (LW-047A) | **sem caminho** (recusa o lado de ~50°) · 0,03 ms | chega, 112 m, contornando · média 4,56 ms, pior 21,78 ms |
| r4 pedra (antigo) | chega por cima de 70 amostras de pedra · 0,26 ms | sem caminho (destino em pedra) · média 6,13, pior 29,00 ms |

- **(a) Os 127 ms da 1ª r2 na N2:** a 1ª chamada monta o cache das células bloqueadas e faz a busca; as 4 seguintes só montam a grade e buscam. Das médias: (5 × 26,45 − 126,56) ÷ 4 ≈ **1,4 ms** por chamada seguinte. Portanto **≈ 125 ms são a montagem do cache** (conta minha sobre a medição; a separação exata não foi medida). No r1, as seguintes ≈ 0,3 ms.
- **N1** passa em tudo o que a rotina usa (r1, r2); falha onde há obstáculo real (r3) e ignora pedra (r4). **N2** contorna, mas a 1ª rota de uma região custa até 127 ms num quadro (tranco), salvo pré-calcular o cache no carregamento. **N3: não construída** (N1 e N2 não falharam em nada que a exija).
- **Limitação:** as caixas dos locais (LW-074) não têm colisão; construções e água não são obstáculo em nenhuma candidata.

## Relógio × corpo (P-d)

- Contas à mão do teste (d) (`test_speed_policies_by_hand`, verde): P1 a 1x = 4 m/s; P1 a 8x = 4 × 8 = **32 m/s**; P2 a 1x, 10 m com 8 min = 10 ÷ (8 × 1,25) = **1 m/s**; P2 a 8x, 10 m com 8 min = 10 ÷ (8 × 1,25 ÷ 8) = **8 m/s**; P2 com teto, 100 m com 2 min = 40 m/s → **7 m/s** e chega atrasado (100 > 7 × 2,5 = 17,5 m); P2 com piso, 1 m com 10 min = 0,08 → **0,8 m/s**; P2 atrasado a 2x = 7 × 2 = **14 m/s**; pausa = **0** nas duas.
- **Interpretação:** "o corpo respeita a velocidade do relógio" = as velocidades são multiplicadas pela velocidade do relógio (a 8x o corpo anda 8 vezes mais rápido na tela). Assim, em minutos de jogo, o corpo cobre o mesmo chão em qualquer velocidade.
- **Conta no papel (não medida):** o `go_to_place` do S1 planeja 8400 cm/min (≈ 67 m/s reais a 1x). Nenhum corpo acompanha: toda caminhada em S0 chega atrasada (o headless viu 15 de 15, levado/previsto 2,00). O tempo limite é o fim planejado + 30 min. P1 cobre 4 × 1,25 = 5 m por minuto de jogo → ~155 m em 31 min; P2 no teto, 8,75 m/min → ~271 m. Logo, **r2 (495 m) vence o tempo limite nas duas**, em qualquer velocidade; as caminhadas do povoado (≤ ~80 m) cabem.
- **Tabela por velocidade e política (ensaio `relogio`): NÃO MEDIDO** (é de Arthur, com `--release`).
- **P3 (só no papel):** `DEFAULT_WALK_SPEED_CM_PER_MIN` = 4 m/s × 1,25 s = **500 cm/min** (hoje 8400). Efeito no S1: as caminhadas ficam 16,8 vezes mais longas (70 m: 14 min em vez de 1; A → B: 99 min em vez de 6), e S0 e S1 passam a concordar. É dado e consistência entre níveis: **decisão de Arthur**, DEC nova. Também pediria rever `intent_timeout_min` (30 < 99). Nada foi mudado.
- **Limitação (fato, `action_runner.gd`):** a duração do `go_to_place` sai de `x_cm/z_cm` lógicos; em S0 eles ficam velhos até a saída, então a duração prevista pode partir do lugar errado.

## P-e (raio S0 × terreno)

- Fato (`terrain_streaming.gd`): carga de 384 m (+64 de histerese), fino de 128 m (+64); colisão só em chunk fino (`terrain_view.gd`). S0 entra a 80 m e sai a 120 m do foco: dentro do fino, se o foco for o jogador. O corpo **não precisa** de colisão (segue `peek_height`), então não cai fora dela.
- Fora do raio fino, a malha grossa (passo de 4 m) difere da altura bilinear de 2 m: o corpo pode flutuar ou afundar um pouco. **NÃO MEDIDO.**
- Com um **segundo foco** (ensaio de carga, povoado B a ~495 m do jogador), os corpos de B ficam **fora do raio de carga** do terreno: sem chão desenhado. Funciona, mas desenharia gente no vazio se a câmera os visse.

## P-f (tempo limite e saída de S0)

- Fato (contrato LW-070 e testes): Intent vencido → a ação é cancelada sem efeito; o corpo vê o Intent sumir, fica parado e espera o próximo (contado como "Intents sumidos"); resultado tardio vira `NPC_RESULT_STALE` (teste (f)).
- NPC que sai de S0 no meio da caminhada: o corpo volta ao pool, o último relato vira a posição lógica e a ação segue abstrata até chegar (teste (g)); NPC removido devolve o corpo.
- NPC que entra em S0 no meio de uma ação abstrata não recebe Intent (limitação 4 da LW-070): o corpo anda até o destino só para não ficar parado, e quem termina a ação é o runner abstrato ("ações herdadas").

## Testes (cobertura pedida)

`tests/soak/sp2/test_sp2_logic.gd`, 8 testes, roda no `tools/check_all`: população real; (a)+(b) 20 ciclos, pool sem corpo novo depois do aquecimento e sem vazamento de nós; (c) teleporte; (d) políticas à mão; (e) N1 segue a altura e recusa r3, N2 contorna e diz "sem caminho"; (f) resultado velho e tempo limite; (g) saída no meio da caminhada e remoção; (h) determinismo (hash do mundo e contadores, duas vezes).

## O que o spike NÃO cobre

Ligação com o jogo real e a ponte de verdade (conversa A); pensamento e população de verdade (LW-063, LW-067); construções e água como obstáculo; animação de verdade; 300 NPCs; multidão; jogador parado muito tempo em área densa; outro hardware; quadros em release; sensação.

## ROTEIRO PARA ARTHUR (ver)

1. Na tomada, tampa aberta, conversas A e B paradas. 2. Rode `tests/soak/run_sp2 --ver`. 3. Ande até o povoado A (a leste, pelo caminho) e volte. 4. Aperte H (painel), B (números), M (política), N (navegação). Velocidade do relógio: só 1 e 2 pelo jogo (4x e 8x ficam para o ensaio `relogio`). 5. Depois de 3 min, o resultado sai no Terminal.

Perguntas (respostas de Arthur **palavra por palavra**, preenchidas depois):
1. Os NPCs aparecem e somem de um jeito que você nota ou parece natural? — *(a preencher)*
2. O jeito de andar parece de gente? — *(a preencher)*
3. Você viu algum NPC pular de lugar ou aparecer duplicado? — *(a preencher)*
4. O jogo continua fluido com todo mundo em volta? — *(a preencher)*
5. A velocidade dos NPCs combina com o relógio quando você acelera? — *(a preencher)*

## Plano B (26.3), se algum número falhar

Quadros fora: raio S0 de 80 → 50 m e `max_s0` de 50 → 30 (valores sugeridos [HIP]). Navegação cara: ficar na N1 e não usar a N2 em execução (só como cálculo pré-feito). Tempo limite em rotas longas: P3, ou tempo limite proporcional à distância (decisão de Arthur).

## Proposta de entrada para DECISIONS.md (número provisório DEC-122; SÓ proposta)

- **Título:** navegação e velocidade dos corpos S0 (resultado do SP2).
- **Contexto:** SP2 (este registro). **Decisão proposta:** (1) navegação **N1** (rota reta por pontos, recusa acima de 40°) para a LW-072, com N2 guardada para quando houver obstáculos; (2) política de velocidade a escolher por Arthur depois da medição (recomendação provisória: **P1**, a mais simples; P2 só muda o ritmo de caminhadas curtas). (3) A diferença entre 8400 cm/min (S1) e o corpo (500 cm/min) precisa de decisão: P3 ou tempo limite maior. **Justificativa:** N1 passa nas rotas da rotina com ~0,1 a 0,7 ms; N2 custa até 127 ms na 1ª rota. **Consequências:** caminhadas longas em S0 vencem o tempo limite enquanto o ponto 3 não for decidido.

## Limitações

Medido só em depuração sem janela; duas execuções diferentes nos quadros lentos; r4 novo e ensaios `carga`/`relogio`/`ver` não rodados por mim; a ponte não foi usada; o mundo do spike soma ao custo do jogo.

- **Relação com DEC-NNN:** DEC-016, DEC-035, DEC-039, DEC-040, DEC-119, DEC-120.
