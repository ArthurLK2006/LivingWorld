11/11/2026 07:44 (Brasília) · PRONTA PARA REVISÃO · LW-087a, rodada 5 e adendo: 2 commits (`acf10ed` e `86d4310`) no ramo `lw-087a-registro-fase-3` empurrados (35 decisões APROVADAS em bloco; `run_sim` corrigido; tecido na manutenção); `check_all` verde; `main` sem mudança (`8dcc81d`); NÃO está no `main`, sem Fase B e sem tag; o Godot da A está parado

# RELATÓRIO — LW-087a, rodada 5 e adendo: aprovação em bloco das 35 decisões do pré-voo, correção do `run_sim` e o tecido na manutenção     Status: PRONTA PARA REVISÃO (rascunho; não está no `main`)

## 1. RESUMO
Registrei a sua aprovação de 11/11/2026: as 35 decisões do pré-voo da Fase 3 (DEC-138 a DEC-141, DEC-145 a DEC-162 e DEC-165 a DEC-177) passaram de PROPOSTA a APROVADA, com a frase pedida e os dois limites (não autoriza editar fixture protegida; não transforma valor [HIP] em requisito). Corrigi o erro do `run_sim` conferindo o código do `main`: ele não registra módulo, então **não muda, nem o hash que ele imprime**; mudam o oráculo e o hash do soak de 30 dias. A recontagem por script **bateu com o esperado** (178 = APROVADA 120, PROPOSTA 29, PENDENTE 18, DESCARTADA 10, SUBSTITUÍDA 1). Só documentos, em **dois** commits no mesmo ramo: a rodada 5 (`acf10ed`) e o adendo (`86d4310`, curto: o tecido na manutenção, trechos antigos do 0012 e a LW-093a e a LW-093b nas divergências). O `main` não andou (`8dcc81d`). Sem Fase B, sem tag.

## Declaração de leitura (início da tarefa)
- **Tarefa:** registrar a aprovação em bloco das 35 decisões e corrigir a frase do `run_sim`, só em `DECISIONS.md`, no roadmap e no `0012`.
- **Li:** o código do `main` (o `tools/` e o `src/` do ramo são idênticos ao `main`): `tools/run_sim.gd`, `src/app/simulation_runner.gd`, `src/app/game_modules.gd`, `src/app/simulation_host.gd` e todas as chamadas de `register_module` em `src/`, `tools/` e `tests/`; o `tests/test_run_sim.sh`; o meu registro, para achar onde ainda se dizia "proposta".
- **Decisões e status:** as 35 estavam PROPOSTA e passam a APROVADA; DEC-142, 143, 144, 163, 164 e 178 já eram APROVADAS (a DEC-163 só ganhou a nota do adendo); as 29 PROPOSTA antigas e a DEC-040 (PENDENTE) ficaram como estavam.

## ANTES e DEPOIS dos totais (recontados por script; índice = cabeçalhos, sem número repetido)

| | APROVADA | (com ressalva) | PROPOSTA | PENDENTE | DESCARTADA | SUBSTITUÍDA | Total |
|---|---|---|---|---|---|---|---|
| **ANTES** (HEAD `28a0227`) | 85 | 20 | 64 | 18 | 10 | 1 | **178** |
| **DEPOIS** (HEAD `acf10ed`) | **120** | 20 | **29** | 18 | 10 | 1 | **178** |

**Bate com o esperado** (178: APROVADA 120, PROPOSTA 29, PENDENTE 18, DESCARTADA 10, SUBSTITUÍDA 1); o script estava programado para parar se desse diferente, e não parou. **O adendo não mudou nenhum status nem linha de índice** (conferido por diff): a recontagem refeita no fim dá os mesmos números. Conta: APROVADA +35, PROPOSTA −35; as ressalvas (20), PENDENTE, DESCARTADA e SUBSTITUÍDA não mudam. Saída do script: `índice=178 cabeçalhos=178 repetidos=nenhum só_no_índice=nenhum só_no_corpo=nenhum · CONFERE`. **Versão do documento: 0.10**, com linha 0.10 no histórico.

