10/11/2026 18:07 (Brasília) — rodando: LW-085f (check_all no HEAD final do ramo lw-085f-correcoes-da-085c, só documentos); o relatório abaixo é o da LW-084 e da LW-085c e será substituído ao parar

# RELATÓRIO — LW-085c: custo do painel de NPC com 300 NPCs     Status: PRONTA PARA REVISÃO (já no `main`, pela Fase B automática)

## 1. RESUMO
O painel de depuração de NPC custa, com 300 NPCs e 30 dias de jogo, **cerca de 37 a 39 ms por segundo** (3,7% a 3,9% do tempo) enquanto está aberto, em build de depuração. A maior parte é o resumo do mundo, que o painel pede a cada ~1 s e que chama `world.validate()`: **19 a 22 ms por chamada** (eram 3,9 ms com 1 dia de jogo). A lista de 300 NPCs com um NPC selecionado, refeita a cada 0,25 s, custa só **4,1 a 4,4 ms** (3,5 ms no teste rápido, com 1 dia de jogo). No quadro em que as duas atualizações caem juntas (uma vez por segundo, quando o resumo dispara junto com a lista), o custo típico é de ~24 ms, acima dos 16,7 ms de um quadro de 60 por segundo. O painel só existe em build de desenvolvimento, então o release não é afetado. Só medi e relatei; nada em `src/`.

## 2. ARQUIVOS CRIADOS (commit `5a94c32`)
- `tests/soak/npc_panel/soak_npc_panel_cost.gd` (+ `.uid`) — o script de medição (98 linhas, 78 de código)
- `tests/soak/run_npc_panel_cost` — script de terminal (11 linhas, 8 de código; `LW_PANEL_DAYS` muda os dias de aquecimento, padrão 30)
- Total: 86 linhas de código (alvo 70 a 90; teto 1,5×).

## 3. ARQUIVOS MODIFICADOS
- `tests/soak/npc_year/npc_year_meter.gd` — +5 −4 linhas: `scaled_setup` ficou público e ganhou o parâmetro `development_build` (o mesmo mundo ×3 da LW-084). Nenhum teste mexido; `test_npc_year_short.gd` segue verde.
- `docs/ROADMAP_STATUS.md` — +1 linha (a da LW-085c, de subtarefa; a contagem não muda).
- Nenhum arquivo protegido; nada em `src/` nem em `data/`.

## 4. DECISÕES TÉCNICAS
- Medi o **painel real** (`NpcInspectorPanel` com a ponte, os textos e os nós), não só a ponte: `panel.refresh()` (lista + detalhe, rastro, memórias e relações do selecionado) e `panel.refresh_summary()`; mais `world.validate()` e `peek_simulation_summary` separados, para ver quem pesa.
- Mundo: o da LW-084 (300 NPCs, 40 notáveis), montado em build de desenvolvimento como no teste do painel, com **30 dias de jogo** de aquecimento: o notável mais cheio já estava com 40 registros (24 memórias + 16 relações, os tetos) e o custo do detalhe é o pior caso.
- Intervalos lidos do próprio painel (`REFRESH_INTERVAL_S` 0,25 e `SUMMARY_INTERVAL_S` 1,0), não copiados. Só imprime; **não reprova por tempo**. Não editei o README (a ordem era só o script).
- **Proposta para a LW-085 (decisão sua):** manter a lista a 4 Hz (custa ~4,4 ms) e **mudar o resumo de 1 s para ~5 s [HIP]**, ou rodar o `validate()` só sob demanda (uma tecla); isso tira ~16 ms por segundo e acaba com o quadro de ~24 ms a cada segundo. Não otimizei nada (AGENTS 4.18: a medição é para decidir).

