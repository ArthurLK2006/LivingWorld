# LW-053 — Parecer da revisão arquitetural da Fase 1

Revisor: Claude (independente do dev, só leitura). Data: 07/11/2026. Base revisada: `main` em `6797563`.

## Veredito: APROVADO COM AJUSTES

0 bloqueantes · 3 importantes · 7 menores. Nada impede a LW-054 (você jogar). Os ajustes importantes pedem uma decisão sua (I1) ou acompanhamento (I2, I3).

## Como revisei, e os limites

- Rodei as três verificações automáticas no `main` extraído: `check_architecture` (nove verificações aprovadas), `check_input_keys` (nenhuma tecla fixa) e `check_literal_text` (nenhum texto de interface solto).
- Procurei por texto, com `grep`, o que as regras do AGENTS.md proíbem em `src/sim`, `src/core` e `src/data`: Node, cena, aleatoriedade solta, relógio do sistema, `await`, `static var`, `@warning_ignore`.
- Conferi arquivos protegidos e o tamanho da fase por `git diff` desde a tag `fase-0-concluida`, e a API da ponte contra o contrato.
- Li os testes pelos nomes e pelo teste de integração (LW-052). Não li as 19.909 linhas da fase linha por linha. As tarefas já tinham sido auditadas uma a uma antes de cada aprovação.
- **Não rodo o Godot.** Todo número de teste (471 testes, `check_all` verde) e de quadros é do dev. Nenhum visual foi conferido por mim nesta revisão.

## Checklist de revisão (10 itens)

| # | Item | Resultado | Evidência |
|---|---|---|---|
| 1 | Simulação separada da apresentação | OK | Nenhum Node, `get_node`, `$`, `preload` ou cena em `src/sim`, `src/core`, `src/data`. Nenhuma referência a `SimulationHost`, `CharacterModule` ou a caminhos de `sim`, `core`, `data` e `persistence` na apresentação (a regra de camadas estendida está no `check_architecture`, 9/9). |
| 2 | Ponte fina | OK, com ressalva | 15 funções públicas, todas no contrato `docs/modules/bridge.md`. `request_interact` usa a posição guardada no personagem, não a da apresentação. Sem regra de jogo nas funções que li. Ressalva M1 (357 linhas). |
| 3 | Dono de cada dado | OK | Posição: `CharacterModule` (valida e rejeita o que não faz sentido). Pontos de interesse: `world` (`InteractionService`, `data/world/pois.json`). Texto: `data/text/pt_br.json`, lido pela apresentação. O fluxo da posição é de um sentido só (corpo → simulação). |
| 4 | Três canais | OK | Um único evento publicado no código (`InteractionPerformed`, `interaction_service.gd:44`) e catalogado em `docs/events.md`. Sem `signal`, `.emit` ou `.connect` em `sim`, `core`, `data`, `bridge` e `persistence`. |
| 5 | Terreno e colisão | OK pelos testes; visual fica para a LW-054 | Testes de colisão, de carga, de streaming, de limites do jogador e do terreno de blockout. Encosta de teste a 50,3° verificada por mim (LW-047A). Frestas entre níveis de detalhe tratadas com saias (LW-038). |
| 6 | Desempenho | OK, com ressalva | Ver LW-053A abaixo e achados I1 e I2. |
| 7 | Sem antecipação | OK | Nenhuma ocorrência de inventário, NPC, combate, clima, estações, gamepad, rede ou telemetria no código. `src/ai_text`, `src/net` e `src/tools` só têm README. Sem autoload novo na fase (continuam `SimulationHost` e `GameApp`). Sem pasta de topo nova. |
| 8 | Teste de integração (LW-052) | OK, com ressalva | Cenário A (nasce, anda, interage, pausa, salva, carrega, mesmo hash e posição), B (30 dias, mesmo hash em duas execuções e com salvar e carregar no meio), C (contagem de nós estável). Ressalva M2. |
| 9 | Conformidade com o AGENTS.md | OK, com ressalvas | Ver "Arquivos protegidos", I3, M1 e M3. Valores [HIP] estão em constantes nomeadas e marcados (35 ocorrências em 22 arquivos de `src/`; o alcance de interação de 3 m está em `INTERACT_REACH_M`). |
| 10 | Terrain3D e medição em release | OK | DEC-057 (d): nenhum gatilho disparou. (e): cumprida pela LW-053A. Ver abaixo. |

### Arquivos protegidos alterados desde a tag da Fase 0 (todos explicados)

| Arquivo | Tarefa | Autorização |
|---|---|---|
| `docs/DECISIONS.md`, `docs/DEVELOPMENT_ROADMAP.md`, `docs/GDD.md`, `docs/TECHNICAL_ARCHITECTURE.md`, `.gitignore` | LW-031A e LW-033A (tarefas DOC) | Tarefas de documentação aprovadas por você |
| `project.godot` | LW-044 (`[input]`) e LW-046 (3 ações de câmera na `[input]`) | Autorização escrita nos envios 23 e 24: só a seção `[input]`. Mudança conferida: só entradas de `[input]`. |
| `tests/fixtures/world/terrain_ok/*` | LW-034 e LW-037 | Fixtures novas, nenhuma existente enfraquecida |

