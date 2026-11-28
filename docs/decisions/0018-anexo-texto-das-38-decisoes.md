# Texto das 38 decisões de design (cópia fiel do dossiê de 28/11/2026)

- **Status:** cópia do texto entregue por Arthur em 28/11/2026, **guardada como registro**. Não é DEC, não autoriza implementação e não altera GDD, roadmap, contrato nem código. As decisões de escopo do v0.1 estão em `0018-integracao-das-38-decisoes.md`.
- **Origem do texto:** o dossiê "LivingWorld — Dossiê de decisões 01–38 para avaliação pelo Maestro", consolidado em 28/11/2026. Entram aqui o cabeçalho e as seções A, B, C e E. As seções D e F do dossiê (pedido de análise ao Maestro e prompt inicial) não são decisões e não foram copiadas.
- **Como ler:** a letra entre parênteses depois do título (A ou B) é a opção escolhida na rodada de planejamento.

## Cabeçalho do dossiê

LivingWorld — Dossiê de decisões 01–38 para avaliação pelo Maestro

Data de consolidação: 28/11/2026

Status: decisões de design aprovadas pelo idealizador; não são autorização de implementação nem alteração automática do GDD/roadmap.

Objetivo: permitir ao Maestro comparar a visão aprovada com o estado real do repositório e do planejamento, identificar incompatibilidades e propor uma implementação incremental e verificável.

Regra de governança: não editar o roadmap/GDD oficial, não abrir PRs de funcionalidades, não implantar mudanças ou alterar produção com base neste documento sem apresentação de análise de impacto e aprovação expressa. Preservar o andamento do plano oficial e evitar custos extras não autorizados.

## A. Decisões aprovadas — Fundamentos e sistemas (01–16)

**01 — Origens e classes (A).** Personagem sem classes fixas; origem é narrativa, sem atributos ou profissões permanentemente bloqueados pela escolha inicial.

**02 — Progressão híbrida (B).** Habilidades e profissões evoluem pelo uso; atributos gerais recebem pontos limitados em marcos de progressão.

**03 — Árvores pequenas de talentos (B).** Árvores simples e expansíveis com escolhas em marcos de proficiência; nada de ramificações extensas no primeiro protótipo.

**04 — Profissões livres (B).** Jogador combina profissões sem turnos de trabalho obrigatórios; cada profissão evolui pela prática e possui patamares (Aprendiz, Profissional, Mestre) para novas técnicas, receitas e oportunidades.

**05 — Combate em tempo real (B).** Ataques leves e fortes, bloqueio, esquiva que consome estamina, disparos de armas à distância e reações a acertos. Combos avançados e aparadas perfeitas ficam para expansões; a seleção/autoataque foi refinada na decisão 17.

**06 — Magia inicial (B).** Três escolas — Fogo, Gelo e Cura — com cerca de 1–2 magias por escola, mana, proficiência por uso e talentos simples. Atenção: proposta que contradiz a exclusão anterior de magia do escopo oficial v0.1; exige análise e aprovação de mudança de escopo.

**07 — Categorias de equipamento (B).** Espadas, machados, arcos, cajados e escudos; armaduras leves, médias e pesadas com características distintas, sem restrições rígidas por classe.

**08 — Criaturas ativas no mundo (B).** Animais selvagens podem fugir ou atacar; humanoides patrulham e perseguem; criaturas fantásticas possuem ataques característicos. Drops e materiais alimentam crafting e economia. Ecologia elaborada e chefes complexos ficam para depois.

**09 — Coleta pelo jogador (B).** Mineração, corte, coleta e afins usam ferramentas e proficiência; recursos do ambiente são limitados e regeneram, persistindo no mundo e integrando inventário, economia e fabricação.

**10 — Fabricação pelo jogador (B).** Receitas, materiais reais, estações apropriadas, proficiência e qualidade variável; integração com equipamentos, contratos e economia. Ver decisões 24–27.

**11 — Alquimia (B).** Ervas e ingredientes de criaturas, receitas e estação própria; poções de vida, mana e proteção elemental; proficiência e pequenas variações de potência/qualidade. Sistemas avançados de combinação, venenos e raridades ficam para depois.

**12 — Encantamento (B).** Profissão evolutiva com receitas, ingredientes mágicos e estação própria; potência influenciada pela proficiência; um efeito por item no v0.1. Encantamentos múltiplos/complexos ficam para depois.

**13 — Qualidade e raridade separadas (B).** Qualidade: Comum / Bem-feito / Excelente. Raridade: Comum / Raro. Atributos dependem do tipo de item, material, qualidade e encantamento. Categorias épicas/lendárias depois.

