#!/bin/sh
# ART-12, 7c-1c: a COMPARAÇÃO com e sem a figura (tests/soak/compare_game_release), SEM janela, SEM Godot e SEM tocar na energia do Mac: arquivos de execução FALSOS, escritos à mão no formato do medidor
# (tests/soak/run_game_release), numa pasta temporária. Confere o agrupamento POR PERFIL (um perfil nunca soma com outro), o descarte e a listagem das inconclusivas, as estatísticas de um grupo à mão, o delta com a
# dispersão ("abaixo do ruído" dentro dela, não fora), a linha em destaque no começo e no fim e os códigos de saída (0, 1 e 2).
set -eu
project_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
work=$(mktemp -d "${TMPDIR:-/tmp}/lw_compare_test.XXXXXX")
trap 'rm -rf "$work"' EXIT HUP INT TERM
compare="$project_dir/tests/soak/compare_game_release"
expect() { [ "$2" = "$3" ] || { echo "FALHA: $1: esperado '$3', veio '$2'"; exit 1; }; echo "OK: $1"; }
expect_has() { case "$2" in *"$3"*) echo "OK: $1";; *) echo "FALHA: $1: sem '$3' em '$2'"; exit 1;; esac; }
expect_lacks() { case "$2" in *"$3"*) echo "FALHA: $1: não devia ter '$3'"; exit 1;; *) echo "OK: $1";; esac; }

# Um arquivo de execução no formato real. $1 arquivo, $2 PERFIL, $3 FIGURA, $4 CLASSIFICAÇÃO, $5 média, $6 mediana, $7 p99, $8 pior (ms); opcionais: $9 figuras ativas (vazio = sem a linha), $10 "instanciar e adicionar" (ms),
# $11 média do "resto do quadro", $12 DURAÇÃO, $13 linha EXTRA depois do veredito. O VEREDITO DEC-119 é escrito como o medidor o escreveria (60 fps ou mais e 0 quadros acima de 33 ms).
mkrun() {
    mkdir -p "$(dirname "$1")"
    verdict=$(awk -v m="$5" 'BEGIN { printf "%s (média %.1f fps, 0 quadros acima de 33 ms; a DEC-119 exige média de 60 fps ou mais e nenhum quadro acima de 33 ms)", (1000 / m >= 60) ? "PASSA" : "FALHA", 1000 / m }')
    {
        printf 'PERFIL: %s\nFIGURA: %s\nDURAÇÃO: %s\nDATA: 2026-11-17 10:00:00 -0300\n' "$2" "$3" "${12:-completa}"
        printf 'MÁQUINA: Mac14,2, Apple M2, macOS 26.1; binário x\nenergia (antes): fonte bateria, bateria 80%% (discharging), baixo consumo (lowpowermode) 0\n'
        printf 'LW-053A: medição de quadros do jogo (cena principal, com janela)\n'
        printf 'carga da cena principal (fora das seções do quadro; o preparo da figura acontece aqui): ler o arquivo 1.0 ms, instanciar e adicionar %s ms\n' "${10:-100.0}"
        printf 'ENSAIO POVOADO 30 s com o jogador no centro de A, NPCs saindo de casa\n'
        printf '  quadros 1800, média %s ms, mediana %s ms, percentil 99 %s ms, pior (sem os 3 primeiros) %s ms\n' "$5" "$6" "$7" "$8"
        printf '  acima de 16,7 ms: 100 · acima de 33 ms: 0\n'
        printf '  custo por seção, em ms por quadro (média / pior): NpcBodiesView 0.10 / 1.20 | NpcBodyDriver 0.20 / 2.30 | resto do quadro %s / 28.00\n' "${11:-16.00}"
        printf '  começo: 100 nós, 12 chunks, 0 corpos | meio: 120 nós | fim: 130 nós | máximo de corpos 50 | posição final x=320.0 m\n  VEREDITO DEC-119: %s\n' "$verdict"
        [ -z "${9:-}" ] || printf '  figuras ativas: máximo %s, no fim %s, de no máximo 50 corpos; NPC da figura: 33\n' "$9" "$9"
        [ -z "${13:-}" ] || printf '%s\n' "${13}"
        printf 'energia (depois): fonte bateria, bateria 79%% (discharging), baixo consumo (lowpowermode) 0\nCLASSIFICAÇÃO: %s\n' "$4"
    } > "$1"
}
section() { printf '%s\n' "$out" | awk -v h="######## PERFIL: $1 ########" '$0 == h { on = 1; next } /^######## PERFIL: / || /^\*\*\*\*/ { on = 0 } on'; }
run_compare() { rc=0; out=$("$compare" "$@" 2>&1) || rc=$?; }
ZERO='  ATENÇÃO: a área local tem figura, mas há 0 figuras ativas neste ensaio (o NPC dela não teve corpo em S0): estes números NÃO medem a figura.'

