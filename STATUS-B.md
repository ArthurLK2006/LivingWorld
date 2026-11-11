11/11/2026 10:37 (Brasília) — CONCLUÍDA: LW-146 (pré-etapa); o `0014` foi ATUALIZADO com as decisões de jogo revisadas de Arthur (ramo `lw-146-prevoo-fase-5`, `8a64980`, 276 linhas, fora do `main`); `check_all` verde (1203 de 1203); a registrar em `DECISIONS.md` na parte 146a; PRONTA PARA REVISÃO; parei (regra 13)

# RELATÓRIO — LW-146 (pré-etapa): levantamento de pré-voo da Fase 5     Status: PRONTA PARA REVISÃO, **RASCUNHO (fora do `main`)**

**Antes de começar (AGENTS 2.3).** Declarei no chat: a tarefa, as fontes lidas (todas no `main`), as DEC com status, o arquivo único e que **não** faria o commit de correção do "(rascunho da LW-087c)", porque você disse que a 087b e a 087d não precisam de mais nada. Dúvidas: nenhuma que bloqueasse.

## 1. RESUMO
Escrevi o levantamento que você pediu, em um único arquivo, com as cinco partes na ordem: (1) as decisões de que a Fase 5 depende, com o status de cada uma e quais travam tarefas; (2) **14 contradições e buracos**, cada um com o trecho de cada fonte (arquivo e seção) e a minha recomendação; (3) a divisão da LW-146 em seis partes e as tarefas que provavelmente passam do limite; (4) **20 perguntas numeradas**, separando as de **jogo** (Q1 a Q10, só você) das **técnicas menores** (Q11 a Q20, o revisor decide como PROPOSTA); (5) riscos e backlog. Não escrevi contrato, código, dados nem eventos.

## 2. ARQUIVOS CRIADOS
- `docs/decisions/0014-pre-voo-da-fase-5.md` — o levantamento (235 linhas; português simples; um glossário curto no topo).

## 3. ARQUIVOS MODIFICADOS
Nenhum. **`docs/events.md` não foi tocado.**

## 4. DECISÕES TÉCNICAS
- **O que concluí que mais pesa:** (a) o **estilo do combate** está escrito de dois jeitos (roadmap e arquitetura descrevem golpe leve e pesado, bloqueio, esquiva e `HitReport` por contato; a DEC-117 e a DEC-121 escolheram alvo e habilidades e deixam bloqueio e esquiva "para depois"); (b) **derrota**: o roadmap recomenda recarregar o autosave, o GDD 6.6 recomenda "derrota raramente fatal", que exigiria prisão e dívida (a economia não tem crédito); (c) **save**: o roadmap manda migrar saves (LW-142 e LW-187), mas as DEC-127 e DEC-134 mandam rejeitar até o "save congelado"; (d) **crime**: a Fase 4 cria só a lei de "pena", nenhuma lei lista os atos, e nenhuma tarefa cria o "roubo".
- **As quatro [REC] do roadmap:** concordo com (b) três trajetórias, (c) 3/3/8 (com a origem por lugar de nascimento) e (d) recarregar o autosave; discordo só de uma parte de (a): "propriedades fora" contradiz o GDD 24.5 ("manter a casa") e a LW-173.
- **Respostas que recomendo (todas PROPOSTA):** Q1 B, Q2 A, Q3 A, Q4 A, Q5 A, Q6 A, Q7 A, Q8 A, Q9 B e Q10 C (não congelar o save no protótipo). Cada pergunta traz as opções e o que muda.
- **Proposta de entrada para o `DECISIONS.md`:** nenhuma (o documento não decide nada).

## 5. TESTES EXECUTADOS
- `git diff --check` — limpo.
- Conferi **por script** os 40 status de DEC escritos na seção 1 contra o índice do `DECISIONS.md` do `main`: **0 divergências**.
- `tools/check_all` em `6251bd3` (ramo `lw-146-prevoo-fase-5`), 09:33 a 09:37 — **VERDE**: nove verificações de arquitetura aprovadas; GUT **Tests 1203, Passing 1203, Asserts 262120**, 170,66 s; Warnings 1 e Deprecated 1; código 0. (1203 = os 1194 de antes mais os 9 da LW-093b, já no `main`.) No início havia **1 processo Godot** de outra conversa rodando; o resultado não foi afetado.
- **NÃO EXECUTADO:** nada além disso; é só documento.

