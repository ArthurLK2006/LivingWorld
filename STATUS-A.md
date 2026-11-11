11/11/2026 20:03 (Brasília) · LW-093 COMPLETA (7 partes, ponta e16072b, `check_all` VERDE 151 scripts/1.322 testes, hashes e `run_sim` iguais). PAREI NA LW-094: tirar o `FoodStub` mata os 100 NPCs de fome em 6 dias (não há produção no jogo real até a LW-097), apaga/altera testes existentes e muda hashes por outra causa; preciso da sua decisão (A a E no item 7)

# RELATÓRIO — LW-093 (partes 1 a 7, completa) e parada na LW-094     Status: PARCIAL (PARADA na LW-094: precisa da sua autorização e de uma decisão de design)

## 1. RESUMO
A LW-093 está completa em 7 partes empilhadas, cada uma com `check_all` VERDE na ponta: o NPC abre conta na economia (com dinheiro inicial por `mint`), o jogo real recebe a economia, a economia responde sobre bens, o tipo de local do mercado virou `market`, o NPC compra, come do inventário e vende, e o pensador escolhe `buy` quando a fome está urgente. **Parei ao abrir a LW-094** (remover o `FoodStub`): ela exige apagar e alterar testes existentes que você não autorizou, mudaria hashes por causa diferente da aprovada, e, principalmente, **tiraria a única fonte de comida do jogo real**: não existe nenhum local de produção nele até a LW-097. LW-094, 095, 096 e 096a não foram iniciadas. Nenhuma tag, nenhum push no `main`.

## Declaração de leitura
**Li:** `AGENTS.md` v0.4; roadmap (LW-093 a 096a, `TEMP-LW-065`/`066`); `docs/modules/economy.md`, `npc.md` 14.2 a 14.8 e `world.md`; os testes que a LW-094 tocaria. **Decisões:** DEC-145, 147, 153, 160, 163, 167, 168, 170 e 175 (APROVADAS). Não li o GDD nem a arquitetura inteiros.

## 2. ARQUIVOS (por parte; ramos empilhados, todos enviados)
| Parte | Ramo / commit | O que é | Arquivos |
|---|---|---|---|
| Junção | `lw-092g-juncao-das-correcoes` `9df6aaa` | merge das 3 correções (092d, 092e, 092f) sobre o `main` | só conflito em `economy_module.gd` e README da economia; 1 ajuste no MEU teste novo da 092e (abre a conta do jogador) |
| 1 | `lw-093-contas-dos-npcs` `35cfae0` | o NPC abre a conta ao nascer | `npc_lifecycle`, `npc_module`, `game_modules`, 9 valores do oráculo, 1 teste |
| 2 | `lw-093d-dinheiro-e-consumo` `3bbcd60` | `mint` `game_start` na abertura da conta; `request_consume` | economia + 1 teste |
| 3 | `lw-093e-jogo-real-com-economia` `49a602b` | o jogo real recebe as definições da economia | `game_app`, `simulation_host`, docs, 1 teste |
| 4 | `lw-093g-consulta-de-bens` `169b446` | `peek_good` e `peek_goods_for_need` (mudança de contrato B) | 7 arquivos, 100 linhas |
| 5 | `lw-093h-tipo-de-local-market` `ece4c60` | `market_reserved` vira `market` (DEC-160) | 19 arquivos, 36 linhas trocadas; os 7 testes existentes editados são os da sua autorização A |
| 6 | `lw-093i-comprar-e-vender` `24ca878` | ações `buy` e `sell`, `NpcTrade`, conclusão da ação na economia, `eat` pelo inventário | 15 arquivos (2 são `.uid` gerados), 456 linhas com docs: no limite da DEC-126 |
| 7 | `lw-093j-pensador-compra` `e16072b` | o pensador escolhe `buy` por valor derivado (Q19) | 14 arquivos (2 `.uid`), 391 linhas; 3 testes novos |
Ramos locais obsoletos que não posso apagar: `lw-093-npcs-no-mercado`, `lw-093c-dinheiro-inicial-e-consumo`.