# O conjunto principal: duas pastas (sem/ e com/) com TODOS os casos, como as de uma rodada do medidor.
r=$work/r1
mkrun "$r/sem/game_release_run_1.txt" bateria sem válida 10.0 10.0 12.0 15.0 '' 100.0 9.70
mkrun "$r/sem/game_release_run_2.txt" bateria sem válida 12.5 12.0 14.0 18.0 '' 100.0 12.20
mkrun "$r/sem/game_release_run_3.txt" bateria sem válida 12.5 12.0 14.0 18.0 '' 100.0 12.20
mkrun "$r/sem/game_release_run_4.txt" bateria sem 'inconclusiva (a bateria caiu 6 pontos (máximo 5))' 100.0 100.0 120.0 150.0 '' 100.0 90.0
mkrun "$r/com/game_release_run_1.txt" bateria com válida 20.0 20.0 24.0 30.0 1 140.0 19.70
mkrun "$r/com/game_release_run_2.txt" bateria com válida 20.0 20.0 24.0 30.0 1 140.0 19.70
mkrun "$r/com/game_release_run_3.txt" bateria com válida 8.0 8.0 9.0 10.0 0 140.0 7.70 completa "$ZERO"
mkrun "$r/sem/game_release_run_5.txt" tomada sem válida 10.0 10.0 12.0 15.0 '' 100.0 9.70
mkrun "$r/sem/game_release_run_6.txt" tomada sem válida 12.5 12.5 15.0 20.0 '' 105.0 12.20
mkrun "$r/com/game_release_run_4.txt" tomada com válida 12.5 12.0 14.0 20.0 1 100.0 12.20
mkrun "$r/com/game_release_run_5.txt" tomada com válida 12.5 12.0 14.0 20.0 1 100.0 12.20
mkrun "$r/sem/game_release_run_7.txt" 'bateria (baixo consumo LIGADO)' sem válida 8.0 8.0 9.0 10.0 '' 100.0 7.70
mkrun "$r/com/game_release_run_6.txt" 'bateria (baixo consumo LIGADO)' com válida 9.0 9.0 10.0 11.0 1 120.0 8.70
mkrun "$r/sem/game_release_run_8.txt" 'bateria (baixo consumo DESCONHECIDO)' sem válida 11.0 11.0 13.0 16.0 '' 100.0 10.70
mkrun "$r/com/game_release_run_7.txt" bateria com válida 5.0 5.0 6.0 7.0 1 140.0 4.70 'CURTA de 10 s (VALIDAÇÃO DO INSTRUMENTO: sem veredito DEC-119)'
run_compare "$r/sem" "$r/com"
expect 'conjunto principal: código 0' "$rc" 0
first_line=$(printf '%s\n' "$out" | head -1); last_line=$(printf '%s\n' "$out" | tail -1)
case "$first_line$last_line" in '*'*'*') echo 'OK: a linha em DESTAQUE abre e fecha a saída';; *) echo 'FALHA: a saída devia abrir e fechar com a linha de destaque'; exit 1;; esac
sentence='NÃO compare os perfis bateria e tomada como equivalentes: cada perfil tem a sua tabela.'
expect 'o aviso dos perfis aparece 2 vezes (começo e fim)' "$(printf '%s\n' "$out" | grep -cF "$sentence")" 2
expect_has 'ressalva: vale para ESTE Mac' "$out" 'este resultado vale para ESTE Mac, estas condições e estas execuções; não representa outros Macs nem plataformas'
expect_has 'a CURTA é ignorada (e dita)' "$out" 'CURTA(s) (validação do instrumento, sem veredito DEC-119) IGNORADA(s): 1'

