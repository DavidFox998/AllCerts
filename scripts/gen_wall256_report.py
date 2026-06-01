#!/usr/bin/env python3
"""Generate docs/Wall256_Conditional_Report.pdf — an HONEST report on the
Wall256 SU(3) strong-coupling CONDITIONAL reduction.

Reproducible: hand-authored SVG pages (DejaVu fonts) + the existing Wall256
diagrams, merged into a single PDF via cairosvg + pypdf. NO claim of a proven
mass gap / spectral gap / Surface #1 is made anywhere in this document.

Run with:
  uvx --quiet --with cairosvg --with pypdf python scripts/gen_wall256_report.py
"""
import base64
import io
import os

import cairosvg
from pypdf import PdfReader, PdfWriter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DOCS = os.path.join(ROOT, "docs")
OUT = os.path.join(DOCS, "Wall256_Conditional_Report.pdf")

W = 1060
SANS = "DejaVu Sans, Arial, Helvetica, sans-serif"
MONO = "DejaVu Sans Mono, Menlo, Consolas, monospace"

INK = "#1a1d27"
GREY = "#6b7280"
BODY = "#3a4051"
BLUE = "#23408e"
RED = "#d23f3f"
GREEN = "#2f8f4e"
BOXFILL = "#f5f6fa"
BOXLINE = "#d4d8e2"


def esc(s: str) -> str:
    return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


def T(x, y, s, size=14, color=BODY, weight="normal", font=SANS, anchor="start"):
    return (
        f'<text x="{x}" y="{y}" font-family="{font}" font-size="{size}" '
        f'font-weight="{weight}" fill="{color}" text-anchor="{anchor}">{esc(s)}</text>'
    )


def wrap(s, maxchars):
    words = s.split()
    lines, cur = [], ""
    for w in words:
        if len(cur) + len(w) + (1 if cur else 0) <= maxchars:
            cur = (cur + " " + w) if cur else w
        else:
            lines.append(cur)
            cur = w
    if cur:
        lines.append(cur)
    return lines


def para(x, y, s, size=14, color=BODY, maxchars=120, lh=21, font=SANS):
    out = []
    for ln in wrap(s, maxchars):
        out.append(T(x, y, ln, size=size, color=color, font=font))
        y += lh
    return "\n".join(out), y


def badge(x, y, label, color):
    w = 18 + len(label) * 8
    return (
        f'<rect x="{x}" y="{y}" width="{w}" height="22" rx="11" ry="11" fill="{color}"/>'
        + T(x + w / 2, y + 15.5, label, size=12.5, color="#ffffff", weight="bold", anchor="middle")
    ), w


def box(x, y, w, h, fill=BOXFILL, line=BOXLINE, lw=1.5, bar=None):
    s = f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="12" ry="12" fill="{fill}" stroke="{line}" stroke-width="{lw}"/>'
    if bar:
        s += f'<rect x="{x}" y="{y}" width="6" height="{h}" rx="3" ry="3" fill="{bar}"/>'
    return s


def page(height, body):
    return (
        f'<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" '
        f'width="{W}" height="{height}" viewBox="0 0 {W} {height}" font-family="{SANS}">'
        f'<rect width="{W}" height="{height}" fill="#ffffff"/>'
        + body
        + "</svg>"
    )


def header(title, subtitle):
    return (
        T(40, 52, title, size=25, color=INK, weight="bold")
        + T(40, 78, subtitle, size=14, color=GREY)
    )


def footer(h, text):
    return (
        f'<line x1="40" y1="{h-58}" x2="{W-40}" y2="{h-58}" stroke="{BOXLINE}" stroke-width="1.2"/>'
        + T(40, h - 36, text, size=11.5, color=GREY, font=MONO)
        + T(40, h - 18, "Towers/YM/Wall256_Scaffold.lean  ·  classical trio  ·  SORRY: 0  ·  NOT a brick  ·  YM Status: Open", size=11.5, color=GREY, font=MONO)
    )


pages = []

# ---------------------------------------------------------------- PAGE 1: cover
b = []
b.append(header("Wall256 — SU(3) Strong-Coupling Conditional Reduction",
                "An honest report · what is machine-checked, what stays open, and what is NOT proven"))
# honesty banner
b.append(box(40, 104, W - 80, 132, fill="#fff5f5", line=RED, lw=2, bar=RED))
b.append(T(64, 138, "CONDITIONAL REDUCTION — NO CLAY RESULT IS PROVEN", size=18, color=RED, weight="bold"))
t, _ = para(64, 166,
            "This document describes a pure logical REDUCTION. It does NOT prove a Yang-Mills mass gap, a "
            "spectral gap, convergence of any real cluster expansion, or close Clay Surface #1. The entire "
            "mathematical content lives in THREE explicit open hypotheses; none is discharged. Scope is the "
            "LATTICE SU(3) strong-coupling regime, NOT the Clay continuum problem.", size=13.5, color="#7a2d2d", maxchars=118)