## 5. TESTES EXECUTADOS
- `tools/check_gdscript_warnings`: sem avisos (313 scripts). Teste rápido `LW_PANEL_DAYS=1 tests/soak/run_npc_panel_cost`: 1/1 passou.
- Medição: `tests/soak/run_npc_panel_cost` ×3 com 30 dias, de 16:13 a 16:18, Mac na tomada; o vigia só viu os 3 godot meus (nenhum outro).
- `tools/check_all` no HEAD final (`d1b0fa2`): **VERDE**, 124 scripts, 1194 testes, 261.693 asserts, 0 avisos novos, 220,8 s. O soak de custo não entra (não começa com `test_`).
- Contra o `main` (`1dd2fb4`, em worktree separado): oráculo do `npc` passa nos dois e o arquivo é idêntico; soak de 30 dias `d13b921112ce` ×3 nos dois; `run_sim --days 7` sementes 1, 2 e 3 iguais.
- Fase B: B0 `main` em `1dd2fb4` (30 de 32, 85 de 192); B1 sem conflito (o `main` não andou; sem junção); B3 contagem por `grep` antes e depois: "30 de 32" ×3 e "85 de 192" ×3, sem mudança; B4 avanço rápido `1dd2fb4..d1b0fa2`; nenhum arquivo protegido; nenhum teste removido, enfraquecido ou pulado.

## 6. RESULTADOS (depuração, 300 NPCs, 30 dias de jogo; média / p99 / máximo, em µs)
| | exec. 1 | exec. 2 | exec. 3 |
|---|---|---|---|
| `world.validate()` | 19.859 / 34.843 / 72.603 | 19.265 / 20.205 / 21.269 | 20.017 / 28.012 / 66.021 |
| `peek_simulation_summary` (ponte) | 20.884 / 49.182 / 71.081 | 19.878 / 26.940 / 96.515 | 22.281 / 79.239 / 241.490 |
| `refresh_summary` (painel) | 21.173 / 42.872 / 149.018 | 19.411 / 21.491 / 22.118 | 20.121 / 31.113 / 32.482 |
| `refresh`, notável selecionado | 4.429 / 4.985 / 5.386 | 4.423 / 5.858 / 8.201 | 4.367 / 4.728 / 4.829 |
| `refresh`, cidadão selecionado | 4.449 / 9.131 / 9.949 | 4.053 / 4.303 / 4.843 | 4.187 / 8.110 / 9.869 |
| custo por segundo, painel aberto | 38,9 ms (3,9%) | 37,1 ms (3,7%) | 37,6 ms (3,8%) |

- O `validate()` é ~95% do resumo. O resumo + a lista no mesmo quadro: ~24 a 26 ms em média (147% a 154% do quadro de 16,7 ms; 72% a 78% do teto de 33 ms da régua de quadro do SP2/DEC-119); com o p99, 26 a 52 ms.
- **O `validate()` cresce com o tempo de jogo:** 3,9 ms com 1 dia (teste rápido) e 19 a 20 ms com 30 dias. Como o notável mais cheio já estava no teto de registros no dia 30, espero que pare de crescer, mas **não medi com 1 ano**.
- Os máximos altos (149 ms, 241 ms) aparecem uma vez por execução e não se repetem: indício de ruído da máquina, não prova.

## 7. PROBLEMAS ENCONTRADOS
- **Erro meu, já no `main`:** a linha da LW-085c no `ROADMAP_STATUS.md` diz que o `refresh` da lista custa "de 3,5 a 4,4 ms" nas 3 execuções; nas 3 execuções de 30 dias foi de 4,1 a 4,4 ms (os 3,5 ms são do teste rápido, de 1 dia). O custo por segundo e o resto da linha estão certos. Conserto proposto (1 linha de documento, que não empurrei sem a sua ordem): trocar "de 3,5 a 4,4 ms" por "de 4,1 a 4,4 ms" naquela linha.
- Nada mais falhou. O `world.validate()` ser caro (e o painel chamá-lo a cada segundo) era a dúvida do achado I-3 e foi confirmada: o próprio status da LW-082 dizia que o custo "não foi verificado".

## 8. RISCOS
- Medido em depuração, sem janela: o painel desenhado na tela (texto, lista) custa mais do que os nós sem desenho. O custo com 1 ano de jogo não foi medido. O painel só roda em build de desenvolvimento (não afeta o release nem a medição de quadros da LW-053A).

## 9. PENDÊNCIAS
- **Decisão que depende de Arthur (para a LW-085):** reduzir o ritmo do resumo do painel (recomendo 1 s → ~5 s [HIP], ou `validate()` só sob demanda). Se quiser o número com 1 ano de jogo antes de decidir, rodo `LW_PANEL_DAYS=360 tests/soak/run_npc_panel_cost` (~25 min).
- Testes manuais: nenhum.

