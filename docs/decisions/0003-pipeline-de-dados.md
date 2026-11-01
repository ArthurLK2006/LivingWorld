# Registro técnico — Pipeline de dados JSON (spike SP3, parte 2)

- **Status:** aprovado por Arthur em 01/11/2026 (DEC-082 aprovada somente quanto ao JSON validado).
- **Data e tarefa:** 01/11/2026, LW-025.
- **Contexto e problema:** a arquitetura (cap. 16.2) recomenda definições em JSON validado, com plano B em `.tres` + validadores. O spike precisava mostrar se esse fluxo é confortável: editar dados, errar, ver o erro e consertar.
- **Opções consideradas:** (1) JSON + `DataLoader`/`DataValidator` (LW-024); (2) `.tres` com scripts de validação (plano B).
- **Escolha ou recomendação:** manter JSON (opção 1). O plano B não foi necessário.
- **Evidência (executada):** três tabelas de teste com referências cruzadas em `tests/fixtures/data/ok` (bens, receitas, ofertas; ofertas citam bens e, opcionalmente, receitas). `tools/validate_data` está dentro do `check_all`. Ciclo medido:
  - quebrar o dado (oferta com `good: "test_good_zz"`): `check_all` ficou VERMELHO com `.../offers.json | item 'test_offer_b' | campo 'good' | referência a id inexistente 'test_good_zz' na tabela 'goods'`;
  - consertar: `check_all` voltou a VERDE (21 testes);
  - `tests/test_validate_data.sh` repete o ciclo automaticamente (referência quebrada, valor fora da faixa, conserto, e edição válida com bem e oferta novos sem quebrar o restante).
- **Teste com o Codex (relatado por Arthur, 01/11/2026):** o Codex editou os dados; o validador aceitou dado bom e recusou dado ruim com mensagem clara (arquivo, item e campo). O `check_all` ficou vermelho depois de uma edição legítima porque um teste do carregador esperava exatamente 2 bens na pasta editável. Correção: os testes do carregador passaram a ler a cópia congelada `tests/fixtures/data/frozen/`, e a pasta `ok/` pode receber qualquer edição válida (confirmado trocando todo o conteúdo dela).
- **Consequências e riscos:** erros de campo apontam arquivo, item e campo, não linha (só erros de sintaxe do JSON trazem linha). Os esquemas ficam em código GDScript; `PipelineSchemas` é só de teste. Dados reais em `data/` e os `*Def` ainda não existem.
- **Relação com DEC-082.**
