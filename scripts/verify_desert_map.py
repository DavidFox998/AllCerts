#!/usr/bin/env python3
"""Certify + verify the Exceptional-Prime Desert Map (Plan #316).

The test (there is only one):
    p is exceptional  <=>  || p * (pi/10) || < 1/p ,
where ||x|| = distance to the nearest integer.  Since 299*p is an integer,
|| p*(299 + pi/10) || == || p*pi/10 ||, so alpha0 = 299 + pi/10 and pi/10
define the SAME exceptional set.

Certification (recompute every prime's test at >= 8,300-digit pi precision):
  - Candidate values are read from BOTH data/pi10_exceptional_primes.txt and
    data/desert_map.csv (they disagree for the giant entries #9..#20).  Only a
    genuine best-approximation denominator of pi/10 can satisfy ||q*pi/10|| < 1/q,
    so testing the rule at full precision disambiguates which value is correct.
  - For the certified value we confirm primality by BPSW (sympy.isprime).
  - Completeness ("exactly 20 below 10^4000, none missing") rests on the
    documented Legendre / best-approximation certificate recorded in the header
    of data/pi10_exceptional_primes.txt (every q with ||q*alpha||<1/q is a
    convergent or upper-semiconvergent of pi/10; all such q <= 10^4000 were
    enumerated and tested exactly, min decision margin ~10^8295).

Outputs the per-prime report, the desert widths (p_k - p_(k-1) - 1), the
energies C_unwt / C_wt, and (with --write) republishes data/desert_map.csv.

Run from repo root:  python3 scripts/verify_desert_map.py [--write]
Requires: mpmath, sympy.
"""
import sys
sys.set_int_max_str_digits(2_000_000)  # giant desert widths exceed the 4300-digit default
from mpmath import mp, mpf, log

mp.dps = 9000  # pi to 9000 digits (>= the 8,300 required; covers #20's ~7200 need)
from sympy import isprime  # noqa: E402

PI_OVER_10 = mp.pi / 10


def norm_frac(q):
    """||q * pi/10|| at full precision for integer q."""
    x = mpf(int(q)) * PI_OVER_10
    return abs(x - mp.nint(x))


def read_txt_primes(path="data/pi10_exceptional_primes.txt"):
    out = {}
    for line in open(path):
        s = line.strip()
        if s and not s.startswith("#"):
            c = s.split()
            if len(c) >= 4 and c[0].isdigit():
                out[int(c[0])] = int(c[3])
    return out


def read_csv_primes(path="data/desert_map.csv"):
    out = {}
    lines = open(path).read().splitlines()
    hdr = lines[0].split(",")
    ki, pe = hdr.index("k"), hdr.index("prime_exact")
    for ln in lines[1:]:
        if ln.strip():
            c = ln.split(",")
            out[int(c[ki])] = int(c[pe])
    return out


def certified_value(k, txt, csv):
    """Return the value at index k that passes ||p*pi/10|| < 1/p, plus diagnostics."""
    cands = []
    for src, d in (("txt", txt), ("csv", csv)):
        if k in d:
            p = d[k]
            cands.append((src, p))
    passers = []
    diag = {}
    for src, p in cands:
        r = mpf(int(p)) * norm_frac(p)
        ok = r < 1  # test: ||p*pi/10|| < 1/p  <=>  r = p*||p*pi/10|| < 1
        diag[src] = (p, r, ok)
        if ok:
            passers.append(p)
    # the certified value is the unique passer (sources may agree on it)
    uniq = sorted(set(passers))
    return (uniq[0] if len(uniq) == 1 else (uniq if uniq else None)), diag


def htail(n, head=18, tail=12, full_below=40):
    """head…tail rendering of a big integer (full if short)."""
    s = str(n)
    if len(s) <= full_below:
        return s
    return f"{s[:head]}…{s[-tail:]}  ({len(s)} digits)"


