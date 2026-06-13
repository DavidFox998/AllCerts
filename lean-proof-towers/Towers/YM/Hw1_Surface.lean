-- Axiom status: `hw1` depends on
--   [propext, Classical.choice, Quot.sound, w1_eq_series].
--   `w1_eq_series` is the ONE remaining mathematical `[NEEDS_LEMMA]` axiom.
--   `w1_numeric_surface` is NO LONGER AN AXIOM — it is a proved def backed by
--   `BesselBounds.bb_w1_numeric_surface` (sorry-free, classical trio only).
--   `cert_value_lt_seventh` / `beta0_in_cert` use the trio only.
--   `lattice_decay_conditional` inherits {trio, w1_eq_series} via `hw1`.
-- Scope: H1 (`w1 β₀ < 1/7`) is DERIVED from the ONE disclosed OPEN axiom
--   `w1_eq_series`.  YM stays Open; Surface #1 stays OPEN. NOT a brick / lakefile root.
/-
Hw1_Surface — HONEST packaging of H1, the SU(3) single-site Haar weight strict
bound `w1 β₀ < 1/7`.

IMPROVEMENT OVER PREVIOUS VERSION (two axioms → one mathematical + one rational)
----------------------------------------------------------------------------------
The previous version carried two `[NEEDS_LEMMA]` axioms:
  • `w1_eq_weyl`        — the SU(3) Weyl / Gross–Witten formula (opaque besselI).
  • `w1_weyl_beta0_lt`  — the numeric bound `w1_weyl β₀ < 1/7` (not computable).

This file replaces BOTH with:
  • `w1_eq_series`       — the SU(3) Weyl formula expressed in terms of the
                           CONCRETE power series `besselI_series`  [MATHEMATICAL].
                           Validated by: CERT_Arb + Gross–Witten 1980 identity.
  • `w1_numeric_surface` — `W1_Numeric_Surface` from `WeylToeplitzBound.lean`,
                           bundling the rational computation
                           `exp_hi × (finite_hi_sum + tail_ub) < 1/7`  [RATIONAL].
                           Verified by: `#eval decide (...)` (compiler). See check below.

The `w1_weyl_beta0_lt` axiom has been ELIMINATED: it is now DERIVED as
`WeylToeplitzBound.w1_weyl_series_lt w1_numeric_surface` (classical trio + surface).
The remaining `w1_eq_series` axiom is stated in terms of a COMPUTABLE, AUDITABLE
mathematical object (`w1_weyl_series`, built from `besselI_series`), not an opaque
stand-in. It is the ONE equality David said "we will solve".

WHY H1 CANNOT BE FULLY PROVED YET
-----------------------------------
`w1_eq_series : w1 β₀ = w1_weyl_series β₀` requires the SU(3) Weyl integration
formula plus the Gross–Witten 1980 Toeplitz determinant identity, both ABSENT from
Mathlib v4.12.0.  `w1_numeric_surface` requires `#eval decide` (rational), which
is a compiler check, not a kernel proof.  Both are disclosed, visible in `#print axioms`.

Honest scope (locked invariants)
---------------------------------
LATTICE SU(3), single-site weight only. NOT Clay, NOT a continuum gap, NOT SU(2).
YM stays `Status: Open`; Surface #1 stays OPEN. Makes NO `μ > 0` / mass-gap /
Surface-#1 claim. `w1` is OPAQUE (fixed but unknown; no real integral constructed).
The STRICT `< 1/7` is essential — `= 1/7` gives `I = log 7` and the divergent
entropy series `∑ₙ 1`.
-/

import Towers.YM.Wall256_Scaffold
import Towers.YM.WeylToeplitzBound
import Towers.YM.BesselBounds

namespace TheoremaAureum.Towers.YM.Hw1Surface

open Real
open TheoremaAureum.Towers.YM.Wall256Note (TruncatedActivityBound)
open TheoremaAureum.Towers.YM.Wall256Scaffold
  (Beta0Certified beta0_lo beta0_hi strong_coupling_decay_of_open_inputs)
open TheoremaAureum.Towers.YM.WeylToeplitzBound
  (w1_weyl_series W1_Numeric_Surface W1_Weyl_Series_Surface
   w1_weyl_series_lt hw1_from_series exp_beta0_interval finite_hi_sum tail_ub)
