# LW-030 — O que você vai fazer (validação da Fase 0)

**RASCUNHO preparado em 02/11/2026.** A LW-030 só começa depois da LW-029 aprovada e dos achados críticos corrigidos.

**Ideia:** você usa o projeto como alguém que o recebe pela primeira vez, numa pasta nova, e confere se tudo funciona do jeito que os documentos dizem. Se algo falhar, não é culpa sua: vira uma tarefa de correção.

## Passos (cerca de 20 a 40 minutos, conforme a velocidade do download)
1. **Pasta nova.** Baixe o repositório numa pasta que nunca foi usada e entre no ramo que eu indicar no dia:
   ```bash
   git clone https://github.com/ArthurLK2006/LivingWorld.git lw-validacao
   ```
2. **Só o README.** Siga apenas o `README.md` (seções 8 a 10), sem ajuda minha. Se faltar um passo, anote qual.
3. **Preparar o projeto** (uma vez, em pasta nova):
   ```bash
   godot --headless --path . --import
   ```
4. **Abrir no Godot 4.7.2** (a versão exata). O painel "Saída" não deve mostrar mensagens vermelhas.
5. **Rodar tudo:** `tools/check_all`. Deve terminar em **VERDE**.
6. **Quebrar de propósito:** troque o `4` por `5` em `tests/unit/test_lw010_pass.gd`, rode `tools/check_all` e veja **VERMELHO** com uma mensagem que você entenda. Desfaça a troca.
7. **Cena inicial (F5):** deve aparecer, no canto superior esquerdo, título, versão e data simulada **avançando**; **Espaço** pausa e continua.
8. **Repetibilidade:** rode duas vezes `tools/run_sim --days 30 --seed 1`. A linha "Hash do estado" tem de ser **igual** nas duas vezes. (Na minha máquina de nuvem deu `732907967efdba5f718687a0bbafbfe102ac51cabc9d15a7f0119a9e64ebc4d7`; no seu Mac pode ser outro, o que importa é ser igual entre as duas rodadas.)
9. **Ler os relatórios dos spikes:** `docs/decisions/0003` (dados), `0004` (núcleo, SP1) e `0005` (salvamento, SP5). Diga se concorda com as decisões.
10. **Conferir o `docs/ROADMAP_STATUS.md`:** o que está escrito bate com o que existe?
11. **Explicar com suas palavras o ciclo de uma tarefa:** você escolhe a tarefa → o Codex implementa e testa e entrega relatório → o auditor confere → você aprova e manda registrar. (Está no roadmap, item 0.6.)

## Pendências que entram na validação
- **Pico de 10 ms (SP1), no Mac:** `tests/soak/run_sp1` (com `GODOT_BIN` apontando para o Godot). Veja a linha "Passos acima de 10000 us": o ideal é **0**. Me passe a linha inteira.

## Como terminar
- Tudo certo: responda **"LW-030 assinada"** (a checklist de 11 itens acima, marcados).
- Algo falhou: me mande **a lista do que falhou** (o item, o que você viu, a mensagem). Cada item vira uma tarefa de correção.

## Observação importante
O `README.md` precisa estar fiel ao projeto para o passo 2 funcionar. Eu o atualizei em 02/11/2026 (seções 5, 6, 8, 9 e 10, que ainda diziam que não existia código). A LW-031 ainda fará o ajuste final da seção "Estado atual".
