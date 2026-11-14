# Fila operacional — Living World

Reflete o roadmap oficial ([DEVELOPMENT_ROADMAP.md](../DEVELOPMENT_ROADMAP.md)) e o [ROADMAP_STATUS.md](../ROADMAP_STATUS.md); **não os substitui** (em conflito, valem eles). O Maestro a atualiza a cada PR. Método aprovado por Arthur em 14/11/2026 (Opção A: roadmap integral, sem corte nem antecipação de fase).

**Atualizada em 14/11/2026 (tarde) · `main` 4cca312 · proteção do `main` ativa (PR e `check_all` obrigatórios, sem force-push nem exclusão, inclui administradores) · cota semanal em 88%, teto de 2 agentes · Mandato 1 em vigor (seção 14.1 do AGENTS.md integrada em 8af0837): [MANDATO_1.md](MANDATO_1.md).**

## Regras da fila
- **Frentes são papéis por tarefa, não sessões:** A caminho crítico · B independentes liberadas · C arte, qualidade e suporte já autorizados. Teto de agentes ativos pela cota: 3 abaixo de 60%, 2 de 60 a 85%, 1 acima de 85%. Não se ocupa frente à toa.
- Uma tarefa só inicia com: dependências satisfeitas (integradas no `main` com CI verde), escopo e contrato aprovados, arquivos sem conflito (matriz abaixo), worktree próprio e critério de aceite objetivo. Nada de antecipar fase nem decisão obrigatória.
- Classes de risco (orientação; **não substituem o AGENTS.md**): 1 sem efeito no jogo (CI e conferência) · 2 código num módulo, sem mexer em contrato, save, evento, valor [HIP] ou design (mais revisor independente) · 3 contratos, save, eventos, balanceamento, design, vários módulos (revisor e aceite de Arthur) · 4 irreversível, custo, dependência, arquivo protegido, tag (Arthur antes e depois).
- Só Arthur aceita (isso é o que conta no ROADMAP_STATUS). A seção 14.1 do AGENTS.md (Mandato de Execução) está **em vigor** desde 14/11 (PR #34): só as tarefas **nomeadas** no [MANDATO_1.md](MANDATO_1.md) começam sozinhas, nunca antes de contrato e escopo aprovados; integração de classe 3 só com o "APROVADO" dele e de classe 4 só com ordem expressa; antes de integrar, a verificação cobre a combinação com o `main` mais recente (a regra geral 10.11 está aprovada e segue em PR de classe 4).

## Em andamento
| Tarefa | Frente | Classe | Estado | Ramo ou PR | Próximo passo |
|---|---|---|---|---|---|
| LW-098a contrato do comerciante e da `Caravan` | A | 3 | aprovado por Arthur; duas revisões independentes feitas; CI rodando | PR #35 | integrar; liberar a 098b |
| ART-6a vegetação por variante (B e C) | C, Mandato 1 | 2 | revisão estreita e CI rodando | PR #39 | integrar |
| Pesquisa de leitura na web de kits CC0 de personagens e criaturas | C (DEC-021) | 1 | agente de leitura, sem baixar nada | — | amostras (Kenney Fantasy Town e até 2 de personagem) só com licença e fonte verificadas |
| Registro dos aceites de LW-093, LW-096, LW-097 e LW-105 | — | 1 | PR de documentos | este PR | integrar |
| DEC-021 aprovada e nota da DEC-020 | — | 4 | aprovada por Arthur; a preparar | a abrir | revisão independente, CI, integrar |
| LW-096: aceite com prazo (`ContractBook.accept(..., now)`) | B | 3 | aprovada por Arthur; a implementar | a abrir | PR isolado, revisão, CI, regressão de hashes (PARA se um mudar, DEC-175) |
| AGENTS.md 10.11 (opção B) | — | 4 | aprovada por Arthur; a preparar | a abrir | revisão independente, CI, integrar |

## Aceites
LW-093, LW-096, LW-097 (**com a ressalva do estoque provisório de 6.000 de comida do povoado C**) e LW-105 **aceitas por Arthur em 14/11/2026** (Fase 3: 11 de 30, 36,7%; projeto: 98 de 192, 51,0%); registro no ROADMAP_STATUS em PR. **LW-095 pendente** (`IncomeStub` presente; falta `service_posts.json`); **LW-108 aguarda a validação manual dele na janela**. Evidências e hashes: [PACOTE_ACEITE_1.md](PACOTE_ACEITE_1.md).

## Liberadas pelo Mandato 1 (entram quando houver vaga de agente e sem conflito de faixa)
| Tarefa | Frente | Observação |
|---|---|---|
| **098b** planejador de lucro (arquivos novos, sem estado nem hash) | A | depois do #35; economia (arquivos novos) |
| **107b** ponte; **107c1** dados do postador; depois 107d, 107e1, 107e2, 107g; **107c2** por último | B | contrato 107a integrado; 107c1 mexe em `EconomyDefinitions` (sequenciar com 098c e 098d1); 107c2 PARA se um hash mudar |
| 098c a 098g (em sequência, 098d dividida em 098d1, 098d2 e 098d3; 098f em 098f1 e 098f2) | A | **098h fora do mandato**; PARA se um valor aprovado mudar |
| **LW-107f** trabalho do jogador | B | **obrigatória**, sem contrato, depende de regra de trabalho no `world`; não dada por concluída por antecipação |
| LW-099 viagem visível; LW-100 fluxo agregado; LW-103 produtores adaptativos | — | fora do mandato; dependem da 098 e de contrato próprio |

## Trilha de arte (Frente C; usa esta fila)
DEC-021 aprovada como **direção híbrida** (cenário procedural e modular; personagens e criaturas por kits CC0 quando compatíveis; modelo provisório não é definitivo sem o aceite visual de Arthur; áudio pendente). Tudo é só apresentação: aparência determinística por identificadores, LOD e DEC-119.
- **ART-6a** vegetação por variante (PR #39). **Avaliar vegetação também na praça A**, preservando a identidade da variante e o desempenho.
- **Praça B: margem de só 59 triângulos:** antes de aumentar limites, otimizar e reutilizar as malhas existentes.
- **ART-8** casas: amostra de arquitetura modular, isolada (não substitui as caixas do mundo antes do aceite visual); preserva colisão, navegação e dados da simulação.
- **ART-9** humano estilizado: pesquisa e amostra isolada (aparência e animações básicas); testa importação, desempenho e compatibilidade visual.
- Depois do aceite visual: aditivo ao mandato para as implementações completas. Em espera: ART-6b (caminhos e mistura de terreno só visuais), ART-7 (adereços de povoado), ART-10 (carrinho, com a LW-099); Fase 4: ART-11; Fase 5: ART-12 a 14.

## Bloqueio do caminho crítico: LW-094 (FoodStub) e o fim do IncomeStub da LW-095
**Não removo o `FoodStub` nem introduzo salário artificial** (ordem de Arthur, 14/11/2026). Linha de base ([diagnóstico](../economia/diagnostico-economico-12-11.md), [resultados](../economia/experimentos/resultados-30-dias.md)): com o código que tira o `FoodStub` (ramo `lw-094a-fim-do-foodstub-codigo`) os 132 NPCs morrem até o dia 14; com o `FoodStub` vivem, mas 0 dos 14 locais de produção rodam no dia 30. Causas medidas: o local paga mais folha do que vende; o spread deixa o dinheiro no mercado (89% no dia 30); sem `data/economy/service_posts.json` os 30 guardas e estalajadeiros não têm posto; 52 NPCs trabalham em cadeias sem comprador final. O que sustentou nos cenários exige regra de folha ociosa, que não está autorizada. **Medição de 14/11/2026** (`tools/measure_economy`, 30 dias, `main` 74dd303): 132 vivos pelo `FoodStub`, mas 0 de 14 locais produzindo desde o dia 7 (todos parados por falta de dinheiro), nenhum posto e 82% do dinheiro nos mercados; os 132 vivos não provam economia sustentável.
**Cadeia:** LW-095 (fim do `IncomeStub`) e LW-094 travam LW-104, LW-109 e LW-114, e por elas a LW-110 e o portão. **Pontos de reavaliação, para o bloqueio não aparecer só na LW-110:** (1) logo depois da LW-098, (2) depois da LW-103, (3) depois da LW-100; em cada um rodo `tools/measure_economy --days 30` (3 sementes) e o cenário do ramo `lw-094a`, e levo a Arthur vivos, locais rodando e o que falta. Só se o cenário fechar sem regra artificial proponho a LW-094. O arquivo `service_posts.json` (dado da LW-095) muda hash: a tarefa PARA e mostra antes, depois e causa.

## Matriz de conflito (duas tarefas só andam juntas se não dividirem faixa)
economia (`src/sim/economy/**`, bloco de save, hora da produção) e **hash** (oráculo, soak de 30 dias) são exclusivos, uma tarefa por vez · npc (`src/sim/npc/**`) · world (`src/sim/world/**`, `data/world/`) · bridge (`src/bridge/**`) · presentation (`src/presentation/**`) · contratos em documentos (`docs/modules/*.md`, `docs/economy/dados.md`: PRs em sequência) · arte (`src/presentation/world_view/plaza/**`).

## Higiene (nada é apagado sem autorização específica)
116 worktrees fora o principal: **97 integrados e sem alteração local** (candidatos à limpeza), **4 integrados mas com 1 alteração local cada** (`lote-1` a `lote-4`: olhar antes de qualquer limpeza), 8 em ramos ainda não integrados (os 2 desta fila, `arte-f0-componentes`, `lw-117`, `piloto-ci`, `status-a`, `status-b`, `status-c`) e 7 destacados. Ramos remotos sem integração: `lw-093-npcs-no-mercado`, `lw-094a-fim-do-foodstub-codigo`, `lw-117-prevoo-fase-4`, `mac-snapshot`, `piloto-ci`, `status-a`, `status-b`, `status-c`. Gerar a lista: `git worktree list` e `git branch -r --no-merged origin/main`. **Nada é apagado: a limpeza só com ordem específica de Arthur.**
