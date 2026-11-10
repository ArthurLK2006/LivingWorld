10/11/2026 20:32 (Brasília) · PRONTA PARA REVISÃO — RASCUNHO · LW-087a: ramo `lw-087a-registro-fase-3` (`44e29df`) empurrado; `check_all` verde; NÃO está no `main`, sem Fase B e sem tag; o Godot da A está parado

# RELATÓRIO — LW-087a: Registro do pré-voo da Fase 3 (economia)     Status: PRONTA PARA REVISÃO — RASCUNHO (não está no `main`)

> **Em uma frase:** só texto, nenhum código. No ramo `lw-087a-registro-fase-3` (HEAD `44e29df`): as DEC-047, 049 e 054 passam a APROVADA; entram 34 entradas novas (DEC-129 a DEC-162), das quais **12 são APROVADAS por você e 22 são PROPOSTA decididas pelo revisor** (padrão de trabalho, não APROVADA); o roadmap divide a LW-087 em 087a a 087d e ganha a LW-093a e a LW-093b; o registro técnico é o `docs/decisions/0012-pre-voo-da-fase-3.md`. **Sem Fase B, sem `main`, sem tag.** Parei (regra 13).

## Declaração de leitura (início da tarefa)

- **Li:** `AGENTS.md` (seções 0, 2, 3, 8, 10, 12, 14 a 16); `DECISIONS.md` (cabeçalho, índice, DEC-047, 049, 054, 083, 084, 126 a 128, seções 7 e 8); o roadmap (Fase 3 inteira, 3.A a 3.J, visão geral, 2.F critério 8, Anexos D, E e F); `docs/decisions/0011-revisao-fase-2.md` (o modelo); o pré-voo da B (`git show a23f5ae:STATUS-B.md`, seções b a e). **Conferi, para citar certo:** backlog (linha dos ids de conteúdo), arquitetura (8.6, 11.5, 11.8, 11.10, 15.4), GDD 12.5, `docs/fase-2/LW-086-relatorio-de-fechamento.md`, e nos ramos da B e da C as perguntas Q1 a Q14 e D1 (`economy.md`, `dados.md`) e Q-W1 a Q-W6 e Q18 a Q22 (`world.md`, `npc.md`).
- **Decisões de que dependo e status:** DEC-047, 049 e 054 PROPOSTA → APROVADA por ordem sua; DEC-083 APROVADA (só os princípios); DEC-084 APROVADA (formato do protótipo); DEC-126, 127 e 128 APROVADAS; DEC-041 APROVADA; DEC-048 PROPOSTA (SP7); DEC-040 PENDENTE (não bloqueia).
- **A ordem chegou em duas versões** (a segunda trocou o status dos menores 7 a 11 e das respostas Q1 a Q22 para PROPOSTA e acrescentou Q10, Q19 e Q22 como decisões suas). Registrei a segunda; a primeira só chegou a existir no meu rascunho de trabalho, antes do commit.

## Como agrupei as entradas (pedido seu)

**34 entradas novas** (DEC-129 a DEC-162) e **3 mudanças de status** (DEC-047, 049 e 054). Uma entrada por decisão, exceto onde a decisão é a mesma:

| Entrada | O que é | Status | Origem | Agrupei? |
|---|---|---|---|---|
| DEC-129 | Escala: 3 povoados, 10 bens, 4 cadeias | APROVADA (valores [HIP]) | sua ordem, item 2 | não |
| DEC-130 a 135 | As seis correções do pré-voo (dono das quantidades; `TradeFlow` sem S2; `npc` e `economy` só por `economy/api` e evento; `mint` inicial antes da LW-094; save não congelado; escopo do `check_temp`) | APROVADA | item 3 | **não: uma entrada por correção** |
| DEC-136 | Não dividir `npc_module`, `npc_thinker`, `action_runner` | APROVADA | item 4 | não |
| DEC-137 | LW-093a (ids de conteúdo, com a D1) e LW-093b (ofício só por JSON) | APROVADA | item 4 | **sim, as duas subtarefas**: são o que entra no lugar da divisão |
| DEC-142, 143, 144 | Q10 (ofícios e cadeias), Q19 (comprar por utilidade), Q22 (emprego) | APROVADA | item 5, "decisões minhas" | não |
| DEC-138, 139, 140 | Menores 7 (tributos), 8 (alvo de estoque), 9 (`RouteStateChanged` e fechar rota) | PROPOSTA | item 5, revisor | não |
| DEC-141 | Menores 10 (sem `entities`) e 11 (`TradeRules` ao construtor) | PROPOSTA | item 5, revisor | **sim**: duas correções de texto da arquitetura sem efeito na Fase 3 |
| DEC-145 | Q1 (B) e Q21 (C): quem abre as contas | PROPOSTA | revisor | **sim**: a mesma decisão vista da economia e do `npc` |
| DEC-146, 147, 148, 149 | Q2 (dono morto), Q3 (`game_start`), Q4 (local dono de si), Q5 (conta do mercado) | PROPOSTA | revisor | não |
| DEC-150 | Q6 e Q7: forma do preço, spread e profundidade | PROPOSTA | revisor | **sim**: duas fórmulas da mesma seção do contrato |
| DEC-151, 152 | Q8 (trabalho, salário e vendas) e Q18 (salário alivia `income`) | PROPOSTA | revisor | **não**, de propósito: há tensão entre as duas (ver Problemas) |
| DEC-153 | Q9 (B) e Q20 (C): só comida; pão por inteiro, grão menos | PROPOSTA | revisor | **sim**: o que o NPC consome |
| DEC-154, 155, 156, 157 | Q11 (perecibilidade), Q12 (três eventos fora), Q13 (conservação de bens), Q14 (contratos) | PROPOSTA | revisor | não |
| DEC-158 | Q-W1: triângulo de rotas | PROPOSTA | revisor | não |
| DEC-159 | Q-W2 e Q-W3: só `open` e `closed`, nenhum campo extra | PROPOSTA | revisor | **sim**: o formato da rota |
| DEC-160, 161, 162 | Q-W4 (`market_reserved` → `market`), Q-W5 (não ampliar o terreno), Q-W6 (aceitar a mudança de hash) | PROPOSTA | revisor | não |

