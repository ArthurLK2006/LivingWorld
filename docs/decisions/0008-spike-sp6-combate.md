# LW-152 — Spike SP6: laço de combate por alvo e habilidades

- **Status:** **PRONTA PARA PLAYTEST (Fase A, 07/11/2026, Brasília).** O código e os testes estão prontos e verdes. **Falta o playtest de Arthur**: as respostas dele (seção "Respostas de Arthur") e os valores finais ainda **não existem**; nada abaixo diz que o combate está "responsivo", "legível" ou "divertido". Isso é só de Arthur (roadmap LW-152). Ramo `spike-lw-152`, a partir de `origin/main` em `307a9db`.
- **Rótulos:** **fato** (com origem), **[HIP]** (valor inicial para Arthur ajustar jogando), **interpretação** (leitura minha de um ponto aberto da tarefa), **limitação**.

## Pergunta (roadmap LW-152; arquitetura 26.3)

O laço de combate **por alvo e habilidades** (DEC-117, APROVADA só quanto à direção) tem boa sensação num duelo 1 contra 1, sobre o jogador, o terreno e a câmera da Fase 1? Critério de sucesso do roadmap: "responsivo e legível segundo você". Plano B (26.3): mais tolerância nas janelas, regras no cliente com validação leve. A DEC-066 segue **PENDENTE**; a DEC-067, **PROPOSTA**; a DEC-053, **PENDENTE**.

## Método

- **Código descartável** em `tests/soak/sp6/` (8 arquivos) e `tests/soak/run_sp6` (9 no total). Não mexe em `project.godot`, `src/`, `data/`, `scenes/`, ponte, contratos, eventos ou autoloads (autorizações A1 a A3 de Arthur, 07/11/2026).
- **Regras puras** (`Sp6Rules`, sem Node, sem tempo do motor, sem sorteio): estado em inteiros, avança por `step(delta_ms)` em ticks de 1 ms. Por quê: o golpe cai no milissegundo exato do fim do preparo e o resultado não depende do tamanho do quadro (testado). Estamina em milésimos de ponto, para os 12 por segundo não perderem fração.
- **Apresentação** (`sp6_main`, `sp6_dummy`, `sp6_hud`): carrega a cena principal **real** (precedente `tests/soak/game_release`), só **lê** a posição do jogador, a ponte e a pausa, e desenha. O feedback de um golpe (brilho, número, mensagem, barras) sai no **mesmo quadro** em que a regra o resolve: o nó principal consome os eventos logo depois do `step` ou do aperto da tecla.
- **Entrada:** teclas Q, R, F, T, Esc e clique esquerdo criadas **só em tempo de execução** (`InputMap.add_action`), e o código recusa (`push_error`) qualquer uma que já pertença às 17 ações oficiais. Conferido: Q, R, F e T não colidem; clique esquerdo e Esc não têm uso em `src/`.

## O que foi construído e o que NÃO (escolhas de Arthur, 07/11/2026)

- **Entra:** seleção do alvo por clique; ataque automático; 3 habilidades por tecla; ritmo (preparo e recuperação); estamina; posição (lado e costas dão mais dano); boneco **parado**, com troca de armadura (T).
- **NÃO entra** (foi para o backlog na Fase B, 1 linha cada): ferimentos por golpe (sangramento, atordoamento); boneco que reage e permite bloqueio e esquiva; bloqueio e esquiva do jogador. **Nada disso foi construído.**

## Interpretações minhas (a confirmar por Arthur)

1. **F em armadura leve:** 25 ÷ 2 em divisão inteira = **12%** (não 12,5%). Efeito: arredonda o dano a favor do boneco em alguns casos.
2. **Ataque automático:** o relógio do intervalo corre sempre (parando no limite de 1500 ms); portanto o 1º golpe sai assim que há alvo no alcance, e depois a cada 1500 ms, e logo ao fim de um preparo/recuperação.
3. **Dois estados e uma mensagem além da lista:** "Sem alvo" (apertar sem alvo) e "Ocupado" (as outras habilidades durante preparo e recuperação). Sem eles a falha seria silenciosa (AGENTS 13.1).
4. **Ordem das recusas ao apertar:** sem alvo, depois sem estamina, depois longe demais. Nada é gasto numa recusa.
5. **Pausa (P):** congela também o relógio do combate, junto com o personagem.
6. **Alvo:** ao cair, o boneco solta o alvo; ao ressurgir é preciso clicar de novo. O preparo em curso mantém o boneco como alvo mesmo se o jogador apertar Esc.
7. **Apertos fora do buffer:** apertar uma habilidade durante o preparo, ou antes dos últimos 200 ms da recuperação, é ignorado sem mensagem.

## Constantes [HIP] (todas em `Sp6Constants`; nenhuma é requisito)

