# Relatório de fechamento da Fase 0 (LW-031)

Preparado em **03/11/2026** (horário de Brasília), a partir do rascunho `docs/fase-0/LW-031-rascunho-relatorio-de-fechamento.md`, que foi mantido como está. Todo fato abaixo vem de uma execução registrada, de um documento do repositório ou de informação dada por Arthur, e a origem aparece no texto. Rótulos usados: **fato**, **decisão**, **proposta**, **hipótese**, **pendente**, **limitação**.

```
RELATÓRIO — LW-031: Fechamento da Fase 0        Status: PRONTA PARA REVISÃO
```

## 1. RESUMO
A Fase 0 entregou a base técnica do jogo: um motor de simulação que roda sem janela (relógio, sorteios repetíveis, eventos, agendador e mundo), leitura e conferência de dados, salvamento com proteção contra falhas, uma cena inicial com a hora simulada e uma verificação única (`tools/check_all`) que roda tudo. Três spikes (núcleo, dados e salvamento) foram medidos e registrados em `docs/decisions/`.

**Placar da fase em 03/11/2026:** **31 de 31 tarefas concluídas ou dispensadas** (29 concluídas e 2 dispensadas, LW-004 e LW-005), ou seja, 100% da fase. **Avanço total do projeto: 31 de 192 tarefas (16,1%)**; as 192 vêm de 31 + 23 + 32 + 30 + 29 + 47, as seis fases do roadmap.

- **LW-029 (revisão arquitetural):** parecer em `docs/fase-0/LW-029-parecer.md`. Veredito **APROVADO COM AJUSTES**, 0 achados críticos, 6 importantes e 13 menores. Arthur aceitou a revisão em 03/11/2026.
- **LW-029A (tarefa extra, fora das 31):** corrigiu os achados I1, I2, I3 e I6 (commit `4efa0a6`). Não muda a contagem de 31 tarefas.
- **LW-029B (reparos M1, M3 e M7):** **não foi feita**; virou dívida no `docs/backlog.md`.
- **LW-030 (validação):** assinada por Arthur em 03/11/2026 **com duas ressalvas** (seção 7).
- **Tag `fase-0-concluida`:** **não foi criada** (a criação depende da autorização de Arthur). Pela definição do roadmap (0.J), a fase só é dada como concluída quando a tag estiver no remoto; por isso o `ROADMAP_STATUS.md` mostra 100% das tarefas e deixa a tag como pendente.

## 2. ARQUIVOS CRIADOS / 3. ARQUIVOS MODIFICADOS (desta tarefa)
- **Criados:** `docs/fase-0/LW-031-relatorio-de-fechamento.md` (este arquivo) e `docs/fase-0/LW-029-parecer.md`.
- **Modificados:** `docs/ROADMAP_STATUS.md`; `README.md`, **a seção 5 e a linha 9** (a linha "Estado atual" da tabela do topo, com autorização de Arthur em 03/11/2026); `docs/backlog.md` (apenas linhas acrescentadas).
- **Mantidos sem alteração:** o rascunho (`LW-031-rascunho-relatorio-de-fechamento.md`), `docs/DEVELOPMENT_ROADMAP.md` e os demais arquivos protegidos. Nenhum código foi tocado.
- **Parecer:** `docs/fase-0/LW-029-parecer.md` é o parecer integral da LW-029, uma **transcrição feita por Arthur** do relatório do revisor, como diz o cabeçalho do próprio arquivo. O texto foi enviado por Arthur no chat em 03/11/2026 e gravado sem alterar o conteúdo (igualdade byte a byte não foi exigida). Os IDs I1 a I6 e M1 a M13 citados neste relatório, no `ROADMAP_STATUS.md` e no `docs/backlog.md` foram conferidos com esse texto.

