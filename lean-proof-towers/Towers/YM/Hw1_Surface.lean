-- Axiom status: every theorem here uses the classical trio
--   [propext, Classical.choice, Quot.sound] ONLY. There is NO `axiom` in this
--   file (the previous bare `axiom hw1` has been REMOVED).
-- Scope: H1 (`w1 β₀ < 1/7`) is NOT proved in Lean. It is CONDITIONAL — reduced to
--   the two named OPEN lemmas `w1_eq_weyl` + `w1_weyl_beta0_lt` (both
--   `[NEEDS_LEMMA]`, validated only by the OUT-OF-TOWER CERT_Arb certificate, NOT
--   proved). YM stays Open; Surface #1 stays OPEN. NOT a brick, NOT a lakefile root.
/-
Hw1_Surface — HONEST CONDITIONAL packaging of H1, the SU(3) single-site Haar
weight strict bound `w1 β₀ < 1/7`, at the CERT_Arb-certified threshold `β₀`.

WHY H1 IS NOT PROVED HERE (and cannot be, in mathlib v4.12.0)
------------------------------------------------------------
Proving `w1 β₀ < 1/7` from the integral definition
`w1 β = ∫_{SU(3)} exp(-β·actL) d haar` (the `actL` of `Towers.YM.Transfer`)
requires THREE ingredients that mathlib v4.12.0 does not have:
  1. the modified Bessel function `I_n` — ABSENT (`find` for any `*bessel*` file
     in mathlib returns nothing; there is no `Real.besselI`);
  2. the SU(3) Weyl integration formula + the Gross–Witten Toeplitz-determinant
     identity that turns the Haar integral into the winding sum below — ABSENT;
  3. a verified interval/Taylor evaluator for `I_n` and `exp`, so the final
     `< 1/7` would be a checkable rational bound — ABSENT (`norm_num` cannot
     decimalise `Real.exp` or any Bessel value; there is no such extension).
Any "proof" filling (1)–(3) with `sorry` would emit `sorryAx`, violating the
ship-clean lock. So H1 is NOT asserted: it is CONDITIONAL, reduced to the two
explicit OPEN lemmas below, each of which mathlib v4.12.0 cannot discharge.

THE TWO OPEN LEMMAS H1 REDUCES TO
---------------------------------
H1 `w1 β₀ < 1/7` follows from the conjunction of:
  * `w1_eq_weyl I`        — `[NEEDS_LEMMA]` the SU(3) Weyl / Gross–Witten formula:
                            `w1 β₀ = weylValue I β₀` (the closed form holds at β₀);
  * `w1_weyl_beta0_lt I`  — `[NEEDS_LEMMA]` the truncated (K=3) winding sum at β₀ is
                            `weylValue I β₀ < 1/7`.
Both quantify over an abstract `I : ℤ → ℝ → ℝ` standing in for the modified
Bessel function `I_n` (ABSENT from mathlib; NOT fabricated). Both are validated
ONLY by the OUT-OF-TOWER CERT_Arb numerics, NOT by any Lean term.

THE OUT-OF-TOWER EVIDENCE (NOT a Lean proof)
--------------------------------------------
The sole evidence for the two lemmas is the rigorous interval certificate
`exports/CERT_Arb_beta0_2026-06-01.yaml` (mpmath.iv, N=36): it encloses
`β₀ ∈ [2.079416880123, 2.079416880124]` with `w1(β₀) ≈ 0.142856757048 < 1/7`,
cross-checked by the EXACT Bessel-determinant closed form
`w1(β) = e^{-β}·∑_{k∈ℤ} det[I_{(i-j)+k}(β/3)]_{3×3}`
(`exports/w1_repo_normalization.py`). Both are OUT-OF-TOWER numerics, NOT Lean
terms. The earlier heuristic threshold `β > 0.85` is REFUTED
(`w1(0.86) = 0.432367 > 1/7`); the un-normalised single Toeplitz det
`e^{-3β}·det[I_{j-i}(2β)]/β²` is also REFUTED (gives 0.029 at β₀, not 1/7).

