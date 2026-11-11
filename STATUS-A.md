11/11/2026 09:12 (Brasília) · PRONTA PARA REVISÃO · LW-093b: teste de que um ofício novo só por JSON funciona e é validado (ramo `lw-093b-oficio-so-por-json`, commit `1dbf3a8`, empurrado; `main` segue em `63caee7`; `check_all` VERDE; só teste, nenhum código de jogo, nenhum hash mudou); falta a sua auditoria

# RELATÓRIO — LW-093b: ofício novo só por JSON     Status: PRONTA PARA REVISÃO

## 1. RESUMO
Criei **um** arquivo de teste (9 testes) que prova duas coisas. **Primeira:** um ofício acrescentado só como dado (sem tocar em nenhuma linha de código) passa na validação, o NPC com esse ofício nasce, ganha casa e local de trabalho e segue a agenda dele num dia de jogo, como os ofícios que já existem. **Segunda:** um ofício inválido (campo ausente, tipo errado, referência quebrada, id repetido, agenda com lacuna) é recusado com mensagem que diz o arquivo, o item e o campo. O teste passou **sem** alterar `src/`, `data/` nem `tests/fixtures/`; ou seja, **a condição de PARE (AGENTS 16.2: "o ofício ainda depende de código") não ocorreu**. O `check_all` ficou verde e nenhum hash nem valor de referência mudou. Um commit, só o ramo da tarefa e o `status-a` empurrados; o `main` não andou, sem tag.

## Declaração de leitura (início da tarefa)
- **Tarefa:** provar por teste que um ofício só por dado funciona e é validado, como já existe para a ação. Só teste.
- **Li:** `AGENTS.md` v0.4; a linha da LW-093b no roadmap; o teste-modelo (`tests/unit/test_action_catalog.gd`, o caso "uma ação nova só por dados") e os de rotina, população e decisão (`test_routine.gd`, `test_population.gd`, `test_decision_flow.gd`); o código de `routine_loader.gd`, `routine_table.gd`, `population_loader.gd`, `population_plan.gd`, `npc_setup.gd`, `npc_module.gd` e `npc_decision_runtime.gd`; os dados `occupations.json`, `routine_blocks.json` e `population.json`.
- **Decisões e status:** DEC-137 (a própria tarefa), DEC-136, DEC-126, DEC-013, DEC-082 e DEC-086: todas **APROVADAS**. Nenhuma PENDENTE de que a tarefa dependa.

## Como cada ponto do aceite foi cumprido
| Ponto da sua ordem | Onde está (arquivo `tests/unit/test_new_occupation_by_data.gd`) |
|---|---|
| (a) ofício só como dado passa na validação e é usado | `…passes_validation_and_keeps_the_others` (24 horas da agenda nova conferidas; os ofícios antigos ficam iguais); `…without_the_data_the_population_row_is_refused_and_with_it_the_npc_is_born` (sem o dado, a população recusa com `NPC_POPULATION_INVALID_REFERENCE`; com o dado, nasce com local do tipo `work`); `…is_born_and_follows_its_own_agenda_for_a_day` (módulo `npc` e mundo reais, 1.440 passos: nasce, tem casa e local de trabalho, faz a ação da agenda nas horas 3, 6, 8, 21 e 22, e `validate()` do módulo e do mundo fica vazio) |
| (b) ofício inválido é recusado com mensagem clara | `…invalid_occupation_row…` (6 casos: `work_place_kind` ausente, de tipo errado, de tipo de local inexistente, campo desconhecido, id repetido, id fora do padrão); `…invalid_agenda_line…` (7 casos: ação inexistente, ofício inexistente, hora acima de 24, hora como texto, id de bloco repetido, fim antes do início, campo obrigatório ausente); `…does_not_cover_the_whole_day…` (lacuna, não começa em 0, não termina em 24, sem nenhuma linha, sobreposição). Cada caso confere o código `ROUTINE_DATA_INVALID`, que **não** devolve tabela e que a mensagem cita arquivo, item e campo |
| (c) segue o modelo da ação; nasce dentro do teste; sem escrita | O ofício `tinker` e a agenda dele são acrescentados **em memória** às tabelas reais e entram por `RoutineLoader.from_tables` (o mesmo caminho do teste da ação). Nenhum `FileAccess` de escrita, nenhuma pasta temporária: `git diff` do commit é só o arquivo novo |
| (d) cobertura mínima; mesma semente, mesmo resultado | Caso feliz: os três de (a). Caso de erro: os três de (b). Caso-limite: `…one_block_for_the_whole_day…` (o menor ofício válido, uma linha de 0 a 24; a hora 24 é recusada) e `…order_of_the_agenda_lines_does_not_matter…`. Semente: `…same_seed_gives_the_same_day…` (duas rodadas com a semente 7 dão as mesmas ações e o mesmo hash do mundo; a semente 8 dá outro hash) |

