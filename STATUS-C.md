10/11/2026 19:16 (Brasília) — CONCLUÍDA: LW-087c, PRONTA PARA REVISÃO, **RASCUNHO (NÃO está no `main`)**; ramo `lw-087c-extensoes-world-npc` (`6dae235`). Fase B NÃO feita, sem tag. Parada: aguardo a assinatura da LW-086. Nada rodando.

RELATÓRIO — LW-087c (DOC): extensões dos contratos de `world` e `npc` para a Fase 3 (Economia)        Status: PRONTA PARA REVISÃO — RASCUNHO em ramo (não está no `main`)

Li antes: AGENTS (inteiro), o pré-voo da B (`STATUS-B.md`, ramo `status-b`, seções b, c e d), `docs/DEVELOPMENT_ROADMAP.md` (3.A a 3.J e as linhas da LW-087 a LW-116), GDD 12 (12.3 a 12.5), arquitetura 5.2, 5.5, 8.6, 11 (inteiro) e 17.4 e 17.5, `docs/modules/world.md` e `docs/modules/npc.md` (inteiros), `docs/events.md`, `docs/world/relevo-do-terreno-de-blockout.md` e o código que o texto cita (`src/core/world/world.gd`, `NpcPersistence`, `FoodStub`, `IncomeStub`, o oráculo). Decisões: DEC-047, DEC-049 e DEC-054 (aprovadas por você hoje; **o `DECISIONS.md` ainda traz PROPOSTA nas três**: o registro é seu), DEC-046, DEC-040 (PENDENTE), DEC-041, DEC-126, DEC-127 e DEC-128 (APROVADAS, já no `main`).

1. RESUMO
Os dois contratos ganharam o que a Fase 3 exige deles, **só em texto e só como PLANEJADO**. `world.md`: rotas entre assentamentos (comprimento, dificuldade, risco), o 3º povoado, o estado de rota, o evento `RouteStateChanged` e o comando de fechar rota (hoje nenhuma tarefa os cria: o texto os põe na LW-097). `npc.md` (seção 14 nova): comprar e vender, consumo do inventário, salário e a necessidade `income`, o fim do `FoodStub` e do `IncomeStub` (LW-094 e LW-095), o save do `FoodStub` que muda na LW-094b e a consulta à economia só por `economy/api`. **Onde GDD e arquitetura não decidem, não decidi:** são 11 pontos em aberto com a minha recomendação (seção 9 abaixo). Nenhum código, dado, evento ou tecla.

2. ARQUIVOS CRIADOS
- Nenhum.

3. ARQUIVOS MODIFICADOS (`git diff origin/main...HEAD`: 2 arquivos, 93 inserções e 2 remoções)
- `docs/modules/world.md` (+27): aviso de rascunho no topo e a seção "Extensão da Fase 3: rotas entre assentamentos e o 3º povoado".
- `docs/modules/npc.md` (+68, −2): aviso no cabeçalho, "(hoje; na Fase 3 …)" nas dependências, uma remissão na seção 9, cinco linhas planejadas no rastreio (seção 12: LW-093, 094, 095, 097 e 104) e a **seção 14** (14.1 a 14.9).
- Nenhum arquivo protegido; `docs/events.md` e o `ROADMAP_STATUS.md` **não** foram tocados (a linha planejada de `RouteStateChanged` entra na LW-087d).

