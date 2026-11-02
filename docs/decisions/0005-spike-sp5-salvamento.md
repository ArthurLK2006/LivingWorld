# LW-028 — Spike SP5: salvamento

- **Status:** resultado entregue; aprovado pela regra automática de Arthur (check_all verde, sem desvio). A DEC-084 (formato de save do protótipo) foi aprovada por Arthur com base neste relatório. Medido no contêiner de nuvem, não no Mac de referência.
- **Pergunta (arquitetura 26.3):** salvar e carregar um mundo cheio é rápido, exato e seguro?
- **Código descartável:** `tests/soak/sp5/run_sp5.gd` e `tests/soak/run_sp5 [--days N] [--npcs N] [--rounds N]` (usa o mundo do SP1, `FakeNpcPopulation`, agora com `on_load`).
- **Ambiente:** contêiner de nuvem, Intel Xeon, 4 vCPU, Godot 4.7.2 estável (binário de editor, `--headless`). Build de release: não medido para o SP5.
- **Resultados (média de rodadas; orçamento da arquitetura 20.1: salvar ≤ ~100 ms na thread principal, carregar em poucos segundos [HIP]):**

| NPCs | Estado em JSON | Arquivo (gzip) | Capturar | Codificar | **Salvar completo** | **Carregar total** |
|---|---|---|---|---|---|---|
| 1.000 | 27,5 KB | 8,1 KB | 0,1 ms | 1,7 ms | **2,3 ms** | **0,9 ms** |
| 10.000 | 279 KB | 80 KB | — | — | 26,0 ms | 7,0 ms |
| 50.000 | 1,48 MB | 387 KB | 4,6 ms | 109 ms | 139,7 ms | 35,2 ms |

  "Salvar completo" = codificar + gravar `.tmp` + reler e conferir + girar backups + renomear. "Carregar total" = ler arquivo + descomprimir + checksum + restaurar mundo + validar.
- **Equivalência exata do hash:** idêntico logo após carregar e **idêntico depois de mais 1 dia simulado nos dois mundos** (em 1.000, 10.000 e 50.000 NPCs). Salvar e carregar no meio de uma simulação não muda o hash final (também coberto por `test_save_codec.gd`). **Critério atingido.**
- **Falha simulada:** falha injetada depois de cada um dos 4 passos do salvamento deixa o slot carregável em 4 de 4 casos (`test_save_store.gd` cobre também o conteúdo correto). **Critério atingido.**
- **Tamanho:** o gzip reduz o JSON a ~26 a 29%. Com NPCs de mentira (só números inteiros) o estado é pequeno; NPCs reais (memórias, relações, crônica) pesarão mais, e a poda (arquitetura 18.7) será necessária.
- **Conclusão:** com o mundo do SP1 (1.000 NPCs) o JSON comprimido atende com folga (~2 ms para salvar). O custo é linear: cerca de 0,09 ms por KB de JSON, então o orçamento de 100 ms na thread principal é ultrapassado perto de ~1 MB de estado (≈ 35.000 NPCs desse tipo). **Plano B, não aplicado por não ser necessário agora:** capturar o estado na thread principal (4,6 ms em 50.000 NPCs) e codificar e gravar em outra thread, sem trocar o formato por binário.
- **Limitações:** NPCs de mentira; sem fsync (o Godot não oferece); medição em ambiente de nuvem compartilhado; a escrita em thread não foi implementada nem testada; nenhum teste de disco cheio.
- **Proposta (para Arthur decidir, relacionada à DEC-084, que segue PROPOSTA):** manter JSON comprimido com a escrita `.tmp` → conferência → backups → final como formato do protótipo; reavaliar binário só se o estado real passar de ~1 MB e a escrita em thread não bastar.
