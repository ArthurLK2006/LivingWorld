# Fila operacional — Living World

Reflete o roadmap oficial ([DEVELOPMENT_ROADMAP.md](../DEVELOPMENT_ROADMAP.md)) e o [ROADMAP_STATUS.md](../ROADMAP_STATUS.md); **não os substitui** (em conflito, valem eles). O Maestro a atualiza a cada PR. Método aprovado por Arthur em 14/11/2026 (Opção A: roadmap integral, sem corte nem antecipação de fase).

**Atualizada em 14/11/2026 · `main` 1cab466, CI verde · proteção do `main` ativa (PR e `check_all` obrigatórios, sem force-push nem exclusão, inclui administradores) · cota semanal em 84%, o teto de agentes é 2.**

## Regras da fila
- **Frentes são papéis por tarefa, não sessões:** A caminho crítico · B independentes liberadas · C arte, qualidade e suporte já autorizados. Teto de agentes ativos pela cota: 3 abaixo de 60%, 2 de 60 a 85%, 1 acima de 85%. Não se ocupa frente à toa.
- Uma tarefa só inicia com: dependências satisfeitas (integradas no `main` com CI verde), escopo e contrato aprovados, arquivos sem conflito (matriz abaixo), worktree próprio e critério de aceite objetivo. Nada de antecipar fase nem decisão obrigatória.
- Classes de risco (orientação; **não substituem o AGENTS.md**): 1 sem efeito no jogo (CI e conferência) · 2 código num módulo, sem mexer em contrato, save, evento, valor [HIP] ou design (mais revisor independente) · 3 contratos, save, eventos, balanceamento, design, vários módulos (revisor e aceite de Arthur) · 4 irreversível, custo, dependência, arquivo protegido, tag (Arthur antes e depois).
- Só Arthur aceita (isso é o que conta no ROADMAP_STATUS). **Até a emenda ao AGENTS ser aprovada** ([EMENDA_AGENTS_PROPOSTA.md](EMENDA_AGENTS_PROPOSTA.md)), a próxima tarefa de código só começa com ordem dele; o que ele já autorizou por escrito segue.

## Em andamento
| Tarefa | Frente | Classe | Estado | Responsável | Ramo ou PR | Próximo passo |
|---|---|---|---|---|---|---|
| ART-3 variantes por mercado (A, B, C) | C | 2 | testes e capturas feitos; junta com o `main` | Maestro | `arte-3-variantes-por-mercado` | recapturar, abrir PR, CI, integrar |
| LW-107a contrato do quadro de contratos | B | 3 | agente escrevendo os documentos | implementador | `lw-107a-contrato-quadro` | PR em rascunho; contrato aprovado por Arthur |
| LW-098a contrato do comerciante e da `Caravan` | A | 3 | agente de leitura gerando a especificação | Plan | — | documento, perguntas a Arthur |
| Pacote de aceite 1 (6 tarefas no `main`) | B | 1 | pronto neste PR | Maestro | este PR | aceite formal de Arthur |
| Emenda ao AGENTS (mandato de execução) | — | 4 | texto pronto neste PR | Maestro | este PR | aprovação de Arthur |

## Aguardando aceite de Arthur (já no `main`)
LW-093, LW-096, LW-097 (com ressalva) e LW-105 com proposta de aceite; LW-108 depois da conferência na janela; LW-095 **parcial** (não aceitar). Detalhes e evidências: [PACOTE_ACEITE_1.md](PACOTE_ACEITE_1.md). Na Fase 3 o placar oficial é 7 de 30 e iria a 11 (a 12 com a LW-108). Fora da Fase 3, sem ação agora: LW-117 e LW-146 (só documentos) e LW-118, no `main` sem contar.

## Liberadas depois das aprovações indicadas
| Tarefa | Depende de | Faixa (conflito) |
|---|---|---|
| LW-107b ponte, 107d ViewModel, 107g teste do ciclo, 107e1 e 107e2 aba | contrato 107a aprovado | bridge, presentation (sem conflito com a LW-098) |
| LW-107c postador de contratos | 107a aprovado | **economia e hash** (exclusiva: nunca junto de 098, 100 ou 103); PARA se um hash aprovado mudar (DEC-175) |
| LW-098 comerciante e `Caravan` (e 098b em diante) | contrato 098a aprovado | **economia, save e hash** (exclusiva) |
| LW-099 viagem visível | LW-098 | world, presentation |
| LW-100 fluxo agregado, LW-103 produtores adaptativos | contrato próprio; LW-098 integrada | economia (exclusiva) |

## Bloqueio do caminho crítico: LW-094 (FoodStub) e o fim do IncomeStub da LW-095
**Não removo o `FoodStub` nem introduzo salário artificial** (ordem de Arthur, 14/11/2026). Linha de base ([diagnóstico](../economia/diagnostico-economico-12-11.md), [resultados](../economia/experimentos/resultados-30-dias.md)): com o código que tira o `FoodStub` (ramo `lw-094a-fim-do-foodstub-codigo`) os 132 NPCs morrem até o dia 14; com o `FoodStub` vivem, mas 0 dos 14 locais de produção rodam no dia 30. Causas medidas: o local paga mais folha do que vende; o spread deixa o dinheiro no mercado (89% no dia 30); sem `data/economy/service_posts.json` os 30 guardas e estalajadeiros não têm posto; 52 NPCs trabalham em cadeias sem comprador final. O que sustentou nos cenários exige regra de folha ociosa, que não está autorizada.
**Cadeia:** LW-095 (fim do `IncomeStub`) e LW-094 travam LW-104, LW-109 e LW-114, e por elas a LW-110 e o portão. **Pontos de reavaliação, para o bloqueio não aparecer só na LW-110:** (1) logo depois da LW-098, (2) depois da LW-103, (3) depois da LW-100; em cada um rodo `tools/measure_economy --days 30` (3 sementes) e o cenário do ramo `lw-094a`, e levo a Arthur vivos, locais rodando e o que falta. Só se o cenário fechar sem regra artificial proponho a LW-094. O arquivo `service_posts.json` (dado da LW-095) muda hash: a tarefa PARA e mostra antes, depois e causa.

## Matriz de conflito (duas tarefas só andam juntas se não dividirem faixa)
economia (`src/sim/economy/**`, bloco de save, hora da produção) e **hash** (oráculo, soak de 30 dias) são exclusivos, uma tarefa por vez · npc (`src/sim/npc/**`) · world (`src/sim/world/**`, `data/world/`) · bridge (`src/bridge/**`) · presentation (`src/presentation/**`) · contratos em documentos (`docs/modules/*.md`, `docs/economy/dados.md`: PRs em sequência) · arte (`src/presentation/world_view/plaza/**`).

## Higiene (nada é apagado sem autorização específica)
115 worktrees, 102 em ramos já integrados ao `main`, 7 destacados; 8 ramos remotos sem integração (`lw-093-npcs-no-mercado`, `lw-094a-fim-do-foodstub-codigo`, `lw-117-prevoo-fase-4`, `mac-snapshot`, `piloto-ci`, `status-a`, `status-b`, `status-c`). Gerar a lista: `git worktree list` e `git branch -r --no-merged origin/main`. Limpeza só com ordem de Arthur.
