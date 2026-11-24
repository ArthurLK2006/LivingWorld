# Contrato de interface LW-107h (proposta): custo e resultado estimados das encomendas, com aviso de possível prejuízo

**REFERÊNCIA DO DESENVOLVIMENTO (Arthur, 23/11/2026: "aprovo a direção de interface que informa custos, margens e riscos econômicos" e "utilize o contrato do PR #157 como referência").** As respostas recomendadas da seção 11 valem no desenvolvimento (única mudança de texto: "Os preços podem mudar.", as palavras dele); a implementação é o PR #162 (rascunho, classe 3), que SÓ integra com o "APROVADO" dele e com a emenda dos documentos de contrato da seção 10. Este PR é só documento: nenhum `src/`, dado, texto, teste ou arquivo protegido muda. Pedido de Arthur (23/11/2026, LW-107c3): um contrato de UI para exibir **estimativas de custo e margem**, com **aviso claro de prejuízo possível e sem prometer lucro, porque os preços mudam**; sem ativar nem integrar o #152 antes da validação visual e da autorização dele. Ramo `lw107c3-contrato-ui-custo` (de `origin/main` 89d935d). O postador segue DESLIGADO (`data/economy/contract_templates.json` = `[]`) e o #152 segue rascunho. Os documentos `docs/economia/lw-107c3-opcao-b-condicoes.md` e `docs/economia/LW-107-validacao-local-opcao-b.md` estão no ramo `lw107c3-opcao-b` e nas pastas locais `validacao-107c3-*`, ainda fora do `main`. Os números do pão e da escassez usados abaixo foram conferidos pelo Maestro em 23/11/2026 contra os testes automáticos no jogo real (`tests/integration/test_contract_option_b_real_world.gd`, no `lw107c3-opcao-b`): pão do A a 11 (5 pães por 55), do B a uns 10 (5 por 48) e, na escassez, a 32 em cada mercado (160 por 5 pães).

## 1. Decisões propostas (resumo)
1. **Onde:** no detalhe da linha escolhida da aba Contratos (abertas, antes de aceitar; aceitas ainda no prazo): 3 rótulos novos, sem mexer nas listas.
2. **O que:** "Custo estimado aqui" (só das unidades que FALTAM), "Resultado estimado" (recompensa menos custo) e UM aviso em texto.
3. **Base do custo:** o mercado em que o jogador ESTÁ, pela cotação real de N unidades (nunca `ask × N`).
4. **Aviso:** "Possível prejuízo" (resultado negativo), "Margem estimada" (neutra, sempre com "os preços mudam"), "Saldo insuficiente para comprar" e "Custo indisponível" (nunca zero).
5. **Origem do número:** uma consulta nova SÓ DE LEITURA da ponte (`peek_trade_quote`, repasse fino do `EconomyModule.peek_quote`); o ViewModel só subtrai e compara.
6. **Quando:** no ritmo que a tela já tem (1 s [HIP]), mas só com a aba Contratos visível; no máximo 1 cotação por encomenda ativa.
7. **Texto:** 9 chaves `ui.contracts.*` novas (de 30 a 39); nenhuma promete lucro.
8. **Classe 3** (contrato novo na ponte e na apresentação, dois módulos): só depois da aprovação dele, em PR próprio e rascunho; não depende da ativação do #152.

## 2. O que mostrar e onde
**Hoje** (`presentation.md` l.63-70; `contracts_layout.gd` `build`): duas listas `Tree` de 3 colunas (bem e quantidade, recompensa, prazo ou estado) e, abaixo, o detalhe da linha escolhida (bem e quantidade, recompensa, prazo restante, destino, "Você tem X de Y", estado), os botões e a dica. **Aceitar exige escolher a linha antes**, então o detalhe é sempre visto antes de aceitar.
**Proposta (L1):** três linhas novas entre o detalhe e os botões, rótulos filhos da `ContractsPage` (não da `MarketColumn`, cujos filhos um teste lista), só com papéis que o `MarketTheme` já tem: `ContractsEstimate` (números, STATUS), `ContractsVerdict` (aviso, RESULT) e `ContractsEstimateHint` (nota, HINT). A dica que já existe (`ContractsHints`) NÃO muda: os testes leem o texto exato dela (`test_contracts_actions.gd` l.331 e 337). Ficam escondidas nas linhas terminadas (Concluído, Vencido, Abandonado, Falhou) e sem jogo.