| Grupo | Valores |
|---|---|
| Q golpe pesado | preparo 700 ms · recuperação 900 ms · dano 30 · estamina 30 |
| R golpe rápido | preparo 200 ms · recuperação 400 ms · dano 10 · estamina 12 |
| F golpe perfurante | preparo 400 ms · recuperação 600 ms · dano 16 · estamina 20 · ignora 50% da redução da armadura |
| Ataque automático | dano 6 · intervalo 1500 ms · estamina 4 |
| Boneco | vida 200 · ressurge em 3000 ms · olha para o oeste · fica a 8 m do nascimento |
| Alcance | 250 cm (horizontal, pés do jogador a centro do boneco) · tolerância no golpe 50 cm · buffer 200 ms |
| Estamina | máximo 100 · regenera 12 por segundo (12 milésimos por ms) · começa 1000 ms depois do último gasto |
| Posição (ângulo) | frente até 60° (x100%) · lado até 120° (x125%) · costas acima (x150%); 60° e 120° contam como o grupo de menor bônus |
| Armadura (T) | nenhuma 0% · leve 25% · pesada 50% |
| Dano final | base x posição% x (100 − redução)% / 10.000, divisão inteira, mínimo 1 |
| Só visual | esfera de clique raio 1,1 m a 0,9 m do chão · brilho 100 ms · mensagem 800 ms · número de dano 900 ms subindo 1,5 m/s · passo máximo por quadro 250 ms |

## Como jogar (Arthur NÃO precisa abrir o editor)

```bash
cd ~/LivingWorld/.worktrees/lw-152 && tests/soak/run_sp6
```

Não é preciso definir `GODOT_BIN`: o script já usa `/Applications/Godot 2.app/Contents/MacOS/Godot` (o mesmo dos outros scripts). **Clique esquerdo** no boneco: escolher o alvo · **Q** pesado, **R** rápido, **F** perfurante · **T** troca a armadura do boneco · **Esc** ou clique no vazio: soltar o alvo · **W A S D**, Shift e Espaço andam como no jogo · **botão direito e arrastar** gira a câmera · **P** pausa. Ao fechar a janela, o terminal mostra o **resumo da sessão** (golpes, erros, dano total, menor estamina, pior quadro): cole no chat. O jogo nasce à meia-noite (a noite é azul-escura); a tecla 2 acelera o relógio.

## Roteiro de playtest (cerca de 10 minutos)

1. Ande (Shift corre) até uns 2 m do boneco, que está à frente no caminho, e clique nele: aparece o anel amarelo e o ataque automático começa sozinho.
2. Fique parado alguns segundos olhando os golpes automáticos (um a cada 1,5 s).
3. Aperte Q, depois R, depois F, um por vez; olhe o preparo e a recuperação nas barras dos três espaços.
4. Aperte duas habilidades em sequência rápida, perto do fim da recuperação (o buffer guarda a segunda).
5. Gaste a estamina até aparecer "Sem fôlego" e espere regenerar (ela só volta 1 s depois do último gasto).
6. Aperte Q e saia andando para trás (S, com Shift) até passar de 3 m antes de o preparo acabar: deve dar "Errou". Parado a mais de 2,5 m, aperte uma habilidade: "Longe demais".
7. Aperte T e compare o dano com armadura leve e pesada; compare o F (perfurante) com o Q na armadura pesada.
8. Gire a câmera e dê a volta no boneco: bata de frente, de lado e pelas costas e olhe a linha "Posição" e os números de dano.
9. Derrube o boneco (200 de vida) e veja ele ressurgir em 3 s (é preciso clicar de novo).

**Perguntas (respostas curtas):** (1) O golpe responde logo? (2) Dá para ler o que está acontecendo? (3) Preparo e recuperação têm bom ritmo? (4) A estamina cria decisão ou só atrapalha? (5) Andar em volta do boneco para dar dano pelas costas é divertido ou chato?

**Pedidos de ajuste:** diga "mais rápido", "mais pesado", "dura demais"; eu mudo só constantes e mostro "antes -> depois". Mecânica nova (outra habilidade, boneco que reage, ferimentos, bloqueio, esquiva) precisa de autorização nova.

## Respostas de Arthur (palavra por palavra; preencher depois do playtest, sem corrigir nem resumir)

| Pergunta | Resposta |
|---|---|
| 1. O golpe responde logo? | *(a preencher)* |
| 2. Dá para ler o que está acontecendo? | *(a preencher)* |
| 3. Preparo e recuperação têm bom ritmo? | *(a preencher)* |
| 4. A estamina cria decisão ou só atrapalha? | *(a preencher)* |
| 5. Dar a volta para bater pelas costas é divertido ou chato? | *(a preencher)* |
| Outras palavras dele | *(a preencher)* |

## Tolerâncias de janela definidas (roadmap LW-152)

Hoje valem os **valores iniciais [HIP]**: preparo Q 700 / R 200 / F 400 ms; recuperação Q 900 / R 400 / F 600 ms; tolerância de alcance no golpe 50 cm; buffer de entrada 200 ms. **Valor FINAL depois dos ajustes: a preencher** (rodadas de ajuste e Fase B). Se o playtest disser "sem resposta", vale o **plano B** da arquitetura 26.3: mais tolerância (buffer e alcance) e regras no cliente com validação leve.