## Conferência do `run_sim` no código do `main`
| Evidência | Onde |
|---|---|
| O `run_sim` só cria o runner, inicia e roda; **não chama `register_module`** | `tools/run_sim.gd` linhas 27, 28 e 31 (`SimulationRunner.new`, `start_new_game`, `describe_state`) |
| O hash impresso vem do estado do mundo, sem módulos | `src/app/simulation_runner.gd` linha 128 (`world.state_hash()`) |
| `register_module` em `src/` só existe no `SimulationRunner` (linha 32) e no `GameModules.register` (linhas 31 e 39: `character` e `npc`) | `src/app/simulation_runner.gd`, `src/app/game_modules.gd` |
| O `GameModules.register` só é chamado pelo `SimulationHost` | `src/app/simulation_host.gd` linha 33 |
| O teste de shell compara hashes **entre rodadas** (mesma semente igual; sementes diferentes, distintas), não contra um valor fixo | `tests/test_run_sim.sh` linhas 17 a 22 |

**Conclusão:** registrar a `economy` (LW-088a) ou o `world` (LW-097) no `SimulationHost` não muda o `run_sim` nem o hash que ele imprime. **Não encontrei nada mais que mude por causa disso** (por isso não parei). O que muda: o oráculo (`test_npc_split_oracle`) e o hash do soak de 30 dias.

## Onde cada ponto da sua ordem foi feito
| Ponto | Onde |
|---|---|
| 1. 35 para APROVADA com a frase | `DECISIONS.md`: Status, "Data / versão" e índice das 35 (70 linhas de índice mudaram: 35 removidas, 35 acrescentadas) |
| 2. Não mexer | DEC-142, 143, 144, 163, 164, 178; as 29 PROPOSTA antigas; DEC-040 — **conferido por diff**: nenhuma linha de índice delas mudou nesta rodada |
| 3. Limites escritos | **em cada uma das 35** (Status), na linha 0.10 do histórico, no parágrafo dos totais, na LW-087a do roadmap e no 0012 (10.1) |
| 4. "proposta" → "aprovada" | DEC-167 (Status e Consequências); DEC-133 (aponta a DEC-170); roadmap: LW-087a e LW-097 (`work_place_id`); 0012: cabeçalho, rótulos, seções 5, 7.2, 8, 9.2 e 7.2 (Q23) |
| 5. Versão 0.10 e histórico | `DECISIONS.md` (cabeçalho e tabela de histórico) |
| 6. Recontagem por script | acima |
| 7. `run_sim` | DEC-162, 172 e 175; roadmap: LW-088a (e o relatório mostra o hash do `run_sim` antes e depois, esperado iguais) e nota 3.D; 0012: 5.3, 7.2, 8 e 9. A **LW-097 não dizia nada do `run_sim`**, então não mudou |
| 8. Seção "Rodada 5" | `0012`, seção 10 |
| 9. Fetch e merge | `main` em `8dcc81d`, já dentro do ramo: **nada a juntar** |
| 10. Sem "da A/B/C" nem STATUS | conferido por busca nos três arquivos (as duas ocorrências de "do C" são o povoado C, não um agente) |

