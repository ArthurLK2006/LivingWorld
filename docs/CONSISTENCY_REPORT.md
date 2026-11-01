# LIVING WORLD — RELATÓRIO DE CONSISTÊNCIA DOCUMENTAL

**Versão:** 0.3 · **Data:** 01/11/2026 (horário de Brasília). A **seção 0** é a revisão final da v0.3; as seções 1 a 7 são o registro da consolidação da v0.2 e foram mantidas como histórico (o que mudou depois está na seção 0).
**Pacote avaliado:** `README.md`, `AGENTS.md`, `docs/GDD.md`, `docs/TECHNICAL_ARCHITECTURE.md`, `docs/DEVELOPMENT_ROADMAP.md`, `docs/DECISIONS.md`, `docs/BRIEFING_MESTRE.md` (todos na versão 0.3, exceto o briefing, que é cópia fiel do texto original).
**Quem decide o que fazer com este relatório:** Arthur. Este relatório **propõe**; não aprova nada.

**Rótulos:** **fato** (verificado nos arquivos) · **proposta** · **hipótese** · **pendente** · **limitação**.

---

## 0. Revisão final (v0.3, 01/11/2026, 15:32)

Arthur encerrou a revisão documental com 15 diretrizes escritas. Esta seção diz o que mudou e o que foi conferido. **Nada foi implementado.**

### 0.1 As 14 inconsistências da revisão (B1 a B14)

| # | Tratamento na v0.3 | Onde |
|---|---|---|
| B1 | Corrigida: a ordem e os nomes das fases são de Arthur; a alocação do conteúdo a cada fase é proposta | RM 0.13, 0.13-B (desvios 1 e 8), Fase 4; DEC-070 |
| B2 | SP6 (combate, LW-152) roda logo depois da LW-054 e antes da Fase 2; o SP4a (LW-033) inclui o teste de subida de câmera; perguntas de diversão nas validações das Fases 1 e 3 | RM; DEC-080 (aprovada só nessa parte) |
| B3 | GDD 7.6 passou a [P1]: o protótipo não tem sistema genérico de atividades; três trajetórias como meta (diretriz 10) | GDD 7.6; DEC-062 |
| B4 | A proibição de trabalho de rede é regra do `AGENTS.md`, não decisão da DEC-018 | AGENTS 1, 6 e 12.2 |
| B5 | Ressalvas de DEC-008 e DEC-027 visíveis no índice; TA 19.2 separa [CONF] de [REC]; legenda do GDD diz que [CONF] só vale com `DECISIONS.md` APROVADA. **Limitação:** as marcas [CONF] do GDD não foram conferidas uma a uma | DECISIONS, TA, GDD |
| B6 | T0 adiado (diretriz 8); "LOD de simulação" da hipótese 4 vale para S0 e S1 no primeiro protótipo | GDD 8.2 e 24.2; TA 8.2; RM desvio 2 |
| B7 | LW-001 concluída; LW-002 e LW-003 enxutas; LW-004 e LW-005 dispensadas; Anexo G virou registro | RM |
| B8 | DEC-081 aprovada (determinismo no mesmo ambiente, sem replay universal); DEC-083 aprovada só nos princípios; formato validado no SP5 | DECISIONS; RM 0.13-C |
| B9 | Teste de subida de câmera no SP4a; hardware de referência é o Mac de Arthur, identificado pelo Codex na LW-006 | RM LW-033, LW-006 |
| B10 | `check_all` é um script de terminal do macOS que chama o Godot sem janela | AGENTS 9.1; RM LW-011 |
| B11 | Spikes renomeados para SP1 a SP8; os níveis de simulação continuam S0 a S3 | todos os documentos |
| B12 | `AGENTS.md` com 32.280 bytes (limite de leitura do Codex, a confirmar: 32.768). Sobram menos de 500 bytes: texto novo deve ir para `docs/` | AGENTS |
| B13 | Migração de save proporcional ao que existe; migrações complexas só com necessidade real (diretriz 7) | AGENTS 4.15; TA 18.6; RM LW-111, 142 e 187 |
| B14 | Tabela de portões de decisão (DEC-055, 083, 040, 066, 053), cada uma pedida a Arthur só quando a tarefa-portão chegar (diretriz 15) | RM 0.13-C |

Também corrigido: o roadmap citava "níveis individuais (S0 a S2)" no desvio 2, mas S2 é o nível agregado; agora diz S0 e S1. A contagem "11 com ressalva" no total de decisões estava errada; são 10.

