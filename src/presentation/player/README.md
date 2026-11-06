Corpo do jogador (módulo `presentation`; contrato em `docs/modules/presentation.md`).

Implementado: `player_body.gd` (`PlayerBody`, LW-045: um `CharacterBody3D` com uma cápsula provisória laranja que anda, corre e pula sobre o terreno, relativo ao giro da câmera; fica parado enquanto o chão sob ele não tem colisão) e, nele mesmo, os limites da LW-047: inclinação máxima caminhável de 40°, margem de 1 m até a borda do mapa e reposição sobre o chão se cair mais de 2 m abaixo do terreno. Física só na apresentação: nada daqui vai para a simulação. Ainda não existe o relato de posição (LW-048).