## 6. RESULTADOS
- **Aceite:** documento único e novo, em rascunho, fora do `main`; cinco partes na ordem pedida; as quatro decisões do roadmap estão em **Q1 (lista de corte), Q2 (trajetórias), Q3 (criaturas, origens e eventos) e Q4 (derrota)**, com as [REC] como ponto de partida.
- **Seção 1:** 9 temas (combate, personagem, ecologia, eventos, crime, câmera e interface, save, desempenho, escopo e entrega). **PENDENTES que travam:** DEC-066, DEC-065, DEC-053 e DEC-029; PROPOSTAS que travam: DEC-028 (câmera `t`) e DEC-070 (eventos); sem DEC alguma: crime, reputação e justiça.
- **Seção 3:** seis partes (146a registro; 146b `combat`; 146c `character`; 146d ecologia e eventos dinâmicos; 146e câmera e ponte; 146f dados e eventos), com **um dono por arquivo** (a `bridge.md` fica só com a 146e), e **12 tarefas** que provavelmente passam de ~300 linhas ou de um módulo (LW-150, 153, 155, 156, 158, 162, 166, 167, 173, 174, 185 e 187), com divisão sugerida. É estimativa por leitura, não medida.

## 7. PROBLEMAS ENCONTRADOS
- **`economy.md:3` ainda diz "(rascunho da LW-087c)"** no `main`. A frase ficou velha quando a LW-087c entrou. **Não corrigi** porque você disse, na última mensagem, que a 087b e a 087d não precisam de mais nada; se quiser, é um commit de uma frase.
- **O ramo nasceu com o `upstream` em `origin/main`** (é o comportamento do Git ao criar um ramo a partir de `origin/main`). **Publiquei com refspec explícita** (`lw-146-prevoo-fase-5:lw-146-prevoo-fase-5`) e conferi com `git ls-remote`: o `main` **não** foi tocado. Um `git push` sem argumento, nesse ramo, iria para o `main`; **não alterei nenhuma configuração do Git**.
- **O `main` andou duas vezes durante a tarefa** (`4ada136` na criação do ramo; depois `9b4f6f0`, status da LW-087). O ramo **não** foi atualizado com essas mudanças (não autorizado e não necessário para um documento novo).
- **Numeração:** o `main` não tem `docs/decisions/0013-...`; usei o `0014` como você pediu.
- Os contratos `persistence.md`, `bridge.md` e a arquitetura têm descompassos pequenos (C14 do documento); a parte 146a os corrige.

## 8. RISCOS
- O levantamento é **leitura de documentos**, não de código: contradições que só aparecem no código não estão aqui.
- As recomendações da Q1 a Q10 são **minhas**; se você escolher outra opção, o contrato muda (cada pergunta diz o quê).
- Quatro DEC PENDENTES (066, 065, 053, 029) travam blocos inteiros; responder antes da 146a evita retrabalho.

## 9. PENDÊNCIAS
- **Suas:** responder Q1 a Q10 e aprovar ou trocar Q11 a Q20 (seção 4 do documento). Não há teste manual.
- **Não iniciei** a LW-146 de verdade nem nenhuma tarefa da Fase 5.

## ACOMPANHAMENTO
- **Avanço:** Fase 3 em andamento (LW-087 no `main`, LW-093b no `main`); Fase 5 **não iniciada**; este documento é a pré-etapa da LW-146.
- **Próxima tarefa recomendada:** a LW-146, em seis partes, **depois** das suas respostas. **Não iniciada.**
- **Decisões que dependem de Arthur:** Q1 a Q10 (jogo), com a recomendação de cada uma no documento; Q11 a Q20 (técnicas) para aprovar ou trocar.
- **Git:** ramo `lw-146-prevoo-fase-5` em `6251bd3`, **publicado só como ramo** (1 commit, só o arquivo 0014); este relatório vai no `status-b`. **Nada no `main`, sem tag, sem `--force`, sem merge.**

