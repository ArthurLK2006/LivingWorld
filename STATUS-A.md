10/11/2026 21:48 (Brasília) · PRONTA PARA REVISÃO — RASCUNHO · LW-087a, rodada 4: commit `28a0227` no ramo `lw-087a-registro-fase-3` empurrado; `check_all` verde; `main` sem mudança (`8dcc81d`); NÃO está no `main`, sem Fase B e sem tag; o Godot da A está parado

# RELATÓRIO — LW-087a, rodada 4: DEC-178 (tecido), marcos de hash por bloco e quatro frases     Status: PRONTA PARA REVISÃO — RASCUNHO (não está no `main`)

> **Em uma frase:** só texto, em **um** commit (`28a0227`) no ramo `lw-087a-registro-fase-3`. Entrou a sua decisão Q22 (DEC-178, APROVADA: o tecido na manutenção dos locais); os marcos de hash passaram a **por bloco** (DEC-175 e DEC-172 revistas); a vaga é em **local de trabalho** (DEC-165); a DEC-162 e a DEC-177 ganharam as frases do `run_sim` e de `ECON_MARKET_FULL`; o roadmap acompanhou. O `main` não andou (`8dcc81d`). **Sem Fase B, sem tag.** Parei (regra 13).

## Declaração de leitura (início da tarefa)
- **Li, no HEAD de início** (B: contrato da `economy` `6b59a96`, dados e eventos `bfceb90`; C: `world.md` e `npc.md` `b2d028d`): as linhas do teto de compra e de `ECON_MARKET_FULL`, da manutenção (`site_upkeep`), dos marcos de hash, do `RouteStateChanged` e do comando de fechar rota (`world.md`), e a distribuição 14/6/20/10. Reli os HEADs **no fim**: **B não mudou**; **a C avançou** de `b2d028d` para **`b7eb2ee`** ("rodada 4, marcos de hash por bloco e tecido na manutenção dos locais") enquanto eu trabalhava; li o commit novo e refiz a conferência abaixo com ele. **Nenhum STATUS é citado nos documentos do projeto** (conferido por busca).
- **Decisões de que dependo e status:** DEC-163 e DEC-164 APROVADAS; DEC-161, 162, 165, 172, 175 e 177 PROPOSTA (minhas); DEC-153 PROPOSTA (ganhou uma nota; ver abaixo).

## ANTES e DEPOIS dos totais (recontados por script; índice = cabeçalhos, sem número repetido)

| | APROVADA | (com ressalva) | PROPOSTA | PENDENTE | DESCARTADA | SUBSTITUÍDA | Total |
|---|---|---|---|---|---|---|---|
| **ANTES** (HEAD `1ad022a`) | 84 | 20 | 64 | 18 | 10 | 1 | **177** |
| **DEPOIS** (HEAD `28a0227`) | **85** | 20 | 64 | 18 | 10 | 1 | **178** |

**Bate com o esperado** (178: APROVADA 85, PROPOSTA 64, PENDENTE 18, DESCARTADA 10, SUBSTITUÍDA 1). Conta: APROVADA +1 (DEC-178); nada mais muda. Saída do script: `índice=178 cabeçalhos=178 repetidos=nenhum só_no_índice=nenhum só_no_corpo=nenhum · CONFERE`; o status de cada entrada bate com o índice (as 178). **Versão do documento: 0.9**; há linha 0.9 no histórico; o próximo número livre é **DEC-179**.

## Decisão → entrada / linha

| Decisão (sua ordem) | Entrada em `DECISIONS.md` | Roadmap e outros |
|---|---|---|
| **Q22** tecido na manutenção dos locais | **DEC-178** (APROVADA); nota "ampliada pela DEC-178" na **DEC-163**; nota na **DEC-153** | **LW-092** (`tool`, `plank` e `fabric`); **LW-097** (tecido nos importados, "onde o povoado não tece") |
| Marcos de hash por bloco | **DEC-175 revista** (título, contexto, decisão); **DEC-172 revista** | **LW-088a** (marco 1 e a regra de parar); LW-092, **LW-093**, **LW-094**, **LW-095**, **LW-096a** (marco 2); **LW-097** (marco 3); nota sob a tabela 3.D |
| Vaga em **local de trabalho** | **DEC-165 revista** (título e decisão) | **LW-096** |
| O código do `run_sim` não muda; o hash impresso muda | **DEC-162 revista**; DEC-172 e DEC-175 | 0012, seções 5.3 e 9.2 |
| Erro `ECON_MARKET_FULL` | **DEC-177 revista** | LW-090 (já tinha o teto) |
| LW-097: terreno **não** ampliado; `RouteStateChanged` e fechar rota | DEC-161 e DEC-140 (inalteradas) | **LW-097** (tirei "se preciso, ampliar"; citei o evento e `request_close_route` / `request_open_route`, como o `world.md` da C os põe) |
| Distribuição 14/6/20/10 | **sem entrada própria**, como você mandou | LW-092, LW-095 e LW-097; 0012, seção 8 |
| Critério 3.F | nada a mudar | — |

