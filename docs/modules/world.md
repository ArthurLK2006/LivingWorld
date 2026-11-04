# Contrato — world

Estado: **ainda não implementado.** Este contrato cobre só o recorte que a Fase 1 usa (LW-034): dados físicos do terreno para andar nele. A visão completa do módulo (mapa lógico de províncias, rotas, assentamentos — arquitetura 5.2 e 5.5) é de fase futura, quando política e economia existirem, e **não é construída agora** (roadmap 1.J: "não fazer nesta fase: mapa"). Isso é uma **redução proposta** da ficha da arquitetura, não o módulo inteiro.

- **Responsabilidade:** guardar e validar os dados físicos do terreno (altura e tipo de superfície) e o ponto de nascimento do jogador; responder consultas de altura e superfície por coordenada.
- **Entradas:** arquivos de `data/world/` (formato exato a definir nas tarefas LW-033/LW-037, que ainda não rodaram), lidos e validados pelo módulo `data`.
- **Saídas:** `HeightQuery` e `SurfaceQuery` — **proposta** de pequenos tipos de retorno com um campo `result: Result` (sucesso ou falha) e o valor consultado, no mesmo padrão já usado por `DecodedSave` em `persistence` (`docs/modules/persistence.md`), em vez de inventar um mecanismo novo de erro só para consultas. `peek_spawn_point()` devolve o ponto de nascimento (dado carregado na validação; não falha depois disso).
- **Dependências permitidas:** `core`, `data` (camadas 0 e 1; `world` é camada 2 — AGENTS cap. 5.1).
- **Dados controlados:** `TerrainData` — grade de alturas e grade de tipo de superfície (só dados, sem `Node`, AGENTS 4.4); ponto de nascimento do jogador (coordenada fixa, parte dos dados de terreno).
- **Interfaces de comunicação:** consultas `peek_height(x, z)` e `peek_surface(x, z)` (devolvem `HeightQuery`/`SurfaceQuery`; fora do mapa devolve `result` de falha — código e mensagem exatos ficam para a implementação); `peek_spawn_point()`. Nenhum comando (`request_*`) nem evento nesta tarefa: a Fase 1 não publica nem ouve evento neste módulo (docs/events.md permanece sem entrada para `world`).
- **Testes necessários:** altura e superfície consultadas batem com o arquivo de dados (critério do roadmap, LW-034); consulta fora do mapa devolve `result` de falha, sem travar (AGENTS 13.1.4); arquivo de terreno inválido falha a validação apontando arquivo e campo (critério do roadmap, LW-034); `peek_spawn_point()` aponta para um local dentro do próprio mapa.

**Pendente [PENDENTE], não decidido aqui:** tamanho do mapa, resolução da grade e tamanho de *chunk* dependem do spike SP4a (LW-033) e da **DEC-055** (dimensões do mundo), hoje **PENDENTE** em `docs/DECISIONS.md`. Nenhum número de dimensão aparece como definitivo neste contrato — só depois do SP4a.

**Limitação [LIM]:** o formato exato dos campos dentro dos arquivos de `data/world/` (nomes, unidade da grade) é proposta das tarefas que os criam (LW-034 e LW-037), não deste contrato.
