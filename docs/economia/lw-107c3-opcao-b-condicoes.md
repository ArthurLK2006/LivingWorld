# LW-107c3, opção B: as condições de ativação (23/11/2026)

**Status:** DOCUMENTO, **nada foi ativado**: neste ramo (`lw107c3-condicoes`, de `lw-095-postos` 6a5da27) não mudou nenhum `src/`, dado, texto ou teste; o dado, o texto e os testes da opção B são do ramo `lw107c3-opcao-b` (commit a8540fa). Decisão de Arthur (23/11/2026): opção B (sem o `grain_shortage`), preparada em PR isolado e RASCUNHO, sem ativar antes da validação visual dele. Este documento cobre as condições 1, 2 (auditoria do texto), 3 e o roteiro da 5; a 4 (testes) é do ramo `lw107c3-opcao-b`. O pacote de decisão é `docs/economia/lw-107c3-decisao-23-11.md`.
**Como foi medido (só `--headless`, nenhum benchmark):** CÓPIA descartável da base da ativação, `lw-095-postos` (com os 6 postos e a regra da refeição; o pacote anterior mediu o `origin/main` 07b97d1 com o `FoodStub`, então os preços de lá ficam superados), por `docs/economia/experimentos/preparar_copia.sh`, com `contract_templates.json` = os modelos do `.initial.json` SEM o grão (`bread_standing` e `flour_shortage`), 138 NPCs, sementes 1, 2 e 3, 30 dias (720 h). Um medidor só da cópia (`l2_bread.gd`, fora do repositório) registra a cada hora, por mercado, estoque, `ask`, `bid` e a cotação REAL (`peek_quote`) de 5 pães para comprar e vender, e roda um jogador-robô opcional. **Robôs:** `issuer` (a cada hora compra no emissor e entrega, sem viagem, como o teste residual da 107c2) e `best` (escolhe a fonte de menor cotação, só age se o ganho esperado for maior que 0, corre 7 m/s até a fonte e daí ao emissor com os minutos de jogo da seção 2.1, aceita e entrega; um trajeto por vez; começa em A; 24 h por dia de jogo). Dinheiro e bens fecharam e o `validate()` do mundo e da economia saiu vazio em todas as execuções concluídas (o `issuer` só concluiu a semente 1: cada execução leva uns 5 min e interrompi as outras duas; ele serve só de confirmação de R0).

## 1. Resumo
- **Pão (condição 1): LOGÍSTICA deliberada enquanto existe um mercado barato (55% das 107 ofertas medidas) e PREJUDICIAL na escassez geral (45%: semanas 3 e 4 de duas das três sementes; com jogador, depois do dia 15 nas três).** A recompensa é fixa (53 por 5 pães = 5,25 x o valor-base 10) e o custo flutua de 6 a 30 por pão, então o ganho só vem de comprar barato em OUTRO mercado (hoje o B) e entregar no emissor (A ou C): +5 a +23 por entrega. Comprando no emissor perde sempre (regra (b), decisão de Arthur de 14/11): média -10 a -28, pior caso -99. Na escassez TODA fonte dá prejuízo. Nada obriga a aceitar, mas a tela não compara preços. Conclusão e opções na seção 2.4.
- **Livro (condição 3): medido, não é problema de tamanho** (153 bytes por contrato; 30 a 39 contratos em 30 dias sem jogador e 85 a 88 com o robô); poda proposta, sem implementar (classe 3).
- **Interface (condição 2):** 43 chaves auditadas, 1 enganosa (`ui.contracts.empty`), já trocada no ramo `lw107c3-opcao-b`; o que falta fora da tela de mercado depende de Arthur (seção 4).

## 2. Pão (`bread_standing`: 5 pães, 48 h, 500 bp, recompensa 53)
**2.1 Regra e geografia.** O postador só publica com `53 <= 5 x ask` do emissor (`ask` >= 11, isto é, pão no estoque-alvo ou abaixo) e o emissor é o próprio destino. Distâncias de `data/world/places.json` (centro de cada mercado) e viagem a 1x (1 min de jogo = 1,25 s reais; o corpo do jogador não acelera com o relógio, `player_body.gd`, então a 2x o mesmo trecho custa o DOBRO de minutos de jogo):

| Trecho | Distância | Correndo (7 m/s) | Andando (4 m/s) |
|---|---|---|---|
| A-B | 503 m | 72 s reais = 58 min de jogo | 126 s = 101 min |
| A-C | 391 m | 56 s = 45 min | 98 s = 78 min |
| B-C | 312 m | 45 s = 36 min | 78 s = 63 min |