### 0.2 Decisões

`DECISIONS.md` mantém 112 entradas: **APROVADA 47 (10 com ressalva) · PROPOSTA 34 · PENDENTE 20 · DESCARTADA 10 · SUBSTITUÍDA 1**. Passaram a APROVADA, nos termos das diretrizes: DEC-012, 015, 016 (só a referência), 022, 041, 050, 051, 062 (só a meta de três), 080 (só a antecipação), 081, 083 (só os princípios) e 089 (só o serviço). Nenhuma outra mudou de status.

### 0.3 O que foi conferido por script nesta versão

- 112 entradas de decisão, sem duplicata, e a lista rápida das APROVADAS com 47 itens;
- 192 tarefas `LW-001` a `LW-192`, em sequência, uma vez cada; nenhuma citação de `LW-NNN` ou `DEC-NNN` inexistente; a única dependência "para frente" é a LW-055 esperar a LW-152 (intencional);
- os 14 diagramas Mermaid dos documentos renderizam sem erro;
- `AGENTS.md` abaixo de 32.768 bytes.

**Não conferido:** nada foi executado no Godot (não há projeto). As versões de GUT, gdUnit4 e Terrain3D vêm de pesquisa de 01/11/2026 e serão reconfirmadas na LW-010 e na hora da instalação.

### 0.4 Pendências que não bloqueiam o início

Hardware **mínimo** (DEC-016) · visibilidade do repositório (DEC-089; sem push enquanto não for decidida) · framework de testes (DEC-086, LW-010) · as dúvidas da tabela 0.13-C do roadmap · telemetria (DEC-023) e gamepad (DEC-024).

---

## 1. Resumo para quem tem pouco tempo (v0.2, histórico)

1. **O pacote está utilizável para iniciar a Fase 0**, com uma condição: Arthur precisa responder às **cinco decisões iniciais** do formulário do Anexo G do roadmap (versão do Godot, sistema operacional, hardware, hospedagem do Git, idioma do código). Sem elas, as tarefas LW-002 a LW-006 não começam. **[fato]**
2. Foram encontrados **11 problemas de consistência** entre os documentos (seção 4) e **11 problemas técnicos de Godot** (seção 6). **Todos foram corrigidos** nesta versão. Nenhum deles mudou o design do jogo, e nenhuma ideia do conceito original foi removida. **[fato]**
3. **Nenhuma decisão mudou de status.** O registro continua com 112 entradas: 35 APROVADA, 38 PROPOSTA, 28 PENDENTE, 10 DESCARTADA, 1 SUBSTITUÍDA. **[fato]**
4. Há **12 contradições conhecidas** (C1 a C12 em `DECISIONS.md`, seção 4) que só Arthur pode resolver. Nenhuma bloqueia a Fase 0. **[fato]**
5. **Nenhum código foi escrito nem executado**, e o Godot não foi instalado. A viabilidade técnica foi avaliada por **leitura da documentação oficial e do código-fonte do Godot**, não por teste (ver seção 6). **[limitação]**

---

## 2. O que foi verificado e como

| Verificação | Método | Resultado |
|---|---|---|
| IDs de decisão (`DEC-NNN`) citados em qualquer documento existem em `DECISIONS.md` | Script que extrai todas as citações e compara com as 112 entradas | **Aprovada.** Nenhuma citação inexistente (a única ocorrência de `DEC-113` é o aviso "próximo número livre") |
| IDs de tarefa (`LW-NNN`) | Script: 192 linhas de tarefa, uma por ID, de LW-001 a LW-192, sem lacuna nem duplicata; nenhuma citação fora do intervalo | **Aprovada** |
| Status válidos e campos obrigatórios das 112 entradas | Script sobre `DECISIONS.md` | **Aprovada** |
| `AGENTS.md`: tamanho e estrutura | `wc -c`: 31.842 bytes (o limite de leitura do Codex é de 32 KiB = 32.768 bytes, **a confirmar na versão em uso**); 17 seções numeradas; 13 regras obrigatórias | **Aprovada**, com folga de apenas 926 bytes |
| Links internos do `README.md` | Script | **Aprovada** (o link para `CONSISTENCY_REPORT.md` passa a existir com este arquivo) |
| Frases antigas que contradiziam as correções ("quatro decisões", formato antigo de relatório, referência errada à LW-005) | Busca de texto | **Aprovada** |
| Comparação de números entre GDD, arquitetura e roadmap (escala de tempo, módulos, contagem de tarefas e de fases) | Leitura e conferência manual | **Aprovada** (1 minuto simulado por passo; 192 tarefas; 6 fases; 8 REV; 6 VAL) |
| Leitura cruzada de conteúdo (GDD × arquitetura × roadmap × decisões) | Leitura integral dos trechos de escopo, de sistemas centrais, de testes e de Git | Gerou os 11 achados da seção 4 |
| Viabilidade técnica em Godot 4.x | Revisão independente (outro agente) contra documentação e código-fonte do Godot; pontos críticos reconferidos por mim | Viável, 11 correções (seção 6) |

