# LW-094a: o estudo de calibração coordenada da economia sem o `FoodStub` (21/11/2026)

**Status:** ESTUDO (só documento). Autorização de Arthur (21/11/2026): "AUTORIZO o estudo de calibração coordenada LW-094a em cópias isoladas". Nenhuma regra, dado, código, referência, hash ou save do repositório mudou; tudo foi medido em CÓPIAS descartáveis do `main` `80db928`, só `--headless`, com o fim do stub emulado por dado (`food_stub.json`: `start_stock` 0, `max_stock` 1, `work_yield` 0). Tudo que aparece aqui como regra é PROPOSTA para ele aprovar. Continua o diagnóstico `docs/economia/lw-094-diagnostico-18-11.md` (não refeito). Termos: **vivos d7/d14/d30** = vivos dos 138 nos dias 7, 14 e 30; **base t1** = sem stub + regra da refeição (fome ≥ 40) + os 6 postos + lotes por trabalhador + comida de 30 dias do C (o melhor cenário do diagnóstico, 138/60/50).

## 1. Resultado (leia primeiro)
1. **Nenhuma calibração no nível do mercado fecha a LW-094.** Foram 37 cenários de 30 dias (semente 1). Além do t1, só um pacote passa de 60 vivos no dia 30: **b4**, com o teto de compra no alvo, o lucro dos locais repartido e o "tesouro do povoado". Ele dá **61, 62 e 65** nas sementes 1 a 3. Em **90 dias ele NÃO é estacionário**: 51 no d40, 35 no d50 e 34 do d60 ao d90 (o B morre inteiro).
2. **O t1 também não é estacionário:** os seus 50 do d30 caem para 24 no d40 e 8 no d50, e ficam em 8 até o d90, com 11.108 moedas presas nas contas dos mortos.
3. **Cinco mecanismos provados por censo** (seção 4) explicam o "equilíbrio de 50" do diagnóstico. Os 50 são os 30 dos postos mais a **primeira** fazenda do A (12) e a **primeira** do B (8).
   - (a) **Ordem fixa dos locais por ID:** a 1ª de duas fazendas iguais enche o teto de compra; a 2ª nunca vende.
   - (b) **NO_FUNDS absorvente:** sem a folha inteira de uma hora o local para, e só ganharia dinheiro produzindo.
   - (c) **O local paga folha para produzir para o próprio estoque**, sem comprador, e queima o capital de 200 em 1 a 3 dias.
   - (d) **A folha é 1 moeda por grão (25% do valor-base):** a comida devolve em salário só um quarto do que custa.
   - (e) **O MERCADO é um sumidouro de mão única:** vende o estoque inicial e o importado sem recomprar de um produtor vivo, embolsa o spread, e só os postos devolvem dinheiro. O caixa dos mercados vai de 9.000 a 12.000 a 20.000 em todos os cenários que aumentam as compras.
4. **Corrigir a oferta não basta.** Rodízio, folha parcial e "produzir só com comprador" corrigem (a) a (c), mas sozinhos dão 50 a 52: sem procura final, o local não quebra, mas também não paga ninguém.
5. **Corrigir a procura também não basta.** Manutenção 10 vezes maior, consumo doméstico pelo excedente, tesouro e salário pelo valor agregado dão de 2 a 61. Cada compra nova no mercado engorda o caixa dele (mecanismo e). A manutenção maior compete com a dos locais por ferramenta e tábua que ninguém mais fabrica, e as fazendas perdem eficiência.
6. **A conclusão é estrutural, com evidência.** Nesta economia fechada o único bem final é a comida, cerca de 2.000 a 2.500 moedas por dia para 138 NPCs. O sistema só fica estacionário com três peças JUNTAS:
   - (i) um **sumidouro de consumo além da comida**, do tamanho da folha dos ofícios que não fazem comida (cerca de 900 a 1.100 moedas por dia) e pago por quem hoje entesoura (guardas com 24 por dia contra cerca de 15 de comida; lavradores com lucro);
   - (ii) uma **oferta que funcione** (ordem justa, folha parcial, produzir para quem compra);
   - (iii) o **caixa do mercado em equilíbrio**: o que ele recebe pela venda de estoque que ninguém produziu tem de voltar à economia.