## Conferência de nomes e números no HEAD de B e C

| Nome ou número | A (esta rodada) | B (contrato, dados, eventos) | C (`npc.md`, `world.md`) |
|---|---|---|---|
| `workplace_id` | DEC-152; LW-095 | `economy.md` (5), `events.md` (1) | `npc.md` (2) ✅ |
| `peek_site` / `peek_post` | DEC-152; LW-095 | `economy.md` e `events.md` | `npc.md` (5 e 5) ✅ |
| `ECON_*` | cito 3: `ECON_MARKET_NO_FUNDS`, `ECON_WORKER_ALREADY_ASSIGNED`, `ECON_MARKET_FULL` | **os 3 existem** no `economy.md` (§4, §5, §6) ✅ | não cita |
| 14 locais de produção / 6 postos / 20 `work` / 10 novos | LW-092, 095 e 097; 0012 §8 | `economy.md` §6 e `dados.md` (linha **Total: 14, 6, 20, 10**) ✅ | `npc.md` (linha 323: 14, 6, 20, 10; A +2, B +3, C +5) ✅ |
| `vacancy` em local de trabalho (produção ou posto) | DEC-165; LW-096 | `economy.md` §8: "local de produção ou posto" ✅ | `npc.md` ✅ |
| `RouteStateChanged` e fechar rota na LW-097 | DEC-140; LW-097 | `economy.md` §9 (reserva; "LW-097") ✅ | `world.md`: `RouteStateChanged(route_id, new_state)` e `request_close_route` / `request_open_route` **na LW-097** ✅ |
| **Marcos de hash** | **por bloco** (88a a 92; 93 a 96a; 97) | **por tarefa** (88a; 93 a 95; 97) | **por bloco** ✅ (HEAD novo `b7eb2ee`: mesma regra, inclusive "primeiro valor de um teste novo não é mudança") |
| `fabric` (tecido) na manutenção | tool, plank, **fabric** (DEC-178) | só `tool` ou `plank` | **ferramenta, tábua e tecido** ✅ (`npc.md`, linhas 274 e 313; cita a DEC-178) |

## Divergências encontradas na B e na C (só listo; você as envia)
1. **B (`economy.md` linha 40, §14 e §16):** os três marcos de hash são **por tarefa** (LW-088a; LW-093 a LW-095; LW-097). Pela sua regra são **por bloco** (LW-088a a LW-092; LW-093 a LW-096a; LW-097). A **linha da LW-097 do §14** diz "marco 2" e "marco 3" na mesma linha (inconsistente por si só). **A C já corrigiu isto no commit `b7eb2ee`.**
2. **B (`economy.md` §6 e `dados.md`, `site_upkeep`):** o vocabulário é "só `tool` ou `plank`"; falta `fabric` (DEC-178). A "limitação conhecida do `fabric`" e a pergunta [Q22] ficam respondidas pela sua decisão. **A C já inclui o tecido** (`npc.md`, linhas 274 e 313).
3. **B (estoque inicial dos importados):** não inclui o **tecido onde o povoado não tece** (A e C); a lista do contrato da `economy` precisa dele (o roadmap já remete a ela).
4. **B (`economy.md` linha 40) e C (`npc.md` linha 304 e `world.md` Q-W6):** dizem que o `run_sim` "não muda, nem o código dele" porque "não registra módulo nenhum". A DEC-175 diz que o **código** não muda mas o **hash que ele imprime** muda (ver "O que quero que você veja", item 1).

