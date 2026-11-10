# LW-087a — Pré-voo da Fase 3 (economia): decisões de 10/11/2026

- **Status:** duas origens, e a diferença importa. (1) **Decisões de Arthur, por escrito, em 10/11/2026** (mensagem que autorizou a LW-087a): entram em `docs/DECISIONS.md` como **APROVADA** (DEC-129 a DEC-137 e DEC-142 a DEC-144) e aprovam as DEC-047, DEC-049 e DEC-054. (2) **Respostas do revisor (Claude), na delegação de menores:** entram como **PROPOSTA**, isto é, **padrão de trabalho, não APROVADA** (DEC-138 a DEC-141 e DEC-145 a DEC-162); Arthur pode trocá-las. Cada entrada de `DECISIONS.md` aponta para a seção correspondente deste arquivo.
- **Data e tarefa:** 10/11/2026 (Brasília), LW-087a (DOC), rascunho no ramo `lw-087a-registro-fase-3`. Origem: pré-voo da Fase 3 da B (`STATUS-B.md`, ramo `status-b`, commit `a23f5ae`, seções b a e); perguntas Q1 a Q14 e D1 do contrato da B (`docs/modules/economy.md` e `docs/economy/dados.md`, ramos `lw-087b-contrato-economy` e `lw-087d-eventos-e-dados`); perguntas Q-W1 a Q-W6 e Q18 a Q22 da C (`docs/modules/world.md` e `docs/modules/npc.md`, ramo `lw-087c-extensoes-world-npc`).
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
- **Decisão:** **(a).** O roadmap ganha a **LW-093a** (verificador de ids de conteúdo, cerca de 60 linhas, **mais a conferência dos ids que os dados de um módulo citam de outro**, a pergunta D1 da B) e a **LW-093b** (teste de que um ofício novo, só por JSON, funciona e é validado; só teste), antes da LW-093; os nomes e a ordem são escolha do redator.
- **O que a D1 faz crescer a LW-093a (estimativa [HIP], não medida):** a D1 são quatro colunas das tabelas da economia que citam id de outro módulo (`need_id` e `occupation_id`, do `npc`; `settlement_id` e `place_id`, do `world`); a economia não importa o `npc`, então o carregador não pode usar `set_ref`. A conferência lê as tabelas dos dois lados e confere cada id. Conta: de cerca de 60 para cerca de 100 linhas de código (+40), mais cerca de 40 de teste (um caso certo e um id inexistente); o total, cerca de 140, fica dentro do limite do AGENTS 5.2 (DEC-126). **Dois efeitos:** a LW-093a passa a depender da LW-089 e da LW-092 (precisa das tabelas); e, se a conferência também rodasse no `app` ao montar o jogo (opção da B), a tarefa tocaria um segundo módulo: o roadmap a deixa só em `tools/` e em teste.
- **Consequências:** a LW-093 depende das duas; elas são subtarefas e não entram na contagem das 30 tarefas.

## 4. Perguntas decididas por Arthur (APROVADAS)

### 4.1 Q10 — Ofícios, locais e distribuição das cadeias (DEC-142)
- **Contexto (fato):** os ofícios de hoje são `farmer`, `lumberjack`, `artisan`, `guard` e `innkeeper`; faltam quem minere e quem crie ovelhas.
- **Opções:** reaproveitar os ofícios existentes e criar `miner` e `shepherd` em dados, distribuindo as cadeias de modo que nenhum povoado se baste (recomendação da B); ou concentrar tudo em cada povoado.
- **Decisão:** a recomendação da B. A população e os locais do 3º povoado e os hashes novos do `npc` ficam para a **LW-097**, **com a aprovação dos valores novos por Arthur**. **Consequências:** muda `population.json`; nada é criado agora.

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

### 5.2 Perguntas Q1 a Q9 e Q11 a Q14 do contrato da B (DEC-145 a DEC-151, DEC-153 a DEC-157)
(A Q10 é decisão de Arthur, na seção 4.1.)
- **Q1 (com a Q21 da C), quem abre as contas:** cada dono abre a sua; o `npc` pela `economy/api`; `request_open_owner(owner_id, kind)` idempotente, com o `mint` inicial (DEC-145).
- **Q2, dono morto:** fechar conta e inventário ao ouvir `NpcDied`, mantendo-os na soma; herança é "não fazer" (DEC-146).
- **Q3, motivos:** `game_start` em vez de `inicio_de_jogo` (DEC-022); conjunto fechado; saldos iniciais por tipo em `owner_kinds.json` [HIP] (DEC-147).
- **Q4, dono do local de produção:** o próprio local (DEC-148).
- **Q5, dinheiro do mercado:** conta de mercado com `mint` inicial e receita das vendas; sem sumidouro (DEC-149).
- **Q6 e Q7, preço, spread e profundidade:** a forma da seção 4 do contrato, com testes por propriedade; calibração na LW-112 (DEC-150).
- **Q8, trabalho, salário e vendas dos locais:** `request_work_shift(place_id, ...)` com salário na hora; compra de insumos e venda de excedente uma vez por hora (DEC-151).
- **Q9 (com a Q20 da C), o que sacia o quê:** `bread` sacia `hunger` por inteiro e `grain` menos [HIP]; só comida na Fase 3 (DEC-153).
- **Q11, perecibilidade:** o campo existe (0 = não perece), sem comportamento (DEC-154).
- **Q12, eventos sem tarefa:** `CaravanAttacked`, `RouteCargoLost` e `BusinessBankrupt` **não** entram na Fase 3 (DEC-155).
- **Q13, conservação de bens:** simétrica à do dinheiro (DEC-156).
- **Q14, contratos:** `labor` = minutos de trabalho num local; `delivery` = bem no destino (DEC-157).

