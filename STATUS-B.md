11/11/2026 09:38 (Brasília) — CONCLUÍDA: LW-146, levantamento de pré-voo da Fase 5, em RASCUNHO fora do `main`: `docs/decisions/0014-pre-voo-da-fase-5.md` (235 linhas) no ramo `lw-146-prevoo-fase-5` (`6251bd3`); 14 contradições, 20 perguntas (10 de jogo, 10 técnicas); `check_all` verde (1203 de 1203); só esse ramo e o `status-b` foram publicados; PRONTA PARA REVISÃO; parei (regra 13)

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
