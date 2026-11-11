11/11/2026 07:54 (Brasília) · CONCLUÍDA · LW-087a: no `main` (`63caee7`) pelo seu "APROVADO LW-087a" (Fase B: `main` sem mudança até aqui, `check_all` verde, placar igual por `grep`, só os arquivos citados, sem tag); o Godot da A está parado

# RELATÓRIO — LW-087a (Fase B): o registro da Fase 3 entra no `main`     Status: PRONTA PARA REVISÃO (já no `main` pelo seu `APROVADO LW-087a`; falta a sua auditoria do texto)

## 1. RESUMO
Você digitou `APROVADO LW-087a`; fiz a Fase B nas mesmas condições da LW-085e. O `main` não tinha andado (`8dcc81d`), então não houve junção; acrescentei a linha de status da subtarefa; o `check_all` ficou verde no HEAD final; o `main` foi de `8dcc81d` para `63caee7` por avanço simples (fast-forward). Sem tag. **Interpretação, dita com todas as letras:** a LW-087a nunca teve a frase definida como gatilho da Fase B (nas rodadas eu tinha "não autorizada"); entendi o seu `APROVADO LW-087a` como o aval pedido na pendência (3) do meu relatório anterior. Se não era isso, o desfazer é uma decisão sua (não uso `--force`).

## 2. ARQUIVOS CRIADOS
- Nenhum nesta fase (o `0012` foi criado nas rodadas anteriores e agora está no `main`).

## 3. ARQUIVOS MODIFICADOS (o que o `main` ganhou, contra `8dcc81d`)
- `docs/DECISIONS.md` — DEC-129 a DEC-178 (50 entradas), as DEC-047, 049 e 054 aprovadas, as 35 decisões do pré-voo aprovadas em bloco, versão 0.10.
- `docs/DEVELOPMENT_ROADMAP.md` — LW-087 em 087a a 087d; LW-088a, 093a, 093b e 096a; ajustes nas LW-089 a 111 e 114; Anexo D, critério 3.F item 4 e a nota de divergências.
- `docs/decisions/0012-pre-voo-da-fase-3.md` — o registro técnico, até a seção 10.
- `docs/backlog.md` — uma linha (consumo de roupa e ferramenta pessoal pelo NPC, fora da Fase 3).
- `docs/ROADMAP_STATUS.md` — **uma linha** (LW-087a, na tabela "Tarefas extras", como subtarefa; a contagem não muda).
- **Arquivos protegidos tocados:** só `docs/DECISIONS.md` e `docs/DEVELOPMENT_ROADMAP.md`, os dois que você autorizou. Nada de código, dado, teste, `AGENTS.md`, `README.md`, GDD, arquitetura ou `project.godot`.

## 4. DECISÕES TÉCNICAS
- **Fase B:** B0 `main` já dentro do ramo (sem junção); B1 commit de status `63caee7`; B2 `check_all`; B3 ensaio (`--dry-run`) e `git push origin lw-087a-registro-fase-3` e `git push origin HEAD:refs/heads/main`, **sem `--force`**; B4 este relatório.
- **Onde pus a linha de status:** na tabela "Tarefas extras (não entram na conta)", porque o arquivo ainda não tem seção da Fase 3 (a Fase 3 não começou) e a LW-087 só se fecha com as partes 087b a 087d.
- **Proposta de entrada para `DECISIONS.md` / pedido de desvio:** nenhum.

## 5. TESTES EXECUTADOS
- `git fetch origin '+refs/heads/main:refs/remotes/origin/main'`: `main` em `8dcc81d` antes de empurrar; `git merge-base --is-ancestor origin/main HEAD`: avanço simples possível.
- Placar por `grep`, antes e depois (e no `main` pelo `git show`): `ROADMAP_STATUS.md` 1 vez "32 de 32" e 1 vez "87 de 192"; `README.md` 2 e 2. **Igual.**
- Recontagem por script no HEAD final: `índice=178 cabeçalhos=178 repetidos=nenhum · CONFERE`; **APROVADA 120 (20 com ressalva) · PROPOSTA 29 · PENDENTE 18 · DESCARTADA 10 · SUBSTITUÍDA 1 = 178**.
- **`tools/check_all` no HEAD final `63caee7` (07:49:49 a 07:53:24, 11/11/2026): VERDE** (`EXIT_CODE_CHECK_ALL=0`): 124 scripts, **1.194 testes, 1.194 passando, 0 falhando**, 261.693 asserts, 180,9 s; 313 scripts sem aviso de compilação; nenhum "SCRIPT ERROR" nem "Parse Error".
- Depois do envio: `main` remoto `63caee7`; ramo `lw-087a-registro-fase-3` remoto `63caee7`; tags remotas `fase-0-concluida`, `fase-1-concluida` e `fase-2-concluida`, **nenhuma nova**.
- **NÃO EXECUTADO:** oráculo, vida de 30 dias e `run_sim` fora do `check_all` (só documentos).

## 6. RESULTADOS
- Todas as condições da Fase B foram cumpridas: junção sem conflito (nem houve), `check_all` verde, só os arquivos citados entre os protegidos, contagem inalterada por `grep`, sem tag.
- **O que agora vale no `main`:** as 120 decisões APROVADAS (35 delas aprovadas por você em bloco em 11/11/2026), com os limites de que a aprovação não autoriza editar fixture protegida (DEC-172) nem transforma valor [HIP] em requisito; o `run_sim` não muda; os três marcos de hash por bloco (DEC-175).

## 7. PROBLEMAS ENCONTRADOS
- **A interpretação do `APROVADO LW-087a`** (item 1): é a única coisa que não estava escrita de antemão.
- **Os contratos da `economy`, dos dados e dos eventos (087b a 087d) e as extensões do `world` e do `npc` NÃO estão no `main`:** seguem como rascunhos em ramos e ainda têm as divergências que listei na rodada 4 (marcos por tarefa, `site_upkeep` sem o tecido, estoque inicial sem o tecido, `run_sim`). O `main` já diz o que vale; esses documentos precisam ser alinhados antes de entrarem.

## 8. RISCOS
- Os rascunhos 087b a 087d, quando entrarem, podem contradizer o registro que já está no `main` (acima).
- A **LW-097** concentra muitas decisões (terreno, rotas, 10 locais `work`, `work_place_id`, estoque dos importados com tecido, teste de distribuição e o marco 3 de hash); a distribuição 14/6/20/10 **ainda não tem entrada** (próximo número: DEC-179).
- A linha de status usa "concluída" porque o texto da LW-087a está no `main`; a LW-087 inteira **continua pendente**.

## 9. PENDÊNCIAS
- **Para você decidir:** (1) a entrada da distribuição 14/6/20/10, ao preparar a LW-097 (você já disse sim); (2) dividir ou não a LW-097; (3) em que ordem a B e a C alinham os contratos (087b a 087d) para irem ao `main`.
- **Teste manual:** nenhum (só texto).

## ACOMPANHAMENTO
- **Avanço:** a Fase 3 não começou; a LW-087 tem a parte 087a no `main` e as partes 087b a 087d pendentes. Contagens do status e do `README.md` inalteradas (Fase 2 em 32 de 32; projeto em 87 de 192).
- **Próxima tarefa recomendada:** o alinhamento dos contratos 087b a 087d ao registro; depois a LW-088a. **Não iniciada.**
- **Decisões que dependem de você:** as três acima.
- **Git:** `main` em `63caee7` (era `8dcc81d`), avanço simples; ramo `lw-087a-registro-fase-3` em `63caee7`; `status-a` atualizado; **nenhuma tag nova**, sem `--force`.
