# Contrato — core

Estado: **parcial**. Só `Result` existe; o resto do núcleo entra nas LW-013 a LW-020.

- **Responsabilidade:** base sem dependências: resultado de comandos (agora); IDs, aleatoriedade, relógio, eventos e agendador (tarefas futuras).
- **Entradas:** nenhuma.
- **Saídas:** `Result` (`ok`, `code`, `message`), criado por `Result.success()` ou `Result.failure(code, message)`. Falha sem código recebe `UNSPECIFIED_ERROR`.
- **Dependências permitidas:** nenhuma (camada 0).
- **Dados controlados:** nenhum estado de simulação.
- **Interfaces de comunicação:** nenhum evento publicado ou ouvido.
- **Testes necessários:** `tests/unit/test_result.gd` (sucesso, falha, distinção entre os dois, falha sem código).