## 3. ARQUIVOS MODIFICADOS NA PARTE 7
`npc_thinker.gd` (+29: `_buy_relieves`, `_for_scoring`, `buy_value` no provedor), `npc_trade.gd` (+15: `buy_value`), `npc_params.gd`/`npc_params_loader.gd`/`data/npc_params.json` (`buy_price_percent` [HIP] = 100), `npc_decision_runtime.gd`, `npc.md`, README do `npc` e de `tests/integration`; testes: `test_npc_buy_decision.gd` (6, economia real, mundo à mão), `test_npc_buys_food.gd` (jogo real, estoque provisório zerado), `buy_value` em `test_npc_trade.gd`.

## 4. DECISÕES TÉCNICAS
- **Suas decisões A, B e C (11/11/2026) aplicadas:** (A) renome `market_reserved`→`market` com os testes listados; (B) `peek_good`/`peek_goods_for_need`; (C) o NPC compra a comida que mais alivia por moeda até `buy_units` [HIP] (2); `eat` come do inventário e, na falta, do `FoodStub` de reserva até a LW-094; `sell` só no catálogo (nenhum NPC comum o escolhe); código novo em `src/sim/npc/trade/`.
- **Valor de `buy` (parte 7):** alívio da melhor compra menos o preço (total pago × `buy_price_percent` / 100), nunca negativo; só com a fome urgente. O pensador dá ao pontuador uma CÓPIA de `buy` com esse efeito (o catálogo não muda). A distância e o tempo pesam pela conta de utilidade de sempre.
- **Desvios do texto do contrato (a seu critério):** `buy` e `sell` não têm condições de dados (o pensador e a conclusão por regra decidem), porque o teste `test_action_equivalence.gd` roda todas as ações do catálogo com provedor falso; a conclusão devolve dados simples (`Completion`) e o `ActionRunner` monta o efeito (`test_action_single_path.gd`); `eat` interrompido mantém o alívio proporcional de sempre.
- **Proposta de entrada para `DECISIONS.md` (I4; numeração provisória DEC-234, faixa da A; NÃO editei o `DECISIONS.md`):** *Título:* exceção pontual à DEC-107 e ao AGENTS 4.17: a economia lê `npc_id` do `NpcDied` pelo nome do campo. *Contexto:* a DEC-132 manda a economia nunca importar o `npc` e a DEC-146 manda fechar o dono ao ouvir `NpcDied`; para cumprir as duas, o `EconomyModule` assina `"NpcDied"` por texto e lê `event.get("npc_id")`, leitura por nome que a DEC-107 (DESCARTADA) e o AGENTS 4.17 proíbem. *Decisão proposta:* uma exceção única e nomeada: a economia pode ler um único campo inteiro (`npc_id`) do evento, com o tipo conferido (`TYPE_INT`); nenhuma chamada dinâmica, carga de código nem outro uso de reflexão; qualquer outra leitura por nome exige outra DEC. *Justificativa:* cumpre a DEC-132 e a DEC-146 sem mudar o `npc`; o risco (renomear o evento ou o campo sem erro de compilação) está coberto por `test_a_dead_npc_is_closed_by_the_event_and_keeps_money_and_goods_in_the_sum`, que usa o `NpcDied` real. *Consequências:* `docs/events.md` já diz "[PROPOSTA]" na linha do evento (trocar pelo número); revisar na LW-093 em diante, quando o `npc` puder chamar `request_close_owner` (opção b, sem reflexão).

## 5. TESTES EXECUTADOS (`tools/check_all`, resultados reais)
| Ponta | Commit | Scripts | Testes | Asserts | Resultado |
|---|---|---|---|---|---|
| Fase B | `d1d3d8b` | 142 | 1.293 | 292.694 | VERDE |
| Junção | `9df6aaa` | 144 | 1.298 | 292.805 | VERDE |
| Parte 1 | `35cfae0` | 145 | 1.300 | 292.817 | VERDE (hashes do marco 2) |
| Parte 2 | `3bbcd60` | 146 | 1.303 | 292.859 | VERDE |
| Parte 3 | `49a602b` | 147 | 1.305 | 292.968 | VERDE |
| Parte 4 | `169b446` | 148 | 1.307 | 292.980 | VERDE |
| Parte 5 | `ece4c60` | 148 | 1.307 | 292.981 | VERDE |
| Parte 6 | `24ca878` | 149 | 1.314 | 293.115 | VERDE |
| Parte 7 | `e16072b` | 151 | 1.322 | 293.484 | VERDE (EXIT 0; o 1º `check_all` da parte 7 deu VERMELHO por 1 aviso de divisão inteira no meu teste novo; corrigi e repeti) |
Zero avisos de compilação; `run_sim` (`--days 30 --seed 1`) `732907967efdba5f718687a0bbafbfe102ac51cabc9d15a7f0119a9e64ebc4d7` igual em todas as pontas. **Mutações da parte 7 (9):** pegas M1 (`buy` nunca alivia), M2 (`buy` sem o efeito derivado), M3 (alivia sem fome urgente), M4/M5/M6 (preço ignorado, percentagem ignorada, valor negativo) e M9 (sem as duas guardas); sobreviveram M7 e M8, equivalentes (a guarda `valor > 0` está em dois lugares; tirar só uma não muda nada, tirar as duas é pego). Dois testes foram acrescentados por causa de M2 e M3.