7. **Recomendação:** NÃO remover o `FoodStub` agora (Mandato 1 mantido).
   - Aprovar como **regras de oferta**, pequenas e sem estado novo: o rodízio da ordem dos locais e da equipe pela hora do relógio, a folha parcial e "produzir só com comprador".
   - **Decidir** o sumidouro de consumo. A forma honesta é a 6ª necessidade (classe 4, muda o save) ou a realocação de ocupação da LW-103. Ver seção 7.
8. **O que NÃO foi provado:** a combinação de (i), (ii) e (iii) com a 6ª necessidade de verdade, que exige save novo e não foi implementada; os 90 dias nas sementes 2 e 3; o desempenho. Ver seção 10.

## 2. Método
- **Cópias:** `git archive origin/main` com o medidor (`docs/economia/experimentos/preparar_copia.sh`) e cenários próprios fora do repositório (`missao/agente_a/exp/cenarios_a.sh` no scratchpad da sessão).
- **Execução:** uma sessão do Godot por semente (`tools/measure_economy --days N --seed S --markets`), no máximo 4 ao mesmo tempo. O censo por ofício, estado dos locais e caixa dos mercados vem do roteiro descartável `censo.gd`.
- **Conferências:** a de dinheiro e a de bens (`money_ok` e `goods_ok`) deram ok em TODAS as execuções.
- **Determinismo:** a reprodução do t1 (a_t1) deu números idênticos aos do diagnóstico de 18/11 (d7: NPCs 8.411, locais 543, mercados 12.566).
- **Horizontes:** 30 dias na triagem. Os 7 dias não separam os cenários, porque a onda de mortes começa no dia 9 ou 10. O finalista e o t1 foram a 90 dias; o finalista também nas sementes 2 e 3.
- **Protótipos de código:** em `patches/*.patch` no scratchpad (tesouro, lucro, parcial, rodizio, encomenda, consumo). Os de dado são filtros `jq` em `cenarios_a.sh`.

## 3. Tabela (vivos d7/d14/d30; sementes 1 a 3 quando indicadas; A/B/C no d30)
| Cenário | O que muda sobre o t1 | Vivos | d30 A/B/C | Caixa dos mercados d30 |
|---|---|---|---|---|
| a_t1 (t1) | nada (referência) | 138/60/50 | 26/16/8 | 11.272 |
| a_t | + tesouro (o excedente do mercado acima de 3.000 vira consumo de tábua, ferramenta e tecido) | 138/72/35 | 26/1/8 | 11.199 |
| a_l | + lucro do local acima de 200 repartido com a equipe | 138/68/50 | 26/16/8 | 11.518 |
| a_tl | + tesouro + lucro | 138/71/11 | 3/0/8 | 11.168 |
| b1 | + teto de compra = alvo (os estoques de reserva ficam em 2x) | 120/56/50 | 26/16/8 | 9.874 |
| b2 | + teto 1,2x | 138/56/50 | 26/16/8 | 9.209 |
| b3 | b1 + lucro | 120/56/50 | 26/16/8 | 9.932 |
| **b4 s1 / s2 / s3** | **b1 + lucro + tesouro** | **127/84/61 · 128/84/62 · 129/84/65** | 26/25/10 · 26/23/13 · 26/25/14 | 7.542 · 7.599 · 7.638 |
| c1 a c4 | b1 + manutenção 10x (com e sem tesouro e lucro) | 120-127/56/50 | 26/16/8 | 9.229-12.794 |
| d1 a d4 | + folha parcial (H-P) + rodízio da ordem (H-R), com e sem teto e manutenção | 121-138/56-76/50-55 | — | 10.590-14.393 |
| e1 a e4 | + salário pelo valor agregado (2 a 5 por hora por receita) | 123-130/60-65/2-26 | — | 17.370-19.687 |
| g1 | + produzir só com comprador (H-E) + rodízio + parcial | 138/62/52 | 27/17/8 | 9.585 |
| g2 a g4 | g1 + teto (+ salário, + manutenção) | 90-110/56/8-50 | — | 8.438-20.519 |
| g5 a g8 | g1 + tesouro (reserva 1.000 ou 3.000; com e sem manutenção e teto) | 101-138/50-76/8-53 | — | 10.751-16.714 |
| k1 a k4 | + consumo doméstico pelo excedente (H-D: quem tem mais de 60 ou 100 compra 1 bem final por dia) | 90-138/56-70/8-50 | — | 9.745-17.954 |
| z1 | teto + H-E + H-R + H-P + lucro + tesouro + H-D | 122/89/25 | 0/16/9 | 15.760 |
| z2 / z3 | teto + lucro + tesouro + H-D / + H-R | 123/84/61 · 128/81/60 | 26/26/9 · 26/17/17 | 10.303 · 7.747 |
| h1 | rebalanceamento só de dados: a 2ª fazenda do A e do B vira posto de guarda (20 guardas a mais) | 138/80/34 | 2/24/8 | 5.962 |