## Verificações executadas (comandos que EU rodei, 07/11/2026)

- `tools/run_tests res://tests/soak/sp6/test_sp6_rules.gd` → `15/15 passed.`, 89 verificações, `---- All tests passed! ----`. O teste roda também no `tools/check_all` (o `run_tests` varre `tests/soak`).
- `tools/check_all` → **VERDE**: 53 scripts de teste, 486/486, `---- All tests passed! ----`; arquitetura, teclas fixas e texto literal aprovados.
- `tools/check_gdscript_warnings` → "sem avisos de compilação (SCRIPTS_VERIFICADOS: 143)".
- `tests/soak/run_sp6 --headless --quit-after 240` → carrega a cena sem erro e imprime o resumo ao encerrar.
- **Fiação com entrada real** (script temporário, apagado antes do commit; janela de 1152 x 648, com capturas de tela): o jogador andou até 193 cm; o clique no boneco o escolheu; o 1º golpe automático saiu na hora (vida 194); Q mostrou "Preparo" e estamina 66; 2 s depois a vida era 158 (194 − 30 do Q − 6 do automático), como na conta à mão do teste; T trocou a armadura; clique no vazio soltou o alvo; Q sem alvo mostrou "Sem alvo". As capturas acharam **dois defeitos que o teste sem janela não via, já corrigidos**: o painel da tela ficava com tamanho 0 x 0 (blocos fora do lugar) e, depois de corrigido, engolia o clique do mouse.
- **Contas do teste (a)** (armadura nenhuma, de frente; t em ms): t=1 automático 6 → 194; Q em t=1 acerta em t=701 → 164; t=1601 automático → 158; R em t=1601 acerta em t=1801 → 148; F em t=2201 acerta em t=2601 → 132; t=3201 automático → 126. Soma 6+30+6+10+16+6 = 74; 200 − 74 = 126. Estamina final 33,2 (conta no teste).
- **NÃO EXECUTADO:** a sensação (é de Arthur); o fechamento da janela pelo botão (o resumo foi visto ao encerrar por `quit`, mesmo caminho de desligamento); medição de quadros (as minhas execuções com captura de tela não valem como medida).

## Limitações

- Um só boneco, parado, sem reagir: não testa defesa, esquiva nem decisão sob pressão (fora por escolha de Arthur).
- Com a câmera padrão, o corpo do jogador cobre parte do boneco quando os dois estão a 2 m; o jogador pode girar a câmera. Árvores e pedras não têm colisão (DEC E4), então não atrapalham.
- Binário de depuração e noite no início (o jogo nasce à meia-noite): a legibilidade do boneco foi reforçada com um brilho próprio, para ele não sumir no escuro.
- Textos da tela literais no código do spike (não passam por `data/text/pt_br.json`, que o spike não pode alterar); descartável.
- **Tamanho do código (aviso para Arthur):** 9 arquivos de código novos e **862 linhas de código** (sem comentários e linhas em branco), dentro do teto de cerca de 700 mais 30% (910) e dos 11 arquivos; pelo `wc -l` seriam 1.155. Usei o sentido comum de "linhas de código"; Arthur pode contestar.

## O que o spike NÃO prova

Não prova a sensação (só o playtest de Arthur) nem o equilíbrio dos números. Não diz nada sobre combate contra NPCs, escala de batalhas (**DEC-053**: só foi testado 1 contra 1), animações, rede ou validação pela simulação, e desempenho com muitos combatentes. Não valida o sistema definitivo (**DEC-066** segue PENDENTE).

## Proposta de entrada para DECISIONS.md (número provisório; só proposta, o dev NÃO escreve em `DECISIONS.md`)

**DEC-121 (provisório; o próximo livre em `DECISIONS.md` é DEC-121, conferido em `307a9db`) — Combate por alvo e habilidades: tolerâncias e valores iniciais do SP6**

| Campo | Conteúdo |
|---|---|
| **Status** | PROPOSTA |
| **Contexto** | O SP6 (LW-152, antecipado pela DEC-080) testou o laço por alvo e habilidades (DEC-117) num duelo 1 contra 1. O playtest de Arthur diz se o laço é "responsivo e legível". |
| **Decisão** | *(a preencher depois do playtest)* Se Arthur aprovar: ficam como valores iniciais do combate do protótipo as janelas e os custos da tabela acima (valores finais depois dos ajustes), em dados e não em código. |
| **Justificativa** | Sensação validada jogando, não por argumento. Insumo da DEC-066; sobre a DEC-053 só diz que 1 contra 1 foi testado. |
| **Consequências** | A DEC-066 continua PENDENTE até Arthur decidir o sistema. A DEC-067 é revista: ferimentos, bloqueio e esquiva ficaram **fora** deste teste. As teclas e o botão do mouse do combate entram no `InputActions` oficial na Fase 5. |
| **Relações** | DEC-053, DEC-066, DEC-067, DEC-080, DEC-117 |
