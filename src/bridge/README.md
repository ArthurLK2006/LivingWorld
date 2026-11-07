Módulo `bridge` (camada 6). Contrato em `docs/modules/bridge.md`.

Implementado (LW-036 e LW-037A): `SimBridge` (consultas somente-leitura de altura, superfície, ponto de nascimento, formato do terreno e hora simulada; pedidos de pausa e velocidade; fila de intenções) e `BridgeIntent` (base das intenções; nenhuma concreta ainda). LW-048: nascimento e relato de posição do personagem (`request_spawn_character`, `request_report_position`, `peek_character`). A ponte não avança a simulação.
