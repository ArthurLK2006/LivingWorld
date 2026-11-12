12/11/2026 15:47 (Brasília) · LW-105 PRONTA PARA REVISAO em ramos (a 26525cb, b 4270a61, c 2130c7d; check_all VERDE em cada parte, c: 186 scripts/1.567 testes); nada da 105 no main. LW-094 BLOQUEADA (opcoes A-D no relatorio abaixo, recomendo A). Entrada do v12 FEITA (main 69bbbb4; hoje main=1a2fc8b da conversa C). Aguardando sua decisao; nada iniciado alem disso


# RELATÓRIO — LW-105: jogador na economia (partes a, b e a junção c) — PARTE 3 do bloco v13     Status: PRONTA PARA REVISÃO (só em ramos; **não entra no `main` neste bloco**, como você mandou; a B revisa)

## 1. RESUMO
O jogador agora tem conta de dinheiro e inventário com peso na economia e compra e vende pela ponte. O saldo vem do `Ledger`, as quantidades e o peso ficam na `economy` (DEC-130) e o dinheiro inicial nasce por `mint` com motivo `game_start` (DEC-147). Escrevi o contrato primeiro (parte a), depois a compra e a venda com chave de texto por código e a ida e volta de save (parte b). A conversa C levou a LW-108 ao `main` no meio do trabalho; fiz a junção no ramo c. Tudo `--headless`, nenhuma janela.

## 2. LEITURA E DECISÕES (AGENTS 2.3)
Li `economy.md` (seções 3, 5, 10 e 14), `bridge.md`, `character.md` (a parte do jogador), o roteiro (LW-105, LW-089, LW-091, LW-035) e os dados. **DEC-130 e DEC-147: APROVADAS**; DEC-145 e DEC-146 (a ponte abre a conta do jogador): aprovadas. **O que já existia e não refiz:** o tipo de dono `player` em `owner_kinds.json` (**saldo inicial 100 e capacidade de peso 60, ambos [HIP]**, não mexi) e o `request_trade` para qualquer dono aberto. **O que faltava era a ponte e o contrato do jogador.**

## 3. RAMOS (todos enviados; nenhum no `main`; sem tag; nenhum ramo apagado)
- `lw-105a-contrato-e-conta-do-jogador` (`26525cb`): contrato em `bridge.md` ("Jogador na economia") e `economy.md`; `BridgePlayerEconomy`; `request_open_player_account` e `peek_player_economy`; 5 testes. **check_all VERDE: 180 scripts, 1.517 testes, 298.669 asserts.**
- `lw-105b-compra-e-venda-do-jogador` (`4270a61`): `request_trade` na ponte, `PlayerTradeReply` com a chave do texto, 10 chaves em `data/text/pt_br.json`, 9 testes. **check_all VERDE: 181 scripts, 1.526 testes, 298.769 asserts.**
- `lw-105c-junta-com-o-main` (`2130c7d`; junção `git merge origin/main` = `1a2fc8b`, a LW-108; sem rebase): **check_all VERDE: 186 scripts, 1.567 testes, 299.355 asserts** (já com os testes da LW-108); ver seção 6.
- Tamanho (só código, teste e dados, sem comentário nem linha em branco): **parte a 141 linhas, parte b 216 linhas**, 4 e 5 arquivos de código/teste (mais docs e `.uid`). Bem abaixo de 450 linhas e 12 arquivos. `sim_bridge.gd`: 269 linhas de código (limite ~300).

## 4. O QUE FOI FEITO (ARQUIVOS)
- **Criados:** `src/bridge/bridge_player_economy.gd` (o repasse fino: abrir conta, consultar, negociar; sem regra de jogo), `src/bridge/bridge_player_economy_replies.gd` (os tipos de resposta, em cópia: `PlayerEconomyReply` com `funds`, `weight`, `capacity`, `goods`; `PlayerTradeReply` com `quantity`, `total`, `text_key`), `tests/unit/test_bridge_player_account.gd` (5 testes), `tests/unit/test_bridge_player_trade.gd` (9 testes).
- **Modificados:** `src/bridge/sim_bridge.gd` (`request_open_player_account`, `peek_player_economy`, `request_trade`; o código `BRIDGE_NO_ECONOMY` e os auxiliares do módulo da economia já vieram do `main` na junção), `data/text/pt_br.json` (+10 chaves `economy.trade.*`), `docs/modules/bridge.md`, `docs/modules/economy.md` (só duas frases) e `src/bridge/README.md`.
- **O jogador é um personagem guardado no `character` e o ID do ator é o ID do dono na economia** (todo ID vem do mesmo `ctx.ids`). A ponte só atende quem o `character` conhece: um NPC, um ID solto ou o próprio mercado como ator voltam com `CHARACTER_UNKNOWN_ACTOR` antes de chegar à economia. A ponte **não expõe** `request_transfer_goods` (responde ao item do `docs/backlog.md` sobre quem pode mover bens de quem).

## 5. TESTES (comandos e resultados reais)
- `tools/run_tests res://tests/unit/test_bridge_player_account.gd`: 5 de 5 (28 asserções). `tools/run_tests res://tests/unit/test_bridge_player_trade.gd`: 9 de 9 (99 asserções).
- Cobrem: a conta abre com o saldo e a capacidade **lidos dos dados** e o dinheiro nasce por um `mint` só; abrir de novo não muda nada; compra e venda movem saldo (do `Ledger`), estoque do mercado e inventário juntos, e o dinheiro vai e volta do mercado; **peso máximo**: a lenha que cabe exatamente no limite passa e uma unidade a mais é recusada com `ECON_CAPACITY_EXCEEDED` sem mudar nada; sem dinheiro, sem o bem e sem estoque voltam com a chave certa e nada muda; mercado, bem, quantidade e lado inválidos, e personagem sem conta, usam a chave genérica; NPC e mercado como ator são recusados; sem jogo, sem personagem ou sem economia as chamadas falham com código; toda chave existe em `pt_br.json`; os lados `buy` e `sell` da ponte são os do motor; **ida e volta de save**: a conta, o saldo, os bens, o peso e a capacidade voltam iguais, o hash do mundo bate e o mesmo jogador continua negociando.
- **Controle de mutação** (cada mutante tem de ser morto pelos testes; arquivo restaurado e conferido depois): 7 mutantes (não conferir o personagem ao abrir; saldo +1; peso e capacidade trocados; não conferir o personagem ao negociar; sem a chave do peso; chaves de compra e venda trocadas; total +1): **os 7 morreram** (4 de 5, 3 de 5, 4 de 5, 8 de 9, 8 de 9, 7 de 9 e 6 de 9 passando).
- `tools/check_all` das partes a e b: acima. **Da junção c: VERDE, EXIT 0, 186 scripts, 1.567 testes, 1.567 aprovados, 299.355 asserts, zero avisos.**

## 6. JUNÇÃO COM O `main` (`lw-105c`) E PROBLEMAS ENCONTRADOS (nada omitido)
1. **Colisão de nome:** a conversa C (LW-108b) e eu criamos, cada um, `src/bridge/bridge_economy_replies.gd` com `class_name BridgeEconomyReplies` (conflito "add/add"), e também `_economy()`, `_missing_economy()` e `BRIDGE_NO_ECONOMY` iguais nos dois lados. **Fiquei com o arquivo dela, sem tocar nele**, e renomeei o meu para `BridgePlayerEconomyReplies` (arquivo próprio); os auxiliares iguais ficaram os do `main`. Conflitos de texto em `bridge.md` e `sim_bridge.gd` resolvidos mantendo os dois lados.
2. **Regra F do `tools/check_architecture`** acusou `balance = ...` no meu tipo de resposta (a regra só aceita essa atribuição em `economy/api/`). Não desliguei nada: o campo se chama `funds` (cópia do saldo do `Ledger`).
3. **Aviso de divisão inteira** do GDScript num teste meu (`capacity / unit_weight`): troquei por um laço de inteiros (zero avisos).
4. Cache de classes velho depois da junção: reconstruí com `godot --headless --path . --import` (AGENTS 4.3).

