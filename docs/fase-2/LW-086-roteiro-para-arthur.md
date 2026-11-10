# LW-086 — O que você vai fazer (validação da Fase 2)

**Escrito em 10/11/2026 (horário de Brasília), na LW-086a.** A LW-086 só começa depois da LW-085 aprovada. Este roteiro segue o da Fase 1 (`docs/fase-1/LW-054-roteiro-para-arthur.md`).

**Ideia:** você valida a Fase 2 em **duas partes**, como combinado:
1. **Uma passada sua na janela**, nos itens que a janela permite (cerca de **13 minutos**, uma sessão só).
2. **Prova por teste automático** nos itens que não têm tecla (alarme, salvar e recarregar, muitos dias acelerados, comida a zero). Você roda um comando por item (ou não roda nada: o resultado de hoje está escrito aqui) e confere se o resultado diz o que o item pede.

Você assina **com essa ressalva** (como na Fase 1: parte na janela, parte por prova automática). **Nenhuma tecla nem comando novo foi criado** para esta validação. Se algo falhar, não é culpa sua: vira uma tarefa de correção. O que está em "Não é defeito" já está registrado: não precisa reportar.

## 0. O quadro dos 8 itens (leia primeiro)
| # | Item da checklist 2.H | Como se valida | Tem prova? |
|---|---|---|---|
| 1 | Ver NPCs saindo de casa, trabalhando, comendo, conversando e dormindo | **Janela** (apoio: teste de vida de 7 dias e soak de 30 dias) | Sim, mas só a janela mostra "o que você vê" |
| 2 | Afastar e voltar: ninguém duplica, some ou teleporta | **Janela** (apoio: 3 testes de corpos e do LOD) | **Parcial:** duplicar e sumir têm teste; **teleporte não tem teste permanente** (só a janela e o relatório do spike SP2) |
| 3 | Selecionar 3 NPCs no painel e entender o porquê | **Janela** (apoio: testes do rastro e do painel) | Sim |
| 4 | Alarme de teste: reações diferentes | **Prova automática** (não há tecla) | Sim: `test_alarm.gd` |
| 5 | Conversar, salvar, recarregar e ser reconhecido | **Janela** (conversar e ser reconhecido) + **prova automática** (salvar e recarregar: não há botão de salvar) | Sim: `test_player_npc_talk.gd` |
| 6 | Esperar muitos dias acelerados | **Prova automática** (a janela só chega a 2x: no máximo 1 dia em 15 min) | Sim: soaks de 30 dias e de 1 ano |
| 7 | Comida a zero: fome e morte registrada | **Prova automática** (não há tecla) | Sim: `test_critical_need.gd`, `test_food_stub.gd` e a fase `starved` do oráculo |
| 8 | Não há dinheiro, mercado nem facções | **Janela** (olhar) + busca por texto | **Não há teste automático dedicado** (só a busca reproduzível da seção 3, item 8) |

**Se algum item ficar sem prova, está dito com todas as letras:** o teleporte (item 2) e o item 8 não têm teste GUT. Eles dependem do que você vê.

## 1. Abrir o jogo (comando exato)
O Mac já tem um **worktree** (uma cópia da pasta do projeto, em ramo próprio) pronto, com a importação do Godot feita: `/Users/arthurlk/LivingWorld/.worktrees/validacao-fase-2`. Abra o **Terminal** e rode:

```bash
"/Applications/Godot 2.app/Contents/MacOS/Godot" --path /Users/arthurlk/LivingWorld/.worktrees/validacao-fase-2
```

Isso abre **a janela do jogo direto** (sem o editor), com tudo da Fase 2. Se preferir o editor: acrescente `--editor` ao comando e aperte **F5**. Se o seu Godot estiver em outro lugar, troque o caminho do programa. **Para fechar:** **Command+Q** (ou o botão vermelho da janela).

Você deve ver o terreno aparecendo aos poucos em volta de uma cápsula laranja (você), com árvores e pedras, e, no canto superior esquerdo, o HUD (data e hora simuladas, a velocidade e a dica da pausa). **O jogo nasce às 05:45**, ainda escuro. Se o jogo abrir em **build de desenvolvimento** (o normal quando aberto por este comando), o painel de depuração de NPC funciona (F3). Em outro tipo de build ele nem existe.

