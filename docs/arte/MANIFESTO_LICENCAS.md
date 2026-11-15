# Manifesto de licenças de arte (Fase 0)

**Status:** PROPOSTA (pesquisa de 13/11/2026, só leitura; os pacotes da Quaternius foram baixados em 14/11/2026 e o subconjunto processado entrou no repositório (seção 7.1)). Define a política e lista os candidatos. A DEC-021 (origem da arte) foi **APROVADA por Arthur em 14/11/2026 como direção híbrida** (o áudio segue PENDENTE); a escolha de cada pacote continua sujeita às verificações deste manifesto e ao aceite visual de Arthur. **Registro de pacotes baixados: seção 7.** "n/i" = não informado na página.

## 1. Política (recomendada em 13/11/2026; o núcleo foi adotado pela DEC-021 em 14/11/2026: só CC0 confirmado na página oficial, registro de origem, tamanho, licença e hash, sem bibliotecas inteiras, serviços pagos, cadastro nem IA 3D de terceiros, e só os downloads autorizados; os demais itens seguem como recomendação)
1. Só entra no repositório asset com licença **CC0** (ou domínio público) confirmada na página oficial do pacote, com URL e data.
2. Cada pacote usado ganha uma linha de registro: nome, autor, URL, licença e onde foi declarada, edição (Free ou Standard), data do download, tamanho, hash SHA-256 do zip, formatos, peças usadas e modificações (script de normalização).
3. Versões pagas (Pro, Extra, Source) ficam fora: a regra é custo zero. Só as versões gratuitas.
4. Licença própria, CC-BY ou que proíba redistribuir os arquivos (o repositório é público) não entra.
5. No máximo 2 autores por cena, para manter a coerência de estilo; paleta e materiais normalizados por script.
6. Nenhum asset de jogos comerciais; nenhum serviço de IA 3D de terceiros (conta, licença incerta).
7. O zip original não vai para o Git: só as peças usadas (glTF e textura), já normalizadas, em `assets/characters/quaternius/` (e, para outros kits, `assets/kits/<pacote>/`) com o texto da licença; este manifesto é o índice. Orçamento de tamanho do repositório [HIP] a definir.

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
- A licença é declarada **por pacote**, não pelo site: registrar URL, data e hash do zip; os arquivos de licença dentro dos zips da Quaternius foram lidos (seção 7).
- Coerência: Kenney (paleta chapada), KayKit (atlas de gradiente) e Quaternius (texturas compartilhadas) diferem em saturação, escala, densidade de polígonos e facetamento. Mitigação: no máximo 2 autores por cena, cena de teste lado a lado, material ou atlas único e a mesma iluminação.
- Não confirmado: aparência e facetamento real de qualquer pacote; barris, caixotes, sacos, cestas, carroças, lampiões, bandeirolas, ruas de pedra, pinheiros em camadas, cogumelos e cristais; quais peças entram nas versões grátis; tamanhos de Kenney, Fantasy Props, Ultimate Nature, Village Pack e Forest Nature; outros pacotes de Quaternius e Kenney.

## 6. Próximo passo (depende de Arthur)
Para decidir pela aparência, falta **baixar uma amostra pequena de cada candidato e ver o render**. Proposta mínima, só versões grátis: Kenney Fantasy Town Kit 2.0 (cerca de 4 MB), KayKit Medieval Hexagon Free (33 MB) e Quaternius Fantasy Props MegaKit Standard (tamanho n/i, estimado abaixo de 100 MB). Cada download será informado antes (pacote, fonte, licença e tamanho) e registrado aqui com hash.