4. DECISÕES TÉCNICAS
- **Forma:** uma seção própria por arquivo, marcada PLANEJADA/RASCUNHO, mais avisos curtos nos pontos que hoje dizem outra coisa (o `npc` "não importa `economy`" ganhou "hoje; na Fase 3 …"). O texto de hoje não foi reescrito.
- **Aplicadas as suas decisões de hoje:** 3 povoados; 10 bens e 4 cadeias (citados, a lista é da economia); DEC-047/049/054; as 6 recomendações da B (a `economy` guarda as quantidades de todo dono; o `npc` importa só `economy/api` e a economia nunca importa o `npc`; contrato de trabalho por evento; `mint` inicial na LW-093; não congelar o save e a LW-111 rejeita save antigo; `check_temp` fora de `docs/`); arquivos grandes do `npc` sem divisão (DEC-126: com o PARE perto de 450 linhas de código).
- **Duas confirmações no código** (não confiei só nos documentos): `World.serialize` grava uma entrada por módulo registrado, mesmo vazia, então o estado de rota (módulo `world` registrado) **muda o `state_hash` de todo jogo**; e `World.on_load` **já recusa** save sem a entrada de um módulo registrado (`WORLD_MODULE_DATA_MISSING`), que é o caminho do "rejeita save antigo".
- **Não fixei nomes da economia** (consulta de saldo, de inventário, retirada para consumo): são do `economy.md` (LW-087b).
- **Proposta de entrada para `DECISIONS.md`** (você decide; não editei o arquivo): (a) mudar para **APROVADA por Arthur em 10/11/2026** o status da DEC-047, da DEC-049 e da DEC-054; (b) uma entrada nova "Escala e regras do protótipo da Fase 3" com as suas decisões de hoje: 3 povoados, os 10 bens e as 4 cadeias genéricos, e as seis recomendações da B. Justificativa: são o que as LW-087a a 087d e a LW-093 em diante vão citar; sem o registro elas dependem de mensagem.

5. TESTES EXECUTADOS
- `sh tools/check_architecture .`, `check_input_keys`, `check_literal_text`: verdes.
- `tools/check_all` **no HEAD final `6dae235`** (com o `main` `9dbcebc` juntado no ramo): **VERDE**, 124 scripts, **1.194 testes (todos passando)**, 261.693 asserts, 313 scripts sem aviso de compilação, 0 erros de script, 3 min 24 s. Rodei antes um no HEAD anterior (`10a9e11`, sem o `main` juntado), também VERDE, com os mesmos números; o segundo é o que vale (a regra era uma vez no HEAD final; o `main` andou no meio do trabalho).
- Junção a seco com o `main` (`git merge-tree`): sem conflito.
- NÃO EXECUTADO: oráculo, soak de 30 dias e `run_sim` (só documentos).

6. RESULTADOS
Aceite cumprido ponto a ponto. (a) `world.md`: rotas com comprimento, dificuldade e risco ✓; o 3º povoado ✓; `RouteStateChanged` e o comando de fechar rota, com o registro de que **nascem na LW-097** ✓. (b) `npc.md`: comprar e vender ✓; salário ✓; consumo a partir do inventário ✓; fim do `FoodStub` e do `IncomeStub` nas LW-094 e LW-095 ✓; o save do `FoodStub` que muda na LW-094b ✓; a consulta do `npc` à economia só por `economy/api` ✓. Tudo marcado PLANEJADO; nenhuma linha diz "implementada" para coisa nova; nenhum código.

7. PROBLEMAS ENCONTRADOS
- **O `main` andou** (LW-085e: DEC-126 a DEC-128, AGENTS 0.4): juntei o `main` **no ramo** (nunca o contrário) e passei a citar DEC-126 e DEC-127 no texto; sem conflito.
- **O roadmap (arquivo protegido) pede coisas que o contrato já contradiz ou não cobre; mudar é sua decisão:** (i) a linha da LW-097 não cita o evento nem o comando de fechar rota, mas o checklist 3.H e as LW-100, LW-104 e LW-110 dependem deles; (ii) a LW-111 diz "save da Fase 2 migra" e a sua decisão é "rejeita"; (iii) a LW-114 diz "no repositório" e a sua decisão exclui `docs/`; (iv) o roadmap põe o `mint` inicial na LW-095 e você o pôs na LW-093.
- **A topologia de 3 povoados não dá, com um único fechamento, "muda o caminho" (LW-097) e "gera escassez no destino" (3.F e 3.H):** é a Q-W1.
- **O oráculo muda duas vezes:** a LW-094b o obriga a refazer a fase `starved` (ela usa `request_set_food_stock`), e a LW-097 muda todos os hashes (módulo `world` registrado e 3º povoado). Os valores novos são decisão sua, como na LW-073b.
- **Apagar `test_food_stub.gd` (19 testes) e `test_income_stub.gd` (13) exige a sua autorização escrita** no texto da LW-094b e da LW-095 (AGENTS 9.5); o texto diz isso.