## 7. DECISÕES TÉCNICAS E PROPOSTAS (não decidi design; nada disso é decisão sua ainda)
- **Os lados `buy` e `sell`** ficam duplicados como constantes da ponte (`BridgePlayerEconomyReplies.SIDE_BUY` e `SIDE_SELL`) porque a ponte só pode citar a `economy/api/` e as constantes do motor não estão lá; um teste confere que são iguais.
- **PONTOS EM ABERTO (dúvidas de design, com recomendação):** (1) **quando a conta do jogador abre**: a ponte não decide; **recomendo chamada explícita** de quem guarda o `actor_id` logo depois de `request_spawn_character`, e **não** abrir dentro do nascimento (a ponte não vira dona de "o jogador"). Hoje **ninguém chama** `request_open_player_account` no jogo real (só os testes): a tela do mercado (LW-106) ou o `GameApp` precisam chamar. (2) **Evento de comércio:** o roteiro diz "eventos e textos por chave"; só fiz os **textos** por chave. Não há evento de comércio em `docs/events.md`; um `TradeCompleted` seria contrato novo e precisa da sua aprovação (**recomendo não criar agora**). (3) **Estar perto do mercado para negociar:** a economia não confere posição e o GDD não descreve; fica para a interface (LW-106) (**recomendo conferir na interface, pela posição guardada, como a conversa faz**). (4) **Valores [HIP]:** saldo inicial 100 e peso 60 continuam em `data/economy/owner_kinds.json`; com os preços de hoje o jogador compra, por exemplo, 12 lenhas (o limite de peso) por uns 55 de dinheiro, mas não 5 ferramentas. Não decidi nada sobre eles.
- **Proposta de entrada para `DECISIONS.md`:** nenhuma (usei o que a DEC-130, a DEC-145/146 e a DEC-147 já dizem).

## 8. RISCOS
Nada chama a conta do jogador no jogo real ainda (ponto 1 acima). A ponte confia no `character` para saber quem é jogador: se houver mais de um personagem (multijogador, fora do escopo) qualquer um negocia por si, mas só por si. A tarifa devolvida pelo motor (sempre 0 na Fase 3) não aparece na resposta (ainda não há cobrança; entra com a LW-130).

## 9. PENDÊNCIAS E O QUE ARTHUR CONFERE EM CASA
Nada visual: **não há tela** (a LW-106 faz a tela de mercado), então **não há nada para abrir no jogo agora**. A B pode revisar os três ramos. **Próxima tarefa recomendada:** LW-106 (interface de mercado), **não iniciada**; antes dela, decidir os pontos 1 a 3 acima.

- **Git:** `main` = `1a2fc8b` (a conversa C; eu não mexi depois de `69bbbb4`); `lw-105a` = `26525cb`, `lw-105b` = `4270a61` (enviados); `lw-105c` = `2130c7d` (enviados). Sem tag, sem `--force`, nenhum ramo apagado.

# RELATÓRIO — LW-094 (só o `FoodStub`) — PARTE 2 do bloco v13 (14:25)     Status: **BLOQUEADA — PAREI como o v12c mandou; nada da LW-094 entrou no `main`**

## 1. O QUE ACONTECEU, EM PALAVRAS SIMPLES
Fiz a parte de código da LW-094 (tirar o `FoodStub`) e **medi antes de mexer nos testes**, como você mandou. **Sem o `FoodStub`, no jogo real de 30 dias morrem os 132 NPCs** (A até o dia 6, C até o dia 9, B até o dia 15). Pela regra do v12c ("se o povoado passar fome: PARE, não mexa nos dados, escreva as opções"), **parei a LW-094**, não toquei em nenhum dado de jogo, não mexi nos testes e não levei nada ao `main`. O código pronto fica guardado no ramo `lw-094a-fim-do-foodstub-codigo` (`8c47b4c`, enviado, **NÃO verde**: os testes que citam o `FoodStub` ainda não foram trocados; **não entra no `main`**).

## 2. MEDIÇÃO (só `--headless`; jogo real = `start_default_game` + `run_days`; conservação do dinheiro e dos bens `true` e `validate()` com 0 problemas nos dois casos)
| | Com `FoodStub` (`main` 69bbbb4) | Sem `FoodStub` (`8c47b4c`) |
|---|---|---|
| NPCs vivos no dia 30 | **132** de 132 | **0** de 132 |
| Mortes | 0 | **132** (`NpcDied`) |
| `ContractOffered` em 30 dias | 0 | 14 (as vagas que a morte abre) |
| Comida (pão + grão) no mercado no dia 30 | A 0 · B 0 · C 38 | A 0 · B 114 · C 35 |
| Livro-razão (`salary` / `trade`) | 4.400 / 15.607 | 4.870 / 19.970 |
| Primeira morte / todos mortos | — | A: dia 5 / dia 6 · C: dia 5 / dia 9 · B: dia 8 / dia 15 |

## 3. POR QUE MORREM (fatos medidos; a causa NÃO é só o povoado C)
1. **Os locais de produção ficam sem dinheiro (`NO_FUNDS`) já no 1º dia**, **com ou sem** o `FoodStub` (medi também no `main`: é igual; o estoque provisório só esconde isso dando comida de graça). No dia 1 do `main`: A parou os 5 locais, B parou 3 de 6 e C 2 de 3; no dia 5 quase tudo parou. A conta do local nasce com 200 (tipo `site`, [HIP]) e a folha é 2 por hora por trabalhador ([HIP]) para 4 a 12 trabalhadores por local (46 em A): **o dinheiro acaba em menos de um dia**, e o local só ganha dinheiro vendendo o que produz, o que ele deixa de produzir quando para (círculo sem partida).
2. **A comida do mercado de A acaba no dia 2** (50 pão e 92 grão para 60 NPCs) e nada a repõe, porque os locais de A pararam. Os NPCs de A morrem **com dinheiro no bolso** (1.756 moedas somadas no dia 5): é falta de oferta.
3. **Em B o mercado guarda 80 pães do dia 6 ao 30 e os 44 NPCs morrem mesmo assim**: sem salário o dinheiro deles acaba (dia 5: 20 dos 44 com menos de 5 moedas; dia 7: 37). É falta de renda. Em C o dinheiro dos NPCs acaba no dia 2 (12 dos 28).
4. Isso confirma o que o `STATUS-A` já dizia: o estoque inicial do mercado da C (200 pão e 10 grão) e o resto da economia **não sustentam** o povo sozinhos. O que falta é a **calibração de partida** da cadeia de produção (saldo inicial dos locais, salário por hora, estoque inicial), que o roadmap põe nas LW-103/LW-104 e LW-109 a LW-113.