## Adendo à rodada 5 (mesma autorização; segundo commit `86d4310`)
| Ponto do adendo | O que fiz | Onde |
|---|---|---|
| 1. DEC-153 e DEC-163: o tecido | **DEC-153** (uma das 35): corrigi a frase ("o tecido é só mercadoria de comércio" virou "ferramenta, tábua e tecido são gastos pelos locais de produção (manutenção, DEC-163 e DEC-178)") e pus a nota "Ampliada pela DEC-178 (10/11/2026): o tecido também é gasto na manutenção dos locais." **DEC-163** (já APROVADA): **só a nota**, a mesma frase; o texto aprovado não foi reescrito | `DECISIONS.md`, célula "Consequências" das duas; "Decisão" da DEC-153 |
| 2. Trechos antigos do 0012 | (a) o tecido na manutenção; (b) `WagesPaid(workplace_id, amount_each)`, com `workplace_id` = `site_id` do local ou `post_id` do posto; (c) marcos por bloco (1 = LW-088a a LW-092; 2 = LW-093 a LW-096a; 3 = LW-097). **Busca por "tecido", "site_id", "marco" e "LW-095":** achei mais **dois** trechos contraditórios e corrigi (seções 5.2 e 7.2: "os locais gastam ferramenta e tábua" ganhou "e, desde a rodada 4, tecido"). Os demais achados são históricos corretos ou já estavam certos | `0012`, seções 5.2, 7.1, 7.2 e 8 |
| 3. LW-093a e LW-093b nas divergências | o parágrafo "Divergências do texto original" citava só a LW-093a (eu tinha escrito "a LW-093a antes dela"); agora diz "a **LW-093a** e a **LW-093b** antes dela (DEC-136 e DEC-137)" | roadmap, parágrafo sob a tabela 3.D |
| 4. Contagem | não muda: **178 = 120 / 29 / 18 / 10 / 1**, recontada por script de novo no fim | acima |
| 5. `check_all` e relatório | `check_all` verde no HEAD final (abaixo); este é o relatório único | — |

## 2. ARQUIVOS CRIADOS
- Nenhum.

## 3. ARQUIVOS MODIFICADOS (rodada 5 e adendo, contra o commit anterior `28a0227`)
- `docs/DECISIONS.md` — +116 −115 (a maior parte é mecânica: Status, "Data / versão" e índice das 35); versão 0.10, totais, histórico, DEC-162, 172 e 175 revistas, DEC-133 e 167; **adendo:** DEC-153 e DEC-163 (+3 −3).
- `docs/DEVELOPMENT_ROADMAP.md` — +5 −5: LW-087a, LW-088a, LW-097 e a nota sob 3.D; **adendo:** o parágrafo de divergências (LW-093a e LW-093b).
- `docs/decisions/0012-pre-voo-da-fase-3.md` — +31 −17: cabeçalho e rótulos, seções 5, 7.2, 8 e 9 e a nova seção 10 "Rodada 5"; **adendo:** 5 trechos antigos corrigidos (+4 −4).
- Não toquei em `docs/backlog.md`, `AGENTS.md`, GDD, arquitetura, `project.godot`, `data/`, `tests/`, `ROADMAP_STATUS.md` nem `README.md`.

## 4. DECISÕES TÉCNICAS
- **Grafia da frase:** escrevi "APROVADA por Arthur em 11/11/2026 (em bloco, pré-voo da Fase 3)", com a palavra de status em maiúsculas, que é a convenção do documento (as outras entradas fazem igual). É a sua frase, só com essa diferença de caixa.
- **Os dois limites foram escritos em cada entrada**, e não só no 0012, para que quem abrir uma entrada isolada veja que a aprovação não abre a pasta protegida nem torna requisito um valor [HIP].
- **A linha 0.9 do histórico não foi reescrita:** ela registra o que a rodada 4 fez, inclusive a frase errada do `run_sim`; a linha 0.10 diz que foi corrigida (histórico não se apaga).
- **Proposta de entrada para `DECISIONS.md` / pedido de desvio:** nenhum.

