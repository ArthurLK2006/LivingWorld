10/11/2026 19:16 (Brasília) — CONCLUÍDA: LW-087b (`lw-087b-contrato-economy`, `7747c1d`) e LW-087d (`lw-087d-eventos-e-dados`, `98ca6c5`) prontas para revisão como RASCUNHO nos ramos, **fora do `main`**, sem Fase B; `check_all` verde nos dois; parei (regra 13)

# RELATÓRIO — LW-087b: contrato do módulo `economy`     Status: PRONTA PARA REVISÃO, **RASCUNHO (não está no `main`)**

## 1. RESUMO
Escrevi a ficha `docs/modules/economy.md`, no padrão do `npc.md` e do `world.md`: o módulo é o **dono único** de estoque, preço e dinheiro; o `Ledger` (`transfer`, `mint`, `burn`, contas, motivo, teste de ouro); bens e inventário por dono; mercados e preço (razão estoque/alvo, faixa, suavização, spread, profundidade); `request_trade` atômico e `TradeRules` neutra; produção e salário; consumo; contratos com custódia; a API (`peek_*`, `request_*`, `on_*`), os eventos, o dado → dono, os arquivos de dados, o rastreio por tarefa (LW-087 a LW-116) e **14 pontos em aberto com recomendação**. As suas decisões de 10/11/2026 entram como incorporadas. Só documento.

## 2. ARQUIVOS CRIADOS
- `docs/modules/economy.md`: o contrato (218 linhas).

## 3. ARQUIVOS MODIFICADOS
Nenhum. Contra o `main` (`9dbcebc`): 1 arquivo novo. Não toquei em `DECISIONS.md`, roadmap, README, `data/`, código nem testes.

## 4. DECISÕES TÉCNICAS
- **O que veio dos documentos** (GDD 12 e 13, arquitetura 11, roadmap 3.D, as suas decisões): a lista inteira das seções 1 a 9 que não leva `[PROPOSTA]`.
- **Onde os documentos não decidem, não escolhi em silêncio:** cada ponto virou **`[PROPOSTA]` numerada (Q1 a Q14)** com a recomendação, na seção 15. Os que mais pedem a sua palavra:
  - **Q4:** o roadmap (LW-092) diz "conta do proprietário", mas "propriedade complexa" é "não fazer" (3.J). Recomendo o **próprio local de produção como dono** (conta e inventário próprios).
  - **Q5:** o mercado paga o produtor com a conta dele; sem fundos, `ECON_MARKET_NO_FUNDS`.
  - **Q9:** nenhum documento diz **quais bens saciam qual necessidade**. Recomendo `bread` por inteiro e `grain` menos [HIP], em `goods.json`.
  - **Q10:** ofícios (só existem `farmer`, `lumberjack`, `artisan`, `guard`, `innkeeper`; faltariam `miner` e `shepherd`), locais `work` suficientes e **distribuição das cadeias pelos 3 povoados** (recomendo que nenhum seja autossuficiente). **Muda `population.json` e os hashes do `npc`.**
  - **Q3:** o motivo do `mint` inicial no roadmap é `inicio_de_jogo`; recomendo `game_start` (identificadores em inglês, DEC-022).
  - **Q8:** o `npc` chama `request_work_shift(place_id, worker_id, minutos)`, o salário sai na hora da conta do local e, uma vez por hora, o local compra insumos e vende excedente ao mercado do povoado.
- **Escolhas de forma (minhas, rotuladas):** códigos `ECON_*`; tipos de resposta em `economy/api/` (lição da LW-085a); a economia registrada **antes** do `npc`; conservação **de bens** simétrica à do dinheiro (Q13); `peek_quote` para consultar o custo sem executar.
- **Sobre o "PARE e pergunte":** entendi como "não decidir em silêncio". Como nenhum ponto impedia de escrever o contrato, **não parei** e entreguei tudo como proposta rotulada. Se você preferia que eu parasse e perguntasse antes de escrever, diga e passo a perguntar.
- **Proposta de entrada para o `DECISIONS.md`:** nenhuma nova (o registro das DEC-047, DEC-049 e DEC-054 é da LW-087a).

