10/11/2026 17:59 (Brasília) · rodando · LW-085 Fase B (APROVADO LW-085): check_all no HEAD final; o relatório abaixo é o da LW-086a e será substituído ao parar

RELATÓRIO — LW-086a (DOC): preparação da validação da Fase 2        Status: PRONTA PARA REVISÃO (já no `main` pela Fase B automática; a auditoria de Arthur não foi feita)

Li antes: AGENTS (inteiro), `docs/DEVELOPMENT_ROADMAP.md` (2.A, 2.C, 2.F, 2.G, 2.H, 2.I, 2.J, linhas da LW-054 e LW-086 e o Anexo D), `docs/fase-1/LW-054-roteiro-para-arthur.md` e `LW-054-relatorio-de-fechamento.md` (formato), `docs/ROADMAP_STATUS.md`, `docs/modules/npc.md`, os 18 arquivos de teste que cito (cabeçalhos e nomes dos testes; os principais lidos por inteiro), os dados (`routine_blocks`, `actions`, `places`, `settlements`, `needs`, `pt_br.json`), `README.md` e os relatórios da A (085a) e da B (084 e 085c). Decisões: DEC-122 (você aceitou o "por ora"), DEC-119 (régua de quadros), DEC-083/084, DEC-040 e DEC-071 ([HIP]).

1. RESUMO
O roteiro da sua validação está no `main`, no mesmo lugar e formato da Fase 1 (`docs/fase-2/`). Os 8 itens da checklist 2.H têm "faça na janela" ou "prova automática" (comando exato, o que o teste prova, resultado de hoje), há uma sessão de janela de cerca de 13 minutos, perguntas de fluidez e a tabela de 2.F e 2.J com o que falta. **Dois pontos sem prova automática estão ditos com todas as letras: o teleporte (item 2) e o item 8.** Um worktree pronto abre a janela com um comando. Nenhum código, tecla ou comando novo.

2. ARQUIVOS CRIADOS
- `docs/fase-2/LW-086-roteiro-para-arthur.md` (217 linhas) — o que você faz: abrir o jogo, teclas, os 8 itens, fluidez, como responder, resultado de hoje dos testes
- `docs/fase-2/LW-086-relatorio-de-fechamento.md` (112 linhas) — RASCUNHO: números, entregáveis, tabelas 2.F e 2.J, retrospectiva e decisões antes da Fase 3
- Worktree `/Users/arthurlk/LivingWorld/.worktrees/validacao-fase-2` (fora do repositório; em `origin/main` `7cb70f2`, importação feita)

3. ARQUIVOS MODIFICADOS
- `docs/ROADMAP_STATUS.md` — +1 linha (a da LW-086a, de subtarefa). A contagem não mudou: script e `grep` antes e depois iguais ("30 de 32" ×1 no status e ×2 no README; "85 de 192" ×1 e ×2; 30 de 30 linhas de tarefa concluídas). Escrevi a linha sem repetir esses números, de propósito. A LW-086 não foi contada.

4. DECISÕES TÉCNICAS
- **Lugar e formato:** `docs/fase-2/`, o mesmo par da Fase 1 (roteiro + fechamento); por isso dois arquivos em vez de um `docs/validacao-fase-2.md`.
- **Como a janela cabe em 13 minutos:** uma sessão só, a 2x (1 minuto real = 96 de jogo). Corra a 1x até o povoado A (chega às ~06:15, a tempo de ver o povoado acordar) e aperte 2 ao chegar; os itens 1, 2, 3, 5 e 8 acontecem em paralelo enquanto o dia passa (22:00, "voltar a dormir", cai no minuto ~10). Tempos são **[estimativa]**, não medi com a janela.
- **O que é janela e o que é prova** (sem teclas novas): janela = 1, 2, 3, 8 e a conversa do 5; prova = 4 (alarme), 6 (dias acelerados), 7 (comida a zero) e salvar e recarregar do 5. Cada teste citado foi **lido e rodado hoje**; só citei o que prova mesmo o que o item pede.
- **Sem prova, dito com todas as letras:** (a) **teleporte:** só o spike SP2 (descartável, fora do `check_all`) e a janela; (b) **item 8:** não há teste GUT, só a busca por texto reproduzível e a janela; (c) **2.F #8:** ação nova só por JSON tem teste, **ofício novo não** (marquei "parcial").
- **Cuidado de fluidez:** com o painel aberto o resumo (`world.validate()`) roda a ~1 s e a 085c mediu ~20 ms por chamada com 300 NPCs; as perguntas P1 a P3 pedem o painel fechado e a P4 pergunta do tranco com ele aberto.
- Worktree em `origin/main` **detached**, `--import` feito; comando exato abaixo.
- **Proposta de entrada para `DECISIONS.md`:** nenhuma nova nesta tarefa (as do registro 0011 seguem no relatório da LW-085).

**Comando para abrir a janela (copiar e colar no Terminal):**
```bash
"/Applications/Godot 2.app/Contents/MacOS/Godot" --path /Users/arthurlk/LivingWorld/.worktrees/validacao-fase-2
```
Com o editor: o mesmo comando mais `--editor`, e F5. Fechar: Command+Q.