## 4. OPÇÕES (todas mexem em valor [HIP] de jogo: **é decisão sua**; não decidi nada)
- **A (minha recomendação): manter o `FoodStub` e adiar a LW-094** até a economia sustentar a comida. Custo: a marca `TEMP-LW-065` continua no código; a LW-114 (`check_temp`) só passa depois. Vantagem: nada muda no jogo, e o ramo `8c47b4c` já tem a remoção pronta (14 arquivos, ~430 linhas apagadas) para quando a economia aguentar. Eu proporia uma **tarefa de calibração de partida** antes da LW-094, com você decidindo os números.
- **B: ajustar só dados de partida** (sem código): subir o saldo inicial do tipo `site` (`owner_kinds.json`) e/ou baixar `wage_per_hour`, e subir o estoque inicial de comida dos mercados de A e C (`markets.json`). Os números são [HIP]; não os escolhi. Posso **medir** candidatos que você indicar (só em memória, sem gravar dado) e dizer quantos dias o povo aguenta.
- **C: reduzir a folha por regra** (por exemplo, o local só paga quando tem dinheiro e os trabalhadores trabalham, ou o mercado "compra a produção" antes do salário): é **mudança de contrato da economia** (seções 6 e 7 do `economy.md`), então precisa de decisão e de tarefa de contrato.
- **D (não recomendo): o `FoodStub` vira rede de segurança permanente** só quando o mercado não tem comida: é "comida mágica", que o `economy.md` (seção 14, LW-094) proíbe.
- **Se você escolher A:** nada mais a fazer na LW-094 agora; o ramo fica guardado. **Se escolher B ou C:** me diga os números ou autorize a tarefa de contrato.

## 5. O QUE FIZ NO CÓDIGO (no ramo `lw-094a-fim-do-foodstub-codigo`, só guardado)
Apaguei `food_stub.gd` e `food_stub_loader.gd` (e os `.uid`) e `data/food_stub.json`; tirei `peek_food_stock`, `request_set_food_stock`, `CODE_FOOD_NOT_CONFIGURED`, a chave `food_stock` do save do `npc` (serialize, validate, resumo, carga) e a ligação no `NpcSetup`; o `NpcPersistence` perdeu o campo `_definitions` que ficou sem uso. **Mantive** `Definitions.food` e `has_food(settlement)` como interface. Comentários e o README do `npc` atualizados. A busca por `TEMP-LW-065` em `src/`, `data/`, `tools/` e `scenes/` ficou **vazia**; em `tests/` ainda tem 6 arquivos (a parte 2 da LW-094, parada). **Não rodei o `check_all` neste ramo** (sabidamente vermelho: os testes citam o que apaguei); **NÃO EXECUTADO** por isso.

## 6. DECISÃO QUE DEPENDE DE ARTHUR
Escolher A, B, C ou outra. **Recomendo A** e, em paralelo, uma tarefa de calibração de partida. Enquanto você não decidir, sigo para o item 3 do v13 (**LW-105**), que não depende disto.

- **Git:** `main` = `69bbbb4` (não mudou); `lw-094a-fim-do-foodstub-codigo` = `8c47b4c` (enviado, não verde, não vai ao `main`). `lw-094b` **não criado** (a parte de testes não foi feita).

# RELATÓRIO — Bloco A v12 + v12c + v13 (PARTE 1: itens 1 a 3 FECHADOS; entrada no `main` FEITA)     Status: PRONTA PARA REVISÃO (esta parte); a LW-094 vem a seguir

## ITEM 1 — JUNÇÃO `lw-096m-junta-com-o-main` (4116294, enviada, aceita por Arthur). Nada a acrescentar.

## ITEM 2 — CUSTÓDIA DO EMISSOR MORTO, OPÇÃO B (`lw-096n-custodia-do-emissor-morto`, enviada)
- Contrato que vence com o emissor morto: a custódia vai para a conta do **mercado do povoado do contrato** (`labor`: povoado do local de trabalho, de produção ou posto; `delivery`: povoado do destino, que é o mercado ou um local de produção). Só inteiros, só pelo `Ledger` (motivo `contract_refund`), sem queimar, sem evento nem motivo novo. Destino que a economia não liga a um povoado (um NPC) ou mercado fechado: a custódia **continua retida** [LIM]. `validate()` ficou mais rígido (só aceita custódia retida de emissor morto quando não há mercado para recebê-la; testado com save adulterado).
- Novo `ContractRefundMarket` (só consulta); `ContractBook` ganhou o 6º parâmetro opcional (`market_book`). 8 testes novos (`test_contract_dead_issuer_custody.gd`). `docs/modules/economy.md`: só a frase e o [LIM].
- **Troquei SÓ o teste que sua autorização cobre** (`test_contract_expiry.gd`: `test_a_dead_issuer_gets_nothing_back_and_the_reward_stays_in_the_contract_account` → `test_a_dead_issuer_custody_goes_to_the_market_of_the_contract_settlement`; mesmo cenário, mesma conservação e `validate()`; primeira asserção `["expired", 0, 1]`; asserção nova do saldo do mercado, antes + 25). Nenhum outro teste existente mudou.
- **Item 3 do v12c (R26-I1):** `test_service_post_data.gd` — o teste do arquivo ausente agora usa uma **pasta temporária SEM `service_posts.json`** (`DirAccess.create_temp`; copia os `.json` reais menos o de postos, carrega `PostLoader` e `EconomySetup` nela e limpa os arquivos). **Não criei `service_posts.json`.** Cria a pasta no temporário do sistema, por decisão sua.

## ITEM 3 (v12) — ENTRADA NO `main` DO CONJUNTO 096h A 096n: **FEITA** (14:05, avanço simples `4db060f..69bbbb4`, sem tag, sem `--force`, nenhum ramo apagado)
Condições (a) a (g), uma por uma:
- (a) `tools/check_all` **VERDE, EXIT 0**, no commit final `69bbbb4`: **179 scripts, 1.512 testes, 1.512 aprovados, 298.640 asserts**, zero avisos do GDScript.
- (b) Os 9 valores do oráculo: `tests/integration/test_npc_split_oracle.gd` é **idêntico** ao do `main` (`git diff origin/main` = 0 linhas) e passa. `tools/run_sim --days 30 --seed 1`: hash `732907967efdba5f718687a0bbafbfe102ac51cabc9d15a7f0119a9e64ebc4d7`, igual ao de sempre (o `run_sim` não registra os módulos de jogo: "Módulos: 0"; problemas de validação 0).
- (c) Conflitos: **só de documento** (o B0 com o `main` `4db060f` entrou sem conflito de texto; o de `src/sim/economy/README.md` da junção 096m foi resolvido mantendo os dois lados).
- (d) Jogo real de 30 dias (`start_default_game` + `run_days(30)`, só `--headless`): **132 vivos antes e depois, 0 mortes, 0 `ContractOffered` (0 `ContractCompleted`, 0 `ContractFailed`)**, conservação do dinheiro **e** dos bens `true`, `validate()` com **0** problemas (economia 0, npc 0, world 0). Livro-razão do mês: `salary=4400`, `trade=15607`, `game_start=0` (o `mint` inicial entra antes do primeiro dia).
- (e) Avanço simples sobre `origin/main` = `4db060f` (conferido por `git fetch` e `merge-base --is-ancestor` antes do push). (f) Sem tag. (g) **Uma** linha de status em `docs/ROADMAP_STATUS.md` ("…no `main` por autorização antecipada de Arthur (Bloco A v12), aguardando auditoria"), sem mudar contagem nem porcentagem.
- **Dado novo que a medição do item 3 trouxe (importa para a LW-094):** no dia 30, com o `FoodStub` ainda ligado, a comida (pão + grão) nos mercados é **A = 0, B = 0, C = 38**. Ou seja, A e B esgotam o mercado de comida e o jogo só segue vivo porque o `FoodStub` cobre o resto. A LW-094 vai medir exatamente isso.

