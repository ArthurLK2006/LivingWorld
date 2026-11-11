11/11/2026 08:46 (Brasília) — CONCLUÍDA: rodada 5 da LW-087b e da LW-087d, **com a junção com o `main` (`63caee7`) autorizada por Arthur**: ramos em `f384597` (087b) e `1ea4590` (087d); `check_all` verde nos dois HEADs pós-junção; rótulos pelo status das DEC (35 aprovadas em 11/11/2026), frase do `run_sim` corrigida; PRONTAS PARA REVISÃO como RASCUNHO fora do `main`; parei (regra 13)

# RELATÓRIO — LW-087b e LW-087d, RODADA 5 (DOC): decisões aprovadas por Arthur em 11/11 e frase do `run_sim`     Status: PRONTA PARA REVISÃO, **RASCUNHO (não está no `main`)**

**Antes de começar (AGENTS 2.3), em palavras simples.** Li: o `AGENTS.md` v0.4; os meus três arquivos como estavam em `16ddf1b` e `99dd70c`; o `DECISIONS.md` do registro da LW-087a **no início** (HEAD `acf10ed`) **e no fim** (HEAD `63caee7`, que **já é o `main`**; o arquivo é o mesmo de `86d4310`, sem mudança de status entre as duas leituras); e, no `main`, o `tools/run_sim.gd`, o `SimulationRunner` e as chamadas de `register_module`. DEC de que depende, com o status do registro: **as 35 que você aprovou em bloco em 11/11/2026** (DEC-138 a 141, 145 a 162 e 165 a 177: todas "APROVADA por Arthur em 11/11/2026" no início e no fim); **APROVADAS em 10/11/2026**: DEC-129 a 137, 142 a 144, 163, 164 e 178, e DEC-047, 049 e 054 (antes PROPOSTA); DEC-048 segue PROPOSTA e DEC-040 PENDENTE. Arquivos: `economy.md` (ramo 087b) e `dados.md` e `events.md` (ramo 087d). Dúvidas: nenhuma que bloqueasse.

## 1. RESUMO
Troquei os rótulos "decidido pelo revisor" e "[PROPOSTA]" pelo status do registro: onde a DEC é uma das 35, o texto diz **"aprovada por Arthur em 11/11/2026 (DEC-NNN)"**; onde já era APROVADA antes, mantive 10/11/2026; o que **não tem DEC** ficou [PROPOSTA] e ganhou uma lista própria na seção 15. Corrigi a frase do `run_sim` (ele não registra módulo, então o hash que ele imprime **também não muda**), troquei o "Estado" para rodada 5 e reescrevi a abertura da seção 16 sem ramo nem agente. **Não mexi em número, conta nem plano B do tecido.** Só documentos.

## 2. ARQUIVOS CRIADOS
Nenhum.

## 3. ARQUIVOS MODIFICADOS
- **Ramo `lw-087b-contrato-economy`** (`1583db9`, 1 commit): `docs/modules/economy.md` (+79 −70; 333 linhas).
- **Ramo `lw-087d-eventos-e-dados`** (`ae3125b`, 1 commit): `docs/economy/dados.md` (+13 −13; 298 linhas) e `docs/events.md` (+2 −2; 28 linhas). Catálogo de eventos: **16**, sem mudança.
- Nada protegido, nada em `data/`, código ou testes.