**Não verificado (e por quê):**

- Nenhum teste automatizado existe ainda, então **nada foi executado em Godot**. **[limitação]**
- Valores numéricos marcados **[HIP]** (por exemplo, 150 a 300 NPCs, 12 a 30 províncias, orçamentos de milissegundos) **não foram medidos**. São hipóteses até os spikes SP1, SP2 e SP4a. **[limitação]**
- O comportamento real do Codex diante do `AGENTS.md` só será conhecido no "teste de leitura" da LW-008. **[limitação]**

---

## 3. Resultado por critério pedido por Arthur

### 3.1 Coerência entre GDD, arquitetura e roadmap — **Coerente, com ressalvas corrigidas**

- Os três descrevem o mesmo jogo, os mesmos módulos, a mesma escala de tempo e a mesma divisão em camadas. **[fato]**
- O roadmap **desvia deliberadamente** do GDD em oito pontos (ordem das fases, T0, trajetórias, polity vizinha, lista de corte, clima, nomes, eventos dinâmicos). Os desvios estão declarados no roadmap (0.13-B) e registrados em `DECISIONS.md` (4.1). **Só a ordem das fases (DEC-094) e a regra de nomes genéricos (DEC-100) estão aprovadas.** Os outros seis desvios são PROPOSTAS. **[fato]**
- Divergências **não declaradas** foram achadas e corrigidas (seção 4: C14, C15, C18, C19, C23).

### 3.2 Ausência de contradições — **Não há contradição sem registro; há contradições abertas que dependem de Arthur**

- 12 contradições conhecidas continuam **abertas ou tratadas só por regra** (C1 a C12). Exemplos: facções × polities (C1), trajetórias do protótipo (C2), salvamento ausente do briefing (C10), "determinístico" × "replay exato" (C12). **[fato]**
- 11 contradições novas foram **resolvidas nos textos** (C13 a C23).
- **Risco residual [hipótese]:** a leitura foi feita por trechos de escopo e de sistemas centrais. Contradições sutis em capítulos de detalhe (por exemplo, valores numéricos repetidos em dois lugares) podem existir. A REV da Fase 0 (LW-029) e as leituras de cada tarefa são o segundo filtro.

### 3.3 Separação entre decisões aprovadas e propostas — **Aprovada**

- Só 35 entradas estão APROVADAS, todas com fonte no briefing ou em prompt de Arthur. **[fato]**
- As legendas **[CONF]** da arquitetura, do roadmap e do GDD diziam "confirmado pelo GDD/arquitetura". Isso permitia que uma proposta passasse por decisão. As três legendas foram redefinidas: **[CONF] só vale se `DECISIONS.md` disser APROVADA.** **[fato]**
- Três itens que o GDD rotulava [CONF] sem base no briefing foram relabelados [PROP]: teclado e mouse, salvamento, construção por NPCs. **[fato]**
- **Pendente:** as 10 alternativas em status DESCARTADA vieram da arquitetura (recusas feitas pelo documento, não por Arthur). Aguardam a ratificação dele.

### 3.4 Compatibilidade entre a arquitetura e o escopo do protótipo — **Compatível**

- A arquitetura é **maior que o protótipo de propósito**: define camadas e contratos que o protótipo usa só em parte. O roadmap cria cada módulo apenas na tarefa que precisa dele, e `src/ai_text` e `src/net` ficam vazios (AGENTS 5.8). **[fato]**
- Itens do GDD 24.2 e como o roadmap os trata:
  - Cobertos nas fases 1 a 5: região, assentamentos, pontos de interesse, bens, cadeias, mercados, caravanas, eventos, combate, câmera, interface, salvamento.
  - **Reduzidos por proposta:** trajetórias (5 → 3), população T0 (fora), clima e estações (fora), facção criminosa (forma mínima), magia e chefe (na lista de corte, decisão na LW-146).
