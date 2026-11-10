10/11/2026 20:22 (Brasília) — CONCLUÍDA: TAREFA 1 (LW-086, fechamento da Fase 2) no `main` (`8dcc81d`) e tag `fase-2-concluida` criada e enviada. Fase 2 em 32 de 32 (100%); projeto em 87 de 192 (45,3%). Seguindo para a Tarefa 2 (revisão) e a Tarefa 3. Nada rodando.

# TAREFA 1 — RELATÓRIO — LW-086: validação e fechamento da Fase 2        Status: PRONTA PARA REVISÃO (já no `main`; a auditoria de Arthur não foi feita)

Li antes: AGENTS (seções 0, 10, 12, 14 e 15 de novo; versão 0.4), `docs/fase-2/LW-086-roteiro-para-arthur.md` e `docs/fase-2/LW-086-relatorio-de-fechamento.md` (os dois, inteiros), `docs/DEVELOPMENT_ROADMAP.md` 2.F, 2.H e 2.J, `docs/ROADMAP_STATUS.md` (cabeçalho, bullets de ressalvas e as linhas da 082, 083 e 086a), o README (linhas 9, 140, 165, 170 e 274), os documentos que citam F3 e as duas tags anteriores (`git tag -n`, `git cat-file -t`). Decisões: DEC-122 (aceita "por ora"), DEC-126, DEC-127 e DEC-128 (APROVADAS, no `main`); DEC-047, 049 e 054 seguem PROPOSTA no `DECISIONS.md` (conferido).

1. RESUMO
A Fase 2 está fechada em texto e em Git: relatório de fechamento sem "rascunho", com as respostas de Arthur e as três ressalvas de 2.F com todas as letras; roteiro, README e contratos corrigidos para Tab (ou fn+F3); linha da LW-086 e placar (32 de 32 e 87 de 192) no status e no README; `check_all` verde no HEAD final; `main` por avanço simples; tag `fase-2-concluida` criada e enviada no commit final, depois do `check_all` verde e da fase em 32 de 32 no `main`.

2. ARQUIVOS CRIADOS
- Nenhum.

3. ARQUIVOS MODIFICADOS (7 documentos, 110 inserções e 77 remoções; nenhum protegido, nenhum código)
- `docs/fase-2/LW-086-relatorio-de-fechamento.md` — sem "RASCUNHO"; seção 1 (placar e as 3 ressalvas), 2 (números e DEC-126 a 128), 3 (entregáveis 8, 9 e 11), 4 (tabelas 2.F e 2.J), **5 (as respostas de Arthur, só as palavras dele)**, 6 (retrospectiva, com a lição da tecla F3 e a da estimativa de tempo), 7 (itens 4, 5, 10 e 11 decididos), 8 e 9.
- `docs/fase-2/LW-086-roteiro-para-arthur.md` — 11 pontos com F3 trocados para "Tab (ou fn+F3)", mais um aviso do Mac logo abaixo da tabela de teclas.
- `docs/ROADMAP_STATUS.md` — cabeçalho (CONCLUÍDA, 32 de 32, 100%, tag, 87 de 192, 45,3%), a linha da **LW-086** (concluída com ressalvas, **sem o placar no texto**), um bullet em "Pendências e ressalvas" e uma frase de atualização nas linhas da LW-082 e da LW-083.
- `README.md` — estado da Fase 2 (CONCLUÍDA), a LW-086, a tag, os números e a tecla do painel (Tab, ou fn+F3).
- `docs/modules/app.md` e `docs/modules/tools.md` — nota de que F3 sozinho é o Mission Control no Mac.
- `docs/backlog.md` — +1 linha **no meio do arquivo** (linha 180 de 213): a dica escrita no jogo ainda diz "F3 ou Tab fecha".

4. DECISÕES TÉCNICAS
- **As três ressalvas de 2.F, escritas com todas as letras** (relatório, seções 1, 4, 5, 7 e 8; linha da LW-086 e bullet no status): (1) critério 2: picos acima de ~10 ms **informativos**; (2) critério 3: teleporte e quadros **pela janela dele**, sem teste automático do teleporte; (3) critério 8: "ofício novo só por JSON" **sem teste**, vira a **LW-093b**, tarefa pequena só de teste antes da LW-093, a registrar pela A na LW-087a (conferido: hoje não consta no roadmap nem no status).
- **O placar não está dentro do texto da linha de status** (nem "32 de 32" nem "87 de 192"): a contagem por grep ficou limpa.
- **Fora da sua lista (pequeno, e digo qual):** (a) uma frase de atualização nas linhas da LW-082 e da LW-083 do status, porque diziam "não verificado na janela" e a sua passada fechou isso; (b) notas de F3 em `app.md` e `tools.md` (documentos de contrato, não protegidos); (c) no README, "a conversa vista na janela por Arthur" e a ressalva da LW-082 fechada. Se preferir sem, desfaço.
- **O hash da tag não está nos documentos** (a tag aponta para o commit que os contém). Na Fase 1 houve um commit seguinte, "registro da tag" (`307a9db`); aqui não o fiz, porque a sua ordem foi tag no commit final. Se quiser o registro, é um commit só de documentos, e preciso do seu pedido.
- Proposta de entrada para `DECISIONS.md`: nenhuma nova.