## 2. As teclas (conferidas em `src/app/input_actions.gd` e no `project.godot`)
| O que faz | Tecla |
|---|---|
| Andar: frente, trás, esquerda, direita | **W**, **S**, **A**, **D** |
| Correr | **Shift esquerdo** (o direito não corre) |
| Pular | **Espaço** |
| Interagir e **conversar** (a menos de 3 m de um NPC) | **E** |
| Pausar e continuar o relógio (congela o personagem; a câmera continua girando) | **P** |
| Velocidade do relógio 1x e 2x | **1** e **2** (os da fileira de cima) |
| Girar a câmera | **←** e **→**, ou **botão direito do mouse** segurado e arrastado |
| Câmera mais baixa ou mais alta | **↑** e **↓**, ou arrastar o mouse (com o botão direito) para cima e para baixo |
| Zoom (de 4 a 40 m) | **roda do mouse** |
| **Painel de depuração de NPC**: abrir e fechar | **F3** ou **Tab** |
| Painel: próximo NPC e NPC anterior | **N** e **B** (ou clicar na lista) |
| Painel: marcar o NPC para guardar o rastro da decisão | **T** |

Só existem **1x e 2x** (não há 4x nem 8x). A 2x, **1 minuto de jogo dura 0,625 s reais**: 1 hora de jogo = 37,5 s, um dia = 15 min.

## 3. Os 8 itens, um por um

**Lugares e cores (para se orientar).** O mapa vai de 0 a 1.024 m; **o jogo não mostra coordenadas**. Na partida a câmera olha para o **leste**: à esquerda fica o norte e à direita o sul. Você nasce sobre o caminho (faixa cor de areia, de oeste a leste). Os marcos ciano ficam a 20 m e a 120 m. O **povoado A** fica uns **100 m depois do marco longe, uns 30 m à direita (sul) do caminho**: cerca de 70 por 40 m de caixas coloridas (60 NPCs). O povoado B (40 NPCs) fica bem mais longe (uns 700 m a leste e um pouco ao sul do nascimento) e **não** é preciso ir lá. **Cores das caixas (locais):** **vermelha = casa** (dormir e comer), **azul = trabalho**, **violeta = descanso**, **amarela = convívio** (conversar). Os NPCs são **cápsulas azul-acinzentadas** (0,4 × 1,8 m, com um "nariz" para a frente), com nomes "Aldeão N". Eles aparecem quando você chega a **menos de uns 80 m** e somem quando você passa de **uns 120 m** (a "histerese" evita piscar); no máximo **50 ao mesmo tempo**. Andando: 4 m/s; correndo: 7 m/s.

**Rotina dos ofícios** (hora de jogo; `data/routine_blocks.json`). Todos dormem das 22:00 às 06:00 e **comem às 06:00**; o resto muda por ofício. **Lavradores:** comem 12 e 18; trabalham 07–12 e 13–18; conversam 19–21; descansam 21–22. **Lenhadores:** comem 12 e 18; trabalham 07–12 e 13–17; descansam 17–18; conversam 19–21; descansam 21–22. **Artesãos:** comem 12 e 18; trabalham 07–11 e 13–18; **conversam 11–12**; descansam 19–20; conversam 20–22. **Guardas:** comem 13 e 20; trabalham 07–13 e 15–20; descansam 14–15; conversam 21–22. **Estalajadeiro:** come 14 e 21; descansa 07–09; trabalha 09–14 e 15–21. (Cada refeição dura uns 20 minutos, no começo da hora.)

### Sessão da janela: um roteiro único, cerca de 13 minutos
Os itens 1, 2, 3, 5 e 8 são feitos **na mesma sessão**, porque o dia precisa passar. **Corra a 1x** até o povoado (assim você chega por volta das 06:15, a tempo de ver o povoado acordar) e **aperte 2 ao chegar**. A 2x, **1 minuto real = 96 minutos de jogo** (1 hora de jogo = 37,5 s; um dia = 15 min). Tempos em minutos **reais** desde que o jogo abre (**[estimativa]**; a hora de jogo vem do HUD):

