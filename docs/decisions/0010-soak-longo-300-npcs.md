# LW-084 — Soak longo: 300 NPCs por 1 ano de jogo, com a alternância S1 ↔ S0

- **Status:** **proposta** (registro de resultado de teste; não muda o status de nenhuma decisão). A LW-084 passa pelo critério de aceite: sem exceção, sem erro de `validate()`, zero mortes e hash repetível (decisão de Arthur de 10/11/2026: picos de passo **não** reprovam).
- **Data e tarefa:** 10/11/2026 (Brasília), LW-084 (084a medidor, 084c release, 084b este registro). Roadmap, linha da LW-084; arquitetura, cap. 20.
- **Rótulos:** **fato** (medido, com origem), **[HIP]** (valor de trabalho), **ruído** (medição feita com outro Godot rodando no Mac), **limitação**.

## Contexto e problema

Critério do roadmap: 300 NPCs por 1 ano de jogo sem janela e com alternância S1 ↔ S0; tick médio dentro do orçamento do cap. 20, sem pico acima de ~10 ms, sem crescimento de memória, hash repetível, sem exceção. Respostas de Arthur de 10/11/2026: os **300 NPCs e o fator ×3 são [HIP]** (a DEC-040 está PENDENTE); a régua de tempo é **[HIP]** (média dentro de ~3 ms e nenhum passo acima de ~10 ms; a DEC-071 é PROPOSTA); **reprovam só** morte de NPC, erro de `validate()`, erro de script ou hash diferente entre execuções; a régua dos picos é **release com a taxa do laço de controle** (a regra da DEC-113 como proposta de trabalho: a DEC-113 foi aprovada só para a LW-023) e a depuração é só informativa.

## Método

- **Medidor** `tests/soak/npc_year/npc_year_meter.gd` (`NpcYearMeter`): o jogo real (`GameModules`, dados de `data/`) com a **capacidade dos locais e a população ×3 em memória** (`SCALE`; `data/` não muda), 40 notáveis (T2, o teto de `data/npc_params.json`), semente 11. O foco do ator anda em ciclo entre o povoado A, o B e um ponto longe de tudo (trocas de **480 min** no padrão `base` e de **30 min** no `stress`), e um **corpo falso** cumpre o protocolo dos Intents (chega e termina na hora prevista; sem Node, sem janela). Mede o passo (`Time.get_ticks_usec`), a memória estática e os objetos de cada dia, o save (comprimido e sem comprimir) a cada 30 dias, mortos e vivos, a validação do mundo e do módulo a cada fim de dia e o hash. Ao fim, conta memórias, traços e relações de cada notável. A conversa do jogador não entra.
- **Versão curta** (`test_npc_year_short.gd`, 1 dia, no `check_all`) e **versão longa** (`soak_npc_year.gd` por `tests/soak/run_npc_year [base|stress]`, 3 execuções: direta, repetida e com salvar e carregar no meio, numa virada de dia com o foco longe, porque o save não guarda corpos). **Release:** `tests/soak/run_npc_year_release` (084c), com laço de controle.
- **Máquina e build:** Mac de Arthur (Apple M3, segundo o registro do SP2), Godot 4.7.2-stable, tomada. As medições do ano são em **depuração** (única com memória estática); as de release são de 30 dias. O Mac é compartilhado com as outras conversas.

## Resultados (fatos)

**Tudo o que decide a LW-084 deu verde:** nas 8 execuções de 1 ano (1 pré-medição, 4 do `base`, 3 do `stress`) e nas 3 de 30 dias em release: **300 vivos o tempo todo, zero mortes, zero erro de `validate()`, zero erro de script, hash idêntico entre as execuções do mesmo padrão** (direta, repetida e salvando e carregando no meio; o do `base` saiu igual nas 5 execuções, inclusive na pré-medição sem a LW-073).