WHAT THIS FILE ACTUALLY CONTAINS
--------------------------------
* `weylValue I β` — the closed-form value `e^{-β}·∑_{k∈ℤ} det[I_{(i-j)+k}(β/3)]`,
  over the abstract Bessel stand-in `I`. `noncomputable`; NOT the real `I_n`.
* `WeylClosedForm w I` — the general (`∀ β > 0`) closed-form SHAPE as a NAMED OPEN
  `Prop`. Asserted by NO theorem.
* `w1_eq_weyl I`, `w1_weyl_beta0_lt I` — the two `[NEEDS_LEMMA]` OPEN `Prop`s H1
  reduces to (see above). Asserted by NO theorem; CERT_Arb-validated only.
* `w1_eq_weyl_of_closedForm` — the general formula at β₀ gives `w1_eq_weyl`
  (trio). A convenience bridge; discharges nothing (`WeylClosedForm` stays OPEN).
* `w1_beta0_lt_seventh I h_eq h_lt` — **H1, CONDITIONAL on the two lemmas**; NO
  axiom; `#print axioms` = classical trio. It RESTATES H1 modulo the two open
  lemmas; it adds NO evidence and discharges nothing.
* `cert_value_lt_seventh`, `beta0_in_cert` — the only GENUINELY Lean-checkable
  facts (trio): the certificate's numeric value lands below `1/7`, and the chosen
  `β₀` literal lies inside the CERT_Arb enclosure `[beta0_lo, beta0_hi]`.
* `lattice_decay_of_weyl_lemmas` — the HONEST version of the requested
  "closes_surface_1": a CONDITIONAL lattice reduction threading the two Weyl
  lemmas through `Wall256Scaffold.strong_coupling_decay_of_open_inputs`. It does
  **NOT** close Surface #1 — see the note above its declaration.

Honest scope (locked invariants)
--------------------------------
LATTICE SU(3), single-site weight only. NOT Clay, NOT a continuum gap, NOT SU(2).
YM stays `Status: Open`; Surface #1 stays OPEN. Makes NO `μ > 0` / mass-gap /
Surface-#1 claim; discharges NO `sorry`/surface. `w1` is OPAQUE (fixed but
unknown; NO real integral constructed or evaluated). The STRICT `< 1/7` is
essential — `= 1/7` gives `I = log 7` and the divergent entropy series `∑ₙ 1`.
-/

import Towers.YM.Wall256_Scaffold

namespace TheoremaAureum.Towers.YM.Hw1Surface

open Real
open TheoremaAureum.Towers.YM.Wall256Note (TruncatedActivityBound)
open TheoremaAureum.Towers.YM.Wall256Scaffold
  (Beta0Certified beta0_lo beta0_hi strong_coupling_decay_of_open_inputs)

/-- The CERT_Arb-certified threshold, pinned to the exact rational upper endpoint
`β₀ = 2.079416880124` of the enclosure `β₀ ∈ [2.079416880123, 2.079416880124]`
(mpmath.iv, N=36). OUT-OF-TOWER interval numerics recorded as a literal, NOT a
Lean proof of any SU(3) integral bound. -/
noncomputable def β₀ : ℝ := 2.079416880124

/-- Abstract SU(3) single-site Haar weight `β ↦ ∫_{SU(3)} exp(-β·actL) d haar`.
OPAQUE — fixed but unknown; NO real integral is constructed or evaluated
(mathlib v4.12.0 has no SU(3) Weyl formula / Bessel functions). -/
opaque w1 : ℝ → ℝ

/-- The SU(3) Weyl / Gross–Witten **closed-form value** at `β`, over an abstract
`I : ℤ → ℝ → ℝ` standing in for the modified Bessel function `I_n` (ABSENT from
mathlib v4.12.0 — this is NOT the real `I_n`, just a parameter):
`weylValue I β = e^{-β} · ∑_{k∈ℤ} det[ I_{(i-j)+k}(β/3) ]_{3×3}`.
`noncomputable` (uses `Real.exp` and a `tsum`); no Bessel value is fabricated. -/
noncomputable def weylValue (I : ℤ → ℝ → ℝ) (β : ℝ) : ℝ :=
  Real.exp (-β) *
    ∑' k : ℤ, (Matrix.of (fun i j : Fin 3 => I ((i : ℤ) - (j : ℤ) + k) (β / 3))).det