# O agrupamento POR PERFIL: cada rótulo é um grupo PRÓPRIO e nenhum soma com outro.
for label in bateria tomada 'bateria (baixo consumo LIGADO)' 'bateria (baixo consumo DESCONHECIDO)'; do expect_has "grupo PRÓPRIO: $label" "$out" "######## PERFIL: $label ########"; done
expect 'quatro perfis, quatro grupos' "$(printf '%s\n' "$out" | grep -c '^######## PERFIL: ')" 4
bat=$(section bateria); tom=$(section tomada); lig=$(section 'bateria (baixo consumo LIGADO)'); des=$(section 'bateria (baixo consumo DESCONHECIDO)')
expect_has 'bateria sem: 4 execuções, 3 válidas e 1 inconclusiva (as do tomada NÃO entram)' "$bat" 'FIGURA sem: 4 execução(ões): 3 válida(s) e 1 inconclusiva(s)'
expect_has 'bateria com: 3 execuções (a CURTA não conta), 2 válidas, 1 inconclusiva' "$bat" 'FIGURA com: 3 execução(ões): 2 válida(s) e 1 inconclusiva(s)'
expect_has 'tomada sem: 2 válidas' "$tom" 'FIGURA sem: 2 execução(ões): 2 válida(s) e 0 inconclusiva(s)'
expect_has 'baixo consumo LIGADO: 1 e 1' "$lig" 'FIGURA sem: 1 execução(ões): 1 válida(s)'
expect_lacks 'o LIGADO (125 fps) NÃO somou na bateria' "$bat" '125.0'
expect_has 'o LIGADO tem o próprio FPS' "$lig" 'FPS médio (1000 / média do quadro): 125.0 (125.0 a 125.0)'
expect_has 'DESCONHECIDO sem execução COM: sem delta, sem erro' "$des" 'FIGURA com: nenhuma execução neste perfil (sem delta)'

# As inconclusivas: DESCARTADAS das estatísticas e LISTADAS com o motivo.
expect_has 'inconclusiva listada com o motivo da classificação' "$bat" 'descartada: sem/game_release_run_4.txt: inconclusiva: a bateria caiu 6 pontos (máximo 5)'
expect_has 'COM a figura sem figura ativa: listada com o motivo' "$bat" 'descartada: com/game_release_run_3.txt: COM a figura, mas 0 figuras ativas no ensaio povoado'
expect_has 'FPS médio, mínimo e máximo do bateria sem (só as 3 válidas: 100, 80 e 80), à mão' "$bat" 'FPS médio (1000 / média do quadro): 86.7 (80.0 a 100.0)'
expect_has 'tempos de quadro do bateria sem à mão (média, mediana, p99, pior)' "$bat" 'média 11.67 (10.00 a 12.50) | mediana 11.33 (10.00 a 12.00) | percentil 99 13.33 (12.00 a 14.00) | pior 17.0 (15.0 a 18.0)'
expect_has 'FPS do bateria com: a execução COM 0 figuras (125 fps) NÃO entrou' "$bat" 'FPS médio (1000 / média do quadro): 50.0 (50.0 a 50.0)'
expect_has 'o VEREDITO DEC-119 de cada execução é o que o medidor imprimiu' "$bat" 'VEREDITO DEC-119 (o do medidor): PASSA (média 100.0 fps, 0 quadros acima de 33 ms)'
expect_has 'o resumo do veredito: PASSA em 3 de 3 no sem, 0 de 2 no com' "$bat" 'PASSA em 3 de 3 execução(ões)'
expect_has 'o resumo do veredito do com: FALHA conta como não passou' "$bat" 'PASSA em 0 de 2 execução(ões)'
expect_has 'o custo por seção de cada execução' "$bat" 'seções, em ms por quadro (média / pior): NpcBodiesView 0.10 / 1.20 | NpcBodyDriver 0.20 / 2.30 | resto do quadro 12.20 / 28.00'
expect_has 'quadros acima de 16,7 ms e de 33 ms' "$bat" 'quadros por execução acima de 16,7 ms: 100.0 (100.0 a 100.0) | acima de 33 ms: 0.0 (0.0 a 0.0)'

