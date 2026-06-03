#!/usr/bin/env python3
"""Render docs/COLOPHON.md to TOWERS_YM_v2.3.pdf (deterministic, monospace).

Verbatim monospace (DejaVuSansMono) render of the colophon source. No AI, no
network. Produces the v2.3 certificate PDF at repo root.

Run: uv run --with reportlab --no-project python scripts/render_colophon_pdf.py
"""
import os
import textwrap

from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.units import inch
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import Preformatted, SimpleDocTemplate, Spacer

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "docs", "COLOPHON.md")
OUT = os.path.join(ROOT, "TOWERS_YM_v2.3.pdf")
FONT = "/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf"
WRAP = 88


def main() -> None:
    pdfmetrics.registerFont(TTFont("DejaVuMono", FONT))
    style = ParagraphStyle("mono", fontName="DejaVuMono", fontSize=8.5, leading=11)

    flow = []
    for ln in open(SRC, encoding="utf-8").read().splitlines():
        if not ln.strip():
            flow.append(Spacer(1, 6))
            continue
        segs = textwrap.wrap(
            ln, WRAP, break_long_words=True,
            replace_whitespace=False, drop_whitespace=False,
        ) or [ln]
        for seg in segs:
            flow.append(Preformatted(seg, style))

    SimpleDocTemplate(
        OUT, pagesize=letter,
        leftMargin=0.75 * inch, rightMargin=0.75 * inch,
        topMargin=0.75 * inch, bottomMargin=0.75 * inch,
        title="Towers YM v2.3 - H4 Boundary Protocol", author="D. Fox",
    ).build(flow)
    print("wrote", OUT)


if __name__ == "__main__":
    main()
