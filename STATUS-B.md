10/11/2026 18:11 (Brasília) — CONCLUÍDA — PRÉ-VOO PRONTO: LW-085f no `main` (`497ab78`, Fase B automática, sem tag) e pré-voo da Fase 3 abaixo (só leitura; nada criado, nenhum Godot); parei (regra 13)

# RELATÓRIO — LW-085f: correções da LW-085c e itens do backlog     Status: PRONTA PARA REVISÃO (já no `main` pela Fase B automática)

## 1. RESUMO
Corrigi o intervalo do `refresh` da lista na linha da LW-085c (de "3,5 a 4,4 ms" para "de 4,1 a 4,4 ms"; os 3,5 ms eram do teste de 1 dia) e registrei no **meio** do `docs/backlog.md` as três linhas que você mandou: a régua provisória de memória (sem virar teste), o ritmo do resumo do painel (as duas opções e os números medidos) e o painel com 1 ano de jogo (não rodar). Só texto: nenhum código, teste nem dado. A linha da LW-085f entrou como subtarefa e a contagem não mudou.

## 2. ARQUIVOS CRIADOS
Nenhum.

## 3. ARQUIVOS MODIFICADOS
- `docs/ROADMAP_STATUS.md`: um número trocado na linha da LW-085c (só ele, conferido por `git diff --word-diff`: `-3,5 +4,1`) e +1 linha (a da LW-085f, entre a da 085d e a da 086a).
- `docs/backlog.md`: +3 linhas, logo depois das linhas da 084b e antes de "Magias, armas e outras habilidades" (meio do arquivo, não no fim).
- Contra o `main` (`fbd6ac0`): 2 arquivos, 5 inserções e 1 remoção. Nenhum arquivo protegido.

## 4. DECISÕES TÉCNICAS
- **Não repeti o que já existia no backlog:** a linha do ano em release (`run_npc_year_release`), a do laço de controle intercalado, a da saturação das memórias dos notáveis (24/24 no teto) e a da divisão do `npc_year_meter.gd` (330 linhas) já estavam lá desde a 084b. Foram 3 linhas novas, não 5.
- **O cálculo da opção A do painel é conta, não medida:** com o resumo a cada 5 s, 19,9 a 22,3 ms divididos por 5 mais 4 vezes 4,1 a 4,4 dá cerca de 20 a 22 ms por segundo. A linha do backlog diz "conta, não medida".
- **Citação da P4:** conferi no roteiro (`docs/fase-2/LW-086-roteiro-para-arthur.md`, linha 174): "painel aberto (F3), tranco uma vez por segundo?". É o que a linha do backlog cita.
- Sem proposta de entrada para o `DECISIONS.md`.

## 5. TESTES EXECUTADOS
- `tools/check_all` no HEAD final (`497ab78`), solto e vigiado, Mac na tomada, sem outro Godot (o vigia anotou os processos a cada 15 s): **VERDE: 124 scripts, 1194 testes, 261.693 asserts, 168,5 s; sem aviso novo (o "Warnings 1 / Deprecated 1" do GUT é o de sempre)**.
- Contagem por `grep`, antes e depois (e no `main`): "31 de 32" (README 2, status 1) e "86 de 192" (README 2, status 1), mais "31 de 32 tarefas concluídas" (2), "86 de 192 tarefas" (3) e "31 de 32 concluídas" (1): **iguais no ramo e no `main`**.
- Comparação do oráculo, do soak de 30 dias e do `run_sim` com o `main`: **NÃO EXECUTADA**, por não constar nas condições desta tarefa e porque o ramo difere do `main` só em dois `.md` (`git diff --stat origin/main HEAD`): código e dados são os mesmos bytes.

## 6. RESULTADOS
Aceite cumprido: o número foi corrigido, as três linhas estão no meio do backlog, a linha da LW-085f está como subtarefa e a contagem não mudou.

