#!/usr/bin/env python3
"""Собирает docs/balance.md: все цифры баланса Space Age+ в одном месте.

Источники:
  * script-output/sap-balance.json — выгрузка прототипов из игры (пишет тестовый мод на тике 12,
    поэтому сначала запустите tools/run-tests.sh);
  * константы в начале scripts/*.lua модулей (local NAME = число -- комментарий).

Использование: FACTORIO=/путь/к/factorio tools/balance.py
"""
import glob
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
QUALITY_SUFFIX = re.compile(r"-sap-(uncommon|rare|epic|legendary)$")
PACK_SHORT = {
    "automation-science-pack": "red", "logistic-science-pack": "green", "military-science-pack": "military",
    "chemical-science-pack": "blue", "production-science-pack": "purple", "utility-science-pack": "yellow",
    "space-science-pack": "space", "metallurgic-science-pack": "metallurgic",
    "electromagnetic-science-pack": "electromagnetic", "agricultural-science-pack": "agricultural",
    "cryogenic-science-pack": "cryogenic", "promethium-science-pack": "promethium",
}


def load_names():
    """Русские названия из локалей модулей."""
    names = {}
    for path in glob.glob(os.path.join(ROOT, "space-age-plus-*", "locale", "ru", "*.cfg")):
        section = None
        with open(path, encoding="utf-8") as f:
            for line in f:
                line = line.rstrip("\n")
                if line.startswith("["):
                    section = line.strip("[]")
                elif "=" in line and section in ("technology-name", "entity-name", "item-name", "recipe-name",
                                                   "mod-setting-name", "fluid-name"):
                    key, value = line.split("=", 1)
                    names.setdefault(key, value)
    return names


def short(pack):
    if pack in PACK_SHORT:
        return PACK_SHORT[pack]
    return pack.replace("sap-", "").replace("-science-pack", "")


def fmt_num(x):
    if x is None:
        return ""
    if isinstance(x, float):
        return f"{x:g}" if abs(x) >= 0.01 else f"{x:.3g}"
    return str(x)


def items(list_):
    return ", ".join(f"{fmt_num(i.get('amount'))} {i['name']}" for i in list_)


def constants():
    """Константы из scripts/*.lua: [(модуль, файл, имя, значение, комментарий)]."""
    rx = re.compile(r"^local ([A-Z][A-Z0-9_]*) = ([-0-9.*/ ()]+?)\s*(?:--\s*(.*))?$")
    out = []
    for path in sorted(glob.glob(os.path.join(ROOT, "space-age-plus-*", "scripts", "*.lua"))):
        module = path.split(os.sep)[-3].replace("space-age-plus-", "")
        prev_comment = ""
        with open(path, encoding="utf-8") as f:
            for line in f:
                line = line.rstrip("\n")
                m = rx.match(line)
                if m:
                    name, expr, comment = m.groups()
                    try:
                        value = eval(expr, {"__builtins__": {}})  # только числа и арифметика
                    except Exception:
                        value = expr
                    out.append((module, os.path.basename(path), name, value, comment or prev_comment))
                    prev_comment = ""
                elif line.startswith("--"):
                    prev_comment = line.lstrip("- ").strip()
                else:
                    prev_comment = ""
    return out


def main():
    factorio = os.environ.get("FACTORIO")
    if not factorio:
        sys.exit("FACTORIO не задан")
    data = json.load(open(os.path.join(factorio, "script-output", "sap-balance.json"), encoding="utf-8"))
    names = load_names()

    def title(name):
        return f"{names[name]} (`{name}`)" if name in names else f"`{name}`"

    out = ["# Баланс Space Age+", "",
           "Все цифры в одном месте. Файл собирается автоматически (`tools/balance.py`) из прототипов игры",
           "и констант в скриптах — правьте исходники, затем пересоберите. Версии технологий по качеству",
           "(`-sap-uncommon` … `-sap-legendary`) стоят дороже обычной и в таблицу не включены.", ""]

    out += ["## Технологии", "", "| Технология | Стоимость | Время | Колбы | Требования |", "|---|---|---|---|---|"]
    for t in data["technologies"]:
        if QUALITY_SUFFIX.search(t["name"]):
            continue
        if t.get("trigger"):
            cost = f"триггер: {t['trigger']}"
        else:
            cost = t.get("formula") or fmt_num(t.get("count"))
        out.append(f"| {title(t['name'])} | {cost} | {fmt_num(t.get('time')) if not t.get('trigger') else ''} | "
                   f"{', '.join(short(p) for p in t.get('packs', [])) if not t.get('trigger') else ''} | "
                   f"{', '.join(t.get('prerequisites', []))} |")

    out += ["", "## Рецепты", "", "| Рецепт | Время, с | Ингредиенты | Результат | Условия |", "|---|---|---|---|---|"]
    for r in data["recipes"]:
        out.append(f"| {title(r['name'])} | {fmt_num(r.get('energy'))} | {items(r.get('ingredients', []))} | "
                   f"{items(r.get('products', []))} | {', '.join(r.get('conditions', []))} |")

    out += ["", "## Существа", "", "| Существо | Здоровье | Скорость | Дальность | Перезарядка, тиков | Урон за удар |",
            "|---|---|---|---|---|---|"]
    for u in data["units"]:
        out.append(f"| {title(u['name'])} | {fmt_num(u.get('health'))} | {fmt_num(u.get('speed'))} | "
                   f"{fmt_num(u.get('range'))} | {fmt_num(u.get('cooldown'))} | {fmt_num(u.get('damage'))} |")

    out += ["", "## Гнёзда и турели", "", "| Объект | Тип | Здоровье |", "|---|---|---|"]
    for s in data["spawners"]:
        out.append(f"| {title(s['name'])} | {s['type']} | {fmt_num(s.get('health'))} |")

    out += ["", "## Постройки", "", "| Постройка | Тип | Здоровье | Потребление, кВт | Скорость |", "|---|---|---|---|---|"]
    for b in data["buildings"]:
        out.append(f"| {title(b['name'])} | {b['type']} | {fmt_num(b.get('health'))} | "
                   f"{fmt_num(round(b['energy'] * 60 / 1000, 1)) if b.get('energy') else ''} | {fmt_num(b.get('speed'))} |")

    out += ["", "## Настройки", "", "| Настройка | Тип | По умолчанию | Диапазон / варианты |", "|---|---|---|---|"]
    for s in data["settings"]:
        allowed = ", ".join(s["allowed"]) if s.get("allowed") else (
            f"{fmt_num(s.get('min'))} … {fmt_num(s.get('max'))}" if s.get("min") is not None else "")
        out.append(f"| {title(s['name'])} | {s['type']} | {s.get('default')} | {allowed} |")

    out += ["", "## Константы в скриптах", "",
            "Значения в начале `scripts/*.lua` каждого модуля (тики: 60 = 1 секунда).", ""]
    current = None
    for module, file, name, value, comment in constants():
        if module != current:
            out += ["", f"### {module}", "", "| Файл | Константа | Значение | Пояснение |", "|---|---|---|---|"]
            current = module
        out.append(f"| {file} | `{name}` | {fmt_num(value)} | {comment} |")

    path = os.path.join(ROOT, "docs", "balance.md")
    with open(path, "w", encoding="utf-8") as f:
        f.write("\n".join(out) + "\n")
    print(f"written {path}")


if __name__ == "__main__":
    main()