## 4. DECISÕES TÉCNICAS e retrospectiva
**4.1 Decisões da fase (todas já registradas):** GUT 9.7.1 (DEC-086); JSON validado para as definições (DEC-082, aprovada); JSON comprimido com escrita `.tmp` → conferência → backups → final como formato de save do protótipo (DEC-084, aprovada, com reavaliação do binário se o estado real passar de ~1 MB); desvio do ciclo de vida de módulos aprovado (`tick` em minutos inteiros e `on_load` devolvendo `Result`); régua de pico do SP1 (DEC-113, aprovada como régua de medição). **Decisões de Arthur em 03/11/2026, durante a LW-029A:** a regra "sem Node" continua sem cobrir `src/app` (opção A); a opção C fica no backlog como candidata a critério da LW-036; o teste que prova que a visita pela ordem natural do `Dictionary` é detectada (`assert_ne`) foi aceito no lugar de um teste vermelho; o tamanho da LW-029A (446 linhas em 7 arquivos) foi aceito. **DEC-089** está aprovada somente quanto ao serviço (GitHub); a visibilidade do repositório segue pendente.

**4.2 Retrospectiva curta (o que atrasou, em fatos):**
- Ambientes: o Godot não existia no ambiente de nuvem e o do Codex tem erros de certificado e de gravação de logs. Resposta: instalação autorizada e `tools/filter_env_noise`, que ignora só esse ruído, com aviso.
- Arquivos protegidos: o registro dos autoloads e a cena inicial exigiram parar e pedir autorização (LW-020/021).
- Testes frágeis: testes que contavam itens da pasta editável quebraram com uma edição legítima do Codex; corrigido com a pasta congelada `tests/fixtures/data/frozen/`.
- Medição em ambiente compartilhado: o pico de 10 ms do SP1 oscilou entre execuções idênticas na nuvem e em depuração no Mac. A régua da DEC-113 (release decide, por taxa e com laço de controle) resolveu: **confirmado em release no Mac** (seção 6, critério 3).
- **Erro meu nos relatórios (achado em 02/11/2026):** os relatórios de várias tarefas diziam "sem avisos de GDScript". Estava errado: o Godot só imprime avisos de compilação com o depurador ligado, e minhas execuções sem janela não os mostravam. O editor de Arthur mostrou 5 (divisão inteira em `sim_clock.gd`); a varredura completa achou 27. Todos corrigidos sem `@warning_ignore`; a divisão inteira, que é intencional (minutos inteiros), virou `IntMath.floor_div`; o `check_all` agora falha se houver qualquer aviso (`tools/check_gdscript_warnings`, com teste). O hash do mundo não mudou.
- Defeito achado por teste: o `World.teardown()` chamava módulos que nunca passaram por `setup()`. Corrigido.
- **Verificação que parecia olhar e não olhava (achado da LW-029):** o mesmo tipo de lacuna dos avisos do GDScript apareceu no `check_architecture`: as regras de tempo do sistema e de estado estático varriam só `src/sim`, que tinha apenas README; o padrão de aleatoriedade deixava passar `randi_range`, `randf_range`, `randfn`, `rand_from_seed`, `.shuffle()` e `.pick_random()`; e nenhum teste pegaria a ordem de um `Dictionary` mudando depois de carregar um save. A LW-029A corrigiu essas lacunas.
- **O que a revisão externa achou (LW-029).** Veredito APROVADO COM AJUSTES, 0 críticos. Resumo dos achados (o texto completo está no parecer):