## PROBLEMAS DESTA PARTE (nada omitido)
1. **O primeiro `check_all` final travou 3 horas** (10:45 a 13:51) num Godot `--headless --debug` parado lendo o teclado (`stdin`) no teste de avisos do GDScript (que cria de propósito um script com aviso); o `check_all` que eu tinha ligado herdou um `stdin` aberto. Matei **só** os processos meus que travaram, sem tocar em arquivo. Daí em diante rodo `tools/check_all < /dev/null`. Nenhuma janela abriu: tudo `--headless`.
2. **Um segundo `check_all` saiu VERMELHO por ambiente** (1.259 de 1.466 testes; erro "Could not find type CultureService/ProvinceLoader"): o cache de classes do Godot (`.godot/`, fora do Git) estava velho depois da junção com o `main`. Rodei `godot --headless --path . --import` (AGENTS 4.3) e repeti o `check_all` inteiro: **VERDE** (acima). Guardei o log vermelho no scratchpad. Nenhum arquivo do projeto mudou por causa disso.
3. Links desatualizados que **deixei como estão** (só a frase e o [LIM], como o v12 mandou): `src/sim/economy/README.md:54` e `docs/events.md:25` ainda descrevem a custódia retida do emissor morto. Sugiro uma linha de documento depois.
4. A mutação M9 (conferência de mercado aberto) é equivalente: o mercado nunca fecha pela API pública; fica só como defesa.

## O QUE ARTHUR CONFERE EM CASA
Nada visual nesta parte (tudo `--headless`). Se quiser: abrir o jogo, deixar rodar um mês e conferir que ninguém morre de fome; o teste que fiz foi sem janela.

- **Git:** `main` = `69bbbb4` (por autorização antecipada, aguardando sua auditoria); ramo `lw-096n-custodia-do-emissor-morto` = `69bbbb4`. Próximo: LW-094 (só o `FoodStub`), depois LW-105 se a 094 parar.

# RELATÓRIO — Bloco A v11 (consertos das revisões da B)     Status: PRONTA PARA REVISÃO

## 1. RESUMO
Fiz os seis itens do v11 em cinco ramos empilhados a partir de `origin/main` (`885615c`), todos enviados, **nada no `main`**, sem tag, sem `--force` e sem apagar ramo. Cada parte tem `check_all` VERDE, `run_sim` e os 9 valores do oráculo IGUAIS (nenhum hash mudou). **Nenhum teste existente foi alterado, exceto o que você autorizou no item 6.** Terminei às 07:52, bem antes das 13:00. A LW-094 e a retirada do `IncomeStub` NÃO foram iniciadas (item 7).

## 2. RAMOS (empilhados; arquivos e linhas contam código, teste e dados, sem docs, README e `.uid`)
| Item | Ramo / commit | O que é | Arquivos / linhas |
|---|---|---|---|
| 1 (R13-I1, R14-I1) | `lw-096h-ids-sem-gasto` `0c8e73a` | `request_post_contract` valida ANTES de pedir o ID (`ContractBook.check_post`); teste NOVO do contador de IDs | 3 / +103 −13 |
| 2 (R18-I1) | `lw-096i-empregado-pelo-work-place` `7e39b80` | empregado = quem tem `work_place_id`; local que a economia não conhece não faz o NPC contar como desempregado | 2 / +118 −4 |
| 3 e 4 (R15-I1, R8-M1, R8-M2) | `lw-096j-resumo-dos-postos-e-folha` `00481f1` | frase da custódia no `economy.md`; `service_posts` no `debug_summary`; folha tudo ou nada | 3 / +111 −3 |
| 6 (R6-I1 completo) | `lw-096k-sinalizador-da-comida` `542220b` | o runner decide pelo resultado da conclusão; sinalizador `_food_from_inventory` removido; teste trocado (autorizado) | 4 / +14 −16 |
| 5 (PostLoader) | `lw-096l-post-loader` `e6bc3ec` | `PostLoader` e ligação no `EconomySetup`; sem nenhum dado novo | 3 / +210 −1 |

## 3. DECISÕES E COMO CUMPRI CADA ITEM
- **Item 1.** Separei a validação do post: `check_post` (mesmas falhas, mesma ordem) vem antes de `_ids.next_id()`. Você pediu "acrescente ao teste das recusas" e também "teste NOVO; nenhum teste existente alterado": fiz um teste NOVO (`test_contract_post_ids.gd`) com as mesmas recusas do teste da porta, comparando `ids.serialize()` antes e depois de cada uma, e mostrando que um post que dá certo gasta exatamente UM ID. O teste da porta ficou como estava.
- **Item 2.** `NpcEmployment._current_employment`: com `work_place_id` preenchido o NPC é empregado; se a economia o lista, a utilidade é a do local, senão vale 0 (e a histerese vale). Testes novos incluem o caso do posto sem `service_posts.json` (nenhum posto nos dados): o guarda de local desconhecido NÃO pega a vaga de 16 (abaixo da histerese de 20), o desempregado de verdade pega, e o artesão do mesmo local desconhecido troca quando o bônus de ofício leva o ganho acima de 20. **Os 11 testes de `test_npc_vacancy.gd` continuaram passando sem alteração** (nenhum quebrou, então não precisei parar).
- **Item 3.** A frase do `economy.md` (seção 8) agora diz o que o código faz (custódia volta ao emissor vivo; emissor morto: fica na conta fechada, [LIM]). O código não mudou. A pergunta de design está na seção 9.
- **Item 4 (R8-M2).** O `debug_summary()` mostra `service_posts`. **A chave só aparece quando há postos**, porque `test_economy_debug_and_kinds.gd` compara o resumo inteiro em 3 pontos (sem postos) e nenhum teste existente pode mudar. Se você quiser a chave SEMPRE presente (mais regular para o painel), preciso da sua autorização para trocar essas 3 linhas (39, 43 e 50 do arquivo). **R8-M1:** em vez de só testar o erro, fiz o menor conserto real: `WagePayer.pay` confere o saldo da folha inteira e cada transferência antes de mover a primeira, e `can_pay` já recusa o que o `Ledger` recusaria; teste novo com um trabalhador no teto de saldo (ninguém recebe, o posto para por `NO_FUNDS`, sem erro no log).
- **Item 6.** O runner guarda `Completion.consumed_from_inventory` e nem chama o gancho do `FoodStub` nesse caso; o `ConditionProvider` ficou sem estado. **Troquei só** `test_the_food_stub_only_consumes_when_the_food_did_not_come_from_the_inventory` (`test_npc_trade.gd`), por uma versão que passa pelo runner; nenhum outro teste mudou; hashes iguais.
- **Item 5.** `PostLoader` valida campos, faixas, texto em branco e um posto por local, com arquivo, item e campo nas mensagens. **O arquivo é opcional** (sem ele não há posto; o jogo e o `data/` ficaram como estavam; não criei `service_posts.json`). O `EconomySetup` leva os postos às definições e recusa o local que tem posto e local de produção.