- **Tensão que Arthur deve conhecer [fato]:** a hipótese 4 do GDD ("câmera contínua e simulação em LOD são viáveis") perde parte do sentido se o nível agregado (T0) nunca for construído. A nota inserida no roadmap (0.13-B, desvio 2) manda a LW-191 registrar que o LOD foi avaliado **só nos níveis individuais**.
- **Mudança de contagem que Arthur não pediu:** nenhuma. O total segue em 192 tarefas.

### 3.5 Viabilidade técnica para Godot 4.x — **Viável, com 11 correções já aplicadas (seção 6)**

### 3.6 Clareza das instruções do `AGENTS.md` — **Clara, com três ambiguidades corrigidas**

Corrigidas:

1. O arquivo mandava **PARAR** se qualquer documento da lista não existisse, mas `ROADMAP_STATUS.md`, `decisions/`, `modules/`, `events.md` e `backlog.md` só nascem na LW-009. O Codex pararia nas primeiras tarefas. Agora há a exceção explícita (seção 2.1).
2. Não ficava claro se o **texto da tarefa** pode autorizar download e instalação (a LW-005 precisa disso). Agora vale a autorização escrita no próprio prompt, campo "GIT E FERRAMENTAS" (seção 0).
3. O roadmap dizia que o Codex cria ramo e faz commit; o `AGENTS.md` exige autorização. O roadmap foi alinhado ao `AGENTS.md`.

**Limitação:** a regra de nomenclatura (seção 7) depende de DEC-022 (idioma do código), ainda PENDENTE. A LW-001 resolve.

### 3.7 Objetividade dos critérios de aceitação da LW-001 — **Era insuficiente; foi reescrita**

Problemas da versão 0.1 **[fato]**:

- O aceite dizia "quatro decisões escritas em frases curtas e aprovadas", sem dizer em que formato nem como provar.
- Eram **cinco** decisões bloqueantes, não quatro: o sistema operacional (DEC-015) ficava de fora.
- Não dizia quem altera `DECISIONS.md`, nem provava que só as entradas certas mudaram.

Versão 0.2:

- Cinco decisões (DEC-012, 015, 016, 022, 089), cada uma com **formato exigido do valor** no Anexo G (por exemplo, "número completo de versão estável, forma `4.<menor>.<correção>-stable`").
- Cinco condições verificáveis: formulário completo; alternativa descartada por item; "aprovo" com data; comparação (diff) mostrando que **só cinco entradas** mudaram de PENDENTE para APROVADA; nenhum código ou instalação.
- DEC-086, 023 e 024 ficam expressamente fora da tarefa.

---

## 4. Problemas encontrados (todos corrigidos nesta versão)

| ID | Gravidade | Onde | Problema | Correção |
|---|---|---|---|---|
| C13 | Importante | TA 0.1, RM 0.2, GDD 0.1 | Legendas [CONF] aceitavam "GDD" ou "arquitetura" como fonte de confirmação | Legendas redefinidas |
| C14 | Importante | TA 27.4, RM Anexo A, AGENTS 15 | Três formatos de relatório de tarefa | AGENTS 15 é o único; os outros apontam para ele |
| C15 | **Bloqueante para o Codex** | RM 0.6, 0.7, 0.10, 0.12, Anexo A | O roadmap mandava o Codex criar ramo, commitar e atualizar status; o `AGENTS.md` proíbe sem autorização | Campos "GIT E FERRAMENTAS" no prompt (Anexo A); fluxo e definição de pronto reescritos |
| C16 | Importante | TA 26.4, RM LW-001 e Anexo F | Sistema operacional alvo (DEC-015) esquecido | Incluído nos três lugares |
| C17 | **Bloqueante para o início** | RM LW-001 | Critério de aceite vago e decisão faltando | Reescrita + Anexo G |
| C18 | Importante | TA 27.3 × RM LW-012 | 6 das 8 regras de `check_architecture` sem tarefa; só 2 eram implementadas | LW-012 passa a cobrir 5 regras; LW-016, LW-021 e LW-036 cobrem as outras 3; tabela RM 0.15 |
| C19 | Importante | GDD 4.4 e 14, TA 3, DEC-060 | Clima e estações: o GDD e a TA os previam no protótipo; o roadmap e DEC-060 os excluem | Notas nos três; continua PROPOSTA |
| C20 | Menor | GDD 18.1, 21.4, 23.1 | Itens sem base no briefing marcados [CONF] | Relabelados [PROP] |
| C21 | Menor | RM 0.8 | Citava LW-005 para a estrutura de pastas (é a LW-007) | Corrigido |
| C22 | Importante | AGENTS 2.1 | Exigia arquivos que só existem após a LW-009 | Exceção declarada |
| C23 | Menor | TA 26.3 × RM | Ordem dos spikes diferente | Nota: vale a ordem do roadmap |