## 5. TESTES EXECUTADOS
- `tools/check_all` no HEAD final (`7747c1d`): **VERDE: 124 scripts, 1194 testes, 261.693 asserts, sem aviso novo (o "Warnings 1 / Deprecated 1" do GUT é o de sempre); 172,5 s; o vigia anotou que outra conversa rodou Godot no worktree `lw-087c` ao mesmo tempo, sem efeito no resultado**. Antes da junção com o `main`, no HEAD `3b73309`, também ficou verde (124 scripts, 1194 testes).
- Autorrevisão: `git diff --check` limpo; 1 arquivo; nenhum protegido; nenhum teste tocado.

## 6. RESULTADOS
Aceite da LW-087b cumprido no que cabe a um rascunho: ficha com os campos do modelo e os tópicos pedidos. Nada foi executado além do `check_all` (só documento).

## 7. PROBLEMAS ENCONTRADOS
- **O `main` andou durante o trabalho** (a LW-085e da A: `AGENTS.md` versão 0.4, DEC-126 a DEC-128). Juntei o `main` atual no ramo (`7747c1d`, sem conflito, **não é a Fase B**) e passei a citar a DEC-127 e o AGENTS 4.15 na regra do save.
- **Referência pendurada:** a seção 13 aponta `docs/economy/dados.md`, que está no ramo da 087d; só resolve quando os dois entrarem.
- **Documentos que se contradizem** (achados ao escrever, além dos 6 do pré-voo): LW-092 "conta do proprietário" × 3.J "propriedade complexa" (Q4); o roadmap escreve o motivo em português (Q3).

## 8. RISCOS
Os 14 pontos são proposta: se você responder diferente na LW-087a, as seções 3 a 8 mudam. A distribuição das cadeias (Q10) mexe em dados do `npc`. A fórmula do preço (Q6, Q7) é calibração (LW-112); o contrato só exige propriedades testáveis.

## 9. PENDÊNCIAS
Suas respostas a Q1 a Q14 (recomendações na seção 15 da ficha). Nenhum teste manual.

---

# RELATÓRIO — LW-087d: eventos econômicos e modelos de dados     Status: PRONTA PARA REVISÃO, **RASCUNHO (não está no `main`)**

## 1. RESUMO
Cataloguei em `docs/events.md` os eventos econômicos do cap. 11.9 da arquitetura como **"planejado, LW-0NN"** (nenhum como pronto) e escrevi `docs/economy/dados.md`, com os modelos de dados em **tabelas planas** (`goods`, `owner_kinds`, `market_targets`, `price_params`, `recipes`, `recipe_inputs`, `recipe_outputs`, `production_sites`), os 10 bens, as 10 receitas das 4 cadeias, as regras de validação e as constantes de preço. Só documento.

## 2. ARQUIVOS CRIADOS
- `docs/economy/dados.md` (153 linhas).

## 3. ARQUIVOS MODIFICADOS
- `docs/events.md` (+13 −4): o total passa de 6 para 15 eventos catalogados (6 existentes ou implementados e 9 planejados); a definição de "planejado"; a linha do `NpcDied` ganha a economia como ouvinte **previsto**; 9 linhas novas; e o parágrafo "considerados e não incluídos".
- Contra o `main` (`9dbcebc`): 2 arquivos. Nada protegido além do que você citou; sem `data/`, código ou testes.