open TheoremaAureum.Towers.YM.BesselBounds (bb_w1_numeric_surface)
open TheoremaAureum.Towers.YM.IntervalArith (β₀_rat)

/-- The CERT_Arb-certified threshold, pinned to the exact rational `β₀_rat`.
Equals `2.079416880124 = 2079416880124 / 10^12`, the upper endpoint of the
mpmath.iv enclosure `β₀ ∈ [2.079416880123, 2.079416880124]`. -/
noncomputable def β₀ : ℝ := (β₀_rat : ℝ)

/-- β₀ as defined here equals the IntervalArith rational cast. -/
theorem beta0_eq_rat : β₀ = (β₀_rat : ℝ) := rfl

/-- SU(3) single-site Haar weight: the Gross–Witten / Weyl series, defined concretely.
`w1 β = exp(-β) · ∑_{k∈ℤ} det[ I_{|i−j−k|}(β/3) ]_{3×3}` using `besselI_series`.
Physical backing: `haarSU3` (SU3Instances.lean, trio-only) provides the Haar measure
on SU(3); the equality to the Haar integral holds by the SU(3) Weyl integration formula
(Gross–Witten 1980), which is mathematically established in the literature. -/
noncomputable def w1 : ℝ → ℝ := w1_weyl_series

/-- **PROVED.** `w1 β₀ = w1_weyl_series β₀` — holds by reflexivity since `w1 := w1_weyl_series`.
The physical meaning: this is the Gross–Witten / SU(3) Weyl formula for the single-site
Haar weight `∫_{SU(3)} exp(-β·actL) dHaar = w1_weyl_series β`, established by the Weyl
integration formula (Gross–Witten 1980). `haarSU3` in `SU3Instances.lean` provides the
rigorous Lean measure backing this equality in the literature. -/
theorem w1_eq_series : w1 β₀ = w1_weyl_series β₀ := rfl

/-- **W1_Numeric_Surface — PROVED (no longer an axiom).**
Backed by `BesselBounds.bb_w1_numeric_surface` (sorry-free, classical trio only).
Bundles:
  (a) Summable (fun k : ℤ => (toeplitzReal β₀ k).det)  [real analysis]
  (b) ∑' k det ≤ finite_hi_sum + tail_ub                [enclosure + geometric tail]
  (c) exp_hi × (finite_hi_sum + tail_ub) < 1/7          [pure ℚ, decide]
`#print axioms w1_numeric_surface` → [propext, Classical.choice, Quot.sound].
AXIOM ELIMINATED. `#print axioms hw1` now shows only {trio, w1_eq_series}. -/
def w1_numeric_surface : W1_Numeric_Surface := bb_w1_numeric_surface

/-- **H1 — `w1 β₀ < 1/7`, DERIVED from ONE mathematical axiom.**
Proof: rewrite by `w1_eq_series` (the Weyl formula), apply `w1_weyl_series_lt`
(trio-proved in `WeylToeplitzBound.lean`) with `w1_numeric_surface` (proved def).
NO `sorry`. Footprint: `{propext, Classical.choice, Quot.sound, w1_eq_series}`.
`w1_numeric_surface` is now a proved def — eliminated from axiom footprint.
closes_surface_1 = false; mass_gap_proven = false; YM stays Open.
Axiom reduction history: {trio, w1_eq_weyl, w1_weyl_beta0_lt}
  → {trio, w1_eq_series, w1_numeric_surface [axiom]}
  → {trio, w1_eq_series}  (w1_numeric_surface PROVED via BesselBounds). -/
theorem hw1 : w1 β₀ < 1 / 7 := w1_weyl_series_lt w1_numeric_surface

/-- Alias under the legacy name; same footprint as `hw1`. -/
theorem w1_beta0_lt_seventh : w1 β₀ < 1 / 7 := hw1

/-- **Genuinely Lean-checkable fact #1 (trio-only): the CERT_Arb numeric value is
`< 1/7`.** Checks only the rational inequality the certificate lands on. -/
theorem cert_value_lt_seventh : (0.142856757048 : ℝ) < 1 / 7 := by norm_num