**Preço do pão (`ask` nas 720 h; custo de 5 pães entre parênteses):** s1: A 11 fixo (55), B 6 a 10 (30 a 50), C 10 a 18 (50 a 93). s2: A 11 a 18, B 6 a 19, C 10 a 29. s3: A 11 a 18, B 6 a 19, C 10 a 30. O A posta o tempo todo, o C quase (638, 618 e 660 de 720 h com `ask` >= 11) e o B só quando encarece (0, 366 e 414 h): no começo só A e C têm encomenda, então o limite de 3 aceitas só pesaria com os três postando (s2 e s3).

**2.2 Lucro por entrega no instante da postagem, sem jogador** (R0 = comprar no emissor; R1 = comprar na fonte mais barata fora do emissor e levar, 36 a 58 min de jogo por trecho; cotação real de 5 pães):

| | s1 | s2 | s3 |
|---|---|---|---|
| Ofertas de pão em 30 dias | 30 | 38 | 39 |
| R0: média / mediana / pior | -9,6 / -2 / -39 | -25,3 / -20 / -94 | -27,5 / -19 / -99 |
| R1: média / mediana / faixa | +11,1 / +8 / +5 a +23 | -8,3 / -10,5 / -41 a +23 | -10,9 / -9 / -50 a +23 |
| Ofertas com R1 > 0 (alguma fonte dá lucro) | 30 de 30 | 15 de 38 | 14 de 39 |
| R1 médio por semana (S1 a S4) | +13,5 / +16,3 / +8,0 / +8,0 | +13,5 / +12,0 / -10,4 / -29,4 | +13,5 / +9,4 / -14,5 / -35,4 |
| R0 médio por semana | -10,6 / -2,8 / -11,4 / -12,0 | -8,9 / -7,0 / -18,5 / -49,5 | -8,4 / -6,7 / -25,2 / -54,8 |
| Arbitragem comum (5 pães, melhor par, mesmo instante, sem viagem): média; R1 a supera | +14,3; 8 de 30 | +16,7; 8 de 38 | +19,3; 6 de 39 |

Total: 107 ofertas, R1 > 0 em 59 (55%), nenhuma fonte lucrativa em 48 (45%), concentradas nas semanas 3 e 4. A única fonte lucrativa foi sempre o B. A tabela diária está nos brutos (`diario_none_s*.csv`).

**2.3 Jogador-robô, 30 dias (com o efeito das próprias compras e entregas nos preços):**

| | s1 | s2 | s3 |
|---|---|---|---|
| `best`: entregas / lucro total (começa com 100) | 61 / +677 | 58 / +641 | 61 / +655 |
| `best`: ganho por entrega, média / mínimo / máximo | +11,1 / +1 / +23 | +11,1 / +1 / +23 | +10,7 / +1 / +23 |
| `best`: entregas por bloco de 5 dias (d0-4, 5-9, 10-14, depois) | 47, 8, 6, 0 | 46, 8, 4, 0 | 45, 8, 8, 0 |
| `best`: rota mais usada; tempo da decisão à entrega | C<-B 56 de 61; 72 min | C<-B 53 de 58; 72 min | C<-B 55 de 61; 71 min |
| `issuer` (compra no emissor, sem viagem): entregas / lucro total; ganho por entrega média (mín a máx) | 33 / -46; -1,4 (-2 a +3) | não concluído | não concluído |

Até cerca de 9 entregas por dia nos 5 primeiros dias (o trajeto B-C de ida e volta leva 72 min e o contrato seguinte só nasce na hora cheia), 8 nos 5 seguintes e **nenhuma depois do dia 15**: com o robô, no dia 10 do s1 o B caiu de 80 para 31 pães e o C subiu de 134 para 194 (alvo 200), e os dois ficaram com `ask` 11 (a diferença fechou); no dia 20 o pão custa 14 a 20 nos três mercados (A 46, B 21 e C 91 pães), o robô não aceita mais nada e 23 a 24 contratos vencem sem aceite. O robô segura 1 contrato por vez: o limite de 3 aceitas nunca pesou.