## 7. Registro de pacotes baixados (DEC-021: origem, tamanho, licença e hash por pacote, e só as peças usadas)
| Pacote | Autor e origem | Licença | Baixado | Zip | Conteúdo | Peças usadas |
|---|---|---|---|---|---|---|
| **Fantasy Town Kit 2.0** | Kenney, `kenney.nl/assets/fantasy-town-kit` (página oficial) | **CC0 1.0** (`License.txt` do pacote: "Creative Commons Zero"; a página diz "Creative Commons CC0"); crédito opcional | por Arthur, em 14/11/2026 (arquivo `kenney_fantasy-town-kit_2.0.zip`) | 3.854.691 bytes; SHA-256 `1a7530c09f4d2fa2cdee259876f089334f8b1f27fa86a0c4f54ef86cdd8676ef` | 167 modelos em GLB (e os mesmos em FBX e 335 arquivos OBJ), uma textura de paleta (`variation-a.png`, 11 KB), cerca de 26 mil triângulos no total (média de 157 por peça), módulos de 1 unidade, **sem personagens**; categorias: paredes 63, telhados 26, escadas 13, fonte 10, rua 9, sebes 6, pinheiros 5, barracas 5, cercas 4, pedras 3, carroças 2, estandartes 2, lampião 1, moinhos | **amostra de 37 modelos GLB** (paredes de madeira e de pedra, telhados, chaminé, barracas, carroça, estandartes, lampião, fonte, cerca, sebe, pinheiros, pedras, calçamento, tábuas) só nos protótipos ART-8 e ART-9, **fora do Git** até o aceite visual de Arthur |
| **Modular Character Outfits: Fantasy [Standard]** | Quaternius, `quaternius.itch.io/modular-character-outfits-fantasy` (página oficial) | **CC0 1.0** (`License_Standard.txt` do zip: "CC0 1.0 Universal (CC0 1.0) Public Domain Dedication"; a página: "Asset license: Creative Commons Zero v1.0 Universal"); crédito opcional | em 14/11/2026 (ART-11), arquivo `Modular Character Outfits - Fantasy[Standard].zip`, **fora do Git** | 294.347.394 bytes; SHA-256 `c3468b18871cc8c8f05ab14df7712baf22cb9f389cbd870babf130e595187f70` | 4 roupas (Peasant e Ranger, masculina e feminina) e 20 peças soltas, em glTF e FBX; texturas de 4096 px (cor, normal e ORM); esqueleto de 65 ossos | **as 22 peças das 4 roupas** (dos `Outfits/*.gltf`), processadas em `assets/characters/quaternius/outfits/` (ver 7.1) |
| **Universal Base Characters [Standard]** | Quaternius, `quaternius.itch.io/universal-base-characters` (página oficial; o pacote cita `quaternius.com/packs/universalbasecharacters.html`) | **CC0 1.0** (`License_Standard.txt` do zip: "CC0 1.0 Universal (CC0 1.0) Public Domain Dedication"; a página: "Asset license: Creative Commons Zero v1.0 Universal"); crédito opcional | em 14/11/2026 (ART-11), arquivo `Universal Base Characters[Standard].zip`, **fora do Git** | 128.968.391 bytes; SHA-256 `fdbf1804c90dfc1ea03e992bff7da2dfd1a79318e13270a660180f9308455f40` | 2 corpos "Superhero" (cerca de 14,3 e 15,1 mil triângulos com olhos e sobrancelhas), 6 cabelos (um é a barba) e 2 sobrancelhas, em glTF e FBX; texturas de 2048 px; mesmo esqueleto de 65 ossos | **cabeça e olhos dos 2 corpos**, **6 cabelos e 2 sobrancelhas** (versão presa ao osso da cabeça), em `base/` e `hair/` (ver 7.1) |
| **Universal Animation Library [Standard]** | Quaternius, `quaternius.itch.io/universal-animation-library` (página oficial) | **CC0 1.0** (`License.txt` do zip: "CC0 1.0 Universal (CC0 1.0) Public Domain Dedication"; a página: "Asset license: Creative Commons Zero v1.0 Universal"); crédito opcional | em 14/11/2026 (ART-11), arquivo `Universal Animation Library[Standard].zip`, **fora do Git** | 15.904.933 bytes; SHA-256 `cc73fc4e495b82958207316596317a3f40b9fa38065bde1027937452da537724` | 43 animações em GLB e FBX, em duas versões (sem e com movimento de raiz, `_RM`), no mesmo esqueleto de 65 ossos | **6 das 43 animações** (versão sem movimento de raiz), em `animations/` (ver 7.1) |

