/-
================================================================
Towers / YM / RiemannianGeometry  (Task #170 — STAND-IN
SU(3) bi-invariant Riemannian distance for the off-diagonal
Varadhan / Molchanov heat-kernel asymptotic
  `K_t(x, e) ≲ t^{-d/2} · exp(-d_g(x, e)² / (4t))`.)

**STATUS: Open.** This file ships an **honest stand-in** for the
SU(3) bi-invariant Riemannian distance
`d_{SU(3)} : SU(3) × SU(3) → ℝ` that the Varadhan small-`t`
off-diagonal asymptotic requires. The real distance comes from
the bi-invariant Killing-form metric on SU(3); neither
`Mathlib.Geometry.Manifold.LieGroup.BiInvariantMetric` nor an
`(SU3, Dist)` instance derived from the Killing form exists in
mathlib v4.12.0 (checked: no file
`Mathlib/Geometry/Manifold/.../BiInvariant*.lean`, no
`Dist (Matrix.specialUnitaryGroup …)` instance).

Concretely:

  `d_SU3 g h := 0`   (placeholder; collapses everything to the
                      diagonal `g = e` regime)

  `IsPseudoDistOnSU3 d` — a `Prop` recording the three
                          pseudo-distance properties of a genuine
                          bi-invariant distance on SU(3) that we
                          *can* state without the absent Submonoid-
                          multiplication elaboration plumbing:
                          symmetry, nonnegativity, vanishing on
                          the diagonal. Bi-invariance under left /
                          right group action `d (k·g) (k·h) = d g h`
                          is *intentionally omitted* — `SU3` is the
                          carrier of the `Matrix.specialUnitaryGroup`
                          `Submonoid`, and the relevant `Mul`
                          instance is not in scope without pulling
                          in additional Submonoid plumbing that
                          would balloon this stand-in beyond
                          proportion to its honest scope (which is
                          to make `d_SU3` available as a *symbol*
                          to the geometric Varadhan-shape brick in
                          `PeterWeylHeatVaradhan.lean`).

  `d_SU3_isPseudoDist`   — inhabitedness witness: the stand-in
                            `d_SU3` satisfies the predicate
                            (vacuously, since `d_SU3 ≡ 0`). This
                            proves the predicate is *consistent*,
                            NOT that we have constructed the
                            real Killing-form distance.

### Drift from the Task #170 brief (honest, locked)

The Task #170 "Done looks like" line asked for a **real** SU(3)
bi-invariant Riemannian metric (a new mathlib dependency or hand-
rolled construction), which would then feed an honest small-`t`
brick `K_t(x) ≲ t^{-4} · exp(-d_g(x, e)² / (4t))`. We cannot ship
that in mathlib v4.12.0 — the Killing-form Riemannian-metric API
on Lie groups is not present, and rolling our own would either
balloon the brick count out of proportion to the task or land
yet more `sorry`s on the way to the real Riemannian-distance
properties (triangle inequality, geodesic-completeness, ...).

What we ship instead, in line with the established stand-in
pattern (Batches 157.1 / 157.2 / 158.1 / 159.1 / 160.1 / 161.1):

  * a `d_SU3` symbol that downstream bricks (in
    `PeterWeylHeatVaradhan.lean`) can reference at type level
    *with the geometric `c = d²/4` shape*;
  * an `IsPseudoDistOnSU3` predicate that records the three
    pseudo-distance properties we *can* state without the absent
    Submonoid-multiplication plumbing;
  * an inhabitedness lemma showing the predicate is consistent.

The downstream geometric Varadhan-shape brick
`Heat_kernel_envelope_real_le_varadhan_geometric` (next file)
then uses this stand-in `d_SU3` to land the
`exp(-d_SU3(x, 1)² / (4t))` factor in the bound's signature. With
`d_SU3 ≡ 0` the factor collapses to `exp 0 = 1` and the brick
reduces to a wrapper around the existing strip bound — exactly
the same shape the OffDiagKernel stand-in
(`Towers/YM/OffDiagKernel.lean`) already uses for `K' t g ≤ C ·
t^{-4} · exp(-c · d(g, 1)² / t)`. Replacing `d_SU3` with the
real Killing-form distance will *intentionally* break the
geometric brick — that breakage is the tripwire signalling that
the real off-diagonal Varadhan bound has landed.

### Honest scope (locked)

This file is **not**:
  * the real SU(3) bi-invariant Riemannian metric (mathlib v4.12.0
    does not have it; the Killing-form construction would also
    need a Lie-algebra inner product, the Riemannian exponential
    map, and geodesic completeness, none of which are in this
    repo);
  * a triangle-inequality / metric-space instance on SU(3)
    (`d_SU3 ≡ 0` is a pseudometric only — degenerate, every pair
    of points has distance `0`);
  * a left- / right-invariance statement `d (k·g) (k·h) = d g h`
    or `d (g·k) (h·k) = d g h` — see the predicate docstring for
    why bi-invariance is intentionally not encoded here;
  * the off-diagonal Varadhan / Molchanov asymptotic itself
    (that bound is *false* for any synthetic envelope as `t → 0⁺`,
    see the drift block in `PeterWeylHeatVaradhan.lean`);
  * a constructive 4D pure-Yang-Mills measure;
  * a mass-gap lower bound on any YM Hamiltonian.