**90 dias (semente 1):**
| Cenário | d30 | d40 | d50 | d60 | d90 | Presas nos mortos | Mercados (d0, d30, d90) |
|---|---|---|---|---|---|---|---|
| t1 | 50 | 24 | 8 | 8 | 8 | 11.108 | 9.000 / 11.272 / 10.124 |
| b4 | 61 | 51 | 35 | 34 | 34 | 6.166 | 9.000 / 7.542 / 6.194 (d40: 5.121) |

No b4, os NPCs vivos têm 12.530 moedas no d30 e 14.166 no d40, concentradas nos lavradores: a média dos vivos é 360 no A e 408 no B no d30, contra 182 dos guardas. A população cai mesmo com dinheiro sobrando no mundo, porque ele está com quem não gasta.

**Por ofício (b4, semente 1, censo do d30):**
- A: lavradores 12/24 (saldo médio 360), guardas 8/8 (182), estalajadeiros 6/6 (179), artesãos 0/12, lenhadores 0/10, comerciantes 0/2.
- B: lavradores 8/16 (408), artesãos 4/8 (1), pastores 4/4 (3), guardas 5/5, estalajadeiros 3/3, lenhadores 0/8, comerciantes 1/2.
- C: artesãos 2/12, mineiros 0/8, guardas 5/5 (26), estalajadeiros 3/3 (26), comerciantes 0/2.
- Os sobreviventes extras do b4 em relação ao t1 são os artesãos e pastores do B, por pouco tempo. Morrem até o d50.

## 4. Os mecanismos (evidência)
**M1. A ordem fixa por ID** (`ProductionBook.hour_step` anda em `site_ids()`, crescente).
- No c2, no dia 3, a fazenda 1 do A está rodando com 1.174 moedas e a fazenda 2 em NO_FUNDS com 0; no dia 7, 1.679 contra 0.
- No B: 557 contra 8.
- Os lavradores da 2ª fazenda morrem: são os 12 + 8 que faltam nos 50.

**M2. NO_FUNDS absorvente** (a folha é tudo ou nada, DEC-169 e R8-M1).
- No c2, no dia 30: ferramenta a 78, tábua a 24 e tecido a 30, com estoque 0 nos três mercados. Os locais que os fazem estão parados, com 0 a 63 moedas.
- No a_t, no B, o grão chega a 12 e a fazenda com 12 moedas não volta (a folha de 8 trabalhadores é 16 por hora). Morrem até guardas com mais de 200 moedas, por falta física de comida.

**M3. Folha paga para o próprio estoque.** O local só para por OUTPUT_FULL quando o PRÓPRIO inventário (400 de peso) enche, e não quando o mercado já está cheio. No censo do t1, no dia 7, 12 dos 14 locais estão com 0 a 36 moedas.

**M4. A participação do trabalho é fixa e pequena:** grão = 1 moeda de folha (4 lavradores × 2 ÷ 8 grãos); pão = cerca de 3 (grão, farinha e forno).
- No A: consumo de cerca de 248 grãos por dia × 1 moeda = 248 de folha, contra cerca de 20 por dia de comida de cada lavrador. Isso dá **12 lavradores**: o mesmo número medido.
- Subir o preço (teto = alvo) só aumenta o lucro do local, e não a folha.
- Subir o salário (e1 a e4) leva os locais a NO_FUNDS e o caixa dos mercados a 17 a 20 mil.