## ADENDO — respostas de Arthur às perguntas do 0014 (chat, 11/11/2026, 09:39)
- **O que ele escreveu:** "Sim, aceito as recomendações", em resposta à pergunta sobre Q1 a Q10. **Leitura do revisor:** vale para as recomendações de **Q1 a Q20**; se ele quis só Q1 a Q10, as Q11 a Q20 seguem como PROPOSTA técnica do revisor, que ele ainda pode trocar.
- **Status:** resposta **no chat**, ainda **não registrada** em `DECISIONS.md`: o registro é da parte **146a** da LW-146 (depois que ele mandar a tarefa). Nada mudou no `0014`, no `main` nem em outro arquivo.
- **Jogo (Q1 a Q10):** **Q1** B (magia, chefe, comando tático só de consulta e facção criminosa mínima ficam fora; **a casa do jogador fica**, sem compra, venda nem expansão); **Q2** A (mercador, soldado/guarda e aventureiro; crime só como consequência); **Q3** A (3 criaturas, 3 origens **por lugar de nascimento**, 8 eventos; tipos concretos como PROPOSTA no contrato); **Q4** A (derrota recarrega o último autosave, com aviso; "derrota raramente fatal" vira [PREV]; o GDD 6.6 e o Anexo D, D2, são atualizados na LW-189); **Q5** A (só o que o SP6 testou mais o inimigo que reage; ferimento simples; bloqueio, esquiva e ferimento por golpe no backlog até um playtest depois da LW-155); **Q6** A (o jogador não comanda; cerca de 20 combatentes com corpo [HIP]; o resto abstrato); **Q7** A (crime = agressão; roubo no backlog); **Q8** A (o mapa mostra tudo, marcado como [LIM]); **Q9** B (as quatro hipóteses mais "três cascatas" e "diversão" no playtest); **Q10** C (não congelar o save no protótipo; a LW-187 vira testes de rejeição clara e da cadeia existente 1 para 2).
- **Técnicas (Q11 a Q20), como PROPOSTA:** Q11 A (intenção de ataque em vez de `HitReport`); Q12 A (a economia destrói o metal com um motivo fechado novo e publica um evento; o `character` cria a instância); Q13 A (um sentido: `military` pede, `combat` devolve baixas por evento); Q14 A (`events` ou `politics` decide o crime pela lista de atos em `laws.json`; a LW-117 recebe o pedido); Q15 A (consultas em lote; o foco do LOD continua o jogador); Q16 A (cada evento dinâmico declara os comandos que usa); Q17 A (quadros pela DEC-119; DEC-071 só depois da LW-179); Q18 A (o `npc` decide e publica; o `combat` resolve; T1 com equipamento padrão por ofício); Q19 A (tarefas de HUD de combate e de inventário e equipamento); Q20 A (nome provisório "Living World").
- **O que isso destrava:** as DEC **066, 065, 053 e 029** ainda precisam de **entrada própria** no registro (146a); as respostas acima são o texto delas. **Não iniciei** a LW-146 nem a 146a.
- **Git:** só este arquivo mudou, no `status-b`. O ramo `lw-146-prevoo-fase-5` segue em `6251bd3`; o `main` não foi tocado; sem tag e sem `--force`.

