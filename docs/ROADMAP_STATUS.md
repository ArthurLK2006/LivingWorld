# Status do roadmap — Living World

Atualizado em: 02/11/2026 · Fase atual: 0 — Fundação técnica (em fechamento).

Fase 0: **28 de 31 tarefas concluídas ou dispensadas** (26 concluídas, 2 dispensadas); faltam LW-029 (revisão externa), LW-030 (validação de Arthur) e LW-031 (fechamento). O percentual oficial da fase só passa a 100% depois dessas três.

## Critérios de cálculo

- Avanço da fase: tarefas concluídas ou dispensadas dividido pelo número aplicável de tarefas da fase.
- Avanço total: tarefas concluídas ou dispensadas dividido pelo total aplicável do roadmap. As tarefas condicionais só entram se adotadas; dispensas devem ser registradas.
- Estados: pendente, em andamento, em auditoria, concluída, dispensada e bloqueada.

## Pendências e ressalvas

- LW-006: **fechada por Arthur em 02/11/2026**. Evidências: F5 no Mac mostrou piso, cubo, céu e sol; a aba Erros do editor ficou sem erros depois da correção dos 27 avisos do GDScript; o `check_all` está verde no Mac (145 testes). As mensagens de certificados e de gravação de logs do ambiente restrito do Codex são ruído de ambiente tratado por `tools/filter_env_noise`.
- LW-008: aprovada por Arthur com ressalvas; o mapeamento individual detalhado das regras da arquitetura não foi comprovado. Limite de leitura do Codex ainda não verificado em fonte oficial.
- Dados: `tests/fixtures/data/ok/` é a amostra editável (validada pelo check_all); `frozen/` é a cópia fixa dos testes do carregador.
- Ambiente de trabalho do Claude (nuvem): Godot 4.7.2 Linux instalado fora do projeto; `check_all` verde sem os erros de certificado do ambiente Codex.
- Trabalho local do Mac preservado por Arthur no ramo `mac-snapshot`, **que já está neste mesmo repositório do GitHub** (um commit, `f1a9192`, em cima da LW-012). Ele fica **fora da revisão da LW-029**: foi só lido e comparado (`docs/fase-0/mac-snapshot-comparacao.md`), nada foi tocado nem juntado ao ramo de trabalho. A decisão sobre aproveitá-lo é de Arthur, depois do fechamento da Fase 0.
- LW-023: **fechada sem ressalva em 02/11/2026.** Critério de pico de 10 ms **CONFIRMADO em build de release** no Mac de referência pela régua da DEC-113 (3 execuções, 0 passos > 10 ms em 1,95 min medido, máximo 2,857 ms, hash igual). Condições da medição: carregador ligado, Godot fechado, sem uso. Em depuração houve picos (informativo). Redação incorporada à arquitetura (20.1 e 26.3) e ao item da LW-023 do roadmap.
- LW-021 (F5 no Mac, 02/11/2026): a janela abriu com piso, cubo, céu e sol e o texto "Living World · versão 0.0.1-dev / Data simulada: ano 1, dia 1, 00:13 · 1x / [Espaço] pausar ou continuar"; **a data avança: sim; o Espaço pausa: sim; o Espaço de novo continua: sim.** Parte visual da LW-021 fechada por Arthur.
- `check_all` no Mac (commit `0eb1bdf`): VERDE, 145 testes (19 scripts, 3.218 asserts).
- Avisos do GDScript: em 02/11/2026 o editor mostrou 5 avisos de divisão inteira em `sim_clock.gd`. O `check_all` não os via porque o Godot só imprime avisos de compilação com o depurador ligado. Varredura completa achou 27 no total (divisão inteira, nomes que repetem funções do Godot, ternário incompatível, variável sem uso, sombreamentos); todos corrigidos sem `@warning_ignore` e o `check_all` ganhou `tools/check_gdscript_warnings`. Relatórios anteriores que diziam "sem avisos de GDScript" estavam errados.
- DEC-086: GUT 9.7.1 aprovado por Arthur e registrado na entrada oficial.
- Ambiente restrito: o `check_all` ignora, com aviso (`NOTA: N mensagem(ns) de ambiente ignorada(s)`), um conjunto **fechado** de mensagens do motor: não conseguir criar o diretório de dados, não conseguir gravar o arquivo de log em `user://logs` e a falha de leitura dos certificados do sistema do macOS (`tools/filter_env_noise`). Cada regra é específica (a mensagem de certificados só vale com a linha de origem `get_system_ca_certificates` logo depois; a de log, com a origem `dir_access.cpp`) e nada que cite `res://` é ignorado; qualquer outro erro continua sendo falha. As mensagens exatas foram conferidas por Arthur contra a saída real do Codex; o caso de diretório/logs sem permissão também foi reproduzido neste ambiente de nuvem. O filtro é provado pelo teste `tests/test_filter_env_noise.sh`, que roda dentro do `check_all`.
- Ambiente Codex: nos testes feitos dentro do Codex aparecem mensagens do próprio motor do Godot sobre certificados do sistema e sobre a criação de `user://logs`, e a importação relatou restrição ao gravar configurações do editor. São mensagens sobre o ambiente, não sobre o nosso código, e no Terminal do Mac o `check_all` fica verde (145 testes). A causa exata dentro do Codex (provavelmente permissões do ambiente dele) **não foi investigada**; não afeta o projeto, porque o filtro acima ignora só essas mensagens e nada mais.

## Tarefas da Fase 0

