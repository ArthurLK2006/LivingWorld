# LW-029 — Pacote da revisão arquitetural da Fase 0

**PRONTO PARA ENVIO AO REVISOR (versão final de 02/11/2026).** Nada aqui foi enviado a ninguém. Quem decide enviar é Arthur. **Código de referência: commit `7e780c5`** do ramo `claude/living-world-coordination-umft1k` (o `src/` é idêntico ao do commit `0eb1bdf`, o que o Mac testou). Os commits posteriores a ele só mexem em documentos; a versão final do pacote é a ponta do ramo no momento do envio. Não há mais pendência de SP1, F5 ou LW-006.

## Em palavras simples
A LW-029 é uma "auditoria de obra": um revisor de fora lê o conjunto do que foi construído na Fase 0 e diz se a base está firme antes de construir em cima dela. Ele **não programa e não aprova**; quem aprova é Arthur.

## Quem revisa
- **O ChatGPT**, no papel de auditor de arquitetura definido na DEC-093 (APROVADA): "Codex implementa; ChatGPT apoia arquitetura, planejamento e auditoria".
- **Opcional, recomendado:** repetir o mesmo pedido numa **segunda conversa independente** (de outra IA ou de outra sessão do ChatGPT) e comparar as respostas. O roadmap prevê isso para revisões de fase. Achados que aparecem nas duas pesam mais.
- Esta sessão (o agente que escreveu o código) **não deve ser o revisor**: quem fez não audita o próprio trabalho.

## O que o revisor precisa receber
O ChatGPT não enxerga o seu computador. Há duas formas:
1. **Repositório público:** basta dizer o endereço e o ramo. A visibilidade é decisão sua (DEC-089); hoje não sei se está público.
2. **Colar o material** (mais seguro). Em **3 mensagens**, nesta ordem:

| Mensagem | Conteúdo | Tamanho atual |
|---|---|---|
| 1 | O texto "PEDIDO" (a partir de "## PEDIDO" até o fim deste arquivo) + `docs/ROADMAP_STATUS.md` + `docs/decisions/0001` a `0006` + `docs/fase-0/mac-snapshot-comparacao.md` | 59.5 KB (59.216 caracteres) |
| 2 | Contratos `docs/modules/core.md`, `data.md`, `persistence.md`, `app.md` + `docs/events.md` + a saída completa de `tools/check_all` (a linha final deve dizer VERDE; a minha tem 21.5 KB (21.926 caracteres)) | 39.2 KB (39.741 caracteres) |
| 3 | Código de `src/` (24 arquivos `.gd`), uma pasta por mensagem se preferir: `app` 8.6 KB; `core` 38.8 KB; `data` 11.2 KB; `persistence` 17.3 KB; `presentation` 0.5 KB | 76.4 KB (77.663 caracteres) |

Os tamanhos são do texto puro em UTF-8 e foram medidos em 02/11/2026. A soma das 3 mensagens é de 175.1 KB (176.620 caracteres). Se o chat do revisor reclamar de tamanho, divida a mensagem 3 por pasta.

Só se o revisor pedir: os testes (`tests/`, 30 arquivos `.gd`, ~99 KB), o `AGENTS.md` (~32 KB) e os capítulos 4, 17 e 18 da arquitetura.

