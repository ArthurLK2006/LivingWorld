# Operação com o Maestro — Living World

**Status:** configuração mínima aprovada como direção por Arthur em 12/11/2026 (chat); classes de risco e autonomia seguem como proposta. Até ele aprovar a política de autonomia, o `AGENTS.md` vale inteiro; em conflito, vale o `AGENTS.md`. Este documento descreve o fluxo e não o substitui.

## 1. Modelo
Uma única conversa com Arthur: o **Maestro** (Sonnet). Ele aciona agentes internos conforme a complexidade e nunca usa o `main` como área de trabalho.

| Papel | Modelo | Quando | Limites |
|---|---|---|---|
| Maestro | Sonnet | sempre; único interlocutor | decide quantos agentes acionar; faz o Git das tarefas autorizadas |
| Implementador (`.claude/agents/implementador.md`) | Sonnet | tarefa normal ou grande, em worktree próprio | não faz Git que escreva e não decide design |
| Revisor (`revisor.md`) | Sonnet | quando o risco pede (classes 2 a 4) | só leitura; recebe especificação e diff, nunca a conclusão de quem implementou |
| Explorador (`explorador.md`) | Haiku | levantamentos e leitura em massa | só leitura; relatório curto com evidência |
| Opus | sob demanda | análise arquitetural difícil ou revisão de alto risco | o Maestro pede e justifica |

Eficiência: tarefa trivial = o Maestro faz e confere de forma objetiva, sem agentes; documento extenso só é lido por trechos; as evidências técnicas ficam no PR e o chat leva o resumo. Limites iniciais das tarefas delegadas (chamadas, tokens e tamanho do relatório): `CLAUDE.md`.

## 2. Rotina de uma tarefa
1. O Maestro abre a tarefa (escopo, critério de aceite, contratos e DEC lidos, classe de risco) e confere colisão com trabalho em andamento (`git worktree list`, PRs e branches abertos).
2. Worktree `.worktrees/<ramo>` a partir de `origin/main` (ramo `lw-NNN-descricao`).
3. Implementação (o Maestro ou um implementador) e verificação local só com `--headless`: `godot --headless --path . --import` e depois `tools/check_all < /dev/null`.
4. Revisão conforme a classe; achado importante volta ao implementador e gera nova revisão.
5. Push do branch e PR (modelo em `.github/pull_request_template.md`); o CI `check_all` roda no PR.
6. Com CI verde e revisão feita, o Maestro apresenta o resultado a Arthur; o merge só ocorre com a aprovação dele.
7. No fim de cada etapa, todo branch ativo está publicado e o registro de retomada está atualizado.

## 3. Classes de risco (proposta; aguarda a aprovação de Arthur)
| Classe | O que é | Revisão |
|---|---|---|
| 1 | sem efeito no jogo: docs, testes novos, ferramentas, CI | CI e conferência objetiva do Maestro |
| 2 | baixo risco: código dentro de um módulo, coberto por testes, sem mudar contrato, save, evento, valor [HIP] ou design | mais um revisor Sonnet independente |
| 3 | médio ou alto: contratos, save, eventos, balanceamento, design, mais de um módulo | revisor e aprovação de Arthur (Opus só se for análise arquitetural) |
| 4 | irreversível, custo, dependência, `AGENTS.md`, `DECISIONS.md` ou arquivo protegido | aprovação de Arthur antes e depois |

A autonomia do Maestro nas classes 1 e 2 só vale depois da proteção do `main` e das regras aprovadas por Arthur.

## 4. Relatório a Arthur e contexto
Resumo curto: concluído; verificações e resultados; pendente; decisões que dependem dele; próxima ação. O relatório completo (AGENTS.md, seção 15) e as evidências ficam no PR. A conversa do Maestro continua e usa a compactação do Claude Code quando o contexto cresce; o que importa vive no GitHub.

## 5. Custo
Custo zero além da assinatura: GitHub Free com runner padrão (repositório público), sem créditos extras, API paga, nuvem ou assinaturas. Qualquer risco de cobrança é avisado antes, com estimativa. No limite gratuito, parar ou adaptar o fluxo.

