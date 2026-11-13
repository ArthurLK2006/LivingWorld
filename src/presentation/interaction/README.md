Módulo `presentation/interaction` (camada 7). Contrato em `docs/modules/presentation.md`.

Implementado (LW-050): `interaction_view.gd` (`InteractionView`: marcadores provisórios dos pontos de interesse, ponto próximo ao alcance, aviso "[E] Interagir", pedido de interação pela ponte e texto do resultado por 5 s). LW-106e: o mercado ao alcance (`peek_market_in_reach`) é o terceiro alvo da tecla, só sem ponto nem NPC ao alcance (aviso `ui.market.prompt` e sinal `market_requested`); `set_blocked` a cala enquanto a tela de mercado está aberta.