5. TESTES EXECUTADOS
- Lote das provas citadas (`tools/run_tests <arquivo>`, 18 arquivos, em `origin/main` `d1b0fa2`): **todos VERDES** (alarme 11/11; necessidade crítica 17/17; `FoodStub` 19/19; conversa com salvar e recarregar 1/1; corpos na cena real 5/5, corpos na tela 7/7, pool 10/10, LOD 20/20; rastro 10/10, ponte do rastro 6/6, painel 6/6; limite de T2 13/13; catálogo 17/17; equivalência 4/4; vida de 7 dias 4/4; ano curto 4/4; oráculo 2/2; impasse × conversa 2/2).
- `tests/soak/run_npc_life_30d` (3 execuções, 26 s cada): vivos no mínimo 100, parado 0 min, problemas 0, hash `d13b921112ce` nas três.
- `sh tools/check_architecture .`, `check_input_keys`, `check_literal_text`: verdes.
- `tools/check_all` **duas vezes** (HEAD `3fc9a04` e HEAD final `7cb70f2`): **VERDE**, 124 scripts, **1.194 testes**, 261.693 asserts, 313 scripts sem aviso de compilação, 0 erros de script, 3 min 31 s ("Warnings 1 / Deprecated 1" do GUT já existia).
- Fumaça do worktree da janela: `--headless --path ... --quit-after 300` rodou a cena principal sem erro. **A janela em si não foi aberta por mim** (é a sua passada).
- NÃO EXECUTADO: o ano de 300 NPCs (cita-se a LW-084; ~21 min por execução); oráculo, hash de 30 dias e `run_sim` contra o `main` (a tarefa é só documento; a Fase B de documento não os pede).

6. RESULTADOS
- Critérios 2.F: **7 cumpridos e 3 parciais** (2 desempenho: picos acima de 10 ms existem, você já os decidiu informativos; 3 LOD: teleporte e quadros dependem da sua janela; 8 dados: ofício novo por JSON sem teste). 2.J: **30 de 32 tarefas**, REV aguarda a sua frase, VAL é esta, tag não criada, status em 93,8%.
- Fase B (condições): junção sem conflito (avanço rápido de `d1b0fa2` por `3fc9a04` e `7cb70f2`), `check_all` verde no HEAD final, nenhum arquivo protegido (só `docs/ROADMAP_STATUS.md` e `docs/fase-2/`), contagem inalterada por grep, **sem tag**, sem `--force`.

7. PROBLEMAS ENCONTRADOS (todos meus)
- **Marcador solto no `main` por ~10 minutos:** o primeiro envio (`3fc9a04`) levou a palavra `RESULTADO_CHECK_ALL` no rascunho do fechamento. Achei na releitura e corrigi em `7cb70f2`, junto de outros acertos da releitura (a rotina de comer por ofício estava imprecisa para guardas e estalajadeiro; o marco de distância do item 2; um `go_to_place` antes do `sleep`). Refiz o `check_all`.
- Um comando meu travou esperando entrada (um `cat` sem arquivo) e custou uns 10 minutos; refiz pelo caminho certo. O primeiro `test_npc_year_short.gd` não imprimiu nada por cache de importação velho (a lição da Fase 1 voltou); com `--import` passou, e o roteiro tem a observação.
- Os horários que escrevi nas linhas "rodando" deste arquivo estavam adiantados em até 25 minutos (17:05, 17:30 e 17:50, contra 17:08, ~17:20 e 17:25 reais); este ficou com a hora real.
- **A LW-085, no meu relatório final, dizia "085c pendente": já não é verdade** (a 085c entrou no `main` em `d1b0fa2`, 16:29). A linha da LW-085 que preparei (ramo local `lw-085-final`) vai ser atualizada com o resultado da 085c quando você digitar a frase.

8. RISCOS
- O cronograma de 13 minutos é uma conta, não uma medição na janela; se o povoado for mais difícil de achar sem coordenadas, passa de 13.
- Os textos do painel são ids crus em inglês; o roteiro avisa, mas pode confundir.
- O teleporte só tem a sua janela como prova.

9. PENDÊNCIAS
- **Sua passada na janela** (~13 min) e a conferência das provas; depois, "LW-086 assinada, com a ressalva de janela mais prova automática" ou a lista do que falhou (formato na seção 5 do roteiro).
- **LW-085, Fase B:** só quando você digitar exatamente **APROVADO LW-085** (a 085c já está no `main`; se não estivesse, eu esperaria 6 vezes 10 minutos). A contagem vai então para 31 de 32 e 86 de 192, com as mesmas condições e sem tag. **Ainda não digitou.**
- Tag `fase-2-concluida`: só com a sua autorização.

ACOMPANHAMENTO
- Avanço: LW-086a concluída e no `main`. Fase 2 segue em **30 de 32 (93,8%)**; projeto em **85 de 192 (44,3%)**. LW-085: relatório final entregue, em auditoria (não contada). LW-086: não feita.
- Próxima tarefa recomendada: **sua passada na janela (LW-086)** e, antes dela, **"APROVADO LW-085"** se concordar com o relatório. Não iniciadas.
- Decisões que dependem de Arthur: (1) as decisões do relatório da LW-085 (entrada no `DECISIONS.md`, AGENTS 4.5 e 5.2, régua de memória, resolução automática de conflito só de acréscimo no backlog); (2) aceitar os 3 critérios parciais de 2.F ou pedir testes pequenos (ofício novo por JSON; teleporte), recomendo pedir só o do ofício; (3) as decisões antes da Fase 3 (seção 7 do rascunho do fechamento).
- Git: `main` = `7cb70f2` (avanço rápido, sem `--force`, sem tag); ramo `lw-086a-roteiro-de-validacao` enviado (`3fc9a04`, `7cb70f2`); worktree `validacao-fase-2` só local; ramo local `lw-085-final` (linha da LW-085 em auditoria) **nunca enviado**. Neste ramo `status-c`: só `STATUS-C.md` e `REVISAO-085-C.md`.
