# Pasta congelada

Cópia fixa dos dados de teste originais (3 tabelas, 2 registros cada). Os testes do carregador, do validador e do pipeline leem **esta** pasta, para não quebrarem quando alguém editar a pasta `ok/`.

- **Não edite** estes arquivos. Para exercitar edição de dados, use `tests/fixtures/data/ok/`: o `tools/check_all` valida essa pasta e deve continuar verde com qualquer edição legítima.
- Mudar esta pasta só se o próprio comportamento do carregador mudar, junto com os testes.
