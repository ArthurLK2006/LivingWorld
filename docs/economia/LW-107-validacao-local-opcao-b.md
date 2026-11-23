# LW-107c3, opção B: validação visual LOCAL (versão preparada; nada disto está no `main`)

**Escrito em 23/11/2026 pelo Maestro**, a pedido de Arthur: ver, na janela, a publicação, a aceitação, a entrega, as recompensas, as mensagens e o comportamento na escassez, ANTES de autorizar a ativação do postador. **Nada vai para o repositório e o postador segue DESLIGADO no `main`** (`data/economy/contract_templates.json` é `[]` lá). As encomendas só existem nas duas pastas abaixo, que são cópias locais; o PR da opção B (#152) segue RASCUNHO.

## 1. As duas pastas prontas (já importadas no Godot)
| Pasta (troque `PASTA` nos comandos) | Para quê |
|---|---|
| `/Users/arthurlk/LivingWorld/.worktrees/validacao-107c3-normal` | o jogo como ficaria com a opção B ligada (dado do #152 e as três regras de oferta do #153): `bread_standing` (5 pães, recompensa 53, 48 h) em cada mercado que cumpre a regra de postagem |
| `/Users/arthurlk/LivingWorld/.worktrees/validacao-107c3-escassez` | igual, mas com o pão ESCASSO desde o começo (estoque inicial 5 nos três mercados, só nesta pasta): o pão custa uns 30 cada e a encomenda continua pagando 53 por 5 pães |

Conferido por mim nas duas pastas (só `--headless`, sem janela): na normal, no 1º dia, **A e C** postam uma encomenda (às 06:00) e o B não (pão a 8, a regra de postagem não passa); na de escassez os **três** mercados postam logo às 06:00 e o pão fica a cerca de 30.

## 2. Abrir o jogo
```bash
"/Applications/Godot 2.app/Contents/MacOS/Godot" --path PASTA
```
Fechar: **Command+Q**. As teclas, o caminho até o povoado A (uns 45 s correndo) e a velocidade (tecla **2**, 2x) são os de `docs/economia/LW-107-roteiro-para-arthur.md`, seções 2 e 3. **Não rode o `cp` do passo 2.1 desse roteiro:** o dado já está ligado nestas pastas. O `sed` opcional do passo 2.2 (3 abertas e prazo de 16 h) só serve se você quiser ver o "3 de 3" e o "Vencido" depressa; nunca o rode com a pasta aberta.

## 3. O que olhar
**Pasta normal (15 a 20 minutos).** Aperte **2** logo ao abrir; às 06:00 de jogo (uns 20 s depois) as encomendas já existem.
| # | Faça | Deve acontecer |
|---|---|---|
| 1 | Publicação: no mercado de A (aba Contratos) | "Entregar 5 x Pão", "Recompensa: 53" e o prazo (cerca de 2 dias); C também tem uma; B não |
| 2 | Aceitação: escolha a linha e aperte Aceitar | a linha vai para "Meus contratos"; "Encomendas aceitas: 1 de 3" |
| 3 | Entrega e recompensa (o caminho do ganho): na aba Mercado do B compre 5 pães (uns 40 no começo; B fica a uns 500 m a leste e 100 m ao sul de A, cerca de 70 s correndo), volte ao mercado de A, aba Contratos, Entregar | o saldo sobe 53 e a linha passa a "Concluído"; sobram uns 13 de ganho, menos o tempo da viagem |
| 4 | O caminho do prejuízo: compre os 5 pães no próprio mercado de A (uns 55 a 60) e entregue | o saldo FINAL cai um pouco: a regra de 14/11 limita a recompensa ao preço, então comprar onde se entrega não dá lucro |
| 5 | Abandonar: aceite outra e aperte Abandonar | painel de confirmação; sem multa; você fica com os itens |
| 6 | Mensagem do quadro vazio (depois de aceitar tudo ou num mercado sem encomenda) | "Nenhuma encomenda disponível agora." (sem causa inventada) |
| 7 | Prazo: deixe uma vencer (2x e a pausa **P**) | "Vencido"; a recompensa volta ao emissor |

**Pasta de escassez (uns 5 minutos).** Abra a aba Contratos de A: a encomenda segue "Recompensa: 53", mas na aba Mercado o pão custa perto de 30 (5 pães, uns 150). **A tela não avisa que a entrega dá prejuízo.** Se aceitar e entregar, o saldo cai uns 100. É a decisão que falta: aceitar isso como risco do jogo, pedir um aviso na tela ou fazer o postador não publicar quando der prejuízo (opções X, Y e Z em `docs/economia/lw-107c3-opcao-b-condicoes.md`).

## 4. O que me dizer depois
Para cada item da tabela: OK ou não; qualquer texto estranho; se você entendeu sem ajuda o que fazer; e, na escassez, se aceitaria o contrato como está, se quer um aviso na tela ou se prefere que o postador não publique quando der prejuízo. Nada do que você fizer nas pastas locais altera o repositório.