## 2. ARQUIVOS CRIADOS
- `tests/unit/test_new_occupation_by_data.gd` — o teste: 280 linhas, **224 de código** (o que a DEC-126 conta; teto ~300).
- `tests/unit/test_new_occupation_by_data.gd.uid` — 1 linha, identificador gerado pelo Godot (`--import`), como nos outros testes; não conta no tamanho.

## 3. ARQUIVOS MODIFICADOS
- Nenhum. `src/`, `data/`, `tests/fixtures/`, `project.godot`, `AGENTS.md` e os documentos ficaram intactos (o commit tem 2 arquivos novos, 283 linhas).

## 4. DECISÕES TÉCNICAS
- **O ofício e a agenda nascem em memória**, copiando as tabelas reais e acrescentando linhas. Alternativa: gravar um arquivo temporário; recusei porque o teste não deve depender de pasta nem deixar resíduo, e o caminho em memória (`from_tables`) já existe para testar dado inválido.
- **A agenda nova usa só ações que já existem** (`sleep`, `eat`, `work`, `rest`, `talk`): assim também se prova que não foi preciso código nem para a ação.
- **A população entra pelo construtor** (`PopulationPlan.new`), trocando `setup.definitions.population` no teste, em vez de editar `population.json`, que a ordem proíbe tocar. O resto do `NpcSetup` é o real.
- **Valores [HIP] não foram fixados.** As horas esperadas (3, 6, 8, 21 e 22) vêm da agenda escrita à mão no teste. Nas outras horas o que o NPC faz depende de necessidades e pesos dos dados reais [HIP], que o teste de propósito não congela; elas só entram na conferência de "tem ação" e de determinismo (mesma semente, mesmo resultado).
- **Controle de mutação** (três quebras temporárias, em cópia, desfeitas): ver seção 5.
- **Proposta de entrada para `DECISIONS.md` / pedido de desvio:** nenhum.

## 5. TESTES EXECUTADOS
- `tools/run_tests res://tests/unit/test_new_occupation_by_data.gd` — **9/9, 427 asserts**.
- **Controles de mutação** (cada um aplicado numa cópia do teste, rodado com o mesmo comando e desfeito; o arquivo voltou **idêntico** ao commitado, `cmp` sem diferença e `git status` limpo; depois 9/9 de novo):

  | Quebra de propósito | Resultado |
  |---|---|
  | M1: a rotina do dia ignora o ofício novo (usa as tabelas reais) | 7/9 (2 falham) |
  | M2: a agenda nova ganha sobreposição (19–21 e 20–22) | 3/9 (6 falham) |
  | M3: a mensagem esperada cita um campo que não existe | 8/9 (1 falha) |
- `tools/check_all` **no arquivo final** (09:01:14 a 09:04:34): **VERDE** (`EXIT_CODE_CHECK_ALL=0`). A primeira rodada (08:57 a 09:00) também foi verde; depois dela só acrescentei dois comentários que justificam o uso de `Variant` (AGENTS 4.2) e **rodei tudo de novo**: vale a segunda.
- Conferência de hashes: comparei as linhas com hash do `check_all` desta tarefa com as do `check_all` da Fase B da LW-087a (a base): **as 15 linhas só diferem nos milissegundos de parede**; os hashes são os mesmos (oráculo de 8 marcos, vida sem jogador de 7 dias `dad2d10abf75`, soak de 300 NPCs `31322f97796b`).
- Buscas no arquivo novo: nenhum `print`, `TODO`, sorteio, `Time.get`/`OS.get`, `await`, `@warning_ignore` nem escrita em disco.
- Git: `git fetch` com refspec explícita (`main` em `63caee7`, já dentro do ramo); `git add` só dos 2 arquivos; `git diff --staged --stat`; um commit; `git push --dry-run` e depois `git push origin lw-093b-oficio-so-por-json`; conferido que o remoto ficou em `1dbf3a8`.
- **NÃO EXECUTADO:** teste manual (não há; é só teste automático).