Total da fase: 230 arquivos, +19.909 e −213 linhas (inclui docs, dados e testes).

## Critérios de aceitação da Fase 1 (roadmap 1.F)

| # | Critério | Situação |
|---|---|---|
| 1 | Nasce no terreno, anda, corre e pula; não atravessa o chão, não sai do mapa, não sobe encosta acima do limite | Coberto por testes (dev). Sentir na prática: LW-054. |
| 2 | Câmera não entra no terreno e não treme | Colisão coberta por teste. "Não treme" é visual: LW-054 (ver I1). |
| 3 | Dia e noite pela hora simulada; pausar congela tudo | Coberto por testes e pela LW-052. Visual: LW-054. |
| 4 | Aviso ao chegar perto e texto da chave de tradução | Coberto por testes. Visual: LW-054. |
| 5 | Desempenho com a meta de quadros | **Meta ainda é proposta [PEND].** Pela medição da LW-053A ela é cumprida (ver I2). Falta você aprovar a meta. |
| 6 | Mesmo hash sem janela; `check_architecture` verde | Cumprido (cenário B; 9/9). |
| 7 | Contagem de nós estável | Cumprido no teste (cenário C). Na medição de 60 s os nós subiram de 599 para 663 enquanto os chunks subiram de 76 para 128, o esperado até o terreno assentar. Uma caminhada longa pelo mapa inteiro é um bom item para a LW-054. |
| 8 | `check_all` verde; integração verde | Declarado pelo dev (471 testes, 136 scripts sem avisos). Não executável por mim. |

## Achados

### Importantes

**I1. O jogo gera 120 quadros por segundo numa tela de 60 Hz.**
Nas medições da LW-053A todos os quadros chegam a cada 8,33 ms, mesmo com o `vsync` ligado e o Godot informando 60 Hz. Você confirmou que joga só na tela do MacBook Air M3, que é de 60 Hz. A física roda a 60 passos por segundo, sem interpolação.
- Risco: metade dos quadros nunca aparece, há gasto de energia e calor à toa, e o personagem pode andar "aos pulinhos" (quadros sem passo novo de física).
- Causa: desconhecida. É hipótese, ainda não testada, que o `vsync` não esteja segurando o jogo em 60 no renderizador `gl_compatibility` no macOS.
- Recomendação: esperar a LW-054. Se você sentir movimento "aos trancos", abrir uma tarefa extra pequena para diagnosticar o `vsync` e a interpolação de física. Ativar a interpolação mexe no `project.godot` (arquivo protegido) e precisa de autorização sua. Incluir no roteiro 1.H a pergunta "o movimento parece fluido ou aos trancos?".

**I2. A meta de quadros ainda não foi aprovada (critério 1.F item 5).**
A proposta [PEND] é: média de 60 quadros por segundo e nunca abaixo de 30. Em release, na tomada, com 3 execuções: média de 8,37 a 8,39 ms por quadro, pior quadro de 24,9 a 27,3 ms na rota, nenhum quadro acima de 33 ms. A proposta é cumprida nessa medição. Limites: amostra pequena (3 execuções), medido a 520 m do início, instantes dos quadros de 16,7 a 33 ms não registrados (7 a 12 por minuto na rota), medição só com o Mac na tomada.
- Recomendação: aprovar a meta como está, com a medição na mão, e registrá-la como decisão. Você pode endurecê-la depois.

**I3. Três tarefas passaram do teto de arquivos sem parar (processo).**
LW-048: 13 arquivos contra 9. LW-049: 15 contra 10. LW-051: 14 contra 7. O AGENTS.md (5.2 e 16.2) manda parar e propor divisão. O código ficou dentro do teto de linhas. O dev relatou o estouro no relatório final em vez de parar antes. Parte da responsabilidade é do meu envio: ele fazia o teto de arquivos contar documentos, o que o deixava mais apertado do que o necessário.
- Recomendação: nos próximos envios, o teto de arquivos conta só arquivos de código e há uma linha "PARE se passar". Sem custo para o que já está pronto.

### Menores

**M1. Dois arquivos passam de 300 linhas** (AGENTS.md 4.5): `src/bridge/sim_bridge.gd` (357) e `src/presentation/world_view/terrain/terrain_view.gd` (322). Já estão no backlog. A Fase 2 vai acrescentar consultas sobre gente na ponte, então ela cresce. Recomendação: dividir a ponte antes de a Fase 2 mexer nela (primeira tarefa da Fase 2, ou tarefa extra antes). `terrain_view.gd` pode esperar.

