# A demanda final da economia: LW-103 (A) contra a 6ª necessidade (B) (23/11/2026)

**Status:** ANÁLISE (só documento). Pedido de Arthur de 23/11/2026: comparar A (aproveitar a LW-103 do roadmap) e B (criar a 6ª necessidade, que muda o save) em cinco critérios. **Não autoriza implementar nenhuma das duas.** Nenhuma simulação nova: os números vêm do estudo `docs/economia/lw-094a-estudo-21-11.md` (citado como "estudo"), de contas feitas sobre os dados de `data/` e das saídas JÁ medidas do cenário g1 (as três regras de oferta aprovadas, 30 dias, semente 1; scratchpad da força-tarefa, `missao/agente_a/exp/saida/g1__r6__d30__s1.csv`). O que é conta ou hipótese está marcado **[HIP]**.

## 1. Resposta curta (leia primeiro)
1. **A LW-103, como está escrita, não cria demanda final.** Ela mexe na OFERTA: quem produz o quê. Pode tirar gente das cadeias que não têm comprador, mas não dá a ninguém um motivo para gastar. E o sinal que ela usa (o preço) aponta para o lado errado nesta economia (seção 2.2).
2. **A 6ª necessidade cria um motivo de gasto, mas sozinha também não fecha a conta.** Ela só pode gastar a sobra de quem tem sobra. Nas medições do g1, essa sobra é de cerca de **280 moedas por dia**, cerca de 30% das 900 a 1.100 que o estudo pede. O resto depende da peça (iii): o caixa do mercado e o saldo dos mortos.
3. **O que mata a economia é um vazamento de dinheiro, não só a falta de um bem.** Nos dias 20 a 30 do g1:
   - a folha que chega aos NPCs é de 894 moedas por dia, das quais 720 (80%) vêm dos postos, pagos pelo caixa do mercado;
   - o caixa dos mercados cai 220 por dia;
   - o dinheiro dos NPCs vivos SOBE 278 por dia, enquanto eles morrem (62 vivos no dia 20, 52 no dia 30).
   Quem ganha mais do que come (os guardas: 24 por dia contra cerca de 15 de comida) guarda a diferença. Quem não ganha, morre.
4. **Recomendação:** nem B agora, nem A sozinha. Sequência mínima na seção 6:
   - primeiro decidir a peça (iii), que nenhuma das duas resolve;
   - depois a LW-103 com o sinal certo (A1 com A2), que não precisa mudar o save **[HIP]**;
   - por último a "saída da sobra": B ou uma alternativa sem mudança de save (o serviço pago, seção 6), escolhida por UM teste pequeno.

## 2. A: o que a LW-103 prevê (`docs/DEVELOPMENT_ROADMAP.md`, linha 793)
### 2.1 O texto
- **Tarefa:** "Produtores adaptativos: NPCs ajustam o que produzem aos preços, com limite e inércia, para o mundo se reequilibrar sozinho".
- **Depende de** LW-092 e LW-090, as duas no `main`. A LW-110 (o soak econômico de 1 ano) depende dela.
- **Aceite literal:** "com preço alto de um bem, parte dos produtores passa a produzi-lo dentro do limite; sem oscilação a cada dia; determinístico".
- **O que ela NÃO prevê:**
  - nenhum consumo novo, nenhuma necessidade e nenhum destino para o caixa do mercado ou para o saldo do morto;
  - nenhum contrato: o `npc.md` (14.8) a põe "fora desta extensão", e o `economy.md` não tem seção sobre ela.
- **Como ela teria de funcionar hoje:** o NPC não escolhe a receita, porque cada local tem receita fixa (`production_sites.json`). Mudar o que produz é mudar de EMPREGO, pela vaga (LW-096a). Ou é o local que muda a equipe desejada (`workers_wanted`) conforme o preço. Definir isso pede um contrato próprio (uma 103a, só de documento).