## O que mudou desde a versão anterior do pacote (em palavras simples)
Para o revisor saber o que é novo em relação ao que o pacote dizia antes de 02/11/2026:
- **O critério de pico de 10 ms deixou de ser pendência e foi confirmado.** Antes havia números de depuração, que variavam muito de uma execução para outra (de 0 a 14 passos lentos com o mesmo código). Foi criada uma régua objetiva (DEC-113), aprovada antes de medir, e o build de release passou nas 3 execuções exigidas. A redação foi levada para a arquitetura (20.1 e 26.3) e para o item da LW-023 no roadmap.
- **O `check_all` ganhou três proteções:** (1) confere logo no início se faltam programas (como o `rg`) e para com uma mensagem só; (2) falha se qualquer script tiver aviso de compilação do GDScript; (3) ignora, com aviso, apenas as mensagens de ambiente conhecidas do macOS e do ambiente restrito do Codex (diretório de dados, logs, certificados), e qualquer outro erro continua falhando.
- **Foram corrigidos 27 avisos do GDScript** que ninguém via (o Godot só os mostra com o depurador ligado). A divisão inteira, que é intencional (o jogo conta minutos inteiros), virou uma função explícita e testada (`IntMath.floor_div`). Os demais foram renomeações e reestruturações sem mudança de comportamento; o hash do mundo não mudou.
- **Novas ferramentas de medição:** `run_sp1 --control` (laço sem o código do jogo, para separar ruído da máquina de custo do código), `compare_sp1_runs` (diz se os picos de duas execuções caem nos mesmos passos) e `run_sp1_release` (mede o release no Mac; tem trava para não apagar pastas que não são dela).
- **Descoberta no módulo de teste do spike:** a cada 99 passos, 818 dos 1.000 NPCs "pensam" juntos (uma onda de ~0,6 ms). Não afeta o critério, mas é lição para o módulo de NPCs real (cada NPC precisa de fase própria; está no backlog).
- **Dados e testes:** os testes do carregador passaram a usar uma pasta congelada, para não quebrarem quando o Codex edita a pasta de dados de exemplo.
- **Decisões novas aprovadas por Arthur:** DEC-084 (formato de save do protótipo) e DEC-113 (régua de pico). A LW-006, a LW-023 e a parte visual da LW-021 foram fechadas.
- **Documentos:** README reescrito para refletir o que existe (inclui os programas externos necessários), comparação só de leitura com o ramo `mac-snapshot`, e este pacote.

## Quanto tempo costuma levar
- **O projeto não registra prazo para a revisão**, então não há número oficial.
- **Estimativa minha, não vinda do roadmap:** cada resposta do revisor leva de alguns minutos a cerca de meia hora, e uma revisão desse tamanho costuma pedir **1 a 3 rodadas** (por exemplo, ele pede um arquivo que faltou). O trecho mais demorado costuma ser **seu**: colar o material e decidir sobre cada achado.

## Depois da resposta
1. Cole a resposta do revisor aqui na conversa.
2. Eu separo o que é **crítico** (precisa de correção antes de seguir), **importante** e **menor**, e proponho uma tarefa para cada um.
3. Você decide. Só quando não houver achado crítico aberto a LW-029 fica aprovada (Definição de concluído da Fase 0, item 3).

## O que o revisor NÃO vai ver
O trabalho local de Arthur no Mac está no ramo `mac-snapshot`, que já está no mesmo repositório do GitHub, mas fica **fora desta revisão**; a comparação foi feita só em leitura (`docs/fase-0/mac-snapshot-comparacao.md`, que entra na mensagem 1) e a junção acontece depois do fechamento da Fase 0.

---

## PEDIDO (copiar a partir daqui)

Você é o auditor de arquitetura do projeto Living World (RPG sandbox 3D em Godot 4.7.2, GDScript tipado, simulação separada da apresentação). Faça a REVISÃO ARQUITETURAL DA FASE 0 (tarefa LW-029), sobre o conjunto da fase e não sobre uma tarefa isolada. Você apenas revisa: não implemente nada e não aprove nada em nome do dono do produto.