| Quando (real) | Hora do jogo | O que fazer |
|---|---|---|
| 0:00 | 05:45 | Abra o jogo (seção 1). **Não** aperte 2 ainda. |
| 0:00 a 0:45 | 05:45 a 06:15 | **Corra** (Shift + W) para o leste pelo caminho, passe os dois marcos ciano, ande uns 100 m e vire à direita: o povoado A. **Pare entre as caixas e aperte 2.** |
| 0:45 a 2:45 | 06:15 a 09:30 | **Item 1**: as cápsulas saem das casas, comem e às **07:00** vão para as caixas azuis. **Item 3** (painel): F3, N, T e ler, 3 vezes. |
| 2:45 a 4:45 | 09:30 a 12:40 | **Item 5**: conversar (E) com um NPC que trabalha; olhe o painel dele. Artesãos conversam às 11:00 (caixa amarela): **item 1**. |
| 4:45 a 6:45 | 12:40 a 15:50 | **Item 2**: afaste-se e volte 3 vezes (veja o item 2). |
| 6:45 a 8:15 | 15:50 a 18:15 | Volte ao povoado. **Item 5** de novo: segunda conversa com o mesmo NPC ("reconhece"). |
| 8:15 a 10:45 | 18:15 a 22:15 | **Item 1**: NPCs conversando (caixa amarela) e depois **indo dormir** às **22:00** (casas, caixas vermelhas; no painel, ação `sleep`). **Item 8**: olhe a tela. |
| 10:45 a 12:45 | 22:15 a 01:30 | Responda as perguntas de fluidez (seção 4) e feche (**Command+Q**). |

Se perder um momento (um NPC já foi embora, ou você se distraiu), **o dia seguinte repete tudo**. Aperte **P** para pausar enquanto lê o painel (o painel continua funcionando com o relógio parado) e **P** de novo para continuar.

**1. Fiquei parado no povoado por alguns minutos de jogo e vi NPCs saindo de casa, indo ao trabalho, comendo, conversando e voltando a dormir.**
- **Faça na janela:** na sessão acima, fique entre as caixas do povoado A e olhe as cápsulas enquanto a hora passa (a 2x depois que você chegar). Abra o painel (**F3**) e olhe a **lista**: cada linha mostra `nome · ofício · ação · S0/S1` (por exemplo `Aldeão 12 · farmer · work · S0`).
- **O que olhar:** (a) até as **07:00** (você chega por volta das 06:15) as cápsulas estão nas casas (vermelhas) e saem delas; a lista mostra `eat`; (b) às **07:00** vão para as caixas **azuis** e a lista mostra `work`; (c) às **12:00** voltam a comer; (d) à noite, **19:00 a 22:00**, vão às caixas **amarelas** (`talk`); (e) depois das **22:00** as cápsulas voltam para as **casas** (a lista mostra `go_to_place`, que é a caminhada, e depois `sleep`) e ficam paradas junto delas.
- **Estar certo:** você vê as cinco coisas (sair, trabalhar, comer, conversar, dormir) acontecendo, em horas parecidas com a rotina acima, sem NPC parado para sempre no meio do caminho.
- **Não é defeito:** as cápsulas andam em **linha reta** e atravessam casas e pedras (navegação N1, DEC-122, "por ora"); sem animação além de andar e parar; chegam **um pouco atrasadas** em relação ao horário (toda caminhada com corpo atrasa); só aparecem NPCs a menos de uns 80 m e no máximo 50; nomes e cores provisórios.
- **Prova automática de apoio** (não substitui o que você vê):
  ```bash
  tools/run_tests res://tests/soak/npc_life/test_npc_life_7d.gd
  ```
  Roda 7 dias de jogo dos 100 NPCs sem jogador e confere que todos vivem, que ninguém fica sem ação por mais de uma hora, que as necessidades ficam de 0 a 100 e que repetir dá o mesmo resultado. **Resultado de hoje: 4/4 passaram.** O soak de 30 dias (`tests/soak/run_npc_life_30d`) está no item 6.