b.append(t)
# what it is
b.append(T(40, 282, "What this is", size=17, color=INK, weight="bold"))
t, y = para(40, 310,
            "Towers/YM/Wall256_Scaffold.lean is a single sorry-free, axiom-clean theorem "
            "(strong_coupling_decay_of_open_inputs). It threads the three open inputs of the Osterwalder-Seiler "
            "strong-coupling analysis through already-landed, genuinely machine-checked algebra "
            "(comparison-test summability + a rho^d = exp(-Delta*d) identity) to an abstract two-point decay "
            "shape. The conclusion holds ONLY IF all three hypotheses hold.", maxchars=120)
b.append(t)
# verdict cards
cy = y + 16
cards = [
    ("PROVEN", GREEN, "The reduction wiring", "comparison-test summability + rho^d=exp(-Delta*d) algebra are machine-checked."),
    ("OPEN", RED, "The 3 hypotheses", "SU(3) Haar bound, Osterwalder-Seiler cluster step, Brydges-Federbush bridge."),
    ("NONE", GREY, "Mass-gap claim", "No mu>0, no spectral gap, no Surface #1, no continuum / Clay statement."),
]
cw = (W - 80 - 2 * 24) / 3
for i, (lab, col, head, txt) in enumerate(cards):
    cx = 40 + i * (cw + 24)
    b.append(box(cx, cy, cw, 150, bar=col))
    bd, bw = badge(cx + 20, cy + 18, lab, col)
    b.append(bd)
    b.append(T(cx + 20, cy + 70, head, size=15, color=INK, weight="bold"))
    t, _ = para(cx + 20, cy + 94, txt, size=12, color=BODY, maxchars=42, lh=17)
    b.append(t)
H1 = cy + 150 + 90
b.append(footer(H1, "Wall256_Conditional_Report.pdf  ·  generated by scripts/gen_wall256_report.py"))
pages.append(page(H1, "\n".join(b)))

# ------------------------------------------------------ PAGE 2: the Lean statement
b = []
b.append(header("The exact Lean statement", "Verbatim from Wall256_Scaffold.lean — the only mathematical assertion in this file"))
# Extract the declaration VERBATIM from the Lean source (statement only:
# theorem header through the one-line proof body; proof-internal `--` comment
# lines are dropped — they are not part of the statement). Self-checks below
# fail the build on any drift from the real syntax.
def extract_theorem():
    src = os.path.join(ROOT, "lean-proof-towers", "Towers", "YM", "Wall256_Scaffold.lean")
    with open(src, encoding="utf-8") as fh:
        raw = [l.rstrip("\n") for l in fh]
    start = next(i for i, l in enumerate(raw)
                 if l.lstrip().startswith("theorem strong_coupling_decay_of_open_inputs"))
    end = next(i for i, l in enumerate(raw)
               if "su2_gap_of_truncatedActivity corr sep" in l)
    block = raw[start:end + 1]
    return [l for l in block if not l.lstrip().startswith("--")]


lean = extract_theorem()
# Self-check: the exact tokens the architect flagged must be present verbatim.
_blob = "\n".join(lean)
for needle in [
    "theorem strong_coupling_decay_of_open_inputs",
    "(corr sep : E → E → ℝ) (C ρ w1 : ℝ)",
    "(hw1 : w1 < 1 / 7)",
    "(hOS : w1 < 1 / 7 → TruncatedActivityBound a)",
    "Summable (fun n : ℕ => N n * a n)",
    "∃ Δ : ℝ, 0 < Δ ∧ ∀ x y, |corr x y| ≤ C * Real.exp (-Δ * sep x y)",
    "su2_gap_of_truncatedActivity corr sep C ρ hN0 hN (hOS hw1) h_bridge",
]:
    assert needle in _blob, f"Lean statement drift — missing verbatim: {needle!r}"

