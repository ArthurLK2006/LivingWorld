# LW-054 — O que você vai fazer (validação da Fase 1)

**Escrito em 07/11/2026 (horário de Brasília), na LW-053.** A LW-054 só começa depois da LW-053 aprovada.

**Ideia:** você joga o que a Fase 1 entrega, como quem abre o jogo pela primeira vez, e confere se cada frase do checklist do roadmap (o plano de tarefas, `docs/DEVELOPMENT_ROADMAP.md`, item 1.H) é verdadeira. O que está em "Não é defeito" já está registrado: não precisa reportar. Se algo falhar, não é culpa sua: vira uma tarefa de correção. Tempo: cerca de 30 a 45 minutos **[estimativa]**.

## 1. Abrir o jogo (só o que o README diz, seções 8 e 9)
1. Use o ramo `main` (a linha principal do projeto no Git) já atualizado com a LW-053; em dúvida, pergunte antes de começar.
2. Abra o **Godot 4.7.2**, escolha **Importar** no gerenciador de projetos e selecione o arquivo `project.godot` na raiz do projeto. Se a pasta for nova, rode antes uma vez no **Terminal** (o programa de comandos do Mac), dentro da pasta do projeto: `"$GODOT_BIN" --headless --path . --import`.
3. Aperte **F5**. Você deve ver o terreno aparecendo aos poucos em volta de uma cápsula laranja (o personagem provisório), com árvores e pedras, e, no canto superior esquerdo, o **HUD** (o texto fixo da tela: título, versão, data e hora simuladas, e a dica da pausa). O painel "Saída" não deve mostrar mensagens vermelhas.
4. **O jogo nasce à meia-noite (tudo azul-escuro).** Dica: aperte **2** logo no início; a 2x o dia nasce em cerca de 4 minutos.

## 2. As teclas (conferidas em `src/app/input_actions.gd` e no `project.godot`)
| O que faz | Tecla | Nome no código |
|---|---|---|
| Andar: frente, trás, esquerda, direita | **W**, **S**, **A**, **D** | `move_forward`, `move_back`, `move_left`, `move_right` |
| Correr | **Shift esquerdo** (o direito não corre) | `run` |
| Pular | **Espaço** | `jump` |
| Interagir | **E** | `interact` |
| Pausar e continuar | **P** | `pause` |
| Velocidade 1x e 2x | **1** e **2** (os da fileira de cima) | `speed_normal`, `speed_double` |
| Girar a câmera | **←** e **→**, ou **botão direito do mouse** segurado e arrastado | `look_left`, `look_right`, `camera_orbit` |
| Deixar a câmera mais baixa ou mais alta | **↑** e **↓**, ou arrastar o mouse (com o botão direito) para cima e para baixo | `look_up`, `look_down`, `camera_orbit` |
| Zoom (de 4 a 40 m) | **roda do mouse**: para frente aproxima, para trás afasta | `zoom_in`, `zoom_out` |

## 3. O checklist, item por item
**Lugares de referência** (metros; o mapa vai de 0 a 1.024 em x e em z; **o jogo não mostra coordenadas**). Na partida a câmera olha para o **leste**: à esquerda fica o norte (z menor, o topo do desenho em `docs/world/relevo-do-terreno-de-blockout.md`) e à direita o sul. Andando: 4 m/s (100 m em 25 s); correndo: 7 m/s (100 m em 14 s).

| Lugar | Onde | Como achar |
|---|---|---|
| Nascimento | (100, 512) | Sobre o caminho |
| Caminho | faixa de 6 m, de oeste a leste (z de 510 a 516) | Faixa cor de areia que cruza o mapa: sua régua |
| Marco perto | (120, 513), a 20 m do nascimento | Cilindro ciano de 2,5 m, em cima do caminho |
| Marco longe | (220, 513), a 120 m | O mesmo cilindro, 100 m depois |
| Morro íngreme | pico (168, 469), a cerca de 80 m; ocupa x de 148 a 207 e z de 436 a 502 | Morro cinza (pedra) à esquerda do caminho, a 10 m dele. Lado oeste (de frente para o nascimento): cerca de 50°. Lado leste: cerca de 31°. Lados norte e sul: cerca de 35° |
| Vale | centro (300, 750), raio 140 m | À direita do caminho, a uns 95 m; fundo 12 m abaixo da planície |
| Colina grande | centro (700, 300), raio 160 m, topo a 40 m | À esquerda do caminho, a uns 50 m |
| Bordas do mapa | x = 0 e x = 1.024; z = 0 e z = 1.024 | A mais perto do nascimento é a oeste (x = 0), a 100 m |

