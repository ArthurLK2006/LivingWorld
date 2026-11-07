Módulo `world` (camada 2). Contrato em `docs/modules/world.md`.

Implementado (LW-034): `TerrainData` (alturas, superfícies e ponto de nascimento; somente leitura) e `TerrainLoader` (lê e valida `data/world/` pelo módulo `data`). LW-049: `PointOfInterest`, `PointOfInterestLoader` (lê `data/world/pois.json`), `InteractionService` (comando de interação com validação de distância) e o evento `InteractionPerformed`. O terreno de blockout (dados) ganhou o morro íngreme de teste (LW-047A). Mapa lógico, rotas e assentamentos entram em fases futuras.
