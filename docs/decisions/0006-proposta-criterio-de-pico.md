# Proposta de redação — critério de pico do SP1

- **Status:** PROPOSTA quanto à redação na arquitetura e no roadmap (não alterados até o resultado do release). **Aprovada por Arthur em 02/11/2026 como régua de medição da LW-023, a valer antes de medir o release** (DEC-113). Preparada em 02/11/2026.
- **Contexto e problema:** com a mesma máquina e o mesmo código (hash idêntico), duas execuções seguidas deram 2 e 14 passos acima de 10 ms (nuvem, depuração); no Mac, 7, 13 e 5. Um critério de "sem pico acima de ~10 ms" falha ou passa conforme a sorte da execução. Em compensação, um laço de controle sem o código do jogo também teve passos acima de 10 ms (~1,7 por minuto na nuvem), o que mostra que a máquina sozinha viola um limite absoluto.

## Texto atual (onde está e o que diz)
1. **Arquitetura, cap. 20.1 "Orçamentos de referência [HIP, a calibrar no spike SP1]"**, linha "Pico máximo de um tick": *"Sem tick que passe de ~10 ms (quebrar em fatias)"*.
2. **Arquitetura, cap. 26.3 "A validar por protótipos técnicos (spikes)", linha SP1, coluna "Critério de sucesso":** *"Tick dentro do orçamento (cap. 20); sem pico > ~10 ms; hash determinístico"*. Plano B: *"Reduzir frequências, compactar dados quentes, limitar contagens; só depois avaliar threads"*.
3. **Roadmap, tarefa LW-023, coluna "Critério":** *"critério da arquitetura (tick dentro do orçamento do cap. 20; sem pico acima de ~10 ms; hash determinístico) atingido, ou plano B (cap. 26.3) aplicado e medido de novo"*; e a **[Revisão Godot v0.2]**: *"Medir com binário de editor e com build de release (assert e verificações de depuração somem no release)"*.
4. **Roadmap, seção 0.F, critério 3:** *"Desempenho (SP1): 1.000 NPCs de mentira rodam 1 ano de jogo dentro do orçamento da arquitetura, ou o plano B está aplicado, medido e registrado."*

## A que build o critério se refere?
**Os textos não dizem.** A arquitetura (itens 1 e 2) não menciona build; o roadmap (item 3) manda medir nos dois (editor e release) sem dizer qual decide. Na prática, o que o jogador recebe é o **release**; o build de depuração (editor) tem verificações extras e é mais lento e mais ruidoso. Esta proposta torna isso explícito.

## Redação proposta (substitui o critério nos itens 2 a 4 se Arthur aprovar)
> **Critério de pico do SP1.** Medido em **build de release**, no **hardware de referência**, em **pelo menos 3 execuções completas** (1 ano de jogo, 1.000 NPCs de mentira, mesma semente), cada uma acompanhada do **laço de controle** (`run_sp1 --control`: mesmo número de passos e mesma duração média, sem o código do jogo). O SP1 é aprovado quando, em todas as execuções:
> 1. o hash de estado é idêntico entre as execuções;
> 2. a média por passo é de até 1 ms e o p99,9 é de até 3 ms **[HIP]**;
> 3. **nenhum passo passa de 50 ms** (limite duro: 3 quadros a 60 FPS) **[HIP]**;
> 4. a taxa de passos acima de 10 ms é de **no máximo 1 por minuto de execução contínua**, ou, se for maior, **não excede a taxa do laço de controle em mais de 1 por minuto** (ruído da máquina é registrado, não reprova) **[HIP]**;
> 5. os passos mais lentos **não se repetem nos mesmos passos** entre execuções (comparados com `compare_sp1_runs`); repetição indica trabalho periódico no código e reprova.
> As medições em **build de depuração** são informativas e devem ser registradas, mas não aprovam nem reprovam.