## ACOMPANHAMENTO
- Avanço: LW-084 e LW-085c no `main`; Fase 2 em 30 de 32 (a LW-085 e o que falta são de vocês). Próxima tarefa recomendada: nenhuma minha (parei na regra 13).
- Git: `main` = `d1b0fa2`; ramos `lw-085c-custo-do-painel` e os da LW-084 mantidos no remoto; sem tag; worktrees `lw-084a`, `lw-084b`, `lw-084c`, `lw-085c`, `ref-main` e `status-b` mantidos em `.worktrees/`. Este ramo (`status-b`) nunca vai para o `main`.

---

# RELATÓRIO — LW-084: Soak longo (300 NPCs por 1 ano, com alternância S1 ↔ S0)     Status: PRONTA PARA REVISÃO (já no `main`, pela Fase B automática)

## 1. RESUMO
O soak de 1 ano com 300 NPCs [HIP] roda limpo. Em 8 execuções de 1 ano (depuração: 1 pré-medição, 4 do padrão `base`, 3 do `stress`) e 3 de 30 dias em release: **300 vivos o tempo todo, zero mortes, zero erro de `validate()`, zero erro de script e o mesmo hash dentro de cada padrão** (inclusive salvando e carregando no meio). O passo médio fica em 1,75 a 2,66 ms (régua [HIP] de ~3 ms); os passos acima de 10 ms existem, mas pela sua decisão são só informativos. A memória cresce ~1,9 MiB só nos primeiros 30 dias e fica plana; o save fica em ~20 KiB comprimido, estável. Entrou no `main` com status +1 (conferido por `grep`): Fase 2 em **30 de 32** e projeto em **85 de 192**.

## 2. ARQUIVOS CRIADOS
- **084a** (`63c0f0a`): `tests/soak/npc_year/npc_year_meter.gd` (o medidor), `test_npc_year_short.gd` (1 dia, no `check_all`, 4 testes), `soak_npc_year.gd` (o ano, fora do `check_all`) e `tests/soak/run_npc_year`.
- **084c** (`629aa40`): `tests/soak/npc_year/npc_year_release_node.gd` e `npc_year_release_main.tscn`, e `tests/soak/run_npc_year_release`.
- **084b** (`872d846`): `docs/decisions/0010-soak-longo-300-npcs.md`.
- (mais os `.uid` dos scripts novos)

## 3. ARQUIVOS MODIFICADOS
- `tests/soak/README.md` — +14 linhas (084a) e +9 (084b: parágrafo do release, com o texto aprovado por você).
- `tests/soak/npc_year/npc_year_meter.gd` e `test_npc_year_short.gd` — na 084b: +37 e +3 linhas (contagem de memórias, traços e relações dos notáveis; save sem comprimir). O medidor ficou com **330 linhas** (acima de ~300): linha no backlog para dividir.
- `docs/backlog.md` — +4 linhas (ano em release; dividir o medidor; laço de controle intercalado; notáveis no teto de memórias).
- `docs/ROADMAP_STATUS.md` (+linhas da LW-084, 084a, 084b e 084c; contagens) e `README.md` (contagens e uma frase): só na Fase B.
- Tamanhos: 084a = 349 linhas de código e teste (estimativa 250, teto 375); 084c = 132 (estimativa 120, teto 180).
- Nenhum arquivo protegido; nada em `data/`, `src/` nem em `project.godot`; nenhum teste removido, enfraquecido ou pulado (o ramo só acrescenta em `tests/`).