### 2.2 O ponto crítico (honesto)
- **O preço não mede quanto trabalho a demanda paga.** Aqui o preço sai da razão entre estoque e alvo (LW-090), não do volume vendido.
- Exemplo do estudo (M2): a ferramenta chega a 78 moedas (3 vezes a base) porque a forja está parada sem dinheiro. Mas toda a manutenção dos 14 locais gasta só cerca de **2,6 ferramentas, 1,75 tábuas e 1,9 tecidos por dia**: cerca de **100 moedas por dia** a valor-base e no máximo 300 no teto **[HIP: conta sobre `site_upkeep.json`, com os 14 locais funcionando]**.
- Uma LW-103 que siga o preço puxaria MAIS gente para a ferramenta, que é o bem de preço alto e volume mínimo. Seria o contrário do que falta.
- **Onde ela ajuda:** com o sinal certo, tira gente dos ofícios sem comprador. As cadeias que não fazem comida empregam 52 NPCs, com folha de cerca de 832 moedas por dia (52 × 2 × 8 h). A capacidade delas é de cerca de 990 moedas por dia de tábua, ferramenta e tecido. A manutenção compra 100 **[HIP: 8 h de produção por dia, 1 lote por hora]**. Sem outro comprador, cerca de 6 a 18 desses 52 bastam.
- **O que ela NÃO resolve:** a sobra que fica guardada (M6), o mercado como sumidouro (M5) e o saldo dos mortos (no t1, 11.108 das 21.520 moedas do mundo ficam presas nos mortos no dia 50). Levar gente para a comida não aumenta a receita da comida, porque a fome não cresce. Só divide a mesma folha entre mais pessoas.

### 2.3 As três variantes dentro do roadmap, sem mudar o save
- **A1, a LW-103 como escrita:**
  - o produtor segue o preço, com limite e inércia;
  - a inércia pode usar o "histórico curto" de preço que o `MarketState` já guarda (LW-090), sem estado novo **[HIP]**;
  - risco: o sinal errado da seção 2.2.
- **A2, a LW-103 com o salário efetivo:**
  - hoje a utilidade do emprego é o salário PROMETIDO vezes 8 horas (`src/sim/npc/employment/npc_employment.gd`, `_utility`, `PAID_HOURS_PER_DAY = 8`);
  - quem está num local parado não sai, porque a vaga só abre quando alguém morre (M7);
  - A2 avalia se o local de fato paga. Uma forma sem estado novo é ler se o local está parado por `NO_FUNDS` ou `OUTPUT_FULL` (o motivo já vai no save) **[HIP]**;
  - **A2 sozinha não move ninguém:** sem vaga aberta num local que paga, não há para onde ir. Ela precisa que a LW-103 abra e feche vagas (a equipe desejada se adapta). Por isso A1 e A2 andam juntas.
- **A3, o consumo e as atividades que já existem:** a tabela abaixo dá o que cada um devolve ao mercado, em ordem de grandeza.

| Fonte | Moedas por dia | Por quê | Evidência |
|---|---|---|---|
| Comida (`eat`, `buy`) | 2.000 a 2.500 | já conta; não cresce, porque a fome é fixa | estudo, seção 1.6 |
| Manutenção dos locais | cerca de 100 (até 300 no teto) | 14 locais; 10 vezes mais já falhou (c1 a c4) | `site_upkeep.json`; estudo, seção 9 |
| Comerciantes (LW-098) | perto de 0 de demanda final | só levam bens de um mercado a outro; morrem até o dia 30 | estudo, M8 e seção 10 |
| Encomendas do jogador (LW-107) | dezenas, no máximo | recompensa limitada a `ask` × lote; até 3 aceitas; mexeu em 4 das 82 colunas do medidor | `lw-107c3-decisao-23-11.md` |
| Compras do jogador (LW-105) | perto de 0 | o jogador não consome bens; o artesanato do jogador é "não fazer" (3.J) | roadmap, 3.J |
| Postos de serviço | 720 de SAÍDA do mercado | é o único retorno grande; esvazia o caixa (-220 por dia no g1) | CSV do g1 |

