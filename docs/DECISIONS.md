# LIVING WORLD — REGISTRO OFICIAL DE DECISÕES (DECISIONS.md)

**Versão do documento:** 0.4 (09/11/2026; entradas DEC-113 a DEC-123 e totais recontados; a 0.3 é de 01/11/2026; ver seção 8)
**Data de criação:** 01/11/2026 (horário de Brasília)
**Responsável pela decisão:** Arthur (dono do produto). **Somente ele aprova.**
**Função deste documento:** ser a **fonte oficial** do que está decidido, proposto, pendente, descartado ou substituído nos projetos de design e de tecnologia do Living World, para evitar contradições futuras entre o Briefing, o GDD, a arquitetura, o roadmap e o trabalho dos agentes de IA.

---

## 0. COMO LER E USAR ESTE DOCUMENTO

### 0.1 Fontes

| Sigla | Documento | Versão |
|---|---|---|
| **BM** | BRIEFING MESTRE — PROJETO LIVING WORLD (texto original de Arthur; cópia fiel em `docs/BRIEFING_MESTRE.md`) | Sem data nem versão registradas; recebido em 01/11/2026 |
| **PA** | Prompts de Arthur de 01/11/2026 (pedidos do GDD, da arquitetura, do roadmap e deste registro) e a **mensagem de 15:32 (Brasília) com 15 diretrizes**, citada como "diretriz N" | 01/11/2026 |
| **GDD** | `GDD.md` | 0.3 (as entradas citam a versão 0.1; os números de capítulo não mudaram) |
| **TA** | `TECHNICAL_ARCHITECTURE.md` | 0.3 (idem) |
| **RM** | `DEVELOPMENT_ROADMAP.md` | 0.3 (idem) |

### 0.2 Status (significado exato)

| Status | Significado | Quem pode atribuir |
|---|---|---|
| **APROVADA** | Decisão de Arthur, escrita por ele no Briefing ou em prompt dele. **Obriga** todos os documentos e agentes. | Somente Arthur |
| **PROPOSTA** | Recomendação ou hipótese de um documento ou de um agente (GDD, TA, RM). **Não obriga.** Pode ser seguida como padrão de trabalho, mas pode ser trocada sem aviso formal. | Qualquer autor, rotulando como proposta |
| **PENDENTE** | Questão aberta. Nenhuma decisão tomada. Pode haver recomendação, que **não** é decisão. | Qualquer autor |
| **DESCARTADA** | Opção avaliada e recusada. Não deve ser reintroduzida sem nova decisão. | Arthur; quando a recusa veio de uma proposta de documento, isso fica dito na entrada |
| **SUBSTITUÍDA** | Decisão ou proposta trocada por outra. Mantida para histórico, indicando a substituta. | Arthur |

**Status com ressalva entre parênteses** (por exemplo, "APROVADA (somente o princípio)") vale **só para o que está entre parênteses**; o restante da entrada segue o que ela disser (PROPOSTA ou PENDENTE).

### 0.3 Regras de autoridade

1. **Só vale como APROVADA o que Arthur escreveu.** Texto de GDD, TA, RM ou de agente que use "confirmado", "[CONF]" ou "decidido" **só** vale como aprovado se a entrada correspondente aqui disser APROVADA e citar a fonte de Arthur.
2. **Em caso de conflito**, vale: (1) este documento, no que diz respeito a **status**; (2) o BM e os prompts de Arthur, no que diz respeito a **conteúdo aprovado**; (3) GDD e TA, no que diz respeito a **detalhes de design e de técnica**; (4) RM, no que diz respeito a **sequência de trabalho**.
3. **Nenhuma sugestão vira APROVADA por não ter sido contestada.** Silêncio não é aprovação.
4. **Agentes (Codex, ChatGPT, Claude ou outro) podem propor, nunca aprovar.** Se uma tarefa depender de item PENDENTE, o agente para e pergunta, mostrando a recomendação.
5. **Mudar uma decisão APROVADA** exige texto novo de Arthur. A entrada antiga recebe SUBSTITUÍDA, com link para a nova. **Nunca se apaga nem se reescreve** uma decisão antiga.
6. **Decisão técnica detalhada** (por exemplo, resultado de um spike) fica em `docs/decisions/NNNN-titulo.md` (RM, tarefa LW-009). Este documento guarda o **resumo, o status e o link**.
7. **Antes de cada tarefa do roadmap**, o agente confere se as decisões citadas na tarefa estão APROVADAS. Tarefas que dependem de PENDENTE aparecem como decisão do usuário no relatório.

### 0.4 Formato de cada entrada

Cada entrada tem: **Identificador** (`DEC-NNN`, sequencial, nunca reutilizado), **Título**, **Status**, **Contexto**, **Decisão**, **Justificativa**, **Consequências**, **Data / versão** (com a fonte) e **Relações** (outras entradas). Nas entradas PENDENTE, "Decisão" diz que nada foi decidido e a **recomendação** (se existir) aparece em "Justificativa". Nas entradas PROPOSTA, a justificativa é a do autor da proposta.

### 0.5 Observações gerais sobre datas

- A **data original** em que Arthur tomou cada decisão do BM **não está registrada**. Por isso, as entradas citam "BM (sem data) · registrada em 01/11/2026".
- "Registrada em 01/11/2026" significa **data de entrada neste documento**, não data da decisão.

---

## 1. ÍNDICE POR ÁREA E STATUS

**Totais atualizados em 09/11/2026 (LW-071b, recontados a partir das linhas das tabelas abaixo, pelo mesmo método da LW-033A):** APROVADA: 62 (19 com ressalva) · PROPOSTA: 32 · PENDENTE: 18 · DESCARTADA: 10 · SUBSTITUÍDA: 1 · **Total: 123**. As 5 aprovadas a mais desde a LW-033A são a DEC-119, a DEC-120, a DEC-121, a DEC-122 e a DEC-123; as 3 ressalvas a mais são a DEC-121, a DEC-122 e a DEC-123. **Totais de 05/11/2026 (LW-033A, recontados a partir das linhas das tabelas abaixo):** APROVADA: 57 (16 com ressalva) · PROPOSTA: 32 · PENDENTE: 18 · DESCARTADA: 10 · SUBSTITUÍDA: 1 · **Total: 118**. Antes da LW-033A as tabelas somavam 52 (15 com ressalva) · 32 · 19 · 10 · 1 = 114; a linha de totais anterior (48 · 34 · 19 · 10 · 1 = 112) já estava defasada em relação às tabelas. Na v0.3 inicial eram 47 · 34 · 20 · 10 · 1.

| Status | Significado em uma linha |
|---|---|
| APROVADA | Obriga. Decisão de Arthur com fonte. |
| PROPOSTA | Não obriga. Padrão de trabalho. |
| PENDENTE | Aberta. Pare e pergunte. |
| DESCARTADA | Recusada (ver ressalva da Área 11). |
| SUBSTITUÍDA | Histórico. Ver a entrada que a substitui. |


**ÁREA 1 — VISÃO, IDENTIDADE E PRINCÍPIOS**

| ID | Título | Status |
|---|---|---|
| DEC-001 | Gênero e visão do projeto | APROVADA |
| DEC-002 | Mundo independente do jogador | APROVADA |
| DEC-003 | Sem campanha linear, sem herói escolhido e sem classes rígidas | APROVADA |
| DEC-004 | Os oito pilares do mundo | APROVADA |
| DEC-005 | Princípio fundamental e portão das seis perguntas | APROVADA |
| DEC-006 | Diretrizes de design: o que evitar e o que buscar | APROVADA |
| DEC-007 | Equilíbrio entre simulação profunda e jogabilidade divertida | APROVADA |
| DEC-008 | Visão de longo prazo do jogador e do mundo | APROVADA (como direção) |
| DEC-009 | Universo original: fantasia, história, política e culturas realistas | APROVADA |
| DEC-010 | Nome comercial do jogo | PENDENTE |

**ÁREA 2 — PLATAFORMA E TECNOLOGIA-BASE**

| ID | Título | Status |
|---|---|---|
| DEC-011 | Godot 4.x como engine | APROVADA |
| DEC-012 | Versão exata do Godot 4.x a fixar | APROVADA (4.7.x; condicionada) |
| DEC-013 | GDScript tipado como linguagem | APROVADA |
| DEC-014 | PC como plataforma inicial | APROVADA |
| DEC-015 | Sistemas operacionais-alvo do PC | APROVADA (macOS) |
| DEC-016 | Hardware-alvo mínimo | APROVADA (somente a referência) |
| DEC-017 | Single-player como experiência inicial | APROVADA |
| DEC-018 | Possibilidade de multiplayer futuro, sem obrigação no protótipo | APROVADA |
| DEC-019 | Preparo arquitetural barato para multiplayer e modelo candidato | PROPOSTA |
| DEC-020 | Estilo visual stylized low-poly | APROVADA |
| DEC-021 | Fonte de arte, modelos, animações e áudio | PENDENTE |
| DEC-022 | Idioma do código e dos comentários | APROVADA |
| DEC-023 | Telemetria | PENDENTE |
| DEC-024 | Suporte a gamepad | PENDENTE |
| DEC-120 | Direção visual: simples, com a sensação de Albion Online e RuneScape | APROVADA |

**ÁREA 3 — CÂMERA E CONTROLE**

| ID | Título | Status |
|---|---|---|
| DEC-025 | Câmera: terceira pessoa combinada com visão tática e estratégica | APROVADA |
| DEC-026 | Transição de câmera seamless | APROVADA |
| DEC-027 | Controle híbrido entre personagem e visão estratégica (princípio) | APROVADA (somente o princípio) |
| DEC-028 | Câmera contínua por parâmetro de escala `t` com três faixas | PROPOSTA |
| DEC-029 | Profundidade do comando nas visões tática e estratégica | PENDENTE |
| DEC-115 | Câmera padrão: terceira pessoa elevada, de altura média | APROVADA |
| DEC-116 | Controle do personagem: movimento por WASD | APROVADA |

**ÁREA 4 — CONTEÚDO DO UNIVERSO (QUESTÕES ABERTAS)**

| ID | Título | Status |
|---|---|---|
| DEC-030 | Magia: existência, forma e quantidade no protótipo | PENDENTE |
| DEC-031 | Nível tecnológico e pólvora | PENDENTE |
| DEC-032 | Espécies e povos não humanos | PENDENTE |
| DEC-033 | Nomes definitivos, lore e cosmologia | PENDENTE |
| DEC-034 | Domesticação de criaturas | PENDENTE |

**ÁREA 5 — NPCs E INTELIGÊNCIA**

| ID | Título | Status |
|---|---|---|
| DEC-035 | Simulação híbrida de NPCs | APROVADA |
| DEC-036 | IA generativa opcional, nunca necessária | APROVADA |
| DEC-037 | O que os NPCs devem possuir | APROVADA |
| DEC-038 | Quatro camadas de NPC (T0 massa, T1 cidadão, T2 notável, T3 líder) | PROPOSTA |
| DEC-039 | Simulação em níveis de detalhe (S0 a S3) | PROPOSTA |
| DEC-040 | Quantidade de NPCs (total, simulados em detalhe e simultâneos) | PENDENTE |
| DEC-041 | T0 / grupos de população fora do protótipo até haver necessidade medida | APROVADA |
| DEC-042 | Decisão do NPC por utilidade, com catálogo de ações em dados | PROPOSTA |
| DEC-043 | Memória episódica limitada, relações e rumores | PROPOSTA |
| DEC-044 | Uso concreto de IA generativa (se houver): modelo, local ou nuvem, custo e privacidade | PENDENTE |
| DEC-122 | Navegação e velocidade dos corpos S0 (resultado do SP2) | APROVADA (por ora) |
| DEC-123 | Relógio contra corpo: direção P3 (resultado do SP2) | APROVADA (somente a direção) |

**ÁREA 6 — SOCIEDADE, ECONOMIA, POLÍTICA E GUERRA**