**2.4 Conclusão: (a), viável como LOGÍSTICA deliberada, com a escassez como o ponto que só Arthur pode aceitar ou mandar resolver.** Lucro típico +8 a +13 por entrega pela fonte mais barata (faixa +1 a +23; o robô, que só age com ganho esperado positivo, nunca perdeu). Pior caso: -99 por entrega de quem compra no emissor (mediana -2 em s1 e -19 a -20 em s2 e s3) e -50 na melhor fonte da escassez. Três fatos a registrar como escolha de gameplay: (i) **o ganho se esgota** em cerca de 15 dias de jogo contínuo (o jogador mesmo fecha a diferença de preço); (ii) **em escassez geral a oferta é ruim**: a recompensa não acompanha o preço, então o contrato vira prejuízo para quem o aceita (ninguém é obrigado, o preço está na aba Mercado, mas nada na tela avisa); (iii) **a arbitragem comum paga mais** (média +17 nos 107 instantes; o contrato dá +11 em s1 e fica negativo em s2 e s3) e sem o teto de 5 pães; o contrato só vence em 22 dos 107 instantes.
**Se Arthur preferir resolver a escassez (nada disto foi feito; regra nova do postador é classe 3):** (X) só dado, dentro de (b): acrescentar o modelo `bread_shortage` (gatilho `shortage`, margem até 5000 bp = recompensa 75): estreita o prejuízo sem acabar com ele (75 contra 71 a 152 de custo de 5 pães nos dias 20 e 29 do s1 com robô); não medido; (Y) só dado: `reward_margin_bp` 1000 (teto do `standing`): recompensa 55, o emissor com `ask` 11 passa de -2 para 0 e a logística sobe cerca de +2; não resolve a escassez, muda o 53 em testes e referências; não medido; (Z) regra nova: recompensa indexada ao preço, destino diferente do emissor, ou o postador não publicar quando nenhuma fonte dá lucro (exige o preço dos outros mercados): resolve, mas mexe na regra (b) e na DEC-175.

## 3. Crescimento do livro de contratos (medido; nenhum benchmark)
Cada contrato de entrega fica no livro para sempre (`ContractBook` não apaga) e o postador o percorre a cada hora cheia. Serialização real (`JsonSaveCodec` sobre `runner.capture_game()`), 30 dias, sem jogador:

| | s1 | s2 | s3 |
|---|---|---|---|
| Postados / vencidos / abertos | 30 / 28 / 2 | 38 / 35 / 3 | 39 / 36 / 3 |
| Bloco `economy.contracts` no save (JSON) | 4579 B (152,6 B por contrato) | 5800 B | 5953 B |
| Save inteiro: JSON / codificado (gzip) | 105972 / 9552 B | 107489 / 9774 B | 107694 / 9714 B |
| x12 (360 dias): contratos; bloco em JSON | 360; 55 KB | 456; 70 KB | 468; 71 KB |
| Com o robô `best` (TETO: ele para no dia 15): postados em 30 dias; x12 em JSON | 88; 161 KB | 85; 156 KB | 87; 159 KB |

**Leitura:** sem jogador o livro cresce 1,0 a 1,3 contrato por dia (um por mercado a cada 48 h): 360 a 470 por ano de jogo e 55 a 71 KB de JSON (o save de 30 dias tem 106 KB; o codificado inteiro, 9,7 KB; o bloco comprimido NÃO foi medido à parte). Com um jogador farmando, o teto linear passa de 1000 contratos por ano e 160 KB. **Não é problema de tamanho.** Não medido (sem benchmark): o custo do `_open_counts` por hora e do `validate()` com milhares de contratos (linear no livro por inspeção); a lista "Meus contratos" também só cresce.
**Poda proposta, SEM implementar (classe 3):** na hora cheia, logo depois do `expire` (`economy_runtime.gd`, linha 56), apagar os contratos de ENTREGA fechados (`completed`, `failed`, `expired`) com `deadline` mais velho que N dias (sugestão N = 7; o prazo é um limite superior do fechamento), sem tocar nos abertos, nos aceitos (custódia), nas vagas de trabalho nem nos IDs (o `IdGenerator` não reaproveita). **Muda:** o save perde os fechados antigos (o bloco passa a ter no máximo 1,3 x (N + 2) contratos, uns 2 KB); um save antigo carrega igual (a poda ocorre na 1ª hora); o hash do mundo COM economia muda depois do dia N (os fixados em teste, oráculo e soak sem economia, não); a aba "Meus contratos" perde o histórico antigo; a regra "contrato fechado nunca sai do livro" (`economy.md`) vira outra. **Testes:** 29 scripts citam o livro; só os que passam de N dias de relógio e leem contrato fechado precisam mudar (a lista sai de `rg` e de uma suíte; NÃO medida).