## 4. DECISÕES TÉCNICAS
- Seguiram as suas respostas: os 300 e o ×3 nascem no código do teste e são [HIP] (DEC-040 PENDENTE); régua de tempo [HIP] (DEC-071 PROPOSTA); o que reprova é só morte, `validate()`, erro de script ou hash diferente entre execuções; a régua dos picos é release com a taxa do controle (DEC-113 como proposta de trabalho), depuração informativa.
- **Download não feito:** o binário de release do Godot 4.7.2 já estava em `$HOME/lw-release-probe/bin` e os modelos de macOS oficiais já estão instalados; comparados sem a assinatura, o slice x86_64 é idêntico e o arm64 difere em 2 bytes do cabeçalho. Não reconferi o SHA-512 do pacote de 1,28 GB (não o baixei).
- **Conflito evitado na Fase B (aviso):** a junção com o `main` teria conflitado em `docs/backlog.md` (os dois lados acrescentaram linhas no fim). A sua regra só tolera conflito em `ROADMAP_STATUS.md` ou `README.md`; em vez de resolver à mão, movi as minhas 4 linhas do fim para o meio do arquivo num commit seguinte (`b97d03f`, mesmo texto, outro lugar) e a junção ficou limpa. Se preferia que eu tivesse parado, diga.
- Salvar e carregar só dá o mesmo hash com o foco longe (o save não guarda corpos): o teste e o soak salvam nesse momento. Com NPCs em S0 no instante do salvamento o hash seria outro; não medi em escala.
- Memória: constante [HIP] de 2 MiB por dia na versão curta (medição: +0,29 MiB em 1 dia). **Proposta de régua definitiva [HIP]** (a decidir por você): crescimento da memória estática entre o dia 30 e o dia 360 de no máximo **0,5 MiB** (observado: 0 a 0,1 MiB; oscilação máxima no meio do ano, 0,4 MiB).
- Não propus entrada nova para o `DECISIONS.md`.

## 5. TESTES EXECUTADOS
- `tools/check_all` no HEAD juntado (`5173282`) e no HEAD final (`1dd2fb4`): **VERDE nos dois**, 124 scripts, **1194 testes**, 261.693 asserts, 0 avisos do GDScript (o "Warnings 1 / Deprecated 1" do GUT já existia), 203 a 210 s. Antes da série: 112 scripts e 1121 testes.
- **Comparação com o `main` (`8b910f1`), em worktree separado:** oráculo do `npc` (`test_npc_split_oracle`) passa nos dois e o arquivo é idêntico; soak de 30 dias `tests/soak/run_npc_life_30d`: hash `d13b921112ce` nas 3 execuções dos dois; `tools/run_sim --days 7`: sementes 1, 2 e 3 iguais (`a0c13ca0…`, `00101d8c…`, `d4ca1885…`).
- Ano ×3 do `base` (13:25 a 14:28, nenhum outro Godot): `RUNS=3 tests/soak/run_npc_year base`, VERDE; ano ×3 do `stress` e a execução extra do `base`: VERDE (com ruído de outros Godot, como combinado); pré-medição e release de 30 dias: números abaixo.
- Git na Fase B: B0 `main` em `8b910f1` (29 de 32, 84 de 192); B1 junção limpa; B2 acima; B3 contagem por `grep` (antes: "29 de 32" e "84 de 192" 3 vezes cada, no README e no status; depois: "30 de 32" e "85 de 192" 3 vezes cada, e a lista do cabeçalho tem 30 IDs); B4 avanço rápido `8b910f1..1dd2fb4`.

## 6. RESULTADOS
| 1 ano, depuração | hash | média | p99,9 | máximo | > 10 ms | parede |
|---|---|---|---|---|---|---|
| pré-medição `base` (sem a LW-073; ruído) | `5141d7e7a84b` | 2344 µs | 12.306 | 208.954 | 723 | 20,9 min |
| `base` 1, 2, 3 (nenhum outro Godot) | `5141d7e7a84b` ×3 | 2358, 2358, 2403 | 12.701, 11.207, 13.837 | 206.453, 276.270, 292.911 | 785, 625, 844 | 21,0 a 21,4 min |
| `base` 4 (extra, com notáveis; ruído) | `5141d7e7a84b` | 2316 | 9.208 | 751.912 | 447 | 20,6 min |
| `stress` 1, 2, 3 (ruído) | `50af223b6f51` ×3 | 2389, 2661, 2417 | 13.163, 25.003, 10.567 | 238.610, 372.890, 672.018 | 812, 2062, 571 | 21,2 a 23,6 min |

Em todas: 300 vivos, **0 mortes**, 0 problemas de `validate()`. A 3ª de cada padrão salva e carrega no dia 180 e dá o mesmo hash. O hash do `base` é o mesmo da pré-medição (sem a LW-073): o detector não mudou o ano.

**Release, 30 dias, `base`, 3 execuções** (nenhum outro Godot; carga do Mac 3 a 5,6): hash `28cfa2f2b844` ×3; média 1752, 1871 e 1783 µs; passos acima de 10 ms: 3, 106 e 12, contra 0, 18 e 23 do laço de controle (**inconclusivo**: o controle roda depois da simulação e não vê a mesma perturbação; nenhum pico caiu nos 5 min depois de uma troca de foco). O release é ~20% mais rápido que a depuração e dá o mesmo hash. **A memória estática vem 0 em release** (só os objetos valem). Ano em release: não feito (decisão sua; backlog).