**O que a Fase 0 entrega (fatos verificados em 02/11/2026):**
- 24 arquivos de código em `src/` (~1.900 linhas) e 30 de teste e de spike em `tests/` (~2.500 linhas), mais 8 scripts de teste em shell. `tools/check_all` verde, 145 testes, também no Mac (depois de instalar o ripgrep; o `check_all` confere os pré-requisitos no início e para com uma mensagem única se faltar algo).
- Núcleo (`src/core`): `Result`, gerador de IDs, gerador aleatório com fluxos nomeados, relógio de simulação (passo fixo de 1 minuto), barramento de eventos com `cause_id`, `SimModule`/`SimContext`, `World` (ordem declarada, salvar/carregar o núcleo), agendador com frequência por módulo e orçamento por passo, hash de estado (SHA-256 do JSON canônico).
- Dados (`src/data`): leitor e validador de JSON (tipos, faixas, referências entre arquivos, ids únicos). Persistência (`src/persistence`): codec de save (gzip, checksum, versão 2, migração 1→2 com fixture) e armazenamento com `.tmp`, backups rotativos e recuperação. App (`src/app`): `SimulationRunner`, autoloads `SimulationHost` e `GameApp`, `tools/run_sim`. Um texto 2D na cena inicial.
- `tools/check_architecture`: 7 regras por busca de texto. `tools/check_gdscript_warnings`: varre os 57 scripts com o depurador ligado e exige **zero avisos de compilação** do GDScript (antes de 02/11/2026 isso não era verificado: o Godot só imprime esses avisos com o depurador ativo; 27 avisos foram achados e corrigidos). `tools/check_all` também ignora, com aviso, ruído de ambiente do Godot (diretório de dados, logs, certificados).
- Spikes: SP1 (núcleo; 1.000 NPCs de mentira, 1 ano: média 0,14 ms por passo no binário de editor e 0,11 ms no de release na nuvem, 0,075 ms em release no Mac; hash igual nas três máquinas/builds; **o critério de pico de 10 ms está CONFIRMADO em release no Mac**, veja abaixo), SP3 (pipeline de dados), SP5 (salvamento: 2,3 ms para salvar e 0,9 ms para carregar com 1.000 NPCs). Relatórios em `docs/decisions/0003` a `0005`.
- DEC-082 (JSON validado), DEC-084 (formato de save do protótipo) e DEC-113 (régua de pico do SP1; sua redação já foi incorporada à arquitetura 20.1/26.3 e ao item da LW-023 do roadmap) estão APROVADAS.

**Confira, item a item, respondendo "ok", "problema" ou "não consigo verificar":**
1. Escopo: algo foi construído além do que a Fase 0 pede (antecipação, "para o futuro")?
2. Contratos de cada módulo (`docs/modules/*.md`) × código: divergências?
3. Camadas: dependências só para camadas inferiores? Simulação sem Nodes de cena? Acoplamento perigoso (módulo importando muitos outros, `SimContext` expondo coisas demais)? Peça o grafo de imports se precisar.
4. Aleatoriedade só pelo gerador do núcleo; tempo da simulação só pelo relógio dela; sem `float` em quantidades.
5. Determinismo: o desenho garante o mesmo hash para a mesma semente? Há risco de a ordem de iteração de `Dictionary` afetar o resultado?
6. Eventos publicados × `docs/events.md` (o catálogo está vazio de propósito: nenhum evento de jogo ainda).
7. Salvamento: formato, checksum, migração, recuperação. Algum cenário de perda de save que os testes não cobrem?
8. Testes: cobrem os critérios de aceite? Algum teste foi enfraquecido? O que falta (por exemplo, `tests/integration/` está vazio)?
9. Desempenho medido × orçamento da arquitetura (cap. 20): as conclusões dos spikes sustentam as decisões?
10. Dívida técnica acumulada e riscos residuais; código de spike que deveria ser descartado (fica em `tests/soak/`).
11. Divergências entre GDD, arquitetura e código.
12. Documentação desatualizada: diga se encontra.