## 6. RESULTADOS: valores de referência do marco 2 (antigo → novo, causa)
**Causa única (provada):** o bloco `economy` do save passa a ter as contas dos NPCs. **Prova:** numa cópia temporária do oráculo tirei o bloco `economy` do hash e os 9 valores ORIGINAIS (`6e12b3067120`, `506a4a23ce89`, `7008d3b19d38`, `84ca55684e34`, `ce14b1e45954`, `142733eb318f`, `00794d5a27b6`, `3e1d080d2eed`, `f9469ccc5a9d`) voltaram; desfeito e conferido com `cmp`. Só as 9 constantes do oráculo foram trocadas (9 linhas no diff).
| Constante | Antigo (marco 1) | Novo |
|---|---|---|
| `intents` | `223b8ec6a7ed` | `8670b52b8ff6` |
| `alarm` | `dfe616868618` | `b62628f049b0` |
| `resumed` | `db2469cec836` | `1251aaf06e2d` |
| `switches` | `888b1962d83b` | `6889619788b5` |
| `talk` | `8b04890c8c9b` | `a8a97e95f464` |
| `save` | `5673e2b3911b` | `781066cec584` |
| `demote` | `62c86fea8233` | `ed884fc6fb21` |
| `starved` | `52c2d24b40fc` | `f11a33ea9ab0` |
| `real_game` | `edf6ebb03cb9` | `76a65b9cfc8a` |
Soaks (só imprimem; o teste do soak de 30 dias não tem constante): vida de 7 dias `af5bdb5e1f21` → `d7266f48286e`; 300 NPCs `52b7851aefc0` → `f31f5186abf5`; 30 dias `82f81b239759` → `706f065740c5`. `run_sim` (`--days 30 --seed 1`): `732907967efdba5f718687a0bbafbfe102ac51cabc9d15a7f0119a9e64ebc4d7`, **igual** em todas as partes. As partes 2 e 3 não mudaram nenhum valor (o oráculo e os soaks não passam pelo host e usam a economia sem definições).
**Partes 4 a 7 não mudaram nenhum valor de referência** (oráculo verde com as constantes do marco 2; os prints dos soaks de 7 dias `d7266f48286e` e de 300 NPCs `f31f5186abf5` iguais aos da parte 1). **Medido na parte 7:** no jogo real com o estoque provisório zerado, em 3 dias os NPCs compram e comem as 300 unidades de comida dos dois mercados (100 pão, 200 grão); o razão tem só `game_start` e `trade` (3.148 moedas movidas) e a conservação do dinheiro e dos bens fecha.

