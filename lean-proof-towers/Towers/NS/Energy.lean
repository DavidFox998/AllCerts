/-
================================================================
Towers / NS / Energy  (Task #56 Path B, batch 7 / Track B)

**Energy-decomposition schema for Navier-Stokes.** Five bricks
that introduce a named split `total = kinetic + potential` on the
Task #51 NS placeholder schema (`VelocityField`, `H1Norm`,
`HasFiniteEnergy` from `Towers.NS.EnergyIneq`) and two combinators
about how the (placeholder) total energy evolves under a flow.

### What this file adds

  1. `kinetic_energy u t := ½ · H1Norm u t ^ 2` — the canonical
     `½ ‖u‖²` shape on the placeholder H¹-norm.
  2. `potential_energy u t := 0` — explicit zero placeholder (real
     NS has no external potential term; this slot is reserved for
     forcing / pressure-work in a future batch).
  3. `total_energy u t := kinetic_energy u t + potential_energy u t`
     — names the decomposition target.
  4. `energy_nonincreasing_flow` — combinator. Given a flow `Φ`
     between velocity fields and a pointwise hypothesis that
     `H1Norm` does not grow along `Φ`, conclude `total_energy`
     also does not grow. Uses `H1Norm_nonneg` (Task #56 brick).
  5. `finite_energy_persistent` — combinator. Given an initial
     finite-energy field and a pointwise bound `‖Φ u₀ 0 x‖ ≤ M`,
     conclude `HasFiniteEnergy (Φ u₀)`. Uses
     `HasFiniteEnergy_of_bounded_zero` (Task #62 brick).

### Honest scope

What this file claims:

  * `kinetic_energy` is `½ · (placeholder H¹-norm) ²` — real
    arithmetic on the Task #51 placeholder. NOT the L² kinetic
    energy `½ ∫ |u|² dx`.
  * `potential_energy` is the literal zero function — explicit
    placeholder for the NS forcing / pressure-work slot. NOT a
    physically meaningful potential.
  * `energy_decomposition` is `total = kinetic + potential` by
    construction (definitional).
  * `energy_nonincreasing_flow` is the *combinator* "if pointwise
    `H1Norm` does not grow under `Φ`, then `total_energy` does
    not grow under `Φ`". The hypothesis is a real quantified
    inequality; the conclusion follows by `mul_self_nonneg` on
    the H1Norm difference.
  * `finite_energy_persistent` is the *combinator* "if `Φ u₀` is
    pointwise bounded at `t = 0`, then `HasFiniteEnergy (Φ u₀)`".

What this file does NOT claim:

  * The Leray-Hopf energy inequality
    `½ ‖u(t)‖_{L²}² + ν ∫₀ᵗ ‖∇u‖_{L²}² ds ≤ ½ ‖u₀‖_{L²}²`;
  * Any actual NS flow `Φ` (no time-evolution operator is
    constructed; `Φ` is an arbitrary parameter);
  * Persistence of the *true* H¹ norm under the NS evolution;
  * NS global regularity, weak-strong uniqueness, or any other
    Clay-style result.

The NS tower status remains **Open** (`docs/ROADMAP.md` § 3).
================================================================
-/

import Towers.NS.EnergyIneq

namespace TheoremaAureum
namespace Towers
namespace NS
namespace Energy

open TheoremaAureum.Towers.NS

/-! ### Schema defs -/

/-- **`kinetic_energy u t`** — placeholder kinetic energy
`½ · H1Norm u t ²`. Uses the Task #51 placeholder `H1Norm`
(Euclidean norm of `u t 0`), so this is NOT the L² kinetic energy
`½ ∫ |u(t,x)|² dx`. -/
noncomputable def kinetic_energy (u : VelocityField) (t : ℝ) : ℝ :=
  (1 / 2) * (H1Norm u t) ^ 2

/-- **`potential_energy u t`** — explicit zero placeholder. Real
NS has no external potential term; this slot reserves the spot
for a future forcing / pressure-work contribution. -/
def potential_energy (_u : VelocityField) (_t : ℝ) : ℝ := 0

/-- **`total_energy u t`** — placeholder total energy as the named
sum `kinetic + potential`. By construction equals `kinetic_energy`
in this batch because `potential_energy = 0`. -/
noncomputable def total_energy (u : VelocityField) (t : ℝ) : ℝ :=
  kinetic_energy u t + potential_energy u t

/-! ### Bricks (5) — one per user-spec item -/

/-- **Brick 1 (`kinetic_energy_def`).** Pins
`kinetic_energy u t = ½ · H1Norm u t ²` by reflexivity. Named
unfolder for downstream lemmas that want to rewrite by name. -/
theorem kinetic_energy_def (u : VelocityField) (t : ℝ) :
    kinetic_energy u t = (1 / 2) * (H1Norm u t) ^ 2 := rfl

/-- **Brick 2 (`potential_energy_def`).** Pins
`potential_energy u t = 0` by reflexivity, making the explicit-
placeholder nature of this slot citable. -/
theorem potential_energy_def (u : VelocityField) (t : ℝ) :
    potential_energy u t = 0 := rfl

/-- **Brick 3 (`energy_decomposition`).** The named
`total = kinetic + potential` split. With `potential_energy = 0`
in this batch the right-hand side simplifies to `kinetic_energy`
alone, but the decomposition shape is structural and survives any
future non-zero `potential_energy`. -/
theorem energy_decomposition (u : VelocityField) (t : ℝ) :
    total_energy u t = kinetic_energy u t + potential_energy u t := rfl

/-- **Brick 4 (`energy_nonincreasing_flow`).** Combinator. Given a
flow `Φ : VelocityField → VelocityField` and a pointwise hypothesis
that `H1Norm` does not grow along `Φ` at the same time `t`, the
total energy does not grow either. The hypothesis is a real
quantified inequality on the Task #51 placeholder `H1Norm`; the
conclusion follows by monotonicity of `x ↦ x²` on the non-negative
reals via `H1Norm_nonneg`. NOT the Leray-Hopf energy inequality. -/
theorem energy_nonincreasing_flow
    (Φ : VelocityField → VelocityField) (u : VelocityField) (t : ℝ)
    (h : H1Norm (Φ u) t ≤ H1Norm u t) :
    total_energy (Φ u) t ≤ total_energy u t := by
  unfold total_energy kinetic_energy potential_energy
  have hΦ_nn : 0 ≤ H1Norm (Φ u) t := H1Norm_nonneg (Φ u) t
  have hsq : (H1Norm (Φ u) t) ^ 2 ≤ (H1Norm u t) ^ 2 :=
    pow_le_pow_left hΦ_nn h 2
  have hhalf : (0 : ℝ) ≤ 1 / 2 := by norm_num
  have := mul_le_mul_of_nonneg_left hsq hhalf
  linarith

/-- **Brick 5 (`finite_energy_persistent`).** Combinator. Given an
initial finite-energy field `u₀` and a pointwise spatial bound on
the post-flow field `Φ u₀` at `t = 0`, conclude `HasFiniteEnergy
(Φ u₀)`. The hypothesis is a real quantified inequality on the
post-flow field; the conclusion uses the Task #62 packager
`HasFiniteEnergy_of_bounded_zero`. NOT a real persistence result
for the NS evolution — `Φ` is an arbitrary parameter, no time-
evolution operator is constructed. -/
theorem finite_energy_persistent
    (Φ : VelocityField → VelocityField) (u₀ : VelocityField)
    (_h0 : HasFiniteEnergy u₀) (M : ℝ)
    (hM : ∀ x : EuclideanSpace ℝ (Fin 3), ‖(Φ u₀) 0 x‖ ≤ M) :
    HasFiniteEnergy (Φ u₀) :=
  HasFiniteEnergy_of_bounded_zero (Φ u₀) M hM

end Energy
end NS
end Towers
end TheoremaAureum
