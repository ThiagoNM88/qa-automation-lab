"""Relatório HTML independente e resumo do GitHub a partir do resultado real do Robot."""
import argparse
import base64
from html import escape
from html.parser import HTMLParser
import os
from pathlib import Path
from urllib.parse import unquote, urlparse
from xml.etree import ElementTree as ET


class Images(HTMLParser):
    def __init__(self):
        super().__init__()
        self.sources = []

    def handle_starttag(self, tag, attrs):
        if tag.lower() == "img":
            self.sources.extend(value for key, value in attrs if key == "src" and value)


def screenshot_data(test, folder):
    allowed = (folder / "browser" / "screenshot").resolve()
    seen = set()
    images = []
    mime = {".png": "image/png", ".jpg": "image/jpeg", ".jpeg": "image/jpeg", ".webp": "image/webp"}
    for msg in test.iter("msg"):
        if msg.get("html") != "true":
            continue
        parser = Images()
        parser.feed(msg.text or "")
        for src in parser.sources:
            parsed = urlparse(src)
            if parsed.scheme or parsed.netloc:
                continue
            path = (folder / unquote(parsed.path)).resolve()
            if not path.is_relative_to(allowed) or path.suffix.lower() not in mime or path in seen:
                continue
            if path.is_file():
                seen.add(path)
                encoded = base64.b64encode(path.read_bytes()).decode("ascii")
                images.append(f'<figure><img loading="lazy" alt="Captura ao final deste cenário" src="data:{mime[path.suffix.lower()]};base64,{encoded}"><figcaption>{escape(path.name)}</figcaption></figure>')
    return images


def build_report(source, destination):
    source, destination = Path(source), Path(destination)
    counts = {"PASS": 0, "FAIL": 0, "SKIP": 0}
    cards, failures = [], []
    screenshot_count = 0
    if source.is_file():
        root = ET.parse(source).getroot()
        for test in root.iter("test"):
            status = test.find("status")
            state = status.get("status", "UNKNOWN") if status is not None else "UNKNOWN"
            if state in counts:
                counts[state] += 1
            name = test.get("name", "Cenário sem nome")
            message = (status.text or "").strip() if status is not None else "Sem resultado registrado."
            if state == "FAIL":
                failures.append((name, message))
            steps = []
            for step in test.findall("kw"):
                result = step.find("status")
                step_state = result.get("status", "UNKNOWN") if result is not None else "UNKNOWN"
                steps.append(f'<li><b>{escape(step_state)}</b> · {escape(step.get("name", ""))}</li>')
            images = screenshot_data(test, source.parent)
            screenshot_count += len(images)
            documentation = test.findtext("doc", "")
            opened = " open" if state == "FAIL" else ""
            cards.append(f'<details class="{escape(state.lower())}"{opened}><summary><span>{escape(state)}</span> {escape(name)}</summary><p>{escape(documentation)}</p><pre>{escape(message)}</pre><ol>{"".join(steps)}</ol>{"".join(images) or "<p>Não há captura disponível para este cenário. Consulte os logs de preparação.</p>"}</details>')
    total = sum(counts.values())
    content = """<!doctype html><html lang="pt-BR"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Evidências dos testes</title><style>
    body{font:16px/1.5 Arial,sans-serif;background:#f4f6fa;color:#17243a;margin:0}main{max-width:1120px;margin:auto;padding:28px}h1{margin:0 0 8px}header{margin-bottom:24px}details{background:white;border:1px solid #cbd5e1;border-radius:10px;margin:14px 0;padding:18px}summary{cursor:pointer;font-weight:700}summary span{display:inline-block;margin-right:10px}.fail{border-left:5px solid #b42332}.fail summary span{color:#a51d2c}.pass{border-left:5px solid #257244}.pass summary span{color:#1d673b}pre{white-space:pre-wrap;overflow-wrap:anywhere;background:#f1f4f8;padding:12px;border-radius:6px}pre:empty{display:none}img{max-width:100%;height:auto;border:1px solid #cbd5e1;border-radius:6px}figure{margin:20px 0}figcaption{font-size:12px;color:#526278}li{margin:5px 0}header p{color:#42536a}footer{margin-top:24px;font-size:13px;color:#526278}</style><main><header><h1>Evidências dos testes</h1>"""
    content += f'<p>{total} cenários · {counts["PASS"]} aprovados · {counts["FAIL"]} reprovados · {counts["SKIP"]} ignorados · {screenshot_count} capturas</p>'
    content += '<p>Abra cada cenário para ver os passos, a mensagem e a captura. As falhas aparecem abertas. Casos DEMO são falhas intencionais do exercício.</p></header>'
    content += "".join(cards) or "<p>Não foi gerado resultado Robot. Consulte os logs de instalação e preparação da execução.</p>"
    content += '<footer>Relatório extraído do output.xml, com imagens incorporadas. Nenhum arquivo externo é necessário para visualizar esta página.</footer></main></html>'
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_text(content, encoding="utf-8")
    summary = f'## Resultado Robot\n\n**{total} cenários · {counts["PASS"]} aprovados · {counts["FAIL"]} reprovados · {screenshot_count} capturas**\n\n'
    if not total:
        summary += "Resultado indisponível. Consulte os logs de preparação.\n"
    if failures:
        summary += "| Cenário reprovado | Mensagem |\n| --- | --- |\n"
        for name, message in failures:
            clean = lambda text: escape(text).replace("|", "\\|").replace("\n", " ")
            summary += f'| {clean(name)} | {clean(message[:700])} |\n'
        summary += "\nCasos DEMO são falhas intencionais; não representam defeitos reais da loja.\n"
    return {"total": total, "counts": counts, "screenshots": screenshot_count, "summary": summary}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", default="results/robot/output.xml")
    parser.add_argument("--output", default="results/visual/evidencias.html")
    parser.add_argument("--link", action="store_true")
    args = parser.parse_args()
    summary_path = os.environ.get("GITHUB_STEP_SUMMARY")
    if args.link:
        url = os.environ.get("EVIDENCIAS_URL", "")
        if summary_path and url.startswith("https://github.com/"):
            with open(summary_path, "a", encoding="utf-8") as handle:
                handle.write(f'\n## Relatório visual\n\n[Abrir cenários e capturas no navegador]({url})\n\nArquivo: `evidencias.html`, sem ZIP. Disponível por três dias. O pacote completo permanece em Artifacts.\n')
        return
    report = build_report(args.input, args.output)
    if summary_path:
        with open(summary_path, "a", encoding="utf-8") as handle:
            handle.write(report["summary"])
    print(f'Relatório visual: {report["total"]} cenários, {report["screenshots"]} capturas. Arquivo: {args.output}')


if __name__ == "__main__":
    main()