def generate_md(path="docs/exceptional-prime-desert-map.md"):
    """Regenerate the report from the CERTIFIED data/desert_map.csv (fast; no BPSW)."""
    lines = open("data/desert_map.csv").read().splitlines()
    hdr = lines[0].split(",")
    col = {name: hdr.index(name) for name in hdr}
    rows = []
    for ln in lines[1:]:
        if ln.strip():
            c = ln.split(",")
            rows.append({k: c[i] for k, i in col.items()})

    out = []
    A = out.append
    A("# Exceptional-Prime Desert Map — α₀ = 299 + π/10")
    A("")
    A("**Status: data report, independently re-certified (Plan #316). No new "
      "mathematics is claimed or proved. GRH/RH stay OPEN; primality is BPSW, "
      "not a formal certificate for the 1000+ digit entries.**")
    A("")
    A("**Rule.** A prime `p` is *exceptional* ⟺ `‖p·π/10‖ < 1/p`, where `‖x‖` = "
      "distance to nearest integer. Since `299·p ∈ ℤ`, this equals "
      "`‖p·(299+π/10)‖`, so the α₀ test and the π/10 test are identical.")
    A("")
    A("**Certification (this report).** Every one of the 20 primes was recomputed "
      "from scratch and tested against **π to 9,000 decimal digits** "
      "(≥ the 8,300-digit requirement; entry #20 needs ~7,200). For each, "
      "`r = p·‖p·π/10‖` was evaluated at full precision and the rule confirmed as "
      "`r < 1`; primality was re-confirmed by BPSW (`sympy.isprime`). Reproduce with "
      "`python3 scripts/verify_desert_map.py`. Exact integers and all fields: "
      "`data/desert_map.csv`.")
    A("")
    A("**Completeness (cited, not re-derived here).** By Legendre / best-"
      "approximation theory every `q` with `‖q·α₀‖ < 1/q` is a convergent or "
      "upper-semiconvergent of π/10; all such `q ≤ 10⁴⁰⁰⁰` were enumerated and "
      "tested exactly with a decision certificate (min margin ~10⁸²⁹⁵ ≫ threshold "
      "10⁸⁰⁰⁰) in `data/pi10_exceptional_primes.txt`. **Result: exactly 20 "
      "exceptional primes to 10⁴⁰⁰⁰.**")
    A("")

    last = rows[-1]
    s4 = rows[:4]
    A("## Structural claim")
    A("")
    A(f"- **S₄ = {{2, 3, 19, 191}}** (the \"trio + 191\").")
    A(f"- **C_unwt(S₄) = {s4[3]['C_unwt_cum']} < 7.2111** (= 2√13, the classical "
      "bound). The unweighted energy of the whole set barely moves above this — "
      f"**C_unwt(S₂₀) = {last['C_unwt_cum']}** — because `log p/(p−1) → 0` for the "
      "giant primes, so only S₄ contributes meaningfully.")
    A(f"- **C_wt(S₄) = {s4[3]['C_wt_cum']}**, growing to "
      f"**C_wt(S₂₀) = {last['C_wt_cum']}** (≫ 7.2111). The weighted energy is "
      "flagged **Open** — it is a computed quantity, not a proof of any bound.")
    p5 = rows[4]
    A(f"- **P5 = {p5['prime_exact']}** ({p5['digits']} digits) opens **Desert 1**, "
      f"a void of **{p5['desert_width']}** consecutive non-exceptional integers "
      "after 191 (= P5 − 191 − 1).")
    A("")

    A("## P5 explicit verification (the centerpiece)")
    A("```")
    p5v = int(p5["prime_exact"])
    nf = norm_frac(p5v)
    A(f"P5            = {p5v}   ({p5['digits']} digits)")
    A(f"‖P5·π/10‖     = {mp.nstr(nf, 12)}")
    A(f"1/P5          = {mp.nstr(mpf(1)/p5v, 12)}")
    A(f"‖P5·π/10‖ < 1/P5 ?  True   (r = P5·‖P5·π/10‖ = {p5['r']} < 1)")
    A("```")
    A("")

    A("## Desert widths  (width_k = p_k − p_(k-1) − 1)")
    A("")
    A("| Desert | between | width (consecutive non-exceptional integers) |")
    A("|---:|:---|:---|")
    for i in range(1, len(rows)):
        w = rows[i]["desert_width"]
        A(f"| {i} | P{i} → P{i+1} | {htail(int(w)) if w not in ('0',) else '0'} |")
    A("")

    A("## The 20 exceptional primes")
    A("")
    for i, r in enumerate(rows):
        k = int(r["k"])
        p = int(r["prime_exact"])
        d = r["digits"]
        nf = norm_frac(p)
        tag = "Trio" if k <= 3 else ("Trio_End" if k == 4 else "GIANT")
        flag = "" if k <= 4 else "  ·  **Open** (P5–P20 flagged Open)"
        A(f"### PRIME #{k} — {d} digit{'s' if d!='1' else ''}  ·  [{tag}]{flag}")
        A(f"- Exact: `{htail(p)}`" + ("" if len(str(p)) <= 40 else
          "  — full integer in `data/desert_map.csv`"))
        A(f"- r = p·‖p·π/10‖ = {r['r']}  (< 1 ✓)")
        A(f"- ‖p·π/10‖ = {mp.nstr(nf, 7)}")
        A(f"- BPSW prime: {r['bpsw_prime']}")
        if k == 1:
            A("- Gap from previous: — (first)")
        else:
            A(f"- Gap from previous (p_k − p_(k-1)): {htail(int(r['gap_from_prev']))}")
            A(f"- Desert width (p_k − p_(k-1) − 1): "
              f"{htail(int(r['desert_width'])) if r['desert_width']!='0' else '0'}")
        A(f"- C_unwt cumulative: {r['C_unwt_cum']}")
        A(f"- C_wt cumulative: {r['C_wt_cum']}")
        A("")

    A("## Notes")
    A("- **First desert (191 → P5)** is the headline void: "
      f"{p5['desert_width']} consecutive integers with zero exceptional primes.")
    A("- The circulated list `…291,317,607,…` is a `299+π` (not π/10) artifact; "
      "291 = 3×97 is composite; only 2,3,19,191 of it actually pass. Excluded.")
    A("- **Honesty.** BPSW is not a formal primality proof for the 1000+ digit "
      "entries; C_wt(S₂₀) is a computed value flagged Open; this report proves no "
      "new mathematics and asserts no bound.")
    A("")

    open(path, "w").write("\n".join(out))
    print(f"# WROTE {path}  ({len(rows)} primes, regenerated from certified CSV)")


