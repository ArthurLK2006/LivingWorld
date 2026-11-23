# LW-107 — O que você vai fazer (validação da interface das encomendas)

**Escrito em 17/11/2026 (horário de Brasília), na tarefa `docs-lw107-roteiro` (só documento: nenhum código, dado ou teste mudou).** Para uma oportunidade futura sua; não há pressa. Segue o estilo dos roteiros da Fase 1 (`docs/fase-1/LW-054-roteiro-para-arthur.md`) e da Fase 2 (`docs/fase-2/LW-086-roteiro-para-arthur.md`).

> **ADENDO de 23/11/2026 (opção B da LW-107c3; vale para o PR RASCUNHO isolado `lw107c3-opcao-b`, que NÃO está no `main`):** esse ramo já traz o dado do postador SEM o contrato de grãos (`bread_standing` e `flour_shortage`); portanto, **na pasta desse ramo NÃO rode o `cp` do passo 2.1** (o `sed` do passo 2.2, 3 abertas e 16 h, continua opcional e só local). A 1ª encomenda sai às 06:00 em A e em C (a sequência 06:00, 07:00 e 08:00 só vale com `max_open` 3). O quadro vazio agora diz "Nenhuma encomenda disponível agora.". "Cada entrega dá um pequeno prejuízo" vale SÓ comprando no mercado do emissor: para ver o ganho, compre 5 pães no mercado B (uns 503 m de A, cerca de 72 s correndo), volte e entregue (+5 a +23 nas primeiras semanas; o ganho some se o pão encarecer nos três mercados). O PR segue RASCUNHO até a sua autorização escrita; para desfazer, `git checkout -- data/economy/contract_templates.json`. Detalhes e números: `docs/economia/lw-107c3-opcao-b-condicoes.md`.

## 1. Antes de começar
- **O que é:** a primeira vez que você vê, **na janela**, a aba **Contratos** da tela de mercado: aceitar, entregar e **abandonar** (com o painel de confirmação), a linha "Encomendas aceitas: 1 de 3" e os rótulos "Abandonado", "Falhou" e "Vencido". Até hoje isso só foi testado **sem janela** (`--headless`): a aparência real (cor do botão de perigo, espaçamento, foco, painel de confirmação) **nunca foi vista**.
- **Quanto tempo:** cerca de **15 a 20 minutos** **[estimativa]**, uma sessão só. Aperte **P** (pausa) quando quiser ler: os prazos das encomendas também param.
- **O que NÃO é:** **não é a ativação** do postador de encomendas (LW-107c3), que segue **desligado** até o seu aceite específico (17/11/2026). É um teste **local e reversível**: **nada disto vai para o repositório** (nunca `git add` nem commit do arquivo alterado) e o jogo real não muda.
- **Se algo falhar, não é culpa sua:** vira tarefa de correção. O que está na seção 5 já está registrado: não precisa reportar.
- **Você precisa de:** o Terminal e uma pasta do projeto no `main` atual, com a importação do Godot feita. O Maestro (Claude) prepara essa pasta (um *worktree*, como na Fase 2) e diz o caminho: abaixo, **`PASTA`** é esse caminho (troque nos comandos).

## 2. Ligar as encomendas de teste SÓ no seu computador (reversível)
**Por quê:** o jogo real não tem encomendas: `data/economy/contract_templates.json` é `[]` (tabela vazia) e o postador (`src/sim/economy/support/contract_poster.gd`; regra em `docs/modules/economy.md`, seção 8; formato em `docs/economy/dados.md`) só posta quando há modelos. O arquivo `data/economy/contract_templates.initial.json` traz os 3 modelos iniciais propostos: pão (gatilho `standing`) e farinha e grão (gatilho `shortage`).

**Passos (no Terminal):**
1. Copie os modelos iniciais sobre o arquivo do jogo:
   ```bash
   cd PASTA
   cp data/economy/contract_templates.initial.json data/economy/contract_templates.json
   ```
2. **Recomendado** (uma linha; só mexe no pão, no seu arquivo local). O arquivo inicial deixa **1** encomenda de pão por mercado e prazo de **48 h** de jogo (30 minutos reais a 2x): sem isto só dá para testar uma encomenda por vez e o limite de 3 e o "Vencido" não aparecem em 20 minutos. A linha abaixo deixa até **3** abertas e prazo de **16 h** (as faixas permitidas são 1 a 3 e 1 a 168; `docs/economy/dados.md`):
   ```bash
   sed -i '' '/bread_standing/{s/"max_open": 1/"max_open": 3/;s/"deadline_hours": 48/"deadline_hours": 16/;}' data/economy/contract_templates.json
   ```
   `grep bread_standing data/economy/contract_templates.json` deve mostrar `"deadline_hours": 16, "max_open": 3`.