**M5. O mercado é o sumidouro.**
- Ele recebe pela venda do estoque inicial (C: 1.600 pães; B: 1.620 farinhas; ferramentas iniciais) e pelo spread, que tem piso de 1 moeda: no preço de piso compra o grão a 1 e vende a 3.
- A única saída do caixa, além de repor estoque de produtor vivo, é a folha dos postos (720 por dia).
- No t1: +3.566 em 7 dias.
- **Toda compra nova no mercado de bem que nenhum produtor vivo repõe é dinheiro que sai da circulação:** consumo k1 e k2, até 16.662 e 17.954; manutenção c1 e c4; tesouro g6, até 17.797.

**M6. Entesouramento.** Os guardas recebem 24 por dia (o posto paga as 24 horas) e comem cerca de 15. O lucro repartido fica com os lavradores: no b4, média de 360 a 408. Sem outro bem para comprar, esse dinheiro sai de circulação.

**M7. O mercado de trabalho não realoca.** A vaga só abre com morte, e o NPC compara o salário NOMINAL (salário por hora × 8 h, `npc_employment.gd`), não o que de fato recebe: ninguém sai do local parado.

**M8. Becos sem comprador local:** a farinha do A (o A não tem padaria) e a lenha do B (o B não tem serraria) dependem só dos comerciantes, que morrem até o d30 na maior parte dos cenários.

## 4.1 Defeito de regra ou escolha de design? (pedido de Arthur de 23/11/2026)
| Mecanismo | Natureza | Corrige com | Muda save? |
|---|---|---|---|
| (a) ordem fixa dos locais por ID na hora | **defeito de regra** (viés determinístico: o de ID menor sempre vende primeiro) | rodízio pela hora absoluta do relógio (H-R) | não |
| (b) `NO_FUNDS` absorvente (folha inteira ou nada) | **escolha de design** (DEC-169: parar e não demitir) com efeito colateral não previsto (armadilha de liquidez) | folha parcial por equipe de lote (H-P), rodízio pela hora | não |
| (c) o local produz e paga folha para o próprio estoque, sem comprador | **defeito de regra** (produção incondicional à procura) | produzir só com comprador (H-E) | não |
| (d) folha de 1 moeda por grão (25% do valor-base) | **escolha de dado** (receitas e valores-base; a regra de margem do carregador limita o salário) | recalibração conjunta de valores e salários (não basta sozinha) | não |
| (e) o mercado é sumidouro de mão única (vende estoque inicial, embolsa o spread, só os postos devolvem) | **limitação estrutural de design** (falta o sumidouro de consumo e a circulação do caixa; Fase 4 prevê tributo e sumidouros) | sumidouro de consumo (6ª necessidade ou LW-103) e equilíbrio do caixa | a 6ª necessidade sim |
| (f) vaga só abre com morte e o NPC compara o salário nominal | **defeito de regra** (`npc_employment.gd` avalia o que o local promete, não o que paga) | avaliar o salário efetivo | não |
| (g) becos sem comprador local (farinha do A, lenha do B) | **escolha de dado** (cadeias e povoados) | dados de produção e rotas | não |
**Resumo:** quatro itens são defeitos de regra ou de rotação (a, c, f, e a armadilha de b), corrigíveis sem estado novo no save e com o rito da DEC-175; dois são escolhas de dado (d, g); um é estrutural (e) e é decisão de design de Arthur.

## 5. As 9 perguntas de Arthur (respondidas para o finalista b4 e, em seguida, para o pacote estrutural da seção 7)
1. **Quem compra o produto?**
   - b4: os NPCs compram a comida; os locais compram insumos e manutenção; o "povoado" consome tábua, ferramenta e tecido com o excedente do caixa do mercado.
   - Pacote: os NPCs, com o salário, compram também os bens finais de uso doméstico.
2. **Por que precisa dele?**
   - Comida: a fome.
   - Bens finais: no b4, um uso abstrato do povoado (obras e reparos). No pacote, a necessidade de uso: roupa, ferramenta da casa, reparo. Sem uma necessidade, a compra é arbitrária, e foi o que falhou (k1 a k4).
3. **De onde vem o dinheiro?** Só do que já circula: nenhum cenário cria dinheiro (conferência ok). No b4, do spread e da venda de estoque pelo mercado (o tesouro) e do lucro do local (o repartido). No pacote, do salário de quem hoje entesoura.
4. **Quem recebe a receita?** O mercado, na venda; o local, quando o mercado repõe; os trabalhadores, pela folha e pelo lucro repartido.
   - No b4 o lucro repartido fica com os lavradores e o tesouro paga sobretudo quem repõe estoque. Quem faz o bem final quase não recebe, porque a oferta já morreu (M2).
