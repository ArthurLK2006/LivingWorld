# LW-087a — Pré-voo da Fase 3 (economia): decisões de 10/11/2026

- **Status:** duas origens, e a diferença importa. (1) **Decisões de Arthur, por escrito, em 10/11/2026** (mensagem que autorizou a LW-087a): entram em `docs/DECISIONS.md` como **APROVADA** (DEC-129 a DEC-137, DEC-142 a DEC-144, DEC-163, DEC-164 e DEC-178) e aprovam as DEC-047, DEC-049 e DEC-054. (2) **Respostas do revisor (Claude), na delegação de menores:** entram como **PROPOSTA**, isto é, **padrão de trabalho, não APROVADA** (DEC-138 a DEC-141, DEC-145 a DEC-162 e DEC-165 a DEC-177); Arthur pode trocá-las. Cada entrada de `DECISIONS.md` aponta para a seção correspondente deste arquivo.
- **Data e tarefa:** 10/11/2026 (Brasília), LW-087a (DOC), rascunho. Origem: o pré-voo da Fase 3 (levantamento feito antes da LW-087: decisões de que a fase depende, contradições e buracos, divisão da LW-087 e backlog prévio); as perguntas Q1 a Q17 e D1 do contrato da `economy` (`docs/modules/economy.md` e `docs/economy/dados.md`); as perguntas Q-W1 a Q-W6 e Q18 a Q23 dos contratos do `world` e do `npc` (`docs/modules/world.md` e `docs/modules/npc.md`).
- **Rótulos:** **fato** (com origem), **decisão** (de Arthur), **proposta** (do revisor), **[HIP]**, **pendente**, **limitação**.

## 1. Escala do protótipo (DEC-129, APROVADA)

- **Contexto (fato):** o roadmap (3.B) e o GDD (12.5, [P1]) davam "3 assentamentos, 8 a 12 bens e 4 cadeias" como hipótese. Hoje existem 2 assentamentos; o terceiro nasce na LW-097. A lista de bens e de cadeias é o aceite da LW-087.
- **Opções:** (a) a lista do pré-voo (10 bens e 4 cadeias); (b) outra lista dentro de 8 a 12 bens.
- **Decisão:** **(a).** 3 povoados; 10 bens genéricos (grão, farinha, pão; madeira, tábua; minério, metal, ferramenta; lã, tecido); 4 cadeias: grão → farinha → pão; madeira → tábua (a madeira também é combustível); minério + madeira → metal → ferramenta; lã → tecido. Armas e roupas ficam para depois. Os valores seguem **[HIP]**.
- **Consequências:** a LW-089 cria os bens, a LW-092 as cadeias e a LW-097 o terceiro povoado. Os nomes são identificadores de trabalho (DEC-100).

## 2. As seis correções do pré-voo (seção c, itens 1 a 6; APROVADAS)

### 2.1 Dono das quantidades de bens (DEC-130)
- **Contexto (fato):** o roadmap (LW-089 e LW-105) põe o inventário de NPC, jogador, local e mercado na `economy`; a arquitetura (15.4) dá o `Inventory` ao `character` ("itens, equipamentos, contêineres").
- **Opções:** (a) a `economy` guarda as quantidades de todo dono, por ID, e o equipamento em instâncias fica no `character` (Fase 5); (b) o `character` guarda todo inventário e a economia consulta; (c) deixar as duas fontes.
- **Decisão:** **(a).** **Consequências:** LW-089 e LW-105 dizem isso; nenhum item em instância na Fase 3.

### 2.2 `TradeFlow` e o LOD S2 (DEC-131)
- **Contexto (fato):** GDD 12.5 e arquitetura 11.6 põem o fluxo agregado em "S2"; a DEC-041 (APROVADA) deixa S2 e S3 fora; o roadmap cria o `TradeFlow` na LW-100.
- **Opções:** (a) manter o roadmap e dizer que o `TradeFlow` é uma abstração econômica por rota, sem depender de S2; (b) reabrir o S2; (c) tirar o fluxo agregado agora.
- **Decisão:** **(a).** O SP7 (LW-101) decide caravanas e fluxo. **Consequências:** LW-100 diz isso; DEC-048 segue PROPOSTA.