## 4. TESTES (`tools/check_all`, resultados reais; todos EXIT 0, zero avisos)
| Ponta | Commit | Scripts | Testes | Asserts |
|---|---|---|---|---|
| base do `main` | `885615c` | 162 | 1.391 | 294.336 |
| item 1 | `0c8e73a` | 163 | 1.393 | 294.366 |
| item 2 | `7e39b80` | 164 | 1.396 | 294.389 |
| itens 3 e 4 | `00481f1` | 165 | 1.400 | 294.423 |
| item 6 | `542220b` | 165 | 1.400 | 294.427 |
| item 5 | `e6bc3ec` | 166 | 1.405 | 294.520 |
**Mutações** (todas pegas): item 1 (ID antes da validação; sem checagem de saldo), item 2 (regra antiga; local vazio contado; sem histerese), itens 3 e 4 (5 mutantes na folha e no resumo; a mutação "chave sempre presente" quebra o teste existente, o que confirma a decisão da chave condicional), item 6 (gancho sempre, nunca, sinalizador não ligado) e item 5 (6 mutantes do carregador e da ligação).

## 5. VALORES DE REFERÊNCIA
Nenhum mudou. `run_sim --days 30 --seed 1`: `732907967efdba5f718687a0bbafbfe102ac51cabc9d15a7f0119a9e64ebc4d7`, igual em todas as pontas. Os 9 valores do oráculo, conferidos no arquivo em cada ponta, são os de `885615c` (`8670b52b8ff6`, `b62628f049b0`, `1251aaf06e2d`, `6889619788b5`, `a8a97e95f464`, `781066cec584`, `ed884fc6fb21`, `f11a33ea9ab0`, `76a65b9cfc8a`).

## 6. PROBLEMAS
Nenhum `check_all` ficou vermelho nesta rodada. Dois ajustes meus no caminho (nos meus testes novos, antes do commit): o teste do item 4 mintava o saldo no teto do `Ledger` pelo motivo `game_start`, que já tinha 1.000 criados e estourava o contador, e passou a usar o motivo `trade`; o teste do item 6 usava `advance(NPC, 20)` duas vezes quando o segundo argumento é o MINUTO (corrigi para 40).

## 7. RISCOS
Todos estes ramos estão só no GitHub e empilhados em `885615c`; o `main` pode andar (a C junta a LW-097), então cada um precisará de junção quando você mandar levar ao `main`. A troca do teste do item 6 é a única mudança num teste existente.

## 8. COMO TRATEI O ITEM 7 (ratificação das listas)
Registrei: a "Preparação da manhã" (a) e (c) do `STATUS-A.md` (abaixo) está ratificada com as premissas de menor dano e as duas recomendações (comida dos mundos de teste sem economia vem da economia real e dos locais de produção da C; `has_food(settlement)` fica como interface). Os valores novos do oráculo ficam para você aprovar depois que eu os medir. **Isto não inicia a LW-094 nem o `IncomeStub`.**

## 9. PERGUNTA DE DESIGN PARA VOCÊ (item 3): para onde vai a custódia de um contrato cujo emissor morreu?
**O problema.** O contrato retém a recompensa numa conta de custódia. Se o prazo vence ou o contrato falha e o emissor já morreu, a conta dele está fechada e o `Ledger` não aceita transferência para dono fechado. Hoje o dinheiro **fica na conta do contrato para sempre** (continua contado no teste de ouro, mas parado). O Q14 prometia que a custódia "nunca fica retida".
**Opções:**
- **A. Continua retida (como está).** Simples e sem regra nova; o dinheiro some da circulação para sempre. Fraqueza: quebra o Q14 e, com muitos contratos de emissores mortos, drena a economia aos poucos.
- **B. Vai para o mercado do povoado do contrato** (`labor`: o povoado do local de trabalho; `delivery`: o povoado do destino, se o destino for um mercado ou tiver povoado conhecido pela economia). O dinheiro volta à circulação, sem sumidouro. Custo: uma regra de "qual povoado" (a economia sabe pelo local de produção ou posto e pelos mercados) e um caso de reserva para quando o povoado não é conhecido (fica retida como em A); uns 40 a 60 linhas e testes.
- **C. Vai ao aceitante**, se já há aceitante (premia quem assumiu o risco), e ao mercado como em B se não há. Fraqueza: incentivo ruim (alguém "aceitar" contrato só para herdar o dinheiro do emissor moribundo) e mexe com a regra "um trabalho, um pagamento".
- **D. Destruir (`burn`).** Fere a decisão "nenhum `burn` na Fase 3" e a conservação passaria a depender de um sumidouro.
**Minha recomendação: B**, com a reserva A para o povoado desconhecido, e na Fase 4 trocar o destino para o tesouro da polity (que a Fase 4 já prevê para a folha). Como contrato com emissor morto é raro (só jogador e facções postam contratos nas fases seguintes), A é aceitável por ora; se preferir não gastar código agora, deixe A e eu só mantenho a frase corrigida do `economy.md`.

## 10. PENDÊNCIAS (suas)
1. Responder a pergunta da seção 9 (A, B, C ou D).
2. Dizer se quer a chave `service_posts` SEMPRE presente no `debug_summary` (exige autorizar a troca de 3 linhas de `test_economy_debug_and_kinds.gd`).
3. Aprovar levar estes cinco ramos ao `main` quando quiser (a junção depende de onde a C estiver).
4. Continua em pé a espera da LW-097 da C no `main` (a Fase B dela segue bloqueada por 2 testes da economia da A, à espera do seu "autorizo").

## ACOMPANHAMENTO
- **Avanço:** o v11 está completo; marco 2 no `main` (`885615c`) mais cinco ramos de conserto só no GitHub.
- **Próxima tarefa recomendada:** LW-094 e o `IncomeStub`, só com novo bloco seu, depois da LW-097 no `main`. Não iniciadas.
- **Git:** ramos novos `lw-096h` a `lw-096l` enviados; `main` intocado (`885615c`); sem tag, sem `--force`, rebase, reset nem ramo apagado; commit e push só dos ramos e do `status-a`.

---
# RELATÓRIO ANTERIOR (bloco A v10) E O QUE SEGURA A LW-094, mantidos abaixo

# RELATÓRIO — LW-095 (só código), LW-096 (partes a a e), LW-096a, 093k e as duas Fases B     Status: PRONTA PARA REVISÃO

## 1. RESUMO
Cumpri o bloco v10 na ordem. (1) A LW-093 (partes 1 a 7) entrou no `main` por avanço simples, com `check_all` verde, os 9 valores do oráculo e o `run_sim` iguais e sem tag. (2) A 093k ajustou a revisão R6. (3) A LW-095 ficou completa **só em código** (salário dos locais, postos de serviço, consulta dos postos, o `npc` aliviando `income`), sem dado novo e com o `IncomeStub` no lugar. (4) A LW-096 ficou completa em cinco partes (livro de contratos com custódia, porta, conclusão, prazo, vagas) e a LW-096a fez o NPC aceitar vaga pela utilidade, com histerese. (5) A linha inteira (093k, 095a a d, 096a a e e 096a) entrou no `main` por autorização antecipada, também por avanço simples, sem tag e sem mudar nenhuma constante. **O `main` está em `885615c`.** A LW-094, o `service_posts.json` e o resto da LW-095 não foram tocados.

## Declaração de leitura
Li: `AGENTS.md` v0.4; os blocos A v8 e v10; `economy.md` seções 6, 8 e 16; `npc.md` 14.2, 14.4 e 14.9; `events.md`; a revisão R6 (no `STATUS-B.md`); as ramificações da C (097a a 097e, só leitura, para a preparação da manhã). **Decisões usadas:** DEC-151, 152, 164, 165, 169, 174, 234 (PROPOSTA, já registrada no `main`), 235 e 236 (APROVADAS).