### 5.3 Perguntas Q-W1 a Q-W6 da C (DEC-158 a DEC-162)
- **Q-W1:** as rotas formam um triângulo (A–B, A–C, B–C) (DEC-158). **Q-W2 e Q-W3:** só `open` e `closed`, nenhum campo extra (DEC-159). **Q-W4:** renomear `market_reserved` para `market` na LW-093 (DEC-160). **Q-W5:** não ampliar o terreno (DEC-161). **Q-W6:** aceitar a mudança de hash na LW-097, atualizando oráculo, hash de 30 dias e `run_sim` com a aprovação de Arthur dos valores novos (DEC-162).

### 5.4 Perguntas Q18, Q20 e Q21 da C (DEC-152, DEC-153, DEC-145)
- **Q18, salário e `income`:** opção A, um evento de pagamento ouvido pelo `npc` (DEC-152). **Q20:** só comida na Fase 3 (junto da Q9, DEC-153). **Q21:** opção A, o `npc` abre a conta pela `economy/api` e a economia faz o `mint` `game_start` (junto da Q1, DEC-145).
- **Limitação (tensão a resolver):** a Q8 da B ("salário na hora", por turno de trabalho) e a Q18 da C ("por hora de produção, aos trabalhadores atribuídos, sem depender de a ação `work` terminar") falam do mesmo pagamento com redações diferentes; precisam ser conciliadas na revisão do `economy.md` (087b) e do `npc.md` (087c).

## 6. Aprovação das DEC-047, DEC-049 e DEC-054

- **Contexto (fato):** as três estavam PROPOSTA; o AGENTS 4.11 já usa a DEC-047 como regra.
- **Opções:** (a) aprovar; (b) manter PROPOSTA (padrão de trabalho, AGENTS 3.2); (c) descartar.
- **Decisão:** **(a).** DEC-047 (dinheiro inteiro e `Ledger`), DEC-049 (`TradeRules` como única inversão; na Fase 3 só a versão neutra) e DEC-054 (uma só moeda, entre outros itens fora do protótipo).
- **Limitação:** o título da DEC-054 lista 13 itens (cercos, exércitos grandes, intriga, sucessão, magia ampla, domesticação, famílias, múltiplas moedas, fundação de organizações, multiplayer, IA generativa, vários continentes, geração procedural). A ordem de Arthur foi "PROPOSTA → APROVADA" com a nota "uma só moeda"; a entrada foi aprovada **inteira**. Se a intenção era só a moeda, a entrada passa a "APROVADA (somente uma só moeda)".

## Pendentes (não decididos aqui)

- **Forma dos dados de receitas** (tabelas planas ou listas aninhadas; backlog e pré-voo, seção e): a recomendação do pré-voo é tabelas planas; esta tarefa não a decide.
- **Divisões 088a, 090, 092, 094a/b, 095 e 098** sugeridas pelo pré-voo: **não decididas**; não entram no roadmap por esta tarefa.

## Validação e referências

- Fonte dos fatos: pré-voo da B (`git show a23f5ae:STATUS-B.md`, seções b a e); conferidos em `docs/DEVELOPMENT_ROADMAP.md` (Fase 3, Anexo D), `docs/TECHNICAL_ARCHITECTURE.md` (8.6, 11.5, 11.8, 11.10, 15.4), `docs/GDD.md` (12.5) e `docs/backlog.md`; perguntas lidas nos ramos `lw-087b-contrato-economy`, `lw-087c-extensoes-world-npc` e `lw-087d-eventos-e-dados`.
- Relação com: DEC-041, DEC-047, DEC-048, DEC-049, DEC-054, DEC-083, DEC-084, DEC-126, DEC-127; modelo deste registro: `docs/decisions/0011-revisao-fase-2.md`.