**Totais recontados por script (índice = cabeçalhos, sem número repetido): APROVADA 82 (20 com ressalva) · PROPOSTA 51 · PENDENTE 18 · DESCARTADA 10 · SUBSTITUÍDA 1 = 162.** Antes (LW-085e): 67 (19) · 32 · 18 · 10 · 1 = 128. Conta: APROVADA 67 + 3 (DEC-047, 049 e 054) + 12 novas = 82; PROPOSTA 32 − 3 + 22 novas = 51; PENDENTE, DESCARTADA e SUBSTITUÍDA não mudam; total 128 + 34 = 162. A ressalva nova é a DEC-129 (valores seguem [HIP]). O próximo número livre é **DEC-163**; a versão do documento é **0.6**; há linha 0.6 no histórico.

## B1 — ANTES e DEPOIS exatos: `docs/DECISIONS.md`

Trechos do diff contra o `main` `8dcc81d`. As 34 entradas novas aparecem como resumo (o texto completo está no arquivo, de `### DEC-129` a `### DEC-162`, antes da seção 3).

**Trecho 1** (`-3 +3`)

ANTES:

> **Versão do documento:** 0.5 (10/11/2026; entradas DEC-126 a DEC-128 acrescentadas e totais recontados; a 0.4 é de 09/11/2026; ver seção 8)

DEPOIS:

> **Versão do documento:** 0.6 (10/11/2026; DEC-047, DEC-049 e DEC-054 aprovadas e entradas DEC-129 a DEC-162 acrescentadas (LW-087a) e totais recontados; a 0.5 é de 10/11/2026 (LW-085e); ver seção 8)


**Trecho 2** (`-57 +57`)

ANTES:

> **Totais atualizados em 10/11/2026 (LW-085e, recontados a partir das linhas das tabelas abaixo, pelo mesmo método da LW-033A):** APROVADA: 67 (19 com ressalva) · PROPOSTA: 32 · PENDENTE: 18 · DESCARTADA: 10 · SUBSTITUÍDA: 1 · **Total: 128**. As 3 aprovadas a mais desde a LW-071f são a DEC-126, a DEC-127 e a DEC-128; nenhuma ressalva nova. **Totais atualizados em 09/11/2026 (LW-071f, recontados a partir das linhas das tabelas abaixo, pelo mesmo método da LW-033A):** APROVADA: 64 (19 com ressalva) · PROPOSTA: 32 · PENDENTE: 18 · DESCARTADA: 10 · SUBSTITUÍDA: 1 · **Total: 125**. As 2 aprovadas a mais desde a LW-071b são a DEC-124 e a DEC-125; nenhuma ressalva nova. **Totais de 09/11/2026 (LW-071b, recontados a partir das linhas das tabelas abaixo, pelo mesmo método da LW-033A):** APROVADA: 62 (19 com ressalva) · PROPOSTA: 32 · PENDENTE: 18 · DESCARTADA: 10 · SUBSTITUÍDA: 1 · **Total: 123**. As 5 aprovadas a mais desde a LW-033A são a DEC-119, a DEC-120, a DEC-121, a DEC-122 e a DEC-123; as 3 ressalvas a mais são a DEC-121, a DEC-122 e a DEC-123. **Totais de 05/11/2026 (LW-033A, recontados a partir das linhas das tabelas abaixo):** APROVADA: 57 (16 com ressalva) · PROPOSTA: 32 · PENDENTE: 18 · DESCARTADA: 10 · SUBSTITUÍDA: 1 · **Total: 118**. Antes da LW-033A as tabelas somavam 52 (15 com ressalva) · 32 · 19 · 10 · 1 = 114; a linha de totais anterior (48 · 34 · 19 · 10 · 1 = 112) já estava defasada em relação às tabelas. Na v0.3 inicial eram 47 · 34 · 20 · 10 · 1.

DEPOIS:

> **Totais atualizados em 10/11/2026 (LW-087a, recontados a partir das linhas das tabelas abaixo, pelo mesmo método da LW-033A):** APROVADA: 82 (20 com ressalva) · PROPOSTA: 51 · PENDENTE: 18 · DESCARTADA: 10 · SUBSTITUÍDA: 1 · **Total: 162**. Desde a LW-085e: a DEC-047, a DEC-049 e a DEC-054 passaram de PROPOSTA a APROVADA; entraram 12 entradas APROVADAS por Arthur (DEC-129 a DEC-137 e DEC-142 a DEC-144) e 22 entradas PROPOSTA decididas pelo revisor (DEC-138 a DEC-141 e DEC-145 a DEC-162); a ressalva nova é a DEC-129 (valores seguem [HIP]). **Totais atualizados em 10/11/2026 (LW-085e, recontados a partir das linhas das tabelas abaixo, pelo mesmo método da LW-033A):** APROVADA: 67 (19 com ressalva) · PROPOSTA: 32 · PENDENTE: 18 · DESCARTADA: 10 · SUBSTITUÍDA: 1 · **Total: 128**. As 3 aprovadas a mais desde a LW-071f são a DEC-126, a DEC-127 e a DEC-128; nenhuma ressalva nova. **Totais atualizados em 09/11/2026 (LW-071f, recontados a partir das linhas das tabelas abaixo, pelo mesmo método da LW-033A):** APROVADA: 64 (19 com ressalva) · PROPOSTA: 32 · PENDENTE: 18 · DESCARTADA: 10 · SUBSTITUÍDA: 1 · **Total: 125**. As 2 aprovadas a mais desde a LW-071b são a DEC-124 e a DEC-125; nenhuma ressalva nova. **Totais de 09/11/2026 (LW-071b, recontados a partir das linhas das tabelas abaixo, pelo mesmo método da LW-033A):** APROVADA: 62 (19 com ressalva) · PROPOSTA: 32 · PENDENTE: 18 · DESCARTADA: 10 · SUBSTITUÍDA: 1 · **Total: 123**. As 5 aprovadas a mais desde a LW-033A são a DEC-119, a DEC-120, a DEC-121, a DEC-122 e a DEC-123; as 3 ressalvas a mais são a DEC-121, a DEC-122 e a DEC-123. **Totais de 05/11/2026 (LW-033A, recontados a partir das linhas das tabelas abaixo):** APROVADA: 57 (16 com ressalva) · PROPOSTA: 32 · PENDENTE: 18 · DESCARTADA: 10 · SUBSTITUÍDA: 1 · **Total: 118**. Antes da LW-033A as tabelas somavam 52 (15 com ressalva) · 32 · 19 · 10 · 1 = 114; a linha de totais anterior (48 · 34 · 19 · 10 · 1 = 112) já estava defasada em relação às tabelas. Na v0.3 inicial eram 47 · 34 · 20 · 10 · 1.