Escala: na escala humana do jogo (habitante de 1,7 m) o fator de uso é **2,5** (confirmado na ART-9b). **Textura:** os GLB referenciam `Textures/colormap.png`, mas o pacote traz só `variation-a.png` (a variação A, pastel); nos protótipos ela foi copiada com o nome `colormap.png`. A paleta padrão das prévias (telhados vermelho e verde-azulado) **não** vem no zip. O zip original não vai para o Git (política 7).

### 7.1 Quaternius: subconjunto processado e versionado (ART-12, entrega 2; 15/11/2026)
Autorização de Arthur (14/11/2026): incluir no Git o subconjunto PROCESSADO (cerca de 17 MB comprimidos), só o necessário, com a procedência CC0 verificada, sem redundância e sem depender de `Downloads`. Os zips originais seguem preservados FORA do Git e o projeto roda sem eles. Destino: `assets/characters/quaternius/` (`README.md`, `License_*.txt`, `outfits/`, `base/`, `hair/`, `animations/`); catálogo: `data/presentation/character_catalog.json`; teste: `tests/unit/test_character_assets.gd`; script que regenera tudo a partir dos zips: `tools/assets/process_quaternius` (confere o SHA-256 dos zips; duas execuções seguidas deram os 60 arquivos gerados idênticos byte a byte, com o Godot 4.7.2).

**Evidência de licença (citações de até 15 palavras).** (a) Nos três zips, `License_Standard.txt` (Fantasy e Base Characters) e `License.txt` (Animation Library): "CC0 1.0 Universal (CC0 1.0) Public Domain Dedication", com a URL `https://creativecommons.org/publicdomain/zero/1.0/`; copiados (só com o fim de linha convertido de CRLF para LF) para `License_Fantasy_Standard.txt`, `License_UBC_Standard.txt` e `License_UAL.txt`. (b) Páginas oficiais do itch.io: "Asset license: Creative Commons Zero v1.0 Universal" e "Free to use in personal, educational and commercial projects. (CC0 License)"; páginas do `quaternius.com`: "License CC0". **As citações (b) vêm da verificação feita em 14/11/2026 e NÃO foram relidas nesta entrega (sem rede).** O CC0 dispensa crédito; os arquivos de licença trazem só um convite de apoio no Patreon, sem efeito legal.

**O que entrou e por quê (só o necessário para o contrato "Personagens animados do mundo", `docs/modules/presentation.md`).**
- Roupas (22 arquivos em `outfits/`): as 4 roupas, uma peça por arquivo e com os nomes originais: tronco e braços juntos (`*_Body_Arms`: a manga e a mão só fazem sentido com o tronco), pernas, botas e, só no Ranger, capuz, ombreira, braceleira e dois cintos. Fonte: `Outfits/*.gltf` (a braceleira e os cintos só existem neles). NÃO entraram: `Modular Parts/` (as mesmas peças repetidas), os FBX, as pastas `Textures/` (cópias das mesmas texturas) e as peles claras (o contrato varia só o pano).
- Cabeça (2 arquivos em `base/`): só cabeça e pescoço do corpo-base, mais os olhos. O corpo nu NÃO é necessário: as roupas cobrem tronco, braços, mãos, pernas e pés, e ele atravessaria o pano (o `Readme.txt` do pacote Fantasy: "only the head of the model is required"). A cabeça tem 3.620 (masculina) e 3.838 (feminina) triângulos, contra 12.566 e 12.812 do corpo. As sobrancelhas embutidas no corpo foram removidas (vêm dos arquivos de cabelo, sem repetição).
- Cabelos, barba e sobrancelhas (8 arquivos em `hair/`): 5 cabelos (`Hair_Buzzed`, `Hair_SimpleParted`, `Hair_BuzzedFemale`, `Hair_Buns`, `Hair_Long`), 1 barba (`Hair_Beard`: pelo facial, para combinar com um cabelo; no catálogo ela fica na lista OPCIONAL `beards`, e não em `hair`, e só os homens a recebem) e as 2 sobrancelhas (`Eyebrows_Regular`, do gênero `male` no catálogo, e `Eyebrows_Female`, do gênero `female`; leitura feita pelos nomes dos arquivos), na versão presa ao osso da cabeça (acompanham a animação).
- Animações (1 arquivo, `animations/UAL1_Standard_Subset.glb`): 6 das 43, da versão sem movimento de raiz (quem move o NPC é a simulação): `Idle_Loop` e `Walk_Loop` (o mínimo: ações `wait` e `go_to_place`), `Jog_Fwd_Loop` (pressa e `flee`), `Idle_Talking_Loop` (`talk` e `talk_player`), `PickUp_Table` (`buy` e `sell`) e `Interact` (`work`). O Godot as importa como `Idle`, `Walk`, `Jog_Fwd`, `Idle_Talking` (repetem) e `PickUp_Table`, `Interact` (não repetem). Ficaram de fora: combate, magia, arma de fogo, natação, direção, pulo, rolamento, agachar, sentar, dança, morte, T-pose e `Fixing_Kneeling` (5,2 s, cerca de 0,45 MB e sem ação de NPC que a use hoje), a versão `_RM` (repetida) e a malha-manequim do arquivo (só o esqueleto é necessário).