### 2.3 Direção entre `npc` e `economy` (DEC-132)
- **Contexto (fato):** arquitetura 8.6 ("o `npc` consulta a `economy` por interface") e 11.10 ("a economia usa o `npc` só por IDs e eventos"); o cap. 11 não define a interface; a DEC-049 admite uma só inversão.
- **Opções:** (a) o `npc` importa só `economy/api`, a economia nunca importa o `npc`, o contrato de trabalho chega por evento; (b) segunda inversão (interface implementada pelo `npc`); (c) a economia importa a `api` do `npc`.
- **Decisão:** **(a).** **Consequências:** LW-093 e LW-095 dizem isso; a revisão LW-115 confere.

### 2.4 Dinheiro inicial tarde demais (DEC-133)
- **Contexto (fato):** a LW-094 remove o `FoodStub` e exige 30 dias verdes, mas o `mint` inicial só nasce na LW-095. Sem dinheiro, guarda, estalajadeiro, artesão e lenhador não compram comida.
- **Opções:** (a) o `mint` inicial entra na LW-093; (b) a LW-095 vem antes da LW-094; (c) manter a ordem.
- **Decisão:** **(a) ou (b)**, as duas aceitas por Arthur; a escolha é feita quando a LW-093 for preparada. O motivo do dinheiro inicial é `game_start` (DEC-147, PROPOSTA).

### 2.5 Save: migrar ou rejeitar (DEC-134)
- **Contexto (fato):** a LW-111 dizia "save da Fase 2 migra e carrega" e previa incremento de `save_version`; o AGENTS 4.15 e a DEC-127 mantêm o número em 2 e rejeitam o save antigo até o "save congelado" (DEC-083), que ninguém declarou.
- **Opções:** (a) declarar o save congelado e migrar; (b) não congelar: a LW-111 rejeita o save antigo com mensagem clara.
- **Decisão:** **(b).** **Consequências:** LW-111, o critério 9 de 3.F e a linha de save de 3.G passam a dizer "rejeita com mensagem clara".

### 2.6 Escopo do `check_temp` (DEC-135)
- **Contexto (fato):** a LW-114 falha com qualquer `TEMP-LW-` "no repositório", mas as marcas ficam para sempre no Anexo D, no `npc.md` e no status.
- **Opções:** (a) olhar `src/`, `data/`, `tests/`, `tools/` e `scenes/`, fora de `docs/`; (b) o repositório inteiro, tirando as marcas dos documentos.
- **Decisão:** **(a).** **Consequências:** LW-114, o aceite da LW-094 e da LW-095 e o Anexo D dizem isso. **Limitação (para a LW-114):** a pasta `tools/` e os testes citam a marca no próprio verificador; a LW-114 precisa evitar que a regra se acione sozinha.

## 3. Preparação da LW-093 (DEC-136 e DEC-137, APROVADAS)

- **Contexto (fato):** o pré-voo (seção e) recomendou dividir `npc_module.gd`, `npc_thinker.gd` e `action_runner.gd` antes da LW-093 (620, 455 e 416 linhas; cerca de 346, 328 e 304 de código), porque a 093, a 094 e a 095 mexem nos três. A DEC-126 já aceita até ~450 linhas de código por arquivo. Dois pontos pesam mais: ids de conteúdo escritos no código (backlog) e o critério 8 de 2.F, parcial na Fase 2 (a ação tem teste; o ofício não: `docs/fase-2/LW-086-relatorio-de-fechamento.md`).
- **Opções:** (a) não dividir e acrescentar duas tarefas pequenas; (b) dividir os três arquivos antes da LW-093 (refatoração grande, mesma saída); (c) nada.
- **Decisão:** **(a).** O roadmap ganha a **LW-093a** (verificador de ids de conteúdo, cerca de 60 linhas, **mais a conferência dos ids que os dados de um módulo citam de outro**, a pergunta D1 do contrato de dados) e a **LW-093b** (teste de que um ofício novo, só por JSON, funciona e é validado; só teste), antes da LW-093; os nomes e a ordem são escolha do redator.
- **O que a D1 faz crescer a LW-093a (estimativa [HIP], não medida):** a D1 são quatro colunas das tabelas da economia que citam id de outro módulo (`need_id` e `occupation_id`, do `npc`; `settlement_id` e `place_id`, do `world`) e a coluna `work_place_id` de `population.json`; a economia não importa o `npc`, então o carregador não pode usar `set_ref`. A conferência lê as tabelas dos dois lados e confere cada id. Conta: de cerca de 60 para cerca de 150 a 200 linhas de código e teste no total (um arquivo de verificação e um de teste, com caso positivo e negativo por id); fica dentro do limite do AGENTS 5.2 (DEC-126). **Dois efeitos:** a LW-093a passa a depender da LW-089 e da LW-092 (precisa das tabelas); e, se a conferência também rodasse no `app` ao montar o jogo (opção do contrato de dados), a tarefa tocaria um segundo módulo: o roadmap a deixa só em `tools/` e em teste.
- **Consequências:** a LW-093 depende das duas; elas são subtarefas e não entram na contagem das 30 tarefas.

