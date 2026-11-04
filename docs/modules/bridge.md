# Contrato — bridge (sim_bridge, mínima)

Estado: **ainda não implementado.** Fase 1 só constrói a fatia mínima (LW-036): respeitar pausa e velocidade, consultas somente-leitura e uma fila de intenções — ver item [PENDENTE] abaixo sobre quem avança a simulação a cada quadro. A ponte completa (fronteira de combate, `ViewModel`s de economia e política — arquitetura cap. 6 e 19) é visão de fases futuras.

- **Responsabilidade:** ser o único caminho entre `presentation` e a simulação: expor consultas somente-leitura do estado simulado, enfileirar intenções (comandos do jogador) para a simulação e respeitar pausa e velocidade (mecanismo exato no item [PENDENTE]). Nenhuma regra de jogo aqui (AGENTS cap. 6).
- **Entradas:** intenções do jogador (comandos tipados, com o identificador do ator — AGENTS cap. 6, "nada de 'o jogador' no singular"). Nenhuma entrada de tempo de quadro nesta tarefa: ver item [PENDENTE].
- **Saídas:** resultado das consultas (altura, superfície, ponto de nascimento, hora simulada — repassando `world` e o relógio do `core`); `Result` de cada intenção processada.
- **Dependências permitidas:** `core`, `app` (`SimulationHost` e `GameApp`, já existentes — `docs/modules/app.md`; o uso exato depende do item [PENDENTE] abaixo), `world`. `bridge` é camada 6 (AGENTS cap. 5.1). **`character` fica de fora desta lista por enquanto:** a linha da LW-036 no roadmap não lista a LW-035 (`character`) como dependência; a integração chega só na LW-048 (relato de posição).
- **Dados controlados:** nenhum dado de simulação (a ponte não é dona de nada — arquitetura cap. 6); só a fila de intenções pendentes, que é estrutura de apresentação, não é salva e não entra no `state_hash`.
- **Interfaces de comunicação:** consultas **propostas**, espelhando as de `world` e do relógio: `peek_height(x, z)`, `peek_surface(x, z)`, `peek_spawn_point()`, `peek_time()` (hora, dia e ano simulados — o critério de aceite da LW-036 cita "a apresentação consulta altura **e hora** apenas via ponte"). Fila de intenções: existe porque a LW-036 pede, mas **nenhuma intenção concreta é definida aqui** — defini-la agora seria antecipar funcionalidade de tarefas futuras (AGENTS 0.3). Nenhum evento nem `Signal` novo nesta tarefa (Signals ficam só na apresentação, que consome o que a ponte expõe — arquitetura 17.2).
- **Testes necessários:** a apresentação consulta altura e hora **apenas** via ponte, nunca importando `sim/` direto (critério do roadmap, LW-036); `check_architecture` confirma isso com a regra 4 do cap. 27.3 **estendida nesta mesma tarefa** pela LW-036 (nenhum módulo importa camada superior nem arquivo privado de outro módulo; teste com import indevido falha apontando arquivo e linha — texto do roadmap).

**[PENDENTE] — quem avança a simulação, pausa e muda a velocidade:** conferido no código em 04/11/2026 (`src/app/simulation_host.gd`, `src/app/game_app.gd`, `src/core/clock/sim_clock.gd`):
- `SimulationHostNode.advance(delta_seconds: float)` (`simulation_host.gd:21-24`) já é chamado a cada quadro pelo próprio `_process` do autoload `SimulationHost` (`simulation_host.gd:27-28`) — **a simulação já avança sozinha, sem a ponte.** Se a ponte também avançasse, a simulação rodaria em dobro.
- A pausa **já existe**, mas no autoload `GameApp`: `toggle_pause()` chama `clock.set_paused` diretamente (`game_app.gd:42-46`), permitido porque está em `src/app`.
- A velocidade **não tem nenhuma entrada pública hoje**: `SimClock.set_speed()` existe (`sim_clock.gd:70`), mas nada em `src/` o chama (conferido por busca no código).
- `bridge` não pode chamar `SimClock.set_paused`/`set_speed` diretamente — regra "relógio e barramento fora de core e app" do `tools/check_architecture` (arquitetura 27.3).

Duas opções, **nenhuma decidida aqui**:
1. O `SimulationHost` continua avançando sozinho no seu `_process`; a ponte só repassa pedidos de pausa/velocidade (comandos novos, a definir) e as consultas.
2. A ponte assume o avanço (chama `SimulationHost.advance()` ela mesma) e o `_process` do `SimulationHost` é desligado — isso **muda o contrato `app`**.

**Recomendação do Claude [PROPOSTA], não decisão:** opção 1 — é a menor mudança e já bate com a arquitetura 6.4 ("cada quadro, o `SimulationHost` acumula o tempo real..."). A decisão fica para Arthur, no início da implementação da LW-036 (registrado também em `docs/backlog.md`).