8. RISCOS
- O texto de `world.md` e `npc.md` é **proposta**: se você não responder as 11 perguntas antes da LW-087a, a 087b e as tarefas da Fase 3 vão escolher sozinhas ou parar.
- A posição do 3º povoado ((560 m, 860 m)) é [HIP] e não foi conferida por teste de inclinação (só a LW-097 pode).

9. PENDÊNCIAS: AS 11 PERGUNTAS (recomendação minha; nada está decidido nos arquivos)
| # | Pergunta | Recomendação |
|---|---|---|
| Q-W1 | Topologia das rotas dos 3 povoados | Triângulo (A–B, A–C, B–C): atende "muda o caminho"; a escassez vem do caminho longo ser mais lento e arriscado e de o teste poder fechar **duas** rotas; a calibração (LW-112) confirma |
| Q-W2 | Estados da rota | Só `open` e `closed`; "perigosa" reservada sem comportamento |
| Q-W3 | Campos extras da rota (`capacity`, `kind`) | Nenhum agora; o `TradeFlow` (LW-100) acrescenta o que precisar |
| Q-W4 | Nome do tipo de local `market_reserved` quando passar a ter comportamento | Renomear para `market` na LW-093 |
| Q-W5 | Posição do 3º povoado e terreno | Não ampliar o terreno; escolher a posição pelo teste de inclinação |
| Q-W6 | O módulo `world` registrado muda todo hash (oráculo, soak de 30 dias, `run_sim`) | Aceitar e atualizar na LW-097 **com a sua aprovação dos valores novos** |
| Q18 | Como o dinheiro recebido alivia `income` | Um evento de pagamento ouvido pelo `npc` (escritor a mais de `need_values`, com teste que lista os escritores); pagamento por hora de produção, aos atribuídos |
| Q19 | Como `buy` vira candidata (o pré-requisito de `eat`) | Valor derivado: `buy` herda o alívio da necessidade que o bem atende, descontados preço e distância |
| Q20 | O que o NPC consome | Só comida na Fase 3; pelo menos um bem do início da cadeia comestível (risco R3.3); a lista é sua, na 087a |
| Q21 | Como a economia conhece os NPCs (contas, dinheiro inicial) sem importar o `npc` | O `npc` chama a `economy/api` ao criar o NPC; a economia faz o `mint` inicial (sem evento novo) |
| Q22 | Como o NPC consegue o emprego (contrato por evento) | Emprego estático para a população inicial (a economia o aprende pela chamada da Q21) e `ContractOffered` mais `request_accept_contract` para vaga nova |

ACOMPANHAMENTO
- Avanço: LW-087c escrita como **rascunho**; a Fase 3 **não começou**. Fase 2 segue em 31 de 32 (96,9%) e projeto em 86 de 192 (44,8%); só falta a LW-086 (a sua passada na janela). Nenhuma contagem mudou.
- Próxima tarefa recomendada: a **LW-086** (sua assinatura) e, depois, a **LW-087a** (respostas às 11 perguntas e à lista de bens). **Não iniciadas.**
- Decisões que dependem de Arthur: as 11 perguntas acima; registrar DEC-047/049/054 e a entrada da escala da Fase 3; o que fazer com as quatro divergências do roadmap (item 7); autorizar por escrito a remoção dos testes dos provisórios no texto da LW-094b e da LW-095.
- Git: **nada no `main`** (`9dbcebc`, inalterado), **sem tag**, sem Fase B. Ramo `lw-087c-extensoes-world-npc` enviado (`10a9e11`, junção `be101e2` e `6dae235`); worktree `.worktrees/lw-087c` mantido. Neste ramo `status-c`: só `STATUS-C.md` e `REVISAO-085-C.md`.
