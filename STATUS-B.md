10/11/2026 13:27 (Brasília) — CONCLUÍDA: LW-084a, pré-medição e LW-084c; a 084b está rodando (ano ×3, padrão base, depuração)

# RELATÓRIO — LW-084a (medidor), pré-medição de 1 ano e LW-084c (release)     Status: PRONTA PARA REVISÃO

## 1. RESUMO
O medidor do soak longo existe e funciona: 300 NPCs [HIP] nascem no código do teste (capacidade e população ×3 em memória, `data/` intocado), 40 viram T2, o foco do ator alterna entre A, B e longe (corpos S1 ↔ S0) e um corpo falso cumpre o protocolo dos Intents. Uma versão de 1 dia entra no `check_all`; o ano roda fora dele (`tests/soak/run_npc_year`). A pré-medição de 1 ano (depuração, base, direta) rodou limpa: **300 vivos o tempo todo, zero mortes, zero erro de `validate()`**. A 084c mede o mesmo soak no binário de release com laço de controle; em 30 dias o hash foi idêntico nas 3 execuções e o passo médio ficou em 1,75 a 1,87 ms. Os passos acima de 10 ms existem, mas o laço de controle também os tem; o resultado é inconclusivo (seção 6).

## 2. ARQUIVOS CRIADOS
084a (ramo `lw-084a-medidor-soak-ano`, commit `63c0f0a`, 8 arquivos com 3 `.uid`):
- `tests/soak/npc_year/npc_year_meter.gd` — o medidor (`NpcYearMeter`: `Config`, `Report`, `run`); 297 linhas
- `tests/soak/npc_year/test_npc_year_short.gd` — versão curta (1 dia), roda no `check_all`; 4 testes
- `tests/soak/npc_year/soak_npc_year.gd` — versão longa (fora do `check_all`; parâmetros por variável de ambiente)
- `tests/soak/run_npc_year` — script de terminal (`base` ou `stress`; `DAYS`, `RUNS`, `LOG`)
084c (ramo `lw-084c-medicao-release`, commit `629aa40` + junção com o main `b12f54b`, 4 arquivos com 1 `.uid`):
- `tests/soak/npc_year/npc_year_release_node.gd` e `npc_year_release_main.tscn` — cena principal do release (passos, controle, onde caem os picos)
- `tests/soak/run_npc_year_release` — script de terminal (cópia do projeto com a cena trocada só na cópia, `.pck`, binário de release)

## 3. ARQUIVOS MODIFICADOS
- `tests/soak/README.md` — +14 linhas (parágrafo do soak longo, 084a). **A 084c não editou o README** (a ordem dizia "só arquivos novos"): proposta de parágrafo na seção 9.
- Tamanho: 084a = 349 linhas de código e teste (estimativa 250, teto 375); 084c = 132 (estimativa 120, teto 180). Contagem sem comentários, linhas em branco e `.uid`.

## 4. DECISÕES TÉCNICAS
- Os 300 NPCs e o ×3 são constantes nomeadas **[HIP]** (`SCALE`; DEC-040 PENDENTE). A régua de ~3 ms (média) e ~10 ms (pico) é **[HIP]** (DEC-071 é PROPOSTA) e só aparece nos números, não em asserção.
- Mortes são só registradas. Reprova só: erro de `validate()` (mundo e `npc`, ao fim de cada dia), erro de script ou hash diferente entre execuções (decisão 3 de Arthur).
- Memória na versão curta: constante **[HIP] de 2 MiB por dia**, justificada pela medição (+1,71 MiB em 7 dias e +1,89 MiB em 30 dias na etapa 1; +0,29 MiB em 1 dia dentro do GUT). A régua definitiva de "sem crescimento" só depois da 1ª medição de 1 ano: ver seção 6, que já traz um ano.
- O hash depois de salvar e carregar só é igual ao da execução direta se o foco estiver longe (o save não guarda corpos): o teste e o soak salvam em minuto de foco longe (1200 no dia, ou na virada do dia). Medi: o hash fica idêntico.
- Padrão de alternância é parâmetro: `base` (480 min) e `stress` (30 min). A conversa do jogador não entra.
- **Download não feito.** O binário de release do Godot 4.7.2 já estava em `$HOME/lw-release-probe/bin` (extraído em 07/11 pelo script que baixa e confere o SHA-512 oficial) e os modelos de macOS oficiais já estão em `~/Library/Application Support/Godot/export_templates/4.7.2.stable`. Comparei os dois sem a assinatura: slice x86_64 idêntico, arm64 difere em 2 bytes do cabeçalho (assinatura). Não reconferi o SHA-512 do pacote de 1,28 GB (não o baixei). Fonte/versão/pasta: Godot 4.7.2-stable oficial, `$HOME/lw-release-probe/bin/godot_macos_release.universal`.
- A 084c grava só em `$HOME/lw-release-probe/npc_year/<data-hora>` (subpasta nova da pasta de medições que já existia); não apaga nada.
- A régua da DEC-113 (release, 3 execuções, laço de controle) foi usada como **proposta de trabalho**: a DEC-113 vale só para a LW-023.

