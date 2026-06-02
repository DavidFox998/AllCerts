---
name: w1 SU(3) single-plaquette weight — repo normalization & Wall256 beta0
description: The repo action normalization for the single-site SU(3) Haar weight w1, the real beta0 threshold for w1<1/7, and why the Wall256 "beta>0.85" doc note is stale.
---

# w1 SU(3) weight: repo normalization and the real Wall256 threshold

**Repo single-plaquette action** is the NORMALIZED form
`S(U) = plaquetteEnergy = (3 - Re tr U)/3 = 1 - Re tr(U)/3`
(`Towers/YM/WilsonPositivity.lean`, `Towers/YM/WilsonAction.lean`).

**Single-site Haar weight** `w1(beta) = ∫_{SU(3)} exp(-beta*S(U)) d haar(U)`.
Under the repo (normalized) action:
- `w1(0) = 1.0`, `w1(0.86) ≈ 0.4324` — this is ~3x ABOVE `1/7`, so `w1(0.86) < 1/7` is FALSE.
- Minimal `beta0` with `w1(beta0) = 1/7` is **`beta0 ≈ 2.0794`**; the bound `w1 < 1/7`
  holds only for `beta > ~2.08`.

**The Wall256_Scaffold "beta > 0.85" note is STALE.** It assumes the UN-normalized
Wilson action `3 - Re tr U` (= `3*S`). Since `w1_unnorm(beta) = w1_repo(3*beta)`, the
un-normalized threshold is `beta0 ≈ 0.693` (so even 0.85 is not exactly right there).
Any "w1(0.86) ≈ 0.054 < 1/7" claim reproduces under NO normalization tested — withdraw it.

**Method that works (numerical only):** deterministic SU(3) Weyl-torus quadrature,
eigenangles `t1,t2,t3=-t1-t2`, density `|Δ|^2 = ∏_{j<k}(2 - 2 cos(t_j - t_k))`,
self-normalized ratio (global constants cancel); validated against a 2e6-draw Haar-SU(3)
Monte Carlo. Script: `lean-proof-towers/exports/w1_repo_normalization.py`.

**RIGOROUS interval certificate now exists (CERT_Arb, 2026-06-01):** a GUARANTEED
enclosure (not sampling) via exact rational Haar moments `m_n=<(Re tr U)^n>` by
constant-term extraction over the SU(3) torus (Weyl weight `V`, `CT[V]=6`) + a
factorial tail bound `|R_N|≤β^{N+1}/(N+1)!·1/(1-β/(N+2))` (since `|m_n|≤3^n`),
evaluated in `mpmath.iv` (N=36, iv.dps=80). NB `m3=1/4 ≠ 0` (the 3⊗3⊗3 epsilon
singlet — a natural pitfall is asserting m3=0). Certified: refined
`β₀∈[2.079416880123, 2.079416880124]` (≈2.0794169), and `w1(0.86)>1/7` (D4 fails).
Script `lean-proof-towers/exports/arb_w1_enclosure.py`; deliverables
`CERT_Arb_beta0.pdf` + `CERT_Arb_beta0_2026-06-01.yaml`. STILL out-of-tower: NOT
Lean/trio-clean, discharges nothing; even `β>β₀` would only SUPPLY (not close)
Wall256 `hw1`.

**Why:** establishing beta0 cost real computation, and the in-repo docstring (0.85) is
misleading. The honest verdict (D4 at 0.86 is NEGATIVE; the real threshold is ~2.08) is
now backed by a rigorous interval certificate (above) — but it is STILL NOT Lean, NOT
trio-clean, and discharges NOTHING (Wall256 `hw1`,
the parent KP surface, Surface #1, and the YM tower all stay OPEN; no mass-gap claim).

**How to apply:** if anyone revisits the Wall256 `hw1 : w1 < 1/7` hypothesis, target
`beta > ~2.08` under the repo's `(3 - Re tr)/3` action (not 0.85), and require a verified
interval enclosure before any strict-bound wording.

**Do NOT try to derive `hw1` (`w1 β₀ < 1/7`) from H4 / `heat_trace_poly_bound`.** This
is a recurring FALSE-PREMISE ask; it fails on three independent counts. (1) WRONG OBJECT:
`w1` is the opaque NORMALIZED single-site Haar weight (~0.1428 at β₀), NOT
`Weyl_sum_explicit_SU3_real` / `Heat_kernel_envelope_real`, which are heat-traces at the
identity and are `≥ 1` for all β>0 (`Heat_kernel_envelope_real_ge_one_of_pos`,
`Weyl…_at_zero = 1`). Any upper-bound chain through them bounds `w1` by something `≥1` —
cannot reach `<1/7`; identifying `w1 = Weyl_sum_explicit` makes the goal FALSE (`≥1>1/7`).
(2) WRONG DOMAIN: `heat_trace_poly_bound` holds only on `Ioc 0 1`; β₀≈2.08 > 1, so it
can't be instantiated at β₀ at all. (3) HOPELESSLY LOOSE even if it applied: the explicit
constant is `C = 64·6561 + 64·128·120·(4/3)⁵ = 419904 + 1006632960/243 ≈ 4.56e6`, so
`C/β₀⁴ ≈ 2.44e5`, i.e. `C/β₀⁴ < 1/7` is FALSE by ~1.7e6×; `norm_num` cannot prove it.
`hw1` stays DERIVED from the two disclosed OPEN `[NEEDS_LEMMA]` axioms (`w1_eq_weyl`,
`w1_weyl_beta0_lt`); it is NOT trio-only provable in mathlib v4.12.0 (no Bessel/Weyl).