## Por que essa redação
- Troca um limite absoluto sujeito à sorte por **limites estatísticos e de taxa** que se repetem entre execuções.
- Separa **ruído da máquina** (controle) de **custo do código** (repetição nos mesmos passos), que são as duas hipóteses em disputa.
- Mantém um **limite duro** (50 ms) que protege o jogador de engasgos grandes.
- Define o build: **release decide**, depuração informa.

## Consequências e riscos
- Os números (1 ms, 3 ms, 50 ms, 1 por minuto) são **hipóteses** minhas; devem ser calibrados com a medição de release no Mac antes de virarem decisão. Com os dados atuais: na nuvem (depuração) o limite de 50 ms nunca foi ultrapassado, mas no Mac, em depuração, foram 73,4 e 88,2 ms; só a medição de release dirá se o item 3 passa.
- Exige 3 execuções de ~2 minutos cada (6 com controle), o que cabe no `check_all` apenas como medição manual, nunca como teste automático.
- Para aplicar, é preciso editar a arquitetura (arquivo protegido) e o roadmap; isso só ocorre com pedido expresso de Arthur numa tarefa de documentação.
- **Proposta de entrada para DECISIONS.md, se aprovada:** "Critério de pico do SP1: medido em release, por taxa e com laço de controle, conforme o texto acima".

### Régua do registro 0006 aplicada às seis medições (informativo: são todas de depuração)
Execução de 1 ano = cerca de 57 s (518.400 passos x ~108 µs); para as três do Codex, que não informaram a média, suponho o mesmo tempo. Itens da régua: (1) hash idêntico; (2) média ≤ 1 ms e p99,9 ≤ 3 ms; (3) nenhum passo > 50 ms; (4) passos > 10 ms: no máximo 1 por minuto de execução contínua (ou até 1 por minuto acima do controle; não há controle nestas medições); (5) picos não se repetem nos mesmos passos.

| # | (1) hash | (2) média / p99,9 | (3) < 50 ms | (4) taxa > 10 ms | (5) picos | Resultado |
|---|---|---|---|---|---|---|
| 1 | ok | não informado | **falha** (88,2 ms) | **falha** (~13,7/min) | sem lista | **FALHA** |
| 2 | não informado | não informado | **falha** (76,3 ms) | **falha** (~7,4/min) | passa | **FALHA** |
| 3 | não informado | não informado | passa (48,5 ms, 1,5 ms de folga) | **falha** (~5,3/min) | passa | **FALHA** |
| 4 | ok | passa | **falha** (73,4 ms) | **falha** (7,4/min) | passa | **FALHA** |
| A | ok | passa | passa | passa (0/min) | passa | **PASSA** |
| B | ok | passa | passa | **falha por um fio** (1 passo em 56 s = 1,07/min) | passa | **FALHA** (só no item 4) |

**Em palavras simples:** só a execução A passa em tudo. A execução B passa em tudo menos na taxa, e falha por **um único passo lento** numa execução de menos de um minuto. As execuções 1, 2 e 4 quebram o limite duro de 50 ms (de 3 a 5 quadros perdidos) e também a taxa. A execução 3 respeita os 50 ms por pouco, mas falha na taxa. Como são builds de depuração, a régua as trata como informativas: não aprovam nem reprovam.

**Ponto em aberto da régua (a decidir ANTES de medir o release, sem relação com o resultado):** o item 4 diz "no máximo 1 por minuto". Numa execução de ~1 minuto, isso significa que **um único passo lento já reprova** (caso da execução B). Definição (a), literal: por execução. Definição (b): acumulado nas 3 execuções (~3 minutos); com B, seria 1 passo em ~2,8 min, ou 0,36 por minuto. Os limites (1 por minuto, 50 ms etc.) **não mudam** em nenhuma das duas; muda só como se conta. Recomendação minha: (b), porque (a) deixa um único evento decidir o resultado e não distingue uma execução azarada de um problema do código. Fica registrado que, se o release falhar, investiga-se e os números não são ajustados para caber.