**Transformações (todas em `tools/assets/process_quaternius`; só o Godot, sem ferramenta externa).**
1. Texturas: 4096 e 2048 px viram 1024 px (filtro Lanczos do `Image.resize`); os olhos (256 px) ficam como estão. Formato **WebP SEM perdas**, e não PNG: os mesmos pixels e 3,6 MB a menos (13,66 MB contra 17,27 MB em PNG de 1024 px). O Godot lê WebP direto (os glTF apontam para o arquivo por caminho relativo, `textures/...`); um visualizador de glTF que não conheça WebP não mostraria as texturas, o que não afeta o jogo. O canal alfa, todo opaco nos mapas de normal, foi descartado. Cada textura existe UMA vez por pasta, compartilhada pelas peças (os originais a repetem em várias pastas). As três licenças (`License_*.txt`) tiveram os fins de linha convertidos de CRLF para LF, como o `.gitattributes` (`* text=auto eol=lf`) as guarda: o SHA-256 do manifesto é o do arquivo versionado. Regenerar o subconjunto por cima troca os `uid` dos 57 `.import` (o molde do script não os traz): nada referencia por `uid` (o catálogo usa caminhos `res://`), mas o diff fica sujo; regenere só se for preciso.
2. Modelos: cada peça virou um GLB com o esqueleto de 65 ossos inteiro (nomes de ossos, nós, malhas e materiais inalterados) e só as malhas da peça, com os dados copiados byte a byte para buffers novos e compactos. As camadas de UV e de cor sem uso (`TEXCOORD_1` a `4` e `COLOR_1` a `3`) foram removidas: os materiais só usam `TEXCOORD_0` (`COLOR_0` foi mantida).
3. Cabeça: ficam os triângulos cujos 3 vértices têm como osso de maior peso `Head` ou `neck_01` (a regra do protótipo da ART-12); vértices e índices recompactados, `min` e `max` de `POSITION` recalculados.
4. Animações: dados das trilhas copiados sem alteração; ficam só o esqueleto, o `skin` e as 6 animações.
5. Referência quebrada do original: os glTF do corpo citam `T_Eye_Normal_png.png`, que não existe no zip; usa-se `T_Eye_Normal.png` (agora em WebP).
6. Importação do Godot, nos `.import` versionados (o cache `.godot/` não é versionado): texturas com `compress/mode=2` (VRAM Compressed; o Godot gera S3TC, aceito pelo Compatibility, pelo Mobile e pelo Forward+), `mipmaps/generate=true` e, nos mapas de normal, `compress/normal_map=1`; cenas com `meshes/generate_lods=true`, `meshes/create_shadow_meshes=true` e `meshes/ensure_tangents=true`. Depois de trazer o ramo, rode `godot --headless --path . --import`.