## 4. Perguntas decididas por Arthur (APROVADAS)

### 4.1 Q10 — Ofícios, locais e distribuição das cadeias (DEC-142)
- **Contexto (fato):** os ofícios de hoje são `farmer`, `lumberjack`, `artisan`, `guard` e `innkeeper`; faltam quem minere e quem crie ovelhas.
- **Opções:** reaproveitar os ofícios existentes e criar `miner` e `shepherd` em dados, distribuindo as cadeias de modo que nenhum povoado se baste (recomendação do contrato da `economy`); ou concentrar tudo em cada povoado.
- **Decisão:** a recomendação do contrato da `economy`. A população e os locais do 3º povoado e os hashes novos do `npc` ficam para a **LW-097**, **com a aprovação dos valores novos por Arthur**. **Consequências:** muda `population.json`; nada é criado agora.

### 4.2 Q19 — Como `buy` vira candidata (DEC-143)
- **Contexto (fato):** `eat` exige `has_food`; `buy` não alivia necessidade, e a utilidade só pontua alívio.
- **Opções:** (A) valor derivado: `buy` herda o alívio da necessidade que o bem atende, descontados preço e distância; (B) `buy` na rotina, em horas fixas; (C) um pequeno planejador de pré-requisitos (reservado a T2 e T3 pelo GDD 9).
- **Decisão:** **(A).** Sem rotina fixa e sem planejador; a utilidade segue sendo o único mecanismo de decisão.

### 4.3 Q22 — Como o NPC consegue o emprego (DEC-144)
- **Contexto (fato):** o roadmap tem contrato de trabalho avulso e de entrega (LW-096) e salário fixo dos trabalhadores do local (LW-095): coisas diferentes.
- **Opções:** (A) emprego estático (`work_place_id` de `population.json`); (B) a economia oferece o emprego por evento (`ContractOffered`) e o NPC aceita pela utilidade; (A para o início e B para vaga nova).
- **Decisão:** **A para o início do jogo e B para a vaga nova.** A população inicial já nasce empregada.

## 5. Decididos pelo revisor (PROPOSTA: padrão de trabalho, não APROVADA)

Para cada item, a opção escolhida é a **recomendação** da fonte; o revisor a adotou na delegação de menores. Arthur pode trocá-la.

