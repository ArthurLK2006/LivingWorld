# LW-029 — Pacote da revisão arquitetural da Fase 0

**RASCUNHO preparado em 02/11/2026.** Nada aqui foi enviado a ninguém. Quem decide enviar é Arthur.

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

| Mensagem | Conteúdo | Tamanho aproximado |
|---|---|---|
| 1 | O texto "PEDIDO" (abaixo) + `docs/ROADMAP_STATUS.md` + `docs/decisions/0001` a `0005` | ~25 KB |
| 2 | Contratos `docs/modules/core.md`, `data.md`, `persistence.md`, `app.md` + `docs/events.md` + a saída completa de `tools/check_all` (a linha final deve dizer VERDE) | ~25 KB |
| 3 | Código de `src/` (23 arquivos, ~77 KB), de preferência uma pasta por mensagem (`core`, depois `data`, `persistence`, `app` e `presentation`) | ~77 KB |

Só se o revisor pedir: os testes de `tests/unit/` (~95 KB), o `AGENTS.md` (~32 KB) e os capítulos 4, 17 e 18 da arquitetura.

## Quanto tempo costuma levar
- **O projeto não registra prazo para a revisão**, então não há número oficial.
- **Estimativa minha, não vinda do roadmap:** cada resposta do revisor leva de alguns minutos a cerca de meia hora, e uma revisão desse tamanho costuma pedir **1 a 3 rodadas** (por exemplo, ele pede um arquivo que faltou). O trecho mais demorado costuma ser **seu**: colar o material e decidir sobre cada achado.

## Depois da resposta
1. Cole a resposta do revisor aqui na conversa.
2. Eu separo o que é **crítico** (precisa de correção antes de seguir), **importante** e **menor**, e proponho uma tarefa para cada um.
3. Você decide. Só quando não houver achado crítico aberto a LW-029 fica aprovada (Definição de concluído da Fase 0, item 3).

## O que o revisor NÃO vai ver
Existe trabalho local seu no Mac, preservado no ramo `mac-snapshot`, que **não está neste repositório remoto**. Ele fica fora desta revisão; a comparação acontece depois do fechamento da Fase 0.

---

## PEDIDO (copiar a partir daqui)

Você é o auditor de arquitetura do projeto Living World (RPG sandbox 3D em Godot 4.7.2, GDScript tipado, simulação separada da apresentação). Faça a REVISÃO ARQUITETURAL DA FASE 0 (tarefa LW-029), sobre o conjunto da fase e não sobre uma tarefa isolada. Você apenas revisa: não implemente nada e não aprove nada em nome do dono do produto.

**O que a Fase 0 entrega (fatos verificados em 02/11/2026):**
- 23 arquivos de código em `src/` (~1.900 linhas) e 27 de teste (~2.400 linhas). `tools/check_all` verde, 141 testes.
- Núcleo (`src/core`): `Result`, gerador de IDs, gerador aleatório com fluxos nomeados, relógio de simulação (passo fixo de 1 minuto), barramento de eventos com `cause_id`, `SimModule`/`SimContext`, `World` (ordem declarada, salvar/carregar o núcleo), agendador com frequência por módulo e orçamento por passo, hash de estado (SHA-256 do JSON canônico).
- Dados (`src/data`): leitor e validador de JSON (tipos, faixas, referências entre arquivos, ids únicos). Persistência (`src/persistence`): codec de save (gzip, checksum, versão 2, migração 1→2 com fixture) e armazenamento com `.tmp`, backups rotativos e recuperação. App (`src/app`): `SimulationRunner`, autoloads `SimulationHost` e `GameApp`, `tools/run_sim`. Um texto 2D na cena inicial.
- `tools/check_architecture`: 7 regras por busca de texto. `tools/check_all` também ignora, com aviso, ruído de ambiente do Godot (diretório de dados, logs, certificados).
- Spikes: SP1 (núcleo; 1.000 NPCs de mentira, 1 ano: média 0,14 ms por passo no binário de editor e 0,11 ms no de release; hash igual entre os dois e igual ao do Mac; **mas o critério de pico de 10 ms não foi cumprido no Mac**, veja abaixo), SP3 (pipeline de dados), SP5 (salvamento: 2,3 ms para salvar e 0,9 ms para carregar com 1.000 NPCs). Relatórios em `docs/decisions/0003` a `0005`.
- DEC-082 (JSON validado) e DEC-084 (formato de save do protótipo) estão APROVADAS.

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
- **Critério de 10 ms do SP1 NÃO cumprido na medição do Mac** (Mac de referência, executado pelo Codex, build de depuração, Godot 4.7.2, 1.000 NPCs, 360 dias: 51 passos acima de 3.000 µs, 13 acima de 10.000 µs, pico de 88,216 ms; `state_hash` `6ed27f5c82950855b7bf45f1bb94688cf103c2e4831e182f292e4b1fd2df236d`, idêntico ao medido na nuvem (Linux, Xeon). O critério de 10 ms NÃO foi cumprido nesta medição. Nas medições na nuvem o pico ficou entre 5,5 e 30,6 ms (5 a 17 passos acima de 3 ms). Ainda não se sabe se o pico é ruído da máquina (picos que mudam de lugar entre execuções) ou trabalho periódico do código (picos nos mesmos passos); a análise depende de duas execuções seguidas e de uma no Terminal normal, ainda não recebidas. Dê a sua opinião sobre a medição e sobre como medir uma versão release no Mac.
- Pendências abertas e fora do seu alcance: conferência visual da cena inicial (F5) e nova execução do `check_all` no Mac; LW-006 segue "em auditoria" por ressalvas de ambiente.
- Existe trabalho local do dono, em outro ramo, fora desta revisão.

**RESPOSTA ESPERADA**
- Veredito: APROVADO / APROVADO COM AJUSTES / REJEITADO
- Achados por severidade (crítico, importante, menor), cada um com arquivo e correção sugerida
- O que o usuário precisa decidir, cada decisão com recomendação
- Avanço da fase em % e próxima tarefa