bh = 40 + len(lean) * 24
b.append(box(40, 104, W - 80, bh, fill="#0f1320", line="#0f1320"))
yy = 134
NBSP = "\u00a0"
for ln in lean:
    col = "#cdd6f4"
    st = ln.lstrip()
    if st.startswith("theorem") or st.startswith("su2_gap"):
        col = "#8fb7ff"
    elif st.startswith("(hw1") or st.startswith("(hOS") or st.startswith("(h_bridge"):
        col = "#7fd1a3"
    # preserve indentation/alignment under SVG whitespace collapsing
    b.append(T(60, yy, ln.replace(" ", NBSP), size=13.5, color=col, font=MONO))
    if st.startswith("(hw1") or st.startswith("(hOS") or st.startswith("(h_bridge"):
        bd, _bw = badge(W - 40 - 16 - 48, yy - 15, "OPEN", RED)
        b.append(bd)
    yy += 24
y = 104 + bh + 36
b.append(T(40, y, "In plain language", size=17, color=INK, weight="bold"))
y += 28
glos = [
    "corr, sep are ABSTRACT — an arbitrary correlator and separation on any type E. No real Wilson-loop "
    "correlator or lattice metric is built.",
    "hN0, hN: the polymer entropy count N n is bounded by the 7^n geometric growth (the 7 = SU(3) coordination "
    "of connected polymers through a fixed plaquette).",
    "Conclusion: exponential two-point decay |corr| ≤ C·exp(-Δ·sep) with Δ > 0 — IF H1, H2, H3 all hold.",
    "The proof body is one line: it just plugs the three hypotheses into the already-landed reduction combinator "
    "su2_gap_of_truncatedActivity (named for legacy reasons; it is group-agnostic and asserts no gap).",
]
for g in glos:
    b.append(f'<circle cx="48" cy="{y-5}" r="3" fill="{BLUE}"/>')
    t, y = para(64, y, g, maxchars=118)
    b.append(t)
    y += 8
H2 = y + 80
b.append(footer(H2, "Source: Wall256_Scaffold.lean (commit 8eeab54)  ·  reused: Wall256_Note.su2_gap_of_truncatedActivity"))
pages.append(page(H2, "\n".join(b)))

# ------------------------------------------------- PAGE 3: the three open hypotheses
b = []
b.append(header("The three OPEN inputs", "Each is a hypothesis — never proved here. The real-world theorem each stands for is named."))
hyps = [
    ("H1", "hw1 : w1 < 1/7",
     "SU(3) single-site Haar weight (strict bound)",
     "w1 stands for ∫_{SU(3)} exp(-β·actL) d(haar). The strict bound < 1/7 holds for large β (β > ~0.85), a "
     "genuine Haar / character-expansion estimate. mathlib v4.12.0 cannot evaluate it, so it is carried as a "
     "real-number hypothesis on an abstract w1.",
     "SU(3) character theory / verified cubature (absent from mathlib v4.12.0)."),
    ("H2", "hOS : w1 < 1/7 → TruncatedActivityBound a",
     "Osterwalder-Seiler 1978, Thm 2.1 (Ursell / cluster step)",
     "Single-site smallness propagates, via the truncated (Ursell) cluster expansion, to a per-size "
     "connected-polymer activity bound a n ≤ exp(-I)^n with rate I > log 7. The cluster expansion is absent "
     "from mathlib, so this implication is a hypothesis.",
     "Osterwalder & Seiler, Ann. Phys. 110 (1978); truncated polymer expansion."),
    ("H3", "h_bridge : Summable(∑ N n·a n) → (0<ρ<1 ∧ clustering)",
     "Brydges-Federbush KP bridge",
     "Kotecký-Preiss summability of the entropy-weighted polymer series turns into geometric two-point "
     "clustering with spectral radius ρ < 1. Standard textbook cluster-expansion theory, but absent from "
     "mathlib v4.12.0; carried as a hypothesis (NOT by sorry).",
     "Friedli & Velenik, Statistical Mechanics of Lattice Systems (2018), Ch. 5."),
]
y = 104
for tag, code, title, desc, src in hyps:
    bh = 150
    b.append(box(40, y, W - 80, bh, bar=RED))
    bd, bw = badge(W - 40 - 16 - 48, y + 16, "OPEN", RED)
    b.append(bd)
    b.append(T(64, y + 36, tag, size=16, color=RED, weight="bold"))
    b.append(T(96, y + 36, title, size=15, color=INK, weight="bold"))
    b.append(T(64, y + 60, code, size=12.5, color=BLUE, weight="bold", font=MONO))
    t, yy = para(64, y + 82, desc, size=12.5, color=BODY, maxchars=120, lh=18)
    b.append(t)
    b.append(T(64, y + bh - 12, "Real-world source: " + src, size=11.5, color=GREY))
    y += bh + 18
H3 = y + 70
b.append(footer(H3, "None of H1, H2, H3 is discharged or scheduled. The conclusion is valid ONLY IF all three hold."))
pages.append(page(H3, "\n".join(b)))