**2. Afastei-me e voltei várias vezes: ninguém duplicou, sumiu de repente ou "teleportou".**
- **Faça na janela:** a partir do povoado A, **corra para longe**: para o **oeste**, pelo caminho, até o **primeiro marco ciano** (uns 165 m, uns 25 s correndo, o bastante para passar dos 120 m), espere uns 5 s e **volte** correndo. Repita **3 vezes** (cerca de 2 minutos reais). Depois chegue perto de uma cápsula e ande em volta dela. No painel (F3), a linha **"Níveis: N com corpo (S0)"** do resumo cai a **0** quando você está longe e volta a subir quando você volta.
- **O que olhar:** (a) **duplicar:** nunca duas cápsulas no mesmo lugar nem uma "sombra" ao lado de outra; (b) **sumir:** **perto de você (menos de uns 80 m)** nenhuma cápsula some ou aparece do nada; **só** some quando você passa de uns 120 m (isso é o esperado); (c) **teleporte:** nenhuma cápsula dá um salto de posição de um quadro para o outro.
- **Estar certo:** ao voltar, as cápsulas reaparecem **onde a rotina diria que elas estariam** (não todas empilhadas na mesma caixa).
- **Não é defeito:** a cápsula andar atrás de uma casa; chegar atrasada; o número de cápsulas variar (cap de 50); alguém estar dormindo e parado.
- **Prova automática** (cobre duplicar e sumir; **não** cobre teleporte):
  ```bash
  tools/run_tests res://tests/integration/test_npc_bodies_in_game.gd
  tools/run_tests res://tests/integration/test_npc_bodies_view.gd
  tools/run_tests res://tests/unit/test_npc_view_pool.gd
  tools/run_tests res://tests/unit/test_npc_lod.gd
  ```
  O que provam: na **cena principal real**, os corpos na tela são **exatamente** os NPCs em S0 (`test_the_scene_turns_the_bodies_on_once_and_the_bodies_on_screen_are_exactly_the_s0_set`), **sair e voltar de S0 não vaza nem duplica corpo** (`test_leaving_and_returning_to_s0_neither_leaks_nor_duplicates_a_body`); a cada passo de um **dia inteiro** com o jogador andando, os corpos ativos são sempre os de S0 e uma troca total devolve os antigos antes de pegar os novos (`..._at_every_step_of_a_day...`); a morte devolve o corpo; **100 entradas e saídas** não perdem nem criam nó (`test_100_enters_and_exits_keep_every_node_and_never_grow_the_pool`); e o LOD tem histerese, não oscila na borda e, ao sair e voltar, continua do ponto relatado sem ultrapassar (`test_re_entering_mid_transit_after_a_reported_exit_continues_from_the_reported_point_without_overshoot`). **Resultado de hoje: 5/5, 7/7, 10/10 e 20/20 passaram.**
- **Sem prova automática permanente:** **o teleporte**. O spike SP2 (código descartável em `tests/soak/sp2`, fora do `check_all`) tinha um detector de teleporte e achou **zero** duplicados, órfãos e teleportes (`docs/decisions/0009-spike-sp2-corpos-e-lod.md`); isso é registro, não um teste que roda a cada mudança. **A sua janela é a prova do teleporte.**

**3. Selecionei 3 NPCs no painel e entendi por que cada um fez o que fez.**
- **Faça na janela:** aperte **F3**. À direita aparece o painel (cerca de 35% da tela, semitransparente): em cima o **resumo do mundo** (hora, quantos NPCs vivos, camadas T1 e T2, S0 e S1, Intents, problemas do `validate()`), no meio a **lista** dos 100 NPCs e embaixo o **detalhe** do selecionado. Aperte **N** para escolher um NPC (ou clique na lista), aperte **T** para **marcar o rastro** e espere uns 10 minutos de jogo (**6 s reais a 2x**, o NPC pensa a cada 10 min). Leia o bloco **"Rastro da decisão"**. Faça com **3 NPCs** diferentes (**N** troca para o próximo, **B** volta). Prefira um que esteja trabalhando, um que esteja indo comer e um que esteja conversando.
- **O que olhar:** cada linha do rastro diz `Minuto M: escolheu <ação> em <local> (<MOTIVO>)`, e logo abaixo as **candidatas** com a nota total e as partes (benefício, personalidade, tempo, distância, risco, inércia). Os motivos são: **ROUTINE** (a rotina do ofício manda nessa hora), **URGENT_NEED** (uma necessidade está urgente, como fome acima de 65), **INERTIA** (continuar o que já fazia), **INTERRUPTION** (um alarme interrompeu) e **FALLBACK** (nada serviu: espera). O detalhe também mostra as cinco **necessidades** (fome, descanso, segurança, renda, social), a ação, o ofício, as **memórias** e as **relações**.
- **Estar certo:** para cada um dos 3 NPCs você consegue dizer, lendo o painel, **por que** ele fez aquilo (por exemplo: "às 07:00 ele escolheu `work` por ROUTINE; `eat` tinha nota menor porque a fome ainda estava baixa").
- **Não é defeito:** os rótulos aparecem em inglês e em maiúsculas (ids dos dados, crus de propósito); só o NPC **marcado** com **T** tem rastro (os outros dizem "Sem marca"); o painel não existe fora de build de desenvolvimento; **com o painel aberto pode haver um pequeno tranco uma vez por segundo** (o resumo roda o `validate()` do mundo; com 300 NPCs mediu ~20 ms por chamada, linha da LW-085c no `docs/ROADMAP_STATUS.md`); feche o painel (F3) antes de responder as perguntas de fluidez.
- **Prova automática de apoio:**
  ```bash
  tools/run_tests res://tests/unit/test_decision_trace.gd
  tools/run_tests res://tests/unit/test_sim_bridge_npc_inspect_trace.gd
  tools/run_tests res://tests/integration/test_npc_debug_panel.gd
  ```
  Provam que um NPC marcado e com fome mostra **todas as candidatas com as partes da nota e o motivo da necessidade urgente** (`test_a_marked_hungry_npc_shows_every_candidate_with_its_score_parts_and_the_urgent_need_reason`), que a rotina, a caminhada e a inércia aparecem como motivos, que marcar **não muda** o mundo (hash, aleatório, IDs), e que o painel **só lê** (a única escrita é a marca). **Resultado de hoje: 10/10, 6/6 e 6/6 passaram.**

