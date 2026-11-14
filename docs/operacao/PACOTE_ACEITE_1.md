# Pacote de aceite 1 — tarefas da Fase 3 já no `main` e ainda não aceitas

Preparado em 14/11/2026 sobre o `main` 1cab466 (CI verde). **Nenhuma tarefa foi marcada como aceita e o ROADMAP_STATUS não foi alterado:** o aceite formal é de Arthur. A cobertura foi levantada por leitura dos nomes de testes (o CI verde do `main` mostra que passam; nada foi reexecutado além dele). A LW-097, critério 2, foi conferida à mão: o levantamento automático a marcou como parcial por engano.

| Grupo | Tarefa | Proposta |
|---|---|---|
| A. Concluída e verificada | LW-096 contratos (com 096a e os consertos 096h a 096n) | aceitar |
| A. Concluída e verificada | LW-105 jogador na economia | aceitar |
| A. Concluída e verificada | LW-093 NPCs no mercado | aceitar |
| D. Com ressalva | LW-097 rotas e terceiro povoado | aceitar com a ressalva abaixo |
| C. Validação manual pendente | LW-108 painel de depuração econômico | aceitar depois da sua conferência na janela |
| B. Parcialmente implementada | LW-095 salários e fim do `IncomeStub` | **não aceitar agora** |

## A. Concluídas e verificadas
**LW-096, contratos.** *Em linguagem de jogador:* alguém publica uma encomenda e guarda o pagamento; quem cumpre recebe; se o prazo vence, o dinheiro volta a quem publicou. Há também vagas de emprego nos locais de trabalho: um NPC sem emprego aceita a vaga aberta por uma morte e só troca de vaga se o ganho compensar. *Evidência:* 8 de 8 critérios com teste (cerca de 55 testes): recompensa retida e paga (`test_contract_book`, `test_contract_completion`), prazo vencido devolve ao emissor (`test_contract_expiry`, `test_contract_dead_issuer_custody`), contrato impossível recusado (`test_contract_book`), conservação do dinheiro, vaga sem custódia (`test_contract_vacancies`), NPC sem emprego aceita a vaga, histerese, local sem saldo para sem demitir (`test_npc_vacancy`). **Proposta: aceitar.**

**LW-105, jogador na economia.** *Em linguagem de jogador:* o jogador tem conta e inventário, compra e vende no mercado, o peso limita a carga e tudo sobrevive a salvar e carregar. *Evidência:* 4 de 4 critérios (48 testes): compra e venda, peso exatamente no limite e o seguinte recusado, saldo e inventário no save (`test_bridge_player_trade`, `test_bridge_player_account`, `test_bridge_market_reach`, `test_bridge_market_in_reach`, `test_market_reach`). Você exercitou na janela em 13/11 (conta, compra e venda). Nota: não há asserção própria de que o saldo vem do `Ledger`; ela é garantida pela regra F do `tools/check_architecture` (só o `Ledger` escreve saldo). **Proposta: aceitar.**

**LW-093, NPCs no mercado.** *Em linguagem de jogador:* NPC com fome e dinheiro compra comida no mercado e come; sem dinheiro não compra; o local de produção vende ao mercado; o dinheiro inicial só nasce com motivo registrado. *Evidência:* critérios 1, 2 e 5 com teste direto (`test_npc_buys_food`, `test_npc_buy_decision`, `test_economy_start_money_and_consume`); o 3 pelo teste da venda do produto (`test_production`; o termo "excedente" não tem teste próprio); o 4 pela regra F do `check_architecture` (dentro do `check_all`) e pelos testes de conservação (`test_trade`, `test_ledger`). 23 testes. Hashes: os valores novos do marco 2 (LW-093 a LW-096a) estão registrados em relatório; **aceitar inclui aprová-los (DEC-175)**. **Proposta: aceitar.**

## D. Com ressalva
**LW-097, rotas e terceiro povoado (C).** *Em linguagem de jogador:* existe um terceiro povoado com estradas entre os três, e cada mercado começa com estoque para 30 dias do que importa; fechar uma estrada muda o caminho (comando só de desenvolvimento). *Evidência:* 5 de 5 critérios: caminho mais curto (`test_routes`); rota fechada muda o caminho e, sem rota, dá "sem caminho" (`test_world_module`); referência quebrada apontada com arquivo, item e campo (`test_routes`); 30 dias com o estoque inicial (`test_initial_stock_covers_30_days`); distribuição (`test_economy_distribution`: nenhum povoado se basta, todo bem necessário tem produtor). Os valores novos de hash do marco 3 (oráculo e soak de 30 dias) entraram pela soma das causas aprovadas (relatório no `STATUS-C`); **aceitar a LW-097 inclui aprová-los (DEC-175)**. **Ressalva:** o estoque inicial de comida do C está em 6.000 [HIP] (era 3.000; autorizado por você em 12/11) para o soak de 30 dias fechar sem mortes. Isso adia, não resolve, a falta estrutural de comida (veja o bloqueio da LW-094 em [FILA.md](FILA.md)). **Proposta: aceitar com essa ressalva registrada.**

