# Living World

> RPG sandbox 3D de fantasia em que o mundo vive, evolui e tem política, economia e guerras próprias, **com ou sem o jogador**.

*"Living World" é o título de trabalho. O nome comercial ainda não foi decidido (DEC-010).*

| | |
|---|---|
| **Estado atual** | **Fase 2 (primeira sociedade) EM ANDAMENTO: 27 de 32 tarefas concluídas (84,4%): a LW-055 (contratos do módulo `npc`, extensão do `world` e catálogo de eventos, só documentos), a LW-056 (assentamentos e locais no `world`, com dois povoados de teste), a LW-074 (uma caixa colorida por local, na tela), a LW-057 (estado do NPC e módulo `npc`), a LW-058 (as cinco necessidades) e a LW-059 (catálogo de ações em dados), aprovadas por Arthur em 07/11/2026, mais da LW-060 à LW-071 e da LW-076 à LW-081 (18 tarefas; as costuras LW-070a a LW-070d, sem linha no roadmap, não entram na conta), aprovadas por Arthur em 08/11/2026, e a LW-072 (os corpos dos NPCs na tela) e a LW-075 (o teste de equivalência entre a ação abstrata e a ação com corpo), aprovadas por Arthur em 09/11/2026, e a LW-083 (a conversa do jogador com um NPC: a tecla de interação, a parada do NPC, a promoção a T2 e a relação e a memória gravadas), que entrou no `main` na noite de 09/11/2026 por autorização antecipada de Arthur, com as subtarefas 083d a 083f ainda sem a auditoria dele e a conversa ainda não vista na janela. Fase 1 (primeiro mundo jogável) CONCLUÍDA: 23 de 23 tarefas concluídas (100%), tag `fase-1-concluida` no remoto, em `ac4c61f` (07/11/2026); avanço total do projeto: 82 de 192 tarefas (42,7%, contando o SP6, LW-152, antecipado).** A Fase 0 (fundação técnica) está concluída: 31 de 31 tarefas concluídas ou dispensadas, tag `fase-0-concluida` no remoto (aprovação de Arthur em 03/11/2026). Existem o projeto Godot, o núcleo da simulação sem janela, leitura de dados, salvamento e a verificação `tools/check_all`; o SP4a (medição de terreno) existe como código descartável em `tests/soak/sp4a`. O terreno de teste de 1 km² já aparece na tela, com colisão (LW-038 e LW-039), carregado só em volta do jogador (LW-040), com céu, luz que segue a hora simulada (dia e noite), árvores e pedras e um mapa de teclas por ações nomeadas (LW-041 a LW-044). Já dá para andar, correr e pular com um personagem provisório (uma cápsula laranja, LW-045), visto de uma câmera de terceira pessoa que gira e dá zoom (LW-046), com limites de inclinação, borda do mapa e queda (LW-047). O personagem relata a posição à simulação (LW-048), dá para interagir com dois pontos de interesse de teste (LW-049 e LW-050), um HUD mostra data, hora, pausa e velocidade e a pausa congela o personagem (LW-051). Dois povoados de teste aparecem sobre o terreno como 36 caixas coloridas, uma por local (LW-056 e LW-074). O módulo `npc` já existe em código e testes (estado do NPC, as cinco necessidades e o catálogo de ações em dados, LW-057 a LW-059), e os NPCs que estão a menos de cerca de 80 m do jogador já aparecem na tela como cápsulas provisórias que andam entre os locais (LW-072; no máximo 50 ao mesmo tempo, rota reta que atravessa pedra e casa, sem animação além de andar e parar). Também dá para conversar com o NPC ao alcance, pela tecla de interação (LW-083; o teste de ponta a ponta passa, mas isso ainda não foi visto na janela). **Ainda não há jogo jogável** (faltam, entre outras coisas, economia, combate, menus e salvamento pela tela). Veja a seção 5 |
| **Versão da documentação** | 0.3 (revisão final de 01/11/2026, horário de Brasília); seções 5, 6.1 e 8 a 10 atualizadas em 02/11/2026 |
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
| Engine | **Godot 4.7.x estável** | DEC-011 e DEC-012. Versão exata em uso: **4.7.2 estável**, registrada em `docs/decisions/0001-ambiente-de-referencia.md` |
| Linguagem | **GDScript tipado** | Todas as variáveis, parâmetros e retornos com tipo (DEC-013) |
| Plataforma | **PC, com macOS como sistema inicial** | DEC-014 e DEC-015. Outros sistemas: futuro |
| Modo | **Single-player** | Multiplayer apenas como possibilidade futura (DEC-017, DEC-018) |
| Visual | **Stylized low-poly** | Fonte de arte, modelos e áudio ainda não definida (DEC-020, DEC-021) |
| Idioma | **Código e identificadores em inglês; documentação, relatórios e interface em português** | DEC-022. O glossário português ↔ identificador está no GDD, Anexo E |
| Repositório | **GitHub** (já existe) | DEC-089 (aprovada só quanto ao serviço). A visibilidade foi decidida na DEC-114 (04/11/2026): **público, por ora**, reversível |

