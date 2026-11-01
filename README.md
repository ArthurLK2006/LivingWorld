# Living World

> RPG sandbox 3D de fantasia em que o mundo vive, evolui e tem política, economia e guerras próprias, **com ou sem o jogador**.

*"Living World" é o título de trabalho. O nome comercial ainda não foi decidido (DEC-010).*

| | |
|---|---|
| **Estado atual** | **Fase de planejamento concluída; a implementação começa pela tarefa LW-006.** Ainda não existe jogo, projeto Godot, código nem testes. O que existe é documentação |
| **Versão da documentação** | 0.3 (revisão final de 01/11/2026, horário de Brasília) |
| **Responsável** | Arthur (dono do produto; único que aprova decisões) |
| **Licença** | Ainda não definida |

---

## Índice

1. [Como ler este README](#1-como-ler-este-readme)
2. [Visão geral](#2-visão-geral)
3. [Características principais](#3-características-principais)
4. [Tecnologias](#4-tecnologias)
5. [Estado atual do desenvolvimento](#5-estado-atual-do-desenvolvimento)
6. [Estrutura de diretórios](#6-estrutura-de-diretórios)
7. [Documentos importantes](#7-documentos-importantes)
8. [Como preparar o ambiente](#8-como-preparar-o-ambiente)
9. [Como abrir o projeto no Godot](#9-como-abrir-o-projeto-no-godot)
10. [Como executar os testes](#10-como-executar-os-testes)
11. [Processo de desenvolvimento](#11-processo-de-desenvolvimento)
12. [Regras para contribuições e agentes de IA](#12-regras-para-contribuições-e-agentes-de-ia)

---

## 1. Como ler este README

Este documento separa **três coisas que não podem ser confundidas**:

| Nível | O que é | Onde aparece | Tem garantia de existir? |
|---|---|---|---|
| **Visão de longo prazo** | O jogo que se quer construir um dia | Seções 2 e 3 | **Não.** É direção, não promessa |
| **Protótipo** | Um recorte pequeno, **proposto**, para provar que a ideia funciona | Seção 3.2 | **Não.** Ainda não foi aprovado em detalhe |
| **Estado atual** | O que realmente existe hoje no repositório | Seção 5 | **Sim.** Só consta aqui o que foi verificado |

Tudo o que está descrito nas seções 2, 3 e 11 como funcionalidade **está planejado e não implementado**, salvo menção em contrário na seção 5.

As decisões do projeto têm status oficial no [`docs/DECISIONS.md`](docs/DECISIONS.md): **APROVADA** (decidida por Arthur), **PROPOSTA**, **PENDENTE**, **DESCARTADA** ou **SUBSTITUÍDA**. Quando este README cita uma decisão, indica o número (por exemplo, `DEC-011`).

---

## 2. Visão geral

**Living World** é um RPG sandbox 3D de fantasia com simulação dinâmica de **sociedade, economia, política, organizações, conflitos militares e exploração** (DEC-001).

A ideia central: o mundo é um **ecossistema independente do jogador** e **continua evoluindo mesmo quando o jogador não interfere**. O jogador é **parte** do mundo, não o centro obrigatório dele (DEC-002).

- O jogador **não é necessariamente um escolhido ou herói**. Nasce em um mundo que já existe, com culturas, interesses, conflitos e economias próprias.
- **Não há campanha linear nem classes rígidas.** O jogador constrói a própria trajetória, combina atividades e muda de objetivos ao longo do tempo (DEC-003).
- O universo é **original**, misturando fantasia, história, política e culturas realistas (DEC-009).
- A filosofia é o **equilíbrio entre simulação profunda e jogabilidade divertida** (DEC-007).

### Exemplo do que se quer ver acontecer (visão, **não implementado**)

> Um conflito territorial interrompe uma rota comercial. Isso gera escassez, eleva preços, prejudica comerciantes, reduz recursos de uma facção e influencia decisões políticas, e o jogador consegue ver **por que** tudo isso aconteceu.

### Princípio de design

Toda mecânica relevante deve responder: (1) o que acontece quando o jogador participa; (2) o que acontece quando não participa; (3) como NPCs e organizações reagem; (4) quais sistemas são afetados; (5) que consequências podem surgir; (6) como o mundo registra e mantém essas consequências (DEC-005).

---

## 3. Características principais

### 3.1 Visão de longo prazo (direção, **nada disto está implementado**)

Os oito pilares do mundo (DEC-004): **mundo vivo · liberdade · sociedade · economia · política · guerra · consequências · exploração.**

| Pilar | O que se pretende |
|---|---|
| Mundo vivo | Regiões, cidades, vilas, recursos, culturas, governos, organizações e acontecimentos autônomos |
| Liberdade | Diferentes profissões, objetivos e estilos de vida, sem classes obrigatórias. Entre as trajetórias previstas na visão estão: soldado, mercador, artesão, minerador, fazendeiro, alquimista, explorador, aventureiro, ladrão, líder de facção, governante, diplomata e comandante |
| Sociedade | NPCs com necessidades, ocupações, rotinas, relações, objetivos, personalidade, memória e capacidade de decidir (DEC-037) |
| Economia | Produção, comércio, transporte, consumo, estoques, preços e escassez, todos conectados e com efeitos observáveis (DEC-046) |
| Política | Facções, governos, alianças, disputas, influência e mudanças de poder, com consequências |
| Guerra | Conflitos por território, recursos, interesses políticos e oportunidades |
| Consequências | Ações e omissões do jogador podem alterar personagens, organizações, economias e regiões |
| Exploração | Descoberta, mistérios, tesouros, ambientes perigosos, criaturas e magia |

A visão **admite** combate físico, furtividade, criaturas, chefes, cercos e batalhas de várias escalas. São **possibilidades**; o que entra no jogo ainda depende de decisões (DEC-008). Itens como magia, espécies não humanas, domesticação e nível tecnológico estão **em aberto** (DEC-030 a DEC-034).

### 3.2 Protótipo (recorte **proposto**, ainda não aprovado em detalhe)

O projeto começa por um **protótipo pequeno, expansível ao longo do tempo** (DEC-091). Seu objetivo **proposto** é provar quatro hipóteses (DEC-098):

1. O mundo funciona sem o jogador.
2. Os sistemas se comunicam e geram cascatas observáveis.
3. O jogador tem opções reais e deixa marcas persistentes.
4. A câmera contínua e a simulação por níveis de detalhe são viáveis em Godot por um desenvolvedor solo.

O conteúdo sugerido para o protótipo (uma região, poucos assentamentos, poucas facções, algumas centenas de NPCs, etc.) são **hipóteses**. Em particular, **estão em aberto**: dimensões do mundo (DEC-055), quantidade de NPCs (DEC-040), escala das batalhas (DEC-053), sistema definitivo de combate (DEC-066) e modelo de persistência (DEC-083).

**Fora do protótipo** (proposta): fundação de organizações pelo jogador, cercos, exércitos grandes, intriga, sucessão política, magia ampla, domesticação, múltiplas moedas, famílias e herança, multiplayer, IA generativa, vários continentes e geração procedural (DEC-054).

### 3.3 Decisões já tomadas sobre a experiência

- **Câmera** em terceira pessoa combinada com visão tática e estratégica, com **transição contínua (seamless)** entre escalas (DEC-025, DEC-026). Como implementar isso ainda é uma proposta a validar (DEC-028).
- **NPCs com IA híbrida:** simulação determinística e sistemas comportamentais como base, com memória (DEC-035).
- **IA generativa é opcional**, usada só quando agregar valor e **nunca necessária** para o jogo funcionar (DEC-036).
- **Single-player** primeiro; **multiplayer** é possibilidade futura, **sem obrigação** de existir no protótipo (DEC-017, DEC-018).

---

## 4. Tecnologias

Decisões **aprovadas** por Arthur:

| Item | Escolha | Observação |
|---|---|---|
| Engine | **Godot 4.7.x estável** | DEC-011 e DEC-012. Condicionada à verificação técnica de compatibilidade; só havendo impedimento concreto usa-se uma 4.6.x estável. A versão exata é registrada na LW-006 |
| Linguagem | **GDScript tipado** | Todas as variáveis, parâmetros e retornos com tipo (DEC-013) |
| Plataforma | **PC, com macOS como sistema inicial** | DEC-014 e DEC-015. Outros sistemas: futuro |
| Modo | **Single-player** | Multiplayer apenas como possibilidade futura (DEC-017, DEC-018) |
| Visual | **Stylized low-poly** | Fonte de arte, modelos e áudio ainda não definida (DEC-020, DEC-021) |
| Idioma | **Código e identificadores em inglês; documentação, relatórios e interface em português** | DEC-022. O glossário português ↔ identificador está no GDD, Anexo E |
| Repositório | **GitHub** (já existe) | DEC-089. A visibilidade (pública ou privada) é decisão do proprietário |

**Ainda pendentes** (não assuma; nenhuma bloqueia o início): hardware mínimo (DEC-016; o hardware de referência é identificado na LW-006), visibilidade do repositório (DEC-089), framework de testes (DEC-086, LW-010), terreno próprio ou addon (DEC-057, LW-033), gamepad (DEC-024), telemetria (DEC-023).

A arquitetura técnica (camadas, módulos, formato de dados e de save) está **proposta** em [`docs/TECHNICAL_ARCHITECTURE.md`](docs/TECHNICAL_ARCHITECTURE.md). Em resumo: simulação totalmente separada da apresentação visual, dados de conteúdo em arquivos validados, comunicação por eventos e testes automáticos sem abrir a janela do jogo. O que dessa proposta já foi aprovado e o que não foi está em `docs/DECISIONS.md`.

---

## 5. Estado atual do desenvolvimento

**Data da informação:** 01/11/2026, 15:32 em diante (Brasília).

### 5.1 O que existe hoje

| Item | Situação |
|---|---|
| Briefing Mestre (visão do projeto) | Escrito por Arthur |
| `BRIEFING_MESTRE.md` (cópia fiel do briefing original) | Pronto |
| `GDD.md` (design do jogo) | **Documento v0.3 pronto** |
| `TECHNICAL_ARCHITECTURE.md` | **Documento v0.3 pronto** |
| `DEVELOPMENT_ROADMAP.md` | **Documento v0.3 pronto** (192 tarefas, 6 fases) |
| `DECISIONS.md` | **Documento v0.3 pronto** (registro oficial de decisões) |
| `AGENTS.md` | **Documento v0.3 pronto** (regras para agentes de IA) |
| `CONSISTENCY_REPORT.md` | Relatório de consistência documental (v0.2, com a seção da revisão v0.3) |
| `README.md` | Este arquivo |

### 5.2 O que **não** existe ainda

| Item | Situação |
|---|---|
| Projeto Godot (`project.godot`) | **Não criado** (previsto na tarefa LW-006) |
| Código GDScript | **Nenhum** |
| Cenas, terreno, personagem, câmera | **Nenhum** |
| NPCs, economia, política, facções, combate | **Nenhum** |
| Salvamento e carregamento | **Nenhum** |
| Testes automáticos e o comando `tools/check_all` | **Não existem** |
| Godot instalado e ambiente do Codex | **A confirmar** (instalação na LW-002; verificação na LW-006). O repositório GitHub já existe |
| Executável jogável | **Não existe** |

### 5.3 Fase atual

O roadmap tem **6 fases e 192 tarefas** (`LW-001` a `LW-192`). Nenhuma foi executada.

| Fase | Nome | Tarefas | Situação |
|---|---|---|---|
| 0 | Fundação técnica | 31 | **Não iniciada** (0 de 31) |
| 1 | Primeiro mundo jogável | 23 | Não iniciada |
| 2 | Primeira sociedade | 32 | Não iniciada |
| 3 | Economia | 30 | Não iniciada |
| 4 | Facções e conflitos | 29 | Não iniciada |
| 5 | Integração e protótipo | 47 | Não iniciada |

**Decisões iniciais (LW-001):** concluídas em 01/11/2026. **Próximos passos:** Arthur instala o Godot 4.7.x (LW-002) e coloca estes documentos na pasta do projeto (LW-003); depois, o Codex executa a **LW-006** (projeto Godot e primeira cena 3D). As LW-004 e LW-005 foram dispensadas.

> Quando o trabalho avançar, o acompanhamento passa a ser mantido em `docs/ROADMAP_STATUS.md`, e esta seção deve ser atualizada **somente** com o que estiver verificado.

---

## 6. Estrutura de diretórios

### 6.1 Hoje

Atualmente o repositório contém **apenas documentação**: `README.md` e `AGENTS.md` na raiz, e em `docs/` o briefing mestre, o GDD, a arquitetura, o roadmap, as decisões e o relatório de consistência.

### 6.2 Estrutura **planejada** (ainda não existe)

Proposta da arquitetura (cap. 2). Será criada aos poucos, **cada pasta só na tarefa que a exige**:

```
living-world/
├── README.md                ← este arquivo
├── AGENTS.md                ← regras para agentes de IA
├── project.godot            ← projeto Godot (planejado, LW-006)
├── docs/
│   ├── BRIEFING_MESTRE.md   ← briefing original de Arthur (cópia fiel)
│   ├── GDD.md
│   ├── TECHNICAL_ARCHITECTURE.md
│   ├── DECISIONS.md
│   ├── DEVELOPMENT_ROADMAP.md
│   ├── CONSISTENCY_REPORT.md ← relatório de consistência documental
│   ├── ROADMAP_STATUS.md    ← acompanhamento (planejado)
│   ├── events.md            ← catálogo de eventos (planejado)
│   ├── backlog.md           ← ideias fora do escopo (planejado)
│   ├── decisions/           ← registros técnicos curtos (planejado)
│   └── modules/             ← contrato de cada módulo (planejado)
├── data/                    ← conteúdo do jogo em arquivos de dados (planejado)
├── src/
│   ├── app/  core/  data/   ← base do jogo (planejado)
│   ├── sim/                 ← SIMULAÇÃO, sem elementos visuais (planejado)
│   ├── persistence/         ← salvar e carregar (planejado)
│   ├── bridge/              ← ponte entre simulação e visual (planejado)
│   ├── presentation/        ← o que o jogador vê e usa (planejado)
│   └── tools/               ← ferramentas de depuração (planejado)
├── scenes/  assets/  addons/
├── tests/                   ← unit, integration, soak, fixtures (planejado)
└── tools/                   ← comandos de verificação (planejado)
```

A ideia-chave: a pasta `src/sim/` (o "mundo") **não conhece** `src/presentation/` (o "visual"). Isso permite testar e rodar o mundo sem abrir o jogo.

---

## 7. Documentos importantes

Leia nesta ordem se for a primeira vez:

| Ordem | Documento | Para que serve | Versão |
|---|---|---|---|
| 1 | [`README.md`](README.md) | Porta de entrada (este arquivo) | 0.3 |
| 2 | [`docs/DECISIONS.md`](docs/DECISIONS.md) | **Fonte oficial** do que está aprovado, proposto, pendente, descartado ou substituído. Prevalece sobre os demais em questão de status | 0.3 |
| 3 | [`AGENTS.md`](AGENTS.md) | Regras obrigatórias de trabalho para agentes de IA (Codex etc.) | 0.3 |
| 4 | [`docs/GDD.md`](docs/GDD.md) | **O que** construir: design do jogo, sistemas, escopo do protótipo | 0.3 |
| 5 | [`docs/TECHNICAL_ARCHITECTURE.md`](docs/TECHNICAL_ARCHITECTURE.md) | **Como** construir: módulos, camadas, dados, testes, riscos técnicos | 0.3 |
| 6 | [`docs/DEVELOPMENT_ROADMAP.md`](docs/DEVELOPMENT_ROADMAP.md) | **Em que ordem**: fases e tarefas `LW-NNN` | 0.3 |
| 7 | [`docs/BRIEFING_MESTRE.md`](docs/BRIEFING_MESTRE.md) | O briefing original de Arthur, origem das decisões APROVADAS | sem versão |
| 8 | [`docs/CONSISTENCY_REPORT.md`](docs/CONSISTENCY_REPORT.md) | Problemas encontrados na consolidação (v0.2) e como a revisão final (v0.3) os tratou | 0.3 |

**Hierarquia de autoridade** (resumo; detalhes no `AGENTS.md`, seção 3): instrução atual de Arthur → `DECISIONS.md` (decisões aprovadas) → `AGENTS.md` → arquitetura → GDD → contrato do módulo → tarefa. **Um rótulo "confirmado" em GDD, arquitetura ou roadmap só vale se `DECISIONS.md` mostrar a decisão como APROVADA.**

Convenção dos rótulos usados nos documentos: **[CONF]** confirmado · **[REC]/[PROP]** recomendação ou proposta · **[HIP]** hipótese · **[PEND]** pendente · **[LIM]** limitação · **[FUT]** futuro.

---

## 8. Como preparar o ambiente

> **Ainda não é possível rodar nada.** Esta seção descreve a sequência da Fase 0 do roadmap. **Não instale nada além do Godot 4.7.x, e só na tarefa LW-002.**

| Passo | Tarefa | Quem | O que acontece |
|---|---|---|---|
| 1 | LW-001 | Arthur | **Concluída:** versão do Godot, macOS, idioma, GitHub e hardware de referência decididos em 01/11/2026 |
| 2 | LW-002 | Arthur | Instala o **Godot 4.7.x estável** (versão padrão, GDScript, sem .NET) no Mac |
| 3 | LW-003 | Arthur | Coloca estes documentos (`README.md` e `AGENTS.md` na raiz, o resto em `docs/`) na pasta do projeto, que é o repositório GitHub clonado. Sem envio ao remoto |
| 4 | LW-006 | Codex | Verifica o Godot, identifica o hardware, cria o projeto, a primeira cena 3D e um teste rápido. Detalhes e comandos na LW-006 do roadmap |

**Requisitos:** Mac com macOS · Godot 4.7.x estável · Git · acesso ao agente de implementação (Codex). O hardware de referência é o seu Mac, identificado pelo Codex na LW-006.

Quando o ambiente existir, esta seção será atualizada com o passo a passo real.

---

## 9. Como abrir o projeto no Godot

> **Ainda não há projeto Godot para abrir.** O arquivo `project.godot` e a primeira cena 3D serão criados na tarefa LW-006.

Procedimento previsto, depois disso:

1. Instalar o Godot **na versão exata** registrada na LW-006 (`docs/decisions/0001-ambiente-de-referencia.md`); usar outra versão pode quebrar o projeto.
2. Abrir o Godot e, no gerenciador de projetos, escolher **Importar**.
3. Selecionar o arquivo `project.godot` na raiz do repositório.
4. Abrir o projeto. Antes da primeira execução, conferir se o editor mostra a versão esperada. Em um clone novo, rode antes uma vez `godot --headless --path . --import` (a pasta `.godot/`, com o cache dos scripts, não vai para o Git).

A cena da LW-006 é só de verificação (piso, cubo, céu e sol). Cenas jogáveis só existirão a partir da Fase 1.

---

## 10. Como executar os testes

> **Ainda não existem testes nem o comando `tools/check_all`.** Nada aqui pode ser executado hoje.

O que está **planejado** (arquitetura cap. 21 e roadmap):

- Um comando único, **`tools/check_all`**, que roda em sequência: verificação de arquitetura → validação de dados → testes unitários → testes de integração → simulação longa curta ("soak").
- Resultado simples: **verde** (tudo certo) ou **vermelho** (lista do que falhou).
- Os testes automáticos rodarão **sem abrir a janela do jogo** (modo *headless* do Godot).
- Até a LW-010 (DEC-086, pendente) o único teste é o `tools/smoke_test.gd` da LW-006; o framework de testes é escolhido na LW-010.
- Haverá também **testes manuais** (checklists curtas) para Arthur jogar e conferir, ao fim de cada fase.

Regra do projeto: **nenhum agente pode declarar teste aprovado sem ter executado** (ver `AGENTS.md`, seção 9).

---

## 11. Processo de desenvolvimento

O desenvolvimento é **incremental**, em **tarefas pequenas e verificáveis**, **sem prazos artificiais**, e **sem antecipar funcionalidades futuras** (DEC-090, DEC-095, DEC-096). O trabalho é feito por **uma pessoa sem experiência de programação** (Arthur), com agentes de IA: **Codex** implementa; **ChatGPT** apoia arquitetura, planejamento e auditoria (DEC-092, DEC-093).

### Fases (decididas por Arthur, DEC-094)

0. **Fundação técnica** — projeto Godot, documentação, estrutura, Git, cena inicial, padrões e testes.
1. **Primeiro mundo jogável** — terreno, ambiente, personagem, câmera, movimentação, colisões e interação.
2. **Primeira sociedade** — NPCs, rotinas, necessidades, profissões, relações e comportamentos.
3. **Economia** — produção, recursos, estoques, comerciantes, preços, compra, venda e transporte.
4. **Facções e conflitos** — organizações, hierarquias, reputação, política, diplomacia e disputas territoriais.
5. **Integração e protótipo** — combate, interface estratégica, eventos, consequências, persistência e otimização.

### Ciclo de cada tarefa (proposta do roadmap)

1. Arthur escolhe a próxima tarefa `LW-NNN` e entrega o prompt ao Codex.
2. O Codex lê as regras e os documentos, implementa, testa e entrega um **relatório padrão**.
3. O relatório passa por **auditoria** (ChatGPT ou outra IA revisora).
4. Arthur **aprova**. Só então a tarefa é considerada concluída e a próxima pode começar.

Ao fim de cada fase há uma **revisão arquitetural** e uma **validação de Arthur**; a fase seguinte só começa depois de ambas aprovadas.

### Como as decisões são tomadas

Agentes **propõem, nunca aprovam**. Decisão pendente ou proposta que precise mudar é levada a Arthur com uma recomendação; ao ser decidida, vira entrada nova em `docs/DECISIONS.md`, sem apagar a anterior.

---

## 12. Regras para contribuições e agentes de IA

### 12.1 Agentes de IA (Codex ou outros)

**Leitura obrigatória antes de qualquer tarefa: [`AGENTS.md`](AGENTS.md).** Resumo das regras que valem sempre:

- Ler os documentos relevantes antes de cada tarefa.
- **Não inventar decisões de design** nem modificar o escopo sem autorização.
- Não instalar ferramentas, não usar serviços pagos e não adicionar dependências sem autorização.
- Não modificar arquivos fora da raiz do projeto e não sobrescrever arquivos sem verificar o conteúdo.
- Não remover funcionalidades sem justificativa e aprovação.
- **Não fazer commit nem push sem autorização explícita.**
- **Não declarar testes aprovados sem executá-los** e **não ocultar falhas**.
- Ao terminar, entregar o relatório padrão e **parar**: não avançar para a próxima tarefa sem aprovação.

### 12.2 Pessoas

O projeto é conduzido por Arthur. Ainda **não há processo definido para contribuições externas**; antes de propor qualquer mudança, fale com ele. Quem editar a documentação deve respeitar a regra de ouro:

> **Não transforme sugestões em decisões aprovadas.** Só entra como APROVADA em `docs/DECISIONS.md` o que Arthur decidiu por escrito.

### 12.3 Dúvidas e conflitos

Se dois documentos se contradizem, **não escolha em silêncio**: descreva o conflito, recomende uma saída e leve a Arthur. As contradições conhecidas hoje estão registradas na seção 4 de `docs/DECISIONS.md`.

---

*Living World — README v0.3 — 01/11/2026. Atualize a seção 5 somente com fatos verificados.*