## 2. ARQUIVOS (ramos empilhados, todos enviados; linhas e arquivos contam código, teste e dados; sem docs, README e `.uid`)
| Parte | Ramo / commit | O que é | Arquivos / linhas |
|---|---|---|---|
| LW-095a | `lw-095a-salario-dos-locais` `df01eb1` | `WagePayer`, passo 3 da hora, `NO_FUNDS`, `WagesPaid` | 8 / 284 |
| LW-095b | `lw-095b-postos-de-servico` `ea5ed94` | `ServicePostBook`, `PostDef`, folha pela conta do mercado antes dos locais, save | 8 / 452 (no limite) |
| LW-095c | `lw-095c-consulta-dos-postos` `9d1b0f6` | `peek_post`, `peek_post_at`, `peek_posts_of` | 4 / 172 |
| LW-095d | `lw-095d-npc-ouve-salario` `2c8525b` | `WageIncome` (o `npc` ouve `WagesPaid`) | 5 / 218 |
| LW-096 a | `lw-096a-contratos-nucleo` `ebd0a06` | `ContractBook`: postar com custódia, aceitar, save | 5 / 426 |
| 093k | `lw-093k-ajustes-da-r6` `8ae5bb3` | R6-I1 (validar a necessidade antes da economia), R6-M1, R6-I2 como [LIM], R6-M2 a M5 no backlog | 5 / 135 |
| LW-096 b | `lw-096b-porta-dos-contratos` `bfbc9a3` | `request_post_contract`, `request_accept_contract`, `peek_contract(s)`, `ContractOffered` | 5 / 315 |
| LW-096 c | `lw-096c-conclusao-dos-contratos` `bc733af` | `request_work_shift`, `request_deliver_contract`, `ContractCompleted` | 7 / 344 |
| LW-096 d | `lw-096d-prazo-dos-contratos` `45bb31b` | prazo, devolução da custódia, `ContractFailed` | 5 / 205 |
| LW-096 e | `lw-096e-vagas` `1ea1b22` | `EconomyVacancies`: vagas postadas pela economia e aceitas por NPC | 6 / 395 |
| LW-096a | `lw-096f-npc-aceita-vaga` `d544daa` | `NpcEmployment`: o NPC aceita vaga pela utilidade, com histerese | 3 / 450 (no limite) |
| Fase B (LW-093) | `lw-093j-pensador-compra` `f2bcb4c` → `main` | junção com o `main` (conflito só em `docs/backlog.md`), linha de status | docs |
| Fase B (resto do marco 2) | `lw-096g-junta-com-o-main` `885615c` → `main` | junção (conflito só em `docs/backlog.md` e `docs/events.md`), linha de status | docs |
Ramos locais vazios ou obsoletos que ficam (não posso apagar): `lw-093-npcs-no-mercado`, `lw-093c-dinheiro-inicial-e-consumo`.

## 3. ARQUIVOS MODIFICADOS QUE JÁ EXISTIAM (só o que você autorizou)
- `tests/unit/test_economy_production_api.gd`: **só as linhas 181 e 182**, pela sua autorização (ratificada no v10, item 2a): a mensagem passou a listar `NO_FUNDS` e o motivo inválido de exemplo passou a `NO_SPACE`.
- `src/sim/economy/events/wages_paid.gd` → `src/sim/economy/api/wages_paid.gd` (0 linhas alteradas; ratificado no v10, item 2c).
- Nenhum outro teste existente foi alterado.

## 4. DECISÕES TÉCNICAS
- **Dados:** nenhum dado novo (sem `service_posts.json`); as definições dos postos só existem montadas à mão nos testes (`EconomyDefinitions.service_posts`). As constantes [HIP] ficaram NOMEADAS no código: `WageIncome.RELIEF_PER_COIN` (1) e, em `NpcEmployment`, `PAID_HOURS_PER_DAY` (8), `COMMUTES_PER_DAY` (2), `OCCUPATION_MATCH_BONUS` (10) e `HYSTERESIS` (20).
- **Eventos citados pelo `npc`** (`WagesPaid`, `ContractOffered`, `ContractCompleted`, `ContractFailed`) moram em `economy/api/`, para cumprir a regra E sem leitura por nome.
- **Vagas (proposta de implementação, sem decisão do GDD):** no máximo UMA vaga aberta por local de trabalho, conferência a cada hora, vaga que deixou de fazer falta falha em silêncio, e aceitar tira o emprego anterior (a vaga que isso abre nasce na hora seguinte).
- **Prazo:** vence na hora cheia seguinte ao prazo (até 59 minutos de atraso); **[LIM]** emissor morto não recebe a custódia de volta e ela fica na conta do contrato (o dinheiro continua contado; o `validate()` aceita).
- **Utilidade da vaga:** salário por hora × 8 horas, menos a caminhada de casa ao trabalho, mais o bônus de ofício; o desempregado aceita se positiva; o empregado só troca acima da histerese e se a vaga for positiva; empate pelo menor ID; nunca sorteia.
- **DESVIO da 093k (R6-I1), a seu critério:** fiz a parte atômica (o runner pergunta ao provedor a necessidade ANTES de chamar a economia: `completion_need_id`), com o teste novo que você pediu. **Não removi o sinalizador `_food_from_inventory`** porque isso exige trocar `test_the_food_stub_only_consumes_when_the_food_did_not_come_from_the_inventory` (`test_npc_trade.gd:179`), que chama o provedor direto e depende dele, e nenhum teste existente está autorizado. Além disso o vazamento que a R6 descreveu não acontece (o sinalizador é reescrito a cada `complete_action`); o teste novo prova que ele não fica ligado. **Peço autorização para trocar esse teste e tirar o sinalizador** (está no `docs/backlog.md`).
- **Propostas de entrada para `DECISIONS.md` (numeração provisória DEC-237 a DEC-241; NÃO editei o `DECISIONS.md`):** (237) as vagas: uma aberta por local, conferência por hora, silêncio ao falhar; (238) a utilidade da vaga e as 4 constantes [HIP]; (239) `income` alivia 1 ponto por moeda de salário [HIP]; (240) o prazo de contrato e a limitação do emissor morto; (241) as classes de evento que o `npc` cita ficam em `economy/api/`.

## 5. TESTES EXECUTADOS (`tools/check_all`, resultados reais; todos EXIT 0, zero avisos de compilação)
| Ponta | Commit | Scripts | Testes | Asserts |
|---|---|---|---|---|
| 093 (Fase B 1, no `main`) | `f2bcb4c` | 151 | 1.322 | 293.484 |
| 095a | `df01eb1` | 152 | 1.329 | 293.561 |
| 095b | `ea5ed94` | 153 | 1.336 | 293.631 |
| 095c | `9d1b0f6` | 154 | 1.339 | 293.660 |
| 095d | `2c8525b` | 155 | 1.345 | 293.708 |
| 096 a | `ebd0a06` | 156 | 1.351 | 293.857 |
| 093k | `8ae5bb3` | 157 | 1.354 | 293.889 |
| 096 b | `bfbc9a3` | 158 | 1.360 | 293.974 |
| 096 c | `bc733af` | 159 | 1.366 | 294.067 |
| 096 d | `45bb31b` | 160 | 1.371 | 294.128 |
| 096 e | `1ea1b22` | 161 | 1.380 | 294.214 |
| 096a (NPC) | `d544daa` | 162 | 1.391 | 294.336 |
| Fase B 2 (no `main`) | `885615c` | 162 | 1.391 | 294.336 |
**Vermelhos que corrigi (3, todos meus, nenhum teste existente tocado):** (1) parte 7 da LW-093 (já no `main`): aviso de divisão inteira no meu teste novo; (2) 095d: pus `WageIncome` na pasta `income/`, onde `test_income_stub.gd` exige a marca `TEMP` em todo arquivo; movi para `needs/`; (3) 096 a: o `check_content_ids` reserva `KIND_` para tipos de dono; renomeei as constantes dos tipos de contrato (`LABOR`, `DELIVERY`, `VACANCY`). **Mutações:** em cada parte rodei de 5 a 14 mutantes e todos foram pegos, depois de acrescentar testes para os que sobreviveram (hysteresis, prazo da entrega, vaga que se preenche); os que sobraram são equivalentes (guarda duplicada de `buy_value`, a checagem de mercado ausente nos postos, a escala `PERMILLE_SCALE`).

