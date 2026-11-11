11/11/2026 12:25 (Brasília) — CONCLUÍDA: LW-117a (registro das decisões da Fase 4): DEC-202 a DEC-223 no DECISIONS.md (11 APROVADAS, 11 PROPOSTA), roadmap corrigido, 0013 no ramo; commit b3987ca ENVIADO ao ramo lw-117a-registro-fase-4 (fora do main); check_all VERDE (1.203 de 1.203). main = 9b4f6f0, intocado. Sem tag, sem --force. Parei (regra 13). Nada rodando.

# LW-117a — RELATÓRIO — Registro das decisões da Fase 4 no `DECISIONS.md` e no roadmap (DOC)        Status: PRONTA PARA REVISÃO

**Declaração do início (AGENTS 2.3), como escrita antes de editar.** Tarefa: registrar no `DECISIONS.md` as respostas de Arthur de 11/11/2026 (Q1 a Q22 do `0013`) e corrigir no roadmap as tarefas que elas mudam; só documentos; ramo `lw-117a-registro-fase-4` a partir do `main` (`9b4f6f0`); nada para o `main`. Li: AGENTS 0.4; o `0013` inteiro; `DECISIONS.md` do `main` (regras, índice, DEC-040, 041, 053 a 057 e DEC-163 a 165 e 178 como modelo); roadmap do `main` (0.13-B e C, Fase 4 inteira, nota e divergências da Fase 3 como modelo); `backlog.md`; de leitura apenas, os números de DEC que a Fase 5 já usa. Decisões de que dependo: APROVADAS 045, 046, 047, 049, 050, 051, 054, 062, 100, 127, 134, 141, 155, 157, 164, 165, 169, 174; PROPOSTA 038, 043, 052, 056, 077, 099; PENDENTES 040, 053 e 055 (não decido nenhuma: nota datada e seguem PENDENTES). Arquivos: `DECISIONS.md` e `DEVELOPMENT_ROADMAP.md` (protegidos; a tarefa manda), `0013` e, se coubesse, `backlog.md`. Dúvidas resolvidas por mim e relatadas abaixo: numeração a partir da DEC-202 e versão 0.12.

## 1. RESUMO
As 22 respostas viraram entradas do `DECISIONS.md`: **DEC-202 a DEC-212 APROVADAS** (Q1 a Q10 e Q22, suas) e **DEC-213 a DEC-223 PROPOSTA** (Q11 a Q21, do revisor, por pedido seu). As DEC-053 e DEC-055 ganharam só uma nota datada e **seguem PENDENTES**. O roadmap dividiu a LW-117 em 117a a 117f e corrigiu as tarefas LW-118 a LW-142 que as respostas mudam. Só documentos; nada foi para o `main`.

## 2. ARQUIVOS CRIADOS
- `docs/decisions/0013-pre-voo-da-fase-4.md` — **novo neste ramo** (veio do rascunho do ramo `lw-117-prevoo-fase-4`, que continua como estava): 345 linhas, com o estado atualizado, a tabela da seção 6.1 (pergunta → DEC) e quatro acertos de redação.

## 3. ARQUIVOS MODIFICADOS (commit `b3987ca`, ramo `lw-117a-registro-fase-4`)
- `docs/DECISIONS.md` — +342 e −11 linhas: 22 entradas novas; 22 linhas no índice por área; versão 0.12; totais; linha da seção 8; notas curtas nas DEC-050, 051, 053, 055, 155 e 164; notas nas duas linhas da seção 3.1 (DEC-053 e DEC-055); C1 da seção 4 passa a resolvida.
- `docs/DEVELOPMENT_ROADMAP.md` — +41 e −32 linhas: 4.B (escala e contradição resolvida), a LW-117 vira 117a a 117f, linhas das LW-118 a LW-142, nota e divergências de 4.D, mermaid, 4.F, 4.G, R4.9, 0.13-C e Anexo F.
- `docs/backlog.md` — +7 linhas (extorsão, reputação multidimensional, T3 completo, crime e justiça completos, satisfação agregada com T0, revenda de carga roubada, rota "perigosa" e terceira polity).

## 4. DECISÕES TÉCNICAS
- **Numeração: DEC-202 a DEC-223 e versão 0.12.** Os números DEC-179 a DEC-201 e a versão 0.11 já estão com o registro da Fase 5, que anda em paralelo (li o arquivo dele, sem tocar). Usei a partir da DEC-202 para as duas não colidirem. Alternativa: pegar a DEC-179 e fazer o outro renumerar. Se você preferir, renumero.
- **Status:** Q1 a Q10 e Q22 entraram como APROVADAS por você; Q11 a Q21, como "PROPOSTA (do revisor…; vale como padrão de trabalho e não é APROVADA)", como você pediu.
- **DEC-053 e DEC-055:** a resposta Q5 (abstrato; você não comanda na Fase 4) e Q6 (4 províncias) são parciais; por isso viraram DEC próprias (206 e 207) e as duas antigas receberam **nota datada, sem mudar o status**. O limite de combatentes com corpo e o tamanho final do mundo continuam sem decisão.
- **Notas em DEC antigas** (050, 051, 155, 164): só uma frase apontando para a entrada nova, no padrão das notas que a LW-087a pôs nas DEC-005, 045 e 053. Nenhuma foi reescrita.
- **A divisão 117a a 117f entrou no roadmap como proposta**, dita assim no texto. Você autorizou só a 117a.
- **Alocações que eu propus (marcadas "alocação proposta"):** os seis eventos novos nas tarefas LW-122, 123, 128, 134 e 135; a troca do pagador da folha dos postos na LW-123; o contrato `escort` publicado pela LW-125. As partes 117b a 117f confirmam ou mudam.
- **Não virou DEC:** o ID próprio da polity (achado 3 do `0013`) e a divisão da LW-117, porque não foram perguntas suas nem respostas técnicas numeradas.
- **Proposta de entrada para `DECISIONS.md`:** nenhuma além das 22 já registradas.

## 5. TESTES EXECUTADOS
- Contagem por script das linhas do índice: **no `main`, 178** (APROVADA 120, com 20 ressalvas; PROPOSTA 29; PENDENTE 18; DESCARTADA 10; SUBSTITUÍDA 1), igual à frase de totais; **depois, 200** (131, com as mesmas 20 ressalvas; 40; 18; 10; 1). 200 entradas `### DEC-`, todas no índice e nenhuma duplicada.
- Conferência por script: cada uma das 22 entradas tem os 7 campos; nenhuma linha de campo com `|` a mais; **toda DEC citada nas linhas novas existe**; só o cabeçalho, a frase de totais e a linha 0.12 citam DEC-179 e DEC-201 (de propósito); **zero** citações a `STATUS-`, `status-*`, "da A/B/C" ou ao pré-voo da Fase 5 nas linhas novas dos quatro arquivos (a única menção ao `0014` é a frase que explica por que ele não foi criado, e ela foi reescrita sem o número).
- As 36 trocas de texto nas linhas do roadmap foram por texto exato, cada uma com uma só ocorrência; nenhuma falhou.
- `git diff --staged --check`: sem erro de espaço em branco.
- Teste de junção, só leitura (`git merge-tree --write-tree`), contra o ramo `lw-146a-registro-fase-5` (`11e179f`): o **roadmap junta sozinho** e o **`DECISIONS.md` dá 28 conflitos de texto** (início do arquivo, índice, totais, seção 8 e o fim das entradas).
- `tools/check_all` **no HEAD final `b3987ca`**: **VERDE.** Arquitetura (nove verificações), GDScript sem avisos, dados válidos, **125 scripts, 1.203 testes (todos passando), 262.120 asserts**, 204,3 s de testes. Mesmos números do `main`, como esperado numa tarefa só de documentos.
- NÃO EXECUTADO: nada além do que é próprio de uma tarefa só de documentos (sem oráculo, soak ou `run_sim`).

## 6. RESULTADOS
Critério cumprido por leitura do diff e pelos scripts acima: cada resposta Q1 a Q22 tem uma DEC com o status certo (tabela 6.1 do `0013`); as divergências do roadmap listadas na seção 6 do `0013` estão nas linhas das tarefas e na nota de 4.D.

## 7. PROBLEMAS ENCONTRADOS
1. **Junção com o registro da Fase 5:** os dois mexem no fim do `DECISIONS.md`, nos totais, no índice e na seção 8. Quem entrar depois resolve 28 trechos à mão e recontar os totais. O roadmap não conflita.
2. **Tempo verbal:** no rascunho eu escrevi "a Fase 3 já criou" os três povoados; ela só **cria** na LW-097 (a DEC-142 diz isso). Corrigi no `0013` e nas entradas novas.
3. **A DEC-213 diverge da arquitetura 5.2** ("dono político" na `Province`, no `world`). A arquitetura é arquivo protegido e não foi mexida; a divergência está dita na entrada.
4. **O nome `0014`** já é do pré-voo da Fase 5; não criei arquivo novo em `docs/decisions/`, ao contrário do que a seção 3 do `0013` previa para a 117a. Ajustei essa linha.
5. O `git worktree add` deixou o ramo `lw-117a-registro-fase-4` com o `origin/main` como ramo de acompanhamento; por isso o envio foi com o nome do ramo escrito por inteiro, para não ir ao `main`.

## 8. RISCOS
- A numeração e a versão 0.12 supõem que o registro da Fase 5 entra antes; se entrar depois, só a versão e a ordem da seção 8 mudam (os números DEC não colidem).
- As DEC-213 a DEC-223 são PROPOSTA: valem como padrão de trabalho, não obrigam. Se você trocar alguma, a linha do roadmap correspondente também muda.
- DEC-222: risco de pagar o mesmo guarda duas vezes (posto e soldo); o contrato de `factions` (117c) tem de separar os dois.
- Pontos que seguem sem decisão: cultura de cada país e os 4 parâmetros; dono da província de fronteira; "imposto de entrada" × tarifa; cobrança da multa e evento de teste do crime; valores das multas; nomes das 5 faixas de reputação; nomes e doutrina das 3 facções.

## 9. PENDÊNCIAS (decisões que dependem de Arthur, cada uma com a recomendação)
1. **Aprovar ou trocar a 117a** (DEC-202 a DEC-223 e as correções do roadmap). Recomendo aprovar.
2. **Ordem de entrada no `main`:** este registro e o da Fase 5. Recomendo o da Fase 5 primeiro (já tem a versão 0.11) e este depois, com os 28 conflitos resolvidos por quem fizer a Fase B.
3. **Próxima parte da LW-117:** recomendo a **117b** (contrato da economia, a que mais destrava as outras). Não iniciada.
4. Teste manual: nenhum (só documentos).

## ACOMPANHAMENTO
- Avanço: **Fase 4: 1 das 6 partes da LW-117 feita (117a)**; as tarefas LW-118 a LW-145 não começaram e dependem da Fase 3. Projeto sem mudança de contagem (nenhuma tarefa nova concluída).
- Próxima tarefa recomendada: **LW-117b**. **Não iniciada.** Parei (regra 13).
- Git: `ramo `lw-117a-registro-fase-4` com **um** commit (`b3987ca`, mensagem "LW-117a: registro das decisões da Fase 4 (DEC-202 a DEC-223), roadmap e pré-voo 0013") e **enviado**, com o nome do ramo escrito por inteiro; `status-c` enviado com este relatório; `main` = `9b4f6f0`, intocado (conferido no remoto depois do envio); ramo `lw-117-prevoo-fase-4` não mexido; ramo e worktree do registro da Fase 5 só lidos; sem tag, sem `--force`.`

---

# LW-117 (PRÉ-ETAPA), AJUSTE DA Q3 — RELATÓRIO — Segunda atualização do 0013 (DOC, rascunho fora do `main`)        Status: PRONTA PARA REVISÃO

**Declaração do início (AGENTS 2.3).** Arthur mudou por mensagem: confirmou Q1, Q2 e Q5 a Q10, manteve a Q4, **mudou a Q3** (mantém a "pena de crime" como multa, com a lista de atos em dados; a fonte do crime vem da Fase 5 e, na Fase 4, testa-se com um evento de teste) e passou **Q11 a Q21** para o revisor, como PROPOSTA, seguindo as recomendações. Como a autorização anterior de commit já tinha sido usada, **editei o arquivo e parei** até ele autorizar; depois ele autorizou **1 commit** no ramo `lw-117-prevoo-fase-4` e o push desse ramo e do `status-c`. Só o 0013; nada no `main`, sem tag, sem `--force`.

## 1. RESUMO
A seção 6 do 0013 agora traz a Q3 nova (que substitui "proibição de bem"), os status finais (Q1, Q2, Q5 a Q10 confirmadas; Q4 mantida; Q11 a Q21 PROPOSTA do revisor; Q22 dele) e dois pontos novos em aberto que a Q3 cria.

## 2. ARQUIVOS CRIADOS
- Nenhum.

## 3. ARQUIVOS MODIFICADOS (commit `debea7e`, "LW-117: ajusta a Q3 e o status das técnicas no levantamento de pré-voo da Fase 4")
- `docs/decisions/0013-pre-voo-da-fase-4.md`: +8 e −6 linhas (agora 316 linhas). Nenhum outro arquivo; contra o `main` o ramo difere só nele.

## 4. DECISÕES TÉCNICAS
- **Q3 (decisão de Arthur):** a "pena de crime" fica como multa; as 5 leis são as do roadmap (tarifa, imposto de entrada, conscrição, pena de crime e licença); atos em dados (agressão, roubo, morte e contrabando, da Fase 5); evento de teste na Fase 4. A "proibição de bem" deixa de ser lei e continua só como capacidade da `TradeRules`.
- **Q11 a Q21:** "PROPOSTA do revisor, seguindo a recomendação"; Q22 anotada como dependente da Q21 (agora PROPOSTA).
- **O que as respostas mudam no roadmap:** a frase da lista de leis foi trocada por "as 5 leis ficam como no roadmap, mas a pena vira multa, com lista de atos em dados e sem fonte de crime na Fase 4".
- **Novos pontos em aberto (o revisor propõe, nada foi decidido):** como a multa é cobrada (comando da economia, motivo `fine`, quem publica o evento de teste, falta de saldo) e a lista de atos e valores (dados [HIP]). Proposta de entrada para `DECISIONS.md`: nenhuma nova.

## 5. TESTES EXECUTADOS
- `tools/check_all` **no HEAD `debea7e`**: **VERDE**. Arquitetura (nove verificações), GDScript **sem avisos** (314 scripts), dados válidos, **125 scripts, 1.203 testes (todos passando), 262.120 asserts**, 170,5 s (3 min 23 s no total).
- `git push origin lw-117-prevoo-fase-4`: `1a56128..debea7e` (avanço simples); o remoto confere (`debea7e`); `main` (`9b4f6f0`) e tags não mudaram.

## 6. RESULTADOS
Aprovados: `check_all` inteiro (1.203 de 1.203); falhos e pulados: 0. Critério cumprido por leitura do diff (8 linhas).

## 7. PROBLEMAS ENCONTRADOS
- A recomendação original da Q3 e a pergunta continuam nas seções 1 a 5 do 0013 (inclusive o achado 8 sobre "pena de crime sem crime"); a seção 6 diz que foram trocadas. É de propósito (guardar o raciocínio), mas quem ler só a seção 4 vê a recomendação antiga.
- O ramo segue **1 commit atrás do `main`** (`9b4f6f0`); não juntei (não autorizado; arquivo novo, sem conflito possível).

## 8. RISCOS
- As respostas ainda **não estão no `DECISIONS.md` nem no roadmap** (parte 117a).
- A Q3 deixa a "pena de crime" sem fonte na Fase 4: só um evento de teste a exercita, então a multa não aparece no jogo até a Fase 5.

## 9. PENDÊNCIAS (decisões que dependem de Arthur, cada uma com a recomendação)
1. **Autorizar a parte 117a** (registro das respostas no `DECISIONS.md` e no roadmap) (**recomendo**).
2. Deixar o revisor propor os pontos em aberto da seção 6 (cultura de cada país, província de fronteira, "imposto de entrada", como a multa é cobrada, nomes e doutrina das facções) (**recomendo**).
3. Teste manual: nenhum.

## ACOMPANHAMENTO
- Avanço: **Fase 2 CONCLUÍDA (32 de 32, 100%)**; projeto 87 de 192 (45,3%). **Fase 3** com a A e a B; **Fase 4 não iniciada** (só a pré-etapa da LW-117, respondida).
- Próxima tarefa recomendada: **LW-117a** (registro). **Não iniciada.** Parei aqui (regra 13).
- Git: `lw-117-prevoo-fase-4` enviado (`debea7e`); `status-c` enviado com este relatório; `main` = `9b4f6f0` (não alterado por mim); sem tag, sem `--force`.