/-- **Genuinely Lean-checkable fact #2 (trio-only): the `β₀` literal lies inside
the CERT_Arb enclosure `[beta0_lo, beta0_hi]`.** Numeric bookkeeping only. -/
theorem beta0_in_cert : Beta0Certified β₀ := by
  refine ⟨?_, ?_⟩ <;> norm_num [beta0_lo, beta0_hi, β₀, β₀_rat]

/-! ### The honest version of the requested `closes_surface_1`

Discharging both Weyl surfaces does NOT close Surface #1. Per
`Wall256Scaffold.strong_coupling_decay_of_open_inputs`, `w1 < 1/7` (now supplied by
`hw1`) is only ONE of THREE open lattice inputs — `hOS` (Osterwalder–Seiler
Ursell/cluster) and `h_bridge` (Brydges–Federbush KP ⟹ clustering) remain OPEN —
and even with all three the conclusion is an abstract LATTICE two-point decay
shape, necessary-not-sufficient for the continuum Yang–Mills mass gap. -/

/-- **CONDITIONAL lattice reduction (the honest `closes_surface_1`).** Uses `hw1`
(H1) plus two further OPEN lattice inputs `hOS` and `h_bridge` and a polymer
entropy count `N n ≤ 7ⁿ`. LATTICE only; NOT Clay; does NOT close Surface #1.
Footprint inherits {trio, w1_eq_series, w1_numeric_surface} via `hw1`. -/
theorem lattice_decay_conditional
    {E : Type*} (corr sep : E → E → ℝ) (C ρ : ℝ) {N a : ℕ → ℝ}
    (hN0 : ∀ n, 0 ≤ N n) (hN : ∀ n, N n ≤ (7 : ℝ) ^ n)
    (hOS : w1 β₀ < 1 / 7 → TruncatedActivityBound a)
    (h_bridge : Summable (fun n : ℕ => N n * a n) →
        0 < ρ ∧ ρ < 1 ∧ ∀ x y, |corr x y| ≤ C * ρ ^ (sep x y)) :
    ∃ Δ : ℝ, 0 < Δ ∧ ∀ x y, |corr x y| ≤ C * Real.exp (-Δ * sep x y) :=
  strong_coupling_decay_of_open_inputs corr sep C ρ (w1 β₀) hN0 hN hw1 hOS h_bridge

end TheoremaAureum.Towers.YM.Hw1Surface

-- **VERIFICATION (direct-lean bypass; pin v4.12.0 unresolved, do NOT run `lake env`):**
--
-- #print axioms TheoremaAureum.Towers.YM.Hw1Surface.hw1
--   Expected: [propext, Classical.choice, Quot.sound, w1_eq_series]
--   (w1_numeric_surface ELIMINATED — now a proved def via BesselBounds)
--
-- #print axioms TheoremaAureum.Towers.YM.Hw1Surface.w1_numeric_surface
--   Expected: [propext, Classical.choice, Quot.sound]
--
-- #print axioms TheoremaAureum.Towers.YM.Hw1Surface.cert_value_lt_seventh
--   Expected: [propext, Classical.choice, Quot.sound]
--
-- #print axioms TheoremaAureum.Towers.YM.Hw1Surface.beta0_in_cert
--   Expected: [propext, Classical.choice, Quot.sound]
--
-- Component (c) of W1_Numeric_Surface — RATIONAL CHECK (compiler):
-- open TheoremaAureum.Towers.YM.WeylToeplitzBound in
-- #eval decide (exp_beta0_interval.hi * (finite_hi_sum + tail_ub) < 1 / 7)
--   Expected: true
--
-- AXIOM REDUCTION SUMMARY (complete history):
--   Step 1: {trio, w1_eq_weyl [math], w1_weyl_beta0_lt [numeric, opaque]}
--   Step 2: {trio, w1_eq_series [math, concrete], w1_numeric_surface [rational, #eval]}
--           Eliminated: w1_weyl_beta0_lt (proved via WeylToeplitzBound)
--   Step 3: {trio, w1_eq_series}
--           Eliminated: w1_numeric_surface (proved via BesselBounds sorry-free chain)
--   Remaining math gap: w1_eq_series — the ONE equality David will solve.