## 7. PROBLEMAS ENCONTRADOS E PARADA
**PROPOSTA DE DESVIO (AGENTS 16.3): LW-094 não pode ser feita como está escrita.**
- **Regra afetada:** a sua condição de parada "hash mudar por causa diferente" e o AGENTS 9.5 (não apagar nem alterar teste sem autorização; a sua autorização só cobre as constantes do oráculo e do soak de 30 dias); também o aceite da LW-094 ("vida sem jogador de 30 dias continua verde"; "se falta comida, aparece escassez e não comida mágica").
- **Problema real (evidência):** (1) `data/economy/production_sites.json` é `[]`: o jogo real não tem local de produção até a LW-097 (DEC-167 põe os 10 locais `work` e o `work_place_id` lá). (2) Medido em 30 dias, 100 NPCs: a comida dos mercados cai de 300 para 48 no dia 2 e para 0 no dia 5 e nada a repõe; hoje ninguém morre (100 vivos, 0 mortos nos 30 dias) porque o `FoodStub` repõe (+5 por trabalho de agricultor). **Medi o que a LW-094 causaria** (teste temporário, já apagado: o jogo real de 30 dias com o estoque provisório mantido em zero a cada minuto): 100 vivos até o dia 4, **1 vivo no dia 5 e 0 no dia 6**: os 100 NPCs morrem de fome. (3) Testes existentes que a LW-094 teria de apagar ou alterar, nenhum autorizado: apagar `test_food_stub.gd`; alterar `test_npc_setup.gd` (linhas 52, 53, 112, 147: o `FoodStub` é o provedor e vai no save), `test_npc_split_oracle.gd` (linhas 194 e 280, que não são constantes), `test_npc_bodies_view.gd:75`, `test_npc_s0_reevaluation.gd:124`, `tests/soak/npc_life/npc_life_check.gd` e `test_npc_life_7d.gd`, a marca em `test_income_stub.gd`, e os provedores falsos de `test_critical_need.gd`, `test_decision_flow.gd`, `test_decision_trace.gd` se a assinatura de `has_food` mudar. (4) Tirar o `FoodStub` tira o bloco de comida do save do `npc`: o oráculo e os soaks mudam por causa diferente da aprovada, e o oráculo e o soak montam o jogo sem economia, ou seja, sem comida: precisam de nova montagem, não de troca de constante. (5) Pelo tamanho, passaria de 450 linhas e de 12 arquivos (DEC-126).
- **Opções:** **A (recomendada)** antecipar a produção mínima de comida do jogo real (preencher `production_sites.json` e o `work_place_id` dos lavradores e padeiros; hoje é LW-097), e só então fazer a LW-094 em duas partes (código e dados; depois testes); **B** seguir a ordem e dar um estoque inicial enorme de comida ao mercado: é comida mágica, contra o aceite; **C** pular a LW-094 e a LW-095 por ora e seguir com a LW-096 (contratos na economia, independe de testes existentes; sem produção ninguém recebe salário e a vaga só valeria para local de produção, porque os postos vêm na LW-095); **D** autorizar a LW-094 como está, aceitando mortes por fome e o soak de vida vermelho: não recomendo; **E** não desviar e esperar.
- **Impacto de A:** `data/economy/production_sites.json`, `data/population.json`, a distribuição de locais `work` (arquivos protegidos fora do escopo da tarefa: preciso da sua autorização), e uma nova rodada de hashes; reverter é voltar os dados.
- Também: o 1º `check_all` da parte 7 ficou vermelho por um aviso do meu teste (corrigido). Rede caiu uma vez em um push de partes anteriores; repeti e funcionou.

## 8. RISCOS
- A economia do jogo real hoje só tem a comida inicial dos mercados e o dinheiro de 60 por NPC; sem produção a comida acaba em 5 dias e, sem o `FoodStub`, o mundo morre de fome em 6 (medido).
- `buy_units` (2) e `buy_price_percent` (100) são [HIP]; com os preços atuais o total de 2 grãos fica abaixo dos 60 pontos de alívio (testado), então o NPC compra sempre que está com fome e tem dinheiro.
- Parte 5 mexeu em 19 arquivos (renome puro) e a parte 6 ficou no limite de tamanho da DEC-126.

## 9. PENDÊNCIAS (suas)
1. **Escolher A, B, C, D ou E para a LW-094** (recomendo A) e, se A ou D, **autorizar por escrito** os testes e os arquivos de dados listados no item 7.
2. Registrar a DEC do I4 (proposta no item 4, DEC-234 provisória); autorizar o ajuste do caso `reply.gd` do `test_check_architecture.sh` para fechar o N9.
3. O `README.md` do projeto ainda está desatualizado no contador de tarefas; não toquei.
4. Testes manuais: nenhum necessário nesta etapa (tudo coberto por teste automático sem janela).

## ACOMPANHAMENTO
- **Avanço:** LW-093 completa (7 partes). Marco 2 aberto, hashes aprovados e estáveis desde a parte 1. Faltam LW-094, 095, 096 e 096a.
- **Próxima tarefa recomendada:** a LW-094 depois da sua decisão (item 9.1). Não iniciada.
- **Git:** `main` em `d1d3d8b`; ramos enviados `lw-092g`, `lw-093`, `lw-093d`, `lw-093e`, `lw-093g`, `lw-093h`, `lw-093i`, `lw-093j-pensador-compra` e `status-a`. Sem tag, sem `--force`, sem rebase nem reset; `stash` não usado.