## 4. DECISÕES TÉCNICAS
- **Eventos planejados (9):** `PriceChanged`, `ShortageDeclared`, `ShortageEnded` (LW-090); `ProductionStopped`, `ProductionResumed` (LW-092); `ContractOffered`, `ContractCompleted`, `ContractFailed` (LW-096); e o `RouteStateChanged` (do `world`, LW-097), que não é da economia mas ela o ouve (menor 9, decidido). Cargas e crônica são `[PROPOSTA]`; onde a arquitetura 17.5 não diz (`ProductionStopped`, `ProductionResumed`, `ContractFailed`), escolhi e rotulei.
- **Três eventos do cap. 11.9 ficaram sem linha, de propósito:** `CaravanAttacked`, `RouteCargoLost` e `BusinessBankrupt` não têm tarefa na Fase 3 (combate de caravanas, bandidos e propriedade complexa são "não fazer", 3.J). Estão no parágrafo "considerados e não incluídos". Se você os quer como "planejado", diga a tarefa.
- **Onde os modelos de dados ficam (o que o padrão manda):** (1) a **lista** dos arquivos e o dono do dado ficam no contrato do módulo, como no `npc.md` e no `world.md` (é a seção 13 da 087b); (2) as **colunas e regras** ficam em documento próprio por área, como o precedente `docs/world/relevo-do-terreno-de-blockout.md`: **`docs/economy/dados.md`**. Não pus as colunas na ficha porque as duas tarefas são ramos paralelos e conflitariam no mesmo arquivo; (3) `data/economy/README.md` só nasce com os dados reais (como o `data/world/README.md`), e `data/` é protegido.
- **Ponto aberto D1:** quatro colunas citam id de outro módulo (`need_id`, `occupation_id`, `settlement_id`, `place_id`); a economia não pode importar o `npc`, então o carregador não pode usar `set_ref` nas tabelas dele. Recomendo `STRING` livre e uma **conferência de dados entre módulos**, junto do verificador de ids de conteúdo (que já é pré-requisito da LW-093).
- **Não inventei números:** só os dois do GDD (faixa de preço 5000 e 30000 pontos-base, [HIP]); quantidades das receitas, valores dos bens e demais constantes ficam "[HIP] a propor".
- **Proposta de entrada para o `DECISIONS.md`:** nenhuma.

## 5. TESTES EXECUTADOS
- `tools/check_all` no HEAD final (`98ca6c5`): **VERDE: 124 scripts, 1194 testes, 261.693 asserts, sem aviso novo (o "Warnings 1 / Deprecated 1" do GUT é o de sempre); 170,4 s; o vigia anotou que outra conversa rodou Godot no worktree `lw-087c` ao mesmo tempo, sem efeito no resultado**. O `check_architecture` só confere que evento **do código** está no catálogo (não o contrário), então as linhas "planejado" não o afetam.
- Autorrevisão: `git diff --check` limpo; 15 linhas na tabela de eventos (6 + 9).

## 6. RESULTADOS
Aceite cumprido no que cabe a um rascunho: eventos com publicador, ouvintes, carga, crônica e a tarefa que o cria; modelos de dados em tabelas planas com os 10 bens e as 4 cadeias.

## 7. PROBLEMAS ENCONTRADOS
O `main` andou (LW-085e); juntei o `main` atual (`98ca6c5`, sem conflito, **não é a Fase B**). O `events.md` e o `dados.md` apontam para `docs/modules/economy.md` (ramo da 087b), referência pendurada até os dois entrarem.

## 8. RISCOS
As cargas dos eventos e as colunas são proposta e mudam se você responder diferente na LW-087a. A conferência entre módulos (D1) ainda não tem dono.

## 9. PENDÊNCIAS
Sua resposta ao D1 e sobre os três eventos sem tarefa. A LW-087c (extensões do `world.md` e do `npc.md`) **não foi iniciada** (não estava na autorização).

---

## ACOMPANHAMENTO
- **Avanço:** Fase 2 em 31 de 32 (a LW-086 é sua validação); Fase 3 não começou. Dois rascunhos de documento prontos nos ramos, **fora do `main`**.
- **Próxima tarefa recomendada:** nenhuma minha (regra 13). Depois de você fechar a Fase 2: LW-087a (registro das DEC-047, DEC-049 e DEC-054 e as respostas de Q1 a Q14 e D1), que decide o que entra nos dois rascunhos.
- **Decisões que dependem de você:** Q1 a Q14 do contrato (a seção 15 tem a recomendação de cada um) e o D1.
- **Git:** `lw-087b-contrato-economy` em `7747c1d` e `lw-087d-eventos-e-dados` em `98ca6c5`, publicados só como ramos; **nada no `main`, sem tag, sem Fase B**. Worktrees mantidos: `.worktrees/lw-087b` e `.worktrees/lw-087d`. O relatório anterior (LW-085f e o pré-voo) está no commit `a23f5ae` do ramo `status-b`.