---

# LW-117 (PRÉ-ETAPA), ATUALIZAÇÃO — RELATÓRIO — Respostas de Arthur registradas no 0013 (DOC, rascunho fora do `main`)        Status: PRONTA PARA REVISÃO

**Declaração do início (AGENTS 2.3).** Depois do levantamento (`a634f9e`), Arthur respondeu **por painel de decisões, em 6 lotes**, as 21 perguntas do 0013 e autorizou, por escrito, **1 commit** no ramo `lw-117-prevoo-fase-4`, só em `docs/decisions/0013-pre-voo-da-fase-4.md`, com o push só desse ramo e do `status-c`; nada no `main`, sem tag, sem `--force`. Li as respostas e o próprio 0013. **Dúvida declarada:** ao cruzar as respostas, a **Q9** (criminosa vive de assaltos) e a **Q21** (carga roubada destruída) **se contradiziam**; perguntei a Arthur (Q22) antes de gravar.

## 1. RESUMO
O 0013 ganhou a **seção 6 "Respostas de Arthur"** (tabela Q1 a Q22), a lista do que as respostas mudam no roadmap e quatro pontos pequenos que continuam em aberto. As seções 1 a 5 ficaram como foram escritas. O ramo está enviado; **o rascunho continua fora do `main`**.

## 2. ARQUIVOS CRIADOS
- Nenhum.

## 3. ARQUIVOS MODIFICADOS (commit `1a56128`, "LW-117: registra as respostas de Arthur no levantamento de pré-voo da Fase 4")
- `docs/decisions/0013-pre-voo-da-fase-4.md`: +41 e −2 linhas (agora 314 linhas): status do cabeçalho, aviso no resumo, seção 6 nova e o "próximo passo". Nenhum outro arquivo; contra o `main` o ramo difere só nele.

## 4. DECISÕES TÉCNICAS
- **As respostas (resumo; a tabela completa está na seção 6 do 0013):** Q1 jogador entra na autoridade e na mercantil; Q2 duas culturas contrastantes; Q3 "pena de crime" vira "proibição de bem"; **Q4 o povoado C é do país vizinho**; Q5 guerra em escala pequena, resolução abstrata e o jogador não comanda (responde a DEC-053); Q6 4 províncias; Q7 reputação de um número em 5 faixas; Q8 save sem congelar (a LW-142 rejeita); Q9 assaltos e contribuição; Q10 um governante por país; **Q11 a Q21 todas na recomendação do revisor, escolhidas uma a uma por Arthur;** **Q22 o assalto leva o dinheiro do comerciante e a carga é destruída.**
- **Rótulos:** Q1 a Q10 e Q22 são "decisão de Arthur"; Q11 a Q21 são "recomendação do revisor, escolhida por Arthur". O registro no `DECISIONS.md` e as correções do roadmap ficam para a parte 117a. Proposta de entrada para `DECISIONS.md`: nenhuma nova.
- **Em aberto (seção 6, "o revisor propõe"):** qual cultura é de qual país; de quem é a província de fronteira; como o "imposto de entrada" difere da tarifa; nomes e doutrina das 3 facções.

## 5. TESTES EXECUTADOS
- `tools/check_all` **no HEAD `1a56128`**: **VERDE**. Arquitetura (nove verificações), GDScript **sem avisos** (314 scripts), dados válidos, **125 scripts, 1.203 testes (todos passando), 262.120 asserts**, 171,4 s (3 min 25 s no total).
- Por busca: o documento não cita arquivos de status nem letras de conversa. `git push origin lw-117-prevoo-fase-4`: `a634f9e..1a56128` (avanço simples); o remoto confere (`1a56128`); `main` e tags não mudaram.
- NÃO EXECUTADO: nada fora do previsto.

## 6. RESULTADOS
Aprovados: `check_all` inteiro (1.203 de 1.203); falhos e pulados: 0. Critério cumprido por leitura do diff.

## 7. PROBLEMAS ENCONTRADOS
- **A contradição Q9 × Q21** (resolvida pela Q22) foi minha: as duas recomendações, lidas juntas, deixavam a criminosa sem renda. A seção 6 registra a resolução.
- O ramo continua **1 commit atrás do `main`** (`9b4f6f0`); não juntei (não autorizado; o arquivo é novo, sem conflito possível).
- O 0013 tem 314 linhas (pedido original: cerca de 250).

## 8. RISCOS
- As respostas ainda **não estão no `DECISIONS.md` nem no roadmap**: valem como registradas neste rascunho até a parte 117a.
- Q4 (C é do vizinho) e Q6 (4 províncias) mudam dados do `world` e a distribuição econômica da Fase 3: a tarifa alta ou a fronteira fechada pode derrubar A e B (o C produz minério, metal e ferramenta). Mitigação já escrita: faixas das leis em dados e calibração no soak de 1 ano.

## 9. PENDÊNCIAS (decisões que dependem de Arthur, cada uma com a recomendação)
1. **Autorizar a parte 117a** (registro das respostas no `DECISIONS.md` e no roadmap, por quem faz o registro) (**recomendo**).
2. **Responder os 4 pontos pequenos em aberto** ou deixar o revisor propor (**recomendo** deixar o revisor propor, como PROPOSTA).
3. Teste manual: nenhum.

## ACOMPANHAMENTO
- Avanço: **Fase 2 CONCLUÍDA (32 de 32, 100%)**; projeto 87 de 192 (45,3%). **Fase 3** com a A e a B; **Fase 4 não iniciada** (só a pré-etapa da LW-117, agora respondida).
- Próxima tarefa recomendada: **LW-117a** (registro). **Não iniciada.** Parei aqui (regra 13).
- Git: `lw-117-prevoo-fase-4` enviado (`1a56128`); `status-c` enviado com este relatório; `main` = `9b4f6f0` (não alterado por mim); sem tag, sem `--force`.

---

# LW-117 (PRÉ-ETAPA) — RELATÓRIO — Levantamento de pré-voo da Fase 4 (DOC, rascunho fora do `main`)        Status: PRONTA PARA REVISÃO

**Declaração do início (AGENTS 2.3).** Tarefa: um único documento novo, `docs/decisions/0013-pre-voo-da-fase-4.md`, com (1) decisões de que a Fase 4 depende e seus status, (2) contradições e buracos entre GDD, arquitetura, roadmap, `DECISIONS.md` e contratos no `main`, (3) divisão sugerida da LW-117, (4) perguntas numeradas, (5) riscos e backlog. **Não é o contrato da LW-117**, não decide nada, não escreve contrato, código, dados nem eventos e não altera `docs/events.md`. Autorização escrita de Arthur: ramo `lw-117-prevoo-fase-4` a partir de `origin/main`; 1 commit; push só desse ramo e do `status-c`; nada para o `main`; sem tag nem `--force`. Li: roadmap 4.A a 4.J; `DECISIONS.md` (índice e DEC-038, 043, 045, 050 a 055, 077, 083, 099, 127, 134); GDD 5.1, 8.6, 10, 11, 14, 15, 19.4, 20, 24; arquitetura 5.2, 11.8, 12, 13, 14, 17.5, 17.7; `npc.md`, `world.md`, `economy.md`, `events.md`. Sem dúvida que me fizesse parar.

## 1. RESUMO
O documento diz que a LW-117 **não deve ser escrita antes das suas respostas**. Achou **18 contradições ou buracos**, **3 decisões PENDENTES que travam tarefas** (DEC-053, 055 e 040) e **6 PROPOSTAS** que valem como padrão de trabalho (DEC-038, 043, 052, 056, 077, 099), e traz **21 perguntas**: Q1 a Q10 de jogo (só você decide) e Q11 a Q21 técnicas (o revisor decide, como PROPOSTA).

## 2. ARQUIVOS CRIADOS
- `docs/decisions/0013-pre-voo-da-fase-4.md` (275 linhas; seções 0 a 5 e validação).

## 3. ARQUIVOS MODIFICADOS
- Nenhum. O ramo difere do `main` **só** nesse arquivo (conferido por `git diff --name-only origin/main...HEAD`); `docs/events.md` ficou igual.

## 4. DECISÕES TÉCNICAS
- **Os seis achados que mais pesam:** (1) não se diz **onde fica a polity vizinha** (DEC-051 não proíbe população, o roadmap diz "nenhum NPC T1"); (2) **três fontes dão o "controle" da província a três donos** (arquitetura 5.2, DEC-050 e o roadmap/GDD 10.3); (3) a economia **não sabe receber uma política real** (troca da `TradeRules`, destino da tarifa, tipos de dono e motivos do `Ledger` fechados); (4) **"pena de crime" é uma das 5 leis e nenhuma tarefa cria crime**; (5) o `npc` precisa de mudanças que a LW-117 não lista (T3, satisfação, rumores em T1, baixas e "em missão"); (6) a LW-142 manda **migrar** o save e a DEC-134 manda **rejeitar**.
- **As 3 perguntas que o roadmap deixa para você:** Q1 (tipos das 3 facções: a DEC-050 **já fixa os tipos**; faltam nomes, doutrina e em quais o jogador entra), Q2 (2 culturas genéricas) e Q3 (as 5 leis, com o problema do crime).
- **Divisão sugerida (seção 3):** 117a registro; 117b extensão da economia; 117c `factions` e `politics`; 117d `military` e a crônica; 117e extensões de `world` e `npc`; 117f eventos e dados. Donos **por papel** no documento (para não citar letras de conversa); no meu mapa: registro = A; economia e dados = B; mundo e NPC = C. **Tarefas que provavelmente passam do limite:** LW-119, 121, 124, 125, 130, 131, 134, 135, 137, 138, 139, 141 e 142.
- **Escolhas minhas:** as recomendações são **só recomendações** (nada vira decisão); onde o GDD não diz, virou pergunta. Proposta de entrada para `DECISIONS.md`: nenhuma.

## 5. TESTES EXECUTADOS
- `tools/check_all` **no HEAD `a634f9e`**: **VERDE**. Arquitetura (nove verificações), GDScript **sem avisos** (314 scripts), dados válidos, **125 scripts, 1.203 testes (todos passando), 262.120 asserts**, 181,3 s (3 min 37 s no total). Os números são maiores que os de antes porque o `main` já trazia a LW-093b.
- **Incidente:** a primeira execução, em worktree novo (sem o cache `.godot`) e com outras execuções rodando ao mesmo tempo em outros ramos, passou de 10 minutos e o Godot ficou parado (CPU ~0). **Parei essa execução** (só a minha), fiz o passo documentado para clone novo (`Godot --headless --path . --import`, 3,7 s; o `godot` não está no PATH, usei o caminho do aplicativo) e rodei de novo: verde. Nada foi instalado.
- Por busca: o documento não cita arquivos de status nem letras de conversa; `git status` limpo; `main` e as tags não mudaram.
- Verificado antes de escrever: o `main` andou de `ce0cbed` para `4ada136` e depois `9b4f6f0` durante o trabalho; a base do ramo é `4ada136` e o que entrou depois (`ROADMAP_STATUS.md` e uma linha do `0012`) **não afeta** nenhuma afirmação (`DECISIONS.md`, roadmap e contratos não mudaram).

## 6. RESULTADOS
Aprovados: `check_all` inteiro (1.203 de 1.203); falhos e pulados: 0. Critério cumprido por leitura: as 5 seções pedidas, nesta ordem, com Q1 a Q10 de jogo e Q11 a Q21 técnicas, e as três perguntas do roadmap incluídas.

## 7. PROBLEMAS ENCONTRADOS
- O documento tem **275 linhas** (pedido: cerca de 250).
- Os trechos de GDD, arquitetura e contratos foram lidos **por seção, não inteiros**; não li o `ROADMAP_STATUS.md` da Fase 4 nem os capítulos 16 a 19 da arquitetura além do 17.5 e 17.7.
- **Não verifiquei** os números de linha do `npc.md` e do `economy.md` (citei seções).
- O ramo está **1 commit atrás do `main`** (`9b4f6f0`); não juntei, porque não foi autorizado e o arquivo é novo (sem conflito possível).

## 8. RISCOS
- As respostas às Q1 a Q10 mudam o tamanho da Fase 4 (por exemplo Q3, Q4 e Q5); a divisão da seção 3 pode mudar depois delas.
- O documento está **fora do `main`**: se ninguém o ler antes da LW-117, os 18 achados se perdem.

## 9. PENDÊNCIAS (decisões que dependem de Arthur, cada uma com a recomendação)
1. **Responder Q1 a Q10** (**recomendo** ler primeiro Q4, Q3 e Q5, as que mais mexem no escopo) e dizer se o revisor pode decidir Q11 a Q21 como PROPOSTA.
2. **Decidir** se o rascunho 0013 entra no `main` junto com a LW-117 ou antes (recomendo junto, como o 0012).
3. Teste manual: nenhum.

## ACOMPANHAMENTO
- Avanço: **Fase 2 CONCLUÍDA (32 de 32, 100%)**; projeto 87 de 192 (45,3%). **Fase 3** com a A e a B; **Fase 4 não iniciada** (esta é só a pré-etapa da LW-117).
- Próxima tarefa recomendada: **LW-117a** (registro das suas respostas), depois das respostas. **Não iniciada.** Parei aqui (regra 13).
- Git: ramo `lw-117-prevoo-fase-4` enviado (`a634f9e`, 1 commit, só o 0013); `status-c` enviado com este relatório; `main` = `9b4f6f0` (não alterado por mim); sem tag, sem `--force`.

---

# FASE B — RELATÓRIO — LW-087c: entrada no `main` (DOC)        Status: PRONTA PARA REVISÃO

**Declaração do início (AGENTS 2.3).** Tarefa: trocar só os rótulos de **estado** de `npc.md` e `world.md` de "rascunho" para "incorporado ao `main` em 11/11/2026 (LW-087c)", sem mudar decisão, número, contrato nem conteúdo, e levar o ramo ao `main` só por avanço simples. Autorização escrita de Arthur: um commit de estado ("LW-087c: estado do contrato incorporado ao main"), `fetch` e `merge origin/main` só se o `main` andasse, push do ramo e do mesmo HEAD ao `main` (só avanço simples, nunca `--force`, sem tag) e push do `status-c`. DEC: as 35 do pré-voo (APROVADAS no `main`), DEC-047, 049, 054 e 126 (APROVADAS). Sem dúvida que me fizesse parar.

## 1. RESUMO
Os dois arquivos agora dizem "incorporado ao `main` em 11/11/2026 (LW-087c)" e deixam escrito que a seção 14 do `npc.md` e a "Extensão da Fase 3" do `world.md` **continuam PLANEJADAS: nada disso existe no código**. O `main` passou de `63caee7` para `e3f715e` por avanço simples e está no mesmo commit que o ramo.

## 2. ARQUIVOS CRIADOS
- Nenhum.

## 3. ARQUIVOS MODIFICADOS (commit `e3f715e`, "LW-087c: estado do contrato incorporado ao main")
- `docs/modules/npc.md` (10 linhas) e `docs/modules/world.md` (6 linhas): 16 linhas trocadas por 16, 18 trocas de texto (tabela na seção 7). Nenhum outro arquivo. **As linhas 206 e 208 do `npc.md` não foram tocadas** (conferido: o diff não tem hunk nelas).
- O que entrou no `main` (`63caee7..e3f715e`): 14 commits do ramo; o resultado contra o `main` anterior é só `npc.md` (+92/−2) e `world.md` (+27) e **nenhum outro arquivo** (conferido por `git diff --name-only`).

## 4. DECISÕES TÉCNICAS
- Troquei "o registro em `DECISIONS.md` é da LW-087a" por "registradas na LW-087a"; "rascunho da LW-087b" e "rascunhos da LW-087b e da LW-087d" por "LW-087b" e "LW-087b e LW-087d"; "do ramo dela" e "do ramo da LW-087a" por "no `DECISIONS.md`" (a LW-087a já está no `main`).
- Em `world.md:63`, "desenho deste rascunho" virou "desenho desta extensão"; em `world.md:72`, "ao rascunho do catálogo da LW-087d" virou "ao catálogo da LW-087d", "antes este rascunho" virou "antes este arquivo" e "já está no rascunho da LW-087d" virou "já consta no catálogo da LW-087d". Mantive os fatos; só saiu a palavra de estado.
- Proposta de entrada para `DECISIONS.md`: nenhuma.