## 4. Interface sem mensagens enganosas (condição 2)
Auditadas as 43 chaves (`ui.contracts.*` 30 e `economy.contract.*` 13) e seus usos em `contracts_page.gd`, `contracts_view_model.gd`, `abandon_confirm.gd`, `market_view.gd` e `bridge_player_contracts_replies.gd` (não existe `contracts_tab.gd`; a aba é do `market_view.gd`).
- **Trocada (commit a8540fa do ramo `lw107c3-opcao-b`; é a única mudança de texto dele):** `ui.contracts.empty` "Nenhum contrato agora: os mercados estão abastecidos" passou a "Nenhuma encomenda disponível agora.": afirmava uma causa que o jogo não sabe (o quadro também fica vazio antes da 1ª hora cheia, 06:00, na espera do prazo de 48 h, com o mercado sem fundos para a custódia, e o pão acima do alvo é só uma das causas). O teste que fixava o texto (`test_contracts_tab.gd`) foi adaptado no mesmo commit. **Falta levar (só documentos):** `docs/modules/economy.md` linha 153 e `docs/modules/presentation.md` linhas 67 e 68 (a decisão de 14/11 citava a mensagem; o que Arthur aceitou foi o quadro poder ficar vazio) e o item 1 de `docs/economia/LW-107-roteiro-para-arthur.md`.
- **Mantidas (42):** só dizem fatos do estado ou da regra: rótulos e estados (`Aberto`, `Aceito`, `Concluído`, `Vencido`, `Abandonado`; `Falhou` hoje nunca aparece), prazo, recompensa, limite ("n de 3"), custódia ("recompensa devolvida ao emissor" e "sem multa" conferem com `ContractBook.expire` e `abandon`), alcance, estoque do destino e as dicas de aceitar e entregar. Nenhuma promete oferta futura.
- **FORA (dependem de decisão de Arthur):** HUD (sem "n de 3" nem o prazo mais próximo), diário, aviso de nova oferta e de prazo, e qualquer comparação de preço (a tela não diz que a recompensa fica abaixo do custo no emissor nem onde o pão é barato).

## 5. As 5 condições de Arthur e a validação visual
| # | Condição | Estado |
|---|---|---|
| 1 | Resolver ou justificar o pão | **JUSTIFICADA** com números (seção 2.4); opções X, Y e Z; aceitar a escassez ou mandar resolver é dele |
| 2 | Interface sem mensagem enganosa | **FEITA** no texto (`ui.contracts.empty`); falta atualizar 3 documentos; HUD, diário e avisos **pendentes dele** |
| 3 | Crescimento do livro | **MEDIDA** (seção 3); poda proposta, classe 3, pendente dele; desempenho não medido |
| 4 | Testes adaptados sem enfraquecer asserções | **do ramo `lw107c3-opcao-b`** (commit a8540fa: 17 scripts de teste); a tabela de adaptações e a suíte são de lá; não reverificada aqui |
| 5 | Validação visual | **PENDENTE dele** |

**Roteiro da validação visual (usa `docs/economia/LW-107-roteiro-para-arthur.md`, com estes ajustes):** (1) a pasta é o worktree do ramo `lw107c3-opcao-b`, que já traz o dado sem o grão: **não rode o `cp` do passo 2.1**; o `sed` do passo 2.2 (3 abertas, 16 h) continua opcional e só local (sem ele só A e C têm encomenda e o "3 de 3" não aparece); (2) a 1ª encomenda sai às 06:00 em A e em C (a sequência 06:00, 07:00 e 08:00 do roteiro só vale com `max_open` 3); (3) no item 1 da lista o quadro vazio agora diz "Nenhuma encomenda disponível agora."; (4) "cada entrega dá um pequeno prejuízo" vale SÓ comprando no emissor: para ver o ganho, compre 5 pães no mercado B (503 m de A, uns 72 s correndo), volte e entregue (+5 a +23 nas primeiras semanas; some se o pão encarecer nos três); (5) o PR segue RASCUNHO até a autorização escrita dele; desfazer é o `git checkout -- data/economy/contract_templates.json` do roteiro.

## 6. O que NÃO foi verificado
Desempenho (hora cheia com milhares de contratos, carga e gravação do save); a janela do jogo; o robô é um jogador idealizado (sem fome nem sono, trajeto reto, 1 trajeto por vez), então as entregas por dia são um TETO e o ritmo real de esgotamento depende de quanto o jogador joga; os preços COM jogador real e NPCs aceitando (LW-104); os efeitos X e Y (só calculados); os testes e o PR do ramo `lw107c3-opcao-b`; sementes além de 1 a 3 e horizonte além de 30 dias (a extrapolação é linear).
**Reproduzir:** `preparar_copia.sh 6a5da27 <pasta>` com `REPO` e `CACHE_SRC`; `contract_templates.json` da cópia = o `.initial.json` sem a linha do grão; medidor, brutos e analisador em `missao/agente_l2/` do scratchpad da missão (fora do repositório).