**4. Disparei o alarme de teste: pessoas reagiram de maneiras diferentes.** *(sem tecla: prova automática)*
- **Por que não há "faça na janela":** o alarme é um comando de depuração do módulo (`request_raise_alarm`), **sem tecla**, e a regra desta validação é **não criar teclas nem comandos**.
- **Prova automática:**
  ```bash
  tools/run_tests res://tests/unit/test_alarm.gd
  ```
  O que prova: **o mesmo alarme** faz o NPC **cauteloso fugir, o leal e sociável ajudar e o frio ignorar** (`test_the_same_alarm_makes_the_coward_flee_the_helper_help_and_the_stoic_ignore`); a reação segue a **personalidade e não a ordem dos NPCs** (`test_the_reaction_follows_the_personality_not_the_order_of_the_npcs`); o raio é inclusivo e só vivos dentro dele reagem; a gravidade multiplica a pressão sem passar de 100; quem trabalhava é interrompido com efeito proporcional, foge e a rotina volta; o mesmo alarme com a mesma semente dá o mesmo mundo, **inclusive salvando no meio da fuga**; e **no jogo real** (100 NPCs, dados reais) o povoado inteiro (60) está no raio, **alguns fogem ou ajudam e outros ignoram e seguem a vida**, e o outro povoado, longe, não reage (`test_the_real_world_a_village_reacts_the_other_far_away_does_not_and_life_goes_on`). **Resultado de hoje: 11/11 passaram (425 asserts).** **Passou se** terminar com `11/11 passed.` e `---- All tests passed! ----`.

**5. Conversei com um NPC, saí, salvei, recarreguei e ele me reconheceu.**
- **Faça na janela (conversar e ser reconhecido; não há botão de salvar):** com o relógio a 2x, chegue a **menos de 3 m** de uma cápsula que esteja **trabalhando** (caixa azul) até aparecer **[E] Interagir** e aperte **E**. Deve aparecer **"A pessoa para e conversa com você."** e a cápsula **para** por uns 6 minutos de jogo (4 s reais a 2x). No painel (F3), com esse NPC selecionado, ele agora é **notável (T2)**, tem **uma memória** de `conversation` e **uma relação** com você (afeição 3, confiança 3). Afaste-se, espere **mais de 1 hora de jogo (40 s reais a 2x)**, volte e aperte **E** de novo: deve aparecer **"A pessoa reconhece você e para para conversar."** (`known`). Se o aviso disser **"Vocês acabaram de conversar. Volte daqui a pouco."**, é o intervalo de 60 min de jogo: espere mais um pouco.
- **Estar certo:** a 1ª conversa diz "para e conversa", a 2ª diz "**reconhece você**", e o painel mostra a relação e a memória guardadas.
- **Não é defeito:** o NPC **não se vira para você** (backlog); os nove textos de conversa são provisórios; "A pessoa está ocupada e não responde." se ele dorme, foge ou ajuda; a ação que ele fazia **recomeça do zero** depois; só 40 NPCs podem virar notáveis (T2); "Ninguém responde." se o NPC estiver sem corpo (S1).
- **Prova automática (salvar e recarregar):**
  ```bash
  tools/run_tests res://tests/integration/test_player_npc_talk.gd
  ```
  O teste, com o jogo real às 07:00: o jogador **anda até o povoado, conversa pela ponte** com um lavrador (ele vira T2, a relação +3/+3 e a memória existem e ele para); **salva no meio da conversa e depois dela**, carrega num jogo novo e confere **hash do mundo, opinião, memória e `validate()` iguais**; no mundo carregado o **intervalo vale** (`NPC_TALK_COOLDOWN`) e, passado ele, a 2ª conversa traz a chave **`known`**, não promove de novo, soma +3/+3 e grava outra memória. Ou seja: **ele me reconhece depois de salvar e recarregar.** **Resultado de hoje: 1/1 passou (100 asserts).** **Passou se** terminar com `1/1 passed.` e `---- All tests passed! ----`.