**14 — Exploração e trabalhos orgânicos (B).** Contratos e oportunidades surgem de demandas econômicas, ameaças e descobertas; recompensas flexíveis (dinheiro, itens e progressão), pequenas consequências locais persistentes. Grandes histórias e masmorras complexas depois.

**15 — Facções e carreira militar voluntária (B).** Reputações por facção, alianças/rivalidades simples, ingresso voluntário na carreira militar com patentes, missões e oportunidades. Sem escalas obrigatórias. Guerras em larga escala e política profunda depois.

**16 — Estado compartilhado do mundo (B).** Coleta, fabricação, comércio, contratos, combate, progressão, facções e reações dos NPCs consultam e modificam um mesmo estado persistente, com consequências simples mas verificáveis. Reações sistêmicas avançadas depois.

## B. Refinamentos aprovados — Experiência e arquitetura (17–38)

**17 — Combate híbrido (B).** Primeiro clique esquerdo seleciona o alvo; segundo clique ou comando inicia autoataques básicos em intervalos, interrompíveis. Habilidades ativas são acionadas manualmente.

**18 — Controles iniciais (A).** Teclas 1–4 para habilidades; Espaço para esquiva com estamina; segurar botão direito para bloqueio; clique esquerdo para seleção e ataque; rolagem do mouse ajusta zoom. Remapeamento futuramente.

**19 — Seis atributos (B).** Força, Destreza, Constituição, Inteligência, Sabedoria e Carisma, distintos das proficiências por uso.

**20 — Pontos de atributos por marcos gerais (B).** Marcos de evolução ampla do personagem, alcançáveis por atividades variadas, concedem pontos limitados para distribuir entre os seis atributos, sem obrigar nível global tradicional. Valores, limites e frequência pendentes de balanceamento.

**21 — Derrota sem perda de bens (A).** Com vida zero, personagem reaparece no último local seguro; mantém equipamentos, dinheiro e recursos; sofre apenas penalidade temporária leve de recuperação/fraqueza. Sem cadáver recuperável ou destruição de itens.

**22 — Durabilidade e reparos (B).** Armas, armaduras e ferramentas se desgastam. Durabilidade zero impede uso, mas não destrói o item. Reparos com materiais, estação e proficiência, ou serviço pago; qualidade pode influenciar resistência ao desgaste.

**23 — Inventário e carga (B).** Peso simplificado por item, pilhas de itens iguais, limite de carga, armazenamento persistente e transporte integrado à economia. Sem penalidades graduais complicadas por sobrecarga. Carroças e animais de carga controláveis depois.

**24 — Catálogo inicial compacto (A).** Um exemplar funcional por categoria de arma aprovada, conjuntos básicos de armaduras leve/média/pesada, poucos recursos e receitas suficientes para testar sistemas aprovados; dois efeitos iniciais de encantamento. Variações de atributos, qualidade e raridade não precisam de modelos 3D individuais.

**25 — Aprendizado contextual de receitas (B).** Receitas simples iniciais; novas receitas por marcos profissionais, NPCs instrutores, livros/pergaminhos, exploração e contratos, com proficiência mínima quando necessário. Poucos exemplos de cada mecanismo no v0.1.

**26 — Produção garantida (A).** Conhecendo receita e cumprindo materiais, estação e requisitos de proficiência, fabricação/alquimia/encantamento têm sucesso garantido; nenhuma perda aleatória de materiais por falha. Qualidade/potência variam com proficiência. Fabricação arriscada só em expansões.

**27 — Produção curta e visual (B).** Tempo curto por receita, animação temática e barra de progresso; sem turnos de trabalho. Estado em andamento, consumo e entrega protegidos contra duplicação ou perda nas interrupções/salvamentos. Filas e fabricação em lotes depois.

**28 — Diálogos contextuais simples (B).** Falas com personalidade básica, serviços relacionados à profissão, respostas influenciadas pela reputação e pelas necessidades locais, opções funcionais de interação e consequências persistentes. Sem dependência de IA generativa; diálogos complexos depois.

**29 — Diário e mapa contextual (B).** Contratos, objetivos e recompensas organizados; objetivo opcional acompanhado na interface; destinos conhecidos marcados; locais desconhecidos exigem exploração ou informação; descoberta e progresso persistem.

**30 — Transporte entre cidades conhecidas (B).** Exploração livre e serviço contratado de passageiros entre locais previamente descobertos, com tarifa, passagem de tempo no mundo, simulação persistente e limites de bagagem. Montarias e veículos controláveis depois.

**31 — Sobrevivência leve (B).** Fome e fadiga crescem gradualmente; alimentação e descanso recuperam o personagem; efeitos temporários moderados, sem morte por fome. Estalagens, camas e alimentos conectados à economia; estado persistente. Sobrevivência avançada depois.

