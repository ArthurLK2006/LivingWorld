# RASCUNHO — Relatório de fechamento da Fase 0 (LW-031)

**Este é um rascunho preparado em 02/11/2026, antes da LW-029 e da LW-030.** Nada aqui vale como fechamento. As condições abertas estão marcadas **AGUARDANDO RESULTADO** e os trechos que dependem da revisão externa estão marcados **A PREENCHER**. Datas e horas em horário de Brasília.

```
RELATÓRIO — LW-031: Fechamento da Fase 0        Status: RASCUNHO (não é PRONTA PARA REVISÃO)
```

## 1. RESUMO
A Fase 0 entregou a base técnica do jogo: um motor de simulação que roda sem janela (relógio, sorteios repetíveis, eventos, agendador e mundo), leitura e conferência de dados, salvamento com proteção contra falhas, uma cena inicial com a hora simulada e uma verificação única (`tools/check_all`) que roda tudo. Três spikes (núcleo, dados e salvamento) foram medidos e registrados. Faltam a revisão externa (LW-029), a sua validação (LW-030) e três confirmações no Mac.

**Placar da fase em 02/11/2026:** 28 de 31 tarefas concluídas ou dispensadas (26 concluídas, 2 dispensadas); 3 pendentes (LW-029, LW-030, LW-031). A LW-006 e a LW-023 foram fechadas por Arthur em 02/11/2026. Percentual oficial: **A PREENCHER** (o `ROADMAP_STATUS.md` só passa a 100% depois da LW-006, LW-029 e LW-030).

## 2. ARQUIVOS CRIADOS / 3. ARQUIVOS MODIFICADOS (previstos para a LW-031)
- Modificar: `docs/ROADMAP_STATUS.md` (fase para 100% quando as condições abaixo estiverem cumpridas), seção "Estado atual" do `README.md`, e `docs/DEVELOPMENT_ROADMAP.md` **somente** se você aprovar os ajustes de tamanho de tarefa da seção 4.
- Criar: a tag `fase-0-concluida` (ver Pendências).
- Hoje o `README.md` já foi atualizado para refletir o que existe (seções 5, 6, 8, 9 e 10).

## 4. DECISÕES TÉCNICAS e retrospectiva
**4.1 Decisões da fase (todas já registradas):** GUT 9.7.1 (DEC-086); JSON validado para as definições (DEC-082, aprovada); JSON comprimido com escrita `.tmp` → conferência → backups → final como formato de save do protótipo (DEC-084, aprovada, com reavaliação do binário se o estado real passar de ~1 MB); desvio do ciclo de vida de módulos aprovado (`tick` em minutos inteiros e `on_load` devolvendo `Result`).

**4.2 Retrospectiva curta (o que atrasou, em fatos):**
- Ambientes: o Godot não existia no ambiente de nuvem e o do Codex tem erros de certificado e de gravação de logs. Resposta: instalação autorizada e `tools/filter_env_noise`, que ignora só esse ruído, com aviso.
- Arquivos protegidos: o registro dos autoloads e a cena inicial exigiram parar e pedir autorização (LW-020/021).
- Testes frágeis: testes que contavam itens da pasta editável quebraram com uma edição legítima do Codex; corrigido com a pasta congelada `tests/fixtures/data/frozen/`.
- Medição em ambiente compartilhado: o pico de 10 ms do SP1 oscilou entre execuções idênticas (ruído do contêiner); por isso o critério segue aberto até a medição no Mac.
- **Erro meu nos relatórios (achado em 02/11/2026):** os relatórios de várias tarefas diziam "sem avisos de GDScript". Estava errado: o Godot só imprime avisos de compilação com o depurador ligado, e minhas execuções sem janela não os mostravam. O editor de Arthur mostrou 5 (divisão inteira em `sim_clock.gd`); a varredura completa achou 27. Todos corrigidos sem `@warning_ignore`; a divisão inteira, que é intencional (minutos inteiros), virou `IntMath.floor_div`; o `check_all` agora falha se houver qualquer aviso (`tools/check_gdscript_warnings`, com teste). O hash do mundo não mudou.
- Defeito achado por teste: o `World.teardown()` chamava módulos que nunca passaram por `setup()`. Corrigido.
- **O que a revisão externa achou:** **A PREENCHER (LW-029).**

**4.3 O que mudar nos modelos do roadmap (propostas minhas, para Arthur decidir):**
1. No modelo de prompt do Codex (Anexo A), acrescentar: "testes não podem depender de pasta editável nem contar itens dela; use uma cópia congelada".
2. Acrescentar ao Anexo A: "spike de desempenho se mede no Mac de referência; medição em nuvem só indica ordem de grandeza".
3. Acrescentar à seção de riscos 0.I: "ruído de ambiente do Godot (logs/certificados) não pode derrubar o `check_all`; só erro real derruba".
4. Tarefas de tamanho: LW-020 e LW-021 precisaram de autorização em arquivo protegido; sugiro marcar essas tarefas, no roadmap, com "exige autorização de `project.godot`" para ninguém ser surpreendido. LW-026 passou do limite de ~8 arquivos (fixtures binárias e migração); sugiro tratar fixtures de save como um item à parte na contagem.