**1. Abri o jogo e nasci no ponto esperado.**
- Fazer: abra o jogo (seção 1) e olhe a tela sem mexer.
- Onde: no nascimento, (100, 512).
- Deve acontecer: você está sobre a faixa cor de areia, com a câmera olhando ao longo dela para o leste e, mais à frente, um cilindro ciano.
- Não é defeito: escuro (meia-noite; a hora de nascimento é decisão sua pendente); cápsula laranja sem animação e cores provisórias; um tranco único logo na abertura; o personagem ficar parado alguns instantes até o chão ficar pronto.

**2. Andei, corri e pulei por todo o terreno; tentei atravessar o chão, sair pela borda e subir a encosta mais íngreme: nada quebrou.**
- Fazer: ande, corra (Shift) e pule (Espaço) pelo caminho, pelo vale e pela colina grande. Depois: (a) borda: aperte **S** (ou gire a câmera 180° e aperte W) até parar; (b) encosta: vá ao morro íngreme e ande contra o lado oeste, pulando; (c) chão: pule e corra morro abaixo e dentro do vale.
- Onde: (a) borda oeste, 100 m atrás do nascimento (cerca de 25 s andando); (b) 50 m a leste pelo caminho, depois à esquerda, de frente para o lado oeste do morro cinza; (c) vale e colina da tabela.
- Deve acontecer: (a) o personagem para a cerca de 1 m da borda; (b) só o pé da encosta (cerca de 3 m) é subido, depois o morro vira parede (limite de 40°); (c) nunca atravessa nem afunda no chão. Pelo lado leste ou pelos lados norte e sul do morro dá para chegar ao topo (25 m).
- Não é defeito: a câmera mostrar o vazio além da borda; árvores e pedras não serem sólidas (o personagem passa por elas); subir os lados de 31° e 35°.

**3. Girei a câmera e me encostei em paredes de terreno: a câmera não ficou "dentro" do chão.**
- Fazer: fique encostado na parede do morro cinza e gire a câmera até a parede ficar entre a câmera e o personagem; deixe a câmera baixa (↑) e afaste com a roda. Repita junto da colina grande.
- Onde: pé do lado oeste do morro (cerca de x = 150, z = 470) e pé da colina grande.
- Deve acontecer: a câmera se aproxima do personagem em vez de entrar no terreno; o chão não some nem aparece "por dentro". Não devem aparecer frestas entre pedaços do terreno.
- Não é defeito: a câmera atravessar a copa das árvores; faixas verticais ("saias") na base do morro, que tapam emendas entre níveis de detalhe.

**4. Esperei passar o dia e a noite; pausei e a luz parou; mudei a velocidade.**
- Fazer: aperte **2** e acompanhe a hora no HUD; aperte **P** para pausar, gire a câmera, aperte **P** de novo; aperte **1** e **2**.
- Onde: qualquer lugar.
- Deve acontecer: a 2x amanhece (06:00) em cerca de 4 minutos, é meio-dia em 7,5, entardece (18:00) em 11 e volta a 00:00 em 15 (a 1x, o dobro). Com a pausa o HUD mostra **PAUSADO**, a luz e o personagem param (a câmera continua girando). O HUD mostra **1x** ou **2x**.
- Não é defeito: amanhecer e entardecer rápidos (cerca de 1 minuto real a 1x); o sol andar em degraus pequenos; sem lua, estrelas nem nuvens.

**5. Interagi com o objeto de teste e li o texto.**
- Fazer: ande até o marco perto e, a menos de 3 m, aperte **E**. Repita no marco longe. Aperte **E** longe de qualquer marco.
- Onde: marco perto (120, 513) e marco longe (220, 513).
- Deve acontecer: aparece "[E] Interagir"; depois do **E**, um texto por cerca de 5 s ("Um marco de pedra simples, sem inscrição, marca o caminho." e "Restos frios de uma fogueira, apagada há muito tempo."). Longe de tudo: "Chegue mais perto."
- Não é defeito: o aviso aparecer e o jogo recusar bem na beira dos 3 m (a posição chega à simulação com até 0,1 s de atraso); o aviso continuar com o jogo pausado.