| ID | Assunto (resumo) | Destino |
|---|---|---|
| I1 | Ordem de `Dictionary` depois de carregar não tinha teste que a pegasse | **Corrigido** na LW-029A (módulo-canário) |
| I2 | Furos no `check_architecture` (aleatoriedade, tempo e estático, pastas) | **Corrigido** na LW-029A (oito verificações) |
| I3 | Cadeia salvar → disco → carregar só era testada no código descartável do spike | **Corrigido** na LW-029A (teste em `tests/integration/`) |
| I4 | Conclusão "plano B de thread desnecessário" valia só para o estado de teste | Critério de aceite da tarefa dona: escrita do save em outra thread antes do módulo de memória dos NPCs e métrica de tamanho do `serialize()` por módulo no resumo de depuração (backlog, linha "Achados I4 e I5") |
| I5 | Padrão de onda do SP1 e desenho de NPC T1 não sustentado | Critério de aceite da tarefa dona: fase própria e fixa por NPC e teto determinístico de pensamentos por passo, com teste de 1 ano (backlog, linha "Achados I4 e I5") |
| I6 | Relógio e barramento acessíveis a qualquer módulo, só por convenção | **Corrigido** na LW-029A pela regra do `check_architecture`; a restrição por tipo (fachada só de leitura) não foi feita |
| M1, M3, M7 | Retorno do `rename` ignorado; agendador não conferido contra o relógio; `capture_game()` sem guarda | LW-029B, **não feita** (backlog, linha "LW-029B") |
| M9, M13 | Textos e comentários desatualizados; redação da régua DEC-113 | DOC pendente (backlog, linha "DOC pendente") |
| M11 | Apresentação dentro de `src/app` (texto de tela, tecla Espaço, `format_clock_line`, pausa escrevendo direto no relógio) | Sai na LW-036 (backlog, linha "Achados menores") |
| M2, M4, M5, M6, M8, M10, M12 | Lacunas de teste do `SaveStore`; hash do estado sem o agendador; `randi_range` com limites de 64 bits (não verificado); dados (2^53 contra 2^53−1, tabelas ou arquivos repetidos, `FLOAT`); ciclo de eventos que trava o salvamento; divergências entre arquitetura e código (orçamento de ms × teto de 60 passos, `app` fora da tabela de camadas, `World.tick()`); varredura de avisos sem comparar o total de scripts com os `.gd` existentes e `run_tests` sem piso de testes | Backlog, linha "Achados menores" |

- **O que a LW-029A entregou (executado em 03/11/2026):** `tools/check_architecture` com 8 verificações; `tests/test_check_architecture.sh` com 27 violações detectadas e 17 casos aceitos, também provados contra 6 mutações da ferramenta; módulo-canário com 5 testes; teste de ponta a ponta com 4 testes; um parágrafo em `docs/modules/MODELO.md`. O ramo `lw-029a-correcoes-revisao` foi publicado com autorização de Arthur.

**4.3 O que mudar nos modelos do roadmap e nos textos protegidos (PROPOSTAS minhas, para Arthur decidir; nada disto foi aplicado):**
1. No modelo de prompt do Codex (Anexo A), acrescentar: "testes não podem depender de pasta editável nem contar itens dela; use uma cópia congelada".
2. Acrescentar ao Anexo A: "spike de desempenho se mede no Mac de referência; medição em nuvem só indica ordem de grandeza".
3. Acrescentar à seção de riscos 0.I: "ruído de ambiente do Godot (logs/certificados) não pode derrubar o `check_all`; só erro real derruba".
4. Tarefas de tamanho: LW-020 e LW-021 precisaram de autorização em arquivo protegido; sugiro marcar essas tarefas, no roadmap, com "exige autorização de `project.godot`" para ninguém ser surpreendido. LW-026 passou do limite de ~8 arquivos (fixtures binárias e migração); sugiro tratar fixtures de save como um item à parte na contagem.
5. Acrescentar ao Anexo A: "toda verificação nova (regra do `check_architecture`, varredura, teste de determinismo) vem com um teste que a faça falhar de propósito". Motivo: os furos achados na LW-029 eram verificações que passavam sem poder falhar; na LW-029A, as 6 mutações da ferramenta mostraram que os testes novos pegam o erro.

**Proposta de texto para a arquitetura 27.3** (a tabela passaria a dizer; o arquivo é protegido e **não foi editado**):

