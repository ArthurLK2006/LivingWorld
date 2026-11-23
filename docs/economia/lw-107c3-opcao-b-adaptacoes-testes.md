# LW-107c3, opção B: a adaptação dos testes (37 testes em 18 scripts), sem enfraquecer asserções (23/11/2026)

**Status:** DOCUMENTO do PR RASCUNHO isolado `lw107c3-opcao-b` (NÃO integrar; o postador só é ativado com a autorização escrita de Arthur e depois da validação visual dele). Condição 4 de Arthur (23/11/2026): adaptar os testes afetados pela ativação sem enfraquecer asserções. O pacote de decisão (`lw-107c3-decisao-23-11.md`) mediu 36 falhas em 17 scripts; a suíte inteira do ramo achou mais 1, do #149 (`test_service_posts_own_market`, o mercado do povoado também paga o pão do postador), adaptada no commit seguinte: **37 testes em 18 scripts**. Todos passam; a contagem de `assert_` por arquivo só sobe (2 testes NOVOS) e, numa cópia com a tabela `[]`, os adaptados FALHAM (não são vazios).

Regra: nenhuma asserção removida nem afrouxada; só valor esperado novo (IDs, contagens, saldos com a custódia, motivos do livro-razão) e, em 2 testes de "quadro vazio", o mundo SEM postador explícito (asserções originais intactas) mais um teste NOVO no mundo com encomendas.
Causa comum: o mundo real agora posta 1 `bread_standing` (5 pães, recompensa 53, `open`) por mercado que pode pagá-lo: A e C na 1ª hora, B só depois de alguns dias; a custódia de 53 sai do caixa do mercado (`contract_escrow`) e fica no contrato (devolução `contract_refund` só no vencimento, 48 h). `POSTED_ESCROW` / `POSTED_REWARD` = 53; `_posted_bread(mercado)` acha o contrato do postador.

## Grupo 1: custódia de 53 no caixa do mercado (14 testes)
| Teste | Antes | Depois | Motivo |
|---|---|---|---|
| test_contract_dead_issuer_custody (6) | mercados `== markets_before`; B `before + REWARD` | `markets_before[i] - POSTED_ESCROW`; B `before - POSTED_ESCROW + REWARD` | cada mercado pagou o pão do postador na janela de 2 h; o resto igual (a custódia morta ainda vai só ao mercado do povoado do contrato) |
| test_contract_expiry::..dead_issuer_custody.. (1) | `market_before + REWARD` | `market_before - POSTED_ESCROW + REWARD` | idem |
| test_contract_cycle (2) | caixa B volta a `cash_b`; quadro `[expired]` | `cash_b - POSTED_ESCROW` (2 pontos); quadro `[expired, open]` | o pão do postador entra no B na 1ª hora e fica aberto |
| test_economy_caravan_trip::arrival_sells (1) | saldo B `funds - expected`; motivos `[game_start, trade]` | `funds - expected - POSTED_ESCROW`; `[contract_escrow, game_start, trade]` | A e B postam às 17:00, antes da chegada (minuto 1143) |
| test_economy_caravan_trip::full_or_broke (1) | caso "saldo do mercado": saldo 60; `fits`/`revenue` calculados na partida | saldo `60 + POSTED_ESCROW` (o B chega com 60, como antes) e `fits`/`revenue` calculados 1 minuto antes do ETA | com saldo 60 o B ficaria com 7 depois do pão e a venda parcial (8 de 20) viraria "sem saldo", igual ao caso 4: o cenário foi preservado |
| test_npc_merchant_food (1) | B `[15, 3000]` | `[15, 3000 - POSTED_ESCROW]` | nada chegou ao B; o saldo só caiu pelo pão do postador |
| test_service_posts (1) | `before - 2*WAGE*guardas` | `before - POSTED_ESCROW - 2*WAGE*guardas` | o mercado A também pagou o pão do postador |
| test_service_posts_own_market (1) | cada mercado paga SÓ a folha dos postos do povoado dele em 2 h: `before - after == 2 * folha` | `== 2 * folha + POSTED_ESCROW` (53) | o mercado também reteve 53 na custódia do pão do postador (a asserção continua exata, por mercado) |