/-- **The exact SU(3) winding-sum closed form, mirrored into Lean as a NAMED OPEN
`Prop`** (general `∀ β > 0` shape): `w β = weylValue I β`. Documents the closed
form's SHAPE without fabricating any Bessel value. Asserted by NO theorem.
OPEN · OUT_OF_TOWER. -/
def WeylClosedForm (w : ℝ → ℝ) (I : ℤ → ℝ → ℝ) : Prop :=
  ∀ β : ℝ, 0 < β → w β = weylValue I β

/-- **`[NEEDS_LEMMA]` #1 — the SU(3) Weyl / Gross–Witten formula at `β₀`.**
`w1 β₀ = weylValue I β₀`. OPEN · OUT_OF_TOWER: the Weyl integration formula +
Gross–Witten Toeplitz-determinant identity are ABSENT from mathlib v4.12.0; the
equality is validated only by the CERT_Arb out-of-tower numerics, NOT by any Lean
term. Asserted by NO theorem. -/
def w1_eq_weyl (I : ℤ → ℝ → ℝ) : Prop := w1 β₀ = weylValue I β₀

/-- **`[NEEDS_LEMMA]` #2 — the truncated (K=3) winding sum is below `1/7` at
`β₀`.** `weylValue I β₀ < 1/7`. OPEN · OUT_OF_TOWER · `[NEEDS_NUMERICS]`: `norm_num`
cannot decimalise `Real.exp` or any Bessel value, so this strict inequality cannot
be evaluated in Lean; it is validated only by the CERT_Arb certificate
(`weylValue ≈ 0.142856757048 < 1/7`). Asserted by NO theorem. -/
def w1_weyl_beta0_lt (I : ℤ → ℝ → ℝ) : Prop := weylValue I β₀ < 1 / 7

/-- The general closed-form `Prop` `WeylClosedForm w1 I` specialises to the
`[NEEDS_LEMMA]` #1 equality `w1_eq_weyl I` at `β₀ > 0`. A convenience bridge;
classical trio. Discharges nothing — `WeylClosedForm` itself stays OPEN. -/
theorem w1_eq_weyl_of_closedForm (I : ℤ → ℝ → ℝ) (h : WeylClosedForm w1 I) :
    w1_eq_weyl I :=
  h β₀ (by norm_num [β₀])

/-- **H1 — the SU(3) single-site Haar weight strict bound `w1 β₀ < 1/7`, carried
CONDITIONALLY (NO axiom).** It is reduced to the two OPEN lemmas: the Weyl formula
`h_eq : w1_eq_weyl I` and the truncated bound `h_lt : w1_weyl_beta0_lt I`. Both are
`[NEEDS_LEMMA]`, validated only by the OUT-OF-TOWER CERT_Arb certificate and NOT
proved in mathlib v4.12.0. This theorem PROVES NOTHING new about SU(3): it just
rewrites `w1 β₀` by its closed form and applies the truncated bound. `#print
axioms` = classical trio. closes_surface_1 = false; mass_gap_proven = false; YM
stays Open. -/
theorem w1_beta0_lt_seventh (I : ℤ → ℝ → ℝ)
    (h_eq : w1_eq_weyl I) (h_lt : w1_weyl_beta0_lt I) :
    w1 β₀ < 1 / 7 := by
  unfold w1_eq_weyl at h_eq
  unfold w1_weyl_beta0_lt at h_lt
  rw [h_eq]
  exact h_lt

/-- **Genuinely Lean-checkable fact #1 (trio-only): the CERT_Arb numeric value is
`< 1/7`.** `w1(β₀) ≈ 0.142856757048` per the interval certificate, and
`0.142856757048 < 1/7 = 0.142857142857…`. This checks only the RATIONAL
inequality the certificate lands on; it does NOT prove `w1 β₀ < 1/7` (that needs
the two OPEN lemmas). -/
theorem cert_value_lt_seventh : (0.142856757048 : ℝ) < 1 / 7 := by norm_num

