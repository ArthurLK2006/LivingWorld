#!/bin/sh
# LW-050: o tools/check_literal_text reprova texto de interface escrito direto no código (e aponta arquivo e linha) e aprova o que não é
# texto de tela (chave de texto, log, comentário, nome de nó, string vazia, só formato). Cada caso que PASSA tem o seu par que FALHA, e o
# código real do projeto tem de passar (controle positivo: o mesmo script reprova o literal de teste logo antes).
set -eu
project_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
fixture=$(mktemp -d "${TMPDIR:-/tmp}/lw050.XXXXXX")
trap 'rm -r "$fixture"' EXIT HUP INT TERM
mkdir -p "$fixture/src/presentation" "$fixture/src/app"
checker="$project_dir/tools/check_literal_text"
violations=0
passes=0
# expect_violation <rótulo> <pasta dentro de src> <conteúdo com \n> [linha esperada]
expect_violation() {
    label=$1
    folder=$2
    content=$3
    line=${4:-1}
    printf "$content\n" > "$fixture/src/$folder/violation.gd"
    if "$checker" "$fixture" > "$fixture/output" 2>&1; then
        echo "FALHA: $label não foi detectado"; cat "$fixture/output"; exit 1
    fi
    if ! grep -F "violation.gd:$line:" "$fixture/output" >/dev/null; then
        echo "FALHA: $label sem arquivo e linha $line"; cat "$fixture/output"; exit 1
    fi
    rm -f "$fixture/src/$folder/violation.gd"
    violations=$((violations + 1))
}
expect_pass() {
    label=$1
    content=$2
    printf "$content\n" > "$fixture/src/presentation/clean.gd"
    if ! "$checker" "$fixture" > "$fixture/output" 2>&1; then
        echo "FALHA: $label deveria passar"; cat "$fixture/output"; exit 1
    fi
    rm -f "$fixture/src/presentation/clean.gd"
    passes=$((passes + 1))
}
expect_violation 'Label.text com literal' presentation 'func f(label: Label) -> void:\n\tlabel.text = "Olá"' 2
expect_violation 'texto com acento' presentation 'func f(label: Label) -> void:\n\tlabel.text = "Ação"' 2
expect_violation 'literal com formato' presentation 'func f(label: Label, total: int) -> void:\n\tlabel.text = "Valor: %d" % total' 2
expect_violation 'text +=' presentation 'func f(label: Label) -> void:\n\tlabel.text += "mais"' 2
expect_violation 'Button.text' presentation 'func f(button: Button) -> void:\n\tbutton.text = "OK"' 2
expect_violation 'RichTextLabel.text' presentation 'func f(rich: RichTextLabel) -> void:\n\trich.text = "[b]Negrito[/b]"' 2
expect_violation 'tooltip_text' presentation 'func f(label: Label) -> void:\n\tlabel.tooltip_text = "Dica"' 2
expect_violation 'set_text com literal' presentation 'func f(label: Label) -> void:\n\tlabel.set_text("Oi")' 2
expect_violation 'add_item com literal' presentation 'func f(list: ItemList) -> void:\n\tlist.add_item("Opção")' 2
expect_violation 'literal em src/app' app 'func f(label: Label) -> void:\n\tlabel.text = "Texto no app"' 2
expect_violation 'função de status devolve frase' app 'func status_text() -> String:\n\treturn "Data simulada: %%s" %% x' 2
expect_violation 'função devolve palavra em maiúsculas' app 'func pace_label() -> String:\n\treturn "PAUSADO"' 2
expect_violation 'frase misturada com chave' presentation 'func prompt_text() -> String:\n\treturn _texts.get_text("ui.key") + " Interagir agora"' 2
expect_pass 'string vazia' 'func f(label: Label) -> void:\n\tlabel.text = ""'
expect_pass 'chave de texto' 'func f(label: Label) -> void:\n\tlabel.text = _texts.get_text("ui.interact_prompt")'
expect_pass 'valor convertido' 'func f(label: Label, count: int) -> void:\n\tlabel.text = str(count)'
expect_pass 'só formato, sem letra' 'func f(label: Label, count: int) -> void:\n\tlabel.text = "%%d" %% count'
expect_pass 'log dentro de função de texto' 'func debug_text() -> void:\n\tpush_warning("duas palavras aqui")\n\tprint("outras palavras aqui")'
expect_pass 'comentário com atribuição' '# label.text = "Olá"'
expect_pass 'nome de nó' 'func f(node: Node) -> void:\n\tnode.name = "Aviso"\n\tvar hud: Node = get_node("HUD/Label")'
expect_pass 'chave de dicionário em função de texto' 'func status_text() -> String:\n\treturn str({"year": 1}["year"])'
expect_pass 'tecla de uma letra' 'func key_label() -> String:\n\treturn "?"'
# O mesmo script que reprovou os literais acima aprova o código real: controle positivo e prova de que o código atual está limpo.
printf 'func f(label: Label) -> void:\n\tlabel.text = "Olá"\n' > "$fixture/src/presentation/violation.gd"
if "$checker" "$fixture" > "$fixture/output" 2>&1; then echo 'FALHA: controle positivo (o literal de teste deveria reprovar)'; exit 1; fi
rm -f "$fixture/src/presentation/violation.gd"
"$checker" "$project_dir" > "$fixture/output" 2>&1 || { echo 'FALHA: o código real tem texto de interface escrito direto'; cat "$fixture/output"; exit 1; }
# Pasta ausente: erro claro, código diferente de zero.
if "$checker" "$fixture/nao_existe" > "$fixture/output" 2>&1; then echo 'FALHA: raiz sem src deveria falhar'; exit 1; fi
grep -F 'AUSENTE' "$fixture/output" >/dev/null || { echo 'FALHA: mensagem de pasta ausente'; cat "$fixture/output"; exit 1; }
echo "LW-050: check_literal_text: $violations violações detectadas, $passes casos aceitos e o código real sem texto de interface literal."