## 5. TESTES EXECUTADOS
- `git fetch origin '+refs/heads/main:refs/remotes/origin/main'`: `main` em `8dcc81d`; `git merge-base --is-ancestor origin/main HEAD`: já dentro do ramo, **nada a juntar**.
- Script de recontagem (`recount_decisions.py`): antes `178 · CONFERE` e depois `178 · CONFERE`, com os totais acima; o script de aplicação **parava se os totais fossem diferentes do esperado**. Coerência: o status de cada entrada bate com o índice (as 178); as 35 têm a frase e os dois limites; as seis já APROVADAS não receberam a frase de 11/11; toda `DEC-NNN` citada no roadmap e no 0012 existe; a seção 10 do 0012 existe.
- Busca por `STATUS-A/B/C`, `status-a/b/c` e rótulos "da A/B/C": nenhuma citação.
- **`tools/check_all` no HEAD final `86d4310` (07:40:58 a 07:44:23, 11/11/2026): VERDE** (`EXIT_CODE_CHECK_ALL=0`). (A rodada 5 sozinha, no `acf10ed`, também ficou verde às 07:22:22 a 07:25:45: 1.194 de 1.194.)
- **NÃO EXECUTADO:** oráculo, vida de 30 dias e `run_sim` fora do `check_all` (só documentos; o `check_all` já roda o `run_sim` de 30 dias e passou).

## 6. RESULTADOS
- **`check_all` (HEAD final `86d4310`):** 124 scripts, **1.194 testes, 1.194 passando, 0 falhando**, 261.693 asserts, 172,8 s; 313 scripts sem aviso de compilação; nenhum "SCRIPT ERROR" nem "Parse Error".
- **Critério de aceite:** os 12 pontos da sua ordem foram feitos (tabela acima); a recontagem bateu; o `run_sim` foi conferido no código.

## 7. PROBLEMAS ENCONTRADOS
- **O meu erro das rodadas 3 e 4:** eu tinha registrado que o hash que o `run_sim` imprime mudaria; o código mostra que não. Já corrigido nos 7 pontos que você listou e no 0012. A linha 0.9 do histórico guarda a frase antiga de propósito.
- **Uma frase velha do 0012 (seção 7.2, rodada 2)** ainda diz que as DEC-005, 045 e 053 "não foram alteradas"; elas ganharam a nota da DEC-054 na rodada 3. É histórico da rodada 2; não mexi.

## 8. RISCOS
- **A aprovação em bloco não aprova hashes:** os três marcos (DEC-175) continuam exigindo a sua aprovação, e a fixture `save_v1` continua exigindo autorização escrita específica (DEC-172).
- **Valores [HIP] aprovados como decisão não viram requisito:** preço, salário, manutenção, estoque inicial e teto de compra são calibrados na LW-112 e provados no soak da LW-110.
- **A LW-097 segue pesada** (terreno, rotas, 10 locais `work`, `work_place_id`, estoque dos importados, teste de distribuição e o marco 3); a distribuição 14/6/20/10 continua sem entrada própria.

## 9. PENDÊNCIAS
- **Para você decidir (cada uma com a minha recomendação):** (1) aprovar a distribuição 14/6/20/10 (hoje sem entrada) — recomendo uma entrada própria ao preparar a LW-097; (2) dividir a LW-097 — recomendo decidir ao preparar o prompt; (3) mandar o rascunho da LW-087a para o `main` (Fase B) — **não autorizada**; recomendo quando B e C tiverem alinhado os contratos às decisões.
- **Teste manual:** nenhum (só texto).

## ACOMPANHAMENTO
- **Avanço:** a LW-087a é a primeira parte da LW-087; a Fase 3 não começou (contagens do status inalteradas; a linha de status e o `README` só entram na Fase B).
- **Próxima tarefa recomendada:** a sua revisão da rodada 5 e, se aprovada, a Fase B da LW-087a; depois a LW-087b, 087c e 087d. **Não iniciada.**
- **Decisões que dependem de você:** as três acima.
- **Git:** **dois** commits no ramo `lw-087a-registro-fase-3`: `acf10ed` ("LW-087a: registra a aprovação das 35 decisões do pré-voo e corrige o run_sim") e `86d4310` (o adendo); empurrados **só** esse ramo e o `status-a`; nada no `main`, nenhuma tag, sem `--force`.