| Ordem visual | Conteúdo |
|---|---|
| 1 a 6 (já existem) | "Entregar 5 x Pão", "Recompensa: 53", prazo, destino, "Você tem 0 de 5", estado |
| 7, 8 e 9 (novas) | os números; o aviso, em destaque; a nota "Estimativa de hoje, só da compra neste mercado..." |
| 10 a 12 (já existem) | botões, resposta do pedido, dica de aceitar ou entregar |

**Alternativa L2 (não recomendo agora):** 4ª coluna "Estimativa" nas listas, só com a palavra do aviso (visível sem escolher a linha). Muda `COLUMN_COUNT` de 3 para 4 e a linha 49 de `tests/unit/test_contracts_layout.gd` (`[0, 1, 2, 3]`): decisão dele (pergunta 6).

## 3. Como ficaria (exemplos com os números medidos em 23/11/2026 nos testes automáticos da opção B; recompensa 53, saldo inicial 100)
| Situação | Linha 7 | Linha 8 |
|---|---|---|
| Pão normal, encomenda aberta no A | Custo estimado aqui: 55 · Resultado estimado: -2 | Possível prejuízo: 2. Os preços mudam. |
| A mesma, já aceita, com a tela aberta no B (pão mais barato) | Custo estimado aqui: 48 · Resultado estimado: 5 | Margem estimada: 5. Os preços mudam. (com a pergunta 3 em "sim", 5 é menos de 10% de 53 e a linha vira "Margem estimada pequena...") |
| Escassez, aberta no A, saldo 100 | Custo estimado aqui: 160 · Resultado estimado: -107 | Possível prejuízo: 107. Os preços mudam. Saldo insuficiente para comprar: faltam 60. |
| Ele já carrega os 5 pães | Você já tem os itens: sem custo de compra | (sem aviso) |
| O mercado não tem pão suficiente | Custo indisponível neste mercado: resultado não estimado | (sem aviso) |

## 4. Base do custo
**Decisão: (a) o mercado aberto na tela** (`market_id` da `MarketView`), cotação de COMPRA (`buy`) de `faltam` unidades, com `faltam = quantidade − unidades livres em mãos`. Porque:
- é o único preço em que ele pode agir agora (comprar exige estar perto: `economy.trade.too_far`);
- a ordem anda pela curva, então o custo real é MAIOR OU IGUAL a `ask × N` (`economy.md` l.153): `ask × N` seria um piso que subestima o custo e INFLA a margem, o contrário do pedido; e o `MarketViewModel` (l.4-5) já proíbe totais na tela (decisão de 13/11);
- não revela preço de mercado que ele não visitou e não exige memória salva; em "Meus contratos" o número muda com o mercado onde ele está, o que mostra onde comprar sem prometer nada.

**Alternativas:** (b) o mais barato dos 3 mercados: leria `peek_economy_markets` (já chega à tela) com 3 cotações por encomenda; "mercados que o jogador conhece" exigiria memória salva (estado novo, classe 3 ou 4) ou uma leitura onisciente (decisão de jogo); e embute uma viagem que o custo não cobre. (c) os dois números: duas linhas por encomenda, para depois da pergunta 1.
**Consequência que Arthur precisa saber:** pela regra (b) do postador (`contract_poster.gd` l.51-52, recompensa no máximo `ask × quantidade`), comprar no emissor nunca dá lucro na hora de postar. Logo a encomenda ABERTA no mercado emissor mostrará quase sempre "Possível prejuízo": pequeno no pão normal (5 pães no A custam 55 contra 53: −2, medido) e grande na escassez (160 contra 53: −107, com saldo inicial 100, que nem cobre a compra). A "Margem estimada" aparece em "Meus contratos" diante de um mercado mais barato (no B, 48 contra 53: +5, medido no 1º dia) ou se o preço do emissor cair depois da postagem. É verdade e é o aviso pedido, mas muda a primeira impressão do "pão normal do A".