# ------------------------------------------------- PAGE 4: strict 1/7 argument
b = []
b.append(header("Why the bound must be STRICT: w1 < 1/7, not w1 = 1/7",
                "The boundary case makes the polymer entropy series diverge — the reduction would be vacuous"))
b.append(box(40, 104, W - 80, 96, bar=BLUE))
b.append(T(64, 138, "The entropy vs. smallness race", size=16, color=INK, weight="bold"))
t, _ = para(64, 164,
            "Connected polymers of size n through a fixed plaquette number at most 7^n (entropy). Each carries an "
            "activity suppressed at rate exp(-I)^n. Convergence of ∑ 7^n·exp(-I)^n needs exp(-I) < 1/7, i.e. I > log 7.",
            size=13, color=BODY, maxchars=118)
b.append(t)
y = 230
steps = [
    ("w1 < 1/7", "⇒ I > log 7", "exp(-I) < 1/7, so the geometric ratio 7·exp(-I) < 1.", GREEN),
    ("∑ 7^n·exp(-I)^n", "= ∑ (7·exp(-I))^n", "converges (geometric, ratio < 1) — KP summable.", GREEN),
    ("w1 = 1/7", "⇒ I = log 7", "exp(-I) = 1/7, ratio = 7·(1/7) = 1.", RED),
    ("∑ 7^n·(1/7)^n", "= ∑ 1", "DIVERGES — the comparison test fails; the reduction is vacuous.", RED),
]
for lhs, mid, note, col in steps:
    b.append(box(40, y, W - 80, 64, bar=col))
    b.append(T(64, y + 30, lhs, size=14, color=BLUE, weight="bold", font=MONO))
    b.append(T(310, y + 30, mid, size=14, color=col, weight="bold", font=MONO))
    b.append(T(560, y + 30, note, size=12.5, color=BODY))
    y += 78
b.append(box(40, y, W - 80, 78, fill="#fff5f5", line=RED, lw=1.8, bar=RED))
t, _ = para(64, y + 30,
            "Consequence: the boundary β = 0.85 (where w1 = 1/7) is EXCLUDED. Only the strict interior bound "
            "gives a convergent polymer series. This is exactly the gap between necessary and sufficient — and it "
            "is precisely the content that mathlib cannot supply.", size=12.5, color="#7a2d2d", maxchars=116)
b.append(t)
H4 = y + 78 + 80
b.append(footer(H4, "This strict-inequality argument is the mathematical reason H1 carries '< 1/7', not '≤ 1/7'."))
pages.append(page(H4, "\n".join(b)))

# ------------------------------------------------- PAGES 5,6: embed existing diagrams
EMBED = [
    ("Wall256_Tower.svg", os.path.join(DOCS, "Wall256_Tower.svg")),
    ("Wall256_Derivation.svg", os.path.join(DOCS, "Wall256_Derivation.svg")),
]

# ------------------------------------------------- PAGE 7: NS parallel
b = []
b.append(header("The parallel in the NS tower (for contrast)",
                "The same honesty pattern governs Navier-Stokes — and NS is FROZEN at the Clay boundary"))
b.append(box(40, 104, W - 80, 96, fill="#f3f7ff", line="#9db8e8", lw=1.8, bar=BLUE))
b.append(T(64, 138, "Same shape, different equation", size=16, color=INK, weight="bold"))
t, _ = para(64, 164,
            "Wall256 reduces a lattice gap to an open clustering bound. The NS tower analogously reduces global "
            "regularity to an open a-priori estimate. In both, the hard analytic input is named, not proved.",
            size=13, color=BODY, maxchars=118)
b.append(t)
y = 224
rows = [
    ("Beale-Kato-Majda criterion",
     "Global smoothness holds iff ∫_0^T ‖ω(t)‖_∞ dt < ∞ (ω = vorticity). The time-integrated vorticity sup "
     "is the open quantity — controlling it is equivalent to the regularity problem itself."),
    ("Enstrophy / vorticity control",
     "enstrophy_bound_global_Surface — a global-in-time bound on the vorticity seminorm. A genuine open "
     "surface; necessary input to BKM, not supplied."),
    ("NS FREEZE (locked invariant)",
     "Towers/NS/* is frozen at milestone NS-540-phase6-clay-boundary. Surface #1 (global regularity) and "
     "Surface #2 (modeled weak existence) stay OPEN. No 'NS solved' / 'regularity proven' claim is made."),
]
for title, desc in rows:
    bh = 96
    col = RED if "FREEZE" in title else GREY
    b.append(box(40, y, W - 80, bh, bar=col))
    bd, _ = badge(W - 40 - 16 - 56, y + 16, "FROZEN" if "FREEZE" in title else "OPEN", col)
    b.append(bd)
    b.append(T(64, y + 36, title, size=15, color=INK, weight="bold"))
    t, _ = para(64, y + 60, desc, size=12.5, color=BODY, maxchars=120, lh=18)
    b.append(t)
    y += bh + 16
