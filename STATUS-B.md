10/11/2026 20:36 (Brasília) — CONCLUÍDA: Tarefa 1 (revisão da LW-087c) já entregue às 20:17 e inalterada; Tarefa 2: LW-087b (`a815f85`) e LW-087d (`3b2a2de`) ajustadas, PRONTAS PARA REVISÃO como RASCUNHO fora do `main`; `check_all` verde nos dois; 3 pontos novos em aberto (Q15 a Q17); parei (regra 13)

# RELATÓRIO — Tarefa 1 (revisão da LW-087c) e Tarefa 2 (ajuste dos rascunhos LW-087b e LW-087d)

## TAREFA 1 — revisão da LW-087c: já entregue, nada mudou
A revisão foi entregue às 20:17 (commit `64dcded` do ramo `status-b`): **nenhum bloqueante, 5 importantes, 9 menores**. Conferi de novo antes de começar a Tarefa 2: o ramo `lw-087a-registro-fase-3` **continua sem existir**, o `STATUS-A.md` segue em "CONCLUÍDA" (LW-085e) e o ramo da 087c segue em `6dae235` (o mesmo que revisei). **O parecer vale como está.** Não repeti a revisão e não toquei no ramo revisado.

## TAREFA 2 — LW-087b e LW-087d: ajuste com as suas decisões     Status: PRONTA PARA REVISÃO, **RASCUNHO (não está no `main`)**

### 1. RESUMO
Ajustei os dois rascunhos às decisões de hoje. Na ficha `economy.md`, a seção 15 agora separa **o que você decidiu**, **o que o revisor decidiu (vale como proposta, e os menores 7 a 11 foram corrigidos para esse rótulo)** e **o que segue em aberto**. O desenho do salário, da vaga e da distribuição das cadeias foi reescrito conforme as decisões; `dados.md` e `events.md` acompanham. Só documento.

### 2. ARQUIVOS CRIADOS
Nenhum.

### 3. ARQUIVOS MODIFICADOS
- `docs/modules/economy.md` (ramo `lw-087b-contrato-economy`, `a815f85`): +80 −61 neste commit; 237 linhas.
- `docs/economy/dados.md` (56 linhas alteradas; 181 linhas) e `docs/events.md` (13 linhas alteradas; passa a 16 eventos: 6 existentes ou implementados e 10 planejados) no ramo `lw-087d-eventos-e-dados` (`3b2a2de`).
- Nada protegido, nada em `data/`, código ou testes; `DECISIONS.md` e roadmap intactos.

### 4. DECISÕES TÉCNICAS
- **Quem decidiu o quê.** Suas: DEC-047, DEC-049, DEC-054; escala; as seis recomendações da seção c; arquivos do `npc` não divididos mais o verificador **LW-093a**; **Q10** (ofícios `miner` e `shepherd` só em dados; nenhum povoado se basta; população do 3º povoado e hashes novos na LW-097 com a sua aprovação), **Q19** (`buy` pela utilidade, valor derivado) e **Q22** (população inicial empregada por dados; vaga por `ContractOffered`). Do revisor, como proposta: Q1 a Q9, Q11 a Q14, D1, Q18 A, Q20, Q21 A e os menores 7 a 11. **Corrigi o rótulo dos menores 7 a 11** em todas as ocorrências (cabeçalho e seções 4, 5 e 9): "decidido pelo revisor", não por você.
- **Q18 A (salário por hora).** Adotei como mandado: cada hora em que o local produz, ele paga o salário a **cada trabalhador atribuído**, tudo ou nada, **sem depender da ação `work` do NPC**. **Reserva minha, mantida e registrada:** o meu achado I1 apontava que um evento por trabalhador é laço quente (até 300 por hora) e não estava no catálogo. **Adaptação para respeitar a Q18 A sem esse risco:** **um** evento `WagesPaid` **por local e por hora** (`site_id` e `amount_each`); o `npc` lê a lista por `peek_site`. É evento novo, **[PROPOSTA]**, entrou no `events.md` (LW-095). O `request_work_shift` ficou **só para contrato `labor`**.
- **Quem trabalha onde.** O `npc` entrega o `work_place_id` ao abrir a conta (`request_open_owner(owner_id, kind, work_place_id)`, Q21 A) e a economia atribui o NPC ao local de produção daquele local; a lista é **derivada** (o dono do `work_place_id` segue sendo o `npc`) e um teste de integração (LW-095) confere que coincidem.
- **Vaga (Q22).** Tipo de contrato `vacancy` (sem custódia, sem prazo): aceitar atribui o NPC ao local e tira a atribuição anterior. **Escolha minha, rotulada como Q16** (o roadmap só tem contrato avulso e de entrega).
- **Distribuição das cadeias [PROPOSTA/HIP], seção 6 e `dados.md`.** **A** faz `grow_grain`, `mill_flour`, `cut_wood`, `saw_plank`; **B** faz `grow_grain`, `cut_wood`, `bake_bread`, `shear_wool`, `weave_fabric`; **C** faz `mine_ore`, `smelt_metal`, `forge_tool`: **12 locais de produção**, e cada povoado depende dos outros para algum bem (regra de dados testável). Respeita o que já existe: A e B têm lavradores e lenhadores. Exige locais `work` novos e a coluna `work_place_id` em `population.json` (mudança pequena de código do `npc`), tudo na LW-097.
- **D1 e a LW-093a.** Ids de outro módulo como texto livre mais conferência de dados entre módulos. **O escopo da 093a cresce de cerca de 60 para cerca de 150 a 200 linhas de código e teste** (um arquivo de verificação e um de teste), ainda dentro do teto da DEC-126; vem depois da LW-092 e antes da LW-093.
- **Dois erros meus, corrigidos** (achados I4 e I5 da revisão): (a) a ficha dizia que a regra D do `check_architecture` já cobria "economia não cita o `npc`"; **não cobre**: a LW-088a ganha uma regra nova (proposta); (b) a ficha dizia que o NPC aceitar contrato era [FUT], o que contradizia o roadmap (LW-104); agora o NPC aceita pela utilidade.
- **Proposta de entrada para o `DECISIONS.md`:** nenhuma nova (o registro é da LW-087a).