### 5.1 Menores 7 a 11 do pré-voo (DEC-138 a DEC-141)
- **Menor 7, tributos.** Fato: GDD 12.5 [P1] cita "tributos"; o roadmap 3.J manda não fazer impostos. Opções: valer o GDD ou o roadmap. **Escolha:** o roadmap; tributos na Fase 4 (DEC-138).
- **Menor 8, alvo de estoque.** Fato: arquitetura 11.5 define o alvo em "dias de consumo", mas o consumo vem depois do mercado. Opções: calcular ou dado fixo. **Escolha:** dado fixo por mercado e bem, em `data/` [HIP] (DEC-139).
- **Menor 9, `RouteStateChanged` e fechar rota.** Fato: o checklist 3.H e o aceite da LW-097 supõem rota fechada; nenhuma tarefa cria o evento nem o comando. Opções: LW-097 ou tarefa nova. **Escolha:** a LW-097 (DEC-140). **Limitação:** a linha da LW-097 no roadmap não foi alterada por esta tarefa (o roadmap ficou limitado às outras tarefas indicadas).
- **Menor 10, módulo `entities`.** Fato: a arquitetura 11.10 lista `entities` entre as dependências da economia; `src/sim/entities/` só tem um README. Opções: criar o módulo ou usar `ctx.ids`. **Escolha:** IDs de `ctx.ids`, como o `npc` (DEC-141).
- **Menor 11, entrega do `TradeRules`.** Fato: "entregue pelo `app`" (3.2) ou "pela `SimContext`" (11.8); sem efeito na Fase 3, que só tem a versão neutra. **Escolha:** entregue à economia no construtor; o texto da arquitetura é alinhado na Fase 4 (DEC-141).

### 5.2 Perguntas Q1 a Q9 e Q11 a Q14 do contrato da `economy` (DEC-145 a DEC-151, DEC-153 a DEC-157)
(A Q10 é decisão de Arthur, na seção 4.1.)
- **Q1 (com a Q21 do contrato do `npc`), quem abre as contas:** cada dono abre a sua; o `npc` pela `economy/api`; `request_open_owner(owner_id, kind, work_place_id)` idempotente, com o `mint` inicial (DEC-145).
- **Q2, dono morto:** fechar conta e inventário ao ouvir `NpcDied`, mantendo-os na soma; herança é "não fazer" (DEC-146).
- **Q3, motivos:** `game_start` em vez de `inicio_de_jogo` (DEC-022); conjunto fechado; saldos iniciais por tipo em `owner_kinds.json` [HIP] (DEC-147).
- **Q4, dono do local de produção:** o próprio local (DEC-148).
- **Q5, dinheiro do mercado:** conta de mercado com `mint` inicial e receita das vendas; sem sumidouro (DEC-149).
- **Q6 e Q7, preço, spread e profundidade:** a forma da seção 4 do contrato, com testes por propriedade; `bid` de no mínimo 1 e `ask` sempre maior que o `bid` (rodada 2); calibração na LW-112 (DEC-150).
- **Q8, trabalho, salário e vendas dos locais:** a hora do local (compra insumos, confere, **paga a folha**, produz, vende o excedente); `request_work_shift` só para contrato `labor` (rodada 2; DEC-151).
- **Q9 (com a Q20 do contrato do `npc`), o que sacia o quê:** `bread` sacia `hunger` por inteiro e `grain` menos [HIP]; o NPC só consome comida; os locais gastam ferramenta e tábua (rodada 2; DEC-153 e DEC-163).
- **Q11, perecibilidade:** o campo existe (0 = não perece), sem comportamento (DEC-154).
- **Q12, eventos sem tarefa:** `CaravanAttacked`, `RouteCargoLost` e `BusinessBankrupt` **não** entram na Fase 3 (DEC-155).
- **Q13, conservação de bens:** simétrica à do dinheiro (DEC-156).
- **Q14, contratos:** `labor` = minutos de trabalho num local; `delivery` = bem no destino (DEC-157).

### 5.3 Perguntas Q-W1 a Q-W6 do contrato do `world` (DEC-158 a DEC-162)
- **Q-W1:** as rotas formam um triângulo (A–B, A–C, B–C) (DEC-158). **Q-W2 e Q-W3:** só `open` e `closed`, nenhum campo extra, e o `RouteStateChanged` leva só `route_id` e `new_state` (DEC-159). **Q-W4:** renomear `market_reserved` para `market` na LW-093 (DEC-160). **Q-W5:** não ampliar o terreno (DEC-161). **Q-W6:** aceitar a mudança de hash na LW-097, atualizando o oráculo, o hash de 30 dias e o hash que o `run_sim` imprime (o código do `run_sim` não muda), com a aprovação de Arthur dos valores novos (DEC-162).

