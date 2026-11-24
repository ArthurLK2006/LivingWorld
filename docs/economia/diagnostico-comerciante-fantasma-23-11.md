# Diagnóstico: o "comerciante-fantasma" existe hoje no `main` (medido, 23/11/2026)

**Estado: CONFIRMADO por medição headless. Nada foi corrigido nem implementado; é um defeito visível do código atual.** A hipótese veio da leitura do código pelo agente que escreveu o [contrato técnico da LW-099](contrato-lw-099-viagem-visivel.md) (rascunho, PR #158), seção 6. A medição foi feita numa CÓPIA descartável do `main` (código do `89d935d`), com um script de sonda que monta o jogo real (6 comerciantes, economia e rotas), liga os corpos e o foco do jogador como a apresentação faz e consulta os corpos pela ponte real `SimBridge.peek_npc_bodies()`. O Maestro rodou a sonda de novo e obteve os mesmos números.

## O que foi medido (comerciante 126, rota B para C, 340 m, 96 minutos de jogo; mercado de partida em (807; 653) m)
| cenário | minutos em que o comerciante tem corpo (está em S0), de 95 |
|---|---|
| A: foco do jogador a 10 m do mercado de partida, ANTES da partida | **95** (o corpo fica em (807,0; 653,0), a 0,0 m do mercado, enquanto a caravana anda de 0 a 340 m) |
| B: foco a 10 m DEPOIS da partida | 65 (entra em S0 no minuto 1; se o foco vai a 130 m, o corpo some no minuto 32 e volta quando o foco retorna, no 62) |
| C: controle, foco a 200 m | 0 |
| D: como o A, com uma conversa aceita no minuto 20 | 95 (a conversa é aceita e a caravana chega no mesmo minuto) |
- Em todos, o corpo some na chegada (minuto 96, igual ao ETA) e a posição lógica do NPC vai para o povoado C, em (567; 853).

## Causa confirmada no código
- `src/sim/npc/lod/lod_reconstruction.gd` linha 15: `is_in_transit` exige uma ação com destino; o comerciante em viagem não tem ação (ação vazia em 95 de 95 minutos), porque a viagem é só "ter caravana na economia". Para o LOD ele está parado no mercado de partida.
- `src/sim/npc/lod/npc_lod.gd` (`_candidates`): entra em S0 a até 80 m do foco e só sai acima de 120 m (`data/lod_params.json`), medido a partir do corpo, que continua no mercado.
- `src/sim/npc/trade/merchant_arrival.gd`: só na CHEGADA o corpo é solto e o NPC é realocado no destino. `src/bridge/sim_bridge.gd` linha 338: `peek_npc_bodies` lista todo S0, sem filtro de viagem.
- O NPC pensa a cada 10 minutos, só para necessidades e morte; não escolhe ação nem recebe `Intent`; só age se o jogador conversar com ele. `release_body` não resolveria (por leitura: ele voltaria a S0 no passo seguinte).

## O que o jogador veria (deduzido da leitura da apresentação; a janela NÃO foi aberta)
Uma figura do comerciante PARADA na praça de partida, como se não tivesse saído, enquanto o jogador estiver a menos de 80 m (entra) e até 120 m (sai); ela some na chegada. Hoje não há caravana visível, só o fantasma. Aparece também se o jogador chega à praça depois da partida, e dá para conversar com ele.

## O que fazer (nada decidido; depende de Arthur)
O contrato da LW-099 propõe o remédio na 099b: `peek_npc_bodies` omitir o NPC que tem caravana (`peek_caravan(id).found`), com o `CaravanView` ocupando o lugar dele na tela. Se Arthur quiser tirar o fantasma ANTES da viagem visível, o menor passo seria só esse filtro na ponte (mudança de comportamento da consulta da ponte: classe 3, com decisão dele); a LW-099 inteira e este filtro seguem NÃO autorizados para implementar.

## O que NÃO foi verificado
A janela e a cena (só headless, mas pela ponte real); corpos reais andando e com atraso (a sonda usa um corpo "perfeito" que cumpre cada intenção no fim previsto); uma só viagem (a causa no código não depende da rota); desempenho e a suíte completa. A sonda (`test_ghost_probe.gd`, 5 segundos) ficou na cópia, fora do repositório; a tarefa 099c a reescreveria como teste.