| Execução (1 ano, depuração) | hash | média | p99,9 | máximo | > 3 ms | > 10 ms | parede |
|---|---|---|---|---|---|---|---|
| Pré-medição, `base` (sem a LW-073 no código; **ruído** no começo) | `5141d7e7a84b` | 2344 µs | 12.306 | 208.954 | 119.787 | 723 | 20,9 min |
| `base` 1 (direta; nenhum outro Godot) | `5141d7e7a84b` | 2358 µs | 12.701 | 206.453 | 119.180 | 785 | 21,0 min |
| `base` 2 (repetida; nenhum outro Godot) | `5141d7e7a84b` | 2358 µs | 11.207 | 276.270 | 119.186 | 625 | 21,0 min |
| `base` 3 (salvar e carregar no dia 180; nenhum outro Godot) | `5141d7e7a84b` | 2403 µs | 13.837 | 292.911 | 123.871 | 844 | 21,4 min |
| `base` 4 (extra, com as contagens dos notáveis; **ruído**) | `5141d7e7a84b` | 2316 µs | 9.208 | 751.912 | 114.731 | 447 | 20,6 min |
| `stress` 1 (direta; **ruído** a partir de 14:53) | `50af223b6f51` | 2389 µs | 13.163 | 238.610 | 119.973 | 812 | 21,2 min |
| `stress` 2 (repetida; **ruído**) | `50af223b6f51` | 2661 µs | 25.003 | 372.890 | 147.137 | 2062 | 23,6 min |
| `stress` 3 (salvar e carregar no dia 180; **ruído**) | `50af223b6f51` | 2417 µs | 10.567 | 672.018 | 123.248 | 571 | 21,4 min |

| Release, 30 dias, `base` (nenhum outro Godot; carga do Mac 3 a 5,6) | hash | média | p99,9 | máximo | > 3 ms | > 10 ms | controle > 10 ms |
|---|---|---|---|---|---|---|---|
| 1 | `28cfa2f2b844` | 1752 µs | 4663 | 20.998 | 2171 | 3 | 0 |
| 2 | `28cfa2f2b844` | 1871 µs | 15.800 | 122.987 | 3399 | 106 | 18 |
| 3 | `28cfa2f2b844` | 1783 µs | 5812 | 63.068 | 2508 | 12 | 23 |

- **Tempo:** a média por passo fica dentro de ~3 ms [HIP] nas 10 execuções (1,75 a 1,87 ms em release; 2,34 a 2,66 ms em depuração). O release é cerca de 20% mais rápido e dá o **mesmo hash** que a depuração (2 dias: `280b928e9c01` nos dois). Passos acima de 3 ms: 23% a 28% em depuração e 5 a 8% em release.
- **Picos acima de ~10 ms (só informativos, pela decisão de Arthur):** depuração, 447 a 2062 por ano (0,09% a 0,4%), com máximos de 206 a 752 ms; release, 3, 106 e 12 em 30 dias. **No release, nenhum caiu nos 5 minutos depois de uma troca de foco** (a análise só existe no nó de release). O passo mais lento cai em **minutos diferentes** de uma execução para outra embora a simulação seja idêntica (mesmo hash): custo que não se repete no mesmo passo aponta para a máquina, não para um passo caro do código (indício, não prova). No release, o controle (espera ocupada, sem o código do jogo) também teve passos acima de 10 ms em duas das três execuções. Taxa acumulada em release: simulação 31 por minuto contra 10,5 do controle; como o controle roda depois da simulação e não junto, **inconclusivo**.
- **Memória (depuração):** a memória estática cresce **1,83 a 1,92 MiB, todo nos primeiros 30 dias**, e fica plana até o dia 360 (diferença entre o dia 30 e o 360: 0 a 0,1 MiB nas execuções do ano; a maior oscilação no meio do ano foi 0,4 MiB, no dia 180 do `base` 3, o dia do salvar e carregar); os objetos ficam entre 4.175 e 4.226 do dia 30 ao 360. **Em release a memória estática vem 0** (o monitor só existe em depuração); só os objetos valem (2343 no começo, 3689 no dia 30).
- **Save:** comprimido (gzip) 19,6 a 20,4 KiB e sem comprimir 340 a 345 KiB, **estáveis** do dia 30 ao 360 (variação de até 3%).
- **Corpos (falsos):** pico 50 (o `max_s0` de `data/lod_params.json`), média 33,3; entradas em S0: **103.819** no `base` e **676.741** no `stress`.
- **Notáveis no fim do ano (40, mín/média/máx):** `stress`: memórias **24/24,0/24** (todos no teto `memory_capacity` 24), traços permanentes **0/0,0/0** (o limiar de 80 nunca é atingido), relações **10/14,7/16** (teto `relations_capacity` 16). `base`: memórias **24/24,0/24**, traços **0/0,0/0**, relações **8/14,6/16**. Contagens por `peek_*`, que só leem (o hash não muda).
- **Salvar e carregar:** com o foco longe (sem corpos), o hash depois de carregar é idêntico ao da execução direta nos dois padrões, em 1 dia e em 1 ano. **Limitação:** com NPCs em S0 no instante do salvamento o hash seria outro (o save não guarda corpos; ver `docs/modules/npc.md`); não foi medido em escala.