**6. Esperei muitos dias com a simulação acelerada: o povoado continuou funcionando.** *(prova automática)*
- **Por que não é na janela:** a janela só chega a **2x**: 1 dia em 15 minutos reais. "Muitos dias" só cabe em teste sem janela.
- **Prova automática 1 (100 NPCs por 30 dias; cerca de 1,5 minuto):**
  ```bash
  tests/soak/run_npc_life_30d
  ```
  Imprime **3 linhas** (3 execuções), cada uma: `vida sem jogador: 43200 min | vivos no mínimo 100 | maior tempo parado 0 min | ... | hash d13b921112ce | ... | problemas 0`. **Passou se:** `vivos no mínimo 100`, `maior tempo parado 0 min`, `problemas 0` e o **mesmo hash nas 3 linhas**. **Resultado de hoje:** ver a seção 6 deste arquivo (preenchida na LW-086a).
- **Prova automática 2 (300 NPCs por 1 ano; ~21 minutos por execução, fora do `check_all`; resultado de hoje vem da LW-084):**
  ```bash
  RUNS=1 tests/soak/run_npc_year base
  ```
  Em **8 execuções de 1 ano** (LW-084, 10/11/2026): **300 vivos o tempo todo, zero mortes, zero erro de `validate()`, mesmo hash dentro de cada padrão** (`5141d7e7a84b` e `50af223b6f51`), inclusive salvando e carregando no meio; memória estática +1,9 MiB só nos primeiros 30 dias e depois plana; save de cerca de 20 KiB comprimido, estável. Detalhes: `docs/decisions/0010-soak-longo-300-npcs.md`. **Limites:** corpo falso e 300 NPCs [HIP].
- **No `check_all`:** `test_npc_life_7d.gd` (7 dias, 100 NPCs) e `test_npc_year_short.gd` (1 dia, 300 NPCs).

**7. Reduzi a comida de teste a zero e vi as consequências (fome, morte registrada).** *(sem tecla: prova automática)*
- **Por que não há "faça na janela":** zerar a comida é o comando de depuração `request_set_food_stock`, **sem tecla**.
- **Prova automática:**
  ```bash
  tools/run_tests res://tests/unit/test_critical_need.gd
  tools/run_tests res://tests/unit/test_food_stub.gd
  tools/run_tests res://tests/integration/test_npc_split_oracle.gd
  ```
  O que provam: **sem comida** o NPC fica **enfraquecido** depois de 24 h de fome crítica e **morre aos 72 h**, no minuto exato, com o evento `NpcDied` (causa `hunger`) publicado **uma vez**, ação cancelada sem efeito, local liberado e `validate()` vazio (`test_without_food_the_npc_is_weakened_then_dies_at_the_limit_with_the_event`); **com comida nunca morre**; comida que chega **depois de enfraquecer mas antes do limite salva o NPC**; **salvar e carregar com NPC morto** funciona e consultas ao morto não falham. O `test_food_stub.gd` tem o teste que o próprio código chama de **"o teste 'comida a zero' do checklist"** (`test_a_hungry_farmer_with_no_food_works_restocks_the_village_and_then_eats`): com o estoque zerado, o lavrador faminto **vai trabalhar, repõe o estoque e então come**. E a fase **`starved`** do oráculo faz o cenário completo: estoque zerado, corpo atrasado que nunca deixa comer, **todos morrem de fome** e a contagem de mortos é a de todos. **Resultado de hoje:** 17/17 (`test_critical_need`), 19/19 (`test_food_stub`) e 2/2 (oráculo) passaram.