3. Confira: `git status --short` deve mostrar **só** ` M data/economy/contract_templates.json`. Linhas `??` de cache do Godot (como `*.import`) podem aparecer depois de abrir o jogo e não são problema; **qualquer outro arquivo com ` M`: pare e avise.** Não rode `tools/check_all` com o arquivo alterado (os testes esperam o jogo real, sem encomendas; confira). O jogo só lê os dados ao **abrir**: se mudar o arquivo com o jogo aberto, feche e abra de novo.

**Quando as encomendas aparecem.** O postador roda a **cada hora cheia do jogo**: para cada mercado e cada modelo posta **no máximo uma** encomenda de entrega por hora (emissor e destino são o próprio mercado), enquanto houver espaço (`max_open`). O gatilho `standing` (pão) posta sempre; o `shortage` (farinha, grão) **só** com escassez declarada no mercado, o que **não** acontece no começo: **só o pão aparece**. A recompensa (5 pães: **53**, segundo `docs/economy/dados.md`; confira na tela) nunca passa do custo de comprar o mesmo lote no mesmo mercado (regra anti-exploração): cada entrega dá um **pequeno prejuízo, de propósito**. O jogo nasce às **05:45**: a 1ª encomenda sai às **06:00**, a 2ª às **07:00** e a 3ª às **08:00** (o HUD mostra a hora).

**Acelerar o tempo.** Só existem as teclas **1** (velocidade normal) e **2** (dobro); não há 4x nem 8x. A 2x, **1 hora de jogo = 37,5 s reais** (a 1x, 75 s). **Aperte 2 antes de abrir o mercado:** com a tela aberta o relógio do mundo **continua andando** (só você e a câmera ficam parados). Com a tela aberta, **1**, **2** e **P** funcionam quando o foco está num botão; se uma lista ou o campo de quantidade tiver o foco, a tecla pode não chegar ao jogo (confira).

## 3. Abrir o jogo e chegar na tela
**Abrir (o mesmo dos outros roteiros):**
```bash
"/Applications/Godot 2.app/Contents/MacOS/Godot" --path PASTA
```
Se o seu Godot estiver em outro lugar, troque o caminho do programa. Para fechar: **Command+Q**. Você deve ver o terreno, a cápsula laranja (você) e, no canto superior esquerdo, o HUD com a data, a hora (05:45) e o ritmo (1x). **Aperte 2** (o HUD passa a dizer 2x).

**Teclas** (conferidas em `project.godot`; os nomes das ações estão em `src/app/input_actions.gd`; **nenhuma tecla nova**): andar **W A S D**; correr **Shift esquerdo**; interagir **E** (`interact`); pausar **P**; velocidade **1** e **2** (fileira de cima); **Esc** (padrão do Godot, `ui_cancel`) e **E** fecham a tela; **Tab**, **Shift+Tab**, setas e **Enter** movem e acionam o foco; o clique do mouse também vale.

**Ir até o mercado:** corra (**Shift + W**) para o **leste** pelo caminho cor de areia, passe os dois marcos ciano, ande uns 100 m e vire à **direita** (sul) uns 40 m: é o **povoado A** (como no roteiro da LW-086; uns 45 s correndo **[estimativa]**). O mercado é a **praça** do povoado (barracas e lampiões; confira). Chegue a **menos de 3 m do centro** dela: aparece **"[E] Abrir o mercado"**. Se houver um NPC ou um marco ciano a menos de 3 m, a tecla age nele em vez de abrir o mercado: afaste-se um pouco. Aperte **E**: a tela abre com as abas **Mercado** e **Contratos** no alto; clique em **Contratos**. (Os mercados B e C ficam longe: não vá.)

## 4. A lista de conferência
Siga de cima para baixo. O **13 (Vencido)** acontece sozinho: a 1ª encomenda vence às **22:00** do HUD (uns 10 min reais depois das 06:00, a 2x). Se alguma vencer antes de você chegar nela, não é defeito: aceite a próxima e siga. Em cada linha, marque **OK** ou **não OK**.