| Regra | Como detecta (busca de texto) |
|---|---|
| Simulação usando cena | `Node`, `Node3D`, `get_node`, `$`, `Camera`, `Control`, `res://scenes` em `src/sim/`, `src/core/`, `src/data/` e `src/persistence/` (e nos arquivos de `src/app/` que não estendem `Node`, se a opção C for aprovada) |
| Aleatoriedade solta | `randf(`, `randi(`, `randomize(`, `randf_range(`, `randi_range(`, `randfn(`, `rand_from_seed(`, `.shuffle(`, `.pick_random(` e `RandomNumberGenerator.new(` fora de `core/rng/` (a tabela atual diz "fora de `core/`", mas a ferramenta só isenta `core/rng/`) |
| Tempo do sistema na simulação | `Time.get_` e `OS.get_` em `src/core/`, `src/app/`, `src/data/`, `src/persistence/` e `src/sim/`. Única exceção: a linha com `Time.get_ticks_usec` em `src/core/scheduler/scheduler.gd` (medição que não entra no estado) |
| Variável estática mutável | `static var` nas mesmas pastas |
| Relógio e barramento fora de core e app | chamadas `.advance_step(`, `.set_paused(`, `.set_speed(` e `.dispatch(` fora de `src/core/` e `src/app/` |

Acrescentar em **[LIM]**: `seed(`, instâncias criadas por `ClassDB` e fontes do sistema não são pegas, e a regra do relógio só varre `src/`.

**Proposta de redação do item 5 da DEC-113** (os números não mudam): *"Os passos acima de 3 ms não se repetem no mesmo passo em 2 ou mais das 3 execuções. Passos periódicos conhecidos do módulo de teste são classificados à parte. Se não houver nenhum passo acima de 3 ms, o item vale por ausência, e isso é registrado assim."* Acrescentar à régua o registro da taxa de passos acima de 10 ms **por milhão de passos**, além da taxa por minuto.

## 5. TESTES EXECUTADOS
**Nuvem (Claude, Linux x86_64, Godot 4.7.2 estável oficial), 03/11/2026**
- `tools/check_all` no commit `4efa0a6`, sem nenhuma alteração: **VERDE**, 154 de 154 testes (Scripts 21, Asserts 3292), "oito verificações" de arquitetura, varredura de avisos do GDScript limpa (60 scripts), 1 aviso "Deprecated" do GUT.
- `tools/run_sim --days 30 --seed 1`, duas rodadas: hash **idêntico** nas duas, `732907967efdba5f718687a0bbafbfe102ac51cabc9d15a7f0119a9e64ebc4d7`.
- Na LW-029A: os dois arquivos de teste novos rodaram verdes (5/5 e 4/4) e a mutação do canário (remover a ordenação) deixou o teste vermelho, como esperado.
- **Rodada final, depois das edições desta tarefa (somente documentos):** `tools/check_all` **VERDE**, 154 de 154 (Scripts 21, Asserts 3292), 1 aviso "Deprecated", varredura de avisos do GDScript limpa (60 scripts). A saída completa é **idêntica** à da linha de base acima; a única diferença possível é o tempo de execução, que não comparei.

**Mac (Arthur; MacBook Air, macOS, Godot 4.7.2), informado por Arthur**
- Antes da LW-029A, commit `0eb1bdf`: `check_all` VERDE, 145 testes. F5 da cena inicial em 02/11/2026: janela com piso, cubo, céu e sol; a data avança; o Espaço pausa e continua; a aba Erros fica vazia. SP1 em release: 3 execuções, nenhum passo acima de 10 ms.
- **03/11/2026, clone novo do ramo `lw-029a-correcoes-revisao`, commit `4efa0a6`: `check_all` VERDE.** Passing Tests 154 de 154 (Scripts 21, Asserts 3292); nenhuma linha de FALHA ou VIOLAÇÃO; linha final "VERDE: arquitetura, dados e etapa de testes aprovadas"; "Arquitetura: oito verificações aprovadas" no projeto real; "LW-029A: 27 violações detectadas e 17 casos aceitos"; os 6 casos de pré-requisitos aprovados; varredura de avisos do GDScript limpa (60 scripts); 1 aviso "Deprecated" do GUT (`wait_frames`, `tests/unit/test_app_nodes.gd:90`).
- `run_sim --days 30 --seed 1`: hash `732907967efdba5f718687a0bbafbfe102ac51cabc9d15a7f0119a9e64ebc4d7`, **igual** ao do desktop Windows e ao da nuvem.