## C. Validação manual pendente
**LW-108, painel de depuração econômico (só leitura).** *Em linguagem de jogador:* um painel que só aparece em build de desenvolvimento (Shift+Tab) e mostra preços, estoques, produção e se o dinheiro está conservado, sem mudar nada. *Evidência:* só leitura provado por varredura e espião (`test_economy_debug_panel`: exercitar o painel não muda nada no jogo); veredito de conservação verde e vermelho (`test_economy_inspector_model`); 26 testes de modelo, painel e integração; "os números batem com as consultas" tem teste parcial. **Falta a sua conferência na janela (exigida pelo roadmap), em 3 passos:** (1) F5 no Godot; (2) Shift+Tab abre o painel: veja o veredito de conservação; (3) anote preço e estoque do pão no mercado de A, ande até ele, aperte E e compare com a tela do mercado: devem ser iguais. **Proposta: aceitar depois dessa conferência.**

## B. Parcial
**LW-095, salários e fim do `IncomeStub`.** *Em linguagem de jogador:* cada local de produção paga salário por hora a cada trabalhador, tudo ou nada; o local sem saldo para sem demitir; guardas e estalajadeiros seriam pagos pelo mercado. *Evidência:* 4 de 5 critérios com teste, mas só com dados em memória (`test_site_payroll`, `test_wage_income`, `test_wage_payer_atomic`, `test_service_posts`; 45 testes). **Critério 1 falha:** o `IncomeStub` ainda existe (a marca `TEMP-LW-066` está em 12 arquivos e o `test_income_stub` a exige) e **não existe `data/economy/service_posts.json`**. **Proposta: não aceitar agora**; fecha junto do fim do `IncomeStub`, que depende de a economia se sustentar (veja o bloqueio em [FILA.md](FILA.md)).

## Hashes exatos que o aceite valida (lidos no `main` 1dbee79, em 14/11/2026)
Nenhum valor é regravado: são os que já estão no `main` e que o CI confere a cada execução.
- **Oráculo da divisão do `npc`** (`tests/integration/test_npc_split_oracle.gd`, tabela `EXPECTED`, SHA-256 completo; o teste falha se um deles mudar):
  - `intents` `28802dfa9d06e0320247f9c3bae14bba887a78bccfacb0803a5ca8d18dd936d6`
  - `alarm` `916683019e46cf83bad1c75127c5370d7bb1403a8107a0def7956617f3832bd7`
  - `resumed` `a2b476e37a0c5462173369c3ee89c93170b2e18d1fdc3a3815e53e14607e62ff`
  - `switches` `b4c379eaad55b668e299a969761aad1191213f95292d3b2c6a0447ed95890dcd`
  - `talk` `a96d78a9a82fde4b81225e97d0c0778ed6c1525b03af5c3909789302986e2e8f`
  - `save` `5c885dbc09eea1495b195c8d03e737d0317003015ec3d02e6ed4019b3af558c9`
  - `demote` `c5b515175b726d328fbe5b481c0474f08cfdbe8e0d6c251cc4b46c342c569895`
  - `starved` `d2533a12fd058d0eb1a41ce42b001782b8f9285f41bc7d68dac2fb6bc01502a6`
  - `real_game` `48857919c5ffce261b0bcfff4e933785adcd5085b6d63cb2f0802e0f81e5e1b4`
- **Soak de 30 dias da vida dos NPCs** (`tests/soak/run_npc_life_30d`, fora do `check_all`): hash `2b0f8a2917c1` (prefixo de 12 caracteres que o script imprime), **igual nas 3 execuções**, 132 vivos no mínimo, maior tempo parado 0 min, 0 problemas. Os mercados de A e B ficam **sem comida em 81% e 87% do tempo** (35.068 e 37.728 de 43.200 min) e o de C em 5,7% (2.450 min): os 132 vivem do `FoodStub`.
- **`tools/run_sim --days 30 --seed 1`:** `732907967efdba5f718687a0bbafbfe102ac51cabc9d15a7f0119a9e64ebc4d7`, **igual ao de 03/11/2026** (não registra módulo: não muda).
- **De onde vêm os valores do oráculo** (cabeçalho do próprio teste): marco 1, bloco vazio `economy` no save (aprovado por você em 11/11); marco 2, frente A (LW-093 a LW-096a; por exemplo `intents` `8670b52b8ff6` e `real_game` `76a65b9cfc8a`, em 12 caracteres); marco 3, soma das causas da LW-097 (regra do `FoodStub` do povoado C e comida no save do `npc`; `world` como módulo registrado, com bloco no save; população real de 132 NPCs aprovada por você em 11/11; junção com o `main` por autorização antecipada de 11/11, com o estoque de comida do C de 3.000 para 6.000 [HIP]).
- **Ressalva da LW-097 a registrar, como você pediu:** o estoque inicial de comida do povoado C é **6.000 [HIP], provisório** (era 3.000; autorizado em 12/11) para o soak de 30 dias fechar sem mortes; adia, não resolve, a falta estrutural de comida (bloqueio da LW-094, [FILA.md](FILA.md)).
- **Frase de aceite sugerida:** "APROVADO LW-093, LW-096, LW-097 (com a ressalva do estoque provisório do povoado C) e LW-105, validando os hashes da seção 'Hashes exatos'". A LW-095 segue pendente e a LW-108 espera a sua conferência na janela.

## Como aceitar
Se concordar: "APROVADO LW-093, LW-096, LW-097 (com a ressalva) e LW-105" leva a Fase 3 de 7 para 11 de 30; "APROVADO LW-108" depois da conferência leva a 12. Com o aceite, o Maestro atualiza o ROADMAP_STATUS. Aceitar a LW-093 e a LW-096 aprova os valores de hash do marco 2, e a LW-097, os do marco 3 (DEC-175): nenhum valor é regravado, são os que já estão no `main`. Fora da Fase 3, sem ação agora: LW-117 e LW-146 (só documentos) e LW-118 estão no `main` e não contam ainda.