**Conclusão de A3:** nada disso chega perto de 900 a 1.100 por dia. O que vem do jogador não conta para o aceite da LW-094, que é a vida SEM jogador.

## 3. B: o que muda de fato com a 6ª necessidade
### 3.1 O que muda no código, no save e nos testes
- **Estado e save:**
  - `NpcState.NEED_COUNT` passa de 5 a 6 (`src/sim/npc/state/npc_state.gd`, linha 10). As listas `need_values` e `need_remainders` do bloco do `npc` no save passam a ter 6 números.
  - `NpcState.parse` recusa a lista de tamanho errado. Assim, **todo save feito antes deixa de abrir**, com a mensagem "lista de 6 inteiros".
  - Isso é coerente com a DEC-134 (o save não é congelado; o save antigo é rejeitado com mensagem clara).
  - Mas o AGENTS.md, item 15, diz ao mesmo tempo "mudou o estado salvo, atualize `save_version`" e "o `save_version` fica em 2 (DEC-127)". **Arthur teria de dizer qual dos dois vale.**
  - A proteção do PR #138 (casa ou local inexistente) não muda.
- **Dados:**
  - uma linha nova em `data/needs.json`, que é dado protegido fora do escopo;
  - `need_id` e `need_relief` em `goods.json` para ferramenta, tábua e tecido;
  - uma ação nova de uso (por exemplo "consertar" ou "vestir");
  - o valor derivado da compra (`buy`, DEC-143) estendido a bens que não são comida.
- **Decisões e documentos:**
  - CONTRARIA duas decisões APROVADAS. A DEC-153 diz "o NPC só consome comida na Fase 3". A DEC-163 diz "roupa e ferramenta pessoal ficam fora". As duas vêm da Q20, decidida pelo próprio Arthur (`npc.md`, 14.9).
  - Toca o `TECHNICAL_ARCHITECTURE.md` 9.2, protegido, que diz "Necessidades do protótipo: fome, descanso, segurança, renda, social. Outras vêm depois".
  - Toca o `npc.md` (seções 2 e 14.3) e o `economy.md`.
  - Pelo AGENTS.md 16.2, contrariar uma APROVADA e mexer em arquivo protegido obriga a PARAR e perguntar. As REGRAS da missão a tratam como proibida sem ordem expressa (classe 4).
- **Testes e referências:**
  - 51 dos 357 scripts de teste citam as necessidades (`need_values`, `NEED_COUNT` ou `needs.json`; teto por busca, não conferido um a um);
  - mudam o oráculo (`test_npc_split_oracle`) e o hash do soak de 30 dias, com o rito da DEC-175.
- **O que se vê no jogo:**
  - NPCs vão ao mercado comprar ferramenta, tecido e tábua e os "usam" em casa;
  - as cadeias de artesão ganham comprador final;
  - o jogador pode vender a NPCs comuns.

### 3.2 O que a necessidade teria de fazer para devolver 900 a 1.100 por dia (sem simular)
- **Gasto médio:** cerca de 7 moedas por NPC por dia (138 NPCs).
- **Exemplo de números:** uma taxa de subida de 2 pontos por hora (48 por dia), aliviada por bem em proporção ao valor-base, cerca de 6 pontos por moeda. Isso dá perto de 8 moedas por dia **[HIP]**.
- **Um bem só não basta.** Só com tecido seriam cerca de 110 tecidos por dia, contra uma capacidade de 32. O consumo tem de se repartir pela capacidade das três cadeias: por NPC e por dia, cerca de 0,23 tábua, 0,12 ferramenta e 0,23 tecido.
- **Não pode matar.** Como a renda, a necessidade tem de pesar pouco e não ser letal (`lethal_after_hours` 0). Quem só tem para a comida não compra, e quem tem sobra compra. É esse o efeito econômico desejado: dar destino à sobra.
- **Risco conhecido:** a compra do NPC disputa com a manutenção dos locais (16 ferramentas por dia contra 2,6). Seria preciso uma regra de prioridade, ou as fazendas perdem eficiência (estudo, seção 1.5).
- **O limite real:** B só gasta o que alguém tem sobrando. No g1 isso são cerca de 280 por dia. O estudo mostra que gastar a sobra sem consertar (iii) falha: o z1, com as três regras de oferta e o consumo pela sobra, termina com 25 vivos. O dinheiro vai para o caixa do mercado, que vende estoque que ninguém repõe.