### 5. TESTES EXECUTADOS
- `tools/check_all` em `a815f85` (087b): **VERDE**, 124 scripts, 1194 testes, 261.693 asserts, 169,2 s; sem aviso novo (o "Warnings 1 / Deprecated 1" do GUT é o de sempre).
- `tools/check_all` em `3b2a2de` (087d): **VERDE**, os mesmos números, 169,4 s.
- Os dois rodaram em sequência (evita dois Godot no mesmo `user://`). `git diff --check` limpo. O `main` (`8dcc81d`) já estava dentro dos dois ramos; juntei-o no começo (**não é a Fase B**).

### 6. RESULTADOS
Cumprido o que foi pedido: seção 15 com a origem certa e sem as perguntas respondidas, rótulo dos menores corrigido, distribuição das cadeias e os 2 ofícios novos como [PROPOSTA/HIP] com nomes genéricos, D1 registrado, escopo da 093a relatado.

### 7. PROBLEMAS ENCONTRADOS (3 pontos novos, todos em aberto na seção 15)
- **Q15, guardas e estalajadeiros sem salário.** Os ofícios `guard` e `innkeeper` (14 pessoas em A e 8 em B hoje) não têm receita nem local de produção entre as 10 receitas: não recebem salário, então não compram comida e **morrem** no soak (risco R3.3). **Recomendo** um local de serviço por povoado, folha paga pela conta do mercado (o dinheiro circula). **É regra nova de jogo, decisão sua.**
- **Q17, o povoado C não produz comida e o comerciante só chega na LW-098.** Com a população do C nascendo na LW-097, ele passa fome e o soak de 30 dias (zero mortes) falha. **Recomendo** estoque inicial de comida no mercado do C para o horizonte do soak, e os soaks de 1 ano só depois da LW-098.
- **Q16**, o tipo `vacancy` (acima).
- **Pendências do rascunho da C que seguem abertas** (eu não as toco; são da 087c): o `npc.md` ainda usa `inicio_de_jogo` (agora decidido como `game_start`), a lista de parâmetros de `request_trade` sem `side` e as citações ao `STATUS-B.md` (achados M1, M2 e I3 da revisão). O mecanismo de salário do `npc.md` (Q18 A) agora **coincide** com a ficha, mas o dono da produção (achado I2: NPC ou local) continua precisando ser reescrito pela C.
- A referência cruzada entre os três arquivos só resolve quando os ramos entrarem juntos.

### 8. RISCOS
Espiral de morte (hora parada = ninguém recebe): calibração na LW-112. Troca de emprego em laço pela vaga: a utilidade do `npc` precisa de histerese (LW-104). Registrar a `economy` no `World` (LW-088a) também muda o `state_hash`, não só a LW-097 (achado M6, ainda vale). A tabela de distribuição é proposta e muda `population.json` e os hashes do `npc`.

### 9. PENDÊNCIAS
Suas decisões: **Q15, Q16, Q17**; aprovar (ou trocar) a **tabela de distribuição** e as **decisões do revisor**; o registro na LW-087a. Nenhum teste manual.

### ACOMPANHAMENTO
- **Avanço:** Fase 2 fechada (tag `fase-2-concluida`, 32 de 32); Fase 3 não iniciada. Dois rascunhos de documento ajustados, **fora do `main`**.
- **Próxima tarefa recomendada:** nenhuma minha (regra 13). Quando você mandar entrar: LW-087a (decisões, registro e os pontos Q15 a Q17).
- **Git:** `lw-087b-contrato-economy` em `a815f85` e `lw-087d-eventos-e-dados` em `3b2a2de`, publicados só como ramos; **nada no `main`, sem tag, sem Fase B**. O relatório anterior (revisão da 087c) está no commit `64dcded` do `status-b`; os rascunhos originais, no `205a284`.