## 6. Retomada em outro computador
1. Instalar Git e Homebrew; `brew install ripgrep gh`; Claude Code. `gh auth login` e a identidade do Git ficam na máquina, nunca no repositório.
2. Godot 4.7.2 exato (`4.7.2.stable.official.ed1daf0bf`), em `/Applications/Godot 2.app` ou apontado por `GODOT_BIN`. Zip macOS: `Godot_v4.7.2-stable_macos.universal.zip`, SHA-512 oficial `38aa16e5bba2083941fc5b3e54be0089bd4cc35e32415f5b9fd9a8a6a7b9818255d44532ea8ef94b5aef56c4b407c2d634fa4f657e4ebe681ebbf59b7bac69ca`.
3. `git clone`, `godot --headless --path . --import` e `tools/check_all < /dev/null`: deve dar VERDE (184 scripts e 1.553 testes em 12/11/2026).
4. Abrir o Claude Code no repositório (o `CLAUDE.md` e os agentes vêm junto) e ler `docs/ROADMAP_STATUS.md`, os PRs abertos, a última execução do CI e a issue "RETOMADA", quando existir.

Não vão ao Git, por desenho: `.godot/`, `export_presets.cfg`, `addons/terrain_3d/`, `user://`, capturas, credenciais e a memória local do Claude.

## 7. Propostas ainda não aplicadas (cada uma pede autorização de Arthur)
- **Acompanhamento por GitHub Issues:** uma issue fixa "RETOMADA" (tarefas ativas, branches e PRs, decisões pendentes de Arthur, próximo passo, data) e uma issue por tarefa **ativa** (critérios, dependências, branch/PR e evidência do CI), fechada ao integrar. Nenhuma issue para o roadmap futuro, que continua em `docs/`. Rótulos mínimos: `ativa`, `aguarda-arthur`, `bloqueada`, `classe-1` a `classe-4`. O repositório é público: tudo fica visível.
- **`.worktrees/` fora do Git:** (a) já vale: adicionar sempre por caminho (AGENTS.md 10.4), nunca `git add -A`, `git add .` nem `commit -a` no checkout principal, e trabalhar só em worktrees; (b) definitiva: a linha `.worktrees/` no `.gitignore` (arquivo protegido, precisa de autorização); (c) rede de segurança: passo no CI que falha se `.worktrees/` ou entradas de submódulo (modo 160000) entrarem no Git.
- **Proteção do `main`:** só depois de coordenar a transição dos pushes diretos das sessões A, B e C: PR obrigatório, `check_all` obrigatório, sem force-push nem exclusão do `main`.
- **Substituir as sessões A, B e C** (não encerrar antes): uma tarefa real feita de ponta a ponta pelo fluxo (PR, CI, revisão, aprovação) sem regressão; o trabalho em andamento delas integrado, estacionado com registro ou classificado; registro de retomada testado (uma sessão nova reproduz o estado só pelo GitHub); proteção do `main` acordada; cota dentro do limite; aprovação de Arthur.

## 8. Limitações conhecidas (12/11/2026)
- **As permissões de `.claude/settings.json` NÃO estão comprovadas.** O teste dinâmico não foi executado: o Claude Code aninhado não herda o login do app (sessão expirada, não contornada) e a conversa do Maestro abriu no checkout principal, onde estas regras não carregam. Houve só validação estática: JSON válido, apenas `allow`, `ask` e `deny`, sem `defaultMode`, sem regra ampla no `allow`, e as formas `Bash(prefixo *)`, `Edit(caminho)` e `Read(caminho)` conferidas com a referência de configuração do próprio Claude Code. A precedência entre `deny`, `ask` e `allow` e o efeito do sufixo antigo `:*` não foram confirmados por essa referência.
- **A proteção efetiva continua sendo** as regras de autorização do `AGENTS.md` (seções 0, 10 e 12) e o ritual de PR com CI. Regras por prefixo não cobrem todas as variantes (por exemplo `rm -fr`, `git push --force-with-lease`, `git diff --output=arquivo`), e não foi verificado se as regras de `Edit` valem para comandos de shell (`sed -i`, redirecionamentos).
- **Teste manual de 1 minuto**, numa sessão aberta num worktree deste repositório: pedir a edição de `AGENTS.md` (deve pedir confirmação; negue); rodar `git push --force --dry-run origin <ramo>` (deve ser negado); rodar `git status` (deve rodar sem pedir). Anote aqui o resultado quando fizer.
