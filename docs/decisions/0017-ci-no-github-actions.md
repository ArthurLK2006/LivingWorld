# Registro técnico — Verificação automática (`check_all`) no GitHub Actions

- **Status:** proposta. Aguarda a aprovação de Arthur na integração do PR; este registro não aprova nem altera o status de nenhuma DEC-NNN.
- **Data e tarefa:** 12/11/2026; piloto de CI da migração para o fluxo com o Maestro (sem número LW).
- **Contexto e problema:** o `tools/check_all` só rodava no Mac de Arthur, e cada sessão "aprovava" o próprio resultado por relato. Para integrar com segurança e continuar o trabalho em outro computador, o resultado precisa vir de um ambiente limpo, que qualquer pessoa possa conferir. Regra financeira de Arthur (12/11/2026): nenhum custo além da assinatura de IA; GitHub Free e runners padrão gratuitos enquanto o repositório for público (DEC-114).
- **Opções consideradas:**
  1. Só rodar no Mac (situação anterior): sem prova independente e sem como retomar em outro computador.
  2. Runner `ubuntu-24.04` padrão, checkout com `git` puro e Godot por soma fixa (escolhida).
  3. Ações de terceiros (por exemplo, instaladores de Godot): menos linhas, mas código externo executando no CI; recusada.
  4. Runner macOS: é o sistema-alvo (DEC-015) e também é gratuito em repositório público, mas é mais lento e custaria 10 vezes mais se o repositório voltasse a ser privado; fica como complemento a avaliar.
- **Escolha ou recomendação:** `.github/workflows/check_all.yml` com runner `ubuntu-24.04`; permissão `contents: read` e nenhum segredo; nenhuma ação de terceiros (nem a `actions/checkout`); Godot 4.7.2 (`4.7.2.stable.official.ed1daf0bf`, o do ambiente de referência) baixado do release oficial e conferido por SHA-512 (arquivo oficial de somas) e SHA-256 (digest informado pelo GitHub) antes de executar qualquer coisa; ripgrep por `apt`; `godot --headless --path . --import` e `tools/check_all < /dev/null`. Gatilhos: `pull_request` e `push` no `main`. Enquanto o `main` não tiver proteção, o resultado é um aviso e não um bloqueio.
- **Consequências e riscos:**
  - Custo zero enquanto o repositório for público. Se voltar a ser privado (DEC-114 é reversível), o plano Free limita os minutos (2.000 por mês no Linux, cerca de 9 min por execução) e o macOS custaria 10 vezes mais: nesse caso, interromper ou adaptar, sem gerar despesa.
  - O CI é Linux; o alvo aprovado é macOS (DEC-015). Ele prova a lógica e a portabilidade dos scripts, não o macOS.
  - Portabilidade: todos os scripts são `#!/bin/sh`, que no macOS é bash e no Ubuntu é dash. O CI achou um `printf` com `%` solto em `tests/test_check_literal_text.sh` (linha 41) que o bash aceitava gerando outro arquivo; corrigido neste PR. Fragilidade parecida resta nas linhas 19 e 32 (conteúdo usado como formato): vai para o backlog.
  - Cada execução leva de 5,7 a 8,9 min (o GUT, de 247 a 414 s); o runner varia.
  - O GitHub avisa por e-mail quem fez o push quando o CI do `main` falha (notificação padrão).
  - PRs vindos de forks rodam sem segredos e com token somente de leitura (comportamento padrão do GitHub); a política de aprovação para colaboradores novos não foi alterada.
  - Reversão: remover o arquivo do workflow (nada mais depende dele); a correção do teste é independente.
- **Validação e referências:** execuções no branch `piloto-ci` (não integrado): 43293565425 (vermelha: defeito do teste), 43295257076 (diagnóstico: com `/bin/sh` = bash, VERDE) e 43303246520 (final, VERDE: 184 scripts, 1.553 testes e 299.224 asserts, os mesmos registrados no Mac para a LW-108). A correção do teste teve revisão independente sem achados bloqueantes. O CI deste PR repete a verificação com os gatilhos de produção.
- **Relação com DEC-NNN:** DEC-012 (versão do Godot), DEC-015 (alvo macOS), DEC-086 (GUT), DEC-087 (verificação única, proposta), DEC-089 e DEC-114 (GitHub e repositório público). Não aprova nem altera nenhuma delas.