## 5. TESTES EXECUTADOS
- `tools/check_all` antes (main `81cc192`): 192,7 s no total (GUT 152,8 s), 112 scripts, 1121 testes, VERDE.
- `tools/check_all` com a 084a: 183,5 s (GUT 152,7 s), 113 scripts, **1125 testes**, 260.076 asserts, VERDE, 0 avisos do GDScript (o "Warnings 1 / Deprecated 1" do GUT já existia antes). **Lentidão:** o teste curto sozinho leva 12,9 s; o esperado é +13 s no `check_all` (≈ +7%), mas o total medido não mostrou aumento (diferença dentro do ruído: o Mac é compartilhado, com outro `check_all` rodando ao lado).
- `tools/check_all` na 084c depois de juntar o main (com a LW-073): 208,3 s, 122 scripts, **1184 testes**, 261.543 asserts, VERDE.
- `DAYS=2 RUNS=3 tests/soak/run_npc_year base`: VERDE; hash `280b928e9c01` igual nas 3 (direta, repetida, salvar e carregar no dia 1). O mesmo hash saiu no release.
- Pré-medição e medição de release: abaixo.

## 6. RESULTADOS
**Pré-medição de 1 ano (rótulo: pré-medição; depuração, padrão base, execução direta, 300 NPCs; sem a LW-073 no código; outro `check_all` rodava no começo e a carga do Mac era ~4; 12:43 a 13:04, 20,9 min de parede):**
- passo: média 2344 µs · p99,9 12.306 µs · máximo 208.954 µs (passo 398.130) · acima de 3 ms: 119.787 (23%) · acima de 10 ms: 723 (0,14%)
- memória estática: 62,5 MiB no começo, 64,4 MiB no dia 30 e **64,4 MiB até o dia 360** (crescimento 1,89 MiB, todo nos primeiros 30 dias); objetos 2833 no começo e 4175 a 4196 do dia 30 ao 360 (estável)
- save comprimido: 19,7 a 20,4 KiB a cada 30 dias (estável)
- vivos 300 o tempo todo, **mortos 0**, problemas de `validate()` 0; corpos: pico 50, média 33,3, 103.819 entradas em S0; hash `5141d7e7a84b`

**084c, release, 30 dias, base, 3 execuções, laço de controle (13:15 a 13:23; nenhum processo Godot de outra sessão durante as execuções; a carga do Mac subiu de 2,9 para 5,6 com processos que não são Godot):**

| Exec. | média | p99,9 | máximo | > 3 ms | > 10 ms | controle > 10 ms |
|---|---|---|---|---|---|---|
| 1 | 1752 µs | 4663 | 20.998 | 2171 | 3 | 0 |
| 2 | 1871 µs | 15.800 | 122.987 | 3399 | 106 | 18 |
| 3 | 1783 µs | 5812 | 63.068 | 2508 | 12 | 23 |