**Trecho 3** (`-142,0 +143,2`)

ANTES: _(nada; só acréscimo)_

DEPOIS:

> | DEC-143 | Comprar é escolhida pelo mesmo mecanismo de utilidade (valor derivado), sem rotina fixa e sem planejador | APROVADA |

> | DEC-144 | A população inicial nasce empregada; a vaga nova é oferecida por evento e aceita pela utilidade | APROVADA |


**Trecho 4** (`-150 +152`)

ANTES:

> | DEC-047 | Dinheiro e quantidades em números inteiros, com livro-razão (`Ledger`) | PROPOSTA |

DEPOIS:

> | DEC-047 | Dinheiro e quantidades em números inteiros, com livro-razão (`Ledger`) | APROVADA |


**Trecho 5** (`-152 +154`)

ANTES:

> | DEC-049 | `TradeRules` como único ponto em que a política altera a economia | PROPOSTA |

DEPOIS:

> | DEC-049 | `TradeRules` como único ponto em que a política altera a economia | APROVADA |


**Trecho 6** (`-157 +159,24`)

ANTES:

> | DEC-054 | Itens fora do protótipo (cercos, exércitos grandes, intriga, sucessão, magia ampla, domesticação, famílias,… | PROPOSTA |

DEPOIS:

> | DEC-054 | Itens fora do protótipo (cercos, exércitos grandes, intriga, sucessão, magia ampla, domesticação, famílias,… | APROVADA |

> | DEC-129 | Escala da economia do protótipo: 3 povoados, 10 bens genéricos e 4 cadeias de produção | APROVADA (valores seguem [HIP]) |

> | DEC-130 | A `economy` guarda as quantidades de bens de todo dono, por ID | APROVADA |

> | DEC-131 | O `TradeFlow` é uma abstração econômica por rota, sem depender de S2 | APROVADA |

> | DEC-132 | O `npc` importa só `economy/api`; a economia nunca importa o `npc`; o contrato de trabalho chega por evento | APROVADA |

> | DEC-133 | O dinheiro inicial (`mint`) existe antes de a LW-094 remover o `FoodStub` | APROVADA |

> | DEC-138 | Tributos e impostos: na Fase 3 valem as regras do roadmap, não o "tributos" [P1] do GDD | PROPOSTA |

> | DEC-139 | O alvo de estoque de cada mercado é dado fixo na Fase 3 | PROPOSTA |

> | DEC-140 | `RouteStateChanged` e o comando de fechar rota pertencem à LW-097 | PROPOSTA |

> | DEC-141 | Dois acertos de texto da arquitetura: IDs de `ctx.ids` (sem `entities`) e `TradeRules` entregue ao construtor | PROPOSTA |

> | DEC-142 | Ofícios `miner` e `shepherd` só em dados, cadeias distribuídas pelos 3 povoados e 3º povoado na LW-097 | APROVADA |

> | DEC-145 | Quem abre as contas: cada dono abre a sua (o `npc` pela `economy/api`) e a economia faz o `mint` inicial | PROPOSTA |

> | DEC-146 | Dono morto: a conta e o inventário se fecham ao ouvir `NpcDied`, sem sair da soma | PROPOSTA |

> | DEC-147 | Motivos do `Ledger` em inglês (`game_start`), em conjunto fechado, e saldos iniciais por tipo de dono | PROPOSTA |

> | DEC-148 | O local de produção é dono de si (conta e inventário próprios) | PROPOSTA |

> | DEC-149 | O mercado tem conta própria e paga o produtor com ela | PROPOSTA |

> | DEC-150 | Forma do preço: inversa do estoque sobre o alvo, com spread e profundidade | PROPOSTA |

> | DEC-151 | Trabalho, salário e vendas dos locais | PROPOSTA |

> | DEC-152 | O salário alivia a necessidade `income` por um evento de pagamento ouvido pelo `npc` | PROPOSTA |

> | DEC-153 | Na Fase 3 o NPC só consome comida: o pão sacia a fome por inteiro e o grão, menos | PROPOSTA |

> | DEC-154 | Perecibilidade: o campo existe e não faz nada na Fase 3 | PROPOSTA |

> | DEC-155 | `CaravanAttacked`, `RouteCargoLost` e `BusinessBankrupt` não entram na Fase 3 | PROPOSTA |

> | DEC-156 | Conservação de bens, simétrica à do dinheiro | PROPOSTA |

> | DEC-157 | Contratos: `labor` (minutos de trabalho num local) e `delivery` (bem no destino) | PROPOSTA |


**Trecho 7** (`-170,0 +196,5`)

ANTES: _(nada; só acréscimo)_

DEPOIS:

> | DEC-158 | As três rotas formam um triângulo (A–B, A–C e B–C) | PROPOSTA |

> | DEC-159 | A rota tem só os estados `open` e `closed` e nenhum campo extra | PROPOSTA |

> | DEC-160 | O tipo de local `market_reserved` é renomeado para `market` na LW-093 | PROPOSTA |

> | DEC-161 | O terreno de blockout não é ampliado para o 3º povoado | PROPOSTA |

> | DEC-162 | A LW-097 aceita a mudança de hash e atualiza o oráculo, com a aprovação de Arthur dos valores novos | PROPOSTA |


**Trecho 8** (`-213,0 +244`)

ANTES: _(nada; só acréscimo)_

DEPOIS:

> | DEC-134 | O save não é congelado na Fase 3: a LW-111 rejeita o save antigo com mensagem clara | APROVADA |


**Trecho 9** (`-233,0 +265,3`)

ANTES: _(nada; só acréscimo)_

DEPOIS:

> | DEC-135 | O `check_temp` (LW-114) olha `src/`, `data/`, `tests/`, `tools/` e `scenes/`, e não `docs/` | APROVADA |

> | DEC-136 | Não dividir `npc_module.gd`, `npc_thinker.gd` nem `action_runner.gd` antes da LW-093 | APROVADA |

> | DEC-137 | Duas subtarefas pequenas antes da LW-093: LW-093a (ids de conteúdo) e LW-093b (ofício só por JSON) | APROVADA |


**Trecho 10** (`-842 +876`)

ANTES:

> | **Status** | PROPOSTA |

DEPOIS:

> | **Status** | APROVADA por Arthur em 10/11/2026 (antes: PROPOSTA). |


**Trecho 11** (`-846,2 +880,2`)

ANTES:

> | **Consequências** | Se aprovada, vira regra de revisão e teste automático (`check_all`). |

> | **Data / versão** | TA 0.1 cap. 11.3 e 11.4 · GDD 0.1 cap. 12.3 · registrada em 01/11/2026 |

DEPOIS:

> | **Consequências** | Se aprovada, vira regra de revisão e teste automático (`check_all`). **Aprovada por Arthur em 10/11/2026 (LW-087a):** vale como regra de revisão e de teste (o `AGENTS.md` 4.11 já a usa); a LW-088 implementa o `Ledger` e o teste de conservação. Uma só moeda: DEC-054. |

> | **Data / versão** | TA 0.1 cap. 11.3 e 11.4 · GDD 0.1 cap. 12.3 · registrada em 01/11/2026 · aprovada por Arthur em 10/11/2026 (LW-087a; `docs/decisions/0012-pre-voo-da-fase-3.md`, seção 6) |


**Trecho 12** (`-866 +900`)

ANTES:

> | **Status** | PROPOSTA |

DEPOIS:

> | **Status** | APROVADA por Arthur em 10/11/2026 (antes: PROPOSTA). |


**Trecho 13** (`-870,2 +904,2`)

ANTES:

> | **Consequências** | Qualquer novo efeito político sobre a economia passa por essa interface. |

> | **Data / versão** | TA 0.1 cap. 11.8 e 13.5 · registrada em 01/11/2026 |

DEPOIS:

> | **Consequências** | Qualquer novo efeito político sobre a economia passa por essa interface. **Aprovada por Arthur em 10/11/2026 (LW-087a):** é a única inversão de dependência do projeto; na Fase 3 só existe a versão neutra (nada proibido, nenhuma tarifa); regras reais de política só na Fase 4 (DEC-138). |

> | **Data / versão** | TA 0.1 cap. 11.8 e 13.5 · registrada em 01/11/2026 · aprovada por Arthur em 10/11/2026 (LW-087a; `docs/decisions/0012-pre-voo-da-fase-3.md`, seção 6) |


**Trecho 14** (`-926 +960`)

ANTES:

> | **Status** | PROPOSTA |

DEPOIS:

> | **Status** | APROVADA por Arthur em 10/11/2026 (antes: PROPOSTA). |


**Trecho 15** (`-930,2 +964,2`)

ANTES:

> | **Consequências** | Cada item pode voltar por decisão de Arthur, com ID novo. O destino de cada um está no RM Anexo E. |

> | **Data / versão** | GDD 0.1 cap. 24.3 · RM 0.1 cap. 0.14 e Anexo E · registrada em 01/11/2026 |

DEPOIS:

> | **Consequências** | Cada item pode voltar por decisão de Arthur, com ID novo. O destino de cada um está no RM Anexo E. **Aprovada por Arthur em 10/11/2026 (LW-087a), a entrada inteira:** o que a Decisão acima chama de "apenas proposta" passa a valer também; na Fase 3 vale em especial "uma só moeda" (DEC-047). Cada item do título pode voltar por decisão nova de Arthur, com ID novo (Anexo E do roadmap). |

> | **Data / versão** | GDD 0.1 cap. 24.3 · RM 0.1 cap. 0.14 e Anexo E · registrada em 01/11/2026 · aprovada por Arthur em 10/11/2026 (LW-087a; `docs/decisions/0012-pre-voo-da-fase-3.md`, seção 6) |


**Trecho 16 — entradas novas (34): DEC-129 a DEC-162.** Texto completo no arquivo (`docs/DECISIONS.md`).

**Trecho 17** (`-2063 +2573`)

ANTES:

> Copiar, preencher e usar o próximo número livre (`DEC-129` em diante). **Nunca reutilizar um número.**

DEPOIS:

> Copiar, preencher e usar o próximo número livre (`DEC-163` em diante). **Nunca reutilizar um número.**


**Trecho 18** (`-2094,0 +2605`)

ANTES: _(nada; só acréscimo)_

DEPOIS:

> | 0.6 | 10/11/2026 | DEC-047, DEC-049 e DEC-054 passaram de PROPOSTA a APROVADA por Arthur (LW-087a) e foram acrescentadas as entradas DEC-129 a DEC-162, a partir de `docs/decisions/0012-pre-voo-da-fase-3.md`. **APROVADAS por Arthur (12):** escala da economia (3 povoados, 10 bens, 4 cadeias); as seis correções do pré-voo (dono das quantidades, `TradeFlow` sem S2, `npc` e `economy` só por `economy/api` e evento, `mint` inicial antes da LW-094, save não congelado, escopo do `check_temp`); não dividir os três arquivos do `npc` e as subtarefas LW-093a e LW-093b; e as perguntas Q10 (ofícios e cadeias), Q19 (comprar por utilidade) e Q22 (emprego). **PROPOSTA, decididas pelo revisor (22), padrão de trabalho e não APROVADAS:** os menores 7 a 11 do pré-voo e as respostas às perguntas Q1 a Q9, Q11 a Q14, Q18, Q20 e Q21 (contratos da `economy` e do `npc`) e Q-W1 a Q-W6 (rotas e 3º povoado). Totais recontados por script (APROVADA: 82 (20 com ressalva), PROPOSTA: 51, PENDENTE: 18, DESCARTADA: 10, SUBSTITUÍDA: 1; total 162). Das entradas antigas só mudaram o status, a consequência e a data das três citadas; nenhuma outra foi alterada. |

## B1 — ANTES e DEPOIS exatos: `docs/DEVELOPMENT_ROADMAP.md`

Só as linhas abaixo mudaram (14 trechos; 23 linhas acrescentadas e 14 removidas, conferido por `git diff --numstat`). **Linhas que a sua ordem não citava e que mudei por coerência** (peço confirmação, ver Pendências): 3.B (escala), o critério 9 de 3.F e a linha de save de 3.G, o Anexo D (escopo do `check_temp`), o diagrama de 3.E, a nota sob a tabela 3.D, a dependência da LW-094 e o `incremento de save_version` da LW-111.

**Trecho 1** (`-750 +750`)

ANTES:

> - Escala do protótipo: **3 assentamentos**, **8 a 12 bens**, **4 cadeias de produção** **[HIP]** (ajustável por decisão sua).

DEPOIS:

> - Escala do protótipo (decisão sua de 10/11/2026, DEC-129): **3 povoados (assentamentos)**, **10 bens genéricos**, **4 cadeias de produção**; os valores seguem **[HIP]** (ajustáveis por decisão sua).


**Trecho 2** (`-770 +770,4`)

ANTES:

> | **LW-087** | DOC | **Contratos** de `economy` (bens, inventário, mercados, produção, consumo, `Ledger`, comércio, contratos), da interface **`TradeRules`**, eventos econômicos em `docs/events.md` (cap. 11.9) e **modelos de dados** (`goods`, `recipes`, constantes de preço). Registrar a lista de 8 a 12 bens e 4 cadeias, **genéricos** | LW-086 | Fichas em `docs/modules/`; dono único para estoque, preço e dinheiro; lista de bens e cadeias aprovada por você |

DEPOIS:

> | **LW-087a** | DOC | **Registro das decisões da Fase 3** em `docs/DECISIONS.md` e `docs/decisions/0012-pre-voo-da-fase-3.md`: aprovação das DEC-047, DEC-049 e DEC-054; escala (3 povoados, 10 bens e 4 cadeias, **genéricos**; DEC-129); as seis correções do pré-voo (DEC-130 a DEC-135); a preparação da LW-093 (DEC-136 e DEC-137); os menores 7 a 11 (DEC-138 a DEC-141); as decisões de Arthur sobre Q10, Q19 e Q22 (DEC-142 a DEC-144) e as respostas do revisor às demais perguntas dos contratos (DEC-145 a DEC-162, PROPOSTA) | LW-086 | Entradas e registro aprovados por você; lista de bens e cadeias aprovada por você; as respostas PROPOSTA (DEC-138 a DEC-141 e DEC-145 a DEC-162) revistas por você, que pode trocá-las |

> | **LW-087b** | DOC | **Contrato** de `economy` em `docs/modules/economy.md` (bens, inventário como quantidades de todo dono por ID, mercados, produção, consumo, `Ledger`, comércio, contratos) e da interface **`TradeRules`** (só a versão neutra na Fase 3) | LW-087a | Ficha em `docs/modules/economy.md`; dono único para estoque, preço e dinheiro; aprovada por você |

> | **LW-087c** | DOC | Extensões de `docs/modules/world.md` (rotas e terceiro povoado) e de `docs/modules/npc.md` (comprar, vender, salário e fim dos provisórios; o `npc` importa só `economy/api`) | LW-087a | Fichas atualizadas, sem código; aprovadas por você |

> | **LW-087d** | DOC | **Eventos econômicos** do cap. 11.9 em `docs/events.md` e **modelos de dados** (`goods`, `recipes`, constantes de preço e alvo de estoque) | LW-087a | Eventos catalogados; modelos de dados revisados; aprovados por você |


**Trecho 3** (`-772 +775`)

ANTES:

> | **LW-089** | IMPL | `economy/goods` e **inventário por entidade**: `GoodDef` em `data/goods.json` (10 bens genéricos **[HIP]**) e tabela de inventários (NPC, jogador, local de produção, mercado) com quantidades inteiras e peso | LW-087 | Testes: validação de bens; adicionar, remover e transferir; peso e capacidade respeitados; ida e volta de save |

DEPOIS:

> | **LW-089** | IMPL | `economy/goods` e **inventário por entidade**: `GoodDef` em `data/goods.json` (10 bens genéricos **[HIP]**; DEC-129) e tabela de inventários (NPC, jogador, local de produção, mercado) com quantidades inteiras e peso; a `economy` guarda as **quantidades** de todo dono, por ID, e o equipamento em instâncias fica no `character` (Fase 5) (DEC-130) | LW-087 | Testes: validação de bens; adicionar, remover e transferir; peso e capacidade respeitados; ida e volta de save |


**Trecho 4** (`-776,3 +779,5`)

ANTES:

> | **LW-093** | IMPL | **NPCs no mercado:** ações de catálogo **comprar** e **vender** via `request_trade`; produtor vende excedente ao mercado local; **consumo** de comida e outros bens a partir do inventário; ajuste do catálogo e dos pré-requisitos | LW-091, LW-092, LW-059, LW-060 | Testes: NPC faminto com dinheiro compra e come; sem dinheiro não compra; produtor vende excedente; nenhum caminho altera saldo fora do `Ledger` |

> | **LW-094** | IMPL | **Remover `FoodStub` (TEMP-LW-065):** NPCs passam a obter comida do mercado ou do próprio inventário; apagar o stub e atualizar testes | LW-093, LW-065 | `FoodStub` não existe mais; busca por `TEMP-LW-065` não encontra nada; vida sem jogador (30 dias) continua verde com a economia real; se falta comida, aparece escassez e não "comida mágica" |

> | **LW-095** | IMPL | **Remover `IncomeStub` (TEMP-LW-066) e introduzir salários:** locais de produção **pagam os trabalhadores pelo `Ledger`**; a necessidade renda passa a ser atendida pelo dinheiro recebido; dinheiro inicial criado por `mint` com motivo `inicio_de_jogo` | LW-092, LW-088, LW-066 | `IncomeStub` removido; busca por `TEMP-LW-066` vazia; trabalhador recebe salário; empregador sem saldo para a produção e registra o motivo; teste de ouro verde |

DEPOIS:

> | **LW-093a** | IMPL | **Verificador de ids de conteúdo** (cerca de 60 linhas, mais a conferência entre módulos, em `tools/`): confere que os ids de conteúdo escritos como constantes no código (`"work"`, `"help"`, `"flee"`...) existem em `data/` e que os ids que as tabelas da economia citam de outro módulo (`need_id`, `occupation_id`, `settlement_id`, `place_id`) existem; nenhum comportamento de jogo muda (DEC-137) | LW-086, LW-089, LW-092 | Id removido ou trocado em `data/` deixa o `check_all` VERMELHO, com mensagem que aponta o id e o arquivo; com os ids certos, VERDE |

> | **LW-093b** | TESTE | **Ofício novo só por JSON:** teste de que um ofício acrescentado só em `data/`, sem tocar código, funciona e é validado, como já existe para a ação (ressalva ao critério 8 de 2.F); só teste, nenhum código de jogo (DEC-137) | LW-086 | O ofício novo passa na validação e é usado; um ofício inválido é recusado pela validação com mensagem clara |

> | **LW-093** | IMPL | **NPCs no mercado:** ações de catálogo **comprar** e **vender** via `request_trade`; produtor vende excedente ao mercado local; **consumo** de comida e outros bens a partir do inventário; ajuste do catálogo e dos pré-requisitos; o `npc` importa só `economy/api` e a economia nunca importa o `npc` (DEC-132); o dinheiro inicial (`mint`, motivo `game_start`; DEC-147) é criado aqui, ou a LW-095 passa a vir antes da LW-094 (DEC-133) | LW-093a, LW-093b, LW-091, LW-092, LW-059, LW-060 | Testes: NPC faminto com dinheiro compra e come; sem dinheiro não compra; produtor vende excedente; nenhum caminho altera saldo fora do `Ledger`; o dinheiro inicial só nasce por `mint` com motivo |

> | **LW-094** | IMPL | **Remover `FoodStub` (TEMP-LW-065):** NPCs passam a obter comida do mercado ou do próprio inventário; apagar o stub e atualizar testes | LW-093, LW-065 (e a LW-095, se a ordem for trocada; DEC-133) | `FoodStub` não existe mais; busca por `TEMP-LW-065` em `src/`, `data/`, `tests/`, `tools/` e `scenes/` não encontra nada (DEC-135); vida sem jogador (30 dias) continua verde com a economia real; se falta comida, aparece escassez e não "comida mágica" |

> | **LW-095** | IMPL | **Remover `IncomeStub` (TEMP-LW-066) e introduzir salários:** locais de produção **pagam os trabalhadores pelo `Ledger`**; a necessidade renda passa a ser atendida pelo dinheiro recebido; o dinheiro inicial, criado por `mint` com motivo `game_start` (DEC-147), já existe desde a LW-093 (ou é criado aqui, se a LW-095 vier antes da LW-094; DEC-133); o vínculo de trabalho chega à economia por evento e a economia não importa o `npc` (DEC-132) | LW-092, LW-088, LW-066 | `IncomeStub` removido; busca por `TEMP-LW-066` vazia em `src/`, `data/`, `tests/`, `tools/` e `scenes/` (DEC-135); trabalhador recebe salário; empregador sem saldo para a produção e registra o motivo; teste de ouro verde |


**Trecho 5** (`-783 +788`)

ANTES:

> | **LW-100** | IMPL | `economy/trade`: **fluxo agregado (`TradeFlow`)** entre mercados distantes: bem, quantidade por dia, atraso e risco por regra | LW-097, LW-090 | Testes: o fluxo move estoque entre mercados com atraso; rota fechada interrompe; risco reduz a entrega esperada; conservação de bens |

DEPOIS:

> | **LW-100** | IMPL | `economy/trade`: **fluxo agregado (`TradeFlow`)** entre mercados distantes: bem, quantidade por dia, atraso e risco por regra; é uma abstração econômica por rota e não depende de S2 (DEC-131) | LW-097, LW-090 | Testes: o fluxo move estoque entre mercados com atraso; rota fechada interrompe; risco reduz a entrega esperada; conservação de bens |


**Trecho 6** (`-788 +793`)

ANTES:

> | **LW-105** | IMPL | **Jogador na economia:** conta e inventário do jogador (peso), `request_trade` pelo jogador, dinheiro inicial por `mint` com motivo; eventos e textos por chaves | LW-089, LW-091, LW-035 | Testes: jogador compra e vende; peso máximo respeitado; saldo vem do `Ledger`; ida e volta de save |

DEPOIS:

> | **LW-105** | IMPL | **Jogador na economia:** conta e inventário do jogador (peso; as quantidades ficam na `economy`, por ID do jogador: DEC-130), `request_trade` pelo jogador, dinheiro inicial por `mint` com motivo `game_start` (DEC-147); eventos e textos por chaves | LW-089, LW-091, LW-035 | Testes: jogador compra e vende; peso máximo respeitado; saldo vem do `Ledger`; ida e volta de save |


**Trecho 7** (`-794 +799`)

ANTES:

> | **LW-111** | TESTE | **Salvar e carregar a economia:** preços, estoques, contas e contratos **exatos**; incremento de `save_version` com **migração simples e fixture** da versão anterior (proporcional ao que existe; migrações complexas só se houver necessidade real) | LW-110 | Hash idêntico após ida e volta; save da Fase 2 migra e carrega; arquivo adulterado é rejeitado |

DEPOIS:

> | **LW-111** | TESTE | **Salvar e carregar a economia:** preços, estoques, contas e contratos **exatos**; `save_version` continua em 2 (DEC-127) e o save da versão anterior é **rejeitado com mensagem clara**, sem migração: o save não é congelado (DEC-134) | LW-110 | Hash idêntico após ida e volta; save da Fase 2 é rejeitado com mensagem clara; arquivo adulterado é rejeitado |


**Trecho 8** (`-797 +802`)

ANTES:

> | **LW-114** | IMPL | **`tools/check_temp`:** falha se existir qualquer marca `TEMP-LW-` no repositório; integrar ao `check_all` | LW-094, LW-095 | Marca inserida de propósito faz o `check_all` ficar VERMELHO; sem marcas, VERDE |

DEPOIS:

> | **LW-114** | IMPL | **`tools/check_temp`:** falha se existir qualquer marca `TEMP-LW-` em `src/`, `data/`, `tests/`, `tools/` ou `scenes/` (fora de `docs/`; DEC-135); integrar ao `check_all` | LW-094, LW-095 | Marca inserida de propósito faz o `check_all` ficar VERMELHO; sem marcas, VERDE |


**Trecho 9** (`-800,0 +806,2`)

ANTES: _(nada; só acréscimo)_

DEPOIS:

> **Nota (LW-087a):** a LW-087 passa a quatro partes (087a a 087d, todas DOC); onde outra tarefa diz "depende de LW-087", leia-se 087a a 087d. A LW-087 continua sendo uma só tarefa na contagem, e a LW-093a e a LW-093b são subtarefas e não entram na contagem das 30 tarefas da fase.

>  


**Trecho 10** (`-805 +812`)

ANTES:

>     P2["Fase 2 concluída LW-086"] --> DOC["LW-087 Contratos"]

DEPOIS:

>     P2["Fase 2 concluída LW-086"] --> DOC["LW-087a a d Decisões e contratos"]


**Trecho 11** (`-814,0 +822,2`)

ANTES: _(nada; só acréscimo)_

DEPOIS:

>     A93["LW-093a Ids de conteúdo"] --> NPCM

>     B93["LW-093b Ofício só por JSON"] --> NPCM


**Trecho 12** (`-868 +877`)

ANTES:

> 9. **Save:** ida e volta exata; migração da versão anterior testada.

DEPOIS:

> 9. **Save:** ida e volta exata; save da versão anterior rejeitado com mensagem clara (DEC-134).


**Trecho 13** (`-880 +889`)

ANTES:

> | **Determinismo e save** | Mesma semente, mesmo hash; ida e volta; migração |

DEPOIS:

> | **Determinismo e save** | Mesma semente, mesmo hash; ida e volta; rejeição de save antigo |


**Trecho 14** (`-1504 +1513`)

ANTES:

> **Verificador:** `tools/check_temp` (LW-114) falha se existir qualquer `TEMP-LW-` no repositório. A partir da Fase 3 ele faz parte do `check_all`.

DEPOIS:

> **Verificador:** `tools/check_temp` (LW-114) falha se existir qualquer `TEMP-LW-` em `src/`, `data/`, `tests/`, `tools/` ou `scenes/`; não olha `docs/`, onde as marcas ficam como registro (DEC-135). As buscas pela marca citadas na tabela valem para esses mesmos diretórios. A partir da Fase 3 ele faz parte do `check_all`.

## 1. Resumo
O pré-voo da Fase 3 virou registro oficial, em rascunho. Aprovei no `DECISIONS.md` as DEC-047, 049 e 054 e registrei as decisões de hoje: as suas (escala, as seis correções, preparação da LW-093, Q10, Q19 e Q22) como APROVADA, e as do revisor (menores 7 a 11, Q1 a Q14, Q-W1 a Q-W6, Q18, Q20 e Q21) como PROPOSTA. O roadmap passou a dizer isso nas linhas que você citou. Nenhum código, dado, teste, `ROADMAP_STATUS.md` ou `README.md` foi tocado.

## 2. Arquivos criados
- `docs/decisions/0012-pre-voo-da-fase-3.md` — registro técnico (contexto, opções, escolha e consequências de cada decisão; como o 0011).

## 3. Arquivos modificados (contra o `main` `8dcc81d`)
- `docs/DECISIONS.md` — três status trocados (índice, status, consequência e data de cada entrada), 34 entradas novas e 34 linhas de índice, totais, versão 0.6, histórico e "próximo número".
- `docs/DEVELOPMENT_ROADMAP.md` — 23 linhas acrescentadas e 14 removidas (acima).
- Não toquei em `AGENTS.md`, GDD, arquitetura, `project.godot`, `data/`, `tests/fixtures/`, `ROADMAP_STATUS.md` nem `README.md`. Commits: `9e299eb` (conteúdo) e `44e29df` (junção com o `main` `8dcc81d`).

## 4. Decisões técnicas
- **PROPOSTA onde o revisor decidiu.** Cada entrada diz no próprio Status: "decidida pelo revisor … vale como padrão de trabalho e **não é APROVADA**" (AGENTS 3.2). Vale a regra de sempre: você pode trocar.
- **0012 cobre o pré-voo inteiro**, e não só os menores 7 a 11: as entradas de `DECISIONS.md` apontam para a seção certa dele. Assim o 0012 é o único lugar com opções e consequências.
- **Escolhi onde cada linha de índice entra:** economia na Área 6 (DEC-129 a 133, 138 a 142, 145 a 157), NPC na Área 5 (143 e 144), mundo na Área 7 (158 a 162), save na Área 9 (134) e processo na Área 10 (135 a 137).
- **LW-093a depende da LW-089 e da LW-092** (acrescentei): a conferência entre módulos precisa das tabelas da economia. **LW-093b** depende só da LW-086. A ordem, que você deixou comigo, é 093a, 093b, 093.
- **Escopo que a D1 acrescenta à LW-093a (você pediu o número):** de cerca de **60 para cerca de 100 linhas de código** (+40) e cerca de **40 de teste**; total perto de 140, dentro do limite do AGENTS 5.2. **É estimativa [HIP], não medida.** Se a conferência também rodasse no `app` ao montar o jogo (opção da B), a tarefa tocaria um segundo módulo; deixei só em `tools/` e em teste.
- **Motivo do dinheiro inicial:** troquei `inicio_de_jogo` por `game_start` nas linhas da LW-093 e da LW-095 e no texto da DEC-133. **Na LW-105 o texto só dizia "com motivo" (não havia o nome); acrescentei `game_start`.**
- **Proposta de entrada para `DECISIONS.md` / pedido de desvio:** nenhum (as entradas já estão no arquivo, por ordem sua).

## 5. Testes executados
- `git fetch origin '+refs/heads/main:refs/remotes/origin/main' '+refs/heads/status-a:refs/remotes/origin/status-a'` e `git merge --no-ff origin/main` (`8dcc81d`): **sem conflito**. O `main` não tinha mexido em `DECISIONS.md`, roadmap nem `AGENTS.md`.
- Script de recontagem (`python3 -I recount_decisions.py docs/DECISIONS.md`, escrito por mim, método da LW-033A): primeiro validado contra os totais de antes (67 (19) · 32 · 18 · 10 · 1 = 128, **CONFERE**), depois no arquivo novo: `índice=162 cabeçalhos=162 repetidos=nenhum só_no_índice=nenhum só_no_corpo=nenhum`, **CONFERE**.
- Conferência cruzada: todas as `DEC-NNN` citadas no roadmap existem no `DECISIONS.md`; todas as seções do 0012 citadas pelas entradas existem.
- `git diff --numstat` contra o `main`: `DECISIONS.md` 526 acréscimos e 15 remoções; roadmap 23 e 14. As 15 remoções do `DECISIONS.md` são versão, totais, 3 linhas de índice, 3×3 linhas das entradas antigas e o "próximo número".
- `godot --headless --path . --import` (com `/Applications/Godot 2.app/Contents/MacOS/Godot`): saiu 0.
- **`tools/check_all` no HEAD final `44e29df` (20:26:48 a 20:30:21, 10/11/2026): VERDE** (`EXIT_CODE_CHECK_ALL=0`).
- **NÃO EXECUTADO:** oráculo, vida de 30 dias, `run_sim` — a tarefa não toca código nem dados.

## 6. Resultados
- **`check_all`:** 124 scripts, **1.194 testes, 1.194 passando, 0 falhando**, 261.693 asserts, 170,7 s; 313 scripts sem aviso de compilação; nenhum "SCRIPT ERROR" nem "Parse Error".
- **Critério de aceite (cada item da sua ordem):** 1 — DEC-047, 049, 054 APROVADA, com índice, status, totais por script, versão, histórico e próximo número. 2 — escala (DEC-129). 3 — as seis correções (DEC-130 a 135), uma entrada cada. 4 — não dividir (DEC-136) e as subtarefas (DEC-137; roadmap). 5 — 0012 e entradas apontando para ele; APROVADAS e PROPOSTA separadas e escritas como tal. 6 — roadmap: LW-087 → 087a a 087d; ajustes só nas linhas citadas; nada renumerado.
- **Verifiquei como:** os 14 trechos do roadmap e os 18 do `DECISIONS.md` estão acima, gerados direto do Git (não digitados).

## 7. Problemas encontrados
- **Tensão entre duas recomendações (Q8 da B × Q18 da C).** A B diz `request_work_shift` com "salário na hora"; a C diz "por hora de produção, aos trabalhadores atribuídos, sem depender de a ação `work` terminar". Registrei as duas como entradas separadas (DEC-151 e DEC-152) com uma limitação escrita; alguém precisa conciliá-las ao revisar o `economy.md` e o `npc.md`.
- **A DEC-054 foi aprovada inteira.** O título lista 13 itens (cercos, magia, famílias, múltiplas moedas, multiplayer…); você escreveu "(uma só moeda)". Segui a ordem literal ("PROPOSTA → APROVADA"). Se só a moeda era a intenção, a entrada vira "APROVADA (somente uma só moeda)".
- **"Mint na LW-093, ou 095 antes da 094":** registrei os dois como aceitos (DEC-133 e roadmap). A escolha fica para quando a LW-093 for preparada.
- **Itens que ficaram só no registro, não no roadmap** (a sua ordem limita o roadmap às linhas citadas): o menor 9 (`RouteStateChanged` e fechar rota na LW-097), o renome `market_reserved` → `market` (LW-093), a aprovação dos hashes novos e a população do 3º povoado (LW-097, Q10 e Q-W6). Valem pelas DEC-140, 160, 162 e 142.
- **Entrada antiga desatualizada, que não reescrevi:** a DEC-031 diz "fica fora do protótipo (DEC-054, proposta)"; agora a DEC-054 é APROVADA. O DECISIONS.md proíbe reescrever entrada antiga.
- **A LW-111 também falava em "incremento de `save_version`"**, o que contradiz a DEC-127; troquei junto com o "migra". Idem o critério 9 de 3.F e a linha de save de 3.G.
- **`check_temp` olhando `tools/` e `tests/`:** o próprio verificador e o teste dele citam `TEMP-LW-`. A LW-114 precisa evitar que a regra se acione sozinha (limitação escrita no 0012, seção 2.6).

## 8. Riscos
- **As 22 entradas PROPOSTA** guiam o trabalho, mas você não as aprovou; se trocar alguma, o `economy.md` (087b), o `npc.md` e o `world.md` (087c) e os dados (087d) já escritos pela B e pela C precisam acompanhar.
- **A estimativa da D1** (+40 linhas de código, +40 de teste) é palpite com base nas quatro colunas; a medida real vem na LW-093a.
- **Divisões sugeridas pela B e NÃO decididas** (não estão no roadmap): 088a (casca do `EconomyModule`), 090, 092, 093, 094a/094b, 095 e 098 em duas ou três partes. Ficam para você.
- **Forma dos dados de receitas** (tabelas planas ou listas aninhadas): pendente (pré-voo, seção e); a 087d não a decide.

## 9. Pendências
- **Para você decidir** (cada uma com a minha recomendação): (1) DEC-054 inteira ou só a moeda — recomendo deixar inteira (o Anexo E já tira esses itens do roadmap). (2) Mint: LW-093 ou LW-095 antes da LW-094 — recomendo LW-093 (não muda a ordem das tarefas). (3) Confirmar as linhas que mudei além da lista (3.B, 3.F.9, 3.G, Anexo D, diagrama, nota de contagem, dependência da LW-094, `save_version` na LW-111) — recomendo manter, porque senão o roadmap contradiz a DEC-127 e a DEC-134. (4) Pôr nas linhas da LW-093, LW-097 e LW-114 os itens que hoje só estão nas DEC (renome `market`, menor 9, hashes) — recomendo pôr quando você autorizar mexer nessas linhas. (5) Rever as 22 PROPOSTA.
- **Fase B:** não autorizada para esta tarefa. Quando você aprovar o rascunho, a linha de status e o `README` entram junto da Fase B (ordem sua).
- **Teste manual:** nenhum (só texto). Basta ler o ANTES e o DEPOIS e o `0012`.

## ACOMPANHAMENTO
- **Avanço:** a LW-087a é a primeira parte da LW-087; a Fase 3 não começou (nenhuma contagem de status foi mudada).
- **Próxima tarefa recomendada:** a sua revisão do rascunho e, se aprovado, a Fase B da LW-087a; depois a LW-087b, 087c e 087d (os rascunhos da B e da C já existem e precisam ser ajustados a estas decisões, em especial `game_start` e a tensão Q8 × Q18). **Não iniciada.**
- **Decisões que dependem de você:** as cinco acima.
- **Git:** 2 commits no ramo `lw-087a-registro-fase-3` (`9e299eb`, `44e29df`), empurrados **só** esse ramo e o `status-a`; nada no `main`, nenhuma tag, sem `--force`.