## 4. Comparação objetiva

| Critério | A1 (LW-103 escrita) | A2 (A1 + salário efetivo) | A3 (o que já existe) | B (6ª necessidade) |
|---|---|---|---|---|
| **Compatibilidade** (save, contratos, classes) | sem save novo **[HIP]**; contrato novo (103a); classe 3 | igual a A1; muda a utilidade de `npc_employment` (classe 3) | nada muda | **save rejeitado**; contraria DEC-153 e DEC-163; arquivo protegido (arquitetura 9.2, `needs.json`); classe 4 |
| **Gameplay** | NPCs trocam de ofício; menos artesãos | idem, e ninguém fica preso num local parado | jogador como comprador e encomendante; o mundo sem jogador igual | NPCs consomem bens de uso; os artesãos têm razão de existir; o jogador vende a NPCs |
| **Complexidade** | média: contrato, vagas que se adaptam, inércia, testes de oscilação | média: mais uma regra em A1 | nenhuma | alta: `npc` e `economy`, ações, dados, cerca de 51 testes afetados, hashes, prioridade contra a manutenção |
| **(i) sumidouro de consumo** | não cobre | não cobre | não cobre (100 a 300 contra 900 a 1.100) | cobre o motivo; o volume fica limitado à sobra (cerca de 280 medidos) |
| **(ii) oferta que funciona** | ajuda (quantos trabalham); risco do sinal de preço | ajuda mais (realoca pelo que é pago) | não | não (as três regras aprovadas já cobrem) |
| **(iii) caixa do mercado e saldo do morto** | não | não | não (os postos só esvaziam) | não |
| **Roadmap** | LW-103 numerada, dependências cumpridas, antes da LW-110 | cabe na LW-103 ou como ajuste da LW-096a | LW-105 e LW-107 já existem | nenhuma tarefa; muda roadmap, DECISIONS, arquitetura, `npc.md` e `economy.md` |

**Evidência e hipótese:**
- **Medido:** estudo, seções 1, 4 e 9; CSV do g1; `npc_employment.gd`; `npc_state.gd`; DEC-153 e DEC-163; roadmap, linhas 793 e 936.
- **Hipótese:** as 8 h de produção; que A1 e A2 dispensam estado novo; os números da seção 3.2; o teto de 6 a 18 artesãos.

## 5. Por que nenhuma das duas fecha sozinha (a conta do dinheiro)
- **A conta:** o mundo tem 21.520 moedas fixas (no início, 9.720 com os NPCs, 2.800 com os locais e 9.000 com os mercados; conferência ok em todas as execuções). Para 138 NPCs viverem, o dinheiro que eles gastam em comida tem de VOLTAR a eles todo dia, como folha, lucro ou posto, e eles têm de gastá-lo.
- **Ele deixa de voltar por quatro caminhos:**
  - o local guarda o lucro (M4: a folha é 25% do grão);
  - o mercado guarda a venda do estoque inicial e o spread (M5);
  - quem ganha acima da comida guarda a sobra (M6: os +278 por dia do g1);
  - o morto prende o saldo.
- **Os preços e os salários não se ajustam para baixo.** O preço tem piso e o salário por negociação é "não fazer" (3.J). Então cada moeda guardada é uma moeda a menos para quem precisa comer.
- **O que cada alternativa fecha:** A cuida de QUEM recebe, não de QUANTO volta. B fecha o terceiro caminho, mas não os outros. A peça (iii) fecha o segundo e o quarto.

