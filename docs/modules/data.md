# Contrato — data

Estado: **parcial (LW-024)**. Existe leitor e validador genéricos; não existe nenhum `*Def` de jogo nem arquivo real em `data/` ainda.

- **Responsabilidade:** ler arquivos JSON de conteúdo, validá-los (tipos, campos obrigatórios, faixas, ids únicos, campos desconhecidos, referências entre tabelas) e entregar os registros convertidos.
- **Entradas:** pasta com arquivos JSON; lista de `DataSchema` (um por tabela, declarado em código).
- **Saídas:** `DataBundle` (`tables`, `issues`, `is_valid()`, `describe_issues()`, `to_result()`). Cada problema (`DataBundle.Issue`) traz arquivo, item (id do registro), campo e mensagem.
- **Dependências permitidas:** `core` (`Result`).
- **Dados controlados:** nenhum estado de simulação; só o conteúdo lido (somente leitura em jogo).
- **Interfaces de comunicação:** `DataLoader.load_all(base_dir, schemas)`. Nenhum evento.
- **Formato (proposta, DEC-082 ainda PROPOSTA):** cada arquivo é uma lista de objetos; cada objeto tem `id` (texto `snake_case`, único na tabela). Números do JSON são decimais e viram `int`/`float` conforme o esquema; inteiro só aceita número sem fração.
- **Limitações:** erros de campo apontam arquivo e item, não linha (o JSON já lido não guarda linha); só erros de sintaxe trazem linha. Inteiros acima de 2^53 são rejeitados. Sem listas nem objetos aninhados nos campos por enquanto.
- **Testes:** `tests/unit/test_data_loader_validator.gd`, com fixtures em `tests/fixtures/data/{ok,bad}`.