### 5.4 Perguntas Q18, Q20 e Q21 do contrato do `npc` (DEC-152, DEC-153, DEC-145)
- **Q18, salário e `income`:** opção A: a economia paga por hora de produção a todos os trabalhadores atribuídos, com **um** evento `WagesPaid` por local e por hora, ouvido pelo `npc` (DEC-152). **Q20:** só comida na Fase 3 (junto da Q9, DEC-153). **Q21:** opção A, o `npc` abre a conta pela `economy/api` e a economia faz o `mint` `game_start` (junto da Q1, DEC-145).
- **Q8 e Q18 não se contradizem (rodada 2):** o salário da Q18 é o passo 3 da hora do local descrita na Q8 (seção 7.2).

## 6. Aprovação das DEC-047, DEC-049 e DEC-054

- **Contexto (fato):** as três estavam PROPOSTA; o AGENTS 4.11 já usa a DEC-047 como regra.
- **Opções:** (a) aprovar; (b) manter PROPOSTA (padrão de trabalho, AGENTS 3.2); (c) descartar.
- **Decisão:** **(a).** DEC-047 (dinheiro inteiro e `Ledger`), DEC-049 (`TradeRules` como única inversão; na Fase 3 só a versão neutra) e DEC-054 (uma só moeda, entre outros itens fora do protótipo).
- **Confirmação (rodada 2):** o título da DEC-054 lista 13 itens (cercos, exércitos grandes, intriga, sucessão, magia ampla, domesticação, famílias, múltiplas moedas, fundação de organizações, multiplayer, IA generativa, vários continentes, geração procedural). Arthur confirmou que a DEC-054 vale **inteira**; o texto dela não muda.

## 7. Rodada 2 (10/11/2026, depois das revisões cruzadas e das decisões novas de Arthur)

### 7.1 Decisões de Arthur (APROVADAS)
- **A DEC-054 vale inteira, com os 13 itens.** O texto dela não muda.
- **Consumo na Fase 3 = manutenção dos locais (DEC-163).** Os locais de produção gastam ferramenta (`tool`) e tábua (`plank`) aos poucos para funcionar; o NPC continua consumindo só comida; o tecido fica só como mercadoria de comércio (a LW-112 pode revisar); roupa e ferramenta pessoal (GDD 12.3) ficam fora da Fase 3 (uma linha em `docs/backlog.md`). Números [HIP] em dados; entra na LW-092.
- **Quem paga guardas e estalajadeiros (DEC-164, Q15).** Cada povoado ganha postos de serviço e a folha sai da conta do mercado do povoado; provisório até a Fase 4 (impostos). Entra na LW-095.
- **Ajustes de coerência do roadmap, confirmados:** a escala em 3.B, o critério 9 de 3.F, a linha de save de 3.G, o Anexo D, a LW-094, a LW-105 e a LW-111.