**M2. Evento na fila com o relógio pausado.** `InteractionPerformed` só é entregue no passo seguinte da simulação. Com o relógio pausado, ele fica na fila e `can_capture_game()` dá falso até a entrega. O teste de integração avança um passo antes de salvar, então não exercita interagir e pausar no mesmo instante. Registrar no backlog e na futura tela de salvar: esvaziar a fila antes de capturar.

**M3. Pasta de rascunho fora da raiz do projeto** (AGENTS.md 12.1). O dev usou a pasta de rascunho da sessão no Lote 4 e na LW-053A. Relatou e apagou, sem efeito no projeto. Reforçar a regra nos próximos envios.

**M4. Texto do backlog mais forte que a evidência.** A linha da LW-053A diz que os picos de ~35 ms do Lote 4 "sumiram só com a tomada". Mas o script e a espera inicial também mudaram entre as duas medições. Trocar por "sumiram com a tomada (o script também mudou)" na próxima edição daquele arquivo.

**M5. `tests/soak/README.md` termina com uma linha em branco** (aviso do `git diff --check`, linha 15). Cosmético. Corrigir na próxima vez que alguém mexer nesse arquivo.

**M6. LW-053A passou 1% do teto de linhas** (262 contra 260; 5 arquivos contra 6). Sem efeito.

**M7. Pasta `$HOME/lw-release-probe` (340 MB) fica no Mac, fora do projeto.** Mantida de propósito para repetir a medição sem baixar 1,28 GB de novo. Apagar quando quiser.

## DEC-057, terreno próprio ou Terrain3D

- (a) Engasgos ao andar: em release, na tomada, nenhum quadro acima de 33 ms; pior quadro da rota 24,9 a 27,3 ms. No Lote 4 (depuração, bateria) eram 34,9 a 52,1 ms. Melhorou muito. Os 7 a 12 quadros por minuto acima de 16,7 ms continuam sem causa confirmada (hipótese: construção de chunks).
- (b) Frestas entre níveis de detalhe: tratadas com saias. Confirmar o visual na LW-054.
- (c) Terreno só na apresentação: cumprido (`check_architecture`).
- (d) Gatilhos para reavaliar o Terrain3D: (1) engasgos persistirem depois de construir os pedaços aos poucos — não persistem acima de 33 ms; (2) frestas sem conserto simples — saias resolveram; (3) mapa de vários quilômetros antes da Fase 5 — o mapa tem 1 km². Nenhum disparou. **Recomendação: não reabrir o Terrain3D agora.** Reavaliar se um gatilho aparecer, e de qualquer forma na revisão da Fase 5.
- (e) Primeira medição em release na tomada: feita na LW-053A.

## O que eu não consegui verificar

- Qualquer número que dependa de rodar o Godot: testes, `check_all`, quadros, nós, memória.
- Qualquer coisa visual: aparência, frestas, câmera tremendo, fluidez, cores. É a LW-054.
- A causa dos 120 quadros por segundo em tela de 60 Hz.
- Comportamento no Windows.
- Uma caminhada longa pelo mapa inteiro (a medição do dev foi de 60 s).

## Recomendação final

Aceitar o parecer como APROVADO COM AJUSTES e seguir para a LW-054. Antes de criar a tag `fase-1-concluida`: registrar a meta de quadros (I2) e conferir, no jogo, se o movimento é fluido (I1). Antes da Fase 2: dividir a ponte (M1) e ajustar a regra de tetos nos envios (I3).

## Decisões de Arthur sobre o parecer (07/11/2026)

- **I2, meta de quadros:** aprovada como proposta (média de 60 quadros por segundo ou mais e nenhum quadro acima de 33 ms, no Mac de referência, na tomada, em release). Será registrada como decisão APROVADA (entrada abaixo) na fase de fechamento desta tarefa.
- **I1, tela a 120 quadros por segundo:** esperar a LW-054. Só se Arthur sentir o movimento "aos trancos" ao jogar é que se abre a tarefa extra de diagnóstico.
- **I3 e M1:** sem pergunta a Arthur. O teto de arquivos dos próximos envios conta só arquivos de código; a divisão da ponte entra na abertura da Fase 2.

## Proposta de entrada para DECISIONS.md (aprovada por Arthur em 07/11/2026; registrada como DEC-119)

- **Título:** Meta de quadros do protótipo.
- **Contexto:** a LW-033 mediu e deixou a meta como proposta; a LW-053A mediu o jogo real em release, na tomada.
- **Decisão proposta:** média de 60 quadros por segundo ou mais e nenhum quadro acima de 33 ms, no hardware de referência (Mac, na tomada, release).
- **Justificativa:** a medição da LW-053A cumpre isso com folga (média ≈ 119 quadros por segundo, pior quadro 24,9 a 27,3 ms).
- **Consequências:** vale como régua das fases seguintes; o aumento de decoração, gente e mapa será medido contra ela.
