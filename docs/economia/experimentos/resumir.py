# Resume as saídas do medidor numa tabela Markdown, uma linha por (cenário, ref), juntando as sementes. Só biblioteca padrão.
# Uso: python3 resumir.py <pasta-data-do-jogo> <pasta-saida> [cenario ...]   (arquivos: <cenario>__<ref>__s<semente>.csv)
import collections
import glob
import os
import sys

sys.dont_write_bytecode = True  # não deixar __pycache__ ao lado dos scripts
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import viagem  # noqa: E402


def read_rows(path):
    with open(path, encoding="utf-8") as handle:
        lines = [x.rstrip("\n") for x in handle if not x.startswith("#") and x.strip() and "," in x]
    header = lines[0].split(",")
    return [dict(zip(header, (int(c) for c in line.split(",")))) for line in lines[1:] if line.split(",")[0].isdigit()]


def span(values):
    low, high = min(values), max(values)
    return str(low) if low == high else "%d-%d" % (low, high)


def main():
    data_dir, out_dir = sys.argv[1], sys.argv[2]
    wanted = sys.argv[3:]
    groups = collections.defaultdict(list)
    for path in sorted(glob.glob(os.path.join(out_dir, "*__s*.csv"))):
        name, ref, seed = os.path.basename(path)[:-4].split("__")
        if not wanted or name in wanted:
            groups[(name, ref)].append((seed, path))
    print("| cenário | ref | sementes | vivos d7 / d14 / d30 | locais rodando d30 (de 14) | dinheiro d30: NPC vivo / NPC morto / locais / mercados | maior razão de preço entre povoados | melhor viagem (lucro, rota) | conferência |")
    print("|---|---|---|---|---|---|---|---|---|")
    for (name, ref), items in sorted(groups.items()):
        alive, running, money, ratios, trips, ok = ({7: [], 14: [], 30: []}, [], [[], [], [], []], [], [], True)
        for _seed, path in items:
            rows = read_rows(path)
            by_day = {r["day"]: r for r in rows}
            last = rows[-1]
            for day in alive:
                alive[day].append(by_day[day]["alive"] if day in by_day else -1)
            running.append(last["sites_running"])
            for index, key in enumerate(("money_npc_alive", "money_npc_dead", "money_site", "money_market")):
                money[index].append(last[key])
            worst = max(((last["pmax_" + g[5:]] / max(1, last["pmin_" + g[5:]]), g[5:]) for g in last if g.startswith("pmax_")))
            ratios.append("%.1fx %s" % worst)
            ok = ok and all(r["problems"] == 0 and r["money_ok"] == 1 and r["goods_ok"] == 1 for r in rows)
            err_path = path[:-4] + ".err"
            if os.path.exists(err_path) and "ERROR:" in open(err_path, encoding="utf-8", errors="replace").read():
                ok = False
            try:
                markets, money_by = viagem.read_markets(path)
                trip = viagem.best_trip(data_dir, markets, money_by) if markets else None
                trips.append(trip)
            except OSError:
                trips.append(None)
        profits = [t["profit"] if t else 0 for t in trips]
        first = next((t for t in trips if t), None)
        route = "%s%s→%s (%d un.)" % (first["good"], first["from"], first["to"], first["n"]) if first else "nenhuma"
        mean = [sum(m) // len(m) for m in money]
        print("| %s | %s | %d | %s / %s / %s | %s | %d / %d / %d / %d | %s | %s ($%s, %s) | %s |" % (
            name, ref, len(items), span(alive[7]), span(alive[14]), span(alive[30]), span(running), mean[0], mean[1], mean[2], mean[3],
            ratios[0], span(profits), "-" if not first else "%d" % first["profit"], route, "ok" if ok else "FALHOU"))


main()