| Caso | Custo mostrado |
|---|---|
| faltam 0 | 0, sem consulta; "Você já tem os itens", SEM veredito de margem (o que ele pagou antes não está salvo) |
| cotação ok | o `total` da cotação de `faltam` unidades (a tarifa só soma quando a economia a cobrar; hoje é 0) |
| cotação recusada (`ECON_INSUFFICIENT_STOCK`, `ECON_BAD_QUANTITY` acima de 50 por ordem, bem banido, qualquer outra) | **desconhecido, nunca zero**: "Custo indisponível neste mercado"; sem resultado nem veredito |
| custo maior que o saldo (`funds` de `peek_player_economy`) | custo mostrado e "Saldo insuficiente para comprar" (a cotação NÃO confere fundos nem peso) |
| peso | não estimado na v1: a compra já é recusada por `economy.trade.too_heavy`, e o lote do modelo é validado para caber |
| unidades em mãos | descontadas sem contar a mesma unidade duas vezes: as aceitas (por `contract_id`) consomem primeiro; as abertas só veem a sobra |

## 5. O aviso (texto primeiro, cor só reforça)
| Quando | Texto | Destaque |
|---|---|---|
| resultado < 0 | "Possível prejuízo: {loss}. Os preços mudam." | matiz local `DANGER_TINT` (`self_modulate`, como o botão Abandonar) |
| resultado >= 0 | "Margem estimada: {margin}. Os preços mudam." | nenhum: cor padrão, sem "lucro", "ganho" nem "garantido" |
| resultado de 0 a 10% da recompensa [HIP], se ele aprovar (pergunta 3) | troca a linha acima por "Margem estimada pequena: {margin}. Pode virar prejuízo, os preços mudam." | nenhum |
| custo maior que o saldo | segunda frase: "Saldo insuficiente para comprar: faltam {short}." | matiz de perigo |

**Convenção da UI:** os avisos são texto (`ui.market.shortage`: "(em falta)"); a única cor de perigo é o matiz local do Abandonar, com contraste conferido por `test_contracts_danger_tint.gd` (≥ 4,5:1 [HIP]). O aviso reutiliza o matiz e o mesmo tipo de teste (`COLOR_RESULT` × `DANGER_TINT` contra `COLOR_PANEL`); `mark_as_danger` hoje só aceita `Button` (l.68), então a implementação a generaliza ou cria uma irmã para `Label`, sem `add_theme_*` (um teste da pasta o proíbe).
**NÃO estimado, dito na nota (linha 9):** tempo e deslocamento, peso, o que já pagou pelos itens em mãos e a mudança de preço até a compra.