### 7.2 Decisões do revisor (PROPOSTA: padrão de trabalho, Arthur pode aprovar ou trocar)
- **Salário (Q18 A), como o contrato da `economy` escreveu (DEC-152, revista).** A cada hora em que o local produz, paga todos os trabalhadores atribuídos, tudo ou nada; **um** evento `WagesPaid` por local e por hora (`site_id` e `amount_each`); o `npc` o ouve e alivia `income`. **Q8 e Q18 não se contradizem:** o salário é o passo 3 da hora do local (DEC-151, revista). **Um trabalho, um pagamento:** `request_work_shift` só vale para contrato `labor` e é recusado se o trabalhador já está atribuído àquele local. A DEC-153 (Q20) foi revista: o NPC só come; os locais consomem ferramenta e tábua.
- **Q16 (DEC-165):** tipo de contrato `vacancy` (sem custódia, sem prazo). **Q17 (DEC-166):** o povoado C começa com estoque de comida no mercado; soaks de 30 dias na LW-097 com ele; soaks de 1 ano só depois da LW-098. **Q23 (DEC-167):** coluna opcional `work_place_id` em `data/population.json` (LW-097); é mudança de formato de dado, então **fica PROPOSTA até Arthur aprovar, quando a LW-097 for preparada**.
- **`sell` do NPC (DEC-168):** mesmo mecanismo de utilidade da `buy`, definido na LW-093; na Fase 3 quem vende o excedente da produção é o **local**; divergência do aceite da LW-093 registrada no roadmap. **LW-096a (DEC-169):** o NPC aceita vaga pela utilidade, com histerese; o emprego só termina por morte ou por outra vaga; local sem dinheiro para e não demite.
- **Dinheiro inicial (DEC-170):** o `mint` `game_start` entra na LW-093, antes da LW-094 (a LW-095 não muda de lugar).
- **LW-088a (DEC-171 e DEC-172):** regra nova no `check_architecture` (o `npc` cita só `economy/api`; a `economy` não cita o `npc`), com teste positivo e negativo; o registro da `economy` no `World` muda o `state_hash` e pode atingir `tests/unit/test_save_codec.gd` (fixture `save_v1`, protegida): a LW-088a **para** e pede a autorização escrita de Arthur antes de mexer em `tests/fixtures`; Arthur aprova os hashes novos **uma vez em cada marco** (três marcos por bloco, a partir da rodada 4: LW-088a a LW-092; LW-093 a LW-096a; LW-097; seção 9); o `run_sim` não muda. **Limitação:** a linha da LW-088a descreve a tarefa como o registro de uma casca do módulo (`api/` vazia), a ideia do pré-voo; Arthur citou só as três regras acima.
- **`request_trade(actor_id, market_id, good_id, quantity, side)` (DEC-173),** na lista de divergências do roadmap (LW-091). **`RouteStateChanged`** leva só `route_id` e `new_state`, e a rota só `open` e `closed` (DEC-159, revista; já estava assim nos contratos). **Preço:** `bid` de no mínimo 1 e `ask` maior que o `bid`, invariante (DEC-150, revista); a fórmula fica em `docs/modules/economy.md`.
- **Correção do registro (nota curta pedida por Arthur):** a frase "DEC-054, proposta" está na **DEC-034**, e não na DEC-031 (citada por engano no relatório da rodada 1); a nota "(DEC-054 aprovada em 10/11/2026)" foi acrescentada na DEC-034. Outras entradas ainda tratam a DEC-054 como proposta (DEC-005, DEC-045 e DEC-053) e **não foram alteradas**.

## 8. Rodada 3 (10/11/2026, depois da segunda rodada das revisões cruzadas)

Todas as decisões abaixo são do **revisor** e entram como **PROPOSTA** (padrão de trabalho): Arthur pode aprovar ou trocar.

- **Q18, postos de serviço sem a marca `TEMP-LW` (DEC-174).** São provisórios até a Fase 4, mas são regra de jogo e não código a remover; o Anexo D e o critério 3.F item 4 do roadmap dizem isso, e o `check_temp` continua exigindo zero marcas.
- **Q19, três marcos de hash (DEC-175; DEC-172 revista).** (1) LW-088a (registro da `economy`); (2) LW-093 a LW-095 (o NPC passa a usar mercado, comida e salário); (3) LW-097 (população nova). Arthur aprova os valores novos uma vez em cada marco; o `run_sim` não muda.
- **Q20, estoque inicial de 30 dias (DEC-176).** Dos bens importados até o comerciante (LW-098): comida no C; ferramenta em A e B; farinha e tábua em B; madeira e tábua em C. Dados [HIP], na LW-097.
- **Q21, teto de compra do mercado (DEC-177).** Por bem, em dados; acima dele o mercado deixa de comprar e o local para por `OUTPUT_FULL` sem perder eficiência. LW-090.
- **Nomes canônicos (valem os do contrato da `economy`).** O evento é `WagesPaid(workplace_id, amount_each)`, em que `workplace_id` é o `site_id` do local de produção ou o `post_id` do posto; a consulta dos trabalhadores é `peek_site` (local de produção) ou `peek_post` (posto); o campo da equipe desejada é `workers_wanted`. A DEC-152 foi revista.
- **Distribuição proposta (sem entrada própria; Arthur a aprova ao preparar a LW-097).** 14 locais de produção e 6 postos de serviço, em 20 locais `work`, dos quais 10 são novos (A +2, B +3, C +5); o teste de dados `test_economy_distribution.gd` confere que nenhum povoado se basta e que todo bem necessário tem produtor. Consta na linha da LW-097.
- **Notas da DEC-054.** A nota curta "(DEC-054 aprovada em 10/11/2026)" foi acrescentada às DEC-005, DEC-045 e DEC-053, sem reescrever nada (a da DEC-034 já existia).
- **Divergências do roadmap.** A nota sob a tabela 3.D lista agora todas as divergências, conferidas linha a linha com a seção 16 do contrato da `economy`.

