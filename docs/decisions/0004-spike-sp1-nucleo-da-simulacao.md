# LW-023 — Spike SP1: núcleo da simulação

- **Status:** resultado entregue; aguarda conferência de Arthur (parada obrigatória). Decisão final do critério de pico depende da medição no Mac de referência.
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