## 6. De onde vem o número (arquitetura)
- **Consulta nova da ponte, só leitura:** `SimBridge.peek_trade_quote(actor_id, market_id, good_id, quantity, side) -> BridgePlayerEconomyReplies.TradeQuoteReply` (`result`, `quantity`, `total`, `average_price`, `tariff`), repasse fino do `EconomyModule.peek_quote` (`economy_module.gd` l.245-246: "serve à interface"; já confere ator, estoque, regras e quantidade de 1 a 50, não fundos nem peso).
- **Falhas:** as da ponte (`BRIDGE_NO_GAME`, `BRIDGE_NO_CHARACTER`, `BRIDGE_NO_ECONOMY`, `CHARACTER_UNKNOWN_ACTOR`) e as da economia, sem traduzir e sem `text_key`; SEM exigir alcance (é leitura, como `peek_contract_board`); sem evento, estado ou texto. Lógica em `BridgePlayerEconomy.quote`, tipo em `bridge_player_economy_replies.gd`; o `SimBridge` só delega (+8 linhas; tem 324 de código, tolerância 450).
- **Por que a ponte:** a apresentação só fala com a ponte. Hoje a ponte NÃO expõe `peek_quote` (`bridge.md` l.46) e Arthur decidiu em 13/11 que o mercado (LW-106) não o usa; a cotação por quantidade é "melhoria futura" (`backlog.md` l.257, `economy.md` l.86). Este contrato pede que ele a libere SÓ para a aba Contratos; a aba Mercado segue como está. **Rejeitadas:** (P2) pôr o custo em `ContractBoardRow` (muda resposta aprovada em 14/11 e faz toda leitura do quadro cotar); (P3) `ask × N` no ViewModel (piso que infla a margem).
- **ViewModel:** `refresh` segue igual e só guarda também o `funds` que já lê (nenhuma consulta nova). Novos `refresh_estimates(bridge, actor_id)` e `estimate_of(contract_id) -> Estimate` (`kind`: nenhuma, em mãos, desconhecida ou conhecida; `missing`, `cost`, `result`, `funds_short`). Só subtrai e compara, como o `minutes_left`; o custo vem da economia, então vale o "não calcula custo" de `presentation.md` l.64. Só inteiros: o `total` já vem arredondado pela economia (por degrau), sem divisão na tela.
- **Quando:** a `ContractsPage` já se atualiza a cada 1 s [HIP] (`REFRESH_INTERVAL_S`) e após cada pedido, mesmo com a aba Mercado escolhida (`market_view.gd` l.8). As estimativas rodam só com a página visível e uma vez ao trocar para ela: nenhuma consulta extra enquanto ele negocia na aba Mercado. Relógio pausado: a leitura continua; os botões seguem como hoje.
- **Custo de desempenho:** 1 `peek_quote` por encomenda ativa com `faltam` > 0 (aberta ou aceita no prazo; as até 5 terminadas não cotam), típico até 6 por atualização, cada uma andando `faltam` degraus (pão 5, farinha 10); NÃO medido (sem benchmark; DEC-119 é a meta de quadros). Se pesar: cache por (mercado, bem, quantidade) e refazer só na mudança da hora de jogo.
- **Determinismo e tolerância:** a cotação é pura (premissa da LW-098h3c, `backlog.md` l.267) e igual à cobrada pelo `request_trade` no MESMO instante (o teste exige igualdade). Depois pode diferir: NPCs e produção mudam preço e estoque, as compras dele andam na curva e uma tarifa futura (LW-130) muda a conta. Nenhuma tolerância numérica é prometida; a nota diz que o valor pago pode ser outro.

## 7. Textos (todos por chave em `data/text/pt_br.json`; `tools/check_literal_text` confere)
| Chave `ui.contracts.` | Texto proposto | Onde aparece |
|---|---|---|
| `estimate_cost` | "Custo estimado aqui: {cost}" | linha 7, custo conhecido |
| `estimate_result` | "Resultado estimado: {result}" | linha 7, junto da anterior |
| `estimate_have` | "Você já tem os itens: sem custo de compra" | linha 7, `faltam` 0 |
| `estimate_unknown` | "Custo indisponível neste mercado: resultado não estimado" | linha 7, cotação recusada |
| `verdict_loss` | "Possível prejuízo: {loss}. Os preços mudam." | linha 8 |
| `verdict_margin` | "Margem estimada: {margin}. Os preços mudam." | linha 8 |
| `verdict_margin_small` | "Margem estimada pequena: {margin}. Pode virar prejuízo, os preços mudam." | linha 8 (só se a pergunta 3 for sim) |
| `verdict_funds` | "Saldo insuficiente para comprar: faltam {short}." | linha 8 |
| `hint_estimate` | "Estimativa de hoje, só da compra neste mercado: tempo e viagem não entram, o que você já tem não entra e o valor pago pode ser outro." | linha 9 |