## 9. Rodada 4 (10/11/2026, depois da terceira rodada das revisões cruzadas)

### 9.1 Decisão de Arthur (APROVADA)
- **O tecido entra na manutenção dos locais (DEC-178, Q22).** Além de ferramenta e tábua (lonas, sacos), em dados. O NPC continua só comendo; roupa continua fora; o teto de compra (DEC-177) e "hora parada = ninguém recebe" ficam. Motivo: sem isso o tecelão e o pastor ficam sem salário e passam fome. Amplia a DEC-163 (que ganhou uma nota curta) e a DEC-153 (idem); o vocabulário de `site_upkeep` passa a `tool`, `plank` e `fabric`.

### 9.2 Decisões do revisor (PROPOSTA: padrão de trabalho, Arthur pode aprovar ou trocar)
- **Marcos de hash por bloco (DEC-175 e DEC-172 revistas).** Marco 1 = LW-088a a LW-092 (a economia ganha estrutura; o NPC ainda não a usa); marco 2 = LW-093 a LW-096a (o NPC usa mercado, comida, salário e vaga); marco 3 = LW-097 (população nova). Em cada bloco, o primeiro valor de referência que mudar faz a tarefa **parar** e mostrar a Arthur o valor antigo, o novo e a causa; se ele aprovar ("aprovo os hashes do marco N"), as demais tarefas do bloco só registram os valores novos, desde que a causa seja a do bloco. A partir da LW-098, se um valor já aprovado mudar, a tarefa para e pergunta (AGENTS 9.5); o primeiro valor de um teste novo não é mudança. A fixture `save_v1` só com autorização escrita específica. **O código do `run_sim` não muda; muda o hash que ele imprime** (DEC-162 e DEC-172).
- **Quatro frases:** a vaga é em **local de trabalho**, isto é, local de produção ou posto de serviço (DEC-165); a DEC-162 diz que o hash do `run_sim` muda e o código dele não; a DEC-177 cita o erro `ECON_MARKET_FULL`; e a DEC-163 diz "ampliada pela DEC-178".
- **Roadmap:** LW-097 deixa de prever ampliar o terreno (DEC-161), cita o estoque inicial dos importados "inclusive tecido onde o povoado não tece" e o `RouteStateChanged` e o comando de fechar rota (o contrato do `world` os põe na LW-097); LW-092 gasta `tool`, `plank` e `fabric`. A distribuição 14/6/20/10 continua **sem entrada própria**.

## Pendentes (não decididos aqui)

- **Forma dos dados de receitas** (tabelas planas ou listas aninhadas; backlog e pré-voo, seção e): a recomendação do pré-voo é tabelas planas; esta tarefa não a decide.
- **Divisões 090, 092, 094a/b, 095 e 098** sugeridas pelo pré-voo: **não decididas**; não entram no roadmap. (A LW-088a passou a existir na rodada 2, seção 7.2.)

## Validação e referências

- Fonte dos fatos: o pré-voo da Fase 3 (seções b a e), conferido em `docs/DEVELOPMENT_ROADMAP.md` (Fase 3, Anexo D), `docs/TECHNICAL_ARCHITECTURE.md` (8.6, 11.5, 11.8, 11.10, 15.4), `docs/GDD.md` (12.5) e `docs/backlog.md`; as perguntas, em `docs/modules/economy.md`, `docs/economy/dados.md`, `docs/modules/world.md` e `docs/modules/npc.md`.
- Relação com: DEC-041, DEC-047, DEC-048, DEC-049, DEC-054, DEC-083, DEC-084, DEC-126, DEC-127; modelo deste registro: `docs/decisions/0011-revisao-fase-2.md`.