| ID | Tipo | Tarefa | Estado | Observações |
|---|---|---|---|---|
| LW-001 | DOC | Decisões iniciais | concluída | Conforme DECISIONS v0.3 |
| LW-002 | USER | Instalar Godot | concluída | 4.7.2 estável verificada |
| LW-003 | USER | Organizar documentos | concluída | Pacote publicado |
| LW-004 | USER | Preparar Codex | dispensada | Absorvida pela LW-006 |
| LW-005 | IMPL | Instalação automatizada | dispensada | Instalação realizada por Arthur |
| LW-006 | IMPL | Projeto e cena estática | concluída | Fechada por Arthur em 02/11/2026: F5 com piso, cubo, céu e sol; aba Erros sem erros após corrigir os 27 avisos; `check_all` verde no Mac |
| LW-007 | IMPL | Estrutura de pastas | concluída | Aprovada por Arthur |
| LW-008 | DOC | Validar AGENTS.md | concluída | Aprovada com ressalvas por Arthur |
| LW-009 | DOC | Modelos e acompanhamento | concluída | Aprovada por Arthur |
| LW-010 | SPIKE | Framework de testes | concluída | GUT 9.7.1 aceito por Arthur; ver decisions/0002-avaliacao-gut.md |
| LW-011 | IMPL | Executor e check_all | concluída | Aprovada por Arthur com ressalvas; avisos do ambiente persistem |
| LW-012 | IMPL | Verificação de arquitetura | concluída | Aprovada por Arthur com ressalvas; integrada ao check_all |
| LW-013 | IMPL | IDs | concluída | Aprovada por Arthur; 29 testes verdes no check_all |
| LW-014 | IMPL | Gerador aleatório | concluída | Aprovada por Arthur; 43 testes verdes no check_all; valores de referência do Godot 4.7.2 em teste |
| LW-015 | IMPL | Relógio | concluída | Aprovada por Arthur; 55 testes verdes; valores [HIP] mantidos: 360 dias por ano e 1 dia de jogo ≈ 30 min reais |
| LW-016 | IMPL | Barramento de eventos | concluída | Aprovada por Arthur; 69 testes verdes; check_architecture agora confere eventos contra docs/events.md (regra 8) |
| LW-017 | IMPL | Result e contratos base | concluída | Aprovada por Arthur; `Result`, `SimModule` e `SimContext`; 75 testes verdes. Desvio (b) aprovado: `tick(elapsed_minutes: int)` e `on_load(data) -> Result`, aplicado na LW-018 |
| LW-018 | IMPL | Mundo | concluída | Aprovada pela regra de aceleração de Arthur (check_all verde, 85 testes; único arquivo protegido alterado: arquitetura 4.6, autorizado). Desvio (b) aplicado |
| LW-019 | IMPL | Agendador | concluída | Aprovada pela regra de aceleração (check_all verde, 95 testes). Orçamento em unidades de trabalho declaradas, não em ms (determinismo, DEC-081); ms só medem |
| LW-020 | IMPL | SimulationHost | concluída | Autoload registrado com autorização de Arthur; `tools/run_sim` no check_all (115 testes) |
| LW-021 | IMPL | Cena inicial com relógio | concluída | Autoloads e `scenes/main.tscn` alterados com autorização de Arthur; regra 5 do check_architecture ativa. Parte visual fechada por Arthur em 02/11/2026 (data avança; Espaço pausa e continua) |
| LW-022 | IMPL | Hash de estado | concluída | Aprovada pela regra de aceleração (check_all verde, 107 testes). 3 execuções de 30 dias dão o mesmo hash |
| LW-023 | SPIKE | Núcleo da simulação | concluída | **Pico de 10 ms CONFIRMADO em release** no Mac (régua DEC-113, 3 execuções, 0 passos > 10 ms em 1,95 min, máximo 2,857 ms, média 0,075 ms, hash igual). Detalhes e linhas brutas em decisions/0004 e docs/fase-0/evidencias |
| LW-024 | IMPL | Leitor e validador de dados | concluída | Aprovada por Arthur; 21 testes verdes no check_all |
| LW-025 | SPIKE | Pipeline de dados | concluída | Aprovada por Arthur; JSON mantido (decisions/0003, DEC-082 aprovada). Teste do Codex no Mac (01/11/2026): editou os dados, o validador aceitou o bom e recusou o ruim com arquivo, item e campo; o check_all ficou vermelho por um teste que contava itens, corrigido com pasta congelada `tests/fixtures/data/frozen/` |
| LW-026 | IMPL | Codec de save | concluída | Regra automática de Arthur (check_all verde, 128 testes). Formato v2, migração 1->2 com fixture, salvar/carregar no meio não muda o hash |
| LW-027 | IMPL | Escrita e recuperação de save | concluída | Regra automática de Arthur (check_all verde). Falha injetada depois de cada passo nunca perde o save anterior; backups rotativos; recuperação ao carregar |
| LW-028 | SPIKE | Salvamento | concluída | Regra automática de Arthur. 1.000 NPCs: salvar 2,3 ms, carregar 0,9 ms, hash idêntico, falha simulada preserva o save (ver decisions/0005). Plano B (thread) não necessário agora |
| LW-029 | REV | Revisão arquitetural | pendente | Pacote para o revisor externo pronto em `docs/fase-0/LW-029-pacote-de-revisao.md` (aguarda envio por Arthur) |
| LW-030 | VAL | Validação do usuário | pendente | Resumo dos passos em `docs/fase-0/LW-030-resumo-para-arthur.md`; depende da LW-029 |
| LW-031 | DOC | Fechamento da fase | pendente | Rascunho do relatório em `docs/fase-0/LW-031-rascunho-relatorio-de-fechamento.md`; depende da LW-030 |

## Portões

| Portão | Estado |
|---|---|
| REV Fase 0 — LW-029 | pendente |
| VAL Fase 0 — LW-030 | pendente |
| Tag fase-0-concluida | pendente |

## Escopo do protótipo

Itens dentro e fora serão registrados na LW-146.