Chaves existentes: nenhuma muda por este contrato. `ui.contracts.empty` ("Nenhum contrato agora: os mercados estão abastecidos") é a 1 enganosa, já trocada no `lw107c3-opcao-b` (a8540fa) por "Nenhuma encomenda disponível agora." e ainda não no `main`: se o #152 não entrar, a troca vai junto da implementação. "Recompensa" fica (é o valor da entrega, não o ganho).

## 8. O que NÃO muda
O postador e a regra de postagem; a recompensa; as regras (b) e de 14/11 (recompensa no máximo `ask × quantidade`); saldo, entrega, limite de 3 e abandono; `contract_templates.json` = `[]`; as opções X, Y e Z do pão (este contrato só MOSTRA informação); a aba Mercado; `request_*`; evento, save e `state_hash`. A estimativa não bloqueia nada: aceitar é grátis e abandonar é sem multa, então o prejuízo só existe se ele comprar e entregar.

## 9. Testes (só descritos; nenhum escrito)
- **Unitários do cálculo:** custo parcial com inventário e sem contar a unidade duas vezes; resultado negativo; saldo insuficiente; mercado sem estoque (desconhecido, nunca 0); lote acima de 50; curva (custo de 5 maior que 5 × `ask` com estoque baixo); `faltam` 0 sem consulta; terminadas sem estimativa; igualdade com o total pago por `request_trade` no mesmo instante; `state_hash` igual.
- **Ponte:** `peek_trade_quote` igual a `EconomyModule.peek_quote`; recusas (NPC, ID solto, sem jogo, sem economia, sem conta); sem exigir alcance; nada muda.
- **Leiaute e texto:** os 3 rótulos, nomes e ordem; escondidos sem estimativa; nenhum filho novo da `MarketColumn`; matiz só no prejuízo e contraste ≥ 4,5:1; as 9 chaves existem, nenhuma literal, nenhum valor com "lucro", "ganho" ou "garant", e todo "Margem" com "preços mudam".
- **Integração (jogo real, contratos postados por `request_post_contract` como em `test_bridge_player_contracts.gd`, postador desligado):** (i) escassez (pão com estoque 5 nos 3 mercados, por `request_set_stock`): "Possível prejuízo" e "Saldo insuficiente" no A com saldo 100; (ii) pão normal no A: "Possível prejuízo" pequeno; (iii) o mesmo contrato aceito e a tela aberta no B: "Margem estimada" positiva; (iv) abrir, atualizar e trocar de aba não mudam o `state_hash`.
- **Só a janela dele julga:** clareza e tamanho do aviso, contraste no monitor dele, se "aqui" é entendido, a impressão de "tudo dá prejuízo no emissor" e a ordem visual.