## Grupo 2: IDs, contagens e linhas do quadro (19 testes)
Ver as linhas de cada script no diff; resumo:
| Teste | Antes | Depois | Motivo |
|---|---|---|---|
| test_bridge_contract_abandon (2) | quadro `[abandonos, open, carried]`; `rows[0]`; `rows[5]`,`rows[6]` | `[posted] +` o mesmo; `rows[1]`; `rows[6]`,`rows[7]` + asserção NOVA da linha 0 (aberto, de ninguém, 53) | o pão do postador (menor ID) está no quadro do A |
| test_bridge_player_contracts (3) | quadro vazio `[0, 60]` e `[contract_id]`; carregado `[...]`; `[first, second]` | teste ORIGINAL intacto em jogo SEM postador (`_restart_without_the_poster`) + teste NOVO do jogo real (`[posted]` e `[posted, contract_id]`); mais `posted` no fim da lista e `open` no fim dos estados; `[first, second, posted]` | quadro vazio é premissa do teste; o resto: o pão aberto do postador |
| test_contracts_view_model (4) | 6 linhas, disponíveis `[late_open, fresh_open]`, `owned` 6 zeros, vazio `[...,0,0,0]` | 7 linhas, disponíveis + `posted`, 7 zeros e `[BREAD,3]` no fim; vazio ORIGINAL em jogo sem postador + teste NOVO (1 linha, a do postador) | idem |
| test_contracts_view_model_abandon (2) | disponíveis `[fresh]`; `[LIMIT, 0, 0]` | `[posted, fresh]`; `[LIMIT, 0, 1]` + asserção NOVA (a linha é o pão do postador) | idem |
| test_contracts_tab (3) | OPEN `[late_open, fresh_open]`; células sem a 3ª linha; `[2, 4]` e `["", 2, 4]` | + `posted` (3ª linha: "Entregar 5 x Pão", 53, 1 d 23 h 20 min); `[3, 4]`; `["", 3, 4]` | idem |
| test_contract_vacancies (3) | `offers.size()` 2, 0, 0, `[1, SITE]`, 1 e `open` 1 | contagem por TIPO: vagas 2, 0, 0, `[1,[SITE]]`, 1; mais `3` pães do postador (`POSTED_BREADS`) e `open` `1 + 3` | `ContractOffered` também sai do postador (1 por mercado) |
| test_npc_employment_by_work_place (1) | `open` 1 | `1 + 3` | a vaga e os 3 pães |
| test_economy_production_api (1) | próximo ID 4 e 44 | 7 e 47 | +3 IDs dos 3 pães do postador |

## Grupo 3: dado, livro-razão e premissa "o jogo real não posta" (4 testes: 2 + 1 + 1)
| Teste | Antes | Depois | Motivo |
|---|---|---|---|
| test_contract_templates_data (2) | dado real = 0 modelos | dado real = `[bread_standing, flour_shortage]` nesta ordem (linhas completas); `ids` das definições; arquivo de exemplo (3 modelos) intacto | opção B |
| test_contract_voluntary_world V1 (1) | 0 entregas e quadros vazios em 1 dia | exatamente 2 entregas (5 pães, 53, `open`, sem aceitante, emissores A e C) e cada quadro mostra só o que o postador pôs nele (B vazio) | o dado real agora posta |
| test_npc_buys_food (1) | motivos `[game_start, salary, trade]` | `[contract_escrow, contract_refund, game_start, salary, trade]` | custódia do pão e devolução no vencimento (48 h) |
| test_contracts_tab (texto) | "Nenhum contrato agora: os mercados estão abastecidos" | "Nenhuma encomenda disponível agora." | causa que o jogo não sabe |

## Auditoria dos textos da aba de Contratos (`data/text/pt_br.json`; só chaves, sem layout/cor/tela)
| Chave | Texto | Veredito |
|---|---|---|
| ui.contracts.empty | "Nenhum contrato agora: os mercados estão abastecidos" | TROCADO por "Nenhuma encomenda disponível agora." (afirmava uma causa que o jogo não sabe; o quadro fica vazio também antes da 1ª hora cheia, depois de aceitar o único contrato, ou quando a regra (b) segura a postagem) |
| ui.contracts.expired_note | "Prazo encerrado, recompensa devolvida ao emissor" | MANTIDO neste PR; sugestão (NÃO aplicada, fora do pedido): "Prazo encerrado, a recompensa volta ao emissor", porque a tela mostra "Vencido" assim que `deadline <= now`, mas a economia só devolve na hora cheia seguinte (até 59 min), e o passado "devolvida" é inexato nessa janela; nenhum teste fixa a frase |
| ui.contracts.empty_mine | "Você ainda não aceitou nenhum contrato." | mantido: a lista "Meus contratos" também mostra os terminados, então vazia = nunca aceitou |
| ui.contracts.abandoned_note, confirm_text | "Sem multa, recompensa devolvida ao emissor" / "Você fica com os itens, nada é pago e ela se encerra." | mantidos: o abandono devolve a custódia na hora e não paga |
| ui.contracts.hint_accept, hint_deliver, capacity, section_*, state.*, line, reward, deadline, destination, owned, accept/deliver/abandon, unavailable | instruções e rótulos | mantidos: nenhuma causa nem promessa de oferta |
| economy.contract.* (accepted, delivered, not_open, unknown, impossible, no_goods, destination_full, too_far, not_yours, expired, failed, abandoned, limit) | respostas da ponte | mantidos: cada uma descreve o código que a ponte devolveu |
Fora do escopo (decisão de Arthur): HUD, diário, aviso de oferta e de prazo. Os documentos que citavam o texto antigo (`presentation.md`, `economy.md` e o roteiro de validação) foram atualizados neste PR.

## Teste EXTRA achado pela suíte inteira (só existe no ramo `lw-095-postos`, não estava nos 36 medidos no main)
| Teste | Antes | Depois | Motivo |
|---|---|---|---|
| test_service_posts_own_market::..only_the_market_of_the_posts_own_settlement_pays_its_payroll.. (1) | `before - after == 2 * folha` em cada um dos 3 mercados | `2 * folha + POSTED_ESCROW` (53) | cada mercado também paga a custódia do pão do postador nas 2 horas; a asserção segue exata e sensível |
Total no ramo: 37 testes em 18 scripts (36 + 1). Suíte inteira: 301 scripts, 2357 testes, 2348 passam, 8 pendentes (`ice_figure`), 1 falha = este teste (já adaptado e verde em seguida).