**Pontos que quero que você examine com atenção (decisões e limitações conhecidas):**
- O agendador mede o orçamento em unidades de trabalho declaradas por módulo e não em milissegundos reais, para o resultado não depender da velocidade da máquina. Concorda?
- `SimClock.advance_step()` é público; só o `SimulationHost` deveria chamá-lo. Hoje é convenção documentada, não regra verificada.
- A apresentação (`StatusOverlay`) lê o autoload `GameApp` diretamente, porque a ponte (`bridge`) só nasce na LW-036.
- A migração 1→2 do save assume que, num save antigo sem estado do agendador, todos os módulos vencem no minuto seguinte.
- O save é gzip + JSON; escrita em outra thread e `fsync` não existem. A partir de ~1 MB de estado, salvar passa de 100 ms na thread principal (medido).
- `check_architecture` é busca de texto; a regra de imports entre camadas só chega na LW-036.
- Valores de hipótese mantidos como constantes nomeadas: 360 dias por ano, 1 dia de jogo ≈ 30 min reais, 8 rodadas de eventos por entrega, 60 passos por quadro, 3 backups.
- **Critério de 10 ms do SP1: CONFIRMADO em build de release no Mac de referência (régua da DEC-113, 3 execuções).** Condições: Apple M3, carregador ligado, Godot fechado, sem uso; cada execução informa "build de depuração: não". Resultado das 3 execuções de 1 ano, 1.000 NPCs: média 75,1 a 75,2 µs, p99,9 até 600 µs, máximo 2,857 ms, **0 passos acima de 3 ms e 0 acima de 10 ms em 1,95 minuto medido** (limite: 1 por minuto, acumulado), hash `6ed27f5c82950855b7bf45f1bb94688cf103c2e4831e182f292e4b1fd2df236d` idêntico ao da nuvem e ao da depuração, controle sem código do jogo também sem passos acima de 10 ms. Os picos mudam de lugar entre execuções; as 3 coincidências exatas são "passos de onda" do módulo de teste (818 dos 1.000 NPCs pensam juntos a cada 99 passos, ~0,6 ms), esperadas por acaso. **Em depuração** o mesmo Mac deu 13, 7, 5, 7, 0 e 1 passos acima de 10 ms (piores: 88,216; 76,279; 48,514; 73,419; 1,266; 10,959 ms), "provavelmente carga ou temperatura da máquina, a confirmar"; na nuvem, o mesmo código e hash deram de 0 a 14, e um laço de controle sem o código do jogo também teve engasgos. Registro: `docs/decisions/0004` e 0006, linhas brutas em `docs/fase-0/evidencias/`. Opine sobre a medição, o laço de controle, a régua (inclusive se o item 5, "não se repetem nos mesmos passos", merece uma frase que o torne explícito) e se o módulo de teste, que forma ondas, é um risco para o módulo de NPCs real.
- **Processo:** em 02/11/2026 o editor mostrou 5 avisos de GDScript que o `check_all` e meus relatórios não enxergavam (o Godot só os imprime com o depurador ligado). Foram achados e corrigidos 27, sem `@warning_ignore`, e a verificação agora é automática. Diga se vê outra lacuna desse tipo, em que uma verificação "verde" não olhava o que parecia olhar.
- Pendências abertas e fora do seu alcance: **nenhuma do SP1, do F5 ou da LW-006** (Arthur fechou a LW-006, a LW-023 e a parte visual da LW-021 em 02/11/2026: data avança, Espaço pausa e continua, aba Erros vazia). Restam a sua revisão (LW-029), a validação de Arthur (LW-030) e o fechamento (LW-031).
- O trabalho local do dono está no ramo `mac-snapshot` do mesmo repositório, **fora desta revisão** (comparado só em leitura em `docs/fase-0/mac-snapshot-comparacao.md`: implementação paralela do núcleo, ponte e tela inicial mínimas, um experimento de terceira pessoa e 5 medições de release do Codex sem passo acima de 10 ms, com simulação bem mais leve). Será reconciliado depois do fechamento da Fase 0.

**RESPOSTA ESPERADA**
- Veredito: APROVADO / APROVADO COM AJUSTES / REJEITADO
- Achados por severidade (crítico, importante, menor), cada um com arquivo e correção sugerida
- O que o usuário precisa decidir, cada decisão com recomendação
- Avanço da fase em % e próxima tarefa