## 10. Arquivos, classe, tarefa e documentos protegidos
- **Tocaria:** `src/bridge/sim_bridge.gd`, `bridge_player_economy.gd`, `bridge_player_economy_replies.gd`; `src/presentation/ui/market/contracts_view_model.gd` (122 linhas de código), `contracts_layout.gd` (77), `contracts_page.gd` (166); `data/text/pt_br.json` (+9 chaves); testes novos (ViewModel, ponte, leiaute e texto, integração).
- **Testes existentes:** nenhum deve mudar (L1 não mexe em coluna nem na dica). Rodar `test_contracts_layout`, `test_contracts_tab`, `test_contracts_actions`, `test_contracts_page_abandon`, `test_bridge_player_contracts` e `test_market_*` antes e depois e PARAR se um assert exato precisar mudar (AGENTS 9.5). Medir e dividir antes de 450 linhas.
- **Classe 3** (`MAESTRO.md` seção 3): contrato novo ou alterado, ponte e apresentação (AGENTS l.352: aprovação dele). Contratos que mudam: `bridge.md` (consulta nova) e `presentation.md` (aba Contratos); `economy.md` só ganha uma nota; nenhum arquivo do 12.5 muda e `DECISIONS.md` só com autorização dele.
- **Tarefa dona proposta: LW-107h** (a LW-107g já existe), ligada à condição 2 da LW-107c3 mas independente da ativação: com o postador desligado o quadro real fica vazio e a UI fica dormente (testada por contratos postados à mão); serve também às encomendas por objetivo da LW-107f, que usam o mesmo quadro. **Ordem sugerida:** aprovar o contrato, implementar em PR próprio, ele validar a tela na pasta de escassez, e só então decidir a ativação.
- **Texto que os documentos ganhariam (NÃO editados aqui):** `presentation.md` (l.64 e 67): "não calcula custo" passa a "o custo vem da economia pela ponte; só subtrai e compara", mais o parágrafo "Custo e resultado estimados (LW-107h)" com as seções 2 a 6 deste contrato; `bridge.md` ("Jogador na economia"): item novo `peek_trade_quote`, e a l.46 diz que o painel econômico segue sem `peek_quote`; `economy.md` l.86: "a aba Contratos a usa (LW-107h)"; `backlog.md` l.257: a cotação por quantidade da aba Mercado segue pendente; `DECISIONS.md` (protegido): "DEC-NNN: a aba Contratos mostra custo e resultado estimados do mercado em que o jogador está, com aviso de possível prejuízo e sem prometer lucro; é informativo e não bloqueia aceitar nem comprar".

## 11. Perguntas para Arthur
| # | Pergunta | Opções | Recomendo |
|---|---|---|---|
| 1 | Base do custo | (a) mercado atual; (b) mais barato dos 3; (c) os dois | (a) |
| 2 | Mostrar quando | sempre; só quando negativo | sempre (esconder a margem faz o silêncio parecer "seguro") |
| 3 | Avisar margem pequena (até 10% da recompensa) | sim; não | sim, faixa única [HIP] |
| 4 | Aceitar com prejuízo estimado | só avisar; pedir confirmação | só avisar (aceitar é grátis) |
| 5 | Liberar `peek_trade_quote` na ponte, só para a aba Contratos (revê a decisão de 13/11) | sim; não | sim |
| 6 | Aviso também nas listas | só no detalhe; 4ª coluna | só no detalhe |
| 7 | Itens já em mãos | "sem custo", sem margem; mostrar margem | "sem custo" |

**Resposta de Arthur (23/11/2026):** aprovou a direção e mandou usar este contrato como referência; as 7 recomendações da coluna "Recomendo" foram adotadas no desenvolvimento (base do custo no mercado atual; sempre mostrar; avisar margem pequena de 10% [HIP]; só avisar, sem confirmação nem bloqueio; liberar `peek_trade_quote` só para a aba Contratos; aviso só no detalhe; itens em mãos = sem custo e sem veredito). Ele pediu também considerar o inventário e não presumir que o que o jogador já tem foi comprado agora. **Aberto (achado da revisão do PR #162):** na posse PARCIAL (faltam 2 de 5), o resultado desconta só o custo das unidades que faltam e a "Margem estimada" pode parecer boa demais; a nota "o que você já tem não entra" cobre o caso, mas fica a pergunta a Arthur: manter, ou mostrar só o aviso de prejuízo nesse caso.

## 12. O que NÃO foi verificado
Nada rodou no Godot (nem teste, nem lint); os números do pão e da escassez foram conferidos contra os testes automáticos da opção B (23/11/2026), mas nenhum cálculo de estimativa foi implementado nem rodado; o contraste do matiz sobre o rótulo, o tamanho do texto na janela e o desempenho de até 6 cotações por segundo NÃO foram medidos; a existência dos nomes citados foi conferida por `rg` no `origin/main` 89d935d, e a dos dois documentos da opção B, no ramo `lw107c3-opcao-b`.