**Windows (Arthur; desktop, Git Bash, Godot 4.7.2, ramo `lw-029a-correcoes-revisao`, commit `4efa0a6`), informado por Arthur**
- `check_all` terminou **VERMELHO** por três linhas que só aparecem no Windows, todas de ferramenta de verificação (detalhes na seção 7). Os testes do GUT passaram: **154 de 154** (Scripts 21, Asserts 3292), inclusive os 9 novos da LW-029A (ordem do `Dictionary` 5/5 e salvar/carregar de ponta a ponta 4/4). Varredura de avisos do GDScript limpa (60 scripts).
- `run_sim --days 30 --seed 1`, duas rodadas: hash **idêntico**, o mesmo da nuvem e do Mac.
- Teste de quebra (trocar `4` por `5` em `tests/unit/test_lw010_pass.gd`): **pegou a falha** (153 aprovados e 1 falho, Asserts 3291/3292, mensagem "A soma deve ser igual a quatro"); depois de desfazer a edição, `git status` ficou vazio.


## 6. RESULTADOS — critérios de aceitação da fase (roadmap 0.F)
| # | Critério | Situação real |
|---|---|---|
| 1 | `check_all` verde em pasta nova, seguindo só o README | **Verde em clone novo no Mac; a parte "seguindo só o README" NÃO está confirmada.** Clone novo do commit `4efa0a6`: 154 de 154. Arthur informou em 03/11/2026 que, no Mac, seguiu comandos recebidos no chat, e não só o README. **No Windows também não foi provado**: o README só cobre macOS (Arthur seguiu um guia provisório) e o `check_all` terminou vermelho por três linhas de ferramenta (ressalvas da LW-030, seção 7) |
| 2 | Mesma semente, mesmo hash em 3 execuções; sementes diferentes, hashes diferentes | **Atendido.** Testes (`test_state_hash`) e SP1; `run_sim --days 30 --seed 1` deu o mesmo hash na nuvem, no Mac e no Windows (observação; a DEC-081 não exige igualdade entre máquinas) |
| 3 | SP1 dentro do orçamento | **Atendido e CONFIRMADO em release.** Mac de referência, build de release, 3 execuções (1 ano, 1.000 NPCs): média 0,075 ms, p99,9 0,600 ms, máximo 2,857 ms, **0 passos > 10 ms em 1,95 min medido**, hash igual ao da nuvem. Passa nos 5 itens da régua DEC-113. Em depuração houve picos (informativo). Limitação: vale para o módulo de teste (NPCs "de mentira"), não para o jogo completo |
| 4 | Erro proposital em JSON apontado com arquivo e campo; `check_all` o detecta | **Atendido.** Teste do Codex no Mac recusou o dado ruim com mensagem clara |
| 5 | Salvamento: ida e volta com hash idêntico; adulterado é rejeitado; falha simulada preserva o save | **Atendido.** A LW-029A acrescentou o teste da cadeia completa em disco (4 testes) |
| 6 | `check_architecture` reprova as violações propositais e aprova o projeto real | **Atendido no Mac e na nuvem** (oito verificações; 27 violações detectadas e 17 casos aceitos pelo teste da LW-029A, além dos casos das LW-012, 016 e 021). **No Windows (Git Bash) não**: a ferramenta acusa a exceção de `scheduler.gd:37` e o teste dela para no meio (seção 7) |
| 7 | Cena inicial abre sem erros e mostra título, versão e hora avançando | **Atendido** por teste e conferido por Arthur com F5 em 02/11/2026 (data avança, Espaço pausa e continua, aba Erros vazia) |
| 8 | Documentação existente e aprovada | **Existe.** `AGENTS.md`, modelos, decisões e `ROADMAP_STATUS.md` (atualizado nesta tarefa). Aprovações de Arthur: LW-029 em 03/11/2026 e LW-030 em 03/11/2026 (com ressalvas). A aprovação **desta** LW-031 está pendente |
| 9 | Cópia remota (GitHub) com a tag `fase-0-concluida` | **Pendente.** A tag **não foi criada**. No remoto há o ramo `lw-029a-correcoes-revisao` (publicado em 03/11/2026 com autorização de Arthur); `main` continua em `95bc4c4`. A visibilidade do repositório é decisão de Arthur (DEC-089) |