## 6. Recomendação e sequência mínima
**Recomendação:**
- Não criar a 6ª necessidade agora e não esperar que a LW-103 resolva a demanda.
- A combinação que o roadmap permite é a LW-103 com o sinal do salário efetivo (A1 com A2), para a OFERTA. Ela fica junto da decisão sobre a peça (iii), que nenhuma alternativa evita.
- A "saída da sobra" (i) se decide depois, entre B e uma alternativa sem mudança de save, escolhida pelo teste pequeno abaixo.
- Assim, a mudança de save só entra se o teste mostrar que ela é necessária.

| Passo | O que é | Decisão de Arthur |
|---|---|---|
| 1 | as três regras de oferta (já aprovadas) | já tomada |
| 2 | peça (iii): saída do caixa do mercado acima de uma reserva e destino do saldo do morto | regra de design nova; o destino do saldo do morto mexe na DEC-146 e encosta em "herança é não fazer" (3.J) |
| 3 | contrato 103a: LW-103 com vagas que se adaptam e a utilidade pelo salário efetivo (A1 com A2) | aprovar o contrato e o sinal (salário pago, não só o preço); classe 3, sem save **[HIP]** |
| 4 | teste H-K, abaixo (uma rodada) | autorizar um protótipo em cópia |
| 5 | se o H-K passar: o serviço pago (sem save). Se falhar: B (com save) | B pede revogar DEC-153 e DEC-163, mudar a arquitetura 9.2 e decidir o `save_version` |

**Hipótese nova e testável (H-K, "o serviço pago na estalagem"):**
- **A ideia:** no g1, a sobra que vaza é quase toda a dos postos. São 30 postos (18 guardas e 12 estalajadeiros) com cerca de 9 moedas por dia de sobra cada, cerca de 270 por dia, contra os +278 medidos.
- Uma saída ligada a uma necessidade que JÁ existe faria os postos se pagarem sozinhos. Por exemplo: `talk` (social) ou `rest` (descanso) no local social passam a custar uma taxa pequena, paga ao caixa do mercado, que é quem paga os postos. Quem tem sobra paga; quem não tem não usa (o preço já desconta a utilidade da compra, DEC-143). Não muda o save, porque a cobrança acontece no fim da ação, sem estado novo **[HIP]**.
- **O teste:** uma rodada de 30 dias, semente 1, numa cópia do g1, com um protótipo de cerca de 20 linhas.
- **Passa se**, nos dias 20 a 30:
  - o caixa dos mercados cai menos de 50 por dia (hoje cai 220);
  - o dinheiro dos NPCs vivos sobe menos de 50 por dia (hoje sobe 278);
  - as conferências de dinheiro e de bens dão ok.
- **Se passar:** a sobra tem destino sem save novo, e B deixa de ser necessária para (i) no nível dos postos.
- **Se falhar:** é o argumento para B.
- **Limites:** ele NÃO paga os 52 artesãos (isso é o passo 3) nem prova 138 vivos. Também é design novo: os serviços como sumidouro estão no GDD 12.3 como proposta, mas não são tarefa do roadmap.

## 7. O que NÃO se sabe
- Se a LW-103 (A1 com A2) dispensa mesmo estado novo no save, e quantos artesãos sobram no equilíbrio (6 a 18 é conta, não medição).
- As horas reais de produção por dia: a conta usa 8, como a constante de `npc_employment.gd`.
- Como B se comportaria de verdade (nunca implementada nem medida), inclusive a disputa com a manutenção.
- Se a peça (iii) sozinha, com as três regras, já levaria a economia muito além dos 52 vivos do g1 (não medido).
- Os números do g1 são de 1 semente, 30 dias, em debug. Os 90 dias só existem para o t1 e o b4 (estudo, seção 10).
- O dado de 51 testes afetados é um teto por busca de texto, não uma lista conferida.