b.append(box(40, y, W - 80, 64, fill="#fff5f5", line=RED, lw=1.8, bar=RED))
t, _ = para(64, y + 28,
            "No cross-tower bridge is claimed: the YM lattice reduction and the NS regularity reduction are "
            "SEPARATE. Neither implies the other; neither is solved.", size=12.5, color="#7a2d2d", maxchars=116)
b.append(t)
H7 = y + 64 + 80
b.append(footer(H7, "NS detail: Towers/NS/* (frozen)  ·  BKM: Beale, Kato & Majda, Comm. Math. Phys. 94 (1984)."))
pages.append(("AUTHORED", page(H7, "\n".join(b))))

# ------------------------------------------------- PAGE 8: what is NOT proven
b = []
b.append(header("What is NOT proven", "Read this page before drawing any conclusion from this report"))
nots = [
    "NO Yang-Mills mass gap. No m > 0, no Δ > 0 unconditionally — Δ exists only under H1+H2+H3.",
    "NO spectral gap for any real Wilson transfer operator. corr/sep are abstract symbols.",
    "NO closure of Clay Surface #1. It stays OPEN; YM tower Status: Open.",
    "NO continuum / Clay statement. Scope is the LATTICE SU(3) strong-coupling regime only.",
    "NO convergence of a real cluster expansion. The KP summability is conditional on H2's rate I > log 7.",
    "NO discharge of any sorry or named open surface. This file adds none and removes none.",
    "NO link to the π/10 exceptional-prime sieve, to κ_15, or to any number-theoretic 'gap'.",
    "NO cross-tower bridge between the YM and NS reductions.",
]
y = 104
b.append(box(40, y, W - 80, 40 + len(nots) * 30, fill="#fff5f5", line=RED, lw=1.8, bar=RED))
yy = y + 34
for n in nots:
    b.append(T(64, yy, "✗", size=14, color=RED, weight="bold", font=MONO))
    b.append(T(88, yy, n, size=13, color="#5a2222"))
    yy += 30
y = yy + 30
b.append(T(40, y, "What IS true", size=17, color=INK, weight="bold"))
y += 26
yes = [
    "The file is sorry-free and axiom-clean (classical trio {propext, Classical.choice, Quot.sound}).",
    "The reduction wiring — comparison-test summability and the rho^d = exp(-Delta*d) algebra — is machine-checked.",
    "The three hard inputs are stated explicitly and honestly, each pointing at its real-world theorem.",
]
b.append(box(40, y, W - 80, 36 + len(yes) * 28, fill="#f1faf4", line="#9cd6b3", lw=1.8, bar=GREEN))
yy = y + 30
for n in yes:
    b.append(T(64, yy, "✓", size=14, color=GREEN, weight="bold", font=MONO))
    b.append(T(88, yy, n, size=13, color="#22503a"))
    yy += 28
H8 = yy + 96
b.append(footer(H8, "Verdict: a clean conditional REDUCTION. The mass gap remains OPEN and unproven."))
pages.append(("AUTHORED", page(H8, "\n".join(b))))


# --------------------------------------------------------------- assemble PDF
writer = PdfWriter()


def add_svg_bytes(svg_str):
    pdf_bytes = cairosvg.svg2pdf(bytestring=svg_str.encode("utf-8"))
    r = PdfReader(io.BytesIO(pdf_bytes))
    for p in r.pages:
        writer.add_page(p)


def add_svg_file(path):
    pdf_bytes = cairosvg.svg2pdf(url=path)
    r = PdfReader(io.BytesIO(pdf_bytes))
    for p in r.pages:
        writer.add_page(p)


# order: cover, statement, hypotheses, strict-1/7, [tower diagram], [derivation diagram], NS, NOT-proven
add_svg_bytes(pages[0])   # cover
add_svg_bytes(pages[1])   # statement
add_svg_bytes(pages[2])   # hypotheses
add_svg_bytes(pages[3])   # strict 1/7
for _name, path in EMBED:
    add_svg_file(path)
add_svg_bytes(pages[4][1])  # NS parallel
add_svg_bytes(pages[5][1])  # NOT proven

with open(OUT, "wb") as f:
    writer.write(f)

print(f"wrote {OUT}  ({len(writer.pages)} pages)")