5. **Como ela financia novos ciclos?** Pela folha, que vira compra de comida. No b4 o ciclo fecha só para a comida e os postos: o ciclo de tábua, ferramenta e tecido não tem fornecedor vivo depois do dia 10.
6. **O que acontece quando a demanda cai?**
   - Hoje: o local enche o próprio estoque pagando a folha e quebra (M3), e nunca volta (M2).
   - Com H-E e H-P: para sem queimar capital e volta pela folha parcial quando há compra.
   - No b4: a demanda cai junto com as mortes e o caixa do mercado esvazia (9.000, 7.542 no d30, 5.121 no d40).
7. **Como o sistema reage à escassez?** O preço sobe até o teto (3x a base): ferramenta a 78. Mas a oferta não responde, porque o local está em NO_FUNDS (M2) e o trabalhador não muda de emprego (M7). A escassez vira morte, não produção.
8. **O que impede acúmulo ou desaparecimento artificial de recursos?**
   - Nada nos cenários: o dinheiro se acumula no mercado (M5), nos guardas e nos lavradores (M6) e nos mortos (6 a 11 mil).
   - O pacote proposto ataca os três: o consumo pago pelo saldo acima de uma reserva; o caixa do mercado com saída proporcional; e a herança ou destino do saldo do morto (proposta a decidir, seção 7).
9. **O comportamento continua estável após muitos dias?** NÃO. t1: 50, 24, 8 (d30, d40, d50). b4: 61, 51, 35, 34 (d30 a d60), e então fica estável só com A e C reduzidos (26 + 8), com 6.166 moedas presas nos mortos.

## 6. Custo de cada alternativa
| Alternativa | Dado protegido | Regra de código | Save | Efeito medido |
|---|---|---|---|---|
| Regra da refeição (B8) | 1 linha em `action_conditions.json` | não | não | já no t1 (necessária) |
| Teto de compra = alvo (H-C) | `market_targets.json` (`buy_cap_bp`; os estoques de reserva ficam em 2x por exigência do carregador) | não | não | muda o preço do piso para a base (sozinha: 50) |
| Manutenção 10x (H-M) | `site_upkeep.json` | não | não | 50 (compete pelo bem que falta) |
| Salário pelo valor agregado (H-S) | `recipes.json` (dentro da regra de margem do carregador) | não | não | 2 a 26 (pior) |
| Lucro repartido (H-L) | parâmetro de reserva (novo dado) | `close_day` da economia (~10 linhas) | não (usa o saldo existente) | vai para quem entesoura |
| Tesouro do povoado (H-T) | reserva e ritmo (novo dado) | `close_day` (~13 linhas) | não | 35 a 61 |
| Rodízio da ordem (H-R) | não | `ProductionBook.hour_step` (~8 linhas) | **não, se a rotação vier da hora absoluta do relógio** (o módulo já tem `_last_hour`); o protótipo usou um contador, que não vai para o save e se perderia ao carregar | sozinho: 50 a 52 |
| Folha parcial (H-P) | não | `hour_step` (~14 linhas); muda o "tudo ou nada" (R8-M1, DEC-169) | não, com o rodízio da equipe pela hora absoluta | idem |
| Produzir só com comprador (H-E) | não | `_stop_reason` (~6 linhas) | não | os locais guardam o capital (g1: 2.117 contra 543 no d7) |
| Consumo pelo excedente sem necessidade (H-D) | limiar (novo dado) | `close_day` (~25 linhas) | não | pior (o dinheiro vai para o caixa do mercado) |
| Rebalanceamento de população (h1) | `population.json`, `production_sites.json` e `service_posts.json` (a capacidade do local limita a linha de população) | não | não | 34 (os postos esvaziam o caixa: 5.962) |
| **6ª necessidade (uso de bens)** | `needs.json`, `goods.json` (alívio), ações | NPC e economia; `NpcState.NEED_COUNT` | **classe 4: muda o formato do save** | NÃO medido |
| Realocação de ocupação (LW-103) | rotina e ofícios por dado | `npc_employment` (utilidade pelo salário REALMENTE recebido) | provável estado novo do salário recente (a avaliar) | NÃO medido |

