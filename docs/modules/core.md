# Contrato inicial de core — LW-013 a LW-015

- Responsabilidade: IDs únicos, aleatoriedade determinística e relógio de simulação.
- Entradas: alocação/liberação de ID; semente e nome de fluxo; passos disponíveis, pausa e velocidade.
- Saídas: IDs crescentes; números por fluxo; minutos e calendário consultável.
- Dependências: nenhuma entre módulos; serviços nativos do Godot.
- Dados controlados: próximo ID, semente e estados dos fluxos, minutos, pausa e velocidade.
- Interfaces: métodos públicos dos serviços; nenhum evento introduzido.
- Testes: unicidade e restauração de IDs; repetição, isolamento e restauração de fluxos; passos, pausa, velocidade e restauração do relógio.

O chamador fornece dias por ano; duração de ano e conversão de tempo real não foram decididas aqui. O algoritmo interno do gerador do Godot pode mudar entre versões; a versão do Godot deve permanecer fixada.

LW-016 a LW-018: barramento mantém fila e causa; contexto reúne serviços; módulos seguem o ciclo de vida da arquitetura; mundo chama os módulos na ordem de registro e encerra na ordem inversa. Eventos de teste não são eventos de jogo.
