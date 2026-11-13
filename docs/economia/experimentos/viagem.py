# Melhor viagem de um comerciante a partir do estado dos mercados no último dia (linhas `#market` do medidor). Só biblioteca padrão.
# Uso: python3 viagem.py <pasta-data-do-jogo> <saida-do-medidor.csv>   (a saída precisa ter sido gerada com --markets)
# O preço de tabela do mercado só depende do estoque pela razão factor(s)/factor(estoque atual); por isso o preço do degrau `s` é
# P(s) = P_agora * factor(s) / factor(estoque_agora), com P_agora = (ask + bid) / 2 lido da linha (a mesma conta do contrato, seção 4).
# Réplica das fórmulas de src/sim/economy/markets/price_math.gd (inteiros). Jogador: peso e dinheiro do tipo `player` em owner_kinds.json;
# caminhada a 4 m/s (player_body.gd, [HIP]); o dinheiro do mercado de destino limita a venda; o teto de compra é alvo * buy_cap_bp / 10000.
import json
import os
import sys

BASIS = 10000
SPREAD_DEN = 20000
WALK_MPS = 4.0


def load(data_dir, sub, name):
    with open(os.path.join(data_dir, sub, name), encoding="utf-8") as handle:
        return json.load(handle)


def ceil_div(a, b):
    return (a + b - 1) // b


def factor(target, stock, params):
    return min(max(BASIS * target // max(stock, 1), params["min_factor_bp"]), params["max_factor_bp"])


def price_at(p_now, base, target, stock_now, stock, params):
    floor_p = max(1, base * params["min_factor_bp"] // BASIS)
    ceil_p = max(floor_p, base * params["max_factor_bp"] // BASIS)
    raw = max(1, p_now * factor(target, stock, params) // factor(target, stock_now, params))
    return min(max(raw, floor_p), ceil_p)


def ask(p, spread):
    return p + ceil_div(p * spread, SPREAD_DEN)


def bid(p, spread):
    return max(1, p - ceil_div(p * spread, SPREAD_DEN))


def read_markets(path):
    markets, money = {}, {}
    with open(path, encoding="utf-8") as handle:
        for line in handle:
            cells = line.strip().split(",")
            if cells[0] == "#market_money":
                money[cells[1]] = int(cells[2])
            elif cells[0] == "#market":
                settlement, good = cells[1], cells[2]
                stock, target, _table, ask_now, bid_now = (int(x) for x in cells[3:8])
                markets.setdefault(settlement, {})[good] = {"stock": stock, "target": target, "p_now": (ask_now + bid_now) // 2}
    return markets, money


def best_trip(data_dir, markets, money):
    goods = {g["id"]: g for g in load(data_dir, "economy", "goods.json")}
    params = load(data_dir, "economy", "price_params.json")[0]
    kinds = {k["id"]: k for k in load(data_dir, "economy", "owner_kinds.json")}
    caps = {(t["settlement_id"], t["good_id"]): t["buy_cap_bp"] for t in load(data_dir, "economy", "market_targets.json")}
    routes = {frozenset((r["settlement_a_id"], r["settlement_b_id"])): r["length_m"] for r in load(data_dir, "world", "routes.json")}
    capacity, wallet, spread = kinds["player"]["weight_capacity"], kinds["player"]["initial_balance"], params["spread_bp"]
    best = None
    for src, src_goods in markets.items():
        for dst, dst_goods in markets.items():
            if src == dst or frozenset((src, dst)) not in routes:
                continue
            for good, s in src_goods.items():
                d = dst_goods[good]
                base, weight = goods[good]["base_value"], goods[good]["weight"]
                cap = d["target"] * caps.get((dst, good), 20000) // BASIS
                n_max = min(capacity // weight, s["stock"], max(0, cap - d["stock"]))
                cost = revenue = 0
                for n in range(1, n_max + 1):
                    cost += ask(price_at(s["p_now"], base, s["target"], s["stock"], s["stock"] - (n - 1), params), spread)
                    revenue += bid(price_at(d["p_now"], base, d["target"], d["stock"], d["stock"] + n, params), spread)
                    if cost > wallet or revenue > money.get(dst, 0):
                        break
                    if revenue - cost > (best["profit"] if best else 0):
                        minutes = round(routes[frozenset((src, dst))] / WALK_MPS / 60, 1)
                        best = {"profit": revenue - cost, "good": good, "n": n, "from": src[-1].upper(), "to": dst[-1].upper(), "cost": cost, "walk_min": minutes}
    return best


if __name__ == "__main__":
    markets_, money_ = read_markets(sys.argv[2])
    print(json.dumps(best_trip(sys.argv[1], markets_, money_) or {"profit": 0}, ensure_ascii=False))