**Condições para a fase estar concluída (roadmap, 0.J):**
| # | Condição | Situação |
|---|---|---|
| 1 | As 31 tarefas concluídas ou dispensadas | **Sim** (29 concluídas, LW-004 e LW-005 dispensadas com justificativa no `ROADMAP_STATUS.md`) |
| 2 | Critérios de 0.F cumpridos | **Com as ressalvas dos critérios 1, 6 e 9 acima** |
| 3 | REV e VAL aprovadas, sem achado crítico aberto | **Sim**: LW-029 aceita (0 críticos) e LW-030 assinada com ressalvas, ambas em 03/11/2026 |
| 4 | Decisões dos spikes registradas em `docs/decisions/` | **Sim** (registros 0001 a 0006) |
| 5 | Tag `fase-0-concluida` no remoto | **Não** (pendente, autorização de Arthur) |
| 6 | `ROADMAP_STATUS.md` mostra 100% | **Sim**, com a tag marcada como pendente |

## 7. PROBLEMAS ENCONTRADOS
**Ressalvas da assinatura da LW-030 (Arthur, 03/11/2026):**
- **(a)** O README só cobre macOS. No Windows, Arthur seguiu um guia provisório; portanto o item "só o README" **não foi provado no Windows**.
- **(b)** No desktop Windows (Git Bash, Godot 4.7.2, ramo `lw-029a-correcoes-revisao`, commit `4efa0a6`) o `check_all` terminou VERMELHO por **três linhas, todas de ferramenta de verificação**, que não aparecem no Mac:
  1. `VIOLAÇÃO: tempo do sistema na simulação`, do `tools/check_architecture`, em `src/core/scheduler/scheduler.gd:37` (`Time.get_ticks_usec`), que é a exceção declarada. **Hipótese não verificada:** o ripgrep escreve o caminho com `\` no Windows e a regra da exceção espera `/`. É um problema novo, vindo da LW-029A.
  2. `FALHA: Time.get_ticks_usec no scheduler.gd é a exceção deveria passar`, em `tests/test_check_architecture.sh`, que usa `set -e` e **para nesse ponto**: os casos seguintes dele não rodaram no Windows. **Eles rodaram inteiros no Mac.**
  3. `FALHA: sem rg...`, em `tests/test_check_prerequisites.sh` (já conhecida; também para ali).

**Outros problemas:**
- Aviso "Deprecated" do GUT em `tests/unit/test_app_nodes.gd:90` (`wait_frames`, trocar por `wait_physics_frames` ou `wait_process_frames`). Presente no Mac e na nuvem; sem efeito nos resultados.
- Textos ainda desatualizados, que dependem de arquivos protegidos ou de código: o README fora da seção 5 (a linha 180, na seção 6.1, lista `tests/` como `unit`, `soak` e `fixtures` e omite `integration`; a linha 9 da tabela do topo foi corrigida nesta tarefa); o resumo da LW-030 (cita 145 testes); `docs/fase-0/LW-029-pacote-de-revisao.md` e o rascunho da LW-031 (dizem "7 regras"); a linha 4 do `docs/backlog.md` (a regra do relógio foi feita na LW-029A); e os itens do achado M9. Tudo registrado no backlog, na linha "DOC pendente".

## 8. RISCOS
- **Pico de tempo por passo:** confirmado em release no Mac (régua DEC-113, 3 execuções). O risco que resta é de leitura: a medição foi feita em condições silenciosas (carregador, Godot fechado, sem uso) e com 1.000 NPCs de teste; em depuração, e com a máquina ocupada, os picos voltam (13, 7, 5, 7, 0 e 1 passos > 10 ms nas seis medições de depuração). Reavaliar quando o módulo de NPCs real existir.
- **Módulo de NPCs real (achado I5):** o módulo de teste do SP1 junta 818 dos 1.000 NPCs no mesmo passo a cada 99 passos. Pela ilustração do parecer (conta, não medição), um pensamento real de 50 µs daria uma onda de ~41 ms e um de 100 µs, de ~82 ms, acima do limite duro de 50 ms da régua. Por isso o desenho de NPC T1 não foi dado como validado; vira critério de aceite da tarefa dona.
- **Salvamento (achado I4):** passa de 100 ms na thread principal a partir de ~1 MB de estado (medido). A arquitetura (cap. 10.4) estima ~1,3 MB só de memórias e relações de 300 NPCs T2, antes de o JSON repetir nomes de campos, ou seja, já acima de ~1 MB; a escrita em outra thread (plano B) não foi implementada.
- `check_architecture` é busca de texto; a regra de imports entre camadas só chega na LW-036; as limitações novas estão no backlog.
- **Windows não é plataforma suportada:** a referência continua sendo o Mac (DEC-015 e DEC-016). Suporte oficial exige uma entrada nova em `DECISIONS.md`.
- Código de spike em `tests/soak/` precisa continuar sendo tratado como descartável.
- Trabalho local do Mac preservado no ramo `mac-snapshot` (já no mesmo repositório do GitHub): comparado só em leitura (`docs/fase-0/mac-snapshot-comparacao.md`), sem tocar nem juntar nada.
- Repositório **público** (visibilidade: DEC-089, pendente). O ramo `lw-029a-correcoes-revisao` foi publicado assim, com autorização de Arthur.

## 9. PENDÊNCIAS
- **Tag `fase-0-concluida`:** só com a autorização de Arthur, na etapa de publicação, depois da aprovação desta tarefa. Não foi criada.
- **Publicação:** o push do ramo `lw-031-fechamento-fase-0` foi autorizado por Arthur em 03/11/2026, só desse ramo e sem `--force`, para revisão em modo leitura. Não houve merge, nem tag, e `main`, `mac-snapshot` e a visibilidade do repositório não foram tocados.
- **DEC-089** (visibilidade do repositório): pendente.
- **Dívidas registradas em `docs/backlog.md`:** LW-029B (M1, M3, M7); regra "sem Node" em `src/app` (opção C, candidata a critério da LW-036; linha da LW-029A); DOC que exige pedido de Arthur; portabilidade Windows; critérios das tarefas donas para I4 e I5; reconciliação de `main` e do ramo `mac-snapshot`; DEC-089; achados menores sem dono.
- Ajustar `docs/DEVELOPMENT_ROADMAP.md` (tamanhos de tarefa, seção 4.3) só se Arthur aprovar as propostas.
- Testes manuais que cabem a Arthur: nenhum novo nesta tarefa (só documentos).

## ACOMPANHAMENTO (obrigatório)
- **Avanço:** Fase 0 com 31 de 31 tarefas concluídas ou dispensadas (100% das tarefas); fase concluída pelo roadmap só com a tag. Projeto: 31 de 192 tarefas (16,1%).
- **Próxima tarefa recomendada:** quem escolhe é Arthur. Pelo roadmap, a primeira da Fase 1 é a **LW-032** (contratos mínimos de `world`, `character` e `bridge`); a Fase 1 **não foi iniciada**. A LW-029B e a portabilidade Windows estão marcadas no backlog para o começo da Fase 1.
- **Decisões que dependem de Arthur:** aprovar esta tarefa; autorizar a tag e decidir a visibilidade do repositório (DEC-089); aprovar ou recusar as propostas da seção 4.3 e os textos para a arquitetura 27.3 e a DEC-113; decidir se haverá suporte ao Windows.
- **Git:** ramo `lw-031-fechamento-fase-0`, criado a partir de `4efa0a6` (ponta de `lw-029a-correcoes-revisao`); um commit (que inclui o parecer); push do ramo autorizado por Arthur em 03/11/2026 para revisão em modo leitura; sem merge; sem tag; `main` e `mac-snapshot` intocados.
