class_name TradeRules
extends RefCounted
## A interface das regras de comércio da `economy` (LW-091; docs/modules/economy.md, seção 5; DEC-049): tarifa, proibição e licença. A economia DEFINE a interface e usa a implementação neutra (`NeutralTradeRules`);
## na Fase 4 o módulo `politics` entrega a sua. A regra chega PRONTA pelo construtor da economia (`EconomyDefinitions.trade_rules`): a economia nunca importa `politics` (é a única inversão de dependência permitida).
## A classe base já é a regra neutra; uma regra nova sobrescreve `peek_terms`.


## O que vale para `good_id` no mercado `market_id` quando `actor_id` negocia. A neutra devolve tudo livre.
func peek_terms(_good_id: String, _market_id: int, _actor_id: int) -> TradeTerms:
	return TradeTerms.new()