## 7. PROBLEMAS ENCONTRADOS
- **Erro meu, corrigido antes de publicar:** o texto da linha da LW-085f dizia "31 de 32 e 86 de 192", e isso subiu de 1 para 2 a ocorrência do placar no `ROADMAP_STATUS.md` (a conferência por `grep` pegou). Tirei os números do texto num commit à parte (`497ab78`); não reescrevi histórico.
- O `STATUS-C.md` diz "Nada rodando": a palavra "rodando" aparece, mas negada. Tratei como livre (o `pgrep` não via Godot). Se preferir, a C pode dizer "parado" em vez disso, para a regra de procurar a palavra não dar falso alarme.
- Escrevi "18:07" no "rodando" do `STATUS-B.md` sem consultar o relógio; o `check_all` começou às 18:06 e terminou às 18:09. Sem efeito prático.

## 8. RISCOS
Nenhum novo: só texto. As três linhas dependem do que o roteiro e o registro `0010` dizem hoje.

## 9. PENDÊNCIAS
Nenhuma da 085f. Nenhum teste manual.

## ACOMPANHAMENTO (085f)
- **Avanço:** Fase 2 em 31 de 32 (96,9%) e projeto em 86 de 192 (44,8%), como no `main`; falta a LW-086 (sua validação).
- **Git:** `main` em `497ab78` por avanço rápido de `fbd6ac0` (sem tag, sem `--force`); ramo `lw-085f-correcoes-da-085c` publicado; worktree `.worktrees/lw-085f` mantido; nada tocado nas pilhas da A e da C. Commits: `f9916b3` (conteúdo), `c58d93f` (junção), `b479d3c` (linha de status) e `497ab78` (tirei o placar do texto).

- **Próxima tarefa recomendada:** nenhuma minha (regra 13). A Fase 3 **não** começa antes de você fechar a Fase 2 (LW-086). **Não iniciada:** LW-087.
- **Decisões que dependem de você:** as do pré-voo abaixo (seções b e c), cada uma com a recomendação.
- O relatório anterior (LW-084 e LW-085c) está no commit `92d2302` deste ramo.

---

# PRÉ-VOO DA FASE 3 (ECONOMIA): só leitura

Nada criado: nenhum ramo, arquivo, dado ou código da Fase 3; nenhum Godot; a LW-087 **não** foi iniciada. **Li:** GDD 12 e 13; arquitetura 11 (e 3.2, 8.6, 15.4, 17.5); roadmap 3.A a 3.J e Anexos D, E e F; `DECISIONS.md` (DEC-046 a 049, 040, 041, 054, 071, 078, 082 a 084, 100, 112); `docs/events.md`; `docs/modules/` (**não existe `economy.md`**; a pasta `src/sim/economy/` só tem um README "reservado"); `data.md`, `npc.md` (seção 9) e `world.md`; o código dos provisórios. As tarefas LW-087 a LW-095 **não citam nenhuma DEC pelo número**.

**Em uma frase:** o desenho é bom, mas há **6 contradições ou buracos** (seção c) e **4 decisões suas** antes da LW-087 (seção b).

## b) Decisões de que a Fase 3 depende

| Decisão | Status | Falta decidir | Recomendação |
|---|---|---|---|
| DEC-047 dinheiro inteiro e `Ledger` | PROPOSTA | aprovar | **Aprovar** (o AGENTS 4.11 já a usa como regra) |
| DEC-049 `TradeRules` única inversão | PROPOSTA | aprovar | **Aprovar** (na Fase 3 só a versão neutra) |
| DEC-048 comércio em 2 escalas | PROPOSTA | nada agora | Manter até o SP7; o limite de diferença é a sua decisão nº 9 do Anexo F, na LW-101 |
| DEC-041 sem T0 e sem LOD S2/S3 · DEC-054 uma só moeda | APROVADA · PROPOSTA | nada | Valem; aprovar a DEC-054 com a 047 |
| DEC-040 escala de NPCs (300) | **PENDENTE** | nada que bloqueie | A economia não depende do número; manter [HIP] |
| DEC-082/083/084 dados e save | APROVADAS (em parte) | "save congelado": sim ou não (contradição 5) | **Não** congelar |
| DEC-046, 100, 071, 078 | APROVADA, APROVADA, PROPOSTA, PROPOSTA | nada | Seguir (nomes genéricos; produção por hora, preço ao fim do dia) |
| **[HIP] 3 assentamentos** | hipótese | confirmar | Confirmar (hoje há 2; o 3º nasce na LW-097) |
| **[HIP] 8 a 12 bens, 4 cadeias** | hipótese | aprovar a lista (é o aceite da LW-087) | **10 bens:** grão, farinha, pão · madeira, tábua · minério, metal, ferramenta · lã, tecido. Cadeias: grão→farinha→pão; madeira→tábua (madeira também é o combustível); minério+madeira→metal→ferramenta; lã→tecido. Armas e roupas ficam para depois |

