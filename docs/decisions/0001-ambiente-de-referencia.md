# Ambiente de referência — LW-006

- Godot: 4.7.2.stable.official.ed1daf0bf, confirmado pelo executável instalado.
- Sistema: macOS Tahoe 26.6.2, confirmado por `sw_vers`.
- Computador: MacBook Air de 15 polegadas, 2024 e GPU integrada Apple M3, informados por Arthur. Chip Apple M3 e 16 GB de RAM confirmados pela imagem do Relatório do Sistema fornecida por Arthur.
- Núcleos de CPU: 8 (4 de desempenho e 4 de eficiência), confirmados pela imagem do Relatório do Sistema. A consulta `sysctl -n hw.ncpu` havia retornado `Operation not permitted` neste ambiente.
- Armazenamento: `df -h .` informou volume de 460 GiB e 356 GiB disponíveis na verificação. A capacidade nominal do dispositivo permanece pendente.
- Idioma: identificadores em inglês; comentários e documentação em português (DEC-022).
- `export_presets.cfg` fica fora do Git até a tarefa de exportação LW-188.

## Verificações da LW-006

**Situação: funcional com ressalvas**, conforme orientação de Arthur. Os testes da cena e do caso de erro passaram; os critérios de saída sem erros e a verificação visual completa continuam pendentes. Os erros do ambiente Codex permanecem para investigação, sem atribuição de causa ao projeto.

- Importação headless: código 0, mas com erros de acesso aos diretórios de dados e cache do Godot e aos certificados do sistema; não aprovada.
- Teste da cena: `SMOKE_TEST: PASS`, código 0; a saída também apresentou erros de acesso aos dados e certificados.
- Cena inexistente: `SMOKE_TEST: FAIL`, código 1, como esperado; os mesmos erros de ambiente apareceram.
- Execução headless por 60 quadros: código 0, porém com erros de acesso aos dados e certificados; não aprovada.
- Verificação visual no editor: Arthur confirmou que a cena 3D abriu e o cubo apareceu ao pressionar F5. A ausência de erros ou avisos no painel Saída não foi confirmada; piso, céu e iluminação não foram confirmados separadamente.
- Nova verificação após abertura por Arthur: importação, teste da cena e execução headless terminaram com código 0; o teste imprimiu `SMOKE_TEST: PASS`. O erro de criação de dados do projeto não reapareceu, mas persistiram o erro de certificados do sistema e, na importação, a falha ao salvar configurações do editor. Assim, o critério de saída sem erros ainda não foi atendido.
- Nova execução do caso de cena inexistente: `SMOKE_TEST: FAIL cena inexistente`, código 1, como esperado; o erro de certificados do sistema também apareceu no ambiente Codex. Os erros de certificados e de permissão foram observados no ambiente de execução do Codex; sua causa exata e o estado do painel Saída no editor não foram confirmados.

## Fechamento da LW-006 (02/11/2026)
Arthur fechou a LW-006 depois de: F5 no Mac mostrando piso, cubo, céu e sol; aba Erros do editor sem erros (após a correção de 27 avisos de GDScript que o `check_all` não enxergava); `check_all` verde no Mac (145 testes). As mensagens de certificados e de gravação de logs vistas no ambiente restrito do Codex são ruído de ambiente, tratado por `tools/filter_env_noise` com regras específicas e testes. Hardware medido nos spikes: MacBook Air M3 (Apple M3), Godot 4.7.2 estável.