## 6. RESULTADOS
- **`check_all`:** 125 scripts, **1.203 testes, 1.203 passando, 0 falhando**, 262.120 asserts, 169,0 s; 314 scripts sem aviso de compilação; 0 "SCRIPT ERROR" e 0 "Parse Error".
- **Contra a base (LW-087a Fase B: 124 / 1.194 / 261.693 / 313):** +1 script, +9 testes, +427 asserts, +1 script verificado. É exatamente o arquivo novo; nada mais mudou.
- **Aceite:** cumprido, e eu sei porque os três pontos estão cobertos pelos 9 testes (tabela acima), os controles de mutação mostram que os testes pegam a quebra, e o código de jogo **não precisou mudar**.

## 7. PROBLEMAS ENCONTRADOS
- **Nenhuma falha, nenhuma divergência entre documentos.** A hipótese da DEC-137 se confirmou: o ofício é só dado.
- O resumo do GUT mostra "Warnings 1 / Deprecated 1": é o aviso de `wait_frames` em `tests/unit/test_app_nodes.gd`, que não toquei; não é do teste novo (eu não comparei com o log da base).
- **Limitação:** a linha de população do ofício novo entra pelo construtor e **não** por um `population.json` em memória; por isso o `PopulationLoader` (esquema do arquivo) não é exercitado para o `tinker`. O que a população checa do ofício (que ele existe e que há casa e local de trabalho com vaga) **é** exercitado, nos dois sentidos.

## 8. RISCOS
- **Acoplamento deliberado com dados reais:** o teste usa o assentamento `test_settlement_a`, os locais com prefixo `a_home_` e `a_work_` (capacidade para 3 + 2 NPCs) e as ações do catálogo atual. A **LW-097** (mundo novo, `work_place_id`) e a **LW-093** mexem nisso; se mudarem esses ids ou capacidades, o teste falha com mensagem clara e deve ser ajustado **na tarefa dona da mudança** (não enfraquecer).
- **Alerta de acoplamento (AGENTS 5.2.4):** o teste usa `app`, `core`, `data`, `npc` e `world`; é normal num teste de ponta a ponta e não cria módulo nem dado novo.
- Não verifiquei nada além do que está na seção 5.

## 9. PENDÊNCIAS
- **A sua auditoria.** A Fase B (`main`) só depois de você digitar `APROVADO LW-093b`; até lá nada vai ao `main`.
- **Teste manual:** nenhum. Se quiser ver o teste rodar sozinho: `tools/run_tests res://tests/unit/test_new_occupation_by_data.gd` (esperado: 9/9).

## ACOMPANHAMENTO
- **Avanço:** a LW-093b é subtarefa e não entra na contagem das 30 tarefas da Fase 3 (DEC-137); as contagens do status só mudam na Fase B. É a primeira tarefa de **código** (aqui, só teste) depois do registro do pré-voo.
- **Próxima tarefa recomendada:** a sua auditoria; depois, se aprovada, a Fase B da LW-093b. Em seguida a sequência do roadmap (LW-087b a 087d, DOC). **Não iniciada.**
- **Decisões que dependem de você:** (1) o `APROVADO LW-093b` para a Fase B; (2) a distribuição 14/6/20/10 ainda sem entrada própria (a entrada nasce ao preparar a LW-097, como você aceitou).
- **Git:** **um** commit, `1dbf3a8` ("LW-093b: teste de que um ofício novo só por JSON funciona e é validado"), no ramo `lw-093b-oficio-so-por-json`, empurrado **só** esse ramo e o `status-a`; `main` em `63caee7` (sem mudança), sem tag, sem `--force`, nenhum Godot meu em execução.