| # | Faça | Deve ver | Resultado |
|---|---|---|---|
| 1 | Na tela do mercado, aba **Contratos**. | Título "Contratos"; "Encomendas aceitas: 0 de 3"; a lista "Disponíveis neste mercado" com linhas como "Entregar 5 x Pão", "Recompensa: 53" e "Prazo: ..."; a lista "Meus contratos" com "Você ainda não aceitou nenhum contrato."; os botões Aceitar, Entregar, Abandonar e de fechar. Se disser "Nenhuma encomenda disponível agora." (o texto antigo, "Nenhum contrato agora: os mercados estão abastecidos", foi trocado em 23/11/2026 porque afirmava uma causa que o jogo não sabe), espere a próxima hora cheia (ou veja a seção 2). | [ ] OK  [ ] não OK |
| 2 | Clique numa linha de "Disponíveis". | Aparece o detalhe da encomenda (destino, recompensa, prazo) e a dica "Para aceitar: escolha um contrato em Disponíveis e aperte Aceitar." | [ ] OK  [ ] não OK |
| 3 | Aperte **Aceitar** (guarde esta: é a do item 13). | Resultado "Contrato aceito. Recompensa na entrega: 53."; a encomenda passa para "Meus contratos"; "Encomendas aceitas: 1 de 3". | [ ] OK  [ ] não OK |
| 4 | Espere a 2ª e a 3ª encomendas (HUD 07:00 e 08:00; a lista se atualiza sozinha) e aceite as duas. | "Encomendas aceitas: 3 de 3". Com uma linha de "Disponíveis" escolhida, **Aceitar** fica **desativado** (cinza) e o clique não faz nada. (A frase do limite está na nota abaixo da tabela.) | [ ] OK  [ ] não OK |
| 5 | Aba **Mercado**: escolha **Pão**, quantidade 5, **Comprar**. Volte a **Contratos**, escolha uma encomenda em "Meus contratos" e aperte **Entregar**. | O detalhe mostra "Você tem N de 5". Sem os pães, **Entregar** fica desativado ou responde "Você não tem os bens deste contrato." (confira qual dos dois); com os 5 pães, entrega: "Entrega feita. Você recebeu 53."; a linha vira "Concluído"; "Encomendas aceitas: 2 de 3"; seu dinheiro sobe 53 (a compra custou um pouco mais: de propósito). | [ ] OK  [ ] não OK |
| 6 | Olhe a fileira de botões. Escolha uma encomenda **aceita e no prazo** em "Meus contratos"; depois uma "Concluído". | **Abandonar** é **diferente** dos outros: tom **avermelhado** e um **espaço maior** entre "Entregar" e ele. Nasce **desativado**; liga só com uma encomenda sua, aceita e no prazo; com a "Concluído" escolhida, fica desativado. | [ ] OK  [ ] não OK |
| 7 | Com uma encomenda aceita escolhida, clique em **Abandonar**. | Abre um painel no **centro** da tela: "Abandonar esta encomenda? Você fica com os itens, nada é pago e ela se encerra.", com dois botões, "Abandonar" (avermelhado) e "Voltar". O **foco** (contorno) começa em **Voltar**. Nada foi enviado ainda. | [ ] OK  [ ] não OK |
| 8 | Aperte **Voltar** (clique, ou **Enter** com o foco nele). | O painel fecha e **nada muda**: a encomenda segue aceita, o "n de 3" é o mesmo, nenhuma frase nova de resultado. | [ ] OK  [ ] não OK |
| 9 | Abra o painel e aperte **Esc**; abra de novo e aperte **E**; com o painel fechado, aperte **Esc**. | **Esc** e **E** só **fecham o painel** (a tela de mercado continua aberta); o **Esc** seguinte fecha a tela. | [ ] OK  [ ] não OK |
| 10 | Com o painel aberto, use **Tab**, **Shift+Tab** e as setas. **Cuidado:** **Enter** com o foco em "Abandonar" **confirma**; deixe o foco em "Voltar". | O foco circula **só** entre "Abandonar" e "Voltar", sem sair do painel. Fora desta tela, Tab abre o painel de NPC e Shift+Tab o painel econômico (depuração); com a tela aberta devem só mover o foco: se um painel lateral aparecer, anote (confira). | [ ] OK  [ ] não OK |
| 11 | Abra o painel e clique **Abandonar** (do painel) **uma vez**. | O painel fecha; resultado "Encomenda abandonada. Não há multa: a recompensa volta ao emissor e os itens ficam com você."; a linha vira "Abandonado" ("Sem multa, recompensa devolvida ao emissor"), palavra **diferente** de "Vencido" e de "Falhou"; o "n de 3" cai 1; o dinheiro não muda; os pães comprados seguem seus (aba Mercado, coluna "Você tem"). | [ ] OK  [ ] não OK |
| 12 | Com uma encomenda aceita, abra o painel de confirmação e aperte **P** (pausa). | O HUD mostra "PAUSADO"; em poucos segundos o painel **fecha sozinho** e **nada** é abandonado; Aceitar, Entregar e Abandonar ficam desativados. **P** de novo: volta ao normal. | [ ] OK  [ ] não OK |
| 13 | Deixe a encomenda do item 3 aceita, sem entregar, até o prazo passar (22:00 do HUD; pause à vontade). | A linha vira "Vencido" ("Prazo encerrado, recompensa devolvida ao emissor"); **Abandonar** fica desativado nela; o "n de 3" cai 1. | [ ] OK  [ ] não OK |
| 14 | Olhe com calma (pausado, **P**): a aparência. | O texto "Abandonar" **cabe** no botão (sem cortar); o tom avermelhado é visível e não berrante; o espaço antes de "Abandonar" não é colado nem longe; o painel é **legível** e o contorno do foco **se vê**; o botão **desativado** ainda se lê. Escreva como achou cada um. | [ ] OK  [ ] não OK |