# O DELTA (com menos sem) com a dispersão: FORA dela no bateria (50 fps contra 86,7) e DENTRO dela no tomada.
expect_has 'delta FORA da dispersão (bateria): ACIMA da dispersão, sem a frase do ruído' "$bat" 'FPS médio: -36.67 fps (sem 86.67, com 50.00; dispersão sem 20.00, com 0.00): ACIMA da dispersão (3 sem e 2 com)'
expect_lacks 'delta FORA da dispersão: NÃO diz "abaixo do ruído"' "$bat" 'abaixo do ruído'
expect_has 'delta da mediana e do p99 (bateria)' "$bat" 'mediana do quadro: +8.67 ms (sem 11.33, com 20.00; dispersão sem 2.00, com 0.00): ACIMA'
expect_has 'delta DENTRO da dispersão (tomada): abaixo do ruído (n execuções por condição)' "$tom" 'FPS médio: -10.00 fps (sem 90.00, com 80.00; dispersão sem 20.00, com 0.00): abaixo do ruído (2 execuções por condição)'
expect_has 'tomada: a mediana também fica abaixo do ruído' "$tom" 'mediana do quadro: +0.75 ms (sem 11.25, com 12.00; dispersão sem 2.50, com 0.00): abaixo do ruído (2 execuções por condição)'
expect_has 'ONDE (bateria): uma seção do quadro' "$bat" 'seção do quadro resto do quadro +8.33 ms por quadro'
expect_has 'ONDE (bateria): a carga da cena' "$bat" 'carga da cena (instanciar e adicionar) +40.0 ms, custo único fora dos quadros'
expect_has 'ONDE (tomada): nada identificável' "$tom" 'ONDE está a diferença: nada identificável'
expect_has 'com 1 execução por condição o ruído NÃO é estimável (nada de "abaixo do ruído" falso)' "$lig" 'ruído NÃO estimável (menos de 2 execuções em uma condição: 1 execuções por condição)'
expect_has 'a CARGA da cena (ler o arquivo e instanciar) por condição e o delta' "$bat" 'FIGURA com: ler o arquivo 1.0 (1.0 a 1.0) | instanciar e adicionar 140.0 (140.0 a 140.0)'

# Os códigos de saída: 1 se algum grupo não tem execução válida, 2 em uso errado.
mkrun "$work/r2/sem/game_release_run_1.txt" bateria sem 'inconclusiva (estado térmico fora do normal DEPOIS: limitação de CPU (CPU_Scheduler_Limit=70))' 10.0 10.0 12.0 15.0
mkrun "$work/r2/com/game_release_run_1.txt" bateria com válida 12.5 12.0 14.0 18.0 1
run_compare "$work/r2/sem" "$work/r2/com"
expect 'grupo sem nenhuma execução válida: código 1' "$rc" 1
expect_has 'o grupo sem execução válida é dito' "$out" 'NENHUMA execução válida neste grupo'
expect_has 'o motivo térmico é listado' "$out" 'limitação de CPU (CPU_Scheduler_Limit=70)'
expect_has 'sem execução COM válida o delta fica INDISPONÍVEL, não inventado' "$out" 'DELTA (com menos sem): INDISPONÍVEL, falta execução válida SEM a figura'
run_compare; expect 'sem argumentos: código 2' "$rc" 2
run_compare "$work/nao_existe"; expect 'caminho que não existe: código 2' "$rc" 2
mkdir "$work/vazia"; run_compare "$work/vazia"; expect 'pasta sem execuções: código 1' "$rc" 1
mkrun "$work/r3/game_release_run_1.txt" bateria sem válida 12.5 12.0 14.0 18.0 '' 100.0 12.20 'CURTA de 10 s (VALIDAÇÃO DO INSTRUMENTO: sem veredito DEC-119)'
run_compare "$work/r3"; expect 'só execuções CURTAS: código 1 (nada a comparar)' "$rc" 1

