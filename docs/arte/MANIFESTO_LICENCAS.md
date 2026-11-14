# Manifesto de licenças de arte (Fase 0)

**Status:** PROPOSTA (pesquisa de 13/11/2026, só leitura: nada foi baixado nem adicionado ao repositório). Define a política e lista os candidatos. A DEC-021 (origem da arte) foi **APROVADA por Arthur em 14/11/2026 como direção híbrida** (o áudio segue PENDENTE); a escolha de cada pacote continua sujeita às verificações deste manifesto e ao aceite visual de Arthur. **Registro de pacotes baixados: seção 7.** "n/i" = não informado na página.

## 1. Política (recomendada em 13/11/2026; o núcleo foi adotado pela DEC-021 em 14/11/2026: só CC0 confirmado na página oficial, registro de origem, tamanho, licença e hash, sem bibliotecas inteiras, serviços pagos, cadastro nem IA 3D de terceiros, e só os downloads autorizados; os demais itens seguem como recomendação)
1. Só entra no repositório asset com licença **CC0** (ou domínio público) confirmada na página oficial do pacote, com URL e data.
2. Cada pacote usado ganha uma linha de registro: nome, autor, URL, licença e onde foi declarada, edição (Free ou Standard), data do download, tamanho, hash SHA-256 do zip, formatos, peças usadas e modificações (script de normalização).
3. Versões pagas (Pro, Extra, Source) ficam fora: a regra é custo zero. Só as versões gratuitas.
4. Licença própria, CC-BY ou que proíba redistribuir os arquivos (o repositório é público) não entra.
5. No máximo 2 autores por cena, para manter a coerência de estilo; paleta e materiais normalizados por script.
6. Nenhum asset de jogos comerciais; nenhum serviço de IA 3D de terceiros (conta, licença incerta).
7. O zip original não vai para o Git: só as peças usadas (glTF e textura), já normalizadas, em `assets/kits/<pacote>/` com o texto da licença; este manifesto é o índice. Orçamento de tamanho do repositório [HIP] a definir.

## 2. Candidatos (licença conforme a página oficial de cada pacote)
| Pacote (autor) e página | Licença (onde) | Tamanho grátis | Formatos | Cobertura e limites | Adeq. |
|---|---|---|---|---|---|
| Medieval Village MegaKit (Quaternius) quaternius.com/packs/medievalvillagemegakit.html | CC0 v1.0 (página do itch e do site) | Standard 153 MB | FBX, OBJ, glTF | paredes, pisos, telhados, portas, janelas, móveis, props, folhagem; sem animação; barraca, barril, carroça, poço, bandeira n/i | B |
| Fantasy Props MegaKit (Quaternius) quaternius.com/packs/fantasypropsmegakit.html | CC0 (link da licença na página) | n/i | FBX, OBJ, glTF | 211 peças low-poly, 4 conjuntos de textura; barracas de mercado, vegetais, baús, ferramentas, poções; barril, caixote, saco, cesta, lampião, carroça, bandeirola n/i; Standard = 60 a 70% | A |
| Stylized Nature MegaKit (Quaternius) quaternius.itch.io/stylized-nature-megakit | CC0 v1.0 (campo da página) | Standard 99 MB | FBX, OBJ, glTF | estilo Ghibli, texturizado; 40 árvores, 35 plantas e flores, 27 rochas, grama, arbustos; cogumelos e cristais n/i; facetado n/i | B |
| Medieval Hexagon Pack (KayKit) kaylousberg.itch.io/kaykit-medieval-hexagon | CC0 v1.0 (campo da página; sem exigir atribuição) | Free 33 MB | FBX, glTF, OBJ | 200+ peças, atlas de gradiente 1024x1024; casas, taverna, mercado, poço, ferreiro, estradas, árvores, rochas; malha hexagonal; cavalos e veículos só na Extra paga; pede não revender cópias sem modificação | B |
| Forest Nature Pack (KayKit) kaylousberg.com/game-assets/forest-nature-pack | CC0 (a página diz uso livre, sem atribuição) | n/i | FBX, glTF, OBJ | árvores, arbustos, grama, rochas, atlas de gradiente 1024x1024; contagem inconsistente na página; pinheiros em camadas, cogumelos, cristais, flores n/i | B |
| Fantasy Town Kit 2.0 (Kenney) kenney.nl/assets/fantasy-town-kit | CC0 (campo License; a página de suporte confirma) | n/i (3,9 MB em espelho) | n/i | 160 arquivos; cidade, muros, edifícios; barracas, caixotes, lampiões n/i | B |
| Nature Kit (Kenney) kenney.nl/assets/nature-kit | CC0 (campo License) | n/i | n/i | 330 arquivos; árvores, rochas, folhagem; cogumelos e cristais n/i | B |
| Castle Kit 2.0 (Kenney) | CC0 (campo License) | n/i | n/i | 75 arquivos; muralhas, torres; não é mercado | B |
| Ultimate Nature Pack e Medieval Village Pack (Quaternius) | CC0 (link na página) | n/i | FBX, OBJ, Blend (sem glTF) | 150 e 44 peças; sem animação; categorias n/i | B |

