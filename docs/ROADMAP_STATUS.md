# Status do roadmap — Living World

Atualizado em: 01/11/2026 · Fase atual: 0 — Fundação técnica.

O percentual definitivo depende da classificação da LW-006 e da validação da LW-009. Para evitar contar tarefas com ressalvas como plenamente concluídas, este registro não apresenta porcentagem consolidada ainda.

## Critérios de cálculo

- Avanço da fase: tarefas concluídas ou dispensadas dividido pelo número aplicável de tarefas da fase.
- Avanço total: tarefas concluídas ou dispensadas dividido pelo total aplicável do roadmap. As tarefas condicionais só entram se adotadas; dispensas devem ser registradas.
- Estados: pendente, em andamento, em auditoria, concluída, dispensada e bloqueada.

## Pendências e ressalvas

- LW-006: funcional com ressalvas por orientação de Arthur. Saída sem erros na importação e execução, painel Saída, e confirmação visual separada de piso, céu e luz ainda não comprovados. Erros de certificados e permissões ocorreram no ambiente Codex; causa não atribuída ao projeto.
- LW-008: aprovada por Arthur com ressalvas; o mapeamento individual detalhado das regras da arquitetura não foi comprovado. Limite de leitura do Codex ainda não verificado em fonte oficial.
- Dados: confirmação de que o Codex consegue editar os dados sem quebrar o resto (parte da LW-025) pendente; usar `tools/validate_data` e `tools/check_all`.
- Ambiente de trabalho do Claude (nuvem): Godot 4.7.2 Linux instalado fora do projeto; `check_all` verde sem os erros de certificado do ambiente Codex.
- LW-023: rodar `tests/soak/run_sp1` no Mac de referência para confirmar que nenhum passo passa de ~10 ms (pendente antes do fim da Fase 0).
- LW-021: conferência visual no Mac: abrir o projeto, F5, ver o texto no canto superior esquerdo, a hora simulada avançar e o Espaço pausar e continuar.
- DEC-086: GUT 9.7.1 aprovado por Arthur e registrado na entrada oficial.
- Ambiente Codex: erros de certificados e de criação de `user://logs` persistem durante os testes; a importação também relatou restrição ao gravar configurações do editor. Causa não atribuída ao projeto; investigar separadamente.

## Tarefas da Fase 0

| ID | Tipo | Tarefa | Estado | Observações |
|---|---|---|---|---|
| LW-001 | DOC | Decisões iniciais | concluída | Conforme DECISIONS v0.3 |
| LW-002 | USER | Instalar Godot | concluída | 4.7.2 estável verificada |
| LW-003 | USER | Organizar documentos | concluída | Pacote publicado |
| LW-004 | USER | Preparar Codex | dispensada | Absorvida pela LW-006 |
| LW-005 | IMPL | Instalação automatizada | dispensada | Instalação realizada por Arthur |
| LW-006 | IMPL | Projeto e cena estática | em auditoria | Funcional com ressalvas; ver acima |
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
| LW-021 | IMPL | Cena inicial com relógio | concluída | Autoloads e `scenes/main.tscn` alterados com autorização de Arthur; regra 5 do check_architecture ativa. Conferência visual na janela pendente (ver abaixo) |
| LW-022 | IMPL | Hash de estado | concluída | Aprovada pela regra de aceleração (check_all verde, 107 testes). 3 execuções de 30 dias dão o mesmo hash |
| LW-023 | SPIKE | Núcleo da simulação | concluída com ressalva | Pico de 10 ms não confirmado; teste no Mac pendente antes do fim da Fase 0. Média 0,14 ms/passo e hash determinístico atingidos (ver decisions/0004) |
| LW-024 | IMPL | Leitor e validador de dados | concluída | Aprovada por Arthur; 21 testes verdes no check_all |
| LW-025 | SPIKE | Pipeline de dados | concluída | Aprovada por Arthur; JSON mantido (decisions/0003, DEC-082 aprovada). Edição pelo Codex ainda não testada |
| LW-026 | IMPL | Codec de save | pendente | |
| LW-027 | IMPL | Escrita e recuperação de save | pendente | |
| LW-028 | SPIKE | Salvamento | pendente | |
| LW-029 | REV | Revisão arquitetural | pendente | |
| LW-030 | VAL | Validação do usuário | pendente | |
| LW-031 | DOC | Fechamento da fase | pendente | |

## Portões

| Portão | Estado |
|---|---|
| REV Fase 0 — LW-029 | pendente |
| VAL Fase 0 — LW-030 | pendente |
| Tag fase-0-concluida | pendente |

## Escopo do protótipo

Itens dentro e fora serão registrados na LW-146.