**Ainda pendentes** (não assuma; nenhuma bloqueia o início): hardware mínimo (DEC-016; só o hardware de referência está aprovado), gamepad (DEC-024), telemetria (DEC-023). O framework de testes já foi decidido: GUT 9.7.1 (DEC-086, aprovada). O terreno do protótipo também já foi decidido: terreno próprio, e não o addon (DEC-057, 05/11/2026).

A arquitetura técnica (camadas, módulos, formato de dados e de save) está **proposta** em [`docs/TECHNICAL_ARCHITECTURE.md`](docs/TECHNICAL_ARCHITECTURE.md). Em resumo: simulação totalmente separada da apresentação visual, dados de conteúdo em arquivos validados, comunicação por eventos e testes automáticos sem abrir a janela do jogo. O que dessa proposta já foi aprovado e o que não foi está em `docs/DECISIONS.md`.

---

## 5. Estado atual do desenvolvimento

**Data da informação:** 06/11/2026 (Brasília). Fonte do detalhe: [`docs/ROADMAP_STATUS.md`](docs/ROADMAP_STATUS.md).

### 5.1 O que existe hoje

| Item | Situação |
|---|---|
| Documentos de planejamento (briefing, GDD, arquitetura, roadmap, decisões, regras para agentes) | Prontos (v0.3) |
| Projeto Godot 4.7.2 (`project.godot`) e cena inicial | Existem. A cena mostra o terreno de teste de 1 km² (planície, colina, vale e caminho, com colisão por chunk, carregado só em volta do jogador), com céu, sol com sombras e névoa que seguem a hora simulada (dia e noite) e árvores e pedras sobre a grama, e o HUD (título, versão, data e hora simuladas, pausa ou velocidade), mais um morro íngreme de teste (LW-047A) e dois marcadores de interação (LW-049 e LW-050). Um personagem provisório (cápsula laranja) anda, corre e pula sobre o terreno, visto de uma câmera de terceira pessoa elevada. As teclas são ações nomeadas do `InputMap`: W, A, S e D andam, Shift esquerdo corre, Espaço pula, o botão direito do mouse arrastado e as setas giram a câmera, a roda dá zoom, E interage com o ponto de interesse próximo, 1 e 2 mudam a velocidade do relógio e P pausa o relógio e congela o personagem (a câmera continua girando) |
| Núcleo da simulação (`src/core`) | Relógio, sorteios repetíveis, IDs, eventos, agendador, mundo e hash de estado, todos testados e rodando **sem janela** |
| Dados (`src/data`) | Leitor e validador de arquivos JSON |
| Salvamento (`src/persistence`) | Salvar e carregar com checksum, versões, migração, backups e recuperação |
| Testes e verificação | `tools/check_all` (arquitetura em 9 verificações, teclas fixas, dados, testes automáticos, cena e simulação). Verificado em 07/11/2026 no commit de código `eac0ffd` (LW-047A, ramo `lw-047a-trecho-ingreme`): **verde no Mac, com 471 testes** (a nuvem não foi repetida desde 03/11/2026, quando deu verde com 154 testes). No Windows (que não é a plataforma de referência) terminou vermelho em 03/11/2026 por três linhas das próprias ferramentas de verificação; detalhes em [`docs/fase-0/LW-031-relatorio-de-fechamento.md`](docs/fase-0/LW-031-relatorio-de-fechamento.md) |
| Medições (spikes) | Núcleo (SP1), dados (SP3), salvamento (SP5), terreno (SP4a) e combate (SP6, LW-152, jogado por Arthur) registrados em `docs/decisions/` |
| Revisão e validação da Fase 0 | Revisão arquitetural aceita (aprovada com ajustes, 0 achados críticos), validação assinada por Arthur com ressalvas e fechamento da fase (LW-031) aprovado, os três em 03/11/2026 |

### 5.2 O que **não** existe ainda