## 7. Recomendação
1. **Manter o `FoodStub`** (Mandato 1) e o critério da LW-094: 138 vivos em 30 dias, sem máscara. O estudo mostra que esse critério não se alcança só com calibração no nível do mercado.
2. **Aprovar, como regras de OFERTA (independentes do resto, pequenas e sem estado novo):**
   - H-R, o rodízio da ordem dos locais pela hora absoluta;
   - H-P, a folha parcial por equipe de lote, com rodízio pela hora;
   - H-E, produzir só com comprador.
   Elas corrigem M1 a M3, que são defeitos de regra, não de calibração. Mudam hashes e referências e precisam do rito da DEC-175.
3. **Decidir o SUMIDOURO (decisão de Arthur):**
   - (a) a **6ª necessidade "uso"**: tecido, ferramenta e tábua consumidos pelo NPC, com alívio por dado e o custo da classe 4 no save. É a única forma causal de pagar os 52 ofícios que não fazem comida.
   - (b) **reduzir a força de trabalho sem comprador** (LW-103, realocação pelo salário real, ou um rebalanceamento da população), aceitando um mundo com menos artesãos.
   - (c) uma combinação das duas.
   Junto com qualquer uma, decidir o **equilíbrio do caixa do mercado** (por exemplo, a saída do excedente acima da reserva como folha de postos ou compra de produtor local) e o **destino do saldo do NPC morto** (hoje preso).
4. **Ordem proposta:** LW-095 (postos) → as regras de oferta (H-R, H-P, H-E) → o estudo do sumidouro (a ou b) em cópias → a remoção do stub.

## 8. Rascunho do contrato para Arthur aprovar (como a 098h)
- **098a-1 (regras de oferta):**
  - A ordem dos locais na hora gira pela hora absoluta (`hora mod n`).
  - O local que não cobre a folha inteira paga as equipes de lote que consegue, em rodízio pela hora absoluta.
  - O local para por OUTPUT_FULL quando já tem um lote sem comprador e o mercado não tem espaço no teto de compra.
  - Sem estado novo no save.
  - Testes novos: duas fazendas iguais vendem nas mesmas horas (±1); um local com saldo de uma equipe volta a produzir; nenhum local paga folha com o mercado cheio e um lote parado.
  - Aceite: conferências ok, determinismo em duas execuções, e as referências antigas, novas e a causa pela DEC-175 antes de qualquer hash.
- **098a-2 (sumidouro, só depois da decisão da seção 7):** o estudo em cópias da 6ª necessidade ou da realocação, com 90 dias em 3 sementes. Aceite: 138 vivos no d30 e população estável do d30 ao d90 (sem tendência de queda), caixa dos mercados dentro de ±20% do inicial, menos de 5% do dinheiro em mortos, nenhuma máscara (sem folha parada, capital extra ou comprador ilimitado).
- **Proibido** em ambos: criar dinheiro ou comida, pagar hora parada, afrouxar a sobrevivência.

## 9. O que foi testado e descartado (não repetir)
- O tesouro sozinho e o tesouro com produção sob encomenda: os bens consumidos são os que a manutenção dos locais precisa, e as fazendas perdem eficiência.
- O salário pelo valor agregado: sem procura, a folha maior só leva a NO_FUNDS mais cedo.
- O consumo doméstico sem necessidade: o dinheiro vai para o mercado, que vende estoque que ninguém repõe.
- A manutenção 10x.
- O rebalanceamento só de postos: o caixa do mercado não sustenta 50 postos (5.962 no d30).

## 10. O que NÃO foi provado
- A 6ª necessidade e a realocação (LW-103): não implementadas nem medidas, porque exigem save novo ou decisão de regra.
- A rotação pela hora ABSOLUTA: os protótipos H-R e H-P usam um contador interno, que dá a mesma sequência num jogo novo. A equivalência ao carregar um save não foi testada.
- Os 90 dias só na semente 1. As sementes 2 e 3 só para o b4, em 30 dias. Os cenários c a z só na semente 1.
- Medições em debug, funcionais, sem desempenho.
- Os comerciantes não foram analisados por viagem; só se sabe que morrem até o d30 na maioria dos cenários.
- O rebalanceamento h1 é um teste de limite, não uma proposta de jogo.
- Roteiros, saídas e `.patch` ficam no scratchpad da sessão (`missao/agente_a/`), fora do repositório.
