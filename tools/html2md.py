"""Convert space_age_plus_MASTER.html into a set of Markdown files.

Usage: python3 -I html2md.py <input.html> <output_dir>
"""
import html
import os
import re
import sys
from html.parser import HTMLParser

VOID = {"br", "meta", "img", "hr", "input", "link"}


class Node:
    def __init__(self, tag, attrs, parent=None):
        self.tag = tag
        self.attrs = dict(attrs)
        self.children = []
        self.parent = parent

    @property
    def classes(self):
        return self.attrs.get("class", "").split()

    def has(self, cls):
        return cls in self.classes

    def elements(self):
        return [c for c in self.children if isinstance(c, Node)]


class Builder(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.root = Node("root", [])
        self.cur = self.root

    def handle_starttag(self, tag, attrs):
        node = Node(tag, attrs, self.cur)
        self.cur.children.append(node)
        if tag not in VOID:
            self.cur = node

    def handle_endtag(self, tag):
        n = self.cur
        while n is not self.root and n.tag != tag:
            n = n.parent
        if n is not self.root:
            self.cur = n.parent

    def handle_data(self, data):
        self.cur.children.append(data)


def find(node, pred):
    out = []
    for c in node.elements():
        if pred(c):
            out.append(c)
        out.extend(find(c, pred))
    return out


def inline(node):
    """Render inline content of a node to a single line of Markdown."""
    parts = []
    for c in node.children:
        if isinstance(c, str):
            parts.append(re.sub(r"\s+", " ", c))
        elif c.tag in ("strong", "b"):
            t = inline(c).strip()
            parts.append(f"**{t}**" if t else "")
        elif c.tag in ("em", "i"):
            t = inline(c).strip()
            parts.append(f"*{t}*" if t else "")
        elif c.tag == "br":
            parts.append("<br>")
        elif c.has("pill"):
            parts.append(f" `{inline(c).strip()}` ")
        else:
            parts.append(" " + inline(c) + " ")
    return re.sub(r" {2,}", " ", "".join(parts)).strip()


def table(node):
    rows = []
    for tr in find(node, lambda n: n.tag == "tr"):
        cells = [inline(td).replace("|", "\\|") for td in tr.elements() if td.tag in ("td", "th")]
        rows.append(cells)
    if not rows:
        return ""
    width = max(len(r) for r in rows)
    rows = [r + [""] * (width - len(r)) for r in rows]
    lines = ["| " + " | ".join(rows[0]) + " |", "|" + "---|" * width]
    lines += ["| " + " | ".join(r) + " |" for r in rows[1:]]
    return "\n".join(lines)


def quote(text):
    return "\n".join("> " + l if l else ">" for l in text.split("\n"))


def block(node, depth):
    """Render block content. Returns a list of Markdown blocks."""
    out = []
    pending_inline = []

    def flush():
        if pending_inline:
            text = re.sub(r" {2,}", " ", " ".join(pending_inline)).strip()
            if text:
                out.append(text)
            pending_inline.clear()

    for c in node.children:
        if isinstance(c, str):
            if c.strip():
                pending_inline.append(re.sub(r"\s+", " ", c).strip())
            continue
        if c.tag in ("button", "script", "style") or c.has("sub-nav") or c.has("top-nav"):
            continue
        if c.tag in ("strong", "b", "em", "i", "span", "a") or c.has("pill"):
            tmp = Node("span", [])
            tmp.children = [c]
            pending_inline.append(inline(tmp))
            continue
        flush()
        if c.tag == "h2":
            out.append("#" * (depth + 1) + " " + inline(c))
        elif c.tag == "h3":
            out.append("#" * (depth + 2) + " " + inline(c))
        elif c.has("sl"):
            out.append("#" * (depth + 2) + " " + inline(c))
        elif c.tag == "table":
            out.append(table(c))
        elif c.tag == "ul":
            out.append("\n".join("- " + inline(li) for li in c.elements() if li.tag == "li"))
        elif c.tag == "ol":
            out.append("\n".join(f"{i}. " + inline(li)
                                 for i, li in enumerate((x for x in c.elements() if x.tag == "li"), 1)))
        elif c.has("diary"):
            label = next((x for x in c.elements() if x.has("dl")), None)
            body = Node("div", [])
            body.children = [x for x in c.children if x is not label]
            text = inline(body)
            out.append(quote((f"**{inline(label)}**\n\n" if label else "") + text))
        elif c.has("stp") or c.has("step"):
            num = next(iter(find(c, lambda n: n.has("sn"))), None)
            title = next(iter(find(c, lambda n: n.has("st"))), None)
            desc = next(iter(find(c, lambda n: n.has("sd"))), None)
            n = inline(num) if num else "-"
            line = f"{n}. **{inline(title)}**" if title else f"{n}."
            if desc:
                line += " — " + inline(desc)
            out.append(line)
        elif c.has("note") or c.has("good") or c.has("info"):
            kind = {"note": "Важно", "good": "Итог", "info": "Примечание"}
            k = next(kind[x] for x in ("note", "good", "info") if c.has(x))
            out.append(quote(f"**{k}:** " + inline(c)))
        elif c.has("open"):
            code = next((x for x in c.elements() if x.has("on")), None)
            rest = Node("div", [])
            rest.children = [x for x in c.children if x is not code]
            out.append(f"- **{inline(code)}** {inline(rest)}" if code else "- " + inline(c))
        elif c.has("divider"):
            out.append("---")
        elif c.tag in ("p",) or c.has("sub"):
            out.append(inline(c))
        else:
            out.extend(block(c, depth))
    flush()
    # Merge consecutive numbered step lines into one list block.
    merged = []
    for b in out:
        if merged and re.match(r"^\d+\. \*\*", b) and re.match(r"^\d+\. \*\*", merged[-1].split("\n")[-1]):
            merged[-1] += "\n" + b
        else:
            merged.append(b)
    return [b for b in merged if b.strip()]


def main(src, out_dir):
    b = Builder()
    b.feed(open(src, encoding="utf-8").read())
    body = next(iter(find(b.root, lambda n: n.tag == "body")))
    nav = find(body, lambda n: n.has("top-btn"))
    tops = []
    for btn in nav:
        m = re.search(r"S\('([^']+)'", btn.attrs.get("onclick", ""))
        tops.append((m.group(1), inline(btn)))
    pages = {p.attrs["id"]: p for p in find(body, lambda n: n.has("page") and "id" in n.attrs)}

    os.makedirs(out_dir, exist_ok=True)
    index = ["# Space Age+ — Мастер документ v0.3", "",
             "Markdown-версия [HTML-документа](../space_age_plus_MASTER.html). "
             "Разделы совпадают с вкладками оригинала.", ""]
    for i, (pid, title) in enumerate(tops):
        page = pages[pid]
        subs = {}
        for btn in find(page, lambda n: n.has("sub-btn")):
            m = re.search(r"T\('([^']+)'", btn.attrs.get("onclick", ""))
            if m:
                subs[m.group(1)] = inline(btn)
        lines = [f"# {title}", ""]
        if subs:
            lines.append(" · ".join(f"[{name}](#{anchor(name)})" for name in subs.values()))
            lines.append("")
            for sid, sname in subs.items():
                lines.append(f"## {sname}")
                lines.append("")
                for blk in block(pages[sid], 2):
                    lines += [blk, ""]
        else:
            for blk in block(page, 1):
                lines += [blk, ""]
        fname = f"{i:02d}-{pid}.md"
        text = "\n".join(lines)
        text = re.sub(r"(\*\*space-age-plus-[\w-]+\*\* — [^\n]+)\n\n(`[^`]+`)", r"- \1 — \2", text)
        text = re.sub(r"\n\n(?=- \*\*space-age-plus-)", "\n", text)
        lines = [text]
        open(os.path.join(out_dir, fname), "w", encoding="utf-8").write("\n".join(lines).rstrip() + "\n")
        index.append(f"{i + 1}. [{title}]({fname})")
    open(os.path.join(out_dir, "README.md"), "w", encoding="utf-8").write("\n".join(index) + "\n")


def anchor(text):
    a = text.strip().lower()
    a = re.sub(r"[^\w\- ]", "", a)
    return a.replace(" ", "-")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