| Item | Situação |
|---|---|
| Personagem e câmera de jogo definitivos | **Só os provisórios** (Fase 1): uma cápsula laranja que anda, corre e pula, com limites de inclinação, borda do mapa e queda (LW-045 e LW-047), e uma câmera de terceira pessoa elevada, com órbita e zoom (LW-046). Ainda sem animação; o corpo relata a posição à simulação (LW-048), interage com pontos de interesse de teste (LW-049 e LW-050) e congela com a pausa (LW-051). O SP4a segue como código descartável de medição em `tests/soak/sp4a` |
| NPCs, economia, política, facções, combate | **NPCs só provisórios:** 100 NPCs de teste nos dois povoados de teste, com necessidades, rotina por ofício e relações (e memória nos notáveis), que perto do jogador aparecem como cápsulas (LW-057 a LW-083). Economia, política, facções e combate: **nenhum** de verdade |
| Conteúdo do jogo em `data/` | **Nenhum** de verdade (só o terreno de teste de blockout em `data/world/`, LW-037, e dados de teste em `tests/fixtures/`) |
| Executável jogável | **Não existe** |

### 5.3 Fase atual

O roadmap tem **6 fases e 192 tarefas** (`LW-001` a `LW-192`).

| Fase | Nome | Tarefas | Situação |
|---|---|---|---|
| 0 | Fundação técnica | 31 | **Concluída** (31 de 31 concluídas ou dispensadas; tag `fase-0-concluida` criada e no remoto, em `7ae6e8e`, 03/11/2026) |
| 1 | Primeiro mundo jogável | 23 | **Concluída** (23 de 23 concluídas, 100%; tag `fase-1-concluida` criada e no remoto, em `ac4c61f`, 07/11/2026: LW-032, LW-033, LW-034, LW-035, LW-036, LW-037, LW-038, LW-039, LW-040, LW-041, LW-042, LW-043, LW-044, LW-045, LW-046, LW-047, LW-048, LW-049, LW-050, LW-051, LW-052, LW-053 e LW-054) |
| 2 | Primeira sociedade | 32 | **Em andamento** (27 de 32 concluídas, 84,4%: LW-055, contratos do `npc`, extensão do `world` e catálogo de eventos, só documentos; LW-056, assentamentos e locais no `world`; LW-074, uma caixa colorida por local; LW-057, estado do NPC e módulo `npc`; LW-058, as cinco necessidades; LW-059, catálogo de ações em dados; aprovadas por Arthur em 07/11/2026; mais LW-060 a LW-071 e LW-076 a LW-081 (18 tarefas; as costuras LW-070a a LW-070d, sem linha no roadmap, não entram na conta), aprovadas por Arthur em 08/11/2026; mais LW-072, os corpos dos NPCs na tela, e LW-075, o teste de equivalência entre a ação abstrata e a ação com corpo, aprovadas por Arthur em 09/11/2026; mais LW-083, a conversa do jogador com um NPC, que entrou no `main` na noite de 09/11/2026 por autorização antecipada de Arthur) |
| 3 | Economia | 30 | Não iniciada |
| 4 | Facções e conflitos | 29 | Não iniciada |
| 5 | Integração e protótipo | 47 | Não iniciada |

A Fase 1 está **concluída**: a LW-032 (contratos mínimos), a LW-033 (spike SP4a do terreno), a LW-034 (dados do terreno e lista de inteiros no `data`), a LW-035 (personagem mínimo no módulo `character`), a LW-036 (ponte mínima entre a apresentação e a simulação), a LW-037 (gerador do terreno de blockout e tamanho do chunk como dado), a LW-038 (terreno desenhado, `TerrainView`), a LW-039 (colisão do terreno por chunk), a LW-040 (carga e descarga de chunks por distância), a LW-041 (ambiente estático), a LW-042 (ciclo de dia e noite), a LW-043 (árvores e pedras por dados), a LW-044 (mapa de entradas), a LW-045 (personagem provisório, `PlayerBody`), a LW-046 (câmera de terceira pessoa), a LW-047 (limites do jogador), a LW-048 (relato de posição à simulação), a LW-049 (pontos de interesse e comando de interação), a LW-050 (interação na tela e textos por chave), a LW-051 (HUD mínimo e pausa que congela o jogador) a LW-052 (teste de integração da fase), a LW-053 (revisão arquitetural, aceita por Arthur) e a LW-054 (validação, assinada por Arthur com a ressalva de que ainda se atravessam árvores e pedras), as vinte e duas últimas aprovadas por Arthur (a LW-033 e a LW-034 em 05/11/2026; da LW-035 à LW-047 em 06/11/2026; da LW-048 à LW-054 em 07/11/2026), estão concluídas, 23 de 23 tarefas (a LW-047A, trecho íngreme no terreno, é extra e não entra na conta). A tag `fase-1-concluida` foi criada e enviada em 07/11/2026, apontando para `ac4c61f`, com autorização de Arthur (tag leve, não anotada). O avanço total do projeto é de 82 de 192 tarefas (42,7%, contando o SP6, LW-152, antecipado, e a LW-055, a LW-056, a LW-074, a LW-057, a LW-058, a LW-059, da LW-060 à LW-072, a LW-075, da LW-076 à LW-081 e a LW-083, todas da Fase 2).

