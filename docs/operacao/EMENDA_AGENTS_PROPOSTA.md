# Emenda ao AGENTS.md: mandato de execução (APROVADA)

**Status: APROVADA por Arthur em 14/11/2026, com três ajustes, e aplicada pelo PR que traz este arquivo** (a alteração específica do `AGENTS.md`, protegido pela seção 12.5, foi autorizada por ele por PR, com revisão e CI). O texto aplicado está no próprio `AGENTS.md` (0.13, "Autorização válida", 10.3, 14, a nova 14.1 e 15.1); aqui fica só o registro do que mudou, sem repetir a redação.

## Trechos que mudaram (texto anterior, exato)
- **0.13:** `13. **NÃO avance para a tarefa seguinte sem aprovação do usuário.** Terminou? Entregue o relatório e **pare**.`
- **Autorização válida (primeira frase):** `**Autorização válida** = escrita, **específica** (diz o quê) e **atual** (vale só para a tarefa em curso).`
- **10.3:** `3. **Commit e push são autorizações separadas.** Autorizar commit **não** autoriza push. Cada autorização vale **só para a tarefa atual**.`
- **14, último parágrafo:** `**Você NÃO declara a tarefa "concluída".** Declare **"pronta para revisão"**. Quem aprova é Arthur, depois da auditoria. **Só então** a próxima tarefa pode começar, e **somente** quando ele mandar.`
- **15.1:** `- Próxima tarefa recomendada: <LW-NNN>. Não iniciada.`
- **Nova seção 14.1, Mandato de Execução.**

## Os três ajustes de Arthur e onde entraram na 14.1
1. **Só as tarefas expressamente nomeadas**, com escopo e contratos aprovados e dependências satisfeitas; o mandato não dispensa autorização obrigatória nem aprova antecipadamente a integração de tarefas de classe 3 e 4 (parágrafos 1 e 2 e "Git e integração").
2. **A verificação cobre a combinação efetiva com o `main` mais recente:** CI verde sobre base antiga não basta quando o `main` mudou em dependências ou arquivos que a tarefa também toca; sem relação, o CI existente vale e não se repete verificação sem ganho (parágrafo "Verificação antes de integrar").
3. **Validade:** termina quando as tarefas nomeadas forem concluídas, quando Arthur revogar ou quando uma mudança relevante invalidar as premissas; tarefas novas só por novo mandato ou aditivo escrito (parágrafo "Validade").

## Limites e reversão
Só dispensa a nova ordem a cada tarefa **listada em um mandato escrito** (o primeiro: [MANDATO_1.md](MANDATO_1.md)); o resto do `AGENTS.md` segue inteiro, a proteção do `main` e o custo zero também. Reversão: um PR de classe 4 restaura os cinco trechos acima e remove a 14.1, ou Arthur revoga o mandato por mensagem.