- **Atenção (não é defeito):** no jogo normal **zerar o estoque não mata ninguém**, porque os lavradores trabalham, repõem a comida e comem; a morte só acontece sem produção ou com o corpo travado, como nos testes.

**8. Confirmei que não há dinheiro, mercado nem facções (ainda).**
- **Faça na janela:** olhe a tela inteira durante a sessão. **Não pode existir:** valor em dinheiro, preço, loja, mercado, menu, inventário, facção, bandeira ou lei, nem nada que fale disso no HUD ou no painel (o painel mostra só necessidades, ação, ofício, rastro, memórias e relações). **Deve existir:** terreno, céu, sol, árvores e pedras, a sua cápsula, as cápsulas dos NPCs, as caixas coloridas, o HUD e (F3) o painel.
- **Prova por busca (não é teste automático):** no Terminal, na pasta do projeto:
  ```bash
  ls src/sim
  rg -n -i "ledger|money|dinheiro|price|preço|market|mercado|wage|salário|faction|facç" src data --glob '!*.uid' --glob '!*.md'
  ```
  **Resultado de hoje:** as pastas `economy`, `factions`, `politics`, `military`, `combat`, `ecology`, `entities` e `events` só têm um `README.md` (sem código); a busca acha **só** (a) dois locais reservados `market_reserved` em `data/world/places.json` (sem caixa na tela e sem uso), (b) o nome desse tipo de local no código do `world` e da apresentação, e (c) **comentários** dos dois provisórios ("sem dinheiro, preço, Ledger ou mercado"). **Não há teste GUT dedicado a este item**; a prova é a busca acima, mais os dois provisórios marcados `TEMP` (`FoodStub`, `IncomeStub`) listados no Anexo D do roadmap com remoção nas LW-094 e LW-095.

**9. Andar e olhar o mundo com gente é agradável o bastante para eu querer continuar? Anotei o que incomoda.** Responda no fim (seções 4 e 5).

## 4. Perguntas de fluidez (resposta curta)
Como na Fase 1 (P1 e P2), agora com NPCs na tela. **Feche o painel (F3) antes de responder** (ele tem custo próprio). Aceito por você: o SP2 "por ora" (DEC-122); você vai observar a fluidez ao jogar.
- **P1.** O **seu** movimento (andar, correr, pular) está **fluido** com cápsulas de NPC na tela, ou aos trancos? (Teste perto das caixas, com 20 a 50 cápsulas à vista.)
- **P2.** A **câmera treme** quando você gira ou anda perto do povoado?
- **P3.** Os **NPCs andam** de forma fluida, ou aos pulos? Algum **saltou de lugar** ou ficou **preso** (parado no caminho)?
- **P4.** Com o **painel aberto (F3)** você nota um tranco **uma vez por segundo**? (Esperado e conhecido; diga se incomoda.)
- Por quê: a régua oficial do SP2 (DEC-119, média ≥ 60 quadros/s) falhou em 3 de 13 ensaios e a causa dos trancos ficou aberta (LW-072); os números de quadros não estão no repositório. A sua resposta é o dado que falta.

## 5. Como responder (a Claude, o revisor)
Uma linha por item: `1 OK` · `2 PROBLEMA — vi uma cápsula saltar de lugar perto da caixa azul` · `3 NÃO CONSEGUI — não achei o rastro` · para os itens só de prova (4, 6 e 7): `4 prova aceita` ou `4 não aceito — porque ...`.
```
1 ...   2 ...   3 ...   4 ...   5 ...   6 ...   7 ...   8 ...
P1 fluido / aos trancos — ...      P2 treme / não treme — ...
P3 fluidos / aos pulos / presos — ...      P4 tranco com o painel: sim / não — ...
9 Agradável para continuar? sim / não — o que incomoda (quadros, câmera, controle, NPCs): ...
```
Se algo estiver estranho, anexe capturas (no Mac: **Shift+Command+4** escolhe a área; **Shift+Command+3** pega a tela toda): a janela com o HUD visível (mostra hora e velocidade) e, se for sobre um NPC, o painel com o NPC selecionado. Diga **onde** estava (perto de que caixa) e **que hora** o HUD mostrava.