/-- **Genuinely Lean-checkable fact #2 (trio-only): the chosen `β₀` literal lies
inside the CERT_Arb enclosure `[beta0_lo, beta0_hi]`.** Ties this file's `β₀` to
the `Wall256_Scaffold` certified interval. Numeric bookkeeping only; proves
NOTHING about the SU(3) integral. -/
theorem beta0_in_cert : Beta0Certified β₀ := by
  refine ⟨?_, ?_⟩ <;> norm_num [beta0_lo, beta0_hi, β₀]

/-! ### The honest version of the requested `closes_surface_1`

The request asked for a `closes_surface_1` theorem "conditional on the 2 lemmas".
Naming anything `closes_surface_1` here would OVERSTATE: discharging the two Weyl
lemmas does NOT close Surface #1. Two independent gaps remain:

  * **More open lattice inputs.** Per `Wall256Scaffold.strong_coupling_decay_of_
    open_inputs`, `w1 < 1/7` is only ONE of THREE open inputs; the lattice decay
    also needs `hOS` (the Osterwalder–Seiler Ursell/cluster step) and `h_bridge`
    (the Brydges–Federbush KP ⟹ geometric clustering step), BOTH still OPEN.
  * **Lattice ≠ Clay.** Even with all three, the conclusion is an abstract
    LATTICE two-point decay shape — necessary-not-sufficient for the continuum
    Yang–Mills mass gap (Surface #1). It is NOT a continuum gap and NOT SU(2).

So the deliverable below makes ALL the remaining open inputs explicit and is named
for what it is — a conditional lattice reduction, NOT a closure. Surface #1 and
the YM tower stay OPEN. -/

/-- **CONDITIONAL lattice reduction (the honest `closes_surface_1`).** Given the
two OPEN Weyl lemmas (`h_eq`, `h_lt` ⟹ `w1 β₀ < 1/7`) AND the two further OPEN
lattice inputs of the strong-coupling analysis — `hOS` (Osterwalder–Seiler
Ursell/cluster) and `h_bridge` (Brydges–Federbush KP ⟹ clustering) — together with
a polymer entropy count `N n ≤ 7ⁿ`, the abstract two-point decay shape follows by
threading them through `Wall256Scaffold.strong_coupling_decay_of_open_inputs`.
Proves NO gap: the entire content is the four open inputs; `corr`/`sep` are
ABSTRACT. LATTICE only; NOT Clay; does NOT close Surface #1; YM stays Open. -/
theorem lattice_decay_of_weyl_lemmas
    {E : Type*} (corr sep : E → E → ℝ) (C ρ : ℝ) {N a : ℕ → ℝ}
    (hN0 : ∀ n, 0 ≤ N n) (hN : ∀ n, N n ≤ (7 : ℝ) ^ n)
    (I : ℤ → ℝ → ℝ) (h_eq : w1_eq_weyl I) (h_lt : w1_weyl_beta0_lt I)
    (hOS : w1 β₀ < 1 / 7 → TruncatedActivityBound a)
    (h_bridge : Summable (fun n : ℕ => N n * a n) →
        0 < ρ ∧ ρ < 1 ∧ ∀ x y, |corr x y| ≤ C * ρ ^ (sep x y)) :
    ∃ Δ : ℝ, 0 < Δ ∧ ∀ x y, |corr x y| ≤ C * Real.exp (-Δ * sep x y) :=
  strong_coupling_decay_of_open_inputs corr sep C ρ (w1 β₀) hN0 hN
    (w1_beta0_lt_seventh I h_eq h_lt) hOS h_bridge

end TheoremaAureum.Towers.YM.Hw1Surface

-- **VERIFICATION (direct-lean bypass; pin v4.12.0 unresolved, do NOT run `lake env`):**
-- #print axioms TheoremaAureum.Towers.YM.Hw1Surface.w1_beta0_lt_seventh       -- classical trio
-- #print axioms TheoremaAureum.Towers.YM.Hw1Surface.w1_eq_weyl_of_closedForm  -- classical trio
-- #print axioms TheoremaAureum.Towers.YM.Hw1Surface.cert_value_lt_seventh     -- classical trio
-- #print axioms TheoremaAureum.Towers.YM.Hw1Surface.beta0_in_cert             -- classical trio
-- #print axioms TheoremaAureum.Towers.YM.Hw1Surface.lattice_decay_of_weyl_lemmas -- classical trio