**Tamanho final.** 118 arquivos e 20.744.328 bytes (19,8 MiB; a conversão das licenças para LF tirou 54 bytes de CR; o teto do teste é 20 MiB): 61 de conteúdo (24 texturas WebP, 13,66 MB; 33 GLB, 7,01 MB; 3 licenças e o README) e 57 `.import`. Compactado (`tar.gz` do diretório): 16.231.145 bytes (15,5 MiB). Na GPU, com S3TC, mipmaps e 1024 px, a ART-12a mediu cerca de 17 MB.

**Arquivos versionados e SHA-256.** O teste confere que este manifesto cita o SHA-256 de cada um (os `.import` são gerados pelo Godot e ficam de fora). Os hashes valem para os arquivos do Git; regenerar em outro sistema pode dar WebP e GLB com bytes diferentes (bibliotecas de compressão).

| Arquivo (em `assets/characters/quaternius/`) | Bytes | SHA-256 |
|---|---|---|
| `License_Fantasy_Standard.txt` | 708 | `9eddea33ca29a6d3918a2a6fa62e0441e6ecc4626c73a18d752e2a35ae4bb22f` |
| `License_UAL.txt` | 320 | `d77329b05c4c206e76c83285ecdd1e5f2b3df2350ec80657ebdb5a706a0fc0de` |
| `License_UBC_Standard.txt` | 784 | `e08f717c3cfd999f4b44f2be4522b11a3ac3c0e5b6364b3a8788d25d4c90ff94` |
| `README.md` | 1539 | `2fe55ab3cbe26859e956b4a0261cee67d13f397eb87b8df73ca591e5dd39d2c9` |
| `animations/UAL1_Standard_Subset.glb` | 1111172 | `f2d72a837477931922f74c32e40af62588eddda415a90cf2fa06646ae0dad7f3` |
| `base/Superhero_Female_Head.glb` | 171040 | `ae3fd5c00632f1753fd1f9903e30d069836a9ff356f0f789033f0d35a8b7f6d5` |
| `base/Superhero_Male_Head.glb` | 163472 | `45c08c2ef19f467d13748cd64fe6807c5742d0f0715ba64964a08a3e28c0a660` |
| `base/textures/T_Eye_Brown.webp` | 23812 | `5d5d919cbe033297543d6886f1429c4d41c4157ed47cf2529ec0d1daaaf85a8f` |
| `base/textures/T_Eye_Normal.webp` | 10714 | `44629285a260d4b0c4d35c415450a8e67c88d81ddbfd22b4e151d6cf3d2c552c` |
| `base/textures/T_Superhero_Female_Dark_BaseColor.webp` | 394988 | `0cbdcc1ca4c8ef7a80dfc6ee1758e019973b80d969208dc6dbd8d437222b0d5c` |
| `base/textures/T_Superhero_Female_Normal.webp` | 654538 | `4ec9b0d5c7fa21a210d17e584ca1a45829448f6c13de8569e1dbd1a2cf401bb8` |
| `base/textures/T_Superhero_Female_Roughness.webp` | 517962 | `9bd8d7a858a5294ca31d2516d27a12f46b3a470bddc6650e45e81d28921f146f` |
| `base/textures/T_Superhero_Male_Dark.webp` | 410142 | `26cc0b99722c4259844c71e7ae6638f21c1244f47f9244734acf4afc1ee41d3e` |
| `base/textures/T_Superhero_Male_Normal.webp` | 742354 | `43dfcb9cdd41eed7adac8e20bdf0fcfae0689131e8c9469f481a8eb4985740f9` |
| `base/textures/T_Superhero_Male_Roughness.webp` | 498054 | `27235769772c0e5a1f4a56d868e0e51e49d3e6de407ad4de42e46a2eda881121` |
| `hair/Eyebrows_Female.glb` | 81636 | `19e8c400d1e3a5b70807fdcc00cd71b0fb9f9d95538dc6b888eac8567b91d318` |
| `hair/Eyebrows_Regular.glb` | 60312 | `8c99ab8eea1d9a832ec64ba60c49ced36c4ede4552401eb8cc7c958807c8d12f` |
| `hair/Hair_Beard.glb` | 58008 | `88456f81b3f35f81658dae3451912a77614f30567d516be051ad095eee4e74cf` |
| `hair/Hair_Buns.glb` | 223276 | `42b48e6a0481ee2eff00a141ce5bddd8da6de03ed7e303a67a7dbc86d3e34bee` |
| `hair/Hair_Buzzed.glb` | 50028 | `c4da7fe0a28d816a6951f4e763b78564a9a45b8551a0171c0e4243d287cae4e7` |
| `hair/Hair_BuzzedFemale.glb` | 50700 | `8aa69cb631554892e357007c43d3ea1258a6f8c12005d7a0b5b50ed9401e4c4d` |
| `hair/Hair_Long.glb` | 199116 | `77987c7e28db57f76ce97092bfa765cb704530b2032dad4ab83e0a0f0fa79919` |
| `hair/Hair_SimpleParted.glb` | 67984 | `40c07b5e03ab498a3f0a3b1e22d4ebf8549977c530b96e4b6e038622e02f8231` |
| `hair/textures/T_Hair_1_BaseColor.webp` | 538734 | `84b18384f974dc43e1d694f723be03879498a99adc38d786eb1e725863f77c66` |
| `hair/textures/T_Hair_1_Normal.webp` | 937786 | `66cad20f29ae5f34876fcf358c49b63c3e7d4396f14e8f45da2ac3007adf81a1` |
| `hair/textures/T_Hair_2_BaseColor.webp` | 629312 | `0427e988db1e14b1169f4886fdb80839a39acd24702e98f364d55755d491c5a3` |
| `hair/textures/T_Hair_2_Normal.webp` | 1124152 | `97ce14a107de7ea0fe925d7ee9b33fe29de5d791e5ce7124797985f0b165421f` |
| `outfits/Female_Peasant_Body_Arms.glb` | 456700 | `251b48e200c721c4c600fe1c1f7c3cdaef9f64b3e484a09c06cdb07134d83f44` |
| `outfits/Female_Peasant_Feet.glb` | 143280 | `e7038d1152be44a0d067d62556280228040f80ecd7538998af4833c6519d0cf7` |
| `outfits/Female_Peasant_Legs.glb` | 91852 | `e3bf8106d1682d8a607bb6a8860c6a70392ea536425f5f64eae2220515d3ecc0` |
| `outfits/Female_Ranger_Acc_Pauldrons.glb` | 91208 | `46d9f3fd5eefb430ace63f0eb3bd5ca013f184620858831297e706d0c19fccf2` |
| `outfits/Female_Ranger_Arms_Bracer.glb` | 267624 | `7a264279da7e98bde1697995fca0b35708857ec45730f2802b9a8493debbd924` |
| `outfits/Female_Ranger_Body_Arms.glb` | 394500 | `6b7e991fe2131a0465555adc3be3697dc79957d525fac18d13f6984ad6ff8ae1` |
| `outfits/Female_Ranger_Body_Belt_1.glb` | 78584 | `1c2a6853a995fcf6c4f08c1e2ba108c94bd045a8002be4d8c2e9cedf45849fed` |
| `outfits/Female_Ranger_Body_Belt_2.glb` | 78584 | `aa34f06cd27d3e8ebec7e767dbcfe91b5b565030f5c7cca80f1e7e80139880fa` |
| `outfits/Female_Ranger_Feet.glb` | 646584 | `63c67754a30641aa8de21fcfb42fe603dd4f07c64cc7e4f67793b4e0c85b10e2` |
| `outfits/Female_Ranger_Head_Hood.glb` | 104052 | `f95fef75400ebe9ad87c2d3fe251854822bd62313e6aa04bfbba897c879bef73` |
| `outfits/Female_Ranger_Legs.glb` | 67356 | `ef1c10ff8a75c1a7907e9f77269fa7fdb0c9efe5da5bff3c03a67b653496c5fa` |
| `outfits/Male_Peasant_Body_Arms.glb` | 433344 | `fee17e444711a56e21f8f48911202478c0ca997bd4729ee59d84ff24b10e8485` |
| `outfits/Male_Peasant_Feet.glb` | 141832 | `b849d142a66f0afb7a11a336f4a1001a8b5f814240525d7d713f9fe02e9fbeb1` |
| `outfits/Male_Peasant_Legs.glb` | 64528 | `40f16605fa4d5f53d770c42cd2163959fdcdd6dad13c0c9f446dc6eeddf9f190` |
| `outfits/Male_Ranger_Acc_Pauldron.glb` | 86012 | `fa9e87f1693d91fb5ef94a4bb2fc954041bafcb10f7780b8e3cbb8cf951389b2` |
| `outfits/Male_Ranger_Arms_Bracer.glb` | 266960 | `3f2293d41fad8c99517649147c8072372afa72c4e5430b6c88ab39617d7893eb` |
| `outfits/Male_Ranger_Body_Arms.glb` | 400308 | `ca5bdab6649026beaedfb0c72ef933442cd9bbe83602519e2006fcf3d752fc07` |
| `outfits/Male_Ranger_Body_Belt_1.glb` | 74044 | `561cf2a29555f73ad461a6f55dd211a2ebab3d69dbb23cc35565603020da3acb` |
| `outfits/Male_Ranger_Body_Belt_2.glb` | 74048 | `42eddb523fa006eccb9d70074270dc72709f2dd7fad3fa5b55e211f91dff23e5` |
| `outfits/Male_Ranger_Feet_Boots.glb` | 645932 | `68f41e55a523f36d934e9f8dd2f53e8c28a442691a09772a5ee590b9c1ec9f5a` |
| `outfits/Male_Ranger_Head_Hood.glb` | 103384 | `228491bd20f3ccd1135038aac0b6b6cf960b503516cb811eb967e8c4c86147dc` |
| `outfits/Male_Ranger_Legs.glb` | 63940 | `e78afb4801b250787be1d29baa9e63b78f5d32cb22da6185640a89c272d1ea8f` |
| `outfits/textures/T_Peasant_BaseColor.webp` | 548980 | `cf138a458b41af2fa177598dcc07e2f4cc13f1a2e4bc67afa6374735e3945a0b` |
| `outfits/textures/T_Peasant_Normal.webp` | 754750 | `5770ba0c6f3fa453585b8b8c5c4f657a4849473192642a655a1fdefdb65341b3` |
| `outfits/textures/T_Peasant_ORM.webp` | 503870 | `476bd6b2eca103822b107d709d21e15582420e5698be28768df272583925dca4` |
| `outfits/textures/T_Ranger_BaseColor.webp` | 709160 | `b27422bf14d2e629e22be2ac37c793546181a64e591ab383ce9ab5f267b8bf3f` |
| `outfits/textures/T_Ranger_Normal.webp` | 833634 | `6dca9f67c05644215b22bc7ad14ba5727487b73ef0f706b7418c233ed75879dc` |
| `outfits/textures/T_Ranger_ORM.webp` | 685232 | `aaa2561cdaee1b15b4598f0aca37490eba9d3c9477085435ee3f276978c7556f` |
| `outfits/textures/T_Regular_Female_Dark_BaseColor.webp` | 401858 | `20fdc337eb10eff5b9b3efe4fee3bd220e06a52b02bdcf54ccdf8f84affed0e5` |
| `outfits/textures/T_Regular_Female_Normal.webp` | 651912 | `a9e6b314a0abc53836994e5d82f599080edceafd0f87bf3c0558fedda3cef16e` |
| `outfits/textures/T_Regular_Female_Roughness.webp` | 518684 | `22d185d5ff44d0ab8cf0c3151181c91d764aafe5432a542347cb823675614b91` |
| `outfits/textures/T_Regular_Male_Dark_BaseColor.webp` | 392590 | `870c066328550b268b10cd155c9c4ba3a7c0d5d482ef0bbf978843499a631bb6` |
| `outfits/textures/T_Regular_Male_Normal.webp` | 683466 | `a7bc7720bb0afae2f6382214956978695f0ddfd9d63f2d6d3bf0b5b1339f75c8` |
| `outfits/textures/T_Regular_Male_Roughness.webp` | 497542 | `40aac91808fc54c252d9dc5594a4a83b7c620ab233365803b03abd459f90268e` |