## 5. TESTES EXECUTADOS
- **B0:** `git fetch origin`: o `main` continuava em `63caee7`, então **não houve junção**; o ramo já continha o `main` (0 commits atrás).
- **B1, por busca:** "rascunho", "RASCUNHO", "fora do `main`" e "não está no `main`": **0** ocorrências nos dois arquivos. "ramo": **3** sobras, todas **outra coisa** e todas na Fase 2 (já no `main`): `npc.md:56` ("o ramo \"objetivo ou plano\" do fluxo", um ramo do fluxo de decisão), `npc.md:206` ("com o ramo S0", um ramo do código) e `npc.md:208` ("no ramo", histórico de uma junção da Fase 2; **você mandou não tocar**).
- **B2:** `tools/check_all` **no HEAD final `e3f715e`**: **VERDE**. Arquitetura (nove verificações), GDScript **sem avisos** (313 scripts), dados válidos, **124 scripts, 1.194 testes (todos passando), 261.693 asserts**, 173,0 s (3 min 25 s no total).
- **B3:** antes do push o `main` ainda era `63caee7` e era ancestral do HEAD. `git push origin lw-087c-extensoes-world-npc`: `bc48767..e3f715e`. `git push origin lw-087c-extensoes-world-npc:main`: `63caee7..e3f715e` (**avanço simples, aceito na 1ª tentativa**). `git ls-remote`: `refs/heads/main` = `refs/heads/lw-087c-extensoes-world-npc` = `e3f715e` = HEAD local. Tags no remoto: as três de antes (`fase-0`, `fase-1`, `fase-2-concluida`); **nenhuma nova**.
- NÃO EXECUTADO: `godot --headless --path . --import` (o `godot` não está no PATH do meu terminal; o `check_all` roda sozinho).

## 6. RESULTADOS
Aprovados: `check_all` inteiro (1.194 de 1.194); falhos e pulados: 0. Critério cumprido por busca, por `ls-remote` e pelo diff (só rótulos de estado, só dois arquivos).

## 7. PROBLEMAS ENCONTRADOS
**Tabela "rótulo antigo → rótulo novo"** (nas linhas longas mostro só o trecho que mudou; linhas do arquivo no `e3f715e`):