**6. Caminhei por bastante tempo sem queda perceptível de quadros.** (*Quadro* = uma imagem desenhada pelo jogo; *quadros por segundo* = quantas por segundo. 1 ms = um milésimo de segundo.)
- Fazer: corra pelo caminho de uma ponta à outra e volte (cerca de 5 minutos correndo).
- Onde: o caminho inteiro, de x = 0 a 1.024 (cerca de 2,5 minutos em cada sentido).
- Deve acontecer: movimento regular, sem engasgos fortes ou frequentes. O terreno novo aparece aos poucos à frente.
- Não é defeito: de 7 a 12 vezes por minuto um quadro demora de 17 a 33 ms (causa ainda não confirmada); só diga se você notar e se incomodar. Também o tranco único da abertura.

**7. Salvei (via teste scriptado ou comando de depuração) e recarreguei sem diferença.** Ainda não há botão de salvar na tela. O teste faz isso sozinho: nasce, anda até o marco, interage, pausa, salva, carrega num jogo novo e confere que o mundo e a posição são iguais (a "impressão digital" do mundo, o *hash*, tem de ser a mesma); depois repete com 30 dias simulados. No Terminal, **na pasta do projeto** (a que tem o `project.godot`):
```bash
tools/run_tests res://tests/integration/test_phase1_scripted.gd
```
Leva poucos segundos (9 s na execução feita na LW-053). **Passou** se terminar com `3/3 passed.` e `---- All tests passed! ----`. Se aparecer outra coisa, copie as últimas 30 linhas. Se o seu Godot não estiver em `/Applications/Godot 2.app`, defina `GODOT_BIN` antes (README, seção 8). Alternativa completa, de alguns minutos: `tools/check_all`, que termina em `VERDE: arquitetura, dados e etapa de testes aprovadas.`

**8. O que vejo é o que eu esperava para esta fase, sem funcionalidades "a mais".**
- Fazer: compare o que viu com esta lista.
- Deve existir: terreno, céu, sol e névoa, árvores e pedras, a cápsula, a câmera, o HUD, os dois marcos ciano.
- Não deve existir (e não existe): NPCs, itens ou inventário, combate, menus, salvar pela tela, som, animação, água, clima.
- Se faltar algo da primeira lista ou sobrar algo da segunda: PROBLEMA.

**9. Andar e olhar o mundo é agradável o bastante para eu querer explorar mais? Anotei o que incomoda (quadros, câmera, controle).** Responda no fim (seção 5).

## 4. Duas perguntas novas (resposta curta)
Perguntamos porque o jogo está desenhando 120 quadros por segundo numa tela de 60 Hz; se o movimento parecer aos trancos, abrimos uma tarefa de diagnóstico.
- **P1.** O movimento do personagem parece fluido ou aos trancos?
- **P2.** A câmera treme quando você gira ou anda?

## 5. Como responder (a Claude, o revisor)
Uma linha por item, assim: `1 OK` · `2 PROBLEMA — afundei no chão perto do vale` · `3 NÃO CONSEGUI — não achei como girar a câmera sem botão direito`.
```
1 ...   2 ...   3 ...   4 ...   5 ...   6 ...   7 ...   8 ...
P1 fluido / aos trancos — ...      P2 treme / não treme — ...
9 Agradável para explorar? sim / não — o que incomoda (quadros, câmera, controle): ...
```
Se algo estiver estranho, anexe capturas (no Mac: **Shift+Command+4** escolhe a área; **Shift+Command+3** pega a tela toda): (1) a janela do jogo com o HUD visível (mostra hora e velocidade); (2) o painel "Saída" do Godot, se houver texto vermelho; (3) uma captura antes e outra durante o problema, dizendo onde você estava (perto de qual marco ou morro). Se o seu mouse ou trackpad não tiver botão direito ou roda, diga qual usa.

**Como terminar:** tudo certo, escreva "LW-054 assinada"; algo falhou, mande a lista (item, o que viu); cada item vira uma tarefa de correção. A tag `fase-1-concluida` só é criada com a sua autorização (AGENTS, seção 10; roadmap, 1.J).

**Pergunta final:** andar e olhar o mundo é agradável o bastante para você querer explorar mais? O que incomoda (quadros, câmera, controle)?