## c) Contradições e buracos

1. **Dono do inventário.** Roadmap LW-089 e LW-105: inventário de NPC, jogador, local e mercado na `economy`. Arquitetura 15.4: `Inventory` é dado do `character` ("itens, equipamentos, contêineres"), mas também "bens comuns são quantidades na economia". **Recomendo:** a `economy` guarda as **quantidades** de todo dono, por ID; o equipamento em instâncias (`character`) fica para a Fase 5.
2. **Fluxo agregado × DEC-041.** GDD 12.5 e arquitetura 11.6 põem o fluxo agregado em "S2"; a DEC-041 (APROVADA) deixa o LOD S2/S3 fora; o roadmap cria o `TradeFlow` na LW-100. Com 3 assentamentos nada é "S2". **Recomendo:** manter o roadmap (o SP7 decide) e escrever que o `TradeFlow` é abstração econômica por rota, sem depender de S2.
3. **Direção `npc` ↔ `economy`.** Arquitetura 8.6: o `npc` "consulta a `economy` por interface"; 11.10: a economia usa o `npc` "só por IDs e eventos"; o cap. 11 não define essa interface e a DEC-049 proíbe uma segunda inversão. **Recomendo:** o `npc` importa só `economy/api` (mesma camada, mão única, já permitido); a economia nunca importa o `npc` (contrato de trabalho chega por evento).
4. **Dinheiro inicial tarde demais.** A LW-094 tira o `FoodStub` e exige 30 dias verdes, mas o `mint` inicial só nasce na LW-095. Sem dinheiro, guarda, estalajadeiro, artesão e lenhador não compram comida. **Recomendo:** o `mint` inicial entra na LW-093 (ou a 095 vem antes da 094).
5. **Migração de save × "save congelado".** LW-111: "save da Fase 2 migra"; AGENTS 4.15 e decisão 0011: `save_version` fica em 2 e save antigo é rejeitado até o congelamento (DEC-083), que ninguém declarou. **Recomendo:** não congelar; a LW-111 troca "migra" por "rejeita com mensagem clara".
6. **`check_temp` × documentos.** LW-114 falha com qualquer `TEMP-LW-` "no repositório", mas as marcas ficam para sempre no Anexo D, no `npc.md` e no status. **Recomendo:** escopo `src/`, `data/`, `tests/`, `tools/`, `scenes/`, **fora de `docs/`**.

**Menores (registrar na LW-087a):** (7) GDD 12.5 [P1] cita "tributos"; o roadmap 3.J diz "não fazer impostos": valem os do roadmap. (8) Alvo de estoque = "dias de consumo" (arq. 11.5), mas o consumo vem depois do mercado: na Fase 3 o alvo é dado fixo. (9) `RouteStateChanged` e o comando "fechar rota" do checklist 3.H: nenhuma tarefa os cria; pôr na LW-097. (10) A arquitetura 11.10 lista `entities`, que não existe: a economia usa IDs de `ctx.ids`, como o `npc`. (11) `TradeRules` "entregue pelo `app`" (3.2) ou "pela `SimContext`" (11.8): sem efeito na Fase 3.

## d) Divisão da LW-087 e ordem das tarefas

**LW-087 em 4 partes (DOC):** **087a** (precisa de você): respostas da seção c, os 10 bens, 4 cadeias e 3 assentamentos · **087b:** `docs/modules/economy.md` (dono único de estoque, preço e dinheiro; `Ledger`, mercado, `request_trade`, `TradeRules`, produção, contratos) · **087c:** extensões do `world.md` (rotas, 3º assentamento) e do `npc.md` (comprar, vender, salário, fim dos provisórios) · **087d:** os 11 eventos do cap. 11.9 em `docs/events.md` e os modelos de dados (`goods`, `recipes` em tabelas planas, parâmetros de preço). A 087a vai primeiro; **087b, 087c e 087d em paralelo** (arquivos diferentes).