## 4. DECISÕES TÉCNICAS
- **Regra de rótulo.** (1) DEC das 35 → "aprovada por Arthur em 11/11/2026 (DEC-NNN)"; (2) DEC já APROVADA antes → data que o `DECISIONS.md` traz (10/11/2026); (3) sem DEC ou PROPOSTA → fica como está e entra na lista da seção 15. Acrescentei o **número da DEC** em cada item do cabeçalho e da seção 15, para a rastreabilidade (`economy.md`, linhas 5, 7 e 257 a 291).
- **Itens em que a DEC cobre a decisão, mas não o nome ou a fórmula.** `test_economy_distribution.gd` (o princípio é a DEC-142, de 10/11) e `test_initial_stock_covers_30_days` (a regra de 30 dias é a DEC-176): o texto diz que a decisão está aprovada e que **a formulação e o nome do teste seguem [PROPOSTA], sem DEC**. Mesmo critério na **hora a hora** (passos 1 a 5 = DEC-151; o **passo 0**, a folha dos postos antes dos locais, segue [PROPOSTA/HIP]) e no **D1** (a conferência na LW-093a é a DEC-137, de 10/11; o desenho dos ids como texto livre segue [PROPOSTA]).
- **Eventos (`events.md`).** Só o `WagesPaid` tem DEC aprovada (DEC-152; postos: DEC-164, de 10/11). Na `ContractOffered`, a vaga é a DEC-165 (11/11) e a DEC-144 (10/11), mas o **nome e a carga** do evento seguem [PROPOSTA]. Os outros sete eventos da economia ficam [PROPOSTA]: nenhuma DEC os cita. Deixei o "rascunho ... ainda não aprovado" do topo do `events.md`, porque vale para tudo que não é `WagesPaid`.
- **Frase do `run_sim`.** Confirmei no `main` (`63caee7`, e antes em `8dcc81d`): `tools/run_sim.gd` só faz `SimulationRunner.new(world_seed)`, `start_new_game()`, `run_days()` e imprime `describe_state()` (que inclui `world.state_hash()`); **não chama `register_module`**, que só é chamado em `GameModules.register`, e este só pelo `SimulationHost.start_new_game` com terreno. Logo o `run_sim` **e o hash que ele imprime não mudam** quando a economia ou o `world` forem registrados. Nova frase em `economy.md:40` (seção 2, item 3 da LW-088a): "o `run_sim` não muda (não registra módulo; o hash que ele imprime também não se altera); mudam o oráculo e o hash do soak de 30 dias", mais "o relatório da LW-088a mostra o hash do `run_sim` antes e depois (esperado: iguais)". Em `dados.md:282` a frase "o código do `run_sim` não muda" também foi trocada. Busquei "run_sim" nos três arquivos: restam só frases corretas (`economy.md:40` e `327`, `dados.md:282`).
- **Seção 16 e Estado.** Abertura reescrita: as decisões do registro "já estão aprovadas por Arthur" (as de 10/11 e as 35 de 11/11, em bloco) e "este arquivo entra no `main` junto com a Fase 3", **sem ramo nem agente** (`economy.md:295`); a tabela do registro agora traz a **data da aprovação** de cada DEC e uma linha para a DEC-167 (coluna `work_place_id`), conferida contra o registro final. "Estado" dos dois arquivos: **rodada 5, 11/11/2026**.
- **Proposta de entrada para o `DECISIONS.md`:** nenhuma.

## 5. TESTES EXECUTADOS
- `git diff --check` em cada ramo, antes do commit — **limpo** nos dois.
- Conferência de que **nada além de rótulo mudou** (script descartável, fora do projeto): nenhuma linha do diff contém a conta do tecido nem o plano B (`A cadeia do tecido`, `Plano B da Q22`, `A conta do tecido`, 0,97, 1,93, 2,2 `f`, 4,8 `f`); e os únicos números que saíram das linhas alteradas foram o "4" de "rodada 4" e o "21" de "Q16 a Q21" (a faixa virou lista item a item), em `economy.md`, e o "087" de "LW-087a" em `dados.md`.
- `tools/check_all` em **`1583db9` (087b)**, 07:46 a 07:49 — **VERDE**: "Arquitetura: nove verificações aprovadas"; GUT **Tests 1194, Passing Tests 1194, Asserts 261693**, Time 171,335 s; Warnings 1 e Deprecated 1 (iguais aos das execuções anteriores); "VERDE: arquitetura, dados e etapa de testes aprovadas"; código de saída 0.
- `tools/check_all` em **`ae3125b` (087d)**, 07:49 a 07:53 — **VERDE**, mesmos números (1194 de 1194, 261693 asserts, 181,269 s); código de saída 0.
- Rodados **em sequência**, não juntos. **Sem junção com o `main`** (ver PROBLEMAS).
- **NÃO EXECUTADO:** o `tools/run_sim` antes e depois (a conclusão sobre o hash vem de **ler o código**, não de rodar; a LW-088a mostrará os dois hashes); `test_save_codec.gd` e a fixture `save_v1` (é o que a LW-088a roda primeiro).

