# SP1 — medição preliminar, LW-023

**Situação: incompleta.** A medição usa o executável do editor Godot 4.7.2, sem janela, e não substitui o teste exigido com build release nem o módulo completo com relógio, agendador, barramento e ações.

- Script: `tests/spikes/sp1_benchmark.gd`; 1.000 registros fictícios de fome, atualizados uma vez por hora, durante 525.600 minutos (365 dias é hipótese apenas para a medição).
- Primeira execução: média 0,452 µs/tick, pico 173 µs.
- Segunda execução: média 0,492 µs/tick, pico 625 µs.
- Ambas produziram SHA-256 `e7aaf4cbc50e59f503dcc0a3a53e77ed470f57fb41afff3a225b3ff3ac271554`.
- O processo terminou com código 0 e exibiu o erro de certificados já observado no ambiente Codex. As medições não provam desempenho da simulação completa nem de um executável release.

## Cenário integrado posterior

O script foi ampliado para usar relógio, agendador, fila de eventos, IDs/RNG e módulo fictício de 1.000 NPCs, com uma atualização horária simples. Foram dois anos de teste separados, cada um com 525.600 passos (365 dias como hipótese), no executável do editor Godot 4.7.2 headless.

- Primeira execução: média 5,551 µs/passo; pico **87.746 µs** (87,746 ms).
- Segunda execução: média 5,288 µs/passo; pico 113 µs.
- Ambas: 87.630 ações e hash SHA-256 `3979f57a6afcbaf6c0206b5df85fb1a619adcb6d6766c29e79de34da9f4fdc56`.
- O pico da primeira execução ultrapassa o limite aproximado de 10 ms do roadmap. A causa não foi identificada e a medição não pode ser descartada por ter variado.
- Release: não executado. A tentativa de exportação retornou ausência do template `4.7.2.stable/macos.zip`; a configuração temporária também indicou necessidade de ETC2/ASTC para o preset macOS. Nenhum template foi instalado e nenhuma configuração global foi alterada.
- Os erros de certificados e permissões do editor apareceram no ambiente Codex; não foram atribuídos à lógica da simulação.

## Repetições com aquecimento — editor

Em cada execução: 525.600 passos, 1.000 NPCs fictícios, atualização horária, relógio, agendador e eventos. As durações abaixo são em microssegundos; inicialização e aquecimento de um dia foram medidos fora das cinco amostras. O percentil é calculado sobre todos os passos de cada execução. Os valores de pico incluem possíveis interrupções do sistema operacional.

| Série | Inicialização | Média | p50 | p95 | p99 | p99,9 | Máximo |
|---|---:|---:|---:|---:|---:|---:|---:|
| Editor 1 | 429 | 5,521 | 5 | 6 | 39 | 48 | 386 |
| Editor 2 | 468 | 5,528 | 5 | 6 | 39 | 48 | 248 |
| Editor 3 | 593 | 5,473 | 5 | 6 | 39 | 47 | 374 |
| Editor 4 | 511 | 5,577 | 5 | 6 | 39 | 49 | **24.731** |
| Editor 5 | 429 | 5,837 | 5 | 6 | 40 | 74 | 4.303 |
| Cópia temporária 1 | 412 | 5,583 | 5 | 6 | 39 | 51 | 763 |
| Cópia temporária 2 | 422 | 5,738 | 5 | 6 | 40 | 59 | **29.409** |
| Cópia temporária 3 | 436 | 5,617 | 5 | 6 | 40 | 52 | 561 |
| Cópia temporária 4 | 437 | 5,888 | 5 | 6 | 40 | 55 | **41.939** |
| Cópia temporária 5 | 514 | 5,531 | 5 | 6 | 39 | 48 | 280 |

O aquecimento do projeto principal teve inicialização de 485 µs e pico de 109 µs; na cópia temporária, 458 µs e 61 µs. A cópia difere apenas no ponto de entrada (`Node._ready` em vez de `SceneTree._initialize`) e no encerramento, para permitir exportação.

Picos acima de 10 ms ocorreram em minutos diferentes, inclusive fora da atualização horária dos NPCs; a maior parcela medida ocorreu dentro de `advance_minute`. Isso demonstra variação intermitente, mas não distingue interrupção do sistema de custo interno do código. O pico anterior de 87,746 ms permanece registrado acima e não é descartado. Todas as dez execuções tiveram o mesmo hash `3979f57a6afcbaf6c0206b5df85fb1a619adcb6d6766c29e79de34da9f4fdc56`.

## Release e editor após download

Template macOS 4.7.2 oficial, instalado pelo gerenciador do Godot a partir do pacote cujo SHA-256 é `f298490b8d44d934be425a5a65a51bf15f422428b229a06a6e11d9ffea248011`, conferido com o release oficial. A exportação arm64 isolada falhou por não localizar o binário esperado; preset universal, com ETC2/ASTC na cópia temporária, exportou. O binário confirmou `SP1 modo: release`. A cena principal não foi alterada.

Cada execução abaixo teve 525.600 passos; tempos em microssegundos. A cópia temporária foi medida no editor e no executável exportado; os percentis excluem inicialização e aquecimento. As cinco primeiras execuções release ocorreram após o download; as cinco últimas linhas são uma nova série no editor, também após o download.

| Série | Inicialização | Média | p50 | p95 | p99 | p99,9 | Máximo |
|---|---:|---:|---:|---:|---:|---:|---:|
| Release 1 | 288 | 3,826 | 3 | 4 | 23 | 35 | 468 |
| Release 2 | 315 | 3,760 | 3 | 4 | 23 | 28 | 160 |
| Release 3 | 287 | 3,764 | 3 | 4 | 23 | 29 | 180 |
| Release 4 | 384 | 3,760 | 3 | 4 | 23 | 28 | 300 |
| Release 5 | 289 | 3,781 | 3 | 4 | 23 | 30 | 191 |
| Editor posterior 1 | 411 | 5,556 | 5 | 6 | 39 | 48 | 3.491 |
| Editor posterior 2 | 440 | 5,530 | 5 | 6 | 39 | 47 | 1.327 |
| Editor posterior 3 | 676 | 5,531 | 5 | 6 | 39 | 47 | 277 |
| Editor posterior 4 | 424 | 5,824 | 5 | 6 | 39 | 52 | **36.100** |
| Editor posterior 5 | 456 | 5,500 | 5 | 6 | 39 | 46 | 144 |

No aquecimento release: inicialização 352 µs, média 3,727 µs e pico 30 µs. No aquecimento do editor posterior: inicialização 571 µs, média 5,459 µs e pico 54 µs. Todas as medições usaram MacBook Air M3, Godot 4.7.2 e modo headless; outras atividades da máquina não foram controladas. As cinco execuções release e as cinco do editor posterior produziram o mesmo hash acima.

O pico reapareceu no editor mesmo após o download, inclusive num passo sem atualização horária. Nenhum pico acima de 10 ms ocorreu nas cinco execuções release, mas a origem exata dos picos no editor — código, runtime ou escalonamento do macOS — não foi isolada. A meta de pico do SP1 não está comprovada em ambos os ambientes, e não se declara a LW-023 concluída.