> O acompanhamento é mantido em `docs/ROADMAP_STATUS.md`. Esta seção só deve conter o que foi verificado.

---

## 6. Estrutura de diretórios

### 6.1 Hoje

Existem: `project.godot`, `scenes/main.tscn`, `data/world/` (terreno de teste, decorações e pontos de interesse), `data/text/` (textos de jogo por chave), `assets/environment/` (recurso do ambiente), `src/` (`app`, `bridge`, `core`, `data`, `persistence`, `sim/world`, `sim/character`, `presentation/ui`, `presentation/world_view` com `terrain`, `environment` e `decoration`, `presentation/player`, `presentation/camera`, `presentation/text`, `presentation/interaction`, mais pastas reservadas com um `README`), `tests/` (`unit`, `integration`, `soak`, `fixtures`), `tools/` (comandos de verificação e simulação) e `docs/` (planejamento, decisões técnicas em `docs/decisions/` e contratos em `docs/modules/`).

### 6.2 Estrutura **planejada** (parte já existe; ver 6.1)

Proposta da arquitetura (cap. 2). Será criada aos poucos, **cada pasta só na tarefa que a exige**:

```
living-world/
├── README.md                ← este arquivo
├── AGENTS.md                ← regras para agentes de IA
├── project.godot            ← projeto Godot (existe)
├── docs/
│   ├── BRIEFING_MESTRE.md   ← briefing original de Arthur (cópia fiel)
│   ├── GDD.md
│   ├── TECHNICAL_ARCHITECTURE.md
│   ├── DECISIONS.md
│   ├── DEVELOPMENT_ROADMAP.md
│   ├── CONSISTENCY_REPORT.md ← relatório de consistência documental
│   ├── ROADMAP_STATUS.md    ← acompanhamento (existe)
│   ├── events.md            ← catálogo de eventos (existe)
│   ├── backlog.md           ← ideias fora do escopo (existe)
│   ├── decisions/           ← registros técnicos curtos (existe)
│   └── modules/             ← contrato de cada módulo (existe; core, data, persistence, app e, como proposta aprovada na LW-055, npc)
├── data/                    ← conteúdo do jogo em arquivos de dados (planejado)
├── src/
│   ├── app/  core/  data/   ← base do jogo (existem)
│   ├── sim/                 ← SIMULAÇÃO, sem elementos visuais (planejado)
│   ├── persistence/         ← salvar e carregar (existe)
│   ├── bridge/              ← ponte entre simulação e visual (planejado)
│   ├── presentation/        ← o que o jogador vê e usa (`ui/`, `world_view/`, `player/` e `camera/` têm conteúdo; o resto é planejado)
│   └── tools/               ← ferramentas de depuração (planejado)
├── scenes/  assets/  addons/
├── tests/                   ← unit, integration, soak, fixtures (existem)
└── tools/                   ← comandos de verificação (existe)
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

**Requisitos:** Mac com macOS.

**Programas externos que os scripts assumem** (o `tools/check_all` confere isso no início e, se faltar algo, para com **uma** mensagem dizendo o que falta e como instalar):

| Programa | Para que serve | Como obter no macOS |
|---|---|---|
| **Godot 4.7.2 estável** (versão exata; padrão, GDScript, sem .NET; ver `docs/decisions/0001-ambiente-de-referencia.md`) | Rodar o projeto e os testes | Baixar de <https://github.com/godotengine/godot-builds/releases/tag/4.7.2-stable> e, se não estiver em `/Applications/Godot 2.app`, definir `GODOT_BIN` |
| **ripgrep (`rg`)** | A verificação de arquitetura (`tools/check_architecture`) | `brew install ripgrep` (precisa do [Homebrew](https://brew.sh)) |
| **Git** | Clonar o repositório | `xcode-select --install` |
| `awk`, `sed`, `grep`, `cut`, `mktemp`, `dirname`, `cp`, `rm`, `mkdir`, `cat`, `head` | Os scripts em `tools/` e `tests/` | Já vêm com o macOS (se faltarem: `xcode-select --install`) |

Só para a medição opcional em release (`tests/soak/run_sp1_release`): `curl`, `unzip`, `tar`, `shasum`, `xattr` e `codesign`, todos já inclusos no macOS.

1. Clone o repositório em uma pasta nova e entre no ramo indicado.
2. Aponte para o Godot. Os comandos em `tools/` procuram o Godot em `/Applications/Godot 2.app/Contents/MacOS/Godot`; se o seu estiver em outro lugar, defina `GODOT_BIN` antes de rodar:
   ```bash
   export GODOT_BIN="/caminho/para/Godot"
   ```
3. Em um clone novo, rode uma vez (cria o cache de scripts, que não vai para o Git):
   ```bash
   "$GODOT_BIN" --headless --path . --import
   ```

Agentes de IA não instalam nada sem autorização (regra do `AGENTS.md`); quem instala os programas acima é você.

---

## 9. Como abrir o projeto no Godot

1. Abra o Godot 4.7.2 e, no gerenciador de projetos, escolha **Importar**.
2. Selecione o arquivo `project.godot` na raiz do repositório e abra o projeto.
3. Aperte **F5** para executar. Você deve ver o terreno de teste (planície verde com um caminho cor de areia e uma colina ao longe) aparecendo aos poucos em volta de uma cápsula laranja, o personagem provisório, visto de uma câmera de terceira pessoa, com árvores e pedras, e, no canto superior esquerdo, o HUD com o título, a versão e a **data e hora simuladas avançando**. O jogo nasce à **meia-noite** (tudo azul-escuro) e, a 1x, só amanhece depois de cerca de 7,5 minutos reais. **P** pausa e continua o relógio e **congela o personagem** (a câmera continua girando), e **1** e **2** mudam a velocidade (1x e 2x). Perto de um marcador ciano aparece **[E] Interagir**; **E** mostra o texto do ponto. **W, A, S e D** andam, **Shift** esquerdo corre e **Espaço** pula; o **botão direito do mouse** arrastado ou as **setas** giram a câmera, e a **roda** dá zoom.

O painel "Saída" não deve mostrar mensagens vermelhas.

---

## 10. Como executar os testes

O comando único é:

```bash
tools/check_all
```

Ele roda, em sequência: conferência dos pré-requisitos → verificação de arquitetura → verificação de teclas fixas (`tools/check_input_keys`) → verificação de texto de tela escrito no código (`tools/check_literal_text`) → **zero avisos de compilação do GDScript** (`tools/check_gdscript_warnings`) → validação dos dados de teste → simulação de 30 dias (`run_sim`) → cena principal por 60 quadros → testes automáticos (GUT), tudo **sem abrir janela**. O resultado termina em **VERDE** (tudo certo) ou **VERMELHO** (com a lista do que falhou).

- **Ambientes sem permissão de gravar logs ou certificados:** o `check_all` ignora, **com um aviso** (`NOTA: ... mensagem(ns) de ambiente ignorada(s)`), só essas mensagens do Godot; qualquer outro erro continua sendo falha.
- **Rodar a simulação sozinha:** `tools/run_sim --days 30 --seed 1` imprime a data final e o "hash do estado"; a mesma semente deve dar o mesmo hash.
- **Validar os dados de teste:** `tools/validate_data`.
- **Gerar de novo o terreno e as decorações de teste:** `tools/make_blockout_terrain` e `tools/make_blockout_decorations` (uso único; com `--check` só conferem se os arquivos de `data/world` estão idênticos ao que gerariam, sem gravar).
- **Medições de desempenho (não fazem parte do `check_all`):** `tests/soak/run_sp1` (núcleo; aceita `--days`, `--npcs`, `--seed` e `--top N` para listar os N passos mais lentos) e `tests/soak/run_sp5` (salvamento). `run_sp1 --control` acrescenta um laço de controle sem o código do jogo. `tests/soak/compare_sp1_runs a.txt b.txt` diz se os picos de duas execuções caem nos mesmos passos. `tests/soak/run_sp1_release` mede o SP1 em build de release no Mac (baixa ~1,28 GB para uma pasta fora do projeto; ver o cabeçalho do script).
- **Testes manuais:** abrir o projeto com F5 e conferir a cena (seção 9).

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