## 5. TESTES EXECUTADOS (no ambiente de nuvem, 02/11/2026)
- `tools/check_all` — **VERDE**, 141 de 141 testes; 7 regras de arquitetura; validação de dados; cena principal por 60 quadros; `run_sim`.
- Mesmo comando em ambiente sem permissão de gravar dados e logs — **VERDE**, com a nota "4 mensagem(ns) de ambiente ignorada(s)".
- Spikes: SP1 (editor e release), SP3 e SP5 conforme `docs/decisions/0003` a `0005`.
- **No Mac (Arthur): AGUARDANDO RESULTADO** — ver seção 9.

## 6. RESULTADOS — critérios de aceitação da fase (roadmap 0.F)
| # | Critério | Situação |
|---|---|---|
| 1 | `check_all` verde em pasta nova, seguindo só o README | Verde na nuvem. **AGUARDANDO RESULTADO** no Mac (LW-030) |
| 2 | Mesma semente, mesmo hash em 3 execuções; sementes diferentes, hashes diferentes | Atendido (testes e SP1) |
| 3 | SP1 dentro do orçamento | **Atendido e CONFIRMADO em release.** Mac de referência, build de release, 3 execuções (1 ano, 1.000 NPCs): média 0,075 ms, p99,9 0,600 ms, máximo 2,857 ms, **0 passos > 10 ms em 1,95 min medido**, hash igual ao da nuvem. Passa nos 5 itens da régua DEC-113. Em depuração houve picos (informativo) |
| 4 | Erro proposital em JSON apontado com arquivo e campo; `check_all` o detecta | Atendido; teste do Codex no Mac recusou o dado ruim com mensagem clara |
| 5 | Salvamento: ida e volta com hash idêntico; adulterado é rejeitado; falha simulada preserva o save | Atendido |
| 6 | `check_architecture` reprova as violações propositais e aprova o projeto real | Atendido (7 regras) |
| 7 | Cena inicial abre sem erros e mostra título, versão e hora avançando | Atendido por teste; conferência visual com F5: **AGUARDANDO RESULTADO** |
| 8 | Documentação existente e aprovada | Em andamento (README atualizado; aprovação de Arthur pendente) |
| 9 | Cópia remota com a tag `fase-0-concluida` | **Pendente de autorização** (ver 9) |

## 7. PROBLEMAS ENCONTRADOS
Veja a retrospectiva (4.2). Além disso: **A PREENCHER** com os achados da LW-029 e as falhas da LW-030.

## 8. RISCOS
- **Pico de tempo por passo:** confirmado em release no Mac (régua DEC-113, 3 execuções). O risco que resta é de leitura: a medição foi feita em condições silenciosas (carregador, Godot fechado, sem uso) e com 1.000 NPCs de teste; em depuração, e com a máquina ocupada, os picos voltam (13, 7, 5, 7, 0 e 1 passos > 10 ms nas seis medições de depuração). Reavaliar quando o módulo de NPCs real existir.
- O salvamento passa de 100 ms na thread principal a partir de ~1 MB de estado (plano B descrito, não implementado).
- `check_architecture` é busca de texto; a regra de imports entre camadas só chega na LW-036.
- Código de spike em `tests/soak/` precisa continuar sendo tratado como descartável.
- Trabalho local do Mac preservado no ramo `mac-snapshot`: ainda não comparado com este ramo (comparação prevista para depois do fechamento da fase).

## 9. PENDÊNCIAS
**Condições abertas da Fase 0: nenhuma delas continua aberta.** Pico de 10 ms: CONFIRMADO em release (3 execuções). Cena inicial (F5): data avança, Espaço pausa e continua, aba Erros sem erros. `check_all` no Mac: VERDE, 145 testes. Teste do Codex na edição de dados: concluído (ver LW-025). O que resta da fase são as tarefas LW-029, LW-030 e LW-031.

**Outras pendências**
- LW-006: fechada por Arthur em 02/11/2026 (sem pendência).
- LW-029 (revisão externa) e LW-030 (validação de Arthur).
- Tag `fase-0-concluida`: só com sua autorização e depois de decidir a visibilidade do repositório (DEC-089). Não foi criada.
- Ramo `mac-snapshot`: comparado só em leitura (`docs/fase-0/mac-snapshot-comparacao.md`); **não tocado nem junto a nada**. Depois do fechamento da Fase 0 apresento a proposta de reaproveitar só o que é único (ponte e tela inicial), **uma tarefa por vez**; a pasta `experiments/` só entra com autorização de Arthur.
- `check_all` no Mac falhava por falta do `rg`; agora confere pré-requisitos no início (README, seção 8). Verde no Mac (141 testes) depois de `brew install ripgrep`.
- Itens de backlog já registrados: textos da interface por chave de tradução; semente e versão do jogo definidas por tela de novo jogo.

## ACOMPANHAMENTO (obrigatório)
- **Avanço:** 28 de 31 tarefas concluídas ou dispensadas; faltam LW-029, LW-030 e LW-031.
- **Próxima tarefa recomendada:** LW-029 (revisão externa). Fase 1 **não iniciada**.
- **Decisões que dependem de Arthur:** enviar o pacote da LW-029 ao revisor; aprovar os ajustes de modelo (4.3); autorizar a tag e o envio, e decidir a visibilidade do repositório.
- **Git:** rascunho versionado em `docs/fase-0/`; ramo de trabalho `claude/living-world-coordination-umft1k`; ramo `mac-snapshot` intocado.
