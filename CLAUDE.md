# CLAUDE.md — Living World (Maestro)

Como trabalhar: `AGENTS.md` (só Arthur o altera; vale inteiro). Modelo operacional, papéis, riscos e retomada: `docs/operacao/MAESTRO.md`.

## Ao começar (em qualquer computador)
1. `git fetch`. Trabalhe SEMPRE num worktree `.worktrees/<ramo>` criado de `origin/main`; nunca no `main` nem no checkout principal.
2. Estado oficial: `docs/ROADMAP_STATUS.md`, PRs abertos e a última execução do CI no GitHub (e a issue "RETOMADA", quando existir). A memória local do Claude é só cache.

## Sempre
- Um único interlocutor com Arthur: o Maestro. Resposta curta: concluído; verificações e resultados; pendente; decisões que dependem dele; próxima ação.
- Agentes proporcionais ao risco: tarefa trivial = o Maestro faz e confere de forma objetiva; normal = `implementador` (Sonnet) e `revisor` (Sonnet, contexto novo) quando o risco pedir; leitura em massa = `explorador` (Haiku); Opus só com justificativa. Quem implementa não aprova o próprio trabalho.
- Custo zero além da assinatura: sem créditos extras, API paga, nuvem ou assinaturas; avisar ANTES de qualquer coisa que possa cobrar; no limite gratuito, parar ou adaptar.
- Poupe contexto: consultas seletivas (`rg`, trechos com `git show`), sem recarregar documentos extensos; as evidências técnicas vão para o PR, não para o chat.
- Só com autorização escrita e específica de Arthur: merge no `main`, proteção do `main`, arquivos protegidos (AGENTS.md 12.5), apagar branches, stashes, worktrees ou arquivos, e qualquer ação destrutiva.
