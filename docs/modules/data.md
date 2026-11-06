# Contrato — data

Estado: **LW-024, LW-025 e LW-034 (lista de inteiros) concluídas**. Existem leitor e validador genéricos; ainda não existe nenhum `*Def` de jogo nem arquivo real em `data/` (só dados de teste em `tests/fixtures/data/`).

- **Responsabilidade:** ler arquivos JSON de conteúdo, validá-los (tipos, campos obrigatórios, faixas, ids únicos, campos desconhecidos, referências entre tabelas) e entregar os registros convertidos.
- **Entradas:** pasta com arquivos JSON; lista de `DataSchema` (um por tabela, declarado em código).
- **Saídas:** `DataBundle` (`tables`, `issues`, `is_valid()`, `describe_issues()`, `to_result()`). Cada problema (`DataBundle.Issue`) traz arquivo, item (id do registro), campo e mensagem.
- **Dependências permitidas:** `core` (`Result`).
- **Dados controlados:** nenhum estado de simulação; só o conteúdo lido (somente leitura em jogo).
- **Interfaces de comunicação:** `DataLoader.load_all(base_dir, schemas)`. Nenhum evento.
- **Formato (proposta; DEC-082 aprovada somente quanto ao JSON validado):** cada arquivo é uma lista de objetos; cada objeto tem `id` (texto `snake_case`, único na tabela). Números do JSON são decimais e viram `int`/`float` conforme o esquema; inteiro só aceita número sem fração.
- **Ferramenta:** `tools/validate_data [pasta]` valida uma pasta (padrão: dados de teste do spike) e roda dentro do `check_all`. Esquemas de teste em `tests/fixtures/data/pipeline_schemas.gd`. **Duas pastas de teste:** `ok/` é a amostra editável (validada pelo `check_all`; pode receber qualquer edição legítima) e `frozen/` é a cópia congelada que os testes do carregador usam, para não quebrarem com edições em `ok/`.
- **Limitações:** erros de campo apontam arquivo e item, não linha (o JSON já lido não guarda linha); só erros de sintaxe trazem linha. Inteiros acima de 2^53 são rejeitados. Sem objetos aninhados nos campos; a única lista aceita é a de inteiros (abaixo).
- **Lista de inteiros (LW-034):** `DataSchema.FieldType.INT_LIST`. Cada elemento precisa ser inteiro (sem fração, até 2^53) e dentro da faixa de `set_range`, que vale para **cada elemento**; `set_max_length(n)` limita o tamanho (padrão `DataSchema.DEFAULT_MAX_LIST_LENGTH` = 4.194.304 **[HIP]**, proteção contra arquivo gigante). Lista vazia **é válida** aqui; quem exige tamanho (ex.: `world`) confere depois. Cada problema aponta arquivo, item, campo e a **posição** do elemento (a partir de 0); só os primeiros `DataValidator.MAX_ELEMENT_ISSUES` (10) são detalhados e o resto vira uma linha de resumo. Depois de validada, a lista vira `PackedInt64Array` no registro.
- **Testes:** `tests/unit/test_data_loader_validator.gd`, com fixtures em `tests/fixtures/data/{frozen,bad}`; `tests/unit/test_data_int_list.gd` (lista de inteiros).