| ID | Título | Status |
|---|---|---|
| DEC-045 | Organizações agem sem intervenção do jogador | APROVADA |
| DEC-046 | Economia funcional e conectada | APROVADA |
| DEC-047 | Dinheiro e quantidades em números inteiros, com livro-razão (`Ledger`) | PROPOSTA |
| DEC-048 | Comércio simulado em duas escalas (detalhada e agregada) | PROPOSTA |
| DEC-049 | `TradeRules` como único ponto em que a política altera a economia | PROPOSTA |
| DEC-050 | Composição de facções e polities do protótipo (3 facções; 2 polities, uma simplificada) | APROVADA (composição inicial) |
| DEC-051 | Polity vizinha de baixa resolução (em vez de quarta facção completa) | APROVADA |
| DEC-052 | Escala de conflitos: incidente, escaramuça, batalha, cerco e guerra | PROPOSTA |
| DEC-053 | Escala das batalhas no protótipo (limite de combatentes e modo de resolução) | PENDENTE |
| DEC-054 | Itens fora do protótipo (cercos, exércitos grandes, intriga, sucessão, magia ampla, domesticação, famílias,… | PROPOSTA |

**ÁREA 7 — MUNDO FÍSICO E ESPACIAL**

| ID | Título | Status |
|---|---|---|
| DEC-055 | Dimensões do mundo (tamanho físico, número de regiões e províncias) | PENDENTE |
| DEC-056 | Mundo lógico separado do mundo visual, com hierarquia espacial | PROPOSTA |
| DEC-057 | Terreno: solução própria ou addon | APROVADA |
| DEC-058 | Terreno em chunks com níveis de detalhe | PROPOSTA |
| DEC-059 | Tempo do mundo: dia e noite, relógio da simulação | PROPOSTA |
| DEC-060 | Clima e estações fora do protótipo | PROPOSTA |
| DEC-061 | Mundo autoral de uma região; sem geração procedural no protótipo | PROPOSTA |
| DEC-118 | Terreno de teste do protótipo (Fase 1) | APROVADA |

**ÁREA 8 — JOGADOR, PROGRESSÃO, COMBATE E EVENTOS**

| ID | Título | Status |
|---|---|---|
| DEC-062 | Trajetórias jogáveis no protótipo | APROVADA (somente a meta de três) |
| DEC-063 | Origens do personagem (3 a 4 no protótipo) | PROPOSTA |
| DEC-064 | Progressão por quatro eixos, sem nível global | PROPOSTA |
| DEC-065 | Morte, ferimentos e derrota do jogador | PENDENTE |
| DEC-066 | Sistema definitivo de combate | PENDENTE |
| DEC-067 | Combate do protótipo: corpo a corpo, arco, furtividade básica, ferimentos e durabilidade | PROPOSTA |
| DEC-068 | Criaturas: 3 a 4 tipos e 1 chefe no protótipo | PROPOSTA |
| DEC-069 | Diretor de eventos (sistema que provoca acontecimentos para dar ritmo) | PENDENTE |
| DEC-070 | Eventos dinâmicos: 8 a 12 tipos, na Fase 5 | PROPOSTA |
| DEC-117 | Direção do combate: por alvo e habilidades | APROVADA (somente a direção; o sistema definitivo segue PENDENTE na DEC-066) |
| DEC-121 | Combate por alvo e habilidades: resultado do SP6 (ponto de partida) | APROVADA (somente como ponto de partida) |

**ÁREA 9 — ARQUITETURA TÉCNICA**

| ID | Título | Status |
|---|---|---|
| DEC-071 | Orçamentos de desempenho e metas de quadros | PROPOSTA |
| DEC-072 | Arquitetura modular e expansível | APROVADA |
| DEC-073 | Simplicidade: não adotar padrões complexos apenas por parecerem profissionais | APROVADA |
| DEC-074 | Simulação separada da apresentação, com ponte de intenções e resultados | PROPOSTA |
| DEC-075 | `World` e `SimulationHost`; no máximo quatro autoloads | PROPOSTA |
| DEC-076 | Entidades como identificadores inteiros nunca reutilizados, com dados por composição | PROPOSTA |
| DEC-077 | Comunicação em três canais, com `EventBus` próprio e causa registrada | PROPOSTA |
| DEC-078 | Passo fixo de simulação de 1 minuto simulado, com orçamento de milissegundos | PROPOSTA |
| DEC-079 | Gerador de aleatoriedade único, com semente salva | PROPOSTA |
| DEC-080 | Spikes: protótipos técnicos descartáveis para validar o que é arriscado (SP1 a SP8) | APROVADA (somente a antecipação de SP6 e SP4a) |
| DEC-081 | Determinismo da simulação no mesmo ambiente (sem replay universal) | APROVADA |
| DEC-082 | Definições do jogo em arquivos de dados validados | APROVADA (somente JSON validado; formato interno dos arquivos segue PROPOSTA) |
| DEC-083 | Modelo de persistência (o que se salva, formato, slots, autosave e regras de falha) | APROVADA (somente os princípios) |
| DEC-084 | Proposta técnica de salvamento: JSON comprimido, escrita atômica, versão e migrações | APROVADA (como formato de save do protótipo, com reavaliação do binário se o estado real passar de ~1 MB e a escrita em thread não bastar) |
| DEC-085 | Modelo de multiplayer (se vier a existir) | PENDENTE |
| DEC-086 | Framework de testes automatizados | APROVADA (GUT 9.7.1) |
| DEC-087 | Verificação única (`check_all`), `AGENTS.md` e contratos por módulo | PROPOSTA |
| DEC-088 | Controle de versão com Git e cópia remota | PROPOSTA |
| DEC-089 | Hospedagem do repositório Git | APROVADA (somente o serviço) |
| DEC-113 | Régua de pico do SP1 (LW-023): release decide, por taxa e com laço de controle | APROVADA (somente como régua de medição da LW-023; redação na arquitetura segue PROPOSTA) |
| DEC-114 | Visibilidade do repositório | APROVADA (reversível) |
| DEC-119 | Meta de quadros do protótipo | APROVADA |

**ÁREA 10 — PROCESSO, ESCOPO E MÉTODO DE TRABALHO**

| ID | Título | Status |
|---|---|---|
| DEC-090 | Desenvolvimento incremental | APROVADA |
| DEC-091 | Protótipo antes da expansão | APROVADA |
| DEC-092 | Desenvolvimento por uma pessoa sem experiência de programação, com agentes de IA | APROVADA |
| DEC-093 | Papéis dos agentes: Codex implementa; ChatGPT apoia arquitetura, planejamento e auditoria | APROVADA |
| DEC-094 | Roadmap em seis fases (0 a 5), tarefas pequenas numeradas e pontos de revisão e validação | APROVADA |
| DEC-095 | Sem prazos artificiais | APROVADA |
| DEC-096 | Não antecipar funcionalidades futuras sem necessidade | APROVADA |
| DEC-097 | Disciplina de rótulos: não inventar decisões e distinguir confirmado, proposto, hipótese, pendente e limitação | APROVADA |
| DEC-098 | Objetivo e conteúdo do protótipo (quatro hipóteses e quadro de conteúdo) | PROPOSTA |
| DEC-099 | Lista de corte (ordem de sacrifício) e sistemas que não se cortam | PROPOSTA |
| DEC-100 | Não inventar nomes definitivos sem necessidade; propostas criativas rotuladas | APROVADA |
| DEC-101 | Separação do escopo em visão de longo prazo, sistemas previstos, primeiro protótipo e funcionalidades futuras | APROVADA |

**ÁREA 11 — ALTERNATIVAS DESCARTADAS**

| ID | Título | Status |
|---|---|---|
| DEC-102 | Descartada: framework de ECS (entidade-componente-sistema) de terceiros | DESCARTADA |
| DEC-103 | Descartada: contêiner de injeção de dependência | DESCARTADA |
| DEC-104 | Descartada: camadas de abstração "por precaução" (repositórios, fábricas, interfaces para tudo) | DESCARTADA |
| DEC-105 | Descartada: *event sourcing* completo | DESCARTADA |
| DEC-106 | Descartada: microsserviços, rede interna e banco de dados externo | DESCARTADA |
| DEC-107 | Descartada: reflexão e meta-programação | DESCARTADA |
| DEC-108 | Descartada: herança profunda de classes | DESCARTADA |
| DEC-109 | Descartada: autoload para tudo | DESCARTADA |
| DEC-110 | Descartada: *threads* espalhadas pelo projeto | DESCARTADA |
| DEC-111 | Descartada por ora: GDExtension (C++/Rust) | DESCARTADA |

**ÁREA 12 — DECISÕES SUBSTITUÍDAS**

| ID | Título | Status |
|---|---|---|
| DEC-112 | Substituída: ordem dos marcos do GDD (economia, depois sociedade, depois mundo físico) | SUBSTITUÍDA |

---

## 2. REGISTRO DAS DECISÕES

---

# ÁREA 1 — VISÃO, IDENTIDADE E PRINCÍPIOS

### DEC-001 — Gênero e visão do projeto

| Campo | Conteúdo |
|---|---|
| **Status** | APROVADA |
| **Contexto** | O BM define o conceito-base do projeto. |
| **Decisão** | Living World é um RPG sandbox 3D de fantasia, com simulação dinâmica de sociedade, economia, política, organizações, conflitos militares e exploração. |
| **Justificativa** | Conceito original de Arthur; ponto de partida de todos os documentos. |
| **Consequências** | Todo sistema deve servir a essa visão. Sistemas isolados, que não se comunicam com os demais, contrariam DEC-004 e DEC-006. |
| **Data / versão** | BM §1 (sem data) · GDD 0.1 cap. 1 · registrada em 01/11/2026 |
| **Relações** | DEC-002, DEC-004, DEC-010 |

### DEC-002 — Mundo independente do jogador

| Campo | Conteúdo |
|---|---|
| **Status** | APROVADA |
| **Contexto** | O BM pede um mundo que funcione como ecossistema, e não como cenário para o jogador. |
| **Decisão** | O mundo é um ecossistema independente do jogador e **continua evoluindo mesmo quando o jogador não interfere**. O jogador é parte do mundo, não o centro obrigatório dele. |
| **Justificativa** | Princípio central do BM (§1 e §10). |
| **Consequências** | A simulação não pode depender de ações do jogador. Cada mecânica relevante responde ao portão de DEC-005. Os testes de longa duração sem jogador (*soak*) são proposta do GDD (24.1, hipótese 1) e do RM, e não parte desta decisão. |
| **Data / versão** | BM §1 e §10 (sem data) · registrada em 01/11/2026 |
| **Relações** | DEC-005, DEC-045, DEC-098 |

### DEC-003 — Sem campanha linear, sem herói escolhido e sem classes rígidas

| Campo | Conteúdo |
|---|---|
| **Status** | APROVADA |
| **Contexto** | O BM descreve o jogador como indivíduo que nasce em um mundo já existente. |
| **Decisão** | O jogador **não é necessariamente um escolhido ou herói**. Não há campanha linear nem classes rígidas. O jogador constrói a trajetória, combinando atividades e mudando de objetivos ao longo do jogo. |
| **Justificativa** | Liberdade como pilar (DEC-004) e mundo independente (DEC-002). |
| **Consequências** | Narrativa emergente. Progressão sem classes. As trajetórias não são mutuamente exclusivas. Quais trajetórias existirão **no protótipo** não está decidido (DEC-062). |
| **Data / versão** | BM §1 e §4 (sem data) · GDD 0.1 cap. 1 · registrada em 01/11/2026 |
| **Relações** | DEC-004, DEC-008, DEC-062 |

### DEC-004 — Os oito pilares do mundo

| Campo | Conteúdo |
|---|---|
| **Status** | APROVADA |
| **Contexto** | O BM lista os pilares que sustentam o design. |
| **Decisão** | São pilares: **Mundo vivo, Liberdade, Sociedade, Economia, Política, Guerra, Consequências e Exploração**, com os significados descritos no BM §3. |
| **Justificativa** | Escolha de Arthur. |
| **Consequências** | Todo sistema deve apoiar pelo menos um pilar. Os **critérios de verificação** de cada pilar escritos no GDD cap. 3 são **proposta do GDD**, e não parte desta decisão. |
| **Data / versão** | BM §3 (sem data) · GDD 0.1 cap. 3 · registrada em 01/11/2026 |
| **Relações** | DEC-005, DEC-006 |

### DEC-005 — Princípio fundamental e portão das seis perguntas

| Campo | Conteúdo |
|---|---|
| **Status** | APROVADA |
| **Contexto** | O BM fixa um teste que toda mecânica relevante deve passar. |
| **Decisão** | O mundo não existe somente para servir ao jogador. Toda mecânica relevante responde: (1) o que acontece quando o jogador participa; (2) o que acontece quando não participa; (3) como NPCs e organizações reagem; (4) quais sistemas são afetados; (5) quais consequências podem surgir; (6) como o mundo registra e mantém essas consequências. |
| **Justificativa** | Garante coerência entre sistemas e independência do mundo. |
| **Consequências** | Nenhuma mecânica relevante entra no design sem responder às seis perguntas. A validação final do protótipo (RM, LW-191) usa essas perguntas. |
| **Data / versão** | BM §10 (sem data) · GDD 0.1 cap. 3.2 · registrada em 01/11/2026 |
| **Relações** | DEC-002, DEC-004 |

### DEC-006 — Diretrizes de design: o que evitar e o que buscar

| Campo | Conteúdo |
|---|---|
| **Status** | APROVADA |
| **Contexto** | O BM define limites de qualidade para o design. |
| **Decisão** | **Evitar:** progressão artificial; *grind* excessivo; repetição sem propósito; NPCs decorativos; sistemas que não se comunicam; economia meramente cosmética; liberdade prometida mas limitada por trilhos; complexidade que prejudique a jogabilidade; sistemas caros ou inviáveis para um desenvolvedor solo assistido por IA. **Buscar:** sistemas conectados; consequências emergentes; jogabilidade intuitiva; profundidade progressiva; modularidade; escalabilidade; eficiência computacional; possibilidade de expansão. |
| **Justificativa** | Escolha de Arthur. |
| **Consequências** | Serve de critério de revisão para GDD, arquitetura e tarefas. Uma ideia que viole a lista "evitar" precisa de decisão explícita de Arthur. |
| **Data / versão** | BM §9 (sem data) · registrada em 01/11/2026 |
| **Relações** | DEC-004, DEC-007 |

### DEC-007 — Equilíbrio entre simulação profunda e jogabilidade divertida

| Campo | Conteúdo |
|---|---|
| **Status** | APROVADA |
| **Contexto** | O BM lista a "filosofia" do projeto entre as características confirmadas. |
| **Decisão** | A filosofia do projeto é o **equilíbrio entre simulação profunda e jogabilidade divertida**. |
| **Justificativa** | Escolha de Arthur. |
| **Consequências** | Nem simulação sem diversão, nem diversão sem simulação. As **regras de precedência** do GDD 3.3 (por exemplo, "jogabilidade vence fidelidade de simulação, a menos que quebre a causalidade") são **proposta do GDD**, não decisão. |
| **Data / versão** | BM §2 (sem data) · GDD 0.1 cap. 3 e 22 · registrada em 01/11/2026 |
| **Relações** | DEC-006 |

### DEC-008 — Visão de longo prazo do jogador e do mundo

| Campo | Conteúdo |
|---|---|
| **Status** | APROVADA (como **direção**, não como requisito) |
| **Contexto** | O BM descreve, sem fixar escopo, o que o jogador e o mundo poderão ter: trajetórias (§4), sociedades e organizações (§5), economia funcional (§6), NPCs (§7), combate e aventura (§8). |
| **Decisão** | Essas descrições são a **visão de longo prazo**. Servem de direção de design. O BM usa "poderá" e "poderá incluir" em §4, §5 e §8: são **possibilidades**, e não obrigações. A domesticação de criaturas está condicionada a "caso seja viável no design". |
| **Justificativa** | Orientar o design sem inflar o protótipo. |
| **Consequências** | Nenhum item da visão é requisito do protótipo apenas por constar no BM (ver DEC-096 e DEC-101, ambas de Arthur). O que entra no protótipo é proposta (DEC-098) e o que fica de fora também (DEC-054). |
| **Data / versão** | BM §4 a §8 (sem data) · registrada em 01/11/2026 |
| **Relações** | DEC-003, DEC-054, DEC-096, DEC-098, DEC-101 |

### DEC-009 — Universo original: fantasia, história, política e culturas realistas

| Campo | Conteúdo |
|---|---|
| **Status** | APROVADA |
| **Contexto** | O BM define a natureza do universo. |
| **Decisão** | O universo é **original**, misturando **fantasia, história, política e culturas realistas**. |
| **Justificativa** | Escolha de Arthur. |
| **Consequências** | Não se usa universo licenciado nem existente. Ficam **abertos**: nível tecnológico (DEC-031), espécies não humanas (DEC-032) e nomes, lore e cosmologia (DEC-033). |
| **Data / versão** | BM §2 (sem data) · GDD 0.1 cap. 1 e 4 · registrada em 01/11/2026 |
| **Relações** | DEC-031, DEC-032, DEC-033, DEC-061 |

### DEC-010 — Nome comercial do jogo

| Campo | Conteúdo |
|---|---|
| **Status** | PENDENTE |
| **Contexto** | "Living World" é o **título de trabalho** (assim o GDD o declara). |
| **Decisão** | **Nada decidido.** Até haver decisão, usar "Living World" apenas como título de trabalho. |
| **Justificativa** | Recomendação (não aprovada): decidir somente depois da validação do protótipo, para não prender o projeto a um nome. |
| **Consequências** | Nome comercial, identidade visual e eventuais registros ficam fora do roadmap técnico. |
| **Data / versão** | GDD 0.1 (cabeçalho) · registrada em 01/11/2026 |
| **Relações** | DEC-001 |

---

# ÁREA 2 — PLATAFORMA E TECNOLOGIA-BASE

### DEC-011 — Godot 4.x como engine

| Campo | Conteúdo |
|---|---|
| **Status** | APROVADA |
| **Contexto** | O BM diz "Engine **inicialmente** escolhida: Godot 4.x". O prompt da arquitetura repete "Tecnologia inicialmente escolhida: Godot 4.x". |
| **Decisão** | O projeto usa **Godot 4.x**. |
| **Justificativa** | Escolha de Arthur. |
| **Consequências** | Toda a arquitetura e o roadmap assumem Godot 4.x. A palavra "inicialmente" indica que trocar de engine é possível, mas **só por nova decisão de Arthur** (a entrada atual então ficaria SUBSTITUÍDA). A **versão exata** a fixar está em DEC-012. |
| **Data / versão** | BM §2 (sem data) · PA 01/11/2026 (arquitetura) · registrada em 01/11/2026 |
| **Relações** | DEC-012, DEC-013 |

### DEC-012 — Versão exata do Godot 4.x a fixar

| Campo | Conteúdo |
|---|---|
| **Status** | APROVADA (condicionada à verificação técnica de compatibilidade) |
| **Contexto** | "4.x" cobre várias versões. Atualizar no meio do projeto pode quebrar código e testes. |
| **Decisão** | **Godot 4.7.x estável** (versão padrão com GDScript, sem .NET, 64 bits), condicionado à verificação técnica de compatibilidade. Havendo impedimento concreto, usar uma **4.6.x estável** compatível. A versão exata (4.7.n) é registrada pelo Codex na LW-006, em `docs/decisions/0001-ambiente-de-referencia.md`, e fica fixada até o fim do protótipo. |
| **Justificativa** | Diretriz 3 de Arthur. Apoio (pesquisa de 01/11/2026, a reconfirmar na LW-010): o GUT 9.7.x declara suporte à 4.7; o gdUnit4 estável consultado cobre 4.5 e 4.6. |
| **Consequências** | Desbloqueia a instalação (LW-002) e a LW-006. Impedimento concreto exige evidência (mensagem de erro ou documentação) no relatório; a troca para 4.6.x se registra em `docs/decisions/` sem nova decisão. Atualizar a versão no meio do protótipo continua exigindo nova decisão. |
| **Data / versão** | TA 0.1 cap. 26.4 · RM 0.1 LW-001 · registrada em 01/11/2026 · mensagem de Arthur de 01/11/2026 15:32 (diretriz 3) |
| **Relações** | DEC-011 |

### DEC-013 — GDScript tipado como linguagem

| Campo | Conteúdo |
|---|---|
| **Status** | APROVADA |
| **Contexto** | O BM fixa a linguagem. |
| **Decisão** | A linguagem é **GDScript tipado**. |
| **Justificativa** | Escolha de Arthur. A TA acrescenta, como justificativa técnica, que a tipagem reduz erros e ajuda agentes de IA. |
| **Consequências** | Variáveis, parâmetros e retornos tipados. Outras linguagens (C#, C++ por GDExtension) só entram por nova decisão. A TA trata GDExtension como último recurso, somente se medições exigirem **[FUT]**. |
| **Data / versão** | BM §2 (sem data) · TA 0.1 cap. 1.4 · registrada em 01/11/2026 |
| **Relações** | DEC-011, DEC-022 |

### DEC-014 — PC como plataforma inicial

| Campo | Conteúdo |
|---|---|
| **Status** | APROVADA |
| **Contexto** | O BM fixa a plataforma inicial. |
| **Decisão** | A plataforma inicial é **PC**. |
| **Justificativa** | Escolha de Arthur. |
| **Consequências** | Teclado e mouse como entrada primária (GDD 21.4). Outras plataformas (consoles, celulares) não fazem parte do escopo atual. Quais sistemas operacionais do PC não está decidido (DEC-015). |
| **Data / versão** | BM §2 (sem data) · registrada em 01/11/2026 |
| **Relações** | DEC-015, DEC-016, DEC-024 |

### DEC-015 — Sistemas operacionais-alvo do PC

| Campo | Conteúdo |
|---|---|
| **Status** | APROVADA |
| **Contexto** | "PC" não diz se o alvo é Windows, Linux, macOS ou mais de um. O roadmap prevê exportar um executável de teste (LW-188). |
| **Decisão** | **macOS** é o sistema de desenvolvimento e de teste inicial. A versão do macOS é registrada pelo Codex na LW-006. Outros sistemas: futuro, sem trabalho agora e sem decisões que os impeçam. |
| **Justificativa** | Diretriz 4 de Arthur. |
| **Consequências** | `tools/run_tests` e `tools/check_all` são escritos para o terminal do macOS e chamam o Godot em modo sem janela; a exportação (LW-188) é para macOS; a escrita de save mantém a sequência tmp, bak, final (custa pouco e protege um futuro Windows). |
| **Data / versão** | Lacuna identificada em 01/11/2026 · RM 0.1 LW-188 · mensagem de Arthur de 01/11/2026 15:32 (diretriz 4) |
| **Relações** | DEC-014, DEC-016 |

### DEC-016 — Hardware-alvo mínimo

| Campo | Conteúdo |
|---|---|
| **Status** | APROVADA (somente o hardware de referência) |
| **Contexto** | Os orçamentos de desempenho (tempo por tick, quadros por segundo, memória) dependem de uma máquina de referência. GDD D7 e TA 20.1 usam "PC intermediário" como referência provisória. |
| **Decisão** | O **hardware de referência** é a máquina macOS de desenvolvimento, **identificada pelo Codex diretamente na máquina** (chip, núcleos, memória, GPU, armazenamento e versão do sistema; sem número de série nem outros identificadores únicos) e registrada em `docs/decisions/0001-ambiente-de-referencia.md` (LW-006). O **hardware mínimo** continua **PENDENTE**; recomendação (não aprovada): não definir agora e publicar como "mínimo testado" depois do teste de carga (LW-179). |
| **Justificativa** | Diretriz 4 de Arthur (referência). A recomendação sobre o mínimo evita prometer o que não foi medido. |
| **Consequências** | Orçamentos de desempenho e spikes medem nessa máquina. Nenhum mínimo vira requisito antes da medição. A pendência do mínimo não bloqueia a primeira implementação. |
| **Data / versão** | GDD 0.1 Anexo D (D7) · TA 0.1 cap. 20.1 e 26.4 · RM 0.1 LW-001 · registrada em 01/11/2026 · mensagem de Arthur de 01/11/2026 15:32 (diretriz 4) |
| **Relações** | DEC-014, DEC-071 |

### DEC-017 — Single-player como experiência inicial

| Campo | Conteúdo |
|---|---|
| **Status** | APROVADA |
| **Contexto** | O BM fixa o modo inicial. |
| **Decisão** | A experiência inicial é **single-player**. |
| **Justificativa** | Escolha de Arthur. |
| **Consequências** | Single-player não exige rede (leitura do GDD 23.1) e o jogo não pode exigir IA generativa (DEC-036). O BM **não** menciona salvamento: a proposta de salvamento completo é do GDD e da TA (DEC-083 e DEC-084). |
| **Data / versão** | BM §2 (sem data) · GDD 0.1 cap. 23.1 · registrada em 01/11/2026 |
| **Relações** | DEC-018, DEC-036, DEC-083 |

### DEC-018 — Possibilidade de multiplayer futuro, sem obrigação no protótipo

| Campo | Conteúdo |
|---|---|
| **Status** | APROVADA |
| **Contexto** | O BM admite multiplayer como possibilidade futura. |
| **Decisão** | **Multiplayer é possibilidade futura**, **sem obrigação** de ser implementado no protótipo. |
| **Justificativa** | Escolha de Arthur. |
| **Consequências** | Nenhum trabalho de rede no protótipo. **Não está decidido** que o multiplayer será feito, nem em qual modelo. As medidas arquiteturais baratas para não fechar essa porta são **proposta** (DEC-019). |
| **Data / versão** | BM §2 (sem data) · GDD 0.1 cap. 23.2 · registrada em 01/11/2026 |
| **Relações** | DEC-017, DEC-019, DEC-085 |

### DEC-019 — Preparo arquitetural barato para multiplayer e modelo candidato

| Campo | Conteúdo |
|---|---|
| **Status** | PROPOSTA |
| **Contexto** | Para o multiplayer ser possível depois, algumas decisões de arquitetura precisam ser tomadas desde já. |
| **Decisão** | Proposta do GDD (23.4) e da TA (23): (1) simulação separada da apresentação; (2) ações do jogador como comandos de dados com identificador do ator; (3) identificadores estáveis de entidades; (4) estado centralizado e serializável; (5) passo de simulação fixo; (6) semente de aleatoriedade controlada; (7) **nenhum código da simulação pode assumir um único jogador**. Modelo candidato **[FUT]**: cooperativo com anfitrião autoritativo. |
| **Justificativa** | Custo quase nulo agora; evita reescrita total depois. |
| **Consequências** | Se aprovada, vira regra de revisão. O **modelo** de multiplayer continua sem decisão. |
| **Data / versão** | GDD 0.1 cap. 23 · TA 0.1 cap. 23 · registrada em 01/11/2026 |
| **Relações** | DEC-018, DEC-074, DEC-076, DEC-079, DEC-085 |

### DEC-020 — Estilo visual stylized low-poly

| Campo | Conteúdo |
|---|---|
| **Status** | APROVADA |
| **Contexto** | O BM fixa o estilo. |
| **Decisão** | O visual é **stylized low-poly**. |
| **Justificativa** | Escolha de Arthur. O GDD e a TA acrescentam que o estilo reduz custo de arte e favorece LOD e *MultiMesh*. |
| **Consequências** | Modelos de poucos polígonos e cores/materiais simples. **Origem dos assets e arte final não estão decididas** (DEC-021). No protótipo, o roadmap usa formas simples provisórias. |
| **Data / versão** | BM §2 (sem data) · registrada em 01/11/2026 |
| **Relações** | DEC-021 |

### DEC-021 — Fonte de arte, modelos, animações e áudio

| Campo | Conteúdo |
|---|---|
| **Status** | PENDENTE |
| **Contexto** | Low-poly estilizado ainda exige modelos, animações e sons. Não foi dito quem os cria nem de onde vêm. |
| **Decisão** | **Nada decidido.** O roadmap usa formas simples e cores planas como provisório. |
| **Justificativa** | Recomendação (não aprovada): decidir só depois da validação final do protótipo. |
| **Consequências** | O protótipo não terá arte final. Licenças de qualquer asset futuro precisam de decisão. |
| **Data / versão** | GDD 0.1 Anexo C (item 12) · RM 0.1 (Anexo E) · registrada em 01/11/2026 |
| **Relações** | DEC-020 |

### DEC-022 — Idioma do código e dos comentários

| Campo | Conteúdo |
|---|---|
| **Status** | APROVADA |
| **Contexto** | Arthur trabalha em português. Agentes de IA costumam render melhor com código em inglês. |
| **Decisão** | **Código e identificadores em inglês** (arquivos, classes, funções, variáveis e IDs de conteúdo em `data/`). **Documentação, relatórios e interface (textos exibidos ao jogador) em português.** Comentários no código: português, explicando o porquê (AGENTS 4.19), conforme a proposta original; Arthur não os tratou separadamente. |
| **Justificativa** | Diretriz 5 de Arthur. Agentes de IA rendem melhor com código em inglês; Arthur audita em português. |
| **Consequências** | O glossário bilíngue do GDD (Anexo E) liga cada termo em português ao seu identificador. Textos da interface por chaves de texto, em português. |
| **Data / versão** | TA 0.1 cap. 2.2 e 26.4 · RM 0.1 LW-001 · registrada em 01/11/2026 · mensagem de Arthur de 01/11/2026 15:32 (diretriz 5) |
| **Relações** | DEC-013 |

### DEC-023 — Telemetria

| Campo | Conteúdo |
|---|---|
| **Status** | PENDENTE |
| **Contexto** | Coletar dados de uso exige consentimento e serviço. |
| **Decisão** | **Nada decidido.** |
| **Justificativa** | Recomendação (TA 26.4, não aprovada): não incluir no protótipo. |
| **Consequências** | Sem telemetria, a validação do protótipo depende de *playtests* manuais. |
| **Data / versão** | TA 0.1 cap. 26.4 · GDD 0.1 cap. 22 · registrada em 01/11/2026 |
| **Relações** | DEC-036 |

### DEC-024 — Suporte a gamepad

| Campo | Conteúdo |
|---|---|
| **Status** | PENDENTE |
| **Contexto** | Teclado e mouse são a entrada primária; gamepad é "possibilidade" no GDD. |
| **Decisão** | **Nada decidido.** (GDD Anexo D, D6) |
| **Justificativa** | Recomendação (GDD, não aprovada): não no protótipo. |
| **Consequências** | O mapeamento de entradas deve usar ações nomeadas (proposta da TA), o que mantém a porta aberta. |
| **Data / versão** | GDD 0.1 cap. 21.4 e Anexo D (D6) · registrada em 01/11/2026 |
| **Relações** | DEC-014 |

---

# ÁREA 3 — CÂMERA E CONTROLE

### DEC-025 — Câmera: terceira pessoa combinada com visão tática e estratégica

| Campo | Conteúdo |
|---|---|
| **Status** | APROVADA |
| **Contexto** | O BM fixa o sistema de câmera. |
| **Decisão** | A câmera combina **terceira pessoa** com **visão tática** e **visão estratégica**. |
| **Justificativa** | Escolha de Arthur: permite viver o mundo em escala humana e entendê-lo em escala de região. |
| **Consequências** | A interface precisa oferecer informação em três escalas. Terreno, LOD e marcadores precisam funcionar em todas (limitação identificada no GDD Anexo C, item 3). |
| **Data / versão** | BM §2 (sem data) · GDD 0.1 cap. 21 · registrada em 01/11/2026 |
| **Relações** | DEC-026, DEC-027, DEC-028 |

### DEC-026 — Transição de câmera seamless

| Campo | Conteúdo |
|---|---|
| **Status** | APROVADA |
| **Contexto** | O BM exige transições fluidas entre escalas. |
| **Decisão** | A transição entre escalas de visualização é **seamless**: fluida, sem cortes bruscos entre modos. |
| **Justificativa** | Escolha de Arthur. |
| **Consequências** | Exige terreno em níveis de detalhe, camadas de mapa sobre o mesmo terreno e mitigação de falhas de profundidade. É um **risco técnico** a validar por protótipo (spike SP4). O **mecanismo** (parâmetro contínuo `t`) é proposta (DEC-028). |
| **Data / versão** | BM §2 (sem data) · GDD 0.1 cap. 21 · registrada em 01/11/2026 |
| **Relações** | DEC-025, DEC-028, DEC-080 |

### DEC-027 — Controle híbrido entre personagem e visão estratégica (princípio)

| Campo | Conteúdo |
|---|---|
| **Status** | APROVADA (somente o **princípio**) |
| **Contexto** | O BM descreve a câmera como "terceira pessoa **combinada com** visão tática e estratégica", e as trajetórias incluem comandante e líder de facção. Arthur pediu o registro especial do "controle híbrido entre personagem e visão estratégica". |
| **Decisão** | O jogador **combina** o controle direto de um personagem em terceira pessoa com uma visão tática e estratégica do mundo. As duas formas de jogar convivem na mesma experiência. |
| **Justificativa** | Escolha de Arthur. |
| **Consequências** | **Não está decidido:** quanto poder de comando o jogador tem nas visões tática e estratégica (apenas consultar e planejar, ou dar ordens). Isso é DEC-029. As faixas de controle por escala do GDD e da TA são proposta (DEC-028). |
| **Data / versão** | BM §2 (sem data) · PA 01/11/2026 (este registro) |
| **Relações** | DEC-025, DEC-028, DEC-029 |

### DEC-028 — Câmera contínua por parâmetro de escala `t` com três faixas

| Campo | Conteúdo |
|---|---|
| **Status** | PROPOSTA |
| **Contexto** | A câmera seamless (DEC-026) precisa de um mecanismo. |
| **Decisão** | Proposta da TA (19.2) e do GDD: uma única câmera controlada por um parâmetro contínuo `t` (0 = terceira pessoa, 1 = estratégica), com curvas editáveis para distância, ângulo, campo de visão, planos de corte, névoa e sombras. Faixas de controle: 0,00–0,25 terceira pessoa; 0,25–0,65 tática local; 0,65–1,00 estratégica regional, com histerese. Os valores numéricos são **hipótese [HIP]**. |
| **Justificativa** | Evita "cortes" entre modos e mantém um único mundo visual. |
| **Consequências** | Validar por spike (RM: SP4a na Fase 1 e SP4 final na Fase 5). Se falhar, o plano B é transição "fatiada" ou addon de terreno. |
| **Data / versão** | TA 0.1 cap. 19.2 · GDD 0.1 cap. 21 · registrada em 01/11/2026 |
| **Relações** | DEC-026, DEC-027, DEC-058, DEC-080 |

### DEC-029 — Profundidade do comando nas visões tática e estratégica

| Campo | Conteúdo |
|---|---|
| **Status** | PENDENTE |
| **Contexto** | O BM prevê trajetórias de comandante e líder de facção, mas o protótipo precisa decidir se o jogador só **consulta e planeja** ou também **dá ordens** nas visões tática e estratégica. |
| **Decisão** | **Nada decidido.** |
| **Justificativa** | Recomendação (GDD 24.5 e RM, não aprovada): no protótipo, mapa estratégico **de consulta**, sem comando tático (item 4 da lista de corte). |
| **Consequências** | Define o tamanho do trabalho de interface e de ordens. Ligada a DEC-053 (escala das batalhas) e a DEC-062 (trajetórias). |
| **Data / versão** | GDD 0.1 cap. 21 e 24.5 · RM 0.1 LW-146 · registrada em 01/11/2026 |
| **Relações** | DEC-027, DEC-053, DEC-062, DEC-099 |

---

# ÁREA 4 — CONTEÚDO DO UNIVERSO (QUESTÕES ABERTAS)

> O BM fixa que o universo é original (DEC-009), mas **não** decide os itens abaixo. Todos permanecem PENDENTES. As recomendações são do GDD (Anexo D) e **não** são decisões.

### DEC-030 — Magia: existência, forma e quantidade no protótipo

| Campo | Conteúdo |
|---|---|
| **Status** | PENDENTE |
| **Contexto** | O BM cita magia como parte da Exploração (§3) e como possibilidade de combate (§8: "poderá incluir"). Não define regras, custo nem se entra no protótipo. |
| **Decisão** | **Nada decidido.** Magia é parte da visão de longo prazo (DEC-008), mas sua forma e o seu lugar no protótipo estão em aberto. (GDD Anexo D, D3) |
| **Justificativa** | Recomendação (GDD, não aprovada): 0 a 2 efeitos simples no protótipo, sendo o primeiro item a ser cortado se o escopo apertar (GDD 24.5, item 1). |
| **Consequências** | Afeta combate (DEC-066), dados e interface. Enquanto pendente, nenhuma tarefa do roadmap implementa magia; a LW-146 pede a decisão formal. |
| **Data / versão** | BM §3 e §8 · GDD 0.1 cap. 16.6 e Anexo D (D3) · RM 0.1 LW-146 · registrada em 01/11/2026 |
| **Relações** | DEC-008, DEC-066, DEC-099 |

### DEC-031 — Nível tecnológico e pólvora

| Campo | Conteúdo |
|---|---|
| **Status** | PENDENTE |
| **Contexto** | O BM define "fantasia, história, política e culturas realistas", sem fixar a tecnologia. A pólvora muda guerra, cerco e economia. |
| **Decisão** | **Nada decidido.** (GDD Anexo D, D9) |
| **Justificativa** | Recomendação (GDD, não aprovada): sem pólvora. |
| **Consequências** | Afeta tipos de armas, unidades, fortificações e cadeias de produção. |
| **Data / versão** | GDD 0.1 Anexo D (D9) · registrada em 01/11/2026 |
| **Relações** | DEC-009, DEC-053 |

### DEC-032 — Espécies e povos não humanos

| Campo | Conteúdo |
|---|---|
| **Status** | PENDENTE |
| **Contexto** | O BM fala em fantasia e culturas realistas, sem dizer se há espécies não humanas jogáveis ou habitantes. Isso multiplica modelos, animações e regras. |
| **Decisão** | **Nada decidido.** (GDD Anexo D, D1; GDD 5.2) |
| **Justificativa** | Recomendação (GDD, não aprovada): apenas humanos no protótipo, com culturas diferenciadas por parâmetros. |
| **Consequências** | Afeta custo de arte, de animação e de dados. Criaturas e monstros (BM §8) são um assunto distinto (DEC-068). |
| **Data / versão** | GDD 0.1 cap. 5.2 e Anexo D (D1) · registrada em 01/11/2026 |
| **Relações** | DEC-009, DEC-068 |

### DEC-033 — Nomes definitivos, lore e cosmologia

| Campo | Conteúdo |
|---|---|
| **Status** | PENDENTE |
| **Contexto** | O GDD e o roadmap usam nomes genéricos e descritivos. Nenhum nome definitivo de mundo, região, povo, facção ou deus foi decidido. |
| **Decisão** | **Nada decidido.** (GDD Anexo D, D10) |
| **Justificativa** | Recomendação (GDD, não aprovada): definir só o mínimo necessário; nomes definitivos depois da validação do protótipo. |
| **Consequências** | Enquanto pendente, nenhum documento, dado ou código pode tratar um nome como definitivo (ver DEC-100). |
| **Data / versão** | GDD 0.1 Anexo D (D10) e cap. 0.5 · registrada em 01/11/2026 |
| **Relações** | DEC-009, DEC-100 |

### DEC-034 — Domesticação de criaturas

| Campo | Conteúdo |
|---|---|
| **Status** | PENDENTE |
| **Contexto** | O BM diz "Domesticação de criaturas, **caso seja viável no design**" (§8). A viabilidade não foi decidida. |
| **Decisão** | **Nada decidido.** (GDD Anexo D, D8) |
| **Justificativa** | Recomendação (GDD, não aprovada): adiar. |
| **Consequências** | Fica fora do protótipo (DEC-054, proposta) e fora do roadmap (RM Anexo E). |
| **Data / versão** | BM §8 · GDD 0.1 Anexo D (D8) · registrada em 01/11/2026 |
| **Relações** | DEC-008, DEC-054, DEC-068 |

---

# ÁREA 5 — NPCs E INTELIGÊNCIA

### DEC-035 — Simulação híbrida de NPCs

| Campo | Conteúdo |
|---|---|
| **Status** | APROVADA |
| **Contexto** | O BM fixa a arquitetura de IA dos NPCs. |
| **Decisão** | A IA dos NPCs é **híbrida**, combinando **simulação tradicional, sistemas comportamentais, memória e possibilidade de IA generativa opcional**. **Simulação determinística e sistemas comportamentais são a base.** |
| **Justificativa** | Escolha de Arthur. O GDD e a TA acrescentam: determinismo permite testar, reproduzir e depurar; custo previsível; funciona offline. |
| **Consequências** | O jogo inteiro funciona sem IA generativa (DEC-036). "Determinística" nesta decisão **não** obriga replay bit a bit dos saves; isso é uma pendência separada (DEC-081). Os mecanismos concretos (utilidade, camadas, memória) são propostas (DEC-038 a DEC-043). |
| **Data / versão** | BM §2 e §7 (sem data) · GDD 0.1 cap. 8 e 9 · TA 0.1 cap. 8 · registrada em 01/11/2026 |
| **Relações** | DEC-036, DEC-037, DEC-081 |

### DEC-036 — IA generativa opcional, nunca necessária

| Campo | Conteúdo |
|---|---|
| **Status** | APROVADA |
| **Contexto** | O BM admite IA generativa como possibilidade, com limites claros. |
| **Decisão** | A IA generativa é **opcional**, usada **somente quando agregar valor** e **sem ser necessária para o funcionamento do jogo**. |
| **Justificativa** | Escolha de Arthur. Evita dependência de serviço externo, custo recorrente e perda de reprodutibilidade. |
| **Consequências** | O protótipo **não** usa IA generativa (GDD 24.3 e RM 0.14, ambos propostas coerentes com esta decisão). Nenhum sistema essencial pode exigir chamada a modelo generativo. Se um dia houver, ela fica atrás de uma interface isolada e desligável (proposta da TA cap. 24). Quando, onde e com qual tecnologia está em DEC-044 (pendente). |
| **Data / versão** | BM §2 e §7 (sem data) · GDD 0.1 cap. 8.8 · TA 0.1 cap. 24 · registrada em 01/11/2026 |
| **Relações** | DEC-017, DEC-035, DEC-044 |

### DEC-037 — O que os NPCs devem possuir

| Campo | Conteúdo |
|---|---|
| **Status** | APROVADA |
| **Contexto** | O BM recusa NPCs decorativos ("simples personagens parados esperando o jogador"). |
| **Decisão** | Os NPCs devem ter **diferentes níveis de complexidade**, com: necessidades, ocupações, rotinas, relações, objetivos, personalidades, memória, recursos, decisões e reações aos acontecimentos. |
| **Justificativa** | Escolha de Arthur (pilar Sociedade e lista "evitar" do BM). |
| **Consequências** | "Diferentes níveis de complexidade" autoriza camadas (DEC-038), mas **não** fixa quantas nem quais. Todo NPC que existe como indivíduo precisa dos elementos aplicáveis ao seu nível. |
| **Data / versão** | BM §3, §7 e §9 (sem data) · registrada em 01/11/2026 |
| **Relações** | DEC-004, DEC-006, DEC-038 |

### DEC-038 — Quatro camadas de NPC (T0 massa, T1 cidadão, T2 notável, T3 líder)

| Campo | Conteúdo |
|---|---|
| **Status** | PROPOSTA |
| **Contexto** | Simular todos os NPCs em detalhe máximo é inviável (GDD marca como limitação). O BM pede "diferentes níveis de complexidade" (DEC-037). |
| **Decisão** | Proposta do GDD (8.2) e da TA (8.2): T0 massa (agregado), T1 cidadão (indivíduo simples), T2 notável (completo), T3 líder (completo + planos), com promoção e rebaixamento entre camadas. |
| **Justificativa** | Limita o custo mantendo detalhe onde importa. |
| **Consequências** | Se aprovada, os dados e módulos de NPC seguem as camadas. O roadmap já a adota **parcialmente** (T0 fora, DEC-041). |
| **Data / versão** | GDD 0.1 cap. 8.2 · TA 0.1 cap. 8.2 · registrada em 01/11/2026 |
| **Relações** | DEC-037, DEC-039, DEC-040, DEC-041 |

### DEC-039 — Simulação em níveis de detalhe (S0 a S3)

| Campo | Conteúdo |
|---|---|
| **Status** | PROPOSTA |
| **Contexto** | O mundo precisa continuar vivo fora da vista do jogador sem custo máximo. |
| **Decisão** | Proposta do GDD (4.5) e da TA (5.3): S0 (em torno do jogador, agentes individuais), S1 (assentamentos e rotas, rotina simplificada), S2 (resto da região, agregado), S3 (fora da região, abstrato, **[LP]**). Raios e frequências são **[HIP]**. Transições devem preservar o estado importante e dar resultados estatisticamente compatíveis. |
| **Justificativa** | "A decisão arquitetural que torna o mundo vivo viável para um desenvolvedor solo" (GDD). O GDD a classifica como o **maior risco técnico** do projeto. |
| **Consequências** | Exige o teste de equivalência (spike SP2) e o de comércio (SP7). O roadmap implementa a parte S0/S1 e adia o agregado (DEC-041). |
| **Data / versão** | GDD 0.1 cap. 4.5 · TA 0.1 cap. 5.3 · registrada em 01/11/2026 |
| **Relações** | DEC-038, DEC-041, DEC-080 |

### DEC-040 — Quantidade de NPCs (total, simulados em detalhe e simultâneos)

| Campo | Conteúdo |
|---|---|
| **Status** | PENDENTE |
| **Contexto** | Arthur pediu o registro desta dúvida. Nenhum documento fixa a quantidade. Existem apenas **hipóteses [HIP]** do GDD e do roadmap, que dependem de medição e de hardware-alvo (DEC-016). |
| **Decisão** | **Nada decidido.** Não há número aprovado de NPCs totais, de NPCs T1/T2 simulados em detalhe nem de NPCs fisicamente presentes ao mesmo tempo. |
| **Justificativa** | Hipóteses em circulação (não aprovadas): 150 a 300 NPCs T1/T2 em detalhe (GDD 24.2 e RM 0.13-B, item 2); "dezenas a poucas centenas" de T2/T3 simultâneos (GDD 8.2); resto do povoamento tratado como T0 agregado (GDD) ou fora do protótipo (RM, DEC-041). A recomendação é **medir** (spike SP2 e LW-179) antes de fixar. |
| **Consequências** | Os orçamentos de desempenho (DEC-071) e o tamanho dos dados dependem desta decisão. Qualquer número citado em documento ou tarefa deve vir rotulado [HIP]. |
| **Data / versão** | GDD 0.1 cap. 8.2 e 24.2 · RM 0.1 LW-055, LW-179 · registrada em 01/11/2026 |
| **Relações** | DEC-016, DEC-038, DEC-041, DEC-071 |

### DEC-041 — T0 / grupos de população fora do protótipo até haver necessidade medida

| Campo | Conteúdo |
|---|---|
| **Status** | APROVADA |
| **Contexto** | O GDD pede T0 para "o restante da população". O roadmap propõe adiar esse mecanismo para reduzir código e risco. |
| **Decisão** | **T0 (população agregada) fica fora do primeiro protótipo.** Só T1 e T2 individuais (cerca de 150 a 300 NPCs, **[HIP]**). O conceito é preservado no GDD e na arquitetura como primeira expansão; `PopulationGroup` e o LOD agregado (S2 e S3) só entram por tarefa nova, se o teste de carga (LW-179) ou a escala pedirem. |
| **Justificativa** | Diretriz 8 de Arthur. Menos código e menos risco. |
| **Consequências** | Desvia do GDD 24.2. Reversível: se a medição pedir, vira tarefa nova com ID novo. |
| **Data / versão** | RM 0.1 seção 0.13-B (desvio 2) · registrada em 01/11/2026 · mensagem de Arthur de 01/11/2026 15:32 (diretriz 8) |
| **Relações** | DEC-038, DEC-039, DEC-040 |

### DEC-042 — Decisão do NPC por utilidade, com catálogo de ações em dados

| Campo | Conteúdo |
|---|---|
| **Status** | PROPOSTA |
| **Contexto** | O BM pede NPCs com necessidades, objetivos e decisões, e uma base determinística e comportamental (DEC-035). |
| **Decisão** | Proposta da TA (9.2 a 9.4, 26.2) e do GDD (9.2): escolha de ação por **utilidade** sobre um **catálogo de ações em arquivos de dados**, com planos apenas para T2/T3, interrupções e registro do motivo ("Por quê?"). |
| **Justificativa** | Simples, depurável por humano e por IA, determinística. |
| **Consequências** | Se trocada (por exemplo, por árvores de comportamento), muda o módulo `npc/decision`, mas não a decisão DEC-035. |
| **Data / versão** | TA 0.1 cap. 9 · GDD 0.1 cap. 9.2 · registrada em 01/11/2026 |
| **Relações** | DEC-035, DEC-043 |

### DEC-043 — Memória episódica limitada, relações e rumores

| Campo | Conteúdo |
|---|---|
| **Status** | PROPOSTA |
| **Contexto** | O BM exige memória e relações para os NPCs (DEC-037). O custo precisa ser controlado. |
| **Decisão** | Proposta da TA (cap. 10) e do GDD (8.5, 8.6): memória episódica de tamanho limitado, relações como dados numéricos e qualitativos, e propagação de informação por rumores. O custo estimado é **[HIP]**. |
| **Justificativa** | Dá memória observável sem texto gerado. |
| **Consequências** | Limite e esquecimento precisam de teste. Afeta o tamanho do save (DEC-084). |
| **Data / versão** | TA 0.1 cap. 10 · GDD 0.1 cap. 8 · registrada em 01/11/2026 |
| **Relações** | DEC-037, DEC-042, DEC-084 |

### DEC-044 — Uso concreto de IA generativa (se houver): modelo, local ou nuvem, custo e privacidade

| Campo | Conteúdo |
|---|---|
| **Status** | PENDENTE **[FUT]** |
| **Contexto** | DEC-036 permite IA generativa opcional, mas não diz o que ela faria, qual modelo, onde rodaria nem quem pagaria o custo. A TA propõe apenas um spike futuro (SP8). |
| **Decisão** | **Nada decidido.** Fora do protótipo e do roadmap atual. |
| **Justificativa** | Recomendação (TA 26.4, não aprovada): decidir somente depois do protótipo validado, com protótipo técnico (SP8) e política de privacidade. |
| **Consequências** | Enquanto pendente, nenhuma tarefa cria integração com IA generativa. |
| **Data / versão** | TA 0.1 cap. 24 e 26.4 · registrada em 01/11/2026 |
| **Relações** | DEC-023, DEC-036, DEC-054 |

---

# ÁREA 6 — SOCIEDADE, ECONOMIA, POLÍTICA E GUERRA

### DEC-045 — Organizações agem sem intervenção do jogador

| Campo | Conteúdo |
|---|---|
| **Status** | APROVADA |
| **Contexto** | O BM descreve organizações e o que o jogador poderá fazer com elas. |
| **Decisão** | As organizações devem possuir **recursos, objetivos, hierarquia, relações, interesses e capacidade de agir sem intervenção do jogador**. |
| **Justificativa** | Escolha de Arthur (mundo independente, DEC-002). |
| **Consequências** | Facções e governos têm ciclo de decisão próprio. **O que o jogador pode fazer com elas** (integrar, ascender, fundar, financiar, conquistar) é visão de longo prazo (DEC-008); a fundação de organizações pelo jogador está fora do protótipo (DEC-054, proposta). |
| **Data / versão** | BM §5 (sem data) · GDD 0.1 cap. 10 · registrada em 01/11/2026 |
| **Relações** | DEC-002, DEC-008, DEC-050 |

### DEC-046 — Economia funcional e conectada

| Campo | Conteúdo |
|---|---|
| **Status** | APROVADA |
| **Contexto** | O BM define a economia como relações observáveis, não como cenário. |
| **Decisão** | A economia representa **produção, distribuição e consumo** (e transporte, estoques, preços e escassez, §3), todos **conectados**, com **efeitos observáveis no mundo** (guerras interrompem rotas, escassez afeta preços e estabilidade, organizações dependem de recursos). Economia meramente cosmética deve ser evitada. |
| **Justificativa** | Escolha de Arthur (pilar Economia e lista "evitar"). |
| **Consequências** | A economia não pode ser decorativa nem independente da política e da guerra. **Não** estão decididos: modelo de preços, número de moedas, tipos de bens, cadeias (ver propostas DEC-047 a DEC-049). |
| **Data / versão** | BM §3, §6 e §9 (sem data) · GDD 0.1 cap. 12 · registrada em 01/11/2026 |
| **Relações** | DEC-004, DEC-047, DEC-048, DEC-049 |

### DEC-047 — Dinheiro e quantidades em números inteiros, com livro-razão (`Ledger`)

| Campo | Conteúdo |
|---|---|
| **Status** | PROPOSTA |
| **Contexto** | Economia que cria ou perde dinheiro sem explicação quebra a simulação. |
| **Decisão** | Proposta da TA (11.3, 11.4, 26.2): dinheiro e quantidades em inteiros; todo movimento de dinheiro passa por um livro-razão com conservação verificável; fontes e sumidouros explícitos. Uma moeda no protótipo (GDD 24.3 deixa "múltiplas moedas" fora). |
| **Justificativa** | Evita erro de arredondamento e permite teste de conservação. |
| **Consequências** | Se aprovada, vira regra de revisão e teste automático (`check_all`). |
| **Data / versão** | TA 0.1 cap. 11.3 e 11.4 · GDD 0.1 cap. 12.3 · registrada em 01/11/2026 |
| **Relações** | DEC-046, DEC-048 |

### DEC-048 — Comércio simulado em duas escalas (detalhada e agregada)

| Campo | Conteúdo |
|---|---|
| **Status** | PROPOSTA (validação no spike SP7) |
| **Contexto** | Simular cada transação de cada mercado em detalhe é caro. |
| **Decisão** | Proposta da TA (11.6) e do GDD (12.4): comércio detalhado perto do jogador e agregado longe, com resultados equivalentes. |
| **Justificativa** | Mesma lógica do LOD (DEC-039). |
| **Consequências** | Exige o teste de equivalência SP7; o roadmap trata o limite de tolerância como decisão de Arthur (LW-101). |
| **Data / versão** | TA 0.1 cap. 11.6 · GDD 0.1 cap. 12.4 · RM 0.1 LW-101 · registrada em 01/11/2026 |
| **Relações** | DEC-039, DEC-047, DEC-049 |

### DEC-049 — `TradeRules` como único ponto em que a política altera a economia

| Campo | Conteúdo |
|---|---|
| **Status** | PROPOSTA |
| **Contexto** | Política e economia precisam se afetar sem se acoplar (embargo, imposto, tarifa). |
| **Decisão** | Proposta da TA (11.8, 13.5, 26.2): a política publica regras em uma interface (`TradeRules`) que a economia consulta; a economia não conhece facções nem leis. |
| **Justificativa** | Mantém a regra "um dono por dado". |
| **Consequências** | Qualquer novo efeito político sobre a economia passa por essa interface. |
| **Data / versão** | TA 0.1 cap. 11.8 e 13.5 · registrada em 01/11/2026 |
| **Relações** | DEC-046, DEC-048, DEC-075 |

### DEC-050 — Composição de facções e polities do protótipo (3 facções; 2 polities, uma simplificada)

| Campo | Conteúdo |
|---|---|
| **Status** | APROVADA (composição inicial) |
| **Contexto** | O BM não fixa quantas facções existem. O GDD propõe 3 facções (autoridade local, organização mercantil, organização criminosa) e 2 a 3 polities com relações simples. |
| **Decisão** | **Inicialmente 3 facções** (autoridade local, organização mercantil, organização criminosa) e **2 entidades políticas (polities)**, sendo uma simplificada (DEC-051). Detalhe adotado provisoriamente por recomendação: a facção de autoridade é o governo da polity principal; a soberania sobre províncias é da polity; as facções têm presença e influência. |
| **Justificativa** | Diretriz 9 de Arthur. Mínimo para observar cascatas políticas, econômicas e criminais. |
| **Consequências** | A contradição antiga (3 facções e só uma governo) fica resolvida pela polity vizinha simplificada. LW-117, LW-118 e LW-138 seguem esta relação entre facção e polity. Uma terceira polity vai para o backlog. |
| **Data / versão** | GDD 0.1 cap. 24.2 e Anexo C · registrada em 01/11/2026 · mensagem de Arthur de 01/11/2026 15:32 (diretriz 9) |
| **Relações** | DEC-045, DEC-051 |

### DEC-051 — Polity vizinha de baixa resolução (em vez de quarta facção completa)

| Campo | Conteúdo |
|---|---|
| **Status** | APROVADA |
| **Contexto** | Resolve a contradição registrada em DEC-050. |
| **Decisão** | A segunda polity é **simplificada** (baixa resolução): relações, força e tarifa, sem membros nem facções internas completas. Dá contexto diplomático e comercial. |
| **Justificativa** | Diretriz 9 de Arthur. Evita o custo de uma quarta facção completa. |
| **Consequências** | Desvia do GDD 24.2 de forma deliberada, agora com aprovação. |
| **Data / versão** | RM 0.1 seção 0.13-B (desvio 4) e LW-117 · registrada em 01/11/2026 · mensagem de Arthur de 01/11/2026 15:32 (diretriz 9) |
| **Relações** | DEC-050 |

### DEC-052 — Escala de conflitos: incidente, escaramuça, batalha, cerco e guerra

| Campo | Conteúdo |
|---|---|
| **Status** | PROPOSTA |
| **Contexto** | O BM pede "batalhas de diferentes escalas" (§8) e conflitos por território, recursos e interesses (§3). |
| **Decisão** | Proposta do GDD (15.2): cinco escalas, com resolução diferente para cada uma (de tempo real a simulação estratégica agregada). |
| **Justificativa** | Organiza o tratamento sem exigir simulação máxima de tudo. |
| **Consequências** | Serve de vocabulário comum. **A escala escolhida para o protótipo está em DEC-053 (pendente).** |
| **Data / versão** | GDD 0.1 cap. 15.2 · registrada em 01/11/2026 |
| **Relações** | DEC-053, DEC-054 |

### DEC-053 — Escala das batalhas no protótipo (limite de combatentes e modo de resolução)

| Campo | Conteúdo |
|---|---|
| **Status** | PENDENTE |
| **Contexto** | Arthur pediu o registro desta dúvida. O BM prevê "batalhas de diferentes escalas", "invasões" e "cercos" como possibilidades (§8). Nenhum documento fixa o tamanho das batalhas nem quantos combatentes corpóreos existem ao mesmo tempo. |
| **Decisão** | **Nada decidido.** Não estão aprovados: (a) o número máximo de combatentes com corpo simultâneos; (b) se a batalha é tático em tempo real limitado ou resolução abstrata; (c) se o jogador pode comandar. |
| **Justificativa** | Hipóteses não aprovadas: GDD 15.5 e TA 14.3 propõem uma abordagem em duas escalas (recorte físico com "poucas dezenas" de combatentes em volta do jogador, mais resolução agregada para o resto), com orçamento a medir por perfilagem **[HIP]**. Batalhas grandes em tempo real são tratadas como **risco [LIM]**. A recomendação é decidir após o spike SP6 e o SP2, com hardware-alvo definido. |
| **Consequências** | Afeta o módulo `military`, o `combat`, a câmera tática (DEC-029) e o orçamento de desempenho (DEC-071). Cercos e exércitos grandes ficam fora do protótipo apenas por proposta (DEC-054). |
| **Data / versão** | BM §8 · GDD 0.1 cap. 15.2 e 15.5 · TA 0.1 cap. 14.3 · RM 0.1 LW-146 · registrada em 01/11/2026 |
| **Relações** | DEC-029, DEC-052, DEC-054, DEC-066, DEC-071 |

### DEC-054 — Itens fora do protótipo (cercos, exércitos grandes, intriga, sucessão, magia ampla, domesticação, famílias, múltiplas moedas, fundação de organizações, multiplayer, IA generativa, vários continentes, geração procedural)

| Campo | Conteúdo |
|---|---|
| **Status** | PROPOSTA |
| **Contexto** | O BM descreve uma visão grande e pede um protótipo pequeno (DEC-091). É preciso dizer o que fica de fora. |
| **Decisão** | Proposta do GDD (24.3, rotulada "[CONF/PROP]") e do RM (0.14, Anexo E): os itens do título ficam **fora do protótipo**. Os itens "multiplayer" e "IA generativa" já estão cobertos por decisões de Arthur (DEC-018 e DEC-036: sem obrigação e opcional); o restante é apenas proposta. |
| **Justificativa** | Mantém o protótipo executável por uma pessoa com agentes. |
| **Consequências** | Cada item pode voltar por decisão de Arthur, com ID novo. O destino de cada um está no RM Anexo E. |
| **Data / versão** | GDD 0.1 cap. 24.3 · RM 0.1 cap. 0.14 e Anexo E · registrada em 01/11/2026 |
| **Relações** | DEC-018, DEC-034, DEC-036, DEC-053, DEC-091, DEC-098 |

---

# ÁREA 7 — MUNDO FÍSICO E ESPACIAL

### DEC-055 — Dimensões do mundo (tamanho físico, número de regiões e províncias)

| Campo | Conteúdo |
|---|---|
| **Status** | PENDENTE |
| **Contexto** | Arthur pediu o registro desta dúvida. **Nenhum documento fixa dimensões em quilômetros nem o tamanho do mundo.** O BM fala em regiões, cidades, vilas (§3) e em protótipo pequeno e expansível (§2). |
| **Decisão** | **Nada decidido.** Não há área, número de regiões, número de cidades nem tamanho de chunk aprovados. (Exceção: o terreno de teste do protótipo foi decidido na DEC-118; o tamanho final do mundo continua sem decisão.) |
| **Justificativa** | Hipóteses não aprovadas, todas rotuladas [HIP]: protótipo com 1 região autoral e 12 a 30 províncias lógicas, parte delas jogável em 3D detalhado (GDD 24.2); chunks de cerca de 64 m e terreno de teste de cerca de 1 km² (RM, fase 1). A recomendação é fixar o tamanho **depois** do spike do terreno (SP4a), com hardware-alvo (DEC-016) e meta de quadros definidos. |
| **Consequências** | Condiciona terreno (DEC-057), câmera estratégica (DEC-028), distância de viagem, desempenho (DEC-071) e quantidade de NPCs (DEC-040). Nenhum número de dimensão pode aparecer como definitivo. Portão da Fase 1 atendido pela DEC-118 (05/11/2026); o tamanho FINAL do mundo continua PENDENTE e deve ser reavaliado, com a condição (d) da DEC-057, antes da Fase 5. |
| **Data / versão** | BM §2 e §3 · GDD 0.1 cap. 4 e 24.2 · RM 0.1 LW-033 · registrada em 01/11/2026 |
| **Relações** | DEC-016, DEC-028, DEC-040, DEC-057, DEC-071, DEC-118 |

### DEC-056 — Mundo lógico separado do mundo visual, com hierarquia espacial

| Campo | Conteúdo |
|---|---|
| **Status** | PROPOSTA |
| **Contexto** | A simulação precisa funcionar sem terreno desenhado (para testar e para rodar em LOD). |
| **Decisão** | Proposta do GDD (4.2) e da TA (5.2): um mapa **lógico** (região, província, assentamento, ponto de interesse) como dado da simulação, independente do terreno 3D, que é apenas apresentação. |
| **Justificativa** | Permite validar economia e sociedade sem gráficos (GDD 24.4, observação). |
| **Consequências** | Os níveis da hierarquia e os nomes são provisórios (DEC-033). |
| **Data / versão** | GDD 0.1 cap. 4.2 · TA 0.1 cap. 5.2 · registrada em 01/11/2026 |
| **Relações** | DEC-033, DEC-074 |

### DEC-057 — Terreno: solução própria ou addon

| Campo | Conteúdo |
|---|---|
| **Status** | APROVADA |
| **Contexto** | A câmera seamless (DEC-026) exige terreno em níveis de detalhe. A TA avaliou as opções e declarou a escolha pendente, para decidir com o resultado do spike SP4a. O spike SP4a (LW-033, `docs/decisions/0007-spike-sp4a-terreno.md`) mediu terreno próprio e addon (Terrain3D v1.1.0-stable, MIT) no PC (provisório) e no Mac de referência (oficial, DEC-016). Nas duas máquinas o terreno próprio foi mais rápido em 9 de 9 combinações e acertou a colisão em 36 de 36; o addon andou liso (0 engasgos), mas acertou 22 de 36 na colisão, causa não investigada. O terreno próprio engasgou ao andar (médio e alto). A comparação visual não foi possível (addon sem material). Medição do Mac em modo depuração, com energia incerta: serve para comparar, não para fixar meta de quadros. |
| **Decisão** | **Terreno próprio** (malha por script, por chunk) para o protótipo. O addon Terrain3D v1.1.0-stable (MIT) **não foi adotado por ora**. |
| **Justificativa** | Mais rápido nas duas máquinas, colisão sempre correta, código nosso e fácil de depurar pelo Codex, sem depender de API nativa fechada. Não é uma escolha sobre o visual final. |
| **Consequências** | Condições de Arthur: (a) resolver os engasgos ao andar antes de oferecer o nível "alto" ao jogador; (b) confirmar ou corrigir a "frestinha" entre níveis de detalhe vizinhos; (c) o terreno fica só na camada de apresentação, para poder trocar depois sem mexer na simulação. Entende-se, por confirmação de Arthur em 05/11/2026: a malha, a colisão e o material do terreno ficam na camada de apresentação; as alturas e superfícies do mapa (dados lógicos, TerrainData, LW-034) ficam na simulação (DEC-056). (d) reavaliar o Terrain3D na LW-040 ou na revisão arquitetural da Fase 1 (LW-053) se ocorrer qualquer um destes gatilhos: os engasgos persistirem depois de construir os pedaços aos poucos; as frestas não tiverem conserto simples; ou a decisão do tamanho do mundo (DEC-055) exigir um mapa de vários quilômetros antes da Fase 5; (e) a primeira medição do jogo real deve ser em modo release e com o Mac na tomada. Qualquer addon de terceiros continua precisando de decisão e licença explícitas. |
| **Data / versão** | TA 0.1 cap. 19.4 e 26.4 · RM 0.1 LW-033 · SP4a Parte A (PC, 04/11/2026) e Parte B (Mac, 05/11/2026) · Decidida por Arthur em 05/11/2026 · registrada em 05/11/2026 (LW-033A) |
| **Relações** | DEC-026, DEC-028, DEC-055, DEC-058, DEC-080 |

### DEC-058 — Terreno em chunks com níveis de detalhe

| Campo | Conteúdo |
|---|---|
| **Status** | PROPOSTA (validação no spike SP4) |
| **Contexto** | Para a transição contínua entre escalas, o terreno precisa mudar de detalhe com a distância. |
| **Decisão** | Proposta da TA (19.4) e do GDD (21): terreno dividido em chunks com LOD, objetos distantes como proxies simples, camadas de mapa sobre o mesmo terreno. Tamanhos e distâncias são **[HIP]**. |
| **Justificativa** | Padrão conhecido para mundos abertos; combina com o estilo low-poly (DEC-020). |
| **Consequências** | É o principal risco técnico da câmera. Plano B: transição "fatiada". Validação parcial no SP4a (05/11/2026): o spike exercitou chunks com níveis de detalhe no terreno próprio, em cerca de 1 km², com as condições (a) e (b) da DEC-057 em aberto; a transição de câmera até a visão estratégica continua sem validação (SP4 final, LW-168). |
| **Data / versão** | TA 0.1 cap. 19.4 · GDD 0.1 cap. 21 · registrada em 01/11/2026 |
| **Relações** | DEC-026, DEC-028, DEC-057 |

### DEC-059 — Tempo do mundo: dia e noite, relógio da simulação

| Campo | Conteúdo |
|---|---|
| **Status** | PROPOSTA |
| **Contexto** | A rotina dos NPCs e a economia dependem de um tempo simulado. |
| **Decisão** | Proposta do GDD (4.4) e da TA (5.4): tempo simulado contínuo, com ciclo de dia e noite e escala de tempo configurável. Valores são **[HIP]**. |
| **Justificativa** | Necessário às rotinas (DEC-037). |
| **Consequências** | A relação entre tempo real e simulado ainda precisa de validação. |
| **Data / versão** | GDD 0.1 cap. 4.4 · TA 0.1 cap. 5.4 · registrada em 01/11/2026 |
| **Relações** | DEC-037, DEC-078 |

### DEC-060 — Clima e estações fora do protótipo

| Campo | Conteúdo |
|---|---|
| **Status** | PROPOSTA |
| **Contexto** | Clima e estações não são necessários às quatro hipóteses do protótipo (GDD 24.1). |
| **Decisão** | Proposta do RM (0.13-B, desvio 6; Anexo E): fora do roadmap. |
| **Justificativa** | Reduz escopo. |
| **Consequências** | Reversível por tarefa nova. |
| **Data / versão** | RM 0.1 seção 0.13-B (desvio 6) · registrada em 01/11/2026 |
| **Relações** | DEC-054, DEC-098 |

### DEC-061 — Mundo autoral de uma região; sem geração procedural no protótipo

| Campo | Conteúdo |
|---|---|
| **Status** | PROPOSTA |
| **Contexto** | O BM pede protótipo pequeno (DEC-091) e universo original (DEC-009). Gerar mundo por algoritmo é caro e difícil de equilibrar. |
| **Decisão** | Proposta do GDD (24.2 e 24.3): uma região autoral, feita à mão, com os dados em arquivos; geração procedural e vários continentes ficam fora. |
| **Justificativa** | Controle de qualidade e custo. |
| **Consequências** | O tamanho dessa região é DEC-055 (pendente). |
| **Data / versão** | GDD 0.1 cap. 24.2 e 24.3 · registrada em 01/11/2026 |
| **Relações** | DEC-009, DEC-055, DEC-091 |

---

# ÁREA 8 — JOGADOR, PROGRESSÃO, COMBATE E EVENTOS

### DEC-062 — Trajetórias jogáveis no protótipo

| Campo | Conteúdo |
|---|---|
| **Status** | APROVADA (somente a meta de três trajetórias) |
| **Contexto** | O BM lista 13 trajetórias como possibilidade (DEC-008) e exige que não sejam exclusivas (DEC-003). Quais existirão no protótipo não foi decidido. |
| **Decisão** | Meta inicial de **três trajetórias jogáveis**, combináveis; as demais ficam preservadas como possibilidades futuras. As três candidatas, adotadas provisoriamente por recomendação: **mercador, soldado/guarda e aventureiro**; confirmação final na LW-146. "Cinco" no GDD 24.2 é teto de conteúdo, não requisito; crime é consequência (LW-164 e LW-165), não trajetória validada; produtor/artesão fica no backlog. |
| **Justificativa** | Diretriz 10 de Arthur. O critério do GDD é "pelo menos três viáveis e combináveis" (24.1, hipótese 3). |
| **Consequências** | Define quais sistemas do jogador entram (comércio, serviço em facção, exploração e combate). LW-184 testa as três. |
| **Data / versão** | BM §4 · GDD 0.1 cap. 24.1 e 24.2 · RM 0.1 seção 0.13-B (desvio 3) e LW-146 · registrada em 01/11/2026 · mensagem de Arthur de 01/11/2026 15:32 (diretriz 10) |
| **Relações** | DEC-003, DEC-008, DEC-029, DEC-098 |

### DEC-063 — Origens do personagem (3 a 4 no protótipo)

| Campo | Conteúdo |
|---|---|
| **Status** | PROPOSTA |
| **Contexto** | O BM diz que o jogador "nasce em um mundo já existente" (§1), sem classes. Uma "origem" dá ponto de partida, sem restringir o futuro. |
| **Decisão** | Proposta do GDD (6.2 e 24.2): 3 a 4 origens no protótipo; origem **não** é classe (não bloqueia atividades). Valores [HIP]. |
| **Justificativa** | Dá variedade inicial com custo baixo. |
| **Consequências** | Conflita com DEC-003 se virar restrição; deve ser revisada. |
| **Data / versão** | GDD 0.1 cap. 6.2 e 24.2 · registrada em 01/11/2026 |
| **Relações** | DEC-003 |

### DEC-064 — Progressão por quatro eixos, sem nível global

| Campo | Conteúdo |
|---|---|
| **Status** | PROPOSTA |
| **Contexto** | O BM proíbe progressão artificial e *grind* excessivo (DEC-006) e classes rígidas (DEC-003). |
| **Decisão** | Proposta do GDD (6.4 e 6.5): progressão em quatro eixos (habilidades por uso, reputação, recursos e relações), sem nível global. |
| **Justificativa** | Coerente com a liberdade de trajetória. |
| **Consequências** | Exige equilíbrio por teste; os números são [HIP]. |
| **Data / versão** | GDD 0.1 cap. 6.4 e 6.5 · registrada em 01/11/2026 |
| **Relações** | DEC-003, DEC-006 |

### DEC-065 — Morte, ferimentos e derrota do jogador

| Campo | Conteúdo |
|---|---|
| **Status** | PENDENTE |
| **Contexto** | O BM não define o que acontece quando o jogador falha. O GDD descreve três modelos (A, B e C). |
| **Decisão** | **Nada decidido.** (GDD 6.6; Anexo D, D2) |
| **Justificativa** | Recomendação (GDD, não aprovada): modelo B no protótipo, e avaliar C depois. Decisão formal planejada na LW-146. |
| **Consequências** | Afeta combate, salvamento (permadeath?), consequências e narrativa. |
| **Data / versão** | GDD 0.1 cap. 6.6 e Anexo D (D2) · RM 0.1 LW-146 · registrada em 01/11/2026 |
| **Relações** | DEC-005, DEC-066 |

### DEC-066 — Sistema definitivo de combate

| Campo | Conteúdo |
|---|---|
| **Status** | PENDENTE |
| **Contexto** | Arthur pediu o registro desta dúvida. O BM fixa só os princípios: combate físico, armas variadas, furtividade, criaturas, chefes, batalhas de diferentes escalas, magia (como possibilidades) e que o combate deve ser "interessante e integrado ao mundo, não uma atividade isolada" (§8). **Não há sistema definitivo.** |
| **Decisão** | **Nada decidido** sobre o sistema em si. O que é APROVADO é apenas o princípio da integração com o mundo (DEC-008). Ficam em aberto: ritmo (tempo real puro, com pausa, por turnos), mira, estamina, golpes, defesa, dano, ferimentos, durabilidade, furtividade e combate à distância. |
| **Justificativa** | O GDD (cap. 16) propõe tempo real em terceira pessoa com estamina e ferimentos, e a TA (cap. 15) define uma fronteira entre simulação e apresentação do combate. Ambos são **PROPOSTA** com ritmo exato em **[HIP]**. A recomendação é decidir após o spike SP6 (combate), na Fase 5. |
| **Consequências** | Afeta DEC-053, DEC-067, DEC-068 e o balanceamento. Enquanto pendente, o combate do protótipo (DEC-067) é só uma proposta de trabalho. |
| **Data / versão** | BM §8 · GDD 0.1 cap. 16 · TA 0.1 cap. 15 · RM 0.1 LW-146 e SP6 · registrada em 01/11/2026 |
| **Relações** | DEC-008, DEC-030, DEC-053, DEC-065, DEC-067 |

### DEC-067 — Combate do protótipo: corpo a corpo, arco, furtividade básica, ferimentos e durabilidade

| Campo | Conteúdo |
|---|---|
| **Status** | PROPOSTA |
| **Contexto** | É o conjunto mínimo de combate proposto para provar as hipóteses. |
| **Decisão** | Proposta do GDD (24.2 e cap. 16): combate em tempo real em terceira pessoa com estamina, ferimentos e durabilidade de equipamento. |
| **Justificativa** | Mínimo coerente com o BM §8. |
| **Consequências** | Se DEC-066 for decidido de outra forma, esta entrada vira SUBSTITUÍDA. A direção por alvo e habilidades (DEC-117) altera o estilo de controle do combate proposto no GDD 16.2 (mira por direção); revisar no SP6. DEC-066 continua PENDENTE. |
| **Data / versão** | GDD 0.1 cap. 16 e 24.2 · registrada em 01/11/2026 |
| **Relações** | DEC-066, DEC-068, DEC-117 |

### DEC-068 — Criaturas: 3 a 4 tipos e 1 chefe no protótipo

| Campo | Conteúdo |
|---|---|
| **Status** | PROPOSTA |
| **Contexto** | O BM lista criaturas, monstros e chefes como possibilidades (§8). |
| **Decisão** | Proposta do GDD (24.2): 3 a 4 tipos de criatura e 1 chefe. O chefe e as criaturas especiais são o **segundo** item da lista de corte (DEC-099). |
| **Justificativa** | Dá variedade mínima de combate e exploração. |
| **Consequências** | O roadmap trata a decisão final do chefe na LW-146. |
| **Data / versão** | GDD 0.1 cap. 24.2 e 24.5 · RM 0.1 LW-146 · registrada em 01/11/2026 |
| **Relações** | DEC-032, DEC-034, DEC-066, DEC-099 |

### DEC-069 — Diretor de eventos (sistema que provoca acontecimentos para dar ritmo)

| Campo | Conteúdo |
|---|---|
| **Status** | PENDENTE |
| **Contexto** | O BM quer acontecimentos autônomos (§3), mas não diz se existirá um "diretor" que ajuste o ritmo para o jogador. Isso pode conflitar com DEC-002. |
| **Decisão** | **Nada decidido.** (GDD 19.5; Anexo D, D4) |
| **Justificativa** | Recomendação (GDD, não aprovada): sem diretor no protótipo. |
| **Consequências** | Os eventos do protótipo (DEC-070) surgem do estado do mundo, sem ajuste para o jogador. |
| **Data / versão** | GDD 0.1 cap. 19.5 e Anexo D (D4) · registrada em 01/11/2026 |
| **Relações** | DEC-002, DEC-070 |

### DEC-070 — Eventos dinâmicos: 8 a 12 tipos, na Fase 5

| Campo | Conteúdo |
|---|---|
| **Status** | PROPOSTA |
| **Contexto** | O GDD põe eventos no marco M4; o roadmap os move para a Fase 5. |
| **Decisão** | Proposta do GDD (24.2: 8 a 12 tipos, [HIP]) e do RM (0.13-B, desvio 8; LW-162): eventos dinâmicos construídos na Fase 5, depois de combate e câmera. Crônica e reputação ficam na Fase 4. |
| **Justificativa** | A alocação de conteúdo às fases é proposta do RM. A DEC-094 (aprovada) fixa apenas a existência, a ordem e os nomes das seis fases. Gatilho: no VAL da Fase 4 (LW-145) decide-se se 1 ou 2 tipos simples sobem para o fim da Fase 4. |
| **Consequências** | Desvia do GDD M4 de forma deliberada. |
| **Data / versão** | GDD 0.1 cap. 24.2 e 24.4 · RM 0.1 seção 0.13-B (desvio 8) e LW-162 · registrada em 01/11/2026 |
| **Relações** | DEC-069, DEC-094, DEC-112 |

---

# ÁREA 9 — ARQUITETURA TÉCNICA

> Duas decisões de Arthur (DEC-072 e DEC-073) e o restante **proposto** pela `TECHNICAL_ARCHITECTURE.md` (TA). O rótulo **[CONF]** que a TA usa em alguns itens **só vale como APROVADA** onde há fonte de Arthur indicada aqui.

### DEC-071 — Orçamentos de desempenho e metas de quadros

| Campo | Conteúdo |
|---|---|
| **Status** | PROPOSTA (valores **[HIP]**) |
| **Contexto** | O BM pede "eficiência computacional" (§9) e sistemas viáveis para um desenvolvedor solo. Sem números, não há como testar. |
| **Decisão** | Proposta da TA (20.1): um orçamento de milissegundos por passo de simulação, por módulo, e uma meta de quadros por segundo no hardware-alvo. **Nenhum valor está aprovado.** |
| **Justificativa** | Torna a eficiência mensurável. |
| **Consequências** | Os valores dependem do hardware-alvo (DEC-016) e da quantidade de NPCs (DEC-040). Meta de quadros é decisão de Arthur na LW-033. A meta de quadros foi decidida na DEC-119 (07/11/2026). |
| **Data / versão** | TA 0.1 cap. 20.1 · RM 0.1 LW-033 · registrada em 01/11/2026 |
| **Relações** | DEC-016, DEC-040, DEC-053, DEC-055 |

### DEC-072 — Arquitetura modular e expansível

| Campo | Conteúdo |
|---|---|
| **Status** | APROVADA |
| **Contexto** | O pedido da arquitetura exige "arquitetura modular e expansível". O BM pede "modularidade", "escalabilidade" e "possibilidade de expansão" (§9). |
| **Decisão** | A arquitetura do Living World é **modular e expansível**. |
| **Justificativa** | Escolha de Arthur. |
| **Consequências** | Cada sistema é um módulo com responsabilidade clara e interface definida. **Como** modularizar (camadas, nomes, pastas) são propostas da TA (DEC-074 a DEC-077). |
| **Data / versão** | BM §9 · PA 01/11/2026 (arquitetura) · registrada em 01/11/2026 |
| **Relações** | DEC-006, DEC-073, DEC-074 |

### DEC-073 — Simplicidade: não adotar padrões complexos apenas por parecerem profissionais

| Campo | Conteúdo |
|---|---|
| **Status** | APROVADA |
| **Contexto** | O pedido da arquitetura diz: "Não adote padrões arquiteturais complexos apenas por parecerem profissionais". |
| **Decisão** | Cada padrão arquitetural só entra se resolver um problema **real e demonstrado** do projeto. |
| **Justificativa** | Escolha de Arthur: o desenvolvedor é solo, sem experiência de programação, e depende de agentes de IA (DEC-092). |
| **Consequências** | A TA 1.3 aplica este critério (ver DEC-102 a DEC-111, alternativas descartadas). Toda tarefa que introduza um padrão novo precisa justificá-lo. |
| **Data / versão** | PA 01/11/2026 (arquitetura) · registrada em 01/11/2026 |
| **Relações** | DEC-006, DEC-092, DEC-102 |

### DEC-074 — Simulação separada da apresentação, com ponte de intenções e resultados

| Campo | Conteúdo |
|---|---|
| **Status** | PROPOSTA |
| **Contexto** | Mundo independente do jogador (DEC-002), testes sem gráficos e preparo barato para multiplayer (DEC-019). |
| **Decisão** | Proposta da TA (cap. 6, 26.2): a simulação não conhece telas nem cenas. Uma **ponte** transporta "intenções" (da apresentação para a simulação) e "resultados" (da simulação para a apresentação). A apresentação nunca altera o estado diretamente. |
| **Justificativa** | Permite testar e rodar a simulação sem gráficos; viabiliza LOD e salvamento limpo. É a decisão estrutural mais importante da TA. |
| **Consequências** | Se aprovada, vira regra de revisão e de `check_all`. Validação no spike SP2. |
| **Data / versão** | TA 0.1 cap. 6 e 26.2 · registrada em 01/11/2026 |
| **Relações** | DEC-002, DEC-019, DEC-056, DEC-075, DEC-077 |

### DEC-075 — `World` e `SimulationHost`; no máximo quatro autoloads

| Campo | Conteúdo |
|---|---|
| **Status** | PROPOSTA |
| **Contexto** | Autoload demais vira variável global disfarçada. |
| **Decisão** | Proposta da TA (4.3, 5.1, 26.2): um objeto `World` guarda o estado; um `SimulationHost` o executa; no máximo 4 autoloads. |
| **Justificativa** | Mantém "um dono por dado". |
| **Consequências** | Qualquer quinto autoload exige decisão. |
| **Data / versão** | TA 0.1 cap. 4.3 e 5.1 · registrada em 01/11/2026 |
| **Relações** | DEC-074, DEC-076 |

### DEC-076 — Entidades como identificadores inteiros nunca reutilizados, com dados por composição

| Campo | Conteúdo |
|---|---|
| **Status** | PROPOSTA |
| **Contexto** | Referências por objeto quebram salvamento, LOD e multiplayer. |
| **Decisão** | Proposta da TA (cap. 7, 26.2): entidade = ID inteiro **nunca reutilizado**; NPCs simulados como dados (não como cenas); composição de dados em vez de herança profunda (máximo 2 níveis). Sem ECS de terceiros (DEC-102). |
| **Justificativa** | Permite salvar, carregar e simular sem depender de nós de cena. |
| **Consequências** | Exige "visão somente leitura" bem definida (limitação reconhecida pela TA 7.5). |
| **Data / versão** | TA 0.1 cap. 7 e 26.2 · registrada em 01/11/2026 |
| **Relações** | DEC-019, DEC-074, DEC-102 |

### DEC-077 — Comunicação em três canais, com `EventBus` próprio e causa registrada

| Campo | Conteúdo |
|---|---|
| **Status** | PROPOSTA |
| **Contexto** | O BM exige que os sistemas se comuniquem e que o mundo registre consequências (DEC-005, DEC-006). |
| **Decisão** | Proposta da TA (cap. 17, 26.2): três canais de comunicação (chamada direta pela interface do dono, eventos pelo `EventBus` e consulta de leitura); cada evento carrega `cause_id`, o que alimenta o painel "Por quê?"; *Signals* do Godot só na apresentação. |
| **Justificativa** | Torna as cascatas rastreáveis e depuráveis. |
| **Consequências** | Exige disciplina de eventos (TA 17.4). |
| **Data / versão** | TA 0.1 cap. 17 e 26.2 · registrada em 01/11/2026 |
| **Relações** | DEC-005, DEC-049, DEC-074 |

### DEC-078 — Passo fixo de simulação de 1 minuto simulado, com orçamento de milissegundos

| Campo | Conteúdo |
|---|---|
| **Status** | PROPOSTA |
| **Contexto** | Simulação reproduzível exige passo fixo e independente da taxa de quadros. |
| **Decisão** | Proposta da TA (6.4, 26.2): passo fixo de 1 minuto simulado, com módulos em frequências diferentes **[HIP]** e orçamento de milissegundos por passo. |
| **Justificativa** | Previsibilidade e testes. |
| **Consequências** | O valor de 1 minuto é proposto e deve ser validado no spike SP1. |
| **Data / versão** | TA 0.1 cap. 6.4 · registrada em 01/11/2026 |
| **Relações** | DEC-059, DEC-071, DEC-080 |

### DEC-079 — Gerador de aleatoriedade único, com semente salva

| Campo | Conteúdo |
|---|---|
| **Status** | PROPOSTA |
| **Contexto** | Aleatoriedade espalhada impede reproduzir bugs. |
| **Decisão** | Proposta da TA (26.2) e do GDD (D5): um único gerador de números aleatórios da simulação, com semente guardada no save. Determinismo total é outra pergunta (DEC-081). |
| **Justificativa** | Reproduzir falhas e testar. |
| **Consequências** | Código da simulação não pode usar `randf()` global nem o relógio do sistema. |
| **Data / versão** | TA 0.1 cap. 26.2 · GDD 0.1 Anexo D (D5) · registrada em 01/11/2026 |
| **Relações** | DEC-081 |

### DEC-080 — Spikes: protótipos técnicos descartáveis para validar o que é arriscado (SP1 a SP8)

| Campo | Conteúdo |
|---|---|
| **Status** | APROVADA (somente a antecipação dos testes de combate e de câmera) |
| **Contexto** | O BM pede que se separe o confirmado do que precisa ser validado (§11). |
| **Decisão** | Proposta da TA (26.3): SP1 núcleo da simulação; SP2 corpos e LOD; SP3 dados e testes; SP4 câmera e terreno; SP5 salvamento; SP6 combate; SP7 equivalência do comércio; SP8 IA de texto **[FUT]**. O roadmap distribui os spikes pelas fases (RM 0.13). **Diretriz 11 de Arthur:** antecipar os testes de combate e de câmera, para não desenvolver quatro fases sem validar a experiência jogável. Na v0.3: o SP6 (combate, LW-152) roda logo depois da LW-054, antes da Fase 2; o SP4a (LW-033) inclui um teste de subida de câmera; o SP4 final continua na Fase 5 (LW-168). |
| **Justificativa** | Transformar hipóteses em fatos antes de construir sobre elas. |
| **Consequências** | Cada spike produz relatório e registro de decisão em `docs/decisions/`. O resultado pode **mudar** propostas (ex.: câmera DEC-028, formato de save DEC-084). |
| **Data / versão** | TA 0.1 cap. 26.3 · RM 0.1 seção 0.13 · registrada em 01/11/2026 · mensagem de Arthur de 01/11/2026 15:32 (diretriz 11) |
| **Relações** | DEC-026, DEC-028, DEC-039, DEC-084 |

### DEC-081 — Determinismo da simulação no mesmo ambiente (sem replay universal)

| Campo | Conteúdo |
|---|---|
| **Status** | APROVADA |
| **Contexto** | DEC-035 fixa simulação determinística como base, mas "determinística" não diz se o jogo promete repetir exatamente o mesmo resultado a partir do mesmo save. |
| **Decisão** | **Determinismo no mesmo ambiente** (mesma versão do jogo, do Godot e do sistema): mesma semente e mesmos comandos produzem o mesmo mundo, provado pelo hash de estado; salvar, carregar e continuar dá o mesmo resultado que continuar direto. **Não** se exige replay universal nem bit a bit entre máquinas, sistemas ou versões. |
| **Justificativa** | Diretriz 6 de Arthur. É o que os testes precisam; o replay universal só serviria a multiplayer em passo travado ou a replays compartilháveis, fora do protótipo (DEC-018). |
| **Consequências** | Simulação em inteiros, gerador único, ordem de iteração definida e SHA-256 do estado (TA 21.5). Hashes não são comparados entre sistemas sem teste. Bugs se reproduzem por semente, save e comandos. |
| **Data / versão** | GDD 0.1 Anexo D (D5) · registrada em 01/11/2026 · mensagem de Arthur de 01/11/2026 15:32 (diretriz 6) |
| **Relações** | DEC-035, DEC-079, DEC-083 |

### DEC-082 — Definições do jogo em arquivos de dados validados

| Campo | Conteúdo |
|---|---|
| **Status** | APROVADA (somente JSON validado como formato das definições; o formato interno dos arquivos — lista de objetos com `id` — e os esquemas seguem PROPOSTA) |
| **Contexto** | Bens, ações, culturas e eventos devem ser dados, não código, para o agente de IA editar sem arriscar a lógica. |
| **Decisão** | Proposta da TA (16.1 a 16.4, 26.2): três tipos de dados (definições, estado, configuração) que não se misturam; definições em arquivos (JSON proposto) validados no boot; IDs textuais estáveis. |
| **Justificativa** | Facilita conteúdo e expansão (DEC-072). |
| **Consequências** | Plano B (`.tres` com validadores) não foi necessário no spike SP3 (LW-025; ver `docs/decisions/0003-pipeline-de-dados.md`). Confirmação de que o Codex edita os dados sem quebrar o resto segue pendente. |
| **Data / versão** | TA 0.1 cap. 16 · registrada em 01/11/2026 · aprovada por Arthur em mensagem de 01/11/2026 (aprovação das entregas LW-024 e LW-025) |
| **Relações** | DEC-072, DEC-080 |

### DEC-083 — Modelo de persistência (o que se salva, formato, slots, autosave e regras de falha)

| Campo | Conteúdo |
|---|---|
| **Status** | APROVADA (somente os princípios iniciais) |
| **Contexto** | Arthur pediu o registro desta dúvida. O BM **não** menciona salvamento. O GDD (24.2) e a TA (cap. 18) propõem salvamento completo, em JSON, mas isso é proposta. |
| **Decisão** | Princípios aprovados: (1) persistência e testes de salvamento (ida e volta) **desde o início**; (2) **migrações complexas adiadas** até existir necessidade real. **Seguem em aberto [PENDENTE]:** estado inteiro ou só diferenças; formato final; quantidade de slots, autosave e backups; modo sem recarregar após a morte (DEC-065); compatibilidade entre versões depois de um marco de "save congelado"; tamanho máximo e poda. Até lá vale a proposta DEC-084 como padrão de trabalho; o formato final sai do SP5 (LW-028). |
| **Justificativa** | Diretriz 7 de Arthur. |
| **Consequências** | Todo estado novo tem `serialize`, `on_load`, `validate` e teste de ida e volta. Até o "save congelado" (proposta: depois da validação da Fase 4), save de versão antiga é rejeitado com mensagem clara em vez de migrado; o mecanismo de migração e uma migração-exemplo (LW-026) existem desde a Fase 0. |
| **Data / versão** | GDD 0.1 cap. 24.2 · TA 0.1 cap. 18 · RM 0.1 (spike de salvamento, Fase 0) · registrada em 01/11/2026 · mensagem de Arthur de 01/11/2026 15:32 (diretriz 7) |
| **Relações** | DEC-065, DEC-081, DEC-084 |

### DEC-084 — Proposta técnica de salvamento: JSON comprimido, escrita atômica, versão e migrações

| Campo | Conteúdo |
|---|---|
| **Status** | APROVADA (como formato de save do protótipo; ver Consequências para a reavaliação) |
| **Contexto** | É a solução técnica proposta para o problema de DEC-083. |
| **Decisão** | Proposta da TA (18.2 a 18.7, 22): interface `SaveCodec` com JSON comprimido primeiro e binário só se as medições exigirem; escrita atômica; checksum; backups rotativos; versão do formato e migrações; arquivo `save_slot_N.lwsave`; **nunca** carregar `.tres`/`.res` vindos de saves (risco de executar código). |
| **Justificativa** | Legível, depurável e seguro. |
| **Consequências** | Substituível por outro formato sem alterar DEC-083. Armadilhas do JSON (números decimais, chaves em texto) estão descritas na TA 18.3. Na revisão técnica de Godot (v0.2), a gravação "atômica" passou a ser a sequência `.tmp` → `.bak` → final com recuperação, porque o renomear do Godot não é atômico no Windows (TA 18.4); seed e state do gerador aleatório são gravados como texto; hash e checksum são SHA-256. Aprovação de Arthur (01/11/2026): vale como formato do protótipo; **reavaliar binário só se o estado real passar de ~1 MB e a escrita em outra thread (plano B do SP5) não bastar**. Evidência: `docs/decisions/0005-spike-sp5-salvamento.md` (1.000 NPCs: salvar 2,3 ms, carregar 0,9 ms; o custo é linear, ~0,09 ms por KB de JSON). Implementação: LW-026 e LW-027. |
| **Data / versão** | TA 0.1 cap. 18 e 22 · registrada em 01/11/2026 · aprovada por Arthur em mensagem de 01/11/2026, após o spike SP5 (LW-028) |
| **Relações** | DEC-043, DEC-080, DEC-083 |

### DEC-085 — Modelo de multiplayer (se vier a existir)

| Campo | Conteúdo |
|---|---|
| **Status** | PENDENTE **[FUT]** |
| **Contexto** | DEC-018 aprova a possibilidade futura, mas não escolhe modelo. O GDD (23.3) lista modelos; o candidato é cooperativo com anfitrião autoritativo. |
| **Decisão** | **Nada decidido.** Não há decisão de fazer multiplayer, nem de qual tipo. |
| **Justificativa** | Recomendação (TA 23, não aprovada): não tratar antes de o protótipo estar validado. |
| **Consequências** | As premissas arquiteturais baratas de DEC-019 mantêm a possibilidade, sem custo de rede agora. |
| **Data / versão** | GDD 0.1 cap. 23.3 · TA 0.1 cap. 23 · registrada em 01/11/2026 |
| **Relações** | DEC-018, DEC-019 |

### DEC-086 — Framework de testes automatizados

| Campo | Conteúdo |
|---|---|
| **Status** | APROVADA |
| **Contexto** | A arquitetura exige testes automáticos (`check_all`); a LW-010 avaliou GUT 9.7.1. |
| **Decisão** | Arthur aceitou GUT 9.7.1 para testes GDScript no Godot 4.7.2. |
| **Justificativa** | A avaliação headless verificou teste aprovado e falha detectada com códigos 0 e 1. |
| **Consequências** | Usar a versão avaliada; ressalvas e detalhes constam em `docs/decisions/0002-avaliacao-gut.md`. |
| **Data / versão** | TA 0.1 cap. 21 e 26.4 · RM LW-010 · decisão aceita por Arthur nesta conversa |
| **Relações** | DEC-012, DEC-087 |

### DEC-087 — Verificação única (`check_all`), `AGENTS.md` e contratos por módulo

| Campo | Conteúdo |
|---|---|
| **Status** | PROPOSTA |
| **Contexto** | Agentes de IA erram mais quando as regras estão só na conversa. |
| **Decisão** | Proposta da TA (27, 26.2) e do RM: um comando único que roda todas as verificações; um arquivo `AGENTS.md` com as regras do projeto; um contrato curto por módulo. |
| **Justificativa** | Reduz regressões e deriva em relação ao design. |
| **Consequências** | Todo agente deve ler esses arquivos antes de cada tarefa. Este documento (DECISIONS.md) deve ser listado entre as fontes obrigatórias. As oito regras de `check_architecture` têm tarefa de implementação definida no RM 0.15 (v0.2). |
| **Data / versão** | TA 0.1 cap. 27 · RM 0.1 LW-008 e LW-009 · registrada em 01/11/2026 |
| **Relações** | DEC-086, DEC-093 |

### DEC-088 — Controle de versão com Git e cópia remota

| Campo | Conteúdo |
|---|---|
| **Status** | PROPOSTA |
| **Contexto** | Quem não programa precisa poder desfazer erros. |
| **Decisão** | Proposta da TA (2.3) e do RM (0.10): Git; um ramo por tarefa; ramo principal sempre verde; tags por fase; cópia remota atualizada. |
| **Justificativa** | Ponto de retorno seguro. |
| **Consequências** | A hospedagem remota está em DEC-089. |
| **Data / versão** | TA 0.1 cap. 2.3 · RM 0.1 seção 0.10 · registrada em 01/11/2026 |
| **Relações** | DEC-089 |

### DEC-089 — Hospedagem do repositório Git

| Campo | Conteúdo |
|---|---|
| **Status** | APROVADA (somente o serviço) |
| **Contexto** | Escolha do serviço onde fica a cópia remota. |
| **Decisão** | O repositório remoto fica no **GitHub** e **já existe**: não há tarefa de recriação. A **visibilidade (pública ou privada) permanece decisão do proprietário**; decidida na **DEC-114** (04/11/2026): público, por ora, reversível. Enquanto a visibilidade não for decidida, nenhum agente faz push (AGENTS 10) (sem efeito desde a DEC-114, de 04/11/2026). |
| **Justificativa** | Diretriz 14 de Arthur (serviço e existência do repositório). |
| **Consequências** | A visibilidade não bloqueia a primeira implementação: o Codex trabalha na pasta local do projeto. Mudar a visibilidade é ação do dono nas configurações do GitHub. |
| **Data / versão** | TA 0.1 cap. 26.4 · RM 0.1 LW-001 · registrada em 01/11/2026 · mensagem de Arthur de 01/11/2026 15:32 (diretriz 14) |
| **Relações** | DEC-088, DEC-114 |

---

# ÁREA 10 — PROCESSO, ESCOPO E MÉTODO DE TRABALHO

### DEC-090 — Desenvolvimento incremental

| Campo | Conteúdo |
|---|---|
| **Status** | APROVADA |
| **Contexto** | O BM pede "protótipo pequeno, expansível ao longo do tempo" (§2). O pedido do roadmap exige "pequenas tarefas verificáveis" e proíbe antecipar funcionalidades futuras sem necessidade. Arthur pediu o registro expresso de "Desenvolvimento incremental". |
| **Decisão** | O Living World é desenvolvido **de forma incremental**: em passos pequenos, cada um verificável, cada um construído sobre uma base já validada. |
| **Justificativa** | Escolha de Arthur: compatível com um desenvolvedor solo, sem experiência de programação, que depende de agentes de IA e de revisão a cada passo (DEC-092). |
| **Consequências** | Nenhuma tarefa faz mais do que está escrita nela (DEC-096). O RM propõe portões de revisão e validação ao fim de cada fase (proposta, não decisão). |
| **Data / versão** | BM §2 e §9 · PA 01/11/2026 (roadmap e este registro) · registrada em 01/11/2026 |
| **Relações** | DEC-091, DEC-092, DEC-094, DEC-096 |

### DEC-091 — Protótipo antes da expansão

| Campo | Conteúdo |
|---|---|
| **Status** | APROVADA |
| **Contexto** | O BM fixa o escopo: "começar com um protótipo pequeno, expansível ao longo do tempo" (§2). Arthur pediu o registro expresso de "Protótipo antes da expansão". |
| **Decisão** | Constrói-se **primeiro um protótipo pequeno**, e só depois se expande. Nenhum conteúdo ou sistema de expansão é construído antes de o protótipo ser validado. |
| **Justificativa** | Escolha de Arthur: reduz risco, prova a viabilidade e evita investir em escala antes de provar a base. |
| **Consequências** | A **definição de protótipo validado** não está aprovada; existe a proposta de quatro hipóteses e critérios no GDD (DEC-098). A ideia de "expandir" não autoriza antecipar itens de DEC-054. |
| **Data / versão** | BM §2 · PA 01/11/2026 · registrada em 01/11/2026 |
| **Relações** | DEC-054, DEC-090, DEC-098, DEC-101 |

### DEC-092 — Desenvolvimento por uma pessoa sem experiência de programação, com agentes de IA

| Campo | Conteúdo |
|---|---|
| **Status** | APROVADA |
| **Contexto** | O BM fala em "desenvolvedor solo assistido por IA" (§9). Os pedidos da arquitetura e do roadmap descrevem um usuário sem experiência de programação que usa agentes de IA. |
| **Decisão** | O desenvolvimento é conduzido por **uma pessoa sem experiência de programação**, apoiada por **agentes de IA**. |
| **Justificativa** | Fato de projeto declarado por Arthur. |
| **Consequências** | Toda decisão técnica deve ser explicável em linguagem simples, verificável por testes automáticos e executável por agente sem exigir conhecimento de código do usuário. Decisões de Arthur são tomadas sobre resultados e comportamentos, não sobre código. |
| **Data / versão** | BM §9 · PA 01/11/2026 (arquitetura e roadmap) · registrada em 01/11/2026 |
| **Relações** | DEC-006, DEC-073, DEC-093 |

### DEC-093 — Papéis dos agentes: Codex implementa; ChatGPT apoia arquitetura, planejamento e auditoria

| Campo | Conteúdo |
|---|---|
| **Status** | APROVADA |
| **Contexto** | O pedido do roadmap define: "Codex como agente principal de implementação e ChatGPT como apoio de arquitetura, planejamento e auditoria". |
| **Decisão** | **Codex** é o agente principal de implementação. **ChatGPT** apoia arquitetura, planejamento e auditoria. |
| **Justificativa** | Escolha de Arthur. |
| **Consequências** | Os modelos de prompt para o Codex e de auditoria para o ChatGPT (RM Anexos A e B) são propostas. Qualquer agente (inclusive estes) **propõe, não aprova** (regra 0.3). |
| **Data / versão** | PA 01/11/2026 (roadmap) · registrada em 01/11/2026 |
| **Relações** | DEC-087, DEC-092 |

### DEC-094 — Roadmap em seis fases (0 a 5), tarefas pequenas numeradas e pontos de revisão e validação

| Campo | Conteúdo |
|---|---|
| **Status** | APROVADA (a **estrutura**; o conteúdo detalhado do `DEVELOPMENT_ROADMAP.md` é PROPOSTA) |
| **Contexto** | Arthur definiu as fases e as exigências do roadmap. |
| **Decisão** | Fases: **0** Fundação técnica; **1** Primeiro mundo jogável; **2** Primeira sociedade; **3** Economia; **4** Facções e conflitos; **5** Integração e protótipo. Cada fase tem objetivo, pré-requisitos, entregáveis, tarefas, dependências, critérios de aceitação, testes, riscos e definição de concluído. Tarefas pequenas e numeradas (LW-001, LW-002…). O plano inclui pontos de **revisão arquitetural** e de **validação do usuário**. |
| **Justificativa** | Escolha de Arthur. |
| **Consequências** | Esta é a **ordem de fases**: mundo jogável, sociedade, economia, facções e conflitos, integração. Ela substitui a ordem de marcos sugerida pelo GDD (DEC-112). As 192 tarefas, a frequência das revisões, os portões entre fases, o uso de tags e o controle de status do RM são **propostas** (o RM os rotula [REC]). |
| **Data / versão** | PA 01/11/2026 (roadmap) · RM 0.1 · registrada em 01/11/2026 |
| **Relações** | DEC-070, DEC-090, DEC-095, DEC-096, DEC-112 |

### DEC-095 — Sem prazos artificiais

| Campo | Conteúdo |
|---|---|
| **Status** | APROVADA |
| **Contexto** | O pedido do roadmap diz: "Não estabeleça prazos artificiais". |
| **Decisão** | O planejamento **não fixa prazos em datas ou semanas**. O avanço se mede em tarefas concluídas e verificadas. |
| **Justificativa** | Escolha de Arthur. |
| **Consequências** | Nenhum documento deve prometer datas. Relatórios usam porcentagem de tarefas concluídas, por fase. |
| **Data / versão** | PA 01/11/2026 (roadmap) · registrada em 01/11/2026 |
| **Relações** | DEC-090, DEC-094 |

### DEC-096 — Não antecipar funcionalidades futuras sem necessidade

| Campo | Conteúdo |
|---|---|
| **Status** | APROVADA |
| **Contexto** | O pedido do roadmap diz: "Não permita que funcionalidades futuras sejam antecipadas sem necessidade". O pedido do GDD diz: "Não transforme todas as ideias futuras em requisitos obrigatórios do protótipo". |
| **Decisão** | Funcionalidades futuras **não** entram no protótipo nem no código por antecipação. Só entra o que a tarefa em curso exige. |
| **Justificativa** | Escolha de Arthur. |
| **Consequências** | O RM propõe regras práticas (backlog de ideias, provisórios nomeados, nada de preparar o futuro com código). Quando uma tarefa depender de algo ainda não construído, usa-se provisório nomeado e removido por tarefa própria. |
| **Data / versão** | PA 01/11/2026 (GDD e roadmap) · registrada em 01/11/2026 |
| **Relações** | DEC-054, DEC-090, DEC-101 |

### DEC-097 — Disciplina de rótulos: não inventar decisões e distinguir confirmado, proposto, hipótese, pendente e limitação

| Campo | Conteúdo |
|---|---|
| **Status** | APROVADA |
| **Contexto** | O BM §11 proíbe inventar decisões e apresentá-las como aprovadas, e manda diferenciar: decisão confirmada, proposta de design, hipótese, questão pendente e limitação técnica. Também manda apresentar contradições e explicar o que for inviável, propondo alternativas. |
| **Decisão** | Todo documento e todo agente do projeto: (1) separa os cinco tipos de afirmação; (2) **não** apresenta proposta como decisão; (3) expõe contradições; (4) explica inviabilidades com alternativas. |
| **Justificativa** | Escolha de Arthur. Este documento (`DECISIONS.md`) é a aplicação dessa regra aos status APROVADA, PROPOSTA e PENDENTE (seção 0.2). |
| **Consequências** | Os rótulos dos documentos (**[CONF]**, **[REC]**/**[PROP]**, **[HIP]**, **[PEND]**, **[LIM]**) correspondem a: APROVADA (somente com fonte de Arthur), PROPOSTA, hipótese, PENDENTE e limitação. **Um rótulo [CONF] em GDD, TA ou RM não substitui a fonte de Arthur.** |
| **Data / versão** | BM §11 · registrada em 01/11/2026 |
| **Relações** | DEC-005, DEC-006 |

### DEC-098 — Objetivo e conteúdo do protótipo (quatro hipóteses e quadro de conteúdo)

| Campo | Conteúdo |
|---|---|
| **Status** | PROPOSTA (todos os valores **[HIP]**) |
| **Contexto** | O BM pede um protótipo pequeno (DEC-091), mas não diz o que ele contém nem como se prova que deu certo. |
| **Decisão** | Proposta do GDD (24.1 e 24.2). **Hipóteses a provar:** (1) o mundo funciona sem o jogador; (2) os sistemas se comunicam, com cascatas observáveis; (3) o jogador tem opções reais (pelo menos três trajetórias viáveis e combináveis) e deixa marcas persistentes; (4) câmera contínua e LOD de simulação são viáveis em Godot por um desenvolvedor solo. **Conteúdo:** uma região autoral com 12 a 30 províncias lógicas; 1 cidade, 2 a 3 vilas e 1 forte; 2 culturas; 150 a 300 NPCs T1/T2; 3 facções; 2 a 3 polities; 8 a 12 bens e 4 cadeias de produção; 8 a 12 tipos de evento; combate básico; 3 a 4 criaturas e 1 chefe; 3 a 4 origens; câmera em terceira pessoa, tática simples e mapa estratégico; salvamento completo. |
| **Justificativa** | Conjunto mínimo para provar as hipóteses. O protótipo "não tem o objetivo de ser bonito, completo ou longo" (GDD 24.1). |
| **Consequências** | Cada valor tem decisão própria quando relevante: DEC-040, DEC-050, DEC-053, DEC-055, DEC-062, DEC-068, DEC-070, DEC-083. Enquanto não aprovado, este quadro é **referência de trabalho** e não requisito. |
| **Data / versão** | GDD 0.1 cap. 24.1 e 24.2 · registrada em 01/11/2026 |
| **Relações** | DEC-040, DEC-050, DEC-053, DEC-055, DEC-062, DEC-091, DEC-099 |

### DEC-099 — Lista de corte (ordem de sacrifício) e sistemas que não se cortam

| Campo | Conteúdo |
|---|---|
| **Status** | PROPOSTA |
| **Contexto** | Se o escopo apertar, é preciso saber o que sai primeiro. |
| **Decisão** | Proposta do GDD (24.5). **Ordem de corte:** (1) efeitos mágicos; (2) chefe e criaturas especiais; (3) construção e expansão de propriedades; (4) comando tático (mantém mapa estratégico de consulta); (5) facção criminosa completa; (6) eventos de menor impacto. **Não cortar:** economia conectada, NPCs com rotina, ciclo de facções, crônica/"Por quê?", combate básico, LOD de simulação, salvamento. O RM (desvio 5) trata esses itens como fora do roadmap até uma decisão formal na LW-146. |
| **Justificativa** | Preserva o que prova as hipóteses. |
| **Consequências** | A lista só vale quando Arthur a aprovar. Cortar algo fora da lista exige decisão. |
| **Data / versão** | GDD 0.1 cap. 24.5 · RM 0.1 seção 0.13-B (desvio 5) e LW-146 · registrada em 01/11/2026 |
| **Relações** | DEC-029, DEC-030, DEC-062, DEC-068, DEC-098 |

### DEC-100 — Não inventar nomes definitivos sem necessidade; propostas criativas rotuladas

| Campo | Conteúdo |
|---|---|
| **Status** | APROVADA |
| **Contexto** | O pedido do GDD diz: "Não invente nomes definitivos para raças, culturas, regiões, religiões ou personagens sem necessidade. Quando houver necessidade criativa, apresente como proposta." |
| **Decisão** | Nomes definitivos **não** são inventados sem necessidade. Quando for necessário um nome, ele é apresentado **como proposta**. |
| **Justificativa** | Escolha de Arthur. |
| **Consequências** | Dados do protótipo usam nomes genéricos (aplicação proposta no RM 0.13-B, desvio 7). Os nomes definitivos continuam pendentes (DEC-033). |
| **Data / versão** | PA 01/11/2026 (GDD) · registrada em 01/11/2026 |
| **Relações** | DEC-033 |

### DEC-101 — Separação do escopo em visão de longo prazo, sistemas previstos, primeiro protótipo e funcionalidades futuras

| Campo | Conteúdo |
|---|---|
| **Status** | APROVADA |
| **Contexto** | O pedido do GDD manda separar claramente: "Visão de longo prazo; Sistemas previstos; Sistemas do primeiro protótipo; Funcionalidades futuras", e não transformar ideias futuras em requisitos do protótipo. |
| **Decisão** | Todo item do projeto pertence a **um** destes quatro níveis, e o nível deve estar sempre explícito. Ideia futura **não** é requisito do protótipo. |
| **Justificativa** | Escolha de Arthur. |
| **Consequências** | Os rótulos de fase dos documentos ([P1], [PREV], [FUT], [LP]) aplicam essa regra. Ao decidir algo novo, registrar também o nível. |
| **Data / versão** | PA 01/11/2026 (GDD) · registrada em 01/11/2026 |
| **Relações** | DEC-008, DEC-091, DEC-096 |

---

# ÁREA 11 — ALTERNATIVAS DESCARTADAS

> **Atenção ao status.** Os dez descartes abaixo vêm da **TA 1.3 ("O que não adotar")**, que é uma **proposta**. Arthur ainda **não ratificou** nenhum. Valem como **padrão de trabalho** até a ratificação, mas **não** como decisão aprovada. Cada um pode ser reaberto com evidência (por exemplo, resultado de um spike) e decisão de Arthur. O critério geral é DEC-073.

### DEC-102 — Descartada: framework de ECS (entidade-componente-sistema) de terceiros

| Campo | Conteúdo |
|---|---|
| **Status** | DESCARTADA (descarte proposto pela TA; ratificação de Arthur pendente) |
| **Contexto** | ECS é padrão usado para milhares de entidades. |
| **Decisão** | Não adotar addon de ECS. Usar IDs inteiros e tabelas por módulo (DEC-076). |
| **Justificativa** | Dependência extra e curva de aprendizado; o ganho só aparece com muitas entidades "quentes", e o LOD já reduz isso. |
| **Consequências** | Reavaliar **somente** se o spike SP2 mostrar necessidade. |
| **Data / versão** | TA 0.1 cap. 1.3 e 7.4 · registrada em 01/11/2026 |
| **Relações** | DEC-073, DEC-076, DEC-080 |

### DEC-103 — Descartada: contêiner de injeção de dependência

| Campo | Conteúdo |
|---|---|
| **Status** | DESCARTADA (descarte proposto pela TA; ratificação de Arthur pendente) |
| **Contexto** | Padrão comum em sistemas grandes. |
| **Decisão** | Não adotar. Passar referências na inicialização (`setup`). |
| **Justificativa** | Complexidade sem benefício neste projeto. |
| **Consequências** | Nenhuma biblioteca de DI. |
| **Data / versão** | TA 0.1 cap. 1.3 · registrada em 01/11/2026 |
| **Relações** | DEC-073 |

### DEC-104 — Descartada: camadas de abstração "por precaução" (repositórios, fábricas, interfaces para tudo)

| Campo | Conteúdo |
|---|---|
| **Status** | DESCARTADA (descarte proposto pela TA; ratificação de Arthur pendente) |
| **Contexto** | Abstrações sem uso real aumentam o número de arquivos que o agente pode errar. |
| **Decisão** | Abstrair somente quando houver **duas implementações reais**. |
| **Justificativa** | Simplicidade (DEC-073). |
| **Consequências** | Exceções já previstas na TA: `SaveCodec` (dois formatos reais) e `TradeRules` (inversão política/economia). |
| **Data / versão** | TA 0.1 cap. 1.3 · registrada em 01/11/2026 |
| **Relações** | DEC-049, DEC-073, DEC-084 |

### DEC-105 — Descartada: *event sourcing* completo

| Campo | Conteúdo |
|---|---|
| **Status** | DESCARTADA (descarte proposto pela TA; ratificação de Arthur pendente) |
| **Contexto** | Reconstruir todo o estado a partir de eventos. |
| **Decisão** | Não adotar. Usar uma **crônica** de eventos importantes como histórico, não como fonte do estado. |
| **Justificativa** | Caro e difícil de depurar. |
| **Consequências** | O estado é salvo diretamente (DEC-084). |
| **Data / versão** | TA 0.1 cap. 1.3 · registrada em 01/11/2026 |
| **Relações** | DEC-073, DEC-077, DEC-084 |

### DEC-106 — Descartada: microsserviços, rede interna e banco de dados externo

| Campo | Conteúdo |
|---|---|
| **Status** | DESCARTADA (descarte proposto pela TA; ratificação de Arthur pendente) |
| **Contexto** | O jogo é single-player e offline (DEC-017). |
| **Decisão** | Não adotar. |
| **Justificativa** | Sem necessidade em single-player offline. |
| **Consequências** | Pode ser reaberto se um dia houver multiplayer (DEC-085). |
| **Data / versão** | TA 0.1 cap. 1.3 · registrada em 01/11/2026 |
| **Relações** | DEC-017, DEC-085 |

### DEC-107 — Descartada: reflexão e meta-programação

| Campo | Conteúdo |
|---|---|
| **Status** | DESCARTADA (descarte proposto pela TA; ratificação de Arthur pendente) |
| **Contexto** | Técnicas que geram comportamento dinâmico no código. |
| **Decisão** | Não adotar. |
| **Justificativa** | Difíceis de depurar, por humanos e por IA. |
| **Consequências** | Código explícito e rastreável. |
| **Data / versão** | TA 0.1 cap. 1.3 · registrada em 01/11/2026 |
| **Relações** | DEC-073, DEC-092 |

### DEC-108 — Descartada: herança profunda de classes

| Campo | Conteúdo |
|---|---|
| **Status** | DESCARTADA (descarte proposto pela TA; ratificação de Arthur pendente) |
| **Contexto** | Hierarquias longas de classes. |
| **Decisão** | Preferir composição de dados; **máximo de dois níveis** de herança. |
| **Justificativa** | Menos acoplamento. |
| **Consequências** | Os dados dos NPCs e itens são compostos, não herdados. |
| **Data / versão** | TA 0.1 cap. 1.3 · registrada em 01/11/2026 |
| **Relações** | DEC-076 |

### DEC-109 — Descartada: autoload para tudo

| Campo | Conteúdo |
|---|---|
| **Status** | DESCARTADA (descarte proposto pela TA; ratificação de Arthur pendente) |
| **Contexto** | Autoload é o jeito mais fácil de criar variável global no Godot. |
| **Decisão** | Não usar para tudo; no máximo 4 autoloads (DEC-075). |
| **Justificativa** | Vira variável global disfarçada. |
| **Consequências** | Referências passadas explicitamente. |
| **Data / versão** | TA 0.1 cap. 1.3 e 4.3 · registrada em 01/11/2026 |
| **Relações** | DEC-075 |

### DEC-110 — Descartada: *threads* espalhadas pelo projeto

| Campo | Conteúdo |
|---|---|
| **Status** | DESCARTADA (descarte proposto pela TA; ratificação de Arthur pendente) |
| **Contexto** | Paralelismo para ganhar desempenho. |
| **Decisão** | Começar com uma única *thread* para a simulação. |
| **Justificativa** | Fonte clássica de bugs raros e difíceis de reproduzir. |
| **Consequências** | Reabrir **somente** com medição (spike) que prove a necessidade. |
| **Data / versão** | TA 0.1 cap. 1.3 e 20 · registrada em 01/11/2026 |
| **Relações** | DEC-071, DEC-078 |

### DEC-111 — Descartada por ora: GDExtension (C++/Rust)

| Campo | Conteúdo |
|---|---|
| **Status** | DESCARTADA (descarte proposto pela TA; ratificação de Arthur pendente) |
| **Contexto** | Permitiria código nativo para partes críticas. |
| **Decisão** | Não usar. Só considerar **[FUT]** se o *profiler* provar que o GDScript tipado não atende. |
| **Justificativa** | GDScript tipado é decisão de Arthur (DEC-013); outras linguagens aumentam complexidade e risco. |
| **Consequências** | Qualquer uso futuro exige nova decisão de Arthur (DEC-013 passaria a ser parcialmente SUBSTITUÍDA). |
| **Data / versão** | TA 0.1 cap. 1.3 · registrada em 01/11/2026 |
| **Relações** | DEC-013, DEC-071 |

---

# ÁREA 12 — DECISÕES SUBSTITUÍDAS

### DEC-112 — Substituída: ordem dos marcos do GDD (economia, depois sociedade, depois mundo físico)

| Campo | Conteúdo |
|---|---|
| **Status** | SUBSTITUÍDA (pela ordem de fases definida por Arthur — DEC-094) |
| **Contexto** | O GDD (24.4) sugeria os marcos: M0 fundações; M1 economia; M2 sociedade; M3 mundo físico; M4 facções, política e eventos; M5 jogador e combate; M6 câmera e UI; M7 polimento. Em particular, **economia antes de sociedade e de mundo físico**, para validar tudo sem gráficos. |
| **Decisão** | Era uma **proposta** do GDD. Arthur definiu outra ordem no pedido do roadmap: mundo jogável (Fase 1), sociedade (Fase 2) e economia (Fase 3). |
| **Justificativa** | Escolha de Arthur de ver um mundo jogável primeiro. |
| **Consequências** | O RM adotou a ordem de Arthur e criou dois **provisórios (TEMP)** na Fase 2 (estoque simples de comida e renda simbólica), removidos nas tarefas LW-094 e LW-095 e garantidos pelo verificador LW-114. Os marcos M0–M7 continuam úteis só como **mapa** (RM 0.13). O critério de aceite "validar sem gráficos" do GDD (24.4) vale agora só para M0 e para a simulação da Fase 0. |
| **Data / versão** | GDD 0.1 cap. 24.4 · PA 01/11/2026 (roadmap) · RM 0.1 seção 0.13 · registrada em 01/11/2026 |
| **Relações** | DEC-070, DEC-094 |

### DEC-113 — Régua de pico do SP1 (LW-023): release decide, por taxa e com laço de controle

| Campo | Conteúdo |
|---|---|
| **Status** | APROVADA (somente como régua de medição da LW-023, a valer antes de medir o release). A redação foi incorporada à arquitetura (20.1 e 26.3) e ao item da LW-023 no roadmap em 02/11/2026, com autorização de Arthur, depois que o release passou na régua nas 3 execuções; o critério 3 da seção 0.F do roadmap não foi alterado. |
| **Contexto** | O critério original ("sem pico acima de ~10 ms", arquitetura 20.1 e 26.3, roadmap LW-023) não diz a que build se refere e é sensível à sorte: o mesmo código e o mesmo hash deram de 0 a 14 passos acima de 10 ms em execuções iguais, e um laço de controle sem o código do jogo também teve passos acima de 10 ms. |
| **Decisão** | Medir em **build de release**, no hardware de referência, em **3 execuções completas** (1 ano, 1.000 NPCs, mesma semente), cada uma com o **laço de controle** (`run_sp1 --control`). Aprovado quando, em todas: (1) hash idêntico; (2) média por passo ≤ 1 ms e p99,9 ≤ 3 ms; (3) nenhum passo acima de 50 ms; (4) passos acima de 10 ms: no máximo 1 por minuto de execução contínua, ou não mais que a taxa do controle + 1 por minuto, **contado de forma acumulada nas execuções do release: a soma dos passos acima de 10 ms dividida pelo total de minutos medidos** (decisão de Arthur de 02/11/2026, registrada antes de analisar o release; nenhum número muda); (5) os passos acima de 3 ms não se repetem no mesmo passo em 2 ou mais das 3 execuções; passos periódicos conhecidos do módulo de teste são classificados à parte; se não houver nenhum passo acima de 3 ms, o item vale por ausência, e isso é registrado assim (redação da LW-031A, 04/11/2026; nenhum número muda). A régua também registra a taxa de passos acima de 10 ms **por milhão de passos**, além da taxa por minuto (acréscimo da LW-031A; não substitui a taxa por minuto do item 4). Medições em depuração são informativas. Texto completo e aplicação às seis medições do Mac em `docs/decisions/0006-proposta-criterio-de-pico.md`. |
| **Justificativa** | Separa ruído da máquina de custo do código, define o build que decide e mantém um limite duro que protege o jogador. Aprovada antes de medir o release para os números não serem ajustados ao resultado. |
| **Consequências** | Se o release falhar, investiga-se a causa; **os números não são ajustados para caber**. Ponto em aberto resolvido por Arthur em 02/11/2026, antes de analisar o release: o item 4 vale de forma **acumulada** (soma dos passos acima de 10 ms ÷ total de minutos medidos), sem mudar nenhum limite. Os valores numéricos são hipóteses [HIP] calibradas só pelas medições de depuração e da nuvem. |
| **Data / versão** | Proposta de 02/11/2026 · aprovada por Arthur em mensagem de 02/11/2026 · item 5 reescrito e taxa por milhão de passos acrescentada na LW-031A, com autorização de Arthur (04/11/2026) |
| **Relações** | DEC-078, DEC-080, DEC-081 |

---

### DEC-114 — Visibilidade do repositório

| Campo | Conteúdo |
|---|---|
| **Status** | APROVADA |
| **Contexto** | A DEC-089 aprovou só o serviço (GitHub); a visibilidade (pública ou privada) ficou como decisão do proprietário, pendente. |
| **Decisão** | Visibilidade do repositório: **PÚBLICO (por ora)**. |
| **Justificativa** | Arthur só consegue conectar uma conta do GitHub ao Claude por vez; com o repositório público, o revisor externo lê o conteúdo sem precisar de conexão própria. |
| **Consequências** | Decisão **reversível**: a reavaliar antes de qualquer conteúdo sensível entrar no repositório, ou quando houver outro motivo para privá-lo. Vale a regra de sempre: nada de chaves, senhas ou dados pessoais no repositório (AGENTS 10.7). Complementa a DEC-089, que segue aprovada só quanto ao serviço. |
| **Data / versão** | Decidida por Arthur em 04/11/2026 · registrada em 04/11/2026 |
| **Relações** | DEC-089 |

---

### DEC-115 — Câmera padrão: terceira pessoa elevada, de altura média

| Campo | Conteúdo |
|---|---|
| **Status** | APROVADA |
| **Contexto** | As DEC-025 e DEC-026 aprovam a câmera combinada e contínua; faltava a câmera do dia a dia na faixa de terceira pessoa. |
| **Decisão** | A câmera principal do jogo é de **terceira pessoa ELEVADA, de altura média**. É **uma câmera única**, que **gira 360°** em volta do personagem e tem **zoom** para perto e para longe. |
| **Justificativa** | Escolha de Arthur. |
| **Consequências** | A altura e a inclinação exatas são **[HIP]** e são calibradas na LW-046, em constantes nomeadas. Esta é a posição de partida da faixa de terceira pessoa da DEC-028 (que continua PROPOSTA) e **não** decide a câmera tática nem a estratégica. |
| **Data / versão** | Decidida por Arthur em 04/11/2026 · registrada em 05/11/2026 (LW-033A) |
| **Relações** | DEC-025, DEC-026, DEC-027, DEC-028 |

---

### DEC-116 — Controle do personagem: movimento por WASD

| Campo | Conteúdo |
|---|---|
| **Status** | APROVADA |
| **Contexto** | O GDD 21.4 propõe teclado e mouse como entrada primária, mas não define o esquema. |
| **Decisão** | O personagem anda pelas teclas **W, A, S e D**. |
| **Justificativa** | Escolha de Arthur. |
| **Consequências** | Tudo por ações nomeadas (`InputMap`, LW-044); nenhuma tecla fixa no código. O remapeamento segue a prioridade P2 (GDD 21.4). O gamepad continua PENDENTE (DEC-024). Olhar, correr, pular e interagir **não** foram decididos aqui. |
| **Data / versão** | Decidida por Arthur em 04/11/2026 · registrada em 05/11/2026 (LW-033A) |
| **Relações** | DEC-024, DEC-115 |

---

### DEC-117 — Direção do combate: por alvo e habilidades

| Campo | Conteúdo |
|---|---|
| **Status** | APROVADA (somente a **direção**; o sistema definitivo de combate segue PENDENTE na DEC-066, no mesmo estilo da DEC-027) |
| **Contexto** | O GDD 16.2 propunha "mira por direção, sem travar sempre o alvo" (PROPOSTA). |
| **Decisão** | O combate é **por alvo e habilidades**: o jogador **seleciona o inimigo** (clicando nele), o **ataque é automático** contra o alvo e as **habilidades são acionadas pelo jogador**, "mas melhorado", com mais profundidade do que nos jogos padrão. O que significa o "melhorado" está **EM ABERTO**. |
| **Justificativa** | Escolha de Arthur. |
| **Consequências** | Substitui, no GDD 16.2, a proposta de mira por direção. Ritmo, estamina, ferimentos, defesa e o "melhorado" serão explorados no spike SP6 (LW-152), com playtest de Arthur. A DEC-066 permanece PENDENTE; a DEC-067 permanece PROPOSTA e é revista no SP6. |
| **Data / versão** | Decidida por Arthur em 04/11/2026 · registrada em 05/11/2026 (LW-033A) |
| **Relações** | DEC-066, DEC-067 |

---

### DEC-118 — Terreno de teste do protótipo (Fase 1)

| Campo | Conteúdo |
|---|---|
| **Status** | APROVADA |
| **Contexto** | A DEC-055 (PENDENTE) é o portão das tarefas LW-034 a LW-037; o spike SP4a mediu o terreno em cerca de 1 km². |
| **Decisão** | O terreno de teste do protótipo tem **cerca de 1 km²**, em chunks de **cerca de 64 m**, definidos como **dados** em `data/world/` (não como constantes no código). |
| **Justificativa** | Escolha de Arthur; é o tamanho que o SP4a mediu. |
| **Consequências** | **Não** fixa o tamanho final do mundo: a DEC-055 **continua PENDENTE**. Os valores ficam em dados e são fáceis de mudar. Um mundo de vários km exigiria nova medição e dispara a reavaliação do Terrain3D (DEC-057, condição d). |
| **Data / versão** | Decidida por Arthur em 05/11/2026 · registrada em 05/11/2026 (LW-033A) |
| **Relações** | DEC-055, DEC-056, DEC-057, DEC-058 |

---

### DEC-119 — Meta de quadros do protótipo

| Campo | Conteúdo |
|---|---|
| **Status** | APROVADA |
| **Contexto** | A DEC-071 deixou a meta de quadros como decisão de Arthur (valores [HIP]). A LW-033 mediu o terreno; a LW-053A mediu o jogo real em modo release, com o Mac na tomada: média de 8,37 a 8,39 ms por quadro e nenhum quadro acima de 33 ms em 3 execuções. |
| **Decisão** | A meta de quadros do protótipo é: **média de 60 quadros por segundo ou mais e nenhum quadro acima de 33 ms**, no hardware de referência (o Mac de Arthur, DEC-016), na tomada, em modo release. |
| **Justificativa** | Escolha de Arthur, com a medição da LW-053A em mãos (cumprida com folga). |
| **Consequências** | Vale como régua das fases seguintes, inclusive para decoração, gente e mapas maiores. Medidas em depuração ou na bateria servem só para comparar. **Não** decide o orçamento de milissegundos por passo de simulação da DEC-071 (continua PROPOSTA) e **não** fixa o tamanho do mundo (DEC-055). O texto do critério 1.F item 5 em DEVELOPMENT_ROADMAP.md ainda diz "proposta [PEND]": a DEC-119 vale sobre ele. O jogo desenhar 120 quadros por segundo numa tela de 60 Hz só será investigado se Arthur sentir movimento aos trancos (backlog). |
| **Data / versão** | Decidida por Arthur em 07/11/2026 · registrada em 07/11/2026 (LW-053) |
| **Relações** | DEC-016, DEC-055, DEC-057, DEC-071 |

---

### DEC-120 — Direção visual: simples, com a sensação de Albion Online e RuneScape

| Campo | Conteúdo |
|---|---|
| **Status** | APROVADA |
| **Contexto** | A DEC-020 fixa o estilo stylized low-poly, mas não diz quão simples ele deve ser nem em que jogos se inspirar. Depois de jogar o protótipo da Fase 1, Arthur indicou a referência de sensação. |
| **Decisão** | A direção visual do jogo é **estilizada e simples**, com a **sensação** de jogos como **Albion Online e RuneScape**. O jogo **não** busca o acabamento super polido e complexo de jogos como Diablo. |
| **Justificativa** | Escolha de Arthur (07/11/2026): ele gosta desse estilo e não quer o polimento e a complexidade de Diablo. É coerente com a DEC-020, com a câmera elevada da DEC-115 e com a diretriz de evitar o que um desenvolvedor solo assistido por IA não sustenta (AGENTS seção 1, DEC-006). |
| **Consequências** | É uma referência de **sensação**, não de cópia: nenhum modelo, personagem, marca ou arte desses jogos pode ser reproduzido. Orienta as tarefas de arte futuras: o simples vale mais que o elaborado. **Não** decide a origem da arte (a DEC-021 continua PENDENTE) nem paleta, proporções ou número de polígonos. As formas simples provisórias do protótipo (DEC-020) continuam valendo. |
| **Data / versão** | Decidida por Arthur em 07/11/2026 · registrada em 07/11/2026 (LW-054) |
| **Relações** | DEC-006, DEC-020, DEC-021, DEC-115 |

---

### DEC-121 — Combate por alvo e habilidades: resultado do SP6 (ponto de partida)

| Campo | Conteúdo |
|---|---|
| **Status** | APROVADA (somente como **ponto de partida**; o sistema definitivo de combate segue PENDENTE na DEC-066) |
| **Contexto** | O SP6 (LW-152, antecipado pela DEC-080) testou, num duelo 1 contra 1 contra um boneco parado, o laço por alvo e habilidades da DEC-117: clique para escolher o alvo, ataque automático, três habilidades com preparo e recuperação, estamina e bônus por posição (lado e costas). Arthur jogou em 07/11/2026 e não pediu ajuste de valores. |
| **Decisão** | (1) O laço do SP6 (alvo por clique, ataque automático, habilidades com preparo e recuperação, estamina e posição) vale como **bom ponto de partida** para o combate do protótipo: segundo Arthur, o golpe responde, dá para ler o que acontece, o ritmo é bom e a estamina cria decisão. (2) Os valores do teste (tempos, danos, custos, alcance e tolerâncias) são **iniciais [HIP]**: ficam em dados, não em código, e podem ser ajustados. (3) O **inimigo não pode ficar estático**: não deve deixar o jogador bater nas costas sem mais nem menos; deve reagir e se posicionar. (4) Ficam **para depois**: ferimentos por golpe, bloqueio e esquiva, magias, armas e outras habilidades. |
| **Justificativa** | Escolha de Arthur, depois de jogar o SP6 (07/11/2026). As respostas dele, palavra por palavra, estão em `docs/decisions/0008-spike-sp6-combate.md`. |
| **Consequências** | **Não** decide o sistema definitivo (a DEC-066 continua PENDENTE) nem a escala das batalhas (a DEC-053 continua PENDENTE; o teste foi só 1 contra 1). A DEC-067 (PROPOSTA) segue como proposta de trabalho. A posição (lado e costas) **não foi sentida** com o boneco parado: só vale validar com inimigo que reage (Fase 5, LW-153 a LW-155). Ferimentos, bloqueio e esquiva continuam sem teste. As teclas e o botão do mouse do combate entram no `InputActions` oficial na Fase 5. O código do spike é descartável (`tests/soak/sp6/`) e não vira o combate definitivo. |
| **Data / versão** | Decidida por Arthur em 07/11/2026 · registrada em 07/11/2026 (LW-152) |
| **Relações** | DEC-053, DEC-066, DEC-067, DEC-080, DEC-117 |

---

### DEC-122 — Navegação e velocidade dos corpos S0 (resultado do SP2)

| Campo | Conteúdo |
|---|---|
| **Status** | APROVADA (por ora; a N1 será revista quando as construções entrarem como obstáculo, LW-073 e LW-074) |
| **Contexto** | O SP2 (LW-071, `docs/decisions/0009-spike-sp2-corpos-e-lod.md`) testou 100 NPCs que ganham corpo perto do jogador (S0) e voltam a ser dados longe (S1), com duas navegações (N1 reta e N2 grade A\*) e duas políticas de velocidade do corpo (P1 e P2). |
| **Decisão** | (1) Navegação **N1** (rota reta por pontos, recusa acima de 40°) por ora; revisar quando as construções entrarem como obstáculo (LW-073 e LW-074). (2) Velocidade do corpo **P1**: passo natural de 4 m/s [HIP] × velocidade do relógio. |
| **Justificativa** | A N1 passa nas rotas da rotina com 0,07 a 0,45 ms em release; a N2 dá trancos de até 85,9 ms na 1ª rota (execução 4). A P1 é a mais simples, e Arthur viu a velocidade acompanhar o relógio; a P2 andou quase sempre no teto e ainda atrasou a maioria. Escolha de Arthur pelo painel de decisões em 08/11/2026. |
| **Consequências** | A N1 atravessa pedra e recusa morro íngreme sem desvio. A P1 chega sempre atrasada enquanto a DEC-123 não for resolvida. Os valores com [HIP] continuam [HIP]. |
| **Data / versão** | Decidida por Arthur em 08/11/2026 · registrada em 08/11/2026 (LW-071a) |
| **Relações** | DEC-016, DEC-035, DEC-039, DEC-040, DEC-119, DEC-120, DEC-123 |

---

### DEC-123 — Relógio contra corpo: direção P3 (resultado do SP2)

| Campo | Conteúdo |
|---|---|
| **Status** | APROVADA (somente a **direção** P3; os tempos de caminhada só mudam depois do teste de 30 dias e de DEC nova) |
| **Contexto** | A simulação planeja a caminhada a 8400 cm por minuto de jogo (`DEFAULT_WALK_SPEED_CM_PER_MIN`, `src/sim/npc/actions/action_runner.gd:31`), cerca de 67 m/s a 1x; o corpo anda 4 m/s. No SP2: 613 de 691 chegadas atrasadas; com P1, 100% atrasadas, com levado ÷ previsto de 2,45 a 7,22. |
| **Decisão** | Direção **P3**: a simulação passará a acompanhar o corpo, com caminhada em torno de **500 cm/min [HIP]**. Conta: 500 cm/min = 5 m por minuto de jogo; a 1x, 1 minuto = 1,25 s, então 5 ÷ 1,25 = **4 m/s**. A rota A → B (495 m) = 495 ÷ 5 ≈ **99 min de jogo** ≈ 99 × 1,25 ≈ **124 s reais** a 1x. É direção, **não tarefa**: nenhuma tarefa de mudança foi criada. |
| **Justificativa** | Escolha de Arthur pelo painel de decisões em 08/11/2026. **Alternativas rejeitadas por Arthur:** manter os 8400 e aceitar o atraso; tempo limite proporcional ao corpo (quebra a regra de que o mundo não muda porque o jogador olha). |
| **Consequências** | Quando aplicada, muda todos os tempos de caminhada da simulação (16,8 vezes mais longos): a constante `DEFAULT_WALK_SPEED_CM_PER_MIN` (`action_runner.gd:31`), o parâmetro padrão de `_init` (linha 54) e o cálculo de minutos do `go_to_place` (linha 340); `tests/unit/test_action_runner.gd` (`_runner`, linha 79, e `test_go_to_place_takes_the_distance_divided_by_the_walk_speed_rounded_up`, linha 357); `data/intent_params.json` (`intent_timeout_min` = 30 [HIP], a rever). Exige o teste de vida de 30 dias (`tests/soak/npc_life/soak_npc_life_30d.gd`, rodado por `tests/soak/run_npc_life_30d`) e DEC nova. Até lá, nada muda. |
| **Data / versão** | Decidida por Arthur em 08/11/2026 · registrada em 08/11/2026 (LW-071a) |
| **Relações** | DEC-016, DEC-035, DEC-039, DEC-040, DEC-119, DEC-120, DEC-122 |

---

## 3. DÚVIDAS ABERTAS EM DESTAQUE

As cinco dúvidas que Arthur pediu para registrar, mais o que bloqueava o início do trabalho. Os números citados são **hipóteses [HIP]**, não decisões. Pendências só relevantes em fases futuras **não** exigem aprovação antecipada (diretriz 15).

### 3.1 As cinco dúvidas pedidas

| Dúvida | ID | O que existe hoje (não aprovado) | Recomendação (não aprovada) | Quando decidir |
|---|---|---|---|---|
| **Dimensões do mundo** | DEC-055 | Nenhuma dimensão em km. Hipótese de 1 região autoral com 12 a 30 províncias lógicas; chunk de cerca de 64 m e terreno de teste de cerca de 1 km² | Fixar depois do spike do terreno (SP4a) e com hardware-alvo definido | Fase 1, tarefa LW-033 (a LW-033 decidiu só o terreno de teste, na DEC-118; o tamanho final do mundo continua PENDENTE) |
| **Quantidade de NPCs** | DEC-040 | Hipótese de 150 a 300 NPCs T1/T2 em detalhe; "dezenas a poucas centenas" de T2/T3; T0 fora (DEC-041, aprovada) | Medir (spike SP2 e tarefa LW-179) antes de fixar | Fases 2 e 5 |
| **Escala das batalhas** | DEC-053 | Cinco escalas de conflito (proposta); "poucas dezenas" de combatentes corpóreos (hipótese); resto abstrato | Decidir após os spikes SP2 e SP6 | Fase 5, tarefas LW-146 e spike SP6 |
| **Sistema definitivo de combate** | DEC-066 | Proposta de tempo real em terceira pessoa com estamina e ferimentos; ritmo exato em hipótese | Decidir após o spike SP6 (combate) | Fase 5 (a direção por alvo e habilidades foi decidida em 04/11/2026, na DEC-117; o sistema definitivo continua PENDENTE) |
| **Modelo de persistência** | DEC-083 | Princípios aprovados (desde o início; migrações complexas adiadas). Formato: proposta DEC-084 | Validar no spike SP5 antes de fixar o formato | Fase 0 (spike SP5) |

### 3.2 O que bloqueava o início (resolvido na v0.3)

| Dúvida | ID | Situação |
|---|---|---|
| Versão do Godot | DEC-012 | APROVADA: 4.7.x estável (4.6.x se houver impedimento concreto); versão exata registrada na LW-006 |
| Sistema operacional | DEC-015 | APROVADA: macOS |
| Hardware | DEC-016 | Referência: identificada pelo Codex na LW-006. Mínimo: PENDENTE, não bloqueia |
| Idioma do código | DEC-022 | APROVADA: código em inglês; documentação, relatórios e interface em português |
| Hospedagem do Git | DEC-089 | GitHub, repositório já existe. Visibilidade: decidida na DEC-114 (público, por ora) |
| Determinismo | DEC-081 | APROVADA: no mesmo ambiente |
| Framework de testes | DEC-086 | APROVADA: GUT 9.7.1, após avaliação da LW-010 |

**Único pré-requisito prático da primeira tarefa:** o Godot 4.7.x instalado no Mac (LW-002, ação de Arthur).

### 3.3 Pendências de design que serão decididas mais adiante

| Dúvida | ID | Decidir em |
|---|---|---|
| Escolha final das três trajetórias (a meta de três é aprovada) | DEC-062 | LW-146 |
| Morte, ferimentos e derrota | DEC-065 | LW-146 |
| Magia | DEC-030 | LW-146 |
| Profundidade do comando tático e estratégico | DEC-029 | LW-146 |
| Diretor de eventos | DEC-069 | Fase 5 |
| Determinismo | DEC-081 | Decidida na v0.3 (mesmo ambiente) |
| Espécies, tecnologia, nomes e domesticação | DEC-032, DEC-031, DEC-033, DEC-034 | Depois do protótipo |
| Terreno próprio ou addon | DEC-057 | Decidida em 05/11/2026 (APROVADA: terreno próprio), com o resultado do Spike SP4a |
| Arte, telemetria, gamepad, multiplayer e IA generativa | DEC-021, DEC-023, DEC-024, DEC-085, DEC-044 | Depois do protótipo |

---

## 4. CONTRADIÇÕES E DESVIOS CONHECIDOS

> Seguindo DEC-097, as contradições aparecem aqui. Nenhuma foi resolvida por Arthur ainda, a menos que a coluna "Situação" diga o contrário.

| # | Contradição ou desvio | Fontes | Entradas | Situação |
|---|---|---|---|---|
| C1 | **Facções × polities.** O GDD pede 3 facções e 2 a 3 polities, mas só uma das 3 facções é governo. | GDD 24.2 × RM 0.13-B (desvio 4) | DEC-050, DEC-051 | Aberta (decisão em LW-117) |
| C2 | **Trajetórias do protótipo.** O GDD lista 5 (mercador, produtor/artesão, soldado/guarda, aventureiro, crime simples); o RM adota 3 (sem produtor/artesão e sem crime completo). | GDD 24.2 × RM 0.13-B (desvio 3) | DEC-062 | Aberta (decisão em LW-146) |
| C3 | **Ordem de construção.** O GDD sugeria economia antes de sociedade e de mundo físico; Arthur definiu outra ordem. | GDD 24.4 × PA (roadmap) | DEC-094, DEC-112 | **Resolvida por Arthur** (ordem do roadmap vale) |
| C4 | **Eventos dinâmicos.** O GDD os põe no marco M4; o RM os põe na Fase 5. | GDD 24.4 × RM 0.13-B (desvio 8) | DEC-070 | Aberta (proposta do RM) |
| C5 | **T0 / população agregada.** O GDD usa T0 para "o restante da população"; o RM o tira do protótipo. | GDD 24.2 × RM 0.13-B (desvio 2) | DEC-041 | Aberta (proposta do RM; depende de medição) |
| C6 | **Lista de corte.** O GDD trata os 6 itens como "sacrifício se o tempo apertar"; o RM trata 4 deles como fora desde o início. | GDD 24.5 × RM 0.13-B (desvio 5) | DEC-099 | Aberta (decisão em LW-146) |
| C7 | **Rótulos [CONF] sem fonte de Arthur.** O GDD e a TA usam [CONF] em itens que não estão no BM nem em prompts (por exemplo, partes do 24.3 e do 15.7). | GDD, TA × BM | DEC-054, DEC-097 | Tratada: só vale como APROVADA o que consta aqui com fonte de Arthur |
| C8 | **"Godot 4.x" é "inicialmente escolhida".** A TA e o GDD tratam como definitivo. Trocar exige nova decisão de Arthur. | BM §2 × TA 26.1 | DEC-011 | Tratada: APROVADA com a ressalva "inicialmente" |
| C9 | **Câmera seamless × plano B.** O BM exige transição fluida; a TA admite plano B "fatiada" se o spike SP4 falhar. | BM §2 × TA 19.2 | DEC-026, DEC-028 | Em risco: se o plano B for necessário, exige **nova decisão** de Arthur (DEC-026 passaria a SUBSTITUÍDA) |
| C10 | **Salvamento.** O BM não menciona salvamento; o GDD e a TA o tratam como obrigatório. | BM × GDD 24.2 / TA 18 | DEC-083, DEC-084 | Tratada na v0.3: princípios aprovados (DEC-083) |
| C11 | **Origem do personagem × classes.** Origens do GDD não podem virar classes (DEC-003). | BM §1 × GDD 6.2 | DEC-003, DEC-063 | Salvaguarda em DEC-063 |
| C12 | **Determinismo.** O BM diz "simulação determinística como base"; a promessa de replay exato é outra coisa. | BM §7 × GDD D5 | DEC-035, DEC-081 | Resolvida na v0.3: determinismo no mesmo ambiente (DEC-081) |

### 4.1 Os oito desvios do roadmap em relação ao GDD e à arquitetura

Os oito desvios do RM (seção 0.13-B) são **PROPOSTAS**, exceto a ordem das fases (DEC-094), a regra de nomes genéricos (DEC-100) e, desde 01/11/2026 15:32, T0 fora (DEC-041), três trajetórias (DEC-062) e polity simplificada (DEC-051), aprovados por Arthur. Os desvios 5, 6 e 8 valem como padrão de trabalho (seção 0.2) e são decididos mais adiante, nas tarefas citadas nas contradições C1 a C6:

| # | Desvio | Entrada |
|---|---|---|
| 1 | Ordem das fases | DEC-094 (aprovada) e DEC-112 (substituição) |
| 2 | T0 fora até haver necessidade medida | DEC-041 (aprovada) |
| 3 | Três trajetórias | DEC-062 (meta aprovada) |
| 4 | Polity vizinha de baixa resolução | DEC-051 (aprovada) |
| 5 | Itens da lista de corte como fora | DEC-099 |
| 6 | Clima e estações fora | DEC-060 |
| 7 | Dados genéricos, sem nomes definitivos | DEC-100 (regra aprovada) |
| 8 | Eventos dinâmicos na Fase 5 | DEC-070 |

### 4.2 Achados da consolidação documental (v0.2), já corrigidos nos documentos

| # | Achado | Correção feita na v0.2 |
|---|---|---|
| C13 | Legendas [CONF] da TA e do RM aceitavam "GDD" ou "arquitetura" como fonte de confirmação | Legendas redefinidas: [CONF] só vale com status APROVADA aqui |
| C14 | Três formatos de relatório de tarefa (TA 27.4, RM Anexo A, AGENTS 15) | O modelo da seção 15 do AGENTS.md é o único; TA e RM apontam para ele |
| C15 | O RM dizia que o Codex cria ramo e faz commit; o AGENTS exige autorização escrita | RM 0.6, 0.7, 0.10, 0.12 e Anexo A com campos GIT E FERRAMENTAS |
| C16 | Sistema operacional alvo (DEC-015) não aparecia nas pendências da TA nem na LW-001 | Incluído na TA 26.4, no Anexo F e no Anexo G do RM |
| C17 | Critério de aceite da LW-001 vago ("quatro decisões") e uma decisão bloqueante fora dela | LW-001 reescrita com cinco decisões e formato de valor exigido (Anexo G) |
| C18 | Seis das oito regras de `check_architecture` (TA 27.3) não tinham tarefa | RM 0.15 liga cada regra a uma tarefa (LW-012, LW-016, LW-021, LW-036) |
| C19 | Clima e estações: GDD 4.4 e 14 previam clima simples no protótipo; DEC-060 e o RM o excluem | Notas no GDD e na TA; continua PROPOSTA |
| C20 | GDD marcava como [CONF] teclado e mouse (21.4), salvamento (23.1) e construção por NPCs (18.1) | Relabelados como [PROP], com ressalva |
| C21 | RM 0.8 citava a LW-005 para a estrutura de pastas (é a LW-007) | Corrigido |
| C22 | AGENTS exigia que arquivos de `docs/` existissem, mas alguns só nascem na LW-009 | Exceção declarada no AGENTS 2.1 |
| C23 | Ordem dos spikes da TA (SP1, SP3, SP5, SP2, SP4, SP6, SP7) diferente da do RM | Nota na TA 26.3: vale a ordem do RM |


---

## 5. RASTREABILIDADE DOS TEMAS PEDIDOS POR ARTHUR

### 5.1 Temas que ele pediu para registrar

| Tema | Entrada | Status |
|---|---|---|
| Godot 4.x | DEC-011 (versão: DEC-012) | APROVADA (4.7.x; 4.6.x se houver impedimento) |
| GDScript tipado | DEC-013 | APROVADA |
| PC | DEC-014 (sistema operacional: DEC-015) | APROVADA (macOS) |
| Single-player inicial | DEC-017 | APROVADA |
| Possibilidade de multiplayer futuro | DEC-018 (preparo: DEC-019; modelo: DEC-085) | APROVADA (preparo PROPOSTA; modelo PENDENTE) |
| Stylized low-poly | DEC-020 (fonte de arte: DEC-021) | APROVADA (fonte de arte PENDENTE) |
| Universo original de fantasia, história e política | DEC-009 | APROVADA |
| Câmera seamless | DEC-025 e DEC-026 (mecanismo: DEC-028) | APROVADA (mecanismo PROPOSTA) |
| Controle híbrido entre personagem e visão estratégica | DEC-027 (profundidade do comando: DEC-029) | APROVADA (princípio); PENDENTE (profundidade) |
| Simulação híbrida de NPCs | DEC-035 (camadas: DEC-038; decisão: DEC-042) | APROVADA (mecanismos PROPOSTA) |
| IA generativa opcional | DEC-036 (uso concreto: DEC-044) | APROVADA (uso concreto PENDENTE) |
| Desenvolvimento incremental | DEC-090 | APROVADA |
| Protótipo antes da expansão | DEC-091 (conteúdo: DEC-098) | APROVADA (conteúdo PROPOSTA) |

### 5.2 Todas as decisões APROVADAS (lista rápida)

DEC-001, 002, 003, 004, 005, 006, 007, 008 (direção), 009, 011, 012 (condicionada), 013, 014, 015, 016 (só a referência), 017, 018, 020, 022, 025, 026, 027 (princípio), 035, 036, 037, 041, 045, 046, 050 (composição inicial), 051, 057, 062 (meta de três), 072, 073, 080 (só a antecipação de SP6 e SP4a), 081, 082 (só JSON validado), 083 (princípios), 084 (formato de save do protótipo), 086 (GUT 9.7.1), 089 (só o serviço), 090, 091, 092, 093, 094 (estrutura), 095, 096, 097, 100, 101, 113 (só a régua da LW-023), 114 (reversível), 115, 116, 117 (só a direção), 118, 119, 120, 121 (só como ponto de partida), 122 (por ora), 123 (só a direção).

---

## 6. MAPEAMENTO COM AS PENDÊNCIAS E RECOMENDAÇÕES DOS OUTROS DOCUMENTOS

### 6.1 GDD, Anexo D (D1 a D10)

| Item | Pergunta | Entrada |
|---|---|---|
| D1 | Espécies não humanas | DEC-032 |
| D2 | Modelo de morte e derrota | DEC-065 |
| D3 | Magia | DEC-030 |
| D4 | Diretor de eventos | DEC-069 |
| D5 | Determinismo total dos saves | DEC-081 (semente: DEC-079) |
| D6 | Gamepad | DEC-024 |
| D7 | Hardware-alvo mínimo | DEC-016 |
| D8 | Domesticação | DEC-034 |
| D9 | Pólvora | DEC-031 |
| D10 | Nomes, lore e cosmologia | DEC-033 |

### 6.2 Arquitetura, 26.4 (pendências)

| Pendência | Entrada |
|---|---|
| Versão exata do Godot | DEC-012 |
| Hardware-alvo mínimo | DEC-016 |
| Framework de testes | DEC-086 |
| Hospedagem Git | DEC-089 |
| Terreno próprio ou addon | DEC-057 |
| Idioma do código | DEC-022 |
| Telemetria | DEC-023 |
| IA generativa | DEC-044 |
| Sistema operacional alvo (adicionada na TA 0.2) | DEC-015 |

### 6.3 Arquitetura, 26.2 (20 recomendações)

| # | Recomendação | Entrada |
|---|---|---|
| 1 | Separação simulação e apresentação com ponte | DEC-074 |
| 2 | `World` e `SimulationHost` | DEC-075 |
| 3 | Máximo de 4 autoloads | DEC-075 |
| 4 | Entidade = ID inteiro nunca reutilizado | DEC-076 |
| 5 | NPCs simulados como dados | DEC-076 |
| 6 | Três canais, `EventBus` próprio e `cause_id` | DEC-077 |
| 7 | *Signals* só na apresentação | DEC-077 |
| 8 | Passo fixo de 1 minuto e orçamento de ms | DEC-078 |
| 9 | Dinheiro em inteiros e `Ledger` | DEC-047 |
| 10 | RNG único com semente salva | DEC-079 |
| 11 | JSON validado | DEC-082 |
| 12 | Save JSON comprimido, atômico, versionado, migrações | DEC-084 |
| 13 | Nunca carregar `.tres`/`.res` de saves | DEC-084 |
| 14 | Utilidade com catálogo em dados | DEC-042 |
| 15 | Intenções descem e resultados sobem | DEC-074 |
| 16 | `TradeRules` | DEC-049 |
| 17 | Nada de "o jogador" no singular | DEC-019 |
| 18 | `check_all` | DEC-087 |
| 19 | `AGENTS.md` e contratos | DEC-087 |
| 20 | Git com cópia remota | DEC-088 |

---

## 7. MODELO PARA NOVA ENTRADA

Copiar, preencher e usar o próximo número livre (`DEC-124` em diante). **Nunca reutilizar um número.**

```markdown
### DEC-NNN — Título curto

| Campo | Conteúdo |
|---|---|
| **Status** | APROVADA | PROPOSTA | PENDENTE | DESCARTADA | SUBSTITUÍDA |
| **Contexto** | Por que a questão existe. |
| **Decisão** | O que foi decidido (ou "Nada decidido"). |
| **Justificativa** | Por que (ou recomendação, se PENDENTE). |
| **Consequências** | O que muda; o que passa a ser proibido ou obrigatório. |
| **Data / versão** | Fonte (documento e capítulo) · data de registro |
| **Relações** | Outras entradas |
```

**Regras de mudança de status**

| De | Para | Quem e como |
|---|---|---|
| PENDENTE | APROVADA | Arthur decide, por escrito. Preencher "Decisão" com a escolha e citar a fonte (data e mensagem). |
| PROPOSTA | APROVADA | Arthur aprova, por escrito, a proposta específica. |
| PROPOSTA ou PENDENTE | DESCARTADA | Arthur recusa a opção, por escrito. |
| APROVADA | SUBSTITUÍDA | Arthur decide algo diferente. Criar **entrada nova** (número novo) e apontar uma para a outra. **Não apagar a antiga.** |
| Qualquer | PENDENTE | Só se uma evidência nova reabrir a questão. Explicar. |

---

## 8. HISTÓRICO DE ALTERAÇÕES

| Versão | Data (Brasília) | Alteração |
|---|---|---|
| 0.4 | 09/11/2026 | Entradas DEC-113 a DEC-123 criadas desde a 0.3 (LW-023 a LW-071a); totais recontados na LW-071b (APROVADA 62, com 19 com ressalva · PROPOSTA 32 · PENDENTE 18 · DESCARTADA 10 · SUBSTITUÍDA 1 = 123). Esta rodada (LW-071b e LW-071c) não mudou o status de nenhuma entrada. |
| 0.3 | 01/11/2026 | Revisão final e diretrizes de Arthur das 15:32. Passaram a APROVADA (com a ressalva indicada na entrada): DEC-012, 015, 016 (só a referência), 022, 041, 050, 051, 062 (só a meta de três), 080 (só a antecipação de SP6 e SP4a), 081, 083 (só os princípios) e 089 (só o serviço). DEC-081 reintitulada. DEC-070: justificativa corrigida (a alocação às fases é proposta; só os nomes e a ordem das fases são de Arthur). Spikes renomeados de S1-S8 para SP1-SP8 (os níveis de simulação continuam S0-S3). Ressalvas dos status visíveis no índice. Nenhuma entrada criada. |
| 0.2 | 01/11/2026 | Consolidação do pacote documental. Nenhuma entrada mudou de status e nenhuma foi criada. Revisão técnica de Godot 4.x aplicada à TA, ao RM e ao AGENTS (11 correções G1 a G11, ver `CONSISTENCY_REPORT.md` seção 6). Fontes atualizadas para as versões 0.2; consequências das cinco pendências da LW-001 e de DEC-087 ajustadas; seção 4.1 reescrita; nova seção 4.2 (achados C13 a C23). |
| 0.1 | 01/11/2026 | Criação do registro. 112 entradas: decisões do Briefing Mestre e dos prompts de Arthur (APROVADA), propostas dos documentos GDD, arquitetura e roadmap (PROPOSTA), questões abertas (PENDENTE), alternativas recusadas pela arquitetura (DESCARTADA, com ratificação pendente) e a ordem de marcos do GDD (SUBSTITUÍDA). |

