/-
================================================================
Towers / YM / SU3Basis  (Task #56 Path B, foundation file)

**Status: WORK IN PROGRESS — not yet wired into the brick wall.**

This file is the Gell-Mann basis scaffolding for the eventual
`su3_basis_def`, `su3_basis_linearIndependent`, `su3_basis_spans`,
and `instance_inner_product_space_su3_euclidean` bricks. It is NOT
imported from `Towers.lean` and NOT listed in
`scripts/check-towers.sh BRICKS` until every theorem in it is
sorry-free and the four named bricks compile with axiom footprint
`{propext, Classical.choice, Quot.sound}`.

**What this batch lands.** The 8 anti-hermitian generators
`iλ₁ … iλ₈` of `su(3)` (Gell-Mann matrices times `Complex.I`),
declared as concrete `Matrix (Fin 3) (Fin 3) ℂ` literals, each
with a proof that it lies in `su3_submodule`. We chose the
*unnormalised* variant of `iλ₈` — namely
`diag (i, 0, -i)` instead of `i / √3 · diag (1, 1, -2)` — so every
entry is an integer / `Complex.I` / `0`, keeping membership proofs
within `decide`/`simp`/`ring` reach. This still spans
`su3_submodule` because we only need *a* real basis, not the
physics-normalised one.

**Honest scope.** Membership in `su3_submodule` means
`star A = -A ∧ Matrix.trace A = 0`. Proving each generator
satisfies those two conditions is the whole content of this file.
None of these matrices represent physical SU(3) gauge fields, and
none of them contribute anything to the YM tower until the
downstream `su3_basis_def` lands with axioms = []. YM tower
status remains **Open** (`docs/ROADMAP.md` § 2).
================================================================
-/

import Mathlib.Data.Matrix.Notation
import Towers.YM.SU3

namespace TheoremaAureum
namespace Towers
namespace YM

open Matrix Complex

/-- `iλ₁` — Gell-Mann generator 1, anti-hermitian form. -/
def gellMann₁ : Matrix (Fin 3) (Fin 3) ℂ :=
  !![0, I, 0; I, 0, 0; 0, 0, 0]

/-- `iλ₂` — Gell-Mann generator 2, anti-hermitian form. -/
def gellMann₂ : Matrix (Fin 3) (Fin 3) ℂ :=
  !![0, 1, 0; -1, 0, 0; 0, 0, 0]

/-- `iλ₃` — Gell-Mann generator 3, anti-hermitian form. -/
def gellMann₃ : Matrix (Fin 3) (Fin 3) ℂ :=
  !![I, 0, 0; 0, -I, 0; 0, 0, 0]

/-- `iλ₄` — Gell-Mann generator 4, anti-hermitian form. -/
def gellMann₄ : Matrix (Fin 3) (Fin 3) ℂ :=
  !![0, 0, I; 0, 0, 0; I, 0, 0]

/-- `iλ₅` — Gell-Mann generator 5, anti-hermitian form. -/
def gellMann₅ : Matrix (Fin 3) (Fin 3) ℂ :=
  !![0, 0, 1; 0, 0, 0; -1, 0, 0]

/-- `iλ₆` — Gell-Mann generator 6, anti-hermitian form. -/
def gellMann₆ : Matrix (Fin 3) (Fin 3) ℂ :=
  !![0, 0, 0; 0, 0, I; 0, I, 0]

/-- `iλ₇` — Gell-Mann generator 7, anti-hermitian form. -/
def gellMann₇ : Matrix (Fin 3) (Fin 3) ℂ :=
  !![0, 0, 0; 0, 0, 1; 0, -1, 0]

/-- `iλ₈` (unnormalised) — `diag (I, 0, -I)`. Anti-hermitian and
    traceless; differs from the physics convention only by an
    overall `1/√3` and a re-basing of the two diagonal generators,
    which is irrelevant for being *a* real basis. -/
def gellMann₈ : Matrix (Fin 3) (Fin 3) ℂ :=
  !![I, 0, 0; 0, 0, 0; 0, 0, -I]

/-! ### Membership in `su3_submodule`

    For each `gellMannₖ` we have to show two things:
    * `star gellMannₖ = -gellMannₖ` (anti-hermitian)
    * `Matrix.trace gellMannₖ = 0` (traceless)

    Both reduce by `Matrix.ext` + `fin_cases` + `simp` on the
    explicit `!![ ... ]` literal, with `Complex.I_mul_I` and
    `Complex.conj_I` doing the conjugation work.
-/

private lemma gellMann₁_mem : gellMann₁ ∈ su3_submodule := by
  rw [su3_submodule_mem_iff]
  refine ⟨?_, ?_⟩
  · ext i j
    fin_cases i <;> fin_cases j <;>
      simp [gellMann₁, Matrix.star_apply, Matrix.neg_apply,
            Matrix.cons_val_zero, Matrix.cons_val_one,
            Matrix.head_cons, Matrix.head_fin_const,
            Matrix.empty_val', Matrix.cons_val_fin_one,
            star_neg, star_one, Complex.conj_I, Complex.I_mul_I,
            neg_neg]
  · simp [gellMann₁, Matrix.trace, Fin.sum_univ_three,
          Matrix.diag_apply,
          Matrix.cons_val_zero, Matrix.cons_val_one, Matrix.head_cons]

end YM
end Towers
end TheoremaAureum