**Nota (item 4):** com 3 de 3 o botão **Aceitar** fica desativado e a tela não tem outro caminho para o 4º aceite; por isso a frase do limite ("Você já tem o máximo de encomendas aceitas ao mesmo tempo. Entregue ou abandone uma antes de aceitar outra.") só aparece se um pedido chegar à ponte por outra via (hoje, só nos testes automáticos). **Não há como forçá-la pela janela**; se você a vir, anote (confira).

## 5. O que NÃO é defeito (limites conhecidos)
- **Abandonar de qualquer lugar** vale na ponte (decisão D2, `docs/modules/economy.md`, seção 8, item (g)), mas a **primeira interface é só esta aba**, que só abre **perto de um mercado** (a menos de 3 m do centro da praça).
- O botão **desativado** tem contraste **menor** que o dos outros, **por desenho** (a revisão citou cerca de 2,5 contra 3,8; número a conferir). **Diga se atrapalha a leitura.**
- O **fundo do painel de confirmação NÃO escurece**, por desenho (escurecer pediria um estilo novo no tema do mercado).
- **Sem o postador ligado não há encomendas** (o jogo real tem a tabela vazia): por isso a seção 2.
- **A próxima encomenda de pão pode demorar (ou não aparecer) depois que você entrega** (acrescentado em 21/11/2026, verificado em `tests/integration/test_contract_cycle_poster.gd`): os 5 pães entregues sobem o estoque do mercado acima do alvo e o preço de compra cai; a regra anti-exploração (a recompensa nunca passa do custo do lote no mesmo mercado) segura a postagem até o estoque baixar (consumo dos habitantes ou uma compra sua). Quadro vazio nessa hora **não é defeito**; os outros dois mercados não são afetados.
- **Só contratos de entrega**; o jogo **não mostra encomendas fora da tela de mercado** (nem no HUD).
- **"Falhou"** não tem como aparecer hoje (nenhuma entrega produz essa falha): o item 11 só confere que "Abandonado" é uma palavra **diferente** dela e de "Vencido".
- Cada entrega no mesmo mercado dá um **pequeno prejuízo** (seção 2); os textos são **provisórios** (a tela usa "contrato" e "encomenda" para a mesma coisa).

## 6. Como me dizer o que viu
Cole no chat com o **Maestro (Claude)**, uma linha por item (`OK`, ou `NÃO OK — o que viu`), mais as perguntas de aparência:
```
1 ...  2 ...  3 ...  4 ...  5 ...  6 ...  7 ...  8 ...  9 ...  10 ...  11 ...  12 ...  13 ...  14 ...
Botão Abandonar (cor): bom / estranho — ...        Espaço entre Entregar e Abandonar: bom / colado / longe — ...
Painel de confirmação (centro, legível, foco em Voltar): ...        Botão desativado: legível / difícil de ler — ...
Outras observações (textos, tempo, o que incomodou): ...
```
Se algo estiver estranho, anexe uma captura (no Mac: **Shift+Command+4** escolhe a área; **Shift+Command+3** pega a tela toda), com o HUD visível (hora e ritmo) e a encomenda em questão. **As capturas ficam só no seu computador: não vão para o repositório.** Para encerrar: tudo certo, escreva **"LW-107, interface das encomendas validada na janela"**; algo falhou, mande a lista (item, o que viu): cada item vira uma tarefa de correção. **A ativação do postador (LW-107c3) só acontece com o seu aceite específico.**

## 7. Desfazer tudo
Feche o jogo (**Command+Q**) e rode, na `PASTA`:
```bash
git checkout -- data/economy/contract_templates.json
git status --short
```
O primeiro comando descarta **só** a sua mudança local nesse arquivo (ele volta a ser `[]`: o jogo real, sem encomendas). O segundo deve sair **vazio** (ou só com linhas `??` de cache do Godot, como `*.import`; **nenhuma** linha ` M`). Se sobrar algo, mande a saída ao Maestro.