## Limitações e riscos

- **Corpo falso e foco que "teletransporta":** o custo medido de S0 é o do protocolo dos Intents e do LOD; **não** inclui física, navegação, desenho nem a conversa do jogador. O SP2 (`0009`) mediu o lado do corpo: zero duplicados, órfãos e teleportes; cerca de 0,13 a 0,17 ms por quadro de física com 100 corpos; 6 quadros acima de 33 ms em 50.549 na medição oficial (fora da régua da DEC-119 em 3 de 13 ensaios, causa aberta para a LW-072).
- **Ruído:** as execuções do `stress` e a extra do `base` rodaram com outras conversas usando Godot no mesmo Mac (rótulo **ruído**); o que reprova não depende de tempo. Os tempos "limpos" são os do `base` 1 a 3 (nenhum outro Godot) e os do release de 30 dias; mesmo assim a carga do Mac, que não é só Godot, ficou entre 3 e 5,6.
- **Ano em release e a memória em release:** não feitos (decisão de Arthur; backlog).
- **Constantes [HIP]:** 300 NPCs e ×3 (DEC-040 PENDENTE), 40 notáveis (dado), padrões de 480 e 30 min, régua de ~3 e ~10 ms (DEC-071 PROPOSTA), limite de 2 MiB de crescimento em 1 dia na versão curta.

## Escolha ou recomendação

- Os 300 NPCs nascem **no código do teste** (sem tocar em `data/`); a régua de pico é **release com a taxa do controle**, e a depuração é informativa; mortes só são registradas, mas a LW-084 exige zero mortes na Fase B.
- **Proposta de régua definitiva de "sem crescimento de memória" [HIP], a decidir por Arthur:** crescimento da memória estática entre o dia 30 e o dia 360 de **no máximo 0,5 MiB** (o maior observado foi 0,1 MiB; a oscilação máxima no meio do ano foi 0,4 MiB; o crescimento dos primeiros 30 dias, de 1,8 a 1,9 MiB, é o aquecimento). Não gravei essa constante em teste: o teste curto segue com 2 MiB por dia.

## Para a revisão da LW-085 (pedido de Arthur)

Custo de memória e relações com 300 NPCs em 1 ano: **notáveis saturam as memórias (24 cada) e quase as relações (14,7 de 16)**, o save inteiro fica em ~340 KiB sem comprimir (~20 KiB comprimido) e **não cresce** depois do dia 30, e a memória do processo cresce só ~1,9 MiB e só no começo. O que o SP2 já mostrou sobre corpos S0/S1: resumo na seção anterior e em `docs/decisions/0009-spike-sp2-corpos-e-lod.md`.

## Validação e referências

- Comandos: `tests/soak/run_npc_year base|stress` (ano, 3 execuções), `tests/soak/run_npc_year_release base` (30 dias, 3 execuções, controle); `tools/check_all` verde com a versão curta.
- Código: `tests/soak/npc_year/` e `tests/soak/README.md`. Commits: `63c0f0a` (084a), `629aa40` (084c), 084b na Fase B.
- **Relação com decisões:** DEC-040 (PENDENTE; os 300 são [HIP]), DEC-071 (PROPOSTA; régua de tempo [HIP]), DEC-113 (aprovada só para a LW-023; aqui, proposta de trabalho), DEC-119 (régua de quadros do jogo, fora desta medição).