**Para a revisão LW-085 (o que você pediu):**
- **Notáveis no fim do ano (40, mín/média/máx):** `stress`: memórias **24/24,0/24** (todos no teto `memory_capacity` 24), traços **0/0,0/0** (o limiar de 80 nunca é atingido), relações **10/14,7/16** (teto 16). `base`: memórias **24/24,0/24**, traços **0/0,0/0**, relações **8/14,6/16**.
- **Crescimento da memória:** +1,83 a +1,92 MiB nas 7 execuções de 1 ano em depuração, **todo nos primeiros 30 dias**; do dia 30 ao 360, 0 a 0,1 MiB. Objetos: entre 4.175 e 4.226 do dia 30 ao 360.
- **Save:** comprimido (gzip) 19,6 a 20,4 KiB; sem comprimir 338 a 345 KiB; **estáveis** do dia 30 ao 360 (variação de até 3%).
- **Corpos (falsos):** pico 50, média 33,3; entradas em S0: 103.819 (`base`) e 676.741 (`stress`).
- **O que o SP2 já mostrou (`docs/decisions/0009`):** com corpos reais, zero duplicados, órfãos e teleportes; cerca de 0,13 a 0,17 ms por quadro de física com 100 corpos; na medição oficial, 6 quadros acima de 33 ms em 50.549 (fora da régua da DEC-119 em 3 de 13 ensaios; a causa dos trancos ficou aberta para a LW-072); a navegação N1 (reta) passa nas rotas da rotina e atravessa pedra; toda caminhada em S0 chega atrasada em relação ao S1 (o S1 planeja ~67 m/s). O soak da LW-084 **não** mede nada disso (corpo falso).

## 7. PROBLEMAS ENCONTRADOS
- O Mac é compartilhado: as execuções do `stress`, a extra do `base` e a pré-medição tiveram outros Godot por perto (rótulo "ruído"); houve passos de até 752 ms. Como a simulação é idêntica entre execuções (mesmo hash) e o passo mais lento cai em minutos diferentes a cada vez, o indício é de máquina, não de passo caro do código; **não é prova**.
- O primeiro rascunho do soak tinha um parâmetro que sombreava `Node.name` (aviso do GDScript): corrigido antes do commit.
- O monitor de memória estática não existe em release.

## 8. RISCOS
- Corpo falso e foco que "teletransporta": o custo de S0 medido é o do protocolo e do LOD, não de física, navegação ou desenho. A conversa do jogador fora do soak.
- 300 NPCs é [HIP] (DEC-040 PENDENTE); a régua de ~10 ms não separa ruído de código com o laço de controle atual.
- Os 40 notáveis saturam as memórias em 1 ano: se a LW-085 quiser memória que não sature, os tetos e o limiar de traços (80) precisam de decisão.

## 9. PENDÊNCIAS
- **Decisões que dependem de Arthur:** (1) a régua definitiva de memória (0,5 MiB entre o dia 30 e o 360?); (2) o conflito de `backlog.md` evitado em vez de resolvido (seção 4); (3) o ano em release e o controle intercalado, só se a LW-085 pedir.
- Testes manuais: nenhum (a LW-084 não muda o jogo).
- **Próxima: LW-085c** (custo do painel de NPC com 300 NPCs). A primeira linha de `STATUS-A.md` e de `STATUS-C.md` não tem "rodando" e não há outro Godot agora; começo pelo script (sem Godot) e só rodo Godot com essa condição, marcando "rodando" aqui.

## ACOMPANHAMENTO
- Avanço: LW-084 concluída e no `main`; Fase 2 em 30 de 32.
- Git: `main` = `1dd2fb4` (084a `63c0f0a`, 084c `629aa40` + junção `b12f54b`, 084b `872d846`, `b97d03f`, junção `5173282`, status `1dd2fb4`); ramos `lw-084a-medidor-soak-ano`, `lw-084c-medicao-release` e `lw-084b-registro-do-ano` mantidos no remoto; sem tag; este ramo (`status-b`) nunca vai para o `main`.