**32 — Redistribuição de build (B).** Pontos de atributos e talentos podem ser redistribuídos em locais seguros mediante custo monetário moderado. Proficiências já aprendidas não são removidas ou transferidas; nenhum investimento permanentemente irreversível. Presets de builds depois.

**33 — Moradia pessoal simples (B).** Iniciar com serviços públicos; possibilidade de adquirir uma casa simples, com baús persistentes, cama para descanso e uma estação básica de trabalho, com custos reais. Construção livre, propriedades múltiplas e gestão de negócios depois.

**34 — Ciclo temporal e clima leve (B).** Manhã/tarde/noite/madrugada contínuas; rotinas/serviços de NPCs variam com horário; iluminação e atmosfera contextuais; clima simples (incluindo chuva), com efeitos leves sobre visibilidade e certas atividades; persistência. Sem condições punitivas; estações e clima profundo depois.

**35 — Mundo pausado com jogo fechado (A).** Enquanto o jogo estiver aberto, simular NPCs, economia, recursos e tempo inclusive fora de câmera. Ao fechar, não avançar relógio/sistemas em tempo real; ao reabrir, restaurar o estado salvo. Nenhum contrato expira por ausência offline.

**36 — Salvamento robusto (B).** Salvamento manual quando seguro; autosave periódico e por eventos; cópias recentes recuperáveis; persistência consistente/atômica de inventário, moeda, transações, economia, NPCs e propriedades; carregar o último estado íntegro; sem evolução offline. Nuvem e histórico extenso depois.

**37 — Contratos normais e urgentes (B).** Contratos normais sem prazo rígido; contratos urgentes voluntários com prazos em tempo do jogo visíveis antes de aceitar e recompensas potencialmente maiores. Desistência possível; inadimplemento urgente pode causar perda leve de reputação, sem multas automáticas, prisão ou confisco. Prazos não avançam quando o jogo está fechado.

**38 — Mercado com oferta e demanda moderadas (B).** Preço-base ajustado em faixas limitadas pela oferta, demanda/estoque local e qualidade; comerciantes lidam com produtos pertinentes à profissão; interface mostra variações de demanda; proteger contra exploração de preço e inconsistências de moeda/itens; transações persistentes.

## C. Limites de escopo e cuidados de integração

1. **Não considerar tudo aprovado para codificação imediata.** Estas 38 decisões descrevem a visão de jogo desejada. A implementação em v0.1 depende da verificação do roadmap e do estado do código, com aprovação específica.
2. **Comparar explicitamente com as decisões técnicas existentes.** Em especial, houve exclusão anterior de magia e escopo original menor para coleta/crafting/alquimia/encantamento; não sobrepor nem apagar decisões anteriores sem sinalizar conflito e obter autorização.
3. **Preservar a base atual.** O Maestro deve manter as fases, marcos, validações e trabalho em andamento, propondo replanejamento em etapas, sem atalhos que provoquem regressões.
4. **Progressão realista.** Identificar dependências e separar: (i) infraestrutura e testes; (ii) primeiro ciclo vertical completo; (iii) incrementos de conteúdo; (iv) expansões adiadas.
5. **Sem custos adicionais sem aprovação.** Não incluir serviços pagos, APIs de IA generativa, pacotes de assets, CI pago ou gastos com agentes sem consulta prévia; preferir ferramentas/ativos permitidos no projeto.
6. **Single-player primeiro.** A simulação offline fica desativada; persistência determinística, recuperabilidade e ausência de duplicação de moeda/itens são condições centrais.
7. **Não adicionar turnos de trabalho obrigatórios.** Profissões, trabalhos e missões são livres; prazos só para contratos urgentes voluntários.
8. **Compatibilizar mecânicas entre si.** Limite de carga com transporte; geração/consumo de recursos com economia; receitas e qualidades com preço; casa e baús com persistência; XP/proficiência com talentos; morte com penalidades; horários/clima com NPCs e contratos.

## E. Critério de validação sugerido — ciclo vertical completo

Um jogador inicia sem classe fixa, encontra NPCs contextuais, descobre um pedido, coleta recursos persistentes com ferramenta e limite de carga, aprende uma receita, fabrica um item em oficina com animação e qualidade, armazena/transporta/vende a mercadoria com preço de mercado e moeda sincronizados, obtém ganhos profissionais/reputação, descansa e salva, e volta ao mesmo estado depois de fechar e reabrir o jogo. O cenário de teste deve verificar também interrupção de fabricação e de comércio sem duplicação de recursos.

Importante: esse roteiro é um teste de integração proposto, não uma obrigação de implementar todos os 38 tópicos simultaneamente.