## O que quero que você veja
1. **O `run_sim`: a sua frase e a de B e C discordam.** Registrei como você mandou ("o código do `run_sim` não muda; muda o hash que ele imprime", DEC-162, DEC-172 e DEC-175). A C diz (`npc.md` linha 304 e `world.md` Q-W6) que o `run_sim` não registra módulo nenhum e por isso o hash dele **não** muda; a B diz o mesmo (linha 40). **Não consigo decidir quem está certo só lendo:** a primeira tarefa do marco 1 (LW-088a) mostra, ao rodar. Se a C estiver certa, a frase vira "o `run_sim` não muda".
2. **Pus uma nota na DEC-153**, que não estava na sua lista: ela dizia "o tecido é só mercadoria de comércio". A nota diz "(a DEC-178 inclui o tecido na manutenção dos locais)". Só a nota, nada reescrito. O texto antigo da DEC-163 e a seção 7.1 do 0012 (rodada 2) também dizem "tecido só mercadoria"; ficam como histórico, e a DEC-163 ganhou a nota "ampliada pela DEC-178", como você mandou.
3. **Os marcos por bloco só aparecem em linhas de tarefa de alguns blocos:** LW-088a, 092, 093, 094, 095, 096a e 097. As LW-089 a LW-091 (também do marco 1) não têm menção própria; a regra está na LW-088a, na LW-092 e na nota sob 3.D.
4. **A LW-097 ficou ainda mais pesada:** terreno, rotas e fechar rota, 10 locais `work`, `work_place_id`, estoque dos importados com tecido, teste de distribuição e o marco 3. Continuo achando que vale dividi-la ao preparar o prompt.
5. **A regra "o primeiro valor de um teste novo não é mudança"** está só na DEC-175 e na nota 3.D; não repeti nas linhas das tarefas.

## 1. Resumo
Registrei a sua decisão Q22 (DEC-178) e refiz os marcos de hash por bloco, com a regra de parar no primeiro valor que mudar e de só registrar os demais. Ajustei quatro frases (vaga em local de trabalho; `run_sim`; `ECON_MARKET_FULL`; nota da DEC-163) e o roadmap nas LW-088a, 092, 093, 094, 095, 096, 096a e 097. Conferi nomes e números nos HEADs da B e da C (a C mudou durante a tarefa; reli): o que está igual e as 4 divergências estão acima. Nenhum código, dado, teste, backlog, `ROADMAP_STATUS.md` ou `README.md` foi tocado.

## 2. Arquivos criados
- Nenhum.

## 3. Arquivos modificados (contra o commit anterior `1ad022a`)
- `docs/DECISIONS.md` — +35 −19: DEC-178 nova; DEC-175, 172, 165, 162 e 177 revistas; notas nas DEC-153 e 163; 1 linha de índice nova e 2 de título trocado; totais, versão 0.9, histórico, "próximo número".
- `docs/DEVELOPMENT_ROADMAP.md` — +10 −10: LW-088a, 092, 093, 094, 095, 096, 096a e 097, a nota sob 3.D e a lista de divergências.
- `docs/decisions/0012-pre-voo-da-fase-3.md` — +13 −3: cabeçalho (DEC-178 APROVADA), seção 9 "Rodada 4" e duas frases ajustadas (5.3 e 7.2).
- Não toquei em `docs/backlog.md`, `AGENTS.md`, GDD, arquitetura, `project.godot`, `data/`, `tests/`, `ROADMAP_STATUS.md` nem `README.md`.

## 4. Decisões técnicas
- **DEC-178 é APROVADA** (sua decisão escrita), com a frase "Escolha de Arthur na rodada 4 (Q22)". Ampliou a DEC-163 só por uma **nota curta**, como você pediu.
- **DEC-175 e DEC-172 foram reescritas na própria entrada** (são PROPOSTA minha e ainda não entraram no `main`). A regra de parar e mostrar "valor antigo, novo e causa" e a frase de aprovação ("aprovo os hashes do marco N") estão na DEC-175.
- **A DEC-178 não ganhou entrada nova para o estoque do tecido nos importados**: a consequência está na própria DEC-178 e na linha da LW-097.
- **Proposta de entrada para `DECISIONS.md` / pedido de desvio:** nenhum.