## 6. RESULTADOS: valores de referência
**Nenhuma constante mudou.** Os 9 valores do oráculo, conferidos no arquivo e sem diferença para o `main`: `intents` `8670b52b8ff6`, `alarm` `b62628f049b0`, `resumed` `1251aaf06e2d`, `switches` `6889619788b5`, `talk` `a8a97e95f464`, `save` `781066cec584`, `demote` `ed884fc6fb21`, `starved` `f11a33ea9ab0`, `real_game` `76a65b9cfc8a`. Os prints dos soaks (7 dias `d7266f48286e`, 300 NPCs `f31f5186abf5`) também. **`run_sim --days 30 --seed 1`: `732907967efdba5f718687a0bbafbfe102ac51cabc9d15a7f0119a9e64ebc4d7`, igual em todas as pontas.** O jogo real não tem local de produção nem posto nos dados, então a folha, os contratos e as vagas nunca rodam nele e nada muda no estado salvo.

## 7. PROBLEMAS E OCORRÊNCIAS
- **Deslize meu, já avisado:** usei `git branch -D` num ramo local vazio que eu tinha criado segundos antes (sem commit, nunca enviado). Não repeti.
- A parte 095b ficou com 452 linhas e a 096a com 450 (no limite da DEC-126); nenhuma passou de 12 arquivos.
- O ID de contrato é consumido mesmo quando o `request_post_contract` falha (os IDs não se reutilizam).
- **Limitações [LIM]:** `sell` sem valor no pensador até a LW-098; `can_buy_food` e `has_goods` sem chamador até lá; emissor morto não recebe a custódia de volta; vaga só nasce da economia (sem nascimento); `income` ainda tem o `IncomeStub` em paralelo (a folha só roda com locais de produção).

## 8. RISCOS
- Tudo isso é testado com definições montadas à mão; o primeiro uso no jogo real será quando a C entregar os dados (LW-097). O equilíbrio de dinheiro (a folha de 28, 16 e 16 moedas por hora dos postos contra os 3.000 iniciais do mercado, [HIP]) só se mede lá (R3.3, calibração na LW-112).
- A economia depende de `economy/api/` com cinco classes de evento citadas pelo `npc`; qualquer renome quebra na compilação (bom), mas exige mexer em dois módulos.
- `npc_module.gd` tem agora 647 linhas (já passava das 300 antes); proponho dividir quando você mandar.

## 9. PENDÊNCIAS (suas)
1. **Autorizar a lista de testes da LW-094 e do `IncomeStub`** (preparada abaixo) quando a LW-097 estiver no `main`.
2. Autorizar a troca do teste `test_npc_trade.gd:179` e a retirada do sinalizador `_food_from_inventory` (R6-I1 completo).
3. Registrar as DEC-237 a DEC-241 propostas no item 4, se concordar.
4. A C junta a LW-097 depois; os valores do oráculo e do soak serão os dela (não toquei).

# AUTORIZAÇÃO DA LISTA DA LW-094 (12/11/2026, 07:00) E O QUE A SEGURA
Arthur escreveu: "Autorizo a lista da LW-094" (a lista do item 6(a) e 6(c) abaixo: 1 arquivo de teste apagado, 8 alterados e a troca dos 9 valores do oráculo e dos soaks pela causa "fim do FoodStub"; a do `IncomeStub` é a 6(c), a executar em seguida se ele mandar). **A LW-094 NÃO foi iniciada, e a razão é o pré-requisito dele, não falta de autorização:** a DEC-236 e o bloco v8 põem a LW-097 da C no `main` ANTES da LW-094, e o `main` segue em `885615c` sem ela (a Fase B da C está BLOQUEADA por 2 testes existentes da economia da A, à espera do "autorizo trocar os números desses 2 testes" dele, patch pronto no `STATUS-C.md`). **Razão técnica:** sem os locais de produção nos dados o jogo real e o soak de 7 dias ficam sem comida (medido: os 100 NPCs morrem em 6 dias sem o `FoodStub`), então a LW-094 não fecha `check_all` verde em cima do `main` de agora.
**Premissas que vou seguir (me avise se discordar):** (1) os mundos de teste sem economia passam a usar a economia real e os locais de produção da C; (2) `Definitions.food` e `has_food(settlement)` ficam como interface. **Começo no dia em que a LW-097 estiver no `main`**, em duas partes (código e dados; depois os testes da lista), cada uma com `check_all` verde e com os valores novos mostrados (antigo, novo e causa).

