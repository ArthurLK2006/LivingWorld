# Proposta de emenda ao AGENTS.md: mandato de execução

**Status: PROPOSTA, não aplicada.** Arthur autorizou em 14/11/2026 só **preparar** a emenda; o `AGENTS.md` é protegido (12.5) e **não foi alterado**. Ela só vale depois da aprovação escrita dele e de um PR de classe 4 que aplique exatamente este texto. Quer-se: continuar tarefas já aprovadas e liberadas sem nova ordem a cada uma, **sem nunca** dispensar autorização de design, contratos, arquitetura, custos, arquivos protegidos ou portões.

## 1. Trechos atuais (texto exato do `AGENTS.md` em 14/11/2026)
- **0.13 (linha 25):** `13. **NÃO avance para a tarefa seguinte sem aprovação do usuário.** Terminou? Entregue o relatório e **pare**.`
- **Autorização válida (linha 27, primeira frase):** `**Autorização válida** = escrita, **específica** (diz o quê) e **atual** (vale só para a tarefa em curso).`
- **10.3 (linha 256):** `3. **Commit e push são autorizações separadas.** Autorizar commit **não** autoriza push. Cada autorização vale **só para a tarefa atual**.`
- **14, último parágrafo (linha 343):** `**Você NÃO declara a tarefa "concluída".** Declare **"pronta para revisão"**. Quem aprova é Arthur, depois da auditoria. **Só então** a próxima tarefa pode começar, e **somente** quando ele mandar.`
- **15.1, modelo do relatório (linha 377):** `- Próxima tarefa recomendada: <LW-NNN>. Não iniciada.`

## 2. Redação substituta
- **0.13:** `13. **NÃO avance para a tarefa seguinte sem aprovação do usuário**, salvo sob Mandato de Execução vigente (14.1). Terminou? Entregue o relatório e **pare**, a menos que o mandato libere a próxima.`
- **Autorização válida:** `... e **atual** (vale só para a tarefa em curso, ou para as tarefas nomeadas de um Mandato de Execução vigente, 14.1).`
- **10.3:** `... Cada autorização vale **só para a tarefa atual** (ou para as tarefas nomeadas de um Mandato de Execução vigente, 14.1).`
- **14, último parágrafo:** `... Quem aprova é Arthur, depois da auditoria. **Só então** a próxima tarefa pode começar, e **somente** quando ele mandar, ou quando um Mandato de Execução vigente (14.1) a liberar.`
- **15.1:** `- Próxima tarefa: <LW-NNN>. Não iniciada (ou iniciada sob o Mandato <nome>).`
- **Nova seção 14.1** (depois da 14):

> ### 14.1 Mandato de Execução
> Arthur pode conceder, **por escrito**, um **Mandato de Execução**: uma lista nomeada de tarefas já aprovadas (escopo e critério de aceite no roadmap ou em contrato aprovado), com validade. Dentro do mandato vigente, e só para as tarefas dele, o Maestro pode **iniciar a próxima tarefa liberada** quando a anterior estiver "pronta para revisão" ou integrada, sem nova ordem, desde que **todas** estas condições valham:
> 1. a tarefa consta no mandato e está **liberada**: dependências satisfeitas (integradas no `main` com CI verde e as verificações da classe), escopo e contratos **aprovados**, nenhuma decisão PENDENTE de que dependa, nenhum conflito com tarefa ativa (mesmo módulo, contrato ou formato de save) e critério de aceite objetivo. O aceite formal pendente da tarefa anterior não impede a seguinte, **exceto** quando o roadmap o exige (portões REV, VAL e tags);
> 2. a sessão do Maestro está ativa (nada roda em segundo plano depois que ela termina);
> 3. o custo continua zero além da assinatura.
>
> O mandato **nunca dispensa:** (a) a aprovação de Arthur para **design**, contratos novos ou alterados, decisões (`DECISIONS.md`), arquitetura, formato de dados ou de save e eventos catalogados; (b) a autorização para **custos**, ferramentas, dependências, serviços e rede; (c) a autorização para **arquivos protegidos** (12.5) e para este arquivo; (d) os **portões** de fase e o **aceite formal** das tarefas, que são de Arthur; (e) as paradas do 16.2 e a regra dos hashes de referência (DEC-175); (f) a revisão independente e o CI verde que a classe de risco exige; (g) as proibições do 10.6.
>
> Para as tarefas do mandato valem as autorizações de Git do 10.2 e do 10.3: ramo e worktree da tarefa, `add` por caminho, `commit`, `push` do ramo da tarefa e PR. O **merge** no `main` segue a classe de risco: **classe 1** (sem efeito no jogo) e **classe 2** (código dentro de um módulo, coberto por testes, sem mexer em contrato, save, evento, valor [HIP] ou design): o Maestro integra com PR, CI verde na base atualizada e, na classe 2, revisão independente sem achado importante; **classe 3** (contratos, save, eventos, balanceamento, design, vários módulos): só depois do "APROVADO" de Arthur (aceite em lote permitido); **classe 4** (irreversível, custo, dependência, arquivo protegido, tag): só com ordem expressa dele, antes e depois. A classe é do Maestro e, na dúvida, sobe.
>
> Arthur pode **suspender ou revogar** o mandato a qualquer momento por mensagem. Toda tarefa iniciada sob mandato é dita no relatório seguinte.

## 3. Impacto e limites
- **Muda:** só dispensa uma nova ordem a cada tarefa **listada no mandato**. Nenhuma outra regra do `AGENTS.md` muda; as regras 0.1 a 0.12, a seção 10.6 (nunca force-push, `reset --hard`, apagar ramos ou tags etc.), a 12 (protegidos e remoções) e a 16.2 (PARE e pergunte) seguem inteiras.
- **Não muda:** quem aceita (Arthur), os portões, a proteção do `main` (PR e `check_all` obrigatórios, inclui administradores), o custo zero.
- **Mandato 1 proposto, depois da emenda (lista fechada):** (a) arte na direção aprovada: ART-5b e ART-6; (b) LW-107b a 107g, **só depois de ele aprovar o contrato 107a**; (c) LW-098b a 098g, **só depois de ele aprovar o contrato 098a e responder às perguntas de design**. Ficam FORA: a 098h (dados e hash: PARA e pede a aprovação dele), a LW-094, a LW-095 (fim do `IncomeStub`), a LW-100 e a LW-103 (sem contrato aprovado) e qualquer tarefa que mude um hash já aprovado. A aprovação de cada contrato continua sendo dele.
- **Reversão:** um PR de classe 4 restaura os cinco trechos do item 1; ou Arthur revoga o mandato por mensagem.
