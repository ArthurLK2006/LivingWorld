# LW-030 — O que você vai fazer (validação da Fase 0)

**RASCUNHO atualizado em 02/11/2026.** A LW-030 só começa depois da LW-029 aprovada e dos achados críticos corrigidos.

**Ideia:** você usa o projeto como alguém que o recebe pela primeira vez, numa pasta nova, e confere se tudo funciona do jeito que os documentos dizem. Se algo falhar, não é culpa sua: vira uma tarefa de correção.

## O que você já fez (não precisa repetir)
- **F5 da cena inicial, no seu Mac:** a janela abriu com piso, cubo, céu e sol; a data simulada avança; o Espaço pausa e, de novo, continua; a aba **Erros** do editor ficou vazia. (Isso fechou a LW-006 e a parte visual da LW-021.)
- **`tools/check_all` no seu Mac:** VERDE, 145 testes (commit `0eb1bdf`).
- **Pico de 10 ms (SP1), em release no seu Mac:** 3 execuções, nenhum passo acima de 10 ms, régua da DEC-113 aprovada antes de medir. O que sobra é só **ler** o relatório (passo 5 abaixo).

## O que falta, em ordem (cerca de 20 a 30 minutos)
1. **Pasta nova e só o README.** Baixe o repositório numa pasta que nunca foi usada e siga **apenas** o `README.md` (seções 8 a 10), sem ajuda minha; se faltar um passo, anote qual.
   ```bash
   git clone --branch claude/living-world-coordination-umft1k https://github.com/ArthurLK2006/LivingWorld.git lw-validacao
   ```
   (Se até lá o ramo `main` já tiver recebido este trabalho, eu aviso e o `--branch` deixa de ser necessário.)
   Pré-requisitos da seção 8: o Godot 4.7.2 e o **ripgrep** (`brew install ripgrep`). Sem o ripgrep o `check_all` não roda; ele avisa isso logo no início, numa mensagem só.
2. **Preparar e rodar tudo na pasta nova**, com o caminho do seu Godot em `GODOT_BIN`:
   ```bash
   "$GODOT_BIN" --headless --path . --import
   ```
   ```bash
   tools/check_all
   ```
   Deve terminar em **VERDE**, com 145 testes. É a única coisa que você repete: o objetivo aqui não é testar o código de novo (isso você já fez), e sim provar que **a pasta nova + o README bastam**.
3. **Quebrar de propósito.** Troque o `4` por `5` em `tests/unit/test_lw010_pass.gd`, rode `tools/check_all` e veja **VERMELHO** com uma mensagem que você entenda. Desfaça a troca.
4. **Repetibilidade.** Rode duas vezes `tools/run_sim --days 30 --seed 1`. A linha "Hash do estado" tem de ser **igual** nas duas vezes. (Na minha máquina de nuvem deu `732907967efdba5f718687a0bbafbfe102ac51cabc9d15a7f0119a9e64ebc4d7`; no seu Mac pode ser outro, o que importa é ser igual entre as duas rodadas.)
5. **Ler os relatórios dos spikes:** `docs/decisions/0003` (dados), `0004` (núcleo, SP1; a conclusão está no topo e na última seção) e `0005` (salvamento, SP5). Diga se concorda com as decisões.
6. **Conferir o `docs/ROADMAP_STATUS.md`:** o que está escrito bate com o que existe?
7. **Explicar com suas palavras o ciclo de uma tarefa:** você escolhe a tarefa → o Codex implementa e testa e entrega relatório → o auditor confere → você aprova e manda registrar. (Está no roadmap, item 0.6.)

## Como terminar
- Tudo certo: responda **"LW-030 assinada"** (os 7 itens acima, marcados).
- Algo falhou: me mande **a lista do que falhou** (o item, o que você viu, a mensagem). Cada item vira uma tarefa de correção.
- Depois disso quem fecha a fase é você, na LW-031 (eu só deixo o rascunho pronto). A tag `fase-0-concluida` só é criada com a sua autorização.

## Observação importante
O `README.md` precisa estar fiel ao projeto para o passo 1 funcionar. Eu o atualizei em 02/11/2026 e revisei de novo antes da revisão externa. A LW-031 ainda fará o ajuste final da seção "Estado atual".
