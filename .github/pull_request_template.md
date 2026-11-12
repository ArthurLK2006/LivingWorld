## Resumo
<!-- 1 a 3 linhas: o que muda e por quê -->

## Escopo
- Tarefa e classe de risco (1 a 4):
- Arquivos (só os autorizados; `git diff --stat`):

## Evidências (ficam aqui, não no chat)
- CI (execução e resultado):
- Verificações locais (comando e resultado real):
- Revisão independente, quando o risco pedir (achados e como foram tratados):

## Custo, riscos e reversão
- Custo adicional: nenhum / <descreva e peça aprovação antes>
- Riscos e o que NÃO foi verificado:
- Como reverter:

## Autorrevisão (AGENTS.md, seção 11)
- [ ] Só os arquivos do escopo; nenhum arquivo protegido tocado sem autorização
- [ ] Nenhum teste removido, desativado ou enfraquecido
- [ ] `check_all` executado de verdade (no CI e/ou local)
- [ ] Sem dependência, serviço, segredo ou ação de terceiros novos
- [ ] Documentação e contratos atualizados, se afetados
- [ ] Aprovação de Arthur para integrar (merge)
