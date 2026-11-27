# Proposta: o comerciante desembarca na doca e caminha até o mercado (27/11/2026)

Estado: **PROPOSTA, só documento.** Nada aqui é decisão: não altera o `DECISIONS.md`, o ROADMAP nem contrato nenhum. A opção O1 está pronta em PR isolado (ramo `lw099h-1-chegada`, empilhado sobre a série de PRs experimentais das docas do carrinho, #182 a #186; o #180 é o guarda-chuva dela). Quem decide é Arthur.

## 1. O que Arthur pediu (27/11/2026)
O comportamento definitivo que ele prefere: o comerciante **chega à doca, termina a viagem, desembarca ou deixa o carrinho e caminha até o mercado**; na partida, o inverso (caminha até a doca e embarca). A dissolução de 0,4 s da partida (PR #175) continua candidata, mas não deve esconder um salto de uns 6 m para sempre. Nenhum sistema novo de desembarque ou de movimento sem mostrar antes o impacto nos contratos e no roadmap: é este documento.

## 2. Como é hoje (conferido no código e nos contratos)
- **Na simulação** a viagem é só uma "caravana": rota, carga e **minutos por trecho**. O comerciante fica, logicamente, no centro do mercado de partida até chegar; ele não anda, não embarca nem desembarca. Na chegada a economia vende o lote, apaga a caravana e avisa (`CaravanArrived`); o `npc` põe o comerciante no centro do mercado de destino e o libera (`npc.md` 14.11, `economy.md` 9.7).
- **Na tela** (só apresentação, desligada por padrão) o carrinho anda da doca de saída à doca de chegada. O corpo comum do comerciante (`NpcView`) só existe quando ele NÃO tem caravana.
- **O salto:** na partida o carrinho nasce na doca e o corpo some da praça; na chegada o carrinho some na doca e o corpo volta no **centro** do mercado, no passo seguinte (até 1,25 s depois a 1x). Com as docas o salto é de 5,70 a 11,85 m (A 5,70; B 6,00; C 11,85 m, a de C na borda sul da praça); sem docas (o dado do `main`) é quase zero.
- **Tempo:** os minutos da viagem já valem do mercado ao mercado. Nada na simulação conta minutos de embarque, desembarque ou caminhada.

## 3. As três opções
**O1. O corpo reaparece na doca e anda até o mercado (PRONTA; só apresentação).** A vista das caravanas guarda a doca de chegada por 4 s reais [HIP]; quando o corpo do comerciante volta, ele nasce na doca (se ela ficar entre 0,25 e 15 m da posição lógica; senão, no centro, como hoje) e o motorista que já existe o leva até a borda da caixa do mercado. Sem doca no dado: idêntico a hoje (testado bit a bit); sem interruptor novo.
- Medido no jogo real (1ª viagem, destino C, motorista real): nasceu na doca, a 11,85 m do centro, 1,2 s depois da chegada; andou 9,14 m (2,3 s a 4 m/s) e parou na borda do mercado (2,71 m do centro). Pela mesma conta: A andaria 2,66 m e B, 3,60 m (docas de A e B não mudaram desde a 1ª medição). A rota a pé é reta e não desvia de peças da praça (DEC-122); medido com uma sonda descartável (pé de 0,8 m de lado contra as peças e as caixas, a cada 0,1 m), as três caminhadas passam sem tocar nada: A com 0,88 m de folga (o poço), B com 0,73 m (a fonte) e C com 0,08 m (a copa da árvore 2 da praça de C, a 3,9 m da doca; a de C cruza a metade sul da praça).
- Não cobre: a partida (segue o salto, ou a dissolução do #175); o carrinho ainda some na doca; se o comerciante não tiver ordem de ir a algum lugar, fica parado na doca (nas medições a primeira ação dele já era no mercado).

**O2. O1 + o carrinho fica parado na doca + a partida começa a pé (só apresentação).** Na chegada o carrinho (vazio, a carga já foi vendida) fica parado na doca como adereço da tela, por um prazo ou até a próxima partida do mesmo comerciante. Na partida o comerciante sai do centro a pé e o carrinho "entra" na estrada ao passar pela doca: os primeiros 1,5 a 3 s do desenho (6 a 12 m, até a doca) são a pé. O **instante de partida, o tempo total e a posição lógica não mudam**: a caminhada sai dos minutos que a simulação já dá à viagem (o desenho passa a ser "a pé até a doca, depois carrinho"). Cuidados: o caminho a pé entre as peças da praça (a rota dos NPCs é reta e não desvia: DEC-122); o carrinho parado não é salvo (some ao carregar); um corpo a mais na reserva por comerciante.

**O3. O desembarque na SIMULAÇÃO.** O comerciante ganha uma posição lógica de doca; embarcar e desembarcar viram ações com custo em minutos; a posição do NPC em viagem e a chegada passam a ser fatos do mundo (S0 e S1 concordam; o salto some de vez; o jogador pode falar com ele na doca).

## 4. Impacto lado a lado
| Eixo | O1 (pronta) | O2 | O3 |
|---|---|---|---|
| Contratos que mudam | só `presentation.md` (uma seção) | `presentation.md` e o contrato da LW-099 (a parte a pé) | `npc.md` 14.11, `economy.md` 9.x, `bridge.md`, `world.md`/dados e `persistence.md` |
| Simulação e hash | nenhum arquivo de simulação; `state_hash` igual com e sem a ligação (testado, com corpo perfeito e com motorista real) | igual: nenhuma escrita na simulação | posição do NPC e tempo mudam: hashes de referência com comerciante mudam (DEC-175: só com ordem de Arthur) |
| Tempo econômico da viagem | não muda | não muda (a caminhada cabe nos minutos que já existem) | muda, a menos que os minutos de embarque caiam dentro dos `leg_minutes` ou numa ação à parte |
| Saves | nenhum | nenhum (carrinho parado não é salvo) | campos novos: versão de save e migração |
| Ponte | nenhuma | nenhuma | `peek_caravan_bodies` e `peek_npc_bodies` mudam; o filtro do NPC em viagem deixa de ser preciso |
| Apresentação | 2 classes + 1 linha na cena | + adereço do carrinho e a partida a pé | o motorista normal leva o corpo; menos código de exceção |
| Desempenho | nenhum custo por quadro (uma consulta quando o corpo nasce) | um corpo a mais por comerciante | sem custo novo por quadro |
| Roadmap | subtarefa da LW-099 (Fase 3): "LW-099h" | subtarefa da LW-099: "LW-099i" [nome proposto] | tarefa NOVA, depois da LW-099 e antes da LW-113 se for do Ciclo do Mercador; senão, Fase 4 |
| Classe de risco | 3 (apresentação, aceite visual dele) | 3 | 3, e **4** se mexer em dado protegido ou regravar hash |
| Esforço | feito (~110 linhas de código, ~570 de teste) | médio (alguns dias) | grande (vários módulos, contratos escritos antes) |

**Determinismo:** o código novo da O1 nunca escreve na simulação. Com o motorista real, que relata a posição do corpo, o `state_hash` também foi igual 60 s reais depois da chegada, porque o `npc` só grava a posição do corpo como posição lógica do NPC quando ele **sai de S0** (`npc_lod.gd`). Depois disso há uma diferença pequena e esperada: no estado o comerciante fica onde o corpo parou (a borda do mercado), não no centro. É o canal da LW-072, já aprovado; os hashes de referência não mudam (a vista das caravanas nasce desligada e os testes deles não têm corpos). A medição depois da saída de S0 não foi feita.

## 5. Recomendação (nesta ordem)
1. **O1 agora**, em PR isolado, junto do aceite visual das docas (#180): ela só faz sentido com docas no dado.
2. **O2 depois** do aceite visual da O1 e da decisão sobre a dissolução da partida (#175), em PR próprio; é o que realiza o "desembarca e caminha" sem tocar contrato.
3. **O3 só com contrato escrito e ordem dele.** Antes, ver na janela se a O2 já basta: a O3 custa um contrato novo em quatro módulos e a regravação de hashes.
Nunca juntar duas delas no mesmo PR.

## 6. Perguntas que dependem de Arthur
1. O desembarque deve **gastar minutos de jogo** (muda lucro e prazo) ou é só desenho (O2)?
2. O carrinho **fica na doca** (até quando: um prazo, ou até a próxima partida do mesmo comerciante) ou some depois de descarregar? E ao carregar um save?
3. Na partida, aceita que a viagem **comece a pé no centro** (de 1,5 a 3 s), com o carrinho entrando na doca?
4. Se o comerciante chegar sem nada para fazer no mercado, ele deve **ir ao mercado mesmo assim** (hoje só anda se a primeira ordem dele tiver destino)?
5. Aceita a O2 como PR **experimental** (como o #180), julgado na janela, antes de qualquer contrato?
6. Na O3, as docas passam a ser **dado do mundo** (`places.json`, dado protegido)? Isso muda os hashes de referência.

## 7. O que não foi verificado
Nada foi visto na janela (só testes sem janela); sem benchmark de desempenho; as caminhadas de A e B são conta, não medição; a 2ª e a 3ª viagens, e a velocidade 8x, não foram medidas.
