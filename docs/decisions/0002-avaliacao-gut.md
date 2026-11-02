# LW-010 — Avaliação do GUT 9.7.1

**Situação:** Arthur aceitou GUT 9.7.1 após a avaliação e a decisão está **registrada como DEC-086 (APROVADA)** em `docs/DECISIONS.md`.

- **Origem:** https://github.com/bitwes/Gut/tree/v9.7.1; distribuição instalada em `addons/gut/`.
- **Licença:** MIT, preservada em `addons/gut/LICENSE.md`.
- **Compatibilidade:** o mantenedor declara Godot 4.7.x; as verificações abaixo usaram Godot 4.7.2.stable e GUT 9.7.1.
- **Teste que passa:** `godot --headless --path . -s res://addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_lw010_pass.gd -gexit`: 1/1 teste, código 0.
- **Falha intencional:** mesmo comando com `-gtest=res://tests/fixtures/lw010_fail.gd`: 0/1, mensagem `[Failed]`, código 1. A fixture não está na pasta normal de testes unitários.
- **Cena existente:** `godot --headless --path . --script res://tools/smoke_test.gd`: `SMOKE_TEST: PASS`, código 0.
- **Limitações:** as execuções exibiram o erro de certificados do ambiente Codex já registrado. A importação também não conseguiu gravar configurações do editor fora do projeto. Nenhuma dessas mensagens foi atribuída ao GUT sem evidência. Os comandos reais usaram o executável instalado em `/Applications/Godot 2.app/Contents/MacOS/Godot` e `--log-file` em `/private/tmp`.
- **Escolha de Arthur:** adotar GUT 9.7.1 para testes GDScript. Não foi implementado executor próprio; gdUnit4 e executor mínimo não foram testados nesta avaliação por instrução de Arthur. O plugin visual não foi habilitado em `project.godot`; a execução usou a linha de comando.