## 5. Testes executados
- `git fetch origin '+refs/heads/main:refs/remotes/origin/main'` (e dos três ramos da B e da C): `main` em `8dcc81d`, já dentro do ramo, **nada a juntar**; o ramo da B **não mudou** entre o início e o fim; **o da C avançou** para `b7eb2ee` e foi relido.
- Script de recontagem: antes `177 · CONFERE`, depois `178 · CONFERE`, com os totais acima. Coerência: status do índice = status de cada entrada (178); toda `DEC-NNN` citada no roadmap e no 0012 existe; toda seção do 0012 citada pelas entradas existe (inclusive a 9). Busca de `STATUS-A`, `STATUS-B`, `STATUS-C`, `status-a/b/c` e dos rótulos "da B" e "da C": **nenhuma ocorrência**.
- **`tools/check_all` no HEAD final `28a0227` (21:44:20 a 21:47:44, 10/11/2026): VERDE** (`EXIT_CODE_CHECK_ALL=0`).
- **NÃO EXECUTADO:** oráculo, vida de 30 dias, `run_sim` (só documentos).

## 6. Resultados
- **`check_all`:** 124 scripts, **1.194 testes, 1.194 passando, 0 falhando**, 261.693 asserts, 172,1 s; 313 scripts sem aviso de compilação; nenhum "SCRIPT ERROR" nem "Parse Error".
- **Critério de aceite:** 1 (DEC-178; DEC-163 com nota; DEC-175 e DEC-172 por bloco; DEC-165, 162 e 177 revistas; versão 0.9, histórico, índice e totais por script, 178 como esperado) · 2 (roadmap: LW-088a, 093 a 095 e 097 com os marcos; LW-092 com `fabric`; LW-096 com "local de trabalho"; LW-097 sem ampliar o terreno, com o tecido nos importados e com o fechar rota) · 3 (0012: cabeçalho e seção 9) · 4 (conferência acima, B e C lidos no início e no fim) · 5 (merge: nada a juntar).

## 7. Problemas encontrados
- As **4 divergências** acima (a B tem as 4; a C só a do `run_sim`, porque o commit `b7eb2ee` corrigiu os marcos e o tecido), para você enviar.
- **A frase do `run_sim`** (item 1 acima): a sua ordem e as duas fichas discordam.
- A DEC-153 tinha a frase "o tecido é só mercadoria", agora anotada.

## 8. Riscos
- **Os marcos por bloco** dependem de o agente que roda cada tarefa seguir a regra de parar no primeiro valor que mudar; se ele registrar em silêncio, o hash muda sem a sua aprovação. A regra está na DEC-175, na LW-088a e na nota 3.D.
- **O `fabric` na manutenção** muda o equilíbrio dos povoados que não tecem (A e C): eles passam a importar tecido, o que depende do estoque inicial e, depois, do comerciante (LW-098). Números [HIP]; a LW-112 calibra.
- **35 entradas minhas ainda são PROPOSTA**; a LW-097 concentra decisões suas (hashes, formato de dado, povoado C).

## 9. Pendências
- **Para você decidir (cada uma com a minha recomendação):** (1) conferir o `run_sim` na LW-088a e acertar a frase — recomendo manter como está até a primeira rodada mostrar; (2) mandar as divergências para a B (as 4) e para a C (a do `run_sim`) — recomendo mandar antes da Fase B da LW-087a; (3) aprovar ou trocar as PROPOSTA — recomendo aprovar as DEC-174 a 177 e a DEC-175 revista junto.
- **Fase B:** não autorizada. A linha de status e o `README` entram só quando você mandar o rascunho para o `main`.
- **Teste manual:** nenhum (só texto).

## ACOMPANHAMENTO
- **Avanço:** a LW-087a segue como primeira parte da LW-087; a Fase 3 não começou (contagens do status inalteradas).
- **Próxima tarefa recomendada:** a sua revisão da rodada 4 e, se aprovada, a Fase B da LW-087a; antes, a B atualiza o rascunho com as divergências 1 a 4 e a C confere a do `run_sim`. **Não iniciada.**
- **Decisões que dependem de você:** as três acima.
- **Git:** **um** commit novo (`28a0227`) no ramo `lw-087a-registro-fase-3`; empurrados **só** esse ramo e o `status-a`; nada no `main`, nenhuma tag, sem `--force`.
