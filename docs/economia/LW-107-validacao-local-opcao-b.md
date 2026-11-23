# LW-107c3, opção B: validação visual LOCAL (versão preparada; nada disto está no `main`)

**Escrito em 23/11/2026 pelo Maestro**, a pedido de Arthur: ver, na janela, a publicação, a aceitação, a entrega, as recompensas, as mensagens e o comportamento na escassez, ANTES de autorizar a ativação do postador. **Nada vai para o repositório e o postador segue DESLIGADO no `main`** (`data/economy/contract_templates.json` é `[]` lá). As encomendas só existem nas duas pastas abaixo, que são cópias locais; o PR da opção B (#152) segue RASCUNHO.

## 1. As duas pastas prontas (já importadas no Godot)
| Pasta (troque `PASTA` nos comandos) | Para quê |
|---|---|
| `/Users/arthurlk/LivingWorld/.worktrees/validacao-107c3-normal` | o jogo como ficaria com a opção B ligada (dado do #152 e as três regras de oferta do #153): `bread_standing` (5 pães, recompensa 53, 48 h) em cada mercado que cumpre a regra de postagem |
| `/Users/arthurlk/LivingWorld/.worktrees/validacao-107c3-escassez` | igual, mas com o pão ESCASSO desde o começo (estoque inicial 5 nos três mercados, só nesta pasta): o pão custa uns 32 cada (160 por 5 pães) e a encomenda continua pagando 53 por 5 pães |

Conferido por mim nas duas pastas (só `--headless`, sem janela): na normal, no 1º dia, **A e C** postam uma encomenda (às 06:00) e o B não (o pão de lá é mais barato, uns 10, e 5 pães custam uns 50, abaixo da recompensa de 53: a regra de 14/11 só deixa postar quando o preço do próprio emissor cobre a recompensa, e isso pode mudar com o preço do dia, então o B pode postar em outro momento); na de escassez os **três** mercados postam logo às 06:00 e o pão fica a uns 32. **Os números acima foram corrigidos em 23/11/2026 depois dos testes automáticos no jogo real (seção 5):** a primeira versão deste guia dizia pão a 8 no B e a uns 30 na escassez.

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
| 3 | Entrega e recompensa (o caminho do ganho): na aba Mercado do B compre 5 pães (uns 48 a 50 no começo, uns 10 cada; você começa com 100 de saldo; B fica a uns 500 m a leste e 100 m ao sul de A, cerca de 70 s correndo), volte ao mercado de A, aba Contratos, Entregar | o saldo sobe 53 e a linha passa a "Concluído"; sobram uns 5 de ganho (medido: 100 para 105), menos o tempo da viagem |
| 4 | O caminho do prejuízo: compre os 5 pães no próprio mercado de A (uns 55) e entregue | o saldo FINAL cai um pouco (medido: 100 para 98): a regra de 14/11 limita a recompensa ao preço, então comprar onde se entrega não dá lucro |
| 5 | Abandonar: aceite outra e aperte Abandonar | painel de confirmação; sem multa; você fica com os itens |
| 6 | Mensagem do quadro vazio (depois de aceitar tudo ou num mercado sem encomenda) | "Nenhuma encomenda disponível agora." (sem causa inventada) |
| 7 | Prazo: deixe uma vencer (2x e a pausa **P**) | "Vencido"; a recompensa volta ao emissor |

**Pasta de escassez (uns 5 minutos).** Abra a aba Contratos de A: a encomenda segue "Recompensa: 53", mas na aba Mercado o pão custa uns 32 (5 pães, 160). **Você começa com 100 de saldo: a compra dos 5 pães será RECUSADA por falta de saldo (os testes automáticos viram `ECON_INSUFFICIENT_FUNDS`), então, do jeito que a pasta está, você vê a recusa e não a perda.** A tela também não avisa que a entrega, para quem tivesse os 160, daria prejuízo de uns 107. **Para ver a perda de fato (opcional, só nesta pasta, com o jogo FECHADO):** dê mais saldo ao jogador com
```bash
sed -i '' 's/"initial_balance": 100}/"initial_balance": 300}/' /Users/arthurlk/LivingWorld/.worktrees/validacao-107c3-escassez/data/economy/owner_kinds.json
```
(só a linha do jogador tem 100 nesse arquivo; vale para um jogo NOVO), abra, aceite a encomenda de A, compre os 5 pães e entregue: o saldo cai de 300 para uns 193. É a decisão que falta: aceitar isso como risco do jogo, pedir um aviso na tela ou fazer o postador não publicar quando der prejuízo (opções X, Y e Z em `docs/economia/lw-107c3-opcao-b-condicoes.md`).

## 4. O que me dizer depois
Para cada item da tabela: OK ou não; qualquer texto estranho; se você entendeu sem ajuda o que fazer; e, na escassez, o que a tela mostrou quando a compra foi recusada por falta de saldo (a mensagem era clara?) e se aceitaria o contrato como está, se quer um aviso na tela ou se prefere que o postador não publique quando der prejuízo. Nada do que você fizer nas pastas locais altera o repositório.

## 5. O que os testes automáticos já conferiram (23/11/2026; isto NÃO substitui a janela)
Oito testes novos (`tests/integration/test_contract_option_b_real_world.gd`), no jogo real de 138 NPCs com o dado real, todos verdes: nada antes das 06:00 e, às 06:00, A e C postam 5 pães por 53 e o B não; o limite de abertos impede a segunda postagem; ciclo comprar no B (custo 48) e entregar no A (saldo 100 para 105, dinheiro e bens conservados a cada passo); comprar no emissor e entregar ali nunca dá lucro (custo 55, saldo 100 para 98); abandonar mantém os itens, sem multa, devolve a custódia e libera o espaço; o vencimento devolve a recompensa ao emissor com os fundos intactos e o postador reposta; na escassez os três mercados postam, o pão custa 32 e a compra do jogador novo é recusada por falta de saldo; o limite de 3 aceitas com os 3 contratos reais; salvar e carregar no meio de um contrato mantém o hash e a custódia. **O que só a janela mostra:** a leitura da tela e dos textos, a clareza para quem não sabe o que fazer e o "sentir" do jogo; os testes teleportam o jogador e avançam o relógio, então o corpo andando, as recusas de entrega no mundo real e a escassez de farinha (`flour_shortage`) no mundo real não foram vistos.