- Hash `28cfa2f2b844` **idêntico nas 3**; mortos 0; problemas 0; corpos: pico 50.
- O release é cerca de 20% mais rápido que a depuração (média 1,75 a 1,87 ms contra 2,1 a 2,3 ms) e dá o mesmo hash que ela.
- **Passos acima de 10 ms: nenhum caiu nos 5 minutos depois de uma troca de foco** (a troca do ator entre povoados não é a causa). Na execução 2 os picos se agrupam (passos 35.655 a 36.353), e o controle também teve 18: sinal de perturbação da máquina nessa janela.
- Taxa acumulada de passos acima de 10 ms: simulação 31 por minuto de execução contínua; controle 10,5. Pela regra de trabalho (taxa do controle + 1 por minuto) **não passa**, puxada pela execução 2; mas o controle roda depois da simulação, não junto, então não vê a mesma perturbação. **Inconclusivo**: não afirmo que é a máquina nem que é o código.
- **Memória estática sempre 0,0 MiB em release** (o monitor só existe no build de depuração). Em release só os objetos valem (2343 no começo, 3689 no dia 30).
- **Ano em release não rodado:** com o laço de controle cada execução leva ~30 min (15 min de simulação + 15 de controle), acima dos ~20 min da ordem.

## 7. PROBLEMAS ENCONTRADOS
- O Mac é compartilhado: sessões de Arthur rodam `check_all` e as medições sofrem. Na pré-medição e no teste curto isso já apareceu (um passo de 74 ms numa execução com salvar e carregar que não se repetiu na seguinte).
- Aviso de GDScript no primeiro rascunho (parâmetro `name` sombreando `Node.name`): corrigido antes do commit.
- O rótulo do tamanho do save: ele é **comprimido** (gzip); o README e o resumo dizem isso.

## 8. RISCOS
- O critério "nenhum passo acima de ~10 ms" é sensível a ruído no Mac; o laço de controle sequencial não separa ruído de código nesses casos. Quem decide a régua é Arthur (seção 9).
- O corpo é falso e o ator "teletransporta" entre os povoados (o jogo real anda): o custo medido de S0 é o do protocolo e do LOD, não o de física, navegação ou desenho.
- A conversa do jogador fica fora do soak (decisão 6).
- 300 NPCs é [HIP] (DEC-040 PENDENTE).

## 9. PENDÊNCIAS
- **084b** (ano ×3 nos dois padrões, depuração) em andamento; depois, registro em `docs/decisions/0010-soak-longo-300-npcs.md`, README do soak e backlog, e a Fase B só se tudo ficar limpo (regra do item 4).
- Decisões que dependem de Arthur, com recomendação:
  1. **Qual build e qual régua decidem os picos de ~10 ms da LW-084?** Recomendo release com a taxa do controle (DEC-113 estendida à LW-084) e a depuração só informativa.
  2. **O ano em release (3 execuções)?** Recomendo só depois da 084b, sem laço de controle (cerca de 15 min por execução) ou com o controle limitado a 30 dias de passos, e só se a pergunta 1 exigir.
  3. **Parágrafo do README para o `run_npc_year_release`** (não editei, por causa de "só arquivos novos"): "`run_npc_year_release [base|stress]` mede o mesmo soak no binário de **release** (3 execuções, laço de controle em cada uma; reaproveita o binário de `$HOME/lw-release-probe/bin`, grava em `$HOME/lw-release-probe/npc_year/<data-hora>`; Mac na tomada). Em release a memória estática não existe (sai 0); só os objetos valem."
- Testes manuais para Arthur: nenhum (a LW-084 não muda o jogo).

## ACOMPANHAMENTO
- Avanço: 084a e 084c concluídas; 084b em execução; Fase B depois dela.
- Próxima tarefa: 084b (liberada: o main já mostra a LW-073, 29 de 32 e 84 de 192).
- Git: `lw-084a-medidor-soak-ano` `63c0f0a`; `lw-084c-medicao-release` `b12f54b` (junção do main `5e8f8b4`); ambos só no remoto, nada no main. Pasta de saídas do release: `$HOME/lw-release-probe/npc_year/20261110-131503`.