## 6. RESULTADOS
**Aceite, item a item.**

| Você pediu | Onde ficou |
|---|---|
| 1. Rótulos pelo status do registro (lido no início e no fim) | `economy.md`: linhas 3, 5, 7, 14, 37, 40, 44, 60, 62, 63, 69, 70, 77, 87, 88, 95, 97, 98, 100, 105, 116, 117, 131, 137 a 139, 144, 146, 154, 234, 257 a 291 e a tabela da seção 16 (linha 312); `dados.md`: 3, 20, 52, 73, 75, 79, 93, 111, 137, 252, 256, 282 e 286; `events.md`: 22 e 23. Lista completa na tabela abaixo |
| 2. Frase do `run_sim` | `economy.md:40` e `dados.md:282` (código lido no `main`) |
| 3. Seção 16 e "Estado" (rodada 5) | `economy.md:3` e `295`; `dados.md:3` |
| 4. Não mudar números, contas nem plano B | verificado (PROBLEMAS e TESTES acima) |
| 5. `check_all` em cada ramo, em sequência | verde nos dois HEADs finais |
| 6. `STATUS-B.md` e parar | este arquivo |

**O que não tem DEC e continua [PROPOSTA]** (lista também em `economy.md:283` a `289`): o desenho dos **ids de outro módulo como texto livre** (D1, lado do dado); a **tabela de distribuição** das cadeias (14 locais de produção, 6 postos, 20 locais `work`, 10 novos; o princípio é a DEC-142); **nomes e formatos** (colunas e arquivos de dados, consultas `peek_*` e seus campos `place_id`, `wage_per_hour`, `workers_wanted`, `workers_assigned`, `buy_cap_bp`, códigos `ECON_*`, nomes de teste); o **passo 0 da hora** (postos antes dos locais); o **plano B da Q22**; a **regra de margem** das receitas; os **eventos da economia** exceto `WagesPaid`; a **pasta** `data/economy/` e o formato dos arquivos. Os **valores [HIP]** continuam [HIP].

**Tabela "rótulo antigo → rótulo novo"** (linha **antes** = em `16ddf1b` ou `99dd70c`; linha **depois** = nos HEADs `1583db9` e `ae3125b`; os textos estão encurtados; os blocos da seção 15 e da tabela da seção 16 aparecem pela linha do bloco):

