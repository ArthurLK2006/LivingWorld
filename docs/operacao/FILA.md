# Fila operacional — Living World

Reflete o roadmap oficial ([DEVELOPMENT_ROADMAP.md](../DEVELOPMENT_ROADMAP.md)) e o [ROADMAP_STATUS.md](../ROADMAP_STATUS.md); **não os substitui** (em conflito, valem eles). O Maestro a atualiza a cada PR. Método aprovado por Arthur em 14/11/2026 (Opção A: roadmap integral, sem corte nem antecipação de fase).

**Atualizada em 14/11/2026 (tarde) · `main` 67e1f4a, CI verde · proteção do `main` ativa (PR e `check_all` obrigatórios, sem force-push nem exclusão, inclui administradores) · cota semanal em 89% (reseta à meia-noite de 15/11), teto de 2 agentes · Mandato 1 em vigor ([MANDATO_1.md](MANDATO_1.md)) · regra 10.11 do AGENTS.md em vigor (verificar o ramo combinado com o `main` mais recente; atualizar por `merge`, nunca `rebase`).**


## Regras da fila
- **Frentes são papéis por tarefa, não sessões:** A caminho crítico · B independentes liberadas · C arte, qualidade e suporte já autorizados. Teto de agentes ativos pela cota: 3 abaixo de 60%, 2 de 60 a 85%, 1 acima de 85%. Não se ocupa frente à toa.
- Uma tarefa só inicia com: dependências satisfeitas (integradas no `main` com CI verde), escopo e contrato aprovados, arquivos sem conflito (matriz abaixo), worktree próprio e critério de aceite objetivo. Nada de antecipar fase nem decisão obrigatória.
- Classes de risco (orientação; **não substituem o AGENTS.md**): 1 sem efeito no jogo (CI e conferência) · 2 código num módulo, sem mexer em contrato, save, evento, valor [HIP] ou design (mais revisor independente) · 3 contratos, save, eventos, balanceamento, design, vários módulos (revisor e aceite de Arthur) · 4 irreversível, custo, dependência, arquivo protegido, tag (Arthur antes e depois).
- Só Arthur aceita (isso é o que conta no ROADMAP_STATUS). A seção 14.1 do AGENTS.md (Mandato de Execução) está **em vigor** desde 14/11 (PR #34): só as tarefas **nomeadas** no [MANDATO_1.md](MANDATO_1.md) começam sozinhas, nunca antes de contrato e escopo aprovados; integração de classe 3 só com o "APROVADO" dele e de classe 4 só com ordem expressa; antes de integrar, a verificação cobre a combinação com o `main` mais recente (a regra geral 10.11 está aprovada e segue em PR de classe 4).

## Em andamento
| Tarefa | Frente | Classe | Estado | Ramo ou PR | Próximo passo |
|---|---|---|---|---|---|
| LW-098b2 planejador de lucro (2ª metade da 098b) | A | 2 | duas revisões independentes (achados corrigidos: saída antecipada e folga da tarifa), 403 linhas de código e teste, CI rodando | PR #45 | integrar |
| LW-107b1 consulta do quadro de contratos (1ª metade da 107b) | B | 2 | **Arthur escolheu dividir a 107b** (sem exceção ao teto do AGENTS 5.2); código e testes já revisados, recortados na fronteira consulta/comandos; cerca de 275 linhas; CI rodando | PR #47 | integrar; libera a 107b2 e a 107d |
| LW-107b2 aceitar e entregar (2ª metade da 107b) | B | 2 | revisada por inteiro (sem defeito de código); o PR #44 vira só esta parte depois do #47, com o `main` mesclado | PR #44 | atualizar com o `main`, CI, integrar; conferir que o resultado final é o revisado |
| LW-098c `Caravan`, `CaravanBook`, tipo de dono `merchant` e a chave `caravans` do save | A | **3** (save) | agente implementando; livro nasce vazio, hashes não mudam | ramo `lw-098c-caravan-e-livro` | revisão e CI; **só integra com o "APROVADO" de Arthur**; PARA se um hash mudar; se passar de 450 linhas, divide |
| ART-9 e ART-9b habitantes e vila de teste com a Kenney (protótipo isolado, procedural) | C | — | duas rodadas de capturas entregues a Arthur (corpo em sino, capuz grosso, bochechas, botas redondas); **ele gostou da direção e ainda não aprovou a aparência** | ramo `art-9-habitantes-prototipo` (sem PR; a dividir quando virar PR) | recolorir a paleta da Kenney, refinar o capelo e a largura; novas capturas para o aceite visual antes de qualquer adoção |

## Aceites
LW-093, LW-096, LW-097 (**com a ressalva do estoque provisório de 6.000 de comida do povoado C**) e LW-105 **aceitas por Arthur em 14/11/2026** (Fase 3: 11 de 30, 36,7%; projeto: 98 de 192, 51,0%), registradas no ROADMAP_STATUS (PR #40). **LW-095 pendente** (`IncomeStub` presente; falta `service_posts.json`); **LW-108 aguarda a validação manual dele na janela**. Evidências e hashes: [PACOTE_ACEITE_1.md](PACOTE_ACEITE_1.md).

## Integradas no `main` em 14/11/2026 (pelo Maestro, com o Mandato 1)
Contratos 107a (#33) e 098a (#35); emenda do AGENTS 14.1 (#34) e regra 10.11 (#41); DEC-021 aprovada (#42); ART-3, ART-5a, ART-5b1 e ART-6a (praças com identidade e vegetação por variante: #29 a #32, #38, #39); correção do prazo do aceite da LW-096 (#43; hashes idênticos, soak `2b0f8a2917c1`); aceites (#40); LW-098b1, parâmetros da caravana e custo de rota (#46).

## Liberadas pelo Mandato 1 (entram quando houver vaga de agente e sem conflito de faixa)
| Tarefa | Frente | Observação |
|---|---|---|
| **107d** `ContractsViewModel`, depois **107e1** (aba de leitura) | B | liberadas quando a 107b1 (#47) entrar; só precisam da consulta |
| **107e2** (aceitar e entregar na tela) e **107g** (teste do ciclo) | B | depois da 107b2 e da 107e1 |
| 098d1, 098d2, 098d3, 098e, 098f1, 098f2, 098g (em sequência) | A | depois da 098c (classe 3); **098h fora do mandato**; PARA se um valor aprovado mudar |
| **107c1** dados do postador; depois **107c2** | B | 107c1 mexe em `EconomyDefinitions` e `EconomySetup` (faixa exclusiva da economia: depois da 098c); 107c2 PARA se um hash mudar |
| **LW-107f** trabalho do jogador | B | **obrigatória**, sem contrato, depende de regra de trabalho do jogador no `world`; não dada por concluída por antecipação |
| LW-099 viagem visível; LW-100 fluxo agregado; LW-103 produtores adaptativos | — | fora do mandato; dependem da 098 e de contrato próprio |

## Trilha de arte (Frente C; usa esta fila)
DEC-021 aprovada como **direção híbrida** (cenário procedural e modular; personagens e criaturas por kits CC0 quando compatíveis; modelo provisório não é definitivo sem o aceite visual de Arthur; áudio pendente). Tudo é só apresentação: aparência determinística por identificadores, LOD e DEC-119.
- **Kenney Fantasy Town Kit 2.0** baixado por Arthur e registrado no [manifesto](../arte/MANIFESTO_LICENCAS.md), seção 7 (CC0, 167 modelos, sem personagens). Amostra de 37 peças só nos protótipos, fora do Git.
- **ART-9 habitantes** (procedurais; a Kenney não traz personagens): fase 1 entregue (6 habitantes, folha de variação, multidão de 132 a 236 fps em depuração); fase 2 em curso. Quando virar PR, dividir (806 linhas de código e teste na fase 1, acima do teto de 450 do AGENTS 5.2).
- **ART-8 casas**: montagem modular de casas da Kenney (escala 2,5 confirmada: parede de 1 vira 2,5 m e o habitante de 1,72 m cabe nas portas), feita na vila de teste da ART-9b; aceite visual antes de trocar as caixas do mundo. **Paleta:** o pacote traz só a variação A (pastel: telhados roxo e azul, árvores verde-menta), que destoa dos habitantes terrosos e da sua referência; **recolorir a textura de paleta** (uma PNG, CC0 permite) para a do guia é o próximo passo (ART-8b). Peças não mescladas somaram 251 chamadas de desenho na vila: mesclar ou instanciar antes de adotar.
- **Avaliar vegetação também na praça A** (preservando a identidade e o desempenho) e, na **praça B, margem de só 59 triângulos**: otimizar e reusar malhas antes de subir limites.
- Em espera: ART-6b (caminhos e mistura de terreno só visuais), ART-7 (adereços de povoado), ART-10 (carrinho, com a LW-099); Fase 4: ART-11; Fase 5: ART-12 a 14.

## Bloqueio do caminho crítico: LW-094 (FoodStub) e o fim do IncomeStub da LW-095
**Não removo o `FoodStub` nem introduzo salário artificial** (ordem de Arthur, 14/11/2026). Linha de base ([diagnóstico](../economia/diagnostico-economico-12-11.md), [resultados](../economia/experimentos/resultados-30-dias.md)): com o código que tira o `FoodStub` (ramo `lw-094a-fim-do-foodstub-codigo`) os 132 NPCs morrem até o dia 14; com o `FoodStub` vivem, mas 0 dos 14 locais de produção rodam no dia 30. Causas medidas: o local paga mais folha do que vende; o spread deixa o dinheiro no mercado (89% no dia 30); sem `data/economy/service_posts.json` os 30 guardas e estalajadeiros não têm posto; 52 NPCs trabalham em cadeias sem comprador final. O que sustentou nos cenários exige regra de folha ociosa, que não está autorizada. **Medição de 14/11/2026** (`tools/measure_economy`, 30 dias, `main` 74dd303): 132 vivos pelo `FoodStub`, mas 0 de 14 locais produzindo desde o dia 7 (todos parados por falta de dinheiro), nenhum posto e 82% do dinheiro nos mercados; os 132 vivos não provam economia sustentável.
**Cadeia:** LW-095 (fim do `IncomeStub`) e LW-094 travam LW-104, LW-109 e LW-114, e por elas a LW-110 e o portão. **Pontos de reavaliação, para o bloqueio não aparecer só na LW-110:** (1) logo depois da LW-098, (2) depois da LW-103, (3) depois da LW-100; em cada um rodo `tools/measure_economy --days 30` (3 sementes) e o cenário do ramo `lw-094a`, e levo a Arthur vivos, locais rodando e o que falta. Só se o cenário fechar sem regra artificial proponho a LW-094. O arquivo `service_posts.json` (dado da LW-095) muda hash: a tarefa PARA e mostra antes, depois e causa.

## Matriz de conflito (duas tarefas só andam juntas se não dividirem faixa)
economia (`src/sim/economy/**`, bloco de save, hora da produção) e **hash** (oráculo, soak de 30 dias) são exclusivos, uma tarefa por vez · npc (`src/sim/npc/**`) · world (`src/sim/world/**`, `data/world/`) · bridge (`src/bridge/**`) · presentation (`src/presentation/**`) · contratos em documentos (`docs/modules/*.md`, `docs/economy/dados.md`: PRs em sequência) · arte (`src/presentation/world_view/plaza/**`).

## Higiene (nada é apagado sem autorização específica)
116 worktrees fora o principal: **97 integrados e sem alteração local** (candidatos à limpeza), **4 integrados mas com 1 alteração local cada** (`lote-1` a `lote-4`: olhar antes de qualquer limpeza), 8 em ramos ainda não integrados (os 2 desta fila, `arte-f0-componentes`, `lw-117`, `piloto-ci`, `status-a`, `status-b`, `status-c`) e 7 destacados. Ramos remotos sem integração: `lw-093-npcs-no-mercado`, `lw-094a-fim-do-foodstub-codigo`, `lw-117-prevoo-fase-4`, `mac-snapshot`, `piloto-ci`, `status-a`, `status-b`, `status-c`. Gerar a lista: `git worktree list` e `git branch -r --no-merged origin/main`. **Nada é apagado: a limpeza só com ordem específica de Arthur.**