YM tower stays `Status: Open` in `docs/ROADMAP.md` § 2.

Axiom footprint
---------------
Depends only on the classical trio
`{propext, Classical.choice, Quot.sound}`.
================================================================
-/

import Mathlib.LinearAlgebra.UnitaryGroup
import Mathlib.Data.Real.Basic
import Mathlib.Data.Complex.Basic

namespace TheoremaAureum
namespace Towers
namespace YM
namespace RiemannianGeometry

/-- The SU(3) group as it appears throughout the YM tower. Same
abbreviation used by `Towers/YM/OffDiagKernel.lean` and
`Towers/YM/MassGap.lean` — kept locally for self-contained
elaboration of the bricks below. -/
abbrev SU3 : Type := Matrix.specialUnitaryGroup (Fin 3) ℂ

/-! ## Stand-in: bi-invariant Riemannian distance on SU(3) -/

/-- **STAND-IN.** The bi-invariant Riemannian distance on SU(3)
that the off-diagonal Varadhan / Molchanov asymptotic
`K_t(g, h) ≲ t^{-d/2} · exp(-d(g, h)² / (4t))` would consume.

Set to the constant `0` here because the genuine Killing-form
Riemannian metric on SU(3) is not in mathlib v4.12.0. Every
downstream bound that mentions `d_SU3` therefore collapses on
the diagonal — see the file docstring for the tripwire. -/
noncomputable def d_SU3 (_g _h : SU3) : ℝ := 0

/-! ## Pseudo-distance predicate -/

/-- **`IsPseudoDistOnSU3 d`** — a `Prop` recording the three
pseudo-distance properties of a bi-invariant distance on SU(3)
that we *can* state without the absent Submonoid-multiplication
plumbing:

  1. symmetric:        `d g h = d h g`
  2. nonneg:           `0 ≤ d g h`
  3. zero on diagonal: `d g g = 0`

Bi-invariance under left / right group action
`d (k·g) (k·h) = d g h` is **intentionally omitted** — `SU3` is
the carrier of the `Matrix.specialUnitaryGroup` `Submonoid` and
the `Mul` plumbing on a `Submonoid`'s carrier requires
additional imports/coercions that would balloon this stand-in
beyond proportion to its honest scope.

We ask **pseudo-distance** (no `d g h = 0 → g = h`) because the
stand-in `d_SU3 ≡ 0` does not separate points — it is a
degenerate pseudometric. The real Killing-form distance *does*
separate points (it is a genuine metric), but landing that
requires the absent Lie-group Riemannian API. -/
def IsPseudoDistOnSU3 (d : SU3 → SU3 → ℝ) : Prop :=
  (∀ g h : SU3, d g h = d h g) ∧
  (∀ g h : SU3, 0 ≤ d g h) ∧
  (∀ g : SU3, d g g = 0)

/-! ## Bricks -/

/-- **Brick 1 (`d_SU3_self`).** The stand-in distance vanishes on
the diagonal. Real (Killing-form) distance also has this property
— here it holds for the trivial reason that `d_SU3 ≡ 0`. -/
theorem d_SU3_self (g : SU3) : d_SU3 g g = 0 := by
  show (0 : ℝ) = 0
  rfl

/-- **Brick 2 (`d_SU3_nonneg`).** The stand-in distance is
nonnegative. Real (Killing-form) distance is also nonnegative
— here it holds trivially since `d_SU3 ≡ 0`. -/
theorem d_SU3_nonneg (g h : SU3) : 0 ≤ d_SU3 g h := by
  show (0 : ℝ) ≤ 0
  exact le_refl _

/-- **Brick 3 (`d_SU3_isPseudoDist`).** Inhabitedness witness:
the stand-in `d_SU3` satisfies the `IsPseudoDistOnSU3` predicate.

Proves the predicate is **consistent** (not vacuously universal),
NOT that we have constructed the real Killing-form bi-invariant
distance on SU(3). The witness here works because `d_SU3 ≡ 0`,
which trivially satisfies symmetry, nonnegativity, and vanishing
on the diagonal. -/
theorem d_SU3_isPseudoDist : IsPseudoDistOnSU3 d_SU3 := by
  refine ⟨?_, ?_, ?_⟩
  · intro _ _; show (0 : ℝ) = 0; rfl
  · intro _ _; exact le_refl _
  · intro _; show (0 : ℝ) = 0; rfl

end RiemannianGeometry
end YM
end Towers
end TheoremaAureum