| # | Arquivo e linha | Antes | Depois |
|---|---|---|---|
| 1 | `npc.md:3` | RASCUNHO da LW-087c (10/11/2026): a seção 14, "Extensão da Fase 3", e as linhas planejadas da seção 12 (LW-09… | Incorporado ao `main` em 11/11/2026 (LW-087c): a seção 14, "Extensão da Fase 3", e as linhas planejadas da se… |
| 2 | `npc.md:103` | RASCUNHO da LW-087c | incorporado ao `main` em 11/11/2026 (LW-087c); PLANEJADA |
| 3 | `npc.md:232` | rascunho da LW-087c | incorporado ao `main` em 11/11/2026 (LW-087c) |
| 4 | `npc.md:248` | RASCUNHO da LW-087c, rodada 2; PLANEJADA, nada existe | incorporado ao `main` em 11/11/2026 (LW-087c); PLANEJADA, nada existe no código |
| 5 | `npc.md:250` | e rascunho não está no `main`** e só entra quando Arthur escrever que pode entrar | a seção foi incorporada ao `main` em 11/11/2026 (LW-087c)** e continua PLANEJADA |
| 6 | `npc.md:250` | rascunhos da LW-087b e da | LW-087b e |
| 7 | `npc.md:252` | ; o registro em `DECISIONS.md` é d |  e registradas n |
| 8 | `npc.md:254` | já registrou essas decisões como APROVADAS por Arthur em 11/11/2026 no `DECISIONS.md` do ramo dela | registrou essas decisões como APROVADAS por Arthur em 11/11/2026 no `DECISIONS.md` |
| 9 | `npc.md:308` |  do ramo da LW-087a |  |
| 10 | `npc.md:320` | rascunho da  |  |
| 11 | `npc.md:324` | rascunho da  |  |
| 12 | `world.md:5` | RASCUNHO da LW-087c (10/11/2026): a seção "Extensão da Fase 3" no fim deste arquivo é PLANEJADA e não existe … | Incorporado ao `main` em 11/11/2026 (LW-087c): a seção "Extensão da Fase 3" no fim deste arquivo continua PLA… |
| 13 | `world.md:61` | RASCUNHO da LW-087c; PLANEJADA, nada existe | incorporado ao `main` em 11/11/2026 (LW-087c); PLANEJADA, nada existe no código |
| 14 | `world.md:63` | e rascunh | a extensã |
| 15 | `world.md:72` | rascunho do catálogo da LW-087d (`docs/events.md`); antes este rascunh | catálogo da LW-087d (`docs/events.md`); antes este arquiv |
| 16 | `world.md:72` | está no rascunh | consta no catálog |
| 17 | `world.md:73` | rascunho da  |  |
| 18 | `world.md:78` | do ramo dela  |  |

- **Referências a arquivos que ainda não estão no `main`:** os dois arquivos citam `docs/modules/economy.md`, `docs/economy/dados.md` e o catálogo de eventos da LW-087d (`WagesPaid` etc. em `docs/events.md`) como os documentos que mandam nos nomes, assinaturas e números da economia. **No `main` agora não existem `economy.md` nem `dados.md`, e o `docs/events.md` dele não tem os eventos novos da Fase 3** (a LW-087b e a LW-087d seguem fora do `main`). O texto já fazia essas citações; só deixei de chamá-los "rascunho". Até a 087b e a 087d entrarem, essas referências apontam para arquivos ausentes.
- Nada falhou; nenhum aviso novo.

## 8. RISCOS
- As referências acima: quem ler o `npc.md` ou o `world.md` no `main` não encontra o `economy.md` até a LW-087b entrar.
- **Não reverifiquei** nesta tarefa as linhas das LW-088a, LW-093, LW-094, LW-095, LW-096a e LW-097 do `npc.md` contra o roadmap que entrou no `main` (pendência do relatório anterior).

## 9. PENDÊNCIAS (decisões que dependem de Arthur, cada uma com a recomendação)
1. **Entrada da LW-087b e da LW-087d no `main`** (`economy.md`, `dados.md` e o catálogo de eventos): resolve as referências ausentes (**recomendo** logo em seguida, no mesmo marco).
2. **Conferir as linhas de tarefa do `npc.md` contra o roadmap do `main`** (**recomendo**).
3. Teste manual: nenhum.

## ACOMPANHAMENTO
- Avanço: **Fase 2 CONCLUÍDA (32 de 32, 100%)**; projeto 87 de 192 (45,3%) (`ROADMAP_STATUS.md` não foi tocado, como você mandou). **Fase 3 não iniciada.** No `main`: a LW-087a e agora a LW-087c; faltam a LW-087b e a LW-087d.
- Próxima tarefa recomendada: entrada da LW-087b e da LW-087d no `main`. **Não iniciada.** Parei aqui (regra 13).
- Git: `main` = `lw-087c-extensoes-world-npc` = `e3f715e` (avanço simples); `status-c` enviado com este relatório; nenhuma tag; sem `--force`; nada além de `npc.md` e `world.md` no commit.

---

# JUNÇÃO DO MAIN E CORREÇÃO DE npc.md:252 — RELATÓRIO — LW-087c (DOC)        Status: PRONTA PARA REVISÃO

**Declaração do início (AGENTS 2.3).** Tarefa: (1) juntar o `main` (`63caee7`) no ramo `lw-087c-extensoes-world-npc`, só para ele ficar em dia, sem tocar no `main`; (2) trocar em `npc.md:252` "o `DECISIONS.md` ainda traz PROPOSTA" (DEC-047, 049 e 054) pelo que o `main` diz agora. Autorização escrita de Arthur: os dois passos (dada), depois o push do ramo e do `status-c` com o relatório (dada). Li o que o `main` traria (só documentos; não muda `npc.md` nem `world.md`) e o `DECISIONS.md` já junto. Sem dúvida que me fizesse parar; se a junção desse conflito, eu a abortaria e avisaria.

## 1. RESUMO
O ramo `lw-087c` está em dia com o `main` (0 commits atrás), a junção não deu conflito e a frase desatualizada de `npc.md:252` foi corrigida. Os dois commits e o relatório foram enviados.

## 2. ARQUIVOS CRIADOS
- Nenhum.

## 3. ARQUIVOS MODIFICADOS
- **Junção `1891452`** ("Merge remote-tracking branch 'origin/main' into lw-087c-extensoes-world-npc"): trouxe 8 commits do `main`, só documentos (5 arquivos, +992/−42): `docs/DECISIONS.md`, `docs/DEVELOPMENT_ROADMAP.md`, `docs/ROADMAP_STATUS.md`, `docs/backlog.md` e `docs/decisions/0012-pre-voo-da-fase-3.md` (novo). **Não alterei nenhum arquivo que veio do `main`.**
- **Correção `bc48767`** ("LW-087c: corrige o status das DEC-047, 049 e 054 no cabeçalho da seção 14"): `docs/modules/npc.md`, 1 linha (`npc.md:252`), de "o `DECISIONS.md` ainda traz PROPOSTA" para "APROVADAS por Arthur em 10/11/2026 no `DECISIONS.md`".
- Contra o `main` (`63caee7`) o ramo difere **só** em `npc.md` e `world.md` (+117/−2).

## 4. DECISÕES TÉCNICAS
- A junção foi feita no ramo, não no `main`; o `main` não foi alterado por mim. Proposta de entrada para `DECISIONS.md`: nenhuma.

## 5. TESTES EXECUTADOS
- `tools/check_all` **no HEAD final `bc48767`** (depois da junção e da correção): **VERDE**. Arquitetura (nove verificações), GDScript **sem avisos** (313 scripts), dados válidos, **124 scripts, 1.194 testes (todos passando), 261.693 asserts**, 172,4 s (3 min 26 s no total). Mesmos números de antes, como esperado (só documentos).
- **Números de DEC contra o `DECISIONS.md` do ramo já junto:** as 47 DEC que os dois arquivos citam têm entrada, e as 35 do pré-voo estão APROVADAS por Arthur em 11/11/2026; DEC-047, 049 e 054 estão APROVADAS (10/11/2026). **Nenhum número deixou de bater.**
- Por busca: "ainda traz PROPOSTA" **0** ocorrências em `npc.md`.
- Push: `lw-087c-extensoes-world-npc` `cf21a0a..bc48767` (avanço simples: o remoto era ancestral do local; o `main` também); o remoto confere (`bc48767`).
- NÃO EXECUTADO: `godot --headless --path . --import` (o `godot` não está no PATH do meu terminal; o `check_all` roda sozinho).

## 6. RESULTADOS
Aprovados: `check_all` inteiro (1.194 de 1.194); falhos e pulados: 0. Critério cumprido por leitura do diff (1 linha) e pelo resultado da junção (sem conflito).

## 7. PROBLEMAS ENCONTRADOS
- **Outras frases que podem estar desatualizadas depois da junção, não alteradas** (fora do que você autorizou): o cabeçalho da seção 14 do `npc.md` ainda diz, no começo, "o registro em `DECISIONS.md` é da LW-087a" (a LW-087a já registrou; a frase continua verdadeira, mas pode ser enxugada); `npc.md:206` e `npc.md:208` ainda citam nomes de conversas de trabalho da Fase 2 ("o da B", "conversa B"); `world.md` e `npc.md` ainda dizem em alguns pontos que o `economy.md` é um "rascunho da LW-087b", o que continua verdadeiro enquanto ele não entra no `main`.
- Nada falhou; nenhum aviso novo.

## 8. RISCOS
- A junção traz o `DEVELOPMENT_ROADMAP.md` novo para o ramo; se algum número de linha de tarefa citado nos meus arquivos (LW-088a, LW-093a, LW-093b, LW-096a) divergir do roadmap, vai aparecer na revisão: **não reverifiquei os textos das tarefas no roadmap do `main` nesta tarefa**.

## 9. PENDÊNCIAS (decisões que dependem de Arthur, cada uma com a recomendação)
1. **Revisar** o ramo `lw-087c` (A): `npc.md` e `world.md` contra o `main` atual; **recomendo** conferir as linhas das LW-088a, LW-093, LW-094, LW-095, LW-096a e LW-097 do `npc.md` com o roadmap que entrou no `main`.
2. **Decidir** quando os rascunhos 087b, 087c e 087d entram no `main` (a LW-087a já entrou).
3. Teste manual: nenhum.

## ACOMPANHAMENTO
- Avanço: **Fase 2 CONCLUÍDA (32 de 32, 100%)**; projeto 87 de 192 (45,3%). **Fase 3 não iniciada.** A LW-087a está no `main`; os rascunhos 087b, 087c e 087d seguem fora dele.
- Próxima tarefa recomendada: a revisão do ramo `lw-087c` contra o roadmap do `main`. **Não iniciada.** Parei aqui (regra 13).
- Git: `lw-087c-extensoes-world-npc` enviado (`bc48767`); `status-c` enviado com este relatório; `main` = `63caee7` (não alterado por mim); nenhuma tag nova; sem merge no `main`, sem Fase B, sem `--force`.

---

# CORREÇÃO DE STATUS — RELATÓRIO — LW-087c: três frases "ainda mostra PROPOSTA" (DOC)        Status: PRONTA PARA REVISÃO

**Declaração do início (AGENTS 2.3).** Tarefa: trocar, em `npc.md:254`, `npc.md:308` e `world.md:78`, a frase "o `DECISIONS.md` do ramo da LW-087a ainda mostra PROPOSTA" pela situação real, e nada além. Autorização escrita de Arthur: um commit no ramo (dada) e, depois, o push de `lw-087c-extensoes-world-npc` e do `status-c` (dada). Li o `DECISIONS.md` da LW-087a antes de escrever "APROVADAS". Sem dúvida que me fizesse parar.

## 1. RESUMO
As três frases agora dizem que a LW-087a já registrou as decisões como APROVADAS por Arthur em 11/11/2026. O commit foi feito e depois enviado, como você autorizou em dois passos.

## 2. ARQUIVOS CRIADOS
- Nenhum.

## 3. ARQUIVOS MODIFICADOS (commit `cf21a0a`, "LW-087c: corrige o status das decisões do pré-voo nas frases de origem")
- `docs/modules/npc.md` (linhas 254 e 308) e `docs/modules/world.md` (linha 78): 3 linhas trocadas por 3. Nenhum outro arquivo.

## 4. DECISÕES TÉCNICAS
- Escrevi "a LW-087a registrou" e mantive "vale o status em `DECISIONS.md`" (AGENTS 8.4); não escrevi que algo "entrou no `main`".
- Proposta de entrada para `DECISIONS.md`: nenhuma.

## 5. TESTES EXECUTADOS
- `tools/check_all` **no HEAD final `cf21a0a`**: **VERDE**. Arquitetura (nove verificações), GDScript **sem avisos** (313 scripts), dados válidos, **124 scripts, 1.194 testes (todos passando), 261.693 asserts**, 182,3 s (3 min 35 s no total).
- **Status e números de DEC:** antes de editar (HEAD `86d4310`, 07:48) as **35 estavam APROVADAS por Arthur em 11/11/2026**; no fim (07:52) o HEAD era o mesmo. Depois do push, no `main` atual (`63caee7`), as 35 continuam APROVADAS e as 25 DEC que os dois arquivos citam têm o mesmo título de antes; **nenhum número deixou de bater**.
- Por busca: "ainda mostra PROPOSTA" **0** ocorrências nos dois arquivos. `git push origin lw-087c-extensoes-world-npc`: `a8be77b..cf21a0a`; o remoto confere (`cf21a0a`).
- NÃO EXECUTADO: `godot --headless --path . --import` (o `godot` não está no PATH do meu terminal; o `check_all` roda sozinho).

## 6. RESULTADOS
Aprovados: `check_all` inteiro (1.194 de 1.194); falhos e pulados: 0. Critério cumprido por leitura do diff (3 linhas).

## 7. PROBLEMAS ENCONTRADOS
- **O `main` avançou durante a tarefa:** de `8dcc81d` para `63caee7` (a LW-087a registrada e o status dela, por terceiros; eu não toquei no `main`). O ramo `lw-087c` ficou **8 commits atrás e 11 à frente** do `main`; o `main` **não mudou** `npc.md` nem `world.md` desde o ponto de partida, então uma junção não deve dar conflito nesses dois arquivos (não testei).
- **`npc.md:252`** (cabeçalho da seção 14) ainda diz que o `DECISIONS.md` "ainda traz PROPOSTA" para DEC-047, 049 e 054. **No `main` atual elas estão APROVADAS**: a frase ficou desatualizada. Não mexi: você autorizou só as três frases.
- **`npc.md:206` e `npc.md:208`:** as duas frases antigas de conversas de trabalho da Fase 2 ("o da B", "conversa B") seguem como estavam.

## 8. RISCOS
- A frase de `npc.md:252` afirma algo que o `main` já superou.
- O ramo `lw-087c` está atrás do `main`: antes de qualquer entrada no `main`, ele precisa de uma junção (precisa da sua autorização).

## 9. PENDÊNCIAS (decisões que dependem de Arthur, cada uma com a recomendação)
1. **Autorizar um commit curto** para corrigir a frase de `npc.md:252` (DEC-047, 049 e 054 APROVADAS) (**recomendo**).
2. **Autorizar a junção do `main` no ramo `lw-087c`** (só para ficar em dia, sem tocar no `main`) (**recomendo**, antes de qualquer pedido de entrada no `main`).
3. Teste manual: nenhum.

## ACOMPANHAMENTO
- Avanço: **Fase 2 CONCLUÍDA (32 de 32, 100%)**; projeto 87 de 192 (45,3%). **Fase 3 não iniciada.** A LW-087a (registro) já está no `main`; os rascunhos 087b, 087c e 087d seguem fora dele.
- Próxima tarefa recomendada: junção do `main` no ramo `lw-087c` e a correção de `npc.md:252`. **Não iniciada.** Parei aqui (regra 13).
- Git: `lw-087c-extensoes-world-npc` enviado (`cf21a0a`); `status-c` enviado com este relatório; `main` = `63caee7` (não foi alterado por mim); nenhuma tag nova; sem merge no `main`, sem Fase B, sem `--force`.

---

# RODADA 5 E ADENDO — RELATÓRIO — LW-087c: marca como aprovadas as decisões do pré-voo; campos da vaga, manutenção com tecido e LW-094 como uma tarefa (DOC)        Status: PRONTA PARA REVISÃO

**Declaração do início (AGENTS 2.3), como escrita antes de editar.** Tarefa: trocar, nos dois arquivos, "PROPOSTA do revisor" e "[PROPOSTA]" por "aprovada por Arthur em 11/11/2026 (DEC-NNN)", só para as 35 decisões da sua aprovação em bloco (DEC-138 a 141, 145 a 162 e 165 a 177). Li: AGENTS (versão 0.4), o texto da tarefa, o `DECISIONS.md` do ramo da A (HEAD `28a0227`, 07:19 de 11/11) e o inventário de todos os rótulos dos dois arquivos (`b7eb2ee`). As 35 são PROPOSTA no `DECISIONS.md` da A hoje; vale a sua aprovação escrita. Arquivos: só `npc.md` e `world.md`. Sem dúvida que me fizesse parar.

**Declaração do início do adendo (AGENTS 2.3).** A rodada 5 já estava entregue (`0c37741`), então fiz **um segundo commit curto** (`a8be77b`) no mesmo ramo. Tarefa: (1) trocar o "[PENDENTE, pedido à B]" do salário e do local da vaga pela lista de campos que a economia definiu; (2) a manutenção gasta `tool`, `plank` ou `fabric`; (3) a LW-094 é **uma tarefa**, como no roadmap; (4) sem "da A", "da B", "da C" nem arquivos de status nos documentos. Li: o `economy.md` da LW-087b no HEAD `16ddf1b` (seção 6, "O que a vaga mostra", e a tabela da API), o roadmap no ramo da LW-087a (`acf10ed`, linha da LW-094) e a busca de 094a, 094b e "da A/B/C" nos meus arquivos. DEC: as 35 aprovadas em 11/11, DEC-163 e 178 (APROVADAS), DEC-175. Só `npc.md` e `world.md`.

## 1. RESUMO
Troquei 41 rótulos nos dois arquivos (28 no `npc.md`, 13 no `world.md`), só onde a decisão está nas 35, e citei a DEC em cada um. O que não está nas 35 ficou "[PROPOSTA]", os valores [HIP] continuam [HIP] e não entrou conteúdo novo, salvo seis frases de "origem" que diziam "nenhuma é decisão aprovada" e ficariam falsas (seção 4). **No adendo** (segundo commit): a lista de campos da vaga (`workplace_id`, `place_id`, `settlement_id`, `occupation_id`, `wage_per_hour`, `workers_wanted` e `workers_assigned`) e o aviso de que `wage_per_hour` vale por hora em que o local produz, não por dia; `fabric` na manutenção; a LW-094 como uma tarefa (com a divisão em 094a e 094b só como plano do revisor se passar do limite de tamanho); e `da B` virou `da LW-087b` onde era referência.

## 2. ARQUIVOS CRIADOS
- Nenhum.

## 3. ARQUIVOS MODIFICADOS (só documentos; ramo `lw-087c-extensoes-world-npc`, dois commits)
- **`0c37741`** "LW-087c: marca como aprovadas as decisões do pré-voo": `npc.md` e `world.md`, 34 linhas trocadas por 34.
- **`a8be77b`** "LW-087c: adendo, campos da vaga, manutenção com tecido e LW-094 como uma tarefa": `npc.md` (12 linhas) e `world.md` (1 linha); 13 trocadas por 13.
- Contra o `main` (`8dcc81d`, intocado) o ramo difere só nesses dois arquivos (+90/−2 e +27).

## 4. DECISÕES TÉCNICAS
- **Mapa rótulo → DEC (conferido contra o texto das DEC no ramo da A):** Q18 A = DEC-152 (e DEC-151, a hora do local); local dono e `sell` = DEC-148 e DEC-168; vaga = DEC-165; LW-096a = DEC-169; Q23 (`work_place_id`) = DEC-167; `mint` na LW-093 = DEC-170; `request_trade` = DEC-173; Q21 A = DEC-145; `bread` e `grain` comestíveis = DEC-153; regra do `check_architecture` = DEC-171; LW-088a e hashes = DEC-172; postos sem marca `TEMP` = DEC-174; marcos de hash por bloco = DEC-175; Q-W1 = DEC-158; Q-W2 e Q-W3 = DEC-159; Q-W4 = DEC-160; Q-W5 = DEC-161; Q-W6 = DEC-162; comando e evento de rota na LW-097 = DEC-140.
- **Já APROVADAS antes, citadas como estavam:** DEC-163, 164 e 178 (e DEC-142, 143, 144, onde aparecem).
- **Fica "[PROPOSTA]" porque não está nas 35 (desenho do rascunho):** LW-094 em duas partes e "Ordem 094a/094b"; "Dependências permitidas depois da Fase 3"; "Quando" (falha por regra do comércio); "Montagem" da `api`; "um agente só em série" e "pasta própria" (14.8); os números da distribuição da B (`[PROPOSTA/HIP]`); no `world.md`, "Dados", "Tipos", "Consultas", "Validação" e "O 3º povoado" (e a parte de "Estado de rota" e "Comando" que vai além das DEC-159 e DEC-140).
- **Seis frases além do rótulo puro** (diziam que nada estava aprovado, o que ficaria falso): a introdução de 14.9 e a linha "Decididas pelo revisor" da seção 14 (`npc.md`); a introdução das Q-W e a linha "Decididas pelo revisor" do `world.md`; a Q23 ("só vale com a aprovação de Arthur, que ele dará na LW-097" virou "aprovada por Arthur em 11/11/2026 (DEC-167)"); e o item "Em aberto" de 14.9, que listava essas aprovações como pendentes. Marquei nas frases que o `DECISIONS.md` do ramo da A ainda mostra PROPOSTA até ela registrar a aprovação.
- **Adendo, item 1 (vaga):** o `[PENDENTE, pedido à B]` virou a lista **com os mesmos nomes** do `economy.md` (seção 6, "O que a vaga mostra", e a tabela da API): em `peek_contracts` (na `vacancy`), `peek_site` e `peek_post`, a LW-096a lê `workplace_id`, `place_id`, `settlement_id`, `occupation_id`, `wage_per_hour`, `workers_wanted` e `workers_assigned`; `wage_per_hour` vale **por hora em que o local produz, não por dia**, e a utilidade da LW-096a decide quanto isso pesa. Como a lista agora traz `workers_wanted`, a frase "o `npc` não lê `workers_wanted`" (14.4 e 14.10) virou "o `npc` não o compara com a lista de atribuídos; só o lê junto da vaga".
- **Adendo, item 2 (manutenção):** Q20 agora diz `tool`, `plank` ou `fabric` (DEC-163 e DEC-178).
- **Adendo, item 3 (LW-094):** a linha da tabela e o bullet "Ordem" de 14.5 dizem **uma tarefa, como no roadmap**; **094a** e **094b** aparecem só nesses dois lugares, como a divisão que o revisor faz ao preparar o prompt se a tarefa passar do limite (AGENTS 5.2). Os demais lugares ("o que a 094b apaga", testes, oráculo, save, a linha de remoção de 9) passaram a dizer "LW-094".
- **Adendo, item 4:** "rascunho da B" virou "rascunho da LW-087b" (3 lugares), "na distribuição da B" virou "na distribuição proposta no `economy.md`" e "ramo dela" virou "ramo da LW-087a". As menções "A e B" que sobram são os **povoados** A e B.
- **Proposta de entrada para `DECISIONS.md`:** nenhuma; registrar o status das 35 é da LW-087a.

## 5. TESTES EXECUTADOS
- **Números de DEC contra `origin/lw-087a-registro-fase-3:docs/DECISIONS.md`:** no **início (07:19)** e no **fim (07:25)** o HEAD da A era o mesmo (`28a0227`) e o arquivo, idêntico. As 25 DEC com número 138 ou mais que os dois arquivos citam (138, 140, 145, 148, 151, 152, 153, 158 a 165, 167 a 175 e 178) existem, com o mesmo título no início e no fim e com o tema que eu cito; **nenhum número deixou de bater, então não parei**.
- `tools/check_all` **no HEAD final `a8be77b`**: **VERDE**. Arquitetura (nove verificações), GDScript **sem avisos** (313 scripts), dados válidos, **124 scripts, 1.194 testes (todos passando), 261.693 asserts**, 172,3 s (3 min 25 s no total). Mesmos números do `main`, como esperado. (No commit anterior, `0c37741`, o `check_all` também ficou verde, com os mesmos números.)
- **Adendo, releitura do `economy.md`:** HEAD `16ddf1b` no início (07:39) e no fim (07:44), sem mudança; o ramo da LW-087a estava em `acf10ed` nos dois momentos.
- **Números de DEC de novo, agora contra `acf10ed`:** as 25 DEC com número 138 ou mais que os dois arquivos citam existem, com o mesmo título de `28a0227`; **nenhum número deixou de bater**. **O status delas mudou: no `acf10ed` todas as que eu cito entre as 35 estão APROVADAS por Arthur em 11/11/2026** (a LW-087a registrou).
- Por busca (adendo): `094a` e `094b` só na linha da LW-094 e no bullet "Ordem"; **0** "pedido à B", "rascunho da B" e "ramo dela" no que acrescentei; **0** citações a arquivos de status.
- NÃO EXECUTADO: `godot --headless --path . --import` (o `godot` não está no PATH do meu terminal; o `check_all` roda sozinho). Oráculo, soak e `run_sim` não foram rodados (só documentos).

## 6. RESULTADOS
Aprovados: `check_all` inteiro (1.194 de 1.194); falhos e pulados: 0. Critério cumprido **por leitura do diff e das tabelas abaixo** (itens 1 a 7 da rodada 5 e 1 a 5 do adendo).

## 7. PROBLEMAS ENCONTRADOS
**Tabela "rótulo antigo → rótulo novo"** (a coluna "DEC" diz qual decisão sustenta a troca; nas linhas longas mostro só o trecho que mudou):

| # | Arquivo e linha | Rótulo antigo | Rótulo novo | DEC |
|---|---|---|---|---|
| 1 | `npc.md:231` | PROPOSTA | aprovadas por Arthur em 11/11/2026 | DEC-171, 172 |
| 2 | `npc.md:232` | PROPOSTA do revisor | aprovada por Arthur em 11/11/2026 (DEC-170) | DEC-170 |
| 3 | `npc.md:235` | PROPOSTA do revisor, DEC-169 (PROPOSTA | aprovada por Arthur em 11/11/2026 (DEC-169 | DEC-169, 165 |
| 4 | `npc.md:236` | PROPOSTA, Q23; Arthur aprova aqui | Q23, aprovada por Arthur em 11/11/2026 (DEC-167) | DEC-167 |
| 5 | `npc.md:252` | PROPOSTA | aprovada por Arthur em 11/11/2026 | DEC-174 |
| 6 | `npc.md:254` | como padrão de trabalho (PROPOSTA: Arthur pode aprovar ou trocar):** (a) **Q18 A**, o salário como o `economy.md` o esc… | e aprovadas por Arthur em 11/11/2026, pelo painel de decisões, em bloco (DEC-138 a 141, 145 a 162 e 165 a 177):** (a) *… | bloco (a) a (e) |
| 7 | `npc.md:258` | PROPOSTA | aprovada por Arthur em 11/11/2026 (DEC-171) | DEC-171 |
| 8 | `npc.md:267` | (b), revisor | aprovada por Arthur em 11/11/2026 (DEC-148 e DEC-168) | DEC-148, 168 |
| 9 | `npc.md:267` | [PROPOSTA] | (DEC-168) | DEC-168 |
| 10 | `npc.md:278` | PROPOSTA | aprovada por Arthur em 11/11/2026 | DEC-174 |
| 11 | `npc.md:279` | (e) e Q21 A, revisor | aprovada por Arthur em 11/11/2026 (DEC-170 e DEC-145) | DEC-170, 145 |
| 12 | `npc.md:280` | revisor | aprovada por Arthur em 11/11/2026 (DEC-152 e DEC-151) | DEC-152, 151 |
| 13 | `npc.md:281` | (c), revisor | o desdobramento, aprovada por Arthur em 11/11/2026 (DEC-165 e DEC-169) | DEC-165, 169 |
| 14 | `npc.md:281` | , PROPOSTA |  | DEC-165 |
| 15 | `npc.md:281` | , PROPOSTA |  | DEC-169 |
| 16 | `npc.md:304` | PROPOSTA do revisor; DEC-172 e DEC-175 na LW-087a, PROPOSTA | aprovada por Arthur em 11/11/2026 (DEC-172 e DEC-175) | DEC-172, 175 |
| 17 | `npc.md:305` | PROPOSTA, Q23 | Q23, aprovada por Arthur em 11/11/2026 (DEC-167) | DEC-167 |
| 18 | `npc.md:308` |  (padrão de trabalho, PROPOSTA: vale para escrever o contrato, e Arthur pode aprovar ou trocar). A LW-087a as registrou… | , cujas decisões Arthur **aprovou em bloco em 11/11/2026**, pelo painel de decisões (DEC-138 a 141, 145 a 162 e 165 a 1… | intro 14.9 |
| 19 | `npc.md:311` | decidida (revisor | aprovada por Arthur em 11/11/2026 (DEC-152 e DEC-151 | DEC-152, 151 |
| 20 | `npc.md:312` | (b), revisor | aprovada por Arthur em 11/11/2026 (DEC-168) | DEC-168 |
| 21 | `npc.md:313` | , proposta do revisor | ; que `bread` sacia por inteiro e `grain` menos: aprovada por Arthur em 11/11/2026, DEC-153 | DEC-153 |
| 22 | `npc.md:314` | decidida (revisor | aprovada por Arthur em 11/11/2026 (DEC-145 | DEC-145 |
| 23 | `npc.md:315` | do revisor | aprovado por Arthur em 11/11/2026 (DEC-165 e DEC-169) | DEC-165, 169 |
| 24 | `npc.md:315` | Revisor (PROPOSTA):** (i) a vaga, de local de produção ou de posto, é um contrato do tipo `vacancy` (`economy.md`, seçã… | Desdobramento:** (i) a vaga, de local de produção ou de posto, é um contrato do tipo `vacancy` (`economy.md`, seção 8; … | DEC-165, 169 |
| 25 | `npc.md:316` | decidida (revisor) como PROPOSTA; Arthur aprova na LW-097 | aprovada por Arthur em 11/11/2026 (DEC-167) | DEC-167 |
| 26 | `npc.md:316` | proposta | decisão | DEC-167 (palavra) |
| 27 | `npc.md:316` | : **só vale com a aprovação de Arthur**, que ele dará na LW-097 | , **aprovada por Arthur em 11/11/2026 (DEC-167)** | DEC-167 |
| 28 | `npc.md:317` | (1) a **aprovação das propostas do revisor** (a a e, Q21, Q23, e as Q-W1 a Q-W6 de `world.md`); (2) os **marcos de hash… | as propostas do revisor desta lista (a a e, Q21, Q23, a LW-096a, os marcos de hash por bloco e as Q-W1 a Q-W6 de `world… | Em aberto |
| 29 | `world.md:63` | como padrão de trabalho (PROPOSTA; Arthur pode aprovar ou trocar | e aprovadas por Arthur em 11/11/2026 (DEC-158 a DEC-162 | Q-W1 a Q-W6 |
| 30 | `world.md:70` |  | ; os estados `open` e `closed`: aprovada por Arthur em 11/11/2026 (DEC-159) | DEC-159 |
| 31 | `world.md:71` |  | ; que a LW-097 o cria: aprovada por Arthur em 11/11/2026 (DEC-140) | DEC-140 |
| 32 | `world.md:72` | .** | ** (aprovada por Arthur em 11/11/2026, DEC-140). | DEC-140 |
| 33 | `world.md:74` | decidida pelo revisor | aprovada por Arthur em 11/11/2026 (DEC-160) | DEC-160 |
| 34 | `world.md:78` | .** **Origem:** as seis são **padrão de trabalho do revisor (PROPOSTA)**: valem para escrever o contrato, **nenhuma é d… |  e aprovadas por Arthur em 11/11/2026, pelo painel de decisões (DEC-158 a DEC-162).** **Origem:** as seis eram padrão d… | intro das Q-W |
| 35 | `world.md:79` | decidida (revisor | aprovada por Arthur em 11/11/2026 (DEC-158 | DEC-158 |
| 36 | `world.md:80` | decidida (revisor | aprovada por Arthur em 11/11/2026 (DEC-159 | DEC-159 |
| 37 | `world.md:81` | decidida (revisor | aprovada por Arthur em 11/11/2026 (DEC-159 | DEC-159 |
| 38 | `world.md:82` | decidida (revisor | aprovada por Arthur em 11/11/2026 (DEC-160 | DEC-160 |
| 39 | `world.md:83` | decidida (revisor | aprovada por Arthur em 11/11/2026 (DEC-161 | DEC-161 |
| 40 | `world.md:84` | decidida (revisor | aprovada por Arthur em 11/11/2026 (DEC-162 | DEC-162 |
| 41 | `world.md:84` | PROPOSTA; DEC-172 e DEC-175 na LW-087a, PROPOSTA | aprovada por Arthur em 11/11/2026 (DEC-172 e DEC-175) | DEC-172, 175 |

**Tabela do adendo (segundo commit `a8be77b`; item = número no adendo):**

| # | Arquivo e linha | Item | Antes (trecho que mudou) | Depois |
|---|---|---|---|---|
| 1 | `npc.md:103` | 3 | (parte 094b)  |  |
| 2 | `npc.md:233` | 3 | em duas partes [PROPOSTA]: **094a** a comida do mercado convive com o `FoodStub`; **094b** remove o `FoodStub`, o estoque do save… | **uma tarefa**, como no roadmap; se passar do limite de tamanho (AGENTS 5.2), o revisor a divide ao preparar o prompt em **094a**… |
| 3 | `npc.md:281` | 1 | precisa de `workers_wanted`:** quem o compara com a lista de atribuídos é a economia, para postar a vaga. A oferta chega por `Con… | compara `workers_wanted` com a lista de atribuídos:** quem o compara é a economia, para postar a vaga. A oferta chega por `Contra… |
| 4 | `npc.md:285` | 3 | **094a**, a comida do mercado convive com o `FoodStub` (o NPC compra quando pode; o estoque provisório segue de reserva); **094b*… | a **LW-094** é **uma tarefa**, como no roadmap: o NPC passa a comer do mercado e do próprio inventário, e a tarefa remove o `Food… |
| 5 | `npc.md:286` | 3 | - **O que a 094b apaga** | - **O que a LW-094 apaga** |
| 6 | `npc.md:288` | 3 | no texto da LW-094b e da LW-095** | no texto da LW-094 e da LW-095** |
| 7 | `npc.md:289` | 3 | a LW-094b obriga a refazer o cenário | a LW-094 obriga a refazer o cenário |
| 8 | `npc.md:290` | 3 | (módulo `economy` ausente), antes da 094b. | (módulo `economy` ausente), antes da LW-094. |
| 9 | `npc.md:290` | 3 | Depois da 094b o `serialize()` | Depois da LW-094 o `serialize()` |
| 10 | `npc.md:290` | 3 | o **teste da 094b usa uma fixture nova** | o **teste da LW-094 usa uma fixture nova** |
| 11 | `npc.md:308` | 4 | ela ainda mostra PROPOSTA até el | a LW-087a ainda mostra PROPOSTA até a LW-087 |
| 12 | `npc.md:313` | 2 |  ou `plank` a cada alguns dias | , `plank` ou `fabric` a cada alguns dias (DEC-163 e DEC-178) |
| 13 | `npc.md:320` | 4 | **os números da distribuição são do `economy.md` (rascunho d | **os números da distribuição são do `economy.md` (rascunho d |
| 14 | `npc.md:324` | 1 | lê** `workers_wanted` | compara** `workers_wanted` com a lista de atribuídos; só o lê junto da vaga |
| 15 | `npc.md:324` | 4 | **Números do `economy.md` (rascunho da B, seção 6; [PROPOSTA | **Números do `economy.md` (rascunho da LW-087b, seção 6; [PR |
| 16 | `npc.md:324` | 4 | da B | proposta no `economy.md` |
| 17 | `world.md:73` | 4 | **Números do `economy.md` (rascunho da B, seção 6; [PROPOSTA | **Números do `economy.md` (rascunho da LW-087b, seção 6; [PR |

**Divergências, só listadas (não editei os outros ramos):**
- **Nomes de conversas na Fase 2:** o `npc.md` tem duas frases antigas, de antes da Fase 3 e já no `main` (linhas 206 e 208: "o da B" e "conversa B"), que citam nomes de conversas de trabalho da época. Ficaram como estão, por estarem fora do que esta tarefa acrescentou; corrijo se você mandar.
- **Frases minhas que ficaram desatualizadas:** em `npc.md:254`, `npc.md:308` e `world.md:78` eu escrevi que o `DECISIONS.md` do ramo da LW-087a "ainda mostra PROPOSTA até ela registrar a aprovação". **No `acf10ed` ela já registrou** (APROVADA). Não alterei, porque o adendo não pedia e só autorizou um commit curto; **recomendo** um commit curto para trocar essas três frases por "registrada como APROVADA no `DECISIONS.md`".
- **DEC-153** (conferida no `28a0227`) ainda dizia "o tecido é só mercadoria de comércio"; a DEC-178 (APROVADA) o pôs na manutenção dos locais. Cito a DEC-153 só para `bread` e `grain`.
- **DEC-162** ainda diz que a LW-097 atualiza o hash que o `run_sim` imprime, e os meus arquivos (e a DEC-172 e a DEC-175) dizem que o `run_sim` não muda.

## 8. RISCOS
- As três frases desatualizadas acima (dizem "ainda mostra PROPOSTA"); sem elas corrigidas, os documentos afirmam algo que o ramo da LW-087a já superou.
- Os pontos do `economy.md` que eu cobrava (salário e local da vaga nas consultas, tecido na manutenção) já estão resolvidos no HEAD `16ddf1b`; **não reverifiquei os marcos por tarefa** dele nesta rodada.

## 9. PENDÊNCIAS (decisões que dependem de Arthur, cada uma com a recomendação)
1. **Você:** autorizar um commit curto para trocar as três frases "ainda mostra PROPOSTA" (**recomendo**) e dizer se corrijo as duas frases de conversa de trabalho (linhas 206 e 208) (**recomendo** deixar como estão).
2. **A LW-087a** corrigir a DEC-153 (tecido) e a DEC-162 (`run_sim`), se ainda divergirem.
3. Teste manual: nenhum.

## ACOMPANHAMENTO
- Avanço: **Fase 2 CONCLUÍDA (32 de 32, 100%)**; projeto 87 de 192 (45,3%). **Fase 3 não iniciada**; os rascunhos 087b, 087c e 087d seguem **fora do `main`**.
- Próxima tarefa recomendada: **LW-087a (A)**, registro do status das 35. **Não iniciada.** Parei aqui (regra 13).
- Git: ramo `lw-087c-extensoes-world-npc` enviado (`a8be77b`, depois de `0c37741`); `status-c` enviado; `main` = `8dcc81d`, intocado; nenhuma tag nova; sem merge no `main`, sem Fase B, sem `--force`.

---

# RODADA 4 — RELATÓRIO — LW-087c: marcos de hash por bloco e tecido na manutenção (DOC)        Status: PRONTA PARA REVISÃO

**Declaração do início (AGENTS 2.3), como escrita antes de editar.** Li: AGENTS (versão 0.4); o texto da tarefa; os HEADs do início (21:42): A `1ad022a`, B `6b59a96` (economia) e `bfceb90` (dados e eventos); de A, DEC-174 a DEC-177 e o roadmap; do `economy.md` da B, marcos, tecido, postos e consultas; o meu `npc.md` e `world.md` (`b2d028d`). Decisões: DEC-022, 126, 127 e 100 e DEC-163 e 164 (APROVADAS); DEC-165, 169, 172, 174 e 175 (PROPOSTA no ramo da A); **DEC-178, tecido (APROVADA por você, ainda não registrada pela A)**; DEC-040 (PENDENTE, não bloqueia). Arquivos: só `world.md` e `npc.md`. **HEADs de novo no fim (21:47): os mesmos três, sem mudança.**

## 1. RESUMO
Os marcos de hash agora são por **bloco** (marco 1 = LW-088a a LW-092; marco 2 = LW-093 a LW-096a; marco 3 = LW-097), com a regra de parar no primeiro valor de referência que mudar, mostrar antes, depois e causa, e só registrar o resto do bloco depois do "aprovo os hashes do marco N". O tecido passou a insumo de manutenção dos locais (o NPC não o consome) e as DEC da A foram citadas onde a frase já existia.

## 2. ARQUIVOS CRIADOS
- Nenhum.

## 3. ARQUIVOS MODIFICADOS (só documentos; ramo `lw-087c-extensoes-world-npc`, commit `b7eb2ee`)
- `docs/modules/npc.md` — 14.8 (marcos por bloco), **linha nova da LW-088a** e linhas LW-093 a LW-097 da seção 12 (marcos), cabeçalho da 14, 14.3, 14.4, 14.5, 14.9 (Q15, Q20, Q22, "em aberto"). Neste commit +18 e −17 linhas.
- `docs/modules/world.md` — Q-W6 (marcos por bloco). 1 linha.
- Contra o `main` (`8dcc81d`, intocado) o ramo difere só nesses dois arquivos (+90/−2 e +27).

## 4. DECISÕES TÉCNICAS
- **Marcos por bloco [PROPOSTA do revisor]:** escritos como você mandou, com as quatro regras (parar no primeiro valor que mudar; "aprovo os hashes do marco N"; a partir da LW-098 valor já aprovado que mudar faz parar e perguntar; o primeiro valor de um teste novo não é mudança). O `run_sim` não muda, nem o código dele. A LW-088a ganhou **uma linha na tabela do `npc.md`** (não é tarefa do `npc`, mas abre o marco 1 e o `npc` herda o hash).
- **Tecido:** onde os arquivos diziam "só mercadoria" ou [LIM], agora dizem que o NPC não o consome e que ele é insumo de manutenção dos locais (DEC-178, em dados). Tirei o [LIM] do tecido, porque agora ele tem consumidor (os locais).
- **DEC citadas, só onde a frase já existia:** LW-096a = DEC-169; vaga = DEC-165; postos = DEC-164 (APROVADA) e DEC-174 (PROPOSTA, sem marca `TEMP-LW-`); marcos = DEC-172 e DEC-175; tecido = DEC-178; consumo = DEC-163. A frase "nenhuma está em `DECISIONS.md`" (14.9) foi corrigida para "a LW-087a as registrou; vale o status em `DECISIONS.md`".
- **LW-096a, salário e local da vaga:** continua **pendência da economia**. O `economy.md` da B (`6b59a96`) ainda não lista o salário nem o local em `peek_site`, `peek_post` nem `peek_contracts`; deixei como estava (14.4: [PENDENTE, pedido à B]) e **não** inventei nome de campo.
- **Proposta de entrada para `DECISIONS.md`:** nenhuma nova.

## 5. TESTES EXECUTADOS
- `tools/check_all` **no HEAD final `b7eb2ee`**: **VERDE**. Arquitetura (nove verificações), GDScript **sem avisos** (313 scripts), dados válidos, **124 scripts, 1.194 testes (todos passando), 261.693 asserts**, 172,1 s (3 min 25 s no total). Mesmos números do `main`, como esperado numa tarefa só de documentos.
- Por busca: **0** citações a `STATUS-B`, `STATUS-C`, `status-b`, `status-c` ou "pré-voo" nas linhas que acrescentei; `site_id` só nas 2 linhas explicativas; **0** frases restantes de "tecido só mercadoria" ou de [LIM] do tecido nos dois arquivos.
- NÃO EXECUTADO: `godot --headless --path . --import` (o `godot` não está no PATH do meu terminal; o `check_all` roda sozinho). Oráculo, soak e `run_sim` não foram rodados (só documentos).

## 6. RESULTADOS
Aprovados: `check_all` inteiro (1.194 de 1.194); falhos e pulados: 0. Critério cumprido **por leitura do diff**: itens 1 a 5 da tarefa.

## 7. PROBLEMAS ENCONTRADOS — o que conferi contra a A e a B
Legenda: **✓** bate; **DIV** divergência (só listada; não editei os ramos da A nem os da B).

| # | O que conferi | Meus arquivos (`b7eb2ee`) | A (`1ad022a`, igual no início e no fim) | B (`6b59a96` e `bfceb90`, iguais no início e no fim) |
|---|---|---|---|---|
| 1 | Marcos de hash por bloco (088a–092; 093–096a; 097) | ✓ | **DIV:** DEC-172 e DEC-175 têm três marcos por tarefa (088a; 093 a 095; 097) | **DIV:** seção 2 e Q19 com três marcos por tarefa; **e a linha da LW-097 na seção 14 diz "marco 2"**, enquanto a seção 2 diz marco 3 |
| 2 | Regra de parar no primeiro valor, depois só registrar; a partir da LW-098 pergunta | ✓ | não traz | não traz |
| 3 | Tecido na manutenção, NPC não consome (DEC-178) | ✓ | **DIV:** DEC-178 **ainda não registrada** (o texto dela diz "próximo número livre: DEC-178") | **DIV:** seção 3 (tabela) e seção 6 ainda dizem "só mercadoria de comércio" e a [LIM] do tecido |
| 4 | LW-096a = DEC-169 | ✓ | ✓ DEC-169 e linha do roadmap (depende da LW-096 e da LW-093) | ✓ seções 8 e 14 |
| 5 | Vaga = DEC-165, também de posto | ✓ | **DIV:** DEC-165 ainda diz só "local de produção" | ✓ vaga de local ou posto (seção 8) |
| 6 | Postos = DEC-164 e DEC-174 (sem marca `TEMP`) | ✓ | ✓ DEC-164 (APROVADA) e DEC-174 (PROPOSTA) | ✓ Q18 decidida (rodada 3): sem marca |
| 7 | `WagesPaid(workplace_id, ...)` e `peek_site` ou `peek_post` | ✓ | ✓ **resolvido:** DEC-152 revista agora usa `workplace_id`, `peek_site` e `peek_post` (era DIV na rodada 3) | ✓ |
| 8 | Salário e local da vaga em `peek_contracts`, `peek_site` ou `peek_post` (LW-096a) | pendência escrita, sem nome de campo | não trata | **ainda pendente:** as linhas de `peek_site`, `peek_post` e `peek_contracts` do `economy.md` não mudaram |
| 9 | `run_sim` não muda | ✓ | ✓ DEC-172 e DEC-175; **DIV interna:** a DEC-162 ainda diz que a LW-097 atualiza o `run_sim` (conferido em `1ad022a`) | ✓ |

## 8. RISCOS
- **A e a B ainda têm os marcos por tarefa e o tecido "só mercadoria"** (e a DEC-178 não existe): até elas atualizarem, os três documentos se contradizem em cima desses dois pontos. A A e a B estão trabalhando em paralelo; reli os HEADs no fim e nada tinha mudado.
- **DEC-178 citada sem registro:** os meus arquivos citam um número que a A ainda não registrou (como você mandou). Se a A usar outro número, tenho de corrigir.
- **LW-096a sem salário e local da vaga nas consultas:** a tarefa não consegue pontuar a vaga até a B listar os campos.

## 9. PENDÊNCIAS (decisões que dependem de Arthur, cada uma com a recomendação)
1. **A LW-087a** registrar a DEC-178 (APROVADA), revisar DEC-172 e DEC-175 para marcos por bloco e a DEC-165 para vaga de posto (**recomendo**).
2. **A B** trocar "tecido só mercadoria" e a [LIM] pela manutenção, os marcos por bloco (e o "marco 2" da LW-097) e listar salário e local da vaga nas consultas.
3. **Você:** aprovar ou trocar as propostas do revisor (marcos por bloco, Q23, Q-W1 a Q-W6; **recomendo aprovar**).
4. Teste manual: nenhum.

## ACOMPANHAMENTO
- Avanço: **Fase 2 CONCLUÍDA (32 de 32, 100%)**; projeto 87 de 192 (45,3%). **Fase 3 não iniciada**; os rascunhos 087b, 087c e 087d seguem **fora do `main`**; o da A (087a) está no ramo dela.
- Próxima tarefa recomendada: **LW-087a (A)**, para alinhar os pontos da tabela. **Não iniciada.** Parei aqui (regra 13).
- Git: ramo `lw-087c-extensoes-world-npc` enviado (`b7eb2ee`); `status-c` enviado; `main` = `8dcc81d`, intocado; nenhuma tag nova; sem merge no `main`, sem Fase B, sem `--force`.

---

# RODADA 3 — RELATÓRIO — LW-087c: `workplace_id` no lugar de `site_id` e números da B conferidos (DOC)        Status: PRONTA PARA REVISÃO

**Declaração do início (AGENTS 2.3), como escrita antes de editar.** Li: AGENTS (versão 0.4); o texto da tarefa; `economy.md` da B inteiro (`3eed5f8`); `dados.md` e `events.md` (`4d49835`); do ramo da A (`86584d6`): `DECISIONS.md` (DEC-148, 149, 151, 152 e DEC-160 a 173), o roadmap (linhas LW-088a, 093, 093a, 093b, 095, 096a, 097 e 104), o registro 0012; o meu `npc.md` e `world.md` no ramo (`f2913f9`). Decisões: DEC-022, 126, 127 e 100 (APROVADAS); DEC-163 e 164 (APROVADAS por você, registradas no ramo da A, ainda não no `main`); DEC-165 a 173 (PROPOSTA); DEC-047, 049 e 054 (PROPOSTA no `main`); DEC-040 (PENDENTE, não bloqueia). Arquivos: só `world.md` e `npc.md`. Sem dúvida que me fizesse parar.

## 1. RESUMO
No `npc.md`, `WagesPaid(site_id, amount_each)` virou `WagesPaid(workplace_id, amount_each)` e `peek_site` virou "`peek_site` ou `peek_post`" em todo lugar que fala de salário (linha da LW-095, 14.4, 14.6, Q18); o `workplace_id` é o `site_id` do local de produção ou o `post_id` do posto. Os números da B (14 locais de produção, 6 postos, 20 locais `work`, 10 novos, `workers_wanted`) agora aparecem em 14.10 e no `world.md` e **batem** com o `economy.md`, o `dados.md` e os dados do `main`. A tabela da seção 7 confere o resto contra a B e a A.

## 2. ARQUIVOS CRIADOS
- Nenhum.

## 3. ARQUIVOS MODIFICADOS (só documentos; ramo `lw-087c-extensoes-world-npc`, commit `b2d028d`)
- `docs/modules/npc.md` — 14.4 (postos como `ServicePost`, `WagesPaid`, vaga de posto, como o `npc` fica sabendo da vaga), 14.6, 14.8 (três marcos de hash numerados e LW-093b), 14.9 (Q15, Q18, Q20, Q22), **14.10 reescrita na parte de população e locais de trabalho** (os números da B e o efeito nas linhas), linhas LW-093 e LW-095 da seção 12. Neste commit +20 e −20 linhas.
- `docs/modules/world.md` — números da B (20 locais `work`, 10 novos) e "três marcos" na Q-W6. Neste commit 2 linhas.
- Contra o `main` (`8dcc81d`, intocado) o ramo difere só nesses dois arquivos (+89/−2 e +27).

## 4. DECISÕES TÉCNICAS
- **Nomes canônicos (os da B), como mandou:** `WagesPaid(workplace_id, amount_each)`; a consulta dos trabalhadores é `peek_site` (local de produção) ou `peek_post` (posto). Sobrou `site_id` em **2 lugares do `npc.md`, de propósito**: a frase que diz que o `workplace_id` é o `site_id` ou o `post_id`.
- **O `npc` não precisa de `workers_wanted`** (a pergunta do item 2 da tarefa): quem o compara com a lista de atribuídos é a economia, para postar a vaga. O `npc` fica sabendo da vaga por `ContractOffered` (`contract_id`, `kind` = `vacancy`) e lê o detalhe por `peek_contracts`. Está escrito em 14.4. **Lacuna:** para a LW-096a pontuar a vaga precisa do **local** e do **salário**, e o `economy.md` não os lista em `peek_site`, `peek_post` nem `peek_contracts`; escrevi como **[PENDENTE, pedido à B]**.
- **Três marcos de hash, como mandou:** marco 1 = LW-088a; marco 2 = LW-093 a LW-095; marco 3 = LW-097, uma aprovação sua dos valores novos em cada um (`npc.md` 14.8, `world.md` Q-W6). O `run_sim` não muda.
- **Postos:** troquei "uma receita sem insumo nem produto" por "**local de trabalho sem receita**, o `ServicePost`, sem conta nem inventário", que é o que a B escreveu na rodada 2; acrescentei o risco que ela anotou (mercado sem fundos para a folha do posto: ninguém recebe naquela hora) e que o posto também tem vaga.
- **Acrescentei, por conferência com a B e a A:** (i) NPC cujo local não tem local de produção nem posto **não é atribuído e não recebe salário**; (ii) `labor` é **recusado** a quem já está atribuído àquele local ("um trabalho, um pagamento"); (iii) a **LW-093b** (só teste: ofício novo só por JSON) é pré-requisito da LW-093 junto da LW-093a, como no roadmap da A; faltava nos meus arquivos.
- **Efeito nas linhas de `population.json` (conta minha, a partir da Q23 e da tabela da B):** com `work_place_id`, uma linha ocupa um local, então as linhas de A e B passam de **10 para 15** (A 7, B 8), mais as do C. Marcado como derivado.
- **Estoque inicial de 30 dias dos importados e teto de compra do mercado:** são da economia; citei só que o povoado C vive do estoque inicial de comida até o comerciante.
- **Proposta de entrada para `DECISIONS.md`:** nenhuma nova.

## 5. TESTES EXECUTADOS
- `tools/check_all` **no HEAD final `b2d028d`**: **VERDE**. Arquitetura (nove verificações), GDScript **sem avisos** (313 scripts), dados válidos, **124 scripts, 1.194 testes (todos passando), 261.693 asserts**, 179,4 s (3 min 31 s no total). Mesmos números do `main`, como esperado numa tarefa só de documentos.
- Por busca: `site_id` sobra em 2 linhas do `npc.md` (as explicativas) e 0 no `world.md`; **0** citações a `STATUS-B`, `STATUS-C`, `status-b`, `status-c` ou "pré-voo" nas linhas que acrescentei.
- Conferido por **cálculo e leitura de dados** do `main`: capacidade dos locais `work` A = 5 × 12 = 60 e B = 5 × 8 = 40 (`data/world/places.json`); população A 24+10+12+8+6 = 60 e B 16+8+8+5+3 = 40 (`data/population.json`).
- NÃO EXECUTADO: `godot --headless --path . --import` (o `godot` não está no PATH do meu terminal; o `check_all` roda sozinho). Nada além de documentos mudou, então oráculo, soak e `run_sim` não foram rodados.

## 6. RESULTADOS
Aprovados: `check_all` inteiro (1.194 de 1.194); falhos e pulados: 0. Critério cumprido **por leitura do diff**: itens 1 a 4 da tarefa feitos.

## 7. PROBLEMAS ENCONTRADOS — tabela da conferência (item 4 da tarefa)
Legenda: **✓** bate; **DIV** divergência (só listada, como mandou; não editei o ramo da A nem os da B).

| # | O que conferi | Meus arquivos (`b2d028d`) | B (`economy.md`, `dados.md`, `events.md`) | A (`86584d6`) |
|---|---|---|---|---|
| 1 | Nome do evento de salário | ✓ `WagesPaid(workplace_id, amount_each)` | ✓ `workplace_id` = `site_id` ou `post_id` (seções 6 e 11; `events.md` linha 22) | **DIV:** DEC-152 e o registro 0012 ainda escrevem `WagesPaid(site_id, amount_each)` e `peek_site` |
| 2 | Consulta dos trabalhadores | ✓ `peek_site` ou `peek_post` | ✓ seção 10 (`peek_post` na LW-095) | **DIV:** só `peek_site` (DEC-152) |
| 3 | 14 locais de produção, 6 postos | ✓ (5+6+3 = 14; 2 por povoado = 6) | ✓ seção 6 e `dados.md` | não traz os números (só o princípio, DEC-163 e 164) |
| 4 | 20 locais `work`, 10 novos | ✓ (A 7, B 8, C 5; A +2, B +3, C +5) | ✓ contas conferidas contra o `main` | não traz |
| 5 | `workers_wanted` | ✓ dado da economia; o `npc` não o lê (14.4 e 14.10) | ✓ colunas de `production_sites.json` e `service_posts.json`; população inicial = `workers_wanted` em cada local (A 60, B 40 + 4 pastores) | não traz |
| 6 | Posto sem receita, sem conta, folha do mercado, `NO_FUNDS` | ✓ | ✓ seção 6 | ✓ DEC-164 (a B é mais detalhada) |
| 7 | NPC sem local de produção nem posto: sem salário | ✓ (acrescentei) | ✓ seção 6 | não trata |
| 8 | Vaga também em posto | ✓ | ✓ seção 8 | **DIV:** DEC-165 diz só "local de produção" |
| 9 | Marcos de hash (sua decisão: 3 marcos) | ✓ 3 marcos numerados | **DIV parcial:** decide 2 (marco 1 = LW-088a **e LW-089**; marco 2 = LW-097) e deixa o 3º (LW-093 a 095) em aberto, recomendando-o | **DIV:** DEC-172 tem 2 marcos (088a e 089; 097) |
| 10 | `run_sim` não muda | ✓ | ✓ | **DIV interna:** DEC-172 diz que não muda; DEC-162 diz que a LW-097 o atualiza |
| 11 | LW-096a | ✓ nova, depois da LW-096, histerese, só termina por morte ou por outra vaga, sem demissão | ✓ seções 6, 8 e 14 | ✓ DEC-169 e linha do roadmap (depende da LW-096 e da LW-093) |
| 12 | LW-093b como pré-requisito da LW-093 | ✓ (acrescentei) | **DIV pequena:** seção 7 só cita a LW-093a | ✓ roadmap: LW-093 depende da 093a e da 093b |
| 13 | `mint` `game_start` na LW-093; `request_trade(actor_id, market_id, good_id, quantity, side)` | ✓ | ✓ | ✓ DEC-170 e DEC-173 |
| 14 | `market_reserved` vira `market` na LW-093; terreno não ampliado; hash da LW-097 com aprovação | ✓ | ✓ (seção 4, "o nome pode mudar") | ✓ DEC-160, 161 e 162 |
| 15 | Postos "provisórios": marca `TEMP`? | ✓ não uso marca | **aberto:** a Q18 dela pergunta e recomenda não marcar | ✓ DEC-164: é regra de jogo até a Fase 4, **não** marca `TEMP-LW-` |

## 8. RISCOS
- **Marco 1 e a LW-089 a LW-092:** B e A põem a LW-089 no marco 1; a sua decisão e os meus arquivos põem só a LW-088a. **Hipótese, não verificada:** se o bloco `economy` do `state_hash` também muda quando as LW-089 a LW-092 acrescentam estado (mercados, locais), esses valores novos precisam de um marco. Pergunta para a LW-087a.
- **Salário e local da vaga** não estão nas consultas da B: sem eles a LW-096a não consegue pontuar a vaga.
- **A mantém `site_id`, dois marcos e a vaga só em local de produção:** a LW-087a precisa alinhar com a B e com a sua decisão de hoje antes de registrar.

## 9. PENDÊNCIAS (decisões que dependem de Arthur, cada uma com a recomendação)
1. **A LW-087a** alinhar DEC-152, DEC-165 e DEC-172 com `workplace_id`, a vaga de posto e os três marcos (**recomendo**); resolver a DEC-162 contra a DEC-172 (`run_sim`).
2. **A B** listar o salário e o local da vaga nas consultas (`peek_site`, `peek_post` ou `peek_contracts`) e citar a LW-093b na seção 7.
3. **Você:** aprovar ou trocar as propostas do revisor (três marcos, Q23, Q-W1 a Q-W6; **recomendo aprovar**) e decidir se o marco 1 cobre a LW-089 a LW-092 (**recomendo** perguntar à LW-087a e provar na LW-088a).
4. Teste manual: nenhum.

## ACOMPANHAMENTO
- Avanço: **Fase 2 CONCLUÍDA (32 de 32, 100%)**; projeto 87 de 192 (45,3%). **Fase 3 não iniciada**; os rascunhos 087b, 087c e 087d seguem **fora do `main`** até você escrever que podem entrar; o da A (087a) está no ramo dela.
- Próxima tarefa recomendada: **LW-087a (A)**, para alinhar as divergências da tabela. **Não iniciada.** Parei aqui (regra 13).
- Git: ramo `lw-087c-extensoes-world-npc` enviado (`b2d028d`); `status-c` enviado; `main` = `8dcc81d`, intocado; nenhuma tag nova; sem merge no `main`, sem Fase B, sem `--force`.

---

# RODADA 2 — RELATÓRIO — LW-087c: alinhar `world.md` e `npc.md` com a B e com as suas novas decisões (DOC)        Status: PRONTA PARA REVISÃO

**Declaração do início (AGENTS 2.3), como escrita antes de editar.** Li: AGENTS (0, 2.3, 3, 8, 10, 14, 15; versão 0.4); o texto da tarefa; `economy.md` da B inteiro (`a815f85`), `dados.md` e `events.md` (`3b2a2de`); a revisão que a B fez da minha 087c (`64dcded` do ramo `status-b`); o meu `npc.md` (seções 12 a 14) e o `world.md` (extensão); dados atuais do `main` (`8dcc81d`). Decisões: DEC-022, 126 e 127 e DEC-100 (APROVADAS); DEC-047, 049 e 054 (PROPOSTA no `DECISIONS.md`, aprovadas por você por mensagem; o registro é da A); DEC-040 (PENDENTE, a tarefa não depende dela). Arquivos: só `docs/modules/world.md` e `docs/modules/npc.md`. Dúvida declarada: o `economy.md` da B ainda não traz as suas decisões 1 e 2 de hoje.

## 1. RESUMO
Os dois arquivos agora seguem o `economy.md` da B (salário por hora com um evento `WagesPaid` por local, vaga como contrato, `work_place_id` entregue ao abrir a conta) e as suas duas decisões novas: **consumo = manutenção dos locais** (o NPC só consome comida; os locais gastam ferramenta e tábua; o tecido é só mercadoria) e **guardas e estalajadeiros = postos de serviço**, com folha paga pela conta do mercado do povoado. Nenhum texto cita mais `STATUS-B.md`, `STATUS-C.md` nem o "pré-voo". A tabela da seção 7 abaixo confere, um por um, os 14 achados da B.

## 2. ARQUIVOS CRIADOS
- Nenhum.

## 3. ARQUIVOS MODIFICADOS (só documentos; ramo `lw-087c-extensoes-world-npc`, commit `f2913f9`)
- `docs/modules/npc.md` — seção 14 reescrita (14.1 a 14.10), linhas LW-093, 094, 095, 097 e 104 da seção 12 atualizadas, **linha nova da LW-096a**, cabeçalho (`[Qn]` e Fase 2). Neste commit +60 e −49 linhas; contra o `main`, o ramo difere +89 e −2.
- `docs/modules/world.md` — Q-W2, hashes, locais de trabalho (cada local de produção e cada posto ocupa um local `work` próprio), Fase 2 fechada. Neste commit ≈ 12 linhas mexidas; contra o `main`, +27.
- Só esses dois arquivos mudam contra o `main` (`8dcc81d`, intocado). Nada do `economy.md`, `dados.md` ou `events.md` da B foi editado.

## 4. DECISÕES TÉCNICAS
**Origem escrita em cada ponto, nos dois arquivos:**

| Ponto | Origem |
|---|---|
| Consumo = manutenção dos locais (NPC só consome comida; locais gastam ferramenta e tábua; tecido só mercadoria) = **Q20** | **Arthur** (APROVADA; registro da A) |
| Guardas e estalajadeiros = postos de serviço, folha pela conta do mercado do povoado = **Q15** | **Arthur** |
| Q10, Q19, Q22 (da rodada 1) | **Arthur** |
| (a) salário Q18 A como a B escreveu (`WagesPaid`, um por local e por hora; o `npc` lê `peek_site` e alivia `income` só dos NPCs dele; vale para os postos) | **revisor** (PROPOSTA) |
| (b) local de produção dono da produção e vende o excedente; NPC recebe salário e compra; `sell` do NPC pelo mesmo mecanismo de utilidade | **revisor** |
| (c) vaga = contrato `vacancy`; **LW-096a** (aceite por utilidade, com histerese); emprego só termina por morte ou por aceitar outra vaga; local sem dinheiro não demite | **revisor** |
| (d) Q23: coluna opcional `work_place_id` em `population.json`; `request_open_owner(owner_id, kind, work_place_id)` | **revisor** (você aprova na LW-097) |
| (e) `mint` inicial (`game_start`) na LW-093; `request_trade(actor_id, market_id, good_id, quantity, side)` | **revisor** |
| Q21 A, Q-W1 a Q-W6 | **revisor** |

**Escolhas minhas, dentro do escopo, para você poder trocar:**
- **Q-W2 mudou (achado M4 da B):** "perigosa" **saiu** do vocabulário da rota (só `open` e `closed`; `closed` é o "bloqueada" da arquitetura 5.2), porque vocabulário reservado sem uso é antecipação (AGENTS 5.5). Era uma proposta do revisor; troque se preferir a reserva.
- **Política de hashes novos [PROPOSTA]** (achado M6): uma aprovação sua por marco (LW-088a, LW-093 a 095 e LW-097); o `run_sim` **não** entra, porque não registra módulo.
- **`request_trade` com a assinatura completa**, como você mandou, em vez de "tirar a lista de parâmetros" (M2 da B); os nomes finais continuam sendo do `economy.md`.
- **Tecido:** escrevi como **[LIM]** que ele não tem consumidor entre NPCs nem locais; o comprador é o jogador e o comércio entre povoados, e o soak da LW-110 confere se o estoque não acumula.
- **O teste da 094b precisa de fixture nova** (o save da Fase 2 já é recusado desde a LW-088a pela ausência do bloco `economy`); `tests/fixtures/` é protegida, então a tarefa precisa da sua autorização. Está escrito na 14.5.
- **Proposta de entrada para `DECISIONS.md`:** nenhuma nova minha; o registro das suas decisões 1 e 2, de Q10, Q19 e Q22 é da LW-087a.

## 5. TESTES EXECUTADOS
- `tools/check_all` **no HEAD final `f2913f9`**: **VERDE**. Arquitetura (nove verificações), GDScript **sem avisos** (313 scripts), dados válidos, **124 scripts, 1.194 testes (todos passando), 261.693 asserts**, 172,3 s (3 min 25 s no total). Mesmos números do `main`, como esperado numa tarefa só de documentos.
- `godot --headless --path . --import`: **NÃO EXECUTADO** (o `godot` não está no PATH do meu terminal; o `check_all` roda sozinho e ficou verde).
- Por busca: `STATUS-B`, `STATUS-C`, `pré-voo`, `status-b` e `status-c` têm **0** ocorrências no que eu escrevi (a única ocorrência de "achado ... revisão cruzada" no `npc.md`, na seção 10, é da Fase 2 e já estava no `main`); `inicio_de_jogo` aparece **2 vezes, as duas explicativas** (tabela da LW-093 e 14.4); `git diff origin/main...HEAD` lista só `npc.md` e `world.md`.
- Conferi por leitura, **sem executar**: `run_sim` não registra módulo (`register_module` só é chamado em `GameModules`) e `World.on_load` recusa módulo ausente (`src/core/world/world.gd`).

## 6. RESULTADOS
Aprovados: `check_all` inteiro (1.194 de 1.194); falhos e pulados: 0. Critério cumprido **por leitura do diff**: itens 1 a 7 da tarefa feitos (14.4, Q18, 14.2, 14.3, Q20, Q22, Q23, 14.10, `world.md`, citações, tabela dos achados).

## 7. PROBLEMAS ENCONTRADOS — conferência dos 14 achados da revisão da B
| Achado | Pedido da B | Situação | Onde ficou |
|---|---|---|---|
| **I1** salário | evento por trabalhador é laço quente; sem evento no catálogo | **Resolvido.** `WagesPaid` agregado por local e por hora (a B o criou no `economy.md` e no `events.md`); o `npc` lê `peek_site`; as "pendências" sobre o catálogo e a divergência saíram | `npc.md` 14.4, 14.7, Q18 |
| **I2** dono da produção | o local é dono; NPC come comprando | **Resolvido.** A "reserva própria" e "a comida vem da produção do ofício" saíram | 14.2, 14.3 |
| **I3** cita `STATUS-B.md` | citar "decisão de Arthur" | **Resolvido.** 0 citações a arquivos de status e ao pré-voo | todo o `npc.md` |
| **I4** "economia nunca importa o `npc`" sem verificação | regra nova na LW-088a | **Resolvido.** 14.1 diz que a regra nasce na LW-088a, com teste positivo e negativo, e é critério de aceite dela (a B corrigiu o `economy.md`, seção 10) | 14.1 |
| **I5** aceitar trabalho | separar vaga fixa (LW-095) de trabalho avulso (LW-096); a B corrigiu o `economy.md` | **Resolvido.** Vaga = contrato `vacancy` na **LW-096a**; avulso (`labor` e `delivery`) na LW-104 | 14.4, 14.9 Q22, linhas 096a e 104 |
| **M1** nome do motivo | unificar | **Resolvido.** `game_start` em todo lugar; as 2 menções a `inicio_de_jogo` são explicativas, como você mandou | linha LW-093, 14.4 |
| **M2** assinatura de `request_trade` | tirar a lista de parâmetros | **Resolvido de outro modo, por ordem sua:** escrevi `request_trade(actor_id, market_id, good_id, quantity, side)` e disse que o `economy.md` manda nos nomes finais | 14.2, 14.6 |
| **M3** carga do `RouteStateChanged` | alinhar | **Já resolvido na rodada 1:** `route_id` e `new_state`, igual à arquitetura 17.3 e à D | `world.md` |
| **M4** estados da rota | citar `closed` = "bloqueada"; sem "perigosa" | **Resolvido.** Q-W2 ajustada (ver seção 4) | `world.md`, Estado de rota e Q-W2 |
| **M5** `run_sim` não muda | corrigir o texto | **Resolvido** em `world.md` (estado de rota e Q-W6) e `npc.md` (linha LW-097, 14.5, 14.8, 14.10); só o oráculo e o hash de 30 dias mudam | os dois |
| **M6** lista de hashes incompleta | política única, citar a 088a | **Resolvido como PROPOSTA:** política de uma aprovação sua por marco (088a, 093 a 095, 097); `world.md` Q-W6 aponta para ela | `npc.md` 14.8; `world.md` Q-W6 |
| **M7** cabeçalho | Q18 a Q22 estão na 14.9 | **Resolvido** | cabeçalho do `npc.md` |
| **M8** pré-requisito da LW-093 | citar o verificador | **Resolvido.** LW-093a como pré-requisito (linha da LW-093, 14.2, 14.8), decisão sua | 12, 14.2, 14.8 |
| **M9** falha de comércio | "falha por regra" (LW-070d); save recusado desde a 088a | **Resolvido.** Falha por regra (em S0 no pensamento seguinte); save da Fase 2 recusado desde a LW-088a e fixture nova para o teste da 094b | 14.2, 14.5 |

**Outros problemas:**
- **O `economy.md` da B ainda não incorpora as suas decisões 1 e 2:** a Q15 segue "em aberto" lá, e a seção 6 diz que NPC sem local de produção "não recebe salário" (o que a sua decisão 2 supera); a manutenção dos locais (ferramenta e tábua) não aparece, e a Q20 diz "só comida". Não editei nada dela.
- **O `mint` inicial:** a B o lista entre as suas recomendações aprovadas (com "ou a LW-095 antes da LW-094"); na sua mensagem de hoje ele está entre as decisões do revisor. Escrevi as duas coisas (14, decisão 4 e (e)).
- Os worktrees locais da B estão à frente do remoto só por junção com o `main`; revisei o que está no remoto.

## 8. RISCOS
- O `economy.md` e este arquivo divergem até a B incorporar as decisões 1 e 2 (manutenção dos locais e postos de serviço).
- **LW-096a** não existe no roadmap (arquivo protegido): se a A não a registrar, a vaga fica sem tarefa dona.
- **Tecido** sem consumidor: dependente da prova no soak da LW-110.
- **Q23** muda o formato de `population.json`; só vale com a sua aprovação na LW-097.

## 9. PENDÊNCIAS (decisões que dependem de Arthur, cada uma com a recomendação)
1. **Aprovar ou trocar** as minhas propostas: (a) a (e), Q21, Q23, Q-W1 a Q-W6 e a política de hashes (**recomendo aprovar**; a única que eu mudei de ideia sozinho foi a Q-W2).
2. **A B** incorporar as suas decisões 1 e 2 no `economy.md` (manutenção dos locais, postos de serviço, Q15 e Q20 como decididas) e conferir o `dados.md`.
3. **A LW-087a** registrar as suas decisões 1 e 2, Q10, Q19 e Q22, a **LW-096a** e a lista de divergências do roadmap.
4. Teste manual: nenhum.

## ACOMPANHAMENTO
- Avanço: **Fase 2 CONCLUÍDA (32 de 32, 100%)**; projeto 87 de 192 (45,3%). **Fase 3 não iniciada**; os rascunhos 087b, 087c e 087d seguem **fora do `main`** até você escrever que podem entrar.
- Próxima tarefa recomendada: **LW-087a (A)**. **Não iniciada.** Parei aqui (regra 13).
- Git: ramo `lw-087c-extensoes-world-npc` enviado (`f2913f9`); `status-c` enviado; `main` = `8dcc81d`, intocado; nenhuma tag nova; sem merge no `main`, sem Fase B, sem `--force`.

---

# TAREFA 3 — RELATÓRIO — LW-087c: ajuste dos meus rascunhos `world.md` e `npc.md` depois das suas decisões (DOC)        Status: PRONTA PARA REVISÃO

Li antes: AGENTS (seções 0, 3, 8, 10, 14 e 15; versão 0.4), os meus dois rascunhos (diff contra o `main`), a minha revisão da Tarefa 2, e, para registrar o impacto de `miner` e `shepherd` com fatos e não de memória: `data/occupations.json`, `routine_blocks.json`, `population.json`, `income_stub.json`, `food_stub.json`, `data/world/places.json`, `population_plan.gd`, `routine_loader.gd`, `income_stub.gd` e `place.gd`. Decisões: DEC-022, 126 e 127 (APROVADAS); DEC-047, 049 e 054 seguem PROPOSTA no `DECISIONS.md` (o registro é seu).

## 1. RESUMO
Os dois rascunhos agora refletem as suas decisões de 10/11/2026 (Q10, Q19, Q22) e deixam **claro quem decidiu cada ponto**: o que é **seu** e o que é **padrão de trabalho do revisor** (PROPOSTA, que você pode aprovar ou trocar). `inicio_de_jogo` virou `game_start` (DEC-022), o impacto de `miner` e `shepherd` está registrado com números do `main` e entrou **uma pergunta nova** (Q23) que as suas decisões abriram. Só os dois arquivos mudaram; nada foi para o `main`, nada de Fase B, nada de tag.

## 2. ARQUIVOS CRIADOS
- Nenhum.

## 3. ARQUIVOS MODIFICADOS (só documentos; ramo `lw-087c-extensoes-world-npc`, commit `187c20c`)
- `docs/modules/world.md` — Q-W1 a Q-W6 de "em aberto" para "decididas" (origem escrita em cada uma); Q10 e o aviso de capacidade dos locais `work`; o `RouteStateChanged` ficou com `route_id` e `new_state`; a renomeação `market_reserved` → `market` na LW-093 detalhada.
- `docs/modules/npc.md` — seção 14 (14.2, 14.4, 14.6, 14.7, 14.8) e linhas LW-093, LW-097 e LW-104 da tabela da seção 12 atualizadas; **14.9** reescrita ("decididas e abertas", com a origem); **14.10 nova** (impacto de `miner` e `shepherd`).
- Neste commit: ≈ +43 e −31 linhas. Contra o `main`, o ramo difere **só** nesses dois arquivos (+105 e −2). O `main` não foi tocado (`8dcc81d`). Merge do `main` no ramo: só para ficar em dia (`9de1582`), sem a Fase B.

## 4. DECISÕES TÉCNICAS
**Quem decidiu o quê (como está escrito nos dois arquivos):**

| Ponto | Decisão | Origem |
|---|---|---|
| **Q10** ofícios e cadeias | criar `miner` e `shepherd` (só dados); 4 cadeias distribuídas pelos 3 povoados, **nenhum autossuficiente**; população do 3º povoado e hashes novos na LW-097, **com a sua aprovação dos valores novos** | **Arthur** |
| **Q19** como `buy` vira candidata | **A**: mesmo mecanismo de utilidade, por valor derivado (herda o alívio da necessidade que o bem atende, descontados preço e distância); sem rotina fixa e sem planejador | **Arthur** |
| **Q22** emprego | população inicial **nasce empregada** (`work_place_id` de dados, como hoje); vaga nova por `ContractOffered`, aceita por utilidade | **Arthur** |
| Q-W1 a Q-W5 | triângulo A–B, A–C e B–C; só `open` e `closed`; nenhum campo extra na rota; `market_reserved` → `market` na LW-093; não ampliar o terreno | **revisor** (PROPOSTA) |
| Q-W6 | aceitar a mudança de hash na LW-097 | **revisor** (PROPOSTA); o **aval aos valores novos é seu** (você o disse ao decidir a Q10) |
| Q18 | **A**: evento de pagamento alivia `income`; pagamento por hora de produção aos trabalhadores atribuídos | **revisor** (PROPOSTA) |
| Q20 | só comida na Fase 3 (`bread` e `grain` comestíveis) | **revisor** (PROPOSTA) |
| Q21 | **A**: o `npc` abre a conta pela `economy/api` ao criar o NPC; a economia faz o `mint` inicial (`game_start`); a economia é registrada **antes** do `npc` | **revisor** (PROPOSTA) |

- **`game_start`:** troquei `inicio_de_jogo` pelo nome em inglês (DEC-022) na tabela da LW-093 e em 14.4; as duas menções que sobram dizem de propósito que o roadmap escreve `inicio_de_jogo` (o roadmap é protegido).
- **Payload do `RouteStateChanged`:** tirei o estado anterior (`route_id`, `new_state`), igual à arquitetura 17.3 e ao catálogo da D (`docs/events.md`). Eu tinha prometido isso na revisão (achado 9).
- **Impacto de `miner` e `shepherd` (14.10), com fatos:** `occupations.json` +2 linhas; **rotina:** cada ofício tem agenda própria que cobre as 24 h (o `RoutineLoader` rejeita ofício sem agenda): cerca de **20 linhas novas** (`farmer` tem 9 blocos, `lumberjack` 10); **`income_stub.json` não exige linha** por ofício (sem linha, o ofício novo só não alivia `income` ao trabalhar enquanto o provisório existir); **população:** hoje a capacidade dos locais `work` é **exatamente igual** à população (A: 5 × 12 = 60 e B: 5 × 8 = 40), então qualquer NPC a mais pede locais `work` novos (senão `NPC_POPULATION_NO_ROOM`); **hashes:** o sorteio dos traços na criação usa o gerador do mundo, então NPCs a mais mudam o oráculo, o hash de 30 dias e o `run_sim`.
- **O que eu NÃO decidi e deixei escrito como pendente:** (a) **Q23, nova:** hoje o NPC recebe o **primeiro** local `work` com vaga, em ordem de `id`; nada liga `miner` à mina. **Recomendo** uma coluna opcional `work_place_id` em `data/population.json` (mudança de **formato de dado**: precisa da sua aprovação, AGENTS 16.2); (b) como `sell` vira candidata (a Q19 só tratou `buy`); (c) qual tarefa do `npc` implementa o aceite de vaga e como o emprego **termina**; (d) o evento de pagamento da Q18 não existe no catálogo da D.
- **Avisos de conflito com os rascunhos da B** (escritos nos meus arquivos, sem editar nada dela): a seção 6 do `economy.md` (salário na hora, por minuto) diverge da Q18; a seção 8 e a linha do `ContractOffered` em `docs/events.md` (aceitar contrato é [FUT]) **contradizem a sua Q22** (revisão cruzada, achados 1 e 2).
- **Proposta de entrada para `DECISIONS.md`:** nenhuma nova minha; o registro de Q10, Q19 e Q22 como decisões suas é da LW-087a.

## 5. TESTES EXECUTADOS
- `tools/check_all` **no HEAD final `187c20c`**: **VERDE**. Arquitetura (nove verificações aprovadas), GDScript **sem avisos** (313 scripts), dados válidos, **124 scripts, 1.194 testes (todos passando), 261.693 asserts**, 169,6 s (3 min 21 s no total). Mesmos números do `main`, como esperado para uma tarefa só de documentos.
- `godot --headless --path . --import`: **NÃO EXECUTADO** neste worktree (`godot` não está no PATH do meu terminal: saída 127). O `check_all` rodou sozinho e ficou verde.
- Conferências por busca: `inicio_de_jogo` só aparece nas 2 menções explicativas; `git diff origin/main...HEAD` lista só `npc.md` e `world.md`.
- NÃO EXECUTADO: oráculo, soak de 30 dias e `run_sim` contra os dados novos (os dados não foram criados: é desenho).

## 6. RESULTADOS
Aprovados: `check_all` inteiro (1.194 de 1.194). Falhos e pulados: 0. Critério da tarefa cumprido **por leitura do diff**: `game_start` no lugar de `inicio_de_jogo`; Q-W1 a Q-W6 e Q18 a Q22 como "decididas" com a origem certa; impacto de `miner` e `shepherd` registrado (ofício, rotina, população, hashes).

## 7. PROBLEMAS ENCONTRADOS
- Os worktrees locais da B (`lw-087b`, `lw-087d`) estão **2 commits à frente do remoto, só por junção com o `main`**: o conteúdo dos três arquivos que revisei não mudou (conferido por `git diff --stat`).
- Os contratos da B e este arquivo ainda **se contradizem** em Q18 e Q22 (acima): precisa da B corrigir (revisão cruzada, achados 1 e 2) e da LW-087a alinhar.
- Os dois rascunhos citam o `STATUS-C.md` (ramo `status-c`) como fonte, como já citavam o `STATUS-B.md`: são referências a arquivos **fora do `main`**; limpar quando a revisão for registrada.

## 8. RISCOS
- **Q20 (só comida):** tábua, ferramenta e tecido ficam sem comprador entre os NPCs; hipótese de acúmulo de estoque e de o mercado ficar sem dinheiro (revisão cruzada, achado 3). Decisão de design **sua**; a minha PROPOSTA de só comida não a resolve.
- **Q23** muda o formato de `population.json`; sem ela o mineiro pode ser mandado para o local de trabalho errado.
- Os valores dos hashes só existem quando a LW-097 rodar; **você aprova os valores novos**, como combinou.

## 9. PENDÊNCIAS (decisões que dependem de Arthur, cada uma com a recomendação)
1. **Aprovar ou trocar** as minhas PROPOSTAs de trabalho: Q-W1 a Q-W6, Q18, Q20 e Q21 (**recomendo aprovar**, com a ressalva do item 2).
2. **Q20 e o risco do achado 3:** demanda mínima de bens que não são comida, um sumidouro simples, ou aceitar e provar no soak da LW-110 com plano B (**recomendo decidir antes da 087a**).
3. **Q23:** coluna opcional `work_place_id` em `data/population.json` (**recomendo**); alternativa: a economia designa os trabalhadores.
4. **`sell`:** o mesmo mecanismo de utilidade da Q19, definido na LW-093 (**recomendo**).
5. **Aceite de vaga e fim do emprego:** qual tarefa implementa (LW-104 ou uma própria depois da LW-096) e como o emprego termina (**recomendo** tarefa própria depois da LW-096).
6. **A B** corrigir `economy.md` (seções 6 e 8) e `docs/events.md` (linha do `ContractOffered`) conforme a revisão cruzada; **a LW-087a** registrar Q10, Q19 e Q22 e a lista de divergências do roadmap.
7. Teste manual: nenhum.

## ACOMPANHAMENTO
- Avanço: **Fase 2 CONCLUÍDA (32 de 32, 100%)**; projeto 87 de 192 (45,3%). **Fase 3 não iniciada**; os rascunhos 087b, 087c e 087d seguem **fora do `main`** até você escrever que podem entrar (a 087a, da A, não está no remoto e eu não a li).
- Próxima tarefa recomendada: **LW-087a (A)**. **Não iniciada.** Parei aqui (regra 13).
- Git: ramo `lw-087c-extensoes-world-npc` enviado (`187c20c`); `status-c` enviado; `main` = `8dcc81d`, intocado; nenhuma tag nova; nada de Fase B; sem `--force`.

---

# TAREFA 2 — REVISÃO CRUZADA (só leitura) dos rascunhos da B: LW-087b (`economy.md`) e LW-087d (`dados.md`, `events.md`)        Status: PRONTA PARA REVISÃO

**Papel:** revisão cruzada (AGENTS 11): **não implementei, não editei nada da B, nenhum commit nos ramos dela.** Li `docs/modules/economy.md` em `origin/lw-087b-contrato-economy` (`7747c1d`, 218 linhas) e `docs/economy/dados.md` (153 linhas) e `docs/events.md` em `origin/lw-087d-eventos-e-dados` (`98ca6c5`); conferi que os dois ramos **não mudaram** desde a leitura. Comparei com: GDD cap. 12 (12.3 inteiro) e 13 (13.1 a 13.5), arquitetura cap. 11 (11.1 a 11.10) e 17.3 a 17.5, roadmap 3.A a 3.J, DEC-022, 047, 049, 054, 100 e 127 (status conferido no `main` `8dcc81d`: DEC-047, 049 e 054 seguem PROPOSTA no `DECISIONS.md`; a B os rotula "aprovado por Arthur em 10/11/2026", o que está certo, e o registro é da LW-087a), e com os dados atuais (`places.json`, `occupations.json`, `population.json`, testes dos provisórios). **Não respondi as perguntas Q1 a Q14 nem a D1 da B.** Linhas abaixo: `economy.md:N`, `dados.md:N`, `events.md:N` (versão do ramo da B).

## Resumo em palavras simples
Os dois rascunhos estão **bem feitos e seguem as regras do projeto** (camadas, dono único, inteiros, nomes genéricos, `game_start` em inglês, 15 eventos contados certo, crônica igual à arquitetura 17.5). Achei **1 problema que impede aprovar como está** (o texto diz o contrário de uma decisão sua de hoje), **6 importantes** (um deles é uma **decisão de design que só você pode tomar**: o que acontece com as cadeias de madeira, metal e lã, que ninguém consome) e **5 menores**.

## BLOQUEANTE (1)
1. **Contradiz a sua decisão de hoje sobre vagas (Q22).** `economy.md:102` diz que o NPC aceitar contrato "não existe na Fase 3 … [FUT]"; `events.md:22` (linha do `ContractOffered`) repete: "aceitar contrato é [FUT]: não existe na Fase 3". Você decidiu o contrário: a **população inicial já nasce empregada** e **vaga nova é oferecida pela economia por evento (`ContractOffered`) e o NPC aceita por utilidade**. Os dois textos precisam mudar (a seção 8 inteira é de quem escreveu a B; eu só aponto): como uma vaga vira contrato `labor` (hoje `economy.md:99-101` só descreve `place_id` e `minutes`, com **um** aceitante), como o evento a anuncia e quem a aceita. Enquanto isso, o `npc.md` (meu, Tarefa 3) e o `economy.md` ficariam em **contradição** em cima do mesmo evento.

## IMPORTANTES (6)
2. **Salário: a B e a proposta Q18 divergem em três pontos** (Q18 é padrão de trabalho do revisor, **não** decisão sua). `economy.md:84` (e a linha da API, `:129`): o `npc` chama `request_work_shift(place_id, worker_id, minutes)` e a economia **paga na hora, por minuto**, a **qualquer** NPC que trabalhou no local; Q18 diz **pagamento por hora de produção aos trabalhadores designados**, com um **evento de pagamento** que alivia `income`. Divergem em (a) **quando** paga, (b) **quem** (o roadmap LW-092 fala em "trabalhadores (NPCs atribuídos)"), (c) **não há evento de pagamento** em `events.md:17-25` (e "compra, venda e consumo não publicam evento", `economy.md:138`). Além disso, (d) `economy.md:84`: sem saldo no local, os minutos **não contam** e o NPC trabalhou de graça; o contrato não diz o que o `npc` faz com esse erro no meio da ação. **Não escolho:** precisa de uma decisão (LW-087a) e de B e C escreverem a mesma coisa.
3. **Ninguém consome madeira, tábua, ferramenta e tecido na Fase 3, e isso pode quebrar a economia. Decisão de design sua.** `economy.md:48,51,53` marcam tábua, ferramenta e tecido como "consumo e venda", mas só a comida é consumida (`:91`, `:211`: só `bread` e `grain` têm `need_id`) e `burn` nunca é chamado (`:32`), sem desgaste nem perecibilidade (`:39`, Q11). O GDD 12.3 diz que a população consome "alimento, vestuário, ferramentas, luxo" e 13.2 põe "roupas (consumo e comércio)" no fim da cadeia 4. **Hipótese, não provada:** estoque dessas três cadeias só cresce até o local parar por `OUTPUT_FULL`; o preço cai para o piso (0,5×); o mercado **paga** os produtores (`:85`) e só recebe dinheiro de volta pelas compras de comida; ele pode ficar sem dinheiro (`ECON_MARKET_NO_FUNDS`, `:75`), os locais ficam sem receita, param por `NO_FUNDS` e o salário para (risco R3.3 do roadmap; critério 3.F item 3, "sem escassez crônica, sem colapso"). Parte disto é **minha**: a Q20 (só comida na Fase 3) é proposta de trabalho do revisor. **Recomendo** que você decida antes da LW-087a entre (a) uma demanda mínima de bens que não são comida (por exemplo, NPC compra ferramenta ou tecido de tempos em tempos; mexe na Q20), (b) um sumidouro simples (desgaste de ferramenta), ou (c) aceitar o risco e provar no soak da LW-110 com plano B escrito.
4. **Caso-limite que o teste vai pegar: preço mínimo 1 × `bid` arredondado para baixo × quantia mínima 1.** `economy.md:20` e `:65` (preço mínimo 1), `:66` (`bid` arredondado **para baixo**), `:31` (`amount` do `Ledger` é 1 ou mais) e `:67` (custo da ordem é a soma unidade a unidade). Com preço 1 (ou 2 e spread alto), o `bid` vira **0** e vender rende 0: o `Ledger` recusa (`ECON_BAD_AMOUNT`) ou o bem sai de graça. `dados.md:94` diz que com `spread_bp` menor que 20000 "o bid continua positivo" porque o contrato "propõe meio a meio", mas `economy.md:66` **não** diz meio a meio e a conta em inteiros não garante. Falta uma regra (por exemplo, `bid` mínimo 1 e `ask` maior que `bid`, ou `base_value` mínimo).
5. **Pagamento duplo possível no mesmo trabalho.** `economy.md:84` (`request_work_shift` soma minutos ao local e paga o salário) e `:101` (a mesma chamada "soma ao contrato" `labor`). Um NPC com contrato aceito num local que também é um local de produção: o minuto conta para os dois, e quem paga duas vezes? Falta a regra "um trabalho, um pagamento".
6. **Impacto de registrar o módulo `economy` nos hashes e na fixture de save, não tratado.** `economy.md:25` só fala da **rejeição** de save antigo (LW-111). Mas `World.serialize` grava uma entrada por módulo registrado e `World.on_load` rejeita save sem a entrada de algum (`src/core/world/world.gd:111`, `WORLD_MODULE_DATA_MISSING`): registrar `economy` (LW-088/089) **muda todo `state_hash`** e pode atingir `tests/unit/test_save_codec.gd:122` (migra a fixture `save_v1` e compara com `save_v1.expected_hash`). A fixture é **protegida** (AGENTS 12.5): mexer exige autorização sua. O contrato deveria dizer isso como risco da LW-088. **Li o código; não executei** (ver "não consegui verificar").
7. **"Nenhum povoado autossuficiente" (Q10, sua decisão) não virou regra conferível.** `dados.md:76` e `:145` deixam a distribuição "a decidir"; `economy.md:212` (Q10) só recomenda. Falta um **teste de dados** do tipo "nenhum povoado tem as quatro cadeias completas". Base atual (conferida no `main`): `places.json` tem **5 locais `work` em cada povoado** (A e B), `occupations.json` tem 5 ofícios e `population.json` tem 10 linhas (5 ofícios × 2 povoados); 10 receitas em 3 povoados, com `miner` e `shepherd` novos, **mudam população e hashes** (a B já diz isso em `dados.md:145`; está certo).

## MENORES (5)
8. `economy.md:63`: "local `market_reserved`" envelhece quando o tipo for renomeado para `market` (proposta Q-W4, LW-093); escrever "hoje `market_reserved`".
9. **Inconsistência entre ramos:** `events.md:25` põe `RouteStateChanged(route_id, new_state)` (igual à arquitetura 17.3); o meu `world.md` diz `route_id, from_state, to_state`. **Vou alinhar o meu à arquitetura e à D** na Tarefa 3 (só `route_id` e `new_state`), salvo ordem contrária.
10. `economy.md:74` e `:126`: `request_trade(actor_id, market_id, good_id, quantity, side)` acrescenta `actor_id` e `side` ao `request_trade(comprador, mercado, bem, quantidade)` do roadmap (LW-091). A mudança é justificada (a LW-093 precisa de venda), mas **não está na lista de divergências** do roadmap com suas decisões; incluir na LW-087a.
11. `economy.md:95`: "59 e 26 referências" aos testes dos provisórios **não reproduzo**: conto **19 e 13 funções `test_`** em `test_food_stub.gd` e `test_income_stub.gd`, e 110 e 29 linhas com a marca nesses dois arquivos (mais 12 e 7 em outros testes). Citar o critério da contagem ou tirar o número.
12. **Texto de estado:** `economy.md:3`, `dados.md:3` e `events.md:5,7` dizem "enquanto a Fase 2 não fecha". A Fase 2 **fechou** (10/11/2026, tag `fase-2-concluida`); na hora do merge trocar a frase. Também: `economy.md:5` (item 4) e `:94` deixam a ordem "mint na LW-093 ou LW-095 antes da LW-094" para a LW-087a, mas o roadmap LW-095 põe o `mint` **na LW-095** (e a minha Tarefa 3 trata como LW-093); entra na lista de divergências.

## O que conferi e está certo
Nomes de bens, receitas e ofícios **genéricos** (DEC-100); `game_start` em inglês em vez de `inicio_de_jogo` (DEC-022); dependências da `economy` só `core`, `data` e `world`, **sem `entities`** (decidido) e sem importar o `npc`; **dono único** (`economy.md:140-156`); dinheiro e quantidades `INT`, proporções em pontos-base, **tabelas planas** (`dados.md:16-17`); preço 0,5× a 3×, suavização, spread e profundidade conforme GDD 12.3 e arquitetura 11.5; `TradeRules` neutra (DEC-049); escopo "não fazer" do roadmap 3.J respeitado (sem bancos, tarifas reais, bandidos); `save_version` 2 e rejeição de save antigo (DEC-127, AGENTS 4.15); `CaravanAttacked`, `RouteCargoLost` e `BusinessBankrupt` **conscientemente fora** (`events.md:27`); **contagem do catálogo: 15 = 6 + 9** (`events.md:5`, conferido linha a linha); coluna "Crônica" igual à arquitetura 17.5 e as três divergências (`ProductionStopped`, `ProductionResumed`, `ContractFailed`) **rotuladas [PROPOSTA]**; todas as tarefas LW-088 a LW-116 têm linha no rastreio (`economy.md:178-197`); o verificador de ids pré-requisito da LW-093 existe no backlog (`docs/backlog.md:179`).

## Não consegui verificar
- **Por execução, nada:** só documentos; não rodei `check_all` nos ramos da B (não há código novo).
- **Achado 6** (efeito do módulo novo na fixture `save_v1` e nos hashes): li `world.gd` e o teste, **não executei**; pode haver uma saída que eu não vi (por exemplo, o teste da fixture montar o mundo sem o módulo novo).
- **Achado 3** é **hipótese**: não simulei o circuito de dinheiro (mercado, locais e NPCs); só a leitura das fórmulas.
- **Achado 4:** conta feita à mão sobre as fórmulas escritas; a curva e os valores reais só existem na LW-090 e na LW-112.
- Os números [HIP] de `price_params` e de `owner_kinds` (a B os deixa "a propor"): não há o que conferir ainda.
- Não conferi os textos de `data/text/pt_br.json` (as chaves `good.<id>.name` ainda não existem; nascem nas LW-089/092).

## Não fiz
Não respondi Q1 a Q14 nem D1; não editei nenhum arquivo da B nem de `main`; não commitei nos ramos `lw-087b-contrato-economy` e `lw-087d-eventos-e-dados`; não mexi no `DECISIONS.md`.

## Git
Só este `STATUS-C.md` (ramo `status-c`) mudou nesta tarefa. Próximo: **Tarefa 3** (meu `world.md` e `npc.md`, ramo `lw-087c-extensoes-world-npc`).

---

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