Adequação: A = serve direto (licença, formato e cobertura no texto da página); B = parcial ou dado-chave n/i; C = não serve. As notas vêm só do texto das páginas: **nenhuma aparência foi vista**.

## 3. Fora da política
- **Shuriken Studio (Low-Poly World 3D Models):** licença própria que proíbe compartilhar os arquivos dos modelos; incompatível com repositório público.
- **Pro, Extra e Source** dos pacotes acima (US$ 9,99 a 14,99+): fora da regra de custo zero.
- **heyheythere** (CC BY 4.0 segundo busca, exige crédito) e itens avulsos do OpenGameArt (páginas deram HTTP 403; CC0 só em trecho de busca): não verificados, não entram.
- **Poly Haven:** CC0 confirmado, mas sem evidência de modelos estilizados (útil para céus e texturas, a avaliar).

## 4. Combinações mínimas (até 3 pacotes, só versões grátis) e ordem sugerida
1. **Quaternius** Medieval Village + Fantasy Props + Stylized Nature (um autor, mais rico; 153 + 99 MB + n/i). Lacunas: barril, caixote, saco, lampião, bandeirola, poço, carroça, cogumelo e cristal n/i.
2. **KayKit** Medieval Hexagon Free (33 MB) + Forest Nature (um autor, leve; mesmo atlas, sem retexturizar). Lacunas: layout preso a hexágonos; poucos adereços soltos.
3. **Kenney** Fantasy Town Kit + Nature Kit + **Quaternius** Fantasy Props (base leve com CC0 bem documentado; 2 autores).
Ordem sugerida pela pesquisa: 1, 3, 2. As combinações 1 e 3 dependem de as barracas estarem na versão grátis do Fantasy Props (n/i).

## 5. Riscos e o que NÃO foi confirmado
- A licença é declarada **por pacote**, não pelo site: registrar URL, data e hash do zip; o arquivo de licença dentro dos zips não foi lido.
- Coerência: Kenney (paleta chapada), KayKit (atlas de gradiente) e Quaternius (texturas compartilhadas) diferem em saturação, escala, densidade de polígonos e facetamento. Mitigação: no máximo 2 autores por cena, cena de teste lado a lado, material ou atlas único e a mesma iluminação.
- Não confirmado: aparência e facetamento real de qualquer pacote; barris, caixotes, sacos, cestas, carroças, lampiões, bandeirolas, ruas de pedra, pinheiros em camadas, cogumelos e cristais; quais peças entram nas versões grátis; tamanhos de Kenney, Fantasy Props, Ultimate Nature, Village Pack e Forest Nature; outros pacotes de Quaternius e Kenney.

## 6. Próximo passo (depende de Arthur)
Para decidir pela aparência, falta **baixar uma amostra pequena de cada candidato e ver o render**. Proposta mínima, só versões grátis: Kenney Fantasy Town Kit 2.0 (cerca de 4 MB), KayKit Medieval Hexagon Free (33 MB) e Quaternius Fantasy Props MegaKit Standard (tamanho n/i, estimado abaixo de 100 MB). Cada download será informado antes (pacote, fonte, licença e tamanho) e registrado aqui com hash.

## 7. Registro de pacotes baixados (DEC-021: origem, tamanho, licença e hash por pacote, e só as peças usadas)
| Pacote | Autor e origem | Licença | Baixado | Zip | Conteúdo | Peças usadas |
|---|---|---|---|---|---|---|
| **Fantasy Town Kit 2.0** | Kenney, `kenney.nl/assets/fantasy-town-kit` (página oficial) | **CC0 1.0** (`License.txt` do pacote: "Creative Commons Zero"; a página diz "Creative Commons CC0"); crédito opcional | por Arthur, em 14/11/2026 (arquivo `kenney_fantasy-town-kit_2.0.zip`) | 3.854.691 bytes; SHA-256 `1a7530c09f4d2fa2cdee259876f089334f8b1f27fa86a0c4f54ef86cdd8676ef` | 167 modelos em GLB (e os mesmos em FBX e 335 arquivos OBJ), uma textura de paleta (`variation-a.png`, 11 KB), cerca de 26 mil triângulos no total (média de 157 por peça), módulos de 1 unidade, **sem personagens**; categorias: paredes 63, telhados 26, escadas 13, fonte 10, rua 9, sebes 6, pinheiros 5, barracas 5, cercas 4, pedras 3, carroças 2, estandartes 2, lampião 1, moinhos | **amostra de 37 modelos GLB** (paredes de madeira e de pedra, telhados, chaminé, barracas, carroça, estandartes, lampião, fonte, cerca, sebe, pinheiros, pedras, calçamento, tábuas) só nos protótipos ART-8 e ART-9, **fora do Git** até o aceite visual de Arthur |

Escala: na escala humana do jogo (habitante de 1,7 m) o fator de uso é **2,5** (confirmado na ART-9b). **Textura:** os GLB referenciam `Textures/colormap.png`, mas o pacote traz só `variation-a.png` (a variação A, pastel); nos protótipos ela foi copiada com o nome `colormap.png`. A paleta padrão das prévias (telhados vermelho e verde-azulado) **não** vem no zip. O zip original não vai para o Git (política 7).