5. TESTES EXECUTADOS
- `tools/check_all` no `main` `9dbcebc` (antes de editar, para citar no relatório): **VERDE**, 124 scripts, 1.194 testes, 261.693 asserts, 313 scripts sem aviso, 0 erros de script, 170 s.
- `tools/check_all` **no HEAD final `8dcc81d`**: **VERDE**, 124 scripts, **1.194 testes (todos passando)**, 261.693 asserts, 313 scripts sem aviso de compilação, 0 erros de script, 3 min 27 s ("Warnings 1 / Deprecated 1" do GUT, o de sempre).
- `check_architecture`, `check_input_keys`, `check_literal_text`: verdes.
- Contagem **por grep, antes** (status/README): `31 de 32` 1/2, `86 de 192` 1/2, `96,9` 1/2, `44,8` 1/2, `32 de 32` 0/0, `87 de 192` 0/0, `45,3` 0/0. **Depois, no arquivo e no `main` remoto (`git show origin/main:…`):** `32 de 32` 1/2, `87 de 192` 1/2, `45,3` 1/2, e os quatro antigos 0/0; 32 de 32 linhas de tarefa da Fase 2 concluídas (script) e 32 IDs únicos na lista do cabeçalho.
- NÃO EXECUTADO: oráculo, soak de 30 dias e `run_sim` contra o `main` (só documentos; nada em `src/`, `data/` ou `tests/`).

6. RESULTADOS (Fase B)
B0: `git fetch origin '+refs/heads/main:refs/remotes/origin/main'`; o `main` não andou (`9dbcebc`); **só o `main`**, nenhum ramo `lw-087*` foi juntado. B1: um commit (`8dcc81d`). B2: verde. B3: `git push origin HEAD:refs/heads/main` (`9dbcebc..8dcc81d`, avanço simples, sem `--force`) e ramo `lw-086-fechamento-fase-2`. **Tag:** `git tag fase-2-concluida 8dcc81d` (tag **leve**, `git cat-file -t` = `commit`, como `fase-0-concluida` e `fase-1-concluida`; `git tag -n` mostra o assunto do commit) e `git push origin refs/tags/fase-2-concluida`; `git ls-remote --tags` lista as três. A tag aponta para o commit final do `main`. Nenhuma tag além dessa.

7. PROBLEMAS ENCONTRADOS
- **F3 (levantamento, só leitura):** no **jogo**, o texto da dica do painel diz F3: `data/text/pt_br.json:27` (`tools.npc_inspector.hint`: "F3 ou Tab fecha · N próximo · B anterior · T marca o rastro"). O HUD e o código de `src/presentation` não citam F3. Também citam F3, sem mudar nada: comentários de `src/app/input_actions.gd:27` e `src/tools/npc_inspector/npc_inspector_panel.gd:125`, os testes `test_npc_inspector_activation.gd` e `test_input_actions.gd` (a tecla ligada é F3 de fato, `KEY_F3`). **Anotado em `docs/backlog.md` (linha 180) e aqui; nenhum código nem dado do jogo foi mexido.**
- **Protegidos que citam F3 e não toquei:** `DECISIONS.md` (DEC-125, "Abre e fecha com F3 (e Tab)", e o texto da DEC-128 sobre a tecla ligada) e `docs/decisions/0011-revisao-fase-2.md` descrevem a tecla ligada (continua verdadeiro); `DEVELOPMENT_ROADMAP.md` só tem nós de um diagrama chamados "F3".
- A sua mensagem chegou duas vezes na conversa (a primeira cortada no meio da Tarefa 3); tratei como uma só, com o texto completo da segunda.

8. RISCOS
- A tag está no `main` e no remoto; apagar ou mover tag exige o seu pedido (AGENTS 10.6).
- A dica do painel no jogo ainda diz F3: quem ler só a tela vai tentar F3 no Mac.

9. PENDÊNCIAS
- LW-093b no roadmap (A, LW-087a). Registro no `DECISIONS.md` de DEC-047/049/054 e da escala da Fase 3 (seu). Divergências do roadmap com decisões suas (LW-097, LW-111, LW-114, `mint`). Texto da dica (backlog).
- Teste manual: nenhum novo.

ACOMPANHAMENTO
- Avanço: **Fase 2 CONCLUÍDA, 32 de 32 (100%)**; projeto 87 de 192 (45,3%). Fase 3 não iniciada.
- Próxima tarefa recomendada: LW-087a (A). **Não iniciada.**
- Git: `main` = `8dcc81d`; tag `fase-2-concluida` = `8dcc81d` (leve), enviada; ramo `lw-086-fechamento-fase-2` enviado; worktree `.worktrees/lw-086`. Neste ramo `status-c`: só `STATUS-C.md` e `REVISAO-085-C.md`.