# PREPARAÇÃO DA MANHÃ (só relatório; NADA foi escrito em código, em dado ou em teste)
## (a) O que a LW-094 apagaria ou alteraria nos testes, com antes e depois
**Premissa de menor dano:** a LW-094 remove `FoodStub`, `FoodStubLoader`, `data/food_stub.json`, `peek_food_stock`, `request_set_food_stock`, a chave `food_stock` do save do `npc` e a ligação no `NpcSetup`, e **mantém** `Definitions.food` e `ActionConditionProvider.has_food(settlement)` como interface (provedor de teste, não stub). Assim os testes com `FakeFood` e `provider.food` (`test_decision_flow`, `test_critical_need`, `test_decision_trace`, `test_action_runner`, `test_npc_intents`, `test_npc_intent_completion_hook`, `test_action_equivalence`) **não mudam**. **Causa de hash: "fim do FoodStub"** (o bloco do `npc` perde `food_stock`, e os mundos de teste sem economia ficam sem comida), a ser medida no marco 3.
| Arquivo e linha | Antes | Depois |
|---|---|---|
| `tests/unit/test_food_stub.gd` (566 linhas, 19 testes) | testa o `FoodStub`, o carregador, a marca `TEMP-LW-065`, `peek_food_stock` e `request_set_food_stock` | **apagar o arquivo** |
| `tests/unit/test_npc_setup.gd:52-53` | `var food: FoodStub = definitions.food as FoodStub; assert_not_null(food, "O provedor de comida do jogo é o FoodStub (TEMP-LW-065).")` | `assert_null(definitions.food, ...)` (o jogo não tem estoque provisório) |
| `tests/unit/test_npc_setup.gd:112` | `assert_true(npc_data.has(FoodStub.SAVE_KEY), ...)` | `assert_false(npc_data.has("food_stock"), ...)` |
| `tests/unit/test_npc_setup.gd:146-150` | laço com `peek_food_stock` e a faixa do estoque | apagar o laço |
| `tests/integration/test_npc_split_oracle.gd:194` | `str([routine.result.ok, routine.action_id, rig.npc.peek_food_stock(SETTLEMENT).stock])` | `str([routine.result.ok, routine.action_id])` |
| `tests/integration/test_npc_split_oracle.gd:280` | `assert_true(live.npc.request_set_food_stock(SETTLEMENT, 0).ok)` | apagar a linha |
| `tests/integration/test_npc_split_oracle.gd:49-57` | os 9 valores atuais | os 9 valores novos (a medir; causa "fim do FoodStub") |
| `tests/integration/test_npc_bodies_view.gd:73-76` | cenário `deadly`: zera o estoque de cada povoado (`request_set_food_stock`) | **decisão sua:** sem estoque, todo mundo passa fome; o cenário não letal precisa de uma fonte de comida (economia montada à mão ou um provedor de teste) |
| `tests/integration/test_npc_s0_reevaluation.gd:122-124` | cenário `STARVING`: idem | mesma decisão |
| `tests/soak/npc_life/npc_life_check.gd:5,118-130,164` | `check_food` com `FoodStub.StockQuery` e os campos `food_min` e `food_zero_minutes` do relatório | apagar `check_food` e os dois campos; os prints do soak perdem "comida mínima" |
| `tests/soak/npc_life/test_npc_life_7d.gd:44-52,109-122` | `_tiny_food`, `_tiny_module(food)` e `test_the_checker_flags_a_food_stock_outside_its_range...` | apagar o teste e o ajudante |
| `tests/unit/test_income_stub.gd:368` | `wrong_mark["temp_mark"] = "TEMP-LW-065"` | outro texto de marca errada (por exemplo `TEMP-LW-999`), para a busca por `TEMP-LW-065` em `tests/` ficar vazia |
| Meus testes (comentários e mensagens): `test_npc_trade.gd:3,25,120,179`, `test_npc_trade_atomicity.gd:14`, `test_npc_buys_food.gd:45` | citam o `FoodStub` e `request_set_food_stock(..., 0)` | trocar o texto; remover a chamada de `test_npc_buys_food.gd:45` |
**Resumo:** 1 arquivo apagado, 8 arquivos alterados (uns 16 pontos), 1 troca dos 9 valores do oráculo. **O resultado muda os hashes dos soaks e do oráculo; o `run_sim` não muda.** A parte de código (apagar a classe, o dado e a ligação) e a de testes ficam em duas partes, cada uma abaixo de 450 linhas.
**Decisões que dependem de você:** (1) de onde vem a comida dos mundos de teste sem economia (cenários não letais de `test_npc_bodies_view` e `test_npc_s0_reevaluation`; o oráculo e os soaks); recomendo montar a economia real e os locais de produção da C nesses mundos, como o jogo real, e aceitar os valores novos; (2) se `has_food(settlement)` fica na interface (recomendo que sim).

## (b) Rascunho do `data/economy/service_posts.json` (6 linhas, locais da 097a e da população da 097d; `wage_per_hour` 2 [HIP], igual ao das receitas)
```
[
	{"id": "post_a_guard", "settlement_id": "test_settlement_a", "place_id": "a_work_06", "occupation_id": "guard", "workers_wanted": 8, "wage_per_hour": 2},
	{"id": "post_a_inn", "settlement_id": "test_settlement_a", "place_id": "a_work_07", "occupation_id": "innkeeper", "workers_wanted": 6, "wage_per_hour": 2},
	{"id": "post_b_guard", "settlement_id": "test_settlement_b", "place_id": "b_work_07", "occupation_id": "guard", "workers_wanted": 5, "wage_per_hour": 2},
	{"id": "post_b_inn", "settlement_id": "test_settlement_b", "place_id": "b_work_08", "occupation_id": "innkeeper", "workers_wanted": 3, "wage_per_hour": 2},
	{"id": "post_c_guard", "settlement_id": "test_settlement_c", "place_id": "c_work_04", "occupation_id": "guard", "workers_wanted": 5, "wage_per_hour": 2},
	{"id": "post_c_inn", "settlement_id": "test_settlement_c", "place_id": "c_work_05", "occupation_id": "innkeeper", "workers_wanted": 3, "wage_per_hour": 2}
]
```
Folha por hora: A 28, B 16, C 16 moedas (672, 384 e 384 por dia) contra o saldo inicial de 3.000 do mercado: **dura de 4 a 8 dias sem a venda de produto**; é o risco R3.3, e o número é [HIP] para a LW-112. **O que falta no código para esse arquivo existir:** `PostLoader` (esquema `service_posts`, um posto por local) e a ligação no `EconomySetup` (o conflito de local entre posto e local de produção); escrevi e desfiz esse trecho no v8 e o refaço em minutos quando você mandar. O `check_content_ids` e o `test_economy_distribution.gd` da C devem passar a ler a tabela.

## (c) Plano da remoção do `IncomeStub` (resto da LW-095; NÃO executado)
1. **Código a apagar:** `src/sim/npc/income/income_stub.gd` e `income_stub_loader.gd`, `data/income_stub.json`, `NpcSetup` (carregamento), `NpcModule.Definitions.income`, `NpcDecisionRuntime` e `ConditionProvider.extra_effects` (o gancho `ActionConditionProvider.extra_effects` pode ficar como interface). O `WageIncome` (já entregue) passa a ser a única fonte de alívio de `income`.
2. **Testes que mudam:** apagar `tests/unit/test_income_stub.gd` (412 linhas, 13 testes); `tests/unit/test_npc_setup.gd:59` (`assert_gt(definitions.income.peek_relief("farmer"), 0, ...)`: apagar a linha); `tests/unit/test_critical_need.gd:285-318` (o provedor de teste que repassa `IncomeStub.extra_effects`: trocar por um efeito extra montado à mão para o teste de efeito proporcional continuar provando a mesma coisa); `tests/integration/test_action_equivalence.gd:42` e `tests/soak/npc_bodies/npc_bodies_twin.gd:288` só mudam se o gancho `extra_effects` sair (comentário e espião).
3. **Causa de hash: "fim do IncomeStub"** (o `income` deixa de cair por trabalhar; só cai com `WagesPaid`, que só existe com locais de produção e postos nos dados). O oráculo e os soaks mudam de novo, **por causa diferente da do FoodStub**: proponho entregar as duas remoções no mesmo marco 3 ou em dois valores relatados separados, a seu critério.
4. **Ordem proposta:** LW-097 da C no `main`; `service_posts.json` e o `PostLoader`; LW-094; `IncomeStub`; o teste de ouro e o soak de 30 dias com a economia real (a morte por fome precisa ficar em zero: a comida sai do mercado, que o local de produção reabastece e a folha mantém o dinheiro dos NPCs).
5. **Critério de aceite:** busca por `TEMP-LW-065` e `TEMP-LW-066` vazia em `src/`, `data/`, `tests/`, `tools/` e `scenes/`; `check_all` verde; 30 dias com os 132 NPCs vivos.

## ACOMPANHAMENTO
- **Avanço:** marco 2 em código completo e no `main` (aguardando a sua auditoria); falta a LW-097 da C no `main`, depois LW-094 e o resto da LW-095 com a sua lista.
- **Próxima tarefa recomendada:** LW-094, só com a sua autorização escrita da lista acima. **Não iniciada.**
- **Git:** `main` em `885615c`; sem tag; nenhum `--force`, rebase, reset ou ramo apagado (a não ser o deslize já avisado); push no `main` só nos itens 1 e 5, por avanço simples.