Outras mudanças de coerência feitas junto: LW-003 (copia o pacote inteiro para o repositório), LW-006 (não sobrescreve o `README.md`), LW-008 (valida o `AGENTS.md` em vez de reescrevê-lo, com teste de leitura), LW-009 (cria `events.md` e o modelo de registro técnico), LW-031 (atualiza "Estado atual" do README), Anexo B (itens 12 e 13: Git e formato do relatório).

---

## 5. Decisões pendentes e recomendações

### 5.1 Para começar (bloqueiam a Fase 0)

| Decisão | Entrada | Recomendação (não aprovada) |
|---|---|---|
| Versão exata do Godot 4.x | DEC-012 | A estável mais recente no início, mantida até o fim do protótipo |
| Sistema operacional | DEC-015 | O que você usa para testar |
| Hardware-alvo | DEC-016 | Sua máquina real de testes |
| Idioma do código | DEC-022 | Identificadores em inglês; comentários e documentos em português |
| Hospedagem do Git | DEC-089 | Serviço conhecido, repositório privado |

### 5.2 As cinco dúvidas que Arthur pediu para registrar (todas PENDENTES, nenhuma bloqueia a Fase 0)

| Dúvida | Entrada | Quando decidir |
|---|---|---|
| Dimensões do mundo | DEC-055 | Fase 1, LW-033 (depois do spike de terreno) |
| Quantidade de NPCs | DEC-040 | Fases 2 e 5 (spike SP2 e LW-179) |
| Escala das batalhas | DEC-053 | Fase 5 (spike SP6 e LW-146) |
| Sistema definitivo de combate | DEC-066 | Fase 5 (spike SP6) |
| Modelo de persistência | DEC-083 | Fase 0 (spike SP5) |

### 5.3 Ratificações que Arthur pode dar de uma vez (recomendação: fazer ao aceitar o pacote)

1. As **10 alternativas DESCARTADAS** pela arquitetura (`DECISIONS.md`, área 11).
2. Os **6 desvios PROPOSTOS** do roadmap (4.1: T0, trajetórias, polity vizinha, lista de corte, clima e estações, eventos dinâmicos). Sem ratificação, eles valem apenas como padrão de trabalho.

### 5.4 Recomendações de processo

1. **Rodar a LW-008 cedo e levar o resultado ao ChatGPT**: o teste de leitura do `AGENTS.md` é a única forma de saber se o Codex entende as 13 regras. O arquivo está a 926 bytes do limite; qualquer acréscimo exige cortar outra coisa.
2. **Confirmar o limite de leitura do Codex** (32 KiB) na documentação da versão em uso antes da LW-008.
3. **Não iniciar a LW-010 (framework de testes) sem a versão do Godot fixada**: a escolha depende dela.
4. **Fazer a REV da Fase 0 (LW-029) com uma segunda IA**, como prevê o roadmap: a leitura deste relatório foi feita por um só autor mais um revisor técnico.
5. **Reavaliar os 192 números do roadmap só depois do spike SP1.** Os tamanhos de tarefa são estimativas.

---

## 6. Viabilidade técnica para Godot 4.x

**Método:** um agente independente (que não escreveu os documentos) conferiu 36 afirmações técnicas contra a **documentação oficial e o código-fonte do Godot** e contra páginas oficiais das ferramentas citadas. Eu conferi pessoalmente no código-fonte e na documentação baixados os pontos que mudam o desenho (sequência de gravação no Windows, precisão do JSON, algoritmo do gerador aleatório, níveis de aviso). **Nenhum comando foi executado no Godot**, que não estava instalado. **[limitação]**

**Veredito: viável, sem item bloqueante.** A arquitetura (simulação separada da apresentação, dados simples, GDScript tipado, JSON validado) é compatível com o Godot 4.x. Foram achados 11 pontos importantes, **todos já corrigidos nos textos** (marcados "Revisão Godot v0.2"):