# Execução sem PERFIL (formato anterior à 7c-1b) ou sem CLASSIFICAÇÃO e as ATENÇÕES do próprio medidor: DESCARTADAS, nunca viram válidas por omissão. Um arquivo sozinho (não pasta) também vale.
mkrun "$work/r4/a/game_release_run_1.txt" tomada sem válida 12.5 12.0 14.0 18.0
mkrun "$work/r4/a/game_release_run_2.txt" tomada sem válida 12.5 12.0 14.0 18.0 '' 100.0 12.20 completa '  ATENÇÃO: quadro de mais de 1 s; o Mac pode ter suspendido, estes números não valem.'
mkrun "$work/r4/a/game_release_run_3.txt" tomada sem válida 12.5 12.0 14.0 18.0 '' 100.0 12.20 completa '  ATENÇÃO: o ensaio POVOADO não teve nenhum corpo; os números dele NÃO medem o caso (S0 cheio).'
mkrun "$work/r4/a/game_release_run_6.txt" tomada com válida 12.5 12.0 14.0 18.0 1 100.0 12.20 completa '  ATENÇÃO: o NPC da figura teve corpo e figura, mas NÃO andou no ensaio POVOADO (is_walking nunca visto): estes números NÃO medem a figura andando.'
grep -v '^PERFIL: ' "$work/r4/a/game_release_run_1.txt" > "$work/r4/a/game_release_run_4.txt"
grep -v '^CLASSIFICAÇÃO: ' "$work/r4/a/game_release_run_1.txt" > "$work/r4/a/game_release_run_5.txt"
run_compare "$work/r4/a" "$work/r4/a/game_release_run_1.txt"
expect_has 'quadro de mais de 1 s: descartada' "$out" 'game_release_run_2.txt: aviso do medidor no ensaio povoado: os números não valem'
expect_has 'povoado sem corpo: descartada' "$out" 'game_release_run_3.txt: aviso do medidor no ensaio povoado: os números não valem (ATENÇÃO: o ensaio POVOADO não teve nenhum corpo'
expect_has 'sem PERFIL: vira grupo à parte, nunca entra em tomada ou bateria' "$out" '######## PERFIL: (arquivo sem a linha PERFIL) ########'
expect_has 'sem CLASSIFICAÇÃO: descartada' "$out" 'game_release_run_5.txt: sem a linha CLASSIFICAÇÃO'
expect_has 'o arquivo dado soma como 2ª leitura (uma pasta e o arquivo dela)' "$out" 'FIGURA sem: 5 execução(ões): 2 válida(s) e 3 inconclusiva(s)'
expect 'grupo (sem PERFIL) sem válida: código 1' "$rc" 1
expect_has 'sem PERFIL: listada com o motivo' "$out" 'game_release_run_4.txt: sem a linha PERFIL'
expect_has 'o aviso do medidor de uma execução VÁLIDA (a figura que não andou) é repassado, e ela segue válida' "$out" 'aviso do medidor (a/game_release_run_6.txt, ensaio povoado): ATENÇÃO: o NPC da figura teve corpo e figura, mas NÃO andou'
expect_has 'a execução COM a figura que não andou continua válida' "$out" 'FIGURA com: 1 execução(ões): 1 válida(s) e 0 inconclusiva(s)'

# Os PIORES quadros: a lista do medidor (acima de 33 ms) vem em ordem do pior para o melhor, só os 5 piores, e o que ficou de fora é contado.
mkrun "$work/r5/game_release_run_1.txt" tomada sem válida 12.5 12.0 14.0 18.0
list='34.0 ms em 1.0 s; 50.0 ms em 2.0 s; 36.0 ms em 3.0 s; 33.5 ms em 4.0 s; 70.0 ms em 5.0 s; 41.0 ms em 6.0 s; 60.0 ms em 7.0 s'
sed "s/acima de 33 ms: 0/acima de 33 ms: 7 ($list)/" "$work/r5/game_release_run_1.txt" > "$work/r5/novo" && mv "$work/r5/novo" "$work/r5/game_release_run_1.txt"
run_compare "$work/r5"
expect_has 'piores quadros: os 5 piores, do pior para o melhor, e quantos ficaram de fora' "$out" 'acima de 33 ms: 7 [piores: 70.0 ms em 5.0 s; 60.0 ms em 7.0 s; 50.0 ms em 2.0 s; 41.0 ms em 6.0 s; 36.0 ms em 3.0 s; +2 outros]'

# A sintaxe e o modo do script.
sh -n "$compare" && echo 'OK: sh -n no script de comparação'
[ -x "$compare" ] && echo 'OK: o script é executável' || { echo 'FALHA: o script não é executável'; exit 1; }
echo 'ART-12 7c-1c: a comparação com e sem a figura, por perfil, aprovada.'