## ADENDO 2 — decisões de jogo revisadas por Arthur (chat, painel de escolhas, 11/11/2026, 10:31) — **substitui o adendo anterior**
- **Status:** respostas **no chat**, ainda **não registradas** em `DECISIONS.md` (parte **146a**, depois que ele mandar a tarefa). O `0014` (ramo `lw-146-prevoo-fase-5`, `6251bd3`) **não foi alterado** e ainda traz as recomendações antigas; a LW-146 deve partir **deste adendo**.
- **Q1 corte:** fora da Fase 5: **sistema de magia, chefe, comando de tropas e facção criminosa completa**; **fica a casa do jogador**. Magia e batalhas grandes viram **visão registrada** (referências do Arthur: Mount & Blade Bannerlord, Total War Warhammer 3, sequência de magias, "um sistema único novo").
- **Q2 trajetórias:** mercador, soldado/guarda e aventureiro; crime só como consequência.
- **Q3 conteúdo:** **3 criaturas, 3 origens, 8 eventos**; origens por lugar de nascimento (campo, cidade, estrada), não por trajetória.
- **Q4 derrota e morte (mudou):** **dois modos à escolha ao começar o jogo.** (a) **Renasce perto**, sem recarregar o save: os itens **soltos** ficam no chão por um tempo; NPCs podem pegá-los; o jogador consegue **descobrir qual NPC pegou** ou correr até o local antes de sumirem; itens **ligados ao personagem** ficam com ele. (b) **Voltar ao último autosave.** Em aberto para o contrato: o tempo que o item dura no chão, como se descobre o NPC e **o que é "item ligado" sem magia** (a magia saiu; "poder ou maldição" fica para "depois").
- **Q5 combate:** só o do SP6, com o inimigo que se posiciona e reage; ferimento simples ("ferido", recupera com o tempo); **bloqueio, esquiva e ferimento por golpe ficam para "depois"**.
- **Q6 tropas (mudou):** **sem comando no protótipo**; **um teste descartável (como o SP6) de comandar um grupo pequeno**, no fim do bloco de combate, para o Arthur jogar e decidir se vira sistema. As DEC-053 e DEC-029 seguem PENDENTES até esse teste.
- **Q7 crime (mudou):** **agressão, roubo, morte e contrabando.** Contrabando = **lista de bens proibidos por lei** (a política de cada região) **mais marca de origem nos itens únicos roubados ou saqueados**; **rastrear cada unidade de mercadoria fica para "depois"**. O saque de mortos é roubo.
- **Q8 mapa (mudou):** **estrutura sempre visível** (assentamentos, rotas, pontos de reconhecimento); **segredos só depois de descobertos** (ruínas, tesouros, minérios, covis escondidos); a regra é **por tipo de coisa, em dados**.
- **Q9 sucesso:** as quatro hipóteses do roadmap **mais** "três cascatas distintas" e "diversão e histórias contáveis" no playtest.
- **Q10 save:** **não congelar no protótipo**; save antigo é sempre rejeitado com mensagem clara; a LW-187 vira testes de rejeição e da cadeia que já existe (1 para 2).
- **Escopo:** o Arthur pediu para **marcar "protótipo" e "depois"**. *Protótipo:* o que está acima, mais as técnicas Q11 a Q20 (recomendações do revisor, **não** reabertas por ele). *Depois (visão registrada):* magia e itens de poder ou maldição, chefe, sistema de comando de tropas, bloqueio e esquiva, ferimento por golpe, prisão e dívida, rastreio de cada unidade de mercadoria. **Estimativa do revisor, não medida:** as ideias de morte, crime, mapa e o teste de tropas somam **cerca de 11 a 14 tarefas novas** às 47 da fase (uns 25%); o contrato da LW-146 lista cada uma.
- **Consequências para as DEC pendentes:** a **DEC-065** (derrota) tem resposta (dois modos); a **DEC-066** parte do SP6; as **DEC-053 e DEC-029** esperam o teste de tropas; a **DEC-030** (magia) fica sem decisão, mas fora do protótipo.
- **Git:** só este arquivo mudou, no `status-b`. O ramo `lw-146-prevoo-fase-5` segue em `6251bd3` e o `main` não foi tocado; sem tag e sem `--force`.

## ADENDO 3 — o `0014` foi atualizado (10:37)
- **Autorização (Arthur, no painel):** "Atualizar o 0014". Vale para **um segundo commit só nesse arquivo** e push **só desse ramo** (e do `status-b`).
- **O que mudou no `0014`:** (1) o Status avisa que a **seção 6 prevalece** sobre as recomendações das seções 0 a 5; (2) cada pergunta Q1 a Q10 ganhou a **"Resposta de Arthur (11/11/2026)"**, com **MUDOU** nas Q4, Q6, Q7 e Q8; (3) cada técnica Q11 a Q20 ganhou a **situação** (recomendação mantida como PROPOSTA; efeitos novos em Q12, Q13, Q14 e Q15); (4) **seção 6 nova**: resumo das respostas, o que resolve em cada contradição, **seis buracos novos** (itens no chão e em corpos; "item ligado" sem magia; dois modos de morte; crime ampliado; mapa por tipo; teste de tropas como spike novo, que a DEC-080 não cobre), **protótipo e depois**, e as quatro perguntas que ficam em aberto (tempo no chão, como se descobre o NPC que pegou, o que é "item ligado" sem magia, o que um ponto de reconhecimento revela). 51 linhas acrescentadas e 11 trocadas; nada apagado além das 11 linhas ampliadas.
- **Testes:** `git diff --check` limpo; `tools/check_all` em **`8a64980`**, 10:33 a 10:36, **VERDE**: nove verificações de arquitetura; GUT **1203 de 1203**, 262120 asserts, 173,42 s; Warnings 1 e Deprecated 1; código 0. Havia **outros processos Godot no Mac** (de outras conversas ou do editor) no início; o resultado não foi afetado.
- **Git:** `lw-146-prevoo-fase-5` = `8a64980` (2 commits: `6251bd3` e este; só o arquivo `0014` mudou); `main` **não** foi tocado e andou por conta de outras conversas; sem tag, sem `--force`, sem junção. Publicado com refspec explícita (o ramo tem upstream em `origin/main`; um `git push` sem argumento iria para o `main`).
- **Não feito:** o registro das decisões em `DECISIONS.md` e nas DEC 065, 066, 053 e 029 (parte **146a**), e o contrato da LW-146. **Aguardo a tarefa.**
