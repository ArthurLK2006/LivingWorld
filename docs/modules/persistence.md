# Contrato — persistence

Estado: **parcial (LW-026)**. Existe o codec; escrita em disco, backups e recuperação entram na LW-027.

- **Responsabilidade:** transformar o estado do jogo em bytes e de volta, com versão, checksum e migrações; gravar e ler com segurança (LW-027).
- **Entradas:** `payload` (dados simples: `{world, scheduler}` montado por `SimulationRunner.capture_game()`) e a versão do jogo.
- **Saídas:** bytes do save; `DecodedSave` (`result`, `save_version`, `game_version`, `payload` já migrado).
- **Dependências permitidas:** `core`.
- **Formato (proposta, DEC-084 segue PROPOSTA):** arquivo gzip. Dentro: uma linha de cabeçalho em JSON (`format` = `lwsave`, `save_version`, `game_version`, `checksum` = SHA-256 dos bytes do payload, `payload_bytes`), uma quebra de linha e o payload em JSON canônico (chaves ordenadas, decimais com precisão total). Versão atual do formato: **2**.
- **Versões:** v1 = payload era o estado do `World` direto; v2 = `{world, scheduler}`. `SaveMigrations` encadeia N para N+1 (migração 1->2 real, com fixture `tests/fixtures/saves/save_v1.lwsave`, gerada pelo próprio código por `generate_save_v1.gd`). Save de versão mais nova é recusado (`SAVE_VERSION_NEWER`); sem passo de migração, `SAVE_NO_MIGRATION`.
- **Erros (códigos):** `SAVE_NOT_GZIP`, `SAVE_CORRUPT`, `SAVE_WRONG_FORMAT`, `SAVE_CHECKSUM_MISMATCH`, `SAVE_VERSION_NEWER`, `SAVE_NO_MIGRATION`, `SAVE_INVALID_PAYLOAD`.
- **Segurança:** só lê JSON (dados simples); nunca carrega `.tres`, `.res`, `.gd` nem objetos; teto de 256 MiB descomprimidos (`MAX_UNCOMPRESSED_BYTES`) contra arquivo que explode ao descomprimir (o teto existe no código mas não tem teste, por exigir um arquivo enorme).
- **Carregar:** `SimulationRunner.load_game(payload, configura_agendador)` num runner novo, sem `on_new_game`; o mundo antigo só deve ser descartado depois do sucesso. Salvar só entre passos, com a fila de eventos vazia (`can_capture_game()`).
- **Limitação:** `decompress_dynamic` do Godot registra um erro de motor ao receber gzip truncado; o codec o converte em `SAVE_CORRUPT` (o teste confere com `assert_engine_error_count`).
- **Testes:** `tests/unit/test_save_codec.gd` (ida e volta preserva o hash e o agendador; salvar e carregar no meio não muda o hash final; adulteração; lixo, vazio, `.tres`, truncado; versões; fixture v1 migrada com hash esperado; erros de migração; texto que parece recurso fica texto; payload incompleto; fila pendente).