**Grandes demais para o limite** (~300 linhas, ~8 arquivos, 1 módulo): **088** (antes, uma casca 088a: `EconomyModule` com `api/` vazia, para 088 e 089 não editarem a mesma porta), **090**, **092**, **093**, **094** (8 arquivos de teste e o save), **095** e **098**: cada uma em duas ou três partes (por exemplo 094a: comida do mercado convive com o `FoodStub`; 094b: remover o `FoodStub`).

**Trabalho em paralelo sem tocar nos mesmos arquivos** (por pasta, não por pessoa):

| Frente | Ordem | Observação |
|---|---|---|
| **Economia** (`src/sim/economy/`, `data/goods`, `recipes`) | 088a → (088 ‖ 089) → (090 ‖ 092) → 091 → 096 → 100 → 101 → 103 | 090 e 092 não dependem um do outro |
| **`npc`** (`src/sim/npc/`, `data/actions*`, `npc_setup.gd`, testes de vida) | 093 → 094/095 → 104 | **um agente só:** `npc_module.gd`, `action_runner.gd` e `npc_persistence.gd` são comuns a todas |
| **Mundo e apresentação** (`world`, `data/world`, `bridge`, `presentation`) | 097 → 099 → 105 → 106 → 107 | a 097 pode andar já ao lado da economia, **mas muda `population.json` e os hashes do `npc`** |
| **Só leitura** | 108 (painel) · 114 (`check_temp`, só `tools/`, depois de 094 e 095) | cabem ao lado de qualquer frente |
| **Fim de fase (em série)** | 109 → 110 → 111 → 112 → 113 → 115 → 116 | mesmos soaks |

Conflitos prováveis (resolvem-se mantendo as duas partes): `ROADMAP_STATUS.md`, `README.md`, `backlog.md`, `events.md` e a porta `economy/api/`.

## e) Backlog a fazer ANTES da Fase 3

| Item | Por que antes | Tamanho | Quando |
|---|---|---|---|
| **Dividir `npc_module.gd`, `npc_thinker.gd`, `action_runner.gd`** (backlog L139; 620, 455 e 416 linhas, ~346, ~328 e ~304 de código) | a 093, 094 e 095 mexem nos três; dividir depois gera conflito | **G:** refatoração, mesma saída (oráculo, hash de 30 dias, `run_sim`) | antes da LW-093 |
| **Ids de conteúdo em dados** (L175: `"work"`, `"help"`, `"flee"`...) | a 093 cria `buy`/`sell` e a 095 mexe em `work`; hoje um id mudado em `data/` quebra o código sem aviso | **P:** verificador de ~60 linhas | antes da LW-093 |
| **Save do `FoodStub`** (fora do backlog; está no `npc.md` e em `npc_persistence.gd`, chave `food_stock`) | remover o estoque muda o save com `save_version` em 2 | **P:** tirar a chave, rejeitar save antigo com mensagem clara, teste | dentro da LW-094b |
| **Apagar `test_food_stub.gd` e `test_income_stub.gd`** | AGENTS 9.5 proíbe apagar teste sem explicar | **P**, mas pede **sua autorização escrita** no texto da 094 e da 095 | no prompt da 094 e da 095 |
| **`data` com listas aninhadas** (L114) | receitas têm insumos e produtos em lista | **M** (~250 linhas), ou **zero** com tabelas planas | decidir na 087a; **recomendo tabelas planas** |
| **Tipos de retorno da `api/` do `npc`** (L206) | porta limpa antes de a economia chamá-la; edita o oráculo (precisa da sua ordem) | **M:** ~12 arquivos | pode esperar a LW-115 |
| **Tamanho do save** (L117; DEC-084: reavaliar perto de 1 MB; hoje ~340 KiB sem comprimir) | contas, inventários e mercados vão crescê-lo | **P:** medir | LW-109 |

**Para levar à LW-087a:** aprovar DEC-047 e DEC-049; confirmar 3 assentamentos, os 10 bens e as 4 cadeias; responder as contradições 1 a 6; decidir se a refatoração do `npc` vem antes da LW-093.