**Como terminar:** tudo certo, escreva **"LW-086 assinada, com a ressalva de janela mais prova automática"**; algo falhou, mande a lista (item, o que viu); cada item vira uma tarefa de correção. **A tag `fase-2-concluida` só é criada com a sua autorização** (AGENTS, seção 10; roadmap, 2.J).

## 6. Resultado de hoje dos testes citados (preenchido na LW-086a)
Rodados em 10/11/2026 (Brasília) sobre `origin/main` (`d1b0fa2`, mais só documentos), com `tools/run_tests <arquivo>`:

| Item | Arquivo de teste | Testes | Asserts | Tempo | Resultado |
|---|---|---|---|---|---|
| 1 | `tests/soak/npc_life/test_npc_life_7d.gd` | 4/4 | 42 | 20,1 s | VERDE |
| 2 | `tests/integration/test_npc_bodies_in_game.gd` | 5/5 | 25 | 1,5 s | VERDE |
| 2 | `tests/integration/test_npc_bodies_view.gd` | 7/7 | 3.545 | 2,4 s | VERDE |
| 2 | `tests/unit/test_npc_view_pool.gd` | 10/10 | 418 | 0,5 s | VERDE |
| 2 | `tests/unit/test_npc_lod.gd` | 20/20 | 157 | 0,5 s | VERDE |
| 3 | `tests/unit/test_decision_trace.gd` | 10/10 | 126 | 0,5 s | VERDE |
| 3 | `tests/unit/test_sim_bridge_npc_inspect_trace.gd` | 6/6 | 81 | 1,4 s | VERDE |
| 3 | `tests/integration/test_npc_debug_panel.gd` | 6/6 | 86 | 2,1 s | VERDE |
| 4 | `tests/unit/test_alarm.gd` | 11/11 | 425 | 1,3 s | VERDE |
| 5 | `tests/integration/test_player_npc_talk.gd` | 1/1 | 100 | 1,1 s | VERDE |
| 6 | `tests/soak/npc_year/test_npc_year_short.gd` (1 dia, 300 NPCs) | 4/4 | 25 | 13,6 s | VERDE |
| 7 | `tests/unit/test_critical_need.gd` | 17/17 | 166 | 0,9 s | VERDE |
| 7 | `tests/unit/test_food_stub.gd` | 19/19 | 308 | 0,5 s | VERDE |
| 7 | `tests/integration/test_npc_split_oracle.gd` | 2/2 | 8.811 | 3,6 s | VERDE |
| 2.F 4, 2.F 7, 2.F 8 | `test_action_equivalence.gd`, `test_npc_tiers.gd`, `test_action_catalog.gd` | 4/4, 13/13, 17/17 | 380, 350, 504 | 0,9 s, 2,8 s, 0,5 s | VERDE |
| 085b (impasse × conversa) | `tests/integration/test_impasse_conversation.gd` | 2/2 | 83 | 1,1 s | VERDE |

**Item 6, soak de 30 dias** (`tests/soak/run_npc_life_30d`, 3 execuções, 26 s cada): `vivos no mínimo 100`, `maior tempo parado 0 min`, `pensamentos por passo no máximo 20`, `problemas 0` e o **mesmo hash `d13b921112ce` nas 3**. (A comida fica a zero por muitos minutos, 33.231 em A e 35.968 em B, e **ninguém morre**: os lavradores repõem e comem. É o esperado, ver o item 7.)

**Item 6, 1 ano com 300 NPCs** (LW-084, não repeti hoje: ~21 minutos por execução): 8 execuções, 300 vivos o tempo todo, 0 mortes, 0 erro de `validate()`, hash igual dentro de cada padrão.

**`tools/check_all`** (todos os testes, a verificação de arquitetura e a de dados): ver `docs/fase-2/LW-086-relatorio-de-fechamento.md`, seção 2 (resultado de hoje no HEAD desta tarefa).

**Observação honesta:** o primeiro `test_npc_year_short.gd` não deu resultado porque o cache de importação do Godot deste worktree era mais velho que o arquivo; depois de `godot --headless --path . --import` ele passou (4/4). Se um teste não imprimir nada na sua máquina, rode antes: `"/Applications/Godot 2.app/Contents/MacOS/Godot" --headless --path . --import`. O worktree que preparei para você já tem a importação feita.
