# Medição do Ice Warrior em release, perfil TOMADA (17/11/2026): resultado EXPLORATÓRIO, não conclusivo

**Status:** medição real executada em 17/11/2026 com a autorização expressa de Arthur ("PODE MEDIR AGORA"), no perfil de energia **tomada** (o perfil **bateria**, prioritário, segue **PENDENTE** para outra oportunidade). **Arthur a classificou como EXPLORATÓRIA, NÃO conclusiva** (a cena-base também falhou na DEC-119 e o Mac executava outras atividades). **A DEC-119 NÃO muda.** Instrumento: `tests/soak/medir_figura` (PRs #106, #107, #112 e #113); só mede, não decide nada.

## 1. As condições (ditas com franqueza)
- **Máquina:** Mac15,13 (MacBook Air, Apple M3), macOS 26.6.2, Godot 4.7.2 em **release**, renderizador **Metal, método `mobile`** (Forward Mobile). Tela interna de **60 Hz** com **vsync ligado**, janela de 1152 x 648. Baixo consumo desligado.
- **Energia:** tomada, bateria em 58% **carregando**; nenhum aviso térmico nem de desempenho; as 6 execuções foram classificadas **válidas** pelo instrumento.
- **O Mac NÃO estava ocioso:** uma atualização do macOS rodava em segundo plano, o WindowServer ficava perto de 40% de CPU e o Chrome estava ativo; a CPU ficou entre **56% e 70% ociosa** (a carga de fundo foi registrada antes e depois).
- **O roteiro:** uma execução CURTA de validação (10 s, com a figura) e **6 execuções do ensaio `povoado` de 30 s**, em ordem contrabalançada **sem, com, com, sem, sem, com** (3 pares). A figura: 1 Ice Warrior (a área local liga a figura ao NPC 37; o custo não depende do ofício), **1 figura ativa em todas as execuções COM**; o aviso "a figura não andou" saiu só na execução curta de 10 s.

## 2. Os números (3 execuções por condição; média e, entre parênteses, de mín a máx)
| | SEM a figura | COM a figura | Diferença (com menos sem) |
|---|---|---|---|
| FPS médio | 59,32 (59,28 a 59,42) | 59,32 (59,31 a 59,35) | -0,00: abaixo do ruído |
| Mediana do quadro | 16,69 ms | 16,70 ms | +0,02 ms: abaixo do ruído |
| Percentil 99 do quadro | 27,1 ms (19,8 a 31,9) | 27,0 ms (20,0 a 31,1) | -0,05 ms: abaixo do ruído |
| Pior quadro | 69,4 ms (51,2 a 88,5) | 71,2 ms (51,9 a 93,9) | dentro da dispersão |
| Quadros acima de 16,7 ms (em 30 s) | 875,7 | 897,3 | dentro da dispersão |
| Quadros acima de 33 ms (em 30 s) | 14,0 (13 a 16) | 11,3 (11 a 12) | dentro da dispersão |
| Custo por seção, ms por quadro | `NpcBodiesView` 0,5; `NpcBodyDriver` 0,84; resto 15,5 | iguais | nenhuma |
| **Carga da cena** (instanciar e adicionar; custo ÚNICO, fora dos quadros) | 91,6 ms | 130,8 ms | **+39,2 ms**: acima da dispersão (indício, a confirmar com mais execuções) |

## 3. A leitura
- **A figura não acrescentou custo mensurável POR QUADRO nestas condições** (todas as diferenças de quadro ficaram abaixo do ruído); o único efeito visto é o custo único de +39 ms na carga da cena.
- **A DEC-119 FALHOU nas 6 execuções, INCLUSIVE SEM a figura** (média de 59,3 fps, abaixo de 60, e 11 a 16 quadros acima de 33 ms por execução). Duas razões, a segunda só uma hipótese: (a) com vsync em 60 Hz o quadro fica preso em 16,67 ms (a mediana foi 16,7 ms): a média só chega a 60,0 se NENHUM quadro for perdido, e perder cerca de 1% já dá 59,3; (b) os picos de 35 a 94 ms apareceram igualmente com e sem a figura, compatíveis com o Mac ocupado, mas isto NÃO foi provado.
- **Não comparar com 7/11:** a medição de 7/11 usava OpenGL (`gl_compatibility`) e os ensaios ROTA, PARADO e PAUSADO (média de 8,3 ms); hoje o jogo rodou em Metal Forward Mobile e no ensaio `povoado` (com corpos). Não são comparáveis diretamente.
- **O que esta rodada NÃO prova:** nem que o jogo atende a DEC-119, nem que não atende; nem a figura andando em quantidade; nem a bateria.

## 4. A decisão de Arthur (17/11/2026)
Resultado **exploratório, não conclusivo**; **não repetir agora**; registrar o resultado do perfil tomada (este documento); **manter a DEC-119 inalterada**; **não iniciar novas otimizações do Ice Warrior sem evidência de gargalo causado pela figura**; deixar o perfil **bateria** pendente.

## 5. PROPOSTA (NÃO implementada; Arthur autorizou só preparar): diagnóstico COMPLEMENTAR de folga
**Problema.** Com vsync ligado em tela de 60 Hz o quadro é quantizado em 16,67 ms: um jogo que gasta 5 ms por quadro e outro que gasta 16 ms leem os dois "cerca de 60 fps". O veredito da DEC-119 (média de 60 fps ou mais e nenhum quadro acima de 33 ms) não mostra QUANTA FOLGA o jogo tem.
**Proposta (sem alterar nem substituir a DEC-119):** um bloco OPCIONAL e SEPARADO no medidor (`DIAGNOSTICO_FOLGA=1`), rotulado **"DIAGNÓSTICO COMPLEMENTAR (não é o veredito DEC-119)"**, que repete cada ensaio com o vsync DESLIGADO (`DisplayServer.window_set_vsync_mode(VSYNC_DISABLED)`, como `tests/soak/sp4a/sp4a_main.gd` já faz) e imprime o tempo de TRABALHO do quadro (média, mediana, p95, p99, pior), a **folga** (16,67 ms dividido pela média do trabalho; por exemplo 8,4 ms de trabalho = folga de 2,0 vezes), a fração dos quadros cujo trabalho passa de 16,67 ms e de 33 ms, e o custo por seção que o medidor já traz. O veredito DEC-119 (com vsync, como hoje) continua o oficial e a sua lógica não muda; o `compare_game_release` ganharia um grupo à parte para o diagnóstico (nunca somado ao da DEC-119).
**Cuidados.** (1) Validar o próprio diagnóstico: se a mediana do trabalho der exatamente 16,67 ms, o vsync NÃO foi desligado e o bloco se declara inválido; (2) a carga de fundo e o perfil de energia continuam registrados e nunca misturados; (3) o diagnóstico só mede folga: quanta folga basta é decisão de Arthur (esta proposta não sugere limite).
**Custo estimado:** cerca de 80 linhas no medidor e no `compare_game_release` e um teste com o `run_game_release` falso (classe 1, ferramenta). **Precisa da aprovação de Arthur para implementar.**

## 6. Os dados brutos
Fora do Git, no Mac de Arthur: `$HOME/lw-release-probe/figura_20261117_183211/` (`sem/` e `com/` com os `game_release_run_N.txt`, e as saídas de cada chamada). O registro desta sessão (com a carga de fundo antes e depois) fica no scratchpad da tarefa.
