# Contrato — core

Estado: **parcial**. Existem `Result` e `IdGenerator`; o resto do núcleo entra nas LW-014 a LW-020.

- **Responsabilidade:** base sem dependências: resultado de comandos (agora); IDs, aleatoriedade, relógio, eventos e agendador (tarefas futuras).
- **Entradas:** nenhuma.
- **Saídas:** `Result` (`ok`, `code`, `message`), criado por `Result.success()` ou `Result.failure(code, message)`. Falha sem código recebe `UNSPECIFIED_ERROR`.
- **Dependências permitidas:** nenhuma (camada 0).
- **IDs (`IdGenerator`, LW-013):** `next_id()` entrega inteiros crescentes a partir de 1, nunca reutilizados; `NO_ID` (0) significa "sem ID" e também é devolvido, com erro registrado, se o limite 2^53-1 acabar. `serialize()` -> `{"next_id": n}`; `on_load(data)` devolve `Result` e só altera o estado se o dado for válido (aceita inteiro ou decimal sem fração, como vem do JSON); `validate()`; `debug_summary()`.
- **Dados controlados:** o contador de IDs (`next_id`).
- **Interfaces de comunicação:** nenhum evento publicado ou ouvido.
- **Testes necessários:** `tests/unit/test_result.gd` (sucesso, falha, distinção entre os dois, falha sem código); `tests/unit/test_id_generator.gd` (crescente e único, ID descartado não volta, salvar/restaurar e ida e volta por JSON continuam a sequência, dado inválido rejeitado sem alterar estado, esgotamento).