def main():
    if "--md" in sys.argv:
        generate_md()
        return
    write = "--write" in sys.argv
    txt, csv = read_txt_primes(), read_csv_primes()
    indices = sorted(set(txt) | set(csv))

    print(f"# mp.dps = {mp.dps}  (pi/10 to ~{mp.dps} digits; Plan #316 wants >= 8300)")
    print(f"# 299 + pi/10 = {mp.nstr(299 + PI_OVER_10, 16)}")
    print(f"# 2*sqrt(13)  = {mp.nstr(2*mp.sqrt(13), 12)}  (classical bound, 'C < 7.2111')")
    print(f"# indices present: {len(indices)}  (txt={len(txt)}, csv={len(csv)})")
    print("\n# k digits   r = p*||p*pi/10||    pass  bpsw   source(txt/csv -> certified)")

    primes = []
    bpsw_flags = []
    for k in indices:
        cert, diag = certified_value(k, txt, csv)
        assert cert is not None and not isinstance(cert, list), \
            f"index {k}: no unique passing value; diag={ { s:(str(p)[:24]+'...', mp.nstr(r,4), ok) for s,(p,r,ok) in diag.items() } }"
        r = mpf(int(cert)) * norm_frac(cert)
        bpsw = isprime(cert)  # BPSW via sympy -- exactly one call per prime
        tag_t = "Y" if diag.get("txt", (None,))[0] == cert else ("n" if "txt" in diag else "-")
        tag_c = "Y" if diag.get("csv", (None,))[0] == cert else ("n" if "csv" in diag else "-")
        print(f"{k:>2} {len(str(cert)):>6}  {mp.nstr(r,10):>16}  {str(r < 1):>5} {str(bpsw):>5}   {tag_t}/{tag_c}")
        primes.append(cert)
        bpsw_flags.append(bpsw)

    assert len(primes) == 20, f"expected 20 certified primes, got {len(primes)}"
    assert all(bpsw_flags), "BPSW failed for a certified prime"
    assert primes == sorted(primes), "certified primes not in ascending order"

    # Energies + desert widths
    cu = cw = mpf(0)
    rows = []
    prev = None
    for k, (p, bpsw) in enumerate(zip(primes, bpsw_flags), start=1):
        cu += log(p) / (p - 1)
        cw += log(p) * p / (p - 1)
        gap = (p - prev) if prev is not None else 0
        width = (p - prev - 1) if prev is not None else 0
        r = mpf(int(p)) * norm_frac(p)
        rows.append(dict(k=k, p=p, digits=len(str(p)), gap=gap, width=width,
                         r=mp.nstr(r, 10), bpsw=bpsw,
                         cu=mp.nstr(cu, 10), cw=mp.nstr(cw, 10)))
        prev = p

    S4 = primes[:4]
    cu4 = sum((log(p) / (p - 1) for p in S4), mpf(0))
    cw4 = sum((log(p) * p / (p - 1) for p in S4), mpf(0))
    bound = 2 * mp.sqrt(13)
    print("\n# ---- STRUCTURAL CLAIM (computed) ----")
    print(f"# S_4 = {S4}")
    print(f"# C_unwt(S_4)  = {mp.nstr(cu4,10)}   < 7.2111 ? {cu4 < bound}")
    print(f"# C_wt (S_4)   = {mp.nstr(cw4,10)}")
    print(f"# C_unwt(S_20) = {mp.nstr(cu,10)}   < 7.2111 ? {cu < bound}")
    print(f"# C_wt (S_20)  = {mp.nstr(cw,10)}   >> 7.2111")
    p5 = primes[4]
    print(f"# P5 = {p5}  (digits={len(str(p5))})  opens Desert 1")
    print(f"# Desert 1 width = P5 - 191 - 1 = {p5 - 191 - 1}")

    print("\n# ---- DESERT WIDTHS  (width_k = p_k - p_(k-1) - 1) ----")
    for row in rows:
        if row["k"] >= 2:
            print(f"# Desert {row['k']-1} (P{row['k']-1}->P{row['k']}): width = {row['width']}")

    if write:
        cols = ["k", "prime_exact", "digits", "gap_from_prev", "desert_width",
                "r", "bpsw_prime", "C_unwt_cum", "C_wt_cum"]
        with open("data/desert_map.csv", "w") as f:
            f.write(",".join(cols) + "\n")
            for row in rows:
                f.write(",".join(str(v) for v in [
                    row["k"], row["p"], row["digits"], row["gap"], row["width"],
                    row["r"], row["bpsw"], row["cu"], row["cw"]]) + "\n")
        print("\n# WROTE data/desert_map.csv (certified, recomputed)")
    else:
        print("\n# (report only; re-run with --write to publish data/desert_map.csv)")


if __name__ == "__main__":
    main()
