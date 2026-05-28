/-
================================================================
Towers / YM / PeterWeylQuadratic  (Task #157 — tighter envelope)

**Tighter envelope bricks for the SU(3) Peter-Weyl heat-kernel
series.** Two new sorry-free bricks that strengthen the slack
bounds shipped in Batch 19.1p-redux-a (`Towers/YM/PeterWeyl.lean`):

  1. `Casimir_SU3_explicit_real_ge_quadratic`
       (already landed in `Towers/YM/Casimir.lean`, Batch 156 file
       1; the bound is `¾·(m+n)² + 3(m+n) ≤ C₂`, sharper than the
       linear `(m+n) ≤ C₂` from `PeterWeyl.lean` Brick 1).

  2. `Weyl_dim_SU3_explicit_real_le_cubic`  *(new, this file)*
       `(Weyl_dim_SU3_explicit (m,n) : ℝ) ≤ ((m+n : ℝ) + 2)^3`
       — real-valued cubic upper bound on the SU(3) Weyl
       dimension, in the `(m+n)` antidiagonal shape. Companion to
       Batch 156.2 file 2's `dim_cubic_bound` in
       `Towers/YM/WeylDim.lean` (which targets the integer-valued
       `dim_SU3 m n` definition and gives `≤ 8·(m+n+1)^3`).
       Both bounds are real and coexist; this one is the
       PeterWeyl-shape (`Weyl_dim_SU3_explicit` over `Weyl_label`),
       not the standalone-integer shape.

  3. `PeterWeyl_Summable_SU3_quadratic`  *(headline, this file)*
       Same conclusion as Batch 19.1p-redux-a's
       `PeterWeyl_Summable_SU3` — `Summable` for every `β > 0` —
       but the proof routes through the **quadratic** Casimir
       bound from `Towers/YM/Casimir.lean` instead of the linear
       bound. Concretely we keep the linear `3(m+n)` part of the
       quadratic lower bound (dropping the nonneg `¾(m+n)²` term),
       yielding `exp(-β·C₂) ≤ exp(-(3β)·m) · exp(-(3β)·n)` — a
       factor-of-3 sharper decay rate than the `PeterWeyl_Summable_SU3`
       envelope. The Peter-Weyl summand is then squeezed against
       the same `summable_poly_succ_exp_neg_real` 1-D envelope from
       Batch 19.1p-redux-a, now at the sharper rate `3β > 0`.

### Why this file exists

`Casimir_SU3_explicit_real_ge_linear` and
`Weyl_dim_SU3_explicit_real_le_poly` in Batch 19.1p-redux-a were
shipped as intentionally-slack envelope bounds (tripwires noted
in `docs/CHANGELOG.md`). The downstream Varadhan small-`t`
asymptotic in `Towers/YM/PeterWeylHeatVaradhan.lean` (and the
in-progress off-diagonal heat-kernel work) needs the **quadratic**
Casimir bound to recover the small-`t` decay exponent
`exp(-c/t)`, and any quantitative spectral-gap work on top of
this needs both tightenings. The new bricks land them in
PeterWeyl shape so the downstream files can `apply` them without
re-routing through `Towers/YM/Casimir.lean` and the standalone
`Towers/YM/WeylDim.lean`.

### Honest scope (locked)

The three bricks above are real-analysis facts about the SU(3)
Peter-Weyl spectral series at the identity. They are NOT:
  * a constructive 4D pure-Yang-Mills measure,
  * an Osterwalder-Schrader Hilbert space reconstruction,
  * a mass-gap lower bound on any YM Hamiltonian,
  * the Varadhan / Molchanov small-`t` heat-kernel asymptotic
    (that is parked in `Towers/YM/PeterWeylHeatVaradhan.lean`,
    strip form only).

**The old Batch 19.1p-redux-a bricks (`_real_ge_linear`,
`_real_le_poly`, `PeterWeyl_Summable_SU3`) are left in place,
unmodified.** This file is purely additive; no deletions.

YM tower stays `Status: Open` in `docs/ROADMAP.md` § 2. Surface
#2 stays OPEN; `kotecky_preiss_criterion` remains a `sorry` in
`Towers/Attempts/ClusterExpansion.lean`. mathlib v4.12.0 only.
Axiom footprint: subset of mathlib's classical trio
`{propext, Classical.choice, Quot.sound}`.
================================================================
-/

import Towers.YM.Casimir

namespace TheoremaAureum
namespace Towers
namespace YM
namespace PeterWeylQuadratic

open TheoremaAureum.Towers.YM.ClusterExpansion
open TheoremaAureum.Towers.YM.PeterWeyl
open TheoremaAureum.Towers.YM.Casimir

/-! ## Brick 1 — Cubic real-valued upper bound on Weyl dim

`(Weyl_dim_SU3_explicit (m,n) : ℝ) ≤ ((m+n : ℝ) + 2)^3`.

Proof: all comparison at the ℕ level. The polynomial inequality
`(m+1)(n+1)(m+n+2) ≤ 2 · (m+n+2)^3` follows from
`(m+1)(n+1) = mn + m + n + 1 ≤ (m+n+2)^2` (AM-GM with slack since
`(m+n+2)^2 = (m+1)^2 + 2(m+1)(n+1) + (n+1)^2 ≥ 2(m+1)(n+1)`).
Then `Nat.div_le_of_le_mul` drops the `/2`, and a single
`push_cast; linarith` lands the real-valued statement.

Used by the downstream Varadhan work to control `dim²` against
the antidiagonal `(m+n)^6` (which the new quadratic Casimir
bound's `exp(-β·(m+n)²)` factor can absorb). -/
theorem Weyl_dim_SU3_explicit_real_le_cubic (mn : Weyl_label) :
    (Weyl_dim_SU3_explicit mn : ℝ) ≤ ((mn.1 : ℝ) + mn.2 + 2) ^ 3 := by
  have key_nat :
      Weyl_dim_SU3_explicit mn ≤ (mn.1 + mn.2 + 2) ^ 3 := by
    unfold Weyl_dim_SU3_explicit
    -- (m+1)(n+1)(m+n+2) ≤ 2·(m+n+2)^3, all at ℕ.
    have h1 : (mn.1 + 1) * (mn.2 + 1) * (mn.1 + mn.2 + 2)
                ≤ 2 * (mn.1 + mn.2 + 2) ^ 3 := by
      zify
      nlinarith [sq_nonneg ((mn.1 : ℤ) - mn.2),
                 sq_nonneg ((mn.1 : ℤ) + mn.2 + 2),
                 Int.natCast_nonneg mn.1, Int.natCast_nonneg mn.2]
    exact Nat.div_le_of_le_mul h1
  have hcast : ((Weyl_dim_SU3_explicit mn : ℕ) : ℝ)
                ≤ (((mn.1 + mn.2 + 2 : ℕ) : ℝ)) ^ 3 := by
    exact_mod_cast key_nat
  have hpush : (((mn.1 + mn.2 + 2 : ℕ) : ℝ)) ^ 3
                = ((mn.1 : ℝ) + mn.2 + 2) ^ 3 := by push_cast; ring
  linarith

/-! ## Brick 2 (Headline) — Direct summability via quadratic Casimir

For every `β > 0`, `∑_{(m,n)} dim² · exp(-β · C₂)` is `Summable`,
proved directly via the **quadratic** Casimir lower bound
`¾·(m+n)² + 3(m+n) ≤ C₂` from `Towers/YM/Casimir.lean`. We drop
the nonneg `¾·(m+n)²` term and keep the linear `3(m+n)` part,
yielding the factor-of-3 sharper rate
`exp(-β·C₂) ≤ exp(-(3β)·m) · exp(-(3β)·n)` — versus the rate
`β` produced by the linear Casimir bound consumed by
`PeterWeyl_Summable_SU3`. The squeeze against the per-factor
envelope reuses Batch 19.1p-redux-a's
`summable_poly_succ_exp_neg_real` at rate `3β > 0`. -/
theorem PeterWeyl_Summable_SU3_quadratic {β : ℝ} (hβ : 0 < β) :
    Summable (fun mn : ℕ × ℕ =>
      ((Weyl_dim_SU3_explicit mn : ℝ)) ^ 2 *
        Real.exp (-(β * (Casimir_SU3_explicit mn : ℝ)))) := by
  have h3β : 0 < 3 * β := by linarith
  -- Per-factor 1D envelope at the sharpened rate `3β`.
  have h1d :
      Summable (fun n : ℕ => ((n : ℝ) + 1) ^ 4 * Real.exp (-(3 * β * n))) :=
    summable_poly_succ_exp_neg_real h3β
  set f : ℕ → ℝ := fun n => ((n : ℝ) + 1) ^ 4 * Real.exp (-(3 * β * n))
    with hf_def
  have hf_nonneg : ∀ n, 0 ≤ f n := by
    intro n
    exact mul_nonneg (pow_nonneg (by positivity) _) (Real.exp_pos _).le
  set env : ℕ × ℕ → ℝ := fun mn => f mn.1 * f mn.2 with henv_def
  have henv_nonneg : (0 : ℕ × ℕ → ℝ) ≤ env :=
    fun mn => mul_nonneg (hf_nonneg _) (hf_nonneg _)
  have henv_summable : Summable env := by
    rw [summable_prod_of_nonneg henv_nonneg]
    refine ⟨fun x => ?_, ?_⟩
    · exact h1d.mul_left (f x)
    · have hcong : (fun x : ℕ => ∑' y, env (x, y)) =
          fun x : ℕ => f x * ∑' y, f y := by
        funext x
        simp only [henv_def]
        exact tsum_mul_left
      rw [hcong]
      exact h1d.mul_right _
  -- Pointwise bound: summand ≤ env, routing through the QUADRATIC Casimir.
  have hbound : ∀ mn : ℕ × ℕ,
      (Weyl_dim_SU3_explicit mn : ℝ) ^ 2 *
        Real.exp (-(β * (Casimir_SU3_explicit mn : ℝ))) ≤ env mn := by
    intro mn
    have hdim_nonneg : (0 : ℝ) ≤ (Weyl_dim_SU3_explicit mn : ℝ) :=
      Nat.cast_nonneg _
    -- Reuse the existing degree-4 Weyl-dim bound for the product shape.
    have hdim_sq :
        (Weyl_dim_SU3_explicit mn : ℝ) ^ 2 ≤
          (((mn.1 : ℝ) + 1) ^ 2 * ((mn.2 : ℝ) + 1) ^ 2) ^ 2 :=
      pow_le_pow_left hdim_nonneg (Weyl_dim_SU3_explicit_real_le_poly mn) 2
    -- Quadratic Casimir → linear `3(m+n) ≤ C₂` (drop the ¾(m+n)² term).
    have hcas_q := Casimir_SU3_explicit_real_ge_quadratic mn
    have hsq_nn : 0 ≤ (3 / 4 : ℝ) * ((mn.1 : ℝ) + mn.2) ^ 2 :=
      mul_nonneg (by norm_num) (sq_nonneg _)
    have hcas_lin :
        3 * ((mn.1 : ℝ) + mn.2) ≤ (Casimir_SU3_explicit mn : ℝ) := by
      linarith
    have hexp_bound :
        Real.exp (-(β * (Casimir_SU3_explicit mn : ℝ))) ≤
          Real.exp (-(β * (3 * ((mn.1 : ℝ) + mn.2)))) := by
      apply Real.exp_le_exp.mpr
      have hβmul := mul_le_mul_of_nonneg_left hcas_lin hβ.le
      linarith
    have hexp_split :
        Real.exp (-(β * (3 * ((mn.1 : ℝ) + mn.2)))) =
          Real.exp (-(3 * β * mn.1)) * Real.exp (-(3 * β * mn.2)) := by
      rw [← Real.exp_add]; congr 1; ring
    have hexp_nonneg :
        (0 : ℝ) ≤ Real.exp (-(β * (Casimir_SU3_explicit mn : ℝ))) :=
      (Real.exp_pos _).le
    have hpoly_sq_eq :
        (((mn.1 : ℝ) + 1) ^ 2 * ((mn.2 : ℝ) + 1) ^ 2) ^ 2 =
          ((mn.1 : ℝ) + 1) ^ 4 * ((mn.2 : ℝ) + 1) ^ 4 := by ring
    have hstep1 :
        (Weyl_dim_SU3_explicit mn : ℝ) ^ 2 *
            Real.exp (-(β * (Casimir_SU3_explicit mn : ℝ))) ≤
          (((mn.1 : ℝ) + 1) ^ 2 * ((mn.2 : ℝ) + 1) ^ 2) ^ 2 *
            Real.exp (-(β * (Casimir_SU3_explicit mn : ℝ))) :=
      mul_le_mul_of_nonneg_right hdim_sq hexp_nonneg
    have hstep2 :
        (((mn.1 : ℝ) + 1) ^ 2 * ((mn.2 : ℝ) + 1) ^ 2) ^ 2 *
            Real.exp (-(β * (Casimir_SU3_explicit mn : ℝ))) ≤
          (((mn.1 : ℝ) + 1) ^ 2 * ((mn.2 : ℝ) + 1) ^ 2) ^ 2 *
            Real.exp (-(β * (3 * ((mn.1 : ℝ) + mn.2)))) := by
      apply mul_le_mul_of_nonneg_left hexp_bound
      exact sq_nonneg _
    have hstep3 :
        (((mn.1 : ℝ) + 1) ^ 2 * ((mn.2 : ℝ) + 1) ^ 2) ^ 2 *
            Real.exp (-(β * (3 * ((mn.1 : ℝ) + mn.2)))) = env mn := by
      simp only [henv_def, hf_def, hpoly_sq_eq, hexp_split]
      ring
    linarith [hstep1.trans (hstep2.trans hstep3.le)]
  -- Squeeze.
  have hsum_nonneg : ∀ mn : ℕ × ℕ, 0 ≤
      (Weyl_dim_SU3_explicit mn : ℝ) ^ 2 *
        Real.exp (-(β * (Casimir_SU3_explicit mn : ℝ))) := fun mn =>
    mul_nonneg (sq_nonneg _) (Real.exp_pos _).le
  exact Summable.of_nonneg_of_le hsum_nonneg hbound henv_summable

end PeterWeylQuadratic
end YM
end Towers
end TheoremaAureum
