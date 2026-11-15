# Personagens animados da Quaternius (CC0): subconjunto processado

Pacotes grátis da Quaternius (Modular Character Outfits: Fantasy, Universal Base Characters e Universal Animation Library), licença **CC0 1.0**
(domínio público; cópias em `License_*.txt`). Origem, SHA-256 dos originais e dos arquivos daqui, transformações e tamanho:
`docs/arte/MANIFESTO_LICENCAS.md`, seção 7.1. Os pacotes originais ficam FORA do Git; o jogo roda sem eles.

- `outfits/`: as 4 roupas (Peasant e Ranger, masculina e feminina) em peças com os nomes originais: tronco e braços (`*_Body_Arms`), pernas, botas
  e, no Ranger, os extras (capuz, ombreira, braceleira, dois cintos).
- `base/`: cabeça e olhos dos dois corpos-base (o corpo nu fica de fora: ele atravessa a roupa).
- `hair/`: 6 cabelos (um deles é a barba) e 2 sobrancelhas, presos ao osso da cabeça.
- `animations/`: 6 animações (idle, walk, jog, conversa, interagir e pegar na mesa) sobre o mesmo esqueleto.
- `*/textures/`: WebP sem perdas de até 1024 px, referenciados por caminho relativo e importados com compressão de VRAM (S3TC) e mipmaps; os
  `.import` versionados guardam essas configurações (e a geração de LOD das malhas). Todo arquivo de modelo traz o MESMO esqueleto de 65 ossos.

Para regenerar a partir dos zips originais: `tools/assets/process_quaternius <fantasy.zip> <ubc.zip> <ual.zip>` e depois
`godot --headless --path . --import`. O catálogo de dados é `data/presentation/character_catalog.json`; o teste é `tests/unit/test_character_assets.gd`.