| Arquivo | Linha (antes → depois) | Rótulo antigo | Rótulo novo |
|---|---|---|---|
| `economy.md` | 3 → 3 | Estado: **RASCUNHO da LW-087b (10/11/2026, rodada 4), fora do `main`, não aprovado.** A Fase 2 … | Estado: **RASCUNHO da LW-087b (11/11/2026, rodada 5), fora do `main`.** As decisões do pré-voo … |
| `economy.md` | 3 → 3 | **aprovado por Arthur em 10/11/2026** (aprovação dada em mensagem; o registro em `DECISIONS.md`… | **aprovada por Arthur em 10/11/2026** ou **em 11/11/2026 (DEC-NNN)** (as decisões do pré-voo da… |
| `economy.md` | 3 → 3 | que separa o **decidido por Arthur**, o **decidido pelo revisor** e o que **segue em aberto** (… | que separa o **decidido por Arthur** (10/11/2026 e 11/11/2026), o que **segue como [PROPOSTA] d… |
| `economy.md` | 5 → 5 | **Decisões de Arthur (APROVADAS por mensagem em 10/11/2026; o registro em `DECISIONS.md` é da L… | **Decisões de Arthur (APROVADAS por mensagem em 10/11/2026 e registradas pela LW-087a no `DECIS… |
| `economy.md` | 5 → 5 | lã → tecido (a madeira também é o combustível). (3) As seis recomendações | lã → tecido (a madeira também é o combustível) (DEC-129). (3) As seis recomendações |
| `economy.md` | 5 → 5 | fora de `docs/`. (4) Os arquivos grandes | fora de `docs/` (as seis, nessa ordem: DEC-130 a DEC-135). (4) Os arquivos grandes |
| `economy.md` | 5 → 5 | em tarefa à parte (seção 7). (5) **Q10:** | em tarefa à parte (seção 7; DEC-136 e DEC-137). (5) **Q10:** |
| `economy.md` | 5 → 5 | com a aprovação de Arthur dos valores novos. (6) **Q19 do `npc.md`:** | com a aprovação de Arthur dos valores novos (DEC-142). (6) **Q19 do `npc.md`:** |
| `economy.md` | 5 → 5 | **sem rotina fixa e sem planejador**. (7) **Q22 do `npc.md`:** | **sem rotina fixa e sem planejador** (DEC-143). (7) **Q22 do `npc.md`:** |
| `economy.md` | 5 → 5 | a aceita pela utilidade. (8) **Consumo | a aceita pela utilidade (DEC-144). (8) **Consumo |
| `economy.md` | 5 → 5 | ficam **fora** da Fase 3. (9) **Postos de serviço (Q15):** | ficam **fora** da Fase 3 (DEC-163). (9) **Postos de serviço (Q15):** |
| `economy.md` | 5 → 5 | **provisório até a Fase 4**. (10) **Q22 (tecido) | **provisório até a Fase 4** (DEC-164). (10) **Q22 (tecido) |
| `economy.md` | 7 → 7 | **Decisões do revisor (Claude, na delegação de menores de Arthur, 10/11/2026), que valem como [… | **Decisões que vieram do revisor (Claude, na delegação de menores de Arthur, 10/11/2026) e que … |
| `economy.md` | 14 → 14 | (menor 10, decidido pelo revisor) | (menor 10, aprovado por Arthur em 11/11/2026, DEC-141) |
| `economy.md` | 37 → 37 | (decidido pelo revisor, f).** `EconomyModule` | (aprovada por Arthur em 11/11/2026, DEC-171 e DEC-172).** `EconomyModule` |
| `economy.md` | 40 → 40 | (revisor, [PROPOSTA]; revê a Q19 da rodada 3) | (aprovada por Arthur em 11/11/2026, DEC-175; revê a Q19 da rodada 3) |
| `economy.md` | 40 → 40 | O código do `run_sim` **não muda** (ele não registra módulos); muda só o hash que ele imprime. | O `run_sim` **não muda** (não registra módulo; o hash que ele imprime também não se altera); mu… |
| `economy.md` | 44 → 44 | Q9, decidido pelo revisor; | Q9, aprovada por Arthur em 11/11/2026, DEC-153; |
| `economy.md` | 60 → 60 | (Q21 A do `npc.md`, decidido pelo revisor; a economia é registrada antes do `npc`) | (Q21 A do `npc.md`, aprovada por Arthur em 11/11/2026, DEC-145; a economia é registrada antes d… |
| `economy.md` | 62 → 62 | **Conservação de bens [PROPOSTA, Q13]:** | **Conservação de bens (Q13; aprovada por Arthur em 11/11/2026, DEC-156):** |
| `economy.md` | 63 → 63 | **Dono morto [PROPOSTA, Q2].** | **Dono morto (Q2; aprovada por Arthur em 11/11/2026, DEC-146).** |
| `economy.md` | 69 → 69 | **dado fixo por bem e mercado na Fase 3**, decidido pelo revisor, menor 8; | **dado fixo por bem e mercado na Fase 3**, aprovado por Arthur em 11/11/2026, DEC-139, menor 8; |
| `economy.md` | 70 → 70 | **Fórmulas em inteiros [PROPOSTA, Q6 e Q7; decidido pelo revisor, e].** | **Fórmulas em inteiros (Q6 e Q7; aprovadas por Arthur em 11/11/2026, DEC-150; a curva exata é c… |
| `economy.md` | 77 → 77 | (Q21, decidido pelo revisor; entra na LW-090) | (Q21, aprovado por Arthur em 11/11/2026, DEC-177; entra na LW-090) |
| `economy.md` | 87 → 87 | **Quem vende o quê na Fase 3 (decidido pelo revisor, h).** | **Quem vende o quê na Fase 3 (aprovada por Arthur em 11/11/2026, DEC-168).** |
| `economy.md` | 88 → 88 | (menor 11, decidido pelo revisor) | (menor 11, aprovado por Arthur em 11/11/2026, DEC-141) |
| `economy.md` | 88 → 88 | (menor 7, decidido pelo revisor: | (menor 7, aprovado por Arthur em 11/11/2026, DEC-138: |
| `economy.md` | 95 → 95 | (Q18, decidido pelo revisor; a DEC-164 da LW-087a diz o mesmo) | (Q18, aprovada por Arthur em 11/11/2026, DEC-174; a DEC-164, aprovada por Arthur em 10/11/2026,… |
| `economy.md` | 97 → 97 | [Q18 A do `npc.md`, decidido pelo revisor; FICA como está] | [Q18 A do `npc.md`, aprovada por Arthur em 11/11/2026, DEC-151 e DEC-152; FICA como está] |
| `economy.md` | 98 → 98 | **Um trabalho, um pagamento (decidido pelo revisor, a).** | **Um trabalho, um pagamento (aprovada por Arthur em 11/11/2026, DEC-151).** |
| `economy.md` | 100 → 100 | **Hora a hora [PROPOSTA, Q8].** | **Hora a hora (Q8; os passos 1 a 5 são a DEC-151, aprovada por Arthur em 11/11/2026; o passo 0,… |
| `economy.md` | 100 → 100 | (quem vende é o **local**, decidido pelo revisor, h) | (quem vende é o **local**, aprovada por Arthur em 11/11/2026, DEC-168) |
| `economy.md` | 105 → 105 | A tabela é **[PROPOSTA/HIP]**, com nomes genéricos (DEC-100), **para Arthur aprovar na LW-087a*… | O princípio e os ofícios são a DEC-142 (aprovada por Arthur em 10/11/2026); a tabela é **[PROPO… |
| `economy.md` | 116 → 116 | **Teste de dados `test_economy_distribution.gd` (LW-097) [PROPOSTA].** | **Teste de dados `test_economy_distribution.gd` (LW-097; o princípio é a DEC-142, aprovada por … |
| `economy.md` | 117 → 117 | (decisão de Arthur, Q17; extensão Q20, decidida pelo revisor; dado na LW-097) | (Q17, aprovada por Arthur em 11/11/2026, DEC-166; extensão Q20, aprovada por Arthur em 11/11/20… |
| `economy.md` | 131 → 131 | **Conferência [PROPOSTA].** | **Conferência (a regra de 30 dias é a DEC-176, aprovada por Arthur em 11/11/2026; a formulação … |
| `economy.md` | 137 → 137 | - **Conta do NPC (Q21 A do `npc.md`, decidido pelo revisor).** | - **Conta do NPC (Q21 A do `npc.md`, aprovada por Arthur em 11/11/2026, DEC-145).** |
| `economy.md` | 138 → 138 | (decididos por Arthur; escopo do D1 decidido pelo revisor) | (DEC-137, aprovada por Arthur em 10/11/2026, inclusive o escopo do D1) |
| `economy.md` | 139 → 139 | (decidido, 3.4; fixado pelo revisor, d) | (decidido, 3.4; fixado na LW-093: aprovada por Arthur em 11/11/2026, DEC-170; a DEC-133, de 10/… |
| `economy.md` | 144 → 144 | aceito pelo revisor, [Q16] | aprovada por Arthur em 11/11/2026, DEC-165, [Q16] |
| `economy.md` | 146 → 146 | decidida pelo revisor, g: depois da LW-096 | aprovada por Arthur em 11/11/2026, DEC-169: depois da LW-096 |
| `economy.md` | 154 → 154 | menor 9, decidido pelo revisor) | menor 9, aprovado por Arthur em 11/11/2026, DEC-140) |
| `economy.md` | 234 → 234 | aprovação, ou troca, das decisões do revisor, da tabela de distribuição e dos números [HIP]; | as decisões do revisor foram aprovadas por Arthur em 11/11/2026 (35 em bloco); ficam para ele a… |
| `economy.md` | 257 → 257 | (seção 15 inteira: títulos e bullets sem DEC) | (seção 15 reescrita: cada bullet com a DEC; lista nova 'Seguem como [PROPOSTA]') |
| `economy.md` | 295 → 295 | O roadmap é arquivo protegido; as diferenças abaixo vêm das decisões de Arthur de 10/11/2026 e … | O roadmap é arquivo protegido; as diferenças abaixo vêm das decisões de Arthur (10/11/2026 e 11… |
| `economy.md` | 312 → 312 | (tabela do registro: sem a data de aprovação; 'rodada 4') | (tabela com a data de aprovação de cada DEC; 'rodada 5'; linha da DEC-167 acrescentada) |
| `dados.md` | 3 → 3 | Estado: **RASCUNHO da LW-087d (10/11/2026, rodada 4), fora do `main`, não aprovado.** A Fase 2 … | Estado: **RASCUNHO da LW-087d (11/11/2026, rodada 5), fora do `main`.** As decisões do pré-voo … |
| `dados.md` | 3 → 3 | **aprovado por Arthur em 10/11/2026** (o registro em `DECISIONS.md` é da LW-087a), **decidido p… | **aprovada por Arthur em 10/11/2026** ou **em 11/11/2026 (DEC-NNN)** (registradas no `DECISIONS… |
| `dados.md` | 20 → 20 | **D1 (referências entre módulos): decidido pelo revisor, vale como [PROPOSTA].** | **D1 (referências entre módulos): a conferência na LW-093a é a DEC-137 (aprovada por Arthur em … |
| `dados.md` | 52 → 52 | (contrato, Q9, e Q20 do `npc.md`, decididos pelo revisor) | (contrato, Q9, e Q20 do `npc.md`, aprovados por Arthur em 11/11/2026, DEC-153) |
| `dados.md` | 73 → 73 | (decidido pelo revisor; "dias de consumo" é calibração, LW-112) | (aprovado por Arthur em 11/11/2026, DEC-139; "dias de consumo" é calibração, LW-112) |
| `dados.md` | 75 → 75 | (Q21, decidido pelo revisor; entra na LW-090) | (Q21, aprovado por Arthur em 11/11/2026, DEC-177; entra na LW-090) |
| `dados.md` | 79 → 79 | (decisão de Arthur, Q17; Q20 decidida pelo revisor; dado na LW-097) | (Q17, aprovada por Arthur em 11/11/2026, DEC-166; Q20, aprovada por Arthur em 11/11/2026, DEC-1… |
| `dados.md` | 93 → 93 | **Conferência (LW-097, `test_initial_stock_covers_30_days`) [PROPOSTA]:** | **Conferência (LW-097, `test_initial_stock_covers_30_days`; a regra de 30 dias é a DEC-176, apr… |
| `dados.md` | 111 → 111 | **`spread_bp` de 1 a 20000** (decidido pelo revisor, e) | **`spread_bp` de 1 a 20000** (aprovado por Arthur em 11/11/2026, DEC-150) |
| `dados.md` | 137 → 137 | foram decididos por Arthur** (só em dados) | foram decididos por Arthur** (só em dados; DEC-142, aprovada em 10/11/2026) |
| `dados.md` | 252 → 252 | (Q18, decidido pelo revisor; a DEC-164 da LW-087a diz o mesmo) | (Q18, aprovada por Arthur em 11/11/2026, DEC-174; a DEC-164, aprovada por Arthur em 10/11/2026,… |
| `dados.md` | 256 → 256 | ; **a tabela é proposta para ele aprovar na LW-087a**, com nomes genéricos (DEC-100). |  (DEC-142, aprovada em 10/11/2026); **a tabela é [PROPOSTA/HIP], sem DEC no registro da LW-087a… |
| `dados.md` | 282 → 282 | (decisão de Arthur: a população inicial nasce empregada por dados; o carregador do `npc` passa … | (decisão de Arthur, DEC-144, de 10/11/2026: a população inicial nasce empregada por dados; a co… |
| `dados.md` | 282 → 282 | o código do `run_sim` não muda), **com a aprovação de Arthur dos valores novos**. | o `run_sim` não muda, nem o hash que ele imprime), **com a aprovação de Arthur dos valores novo… |
| `dados.md` | 286 → 286 | **Teste de dados `test_economy_distribution.gd` (LW-097) [PROPOSTA].** | **Teste de dados `test_economy_distribution.gd` (LW-097; o princípio é a DEC-142, aprovada por … |
| `events.md` | 22 → 22 | **[PROPOSTA]** (Q18 A do `npc.md`, decidido pelo revisor; postos de serviço: decisão de Arthur) | **aprovada por Arthur em 11/11/2026** (DEC-152, Q18 A do `npc.md`; postos de serviço: DEC-164, … |
| `events.md` | 23 → 23 | **[PROPOSTA]** \| nenhum hoje. **Previstos:** `npc` (aceita pela utilidade; a vaga é decisão de… | **[PROPOSTA]** (o nome e a carga; a vaga como tipo de contrato é a DEC-165, aprovada por Arthur… |

## 7. PROBLEMAS ENCONTRADOS
- **O `main` andou durante a tarefa:** de `8dcc81d` para **`63caee7`**, que é o mesmo commit do registro da LW-087a (as DEC aprovadas, o roadmap, o `0012`, o `ROADMAP_STATUS.md` e o `backlog.md`). **Os meus dois ramos não o contêm** (confirmei por `merge-base`) e **eu não fiz junção**: a sua autorização desta rodada diz "nada de merge", e o AGENTS 10.2 exige autorização para `merge`; uma junção seria também um segundo commit por ramo. Os arquivos que mudei (`economy.md`, `dados.md`, `events.md`) **não** foram alterados no `main` nesse intervalo, então a junção não deve ter conflito. Os status das DEC no `main` são os que usei (35 "APROVADA por Arthur em 11/11/2026").
- **A (HEAD final `63caee7`):** não achei mais nenhuma das divergências da rodada 4: o adendo `86d4310` corrigiu as DEC-153 e 163 (tecido), os trechos do `0012` e a LW-093b nas divergências do roadmap. O roadmap já traz a frase do `run_sim` corrigida.
- **C (HEAD `a8be77b`):** (1) o `npc.md` (bloco "Origem de cada decisão", perto da linha 308) ainda diz que o `DECISIONS.md` "ainda mostra PROPOSTA" nas 35 até a LW-087a registrar a aprovação; **já está registrada, e no `main`**; (2) a divergência do vocabulário `tool` ou `plank` na Q20 e o pedido "[PENDENTE, pedido à B]" da vaga, que eu tinha listado na rodada 4, **foram corrigidos** pela C; (3) a LW-094 agora é uma tarefa, como no roadmap. Nenhuma divergência com os meus nomes de campos da vaga.
- **Meu:** o "Estado" do `events.md` continua dizendo "rascunho, ainda não aprovado" para o catálogo; é verdade para tudo menos o `WagesPaid` (mantido de propósito, acima). O cabeçalho de `economy.md` (linha 3) usa "DEC-NNN" como exemplo de rótulo, não como referência.

## 8. RISCOS
- Os pontos **sem DEC** seguem [PROPOSTA]; se o texto de uma DEC mudar no registro depois desta rodada, o rótulo daqui precisa seguir.
- A conclusão sobre o `run_sim` vem da leitura do código; a LW-088a confirma rodando (hash antes e depois).
- Os ramos 087b e 087d estão **atrás do `main`**; a junção fica para quando você autorizar.
- Seguem de antes: a conta do tecido é ilustrativa (suposições minhas), a cadeia é fina (1 hora de trabalho por dia) e a fixture `save_v1` não foi executada.

## 9. PENDÊNCIAS
- **Suas:** aprovar, ou trocar, os pontos sem DEC listados acima (a tabela de distribuição e os nomes são os mais relevantes antes da LW-088a); dizer se autoriza a **junção com o `main`** (`merge origin/main`) nos dois ramos. O plano B da Q22 só volta a você se a LW-110 mostrar fome.
- **Do que não está feito:** nada de código, dado ou teste (é só documento). Nenhum teste manual.

## ACOMPANHAMENTO
- **Avanço:** Fase 2 fechada (32 de 32); registro da LW-087a **no `main`** (aprovado); Fase 3 não iniciada; rascunhos 087b, 087c e 087d **fora do `main`**.
- **Próxima tarefa recomendada:** nenhuma minha (regra 13). A próxima do roadmap é a **LW-088a**, que **não iniciei**.
- **Decisões que dependem de Arthur:** (a) aprovar, ou trocar, os pontos sem DEC (recomendo aprovar a tabela de distribuição e os nomes antes da LW-088a); (b) autorizar a junção com o `main`, se quiser os ramos em dia.
- **Git:** `lw-087b-contrato-economy` em `1583db9` e `lw-087d-eventos-e-dados` em `ae3125b`, **publicados só como ramos** (refspec explícita; um commit em cada); este relatório vai só no `status-b`. **Nada no `main`, sem tag, sem Fase B, sem `--force`, sem junção.** `main` em `63caee7`. Relatório da rodada 4: commit `c2de942` do `status-b`.

## ADENDO — junção com o `main` (autorizada por Arthur no chat: "Sim, juntar"; 08:46)
- **O que fiz:** `merge origin/main` (`63caee7`, o registro da LW-087a já aprovado) **dentro de cada ramo de rascunho**, um commit de junção em cada: `lw-087b-contrato-economy` `1583db9` → **`f384597`** e `lw-087d-eventos-e-dados` `ae3125b` → **`1ea4590`**. **Nada foi feito no `main`** (sem merge nele, sem push nele), sem tag, sem Fase B, sem `--force`. Sem conflito: o `main` trouxe só `DECISIONS.md`, `DEVELOPMENT_ROADMAP.md`, `ROADMAP_STATUS.md`, `backlog.md` e o `0012` (5 arquivos, +992 −42); conferi que `economy.md`, `dados.md` e `events.md` ficaram **idênticos** aos de antes da junção.
- **Testes (`tools/check_all`, em sequência, nos HEADs pós-junção):** `f384597` — **VERDE**, Tests 1194, Passing Tests 1194, Asserts 261693, Time 188,384 s, Warnings 1 e Deprecated 1; `1ea4590` — **VERDE**, mesmos números, Time 173,385 s; código de saída 0 nos dois. Início 08:00, fim 08:45; o primeiro ficou mais lento porque o Mac estava ocupado (carga alta), sem falha.
- **Outras observações:** a mensagem que repetia o texto da rodada 5 (mesmo conteúdo) chegou com a junção em andamento; **não refiz a rodada**, só concluí a junção. Os ramos ficam com **dois commits cada** (o da rodada 5 e a junção), porque você autorizou a junção depois da regra "um commit". Na releitura final: `main` e a A em `63caee7`; a C andou para `cf21a0a` (não li o que mudou; é arquivo da C, fora desta tarefa).
- **Git:** `lw-087b-contrato-economy` `f384597`, `lw-087d-eventos-e-dados` `1ea4590` e este `status-b` publicados; o `main` segue em `63caee7`.