| # | Ponto (gravidade: importante) | Onde foi corrigido |
|---|---|---|
| G1 | Em clone novo falta a pasta `.godot/` (fora do Git) e os `class_name` não são reconhecidos: é preciso rodar `godot --headless --path . --import` antes de tudo | TA 21.3; RM LW-004, LW-006, LW-030; AGENTS 4.3; README seção 9 |
| G2 | O esquema de `SimModule` da arquitetura geraria avisos (`UNUSED_PARAMETER`, e `seed` esconde uma função embutida) e quebraria a regra "sem avisos" | TA 4.6 corrigido |
| G3 | Os padrões de aviso do Godot **não** impõem tipagem (`untyped_declaration` vem desligado) | RM LW-006 grava o nível em `project.godot` |
| G4 | O Godot nem sempre sai com código de erro quando um script falha (exportação com script quebrado sai com 0; relatos abertos até a 4.7) | TA 21.3; RM LW-011 e LW-188 (teste de fumaça no executável) |
| G5 | `JSON.stringify` não preserva floats exatamente por padrão (cerca de 14 dígitos) e a leitura converte tudo em decimal de 64 bits: `seed` e `state` do gerador aleatório se corromperiam | TA 18.3; RM LW-014, LW-026 |
| G6 | O Godot 4 mantém a ordem de inserção dos `Dictionary`; o JSON sai ordenado. Módulos que iteram por dicionário divergem após salvar e carregar | TA 18.3; RM LW-026 (teste extra) |
| G7 | **"Renomear sobre o arquivo final é atômico" é falso no Windows**: o Godot apaga o destino antes de mover (conferido em `dir_access_windows.cpp`). `flush()` também não garante gravação física | TA 18.4 (sequência `.tmp` → `.bak` → final com recuperação); RM LW-027 |
| G8 | O gerador aleatório do Godot tem algoritmo "detalhe de implementação" (conferido na documentação): pode mudar entre versões do Godot, invalidando hashes e saves de referência | TA 21.5 e R10; RM LW-014 (semente de cada fluxo por SHA-256) |
| G9 | O algoritmo de hash e de checksum não estava nomeado; `hash()` do Godot tem 32 bits | TA 18.2 e 21.5; RM LW-022 (SHA-256) |
| G10 | Coleções tipadas aninhadas (`Array[Array[int]]`) não existem; `Dictionary[K, V]` tipado exige a 4.4 | TA 4.6; AGENTS 4.2 |
| G11 | A versão do Godot a fixar depende das ferramentas: em 01/11/2026 a estável é a **4.7.2**; GUT 9.7.x declara suporte à 4.7, mas o gdUnit4 estável e o Terrain3D declaram até a 4.5/4.6 | RM Anexo G (linha 1) e LW-010 |

**Pontos menores incorporados:** um `MultiMeshInstance3D` por chunk; LOD automático de malhas só existe na importação (o do terreno é manual); teste de colisão aguarda um quadro de física; funções de leitura com objetos listadas como proibidas (e buscadas pelo `check_architecture`); `assert` some em build de release.

**Apontado pelo revisor e não aplicado:** ele afirmou que a arquitetura diz "Signals exigem Nodes". **Não encontrei essa frase** em nenhum capítulo (17.2 diz apenas que o ouvinte pode quebrar se o objeto for liberado). Nada foi alterado.

**Não verificado por ninguém (precisa de teste real, por isso são tarefas do roadmap):**

- Código de saída do Godot em erro de parse num script de linha de comando; se um autoload é acessível em script `--script` (a LW-020 manda confirmar).
- GUT e gdUnit4 em modo sem janela (as páginas oficiais lidas não dizem); a LW-010 testa.
- Terrain3D na versão 4.7 e estado do HTerrain (spike SP4a).
- Gravação do save em outra thread (`Thread`/`WorkerThreadPool`) e modos de compressão (spike SP5).
- **O orçamento de cerca de 3 ms por tick para centenas ou milhares de NPCs em GDScript.** É hipótese razoável (benchmarks de terceiros indicam cerca de 100 a 165 milhões de operações simples por segundo), mas **só o spike SP1 responde**.
- Determinismo entre computadores e sistemas diferentes (a arquitetura já o exclui como objetivo).
- Fase 1 em diante: câmera de terceira pessoa (`SpringArm3D`), personagem e mapa de entradas não foram conferidos.


---

## 7. O que este relatório não cobre

- Qualidade artística, ritmo de jogo e divertimento: só se verificam jogando (VAL de cada fase).
- Custos de ferramentas de terceiros: não há nenhum previsto; qualquer serviço pago exige autorização (AGENTS regra 5).
- Aspectos jurídicos de licença do jogo: licença ainda não definida (README).

*Fim do relatório — versão 0.2.*
